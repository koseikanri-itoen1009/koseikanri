-- ���b�g�ʎ�����׃e�[�u�����ڒǉ��X�N���v�g
ALTER TABLE xxcoi.xxcoi_lot_transactions ADD (
  wf_delivery_flag  VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcoi.xxcoi_lot_transactions.wf_delivery_flag  IS 'WF�z�M�σt���O';
/
