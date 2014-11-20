/***********************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : xxcos_edi_base_info_v
 * Description     : EDI���_���r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2011/12/15    1.0   T.Yoshimoto      �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_edi_base_info_v
AS
SELECT xeh.base_code      base_code                       -- ���_�R�[�h
      ,hp.party_name      party_name                      -- ���_����
      ,xeh.edi_chain_code edi_chain_code                  -- EDI�`�F�[���X�R�[�h
      ,xeh.process_date   process_date                    -- ������
      ,xeh.process_time   process_time                    -- ��������
FROM xxcos_edi_headers xeh
    ,hz_cust_accounts hca
    ,hz_parties hp
WHERE xeh.edi_delivery_schedule_flag = 'Y'
AND   hca.account_number             = xeh.base_code
AND   hca.party_id                   = hp.party_id
GROUP BY xeh.base_code
        ,hp.party_name
        ,xeh.edi_chain_code
        ,xeh.process_date
        ,xeh.process_time
;
COMMENT ON  COLUMN  xxcos_edi_base_info_v.base_code       IS  '���_�R�[�h'; 
COMMENT ON  COLUMN  xxcos_edi_base_info_v.party_name      IS  '���_����';
COMMENT ON  COLUMN  xxcos_edi_base_info_v.edi_chain_code  IS  'EDI�`�F�[���X�R�[�h';
COMMENT ON  COLUMN  xxcos_edi_base_info_v.process_date    IS  '������';
COMMENT ON  COLUMN  xxcos_edi_base_info_v.process_time    IS  '��������';
--
COMMENT ON  TABLE   xxcos_edi_base_info_v                 IS  'EDI���_���r���[';
