# Amber Framework Website

The Amber Framework website, running on Amber `2.0.0-beta.2` and ECR. The
`agent/v2-experience-preview` branch contains the proposed V2 experience,
versioned documentation, blog, and brand system without a Node or Webpack
runtime.

> **Preview — not approved for release.** This branch must not merge or deploy
> until the owner explicitly approves the visual proof and every item in
> `design/v2-preview/RELEASE_GATES.md`.

## Local development

Requirements:

- Crystal 1.20 or newer (earlier than 2.0)
- Shards

```sh
shards install
amber watch
```

Open <http://localhost:3000>. Static CSS, JavaScript, and brand assets live in
`public/assets`; no front-end build step is required.

## Verification

```sh
crystal spec
scripts/check_v2_beta_docs.sh
scripts/check_v2_site_launch.sh
scripts/check_v2_preview.sh
```

## Production boundary

The production image compiles the site with Crystal 1.21 and runs the generated
`bin/amberframework` binary. DigitalOcean App Platform deploys `master` through
the root `Dockerfile`. Production remains on the restored pre-redesign site
until the owner explicitly approves this preview.

```sh
docker compose up --build
```

## Contributing

1. Fork <https://github.com/amberframework/amberframework.org>.
2. Create a focused branch.
3. Run the verification commands above.
4. Open a pull request with desktop and mobile screenshots for visual changes.
5. Do not merge or deploy a V2 experience without explicit owner approval.
