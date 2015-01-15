/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name   : XXCFO_VENDOR_MST_READ_V
 * Description : 仕入先マスタ読み替えビュー
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014-09-19    1.0   K.Kubo           新規作成
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcfo_vendor_mst_read_v(
  mfg_vendor_code
, mfg_vendor_name
, mfg_vendor_site_id
, mfg_vendor_site_code
, mfg_vendor_site_name
, sales_vendor_code
, sales_vendor_name
, sales_vendor_site_code
, sales_vendor_site_name
, sales_accts_pay_ccid
)
AS
SELECT  mfg_pv.segment1                           AS mfg_vendor_code         -- 仕入先コード（生産）
       ,mfg_xv.vendor_name                        AS mfg_vendor_name         -- 仕入先名（生産）
       ,mfg_pvsa.vendor_site_id                   AS mfg_vendor_site_id      -- 仕入先サイトID（生産）
       ,mfg_pvsa.vendor_site_code                 AS mfg_vendor_site_code    -- 仕入先サイトコード（生産）
       ,mfg_xvsa.vendor_site_name                 AS mfg_vendor_site_name    -- 仕入先サイト名（生産）
       ,sa_pv.segment1                            AS sales_vendor_code       -- 仕入先コード（営業）
       ,sa_pv.vendor_name                         AS sales_vendor_name       -- 仕入先名（営業）
       ,sa_pvsa.vendor_site_code                  AS sales_vendor_site_code  -- 仕入先サイトコード（営業）
       ,sa_pvsa.attribute1                        AS sales_vendor_site_name  -- 仕入先サイト名（営業）
       ,sa_pvsa.accts_pay_code_combination_id     AS sales_accts_pay_ccid    -- 負債勘定CCID（営業）
FROM    po_vendors                mfg_pv          -- 仕入先マスタ（生産）
       ,po_vendor_sites_all       mfg_pvsa        -- 仕入先サイトマスタ（生産）
       ,xxcmn_vendors             mfg_xv          -- 仕入先アドオンマスタ（生産）
       ,xxcmn_vendor_sites_all    mfg_xvsa        -- 仕入先サイトアドオンマスタ（生産）
       ,po_vendors                sa_pv           -- 仕入先マスタ（営業）
       ,po_vendor_sites_all       sa_pvsa         -- 仕入先サイトマスタ（営業）
WHERE  
       --生産 仕入先の紐付け
       mfg_pv.vendor_id        = mfg_pvsa.vendor_id
AND    mfg_pv.vendor_id        = mfg_xv.vendor_id
AND    ((mfg_xv.start_date_active <= trunc(sysdate)) AND (mfg_xv.end_date_active >= trunc(sysdate)))
AND    mfg_pvsa.vendor_site_id = mfg_xvsa.vendor_site_id
AND    ((mfg_xvsa.start_date_active <= trunc(sysdate)) AND (mfg_xvsa.end_date_active >= trunc(sysdate)))
AND    mfg_pvsa.org_id         = FND_PROFILE.VALUE('XXCFO1_MFG_ORG_ID')
       --営業 仕入先の紐付け
AND    sa_pv.vendor_id         = sa_pvsa.vendor_id
AND    sa_pvsa.org_id          = FND_PROFILE.VALUE('ORG_ID')
       --営業と生産の紐付け
AND    mfg_pvsa.attribute5     = sa_pvsa.vendor_site_code
/
COMMENT ON TABLE  apps.xxcfo_vendor_mst_read_v IS '仕入先マスタ読み替えビュー'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_code IS '仕入先コード（生産）'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_name IS '仕入先名（生産）'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_site_id IS '仕入先サイトID（生産）'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_site_code IS '仕入先サイトコード（生産）'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_site_name IS '仕入先サイト名（生産）'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_vendor_code IS '仕入先コード（営業）'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_vendor_name IS '仕入先名（営業）'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_vendor_site_code IS '仕入先サイトコード（営業）'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_vendor_site_name IS '仕入先サイト名（営業）'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_accts_pay_ccid IS '負債勘定CCID（営業）'
/
