-- 1. FIND PEOPLE (NOT YET FRIENDS) WITH SIMILAR MUSIC TASTE BASED ON PLAYLIST OVERLAPS
SELECT
    p1.name AS person,
    p2.name AS recommendation,
    COUNT(DISTINCT pl1.playlist_id) AS shared_playlist_count,
    COUNT(DISTINCT sl1.song_id) AS shared_song_count,
    COUNT(DISTINCT pl1.playlist_id) + COUNT(DISTINCT sl1.song_id) AS total_count
FROM Person p1
JOIN Person p2
JOIN rdbms.Playlist_Like pl1 ON p1.id = pl1.person_id
JOIN rdbms.Playlist_Like pl2 ON p2.id = pl2.person_id
JOIN rdbms.Song_Like sl1 on p1.id = sl1.person_id
JOIN rdbms.Song_Like sl2 on p2.id = sl2.person_id
WHERE NOT EXISTS (
    SELECT *
    FROM Friendship
    WHERE person1_id = p1.id
    AND person2_id = p2.id
)
AND p1.id = 1 -- me : Change id for each user
AND pl1.playlist_id = pl2.playlist_id
AND sl1.song_id = sl2.song_id
AND p1.id <> p2.id
GROUP BY p2.id, recommendation
ORDER BY total_count DESC;

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
