/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_BASE_CODE_V
 * Description     : 計画_担当拠点ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-12-09    1.0   SCS.Tsubomatsu  新規作成
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOP_BASE_CODE_V
  ( "BASE_CODE"     -- 拠点コード
  , "BASE_NAME"     -- 拠点名称
  )
AS
  SELECT hca.account_number   AS base_code  -- 拠点コード
        ,xp.party_short_name  AS base_name  -- 拠点名称
  FROM   hz_cust_accounts hca   -- 顧客マスタ
        ,xxcmn_parties xp       -- パーティアドオンマスタ
  WHERE  hca.customer_class_code = '1'
  AND    hca.party_id = xp.party_id (+)
  AND (( hca.account_number = xxcop_common_pkg.get_charge_base_code( FND_GLOBAL.USER_ID, SYSDATE ) )
  OR   ( hca.cust_account_id IN (
           SELECT xca.customer_id           -- 顧客ID
           FROM   xxcmm_cust_accounts xca   -- 顧客追加情報
           WHERE  xca.management_base_code = xxcop_common_pkg.get_charge_base_code( FND_GLOBAL.USER_ID, SYSDATE ) )
       ))
--  AND    NVL( TO_DATE( hca.attribute3, 'yyyy/mm/dd' ), SYSDATE ) <= SYSDATE
  AND    xp.start_date_active(+) <= TRUNC( SYSDATE )
  AND    xp.end_date_active  (+) >= TRUNC( SYSDATE )
  ORDER BY DECODE( hca.account_number, xxcop_common_pkg.get_charge_base_code( FND_GLOBAL.USER_ID, SYSDATE ), 0, 1 )
          ,hca.account_number
  ;
--
COMMENT ON TABLE XXCOP_BASE_CODE_V IS '計画_担当拠点ビュー'
/
--
COMMENT ON COLUMN XXCOP_BASE_CODE_V.base_code IS '拠点コード'
/
COMMENT ON COLUMN XXCOP_BASE_CODE_V.base_name IS '拠点名称'
/
