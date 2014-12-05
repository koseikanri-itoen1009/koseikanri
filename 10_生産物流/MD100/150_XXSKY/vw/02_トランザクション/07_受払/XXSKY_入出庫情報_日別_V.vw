CREATE OR REPLACE VIEW APPS.XXSKY_入出庫情報_日別_V
(
 年月
,入出庫区分
,予定実績区分
,事由コード
,事由コード名
,商品区分コード
,商品区分名
,品目区分コード
,品目区分名
,内外区分コード
,内外区分名
,群コード
,品目コード
,品目名
,品目略称
,ケース入数
,名義コード
,名義
,倉庫コード
,保管場所コード
,保管場所名
,保管場所略称
,受払先コード
,受払先名
,数量１日
,数量２日
,数量３日
,数量４日
,数量５日
,数量６日
,数量７日
,数量８日
,数量９日
,数量１０日
,数量１１日
,数量１２日
,数量１３日
,数量１４日
,数量１５日
,数量１６日
,数量１７日
,数量１８日
,数量１９日
,数量２０日
,数量２１日
,数量２２日
,数量２３日
,数量２４日
,数量２５日
,数量２６日
,数量２７日
,数量２８日
,数量２９日
,数量３０日
,数量３１日
)
AS
SELECT  --Add 2014/12/02 E_本稼動_12685 PT対応 Start
        /*+ OPTIMIZER_FEATURES_ENABLE('10.2.0.3') */
        --Add 2014/12/02 E_本稼動_12685 PT対応 End
        SIOT.yyyymm                    AS yyyymm                   --年月
       ,CASE WHEN SIOT.in_out_kbn = 1 THEN '入庫'    --入出庫区分コードが1:入庫
             WHEN SIOT.in_out_kbn = 2 THEN '出庫'    --入出庫区分コードが2:出庫
             ELSE SIOT.in_out_kbn
        END                            AS in_out_kbn_name          --入出庫区分
       ,CASE WHEN SIOT.status = 1 THEN '予定'        --予定実績区分コードが1:入庫
             WHEN SIOT.status = 2 THEN '実績'        --予定実績区分コードが2:出庫
             ELSE SIOT.status
        END                            AS status_name              --予定実績区分
       ,SIOT.reason_code               AS reason_code              --事由コード
       ,FLV01.meaning                  AS reason_code_name         --事由コード名
       ,XPCV.prod_class_code           AS prod_class_code          --商品区分コード
       ,XPCV.prod_class_name           AS prod_class_name          --商品区分名
       ,XICV.item_class_code           AS item_class_code          --品目区分コード
       ,XICV.item_class_name           AS item_class_name          --品目区分名
       ,XIOCV.inout_class_code         AS inout_class_code         --内外区分コード
       ,XIOCV.inout_class_name         AS inout_class_name         --内外区分名
       ,XCCV.crowd_code                AS crowd_code               --群コード
       ,SIOT.item_no                   AS item_no                  --品目コード
       ,SIOT.item_name                 AS item_name                --品目名
       ,SIOT.item_short_name           AS item_short_name          --品目略称
       ,SIOT.case_content              AS case_content             --ケース入数
       ,IWM.attribute1                 AS cust_stc_whse            --名義コード
       ,FLV02.meaning                  AS cust_stc_whse_name       --名義
       ,SIOT.whse_code                 AS whse_code                --倉庫コード
       ,SIOT.location_code             AS location_code            --保管場所コード
       ,SIOT.location                  AS location                 --保管場所名
       ,SIOT.location_s_name           AS location_s_name          --保管場所略称
       ,SIOT.ukebaraisaki_code         AS ukebaraisaki_code        --受払先コード
       ,SIOT.ukebaraisaki_name         AS ukebaraisaki_name        --受払先名
       ,NVL( SIOT.qty_01dy, 0 )        AS qty_01dy                 --数量１日
       ,NVL( SIOT.qty_02dy, 0 )        AS qty_02dy                 --数量２日
       ,NVL( SIOT.qty_03dy, 0 )        AS qty_03dy                 --数量３日
       ,NVL( SIOT.qty_04dy, 0 )        AS qty_04dy                 --数量４日
       ,NVL( SIOT.qty_05dy, 0 )        AS qty_05dy                 --数量５日
       ,NVL( SIOT.qty_06dy, 0 )        AS qty_06dy                 --数量６日
       ,NVL( SIOT.qty_07dy, 0 )        AS qty_07dy                 --数量７日
       ,NVL( SIOT.qty_08dy, 0 )        AS qty_08dy                 --数量８日
       ,NVL( SIOT.qty_09dy, 0 )        AS qty_09dy                 --数量９日
       ,NVL( SIOT.qty_10dy, 0 )        AS qty_10dy                 --数量１０日
       ,NVL( SIOT.qty_11dy, 0 )        AS qty_11dy                 --数量１１日
       ,NVL( SIOT.qty_12dy, 0 )        AS qty_12dy                 --数量１２日
       ,NVL( SIOT.qty_13dy, 0 )        AS qty_13dy                 --数量１３日
       ,NVL( SIOT.qty_14dy, 0 )        AS qty_14dy                 --数量１４日
       ,NVL( SIOT.qty_15dy, 0 )        AS qty_15dy                 --数量１５日
       ,NVL( SIOT.qty_16dy, 0 )        AS qty_16dy                 --数量１６日
       ,NVL( SIOT.qty_17dy, 0 )        AS qty_17dy                 --数量１７日
       ,NVL( SIOT.qty_18dy, 0 )        AS qty_18dy                 --数量１８日
       ,NVL( SIOT.qty_19dy, 0 )        AS qty_19dy                 --数量１９日
       ,NVL( SIOT.qty_20dy, 0 )        AS qty_20dy                 --数量２０日
       ,NVL( SIOT.qty_21dy, 0 )        AS qty_21dy                 --数量２１日
       ,NVL( SIOT.qty_22dy, 0 )        AS qty_22dy                 --数量２２日
       ,NVL( SIOT.qty_23dy, 0 )        AS qty_23dy                 --数量２３日
       ,NVL( SIOT.qty_24dy, 0 )        AS qty_24dy                 --数量２４日
       ,NVL( SIOT.qty_25dy, 0 )        AS qty_25dy                 --数量２５日
       ,NVL( SIOT.qty_26dy, 0 )        AS qty_26dy                 --数量２６日
       ,NVL( SIOT.qty_27dy, 0 )        AS qty_27dy                 --数量２７日
       ,NVL( SIOT.qty_28dy, 0 )        AS qty_28dy                 --数量２８日
       ,NVL( SIOT.qty_29dy, 0 )        AS qty_29dy                 --数量２９日
       ,NVL( SIOT.qty_30dy, 0 )        AS qty_30dy                 --数量３０日
       ,NVL( SIOT.qty_31dy, 0 )        AS qty_31dy                 --数量３１日
  FROM  ( --日別集計のみを行う
          SELECT  TO_CHAR( XIOT.arrival_date, 'YYYYMM' )           AS yyyymm                 --年月
                 ,XIOT.in_out_kbn                                  AS in_out_kbn             --入出庫区分
                 ,XIOT.status                                      AS status                 --予定実績区分
                 ,XIOT.reason_code                                 AS reason_code            --事由コード
                 ,XIOT.item_id                                     AS item_id                --品目ID
                 ,XIOT.item_no                                     AS item_no                --品目コード
                 ,XIOT.item_name                                   AS item_name              --品目名
                 ,XIOT.item_short_name                             AS item_short_name        --品目略称
                 ,XIOT.case_content                                AS case_content           --ケース入数
                 ,XIOT.whse_code                                   AS whse_code              --倉庫コード
                 ,XIOT.location_code                               AS location_code          --保管場所コード
                 ,XIOT.location                                    AS location               --保管場所名
                 ,XIOT.location_s_name                             AS location_s_name        --保管場所略称
                 ,XIOT.ukebaraisaki_code                           AS ukebaraisaki_code      --受払先コード
                 ,XIOT.ukebaraisaki_name                           AS ukebaraisaki_name      --受払先名
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '01' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_01dy  --数量１日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '02' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_02dy  --数量２日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '03' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_03dy  --数量３日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '04' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_04dy  --数量４日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '05' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_05dy  --数量５日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '06' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_06dy  --数量６日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '07' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_07dy  --数量７日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '08' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_08dy  --数量８日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '09' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_09dy  --数量９日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '10' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_10dy  --数量１０日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '11' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_11dy  --数量１１日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '12' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_12dy  --数量１２日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '13' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_13dy  --数量１３日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '14' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_14dy  --数量１４日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '15' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_15dy  --数量１５日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '16' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_16dy  --数量１６日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '17' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_17dy  --数量１７日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '18' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_18dy  --数量１８日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '19' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_19dy  --数量１９日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '20' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_20dy  --数量２０日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '21' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_21dy  --数量２１日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '22' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_22dy  --数量２２日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '23' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_23dy  --数量２３日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '24' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_24dy  --数量２４日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '25' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_25dy  --数量２５日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '26' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_26dy  --数量２６日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '27' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_27dy  --数量２７日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '28' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_28dy  --数量２８日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '29' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_29dy  --数量２９日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '30' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_30dy  --数量３０日
                 ,SUM( CASE WHEN TO_CHAR( XIOT.arrival_date, 'DD' ) = '31' THEN ROUND( XIOT.quantity, 3 ) END ) AS qty_31dy  --数量３１日
            FROM  xxsky_inout_trans_v        XIOT    --入出庫情報（中間VIEW）
          GROUP BY TO_CHAR( XIOT.arrival_date, 'YYYYMM' )    --年月
                  ,XIOT.in_out_kbn                           --入出庫区分
                  ,XIOT.status                               --予定実績区分
                  ,XIOT.reason_code                          --事由コード
                  ,XIOT.item_id                              --品目ID
                  ,XIOT.item_no                              --品目コード
                  ,XIOT.item_name                            --品目名
                  ,XIOT.item_short_name                      --品目略称
                  ,XIOT.case_content                         --ケース入数
                  ,XIOT.whse_code                            --倉庫コード
                  ,XIOT.location_code                        --保管場所コード
                  ,XIOT.location                             --保管場所名
                  ,XIOT.location_s_name                      --保管場所略称
                  ,XIOT.ukebaraisaki_code                    --受払先コード
                  ,XIOT.ukebaraisaki_name                    --受払先名
        )  SIOT
       ,xxsky_prod_class_v            XPCV    --商品区分取得用
       ,xxsky_item_class_v            XICV    --品目区分取得用
       ,xxsky_inout_class_v           XIOCV   --内外区分取得用
       ,xxsky_crowd_code_v            XCCV    --群コード取得用
       ,ic_whse_mst                   IWM     --倉庫マスタ
       ,fnd_lookup_values             FLV01   --事由コード名取得用
       ,fnd_lookup_values             FLV02   --名義取得用
 WHERE
   --商品区分取得
        SIOT.item_id = XPCV.item_id(+)
   --品目区分取得
   AND  SIOT.item_id = XICV.item_id(+)
   --内外区分取得
   AND  SIOT.item_id = XIOCV.item_id(+)
   --群コード取得
   AND  SIOT.item_id = XCCV.item_id(+)
   --倉庫情報取得
   AND  SIOT.whse_code = IWM.whse_code(+)
   --【クイックコード】事由コード名取得
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXCMN_NEW_DIVISION'
   AND  FLV01.lookup_code(+) = SIOT.reason_code
   --【クイックコード】名義取得
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_INV_CTRL'
   AND  FLV02.lookup_code(+) = IWM.attribute1
