/*************************************************************************
 * 
 * View  Name      : XXSKZ_PROD_CLASS_V
 * Description     : XXSKZ_PROD_CLASS_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_PROD_CLASS_V
    (ITEM_ID
    ,PROD_CLASS_CODE
    ,PROD_CLASS_NAME
    )
AS
SELECT  GIC.item_id
       ,MCB.segment1                prod_class_code  --商品区分コード
       ,MCT.description             prod_class_name  --商品区分名
  FROM  gmi_item_categories     GIC              --OPM品目カテゴリ割当
       ,mtl_categories_b        MCB              --品目カテゴリマスタ
       ,mtl_categories_tl       MCT              --品目カテゴリマスタ日本語
       ,mtl_category_sets_tl    MCS              --品目カテゴリセット日本語
 WHERE  GIC.category_id = MCB.category_id
   AND  MCB.category_id = MCT.category_id
   AND  MCT.language = 'JA'
   AND  MCT.source_lang = 'JA'
   AND  GIC.category_set_id = MCS.category_set_id
   AND  MCS.language = 'JA'
   AND  MCS.source_lang = 'JA'
   AND  MCS.category_set_name = '商品区分'
/
COMMENT ON TABLE APPS.XXSKZ_PROD_CLASS_V IS 'SKYLINK用中間VIEW OPM品目区分VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_PROD_CLASS_V.ITEM_ID          IS '品目ID'
/
COMMENT ON COLUMN APPS.XXSKZ_PROD_CLASS_V.PROD_CLASS_CODE  IS '商品区分コード'
/
COMMENT ON COLUMN APPS.XXSKZ_PROD_CLASS_V.PROD_CLASS_NAME  IS '商品区分名'
/
