CREATE OR REPLACE PACKAGE BODY XXCFR003A08C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A08C
 * Description     : 汎用商品（全明細）請求データ作成
 * MD.050          : MD050_CFR_003_A08_汎用商品（全明細）請求データ作成
 * MD.070          : MD050_CFR_003_A08_汎用商品（全明細）請求データ作成
 * Version         : 1.5
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init            P         初期処理
 *  get_invoice     P         請求情報取得処理
 *  put             P         ファイル出力処理
 *  end_proc        P         終了処理
 *  submain         P         汎用商品（全明細）請求データ作成処理実行部
 *  main            P         コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-12-02    1.0   SCS 寺内 真紀 初回作成
 *  2009-10-01    1.1   SCS 窪   和重 AR仕様変更IE535対応
 *  2010-01-29    1.2   SCS 安川 智博 障害「E_本稼動_01503」対応
 *  2019-07-26    1.3   SCSK 石井 裕幸 障害「E_本稼動_15472」対応
 *  2023-05-17    1.4   SCSK Y.Koh     E_本稼動_19168【AR】インボイス対応_イセトー、汎用請求書、請求金額一覧
 *  2023-12-20    1.5   SCSK Y.Ryu     E_本稼動_19496対応
 ************************************************************************/

--
--#######################  固定グローバル定数宣言部 START   #######################
--
  cv_status_normal   CONSTANT VARCHAR2(1) := '0';  -- 正常終了
  cv_status_warn     CONSTANT VARCHAR2(1) := '1';   --警告
  cv_status_error    CONSTANT VARCHAR2(1) := '2';   --エラー
  cv_msg_part        CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3) := '.';
  
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A08C';  -- パッケージ名
  
--
--##############################  固定部 END   ####################################
--
  
  --===============================================================
  -- グローバル定数
  --===============================================================
  cv_xxcfr_app_name  CONSTANT VARCHAR2(10) := 'XXCFR';  -- アドオン会計 AR のアプリケーション短縮名
  cv_xxccp_app_name  CONSTANT VARCHAR2(10) := 'XXCCP';  -- アドオン：共通・IF領域のアプリケーション短縮名
  
  -- メッセージ番号
  cv_msg_cfr_00010  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00010';
  cv_msg_cfr_00015  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00015';
  cv_msg_cfr_00016  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00016';
  cv_msg_cfr_00024  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00024';
  cv_msg_cfr_00056  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00056';
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
  cv_msg_cfr_00006  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00006';  -- 業務処理日付エラーメッセージ
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
-- 2023/05/17 Ver1.4 ADD Start
  ct_msg_cfr_00004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00004';
-- 2023/05/17 Ver1.4 ADD End
  
  cv_msg_ccp_90000  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90000';
  cv_msg_ccp_90001  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90001';
  cv_msg_ccp_90002  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90002';
  cv_msg_ccp_90004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90004';
  cv_msg_ccp_90005  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90005';
  cv_msg_ccp_90006  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90006';
  
  -- メッセージトークン
  cv_tkn_get_data   CONSTANT VARCHAR2(30) := 'DATA';                 -- 取得対象データ
  cv_tkn_count      CONSTANT VARCHAR2(30) := 'COUNT';                -- 処理件数
  cv_tkn_tab_name   CONSTANT VARCHAR2(30) := 'TABLE';                -- テーブル名
  cv_func_name      CONSTANT VARCHAR2(30) := 'FUNC_NAME';            -- 共通関数名
-- 2023/05/17 Ver1.4 ADD Start
  cv_tkn_prof       CONSTANT VARCHAR2(30) := 'PROF_NAME';            -- プロファイル
-- 2023/05/17 Ver1.4 ADD End
  
  -- プロファイルオプション
  cv_prof_name_set_of_bks_id  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
  cv_prof_name_org_id         CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'ORG_ID';
-- 2023/12/20 Ver1.5 MOD Start
---- 2023/05/17 Ver1.4 ADD Start
--  ct_invoice_t_no             CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'XXCMM1_INVOICE_T_NO';
---- 2023/05/17 Ver1.4 ADD End
  cv_hkd_start_date           CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'XXCMM1_ITOEN_HKD_START_DATE';
-- 2023/12/20 Ver1.5 MOD End
  
  -- 参照タイプ
-- Modify 2019-07-26 Ver1.3 Start ----------------------------------------------
--  cv_lookup_type_out       CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_003A06_BILL_DATA_SET';  -- 汎用請求出力用参照タイプ名
  cv_lookup_type_out       CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_003A06_BILL_DATA_SET_1';  -- 汎用請求出力用参照タイプ名1
-- Modify 2019-07-26 Ver1.3 End   ----------------------------------------------
  
  -- 請求書全社出力権限判定関数INパラーメータ値
  cv_invoice_type  CONSTANT VARCHAR2(1) := 'G';  -- 請求書タイプ(G:汎用請求書)
  
  -- 請求書全社出力権限判定関数戻り値
  cv_yes  CONSTANT VARCHAR2(1) := 'Y';  -- 全社出力権限あり
  cv_no   CONSTANT VARCHAR2(1) := 'N';  -- 全社出力権限なし
  
  -- 請求書全社出力権限設定値
  cv_enable_all   CONSTANT VARCHAR2(1) := '1';  -- 全社出力権限あり
  cv_disable_all  CONSTANT VARCHAR2(1) := '0';  -- 全社出力権限なし
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
  cv_dict_cr_relate    CONSTANT VARCHAR2(12) := 'CFR003A02006';  -- 与信関連
  cv_dict_ar           CONSTANT VARCHAR2(12) := 'CFR003A02007';  -- 売掛管理先
-- 2023/12/20 Ver1.5 ADD Start
  cv_dict_t_no         CONSTANT VARCHAR2(12) := 'CFR003A06001'; -- 登録番号
  cv_dict_issuer       CONSTANT VARCHAR2(12) := 'CFR003A06002'; -- 発行事業者(会社名)
-- 2023/12/20 Ver1.5 ADD End
  -- 顧客名称取得関数パラメータ(全角)
  cv_get_acct_name_f   CONSTANT VARCHAR2(1)  := '0';             -- 正式名称
  --
  cv_bill_to           CONSTANT VARCHAR2(10) := 'BILL_TO';       -- 顧客使用目的：請求
  cv_rlt_class_bill    CONSTANT VARCHAR2(1)  := '1';             -- 顧客関連分類：請求
  cv_rlt_stat_act      CONSTANT VARCHAR2(1)  := 'A';             -- 関連ステータス：有効
-- Add 2010/01/29 Ver1.2 Start
  cv_site_use_stat_act CONSTANT VARCHAR2(1)  := 'A';             -- 使用目的ステータス：有効
-- Add 2010/01/29 Ver1.2 End
  -- 顧客区分
  cv_cust_class_base   CONSTANT VARCHAR2(2)  := '1';      -- 拠点
  cv_cust_class_ar     CONSTANT VARCHAR2(2)  := '14';     -- 売掛管理先
  cv_cust_class_encl   CONSTANT VARCHAR2(2)  := '21';     -- 統括請求書用
  cv_cust_class_invo   CONSTANT VARCHAR2(2)  := '20';     -- 請求書用
  cv_cust_class_ship   CONSTANT VARCHAR2(2)  := '10';     -- 出荷先
  -- 請求書出力形式
  cv_inv_prt_type CONSTANT VARCHAR2(1) := '2';  -- 汎用請求書
  -- 一括請求書発行フラグ
  cv_cons_inv_flag CONSTANT VARCHAR2(1) := 'Y';  -- 有効
