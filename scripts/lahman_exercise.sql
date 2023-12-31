-- Lahman Baseball Database Exercise
--this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
--A data dictionary is included with the files for this project.

--Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.

-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

SELECT
	MIN(year),
	MAX(year)
FROM homegames;

--ANSWER: The earliest is 1871 and the latest is 2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT
	DISTINCT p.namegiven
	,p.height
	,f.franchname
	,(a.g_all) AS games_played
FROM people AS p
INNER JOIN appearances AS a
USING(playerid)
LEFT JOIN teams AS t
USING(teamid)
LEFT JOIN teamsfranchises AS f
USING(franchid)
WHERE p.height = (SELECT MIN(height)
				 FROM people)

--ANSWERS: Edward Carl 43inches and 1 game for the Baltimore Orioles	

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
	
SELECT
	DISTINCT c.playerid
	,p.namefirst || ' ' || p.namelast AS name
	,(SUM(sl.salary)/3):: numeric :: money AS tot_salary
FROM schools AS s
INNER JOIN collegeplaying AS c
USING(schoolid)
LEFT JOIN people AS p
USING(playerid)
LEFT JOIN salaries AS SL
USING(playerid)
WHERE s.schoolname = 'Vanderbilt University' AND sl.salary IS NOT NULL
GROUP BY c.playerid, p.namefirst, p.namelast, s.schoolname
ORDER BY tot_salary DESC
LIMIT 1

--ANSWERS: David Price $81,851,296.00

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT
	CASE
			WHEN pos = 'OF' THEN 'Outfield'
			WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
			WHEN pos IN ('P', 'C') THEN 'Battery'
			END AS position
	,SUM(po) AS putouts
FROM fielding
WHERE yearid = '2016'
GROUP BY position
   
--ANSWERS:
-- "Battery"	41,424
-- "Infield"	58,934
-- "Outfield"	29,560

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
   
WITH yearly AS(
SELECT
	ROUND(SUM(p.so)/h.tot_games, 2) AS avg_so_yr
	,ROUND(SUM(p.hr)/h.tot_games, 2) AS avg_hr_yr
	,h.year/10*10 AS decade
FROM pitching AS p
INNER JOIN (SELECT
				CAST(SUM(games) AS numeric) AS tot_games
				,year
			FROM homegames
		   GROUP BY year) AS h
ON p.yearid = h.year
WHERE h.year >= 1920
GROUP BY h.year, h.tot_games
ORDER BY decade
)
SELECT
	decade
	,ROUND(avg(avg_so_yr), 2) AS avg_so_decade
	,ROUND(avg(avg_hr_yr), 2) AS avg_hr_decade
FROM yearly
GROUP BY decade

--ANSWER: Strike outs increased while HR's stayed mostly the same

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT
	p.namegiven
	,ROUND(CAST(b.sb AS numeric)/CAST((b.sb + b.cs) AS numeric), 2) AS sb_percent
FROM people as p
INNER JOIN batting AS b
USING(playerid)
WHERE b.yearid = 2016 AND (b.sb + b.cs) >= 20
ORDER BY sb_percent DESC

--ANSWERS: Christopher with 91%

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

--Most wins without wining WS
SELECT
	f.franchname AS name
	,t.yearid AS year
	,t.w
	,t.wswin
FROM teams AS t
INNER JOIN teamsfranchises AS f
USING(franchid)
WHERE t.yearid BETWEEN 1970 AND 2016 AND t.wswin = 'N'
ORDER BY t.w DESC
LIMIT 1
--Seattle Mariners 116 wins in 2001

--Least wins with winning WS
SELECT
	f.franchname AS name
	,t.yearid AS year
	,t.w
	,t.wswin
FROM teams AS t
INNER JOIN teamsfranchises AS f
USING(franchid)
WHERE t.yearid BETWEEN 1970 AND 2016 AND t.wswin = 'Y'
ORDER BY t.w
LIMIT 1;
--Los Angeles Dodges 63 wins in 1981

--Seeing why LA's games were so low
SELECT AVG(games), year
FROM homegames
WHERE year BETWEEN 1970 AND 2016
GROUP BY year
ORDER BY year
--There was strike this year

--Redo removing 1981
SELECT
	f.franchname AS name
	,t.yearid AS year
	,t.w
	,t.wswin
FROM teams AS t
INNER JOIN teamsfranchises AS f
USING(franchid)
WHERE t.yearid BETWEEN 1970 AND 2016
	AND t.wswin = 'Y'
	AND t.yearid != 1981
ORDER BY t.w;
--ST. Louis Cardinals 83 wins in 2006

