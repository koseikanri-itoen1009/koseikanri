CREATE OR REPLACE PACKAGE BODY APPS.XXCOS007A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS007A03C(body)
 * Description      : 受注クローズ対象情報テーブルの情報から受注ワークリストのステータスを
 *                    更新します。
 * MD.050           :  MD050_COS_007_A03_受注明細WFクローズ
 *
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  start_proc             初期処理 (A-1)
 *  get_order_close        受注クローズ対象情報取得 (A-2)
 *  upd_wk_staus           ワークフローステータス更新 (A-3)
 *  upd_order_close        受注クローズ対象情報更新 (A-4)
 *  del_order_close        受注クローズ対象情報削除 (A-6)
 *  submain                メイン処理プロシージャ
 *                           セーブポイント発行処理 (A-5)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/09/01    1.0   K.Satomura       新規作成
 *  2010/08/24    1.1   S.Miyakoshi      [E_本稼動_01763] INVへの販売実績連携の日中化対応(入力パラメータ：要求IDの追加)
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
  gn_skip_cnt      NUMBER;                    -- スキップ件数
  gn_warn_cnt      NUMBER;                    -- 警告件数
  gn_delete_cnt    NUMBER;                    -- 削除件数
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name CONSTANT VARCHAR2(100) := 'XXCOS007A03C';  -- パッケージ名
  cv_app_name CONSTANT VARCHAR2(5)   := 'XXCOS';         -- アプリケーション短縮名
  --
  -- メッセージコード
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00014'; -- 業務日付取得エラー
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00001'; -- ロックエラー
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13906'; -- 受注明細WFクローズエラー
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00011'; -- データ更新エラーメッセージ
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00012'; -- データ削除エラーメッセージ
  cv_tkn_number_06 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13907'; -- 処理件数メッセージ
  cv_tkn_number_07 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00004'; -- プロファイル取得エラー
  cv_tkn_number_08 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-10075'; -- 削除件数
  cv_tkn_number_09 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13901'; -- 入力パラメータエラー
  cv_tkn_number_10 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13902'; -- 営業日取得エラーメッセージ
  cv_tkn_number_11 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11952'; -- メッセージ用文字列（実行区分）
  cv_tkn_number_12 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13903'; -- メッセージ用文字列（受注クローズ削除日数）
  cv_tkn_number_13 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13904'; -- メッセージ用文字列（受注クローズ対象情報テーブル）
  cv_tkn_number_14 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13905'; -- 入力パラメータ出力メッセージ
  cv_tkn_number_15 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11532'; -- メッセージ用文字列（受注クローズAPI）
  --
  -- トークンコード
  cv_tkn_param       CONSTANT VARCHAR2(20) := 'PARAM';
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_profile     CONSTANT VARCHAR2(20) := 'PROFILE';
  cv_tkn_api_name    CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_err_msg     CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_line_ID     CONSTANT VARCHAR2(20) := 'LINE_ID';
  cv_tkn_table_name  CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data    CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_tkn_count1      CONSTANT VARCHAR2(20) := 'COUNT1';
  cv_tkn_count2      CONSTANT VARCHAR2(20) := 'COUNT2';
  cv_tkn_count3      CONSTANT VARCHAR2(20) := 'COUNT3';
  cv_tkn_count4      CONSTANT VARCHAR2(20) := 'COUNT4';
  cv_tkn_count       CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_param_name  CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_value       CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_basic_day   CONSTANT VARCHAR2(20) := 'BASIC_DAY';
  cv_tkn_working_day CONSTANT VARCHAR2(20) := 'WORKING_DAY';
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
  cv_tkn_request_id  CONSTANT VARCHAR2(20) := 'REQUEST_ID';
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
  --
  -- DEBUG_LOG用メッセージ
  --cv_debug_msg1_1       CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  --cv_debug_msg1_2       CONSTANT VARCHAR2(200) := 'gd_business_date = ';
  --cv_debug_msg1_3       CONSTANT VARCHAR2(200) := '<< 入力パラメータ >>';
  --cv_debug_msg1_4       CONSTANT VARCHAR2(200) := 'in_exe_div = ';
  --cv_debug_msg1_5       CONSTANT VARCHAR2(200) := '<< プロファイルオプション値 >>';
  --cv_debug_msg1_6       CONSTANT VARCHAR2(200) := 'lt_delete_days = ';
  --cv_debug_msg1_7       CONSTANT VARCHAR2(200) := '<< ワークフローステータス更新失敗 >>';
  --cv_debug_msg1_8       CONSTANT VARCHAR2(200) := 'lv_errmsg = ';
  --cv_debug_msg_rollback CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --
  -- ===============================
  -- ユーザー定義カーソル型
  -- ===============================
  --
  -- ===============================
  -- ユーザー定義グローバルレコード定義
  -- ===============================
  TYPE order_line_id_ttype IS TABLE OF xxcos_order_close.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE process_status_ttype IS TABLE OF xxcos_order_close.process_status%TYPE INDEX BY BINARY_INTEGER;
  --
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
  gt_order_line_id_tab  order_line_id_ttype;
  gt_process_status_tab process_status_ttype;
  --
  -- ===============================
  -- ユーザー定義グローバル例外
  -- ===============================
  global_lock_expt EXCEPTION;  -- ロック例外
  --
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : start_proc
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE start_proc(
     in_exe_div      IN         NUMBER                                              -- 実行区分
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
    ,in_request_id   IN         NUMBER                                              -- 要求ID
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
    ,od_process_date OUT        DATE                                                -- 業務処理日付
    ,ot_delete_days  OUT        fnd_profile_option_values.profile_option_value%TYPE -- 受注クローズ削除日数
    ,ov_errbuf       OUT NOCOPY VARCHAR2                                            -- エラー・メッセージ            --# 固定 #
    ,ov_retcode      OUT NOCOPY VARCHAR2                                            -- リターン・コード              --# 固定 #
    ,ov_errmsg       OUT NOCOPY VARCHAR2                                            -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'start_proc';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ct_prof_delete_days CONSTANT fnd_profile_option_values.profile_option_value%TYPE := 'XXCOS1_ORDER_DELETE_DAYS';
    cn_exe_div_any_time CONSTANT NUMBER                                              := 1; -- 随時実行
    cn_exe_div_regular  CONSTANT NUMBER                                              := 2; -- 定期実行
    -- 
    -- *** ローカル変数 ***
    lv_work         VARCHAR2(4000);
    ld_process_date DATE;                                                -- 業務処理日付
    lt_delete_days  fnd_profile_option_values.profile_option_value%TYPE; -- 受注クローズ削除日数
    lv_tkn1         VARCHAR2(4000);
    --
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 業務処理日付取得
    -- ===========================
    ld_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF (ld_process_date = NULL) THEN
      -- 業務処理日付取得に失敗した場合（戻り値NULL）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_name      -- アプリケーション短縮名
                    ,iv_name        => cv_tkn_number_01 -- メッセージコード
                   );
      --
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    --fnd_file.put_line(
    --   which  => fnd_file.log
    --  ,buff   => cv_debug_msg1_1 || CHR(10) ||
    --             cv_debug_msg1_2 || TO_CHAR(ld_process_date, 'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
    --             ''
    --);
    --
    -- ===========================
    -- 入力パラメータチェック
    -- ===========================
    IF (NVL(in_exe_div, 0) <> cn_exe_div_any_time
      AND NVL(in_exe_div, 0) <> cn_exe_div_regular)
    THEN
      -- 入力パラメータエラー
      lv_tkn1 := xxccp_common_pkg.get_msg(
                    iv_application => cv_app_name      -- アプリケーション短縮名
                   ,iv_name        => cv_tkn_number_11 -- メッセージコード
                 );
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_09   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_param_name  -- トークンコード1
                     ,iv_token_value1 => lv_tkn1            -- トークン値1
                     ,iv_token_name2  => cv_tkn_value       -- トークンコード2
                     ,iv_token_value2 => cn_exe_div_any_time ||
                                         ',' ||
                                         cn_exe_div_regular -- トークン値2
                   );
      --
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    -- 入力パラメータをログ出力
    lv_work := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name         -- アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_14    -- メッセージコード
                 ,iv_token_name1  => cv_tkn_param        -- トークンコード1
                 ,iv_token_value1 => TO_CHAR(in_exe_div) -- トークン値1
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
                 ,iv_token_name2  => cv_tkn_request_id      -- トークンコード2
                 ,iv_token_value2 => TO_CHAR(in_request_id) -- トークン値2(要求ID)
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
               );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_work
    );
    --
    -- 空行出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => NULL
    );
    --
    -- メッセージ出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => lv_work
    );
    --
    -- 空行出力
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => NULL
    );
    --
    -- ============================
    -- プロファイルオプション値取得
    -- ============================
    lt_delete_days := fnd_profile.value(ct_prof_delete_days);
    --
    IF (lt_delete_days IS NULL) THEN
      -- プロファイル取得エラー
      lv_tkn1 := xxccp_common_pkg.get_msg(
                    iv_application => cv_app_name      -- アプリケーション短縮名
                   ,iv_name        => cv_tkn_number_12 -- メッセージコード
                 );
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name      -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_07 -- メッセージコード
                    ,iv_token_name1  => cv_tkn_profile   -- トークンコード1
                    ,iv_token_value1 => lv_tkn1          -- トークン値1
                   );
      --
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG ***
    -- プロファイルオプション値をログ出力
    --fnd_file.put_line(
    --   which  => fnd_file.log
    --  ,buff   => cv_debug_msg1_5 || CHR(10) ||
    --             cv_debug_msg1_6 || lt_delete_days || CHR(10) ||
    --             ''
    --);
    --
    od_process_date := ld_process_date;
    ot_delete_days  := lt_delete_days;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
