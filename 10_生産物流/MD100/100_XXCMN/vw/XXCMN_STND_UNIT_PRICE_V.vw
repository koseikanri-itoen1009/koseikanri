CREATE OR REPLACE FORCE VIEW xxcmn_stnd_unit_price_v
  (
    period
   ,start_date_active
   ,end_date_active
   ,item_id
   ,stnd_unit_price
   ,stnd_unit_price_gen
   ,stnd_unit_price_sai
   ,stnd_unit_price_shi
   ,stnd_unit_price_hou
   ,stnd_unit_price_gai
   ,stnd_unit_price_hok
   ,stnd_unit_price_kei
  )
AS
  SELECT TO_CHAR( cldh.start_date, 'YYYY' )   AS period
        ,cldd.start_date                      AS start_date_active
        ,cldd.end_date                        AS end_date_active
        ,cmpd1.item_id                        AS item_id
        ,(cmpd1.cmpnt_cost
        + cmpd2.cmpnt_cost
        + cmpd3.cmpnt_cost
        + cmpd4.cmpnt_cost
        + cmpd5.cmpnt_cost
        + cmpd6.cmpnt_cost
        + cmpd7.cmpnt_cost
        + cmpd8.cmpnt_cost
        + cmpd9.cmpnt_cost
        + cmpd10.cmpnt_cost)                  AS stnd_unit_price
        ,cmpd1.cmpnt_cost                     AS stnd_unit_price_gen
        ,cmpd2.cmpnt_cost                     AS stnd_unit_price_sai
        ,cmpd3.cmpnt_cost                     AS stnd_unit_price_shi
        ,cmpd4.cmpnt_cost                     AS stnd_unit_price_hou
        ,cmpd5.cmpnt_cost                     AS stnd_unit_price_gai
        ,cmpd6.cmpnt_cost                     AS stnd_unit_price_hok
        ,cmpd7.cmpnt_cost                     AS stnd_unit_price_kei
  FROM   cm_cldr_hdr_b  cldh
        ,cm_cldr_dtl    cldd
        ,cm_cmpt_dtl    cmpd1
        ,cm_cmpt_dtl    cmpd2
        ,cm_cmpt_dtl    cmpd3
        ,cm_cmpt_dtl    cmpd4
        ,cm_cmpt_dtl    cmpd5
        ,cm_cmpt_dtl    cmpd6
        ,cm_cmpt_dtl    cmpd7
        ,cm_cmpt_dtl    cmpd8
        ,cm_cmpt_dtl    cmpd9
        ,cm_cmpt_dtl    cmpd10
--        ,cm_cmpt_mst_b  cmpm1
--        ,cm_cmpt_mst_b  cmpm2
--        ,cm_cmpt_mst_b  cmpm3
--        ,cm_cmpt_mst_b  cmpm4
--        ,cm_cmpt_mst_b  cmpm5
--        ,cm_cmpt_mst_b  cmpm6
--        ,cm_cmpt_mst_b  cmpm7
--        ,cm_cmpt_mst_b  cmpm8
--        ,cm_cmpt_mst_b  cmpm9
--        ,cm_cmpt_mst_b  cmpm10
  WHERE  cldh.calendar_code        = cldd.calendar_code
  AND    cldd.calendar_code        = cmpd1.calendar_code
  AND    cldd.period_code          = cmpd1.period_code
  AND    cmpd1.whse_code           = FND_PROFILE.VALUE( 'XXCMN_COST_PRICE_WHSE_CODE' )
  AND    cmpd1.cost_cmpntcls_id    = 1
--  AND    cmpd1.cost_cmpntcls_id    = cmpm1.cost_cmpntcls_id
--  AND    cmpm1.cost_cmpntcls_code  = '01GEN'
  AND    cldd.calendar_code        = cmpd2.calendar_code
  AND    cldd.period_code          = cmpd2.period_code
  AND    cmpd2.whse_code           = cmpd1.whse_code
  AND    cmpd2.item_id             = cmpd1.item_id
  AND    cmpd2.cost_cmpntcls_id    = 2
--  AND    cmpd2.cost_cmpntcls_id    = cmpm2.cost_cmpntcls_id
--  AND    cmpm2.cost_cmpntcls_code  = '02SAI'
  AND    cldd.calendar_code        = cmpd3.calendar_code
  AND    cldd.period_code          = cmpd3.period_code
  AND    cmpd3.whse_code           = cmpd1.whse_code
  AND    cmpd3.item_id             = cmpd1.item_id
  AND    cmpd3.cost_cmpntcls_id    = 3
