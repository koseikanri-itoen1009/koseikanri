ALTER TABLE xxcso.xxcso_sp_decision_headers ADD(
  construction_start_year         NUMBER(4,0),  -- �H���J�n�i�N�j
  construction_start_month        NUMBER(2,0),  -- �H���J�n�i���j
  construction_end_year           NUMBER(4,0),  -- �H���I���i�N�j
  construction_end_month          NUMBER(2,0),  -- �H���I���i���j
  Installation_start_year         NUMBER(4,0),  -- �ݒu�����݊��ԊJ�n�i�N�j
  Installation_start_month        NUMBER(2,0),  -- �ݒu�����݊��ԊJ�n�i���j
  Installation_end_year           NUMBER(4,0),  -- �ݒu�����݊��ԏI���i�N�j
  Installation_end_month          NUMBER(2,0)   -- �ݒu�����݊��ԏI���i���j
);
--
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.construction_start_year       IS '�H���J�n�i�N�j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.construction_start_month      IS '�H���J�n�i���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.construction_end_year         IS '�H���I���i�N�j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.construction_end_month        IS '�H���I���i���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.Installation_start_year       IS '�ݒu�����݊��ԊJ�n�i�N�j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.Installation_start_month      IS '�ݒu�����݊��ԊJ�n�i���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.Installation_end_year         IS '�ݒu�����݊��ԏI���i�N�j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.Installation_end_month        IS '�ݒu�����݊��ԏI���i���j';
