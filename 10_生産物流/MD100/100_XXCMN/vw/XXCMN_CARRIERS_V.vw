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
  eos_control_type,
  eos_detination,
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
          CASE
            WHEN xp.eos_detination IS NULL
              THEN '0'
              ELSE '1'
          END,
          xp.eos_detination,
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
  AND     hca.status(+)           = 'A'
  AND     xp.start_date_active <= TRUNC(SYSDATE)
  AND     xp.end_date_active   >= TRUNC(SYSDATE)
;
--
COMMENT ON COLUMN xxcmn_carriers_v.party_id                  IS 'パーティーID';
COMMENT ON COLUMN xxcmn_carriers_v.party_number              IS '組織番号';
COMMENT ON COLUMN xxcmn_carriers_v.recept_date               IS 'マスタ受信日時';
COMMENT ON COLUMN xxcmn_carriers_v.freight_code              IS '短縮名';
COMMENT ON COLUMN xxcmn_carriers_v.start_date_active         IS '適用開始日';
COMMENT ON COLUMN xxcmn_carriers_v.end_date_active           IS '適用終了日';
COMMENT ON COLUMN xxcmn_carriers_v.party_name                IS '正式名';
COMMENT ON COLUMN xxcmn_carriers_v.party_short_name          IS '略称';
COMMENT ON COLUMN xxcmn_carriers_v.party_name_alt            IS 'カナ名';
COMMENT ON COLUMN xxcmn_carriers_v.zip                       IS '郵便番号';
COMMENT ON COLUMN xxcmn_carriers_v.address_line1             IS '住所１';
COMMENT ON COLUMN xxcmn_carriers_v.address_line2             IS '住所２';
COMMENT ON COLUMN xxcmn_carriers_v.phone                     IS '電話番号';
COMMENT ON COLUMN xxcmn_carriers_v.fax                       IS 'ＦＡＸ番号';
COMMENT ON COLUMN xxcmn_carriers_v.reserve_order             IS '引当順';
COMMENT ON COLUMN xxcmn_carriers_v.drink_transfer_std        IS 'ドリンク運賃振替基準';
COMMENT ON COLUMN xxcmn_carriers_v.leaf_transfer_std         IS 'リーフ運賃振替基準';
COMMENT ON COLUMN xxcmn_carriers_v.transfer_group            IS '振替グループ';
COMMENT ON COLUMN xxcmn_carriers_v.distribution_block        IS '物流ブロック';
COMMENT ON COLUMN xxcmn_carriers_v.base_major_division       IS '拠点大分類';
COMMENT ON COLUMN xxcmn_carriers_v.eos_control_type          IS 'EOS管理区分';
COMMENT ON COLUMN xxcmn_carriers_v.eos_detination            IS 'EOS宛先';
COMMENT ON COLUMN xxcmn_carriers_v.complusion_output_code    IS '強制出力区分';
--
COMMENT ON TABLE  xxcmn_carriers_v IS '運送業者情報VIEW';
