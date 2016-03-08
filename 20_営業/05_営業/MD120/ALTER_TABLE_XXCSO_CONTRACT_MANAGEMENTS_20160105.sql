ALTER TABLE xxcso.xxcso_contract_managements ADD(
  vdms_interface_flag  VARCHAR2(1),
  vdms_interface_date  DATE
);
--
COMMENT ON COLUMN xxcso.xxcso_contract_managements.vdms_interface_flag    IS '自販機S連携フラグ';
COMMENT ON COLUMN xxcso.xxcso_contract_managements.vdms_interface_date    IS '自販機S連携日';
