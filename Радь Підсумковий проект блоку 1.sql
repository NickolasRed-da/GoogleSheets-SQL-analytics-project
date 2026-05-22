WITH users_parsed AS 
(
    SELECT
        u.user_id,
        u.signup_datetime,
        u.promo_signup_flag,
        CASE
            WHEN TRIM(u.signup_datetime) ~ '^\d{2}[.\-/]\d{2}[.\-/]\d{4}'
            THEN to_date(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(TRIM(u.signup_datetime), '\s.*$', ''),
                    '[./]', '-', 'g'),
                'DD-MM-YYYY')
            WHEN TRIM(u.signup_datetime) ~ '^\d{4}[.\-/]\d{2}[.\-/]\d{2}'
            THEN to_date(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(TRIM(u.signup_datetime), '\s.*$', ''),
                    '[./]', '-', 'g'),
                'YYYY-MM-DD')
            WHEN TRIM(u.signup_datetime) ~ '^\d{1,2}[.\-/]\d{1,2}[.\-/]\d{4}'
            THEN to_date(
                    LPAD((REGEXP_MATCH(REGEXP_REPLACE(TRIM(u.signup_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{4})'))[1], 2, '0')
                    || '-' ||
                    LPAD((REGEXP_MATCH(REGEXP_REPLACE(TRIM(u.signup_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{4})'))[2], 2, '0')
                    || '-' ||
                    (REGEXP_MATCH(REGEXP_REPLACE(TRIM(u.signup_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{4})'))[3],
                'DD-MM-YYYY')
            WHEN TRIM(u.signup_datetime) ~ '^\d{1,2}[.\-/]\d{1,2}[.\-/]\d{2}'
            THEN to_date(
                    LPAD((REGEXP_MATCH(REGEXP_REPLACE(TRIM(u.signup_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{2})'))[1], 2, '0')
                    || '-' ||
                    LPAD((REGEXP_MATCH(REGEXP_REPLACE(TRIM(u.signup_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{2})'))[2], 2, '0')
                    || '-' ||
                    '20' || (REGEXP_MATCH(REGEXP_REPLACE(TRIM(u.signup_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{2})'))[3],
                'DD-MM-YYYY')
            ELSE NULL
        END AS signup_ts
    FROM cohort_users_raw u
),
events_parsed AS 
(
    SELECT
        e.user_id,
        e.event_type,
        CASE
            WHEN TRIM(e.event_datetime) ~ '^\d{2}[.\-/]\d{2}[.\-/]\d{4}'
            THEN to_date(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(TRIM(e.event_datetime), '\s.*$', ''),
                    '[./]', '-', 'g'),
                'DD-MM-YYYY')
            WHEN TRIM(e.event_datetime) ~ '^\d{4}[.\-/]\d{2}[.\-/]\d{2}'
            THEN to_date(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(TRIM(e.event_datetime), '\s.*$', ''),
                    '[./]', '-', 'g'),
                'YYYY-MM-DD')
            WHEN TRIM(e.event_datetime) ~ '^\d{1,2}[.\-/]\d{1,2}[.\-/]\d{4}'
            THEN to_date(
                    LPAD((REGEXP_MATCH(REGEXP_REPLACE(TRIM(e.event_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{4})'))[1], 2, '0')
                    || '-' ||
                    LPAD((REGEXP_MATCH(REGEXP_REPLACE(TRIM(e.event_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{4})'))[2], 2, '0')
                    || '-' ||
                    (REGEXP_MATCH(REGEXP_REPLACE(TRIM(e.event_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{4})'))[3],
                'DD-MM-YYYY')
            WHEN TRIM(e.event_datetime) ~ '^\d{1,2}[.\-/]\d{1,2}[.\-/]\d{2}'
            THEN to_date(
                    LPAD((REGEXP_MATCH(REGEXP_REPLACE(TRIM(e.event_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{2})'))[1], 2, '0')
                    || '-' ||
                    LPAD((REGEXP_MATCH(REGEXP_REPLACE(TRIM(e.event_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{2})'))[2], 2, '0')
                    || '-' ||
                    '20' || (REGEXP_MATCH(REGEXP_REPLACE(TRIM(e.event_datetime), '\s.*$', ''), '(\d+)[.\-/](\d+)[.\-/](\d{2})'))[3],
                'DD-MM-YYYY')
            ELSE NULL
        END AS event_ts
    FROM cohort_events_raw e
    WHERE e.event_datetime IS NOT NULL
      AND e.event_type     IS NOT NULL
),
user_activity AS (
    SELECT
        u.user_id,
        DATE_TRUNC('month', u.signup_ts)::DATE   AS cohort_month,
        u.promo_signup_flag,
        DATE_TRUNC('month', e.event_ts)::DATE    AS activity_month,
        CAST(
            (DATE_PART('year',  e.event_ts) - DATE_PART('year',  u.signup_ts)) * 12
            + (DATE_PART('month', e.event_ts) - DATE_PART('month', u.signup_ts))
        AS INT) AS month_offset FROM users_parsed u
    JOIN events_parsed e ON u.user_id = e.user_id
    WHERE u.signup_ts   IS NOT NULL
      AND e.event_ts    IS NOT NULL
      AND e.event_type  IS NOT NULL
      AND e.event_type <> 'test_event'
)
SELECT
    promo_signup_flag,
    cohort_month,
    month_offset,
    COUNT(DISTINCT user_id) AS users_total
FROM user_activity
WHERE activity_month BETWEEN '2025-01-01' AND '2025-06-01'
GROUP BY promo_signup_flag, cohort_month, month_offset
ORDER BY promo_signup_flag, cohort_month, month_offset;