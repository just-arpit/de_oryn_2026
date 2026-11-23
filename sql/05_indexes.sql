-- Workload indexes for the Instagram schema.
SET search_path TO instagram;

-- R06/R16: trigram indexes support substring ILIKE searches; the username
-- prefix uses the separate pattern-ops B-tree below.
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
-- R06: supports the username LIKE 'prefix%' branch after splitting the OR.
CREATE INDEX IF NOT EXISTS idx_users_username_pattern
    ON users (username varchar_pattern_ops);
-- R06: supports the full_name ILIKE '%substring%' branch.
CREATE INDEX IF NOT EXISTS idx_users_full_name_trgm
    ON users USING GIN (full_name public.gin_trgm_ops);
-- R16: supports location substring matches, which can combine with the
-- created_at range index through a bitmap AND when both predicates are selective.
CREATE INDEX IF NOT EXISTS idx_posts_location_trgm
    ON posts USING GIN (location_name public.gin_trgm_ops);

-- R01: equality on author precedes descending creation time; the partial
-- predicate removes archived rows that the feed always filters out.
CREATE INDEX IF NOT EXISTS idx_posts_active_user_created
    ON posts (user_id, created_at DESC)
    WHERE NOT is_archived;

-- R02: same active author feed lookup as R01, limited to one profile.
CREATE INDEX IF NOT EXISTS idx_posts_user_created ON posts (user_id, created_at DESC);

-- R05, R11, R12, R16, R18, R20, R24: timestamp range/equality probes
-- first; supports June/2026 filters and joins without applying a function
-- to the indexed timestamp.
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts (created_at);

-- R05/R12: hashtag is the selective equality predicate, followed by post_id
-- for the join to posts; this also allows an index-only association lookup.
CREATE INDEX IF NOT EXISTS idx_post_hashtags_hashtag_post
    ON post_hashtags (hashtag_id, post_id);

-- R04/R13: post_id and parent_comment_id are equality probes; created_at
-- supplies the top-level comment order. R04 finds comments on one post.
CREATE INDEX IF NOT EXISTS idx_comments_post_parent_created
    ON comments (post_id, parent_comment_id, created_at);

-- R04/R13: direct child-comment existence/count lookup by parent id.
CREATE INDEX IF NOT EXISTS idx_comments_parent_comment
    ON comments (parent_comment_id);

-- R22: only hidden comments are indexed, in the requested newest-first order.
CREATE INDEX IF NOT EXISTS idx_comments_hidden_created
    ON comments (created_at DESC) WHERE is_hidden;

-- R17: only first media items longer than 60 seconds are relevant; post_id
-- supports the join and duration_sec is available from the index.
CREATE INDEX IF NOT EXISTS idx_post_media_long_first
    ON post_media (post_id) INCLUDE (duration_sec)
    WHERE position = 1 AND duration_sec > 60;

-- R09/W06: equality on target and status, then order by newest request.
CREATE INDEX IF NOT EXISTS idx_follows_followee_status_created
    ON follows (followee_id, status, created_at DESC);

-- R14/R15/R21: target and accepted status narrow follower rows; follower_id
-- covers selected IDs and supports anti-joins/counts. W06 also finds pending
-- rows via the leading target/status keys.
CREATE INDEX IF NOT EXISTS idx_follows_followee_status_follower
    ON follows (followee_id, status, follower_id);

-- R07/R19/R21: post_id equality is the lookup key; created_at supports R07's
-- display order and user_id is covered for joins/counts.
CREATE INDEX IF NOT EXISTS idx_likes_post_created_user
    ON likes (post_id, created_at DESC, user_id);

-- R10/R24: story creation time is the range predicate and order key.
CREATE INDEX IF NOT EXISTS idx_stories_created_at ON stories (created_at);

-- W05: expiry cutoff selects rows to delete.
CREATE INDEX IF NOT EXISTS idx_stories_expires_at ON stories (expires_at);
