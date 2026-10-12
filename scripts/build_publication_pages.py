"""Export the reviewed concepts with first-party assets and canonical site links."""
from pathlib import Path
from html import escape
import base64
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "site_content"
PUBLIC = ROOT / "public"
IMAGE_SHA256 = "b5f1c250d0278cce8adb1dca646ecc23d0ad9563dbb475473c706be999deb3c5"
DOC_LINKS = {
    "BUSINESS_TEMPLATE_CONTRACT.md": "/docs/v2/project/business-templates",
    "GOVERNANCE.md": "/docs/v2/project/governance",
    "RELEASE_CONTRACT_REVIEW.md": "/docs/v2/project/release-contract",
    "RELEASE_BUNDLE_CONTRACT.md": "/docs/v2/project/release-contract",
    "AGENT_USAGE_CONTRACT.md": "/docs/v2/project/contributing-with-your-assistant",
    "CONTRIBUTING.md": "/docs/v2/contributing",
    "TENANCY_STORY_DRAFT.md": "/docs/v2/project/tenancy-paths",
}


def canonicalize_links(content):
    for filename, target in DOC_LINKS.items():
        content = content.replace("http://127.0.0.1:8865/contribution-system/" + filename, target)
        content = content.replace("../contribution-system/" + filename, target)
        content = content.replace("http://127.0.0.1:8865/research/" + filename, target)
        content = content.replace("../research/" + filename, target)
        content = content.replace('href="' + filename + '"', 'href="' + target + '"')
    content = content.replace("http://127.0.0.1:8865/pioneers/agent-entry-evidence.json", "/release-tracker.json")
    content = content.replace("http://127.0.0.1:8865/pioneers/", "/pioneers/")
    content = content.replace("http://127.0.0.1:8865/research/", "/research/")
    content = content.replace("http://127.0.0.1:8865/", "/roadmap/")
    content = content.replace("../contribution-system/release-contract-audit.json", "/release-tracker.json")
    content = content.replace('href="../research/"', 'href="/research/"')
    content = content.replace('href="../"', 'href="/roadmap/"')
    content = content.replace('href="./#p-', 'href="/pioneers/#p-')
    content = content.replace('href="./"', 'href="/pioneers/"')
    content = content.replace("Evidence checked October 5, 2026", "Release history and current state")
    content = content.replace("Recruitment concept", "Amber Pioneers")
    content = content.replace("Source record</a>", "Live release sources</a>")
    content = content.replace("Public website publication is pending.", "The measurements retain their original dates and workload scopes.")
    content = content.replace("Current roadmap draft", "Road to Amber V2")
    content = content.replace("Local recruitment concept", "Amber Pioneers")
    return content


def redact_local_paths(content):
    return re.sub(r"/Users/[A-Za-z0-9_./ -]+", "[local workspace]", content)


def wrap_page(fragment, title, slug):
    return ('<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="description" content="' + escape(title) + '"><title>' + escape(title) + '</title><link rel="canonical" href="https://amberframework.org/' + slug + '/"><style>:root{color-scheme:light dark}body{margin:0}</style></head><body>\n' + fragment + '\n</body></html>\n')


def add_release_summary(content):
    summary = version_release_viewer((SOURCE / "release-summary.html").read_text())
    if "</main>" in content:
        return content.replace("</main>", summary + "</main>", 1)
    return content + summary


def write_page(slug, content, title, markdown):
    destination = PUBLIC / slug
    destination.mkdir(parents=True, exist_ok=True)
    require_public_links(content)
    (destination / "index.html").write_text(content)
    (destination / "index.md").write_text(markdown)
    (destination / "index.json").write_text(json.dumps({"schema_version": 1, "page_title": title, "canonical_url": "https://amberframework.org/" + slug + "/", "markdown_url": "/" + slug + ".md", "release_tracker_url": "/release-tracker.json", "contribution_repository": "https://github.com/amberframework/amber/issues", "discord_url": "https://discord.gg/vwvP5zakSn"}, indent=2) + "\n")


def version_release_viewer(content):
    if "/publication/release-tracker.js" in content:
        digest = hashlib.sha256((PUBLIC / "publication/release-tracker.js").read_bytes()).hexdigest()
        content = re.sub(r"/publication/release-tracker\.js(?:\?v=[0-9a-f]{64})?", "/publication/release-tracker.js?v=" + digest, content)
    return content


def require_public_links(content):
    for target in re.findall(r'(?:href|src)=["\']([^"\']+)', content):
        if "127.0.0.1" in target or "localhost" in target or target.startswith("/Users/") or "contribution-system" in target:
            raise ValueError("Publication link needs a public destination: " + target)
    if "/Users/" in content:
        raise ValueError("Publication still contains a private filesystem path")


