// 1. FIND PEOPLE (NOT YET FRIENDS) WITH SIMILAR MUSIC TASTE BASED ON PLAYLIST OVERLAPS
MATCH (me:Person)<-[:LIKED_BY]-(item)-[:LIKED_BY]->(other:Person)
WHERE me <> other AND NOT (me)-[:FRIENDS_WITH]-(other) AND me.id IN [1, 2]
WITH me, other, COUNT(DISTINCT item) AS total_shared_likes
ORDER BY total_shared_likes DESC
RETURN other.name AS recommendation, total_shared_likes;

// 2. FIND PEOPLE WHO LIKES SONG PERFORMED BY THEIR FRIENDS' FOLLOWED ARTISTS AND CONTAINED IN PLAYLISTS CREATED BY THAT FRIEND
MATCH
  (p1:Person)-[:FRIENDS_WITH]-
  (p2:Person)-[:CREATED]->
  (pl:Playlist)-[:CONTAINS]->
  (s:Song)-[:LIKED_BY]->
  (p1)
MATCH (s)-[:PERFORMED_BY]->(a:Artist)<-[:FOLLOWS]-(p2)
RETURN DISTINCT p1.name AS person_name, s.name AS song_name;

// 3. RECOMMEND SONGS THAT ARE LIKED BY YOUR FRIENDS WHO FOLLOW AT LEAST ONE OF THE SAME ARTISTS YOU DO.
MATCH (person1:Person)-[:FRIENDS_WITH]-(person2:Person)
MATCH (person1)-[:FOLLOWS]->(commonArtist:Artist)<-[:FOLLOWS]-(person2)
MATCH (person2)<-[:LIKED_BY]-(song:Song)
WHERE NOT (person1)<-[:LIKED_BY]-(song)
RETURN DISTINCT person1, song.id AS songId, song.name AS songName