# Amber Framework Website

The Amber Framework website, running on Amber `2.0.0-beta.2` and ECR. The V2
public-beta experience includes versioned documentation, the project blog, and
the Amber brand system without a Node or Webpack runtime.

Amber CLI `2.0.3` is the minimum version for the web starter demonstrated on
the homepage and in the V2 guides.

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
the root `Dockerfile`. Release evidence and the final gate status live in
`design/v2-preview/RELEASE_PROOF.md` and `design/v2-preview/RELEASE_GATES.md`.

```sh
docker compose up --build
```

## Contributing

1. Fork <https://github.com/amberframework/amberframework.org>.
2. Create a focused branch.
3. Run the verification commands above.
4. Open a pull request with desktop and mobile screenshots for visual changes.
5. Keep the CLI, framework pin, generated starter, and public documentation in
   one verified release contract.
