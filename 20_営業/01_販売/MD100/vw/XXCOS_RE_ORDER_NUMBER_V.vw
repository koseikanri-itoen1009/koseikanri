/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_re_order_number_v
 * Description     : 再送受注番号取得
 * Version         : 1.3
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/05/22    1.0   T.Kitajima       新規作成
 *  2009/06/04    1.1   T.Miyata         T1_1314対応
 *  2009/07/07    1.2   T.Miyata         0000478対応
 *  2009/07/14    1.3   K.Kiriu          0000063対応
 *  2009/10/21    1.4   K.Atsushiba      0001113対応
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_re_order_number_v (
  order_number,                         -- 受注番号
  shipping_instructions                 -- 出荷指示
/* 2009/10/21 Ver1.4 Add Start */
  ,delivery_base_code                   -- 納品拠点
/* 2009/10/21 Ver1.4 Add End */
)
AS
  SELECT DISTINCT
         ooha.order_number                               order_number
         ,SUBSTRB( ooha.shipping_instructions, 1, 20 )   shipping_instructions
/* 2009/10/21 Ver1.4 Add Start */
         ,xca.delivery_base_code                         delivery_base_code
/* 2009/10/21 Ver1.4 Add End */
  FROM   oe_order_headers_all                   ooha               -- 受注ヘッダ
        ,oe_order_lines_all                     oola               -- 受注明細
        ,hz_cust_accounts                       hca                -- 顧客マスタ
        ,mtl_system_items_b                     msib               -- 品目マスタ
        ,oe_transaction_types_tl                ottah              -- 受注取引タイプ（受注ヘッダ用）
        ,oe_transaction_types_tl                ottal              -- 受注取引タイプ（受注明細用）
        ,mtl_secondary_inventories              msi                -- 保管場所マスタ
        ,xxcmn_item_categories5_v               xicv               -- 商品区分View
        ,xxcmm_cust_accounts                    xca                -- 顧客追加情報
        ,hz_cust_acct_sites_all                 sites              -- 顧客所在地
        ,hz_cust_site_uses_all                  uses               -- 顧客使用目的
        ,hz_party_sites                         hps                -- パーティサイトマスタ
        ,hz_locations                           hl                 -- パーティサイトマスタ
        ,fnd_lookup_values                      flv_tran           -- LookUp参照テーブル(明細.受注タイプ)
        ,fnd_lookup_values                      flv_hokan          -- LookUp参照テーブル(保管場所)
        ,hr_operating_units                     hou                -- 営業単位マスタ
  WHERE ooha.header_id                          = oola.header_id                         -- ヘッダーID
  AND   ooha.booked_flag                        = 'Y'                                    -- ステータス(記帳)
/* 2009/07/14 Ver1.3 Add Start */
  AND   (
          ooha.global_attribute3 IS NULL
        OR
          ooha.global_attribute3 = '01'
        )                                                                                --情報区分
