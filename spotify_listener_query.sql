--OVERALL LISTENING TIME PER YEAR
With year_listening_time as (
SELECT EXTRACT(YEAR FROM start_listening_time) as years, COUNT(DISTINCT listening_id) as total_listening_session,
COUNT(DISTINCT user_id) as total_listeners, SUM(end_listening_time - start_listening_time) as total_listening_time
FROM listening_table
GROUP BY EXTRACT(YEAR FROM start_listening_time)
),
overall_time as (
SELECT SUM(end_listening_time - start_listening_time) as overall
FROM listening_table
)
SELECT y.years, y.total_listening_session, y.total_listeners, y.total_listening_time, o.overall,
ROUND(( EXTRACT(EPOCH FROM y.total_listening_time) / EXTRACT(EPOCH FROM o.overall) ) * 100, 2) as time_percentage
FROM year_listening_time y CROSS JOIN overall_time o;


--GENDER TOTAL LISTENING HOURS, LISTENING SESSION AND PERCENTAGE IN 2026

With gender_hours as (
SELECT u.gender, SUM(l.end_listening_time - l.start_listening_time) as total_hours,
COUNT(DISTINCT l.listening_id) as total_listening_session
FROM listening_table l JOIN user_table u ON l.user_id = u.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.gender
),
total_hours as (
SELECT SUM(end_listening_time - start_listening_time) as overall_hours
FROM listening_table l 
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
)
SELECT g.gender, g.total_listening_session, g.total_hours, t.overall_hours,
ROUND((EXTRACT (EPOCH FROM g.total_hours) / EXTRACT (EPOCH FROM t.overall_hours)) * 100, 2) as gender_hours_percentage
FROM gender_hours g CROSS JOIN total_hours t;


--PERCENTAGE OF GENDER LISTENER IN EACH YEAR
WITH year_total_gender as (
SELECT EXTRACT(YEAR FROM l.start_listening_time) as years, 
u.gender, COUNT(DISTINCT u.user_id) as total_gender_number
FROM listening_table l JOIN user_table u ON l.user_id = u.user_id
GROUP BY EXTRACT(YEAR FROM l.start_listening_time), u.gender
),
overall_listener as (
SELECT EXTRACT(YEAR FROM l.start_listening_time) as yearss,
COUNT(DISTINCT u.user_id) as total_listener
FROM listening_table l JOIN user_table u ON l.user_id = u.user_id
GROUP BY EXTRACT(YEAR FROM l.start_listening_time)
)
SELECT y.years, y.gender, y.total_gender_number,
o.total_listener, ROUND((y.total_gender_number::NUMERIC / o.total_listener) * 100, 2) as gender_percentage
FROM year_total_gender y JOIN overall_listener o ON y.years = o.yearss


--YEARLY PERCENTAGE GROWTH OF LISTENING SESSION
WITH yearly_session as (
SELECT EXTRACT(YEAR FROM start_listening_time) as years, COUNT(DISTINCT listening_id) as total_listening_session
FROM listening_table
GROUP BY EXTRACT(YEAR FROM start_listening_time)
),
lagged as (
SELECT years, total_listening_session as this_year_session,
LAG(total_listening_session) OVER(ORDER BY years) as previous_year_session
FROM yearly_session
)
SELECT years, this_year_session, previous_year_session,
CASE
WHEN previous_year_session = 0 OR previous_year_session IS NULL THEN NULL
ELSE ROUND((this_year_session::NUMERIC - previous_year_session) / previous_year_session * 100, 2)
END  as listening_percentage_growth
FROM lagged;


-- TOTAL AVERAGE LISTENING TIME PER SESSION/EVENT
SELECT EXTRACT(YEAR FROM start_listening_time) as years, AVG(end_listening_time - start_listening_time) as average_listening_time
FROM listening_table
GROUP BY EXTRACT(YEAR FROM start_listening_time);


--CALCULATING YEARLY PERCENTAGE CHANGES IN AVERAGE LISTENING TIME 

WITH year_avg_seconds as (
SELECT
    EXTRACT(YEAR FROM start_listening_time) AS years,
    ROUND(
        AVG(EXTRACT(EPOCH FROM
            (end_listening_time - start_listening_time)
        ))::numeric,
        2
    ) AS average_listening_time_seconds
FROM listening_table
GROUP BY EXTRACT(YEAR FROM start_listening_time)
ORDER BY years
),
lagged_sec as (
SELECT years, average_listening_time_seconds as year_2026_avg_second,
LAG(average_listening_time_seconds) OVER(ORDER BY years) as year_2025_avg_second
FROM year_avg_seconds
)
SELECT years, year_2026_avg_second, year_2025_avg_second,
CASE
WHEN year_2025_avg_second = 0 OR year_2025_avg_second IS NULL THEN NULL
ELSE ROUND((year_2026_avg_second - year_2025_avg_second) / year_2025_avg_second * 100, 2) 
END as yearly_percentage_of_avg_time_seconds
FROM lagged_sec;


