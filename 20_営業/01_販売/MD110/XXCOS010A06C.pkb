CREATE OR REPLACE PACKAGE BODY APPS.XXCOS010A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A06C (body)
 * Description      : 受注インポートエラー検知
 * MD.050           : MD050_COS_010_A06_受注インポートエラー検知
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              初期処理(A-1)
 *  reg_order_proc         受注インポート(A-2)
 *  err_chk_proc           エラーチェック(A-3)
 *    err_msg_out_proc       エラーメッセージ出力(A-4)
 *  end_proc               終了処理(A-5)
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/07/06    1.0   K.Satomura       新規作成
 *  2009/11/10    1.1   M.Sano           [E_T4_00173]不要な結合テーブルの削除・ヒント句追加
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
  global_get_profile_expt EXCEPTION; --プロファイル取得例外ハンドラ
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(128)                               := 'XXCOS010A06C'; -- パッケージ名
  ct_xxcos_appl_short_name CONSTANT fnd_application.application_short_name%TYPE := 'XXCOS';        -- アプリケーション短縮名(販物)
  ct_xxccp_appl_short_name CONSTANT fnd_application.application_short_name%TYPE := 'XXCCP';        -- アプリケーション短縮名(共通)
  cv_flag_yes              CONSTANT VARCHAR2(1)                                 := 'Y';            -- フラグ=Y
  cv_flag_no               CONSTANT VARCHAR2(1)                                 := 'N';            -- フラグ=N
  cn_number_zero           CONSTANT NUMBER                                      := 0;              -- 数値=0
  cn_number_one            CONSTANT NUMBER                                      := 1;              -- 数値=1
  --
  -- メッセージ
  ct_msg_get_profile_err CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004'; -- プロファイル取得エラー
  ct_msg_get_data_err    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013'; -- データ抽出エラーメッセージ
  ct_msg_param_output    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13801'; -- パラメータ出力メッセージ
  ct_msg_err_chk_failed  CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13802'; -- エラーチェック失敗メッセージ
  ct_msg_err_info        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13803'; -- エラー情報
  ct_msg_err_cnt         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13804'; -- エラー件数
  ct_msg_order_inp_err   CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13805'; -- 受注インポートエラーメッセージ
  ct_msg_char1           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13806'; -- メッセージ用文字列
  ct_msg_char2           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13807'; -- メッセージ用文字列
  ct_msg_char3           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13808'; -- メッセージ用文字列
  ct_msg_char4           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13809'; -- メッセージ用文字列
  ct_msg_char5           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13810'; -- メッセージ用文字列
  ct_msg_char6           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13811'; -- メッセージ用文字列
  ct_msg_char7           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13812'; -- メッセージ用文字列
  ct_msg_char8           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13813'; -- メッセージ用文字列
  ct_msg_char9           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13814'; -- メッセージ用文字列
  ct_msg_char10          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13815'; -- メッセージ用文字列
  ct_msg_publish_request CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13816'; -- 要求発行メッセージ
  ct_msg_time_over       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13817'; -- 待機時間経過メッセージ
  ct_msg_imp_war_err     CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13818'; -- 受注インポート警告・エラーメッセージ
  --
  -- トークン
  cv_tkn_param      CONSTANT VARCHAR2(512) := 'PARAM';      -- パラメータ
  cv_tkn_profile    CONSTANT VARCHAR2(512) := 'PROFILE';    -- プロファイル名
  cv_tkn_table_name CONSTANT VARCHAR2(512) := 'TABLE_NAME'; -- テーブル名
  cv_tkn_key_data   CONSTANT VARCHAR2(512) := 'KEY_DATA';   -- データキー
  cv_tkn_count1     CONSTANT VARCHAR2(512) := 'COUNT1';     -- カウント1
  cv_tkn_count2     CONSTANT VARCHAR2(512) := 'COUNT2';     -- カウント2
  cv_tkn_request_id CONSTANT VARCHAR2(512) := 'REQUEST_ID'; -- 要求ＩＤ
  cv_tkn_colmun1    CONSTANT VARCHAR2(512) := 'COLMUN1';    -- カラム1
  cv_tkn_colmun2    CONSTANT VARCHAR2(512) := 'COLMUN2';    -- カラム2
  cv_tkn_code       CONSTANT VARCHAR2(512) := 'CODE';       -- コード
  cv_tkn_name       CONSTANT VARCHAR2(512) := 'NAME';       -- 名称
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_wait_interval    NUMBER;                                -- 待機間隔
  gn_max_wait_time    NUMBER;                                -- 最大待機時間
  gt_order_source_id  oe_order_sources.order_source_id%TYPE; -- 受注ソースＩＤ
  gn_request_id       NUMBER;                                -- 要求ＩＤ
  gn_header_error_cnt NUMBER;                                -- 受注ヘッダOIFエラー件数
  gn_line_error_cnt   NUMBER;                                -- 受注明細OIFエラー件数
  gv_imp_warm_flg     VARCHAR2(1);                           -- 受注インポート処理の結果（警告時：'Y'）
  --
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
     iv_order_source_name IN         VARCHAR2 -- 受注ソース名称
    ,ov_errbuf            OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    cv_wait_interval CONSTANT VARCHAR2(100) := 'XXCOS1_INTERVAL_OEOIMP'; -- 待機間隔プロファイル
    cv_max_wait_time CONSTANT VARCHAR2(100) := 'XXCOS1_MAX_WAIT_OEOIMP'; -- 最大待機間隔プロファイル
    --
    -- *** ローカル変数 ***
    lv_key_info VARCHAR2(5000); -- キー情報
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
    ------------------------------------
    -- パラメータ出力
    ------------------------------------
    -- 受注ソース
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => ct_xxcos_appl_short_name -- アプリケーション短縮名
                   ,iv_name         => ct_msg_param_output      -- メッセージコード
                   ,iv_token_name1  => cv_tkn_param             -- トークンコード1
                   ,iv_token_value1 => iv_order_source_name     -- トークン値1
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => NULL
    );
    --
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => NULL
    );
    --
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
    );
    --
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => NULL
    );
    --
    ------------------------------------
    -- プロファイル値取得
    ------------------------------------
    -- 待機間隔
    gn_wait_interval := TO_NUMBER(fnd_profile.value(cv_wait_interval));
    --
    IF (gn_wait_interval IS NULL) THEN
      -- プロファイル値がNULLの場合はエラー
      xxcos_common_pkg.makeup_key_info(
         ov_errbuf      => lv_errbuf      -- エラー・メッセージ
        ,ov_retcode     => lv_retcode     -- リターンコード
        ,ov_errmsg      => lv_errmsg      -- ユーザ・エラー・メッセージ
        ,ov_key_info    => lv_key_info    -- 編集されたキー情報
        ,iv_item_name1  => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char1
                           )
        ,iv_data_value1 => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char2
                           )
      );
      --
      RAISE global_get_profile_expt;
      --
    END IF;
    --
    -- 最大待機間隔
    gn_max_wait_time := TO_NUMBER(fnd_profile.value(cv_max_wait_time));
    --
    IF (gn_max_wait_time IS NULL) THEN
      -- プロファイル値がNULLの場合はエラー
      xxcos_common_pkg.makeup_key_info(
         ov_errbuf      => lv_errbuf      -- エラー・メッセージ
        ,ov_retcode     => lv_retcode     -- リターンコード
        ,ov_errmsg      => lv_errmsg      -- ユーザ・エラー・メッセージ
        ,ov_key_info    => lv_key_info    -- 編集されたキー情報
        ,iv_item_name1  => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char1
                           )
        ,iv_data_value1 => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char3
                           )
      );
      --
      RAISE global_get_profile_expt;
      --
    END IF;
    --
    ------------------------------------
    -- 受注ソース名称変換
    ------------------------------------
    BEGIN
      SELECT oos.order_source_id -- 受注ソースＩＤ
      INTO   gt_order_source_id
      FROM   oe_order_sources oos -- 受注ソース
      WHERE  oos.name         = iv_order_source_name
      AND    oos.enabled_flag = cv_flag_yes
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        xxcos_common_pkg.makeup_key_info(
           ov_errbuf      => lv_errbuf      -- エラー・メッセージ
          ,ov_retcode     => lv_retcode     -- リターンコード
          ,ov_errmsg      => lv_errmsg      -- ユーザ・エラー・メッセージ
          ,ov_key_info    => lv_key_info    -- 編集されたキー情報
          ,iv_item_name1  => xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name
                             ,iv_name        => ct_msg_char4
                           )
          ,iv_data_value1 => iv_order_source_name
        );
        --
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_get_data_err
                       ,iv_token_name1  => cv_tkn_table_name
                       ,iv_token_value1 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char5
                                           )
                       ,iv_token_name2  => cv_tkn_key_data
                       ,iv_token_value2 => lv_key_info
                     );
        --
        RAISE global_api_others_expt;
        --
    END;
    --
  EXCEPTION
    WHEN global_get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name
                     ,iv_name         => ct_msg_get_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || ov_errmsg, 1, 5000);
      ov_retcode := cv_status_error;
      --
