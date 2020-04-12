WITH RECURSIVE cte AS (
    SELECT t2.id_tt, q1.id_em
         , IF(q1.dt_b > CONCAT(DATE_FORMAT(q1.dt_b,'%y-%m-%d '),t_o), q1.dt_b, CONCAT(DATE_FORMAT(q1.dt_b,'%y-%m-%d '),t_o)) t_o
         , IF(q1.dt_e <= CONCAT(DATE_FORMAT(q1.dt_e,'%y-%m-%d '), t_c), q1.dt_e, CONCAT(DATE_FORMAT(q1.dt_e,'%y-%m-%d '), t_c)) t_c
     FROM t2
     JOIN (
         SELECT y1.id_em, y1.id_tt, y1.dt_b, IFNULL(y2.dt, y1.dt_e) dt_e
           FROM (
                    SELECT id_tt, id_em, MIN(dt) dt_b, MAX(dt) dt_e
                    FROM t1
                    GROUP BY id_tt, id_em
                ) y1
           LEFT JOIN (
                        SELECT
                               n1.id_em, n1.id_tt
                               , IF(n2.st = 'no',CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),n2.t_c) as datetime)
                                   ,IF(
                                       CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'00:00') as datetime) <= n1.dt
                                       AND n1.dt <= CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'09:59') as datetime)
                                       ,CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),n2.t_c) as datetime)
                                       ,CAST(CONCAT(DATE_FORMAT(ADDDATE(n1.dt,1),'%y-%m-%d '),n2.t_c) as datetime)
                                       )) dt
                           FROM (
                            SELECT id_em, id_tt, MAX(dt) dt
                              FROM t1
                             WHERE st = 'ON'
                             GROUP BY id_em, id_tt
                              ) n1
                           JOIN t2 n2
                            ON n1.id_tt = n2.id_tt AND (
                                (CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),n2.t_c) as datetime) > n1.dt AND n2.st = 'no')
                                OR (
                                    n2.st = 'yes'
                                    AND (
                                            CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'10:00') as datetime) <= n1.dt
                                            AND n1.dt <= CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'23:59:59') as datetime)
                                            AND CAST(CONCAT(DATE_FORMAT(ADDDATE(n1.dt,1),'%y-%m-%d '),n2.t_c) as datetime) > n1.dt
                                            OR
                                            CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'00:00') as datetime) <= n1.dt
                                            AND n1.dt <= CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'09:59') as datetime)
                                            AND CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),n2.t_c) as datetime) > n1.dt
                                        )
                                    )
                                )
                          WHERE NOT EXISTS (
                            SELECT 1
                            FROM (
                                     SELECT id_em, id_tt, MAX(dt) dt
                                     FROM t1
                                     WHERE st = 'OFF'
                                     GROUP BY id_em, id_tt
                                 ) s
                            WHERE s.id_em = n1.id_em AND s.id_tt = n1.id_tt
                             AND s.dt > n1.dt)

               ) y2
         ON y2.id_em = y1.id_em AND y2.id_tt = y1.id_tt
     ) q1
       ON q1.id_tt = t2.id_tt
    UNION ALL
    SELECT id_tt, id_em, ADDTIME(t_o, '0:15'), t_c
     FROM cte
    WHERE t_o < t_c
)

SELECT cte.id_tt, cte.id_em, r.d dt, TIME_FORMAT(cte.t_o, '%H%i') i, IF(TIMESTAMPDIFF(MINUTE, cte.t_o, r.dt_e)> 15, 15, TIMESTAMPDIFF(MINUTE, cte.t_o, r.dt_e)) quant, cte.t_o, cte.t_c, r.dt_b, r.dt_e
  FROM cte
  join (
        SELECT w.id_tt, w.id_em
     , DATE(w.dt) d
     , IF(MAX(w.dt4) IS NULL, MIN(w.dt2), MIN(w.dt4)) dt_b
     , w.dt dt_e
#     , MIN(w.dt2) dt2, MAX(w.dt3) dt3, MIN(w.dt4) dt4
 FROM (
        SELECT s1.*, s2.dt dt4
          FROM (
              SELECT q1.id_em, q1.id_tt, q1.dt, MIN(q2.dt) dt2, MAX(q3.dt) dt3
              FROM (
                       SELECT id_em, id_tt, dt
                       FROM t1
                       WHERE st = 'OFF'
                       UNION
                        SELECT
                               n1.id_em, n1.id_tt
                               , IF(n2.st = 'no',CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),n2.t_c) as datetime)
                                   ,IF(
                                       CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'00:00') as datetime) <= n1.dt
                                       AND n1.dt <= CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'09:59') as datetime)
                                       ,CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),n2.t_c) as datetime)
                                       ,CAST(CONCAT(DATE_FORMAT(ADDDATE(n1.dt,1),'%y-%m-%d '),n2.t_c) as datetime)
                                       )) dt
                           FROM (
                            SELECT id_em, id_tt, MAX(dt) dt
                              FROM t1
                             WHERE st = 'ON'
                             GROUP BY id_em, id_tt
                              ) n1
                           JOIN t2 n2
                            ON n1.id_tt = n2.id_tt AND (
                                (CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),n2.t_c) as datetime) > n1.dt AND n2.st = 'no')
                                OR (
                                    n2.st = 'yes'
                                    AND (
                                            CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'10:00') as datetime) <= n1.dt
                                            AND n1.dt <= CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'23:59:59') as datetime)
                                            AND CAST(CONCAT(DATE_FORMAT(ADDDATE(n1.dt,1),'%y-%m-%d '),n2.t_c) as datetime) > n1.dt
                                            OR
                                            CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'00:00') as datetime) <= n1.dt
                                            AND n1.dt <= CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),'09:59') as datetime)
                                            AND CAST(CONCAT(DATE_FORMAT(n1.dt,'%y-%m-%d '),n2.t_c) as datetime) > n1.dt
                                        )
                                    )
                                )
                          WHERE NOT EXISTS (
                            SELECT 1
                            FROM (
                                     SELECT id_em, id_tt, MAX(dt) dt
                                     FROM t1
                                     WHERE st = 'OFF'
                                     GROUP BY id_em, id_tt
                                 ) s
                            WHERE s.id_em = n1.id_em AND s.id_tt = n1.id_tt
                             AND s.dt > n1.dt)
                   ) q1
                       LEFT JOIN (
                  SELECT *
                  FROM t1
                  where st = 'ON'
              ) q2
                ON q2.id_em = q1.id_em AND q2.id_tt = q1.id_tt AND q1.dt > q2.dt
              LEFT JOIN (
                  SELECT *
                  FROM t1
                  where st = 'OFF'
              ) q3
               ON q3.id_em = q1.id_em AND q3.id_tt = q1.id_tt AND q3.dt < q1.dt
              GROUP BY q1.id_em, q1.id_tt, q1.dt
              ORDER BY q1.id_em, q1.id_tt, q1.dt
          ) s1
           LEFT JOIN (
              SELECT *
              FROM t1
            where st = 'ON'
          ) s2
           ON s2.id_em = s1.id_em AND s2.id_tt = s1.id_tt AND s2.dt > s1.dt3
         ORDER BY s1.id_em, s1.id_tt, s1.dt, s1.dt2, s1.dt3, s2.dt
      ) w
  GROUP BY w.id_em, w.id_tt, w.dt
  ORDER BY w.id_em, w.id_tt, w.dt
      ) r
    ON r.id_tt = cte.id_tt AND r.id_em = cte.id_em AND r.dt_b <= cte.t_o AND cte.t_o < r.dt_e
 ORDER BY id_tt, t_o
