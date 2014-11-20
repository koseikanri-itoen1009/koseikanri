CREATE OR REPLACE VIEW xxcmn_cust_accounts_v
(
  party_id,
  party_number,
  recept_date,
  cust_account_id,
  account_number,
  customer_class_code,
  division_code,
  location_rel_code,
  ship_mng_code,
  leave_shed_div,
  terminal_code,
  party_for_factory_code,
  whse_department,
  frequent_factory,
  cust_enable_flag,
  block_name,
  order_auto_code,
  drop_ship_div,
  shift_judg_flg,
  drink_base_category,
  leaf_base_category,
  sale_base_code,
  res_sale_base_code,
  chain_store,
  chain_store_name,
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
  base_major_division
)
AS
  SELECT  hp.party_id,
          hca.account_number,
          hp.attribute24,
          hca.cust_account_id,
          hca.account_number,
          hca.customer_class_code,
          CASE
            WHEN hca.attribute3 <= TO_CHAR(SYSDATE,'YYYYMMDD')
              THEN hca.attribute2
              ELSE hca.attribute1
          END,
          hca.attribute4,
          hca.attribute5,
          hca.attribute6,
          hca.attribute7,
          hca.attribute9,
          hca.attribute10,
          hca.attribute11,
          hca.attribute12,
          NULL,
          hca.attribute14,
          hca.attribute15,
          NULL,
          hca.attribute13,
          hca.attribute16,
          hca.attribute17,
          hca.attribute18,
          hca.attribute19,
          hca.attribute20,
          xp.start_date_active,
          xp.end_date_active,
          xp.party_name,
          CASE
            WHEN hca.customer_class_code = '10'
              THEN xp.party_name
              ELSE xp.party_short_name
          END,
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
          xp.base_major_division
  FROM    hz_parties        hp,
          hz_cust_accounts  hca,
          xxcmn_parties     xp
 WHERE    hp.party_id           = hca.party_id
 AND      hp.party_id           = xp.party_id
 AND      hp.status             = 'A'
 AND      hca.status            = 'A'
 AND      xp.start_date_active  <= TRUNC(SYSDATE)
 AND      xp.end_date_active    >= TRUNC(SYSDATE)
;
--
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_id                IS '�p�[�e�B�[ID';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_number            IS '�g�D�ԍ�';
COMMENT ON COLUMN xxcmn_cust_accounts_v.recept_date             IS '�}�X�^��M����';
COMMENT ON COLUMN xxcmn_cust_accounts_v.cust_account_id         IS '�ڋqID';
COMMENT ON COLUMN xxcmn_cust_accounts_v.account_number          IS '�ڋq�ԍ�';
COMMENT ON COLUMN xxcmn_cust_accounts_v.customer_class_code     IS '�ڋq�敪';
COMMENT ON COLUMN xxcmn_cust_accounts_v.division_code           IS '�{���R�[�h';
COMMENT ON COLUMN xxcmn_cust_accounts_v.location_rel_code       IS '���_���їL���敪';
COMMENT ON COLUMN xxcmn_cust_accounts_v.ship_mng_code           IS '�o�׊Ǘ����敪';
COMMENT ON COLUMN xxcmn_cust_accounts_v.leave_shed_div          IS '�q�֑Ώۉۋ敪';
COMMENT ON COLUMN xxcmn_cust_accounts_v.terminal_code           IS '�[���L���敪';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_for_factory_code  IS '�H��p���_�敪';
COMMENT ON COLUMN xxcmn_cust_accounts_v.whse_department         IS '�q�ɊǗ�����';
COMMENT ON COLUMN xxcmn_cust_accounts_v.frequent_factory        IS '��\�H��';
COMMENT ON COLUMN xxcmn_cust_accounts_v.cust_enable_flag        IS '���~�q�\���t���O';
COMMENT ON COLUMN xxcmn_cust_accounts_v.block_name              IS '�n�於';
COMMENT ON COLUMN xxcmn_cust_accounts_v.order_auto_code         IS '�o�׈˗������쐬�敪';
COMMENT ON COLUMN xxcmn_cust_accounts_v.drop_ship_div           IS '�����敪';
COMMENT ON COLUMN xxcmn_cust_accounts_v.shift_judg_flg          IS '�ڍs����t���O';
COMMENT ON COLUMN xxcmn_cust_accounts_v.drink_base_category     IS '�h�����N���_�J�e�S��';
COMMENT ON COLUMN xxcmn_cust_accounts_v.leaf_base_category      IS '���[�t���_�J�e�S��';
COMMENT ON COLUMN xxcmn_cust_accounts_v.sale_base_code          IS '�������㋒�_�R�[�h';
COMMENT ON COLUMN xxcmn_cust_accounts_v.res_sale_base_code      IS '�\��(����)���㋒�_�R�[�h';
COMMENT ON COLUMN xxcmn_cust_accounts_v.chain_store             IS '����`�F�[���X';
COMMENT ON COLUMN xxcmn_cust_accounts_v.chain_store_name        IS '����`�F�[���X��';
COMMENT ON COLUMN xxcmn_cust_accounts_v.start_date_active       IS '�K�p�J�n��';
COMMENT ON COLUMN xxcmn_cust_accounts_v.end_date_active         IS '�K�p�I����';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_name              IS '������';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_short_name        IS '����';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_name_alt          IS '�J�i��';
COMMENT ON COLUMN xxcmn_cust_accounts_v.zip                     IS '�X�֔ԍ�';
COMMENT ON COLUMN xxcmn_cust_accounts_v.address_line1           IS '�Z���P';
COMMENT ON COLUMN xxcmn_cust_accounts_v.address_line2           IS '�Z���Q';
COMMENT ON COLUMN xxcmn_cust_accounts_v.phone                   IS '�d�b�ԍ�';
COMMENT ON COLUMN xxcmn_cust_accounts_v.fax                     IS '�e�`�w�ԍ�';
COMMENT ON COLUMN xxcmn_cust_accounts_v.reserve_order           IS '������';
COMMENT ON COLUMN xxcmn_cust_accounts_v.drink_transfer_std      IS '�h�����N�^���U�֊';
COMMENT ON COLUMN xxcmn_cust_accounts_v.leaf_transfer_std       IS '���[�t�^���U�֊';
COMMENT ON COLUMN xxcmn_cust_accounts_v.transfer_group          IS '�U�փO���[�v';
COMMENT ON COLUMN xxcmn_cust_accounts_v.distribution_block      IS '�����u���b�N';
COMMENT ON COLUMN xxcmn_cust_accounts_v.base_major_division     IS '���_�啪��';
--
COMMENT ON TABLE  xxcmn_cust_accounts_v IS '�ڋq���VIEW';
