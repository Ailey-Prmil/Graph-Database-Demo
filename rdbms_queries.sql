-- 1. FIND PEOPLE (NOT YET FRIENDS) WITH SIMILAR MUSIC TASTE BASED ON PLAYLIST OVERLAPS
WITH interactions AS (
    SELECT
        p1.id AS person,
        p2.id AS r_id,
        p2.name AS recommendation,
        COUNT(DISTINCT pl1.playlist_id) AS shared_playlist_count,
        0 AS shared_song_count
    FROM rdbms.Playlist_Like pl1
    JOIN rdbms.Playlist_Like pl2 ON pl1.playlist_id = pl2.playlist_id
    JOIN Person p1 ON p1.id = pl1.person_id
    JOIN Person p2 ON p2.id = pl2.person_id
    LEFT JOIN Friendship f ON f.person1_id = p1.id AND f.person2_id = p2.id
    WHERE p1.id IN (1,2) AND p1.id <> p2.id AND f.person1_id IS NULL
    GROUP BY person, p2.id, p2.name
    UNION ALL
    SELECT
        p1.id AS person,
        p2.id AS r_id,
        p2.name AS recommendation,
        0 AS shared_playlist_count,
        COUNT(DISTINCT s1.song_id) AS shared_song_count
    FROM rdbms.Song_Like s1
    JOIN rdbms.Song_Like s2 ON s1.song_id = s2.song_id
    JOIN Person p1 ON p1.id = s1.person_id
    JOIN Person p2 ON p2.id = s2.person_id
    LEFT JOIN Friendship f ON f.person1_id = p1.id AND f.person2_id = p2.id
    WHERE p1.id IN (1,2) AND p1.id <> p2.id AND f.person1_id IS NULL
    GROUP BY person, p2.id, p2.name
),
aggregated AS (
    SELECT
        person,
        r_id,
        recommendation,
        SUM(shared_playlist_count) AS shared_playlist_count,
        SUM(shared_song_count) AS shared_song_count
    FROM interactions
    GROUP BY person, r_id, recommendation
)
SELECT 
    person, 
    r_id, 
    recommendation, 
    (shared_playlist_count + shared_song_count) 
        AS shared_total_count 
FROM aggregated
ORDER BY shared_total_count DESC;

-- 2. FIND PEOPLE WHO LIKES SONG PERFORMED BY THEIR FRIENDS' FOLLOWED ARTISTS AND CONTAINED IN PLAYLISTS CREATED BY THAT FRIEND
SELECT DISTINCT p1.name AS person_name, s.name AS song_name
FROM Person p1
JOIN Friendship f ON f.person1_id = p1.id
JOIN Person p2 ON f.person2_id = p2.id
JOIN Playlist pl ON pl.created_by = p2.id
JOIN Playlist_Song ps ON pl.id = ps.playlist_id
JOIN Song s ON ps.song_id = s.id
JOIN Song_Like sl ON s.id = sl.song_id AND sl.person_id = p1.id
JOIN Perform pf ON s.id = pf.song_id
JOIN Artist a ON pf.artist_id = a.id
JOIN Follow fo ON a.id = fo.artist_id AND fo.person_id = p2.id
WHERE p1.id != p2.id
UNION
SELECT DISTINCT p1.name AS person_name, s.name AS song_name
FROM Person p1
JOIN Friendship f ON f.person2_id = p1.id
JOIN Person p2 ON f.person1_id = p2.id
JOIN Playlist pl ON pl.created_by = p2.id
JOIN Playlist_Song ps ON pl.id = ps.playlist_id
JOIN Song s ON ps.song_id = s.id
JOIN Song_Like sl ON s.id = sl.song_id AND sl.person_id = p1.id
JOIN Perform pf ON s.id = pf.song_id
JOIN Artist a ON pf.artist_id = a.id
JOIN Follow fo ON a.id = fo.artist_id AND fo.person_id = p2.id
WHERE p1.id != p2.id;

-- 3. RECOMMEND SONGS THAT ARE LIKED BY YOUR FRIENDS WHO FOLLOW AT LEAST ONE OF THE SAME ARTISTS YOU DO.SELECT DISTINCT p1.name AS person_name, s.name AS song_name
SELECT DISTINCT p1.name AS person_name, s.name AS song_name, s.id
FROM Person p1
JOIN Friendship f ON f.person1_id = p1.id
JOIN Person p2 ON f.person2_id = p2.id
JOIN Follow fl1 ON fl1.person_id = p1.id
JOIN Follow fl2 ON fl2.person_id = p2.id
JOIN Song_Like sl ON sl.person_id = p2.id
JOIN Song s ON sl.song_id = s.id
WHERE p1.id != p2.id
AND fl1.artist_id = fl2.artist_id
AND NOT EXISTS(
    SELECT *
    FROM Song_Like temp
    WHERE temp.song_id = sl.song_id
    AND temp.person_id = p1.id
)
UNION
SELECT DISTINCT p1.name AS person_name, s.name AS song_name, s.id
FROM Person p1
JOIN Friendship f ON f.person2_id = p1.id
JOIN Person p2 ON f.person1_id = p2.id
JOIN Follow fl1 ON fl1.person_id = p1.id
JOIN Follow fl2 ON fl2.person_id = p2.id
JOIN Song_Like sl ON sl.person_id = p2.id
JOIN Song s ON sl.song_id = s.id
WHERE p1.id != p2.id
AND fl1.artist_id = fl2.artist_id
AND NOT EXISTS(
    SELECT *
    FROM Song_Like temp
    WHERE temp.song_id = sl.song_id
    AND temp.person_id = p1.id
);
