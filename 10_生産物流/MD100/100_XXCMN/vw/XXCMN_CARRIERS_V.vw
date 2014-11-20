CREATE OR REPLACE VIEW xxcmn_carriers_v
(
  party_id,
  party_number,
  recept_date,
  freight_code,
  start_date_active,
  end_date_active,
  party_name,
  party_short_name,
  party_name_alt,
  zip,
  address_line1,
  address_line2,
  phone,
  fax,
  reserve_order,
  drink_transfer_std,
  leaf_transfer_std,
  transfer_group,
  distribution_block,
  base_major_division,
  department,
  billing_department,
  payment_term_id,
  tax_rounding_rule,
  consumption_tax_code,
  eos_control_type,
  eos_detination,
  carriage_due_date,
  carriage_rounding_rule,
  carriage_tax_code,
  pay_judgement_code,
  complusion_output_code
)
AS
  SELECT  hp.party_id,
          wc.freight_code,
          hp.attribute24,
          wc.freight_code,
          xp.start_date_active,
          xp.end_date_active,
          xp.party_name,
          xp.party_short_name,
          xp.party_name_alt,
          xp.zip,
          xp.address_line1,
          xp.address_line2,
          xp.phone,
          xp.fax,
          xp.reserve_order,
          xp.drink_transfer_std,
          xp.leaf_transfer_std,
          xp.transfer_group,
          xp.distribution_block,
          xp.base_major_division,
          xp.department,
          xp.billing_department,
          xp.payment_term_id,
          xp.tax_rounding_rule,
          xp.consumption_tax_code,
          xp.eos_control_type,
          xp.eos_detination,
          xp.carriage_due_date,
          xp.carriage_rounding_rule,
          xp.carriage_tax_code,
          xp.pay_judgement_code,
          CASE
            WHEN hca.class_code = '3PL'
              THEN '1'
              ELSE '0'
          END
  FROM    hz_parties      hp,
          wsh_carriers    wc,
          xxcmn_parties   xp,
          hz_code_assignments hca
  WHERE   hp.party_id          = wc.carrier_id
  AND     hp.party_id          = xp.party_id
  AND     hp.status            = 'A'
  AND     hp.party_id          = hca.owner_table_id(+) 
  AND     hca.owner_table_name(+) = 'HZ_PARTIES' 
  AND     hca.class_category(+)   = 'TRANSPORTATION_PROVIDERS'
  AND     xp.start_date_active <= TRUNC(SYSDATE)
  AND     xp.end_date_active   >= TRUNC(SYSDATE)
;
--
COMMENT ON COLUMN xxcmn_carriers_v.party_id                  IS '�p�[�e�B�[ID';
COMMENT ON COLUMN xxcmn_carriers_v.party_number              IS '�g�D�ԍ�';
COMMENT ON COLUMN xxcmn_carriers_v.recept_date               IS '�}�X�^��M����';
COMMENT ON COLUMN xxcmn_carriers_v.freight_code              IS '�Z�k��';
COMMENT ON COLUMN xxcmn_carriers_v.start_date_active         IS '�K�p�J�n��';
COMMENT ON COLUMN xxcmn_carriers_v.end_date_active           IS '�K�p�I����';
COMMENT ON COLUMN xxcmn_carriers_v.party_name                IS '������';
COMMENT ON COLUMN xxcmn_carriers_v.party_short_name          IS '����';
COMMENT ON COLUMN xxcmn_carriers_v.party_name_alt            IS '�J�i��';
COMMENT ON COLUMN xxcmn_carriers_v.zip                       IS '�X�֔ԍ�';
COMMENT ON COLUMN xxcmn_carriers_v.address_line1             IS '�Z���P';
COMMENT ON COLUMN xxcmn_carriers_v.address_line2             IS '�Z���Q';
COMMENT ON COLUMN xxcmn_carriers_v.phone                     IS '�d�b�ԍ�';
COMMENT ON COLUMN xxcmn_carriers_v.fax                       IS '�e�`�w�ԍ�';
COMMENT ON COLUMN xxcmn_carriers_v.reserve_order             IS '������';
COMMENT ON COLUMN xxcmn_carriers_v.drink_transfer_std        IS '�h�����N�^���U�֊';
COMMENT ON COLUMN xxcmn_carriers_v.leaf_transfer_std         IS '���[�t�^���U�֊';
COMMENT ON COLUMN xxcmn_carriers_v.transfer_group            IS '�U�փO���[�v';
COMMENT ON COLUMN xxcmn_carriers_v.distribution_block        IS '�����u���b�N';
COMMENT ON COLUMN xxcmn_carriers_v.base_major_division       IS '���_�啪��';
COMMENT ON COLUMN xxcmn_carriers_v.department                IS '����';
COMMENT ON COLUMN xxcmn_carriers_v.billing_department        IS '�����Ǘ�����';
COMMENT ON COLUMN xxcmn_carriers_v.payment_term_id           IS '�x������';
COMMENT ON COLUMN xxcmn_carriers_v.tax_rounding_rule         IS '�l�̌ܓ��敪';
COMMENT ON COLUMN xxcmn_carriers_v.consumption_tax_code      IS '����ŋ敪';
COMMENT ON COLUMN xxcmn_carriers_v.eos_control_type          IS 'EOS�Ǘ��敪';
COMMENT ON COLUMN xxcmn_carriers_v.eos_detination            IS 'EOS����';
COMMENT ON COLUMN xxcmn_carriers_v.carriage_due_date         IS '�^���� - ����';
COMMENT ON COLUMN xxcmn_carriers_v.carriage_rounding_rule    IS '�^���� - �l�̌ܓ��敪';
COMMENT ON COLUMN xxcmn_carriers_v.carriage_tax_code         IS '�^���� - ����ŋ敪';
COMMENT ON COLUMN xxcmn_carriers_v.pay_judgement_code        IS '�x�����f�敪';
COMMENT ON COLUMN xxcmn_carriers_v.complusion_output_code    IS '�����o�͋敪';
--
COMMENT ON TABLE  xxcmn_carriers_v IS '�^���Ǝҏ��VIEW';
