/*************************************************************************
 * 
 * View  Name      : XXSKZ_特販受注明細_基本_V
 * Description     : XXSKZ_特販受注明細_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_特販受注明細_基本_V
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
-- 2009/12/25 T.Yoshimoto Mod Start
--      , xhkv.品目名                               品目摘要
      ,(select xhkv.品目名
        from XXSKZ_品目マスタ_基本_V   xhkv
        where xhkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.適用開始日
                            AND xhkv.適用終了日
       ) 品目摘要
-- 2009/12/25 T.Yoshimoto Mod End
      , oola.order_quantity_uom                   単位
      , oola.ordered_quantity                     数量
      , oola.attribute8                           "時間指定（From）"
      , oola.attribute9                           "時間指定（To）"
      , oola.attribute7                           備考
      , oola.attribute4                           検収予定日
      , oola.attribute6                           子コード
-- 2009/12/25 T.Yoshimoto Mod Start
--      , xhkv.ケース入数                           入数
--      , xhwkv.商品区分                            商品区分
--      , xhwkv.商品区分名                          商品区分名
--      , xhwkv.本社商品区分                        本社商品区分
--      , xhwkv.本社商品区分名                      本社商品区分名
--      , xhwkv.品目区分                            品目区分
--      , xhwkv.品目区分名                          品目区分名
      ,(select xhkv.ケース入数
        from xxskz_品目マスタ_基本_v   xhkv
        where xhkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.適用開始日
                            AND xhkv.適用終了日
       ) 入数
      ,(select xhwkv.商品区分
        from xxskz_品目カテゴリ割当_基本_v   xhwkv
        where xhwkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.適用開始日
                            AND xhwkv.適用終了日
       ) 商品区分
      ,(select xhwkv.商品区分名
        from xxskz_品目カテゴリ割当_基本_v   xhwkv
        where xhwkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.適用開始日
                            AND xhwkv.適用終了日
       ) 商品区分名
      ,(select xhwkv.本社商品区分
        from xxskz_品目カテゴリ割当_基本_v   xhwkv
        where xhwkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.適用開始日
                            AND xhwkv.適用終了日
       ) 本社商品区分
      ,(select xhwkv.本社商品区分名
        from xxskz_品目カテゴリ割当_基本_v   xhwkv
        where xhwkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.適用開始日
                            AND xhwkv.適用終了日
       ) 本社商品区分名
      ,(select xhwkv.品目区分
        from xxskz_品目カテゴリ割当_基本_v   xhwkv
        where xhwkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.適用開始日
                            AND xhwkv.適用終了日
       ) 品目区分
      ,(select xhwkv.品目区分名
        from xxskz_品目カテゴリ割当_基本_v   xhwkv
        where xhwkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhwkv.適用開始日
                            AND xhwkv.適用終了日
       ) 品目区分名
--      , xhkv.商品種別                             商品種別
--      , xhkv.商品種別名                           商品種別名
--      , xhkv.重量容積区分                         重量容積区分
--      , xhkv.重量容積区分名                       重量容積区分名
--      , xhkv.重量                                 重量
--      , xhkv.容積                                 容積
      ,(select xhkv.商品種別
        from xxskz_品目マスタ_基本_v   xhkv
        where xhkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.適用開始日
                            AND xhkv.適用終了日
       ) 商品種別
      ,(select xhkv.商品種別名
        from xxskz_品目マスタ_基本_v   xhkv
        where xhkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.適用開始日
                            AND xhkv.適用終了日
       ) 商品種別名
      ,(select xhkv.重量容積区分
        from xxskz_品目マスタ_基本_v   xhkv
        where xhkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.適用開始日
                            AND xhkv.適用終了日
       ) 重量容積区分
      ,(select xhkv.重量容積区分名
        from xxskz_品目マスタ_基本_v   xhkv
        where xhkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.適用開始日
                            AND xhkv.適用終了日
       ) 重量容積区分名
      ,(select xhkv.重量
        from xxskz_品目マスタ_基本_v   xhkv
        where xhkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.適用開始日
                            AND xhkv.適用終了日
       ) 重量
      ,(select xhkv.容積
        from xxskz_品目マスタ_基本_v   xhkv
        where xhkv.品目コード = oola.ordered_item
        AND   oola.request_date BETWEEN xhkv.適用開始日
                            AND xhkv.適用終了日
       ) 容積
-- 2009/12/25 T.Yoshimoto Mod End
FROM
        oe_order_headers_all            ooha  --受注ヘッダテーブル
      , oe_order_lines_all              oola  --受注明細テーブル
      , mtl_secondary_inventories       msi
-- 2009/12/25 T.Yoshimoto Del Start
--      , xxsky_品目マスタ_基本_v         xhkv
--      , xxsky_品目カテゴリ割当_基本_v   xhwkv
-- 2009/12/25 T.Yoshimoto Del End
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
-- 2009/12/25 T.Yoshimoto Del Start
--AND   oola.ordered_item = xhkv.品目コード
--AND   ooha.request_date BETWEEN xhkv.適用開始日
--                            AND xhkv.適用終了日
--AND   oola.ordered_item = xhwkv.品目コード
--AND   ooha.request_date BETWEEN xhwkv.適用開始日
--                            AND xhwkv.適用終了日
-- 2009/12/25 T.Yoshimoto Del End
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
/
COMMENT ON TABLE APPS.XXSKZ_特販受注明細_基本_V IS 'SKYLINK用 特販受注明細(基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.明細タイプ IS '明細タイプ'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.明細 IS '明細'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.依頼No IS '依頼No'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.保管場所コード IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.保管場所 IS '保管場所'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.受注番号 IS '受注番号'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.出荷予定日 IS '出荷予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.納品予定日 IS '納品予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.受注品目 IS '受注品目'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.品目摘要 IS '品目摘要'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.単位 IS '単位'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.数量 IS '数量'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V."時間指定（From）" IS '時間指定（From）'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V."時間指定（To）" IS '時間指定（To）'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.備考 IS '備考'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.検収予定日 IS '検収予定日'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.子コード IS '子コード'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.入数 IS '人数'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.商品区分 IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.商品区分名 IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.本社商品区分 IS '本社商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.本社商品区分名 IS '本社商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.品目区分 IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.品目区分名 IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.商品種別 IS '商品種別'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.商品種別名 IS '商品種別名'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.重量容積区分 IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.重量容積区分名 IS '重量容積区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.重量 IS '重量'
/
COMMENT ON COLUMN APPS.XXSKZ_特販受注明細_基本_V.容積 IS '容積'
/

