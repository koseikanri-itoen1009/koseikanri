/*************************************************************************
 * 
 * View  Name      : XXSKZ_ψζvζ_ϊΚ_V
 * Description     : XXSKZ_ψζvζ_ϊΚ_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ρμ¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_ψζvζ_ϊΚ_V
(
 N
,€iζͺ
,€iζͺΌ
,iΪζͺ
,iΪζͺΌ
,QR[h
,ΰOζͺ
,ΰOζͺΌ
,iΪ
,iΪΌ
,iΪͺΜ
,oΧ³ΫΗqΙ
,oΧ³ΫΗqΙΌ
,_
,_Ό
,P[Xό
,ΚPϊ
,ΚQϊ
,ΚRϊ
,ΚSϊ
,ΚTϊ
,ΚUϊ
,ΚVϊ
,ΚWϊ
,ΚXϊ
,ΚPOϊ
,ΚPPϊ
,ΚPQϊ
,ΚPRϊ
,ΚPSϊ
,ΚPTϊ
,ΚPUϊ
,ΚPVϊ
,ΚPWϊ
,ΚPXϊ
,ΚQOϊ
,ΚQPϊ
,ΚQQϊ
,ΚQRϊ
,ΚQSϊ
,ΚQTϊ
,ΚQUϊ
,ΚQVϊ
,ΚQWϊ
,ΚQXϊ
,ΚROϊ
,ΚRPϊ
)
AS
SELECT  SMFC.frct_ym                frct_ym            --N
       ,PRODC.prod_class_code       prod_class_code    --€iζͺ
       ,PRODC.prod_class_name       prod_class_name    --€iζͺΌ
       ,ITEMC.item_class_code       item_class_code    --iΪζͺ
       ,ITEMC.item_class_name       item_class_name    --iΪζͺΌ
       ,CROWD.crowd_code            crowd_code         --QR[h
       ,INOUT.inout_class_code      inout_class_code   --ΰOζͺ
       ,INOUT.inout_class_name      inout_class_name   --ΰOζͺΌ 
       ,ITEM.item_no                item_code          --iΪ
       ,ITEM.item_name              item_name          --iΪΌ
       ,ITEM.item_short_name        item_s_name        --iΪͺΜ
       ,SMFC.dlvr_from              dlvr_from          --oΧ³ΫΗqΙ
       ,ITMLC.description           dlvr_from_name     --oΧ³ΫΗqΙΌ
       ,SMFC.branch                 branch             --_
       ,BRCH.party_name             branch_name        --_Ό
       ,ITEM.num_of_cases           incase_qty         --P[Xό
       ,NVL( SMFC.fc_qty_01dy, 0 )  fc_qty_01dy        --ΚPϊ
       ,NVL( SMFC.fc_qty_02dy, 0 )  fc_qty_02dy        --ΚQϊ
       ,NVL( SMFC.fc_qty_03dy, 0 )  fc_qty_03dy        --ΚRϊ
       ,NVL( SMFC.fc_qty_04dy, 0 )  fc_qty_04dy        --ΚSϊ
       ,NVL( SMFC.fc_qty_05dy, 0 )  fc_qty_05dy        --ΚTϊ
       ,NVL( SMFC.fc_qty_06dy, 0 )  fc_qty_06dy        --ΚUϊ
       ,NVL( SMFC.fc_qty_07dy, 0 )  fc_qty_07dy        --ΚVϊ
       ,NVL( SMFC.fc_qty_08dy, 0 )  fc_qty_08dy        --ΚWϊ
       ,NVL( SMFC.fc_qty_09dy, 0 )  fc_qty_09dy        --ΚXϊ
       ,NVL( SMFC.fc_qty_10dy, 0 )  fc_qty_10dy        --ΚPOϊ
       ,NVL( SMFC.fc_qty_11dy, 0 )  fc_qty_11dy        --ΚPPϊ
       ,NVL( SMFC.fc_qty_12dy, 0 )  fc_qty_12dy        --ΚPQϊ
       ,NVL( SMFC.fc_qty_13dy, 0 )  fc_qty_13dy        --ΚPRϊ
       ,NVL( SMFC.fc_qty_14dy, 0 )  fc_qty_14dy        --ΚPSϊ
       ,NVL( SMFC.fc_qty_15dy, 0 )  fc_qty_15dy        --ΚPTϊ
       ,NVL( SMFC.fc_qty_16dy, 0 )  fc_qty_16dy        --ΚPUϊ
       ,NVL( SMFC.fc_qty_17dy, 0 )  fc_qty_17dy        --ΚPVϊ
       ,NVL( SMFC.fc_qty_18dy, 0 )  fc_qty_18dy        --ΚPWϊ
       ,NVL( SMFC.fc_qty_19dy, 0 )  fc_qty_19dy        --ΚPXϊ
       ,NVL( SMFC.fc_qty_20dy, 0 )  fc_qty_20dy        --ΚQOϊ
       ,NVL( SMFC.fc_qty_21dy, 0 )  fc_qty_21dy        --ΚQPϊ
       ,NVL( SMFC.fc_qty_22dy, 0 )  fc_qty_22dy        --ΚQQϊ
       ,NVL( SMFC.fc_qty_23dy, 0 )  fc_qty_23dy        --ΚQRϊ
       ,NVL( SMFC.fc_qty_24dy, 0 )  fc_qty_24dy        --ΚQSϊ
       ,NVL( SMFC.fc_qty_25dy, 0 )  fc_qty_25dy        --ΚQTϊ
       ,NVL( SMFC.fc_qty_26dy, 0 )  fc_qty_26dy        --ΚQUϊ
       ,NVL( SMFC.fc_qty_27dy, 0 )  fc_qty_27dy        --ΚQVϊ
       ,NVL( SMFC.fc_qty_28dy, 0 )  fc_qty_28dy        --ΚQWϊ
       ,NVL( SMFC.fc_qty_29dy, 0 )  fc_qty_29dy        --ΚQXϊ
       ,NVL( SMFC.fc_qty_30dy, 0 )  fc_qty_30dy        --ΚROϊ
       ,NVL( SMFC.fc_qty_31dy, 0 )  fc_qty_31dy        --ΚRPϊ
  FROM  ( --NAqΙA_AiΪPΚΕWv΅½iϊΚπ‘Ι΅½jvζΚWvf[^
          SELECT  TO_CHAR( MFDT.forecast_date, 'YYYYMM' )                                                              frct_ym      --\θN
                 ,MFDN.attribute2                                                                                      dlvr_from    --oΧ³ΫΗqΙR[h
                 ,MFDN.attribute3                                                                                      branch       --_R[h
                 ,MFDT.inventory_item_id                                                                               item_id      --oΧiΪID
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '01' THEN MFDT.current_forecast_quantity END )  fc_qty_01dy  --ΚPϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '02' THEN MFDT.current_forecast_quantity END )  fc_qty_02dy  --ΚQϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '03' THEN MFDT.current_forecast_quantity END )  fc_qty_03dy  --ΚRϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '04' THEN MFDT.current_forecast_quantity END )  fc_qty_04dy  --ΚSϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '05' THEN MFDT.current_forecast_quantity END )  fc_qty_05dy  --ΚTϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '06' THEN MFDT.current_forecast_quantity END )  fc_qty_06dy  --ΚUϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '07' THEN MFDT.current_forecast_quantity END )  fc_qty_07dy  --ΚVϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '08' THEN MFDT.current_forecast_quantity END )  fc_qty_08dy  --ΚWϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '09' THEN MFDT.current_forecast_quantity END )  fc_qty_09dy  --ΚXϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '10' THEN MFDT.current_forecast_quantity END )  fc_qty_10dy  --ΚPOϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '11' THEN MFDT.current_forecast_quantity END )  fc_qty_11dy  --ΚPPϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '12' THEN MFDT.current_forecast_quantity END )  fc_qty_12dy  --ΚPQϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '13' THEN MFDT.current_forecast_quantity END )  fc_qty_13dy  --ΚPRϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '14' THEN MFDT.current_forecast_quantity END )  fc_qty_14dy  --ΚPSϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '15' THEN MFDT.current_forecast_quantity END )  fc_qty_15dy  --ΚPTϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '16' THEN MFDT.current_forecast_quantity END )  fc_qty_16dy  --ΚPUϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '17' THEN MFDT.current_forecast_quantity END )  fc_qty_17dy  --ΚPVϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '18' THEN MFDT.current_forecast_quantity END )  fc_qty_18dy  --ΚPWϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '19' THEN MFDT.current_forecast_quantity END )  fc_qty_19dy  --ΚPXϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '20' THEN MFDT.current_forecast_quantity END )  fc_qty_20dy  --ΚQOϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '21' THEN MFDT.current_forecast_quantity END )  fc_qty_21dy  --ΚQPϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '22' THEN MFDT.current_forecast_quantity END )  fc_qty_22dy  --ΚQQϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '23' THEN MFDT.current_forecast_quantity END )  fc_qty_23dy  --ΚQRϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '24' THEN MFDT.current_forecast_quantity END )  fc_qty_24dy  --ΚQSϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '25' THEN MFDT.current_forecast_quantity END )  fc_qty_25dy  --ΚQTϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '26' THEN MFDT.current_forecast_quantity END )  fc_qty_26dy  --ΚQUϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '27' THEN MFDT.current_forecast_quantity END )  fc_qty_27dy  --ΚQVϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '28' THEN MFDT.current_forecast_quantity END )  fc_qty_28dy  --ΚQWϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '29' THEN MFDT.current_forecast_quantity END )  fc_qty_29dy  --ΚQXϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '30' THEN MFDT.current_forecast_quantity END )  fc_qty_30dy  --ΚROϊ
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '31' THEN MFDT.current_forecast_quantity END )  fc_qty_31dy  --ΚRPϊ
            FROM  mrp_forecast_designators    MFDN    --tH[LXgΌe[u
                 ,mrp_forecast_dates          MFDT    --tH[LXgϊte[u
           WHERE  MFDN.attribute1 = '01'                                --ψζvζ
             AND  MFDN.organization_id = fnd_profile.VALUE( 'XXCMN_MASTER_ORG_ID' )
             AND  MFDN.forecast_designator = MFDT.forecast_designator
             AND  MFDN.organization_id = MFDT.organization_id
          GROUP BY  TO_CHAR( MFDT.forecast_date, 'YYYYMM' )
                   ,MFDN.attribute2
                   ,MFDN.attribute3
                   ,MFDT.inventory_item_id
        )                       SMFC    --ψζvζϊΚWv
       ,xxskz_item_mst2_v       ITEM    --iΪΌζΎp
       ,xxskz_prod_class_v      PRODC   --€iζͺζΎp
       ,xxskz_item_class_v      ITEMC   --iΪζͺζΎp
       ,xxskz_crowd_code_v      CROWD   --QR[hζΎp
       ,xxskz_inout_class_v     INOUT   --ΰOζͺζΎp
       ,xxskz_item_locations_v  ITMLC   --ΫΗqΙΌζΎp
       ,xxskz_cust_accounts2_v  BRCH    --_ΌζΎp
 WHERE
   --iΪΌζΎ
        SMFC.item_id   = ITEM.inventory_item_id(+)
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) >= ITEM.start_date_active(+)  --ϊtΕυ
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) <= ITEM.end_date_active(+)    --ϊtΕυ
   --iΪJeSΌζΎ
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   AND  ITEM.item_id   = INOUT.item_id(+)
   --oΧ³ΫΗqΙΌζΎ
   AND  SMFC.dlvr_from = ITMLC.segment1(+)
   --_ΌζΎ
   AND  SMFC.branch    = BRCH.party_number(+)
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) >= BRCH.start_date_active(+)  --ϊtΕυ
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) <= BRCH.end_date_active(+)    --ϊtΕυ
/
COMMENT ON TABLE APPS.XXSKZ_ψζvζ_ϊΚ_V IS 'SKYLINKp ψζvζiϊΚjVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.N             IS 'N'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.€iζͺ         IS '€iζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.€iζͺΌ       IS '€iζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.iΪζͺ         IS 'iΪζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.iΪζͺΌ       IS 'iΪζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.QR[h         IS 'QR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΰOζͺ         IS 'ΰOζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΰOζͺΌ       IS 'ΰOζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.iΪ             IS 'iΪ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.iΪΌ           IS 'iΪΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.iΪͺΜ         IS 'iΪͺΜ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.oΧ³ΫΗqΙ   IS 'oΧ³ΫΗqΙ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.oΧ³ΫΗqΙΌ IS 'oΧ³ΫΗqΙΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V._             IS '_'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V._Ό           IS '_Ό'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.P[Xό       IS 'P[Xό'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPϊ         IS 'ΚPϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQϊ         IS 'ΚQϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚRϊ         IS 'ΚRϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚSϊ         IS 'ΚSϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚTϊ         IS 'ΚTϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚUϊ         IS 'ΚUϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚVϊ         IS 'ΚVϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚWϊ         IS 'ΚWϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚXϊ         IS 'ΚXϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPOϊ       IS 'ΚPOϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPPϊ       IS 'ΚPPϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPQϊ       IS 'ΚPQϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPRϊ       IS 'ΚPRϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPSϊ       IS 'ΚPSϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPTϊ       IS 'ΚPTϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPUϊ       IS 'ΚPUϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPVϊ       IS 'ΚPVϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPWϊ       IS 'ΚPWϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚPXϊ       IS 'ΚPXϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQOϊ       IS 'ΚQOϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQPϊ       IS 'ΚQPϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQQϊ       IS 'ΚQQϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQRϊ       IS 'ΚQRϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQSϊ       IS 'ΚQSϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQTϊ       IS 'ΚQTϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQUϊ       IS 'ΚQUϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQVϊ       IS 'ΚQVϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQWϊ       IS 'ΚQWϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚQXϊ       IS 'ΚQXϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚROϊ       IS 'ΚROϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ψζvζ_ϊΚ_V.ΚRPϊ       IS 'ΚRPϊ'
/