-- NUMBER OF LISTENER AND GROWTH LISTENER PERCENTAGE EACH YEAR
WITH years_listener as(
SELECT EXTRACT(YEAR FROM start_listening_time) as years,
COUNT(DISTINCT user_id) as number_of_listener
FROM listening_table
GROUP BY EXTRACT(YEAR FROM start_listening_time)
ORDER BY years
),
lagged_listener as (
SELECT years, number_of_listener as this_year_listener,
LAG(number_of_listener) OVER(ORDER BY years) as previous_year_listener
FROM years_listener
)
SELECT years, this_year_listener, previous_year_listener,
CASE
WHEN previous_year_listener = 0 OR previous_year_listener = NULL THEN NULL 
ELSE ROUND((this_year_listener::NUMERIC - previous_year_listener) / previous_year_listener * 100, 2)
END as growth_listener_percentage
FROM lagged_listener
WHERE previous_year_listener IS NOT NULL;


--TOTAL AVERAGE LISTENING SESSION PER LISTENER PER YEAR

WITH yearly_listening AS (
    SELECT
        EXTRACT(YEAR FROM start_listening_time) AS years,
        COUNT(DISTINCT listening_id) AS total_sessions,
        COUNT(DISTINCT user_id) AS unique_listeners
    FROM listening_table
    GROUP BY EXTRACT(YEAR FROM start_listening_time)
)
SELECT
    years,
    total_sessions,
    unique_listeners,
    ROUND(
        total_sessions::numeric / unique_listeners,
        2
    ) AS avg_sessions_per_listener
FROM yearly_listening
ORDER BY years;


-- MONTHLY TOTAL LISTENING SESSION/EVENT & LISTENER IN 2026
SELECT DATE_TRUNC('month', start_listening_time) as months, COUNT(listening_id) as total_listening_session,
COUNT(DISTINCT user_id) as total_listening
FROM listening_table
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
GROUP BY DATE_TRUNC('month', start_listening_time)
ORDER BY months


-- UNIQUE USER ID ADDED PER MONTH IN 2026
With first_user_played as (
SELECT user_id,
MIN(start_listening_time) as first_played_song
FROM listening_table
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
GROUP BY user_id
)
SELECT DATE_TRUNC('month', first_played_song) as months,
COUNT(*) as unique_user
FROM first_user_played
GROUP BY DATE_TRUNC('month', first_played_song)
ORDER BY months


--RETURNING LISTENERS PERCENTAGE FROM 2025 TO 2026
With returning_listeners as (
SELECT COUNT(DISTINCT l.user_id) AS returning_user_id
FROM listening_table l
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
  AND l.user_id IN (
      SELECT DISTINCT user_id
      FROM listening_table
      WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
  )
),
overall_listeners as (
SELECT COUNT(DISTINCT user_id) as overall_2025_listeners
FROM listening_table l 
WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
)
SELECT r.returning_user_id, ol.overall_2025_listeners,
ROUND((r.returning_user_id::NUMERIC / ol.overall_2025_listeners) * 100, 2) as return_listeners_percentage
FROM returning_listeners r CROSS JOIN overall_listeners ol;


-- NUMBER OF INACTIVE USER FROM 2025 TO 2026
SELECT COUNT(DISTINCT l.user_id) as users2025
FROM listening_table l
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2025
AND l.user_id NOT IN (
SELECT DISTINCT user_id
FROM listening_table 
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
);


--HOW MANY NEW LISTENER OF 2026 AND ITS PERCENTAGE

WITH new_listeners as (
SELECT COUNT(DISTINCT l.user_id) AS new_2026_users
FROM listening_table l
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
  AND l.user_id NOT IN (
      SELECT DISTINCT user_id
      FROM listening_table
      WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
  )
),
overall_2026_listeners as (
SELECT COUNT(DISTINCT user_id) as overall_listeners_2026
FROM listening_table 
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
)
SELECT n.new_2026_users, ov.overall_listeners_2026,
ROUND((n.new_2026_users::NUMERIC / ov.overall_listeners_2026) * 100, 2) as new_listeners_percentage
FROM new_listeners n CROSS JOIN overall_2026_listeners ov;


