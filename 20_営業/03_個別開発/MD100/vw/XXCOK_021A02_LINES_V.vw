/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_021A02_LINES_V
 * Description : 問屋請求見積書突き合わせ画面（明細）ビュー
 * Version     : 1.5
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          新規作成
 *  2009/03/12    1.1   K.Yamaguchi      [障害T1_0014]項目追加
 *  2009/04/21    1.2   K.Yamaguchi      [障害T1_0531]支払単価が０の場合、
 *                                                    見積書の検索を行わない
 *  2009/09/01    1.3   S.Moriyama       [障害0001230]OPM品目マスタ取得条件追加
 *  2009/09/11    1.4   K.Yamaguchi      [障害0001353]障害0001230からの障害対応
 *  2012/07/05    1.5   T.Osawa          [E_本稼動_08317] 問屋請求書明細テーブルに抽出条件を追加
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_021a02_lines_v(
  row_id
, wholesale_bill_detail_id
, wholesale_bill_header_id
, supplier_code
, expect_payment_date
, selling_month
, base_code
, bill_no
, cust_code
, sales_outlets_code
, sales_outlets_name
, item_code_dsp
, item_name_dsp
, acct_code
, sub_acct_code
, demand_unit_type
, demand_qty
, demand_unit_price
, payment_qty
, payment_unit_price
, revise_flag
, status
, status_func
, payment_creation_date
, item_code
, gyotai_chu
, vessel_group
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
)
AS
SELECT xwbl.ROWID                       AS row_id
     , xwbl.wholesale_bill_detail_id    AS wholesale_bill_detail_id   -- 問屋請求書明細ID
     , xwbl.wholesale_bill_header_id    AS wholesale_bill_header_id   -- 問屋請求書ヘッダID
     , xwbh.supplier_code               AS supplier_code              -- 仕入先コード
     , xwbh.expect_payment_date         AS expect_payment_date        -- 支払予定日
     , xwbl.selling_month               AS selling_month              -- 売上対象年月
     , xwbh.base_code                   AS base_code                  -- 拠点コード
     , xwbl.bill_no                     AS bill_no                    -- 請求書No.
     , xwbh.cust_code                   AS cust_code                  -- 顧客コード
     , xwbl.sales_outlets_code          AS sales_outlets_code         -- 問屋帳合先コード
     , hp.party_name                    AS sales_outlets_name         -- 問屋帳合先名
     , NVL( xwbl.item_code
          , xwbl.acct_code || '-' || xwbl.sub_acct_code )
                                        AS item_code_dsp              -- 品名コード
     , CASE
       WHEN xwbl.item_code IS NOT NULL THEN
         item.item_short_name
       ELSE
         acct.acct_name
       END                              AS item_name_dsp              -- 品名
     , xwbl.acct_code                   AS acct_code                  -- 勘定科目コード
     , xwbl.sub_acct_code               AS sub_acct_code              -- 補助科目コード
     , xwbl.demand_unit_type            AS demand_unit_type           -- 請求単位
     , xwbl.demand_qty                  AS demand_qty                 -- 請求数量
     , xwbl.demand_unit_price           AS demand_unit_price          -- 請求単価
     , xwbl.payment_qty                 AS payment_qty                -- 支払数量
     , xwbl.payment_unit_price          AS payment_unit_price         -- 支払単価
     , xwbl.revise_flag                 AS revise_flag                -- 業管訂正フラグ
     , xwbl.status                      AS status                     -- ステータスコード
