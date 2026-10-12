"""Collect public release metadata and publish one complete immutable projection."""
from __future__ import annotations
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import time


class InvalidSnapshot(ValueError):
    pass


def require_valid(condition, explanation):
    if not condition:
        raise InvalidSnapshot(explanation)


def canonical_bytes(value):
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode()


def resolve_sha256(value):
    return hashlib.sha256(value).hexdigest()


def validate_commit_identity(commit_sha):
    require_valid(isinstance(commit_sha, str) and re.fullmatch(r"[0-9a-f]{40}", commit_sha), "Full source commit required")
    return commit_sha


def validate_event_time(event_time):
    parsed_time = datetime.fromisoformat(event_time.replace("Z", "+00:00"))
    require_valid(parsed_time.tzinfo is not None, "Release event requires a timezone")
    return event_time


@dataclass(frozen=True)
class RepositoryDefinition:
    project_title: str
    repository: str
    branch: str
    release_limit: int
    list_of_roadmap_cards: list[str]


@dataclass(frozen=True)
class PublishedRelease:
    release_id: int
    tag_name: str
    release_title: str
    published_at: str
    is_prerelease: bool
    source_commit: str
    release_url: str
    release_body: str
    list_of_assets: list[dict]


@dataclass(frozen=True)
class RepositoryRecord:
    project_title: str
    repository: str
    repository_url: str
    tracked_branch: str
    source_commit: str
    source_updated_at: str
    has_issues: bool
    is_archived: bool
    latest_tag: str | None
    latest_tag_commit: str | None
    list_of_roadmap_cards: list[str]
    list_of_releases: list[PublishedRelease]


class ReadGithubMetadata:
    """Convert GitHub responses at the API perimeter before the publisher uses them."""
    def __init__(self, *, authorization_token="", api_origin="https://api.github.com"):
        self.authorization_token = authorization_token
        self.api_origin = api_origin

    def _read_api_document(self, api_path):
        headers = {"Accept": "application/vnd.github+json", "User-Agent": "amberframework-ecosystem-release-tracker", "X-GitHub-Api-Version": "2022-11-28"}
        if self.authorization_token:
            headers["Authorization"] = "Bearer " + self.authorization_token
        for attempt in range(3):
            try:
                with urlopen(Request(self.api_origin + api_path, headers=headers), timeout=30) as response:
                    require_valid(response.status == 200, "GitHub response incomplete: " + api_path)
                    return json.loads(response.read(4_000_000))
            except HTTPError as error:
                if error.code not in {429, 500, 502, 503, 504} or attempt == 2:
                    raise InvalidSnapshot("GitHub metadata unavailable: " + api_path + " HTTP " + str(error.code)) from error
            except (URLError, TimeoutError) as error:
                if attempt == 2:
                    raise InvalidSnapshot("GitHub metadata timed out: " + api_path) from error
            time.sleep(attempt + 1)
        raise InvalidSnapshot("GitHub response unavailable: " + api_path)

    def resolve_tag_commit(self, *, repository, tag_name):
        reference = self._read_api_document("/repos/" + repository + "/git/ref/tags/" + quote(tag_name, safe=""))["object"]
        for unused_depth in range(5):
            commit_sha = validate_commit_identity(reference["sha"])
            if reference["type"] == "commit":
                return commit_sha
            require_valid(reference["type"] == "tag", "Unexpected tag object type")
            reference = self._read_api_document("/repos/" + repository + "/git/tags/" + commit_sha)["object"]
        raise InvalidSnapshot("Nested tag chain exceeds the declared bound")

    def read_repository_record(self, definition):
        repository = definition.repository
        metadata = self._read_api_document("/repos/" + repository)
        require_valid(metadata["full_name"].casefold() == repository.casefold(), "Repository identity changed: " + repository)
        branch = definition.branch or metadata["default_branch"]
        source = self._read_api_document("/repos/" + repository + "/commits/" + quote(branch, safe=""))
        if repository == "crimson-knight/amberframework.org":
            # Generated refresh commits are data updates, not new website implementation.
            commits = self._read_api_document("/repos/" + repository + "/commits?per_page=1&path=src&sha=" + quote(branch, safe=""))
            source = commits[0] if commits else None
            require_valid(source is not None, "Website application source commit missing")
        source_commit = validate_commit_identity(source["sha"])
        source_updated_at = validate_event_time(source["commit"]["committer"]["date"])
        tags = self._read_api_document("/repos/" + repository + "/tags?per_page=1")
        latest_tag = tags[0]["name"] if tags else None
        latest_tag_commit = self.resolve_tag_commit(repository=repository, tag_name=latest_tag) if latest_tag else None
        payload = self._read_api_document("/repos/" + repository + "/releases?per_page=" + str(definition.release_limit))
        require_valid(isinstance(payload, list), "Release list missing: " + repository)
        list_of_releases = []
        for entry in payload:
            require_valid(type(entry["draft"]) is bool and type(entry["prerelease"]) is bool, "Release state missing: " + repository)
            if entry["draft"]:
                continue
            tag_name = entry["tag_name"]
            require_valid(isinstance(tag_name, str) and tag_name, "Release tag missing")
            source_revision = self.resolve_tag_commit(repository=repository, tag_name=tag_name)
            published_at = validate_event_time(entry["published_at"])
            require_valid(entry["html_url"].startswith("https://github.com/" + repository + "/releases/"), "Release URL identity mismatch")
            list_of_assets = []
            for asset in entry["assets"]:
                asset_digest = asset.get("digest")
                require_valid(asset_digest is None or re.fullmatch(r"sha256:[0-9a-f]{64}", asset_digest), "Artifact digest malformed")
                require_valid(asset["browser_download_url"].startswith("https://github.com/" + repository + "/releases/download/"), "Artifact URL identity mismatch")
                list_of_assets.append({"asset_title": asset["name"], "download_url": asset["browser_download_url"], "github_reported_digest": asset_digest, "size_bytes": asset["size"]})
            list_of_releases.append(PublishedRelease(entry["id"], tag_name, entry.get("name") or tag_name, published_at, entry["prerelease"], source_revision, entry["html_url"], entry.get("body") or "", list_of_assets))
        list_of_releases.sort(key=lambda release: release.published_at, reverse=True)
        return RepositoryRecord(definition.project_title, repository, "https://github.com/" + repository, branch, source_commit, source_updated_at, metadata["has_issues"], metadata["archived"], latest_tag, latest_tag_commit, definition.list_of_roadmap_cards, list_of_releases)


