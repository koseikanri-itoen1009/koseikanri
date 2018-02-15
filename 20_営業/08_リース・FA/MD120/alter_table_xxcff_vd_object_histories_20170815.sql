ALTER TABLE xxcff.xxcff_vd_object_histories ADD(
    ifrs_life_in_months    NUMBER(3)
   ,ifrs_cat_deprn_method  VARCHAR2(30)
   ,real_estate_acq_tax    NUMBER(13)
   ,borrowing_cost         NUMBER(13)
   ,other_cost             NUMBER(13)
   ,ifrs_asset_account     VARCHAR2(5)
   ,correct_date           DATE
);
--
COMMENT ON COLUMN xxcff.xxcff_vd_object_histories.ifrs_life_in_months     IS  'IFRS�ϗp�N��';
COMMENT ON COLUMN xxcff.xxcff_vd_object_histories.ifrs_cat_deprn_method   IS  'IFRS���p';
COMMENT ON COLUMN xxcff.xxcff_vd_object_histories.real_estate_acq_tax     IS  '�s���Y�擾��';
COMMENT ON COLUMN xxcff.xxcff_vd_object_histories.borrowing_cost          IS  '�ؓ��R�X�g';
COMMENT ON COLUMN xxcff.xxcff_vd_object_histories.other_cost              IS  '���̑�';
COMMENT ON COLUMN xxcff.xxcff_vd_object_histories.ifrs_asset_account      IS  'IFRS���Y�Ȗ�';
COMMENT ON COLUMN xxcff.xxcff_vd_object_histories.correct_date            IS  '�C���N����';