-- 2009/04/21 Ver.1.2 [障害T1_0531] SCS K.Yamaguchi REPAIR START
--     , xxcok_common_pkg.get_wholesale_req_est_type_f(
--         xca.wholesale_ctrl_code    -- 問屋管理コード
--       , xwbl.sales_outlets_code    -- 問屋帳合先コード
--       , xwbl.item_code             -- 品目コード
--       , xwbl.payment_unit_price    -- 請求単価
--       , xwbl.demand_unit_type      -- 請求単位
--       , xwbl.selling_month         -- 売上対象年月
--       )                                AS status_func                -- 関数戻り値（ステータス）
     , CASE
       WHEN xwbl.payment_unit_price <> 0 THEN
         xxcok_common_pkg.get_wholesale_req_est_type_f(
           xca.wholesale_ctrl_code    -- 問屋管理コード
         , xwbl.sales_outlets_code    -- 問屋帳合先コード
         , xwbl.item_code             -- 品目コード
         , xwbl.payment_unit_price    -- 請求単価
         , xwbl.demand_unit_type      -- 請求単位
         , xwbl.selling_month         -- 売上対象年月
         )
       END                              AS status_func                -- 関数戻り値（ステータス）
-- 2009/04/21 Ver.1.2 [障害T1_0531] SCS K.Yamaguchi REPAIR END
     , xwbl.payment_creation_date       AS payment_creation_date      -- 支払データ作成年月日
     , xwbl.item_code                   AS item_code                  -- 品目コード（実）
     , flv.attribute1                   AS gyotai_chu                 -- 中分類
     , item.vessel_group                AS vessel_group               -- 容器群コード
     , xwbl.created_by                  AS created_by                 -- 作成者
     , xwbl.creation_date               AS creation_date              -- 作成日
     , xwbl.last_updated_by             AS last_updated_by            -- 最終更新者
     , xwbl.last_update_date            AS last_update_date           -- 最終更新日
     , xwbl.last_update_login           AS last_update_login          -- 最終更新ログイン
FROM xxcok_wholesale_bill_line     xwbl      -- 問屋請求書明細テーブル
   , xxcok_wholesale_bill_head     xwbh      -- 問屋請求書ヘッダテーブル
   , xxcmm_cust_accounts           xca       -- 顧客追加情報（顧客）
   , hz_cust_accounts              hca2      -- 顧客マスタ（顧客）
   , hz_cust_accounts              hca       -- 顧客マスタ（問屋帳合先）
   , hz_parties                    hp        -- パーティマスタ（問屋帳合先）
   , fnd_lookup_values             flv       -- クイックコード（業態小分類）
   , ( SELECT iimb.item_no              AS item_no             -- 品名コード
            , ximb.item_short_name      AS item_short_name     -- 略称
            , xsib.vessel_group         AS vessel_group        -- 容器群
-- 2009/09/01 Ver.1.3 [障害0001230] SCS S.Moriyama ADD START
            , ximb.start_date_active    AS start_date_active   -- 適用開始日
            , ximb.end_date_active      AS end_date_active     -- 適用終了日
-- 2009/09/01 Ver.1.3 [障害0001230] SCS S.Moriyama ADD END
       FROM mtl_parameters         mp
          , mtl_system_items_b     msib
          , xxcmm_system_items_b   xsib
          , ic_item_mst_b          iimb
          , xxcmn_item_mst_b       ximb
       WHERE mp.organization_id     = msib.organization_id
         AND msib.segment1          = xsib.item_code
         AND msib.segment1          = iimb.item_no
         AND xsib.item_id           = iimb.item_id
         AND iimb.item_id           = ximb.item_id
         AND mp.organization_code   = FND_PROFILE.VALUE( 'XXCOK1_ORG_CODE_SALES' )
     )                             item      -- 品目マスタ
   , ( SELECT ffv1.flex_value                AS acct_code           -- 勘定科目コード
            , ffv2.flex_value                AS sub_acct_code       -- 補助科目コード
            ,           ffvt1.description
              || '-' || ffvt2.description    AS acct_name           -- 勘定科目名-補助科目名
       FROM fnd_flex_value_sets    ffvs1
          , fnd_flex_values        ffv1
          , fnd_flex_values_tl     ffvt1
          , fnd_flex_value_sets    ffvs2
          , fnd_flex_values        ffv2
          , fnd_flex_values_tl     ffvt2
       WHERE ffvs1.flex_value_set_id         = ffv1.flex_value_set_id
         AND ffv1.flex_value_id              = ffvt1.flex_value_id
         AND ffvt1.language                  = USERENV( 'LANG' )
         AND ffvs1.flex_value_set_name       = 'XX03_ACCOUNT'
         AND ffvs2.flex_value_set_id         = ffv2.flex_value_set_id
         AND ffv2.flex_value_id              = ffvt2.flex_value_id
         AND ffvt2.language                  = USERENV( 'LANG' )
         AND ffvs2.flex_value_set_name       = 'XX03_SUB_ACCOUNT'
         AND ffv2.parent_flex_value_low      = ffv1.flex_value
     )                             acct      -- AFF勘定科目
