CREATE OR REPLACE VIEW apps.xxwsh_carriers_schedule_ln_v
(ROW_ID,
 HEADER_ID,
 DEFAULT_LINE,
 TRANSACTION_TYPE,
 TRANSACTION_TYPE_NAME,
 DELIVERY_NO,
 REQUEST_NO,
 CAREER_ID,
 FREIGHT_CARRIER_CODE,
 SHIPPING_METHOD_CODE,
 SHIPPING_KUBUN_CODE,
 MIXED_CLASS_CODE,
 TRANSACTION_TYPE_ID,
 SCHEDULE_SHIP_DATE,
 SCHEDULE_ARRIVAL_DATE,
-- 2008/09/02 TE080_600指摘No13対応 Add D.Nihei Start
 AMOUNT_FIX_CLASS,
-- 2008/09/02 TE080_600指摘No13対応 Add D.Nihei End
 DELIVER_FROM,
 DELIVER_FROM_NAME,
 DELIVER_TO,
 VENDOR_SITE_CODE,
 DELIVER_TO_NAME,
 VENDOR_SITE_CODE_NAME,
 HEAD_SALES_BRANCH,
 HEAD_SALES_BRANCH_NAME,
 VENDOR_CODE,
 VENDOR_SHORT_NAME,
 BASED_WEIGHT,
 BASED_CAPACITY,
 SUM_WEIGHT,
 SUM_CAPACITY,
 PALLET_SUM_QUANTITY,
 SUM_PALLET_WEIGHT,
 LOADING_EFFICIENCY_WEIGHT,
 LOADING_EFFICIENCY_CAPACITY,
 WEIGHT_CAPACITY_CLASS,
 PROD_CLASS,
 MIXED_RATIO,
 SLIP_NUMBER,
 SMALL_QUANTITY,
 LABEL_QUANTITY,
 MIXED_SIGN,
 MIXED_NO,
 RESULT_FREIGHT_CARRIER_ID,
 RESULT_FREIGHT_CARRIER_CODE,
 RESULT_SHIPPING_METHOD_CODE,
 RESULT_SHIPPING_KUBUN_CODE,
 RESULT_MIXED_CLASS_CODE,
 RESULT_DELIVER_TO,
 RESULT_DELIVER_TO_NAME,
 SHIPPED_DATE,
 ARRIVAL_DATE,
 REQ_STATUS,
 NOTIF_STATUS,
 PREV_NOTIF_STATUS,
 NOTIF_DATE,
 NEW_MODIFY_FLG,
 SCREEN_UPDATE_BY,
 SCREEN_UPDATE_DATE,
 PREV_DELIVERY_NO,
 ACTUAL_CONFIRM_CLASS,
 CREATED_BY,
 CREATION_DATE,
 LAST_UPDATED_BY,
 LAST_UPDATE_DATE,
 LAST_UPDATE_LOGIN
) AS 
SELECT xoha.rowid                       row_id
      ,xoha.order_header_id             header_id                   -- 受注ヘッダID
      ,NVL2(xcs.default_line_number,'0','1') default_line           -- 基準明細
      ,xottv.shipping_shikyu_class      transaction_type           -- 処理種別コード
      ,xlvv1.meaning                    transaction_type_name       -- 処理種別名称
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--      ,NVL(xoha.delivery_no,xoha.mixed_no) delivery_no              -- 配送No
      ,xoha.delivery_no                 delivery_no              -- 配送No
      ,xoha.request_no                  request_no                  -- 依頼No
      ,xoha.career_id                   career_id                   -- 運送業者ID
      ,xoha.freight_carrier_code        freight_carrier_code        -- 運送業者
      ,xoha.shipping_method_code        shipping_method_code        -- 配送区分
      ,xlvv2.attribute6                 shipping_kubun_code         -- DFF小口区分
      ,xlvv2.attribute9                 mixed_class_code            -- DFF混載区分
      ,xottv.transaction_type_id        transaction_type_id         -- 取引タイプID
      ,xoha.schedule_ship_date          schedule_ship_date          -- 出庫予定日
      ,xoha.schedule_arrival_date       schedule_arrival_date       -- 着荷予定日
-- 2008/09/02 TE080_600指摘No13対応 Add D.Nihei Start
      ,xoha.amount_fix_class            amount_fix_class            -- 有償金額確定区分
