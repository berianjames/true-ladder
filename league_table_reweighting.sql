-- Parse list of teams
DROP TABLE IF EXISTS premier_league.teams;
CREATE TABLE IF NOT EXISTS premier_league.teams
SELECT DISTINCT(hometeam) as team
FROM results_2013_01_20 r; 

-- Create table of all premier league matchups, 
--  marking whether they are present in the import file
DROP TABLE IF EXISTS premier_league.possible_matches;
CREATE TABLE IF NOT EXISTS premier_league.possible_matches
SELECT 
 t.team AS hometeam,
 t2.team AS awayteam,
 IF(r.hometeam IS NULL, 0, 1) AS is_played
FROM teams AS t
JOIN teams AS t2 
ON t.team <> t2.team
LEFt JOIN results_2013_01_20 AS r
ON t.team = r.hometeam AND t2.team = r.awayteam 
ORDER BY hometeam, awayteam;

-- Compute the home and away points for all teams
DROP TABLE IF EXISTS premier_league.away_pts;
CREATE TABLE premier_league.away_pts
SELECT 
 awayteam,
 COUNT(*) as away_games,
 SUM( 
   CASE r.FTR
     WHEN 'A' THEN 3
     WHEN 'D' THEN 1
     WHEN 'H' THEN 0
   END
   ) as away_pts,
   SUM(FTAG) as away_goals_for,
   SUM(FTHG) as away_goals_against
FROM results_2013_01_20 r
WHERE r.FTHG IS NOT NULL
GROUP BY 1;

DROP TABLE IF EXISTS premier_league.home_pts;
CREATE TABLE premier_league.home_pts
SELECT 
 hometeam,
 COUNT(*) as home_games,
 SUM( 
   CASE r.FTR
     WHEN 'H' THEN 3
     WHEN 'D' THEN 1
     WHEN 'A' THEN 0
   END
   ) as home_pts,
   SUM(FTHG) as home_goals_for,
   SUM(FTAG) as home_goals_against
FROM results_2013_01_20 r
WHERE r.FTAG IS NOT NULL
GROUP BY 1;

-- Based on the points scored at home and away, and 
--  the overall performance of all team, compute performance weights
DROP TABLE IF EXISTS away_weights;
CREATE TABLE away_weights
SELECT 
 awayteam as team, 
 away_pts / away_games,
 away_pts / away_games / (SELECT AVG(away_pts / away_games) FROM away_pts) as away_weight
FROM away_pts;

DROP TABLE IF EXISTS home_weights;
CREATE TABLE home_weights
SELECT 
 hometeam as team, 
 home_pts / home_games,
 home_pts / home_games / (SELECT AVG(home_pts / home_games) FROM home_pts) as home_weight
FROM home_pts;

-- Compute the current unbalanced Premier League ladder
DROP TABLE IF EXISTS premier_league.current_table;
CREATE TABLE premier_league.current_table
SELECT
 ht.hometeam as team,
 ht.home_games + at.away_games as games,
 ht.home_pts,
 at.away_pts,
 ht.home_goals_for - ht.home_goals_against + at.away_goals_for - at.away_goals_against as goal_diff,
 ht.home_pts + at.away_pts as total_pts
FROM
 home_pts ht
JOIN
 away_pts at
ON at.awayteam = ht.hometeam
ORDER BY total_pts desc, goal_diff desc;
ALTER TABLE premier_league.current_table ADD rank INT NOT NULL AUTO_INCREMENT KEY FIRST;

DROP TABLE IF EXISTS current_table_rebalanced;
CREATE TABLE IF NOT EXISTS current_table_rebalanced
SELECT
 ct.rank as rank_raw,
 ct.team,
 ct.games,
 ct.home_pts,
 ROUND(ct.home_pts * hometeam_weights.reweighting,2) as home_pts_balanced,
 ct.away_pts,
 ROUND(ct.away_pts * awayteam_weights.reweighting,2) as away_pts_balanced,
 ct.goal_diff,
 ct.home_pts + ct.away_pts as total_pts,
 ROUND(ct.home_pts * hometeam_weights.reweighting + ct.away_pts * awayteam_weights.reweighting,3) as total_pts_balanced
FROM current_table ct
JOIN (SELECT hometeam, AVG(away_weight) as reweighting FROM possible_matches pm LEFT JOIN away_weights aw ON aw.team = pm.awayteam WHERE pm.is_played = 1 GROUP BY hometeam) as hometeam_weights
ON hometeam_weights.hometeam = ct.team
JOIN (SELECT awayteam, AVG(home_weight) as reweighting FROM possible_matches pm LEFT JOIN home_weights hw ON hw.team = pm.hometeam WHERE pm.is_played = 1 GROUP BY awayteam) as awayteam_weights
ON awayteam_weights.awayteam = ct.team
ORDER BY total_pts_balanced desc, goal_diff desc;
ALTER TABLE premier_league.current_table_rebalanced ADD rank INT NOT NULL AUTO_INCREMENT KEY FIRST;