WHERE xwbl.wholesale_bill_header_id     = xwbh.wholesale_bill_header_id
  AND xwbh.cust_code                    = hca2.account_number
  AND hca2.cust_account_id              = xca.customer_id
  AND xwbl.sales_outlets_code           = hca.account_number
  AND hca.party_id                      = hp.party_id
  AND xwbl.item_code                    = item.item_no(+)
  AND xwbl.acct_code                    = acct.acct_code(+)
  AND xwbl.sub_acct_code                = acct.sub_acct_code(+)
-- 2012/07/05 Ver.1.5 [障害E_本稼動_08317] SCSK T.Osawa ADD START
  AND (
      xwbl.status                       IS NULL
   OR xwbl.status                       <> 'D')
-- 2012/07/05 Ver.1.5 [障害E_本稼動_08317] SCSK T.Osawa ADD END
  AND flv.lookup_type                   = 'XXCMM_CUST_GYOTAI_SHO'
  AND flv.lookup_code                   = hca.customer_class_code
  AND flv.language                      = USERENV( 'LANG' )
-- 2009/09/11 Ver.1.4 [障害0001353] SCS K.Yamaguchi REPAIR START
---- 2009/09/01 Ver.1.3 [障害0001230] SCS S.Moriyama ADD START
--  AND xwbh.expect_payment_date BETWEEN item.start_date_active
--                                   AND NVL ( item.end_date_active , xwbh.expect_payment_date )
---- 2009/09/01 Ver.1.3 [障害0001230] SCS S.Moriyama ADD END
  AND xwbh.expect_payment_date BETWEEN NVL ( item.start_date_active, xwbh.expect_payment_date )
                                   AND NVL ( item.end_date_active  , xwbh.expect_payment_date )
-- 2009/09/11 Ver.1.4 [障害0001353] SCS K.Yamaguchi REPAIR END
/
COMMENT ON TABLE  apps.xxcok_021a02_lines_v                                IS '問屋請求見積書突き合わせ画面（明細）ビュー'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.row_id                         IS 'ROW_ID'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.wholesale_bill_detail_id       IS '問屋請求書明細ID'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.wholesale_bill_header_id       IS '問屋請求書ヘッダID'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.supplier_code                  IS '仕入先コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.expect_payment_date            IS '支払予定日'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.selling_month                  IS '売上対象年月'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.base_code                      IS '拠点コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.bill_no                        IS '請求書No.'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.cust_code                      IS '顧客コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.sales_outlets_code             IS '問屋帳合先コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.sales_outlets_name             IS '問屋帳合先名'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.item_code_dsp                  IS '品名コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.item_name_dsp                  IS '品名'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.acct_code                      IS '勘定科目コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.sub_acct_code                  IS '補助科目コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.demand_unit_type               IS '請求単位'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.demand_qty                     IS '請求数量'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.demand_unit_price              IS '請求単価'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.payment_qty                    IS '支払数量'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.payment_unit_price             IS '支払単価'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.revise_flag                    IS '業管訂正フラグ'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.status                         IS 'ステータスコード'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.status_func                    IS '関数戻り値（ステータス）'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.payment_creation_date          IS '支払データ作成年月日'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.item_code                      IS '品目コード（実）'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.gyotai_chu                     IS '中分類'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.vessel_group                   IS '容器群コード'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.created_by                     IS '作成者'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.creation_date                  IS '作成日'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.last_updated_by                IS '最終更新者'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.last_update_date               IS '最終更新日'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.last_update_login              IS '最終更新ログイン'
/