-- 2008/09/02 TE080_600指摘No13対応 Add D.Nihei End
      ,xoha.deliver_from                deliver_from                -- 出荷元保管場所
      ,xilv.description                 deliver_from_name           -- 摘要
      ,xoha.deliver_to                  deliver_to                  -- 出荷先
      ,xoha.vendor_site_code            vendor_site_code            -- 取引先サイト
      ,xcasv.party_site_full_name       deliver_to_name             -- 出荷先正式名称
      ,xvsv.vendor_site_short_name      vendor_site_code_name       -- 取引先サイト略称
      ,xoha.head_sales_branch           head_sales_branch           -- 管轄拠点
      ,xcav.party_short_name            head_sales_branch_name      -- 管轄拠点略称
      ,xoha.vendor_code                 vendor_code                 -- 取引先
      ,xvv.vendor_short_name            vendor_short_name           -- 取引先略称
      ,xoha.based_weight                based_weight                -- 基本重量
      ,xoha.based_capacity              based_capacity              -- 基本容積
      ,xoha.sum_weight                  sum_weight                  -- 積載重量合計
      ,xoha.sum_capacity                sum_capacity                -- 積載容積合計
      ,xoha.pallet_sum_quantity         pallet_sum_quantity         -- 合計パレット枚数
      ,xoha.sum_pallet_weight           sum_pallet_weight           -- 合計パレット重量
      ,xoha.loading_efficiency_weight   loading_efficiency_weight   -- 重量積載効率
      ,xoha.loading_efficiency_capacity loading_efficiency_capacity -- 容積積載効率
      ,xoha.weight_capacity_class       weight_capacity_class       -- 重量容積区分
      ,xoha.prod_class                  prod_class                  -- 商品区分
      ,xoha.mixed_ratio                 mixed_ratio                 -- 混載率
      ,xoha.slip_number                 slip_number                 -- 送り状No
      ,xoha.small_quantity              small_quantity              -- 小口個数
      ,xoha.label_quantity              label_quantity              -- ラベル枚数
      ,xoha.mixed_sign                  mixed_sign                  -- 混載記号
      ,DECODE(xottv.shipping_shikyu_class
         ,'1',xoha.mixed_no
         ,'2',NULL)                     mixed_no                    -- 混載元No
      ,xoha.result_freight_carrier_id   result_freight_carrier_id   -- 運送業者_実績ID
      ,xoha.result_freight_carrier_code result_freight_carrier_code -- 運送業者_実績
      ,xoha.result_shipping_method_code result_shipping_method_code -- 配送区分_実績
      ,xlvv3.attribute6                 result_shipping_kubun_code  -- DFF小口区分_実績
      ,xlvv3.attribute9                 result_mixed_class_code     -- DFF混載区分_実績
      ,xoha.result_deliver_to           result_deliver_to           -- 出荷先_実績
      ,xcasv2.party_site_full_name      result_deliver_to_name      -- 出荷先_実績名称
      ,xoha.shipped_date                shipped_date                -- 出荷日
      ,xoha.arrival_date                arrival_date                -- 着荷日
      --
      ,xoha.req_status                  req_status                  -- ステータス
      ,xoha.notif_status                notif_status                -- 通知ステータス
      ,xoha.prev_notif_status           prev_notif_status           -- 前回通知ステータス
      ,xoha.notif_date                  notif_date                  -- 確定通知実施日時
      ,xoha.new_modify_flg              new_modify_flg              -- 新規修正フラグ
      ,xoha.screen_update_by            screen_update_by            -- 画面更新者
      ,xoha.screen_update_date          screen_update_date          -- 画面更新日時
      ,xoha.prev_delivery_no            prev_delivery_no            -- 前回配送№
      ,xoha.actual_confirm_class        actual_confirm_class        -- 実績計上済区分
      --
      ,xoha.created_by                  created_by                  -- 作成者
      ,xoha.creation_date               creation_date               -- 作成日
      ,xoha.last_updated_by             last_updated_by             -- 最終更新者
      ,xoha.last_update_date            last_update_date            -- 最終更新日
      ,xoha.last_update_login           last_update_login           -- 最終更新ログイン