--#####################################  固定部 START ##########################################
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : <reg_order_proc>
   * Description      : <受注インポート>(A-2)
   ***********************************************************************************/
  PROCEDURE reg_order_proc (
     ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reg_order_proc'; -- プログラム名
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
    cv_application        CONSTANT VARCHAR2(5)  := 'ONT';     -- Application
    cv_program            CONSTANT VARCHAR2(9)  := 'OEOIMP';  -- Program
    cb_sub_request        CONSTANT BOOLEAN      := FALSE;     -- Sub_request
    cv_debug_level        CONSTANT VARCHAR2(1)  := '1';       -- デバッグ・レベル
    cv_ord_inp_inst_cnt   CONSTANT VARCHAR2(1)  := '4';       -- 受注インポート・インスタンス数
    cv_con_status_normal  CONSTANT VARCHAR2(10) := 'NORMAL';  -- ステータス（正常）
    cv_con_status_warning CONSTANT VARCHAR2(10) := 'WARNING'; -- ステータス（警告）
    --
    -- *** ローカル変数 ***
    lb_wait_result BOOLEAN;
    lv_phase       VARCHAR2(50);
    lv_status      VARCHAR2(50);
    lv_dev_phase   VARCHAR2(50);
    lv_dev_status  VARCHAR2(50);
    lv_message     VARCHAR2(5000);
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
    -- 受注インポートコンカレント起動
    gn_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_program
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => cb_sub_request
                       ,argument1   => gt_order_source_id  -- 受注ソースＩＤ
                       ,argument2   => NULL                -- 当初システム文書参照
                       ,argument3   => NULL                -- 工程コード
                       ,argument4   => cv_flag_no          -- 検証のみ？
                       ,argument5   => cv_debug_level      -- デバッグレベル
                       ,argument6   => cv_ord_inp_inst_cnt -- 受注インポートインスタンス数
                       ,argument7   => NULL                -- 販売先組織ＩＤ
                       ,argument8   => NULL                -- 販売先組織
                       ,argument9   => NULL                -- 変更順序
                       ,argument10  => cv_flag_yes         -- インスタンスの単一明細キュー使用可
                       ,argument11  => cv_flag_no          -- 後続に続くブランクのトリム
                       ,argument12  => cv_flag_yes         -- 付加フレックスのフィールド
                     );
    --
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => ct_xxcos_appl_short_name
                   ,iv_name         => ct_msg_publish_request
                   ,iv_token_name1  => cv_tkn_request_id
                   ,iv_token_value1 => TO_CHAR(gn_request_id)
                 );
    --
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => lv_errmsg
    );
    --
    IF (gn_request_id = cn_number_zero) THEN
      -- 正しく要求が発行できなかった場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => ct_xxcos_appl_short_name
                     ,iv_name        => ct_msg_order_inp_err
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- コンカレント起動のためコミット
    COMMIT;
    --
    -- コンカレントの終了待機
    lb_wait_result := fnd_concurrent.wait_for_request(
                         request_id => gn_request_id
                        ,interval   => gn_wait_interval
                        ,max_wait   => gn_max_wait_time
                        ,phase      => lv_phase
                        ,status     => lv_status
                        ,dev_phase  => lv_dev_phase
                        ,dev_status => lv_dev_status
                        ,message    => lv_message
                      );
    --
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name
                     ,iv_name         => ct_msg_time_over
                     ,iv_token_name1  => cv_tkn_request_id
                     ,iv_token_value1 => TO_CHAR(gn_request_id)
                   );
      --
      RAISE global_api_expt;
      --
    ELSIF (lv_dev_status <> cv_con_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name
                     ,iv_name         => ct_msg_imp_war_err
                     ,iv_token_name1  => cv_tkn_request_id
                     ,iv_token_value1 => TO_CHAR(gn_request_id)
                   );
      --
      IF (lv_dev_status = cv_con_status_warning ) THEN
        gv_imp_warm_flg := cv_flag_yes;
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg
        );
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => NULL
        );
      ELSE
        RAISE global_api_expt;
        --
      END IF;
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
  END reg_order_proc;
