CREATE OR REPLACE PACKAGE BODY XXCOI001A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A04C(body)
 * Description      : 自動入庫確認
 * MD.050           : 自動入庫確認 MD050_COI_001_A04
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_slip_num           対象伝票No取得処理 (A-2)
 *  get_storage_info       入庫情報取得処理 (A-4)
 *  chk_org_acct_period    会計期間チェック処理 (A-5)
 *  get_lock               ロック取得処理 (A-6)
 *  upd_storage_info_tab   自動入庫確認処理 (A-7)
 *  submain                メイン処理プロシージャ
 *                         セーブポイント設定 (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理 (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/26    1.0   K.Nakamura       新規作成
 *  2009/02/12    1.1   S.Moriyama       結合テスト障害No002対応
 *  2009/02/24    1.2   K.Nakamura       結合テスト障害No026対応
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  no_data_expt                   EXCEPTION; -- 取得件数0件例外
  lock_expt                      EXCEPTION; -- ロック取得例外
  acct_period_close_expt         EXCEPTION; -- 在庫会計期間クローズ
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ロック取得例外
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100) := 'XXCOI001A04C'; -- パッケージ
  cv_appl_short_name             CONSTANT VARCHAR2(10)  := 'XXCCP';        -- アドオン：共通・IF領域
  cv_application_short_name      CONSTANT VARCHAR2(10)  := 'XXCOI';        -- アプリケーション短縮名
  cv_flag_on                     CONSTANT VARCHAR2(1)   := 'Y';            -- フラグON
  cv_flag_off                    CONSTANT VARCHAR2(1)   := 'N';            -- フラグOFF
  -- メッセージ
  cv_no_para_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなしメッセージ
  cv_org_code_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
  cv_org_id_get_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
  cv_no_data_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- 対象データ無しメッセージ
  cv_process_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- 業務日付取得エラーメッセージ
  cv_acct_period_close_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10018'; -- 在庫会計期間クローズメッセージ
  cv_table_lock_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10029'; -- ロックエラーメッセージ（入庫情報一時表）
  -- トークン
  cv_tkn_pro                     CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- プロファイル名
  cv_tkn_org_code                CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';     -- 在庫組織コード
  cv_tkn_den_no                  CONSTANT VARCHAR2(20)  := 'DEN_NO';           -- 伝票No
  cv_tkn_entry_date              CONSTANT VARCHAR2(20)  := 'ENTRY_DATE';       -- 伝票日付
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 伝票Noレコード格納用
  TYPE gt_slip_num_ttype IS TABLE OF xxcoi_storage_information.slip_num%TYPE INDEX BY BINARY_INTEGER;
--
  -- 入庫情報レコード格納用
  TYPE gr_storage_info_rec IS RECORD(
      transaction_id                 xxcoi_storage_information.transaction_id%TYPE                 -- 取引ID
    , slip_num                       xxcoi_storage_information.slip_num%TYPE                       -- 伝票番号
    , slip_date                      xxcoi_storage_information.slip_date%TYPE                      -- 伝票日付
    , ship_case_qty                  xxcoi_storage_information.ship_case_qty%TYPE                  -- 出庫数量ケース数
    , ship_singly_qty                xxcoi_storage_information.ship_singly_qty%TYPE                -- 出庫数量バラ数
    , ship_summary_qty               xxcoi_storage_information.ship_summary_qty%TYPE               -- 出庫数量総バラ数
    , check_summary_qty              xxcoi_storage_information.check_summary_qty%TYPE              -- 確認数量総バラ数
    , material_transaction_unset_qty xxcoi_storage_information.material_transaction_unset_qty%TYPE -- 資材取引未連携数量
  );
--
  TYPE gt_storage_info_ttype IS TABLE OF gr_storage_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_org_id                      mtl_parameters.organization_id%TYPE; -- 在庫組織ID
  gd_date                        DATE;                                -- 業務日付
  -- カウンタ
  gn_slip_loop_cnt               NUMBER; -- 伝票単位ループカウンタ
  gn_storage_info_loop_cnt       NUMBER; -- 入庫情報単位ループカウンタ
  gn_storage_info_cnt            NUMBER; -- 入庫情報単位カウンタ
  -- PL/SQL表
  gt_slip_num_tab                gt_slip_num_ttype;
  gt_storage_info_tab            gt_storage_info_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    -- プロファイル
    cv_prf_org_code                CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE'; -- 在庫組織コード
--
    -- *** ローカル変数 ***
    lt_org_code                    mtl_parameters.organization_code%TYPE; -- 在庫組織コード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- コンカレント入力パラメータなしメッセージログ出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => cv_no_para_msg
                  );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- ===============================
    -- プロファイル取得：在庫組織コード
    -- ===============================
    lt_org_code := fnd_profile.value( cv_prf_org_code );
    -- プロファイルが取得できない場合
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 在庫組織ID取得
    -- ===============================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_code );
    -- 共通関数の戻り値がNULLの場合
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_id_get_err_msg
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 業務日付取得
    -- ===============================
    gd_date := xxccp_common_pkg2.get_process_date;
    -- 共通関数の戻り値がNULLの場合
    IF ( gd_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_process_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN
    -- *** 共通関数例外ハンドラ ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_slip_num
   * Description      : 対象伝票No取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_slip_num(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_slip_num'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 伝票単位取得
    CURSOR slip_num_cur
    IS
      SELECT  DISTINCT xsi.slip_num     AS slip_num              -- 伝票No
      FROM    xxcoi_storage_information xsi                      -- 入庫情報一時表
      WHERE   xsi.auto_store_check_flag = cv_flag_on             -- 自動入庫確認フラグ
      AND     xsi.summary_data_flag     = cv_flag_on             -- サマリーデータフラグ
      AND     xsi.ship_summary_qty      <> xsi.check_summary_qty -- 出庫数量総バラ数 <> 確認数量総バラ数
      AND     TRUNC( xsi.slip_date )    <= gd_date               -- 伝票日付
      ORDER BY xsi.slip_num
    ;
    -- <カーソル名>レコード型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN slip_num_cur;
--
    -- レコード読み込み
    FETCH slip_num_cur BULK COLLECT INTO gt_slip_num_tab;
--
    -- 対象件数セット
    gn_target_cnt := gt_slip_num_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE slip_num_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_slip_num;
--
  /**********************************************************************************
   * Procedure Name   : get_storage_info
   * Description      : 入庫情報取得処理 (A-4)
   ***********************************************************************************/
  PROCEDURE get_storage_info(
    gn_slip_loop_cnt IN  NUMBER,       --   伝票単位ループカウンタ
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_storage_info'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 入庫情報単位取得
    CURSOR storage_info_cur
    IS
      SELECT
             xsi.transaction_id                 AS transaction_id                     -- 取引ID
           , xsi.slip_num                       AS slip_num                           -- 伝票No
           , xsi.slip_date                      AS slip_date                          -- 伝票日付
           , xsi.ship_case_qty                  AS ship_case_qty                      -- 出庫数量ケース数
           , xsi.ship_singly_qty                AS ship_singly_qty                    -- 出庫数量バラ数
           , xsi.ship_summary_qty               AS ship_summary_qty                   -- 出庫数量総バラ数
           , xsi.check_summary_qty              AS check_summary_qty                  -- 確認数量総バラ数
           , xsi.material_transaction_unset_qty AS material_transaction_unset_qty     -- 資材取引未連携数量
      FROM 
             xxcoi_storage_information          xsi                                   -- 入庫情報一時表
      WHERE 
             xsi.slip_num                       = gt_slip_num_tab( gn_slip_loop_cnt ) -- 伝票No
      AND    xsi.summary_data_flag              = cv_flag_on                          -- サマリーデータフラグ
      AND    xsi.ship_summary_qty               <> xsi.check_summary_qty              -- 出庫数量総バラ数 <> 確認数量総バラ数
      AND    TRUNC( xsi.slip_date )             <= gd_date                            -- 伝票日付
    ;
    -- <カーソル名>レコード型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN storage_info_cur;
--
    -- レコード読み込み
    FETCH storage_info_cur BULK COLLECT INTO gt_storage_info_tab;
--
    -- 対象件数セット
    gn_storage_info_cnt := gt_storage_info_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE storage_info_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_storage_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_org_acct_period
   * Description      : 会計期間チェック処理 (A-5)
   ***********************************************************************************/
  PROCEDURE chk_org_acct_period(
    gn_slip_loop_cnt         IN   NUMBER,    -- 伝票単位ループカウンタ
    gn_storage_info_loop_cnt IN   NUMBER,    -- 入庫情報単位ループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_org_acct_period'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
    -- 在庫会計期間チェック
    lb_chk_result                BOOLEAN; -- ステータス
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    lb_chk_result := TRUE;
--
    -- ===============================
    -- 在庫会計期間チェック
    -- ===============================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                                 -- 在庫組織ID
      , id_target_date     => gt_storage_info_tab( gn_storage_info_loop_cnt ).slip_date -- 対象日
      , ob_chk_result      => lb_chk_result                                             -- チェック結果
      , ov_errbuf          => lv_errbuf                                                 -- エラーメッセージ
      , ov_retcode         => lv_retcode                                                -- リターン・コード
      , ov_errmsg          => lv_errmsg                                                 -- ユーザー・エラーメッセージ
    );
--
    -- 戻り値のステータスがFALSEの場合
    IF ( lb_chk_result = FALSE ) THEN
      RAISE acct_period_close_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- 在庫会計期間クローズエラー
    WHEN acct_period_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_acct_period_close_err_msg
                     , iv_token_name1  => cv_tkn_den_no
                     , iv_token_value1 => gt_slip_num_tab( gn_slip_loop_cnt )
                     , iv_token_name2  => cv_tkn_entry_date
                     , iv_token_value2 => TO_CHAR( gt_storage_info_tab( gn_storage_info_loop_cnt ).slip_date, 'YYYY/MM/DD' )
                   );
      lv_errbuf  := lv_errmsg;
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --エラーメッセージ
      );
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
--#####################################  固定部 END   ##########################################
--
  END chk_org_acct_period;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ロック取得処理 (A-6)
   ***********************************************************************************/
  PROCEDURE get_lock(
    gn_slip_loop_cnt         IN   NUMBER,    -- 伝票単位ループカウンタ
    gn_storage_info_loop_cnt IN   NUMBER,    -- 入庫情報単位ループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 入庫情報一時表ロック取得
    CURSOR xsi_slip_num_cur
    IS
      SELECT  xsi.slip_num              AS slip_num                                                      -- 伝票No
      FROM    xxcoi_storage_information xsi                                                              -- 入庫情報一時表
      WHERE   xsi.transaction_id        = gt_storage_info_tab( gn_storage_info_loop_cnt ).transaction_id -- 取引ID
      FOR UPDATE OF xsi.slip_num NOWAIT
    ;
--
    -- <カーソル名>レコード型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN xsi_slip_num_cur;
--
    -- カーソルクローズ
    CLOSE xsi_slip_num_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ロック取得エラー
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_table_lock_err_msg
                      , iv_token_name1  => cv_tkn_den_no
                      , iv_token_value1 => gt_slip_num_tab( gn_slip_loop_cnt )
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --エラーメッセージ
      );
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   : upd_storage_info_tab
   * Description      : 自動入庫確認処理 (A-7)
   ***********************************************************************************/
  PROCEDURE upd_storage_info_tab(
    gn_storage_info_loop_cnt IN   NUMBER,    -- 倉替データループカウンタ
    ov_errbuf                OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_storage_info_tab'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 入出庫一時表更新
    UPDATE xxcoi_storage_information xsi                                                                                -- 入庫情報一時表
    SET    xsi.check_case_qty                 = gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_case_qty           -- 確認数量ケース数
         , xsi.check_singly_qty               = gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_singly_qty         -- 確認数量バラ数
         , xsi.check_summary_qty              = gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_summary_qty        -- 確認数量総バラ数
         , xsi.material_transaction_unset_qty = ( ( gt_storage_info_tab( gn_storage_info_loop_cnt ).material_transaction_unset_qty -- 資材取引未連携数量
                                                  + gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_summary_qty )  -- 出庫数量総バラ数
                                                  - gt_storage_info_tab( gn_storage_info_loop_cnt ).check_summary_qty ) -- 確認数量総バラ数
         , xsi.store_check_flag               = cv_flag_on                                                              -- 入庫確認フラグ
         , xsi.material_transaction_set_flag  = cv_flag_off                                                             -- 資材取引連携済フラグ
         , xsi.last_updated_by                = cn_last_updated_by                                                      -- 最終更新者
         , xsi.last_update_date               = cd_last_update_date                                                     -- 最終更新日
         , xsi.last_update_login              = cn_last_update_login                                                    -- 最終更新ログイン
         , xsi.request_id                     = cn_request_id                                                           -- 要求ID
         , xsi.program_application_id         = cn_program_application_id                                               -- プログラムアプリケーションID
         , xsi.program_id                     = cn_program_id                                                           -- プログラムID
         , xsi.program_update_date            = cd_program_update_date                                                  -- プログラム更新日
    WHERE  xsi.transaction_id                 = gt_storage_info_tab( gn_storage_info_loop_cnt ).transaction_id          -- 取引ID
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
--#####################################  固定部 END   ##########################################
--
  END upd_storage_info_tab;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
    -- <カーソル名>レコード型
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 対象伝票No取得処理 (A-2)
    -- ===============================
    get_slip_num(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 伝票No取得件数が0件の場合
    IF ( gn_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
    -- 伝票単位ループ開始
    <<gt_slip_num_tab_loop>>
    FOR gn_slip_loop_cnt IN 1 .. gn_target_cnt LOOP
--
      -- ===============================
      -- セーブポイント設定 (A-3)
      -- ===============================
      SAVEPOINT slip_num_point;
--
      -- ===============================
      -- 入庫情報取得処理 (A-4)
      -- ===============================
      get_storage_info(
          gn_slip_loop_cnt => gn_slip_loop_cnt -- 伝票単位ループカウンタ
        , ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
        , ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
        , ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 入庫情報単位ループ開始
      <<gt_storage_info_tab_loop>>
      FOR gn_storage_info_loop_cnt IN 1 .. gn_storage_info_cnt LOOP
--
        -- ===============================
        -- 会計期間チェック処理 (A-5)
        -- ===============================
        chk_org_acct_period(
            gn_slip_loop_cnt         => gn_slip_loop_cnt         -- 伝票単位ループカウンタ
          , gn_storage_info_loop_cnt => gn_storage_info_loop_cnt -- 入庫情報単位ループカウンタ
          , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- セーブポイントまでロールバック
          ROLLBACK TO SAVEPOINT slip_num_point;
          -- 入庫情報単位ループを抜ける
          EXIT gt_storage_info_tab_loop;
        END IF;
--
        -- ===============================
        -- ロック取得処理 (A-6)
        -- ===============================
        get_lock(
            gn_slip_loop_cnt         => gn_slip_loop_cnt         -- 伝票単位ループカウンタ
          , gn_storage_info_loop_cnt => gn_storage_info_loop_cnt -- 入庫情報単位ループカウンタ
          , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- セーブポイントまでロールバック
          ROLLBACK TO SAVEPOINT slip_num_point;
          -- 入庫情報単位ループを抜ける
          EXIT gt_storage_info_tab_loop;
        END IF;
--
        -- ===============================
        -- 自動入庫確認処理 (A-7)
        -- ===============================
        upd_storage_info_tab(
            gn_storage_info_loop_cnt => gn_storage_info_loop_cnt -- 入庫情報単位ループカウンタ
          , ov_errbuf                => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode               => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP gt_storage_info_tab_loop;
--
      -- ステータスが正常の場合
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 成功件数
        gn_normal_cnt := gn_normal_cnt + 1;
      -- ステータスが警告の場合
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        -- エラー件数
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
--
    END LOOP gt_slip_num_tab_loop;
--
  EXCEPTION
    -- 取得件数0件
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_no_data_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_normal;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --エラーメッセージ
      );
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
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
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
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
      , lv_retcode  -- リターン・コード             --# 固定 #
      , lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- 終了ステータス「エラー」の場合、対象件数・正常件数の初期化とエラー件数のセット
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
--    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name
--                    , iv_name         => cv_skip_rec_msg
--                    , iv_token_name1  => cv_cnt_token
--                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- 終了ステータスが「エラー」以外且つ、エラー件数が1件以上ある場合、終了ステータス「警告」にする
    IF ( ( lv_retcode <> cv_status_error ) AND ( gn_error_cnt > 0 ) ) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI001A04C;
/
