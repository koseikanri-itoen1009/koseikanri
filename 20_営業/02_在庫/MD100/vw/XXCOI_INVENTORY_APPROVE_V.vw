/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_INVENTORY_APPROVE_V
 * Description : 棚卸承認画面ビュー
 * Version     : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   H.Sasaki         新規作成
 *  2009/05/13    1.1   T.Nakamura       [T1_0877]CREATE文のセミコロンを削除
 *  2009/05/22    1.2   T.Nakamura       [T1_1150]拠点コードによる絞込条件を削除
 *  2009/07/24    1.3   H.Sasaki         [0000830]棚卸管理の抽出条件を修正
 *  2009/07/29    1.4   N.Abe            [0000878]抽出条件、出力順序修正
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
-- == 2009/07/24 V1.3 Modified START =============================================================
--SELECT   ici.inventory_seq                inventory_seq             -- 棚卸SEQ
--        ,msi.attribute7                   base_code                 -- 拠点コード
--        ,hca.account_name                 base_name                 -- 拠点名称
--        ,msi.secondary_inventory_name     subinventory_code         -- 保管場所コード
--        ,msi.description                  subinventory_name         -- 保管場所名称
--        ,msi.disable_date                 disable_date              -- 無効日
--        ,ici.inventory_year_month         inventory_year_month      -- 年月
--        ,ici.inventory_date               inventory_date            -- 棚卸日
--        ,ici.inventory_status             inventory_status          -- 棚卸ステータス
--        ,flv.meaning                      inventory_status_name     -- 棚卸ステータス名称
--        ,ici.created_by                   created_by                -- 作成者
--        ,ici.creation_date                creation_date             -- 作成日時
--        ,ici.last_updated_by              last_updated_by           -- 最終更新者
--        ,ici.last_update_date             last_update_date          -- 最終更新日時
--        ,ici.last_update_login            last_update_login         -- 最終更新ログイン者
--FROM     mtl_secondary_inventories        msi                       -- 保管場所マスタ
--        ,hz_cust_accounts                 hca                       -- 顧客マスタ
--        ,fnd_lookup_values                flv                       -- 参照タイプ
--        ,( SELECT  xic.inventory_seq                                      inventory_seq             -- 棚卸SEQ
--                  ,xic.inventory_year_month                               inventory_year_month      -- 年月
--                  ,xic.inventory_date                                     inventory_date            -- 棚卸日
--                  ,NVL(xic.inventory_status, 0)                           inventory_status          -- 棚卸ステータス
--                  ,xic.inventory_kbn                                      inventory_kbn             -- 棚卸区分
--                  ,msi_in.attribute7                                      base_code                 -- 拠点コード
--                  ,msi_in.secondary_inventory_name                        subinventory_code         -- 名称（保管場所コード）
--                  ,msi_in.organization_id                                 organization_id           -- 組織ID
--                  ,NVL(xic.created_by       ,msi_in.created_by       )    created_by                -- 作成者
--                  ,NVL(xic.creation_date    ,msi_in.creation_date    )    creation_date             -- 作成日時
--                  ,NVL(xic.last_updated_by  ,msi_in.last_updated_by  )    last_updated_by           -- 最終更新者
--                  ,NVL(xic.last_update_date ,msi_in.last_update_date )    last_update_date          -- 最終更新日時
--                  ,NVL(xic.last_update_login,msi_in.last_update_login)    last_update_login         -- 最終更新ログイン者
--           FROM    xxcoi_inv_control                  xic                 -- 棚卸管理テーブル
--                  ,mtl_secondary_inventories          msi_in              -- 保管場所マスタ
--           WHERE   msi_in.organization_id             =   xxcoi_common_pkg.get_organization_id('S01')
---- == 2009/05/22 V1.2 Deleted START =============================================================
----           AND     msi_in.attribute7                  =   xic.base_code(+)
---- == 2009/05/22 V1.2 Deleted END   =============================================================
--           AND     msi_in.secondary_inventory_name    =   xic.subinventory_code(+)
--         )                                ici                       -- 棚卸管理情報
--WHERE   msi.organization_id             = ici.organization_id
--AND     msi.attribute7                  = hca.account_number
--AND     hca.customer_class_code         = '1'
---- == 2009/05/22 V1.2 Deleted START =============================================================
----AND     msi.attribute7                  = ici.base_code
---- == 2009/05/22 V1.2 Deleted END   =============================================================
--AND     msi.secondary_inventory_name    = ici.subinventory_code
--AND     (   ici.inventory_kbn  = '2'
--         OR ici.inventory_kbn IS NULL
--        )
--AND     msi.attribute1 <> '5'
--AND     msi.attribute1 <> '8'
--AND     flv.lookup_type                 = 'XXCOI1_INV_STATUS_F'
--AND     flv.lookup_code                 = ici.inventory_status
--AND     flv.language                    = USERENV('LANG')
--
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
        ,(
          SELECT  xic.inventory_seq                                      inventory_seq             -- 棚卸SEQ
                 ,xic.inventory_year_month                               inventory_year_month      -- 年月
                 ,xic.inventory_date                                     inventory_date            -- 棚卸日
                 ,NVL(xic.inventory_status, 0)                           inventory_status          -- 棚卸ステータス
                 ,sub_msi.attribute7                                     base_code                 -- 拠点コード
                 ,sub_msi.secondary_inventory_name                       subinventory_code         -- 名称（保管場所コード）
                 ,sub_msi.organization_id                                organization_id           -- 組織ID
                 ,NVL(xic.created_by       ,sub_msi.created_by       )   created_by                -- 作成者
                 ,NVL(xic.creation_date    ,sub_msi.creation_date    )   creation_date             -- 作成日時
                 ,NVL(xic.last_updated_by  ,sub_msi.last_updated_by  )   last_updated_by           -- 最終更新者
                 ,NVL(xic.last_update_date ,sub_msi.last_update_date )   last_update_date          -- 最終更新日時
                 ,NVL(xic.last_update_login,sub_msi.last_update_login)   last_update_login         -- 最終更新ログイン者
          FROM    (SELECT    xic_main.inventory_seq
                            ,xic_main.inventory_year_month
                            ,xic_main.subinventory_code
                            ,xic_main.inventory_date
                            ,xic_main.inventory_status
                            ,xic_main.created_by
                            ,xic_main.creation_date
                            ,xic_main.last_updated_by
                            ,xic_main.last_update_date
                            ,xic_main.last_update_login
                   FROM      xxcoi_inv_control     xic_main
                            ,(SELECT    MAX(xic.inventory_date)   inventory_date
                                       ,xic.base_code             base_code
                                       ,xic.subinventory_code     subinventory_code
                              FROM      xxcoi_inv_control        xic
-- == 2009/07/29 V1.4 Added START =============================================================
                                       ,(SELECT MIN(TO_CHAR(oap.period_start_date, 'YYYYMM')) period_date
                                         FROM   org_acct_periods  oap
                                         WHERE  oap.organization_id  = xxcoi_common_pkg.get_organization_id('S01')
                                         AND    oap.open_flag        = 'Y'
                                        ) oap_sub
-- == 2009/07/29 V1.4 Added END   =============================================================
                              WHERE     xic.inventory_kbn    =   '2'
-- == 2009/07/29 V1.4 Added START =============================================================
                              AND       xic.inventory_year_month = oap_sub.period_date
-- == 2009/07/29 V1.4 Added END   =============================================================
                              GROUP BY  xic.inventory_year_month
                                       ,xic.base_code
                                       ,xic.subinventory_code
                             ) xic_sub
                   WHERE     xic_main.inventory_date    =   xic_sub.inventory_date
                   AND       xic_main.base_code         =   xic_sub.base_code
                   AND       xic_main.subinventory_code =   xic_sub.subinventory_code
                   AND       xic_main.inventory_kbn     =   '2'
                  )                                   xic                 -- 棚卸管理テーブル
                 ,mtl_secondary_inventories           sub_msi             -- 保管場所マスタ
          WHERE   sub_msi.organization_id             =   xxcoi_common_pkg.get_organization_id('S01')
          AND     sub_msi.secondary_inventory_name    =   xic.subinventory_code(+)
         )                                ici                       -- 棚卸管理情報
WHERE   msi.organization_id             = ici.organization_id
AND     msi.attribute7                  = hca.account_number
AND     hca.customer_class_code         = '1'
AND     msi.secondary_inventory_name    = ici.subinventory_code
-- == 2009/07/29 V1.4 Added START =============================================================
AND     msi.attribute13 <> '7'
-- == 2009/07/29 V1.4 Added END   =============================================================
AND     msi.attribute1 <> '5'
AND     msi.attribute1 <> '8'
AND     flv.lookup_type                 = 'XXCOI1_INV_STATUS_F'
AND     flv.lookup_code                 = ici.inventory_status
AND     flv.language                    = USERENV('LANG')
-- == 2009/07/24 V1.3 Modified END   =============================================================
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
