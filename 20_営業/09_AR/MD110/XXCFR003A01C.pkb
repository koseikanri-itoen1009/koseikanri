CREATE OR REPLACE PACKAGE BODY XXCFR003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A01C(body)
 * Description      : 請求データ削除
 * MD.050           : MD050_CFR_003_A01_請求データ削除
 * MD.070           : MD050_CFR_003_A01_請求データ削除
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  out_log_inparam        入力パラメータ値ログ出力     (A-1)
 *  get_profile_value      プロファイル取得処理         (A-2)
 *  get_del_period         保持対象外日付取得処理       (A-3)
 *  del_inv_detail         請求明細情報削除処理         (A-4)
 *  del_inv_header         請求ヘッダ情報削除処理       (A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-10-31    1.0  SCS 大川 恵      初回作成
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
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3)     := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3)     := ',';
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
  gn_target_h_cnt  NUMBER;                   -- 対象件数(ヘッダ)
  gn_normal_h_cnt  NUMBER;                   -- 正常件数(ヘッダ)
  gn_target_d_cnt  NUMBER;                   -- 対象件数(明細)
  gn_normal_d_cnt  NUMBER;                   -- 正常件数(明細)
  gn_error_cnt     NUMBER;                   -- エラー件数
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
  profile_expt              EXCEPTION;     -- プロファイル取得エラー
  lock_expt                 EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- メッセージ用定数
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A01C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- メッセージ番号
  cv_msg_003a01_001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; --対象件数メッセージ  ：ヘッダ
  cv_msg_003a01_002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; --成功件数メッセージ  ：ヘッダ
  cv_msg_003a01_003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; --エラー件数メッセージ：ヘッダ
  cv_msg_003a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; --対象件数メッセージ  ：明細
  cv_msg_003a01_005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; --成功件数メッセージ  ：明細
  cv_msg_003a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; --エラー件数メッセージ：明細
  cv_msg_003a01_007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; --正常終了メッセージ
  cv_msg_003a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; --エラー終了全ロールバックメッセージ
--
  cv_msg_003a01_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00018'; --件数タイトル：ヘッダ
  cv_msg_003a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00019'; --件数タイトル：明細
  cv_msg_003a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --プロファイル取得エラーメッセージ
  cv_msg_003a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --業務処理日付取得エラーメッセージ
  cv_msg_003a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --ロックエラーメッセージ
  cv_msg_003a01_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --データ削除エラーメッセージ
--
  -- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
--
  --プロファイル
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';                           -- 組織ID
  cv_account_id      CONSTANT VARCHAR2(30) := 'SET_OF_BOOKS_ID';                  -- 会計帳簿ID
  cv_tkn_profn       CONSTANT VARCHAR2(35) := 'XXCFR1_INVOICE_DATA_RESERVE_DATE'; -- 保存期間
  -- 使用DB名
  cv_tkn_d_tab       CONSTANT VARCHAR2(50) := 'XXCFR_INVOICE_LINES';   -- 請求明細情報テーブル
  cv_tkn_h_tab       CONSTANT VARCHAR2(50) := 'XXCFR_INVOICE_HEADERS'; -- 請求ヘッダ情報テーブル
  -- メッセージ出力区分
  cv_file_type_out   CONSTANT VARCHAR2(50) := 'OUTPUT';
  cv_file_type_log   CONSTANT VARCHAR2(50) := 'LOG';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 定数
  gn_inv_keep_period          NUMBER;                     -- プロファイル：保存期間
  gd_process_date             DATE;                       -- 業務日付
  gd_del_date                 DATE;                       -- 請求書保持対象外日付
