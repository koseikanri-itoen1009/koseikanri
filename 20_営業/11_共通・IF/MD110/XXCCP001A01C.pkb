CREATE OR REPLACE PACKAGE BODY APPS.XXCCP001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP001A01C(spec)
 * Description      : 業務日付照会更新
 * MD.050           : MD050_CCP_001_A01_業務日付更新照会
 * Version          : 1.02
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  con_get_process_date   業務日付照会処理(A-2)
 *  update_process_date    業務日付更新処理(A-3)
 *  insert_process_date    業務日付登録処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(後処理)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.00  渡辺直樹         新規作成
 *  2009/05/01    1.01  Masayuki.Sano    障害番号T1_0910対応(スキーマ名付加)
 *  2009/06/01    1.02  Masayuki.Sano    障害番号T1_1276対応(コンカレント･ログ出力対応)
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  --異常:2
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
  --WHOカラム
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE          := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE          := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE          := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
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
  parameter_error_expt   EXCEPTION;
  get_process_error_expt EXCEPTION;
  get_profile_error      EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP001A01C'; -- パッケージ名
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf       OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    ,iv_handle_area  IN  VARCHAR2     --   処理区分
    ,iv_process_date IN  VARCHAR2)    --   業務日付
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'init';             -- プログラム名
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
    cv_profile_name1  CONSTANT VARCHAR2(100) := 'XXCCP1_HANDLE_AREA';   --処理区分
    cv_profile_name2  CONSTANT VARCHAR2(100) := 'XXCCP1_PROCESS_DATE';  --業務日付
    cv_message_name1  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10015';     --入力パラメータエラーメッセージ
    cv_message_name2  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10016';     --プロファイル取得エラーメッセージ
    cv_token_name1    CONSTANT VARCHAR2(100) := 'ITEM';                 --トークン名
--
    -- *** ローカル変数 ***
    lv_profile        VARCHAR2(100);  --入力パラメータ出力用変数
    lv_profile1       VARCHAR2(100);  --入力パラメータ出力用変数
    lv_profile2       VARCHAR2(100);  --入力パラメータ出力用変数
    ld_process_date   VARCHAR2(100);  --入力パラメータ出力用変数
--
  BEGIN
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/06/01 Ver1.02 Add Start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/06/01 Ver1.02 Add End
    lv_profile1 := FND_PROFILE.VALUE(cv_profile_name1);
    IF (lv_profile1 IS NULL) THEN
      RAISE get_profile_error;
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_profile1||cv_msg_part||iv_handle_area
    );
-- 2009/06/01 Ver1.02 Add Start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_profile1||cv_msg_part||iv_handle_area
    );
-- 2009/06/01 Ver1.02 Add End
    lv_profile2 := FND_PROFILE.VALUE(cv_profile_name2);
    IF (lv_profile2 IS NULL) THEN
      RAISE get_profile_error;
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_profile2||cv_msg_part||iv_process_date
    );
-- 2009/06/01 Ver1.02 Add Start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_profile2||cv_msg_part||iv_process_date
    );
-- 2009/06/01 Ver1.02 Add End
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/06/01 Ver1.02 Add Start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/06/01 Ver1.02 Add End
    IF (iv_handle_area NOT IN ('1','2'))
      OR (iv_handle_area IS NULL) THEN
        lv_profile := lv_profile1;
        RAISE parameter_error_expt;
    ELSIF (iv_handle_area = 1)
      AND (iv_process_date IS NOT NULL) THEN
        BEGIN
        ld_process_date := TO_DATE(iv_process_date,'YYYYMMDD');
      --
        EXCEPTION
          WHEN OTHERS THEN
            lv_profile := lv_profile2;
            RAISE parameter_error_expt;
        END;
    END IF;
    ov_retcode := cv_status_normal;
  --
  EXCEPTION
    WHEN parameter_error_expt THEN
      --「入力パラメータエラーメッセージ」取得
      -- ITEMの値が不正です。
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_message_name1
                      ,iv_token_name1  => cv_token_name1
                      ,iv_token_value1 => lv_profile
                    );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    WHEN get_profile_error THEN
      --「プロファイル取得エラーメッセージ」取得
      --プロファイルの取得に失敗しました。
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_message_name2
                    );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : con_get_process_date
   * Description      : 業務日付参照処理(A-2)
   ***********************************************************************************/
  PROCEDURE con_get_process_date(
    iv_handle_area  IN  VARCHAR2      --   処理区分
   ,ov_errbuf       OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode      OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg       OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
   ,ov_process_date OUT VARCHAR2)     --   業務日付
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- プログラム名
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
    cv_message_name    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10013'; --参照異常エラーメッセージ
    cv_token_name      VARCHAR2(100) := 'RTNCD';                     --トークン名
    cn_process_date_id NUMBER        := 1;                           --業務日付テーブル主キー
