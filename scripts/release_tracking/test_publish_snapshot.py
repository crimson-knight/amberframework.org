"""Behavioral release projection checks with an isolated synthetic repository."""
from dataclasses import replace
from pathlib import Path
from tempfile import TemporaryDirectory
import json
import unittest
from scripts.release_tracking.when_repositories_are_checked_then_publish_snapshot import (
    RepositoryDefinition, RepositoryRecord, PublishedRelease, InvalidSnapshot,
    WhenRepositoriesAreCheckedThenPublishSnapshot, ReadGithubMetadata, resolve_release_body_links, load_repository_definitions,
)

class SnapshotPublicationTest(unittest.TestCase):
    def setUp(self):
        self.directory = TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / 'site_content').mkdir()
        (self.root / 'site_content/release-tracker.html').write_text('<h1>Release evidence</h1>')
        self.definition = RepositoryDefinition('Example', 'owner/example', 'main', 5, ['core'])
        self.release = PublishedRelease(1, 'v2.0.0-beta.1', 'Beta', '2026-10-01T00:00:00Z', True, 'a' * 40, 'https://github.com/owner/example/releases/tag/v2.0.0-beta.1', 'Evidence', [])
        self.record = RepositoryRecord('Example', 'owner/example', 'https://github.com/owner/example', 'main', 'b' * 40, '2026-10-01T00:00:00Z', True, False, 'v2.0.0-beta.1', 'a' * 40, ['core'], [self.release])

    def publish(self, record=None, checked_at='2026-10-12T12:00:00Z', gateway=None, definitions=None):
        class FixtureGateway:
            def read_repository_record(inner, definition):
                return record or self.record
        return WhenRepositoriesAreCheckedThenPublishSnapshot(project_root=self.root, list_of_repository_definitions=definitions or [self.definition], github_gateway=gateway or FixtureGateway(), checked_at=checked_at, roster_sha256='c' * 64).perform()

    def fingerprint(self):
        return {str(path.relative_to(self.root)): path.read_bytes() for path in self.root.rglob('*') if path.is_file()}

    def test_publishes_prerelease_with_resolved_commit_and_manifest(self):
        digest = self.publish()
        current = self.root / 'public/release-tracker/current'
        self.assertEqual(current.readlink().name, digest)
        snapshot = json.loads((current / 'snapshot.json').read_text())
        self.assertTrue(snapshot['repositories'][0]['list_of_releases'][0]['is_prerelease'])
        self.assertEqual(snapshot['repositories'][0]['list_of_releases'][0]['source_commit'], 'a' * 40)
        self.assertEqual(set(json.loads((current / 'manifest.json').read_text())), {'snapshot.json', 'snapshot.js', 'index.html'})

    def test_unchanged_check_updates_health_without_duplicate_bundle(self):
        digest = self.publish()
        next_digest = self.publish(checked_at='2026-10-12T13:00:00Z')
        self.assertEqual(digest, next_digest)
        self.assertEqual(len(list((self.root / 'public/release-tracker/bundles').iterdir())), 1)
        health = json.loads((self.root / 'public/release-tracker/health.json').read_text())
        self.assertEqual(health['checked_at'], '2026-10-12T13:00:00Z')
        self.assertEqual(json.loads((self.root / 'public/release-tracker/index.json').read_text())['content_updated_at'], '2026-10-12T12:00:00Z')

    def test_new_release_creates_bundle_and_updates_legacy_catalog(self):
        before = self.publish()
        release = replace(self.release, tag_name='v2.0.0-beta.2', source_commit='d' * 40)
        after = self.publish(replace(self.record, list_of_releases=[release, self.release]))
        self.assertNotEqual(before, after)
        self.assertEqual(len(json.loads((self.root / 'config/github_releases.json').read_text())['releases']), 2)

    def test_failed_fetch_preserves_every_published_file(self):
        self.publish()
        before = self.fingerprint()
        class UnavailableGateway:
            def read_repository_record(inner, definition):
                raise InvalidSnapshot('Synthetic unavailable response')
        with self.assertRaises(InvalidSnapshot):
            self.publish(gateway=UnavailableGateway())
        self.assertEqual(self.fingerprint(), before)

    def test_incomplete_roster_preserves_snapshot(self):
        self.publish()
        before = self.fingerprint()
        with self.assertRaises(InvalidSnapshot):
            self.publish(replace(self.record, repository='owner/wrong'))
        self.assertEqual(self.fingerprint(), before)

    def test_moved_published_tag_preserves_snapshot(self):
        self.publish()
        before = self.fingerprint()
        with self.assertRaisesRegex(InvalidSnapshot, 'Published tag moved'):
            self.publish(replace(self.record, list_of_releases=[replace(self.release, source_commit='e' * 40)]))
        self.assertEqual(self.fingerprint(), before)

    def test_duplicate_roster_fails_before_publication(self):
        with self.assertRaises(InvalidSnapshot):
            self.publish(definitions=[self.definition, self.definition])
        self.assertFalse((self.root / 'public').exists())

    def test_template_revision_updates_bundle_identity(self):
        before = self.publish()
        (self.root / 'site_content/release-tracker.html').write_text('<h1>New release presentation</h1>')
        self.assertNotEqual(self.publish(), before)

    def test_unqualified_source_ref_is_rejected(self):
        with self.assertRaises(InvalidSnapshot):
            self.publish(replace(self.record, source_commit='main'))
        self.assertFalse((self.root / 'public').exists())

    def test_corrupted_existing_bundle_fails_before_health_changes(self):
        self.publish()
        health_path = self.root / 'public/release-tracker/health.json'
        before = health_path.read_bytes()
        (self.root / 'public/release-tracker/current/snapshot.js').write_text('corrupted')
        with self.assertRaisesRegex(InvalidSnapshot, 'hash mismatch'):
            self.publish(checked_at='2026-10-12T13:00:00Z')
        self.assertEqual(health_path.read_bytes(), before)

    def test_release_body_links_keep_their_released_source_context(self):
        body = '[Report](benchmarks/report.md) [Public](https://example.com/report) [Anchor](#scope)'
        result = resolve_release_body_links(body, 'owner/example', 'a' * 40)
        self.assertIn('https://github.com/owner/example/blob/' + 'a' * 40 + '/benchmarks/report.md', result)
        self.assertIn('[Public](https://example.com/report)', result)
        self.assertIn('[Anchor](#scope)', result)

    def test_unknown_roadmap_association_is_rejected_before_collection(self):
        (self.root / 'config').mkdir()
        (self.root / 'site_content/roadmap.fragment.html').write_text("{id:'core',title:'Foundation'}")
        roster = {'schema_version':1,'refresh_interval_minutes':60,'repositories':[{'project_title':'Example','repository':'owner/example','release_limit':5,'roadmap_cards':['missing-card']}]}
        (self.root / 'config/release_repositories.json').write_text(json.dumps(roster))
        with self.assertRaisesRegex(InvalidSnapshot, 'Unknown roadmap card association'):
            load_repository_definitions(self.root)
        self.assertFalse((self.root / 'public').exists())

    def test_annotated_tag_resolves_to_commit(self):
        class AnnotatedGateway(ReadGithubMetadata):
            def _read_api_document(inner, path):
                return {'object': {'type': 'commit' if '/git/tags/' in path else 'tag', 'sha': 'a' * 40}}
        self.assertEqual(AnnotatedGateway().resolve_tag_commit(repository='owner/example', tag_name='v1'), 'a' * 40)

    def test_nested_tag_cycle_fails_closed(self):
        class CyclicGateway(ReadGithubMetadata):
            def _read_api_document(inner, path):
                return {'object': {'type': 'tag', 'sha': 'a' * 40}}
        with self.assertRaises(InvalidSnapshot):
            CyclicGateway().resolve_tag_commit(repository='owner/example', tag_name='v1')

if __name__ == '__main__':
    unittest.main()