--
--#####################################  固定部 END   ##########################################
--
  END start_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_order_close
   * Description      : 受注クローズ対象情報取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_order_close(
     it_sel_process_status IN         xxcos_order_close.process_status%TYPE -- 処理ステータス
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
    ,in_request_id         IN         NUMBER                                -- 要求ID
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
    ,ov_errbuf             OUT NOCOPY VARCHAR2                              -- エラー・メッセージ            --# 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2                              -- リターン・コード              --# 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2                              -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_order_close';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    lt_delete_days fnd_profile_option_values.profile_option_value%TYPE; -- 受注クローズ削除日数
    lv_tkn1        VARCHAR2(4000);
    --
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 受注クローズ対象情報取得
    -- ===========================
    BEGIN
      SELECT xoc.order_line_id order_line_id -- 受注明細ＩＤ
      BULK COLLECT INTO gt_order_line_id_tab
      FROM   xxcos_order_close xoc -- 受注クローズ対象情報テーブル
      WHERE  xoc.process_status = it_sel_process_status
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
      AND    (
              ( in_request_id IS NULL )
              OR
              ( in_request_id IS NOT NULL 
                AND xoc.request_id = in_request_id )
             )
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
      FOR UPDATE NOWAIT
      ;
      --
    EXCEPTION
      WHEN global_lock_expt THEN
        lv_tkn1 := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- アプリケーション短縮名
                     ,iv_name        => cv_tkn_number_13 -- メッセージコード
                   );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name      -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02 -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table     -- トークンコード1
                       ,iv_token_value1 => lv_tkn1          -- トークン値1
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
--
--#####################################  固定部 END   ##########################################
--
  END get_order_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_wk_staus
   * Description      : ワークフローステータス更新 (A-3)
   ***********************************************************************************/
  PROCEDURE upd_wk_staus(
     it_order_line_id  IN         xxcos_order_close.order_line_id%TYPE  -- 受注明細ＩＤ
    ,ot_process_status OUT        xxcos_order_close.process_status%TYPE -- 処理ステータス
    ,ov_errbuf         OUT NOCOPY VARCHAR2                              -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2                              -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2                              -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_wk_staus';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_close_type CONSTANT VARCHAR2(5)                           := 'OEOL';
    cv_activity   CONSTANT VARCHAR2(27)                          := 'XXCOS_R_STANDARD_LINE:BLOCK';
    cv_result     CONSTANT VARCHAR2(1)                           := NULL;
    ct_status_end CONSTANT xxcos_order_close.process_status%TYPE := 'Y';
    ct_status_err CONSTANT xxcos_order_close.process_status%TYPE := 'E';
    --
    -- *** ローカル変数 ***
    lt_process_status xxcos_order_close.process_status%TYPE;
    lv_err_name       VARCHAR2(4000);
    lv_err_stack      VARCHAR2(4000);
    lv_tkn1           VARCHAR2(4000);
    --
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ot_process_status := ct_status_end;
    --
    wf_engine.completeactivity(
       itemtype => cv_close_type
      ,itemkey  => it_order_line_id
      ,activity => cv_activity
      ,result   => cv_result
    );
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.get_error(
         err_name    => lv_err_name
        ,err_message => lv_errmsg
        ,err_stack   => lv_err_stack
      );
      --
      -- エラー内容を出力
      lv_tkn1 := xxccp_common_pkg.get_msg(
                    iv_application => cv_app_name      -- アプリケーション短縮名
                   ,iv_name        => cv_tkn_number_15 -- メッセージコード
                 );
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name      -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_03 -- メッセージコード
                     ,iv_token_name1  => cv_tkn_api_name  -- トークンコード1
                     ,iv_token_value1 => lv_tkn1          -- トークン値1
                     ,iv_token_name2  => cv_tkn_err_msg   -- トークンコード2
                     ,iv_token_value2 => lv_errmsg        -- トークン値2
                     ,iv_token_name3  => cv_tkn_line_id   -- トークンコード3
                     ,iv_token_value3 => it_order_line_id -- トークン値3
                   );
      --
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => lv_errmsg || CHR(10) ||
                   ''
      );
      --
      ov_errbuf         := lv_errmsg;
      ov_errmsg         := lv_errmsg;
      ot_process_status := ct_status_err;
      ov_retcode        := cv_status_warn;
      --
  END upd_wk_staus;
