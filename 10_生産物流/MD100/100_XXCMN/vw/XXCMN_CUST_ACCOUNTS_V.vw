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
-- 2009/10/27 Y.Kawano Mod Start 本番#1675
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
-- 2009/10/27 Y.Kawano Mod End 本番#1675
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
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_id                IS 'パーティーID';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_number            IS '組織番号';
COMMENT ON COLUMN xxcmn_cust_accounts_v.recept_date             IS 'マスタ受信日時';
COMMENT ON COLUMN xxcmn_cust_accounts_v.cust_account_id         IS '顧客ID';
COMMENT ON COLUMN xxcmn_cust_accounts_v.account_number          IS '顧客番号';
COMMENT ON COLUMN xxcmn_cust_accounts_v.customer_class_code     IS '顧客区分';
COMMENT ON COLUMN xxcmn_cust_accounts_v.division_code           IS '本部コード';
COMMENT ON COLUMN xxcmn_cust_accounts_v.location_rel_code       IS '拠点実績有無区分';
COMMENT ON COLUMN xxcmn_cust_accounts_v.ship_mng_code           IS '出荷管理元区分';
COMMENT ON COLUMN xxcmn_cust_accounts_v.leave_shed_div          IS '倉替対象可否区分';
COMMENT ON COLUMN xxcmn_cust_accounts_v.terminal_code           IS '端末有無区分';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_for_factory_code  IS '工場用拠点区分';
COMMENT ON COLUMN xxcmn_cust_accounts_v.whse_department         IS '倉庫管理部署';
COMMENT ON COLUMN xxcmn_cust_accounts_v.frequent_factory        IS '代表工場';
COMMENT ON COLUMN xxcmn_cust_accounts_v.cust_enable_flag        IS '中止客申請フラグ';
COMMENT ON COLUMN xxcmn_cust_accounts_v.block_name              IS '地区名';
COMMENT ON COLUMN xxcmn_cust_accounts_v.order_auto_code         IS '出荷依頼自動作成区分';
COMMENT ON COLUMN xxcmn_cust_accounts_v.drop_ship_div           IS '直送区分';
COMMENT ON COLUMN xxcmn_cust_accounts_v.shift_judg_flg          IS '移行判定フラグ';
COMMENT ON COLUMN xxcmn_cust_accounts_v.drink_base_category     IS 'ドリンク拠点カテゴリ';
COMMENT ON COLUMN xxcmn_cust_accounts_v.leaf_base_category      IS 'リーフ拠点カテゴリ';
COMMENT ON COLUMN xxcmn_cust_accounts_v.sale_base_code          IS '当月売上拠点コード';
COMMENT ON COLUMN xxcmn_cust_accounts_v.res_sale_base_code      IS '予約(翌月)売上拠点コード';
COMMENT ON COLUMN xxcmn_cust_accounts_v.chain_store             IS '売上チェーン店';
COMMENT ON COLUMN xxcmn_cust_accounts_v.chain_store_name        IS '売上チェーン店名';
COMMENT ON COLUMN xxcmn_cust_accounts_v.start_date_active       IS '適用開始日';
COMMENT ON COLUMN xxcmn_cust_accounts_v.end_date_active         IS '適用終了日';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_name              IS '正式名';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_short_name        IS '略称';
COMMENT ON COLUMN xxcmn_cust_accounts_v.party_name_alt          IS 'カナ名';
COMMENT ON COLUMN xxcmn_cust_accounts_v.zip                     IS '郵便番号';
COMMENT ON COLUMN xxcmn_cust_accounts_v.address_line1           IS '住所１';
COMMENT ON COLUMN xxcmn_cust_accounts_v.address_line2           IS '住所２';
COMMENT ON COLUMN xxcmn_cust_accounts_v.phone                   IS '電話番号';
COMMENT ON COLUMN xxcmn_cust_accounts_v.fax                     IS 'ＦＡＸ番号';
COMMENT ON COLUMN xxcmn_cust_accounts_v.reserve_order           IS '引当順';
COMMENT ON COLUMN xxcmn_cust_accounts_v.drink_transfer_std      IS 'ドリンク運賃振替基準';
COMMENT ON COLUMN xxcmn_cust_accounts_v.leaf_transfer_std       IS 'リーフ運賃振替基準';
COMMENT ON COLUMN xxcmn_cust_accounts_v.transfer_group          IS '振替グループ';
COMMENT ON COLUMN xxcmn_cust_accounts_v.distribution_block      IS '物流ブロック';
COMMENT ON COLUMN xxcmn_cust_accounts_v.base_major_division     IS '拠点大分類';
--
COMMENT ON TABLE  xxcmn_cust_accounts_v IS '顧客情報VIEW';
