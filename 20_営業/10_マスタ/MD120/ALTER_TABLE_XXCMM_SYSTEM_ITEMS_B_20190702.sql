ALTER TABLE xxcmm.xxcmm_system_items_b ADD (
  item_dtl_status VARCHAR2(2)
 ,remarks         VARCHAR2(50)
);
COMMENT ON COLUMN xxcmm.xxcmm_system_items_b.item_dtl_status  IS '品目詳細ステータス';
COMMENT ON COLUMN xxcmm.xxcmm_system_items_b.remarks          IS '備考';