-- AGE BUCKET PERCENTAGE OF NEW LISTENER IN 2026
WITH added_user as( 
SELECT DISTINCT u.user_id, u.age FROM  user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
AND u.user_id NOT IN (
SELECT user_id FROM listening_table
WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
)
),
grouping_user as (
SELECT user_id,
CASE
WHEN age BETWEEN 19 AND 26 THEN '19-26'
WHEN age BETWEEN 27 AND 34 THEN '27-34'
WHEN age BETWEEN 35 AND 42 THEN '35-42'
WHEN age BETWEEN 43 AND 50 THEN '43-50'
WHEN age BETWEEN 51 AND 58 THEN '51-58'
END as age_bucket FROM added_user
),
total_bucket as (
SELECT DISTINCT age_bucket as age_bucket, COUNT(*) as total_member
FROM grouping_user
GROUP BY age_bucket
),
final_counting as (
SELECT * FROM total_bucket
),
overall_new_user as (
SELECT COUNT(DISTINCT u.user_id) overall_new FROM  user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
AND u.user_id NOT IN (
SELECT user_id FROM listening_table
WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
)
)
SELECT f.age_bucket, f.total_member, o.overall_new, ROUND((f.total_member::NUMERIC / o.overall_new) * 100, 2) as new_user_percentage_per_bucket
FROM final_counting f CROSS JOIN overall_new_user o;



-- PLAN PERCENTAGE OF NEW USER IN 2026
WITH added_user as( 
SELECT DISTINCT u.user_id, u.plan FROM  user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
AND u.user_id NOT IN (
SELECT user_id FROM listening_table l
WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
)
),
total_new_plan as (
SELECT DISTINCT plan, COUNT(*) as added_plan FROM 
added_user
GROUP BY plan
),
new_user_plan_2026 as (
SELECT COUNT(DISTINCT u.user_id) as overall_new_user_plan FROM  user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
AND u.user_id NOT IN (
SELECT user_id FROM listening_table l
WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
)
)
SELECT t.plan, t.added_plan, n.overall_new_user_plan,
ROUND((t.added_plan::NUMERIC / n.overall_new_user_plan) * 100, 2) as new_user_plan_2026_percentage
FROM total_new_plan t CROSS JOIN new_user_plan_2026 n;


-- COUNTRY PERCENTAGE OF NEW USER IN 2026
WITH added_user as( 
SELECT DISTINCT u.user_id, u.country FROM  user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
AND u.user_id NOT IN (
SELECT user_id FROM listening_table l
WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
)
),
total_new_country as (
SELECT DISTINCT country, COUNT(*) as added_country FROM 
added_user
GROUP BY country
),
new_user_country_2026 as (
SELECT COUNT(DISTINCT u.user_id) as overall_new_user_country FROM  user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
AND u.user_id NOT IN (
SELECT user_id FROM listening_table l
WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
)
)
SELECT t.country, t.added_country, n.overall_new_user_country,
ROUND((t.added_country::NUMERIC / n.overall_new_user_country) * 100, 2) as new_user_country_2026_percentage
FROM total_new_country t CROSS JOIN new_user_country_2026 n;



-- GENDER PERCENTAGE OF NEW USER IN 2026
WITH added_user as( 
SELECT DISTINCT u.user_id, u.gender FROM  user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
AND u.user_id NOT IN (
SELECT user_id FROM listening_table l
WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
)
),
total_new_user_gender as (
SELECT DISTINCT gender, COUNT(*) as added_count_gender FROM 
added_user
GROUP BY gender
),
new_user_gender_2026 as (
SELECT COUNT(DISTINCT u.user_id) as overall_new_user_gender FROM  user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
AND u.user_id NOT IN (
SELECT user_id FROM listening_table l
WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
)
)
SELECT t.gender, t.added_count_gender, n.overall_new_user_gender,
ROUND((t.added_count_gender::NUMERIC / n.overall_new_user_gender) * 100, 2) as new_user_country_2026_percentage
FROM total_new_user_gender t CROSS JOIN new_user_gender_2026 n;


--TOP 1 SONG PER AGE BUCKET IN 2026
WITH age_brucket as (
SELECT 
CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END as age, t.track_id, t.song_name, a.artist_name, t.genre, COUNT(DISTINCT l.listening_id) as total_listening_session,
COUNT(DISTINCT l.user_id) as total_unique_listener
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
JOIN track t ON t.track_id = l.track_id
JOIN artists_table a ON t.artists_id = a.artists_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END, t.track_id, t.song_name, t.genre, a.artist_name
ORDER BY age
),
top_genre as (
SELECT age, track_id, song_name, genre, artist_name, total_listening_session, 
total_unique_listener, ROW_NUMBER() OVER(PARTITION BY age ORDER BY total_listening_session DESC) as rnk
FROM age_brucket
),
information as (
SELECT * FROM top_genre
WHERE rnk = 1
),
overall_listening_bucket as (
SELECT CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END as age, COUNT(DISTINCT l.listening_id) as overall_session,
COUNT(DISTINCT l.track_id) as total_song_name,
COUNT(DISTINCT l.user_id) as overall_unique_listener
FROM listening_table l JOIN user_table u ON l.user_id = u.user_id
GROUP BY CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END
)
SELECT i.age, i.track_id, i.song_name, i.artist_name, i.genre, i.total_listening_session, i.total_unique_listener,
o.overall_session, o.total_song_name, o.overall_unique_listener, i.rnk, ROUND((i.total_listening_session::NUMERIC / o.overall_session) * 100, 2) as listening_percentage
FROM information i JOIN overall_listening_bucket o ON i.age = o.age



