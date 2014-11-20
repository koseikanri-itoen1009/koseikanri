CREATE OR REPLACE PACKAGE BODY XXCOK017A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK017A01C(body)
 * Description      : 「本振用FBデータ作成」にて支払対象となった
 *                     自販機販売手数料に関する仕訳を作成し、GLモジュールへ連携
 * MD.050           : GLインターフェイス（GL I/F） MD050_COK_017_A01
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  update_xbb             連携結果の更新(A-6)
 *  insert_gi              仕訳登録(A-4)(A-5)
 *  bm_loop                販売手数料情報ループ(A-2)(A-3)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/14    1.0   A.Yano           新規作成
 *  2009/03/03    1.1   A.Yano           [障害COK_071] GL記帳日の不具合対応
 *  2009/05/13    1.2   M.Hiruta         [障害T1_0867] GLへ連携するデータの顧客コードにダミーを設定しないよう変更
 *  2009/05/25    1.3   M.Hiruta         [障害T1_1166] GLへ連携するデータの顧客コードの取得処理において
 *                                                     正確な顧客コードを取得できるよう変更
 *  2009/09/09    1.4   K.Yamaguchi      [障害0001327] 仕訳有効日付に実際の支払日を設定
 *  2009/10/19    1.5   S.Moriyama       [障害E_T4_00044] 販売手数料マイナス連携対応
 *  2010/03/02    1.6   K.Yamaguchi      [E_本稼動_01596] 振込手数料は相手負担の場合のみ仕訳を作成する
 *                                                        仕訳の作成単位を仕入先単位とする
 *                                                        AFF部門は当月売上拠点とする
 *                                                        起票部門は仕入先の問合せ担当拠点とする
 *                                                        販手残高テーブルに項目「伝票番号」追加、採番された伝票番号で更新する
 *  2010/04/26    1.7   S.Arizumi        [E_本稼動_02268] 自販機販売手数料に対する課税時の勘定科目は、課税仕入5％を設定する。
 *
 *****************************************************************************************/
