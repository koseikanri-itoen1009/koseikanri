-- �O���o�������сi�A�h�I���j���ڒǉ��X�N���v�g
ALTER TABLE xxpo.xxpo_vendor_supply_txns ADD (
  po_number  VARCHAR2(20)
)
/
COMMENT ON COLUMN xxpo.xxpo_vendor_supply_txns.po_number  IS '�����ԍ�';
/