-- 2023/12/20 Ver1.5 ADD Start
  cv_itoen         CONSTANT VARCHAR2(3) := '001';  -- 伊藤園会社コード
-- 2023/12/20 Ver1.5 ADD End

-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
  -- 使用可能フラグ
  cv_enable_yes CONSTANT VARCHAR2(1) := 'Y';       -- 有効
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
  
  --===============================================================
  -- グローバル変数
  --===============================================================
  gn_gl_set_of_bks_id       gl_sets_of_books.set_of_books_id%TYPE;     -- プロファイル会計帳簿ID
  gn_org_id                 xxcfr_bill_customers_v.org_id%TYPE;        -- プロファイル組織ID
  gv_user_dept_code         per_all_people_f.attribute28%TYPE;         -- ログインユーザ所属部門コード
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--  gv_enable_all             VARCHAR2(1);                               -- 全社参照権限
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
  gn_rec_count              PLS_INTEGER := 0;                          -- 請求書情報取得件数
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
  gd_process_date           DATE;                                      -- 業務日付
  gv_party_ref_type         VARCHAR2(50);                              -- パーティ関連タイプ(与信関連)
  gv_party_rev_code         VARCHAR2(50);                              -- パーティ関連(売掛管理先)
  gt_bill_location_name     xxcfr_invoice_headers.bill_location_name%TYPE;
                                                                       -- 請求拠点名
  gt_agent_tel_num          xxcfr_invoice_headers.agent_tel_num%TYPE;  -- 担当電話番号
  -- 税込請求金額算出用
  gn_amount_inc_tax         NUMBER := 0;                               -- 税込請求金額 
  gn_tax_sum                NUMBER := 0;                               -- うち消費税金額
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
-- 2023/05/17 Ver1.4 ADD Start
  gv_invoice_t_no           VARCHAR2(14);                              -- インボイス適格請求書発行事業者登録番号
-- 2023/05/17 Ver1.4 ADD End
-- 2023/12/20 Ver1.5 ADD Start
  gv_hkd_start_date         VARCHAR2(10);                              -- 伊藤園北海道適用開始日付
  gv_drafting_company       VARCHAR2(3);                               -- 請求データ作成会社コード
  gv_invoice_issuer         VARCHAR2(100);                             -- 発行事業者(会社名)
  gv_t_no                   VARCHAR2(50);                              -- エラー文言：登録番号
  gv_issuer                 VARCHAR2(50);                              -- エラー文言：発行事業者(会社名)
-- 2023/12/20 Ver1.5 ADD End
  
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
  --===============================================================
  -- グローバルカーソル
  --===============================================================
  -- 出荷先顧客情報取得カーソル
  CURSOR get_ship_cust_cur(id_target_date       DATE
                          ,iv_cust_code_receipt VARCHAR2
                          ,iv_cust_code_payment VARCHAR2
                          ,iv_cust_code_bill    VARCHAR2
                          ,iv_cust_code_ship    VARCHAR2)
  IS
    SELECT xca_ar.torihikisaki_code                         vender_code               -- 取引先コード
          ,hca_cr.account_number                            credit_cust_code          -- 与信先顧客コード
          ,xxcfr_common_pkg.get_cust_account_name(
             hca_cr.account_number,
             cv_get_acct_name_f)                            credit_cust_name          -- 与信先顧客名
          ,hca_ar.account_number                            receipt_cust_code         -- 売掛管理先顧客コード
          ,xxcfr_common_pkg.get_cust_account_name(
             hca_ar.account_number,
             cv_get_acct_name_f)                            receipt_cust_name         -- 売掛管理先顧客名
          ,hca_encl.account_number                          payment_cust_code         -- 統括請求書用顧客コード
          ,xxcfr_common_pkg.get_cust_account_name(
             hca_encl.account_number,
             cv_get_acct_name_f)                            payment_cust_name         -- 統括請求書用顧客名
          ,hca_invo.account_number                          bill_cust_code            -- 請求書用顧客コード
          ,xxcfr_common_pkg.get_cust_account_name(
             hca_invo.account_number,
             cv_get_acct_name_f)                            bill_cust_name            -- 請求書用顧客名
          ,hca_ship.account_number                          ship_cust_code            -- 出荷先顧客コード
          ,xca_ship.store_code                              ship_shop_code            -- 出荷先顧客店NO
          ,(SELECT hcsu_ar.attribute5    
            FROM   hz_cust_site_uses   hcsu_ar
            WHERE  hcsu_ar.site_use_code       = cv_bill_to
-- Add 2010/01/29 Ver1.2 Start
            AND    hcsu_ar.status              = cv_site_use_stat_act
-- Add 2010/01/29 Ver1.2 End
            AND    hcas_ship.cust_acct_site_id = hcsu_ar.cust_acct_site_id
           )                                                credit_receiv_code2       -- 売掛コード２（事業所）
          ,(SELECT hcsu_ar.attribute6
            FROM   hz_cust_site_uses   hcsu_ar
            WHERE  hcsu_ar.site_use_code       = cv_bill_to
-- Add 2010/01/29 Ver1.2 Start
            AND    hcsu_ar.status              = cv_site_use_stat_act
-- Add 2010/01/29 Ver1.2 End
            AND    hcas_ship.cust_acct_site_id = hcsu_ar.cust_acct_site_id
           )                                                credit_receiv_code3       -- 売掛コード３（その他）
    FROM   hz_cust_accounts      hca_ship  -- 顧客マスタ(出荷先)
          ,hz_cust_acct_sites    hcas_ship -- 顧客所在地(出荷先)
          ,hz_cust_site_uses     hcsu_ship -- 顧客使用目的(出荷先)
          ,hz_cust_acct_relate   hcar      -- 顧客関連
          ,hz_cust_accounts      hca_ar    -- 顧客マスタ(売掛管理先)
          ,hz_cust_acct_sites    hcas_ar   -- 顧客所在地(売掛管理先)
          ,hz_cust_site_uses     hcsu_ar   -- 顧客使用目的(売掛管理先)
          ,hz_customer_profiles  hcp_ar    -- 顧客プロファイル(売掛管理先)
          ,xxcmm_cust_accounts   xca_ship  -- 顧客追加情報(出荷先)
          ,xxcmm_cust_accounts   xca_ar    -- 顧客追加情報(売掛管理先)
          ,hz_cust_accounts      hca_invo  -- 顧客マスタ(請求書用)
          ,xxcmm_cust_accounts   xca_invo  -- 顧客追加情報(請求書用)
          ,hz_cust_accounts      hca_encl  -- 顧客マスタ(統括請求書用)
          ,xxcmm_cust_accounts   xca_encl  -- 顧客追加情報(統括請求書用)
          ,hz_relationships      hzrl      -- パーティ関連
          ,hz_cust_accounts      hca_cr    -- 与信先顧客マスタ
    WHERE  hca_ship.cust_account_id        = hcas_ship.cust_account_id
    AND    hca_ship.customer_class_code    = cv_cust_class_ship
    AND    hcas_ship.cust_acct_site_id     = hcsu_ship.cust_acct_site_id
    AND    hca_ship.cust_account_id        = hcar.related_cust_account_id
    AND    hcar.status                     = cv_rlt_stat_act
    AND    hcar.attribute1                 = cv_rlt_class_bill
    AND    hcar.cust_account_id            = hca_ar.cust_account_id
    AND    hca_ar.customer_class_code      = cv_cust_class_ar
    AND    hca_ar.cust_account_id          = hcas_ar.cust_account_id
    AND    hcas_ar.cust_acct_site_id       = hcsu_ar.cust_acct_site_id
    AND    hcsu_ar.site_use_code           = cv_bill_to
-- Add 2010/01/29 Ver1.2 Start
    AND    hcsu_ar.status                  = cv_site_use_stat_act
