/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_INVENTORY_APPROVE_V
 * Description : 棚卸承認画面ビュー
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   H.Sasaki         新規作成
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOI_INVENTORY_APPROVE_V(
   INVENTORY_SEQ
  ,BASE_CODE
  ,BASE_NAME
  ,SUBINVENTORY_CODE
  ,SUBINVENTORY_NAME
  ,DISABLE_DATE
  ,INVENTORY_YEAR_MONTH
  ,INVENTORY_DATE
  ,INVENTORY_STATUS
  ,INVENTORY_STATUS_NAME
  ,CREATED_BY
  ,CREATION_DATE
  ,LAST_UPDATED_BY
  ,LAST_UPDATE_DATE
  ,LAST_UPDATE_LOGIN
) AS 
SELECT   ici.inventory_seq                inventory_seq             -- 棚卸SEQ
        ,msi.attribute7                   base_code                 -- 拠点コード
        ,hca.account_name                 base_name                 -- 拠点名称
        ,msi.secondary_inventory_name     subinventory_code         -- 保管場所コード
        ,msi.description                  subinventory_name         -- 保管場所名称
        ,msi.disable_date                 disable_date              -- 無効日
        ,ici.inventory_year_month         inventory_year_month      -- 年月
        ,ici.inventory_date               inventory_date            -- 棚卸日
        ,ici.inventory_status             inventory_status          -- 棚卸ステータス
        ,flv.meaning                      inventory_status_name     -- 棚卸ステータス名称
        ,ici.created_by                   created_by                -- 作成者
        ,ici.creation_date                creation_date             -- 作成日時
        ,ici.last_updated_by              last_updated_by           -- 最終更新者
        ,ici.last_update_date             last_update_date          -- 最終更新日時
        ,ici.last_update_login            last_update_login         -- 最終更新ログイン者
FROM     mtl_secondary_inventories        msi                       -- 保管場所マスタ
        ,hz_cust_accounts                 hca                       -- 顧客マスタ
        ,fnd_lookup_values                flv                       -- 参照タイプ
        ,( SELECT  xic.inventory_seq                                      inventory_seq             -- 棚卸SEQ
                  ,xic.inventory_year_month                               inventory_year_month      -- 年月
                  ,xic.inventory_date                                     inventory_date            -- 棚卸日
                  ,NVL(xic.inventory_status, 0)                           inventory_status          -- 棚卸ステータス
                  ,xic.inventory_kbn                                      inventory_kbn             -- 棚卸区分
                  ,msi_in.attribute7                                      base_code                 -- 拠点コード
                  ,msi_in.secondary_inventory_name                        subinventory_code         -- 名称（保管場所コード）
                  ,msi_in.organization_id                                 organization_id           -- 組織ID
                  ,NVL(xic.created_by       ,msi_in.created_by       )    created_by                -- 作成者
                  ,NVL(xic.creation_date    ,msi_in.creation_date    )    creation_date             -- 作成日時
                  ,NVL(xic.last_updated_by  ,msi_in.last_updated_by  )    last_updated_by           -- 最終更新者
                  ,NVL(xic.last_update_date ,msi_in.last_update_date )    last_update_date          -- 最終更新日時
                  ,NVL(xic.last_update_login,msi_in.last_update_login)    last_update_login         -- 最終更新ログイン者
           FROM    xxcoi_inv_control                  xic                 -- 棚卸管理テーブル
                  ,mtl_secondary_inventories          msi_in              -- 保管場所マスタ
           WHERE   msi_in.organization_id             =   xxcoi_common_pkg.get_organization_id('S01')
           AND     msi_in.attribute7                  =   xic.base_code(+)
           AND     msi_in.secondary_inventory_name    =   xic.subinventory_code(+)
         )                                ici                       -- 棚卸管理情報
WHERE   msi.organization_id             = ici.organization_id
AND     msi.attribute7                  = hca.account_number
AND     hca.customer_class_code         = '1'
AND     msi.attribute7                  = ici.base_code
AND     msi.secondary_inventory_name    = ici.subinventory_code
AND     (   ici.inventory_kbn  = '2'
         OR ici.inventory_kbn IS NULL
        )
AND     msi.attribute1 <> '5'
AND     msi.attribute1 <> '8'
AND     flv.lookup_type                 = 'XXCOI1_INV_STATUS_F'
AND     flv.lookup_code                 = ici.inventory_status
AND     flv.language                    = USERENV('LANG');
/
COMMENT ON TABLE  XXCOI_INVENTORY_APPROVE_V                       IS '棚卸承認画面ビュー';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_SEQ         IS '棚卸SEQ';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.BASE_CODE             IS '拠点コード';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.BASE_NAME             IS '拠点名称';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.SUBINVENTORY_CODE     IS '保管場所コード';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.SUBINVENTORY_NAME     IS '保管場所名称';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.DISABLE_DATE          IS '無効日';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_YEAR_MONTH  IS '年月';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_DATE        IS '棚卸日';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_STATUS      IS '棚卸ステータス';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.INVENTORY_STATUS_NAME IS '棚卸ステータス名称';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.CREATED_BY            IS '作成者';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.CREATION_DATE         IS '作成日時';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.LAST_UPDATED_BY       IS '最終更新者';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.LAST_UPDATE_DATE      IS '最終更新日時';
/
COMMENT ON COLUMN XXCOI_INVENTORY_APPROVE_V.LAST_UPDATE_LOGIN     IS '最終更新ログイン者';
/
