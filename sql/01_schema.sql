-- Instagram seed-data schema (PostgreSQL 15+).
-- Only relational constraints are defined here; no tuning indexes are added.
CREATE SCHEMA instagram;
SET search_path TO instagram;

CREATE TABLE users (
    user_id          INTEGER PRIMARY KEY,
    username         VARCHAR(30) NOT NULL UNIQUE
                     CHECK (username ~ '^[a-z0-9._]{1,30}$'),
    full_name        VARCHAR(100) NOT NULL,
    email            VARCHAR(254) NOT NULL UNIQUE,
    bio              TEXT,
    account_type     VARCHAR(10) NOT NULL
                     CHECK (account_type IN ('PERSONAL', 'CREATOR', 'BUSINESS')),
    is_private       BOOLEAN NOT NULL,
    is_verified      BOOLEAN NOT NULL,
    followers_count  INTEGER NOT NULL CHECK (followers_count >= 0),
    following_count  INTEGER NOT NULL CHECK (following_count >= 0),
    created_at       TIMESTAMPTZ NOT NULL,
    CHECK (account_type <> 'BUSINESS' OR NOT is_private)
);

CREATE TABLE follows (
    follower_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    followee_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    status      VARCHAR(10) NOT NULL CHECK (status IN ('ACCEPTED', 'PENDING')),
    created_at  TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (follower_id, followee_id),
    CHECK (follower_id <> followee_id)
);

CREATE TABLE hashtags (
    hashtag_id INTEGER PRIMARY KEY,
    tag        VARCHAR(30) NOT NULL UNIQUE
               CHECK (tag ~ '^[a-z0-9_]+$')
);

CREATE TABLE posts (
    post_id       INTEGER PRIMARY KEY,
    user_id       INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    post_type     VARCHAR(10) NOT NULL CHECK (post_type IN ('PHOTO', 'VIDEO', 'CAROUSEL', 'REEL')),
    caption       TEXT,
    location_name VARCHAR(100),
    like_count    INTEGER NOT NULL CHECK (like_count >= 0),
    comment_count INTEGER NOT NULL CHECK (comment_count >= 0),
    is_archived   BOOLEAN NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL
);

CREATE TABLE post_hashtags (
    post_id    INTEGER NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    hashtag_id INTEGER NOT NULL REFERENCES hashtags(hashtag_id) ON DELETE RESTRICT,
    PRIMARY KEY (post_id, hashtag_id)
);

CREATE TABLE post_media (
    post_id      INTEGER NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    position     SMALLINT NOT NULL CHECK (position BETWEEN 1 AND 10),
    media_type   VARCHAR(5) NOT NULL CHECK (media_type IN ('IMAGE', 'VIDEO')),
    media_url    TEXT NOT NULL,
    width        SMALLINT NOT NULL CHECK (width > 0),
    height       SMALLINT NOT NULL CHECK (height > 0),
    duration_sec NUMERIC(6,1),
    PRIMARY KEY (post_id, position),
    CHECK ((media_type = 'VIDEO' AND duration_sec IS NOT NULL AND duration_sec > 0)
        OR (media_type = 'IMAGE' AND duration_sec IS NULL))
);

CREATE TABLE likes (
    user_id    INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    post_id    INTEGER NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, post_id)
);

CREATE TABLE comments (
    comment_id        INTEGER PRIMARY KEY,
    post_id           INTEGER NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    user_id           INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    parent_comment_id INTEGER REFERENCES comments(comment_id) ON DELETE CASCADE,
    body              TEXT NOT NULL,
    is_hidden         BOOLEAN NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL
);

CREATE TABLE stories (
    story_id   INTEGER PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    media_type VARCHAR(5) NOT NULL CHECK (media_type IN ('IMAGE', 'VIDEO')),
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    view_count INTEGER NOT NULL CHECK (view_count >= 0),
    CHECK (expires_at = created_at + INTERVAL '24 hours')
);
