--�e�[�u����`�ǉ�
ALTER TABLE xxcos.xxcos_edi_inventory
  ADD (edi_received_date DATE NULL );


--�R�����g�ǉ�
COMMENT ON COLUMN xxcos.xxcos_edi_inventory.edi_received_date IS 'EDI��M��';