/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_stc_forward_num_v
 * Description     : EDI伝送追番ビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/04/10    1.0   K.Kiriu         新規作成
 *  2010/03/09    1.1   M.Sano          [E_本稼動_01707]EDI伝送名称追加
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_edi_stc_forward_num_v(
   edi_forward_number     -- EDI伝送追番
/* 2010/03/09 Ver.1.1 Add Start */
  ,edi_forward_name       -- EDI伝送名称
/* 2010/03/09 Ver.1.1 Add End   */
  ,ship_storage_code      -- 出荷元保管場所
  ,edi_chain_code         -- EDIチェーン店コード
)
AS
SELECT DISTINCT
       flvv.attribute3        edi_forward_number  -- EDI伝送追番
/* 2010/03/09 Ver.1.1 Add Start */
      ,flvv.meaning           edi_forward_name    -- EDI伝送名称
/* 2010/03/09 Ver.1.1 Add End   */
      ,xca.ship_storage_code  ship_storage_code   -- 出荷元保管場所
      ,flvv.attribute1        edi_chain_code      -- EDIチェーン店コード
FROM   fnd_lookup_values_vl flvv
      ,xxcmm_cust_accounts  xca
WHERE  flvv.lookup_type    = 'XXCOS1_EDI_CONTROL_LIST'
AND    flvv.enabled_flag   = 'Y'
AND    (
         ( flvv.start_date_active IS NULL )
         OR
         ( flvv.start_date_active <= TRUNC(SYSDATE) )
       )
AND    (
         ( flvv.end_date_active IS NULL )
         OR
         ( flvv.end_date_active >= TRUNC(SYSDATE) )
       )
AND    flvv.attribute1       = xca.chain_store_code
AND    flvv.attribute3       = xca.edi_forward_number
;
COMMENT ON  COLUMN  xxcos_edi_stc_forward_num_v.edi_forward_number  IS 'EDI伝送追番';
/* 2010/03/09 Ver.1.1 Add Start */
COMMENT ON  COLUMN  xxcos_edi_stc_forward_num_v.edi_forward_name    IS 'EDI伝送名称';
/* 2010/03/09 Ver.1.1 Add End   */
COMMENT ON  COLUMN  xxcos_edi_stc_forward_num_v.ship_storage_code   IS '出荷元保管場所';
COMMENT ON  COLUMN  xxcos_edi_stc_forward_num_v.edi_chain_code      IS 'EDIチェーン店コード';
--
COMMENT ON  TABLE   xxcos_edi_stc_forward_num_v                     IS 'EDI伝送追番ビュー';