FROM   xxwsh_order_headers_all      xoha   -- 受注ヘッダー
      ,xxwsh_oe_transaction_types_v xottv  -- 受注タイプ
      ,xxwsh_carriers_schedule      xcs    -- 配車配送計画
      ,xxcmn_lookup_values_v        xlvv1
      ,xxcmn_lookup_values_v        xlvv2
      ,xxcmn_lookup_values_v        xlvv3
      ,xxcmn_item_locations_v       xilv
      ,xxcmn_cust_acct_sites_v      xcasv
      ,xxcmn_cust_acct_sites_v      xcasv2
      ,xxcmn_vendor_sites_v         xvsv
      ,xxcmn_cust_accounts_v        xcav
      ,xxcmn_vendors_v              xvv
WHERE xlvv1.lookup_type(+)        = 'XXWSH_PROCESS_TYPE'
AND   xlvv1.lookup_code(+)        = xottv.shipping_shikyu_class       -- 処理種別
AND   xlvv2.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv2.lookup_code(+)        = xoha.shipping_method_code         -- 配送区分
AND   xlvv3.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv3.lookup_code(+)        = xoha.result_shipping_method_code  -- 配送区分_実績
AND   xilv.segment1(+)            = xoha.deliver_from                 -- 出荷元保管場所名称取得
AND   xcasv.party_site_id(+)      = xoha.deliver_to_id                -- 出荷先名称
AND   xcasv2.party_site_id(+)     = xoha.result_deliver_to_id         -- 出荷先_実績名称
AND   xvsv.vendor_site_id(+)      = xoha.vendor_site_id               -- 取引先サイト名称
AND   xcav.party_number(+)        = xoha.head_sales_branch            -- 管轄拠点名称
AND   xcav.customer_class_code(+) = '1'                               -- 顧客区分
AND   xvv.segment1(+)             = xoha.vendor_code                  -- 取引先名称
AND   xcs.default_line_number (+) = xoha.request_no
AND   xcs.delivery_no (+)         = xoha.delivery_no
AND   xoha.order_type_id          = xottv.transaction_type_id
AND   xoha.latest_external_flag   = 'Y'
AND   (    (xottv.shipping_shikyu_class   = '1')
      OR   (xottv.shipping_shikyu_class = '2') )
AND   xoha.delivery_no IS NOT NULL
UNION ALL
SELECT xoha.rowid                       row_id
      ,xoha.order_header_id             header_id                   -- 受注ヘッダID
      ,NVL2(xcs.default_line_number,'0','1') default_line           -- 基準明細
      ,xottv.shipping_shikyu_class      transaction_type           -- 処理種別コード
      ,xlvv1.meaning                    transaction_type_name       -- 処理種別名称
      ,xoha.mixed_no                    delivery_no              -- 配送No
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
      ,xoha.request_no                  request_no                  -- 依頼No
      ,xoha.career_id                   career_id                   -- 運送業者ID
      ,xoha.freight_carrier_code        freight_carrier_code        -- 運送業者
      ,xoha.shipping_method_code        shipping_method_code        -- 配送区分
      ,xlvv2.attribute6                 shipping_kubun_code         -- DFF小口区分
      ,xlvv2.attribute9                 mixed_class_code            -- DFF混載区分
      ,xottv.transaction_type_id        transaction_type_id         -- 取引タイプID
      ,xoha.schedule_ship_date          schedule_ship_date          -- 出庫予定日
      ,xoha.schedule_arrival_date       schedule_arrival_date       -- 着荷予定日
-- 2008/09/02 TE080_600指摘No13対応 Add D.Nihei Start
      ,xoha.amount_fix_class            amount_fix_class            -- 有償金額確定区分
