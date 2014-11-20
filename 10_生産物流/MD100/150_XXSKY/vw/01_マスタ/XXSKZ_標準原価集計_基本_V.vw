/*************************************************************************
 * 
 * View  Name      : XXSKZ_標準原価集計_基本_V
 * Description     : XXSKZ_標準原価集計_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_標準原価集計_基本_V
(
 商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,有効開始日
,有効終了日
,集計原価
,原料費
,再製費
,資材費
,包装費
,外注加工費
,保管費
,その他経費
,FMルート用
,予備１
,予備２
,予備３
)
AS
SELECT
        PRODC.prod_class_code           prod_class_code               --商品区分
       ,PRODC.prod_class_name           prod_class_name               --商品区分名
       ,ITEMC.item_class_code           item_class_code               --品目区分
       ,ITEMC.item_class_name           item_class_name               --品目区分名
       ,CROWD.crowd_code                crowd_code                    --群コード
       ,ITEM.item_no                    item_no                       --品目コード
       ,ITEM.item_name                  item_name                     --品目名
       ,ITEM.item_short_name            item_short_name               --品目略称
       ,TRUNC( SCCD.start_date )        start_date                    --有効開始日
       ,TRUNC( SCCD.end_date )          end_date                      --有効終了日
       ,NVL( SCCD.cost_all, 0 )         cost_all                      --集計原価
       ,NVL( SCCD.cost_gen, 0 )         cost_gen                      --原料費
       ,NVL( SCCD.cost_sai, 0 )         cost_sai                      --再製費
       ,NVL( SCCD.cost_szi, 0 )         cost_szi                      --資材費
       ,NVL( SCCD.cost_hou, 0 )         cost_hou                      --包装費
       ,NVL( SCCD.cost_gai, 0 )         cost_gai                      --外注加工費
       ,NVL( SCCD.cost_hkn, 0 )         cost_hkn                      --保管費
       ,NVL( SCCD.cost_kei, 0 )         cost_kei                      --その他経費
       ,NVL( SCCD.cost_fm , 0 )         cost_fm                       --FMルート用
       ,NVL( SCCD.cost_yb1, 0 )         cost_yb1                      --予備１
       ,NVL( SCCD.cost_yb2, 0 )         cost_yb2                      --予備２
       ,NVL( SCCD.cost_yb3, 0 )         cost_yb3                      --予備３
  FROM (
          -------------------------------------------------------
          -- 期間、倉庫、品目単位で集計した情報を取得
          -------------------------------------------------------
          SELECT
                  CCD.item_id                     item_id             --品目ID
                 ,CCDD.start_date                 start_date          --有効開始日
                 ,CCDD.end_date                   end_date            --有効終了日
                 ,SUM( CCD.cmpnt_cost )           cost_all            --集計原価
                  --コンポーネント原価単位で項目表示を行なう
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '01GEN' THEN CCD.cmpnt_cost END )  cost_gen  --原料費
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '02SAI' THEN CCD.cmpnt_cost END )  cost_sai  --再製費
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '03SZI' THEN CCD.cmpnt_cost END )  cost_szi  --資材費
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '04HOU' THEN CCD.cmpnt_cost END )  cost_hou  --包装費
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '05GAI' THEN CCD.cmpnt_cost END )  cost_gai  --外注加工費
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '06HKN' THEN CCD.cmpnt_cost END )  cost_hkn  --保管費
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '07KEI' THEN CCD.cmpnt_cost END )  cost_kei  --その他経費
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '99FM'  THEN CCD.cmpnt_cost END )  cost_fm   --FMルート用
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '08YB1' THEN CCD.cmpnt_cost END )  cost_yb1  --予備１
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '09YB2' THEN CCD.cmpnt_cost END )  cost_yb2  --予備２
                 ,SUM( CASE WHEN CCMB.cost_cmpntcls_code = '10YB3' THEN CCD.cmpnt_cost END )  cost_yb3  --予備３
            FROM
                  cm_cmpt_dtl                     CCD                 --品目原価マスタ
                 ,cm_cmpt_mst_b                   CCMB                --コンポーネントマスタ
                 ,cm_cldr_dtl                     CCDD                --原価カレンダ
           WHERE
             --品目原価マスタの抽出条件(Uniqueキーを絞っておく)
                  CCD.whse_code                   = '000'             --倉庫(原価倉庫)
             AND  CCD.cost_mthd_code              = 'STDU'            --原価方法コード
             AND  CCD.cost_analysis_code          = '0000'            --分析コード
             AND  CCD.cost_level                  = 0                 --コストレベル
             AND  CCD.rollover_ind                = 0                 --確定フラグ
             AND  CCD.delete_mark                 = 0                 --削除フラグ
             --コンポーネントマスタ情報取得
             AND  CCD.cost_cmpntcls_id            = CCMB.cost_cmpntcls_id
             --原価カレンダ情報取得
             AND  CCD.calendar_code               = CCDD.calendar_code
             AND  CCD.period_code                 = CCDD.period_code
          GROUP BY
                  CCD.item_id                     --品目ID
                 ,CCDD.start_date                 --有効開始日
                 ,CCDD.end_date                   --有効終了日
       )                           SCCD           --原価集計情報
       ,xxskz_item_mst2_v          ITEM           --品目情報取得用
       ,xxskz_prod_class_v         PRODC          --商品区分取得用
       ,xxskz_item_class_v         ITEMC          --品目区分取得用
       ,xxskz_crowd_code_v         CROWD          --群コード取得用
 WHERE
   --品目情報取得 (原価有効終了日時点で有効な品目情報を取得する事とする)
        SCCD.item_id               = ITEM.item_id(+)
   AND  TRUNC( SCCD.end_date )    >= ITEM.start_date_active(+)
   AND  TRUNC( SCCD.end_date )    <= ITEM.end_date_active(+)
   --品目カテゴリ情報取得
   AND  SCCD.item_id               = PRODC.item_id(+)
   AND  SCCD.item_id               = ITEMC.item_id(+)
   AND  SCCD.item_id               = CROWD.item_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_標準原価集計_基本_V IS 'SKYLINK用標準原価集計（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.商品区分   IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.品目区分   IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.群コード   IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.品目コード IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.品目名     IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.品目略称   IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.有効開始日 IS '有効開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.有効終了日 IS '有効終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.集計原価   IS '集計原価'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.原料費     IS '原料費'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.再製費     IS '再製費'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.資材費     IS '資材費'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.包装費     IS '包装費'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.外注加工費 IS '外注加工費'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.保管費     IS '保管費'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.その他経費 IS 'その他経費'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.FMルート用 IS 'FMルート用'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.予備１     IS '予備１'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.予備２     IS '予備２'
/
COMMENT ON COLUMN APPS.XXSKZ_標準原価集計_基本_V.予備３     IS '予備３'
/
