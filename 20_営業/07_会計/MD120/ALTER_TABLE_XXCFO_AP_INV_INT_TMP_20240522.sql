-- AP�������w�b�_�[OIF�ꎞ�\���ڒǉ�
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
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.request_id  IS '�v��ID';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute5  IS '�������z(�Ŕ�)';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute6  IS '�ŗ�';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute7  IS '�������z(�Ŕ�)2';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute8  IS '�ŗ�2';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute9  IS '�������z(�Ŕ�)3';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute10 IS '�ŗ�3';
COMMENT ON COLUMN xxcfo.xxcfo_ap_inv_int_tmp.attribute11 IS '���z�v�Z�ΏۊO�t���O';
