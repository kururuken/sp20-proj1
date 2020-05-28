DROP VIEW IF EXISTS q0, q1i, q1ii, q1iii, q1iv, q2i, q2ii, q2iii, q3i, q3ii, q3iii, q4i, q4ii, q4iii, q4iv, q4v;

-- Question 0
CREATE VIEW q0(era) 
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear 
  ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70 
  ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, p.playerid, yearid
  FROM people AS p
  INNER JOIN HallofFame AS h
  ON p.playerid = h.playerid
  WHERE inducted = 'Y'
  ORDER BY yearid DESC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, p.playerid, cp.schoolid, h.yearid
  FROM people AS p 
  INNER JOIN HallofFame AS h ON p.playerid = h.playerid
  INNER JOIN CollegePlaying AS cp ON p.playerid = cp.playerid
  WHERE inducted = 'Y' AND cp.schoolid IN (
    SELECT s.schoolid
    FROM Schools AS s
    WHERE s.schoolstate = 'CA'
  )
  ORDER BY h.yearid DESC, schoolid ASC, p.playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid, namefirst, namelast, cp.schoolid
  FROM people AS p 
  INNER JOIN HallofFame AS h ON p.playerid = h.playerid
  LEFT JOIN CollegePlaying AS cp ON p.playerid = cp.playerid
  WHERE inducted = 'Y'
  ORDER BY p.playerid DESC, schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, namefirst, namelast, yearid, slg
  FROM people AS p
  INNER JOIN (
    SELECT b.playerid, yearid, CAST((h - h2b - h3b - hr) + 2 * h2b + 3 * h3b + 4 * hr AS float) / CAST(ab AS float) AS slg
    FROM batting AS b
    WHERE ab > 50
  ) AS s
  ON p.playerid = s.playerid
  ORDER BY slg DESC, yearid ASC, p.playerid ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, namefirst, namelast, lslg
  FROM people AS p
  INNER JOIN (
    SELECT playerid, CAST(SUM(h - h2b - h3b - hr) + 2 * SUM(h2b) + 3 * SUM(h3b) + 4 * SUM(hr) AS float) / CAST(SUM(ab) AS float) AS lslg
    FROM batting
    GROUP BY playerid 
    HAVING SUM(ab) > 50
  ) AS s
  ON p.playerid = s.playerid
  ORDER BY lslg DESC, p.playerid ASC
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT namefirst, namelast, lslg
  FROM people AS p
  INNER JOIN (
    SELECT playerid, CAST(SUM(h - h2b - h3b - hr) + 2 * SUM(h2b) + 3 * SUM(h3b) + 4 * SUM(hr) AS float) / CAST(SUM(ab) AS float) AS lslg
    FROM batting
    GROUP BY playerid 
    HAVING SUM(ab) > 50
  ) AS s
  ON p.playerid = s.playerid
  WHERE lslg > (
    SELECT CAST(SUM(h - h2b - h3b - hr) + 2 * SUM(h2b) + 3 * SUM(h3b) + 4 * SUM(hr) AS float) / CAST(SUM(ab) AS float)
    FROM batting
    WHERE playerid = 'mayswi01'
  )
  ORDER BY lslg DESC

;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg, stddev)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary), STDDEV(salary)
  FROM Salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
-- WITH AS clause generates a temporary table
  WITH T1 AS (
    SELECT MIN(salary) AS l, (MAX(salary) - MIN(salary)) / 10 AS step
    FROM Salaries
    WHERE yearid = '2016'
  ), T2 AS (
    SELECT i AS binid, l + i * step AS low, l + (i + 1) * step AS high
    FROM generate_series(0, 9) AS i, T1 -- 1. give a column an alias, 2. Cross join is suitable if we just want to broadcast
  )
  SELECT binid, low, high, COUNT(*)
  FROM T2
  INNER JOIN Salaries AS s
  ON s.salary >= low AND (s.salary < high OR (binid = 9 AND s.salary <= high)) -- JOIN could also support predicate
  WHERE yearid = '2016'
  GROUP BY binid, low, high  -- mutiple group by
  ORDER BY binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT s1.yearid, MIN(s1.salary) - MIN(s2.salary), MAX(s1.salary) - MAX(s2.salary), AVG(s1.salary) - AVG(s2.salary)
  FROM Salaries AS s1
  INNER JOIN Salaries AS s2
  ON CAST(s1.yearid AS int) - 1 = CAST(s2.yearid AS int)
  GROUP BY s1.yearid
  ORDER BY s1.yearid ASC
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  WITH T AS (
    SELECT MAX(salary) AS h, yearid
    FROM Salaries
    GROUP BY yearid
    HAVING yearid = '2000' OR yearid = '2001' 
  )
  SELECT p.playerid, namefirst, namelast, salary, yearid
  FROM people AS p
  INNER JOIN (
    SELECT playerid, salary, s.yearid
    FROM Salaries AS s
    INNER JOIN T
    ON s.yearid = T.yearid AND salary = T.h
  ) AS s
  ON s.playerid = p.playerid
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) 
AS
  SELECT a.teamid, MAX(salary) - MIN(salary) AS diffAvg
  FROM allstarfull AS a
  INNER JOIN salaries AS s
  ON s.playerid = a.playerid
  WHERE a.yearid = '2016' AND s.yearid = '2016'
  GROUP BY a.teamid
  ORDER BY a.teamid
;

