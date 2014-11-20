/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_BASE_V
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
CREATE OR REPLACE VIEW apps.xxcok_base_v
  ( base_code                                -- 拠点コード
  , base_name                                -- 拠点名称
  )
AS
  SELECT hca.account_number   base_code         -- 顧客コード
       , hp.party_name        base_name         -- 顧客名称
  FROM   hz_cust_accounts      hca              -- 顧客マスタ
       , hz_parties            hp               -- パーティマスタ
  WHERE  hca.party_id            = hp.party_id
  AND    hca.customer_class_code = '1'          -- 拠点
  AND    hp.duns_number_c       <> '90'
/
COMMENT ON TABLE  apps.xxcok_base_v                       IS '拠点ビュー'
/
COMMENT ON COLUMN apps.xxcok_base_v.base_code             IS '拠点コード'
/
COMMENT ON COLUMN apps.xxcok_base_v.base_name             IS '拠点名称'
/
