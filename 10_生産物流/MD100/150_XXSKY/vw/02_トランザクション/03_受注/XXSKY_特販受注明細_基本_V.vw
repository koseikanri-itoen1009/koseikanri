CREATE OR REPLACE VIEW APPS.XXSKY_特販受注明細_基本_V
(
   明細タイプ
  ,明細
  ,依頼No
  ,保管場所コード
  ,保管場所
  ,受注番号
  ,出荷予定日
  ,納品予定日
  ,受注品目
  ,品目摘要
  ,単位
  ,数量
  ,"時間指定（From）"
  ,"時間指定（To）"
  ,備考
  ,検収予定日
  ,子コード
  ,入数
  -- ココからは案
  ,商品区分
  ,商品区分名
  ,本社商品区分
  ,本社商品区分名
  ,品目区分
  ,品目区分名
  ,商品種別
  ,商品種別名
  ,重量容積区分
  ,重量容積区分名
  ,重量
  ,容積
)
AS
SELECT 
        otttl.description                         明細タイプ
      , oola.line_number                          明細
      , oola.packing_instructions                 依頼No
      , oola.subinventory                         保管場所コード
      , msi.description                           保管場所
      , ooha.order_number                         受注番号
      , oola.schedule_ship_date                   出荷予定日
      , oola.request_date                         納品予定日
      , oola.ordered_item                         受注品目
      , xhkv.品目名                               品目摘要
      , oola.order_quantity_uom                   単位
      , oola.ordered_quantity                     数量
      , oola.attribute8                           "時間指定（From）"
      , oola.attribute9                           "時間指定（To）"
      , oola.attribute7                           備考
      , oola.attribute4                           検収予定日
      , oola.attribute6                           子コード
      , xhkv.ケース入数                           入数
      -- ココからは案
      , xhwkv.商品区分                            商品区分
      , xhwkv.商品区分名                          商品区分名
      , xhwkv.本社商品区分                        本社商品区分
      , xhwkv.本社商品区分名                      本社商品区分名
      , xhwkv.品目区分                            品目区分
      , xhwkv.品目区分名                          品目区分名
      , xhkv.商品種別                             商品種別
      , xhkv.商品種別名                           商品種別名
      , xhkv.重量容積区分                         重量容積区分
      , xhkv.重量容積区分名                       重量容積区分名
      , xhkv.重量                                 重量
      , xhkv.容積                                 容積
FROM
        oe_order_headers_all            ooha
      , oe_order_lines_all              oola
      , mtl_secondary_inventories       msi
      , xxsky_品目マスタ_基本_v         xhkv
      , xxsky_品目カテゴリ割当_基本_v   xhwkv
      -- 顧客情報
      , xxcmn_cust_accounts2_v          xca2v
      -- 明細タイプ
      , oe_transaction_types_tl         otttl   -- 受注明細摘要用取引タイプ
      -- 営業単位
      , hr_all_organization_units       haou
WHERE
      ooha.header_id      = oola.header_id
AND   ooha.request_date   = oola.request_date
AND   ooha.org_id         = oola.org_id
-- 保管場所
AND oola.subinventory     = msi.secondary_inventory_name
AND oola.ship_from_org_id = msi.organization_id
-- 品目マスタ
AND   oola.ordered_item = xhkv.品目コード
AND   ooha.request_date BETWEEN xhkv.適用開始日
                            AND xhkv.適用終了日
AND   oola.ordered_item = xhwkv.品目コード
AND   ooha.request_date BETWEEN xhwkv.適用開始日
                            AND xhwkv.適用終了日
-- 顧客情報
AND   ooha.sold_to_org_id       = xca2v.cust_account_id
AND   ooha.request_date BETWEEN xca2v.start_date_active
                            AND xca2v.end_date_active
-- 明細タイプ
AND   oola.line_type_id         = otttl.transaction_type_id
AND   otttl.language            = 'JA'
-- 拠点コード（特販部指定 クイックコード定義）
AND   EXISTS (
              SELECT 'x'
              FROM  xxcmn_lookup_values_v xkgv
              WHERE xkgv.lookup_type = 'XXCMN_SALE_SKYLINK_BRANCH'
              AND   xkgv.lookup_code = xca2v.sale_base_code
             )
-- 営業組織
AND   haou.type    = 'OU'
AND   haou.name    = 'SALES-OU'
-- 営業 組織ID
AND   ooha.org_id  = haou.organization_id
;

