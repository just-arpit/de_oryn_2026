# Optimization report

## Method

The before values are the original three-run baseline averages recorded in [03_baseline_timings.md](03_baseline_timings.md), measured before the workload indexes were present. The after values are three-run averages from `./benchmarks/run_benchmark.sh de optimized 3 sql/06_optimized_queries.sql`, using the indexes in `sql/05_indexes.sql`. Times are PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)` execution times in milliseconds.

The requested fresh `baseline` run was performed after the optimized indexes were already installed in the database. It is saved in `benchmarks/results/baseline/summary.csv`, but is not used as the before measurement because it is not an unindexed baseline.

## Before and after

| Query | Before (ms) | After (ms) | Change |
|---|---:|---:|---:|
| R01 | 6.581 | 0.528 | 92.0% faster |
| R02 | 3.448 | 0.066 | 98.1% faster |
| R03 | 0.029 | 0.028 | 3.4% faster |
| R04 | 8.743 | 0.114 | 98.7% faster |
| R05 | 9.823 | 0.888 | 91.0% faster |
| R06 | 8.626 | 9.755 | 13.1% slower |
| R07 | 6.561 | 0.088 | 98.7% faster |
| R08 | 0.129 | 0.131 | 1.6% slower |
| R09 | 2.316 | 0.102 | 95.6% faster |
| R10 | 2.223 | 0.209 | 90.6% faster |
| R11 | 6.951 | 5.388 | 22.5% faster |
| R12 | 10.058 | 0.791 | 92.1% faster |
| R13 | 21.234 | 0.088 | 99.6% faster |
| R14 | 2.442 | 0.042 | 98.3% faster |
| R15 | 29.757 | 30.266 | 1.7% slower |
| R16 | 4.465 | 0.339 | 92.4% faster |
| R17 | 8.573 | 8.638 | 0.8% slower |
| R18 | 4.523 | 0.867 | 80.8% faster |
| R19 | 5478.076 | 74.816 | 98.6% faster |
| R20 | 12.430 | 10.113 | 18.6% faster |
| R21 | 3.799 | 0.114 | 97.0% faster |
| R22 | 4.711 | 1.438 | 69.5% faster |
| R23 | 0.024 | 0.035 | 45.8% slower |
| R24 | 1.452 | 0.515 | 64.5% faster |
| W01 | 0.431 | 0.445 | 3.2% slower |
| W02 | 0.487 | 0.558 | 14.6% slower |
| W03 | 0.126 | 0.116 | 7.9% faster |
| W04 | 68.314 | 74.342 | 8.8% slower |
| W05 | 6.552 | 6.418 | 2.0% faster |
| W06 | 2.490 | 0.241 | 90.3% faster |

## What changed

The read-query average fell from **234.874 ms** to **6.057 ms** (97.4% lower). Most of the gain came from indexes that let PostgreSQL visit a small matching range instead of scanning whole tables: active posts by author and time (R01–R02), comments by post and parent plus replies (R04, R13), likes by post (R07), pending/accepted follows by target (R09, R14, R21), and date ranges for posts and stories (R05, R10, R12, R16, R18, R24). The hidden-comments partial index also reduced the page scan in R22.

R19 improved substantially because the rewrite aggregates posts and likes once by author rather than running a likes-count subquery separately for every verified account. R13 also uses `NOT EXISTS`, which can use the parent-comment index directly. R10 and R18 now filter timestamps with half-open ranges, allowing ordinary timestamp indexes to serve the date filters.

Not every query improved. R06 still scans users because its contains-name search (`ILIKE '%...%'`) has no trigram index. R15 must count accepted follows across accounts, and R17 still scans posts to apply its type/year and media-duration conditions. The write-query average changed from **13.067 ms** to **13.687 ms** (+4.7%), reflecting the extra index maintenance cost; some targeted writes such as W06 improved because the pending-follow lookup is indexed.

The timing differences are from one three-run sample per phase, so small changes can reflect run-to-run variation. The largest read improvements are also visible in the saved query plans under `benchmarks/results/optimized/`.