-- 2008/09/02 TE080_600指摘No13対応 Add D.Nihei End
      ,xoha.deliver_from                deliver_from                -- 出荷元保管場所
      ,xilv.description                 deliver_from_name           -- 摘要
      ,xoha.deliver_to                  deliver_to                  -- 出荷先
      ,xoha.vendor_site_code            vendor_site_code            -- 取引先サイト
      ,xcasv.party_site_full_name       deliver_to_name             -- 出荷先正式名称
      ,xvsv.vendor_site_short_name      vendor_site_code_name       -- 取引先サイト略称
      ,xoha.head_sales_branch           head_sales_branch           -- 管轄拠点
      ,xcav.party_short_name            head_sales_branch_name      -- 管轄拠点略称
      ,xoha.vendor_code                 vendor_code                 -- 取引先
      ,xvv.vendor_short_name            vendor_short_name           -- 取引先略称
      ,xoha.based_weight                based_weight                -- 基本重量
      ,xoha.based_capacity              based_capacity              -- 基本容積
      ,xoha.sum_weight                  sum_weight                  -- 積載重量合計
      ,xoha.sum_capacity                sum_capacity                -- 積載容積合計
      ,xoha.pallet_sum_quantity         pallet_sum_quantity         -- 合計パレット枚数
      ,xoha.sum_pallet_weight           sum_pallet_weight           -- 合計パレット重量
      ,xoha.loading_efficiency_weight   loading_efficiency_weight   -- 重量積載効率
      ,xoha.loading_efficiency_capacity loading_efficiency_capacity -- 容積積載効率
      ,xoha.weight_capacity_class       weight_capacity_class       -- 重量容積区分
      ,xoha.prod_class                  prod_class                  -- 商品区分
      ,xoha.mixed_ratio                 mixed_ratio                 -- 混載率
      ,xoha.slip_number                 slip_number                 -- 送り状No
      ,xoha.small_quantity              small_quantity              -- 小口個数
      ,xoha.label_quantity              label_quantity              -- ラベル枚数
      ,xoha.mixed_sign                  mixed_sign                  -- 混載記号
      ,DECODE(xottv.shipping_shikyu_class
         ,'1',xoha.mixed_no
         ,'2',NULL)                     mixed_no                    -- 混載元No
      ,xoha.result_freight_carrier_id   result_freight_carrier_id   -- 運送業者_実績ID
      ,xoha.result_freight_carrier_code result_freight_carrier_code -- 運送業者_実績
      ,xoha.result_shipping_method_code result_shipping_method_code -- 配送区分_実績
      ,xlvv3.attribute6                 result_shipping_kubun_code  -- DFF小口区分_実績
      ,xlvv3.attribute9                 result_mixed_class_code     -- DFF混載区分_実績
      ,xoha.result_deliver_to           result_deliver_to           -- 出荷先_実績
      ,xcasv2.party_site_full_name      result_deliver_to_name      -- 出荷先_実績名称
      ,xoha.shipped_date                shipped_date                -- 出荷日
      ,xoha.arrival_date                arrival_date                -- 着荷日
      --
      ,xoha.req_status                  req_status                  -- ステータス
      ,xoha.notif_status                notif_status                -- 通知ステータス
      ,xoha.prev_notif_status           prev_notif_status           -- 前回通知ステータス
      ,xoha.notif_date                  notif_date                  -- 確定通知実施日時
      ,xoha.new_modify_flg              new_modify_flg              -- 新規修正フラグ
      ,xoha.screen_update_by            screen_update_by            -- 画面更新者
      ,xoha.screen_update_date          screen_update_date          -- 画面更新日時
      ,xoha.prev_delivery_no            prev_delivery_no            -- 前回配送№
      ,xoha.actual_confirm_class        actual_confirm_class        -- 実績計上済区分
      --
      ,xoha.created_by                  created_by                  -- 作成者
      ,xoha.creation_date               creation_date               -- 作成日
      ,xoha.last_updated_by             last_updated_by             -- 最終更新者
      ,xoha.last_update_date            last_update_date            -- 最終更新日
      ,xoha.last_update_login           last_update_login           -- 最終更新ログイン
FROM   xxwsh_order_headers_all      xoha   -- 受注ヘッダー
      ,xxwsh_oe_transaction_types_v xottv  -- 受注タイプ
      ,xxwsh_carriers_schedule      xcs    -- 配車配送計画
      ,xxcmn_lookup_values_v        xlvv1
      ,xxcmn_lookup_values_v        xlvv2
      ,xxcmn_lookup_values_v        xlvv3
      ,xxcmn_item_locations_v       xilv
      ,xxcmn_cust_acct_sites_v      xcasv
      ,xxcmn_cust_acct_sites_v      xcasv2
      ,xxcmn_vendor_sites_v         xvsv
      ,xxcmn_cust_accounts_v        xcav
      ,xxcmn_vendors_v              xvv