--
  /**********************************************************************************
   * Procedure Name   : upd_order_close
   * Description      : 受注クローズ対象情報更新(A-4)
   ***********************************************************************************/
  PROCEDURE upd_order_close(
     id_process_date IN         DATE     -- 業務日付
    ,ov_errbuf       OUT NOCOPY VARCHAR2 -- エラー・メッセージ            --# 固定 #
    ,ov_retcode      OUT NOCOPY VARCHAR2 -- リターン・コード              --# 固定 #
    ,ov_errmsg       OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_order_close';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    lv_tkn1 VARCHAR2(4000);
    --
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
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
    -- ========================================
    -- 受注クローズ対象情報更新
    -- ========================================
    BEGIN
      FORALL i IN  1.. gt_order_line_id_tab.COUNT
        UPDATE xxcos_order_close xoc -- 受注クローズ対象情報テーブル
        SET    xoc.process_status         = gt_process_status_tab(i)  -- 処理ステータス
              ,xoc.process_date           = id_process_date           -- 処理日
              ,xoc.last_updated_by        = cn_last_updated_by        -- 最終更新者
              ,xoc.last_update_date       = cd_last_update_date       -- 最終更新日
              ,xoc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
              ,xoc.request_id             = cn_request_id             -- 要求ID
              ,xoc.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
              ,xoc.program_id             = cn_program_id             -- コンカレント・プログラムID
              ,xoc.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE  xoc.order_line_id = gt_order_line_id_tab(i)
        ;
        --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn1 := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- アプリケーション短縮名
                     ,iv_name        => cv_tkn_number_13 -- メッセージコード
                   );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name       -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table_name -- トークンコード1
                       ,iv_token_value1 => lv_tkn1           -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_data   -- トークンコード2
                       ,iv_token_value2 => NULL              -- トークンコード2
                     );
        --
        lv_errbuf  := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE global_api_others_expt;
        --
    END;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_order_close;