--TOTAL PLAN LISTENERS IN 2026 (COMPARISON)
SELECT u.plan,
COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM l.start_listening_time) = 2025 THEN u.user_id END) as listeners_2025_by_plan,
COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM l.start_listening_time) = 2026 THEN u.user_id END) as listeners_2026_by_plan
FROM listening_table l JOIN user_table u ON l.user_id = u.user_id
GROUP BY u.plan;


-- PLAN OVERALL LISTENER AND NEW LISTENERS POSSIBLE GROWTH PLAN

WITH new_listener_2026 AS (
    SELECT DISTINCT u.user_id, u.plan
    FROM listening_table l
    JOIN user_table u
        ON l.user_id = u.user_id
    WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
      AND u.user_id NOT IN (
          SELECT DISTINCT user_id
          FROM listening_table
          WHERE EXTRACT(YEAR FROM start_listening_time) = 2025
      )
),
information AS (
    SELECT plan, COUNT(user_id) AS total_new_listeners
    FROM new_listener_2026
    GROUP BY plan
),
all_listeners AS (
    SELECT u.plan,
           COUNT(DISTINCT l.user_id) AS overall_listeners_2026
    FROM listening_table l
    JOIN user_table u
        ON l.user_id = u.user_id
    WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
    GROUP BY u.plan
)
SELECT
    a.plan,
    a.overall_listeners_2026,
    COALESCE(i.total_new_listeners, 0) AS total_new_listeners
FROM all_listeners a
LEFT JOIN information i
    ON a.plan = i.plan
ORDER BY a.plan;


--PLAN LISTENERS PERCENTAGE CONTRIBUTION IN 2026
WITH plan_listeners as (
SELECT u.plan, COUNT(DISTINCT u.user_id) as total_listener
FROM user_table u JOIN listening_table l ON l.user_id = u.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.plan
),
overall_listeners as (
SELECT COUNT(DISTINCT user_id) as all_listeners
FROM listening_table 
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
)
SELECT p.plan, p.total_listener, o.all_listeners,
ROUND((p.total_listener::NUMERIC / o.all_listeners) * 100, 2) as percentage_listeners
FROM plan_listeners p CROSS JOIN overall_listeners o



