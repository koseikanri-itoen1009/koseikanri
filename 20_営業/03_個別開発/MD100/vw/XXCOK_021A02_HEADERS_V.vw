/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_021A02_HEADERS_V
 * Description : 問屋請求見積書突き合わせ画面（ヘッダ）ビュー
 * Version     : 1.3
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          新規作成
 *  2009/02/02    1.1   K.Yamaguchi      [障害COK_004] 抽出条件に営業単位を追加
 *                                       [障害COK_004] 抽出条件に仕入先サイトマスタの無効日を追加
 *  2010/02/23    1.2   K.Yamaguchi      [E_本稼動_01176] 口座種別の取得元変更
 *  2012/03/08    1.3   S.Niki           [E_本稼動_08315] ヘッダに売上対象年月を追加
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_021a02_headers_v(
  row_id
, wholesale_bill_header_id
, base_code
, base_name
, cust_code
, cust_name
, wholesale_ctrl_code
, wholesale_ctrl_name
, expect_payment_date
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki ADD START
, selling_month
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki ADD END
, supplier_code
, supplier_name
, bank_name
, bank_branch_name
, bank_account_type_name
, bank_account_num
, management_base_code
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
)
AS
SELECT xwbh.ROWID                       AS row_id                     -- ROW_ID
     , xwbh.wholesale_bill_header_id    AS wholesale_bill_header_id   -- 問屋請求書ヘッダID
     , xwbh.base_code                   AS base_code                  -- 拠点コード
     , hp1.party_name                   AS base_name                  -- 拠点名
     , xwbh.cust_code                   AS cust_code                  -- 顧客コード
     , hp2.party_name                   AS cust_name                  -- 顧客名
     , xca2.wholesale_ctrl_code         AS wholesale_ctrl_code        -- 問屋管理コード
     , flv.meaning                      AS wholesale_ctrl_name        -- 問屋管理名
     , xwbh.expect_payment_date         AS expect_payment_date        -- 支払予定日
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki ADD START
     , line.selling_month               AS selling_month              -- 売上対象年月
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki ADD END
     , xwbh.supplier_code               AS supplier_code              -- 仕入先コード
     , pv.vendor_name                   AS supplier_name              -- 仕入先名
     , abb.bank_name                    AS bank_name                  -- 振込銀行名
     , abb.bank_branch_name             AS bank_branch_name           -- 支店名
     , hl.meaning                       AS bank_account_type_name     -- 種別
     , abaa.bank_account_num            AS bank_account_num           -- 口座番号
     , xca1.management_base_code        AS management_base_code       -- 管理元拠点コード
     , xwbh.created_by                  AS created_by                 -- 作成者
     , xwbh.creation_date               AS creation_date              -- 作成日
     , xwbh.last_updated_by             AS last_updated_by            -- 最終更新者
     , xwbh.last_update_date            AS last_update_date           -- 最終更新日
     , xwbh.last_update_login           AS last_update_login          -- 最終更新ログイン
