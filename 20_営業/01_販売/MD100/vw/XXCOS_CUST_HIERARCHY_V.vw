/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOS_CUST_HIERARCHY_V
 * Description     : 顧客階層ビュー
 * Version         : 1.5
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   S.Tomita         新規作成
 *  2009/07/13    1.1   K.Kakishita      [0000433] パフォーマンス障害
 *                                       ・ヒント句追加
 *  2009/07/30    1.2   K.Kakishita      [0000433] パフォーマンス障害
 *                                       ・④のWHERE句を変更
 *  2009/08/03    1.3   K.Kakishita      [0000433] パフォーマンス障害
 *                                       ・ヒント句削除
 *                                       ・インラインビューの別名追加
 *                                       ・④表別名変更
 *  2009/08/05    1.4   K.Kakishita      [0000938] 修正ミス
 *                                       ・条件追加
 *                                       ・ROWNUMを'X'に変更
 *  2009/09/11    1.5   K.Kiriu          [0001337]ヒント句追加
 *                                                SELECT句に別名追加 ※コメント化なし
 *  2009/11/12    1.6   K.Atsushiba      [I_E_648]④の顧客関連の抽出条件追加
 ************************************************************************/
  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOS_CUST_HIERARCHY_V" ("CASH_ACCOUNT_ID", "CASH_ACCOUNT_NUMBER", "CASH_ACCOUNT_NAME", "BILL_ACCOUNT_ID", "BILL_ACCOUNT_NUMBER", "BILL_ACCOUNT_NAME", "SHIP_ACCOUNT_ID", "SHIP_ACCOUNT_NUMBER", "SHIP_ACCOUNT_NAME", "CASH_RECEIV_BASE_CODE", "BILL_PARTY_ID", "BILL_BILL_BASE_CODE", "BILL_POSTAL_CODE", "BILL_STATE", "BILL_CITY", "BILL_ADDRESS1", "BILL_ADDRESS2", "BILL_TEL_NUM", "BILL_CONS_INV_FLAG", "BILL_TORIHIKISAKI_CODE", "BILL_STORE_CODE", "BILL_CUST_STORE_NAME", "BILL_TAX_DIV", "BILL_CRED_REC_CODE1", "BILL_CRED_REC_CODE2", "BILL_CRED_REC_CODE3", "BILL_INVOICE_TYPE", "BILL_PAYMENT_TERM_ID", "BILL_PAYMENT_TERM2", "BILL_PAYMENT_TERM3", "BILL_TAX_ROUND_RULE", "SHIP_SALE_BASE_CODE") AS
  SELECT cust_hier.cash_account_id                          AS cash_account_id        --入金先顧客ID
        ,cust_hier.cash_account_number                      AS cash_account_number    --入金先顧客コード
        ,xxcfr_common_pkg.get_cust_account_name(
                            cust_hier.cash_account_number,
                            0)                              AS cash_account_name      --入金先顧客名称
        ,cust_hier.bill_account_id                          AS bill_account_id        --請求先顧客ID
        ,cust_hier.bill_account_number                      AS bill_account_number    --請求先顧客コード
        ,xxcfr_common_pkg.get_cust_account_name(
                            cust_hier.bill_account_number,
                            0)                              AS bill_account_name      --請求先顧客名称
        ,cust_hier.ship_account_id                          AS ship_account_id        --出荷先顧客ID
        ,cust_hier.ship_account_number                      AS ship_account_number    --出荷先顧客コード
        ,xxcfr_common_pkg.get_cust_account_name(
                            cust_hier.ship_account_number,
                            0)                              AS ship_account_name      --出荷先顧客名称
        ,cust_hier.cash_receiv_base_code                    AS cash_receiv_base_code  --入金拠点コード
        ,cust_hier.bill_party_id                            AS bill_party_id          --パーティID
        ,cust_hier.bill_bill_base_code                      AS bill_bill_base_code    --請求拠点コード
        ,cust_hier.bill_postal_code                         AS bill_postal_code       --郵便番号
        ,cust_hier.bill_state                               AS bill_state             --都道府県
        ,cust_hier.bill_city                                AS bill_city              --市・区
        ,cust_hier.bill_address1                            AS bill_address1          --住所1
        ,cust_hier.bill_address2                            AS bill_address2          --住所2
        ,cust_hier.bill_tel_num                             AS bill_tel_num           --電話番号
        ,cust_hier.bill_cons_inv_flag                       AS bill_cons_inv_flag     --一括請求書発行フラグ
        ,cust_hier.bill_torihikisaki_code                   AS bill_torihikisaki_code --取引先コード
        ,cust_hier.bill_store_code                          AS bill_store_code        --店舗コード
        ,cust_hier.bill_cust_store_name                     AS bill_cust_store_name   --顧客店舗名称
        ,cust_hier.bill_tax_div                             AS bill_tax_div           --消費税区分
        ,cust_hier.bill_cred_rec_code1                      AS bill_cred_rec_code1    --売掛コード1(請求書)
        ,cust_hier.bill_cred_rec_code2                      AS bill_cred_rec_code2    --売掛コード2(事業所)
        ,cust_hier.bill_cred_rec_code3                      AS bill_cred_rec_code3    --売掛コード3(その他)
        ,cust_hier.bill_invoice_type                        AS bill_invoice_type      --請求書出力形式
        ,cust_hier.bill_payment_term_id                     AS bill_payment_term_id   --支払条件
        ,TO_NUMBER(cust_hier.bill_payment_term2)            AS bill_payment_term2     --第2支払条件
        ,TO_NUMBER(cust_hier.bill_payment_term3)            AS bill_payment_term3     --第3支払条件
        ,cust_hier.bill_tax_round_rule                      AS bill_tax_round_rule    --税金－端数処理
        ,cust_hier.ship_sale_base_code                      AS ship_sale_base_code    --売上拠点コード
  FROM   (
  --①入金先顧客＆請求先顧客－出荷先顧客
    SELECT
/* 2009/09/11 Ver1.5 Add Start */
           /*+
             LEADING(ship_hzca_1)
             USE_NL(ship_hzca_1 bill_hzca_1 bill_hcar_1 bill_hzad_1 ship_hzad_1)
           */
/* 2009/09/11 Ver1.5 Add End   */
           bill_hzca_1.cust_account_id         AS cash_account_id         --入金先顧客ID
          ,bill_hzca_1.account_number          AS cash_account_number     --入金先顧客コード
          ,bill_hzca_1.cust_account_id         AS bill_account_id         --請求先顧客ID
          ,bill_hzca_1.account_number          AS bill_account_number     --請求先顧客コード
          ,ship_hzca_1.cust_account_id         AS ship_account_id         --出荷先顧客ID
          ,ship_hzca_1.account_number          AS ship_account_number     --出荷先顧客コード
          ,bill_hzad_1.receiv_base_code        AS cash_receiv_base_code   --入金拠点コード
          ,bill_hzca_1.party_id                AS bill_party_id           --パーティID
          ,bill_hzad_1.bill_base_code          AS bill_bill_base_code     --請求拠点コード
          ,bill_hzlo_1.postal_code             AS bill_postal_code        --郵便番号
          ,bill_hzlo_1.state                   AS bill_state              --都道府県
          ,bill_hzlo_1.city                    AS bill_city               --市・区
          ,bill_hzlo_1.address1                AS bill_address1           --住所1
          ,bill_hzlo_1.address2                AS bill_address2           --住所2
          ,bill_hzlo_1.address_lines_phonetic  AS bill_tel_num            --電話番号
          ,bill_hzcp_1.cons_inv_flag           AS bill_cons_inv_flag      --一括請求書発行フラグ
          ,bill_hzad_1.torihikisaki_code       AS bill_torihikisaki_code  --取引先コード
          ,bill_hzad_1.store_code              AS bill_store_code         --店舗コード
          ,bill_hzad_1.cust_store_name         AS bill_cust_store_name    --顧客店舗名称
          ,bill_hzad_1.tax_div                 AS bill_tax_div            --消費税区分
          ,bill_hsua_1.attribute4              AS bill_cred_rec_code1     --売掛コード1(請求書)
          ,bill_hsua_1.attribute5              AS bill_cred_rec_code2     --売掛コード2(事業所)
          ,bill_hsua_1.attribute6              AS bill_cred_rec_code3     --売掛コード3(その他)
          ,bill_hsua_1.attribute7              AS bill_invoice_type       --請求書出力形式
          ,bill_hsua_1.payment_term_id         AS bill_payment_term_id    --支払条件
          ,bill_hsua_1.attribute2              AS bill_payment_term2      --第2支払条件
          ,bill_hsua_1.attribute3              AS bill_payment_term3      --第3支払条件
          ,bill_hsua_1.tax_rounding_rule       AS bill_tax_round_rule     --税金－端数処理
          ,ship_hzad_1.sale_base_code          AS ship_sale_base_code     --売上拠点コード
    FROM   hz_cust_accounts          bill_hzca_1              --請求先顧客マスタ
          ,hz_cust_acct_sites        bill_hasa_1              --請求先顧客所在地
          ,hz_cust_site_uses         bill_hsua_1              --請求先顧客使用目的
          ,xxcmm_cust_accounts       bill_hzad_1              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_1              --請求先パーティサイト
          ,hz_locations              bill_hzlo_1              --請求先顧客事業所
          ,hz_customer_profiles      bill_hzcp_1              --請求先顧客プロファイル
          ,hz_cust_accounts          ship_hzca_1              --出荷先顧客マスタ
          ,hz_cust_acct_sites        ship_hasa_1              --出荷先顧客所在地
          ,hz_cust_site_uses         ship_hsua_1              --出荷先顧客使用目的
          ,xxcmm_cust_accounts       ship_hzad_1              --出荷先顧客追加情報
          ,hz_cust_acct_relate       bill_hcar_1              --顧客関連マスタ(請求関連)
    WHERE  bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --請求先顧客マスタ.顧客ID = 顧客関連マスタ.顧客ID
    AND    bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --顧客関連マスタ.関連先顧客ID = 出荷先顧客マスタ.顧客ID
    AND    bill_hzca_1.customer_class_code = '14'                            --請求先顧客.顧客区分 = '14'(売掛管理先顧客)
    AND    bill_hcar_1.status = 'A'                                          --顧客関連マスタ.ステータス = ‘A’
    AND    bill_hcar_1.attribute1 = '1'                                      --顧客関連マスタ.関連分類 = ‘1’ (請求)
    AND    bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hsua_1.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
    AND    ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --出荷先顧客マスタ.顧客ID = 出荷先顧客所在地.顧客ID
    AND    ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --出荷先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    ship_hzca_1.cust_account_id = ship_hzad_1.customer_id             --出荷先顧客マスタ.顧客ID = 出荷先顧客追加情報.顧客ID
    AND    bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID
    AND    bill_hzps_1.location_id = bill_hzlo_1.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID
    AND    bill_hsua_1.site_use_id = bill_hzcp_1.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
    AND NOT EXISTS (
                SELECT /*+ INDEX( cash_hcar_1 HZ_CUST_ACCT_RELATE_N2 ) */
                       'X'
                FROM   hz_cust_acct_relate       cash_hcar_1   --顧客関連マスタ(入金関連)
                WHERE  cash_hcar_1.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
                AND    cash_hcar_1.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
                AND    cash_hcar_1.related_cust_account_id = bill_hzca_1.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
                     )
    UNION ALL
    --②入金先顧客－請求先顧客－出荷先顧客
    SELECT
/* 2009/09/11 Ver1.5 Add Start */
           /*+
             LEADING(ship_hzca_2)
             USE_NL(ship_hzca_2 bill_hzca_2 cash_hzca_2 bill_hcar_2 cash_hcar_2 cash_hzad_2 bill_hzad_2 ship_hzad_2)
           */
/* 2009/09/11 Ver1.5 Add End   */
           cash_hzca_2.cust_account_id           AS cash_account_id         --入金先顧客ID
          ,cash_hzca_2.account_number            AS cash_account_number     --入金先顧客コード
          ,bill_hzca_2.cust_account_id           AS bill_account_id         --請求先顧客ID
          ,bill_hzca_2.account_number            AS bill_account_number     --請求先顧客コード
          ,ship_hzca_2.cust_account_id           AS ship_account_id         --出荷先顧客ID
          ,ship_hzca_2.account_number            AS ship_account_number     --出荷先顧客コード
          ,cash_hzad_2.receiv_base_code          AS cash_receiv_base_code   --入金拠点コード
          ,bill_hzca_2.party_id                  AS bill_party_id           --パーティID
          ,bill_hzad_2.bill_base_code            AS bill_bill_base_code     --請求拠点コード
          ,bill_hzlo_2.postal_code               AS bill_postal_code        --郵便番号
          ,bill_hzlo_2.state                     AS bill_state              --都道府県
          ,bill_hzlo_2.city                      AS bill_city               --市・区
          ,bill_hzlo_2.address1                  AS bill_address1           --住所1
          ,bill_hzlo_2.address2                  AS bill_address2           --住所2
          ,bill_hzlo_2.address_lines_phonetic    AS bill_tel_num            --電話番号
          ,bill_hzcp_2.cons_inv_flag             AS bill_cons_inv_flag      --一括請求書発行フラグ
          ,bill_hzad_2.torihikisaki_code         AS bill_torihikisaki_code  --取引先コード
          ,bill_hzad_2.store_code                AS bill_store_code         --店舗コード
          ,bill_hzad_2.cust_store_name           AS bill_cust_store_name    --顧客店舗名称
          ,bill_hzad_2.tax_div                   AS bill_tax_div            --消費税区分
          ,bill_hsua_2.attribute4                AS bill_cred_rec_code1     --売掛コード1(請求書)
          ,bill_hsua_2.attribute5                AS bill_cred_rec_code2     --売掛コード2(事業所)
          ,bill_hsua_2.attribute6                AS bill_cred_rec_code3     --売掛コード3(その他)
          ,bill_hsua_2.attribute7                AS bill_invoice_type       --請求書出力形式
          ,bill_hsua_2.payment_term_id           AS bill_payment_term_id    --支払条件
          ,bill_hsua_2.attribute2                AS bill_payment_term2      --第2支払条件
          ,bill_hsua_2.attribute3                AS bill_payment_term3      --第3支払条件
          ,bill_hsua_2.tax_rounding_rule         AS bill_tax_round_rule     --税金－端数処理
          ,ship_hzad_2.sale_base_code            AS ship_sale_base_code     --売上拠点コード
    FROM   hz_cust_accounts          cash_hzca_2              --入金先顧客マスタ
          ,hz_cust_acct_sites        cash_hasa_2              --入金先顧客所在地
          ,xxcmm_cust_accounts       cash_hzad_2              --入金先顧客追加情報
          ,hz_cust_accounts          bill_hzca_2              --請求先顧客マスタ
          ,hz_cust_acct_sites        bill_hasa_2              --請求先顧客所在地
          ,hz_cust_site_uses         bill_hsua_2              --請求先顧客使用目的
          ,xxcmm_cust_accounts       bill_hzad_2              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_2              --請求先パーティサイト
          ,hz_locations              bill_hzlo_2              --請求先顧客事業所
          ,hz_customer_profiles      bill_hzcp_2              --請求先顧客プロファイル
          ,hz_cust_accounts          ship_hzca_2              --出荷先顧客マスタ
          ,hz_cust_acct_sites        ship_hasa_2              --出荷先顧客所在地
          ,hz_cust_site_uses         ship_hsua_2              --出荷先顧客使用目的
          ,xxcmm_cust_accounts       ship_hzad_2              --出荷先顧客追加情報
          ,hz_cust_acct_relate       cash_hcar_2              --顧客関連マスタ(入金関連)
          ,hz_cust_acct_relate       bill_hcar_2              --顧客関連マスタ(請求関連)
    WHERE  cash_hzca_2.cust_account_id = cash_hcar_2.cust_account_id         --入金先顧客マスタ.顧客ID = 顧客関連マスタ(入金関連).顧客ID
    AND    cash_hzca_2.cust_account_id = cash_hzad_2.customer_id             --入金先顧客マスタ.顧客ID = 入金先顧客追ﾁ情報.顧客ID
    AND    cash_hcar_2.related_cust_account_id = bill_hzca_2.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
    AND    bill_hzca_2.cust_account_id = bill_hcar_2.cust_account_id         --請求先顧客マスタ.顧客ID = 顧客関連マスタ(請求関連).顧客ID
    AND    bill_hcar_2.related_cust_account_id = ship_hzca_2.cust_account_id --顧客関連マスタ(請求関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
    AND    cash_hzca_2.customer_class_code = '14'                            --請求先顧客.顧客区分 = '14'(売掛管理先顧客)
    AND    ship_hzca_2.customer_class_code IN ('10','12')                    --請求先顧客.顧客区分 = '10'(顧客)
    AND    cash_hcar_2.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
    AND    cash_hcar_2.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
    AND    bill_hcar_2.status = 'A'                                          --顧客関連マスタ(請求関連).ステータス = ‘A’
    AND    bill_hcar_2.attribute1 = '1'                                      --顧客関連マスタ(請求関連).関連分類 = ‘1’ (請求)
    AND    bill_hzca_2.cust_account_id = bill_hzad_2.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    bill_hzca_2.cust_account_id = bill_hasa_2.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_2.cust_acct_site_id = bill_hsua_2.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hsua_2.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
    AND    cash_hzca_2.cust_account_id = cash_hasa_2.cust_account_id         --入金先顧客マスタ.顧客ID = 入金先顧客所在地.顧客ID
    AND    ship_hzca_2.cust_account_id = ship_hzad_2.customer_id             --出荷先顧客マスタ.顧客ID = 出荷先顧客追加情報.顧客ID
    AND    ship_hzca_2.cust_account_id = ship_hasa_2.cust_account_id         --出荷先顧客マスタ.顧客ID = 出荷先顧客所在地.顧客ID
    AND    ship_hasa_2.cust_acct_site_id = ship_hsua_2.cust_acct_site_id     --出荷先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    bill_hasa_2.party_site_id = bill_hzps_2.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID
    AND    bill_hzps_2.location_id = bill_hzlo_2.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID
    AND    bill_hsua_2.site_use_id = bill_hzcp_2.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
    UNION ALL
    --③入金先顧客－請求先顧客＆出荷先顧客
    SELECT
/* 2009/09/11 Ver1.5 Add Start */
           /*+
             LEADING(ship_hzca_3)
             USE_NL(ship_hzca_3 cash_hzca_3 cash_hcar_3)
             USE_NL(bill_hzad_3)
             USE_NL(cash_hasa_3)
             USE_NL(bill_hasa_3)
           */
/* 2009/09/11 Ver1.5 Add End   */
           cash_hzca_3.cust_account_id             AS cash_account_id         --入金先顧客ID
          ,cash_hzca_3.account_number              AS cash_account_number     --入金先顧客コード
          ,ship_hzca_3.cust_account_id             AS bill_account_id         --請求先顧客ID
          ,ship_hzca_3.account_number              AS bill_account_number     --請求先顧客コード
          ,ship_hzca_3.cust_account_id             AS ship_account_id         --出荷先顧客ID
          ,ship_hzca_3.account_number              AS ship_account_number     --出荷先顧客コード
          ,cash_hzad_3.receiv_base_code            AS cash_receiv_base_code   --入金拠点コード
          ,ship_hzca_3.party_id                    AS bill_party_id           --パーティID
          ,bill_hzad_3.bill_base_code              AS bill_bill_base_code     --請求拠点コード
          ,bill_hzlo_3.postal_code                 AS bill_postal_code        --郵便番号
          ,bill_hzlo_3.state                       AS bill_state              --都道府県
          ,bill_hzlo_3.city                        AS bill_city               --市・区
          ,bill_hzlo_3.address1                    AS bill_address1           --住所1
          ,bill_hzlo_3.address2                    AS bill_address2           --住所2
          ,bill_hzlo_3.address_lines_phonetic      AS bill_tel_num            --電話番号
          ,bill_hzcp_3.cons_inv_flag               AS bill_cons_inv_flag      --一括請求書発行フラグ
          ,bill_hzad_3.torihikisaki_code           AS bill_torihikisaki_code  --取引先コード
          ,bill_hzad_3.store_code                  AS bill_store_code         --店舗コード
          ,bill_hzad_3.cust_store_name             AS bill_cust_store_name    --顧客店舗名称
          ,bill_hzad_3.tax_div                     AS bill_tax_div            --消費税区分
          ,bill_hsua_3.attribute4                  AS bill_cred_rec_code1     --売掛コード1(請求書)
          ,bill_hsua_3.attribute5                  AS bill_cred_rec_code2     --売掛コード2(事業所)
          ,bill_hsua_3.attribute6                  AS bill_cred_rec_code3     --売掛コード3(その他)
          ,bill_hsua_3.attribute7                  AS bill_invoice_type       --請求書出力形式
          ,bill_hsua_3.payment_term_id             AS bill_payment_term_id    --支払条件
          ,bill_hsua_3.attribute2                  AS bill_payment_term2      --第2支払条件
          ,bill_hsua_3.attribute3                  AS bill_payment_term3      --第3支払条件
          ,bill_hsua_3.tax_rounding_rule           AS bill_tax_round_rule     --税金－端数処理
          ,bill_hzad_3.sale_base_code              AS ship_sale_base_code     --売上拠点コード
    FROM   hz_cust_accounts          cash_hzca_3              --入金先顧客マスタ
          ,hz_cust_acct_sites        cash_hasa_3              --入金先顧客所在地
          ,xxcmm_cust_accounts       cash_hzad_3              --入金先顧客追加情報
          ,hz_cust_accounts          ship_hzca_3              --出荷先顧客マスタ　※請求先含む
          ,hz_cust_acct_sites        bill_hasa_3              --請求先顧客所在地
          ,hz_cust_site_uses         bill_hsua_3              --請求先顧客使用目的
          ,hz_cust_site_uses         ship_hsua_3              --出荷先顧客使用目的
          ,xxcmm_cust_accounts       bill_hzad_3              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_3              --請求先パーティサイト
          ,hz_locations              bill_hzlo_3              --請求先顧客事業所
          ,hz_customer_profiles      bill_hzcp_3              --請求先顧客プロファイル
          ,hz_cust_acct_relate       cash_hcar_3              --顧客関連マスタ(入金関連)
    WHERE  cash_hzca_3.cust_account_id = cash_hcar_3.cust_account_id         --入金先顧客マスタ.顧客ID = 顧客関連マスタ(入金関連).顧客ID
    AND    cash_hzca_3.cust_account_id = cash_hzad_3.customer_id             --入金先顧客マスタ.顧客ID = 入金先顧客追加情報.顧客ID
    AND    cash_hcar_3.related_cust_account_id = ship_hzca_3.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
    AND    cash_hzca_3.customer_class_code = '14'                            --入金先顧客.顧客区分 = '14'(売掛管理先顧客)
    AND    ship_hzca_3.customer_class_code IN ('10','12')                            --請求先顧客.顧客区分 = '10'(顧客)
    AND    cash_hcar_3.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
    AND    cash_hcar_3.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
    AND    NOT EXISTS (
               SELECT /*+ INDEX( ex_hcar_3 HZ_CUST_ACCT_RELATE_N1 ) */
                      'X'
               FROM   hz_cust_acct_relate     ex_hcar_3       --顧客関連マスタ(請求関連)
               WHERE  ex_hcar_3.cust_account_id = ship_hzca_3.cust_account_id         --顧客関連マスタ(請求関連).顧客ID = 出荷先顧客マスタ.顧客ID
               AND    ex_hcar_3.status = 'A'                                          --顧客関連マスタ(請求関連).ステータス = ‘A’
                    )
    AND    ship_hzca_3.cust_account_id = bill_hzad_3.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    ship_hzca_3.cust_account_id = bill_hasa_3.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_3.cust_acct_site_id = bill_hsua_3.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hasa_3.cust_acct_site_id = ship_hsua_3.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    bill_hsua_3.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
    AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    cash_hzca_3.cust_account_id = cash_hasa_3.cust_account_id         --入金先顧客マスタ.顧客ID = 入金先顧客所在地.顧客ID
    AND    bill_hasa_3.party_site_id = bill_hzps_3.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID
    AND    bill_hzps_3.location_id = bill_hzlo_3.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID
    AND    bill_hsua_3.site_use_id = bill_hzcp_3.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
    UNION ALL
    --④入金先顧客＆請求先顧客＆出荷先顧客
    SELECT
/* 2009/09/11 Ver1.5 Add Start */
           /*+
             LEADING(ship_hzca_4)
             USE_NL(ship_hzca_4 bill_hasa_4 bill_hsua_4 ship_hsua_4)
             USE_NL(bill_hzad_4)
           */
/* 2009/09/11 Ver1.5 Add End   */
           ship_hzca_4.cust_account_id               AS cash_account_id         --入金先顧客ID
          ,ship_hzca_4.account_number                AS cash_account_number     --入金先顧客コード
          ,ship_hzca_4.cust_account_id               AS bill_account_id         --請求先顧客ID
          ,ship_hzca_4.account_number                AS bill_account_number     --請求先顧客コード
          ,ship_hzca_4.cust_account_id               AS ship_account_id         --出荷先顧客ID
          ,ship_hzca_4.account_number                AS ship_account_number     --出荷先顧客コード
          ,bill_hzad_4.receiv_base_code              AS cash_receiv_base_code   --入金拠点コード
          ,ship_hzca_4.party_id                      AS bill_party_id           --パーティID
          ,bill_hzad_4.bill_base_code                AS bill_bill_base_code     --請求拠点コード
          ,bill_hzlo_4.postal_code                   AS bill_postal_code        --郵便番号
          ,bill_hzlo_4.state                         AS bill_state              --都道府県
          ,bill_hzlo_4.city                          AS bill_city               --市・区
          ,bill_hzlo_4.address1                      AS bill_address1           --住所1
          ,bill_hzlo_4.address2                      AS bill_address2           --住所2
          ,bill_hzlo_4.address_lines_phonetic        AS bill_tel_num            --電話番号
          ,bill_hzcp_4.cons_inv_flag                 AS bill_cons_inv_flag      --一括請求書発行フラグ
          ,bill_hzad_4.torihikisaki_code             AS bill_torihikisaki_code  --取引先コード
          ,bill_hzad_4.store_code                    AS bill_store_code         --店舗コード
          ,bill_hzad_4.cust_store_name               AS bill_cust_store_name    --顧客店舗名称
          ,bill_hzad_4.tax_div                       AS bill_tax_div            --消費税区分
          ,bill_hsua_4.attribute4                    AS bill_cred_rec_code1     --売掛コード1(請求書)
          ,bill_hsua_4.attribute5                    AS bill_cred_rec_code2     --売掛コード2(事業所)
          ,bill_hsua_4.attribute6                    AS bill_cred_rec_code3     --売掛コード3(その他)
          ,bill_hsua_4.attribute7                    AS bill_invoice_type       --請求書出力形式
          ,bill_hsua_4.payment_term_id               AS bill_payment_term_id    --支払条件
          ,bill_hsua_4.attribute2                    AS bill_payment_term2      --第2支払条件
          ,bill_hsua_4.attribute3                    AS bill_payment_term3      --第3支払条件
          ,bill_hsua_4.tax_rounding_rule             AS bill_tax_round_rule     --税金－端数処理
          ,bill_hzad_4.sale_base_code                AS ship_sale_base_code     --売上拠点コード
    FROM   hz_cust_accounts          ship_hzca_4              --出荷先顧客マスタ　※入金先・請求先含む
          ,hz_cust_acct_sites        bill_hasa_4              --請求先顧客所在地
          ,hz_cust_site_uses         bill_hsua_4              --請求先顧客使用目的
          ,hz_cust_site_uses         ship_hsua_4              --出荷先顧客使用目的
          ,xxcmm_cust_accounts       bill_hzad_4              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_4              --請求先パーティサイト
          ,hz_locations              bill_hzlo_4              --請求先顧客事業所
          ,hz_customer_profiles      bill_hzcp_4              --請求先顧客プロファイル
    WHERE  (
             ship_hzca_4.customer_class_code  IS NULL
           OR
             ship_hzca_4.customer_class_code  IN ( '10', '12' )               --請求先顧客.顧客区分 = '10'(顧客)、'12'(上様顧客)
           )
    AND    NOT EXISTS (
               SELECT /*+ INDEX( ex_hcar_41 HZ_CUST_ACCT_RELATE_N1 ) */
                      'X'
               FROM   hz_cust_acct_relate     ex_hcar_41      --顧客関連マスタ
               WHERE
                      ex_hcar_41.cust_account_id = ship_hzca_4.cust_account_id          --顧客関連マスタ(請求関連).顧客ID = 出荷先顧客マスタ.顧客ID
               AND    ex_hcar_41.status = 'A'                                           --顧客関連マスタ(請求関連).ステータス = ‘A’
/* 2009/11/12 Ver1.6 Add Start */
               AND    ex_hcar_41.attribute1 = '2'
/* 2009/11/12 Ver1.6 Add End */
                    )
    AND    NOT EXISTS (
               SELECT /*+ INDEX( ex_hcar_42 HZ_CUST_ACCT_RELATE_N2 ) */
                      'X'
               FROM   hz_cust_acct_relate     ex_hcar_42      --顧客関連マスタ
               WHERE
                      ex_hcar_42.related_cust_account_id = ship_hzca_4.cust_account_id   --顧客関連マスタ(請求関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
               AND    ex_hcar_42.status = 'A'                                            --顧客関連マスタ(請求関連).ステータス = ‘A’
/* 2009/11/12 Ver1.6 Add Start */
               AND    ex_hcar_42.attribute1 = '2'
/* 2009/11/12 Ver1.6 Add End */
                    )
    AND    ship_hzca_4.cust_account_id = bill_hzad_4.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    ship_hzca_4.cust_account_id = bill_hasa_4.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_4.cust_acct_site_id = bill_hsua_4.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hasa_4.cust_acct_site_id = ship_hsua_4.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    bill_hsua_4.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
    AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    bill_hasa_4.party_site_id = bill_hzps_4.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID
    AND    bill_hzps_4.location_id = bill_hzlo_4.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID
    AND    bill_hsua_4.site_use_id = bill_hzcp_4.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
) cust_hier;
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.cash_account_id         IS  '入金先顧客ID';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.cash_account_number     IS  '入金先顧客コード';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.cash_account_name       IS  '入金先顧客名称';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_account_id         IS  '請求先顧客ID';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_account_number     IS  '請求先顧客コード';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_account_name       IS  '請求先顧客名称';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.ship_account_id         IS  '出荷先顧客ID';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.ship_account_number     IS  '出荷先顧客コード';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.ship_account_name       IS  '出荷先顧客名称';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.cash_receiv_base_code   IS  '入金拠点コード';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_party_id           IS  'パーティID';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_bill_base_code     IS  '請求拠点コード';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_postal_code        IS  '郵便番号';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_state              IS  '都道府県';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_city               IS  '市・区';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_address1           IS  '住所1';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_address2           IS  '住所2';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_tel_num            IS  '電話番号';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_cons_inv_flag      IS  '一括請求書発行フラグ';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_torihikisaki_code  IS  '取引先コード';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_store_code         IS  '店舗コード';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_cust_store_name    IS  '顧客店舗名称';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_tax_div            IS  '消費税区分';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_cred_rec_code1     IS  '売掛コード1(請求書)';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_cred_rec_code2     IS  '売掛コード2(事業所)';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_cred_rec_code3     IS  '売掛コード3(その他)';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_invoice_type       IS  '請求書出力形式';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_payment_term_id    IS  '支払条件';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_payment_term2      IS  '第2支払条件';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_payment_term3      IS  '第3支払条件';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.bill_tax_round_rule     IS  '税金－端数処理';
COMMENT ON  COLUMN  xxcos_cust_hierarchy_v.ship_sale_base_code     IS  '売上拠点コード';
--
COMMENT ON  TABLE   xxcos_cust_hierarchy_v                         IS  'XXCOS顧客階層ビュー';
