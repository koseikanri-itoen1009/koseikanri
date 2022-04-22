CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A25C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A25C (body)
 * Description      : AP部門入力の伝票のステータスに従い、
 *                  : 控除額の支払 (AP支払) 画面の消込ステータスを更新します。
 * MD.050           : AP部門入力連携 MD050_COK_024_A25
 * Version          : 1.2
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                    Description
 * ----------------------------------------------------------------------------------------
 *  init                    A-1.初期処理
 *  get_recon_header        A-2.控除消込ヘッダー情報抽出
 *  status_reflect_rej_appr A-3.ステータス反映処理 (却下・承認)
 *  get_cancel_slip         A-4.取消伝票抽出
 *  status_reflect_cancel   A-5.ステータス反映処理 (取消)
 *  update_sales_dedu_ctrl  A-6.販売控除管理情報更新
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ(A-7.終了処理を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/05/15    1.0   M.Sato           新規作成
 *  2021/09/27    1.1   K.Yoshikawa      E_本稼動_17557
 *  2022/04/19    1.2   SCSK Y.Koh       E_本稼動_18172  控除支払伝票取消時の差額
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
  cv_pkg_name              CONSTANT VARCHAR2(20) := 'XXCOK024A25C';                   -- パッケージ名
  -- アプリケーション短縮名
  cv_xxccp_appl_name       CONSTANT VARCHAR2(10) := 'XXCCP';                          -- 共通領域短縮アプリ名
  cv_xxcok_short_nm        CONSTANT VARCHAR2(10) := 'XXCOK';                          -- 個別開発領域短縮アプリ名
  -- メッセージ名称
  cv_last_process_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10592';               -- 前回処理情報取得エラー
  cv_table_lock_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';               -- ロックエラーメッセージ
  cv_target_rej_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10712';               -- 対象件数(却下)メッセージ
  cv_target_app_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10713';               -- 対象件数(承認)メッセージ
  cv_target_canc_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10714';               -- 対象件数(取消)メッセージ
  cv_success_rej_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10715';               -- 成功件数(却下)メッセージ
  cv_success_app_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10716';               -- 成功件数(承認)メッセージ
  cv_success_canc_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10717';               -- 成功件数(取消)メッセージ
  cv_error_rec_msg         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';               -- エラー件数メッセージ
  cv_normal_msg            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';               -- 正常終了メッセージ
  cv_warn_msg              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';               -- 警告終了メッセージ
  cv_error_msg             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';               -- エラー終了全ロールバック
  -- トークン
  cv_cnt_token             CONSTANT VARCHAR2(20) := 'COUNT';                          -- 件数メッセージ用トークン
  -- フラグ・区分定数
  cv_y_flag                CONSTANT VARCHAR2(1)  := 'Y';                              -- フラグ値:Y
  -- 販売控除連携管理情報
  cv_ap_input_flag         CONSTANT VARCHAR2(1)  := 'P';                              -- AP部門入力情報
  -- 控除消込ヘッダー情報
  cv_interface_div         CONSTANT VARCHAR2(2)  := 'AP';                             -- AP支払
  cv_recon_status_transmit CONSTANT VARCHAR2(2)  := 'SD';                             -- 送信済
  cv_recon_status_deleted  CONSTANT VARCHAR2(2)  := 'DD';                             -- 削除済
  cv_recon_status_appr     CONSTANT VARCHAR2(2)  := 'AD';                             -- 承認済
  cv_recon_status_cancel   CONSTANT VARCHAR2(2)  := 'CD';                             -- 取消済
  -- AP部門入力
  cv_ap_status_reject      CONSTANT VARCHAR2(2)  := '10';                             -- 却下
  cv_ap_status_appr        CONSTANT VARCHAR2(2)  := '80';                             -- 承認済
  cv_slip_type             CONSTANT VARCHAR2(10) := '30000';                          -- 販売控除
  -- 販売控除情報
  cv_source_cate           CONSTANT VARCHAR2(1)  := 'D';                              -- 作成元区分：差額調整
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 控除消込ヘッダ抽出レコード型定義
  TYPE g_recon_header_rtype IS RECORD(
       recon_head_id       xxcok_deduction_recon_head.deduction_recon_head_id%TYPE    -- 控除消込ヘッダーID
      ,recon_slip_num      xxcok_deduction_recon_head.recon_slip_num%TYPE             -- 支払伝票番号
  );
  -- 控除消込ヘッダ抽出ワークテーブル型定義
  TYPE g_recon_head_ttype IS TABLE OF g_recon_header_rtype INDEX BY BINARY_INTEGER;
  -- 控除消込ヘッダ抽出テーブル型変数
  g_recon_head_tbl         g_recon_head_ttype;                                        -- 控除消込ヘッダ抽出
--
  -- AP部門入力抽出レコード型定義
  TYPE g_ap_input_rtype IS RECORD(
       status              xx03_payment_slips.wf_status%TYPE                          -- ステータス
      ,approval_date       xx03_payment_slips.approval_date%TYPE                      -- 承認日
      ,approver            per_all_people_f.employee_number%TYPE                      -- 承認者
  );
  -- AP部門入力抽出ワークテーブル型定義
  TYPE g_ap_input_ttype IS TABLE OF g_ap_input_rtype INDEX BY BINARY_INTEGER;
  -- AP部門入力抽出テーブル型変数
  g_ap_input_tbl           g_ap_input_ttype;                                          -- AP部門入力ステータス抽出
--
  -- 取消伝票抽出型定義
  TYPE g_cancel_slip_rtype IS RECORD(
       recon_slip_num      xx03_payment_slips.description%TYPE                        -- 支払伝票番号
      ,approval_date       xx03_payment_slips.approval_date%TYPE                      -- 承認日
  );
  -- 取消伝票抽出ワークテーブル型定義
  TYPE g_cancel_slip_ttype IS TABLE OF g_cancel_slip_rtype INDEX BY BINARY_INTEGER;
  -- 取消伝票抽出テーブル型変数
  g_cancel_slip_tbl        g_cancel_slip_ttype;                                       -- 取消伝票抽出
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期取得
  gd_last_process_date          DATE;                                                 -- 前回処理日時
  gd_this_process_date          DATE;                                                 -- 今回処理日時
-- 2022/04/19 Ver1.2 ADD Start
  gd_cancel_gl_date             DATE;                                                 -- 取消GL記帳日
-- 2022/04/19 Ver1.2 ADD End
  -- 対象件数
  gn_reject_target_cnt          NUMBER;                                               -- 対象件数(却下)
  gn_approval_target_cnt        NUMBER;                                               -- 対象件数(承認)
  gn_cancel_target_cnt          NUMBER;                                               -- 対象件数(取消)
  -- 正常件数
  gn_reject_normal_cnt          NUMBER;                                               -- 成功件数(却下)
  gn_approval_normal_cnt        NUMBER;                                               -- 成功件数(承認)
  gn_cancel_normal_cnt          NUMBER;                                               -- 成功件数(取消)
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
    -- 1.前回の処理日時を取得
    -- ============================================================
    BEGIN
    --
      SELECT  xsdc.last_cooperation_date    AS last_cooperation_date
      INTO    gd_last_process_date                -- 前回処理日時
      FROM    xxcok_sales_deduction_control xsdc  -- 販売控除連携管理情報
      WHERE   xsdc.control_flag             = cv_ap_input_flag
      ;
    --
    EXCEPTION
      WHEN  OTHERS THEN
        -- 前回処理情報取得エラーメッセージ
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_last_process_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ============================================================
    -- 2.今回の処理日時を取得
    -- ============================================================
    gd_this_process_date  := SYSDATE;           -- 今回処理日時
-- 2022/04/19 Ver1.2 ADD Start
    -- ============================================================
    -- 3.AP部門入力カレンダーのOPEN月取得
    -- ============================================================
    SELECT
        MIN(gps.end_date)
    INTO
        gd_cancel_gl_date
    FROM
        gl_period_statuses  gps ,
        fnd_application     fa
    WHERE
        fa.application_short_name   =   'SQLGL'
    and gps.application_id          =   fa.application_id
    and gps.set_of_books_id         =   FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
    and gps.end_date                >=  TO_DATE('2010/01/01','YYYY/MM/DD')
    and gps.adjustment_period_flag  =   'N'
    and NVL(gps.attribute1,'O')     =   'O';
-- 2022/04/19 Ver1.2 ADD End
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
   * Procedure Name   : status_reflect_rej_appr
   * Description      : A-3.ステータス反映処理 (却下・承認)
   ***********************************************************************************/
  PROCEDURE status_reflect_rej_appr(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
                 ,in_get_cnt    IN  NUMBER   )   --   反映処理回数
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'status_reflect_rej_appr';             -- プログラム名
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
    ln_request_id               NUMBER;                                     -- 戻り値：要求ID
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
    -- AP部門入力抽出カーソル
    CURSOR ap_input_cur
    IS
      SELECT xps.wf_status                AS status                         -- ステータス
            ,xps.approval_date            AS approval_date                  -- 承認日
            ,papf.employee_number         AS approver                       -- 承認者
      FROM   xx03_payment_slips           xps                               -- AP部門入力
            ,per_all_people_f             papf                              -- 従業員
      WHERE  xps.description              = g_recon_head_tbl(in_get_cnt).recon_slip_num
      AND    xps.wf_status               != cv_ap_status_reject
      AND    xps.orig_invoice_num         IS NULL
      AND    papf.person_id(+)            = xps.approver_person_id
      AND    TRUNC( SYSDATE )       BETWEEN papf.effective_start_date(+)
                                        AND papf.effective_end_date(+)
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
    -- 処理対象伝票のAP部門入力ステータスを取得
    -- ============================================================
    -- カーソルオープン
    OPEN  ap_input_cur;
    -- データ取得
    FETCH ap_input_cur BULK COLLECT INTO g_ap_input_tbl;
    -- カーソルクローズ
    CLOSE ap_input_cur;
--
    -- 取得件数が0件の場合
    IF ( g_ap_input_tbl.COUNT = 0 ) THEN
      -- 対象件数(却下)をインクリメント
      gn_reject_target_cnt := gn_reject_target_cnt + 1;
      -- 控除消込ヘッダー情報のステータスを「削除済」に更新
      UPDATE  xxcok_deduction_recon_head   xdrh                             -- 控除消込ヘッダー情報
      SET     xdrh.recon_status            = cv_recon_status_deleted        -- 消込スタータス
             ,xdrh.last_updated_by         = cn_last_updated_by             -- 最終更新者
             ,xdrh.last_update_date        = cd_last_update_date            -- 最終更新日
             ,xdrh.last_update_login       = cn_last_update_login           -- 最終更新ログイン
             ,xdrh.request_id              = cn_request_id                  -- 要求ID
             ,xdrh.program_application_id  = cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
             ,xdrh.program_id              = cn_program_id                  -- コンカレント・プログラムID
             ,xdrh.program_update_date     = cd_program_update_date         -- プログラム更新日
      WHERE   xdrh.deduction_recon_head_id = g_recon_head_tbl(in_get_cnt).recon_head_id
      ;
      -- 該当支払の控除データを開放
      UPDATE  xxcok_sales_deduction        xsd                              -- 販売控除情報
      SET     xsd.recon_slip_num           = NULL                           -- 支払伝票番号
             ,xsd.carry_payment_slip_num   = NULL                           -- 繰越時支払伝票番号
             ,xsd.last_updated_by          = cn_last_updated_by             -- 最終更新者
             ,xsd.last_update_date         = cd_last_update_date            -- 最終更新日
             ,xsd.last_update_login        = cn_last_update_login           -- 最終更新ログイン
             ,xsd.request_id               = cn_request_id                  -- 要求ID
             ,xsd.program_application_id   = cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
             ,xsd.program_id               = cn_program_id                  -- コンカレント・プログラムID
             ,xsd.program_update_date      = cd_program_update_date         -- プログラム更新日
      WHERE   xsd.recon_slip_num           = g_recon_head_tbl(in_get_cnt).recon_slip_num
      ;
      -- 成功件数(却下)をインクリメント
      gn_reject_normal_cnt := gn_reject_normal_cnt + 1;
--
    -- 取得ステータスが承認済の場合
    ELSIF ( g_ap_input_tbl(1).status = cv_ap_status_appr ) THEN
      -- 対象件数(承認)をインクリメント
      gn_approval_target_cnt := gn_approval_target_cnt + 1;
      -- 控除消込ヘッダー情報のステータスを「承認済」に更新
      UPDATE  xxcok_deduction_recon_head   xdrh                             -- 控除消込ヘッダー情報
      SET     xdrh.recon_status            = cv_recon_status_appr           -- 消込スタータス
             ,xdrh.approval_date           = TRUNC( g_ap_input_tbl(1).approval_date )
                                                                            -- 承認日
             ,xdrh.approver                = g_ap_input_tbl(1).approver     -- 承認者
             ,xdrh.ap_ar_if_flag           = cv_y_flag                      -- AP/AR連携フラグ
             ,xdrh.last_updated_by         = cn_last_updated_by             -- 最終更新者
             ,xdrh.last_update_date        = cd_last_update_date            -- 最終更新日
             ,xdrh.last_update_login       = cn_last_update_login           -- 最終更新ログイン
             ,xdrh.request_id              = cn_request_id                  -- 要求ID
             ,xdrh.program_application_id  = cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
             ,xdrh.program_id              = cn_program_id                  -- コンカレント・プログラムID
             ,xdrh.program_update_date     = cd_program_update_date         -- プログラム更新日
      WHERE   xdrh.deduction_recon_head_id = g_recon_head_tbl(in_get_cnt).recon_head_id
      ;
      -- 成功件数(承認)をインクリメント
      gn_approval_normal_cnt := gn_approval_normal_cnt + 1;
      -- 控除データ差額金額調整を実行
      XXCOK024A19C.main( lv_errbuf
                        ,lv_retcode
                        ,lv_errmsg
                        ,g_recon_head_tbl(in_get_cnt).recon_slip_num
                        );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( ap_input_cur%ISOPEN ) THEN
        CLOSE ap_input_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( ap_input_cur%ISOPEN ) THEN
        CLOSE ap_input_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( ap_input_cur%ISOPEN ) THEN
        CLOSE ap_input_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 END  #################################
--
  END status_reflect_rej_appr;
--
  /**********************************************************************************
   * Procedure Name   : get_recon_header
   * Description      : A-2.控除消込ヘッダー情報抽出
   ***********************************************************************************/
  PROCEDURE get_recon_header(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_recon_header';                    -- プログラム名
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
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
    -- *** ローカル・カーソル ***
    -- 控除消込ヘッダ抽出カーソル
    CURSOR recon_head_cur
    IS
      SELECT xdrh.deduction_recon_head_id  AS recon_head_id           -- 控除消込ヘッダーID
            ,xdrh.recon_slip_num           AS recon_slip_num          -- 支払伝票番号
      FROM   xxcok_deduction_recon_head    xdrh                       -- 控除消込ヘッダー情報
      WHERE  xdrh.interface_div            = cv_interface_div
      AND    xdrh.recon_status             = cv_recon_status_transmit
      FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
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
    -- 処理対象消込ヘッダ情報取得
    -- ============================================================
    -- カーソルオープン
    OPEN  recon_head_cur;
    -- データ取得
    FETCH recon_head_cur BULK COLLECT INTO g_recon_head_tbl;
    -- カーソルクローズ
    CLOSE recon_head_cur;
--
    -- 控除消込ヘッダの抽出件数が0件以上の場合
    IF ( g_recon_head_tbl.COUNT > 0 ) THEN
      -- 抽出件数分ステータス反映処理を実行
      <<reflect_rej_appr_loop>>
      FOR ln_get_cnt IN 1..g_recon_head_tbl.COUNT LOOP
        -- ===============================
        -- A-3.ステータス反映処理 (却下・承認)
        -- ===============================
        status_reflect_rej_appr(
            ov_errbuf   => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
           ,ov_retcode  => lv_retcode           -- リターン・コード             -- # 固定 #
           ,ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
           ,in_get_cnt  => ln_get_cnt           -- 反映処理回数
        );
      END LOOP reflect_rej_appr_loop;
    END IF;
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      -- カーソルクローズ
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      -- ロックエラーメッセージ
      lv_errmsg      := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                 ,cv_table_lock_msg
                                                 );
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode     := cv_status_error;
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 END  #################################
--
  END get_recon_header;
--
  /**********************************************************************************
   * Procedure Name   : get_cancel_slip
   * Description      : A-4.取消伝票抽出
   ***********************************************************************************/
  PROCEDURE get_cancel_slip(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cancel_slip';                     -- プログラム名
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
    -- 取消伝票抽出カーソル
    CURSOR cancel_slip_cur
    IS
      SELECT xpss.description       AS recon_slip_num       -- 支払伝票番号
            ,xpsc.approval_date     AS approval_date        -- 承認日
      FROM   xx03_payment_slips     xpss,                   -- AP部門入力(元伝票)
             xx03_payment_slips     xpsc                    -- AP部門入力(取消伝票)
      WHERE  xpsc.slip_type         =   cv_slip_type
      AND    xpsc.wf_status         =   cv_ap_status_appr
-- 2021/09/27 Ver1.1 MOD Start
--      AND    xpsc.last_update_date  >   gd_last_process_date
--      AND    xpsc.last_update_date  <=  gd_this_process_date
      AND    xpsc.approval_date  >   gd_last_process_date
      AND    xpsc.approval_date  <=  gd_this_process_date
-- 2021/09/27 Ver1.1 MOD End
      AND    xpss.invoice_num       =   xpsc.orig_invoice_num
      AND    xpss.org_id            =   xpsc.org_id
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
    OPEN  cancel_slip_cur;
    -- データ取得
    FETCH cancel_slip_cur BULK COLLECT INTO g_cancel_slip_tbl;
    -- カーソルクローズ
    CLOSE cancel_slip_cur;
    -- 対象件数(取消)に抽出件数を格納
    gn_cancel_target_cnt := g_cancel_slip_tbl.COUNT;
--
  EXCEPTION
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( cancel_slip_cur%ISOPEN ) THEN
        CLOSE cancel_slip_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( cancel_slip_cur%ISOPEN ) THEN
        CLOSE cancel_slip_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( cancel_slip_cur%ISOPEN ) THEN
        CLOSE cancel_slip_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 END  #################################
--
  END get_cancel_slip;
--
  /**********************************************************************************
   * Procedure Name   : status_reflect_cancel
   * Description      : A-5.ステータス反映処理 (取消)
   ***********************************************************************************/
  PROCEDURE status_reflect_cancel(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'status_reflect_cancel';               -- プログラム名
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
    <<reflect_cancel_loop>>
    FOR ln_get_cnt IN 1..g_cancel_slip_tbl.COUNT LOOP
      BEGIN
        -- 控除消込ヘッダーロック処理
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcok_deduction_recon_head    xdrh                       -- 控除消込ヘッダー情報
        WHERE  xdrh.recon_slip_num           = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
        FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
        ;
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
      BEGIN
        -- 販売控除情報ロック処理
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcok_sales_deduction         xsd                        -- 販売控除情報
        WHERE  xsd.recon_slip_num            = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
        FOR UPDATE OF xsd.sales_deduction_id NOWAIT
        ;
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
      -- 控除消込ヘッダー情報の消込ステータスを更新
      UPDATE  xxcok_deduction_recon_head   xdrh                             -- 控除消込ヘッダー情報
      SET     xdrh.recon_status            = cv_recon_status_cancel         -- 消込スタータス
             ,xdrh.cancellation_date       = TRUNC( g_cancel_slip_tbl(ln_get_cnt).approval_date )
                                                                            -- 取消日
-- 2022/04/19 Ver1.2 ADD Start
             ,xdrh.cancel_gl_date          = DECODE(xdrh.gl_if_flag, 'N', xdrh.gl_date, gd_cancel_gl_date)
                                                                            -- 取消GL記帳日
-- 2022/04/19 Ver1.2 ADD End
             ,xdrh.last_updated_by         = cn_last_updated_by             -- 最終更新者
             ,xdrh.last_update_date        = cd_last_update_date            -- 最終更新日
             ,xdrh.last_update_login       = cn_last_update_login           -- 最終更新ログイン
             ,xdrh.request_id              = cn_request_id                  -- 要求ID
             ,xdrh.program_application_id  = cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
             ,xdrh.program_id              = cn_program_id                  -- コンカレント・プログラムID
             ,xdrh.program_update_date     = cd_program_update_date         -- プログラム更新日
      WHERE   xdrh.recon_slip_num          = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
      ;
      -- 成功件数(取消)をインクリメント
      gn_cancel_normal_cnt := gn_cancel_normal_cnt + 1;
--
      -- 該当支払の差額調整データを取消済に更新
      UPDATE  xxcok_sales_deduction        xsd                              -- 販売控除情報
      SET     xsd.status                   = 'C'                            -- ステータス
             ,xsd.recovery_del_date        = SYSDATE                        -- リカバリデータ削除時日付
             ,xsd.cancel_flag              = cv_y_flag                      -- 取消フラグ
             ,xsd.last_updated_by          = cn_last_updated_by             -- 最終更新者
             ,xsd.last_update_date         = cd_last_update_date            -- 最終更新日
             ,xsd.last_update_login        = cn_last_update_login           -- 最終更新ログイン
             ,xsd.request_id               = cn_request_id                  -- 要求ID
             ,xsd.program_application_id   = cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
             ,xsd.program_id               = cn_program_id                  -- コンカレント・プログラムID
             ,xsd.program_update_date      = cd_program_update_date         -- プログラム更新日
      WHERE   xsd.recon_slip_num           = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
      AND     xsd.source_category          = cv_source_cate
      ;
--
      -- 該当支払の控除データを開放
      UPDATE  xxcok_sales_deduction        xsd                              -- 販売控除情報
      SET     xsd.recon_slip_num           = NULL                           -- 支払伝票番号
             ,xsd.carry_payment_slip_num   = NULL                           -- 繰越時支払伝票番号
             ,xsd.last_updated_by          = cn_last_updated_by             -- 最終更新者
             ,xsd.last_update_date         = cd_last_update_date            -- 最終更新日
             ,xsd.last_update_login        = cn_last_update_login           -- 最終更新ログイン
             ,xsd.request_id               = cn_request_id                  -- 要求ID
             ,xsd.program_application_id   = cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
             ,xsd.program_id               = cn_program_id                  -- コンカレント・プログラムID
             ,xsd.program_update_date      = cd_program_update_date         -- プログラム更新日
      WHERE   xsd.recon_slip_num           = g_cancel_slip_tbl(ln_get_cnt).recon_slip_num
      AND     xsd.status                   = 'N'
      ;
    END LOOP reflect_cancel_loop;
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
  END status_reflect_cancel;
--
  /**********************************************************************************
   * Procedure Name   : update_sales_dedu_ctrl
   * Description      : A-6.販売控除管理情報更新
   ***********************************************************************************/
  PROCEDURE update_sales_dedu_ctrl(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sales_dedu_ctrl';              -- プログラム名
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
    -- 販売控除連携管理情報の最終連携日時を更新
    UPDATE  xxcok_sales_deduction_control xsdc                            -- 販売控除連携管理情報
    SET     xsdc.last_cooperation_date    = gd_this_process_date          -- 最終連携日時
           ,xsdc.last_updated_by          = cn_last_updated_by            -- 最終更新者
           ,xsdc.last_update_date         = cd_last_update_date           -- 最終更新日
           ,xsdc.last_update_login        = cn_last_update_login          -- 最終更新ログイン
           ,xsdc.request_id               = cn_request_id                 -- 要求ID
           ,xsdc.program_application_id   = cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
           ,xsdc.program_id               = cn_program_id                 -- コンカレント・プログラムID
           ,xsdc.program_update_date      = cd_program_update_date        -- プログラム更新日
    WHERE   xsdc.control_flag             = cv_ap_input_flag
    ;
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
  END update_sales_dedu_ctrl;
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
    gn_reject_target_cnt          := 0;                   -- 対象件数(却下)
    gn_approval_target_cnt        := 0;                   -- 対象件数(承認)
    gn_cancel_target_cnt          := 0;                   -- 対象件数(取消)
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
    -- A-2.控除消込ヘッダー情報抽出
    -- ===============================
    get_recon_header(
        ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
       ,ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
       ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4.取消伝票抽出
    -- ===============================
    get_cancel_slip(
        ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
       ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
       ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 取消伝票抽出の件数が1件以上の場合
    IF ( g_cancel_slip_tbl.COUNT > 0 ) THEN
      -- ===============================
      -- A-5.ステータス反映処理 (取消)
      -- ===============================
      status_reflect_cancel(
          ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
         ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
         ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- A-6.販売控除管理情報更新
    -- ===============================
    update_sales_dedu_ctrl(
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
    -- A-7.終了処理
    -- ===============================
--
    -- エラー発生時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_reject_target_cnt   := 0;
      gn_approval_target_cnt := 0;
      gn_cancel_target_cnt   := 0;
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
    -- 成功件数出力(却下)
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
END XXCOK024A25C;
/
