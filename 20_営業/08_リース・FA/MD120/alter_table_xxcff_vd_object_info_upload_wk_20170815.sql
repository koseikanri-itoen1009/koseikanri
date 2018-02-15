ALTER TABLE xxcff.xxcff_vd_object_info_upload_wk ADD(
    ifrs_life_in_months    NUMBER(3)
   ,ifrs_cat_deprn_method  VARCHAR2(30)
   ,real_estate_acq_tax    NUMBER(13)
   ,borrowing_cost         NUMBER(13)
   ,other_cost             NUMBER(13)
   ,ifrs_asset_account     VARCHAR2(5)
   ,correct_date           DATE
);
--
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.ifrs_life_in_months    IS  'IFRS耐用年数';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.ifrs_cat_deprn_method  IS  'IFRS償却';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.real_estate_acq_tax    IS  '不動産取得税';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.borrowing_cost         IS  '借入コスト';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.other_cost             IS  'その他';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.ifrs_asset_account     IS  'IFRS資産科目';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.correct_date           IS  '修正年月日';
