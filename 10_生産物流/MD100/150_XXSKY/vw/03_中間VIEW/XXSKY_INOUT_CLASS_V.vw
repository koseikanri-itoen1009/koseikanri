CREATE OR REPLACE VIEW APPS.XXSKY_INOUT_CLASS_V
    (ITEM_ID
    ,INOUT_CLASS_CODE
    ,INOUT_CLASS_NAME
    )
AS
SELECT  GIC.item_id
       ,MCB.segment1                inout_class_code  --���O�敪�R�[�h
       ,MCT.description             inout_class_name  --���O�敪��
  FROM  gmi_item_categories     GIC                   --OPM�i�ڃJ�e�S������
       ,mtl_categories_b        MCB                   --�i�ڃJ�e�S���}�X�^
       ,mtl_categories_tl       MCT                   --�i�ڃJ�e�S���}�X�^���{��
       ,mtl_category_sets_tl    MCS                   --�i�ڃJ�e�S���Z�b�g���{��
 WHERE  GIC.category_id = MCB.category_id
   AND  MCB.category_id = MCT.category_id
   AND  MCT.language = 'JA'
   AND  MCT.source_lang = 'JA'
   AND  GIC.category_set_id = MCS.category_set_id
   AND  MCS.language = 'JA'
   AND  MCS.source_lang = 'JA'
   AND  MCS.category_set_name = '���O�敪'
/
COMMENT ON TABLE APPS.XXSKY_INOUT_CLASS_V                      IS 'SKYLINK�p����VIEW OPM���O�敪VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_INOUT_CLASS_V.ITEM_ID             IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXSKY_INOUT_CLASS_V.INOUT_CLASS_CODE    IS '���O�敪�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_INOUT_CLASS_V.INOUT_CLASS_NAME    IS '���O�敪��'
/
