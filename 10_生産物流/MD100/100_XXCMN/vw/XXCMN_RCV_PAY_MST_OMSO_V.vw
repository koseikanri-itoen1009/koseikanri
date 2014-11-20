/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_OMSO_V
 * Description     : 経理受払区分情報VIEW_受注関連
 * Version         : 1.7
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-04-14    1.0   Y.Ishikawa       新規作成
 *  2008-05-20    1.1   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_Vをやめ
 *                                       必要なテーブルのみの結合とする。
 *  2008-06-10    1.2   Y.Ishikawa       取引区分'見本出庫','廃却出庫' →
 *                                       '見本','廃却'へ変更
 *  2008-06-12    1.3   Y.Ishikawa       項目に取引区分名を追加
 *  2008-06-12    1.4   Y.Ishikawa       項目に仕入先IDを追加
 *  2008-06-13    1.5   Y.Ishikawa       着荷予定日を追加
 *  2008-06-13    1.6   Y.Ishikawa       カテゴリ取得部分でGROUP BYの利用をやめる
 *  2008-07-01    1.7   Y.Ishikawa       出荷支給区分によって受注ヘッダーの抽出条件
 *                                       が出荷実績か支給実績を判断するよう変更する
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCMN_RCV_PAY_MST_OMSO_V
    (NEW_DIV_ACCOUNT,DEALINGS_DIV,RCV_PAY_DIV,DOC_TYPE,SOURCE_DOCUMENT_CODE,TRANSACTION_TYPE,
     SHIPMENT_PROVISION_DIV,STOCK_ADJUSTMENT_DIV,SHIP_PROV_RCV_PAY_CATEGORY,ITEM_DIV_AHEAD,
     ITEM_DIV_ORIGIN,PROD_DIV_AHEAD,PROD_DIV_ORIGIN,ROUTING_CLASS,LINE_TYPE,HIT_IN_DIV,
     REASON_CODE,DOC_LINE,RESULT_POST,UNIT_PRICE,REQUEST_ITEM_CODE,ARRIVAL_DATE,
     DELIVER_TO_ID,ITEM_ID,ITEM_DIV,PROD_DIV,CROWD_CODE,ACNT_CROWD_CODE,DEALINGS_DIV_NAME,
     VENDOR_SITE_ID,SCHEDULE_ARRIVAL_DATE)