--
  /**********************************************************************************
   * Procedure Name   : <err_msg_out_proc>
   * Description      : <エラーメッセージ出力>(A-4)
   ***********************************************************************************/
  PROCEDURE err_msg_out_proc(
     iv_order_source_name IN         VARCHAR2                                -- 受注ソース名称
    ,it_account_number    IN         hz_cust_accounts.account_number%TYPE    -- 顧客コード
    ,it_account_name      IN         hz_cust_accounts.account_name%TYPE      -- 顧客名称
    ,it_request_id        IN         fnd_concurrent_requests.request_id%TYPE -- 要求ＩＤ
    ,ov_errbuf            OUT NOCOPY VARCHAR2                                -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2                                -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2                                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_msg_out_proc'; -- プログラム名
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
    cv_order_source_name_edi CONSTANT VARCHAR2(100) := 'EDI受注';
    --
    -- *** ローカル変数 ***
    lv_msg_data VARCHAR2(5000);
    --
    -- *** ローカル・カーソル ***
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
    IF (iv_order_source_name = cv_order_source_name_edi) THEN
      -- エラー情報(EDI)
      lv_msg_data := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => ct_msg_err_info          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_request_id        -- トークンコード1
                       ,iv_token_value1 => it_request_id            -- トークン値1
                       ,iv_token_name2  => cv_tkn_colmun1           -- トークンコード2
                       ,iv_token_value2 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char7
                                           )                        -- トークン値2
                       ,iv_token_name3  => cv_tkn_code              -- トークンコード3
                       ,iv_token_value3 => it_account_number        -- トークン値3
                       ,iv_token_name4  => cv_tkn_colmun2           -- トークンコード4
                       ,iv_token_value4 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char8
                                           )                        -- トークン値4
                       ,iv_token_name5  => cv_tkn_name              -- トークンコード5
                       ,iv_token_value5 => it_account_name          -- トークン値5
                     );
      --
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => lv_msg_data
      );
      --
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => NULL
      );
      --
    ELSE
      -- エラー情報(顧客)
      lv_msg_data := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => ct_msg_err_info          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_request_id        -- トークンコード1
                       ,iv_token_value1 => it_request_id            -- トークン値1
                       ,iv_token_name2  => cv_tkn_colmun1           -- トークンコード2
                       ,iv_token_value2 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char9
                                           )                        -- トークン値2
                       ,iv_token_name3  => cv_tkn_code              -- トークンコード3
                       ,iv_token_value3 => it_account_number        -- トークン値3
                       ,iv_token_name4  => cv_tkn_colmun2           -- トークンコード4
                       ,iv_token_value4 => xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name
                                             ,iv_name        => ct_msg_char10
                                           )                        -- トークン値4
                       ,iv_token_name5  => cv_tkn_name              -- トークンコード5
                       ,iv_token_value5 => it_account_name          -- トークン値5
                     );
      --
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => lv_msg_data
      );
      --
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => NULL
      );
      --
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
  END err_msg_out_proc;
