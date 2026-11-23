# Baseline timings

Measured with `./benchmarks/run_benchmark.sh de baseline 3` on PostgreSQL 18.6. Every query was run three times with `EXPLAIN (ANALYZE, BUFFERS)`; write statements ran inside `BEGIN`/`ROLLBACK`. Values are execution time in milliseconds. The tuning indexes were removed during this clean baseline run.

| SQL query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Scan type | Why it is slow or fast |
|---|---|---:|---:|---:|---:|---|---|
| R01: Home feed: the latest 30 posts from accounts user 1042 follows | READ | 6.760 | 6.311 | 5.800 | 6.290 | Seq Scan on posts | Index Scan using follows_pkey on follows | Seq scan of posts and feed sort; no author/time index. |
| R02: Profile grid: user 217's latest 12 posts | READ | 3.151 | 3.138 | 2.938 | 3.076 | Seq Scan on posts | Seq scan and sort over posts for one profile. |
| R03: Open a profile by username | READ | 0.031 | 0.027 | 0.028 | 0.029 | Index Scan using users_username_key on users | Unique username lookup is already indexed. |
| R04: Post page: top-level comments on post 59689 with the number of replies each has | READ | 8.591 | 7.616 | 7.587 | 7.931 | Seq Scan on comments | Full comments scan plus reply join/group and sort. |
| R05: Explore: top posts tagged #travel in June 2026 | READ | 9.570 | 8.912 | 9.099 | 9.194 | Seq Scan on post_hashtags | Seq Scan on hashtags | Index Scan using posts_pkey on posts | Scans tag links/posts then sorts matching likes. |
| R06: Search bar: accounts whose username starts with "karan" or whose name contains "karan sharma" | READ | 8.934 | 8.509 | 9.310 | 8.918 | Seq Scan on users | OR predicates with a leading-wildcard name search force a user scan. |
| R07: "Liked by": people who liked post 59689, showing whether user 1042 follows them | READ | 6.070 | 6.178 | 6.282 | 6.177 | Seq Scan on likes | Index Scan using users_pkey on users | Index Scan using follows_pkey on follows | Scans likes to find one post, then joins users/follows and sorts. |
| R08: "Suggested for you": friends-of-friends of user 1042 that 1042 doesn't follow yet | READ | 0.132 | 0.125 | 0.122 | 0.126 | Index Scan using follows_pkey on follows | Index Only Scan using follows_pkey on follows | PK lookups restrict the two follow traversals; already selective. |
| R09: Follow requests screen: pending requests for private account 338 | READ | 2.697 | 2.476 | 2.416 | 2.530 | Index Scan using follows_pkey on follows | Index Scan using users_pkey on users | PK lookup by follower direction cannot efficiently find requests by target. |
| R10: Story highlights: stories posted in June 2026 by accounts user 1042 follows | READ | 2.501 | 2.197 | 2.145 | 2.281 | Seq Scan on stories | Index Scan using follows_pkey on follows | Scans stories and applies DATE() to the timestamp. |
| R11: Creator insights: engagement rate (likes + comments per follower) of creators' 2026 posts, top 20 | READ | 7.158 | 7.028 | 7.973 | 7.386 | Seq Scan on posts | Seq Scan on users | Scans posts/users and groups creator activity. |
| R12: Trending: hashtags used most in the last 7 days of June 2026 | READ | 3.103 | 2.979 | 3.075 | 3.052 | Seq Scan on posts | Index Only Scan using post_hashtags_pkey on post_hashtags | Seq Scan on hashtags | Scans post hashtag links/posts to aggregate trending tags. |
| R13: Creator tools: comments on post 59689 that nobody has replied to yet | READ | 21.096 | 20.374 | 20.450 | 20.640 | Seq Scan on comments | NOT IN subquery scans comments; NULL makes the query return no rows. |
| R14: "Not following back": accounts that follow user 217 whom 217 doesn't follow | READ | 2.583 | 2.564 | 2.380 | 2.509 | Index Scan using follows_pkey on follows | Index Only Scan using follows_pkey on follows | PK supports relationship probes, but reverse target lookup remains broad. |
| R15: Data quality: verified or creator accounts whose stored follower count is wrong | READ | 28.028 | 27.997 | 27.775 | 27.933 | Seq Scan on follows | Seq Scan on users | Must count accepted follows across users; broad aggregation. |
| R16: Places: posts tagged with a location containing "goa" in June 2026 | READ | 4.507 | 4.377 | 4.245 | 4.376 | Seq Scan on posts | Scans posts for a substring location and date range. |
| R17: Reels team: creators' reels longer than 60 seconds posted in 2026 | READ | 8.691 | 8.611 | 8.524 | 8.609 | Seq Scan on posts | Index Scan using users_pkey on users | Index Scan using post_media_pkey on post_media | Scans posts and applies EXTRACT(YEAR) plus media/user filters. |
| R18: Content analytics: new posts per day and type in June 2026 | READ | 4.363 | 4.385 | 4.367 | 4.372 | Seq Scan on posts | DATE() prevents a direct timestamp range scan; scans posts and groups. |
| R19: Verified-account report: last post time and total likes received by every verified account | READ | 5279.163 | 5336.303 | 5436.076 | 5350.514 | Seq Scan on users | Seq Scan on posts | Seq Scan on likes | Correlated subqueries rescan posts/likes for every verified user. |
| R20: Content analytics: 10 most-commented posts of June 2026 (counting real comments) | READ | 13.304 | 12.332 | 12.449 | 12.695 | Seq Scan on comments | Seq Scan on posts | Scans comments and joins posts to filter June activity. |
| R21: Creator tools: "ghost followers" of user 217 (followers who never liked any of 217's posts) | READ | 3.852 | 3.763 | 3.816 | 3.810 | Index Scan using follows_pkey on follows | Index Only Scan using likes_pkey on likes | Index Scan using posts_pkey on posts | Repeated anti-join checks across the user’s accepted followers. |
| R22: Moderation console: hidden comments, newest first, page 61 (25 per page) | READ | 4.630 | 4.724 | 4.718 | 4.691 | Seq Scan on comments | Scans hidden status and sorts/offsets comments. |
| R23: Like button state: has user 1042 liked post 59689? | READ | 0.052 | 0.025 | 0.030 | 0.036 | Index Only Scan using likes_pkey on likes | Composite PK gives a direct existence lookup. |
| R24: Story insights: total story views per account in the last 30 days, top 20 | READ | 1.570 | 1.485 | 1.517 | 1.524 | Seq Scan on stories | Scans and aggregates stories in the date window. |
| W01: Publish a new photo post | WRITE | 0.407 | 0.382 | 0.403 | 0.397 | (no scan) | Insert is direct; FK check dominates small write cost. |
| W02: Double-tap: user 1042 likes post 59689 | WRITE | 0.480 | 0.450 | 0.442 | 0.457 | (no scan) | Composite PK handles conflict check; FK checks dominate. |
| W03: Keep the counter in sync after the like | WRITE | 0.311 | 0.123 | 0.122 | 0.185 | Index Scan using posts_pkey on posts | PK locates the single post row. |
| W04: Nightly job: recompute every user's follower count | WRITE | 67.064 | 67.925 | 67.027 | 67.339 | Seq Scan on users | Seq Scan on follows | Must scan/group accepted follows for all users. |
| W05: Housekeeping: delete stories that expired before June 2026 | WRITE | 6.449 | 6.689 | 6.565 | 6.568 | Seq Scan on stories | Scans stories to locate expired rows. |
| W06: Private account 338 accepts all pending follow requests | WRITE | 2.450 | 2.492 | 2.504 | 2.482 | Index Scan using follows_pkey on follows | PK starts with follower_id, not followee_id/status. |
| **Total (sum of all 30)** |  | 5507.698 | 5560.497 | 5660.185 | 5576.127 |  |  |
