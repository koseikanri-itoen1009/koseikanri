CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A48C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A48C (body)
 * Description      : ERP CLOUDの買掛/未払金請求書のステータスに従い、
 *                  : 控除額の支払 (AP支払) 画面の消込ステータスを更新します。
 * MD.050           : 控除支払承認ステータス反映 MD050_COK_024_A48
 * Version          : 1.0
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                    Description
 * ----------------------------------------------------------------------------------------
 *  init                    A-1.初期処理
 *  get_recon_status        A-2.控除支払ステータス抽出
 *  update_recon_status     A-3.ステータス反映処理
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ(A-4.終了処理を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2024/11/28    1.0   Y.Koh            新規作成
 *
 *****************************************************************************************/
--
--###########################  固定グローバル定数宣言部 START  ###########################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--############################  固定グローバル定数宣言部 END  ############################
--
--###########################  固定グローバル変数宣言部 START  ###########################
--
  gv_out_msg       VARCHAR2(2000);            -- 出力メッセージ
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--############################  固定グローバル変数宣言部 END  ############################
--
--##############################  固定共通例外宣言部 START  ##############################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--###############################  固定共通例外宣言部 END  ###############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A48C';                    -- パッケージ名
  -- アプリケーション短縮名
  cv_xxccp_appl_name        CONSTANT VARCHAR2(10) := 'XXCCP';                           -- 共通領域短縮アプリ名
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                           -- 個別開発領域短縮アプリ名
  -- メッセージ名称
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';                -- ロックエラーメッセージ
  cv_target_err_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10881';                -- 対象件数(インポートエラー)メッセージ
  cv_target_new_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10882';                -- 対象件数(新規)メッセージ
  cv_target_rej_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10712';                -- 対象件数(却下)メッセージ
  cv_target_app_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10713';                -- 対象件数(承認)メッセージ
  cv_target_canc_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10714';                -- 対象件数(取消)メッセージ
  cv_success_err_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10883';                -- 成功件数(インポートエラー)メッセージ
  cv_success_new_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10884';                -- 成功件数(新規)メッセージ
  cv_success_rej_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10715';                -- 成功件数(却下)メッセージ
  cv_success_app_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10716';                -- 成功件数(承認)メッセージ
  cv_success_canc_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10717';                -- 成功件数(取消)メッセージ
  cv_error_rec_msg          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';                -- エラー件数メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';                -- 正常終了メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';                -- 警告終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';                -- エラー終了全ロールバック
  -- トークン
  cv_cnt_token              CONSTANT VARCHAR2(20) := 'COUNT';                           -- 件数メッセージ用トークン
  -- フラグ・区分定数
  cv_y_flag                 CONSTANT VARCHAR2(1)  := 'Y';                               -- フラグ値:Y
  cv_n_flag                 CONSTANT VARCHAR2(1)  := 'N';                               -- フラグ値:N
  cv_new_flag               CONSTANT VARCHAR2(1)  := 'N';                               -- フラグ値:NEW
  -- 控除支払ステータス
  cv_ap_status_e            CONSTANT VARCHAR2(1)  := 'E';                               -- インポートエラー
  cv_ap_status_n            CONSTANT VARCHAR2(1)  := 'N';                               -- 新規
  cv_ap_status_d            CONSTANT VARCHAR2(1)  := 'D';                               -- 否認
  cv_ap_status_a            CONSTANT VARCHAR2(1)  := 'A';                               -- 承認
  cv_ap_status_c            CONSTANT VARCHAR2(1)  := 'C';                               -- 取消
  -- 控除消込ヘッダー情報
  cv_recon_status_eg        CONSTANT VARCHAR2(2)  := 'EG';                              -- 入力中
  cv_recon_status_sd        CONSTANT VARCHAR2(2)  := 'SD';                              -- 送信済
  cv_recon_status_dd        CONSTANT VARCHAR2(2)  := 'DD';                              -- 削除済
  cv_recon_status_ad        CONSTANT VARCHAR2(2)  := 'AD';                              -- 承認済
  cv_recon_status_cd        CONSTANT VARCHAR2(2)  := 'CD';                              -- 取消済
  -- 販売控除情報
  cv_source_cate            CONSTANT VARCHAR2(1)  := 'D';                               -- 作成元区分：差額調整
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 取消伝票抽出型定義
  TYPE g_recon_status_rtype IS RECORD(
       recon_status_id      xxcok_deduction_recon_status.recon_status_id%TYPE           -- 控除支払ステータスID
      ,recon_slip_num       xxcok_deduction_recon_status.recon_slip_num%TYPE            -- 支払伝票番号
      ,status               xxcok_deduction_recon_status.status%TYPE                    -- ステータス
      ,approval_date        xxcok_deduction_recon_status.approval_date%TYPE             -- 承認日
      ,approver             per_all_people_f.employee_number%TYPE                       -- 承認者
      ,cancellation_date    xxcok_deduction_recon_status.cancellation_date%TYPE         -- 取消日
  );
  -- 取消伝票抽出ワークテーブル型定義
  TYPE g_recon_status_ttype IS TABLE OF g_recon_status_rtype INDEX BY BINARY_INTEGER;
  -- 取消伝票抽出テーブル型変数
  g_recon_status_tbl    g_recon_status_ttype;                                           -- 取消伝票抽出
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期取得
  gd_cancel_gl_date         DATE;                                                       -- 取消GL記帳日
  -- 対象件数
  gn_err_target_cnt         NUMBER;                                                     -- 対象件数(インポートエラー)
  gn_new_target_cnt         NUMBER;                                                     -- 対象件数(新規)
  gn_reject_target_cnt      NUMBER;                                                     -- 対象件数(却下)
  gn_approval_target_cnt    NUMBER;                                                     -- 対象件数(承認)
  gn_cancel_target_cnt      NUMBER;                                                     -- 対象件数(取消)
  -- 正常件数
  gn_err_normal_cnt         NUMBER;                                                     -- 成功件数(インポートエラー)
  gn_new_normal_cnt         NUMBER;                                                     -- 成功件数(新規)
  gn_reject_normal_cnt      NUMBER;                                                     -- 成功件数(却下)
  gn_approval_normal_cnt    NUMBER;                                                     -- 成功件数(承認)
  gn_cancel_normal_cnt      NUMBER;                                                     -- 成功件数(取消)
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.初期処理
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ            --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード              --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                                 -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    -- ============================================================
    -- 1.APカレンダーのOPEN月取得
    -- ============================================================
    SELECT
        MIN(gps.end_date) cancel_gl_date
    INTO
        gd_cancel_gl_date
    FROM
        gl_period_statuses  gps ,
        fnd_application     fa
    WHERE
        fa.application_short_name   =   'SQLAP'
    and gps.application_id          =   fa.application_id
    and gps.set_of_books_id         =   FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
    and CLOSING_STATUS              =   'O';
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#################################  固定例外処理部 END  #################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_recon_status
   * Description      : A-2.控除支払ステータス抽出
   ***********************************************************************************/
  PROCEDURE get_recon_status(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_recon_status';                -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
    -- 控除支払ステータス
    CURSOR recon_status_cur
    IS
      SELECT  xdrs.recon_status_id    AS  recon_status_id   , -- 控除支払ステータスID
              xdrs.recon_slip_num     AS  recon_slip_num    , -- 支払伝票番号
              xdrs.status             AS  status            , -- ステータス
              xdrs.approval_date      AS  approval_date     , -- 承認日
              papf.employee_number    AS  approver          , -- 承認者
              xdrs.cancellation_date  AS  cancellation_date   -- 取消日
      FROM    per_all_people_f        papf,                   -- 従業員
              fnd_user                fu  ,                   -- ユーザー
              xxcok_deduction_recon_status    xdrs            -- 控除支払ステータステーブル
      WHERE   xdrs.processed_flag = cv_n_flag                 -- 処理済フラグ
      AND     fu.user_name(+)     = xdrs.approver
      AND     papf.PERSON_ID(+)   = fu.EMPLOYEE_ID
      AND     trunc(sysdate)      between papf.EFFECTIVE_START_DATE(+)  and papf.EFFECTIVE_END_DATE(+)
      ORDER BY recon_status_id
      ;
    -- *** ローカル・レコード ***
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    -- ============================================================
    -- 取消伝票情報取得
    -- ============================================================
    -- カーソルオープン
    OPEN  recon_status_cur;
    -- データ取得
    FETCH recon_status_cur BULK COLLECT INTO g_recon_status_tbl;
    -- カーソルクローズ
    CLOSE recon_status_cur;
--
  EXCEPTION
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( recon_status_cur%ISOPEN ) THEN
        CLOSE recon_status_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( recon_status_cur%ISOPEN ) THEN
        CLOSE recon_status_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( recon_status_cur%ISOPEN ) THEN
        CLOSE recon_status_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 END  #################################
--
  END get_recon_status;
--
  /**********************************************************************************
   * Procedure Name   : update_recon_status
   * Description      : A-3.ステータス反映処理
   ***********************************************************************************/
  PROCEDURE update_recon_status(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_recon_status';             -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_dummy            NUMBER;
    -- *** ローカル例外 ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    -- 取消伝票抽出件数分ステータス反映処理を実行
    <<update_recon_status_loop>>
    FOR ln_get_cnt IN 1..g_recon_status_tbl.COUNT LOOP
--
      BEGIN
--
        -- 控除消込ヘッダーロック処理
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcok_deduction_recon_head    xdrh -- 控除消込ヘッダー情報
        WHERE  xdrh.recon_slip_num           = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
        ;
--
        -- 販売控除情報ロック処理
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcok_sales_deduction         xsd  -- 販売控除情報
        WHERE  xsd.recon_slip_num            = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        FOR UPDATE OF xsd.sales_deduction_id NOWAIT
        ;
--
      EXCEPTION
        -- ロックエラー
        WHEN lock_expt THEN
          -- ロックエラーメッセージ
          lv_errmsg      := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                     ,cv_table_lock_msg
                                                     );
          lv_errbuf      := lv_errmsg;
          ov_errmsg      := lv_errmsg;
          ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode     := cv_status_error;
          RAISE global_process_expt;
        WHEN OTHERS THEN
          NULL;
      END;
--
      IF    g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_e  THEN -- インポートエラー
--
        -- 対象件数(インポートエラー)をインクリメント
        gn_err_target_cnt := gn_err_target_cnt + 1;
--
        -- 控除消込ヘッダー情報の消込ステータスを更新
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- 控除消込ヘッダー情報
        SET     xdrh.recon_status           = cv_recon_status_eg                          , -- 消込スタータス
                ap_ar_if_flag               = cv_n_flag                                   , -- AP/AR連携フラグ
                xdrh.last_updated_by        = cn_last_updated_by                          , -- 最終更新者
                xdrh.last_update_date       = cd_last_update_date                         , -- 最終更新日
                xdrh.last_update_login      = cn_last_update_login                        , -- 最終更新ログイン
                xdrh.request_id             = cn_request_id                               , -- 要求ID
                xdrh.program_application_id = cn_program_application_id                   , -- コンカレント・プログラム・アプリケーションID
                xdrh.program_id             = cn_program_id                               , -- コンカレント・プログラムID
                xdrh.program_update_date    = cd_program_update_date                        -- プログラム更新日
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- 成功件数(インポートエラー)をインクリメント
        gn_err_normal_cnt := gn_err_normal_cnt + 1;
--
      ELSIF g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_n  THEN -- 新規
--
        -- 対象件数(新規)をインクリメント
        gn_new_target_cnt := gn_new_target_cnt + 1;
--
        -- 控除消込ヘッダー情報の消込ステータスを更新
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- 控除消込ヘッダー情報
        SET     xdrh.recon_status           = cv_recon_status_sd                          , -- 消込スタータス
                xdrh.last_updated_by        = cn_last_updated_by                          , -- 最終更新者
                xdrh.last_update_date       = cd_last_update_date                         , -- 最終更新日
                xdrh.last_update_login      = cn_last_update_login                        , -- 最終更新ログイン
                xdrh.request_id             = cn_request_id                               , -- 要求ID
                xdrh.program_application_id = cn_program_application_id                   , -- コンカレント・プログラム・アプリケーションID
                xdrh.program_id             = cn_program_id                               , -- コンカレント・プログラムID
                xdrh.program_update_date    = cd_program_update_date                        -- プログラム更新日
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- 成功件数(新規)をインクリメント
        gn_new_normal_cnt := gn_new_normal_cnt + 1;
--
      ELSIF g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_d  THEN -- 却下
--
        -- 対象件数(却下)をインクリメント
        gn_reject_target_cnt := gn_reject_target_cnt + 1;
--
        -- 控除消込ヘッダー情報の消込ステータスを更新
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- 控除消込ヘッダー情報
        SET     xdrh.recon_status           = cv_recon_status_dd                          , -- 消込スタータス
                xdrh.last_updated_by        = cn_last_updated_by                          , -- 最終更新者
                xdrh.last_update_date       = cd_last_update_date                         , -- 最終更新日
                xdrh.last_update_login      = cn_last_update_login                        , -- 最終更新ログイン
                xdrh.request_id             = cn_request_id                               , -- 要求ID
                xdrh.program_application_id = cn_program_application_id                   , -- コンカレント・プログラム・アプリケーションID
                xdrh.program_id             = cn_program_id                               , -- コンカレント・プログラムID
                xdrh.program_update_date    = cd_program_update_date                        -- プログラム更新日
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- 該当支払の控除データを開放
        UPDATE  xxcok_sales_deduction        xsd                                            -- 販売控除情報
        SET     xsd.recon_slip_num           = NULL                                       , -- 支払伝票番号
                xsd.carry_payment_slip_num   = NULL                                       , -- 繰越時支払伝票番号
                xsd.last_updated_by          = cn_last_updated_by                         , -- 最終更新者
                xsd.last_update_date         = cd_last_update_date                        , -- 最終更新日
                xsd.last_update_login        = cn_last_update_login                       , -- 最終更新ログイン
                xsd.request_id               = cn_request_id                              , -- 要求ID
                xsd.program_application_id   = cn_program_application_id                  , -- コンカレント・プログラム・アプリケーションID
                xsd.program_id               = cn_program_id                              , -- コンカレント・プログラムID
                xsd.program_update_date      = cd_program_update_date                       -- プログラム更新日
        WHERE   xsd.recon_slip_num           = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        AND     xsd.status                   = cv_new_flag
        ;
--
        -- 成功件数(却下)をインクリメント
        gn_reject_normal_cnt := gn_reject_normal_cnt + 1;
--
      ELSIF g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_a  THEN -- 承認
--
        -- 対象件数(承認)をインクリメント
        gn_approval_target_cnt := gn_approval_target_cnt + 1;
--
        -- 控除消込ヘッダー情報の消込ステータスを更新
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- 控除消込ヘッダー情報
        SET     xdrh.recon_status           = cv_recon_status_ad                          , -- 消込スタータス
                approval_date               = g_recon_status_tbl(ln_get_cnt).approval_date, -- 承認日
                approver                    = g_recon_status_tbl(ln_get_cnt).approver     , -- 承認者
                xdrh.last_updated_by        = cn_last_updated_by                          , -- 最終更新者
                xdrh.last_update_date       = cd_last_update_date                         , -- 最終更新日
                xdrh.last_update_login      = cn_last_update_login                        , -- 最終更新ログイン
                xdrh.request_id             = cn_request_id                               , -- 要求ID
                xdrh.program_application_id = cn_program_application_id                   , -- コンカレント・プログラム・アプリケーションID
                xdrh.program_id             = cn_program_id                               , -- コンカレント・プログラムID
                xdrh.program_update_date    = cd_program_update_date                        -- プログラム更新日
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- 控除データ差額金額調整を実行
        XXCOK024A19C.main( lv_errbuf
                          ,lv_retcode
                          ,lv_errmsg
                          ,g_recon_status_tbl(ln_get_cnt).recon_slip_num
                          );
--
        IF ( lv_retcode = cv_status_error ) THEN
          lv_errmsg :=  '差額金額調整:'  ||  lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        -- 成功件数(承認)をインクリメント
        gn_approval_normal_cnt := gn_approval_normal_cnt + 1;
--
      ELSIF g_recon_status_tbl(ln_get_cnt).status  = cv_ap_status_c  THEN -- 取消
--
        -- 対象件数(取消)をインクリメント
        gn_cancel_target_cnt := gn_cancel_target_cnt + 1;
--
        -- 控除消込ヘッダー情報の消込ステータスを更新
        UPDATE  xxcok_deduction_recon_head   xdrh                                           -- 控除消込ヘッダー情報
        SET     xdrh.recon_status           = DECODE(xdrh.recon_status, cv_recon_status_ad, cv_recon_status_cd, cv_recon_status_dd)
                                                                                          , -- 消込スタータス
                xdrh.cancellation_date      = DECODE(xdrh.recon_status, cv_recon_status_ad, g_recon_status_tbl(ln_get_cnt).cancellation_date, xdrh.cancellation_date)
                                                                                          , -- 取消日
                xdrh.cancel_gl_date         = DECODE(xdrh.recon_status, cv_recon_status_ad, DECODE(xdrh.gl_if_flag, cv_n_flag, xdrh.gl_date, gd_cancel_gl_date), xdrh.cancel_gl_date)
                                                                                          , -- 取消GL記帳日
                xdrh.last_updated_by        = cn_last_updated_by                          , -- 最終更新者
                xdrh.last_update_date       = cd_last_update_date                         , -- 最終更新日
                xdrh.last_update_login      = cn_last_update_login                        , -- 最終更新ログイン
                xdrh.request_id             = cn_request_id                               , -- 要求ID
                xdrh.program_application_id = cn_program_application_id                   , -- コンカレント・プログラム・アプリケーションID
                xdrh.program_id             = cn_program_id                               , -- コンカレント・プログラムID
                xdrh.program_update_date    = cd_program_update_date                        -- プログラム更新日
        WHERE   xdrh.recon_slip_num         = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        ;
--
        -- 該当支払の差額調整データを取消済に更新
        UPDATE  xxcok_sales_deduction        xsd                                            -- 販売控除情報
        SET     xsd.status                   = 'C'                                        , -- ステータス
                xsd.recovery_del_date        = SYSDATE                                    , -- リカバリデータ削除時日付
                xsd.cancel_flag              = cv_y_flag                                  , -- 取消フラグ
                xsd.last_updated_by          = cn_last_updated_by                         , -- 最終更新者
                xsd.last_update_date         = cd_last_update_date                        , -- 最終更新日
                xsd.last_update_login        = cn_last_update_login                       , -- 最終更新ログイン
                xsd.request_id               = cn_request_id                              , -- 要求ID
                xsd.program_application_id   = cn_program_application_id                  , -- コンカレント・プログラム・アプリケーションID
                xsd.program_id               = cn_program_id                              , -- コンカレント・プログラムID
                xsd.program_update_date      = cd_program_update_date                       -- プログラム更新日
        WHERE   xsd.recon_slip_num           = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        AND     xsd.source_category          = cv_source_cate
        ;
--
        -- 該当支払の控除データを開放
        UPDATE  xxcok_sales_deduction        xsd                                            -- 販売控除情報
        SET     xsd.recon_slip_num           = NULL                                       , -- 支払伝票番号
                xsd.carry_payment_slip_num   = NULL                                       , -- 繰越時支払伝票番号
                xsd.last_updated_by          = cn_last_updated_by                         , -- 最終更新者
                xsd.last_update_date         = cd_last_update_date                        , -- 最終更新日
                xsd.last_update_login        = cn_last_update_login                       , -- 最終更新ログイン
                xsd.request_id               = cn_request_id                              , -- 要求ID
                xsd.program_application_id   = cn_program_application_id                  , -- コンカレント・プログラム・アプリケーションID
                xsd.program_id               = cn_program_id                              , -- コンカレント・プログラムID
                xsd.program_update_date      = cd_program_update_date                       -- プログラム更新日
        WHERE   xsd.recon_slip_num           = g_recon_status_tbl(ln_get_cnt).recon_slip_num
        AND     xsd.status                   = cv_new_flag
        ;
--
        -- 成功件数(取消)をインクリメント
        gn_cancel_normal_cnt := gn_cancel_normal_cnt + 1;
--
      END IF;
--
      -- 控除支払ステータステーブルの処理済フラグを更新
      UPDATE  xxcok_deduction_recon_status  xdrs                                            -- 控除支払ステータステーブル
      SET     xdrs.processed_flag         = cv_y_flag                                     , -- 処理済フラグ
              xdrs.last_updated_by        = cn_last_updated_by                            , -- 最終更新者
              xdrs.last_update_date       = cd_last_update_date                           , -- 最終更新日
              xdrs.last_update_login      = cn_last_update_login                          , -- 最終更新ログイン
              xdrs.request_id             = cn_request_id                                 , -- 要求ID
              xdrs.program_application_id = cn_program_application_id                     , -- コンカレント・プログラム・アプリケーションID
              xdrs.program_id             = cn_program_id                                 , -- コンカレント・プログラムID
              xdrs.program_update_date    = cd_program_update_date                          -- プログラム更新日
      WHERE   xdrs.recon_status_id        = g_recon_status_tbl(ln_get_cnt).recon_status_id
      ;
--
    END LOOP update_recon_status_loop;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#################################  固定例外処理部 END  #################################
--
  END update_recon_status;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
                    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
                    ,ov_errmsg       OUT VARCHAR2 )        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                                       -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);                                        -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                                           -- リターン・コード
    lv_errmsg  VARCHAR2(5000);                                        -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END  #####################################
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
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END  #####################################
--
    -- グローバル変数の初期化
    gn_error_cnt                  := 0;                   -- エラー件数
    gn_err_target_cnt             := 0;                   -- 対象件数(インポートエラー)
    gn_new_target_cnt             := 0;                   -- 対象件数(新規)
    gn_reject_target_cnt          := 0;                   -- 対象件数(却下)
    gn_approval_target_cnt        := 0;                   -- 対象件数(承認)
    gn_cancel_target_cnt          := 0;                   -- 対象件数(取消)
    gn_err_normal_cnt             := 0;                   -- 成功件数(インポートエラー)
    gn_new_normal_cnt             := 0;                   -- 成功件数(新規)
    gn_reject_normal_cnt          := 0;                   -- 成功件数(却下)
    gn_approval_normal_cnt        := 0;                   -- 成功件数(承認)
    gn_cancel_normal_cnt          := 0;                   -- 成功件数(取消)
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init( ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
         ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
         ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.控除支払ステータス抽出
    -- ===============================
    get_recon_status(
        ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
       ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
       ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.ステータス反映処理
    -- ===============================
    update_recon_status(
        ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
       ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
       ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
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
--#####################################  固定部 END  #####################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
--
  PROCEDURE main( errbuf           OUT VARCHAR2               -- エラー・メッセージ  --# 固定 #
                 ,retcode          OUT VARCHAR2      )        -- リターン・コード    --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                             -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf          VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);         -- リターン・コード
    lv_errmsg          VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);       -- 終了メッセージコード
--
--#####################################  固定部 END  #####################################
--
  BEGIN
--
--####################################  固定部 START  ####################################--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
       ,ov_errbuf  => lv_errbuf
       ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--#####################################  固定部 END  #####################################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain( ov_errbuf        => lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,ov_retcode       => lv_retcode        -- リターン・コード             --# 固定 #
            ,ov_errmsg        => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
    -- ===============================
    -- A-4.終了処理
    -- ===============================
--
    -- エラー発生時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_err_target_cnt      := 0;
      gn_new_target_cnt      := 0;
      gn_reject_target_cnt   := 0;
      gn_approval_target_cnt := 0;
      gn_cancel_target_cnt   := 0;
      gn_err_normal_cnt      := 0;
      gn_new_normal_cnt      := 0;
      gn_reject_normal_cnt   := 0;
      gn_approval_normal_cnt := 0;
      gn_cancel_normal_cnt   := 0;
      gn_error_cnt           := 1;
    END IF;
--
    --エラー出力
    IF (lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --エラーメッセージ
      );
    END IF;
--
    -- ===============================
    -- 1.処理件数メッセージ出力
    -- ===============================
    -- 対象件数出力(インポートエラー)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_err_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_err_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 対象件数出力(新規)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_new_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_new_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 対象件数出力(却下)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_rej_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_reject_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 対象件数出力(承認)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_app_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_approval_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 対象件数出力(取消)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_target_canc_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_cancel_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- 成功件数出力(インポートエラー)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_err_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_err_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 成功件数出力(承認)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_new_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_new_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 成功件数出力(新規)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_rej_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_reject_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 成功件数出力(承認)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_app_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_approval_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 成功件数出力(取消)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_success_canc_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_cancel_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_error_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ===============================
    -- 2.処理終了メッセージ
    -- ===============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                           ,iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
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
--
--#####################################  固定部 END  #####################################
--
  END main;
--
END XXCOK024A48C;
/