WHERE xlvv1.lookup_type(+)        = 'XXWSH_PROCESS_TYPE'
AND   xlvv1.lookup_code(+)        = xottv.shipping_shikyu_class       -- 処理種別
AND   xlvv2.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv2.lookup_code(+)        = xoha.shipping_method_code         -- 配送区分
AND   xlvv3.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv3.lookup_code(+)        = xoha.result_shipping_method_code  -- 配送区分_実績
AND   xilv.segment1(+)            = xoha.deliver_from                 -- 出荷元保管場所名称取得
AND   xcasv.party_site_id(+)      = xoha.deliver_to_id                -- 出荷先名称
AND   xcasv2.party_site_id(+)     = xoha.result_deliver_to_id         -- 出荷先_実績名称
AND   xvsv.vendor_site_id(+)      = xoha.vendor_site_id               -- 取引先サイト名称
AND   xcav.party_number(+)        = xoha.head_sales_branch            -- 管轄拠点名称
AND   xcav.customer_class_code(+) = '1'                               -- 顧客区分
AND   xvv.segment1(+)             = xoha.vendor_code                  -- 取引先名称
AND   xcs.default_line_number (+) = xoha.request_no
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--AND   xcs.delivery_no (+)         = NVL(xoha.delivery_no,xoha.mixed_no)
AND   xcs.delivery_no (+)         = xoha.mixed_no
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
AND   xoha.order_type_id          = xottv.transaction_type_id
AND   xoha.latest_external_flag   = 'Y'
AND   (    (xottv.shipping_shikyu_class   = '1')
      OR (   (xottv.shipping_shikyu_class = '2')
         AND (xoha.delivery_no IS NOT NULL)))
-- 2008/09/02 PT1-1_4 Add D.Nihei Start
AND   xoha.delivery_no IS NULL
-- 2008/09/02 PT1-1_4 Add D.Nihei End
UNION ALL
SELECT xmrih.rowid                        row_id
      ,xmrih.mov_hdr_id                       header_id               -- 移動ヘッダID
      ,NVL2(xcs.default_line_number,'0','1') default_line            -- 基準明細
      ,'3'                                transaction_type            -- 処理種別コード
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--      ,xlvv1.meaning                      transaction_type_name       -- 処理種別名称
      ,(SELECT  xlvv1.meaning
        FROM    xxcmn_lookup_values_v xlvv1
        WHERE   xlvv1.lookup_type = 'XXWSH_PROCESS_TYPE'
        AND     xlvv1.lookup_code = '3'
        AND     ROWNUM            = 1  )  transaction_type_name       -- 処理種別名称
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
      ,xmrih.delivery_no                  delivery_no                 -- 配送No
      ,xmrih.mov_num                      request_no                  -- 依頼No/移動No
      ,xmrih.career_id                    career_id                   -- 運送業者ID
      ,xmrih.freight_carrier_code         freight_carrier_code        -- 運送業者
      ,xmrih.shipping_method_code         shipping_method_code        -- 配送区分
      ,xlvv2.attribute6                   shipping_kubun_code         -- DFF小口区分
      ,xlvv2.attribute9                   mixed_class_code            -- DFF混載区分
      ,NULL                               transaction_type_id         -- 取引タイプID
      ,xmrih.schedule_ship_date           schedule_ship_date          -- 出庫予定日
      ,xmrih.schedule_arrival_date        schedule_arrival_date       -- 着荷予定日
-- 2008/09/02 TE080_600指摘No13対応 Add D.Nihei Start
      ,NULL                               amount_fix_class            -- 有償金額確定区分