-- Add 2010/01/29 Ver1.2 End
    AND    hcsu_ar.attribute7              = cv_inv_prt_type
    AND    hcsu_ship.bill_to_site_use_id   = hcsu_ar.site_use_id
-- Add 2010/01/29 Ver1.2 Start
    AND    hcsu_ship.status                = cv_site_use_stat_act
-- Add 2010/01/29 Ver1.2 End
    AND    hca_ar.cust_account_id          = hcp_ar.cust_account_id
    AND    hcsu_ar.site_use_id             = hcp_ar.site_use_id
    AND    hcp_ar.cons_inv_flag            = cv_cons_inv_flag
    AND    hca_ar.cust_account_id          = xca_ar.customer_id(+)
    AND    hca_ship.cust_account_id        = xca_ship.customer_id(+)
    AND    xca_ship.invoice_code           = hca_invo.account_number(+)
    AND    hca_invo.customer_class_code(+) = cv_cust_class_invo
    AND    hca_invo.cust_account_id        = xca_invo.customer_id(+)
    AND    xca_invo.enclose_invoice_code   = hca_encl.account_number(+)
    AND    hca_encl.customer_class_code(+) = cv_cust_class_encl
    AND    hca_encl.cust_account_id        = xca_encl.customer_id(+)
    AND    hca_ar.party_id                 = hzrl.object_id(+)
    AND    hzrl.status(+)                  = cv_rlt_stat_act
    AND    hzrl.relationship_type(+)       = gv_party_ref_type
    AND    hzrl.relationship_code(+)       = gv_party_rev_code
    AND    id_target_date         BETWEEN TRUNC(NVL(hzrl.start_date(+), id_target_date))
                                       AND TRUNC(NVL(hzrl.end_date(+), id_target_date))
    AND    hzrl.subject_id               = hca_cr.party_id(+)
    AND    (hca_ar.account_number        = iv_cust_code_receipt
       OR   hca_encl.account_number      = iv_cust_code_payment
       OR   hca_invo.account_number      = iv_cust_code_bill
       OR   hca_ship.account_number      = iv_cust_code_ship)
    UNION ALL
    -- 単独店
    SELECT NULL                                             vender_code               -- 取引先コード
          ,NULL                                             credit_cust_code          -- 与信先顧客コード
          ,NULL                                             credit_cust_name          -- 与信先顧客名
          ,NULL                                             receipt_cust_code         -- 売掛管理先顧客コード
          ,NULL                                             receipt_cust_name         -- 売掛管理先顧客名
          ,hca_encl.account_number                          payment_cust_code         -- 統括請求書用顧客コード
          ,xxcfr_common_pkg.get_cust_account_name(
             hca_encl.account_number,
             cv_get_acct_name_f)                            payment_cust_name         -- 統括請求書用顧客名
          ,hca_invo.account_number                          bill_cust_code            -- 請求書用顧客コード
          ,xxcfr_common_pkg.get_cust_account_name(
             hca_invo.account_number,
             cv_get_acct_name_f)                            bill_cust_name            -- 請求書用顧客名
          ,hca_ship.account_number                          ship_cust_code            -- 出荷先顧客コード
          ,xca_ship.store_code                              ship_shop_code            -- 出荷先顧客店NO
          ,hcsu_ar.attribute5                               credit_receiv_code2       -- 売掛コード２（事業所）
          ,hcsu_ar.attribute6                               credit_receiv_code3       -- 売掛コード３（その他）
    FROM   hz_cust_accounts      hca_ship  -- 顧客マスタ(出荷先)
          ,hz_cust_acct_sites    hcas_ship -- 顧客所在地(出荷先)
          ,hz_cust_site_uses     hcsu_ship -- 顧客使用目的(出荷先)
          ,hz_cust_site_uses     hcsu_ar   -- 顧客使用目的(請求先)
          ,hz_customer_profiles  hcp_ship  -- 顧客プロファイル(出荷先)
          ,xxcmm_cust_accounts   xca_ship  -- 顧客追加情報(出荷先)
          ,hz_cust_accounts      hca_invo  -- 顧客マスタ(請求書用)
          ,xxcmm_cust_accounts   xca_invo  -- 顧客追加情報(請求書用)
          ,hz_cust_accounts      hca_encl  -- 顧客マスタ(統括請求書用)
          ,xxcmm_cust_accounts   xca_encl  -- 顧客追加情報(統括請求書用)
    WHERE  hca_ship.cust_account_id        = hcas_ship.cust_account_id
    AND    hca_ship.customer_class_code    = cv_cust_class_ship
    AND    hcas_ship.cust_acct_site_id     = hcsu_ship.cust_acct_site_id
    AND    hcas_ship.cust_acct_site_id     = hcsu_ar.cust_acct_site_id
    AND    hcsu_ar.attribute7              = cv_inv_prt_type
    AND    hcsu_ar.site_use_code           = cv_bill_to
-- Add 2010/01/29 Ver1.2 Start
    AND    hcsu_ar.status                  = cv_site_use_stat_act
-- Add 2010/01/29 Ver1.2 End
    AND    hcsu_ship.bill_to_site_use_id   = hcsu_ar.site_use_id
-- Add 2010/01/29 Ver1.2 Start
    AND    hcsu_ship.status                = cv_site_use_stat_act
-- Add 2010/01/29 Ver1.2 End
    AND    hca_ship.cust_account_id        = hcp_ship.cust_account_id
    AND    hcsu_ar.site_use_id             = hcp_ship.site_use_id
    AND    hcp_ship.cons_inv_flag          = cv_cons_inv_flag
    AND    hca_ship.cust_account_id        = xca_ship.customer_id(+)
    AND    xca_ship.invoice_code           = hca_invo.account_number(+)
    AND    hca_invo.customer_class_code(+) = cv_cust_class_invo
    AND    hca_invo.cust_account_id        = xca_invo.customer_id(+)
    AND    xca_invo.enclose_invoice_code   = hca_encl.account_number(+)
    AND    hca_encl.customer_class_code(+) = cv_cust_class_encl
    AND    hca_encl.cust_account_id        = xca_encl.customer_id(+)
    AND    (hca_encl.account_number        = iv_cust_code_payment
       OR   hca_invo.account_number        = iv_cust_code_bill
       OR   hca_ship.account_number        = iv_cust_code_ship);
--
  --===============================================================
  -- グローバルタイプ
  --===============================================================
  TYPE get_ship_cust_ttype IS TABLE OF get_ship_cust_cur%ROWTYPE INDEX BY PLS_INTEGER;    -- 出荷先顧客情報
  --
  g_ship_cust_tab          get_ship_cust_ttype;                                           -- 出荷先顧客情報
