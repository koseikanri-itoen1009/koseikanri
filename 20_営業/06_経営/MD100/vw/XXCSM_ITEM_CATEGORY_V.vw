CREATE OR REPLACE VIEW XXCSM_ITEM_CATEGORY_V
(
  category_id
 ,category_set_id
 ,segment1
 ,description
 ,attribute1
 ,attribute2
 ,attribute3
 ,attribute4
 ,attribute5
 ,attribute6
 ,attribute7
 ,attribute8
 ,attribute9
 ,attribute10
 ,attribute11
 ,attribute12
 ,attribute13
 ,attribute14
 ,attribute15
)
AS
  SELECT  /*+ NO_INDEX(mcb MTL__CATEGORIES_B_N2) */
          mcb.category_id      category_id     --�J�e�S��ID
         ,mcsb.category_set_id category_set_id --�J�e�S���Z�b�gID
         ,mcb.segment1         segment1        --���i�Q�R�[�h
         ,mct.description      description     --����
         ,mcb.attribute1       attribute1      --DFF1(�o�^��)
         ,mcb.attribute2       attribute2      --DFF2(���̑��E�v)
         ,mcb.attribute3       attribute3      --DFF3(�V���i�R�[�h�j
         ,mcb.attribute4       attribute4      --DFF4
         ,mcb.attribute5       attribute5      --DFF5
         ,mcb.attribute6       attribute6      --DFF6
         ,mcb.attribute7       attribute7      --DFF7
         ,mcb.attribute8       attribute8      --DFF8
         ,mcb.attribute9       attribute9      --DFF9
         ,mcb.attribute10      attribute10     --DFF10
         ,mcb.attribute11      attribute11     --DFF11
         ,mcb.attribute12      attribute12     --DFF12
         ,mcb.attribute13      attribute13     --DFF13
         ,mcb.attribute14      attribute14     --DFF14
         ,mcb.attribute15      attribute15     --DFF15
  FROM   mtl_categories_b    mcb
        ,mtl_categories_tl   mct
        ,mtl_category_sets_b mcsb
        ,mtl_category_sets_tl mcst
        ,fnd_id_flex_structures    fifs
        ,xxcsm_process_date_v      xpcdv
  WHERE mcsb.structure_id = mcb.structure_id
  AND   mcb.category_id = mct.category_id
  AND   mct.language = USERENV('LANG')
  AND   mcb.enabled_flag = 'Y'
  AND   NVL(mcb.disable_date,xpcdv.process_date) <= xpcdv.process_date
  AND   fifs.id_flex_structure_code = 'XXCMN_SGUN_CODE'
  AND   fifs.application_id = 401 
  AND   fifs.id_flex_code = 'MCAT'
  AND   fifs.id_flex_num = mcsb.structure_id
  AND   mcsb.category_set_id = mcst.category_set_id
  AND   mcst.language = USERENV('LANG')
/
--
COMMENT ON COLUMN xxcsm_item_category_v.category_id     IS '�J�e�S��ID';
COMMENT ON COLUMN xxcsm_item_category_v.category_set_id IS '�J�e�S���Z�b�gID';
COMMENT ON COLUMN xxcsm_item_category_v.segment1        IS '���i�Q�R�[�h';
COMMENT ON COLUMN xxcsm_item_category_v.description     IS '����';
COMMENT ON COLUMN xxcsm_item_category_v.attribute1      IS 'DFF1(�o�^��)';
COMMENT ON COLUMN xxcsm_item_category_v.attribute2      IS 'DFF2(���̑��E�v)';
COMMENT ON COLUMN xxcsm_item_category_v.attribute3      IS 'DFF3(�V���i�R�[�h)';
COMMENT ON COLUMN xxcsm_item_category_v.attribute4      IS 'DFF4';
COMMENT ON COLUMN xxcsm_item_category_v.attribute5      IS 'DFF5';
COMMENT ON COLUMN xxcsm_item_category_v.attribute6      IS 'DFF6';
COMMENT ON COLUMN xxcsm_item_category_v.attribute7      IS 'DFF7';
COMMENT ON COLUMN xxcsm_item_category_v.attribute8      IS 'DFF8';
COMMENT ON COLUMN xxcsm_item_category_v.attribute9      IS 'DFF9';
COMMENT ON COLUMN xxcsm_item_category_v.attribute10     IS 'DFF10';
COMMENT ON COLUMN xxcsm_item_category_v.attribute11     IS 'DFF11';
COMMENT ON COLUMN xxcsm_item_category_v.attribute12     IS 'DFF12';
COMMENT ON COLUMN xxcsm_item_category_v.attribute13     IS 'DFF13';
COMMENT ON COLUMN xxcsm_item_category_v.attribute14     IS 'DFF14';
COMMENT ON COLUMN xxcsm_item_category_v.attribute15     IS 'DFF15';
--                
COMMENT ON TABLE  xxcsm_item_category_v IS '���i�Q�ꗗ�r���[';

