CREATE OR REPLACE VIEW xxcmn_carriers2_v
(
  party_id,
  party_number,
  party_status,
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
          hp.status,
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
  WHERE   hp.party_id = wc.carrier_id
  AND     hp.party_id = xp.party_id
  AND     hp.party_id          = hca.owner_table_id(+) 
  AND     hca.owner_table_name(+) = 'HZ_PARTIES' 
  AND     hca.class_category(+)   = 'TRANSPORTATION_PROVIDERS'
  AND     hca.status(+)           = 'A'
;
--
COMMENT ON COLUMN xxcmn_carriers2_v.party_id                    IS 'p[eB[ID';
COMMENT ON COLUMN xxcmn_carriers2_v.party_number                IS 'gDÔ';
COMMENT ON COLUMN xxcmn_carriers2_v.party_status                IS 'gDXe[^X';
COMMENT ON COLUMN xxcmn_carriers2_v.recept_date                 IS '}X^óMú';
COMMENT ON COLUMN xxcmn_carriers2_v.freight_code                IS 'Zk¼';
COMMENT ON COLUMN xxcmn_carriers2_v.start_date_active           IS 'KpJnú';
COMMENT ON COLUMN xxcmn_carriers2_v.end_date_active             IS 'KpI¹ú';
COMMENT ON COLUMN xxcmn_carriers2_v.party_name                  IS '³®¼';
COMMENT ON COLUMN xxcmn_carriers2_v.party_short_name            IS 'ªÌ';
COMMENT ON COLUMN xxcmn_carriers2_v.party_name_alt              IS 'Ji¼';
COMMENT ON COLUMN xxcmn_carriers2_v.zip                         IS 'XÖÔ';
COMMENT ON COLUMN xxcmn_carriers2_v.address_line1               IS 'ZP';
COMMENT ON COLUMN xxcmn_carriers2_v.address_line2               IS 'ZQ';
COMMENT ON COLUMN xxcmn_carriers2_v.phone                       IS 'dbÔ';
COMMENT ON COLUMN xxcmn_carriers2_v.fax                         IS 'e`wÔ';
COMMENT ON COLUMN xxcmn_carriers2_v.reserve_order               IS 'ø';
COMMENT ON COLUMN xxcmn_carriers2_v.drink_transfer_std          IS 'hN^ÀUÖî';
COMMENT ON COLUMN xxcmn_carriers2_v.leaf_transfer_std           IS '[t^ÀUÖî';
COMMENT ON COLUMN xxcmn_carriers2_v.transfer_group              IS 'UÖO[v';
COMMENT ON COLUMN xxcmn_carriers2_v.distribution_block          IS '¨¬ubN';
COMMENT ON COLUMN xxcmn_carriers2_v.base_major_division         IS '_åªÞ';
COMMENT ON COLUMN xxcmn_carriers2_v.eos_control_type            IS 'EOSÇæª';
COMMENT ON COLUMN xxcmn_carriers2_v.eos_detination              IS 'EOS¶æ';
COMMENT ON COLUMN xxcmn_carriers2_v.complusion_output_code      IS '­§oÍæª';
--
COMMENT ON TABLE  xxcmn_carriers2_v IS '^ÆÒîñVIEW2';
