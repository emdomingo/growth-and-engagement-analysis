-- Note: Our events data only starts from 01-May-2014

-- Setting up the CTE:
-- • Filter the event_type column so that only 'engagement' events are shown.
-- • Get the ISO week number so that the analysis is on a per week basis.
-- • Condense the device column to device_type (desktop, mobile and tablet).
-- • Join with the users table and get the company_id per user.

WITH engagements AS (
	SELECT e.*,
		   DATEPART(ISO_WEEK, occurred_at) AS week_num,
		   CASE
				WHEN e.device IN ('nexus 5', 'nexus 7', 
					'nexus 10', 'nokia lumia 635', 'iphone 4s', 
					'iphone 5', 'iphone 5s', 'amazon fire phone', 
					'samsung galaxy note', 'samsung galaxy s4', 
					'htc one') THEN 'mobile'
				WHEN e.device IN ('dell inspiron notebook', 'dell inspiron desktop', 
					'lenovo thinkpad', 'macbook pro', 'asus chromebook', 
					'macbook air', 'acer aspire notebook', 'acer aspire desktop',
					'windows surface', 'hp pavilion desktop', 'mac mini') THEN 'desktop'
				WHEN e.device IN ('ipad mini', 'kindle fire', 'ipad air', 'samsumg galaxy tablet') THEN 'tablet'
				ELSE NULL
			END AS device_type,
			u.company_id
	FROM yammer.dbo.events AS e
	LEFT JOIN yammer.dbo.users AS u
	ON e.user_id = u.user_id
	WHERE event_type = 'engagement'
)

-- Since analysis is on a per week basis, we first check if we have complete data for every week.

SELECT COUNT(DISTINCT DATEPART(DAYOFYEAR, occurred_at)) AS day_num,
	   week_num
FROM engagements
GROUP BY week_num
ORDER BY week_num ASC

-- We only have 4 days with data from week 18. It's best to just remove those from the analysis.

-- Show number of engagements per week.

SELECT week_num,
	   COUNT(*) AS num_engagements
FROM engagements
WHERE week_num != 18
GROUP BY week_num
ORDER BY week_num ASC

-- We see a sharp drop in engagements on weeks 32 and 33. Let's investigate for probable reasons.

-- First, let's check usage between device_types

-- Per device
SELECT week_num, 
       device_type,
	   COUNT(*) AS num_engagements
FROM engagements
WHERE week_num != 18
GROUP BY week_num, device_type
ORDER BY week_num ASC
----

-- Next, let's check engagements per company. There might be one company with a large userbase who quit using the app.
-- We will limit the number of companies checked to 20. We can do this by using a subquery.
SELECT week_num, 
       company_id,
	   COUNT(*) AS num_engagements
FROM engagements
WHERE company_id IN (
    -- TOP 20 companies according to user_num
	SELECT TOP 20 company_id
	FROM engagements
	GROUP BY company_id
	ORDER BY COUNT(DISTINCT user_id) DESC)
AND week_num != 18
GROUP BY week_num, company_id
ORDER BY week_num ASC

-- Finally, we'll check engagements per location. A sharp drop in engagements in a specific region might mean a server outage.
-- We'll also limit this to 20 locations.
SELECT week_num, 
       location,
	   COUNT(*) AS num_engagements
FROM engagements
WHERE location in (
	SELECT TOP 20 location
	FROM engagements
	GROUP BY location
	ORDER BY COUNT(DISTINCT user_id) DESC)
AND week_num != 18
GROUP BY week_num, location
ORDER BY week_num ASC, num_engagements DESC
----
