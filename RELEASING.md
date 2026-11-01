# Releasing amberframework.org

The live site runs only from release tags.
Seth Tucker approved this policy on 2026-11-01.

## Who decides

Seth Tucker decides what goes into each release.
Seth Tucker decides when a release is tagged and deployed.
Anyone else who cuts or deploys a release does so with his recorded approval.

## The branches

`master` is where work lands.
`master` is never live.
`release/next` collects the next group of changes.
`release/next` only receives commits that are already on `master`.
Feature branches start from `master` and return to `master` through a pull request.

## How a change gets into `master`

Open a pull request against `master`.
CI must pass: specs, the docs checks, the deployment image and its public routes.
A maintainer reviews it and merges it.
Merging to `master` changes nothing on the live site.

## How a change gets into `release/next`

Open a pull request from `master` (or from a branch of chosen `master` commits) into `release/next`.
The pull request lists the changes it brings.
Seth reviews the list and merges it when he wants those changes in the next release.
CI runs on `release/next` after every merge.

## How a release is cut

The release is the tip of `release/next` when CI on it is green.
Tag that commit with an annotated tag and push the tag:

```sh
git fetch origin
git tag -a site-2026.11.1 -m "amberframework.org site-2026.11.1" origin/release/next
git push origin site-2026.11.1
```

Pushing the tag starts CI for that exact commit.
CI builds the deployment image, runs every check, and exports the site bundle.
CI publishes a GitHub Release named for the tag.
The release holds `amberframework-bundle.tar.gz`, `release-manifest.json` and `SHA256SUMS`.
The release notes state the commit hash, the bundle sha256 and the binary sha256.

## Tag names

A release tag is `site-YYYY.MM.N`, for example `site-2026.11.1`.
`YYYY.MM` is the year and month the release is cut.
`N` starts at 1 each month and goes up by one for each release that month.
A test tag adds a label, for example `site-2026.11.0-test`.
A test tag is published as a prerelease and is deleted after its test.
A release tag never moves and is never reused.
A fix after a release ships as a new tag.

## How deploy works

Deploy from a checkout of this repository with `gh` signed in and the droplet key present.

```sh
scripts/deploy_droplet.sh site-2026.11.1   # deploy exactly this tag
scripts/deploy_droplet.sh                  # deploy the newest release tag
scripts/deploy_droplet.sh --dry-run site-2026.11.1   # select and verify only; change nothing
```

The script accepts only tags; it refuses branch names and commit hashes.
It downloads the tag's GitHub Release.
It checks `SHA256SUMS`, GitHub's asset digest and the manifest against the bundle.
It checks that the manifest names the tag's commit and that CI passed for that commit.
It checks the bundle and the binary again on the server.
It installs the release in `/srv/site/amberframework/releases/<tag>_<sha12>_<time>/`.
It writes the tag into `DEPLOYED_TAG` in that directory.
It moves the `current` link, restarts the service and checks the site through Caddy.
If the site fails that check, the script puts the previous release back.

## How rollback works

Rolling back means redeploying the previous tag.

```sh
scripts/deploy_droplet.sh --rollback             # the release tag just before the one live now
scripts/deploy_droplet.sh site-2026.11.1         # or any earlier tag by name
```

`--rollback` reads `DEPLOYED_TAG` on the server and deploys the release tag before it.
Every rollback goes through the same checks as a deploy.
GitHub Releases keep every tag's bundle, so any past tag can be redeployed.
CI also keeps each tag's bundle as a workflow artifact for 90 days.

## Where things live

The droplet and its services: `agentc-agency-01` (see that server's `SERVER.md`).
The deploy script: `scripts/deploy_droplet.sh`.
The one-time server setup: `scripts/setup_droplet.sh`.
The CI workflow: `.github/workflows/ci.yml`.
