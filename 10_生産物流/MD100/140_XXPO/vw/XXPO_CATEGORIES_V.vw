CREATE OR REPLACE VIEW xxpo_categories_v
(
  category_set_id,
  category_set_name,
  category_set_description,
  validate_flag,
  category_id,
  category_description,
  category_code,
  disable_date,
  enable_flag
)
AS
  SELECT  mcst.category_set_id,
          mcst.category_set_name,
          mcst.description,
          mcsb.validate_flag,
          mct.category_id,
          mct.description,
          mcb.segment1,
          mcb.disable_date,
          mcb.enabled_flag
  FROM    mtl_category_sets_b   mcsb,
          mtl_category_sets_tl  mcst,
          mtl_categories_b      mcb,
          mtl_categories_tl     mct
  WHERE   mcsb.category_set_id  = mcst.category_set_id
  AND     mcst.language         = 'JA'
  AND     mcsb.structure_id     = mcb.structure_id
  AND     mcb.category_id       = mct.category_id
  AND     mct.language          = 'JA';
--
COMMENT ON COLUMN xxpo_categories_v.category_set_id            IS '�J�e�S���Z�b�gID';
COMMENT ON COLUMN xxpo_categories_v.category_set_name          IS '�J�e�S���Z�b�g��';
COMMENT ON COLUMN xxpo_categories_v.category_set_description   IS '�J�e�S���Z�b�g�E�v';
COMMENT ON COLUMN xxpo_categories_v.validate_flag              IS '���؃t���O';
COMMENT ON COLUMN xxpo_categories_v.category_id                IS '�J�e�S��ID';
COMMENT ON COLUMN xxpo_categories_v.category_description       IS '�J�e�S���E�v';
COMMENT ON COLUMN xxpo_categories_v.category_code              IS '�J�e�S���R�[�h';
COMMENT ON COLUMN xxpo_categories_v.disable_date               IS '������';
COMMENT ON COLUMN xxpo_categories_v.enable_flag                IS '�g�p�\�t���O';
--
COMMENT ON TABLE  xxpo_categories_v IS 'XXPO�J�e�S�����VIEW';
