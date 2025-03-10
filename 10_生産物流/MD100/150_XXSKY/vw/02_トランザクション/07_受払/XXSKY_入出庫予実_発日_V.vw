CREATE OR REPLACE VIEW APPS.XXSKY_üoÉ\À_­ú_V
(
 N
,üoÉæª
,\èÀÑæª
,RR[h
,RR[h¼
,¤iæªR[h
,¤iæª¼
,iÚæªR[h
,iÚæª¼
,àOæªR[h
,àOæª¼
,QR[h
,iÚR[h
,iÚ¼
,iÚªÌ
,P[Xü
,¼`R[h
,¼`
,qÉR[h
,ÛÇêR[h
,ÛÇê¼
,ÛÇêªÌ
,ó¥æR[h
,ó¥æ¼
,ÊPú
,ÊQú
,ÊRú
,ÊSú
,ÊTú
,ÊUú
,ÊVú
,ÊWú
,ÊXú
,ÊPOú
,ÊPPú
,ÊPQú
,ÊPRú
,ÊPSú
,ÊPTú
,ÊPUú
,ÊPVú
,ÊPWú
,ÊPXú
,ÊQOú
,ÊQPú
,ÊQQú
,ÊQRú
,ÊQSú
,ÊQTú
,ÊQUú
,ÊQVú
,ÊQWú
,ÊQXú
,ÊROú
,ÊRPú
)
AS
SELECT  --Add 2014/12/02 E_{Ò®_12685 PTÎ Start
        /*+ OPTIMIZER_FEATURES_ENABLE('10.2.0.3') */
        --Add 2014/12/02 E_{Ò®_12685 PTÎ End
        SIOT.yyyymm                    AS yyyymm                   --N
       ,CASE WHEN SIOT.in_out_kbn = 1 THEN 'üÉ'    --üoÉæªR[hª1:üÉ
             WHEN SIOT.in_out_kbn = 2 THEN 'oÉ'    --üoÉæªR[hª2:oÉ
             ELSE SIOT.in_out_kbn
        END                            AS in_out_kbn_name          --üoÉæª
       ,CASE WHEN SIOT.status = 1 THEN '\è'        --\èÀÑæªR[hª1:üÉ
             WHEN SIOT.status = 2 THEN 'ÀÑ'        --\èÀÑæªR[hª2:oÉ
             ELSE SIOT.status
        END                            AS status_name              --\èÀÑæª
       ,SIOT.reason_code               AS reason_code              --RR[h
       ,FLV01.meaning                  AS reason_code_name         --RR[h¼
       ,XPCV.prod_class_code           AS prod_class_code          --¤iæªR[h
       ,XPCV.prod_class_name           AS prod_class_name          --¤iæª¼
       ,XICV.item_class_code           AS item_class_code          --iÚæªR[h
       ,XICV.item_class_name           AS item_class_name          --iÚæª¼
       ,XIOCV.inout_class_code         AS inout_class_code         --àOæªR[h
       ,XIOCV.inout_class_name         AS inout_class_name         --àOæª¼
       ,XCCV.crowd_code                AS crowd_code               --QR[h
       ,SIOT.item_no                   AS item_no                  --iÚR[h
       ,SIOT.item_name                 AS item_name                --iÚ¼
       ,SIOT.item_short_name           AS item_short_name          --iÚªÌ
       ,SIOT.case_content              AS case_content             --P[Xü
       ,IWM.attribute1                 AS cust_stc_whse            --¼`R[h
       ,FLV02.meaning                  AS cust_stc_whse_name       --¼`
       ,SIOT.whse_code                 AS whse_code                --qÉR[h
       ,SIOT.location_code             AS location_code            --ÛÇêR[h
       ,SIOT.location                  AS location                 --ÛÇê¼
       ,SIOT.location_s_name           AS location_s_name          --ÛÇêªÌ
       ,SIOT.ukebaraisaki_code         AS ukebaraisaki_code        --ó¥æR[h
       ,SIOT.ukebaraisaki_name         AS ukebaraisaki_name        --ó¥æ¼
       ,NVL( SIOT.qty_01dy, 0 )        AS qty_01dy                 --ÊPú
       ,NVL( SIOT.qty_02dy, 0 )        AS qty_02dy                 --ÊQú
       ,NVL( SIOT.qty_03dy, 0 )        AS qty_03dy                 --ÊRú
       ,NVL( SIOT.qty_04dy, 0 )        AS qty_04dy                 --ÊSú
       ,NVL( SIOT.qty_05dy, 0 )        AS qty_05dy                 --ÊTú
       ,NVL( SIOT.qty_06dy, 0 )        AS qty_06dy                 --ÊUú
       ,NVL( SIOT.qty_07dy, 0 )        AS qty_07dy                 --ÊVú
       ,NVL( SIOT.qty_08dy, 0 )        AS qty_08dy                 --ÊWú
       ,NVL( SIOT.qty_09dy, 0 )        AS qty_09dy                 --ÊXú
       ,NVL( SIOT.qty_10dy, 0 )        AS qty_10dy                 --ÊPOú
       ,NVL( SIOT.qty_11dy, 0 )        AS qty_11dy                 --ÊPPú
       ,NVL( SIOT.qty_12dy, 0 )        AS qty_12dy                 --ÊPQú
       ,NVL( SIOT.qty_13dy, 0 )        AS qty_13dy                 --ÊPRú
       ,NVL( SIOT.qty_14dy, 0 )        AS qty_14dy                 --ÊPSú
       ,NVL( SIOT.qty_15dy, 0 )        AS qty_15dy                 --ÊPTú
       ,NVL( SIOT.qty_16dy, 0 )        AS qty_16dy                 --ÊPUú
       ,NVL( SIOT.qty_17dy, 0 )        AS qty_17dy                 --ÊPVú
       ,NVL( SIOT.qty_18dy, 0 )        AS qty_18dy                 --ÊPWú
       ,NVL( SIOT.qty_19dy, 0 )        AS qty_19dy                 --ÊPXú
       ,NVL( SIOT.qty_20dy, 0 )        AS qty_20dy                 --ÊQOú
       ,NVL( SIOT.qty_21dy, 0 )        AS qty_21dy                 --ÊQPú
       ,NVL( SIOT.qty_22dy, 0 )        AS qty_22dy                 --ÊQQú
       ,NVL( SIOT.qty_23dy, 0 )        AS qty_23dy                 --ÊQRú
       ,NVL( SIOT.qty_24dy, 0 )        AS qty_24dy                 --ÊQSú
       ,NVL( SIOT.qty_25dy, 0 )        AS qty_25dy                 --ÊQTú
       ,NVL( SIOT.qty_26dy, 0 )        AS qty_26dy                 --ÊQUú
       ,NVL( SIOT.qty_27dy, 0 )        AS qty_27dy                 --ÊQVú
       ,NVL( SIOT.qty_28dy, 0 )        AS qty_28dy                 --ÊQWú
       ,NVL( SIOT.qty_29dy, 0 )        AS qty_29dy                 --ÊQXú
       ,NVL( SIOT.qty_30dy, 0 )        AS qty_30dy                 --ÊROú
       ,NVL( SIOT.qty_31dy, 0 )        AS qty_31dy                 --ÊRPú
  FROM  ( --­úWvÌÝðs¤
          SELECT  TO_CHAR( XIOT.leaving_date, 'YYYYMM' )           AS yyyymm                 --N
                 ,XIOT.in_out_kbn                                  AS in_out_kbn             --üoÉæª
                 ,XIOT.status                                      AS status                 --\èÀÑæª
                 ,XIOT.reason_code                                 AS reason_code            --RR[h
                 ,XIOT.item_id                                     AS item_id                --iÚID
                 ,XIOT.item_no                                     AS item_no                --iÚR[h
                 ,XIOT.item_name                                   AS item_name              --iÚ¼
                 ,XIOT.item_short_name                             AS item_short_name        --iÚªÌ
                 ,XIOT.case_content                                AS case_content           --P[Xü
                 ,XIOT.whse_code                                   AS whse_code              --qÉR[h
                 ,XIOT.location_code                               AS location_code          --ÛÇêR[h
                 ,XIOT.location                                    AS location               --ÛÇê¼
                 ,XIOT.location_s_name                             AS location_s_name        --ÛÇêªÌ
                 ,XIOT.ukebaraisaki_code                           AS ukebaraisaki_code      --ó¥æR[h
                 ,XIOT.ukebaraisaki_name                           AS ukebaraisaki_name      --ó¥æ¼
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '01' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_01dy  --ÊPú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '02' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_02dy  --ÊQú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '03' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_03dy  --ÊRú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '04' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_04dy  --ÊSú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '05' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_05dy  --ÊTú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '06' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_06dy  --ÊUú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '07' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_07dy  --ÊVú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '08' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_08dy  --ÊWú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '09' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_09dy  --ÊXú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '10' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_10dy  --ÊPOú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '11' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_11dy  --ÊPPú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '12' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_12dy  --ÊPQú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '13' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_13dy  --ÊPRú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '14' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_14dy  --ÊPSú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '15' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_15dy  --ÊPTú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '16' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_16dy  --ÊPUú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '17' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_17dy  --ÊPVú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '18' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_18dy  --ÊPWú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '19' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_19dy  --ÊPXú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '20' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_20dy  --ÊQOú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '21' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_21dy  --ÊQPú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '22' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_22dy  --ÊQQú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '23' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_23dy  --ÊQRú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '24' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_24dy  --ÊQSú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '25' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_25dy  --ÊQTú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '26' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_26dy  --ÊQUú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '27' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_27dy  --ÊQVú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '28' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_28dy  --ÊQWú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '29' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_29dy  --ÊQXú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '30' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_30dy  --ÊROú
                 ,SUM( CASE WHEN TO_CHAR( XIOT.leaving_date, 'DD' ) = '31' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_31dy  --ÊRPú
            FROM  xxsky_inout_yj_trans_v     XIOT    --üoÉ\ÀiÔVIEWj
          GROUP BY TO_CHAR( XIOT.leaving_date, 'YYYYMM' )    --N
                  ,XIOT.in_out_kbn                           --üoÉæª
                  ,XIOT.status                               --\èÀÑæª
                  ,XIOT.reason_code                          --RR[h
                  ,XIOT.item_id                              --iÚID
                  ,XIOT.item_no                              --iÚR[h
                  ,XIOT.item_name                            --iÚ¼
                  ,XIOT.item_short_name                      --iÚªÌ
                  ,XIOT.case_content                         --P[Xü
                  ,XIOT.whse_code                            --qÉR[h
                  ,XIOT.location_code                        --ÛÇêR[h
                  ,XIOT.location                             --ÛÇê¼
                  ,XIOT.location_s_name                      --ÛÇêªÌ
                  ,XIOT.ukebaraisaki_code                    --ó¥æR[h
                  ,XIOT.ukebaraisaki_name                    --ó¥æ¼
        )  SIOT
       ,xxsky_prod_class_v            XPCV    --¤iæªæ¾p
       ,xxsky_item_class_v            XICV    --iÚæªæ¾p
       ,xxsky_inout_class_v           XIOCV   --àOæªæ¾p
       ,xxsky_crowd_code_v            XCCV    --QR[hæ¾p
       ,ic_whse_mst                   IWM     --qÉ}X^
       ,fnd_lookup_values             FLV01   --RR[h¼æ¾p
       ,fnd_lookup_values             FLV02   --¼`æ¾p
 WHERE
   --¤iæªæ¾
        SIOT.item_id = XPCV.item_id(+)
   --iÚæªæ¾
   AND  SIOT.item_id = XICV.item_id(+)
   --àOæªæ¾
   AND  SIOT.item_id = XIOCV.item_id(+)
   --QR[hæ¾
   AND  SIOT.item_id = XCCV.item_id(+)
   --qÉîñæ¾
   AND  SIOT.whse_code = IWM.whse_code(+)
   --yNCbNR[hzRR[h¼æ¾
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXCMN_NEW_DIVISION'
   AND  FLV01.lookup_code(+) = SIOT.reason_code
   --yNCbNR[hz¼`æ¾
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_INV_CTRL'
   AND  FLV02.lookup_code(+) = IWM.attribute1
/
COMMENT ON TABLE APPS.XXSKY_üoÉ\À_­ú_V IS 'SKYLINKp üoÉ\Ài­újVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.N           IS 'N'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.üoÉæª     IS 'üoÉæª'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.\èÀÑæª   IS '\èÀÑæª'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.RR[h     IS 'RR[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.RR[h¼   IS 'RR[h¼'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.¤iæªR[h IS '¤iæªR[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.¤iæª¼     IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.iÚæªR[h IS 'iÚæªR[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.iÚæª¼     IS 'iÚæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.àOæªR[h IS 'àOæªR[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.àOæª¼     IS 'àOæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.QR[h       IS 'QR[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.iÚR[h     IS 'iÚR[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.iÚ¼         IS 'iÚ¼'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.iÚªÌ       IS 'iÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.P[Xü     IS 'P[Xü'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.¼`R[h     IS '¼`R[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.¼`           IS '¼`'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.qÉR[h     IS 'qÉR[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÛÇêR[h IS 'ÛÇêR[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÛÇê¼     IS 'ÛÇê¼'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÛÇêªÌ   IS 'ÛÇêªÌ'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ó¥æR[h   IS 'ó¥æR[h'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ó¥æ¼       IS 'ó¥æ¼'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPú       IS 'ÊPú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQú       IS 'ÊQú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊRú       IS 'ÊRú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊSú       IS 'ÊSú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊTú       IS 'ÊTú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊUú       IS 'ÊUú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊVú       IS 'ÊVú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊWú       IS 'ÊWú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊXú       IS 'ÊXú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPOú     IS 'ÊPOú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPPú     IS 'ÊPPú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPQú     IS 'ÊPQú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPRú     IS 'ÊPRú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPSú     IS 'ÊPSú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPTú     IS 'ÊPTú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPUú     IS 'ÊPUú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPVú     IS 'ÊPVú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPWú     IS 'ÊPWú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊPXú     IS 'ÊPXú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQOú     IS 'ÊQOú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQPú     IS 'ÊQPú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQQú     IS 'ÊQQú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQRú     IS 'ÊQRú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQSú     IS 'ÊQSú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQTú     IS 'ÊQTú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQUú     IS 'ÊQUú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQVú     IS 'ÊQVú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQWú     IS 'ÊQWú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊQXú     IS 'ÊQXú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊROú     IS 'ÊROú'
/
COMMENT ON COLUMN APPS.XXSKY_üoÉ\À_­ú_V.ÊRPú     IS 'ÊRPú'
/
