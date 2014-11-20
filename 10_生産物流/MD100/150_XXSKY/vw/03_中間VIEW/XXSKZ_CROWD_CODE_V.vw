/*************************************************************************
 * 
 * View  Name      : XXSKZ_CROWD_CODE_V
 * Description     : XXSKZ_CROWD_CODE_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_CROWD_CODE_V
    (ITEM_ID
    ,CROWD_CODE
    )
AS
SELECT  GIC.item_id
       ,MCB.segment1                crowd_code       --群コード
  FROM  gmi_item_categories         GIC              --OPM品目カテゴリ割当
       ,mtl_categories_b            MCB              --品目カテゴリマスタ
       ,mtl_category_sets_tl        MCS              --品目カテゴリセット日本語
 WHERE  GIC.category_id = MCB.category_id
   AND  GIC.category_set_id = MCS.category_set_id
   AND  MCS.language = 'JA'
   AND  MCS.source_lang = 'JA'
   AND  MCS.category_set_name = '群コード'
/
COMMENT ON TABLE APPS.XXSKZ_CROWD_CODE_V               IS 'SKYLINK用中間VIEW  OPM品目区分VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_CROWD_CODE_V.ITEM_ID      IS '品目ID'
/
COMMENT ON COLUMN APPS.XXSKZ_CROWD_CODE_V.CROWD_CODE   IS '群コード'
/
