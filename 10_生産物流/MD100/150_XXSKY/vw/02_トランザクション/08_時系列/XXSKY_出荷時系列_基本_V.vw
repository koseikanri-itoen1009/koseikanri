CREATE OR REPLACE VIEW APPS.XXSKY_oΧnρ_ξ{_V
(
 Nx
,
,Ό
,_
,_Ό
,€iζͺ
,€iζͺΌ
,iΪζͺ
,iΪζͺΌ
,QR[h
,iΪ
,iΪΌ
,iΪͺΜ
,oΧqΙ
,oΧqΙΌ
,oΧ_T
,oΧ_U
,oΧ_V
,oΧ_W
,oΧ_X
,oΧ_PO
,oΧ_PP
,oΧ_PQ
,oΧ_P
,oΧ_Q
,oΧ_R
,oΧ_S
)
AS
SELECT  SMSP.year                     year             --Nx
       ,SMSP.pm_dept                  pm_dept          --
       ,LOCT.location_name            pm_dept_name     --Ό
       ,SMSP.hs_branch                hs_branch        --_
       ,BRCH.party_name               hs_branch_name   --_Ό
       ,PRODC.prod_class_code         prod_class_code  --€iζͺ
       ,PRODC.prod_class_name         prod_class_name  --€iζͺΌ
       ,ITEMC.item_class_code         item_class_code  --iΪζͺ
       ,ITEMC.item_class_name         item_class_name  --iΪζͺΌ
       ,CROWD.crowd_code              crowd_code       --QR[h
       ,SMSP.item_code                item_code        --iΪ
       ,ITEM.item_name                item_name        --iΪΌ
       ,ITEM.item_short_name          item_s_name      --iΪͺΜ
       ,SMSP.dlvr_from                dlvr_from        --oΧqΙ
       ,ITMLC.description             dlvr_from_name   --oΧqΙΌ
       ,NVL( SMSP.ship_qty_5th , 0 )  ship_qty_5th     --oΧ_T
       ,NVL( SMSP.ship_qty_6th , 0 )  ship_qty_6th     --oΧ_U
       ,NVL( SMSP.ship_qty_7th , 0 )  ship_qty_7th     --oΧ_V
       ,NVL( SMSP.ship_qty_8th , 0 )  ship_qty_8th     --oΧ_W
       ,NVL( SMSP.ship_qty_9th , 0 )  ship_qty_9th     --oΧ_X
       ,NVL( SMSP.ship_qty_10th, 0 )  ship_qty_10th    --oΧ_PO
       ,NVL( SMSP.ship_qty_11th, 0 )  ship_qty_11th    --oΧ_PP
       ,NVL( SMSP.ship_qty_12th, 0 )  ship_qty_12th    --oΧ_PQ
       ,NVL( SMSP.ship_qty_1th , 0 )  ship_qty_1th     --oΧ_P
       ,NVL( SMSP.ship_qty_2th , 0 )  ship_qty_2th     --oΧ_Q
       ,NVL( SMSP.ship_qty_3th , 0 )  ship_qty_3th     --oΧ_R
       ,NVL( SMSP.ship_qty_4th , 0 )  ship_qty_4th     --oΧ_S
  FROM  (  --NxAA_AoΧiΪAqΙPΚΕWv΅½ixWvπ‘Ι΅½joΧΚWvf[^
           SELECT  ICD.fiscal_year                                                  year           --Nx
                  ,XOHA.performance_management_dept                                 pm_dept        --
                  ,XOHA.head_sales_branch                                           hs_branch      --_
                  ,XOLA.request_item_code                                           item_code      --ΛiΪ
                  ,XOHA.deliver_from                                                dlvr_from      --oΧ³ΫΗqΙ
                   --oΧT`S
                  ,SUM( CASE WHEN ICD.period =  1 THEN XOLA.shipped_quantity END )  ship_qty_5th   --oΧ_T
                  ,SUM( CASE WHEN ICD.period =  2 THEN XOLA.shipped_quantity END )  ship_qty_6th   --oΧ_U
                  ,SUM( CASE WHEN ICD.period =  3 THEN XOLA.shipped_quantity END )  ship_qty_7th   --oΧ_V
                  ,SUM( CASE WHEN ICD.period =  4 THEN XOLA.shipped_quantity END )  ship_qty_8th   --oΧ_W
                  ,SUM( CASE WHEN ICD.period =  5 THEN XOLA.shipped_quantity END )  ship_qty_9th   --oΧ_X
                  ,SUM( CASE WHEN ICD.period =  6 THEN XOLA.shipped_quantity END )  ship_qty_10th  --oΧ_PO
                  ,SUM( CASE WHEN ICD.period =  7 THEN XOLA.shipped_quantity END )  ship_qty_11th  --oΧ_PP
                  ,SUM( CASE WHEN ICD.period =  8 THEN XOLA.shipped_quantity END )  ship_qty_12th  --oΧ_PQ
                  ,SUM( CASE WHEN ICD.period =  9 THEN XOLA.shipped_quantity END )  ship_qty_1th   --oΧ_P
                  ,SUM( CASE WHEN ICD.period = 10 THEN XOLA.shipped_quantity END )  ship_qty_2th   --oΧ_Q
                  ,SUM( CASE WHEN ICD.period = 11 THEN XOLA.shipped_quantity END )  ship_qty_3th   --oΧ_R
                  ,SUM( CASE WHEN ICD.period = 12 THEN XOLA.shipped_quantity END )  ship_qty_4th   --oΧ_S
             FROM  ic_cldr_dtl                  ICD     --έΙJ_
                  ,xxwsh_order_headers_all      XOHA    --σwb_
                  ,xxwsh_order_lines_all        XOLA    --σΎΧ
                  ,oe_transaction_types_all     OTTA    --σ^Cv}X^
            WHERE
              --oΧf[^oπ
                   OTTA.attribute1 = '1'                                      --oΧ
              AND  OTTA.attribute4 = '1'                                      --ΚνoΧ(©{Apόπ­)
              AND  OTTA.order_category_code = 'ORDER'
              AND  XOHA.req_status = '04'                                     --ΐΡvγΟ
              AND  XOHA.latest_external_flag = 'Y'
              AND  XOHA.order_type_id = OTTA.transaction_type_id
              --ΎΧf[^oπ
              AND  XOLA.shipped_quantity <> 0
              AND  NVL( XOLA.delete_flag, 'N' ) <> 'Y'                        --³ψΎΧΘO
              AND  XOHA.order_header_id = XOLA.order_header_id
              --έΙJ_ΖΜπ
              AND  ICD.orgn_code = 'ITOE'
              AND  TO_CHAR( NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ), 'YYYYMM' ) = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
            GROUP BY ICD.fiscal_year
                    ,XOHA.performance_management_dept
                    ,XOHA.head_sales_branch
                    ,XOLA.request_item_code
                    ,XOHA.deliver_from
         )  SMSP                          --oΧΚWv
        ,xxsky_locations_v        LOCT    --ΌζΎpiSYSDATEΕLψf[^πoj
        ,xxsky_cust_accounts_v    BRCH    --_ΌζΎpiSYSDATEΕLψf[^πoj
        ,xxsky_item_mst_v         ITEM    --iΪΌζΎpiSYSDATEΕLψf[^πoj
        ,xxsky_prod_class_v       PRODC   --€iζͺζΎp
        ,xxsky_item_class_v       ITEMC   --iΪζͺζΎp
        ,xxsky_crowd_code_v       CROWD   --QR[hζΎp
        ,xxsky_item_locations_v   ITMLC   --ΫΗqΙΌζΎp
 WHERE
   --ΌζΎ
        SMSP.pm_dept   = LOCT.location_code(+)
   --_ΌζΎ
   AND  SMSP.hs_branch = BRCH.party_number(+)
   --iΪΌζΎ
   AND  SMSP.item_code = ITEM.item_no(+)
   --iΪJeSΌζΎ
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   --oΧ³ΫΗqΙΌζΎ
   AND  SMSP.dlvr_from = ITMLC.segment1(+)
/
COMMENT ON TABLE APPS.XXSKY_oΧnρ_ξ{_V IS 'SKYLINKp oΧnρiξ{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.Nx IS 'Nx'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V. IS ''
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.Ό IS 'Ό'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V._ IS '_'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V._Ό IS '_Ό'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.€iζͺ IS '€iζͺ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.€iζͺΌ IS '€iζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.iΪζͺ IS 'iΪζͺ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.iΪζͺΌ IS 'iΪζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.QR[h IS 'QR[h'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.iΪ IS 'iΪ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.iΪΌ IS 'iΪΌ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.iΪͺΜ IS 'iΪͺΜ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧqΙ IS 'oΧqΙ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧqΙΌ IS 'oΧqΙΌ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_T IS 'oΧ_T'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_U IS 'oΧ_U'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_V IS 'oΧ_V'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_W IS 'oΧ_W'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_X IS 'oΧ_X'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_PO IS 'oΧ_PO'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_PP IS 'oΧ_PP'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_PQ IS 'oΧ_PQ'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_P IS 'oΧ_P'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_Q IS 'oΧ_Q'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_R IS 'oΧ_R'
/
COMMENT ON COLUMN APPS.XXSKY_oΧnρ_ξ{_V.oΧ_S IS 'oΧ_S'
/
