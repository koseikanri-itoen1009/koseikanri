ALTER TABLE XXCSO.XXCSO_SP_DECISION_HEADERS
ADD(
  INSTALL_PAY_START_DATE        DATE         -- �x�����ԊJ�n���i�ݒu���^���j
, INSTALL_PAY_END_DATE          DATE         -- �x�����ԏI�����i�ݒu���^���j
, AD_ASSETS_PAYMENT_TYPE        VARCHAR2(1)  -- �x�������i�s�����Y�g�p���j
, AD_ASSETS_PAY_START_DATE      DATE         -- �x�����ԊJ�n���i�s�����Y�g�p���j
, AD_ASSETS_PAY_END_DATE        DATE         -- �x�����ԏI�����i�s�����Y�g�p���j
)
/
COMMENT ON COLUMN XXCSO.XXCSO_SP_DECISION_HEADERS.INSTALL_PAY_START_DATE       IS '�x�����ԊJ�n���i�ݒu���^���j'
/
COMMENT ON COLUMN XXCSO.XXCSO_SP_DECISION_HEADERS.INSTALL_PAY_END_DATE         IS '�x�����ԏI�����i�ݒu���^���j'
/
COMMENT ON COLUMN XXCSO.XXCSO_SP_DECISION_HEADERS.AD_ASSETS_PAYMENT_TYPE       IS '�x�������i�s�����Y�g�p���j'
/
COMMENT ON COLUMN XXCSO.XXCSO_SP_DECISION_HEADERS.AD_ASSETS_PAY_START_DATE     IS '�x�����ԊJ�n���i�s�����Y�g�p���j'
/
COMMENT ON COLUMN XXCSO.XXCSO_SP_DECISION_HEADERS.AD_ASSETS_PAY_END_DATE       IS '�x�����ԏI�����i�s�����Y�g�p���j'
/