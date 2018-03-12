

SELECT
  by_day,
  by_dow,
  by_month,
  (CAST(by_day AS NUMERIC) + CAST(by_dow AS NUMERIC) + CAST(by_month AS NUMERIC)) / 3 AS net_multiplier,
  all_dates :: DATE                                                                   AS all_dates,
  CASE WHEN EXTRACT(ISODOW FROM all_dates :: DATE) = 7
    THEN 0
  ELSE EXTRACT(ISODOW FROM all_dates :: DATE)
  END                                                                                 AS all_dates_wkday,
  EXTRACT(DAY FROM all_dates :: DATE)                                                 AS all_dates_date,
  EXTRACT(MONTH FROM all_dates :: DATE)                                               AS all_dates_month
FROM generate_series(
         now(),
         DATE('now') + INTERVAL '1 year',
         '1 day' :: INTERVAL) AS all_dates
  JOIN
  (SELECT
     (count / avg(count)
     OVER (
       PARTITION BY part, month )) by_day,
     date,
     month
   FROM
     (SELECT
        count(*)                              AS count,
        EXTRACT(DAY FROM move_date :: DATE)   AS date,
        EXTRACT(MONTH FROM move_date :: DATE) AS month,
        1                                     AS part
      FROM move_plans
        JOIN jobs
          ON jobs.move_plan_id = move_plans.id
      GROUP BY EXTRACT(DAY FROM move_date :: DATE), EXTRACT(MONTH FROM move_date :: DATE)
      ORDER BY date)
       AS test_day) AS by_day
    ON by_day.month = EXTRACT(MONTH FROM all_dates :: DATE) AND by_day.date = EXTRACT(DAY FROM all_dates :: DATE)
  JOIN (SELECT
          (dow_count / avg(dow_count)
          OVER (
            PARTITION BY part )) AS by_dow,
          dow
        FROM
          (
            SELECT
              count(*)                                        AS dow_count,
              CASE WHEN EXTRACT(ISODOW FROM move_date :: DATE) = 7
                THEN 0
              ELSE EXTRACT(ISODOW FROM move_date :: DATE) END AS dow,
              1                                               AS part
            FROM move_plans
              JOIN jobs
                ON jobs.move_plan_id = move_plans.id
            GROUP BY EXTRACT(ISODOW FROM move_date :: DATE)
            ORDER BY dow
          )
            AS test_dow) AS by_dow
    ON by_dow.dow = CASE WHEN EXTRACT(ISODOW FROM all_dates :: DATE) = 7
    THEN 0
                    ELSE EXTRACT(ISODOW FROM all_dates :: DATE) END
  JOIN (SELECT
          (count / avg(count)
          OVER (
            PARTITION BY part )) by_month,
          month
        FROM
          (SELECT
             count(*)                              AS count,
             EXTRACT(MONTH FROM move_date :: DATE) AS month,
             1                                     AS part
           FROM move_plans
             JOIN jobs
               ON jobs.move_plan_id = move_plans.id
           GROUP BY EXTRACT(MONTH FROM move_date :: DATE)
           ORDER BY month) AS test_month) AS by_month
    ON by_month.month = EXTRACT(MONTH FROM all_dates :: DATE)
ORDER BY all_dates;

