# Amber ecosystem releases

The tracker checks the declared repository roster every hour and on manual or repository dispatch. It resolves published release tags to full source commits, records GitHub-reported asset digests, and publishes one complete immutable snapshot. Current source, source tags and GitHub releases remain separate states. Asset metadata is distinct from downloaded artifact verification.

Failed or incomplete collection preserves the previous complete snapshot and its last successful check. The page exposes freshness, exact release identities, source timestamps and refresh-run links. Every roster entry is checked against live GitHub metadata. The website's implementation source excludes generated tracker refresh commits.

[Current snapshot JSON](/release-tracker.json) · [Last successful check](/release-tracker/health.json) · [Refresh runs](https://github.com/crimson-knight/amberframework.org/actions/workflows/sync-releases.yml) · [Support matrix](/docs/v2/beta-support) · [Roadmap](/roadmap/).