FROM xxcok_wholesale_bill_head     xwbh      -- 問屋請求書ヘッダテーブル
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki ADD START
   , ( SELECT xwbl.wholesale_bill_header_id      AS wholesale_bill_header_id  -- 問屋請求書ヘッダID
            , xwbl.selling_month                 AS selling_month             -- 売上対象年月
       FROM   xxcok_wholesale_bill_line  xwbl  -- 問屋請求書明細テーブル
       GROUP BY xwbl.wholesale_bill_header_id
              , xwbl.selling_month
     )                             line      -- 問屋請求書明細テーブル
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki ADD END
   , hz_cust_accounts              hca1      -- 顧客マスタ（拠点）
   , hz_cust_accounts              hca2      -- 顧客マスタ（顧客）
   , hz_parties                    hp1       -- パーティマスタ（拠点）
   , hz_parties                    hp2       -- パーティマスタ（顧客）
   , xxcmm_cust_accounts           xca2      -- 顧客追加情報（顧客）
   , xxcmm_cust_accounts           xca1      -- 顧客追加情報（拠点）
   , fnd_lookup_values             flv       -- クイックコード（問屋管理コード）
   , po_vendors                    pv        -- 仕入先マスタ
   , po_vendor_sites_all           pvsa      -- 仕入先サイトマスタ
   , ap_bank_account_uses_all      abaua     -- 銀行口座使用情報
   , ap_bank_accounts_all          abaa      -- 銀行口座マスタ
   , ap_bank_branches              abb       -- 銀行支店マスタ
   , hr_lookups                    hl        -- クイックコード（口座種別）
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki MOD START
--WHERE xwbh.base_code                    = hca1.account_number
WHERE line.wholesale_bill_header_id     = xwbh.wholesale_bill_header_id
  AND xwbh.base_code                    = hca1.account_number
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki MOD END
  AND xwbh.cust_code                    = hca2.account_number
  AND hca1.party_id                     = hp1.party_id
  AND hca2.party_id                     = hp2.party_id
  AND hca1.cust_account_id              = xca1.customer_id
  AND hca2.cust_account_id              = xca2.customer_id
  AND xca2.wholesale_ctrl_code          = flv.lookup_code
  AND flv.lookup_type                   = 'XXCMM_TONYA_CODE'
  AND flv.language                      = USERENV( 'LANG' )
  AND xwbh.supplier_code                = pv.segment1
  AND pv.vendor_id                      = pvsa.vendor_id
  AND pvsa.vendor_id                    = abaua.vendor_id
  AND pvsa.vendor_site_id               = abaua.vendor_site_id
  AND abaua.external_bank_account_id    = abaa.bank_account_id
  AND abaa.bank_branch_id               = abb.bank_branch_id
  AND abaa.bank_account_type            = hl.lookup_code
  AND abaua.primary_flag                = 'Y'
  AND ( abaua.start_date <= xxccp_common_pkg2.get_process_date OR abaua.start_date IS NULL )
  AND ( abaua.end_date   >= xxccp_common_pkg2.get_process_date OR abaua.end_date   IS NULL )
-- 2010/02/23 Ver.1.2 [E_本稼動_01176] SCS K.Yamaguchi REPAIR START
--  AND hl.lookup_type                    = 'JP_BANK_ACCOUNT_TYPE'
  AND hl.lookup_type                    = 'XXCSO1_KOZA_TYPE'
-- 2010/02/23 Ver.1.2 [E_本稼動_01176] SCS K.Yamaguchi REPAIR END
  AND pvsa.org_id                       = abaua.org_id
  AND pvsa.org_id                       = abaa.org_id
  AND pvsa.org_id                       = TO_NUMBER( FND_PROFILE.VALUE( 'ORG_ID' ) )
  AND ( pvsa.inactive_date > xxccp_common_pkg2.get_process_date OR pvsa.inactive_date IS NULL )
/
COMMENT ON TABLE  apps.xxcok_021a02_headers_v                              IS '問屋請求見積書突き合わせ画面（ヘッダ）ビュー'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.row_id                       IS 'ROW_ID'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.wholesale_bill_header_id     IS '問屋請求書ヘッダID'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.base_code                    IS '拠点コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.base_name                    IS '拠点名'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.cust_code                    IS '顧客コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.cust_name                    IS '顧客名'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.wholesale_ctrl_code          IS '問屋管理コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.wholesale_ctrl_name          IS '問屋管理名'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.expect_payment_date          IS '支払予定日'
/
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki ADD START
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.selling_month                IS '売上対象年月'
/
-- 2012/03/08 Ver.1.3 [障害E_本稼動_08315] SCSK S.Niki ADD END
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.supplier_code                IS '仕入先コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.supplier_name                IS '仕入先名'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.bank_name                    IS '振込銀行名'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.bank_branch_name             IS '支店名'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.bank_account_type_name       IS '種別'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.bank_account_num             IS '口座番号'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.management_base_code         IS '管理元拠点コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.created_by                   IS '作成者'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.creation_date                IS '作成日'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.last_updated_by              IS '最終更新者'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.last_update_date             IS '最終更新日'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.last_update_login            IS '最終更新ログイン'
/
