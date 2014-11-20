ALTER TABLE xxinv.xxinv_mov_lot_details ADD (
  actual_confirm_class VARCHAR2(1) DEFAULT 'N'
);
COMMENT ON COLUMN xxinv.xxinv_mov_lot_details.actual_confirm_class      IS 'é¿ê—åvè„çœÉtÉâÉO';
