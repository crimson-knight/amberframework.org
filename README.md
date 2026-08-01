# Amber Framework Website

The official Amber Framework website, running on Amber `2.0.0-beta.2` and ECR.
The site serves the V2 launch experience, versioned documentation, release blog,
and brand system without a Node or Webpack runtime.

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
```

## Production

The production image compiles the site with Crystal 1.21 and runs the generated
`bin/amberframework` binary. DigitalOcean App Platform deploys `master` through
the root `Dockerfile`.

```sh
docker compose up --build
```

## Contributing

1. Fork <https://github.com/amberframework/amberframework.org>.
2. Create a focused branch.
3. Run the verification commands above.
4. Open a pull request with screenshots for visual changes.