def write_atomic_file(destination, content):
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(destination.name + ".pending")
    temporary.write_bytes(content)
    os.replace(temporary, destination)


class WhenRepositoriesAreCheckedThenPublishSnapshot:
    """When the declared roster is checked, publish its complete release projection."""
    def __init__(self, *, project_root, list_of_repository_definitions, github_gateway, checked_at, roster_sha256):
        self.project_root = Path(project_root)
        self.list_of_repository_definitions = list_of_repository_definitions
        self.github_gateway = github_gateway
        self.checked_at = validate_event_time(checked_at)
        self.roster_sha256 = roster_sha256
        self.list_of_repository_records = []
        self.content_sha256 = ""

    def perform(self):
        self.collect_repository_records()
        self.validate_complete_roster()
        self.publish_verified_snapshot()
        return self.content_sha256

    def collect_repository_records(self):
        with ThreadPoolExecutor(max_workers=4) as executor:
            self.list_of_repository_records = list(executor.map(self.github_gateway.read_repository_record, self.list_of_repository_definitions))

    def validate_complete_roster(self):
        expected = [source.repository for source in self.list_of_repository_definitions]
        actual = [record.repository for record in self.list_of_repository_records]
        require_valid(len(expected) > 0 and len(set(expected)) == len(expected) and actual == expected, "Incomplete or duplicate repository roster")
        previous_path = self.project_root / "public/release-tracker/current/snapshot.json"
        previous = json.loads(previous_path.read_text()) if previous_path.exists() else {"repositories": []}
        prior_commits = {(record["repository"], release["tag_name"]): release["source_commit"] for record in previous["repositories"] for release in record["list_of_releases"]}
        for record in self.list_of_repository_records:
            validate_commit_identity(record.source_commit)
            require_valid(len({release.tag_name for release in record.list_of_releases}) == len(record.list_of_releases), "Duplicate published release")
            for release in record.list_of_releases:
                previous_commit = prior_commits.get((record.repository, release.tag_name))
                require_valid(previous_commit is None or previous_commit == release.source_commit, "Published tag moved: " + record.repository + " " + release.tag_name)

    def publish_verified_snapshot(self):
        tracker_root = self.project_root / "public/release-tracker"
        snapshot = {"schema_version": 1, "roster_sha256": self.roster_sha256, "template_sha256": resolve_sha256((self.project_root / "site_content/release-tracker.html").read_bytes()), "repositories": [asdict(record) for record in self.list_of_repository_records], "scope": "Published GitHub release metadata and resolved source refs; asset digests are GitHub-reported, not downloaded verification."}
        self.content_sha256 = resolve_sha256(canonical_bytes(snapshot))
        snapshot["content_sha256"] = self.content_sha256
        bundle_root = tracker_root / "bundles" / self.content_sha256
        if not bundle_root.exists():
            bundle_root.parent.mkdir(parents=True, exist_ok=True)
            staging_root = Path(tempfile.mkdtemp(prefix=".staging-", dir=bundle_root.parent))
            try:
                snapshot["content_updated_at"] = self.checked_at
                (staging_root / "snapshot.json").write_bytes(canonical_bytes(snapshot))
                encoded = json.dumps(snapshot, ensure_ascii=False).replace("<", "\\u003c")
                (staging_root / "snapshot.js").write_text("window.AmberReleaseSnapshot=" + encoded + ";\n")
                template = (self.project_root / "site_content/release-tracker.html").read_text()
                (staging_root / "index.html").write_text(template)
                manifest = {name: resolve_sha256((staging_root / name).read_bytes()) for name in ["snapshot.json", "snapshot.js", "index.html"]}
                (staging_root / "manifest.json").write_bytes(canonical_bytes(manifest))
                os.replace(staging_root, bundle_root)
            finally:
                if staging_root.exists():
                    shutil.rmtree(staging_root)
        manifest = json.loads((bundle_root / "manifest.json").read_text())
        require_valid(set(manifest) == {"snapshot.json", "snapshot.js", "index.html"}, "Snapshot manifest incomplete")
        for filename, expected_digest in manifest.items():
            require_valid(resolve_sha256((bundle_root / filename).read_bytes()) == expected_digest, "Snapshot artifact hash mismatch: " + filename)
        health = {"checked_at": self.checked_at, "content_sha256": self.content_sha256, "roster_sha256": self.roster_sha256, "refresh_interval_minutes": 60, "repository_count": len(self.list_of_repository_records)}
        write_atomic_file(tracker_root / "health.json", canonical_bytes(health))
        write_atomic_file(tracker_root / "health.js", ("window.AmberReleaseHealth=" + json.dumps(health) + ";\n").encode())
        tracker_root.mkdir(parents=True, exist_ok=True)
        pending_pointer = tracker_root / "current.pending"
        pending_pointer.unlink(missing_ok=True)
        pending_pointer.symlink_to("bundles/" + self.content_sha256, target_is_directory=True)
        os.replace(pending_pointer, tracker_root / "current")
        for filename, target in [("index.html", "current/index.html"), ("index.json", "current/snapshot.json")]:
            pointer = tracker_root / filename
            if not pointer.is_symlink():
                pointer.unlink(missing_ok=True)
                pointer.symlink_to(target)
        list_of_legacy_releases = []
        for record in self.list_of_repository_records:
            for release in record.list_of_releases:
                publication_time = datetime.fromisoformat(release.published_at.replace("Z", "+00:00"))
                list_of_legacy_releases.append({"project": record.project_title, "repository": record.repository, "tag_name": release.tag_name, "name": release.release_title, "published_at": release.published_at, "published_on": publication_time.strftime("%B %d, %Y").replace(" 0", " "), "prerelease": release.is_prerelease, "url": release.release_url, "body": release.release_body})
        list_of_legacy_releases.sort(key=lambda release: release["published_at"], reverse=True)
        write_atomic_file(self.project_root / "config/github_releases.json", canonical_bytes({"schema_version": 1, "synced_at": self.checked_at, "releases": list_of_legacy_releases}))


