CREATE OR REPLACE PACKAGE BODY XXCOK015A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A02R(body)
 * Description      : 手数料を現金支払する際の支払案内書（領収書付き）を
 *                    各売上計上拠点で印刷します。
 * MD.050           : 支払案内書印刷（領収書付き） MD050_COK_015_A02
 * Version          : 1.5
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  update_xbb           販手残高情報更新(A-6)
 *  delete_xrbpr         ワークテーブルデータ削除(A-5)
 *  start_svf            SVF起動(A-4)
 *  insert_xrbpr         データ取得(A-2)・ワークテーブルデータ登録(A-3)
 *  init                 初期処理(A-1)
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   K.Yamaguchi      新規作成
 *  2009/02/18    1.1   K.Suenaga        [障害COK_044]最新の仕入先サイト情報を取得・更新する
 *  2009/05/29    1.2   K.Yamaguchi      [障害T1_1261]販手残高テーブル更新項目追加
 *  2009/09/10    1.3   S.Moriyama       [障害0000060]住所の桁数変更対応
 *  2009/10/14    1.4   S.Moriyama       [変更依頼I_E_573]仕入先名称、住所の設定内容変更対応
 *  2011/02/02    1.5   M.Watanabe       [E_本稼動_05408,05409]年次切替対応
 *
 *****************************************************************************************/
  --==================================================
  -- グローバル定数
  --==================================================
  -- パッケージ名
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK015A02R';
  -- アプリケーション短縮名
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
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
  -- メッセージコード
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- 対象件数
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- 成功件数
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- エラー件数
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- 正常終了
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- 警告終了
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- エラー終了全ロールバック
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00040                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00040';
  cv_msg_cok_00074                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00074';
  cv_msg_cok_00086                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00086';
  cv_msg_cok_00088                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00088';
  cv_msg_cok_10102                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10102';
  -- トークン
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_errmsg                    CONSTANT VARCHAR2(30)    := 'ERRMSG';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_selling_base_code         CONSTANT VARCHAR2(30)    := 'SELLING_BASE_CODE';
  cv_tkn_fix_flag                  CONSTANT VARCHAR2(30)    := 'FIX_FLAG';
  cv_tkn_vendor_code               CONSTANT VARCHAR2(30)    := 'VENDOR_CODE';
  -- セパレータ
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- プロファイル・オプション名
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_BM';   -- XXCOK:支払案内書_販売手数料見出し
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_EP';   -- XXCOK:支払案内書_電気料見出し
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'ORG_ID';                       -- MO: 営業単位
  -- 参照タイプ名
  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCMM_YOKI_KUBUN';    -- 容器区分
  cv_lookup_type_02                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_CALC_TYPE'; -- 販手計算条件
  -- 共通関数メッセージ出力区分
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- SVF起動パラメータ
  cv_file_id                       CONSTANT VARCHAR2(20)    := 'XXCOK015A02R';       -- 帳票ID
  cv_output_mode                   CONSTANT VARCHAR2(1)     := '1';                  -- 出力区分(PDF出力)
  cv_extension                     CONSTANT VARCHAR2(10)    := '.pdf';               -- 出力ファイル名拡張子(PDF出力)
  cv_frm_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A02S.xml';   -- フォーム様式ファイル名
  cv_vrq_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A02S.vrq';   -- クエリー様式ファイル名
  -- 書式フォーマット
  cv_format_fxrrrrmm               CONSTANT VARCHAR2(50)    := 'FXRRRRMM';
  cv_format_fxrrrrmmdd             CONSTANT VARCHAR2(50)    := 'FXRRRRMMDD';
  cv_format_date                   CONSTANT VARCHAR2(50)    := 'RRRR"年"MM"月"DD"日"';
  cv_format_ee_month               CONSTANT VARCHAR2(50)    := 'EERR"年"MM"月分"';
  cv_format_ee_date                CONSTANT VARCHAR2(50)    := 'EERR"年"MM"月"DD"日"';
  -- 各国語サポートパラメータ
  cv_nls_param                     CONSTANT VARCHAR2(50)    := 'nls_calendar=''japanese imperial''';
  -- BM支払区分
  cv_bm_type_1                     CONSTANT VARCHAR2(1)     := '1';                  -- 本振（案内有）
  cv_bm_type_2                     CONSTANT VARCHAR2(1)     := '2';                  -- 本振（案内無）
  cv_bm_type_3                     CONSTANT VARCHAR2(1)     := '3';                  -- AP支払
  cv_bm_type_4                     CONSTANT VARCHAR2(1)     := '4';                  -- 現金支払
  -- 入力パラメータ・支払確定
  cv_param_fix_flag_y              CONSTANT VARCHAR2(5)     := 'Yes';
  cv_param_fix_flag_n              CONSTANT VARCHAR2(5)     := 'No';
