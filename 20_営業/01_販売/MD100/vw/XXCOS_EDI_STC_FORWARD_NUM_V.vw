/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_stc_forward_num_v
 * Description     : EDI�`���ǔԃr���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/04/10    1.0   K.Kiriu         �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_edi_stc_forward_num_v(
   edi_forward_number     -- EDI�`���ǔ�
  ,ship_storage_code      -- �o�׌��ۊǏꏊ
  ,edi_chain_code         -- EDI�`�F�[���X�R�[�h
)
AS
SELECT DISTINCT
       flvv.attribute3        edi_forward_number  -- EDI�`���ǔ�
      ,xca.ship_storage_code  ship_storage_code   -- �o�׌��ۊǏꏊ
      ,flvv.attribute1        edi_chain_code      -- EDI�`�F�[���X�R�[�h
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
COMMENT ON  COLUMN  xxcos_edi_stc_forward_num_v.edi_forward_number  IS 'EDI�`���ǔ�';
COMMENT ON  COLUMN  xxcos_edi_stc_forward_num_v.ship_storage_code   IS '�o�׌��ۊǏꏊ';
COMMENT ON  COLUMN  xxcos_edi_stc_forward_num_v.edi_chain_code      IS 'EDI�`�F�[���X�R�[�h';
--
COMMENT ON  TABLE   xxcos_edi_stc_forward_num_v                     IS 'EDI�`���ǔԃr���[';
