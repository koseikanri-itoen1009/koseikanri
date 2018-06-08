/***********************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * View Name       : XXCOS_005A02F_V
 * Description     : �ꊇ�X�V�p�󒍃f�[�^�擾View
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2018/4/13     1.0   H.Sasaki         �V�K�쐬
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
    ooha.header_id                HEADER_ID                   --  �󒍃w�b�_ID
  , oola.line_id                  LINE_ID                     --  �󒍖���ID
  , oola.line_number              LINE_NUMBER                 --  ���הԍ�
  , ooha.flow_status_code         HEADER_FLOW_STATUS          --  �󒍃X�e�[�^�X�i�w�b�_�j
  , oola.flow_status_code         LINE_FLOW_STATUS            --  �󒍃X�e�[�^�X�i���ׁj
  , ooha.order_type_id            ORDER_TYPE_ID               --  �󒍃^�C�vID
  , oola.line_type_id             LINE_TYPE_ID                --  ���׃^�C�vID
  , ooha.sold_to_org_id           CUSTOMER_ID                 --  �ڋqID
  , ooha.order_number             ORDER_NUMBER                --  �󒍔ԍ�
  , ooha.cust_po_number           CUST_PO_NUMBER              --  �ڋq�����ԍ�
  , ooha.ordered_date             ORDERED_DATE                --  �󒍓�
  , ooha.request_date             HEADER_REQUEST_DATE         --  �����i�w�b�_�j
  , ooha.order_source_id          ORDER_SOURCE_ID             --  �󒍃\�[�XID
  , ooha.global_attribute3        DATA_TYPE                   --  ���敪
  , oola.inventory_item_id        INVENTORY_ITEM_ID           --  �i��ID
  , oola.order_quantity_uom       ORDER_QUANTITY_UOM          --  �󒍒P��
  , oola.ordered_quantity * CASE WHEN oola.line_category_code = 'ORDER' THEN 1 ELSE -1 END
                                  ORDERED_QUANTITY            --  �󒍐���
  , oola.subinventory             SUBINV_CODE                 --  �ۊǏꏊ
  , oola.request_date             LINE_REQUEST_DATE           --  �����i���ׁj
  , oola.line_category_code       LINE_CATEGORY_CODE          --  ���׃J�e�S���R�[�h
  , oola.schedule_ship_date       SCHEDULE_SHIP_DATE          --  �o�ח\���
  , oola.attribute4               ACCEPT_DATE                 --  ������
  , oola.creation_date            CREATION_DATE               --  �쐬���i���ׁj
  , oola.created_by               CREATED_BY                  --  �쐬�ҁi���ׁj
  , oola.last_update_date         LAST_UPDATE_DATE            --  �ŏI�X�V���i���ׁj
  , oola.last_updated_by          LAST_UPDATED_BY             --  �ŏI�X�V�ҁi���ׁj
  , oola.last_update_login        LAST_UPDATE_LOGIN           --  �ŏI�X�V���O�C���ҁi���ׁj
  , flv.description               LINE_FLOW_STATUS_NAME       --  �󒍃X�e�[�^�X���i���ׁj
  , otth.name                     HEADER_TYPE_NAME            --  �󒍃^�C�v��
  , ottl.name                     LINE_TYPE_NAME              --  ���׃^�C�v��
  , hca.account_number            CUSTOMER_CODE               --  �ڋq�ԍ�
  , hp.party_name                 CUSTOMER_NAME               --  �ڋq��
  , hp.duns_number_c              DUNS_NUMBER_C               --  DUNS�ԍ�
  , xca.chain_store_code          CHAIN_STORE_CODE            --  �`�F�[���X�R�[�h
  , msib.segment1                 ITEM_CODE                   --  �i�ڃR�[�h
  , msib.description              ITEM_NAME                   --  �i��
  , msib.inventory_asset_flag     INVENTORY_ASSET_FLAG        --  �݌Ɏ��Y���z
  , msib.primary_uom_code         PRIMARY_UOM_CODE            --  ��P��
  , NVL(
      ( SELECT  'Y'
        FROM    fnd_lookup_values   sflv
        WHERE   sflv.lookup_type  =   'XXCOS1_EDI_ITEM_ERR_TYPE'
        AND     sflv.language     =   USERENV( 'LANG' )
        AND     sflv.enabled_flag =   'Y'
        AND     TRUNC( SYSDATE )  BETWEEN TRUNC( NVL( sflv.start_date_active, SYSDATE ) ) AND TRUNC( NVL( sflv.end_date_active, SYSDATE ) )
        AND     sflv.lookup_code  =   msib.segment1
      ), 'N'
    )                             ERROR_ITEM_FLAG             --  �G���[�i�ڃt���O
  , msi.description               SUBINV_NAME                 --  �ۊǏꏊ��
FROM    oe_order_headers_all            ooha          --  �󒍃w�b�_
      , oe_order_lines_all              oola          --  �󒍖���
      , xxcmm_cust_accounts             xca           --  �ڋq�A�h�I��
      , fnd_lookup_values               flv           --  �Q�ƕ\
      , oe_transaction_types_all        otah          --  �󒍃^�C�v�i�w�b�_�j
      , oe_transaction_types_tl         otth          --  �󒍃^�C�vTL�i�w�b�_�j
      , oe_transaction_types_all        otal          --  �󒍃^�C�v�i���ׁj
      , oe_transaction_types_tl         ottl          --  �󒍃^�C�vTL�i���ׁj
      , hz_cust_accounts                hca           --  �ڋq�}�X�^
      , hz_parties                      hp            --  �p�[�e�B
      , mtl_system_items_b              msib          --  �i�ڃ}�X�^
      , mtl_secondary_inventories       msi           --  �ۊǏꏊ�}�X�^
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
