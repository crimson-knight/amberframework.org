# Amber CLI template delivery strategy

Status: **OFFLINE DELIVERY IMPLEMENTED; REMOTE CHANNEL PROPOSED**

Updated: August 11, 2026

## Current behavior

Amber CLI `2.0.6` generates web projects through inline writer methods in
`AmberCLI::Commands::NewCommand`. The repository also contains an application
template tree, but `NewCommand#create_project_structure` does not render that
tree. The beta contract now checks the identifying dependencies, views, and
authored assets in both representations, but they are still two maintenance
surfaces rather than one canonical generator input.

The executable therefore has two useful properties today:

- generation is deterministic and works offline; and
- a project records an exact Amber prerelease pin.

It also has one material operational cost: fixing the generated scaffold
requires a new CLI build and package release. Static assets are authored under
`app/assets/` and compiled locally into `public/assets/`; template delivery does
not require a runtime CDN, npm registry, or remote font host.

## Near-term beta decision

For the V2 beta, keep generation offline and deterministic. Make the inline
generator and the website proof agree, remove the unused duplicate template or
make it the sole generator input, and publish template corrections as Amber CLI
patch releases. Installation docs should tell users to upgrade the CLI before
creating a project.

Do not mutate existing applications automatically.

## Proposed remote channel

A future CLI may update templates independently without turning generation into
an unaudited network operation:

1. Publish a versioned manifest from an Amber-controlled release origin.
2. Give each template an immutable version, supported CLI range, supported
   Amber range, archive URL, SHA-256 digest, and release signature.
3. Verify both the signature and digest before extracting anything.
4. Cache verified archives in the platform cache directory.
5. Bundle the latest compatible template with the CLI as an offline fallback.
6. Expose explicit controls such as `--template-version`, `--offline`, and
   `amber template update`; never change an existing project implicitly.
7. Record the selected template version in `.amber.yml` so bug reports can
   reproduce the generated starting point.

The default channel should resolve only to templates compatible with the
installed CLI major version. A failed fetch, signature, digest, or compatibility
check must fail closed or use the clearly reported bundled fallback.

## Release gates

- One canonical template source produces the generated project and website
  demonstration.
- Clean macOS and Linux runs prove online, cached, and offline generation.
- Signature and path-traversal failure tests pass.
- A manifest rollback cannot silently downgrade an explicitly pinned template.
- Documentation distinguishes CLI version, template version, and Amber
  framework version.
- The owner approves the network and trust model before implementation ships.