--
  /**********************************************************************************
   * Procedure Name   : del_order_close
   * Description      : 受注クローズ対象情報削除(A-6)
   ***********************************************************************************/
  PROCEDURE del_order_close(
     id_process_date IN         DATE     -- 業務処理日付
    ,in_delete_days  IN         NUMBER   -- 削除日数
    ,on_delete_count OUT        NUMBER   -- 削除件数
    ,ov_errbuf       OUT NOCOPY VARCHAR2 -- エラー・メッセージ            --# 固定 #
    ,ov_retcode      OUT NOCOPY VARCHAR2 -- リターン・コード              --# 固定 #
    ,ov_errmsg       OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'del_order_close';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ct_process_status_end CONSTANT xxcos_order_close.process_status%TYPE := 'Y'; -- 処理ステータス=処理済
    --
    -- *** ローカル変数 ***
    ld_working_day  DATE;
    ln_delete_count NUMBER;
    lv_tkn1         VARCHAR2(4000);
    --
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ========================================
    -- 削除営業日取得
    -- ========================================
    ld_working_day := xxccp_common_pkg2.get_working_day(
                         id_date          => id_process_date
                        ,in_working_day   => in_delete_days
                        ,iv_calendar_code => NULL
                      );
    --
    IF (ld_working_day IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name        -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_10   -- メッセージコード
                    ,iv_token_name1  => cv_tkn_basic_day   -- トークンコード1
                    ,iv_token_value1 => id_process_date    -- トークン値1
                    ,iv_token_name2  => cv_tkn_working_day -- トークンコード2
                    ,iv_token_value2 => in_delete_days     -- トークン値2
                   );
      --
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ========================================
    -- 受注クローズ対象情報削除
    -- ========================================
    BEGIN
      DELETE xxcos_order_close xoc -- 受注クローズ対象情報テーブル
      WHERE  xoc.process_status       = ct_process_status_end
      AND    TRUNC(xoc.process_date) <= TRUNC(ld_working_day)
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn1 := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- アプリケーション短縮名
                     ,iv_name        => cv_tkn_number_13 -- メッセージコード
                   );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name       -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table_name -- トークンコード1
                       ,iv_token_value1 => lv_tkn1           -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_data   -- トークンコード2
                       ,iv_token_value2 => id_process_date   -- トークンコード2
                     );
        --
        lv_errbuf  := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE global_api_others_expt;
        --
    END;
    --
    -- ========================================
    -- 受注クローズ対象情報削除件数取得
    -- ========================================
    ln_delete_count := SQL%ROWCOUNT;
    --
    on_delete_count := ln_delete_count;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_order_close;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     in_exe_div IN         NUMBER   -- 実行区分
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
    ,in_request_id IN      NUMBER   -- 要求ID
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
    ,ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ            --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード              --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ct_exe_div_1  CONSTANT NUMBER                                := 1;   -- 実行区分=随時実行
    ct_exe_div_2  CONSTANT NUMBER                                := 2;   -- 実行区分=定期実行
    ct_proc_sts_1 CONSTANT xxcos_order_close.process_status%TYPE := 'E'; -- 処理ステータス=エラー
    ct_proc_sts_2 CONSTANT xxcos_order_close.process_status%TYPE := 'N'; -- 処理ステータス=未処理
    ct_proc_sts_3 CONSTANT xxcos_order_close.process_status%TYPE := 'Y'; -- 処理ステータス=処理済
    --
    -- *** ローカル変数 ***
    ld_process_date       DATE;                                                -- 業務処理日付
    lt_delete_days        fnd_profile_option_values.profile_option_value%TYPE; -- 受注クローズ削除日数
    lt_sel_process_status xxcos_order_close.process_status%TYPE;               -- 処理ステータス（検索用）
    lt_upd_process_status xxcos_order_close.process_status%TYPE;               -- 処理ステータス（更新用）
    --
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- *** ローカル例外 ***
    upd_wk_status_warn EXCEPTION;
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
    gn_target_cnt := 0; -- 対象件数
    gn_normal_cnt := 0; -- 正常件数
    gn_error_cnt  := 0; -- エラー件数
    gn_warn_cnt   := 0; -- 警告件数
    gn_delete_cnt := 0; -- 削除件数
