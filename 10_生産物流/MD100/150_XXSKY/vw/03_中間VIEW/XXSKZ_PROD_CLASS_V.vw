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
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_PROD_CLASS_V
    (ITEM_ID
    ,PROD_CLASS_CODE
    ,PROD_CLASS_NAME
    )
AS
SELECT  GIC.item_id
       ,MCB.segment1                prod_class_code  --���i�敪�R�[�h
       ,MCT.description             prod_class_name  --���i�敪��
  FROM  gmi_item_categories     GIC              --OPM�i�ڃJ�e�S������
       ,mtl_categories_b        MCB              --�i�ڃJ�e�S���}�X�^
       ,mtl_categories_tl       MCT              --�i�ڃJ�e�S���}�X�^���{��
       ,mtl_category_sets_tl    MCS              --�i�ڃJ�e�S���Z�b�g���{��
 WHERE  GIC.category_id = MCB.category_id
   AND  MCB.category_id = MCT.category_id
   AND  MCT.language = 'JA'
   AND  MCT.source_lang = 'JA'
   AND  GIC.category_set_id = MCS.category_set_id
   AND  MCS.language = 'JA'
   AND  MCS.source_lang = 'JA'
   AND  MCS.category_set_name = '���i�敪'
/
COMMENT ON TABLE APPS.XXSKZ_PROD_CLASS_V IS 'SKYLINK�p����VIEW OPM�i�ڋ敪VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_PROD_CLASS_V.ITEM_ID          IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXSKZ_PROD_CLASS_V.PROD_CLASS_CODE  IS '���i�敪�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_PROD_CLASS_V.PROD_CLASS_NAME  IS '���i�敪��'
/
