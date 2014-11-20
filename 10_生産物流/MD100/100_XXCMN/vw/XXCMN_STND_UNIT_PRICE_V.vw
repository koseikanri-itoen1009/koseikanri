CREATE OR REPLACE VIEW xxcmn_stnd_unit_price_v
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
        ,cmpd.item_id                         AS item_id
        ,SUM( cmpd.cmpnt_cost )               AS stnd_unit_price
        ,SUM( CASE cmpm.cost_cmpntcls_code
                WHEN  '01GEN' THEN cmpd.cmpnt_cost
                ELSE 0
              END )                           AS stnd_unit_price_gen
        ,SUM( CASE cmpm.cost_cmpntcls_code
                WHEN  '02SAI' THEN cmpd.cmpnt_cost
                ELSE 0
              END )                           AS stnd_unit_price_sai
        ,SUM( CASE cmpm.cost_cmpntcls_code
                WHEN  '03SZI' THEN cmpd.cmpnt_cost
                ELSE 0
              END )                           AS stnd_unit_price_shi
        ,SUM( CASE cmpm.cost_cmpntcls_code
                WHEN  '04HOU' THEN cmpd.cmpnt_cost
                ELSE 0
              END )                           AS stnd_unit_price_hou
        ,SUM( CASE cmpm.cost_cmpntcls_code
                WHEN  '05GAI' THEN cmpd.cmpnt_cost
                ELSE 0
              END )                           AS stnd_unit_price_gai
        ,SUM( CASE cmpm.cost_cmpntcls_code
                WHEN  '06HKN' THEN cmpd.cmpnt_cost
                ELSE 0
              END )                           AS stnd_unit_price_hok
        ,SUM( CASE cmpm.cost_cmpntcls_code
                WHEN  '07KEI' THEN cmpd.cmpnt_cost
                ELSE 0
              END )                           AS stnd_unit_price_kei
  FROM cm_cldr_hdr_b  cldh
      ,cm_cldr_dtl    cldd
      ,cm_cmpt_dtl    cmpd
      ,cm_cmpt_mst_b  cmpm
  WHERE cmpd.cost_cmpntcls_id = cmpm.cost_cmpntcls_id
  AND   cmpd.whse_code        = FND_PROFILE.VALUE( 'XXCMN_COST_PRICE_WHSE_CODE' )
  AND   cldh.calendar_code    = cmpd.calendar_code
  AND   cldd.calendar_code    = cldh.calendar_code
  GROUP BY TO_CHAR( cldh.start_date, 'YYYY' )
          ,cldd.start_date
          ,cldd.end_date
          ,cmpd.item_id
;
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