--
  /**********************************************************************************
   * Procedure Name   : out_log_inparam
   * Description      : 入力パラメータ値ログ出力処理 (A-1)
   ***********************************************************************************/
  PROCEDURE out_log_inparam(
    ov_errbuf   OUT  VARCHAR2,  -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode  OUT  VARCHAR2,  -- 2.リターン・コード             --# 固定 #
    ov_errmsg   OUT  VARCHAR2)  -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_log_inparam'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- メッセージ出力
      ,ov_errbuf       => ov_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => ov_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => ov_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,ov_errbuf       => ov_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => ov_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => ov_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END out_log_inparam;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf   OUT  VARCHAR2,  -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode  OUT  VARCHAR2,  -- 2.リターン・コード             --# 固定 #
    ov_errmsg   OUT  VARCHAR2)  -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- プロファイル：保存期間の取得
    gn_inv_keep_period := TO_NUMBER( FND_PROFILE.VALUE(cv_tkn_profn) );
    -- 取得エラー時
    IF (gn_inv_keep_period IS NULL) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(cv_msg_kbn_cfr     -- アプリケーション短縮名
                                                    ,cv_msg_003a01_011  -- メッセージ
                                                    ,cv_tkn_prof        -- トークンコード
                                                     -- トークン：XXCFR:請求データ保持期間
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_tkn_profn))
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
--
--#####################################  固定部 END   ##########################################
--
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : get_del_period
   * Description      : 保持対象外日付取得処理 (A-3)
   ***********************************************************************************/
  PROCEDURE get_del_period(
    ov_errbuf   OUT  VARCHAR2,  -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode  OUT  VARCHAR2,  -- 2.リターン・コード             --# 固定 #
    ov_errmsg   OUT  VARCHAR2)  -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_del_period'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --共通関数「業務処理日付取得関数」により業務処理日付を取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --取得結果がNULLならばエラー
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                                    cv_msg_kbn_cfr     -- アプリケーション短縮名：XXCFR
                                                   ,cv_msg_003a01_012) -- メッセージ：APP-XXCFR1-00006
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --請求書保持対象外日付を取得
    --業務日付(DATE型)－保存期間(NUMBER型)
    gd_del_date := TRUNC(gd_process_date) - gn_inv_keep_period;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END get_del_period;
--
  /**********************************************************************************
   * Procedure Name   : del_inv_detail
   * Description      : 請求明細情報削除処理 (A-4)
   ***********************************************************************************/
  PROCEDURE del_inv_detail(
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_inv_detail'; -- プログラム名
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
    ln_del_count NUMBER :=0;
--
    -- *** ローカル・カーソル ***
    -- テーブルロックカーソル
    CURSOR del_table_d_cur
    IS
      SELECT xil.invoice_id invoice_id
      FROM xxcfr_invoice_lines xil
      WHERE  EXISTS(
        SELECT 'x'
        FROM   xxcfr_invoice_headers xih
        WHERE  xih.invoice_id = xil.invoice_id    -- 一括請求書ID
          AND  xih.inv_creation_date <= gd_del_date ) -- 請求書保持対象外日付
        FOR UPDATE OF xil.invoice_id NOWAIT;
--
    -- *** ローカル・レコード ***
--
  xxcfr_del_rec    del_table_d_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN del_table_d_cur;
    BEGIN
      <<delete_lines_loop>>
      LOOP
        FETCH del_table_d_cur INTO xxcfr_del_rec;
        EXIT delete_lines_loop WHEN del_table_d_cur%NOTFOUND;
        --対象データを削除
        DELETE FROM xxcfr_invoice_lines xil
        WHERE  CURRENT OF del_table_d_cur;
        -- 処理件数カウント
        ln_del_count := ln_del_count + 1; 
      END LOOP delete_lines_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a01_014 -- データ削除エラー
                                                      ,cv_tkn_table         -- トークン'TABLE'
                                                      ,xxcfr_common_pkg.get_table_comment(cv_tkn_d_tab))
                                                       -- 請求明細情報テーブル
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        -- カーソルクローズ
        CLOSE del_table_d_cur;
        RAISE global_api_expt;
    END;
--
    -- 処理件数のセット
    gn_target_d_cnt := ln_del_count;
    gn_normal_d_cnt := ln_del_count;
    -- カーソルクローズ
    CLOSE del_table_d_cur;
--
  EXCEPTION