-- 2009/05/29 Ver.1.2 [障害T1_1261] SCS K.Yamaguchi ADD START
  -- 連携ステータス
  cv_if_status_processed           CONSTANT VARCHAR2(1)     := '1';
-- 2009/05/29 Ver.1.2 [障害T1_1261] SCS K.Yamaguchi ADD END
  --==================================================
  -- グローバル変数
  --==================================================
  -- カウンタ
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- 対象件数
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- 正常件数
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- 異常件数
  -- 入力パラメータ
  gv_param_base_code               VARCHAR2(4)   DEFAULT NULL;  -- 売上計上拠点
  gv_param_fix_flag                VARCHAR2(7)   DEFAULT NULL;  -- 支払確定
  gv_param_vendor_code             VARCHAR2(9)   DEFAULT NULL;  -- 支払先
  -- 初期処理取得値
  gd_process_date                  DATE          DEFAULT NULL;   -- 業務処理日付
  gn_org_id                        NUMBER        DEFAULT NULL;   -- 営業単位ID
  gv_prompt_bm                     VARCHAR2(100) DEFAULT NULL;   -- 支払案内書_販売手数料見出し
  gv_prompt_ep                     VARCHAR2(100) DEFAULT NULL;   -- 支払案内書_電気料見出し
  --==================================================
  -- 共通例外
  --==================================================
  --*** 処理部共通例外 ***
  global_process_expt              EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                  EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt           EXCEPTION;
  --==================================================
  -- 例外
  --==================================================
  --*** エラー終了 ***
  error_proc_expt                  EXCEPTION;
