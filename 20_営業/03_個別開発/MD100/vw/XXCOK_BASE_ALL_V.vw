/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_BASE_ALL_V
 * Description : 拠点ビュー
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          新規作成
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_base_all_v
  ( base_code                                -- 拠点コード
  , base_name                                -- 拠点名称
  , management_base_code                     -- 管理元拠点コード
  )
AS
  SELECT hca.account_number             base_code                -- 顧客コード
       , hp.party_name                  base_name                -- 顧客名称
       , xca.management_base_code       management_base_code     -- 管理元拠点コード
  FROM   hz_cust_accounts      hca              -- 顧客マスタ
       , hz_parties            hp               -- パーティマスタ
       , xxcmm_cust_accounts  xca               -- 顧客追加情報
  WHERE  hca.party_id            = hp.party_id
  AND    hca.cust_account_id     = xca.customer_id
  AND    hca.customer_class_code = '1'          -- 拠点
/
COMMENT ON TABLE  apps.xxcok_base_all_v                       IS '拠点ビュー'
/
COMMENT ON COLUMN apps.xxcok_base_all_v.base_code             IS '拠点コード'
/
COMMENT ON COLUMN apps.xxcok_base_all_v.base_name             IS '拠点名称'
/
COMMENT ON COLUMN apps.xxcok_base_all_v.management_base_code  IS '管理元拠点コード'
/
