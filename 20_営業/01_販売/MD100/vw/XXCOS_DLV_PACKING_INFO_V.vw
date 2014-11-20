/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_dlv_packing_info_v
 * Description     : 納品予定更新(荷番情報)画面view
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/10/29    1.0   K.Kiriu         新規作成
 *  2010/06/16    1.1   H.Sasaki        [E_本稼動_03075]拠点選択対応
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_dlv_packing_info_v(
   edi_header_info_id          -- EDIヘッダ情報.EDIヘッダ情報ID
  ,edi_chain_code              -- EDIヘッダ情報.EDIチェーン店コード
  ,shop_code                   -- EDIヘッダ情報.店コード
  ,shop_delivery_date          -- EDIヘッダ情報.店舗納品日
  ,invoice_class               -- EDIヘッダ情報.伝票区分
  ,delivery_schedule_flag      -- EDIヘッダ情報.EDI納品予定送信済フラグ
  ,xeh_last_updated_by         -- EDIヘッダ情報.最終更新者
  ,xeh_last_update_date        -- EDIヘッダ情報.最終更新日
  ,xeh_last_update_login       -- EDIヘッダ情報.最終ログインID
  ,edi_line_info_id            -- EDI明細情報.EDI明細情報ID
  ,product_code_itouen         -- EDI明細情報.商品コード(伊藤園)
  ,packing_number              -- EDI明細情報.梱包番号
  ,sum_order_qty               -- EDI明細情報.発注数量(合計、バラ)
  ,sum_shipping_qty            -- EDI明細情報.出荷数量(合計、バラ)
  ,sum_stockout_qty            -- EDI明細情報.欠品数量(合計、バラ)
  ,xel_last_updated_by         -- EDI明細情報.最終更新者
  ,xel_last_update_date        -- EDI明細情報.最終更新日
  ,xel_last_update_login       -- EDI明細情報.最終ログインID
  ,ordered_item                -- 受注明細.受注品目
  ,order_quantity_uom          -- 受注明細.受注単位
  ,ordered_quantity            -- 受注明細.受注数量(分割考慮)
  ,num_of_case                 -- OPM品目.ケース入数
  ,num_of_bowl                 -- Disc品目アドオン.ボール入数
  ,jan_code                    -- JANコード
  ,item_name                   -- 商品名
  ,org_id                      -- 受注ヘッダ.営業単位ID
  ,organization_id             -- Disc品目.在庫組織ID
/* 2010/06/16 Ver1.1 Add START */
  ,base_code                   --  顧客アドオン.納品拠点
/* 2010/06/16 Ver1.1 Add END   */
)
AS
  SELECT xeh.edi_header_info_id          edi_header_info_id      -- EDIヘッダ情報.EDIヘッダ情報ID
        ,xeh.edi_chain_code              edi_chain_code          -- EDIヘッダ情報.EDIチェーン店コード
        ,xeh.shop_code                   shop_code               -- EDIヘッダ情報.店コード
        ,xeh.shop_delivery_date          shop_delivery_date      -- EDIヘッダ情報.店舗納品日
        ,xeh.invoice_class               invoice_class           -- EDIヘッダ情報.伝票区分
        ,xeh.edi_delivery_schedule_flag  delivery_schedule_flag  -- EDIヘッダ情報.EDI納品予定送信済フラグ
        ,xeh.last_updated_by             xeh_last_updated_by     -- EDIヘッダ情報.最終更新者
        ,xeh.last_update_date            xeh_last_update_date    -- EDIヘッダ情報.最終更新日
        ,xeh.last_update_login           xeh_last_update_login   -- EDIヘッダ情報.最終ログインID
        ,xel.edi_line_info_id            edi_line_info_id        -- EDI明細情報.EDI明細情報ID
        ,xel.product_code_itouen         product_code_itouen     -- EDI明細情報.商品コード(伊藤園)
        ,xel.packing_number              packing_number          -- EDI明細情報.梱包番号
        ,xel.sum_order_qty               sum_order_qty           -- EDI明細情報.発注数量(合計、バラ)
        ,xel.sum_shipping_qty            sum_shipping_qty        -- EDI明細情報.出荷数量(合計、バラ)
        ,xel.sum_stockout_qty            sum_stockout_qty        -- EDI明細情報.欠品数量(合計、バラ)
        ,xel.last_updated_by             xel_last_updated_by     -- EDI明細情報.最終更新者
        ,xel.last_update_date            xel_last_update_date    -- EDI明細情報.最終更新日
        ,xel.last_update_login           xel_last_update_login   -- EDI明細情報.最終ログインID
        ,oola.ordered_item               ordered_item            -- 受注明細.受注品目
        ,oola.order_quantity_uom         order_quantity_uom      -- 受注明細.受注単位
        ,( SELECT /*+
                     INDEX(oola1 oe_order_lines_n1)
                  */
                  NVL( SUM( oola1.ordered_quantity ), 0 )
           FROM   oe_order_lines_all oola1
           WHERE  oola1.header_id = oola.header_id
           AND    (
                    ( oola1.line_id = oola.line_id )
                  OR
                    (
                      ( oola1.global_attribute3 = TO_CHAR( oola.line_id ) )
                      AND
                      ( oola1.global_attribute4 = xel.order_connection_line_number )
                    )
                  )
         )                               ordered_quantity        -- 受注明細.受注数量(分割考慮)
        ,iimb.attribute11                num_of_case             -- OPM品目.ケース入数
        ,xsib.bowl_inc_num               num_of_bowl             -- Disc品目アドオン.ボール入数
        ,DECODE( iimb.attribute21,
                 NULL, xel.product_code2,
                 iimb.attribute21 )      jan_code                -- JANコード
        ,DECODE( iimb.attribute21,
                 NULL, xel.product_name2_alt,
                 msib.description )      item_name               -- 商品名
        ,ooha.org_id                     org_id                  -- 受注ヘッダ.営業単位ID
        ,msib.organization_id            organization_id         -- Disc品目.在庫組織ID