--
  /**********************************************************************************
   * Procedure Name   : update_xbb
   * Description      : 販手残高情報更新(A-6)
   ***********************************************************************************/
  PROCEDURE update_xbb(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xbb';     -- プログラム名
    cv_n                           CONSTANT VARCHAR2(1)  := 'N';
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
    CURSOR lock_xbb_cur IS
      SELECT xbb.bm_balance_id
      FROM xxcok_backmargin_balance     xbb  -- 販手残高テーブル
         , po_vendors                   pv   -- 仕入先マスタ
         , po_vendor_sites_all          pvsa -- 仕入先サイトマスタ
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe ADD START
         , xxcmm_cust_accounts          xca  -- 顧客追加情報
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe ADD END
      WHERE xbb.supplier_code                = pv.segment1
        AND pv.vendor_id                     = pvsa.vendor_id
        AND xbb.expect_payment_amt_tax       > 0
        AND xbb.resv_flag                   IS NULL
        AND xbb.publication_date            IS NULL
        AND pvsa.hold_all_payments_flag      = cv_n
        AND pvsa.org_id                      = gn_org_id
        AND pvsa.attribute4                  = cv_bm_type_4
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe UPD START
--        AND xbb.base_code                    = gv_param_base_code
        AND xbb.cust_code                    = xca.customer_code
        AND xca.past_sale_base_code          = gv_param_base_code
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe UPD END
        AND xbb.supplier_code                = gv_param_vendor_code
        AND ( pvsa.inactive_date             < gd_process_date OR pvsa.inactive_date IS NULL )
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
    TYPE l_lock_xbb_ttype          IS TABLE OF xxcok_backmargin_balance.bm_balance_id%TYPE INDEX BY BINARY_INTEGER;
    l_lock_xbb_tab                 l_lock_xbb_ttype;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ロック・更新対象販手残高ID取得
    --==================================================
    OPEN  lock_xbb_cur;
    FETCH lock_xbb_cur BULK COLLECT INTO l_lock_xbb_tab;
    CLOSE lock_xbb_cur;
    IF( l_lock_xbb_tab.COUNT = 0 ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cok
                    , iv_name         => cv_msg_cok_10102
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => 0
                    );
      lv_end_retcode := cv_status_warn;
    ELSE
      --==================================================
      -- 販手残高テーブル更新
      --==================================================
      FORALL i IN 1 .. l_lock_xbb_tab.COUNT
      UPDATE xxcok_backmargin_balance     xbb  -- 販手残高テーブル
      SET payment_amt_tax            = expect_payment_amt_tax    -- 支払額（税込）
        , expect_payment_amt_tax     = 0                         -- 支払予定額（税込）
        , publication_date           = gd_process_date           -- 案内書発効日
-- 2009/05/29 Ver.1.2 [障害T1_1261] SCS K.Yamaguchi ADD START
        , fb_interface_status        = cv_if_status_processed    -- 連携ステータス（本振用FB）
        , fb_interface_date          = gd_process_date           -- 連携日（本振用FB）
        , edi_interface_status       = cv_if_status_processed    -- 連携ステータス（EDI支払案内書）
        , edi_interface_date         = gd_process_date           -- 連携日（EDI支払案内書）
        , gl_interface_status        = cv_if_status_processed    -- 連携ステータス（GL）
        , gl_interface_date          = gd_process_date           -- 連携日（GL）
        , balance_cancel_date        = gd_process_date           -- 残高取消日
-- 2009/05/29 Ver.1.2 [障害T1_1261] SCS K.Yamaguchi ADD END
        , last_updated_by            = cn_last_updated_by
        , last_update_date           = SYSDATE
        , last_update_login          = cn_last_update_login
        , request_id                 = cn_request_id
        , program_application_id     = cn_program_application_id
        , program_id                 = cn_program_id
        , program_update_date        = SYSDATE
      WHERE xbb.bm_balance_id = l_lock_xbb_tab(i)
      ;
    END IF;
    gn_target_cnt := l_lock_xbb_tab.COUNT;
    gn_normal_cnt := gn_target_cnt;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
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
  END update_xbb;
--
  /**********************************************************************************
   * Procedure Name   : delete_xrbpr
   * Description      : ワークテーブルデータ削除(A-5)
   ***********************************************************************************/
  PROCEDURE delete_xrbpr(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xrbpr';     -- プログラム名
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
    CURSOR lock_xrbpd_cur
    IS
      SELECT 'X'
      FROM xxcok_rep_bm_pg_receipt xrbpr
      WHERE xrbpr.request_id = cn_request_id
      FOR UPDATE OF xrbpr.payment_code NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ロック取得
    --==================================================
    OPEN  lock_xrbpd_cur;
    CLOSE lock_xrbpd_cur;
    --==================================================
    -- ワークテーブルデータ削除
    --==================================================
    DELETE
    FROM xxcok_rep_bm_pg_receipt   xrbpr
    WHERE xrbpr.request_id = cn_request_id
    ;
    --==================================================
    -- 成功件数取得
    --==================================================
    gn_target_cnt := SQL%ROWCOUNT;
    gn_normal_cnt := gn_target_cnt;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
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
  END delete_xrbpr;
--
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF起動(A-4)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'start_svf';     -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lv_date                        VARCHAR2(8)    DEFAULT NULL;                 -- 出力ファイル名用日付
    lv_file_name                   VARCHAR2(100)  DEFAULT NULL;                 -- 出力ファイル名
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- システム日付型変換
    --==================================================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    --==================================================
    -- 出力ファイル名(帳票ID + YYYYMMDD + 要求ID)
    --==================================================
    lv_file_name := cv_file_id
                 || TO_CHAR( SYSDATE, cv_format_fxrrrrmmdd )
                 || TO_CHAR( cn_request_id )
                 || cv_extension
                 ;
    --==================================================
    -- SVFコンカレント起動
    --==================================================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf                => lv_errbuf                 -- エラーバッファ
    , ov_retcode               => lv_retcode                -- リターンコード
    , ov_errmsg                => lv_errmsg                 -- エラーメッセージ
    , iv_conc_name             => cv_pkg_name               -- コンカレント名
    , iv_file_name             => lv_file_name              -- 出力ファイル名
    , iv_file_id               => cv_file_id                -- 帳票ID
    , iv_output_mode           => cv_output_mode            -- 出力区分
    , iv_frm_file              => cv_frm_file               -- フォーム様式ファイル名
    , iv_vrq_file              => cv_vrq_file               -- クエリー様式ファイル名
    , iv_org_id                => NULL                      -- ORG_ID
    , iv_user_name             => fnd_global.user_name      -- ログイン・ユーザ名
    , iv_resp_name             => fnd_global.resp_name      -- ログイン・ユーザ職責名
    , iv_doc_name              => NULL                      -- 文書名
    , iv_printer_name          => NULL                      -- プリンタ名
    , iv_request_id            => TO_CHAR( cn_request_id )  -- 要求ID
    , iv_nodata_msg            => NULL                      -- データなしメッセージ
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cok
                    , iv_name         => cv_msg_cok_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => 0
                    );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END start_svf;
--
  /**********************************************************************************
   * Procedure Name   : insert_xrbpr
   * Description      : データ取得(A-2)・ワークテーブルデータ登録(A-3)
   ***********************************************************************************/
  PROCEDURE insert_xrbpr(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xrbpr';     -- プログラム名
    cv_n                           CONSTANT VARCHAR2(1)  := 'N';
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
    -- ワークテーブルデータ登録
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_receipt(
      payment_code                      -- 支払先コード
    , publication_date                  -- 発行日
    , payment_zip_code                  -- 支払先郵便番号
    , payment_addr_1                    -- 支払先住所1
    , payment_addr_2                    -- 支払先住所2
    , payment_name_1                    -- 支払先宛名1
    , payment_name_2                    -- 支払先宛名2
    , contact_base_section_code         -- 地区コード（連絡先拠点）
    , contact_base_code                 -- 連絡先拠点コード
    , contact_base_name                 -- 連絡先拠点名
    , contact_addr_1                    -- 連絡先住所1
    , contact_addr_2                    -- 連絡先住所2
    , contact_phone_no                  -- 連絡先電話番号
    , target_month                      -- 年月分
    , closing_date                      -- 締め日
    , selling_amt_sum                   -- 販売金額合計
    , bm_index_1                        -- 合計見出し1
    , bm_amt_1                          -- 合計手数料1
    , bm_index_2                        -- 合計見出し2
    , bm_amt_2                          -- 合計手数料2
    , payment_amt_tax                   -- 支払金額（税込）
    , created_by                        -- 作成者
    , creation_date                     -- 作成日
    , last_updated_by                   -- 最終更新者
    , last_update_date                  -- 最終更新日
    , last_update_login                 -- 最終更新ログイン
    , request_id                        -- 要求ID
    , program_application_id            -- コンカレント・プログラム・アプリケーションID
    , program_id                        -- コンカレント・プログラムID
    , program_update_date               -- プログラム更新日
    )
    SELECT payment_code                 AS payment_code
         , TO_CHAR( gd_process_date
                  , cv_format_date  )   AS publication_date
         , payment_zip_code             AS payment_zip_code
         , payment_addr_1               AS payment_addr_1
         , payment_addr_2               AS payment_addr_2
         , payment_name_1               AS payment_name_1
         , payment_name_2               AS payment_name_2
         , contact_base_section_code    AS contact_base_section_code
         , contact_base_code            AS contact_base_code
         , contact_base_name            AS contact_base_name
         , contact_addr_1               AS contact_addr_1
         , contact_addr_2               AS contact_addr_2
         , contact_phone_no             AS contact_phone_no
         , TO_CHAR( closing_date
                  , cv_format_ee_month
                  , cv_nls_param )      AS target_month
         , closing_date                 AS closing_date
         , selling_amt_sum              AS selling_amt_sum
         , CASE
           WHEN backmargin > 0 THEN
             gv_prompt_bm
           ELSE
             gv_prompt_ep
           END                          AS bm_index_1
         , CASE
           WHEN backmargin > 0 THEN
             backmargin
           ELSE
             electric_amt
           END                          AS bm_amt_1
         , CASE
           WHEN backmargin   > 0
            AND electric_amt > 0 THEN
             gv_prompt_ep
           END                          AS bm_index_2
         , CASE
           WHEN backmargin   > 0
            AND electric_amt > 0 THEN
             electric_amt
           END                          AS bm_amt_2
         , payment_amt_tax              AS payment_amt_tax
         , cn_created_by                AS created_by
         , SYSDATE                      AS creation_date
         , cn_last_updated_by           AS last_updated_by
         , SYSDATE                      AS last_update_date
         , cn_last_update_login         AS last_update_login
         , cn_request_id                AS request_id
         , cn_program_application_id    AS program_application_id
         , cn_program_id                AS program_id
         , SYSDATE                      AS program_update_date
    FROM ( SELECT xbb.supplier_code                                   AS payment_code
-- 2009/10/14 Ver.1.4 [変更依頼I_E_573] SCS S.Moriyama UPD START
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama UPD START
----                , pvsa.zip                                            AS payment_zip_code
----                , pvsa.state || pvsa.city || pvsa.address_line1       AS payment_addr_1
----                , pvsa.address_line2                                  AS payment_addr_2
----                , SUBSTR( pv.vendor_name,  1, 15 )                    AS payment_name_1
----                , SUBSTR( pv.vendor_name, 16     )                    AS payment_name_2
--                , SUBSTRB( pvsa.zip , 1 , 8 )                         AS payment_zip_code
--                , SUBSTR( pvsa.city  || pvsa.address_line1
--                                     || pvsa.address_line2 , 1 , 20 ) AS payment_addr_1
--                , SUBSTR( pvsa.city  || pvsa.address_line1
--                                     || pvsa.address_line2 , 21, 20 ) AS payment_addr_2
--                , SUBSTR( pv.vendor_name,  1, 20 )                    AS payment_name_1
--                , SUBSTR( pv.vendor_name, 21, 20 )                    AS payment_name_2
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama UPD END
--                , hca.base_area_code                                  AS contact_base_section_code
--                , hca.base_code                                       AS contact_base_code
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama UPD START
----                , hca.base_name                                       AS contact_base_name
----                , hca.base_address1                                   AS contact_addr_1
----                , hca.base_address2                                   AS contact_addr_2
----                , hca.base_phone_num                                  AS contact_phone_no
--                , SUBSTR( hca.base_name , 1 , 20 )                    AS contact_base_name
--                , SUBSTR( hca.base_address1 , 1 , 20 )                AS contact_addr_1
--                , SUBSTR( hca.base_address1 , 21, 20 )                AS contact_addr_2
--                , SUBSTRB( hca.base_phone_num , 1 ,15 )               AS contact_phone_no
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama UPD END
--                , MAX( xbb.closing_date )                             AS closing_date
--                , SUM( xbb.selling_amt_tax )                          AS selling_amt_sum
--                , SUM(   NVL( xbb.backmargin    , 0 )
--                       + NVL( xbb.backmargin_tax, 0 )
--                  )                                                   AS backmargin
--                , SUM(   NVL( xbb.electric_amt    , 0 )
--                       + NVL( xbb.electric_amt_tax, 0 )
--                  )                                                   AS electric_amt
--                , SUM( xbb.expect_payment_amt_tax )                   AS payment_amt_tax
--           FROM xxcok_backmargin_balance     xbb  -- 販手残高テーブル
--              , po_vendors                   pv   -- 仕入先マスタ
--              , po_vendor_sites_all          pvsa -- 仕入先サイトマスタ
--              , ( SELECT hca.account_number            AS base_code
--                       , hp.party_name                 AS base_name
--                       , hl.address3                   AS base_area_code
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama UPD START
----                       ,    hl.state
----                         || hl.city
----                         || hl.address1                AS base_address1
----                       , hl.address2                   AS base_address2
--                       ,    hl.city
--                         || hl.address1
--                         || hl.address2                  AS base_address1
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama UPD END
--                       , hl.address_lines_phonetic     AS base_phone_num
--                  FROM hz_cust_accounts           hca       -- 顧客マスタ
--                     , hz_cust_acct_sites_all     hcasa     -- 顧客所在地マスタ
--                     , hz_parties                 hp        -- パーティマスタ
--                     , hz_party_sites             hps       -- パーティサイトマスタ
--                     , hz_locations               hl        -- 顧客事業所マスタ
--                  WHERE hca.cust_account_id  = hcasa.cust_account_id
--                    AND hca.party_id         = hp.party_id
--                    AND hcasa.party_site_id  = hps.party_site_id
--                    AND hps.location_id      = hl.location_id
--                    AND hcasa.org_id        = gn_org_id
--                )                            hca
--           WHERE xbb.base_code                    = hca.base_code
--             AND xbb.supplier_code                = pv.segment1
--             AND pv.vendor_id                     = pvsa.vendor_id
--             AND pvsa.org_id                      = gn_org_id
--             AND pvsa.attribute4                  = cv_bm_type_4
--             AND xbb.expect_payment_amt_tax       > 0
--             AND xbb.payment_amt_tax              = 0
--             AND xbb.resv_flag                   IS NULL
--             AND xbb.publication_date            IS NULL
--             AND pvsa.hold_all_payments_flag      = cv_n
--             AND xbb.base_code                    = gv_param_base_code
--             AND xbb.supplier_code                = NVL( gv_param_vendor_code, xbb.supplier_code )
--             AND ( pvsa.inactive_date             < gd_process_date OR pvsa.inactive_date IS NULL )
--           GROUP BY xbb.supplier_code
--                  , pvsa.zip
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama UPD START
----                  , pvsa.state || pvsa.city || pvsa.address_line1
----                  , pvsa.address_line2
----                  , SUBSTR( pv.vendor_name,  1, 15 )
----                  , SUBSTR( pv.vendor_name, 16     )
--                  , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--                  , SUBSTR( pv.vendor_name,  1, 20 )
--                  , SUBSTR( pv.vendor_name, 21, 20 )
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama UPD END
--                  , hca.base_code
--                  , hca.base_name
--                  , hca.base_area_code
--                  , hca.base_address1
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama DEL START
----                  , hca.base_address2
---- 2009/09/10 Ver.1.3 [障害0000060] SCS S.Moriyama DEL END
--                  , hca.base_phone_num
--         )
                , SUBSTRB( pvsa.zip , 1 , 8 )                         AS payment_zip_code
                , SUBSTR( pvsa.address_line1
                          || pvsa.address_line2 , 1 , 20 )            AS payment_addr_1
                , SUBSTR( pvsa.address_line1
                          || pvsa.address_line2 , 21, 20 )            AS payment_addr_2
                , SUBSTR( pvsa.attribute1,  1, 20 )                   AS payment_name_1
                , SUBSTR( pvsa.attribute1, 21, 20 )                   AS payment_name_2
                , hca.base_area_code                                  AS contact_base_section_code
                , hca.base_code                                       AS contact_base_code
                , SUBSTR( hca.base_name , 1 , 20 )                    AS contact_base_name
                , SUBSTR( hca.base_address1 , 1 , 20 )                AS contact_addr_1
                , SUBSTR( hca.base_address1 , 21, 20 )                AS contact_addr_2
                , SUBSTRB( hca.base_phone_num , 1 ,15 )               AS contact_phone_no
                , MAX( xbb.closing_date )                             AS closing_date
                , SUM( xbb.selling_amt_tax )                          AS selling_amt_sum
                , SUM(   NVL( xbb.backmargin    , 0 )
                       + NVL( xbb.backmargin_tax, 0 )
                  )                                                   AS backmargin
                , SUM(   NVL( xbb.electric_amt    , 0 )
                       + NVL( xbb.electric_amt_tax, 0 )
                  )                                                   AS electric_amt
                , SUM( xbb.expect_payment_amt_tax )                   AS payment_amt_tax
           FROM xxcok_backmargin_balance     xbb  -- 販手残高テーブル
              , po_vendors                   pv   -- 仕入先マスタ
              , po_vendor_sites_all          pvsa -- 仕入先サイトマスタ
              , ( SELECT hca.account_number            AS base_code
                       , hp.party_name                 AS base_name
                       , hl.address3                   AS base_area_code
                       ,    hl.city
                         || hl.address1
                         || hl.address2                AS base_address1
                       , hl.address_lines_phonetic     AS base_phone_num
                  FROM hz_cust_accounts           hca       -- 顧客マスタ
                     , hz_cust_acct_sites_all     hcasa     -- 顧客所在地マスタ
                     , hz_parties                 hp        -- パーティマスタ
                     , hz_party_sites             hps       -- パーティサイトマスタ
                     , hz_locations               hl        -- 顧客事業所マスタ
                  WHERE hca.cust_account_id  = hcasa.cust_account_id
                    AND hca.party_id         = hp.party_id
                    AND hcasa.party_site_id  = hps.party_site_id
                    AND hps.location_id      = hl.location_id
                    AND hcasa.org_id        = gn_org_id
                )                            hca
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe ADD START
              , xxcmm_cust_accounts          xca  -- 顧客追加情報
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe ADD END
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe UPD START
--           WHERE xbb.base_code                    = hca.base_code
--             AND xbb.supplier_code                = pv.segment1
             WHERE xbb.supplier_code                = pv.segment1
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe UPD END
             AND pv.vendor_id                     = pvsa.vendor_id
             AND pvsa.org_id                      = gn_org_id
             AND pvsa.attribute4                  = cv_bm_type_4
             AND xbb.expect_payment_amt_tax       > 0
             AND xbb.payment_amt_tax              = 0
             AND xbb.resv_flag                   IS NULL
             AND xbb.publication_date            IS NULL
             AND pvsa.hold_all_payments_flag      = cv_n
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe UPD START
--             AND xbb.base_code                    = gv_param_base_code
             AND xbb.cust_code                    = xca.customer_code
             AND xca.past_sale_base_code          = gv_param_base_code
             AND xca.sale_base_code               = hca.base_code
-- 2011/02/02 Ver.1.5 [障害E_本稼動_05408] SCS M.Watanabe UPD END
             AND xbb.supplier_code                = NVL( gv_param_vendor_code, xbb.supplier_code )
             AND ( pvsa.inactive_date             < gd_process_date OR pvsa.inactive_date IS NULL )
           GROUP BY xbb.supplier_code
                  , pvsa.zip
                  , pvsa.address_line1 || pvsa.address_line2
                  , SUBSTR( pvsa.attribute1,  1, 20 )
                  , SUBSTR( pvsa.attribute1, 21, 20 )
                  , hca.base_code
                  , hca.base_name
                  , hca.base_area_code
                  , hca.base_address1
                  , hca.base_phone_num
         )
-- 2009/10/14 Ver.1.4 [変更依頼I_E_573] SCS S.Moriyama UPD END
    ;
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
  END insert_xrbpr;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_base_code                   IN  VARCHAR2        -- 売上計上拠点
  , iv_fix_flag                    IN  VARCHAR2        -- 支払確定
  , iv_vendor_code                 IN  VARCHAR2        -- 支払先
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
    ld_chk_date                    DATE           DEFAULT NULL;                 -- 日付型チェック用変数
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- プログラム入力項目を出力
    --==================================================
    -- 売上計上拠点
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00074
                  , iv_token_name1          => cv_tkn_selling_base_code
                  , iv_token_value1         => iv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- 支払確定
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00088
                  , iv_token_name1          => cv_tkn_fix_flag
                  , iv_token_value1         => iv_fix_flag
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- 支払先
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00086
                  , iv_token_name1          => cv_tkn_vendor_code
                  , iv_token_value1         => iv_vendor_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 1
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
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(MO: 営業単位)
    --==================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_03 ) );
    IF( gn_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_03
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_販売手数料見出し)
    --==================================================
    gv_prompt_bm := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_prompt_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_電気料見出し)
    --==================================================
    gv_prompt_ep := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_prompt_ep IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_02
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    gv_param_base_code   := iv_base_code;
    gv_param_fix_flag    := iv_fix_flag;
    gv_param_vendor_code := iv_vendor_code;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
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
  , iv_base_code                   IN  VARCHAR2        -- 売上計上拠点
  , iv_fix_flag                    IN  VARCHAR2        -- 支払確定
  , iv_vendor_code                 IN  VARCHAR2        -- 支払先
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';          -- プログラム名
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
    , iv_base_code            => iv_base_code          -- 売上計上拠点
    , iv_fix_flag             => iv_fix_flag           -- 支払確定
    , iv_vendor_code          => iv_vendor_code        -- 支払先
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 支払確定：No
    --==================================================
    IF( gv_param_fix_flag = cv_param_fix_flag_n ) THEN
      --==================================================
      -- データ取得(A-2)・ワークテーブルデータ登録(A-3)
      --==================================================
      insert_xrbpr(
        ov_errbuf               => lv_errbuf                -- エラー・メッセージ
      , ov_retcode              => lv_retcode               -- リターン・コード
      , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 確定
      --==================================================
      COMMIT;
      --==================================================
      -- SVF起動(A-4)
      --==================================================
      start_svf(
        ov_errbuf   => lv_errbuf   -- エラー・メッセージ
      , ov_retcode  => lv_retcode  -- リターン・コード
      , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- ワークテーブルデータ削除(A-5)
      --==================================================
      delete_xrbpr(
        ov_errbuf               => lv_errbuf                -- エラー・メッセージ
      , ov_retcode              => lv_retcode               -- リターン・コード
      , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    --==================================================
    -- 支払確定：Yes
    --==================================================
    ELSIF( gv_param_fix_flag = cv_param_fix_flag_y ) THEN
      --==================================================
      -- 販手残高情報更新(A-6)
      --==================================================
      update_xbb(
        ov_errbuf               => lv_errbuf                -- エラー・メッセージ
      , ov_retcode              => lv_retcode               -- リターン・コード
      , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
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
  , iv_base_code                   IN  VARCHAR2        -- 売上計上拠点
  , iv_fix_flag                    IN  VARCHAR2        -- 支払確定
  , iv_vendor_code                 IN  VARCHAR2        -- 支払先
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
    , iv_which                => cv_which_log
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --==================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_base_code            => iv_base_code          -- 売上計上拠点
    , iv_fix_flag             => iv_fix_flag           -- 支払確定
    , iv_vendor_code          => iv_vendor_code        -- 支払先
    );
    --==================================================
    -- エラー出力
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG   -- 出力区分
                    , iv_message               => lv_errmsg      -- メッセージ
                    , in_new_line              => 0              -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 1
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
                    in_which                 => FND_FILE.LOG
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
                    in_which                 => FND_FILE.LOG
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
                    in_which                 => FND_FILE.LOG
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
                    in_which                 => FND_FILE.LOG
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
END XXCOK015A02R;
/