--
    WHEN lock_expt THEN  -- テーブルロックエラー
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                                     cv_msg_kbn_cfr        -- 'XXCFR'
                                                    ,cv_msg_003a01_013    -- テーブルロックエラー
                                                    ,cv_tkn_table         -- トークン'TABLE'
                                                    ,xxcfr_common_pkg.get_table_comment( -- 請求明細情報テーブル
                                                                                        cv_tkn_d_tab
                                                                                        ) )
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END del_inv_detail;
--
  /**********************************************************************************
   * Procedure Name   : del_inv_header
   * Description      : 請求ヘッダ情報削除処理 (A-5)
   ***********************************************************************************/
  PROCEDURE del_inv_header(
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
      -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_inv_detail'; -- プログラム名
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
    ln_del_h_count NUMBER :=0;
--
    -- *** ローカル・カーソル ***
    -- テーブルロックカーソル
    CURSOR del_table_h_cur
    IS
      SELECT xih.invoice_id invoice_id
      FROM   xxcfr_invoice_headers xih         -- 請求ヘッダ情報
      WHERE  xih.inv_creation_date <= gd_del_date  -- 請求書保持対象外日付
      FOR UPDATE OF xih.invoice_id NOWAIT;
--
    -- *** ローカル・レコード ***
--
  xxcfr_del_h_rec    del_table_h_cur%rowtype;
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
    OPEN del_table_h_cur;
    BEGIN
      <<delete_headers_loop>>
      LOOP
        FETCH del_table_h_cur INTO xxcfr_del_h_rec;
        EXIT delete_headers_loop WHEN del_table_h_cur%NOTFOUND;
        --対象データを削除
        DELETE FROM xxcfr_invoice_headers xih
        WHERE  CURRENT OF del_table_h_cur;
        -- 処理件数カウント
        ln_del_h_count := ln_del_h_count + 1;
      END LOOP delete_headers_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a01_014 -- データ削除エラー
                                                      ,cv_tkn_table         -- トークン'TABLE'
                                                      ,xxcfr_common_pkg.get_table_comment(cv_tkn_h_tab))
                                                       --請求ヘッダ情報テーブル
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        -- カーソルクローズ
        CLOSE del_table_h_cur;
        RAISE global_api_expt;
    END;
    -- 処理件数のセット
    gn_target_h_cnt := ln_del_h_count;
    gn_normal_h_cnt := ln_del_h_count;
    -- カーソルクローズ
    CLOSE del_table_h_cur;
--
  EXCEPTION
--
    WHEN lock_expt THEN  -- テーブルロックエラー
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a01_013    -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     --請求ヘッダ情報テーブル
                                                     ,xxcfr_common_pkg.get_table_comment(cv_tkn_h_tab))
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END del_inv_header;
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_h_cnt := 0;
    gn_normal_h_cnt := 0;
    gn_target_d_cnt := 0;
    gn_normal_d_cnt := 0;
    gn_error_cnt    := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  入力パラメータ値ログ出力 (A-1)
    -- =====================================================
    out_log_inparam(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理 (A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  保持対象外日付取得処理 (A-3)
    -- =====================================================
    get_del_period(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  請求明細情報削除処理 (A-4)
    -- =====================================================
    del_inv_detail(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  請求ヘッダ情報削除処理 (A-5)
    -- =====================================================
    del_inv_header(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
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
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
    errbuf        OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode       OUT     VARCHAR2          --    エラーコード     #固定#
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --正常終了メッセージ
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --警告終了メッセージ
    cv_error_msg CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90006'; --警告終了メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
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
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
            lv_errbuf     -- エラー・メッセージ           --# 固定 #
           ,lv_retcode    -- リターン・コード             --# 固定 #
           ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_h_cnt := 0;
      gn_normal_h_cnt := 0;
      gn_target_d_cnt := 0;
      gn_normal_d_cnt := 0;
      gn_error_cnt    := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
    --正常でない場合、エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --１行改行
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
    --エラー出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --エラーメッセージ
    );
    --件数タイトル：ヘッダ
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cfr
                                          ,iv_name         => cv_msg_003a01_009
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_001
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_target_h_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_002
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_normal_h_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_003
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --件数タイトル：明細
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cfr
                                          ,iv_name         => cv_msg_003a01_010
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_001
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_target_d_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_002
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_normal_d_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => cv_msg_003a01_003
                                          ,iv_token_name1  => 'COUNT'
                                          ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
                                           iv_application  => cv_msg_kbn_ccp
                                          ,iv_name         => lv_message_code
                  );
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
END XXCFR003A01C;
/