--PLAN LISTENING SESSION RATE 2026 (WHO'S MORE ACTIVE IN LISTENING MUSIC)
WITH plan_activities as (
SELECT u.plan, COUNT(DISTINCT l.user_id) as total_listeners, COUNT(DISTINCT l.listening_id) as total_listening_session
FROM listening_table l JOIN user_table u ON l.user_id = u.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.plan
)
SELECT plan, total_listeners, total_listening_session,
ROUND((total_listening_session::NUMERIC / total_listeners), 2) as listening_session_rate
FROM plan_activities


-- PLAN LISTENING TIME DURATION IN 2026 (MOST DURATION TIME)
SELECT u.plan, SUM(l.end_listening_time - start_listening_time) as total_listening_duration
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.plan
ORDER BY total_listening_duration DESC


--PLAN TOTAL LISTENERS PER AGE BUCKET
WITH plan_age_bucket as (
SELECT DISTINCT l.user_id, u.plan,
CASE 
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END as age_bucket FROM listening_table l JOIN user_table u ON
l.user_id = u.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.plan, l.user_id, u.age
)
SELECT plan, age_bucket, COUNT(DISTINCT user_id) as total_listeners
FROM plan_age_bucket
GROUP BY plan, age_bucket



-- TOP 1 COUNTRY BY TOTAL LISTENERS PER PLAN
SELECT plan, country, total_listeners FROM (
SELECT plan, country, total_listeners, ROW_NUMBER() OVER(PARTITION BY plan ORDER BY total_listeners DESC) as rnk
FROM(
SELECT u.plan, u.country, COUNT(DISTINCT u.user_id) as total_listeners
FROM listening_table l JOIN user_table u ON l.user_id = u.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.plan, u.country
) as a
) as b
WHERE rnk = 1


--TOP 5 ALBUM OF 2026 BASED ON SONGS LISTENING SESSION
SELECT ats.artist_name, a.album_name, COUNT(DISTINCT l.listening_id) as total_listening_session
FROM listening_table l JOIN track t ON l.track_id = t.track_id
JOIN album_table a ON t.album_id = a.album_id
JOIN artists_table ats ON ats.artists_id = a.artists_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY ats.artist_name, a.album_name
ORDER BY total_listening_session DESC
LIMIT 5


--WHICH GENRE DOMINATE EACH TOP 5 ALBUM IN 2026

WITH top5_album as (
SELECT a.album_id, a.album_name, COUNT(DISTINCT l.listening_id) as total_listening_session,
COUNT(DISTINCT l.user_id) as total_listeners
FROM listening_table l JOIN track t ON l.track_id = t.track_id
JOIN album_table a ON t.album_id = a.album_id
JOIN artists_table ar ON ar.artists_id = a.artists_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY a.album_id, a.album_name
ORDER BY total_listening_session DESC
LIMIT 5
),
genre_counting as (
SELECT top.album_name, t.genre, COUNT(DISTINCT l.listening_id) as total_listening_session
FROM listening_table l JOIN track t ON l.track_id = t.track_id
JOIN album_table ab ON t.album_id = ab.album_id
JOIN top5_album top ON top.album_id = ab.album_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY top.album_name, t.genre
),
genre_ranking as (
SELECT *, ROW_NUMBER() OVER(PARTITION BY album_name ORDER BY total_listening_session DESC) as rnk
FROM genre_counting
)
SELECT * FROM genre_ranking
WHERE rnk = 1



--TOTAL PERCENTAGE OF TOP 5 ALBUM IN 2026
WITH album_session as (
SELECT a.album_name, COUNT(DISTINCT l.listening_id) as total_listening_session
FROM listening_table l JOIN track t ON l.track_id = t.track_id
JOIN album_table a ON t.album_id = a.album_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY a.album_name
ORDER BY total_listening_session DESC
LIMIT 5
),
overall_session as (
SELECT COUNT(DISTINCT listening_id) as overall_listening_session
FROM listening_table
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
),
album_percentage as (
SELECT als.album_name, als.total_listening_session, os.overall_listening_session,
ROUND((als.total_listening_session::NUMERIC / os.overall_listening_session) * 100, 2) as album_session_percentage
FROM album_session als CROSS JOIN overall_session os
)
SELECT SUM(album_session_percentage) as top5_total_percentage
FROM album_percentage


--TOP 5 ALBUM TOTAL LISTENER VS TOTAL LISTENING SESSION
SELECT a.album_name, COUNT(DISTINCT l.listening_id) as total_listening_session,
COUNT(DISTINCT l.user_id) as total_listeners
FROM listening_table l JOIN track t ON l.track_id = t.track_id
JOIN album_table a ON t.album_id = a.album_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY a.album_name
ORDER BY total_listening_session DESC
LIMIT 5



--top5 album listeners total listening session
WITH top5_album AS (
    SELECT
        al.album_id,
        al.album_name,
        COUNT(DISTINCT l.listening_id) AS total_listening_session,
        COUNT(DISTINCT l.user_id) AS total_listeners
    FROM listening_table l
    JOIN track t
        ON l.track_id = t.track_id
    JOIN album_table al
        ON t.album_id = al.album_id
    WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
    GROUP BY al.album_id, al.album_name
    ORDER BY total_listening_session DESC, al.album_name
    LIMIT 5
),
top5_listeners AS (
    SELECT
        tp.album_id,
        tp.album_name,
        tp.total_listening_session,
        tp.total_listeners,
        l2.user_id,
        u2.user_name,
        COUNT(DISTINCT l2.listening_id) AS user_listening_session
    FROM listening_table l2
    JOIN track t2
        ON l2.track_id = t2.track_id
    JOIN user_table u2
        ON l2.user_id = u2.user_id
    JOIN top5_album tp
        ON tp.album_id = t2.album_id
    WHERE EXTRACT(YEAR FROM l2.start_listening_time) = 2026
    GROUP BY
        tp.album_id,
        tp.album_name,
        tp.total_listening_session,
        tp.total_listeners,
        l2.user_id,
        u2.user_name
)
SELECT *
FROM top5_listeners
ORDER BY total_listening_session DESC


--2026 TOP 5 ALBUM VS 2025 TOP 5 ALBUM
SELECT years, album_id, album_name, total_listening_session FROM(
SELECT years, album_id, album_name, total_listening_session, ROW_NUMBER() OVER(PARTITION BY years ORDER BY total_listening_session DESC) as rnk
FROM(
SELECT EXTRACT(YEAR FROM l.start_listening_time) as years,
a.album_id, a.album_name, COUNT(DISTINCT l.listening_id) as total_listening_session
FROM listening_table l JOIN track t ON l.track_id = t.track_id
JOIN album_table a ON a.album_id = t.album_id
GROUP BY EXTRACT(YEAR FROM l.start_listening_time),
a.album_id, a.album_name
)as a
) as b
WHERE rnk <= 5



--MOST ACTIVE HOUR OF HIGHEST LISTENING EVENT/SESSION WITH NUMBER OF LISTENERS IN 2026
SELECT DATE_PART('hour', start_listening_time::TIME) as hours,
COUNT(DISTINCT listening_id) as total_listening_session,
COUNT(DISTINCT user_id) as total_listeners
FROM listening_table 
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
GROUP BY DATE_PART('hour', start_listening_time::TIME)
ORDER BY total_listening_session DESC


--HOURS ADDITIONAL SESSION PERCENTAGE
WITH hourly_listening AS (
    SELECT
        EXTRACT(HOUR FROM start_listening_time) AS listening_hour,
        COUNT(DISTINCT listening_id) AS total_sessions,
        COUNT(DISTINCT user_id) AS unique_listeners
    FROM listening_table
    WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
    GROUP BY EXTRACT(HOUR FROM start_listening_time)
)
SELECT
    listening_hour,
    total_sessions,
    unique_listeners,
    total_sessions - unique_listeners AS additional_sessions,
    ROUND(
        100.0 * (total_sessions - unique_listeners)
        / NULLIF(total_sessions, 0),
        2
    ) AS additional_session_percentage
FROM hourly_listening
ORDER BY additional_session_percentage DESC;



--PERCENTAGE OF LISTENERS WITH REPEATED LISTENING BEHAVIOR PER HOUR (EXCLUDE HOUR THAT DOESN'T REPEATED LISTENERS) 
WITH hours_listeners as (
SELECT
    EXTRACT(HOUR FROM start_listening_time) AS listening_hour,
    COUNT(DISTINCT user_id) AS total_listeners
FROM listening_table
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
GROUP BY EXTRACT(HOUR FROM start_listening_time)
),
hours_user_listeners as (
SELECT h.listening_hour, h.total_listeners, l1.user_id,
COUNT(DISTINCT l1.listening_id) as total_listening_session
FROM listening_table l1 JOIN hours_listeners h ON EXTRACT(HOUR FROM l1.start_listening_time) = h.listening_hour
WHERE EXTRACT(YEAR FROM l1.start_listening_time) = 2026
GROUP BY h.listening_hour, h.total_listeners, l1.user_id
),
hours_user_total_listeners as (
SELECT * FROM hours_user_listeners
WHERE total_listening_session > 1
),
counting_repeated_listeners as (
SELECT listening_hour, total_listeners, COUNT(DISTINCT user_id) as total_repeated_listeners
FROM hours_user_total_listeners
GROUP BY listening_hour, total_listeners
)
SELECT listening_hour, total_listeners, total_repeated_listeners,
ROUND((total_repeated_listeners::NUMERIC / total_listeners) * 100, 2) as percentage_of_repeated_listeners
FROM counting_repeated_listeners


--AGE MOST LISTENING HOURS IN 2026
SELECT age, hour, total_listening_session FROM(
SELECT age, hour, total_listening_session, ROW_NUMBER() OVER(PARTITION BY age ORDER BY total_listening_session DESC) as rnk
FROM(
SELECT
CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 42 AND 50 THEN '42-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END as age, DATE_PART('hour', l.start_listening_time) as hour,
COUNT(*) as total_listening_session
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 42 AND 50 THEN '42-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END , DATE_PART('hour', l.start_listening_time)
) as a
) as b
WHERE rnk = 1



--GENRE WITH MOST LISTENING SESSION AND LISTENERS (WITH PERCENTAGE)

WITH genre_listening_session as (
SELECT t.genre, COUNT(DISTINCT l.listening_id) as total_listening_session,
COUNT(DISTINCT l.user_id) as total_listeners
FROM listening_table l JOIN track t ON l.track_id = t.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY t.genre
),
overall_2026_listening_session as (
SELECT COUNT(DISTINCT listening_id) as overall_listening_session,
COUNT(DISTINCT user_id) as overall_listeners
FROM listening_table 
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
)
SELECT g.genre, g.total_listening_session, g.total_listeners, o.overall_listening_session,
o.overall_listeners,
ROUND((g.total_listening_session::NUMERIC / o.overall_listening_session) * 100, 2) as listening_session_percentage,
ROUND((g.total_listeners::NUMERIC / o.overall_listeners) * 100, 2) as listener_percentage
FROM genre_listening_session g CROSS JOIN overall_2026_listening_session o


-- GENRE POPULARITY: MANY LISTENERS OR REPEATED LISTENING IN 2026 AND AVERAGE SESSION PER LISTENER

SELECT
    t.genre,
    COUNT(DISTINCT l.user_id) AS unique_listeners,
    COUNT(DISTINCT l.listening_id) AS total_listening_sessions,
    ROUND(
        COUNT(DISTINCT l.listening_id)::NUMERIC
        / NULLIF(COUNT(DISTINCT l.user_id), 0),
        2
    ) AS avg_sessions_per_listener
FROM listening_table l
JOIN track t
    ON l.track_id = t.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY t.genre
ORDER BY total_listening_sessions DESC;



-- GENRE MOST AVERAGE RATINGS IN 2026
SELECT t.genre, ROUND(AVG(l.ratings), 2) as average_ratings
FROM track t JOIN listening_table l ON t.track_id = l.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY t.genre
ORDER BY average_ratings DESC


--GENRE YEARLY GROWTH PERCENTAGE

WITH genre_listening_record_year as (
SELECT EXTRACT(YEAR FROM l.start_listening_time) as years,
t.genre, COUNT(DISTINCT l.listening_id) as total_play
FROM listening_table l JOIN track t ON l.track_id = t.track_id
),
lagged as(
SELECT years, genre, total_play as year_2026_play,
LAG(total_play) OVER(PARTITION BY genre ORDER BY years) as year_2025_play
FROM genre_listening_record_year
)
SELECT years, genre, year_2026_play, year_2025_play,
CASE
WHEN year_2025_play = 0 OR year_2025_play IS NULL THEN NULL
ELSE ROUND((year_2026_play::NUMERIC - year_2025_play) / year_2025_play * 100, 2)
END as yearly_growth
FROM lagged
WHERE year_2025_play IS NOT NULL



--GENRE RANKING OVERALL in 2026

SELECT t.genre, COUNT(DISTINCT l.listening_id) as total_played,
COUNT(DISTINCT user_id) as total_listener
FROM listening_table L JOIN track t ON l.track_id = t.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY t.genre
ORDER BY total_played DESC


-- TOP 1 GENRE PER AGE BUCKET
WITH age_brucket as (
SELECT 
CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END as age, t.genre, COUNT(*) as total_listening_session,
COUNT(DISTINCT l.user_id) as total_listeners
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
JOIN track t ON t.track_id = l.track_id 
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END, t.genre
ORDER BY age, t.genre
),
top_genre as (
SELECT age, genre, total_listening_session, total_listeners, ROW_NUMBER() OVER(PARTITION BY age ORDER BY total_listening_session DESC) as rnk
FROM age_brucket
)
SELECT * FROM top_genre
WHERE rnk <= 2



--GENRE AVG SESSION PER LISTENERS

WITH genre_activity AS (
    SELECT
        CASE
            WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
            WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
            WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
            WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
            WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
        END AS age_bucket,
        t.genre,
        COUNT(DISTINCT l.listening_id) AS total_sessions,
        COUNT(DISTINCT l.user_id) AS unique_listeners
    FROM listening_table l
    JOIN user_table u
        ON l.user_id = u.user_id
    JOIN track t
        ON l.track_id = t.track_id
    WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
    GROUP BY age_bucket, t.genre
),
genre_ranking AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY age_bucket
            ORDER BY total_sessions DESC, genre
        ) AS genre_rank
    FROM genre_activity
)
SELECT
    age_bucket,
    genre,
    total_sessions,
    unique_listeners,
    ROUND(
        total_sessions::NUMERIC /
        NULLIF(unique_listeners, 0),
        2
    ) AS avg_sessions_per_listener
