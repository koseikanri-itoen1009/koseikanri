CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A43C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK024A43C (body)
 * Description      : 自動消込済のAR部門入力伝票取消時に、消込済の控除データを開放します。
 * MD.050           : 入金相殺自動消込取消処理 MD050_COK_024_A43
 * Version          : 1.1
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                    Description
 * ----------------------------------------------------------------------------------------
 *  init                    A-1.初期処理
 *  cancel_deduction        A-3.自動消込の取消処理(A-2.AR部門入力情報抽出を含む)
 *  update_recon_head       A-4.控除消込ヘッダー情報更新
 *  update_sales_deduction  A-5.販売控除情報更新
 *  update_sales_dedu_ctrl  A-6.販売控除管理情報更新
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ(A-7.終了処理を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2022/11/07    1.0   R.Oikawa         新規作成
 *  2024/03/12    1.1   SCSK Y.Koh       [E_本稼動_19496] グループ会社統合対応
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
  cv_pkg_name                   CONSTANT VARCHAR2(20) := 'XXCOK024A43C';                   -- パッケージ名
  -- アプリケーション短縮名
  cv_xxccp_appl_name            CONSTANT VARCHAR2(10) := 'XXCCP';                          -- 共通領域短縮アプリ名
  cv_xxcok_short_nm             CONSTANT VARCHAR2(10) := 'XXCOK';                          -- 個別開発領域短縮アプリ名
  cv_appl_name_sqlgl            CONSTANT VARCHAR2(10) := 'SQLGL';
  -- メッセージ名称
  cv_msg_cok_10592              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10592';               -- 前回処理情報取得エラー
  cv_msg_cok_10732              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10732';               -- ロックエラーメッセージ
  cv_msg_cok_10852              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10852';               -- 成功件数(控除消込ヘッダー情報)メッセージ
  cv_msg_cok_10853              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10853';               -- 成功件数(AR部門入力明細)メッセージ
  cv_msg_ccp_90000              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';               -- 対象件数メッセージ
  cv_msg_ccp_90002              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';               -- エラー件数メッセージ
  cv_msg_ccp_90004              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';               -- 正常終了メッセージ
  cv_msg_ccp_90005              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';               -- 警告終了メッセージ
  cv_msg_ccp_90006              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';               -- エラー終了全ロールバック
  --メッセージ文字列
  cv_msg_cok_10854              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10854'; -- 控除消込ヘッダー情報(メッセージ文字列)
  cv_msg_cok_10855              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10855'; -- 販売控除情報(メッセージ文字列)
  cv_msg_cok_10856              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10856'; -- AR部門入力明細(メッセージ文字列)
  -- トークン
  cv_profile_token              CONSTANT VARCHAR2(20) := 'PROFILE';                        -- プロファイルのトークン名
  cv_cnt_token                  CONSTANT VARCHAR2(20) := 'COUNT';                          -- 件数メッセージ用
  cv_tkn_table                  CONSTANT VARCHAR2(20) := 'TABLE';                          -- テーブル名
--
  -- フラグ
  cv_y                          CONSTANT VARCHAR2(1)  := 'Y';                              -- 値:Y
  cv_n                          CONSTANT VARCHAR2(1)  := 'N';                              -- 値:N
  -- 控除消込ヘッダー情報
  cv_recon_status_cancel        CONSTANT VARCHAR2(2)  := 'CD';                             -- 取消済
  -- AR部門入力
  cv_ar_status_appr             CONSTANT VARCHAR2(2)  := '80';                             -- 承認済
  -- 入金相殺自動消込フラグ
  cv_ar_flag_recon              CONSTANT VARCHAR2(1)  := 'Y';                              -- 消込済
  cv_ar_flag_cancel             CONSTANT VARCHAR2(1)  := 'C';                              -- 取消済
  -- 販売控除情報
  cv_source_cate                CONSTANT VARCHAR2(1)  := 'D';                              -- 作成元区分：差額調整
  cv_status_cancel              CONSTANT VARCHAR2(1)  := 'C';                              -- 取消済
  cv_cancel_flag_y              CONSTANT VARCHAR2(1)  := 'Y';                              -- 取消済
  -- 販売控除連携管理情報
  cv_ar_input_flag              CONSTANT VARCHAR2(1)  := 'R';                              -- AR部門入力情報
  -- 伝票種別
-- 2024/03/12 Ver1.1 DEL Start
--  cv_slip_type_80300            CONSTANT VARCHAR2(5)  := '80300';                          -- 入金相殺
-- 2024/03/12 Ver1.1 DEL End
  -- カレンダーオープン
  cv_open                       CONSTANT VARCHAR2(1)  := 'O';                              -- オープン
  -- カレンダー日付
  cd_minend_date                CONSTANT DATE         := TO_DATE('2010/01/01','YYYY/MM/DD'); -- 最小オープン日付
  --プロファイル
  cv_set_of_bks_id              CONSTANT VARCHAR2(20) := 'GL_SET_OF_BKS_ID';              -- 会計帳簿ID
-- 2024/03/12 Ver1.1 DEL Start
--  cv_trans_type_name_var_cons   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOK1_RA_TRX_TYPE_VARIABLE_CONS'; -- 取引タイプ名
-- 2024/03/12 Ver1.1 DEL End
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
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
  -- 正常件数
  gn_recon_headt_normal_cnt     NUMBER;                                               -- 成功件数(控除消込ヘッダー情報)
  gn_receivable_normal_cnt      NUMBER;                                               -- 成功件数(AR部門入力明細)
  -- GL記帳日
  gd_cancel_gl_date             DATE;                                                 -- 取消GL記帳日
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
    -- 1.今回の処理日時を取得
    -- ============================================================
    gd_this_process_date  := SYSDATE;           -- 今回処理日時
--
    -- ============================================================
    -- 2.前回の処理日時を取得
    -- ============================================================
    BEGIN
    --
      SELECT  xsdc.last_cooperation_date    AS last_cooperation_date
      INTO    gd_last_process_date                -- 前回処理日時
      FROM    xxcok_sales_deduction_control xsdc  -- 販売控除連携管理情報
      WHERE   xsdc.control_flag = cv_ar_input_flag
      ;
    --
    EXCEPTION
      WHEN  OTHERS THEN
        -- 前回処理情報取得エラーメッセージ
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_msg_cok_10592
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================================
    -- 3.AR部門入力カレンダーのOPEN月取得
    -- ============================================================
    SELECT  MIN( gps.end_date ) cancel_gl_date
    INTO    gd_cancel_gl_date
    FROM    gl_period_statuses  gps
           ,fnd_application     fa
    WHERE   fa.application_short_name    =   cv_appl_name_sqlgl
    AND     gps.application_id           =   fa.application_id
    AND     gps.set_of_books_id          =   FND_PROFILE.VALUE( cv_set_of_bks_id )
    AND     gps.end_date                 >=  cd_minend_date
    AND     gps.adjustment_period_flag   =   cv_n
    AND     NVL(gps.attribute4, cv_open) =   cv_open
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : update_recon_head
   * Description      : A-4.控除消込ヘッダー情報更新
   ***********************************************************************************/
  PROCEDURE update_recon_head(
                  iv_recon_slip_num IN  xxcok_deduction_recon_head.recon_slip_num%TYPE   -- 支払伝票番号
                 ,id_approval_date  IN  xxcok_deduction_recon_head.approval_date%TYPE    -- 承認日
                 ,ov_errbuf         OUT VARCHAR2      --   エラー・メッセージ            --# 固定 #
                 ,ov_retcode        OUT VARCHAR2      --   リターン・コード              --# 固定 #
                 ,ov_errmsg         OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_recon_head';              -- プログラム名
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
    --==============================================================
    --ロック取得用カーソル
    --==============================================================
    CURSOR recon_head_cur(
      iv_recon_slip_num IN xxcok_deduction_recon_head.recon_slip_num%TYPE
    )
    IS
      SELECT xdrh.recon_slip_num     AS recon_slip_num
      FROM   xxcok_deduction_recon_head xdrh
      WHERE  xdrh.recon_slip_num    = iv_recon_slip_num     -- 支払伝票番号
      FOR UPDATE OF xdrh.recon_slip_num NOWAIT
      ;
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    OPEN  recon_head_cur(
            iv_recon_slip_num => iv_recon_slip_num
          );
    CLOSE recon_head_cur;
    --==================================
    -- 控除消込ヘッダを更新
    --==================================
    UPDATE  xxcok_deduction_recon_head xdrh
    SET     xdrh.recon_status            = cv_recon_status_cancel        -- 消込ステータス（取消済に更新）
           ,xdrh.cancellation_date       = id_approval_date              -- 取消日
           ,xdrh.cancel_gl_date          = DECODE(xdrh.gl_if_flag, cv_n, xdrh.gl_date
                                             , gd_cancel_gl_date)        -- 取消GL記帳日
           ,xdrh.last_updated_by         = cn_last_updated_by            -- 最終更新者
           ,xdrh.last_update_date        = cd_last_update_date           -- 最終更新日
           ,xdrh.last_update_login       = cn_last_update_login          -- 最終更新ログイン
           ,xdrh.request_id              = cn_request_id                 -- 要求ID
           ,xdrh.program_application_id  = cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
           ,xdrh.program_id              = cn_program_id                 -- コンカレント・プログラムID
           ,xdrh.program_update_date     = cd_program_update_date        -- プログラム更新日
    WHERE   xdrh.recon_slip_num          = iv_recon_slip_num             -- 支払伝票番号
    ;
--
    -- 控除消込ヘッダの更新件数
    gn_recon_headt_normal_cnt := gn_recon_headt_normal_cnt + SQL%ROWCOUNT;
--
  EXCEPTION
--
    -- ロックエラー
    WHEN lock_expt THEN
      -- カーソルクローズ
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      -- ロックエラーメッセージ
      lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                                 ,iv_name          => cv_msg_cok_10732
                                                 ,iv_token_name1   => cv_tkn_table
                                                 ,iv_token_value1  => cv_msg_cok_10854            -- 文字列「控除消込ヘッダー情報」
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
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#################################  固定例外処理部 END  #################################
--
  END update_recon_head;
--
  /**********************************************************************************
   * Procedure Name   : update_sales_deduction
   * Description      : A-5.販売控除情報更新
   ***********************************************************************************/
  PROCEDURE update_sales_deduction(
                  iv_recon_slip_num IN  xxcok_sales_deduction.recon_slip_num%TYPE        -- 支払伝票番号
                 ,ov_errbuf         OUT VARCHAR2      --   エラー・メッセージ            --# 固定 #
                 ,ov_retcode        OUT VARCHAR2      --   リターン・コード              --# 固定 #
                 ,ov_errmsg         OUT VARCHAR2 )    --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sales_deduction';              -- プログラム名
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
    -- *** ローカル例外 ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
--
    -- *** ローカル・カーソル ***
    --==============================================================
    --ロック取得用カーソル
    --==============================================================
    CURSOR sales_deduction_cur(
      iv_recon_slip_num IN xxcok_deduction_recon_head.recon_slip_num%TYPE
    )
    IS
      SELECT xsd.recon_slip_num    AS recon_slip_num
      FROM   xxcok_sales_deduction xsd
      WHERE  xsd.recon_slip_num    = iv_recon_slip_num     -- 支払伝票番号
      FOR UPDATE OF xsd.recon_slip_num NOWAIT
      ;
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    OPEN  sales_deduction_cur(
            iv_recon_slip_num => iv_recon_slip_num
          );
    CLOSE sales_deduction_cur;
    --==================================
    -- 控除データ
    -- 販売控除情報を更新
    --==================================
    UPDATE xxcok_sales_deduction xsd
    SET    xsd.recon_slip_num          = NULL                          -- 支払伝票番号
          ,xsd.carry_payment_slip_num  = NULL                          -- 繰越時支払伝票番号
          ,xsd.last_updated_by         = cn_last_updated_by            -- 最終更新者
          ,xsd.last_update_date        = cd_last_update_date           -- 最終更新日
          ,xsd.last_update_login       = cn_last_update_login          -- 最終更新ログイン
          ,xsd.request_id              = cn_request_id                 -- 要求ID
          ,xsd.program_application_id  = cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
          ,xsd.program_id              = cn_program_id                 -- コンカレント・プログラムID
          ,xsd.program_update_date     = cd_program_update_date        -- プログラム更新日
    WHERE  xsd.recon_slip_num          = iv_recon_slip_num             -- 支払伝票番号
    AND    xsd.source_category        != cv_source_cate                -- 作成元区分
    ;
--
    --==================================
    -- 控除データ（差額）
    -- 販売控除情報を更新
    --==================================
    UPDATE xxcok_sales_deduction xsd
    SET    xsd.status                  = cv_status_cancel              -- ステータス
          ,xsd.recovery_del_date       = SYSDATE                       -- リカバリデータ削除時日付
          ,xsd.recovery_del_request_id = fnd_global.conc_request_id    -- リカバリデータ削除時要求ID
          ,xsd.cancel_flag             = cv_cancel_flag_y              -- 取消フラグ
          ,xsd.last_updated_by         = cn_last_updated_by            -- 最終更新者
          ,xsd.last_update_date        = cd_last_update_date           -- 最終更新日
          ,xsd.last_update_login       = cn_last_update_login          -- 最終更新ログイン
          ,xsd.request_id              = cn_request_id                 -- 要求ID
          ,xsd.program_application_id  = cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
          ,xsd.program_id              = cn_program_id                 -- コンカレント・プログラムID
          ,xsd.program_update_date     = cd_program_update_date        -- プログラム更新日
    WHERE  xsd.recon_slip_num          = iv_recon_slip_num             -- 支払伝票番号
    AND    xsd.source_category         = cv_source_cate                -- 作成元区分
    ;
--
  EXCEPTION
--
    -- ロックエラー
    WHEN lock_expt THEN
      -- カーソルクローズ
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      -- ロックエラーメッセージ
      lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                                 ,iv_name          => cv_msg_cok_10732
                                                 ,iv_token_name1   => cv_tkn_table
                                                 ,iv_token_value1  => cv_msg_cok_10855            -- 文字列「販売控除情報」
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
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sales_deduction_cur%ISOPEN ) THEN
        CLOSE sales_deduction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 END  #################################
--
  END update_sales_deduction;
--
  /**********************************************************************************
   * Procedure Name   : cancel_deduction
   * Description      : A-3.自動消込の取消処理
   ***********************************************************************************/
  PROCEDURE cancel_deduction(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cancel_deduction';                    -- プログラム名
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
--
    -- *** ローカル・カーソル ***
    -- ===============================
    -- A-2．AR部門入力情報抽出
    -- ===============================
    CURSOR get_receivable_slips_cur
    IS
      SELECT  xrss.receivable_num || '-' || xrsl.line_number   AS receivable_num     -- 支払伝票番号
             ,xrsl.receivable_line_id                          AS receivable_line_id -- 明細ID
             ,TRUNC(xrsc.approval_date)                        AS approval_date      -- 承認日
      FROM    xx03.xx03_receivable_slips xrsc                                        -- AR部門入力ヘッダ(取消)
             ,xx03.xx03_receivable_slips_line xrslc                                  -- AR部門明細(取消)
             ,xx03.xx03_receivable_slips xrss                                        -- AR部門入力ヘッダ(元)
             ,xx03.xx03_receivable_slips_line xrsl                                   -- AR部門入力明細(元)
      WHERE   xrsc.orig_invoice_num      = xrss.receivable_num                       -- 支払伝票番号(元と取消)
      AND     xrsc.org_id                = xrss.org_id                               -- 組織ID(元と取消)
      AND     xrsc.receivable_id         = xrslc.receivable_id                       -- 伝票ID(取消)
      AND     xrslc.line_number          = xrsl.line_number                          -- 明細番号(元と取消)
      AND     xrss.receivable_id         = xrsl.receivable_id                        -- 伝票ID(元)
-- 2024/03/12 Ver1.1 DEL Start
--      AND     xrsc.slip_type             = cv_slip_type_80300                        -- 伝票種別
-- 2024/03/12 Ver1.1 DEL End
      AND     xrsc.orig_invoice_num IS NOT NULL                                      -- 修正元伝票番号
      AND     xrsc.wf_status             = cv_ar_status_appr                         -- ステータス（承認済）
      AND     xrsc.approval_date         > gd_last_process_date                      -- 承認日(前回処理日時)
      AND     xrsc.approval_date        <= gd_this_process_date                      -- 承認日(今回処理日時)
      AND     NVL(xrsl.attribute8 ,cv_n) = cv_ar_flag_recon                          -- 入金相殺自動消込フラグ
      FOR UPDATE OF xrsl.receivable_line_id NOWAIT
      ;
    -- カーソルレコード型
    get_receivable_slips_rec  get_receivable_slips_cur%ROWTYPE;
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
    -- カーソル取得
    <<cancel_loop>>
    FOR get_receivable_slips_rec IN get_receivable_slips_cur LOOP
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================
      -- A-4.控除消込ヘッダー情報更新
      -- ===============================
      update_recon_head(
            iv_recon_slip_num => get_receivable_slips_rec.receivable_num        -- 支払伝票番号
           ,id_approval_date  => get_receivable_slips_rec.approval_date         -- 承認日
           ,ov_errbuf         => lv_errbuf                                      -- エラー・メッセージ           -- # 固定 #
           ,ov_retcode        => lv_retcode                                     -- リターン・コード             -- # 固定 #
           ,ov_errmsg         => lv_errmsg                                      -- ユーザー・エラー・メッセージ -- # 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-5.販売控除情報更新
      -- ===============================
      update_sales_deduction(
            iv_recon_slip_num => get_receivable_slips_rec.receivable_num        -- 支払伝票番号
           ,ov_errbuf         => lv_errbuf                                      -- エラー・メッセージ           -- # 固定 #
           ,ov_retcode        => lv_retcode                                     -- リターン・コード             -- # 固定 #
           ,ov_errmsg         => lv_errmsg                                      -- ユーザー・エラー・メッセージ -- # 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- AR部門入力明細更新
      -- ===============================
      BEGIN
        -- AR部門入力明細を更新
        UPDATE xx03.xx03_receivable_slips_line xrsl
        SET    xrsl.attribute8               = cv_ar_flag_cancel             -- 入金相殺自動消込フラグ
              ,xrsl.last_updated_by          = cn_last_updated_by            -- 最終更新者
              ,xrsl.last_update_date         = cd_last_update_date           -- 最終更新日
              ,xrsl.last_update_login        = cn_last_update_login          -- 最終更新ログイン
              ,xrsl.request_id               = cn_request_id                 -- 要求ID
              ,xrsl.program_application_id   = cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
              ,xrsl.program_id               = cn_program_id                 -- コンカレント・プログラムID
              ,xrsl.program_update_date      = cd_program_update_date        -- プログラム更新日
        WHERE  xrsl.receivable_line_id       = get_receivable_slips_rec.receivable_line_id
        ;
        -- AR部門入力明細更新の更新件数
        gn_receivable_normal_cnt := gn_receivable_normal_cnt + SQL%ROWCOUNT;
--
      END;
--
    END LOOP cancel_loop;
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      -- ロックエラーメッセージ
      lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                                 ,iv_name          => cv_msg_cok_10732
                                                 ,iv_token_name1   => cv_tkn_table
                                                 ,iv_token_value1  => cv_msg_cok_10856            -- 文字列「AR部門入力明細」
                                                 );
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode     := cv_status_error;
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
--#################################  固定例外処理部 END  #################################
--
  END cancel_deduction;
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
    WHERE   xsdc.control_flag             = cv_ar_input_flag
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
    gn_target_cnt                 := 0;                   -- 対象件数
    gn_recon_headt_normal_cnt     := 0;                   -- 成功件数(控除消込ヘッダー情報)
    gn_receivable_normal_cnt      := 0;                   -- 成功件数(AR部門入力明細)
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
    -- A-3.自動消込の取消処理
    -- ===============================
    cancel_deduction(
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
    -- A-6.終了処理
    -- ===============================
--
    -- エラー発生時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt             := 0;
      gn_recon_headt_normal_cnt := 0;
      gn_receivable_normal_cnt  := 0;
      gn_error_cnt              := 1;
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
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_ccp_90000
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 成功件数出力(控除消込ヘッダー情報)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_msg_cok_10852
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_recon_headt_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- 成功件数出力(AR部門入力明細)
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_msg_cok_10853
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_receivable_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_ccp_90002
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
      lv_message_code := cv_msg_ccp_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_ccp_90006;
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
END XXCOK024A43C;
/
