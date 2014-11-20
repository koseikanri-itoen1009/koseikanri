/*************************************************************************
 * 
 * View  Name      : XXSKZ_引取計画_日別_V
 * Description     : XXSKZ_引取計画_日別_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_引取計画_日別_V
(
 年月
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,内外区分
,内外区分名
,品目
,品目名
,品目略称
,出荷元保管倉庫
,出荷元保管倉庫名
,拠点
,拠点名
,ケース入数
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
SELECT  SMFC.frct_ym                frct_ym            --年月
       ,PRODC.prod_class_code       prod_class_code    --商品区分
       ,PRODC.prod_class_name       prod_class_name    --商品区分名
       ,ITEMC.item_class_code       item_class_code    --品目区分
       ,ITEMC.item_class_name       item_class_name    --品目区分名
       ,CROWD.crowd_code            crowd_code         --群コード
       ,INOUT.inout_class_code      inout_class_code   --内外区分
       ,INOUT.inout_class_name      inout_class_name   --内外区分名 
       ,ITEM.item_no                item_code          --品目
       ,ITEM.item_name              item_name          --品目名
       ,ITEM.item_short_name        item_s_name        --品目略称
       ,SMFC.dlvr_from              dlvr_from          --出荷元保管倉庫
       ,ITMLC.description           dlvr_from_name     --出荷元保管倉庫名
       ,SMFC.branch                 branch             --拠点
       ,BRCH.party_name             branch_name        --拠点名
       ,ITEM.num_of_cases           incase_qty         --ケース入数
       ,NVL( SMFC.fc_qty_01dy, 0 )  fc_qty_01dy        --数量１日
       ,NVL( SMFC.fc_qty_02dy, 0 )  fc_qty_02dy        --数量２日
       ,NVL( SMFC.fc_qty_03dy, 0 )  fc_qty_03dy        --数量３日
       ,NVL( SMFC.fc_qty_04dy, 0 )  fc_qty_04dy        --数量４日
       ,NVL( SMFC.fc_qty_05dy, 0 )  fc_qty_05dy        --数量５日
       ,NVL( SMFC.fc_qty_06dy, 0 )  fc_qty_06dy        --数量６日
       ,NVL( SMFC.fc_qty_07dy, 0 )  fc_qty_07dy        --数量７日
       ,NVL( SMFC.fc_qty_08dy, 0 )  fc_qty_08dy        --数量８日
       ,NVL( SMFC.fc_qty_09dy, 0 )  fc_qty_09dy        --数量９日
       ,NVL( SMFC.fc_qty_10dy, 0 )  fc_qty_10dy        --数量１０日
       ,NVL( SMFC.fc_qty_11dy, 0 )  fc_qty_11dy        --数量１１日
       ,NVL( SMFC.fc_qty_12dy, 0 )  fc_qty_12dy        --数量１２日
       ,NVL( SMFC.fc_qty_13dy, 0 )  fc_qty_13dy        --数量１３日
       ,NVL( SMFC.fc_qty_14dy, 0 )  fc_qty_14dy        --数量１４日
       ,NVL( SMFC.fc_qty_15dy, 0 )  fc_qty_15dy        --数量１５日
       ,NVL( SMFC.fc_qty_16dy, 0 )  fc_qty_16dy        --数量１６日
       ,NVL( SMFC.fc_qty_17dy, 0 )  fc_qty_17dy        --数量１７日
       ,NVL( SMFC.fc_qty_18dy, 0 )  fc_qty_18dy        --数量１８日
       ,NVL( SMFC.fc_qty_19dy, 0 )  fc_qty_19dy        --数量１９日
       ,NVL( SMFC.fc_qty_20dy, 0 )  fc_qty_20dy        --数量２０日
       ,NVL( SMFC.fc_qty_21dy, 0 )  fc_qty_21dy        --数量２１日
       ,NVL( SMFC.fc_qty_22dy, 0 )  fc_qty_22dy        --数量２２日
       ,NVL( SMFC.fc_qty_23dy, 0 )  fc_qty_23dy        --数量２３日
       ,NVL( SMFC.fc_qty_24dy, 0 )  fc_qty_24dy        --数量２４日
       ,NVL( SMFC.fc_qty_25dy, 0 )  fc_qty_25dy        --数量２５日
       ,NVL( SMFC.fc_qty_26dy, 0 )  fc_qty_26dy        --数量２６日
       ,NVL( SMFC.fc_qty_27dy, 0 )  fc_qty_27dy        --数量２７日
       ,NVL( SMFC.fc_qty_28dy, 0 )  fc_qty_28dy        --数量２８日
       ,NVL( SMFC.fc_qty_29dy, 0 )  fc_qty_29dy        --数量２９日
       ,NVL( SMFC.fc_qty_30dy, 0 )  fc_qty_30dy        --数量３０日
       ,NVL( SMFC.fc_qty_31dy, 0 )  fc_qty_31dy        --数量３１日
  FROM  ( --年月、倉庫、拠点、品目単位で集計した（日別を横にした）計画数量集計データ
          SELECT  TO_CHAR( MFDT.forecast_date, 'YYYYMM' )                                                              frct_ym      --予定年月
                 ,MFDN.attribute2                                                                                      dlvr_from    --出荷元保管倉庫コード
                 ,MFDN.attribute3                                                                                      branch       --拠点コード
                 ,MFDT.inventory_item_id                                                                               item_id      --出荷品目ID
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '01' THEN MFDT.current_forecast_quantity END )  fc_qty_01dy  --数量１日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '02' THEN MFDT.current_forecast_quantity END )  fc_qty_02dy  --数量２日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '03' THEN MFDT.current_forecast_quantity END )  fc_qty_03dy  --数量３日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '04' THEN MFDT.current_forecast_quantity END )  fc_qty_04dy  --数量４日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '05' THEN MFDT.current_forecast_quantity END )  fc_qty_05dy  --数量５日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '06' THEN MFDT.current_forecast_quantity END )  fc_qty_06dy  --数量６日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '07' THEN MFDT.current_forecast_quantity END )  fc_qty_07dy  --数量７日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '08' THEN MFDT.current_forecast_quantity END )  fc_qty_08dy  --数量８日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '09' THEN MFDT.current_forecast_quantity END )  fc_qty_09dy  --数量９日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '10' THEN MFDT.current_forecast_quantity END )  fc_qty_10dy  --数量１０日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '11' THEN MFDT.current_forecast_quantity END )  fc_qty_11dy  --数量１１日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '12' THEN MFDT.current_forecast_quantity END )  fc_qty_12dy  --数量１２日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '13' THEN MFDT.current_forecast_quantity END )  fc_qty_13dy  --数量１３日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '14' THEN MFDT.current_forecast_quantity END )  fc_qty_14dy  --数量１４日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '15' THEN MFDT.current_forecast_quantity END )  fc_qty_15dy  --数量１５日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '16' THEN MFDT.current_forecast_quantity END )  fc_qty_16dy  --数量１６日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '17' THEN MFDT.current_forecast_quantity END )  fc_qty_17dy  --数量１７日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '18' THEN MFDT.current_forecast_quantity END )  fc_qty_18dy  --数量１８日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '19' THEN MFDT.current_forecast_quantity END )  fc_qty_19dy  --数量１９日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '20' THEN MFDT.current_forecast_quantity END )  fc_qty_20dy  --数量２０日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '21' THEN MFDT.current_forecast_quantity END )  fc_qty_21dy  --数量２１日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '22' THEN MFDT.current_forecast_quantity END )  fc_qty_22dy  --数量２２日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '23' THEN MFDT.current_forecast_quantity END )  fc_qty_23dy  --数量２３日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '24' THEN MFDT.current_forecast_quantity END )  fc_qty_24dy  --数量２４日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '25' THEN MFDT.current_forecast_quantity END )  fc_qty_25dy  --数量２５日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '26' THEN MFDT.current_forecast_quantity END )  fc_qty_26dy  --数量２６日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '27' THEN MFDT.current_forecast_quantity END )  fc_qty_27dy  --数量２７日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '28' THEN MFDT.current_forecast_quantity END )  fc_qty_28dy  --数量２８日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '29' THEN MFDT.current_forecast_quantity END )  fc_qty_29dy  --数量２９日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '30' THEN MFDT.current_forecast_quantity END )  fc_qty_30dy  --数量３０日
                 ,SUM( CASE WHEN TO_CHAR( MFDT.forecast_date, 'DD' ) = '31' THEN MFDT.current_forecast_quantity END )  fc_qty_31dy  --数量３１日
            FROM  mrp_forecast_designators    MFDN    --フォーキャスト名テーブル
                 ,mrp_forecast_dates          MFDT    --フォーキャスト日付テーブル
           WHERE  MFDN.attribute1 = '01'                                --引取計画
             AND  MFDN.organization_id = fnd_profile.VALUE( 'XXCMN_MASTER_ORG_ID' )
             AND  MFDN.forecast_designator = MFDT.forecast_designator
             AND  MFDN.organization_id = MFDT.organization_id
          GROUP BY  TO_CHAR( MFDT.forecast_date, 'YYYYMM' )
                   ,MFDN.attribute2
                   ,MFDN.attribute3
                   ,MFDT.inventory_item_id
        )                       SMFC    --引取計画日別集計
       ,xxskz_item_mst2_v       ITEM    --品目名取得用
       ,xxskz_prod_class_v      PRODC   --商品区分取得用
       ,xxskz_item_class_v      ITEMC   --品目区分取得用
       ,xxskz_crowd_code_v      CROWD   --群コード取得用
       ,xxskz_inout_class_v     INOUT   --内外区分取得用
       ,xxskz_item_locations_v  ITMLC   --保管倉庫名取得用
       ,xxskz_cust_accounts2_v  BRCH    --拠点名取得用
 WHERE
   --品目名取得
        SMFC.item_id   = ITEM.inventory_item_id(+)
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) >= ITEM.start_date_active(+)  --月末日付で検索
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) <= ITEM.end_date_active(+)    --月末日付で検索
   --品目カテゴリ名取得
   AND  ITEM.item_id   = PRODC.item_id(+)
   AND  ITEM.item_id   = ITEMC.item_id(+)
   AND  ITEM.item_id   = CROWD.item_id(+)
   AND  ITEM.item_id   = INOUT.item_id(+)
   --出荷元保管倉庫名取得
   AND  SMFC.dlvr_from = ITMLC.segment1(+)
   --拠点名取得
   AND  SMFC.branch    = BRCH.party_number(+)
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) >= BRCH.start_date_active(+)  --月末日付で検索
   AND  LAST_DAY( TO_DATE( SMFC.frct_ym || '01', 'YYYYMMDD' ) ) <= BRCH.end_date_active(+)    --月末日付で検索
/
COMMENT ON TABLE APPS.XXSKZ_引取計画_日別_V IS 'SKYLINK用 引取計画（日別）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.年月             IS '年月'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.商品区分         IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.商品区分名       IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.品目区分         IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.品目区分名       IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.群コード         IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.内外区分         IS '内外区分'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.内外区分名       IS '内外区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.品目             IS '品目'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.品目名           IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.品目略称         IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.出荷元保管倉庫   IS '出荷元保管倉庫'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.出荷元保管倉庫名 IS '出荷元保管倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.拠点             IS '拠点'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.拠点名           IS '拠点名'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.ケース入数       IS 'ケース入数'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１日         IS '数量１日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２日         IS '数量２日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量３日         IS '数量３日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量４日         IS '数量４日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量５日         IS '数量５日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量６日         IS '数量６日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量７日         IS '数量７日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量８日         IS '数量８日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量９日         IS '数量９日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１０日       IS '数量１０日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１１日       IS '数量１１日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１２日       IS '数量１２日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１３日       IS '数量１３日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１４日       IS '数量１４日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１５日       IS '数量１５日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１６日       IS '数量１６日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１７日       IS '数量１７日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１８日       IS '数量１８日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量１９日       IS '数量１９日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２０日       IS '数量２０日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２１日       IS '数量２１日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２２日       IS '数量２２日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２３日       IS '数量２３日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２４日       IS '数量２４日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２５日       IS '数量２５日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２６日       IS '数量２６日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２７日       IS '数量２７日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２８日       IS '数量２８日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量２９日       IS '数量２９日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量３０日       IS '数量３０日'
/
COMMENT ON COLUMN APPS.XXSKZ_引取計画_日別_V.数量３１日       IS '数量３１日'
/
