ALTER TABLE xxcmm.xxcmm_wk_item_batch_regist ADD (
  item_dtl_status VARCHAR2(100)
 ,remarks         VARCHAR2(100)
);
COMMENT ON COLUMN xxcmm.xxcmm_wk_item_batch_regist.item_dtl_status  IS '�i�ڏڍ׃X�e�[�^�X';
COMMENT ON COLUMN xxcmm.xxcmm_wk_item_batch_regist.remarks          IS '���l';
