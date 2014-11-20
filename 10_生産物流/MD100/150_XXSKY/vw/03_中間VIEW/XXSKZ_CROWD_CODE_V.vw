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
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_CROWD_CODE_V
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
COMMENT ON TABLE APPS.XXSKZ_CROWD_CODE_V               IS 'SKYLINK�p����VIEW  OPM�i�ڋ敪VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_CROWD_CODE_V.ITEM_ID      IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXSKZ_CROWD_CODE_V.CROWD_CODE   IS '�Q�R�[�h'
/
