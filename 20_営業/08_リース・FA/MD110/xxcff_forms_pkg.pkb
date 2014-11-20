CREATE OR REPLACE PACKAGE BODY XXCFF_FORMS_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_FORMS_PKG(spec)
 * Description      : リース・FA領域FORMS用共通関数
 * MD.050           : なし
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ---- ----- ----------------------------------------------
 *  Name                        Type  Ret   Description
 * ---------------------------- ---- ----- ----------------------------------------------
 *  exe_sql                      P    -     動的SQL実行処理
 *  作成順に記述していくこと
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/09    1.0   SCS松中俊樹      新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF_FORMS_PKG'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCFF';            -- アドオン：FA・リース領域
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
   * Procedure Name   : exe_sql
   * Description      : 動的SQL実行処理
   ***********************************************************************************/
  PROCEDURE exe_sql(
    iv_sql        IN  VARCHAR2,   --   実行SQL
    ov_value1     OUT VARCHAR2,   --   SQL実行結果
    ov_value2     OUT VARCHAR2,   --   SQL実行結果
    ov_value3     OUT VARCHAR2,   --   SQL実行結果
    ov_value4     OUT VARCHAR2,   --   SQL実行結果
    ov_value5     OUT VARCHAR2,   --   SQL実行結果
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'exe_sql'; -- プログラム名
    cv_init_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00152'; -- 初期処理エラー
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
    TYPE rec_sql IS RECORD
     (value1 NUMBER
     ,value2 NUMBER
     ,value3 NUMBER
     ,value4 NUMBER
     ,value5 NUMBER);
--
    lr_sql rec_sql;
--
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
    --渡されたSQL文を実行
    EXECUTE IMMEDIATE iv_sql INTO lr_sql;
    --OUTパラメータ設定
    ov_value1 := lr_sql.value1;
    ov_value2 := lr_sql.value2;
    ov_value3 := lr_sql.value3;
    ov_value4 := lr_sql.value4;
    ov_value5 := lr_sql.value5;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--    WHEN global_api_expt THEN                           --*** 処理エラー ***
--      -- *** 任意で例外処理を記述する ****
--      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_init_err_msg
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END exe_sql;
--
END XXCFF_FORMS_PKG;
/
