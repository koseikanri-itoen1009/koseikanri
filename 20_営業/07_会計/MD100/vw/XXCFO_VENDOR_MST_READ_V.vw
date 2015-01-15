/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name   : XXCFO_VENDOR_MST_READ_V
 * Description : �d����}�X�^�ǂݑւ��r���[
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014-09-19    1.0   K.Kubo           �V�K�쐬
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
SELECT  mfg_pv.segment1                           AS mfg_vendor_code         -- �d����R�[�h�i���Y�j
       ,mfg_xv.vendor_name                        AS mfg_vendor_name         -- �d���於�i���Y�j
       ,mfg_pvsa.vendor_site_id                   AS mfg_vendor_site_id      -- �d����T�C�gID�i���Y�j
       ,mfg_pvsa.vendor_site_code                 AS mfg_vendor_site_code    -- �d����T�C�g�R�[�h�i���Y�j
       ,mfg_xvsa.vendor_site_name                 AS mfg_vendor_site_name    -- �d����T�C�g���i���Y�j
       ,sa_pv.segment1                            AS sales_vendor_code       -- �d����R�[�h�i�c�Ɓj
       ,sa_pv.vendor_name                         AS sales_vendor_name       -- �d���於�i�c�Ɓj
       ,sa_pvsa.vendor_site_code                  AS sales_vendor_site_code  -- �d����T�C�g�R�[�h�i�c�Ɓj
       ,sa_pvsa.attribute1                        AS sales_vendor_site_name  -- �d����T�C�g���i�c�Ɓj
       ,sa_pvsa.accts_pay_code_combination_id     AS sales_accts_pay_ccid    -- ������CCID�i�c�Ɓj
FROM    po_vendors                mfg_pv          -- �d����}�X�^�i���Y�j
       ,po_vendor_sites_all       mfg_pvsa        -- �d����T�C�g�}�X�^�i���Y�j
       ,xxcmn_vendors             mfg_xv          -- �d����A�h�I���}�X�^�i���Y�j
       ,xxcmn_vendor_sites_all    mfg_xvsa        -- �d����T�C�g�A�h�I���}�X�^�i���Y�j
       ,po_vendors                sa_pv           -- �d����}�X�^�i�c�Ɓj
       ,po_vendor_sites_all       sa_pvsa         -- �d����T�C�g�}�X�^�i�c�Ɓj
WHERE  
       --���Y �d����̕R�t��
       mfg_pv.vendor_id        = mfg_pvsa.vendor_id
AND    mfg_pv.vendor_id        = mfg_xv.vendor_id
AND    ((mfg_xv.start_date_active <= trunc(sysdate)) AND (mfg_xv.end_date_active >= trunc(sysdate)))
AND    mfg_pvsa.vendor_site_id = mfg_xvsa.vendor_site_id
AND    ((mfg_xvsa.start_date_active <= trunc(sysdate)) AND (mfg_xvsa.end_date_active >= trunc(sysdate)))
AND    mfg_pvsa.org_id         = FND_PROFILE.VALUE('XXCFO1_MFG_ORG_ID')
       --�c�� �d����̕R�t��
AND    sa_pv.vendor_id         = sa_pvsa.vendor_id
AND    sa_pvsa.org_id          = FND_PROFILE.VALUE('ORG_ID')
       --�c�ƂƐ��Y�̕R�t��
AND    mfg_pvsa.attribute5     = sa_pvsa.vendor_site_code
/
COMMENT ON TABLE  apps.xxcfo_vendor_mst_read_v IS '�d����}�X�^�ǂݑւ��r���['
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_code IS '�d����R�[�h�i���Y�j'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_name IS '�d���於�i���Y�j'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_site_id IS '�d����T�C�gID�i���Y�j'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_site_code IS '�d����T�C�g�R�[�h�i���Y�j'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.mfg_vendor_site_name IS '�d����T�C�g���i���Y�j'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_vendor_code IS '�d����R�[�h�i�c�Ɓj'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_vendor_name IS '�d���於�i�c�Ɓj'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_vendor_site_code IS '�d����T�C�g�R�[�h�i�c�Ɓj'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_vendor_site_name IS '�d����T�C�g���i�c�Ɓj'
/
COMMENT ON COLUMN apps.xxcfo_vendor_mst_read_v.sales_accts_pay_ccid IS '������CCID�i�c�Ɓj'
/