FROM genre_ranking
WHERE genre_rank = 1
ORDER BY age_bucket;


-- ACTIVE NUMBER OF UNIQUE LISTENER PER DAY
SELECT start_listening_time::Date, COUNT(DISTINCT user_id) as total_number_of_listener
FROM listening_table
GROUP BY start_listening_time::DATE


-- GENDER LISTENER PERCENTAGE PER GENRE IN 2026
WITH genre_gender as (
SELECT t.genre, u.gender, COUNT(DISTINCT l.user_id) as total_user FROM listening_table l
JOIN track t ON l.track_id = t.track_id JOIN user_table u ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026 
GROUP BY t.genre, u.gender
),
overall_count as (
SELECT t.genre, COUNT(DISTINCT l.user_id) as overall_genre_user_count
FROM listening_table l JOIN track t ON l.track_id = t.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY t.genre
)
SELECT g.genre, g.gender, g.total_user, ROUND((g.total_user::NUMERIC / o.overall_genre_user_count) * 100, 2) as percentage_of_gender
FROM genre_gender g JOIN overall_count o ON g.genre = o.genre



--COUNTRY THE HAVE MOST LISTENING SESSION CONTRIBUTION IN EACH GENRE

WITH country_listening_genre as (
SELECT u.country, t.genre, 
COUNT(DISTINCT l.listening_id) as total_play
FROM listening_table l JOIN user_table u ON l.user_id = u.user_id
JOIN track t ON t.track_id = l.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.country, t.genre
),
genre_total as (
SELECT t.genre, COUNT(DISTINCT l.listening_id) as overall_listening_session
FROM listening_table l JOIN track t ON l.track_id = t.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY t.genre
),
count_percentage as (
SELECT c.country, c.genre, c.total_play,
g.overall_listening_session, ROUND((c.total_play::NUMERIC / g.overall_listening_session) * 100 , 2) as country_total_percentage
FROM country_listening_genre c JOIN genre_total g ON c.genre = g.genre
),
top1 as (
SELECT *, ROW_NUMBER() OVER(PARTITION BY genre ORDER BY country_total_percentage DESC) as rnk
FROM count_percentage
)
SELECT * FROM top1
WHERE rnk = 1


