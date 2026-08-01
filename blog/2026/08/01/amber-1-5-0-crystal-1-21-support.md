# Amber 1.5.0: Crystal 1.21 Support Restored

Crystal 1.21 turned on multithreading by default, and with it `Process.fork` became a compile-time error. Amber 1.x used `Process.fork` inside `Amber::Cluster`, in a code path the compiler reaches from every `Amber::Server.start` — which meant **every Amber app stopped compiling on Crystal 1.21**, whether or not it used cluster mode.

Amber 1.5.0 fixes that, and it's out now.

## What's in 1.5.0

**Crystal 1.21 compatibility.** Cluster workers are now spawned with `Process.new` instead of `Process.fork` — the same mechanism Amber V2 uses. `process_count` and master/worker behavior are unchanged. The fix was verified end-to-end: a fresh `amber new` app resolves the released shard, compiles on Crystal 1.21.0, serves requests, and cluster mode spawns real workers.

**Security hardening**, thanks to a series of contributions from [@renich](https://github.com/renich):

- Exception messages are HTML-escaped in the default error response (XSS).
- `amber encrypt` no longer passes your editor command through a shell (command injection).
- `MessageVerifier` / `MessageEncryptor` reject malformed payloads with typed exceptions instead of crashing with `IndexError`.
- New apps ship with a `SecureHeaders` pipe out of the box — `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`, and `Referrer-Policy` on by default, HSTS opt-in — plugged above the error handler so 404 and 403 responses keep their headers too.

**Performance.** Router content-extension matching moved from regex alternation to string operations with a set lookup.

**Working CI again.** The project moved from CircleCI (which had been failing at the infrastructure level) to GitHub Actions: the suite now runs against Crystal 1.20.3 and latest on Linux, latest on macOS, plus a full generated-app build against Postgres.

**A compatibility chart.** [`COMPATIBILITY.md`](https://github.com/amberframework/amber/blob/master/COMPATIBILITY.md) in the repo now documents — with measured results, not guesses — which Crystal versions build which Amber releases. Amber 1.5.0 declares `crystal: ">= 1.20.0, < 2.0"`, which reflects what's actually tested.

## Upgrading

If your app pins `amber` exactly (older generated apps pin `version: 1.4.1`), change your `shard.yml` to:

```yaml
dependencies:
  amber:
    github: amberframework/amber
    version: ~> 1.5.0
```

then `shards update`. Existing apps don't get `SecureHeaders` automatically — add `plug Amber::Pipe::SecureHeaders.new` above `plug Amber::Pipe::Error.new` in `config/routes.cr` to adopt it.

The CLI is available via Homebrew (`brew install amber`) — the formula is updated to 1.5.0.

## Where Amber is headed

1.5.0 exists so that nobody is stranded on a framework that won't compile against a current Crystal. But to be direct about priorities: **the future of Amber is V2.**

The 1.x line is now in maintenance mode — security and compatibility fixes, not new features. All new development is happening on [Amber V2](https://github.com/amberframework/amber/pull/1383), the zero-dependency rewrite currently in beta (`2.0.0-beta.2`): one repo, no third-party shard roulette, typed configuration, built-in jobs and mailers, modernized WebSockets, and a spec suite that runs 2,300+ examples in under three seconds. V2 already runs clean on Crystal 1.21.

If you're starting something new, start it on the V2 beta and tell us what breaks. That feedback is what gets V2 to a final release.

Thanks to everyone who contributed to this release — especially @renich for the security work and the patience while the review backlog got cleared.
