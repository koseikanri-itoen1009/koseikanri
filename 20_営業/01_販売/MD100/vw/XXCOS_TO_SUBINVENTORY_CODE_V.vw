/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_to_subinventory_code_v
 * Description     : EDI搬送先保管場所ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   S.Nakamura       新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_to_subinventory_code_v (
  secondary_inventory_name  --保管場所コード
 ,description               --適用
)
AS
  SELECT  DISTINCT
          msi.secondary_inventory_name  secondary_inventory_name  --保管場所コード
         ,msi.description               description               --適用
  FROM    xxcos_login_base_info_v    xlbiv --ログインユーザ拠点ビュー
         ,xxcmm_cust_accounts        xca   --顧客追加情報
         ,mtl_secondary_inventories  msi   --保管場所マスタ
         ,mtl_parameters             mp    --在庫組織マスタ
         ,fnd_lookup_values_vl       flvv  --クイックコード
  WHERE  xca.delivery_base_code        = xlbiv.base_code                                  --結合(顧客追加=拠点)
  AND    msi.secondary_inventory_name  = xca.ship_storage_code                            --結合(保管場所=顧客追加)
  AND    msi.attribute13               = '3'                                              --在庫型センター
  AND    mp.organization_id            = msi.organization_id                              --結合(在庫組織=保管場所)
  AND    mp.organization_code          = FND_PROFILE.VALUE( 'XXCOI1_ORGANIZATION_CODE' )  --在庫組織コード
  AND    flvv.lookup_type              = 'XXCOS1_EDI_CONTROL_LIST'                        --EDI制御情報
  AND    flvv.attribute1               = xca.chain_store_code                             --結合(クイック=顧客追加)
  AND    flvv.attribute2               = '22'                                             --入庫予定対象
  AND    flvv.attribute3               = '01'                                             --並列処理番号('01'固定)
  AND    flvv.enabled_flag             = 'Y'                                              --有効
  AND    (
           ( flvv.start_date_active IS NULL )
           OR
           ( flvv.start_date_active <= TRUNC(SYSDATE) )
         )
  AND    (
           ( flvv.end_date_active IS NULL )
           OR
           ( flvv.end_date_active >= TRUNC(SYSDATE) )
         )                                                                                --今日日付がFROM-TO内
;
COMMENT ON  COLUMN  xxcos_to_subinventory_code_v.secondary_inventory_name  IS  '保管場所コード';
COMMENT ON  COLUMN  xxcos_to_subinventory_code_v.description               IS  '適用';
--
COMMENT ON  TABLE   xxcos_to_subinventory_code_v                           IS  'EDI搬送先保管場所ビュー';
