CREATE OR REPLACE VIEW APPS.XXSKY_CROWD_CODE_V
    (ITEM_ID
    ,CROWD_CODE
    )
AS
SELECT  GIC.item_id
       ,MCB.segment1                crowd_code       --�Q�R�[�h
  FROM  gmi_item_categories         GIC              --OPM�i�ڃJ�e�S������
       ,mtl_categories_b            MCB              --�i�ڃJ�e�S���}�X�^
       ,mtl_category_sets_tl        MCS              --�i�ڃJ�e�S���Z�b�g���{��
 WHERE  GIC.category_id = MCB.category_id
   AND  GIC.category_set_id = MCS.category_set_id
   AND  MCS.language = 'JA'
   AND  MCS.source_lang = 'JA'
   AND  MCS.category_set_name = '�Q�R�[�h'
/
COMMENT ON TABLE APPS.XXSKY_CROWD_CODE_V               IS 'SKYLINK�p����VIEW  OPM�i�ڋ敪VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_CROWD_CODE_V.ITEM_ID      IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXSKY_CROWD_CODE_V.CROWD_CODE   IS '�Q�R�[�h'
/
