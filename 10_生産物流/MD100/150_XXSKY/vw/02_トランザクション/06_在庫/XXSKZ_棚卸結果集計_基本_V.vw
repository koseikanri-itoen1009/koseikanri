/*************************************************************************
 * 
 * View  Name      : XXSKZ_棚卸結果集計_基本_V
 * Description     : XXSKZ_棚卸結果集計_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_棚卸結果集計_基本_V
(
 棚卸年月
,棚卸倉庫コード
,棚卸倉庫名
,保管場所コード
,保管場所名
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目コード
,品目名
,品目略称
,ロットNO
,製造日
,賞味期限
,固有記号
,棚卸ケース数合計
,入数
,棚卸バラ数合計
)
AS
SELECT  TO_CHAR( XSIR.invent_date, 'YYYYMM' )        --棚卸年月
       ,XSIR.invent_whse_code                        --棚卸倉庫コード
       ,IWM.whse_name                                --棚卸倉庫名
       ,XILV.segment1               location_code    --保管場所コード
       ,XILV.description            location_name    --保管場所名
       ,XPCV.prod_class_code                         --商品区分
       ,XPCV.prod_class_name                         --商品区分名
       ,XICV.item_class_code                         --品目区分
       ,XICV.item_class_name                         --品目区分名
       ,XCCV.crowd_code                              --群コード
       ,XSIR.item_code                               --品目コード
       ,XIMV.item_name                               --品目名
       ,XIMV.item_short_name                         --品目略称
       ,XSIR.lot_no                                  --ロットNo
       ,ILM.attribute1                               --製造日
       ,ILM.attribute3                               --賞味期限
       ,ILM.attribute2                               --固有記号
       ,SUM( XSIR.case_amt )        sum_case_amt     --棚卸ケース数合計
       ,XSIR.content                                 --入数
       ,SUM( XSIR.loose_amt )       sum_loose_amt    --棚卸バラ数合計
FROM    xxinv_stc_inventory_result  XSIR             --棚卸結果アドオン
       ,ic_whse_mst                 IWM              --倉庫名取得
       ,xxskz_item_locations_v      XILV             --保管場所取得用
       ,xxskz_item_mst2_v           XIMV             --品目取得
       ,ic_lots_mst                 ILM              --ロット情報取得
       ,xxskz_prod_class_v          XPCV             --商品区分取得
       ,xxskz_item_class_v          XICV             --品目区分取得
       ,xxskz_crowd_code_v          XCCV             --群コード取得
WHERE
  --倉庫名取得結合
       XSIR.invent_whse_code = IWM.whse_code(+)
  --保管場所情報取得結合
  AND  XILV.allow_pickup_flag(+) = '1'                  --出荷引当対象フラグ
  AND  XSIR.invent_whse_code     = XILV.whse_code(+)
  --品目取得結合
  AND  XIMV.item_id(+) = XSIR.item_id
  AND  XIMV.start_date_active(+) <= XSIR.invent_date
  AND  XIMV.end_date_active(+)   >= XSIR.invent_date
  --ロット情報取得結合
  AND  XSIR.item_id = ILM.item_id(+)
  AND  XSIR.lot_id = ILM.lot_id(+)
  --商品区分取得結合
  AND  XPCV.item_id(+) = XSIR.item_id
  --品目区分取得結合
  AND  XICV.item_id(+) = XSIR.item_id
  --群コード取得結合
  AND  XCCV.item_id(+) = XSIR.item_id
GROUP BY TO_CHAR( XSIR.invent_date, 'YYYYMM' )
        ,XSIR.invent_whse_code
        ,IWM.whse_name
        ,XILV.segment1
        ,XILV.description
        ,XPCV.prod_class_code
        ,XPCV.prod_class_name
        ,XICV.item_class_code
        ,XICV.item_class_name
        ,XCCV.crowd_code
        ,XSIR.item_code
        ,XIMV.item_name
        ,XIMV.item_short_name
        ,XSIR.lot_no
        ,ILM.attribute1
        ,ILM.attribute2
        ,ILM.attribute3
        ,XSIR.content
/
COMMENT ON TABLE APPS.XXSKZ_棚卸結果集計_基本_V IS 'XXSKZ_棚卸結果集計 (基本) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.棚卸年月         IS '棚卸年月'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.棚卸倉庫コード   IS '棚卸倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.棚卸倉庫名       IS '棚卸倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.保管場所コード   IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.保管場所名       IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.商品区分         IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.商品区分名       IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.品目区分         IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.品目区分名       IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.群コード         IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.品目コード       IS '品目コード'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.品目名           IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.品目略称         IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.ロットNO         IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.製造日           IS '製造日'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.賞味期限         IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.固有記号         IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.棚卸ケース数合計 IS '棚卸ケース数合計'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.入数             IS '入数'
/
COMMENT ON COLUMN APPS.XXSKZ_棚卸結果集計_基本_V.棚卸バラ数合計   IS '棚卸バラ数合計'
/