/* 2009/07/14 Ver1.3 Add End   */
  AND   oola.flow_status_code                   NOT IN ('CANCELLED','CLOSED')            -- ステータス(明細)
  AND   ooha.sold_to_org_id                     = hca.cust_account_id                    -- 顧客ID
  AND   ooha.order_type_id                      = ottah.transaction_type_id              -- 取引タイプID(ヘッダー)
  AND   ottah.language                          = USERENV('LANG')
  AND   ottah.name                              = flv_tran.attribute1                    -- 取引タイプ名(ヘッダー)
  AND   oola.line_type_id                       = ottal.transaction_type_id              -- 取引タイプID(明細)
  AND   ottal.language                          = USERENV('LANG')
  AND   ottal.name                              = flv_tran.attribute2                    -- 取引タイプ名(明細)
  AND   oola.subinventory                       = msi.secondary_inventory_name           -- 保管場所
  AND   msi.attribute13                         = flv_hokan.meaning                      -- 保管場所区分
  AND   oola.packing_instructions               IS NOT NULL
  AND   NOT EXISTS (
                    SELECT xoha.request_no
                      FROM xxwsh_order_headers_all xoha
                     WHERE xoha.request_no    = oola.packing_instructions
                   )
  AND   NVL(oola.attribute6,oola.ordered_item) 
            NOT IN ( SELECT flv_non_inv.lookup_code
                     FROM   fnd_lookup_values             flv_non_inv
                     WHERE  flv_non_inv.lookup_type       = 'XXCOS1_NO_INV_ITEM_CODE'
                     AND    flv_non_inv.language          = USERENV('LANG')
                     AND    flv_non_inv.enabled_flag      = 'Y')
  AND   NVL(oola.attribute6,oola.ordered_item) 
            NOT IN ( SELECT flv_err.lookup_code
                     FROM   fnd_lookup_values             flv_err
                     WHERE  flv_err.lookup_type           = 'XXCOS1_EDI_ITEM_ERR_TYPE'
                     AND    flv_err.language              = USERENV('LANG')
                     AND    flv_err.enabled_flag          = 'Y')
  AND   xca.customer_id = hca.cust_account_id
  AND   oola.org_id                             = FND_PROFILE.VALUE('ORG_ID')               -- 営業単位
  AND   oola.ordered_item                       = msib.segment1                             -- 品目コード
  AND   xicv.item_no                            = msib.segment1                             -- 品目コード
  AND   msib.organization_id                    = oola.ship_from_org_id                     -- 組織ID
  AND   hca.cust_account_id                     = sites.cust_account_id                     -- 顧客ID
  AND   sites.cust_acct_site_id                 = uses.cust_acct_site_id                    -- 顧客サイトID
  AND   hca.customer_class_code                 = '10'                                      -- 顧客区分
  AND   uses.site_use_code                      = 'SHIP_TO'                                 -- 使用目的
  AND   sites.org_id                            = hou.organization_id                       -- 生産営業単位
  AND   uses.org_id                             = hou.organization_id                       -- 生産営業単位
  AND   sites.party_site_id                     = hps.party_site_id                         -- パーティサイトID
--****************************** 2009/07/07 1.2 T.Miyata ADD  START ******************************--
  AND   sites.status                            = 'A'                                       -- 顧客所在地.ステータス
--****************************** 2009/07/07 1.2 T.Miyata ADD  END   ******************************--  AND   hps.location_id                         = hl.location_id                            -- 事業所ID
  AND   hca.account_number                      IS NOT NULL                                 -- アカウント番号
  AND   hl.province                             IS NOT NULL                                 -- 配送先コード
  AND   hou.name                                = FND_PROFILE.VALUE('XXCOS1_ITOE_OU_MFG')   -- 生産営業単位
  AND   flv_tran.lookup_type                    = 'XXCOS1_TRAN_TYPE_MST_008_A01'
  AND   flv_tran.language                       = USERENV('LANG')
  AND   flv_tran.enabled_flag                   = 'Y'
  AND   flv_hokan.lookup_type                   = 'XXCOS1_HOKAN_DIRECT_TYPE_MST'
  AND   flv_hokan.lookup_code                   = 'XXCOS_DIRECT_11'
  AND   flv_hokan.language                      = USERENV('LANG')
  AND   flv_hokan.enabled_flag                  = 'Y'
/* 2009/10/21 Ver1.4 Add Start */
  AND   msib.organization_id                    = xxcoi_common_pkg.get_organization_id( FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE'))
  AND   msi.organization_id                     = xxcoi_common_pkg.get_organization_id( FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE'))
/* 2009/10/21 Ver1.4 Add End */
  ;
COMMENT ON  COLUMN  xxcos_re_order_number_v.order_number           IS  '受注番号';
COMMENT ON  COLUMN  xxcos_re_order_number_v.shipping_instructions  IS  '出荷指示';
/* 2009/10/21 Ver1.4 Add Start */
COMMENT ON  COLUMN  xxcos_re_order_number_v.delivery_base_code     IS  '納品拠点';
/* 2009/10/21 Ver1.4 Add End */
--
COMMENT ON  TABLE   xxcos_re_order_number_v                        IS  '再送受注番号取得';
