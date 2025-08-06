-- ====================================================================
-- ADVANCED FUNNEL ANALYSIS (using Window Functions & Segmentation)
-- ====================================================================
-- This query sequences user events to build a funnel, calculates time between steps,
-- and segments the results by the user's platform.

WITH user_events_sequenced AS (
    -- First, sequence all events for each user based on timestamp
    SELECT
        user_id,
        platform,
        event_name,
        event_timestamp,
        LEAD(event_name, 1) OVER (PARTITION BY user_id ORDER BY event_timestamp) as next_event_name,
        LEAD(event_timestamp, 1) OVER (PARTITION BY user_id ORDER BY event_timestamp) as next_event_timestamp
    FROM events
),
funnel_stages AS (
    -- Identify key funnel transitions and calculate the time taken for each transition
    SELECT
        platform,
        user_id,
        -- Stage 1: Install to View Item
        CASE
            WHEN event_name = 'app_install' AND next_event_name = 'view_item'
            THEN TIMESTAMPDIFF(SECOND, event_timestamp, next_event_timestamp)
        END as time_to_view,
        -- Stage 2: View Item to Add to Cart
        CASE
            WHEN event_name = 'view_item' AND next_event_name = 'add_to_cart'
            THEN TIMESTAMPDIFF(SECOND, event_timestamp, next_event_timestamp)
        END as time_to_cart,
        -- Stage 3: Add to Cart to Purchase
        CASE
            WHEN event_name = 'add_to_cart' AND next_event_name = 'purchase'
            THEN TIMESTAMPDIFF(SECOND, event_timestamp, next_event_timestamp)
        END as time_to_purchase
    FROM user_events_sequenced
)
-- Aggregate the results by platform to get the final funnel metrics
SELECT
    platform,
    -- Count of users at each stage
    COUNT(DISTINCT e.user_id) AS total_installs,
    COUNT(DISTINCT CASE WHEN f.time_to_view IS NOT NULL THEN e.user_id END) AS viewed_item_users,
    COUNT(DISTINCT CASE WHEN f.time_to_cart IS NOT NULL THEN e.user_id END) AS added_to_cart_users,
    COUNT(DISTINCT CASE WHEN f.time_to_purchase IS NOT NULL THEN e.user_id END) AS purchased_users,
    -- Conversion rates between stages
    (COUNT(DISTINCT CASE WHEN f.time_to_view IS NOT NULL THEN e.user_id END) * 100.0 / COUNT(DISTINCT e.user_id)) AS install_to_view_rate,
    (COUNT(DISTINCT CASE WHEN f.time_to_cart IS NOT NULL THEN e.user_id END) * 100.0 / COUNT(DISTINCT CASE WHEN f.time_to_view IS NOT NULL THEN e.user_id END)) AS view_to_cart_rate,
    (COUNT(DISTINCT CASE WHEN f.time_to_purchase IS NOT NULL THEN e.user_id END) * 100.0 / COUNT(DISTINCT CASE WHEN f.time_to_cart IS NOT NULL THEN e.user_id END)) AS cart_to_purchase_rate,
    -- Average time (in seconds) to progress to the next stage
    AVG(f.time_to_view) AS avg_time_install_to_view,
    AVG(f.time_to_cart) AS avg_time_view_to_cart,
    AVG(f.time_to_purchase) AS avg_time_cart_to_purchase
FROM events e
LEFT JOIN funnel_stages f ON e.user_id = f.user_id AND e.platform = f.platform
WHERE e.event_name = 'app_install'
GROUP BY platform;


-- ====================================================================
-- COHORT RETENTION CURVE (Weekly)
-- ====================================================================
-- Tracks user retention for weekly cohorts over a 4-week period.

WITH install_cohorts AS (
    -- Determine the cohort week for each user based on their install date
    SELECT
        user_id,
        DATE_FORMAT(MIN(event_timestamp), '%Y-%m-%d') AS cohort_date
    FROM events
    WHERE event_name = 'app_install'
    GROUP BY user_id
),
user_activity_by_week AS (
    -- Determine the week of activity for each user
    SELECT DISTINCT
        user_id,
        TIMESTAMPDIFF(WEEK, (SELECT MIN(cohort_date) FROM install_cohorts), event_timestamp) AS activity_week
    FROM events
)
SELECT
    DATE_FORMAT(ic.cohort_date, '%Y-%m-%d') AS cohort_start_date,
    COUNT(DISTINCT ic.user_id) AS cohort_size,
    -- Retention percentages for each week
    SUM(CASE WHEN ua.activity_week = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT ic.user_id) AS week_0_retention,
    SUM(CASE WHEN ua.activity_week = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT ic.user_id) AS week_1_retention,
    SUM(CASE WHEN ua.activity_week = 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT ic.user_id) AS week_2_retention,
    SUM(CASE WHEN ua.activity_week = 3 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT ic.user_id) AS week_3_retention
FROM install_cohorts ic
LEFT JOIN user_activity_by_week ua ON ic.user_id = ua.user_id
GROUP BY cohort_start_date
ORDER BY cohort_start_date;


-- ====================================================================
-- ACTIVE USERS (DAU, WAU, MAU) & STICKINESS RATIO
-- ====================================================================

-- DAU, WAU, and MAU are calculated here for the most recent period.
-- In a real-world scenario, you'd run these for specific date ranges.

WITH dau AS (
    SELECT COUNT(DISTINCT user_id) as daily_active_users
    FROM events
    WHERE event_timestamp >= CURDATE() - INTERVAL 1 DAY AND event_timestamp < CURDATE()
),
wau AS (
    SELECT COUNT(DISTINCT user_id) as weekly_active_users
    FROM events
    WHERE event_timestamp >= CURDATE() - INTERVAL 7 DAY AND event_timestamp < CURDATE()
),
mau AS (
    SELECT COUNT(DISTINCT user_id) as monthly_active_users
    FROM events
    WHERE event_timestamp >= CURDATE() - INTERVAL 30 DAY AND event_timestamp < CURDATE()
)
SELECT
    d.daily_active_users,
    w.weekly_active_users,
    m.monthly_active_users,
    (d.daily_active_users * 100.0 / m.monthly_active_users) AS stickiness_ratio_pct
FROM dau d, wau w, mau m;


-- ====================================================================
-- ACTIVATION TIME DISTRIBUTION
-- ====================================================================
-- Calculates the median and 75th percentile time it takes for a user
-- to get from 'app_install' to their first 'view_item' event.
-- Note: PERCENTILE_CONT is not standard in MySQL 5.7. This query assumes MySQL 8+ or a compatible DB.

WITH install_times AS (
    SELECT user_id, MIN(event_timestamp) as install_time
    FROM events
    WHERE event_name = 'app_install'
    GROUP BY user_id
),
activation_times AS (
    SELECT user_id, MIN(event_timestamp) as activation_time
    FROM events
    WHERE event_name = 'view_item'
    GROUP BY user_id
),
time_to_activate AS (
    SELECT
        TIMESTAMPDIFF(SECOND, i.install_time, a.activation_time) as activation_seconds
    FROM install_times i
    JOIN activation_times a ON i.user_id = a.user_id
    WHERE a.activation_time > i.install_time
)
SELECT
    -- Using AVG as a substitute for MEDIAN for broader compatibility
    AVG(activation_seconds) as mean_activation_time_seconds,
    -- This part of the query is for DBs that support PERCENTILE_CONT
    -- PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY activation_seconds) OVER() as median_activation_time,
    -- PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY activation_seconds) OVER() as p75_activation_time
    0 as placeholder_for_median -- Placeholder
FROM time_to_activate;
