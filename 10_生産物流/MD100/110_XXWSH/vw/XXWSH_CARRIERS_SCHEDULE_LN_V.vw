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
-- 2008/09/02 TE080_600wENo13Î Add D.Nihei Start
 AMOUNT_FIX_CLASS,
-- 2008/09/02 TE080_600wENo13Î Add D.Nihei End
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
      ,xoha.order_header_id             header_id                   -- ówb_ID
      ,NVL2(xcs.default_line_number,'0','1') default_line           -- î¾×
      ,xottv.shipping_shikyu_class      transaction_type           -- íÊR[h
      ,xlvv1.meaning                    transaction_type_name       -- íÊ¼Ì
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--      ,NVL(xoha.delivery_no,xoha.mixed_no) delivery_no              -- zNo
      ,xoha.delivery_no                 delivery_no              -- zNo
      ,xoha.request_no                  request_no                  -- ËNo
      ,xoha.career_id                   career_id                   -- ^ÆÒID
      ,xoha.freight_carrier_code        freight_carrier_code        -- ^ÆÒ
      ,xoha.shipping_method_code        shipping_method_code        -- zæª
      ,xlvv2.attribute6                 shipping_kubun_code         -- DFF¬ûæª
      ,xlvv2.attribute9                 mixed_class_code            -- DFF¬Úæª
      ,xottv.transaction_type_id        transaction_type_id         -- æø^CvID
      ,xoha.schedule_ship_date          schedule_ship_date          -- oÉ\èú
      ,xoha.schedule_arrival_date       schedule_arrival_date       -- ×\èú
-- 2008/09/02 TE080_600wENo13Î Add D.Nihei Start
      ,xoha.amount_fix_class            amount_fix_class            -- Làzmèæª
-- 2008/09/02 TE080_600wENo13Î Add D.Nihei End
      ,xoha.deliver_from                deliver_from                -- o×³ÛÇê
      ,xilv.description                 deliver_from_name           -- Ev
      ,xoha.deliver_to                  deliver_to                  -- o×æ
      ,xoha.vendor_site_code            vendor_site_code            -- æøæTCg
      ,xcasv.party_site_full_name       deliver_to_name             -- o×æ³®¼Ì
      ,xvsv.vendor_site_short_name      vendor_site_code_name       -- æøæTCgªÌ
      ,xoha.head_sales_branch           head_sales_branch           -- Ç_
      ,xcav.party_short_name            head_sales_branch_name      -- Ç_ªÌ
      ,xoha.vendor_code                 vendor_code                 -- æøæ
      ,xvv.vendor_short_name            vendor_short_name           -- æøæªÌ
      ,xoha.based_weight                based_weight                -- î{dÊ
      ,xoha.based_capacity              based_capacity              -- î{eÏ
      ,xoha.sum_weight                  sum_weight                  -- ÏÚdÊv
      ,xoha.sum_capacity                sum_capacity                -- ÏÚeÏv
      ,xoha.pallet_sum_quantity         pallet_sum_quantity         -- vpbg
      ,xoha.sum_pallet_weight           sum_pallet_weight           -- vpbgdÊ
      ,xoha.loading_efficiency_weight   loading_efficiency_weight   -- dÊÏÚø¦
      ,xoha.loading_efficiency_capacity loading_efficiency_capacity -- eÏÏÚø¦
      ,xoha.weight_capacity_class       weight_capacity_class       -- dÊeÏæª
      ,xoha.prod_class                  prod_class                  -- ¤iæª
      ,xoha.mixed_ratio                 mixed_ratio                 -- ¬Ú¦
      ,xoha.slip_number                 slip_number                 -- èóNo
      ,xoha.small_quantity              small_quantity              -- ¬ûÂ
      ,xoha.label_quantity              label_quantity              -- x
      ,xoha.mixed_sign                  mixed_sign                  -- ¬ÚL
      ,DECODE(xottv.shipping_shikyu_class
         ,'1',xoha.mixed_no
         ,'2',NULL)                     mixed_no                    -- ¬Ú³No
      ,xoha.result_freight_carrier_id   result_freight_carrier_id   -- ^ÆÒ_ÀÑID
      ,xoha.result_freight_carrier_code result_freight_carrier_code -- ^ÆÒ_ÀÑ
      ,xoha.result_shipping_method_code result_shipping_method_code -- zæª_ÀÑ
      ,xlvv3.attribute6                 result_shipping_kubun_code  -- DFF¬ûæª_ÀÑ
      ,xlvv3.attribute9                 result_mixed_class_code     -- DFF¬Úæª_ÀÑ
      ,xoha.result_deliver_to           result_deliver_to           -- o×æ_ÀÑ
      ,xcasv2.party_site_full_name      result_deliver_to_name      -- o×æ_ÀÑ¼Ì
      ,xoha.shipped_date                shipped_date                -- o×ú
      ,xoha.arrival_date                arrival_date                -- ×ú
      --
      ,xoha.req_status                  req_status                  -- Xe[^X
      ,xoha.notif_status                notif_status                -- ÊmXe[^X
      ,xoha.prev_notif_status           prev_notif_status           -- OñÊmXe[^X
      ,xoha.notif_date                  notif_date                  -- mèÊmÀ{ú
      ,xoha.new_modify_flg              new_modify_flg              -- VKC³tO
      ,xoha.screen_update_by            screen_update_by            -- æÊXVÒ
      ,xoha.screen_update_date          screen_update_date          -- æÊXVú
      ,xoha.prev_delivery_no            prev_delivery_no            -- Oñz
      ,xoha.actual_confirm_class        actual_confirm_class        -- ÀÑvãÏæª
      --
      ,xoha.created_by                  created_by                  -- ì¬Ò
      ,xoha.creation_date               creation_date               -- ì¬ú
      ,xoha.last_updated_by             last_updated_by             -- ÅIXVÒ
      ,xoha.last_update_date            last_update_date            -- ÅIXVú
      ,xoha.last_update_login           last_update_login           -- ÅIXVOC
FROM   xxwsh_order_headers_all      xoha   -- ówb_[
      ,xxwsh_oe_transaction_types_v xottv  -- ó^Cv
      ,xxwsh_carriers_schedule      xcs    -- zÔzvæ
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
AND   xlvv1.lookup_code(+)        = xottv.shipping_shikyu_class       -- íÊ
AND   xlvv2.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv2.lookup_code(+)        = xoha.shipping_method_code         -- zæª
AND   xlvv3.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv3.lookup_code(+)        = xoha.result_shipping_method_code  -- zæª_ÀÑ
AND   xilv.segment1(+)            = xoha.deliver_from                 -- o×³ÛÇê¼Ìæ¾
-- 2009/04/24 Y.Kazama {ÔáQ#1398Î(60A) Mod Start
AND   xcasv.party_site_number(+)  = xoha.deliver_to                   -- o×æ¼Ì
AND   xcasv2.party_site_number(+) = xoha.result_deliver_to            -- o×æ_ÀÑ¼Ì
--AND   xcasv.party_site_id(+)      = xoha.deliver_to_id
--AND   xcasv2.party_site_id(+)     = xoha.result_deliver_to_id
-- 2009/04/24 Y.Kazama {ÔáQ#1398Î(60A) Mod End
AND   xvsv.vendor_site_id(+)      = xoha.vendor_site_id               -- æøæTCg¼Ì
AND   xcav.party_number(+)        = xoha.head_sales_branch            -- Ç_¼Ì
AND   xcav.customer_class_code(+) = '1'                               -- Úqæª
AND   xvv.segment1(+)             = xoha.vendor_code                  -- æøæ¼Ì
AND   xcs.default_line_number (+) = xoha.request_no
AND   xcs.delivery_no (+)         = xoha.delivery_no
AND   xoha.order_type_id          = xottv.transaction_type_id
AND   xoha.latest_external_flag   = 'Y'
AND   (    (xottv.shipping_shikyu_class   = '1')
      OR   (xottv.shipping_shikyu_class = '2') )
AND   xoha.delivery_no IS NOT NULL
UNION ALL
SELECT xoha.rowid                       row_id
      ,xoha.order_header_id             header_id                   -- ówb_ID
      ,NVL2(xcs.default_line_number,'0','1') default_line           -- î¾×
      ,xottv.shipping_shikyu_class      transaction_type           -- íÊR[h
      ,xlvv1.meaning                    transaction_type_name       -- íÊ¼Ì
      ,xoha.mixed_no                    delivery_no              -- zNo
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
      ,xoha.request_no                  request_no                  -- ËNo
      ,xoha.career_id                   career_id                   -- ^ÆÒID
      ,xoha.freight_carrier_code        freight_carrier_code        -- ^ÆÒ
      ,xoha.shipping_method_code        shipping_method_code        -- zæª
      ,xlvv2.attribute6                 shipping_kubun_code         -- DFF¬ûæª
      ,xlvv2.attribute9                 mixed_class_code            -- DFF¬Úæª
      ,xottv.transaction_type_id        transaction_type_id         -- æø^CvID
      ,xoha.schedule_ship_date          schedule_ship_date          -- oÉ\èú
      ,xoha.schedule_arrival_date       schedule_arrival_date       -- ×\èú
-- 2008/09/02 TE080_600wENo13Î Add D.Nihei Start
      ,xoha.amount_fix_class            amount_fix_class            -- Làzmèæª
-- 2008/09/02 TE080_600wENo13Î Add D.Nihei End
      ,xoha.deliver_from                deliver_from                -- o×³ÛÇê
      ,xilv.description                 deliver_from_name           -- Ev
      ,xoha.deliver_to                  deliver_to                  -- o×æ
      ,xoha.vendor_site_code            vendor_site_code            -- æøæTCg
      ,xcasv.party_site_full_name       deliver_to_name             -- o×æ³®¼Ì
      ,xvsv.vendor_site_short_name      vendor_site_code_name       -- æøæTCgªÌ
      ,xoha.head_sales_branch           head_sales_branch           -- Ç_
      ,xcav.party_short_name            head_sales_branch_name      -- Ç_ªÌ
      ,xoha.vendor_code                 vendor_code                 -- æøæ
      ,xvv.vendor_short_name            vendor_short_name           -- æøæªÌ
      ,xoha.based_weight                based_weight                -- î{dÊ
      ,xoha.based_capacity              based_capacity              -- î{eÏ
      ,xoha.sum_weight                  sum_weight                  -- ÏÚdÊv
      ,xoha.sum_capacity                sum_capacity                -- ÏÚeÏv
      ,xoha.pallet_sum_quantity         pallet_sum_quantity         -- vpbg
      ,xoha.sum_pallet_weight           sum_pallet_weight           -- vpbgdÊ
      ,xoha.loading_efficiency_weight   loading_efficiency_weight   -- dÊÏÚø¦
      ,xoha.loading_efficiency_capacity loading_efficiency_capacity -- eÏÏÚø¦
      ,xoha.weight_capacity_class       weight_capacity_class       -- dÊeÏæª
      ,xoha.prod_class                  prod_class                  -- ¤iæª
      ,xoha.mixed_ratio                 mixed_ratio                 -- ¬Ú¦
      ,xoha.slip_number                 slip_number                 -- èóNo
      ,xoha.small_quantity              small_quantity              -- ¬ûÂ
      ,xoha.label_quantity              label_quantity              -- x
      ,xoha.mixed_sign                  mixed_sign                  -- ¬ÚL
      ,DECODE(xottv.shipping_shikyu_class
         ,'1',xoha.mixed_no
         ,'2',NULL)                     mixed_no                    -- ¬Ú³No
      ,xoha.result_freight_carrier_id   result_freight_carrier_id   -- ^ÆÒ_ÀÑID
      ,xoha.result_freight_carrier_code result_freight_carrier_code -- ^ÆÒ_ÀÑ
      ,xoha.result_shipping_method_code result_shipping_method_code -- zæª_ÀÑ
      ,xlvv3.attribute6                 result_shipping_kubun_code  -- DFF¬ûæª_ÀÑ
      ,xlvv3.attribute9                 result_mixed_class_code     -- DFF¬Úæª_ÀÑ
      ,xoha.result_deliver_to           result_deliver_to           -- o×æ_ÀÑ
      ,xcasv2.party_site_full_name      result_deliver_to_name      -- o×æ_ÀÑ¼Ì
      ,xoha.shipped_date                shipped_date                -- o×ú
      ,xoha.arrival_date                arrival_date                -- ×ú
      --
      ,xoha.req_status                  req_status                  -- Xe[^X
      ,xoha.notif_status                notif_status                -- ÊmXe[^X
      ,xoha.prev_notif_status           prev_notif_status           -- OñÊmXe[^X
      ,xoha.notif_date                  notif_date                  -- mèÊmÀ{ú
      ,xoha.new_modify_flg              new_modify_flg              -- VKC³tO
      ,xoha.screen_update_by            screen_update_by            -- æÊXVÒ
      ,xoha.screen_update_date          screen_update_date          -- æÊXVú
      ,xoha.prev_delivery_no            prev_delivery_no            -- Oñz
      ,xoha.actual_confirm_class        actual_confirm_class        -- ÀÑvãÏæª
      --
      ,xoha.created_by                  created_by                  -- ì¬Ò
      ,xoha.creation_date               creation_date               -- ì¬ú
      ,xoha.last_updated_by             last_updated_by             -- ÅIXVÒ
      ,xoha.last_update_date            last_update_date            -- ÅIXVú
      ,xoha.last_update_login           last_update_login           -- ÅIXVOC
FROM   xxwsh_order_headers_all      xoha   -- ówb_[
      ,xxwsh_oe_transaction_types_v xottv  -- ó^Cv
      ,xxwsh_carriers_schedule      xcs    -- zÔzvæ
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
AND   xlvv1.lookup_code(+)        = xottv.shipping_shikyu_class       -- íÊ
AND   xlvv2.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv2.lookup_code(+)        = xoha.shipping_method_code         -- zæª
AND   xlvv3.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv3.lookup_code(+)        = xoha.result_shipping_method_code  -- zæª_ÀÑ
AND   xilv.segment1(+)            = xoha.deliver_from                 -- o×³ÛÇê¼Ìæ¾
-- 2009/04/24 Y.Kazama {ÔáQ#1398Î(60A) Mod Start
AND   xcasv.party_site_number(+)  = xoha.deliver_to                   -- o×æ¼Ì
AND   xcasv2.party_site_number(+) = xoha.result_deliver_to            -- o×æ_ÀÑ¼Ì
--AND   xcasv.party_site_id(+)      = xoha.deliver_to_id
--AND   xcasv2.party_site_id(+)     = xoha.result_deliver_to_id
-- 2009/04/24 Y.Kazama {ÔáQ#1398Î(60A) Mod End
AND   xvsv.vendor_site_id(+)      = xoha.vendor_site_id               -- æøæTCg¼Ì
AND   xcav.party_number(+)        = xoha.head_sales_branch            -- Ç_¼Ì
AND   xcav.customer_class_code(+) = '1'                               -- Úqæª
AND   xvv.segment1(+)             = xoha.vendor_code                  -- æøæ¼Ì
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
      ,xmrih.mov_hdr_id                       header_id               -- Ú®wb_ID
      ,NVL2(xcs.default_line_number,'0','1') default_line            -- î¾×
      ,'3'                                transaction_type            -- íÊR[h
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--      ,xlvv1.meaning                      transaction_type_name       -- íÊ¼Ì
      ,(SELECT  xlvv1.meaning
        FROM    xxcmn_lookup_values_v xlvv1
        WHERE   xlvv1.lookup_type = 'XXWSH_PROCESS_TYPE'
        AND     xlvv1.lookup_code = '3'
        AND     ROWNUM            = 1  )  transaction_type_name       -- íÊ¼Ì
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
      ,xmrih.delivery_no                  delivery_no                 -- zNo
      ,xmrih.mov_num                      request_no                  -- ËNo/Ú®No
      ,xmrih.career_id                    career_id                   -- ^ÆÒID
      ,xmrih.freight_carrier_code         freight_carrier_code        -- ^ÆÒ
      ,xmrih.shipping_method_code         shipping_method_code        -- zæª
      ,xlvv2.attribute6                   shipping_kubun_code         -- DFF¬ûæª
      ,xlvv2.attribute9                   mixed_class_code            -- DFF¬Úæª
      ,NULL                               transaction_type_id         -- æø^CvID
      ,xmrih.schedule_ship_date           schedule_ship_date          -- oÉ\èú
      ,xmrih.schedule_arrival_date        schedule_arrival_date       -- ×\èú
-- 2008/09/02 TE080_600wENo13Î Add D.Nihei Start
      ,NULL                               amount_fix_class            -- Làzmèæª
-- 2008/09/02 TE080_600wENo13Î Add D.Nihei End
      ,xmrih.shipped_locat_code           deliver_from                -- o×³ÛÇê
      ,xilv.description                   deliver_from_name           -- Ev
      ,xmrih.ship_to_locat_code           deliver_to                  -- o×æ
      ,NULL                               vendor_site_code            -- æøæTCg
      ,xilv2.description                  deliver_to_name             -- ³®¼Ì
      ,NULL                               vendor_site_code_name       -- æøæTCgªÌ
      ,NULL                               head_sales_branch           -- Ç_
      ,NULL                               head_sales_branch_name      -- Ç_ªÌ
      ,NULL                               vendor_code                 -- æøæ
      ,NULL                               vendor_short_name           -- æøæªÌ
      ,xmrih.based_weight                 based_weight                -- î{dÊ
      ,xmrih.based_capacity               based_capacity              -- î{eÏ
      ,xmrih.sum_weight                   sum_weight                  -- ÏÚdÊv
      ,xmrih.sum_capacity                 sum_capacity                -- ÏÚeÏv
      ,xmrih.pallet_sum_quantity          pallet_sum_quantity         -- vpbg
      ,xmrih.sum_pallet_weight            sum_pallet_weight           -- vpbgdÊ
      ,xmrih.loading_efficiency_weight    loading_efficiency_weight   -- dÊÏÚø¦
      ,xmrih.loading_efficiency_capacity  loading_efficiency_capacity -- eÏÏÚø¦
      ,xmrih.weight_capacity_class        weight_capacity_class       -- dÊeÏæª
      ,xmrih.item_class                   prod_class                  -- ¤iæª
      ,xmrih.mixed_ratio                  mixed_ratio                 -- ¬Ú¦
      ,xmrih.slip_number                  slip_number                 -- èóNo
      ,xmrih.small_quantity               small_quantity              -- ¬ûÂ
      ,xmrih.label_quantity               label_quantity              -- x
      ,xmrih.mixed_sign                   mixed_sign                  -- ¬ÚL
      ,NULL                               mixed_no                    -- ¬Ú³No
      ,xmrih.actual_career_id             result_freight_carrier_id   -- ^ÆÒ_ÀÑID
      ,xmrih.actual_freight_carrier_code  result_freight_carrier_code -- ^ÆÒ_ÀÑ
      ,xmrih.actual_shipping_method_code  result_shipping_method_code -- zæª_ÀÑ
      ,xlvv3.attribute6                   result_shipping_kubun_code  -- DFF¬ûæª_ÀÑ
      ,xlvv3.attribute9                   result_mixed_class_code     -- DFF¬Úæª_ÀÑ
      ,NULL                               result_deliver_to           -- o×æ_ÀÑ
      ,NULL                               result_deliver_to_name      -- o×æ_ÀÑ¼Ì
      ,xmrih.actual_ship_date             shipped_date                -- o×ú
      ,xmrih.actual_arrival_date          arrival_date                -- ×ú
      --
      ,xmrih.status                       req_status                  -- Xe[^X
      ,xmrih.notif_status                 notif_status                -- ÊmXe[^X
      ,xmrih.prev_notif_status            prev_notif_status           -- OñÊmXe[^X
      ,xmrih.notif_date                   notif_date                  -- mèÊmÀ{ú
      ,xmrih.new_modify_flg               new_modify_flg              -- VKC³tO
      ,xmrih.screen_update_by             screen_update_by            -- æÊXVÒ
      ,xmrih.screen_update_date           screen_update_date          -- æÊXVú
      ,xmrih.prev_delivery_no             prev_delivery_no            -- Oñz
      ,xmrih.comp_actual_flg              actual_confirm_class        -- ÀÑvãÏæª
      --
      ,xmrih.created_by                   created_by                  -- ì¬Ò
      ,xmrih.creation_date                creation_date               -- ì¬ú
      ,xmrih.last_updated_by              last_updated_by             -- ÅIXVÒ
      ,xmrih.last_update_date             last_update_date            -- ÅIXVú
      ,xmrih.last_update_login            last_update_login           -- ÅIXVOC
FROM   xxinv_mov_req_instr_headers xmrih
      ,xxwsh_carriers_schedule     xcs    -- zÔzvæ
-- 2008/09/02 PT1-1_4 Del D.Nihei Start
--      ,xxcmn_lookup_values_v       xlvv1
-- 2008/09/02 PT1-1_4 Del D.Nihei End
      ,xxcmn_lookup_values_v       xlvv2
      ,xxcmn_lookup_values_v       xlvv3
      ,xxcmn_item_locations_v      xilv
      ,xxcmn_item_locations_v      xilv2
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--WHERE  xlvv1.lookup_type          = 'XXWSH_PROCESS_TYPE' 
--AND    xlvv1.lookup_code          = '3'                                -- íÊ
WHERE  xlvv2.lookup_type(+)       = 'XXCMN_SHIP_METHOD'
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
AND    xlvv2.lookup_code(+)       = xmrih.shipping_method_code         -- zæª
AND    xlvv3.lookup_type(+)       = 'XXCMN_SHIP_METHOD'
AND    xlvv3.lookup_code(+)       = xmrih.actual_shipping_method_code  -- zæª_ÀÑ
AND    xilv.segment1(+)           = xmrih.shipped_locat_code           -- o×³ÛÇê¼Ìæ¾
AND    xilv2.segment1(+)          = xmrih.ship_to_locat_code           -- o×æÛÇê¼æ¾
AND    xcs.default_line_number(+) = xmrih.mov_num
AND    xcs.delivery_no (+)        = xmrih.delivery_no
AND    xmrih.delivery_no IS NOT NULL;