--
    -- ========================================
    -- A-1.初期処理
    -- ========================================
    start_proc(
       in_exe_div      => in_exe_div      -- 実行区分
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
      ,in_request_id   => in_request_id   -- 要求ID
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
      ,od_process_date => ld_process_date -- 業務処理日付
      ,ot_delete_days  => lt_delete_days  -- 受注クローズ削除日数
      ,ov_errbuf       => lv_errbuf       -- エラー・メッセージ            --# 固定 #
      ,ov_retcode      => lv_retcode      -- リターン・コード              --# 固定 #
      ,ov_errmsg       => lv_errmsg       -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ========================================
    -- A-2.受注クローズ対象情報取得
    -- ========================================
    IF (in_exe_div = ct_exe_div_1) THEN
      -- 実行区分が1(随時実行)の場合
      lt_sel_process_status := ct_proc_sts_1;
      --
    ELSE
      -- 実行区分が2(定期実行)の場合
      lt_sel_process_status := ct_proc_sts_2;
      --
    END IF;
    --
    get_order_close(
       it_sel_process_status => lt_sel_process_status -- 処理ステータス
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
      ,in_request_id         => in_request_id         -- 要求ID
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
      ,ov_errbuf             => lv_errbuf             -- エラー・メッセージ            --# 固定 #
      ,ov_retcode            => lv_retcode            -- リターン・コード              --# 固定 #
      ,ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    <<wf_upd_loop>>
    FOR i IN 1..gt_order_line_id_tab.COUNT LOOP
      gn_target_cnt := gn_target_cnt + 1;
      --
      -- ========================================
      -- A-3.ワークフローステータス更新
      -- ========================================
      upd_wk_staus(
         it_order_line_id  => gt_order_line_id_tab(i) -- 受注明細ＩＤ
        ,ot_process_status => lt_upd_process_status   -- 処理ステータス
        ,ov_errbuf         => lv_errbuf               -- エラー・メッセージ            --# 固定 #
        ,ov_retcode        => lv_retcode              -- リターン・コード              --# 固定 #
        ,ov_errmsg         => lv_errmsg               -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_normal) THEN
        gt_process_status_tab(i) := ct_proc_sts_3;
        gn_normal_cnt            := gn_normal_cnt + 1;
        --
      ELSIF (lv_retcode = cv_status_warn) THEN
        gt_process_status_tab(i) := ct_proc_sts_1;
        gn_warn_cnt              := gn_warn_cnt + 1;
        --
      END IF;
      --
    END LOOP wf_upd_loop;
    --
    -- ========================================
    -- A-4.受注クローズ対象情報更新
    -- ========================================
    upd_order_close(
       id_process_date => ld_process_date -- 業務処理日付
      ,ov_errbuf       => lv_errbuf       -- エラー・メッセージ            --# 固定 #
      ,ov_retcode      => lv_retcode      -- リターン・コード              --# 固定 #
      ,ov_errmsg       => lv_errmsg       -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ========================================
    -- A-5.セーブポイント発行
    -- ========================================
    SAVEPOINT delete_order_close;
    --
    -- ========================================
    -- A-6.受注クローズ対象情報削除
    -- ========================================
    del_order_close(
       id_process_date => ld_process_date           -- 業務処理日付
      ,in_delete_days  => TO_NUMBER(lt_delete_days) -- 受注クローズ削除日数
      ,on_delete_count => gn_delete_cnt             -- 受注クローズ削除件数
      ,ov_errbuf       => lv_errbuf                 -- エラー・メッセージ            --# 固定 #
      ,ov_retcode      => lv_retcode                -- リターン・コード              --# 固定 #
      ,ov_errmsg       => lv_errmsg                 -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      ROLLBACK TO SAVEPOINT delete_order_close;
      RAISE global_process_expt;
      --
    END IF;
    --
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
      --
    END IF;
    --
    IF (gn_error_cnt > 0) THEN
      ov_retcode := cv_status_error;
      --
    END IF;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode   := cv_status_error;
      --
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode   := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
      --
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf     OUT NOCOPY VARCHAR2 -- エラー・メッセージ  --# 固定 #
    ,retcode    OUT NOCOPY VARCHAR2 -- リターン・コード    --# 固定 #
    ,in_exe_div IN         NUMBER   -- 実行区分
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
    ,in_request_id IN      NUMBER   -- 要求ID
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
  )
  IS
--
--###########################  固定部 START   ###########################
--
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
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
    lv_errbuf          VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
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
       in_exe_div => in_exe_div -- 実行区分
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
      ,in_request_id => in_request_id -- 要求ID
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
      ,ov_errbuf  => lv_errbuf  -- エラー・メッセージ            --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード              --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-7.終了処理
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    --ステータスセット
    retcode := lv_retcode;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_06
                    ,iv_token_name1  => cv_tkn_count1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt) -- 抽出件数
                    ,iv_token_name2  => cv_tkn_count2
                    ,iv_token_value2 => TO_CHAR(gn_normal_cnt) -- 成功件数
                    ,iv_token_name3  => cv_tkn_count3
                    ,iv_token_value3 => TO_CHAR(gn_error_cnt)  -- エラー件数
                    ,iv_token_name4  => cv_tkn_count4
                    ,iv_token_value4 => TO_CHAR(gn_warn_cnt)   -- 警告件数
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --削除件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_08
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_delete_cnt) -- 削除件数
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      --fnd_file.put_line(
      --   which  => FND_FILE.LOG
      --  ,buff   => cv_debug_msg_rollback || CHR(10) ||
      --             ''
      --);
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      --fnd_file.put_line(
      --   which  => FND_FILE.LOG
      --  ,buff   => cv_debug_msg_rollback || CHR(10) ||
      --             ''
      --);
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      --fnd_file.put_line(
      --   which  => FND_FILE.LOG
      --  ,buff   => cv_debug_msg_rollback || CHR(10) ||
      --             ''
      --);
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOS007A03C;
/
