-- A CTE was used to portion out the dates per month and year, count the number of users created, 
-- and by using a case statement, count the number of users who activated their accounts.
-- Afterwards, the CTE was queried to get the cumulative sum of users created and activated.

WITH user_count AS (
	SELECT DATEPART(YY, created_at) AS signup_year,
		   DATEPART(MM, created_at) AS signup_month,
		   COUNT(*) AS users_created,
		   SUM(CASE WHEN state = 'active' THEN 1 ELSE 0 END) AS users_active
	FROM yammer.dbo.users
	GROUP BY DATEPART(MM, created_at), DATEPART(YY, created_at)
)

SELECT *,
	   SUM(users_created) OVER (ORDER BY signup_year ASC, signup_month ASC) AS total_users_created,
	   SUM(users_active) OVER (ORDER BY signup_year ASC, signup_month ASC) AS total_users_active
FROM user_count
ORDER BY signup_year ASC, signup_month ASC