AS
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,xrpm.source_document_code       AS source_document_code       -- ソース文書
       ,xrpm.transaction_type           AS transaction_type           -- PO取引タイプ
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- 出荷支給区分
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- 在庫調整区分
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- 出荷支給受払カテゴリ
       ,xrpm.item_div_ahead             AS item_div_ahead             -- 品目区分（振替先）
       ,xrpm.item_div_origin            AS item_div_origin            -- 品目区分（振替元）
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- 商品区分（振替先）
       ,xrpm.prod_div_origin            AS prod_div_origin            -- 商品区分（振替元）
       ,xrpm.routing_class              AS routing_class              -- 工順区分
       ,xrpm.line_type                  AS line_type                  -- ラインタイプ
       ,xrpm.hit_in_div                 AS hit_in_div                 -- 打込区分
       ,xrpm.reason_code                AS reason_code                -- 事由コード
       ,wdd.delivery_detail_id          AS doc_line                   -- 取引明細番号
       ,ooha.attribute11                AS result_post                -- 成績部署
       ,xola.unit_price                 AS unit_price                 -- 販売単価
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
       ,xoha.arrival_date               AS arrival_date               -- 着荷日
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- 出荷先ID
       ,NULL                            AS item_id                    -- 品目ID
       ,mcb_o2.segment1                 AS item_div                   -- 品目区分
       ,mcb_o1.segment1                 AS prod_div                   -- 商品区分
       ,mcb_o3.segment1                 AS crowd_code                 -- 郡
       ,mcb_o4.segment1                 AS acnt_crowd_code            -- 経理郡
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
       ,xoha.vendor_site_id             AS vendor_site_id             -- 仕入先ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- 着荷予定日
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,wsh_delivery_details     wdd     -- 出荷搬送明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a1   -- 振替先品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a2   -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_categories_b       mcb_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a3   -- 振替先品目郡カテゴリ情報
       ,gmi_item_categories    gic_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a4   -- 振替先品目経理郡カテゴリ情報
       ,gmi_item_categories    gic_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o1   -- 振替元品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o2   -- 振替元品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_categories_b       mcb_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o3   -- 振替元品目郡カテゴリ情報
       ,gmi_item_categories    gic_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o4   -- 振替元品目経理郡カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('製品出荷','有償')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- 在庫調整以外
      OR  (otta.attribute4       IS NULL))        -- 在庫調整以外
  AND NVL( xrpm.ship_prov_rcv_pay_category, NVL( otta.attribute11, 'NULL' ) ) =
      NVL( otta.attribute11, 'NULL' )
  AND xrpm.item_div_ahead      IS NOT NULL
  AND xrpm.item_div_origin     IS NOT NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_o2.segment1
  AND xola.request_item_code = xola.shipping_item_code
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '商品区分'
  AND iimb_a.item_id            = gic_a1.item_id
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '品目区分'
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替先郡取得情報
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '群コード'
  AND iimb_a.item_id            = gic_a3.item_id
  -- 振替先経理郡取得情報
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '経理部用群コード'
  AND iimb_a.item_id            = gic_a4.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '商品区分'
  AND iimb_o.item_id            = gic_o1.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '品目区分'
  AND iimb_o.item_id            = gic_o2.item_id
  -- 振替元郡取得情報
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '群コード'
  AND iimb_o.item_id            = gic_o3.item_id
  -- 振替元経理郡取得情報
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '経理部用群コード'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,xrpm.source_document_code       AS source_document_code       -- ソース文書
       ,xrpm.transaction_type           AS transaction_type           -- PO取引タイプ
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- 出荷支給区分
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- 在庫調整区分
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- 出荷支給受払カテゴリ
       ,xrpm.item_div_ahead             AS item_div_ahead             -- 品目区分（振替先）
       ,xrpm.item_div_origin            AS item_div_origin            -- 品目区分（振替元）
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- 商品区分（振替先）
       ,xrpm.prod_div_origin            AS prod_div_origin            -- 商品区分（振替元）
       ,xrpm.routing_class              AS routing_class              -- 工順区分
       ,xrpm.line_type                  AS line_type                  -- ラインタイプ
       ,xrpm.hit_in_div                 AS hit_in_div                 -- 打込区分
       ,xrpm.reason_code                AS reason_code                -- 事由コード
       ,wdd.delivery_detail_id          AS doc_line                   -- 取引明細番号
       ,ooha.attribute11                AS result_post                -- 成績部署
       ,xola.unit_price                 AS unit_price                 -- 販売単価
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
       ,xoha.arrival_date               AS arrival_date               -- 着荷日
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- 出荷先ID
       ,NULL                            AS item_id                    -- 品目ID
       ,mcb_o2.segment1                 AS item_div                   -- 品目区分
       ,mcb_o1.segment1                 AS prod_div                   -- 商品区分
       ,mcb_o3.segment1                 AS crowd_code                 -- 郡
       ,mcb_o4.segment1                 AS acnt_crowd_code            -- 経理郡
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
       ,xoha.vendor_site_id             AS vendor_site_id             -- 仕入先ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- 着荷予定日
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,wsh_delivery_details     wdd     -- 出荷搬送明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a1   -- 振替先品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a2   -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_categories_b       mcb_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a3   -- 振替先品目郡カテゴリ情報
       ,gmi_item_categories    gic_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a4   -- 振替先品目経理郡カテゴリ情報
       ,gmi_item_categories    gic_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o1   -- 振替元品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o2   -- 振替元品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_categories_b       mcb_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o3   -- 振替元品目郡カテゴリ情報
       ,gmi_item_categories    gic_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o4   -- 振替元品目経理郡カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('資材出荷','有償')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- 在庫調整以外
      OR  (otta.attribute4       IS NULL))        -- 在庫調整以外
  AND NVL( xrpm.ship_prov_rcv_pay_category, NVL( otta.attribute11, 'NULL' ) ) =
      NVL( otta.attribute11, 'NULL' )
  AND xrpm.item_div_ahead      IS NULL
  AND xrpm.item_div_origin     IS NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND mcb_a2.segment1  <> '5'   -- 製品以外
  AND mcb_o2.segment1  <> '5'   -- 製品以外
  AND xola.request_item_code = xola.shipping_item_code
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '商品区分'
  AND iimb_a.item_id            = gic_a1.item_id
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '品目区分'
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替先郡取得情報
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '群コード'
  AND iimb_a.item_id            = gic_a3.item_id
  -- 振替先経理郡取得情報
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '経理部用群コード'
  AND iimb_a.item_id            = gic_a4.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '商品区分'
  AND iimb_o.item_id            = gic_o1.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '品目区分'
  AND iimb_o.item_id            = gic_o2.item_id
  -- 振替元郡取得情報
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '群コード'
  AND iimb_o.item_id            = gic_o3.item_id
  -- 振替元経理郡取得情報
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '経理部用群コード'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,xrpm.source_document_code       AS source_document_code       -- ソース文書
       ,xrpm.transaction_type           AS transaction_type           -- PO取引タイプ
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- 出荷支給区分
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- 在庫調整区分
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- 出荷支給受払カテゴリ
       ,xrpm.item_div_ahead             AS item_div_ahead             -- 品目区分（振替先）
       ,xrpm.item_div_origin            AS item_div_origin            -- 品目区分（振替元）
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- 商品区分（振替先）
       ,xrpm.prod_div_origin            AS prod_div_origin            -- 商品区分（振替元）
       ,xrpm.routing_class              AS routing_class              -- 工順区分
       ,xrpm.line_type                  AS line_type                  -- ラインタイプ
       ,xrpm.hit_in_div                 AS hit_in_div                 -- 打込区分
       ,xrpm.reason_code                AS reason_code                -- 事由コード
       ,wdd.delivery_detail_id          AS doc_line                   -- 取引明細番号
       ,ooha.attribute11                AS result_post                -- 成績部署
       ,xola.unit_price                 AS unit_price                 -- 販売単価
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
       ,xoha.arrival_date               AS arrival_date               -- 着荷日
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- 出荷先ID
       ,DECODE(xlvv.meaning,
                 '振替有償_受入',iimb_a.item_id,                      -- 振替先品目ID
                 '振替有償_出荷',iimb_a.item_id,                      -- 振替先品目ID
                 '振替有償_払出',iimb_o.item_id) AS item_id           -- 振替元品目ID
       ,DECODE(xlvv.meaning,
                 '振替有償_受入',mcb_a2.segment1,                     -- 振替先品目区分
                 '振替有償_出荷',mcb_a2.segment1,                     -- 振替先品目区分
                 '振替有償_払出',mcb_o2.segment1) AS item_div         -- 振替元品目区分
       ,DECODE(xlvv.meaning,
                 '振替有償_受入',mcb_a1.segment1,                     -- 振替先商品区分
                 '振替有償_出荷',mcb_a1.segment1,                     -- 振替先商品区分
                 '振替有償_払出',mcb_o1.segment1) AS prod_div         -- 振替元商品区分
       ,DECODE(xlvv.meaning,
                 '振替有償_受入',mcb_a3.segment1,                     -- 振替先郡
                 '振替有償_出荷',mcb_a3.segment1,                     -- 振替先郡
                 '振替有償_払出',mcb_o3.segment1) AS crowd_code       -- 振替元郡
       ,DECODE(xlvv.meaning,
                 '振替有償_受入',mcb_a4.segment1,                     -- 振替先経理郡
                 '振替有償_出荷',mcb_a4.segment1,                     -- 振替先経理郡
                 '振替有償_払出',mcb_o4.segment1) AS acnt_crowd_code  -- 振替元経理郡
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
       ,xoha.vendor_site_id             AS vendor_site_id             -- 仕入先ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- 着荷予定日
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,wsh_delivery_details     wdd     -- 出荷搬送明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a1   -- 振替先品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a2   -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_categories_b       mcb_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a3   -- 振替先品目郡カテゴリ情報
       ,gmi_item_categories    gic_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a4   -- 振替先品目経理郡カテゴリ情報
       ,gmi_item_categories    gic_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o1   -- 振替元品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o2   -- 振替元品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_categories_b       mcb_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o3   -- 振替元品目郡カテゴリ情報
       ,gmi_item_categories    gic_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o4   -- 振替元品目経理郡カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('振替有償_受入','振替有償_出荷','振替有償_払出')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- 在庫調整以外
      OR  (otta.attribute4       IS NULL))        -- 在庫調整以外
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  AND xrpm.item_div_ahead      IS NOT NULL
  AND xrpm.item_div_origin     IS NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND xrpm.item_div_ahead         = mcb_a2.segment1
  AND mcb_o2.segment1          <> '5'   -- 製品以外
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '商品区分'
  AND iimb_a.item_id            = gic_a1.item_id
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '品目区分'
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替先郡取得情報
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '群コード'
  AND iimb_a.item_id            = gic_a3.item_id
  -- 振替先経理郡取得情報
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '経理部用群コード'
  AND iimb_a.item_id            = gic_a4.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '商品区分'
  AND iimb_o.item_id            = gic_o1.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '品目区分'
  AND iimb_o.item_id            = gic_o2.item_id
  -- 振替元郡取得情報
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '群コード'
  AND iimb_o.item_id            = gic_o3.item_id
  -- 振替元経理郡取得情報
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '経理部用群コード'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,xrpm.source_document_code       AS source_document_code       -- ソース文書
       ,xrpm.transaction_type           AS transaction_type           -- PO取引タイプ
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- 出荷支給区分
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- 在庫調整区分
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- 出荷支給受払カテゴリ
       ,xrpm.item_div_ahead             AS item_div_ahead             -- 品目区分（振替先）
       ,xrpm.item_div_origin            AS item_div_origin            -- 品目区分（振替元）
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- 商品区分（振替先）
       ,xrpm.prod_div_origin            AS prod_div_origin            -- 商品区分（振替元）
       ,xrpm.routing_class              AS routing_class              -- 工順区分
       ,xrpm.line_type                  AS line_type                  -- ラインタイプ
       ,xrpm.hit_in_div                 AS hit_in_div                 -- 打込区分
       ,xrpm.reason_code                AS reason_code                -- 事由コード
       ,wdd.delivery_detail_id          AS doc_line                   -- 取引明細番号
       ,ooha.attribute11                AS result_post                -- 成績部署
       ,xola.unit_price                 AS unit_price                 -- 販売単価
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
       ,xoha.arrival_date               AS arrival_date               -- 着荷日
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- 出荷先ID
       ,DECODE(xlvv.meaning,
                 '商品振替有償_受入',iimb_a.item_id,                     -- 振替先品目ID
                 '商品振替有償_出荷',iimb_a.item_id,                     -- 振替先品目ID
                 '商品振替有償_払出',iimb_o.item_id) AS item_id          -- 振替元品目ID
       ,DECODE(xlvv.meaning,
                 '商品振替有償_受入',mcb_a2.segment1,             -- 振替先品目区分
                 '商品振替有償_出荷',mcb_a2.segment1,             -- 振替先品目区分
                 '商品振替有償_払出',mcb_o2.segment1) AS item_div -- 振替元品目区分
       ,DECODE(xlvv.meaning,
                 '商品振替有償_受入',mcb_a1.segment1,             -- 振替先商品区分
                 '商品振替有償_出荷',mcb_a1.segment1,             -- 振替先商品区分
                 '商品振替有償_払出',mcb_o1.segment1) AS prod_div -- 振替元商品区分
       ,DECODE(xlvv.meaning,
                 '商品振替有償_受入',mcb_a3.segment1,                  -- 振替先郡
                 '商品振替有償_出荷',mcb_a3.segment1,                  -- 振替先郡
                 '商品振替有償_払出',mcb_o3.segment1) AS crowd_code    -- 振替元郡
       ,DECODE(xlvv.meaning,
                 '商品振替有償_受入',mcb_a4.segment1,             -- 振替先経理郡
                 '商品振替有償_出荷',mcb_a4.segment1,             -- 振替先経理郡
                 '商品振替有償_払出',mcb_o4.segment1) AS acnt_crowd_code -- 振替元経理郡
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
       ,xoha.vendor_site_id             AS vendor_site_id             -- 仕入先ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- 着荷予定日
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,wsh_delivery_details     wdd     -- 出荷搬送明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a1   -- 振替先品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a2   -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_categories_b       mcb_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a3   -- 振替先品目郡カテゴリ情報
       ,gmi_item_categories    gic_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a4   -- 振替先品目経理郡カテゴリ情報
       ,gmi_item_categories    gic_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o1   -- 振替元品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o2   -- 振替元品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_categories_b       mcb_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o3   -- 振替元品目郡カテゴリ情報
       ,gmi_item_categories    gic_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o4   -- 振替元品目経理郡カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('商品振替有償_受入','商品振替有償_出荷','商品振替有償_払出')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no           = xola.request_item_code
  AND iimb_o.item_no           = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- 在庫調整以外
      OR  (otta.attribute4       IS NULL))        -- 在庫調整以外
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NOT NULL
  AND xrpm.prod_div_ahead  IS NOT NULL
  AND xrpm.prod_div_origin IS NOT NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_o2.segment1
  AND xrpm.prod_div_ahead  = mcb_a1.segment1
  AND xrpm.prod_div_origin = mcb_o1.segment1
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '商品区分'
  AND iimb_a.item_id            = gic_a1.item_id
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '品目区分'
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替先郡取得情報
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '群コード'
  AND iimb_a.item_id            = gic_a3.item_id
  -- 振替先経理郡取得情報
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '経理部用群コード'
  AND iimb_a.item_id            = gic_a4.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '商品区分'
  AND iimb_o.item_id            = gic_o1.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '品目区分'
  AND iimb_o.item_id            = gic_o2.item_id
  -- 振替元郡取得情報
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '群コード'
  AND iimb_o.item_id            = gic_o3.item_id
  -- 振替元経理郡取得情報
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '経理部用群コード'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,xrpm.source_document_code       AS source_document_code       -- ソース文書
       ,xrpm.transaction_type           AS transaction_type           -- PO取引タイプ
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- 出荷支給区分
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- 在庫調整区分
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- 出荷支給受払カテゴリ
       ,xrpm.item_div_ahead             AS item_div_ahead             -- 品目区分（振替先）
       ,xrpm.item_div_origin            AS item_div_origin            -- 品目区分（振替元）
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- 商品区分（振替先）
       ,xrpm.prod_div_origin            AS prod_div_origin            -- 商品区分（振替元）
       ,xrpm.routing_class              AS routing_class              -- 工順区分
       ,xrpm.line_type                  AS line_type                  -- ラインタイプ
       ,xrpm.hit_in_div                 AS hit_in_div                 -- 打込区分
       ,xrpm.reason_code                AS reason_code                -- 事由コード
       ,wdd.delivery_detail_id          AS doc_line                   -- 取引明細番号
       ,ooha.attribute11                AS result_post                -- 成績部署
       ,xola.unit_price                 AS unit_price                 -- 販売単価
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
       ,xoha.arrival_date               AS arrival_date               -- 着荷日
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- 出荷先ID
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',iimb_a.item_id,                  -- 振替先品目ID
                 '振替出荷_受入_半',iimb_a.item_id,                  -- 振替先品目ID
                 '振替出荷_出荷'   ,iimb_a.item_id,                  -- 振替先品目ID
                 '振替出荷_払出'   ,iimb_o.item_id) AS item_id       -- 振替元品目ID
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',mcb_a2.segment1,                 -- 振替先品目区分
                 '振替出荷_受入_半',mcb_a2.segment1,                 -- 振替先品目区分
                 '振替出荷_出荷'   ,mcb_a2.segment1,                 -- 振替先品目区分
                 '振替出荷_払出'   ,mcb_o2.segment1) AS item_div     -- 振替元品目区分
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',mcb_a1.segment1,                 -- 振替先商品区分
                 '振替出荷_受入_半',mcb_a1.segment1,                 -- 振替先商品区分
                 '振替出荷_出荷'   ,mcb_a1.segment1,                 -- 振替先商品区分
                 '振替出荷_払出'   ,mcb_o1.segment1) AS prod_div     -- 振替元商品区分
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',mcb_a3.segment1,                 -- 振替先郡
                 '振替出荷_受入_半',mcb_a3.segment1,                 -- 振替先郡
                 '振替出荷_出荷'   ,mcb_a3.segment1,                 -- 振替先郡
                 '振替出荷_払出'   ,mcb_o3.segment1) AS crowd_code   -- 振替元郡
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',mcb_a4.segment1,                 -- 振替先経理郡
                 '振替出荷_受入_半',mcb_a4.segment1,                 -- 振替先経理郡
                 '振替出荷_出荷'   ,mcb_a4.segment1,                 -- 振替先経理郡
                 '振替出荷_払出'   ,mcb_o4.segment1) AS acnt_crowd_code -- 振替元経理郡
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
       ,xoha.vendor_site_id             AS vendor_site_id             -- 仕入先ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- 着荷予定日
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,wsh_delivery_details     wdd     -- 出荷搬送明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a1   -- 振替先品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a2   -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_categories_b       mcb_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a3   -- 振替先品目郡カテゴリ情報
       ,gmi_item_categories    gic_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a4   -- 振替先品目経理郡カテゴリ情報
       ,gmi_item_categories    gic_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o1   -- 振替元品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o2   -- 振替元品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_categories_b       mcb_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o3   -- 振替元品目郡カテゴリ情報
       ,gmi_item_categories    gic_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o4   -- 振替元品目経理郡カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('振替出荷_受入_原','振替出荷_受入_半',
                                    '振替出荷_出荷','振替出荷_払出')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- 在庫調整以外
      OR  (otta.attribute4       IS NULL))        -- 在庫調整以外
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NULL
  AND xrpm.prod_div_ahead  IS NULL
  AND xrpm.prod_div_origin IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND mcb_o2.segment1      <> '5'   -- 製品以外
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '商品区分'
  AND iimb_a.item_id            = gic_a1.item_id
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '品目区分'
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替先郡取得情報
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '群コード'
  AND iimb_a.item_id            = gic_a3.item_id
  -- 振替先経理郡取得情報
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '経理部用群コード'
  AND iimb_a.item_id            = gic_a4.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '商品区分'
  AND iimb_o.item_id            = gic_o1.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '品目区分'
  AND iimb_o.item_id            = gic_o2.item_id
  -- 振替元郡取得情報
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '群コード'
  AND iimb_o.item_id            = gic_o3.item_id
  -- 振替元経理郡取得情報
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '経理部用群コード'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,xrpm.source_document_code       AS source_document_code       -- ソース文書
       ,xrpm.transaction_type           AS transaction_type           -- PO取引タイプ
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- 出荷支給区分
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- 在庫調整区分
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- 出荷支給受払カテゴリ
       ,xrpm.item_div_ahead             AS item_div_ahead             -- 品目区分（振替先）
       ,xrpm.item_div_origin            AS item_div_origin            -- 品目区分（振替元）
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- 商品区分（振替先）
       ,xrpm.prod_div_origin            AS prod_div_origin            -- 商品区分（振替元）
       ,xrpm.routing_class              AS routing_class              -- 工順区分
       ,xrpm.line_type                  AS line_type                  -- ラインタイプ
       ,xrpm.hit_in_div                 AS hit_in_div                 -- 打込区分
       ,xrpm.reason_code                AS reason_code                -- 事由コード
       ,wdd.delivery_detail_id          AS doc_line                   -- 取引明細番号
       ,ooha.attribute11                AS result_post                -- 成績部署
       ,xola.unit_price                 AS unit_price                 -- 販売単価
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
       ,xoha.arrival_date               AS arrival_date               -- 着荷日
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- 出荷先ID
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',iimb_a.item_id,                   -- 振替先品目ID
                 '振替出荷_受入_半',iimb_a.item_id,                   -- 振替先品目ID
                 '振替出荷_出荷'   ,iimb_a.item_id,                   -- 振替先品目ID
                 '振替出荷_払出'   ,iimb_o.item_id) AS item_id        -- 振替元品目ID
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',mcb_a2.segment1,                  -- 振替先品目区分
                 '振替出荷_受入_半',mcb_a2.segment1,                  -- 振替先品目区分
                 '振替出荷_出荷'   ,mcb_a2.segment1,                  -- 振替先品目区分
                 '振替出荷_払出'   ,mcb_o2.segment1) AS item_div      -- 振替元品目区分
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',mcb_a1.segment1,                  -- 振替先商品区分
                 '振替出荷_受入_半',mcb_a1.segment1,                  -- 振替先商品区分
                 '振替出荷_出荷'   ,mcb_a1.segment1,                  -- 振替先商品区分
                 '振替出荷_払出'   ,mcb_o1.segment1) AS prod_div      -- 振替元商品区分
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',mcb_a3.segment1,                  -- 振替先郡
                 '振替出荷_受入_半',mcb_a3.segment1,                  -- 振替先郡
                 '振替出荷_出荷'   ,mcb_a3.segment1,                  -- 振替先郡
                 '振替出荷_払出'   ,mcb_o3.segment1) AS crowd_code    -- 振替元郡
       ,DECODE(xlvv.meaning,
                 '振替出荷_受入_原',mcb_a4.segment1,                  -- 振替先経理郡
                 '振替出荷_受入_半',mcb_a4.segment1,                  -- 振替先経理郡
                 '振替出荷_出荷'   ,mcb_a4.segment1,                  -- 振替先経理郡
                 '振替出荷_払出'   ,mcb_o4.segment1) AS acnt_crowd_code -- 振替元経理郡
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
       ,xoha.vendor_site_id             AS vendor_site_id             -- 仕入先ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- 着荷予定日
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,wsh_delivery_details     wdd     -- 出荷搬送明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a1   -- 振替先品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a2   -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_categories_b       mcb_a3    -- 振替先品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a3   -- 振替先品目郡カテゴリ情報
       ,gmi_item_categories    gic_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_a4    -- 振替先品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a4   -- 振替先品目経理郡カテゴリ情報
       ,gmi_item_categories    gic_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o1   -- 振替元品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_o2   -- 振替元品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_categories_b       mcb_o3    -- 振替元品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o3   -- 振替元品目郡カテゴリ情報
       ,gmi_item_categories    gic_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_o4    -- 振替元品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_o4   -- 振替元品目経理郡カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('振替出荷_受入_原','振替出荷_受入_半',
                                    '振替出荷_出荷','振替出荷_払出')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- 在庫調整以外
      OR  (otta.attribute4       IS NULL))        -- 在庫調整以外
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NOT NULL
  AND xrpm.prod_div_ahead  IS NULL
  AND xrpm.prod_div_origin IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_o2.segment1
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '商品区分'
  AND iimb_a.item_id            = gic_a1.item_id
  -- 振替先商品区分カテゴリ取得情報
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '品目区分'
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替先郡取得情報
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '群コード'
  AND iimb_a.item_id            = gic_a3.item_id
  -- 振替先経理郡取得情報
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '経理部用群コード'
  AND iimb_a.item_id            = gic_a4.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '商品区分'
  AND iimb_o.item_id            = gic_o1.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '品目区分'
  AND iimb_o.item_id            = gic_o2.item_id
  -- 振替元郡取得情報
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '群コード'
  AND iimb_o.item_id            = gic_o3.item_id
  -- 振替元経理郡取得情報
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '経理部用群コード'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,xrpm.source_document_code       AS source_document_code       -- ソース文書
       ,xrpm.transaction_type           AS transaction_type           -- PO取引タイプ
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- 出荷支給区分
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- 在庫調整区分
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- 出荷支給受払カテゴリ
       ,xrpm.item_div_ahead             AS item_div_ahead             -- 品目区分（振替先）
       ,xrpm.item_div_origin            AS item_div_origin            -- 品目区分（振替元）
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- 商品区分（振替先）
       ,xrpm.prod_div_origin            AS prod_div_origin            -- 商品区分（振替元）
       ,xrpm.routing_class              AS routing_class              -- 工順区分
       ,xrpm.line_type                  AS line_type                  -- ラインタイプ
       ,xrpm.hit_in_div                 AS hit_in_div                 -- 打込区分
       ,xrpm.reason_code                AS reason_code                -- 事由コード
       ,wdd.delivery_detail_id          AS doc_line                   -- 取引明細番号
       ,ooha.attribute11                AS result_post                -- 成績部署
       ,xola.unit_price                 AS unit_price                 -- 販売単価
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
       ,xoha.arrival_date               AS arrival_date               -- 着荷日
       ,xoha.deliver_to_id              AS deliver_to_id              -- 出荷先ID
       ,NULL                            AS item_id                    -- 品目ID
       ,mcb_a2.segment1                 AS item_div                   -- 品目区分
       ,mcb_a1.segment1                 AS prod_div                   -- 商品区分
       ,mcb_a3.segment1                 AS crowd_code                 -- 郡
       ,mcb_a4.segment1                 AS acnt_crowd_code            -- 経理郡
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
       ,xoha.vendor_site_id             AS vendor_site_id             -- 仕入先ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- 着荷予定日
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,wsh_delivery_details     wdd     -- 出荷搬送明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 品目情報
       ,gmi_item_categories    gic_a1    -- 品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_a1    -- 品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a1   -- 品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_a2    -- 品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 先品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a2   -- 品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_a3    -- 品目郡カテゴリ情報
       ,mtl_categories_b       mcb_a3    -- 品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a3   -- 品目郡カテゴリ情報
       ,gmi_item_categories    gic_a4    -- 品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_a4    -- 品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a4   -- 品目経理郡カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type                   = 'OMSO'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('倉替','返品')
  AND xrpm.dealings_div               = xlvv.lookup_code
  AND ooha.header_id                  = wdd.source_header_id
  AND otta.transaction_type_id        = ooha.order_type_id
  AND oola.line_id                    = wdd.source_line_id
  AND wdd.org_id                      = ooha.org_id
  AND wdd.org_id                      = oola.org_id
  AND xoha.header_id                  = ooha.header_id
  AND oola.header_id                  = ooha.header_id
  AND xola.header_id                  = xoha.header_id
  AND oola.line_id                    = xola.line_id
  AND iimb_a.item_no                  = xola.shipping_item_code
  AND xrpm.shipment_provision_div     = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- 在庫調整以外
      OR  (otta.attribute4       IS NULL))        -- 在庫調整以外
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  -- 商品区分カテゴリ取得情報
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '商品区分'
  AND iimb_a.item_id            = gic_a1.item_id
  -- 商品区分カテゴリ取得情報
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '品目区分'
  AND iimb_a.item_id            = gic_a2.item_id
  -- 郡取得情報
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '群コード'
  AND iimb_a.item_id            = gic_a3.item_id
  -- 経理郡取得情報
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '経理部用群コード'
  AND iimb_a.item_id            = gic_a4.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,xrpm.source_document_code       AS source_document_code       -- ソース文書
       ,xrpm.transaction_type           AS transaction_type           -- PO取引タイプ
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- 出荷支給区分
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- 在庫調整区分
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- 出荷支給受払カテゴリ
       ,xrpm.item_div_ahead             AS item_div_ahead             -- 品目区分（振替先）
       ,xrpm.item_div_origin            AS item_div_origin            -- 品目区分（振替元）
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- 商品区分（振替先）
       ,xrpm.prod_div_origin            AS prod_div_origin            -- 商品区分（振替元）
       ,xrpm.routing_class              AS routing_class              -- 工順区分
       ,xrpm.line_type                  AS line_type                  -- ラインタイプ
       ,xrpm.hit_in_div                 AS hit_in_div                 -- 打込区分
       ,xrpm.reason_code                AS reason_code                -- 事由コード
       ,wdd.delivery_detail_id          AS doc_line                   -- 取引明細番号
       ,ooha.attribute11                AS result_post                -- 成績部署
       ,xola.unit_price                 AS unit_price                 -- 販売単価
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
       ,xoha.arrival_date               AS arrival_date               -- 着荷日
       ,xoha.deliver_to_id              AS deliver_to_id              -- 出荷先ID
       ,NULL                            AS item_id                    -- 品目ID
       ,mcb_a2.segment1                 AS item_div                   -- 品目区分
       ,mcb_a1.segment1                 AS prod_div                   -- 商品区分
       ,mcb_a3.segment1                 AS crowd_code                 -- 郡
       ,mcb_a4.segment1                 AS acnt_crowd_code            -- 経理郡
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
       ,xoha.vendor_site_id             AS vendor_site_id             -- 仕入先ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- 着荷予定日
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,wsh_delivery_details     wdd     -- 出荷搬送明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 品目情報
       ,gmi_item_categories    gic_a1    -- 品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_a1    -- 品目商品区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a1   -- 品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_a2    -- 品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 先品目品目区分カテゴリ情報
       ,mtl_category_sets_tl   mcst_a2   -- 品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_a3    -- 品目郡カテゴリ情報
       ,mtl_categories_b       mcb_a3    -- 品目郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a3   -- 品目郡カテゴリ情報
       ,gmi_item_categories    gic_a4    -- 品目経理郡カテゴリ情報
       ,mtl_categories_b       mcb_a4    -- 品目経理郡カテゴリ情報
       ,mtl_category_sets_tl   mcst_a4   -- 品目経理郡カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type                   = 'OMSO'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('見本','廃却')
  AND xrpm.dealings_div               = xlvv.lookup_code
  AND ooha.header_id                  = wdd.source_header_id
  AND otta.transaction_type_id        = ooha.order_type_id
  AND oola.line_id                    = wdd.source_line_id
  AND wdd.org_id                      = ooha.org_id
  AND wdd.org_id                      = oola.org_id
  AND xoha.header_id                  = ooha.header_id
  AND oola.header_id                  = ooha.header_id
  AND xola.header_id                  = xoha.header_id
  AND oola.line_id                    = xola.line_id
  AND iimb_a.item_no                   = xola.shipping_item_code
  AND xrpm.stock_adjustment_div       = otta.attribute4
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  -- 商品区分カテゴリ取得情報
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '商品区分'
  AND iimb_a.item_id            = gic_a1.item_id
  -- 商品区分カテゴリ取得情報
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '品目区分'
  AND iimb_a.item_id            = gic_a2.item_id
  -- 郡取得情報
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '群コード'
  AND iimb_a.item_id            = gic_a3.item_id
  -- 経理郡取得情報
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '経理部用群コード'
  AND iimb_a.item_id            = gic_a4.item_id
