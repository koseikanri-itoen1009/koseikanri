-- AP請求書ヘッダーOIF一時表項目追加
ALTER TABLE xxcfo.xxcfo_ap_inv_int_tmp ADD(
  request_id     NUMBER(15)
 ,attribute5     VARCHAR2(150)
 ,attribute6     VARCHAR2(150)
 ,attribute7     VARCHAR2(150)
 ,attribute8     VARCHAR2(150)
 ,attribute9     VARCHAR2(150)
 ,attribute10    VARCHAR2(150)
 ,attribute11    VARCHAR2(150)
);
--
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.request_id  IS '要求ID';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute5  IS '請求金額(税抜)';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute6  IS '税率';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute7  IS '請求金額(税抜)2';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute8  IS '税率2';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute9  IS '請求金額(税抜)3';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute10 IS '税率3';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute11 IS '差額計算対象外フラグ';
