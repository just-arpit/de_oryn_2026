-- Run from the repository root after extracting seed_data.zip.
SET search_path TO instagram;

\copy users FROM 'seed_data/users.csv' WITH (FORMAT csv, HEADER true)
\copy follows FROM 'seed_data/follows.csv' WITH (FORMAT csv, HEADER true)
\copy hashtags FROM 'seed_data/hashtags.csv' WITH (FORMAT csv, HEADER true)
\copy posts FROM 'seed_data/posts.csv' WITH (FORMAT csv, HEADER true)
\copy post_hashtags FROM 'seed_data/post_hashtags.csv' WITH (FORMAT csv, HEADER true)
\copy post_media FROM 'seed_data/post_media.csv' WITH (FORMAT csv, HEADER true)
\copy likes FROM 'seed_data/likes.csv' WITH (FORMAT csv, HEADER true)
\copy comments FROM 'seed_data/comments.csv' WITH (FORMAT csv, HEADER true)
\copy stories FROM 'seed_data/stories.csv' WITH (FORMAT csv, HEADER true)

ANALYZE;
