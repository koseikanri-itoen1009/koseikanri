/*************************************************************************
 * 
 * View  Name      : XXSKZ_όoΙξρ_­ϊ_V
 * Description     : XXSKZ_όoΙξρ_­ϊ_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK μ    ρμ¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_όoΙξρ_­ϊ_V
(
 N
,όoΙζͺ
,\θΐΡζͺ
,RR[h
,RR[hΌ
,€iζͺR[h
,€iζͺΌ
,iΪζͺR[h
,iΪζͺΌ
,ΰOζͺR[h
,ΰOζͺΌ
,QR[h
,iΪR[h
,iΪΌ
,iΪͺΜ
,P[Xό
,Ό`R[h
,Ό`
,qΙR[h
,ΫΗκR[h
,ΫΗκΌ
,ΫΗκͺΜ
,σ₯ζR[h
,σ₯ζΌ
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
SELECT  SIOT.yyyymm                    AS yyyymm                   --N
       ,CASE WHEN SIOT.in_out_kbn = 1 THEN 'όΙ'    --όoΙζͺR[hͺ1:όΙ
             WHEN SIOT.in_out_kbn = 2 THEN 'oΙ'    --όoΙζͺR[hͺ2:oΙ
             ELSE SIOT.in_out_kbn
        END                            AS in_out_kbn_name          --όoΙζͺ
       ,CASE WHEN SIOT.status = 1 THEN '\θ'        --\θΐΡζͺR[hͺ1:όΙ
             WHEN SIOT.status = 2 THEN 'ΐΡ'        --\θΐΡζͺR[hͺ2:oΙ
             ELSE SIOT.status
        END                            AS status_name              --\θΐΡζͺ
       ,SIOT.reason_code               AS reason_code              --RR[h
       ,FLV01.meaning                  AS reason_code_name         --RR[hΌ
       ,XPCV.prod_class_code           AS prod_class_code          --€iζͺR[h
       ,XPCV.prod_class_name           AS prod_class_name          --€iζͺΌ
       ,XICV.item_class_code           AS item_class_code          --iΪζͺR[h
       ,XICV.item_class_name           AS item_class_name          --iΪζͺΌ
       ,XIOCV.inout_class_code         AS inout_class_code         --ΰOζͺR[h
       ,XIOCV.inout_class_name         AS inout_class_name         --ΰOζͺΌ
       ,XCCV.crowd_code                AS crowd_code               --QR[h
       ,SIOT.item_no                   AS item_no                  --iΪR[h
       ,SIOT.item_name                 AS item_name                --iΪΌ
       ,SIOT.item_short_name           AS item_short_name          --iΪͺΜ
       ,SIOT.case_content              AS case_content             --P[Xό
       ,IWM.attribute1                 AS cust_stc_whse            --Ό`R[h
       ,FLV02.meaning                  AS cust_stc_whse_name       --Ό`
       ,SIOT.whse_code                 AS whse_code                --qΙR[h
       ,SIOT.location_code             AS location_code            --ΫΗκR[h
       ,SIOT.location                  AS location                 --ΫΗκΌ
       ,SIOT.location_s_name           AS location_s_name          --ΫΗκͺΜ
       ,SIOT.ukebaraisaki_code         AS ukebaraisaki_code        --σ₯ζR[h
       ,SIOT.ukebaraisaki_name         AS ukebaraisaki_name        --σ₯ζΌ
       ,NVL( SIOT.qty_01dy, 0 )        AS qty_01dy                 --ΚPϊ
       ,NVL( SIOT.qty_02dy, 0 )        AS qty_02dy                 --ΚQϊ
       ,NVL( SIOT.qty_03dy, 0 )        AS qty_03dy                 --ΚRϊ
       ,NVL( SIOT.qty_04dy, 0 )        AS qty_04dy                 --ΚSϊ
       ,NVL( SIOT.qty_05dy, 0 )        AS qty_05dy                 --ΚTϊ
       ,NVL( SIOT.qty_06dy, 0 )        AS qty_06dy                 --ΚUϊ
       ,NVL( SIOT.qty_07dy, 0 )        AS qty_07dy                 --ΚVϊ
       ,NVL( SIOT.qty_08dy, 0 )        AS qty_08dy                 --ΚWϊ
       ,NVL( SIOT.qty_09dy, 0 )        AS qty_09dy                 --ΚXϊ
       ,NVL( SIOT.qty_10dy, 0 )        AS qty_10dy                 --ΚPOϊ
       ,NVL( SIOT.qty_11dy, 0 )        AS qty_11dy                 --ΚPPϊ
       ,NVL( SIOT.qty_12dy, 0 )        AS qty_12dy                 --ΚPQϊ
       ,NVL( SIOT.qty_13dy, 0 )        AS qty_13dy                 --ΚPRϊ
       ,NVL( SIOT.qty_14dy, 0 )        AS qty_14dy                 --ΚPSϊ
       ,NVL( SIOT.qty_15dy, 0 )        AS qty_15dy                 --ΚPTϊ
       ,NVL( SIOT.qty_16dy, 0 )        AS qty_16dy                 --ΚPUϊ
       ,NVL( SIOT.qty_17dy, 0 )        AS qty_17dy                 --ΚPVϊ
       ,NVL( SIOT.qty_18dy, 0 )        AS qty_18dy                 --ΚPWϊ
       ,NVL( SIOT.qty_19dy, 0 )        AS qty_19dy                 --ΚPXϊ
       ,NVL( SIOT.qty_20dy, 0 )        AS qty_20dy                 --ΚQOϊ
       ,NVL( SIOT.qty_21dy, 0 )        AS qty_21dy                 --ΚQPϊ
       ,NVL( SIOT.qty_22dy, 0 )        AS qty_22dy                 --ΚQQϊ
       ,NVL( SIOT.qty_23dy, 0 )        AS qty_23dy                 --ΚQRϊ
       ,NVL( SIOT.qty_24dy, 0 )        AS qty_24dy                 --ΚQSϊ
       ,NVL( SIOT.qty_25dy, 0 )        AS qty_25dy                 --ΚQTϊ
       ,NVL( SIOT.qty_26dy, 0 )        AS qty_26dy                 --ΚQUϊ
       ,NVL( SIOT.qty_27dy, 0 )        AS qty_27dy                 --ΚQVϊ
       ,NVL( SIOT.qty_28dy, 0 )        AS qty_28dy                 --ΚQWϊ
       ,NVL( SIOT.qty_29dy, 0 )        AS qty_29dy                 --ΚQXϊ
       ,NVL( SIOT.qty_30dy, 0 )        AS qty_30dy                 --ΚROϊ
       ,NVL( SIOT.qty_31dy, 0 )        AS qty_31dy                 --ΚRPϊ
  FROM  ( --­ϊWvΜέπs€
          SELECT  TO_CHAR( XIOT.leaving_date, 'YYYYMM' )           AS yyyymm                 --N
                 ,XIOT.in_out_kbn                                  AS in_out_kbn             --όoΙζͺ
                 ,XIOT.status                                      AS status                 --\θΐΡζͺ
                 ,XIOT.reason_code                                 AS reason_code            --RR[h
                 ,XIOT.item_id                                     AS item_id                --iΪID
                 ,XIOT.item_no                                     AS item_no                --iΪR[h
                 ,XIOT.item_name                                   AS item_name              --iΪΌ
                 ,XIOT.item_short_name                             AS item_short_name        --iΪͺΜ
                 ,XIOT.case_content                                AS case_content           --P[Xό
                 ,XIOT.whse_code                                   AS whse_code              --qΙR[h
                 ,XIOT.location_code                               AS location_code          --ΫΗκR[h
                 ,XIOT.location                                    AS location               --ΫΗκΌ
                 ,XIOT.location_s_name                             AS location_s_name        --ΫΗκͺΜ
                 ,XIOT.ukebaraisaki_code                           AS ukebaraisaki_code      --σ₯ζR[h
                 ,XIOT.ukebaraisaki_name                           AS ukebaraisaki_name      --σ₯ζΌ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '01' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_01dy  --ΚPϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '02' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_02dy  --ΚQϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '03' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_03dy  --ΚRϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '04' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_04dy  --ΚSϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '05' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_05dy  --ΚTϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '06' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_06dy  --ΚUϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '07' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_07dy  --ΚVϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '08' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_08dy  --ΚWϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '09' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_09dy  --ΚXϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '10' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_10dy  --ΚPOϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '11' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_11dy  --ΚPPϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '12' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_12dy  --ΚPQϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '13' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_13dy  --ΚPRϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '14' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_14dy  --ΚPSϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '15' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_15dy  --ΚPTϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '16' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_16dy  --ΚPUϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '17' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_17dy  --ΚPVϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '18' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_18dy  --ΚPWϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '19' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_19dy  --ΚPXϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '20' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_20dy  --ΚQOϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '21' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_21dy  --ΚQPϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '22' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_22dy  --ΚQQϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '23' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_23dy  --ΚQRϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '24' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_24dy  --ΚQSϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '25' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_25dy  --ΚQTϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '26' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_26dy  --ΚQUϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '27' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_27dy  --ΚQVϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '28' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_28dy  --ΚQWϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '29' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_29dy  --ΚQXϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '30' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_30dy  --ΚROϊ
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '31' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_31dy  --ΚRPϊ
            FROM  xxskz_inout_trans_v        XIOT    --όoΙξρiΤVIEWj   
          GROUP BY TO_CHAR( XIOT.leaving_date, 'YYYYMM' )    --N
                  ,XIOT.in_out_kbn                           --όoΙζͺ
                  ,XIOT.status                               --\θΐΡζͺ
                  ,XIOT.reason_code                          --RR[h
                  ,XIOT.item_id                              --iΪID
                  ,XIOT.item_no                              --iΪR[h
                  ,XIOT.item_name                            --iΪΌ
                  ,XIOT.item_short_name                      --iΪͺΜ
                  ,XIOT.case_content                         --P[Xό
                  ,XIOT.whse_code                            --qΙR[h
                  ,XIOT.location_code                        --ΫΗκR[h
                  ,XIOT.location                             --ΫΗκΌ
                  ,XIOT.location_s_name                      --ΫΗκͺΜ
                  ,XIOT.ukebaraisaki_code                    --σ₯ζR[h
                  ,XIOT.ukebaraisaki_name                    --σ₯ζΌ
        )  SIOT
       ,xxskz_prod_class_v            XPCV    --€iζͺζΎp
       ,xxskz_item_class_v            XICV    --iΪζͺζΎp
       ,xxskz_inout_class_v           XIOCV   --ΰOζͺζΎp
       ,xxskz_crowd_code_v            XCCV    --QR[hζΎp
       ,ic_whse_mst                   IWM     --qΙ}X^
       ,fnd_lookup_values             FLV01   --RR[hΌζΎp
       ,fnd_lookup_values             FLV02   --Ό`ζΎp
 WHERE
   --€iζͺζΎ
        SIOT.item_id = XPCV.item_id(+)
   --iΪζͺζΎ
   AND  SIOT.item_id = XICV.item_id(+)
   --ΰOζͺζΎ
   AND  SIOT.item_id = XIOCV.item_id(+)
   --QR[hζΎ
   AND  SIOT.item_id = XCCV.item_id(+)
   --qΙξρζΎ
   AND  SIOT.whse_code = IWM.whse_code(+)
   --yNCbNR[hzRR[hΌζΎ
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXCMN_NEW_DIVISION'
   AND  FLV01.lookup_code(+) = SIOT.reason_code
   --yNCbNR[hzΌ`ζΎ
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_INV_CTRL'
   AND  FLV02.lookup_code(+) = IWM.attribute1
/
COMMENT ON TABLE APPS.XXSKZ_όoΙξρ_­ϊ_V IS 'SKYLINKp όoΙξρi­ϊjVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.N           IS 'N'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.όoΙζͺ     IS 'όoΙζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.\θΐΡζͺ   IS '\θΐΡζͺ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.RR[h     IS 'RR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.RR[hΌ   IS 'RR[hΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.€iζͺR[h IS '€iζͺR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.€iζͺΌ     IS '€iζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.iΪζͺR[h IS 'iΪζͺR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.iΪζͺΌ     IS 'iΪζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΰOζͺR[h IS 'ΰOζͺR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΰOζͺΌ     IS 'ΰOζͺΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.QR[h       IS 'QR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.iΪR[h     IS 'iΪR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.iΪΌ         IS 'iΪΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.iΪͺΜ       IS 'iΪͺΜ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.P[Xό     IS 'P[Xό'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.Ό`R[h     IS 'Ό`R[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.Ό`           IS 'Ό`'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.qΙR[h     IS 'qΙR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΫΗκR[h IS 'ΫΗκR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΫΗκΌ     IS 'ΫΗκΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΫΗκͺΜ   IS 'ΫΗκͺΜ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.σ₯ζR[h   IS 'σ₯ζR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.σ₯ζΌ       IS 'σ₯ζΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPϊ       IS 'ΚPϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQϊ       IS 'ΚQϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚRϊ       IS 'ΚRϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚSϊ       IS 'ΚSϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚTϊ       IS 'ΚTϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚUϊ       IS 'ΚUϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚVϊ       IS 'ΚVϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚWϊ       IS 'ΚWϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚXϊ       IS 'ΚXϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPOϊ     IS 'ΚPOϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPPϊ     IS 'ΚPPϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPQϊ     IS 'ΚPQϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPRϊ     IS 'ΚPRϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPSϊ     IS 'ΚPSϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPTϊ     IS 'ΚPTϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPUϊ     IS 'ΚPUϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPVϊ     IS 'ΚPVϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPWϊ     IS 'ΚPWϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚPXϊ     IS 'ΚPXϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQOϊ     IS 'ΚQOϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQPϊ     IS 'ΚQPϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQQϊ     IS 'ΚQQϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQRϊ     IS 'ΚQRϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQSϊ     IS 'ΚQSϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQTϊ     IS 'ΚQTϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQUϊ     IS 'ΚQUϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQVϊ     IS 'ΚQVϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQWϊ     IS 'ΚQWϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚQXϊ     IS 'ΚQXϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚROϊ     IS 'ΚROϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_όoΙξρ_­ϊ_V.ΚRPϊ     IS 'ΚRPϊ'
/
