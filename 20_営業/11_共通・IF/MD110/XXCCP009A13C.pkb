CREATE OR REPLACE PACKAGE BODY XXCCP009A13C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A13C(body)
 * Description      : 顧客階層情報CSV出力
 * MD.070           : 顧客階層情報CSV出力 (MD070_IPO_CCP_009_A13)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/01/13     1.0  SCSK H.Wajima   [E_本稼動_12836]新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP009A13C'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,                               --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,                               --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)                               --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
    cv_msg_no_parameter     CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- パラメータなし
    cv_org_id               CONSTANT VARCHAR2(6)   := 'ORG_ID';            -- 営業単位ID
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_org_id               NUMBER;    -- ログインユーザの営業単位ID
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 顧客階層ビュー情報取得
    CURSOR get_hz_cust_accounts_cur( in_org_id NUMBER )
      IS
        SELECT
            customer_v.cash_account_id     --入金先顧客ID
          , customer_v.cash_account_number --入金先顧客コード
          , customer_v.cash_account_name   --入金先顧客名称
          , customer_v.bill_account_id     --請求先顧客ID
          , customer_v.bill_account_number --請求先顧客コード
          , customer_v.bill_account_name   --請求先顧客名称
          , customer_v.ship_account_id     --出荷先顧客ID
          , customer_v.ship_account_number --出荷先顧客コード
          , customer_v.ship_account_name   --出荷先顧客名称
        FROM
          (
            SELECT
                     temp.cash_account_id                          AS cash_account_id        --入金先顧客ID
                    ,temp.cash_account_number                      AS cash_account_number    --入金先顧客コード
                    ,(SELECT hzpt.party_name AS party_name
                      FROM   apps.hz_parties       hzpt,
                             apps.hz_cust_accounts hzca
                      WHERE  hzca.party_id = hzpt.party_id
                      AND    hzca.account_number = temp.cash_account_number
                     )                                             AS cash_account_name      --入金先顧客名称
                    ,temp.bill_account_id                          AS bill_account_id        --請求先顧客ID
                    ,temp.bill_account_number                      AS bill_account_number    --請求先顧客コード
                    ,(SELECT hzpt.party_name AS party_name
                      FROM   apps.hz_parties       hzpt,
                             apps.hz_cust_accounts hzca
                      WHERE  hzca.party_id = hzpt.party_id
                      AND    hzca.account_number = temp.bill_account_number
                     )                                             AS bill_account_name      --請求先顧客名称
                    ,temp.ship_account_id                          AS ship_account_id        --出荷先顧客ID
                    ,temp.ship_account_number                      AS ship_account_number    --出荷先顧客コード
                    ,(SELECT hzpt.party_name AS party_name
                      FROM   apps.hz_parties       hzpt,
                             apps.hz_cust_accounts hzca
                      WHERE  hzca.party_id = hzpt.party_id
                      AND    hzca.account_number = temp.ship_account_number
                     )                                             AS ship_account_name      --出荷先顧客名称
                    ,temp.cash_receiv_base_code                    AS cash_receiv_base_code  --入金拠点コード
                    ,temp.bill_party_id                            AS bill_party_id          --パーティID
                    ,temp.bill_bill_base_code                      AS bill_bill_base_code    --請求拠点コード
                    ,temp.bill_postal_code                         AS bill_postal_code       --郵便番号
                    ,temp.bill_state                               AS bill_state             --都道府県
                    ,temp.bill_city                                AS bill_city              --市・区
                    ,temp.bill_address1                            AS bill_address1          --住所1
                    ,temp.bill_address2                            AS bill_address2          --住所2
                    ,temp.bill_tel_num                             AS bill_tel_num           --電話番号
                    ,temp.bill_cons_inv_flag                       AS bill_cons_inv_flag     --一括請求書発行フラグ
                    ,temp.bill_torihikisaki_code                   AS bill_torihikisaki_code --取引先コード
                    ,temp.bill_store_code                          AS bill_store_code        --店舗コード
                    ,temp.bill_cust_store_name                     AS bill_cust_store_name   --顧客店舗名称
                    ,temp.bill_tax_div                             AS bill_tax_div           --消費税区分
                    ,temp.bill_cred_rec_code1                      AS bill_cred_rec_code1    --売掛コード1(請求書)
                    ,temp.bill_cred_rec_code2                      AS bill_cred_rec_code2    --売掛コード2(事業所)
                    ,temp.bill_cred_rec_code3                      AS bill_cred_rec_code3    --売掛コード3(その他)
                    ,temp.bill_invoice_type                        AS bill_invoice_type      --請求書出力形式
                    ,temp.bill_payment_term_id                     AS bill_payment_term_id   --支払条件
                    ,TO_NUMBER(temp.bill_payment_term2)            AS bill_payment_term2     --第2支払条件
                    ,TO_NUMBER(temp.bill_payment_term3)            AS bill_payment_term3     --第3支払条件
                    ,temp.bill_tax_round_rule                      AS bill_tax_round_rule    --税金－端数処理
                    ,temp.ship_sale_base_code                      AS ship_sale_base_code    --売上拠点コード
                    ,temp.bill_attribute4                          AS bill_attribute4        -- 発行サイクル(請求先)
                    ,temp.bill_attribute7                          AS bill_attribute7        -- 売掛コード1(請求先)
                    ,temp.bill_attribute8                          AS bill_attribute8        -- 請求書出力形式(請求先)
                    ,temp.bill_site_use_id                         AS bill_site_use_id       -- 使用目的内部ID(請求先)
                    ,temp.ship_attribute4                          AS ship_attribute4        -- 発行サイクル(出荷先)
                    ,temp.ship_attribute7                          AS ship_attribute7        -- 売掛コード1(出荷先)
                    ,temp.ship_attribute8                          AS ship_attribute8        -- 請求書出力形式(出荷先)
                    ,temp.ship_site_use_id                         AS ship_site_use_id       -- 使用目的内部ID(出荷先)
                    ,temp.ship_payment_term_id                     AS ship_payment_term_id   -- 支払条件
              FROM   (  --①入金先顧客＆請求先顧客－出荷先顧客
                      SELECT /*+ LEADING(bill_hsua_1)
                                 USE_NL( bill_hzca_1 bill_hasa_1 bill_hsua_1 bill_hzad_1 bill_hzps_1 bill_hzlo_1 bill_hzcp_1 bill_hcar_1)
                                 USE_NL( ship_hzca_1 ship_hasa_1 ship_hsua_1 ship_hzad_1)
                             */
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
            -----------------------------------------------------------------------------------------------------------
                            ,bill_hsua_1.attribute4              AS bill_attribute4         -- 発行サイクル(請求先)
                            ,bill_hsua_1.attribute7              AS bill_attribute7         -- 売掛コード1(請求先)
                            ,bill_hsua_1.attribute8              AS bill_attribute8         -- 請求書出力形式(請求先)
                            ,bill_hsua_1.site_use_id             AS bill_site_use_id        -- 使用目的内部ID(請求先)
                            ,ship_hsua_1.attribute4              AS ship_attribute4         -- 発行サイクル(出荷先)
                            ,ship_hsua_1.attribute7              AS ship_attribute7         -- 売掛コード1(出荷先)
                            ,ship_hsua_1.attribute8              AS ship_attribute8         -- 請求書出力形式(出荷先)
                            ,ship_hsua_1.site_use_id             AS ship_site_use_id        -- 使用目的内部ID(出荷先)
                            ,ship_hsua_1.payment_term_id         AS ship_payment_term_id    -- 支払条件
            -----------------------------------------------------------------------------------------------------------
                      FROM   apps.hz_cust_accounts          bill_hzca_1              --請求先顧客マスタ
                            ,apps.hz_cust_acct_sites_all    bill_hasa_1              --請求先顧客所在地
                            ,apps.hz_cust_site_uses_all     bill_hsua_1              --請求先顧客使用目的
                            ,apps.xxcmm_cust_accounts       bill_hzad_1              --請求先顧客追加情報
                            ,apps.hz_party_sites            bill_hzps_1              --請求先パーティサイト
                            ,apps.hz_locations              bill_hzlo_1              --請求先顧客事業所
                            ,apps.hz_customer_profiles      bill_hzcp_1              --請求先顧客プロファイル
                            ,apps.hz_cust_accounts          ship_hzca_1              --出荷先顧客マスタ
                            ,apps.hz_cust_acct_sites_all    ship_hasa_1              --出荷先顧客所在地
                            ,apps.hz_cust_site_uses_all     ship_hsua_1              --出荷先顧客使用目的
                            ,apps.xxcmm_cust_accounts       ship_hzad_1              --出荷先顧客追加情報
                            ,apps.hz_cust_acct_relate_all   bill_hcar_1              --顧客関連マスタ(請求関連)
                      WHERE  bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --請求先顧客マスタ.顧客ID = 顧客関連マスタ.顧客ID
                      AND    bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --顧客関連マスタ.関連先顧客ID = 出荷先顧客マスタ.顧客ID
                      AND    bill_hzca_1.customer_class_code = '14'                            --請求先顧客.顧客区分 = '14'(売掛管理先顧客)
                      AND    bill_hcar_1.status = 'A'                                          --顧客関連マスタ.ステータス = ‘A’
                      AND    bill_hcar_1.attribute1 = '1'                                      --顧客関連マスタ.関連分類 = ‘1’ (請求)
                      AND    bill_hasa_1.org_id = in_org_id                                    --請求先顧客所在地.組織ID = ログインユーザの組織ID
                      AND    ship_hasa_1.org_id = in_org_id                                    --出荷先顧客所在地.組織ID = ログインユーザの組織ID
                      AND    bill_hcar_1.org_id = in_org_id                                    --顧客関連マスタ(請求関連).組織ID = ログインユーザの組織ID
                      AND    bill_hsua_1.org_id = in_org_id                                    --請求先顧客使用目的.組織ID = ログインユーザの組織ID
                      AND    ship_hsua_1.org_id = in_org_id                                    --出荷先顧客使用目的.組織ID = ログインユーザの組織ID
                      AND    bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
                      AND    bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
                      AND    bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
                      AND    bill_hsua_1.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
                      AND    bill_hsua_1.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
                      AND    ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --出荷先顧客マスタ.顧客ID = 出荷先顧客所在地.顧客ID
                      AND    ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --出荷先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
                      AND    ship_hsua_1.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
                      AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
                      AND    ship_hzca_1.cust_account_id = ship_hzad_1.customer_id             --出荷先顧客マスタ.顧客ID = 出荷先顧客追加情報.顧客ID
                      AND    bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID
                      AND    bill_hzps_1.location_id = bill_hzlo_1.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID
                      AND    bill_hsua_1.site_use_id = bill_hzcp_1.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
                      AND NOT EXISTS (
                                  SELECT 'X'
                                  FROM   apps.hz_cust_acct_relate_all   cash_hcar_1                        --顧客関連マスタ(入金関連)
                                  WHERE  cash_hcar_1.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
                                  AND    cash_hcar_1.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
                                  AND    cash_hcar_1.related_cust_account_id = bill_hzca_1.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
                                  AND    cash_hcar_1.org_id = in_org_id                                    --顧客関連マスタ(入金関連).組織ID = ログインユーザの組織ID
                                       )
                        UNION ALL
                      --②入金先顧客－請求先顧客－出荷先顧客
                      SELECT /*+ LEADING(bill_hsua_2)
                                 USE_NL( cash_hzca_2 cash_hasa_2 cash_hzad_2 cash_hcar_2)
                                 USE_NL( bill_hzca_2 bill_hasa_2 bill_hsua_2 bill_hzad_2 bill_hzps_2 bill_hzlo_2 bill_hzcp_2 bill_hcar_2)
                                 USE_NL( ship_hzca_2 ship_hasa_2 ship_hsua_2 ship_hzad_2)
                             */
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
            -----------------------------------------------------------------------------------------------------------
                            ,bill_hsua_2.attribute4              AS bill_attribute4         -- 発行サイクル(請求先)
                            ,bill_hsua_2.attribute7              AS bill_attribute7         -- 売掛コード1(請求先)
                            ,bill_hsua_2.attribute8              AS bill_attribute8         -- 請求書出力形式(請求先)
                            ,bill_hsua_2.site_use_id             AS bill_site_use_id        -- 使用目的内部ID(請求先)
                            ,ship_hsua_2.attribute4              AS ship_attribute4         -- 発行サイクル(出荷先)
                            ,ship_hsua_2.attribute7              AS ship_attribute7         -- 売掛コード1(出荷先)
                            ,ship_hsua_2.attribute8              AS ship_attribute8         -- 請求書出力形式(出荷先)
                            ,ship_hsua_2.site_use_id             AS ship_site_use_id        -- 使用目的内部ID(出荷先)
                            ,ship_hsua_2.payment_term_id         AS ship_payment_term_id    -- 支払条件
            -----------------------------------------------------------------------------------------------------------
                      FROM   apps.hz_cust_accounts          cash_hzca_2              --入金先顧客マスタ
                            ,apps.hz_cust_acct_sites_all    cash_hasa_2              --入金先顧客所在地
                            ,apps.xxcmm_cust_accounts       cash_hzad_2              --入金先顧客追加情報
                            ,apps.hz_cust_accounts          bill_hzca_2              --請求先顧客マスタ
                            ,apps.hz_cust_acct_sites_all    bill_hasa_2              --請求先顧客所在地
                            ,apps.hz_cust_site_uses_all     bill_hsua_2              --請求先顧客使用目的
                            ,apps.xxcmm_cust_accounts       bill_hzad_2              --請求先顧客追加情報
                            ,apps.hz_party_sites            bill_hzps_2              --請求先パーティサイト
                            ,apps.hz_locations              bill_hzlo_2              --請求先顧客事業所
                            ,apps.hz_customer_profiles      bill_hzcp_2              --請求先顧客プロファイル
                            ,apps.hz_cust_accounts          ship_hzca_2              --出荷先顧客マスタ
                            ,apps.hz_cust_acct_sites_all    ship_hasa_2              --出荷先顧客所在地
                            ,apps.hz_cust_site_uses_all     ship_hsua_2              --出荷先顧客使用目的
                            ,apps.xxcmm_cust_accounts       ship_hzad_2              --出荷先顧客追加情報
                            ,apps.hz_cust_acct_relate_all   cash_hcar_2              --顧客関連マスタ(入金関連)
                            ,apps.hz_cust_acct_relate_all   bill_hcar_2              --顧客関連マスタ(請求関連)
                      WHERE  cash_hzca_2.cust_account_id = cash_hcar_2.cust_account_id         --入金先顧客マスタ.顧客ID = 顧客関連マスタ(入金関連).顧客ID
                      AND    cash_hzca_2.cust_account_id = cash_hzad_2.customer_id             --入金先顧客マスタ.顧客ID = 入金先顧客追加情報.顧客ID
                      AND    cash_hcar_2.related_cust_account_id = bill_hzca_2.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
                      AND    bill_hzca_2.cust_account_id = bill_hcar_2.cust_account_id         --請求先顧客マスタ.顧客ID = 顧客関連マスタ(請求関連).顧客ID
                      AND    bill_hcar_2.related_cust_account_id = ship_hzca_2.cust_account_id --顧客関連マスタ(請求関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
                      AND    cash_hzca_2.customer_class_code = '14'                            --請求先顧客.顧客区分 = '14'(売掛管理先顧客)
                      AND    ship_hzca_2.customer_class_code = '10'                            --請求先顧客.顧客区分 = '10'(顧客)
                      AND    cash_hcar_2.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
                      AND    cash_hcar_2.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
                      AND    bill_hcar_2.status = 'A'                                          --顧客関連マスタ(請求関連).ステータス = ‘A’
                      AND    bill_hcar_2.attribute1 = '1'                                      --顧客関連マスタ(請求関連).関連分類 = ‘1’ (請求)
                      AND    cash_hasa_2.org_id = in_org_id                                    --入金先顧客所在地.組織ID = ログインユーザの組織ID
                      AND    bill_hasa_2.org_id = in_org_id                                    --請求先顧客所在地.組織ID = ログインユーザの組織ID
                      AND    ship_hasa_2.org_id = in_org_id                                    --出荷先顧客所在地.組織ID = ログインユーザの組織ID
                      AND    cash_hcar_2.org_id = in_org_id                                    --顧客関連マスタ(入金関連).組織ID = ログインユーザの組織ID
                      AND    bill_hcar_2.org_id = in_org_id                                    --顧客関連マスタ(請求関連).組織ID = ログインユーザの組織ID
                      AND    bill_hsua_2.org_id = in_org_id                                    --請求先顧客使用目的.組織ID = ログインユーザの組織ID
                      AND    ship_hsua_2.org_id = in_org_id                                    --出荷先顧客使用目的.組織ID = ログインユーザの組織ID
                      AND    bill_hzca_2.cust_account_id = bill_hzad_2.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
                      AND    bill_hzca_2.cust_account_id = bill_hasa_2.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
                      AND    bill_hasa_2.cust_acct_site_id = bill_hsua_2.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
                      AND    bill_hsua_2.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
                      AND    bill_hsua_2.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
                      AND    cash_hzca_2.cust_account_id = cash_hasa_2.cust_account_id         --入金先顧客マスタ.顧客ID = 入金先顧客所在地.顧客ID
                      AND    ship_hzca_2.cust_account_id = ship_hzad_2.customer_id             --出荷先顧客マスタ.顧客ID = 出荷先顧客追加情報.顧客ID
                      AND    ship_hzca_2.cust_account_id = ship_hasa_2.cust_account_id         --出荷先顧客マスタ.顧客ID = 出荷先顧客所在地.顧客ID
                      AND    ship_hasa_2.cust_acct_site_id = ship_hsua_2.cust_acct_site_id     --出荷先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
                      AND    ship_hsua_2.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
                      AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
                      AND    bill_hasa_2.party_site_id = bill_hzps_2.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID
                      AND    bill_hzps_2.location_id = bill_hzlo_2.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID
                      AND    bill_hsua_2.site_use_id = bill_hzcp_2.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
                        UNION ALL
                      --③入金先顧客－請求先顧客＆出荷先顧客
                      SELECT /*+ LEADING(bill_hsua_3)
                                 USE_NL( cash_hzca_3 cash_hasa_3 cash_hzad_3 cash_hcar_3 )
                                 USE_NL( bill_hasa_3 bill_hsua_3 bill_hzad_3 bill_hzps_3 bill_hzlo_3 bill_hzcp_3 )
                                 USE_NL( ship_hzca_3 ship_hsua_3 )
                             */
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
            -----------------------------------------------------------------------------------------------------------
                            ,bill_hsua_3.attribute4                  AS bill_attribute4         -- 発行サイクル(請求先)
                            ,bill_hsua_3.attribute7                  AS bill_attribute7         -- 売掛コード1(請求先)
                            ,bill_hsua_3.attribute8                  AS bill_attribute8         -- 請求書出力形式(請求先)
                            ,bill_hsua_3.site_use_id                 AS bill_site_use_id        -- 使用目的内部ID(請求先)
                            ,ship_hsua_3.attribute4                  AS ship_attribute4         -- 発行サイクル(出荷先)
                            ,ship_hsua_3.attribute7                  AS ship_attribute7         -- 売掛コード1(出荷先)
                            ,ship_hsua_3.attribute8                  AS ship_attribute8         -- 請求書出力形式(出荷先)
                            ,ship_hsua_3.site_use_id                 AS ship_site_use_id        -- 使用目的内部ID(出荷先)
                            ,ship_hsua_3.payment_term_id             AS ship_payment_term_id    -- 支払条件
            -----------------------------------------------------------------------------------------------------------
                      FROM   apps.hz_cust_accounts          cash_hzca_3              --入金先顧客マスタ
                            ,apps.hz_cust_acct_sites_all    cash_hasa_3              --入金先顧客所在地
                            ,apps.xxcmm_cust_accounts       cash_hzad_3              --入金先顧客追加情報
                            ,apps.hz_cust_accounts          ship_hzca_3              --出荷先顧客マスタ  ※請求先含む
                            ,apps.hz_cust_acct_sites_all    bill_hasa_3              --請求先顧客所在地
                            ,apps.hz_cust_site_uses_all     bill_hsua_3              --請求先顧客使用目的
                            ,apps.hz_cust_site_uses_all     ship_hsua_3              --出荷先顧客使用目的
                            ,apps.xxcmm_cust_accounts       bill_hzad_3              --請求先顧客追加情報
                            ,apps.hz_party_sites            bill_hzps_3              --請求先パーティサイト
                            ,apps.hz_locations              bill_hzlo_3              --請求先顧客事業所
                            ,apps.hz_customer_profiles      bill_hzcp_3              --請求先顧客プロファイル
                            ,apps.hz_cust_acct_relate_all   cash_hcar_3              --顧客関連マスタ(入金関連)
                      WHERE  cash_hzca_3.cust_account_id = cash_hcar_3.cust_account_id         --入金先顧客マスタ.顧客ID = 顧客関連マスタ(入金関連).顧客ID
                      AND    cash_hzca_3.cust_account_id = cash_hzad_3.customer_id             --入金先顧客マスタ.顧客ID = 入金先顧客追加情報.顧客ID
                      AND    cash_hcar_3.related_cust_account_id = ship_hzca_3.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
                      AND    cash_hzca_3.customer_class_code = '14'                            --入金先顧客.顧客区分 = '14'(売掛管理先顧客)
                      AND    ship_hzca_3.customer_class_code = '10'                            --請求先顧客.顧客区分 = '10'(顧客)
                      AND    cash_hcar_3.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
                      AND    cash_hcar_3.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
                      AND    cash_hasa_3.org_id = in_org_id                                    --入金先顧客所在地.組織ID = ログインユーザの組織ID
                      AND    bill_hasa_3.org_id = in_org_id                                    --請求先顧客所在地.組織ID = ログインユーザの組織ID
                      AND    cash_hcar_3.org_id = in_org_id                                    --顧客関連マスタ(入金関連).組織ID = ログインユーザの組織ID
                      AND    bill_hsua_3.org_id = in_org_id                                    --請求先顧客使用目的.組織ID = ログインユーザの組織ID
                      AND    ship_hsua_3.org_id = in_org_id                                    --出荷先顧客使用目的.組織ID = ログインユーザの組織ID
                      AND    NOT EXISTS (
                                 SELECT ROWNUM
                                 FROM   apps.hz_cust_acct_relate_all ex_hcar_3                          --顧客関連マスタ(請求関連)
                                 WHERE  ex_hcar_3.cust_account_id = ship_hzca_3.cust_account_id         --顧客関連マスタ(請求関連).顧客ID = 出荷先顧客マスタ.顧客ID
                                 AND    ex_hcar_3.status = 'A'                                          --顧客関連マスタ(請求関連).ステータス = ‘A’
                                 AND    ex_hcar_3.org_id = in_org_id                                    --顧客関連マスタ(請求関連).組織ID = ログインユーザの組織ID
                                      )
                      AND    ship_hzca_3.cust_account_id = bill_hzad_3.customer_id                      --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
                      AND    ship_hzca_3.cust_account_id = bill_hasa_3.cust_account_id                  --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
                      AND    bill_hasa_3.cust_acct_site_id = bill_hsua_3.cust_acct_site_id              --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
                      AND    bill_hasa_3.cust_acct_site_id = ship_hsua_3.cust_acct_site_id              --請求先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
                      AND    bill_hsua_3.site_use_code = 'BILL_TO'                                      --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
                      AND    bill_hsua_3.status = 'A'                                                   --請求先顧客使用目的.ステータス = 'A'
                      AND    ship_hsua_3.status = 'A'                                                   --出荷先顧客使用目的.ステータス = 'A'
                      AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id                  --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
                      AND    cash_hzca_3.cust_account_id = cash_hasa_3.cust_account_id                  --入金先顧客マスタ.顧客ID = 入金先顧客所在地.顧客ID
                      AND    bill_hasa_3.party_site_id = bill_hzps_3.party_site_id                      --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID
                      AND    bill_hzps_3.location_id = bill_hzlo_3.location_id                          --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID
                      AND    bill_hsua_3.site_use_id = bill_hzcp_3.site_use_id(+)                       --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
                      UNION ALL
                      --④入金先顧客＆請求先顧客＆出荷先顧客
                      SELECT /*+ LEADING(bill_hsua_4)
                                 USE_NL( bill_hasa_4 bill_hsua_4 bill_hzad_4 bill_hzps_4 bill_hzlo_4 bill_hzcp_4 )
                                 USE_NL( ship_hzca_4 ship_hsua_4 )
                             */
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
            -----------------------------------------------------------------------------------------------------------
                            ,bill_hsua_4.attribute4                    AS bill_attribute4         -- 発行サイクル(請求先)
                            ,bill_hsua_4.attribute7                    AS bill_attribute7         -- 売掛コード1(請求先)
                            ,bill_hsua_4.attribute8                    AS bill_attribute8         -- 請求書出力形式(請求先)
                            ,bill_hsua_4.site_use_id                   AS bill_site_use_id        -- 使用目的内部ID(請求先)
                            ,ship_hsua_4.attribute4                    AS ship_attribute4         -- 発行サイクル(出荷先)
                            ,ship_hsua_4.attribute7                    AS ship_attribute7         -- 売掛コード1(出荷先)
                            ,ship_hsua_4.attribute8                    AS ship_attribute8         -- 請求書出力形式(出荷先)
                            ,ship_hsua_4.site_use_id                   AS ship_site_use_id        -- 使用目的内部ID(出荷先)
                            ,ship_hsua_4.payment_term_id               AS ship_payment_term_id    -- 支払条件
            -----------------------------------------------------------------------------------------------------------
                      FROM   apps.hz_cust_accounts          ship_hzca_4              --出荷先顧客マスタ　※入金先・請求先含む
                            ,apps.hz_cust_acct_sites_all    bill_hasa_4              --請求先顧客所在地
                            ,apps.hz_cust_site_uses_all     bill_hsua_4              --請求先顧客使用目的
                            ,apps.hz_cust_site_uses_all     ship_hsua_4              --出荷先顧客使用目的
                            ,apps.xxcmm_cust_accounts       bill_hzad_4              --請求先顧客追加情報
                            ,apps.hz_party_sites            bill_hzps_4              --請求先パーティサイト
                            ,apps.hz_locations              bill_hzlo_4              --請求先顧客事業所
                            ,apps.hz_customer_profiles      bill_hzcp_4              --請求先顧客プロファイル
                      WHERE  ship_hzca_4.customer_class_code = '10'             --請求先顧客.顧客区分 = '10'(顧客)
                      AND    bill_hasa_4.org_id = in_org_id                     --請求先顧客所在地.組織ID = ログインユーザの組織ID
                      AND    bill_hsua_4.org_id = in_org_id                     --請求先顧客使用目的.組織ID = ログインユーザの組織ID
                      AND    ship_hsua_4.org_id = in_org_id                     --出荷先顧客使用目的.組織ID = ログインユーザの組織ID
                      AND    NOT EXISTS (
                                 SELECT ROWNUM
                                 FROM   apps.hz_cust_acct_relate_all ex_hcar_4                            --顧客関連マスタ
                                 WHERE
                                       (ex_hcar_4.cust_account_id = ship_hzca_4.cust_account_id           --顧客関連マスタ(請求関連).顧客ID = 出荷先顧客マスタ.顧客ID
                                 OR     ex_hcar_4.related_cust_account_id = ship_hzca_4.cust_account_id)  --顧客関連マスタ(請求関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
                                 AND    ex_hcar_4.status = 'A'                                            --顧客関連マスタ(請求関連).ステータス = ‘A’
                                 AND    ex_hcar_4.org_id = in_org_id                                      --請求先顧客所在地.組織ID = ログインユーザの組織ID
                                 AND    ex_hcar_4.attribute1 = '2'                                        --顧客関連マスタ(請求関連).関連区分 = ‘2’(入金)
                                      )
                      AND    ship_hzca_4.cust_account_id = bill_hzad_4.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
                      AND    ship_hzca_4.cust_account_id = bill_hasa_4.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
                      AND    bill_hasa_4.cust_acct_site_id = bill_hsua_4.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
                      AND    bill_hasa_4.cust_acct_site_id = ship_hsua_4.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
                      AND    bill_hsua_4.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
                      AND    bill_hsua_4.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
                      AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
                      AND    ship_hsua_4.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
                      AND    bill_hasa_4.party_site_id = bill_hzps_4.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID
                      AND    bill_hzps_4.location_id = bill_hzlo_4.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID
                      AND    bill_hsua_4.site_use_id = bill_hzcp_4.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
                     ) temp
          ) customer_v
          ;
    -- レコード型
    get_hz_cust_accounts_rec  get_hz_cust_accounts_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- init部
    -- ===============================
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_msg_no_parameter
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
    -- 空行出力
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => NULL
                     );
--
    --==============================================================
    -- ログインユーザの営業単位ID取得
    --==============================================================
    ln_org_id := FND_PROFILE.VALUE(cv_org_id);
--
    -- ===============================
    -- 処理部
    -- ===============================
--
    -- 項目名出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '"入金先顧客ID","入金先顧客コード","入金先顧客名称","請求先顧客ID","請求先顧客コード","請求先顧客名称","出荷先顧客ID","出荷先顧客コード","出荷先顧客名称"'
    );
    -- データ部出力(CSV)
    FOR get_hz_cust_accounts_rec IN get_hz_cust_accounts_cur(ln_org_id)
     LOOP
       --件数セット
       gn_target_cnt := gn_target_cnt + 1;
       --変更する項目及びキー情報を出力
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => '"'|| get_hz_cust_accounts_rec.cash_account_id     || '","'
                       || get_hz_cust_accounts_rec.cash_account_number || '","'
                       || get_hz_cust_accounts_rec.cash_account_name   || '","'
                       || get_hz_cust_accounts_rec.bill_account_id     || '","'
                       || get_hz_cust_accounts_rec.bill_account_number || '","'
                       || get_hz_cust_accounts_rec.bill_account_name   || '","'
                       || get_hz_cust_accounts_rec.ship_account_id     || '","'
                       || get_hz_cust_accounts_rec.ship_account_number || '","'
                       || get_hz_cust_accounts_rec.ship_account_name   || '"'
       );
    END LOOP;
--
    -- 成功件数＝対象件数
    gn_normal_cnt  := gn_target_cnt;
    -- 対象件数=0であれば警告
    IF (gn_target_cnt = 0) THEN
      gn_warn_cnt    := 1;
      ov_retcode     := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_error_cnt := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP009A13C;
/