def main():
    image = ROOT / "app/assets/characters/amber-pioneers-crystal-trail-v1.webp"
    assert hashlib.sha256(image.read_bytes()).hexdigest() == IMAGE_SHA256
    list_of_images = list((PUBLIC / "assets/characters").glob("amber-pioneers-crystal-trail-v1-*.webp"))
    assert len(list_of_images) == 1, "Build the manifest-backed illustration first"
    image_url = "/" + list_of_images[0].relative_to(PUBLIC).as_posix()
    pioneers = canonicalize_links((SOURCE / "pioneers.fragment.html").read_text())
    image_data = "data:image/webp;base64," + base64.b64encode(image.read_bytes()).decode()
    assert image_data in pioneers
    pioneers = pioneers.replace(image_data, image_url)
    pioneers = pioneers.replace("/blob/v2025.11.25.6/", "/blob/v2025.11.25.8/")
    pioneers = pioneers.replace("Available foundation · Distributed today as Shards Alpha", "Available foundation · Minecart and its agent tools")
    pioneers = pioneers.replace("The Minecart rename is local work. The installed command is still <code>shards-alpha</code>.", "Minecart 2025.11.25.8 is published. <code>shards-alpha</code> remains a compatibility alias.")
    pioneers = pioneers.replace("App MCP and agent setup have open CLI PRs.", "Agent setup is included in CLI 2.0.7. App MCP has an open CLI PR.")
    pioneers = pioneers.replace("app MCP and agent setup have open CLI PRs.", "Agent setup is included in CLI 2.0.7. App MCP has an open CLI PR.")
    pioneers = pioneers.replace("Grant and CLI source merged · starter release pending · app capacity unmeasured", "Grant source and CLI 2.0.7 available · tutorial and measured app profile in preparation")
    pioneers = pioneers.replace("Minecart's tools are distributed in the installed Shards Alpha build.", "Minecart and CLI 2.0.7 carry the available agent entry tools.")
    pioneers = pioneers.replace("The issue-first policy is our direction; its shared public policy and required GitHub checks are being prepared.", "The issue-first policy is published in the project guides; required GitHub checks are being prepared.")
    pioneers = pioneers.replace(" · New artwork created for Amber Pioneers", "")
    assert not re.search(r"<(?:form|input|textarea)\b", pioneers)
    pioneers = add_release_summary(pioneers)
    write_page("pioneers", wrap_page(pioneers, "Seek adventure · Amber Pioneers", "pioneers"), "Amber Pioneers", (SOURCE / "pioneers.md").read_text())
    roadmap = canonicalize_links((SOURCE / "roadmap.fragment.html").read_text())
    roadmap = add_release_summary(roadmap)
    write_page("roadmap", wrap_page(roadmap, "The road to Amber V2", "roadmap"), "The road to Amber V2", (SOURCE / "roadmap.md").read_text())
    beta = canonicalize_links((SOURCE / "beta-guide.html").read_text())
    beta = beta.replace("Draft invitation and process guide · October 5, 2026 · Public policy and broad synchronization are being prepared.", "The beta exercises the release journey. Website policy is published; required GitHub enforcement and the full ecosystem bundle are separate work.")
    beta = beta.replace("This guide is a local draft.", "See the release tracker for current repository publication state.")
    require_public_links(beta)
    (PUBLIC / "pioneers/release-contract.html").write_text(beta)
    research = canonicalize_links((SOURCE / "research.html").read_text())
    research = redact_local_paths(research)
    write_page("research", research, "Amber components and performance research", canonicalize_links((SOURCE / "research/RESEARCH_OVERVIEW.md").read_text()))
    for source in (SOURCE / "research").iterdir():
        if not source.is_file():
            continue
        if source.suffix == ".png":
            (PUBLIC / "research" / source.name).write_bytes(source.read_bytes())
            continue
        content = redact_local_paths(canonicalize_links(source.read_text()))
        (PUBLIC / "research" / source.name).write_text(content)
    (PUBLIC / "research/index.json").write_bytes((PUBLIC / "research/progress-data.json").read_bytes())
    (PUBLIC / "release-tracker").mkdir(exist_ok=True)
    (PUBLIC / "release-tracker/index.md").write_text((SOURCE / "release-tracker.md").read_text())
    print("Built canonical roadmap, Pioneers, beta guide, scoped research and machine-readable pages.")


if __name__ == "__main__":
    main()
