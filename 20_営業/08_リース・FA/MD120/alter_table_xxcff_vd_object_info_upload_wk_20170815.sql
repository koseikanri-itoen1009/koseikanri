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
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.ifrs_life_in_months    IS  'IFRSÏpN';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.ifrs_cat_deprn_method  IS  'IFRSp';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.real_estate_acq_tax    IS  's®Yæ¾Å';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.borrowing_cost         IS  'ØüRXg';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.other_cost             IS  '»Ì¼';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.ifrs_asset_account     IS  'IFRSYÈÚ';
COMMENT ON COLUMN xxcff.xxcff_vd_object_info_upload_wk.correct_date           IS  'C³Nú';
