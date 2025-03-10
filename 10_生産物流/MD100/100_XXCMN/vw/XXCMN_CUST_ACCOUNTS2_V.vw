CREATE OR REPLACE VIEW xxcmn_cust_accounts2_v
(
  party_id,
  party_number,
  party_status,
  recept_date,
  cust_account_id,
  account_number,
  customer_class_code,
  account_status,
  old_division_code,
  new_division_code,
  division_start_date,
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
          hp.status,
          hp.attribute24,
          hca.cust_account_id,
          hca.account_number,
          hca.customer_class_code,
          hca.status,
          hca.attribute1,
          hca.attribute2,
          hca.attribute3,
          hca.attribute4,
          hca.attribute5,
          hca.attribute6,
          hca.attribute7,
          hca.attribute9,
          hca.attribute10,
          hca.attribute11,
-- 2009/10/27 Y.Kawano Mod Start {Ô#1675
--          hca.attribute12,
          CASE hca.customer_class_code
          WHEN '1' THEN
            CASE hp.duns_number_c
            WHEN '30' THEN '0'
            WHEN '40' THEN '0'
            WHEN '99' THEN '0'
            ELSE '2'
            END
          WHEN '10' THEN
            CASE hp.duns_number_c
            WHEN '30' THEN '0'
            WHEN '40' THEN '0'
            ELSE '2'
            END
          END cust_enable_flag,
-- 2009/10/27 Y.Kawano Mod End {Ô#1675
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
  WHERE   hp.party_id = hca.party_id
  AND     hp.party_id = xp.party_id
;
--
COMMENT ON COLUMN xxcmn_cust_accounts2_v.party_id               IS 'p[eB[ID';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.party_number           IS 'gDÔ';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.party_status           IS 'gDXe[^X';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.recept_date            IS '}X^óMú';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.cust_account_id        IS 'ÚqID';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.account_number         IS 'ÚqÔ';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.customer_class_code    IS 'Úqæª';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.account_status         IS 'ÚqXe[^X';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.old_division_code      IS 'E{R[h';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.new_division_code      IS 'VE{R[h';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.division_start_date    IS '{R[hKpJnú';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.location_rel_code      IS '_ÀÑL³æª';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.ship_mng_code          IS 'o×Ç³æª';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.leave_shed_div         IS 'qÖÎÛÂÛæª';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.terminal_code          IS '[L³æª';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.party_for_factory_code IS 'Hêp_æª';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.whse_department        IS 'qÉÇ';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.frequent_factory       IS 'ã\Hê';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.cust_enable_flag       IS '~q\¿tO';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.block_name             IS 'næ¼';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.order_auto_code        IS 'o×Ë©®ì¬æª';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.drop_ship_div          IS '¼æª';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.shift_judg_flg         IS 'Ús»ètO';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.drink_base_category    IS 'hN_JeS';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.leaf_base_category     IS '[t_JeS';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.sale_base_code         IS 'ã_R[h';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.res_sale_base_code     IS '\ñ()ã_R[h';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.chain_store            IS 'ã`F[X';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.chain_store_name       IS 'ã`F[X¼';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.start_date_active      IS 'KpJnú';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.end_date_active        IS 'KpI¹ú';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.party_name             IS '³®¼';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.party_short_name       IS 'ªÌ';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.party_name_alt         IS 'Ji¼';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.zip                    IS 'XÖÔ';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.address_line1          IS 'ZP';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.address_line2          IS 'ZQ';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.phone                  IS 'dbÔ';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.fax                    IS 'e`wÔ';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.reserve_order          IS 'ø';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.drink_transfer_std     IS 'hN^ÀUÖî';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.leaf_transfer_std      IS '[t^ÀUÖî';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.transfer_group         IS 'UÖO[v';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.distribution_block     IS '¨¬ubN';
COMMENT ON COLUMN xxcmn_cust_accounts2_v.base_major_division    IS '_åªÞ';
--
COMMENT ON TABLE  xxcmn_cust_accounts2_v IS 'ÚqîñVIEW2';