def load_repository_definitions(project_root):
    roster = (project_root / "config/release_repositories.json").read_bytes()
    document = json.loads(roster)
    require_valid(document["schema_version"] == 1 and document["refresh_interval_minutes"] == 60, "Unknown roster contract")
    list_of_definitions = []
    for source in document["repositories"]:
        require_valid(re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", source["repository"]), "Repository identity malformed")
        require_valid(1 <= source["release_limit"] <= 100, "Release page bound invalid")
        list_of_definitions.append(RepositoryDefinition(source["project_title"], source["repository"], source.get("branch", ""), source["release_limit"], source["roadmap_cards"]))
    return list_of_definitions, resolve_sha256(roster)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    arguments = parser.parse_args()
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN") or ""
    if not token and shutil.which("gh"):
        token = subprocess.check_output(["gh", "auth", "token"], text=True).strip()
    definitions, roster_digest = load_repository_definitions(arguments.root)
    current_time = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    publisher = WhenRepositoriesAreCheckedThenPublishSnapshot(project_root=arguments.root, list_of_repository_definitions=definitions, github_gateway=ReadGithubMetadata(authorization_token=token), checked_at=current_time, roster_sha256=roster_digest)
    try:
        content_digest = publisher.perform()
    except (InvalidSnapshot, KeyError, TypeError, json.JSONDecodeError) as error:
        raise SystemExit("Release refresh failed; last complete snapshot retained: " + str(error)) from error
    print(json.dumps({"checked_at": current_time, "repositories_checked": len(definitions), "content_sha256": content_digest}))