/
COMMENT ON TABLE APPS.XXSKY_入出庫情報_日別_V IS 'SKYLINK用 入出庫情報（日別）VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.年月           IS '年月'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.入出庫区分     IS '入出庫区分'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.予定実績区分   IS '予定実績区分'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.事由コード     IS '事由コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.事由コード名   IS '事由コード名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.商品区分コード IS '商品区分コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.商品区分名     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.品目区分コード IS '品目区分コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.品目区分名     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.内外区分コード IS '内外区分コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.内外区分名     IS '内外区分名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.群コード       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.品目コード     IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.品目名         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.品目略称       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.ケース入数     IS 'ケース入数'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.名義コード     IS '名義コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.名義           IS '名義'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.倉庫コード     IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.保管場所コード IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.保管場所名     IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.保管場所略称   IS '保管場所略称'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.受払先コード   IS '受払先コード'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.受払先名       IS '受払先名'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１日       IS '数量１日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２日       IS '数量２日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量３日       IS '数量３日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量４日       IS '数量４日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量５日       IS '数量５日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量６日       IS '数量６日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量７日       IS '数量７日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量８日       IS '数量８日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量９日       IS '数量９日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１０日     IS '数量１０日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１１日     IS '数量１１日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１２日     IS '数量１２日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１３日     IS '数量１３日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１４日     IS '数量１４日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１５日     IS '数量１５日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１６日     IS '数量１６日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１７日     IS '数量１７日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１８日     IS '数量１８日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量１９日     IS '数量１９日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２０日     IS '数量２０日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２１日     IS '数量２１日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２２日     IS '数量２２日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２３日     IS '数量２３日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２４日     IS '数量２４日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２５日     IS '数量２５日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２６日     IS '数量２６日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２７日     IS '数量２７日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２８日     IS '数量２８日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量２９日     IS '数量２９日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量３０日     IS '数量３０日'
/
COMMENT ON COLUMN APPS.XXSKY_入出庫情報_日別_V.数量３１日     IS '数量３１日'
/
