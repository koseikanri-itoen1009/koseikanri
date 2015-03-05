ALTER TABLE xxcso.xxcso_sp_decision_headers ADD(
   contract_year_month           NUMBER(2,0)     -- �_�񌎐�
  ,contract_start_year           NUMBER(4,0)     -- �_����ԊJ�n�i�N�j
  ,contract_start_month          NUMBER(2,0)     -- �_����ԊJ�n�i���j
  ,contract_end_year             NUMBER(4,0)     -- �_����ԏI���i�N�j
  ,contract_end_month            NUMBER(2,0)     -- �_����ԏI���i���j
  ,bidding_item                  VARCHAR2(1)     -- ���D�Č�
  ,cancell_before_maturity       VARCHAR2(1)     -- ���r������
  ,ad_assets_type                VARCHAR2(1)     -- �x���敪�i�s�����Y�g�p���j
  ,ad_assets_amt                 NUMBER(8,0)     -- ���z�i�s�����Y�g�p���j
  ,ad_assets_this_time           NUMBER(8,0)     -- ����x���i�s�����Y�g�p���j
  ,ad_assets_payment_year        NUMBER(2,0)     -- �x���N���i�s�����Y�g�p���j
  ,ad_assets_payment_date        DATE            -- �x�������i�s�����Y�g�p���j
  ,tax_type                      VARCHAR2(1)     -- �ŋ敪
  ,install_supp_type             VARCHAR2(1)     -- �x���敪�i�ݒu���^���j
  ,install_supp_payment_type     VARCHAR2(1)     -- �x�������i�ݒu���^���j
  ,install_supp_amt              NUMBER(8,0)     -- ���z�i�ݒu���^���j
  ,install_supp_this_time        NUMBER(8,0)     -- ����x���i�ݒu���^���j
  ,install_supp_payment_year     NUMBER(2,0)     -- �x���N���i�ݒu���^���j
  ,install_supp_payment_date     DATE            -- �x�������i�ݒu���^���j
  ,electric_payment_type         VARCHAR2(1)     -- �x�������i�d�C��j
  ,electric_payment_change_type  VARCHAR2(1)     -- �x�������i�ϓ��d�C��j
  ,electric_payment_cycle        VARCHAR2(1)     -- �x���T�C�N���i�d�C��j
  ,electric_closing_date         VARCHAR2(2)     -- �����i�d�C��j
  ,electric_trans_month          VARCHAR2(2)     -- �U�����i�d�C��j
  ,electric_trans_date           VARCHAR2(2)     -- �U�����i�d�C��j
  ,electric_trans_name           VARCHAR2(360)   -- �_���ȊO���i�d�C��j
  ,electric_trans_name_alt       VARCHAR2(320)   -- �_���ȊO���J�i�i�d�C��j
  ,intro_chg_type                VARCHAR2(1)     -- �x���敪�i�Љ�萔���j
  ,intro_chg_payment_type        VARCHAR2(1)     -- �x�������i�Љ�萔���j
  ,intro_chg_amt                 NUMBER(8,0)     -- ���z�i�Љ�萔���j
  ,intro_chg_this_time           NUMBER(8,0)     -- ����x���i�Љ�萔���j
  ,intro_chg_payment_year        NUMBER(2,0)     -- �x���N���i�Љ�萔���j
  ,intro_chg_payment_date        DATE            -- �x�������i�Љ�萔���j
  ,intro_chg_per_sales_price     NUMBER(5,2)     -- �̔����z����Љ�萔����
  ,intro_chg_per_piece           NUMBER(8,0)     -- 1�{����Љ�萔���z
  ,intro_chg_closing_date        VARCHAR2(2)     -- �����i�Љ�萔���j
  ,intro_chg_trans_month         VARCHAR2(2)     -- �U�����i�Љ�萔���j
  ,intro_chg_trans_date          VARCHAR2(2)     -- �U�����i�Љ�萔���j
  ,intro_chg_trans_name          VARCHAR2(360)   -- �_���ȊO���i�Љ�萔���j
  ,intro_chg_trans_name_alt      VARCHAR2(320)   -- �_���ȊO���J�i�i�Љ�萔���j
);
--
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_year_month           IS '�_�񌎐�';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_start_year           IS '�_����ԊJ�n�i�N�j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_start_month          IS '�_����ԊJ�n�i���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_end_year             IS '�_����ԏI���i�N�j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_end_month            IS '�_����ԏI���i���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.bidding_item                  IS '���D�Č�';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.cancell_before_maturity       IS '���r������';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_type                IS '�x���敪�i�s�����Y�g�p���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_amt                 IS '���z�i�s�����Y�g�p���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_this_time           IS '����x���i�s�����Y�g�p���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_payment_year        IS '�x���N���i�s�����Y�g�p���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_payment_date        IS '�x�������i�s�����Y�g�p���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.tax_type                      IS '�ŋ敪';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_type             IS '�x���敪�i�ݒu���^���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_payment_type     IS '�x�������i�ݒu���^���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_amt              IS '���z�i�ݒu���^���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_this_time        IS '����x���i�ݒu���^���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_payment_year     IS '�x���N���i�ݒu���^���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_payment_date     IS '�x�������i�ݒu���^���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_payment_type         IS '�x�������i�d�C��j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_payment_change_type  IS '�x�������i�ϓ��d�C��j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_payment_cycle        IS '�x���T�C�N���i�d�C��j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_closing_date         IS '�����i�d�C��j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_trans_month          IS '�U�����i�d�C��j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_trans_date           IS '�U�����i�d�C��j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_trans_name           IS '�_���ȊO���i�d�C��j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_trans_name_alt       IS '�_���ȊO���J�i�i�d�C��j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_type                IS '�x���敪�i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_payment_type        IS '�x�������i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_amt                 IS '���z�i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_this_time           IS '����x���i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_payment_year        IS '�x���N���i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_payment_date        IS '�x�������i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_per_sales_price     IS '�̔����z����Љ�萔����';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_per_piece           IS '1�{����Љ�萔���z';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_closing_date        IS '�����i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_trans_month         IS '�U�����i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_trans_date          IS '�U�����i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_trans_name          IS '�_���ȊO���i�Љ�萔���j';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_trans_name_alt      IS '�_���ȊO���J�i�i�Љ�萔���j';
