ALTER TABLE xxcso.xxcso_contract_managements ADD(
  vdms_interface_flag  VARCHAR2(1),
  vdms_interface_date  DATE
);
--
COMMENT ON COLUMN xxcso.xxcso_contract_managements.vdms_interface_flag    IS '���̋@S�A�g�t���O';
COMMENT ON COLUMN xxcso.xxcso_contract_managements.vdms_interface_date    IS '���̋@S�A�g��';