--TOP 5 MOST ARTIST AND TRACK PLAYED THE MOST IN 2026

SELECT a.artist_name, t.song_name, t.genre, COUNT(DISTINCT l.listening_id) as total_listening_session
FROM artists_table a JOIN track t ON a.artists_id = t.artists_id
JOIN listening_table l ON l.track_id = t.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY a.artist_name, t.song_name, t.genre
ORDER BY total_listening_session DESC
LIMIT 5


--COUNTRY LISTENING TIME IN 2026
SELECT u.country, SUM(l.end_listening_time - l.start_listening_time) as total_listening_time
FROM user_table u LEFT JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.country
ORDER BY total_listening_time DESC


--COUNTRY TOP GENRE IN 2026
SELECT country, genre, total_listening_session FROM(
SELECT country, genre, total_listening_session, ROW_NUMBER() OVER(PARTITION BY country ORDER BY total_listening_session DESC) as rnk
FROM(
SELECT u.country, t.genre, COUNT(l.listening_id) as total_listening_session
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
JOIN track t ON l.track_id = t.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.country, t.genre
)as a
) as b
WHERE rnk = 1


--COUNTRY TOTAL LISTENING EVENT/SESSION IN 2026
SELECT u.country, COUNT(l.listening_id) as total_listening_session
FROM user_table u LEFT JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.country
ORDER BY total_listening_session DESC