--
    -- *** ローカル変数 ***
    lv_output DATE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT process_date
    INTO   lv_output
    FROM   xxccp_process_dates
    WHERE  process_date_id = cn_process_date_id
    ;
    ov_process_date :=lv_output;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      IF (iv_handle_area = '2') THEN
      --参照異常エラーメッセージ
      --業務日付の取得に失敗しました。（リターンコード：「  」）
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_message_name
                        ,iv_token_name1  => cv_token_name
                        ,iv_token_value1 => SQLCODE
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
      ELSIF (iv_handle_area = '1') THEN
        ov_process_date := NULL;
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END con_get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : update_process_date
   * Description      : 業務日付更新処理(A-3)
   ***********************************************************************************/
  PROCEDURE update_process_date(
    iv_process_date IN  VARCHAR2      --   入力パラメータ：業務日付
   ,ov_errbuf       OUT VARCHAR2      --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode      OUT VARCHAR2      --   リターン・コード                    --# 固定 #
   ,ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_process_date'; -- プログラム名
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
    cv_profile_name   VARCHAR2(100) := 'XXCCP1_PROCESS_DATE';  --業務日付
    cv_message_name   VARCHAR2(100) := 'APP-XXCCP1-10012';     --更新異常エラーメッセージ
    cv_message_name2  VARCHAR2(100) := 'APP-XXCCP1-30001';     --更新正常終了メッセージ
    cv_token_name1    VARCHAR2(100) := 'DATE';                 --トークン名
    cv_token_name2    VARCHAR2(100) := 'RTNCD';                --トークン値
--
    -- *** ローカル変数 ***
    ld_process_date DATE;  --業務日付格納用変数
    lv_message      VARCHAR2(1000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF (iv_process_date IS NULL) THEN
      ld_process_date := TRUNC(SYSDATE,'DD');
    ELSIF (iv_process_date IS NOT NULL) THEN
      ld_process_date := TO_DATE(iv_process_date,'YYYYMMDD');
    END IF;
    --
    UPDATE xxccp.xxccp_process_dates
    SET
      process_date           = ld_process_date
     ,last_updated_by        = cn_last_updated_by
     ,last_update_date       = cd_last_update_date
     ,last_update_login      = cn_last_update_login
     ,request_id             = cn_request_id
     ,program_application_id = cn_program_application_id
     ,program_id             = cn_program_id
     ,program_update_date    = cd_program_update_date
    WHERE
      process_date_id = 1;
    --
    lv_message := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_message_name2
                       ,iv_token_name1  => cv_token_name1
                       ,iv_token_value1 => TO_CHAR(ld_process_date,'YYYY/MM/DD')
                    );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_message
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --更新異常エラーメッセージ
      --業務日付の更新に失敗しました。（リターンコード：「 RTNCD 」）
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_message_name
                       ,iv_token_name1  => cv_token_name2
                       ,iv_token_value1 => SQLCODE
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_process_date;
--
  /**********************************************************************************
   * Procedure Name   : insert_process_date
   * Description      : 業務日付登録処理(A-4)
   ***********************************************************************************/
  PROCEDURE insert_process_date(
     iv_process_date IN  VARCHAR2      --   業務日付
    ,ov_errbuf       OUT VARCHAR2      --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode      OUT VARCHAR2      --   リターン・コード                    --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_process_date'; -- プログラム名
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
    cv_profile_name    VARCHAR2(100) := 'XXCCP1_PROCESS_DATE';  --業務日付
    cv_message_name    VARCHAR2(100) := 'APP-XXCCP1-10017';     --登録異常エラーメッセージ
    cv_message_name2   VARCHAR2(100) := 'APP-XXCCP1-30002';     --登録正常終了メッセージ
    cv_token_name1     VARCHAR2(100) := 'DATE';                 --トークン名
    cv_token_name2     VARCHAR2(100) := 'RTNCD';                --トークン名
    cn_process_date_id NUMBER        := 1;                      --業務日付テーブル主キー
--
    -- *** ローカル変数 ***
    ld_process_date DATE;           --業務日付格納用変数
    lv_message      VARCHAR2(1000); --メッセージ出力用変数
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF (iv_process_date IS NULL) THEN
      ld_process_date := TRUNC(SYSDATE,'DD');
    ELSIF (iv_process_date IS NOT NULL) THEN
      ld_process_date := TO_DATE(iv_process_date,'YYYYMMDD');
    END IF;
    --
    INSERT INTO xxccp.xxccp_process_dates(
       process_date_id
      ,process_date
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       cn_process_date_id
      ,ld_process_date
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
    );
    --
    lv_message := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_message_name2
                       ,iv_token_name1  => cv_token_name1
                       ,iv_token_value1 => TO_CHAR(ld_process_date,'YYYY/MM/DD')
                    );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_message
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --登録異常エラーメッセージ
      --業務日付の登録に失敗しました。（リターンコード：「 RTNCD 」）
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_message_name
                       ,iv_token_name1  => cv_token_name2
                       ,iv_token_value1 => SQLCODE
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_process_date;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_handle_area  IN  VARCHAR2
    ,iv_process_date IN  VARCHAR2
    ,ov_errbuf       OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2      --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';              --プログラム名
    cv_profile_name2  CONSTANT VARCHAR2(100) := 'XXCCP1_HANDLE_AREA';   --処理区分
    cv_message_name1  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10015';     --入力パラメータエラーメッセージ
    cv_token_name1    CONSTANT VARCHAR2(100) := 'ITEM';                 --トークン名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);     -- リターン・コード
    lv_errmsg        VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_handle_area   VARCHAR2(100);
    lv_process_date  VARCHAR2(100);
    lv_process_date2 DATE;
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--  
    lv_handle_area  := iv_handle_area;
    lv_process_date := iv_process_date;
    --(処理部呼び出し)
    init(lv_errbuf         --   エラー・メッセージ           --# 固定 #
        ,lv_retcode        --   リターン・コード             --# 固定 #
        ,lv_errmsg         --   ユーザー・エラー・メッセージ --# 固定 #
        ,lv_handle_area
        ,lv_process_date);
    IF (lv_retcode = cv_status_normal) THEN
      con_get_process_date(
             lv_handle_area
            ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
            ,lv_retcode       -- リターン・コード             --# 固定 #
            ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
            ,lv_process_date2
      );
      IF (iv_handle_area = '2') THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => TO_CHAR(lv_process_date2,'YYYY/MM/DD')
        );
      ELSIF (iv_handle_area = '1') THEN
        IF (lv_process_date2 IS NOT NULL) THEN
        update_process_date(
              iv_process_date
             ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
             ,lv_retcode        -- リターン・コード             --# 固定 #
             ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        ELSE
        insert_process_date(
              iv_process_date
             ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
             ,lv_retcode        -- リターン・コード             --# 固定 #
             ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        END IF;
      END IF;
    END IF;
--
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
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
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_handle_area  IN  VARCHAR2,      --   処理区分
    iv_process_date IN  VARCHAR2       --   業務日付
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
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
       iv_handle_area
      ,iv_process_date
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    gn_target_cnt := gn_target_cnt + 1;
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    ELSE
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
END XXCCP001A01C;
/
