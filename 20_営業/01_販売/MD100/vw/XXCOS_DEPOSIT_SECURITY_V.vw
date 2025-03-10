/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_deposit_security_v
 * Description     : 預り金VDチェーン店セキュリティview
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/03/06    1.0   K.Kumamoto       新規作成
 *  2009/09/03    1.1   M.Sano           障害番号0001227 対応
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_deposit_security_v (
  user_id
 ,user_name
 ,chain_code
 ,chain_name
)
AS
  SELECT DISTINCT
         store.user_id
        ,store.user_name
        ,xlvv.lookup_code chain_code
        ,xlvv.meaning chain_name
  FROM xxcos_deposit_store_security_v store
      ,xxcos_lookup_values_v xlvv
-- 2009/09/03 Ver1.1 Add Start
      ,( SELECT TRUNC( xpd.process_date ) process_date
         FROM   xxccp_process_dates xpd ) pd
-- 2009/09/03 Ver1.1 Add End
  WHERE xlvv.lookup_type = 'XXCOS1_DEPOSIT_VD_CHAIN_MST'
  AND   xlvv.lookup_code = store.chain_code
-- 2009/09/03 Ver1.1 Mod Start
--  AND   xxccp_common_pkg2.get_process_date
--    BETWEEN xlvv.start_date_active
--    AND     NVL(xlvv.end_date_active,xxccp_common_pkg2.get_process_date)
  AND   pd.process_date BETWEEN xlvv.start_date_active AND NVL(xlvv.end_date_active, pd.process_date)
-- 2009/09/03 Ver1.1 Mod End
;
COMMENT ON  COLUMN  xxcos_deposit_security_v.user_id          IS  'ユーザID';
COMMENT ON  COLUMN  xxcos_deposit_security_v.user_name        IS  'ユーザ名称';
COMMENT ON  COLUMN  xxcos_deposit_security_v.chain_code       IS  'チェーン店コード';
COMMENT ON  COLUMN  xxcos_deposit_security_v.chain_name       IS  'チェーン店名称';
--
COMMENT ON  TABLE   xxcos_deposit_security_v                  IS  '預り金VDチェーン店セキュリティビュー';