--
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
  --===============================================================
  -- グローバル例外
  --===============================================================
  global_process_expt       EXCEPTION; -- 関数例外
  global_api_expt           EXCEPTION; -- 共通関数例外
  global_api_others_expt    EXCEPTION; -- 共通関数OTHERS例外
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);  -- 共通関数例外(ORA-20000)とglobal_api_others_exptをマッピング
  
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date   IN  VARCHAR2,    -- 締日
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--    iv_ar_code1      IN  VARCHAR2,    -- 売掛コード１(請求書)
    iv_cust_code     IN  VARCHAR2,    -- 顧客コード
    iv_cust_class    IN  VARCHAR2,    -- 顧客区分
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_log             CONSTANT VARCHAR2(10)  := 'LOG';          -- パラメータ出力関数 ログ出力時のiv_which値
    cv_output          CONSTANT VARCHAR2(10)  := 'OUTPUT';       -- パラメータ出力関数 レポート出力時のiv_which値
    cv_person_dff_name CONSTANT VARCHAR2(10)  := 'PER_PEOPLE';   -- 従業員マスタDFF名
    cv_peson_dff_att28 CONSTANT VARCHAR2(11)  := 'ATTRIBUTE28';  -- 従業員マスタDFF28(所属部署)カラム名
    
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    lv_token_value fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE; --所属部門取得エラー時のメッセージトークン値
    
    -- ===============================
    -- ローカル例外
    -- ===============================
    get_user_dept_expt EXCEPTION;  -- ユーザ所属部門取得例外
    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    
    -- コンカレントパラメータログ出力
    xxcfr_common_pkg.put_log_param(iv_which => cv_log,
                                   iv_conc_param1 => iv_target_date,
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--                                   iv_conc_param2 => iv_ar_code1,
                                   iv_conc_param2 => iv_cust_code,
                                   iv_conc_param3 => iv_cust_class,
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
                                   ov_errbuf => lv_errbuf,
                                   ov_retcode => lv_retcode,
                                   ov_errmsg => lv_errmsg
                                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    
    -- プロファイル会計帳簿取得
    gn_gl_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_name_set_of_bks_id));
    
    -- プロファイル営業単位取得
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_name_org_id));
-- 2023/12/20 Ver1.5 MOD Start
---- 2023/05/17 Ver1.4 ADD Start
--    -- プロファイル:インボイス適格請求書発行事業者登録番号
--    gv_invoice_t_no := FND_PROFILE.VALUE(ct_invoice_t_no);
--    --
--    -- 取得できない場合はエラー
--    IF (gv_invoice_t_no IS NULL) THEN
--      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfr_app_name -- 'XXCFR'
--                                                    ,ct_msg_cfr_00004  -- プロファイル取得エラー
--                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
--                                                    ,xxcfr_common_pkg.get_user_profile_name(ct_invoice_t_no))
--                                                       -- 適格請求書発行事業者登録番号
--                                                   ,1
--                                                   ,5000);
--      RAISE global_api_expt;
--    END IF;
---- 2023/05/17 Ver1.4 ADD End
    -- プロファイル:XXCMM:伊藤園北海道適用開始日付
    gv_hkd_start_date := FND_PROFILE.VALUE(cv_hkd_start_date);
    IF (gv_hkd_start_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfr_app_name -- 'XXCFR'
                                                    ,ct_msg_cfr_00004  -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_hkd_start_date))
                                                       -- XXCMM:伊藤園北海道適用開始日付
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
-- 2023/12/20 Ver1.5 MOD End
    
    -- 所属部門コード取得
    gv_user_dept_code := xxcfr_common_pkg.get_user_dept(in_user_id => FND_GLOBAL.USER_ID,
                                                        id_get_date => SYSDATE
                                                       );
    IF (gv_user_dept_code IS NULL) THEN
      RAISE get_user_dept_expt;
    END IF;
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
    -- 業務処理日付取得処理
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date());
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_xxcfr_app_name
                                                   ,iv_name         => cv_msg_cfr_00006)
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
    -- 所属部門名取得
    gt_bill_location_name := xxcfr_common_pkg.get_cust_account_name(
                               gv_user_dept_code,
                               cv_get_acct_name_f);
    -- 拠点電話番号取得
    BEGIN
      SELECT base_hzlo.address_lines_phonetic  base_tel_num    --電話番号
      INTO   gt_agent_tel_num
      FROM   hz_cust_accounts                  base_hzca,      --顧客マスタ(請求拠点)
             hz_cust_acct_sites                base_hasa,      --顧客所在地ビュー(請求拠点)
             hz_locations                      base_hzlo,      --顧客事業所(請求拠点)
             hz_party_sites                    base_hzps       --パーティサイト(請求拠点)
      WHERE  base_hzca.account_number      = gv_user_dept_code
      AND    base_hzca.cust_account_id     = base_hasa.cust_account_id
      AND    base_hasa.party_site_id       = base_hzps.party_site_id
      AND    base_hzps.location_id         = base_hzlo.location_id
      AND    base_hzca.customer_class_code = cv_cust_class_base
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_agent_tel_num := NULL;
    END;
    --与信関連条件取得処理
    -- パーティ関連タイプ(与信関連)取得
    gv_party_ref_type := xxcfr_common_pkg.lookup_dictionary(
                           iv_loopup_type_prefix => cv_xxcfr_app_name
                          ,iv_keyword            => cv_dict_cr_relate);
    -- パーティ関連(売掛管理先)取得
    gv_party_rev_code := xxcfr_common_pkg.lookup_dictionary(
                           iv_loopup_type_prefix => cv_xxcfr_app_name
                          ,iv_keyword            => cv_dict_ar);
--
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
-- 2023/12/20 Ver1.5 ADD Start
    -- 請求データ作成会社コード取得
    IF (TO_DATE(gv_hkd_start_date, 'YYYYMMDD') <= xxcfr_common_pkg.get_date_param_trans(iv_target_date)) THEN
      BEGIN
        SELECT xxcfr_common_pkg.get_company_code(
                 iv_dept_code       => xca.bill_base_code
                ,in_set_of_books_id => gn_gl_set_of_bks_id
                ,id_base_date       => xxcfr_common_pkg.get_date_param_trans(iv_target_date))
               AS drafting_company
        INTO   gv_drafting_company
        FROM   xxcmm_cust_accounts xca       --顧客追加情報
        WHERE  xca.customer_code = iv_cust_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gv_drafting_company := cv_itoen;
      END;
    ELSE
      gv_drafting_company := cv_itoen;
    END IF;
    --
    -- 適格請求書発行事業者報取得
    xxcfr_common_pkg.get_invoice_issuer_info(
      iv_company_code => gv_drafting_company  -- (IN)請求データ作成会社コード
     ,ov_regnum       => gv_invoice_t_no      -- (OUT)登録番号
     ,ov_issuer       => gv_invoice_issuer    -- (OUT)発行事業者(会社名)
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- 登録番号のチェック
    IF (gv_invoice_t_no IS NULL) THEN
      -- エラーメッセージ出力用文言(登録番号)取得
      gv_t_no := xxcfr_common_pkg.lookup_dictionary(
                           iv_loopup_type_prefix => cv_xxcfr_app_name
                          ,iv_keyword            => cv_dict_t_no);
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00015,
                                            iv_token_name1 => cv_tkn_get_data,
                                            iv_token_value1 => gv_t_no);
      RAISE global_api_expt;
    END IF;
    --
    -- 発行事業者(会社名)のチェック
    IF (gv_invoice_issuer IS NULL) THEN
      -- エラーメッセージ出力用文言(発行事業者(会社名))取得
      gv_issuer := xxcfr_common_pkg.lookup_dictionary(
                           iv_loopup_type_prefix => cv_xxcfr_app_name
                          ,iv_keyword            => cv_dict_issuer);
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00015,
                                            iv_token_name1 => cv_tkn_get_data,
                                            iv_token_value1 => gv_issuer);
      RAISE global_api_expt;
    END IF;
