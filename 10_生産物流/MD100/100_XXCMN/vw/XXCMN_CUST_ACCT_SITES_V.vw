CREATE OR REPLACE VIEW xxcmn_cust_acct_sites_v
(
  party_site_id,
  party_id,
  location_id,
  party_site_number,
  party_site_name,
  recept_date,
  cust_account_id,
  cust_acct_site_id,
  drink_calender,
  jpr_user_code,
  prefecture_code,
  num_of_vehicle,
  appoint_item_div,
  sub_lift_div,
  sub_slip_div,
  sub_palette_move_div,
  sub_pack_div,
  sub_palette_div,
  rule_div,
  pileup_div,
  pass_permit_div,
  enter_permit_div,
  vehicle_div,
  contact_at_delivery_div,
  department_code,
  ship_to_no,
  leaf_calender,
  spare2,
  site_use_id,
  site_use_code,
  primary_flag,
  start_date_active,
  end_date_active,
  base_code,
  party_site_full_name,
  party_site_short_name,
  party_site_name_alt,
  zip,
  address_line1,
  address_line2,
  phone,
  fax,
  invoice_report_id,
  freshness_condition
)
AS
  SELECT  hps.party_site_id,
          hps.party_id,
          hps.location_id,
          hcas.attribute18,
          hps.party_site_name,
          hps.attribute20,
          hcas.cust_account_id,
          hcas.cust_acct_site_id,
          hcas.attribute1,
          hcas.attribute2,
          hcas.attribute3,
          hcas.attribute4,
          hcas.attribute5,
          hcas.attribute6,
          hcas.attribute7,
          hcas.attribute8,
          hcas.attribute9,
          hcas.attribute10,
          hcas.attribute11,
          hcas.attribute12,
          hcas.attribute13,
          hcas.attribute14,
          hcas.attribute15,
          hcas.attribute16,
          hcas.attribute17,
          hcas.attribute18,
          hcas.attribute19,
          hcas.attribute20,
          hcsu.site_use_id,
          hcsu.site_use_code,
          hcsu.primary_flag,
          xps.start_date_active,
          xps.end_date_active,
          xps.base_code,
          xps.party_site_name,
          xps.party_site_short_name,
          xps.party_site_name_alt,
          xps.zip,
          xps.address_line1,
          xps.address_line2,
          xps.phone,
          xps.fax,
          xps.invoice_report_id,
          xps.freshness_condition
  FROM    hz_party_sites          hps,
          hz_cust_acct_sites_all  hcas,
          hz_cust_site_uses_all   hcsu,
          xxcmn_party_sites       xps
  WHERE   hps.party_site_id       = hcas.party_site_id
  AND     hcas.org_id             = FND_PROFILE.VALUE('ORG_ID')
  AND     hcas.cust_acct_site_id  = hcsu.cust_acct_site_id
  AND     hps.party_site_id       = xps.party_site_id
  AND     hps.party_id            = xps.party_id
  AND     hps.location_id         = xps.location_id
  AND     hps.status              = 'A'
  AND     hcas.status             = 'A'
  AND     hcsu.site_use_code      = 'SHIP_TO'
  AND     hcsu.status             = 'A'
  AND     xps.start_date_active   <= TRUNC(SYSDATE)
  AND     xps.end_date_active     >= TRUNC(SYSDATE)
;
--
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_id                 IS '�p�[�e�B�T�C�gID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_id                      IS '�p�[�e�B�[ID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.location_id                   IS '���P�[�V����ID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_number             IS '�T�C�g�ԍ�';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_name               IS '�T�C�g��';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.recept_date                   IS '�}�X�^��M����';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.cust_account_id               IS '�ڋqID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.cust_acct_site_id             IS '�ڋq�T�C�gID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.drink_calender                IS '�h�����N��J�����_';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.jpr_user_code                 IS 'JPR���[�U�R�[�h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.prefecture_code               IS '�s���{���R�[�h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.num_of_vehicle                IS '�ő���Ɏ��q';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.appoint_item_div              IS '�w�荀�ڋ敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_lift_div                  IS '�t�ыƖ����t�g�敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_slip_div                  IS '�t�ыƖ���p�`�[�敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_palette_move_div          IS '�t�ыƖ��p���b�g�ϑ֋敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_pack_div                  IS '�t�ыƖ��ב��敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.sub_palette_div               IS '�t�ыƖ���p�p���b�g�J�S�敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.rule_div                      IS '���[���敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.pileup_div                    IS '�i�ϗA���ۋ敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.pass_permit_div               IS '�ʍs���؋敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.enter_permit_div              IS '���ꋖ�؋敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.vehicle_div                   IS '���q�w��敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.contact_at_delivery_div       IS '�[�i���A���敪';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.department_code               IS '�����R�[�h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.ship_to_no                    IS '�z����ԍ�';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.leaf_calender                 IS '���[�t��J�����_';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.spare2                        IS '�\��2';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.site_use_id                   IS '�g�p�ړIID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.site_use_code                 IS '�g�p�ړI�R�[�h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.primary_flag                  IS '��t���O';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.start_date_active             IS '�K�p�J�n��';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.end_date_active               IS '�K�p�I����';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.base_code                     IS '���_�R�[�h';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_full_name          IS '������';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_short_name         IS '����';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.party_site_name_alt           IS '�J�i��';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.zip                           IS '�X�֔ԍ�';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.address_line1                 IS '�Z���P';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.address_line2                 IS '�Z���Q';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.phone                         IS '�d�b�ԍ�';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.fax                           IS 'FAX�ԍ�';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.invoice_report_id             IS '����󃌃|�[�gID';
COMMENT ON COLUMN xxcmn_cust_acct_sites_v.freshness_condition           IS '�N�x����';
--
COMMENT ON TABLE  xxcmn_cust_acct_sites_v IS '�ڋq�T�C�g���VIEW';
