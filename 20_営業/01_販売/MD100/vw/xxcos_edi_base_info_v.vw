/***********************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : xxcos_edi_base_info_v
 * Description     : EDI拠点情報ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2011/12/15    1.0   T.Yoshimoto      新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_edi_base_info_v
AS
SELECT xeh.base_code      base_code                       -- 拠点コード
      ,hp.party_name      party_name                      -- 拠点名称
      ,xeh.edi_chain_code edi_chain_code                  -- EDIチェーン店コード
      ,xeh.process_date   process_date                    -- 処理日
      ,xeh.process_time   process_time                    -- 処理時刻
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
COMMENT ON  COLUMN  xxcos_edi_base_info_v.base_code       IS  '拠点コード'; 
COMMENT ON  COLUMN  xxcos_edi_base_info_v.party_name      IS  '拠点名称';
COMMENT ON  COLUMN  xxcos_edi_base_info_v.edi_chain_code  IS  'EDIチェーン店コード';
COMMENT ON  COLUMN  xxcos_edi_base_info_v.process_date    IS  '処理日';
COMMENT ON  COLUMN  xxcos_edi_base_info_v.process_time    IS  '処理時刻';
--
COMMENT ON  TABLE   xxcos_edi_base_info_v                 IS  'EDI拠点情報ビュー';