-- 2023/12/20 Ver1.5 ADD End
    
  EXCEPTION
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 所属部門が取得できない場合 ***
    WHEN get_user_dept_expt THEN
      BEGIN
        SELECT ffcu.end_user_column_name end_user_column_name --ユーザセグメント名
        INTO lv_token_value
        FROM fnd_descr_flex_col_usage_vl ffcu                 --DFFセグメント使用方法ビュー
        WHERE ffcu.descriptive_flexfield_name = cv_person_dff_name
          AND ffcu.application_column_name = cv_peson_dff_att28;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00015,
                                            iv_token_name1 => cv_tkn_get_data,
                                            iv_token_value1 => lv_token_value);
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END init;
  
  /**********************************************************************************
   * Procedure Name   : get_invoice
   * Description      : 請求情報取得処理
   ***********************************************************************************/
  PROCEDURE get_invoice(
    iv_target_date   IN  DATE,        -- 締日
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--    iv_ar_code1      IN  VARCHAR2,    -- 売掛コード１(請求書)
    iv_cust_code     IN  VARCHAR2,    -- 顧客コード
    iv_cust_class    IN  VARCHAR2,    -- 顧客区分
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_invoice';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    --===============================================================
    -- ローカル定数
    --===============================================================
    -- VD顧客区分値
    cv_is_vd     CONSTANT VARCHAR2(1) := '1';  -- VD顧客
    cv_is_not_vd CONSTANT VARCHAR2(1) := '0';  -- VD顧客以外
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
    -- 参照タイプ
    cv_lookup_type  CONSTANT VARCHAR2(30) := 'XXCFR1_TAX_CATEGORY';  -- 税分類
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--    -- 請求書出力形式
--    cv_inv_prt_type CONSTANT VARCHAR2(1) := '2';  -- 汎用請求書
--    
--    -- 一括請求書発行フラグ
--    cv_cons_inv_flag CONSTANT VARCHAR2(1) := 'Y';  -- 有効
--    
--    -- ソートキー項目NULL時の値
--    cv_sort_null_value CONSTANT VARCHAR2(1) := '0';
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
    
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    
    --===============================================================
    -- ローカル変数
    --===============================================================
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
    --
    --カーソルパラメータ変数
    lt_cust_code_receipt hz_cust_accounts.account_number%TYPE := NULL;  -- 顧客コード（売掛管理先）
    lt_cust_code_payment hz_cust_accounts.account_number%TYPE := NULL;  -- 顧客コード（統括請求用）
    lt_cust_code_bill    hz_cust_accounts.account_number%TYPE := NULL;  -- 顧客コード（請求書用）
    lt_cust_code_ship    hz_cust_accounts.account_number%TYPE := NULL;  -- 顧客コード（出荷先）
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--
    -- パラメータ：顧客区分が売掛管理先の場合
    IF(iv_cust_class = cv_cust_class_ar)THEN
      --
      lt_cust_code_receipt := iv_cust_code;
      --
    -- パラメータ：顧客区分が統括請求書用の場合
    ELSIF(iv_cust_class = cv_cust_class_encl)THEN
      --
      lt_cust_code_payment := iv_cust_code;
      --
    -- パラメータ：顧客区分が請求書用の場合
    ELSIF(iv_cust_class = cv_cust_class_invo)THEN
      --
      lt_cust_code_bill    := iv_cust_code;
      --
    -- パラメータ：顧客区分が出荷先の場合
    ELSIF(iv_cust_class = cv_cust_class_ship)THEN
      --
      lt_cust_code_ship    := iv_cust_code;
    END IF;
--
    OPEN get_ship_cust_cur(iv_target_date
                          ,lt_cust_code_receipt
                          ,lt_cust_code_payment
                          ,lt_cust_code_bill
                          ,lt_cust_code_ship);
    --
    -- コレクション変数に代入
    FETCH get_ship_cust_cur BULK COLLECT INTO g_ship_cust_tab;
    --
    CLOSE get_ship_cust_cur;
    --
    <<ship_cust_loop>>
    FOR i IN 1..g_ship_cust_tab.COUNT LOOP
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
    -- CSV出力ワークテーブルへ挿入
    INSERT INTO xxcfr_csv_outs_temp(
      request_id,                                       -- 要求ID
      seq,                                              -- 出力順
      col1,                                             -- 取引先名
      col2,                                             -- 作成日
      col3,                                             -- 対象年月
      col4,                                             -- 対象期間(自)
      col5,                                             -- 対象期間(至)
      col6,                                             -- 取引先コード
      col7,                                             -- 請求担当拠点コード
      col8,                                             -- 請求担当拠点名
      col9,                                             -- 請求担当拠点電話番号
      col10,                                            -- 与信先顧客コード
      col11,                                            -- 与信先顧客名
      col12,                                            -- 入金先顧客コード
      col13,                                            -- 入金先顧客名
      col14,                                            -- 親請求先顧客コード
      col15,                                            -- 親請求先顧客名
      col16,                                            -- 請求先顧客コード
      col17,                                            -- 請求先顧客名
      col18,                                            -- 売掛コード２（事業所）
      col19,                                            -- 売掛コード２（事業所）名称
      col20,                                            -- 売掛コード３（その他）
      col21,                                            -- 売掛コード３（その他）名称
      col22,                                            -- 拠点コード
      col23,                                            -- 拠点名
      col24,                                            -- 顧客コード
      col25,                                            -- 顧客名
      col26,                                            -- 請求先顧客店NO
      col27,                                            -- 請求先顧客店名
      col28,                                            -- 納品先顧客店NO
      col29,                                            -- 納品先顧客店名
      col30,                                            -- 自動販売機番号
      col31,                                            -- 納品日
      col32,                                            -- 伝票NO
      col33,                                            -- オーダーNO
      col34,                                            -- コラム
      col35,                                            -- 商品コード
      col36,                                            -- JANコード
      col37,                                            -- 商品名
      col38,                                            -- 容器
      col39,                                            -- 数量
      col40,                                            -- 卸単価
      col41,                                            -- 売価
      col42,                                            -- 金額
      col43,                                            -- 金額（黒）
      col44,                                            -- 金額（赤）
      col45,                                            -- 金額（計）
      col46,                                            -- 税込請求金額
      col47,                                            -- うち消費税金額
      col48,                                            -- BM1単価
      col49,                                            -- BM1率
      col50,                                            -- BM1金額
      col51,                                            -- BM2単価
      col52,                                            -- BM2率
      col53,                                            -- BM2金額
      col54,                                            -- BM3単価
      col55,                                            -- BM3率
      col56,                                            -- BM3金額
      col57,                                            -- VD請求額
      col58,                                            -- 電気代
      col59,                                            -- 伝票区分
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--      col60)                                            -- 分類区分
--    (SELECT conc_request_id,
      col60                                             -- 分類区分
     ,col101                                            -- 伝票明細NO
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
     ,col61                                             -- 摘要
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
     )
    (SELECT (conc_request_id * -1),
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
            ROWNUM,
            itoen_name,
            inv_creation_date,
            object_month,
            object_date_from,
            object_date_to,
            vender_code,
            bill_location_code,
            bill_location_name,
            agent_tel_num,
            credit_cust_code,
            credit_cust_name,
            receipt_cust_code,
            receipt_cust_name,
            payment_cust_code,
            payment_cust_name,
            bill_cust_code,
            bill_cust_name,
            credit_receiv_code2,
            credit_receiv_name2,
            credit_receiv_code3,
            credit_receiv_name3,
            sold_location_code,
            sold_location_name,
            ship_cust_code,
            ship_cust_name,
            bill_shop_code,
            bill_shop_name,
            ship_shop_code,
            ship_shop_name,
            vd_num,
            delivery_date,
            slip_num,
            order_num,
            column_num,
            item_code,
            jan_code,
            item_name,
            vessel,
            quantity,
            unit_price,
            ship_amount,
            sold_amount,
            sold_amount_plus,
            sold_amount_minus,
            sold_amount_total,
            inv_amount_includ_tax,
            tax_amount_sum,
            bm_unit_price1,
            bm_rate1,
            bm_price1,
            bm_unit_price2,
            bm_rate2,
            bm_price2,
            bm_unit_price3,
            bm_rate3,
            bm_price3,
            vd_amount_claimed,
            electric_charges,
            slip_type,
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--            classify_type
            classify_type
           ,note_line_id
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
           ,description
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
     FROM (SELECT FND_GLOBAL.CONC_REQUEST_ID                       conc_request_id,          -- 要求ID
                  ''                                               sort_num,                 -- 出力順
                  xih.itoen_name                                   itoen_name,               -- 取引先名
                  TO_CHAR(xih.inv_creation_date,'YYYY/MM/DD')      inv_creation_date,        -- 作成日
                  xih.object_month                                 object_month,             -- 対象年月
                  TO_CHAR(xih.object_date_from,'YYYY/MM/DD')       object_date_from,         -- 対象期間(自)
                  TO_CHAR(xih.object_date_to,'YYYY/MM/DD')         object_date_to,           -- 対象期間(至)
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--                  xih.vender_code                                  vender_code,              -- 取引先コード
--                  xih.bill_location_code                           bill_location_code,       -- 請求担当拠点コード
--                  xih.bill_location_name                           bill_location_name,       -- 請求担当拠点名
--                  xih.agent_tel_num                                agent_tel_num,            -- 請求担当拠点電話番号
--                  xih.credit_cust_code                             credit_cust_code,         -- 与信先顧客コード
--                  xih.credit_cust_name                             credit_cust_name,         -- 与信先顧客名
--                  xih.receipt_cust_code                            receipt_cust_code,        -- 入金先顧客コード
--                  xih.receipt_cust_name                            receipt_cust_name,        -- 入金先顧客名
--                  xih.payment_cust_code                            payment_cust_code,        -- 売掛コード１（請求書）
--                  xih.payment_cust_name                            payment_cust_name,        -- 売掛コード１（請求書）名称
--                  xih.bill_cust_code                               bill_cust_code,           -- 請求先顧客コード
--                  xih.bill_cust_name                               bill_cust_name,           -- 請求先顧客名
--                  xih.credit_receiv_code2                          credit_receiv_code2,      -- 売掛コード２（事業所）
--                  xih.credit_receiv_name2                          credit_receiv_name2,      -- 売掛コード２（事業所）名称
--                  xih.credit_receiv_code3                          credit_receiv_code3,      -- 売掛コード３（その他）
--                  xih.credit_receiv_name3                          credit_receiv_name3,      -- 売掛コード３（その他）名称
--                  xil.sold_location_code                           sold_location_code,       -- 拠点コード
--                  xil.sold_location_name                           sold_location_name,       -- 拠点名
--                  xil.ship_cust_code                               ship_cust_code,           -- 顧客コード
--                  xil.ship_cust_name                               ship_cust_name,           -- 顧客名
--                  xih.bill_shop_code                               bill_shop_code,           -- 請求先顧客店NO
--                  xih.bill_shop_name                               bill_shop_name,           -- 請求先顧客店名
--                  xil.ship_shop_code                               ship_shop_code,           -- 納品先顧客店NO
--                  xil.ship_shop_name                               ship_shop_name,           -- 納品先顧客店名
--                  DECODE(xil.vd_cust_type,
--                          cv_is_vd,
--                          xil.vd_num,
--                          NULL
--                        )                                          vd_num,                   -- 自動販売機番号
--                  TO_CHAR(xil.delivery_date,'YYYY/MM/DD')          delivery_date,            -- 納品日
--                  DECODE(xil.vd_cust_type,
--                         cv_is_not_vd,
--                         xil.slip_num,
--                         NULL
--                        )                                          slip_num,                 -- 伝票NO
                  g_ship_cust_tab(i).vender_code                   vender_code,              -- 取引先コード
                  gv_user_dept_code                                bill_location_code,       -- 請求担当拠点コード
                  gt_bill_location_name                            bill_location_name,       -- 請求担当拠点名
                  gt_agent_tel_num                                 agent_tel_num,            -- 請求担当拠点電話番号
                  g_ship_cust_tab(i).credit_cust_code              credit_cust_code,         -- 与信先顧客コード
                  g_ship_cust_tab(i).credit_cust_name              credit_cust_name,         -- 与信先顧客名
                  g_ship_cust_tab(i).receipt_cust_code             receipt_cust_code,        -- 入金先顧客コード
                  g_ship_cust_tab(i).receipt_cust_name             receipt_cust_name,        -- 入金先顧客名
                  g_ship_cust_tab(i).payment_cust_code             payment_cust_code,        -- 親請求先顧客コード
                  g_ship_cust_tab(i).payment_cust_name             payment_cust_name,        -- 親請求先顧客名
                  g_ship_cust_tab(i).bill_cust_code                bill_cust_code,           -- 請求先顧客コード
                  g_ship_cust_tab(i).bill_cust_name                bill_cust_name,           -- 請求先顧客名
                  g_ship_cust_tab(i).credit_receiv_code2           credit_receiv_code2,      -- 売掛コード２（事業所）
                  NULL                                             credit_receiv_name2,      -- 売掛コード２（事業所）名称
                  g_ship_cust_tab(i).credit_receiv_code3           credit_receiv_code3,      -- 売掛コード３（その他）
                  NULL                                             credit_receiv_name3,      -- 売掛コード３（その他）名称
                  xil.sold_location_code                           sold_location_code,       -- 拠点コード
                  xil.sold_location_name                           sold_location_name,       -- 拠点名
                  xil.ship_cust_code                               ship_cust_code,           -- 顧客コード
                  xil.ship_cust_name                               ship_cust_name,           -- 顧客名
                  NULL                                             bill_shop_code,           -- 請求先顧客店NO
                  NULL                                             bill_shop_name,           -- 請求先顧客店名
                  xil.ship_shop_code                               ship_shop_code,           -- 納品先顧客店NO
                  xil.ship_shop_name                               ship_shop_name,           -- 納品先顧客店名
                  DECODE(xil.vd_cust_type,
                         cv_is_vd,
                         xil.vd_num,
                         NULL
                        )                                          vd_num,                   -- 自動販売機番号
                  TO_CHAR(xil.delivery_date,'YYYY/MM/DD')          delivery_date,            -- 納品日
                  xil.slip_num                                     slip_num,                 -- 伝票NO
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
                  DECODE(xil.vd_cust_type,
                         cv_is_not_vd,
                         xil.order_num,
                         NULL
                        )                                          order_num,                -- オーダーNO
                  NULL                                             column_num,               -- コラム
                  xil.item_code                                    item_code,                -- 商品コード
                  xil.jan_code                                     jan_code,                 -- JANコード
                  xil.item_name                                    item_name,                -- 商品名
                  DECODE(xil.vd_cust_type,
                         cv_is_vd,
                         xil.vessel_type_name,
                         NULL
                        )                                          vessel,                   -- 容器
                  xil.quantity                                     quantity,                 -- 数量
                  xil.unit_price                                   unit_price,               -- 卸単価
                  DECODE(xil.vd_cust_type,
                         cv_is_vd,
                         xil.unit_price,
                         NULL
                        )                                          ship_amount,              -- 売価
                  xil.sold_amount                                  sold_amount,              -- 金額
                  NULL                                             sold_amount_plus,         -- 金額（黒）
                  NULL                                             sold_amount_minus,        -- 金額（赤）
                  NULL                                             sold_amount_total,        -- 金額（計）
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--                  xih.inv_amount_includ_tax                        inv_amount_includ_tax,    -- 税込請求金額
--                  xih.tax_amount_sum                               tax_amount_sum,           -- うち消費税金額
                  xil.ship_amount + xil.tax_amount                 inv_amount_includ_tax,    -- 税込請求金額
                  xil.tax_amount                                   tax_amount_sum,           -- うち消費税金額
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
                  NULL                                             bm_unit_price1,           -- BM1単価
                  NULL                                             bm_rate1,                 -- BM1率
                  NULL                                             bm_price1,                -- BM1金額
                  NULL                                             bm_unit_price2,           -- BM2単価
                  NULL                                             bm_rate2,                 -- BM2率
                  NULL                                             bm_price2,                -- BM2金額
                  NULL                                             bm_unit_price3,           -- BM3単価
                  NULL                                             bm_rate3,                 -- BM3率
                  NULL                                             bm_price3,                -- BM3金額
                  NULL                                             vd_amount_claimed,        -- VD請求額
                  NULL                                             electric_charges,         -- 電気代
                  xil.slip_type                                    slip_type,                -- 伝票区分
                  xil.classify_type                                classify_type             -- 分類区分
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
                 ,xil.note_line_id                                 note_line_id              -- 伝票明細NO
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
                 ,flva.attribute1                                  description               -- 摘要
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
           FROM xxcfr_invoice_headers xih,
                xxcfr_invoice_lines   xil
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
               ,(SELECT flv.attribute1   attribute1
                       ,flv.lookup_code  lookup_code
                   FROM fnd_lookup_values     flv
                  WHERE flv.lookup_type   = cv_lookup_type
                    AND flv.language      = USERENV( 'LANG' )
                    AND flv.enabled_flag  = cv_enable_yes)  flva
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--           WHERE xih.invoice_id = xil.invoice_id
--             AND EXISTS (SELECT 'X'
--                         FROM xxcfr_bill_customers_v xbcv
--                         WHERE xih.bill_cust_code = xbcv.bill_customer_code
--                           AND ((cv_enable_all = gv_enable_all AND
--                                 xbcv.bill_base_code = xbcv.bill_base_code)
--                                OR
--                                (cv_disable_all = gv_enable_all AND
--                                 xbcv.bill_base_code = gv_user_dept_code))
--                           AND xbcv.receiv_code1 = iv_ar_code1
--                           AND xbcv.inv_prt_type = cv_inv_prt_type
--                           AND xbcv.cons_inv_flag = cv_cons_inv_flag
--                           AND xbcv.org_id = gn_org_id
--                        )
--             AND xih.cutoff_date = iv_target_date
           WHERE xil.ship_cust_code = g_ship_cust_tab(i).ship_cust_code
             AND xil.cutoff_date    = iv_target_date
             AND xil.invoice_id     = xih.invoice_id            
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
             AND xih.set_of_books_id = gn_gl_set_of_bks_id
             AND xih.org_id = gn_org_id
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--           ORDER BY NVL(xih.bill_shop_code,cv_sort_null_value),  -- 請求先顧客店NO
--                    xih.bill_cust_code,                          -- 請求先顧客コード
--                    NVL(xil.ship_shop_code,cv_sort_null_value),  -- 納品先顧客店NO
--                    xil.ship_cust_code,                          -- 納品先顧客コード
--                    TO_CHAR(xil.delivery_date,'YYYY/MM/DD'),     -- 納品日
--                    DECODE(xil.vd_cust_type,
--                           cv_is_not_vd,
--                           xil.slip_num,
--                           NULL
--                          ),                                     -- 伝票NO
--                    xil.note_line_id                             -- 伝票明細NO
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
             AND xil.tax_code       = flva.lookup_code(+)
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
          )
    );
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
    END LOOP ship_cust_loop;
    --
    -- 並び替えを行った上でCSV出力ワークテーブルへ再挿入
    INSERT INTO xxcfr_csv_outs_temp(
      request_id,
      seq,
      col1,
      col2,
      col3,
      col4,
      col5,
      col6,
      col7,
      col8,
      col9,
      col10,
      col11,
      col12,
      col13,
      col14,
      col15,
      col16,
      col17,
      col18,
      col19,
      col20,
      col21,
      col22,
      col23,
      col24,
      col25,
      col26,
      col27,
      col28,
      col29,
      col30,
      col31,
      col32,
      col33,
      col34,
      col35,
      col36,
      col37,
      col38,
      col39,
      col40,
      col41,
      col42,
      col43,
      col44,
      col45,
      col46,
      col47,
      col48,
      col49,
      col50,
      col51,
      col52,
      col53,
      col54,
      col55,
      col56,
      col57,
      col58,
      col59,
-- Modify 2019-07-26 Ver1.3 Start ----------------------------------------------
--      col60)
      col60,
-- 2023/05/17 Ver1.4 ADD Start
      col61,
      col62)        -- インボイス適格請求書発行事業者登録番号
