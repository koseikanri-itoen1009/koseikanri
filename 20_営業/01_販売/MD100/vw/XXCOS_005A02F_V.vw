/***********************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * View Name       : XXCOS_005A02F_V
 * Description     : 一括更新用受注データ取得View
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2018/4/13     1.0   H.Sasaki         新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCOS_005A02F_V(
  HEADER_ID
, LINE_ID
, LINE_NUMBER
, HEADER_FLOW_STATUS
, LINE_FLOW_STATUS
, ORDER_TYPE_ID
, LINE_TYPE_ID
, CUSTOMER_ID
, ORDER_NUMBER
, CUST_PO_NUMBER
, ORDERED_DATE
, HEADER_REQUEST_DATE
, ORDER_SOURCE_ID
, DATA_TYPE
, INVENTORY_ITEM_ID
, ORDER_QUANTITY_UOM
, ORDERED_QUANTITY
, SUBINV_CODE
, LINE_REQUEST_DATE
, LINE_CATEGORY_CODE
, SCHEDULE_SHIP_DATE
, ACCEPT_DATE
, CREATION_DATE
, CREATED_BY
, LAST_UPDATE_DATE
, LAST_UPDATED_BY
, LAST_UPDATE_LOGIN
, LINE_FLOW_STATUS_NAME
, HEADER_TYPE_NAME
, LINE_TYPE_NAME
, CUSTOMER_CODE
, CUSTOMER_NAME
, DUNS_NUMBER_C
, CHAIN_STORE_CODE
, ITEM_CODE
, ITEM_NAME
, INVENTORY_ASSET_FLAG
, PRIMARY_UOM_CODE
, ERROR_ITEM_FLAG
, SUBINV_NAME
) AS
SELECT
    ooha.header_id                HEADER_ID                   --  受注ヘッダID
  , oola.line_id                  LINE_ID                     --  受注明細ID
  , oola.line_number              LINE_NUMBER                 --  明細番号
  , ooha.flow_status_code         HEADER_FLOW_STATUS          --  受注ステータス（ヘッダ）
  , oola.flow_status_code         LINE_FLOW_STATUS            --  受注ステータス（明細）
  , ooha.order_type_id            ORDER_TYPE_ID               --  受注タイプID
  , oola.line_type_id             LINE_TYPE_ID                --  明細タイプID
  , ooha.sold_to_org_id           CUSTOMER_ID                 --  顧客ID
  , ooha.order_number             ORDER_NUMBER                --  受注番号
  , ooha.cust_po_number           CUST_PO_NUMBER              --  顧客発注番号
  , ooha.ordered_date             ORDERED_DATE                --  受注日
  , ooha.request_date             HEADER_REQUEST_DATE         --  着日（ヘッダ）
  , ooha.order_source_id          ORDER_SOURCE_ID             --  受注ソースID
  , ooha.global_attribute3        DATA_TYPE                   --  情報区分
  , oola.inventory_item_id        INVENTORY_ITEM_ID           --  品目ID
  , oola.order_quantity_uom       ORDER_QUANTITY_UOM          --  受注単位
  , oola.ordered_quantity * CASE WHEN oola.line_category_code = 'ORDER' THEN 1 ELSE -1 END
                                  ORDERED_QUANTITY            --  受注数量
  , oola.subinventory             SUBINV_CODE                 --  保管場所
  , oola.request_date             LINE_REQUEST_DATE           --  着日（明細）
  , oola.line_category_code       LINE_CATEGORY_CODE          --  明細カテゴリコード
  , oola.schedule_ship_date       SCHEDULE_SHIP_DATE          --  出荷予定日
  , oola.attribute4               ACCEPT_DATE                 --  検収日
  , oola.creation_date            CREATION_DATE               --  作成日（明細）
  , oola.created_by               CREATED_BY                  --  作成者（明細）
  , oola.last_update_date         LAST_UPDATE_DATE            --  最終更新日（明細）
  , oola.last_updated_by          LAST_UPDATED_BY             --  最終更新者（明細）
  , oola.last_update_login        LAST_UPDATE_LOGIN           --  最終更新ログイン者（明細）
  , flv.description               LINE_FLOW_STATUS_NAME       --  受注ステータス名（明細）
  , otth.name                     HEADER_TYPE_NAME            --  受注タイプ名
  , ottl.name                     LINE_TYPE_NAME              --  明細タイプ名
  , hca.account_number            CUSTOMER_CODE               --  顧客番号
  , hp.party_name                 CUSTOMER_NAME               --  顧客名
  , hp.duns_number_c              DUNS_NUMBER_C               --  DUNS番号
  , xca.chain_store_code          CHAIN_STORE_CODE            --  チェーン店コード
  , msib.segment1                 ITEM_CODE                   --  品目コード
  , msib.description              ITEM_NAME                   --  品名
  , msib.inventory_asset_flag     INVENTORY_ASSET_FLAG        --  在庫資産価額
  , msib.primary_uom_code         PRIMARY_UOM_CODE            --  基準単位
  , NVL(
      ( SELECT  'Y'
        FROM    fnd_lookup_values   sflv
        WHERE   sflv.lookup_type  =   'XXCOS1_EDI_ITEM_ERR_TYPE'
        AND     sflv.language     =   USERENV( 'LANG' )
        AND     sflv.enabled_flag =   'Y'
        AND     TRUNC( SYSDATE )  BETWEEN TRUNC( NVL( sflv.start_date_active, SYSDATE ) ) AND TRUNC( NVL( sflv.end_date_active, SYSDATE ) )
        AND     sflv.lookup_code  =   msib.segment1
      ), 'N'
    )                             ERROR_ITEM_FLAG             --  エラー品目フラグ
  , msi.description               SUBINV_NAME                 --  保管場所名
FROM    oe_order_headers_all            ooha          --  受注ヘッダ
      , oe_order_lines_all              oola          --  受注明細
      , xxcmm_cust_accounts             xca           --  顧客アドオン
      , fnd_lookup_values               flv           --  参照表
      , oe_transaction_types_all        otah          --  受注タイプ（ヘッダ）
      , oe_transaction_types_tl         otth          --  受注タイプTL（ヘッダ）
      , oe_transaction_types_all        otal          --  受注タイプ（明細）
      , oe_transaction_types_tl         ottl          --  受注タイプTL（明細）
      , hz_cust_accounts                hca           --  顧客マスタ
      , hz_parties                      hp            --  パーティ
      , mtl_system_items_b              msib          --  品目マスタ
      , mtl_secondary_inventories       msi           --  保管場所マスタ
WHERE   ooha.header_id            =   oola.header_id
AND     ooha.flow_status_code   IN( 'ENTERED', 'BOOKED' )
AND     oola.flow_status_code   IN( 'ENTERED', 'BOOKED' )
AND     xca.customer_id           =   ooha.sold_to_org_id
AND EXISTS( SELECT  1
            FROM    xxcos_all_or_login_base_info_v  xalbv
            WHERE   xalbv.base_code   =   xca.sale_base_code
            OR      xalbv.base_code   =   xca.past_sale_base_code
            OR      xalbv.base_code   =   xca.delivery_base_code
    )
AND     oola.flow_status_code     =   flv.lookup_code
AND     flv.lookup_type           =   'LINE_FLOW_STATUS'
AND     flv.language              =   USERENV('LANG')
AND     flv.enabled_flag          =   'Y'
AND     TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flv.start_date_active, SYSDATE ) ) AND TRUNC( NVL( flv.end_date_active, SYSDATE ) )
AND     ooha.order_type_id        =   otth.transaction_type_id
AND     otah.transaction_type_id  =   otth.transaction_type_id
AND     otth.language             =   USERENV( 'LANG' )
AND     TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( otah.start_date_active, SYSDATE ) ) AND TRUNC( NVL( otah.end_date_active, SYSDATE ) )
AND     oola.line_type_id         =   ottl.transaction_type_id
AND     otal.transaction_type_id  =   ottl.transaction_type_id
AND     ottl.language             =   USERENV( 'LANG' )
AND     TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( otal.start_date_active, SYSDATE ) ) AND TRUNC( NVL( otal.end_date_active, SYSDATE ) )
AND     xca.customer_id           =   hca.cust_account_id
AND     hca.party_id              =   hp.party_id
AND     hca.status                =   'A'
AND     hp.status                 =   'A'
AND     oola.inventory_item_id    =   msib.inventory_item_id
AND     msib.organization_id      =   xxcoi_common_pkg.get_organization_id( fnd_profile.value( 'XXCOI1_ORGANIZATION_CODE' ) )
AND     oola.subinventory         =   msi.secondary_inventory_name(+)
AND     oola.ship_from_org_Id     =   msi.organization_id(+)
;
