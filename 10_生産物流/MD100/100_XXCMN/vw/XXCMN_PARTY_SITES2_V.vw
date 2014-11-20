CREATE OR REPLACE VIEW xxcmn_party_sites2_v
(
  party_site_id,
  party_id,
  location_id,
  party_site_number,
  party_site_name,
  party_site_status,
  recept_date,
  cust_account_id,
  cust_acct_site_id,
  cust_acct_site_status,
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
  cust_site_uses_status,
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
          hps.status,
          hps.attribute20,
          hcas.cust_account_id,
          hcas.cust_acct_site_id,
          hcas.status,
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
          hcsu.status,
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
  WHERE   hps.party_site_id       = hcas.party_site_id (+)
  AND     hcas.org_id             = FND_PROFILE.VALUE('ORG_ID')
  AND     hcas.cust_acct_site_id  = hcsu.cust_acct_site_id
  AND     hps.party_site_id       = xps.party_site_id
  AND     hps.party_id            = xps.party_id
  AND     hps.location_id         = xps.location_id
  AND     hcsu.site_use_code      = 'SHIP_TO'
;
--
COMMENT ON COLUMN xxcmn_party_sites2_v.party_site_id           IS 'パーティサイトID';
COMMENT ON COLUMN xxcmn_party_sites2_v.party_id                IS 'パーティーID';
COMMENT ON COLUMN xxcmn_party_sites2_v.location_id             IS 'ロケーションID';
COMMENT ON COLUMN xxcmn_party_sites2_v.party_site_number       IS 'サイト番号';
COMMENT ON COLUMN xxcmn_party_sites2_v.party_site_name         IS 'サイト名';
COMMENT ON COLUMN xxcmn_party_sites2_v.party_site_status       IS 'サイトステータス';
COMMENT ON COLUMN xxcmn_party_sites2_v.recept_date             IS 'マスタ受信日時';
COMMENT ON COLUMN xxcmn_party_sites2_v.cust_account_id         IS '顧客ID';
COMMENT ON COLUMN xxcmn_party_sites2_v.cust_acct_site_id       IS '顧客サイトID';
COMMENT ON COLUMN xxcmn_party_sites2_v.cust_acct_site_status   IS '顧客サイトステータス';
COMMENT ON COLUMN xxcmn_party_sites2_v.drink_calender          IS 'ドリンク基準カレンダ';
COMMENT ON COLUMN xxcmn_party_sites2_v.jpr_user_code           IS 'JPRユーザコード';
COMMENT ON COLUMN xxcmn_party_sites2_v.prefecture_code         IS '都道府県コード';
COMMENT ON COLUMN xxcmn_party_sites2_v.num_of_vehicle          IS '最大入庫車輌';
COMMENT ON COLUMN xxcmn_party_sites2_v.appoint_item_div        IS '指定項目区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.sub_lift_div            IS '付帯業務リフト区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.sub_slip_div            IS '付帯業務専用伝票区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.sub_palette_move_div    IS '付帯業務パレット積替区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.sub_pack_div            IS '付帯業務荷造区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.sub_palette_div         IS '付帯業務専用パレットカゴ区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.rule_div                IS 'ルール区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.pileup_div              IS '段積輸送可否区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.pass_permit_div         IS '通行許可証区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.enter_permit_div        IS '入場許可証区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.vehicle_div             IS '車輌指定区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.contact_at_delivery_div IS '納品時連絡区分';
COMMENT ON COLUMN xxcmn_party_sites2_v.department_code         IS '部署コード';
COMMENT ON COLUMN xxcmn_party_sites2_v.ship_to_no              IS '配送先番号';
COMMENT ON COLUMN xxcmn_party_sites2_v.leaf_calender           IS 'リーフ基準カレンダ';
COMMENT ON COLUMN xxcmn_party_sites2_v.spare2                  IS '予備2';
COMMENT ON COLUMN xxcmn_party_sites2_v.site_use_id             IS '使用目的ID';
COMMENT ON COLUMN xxcmn_party_sites2_v.site_use_code           IS '使用目的コード';
COMMENT ON COLUMN xxcmn_party_sites2_v.primary_flag            IS '主フラグ';
COMMENT ON COLUMN xxcmn_party_sites2_v.cust_site_uses_status   IS '使用目的ステータス';
COMMENT ON COLUMN xxcmn_party_sites2_v.start_date_active       IS '適用開始日';
COMMENT ON COLUMN xxcmn_party_sites2_v.end_date_active         IS '適用終了日';
COMMENT ON COLUMN xxcmn_party_sites2_v.base_code               IS '拠点コード';
COMMENT ON COLUMN xxcmn_party_sites2_v.party_site_full_name    IS '正式名';
COMMENT ON COLUMN xxcmn_party_sites2_v.party_site_short_name   IS '略称';
COMMENT ON COLUMN xxcmn_party_sites2_v.party_site_name_alt     IS 'カナ名';
COMMENT ON COLUMN xxcmn_party_sites2_v.zip                     IS '郵便番号';
COMMENT ON COLUMN xxcmn_party_sites2_v.address_line1           IS '住所１';
COMMENT ON COLUMN xxcmn_party_sites2_v.address_line2           IS '住所２';
COMMENT ON COLUMN xxcmn_party_sites2_v.phone                   IS '電話番号';
COMMENT ON COLUMN xxcmn_party_sites2_v.fax                     IS 'FAX番号';
COMMENT ON COLUMN xxcmn_party_sites2_v.invoice_report_id       IS '送り状レポートID';
COMMENT ON COLUMN xxcmn_party_sites2_v.freshness_condition     IS '鮮度条件';
--
COMMENT ON TABLE  xxcmn_party_sites2_v IS 'パーティサイト情報VIEW2';