--
-- 2010/03/02 Ver.1.6 [E_本稼動_01596] SCS K.Yamaguchi REPAIR START
--  -- ===============================
--  -- ユーザー定義グローバル定数
--  -- ===============================
--  -- パッケージ名
--  cv_pkg_name                    CONSTANT VARCHAR2(20)  := 'XXCOK017A01C';
--  --ステータス・コード
--  cv_status_normal               CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- 正常:0
--  cv_status_warn                 CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- 警告:1
--  cv_status_error                CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- 異常:2
--  --WHOカラム
--  cn_created_by                  CONSTANT NUMBER        := fnd_global.user_id;         -- CREATED_BY
--  cn_last_updated_by             CONSTANT NUMBER        := fnd_global.user_id;         -- LAST_UPDATED_BY
--  cn_last_update_login           CONSTANT NUMBER        := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
--  cn_request_id                  CONSTANT NUMBER        := fnd_global.conc_request_id; -- REQUEST_ID
--  cn_program_application_id      CONSTANT NUMBER        := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
--  cn_program_id                  CONSTANT NUMBER        := fnd_global.conc_program_id; -- PROGRAM_ID
--  -- セパレータ
--  cv_msg_part                    CONSTANT VARCHAR2(3)   := ' : ';
--  cv_msg_cont                    CONSTANT VARCHAR2(1)   := '.';
--  -- アプリケーション短縮名
--  cv_app_name_ccp                CONSTANT VARCHAR2(5)   := 'XXCCP';
--  cv_app_name_cok                CONSTANT VARCHAR2(5)   := 'XXCOK';
--  cv_app_short_name              CONSTANT VARCHAR2(5)   := 'SQLGL';
--  -- メッセージ
--  cv_target_rec_msg              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';      -- 対象件数メッセージ
--  cv_success_rec_msg             CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';      -- 成功件数メッセージ
--  cv_error_rec_msg               CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';      -- エラー件数メッセージ
--  cv_normal_msg                  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';      -- 正常終了メッセージ
--  cv_error_msg                   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';      -- エラー終了全ロールバック
--  cv_no_parameter_msg            CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';      -- コンカレント入力パラメータなし
--  cv_process_date_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00028';      -- 業務処理日付取得エラー
--  cv_profile_err_msg             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';      -- プロファイル値取得エラー
--  cv_acctg_chk_err_msg           CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00042';      -- 会計期間チェックエラー
--  cv_gl_info_err_msg             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10265';      -- GL連携情報取得エラー
--  cv_sales_staff_code_err_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00033';      -- 営業担当員取得エラー
--  cv_acctg_calendar_err_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00011';      -- 会計カレンダ情報取得エラー
--  cv_slip_number_err_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00025';      -- 伝票番号取得エラー
--  cv_group_id_err_msg            CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00024';      -- グループID取得エラー
--  cv_gl_insert_err_msg           CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10268';      -- GL連携データ登録エラー
--  cv_bm_balance_err_msg          CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00053';      -- 販手残高テーブルロックエラー
--  cv_gl_if_update_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10270';      -- GL連携結果更新エラー
--  -- トークン
--  cv_cnt_token                   CONSTANT VARCHAR2(10)  := 'COUNT';                 -- 件数メッセージ用トークン名
--  cv_profile_token               CONSTANT VARCHAR2(10)  := 'PROFILE';               -- プロファイル名
--  cv_proc_date_token             CONSTANT VARCHAR2(10)  := 'PROC_DATE';             -- 処理日
--  cv_dept_code_token             CONSTANT VARCHAR2(10)  := 'DEPT_CODE';             -- 拠点コード
--  cv_vend_code_token             CONSTANT VARCHAR2(10)  := 'VEND_CODE';             -- 仕入先コード
--  cv_vend_site_code_token        CONSTANT VARCHAR2(20)  := 'VEND_SITE_CODE';        -- 仕入先サイトコード
--  cv_cust_code_token             CONSTANT VARCHAR2(10)  := 'CUST_CODE';             -- 顧客コード
--  cv_pay_date_token              CONSTANT VARCHAR2(10)  := 'PAY_DATE';              -- 支払日
--  -- プロファイル名
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--  -- MO: 営業単位
--  cv_org_id                      CONSTANT VARCHAR2(10)  := 'ORG_ID';
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--  -- 会計帳簿名
--  cv_set_of_bks_name             CONSTANT VARCHAR2(20)  := 'GL_SET_OF_BKS_NAME';
--  -- 会計帳簿ID
--  cv_set_of_bks_id               CONSTANT VARCHAR2(20)  := 'GL_SET_OF_BKS_ID';
--  -- COK:会社コード
--  cv_aff1_company_code           CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF1_COMPANY_CODE';
--  -- COK:部門コード_財務経理部
--  cv_aff2_dept_fin               CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF2_DEPT_FIN';
--  -- COK:顧客コード_ダミー値
--  cv_aff5_customer_dummy         CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF5_CUSTOMER_DUMMY';
--  -- COK:企業コード_ダミー値
--  cv_aff6_company_dummy          CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF6_COMPANY_DUMMY';
--  -- COK:予備コード１_ダミー値
--  cv_aff7_preliminary1_dummy     CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';
--  -- COK:予備コード２_ダミー値
--  cv_aff8_preliminary2_dummy     CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';
--  -- COK:勘定科目_自販機販売手数料
--  cv_aff3_vend_sales_commission  CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_VEND_SALES_COMMISSION';
--  -- COK:勘定科目_手数料
--  cv_aff3_fee                    CONSTANT VARCHAR2(20)  := 'XXCOK1_AFF3_FEE';
--  -- COK:勘定科目_仮払消費税等
--  cv_aff3_payment_excise_tax     CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_PAYMENT_EXCISE_TAX';
--  -- COK:勘定科目_当座預金
--  cv_aff3_current_account        CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_CURRENT_ACCOUNT';
--  -- COK:補助科目_自販機販売手数料_自販リベート
--  cv_aff4_vend_sales_rebate      CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_VEND_SALES_REBATE';
--  -- COK:補助科目_自販機販売手数料_自販電気料
--  cv_aff4_vend_sales_elec_cost   CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_VEND_SALES_ELEC_COST';
--  -- COK:補助科目_手数料_振込手数料
--  cv_aff4_transfer_fee           CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_TRANSFER_FEE';
--  -- COK:補助科目_ダミー値
--  cv_aff4_subacct_dummy          CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_SUBACCT_DUMMY';
--  -- COK:補助科目_当座預金_当社口座
--  cv_aff4_current_account_our    CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_CURRENT_ACCOUNT_OUR';
--  -- COK:銀行手数料_振込額基準
--  cv_bank_fee_trans_criterion    CONSTANT VARCHAR2(40)  := 'XXCOK1_BANK_FEE_TRANS_CRITERION';
--  -- COK:銀行手数料_基準額未満
--  cv_bank_fee_less_criterion     CONSTANT VARCHAR2(40)  := 'XXCOK1_BANK_FEE_LESS_CRITERION';
--  -- COK:銀行手数料_基準額以上
--  cv_bank_fee_more_criterion     CONSTANT VARCHAR2(40)  := 'XXCOK1_BANK_FEE_MORE_CRITERION';
--  -- COK:販売手数料_消費税率
--  cv_bm_tax                      CONSTANT VARCHAR2(20)  := 'XXCOK1_BM_TAX';
--  -- COK:FB支払条件
--  cv_fb_term_name                CONSTANT VARCHAR2(40)  := 'XXCOK1_FB_TERM_NAME';
--  -- COK:仕訳カテゴリ_販売手数料
--  cv_gl_category_bm              CONSTANT VARCHAR2(40)  := 'XXCOK1_GL_CATEGORY_BM';
--  -- COK:仕訳ソース_個別開発
--  cv_gl_source_cok               CONSTANT VARCHAR2(40)  := 'XXCOK1_GL_SOURCE_COK';
--  -- 連携ステータス（本振用FB）
--  cv_interface_status_fb         CONSTANT VARCHAR2(1)   := '1';                     -- 処理済
--  -- 連携ステータス（GL）
--  cv_if_status_gl_before         CONSTANT VARCHAR2(1)   := '0';                     -- 未処理
--  cv_if_status_gl_after          CONSTANT VARCHAR2(1)   := '1';                     -- 処理済
--  -- 全支払の保留フラグ
--  cv_hold_pay_flag_n             CONSTANT VARCHAR2(1)   := 'N';                     -- 保留なし
--  -- BM支払区分
--  cv_bm_payment_type1            CONSTANT VARCHAR2(1)   := '1';                     -- 本振（案内有）
--  cv_bm_payment_type2            CONSTANT VARCHAR2(1)   := '2';                     -- 本振（案内無）
--  -- 銀行手数料負担者
--  cv_chrg_flag_i                 CONSTANT VARCHAR2(1)   := 'I';                     -- 当方負担
--  -- 本機能のプログラムID
--  cv_program_id                  CONSTANT VARCHAR2(15)  := 'XXCOK017A01C';          -- GLインタフェース
--  -- GLインタフェーステーブル登録フラグ
--  cv_vend_sales                  CONSTANT VARCHAR2(1)   := 'V';                     -- 自販機販売手数料仕訳
--  cv_backmargin                  CONSTANT VARCHAR2(1)   := 'B';                     -- 販売手数料仕訳
--  -- GLインタフェーステーブル登録データ
--  cv_gl_if_tab_status            CONSTANT VARCHAR2(3)   := 'NEW';                   -- ステータスNEW
--  cv_balance_flag_a              CONSTANT VARCHAR2(1)   := 'A';                     -- 残高タイプ
--  -- GL付加情報フラグ（伝票単位）
--  cv_gl_add_info_y               CONSTANT VARCHAR2(1)   := 'Y';                     -- 取得する
--  cv_gl_add_info_n               CONSTANT VARCHAR2(1)   := 'N';                     -- 取得しない
--  -- 銀行手数料設定フラグ（仕入先単位）
--  cv_bank_charge_y               CONSTANT VARCHAR2(1)   := 'Y';                     -- 設定する
--  cv_bank_charge_n               CONSTANT VARCHAR2(1)   := 'N';                     -- 設定しない
--  -- ===============================
--  -- ユーザー定義グローバル変数
--  -- ===============================
--  gn_target_cnt                   NUMBER                        DEFAULT 0;     -- 対象件数
--  gn_normal_cnt                   NUMBER                        DEFAULT 0;     -- 正常件数
--  gn_error_cnt                    NUMBER                        DEFAULT 0;     -- エラー件数
--  gn_warn_cnt                     NUMBER                        DEFAULT 0;     -- スキップ件数
--  -- プロファイル値
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--  gn_org_id                       NUMBER                        DEFAULT NULL;  -- 営業単位ID
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--  gv_set_of_bks_name              VARCHAR2(20)                  DEFAULT NULL;  -- 会計帳簿名
--  gv_set_of_bks_id                VARCHAR2(20)                  DEFAULT NULL;  -- 会計帳簿ID
--  gv_aff1_company_code            VARCHAR2(20)                  DEFAULT NULL;  -- 会社コード
--  gv_aff2_dept_fin                VARCHAR2(20)                  DEFAULT NULL;  -- 部門コード_財務経理部
--  gv_aff5_customer_dummy          VARCHAR2(20)                  DEFAULT NULL;  -- 顧客コード_ダミー値
--  gv_aff6_company_dummy           VARCHAR2(20)                  DEFAULT NULL;  -- 企業コード_ダミー値
--  gv_aff7_preliminary1_dummy      VARCHAR2(20)                  DEFAULT NULL;  -- 予備コード１_ダミー値
--  gv_aff8_preliminary2_dummy      VARCHAR2(20)                  DEFAULT NULL;  -- 予備コード２_ダミー値
--  gv_aff3_vend_sales_commission   VARCHAR2(20)                  DEFAULT NULL;  -- 勘定科目_自販機販売手数料
--  gv_aff3_fee                     VARCHAR2(20)                  DEFAULT NULL;  -- 勘定科目_手数料
--  gv_aff3_payment_excise_tax      VARCHAR2(20)                  DEFAULT NULL;  -- 勘定科目_仮払消費税等
--  gv_aff3_current_account         VARCHAR2(20)                  DEFAULT NULL;  -- 勘定科目_当座預金
--  gv_aff4_vend_sales_rebate       VARCHAR2(20)                  DEFAULT NULL;  -- 補助科目_自販機販売手数料_自販リベート
--  gv_aff4_vend_sales_elec_cost    VARCHAR2(20)                  DEFAULT NULL;  -- 補助科目_自販機販売手数料_自販電気料
--  gv_aff4_transfer_fee            VARCHAR2(20)                  DEFAULT NULL;  -- 補助科目_手数料_振込手数料
--  gv_aff4_subacct_dummy           VARCHAR2(20)                  DEFAULT NULL;  -- 補助科目_ダミー値
--  gv_aff4_current_account_our     VARCHAR2(20)                  DEFAULT NULL;  -- 補助科目_当座預金_当社口座
--  gv_bank_fee_trans_criterion     VARCHAR2(20)                  DEFAULT NULL;  -- 銀行手数料_振込額基準
--  gv_bank_fee_less_criterion      VARCHAR2(20)                  DEFAULT NULL;  -- 銀行手数料_基準額未満
--  gv_bank_fee_more_criterion      VARCHAR2(20)                  DEFAULT NULL;  -- 銀行手数料_基準額以上
--  gv_bm_tax                       VARCHAR2(30)                  DEFAULT NULL;  -- 販売手数料_消費税率
--  gv_fb_term_name                 VARCHAR2(10)                  DEFAULT NULL;  -- FB支払条件
--  gv_gl_category_bm               VARCHAR2(20)                  DEFAULT NULL;  -- 仕訳カテゴリ_販売手数料
--  gv_gl_source_cok                VARCHAR2(20)                  DEFAULT NULL;  -- 仕訳ソース_個別開発
--  -- 初期処理取得データ
--  gd_process_date                 DATE                          DEFAULT NULL;  -- 業務処理日付
--  gd_close_date                   DATE                          DEFAULT NULL;  -- 締め日
--  gd_payment_date                 DATE                          DEFAULT NULL;  -- 当月の支払日
--  gv_batch_name                   VARCHAR2(50)                  DEFAULT NULL;  -- バッチ名
--  gt_group_id                     gl_je_sources.attribute1%TYPE DEFAULT NULL;  -- グループID
--  -- ===============================
--  -- ユーザー定義グローバルカーソル
--  -- ===============================
--  -- GL連携データ
--  CURSOR gl_interface_cur
--  IS
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR START
----    SELECT xbb.base_code                          AS base_code             -- 拠点コード
--    SELECT /*+
--             LEADING( xbb, pv, pvsa )
--             INDEX( xbb  XXCOK_BACKMARGIN_BALANCE_N10 )
--           */
--           xbb.base_code                          AS base_code             -- 拠点コード
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR END
--          ,xbb.supplier_code                      AS supplier_code         -- 仕入先コード
--          ,xbb.supplier_site_code                 AS supplier_site_code    -- 仕入先サイトコード
--          ,xbb.cust_code                          AS cust_code             -- 顧客コード
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR START
----          ,SUM( NVL( xbb.backmargin, 0 ) )        AS backmargin            -- 販売手数料
----          ,SUM( NVL( xbb.backmargin_tax, 0 ) )    AS backmargin_tax        -- 販売手数料消費税額
----          ,SUM( NVL( xbb.electric_amt, 0 ) )      AS electric_amt          -- 電気料
----          ,SUM( NVL( xbb.electric_amt_tax, 0 ) )  AS electric_amt_tax      -- 電気料消費税額
--          ,NVL( SUM( xbb.backmargin       ), 0 )  AS backmargin            -- 販売手数料
--          ,NVL( SUM( xbb.backmargin_tax   ), 0 )  AS backmargin_tax        -- 販売手数料消費税額
--          ,NVL( SUM( xbb.electric_amt     ), 0 )  AS electric_amt          -- 電気料
--          ,NVL( SUM( xbb.electric_amt_tax ), 0 )  AS electric_amt_tax      -- 電気料消費税額
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR END
--          ,xbb.tax_code                           AS tax_code              -- 税金コード
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR START
----          ,MAX( xbb.expect_payment_date )         AS expect_payment_date   -- 支払予定日
--          ,MAX( xbb.publication_date )            AS expect_payment_date   -- 支払日
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR END
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR START
----          ,SUM( NVL( xbb.backmargin, 0 )
----             +  NVL( xbb.backmargin_tax, 0 )
----             +  NVL( xbb.electric_amt, 0 )
----             +  NVL( xbb.electric_amt_tax, 0 ) )  AS amt_sum               -- 振込額
--          ,NVL( SUM( xbb.payment_amt_tax ), 0 )   AS amt_sum               -- 振込額
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR END
--          ,pvsa.bank_charge_bearer                AS bank_charge_bearer    -- 銀行手数料負担者
--          ,pvsa.payment_currency_code             AS payment_currency_code -- 支払通貨
--    FROM xxcok_backmargin_balance xbb    -- 販手残高テーブル
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi DELETE START
----        ,hz_cust_accounts         hca    -- 顧客マスタ
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi DELETE END
--        ,po_vendors               pv     -- 仕入先マスタ
--        ,po_vendor_sites_all      pvsa   -- 仕入先サイトマスタ
--    WHERE xbb.fb_interface_status     =  cv_interface_status_fb
--    AND   xbb.gl_interface_status     =  cv_if_status_gl_before
--    AND   xbb.supplier_code           =  pv.segment1
--    AND   xbb.supplier_site_code      =  pvsa.vendor_site_code
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi ADD START
--    AND   pv.vendor_id                =  pvsa.vendor_id
--    AND   NVL( xbb.expect_payment_amt_tax, 0 ) = 0
--    AND   xbb.publication_date        BETWEEN TRUNC( gd_process_date, 'MM' )
--                                          AND LAST_DAY( TRUNC( gd_process_date ) )
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi ADD END
--    AND   pvsa.hold_all_payments_flag =  cv_hold_pay_flag_n
--    AND   (   ( pvsa.inactive_date    IS NULL )
--            OR( pvsa.inactive_date    >= gd_payment_date ) )
--    AND   pvsa.attribute4 IN( cv_bm_payment_type1, cv_bm_payment_type2 )
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi DELETE START
----    AND   xbb.cust_code               =  hca.account_number
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi DELETE END
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--    AND   pvsa.org_id = gn_org_id
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--    GROUP BY xbb.base_code
--            ,xbb.supplier_code
--            ,xbb.supplier_site_code
--            ,xbb.cust_code
--            ,xbb.tax_code
--            ,pvsa.bank_charge_bearer
--            ,pvsa.payment_currency_code
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama ADD START
--    HAVING NVL( SUM( xbb.backmargin       ), 0 ) <> 0
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama ADD END
--    ORDER BY xbb.supplier_code
--            ,xbb.base_code
--  ;
--  -- ===============================
--  -- ユーザー定義グローバルレコード
--  -- ===============================
--  -- GL連携データ
--  g_gl_interface_rec   gl_interface_cur%ROWTYPE;
--  -- ===============================
--  -- ユーザー定義グローバル例外
--  -- ===============================
--  --*** 処理部共通例外 ***
--  global_process_expt         EXCEPTION;
--  --*** 共通関数例外 ***
--  global_api_expt             EXCEPTION;
--  --*** 共通関数OTHERS例外 ***
--  global_api_others_expt      EXCEPTION;
--  global_nodata_expt          EXCEPTION;      -- データ取得例外
--  global_lock_expt            EXCEPTION;      -- ロック処理例外
--  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--  PRAGMA EXCEPTION_INIT( global_lock_expt, -54 );
----
--  /**********************************************************************************
--   * Procedure Name   : init
--   * Description      : 初期処理(A-1)
--   ***********************************************************************************/
--  PROCEDURE init(
--     ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ
--    ,ov_retcode    OUT VARCHAR2      -- リターン・コード
--    ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name                    CONSTANT VARCHAR2(4)  := 'init';          -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
--    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
--    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--    lv_out_msg                     VARCHAR2(2000) DEFAULT NULL;              -- 出力メッセージ
--    lb_retcode                     BOOLEAN        DEFAULT TRUE;              -- メッセージ出力のリターン・コード
--    lv_nodata_profile              VARCHAR2(40)   DEFAULT NULL;              -- 未取得のプロファイル名
--    -- *** ローカル例外 ***
--    nodata_profile_expt        EXCEPTION;    -- プロファイル値取得例外
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- ====================================================
--    -- 1. メッセージ出力
--    -- ====================================================
--    lv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name_ccp
--                    ,iv_name         => cv_no_parameter_msg
--                  );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                     FND_FILE.OUTPUT
--                    ,lv_out_msg
--                    ,1
--                  );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                     FND_FILE.LOG
--                    ,lv_out_msg
--                    ,2
--                  );
----
--    -- ====================================================
--    -- 2. 業務処理日付取得
--    -- ====================================================
--    gd_process_date := xxccp_common_pkg2.get_process_date();
--    IF( gd_process_date IS NULL ) THEN
--      RAISE global_nodata_expt;
--    END IF;
----
--    -- ====================================================
--    -- 3. 会計帳簿名取得
--    -- ====================================================
--    gv_set_of_bks_name := FND_PROFILE.VALUE( cv_set_of_bks_name );
--    IF( gv_set_of_bks_name IS NULL ) THEN
--      lv_nodata_profile := cv_set_of_bks_name;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 4. 会計帳簿ID取得
--    -- ====================================================
--    gv_set_of_bks_id   := FND_PROFILE.VALUE( cv_set_of_bks_id );
--    IF( gv_set_of_bks_id IS NULL ) THEN
--      lv_nodata_profile := cv_set_of_bks_id;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 5. 会社コード取得
--    -- ====================================================
--    gv_aff1_company_code := FND_PROFILE.VALUE( cv_aff1_company_code );
--    IF( gv_aff1_company_code IS NULL ) THEN
--      lv_nodata_profile := cv_aff1_company_code;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 6. 財務経理部の部門コード取得
--    -- ====================================================
--    gv_aff2_dept_fin := FND_PROFILE.VALUE( cv_aff2_dept_fin );
--    IF( gv_aff2_dept_fin IS NULL ) THEN
--      lv_nodata_profile := cv_aff2_dept_fin;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 7. 顧客コードのダミー値取得
--    -- ====================================================
--    gv_aff5_customer_dummy := FND_PROFILE.VALUE( cv_aff5_customer_dummy );
--    IF( gv_aff5_customer_dummy IS NULL ) THEN
--      lv_nodata_profile := cv_aff5_customer_dummy;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 8. 企業コードのダミー値取得
--    -- ====================================================
--    gv_aff6_company_dummy  := FND_PROFILE.VALUE( cv_aff6_company_dummy );
--    IF( gv_aff6_company_dummy IS NULL ) THEN
--      lv_nodata_profile := cv_aff6_company_dummy;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 9. 予備コード１のダミー値取得
--    -- ====================================================
--    gv_aff7_preliminary1_dummy := FND_PROFILE.VALUE( cv_aff7_preliminary1_dummy );
--    IF( gv_aff7_preliminary1_dummy IS NULL ) THEN
--      lv_nodata_profile := cv_aff7_preliminary1_dummy;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 10. 予備コード２のダミー値取得
--    -- ====================================================
--    gv_aff8_preliminary2_dummy := FND_PROFILE.VALUE( cv_aff8_preliminary2_dummy );
--    IF( gv_aff8_preliminary2_dummy IS NULL ) THEN
--      lv_nodata_profile := cv_aff8_preliminary2_dummy;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 11. 自販機販売手数料の勘定科目コード取得
--    -- ====================================================
--    gv_aff3_vend_sales_commission := FND_PROFILE.VALUE( cv_aff3_vend_sales_commission );
--    IF( gv_aff3_vend_sales_commission IS NULL ) THEN
--      lv_nodata_profile := cv_aff3_vend_sales_commission;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 12. 手数料の勘定科目コード取得
--    -- ====================================================
--    gv_aff3_fee := FND_PROFILE.VALUE( cv_aff3_fee );
--    IF( gv_aff3_fee IS NULL ) THEN
--      lv_nodata_profile := cv_aff3_fee;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 13. 仮払消費税等の勘定科目コード取得
--    -- ====================================================
--    gv_aff3_payment_excise_tax := FND_PROFILE.VALUE( cv_aff3_payment_excise_tax );
--    IF( gv_aff3_payment_excise_tax IS NULL ) THEN
--      lv_nodata_profile := cv_aff3_payment_excise_tax;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 14. 当座預金の勘定科目コード取得
--    -- ====================================================
--    gv_aff3_current_account := FND_PROFILE.VALUE( cv_aff3_current_account );
--    IF( gv_aff3_current_account IS NULL ) THEN
--      lv_nodata_profile := cv_aff3_current_account;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 15. 自販機販売手数料_自販リベートの補助科目コード取得
--    -- ====================================================
--    gv_aff4_vend_sales_rebate := FND_PROFILE.VALUE( cv_aff4_vend_sales_rebate );
--    IF( gv_aff4_vend_sales_rebate IS NULL ) THEN
--      lv_nodata_profile := cv_aff4_vend_sales_rebate;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 16. 自販機販売手数料_自販電気料の補助科目コード取得
--    -- ====================================================
--    gv_aff4_vend_sales_elec_cost := FND_PROFILE.VALUE( cv_aff4_vend_sales_elec_cost );
--    IF( gv_aff4_vend_sales_elec_cost IS NULL ) THEN
--      lv_nodata_profile := cv_aff4_vend_sales_elec_cost;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 17. 手数料_振込手数料の補助科目コード取得
--    -- ====================================================
--    gv_aff4_transfer_fee := FND_PROFILE.VALUE( cv_aff4_transfer_fee );
--    IF( gv_aff4_transfer_fee IS NULL ) THEN
--      lv_nodata_profile := cv_aff4_transfer_fee;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 18. 補助科目コードのダミー値取得
--    -- ====================================================
--    gv_aff4_subacct_dummy := FND_PROFILE.VALUE( cv_aff4_subacct_dummy );
--    IF( gv_aff4_subacct_dummy IS NULL ) THEN
--      lv_nodata_profile := cv_aff4_subacct_dummy;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 19. 当座預金_当社口座の補助科目コード取得
--    -- ====================================================
--    gv_aff4_current_account_our :=FND_PROFILE.VALUE( cv_aff4_current_account_our );
--    IF( gv_aff4_current_account_our IS NULL ) THEN
--      lv_nodata_profile := cv_aff4_current_account_our;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 20. 振込額の基準金額取得
--    -- ====================================================
--    gv_bank_fee_trans_criterion := FND_PROFILE.VALUE( cv_bank_fee_trans_criterion );
--    IF( gv_bank_fee_trans_criterion IS NULL ) THEN
--      lv_nodata_profile := cv_bank_fee_trans_criterion;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 21. 振込額が基準額未満の銀行手数料取得
--    -- ====================================================
--    gv_bank_fee_less_criterion := FND_PROFILE.VALUE( cv_bank_fee_less_criterion );
--    IF( gv_bank_fee_less_criterion IS NULL ) THEN
--      lv_nodata_profile := cv_bank_fee_less_criterion;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 22. 振込額が基準額以上の銀行手数料取得
--    -- ====================================================
--    gv_bank_fee_more_criterion := FND_PROFILE.VALUE( cv_bank_fee_more_criterion );
--    IF( gv_bank_fee_more_criterion IS NULL ) THEN
--      lv_nodata_profile := cv_bank_fee_more_criterion;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 23. 消費税率取得
--    -- ====================================================
--    gv_bm_tax := FND_PROFILE.VALUE( cv_bm_tax );
--    IF( gv_bm_tax IS NULL ) THEN
--      lv_nodata_profile := cv_bm_tax;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 24. FB支払条件を取得
--    -- ====================================================
--    gv_fb_term_name := FND_PROFILE.VALUE( cv_fb_term_name );
--    IF( gv_fb_term_name IS NULL ) THEN
--      lv_nodata_profile := cv_fb_term_name;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 25. 販売手数料の仕訳カテゴリ取得
--    -- ====================================================
--    gv_gl_category_bm := FND_PROFILE.VALUE( cv_gl_category_bm );
--    IF( gv_gl_category_bm IS NULL ) THEN
--      lv_nodata_profile := cv_gl_category_bm;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 26. 販売手数料の仕訳ソース取得
--    -- ====================================================
--    gv_gl_source_cok := FND_PROFILE.VALUE( cv_gl_source_cok );
--    IF( gv_gl_source_cok IS NULL ) THEN
--      lv_nodata_profile := cv_gl_source_cok;
--      RAISE nodata_profile_expt;
--    END IF;
----
--    -- ====================================================
--    -- 27. 当月の支払日取得（締め日・支払日）
--    -- ====================================================
--    xxcok_common_pkg.get_close_date_p(
--       ov_errbuf     =>   lv_errbuf
--      ,ov_retcode    =>   lv_retcode
--      ,ov_errmsg     =>   lv_errmsg
--      ,id_proc_date  =>   gd_process_date
--      ,iv_pay_cond   =>   gv_fb_term_name
--      ,od_close_date =>   gd_close_date
--      ,od_pay_date   =>   gd_payment_date
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_api_expt;
--    END IF;
----
--    -- ====================================================
--    -- 28. グループID取得
--    -- ====================================================
--    BEGIN
----
--      SELECT gjs.attribute1 AS group_id     -- グループID
--      INTO gt_group_id
--      FROM gl_je_sources gjs
--      WHERE gjs.user_je_source_name = gv_gl_source_cok
--      AND   gjs.language            = USERENV( 'LANG' )
--      ;
--      IF( gt_group_id IS NULL ) THEN
--        RAISE NO_DATA_FOUND;
--      END IF;
----
--    EXCEPTION
--      -- *** グループID取得例外 ***
--      WHEN OTHERS THEN
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_app_name_cok
--                        ,iv_name         => cv_group_id_err_msg
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                         FND_FILE.OUTPUT
--                        ,lv_out_msg
--                        ,0
--                      );
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--        ov_retcode := cv_status_error;
----
--    END;
----
--    -- ====================================================
--    -- 29. バッチ名取得
--    -- ====================================================
--    gv_batch_name := xxcok_common_pkg.get_batch_name_f( gv_gl_category_bm );
----
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--    -- ====================================================
--    -- 30. 営業単位ID取得
--    -- ====================================================
--    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_org_id ) );
--    IF( gn_org_id IS NULL ) THEN
--      lv_nodata_profile := cv_org_id;
--      RAISE nodata_profile_expt;
--    END IF;
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----
--  EXCEPTION
--    --*** プロファイル値取得例外 ***
--    WHEN nodata_profile_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_name_cok
--                      ,iv_name         => cv_profile_err_msg
--                      ,iv_token_name1  => cv_profile_token
--                      ,iv_token_value1 => lv_nodata_profile
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       FND_FILE.OUTPUT
--                      ,lv_out_msg
--                      ,0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    --*** 業務処理日付取得例外 ***
--    WHEN global_nodata_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_name_cok
--                      ,iv_name         => cv_process_date_err_msg
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       FND_FILE.OUTPUT
--                      ,lv_out_msg
--                      ,0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END init;
----
--  /**********************************************************************************
--   * Procedure Name   : check_acctg_period
--   * Description      : 妥当性チェック処理(A-2)
--   ***********************************************************************************/
--  PROCEDURE check_acctg_period(
--     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ
--    ,ov_retcode    OUT VARCHAR2      --   リターン・コード
--    ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name          CONSTANT VARCHAR2(20) := 'check_acctg_period'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;                   -- エラー・メッセージ
--    lv_retcode           VARCHAR2(1)    DEFAULT cv_status_normal;       -- リターン・コード
--    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;                   -- ユーザー・エラー・メッセージ
--    lv_out_msg           VARCHAR2(2000) DEFAULT NULL;                   -- 出力メッセージ
--    lb_retcode           BOOLEAN        DEFAULT TRUE;                   -- メッセージ出力のリターン・コード
--    lb_acctb_period_chk  BOOLEAN        DEFAULT FALSE;                  -- 会計期間チェック：有効/無効(TRUE/FALSE)
--    -- *** ローカル例外 ***
--    acctg_chk_expt   EXCEPTION;        -- 会計期間チェック例外
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- ====================================================
--    -- 妥当性チェック
--    -- ====================================================
--    lb_acctb_period_chk := xxcok_common_pkg.check_acctg_period_f(
--                              TO_NUMBER( gv_set_of_bks_id )
--                             ,gd_payment_date
--                             ,cv_app_short_name
--                           );
--    IF( lb_acctb_period_chk = FALSE ) THEN
--      RAISE acctg_chk_expt;
--    END IF;
----
--  EXCEPTION
--    --*** 会計期間チェック例外 ***
--    WHEN acctg_chk_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_name_cok
--                      ,iv_name         => cv_acctg_chk_err_msg
--                      ,iv_token_name1  => cv_proc_date_token
--                      ,iv_token_value1 => TO_CHAR( gd_payment_date, 'YYYY/MM/DD' )
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       FND_FILE.OUTPUT
--                      ,lv_out_msg
--                      ,0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END check_acctg_period;
----
--  /**********************************************************************************
--   * Procedure Name   : get_interface_add_info
--   * Description      : GL連携データ付加情報の取得(A-4)
--   ***********************************************************************************/
--  PROCEDURE get_interface_add_info(
--     ov_errbuf                    OUT VARCHAR2                                         -- エラー・メッセージ
--    ,ov_retcode                   OUT VARCHAR2                                         -- リターン・コード
--    ,ov_errmsg                    OUT VARCHAR2                                         -- ユーザー・エラー・メッセージ
--    ,iv_gl_add_info_flag          IN  VARCHAR2                                         -- GL付加情報フラグ
--    ,iv_bank_charge_flag          IN  VARCHAR2                                         -- 銀行手数料フラグ
--    ,it_base_code_slip            IN  xxcok_backmargin_balance.base_code%TYPE          -- 拠点コード(MAX)
--    ,it_supplier_code_slip        IN  xxcok_backmargin_balance.supplier_code%TYPE      -- 仕入先コード(MAX)
--    ,it_supplier_site_code_slip   IN  xxcok_backmargin_balance.supplier_site_code%TYPE -- 仕入先サイトコード(MAX)
--    ,in_bank_chrg_amt_slip        IN  NUMBER                                           -- 振込手数料額（仕入先）
--    ,in_bank_sales_tax_slip       IN  NUMBER                                           -- 振込手数料税額（仕入先）
--    ,ov_sales_staff_code          OUT VARCHAR2                                         -- 営業担当者コード
--    ,ov_corp_code                 OUT VARCHAR2                                         -- 企業コード
--    ,ov_period_name               OUT VARCHAR2                                         -- 会計期間名
--    ,ov_slip_number               OUT VARCHAR2                                         -- 伝票番号
--    ,on_payment_chrg_amt          OUT NUMBER                                           -- 振込手数料額
--    ,on_bank_sales_tax            OUT NUMBER                                           -- 振込手数料税額
--    ,ot_base_code_vendor          OUT xxcok_backmargin_balance.base_code%TYPE          -- 拠点コード(MAX)
--    ,ot_supplier_code_vendor      OUT xxcok_backmargin_balance.supplier_code%TYPE      -- 仕入先コード(MAX)
--    ,ot_supplier_site_code_vendor OUT xxcok_backmargin_balance.supplier_site_code%TYPE -- 仕入先サイトコード(MAX)
--    ,on_bank_chrg_amt_vendor      OUT NUMBER                                           -- 振込手数料額（仕入先）
--    ,on_bank_sales_tax_vendor     OUT NUMBER                                           -- 振込手数料税額（仕入先）
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--    ,ot_cust_code_vendor          OUT xxcok_backmargin_balance.cust_code%TYPE          -- 顧客コード(MAX)
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name                CONSTANT VARCHAR2(30) := 'get_interface_add_info';  -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- エラー・バッファ
--    lv_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;            -- リターン・コード
--    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- エラー・メッセージ
--    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                        -- 出力メッセージ
--    lb_retcode                 BOOLEAN        DEFAULT TRUE;                        -- メッセージ出力のリターン・コード
--    ln_period_year             NUMBER         DEFAULT NULL;                        -- 会計年度
--    lv_closing_status          VARCHAR2(1)    DEFAULT NULL;                        -- ステータス
--    lv_sales_staff_code        VARCHAR2(20)   DEFAULT NULL;                        -- 営業担当者コード
--    lv_corp_code               VARCHAR2(20)   DEFAULT NULL;                        -- 企業コード
--    lv_period_name             VARCHAR2(20)   DEFAULT NULL;                        -- 会計期間名
--    lv_slip_number             VARCHAR2(20)   DEFAULT NULL;                        -- 伝票番号
--    -- 振込手数料
--    ln_bank_chrg_amt           NUMBER         DEFAULT NULL;                        -- 振込手数料額
--    ln_bank_sales_tax          NUMBER         DEFAULT NULL;                        -- 振込手数料消費税額
--    -- 銀行手数料算出情報
--    lt_supplier_code           xxcok_backmargin_balance.supplier_code%TYPE      DEFAULT NULL; -- 仕入先コード
--    lt_supplier_site_code      xxcok_backmargin_balance.supplier_site_code%TYPE DEFAULT NULL; -- 仕入先サイトコード
--    lt_payment_amt_tax         xxcok_backmargin_balance.payment_amt_tax%TYPE    DEFAULT NULL; -- 支払額
--    -- 銀行手数料振込拠点情報
--    lt_base_code_max           xxcok_backmargin_balance.base_code%TYPE          DEFAULT NULL; -- 拠点コード(MAX)
--    lt_supplier_code_max       xxcok_backmargin_balance.supplier_code%TYPE      DEFAULT NULL; -- 仕入先コード(MAX)
--    lt_supplier_site_code_max  xxcok_backmargin_balance.supplier_site_code%TYPE DEFAULT NULL; -- 仕入先サイトコード(MAX)
--    lt_payment_amt_max         xxcok_backmargin_balance.payment_amt_tax%TYPE    DEFAULT NULL; -- 支払額(MAX)
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--    lt_cust_code_max           xxcok_backmargin_balance.cust_code%TYPE          DEFAULT NULL; -- 顧客コード(MAX)
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- ====================================================
--    -- 1. 営業担当員コードを取得
--    -- ====================================================
--    lv_sales_staff_code := xxcok_common_pkg.get_sales_staff_code_f(
--                              g_gl_interface_rec.cust_code
--                             ,gd_process_date
--                           );
--    IF( lv_sales_staff_code IS NULL ) THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_name_cok
--                      ,iv_name         => cv_sales_staff_code_err_msg
--                      ,iv_token_name1  => cv_cust_code_token
--                      ,iv_token_value1 => g_gl_interface_rec.cust_code
--                    );
--      RAISE global_nodata_expt;
--    END IF;
----
--    -- ====================================================
--    -- 2. 企業コードを取得
--    -- ====================================================
--    lv_corp_code := xxcok_common_pkg.get_companies_code_f( g_gl_interface_rec.cust_code );
--    IF( lv_corp_code IS NULL ) THEN
--      lv_corp_code := gv_aff6_company_dummy;
--    END IF;
----
--    -- ====================================================
--    -- 3. 会計期間名を取得
--    -- ====================================================
--    xxcok_common_pkg.get_acctg_calendar_p(
--       ov_errbuf                  =>   lv_errbuf
--      ,ov_retcode                 =>   lv_retcode
--      ,ov_errmsg                  =>   lv_errmsg
--      ,in_set_of_books_id         =>   TO_NUMBER( gv_set_of_bks_id )          -- 会計帳簿ID
--      ,iv_application_short_name  =>   cv_app_short_name                      -- アプリケーション短縮名
--      ,id_object_date             =>   g_gl_interface_rec.expect_payment_date -- 支払予定日
--      ,on_period_year             =>   ln_period_year                         -- 会計年度
--      ,ov_period_name             =>   lv_period_name                         -- 会計期間名
--      ,ov_closing_status          =>   lv_closing_status                      -- ステータス
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_name_cok
--                      ,iv_name         => cv_acctg_calendar_err_msg
--                      ,iv_token_name1  => cv_proc_date_token
--                      ,iv_token_value1 => TO_CHAR( gd_payment_date, 'YYYY/MM/DD' )
--                    );
--      RAISE global_nodata_expt;
--    END IF;
----
--    -- ====================================================
--    -- GL付加情報フラグがYの場合
--    -- （拠点コードまたは仕入先コードが変わった場合）
--    -- ====================================================
--    IF( iv_gl_add_info_flag = cv_gl_add_info_y ) THEN
--      -- ====================================================
--      -- 4. 伝票番号を取得
--      -- ====================================================
--      lv_slip_number := xxcok_common_pkg.get_slip_number_f( cv_program_id );
--      IF( lv_slip_number IS NULL ) THEN
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_app_name_cok
--                        ,iv_name         => cv_slip_number_err_msg
--                      );
--        RAISE global_nodata_expt;
--      END IF;
--      -- ====================================================
--      -- OUTパラメータ設定
--      -- ====================================================
--      ov_slip_number := lv_slip_number;        -- 伝票番号
--    END IF;
----
--    -- ====================================================
--    -- 銀行手数料設定フラグがYの場合
--    -- （仕入先コードが変わった場合）
--    -- ====================================================
--    IF( iv_bank_charge_flag = cv_bank_charge_y ) THEN
--      -- ====================================================
--      -- 5. 銀行手数料算出情報を取得
--      -- ====================================================
--      SELECT xbb.supplier_code          AS supplier_code       -- 仕入先コード
--            ,xbb.supplier_site_code     AS supplier_site_code  -- 仕入先サイトコード
--            ,SUM( xbb.payment_amt_tax ) AS payment_amt_tax     -- 支払額
--      INTO lt_supplier_code
--          ,lt_supplier_site_code
--          ,lt_payment_amt_tax
--      FROM xxcok_backmargin_balance  xbb
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama DEL START
----          ,po_vendors                pv
----          ,po_vendor_sites_all       pvsa
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama DEL END
--      WHERE xbb.fb_interface_status         = cv_interface_status_fb
--      AND   xbb.gl_interface_status         = cv_if_status_gl_before
--      AND   xbb.supplier_code               = g_gl_interface_rec.supplier_code
--      AND   xbb.supplier_site_code          = g_gl_interface_rec.supplier_site_code
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama DEL START
----      AND   xbb.supplier_code               = pv.segment1
----      AND   xbb.supplier_site_code          = pvsa.vendor_site_code
----      AND   pvsa.hold_all_payments_flag     = cv_hold_pay_flag_n
----      AND   (   ( pvsa.inactive_date IS NULL )
----              OR( pvsa.inactive_date >= gd_payment_date ) )
----      AND   pvsa.attribute4 IN( cv_bm_payment_type1, cv_bm_payment_type2 )
------ Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----      AND   pvsa.org_id = gn_org_id
------ End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama DEL END
--      GROUP BY xbb.supplier_code
--              ,xbb.supplier_site_code
--      ;
----
--      -- ====================================================
--      -- 6. 振込手数料を算出
--      -- ====================================================
--      -- 銀行手数料_振込額基準未満
--      IF( lt_payment_amt_tax < TO_NUMBER( gv_bank_fee_trans_criterion ) ) THEN
--        ln_bank_chrg_amt := TO_NUMBER( gv_bank_fee_less_criterion );
--      -- 銀行手数料_振込額基準以上
--      ELSIF( lt_payment_amt_tax >= TO_NUMBER( gv_bank_fee_trans_criterion ) ) THEN
--        ln_bank_chrg_amt := TO_NUMBER( gv_bank_fee_more_criterion );
--      END IF;
--      -- ====================================================
--      -- 振込手数料消費税額算出
--      -- ====================================================
--      ln_bank_sales_tax := ln_bank_chrg_amt * ( TO_NUMBER( gv_bm_tax ) / 100 );
----
--      -- ====================================================
--      -- 7. 銀行手数料振込拠点情報を取得
--      -- ====================================================
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama UPD START
----      SELECT base.base_code           AS base_code          -- 拠点コード
----            ,base.supplier_code       AS supplier_code      -- 仕入先コード
----            ,base.supplier_site_code  AS supplier_site_code -- 仕入先サイトコード
----            ,base.payment_amt         AS payment_amt_max    -- 支払額（MAX）
------ Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----            ,base.cust_code           AS cust_code
------ End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----      INTO lt_base_code_max
----          ,lt_supplier_code_max
----          ,lt_supplier_site_code_max
----          ,lt_payment_amt_max
------ Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----          ,lt_cust_code_max
------ End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----      FROM ( SELECT ROW_NUMBER() over (
----                      ORDER BY SUM( xbb.payment_amt_tax ) DESC
------ Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----                              ,xbb.cust_code              ASC
------ End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----                              ,xbb.base_code              ASC
----                    )                              AS row_num
----                   ,xbb.base_code                  AS base_code
----                   ,xbb.supplier_code              AS supplier_code
----                   ,xbb.supplier_site_code         AS supplier_site_code
----                   ,SUM( xbb.payment_amt_tax )     AS payment_amt
------ Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----                   ,xbb.cust_code                  AS cust_code
------ End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----             FROM xxcok_backmargin_balance  xbb
----                 ,po_vendors                pv
----                 ,po_vendor_sites_all       pvsa
----             WHERE xbb.fb_interface_status     =  cv_interface_status_fb
----             AND   xbb.gl_interface_status     =  cv_if_status_gl_before
----             AND   xbb.supplier_code           =  g_gl_interface_rec.supplier_code
----             AND   xbb.supplier_site_code      =  g_gl_interface_rec.supplier_site_code
----             AND   xbb.supplier_code           =  pv.segment1
----             AND   xbb.supplier_site_code      =  pvsa.vendor_site_code
----             AND   pvsa.hold_all_payments_flag =  cv_hold_pay_flag_n
----             AND   (   ( pvsa.inactive_date      IS NULL )
----                     OR( pvsa.inactive_date      >= gd_payment_date ) )
----             AND   pvsa.attribute4 IN( cv_bm_payment_type1, cv_bm_payment_type2 )
------ Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----             AND   pvsa.org_id                 = gn_org_id
------ End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----             GROUP BY xbb.base_code
----                     ,xbb.supplier_code
----                     ,xbb.supplier_site_code
------ Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----                     ,xbb.cust_code
------ End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----             ) base
----      WHERE base.row_num = 1
----      ;
--      SELECT base.base_code           AS base_code          -- 拠点コード
--            ,base.supplier_code       AS supplier_code      -- 仕入先コード
--            ,base.supplier_site_code  AS supplier_site_code -- 仕入先サイトコード
--            ,base.payment_amt         AS payment_amt_max    -- 支払額（MAX）
--            ,base.cust_code           AS cust_code
--      INTO lt_base_code_max
--          ,lt_supplier_code_max
--          ,lt_supplier_site_code_max
--          ,lt_payment_amt_max
--          ,lt_cust_code_max
--      FROM ( SELECT /*+ INDEX( xbb xxcok_backmargin_balance_n09 ) */
--                    ROW_NUMBER() over (
--                      ORDER BY SUM( xbb.payment_amt_tax ) DESC
--                              ,xbb.cust_code              ASC
--                              ,xbb.base_code              ASC
--                    )                              AS row_num
--                   ,xbb.base_code                  AS base_code
--                   ,xbb.supplier_code              AS supplier_code
--                   ,xbb.supplier_site_code         AS supplier_site_code
--                   ,SUM( xbb.payment_amt_tax )     AS payment_amt
--                   ,xbb.cust_code                  AS cust_code
--             FROM xxcok_backmargin_balance  xbb
--             WHERE xbb.fb_interface_status     =  cv_interface_status_fb
--             AND   xbb.gl_interface_status     =  cv_if_status_gl_before
--             AND   xbb.supplier_code           =  g_gl_interface_rec.supplier_code
--             AND   xbb.supplier_site_code      =  g_gl_interface_rec.supplier_site_code
--             GROUP BY xbb.base_code
--                     ,xbb.supplier_code
--                     ,xbb.supplier_site_code
--                     ,xbb.cust_code
--             ) base
--      WHERE base.row_num = 1
--      ;
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama UPD END
----
--      -- ====================================================
--      -- OUTパラメータ設定（仕入先単位）
--      -- ====================================================
--      ot_base_code_vendor           := lt_base_code_max;           -- 拠点コード
--      ot_supplier_code_vendor       := lt_supplier_code_max;       -- 仕入先コード
--      ot_supplier_site_code_vendor  := lt_supplier_site_code_max;  -- 仕入先サイトコード
--      on_bank_chrg_amt_vendor       := ln_bank_chrg_amt;           -- 振込手数料
--      on_bank_sales_tax_vendor      := ln_bank_sales_tax;          -- 振込手数料消費税額
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--      ot_cust_code_vendor           := lt_cust_code_max;           -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--    END IF;
----
--    -- ====================================================
--    -- 8. 振込手数料を設定
--    -- ====================================================
--    -- ====================================================
--    -- 銀行手数料設定フラグがYの場合
--    -- （仕入先コードが変わった場合）
--    -- ====================================================
--    IF( iv_bank_charge_flag = cv_bank_charge_y ) THEN
--      IF(    g_gl_interface_rec.base_code          = lt_base_code_max )
--        AND( g_gl_interface_rec.supplier_code      = lt_supplier_code_max )
--        AND( g_gl_interface_rec.supplier_site_code = lt_supplier_site_code_max )
--      THEN
--        on_payment_chrg_amt := ln_bank_chrg_amt;
--        on_bank_sales_tax   := ln_bank_sales_tax;
--      ELSE
--        on_payment_chrg_amt := 0;
--        on_bank_sales_tax   := 0;
--      END IF;
--    -- ====================================================
--    -- GL付加情報フラグがYの場合
--    -- （拠点コードまたは仕入先コードが変わった場合）
--    -- ====================================================
--    ELSIF( iv_gl_add_info_flag = cv_gl_add_info_y ) THEN
--      IF(    g_gl_interface_rec.base_code          = it_base_code_slip )
--        AND( g_gl_interface_rec.supplier_code      = it_supplier_code_slip )
--        AND( g_gl_interface_rec.supplier_site_code = it_supplier_site_code_slip )
--      THEN
--        on_payment_chrg_amt := in_bank_chrg_amt_slip;
--        on_bank_sales_tax   := in_bank_sales_tax_slip;
--      ELSE
--        on_payment_chrg_amt := 0;
--        on_bank_sales_tax   := 0;
--      END IF;
--    END IF;
----
--    -- ====================================================
--    -- OUTパラメータ設定
--    -- ====================================================
--    ov_sales_staff_code := lv_sales_staff_code;   -- 営業担当者コード
--    ov_corp_code        := lv_corp_code;          -- 企業コード
--    ov_period_name      := lv_period_name;        -- 会計期間名
----
--  EXCEPTION
--    --*** データ取得例外 ***
--    WHEN global_nodata_expt THEN
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       FND_FILE.OUTPUT
--                      ,lv_out_msg
--                      ,0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END get_interface_add_info;
----
--  /**********************************************************************************
--   * Procedure Name   : insert_interface_info
--   * Description      : GL連携データの登録(A-5)
--   ***********************************************************************************/
--  PROCEDURE insert_interface_info(
--     ov_errbuf                    OUT VARCHAR2                                         -- エラー・メッセージ
--    ,ov_retcode                   OUT VARCHAR2                                         -- リターン・コード
--    ,ov_errmsg                    OUT VARCHAR2                                         -- ユーザー・エラー・メッセージ
--    ,it_entered_dr                IN  gl_interface.entered_dr%TYPE                     -- 借方金額
--    ,it_entered_cr                IN  gl_interface.entered_cr%TYPE                     -- 貸方金額
--    ,it_department                IN  gl_interface.segment2%TYPE                       -- 部門
--    ,it_account                   IN  gl_interface.segment3%TYPE                       -- 勘定科目
--    ,it_sub_account               IN  gl_interface.segment4%TYPE                       -- 補助科目
--    ,it_accounting_date           IN  gl_interface.accounting_date%TYPE                -- 仕訳有効日付
--    ,it_currency_code             IN  gl_interface.currency_code%TYPE                  -- 通貨コード
--    ,it_customer_code             IN  gl_interface.segment5%TYPE                       -- 顧客コード
--    ,it_corp_code                 IN  gl_interface.segment6%TYPE                       -- 企業コード
--    ,it_gl_name                   IN  gl_interface.reference4%TYPE                     -- 仕訳名
--    ,it_period_name               IN  gl_interface.period_name%TYPE                    -- 会計期間名
--    ,it_tax_code                  IN  gl_interface.attribute1%TYPE                     -- 税区分
--    ,it_slip_number               IN  gl_interface.attribute3%TYPE                     -- 伝票番号
--    ,it_dept_base                 IN  gl_interface.attribute4%TYPE                     -- 起票部門
--    ,it_sales_staff_code          IN  gl_interface.attribute5%TYPE                     -- 伝票入力者
--    ,it_supplier_code_before      IN  xxcok_backmargin_balance.supplier_code%TYPE      -- 仕入先コード
--    ,it_supplier_site_code_before IN  xxcok_backmargin_balance.supplier_site_code%TYPE -- 仕入先サイトコード
--    ,it_cust_code_before          IN  xxcok_backmargin_balance.cust_code%TYPE          -- 顧客コード
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name        CONSTANT VARCHAR2(30) := 'insert_interface_info';      -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf          VARCHAR2(5000)               DEFAULT NULL;             -- エラー・メッセージ
--    lv_retcode         VARCHAR2(1)                  DEFAULT cv_status_normal; -- リターン・コード
--    lv_errmsg          VARCHAR2(5000)               DEFAULT NULL;             -- ユーザー・エラー・メッセージ
--    lv_out_msg         VARCHAR2(2000)               DEFAULT NULL;             -- 出力メッセージ
--    lb_retcode         BOOLEAN                      DEFAULT TRUE;             -- メッセージ出力のリターン・コード
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- ====================================================
--    -- GLインタフェース登録
--    -- ====================================================
--    BEGIN
--      INSERT INTO gl_interface(
--         status                         -- ステータス
--        ,set_of_books_id                -- 会計帳簿ID
--        ,accounting_date                -- 仕訳有効日付
--        ,currency_code                  -- 通貨コード
--        ,date_created                   -- 新規作成日付
--        ,created_by                     -- 新規作成者ID
--        ,actual_flag                    -- 残高タイプ
--        ,user_je_category_name          -- 仕訳カテゴリ名
--        ,user_je_source_name            -- 仕訳ソース名
--        ,segment1                       -- 会社
--        ,segment2                       -- 部門
--        ,segment3                       -- 勘定科目
--        ,segment4                       -- 補助科目
--        ,segment5                       -- 顧客コード
--        ,segment6                       -- 企業コード
--        ,segment7                       -- 予備１
--        ,segment8                       -- 予備２
--        ,entered_dr                     -- 借方金額
--        ,entered_cr                     -- 貸方金額
--        ,reference1                     -- バッチ名
--        ,reference4                     -- 仕訳名
--        ,period_name                    -- 会計期間名
--        ,group_id                       -- グループID
--        ,attribute1                     -- 税区分
--        ,attribute3                     -- 伝票番号
--        ,attribute4                     -- 起票部門
--        ,attribute5                     -- 伝票入力者
--        ,context                        -- DFFコンテキスト
--      ) VALUES (
--         cv_gl_if_tab_status            -- ステータス
--        ,TO_NUMBER( gv_set_of_bks_id )  -- 会計帳簿ID
--        ,it_accounting_date             -- 仕訳有効日付
--        ,it_currency_code               -- 通貨コード
--        ,SYSDATE                        -- 新規作成日付
--        ,fnd_global.user_id             -- 新規作成者ID
--        ,cv_balance_flag_a              -- 残高タイプ
--        ,gv_gl_category_bm              -- 仕訳カテゴリ名
--        ,gv_gl_source_cok               -- 仕訳ソース名
--        ,gv_aff1_company_code           -- 会社
--        ,it_department                  -- 部門
--        ,it_account                     -- 勘定科目
--        ,it_sub_account                 -- 補助科目
--        ,it_customer_code               -- 顧客コード
--        ,it_corp_code                   -- 企業コード
--        ,gv_aff7_preliminary1_dummy     -- 予備１
--        ,gv_aff8_preliminary2_dummy     -- 予備２
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama UPD START
----        ,it_entered_dr                  -- 借方金額
----        ,it_entered_cr                  -- 貸方金額
--        , CASE WHEN ( it_entered_dr > 0 AND it_entered_dr IS NOT NULL ) THEN it_entered_dr
--               WHEN ( it_entered_cr < 0 AND it_entered_cr IS NOT NULL ) THEN it_entered_cr * -1
--               ELSE NULL END
--        , CASE WHEN ( it_entered_cr > 0 AND it_entered_cr IS NOT NULL ) THEN it_entered_cr
--               WHEN ( it_entered_dr < 0 AND it_entered_dr IS NOT NULL ) THEN it_entered_dr * -1
--               ELSE NULL END
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama UPD END
--        ,gv_batch_name                  -- バッチ名
--        ,it_gl_name                     -- 仕訳名
--        ,it_period_name                 -- 会計期間名
--        ,TO_NUMBER( gt_group_id )       -- グループID
--        ,it_tax_code                    -- 税区分
--        ,it_slip_number                 -- 伝票番号
--        ,it_dept_base                   -- 起票部門
--        ,it_sales_staff_code            -- 伝票入力者
--        ,gv_set_of_bks_name             -- DFFコンテキスト
--      );
----
--    EXCEPTION
--      --*** GL連携データ登録例外 ***
--      WHEN OTHERS THEN
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_app_name_cok
--                        ,iv_name         => cv_gl_insert_err_msg
--                        ,iv_token_name1  => cv_dept_code_token
--                        ,iv_token_value1 => it_dept_base
--                        ,iv_token_name2  => cv_vend_code_token
--                        ,iv_token_value2 => it_supplier_code_before
--                        ,iv_token_name3  => cv_vend_site_code_token
--                        ,iv_token_value3 => it_supplier_site_code_before
--                        ,iv_token_name4  => cv_cust_code_token
--                        ,iv_token_value4 => it_cust_code_before
--                        ,iv_token_name5  => cv_pay_date_token
--                        ,iv_token_value5 => TO_CHAR( it_accounting_date, 'YYYY/MM/DD' )
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                         FND_FILE.OUTPUT
--                        ,lv_out_msg
--                        ,0
--                      );
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--        ov_retcode := cv_status_error;
----
--    END;
----
--  EXCEPTION
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END insert_interface_info;
----
--  /**********************************************************************************
--   * Procedure Name   : set_insert_info
--   * Description      : 仕訳作成
--   *                    明細起票時残高金額が0以下の場合は勘定科目に関係なく貸借逆転で作成する
--   ***********************************************************************************/
--  PROCEDURE set_insert_info(
--     ov_errbuf                     OUT VARCHAR2                                          -- エラー・メッセージ
--    ,ov_retcode                    OUT VARCHAR2                                          -- リターン・コード
--    ,ov_errmsg                     OUT VARCHAR2                                          -- ユーザー・エラー・メッセージ
--    ,iv_insert_flag                IN  VARCHAR2                                          -- GLインタフェース登録フラグ
--    ,it_base_code_before           IN  xxcok_backmargin_balance.base_code%TYPE           -- 拠点コード
--    ,it_tax_code_before            IN  xxcok_backmargin_balance.tax_code%TYPE            -- 税金コード
--    ,it_expect_payment_date_before IN  xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払予定日
--    ,it_bank_charge_bearer_before  IN  po_vendor_sites_all.bank_charge_bearer%TYPE       -- 銀行手数料負担者
--    ,it_payment_currency_before    IN  po_vendor_sites_all.payment_currency_code%TYPE    -- 支払通貨
--    ,it_supplier_code_before       IN  xxcok_backmargin_balance.supplier_code%TYPE       -- 仕入先コード
--    ,it_supplier_site_code_before  IN  xxcok_backmargin_balance.supplier_site_code%TYPE  -- 仕入先サイトコード
--    ,it_cust_code_before           IN  xxcok_backmargin_balance.cust_code%TYPE           -- 顧客コード
--    ,iv_corp_code                  IN  VARCHAR2                                          -- 企業コード
--    ,in_bm_sum_amt_tax_before      IN  NUMBER                                            -- 販売手数料消費税額合計
--    ,in_electric_sum_tax_before    IN  NUMBER                                            -- 電気料消費税額合計
--    ,in_payment_sum_amt_before     IN  NUMBER                                            -- 振込額合計
--    ,iv_sales_staff_code           IN  VARCHAR2                                          -- 営業担当者コード
--    ,iv_period_name                IN  VARCHAR2                                          -- 会計期間名
--    ,iv_slip_number                IN  VARCHAR2                                          -- 伝票番号
--    ,in_payment_chrg_amt           IN  NUMBER                                            -- 振込手数料額
--    ,in_bank_sales_tax             IN  NUMBER                                            -- 振込手数料消費税額
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name          CONSTANT VARCHAR2(30) := 'set_insert_info';      -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf            VARCHAR2(5000)               DEFAULT NULL;             -- エラー・メッセージ
--    lv_retcode           VARCHAR2(1)                  DEFAULT cv_status_normal; -- リターン・コード
--    lv_errmsg            VARCHAR2(5000)               DEFAULT NULL;             -- ユーザー・エラー・メッセージ
--    lv_out_msg           VARCHAR2(2000)               DEFAULT NULL;             -- 出力メッセージ
--    lb_retcode           BOOLEAN                      DEFAULT TRUE;             -- メッセージ出力のリターン・コード
--    -- GLインタフェース登録データ
--    lt_entered_dr                 gl_interface.entered_dr%TYPE                     DEFAULT NULL; -- 借方金額
--    lt_entered_cr                 gl_interface.entered_cr%TYPE                     DEFAULT NULL; -- 貸方金額
--    lt_department                 gl_interface.segment2%TYPE                       DEFAULT NULL; -- 部門
--    lt_account                    gl_interface.segment3%TYPE                       DEFAULT NULL; -- 勘定科目
--    lt_sub_account                gl_interface.segment4%TYPE                       DEFAULT NULL; -- 補助科目
--    lt_accounting_date            gl_interface.accounting_date%TYPE                DEFAULT NULL; -- 仕訳有効日付
--    lt_currency_code              gl_interface.currency_code%TYPE                  DEFAULT NULL; -- 通貨コード
--    lt_customer_code              gl_interface.segment5%TYPE                       DEFAULT NULL; -- 顧客コード
--    lt_corp_code                  gl_interface.segment6%TYPE                       DEFAULT NULL; -- 企業コード
--    lt_gl_name                    gl_interface.reference4%TYPE                     DEFAULT NULL; -- 仕訳名
--    lt_period_name                gl_interface.period_name%TYPE                    DEFAULT NULL; -- 会計期間名
--    lt_tax_code                   gl_interface.attribute1%TYPE                     DEFAULT NULL; -- 税区分
--    lt_slip_number                gl_interface.attribute3%TYPE                     DEFAULT NULL; -- 伝票番号
--    lt_dept_base                  gl_interface.attribute4%TYPE                     DEFAULT NULL; -- 起票部門
--    lt_sales_staff_code           gl_interface.attribute5%TYPE                     DEFAULT NULL; -- 伝票入力者
--    lt_supplier_code_before       xxcok_backmargin_balance.supplier_code%TYPE      DEFAULT NULL; -- 仕入先コード
--    lt_supplier_site_code_before  xxcok_backmargin_balance.supplier_site_code%TYPE DEFAULT NULL; -- 仕入先サイトコード
--    lt_cust_code_before           xxcok_backmargin_balance.cust_code%TYPE          DEFAULT NULL; -- 顧客コード
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--    lt_cust_code_vendor           xxcok_backmargin_balance.cust_code%TYPE          DEFAULT NULL; -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- ====================================================
--    -- GLインタフェース登録フラグが'V'の場合
--    -- 顧客毎の仕訳作成
--    -- ====================================================
--    IF( iv_insert_flag = cv_vend_sales ) THEN
--      -- エラーメッセージ用
--      lt_supplier_code_before      := g_gl_interface_rec.supplier_code;         -- 仕入先コード
--      lt_supplier_site_code_before := g_gl_interface_rec.supplier_site_code;    -- 仕入先サイトコード
--      lt_cust_code_before          := g_gl_interface_rec.cust_code;             -- 顧客コード
--      -- 登録データ
--      lt_accounting_date           := g_gl_interface_rec.expect_payment_date;   -- 仕訳有効日付
--      lt_currency_code             := g_gl_interface_rec.payment_currency_code; -- 通貨コード
--      lt_customer_code             := g_gl_interface_rec.cust_code;             -- 顧客コード
--      lt_corp_code                 := iv_corp_code;                             -- 企業コード
--      lt_gl_name                   := iv_slip_number;                           -- 仕訳名
--      lt_period_name               := iv_period_name;                           -- 会計期間名
--      lt_tax_code                  := g_gl_interface_rec.tax_code;              -- 税区分
--      lt_slip_number               := iv_slip_number;                           -- 伝票番号
--      lt_dept_base                 := g_gl_interface_rec.base_code;             -- 起票部門
--      lt_sales_staff_code          := iv_sales_staff_code;                      -- 伝票入力者
----
--      -- ====================================================
--      -- 販売手数料
--      -- ====================================================
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama UPD START
----      IF( g_gl_interface_rec.backmargin > 0 ) THEN
--      IF( g_gl_interface_rec.backmargin != 0 ) THEN
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama UPD END
--        lt_department  := g_gl_interface_rec.base_code;     -- 拠点コード
--        lt_account     := gv_aff3_vend_sales_commission;    -- 自販機販手
--        lt_sub_account := gv_aff4_vend_sales_rebate;        -- 自販機リベート
--        lt_entered_dr  := g_gl_interface_rec.backmargin;    -- 販売手数料
--        lt_entered_cr  := NULL;                             -- 貸方金額
--        -- ====================================================
--        -- GLインタフェース登録
--        -- ====================================================
--        insert_interface_info(
--           ov_errbuf                    => lv_errbuf                    -- エラー・メッセージ
--          ,ov_retcode                   => lv_retcode                   -- リターン・コード
--          ,ov_errmsg                    => lv_errmsg                    -- ユーザー・エラー・メッセージ
--          ,it_entered_dr                => lt_entered_dr                -- 借方金額
--          ,it_entered_cr                => lt_entered_cr                -- 貸方金額
--          ,it_department                => lt_department                -- 部門
--          ,it_account                   => lt_account                   -- 勘定科目
--          ,it_sub_account               => lt_sub_account               -- 補助科目
--          ,it_accounting_date           => lt_accounting_date           -- 仕訳有効日付
--          ,it_currency_code             => lt_currency_code             -- 通貨コード
--          ,it_customer_code             => lt_customer_code             -- 顧客コード
--          ,it_corp_code                 => lt_corp_code                 -- 企業コード
--          ,it_gl_name                   => lt_gl_name                   -- 仕訳名
--          ,it_period_name               => lt_period_name               -- 会計期間名
--          ,it_tax_code                  => lt_tax_code                  -- 税区分
--          ,it_slip_number               => lt_slip_number               -- 伝票番号
--          ,it_dept_base                 => lt_dept_base                 -- 起票部門
--          ,it_sales_staff_code          => lt_sales_staff_code          -- 伝票入力者
--          ,it_supplier_code_before      => lt_supplier_code_before      -- 仕入先コード
--          ,it_supplier_site_code_before => lt_supplier_site_code_before -- 仕入先サイトコード
--          ,it_cust_code_before          => lt_cust_code_before          -- 顧客コード
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--      -- ====================================================
--      -- 電気料
--      -- ====================================================
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama UPD START
----      IF( g_gl_interface_rec.electric_amt > 0 ) THEN
--      IF( g_gl_interface_rec.electric_amt != 0 ) THEN
---- 2009/10/19 Ver.1.5 [障害E_T4_00044] SCS S.Moriyama UPD END
--        lt_department  := g_gl_interface_rec.base_code;     -- 拠点コード
--        lt_account     := gv_aff3_vend_sales_commission;    -- 自販機販手
--        lt_sub_account := gv_aff4_vend_sales_elec_cost;     -- 自販機電気料
--        lt_entered_dr  := g_gl_interface_rec.electric_amt;  -- 電気料
--        lt_entered_cr  := NULL;                             -- 貸方金額
--        -- ====================================================
--        -- GLインタフェース登録
--        -- ====================================================
--        insert_interface_info(
--           ov_errbuf                    => lv_errbuf                    -- エラー・メッセージ
--          ,ov_retcode                   => lv_retcode                   -- リターン・コード
--          ,ov_errmsg                    => lv_errmsg                    -- ユーザー・エラー・メッセージ
--          ,it_entered_dr                => lt_entered_dr                -- 借方金額
--          ,it_entered_cr                => lt_entered_cr                -- 貸方金額
--          ,it_department                => lt_department                -- 部門
--          ,it_account                   => lt_account                   -- 勘定科目
--          ,it_sub_account               => lt_sub_account               -- 補助科目
--          ,it_accounting_date           => lt_accounting_date           -- 仕訳有効日付
--          ,it_currency_code             => lt_currency_code             -- 通貨コード
--          ,it_customer_code             => lt_customer_code             -- 顧客コード
--          ,it_corp_code                 => lt_corp_code                 -- 企業コード
--          ,it_gl_name                   => lt_gl_name                   -- 仕訳名
--          ,it_period_name               => lt_period_name               -- 会計期間名
--          ,it_tax_code                  => lt_tax_code                  -- 税区分
--          ,it_slip_number               => lt_slip_number               -- 伝票番号
--          ,it_dept_base                 => lt_dept_base                 -- 起票部門
--          ,it_sales_staff_code          => lt_sales_staff_code          -- 伝票入力者
--          ,it_supplier_code_before      => lt_supplier_code_before      -- 仕入先コード
--          ,it_supplier_site_code_before => lt_supplier_site_code_before -- 仕入先サイトコード
--          ,it_cust_code_before          => lt_cust_code_before          -- 顧客コード
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
----
--    -- ====================================================
--    -- GLインタフェース登録フラグが'B'の場合
--    -- 伝票単位の仕訳作成
--    -- ====================================================
--    ELSIF( iv_insert_flag = cv_backmargin ) THEN
--      -- エラーメッセージ用
--      lt_supplier_code_before      := it_supplier_code_before;         -- 仕入先コード
--      lt_supplier_site_code_before := it_supplier_site_code_before;    -- 仕入先サイトコード
--      lt_cust_code_before          := it_cust_code_before;             -- 顧客コード
--      -- 登録データ
--      lt_accounting_date           := it_expect_payment_date_before;   -- 仕訳有効日付
--      lt_currency_code             := it_payment_currency_before;      -- 通貨コード
--      lt_customer_code             := gv_aff5_customer_dummy;          -- 顧客コード
--      lt_corp_code                 := gv_aff6_company_dummy;           -- 企業コード
--      lt_gl_name                   := iv_slip_number;                  -- 仕訳名
--      lt_period_name               := iv_period_name;                  -- 会計期間名
--      lt_tax_code                  := it_tax_code_before;              -- 税区分
--      lt_slip_number               := iv_slip_number;                  -- 伝票番号
--      lt_dept_base                 := it_base_code_before;             -- 起票部門
--      lt_sales_staff_code          := iv_sales_staff_code;             -- 伝票入力者
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--      lt_cust_code_vendor          := it_cust_code_before;             -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--      -- ====================================================
--      -- 1. 銀行手数料負担者が当方の場合
--      -- ====================================================
--      IF( it_bank_charge_bearer_before = cv_chrg_flag_i ) THEN
--        IF( in_payment_chrg_amt > 0 ) THEN
--          -- ====================================================
--          -- 振込手数料（借方）
--          -- ====================================================
--          lt_department  := it_base_code_before;          -- 拠点コード
--          lt_account     := gv_aff3_fee;                  -- 手数料
--          lt_sub_account := gv_aff4_transfer_fee;         -- 振込手数料
--          lt_entered_dr  := in_payment_chrg_amt;          -- 振込手数料額
--          lt_entered_cr  := NULL;                         -- 貸方金額
--          -- ====================================================
--          -- GLインタフェース登録
--          -- ====================================================
--          insert_interface_info(
--             ov_errbuf                    => lv_errbuf                    -- エラー・メッセージ
--            ,ov_retcode                   => lv_retcode                   -- リターン・コード
--            ,ov_errmsg                    => lv_errmsg                    -- ユーザー・エラー・メッセージ
--            ,it_entered_dr                => lt_entered_dr                -- 借方金額
--            ,it_entered_cr                => lt_entered_cr                -- 貸方金額
--            ,it_department                => lt_department                -- 部門
--            ,it_account                   => lt_account                   -- 勘定科目
--            ,it_sub_account               => lt_sub_account               -- 補助科目
--            ,it_accounting_date           => lt_accounting_date           -- 仕訳有効日付
--            ,it_currency_code             => lt_currency_code             -- 通貨コード
---- Start 2009/05/13 Ver_1.2 T1_0867 M.Hiruta
----            ,it_customer_code             => lt_customer_code             -- 顧客コード
----            ,it_corp_code                 => lt_corp_code                 -- 企業コード
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----            ,it_customer_code             => g_gl_interface_rec.cust_code -- 顧客コード
--            ,it_customer_code             => lt_cust_code_vendor          -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--            ,it_corp_code                 => iv_corp_code                 -- 企業コード
---- End   2009/05/13 Ver_1.2 T1_0867 M.Hiruta
--            ,it_gl_name                   => lt_gl_name                   -- 仕訳名
--            ,it_period_name               => lt_period_name               -- 会計期間名
--            ,it_tax_code                  => lt_tax_code                  -- 税区分
--            ,it_slip_number               => lt_slip_number               -- 伝票番号
--            ,it_dept_base                 => lt_dept_base                 -- 起票部門
--            ,it_sales_staff_code          => lt_sales_staff_code          -- 伝票入力者
--            ,it_supplier_code_before      => lt_supplier_code_before      -- 仕入先コード
--            ,it_supplier_site_code_before => lt_supplier_site_code_before -- 仕入先サイトコード
--            ,it_cust_code_before          => lt_cust_code_before          -- 顧客コード
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
----
--        END IF;
----
--        -- ====================================================
--        -- 消費税額（借方）
--        -- ====================================================
--        lt_department  := gv_aff2_dept_fin;               -- 財務経理部
--        lt_account     := gv_aff3_payment_excise_tax;     -- 仮払消費税等
--        lt_sub_account := gv_aff4_subacct_dummy;          -- ダミー値
--        lt_entered_dr  := ( in_bm_sum_amt_tax_before      -- 販手消費税額 + 電気料消費税額 + 振込手数料消費税額
--                          + in_electric_sum_tax_before
--                          + in_bank_sales_tax          ); -- 消費税額
--        lt_entered_cr  := NULL;                           -- 貸方金額
--        -- ====================================================
--        -- GLインタフェース登録
--        -- ====================================================
--        insert_interface_info(
--           ov_errbuf                    => lv_errbuf                    -- エラー・メッセージ
--          ,ov_retcode                   => lv_retcode                   -- リターン・コード
--          ,ov_errmsg                    => lv_errmsg                    -- ユーザー・エラー・メッセージ
--          ,it_entered_dr                => lt_entered_dr                -- 借方金額
--          ,it_entered_cr                => lt_entered_cr                -- 貸方金額
--          ,it_department                => lt_department                -- 部門
--          ,it_account                   => lt_account                   -- 勘定科目
--          ,it_sub_account               => lt_sub_account               -- 補助科目
--          ,it_accounting_date           => lt_accounting_date           -- 仕訳有効日付
--          ,it_currency_code             => lt_currency_code             -- 通貨コード
--          ,it_customer_code             => lt_customer_code             -- 顧客コード
--          ,it_corp_code                 => lt_corp_code                 -- 企業コード
--          ,it_gl_name                   => lt_gl_name                   -- 仕訳名
--          ,it_period_name               => lt_period_name               -- 会計期間名
--          ,it_tax_code                  => lt_tax_code                  -- 税区分
--          ,it_slip_number               => lt_slip_number               -- 伝票番号
--          ,it_dept_base                 => lt_dept_base                 -- 起票部門
--          ,it_sales_staff_code          => lt_sales_staff_code          -- 伝票入力者
--          ,it_supplier_code_before      => lt_supplier_code_before      -- 仕入先コード
--          ,it_supplier_site_code_before => lt_supplier_site_code_before -- 仕入先サイトコード
--          ,it_cust_code_before          => lt_cust_code_before          -- 顧客コード
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- ====================================================
--        -- 振込額（貸方）
--        -- ====================================================
--        lt_department  := gv_aff2_dept_fin;               -- 財務経理部
--        lt_account     := gv_aff3_current_account;        -- 当座預金
--        lt_sub_account := gv_aff4_current_account_our;    -- 当社口座
--        lt_entered_dr  := NULL;                           -- 借方金額
--        lt_entered_cr  := ( in_payment_sum_amt_before     -- 振込額 + 振込手数料 + 振込手数料消費税額
--                          + in_payment_chrg_amt
--                          + in_bank_sales_tax         );  -- 振込額
--        -- ====================================================
--        -- GLインタフェース登録
--        -- ====================================================
--        insert_interface_info(
--           ov_errbuf                    => lv_errbuf                    -- エラー・メッセージ
--          ,ov_retcode                   => lv_retcode                   -- リターン・コード
--          ,ov_errmsg                    => lv_errmsg                    -- ユーザー・エラー・メッセージ
--          ,it_entered_dr                => lt_entered_dr                -- 借方金額
--          ,it_entered_cr                => lt_entered_cr                -- 貸方金額
--          ,it_department                => lt_department                -- 部門
--          ,it_account                   => lt_account                   -- 勘定科目
--          ,it_sub_account               => lt_sub_account               -- 補助科目
--          ,it_accounting_date           => lt_accounting_date           -- 仕訳有効日付
--          ,it_currency_code             => lt_currency_code             -- 通貨コード
--          ,it_customer_code             => lt_customer_code             -- 顧客コード
--          ,it_corp_code                 => lt_corp_code                 -- 企業コード
--          ,it_gl_name                   => lt_gl_name                   -- 仕訳名
--          ,it_period_name               => lt_period_name               -- 会計期間名
--          ,it_tax_code                  => lt_tax_code                  -- 税区分
--          ,it_slip_number               => lt_slip_number               -- 伝票番号
--          ,it_dept_base                 => lt_dept_base                 -- 起票部門
--          ,it_sales_staff_code          => lt_sales_staff_code          -- 伝票入力者
--          ,it_supplier_code_before      => lt_supplier_code_before      -- 仕入先コード
--          ,it_supplier_site_code_before => lt_supplier_site_code_before -- 仕入先サイトコード
--          ,it_cust_code_before          => lt_cust_code_before          -- 顧客コード
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--      -- ====================================================
--      -- 2. 銀行手数料負担者が相手先の場合
--      -- ====================================================
--      ELSE
--        -- ====================================================
--        -- 消費税額（借方）
--        -- ====================================================
--        lt_department  := gv_aff2_dept_fin;               -- 財務経理部
--        lt_account     := gv_aff3_payment_excise_tax;     -- 仮払消費税等
--        lt_sub_account := gv_aff4_subacct_dummy;          -- ダミー値
--        lt_entered_dr  := ( in_bm_sum_amt_tax_before      -- 販手消費税額 + 電気料消費税額 - 振込手数料消費税額
--                          + in_electric_sum_tax_before
--                          - in_bank_sales_tax          ); -- 消費税額
--        lt_entered_cr  := NULL;                           -- 貸方金額
--        -- ====================================================
--        -- GLインタフェース登録
--        -- ====================================================
--        insert_interface_info(
--           ov_errbuf                    => lv_errbuf                    -- エラー・メッセージ
--          ,ov_retcode                   => lv_retcode                   -- リターン・コード
--          ,ov_errmsg                    => lv_errmsg                    -- ユーザー・エラー・メッセージ
--          ,it_entered_dr                => lt_entered_dr                -- 借方金額
--          ,it_entered_cr                => lt_entered_cr                -- 貸方金額
--          ,it_department                => lt_department                -- 部門
--          ,it_account                   => lt_account                   -- 勘定科目
--          ,it_sub_account               => lt_sub_account               -- 補助科目
--          ,it_accounting_date           => lt_accounting_date           -- 仕訳有効日付
--          ,it_currency_code             => lt_currency_code             -- 通貨コード
--          ,it_customer_code             => lt_customer_code             -- 顧客コード
--          ,it_corp_code                 => lt_corp_code                 -- 企業コード
--          ,it_gl_name                   => lt_gl_name                   -- 仕訳名
--          ,it_period_name               => lt_period_name               -- 会計期間名
--          ,it_tax_code                  => lt_tax_code                  -- 税区分
--          ,it_slip_number               => lt_slip_number               -- 伝票番号
--          ,it_dept_base                 => lt_dept_base                 -- 起票部門
--          ,it_sales_staff_code          => lt_sales_staff_code          -- 伝票入力者
--          ,it_supplier_code_before      => lt_supplier_code_before      -- 仕入先コード
--          ,it_supplier_site_code_before => lt_supplier_site_code_before -- 仕入先サイトコード
--          ,it_cust_code_before          => lt_cust_code_before          -- 顧客コード
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- ====================================================
--        -- 振込額（貸方）
--        -- ====================================================
--        lt_department  := gv_aff2_dept_fin;               -- 財務経理部
--        lt_account     := gv_aff3_current_account;        -- 当座預金
--        lt_sub_account := gv_aff4_current_account_our;    -- 当社口座
--        lt_entered_dr  := NULL;                           -- 借方金額
--        lt_entered_cr  := ( in_payment_sum_amt_before     -- 振込額 - 振込手数料 - 振込手数料消費税額
--                          - in_payment_chrg_amt
--                          - in_bank_sales_tax         );  -- 振込額
--        -- ====================================================
--        -- GLインタフェース登録
--        -- ====================================================
--        insert_interface_info(
--           ov_errbuf                    => lv_errbuf                    -- エラー・メッセージ
--          ,ov_retcode                   => lv_retcode                   -- リターン・コード
--          ,ov_errmsg                    => lv_errmsg                    -- ユーザー・エラー・メッセージ
--          ,it_entered_dr                => lt_entered_dr                -- 借方金額
--          ,it_entered_cr                => lt_entered_cr                -- 貸方金額
--          ,it_department                => lt_department                -- 部門
--          ,it_account                   => lt_account                   -- 勘定科目
--          ,it_sub_account               => lt_sub_account               -- 補助科目
--          ,it_accounting_date           => lt_accounting_date           -- 仕訳有効日付
--          ,it_currency_code             => lt_currency_code             -- 通貨コード
--          ,it_customer_code             => lt_customer_code             -- 顧客コード
--          ,it_corp_code                 => lt_corp_code                 -- 企業コード
--          ,it_gl_name                   => lt_gl_name                   -- 仕訳名
--          ,it_period_name               => lt_period_name               -- 会計期間名
--          ,it_tax_code                  => lt_tax_code                  -- 税区分
--          ,it_slip_number               => lt_slip_number               -- 伝票番号
--          ,it_dept_base                 => lt_dept_base                 -- 起票部門
--          ,it_sales_staff_code          => lt_sales_staff_code          -- 伝票入力者
--          ,it_supplier_code_before      => lt_supplier_code_before      -- 仕入先コード
--          ,it_supplier_site_code_before => lt_supplier_site_code_before -- 仕入先サイトコード
--          ,it_cust_code_before          => lt_cust_code_before          -- 顧客コード
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- ====================================================
--        -- 振込手数料（貸方）
--        -- ====================================================
--        IF (in_payment_chrg_amt > 0) THEN
--          lt_department  := gv_aff2_dept_fin;             -- 財務経理部
--          lt_account     := gv_aff3_fee;                  -- 手数料
--          lt_sub_account := gv_aff4_transfer_fee;         -- 振込手数料
--          lt_entered_dr  := NULL;                         -- 借方金額
--          lt_entered_cr  := in_payment_chrg_amt;          -- 振込手数料額
--          -- ====================================================
--          -- GLインタフェース登録
--          -- ====================================================
--          insert_interface_info(
--             ov_errbuf                    => lv_errbuf                    -- エラー・メッセージ
--            ,ov_retcode                   => lv_retcode                   -- リターン・コード
--            ,ov_errmsg                    => lv_errmsg                    -- ユーザー・エラー・メッセージ
--            ,it_entered_dr                => lt_entered_dr                -- 借方金額
--            ,it_entered_cr                => lt_entered_cr                -- 貸方金額
--            ,it_department                => lt_department                -- 部門
--            ,it_account                   => lt_account                   -- 勘定科目
--            ,it_sub_account               => lt_sub_account               -- 補助科目
--            ,it_accounting_date           => lt_accounting_date           -- 仕訳有効日付
--            ,it_currency_code             => lt_currency_code             -- 通貨コード
---- Start 2009/05/13 Ver_1.2 T1_0867 M.Hiruta
----            ,it_customer_code             => lt_customer_code             -- 顧客コード
----            ,it_corp_code                 => lt_corp_code                 -- 企業コード
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----            ,it_customer_code             => g_gl_interface_rec.cust_code -- 顧客コード
--            ,it_customer_code             => lt_cust_code_vendor          -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--            ,it_corp_code                 => iv_corp_code                 -- 企業コード
---- End   2009/05/13 Ver_1.2 T1_0867 M.Hiruta
--            ,it_gl_name                   => lt_gl_name                   -- 仕訳名
--            ,it_period_name               => lt_period_name               -- 会計期間名
--            ,it_tax_code                  => lt_tax_code                  -- 税区分
--            ,it_slip_number               => lt_slip_number               -- 伝票番号
--            ,it_dept_base                 => lt_dept_base                 -- 起票部門
--            ,it_sales_staff_code          => lt_sales_staff_code          -- 伝票入力者
--            ,it_supplier_code_before      => lt_supplier_code_before      -- 仕入先コード
--            ,it_supplier_site_code_before => lt_supplier_site_code_before -- 仕入先サイトコード
--            ,it_cust_code_before          => lt_cust_code_before          -- 顧客コード
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
----
--        END IF;
----
--      END IF;
----
--    END IF;
----
--  EXCEPTION
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END set_insert_info;
----
--  /**********************************************************************************
--   * Procedure Name   : update_interface_info
--   * Description      : 連携結果の更新(A-6)
--   ***********************************************************************************/
--  PROCEDURE update_interface_info(
--     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ
--    ,ov_retcode    OUT VARCHAR2     --   リターン・コード
--    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name      CONSTANT VARCHAR2(30) := 'update_interface_info'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
--    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
--    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
--    lv_out_msg       VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
--    lb_retcode       BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力のリターン・コード
--    -- *** ローカルカーソル ***
--    CURSOR lock_cur
--    IS
--      SELECT 'X'
--      FROM xxcok_backmargin_balance xbb
--      WHERE xbb.base_code           = g_gl_interface_rec.base_code
--      AND   xbb.supplier_code       = g_gl_interface_rec.supplier_code
--      AND   xbb.supplier_site_code  = g_gl_interface_rec.supplier_site_code
--      AND   xbb.cust_code           = g_gl_interface_rec.cust_code
--      AND   xbb.fb_interface_status = cv_interface_status_fb
--      AND   xbb.gl_interface_status = cv_if_status_gl_before
--      FOR UPDATE OF xbb.bm_balance_id NOWAIT
--    ;
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- ====================================================
--    -- 1. 販手残高テーブルのロックを取得
--    -- ====================================================
--    OPEN  lock_cur;
--    CLOSE lock_cur;
----
--    -- ====================================================
--    -- 2. 対象データを連携済に更新
--    -- ====================================================
--    BEGIN
--      UPDATE xxcok_backmargin_balance
--      SET gl_interface_status    = cv_if_status_gl_after -- 連携ステータス（GL）
--         ,gl_interface_date      = gd_process_date       -- 連携日（GL）
--         ,last_updated_by        = cn_last_updated_by
--         ,last_update_date       = SYSDATE
--         ,last_update_login      = cn_last_update_login
--         ,request_id             = cn_request_id
--         ,program_application_id = cn_program_application_id
--         ,program_id             = cn_program_id
--         ,program_update_date    = SYSDATE
--      WHERE base_code           = g_gl_interface_rec.base_code
--      AND   supplier_code       = g_gl_interface_rec.supplier_code
--      AND   supplier_site_code  = g_gl_interface_rec.supplier_site_code
--      AND   cust_code           = g_gl_interface_rec.cust_code
--      AND   fb_interface_status = cv_interface_status_fb
--      AND   gl_interface_status = cv_if_status_gl_before
--      ;
----
--    EXCEPTION
--      --*** GL連携結果更新例外 ***
--      WHEN OTHERS THEN
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_app_name_cok
--                        ,iv_name         => cv_gl_if_update_err_msg
--                        ,iv_token_name1  => cv_dept_code_token
--                        ,iv_token_value1 => g_gl_interface_rec.base_code
--                        ,iv_token_name2  => cv_vend_code_token
--                        ,iv_token_value2 => g_gl_interface_rec.supplier_code
--                        ,iv_token_name3  => cv_vend_site_code_token
--                        ,iv_token_value3 => g_gl_interface_rec.supplier_site_code
--                        ,iv_token_name4  => cv_cust_code_token
--                        ,iv_token_value4 => g_gl_interface_rec.cust_code
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                         FND_FILE.OUTPUT
--                        ,lv_out_msg
--                        ,0
--                      );
--        ov_errmsg  := NULL;
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--        ov_retcode := cv_status_error;
----
--    END;
----
--  EXCEPTION
--    --*** GL連携結果更新ロック例外 ***
--    WHEN global_lock_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_name_cok
--                      ,iv_name         => cv_bm_balance_err_msg
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       FND_FILE.OUTPUT
--                      ,lv_out_msg
--                      ,0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
--  END update_interface_info;
----
--  /**********************************************************************************
--   * Procedure Name   : get_gl_interface
--   * Description      : GL連携データの取得(A-3)
--   ***********************************************************************************/
--  PROCEDURE get_gl_interface(
--     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ
--    ,ov_retcode    OUT VARCHAR2      --   リターン・コード
--    ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name   CONSTANT VARCHAR2(20) := 'get_gl_interface'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
--    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
--    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--    lv_out_msg                     VARCHAR2(2000) DEFAULT NULL;              -- 出力メッセージ
--    -- GL付加情報
--    lb_retcode                     BOOLEAN        DEFAULT TRUE;              -- メッセージ出力のリターン・コード
--    lv_sales_staff_code            VARCHAR2(10)   DEFAULT NULL;              -- 営業担当者コード
--    lv_corp_code                   VARCHAR2(10)   DEFAULT NULL;              -- 企業コード
--    lv_period_name                 VARCHAR2(15)   DEFAULT NULL;              -- 会計期間名
--    lv_slip_number                 VARCHAR2(20)   DEFAULT NULL;              -- 伝票番号
--    ln_payment_chrg_amt            NUMBER         DEFAULT NULL;              -- 振込手数料額
--    ln_bank_sales_tax              NUMBER         DEFAULT NULL;              -- 振込手数料税額
--    -- フラグ
--    lv_gl_add_info_flag            VARCHAR2(1)    DEFAULT NULL;              -- 付加情報取得フラグ(伝票単位)
--    lv_bank_charge_flag            VARCHAR2(1)    DEFAULT NULL;              -- 銀行手数料設定フラグ(仕入先単位)
--    lv_insert_flag                 VARCHAR2(1)    DEFAULT NULL;              -- GLインタフェース登録フラグ
--    -- 累計データ
--    ln_bm_sum_amt_tax_before       NUMBER         DEFAULT 0;                 -- 販売手数料消費税額合計
--    ln_electric_sum_tax_before     NUMBER         DEFAULT 0;                 -- 電気料消費税額合計
--    ln_payment_sum_amt_before      NUMBER         DEFAULT 0;                 -- 振込額
--    -- 仕入先単位で取得したデータ
--    lt_base_code_vendor            xxcok_backmargin_balance.base_code%TYPE           DEFAULT NULL; -- 拠点コード
--    lt_supplier_code_vendor        xxcok_backmargin_balance.supplier_code%TYPE       DEFAULT NULL; -- 仕入先コード
--    lt_supplier_site_code_vendor   xxcok_backmargin_balance.supplier_site_code%TYPE  DEFAULT NULL; -- 仕入先サイトコード
--    ln_bank_chrg_amt_vendor        NUMBER                                            DEFAULT NULL; -- 振込手数料額
--    ln_bank_sales_tax_vendor       NUMBER                                            DEFAULT NULL; -- 振込手数料税額
--    -- 伝票単位で取得したデータ
--    lt_base_code_slip              xxcok_backmargin_balance.base_code%TYPE           DEFAULT NULL; -- 拠点コード
--    lt_supplier_code_slip          xxcok_backmargin_balance.supplier_code%TYPE       DEFAULT NULL; -- 仕入先コード
--    lt_supplier_site_code_slip     xxcok_backmargin_balance.supplier_site_code%TYPE  DEFAULT NULL; -- 仕入先サイトコード
--    ln_bank_chrg_amt_slip          NUMBER                                            DEFAULT NULL; -- 振込手数料額
--    ln_bank_sales_tax_slip         NUMBER                                            DEFAULT NULL; -- 振込手数料税額
--    -- 販売手数料データ
--    lv_slip_number_before          VARCHAR2(20)                                      DEFAULT NULL; -- 伝票番号
--    ln_payment_chrg_amt_before     NUMBER                                            DEFAULT NULL; -- 振込手数料額
--    ln_bank_sales_tax_before       NUMBER                                            DEFAULT NULL; -- 振込手数料税額
--    lt_base_code_before            xxcok_backmargin_balance.base_code%TYPE           DEFAULT NULL; -- 拠点コード
--    lt_supplier_code_before        xxcok_backmargin_balance.supplier_code%TYPE       DEFAULT NULL; -- 仕入先コード
--    lt_supplier_site_code_before   xxcok_backmargin_balance.supplier_site_code%TYPE  DEFAULT NULL; -- 仕入先サイトコード
--    lt_cust_code_before            xxcok_backmargin_balance.cust_code%TYPE           DEFAULT NULL; -- 顧客コード
--    lt_tax_code_before             xxcok_backmargin_balance.tax_code%TYPE            DEFAULT NULL; -- 税金コード
--    lt_expect_payment_date_before  xxcok_backmargin_balance.expect_payment_date%TYPE DEFAULT NULL; -- 支払予定日
--    lt_bank_charge_bearer_before   po_vendor_sites_all.bank_charge_bearer%TYPE       DEFAULT NULL; -- 銀行手数料負担者
--    lt_payment_currency_before     po_vendor_sites_all.payment_currency_code%TYPE    DEFAULT NULL; -- 支払通貨
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--    lt_cust_code_vendor            xxcok_backmargin_balance.cust_code%TYPE           DEFAULT NULL; -- 顧客コード
--    lt_cust_code_slip              xxcok_backmargin_balance.cust_code%TYPE           DEFAULT NULL; -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- ====================================================
--    -- 1件目のGL連携データ取得
--    -- ====================================================
--    OPEN  gl_interface_cur;
--    FETCH gl_interface_cur INTO g_gl_interface_rec;
----
--    -- ====================================================
--    -- 振込手数料仕訳作成用のデータを保持する
--    -- ====================================================
--    lt_base_code_before          := g_gl_interface_rec.base_code;          -- 拠点コード
--    lt_supplier_code_before      := g_gl_interface_rec.supplier_code;      -- 仕入先コード
--    lt_supplier_site_code_before := g_gl_interface_rec.supplier_site_code; -- 仕入先サイトコード
----
--    -- ====================================================
--    -- 付加情報取得フラグ設定（伝票単位取得する）
--    -- 銀行手数料設定フラグ設定（仕入先単位取得する）
--    -- GLインタフェース登録フラグ設定（自販機販売手数料仕訳）
--    -- ====================================================
--    lv_gl_add_info_flag        := cv_gl_add_info_y;
--    lv_bank_charge_flag        := cv_bank_charge_y;
--    lv_insert_flag             := cv_vend_sales;
----
--    <<g_gl_interface_loop>>
--    LOOP
--      EXIT WHEN gl_interface_cur%NOTFOUND;
--      -- ====================================================
--      -- 拠点コードまたは仕入先コードが一致した場合
--      -- ====================================================
--      IF(  ( lt_base_code_before     = g_gl_interface_rec.base_code )
--        AND( lt_supplier_code_before = g_gl_interface_rec.supplier_code ) )
--      THEN
--        -- 対象件数
--        gn_target_cnt := gn_target_cnt + 1;
--        -- ====================================================
--        -- A-4. GL連携データ付加情報の取得
--        -- ====================================================
--        get_interface_add_info(
--           ov_errbuf                    =>   lv_errbuf                    -- エラー・メッセージ
--          ,ov_retcode                   =>   lv_retcode                   -- リターン・コード
--          ,ov_errmsg                    =>   lv_errmsg                    -- ユーザー・エラー・メッセージ
--          ,iv_gl_add_info_flag          =>   lv_gl_add_info_flag          -- GL付加情報フラグ
--          ,iv_bank_charge_flag          =>   lv_bank_charge_flag          -- 銀行手数料設定フラグ
--          ,it_base_code_slip            =>   lt_base_code_slip            -- 拠点コード
--          ,it_supplier_code_slip        =>   lt_supplier_code_slip        -- 仕入先コード
--          ,it_supplier_site_code_slip   =>   lt_supplier_site_code_slip   -- 仕入先サイトコード
--          ,in_bank_chrg_amt_slip        =>   ln_bank_chrg_amt_slip        -- 振込手数料額
--          ,in_bank_sales_tax_slip       =>   ln_bank_sales_tax_slip       -- 振込手数料税額
--          ,ov_sales_staff_code          =>   lv_sales_staff_code          -- 営業担当者コード
--          ,ov_corp_code                 =>   lv_corp_code                 -- 企業コード
--          ,ov_period_name               =>   lv_period_name               -- 会計期間名
--          ,ov_slip_number               =>   lv_slip_number               -- 伝票番号
--          ,on_payment_chrg_amt          =>   ln_payment_chrg_amt          -- 振込手数料額
--          ,on_bank_sales_tax            =>   ln_bank_sales_tax            -- 振込手数料税額
--          ,ot_base_code_vendor          =>   lt_base_code_vendor          -- 拠点コード
--          ,ot_supplier_code_vendor      =>   lt_supplier_code_vendor      -- 仕入先コード
--          ,ot_supplier_site_code_vendor =>   lt_supplier_site_code_vendor -- 仕入先サイトコード
--          ,on_bank_chrg_amt_vendor      =>   ln_bank_chrg_amt_vendor      -- 振込手数料額
--          ,on_bank_sales_tax_vendor     =>   ln_bank_sales_tax_vendor     -- 振込手数料税額
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--          ,ot_cust_code_vendor          =>   lt_cust_code_vendor          -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- ====================================================
--        -- 取得した付加情報を退避
--        -- ====================================================
--        -- ====================================================
--        -- GL付加情報フラグがYの場合
--        -- （拠点コードまたは仕入先コードが変わった場合）
--        -- ====================================================
--        IF( lv_gl_add_info_flag = cv_gl_add_info_y ) THEN
--          lv_slip_number_before       := lv_slip_number;               -- 伝票番号
--          ln_payment_chrg_amt_before  := ln_payment_chrg_amt;          -- 振込手数料額
--          ln_bank_sales_tax_before    := ln_bank_sales_tax;            -- 振込手数料税額
--        END IF;
----
--        -- ====================================================
--        -- 銀行手数料設定フラグがYの場合
--        -- （仕入先コードが変わった場合）
--        -- ====================================================
--        IF( lv_bank_charge_flag = cv_bank_charge_y ) THEN
--          lt_base_code_slip           := lt_base_code_vendor;          -- 拠点コード
--          lt_supplier_code_slip       := lt_supplier_code_vendor;      -- 仕入先コード
--          lt_supplier_site_code_slip  := lt_supplier_site_code_vendor; -- 仕入先サイトコード
--          ln_bank_chrg_amt_slip       := ln_bank_chrg_amt_vendor;      -- 振込手数料額
--          ln_bank_sales_tax_slip      := ln_bank_sales_tax_vendor;     -- 振込手数料税額
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--          lt_cust_code_slip           := lt_cust_code_vendor;          -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--        END IF;
----
--        -- ====================================================
--        -- A-5. GL連携データの登録（顧客毎）
--        -- ====================================================
--        lv_insert_flag := cv_vend_sales;
----
--        set_insert_info(
--           ov_errbuf                     =>  lv_errbuf                      -- エラー・メッセージ
--          ,ov_retcode                    =>  lv_retcode                     -- リターン・コード
--          ,ov_errmsg                     =>  lv_errmsg                      -- ユーザー・エラー・メッセージ
--          ,iv_insert_flag                =>  lv_insert_flag                 -- GLインタフェース登録フラグ
--          ,it_base_code_before           =>  lt_base_code_before            -- 拠点コード
--          ,it_tax_code_before            =>  lt_tax_code_before             -- 税金コード
--          ,it_expect_payment_date_before =>  lt_expect_payment_date_before  -- 支払日
--          ,it_bank_charge_bearer_before  =>  lt_bank_charge_bearer_before   -- 銀行手数料負担者
--          ,it_payment_currency_before    =>  lt_payment_currency_before     -- 支払通貨
--          ,it_supplier_code_before       =>  lt_supplier_code_before        -- 仕入先コード
--          ,it_supplier_site_code_before  =>  lt_supplier_site_code_before   -- 仕入先サイトコード
--          ,it_cust_code_before           =>  lt_cust_code_before            -- 顧客コード
--          ,iv_corp_code                  =>  lv_corp_code                   -- 企業コード
--          ,in_bm_sum_amt_tax_before      =>  ln_bm_sum_amt_tax_before       -- 販売手数料消費税額合計
--          ,in_electric_sum_tax_before    =>  ln_electric_sum_tax_before     -- 電気料消費税額合計
--          ,in_payment_sum_amt_before     =>  ln_payment_sum_amt_before      -- 振込額合計
--          ,iv_sales_staff_code           =>  lv_sales_staff_code            -- 営業担当者コード
--          ,iv_period_name                =>  lv_period_name                 -- 会計期間名
--          ,iv_slip_number                =>  lv_slip_number_before          -- 伝票番号
--          ,in_payment_chrg_amt           =>  ln_payment_chrg_amt_before     -- 振込手数料額
--          ,in_bank_sales_tax             =>  ln_bank_sales_tax_before       -- 振込手数料税額
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- ====================================================
--        -- A-6. 連携結果の更新
--        -- ====================================================
--        update_interface_info(
--           ov_errbuf     =>   lv_errbuf    -- エラー・メッセージ
--          ,ov_retcode    =>   lv_retcode   -- リターン・コード
--          ,ov_errmsg     =>   lv_errmsg    -- ユーザー・エラー・メッセージ
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- 正常件数
--        gn_normal_cnt := gn_normal_cnt + 1;
----
--        -- ====================================================
--        -- 振込手数料仕訳作成用のデータを保持する
--        -- ====================================================
--        ln_bm_sum_amt_tax_before        := ln_bm_sum_amt_tax_before   + g_gl_interface_rec.backmargin_tax;
--        ln_electric_sum_tax_before      := ln_electric_sum_tax_before + g_gl_interface_rec.electric_amt_tax;
--        ln_payment_sum_amt_before       := ln_payment_sum_amt_before  + g_gl_interface_rec.amt_sum;
--        lt_tax_code_before              := g_gl_interface_rec.tax_code;
--        lt_expect_payment_date_before   := g_gl_interface_rec.expect_payment_date;
--        lt_bank_charge_bearer_before    := g_gl_interface_rec.bank_charge_bearer;
--        lt_payment_currency_before      := g_gl_interface_rec.payment_currency_code;
--        lt_cust_code_before             := g_gl_interface_rec.cust_code;
----
--        -- ====================================================
--        -- 付加情報フラグ設定（伝票単位取得しない）
--        -- 銀行手数料フラグ設定（仕入先単位取得しない）
--        -- ====================================================
--        lv_gl_add_info_flag             := cv_gl_add_info_n;
--        lv_bank_charge_flag             := cv_bank_charge_n;
----
--        -- ====================================================
--        -- 次レコード
--        -- ====================================================
--        FETCH gl_interface_cur INTO g_gl_interface_rec;
----
--      -- ====================================================
--      -- 拠点コードまたは仕入先コードが変わった場合
--      -- ====================================================
--      ELSE
--        -- ====================================================
--        -- 仕入先コードが変わった場合
--        -- 銀行手数料フラグ設定（仕入先単位データ取得する）
--        -- ====================================================
--        IF( lt_supplier_code_before <> g_gl_interface_rec.supplier_code ) THEN
--          lv_bank_charge_flag    := cv_bank_charge_y;
--        END IF;
----
--        -- ====================================================
--        -- A-5. GL連携データの登録（手数料）
--        -- ====================================================
--        lv_insert_flag := cv_backmargin;
----
--        set_insert_info(
--           ov_errbuf                     =>  lv_errbuf                      -- エラー・メッセージ
--          ,ov_retcode                    =>  lv_retcode                     -- リターン・コード
--          ,ov_errmsg                     =>  lv_errmsg                      -- ユーザー・エラー・メッセージ
--          ,iv_insert_flag                =>  lv_insert_flag                 -- GLインタフェース登録フラグ
--          ,it_base_code_before           =>  lt_base_code_before            -- 拠点コード
--          ,it_tax_code_before            =>  lt_tax_code_before             -- 税金コード
--          ,it_expect_payment_date_before =>  lt_expect_payment_date_before  -- 支払日
--          ,it_bank_charge_bearer_before  =>  lt_bank_charge_bearer_before   -- 銀行手数料負担者
--          ,it_payment_currency_before    =>  lt_payment_currency_before     -- 支払通貨
--          ,it_supplier_code_before       =>  lt_supplier_code_before        -- 仕入先コード
--          ,it_supplier_site_code_before  =>  lt_supplier_site_code_before   -- 仕入先サイトコード
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----          ,it_cust_code_before           =>  lt_cust_code_before            -- 顧客コード
--          ,it_cust_code_before           =>  lt_cust_code_slip              -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--          ,iv_corp_code                  =>  lv_corp_code                   -- 企業コード
--          ,in_bm_sum_amt_tax_before      =>  ln_bm_sum_amt_tax_before       -- 販売手数料消費税額合計
--          ,in_electric_sum_tax_before    =>  ln_electric_sum_tax_before     -- 電気料消費税額合計
--          ,in_payment_sum_amt_before     =>  ln_payment_sum_amt_before      -- 振込額合計
--          ,iv_sales_staff_code           =>  lv_sales_staff_code            -- 営業担当者コード
--          ,iv_period_name                =>  lv_period_name                 -- 会計期間名
--          ,iv_slip_number                =>  lv_slip_number_before          -- 伝票番号
--          ,in_payment_chrg_amt           =>  ln_payment_chrg_amt_before     -- 振込手数料額
--          ,in_bank_sales_tax             =>  ln_bank_sales_tax_before       -- 振込手数料税額
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- ====================================================
--        -- 振込手数料仕訳作成用のデータを保持する
--        -- ====================================================
--        lt_base_code_before          := g_gl_interface_rec.base_code;          -- 拠点コード
--        lt_supplier_code_before      := g_gl_interface_rec.supplier_code;      -- 仕入先コード
--        lt_supplier_site_code_before := g_gl_interface_rec.supplier_site_code; -- 仕入先サイトコード
----
--        -- ====================================================
--        -- 累計データリセット
--        -- ====================================================
--        ln_bm_sum_amt_tax_before   := 0;    -- 販売手数料消費税額合計
--        ln_electric_sum_tax_before := 0;    -- 電気料消費税額合計
--        ln_payment_sum_amt_before  := 0;    -- 振込額
----
--        -- ====================================================
--        -- 付加情報取得フラグ（伝票単位データ取得する）
--        -- ====================================================
--        lv_gl_add_info_flag      := cv_gl_add_info_y;
----
--      END IF;
----
--    END LOOP g_gl_interface_loop;
--    -- ====================================================
--    -- GL連携情報が1件も取得できなかった場合
--    -- ====================================================
--    IF( gn_target_cnt = 0 ) THEN
--      RAISE global_nodata_expt;
--    END IF;
----
--    CLOSE gl_interface_cur;
--    -- ====================================================
--    -- A-5. GL連携データの登録
--    -- ====================================================
--    lv_insert_flag := cv_backmargin;
----
--    set_insert_info(
--       ov_errbuf                     =>  lv_errbuf                      -- エラー・メッセージ
--      ,ov_retcode                    =>  lv_retcode                     -- リターン・コード
--      ,ov_errmsg                     =>  lv_errmsg                      -- ユーザー・エラー・メッセージ
--      ,iv_insert_flag                =>  lv_insert_flag                 -- GLインタフェース登録フラグ
--      ,it_base_code_before           =>  lt_base_code_before            -- 拠点コード
--      ,it_tax_code_before            =>  lt_tax_code_before             -- 税金コード
--      ,it_expect_payment_date_before =>  lt_expect_payment_date_before  -- 支払日
--      ,it_bank_charge_bearer_before  =>  lt_bank_charge_bearer_before   -- 銀行手数料負担者
--      ,it_payment_currency_before    =>  lt_payment_currency_before     -- 支払通貨
--      ,it_supplier_code_before       =>  lt_supplier_code_before        -- 仕入先コード
--      ,it_supplier_site_code_before  =>  lt_supplier_site_code_before   -- 仕入先サイトコード
---- Start 2009/05/25 Ver_1.3 T1_1166 M.Hiruta
----      ,it_cust_code_before           =>  lt_cust_code_before            -- 顧客コード
--      ,it_cust_code_before           =>  lt_cust_code_slip              -- 顧客コード
---- End   2009/05/25 Ver_1.3 T1_1166 M.Hiruta
--      ,iv_corp_code                  =>  lv_corp_code                   -- 企業コード
--      ,in_bm_sum_amt_tax_before      =>  ln_bm_sum_amt_tax_before       -- 販売手数料消費税額合計
--      ,in_electric_sum_tax_before    =>  ln_electric_sum_tax_before     -- 電気料消費税額合計
--      ,in_payment_sum_amt_before     =>  ln_payment_sum_amt_before      -- 振込額合計
--      ,iv_sales_staff_code           =>  lv_sales_staff_code            -- 営業担当者コード
--      ,iv_period_name                =>  lv_period_name                 -- 会計期間名
--      ,iv_slip_number                =>  lv_slip_number_before          -- 伝票番号
--      ,in_payment_chrg_amt           =>  ln_payment_chrg_amt_before     -- 振込手数料額
--      ,in_bank_sales_tax             =>  ln_bank_sales_tax_before       -- 振込手数料税額
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
----
--  EXCEPTION
--    --*** GL連携データ取得例外 ***
--    WHEN global_nodata_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_name_cok
--                      ,iv_name         => cv_gl_info_err_msg
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       FND_FILE.OUTPUT
--                      ,lv_out_msg
--                      ,0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR START
----      ov_retcode := cv_status_error;
--      ov_retcode := cv_status_normal;
---- 2009/09/09 Ver.1.4 [障害0001327] SCS K.Yamaguchi REPAIR END
--      CLOSE gl_interface_cur;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--      CLOSE gl_interface_cur;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--      CLOSE gl_interface_cur;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--      CLOSE gl_interface_cur;
----
--  END get_gl_interface;
----
--  /**********************************************************************************
--   * Procedure Name   : submain
--   * Description      : メイン処理プロシージャ
--   **********************************************************************************/
--  PROCEDURE submain(
--     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ
--    ,ov_retcode    OUT VARCHAR2      --   リターン・コード
--    ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name   CONSTANT VARCHAR2(20) := 'submain';          -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf     VARCHAR2(5000)  DEFAULT NULL;                -- エラー・メッセージ
--    lv_retcode    VARCHAR2(1)     DEFAULT cv_status_normal;    -- リターン・コード
--    lv_errmsg     VARCHAR2(5000)  DEFAULT NULL;                -- ユーザー・エラー・メッセージ
--    lv_out_msg    VARCHAR2(2000)  DEFAULT NULL;                -- 出力メッセージ
--    lb_retcode    BOOLEAN         DEFAULT TRUE;                -- メッセージ出力のリターン・コード
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- ====================================================
--    -- グローバル変数の初期化
--    -- ====================================================
--    gn_target_cnt := 0;
--    gn_normal_cnt := 0;
--    gn_error_cnt  := 0;
--    -- ====================================================
--    -- A-1. 初期処理
--    -- ====================================================
--    init(
--       ov_errbuf    =>   lv_errbuf        -- エラー・メッセージ
--      ,ov_retcode   =>   lv_retcode       -- リターン・コード
--      ,ov_errmsg    =>   lv_errmsg        -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
----
--    -- ====================================================
--    -- A-2. 妥当性チェック処理
--    -- ====================================================
--    check_acctg_period(
--       ov_errbuf    =>   lv_errbuf        -- エラー・メッセージ
--      ,ov_retcode   =>   lv_retcode       -- リターン・コード
--      ,ov_errmsg    =>   lv_errmsg        -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
----
--    -- ====================================================
--    -- A-3. GL連携データの取得
--    -- ====================================================
--    get_gl_interface(
--       ov_errbuf    =>   lv_errbuf        -- エラー・メッセージ
--      ,ov_retcode   =>   lv_retcode       -- リターン・コード
--      ,ov_errmsg    =>   lv_errmsg        -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
----
--  EXCEPTION
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END submain;
----
--  /**********************************************************************************
--   * Procedure Name   : main
--   * Description      : コンカレント実行ファイル登録プロシージャ
--   **********************************************************************************/
----
--  PROCEDURE main(
--     errbuf        OUT VARCHAR2       --   エラー・メッセージ
--    ,retcode       OUT VARCHAR2       --   リターン・コード
--  )
--  IS
----
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name       CONSTANT VARCHAR2(5) := 'main';            -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf         VARCHAR2(5000)  DEFAULT NULL;              -- エラー・メッセージ
--    lv_retcode        VARCHAR2(1)     DEFAULT cv_status_normal;  -- リターン・コード
--    lv_errmsg         VARCHAR2(5000)  DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--    lv_out_msg        VARCHAR2(2000)  DEFAULT NULL;              -- 出力メッセージ
--    lv_message_code   VARCHAR2(20)    DEFAULT NULL;              -- 終了メッセージ
--    lb_retcode        BOOLEAN         DEFAULT TRUE;              -- メッセージ出力のリターン・コード
----
--  BEGIN
----
--    -- ====================================================
--    -- コンカレントヘッダメッセージ出力関数の呼び出し
--    -- ====================================================
--    xxccp_common_pkg.put_log_header(
--       ov_retcode => lv_retcode
--      ,ov_errbuf  => lv_errbuf
--      ,ov_errmsg  => lv_errmsg
--    );
----
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_api_expt;
--    END IF;
----
--    -- ====================================================
--    -- submainの呼び出し（実際の処理はsubmainで行う）
--    -- ====================================================
--    submain(
--       ov_errbuf    =>  lv_errbuf   -- エラー・メッセージ
--      ,ov_retcode   =>  lv_retcode  -- リターン・コード
--      ,ov_errmsg    =>  lv_errmsg   -- ユーザー・エラー・メッセージ
--    );
----
--    -- ====================================================
--    -- エラー出力
--    -- ====================================================
--    IF( lv_retcode = cv_status_error ) THEN
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       FND_FILE.OUTPUT
--                      ,lv_errmsg
--                      ,1
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       FND_FILE.LOG
--                      ,lv_errbuf
--                      ,1
--                    );
--    END IF;
----
--    -- ====================================================
--    -- 異常終了の場合の件数セット
--    -- ====================================================
--    IF( lv_retcode = cv_status_error ) THEN
--      gn_target_cnt := 0;
--      gn_normal_cnt := 0;
--      gn_error_cnt  := 1;
--    END IF;
--    -- ====================================================
--    -- 対象件数出力
--    -- ====================================================
--    lv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name_ccp
--                    ,iv_name         => cv_target_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
--                   );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                     FND_FILE.OUTPUT
--                    ,lv_out_msg
--                    ,0
--                  );
----
--    -- ====================================================
--    -- 成功件数出力
--    -- ====================================================
--    lv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name_ccp
--                    ,iv_name         => cv_success_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
--                   );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                     FND_FILE.OUTPUT
--                    ,lv_out_msg
--                    ,0
--                  );
----
--    -- ====================================================
--    -- エラー件数出力
--    -- ====================================================
--    lv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name_ccp
--                    ,iv_name         => cv_error_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
--                   );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                     FND_FILE.OUTPUT
--                    ,lv_out_msg
--                    ,1
--                  );
----
--    -- ====================================================
--    -- 終了メッセージ
--    -- ====================================================
--    IF( lv_retcode = cv_status_normal ) THEN
--      lv_message_code := cv_normal_msg;
--    ELSIF( lv_retcode = cv_status_error ) THEN
--      lv_message_code := cv_error_msg;
--    END IF;
----
--    lv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name_ccp
--                    ,iv_name         => lv_message_code
--                   );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                     FND_FILE.OUTPUT
--                    ,lv_out_msg
--                    ,0
--                  );
--    -- ====================================================
--    -- ステータスセット
--    -- ====================================================
--    retcode := lv_retcode;
--    -- ====================================================
--    -- 終了ステータスがエラーの場合はROLLBACKする
--    -- ====================================================
--    IF( retcode = cv_status_error ) THEN
--      ROLLBACK;
--    END IF;
----
--  EXCEPTION
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      retcode := cv_status_error;
--      ROLLBACK;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      retcode := cv_status_error;
--      ROLLBACK;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      retcode := cv_status_error;
--      ROLLBACK;
----
--  END main;
----
  --==================================================
  -- グローバル定数
  --==================================================
  -- パッケージ名
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK017A01C';
  -- アプリケーション短縮名
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  cv_appl_short_name_gl            CONSTANT VARCHAR2(10)    := 'SQLGL';
  -- ステータス・コード
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- 言語
  cv_lang                          CONSTANT VARCHAR2(50)    := USERENV( 'LANG' );
  -- メッセージコード
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- 対象件数
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- 成功件数
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- エラー件数
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';        -- エラー件数
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- 正常終了
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- 警告終了
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- エラー終了全ロールバック
  cv_msg_ccp_90008                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90008';        -- コンカレント入力パラメータなし
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00011                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00011';
  cv_msg_cok_00024                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00024';
  cv_msg_cok_00025                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00025';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00042                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00042';
  cv_msg_cok_00053                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00053';
  -- トークン
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';                 -- 件数メッセージ用トークン名
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';               -- プロファイル名
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';             -- 処理日
  cv_tkn_dept_code                 CONSTANT VARCHAR2(30)    := 'DEPT_CODE';             -- 拠点コード
  cv_tkn_vend_code                 CONSTANT VARCHAR2(30)    := 'VEND_CODE';             -- 仕入先コード
  cv_tkn_vend_site_code            CONSTANT VARCHAR2(30)    := 'VEND_SITE_CODE';        -- 仕入先サイトコード
  cv_tkn_cust_code                 CONSTANT VARCHAR2(30)    := 'CUST_CODE';             -- 顧客コード
  cv_tkn_pay_date                  CONSTANT VARCHAR2(30)    := 'PAY_DATE';              -- 支払日
  -- セパレータ
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- プロファイル・オプション名
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'ORG_ID';                              -- MO: 営業単位
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                    -- 会計帳簿ID
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_NAME';                  -- 会計帳簿名
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF1_COMPANY_CODE';            -- 会社コード
  cv_profile_name_05               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF2_DEPT_FIN';                -- 部門コード_財務経理部
  cv_profile_name_06               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF3_CURRENT_ACCOUNT';         -- 勘定科目_当座預金
  cv_profile_name_07               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF3_FEE';                     -- 勘定科目_手数料
  cv_profile_name_08               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF3_PAYMENT_EXCISE_TAX';      -- 勘定科目_仮払消費税
  cv_profile_name_09               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF3_VEND_SALES_COMMISSION';   -- 勘定科目_自販機販売手数料
  cv_profile_name_10               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF4_SUBACCT_DUMMY';           -- 補助科目_ダミー値
  cv_profile_name_11               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF4_TRANSFER_FEE';            -- 補助科目_手数料_振込手数料
  cv_profile_name_12               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF4_VEND_SALES_ELEC_COST';    -- 補助科目_自販機販売手数料_自販電気料
  cv_profile_name_13               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF4_VEND_SALES_REBATE';       -- 補助科目_自販機販売手数料_自販リベート
  cv_profile_name_14               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF4_CURRENT_ACCOUNT_OUR';     -- 補助科目_当座預金_当社口座
  cv_profile_name_15               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF5_CUSTOMER_DUMMY';          -- 顧客コード_ダミー値
  cv_profile_name_16               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF6_COMPANY_DUMMY';           -- 企業コード_ダミー値
  cv_profile_name_17               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';      -- 予備コード１_ダミー値
  cv_profile_name_18               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';      -- 予備コード２_ダミー値
  cv_profile_name_19               CONSTANT VARCHAR2(50)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';      -- 銀行手数料_基準額未満
  cv_profile_name_20               CONSTANT VARCHAR2(50)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';      -- 銀行手数料_基準額以上
  cv_profile_name_21               CONSTANT VARCHAR2(50)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION';     -- 銀行手数料_振込額基準
  cv_profile_name_22               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_TAX';                       -- 販売手数料_消費税率
  cv_profile_name_23               CONSTANT VARCHAR2(50)    := 'XXCOK1_FB_TERM_NAME';                 -- FB支払条件
  cv_profile_name_24               CONSTANT VARCHAR2(50)    := 'XXCOK1_GL_CATEGORY_BM';               -- 仕訳カテゴリ_販売手数料
  cv_profile_name_25               CONSTANT VARCHAR2(50)    := 'XXCOK1_GL_SOURCE_COK';                -- 仕訳ソース_個別開発
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi ADD START
  cv_profile_name_26               CONSTANT VARCHAR2(50)    := 'XXCOK1_PURCHASE_WITHIN_TAX_CODE';     -- 課税仕入内税消費税コード
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi ADD END
  -- 参照タイプ名
  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCMM_CHAIN_CODE';                    -- チェーン店コード
  -- 会計期間ステータス
  cv_closing_status_open           CONSTANT VARCHAR2(1)     := 'O'; -- オープン
  -- 有効フラグ
  cv_enable                        CONSTANT VARCHAR2(1)     := 'Y'; -- 有効
  cv_disable                       CONSTANT VARCHAR2(1)     := 'N'; -- 無効
  -- BM支払区分
  cv_bm_type_1                     CONSTANT VARCHAR2(1)     := '1'; -- 本振（案内書あり）
  cv_bm_type_2                     CONSTANT VARCHAR2(1)     := '2'; -- 本振（案内書なし）
  -- 銀行手数料負担者
  cv_chrg_flag_i                   CONSTANT VARCHAR2(1)     := 'I'; -- 当方負担
  -- 連携ステータス（本振用FB）
  cv_interface_status_fb           CONSTANT VARCHAR2(1)     := '1'; -- 処理済
  -- 連携ステータス（GL）
  cv_gl_if_status_before           CONSTANT VARCHAR2(1)     := '0'; -- 未処理
  cv_gl_if_status_after            CONSTANT VARCHAR2(1)     := '1'; -- 処理済
  -- 仕訳ステータス
  cv_je_status_new                 CONSTANT VARCHAR2(3)     := 'NEW'; -- 新規
  -- 残高タイプ
  cv_balance_type_result           CONSTANT VARCHAR2(1)     := 'A'; -- 実績
  --==================================================
  -- グローバル変数
  --==================================================
  -- カウンタ
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- 対象件数
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- 正常件数
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- 異常件数
  gn_skip_cnt                      NUMBER        DEFAULT 0;      -- スキップ件数
  gn_contract_err_cnt              NUMBER        DEFAULT 0;      -- 販手条件エラー件数
  -- 初期処理取得値
  gd_process_date                  DATE          DEFAULT NULL;   -- 業務処理日付
  gn_prof_org_id                   NUMBER        DEFAULT NULL;   -- 営業単位ID
  gn_prof_set_of_books_id          NUMBER        DEFAULT NULL;   -- 会計帳簿ID
  gv_prof_set_of_books_name        VARCHAR2(100) DEFAULT NULL;   -- 会計帳簿名
  gv_prof_aff1_company_code        VARCHAR2(100) DEFAULT NULL;   -- 会社コード
  gv_prof_aff2_dept_fin            VARCHAR2(100) DEFAULT NULL;   -- 部門コード_財務経理部
  gv_prof_aff3_current_account     VARCHAR2(100) DEFAULT NULL;   -- 勘定科目_当座預金
  gv_prof_aff3_fee                 VARCHAR2(100) DEFAULT NULL;   -- 勘定科目_手数料
  gv_prof_aff3_tax                 VARCHAR2(100) DEFAULT NULL;   -- 勘定科目_仮払消費税
  gv_prof_aff3_bm                  VARCHAR2(100) DEFAULT NULL;   -- 勘定科目_自販機販売手数料
  gv_prof_aff4_dummy               VARCHAR2(100) DEFAULT NULL;   -- 補助科目_ダミー値
  gv_prof_aff4_transfer_fee        VARCHAR2(100) DEFAULT NULL;   -- 補助科目_手数料_振込手数料
  gv_prof_aff4_elec_cost           VARCHAR2(100) DEFAULT NULL;   -- 補助科目_自販機販売手数料_自販電気料
  gv_prof_aff4_rebate              VARCHAR2(100) DEFAULT NULL;   -- 補助科目_自販機販売手数料_自販リベート
  gv_prof_aff4_company_account     VARCHAR2(100) DEFAULT NULL;   -- 補助科目_当座預金_当社口座
  gv_prof_aff5_dummy               VARCHAR2(100) DEFAULT NULL;   -- 顧客コード_ダミー値
  gv_prof_aff6_dummy               VARCHAR2(100) DEFAULT NULL;   -- 企業コード_ダミー値
  gv_prof_aff7_dummy               VARCHAR2(100) DEFAULT NULL;   -- 予備コード１_ダミー値
  gv_prof_aff8_dummy               VARCHAR2(100) DEFAULT NULL;   -- 予備コード２_ダミー値
  gn_prof_bank_fee_less            NUMBER        DEFAULT NULL;   -- 銀行手数料_基準額未満
  gn_prof_bank_fee_more            NUMBER        DEFAULT NULL;   -- 銀行手数料_基準額以上
  gn_prof_bank_fee_standard        NUMBER        DEFAULT NULL;   -- 銀行手数料_振込額基準
  gn_prof_bm_tax_rate              NUMBER        DEFAULT NULL;   -- 販売手数料_消費税率
  gv_prof_fb_term_name             VARCHAR2(100) DEFAULT NULL;   -- FB支払条件
  gv_prof_gl_category_bm           VARCHAR2(100) DEFAULT NULL;   -- 仕訳カテゴリ_販売手数料
  gv_prof_gl_source_cok            VARCHAR2(100) DEFAULT NULL;   -- 仕訳ソース_個別開発
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi ADD START
  gv_prof_tax_code                 VARCHAR2(100) DEFAULT NULL;   -- 税金コード
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi ADD END
  gd_close_date                    DATE          DEFAULT NULL;   -- 締め日
  gd_payment_date                  DATE          DEFAULT NULL;   -- 支払日
  gn_group_id                      NUMBER        DEFAULT NULL;   -- グループID
  gv_batch_name                    VARCHAR2(100) DEFAULT NULL;   -- バッチ名
  gn_period_year                   NUMBER        DEFAULT NULL;   -- 会計年度
  gv_period_name                   VARCHAR2(100) DEFAULT NULL;   -- 会計期間名
  gv_closing_status                VARCHAR2(100) DEFAULT NULL;   -- 会計ステータス
  gv_user_name                     VARCHAR2(100) DEFAULT NULL;   -- 伝票入力者
  --==================================================
  -- 共通例外
  --==================================================
  --*** 処理部共通例外 ***
  global_process_expt              EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                  EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ロック取得エラー ***
  resource_busy_expt               EXCEPTION;
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
  --==================================================
  -- グローバル例外
  --==================================================
  --*** エラー終了 ***
  error_proc_expt                  EXCEPTION;
  --*** 警告スキップ ***
  warning_skip_expt                EXCEPTION;
  --==================================================
  -- グローバルカーソル
  --==================================================
  CURSOR get_bm_data_cur IS
    SELECT /*+
             LEADING( xbb, pv, pvsa )
             INDEX( xbb  XXCOK_BACKMARGIN_BALANCE_N10 )
           */
           xbb.supplier_code                           AS supplier_code                   -- 仕入先コード
         , xbb.supplier_site_code                      AS supplier_site_code              -- 仕入先サイトコード
         , xbb.cust_code                               AS cust_code                       -- 顧客コード
         , NVL( ( SELECT flvv.attribute1
                  FROM fnd_lookup_values_vl           flvv
                  WHERE xca.delivery_chain_code     = flvv.lookup_code
                    AND flvv.lookup_type            = cv_lookup_type_01
                    AND flvv.enabled_flag           = cv_enable
                    AND NVL( flvv.start_date_active, gd_process_date ) <= gd_process_date
                    AND NVL( flvv.end_date_active  , gd_process_date ) >= gd_process_date
                )
              , gv_prof_aff6_dummy )                   AS enterprise_code                 -- 企業コード
         , xca.sale_base_code                          AS base_code                       -- 拠点コード
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi REPAIR START
--         , xbb.tax_code                                AS tax_code                        -- 税コード
         , gv_prof_tax_code                            AS tax_code                        -- 税コード
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi REPAIR END
         , pvs.bank_charge_bearer                      AS bank_charge_bearer              -- 手数料負担者
         , pvs.payment_currency_code                   AS payment_currency_code           -- 通貨コード
         , pvs.attribute5                              AS section_code                    -- 起票部門
         , MAX( xbb.publication_date )                 AS publication_date                -- 支払日
         , NVL( SUM( xbb.backmargin        ), 0 )      AS backmargin                      -- 販売手数料
         , NVL( SUM( xbb.backmargin_tax    ), 0 )      AS backmargin_tax                  -- 販売手数料（消費税額）
         , NVL( SUM( xbb.electric_amt      ), 0 )      AS electric_amt                    -- 電気料
         , NVL( SUM( xbb.electric_amt_tax  ), 0 )      AS electric_amt_tax                -- 電気料（消費税額）
         , NVL( SUM( xbb.payment_amt_tax   ), 0 )      AS payment_amt_tax                 -- 支払額（税込）
    FROM xxcok_backmargin_balance       xbb       -- 販手残高
       , po_vendors                     pv        -- 仕入先
       , po_vendor_sites                pvs       -- 仕入先サイト
       , hz_cust_accounts               hca       -- 顧客マスタ
       , xxcmm_cust_accounts            xca       -- 顧客追加情報
    WHERE xbb.supplier_code           = pv.segment1
      AND xbb.supplier_site_code      = pvs.vendor_site_code
      AND pv.vendor_id                = pvs.vendor_id
      AND (    ( pvs.inactive_date   IS NULL            )
            OR ( pvs.inactive_date   >= gd_payment_date )
          )
      AND xbb.cust_code               = hca.account_number
      AND hca.cust_account_id         = xca.customer_id
      AND NVL( xbb.expect_payment_amt_tax, 0 ) = 0
      AND xbb.publication_date  BETWEEN TRUNC( gd_process_date, 'MM' )
                                    AND LAST_DAY( gd_process_date )
      AND xbb.fb_interface_status     = cv_interface_status_fb
      AND xbb.gl_interface_status     = cv_gl_if_status_before
    GROUP BY xbb.supplier_code
           , xbb.supplier_site_code
           , xbb.cust_code
           , xca.delivery_chain_code
           , xca.sale_base_code
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi DELETE START
--           , xbb.tax_code
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi DELETE END
           , pvs.bank_charge_bearer
           , pvs.payment_currency_code
           , pvs.attribute5
    ORDER BY xbb.supplier_code
           , NVL( SUM( xbb.payment_amt_tax   ), 0 ) DESC
           , xbb.cust_code
           , xca.sale_base_code
  ;
--
  /**********************************************************************************
   * Procedure Name   : update_xbb
   * Description      : 連携結果の更新(A-6)
   ***********************************************************************************/
  PROCEDURE update_xbb(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_supplier_code               IN  VARCHAR2        -- 仕入先コード
  , iv_org_slip_number             IN  VARCHAR2        -- 伝票番号
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xbb';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xbb_update_lock_cur
    IS
      SELECT xbb.bm_balance_id          AS bm_balance_id    -- 販手残高ID
      FROM xxcok_backmargin_balance     xbb  -- 販手残高
      WHERE xbb.supplier_code           = iv_supplier_code
        AND xbb.fb_interface_status     = cv_interface_status_fb
        AND xbb.gl_interface_status     = cv_gl_if_status_before
        AND NVL( xbb.expect_payment_amt_tax, 0 ) = 0
        AND xbb.publication_date  BETWEEN TRUNC( gd_process_date, 'MM' )
                                      AND LAST_DAY( gd_process_date )
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 販手残高更新ループ
    --==================================================
    << xsel_update_lock_loop >>
    FOR xbb_update_lock_rec IN xbb_update_lock_cur LOOP
      --==================================================
      -- 販手残高連携結果更新
      --==================================================
      UPDATE xxcok_backmargin_balance  xbb
      SET xbb.gl_interface_status     = cv_gl_if_status_after -- 連携ステータス（GL）
        , xbb.gl_interface_date       = gd_process_date       -- 連携日（GL）
        , xbb.org_slip_number         = iv_org_slip_number    -- 伝票番号
        , xbb.last_updated_by         = cn_last_updated_by
        , xbb.last_update_date        = SYSDATE
        , xbb.last_update_login       = cn_last_update_login
        , xbb.request_id              = cn_request_id
        , xbb.program_application_id  = cn_program_application_id
        , xbb.program_id              = cn_program_id
        , xbb.program_update_date     = SYSDATE
      WHERE xbb.bm_balance_id = xbb_update_lock_rec.bm_balance_id
      ;
    END LOOP xbb_update_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00053
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xbb;
--
  /**********************************************************************************
   * Procedure Name   : insert_gi
   * Description      : 仕訳登録(A-4)(A-5)
   ***********************************************************************************/
  PROCEDURE insert_gi(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , it_accounting_date             gl_interface.accounting_date       %TYPE
  , it_currency_code               gl_interface.currency_code         %TYPE
  , it_aff2_department             gl_interface.segment2              %TYPE
  , it_aff3_account                gl_interface.segment3              %TYPE
  , it_aff4_sub_account            gl_interface.segment4              %TYPE
  , it_aff5_customer               gl_interface.segment5              %TYPE
  , it_aff6_enterprise             gl_interface.segment6              %TYPE
  , it_entered_dr                  gl_interface.entered_dr            %TYPE
  , it_entered_cr                  gl_interface.entered_cr            %TYPE
  , it_tax_code                    gl_interface.reference1            %TYPE
  , it_slip_number                 gl_interface.attribute3            %TYPE
  , it_section                     gl_interface.attribute4            %TYPE
  , it_supplier_code               gl_interface.attribute7            %TYPE
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_gi';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- GLインタフェース登録
    --==================================================
    INSERT INTO gl_interface(
      status                         -- ステータス
    , set_of_books_id                -- 会計帳簿ID
    , accounting_date                -- 仕訳有効日付
    , currency_code                  -- 通貨コード
    , date_created                   -- 新規作成日付
    , created_by                     -- 新規作成者ID
    , actual_flag                    -- 残高タイプ
    , user_je_category_name          -- 仕訳カテゴリ名
    , user_je_source_name            -- 仕訳ソース名
    , segment1                       -- 会社
    , segment2                       -- 部門
    , segment3                       -- 勘定科目
    , segment4                       -- 補助科目
    , segment5                       -- 顧客コード
    , segment6                       -- 企業コード
    , segment7                       -- 予備１
    , segment8                       -- 予備２
    , entered_dr                     -- 借方金額
    , entered_cr                     -- 貸方金額
    , reference1                     -- バッチ名
    , reference4                     -- 仕訳名
    , period_name                    -- 会計期間名
    , group_id                       -- グループID
    , attribute1                     -- 税区分
    , attribute3                     -- 伝票番号
    , attribute4                     -- 起票部門
    , attribute5                     -- 伝票入力者
    , attribute7                     -- 仕入先コード
    , context                        -- DFFコンテキスト
    )
    VALUES(
      cv_je_status_new               -- ステータス
    , gn_prof_set_of_books_id        -- 会計帳簿ID
    , it_accounting_date             -- 仕訳有効日付
    , it_currency_code               -- 通貨コード
    , SYSDATE                        -- 新規作成日付
    , cn_created_by                  -- 新規作成者ID
    , cv_balance_type_result         -- 残高タイプ
    , gv_prof_gl_category_bm         -- 仕訳カテゴリ名
    , gv_prof_gl_source_cok          -- 仕訳ソース名
    , gv_prof_aff1_company_code      -- 会社
    , it_aff2_department             -- 部門
    , it_aff3_account                -- 勘定科目
    , it_aff4_sub_account            -- 補助科目
    , it_aff5_customer               -- 顧客コード
    , it_aff6_enterprise             -- 企業コード
    , gv_prof_aff7_dummy             -- 予備１
    , gv_prof_aff8_dummy             -- 予備２
    , CASE
        WHEN it_entered_dr < 0
          OR it_entered_cr < 0
        THEN
          it_entered_cr * -1
        ELSE
          it_entered_dr
      END
    , CASE
        WHEN it_entered_dr < 0
          OR it_entered_cr < 0
        THEN
          it_entered_dr * -1
        ELSE
          it_entered_cr
      END
    , gv_batch_name                  -- バッチ名
    , it_slip_number                 -- 仕訳名
    , gv_period_name                 -- 会計期間名
    , gn_group_id                    -- グループID
    , it_tax_code                    -- 税区分
    , it_slip_number                 -- 伝票番号
    , it_section                     -- 起票部門
    , gv_user_name                   -- 伝票入力者
    , it_supplier_code               -- 仕入先コード
    , gv_prof_set_of_books_name      -- DFFコンテキスト
    );
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_gi;
--
  /**********************************************************************************
   * Procedure Name   : bm_loop
   * Description      : 販売手数料情報ループ(A-2)
   ***********************************************************************************/
  PROCEDURE bm_loop(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'bm_loop';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    -- バッチ単位取得項目
    lt_slip_number                 gl_interface.attribute3%TYPE                 DEFAULT NULL; -- 伝票番号
    ln_fee_no_tax                  NUMBER                                       DEFAULT 0;    -- 振込手数料
    ln_fee_tax                     NUMBER                                       DEFAULT 0;    -- 振込手数料
    -- ブレイク条件項目
    lt_break_supplier_code         xxcok_backmargin_balance.supplier_code%TYPE  DEFAULT NULL;
    -- 振込額・仮払消費税用退避項目
    lt_cust_code                   gl_interface.segment5%TYPE                   DEFAULT NULL; -- 顧客コード
    lt_tax_code                    gl_interface.attribute1%TYPE                 DEFAULT NULL; -- 税コード
    lt_bank_charge_bearer          po_vendor_sites_all.bank_charge_bearer%TYPE  DEFAULT NULL; -- 手数料負担者
    lt_publication_date            gl_interface.accounting_date%TYPE            DEFAULT NULL; -- 支払日
    lt_currency_code               gl_interface.currency_code%TYPE              DEFAULT NULL; -- 通貨コード
    lt_section_code                gl_interface.attribute3%TYPE                 DEFAULT NULL; -- 起票部門
    ln_transfer_amount             NUMBER                                       DEFAULT 0;    -- 振込額
    ln_consumption_tax             NUMBER                                       DEFAULT 0;    -- 仮払消費税額
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ブレイク条件項目初期化
    --==================================================
    lt_break_supplier_code := NULL;
    --==================================================
    -- 販売手数料情報の取得
    --==================================================
    << bm_data_loop >>
    FOR get_bm_data_rec IN get_bm_data_cur LOOP
      gn_target_cnt := gn_target_cnt + 1;
      --==================================================
      -- ブレイク時処理
      --==================================================
      IF(    ( lt_break_supplier_code <> get_bm_data_rec.supplier_code )
          OR ( lt_break_supplier_code IS NULL                          )
      ) THEN
        --==================================================
        -- 支払先単位仕訳作成(A-5)
        --==================================================
        IF( lt_break_supplier_code IS NOT NULL ) THEN
          -- 振込手数料設定
          IF( lt_bank_charge_bearer = cv_chrg_flag_i ) THEN
            ln_fee_no_tax := 0;
            ln_fee_tax    := 0;
          ELSIF( ln_transfer_amount >= gn_prof_bank_fee_standard ) THEN
            ln_fee_no_tax := gn_prof_bank_fee_more;
            ln_fee_tax    := gn_prof_bank_fee_more * gn_prof_bm_tax_rate / 100;
          ELSE
            ln_fee_no_tax := gn_prof_bank_fee_less;
            ln_fee_tax    := gn_prof_bank_fee_less * gn_prof_bm_tax_rate / 100;
          END IF;
          ln_transfer_amount := ln_transfer_amount - ln_fee_no_tax - ln_fee_tax;
          ln_consumption_tax := ln_consumption_tax - ln_fee_tax;
          -- 振込額
          IF( ln_transfer_amount <> 0 ) THEN
            insert_gi(
              ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
            , ov_retcode                  => lv_retcode                 -- リターン・コード
            , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
            , it_accounting_date          => lt_publication_date
            , it_currency_code            => lt_currency_code
            , it_aff2_department          => gv_prof_aff2_dept_fin
            , it_aff3_account             => gv_prof_aff3_current_account
            , it_aff4_sub_account         => gv_prof_aff4_company_account
            , it_aff5_customer            => gv_prof_aff5_dummy
            , it_aff6_enterprise          => gv_prof_aff6_dummy
            , it_entered_dr               => NULL
            , it_entered_cr               => ln_transfer_amount
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi REPAIR START
--            , it_tax_code                 => lt_tax_code
            , it_tax_code                 => NULL
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi REPAIR END
            , it_slip_number              => lt_slip_number
            , it_section                  => lt_section_code
            , it_supplier_code            => lt_break_supplier_code
            );
            IF( lv_retcode = cv_status_error ) THEN
              lv_end_retcode := cv_status_error;
              RAISE global_process_expt;
            END IF;
          END IF;
          -- 仮払消費税
          IF( ln_consumption_tax <> 0 ) THEN
            insert_gi(
              ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
            , ov_retcode                  => lv_retcode                 -- リターン・コード
            , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
            , it_accounting_date          => lt_publication_date
            , it_currency_code            => lt_currency_code
            , it_aff2_department          => gv_prof_aff2_dept_fin
            , it_aff3_account             => gv_prof_aff3_tax
            , it_aff4_sub_account         => gv_prof_aff4_dummy
            , it_aff5_customer            => gv_prof_aff5_dummy
            , it_aff6_enterprise          => gv_prof_aff6_dummy
            , it_entered_dr               => ln_consumption_tax
            , it_entered_cr               => NULL
            , it_tax_code                 => lt_tax_code
            , it_slip_number              => lt_slip_number
            , it_section                  => lt_section_code
            , it_supplier_code            => lt_break_supplier_code
            );
            IF( lv_retcode = cv_status_error ) THEN
              lv_end_retcode := cv_status_error;
              RAISE global_process_expt;
            END IF;
          END IF;
          -- 振込手数料
          IF( ln_fee_no_tax <> 0 ) THEN
            insert_gi(
              ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
            , ov_retcode                  => lv_retcode                 -- リターン・コード
            , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
            , it_accounting_date          => lt_publication_date
            , it_currency_code            => lt_currency_code
            , it_aff2_department          => gv_prof_aff2_dept_fin
            , it_aff3_account             => gv_prof_aff3_fee
            , it_aff4_sub_account         => gv_prof_aff4_transfer_fee
            , it_aff5_customer            => gv_prof_aff5_dummy
            , it_aff6_enterprise          => gv_prof_aff6_dummy
            , it_entered_dr               => NULL
            , it_entered_cr               => ln_fee_no_tax
            , it_tax_code                 => lt_tax_code
            , it_slip_number              => lt_slip_number
            , it_section                  => lt_section_code
            , it_supplier_code            => lt_break_supplier_code
            );
            IF( lv_retcode = cv_status_error ) THEN
              lv_end_retcode := cv_status_error;
              RAISE global_process_expt;
            END IF;
          END IF;
          --==================================================
          -- 連携結果の更新(A-6)
          --==================================================
          update_xbb(
            ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
          , ov_retcode                  => lv_retcode                 -- リターン・コード
          , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
          , iv_supplier_code            => lt_break_supplier_code     -- 仕入先コード
          , iv_org_slip_number          => lt_slip_number             -- 伝票番号
          );
          IF( lv_retcode = cv_status_error ) THEN
            lv_end_retcode := cv_status_error;
            RAISE global_process_expt;
          END IF;
        END IF;
        --==================================================
        -- 仕入先共通情報保持(A-3)
        --==================================================
        lt_break_supplier_code := get_bm_data_rec.supplier_code;
        lt_cust_code           := get_bm_data_rec.cust_code;
        lt_tax_code            := get_bm_data_rec.tax_code;
        lt_bank_charge_bearer  := get_bm_data_rec.bank_charge_bearer;
        lt_publication_date    := get_bm_data_rec.publication_date;
        lt_currency_code       := get_bm_data_rec.payment_currency_code;
        lt_section_code        := get_bm_data_rec.section_code;
        ln_transfer_amount     := 0;
        ln_consumption_tax     := 0;
        ln_fee_no_tax          := 0;
        ln_fee_tax             := 0;
        -- 伝票番号取得
        lt_slip_number := xxcok_common_pkg.get_slip_number_f( cv_pkg_name );
        IF( lt_slip_number IS NULL ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_00025
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
        END IF;
      END IF;
      --==================================================
      -- 顧客単位仕訳作成(A-4)
      --==================================================
      -- リベート
      IF( get_bm_data_rec.backmargin <> 0 ) THEN
        insert_gi(
          ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
        , ov_retcode                  => lv_retcode                 -- リターン・コード
        , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
        , it_accounting_date          => get_bm_data_rec.publication_date
        , it_currency_code            => get_bm_data_rec.payment_currency_code
        , it_aff2_department          => get_bm_data_rec.base_code
        , it_aff3_account             => gv_prof_aff3_bm
        , it_aff4_sub_account         => gv_prof_aff4_rebate
        , it_aff5_customer            => get_bm_data_rec.cust_code
        , it_aff6_enterprise          => get_bm_data_rec.enterprise_code
        , it_entered_dr               => get_bm_data_rec.backmargin
        , it_entered_cr               => NULL
        , it_tax_code                 => get_bm_data_rec.tax_code
        , it_slip_number              => lt_slip_number
        , it_section                  => get_bm_data_rec.section_code
        , it_supplier_code            => get_bm_data_rec.supplier_code
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        END IF;
      END IF;
      -- 電気料
      IF( get_bm_data_rec.electric_amt <> 0 ) THEN
        insert_gi(
          ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
        , ov_retcode                  => lv_retcode                 -- リターン・コード
        , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
        , it_accounting_date          => get_bm_data_rec.publication_date
        , it_currency_code            => get_bm_data_rec.payment_currency_code
        , it_aff2_department          => get_bm_data_rec.base_code
        , it_aff3_account             => gv_prof_aff3_bm
        , it_aff4_sub_account         => gv_prof_aff4_elec_cost
        , it_aff5_customer            => get_bm_data_rec.cust_code
        , it_aff6_enterprise          => get_bm_data_rec.enterprise_code
        , it_entered_dr               => get_bm_data_rec.electric_amt
        , it_entered_cr               => NULL
        , it_tax_code                 => get_bm_data_rec.tax_code
        , it_slip_number              => lt_slip_number
        , it_section                  => get_bm_data_rec.section_code
        , it_supplier_code            => get_bm_data_rec.supplier_code
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warn ) THEN
          RAISE warning_skip_expt;
        END IF;
      END IF;
      -- 支払先単位仕訳用集計
      ln_transfer_amount := ln_transfer_amount
                          + get_bm_data_rec.backmargin
                          + get_bm_data_rec.backmargin_tax
                          + get_bm_data_rec.electric_amt
                          + get_bm_data_rec.electric_amt_tax
      ;
      ln_consumption_tax := ln_consumption_tax
                          + get_bm_data_rec.backmargin_tax
                          + get_bm_data_rec.electric_amt_tax
      ;
      --==================================================
      -- 正常件数カウント
      --==================================================
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP bm_data_loop;
    --==================================================
    -- 最終ブレイク単位分処理
    --==================================================
    IF( lt_break_supplier_code IS NOT NULL ) THEN
      --==================================================
      -- 支払先単位仕訳作成(A-5)
      --==================================================
      -- 振込手数料設定
      IF( lt_bank_charge_bearer = cv_chrg_flag_i ) THEN
        ln_fee_no_tax := 0;
        ln_fee_tax    := 0;
      ELSIF( ln_transfer_amount + ln_consumption_tax >= gn_prof_bank_fee_standard ) THEN
        ln_fee_no_tax := gn_prof_bank_fee_more;
        ln_fee_tax    := gn_prof_bank_fee_more * gn_prof_bm_tax_rate / 100;
      ELSE
        ln_fee_no_tax := gn_prof_bank_fee_less;
        ln_fee_tax    := gn_prof_bank_fee_less * gn_prof_bm_tax_rate / 100;
      END IF;
      ln_transfer_amount := ln_transfer_amount - ln_fee_no_tax - ln_fee_tax;
      ln_consumption_tax := ln_consumption_tax - ln_fee_tax;
      -- 振込額
      IF( ln_transfer_amount <> 0 ) THEN
        insert_gi(
          ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
        , ov_retcode                  => lv_retcode                 -- リターン・コード
        , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
        , it_accounting_date          => lt_publication_date
        , it_currency_code            => lt_currency_code
        , it_aff2_department          => gv_prof_aff2_dept_fin
        , it_aff3_account             => gv_prof_aff3_current_account
        , it_aff4_sub_account         => gv_prof_aff4_company_account
        , it_aff5_customer            => gv_prof_aff5_dummy
        , it_aff6_enterprise          => gv_prof_aff6_dummy
        , it_entered_dr               => NULL
        , it_entered_cr               => ln_transfer_amount
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi REPAIR START
--        , it_tax_code                 => lt_tax_code
        , it_tax_code                 => NULL
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi REPAIR END
        , it_slip_number              => lt_slip_number
        , it_section                  => lt_section_code
        , it_supplier_code            => lt_break_supplier_code
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        END IF;
      END IF;
      -- 仮払消費税
      IF( ln_consumption_tax <> 0 ) THEN
        insert_gi(
          ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
        , ov_retcode                  => lv_retcode                 -- リターン・コード
        , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
        , it_accounting_date          => lt_publication_date
        , it_currency_code            => lt_currency_code
        , it_aff2_department          => gv_prof_aff2_dept_fin
        , it_aff3_account             => gv_prof_aff3_tax
        , it_aff4_sub_account         => gv_prof_aff4_dummy
        , it_aff5_customer            => gv_prof_aff5_dummy
        , it_aff6_enterprise          => gv_prof_aff6_dummy
        , it_entered_dr               => ln_consumption_tax
        , it_entered_cr               => NULL
        , it_tax_code                 => lt_tax_code
        , it_slip_number              => lt_slip_number
        , it_section                  => lt_section_code
        , it_supplier_code            => lt_break_supplier_code
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        END IF;
      END IF;
      -- 振込手数料
      IF( ln_fee_no_tax <> 0 ) THEN
        insert_gi(
          ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
        , ov_retcode                  => lv_retcode                 -- リターン・コード
        , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
        , it_accounting_date          => lt_publication_date
        , it_currency_code            => lt_currency_code
        , it_aff2_department          => gv_prof_aff2_dept_fin
        , it_aff3_account             => gv_prof_aff3_fee
        , it_aff4_sub_account         => gv_prof_aff4_transfer_fee
        , it_aff5_customer            => gv_prof_aff5_dummy
        , it_aff6_enterprise          => gv_prof_aff6_dummy
        , it_entered_dr               => NULL
        , it_entered_cr               => ln_fee_no_tax
        , it_tax_code                 => lt_tax_code
        , it_slip_number              => lt_slip_number
        , it_section                  => lt_section_code
        , it_supplier_code            => lt_break_supplier_code
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        END IF;
      END IF;
      --==================================================
      -- 連携結果の更新(A-6)
      --==================================================
      update_xbb(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , iv_supplier_code            => lt_break_supplier_code     -- 仕入先コード
      , iv_org_slip_number          => lt_slip_number             -- 伝票番号
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END bm_loop;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- プログラム入力項目を出力
    --==================================================
    -- パラメータなし
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_ccp
                  , iv_name                 => cv_msg_ccp_90008
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message              => lv_outmsg          -- メッセージ
                  , in_new_line             => 0                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    --==================================================
    -- 業務処理日付取得
    --==================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'gd_process_date' || '【' || TO_CHAR( gd_process_date, 'RRRR/MM/DD' ) || '】' ); -- debug
    --==================================================
    -- プロファイル取得(営業単位ID)
    --==================================================
    gn_prof_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_01 ) );
    IF( gn_prof_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(会計帳簿ID)
    --==================================================
    gn_prof_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_02 ) );
    IF( gn_prof_set_of_books_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_02
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(会計帳簿名)
    --==================================================
    gv_prof_set_of_books_name := FND_PROFILE.VALUE( cv_profile_name_03 );
    IF( gv_prof_set_of_books_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_03
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(会社コード)
    --==================================================
    gv_prof_aff1_company_code := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF( gv_prof_aff1_company_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_04
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(部門コード_財務経理部)
    --==================================================
    gv_prof_aff2_dept_fin := FND_PROFILE.VALUE( cv_profile_name_05 );
    IF( gv_prof_aff2_dept_fin IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_05
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(勘定科目_当座預金)
    --==================================================
    gv_prof_aff3_current_account := FND_PROFILE.VALUE( cv_profile_name_06 );
    IF( gv_prof_aff3_current_account IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_06
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(勘定科目_手数料)
    --==================================================
    gv_prof_aff3_fee := FND_PROFILE.VALUE( cv_profile_name_07 );
    IF( gv_prof_aff3_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_07
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(勘定科目_仮払消費税)
    --==================================================
    gv_prof_aff3_tax := FND_PROFILE.VALUE( cv_profile_name_08 );
    IF( gv_prof_aff3_tax IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_08
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(勘定科目_自販機販売手数料)
    --==================================================
    gv_prof_aff3_bm := FND_PROFILE.VALUE( cv_profile_name_09 );
    IF( gv_prof_aff3_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_09
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(補助科目_ダミー値)
    --==================================================
    gv_prof_aff4_dummy := FND_PROFILE.VALUE( cv_profile_name_10 );
    IF( gv_prof_aff4_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_10
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(補助科目_手数料_振込手数料)
    --==================================================
    gv_prof_aff4_transfer_fee := FND_PROFILE.VALUE( cv_profile_name_11 );
    IF( gv_prof_aff4_transfer_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_11
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(補助科目_自販機販売手数料_自販電気料)
    --==================================================
    gv_prof_aff4_elec_cost := FND_PROFILE.VALUE( cv_profile_name_12 );
    IF( gv_prof_aff4_elec_cost IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_12
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(補助科目_自販機販売手数料_自販リベート)
    --==================================================
    gv_prof_aff4_rebate := FND_PROFILE.VALUE( cv_profile_name_13 );
    IF( gv_prof_aff4_rebate IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_13
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(補助科目_当座預金_当社口座)
    --==================================================
    gv_prof_aff4_company_account := FND_PROFILE.VALUE( cv_profile_name_14 );
    IF( gv_prof_aff4_company_account IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_14
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(顧客コード_ダミー値)
    --==================================================
    gv_prof_aff5_dummy := FND_PROFILE.VALUE( cv_profile_name_15 );
    IF( gv_prof_aff5_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_15
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(企業コード_ダミー値)
    --==================================================
    gv_prof_aff6_dummy := FND_PROFILE.VALUE( cv_profile_name_16 );
    IF( gv_prof_aff6_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_16
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(予備コード１_ダミー値)
    --==================================================
    gv_prof_aff7_dummy := FND_PROFILE.VALUE( cv_profile_name_17 );
    IF( gv_prof_aff7_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_17
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(予備コード２_ダミー値)
    --==================================================
    gv_prof_aff8_dummy := FND_PROFILE.VALUE( cv_profile_name_18 );
    IF( gv_prof_aff8_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_18
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(銀行手数料_基準額未満)
    --==================================================
    gn_prof_bank_fee_less := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_19 ) );
    IF( gn_prof_bank_fee_less IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_19
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(銀行手数料_基準額以上)
    --==================================================
    gn_prof_bank_fee_more := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_20 ) );
    IF( gn_prof_bank_fee_more IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_20
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(銀行手数料_振込額基準)
    --==================================================
    gn_prof_bank_fee_standard := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_21 ) );
    IF( gn_prof_bank_fee_standard IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_21
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(販売手数料_消費税率)
    --==================================================
    gn_prof_bm_tax_rate := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_22 ) );
    IF( gn_prof_bm_tax_rate IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_22
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(FB支払条件)
    --==================================================
    gv_prof_fb_term_name := FND_PROFILE.VALUE( cv_profile_name_23 );
    IF( gv_prof_fb_term_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_23
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(仕訳カテゴリ_販売手数料)
    --==================================================
    gv_prof_gl_category_bm := FND_PROFILE.VALUE( cv_profile_name_24 );
    IF( gv_prof_gl_category_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_24
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(仕訳ソース_個別開発)
    --==================================================
    gv_prof_gl_source_cok := FND_PROFILE.VALUE( cv_profile_name_25 );
    IF( gv_prof_gl_source_cok IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_25
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi ADD START
    --==================================================
    -- プロファイル取得(課税仕入内税消費税コード)
    --==================================================
    gv_prof_tax_code := FND_PROFILE.VALUE( cv_profile_name_26 );
    IF( gv_prof_tax_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_26
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2010/03/02 Ver.1.7 [E_本稼動_02268] SCS S.Arizumi ADD END
    --==================================================
    -- 締め・支払日取得
    --==================================================
    xxcok_common_pkg.get_close_date_p(
      ov_errbuf               => lv_errbuf
    , ov_retcode              => lv_retcode
    , ov_errmsg               => lv_errmsg
    , id_proc_date            => gd_process_date
    , iv_pay_cond             => gv_prof_fb_term_name
    , od_close_date           => gd_close_date
    , od_pay_date             => gd_payment_date
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --==================================================
    -- グループID取得
    --==================================================
    SELECT TO_NUMBER( gjs.attribute1 ) AS group_id     -- グループID
    INTO gn_group_id
    FROM gl_je_sources gjs
    WHERE gjs.user_je_source_name = gv_prof_gl_source_cok
      AND gjs.language            = cv_lang
    ;
    IF( gn_group_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00024
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- バッチ名取得
    --==================================================
    gv_batch_name := xxcok_common_pkg.get_batch_name_f( gv_prof_gl_category_bm );
    --==================================================
    -- 会計期間情報取得
    --==================================================
    xxcok_common_pkg.get_acctg_calendar_p(
      ov_errbuf                 => lv_errbuf
    , ov_retcode                => lv_retcode
    , ov_errmsg                 => lv_errmsg
    , in_set_of_books_id        => gn_prof_set_of_books_id  -- 会計帳簿ID
    , iv_application_short_name => cv_appl_short_name_gl    -- アプリケーション短縮名
    , id_object_date            => gd_payment_date          -- 支払予定日
    , on_period_year            => gn_period_year           -- 会計年度
    , ov_period_name            => gv_period_name           -- 会計期間名
    , ov_closing_status         => gv_closing_status        -- ステータス
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00011
                    , iv_token_name1          => cv_tkn_proc_date
                    , iv_token_value1         => TO_CHAR( gd_payment_date, 'YYYY/MM/DD' )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    ELSIF(    ( gv_closing_status <> cv_closing_status_open )
           OR ( gv_closing_status IS NULL                   )
    ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00042
                    , iv_token_name1          => cv_tkn_proc_date
                    , iv_token_value1         => TO_CHAR( gd_payment_date, 'YYYY/MM/DD' )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- 伝票入力者取得
    --==================================================
    SELECT fu.user_name user_name
    INTO gv_user_name
    FROM fnd_user             fu
    WHERE fu.user_id          = cn_created_by
    ;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 初期処理(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 販売手数料情報ループ(A-2)
    --==================================================
    bm_loop(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- エラーメッセージ
  , retcode                        OUT VARCHAR2        -- エラーコード
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- 終了メッセージコード
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message               => NULL               -- メッセージ
                  , in_new_line              => 1                  -- 改行
                  );
    --==================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    --==================================================
    -- エラー出力
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT     -- 出力区分
                    , iv_message               => lv_errmsg           -- メッセージ
                    , in_new_line              => 1                   -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 0
                    );
    END IF;
    --==================================================
    -- 対象件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 成功件数出力(エラー発生の場合、成功件数:0件 エラー件数:1件  対象件数0件の場合、成功件数:0件)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- エラー件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- 処理終了メッセージ出力
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ステータスセット
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- 終了ステータスエラー時、ロールバック
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
-- 2010/03/02 Ver.1.6 [E_本稼動_01596] SCS K.Yamaguchi REPAIR END
END XXCOK017A01C;
/
