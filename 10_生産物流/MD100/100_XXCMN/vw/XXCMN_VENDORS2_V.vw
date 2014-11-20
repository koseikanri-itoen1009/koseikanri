CREATE OR REPLACE VIEW xxcmn_vendors2_v
(
  vendor_id,
  segment1,
  vendor_name,
  customer_num,
  inactive_date,
  spare1,
  frequent_factory,
  product_result_type,
  frequent_delivery,
  vendor_div,
  memo,
  spare2,
  spare3,
  spare4,
  spare5,
  spare6,
  spare7,
  spare8,
  spare9,
  spare10,
  start_date_active,
  end_date_active,
  vendor_full_name,
  vendor_short_name,
  vendor_name_alt,
  zip,
  address_line1,
  address_line2,
  phone,
  fax,
  department,
  terms_date,
  payment_to,
  mediation
)
AS
  SELECT  pv.vendor_id,
          pv.segment1,
          pv.vendor_name,
          pv.customer_num,
          pv.end_date_active,
          pv.attribute1,
          pv.attribute2,
          pv.attribute3,
          pv.attribute4,
          pv.attribute5,
          pv.attribute6,
          pv.attribute7,
          pv.attribute8,
          pv.attribute9,
          pv.attribute10,
          pv.attribute11,
          pv.attribute12,
          pv.attribute13,
          pv.attribute14,
          pv.attribute15,
          xv.start_date_active,
          xv.end_date_active,
          xv.vendor_name,
          xv.vendor_short_name,
          xv.vendor_name_alt,
          xv.zip,
          xv.address_line1,
          xv.address_line2,
          xv.phone,
          xv.fax,
          xv.department,
          xv.terms_date,
          xv.payment_to,
          xv.mediation
  FROM    po_vendors      pv,
          xxcmn_vendors   xv
  WHERE   pv.vendor_id = xv.vendor_id
;
--
COMMENT ON COLUMN xxcmn_vendors2_v.vendor_id             IS 'd“üæID';
COMMENT ON COLUMN xxcmn_vendors2_v.segment1              IS 'd“üæ”Ô†';
COMMENT ON COLUMN xxcmn_vendors2_v.vendor_name           IS 'd“üæ–¼';
COMMENT ON COLUMN xxcmn_vendors2_v.customer_num          IS 'ŒÚ‹q”Ô†';
COMMENT ON COLUMN xxcmn_vendors2_v.end_date_active       IS '–³Œø“ú';
COMMENT ON COLUMN xxcmn_vendors2_v.spare1                IS '—\”õ1';
COMMENT ON COLUMN xxcmn_vendors2_v.frequent_factory      IS '‘ã•\Hê';
COMMENT ON COLUMN xxcmn_vendors2_v.product_result_type   IS '¶YÀÑˆ—ƒ^ƒCƒv';
COMMENT ON COLUMN xxcmn_vendors2_v.frequent_delivery     IS '‘ã•\”[“üæ';
COMMENT ON COLUMN xxcmn_vendors2_v.vendor_div            IS 'd“üæ‹æ•ª';
COMMENT ON COLUMN xxcmn_vendors2_v.memo                  IS '”õl';
COMMENT ON COLUMN xxcmn_vendors2_v.spare2                IS '—\”õ2';
COMMENT ON COLUMN xxcmn_vendors2_v.spare3                IS '—\”õ3';
COMMENT ON COLUMN xxcmn_vendors2_v.spare4                IS '—\”õ4';
COMMENT ON COLUMN xxcmn_vendors2_v.spare5                IS '—\”õ5';
COMMENT ON COLUMN xxcmn_vendors2_v.spare6                IS '—\”õ6';
COMMENT ON COLUMN xxcmn_vendors2_v.spare7                IS '—\”õ7';
COMMENT ON COLUMN xxcmn_vendors2_v.spare8                IS '—\”õ8';
COMMENT ON COLUMN xxcmn_vendors2_v.spare9                IS '—\”õ9';
COMMENT ON COLUMN xxcmn_vendors2_v.spare10               IS '—\”õ10';
COMMENT ON COLUMN xxcmn_vendors2_v.start_date_active     IS '“K—pŠJn“ú';
COMMENT ON COLUMN xxcmn_vendors2_v.end_date_active       IS '“K—pI—¹“ú';
COMMENT ON COLUMN xxcmn_vendors2_v.vendor_full_name      IS '³®–¼';
COMMENT ON COLUMN xxcmn_vendors2_v.vendor_short_name     IS '—ªÌ';
COMMENT ON COLUMN xxcmn_vendors2_v.vendor_name_alt       IS 'ƒJƒi–¼';
COMMENT ON COLUMN xxcmn_vendors2_v.zip                   IS '—X•Ö”Ô†';
COMMENT ON COLUMN xxcmn_vendors2_v.address_line1         IS 'ZŠ‚P';
COMMENT ON COLUMN xxcmn_vendors2_v.address_line2         IS 'ZŠ‚Q';
COMMENT ON COLUMN xxcmn_vendors2_v.phone                 IS '“d˜b”Ô†';
COMMENT ON COLUMN xxcmn_vendors2_v.fax                   IS 'FAX”Ô†';
COMMENT ON COLUMN xxcmn_vendors2_v.department            IS '•”';
COMMENT ON COLUMN xxcmn_vendors2_v.terms_date            IS 'x•¥ğŒİ’è“ú';
COMMENT ON COLUMN xxcmn_vendors2_v.payment_to            IS 'x•¥æ';
COMMENT ON COLUMN xxcmn_vendors2_v.mediation             IS 'ˆ´ùÒ';
--
COMMENT ON TABLE  xxcmn_vendors2_v IS 'd“üæî•ñVIEW2';