--
  /**********************************************************************************
   * Procedure Name   : <err_chk_proc>
   * Description      : <エラーチェック>(A-3)
   ***********************************************************************************/
  PROCEDURE err_chk_proc(
     iv_order_source_name IN         VARCHAR2 -- 受注ソース名称
    ,ov_errbuf            OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_chk_proc'; -- プログラム名
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
    cv_order_source_name_edi CONSTANT VARCHAR2(100)                             := 'EDI受注';
    cv_cust_code_cust        CONSTANT hz_cust_accounts.customer_class_code%TYPE := '10'; -- 顧客区分=顧客
    cv_cust_code_chain       CONSTANT hz_cust_accounts.customer_class_code%TYPE := '18'; -- 顧客区分=チェーン店
    --
    -- *** ローカル変数 ***
    lv_msg_data VARCHAR2(3000);
    --
    -- *** ローカル・カーソル ***
    -- EDI用カーソル
    CURSOR get_edi_err_info_cur
    IS
      SELECT xca2.edi_chain_code account_number -- チェーン店コード(EDI)
            ,hca2.account_name   account_name   -- チェーン店名称
            ,fcr.request_id      request_id     -- 要求ＩＤ
      FROM   fnd_concurrent_requests fcr  -- コンカレント要求表
            ,oe_headers_iface_all    ohi  -- 受注ヘッダOIF
            ,oe_lines_iface_all      oli  -- 受注明細OIF
            ,hz_cust_accounts        hca  -- 顧客マスタ
            ,xxcmm_cust_accounts     xca  -- 顧客アドオンマスタ
            ,hz_cust_accounts        hca2 -- 顧客マスタ(EDI)
            ,xxcmm_cust_accounts     xca2 -- 顧客アドオンマスタ(EDI)
      WHERE  fcr.parent_request_id     = gn_request_id
      AND    fcr.request_id            = ohi.request_id
      AND    fcr.request_id            = oli.request_id
      AND    ohi.orig_sys_document_ref = oli.orig_sys_document_ref
      AND    (
                  ohi.error_flag = cv_flag_yes
               OR oli.error_flag = cv_flag_yes
             )
      AND    hca.account_number       = ohi.customer_number
      AND    hca.customer_class_code  = cv_cust_code_cust
      AND    hca.cust_account_id      = xca.customer_id
      AND    hca2.customer_class_code = cv_cust_code_chain
      AND    hca2.cust_account_id     = xca2.customer_id
      AND    xca.chain_store_code     = xca2.edi_chain_code
      GROUP BY xca2.edi_chain_code
              ,hca2.account_name
              ,fcr.request_id
      ORDER BY fcr.request_id ASC
      ;
      --
    -- CSV用カーソル
    CURSOR get_csv_err_info_cur
    IS
      SELECT 
/* 2009/11/10 Ver.1.1 Add Start */
             /*+ use_nl(fcr ohi oli) */
/* 2009/11/10 Ver.1.1 Add Start */
             hca.account_number account_number -- 顧客コード
            ,hca.account_name   account_name   -- 顧客名称
            ,fcr.request_id     request_id     -- 要求ＩＤ
      FROM   fnd_concurrent_requests fcr  -- コンカレント要求表
            ,oe_headers_iface_all    ohi  -- 受注ヘッダOIF
            ,oe_lines_iface_all      oli  -- 受注明細OIF
            ,hz_cust_accounts        hca  -- 顧客マスタ
            ,xxcmm_cust_accounts     xca  -- 顧客アドオンマスタ
/* 2009/11/10 Ver.1.1 Del Start */
--            ,hz_cust_accounts        hca2 -- 顧客マスタ(EDI)
--            ,xxcmm_cust_accounts     xca2 -- 顧客アドオンマスタ(EDI)
/* 2009/11/10 Ver.1.1 Del End   */
      WHERE  fcr.parent_request_id     = gn_request_id
      AND    fcr.request_id            = ohi.request_id
      AND    fcr.request_id            = oli.request_id
      AND    ohi.orig_sys_document_ref = oli.orig_sys_document_ref
      AND    (
                  ohi.error_flag = cv_flag_yes
               OR oli.error_flag = cv_flag_yes
             )
      AND    hca.account_number       = ohi.customer_number
      AND    hca.customer_class_code  = cv_cust_code_cust
      AND    hca.cust_account_id      = xca.customer_id
      GROUP BY hca.account_number
              ,hca.account_name
              ,fcr.request_id
      ORDER BY fcr.request_id ASC
      ;
    --
    -- *** ローカル・レコード ***
    lt_err_info_rec get_csv_err_info_cur%ROWTYPE;
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
    -- ヘッダエラー件数取得
    SELECT COUNT(1)
    INTO   gn_header_error_cnt
    FROM   fnd_concurrent_requests fcr -- コンカレント要求表
          ,oe_headers_iface_all    ohi -- 受注ヘッダOIF
    WHERE  fcr.parent_request_id = gn_request_id
    AND    fcr.request_id        = ohi.request_id
    AND    ohi.error_flag        = cv_flag_yes
    ;
    --
    -- 明細エラー件数取得
    SELECT COUNT(1)
    INTO   gn_line_error_cnt
    FROM   fnd_concurrent_requests fcr -- コンカレント要求表
          ,oe_headers_iface_all    ohi -- 受注ヘッダOIF
          ,oe_lines_iface_all      oli -- 受注明細OIF
    WHERE  fcr.parent_request_id     = gn_request_id
    AND    fcr.request_id            = ohi.request_id
    AND    fcr.request_id            = oli.request_id
    AND    ohi.orig_sys_document_ref = oli.orig_sys_document_ref
    AND    oli.error_flag            = cv_flag_yes
    ;
    --
    IF (gn_header_error_cnt > cn_number_zero
      OR gn_line_error_cnt > cn_number_zero)
    THEN
      -- エラーデータ取得
      IF (iv_order_source_name = cv_order_source_name_edi) THEN
        OPEN get_edi_err_info_cur;
        --
      ELSE
        OPEN get_csv_err_info_cur;
        --
      END IF;
      --
      <<get_err_info_loop>>
      LOOP
        BEGIN
          IF (iv_order_source_name = cv_order_source_name_edi) THEN
            FETCH get_edi_err_info_cur INTO lt_err_info_rec;
            --
          ELSE
            FETCH get_csv_err_info_cur INTO lt_err_info_rec;
            --
          END IF;
          --
        EXCEPTION
          WHEN OTHERS THEN
            -- 取得に失敗した場合
            IF (get_edi_err_info_cur%ISOPEN) THEN
              CLOSE get_edi_err_info_cur;
              --
            END IF;
            --
            IF (get_csv_err_info_cur%ISOPEN) THEN
              CLOSE get_csv_err_info_cur;
              --
            END IF;
            --
            lv_msg_data := xxccp_common_pkg.get_msg(
                              iv_application => ct_xxcos_appl_short_name -- アプリケーション短縮名
                             ,iv_name        => ct_msg_err_chk_failed    -- メッセージコード
                           );
            --
            RAISE global_api_expt;
            --
        END;
        --
        IF (iv_order_source_name = cv_order_source_name_edi) THEN
          EXIT WHEN get_edi_err_info_cur%NOTFOUND
            OR get_edi_err_info_cur%ROWCOUNT = 0;
          --
        ELSE
          EXIT WHEN get_csv_err_info_cur%NOTFOUND
            OR get_csv_err_info_cur%ROWCOUNT = 0;
          --
        END IF;
        --
        -- エラーメッセージ出力
        err_msg_out_proc(
           iv_order_source_name => iv_order_source_name
          ,it_account_number    => lt_err_info_rec.account_number
          ,it_account_name      => lt_err_info_rec.account_name
          ,it_request_id        => lt_err_info_rec.request_id
          ,ov_errbuf            => lv_errbuf
          ,ov_retcode           => lv_retcode
          ,ov_errmsg            => lv_errmsg
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
          --
        END IF;
        --
      END LOOP get_err_info_loop;
      --
      IF (iv_order_source_name = cv_order_source_name_edi) THEN
        CLOSE get_edi_err_info_cur;
        --
      ELSE
        CLOSE get_csv_err_info_cur;
        --
      END IF;
      --
    END IF;
    --
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
/* 2009/11/10 Ver.1.1 Add Start */
      -- カーソルがオープンしている場合、クローズ
      IF (get_edi_err_info_cur%ISOPEN) THEN
        CLOSE get_edi_err_info_cur;
        --
      END IF;
      --
      IF (get_csv_err_info_cur%ISOPEN) THEN
        CLOSE get_csv_err_info_cur;
        --
      END IF;
/* 2009/11/10 Ver.1.1 Add End   */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
/* 2009/11/10 Ver.1.1 Add Start */
      -- カーソルがオープンしている場合、クローズ
      IF (get_edi_err_info_cur%ISOPEN) THEN
        CLOSE get_edi_err_info_cur;
        --
      END IF;
      --
      IF (get_csv_err_info_cur%ISOPEN) THEN
        CLOSE get_csv_err_info_cur;
        --
      END IF;
/* 2009/11/10 Ver.1.1 Add End   */
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
/* 2009/11/10 Ver.1.1 Add Start */
      -- カーソルがオープンしている場合、クローズ
      IF (get_edi_err_info_cur%ISOPEN) THEN
        CLOSE get_edi_err_info_cur;
        --
      END IF;
      --
      IF (get_csv_err_info_cur%ISOPEN) THEN
        CLOSE get_csv_err_info_cur;
        --
      END IF;
/* 2009/11/10 Ver.1.1 Add End   */
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END err_chk_proc;
--
  /**********************************************************************************
   * Procedure Name   : <end_proc>
   * Description      : <終了処理>(A-5)
   ***********************************************************************************/
  PROCEDURE end_proc(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_proc'; -- プログラム名
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
--
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    lv_msg_data VARCHAR2(3000);
    --
    -- *** ローカル・カーソル ***
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
    lv_msg_data := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name -- アプリケーション短縮名
                     ,iv_name         => ct_msg_err_cnt           -- メッセージコード
                     ,iv_token_name1  => cv_tkn_count1            -- トークンコード1
                     ,iv_token_value1 => gn_header_error_cnt      -- トークン値1
                     ,iv_token_name2  => cv_tkn_count2            -- トークンコード2
                     ,iv_token_value2 => gn_line_error_cnt        -- トークン値2
                   );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_msg_data
    );
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
  END end_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_order_source_name IN         VARCHAR2 -- 受注ソース名称
    ,ov_errbuf            OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_wait_interval    := 0;
    gn_max_wait_time    := 0;
    gt_order_source_id  := 0;
    gn_request_id       := 0;
    gn_header_error_cnt := 0;
    gn_line_error_cnt   := 0;
    gv_imp_warm_flg     := NULL;
    --
    -- --------------------------------------------------------------------
    -- * init_proc         初期処理                                   (A-1)
    -- --------------------------------------------------------------------
    init_proc(
       iv_order_source_name => iv_order_source_name -- 受注ソース名称
      ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- --------------------------------------------------------------------
    -- * reg_order_proc   受注インポート                              (A-2)
    -- --------------------------------------------------------------------
    reg_order_proc (
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- --------------------------------------------------------------------
    -- * err_chk_proc       エラーチェック                            (A-3)
    -- --------------------------------------------------------------------
    err_chk_proc(
       iv_order_source_name => iv_order_source_name -- 受注ソース名称
      ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- --------------------------------------------------------------------
    -- * end_proc         終了処理                                    (A-5)
    -- --------------------------------------------------------------------
    end_proc(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    IF ( gn_header_error_cnt > cn_number_zero
      OR gn_line_error_cnt > cn_number_zero
      OR gv_imp_warm_flg = cv_flag_yes )
    THEN
      -- エラーが１件でもあった場合は警告終了
      ov_retcode := cv_status_warn;
      --
    END IF;
    --
  EXCEPTION
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
     errbuf            OUT VARCHAR2 -- エラー・メッセージ  --# 固定 #
    ,retcode           OUT VARCHAR2 -- リターン・コード    --# 固定 #
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
    ,iv_order_source_name IN VARCHAR2 -- 受注ソース名称
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
       iv_order_source_name -- 受注ソース名称
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    --*** エラー出力は要件によって使い分けてください ***--
--    --エラー出力
--    IF (lv_retcode = cv_status_error) THEN
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errbuf --エラーメッセージ
--      );
--    END IF;
    --エラー出力：「警告」かつ「mainでメッセージを出力」する要件のある場合
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
/*  不必要
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_get_h_count
                    ,iv_token_name1  => cv_tkn_param1
                    ,iv_token_value1 => TO_CHAR(gn_hed_Suc_cnt)
                    ,iv_token_name2  => cv_tkn_param2
                    ,iv_token_value2 => TO_CHAR(gn_line_Suc_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
*/
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
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
END XXCOS010A06C;
/