--      col61)
-- 2023/05/17 Ver1.4 ADD End
-- Modify 2019-07-26 Ver1.3 End   ----------------------------------------------
      (SELECT FND_GLOBAL.CONC_REQUEST_ID,
          ROWNUM,
-- Ver1.5 MOD Start
--          col1,
          gv_invoice_issuer,  -- 発行事業者(会社名)
-- Ver1.5 MOD End
          col2,
          col3,
          col4,
          col5,
          col6,
          col7,
          col8,
          col9,
          col10,
          col11,
          col12,
          col13,
          col14,
          col15,
          col16,
          col17,
          col18,
          col19,
          col20,
          col21,
          col22,
          col23,
          col24,
          col25,
          col26,
          col27,
          col28,
          col29,
          col30,
          col31,
          col32,
          col33,
          col34,
          col35,
          col36,
          col37,
          col38,
          col39,
          col40,
          col41,
          col42,
          col43,
          col44,
          col45,
          col46,
          col47,
          col48,
          col49,
          col50,
          col51,
          col52,
          col53,
          col54,
          col55,
          col56,
          col57,
          col58,
          col59,
          col60
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
         ,col61
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
-- 2023/05/17 Ver1.4 ADD Start
         ,gv_invoice_t_no               -- インボイス適格請求書発行事業者登録番号
-- 2023/05/17 Ver1.4 ADD End
       FROM (SELECT col1,
               col2,
               col3,
               col4,
               col5,
               col6,
               col7,
               col8,
               col9,
               col10,
               col11,
               col12,
               col13,
               col14,
               col15,
               col16,
               col17,
               col18,
               col19,
               col20,
               col21,
               col22,
               col23,
               col24,
               col25,
               col26,
               col27,
               col28,
               col29,
               col30,
               col31,
               col32,
               col33,
               col34,
               col35,
               col36,
               col37,
               col38,
               col39,
               col40,
               col41,
               col42,
               col43,
               col44,
               col45,
               col46,
               col47,
               col48,
               col49,
               col50,
               col51,
               col52,
               col53,
               col54,
               col55,
               col56,
               col57,
               col58,
               col59,
               col60
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
              ,col61
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
             FROM xxcfr_csv_outs_temp
             WHERE request_id = FND_GLOBAL.CONC_REQUEST_ID * -1
             ORDER BY 
                 col14                -- 親請求先顧客コード
                ,col16                -- 請求先顧客コード
                ,col28 NULLS FIRST    -- 納品先顧客店NO
                ,col24                -- 納品先顧客コード
                ,col31                -- 納品日
                ,col32                -- 伝票NO
                ,col101               -- 伝票明細NO
-- Add 2019-07-26 Ver1.3 Start ----------------------------------------------
                ,col61 NULLS FIRST    -- 摘要
-- Add 2019-07-26 Ver1.3 End   ----------------------------------------------
             )
      );
    -- 税込請求金額の算出
    SELECT SUM(xcot.col46)
          ,SUM(xcot.col47)
    INTO gn_amount_inc_tax    -- 税込請求金額
        ,gn_tax_sum           -- うち消費税金額
    FROM xxcfr_csv_outs_temp xcot    
    WHERE xcot.request_id = FND_GLOBAL.CONC_REQUEST_ID;
    --
    UPDATE xxcfr_csv_outs_temp xcot
    SET xcot.col46 = gn_amount_inc_tax   -- 税込請求金額
       ,xcot.col47 = gn_tax_sum          -- うち消費税金額
    WHERE xcot.request_id = FND_GLOBAL.CONC_REQUEST_ID;
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
        -- 処理件数格納
        gn_rec_count := SQL%ROWCOUNT;
    
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00016,
                                            iv_token_name1 => cv_tkn_tab_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_table_comment('XXCFR_CSV_OUTS_TEMP')
                                           );
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
  END get_invoice;
  
  /**********************************************************************************
   * Procedure Name   : put
   * Description      : ファイル出力処理
   ***********************************************************************************/
  PROCEDURE put(
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put';  -- プログラム名
--
--##############################  固定部 END   ##################################
    --===============================================================
    -- ローカル定数
    --===============================================================
    -- 参照タイプ
    cv_lookup_type_func_name CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_ERR_MSG_TOKEN';        -- エラーメッセージ出力用参照タイプ名
    
    -- 参照コード
    cv_lookup_code_func_name CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFR000A00006';                -- エラーメッセージ出力用参照タイプコード
    
    --===============================================================
    -- ローカル変数
    --===============================================================
    lv_func_name fnd_lookup_values.description%TYPE;  -- 汎用請求出力処理共通関数名
    
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- OUTファイル出力処理実行
    xxcfr_common_pkg.csv_out(in_request_id => FND_GLOBAL.CONC_REQUEST_ID,
                             iv_lookup_type => cv_lookup_type_out,
                             in_rec_cnt => gn_rec_count,
                             ov_retcode => lv_retcode,
                             ov_errbuf => lv_errbuf,
                             ov_errmsg => lv_errmsg
                            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    
  EXCEPTION
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      BEGIN
        SELECT flvv.description description
        INTO lv_func_name
        FROM fnd_lookup_values_vl flvv
        WHERE flvv.lookup_type = cv_lookup_type_func_name
          AND flvv.lookup_code = cv_lookup_code_func_name
          AND flvv.enabled_flag = cv_yes
          AND SYSDATE BETWEEN flvv.start_date_active AND flvv.end_date_active;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00010,
                                            iv_token_name1 => cv_func_name,
                                            iv_token_value1 => lv_func_name);
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END put;
  
  /**********************************************************************************
   * Procedure Name   : end_proc
   * Description      : 終了処理プロシージャ
   ***********************************************************************************/
  PROCEDURE end_proc(
    iv_retcode          IN  VARCHAR2,  -- 処理ステータス
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS
    
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_proc';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    
    -- 対象データ0件警告メッセージ出力
    IF (iv_retcode = cv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                 iv_name => cv_msg_cfr_00024
                                                )
                       );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
    END IF;
    
    -- 件数出力
    -- 正常または警告終了の場合
    IF ((iv_retcode = cv_status_normal) OR (iv_retcode = cv_status_warn)) THEN
      -- 対象件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90000,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      
      -- 成功件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90001,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => gn_rec_count
                                                )
                       );
      
      -- エラー件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90002,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
    -- エラー終了の場合
    ELSIF (iv_retcode = cv_status_error) THEN
      -- 対象件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90000,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      
      -- 成功件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90001,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 0
                                                )
                       );
      
      -- エラー件数出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90002,
                                                 iv_token_name1 => cv_tkn_count,
                                                 iv_token_value1 => 1
                                                )
                       );
      -- エラーが存在しない場合
    END IF;
    
    -- 終了メッセージ出力
    -- エラーが存在する場合
    IF (iv_retcode = cv_status_error) THEN
      -- エラー終了メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90006
                                                )
                       );
    -- 対象データ0件の場合(警告終了)
    ELSIF (iv_retcode = cv_status_warn) THEN
      -- 警告終了メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90005
                                                )
                       );
    -- 正常終了の場合
    ELSE
      -- 正常終了メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90004
                                                )
                       );
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END end_proc;
  
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : 汎用商品（全明細）請求データ作成処理実行部
   ***********************************************************************************/
  PROCEDURE submain(
    iv_target_date   IN  VARCHAR2,    -- 締日
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--    iv_ar_code1      IN  VARCHAR2,    -- 売掛コード１(請求書)
    iv_cust_code     IN  VARCHAR2,    -- 顧客コード
    iv_cust_class    IN  VARCHAR2,    -- 顧客区分
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    
    --===============================================================
    -- A-1．初期処理
    --===============================================================
    init(iv_target_date,
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--         iv_ar_code1,
         iv_cust_code,
         iv_cust_class,
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
         lv_errbuf,
         lv_retcode,
         lv_errmsg
        );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--    --===============================================================
--    -- A-2．出力セキュリティ判定
--    --===============================================================
--    gv_enable_all := xxcfr_common_pkg.chk_invoice_all_dept(iv_user_dept_code => gv_user_dept_code,
--                                                           iv_invoice_type => cv_invoice_type
--                                                          );
--    IF (gv_enable_all = cv_yes) THEN
--      gv_enable_all := cv_enable_all;
--    ELSE
--      gv_enable_all := cv_disable_all;
--    END IF;
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
    
    --===============================================================
    -- A-3．請求情報取得処理
    --===============================================================
    get_invoice(xxcfr_common_pkg.get_date_param_trans(iv_target_date),
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--                iv_ar_code1,
                iv_cust_code,
                iv_cust_class,
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
                lv_errbuf,
                lv_retcode,
                lv_errmsg
               );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
    --===============================================================
    -- A-4．ファイル出力処理
    --===============================================================
    put(lv_errbuf,
        lv_retcode,
        lv_errmsg
       );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
    -- 処理件数0の場合警告終了
    IF (gn_rec_count = 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
    
  EXCEPTION
    -- *** サブプログラムエラー発生時 ***
    WHEN global_process_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END submain;
  
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   ***********************************************************************************/
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- 締日
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--    iv_ar_code1      IN  VARCHAR2     -- 売掛コード１(請求書)
    iv_cust_code     IN  VARCHAR2,    -- 顧客コード
    iv_cust_class    IN  VARCHAR2     -- 顧客区分
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
  ) IS
    
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_put_log_which CONSTANT VARCHAR2(10) := 'LOG';  -- ログヘッダ出力関数iv_whichパラメータ
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
    
  BEGIN
    
    xxccp_common_pkg.put_log_header(iv_which => cv_put_log_which,
                                    ov_retcode => lv_retcode,
                                    ov_errbuf => lv_errbuf,
                                    ov_errmsg => lv_errmsg
                                   );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    
    submain(iv_target_date,
-- Modify 2009-10-01 Ver1.1 Start ----------------------------------------------
--            iv_ar_code1,
            iv_cust_code,
            iv_cust_class,
-- Modify 2009-10-01 Ver1.1 End   ----------------------------------------------
            lv_errbuf,
            lv_retcode,
            lv_errmsg
           );
    
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfr_app_name
                     ,iv_name         => cv_msg_cfr_00056
                   )
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000) --エラーメッセージ
      );
    END IF;
    
    -- ステータスをセット
    retcode := lv_retcode;
    
    --===============================================================
    -- A-5．終了処理
    --===============================================================
    end_proc(retcode,
             lv_errbuf,
             lv_retcode,
             lv_errmsg
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
   -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
        ROLLBACK;
    END IF;
    
  EXCEPTION
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
    -- *** サブプログラムエラー発生時 ***
    WHEN global_process_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
  
END  XXCFR003A08C;
/
