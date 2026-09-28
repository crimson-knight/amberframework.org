---
title: "ActiveRecord parity"
section: "guides/models/grant"
order: 80
description: "Grant's ActiveRecord 8 feature tracker, PostgreSQL evidence, and current gaps"
---

# ActiveRecord parity

> **Tracker snapshot:** This page follows the generated Grant parity report
> checked into source commit `70ac8beaa172f03c389bacaff06cd8f3c520805c`.
> In that source snapshot, `Grant::VERSION` is `0.23.4`; the report's own
> metadata says its evidence was generated for implementation commit
> `38ce96160323c2cdc4488d03f1d9e14315c59847`. The counts below are that
> committed report, not a new calculation for commit `70ac8be`.
> The report records baseline score source commit `32b69d8`.

Grant tracks how its public model API compares with Rails ActiveRecord 8. Each
row names a feature, its status, and the evidence or remaining gap. The
[generated `docs/PARITY.md` at commit `70ac8be`](https://github.com/crimson-knight/grant/blob/70ac8beaa172f03c389bacaff06cd8f3c520805c/docs/PARITY.md)
is the source of truth for this snapshot.

## How status is scored

- **Complete** means a named spec for the feature passes against PostgreSQL.
  The report lists the spec path for each complete row.
- **Partial** means Grant implements some of the feature, with parity gaps or
  incomplete PostgreSQL evidence described in the report.
- **Missing** means no equivalent is available in the tracked API; the report
  assigns each missing item a priority.
- **N/A** means ActiveRecord 8 does not provide the feature, with the reason
  recorded in the report.

The generator checks that every complete row has a named spec path and that
the file exists. It does not run that spec; maintainers run the evidence suite
on PostgreSQL before marking a feature complete.

## Headline and counts

For Grant `0.23.4`, the committed report records **150 complete / 48 partial /
30 missing / 6 not applicable**. That is **65.8%** of **228 applicable**
features complete, out of **234** tracked.

| Area | Complete | Partial | Missing | N/A | Applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| Adapters & connections | 9 | 7 | 1 | 0 | 17 |
| Associations | 19 | 6 | 3 | 0 | 28 |
| Core persistence & attributes | 26 | 5 | 5 | 0 | 36 |
| Infrastructure (locking, encryption, instrumentation, …) | 3 | 5 | 5 | 1 | 13 |
| Migrations & schema | 2 | 11 | 3 | 0 | 16 |
| Multiple databases & sharding | 14 | 10 | 3 | 3 | 27 |
| Query interface | 39 | 3 | 5 | 2 | 47 |
| Raw SQL | 8 | 0 | 0 | 0 | 8 |
| Validations & callbacks | 30 | 1 | 5 | 0 | 36 |
| **Total** | **150** | **48** | **30** | **6** | **228** |

## Prioritized missing features

The following list preserves the priorities and gaps in the generated report:

1. **create_or_find_by (unique-constraint race-safe create)** (Core persistence & attributes) — No equivalent class method exists.
2. **create_with relation defaults** (Core persistence & attributes) — No relation `#create_with` implementation exists.
3. **Store accessors (`store_accessor` for JSON column sub-keys)** (Core persistence & attributes) — No store/store_accessor macro or per-key JSON accessors in current src.
4. **Dirty tracking before save (`changes_to_save` / `will_save_change_to_attribute?`)** (Core persistence & attributes) — ActiveRecord pre-save dirty-state helper names are absent.
5. **attribute_before_type_cast** (Core persistence & attributes) — No raw-before-cast attribute reader exists.
6. **collection singular IDs accessor (`post_ids` / `user_ids=`)** (Associations) — No equivalent found in current src.
7. **HABTM (`has_and_belongs_to_many`) equivalent** (Associations) — Grant has no HABTM association macro.
8. **delegated types** (Associations) — No `delegated_type` macro or generated delegated-type helpers exist.
9. **Unified validates macro (AR style: `validates :field, presence: true, length: {min:2}`)** (Validations & callbacks) — No single unified validates macro; separate validator macros are required.
10. **errors.details (AR8 structured type+options per error)** (Validations & callbacks) — Errors expose messages but no structured AR details/type/options API.
11. **strict: option on validators (raises instead of adding to errors)** (Validations & callbacks) — No strict validation option that raises on validation failure.
12. **run_callbacks (manual callback execution)** (Validations & callbacks) — No public `run_callbacks(:event)` API exists.
13. **after_all_transactions_commit** (Validations & callbacks) — No global outermost-commit callback API exists.
14. **query cache (within-request result memoization)** (Query interface) — No `Model.cache`/`uncached` or request query-cache implementation exists.
15. **from (custom FROM clause / subquery as table)** (Query interface) — No relation `#from` implementation exists.
16. **readonly relations (prevent persistence on fetched records)** (Query interface) — No equivalent found in current src.
17. **calculate (generic aggregation method)** (Query interface) — Named aggregate methods exist; the AR `calculate` API is absent.
18. **optimizer hints (e.g. FORCE INDEX for MySQL)** (Query interface) — No ActiveRecord-style `optimizer_hints` relation API exists.
19. **Prepared statements / statement caching** (Adapters & connections) — No per-connection prepared-statement cache exists.
20. **Fixtures / test helpers (ActiveRecord::FixtureSet equivalent)** (Infrastructure (locking, encryption, instrumentation, …)) — No fixture loader or transactional test helper equivalent exists.
21. **Schema dump / `schema.rb` equivalent** (Migrations & schema) — No schema dump/load format or schema cache artifact exists.
22. **`alter_table` / `change_column` / `add_column` at runtime via Grant DSL** (Migrations & schema) — No ALTER TABLE migration DSL exists.
23. **`rename_table` DSL** (Migrations & schema) — No rename_table migration DSL exists.
24. **Shard key immutability enforcement** (Multiple databases & sharding) — Saving a changed shard key is not guarded.
25. **Cross-shard join detection** (Multiple databases & sharding) — No cross-shard join guard exists.
26. **Automatic role-switching middleware (DatabaseSelector equivalent)** (Multiple databases & sharding) — Grant has no Amber request middleware that automatically routes reads and writes.
27. **Configurable optimistic-locking column (`locking_column`)** (Infrastructure (locking, encryption, instrumentation, …)) — Grant does not expose ActiveRecord `locking_column` customization.
28. **`query_constraints` composite model keys** (Infrastructure (locking, encryption, instrumentation, …)) — No `query_constraints` model API exists.
29. **Schema cache / schema introspection API** (Infrastructure (locking, encryption, instrumentation, …)) — No ActiveRecord schema-cache equivalent is exposed.
30. **QueryLogs with context tags (SQL comment injection)** (Infrastructure (locking, encryption, instrumentation, …)) — Query annotate works; request-context QueryLogs tags are absent.

## Regenerating the report

For a release, maintainers update `docs/parity/parity.json` with the feature
statuses, named PostgreSQL spec evidence, gaps, and priorities, and set
`verified_against_commit` to the tested implementation commit. They then bump
the version in `shard.yml` and run `crystal-alpha run scripts/generate_parity.cr`
from the Grant repository root. The generator
writes `docs/PARITY.md`, `src/grant/parity.cr`, and the versioned
`docs/parity/<version>.md` snapshot. It refuses to overwrite an existing
versioned snapshot unless maintainers explicitly pass `--refresh-snapshot`.
