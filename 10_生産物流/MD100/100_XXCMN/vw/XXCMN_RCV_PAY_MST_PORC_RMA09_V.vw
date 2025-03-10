/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_PORC_RMA09_V
 * Description     : 経理受払区分情報VIEW_購買関連_出荷(for XXCMN770009C)
 * Version         : 1.7
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-08-07    1.0   R.Tomoyose       新規作成
 *  2008/08/27    1.1   A.Shiina         取得項目に受払区分を追加
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCMN_RCV_PAY_MST_PORC_RMA09_V
-- 2008/08/27 v1.1 UPDATE START
--    (NEW_DIV_ACCOUNT,DEALINGS_DIV,DOC_TYPE,DOC_ID,DOC_LINE,REQUEST_ITEM_CODE)
    (NEW_DIV_ACCOUNT,DEALINGS_DIV,RCV_PAY_DIV,DOC_TYPE,DOC_ID,DOC_LINE,REQUEST_ITEM_CODE)
-- 2008/08/27 v1.1 UPDATE END
AS
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
-- 2008/08/27 v1.1 ADD START
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
-- 2008/08/27 v1.1 ADD END
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,rsl.shipment_header_id          AS doc_id                     -- 文書ID
       ,rsl.line_num                    AS doc_line                   -- 取引明細番号
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,rcv_shipment_lines       rsl     -- 受入明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 品目情報
       ,gmi_item_categories    gic_a2    -- 品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 品目品目区分カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('製品出荷','有償')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = rsl.oe_order_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND oola.line_id              = rsl.oe_order_line_id
  AND oola.line_id              = xola.line_id
  AND xola.request_item_code    = xola.shipping_item_code
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_a.item_no            = xola.shipping_item_code
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
  AND xrpm.item_div_origin = mcb_a2.segment1
  -- 品目区分カテゴリ取得情報
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
-- 2008/08/27 v1.1 ADD START
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
-- 2008/08/27 v1.1 ADD END
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,rsl.shipment_header_id          AS doc_id                     -- 文書ID
       ,rsl.line_num                    AS doc_line                   -- 取引明細番号
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,rcv_shipment_lines       rsl     -- 受入明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 品目情報
       ,gmi_item_categories    gic_a2    -- 品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 品目品目区分カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('資材出荷','有償')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = rsl.oe_order_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND oola.line_id              = rsl.oe_order_line_id
  AND oola.line_id              = xola.line_id
  AND xola.request_item_code    = xola.shipping_item_code
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_a.item_no            = xola.shipping_item_code
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
  -- 品目区分カテゴリ取得情報
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
-- 2008/08/27 v1.1 ADD START
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
-- 2008/08/27 v1.1 ADD END
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,rsl.shipment_header_id          AS doc_id                     -- 文書ID
       ,rsl.line_num                    AS doc_line                   -- 取引明細番号
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,rcv_shipment_lines       rsl     -- 受入明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type               = 'PORC'
  AND xrpm.source_document_code   = 'RMA'
  AND xlvv.lookup_type            = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                IN ('振替有償_受入','振替有償_出荷','振替有償_払出')
  AND xrpm.dealings_div           = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id              = rsl.oe_order_header_id
  AND otta.transaction_type_id    = ooha.order_type_id
  AND xoha.header_id              = ooha.header_id
  AND oola.header_id              = ooha.header_id
  AND oola.line_id                = rsl.oe_order_line_id
  AND oola.line_id                = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- 在庫調整以外
      OR  (otta.attribute4       IS NULL))        -- 在庫調整以外
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  AND xrpm.item_div_ahead         IS NOT NULL
  AND xrpm.item_div_origin        IS NULL
  AND xrpm.prod_div_ahead         IS NULL
  AND xrpm.prod_div_origin        IS NULL
  AND xrpm.item_div_ahead         = mcb_a2.segment1
  AND mcb_o2.segment1          <> '5'   -- 製品以外
  -- 振替先品目区分カテゴリ取得情報
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替元品目区分カテゴリ取得情報
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
-- 2008/08/27 v1.1 ADD START
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
-- 2008/08/27 v1.1 ADD END
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,rsl.shipment_header_id          AS doc_id                     -- 文書ID
       ,rsl.line_num                    AS doc_line                   -- 取引明細番号
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,rcv_shipment_lines       rsl     -- 受入明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a1    -- 振替先品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_a1    -- 振替先品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o1    -- 振替元品目商品区分カテゴリ情報
       ,mtl_categories_b       mcb_o1    -- 振替元品目商品区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('商品振替有償_受入','商品振替有償_出荷','商品振替有償_払出')
  AND xrpm.dealings_div           = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id              = rsl.oe_order_header_id
  AND otta.transaction_type_id    = ooha.order_type_id
  AND xoha.header_id              = ooha.header_id
  AND oola.header_id              = ooha.header_id
  AND oola.line_id                = rsl.oe_order_line_id
  AND oola.line_id                = xola.line_id
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
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- 振替先品目区分カテゴリ取得情報
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替元商品区分カテゴリ取得情報
  AND gic_o1.category_set_id    = gic_a1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND iimb_o.item_id            = gic_o1.item_id
  -- 振替元品目区分カテゴリ取得情報
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
-- 2008/08/27 v1.1 ADD START
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
-- 2008/08/27 v1.1 ADD END
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,rsl.shipment_header_id          AS doc_id                     -- 文書ID
       ,rsl.line_num                    AS doc_line                   -- 取引明細番号
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,rcv_shipment_lines       rsl     -- 受入明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('振替出荷_受入_原','振替出荷_受入_半',
                                    '振替出荷_出荷','振替出荷_払出')
  AND xrpm.dealings_div           = xlvv.lookup_code
  AND xoha.req_status             = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id              = rsl.oe_order_header_id
  AND otta.transaction_type_id    = ooha.order_type_id
  AND xoha.header_id              = ooha.header_id
  AND oola.header_id              = ooha.header_id
  AND oola.line_id                = rsl.oe_order_line_id
  AND oola.line_id                = xola.line_id
  AND iimb_a.item_no              = xola.request_item_code
  AND iimb_o.item_no              = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- 在庫調整以外
      OR  (otta.attribute4       IS NULL))        -- 在庫調整以外
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NULL
  AND xrpm.prod_div_ahead  IS NULL
  AND xrpm.prod_div_origin IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND mcb_o2.segment1      <> '5'   -- 製品以外
  -- 振替先品目区分カテゴリ取得情報
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替元品目区分カテゴリ取得情報
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
-- 2008/08/27 v1.1 ADD START
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
-- 2008/08/27 v1.1 ADD END
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,rsl.shipment_header_id          AS doc_id                     -- 文書ID
       ,rsl.line_num                    AS doc_line                   -- 取引明細番号
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,rcv_shipment_lines       rsl     -- 受入明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,ic_item_mst_b          iimb_a    -- 振替先品目情報
       ,ic_item_mst_b          iimb_o    -- 振替元品目情報
       ,gmi_item_categories    gic_a2    -- 振替先品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_a2    -- 振替先品目品目区分カテゴリ情報
       ,gmi_item_categories    gic_o2    -- 振替元品目品目区分カテゴリ情報
       ,mtl_categories_b       mcb_o2    -- 振替元品目品目区分カテゴリ情報
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('振替出荷_受入_原','振替出荷_受入_半',
                                    '振替出荷_出荷','振替出荷_払出')
  AND xrpm.dealings_div           = xlvv.lookup_code
  AND xoha.req_status             = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id              = rsl.oe_order_header_id
  AND otta.transaction_type_id    = ooha.order_type_id
  AND xoha.header_id              = ooha.header_id
  AND oola.header_id              = ooha.header_id
  AND oola.line_id                = rsl.oe_order_line_id
  AND oola.line_id                = xola.line_id
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
  -- 振替先品目区分カテゴリ取得情報
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- 振替元品目区分カテゴリ取得情報
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
-- 2008/08/27 v1.1 ADD START
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
-- 2008/08/27 v1.1 ADD END
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,rsl.shipment_header_id          AS doc_id                     -- 文書ID
       ,rsl.line_num                    AS doc_line                   -- 取引明細番号
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,rcv_shipment_lines       rsl     -- 受入明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type                   = 'PORC'
  AND xrpm.source_document_code       = 'RMA'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('倉替','返品')
  AND xrpm.dealings_div               = xlvv.lookup_code
  AND ooha.header_id                  = rsl.oe_order_header_id
  AND otta.transaction_type_id        = ooha.order_type_id
  AND xoha.header_id                  = ooha.header_id
  AND oola.header_id                  = ooha.header_id
  AND oola.line_id                    = rsl.oe_order_line_id
  AND oola.line_id                    = xola.line_id
  AND xrpm.shipment_provision_div     = otta.attribute1
  AND ((otta.attribute4               <> '2')         -- 在庫調整以外
      OR  (otta.attribute4            IS NULL))       -- 在庫調整以外
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
-- 2008/08/27 v1.1 ADD START
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
-- 2008/08/27 v1.1 ADD START
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,rsl.shipment_header_id          AS doc_id                     -- 文書ID
       ,rsl.line_num                    AS doc_line                   -- 取引明細番号
       ,oola.attribute3                 AS request_item_code          -- 依頼品目コード
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,rcv_shipment_lines       rsl     -- 受入明細
       ,oe_order_headers_all     ooha    -- 受注ヘッダ
       ,oe_order_lines_all       oola    -- 受注明細
       ,oe_transaction_types_all otta    -- 受注タイプ
       ,xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
       ,xxwsh_order_lines_all    xola    -- 受注明細アドオン
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type                   = 'PORC'
  AND xrpm.source_document_code       = 'RMA'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('見本','廃却')
  AND xrpm.dealings_div               = xlvv.lookup_code
  AND ooha.header_id                  = rsl.oe_order_header_ID
  AND otta.transaction_type_id        = ooha.order_type_id
  AND xoha.header_id                  = ooha.header_id
  AND oola.header_id                  = ooha.header_id
  AND oola.line_id                    = rsl.oe_order_line_iD
  AND oola.line_id                    = xola.line_id
  AND xrpm.stock_adjustment_div       = otta.attribute4
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
/
COMMENT ON TABLE XXCMN_RCV_PAY_MST_PORC_RMA09_V IS '経理受払区分情報VIEW_購買関連_出荷09'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA09_V.NEW_DIV_ACCOUNT IS '新経理受払区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA09_V.DEALINGS_DIV IS '取引区分'
/
-- 2008/08/27 v1.1 ADD START
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA09_V.RCV_PAY_DIV IS '受払区分'
/
-- 2008/08/27 v1.1 ADD END
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA09_V.DOC_TYPE IS '文書タイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA09_V.DOC_ID   IS '文書ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA09_V.DOC_LINE IS '取引明細番号'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA09_V.REQUEST_ITEM_CODE IS '依頼品目コード'
/