--AGE BRUCKET TOTAL EVENT/SESSION IN 2026
SELECT 
CASE 
WHEN u.age BETWEEN 19 AND 26 THEN '18-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END as age, COUNT(l.listening_id) as total_listening_session
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY CASE 
WHEN u.age BETWEEN 19 AND 26 THEN '18-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END
ORDER BY age


--GENRE RATING PER AGE BRUCKET IN 2026
SELECT 
CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END as age, t.genre, ROUND(AVG(l.ratings),2) as ratings
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
JOIN track t ON t.track_id = l.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026 AND l.ratings IS NOT NULL 
GROUP BY CASE
WHEN u.age BETWEEN 19 AND 26 THEN '19-26'
WHEN u.age BETWEEN 27 AND 34 THEN '27-34'
WHEN u.age BETWEEN 35 AND 42 THEN '35-42'
WHEN u.age BETWEEN 43 AND 50 THEN '43-50'
WHEN u.age BETWEEN 51 AND 58 THEN '51-58'
END, t.genre
ORDER BY ratings DESC, age


--MOST ACTIVE DAY OF THE WEEK OF LISTENER LISTENING EVENT/SESSION IN 2026
SELECT TO_CHAR(start_listening_time::DATE, 'Day') as day_of_the_week,
COUNT(DISTINCT listening_id) as total_listening_session
FROM listening_table 
WHERE EXTRACT(YEAR FROM start_listening_time) = 2026
GROUP BY TO_CHAR(start_listening_time::DATE, 'Day')
ORDER BY total_listening_session DESC


-- PLAN AVERAGE LISTENING EVENTS/SESSION PER USER IN 2026
SELECT u.plan,
COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM l.start_listening_time) = 2026 THEN l.user_id END) as total_unique_listener_2026,
COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM l.start_listening_time) = 2026 THEN l.listening_id END) as total_listening_session_2026,
ROUND(COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM l.start_listening_time) = 2026 THEN l.listening_id END)::NUMERIC / NULLIF(COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM l.start_listening_time) = 2026 THEN l.user_id END),0),2) as session_per_users
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
GROUP BY u.plan


-- PLAN MOST PLAYED GENRE IN 2026

SELECT plan, genre, total_listening_session FROM(
SELECT plan, genre, total_listening_session, ROW_NUMBER() OVER(PARTITION BY plan ORDER BY total_listening_session DESC) as rnk
FROM(
SELECT u.plan, t.genre, COUNT(DISTINCT l.listening_id) as total_listening_session
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
JOIN track t ON t.track_id = l.track_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.plan, t.genre
) as a
) as b
WHERE rnk = 1



--LISTENING CONSISTENCY PER LISTENER (MORE THAN 1 DAY OF LISTENING)
SELECT u.user_id, u.user_name, COUNT(DISTINCT l.start_listening_time::DATE) total_days_listening,
COUNT(DISTINCT EXTRACT(MONTH FROM l.start_listening_time)) as num_of_month,
COUNT(DISTINCT l.listening_id) as total_listening_session
FROM user_table u JOIN listening_table l ON u.user_id = l.user_id
WHERE EXTRACT(YEAR FROM l.start_listening_time) = 2026
GROUP BY u.user_id, u.user_name
HAVING COUNT(DISTINCT l.start_listening_time::DATE) > 1
ORDER BY total_days_listening DESC


--TOTAL SONG PER ALBUM
SELECT a.album_id, a.album_name, COUNT(DISTINCT t.track_id) as total_song
FROM album_table a JOIN track t ON a.album_id = t.album_id
GROUP BY a.album_id, a.album_name
ORDER BY total_song DESC