-- 2008/09/02 TE080_600指摘No13対応 Add D.Nihei End
      ,xmrih.shipped_locat_code           deliver_from                -- 出荷元保管場所
      ,xilv.description                   deliver_from_name           -- 摘要
      ,xmrih.ship_to_locat_code           deliver_to                  -- 出荷先
      ,NULL                               vendor_site_code            -- 取引先サイト
      ,xilv2.description                  deliver_to_name             -- 正式名称
      ,NULL                               vendor_site_code_name       -- 取引先サイト略称
      ,NULL                               head_sales_branch           -- 管轄拠点
      ,NULL                               head_sales_branch_name      -- 管轄拠点略称
      ,NULL                               vendor_code                 -- 取引先
      ,NULL                               vendor_short_name           -- 取引先略称
      ,xmrih.based_weight                 based_weight                -- 基本重量
      ,xmrih.based_capacity               based_capacity              -- 基本容積
      ,xmrih.sum_weight                   sum_weight                  -- 積載重量合計
      ,xmrih.sum_capacity                 sum_capacity                -- 積載容積合計
      ,xmrih.pallet_sum_quantity          pallet_sum_quantity         -- 合計パレット枚数
      ,xmrih.sum_pallet_weight            sum_pallet_weight           -- 合計パレット重量
      ,xmrih.loading_efficiency_weight    loading_efficiency_weight   -- 重量積載効率
      ,xmrih.loading_efficiency_capacity  loading_efficiency_capacity -- 容積積載効率
      ,xmrih.weight_capacity_class        weight_capacity_class       -- 重量容積区分
      ,xmrih.item_class                   prod_class                  -- 商品区分
      ,xmrih.mixed_ratio                  mixed_ratio                 -- 混載率
      ,xmrih.slip_number                  slip_number                 -- 送り状No
      ,xmrih.small_quantity               small_quantity              -- 小口個数
      ,xmrih.label_quantity               label_quantity              -- ラベル枚数
      ,xmrih.mixed_sign                   mixed_sign                  -- 混載記号
      ,NULL                               mixed_no                    -- 混載元No
      ,xmrih.actual_career_id             result_freight_carrier_id   -- 運送業者_実績ID
      ,xmrih.actual_freight_carrier_code  result_freight_carrier_code -- 運送業者_実績
      ,xmrih.actual_shipping_method_code  result_shipping_method_code -- 配送区分_実績
      ,xlvv3.attribute6                   result_shipping_kubun_code  -- DFF小口区分_実績
      ,xlvv3.attribute9                   result_mixed_class_code     -- DFF混載区分_実績
      ,NULL                               result_deliver_to           -- 出荷先_実績
      ,NULL                               result_deliver_to_name      -- 出荷先_実績名称
      ,xmrih.actual_ship_date             shipped_date                -- 出荷日
      ,xmrih.actual_arrival_date          arrival_date                -- 着荷日
      --
      ,xmrih.status                       req_status                  -- ステータス
      ,xmrih.notif_status                 notif_status                -- 通知ステータス
      ,xmrih.prev_notif_status            prev_notif_status           -- 前回通知ステータス
      ,xmrih.notif_date                   notif_date                  -- 確定通知実施日時
      ,xmrih.new_modify_flg               new_modify_flg              -- 新規修正フラグ
      ,xmrih.screen_update_by             screen_update_by            -- 画面更新者
      ,xmrih.screen_update_date           screen_update_date          -- 画面更新日時
      ,xmrih.prev_delivery_no             prev_delivery_no            -- 前回配送№
      ,xmrih.comp_actual_flg              actual_confirm_class        -- 実績計上済区分
      --
      ,xmrih.created_by                   created_by                  -- 作成者
      ,xmrih.creation_date                creation_date               -- 作成日
      ,xmrih.last_updated_by              last_updated_by             -- 最終更新者
      ,xmrih.last_update_date             last_update_date            -- 最終更新日
      ,xmrih.last_update_login            last_update_login           -- 最終更新ログイン
FROM   xxinv_mov_req_instr_headers xmrih
      ,xxwsh_carriers_schedule     xcs    -- 配車配送計画
-- 2008/09/02 PT1-1_4 Del D.Nihei Start
--      ,xxcmn_lookup_values_v       xlvv1
-- 2008/09/02 PT1-1_4 Del D.Nihei End
      ,xxcmn_lookup_values_v       xlvv2
      ,xxcmn_lookup_values_v       xlvv3
      ,xxcmn_item_locations_v      xilv
      ,xxcmn_item_locations_v      xilv2
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--WHERE  xlvv1.lookup_type          = 'XXWSH_PROCESS_TYPE' 
--AND    xlvv1.lookup_code          = '3'                                -- 処理種別
WHERE  xlvv2.lookup_type(+)       = 'XXCMN_SHIP_METHOD'
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
AND    xlvv2.lookup_code(+)       = xmrih.shipping_method_code         -- 配送区分
AND    xlvv3.lookup_type(+)       = 'XXCMN_SHIP_METHOD'
AND    xlvv3.lookup_code(+)       = xmrih.actual_shipping_method_code  -- 配送区分_実績
AND    xilv.segment1(+)           = xmrih.shipped_locat_code           -- 出荷元保管場所名称取得
AND    xilv2.segment1(+)          = xmrih.ship_to_locat_code           -- 出荷先保管場所名取得
AND    xcs.default_line_number(+) = xmrih.mov_num
AND    xcs.delivery_no (+)        = xmrih.delivery_no
AND    xmrih.delivery_no IS NOT NULL;
