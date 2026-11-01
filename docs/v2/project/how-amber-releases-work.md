---
title: "How Amber releases work"
section: "project"
order: 35
description: "Where work lands, how a release is chosen and tagged, and how a release is rolled back"
---

# How Amber releases work

Every Amber release is a tag.
What you install or visit always comes from a tag, never from a branch.

## Who decides

Seth Tucker, the project lead, decides what goes into each release and when it ships.
Maintainers review the work; the [governance page](/docs/v2/project/governance) describes their part.

## Where work lands

Merged pull requests land on each repository's development branch.
For Amber V2 that is `v2-dev` in the framework repository, `main` in the CLI repository, and `master` for this website.
A development branch is where work collects; it is never a release.
For an app you depend on, install from a release tag.

## How the next release is chosen

A release branch, `release/next`, collects the changes chosen for the next release.
Only changes already merged to the development branch move to it.
The project lead chooses which of those changes go in.

## How a release is tagged

When the chosen group passes CI, its commit gets a tag that never moves.
The framework and its libraries use version tags, for example `v2.0.0-beta.5`.
This website uses date tags, for example `site-2026.11.1`.
Each release names its full commit hash and the sha256 of every file it publishes.
The [release tracker](https://amberframework.org/release-tracker/) records each tag's commit and published file digests.

## How a release reaches you

Shards and the CLI install from release tags, pinned by your `shard.lock`.
This website is deployed only from its release tags, after CI builds and tests that exact commit.

## How a release is rolled back

Rolling back means redeploying the previous tag.
Earlier tags stay published, so an app can pin the previous version and the website can redeploy its previous tag.
A fix ships as a new tag; a published tag is never changed.

## Where to follow along

Release notes and their files are on each repository's GitHub Releases page.
The [release contract](/docs/v2/project/release-contract) describes what a release must prove before it ships.