/* 2010/06/16 Ver1.1 Add START */
        ,xca.delivery_base_code          base_code               --  顧客アドオン.納品拠点
/* 2010/06/16 Ver1.1 Add END   */
  FROM   xxcos_edi_headers     xeh   -- EDIヘッダ情報
        ,xxcos_edi_lines       xel   -- EDI明細情報
        ,oe_order_headers_all  ooha  -- 受注ヘッダ
        ,oe_order_lines_all    oola  -- 受注明細
        ,ic_item_mst_b         iimb  -- OPM品目
        ,mtl_system_items_b    msib  -- Disc品目
        ,xxcmm_system_items_b  xsib  -- Disc品目アドオン
/* 2010/06/16 Ver1.1 Add START */
        , xxcmm_cust_accounts   xca   --  顧客アドオン
/* 2010/06/16 Ver1.1 Add END   */
  WHERE  xeh.edi_header_info_id            =  xel.edi_header_info_id
  AND    xeh.edi_delivery_schedule_flag    =  'N'
  AND    xeh.order_connection_number       =  ooha.orig_sys_document_ref
  AND    xel.order_connection_line_number  =  oola.orig_sys_line_ref
  AND    ooha.header_id                    =  oola.header_id
  AND    (
           ( ooha.global_attribute3        =  '02' )
           OR
           ( ooha.global_attribute3        IS NULL )
         )
  AND    oola.inventory_item_id            =  msib.inventory_item_id
  AND    msib.segment1                     =  iimb.item_no
  AND    msib.segment1                     =  xsib.item_code
/* 2010/06/16 Ver1.1 Add START */
  AND    ooha.sold_to_org_id               =   xca.customer_id
/* 2010/06/16 Ver1.1 Add END   */
  ;
--
COMMENT ON COLUMN xxcos_dlv_packing_info_v.edi_header_info_id      IS 'EDIヘッダ情報ID';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.edi_chain_code          IS 'EDIチェーン店コード';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.shop_code               IS '店コード';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.shop_delivery_date      IS '店舗納品日';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.invoice_class           IS '伝票区分';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.delivery_schedule_flag  IS 'EDI納品予定送信済フラグ';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xeh_last_updated_by     IS '最終更新者(ヘッダ)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xeh_last_update_date    IS '最終更新日(ヘッダ)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xeh_last_update_login   IS '最終ログインID(ヘッダ)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.edi_line_info_id        IS 'EDI明細情報ID';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.product_code_itouen     IS '商品コード(伊藤園)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.packing_number          IS '梱包番号';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.sum_order_qty           IS '発注数量(合計、バラ)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.sum_shipping_qty        IS '出荷数量(合計、バラ)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.sum_stockout_qty        IS '欠品数量(合計、バラ)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xel_last_updated_by     IS '最終更新者(明細)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xel_last_update_date    IS '最終更新日(明細)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xel_last_update_login   IS '最終ログインID(明細)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.ordered_item            IS '受注品目';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.order_quantity_uom      IS '受注単位';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.ordered_quantity        IS '受注数量(分割考慮)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.num_of_case             IS 'ケース入数';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.num_of_bowl             IS 'ボール入数';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.jan_code                IS 'JANコード';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.item_name               IS '商品名';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.org_id                  IS '営業単位ID';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.organization_id         IS '在庫組織ID';
/* 2010/06/16 Ver1.1 Add START */
COMMENT ON COLUMN xxcos_dlv_packing_info_v.base_code               IS '拠点コード';
/* 2010/06/16 Ver1.1 Add END   */
--
COMMENT ON TABLE  xxcos_dlv_packing_info_v                         IS  '納品予定更新(荷番情報)画面view';
