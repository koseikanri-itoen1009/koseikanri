-- ���b�g�ʎ�����׃e�[�u�����ڒǉ��X�N���v�g
ALTER TABLE xxcoi.xxcoi_lot_transactions ADD (
  inside_warehouse_code VARCHAR2(10)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_lot_transactions.inside_warehouse_code  IS '�ŏI���ɕۊǏꏊ';
/
