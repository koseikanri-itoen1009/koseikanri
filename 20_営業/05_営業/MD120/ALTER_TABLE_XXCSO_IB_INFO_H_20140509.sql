ALTER TABLE xxcso.xxcso_ib_info_h ADD (
  declaration_place               VARCHAR2(5),
  disposal_intaface_flag          VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcso.xxcso_ib_info_h.declaration_place                      IS '申告地'
/
COMMENT ON COLUMN xxcso.xxcso_ib_info_h.disposal_intaface_flag                 IS '廃棄連携フラグ'
/