--  AND    cmpd3.cost_cmpntcls_id    = cmpm3.cost_cmpntcls_id
--  AND    cmpm3.cost_cmpntcls_code  = '03SZI'
  AND    cldd.calendar_code        = cmpd4.calendar_code
  AND    cldd.period_code          = cmpd4.period_code
  AND    cmpd4.whse_code           = cmpd1.whse_code
  AND    cmpd4.item_id             = cmpd1.item_id
  AND    cmpd4.cost_cmpntcls_id    = 4
--  AND    cmpd4.cost_cmpntcls_id    = cmpm4.cost_cmpntcls_id
--  AND    cmpm4.cost_cmpntcls_code  = '04HOU'
  AND    cldd.calendar_code        = cmpd5.calendar_code
  AND    cldd.period_code          = cmpd5.period_code
  AND    cmpd5.whse_code           = cmpd1.whse_code
  AND    cmpd5.item_id             = cmpd1.item_id
  AND    cmpd5.cost_cmpntcls_id    = 5
--  AND    cmpd5.cost_cmpntcls_id    = cmpm5.cost_cmpntcls_id
--  AND    cmpm5.cost_cmpntcls_code  = '05GAI'
  AND    cldd.calendar_code        = cmpd6.calendar_code
  AND    cldd.period_code          = cmpd6.period_code
  AND    cmpd6.whse_code           = cmpd1.whse_code
  AND    cmpd6.item_id             = cmpd1.item_id
  AND    cmpd6.cost_cmpntcls_id    = 6
--  AND    cmpd6.cost_cmpntcls_id    = cmpm6.cost_cmpntcls_id
--  AND    cmpm6.cost_cmpntcls_code  = '06HKN'
  AND    cldd.calendar_code        = cmpd7.calendar_code
  AND    cldd.period_code          = cmpd7.period_code
  AND    cmpd7.whse_code           = cmpd1.whse_code
  AND    cmpd7.item_id             = cmpd1.item_id
  AND    cmpd7.cost_cmpntcls_id    = 7
--  AND    cmpd7.cost_cmpntcls_id    = cmpm7.cost_cmpntcls_id
--  AND    cmpm7.cost_cmpntcls_code  = '07KEI'
  AND    cldd.calendar_code        = cmpd8.calendar_code
  AND    cldd.period_code          = cmpd8.period_code
  AND    cmpd8.whse_code           = cmpd1.whse_code
  AND    cmpd8.item_id             = cmpd1.item_id
  AND    cmpd8.cost_cmpntcls_id    = 8
--  AND    cmpd8.cost_cmpntcls_id    = cmpm8.cost_cmpntcls_id
--  AND    cmpm8.cost_cmpntcls_code  = '08YB1'
  AND    cldd.calendar_code        = cmpd9.calendar_code
  AND    cldd.period_code          = cmpd9.period_code
  AND    cmpd9.whse_code           = cmpd1.whse_code
  AND    cmpd9.item_id             = cmpd1.item_id
  AND    cmpd9.cost_cmpntcls_id    = 11
--  AND    cmpd9.cost_cmpntcls_id    = cmpm9.cost_cmpntcls_id
--  AND    cmpm9.cost_cmpntcls_code  = '09YB2'
  AND    cldd.calendar_code        = cmpd10.calendar_code
  AND    cldd.period_code          = cmpd10.period_code
  AND    cmpd10.whse_code          = cmpd1.whse_code
  AND    cmpd10.item_id            = cmpd1.item_id
  AND    cmpd10.cost_cmpntcls_id   = 12;
--  AND    cmpd10.cost_cmpntcls_id   = cmpm10.cost_cmpntcls_id
--  AND    cmpm10.cost_cmpntcls_code = '10YB3';
--
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.period                IS '年度' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.start_date_active     IS '適用開始日' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.end_date_active       IS '適用終了日' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.item_id               IS '品目ID' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.stnd_unit_price       IS '標準原価' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.stnd_unit_price_gen   IS '標準原価＿原料' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.stnd_unit_price_sai   IS '標準原価＿再製費' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.stnd_unit_price_shi   IS '標準原価＿資材費' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.stnd_unit_price_hou   IS '標準原価＿包装費' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.stnd_unit_price_gai   IS '標準原価＿外注加工費' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.stnd_unit_price_hok   IS '標準原価＿保管費' ;
COMMENT ON COLUMN xxcmn_stnd_unit_price_v.stnd_unit_price_kei   IS '標準原価＿その他経費' ;
--
COMMENT ON TABLE  xxcmn_stnd_unit_price_v IS '標準原価情報View' ;
