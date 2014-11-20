CREATE OR REPLACE VIEW xxcmn_parties_v
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
  base_major_division
)
AS
  SELECT  hp.party_id,
          wc.freight_code,
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
-- 2009/08/03 T.Yoshimoto Mod Start �{��#1570
--          hca.attribute12,
          CASE hp.duns_number_c
            WHEN '30' THEN '0'
            WHEN '40' THEN '0'
            ELSE '2'
          END cust_enable_flag,
-- 2009/08/03 T.Yoshimoto Mod End �{��#1570
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
          xp.base_major_division
  FROM    hz_parties        hp,
          hz_cust_accounts  hca,
          wsh_carriers      wc,
          xxcmn_parties     xp
  WHERE   hp.party_id           = hca.party_id (+)
  AND     hp.party_id           = wc.carrier_id (+)
  AND     hp.party_id           = xp.party_id
  AND     hp.status             = 'A'
  AND     hca.status(+)         = 'A'
  AND     xp.start_date_active  <= TRUNC(SYSDATE)
  AND     xp.end_date_active    >= TRUNC(SYSDATE)
  AND     hca.cust_account_id   IS NULL
  UNION ALL
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
-- 2009/08/03 T.Yoshimoto Mod Start �{��#1570
--          hca.attribute12,
          CASE hp.duns_number_c
            WHEN '30' THEN '0'
            WHEN '40' THEN '0'
            ELSE '2'
          END cust_enable_flag,
-- 2009/08/03 T.Yoshimoto Mod End �{��#1570
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
          xp.base_major_division
  FROM    hz_parties        hp,
          hz_cust_accounts  hca,
          wsh_carriers      wc,
          xxcmn_parties     xp
  WHERE   hp.party_id           = hca.party_id (+)
  AND     hp.party_id           = wc.carrier_id (+)
  AND     hp.party_id           = xp.party_id
  AND     hp.status             = 'A'
  AND     hca.status(+)         = 'A'
  AND     xp.start_date_active  <= TRUNC(SYSDATE)
  AND     xp.end_date_active    >= TRUNC(SYSDATE)
  AND     hca.cust_account_id   IS NOT NULL
;
--
COMMENT ON COLUMN xxcmn_parties_v.party_id               IS '�p�[�e�B�[ID';
COMMENT ON COLUMN xxcmn_parties_v.party_number           IS '�g�D�ԍ�';
COMMENT ON COLUMN xxcmn_parties_v.recept_date            IS '�}�X�^��M����';
COMMENT ON COLUMN xxcmn_parties_v.cust_account_id        IS '�ڋqID';
COMMENT ON COLUMN xxcmn_parties_v.account_number         IS '�ڋq�ԍ�';
COMMENT ON COLUMN xxcmn_parties_v.customer_class_code    IS '�ڋq�敪';
COMMENT ON COLUMN xxcmn_parties_v.division_code          IS '�{���R�[�h';
COMMENT ON COLUMN xxcmn_parties_v.location_rel_code      IS '���_���їL���敪';
COMMENT ON COLUMN xxcmn_parties_v.ship_mng_code          IS '�o�׊Ǘ����敪';
COMMENT ON COLUMN xxcmn_parties_v.leave_shed_div         IS '�q�֑Ώۉۋ敪';
COMMENT ON COLUMN xxcmn_parties_v.terminal_code          IS '�[���L���敪';
COMMENT ON COLUMN xxcmn_parties_v.party_for_factory_code IS '�H��p���_�敪';
COMMENT ON COLUMN xxcmn_parties_v.whse_department        IS '�q�ɊǗ�����';
COMMENT ON COLUMN xxcmn_parties_v.frequent_factory       IS '��\�H��';
COMMENT ON COLUMN xxcmn_parties_v.cust_enable_flag       IS '���~�q�\���t���O';
COMMENT ON COLUMN xxcmn_parties_v.block_name             IS '�n�於';
COMMENT ON COLUMN xxcmn_parties_v.order_auto_code        IS '�o�׈˗������쐬�敪';
COMMENT ON COLUMN xxcmn_parties_v.drop_ship_div          IS '�����敪';
COMMENT ON COLUMN xxcmn_parties_v.shift_judg_flg         IS '�ڍs����t���O';
COMMENT ON COLUMN xxcmn_parties_v.drink_base_category    IS '�h�����N���_�J�e�S��';
COMMENT ON COLUMN xxcmn_parties_v.leaf_base_category     IS '���[�t���_�J�e�S��';
COMMENT ON COLUMN xxcmn_parties_v.sale_base_code         IS '�������㋒�_�R�[�h';
COMMENT ON COLUMN xxcmn_parties_v.res_sale_base_code     IS '�\��(����)���㋒�_�R�[�h';
COMMENT ON COLUMN xxcmn_parties_v.chain_store            IS '����`�F�[���X';
COMMENT ON COLUMN xxcmn_parties_v.chain_store_name       IS '����`�F�[���X��';
COMMENT ON COLUMN xxcmn_parties_v.freight_code           IS '�Z�k��';
COMMENT ON COLUMN xxcmn_parties_v.start_date_active      IS '�K�p�J�n��';
COMMENT ON COLUMN xxcmn_parties_v.end_date_active        IS '�K�p�I����';
COMMENT ON COLUMN xxcmn_parties_v.party_name             IS '������';
COMMENT ON COLUMN xxcmn_parties_v.party_short_name       IS '����';
COMMENT ON COLUMN xxcmn_parties_v.party_name_alt         IS '�J�i��';
COMMENT ON COLUMN xxcmn_parties_v.zip                    IS '�X�֔ԍ�';
COMMENT ON COLUMN xxcmn_parties_v.address_line1          IS '�Z���P';
COMMENT ON COLUMN xxcmn_parties_v.address_line2          IS '�Z���Q';
COMMENT ON COLUMN xxcmn_parties_v.phone                  IS '�d�b�ԍ�';
COMMENT ON COLUMN xxcmn_parties_v.fax                    IS '�e�`�w�ԍ�';
COMMENT ON COLUMN xxcmn_parties_v.reserve_order          IS '������';
COMMENT ON COLUMN xxcmn_parties_v.drink_transfer_std     IS '�h�����N�^���U�֊';
COMMENT ON COLUMN xxcmn_parties_v.leaf_transfer_std      IS '���[�t�^���U�֊';
COMMENT ON COLUMN xxcmn_parties_v.transfer_group         IS '�U�փO���[�v';
COMMENT ON COLUMN xxcmn_parties_v.distribution_block     IS '�����u���b�N';
COMMENT ON COLUMN xxcmn_parties_v.base_major_division    IS '���_�啪��';
--
COMMENT ON TABLE  xxcmn_parties_v IS '�p�[�e�B���VIEW';