--Percent most winning team wins WS
WITH max_ws AS(
SELECT 
	CASE
		WHEN t.wswin = 'Y' THEN 1
		ELSE 0 END AS ws
	,yearid
FROM(SELECT
	yearid
	,MAX(w) AS w
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016 AND yearid != 1981
	GROUP BY yearid) AS y
LEFT JOIN teams AS t
USING(yearid, w)
)
SELECT
	ROUND((CAST(SUM(ws) AS numeric)/CAST(COUNT(DISTINCT yearid) AS numeric)),2)* 100|| '%'  AS max_perc
	,COUNT(DISTINCT yearid)
FROM max_ws
--26% of the time

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

WITH att AS (
SELECT
	park
	,team
	,year
	,SUM(attendance) AS sum_att
FROM homegames
WHERE year = 2016
GROUP BY team, park, year
ORDER BY sum_att
)
SELECT * FROM(
SELECT
	p.park_name
	,a.team
	,a.sum_att/h.games AS avg_game
	,'bottom 5' AS type
FROM att AS a
INNER JOIN homegames AS h
USING(team, park, year)
INNER JOIN parks AS p
USING(park)
WHERE h.games > 10
ORDER BY avg_game
LIMIT 5
)
UNION
SELECT * FROM(
SELECT
	p.park_name
	,a.team
	,a.sum_att/h.games AS avg_game
	,'top 5' AS type
FROM att AS a
INNER JOIN homegames AS h
USING(team, park, year)
INNER JOIN parks AS p
USING(park)
WHERE h.games > 10
ORDER BY avg_game DESC
LIMIT 5
)
ORDER BY 3

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

WITH list AS(
SELECT
	p.namefirst || ' ' || p.namelast AS name
	,a.awardid
	,a.lgid
	,a.yearid
	,m.teamid AS team
FROM awardsmanagers AS a
LEFT JOIN people AS p
USING(playerid)
LEFT JOIN managers AS m
USING(yearid, lgid)
LEFT JOIN teams AS t
USING(teamid)
WHERE a.playerid IN (
	SELECT playerid
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	GROUP BY playerid
	HAVING COUNT(DISTINCT lgid) > 1)
AND a.playerid = m.playerid
AND a.awardid = 'TSN Manager of the Year'
GROUP BY p.namefirst, p.namelast, a.yearid, a.lgid, m.teamid, a.awardid
ORDER BY p.namefirst, p.namelast
)

SELECT
	name
FROM list
GROUP BY name
HAVING COUNT(DISTINCT lgid) > 1

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

WITH hr_maxes AS(
SELECT
	playerid
	,MAX(hr) as max_hr
FROM batting
GROUP BY playerid
HAVING COUNT(DISTINCT yearid) >= 10
)
SELECT
	p.namefirst || ' ' ||p.namelast
	,b.hr
FROM hr_maxes AS m
LEFT JOIN people AS p
USING(playerid)
LEFT JOIN batting AS b
USING(playerid)
WHERE b.yearid = 2016
AND b.hr = m.max_hr
AND b.hr >= 1

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

WITH sal_rank AS(
SELECT
	yearid
	,teamid
	,SUM(salary)::numeric::int AS team_pay
	, RANK() OVER(PARTITION BY yearid ORDER BY SUM(salary) DESC)
FROM salaries
WHERE yearid >= 2000
GROUP BY teamid, yearid
)

SELECT
	CORR(s.team_pay, t.w)
FROM sal_rank AS s
LEFT JOIN teams AS t
USING(yearid, teamid)

--No Correlation

-- 12. In this question, you will explore the connection between number of wins and attendance.
--Does there appear to be any correlation between attendance at home games and number of wins?
--Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner

WITH cte AS(
SELECT
	h.year
	,h.team
	,h.attendance
	,t.w
FROM homegames AS h
INNER JOIN teams AS t
ON h.team = t.teamid AND h.year = t.yearid
)

SELECT
	CORR(attendance, w) AS win_corr
FROM cte

--No Correlation


WITH cte AS(
SELECT
	h.year
	,h.team
	,h.attendance
	,t.wswin
	,CASE
		WHEN t.wswin = 'Y' THEN 1
		ELSE 0 END AS bin_ws
FROM homegames AS h
INNER JOIN teams AS t
ON h.team = t.teamid AND h.year = t.yearid
WHERE t.wswin IS NOT NULL
ORDER BY h.team, h.year
),
cte2 AS(
SELECT
	*
	,LAG(bin_ws) OVER()
FROM cte
)

SELECT
	CORR(attendance, lag)
FROM cte2

--No Correlation

WITH cte AS(
SELECT
	h.year
	,h.team
	,h.attendance
	,t.wcwin
	,t.divwin
	,CASE
		WHEN t.wcwin = 'Y' OR t.divwin = 'Y' THEN 1
		ELSE 0 END AS bin_wcd
FROM homegames AS h
INNER JOIN teams AS t
ON h.team = t.teamid AND h.year = t.yearid
WHERE t.wswin IS NOT NULL
ORDER BY h.team, h.year
)

SELECT
	CORR(attendance, bin_wcd)
FROM cte

--No Correlation

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?



  