/
COMMENT ON TABLE XXCMN_RCV_PAY_MST_OMSO_V IS '経理受払区分情報VIEW_受注関連'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.NEW_DIV_ACCOUNT IS '新経理受払区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DEALINGS_DIV IS '取引区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.RCV_PAY_DIV IS '受払区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DOC_TYPE IS '文書タイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.SOURCE_DOCUMENT_CODE IS 'ソース文書'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.TRANSACTION_TYPE IS 'PO取引タイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.SHIPMENT_PROVISION_DIV IS '出荷支給区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.STOCK_ADJUSTMENT_DIV IS '在庫調整区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.SHIP_PROV_RCV_PAY_CATEGORY IS '出荷支給受払カテゴリ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ITEM_DIV_AHEAD IS '品目区分（振替先）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ITEM_DIV_ORIGIN IS '品目区分（振替元）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.PROD_DIV_AHEAD IS '商品区分（振替先）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.PROD_DIV_ORIGIN IS '商品区分（振替元）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ROUTING_CLASS IS '工順区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.LINE_TYPE IS 'ラインタイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.HIT_IN_DIV IS '打込区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.REASON_CODE IS '事由コード'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DOC_LINE IS '取引明細番号'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.RESULT_POST IS '成績部署'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.UNIT_PRICE IS '販売単価'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.REQUEST_ITEM_CODE IS '依頼品目コード'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ARRIVAL_DATE IS '着荷日'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DELIVER_TO_ID IS '出荷先ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ITEM_ID IS '品目ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ITEM_DIV IS '品目区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.PROD_DIV IS '商品区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.CROWD_CODE IS '郡'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ACNT_CROWD_CODE IS '経理郡'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DEALINGS_DIV_NAME IS '取引区分名'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.VENDOR_SITE_ID IS '仕入先ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.SCHEDULE_ARRIVAL_DATE IS '着荷予定日'
/