-- ���b�g�ʈ����\���ʈꎞ�\���ڒǉ��X�N���v�g
ALTER TABLE xxcoi.xxcoi_tmp_lot_reserve_qty ADD (
  priority NUMBER
)
/
COMMENT ON COLUMN xxcoi.xxcoi_tmp_lot_reserve_qty.priority  IS '�D�揇��';
/