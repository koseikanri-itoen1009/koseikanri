CREATE OR REPLACE PACKAGE BODY APPS.XXCFR003A20C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCFR003A20C(body)
 * Description      : 店舗別明細出力
 * MD.050           : MD050_CFR_003_A20_店舗別明細出力
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  exe_svf                SVF起動(A-2)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------
 *  2015/07/23    1.0   SCSK 小路 恭弘   新規作成
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
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCFR003A20';             -- パッケージ名
  -- アプリケーション短縮名
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCFR';                   -- アプリケーション
  -- 帳票名
  cv_svf_name                 CONSTANT VARCHAR2(20) := 'XXCFR003A20';             -- 帳票名
  -- メッセージ
  cv_msg_xxcfr_00011          CONSTANT VARCHAR2(16) := 'APP-XXCFR1-00011';        -- APIエラーメッセージ
  cv_msg_xxcfr_00024          CONSTANT VARCHAR2(16) := 'APP-XXCFR1-00024';        -- 帳票０件ログメッセージ
  cv_msg_xxcfr_00152          CONSTANT VARCHAR2(16) := 'APP-XXCFR1-00152';        -- パラメータ出力メッセージ
  cv_msg_xxcfr_00153          CONSTANT VARCHAR2(16) := 'APP-XXCFR1-00153';        -- 請求書タイプ定義なしエラーメッセージ
  -- トークンコード
  cv_tkn_param1               CONSTANT VARCHAR2(30) := 'PARAM1';                  -- パラメータ名１
  cv_tkn_param2               CONSTANT VARCHAR2(30) := 'PARAM2';                  -- パラメータ名２
  cv_tkn_param3               CONSTANT VARCHAR2(30) := 'PARAM3';                  -- パラメータ名３
  cv_tkn_param4               CONSTANT VARCHAR2(30) := 'PARAM4';                  -- パラメータ名４
  cv_tkn_lookup_type          CONSTANT VARCHAR2(30) := 'LOOKUP_TYPE';             -- 参照タイプ
  cv_tkn_lookup_code          CONSTANT VARCHAR2(30) := 'LOOKUP_CODE';             -- 参照コード
  cv_tkn_api                  CONSTANT VARCHAR2(30) := 'API_NAME';                -- API名
  -- 日本語辞書
  cv_dict_svf                 CONSTANT VARCHAR2(30) := 'CFR000A00004';            -- SVF起動
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_report_type              IN  VARCHAR2  -- 帳票区分
   ,iv_bill_type                IN  VARCHAR2  -- 請求書タイプ
   ,in_org_request_id           IN  NUMBER    -- 発行元要求ID
   ,in_target_cnt               IN  NUMBER    -- 対象件数
   ,ov_svf_file_xml             OUT VARCHAR2  -- 帳票フォームファイル名
   ,ov_svf_file_vrq             OUT VARCHAR2  -- 帳票クエリーファイル名
   ,ov_errbuf                   OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                  OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  ) 
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
    -- 参照タイプ
    cv_xxcfr_bill_type          CONSTANT VARCHAR2(19) := 'XXCFR1_BILL_TYPE';     -- 請求書タイプ
    -- 有効
    cv_enabled_flag             CONSTANT VARCHAR2(1)  := 'Y';                    -- 有効
    -- 帳票拡張子
    cv_xml                      CONSTANT VARCHAR2(4)  := '.xml';                 -- フォームファイル
    cv_vrq                      CONSTANT VARCHAR2(4)  := '.vrq';                 -- クエリーファイル
--
    -- *** ローカル変数 ***
    lv_param_msg                VARCHAR2(5000);                         -- パラメータ出力用
    lv_file_id                  VARCHAR2(3);                            -- 帳票ID
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
    -- パラメータ出力
    --==============================================================
    --メッセージ編集
    lv_param_msg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_application              -- アプリケーション
                      , iv_name          => cv_msg_xxcfr_00152          -- メッセージコード
                      , iv_token_name1   => cv_tkn_param1               -- トークンコード１
                      , iv_token_value1  => iv_report_type              -- 帳票区分
                      , iv_token_name2   => cv_tkn_param2               -- トークンコード２
                      , iv_token_value2  => iv_bill_type                -- 請求書タイプ
                      , iv_token_name3   => cv_tkn_param3               -- トークンコード３
                      , iv_token_value3  => TO_CHAR(in_org_request_id)  -- 発行元要求ID
                      , iv_token_name4   => cv_tkn_param4               -- トークンコード４
                      , iv_token_value4  => TO_CHAR(in_target_cnt)      -- 処理件数
                    );
    -- ログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- 帳票ID取得
    --==================================
    BEGIN
      SELECT flvv.meaning AS file_id
      INTO   lv_file_id
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type  = cv_xxcfr_bill_type
      AND    flvv.lookup_code  = iv_bill_type
      AND    flvv.enabled_flag = cv_enabled_flag
      AND    TRUNC(NVL(flvv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
      AND    TRUNC(NVL(flvv.end_date_active,   SYSDATE)) >= TRUNC(SYSDATE)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application         -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcfr_00153     -- メッセージコード
                         , iv_token_name1  => cv_tkn_lookup_type     -- トークンコード1
                         , iv_token_value1 => cv_xxcfr_bill_type     -- トークン値1
                         , iv_token_name2  => cv_tkn_lookup_code     -- トークンコード2
                         , iv_token_value2 => iv_bill_type           -- トークン値2
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- ファイル名編集
    --==================================
    -- 帳票フォームファイル名編集
    ov_svf_file_xml := cv_svf_name || lv_file_id || cv_xml;
    -- 帳票クエリーファイル名編集
    ov_svf_file_vrq := cv_svf_name || lv_file_id || cv_vrq;
--
  EXCEPTION
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : exe_svf
   * Description      : SVF起動(A-2)
   ***********************************************************************************/
  PROCEDURE exe_svf(
     iv_report_type         IN  VARCHAR2                 -- 帳票区分
    ,iv_svf_form_nm         IN  VARCHAR2                 -- 帳票フォームファイル名
    ,iv_svf_query_nm        IN  VARCHAR2                 -- 帳票クエリーファイル名
    ,in_org_request_id      IN  NUMBER                   -- 発行元要求ID
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'exe_svf';     -- プログラム名
----#####################  固定ローカル変数宣言部 START   ########################
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
    -- 日付書式
    cv_yyyymmdd            CONSTANT VARCHAR2(10) := 'YYYYMMDD';                -- YYYYMMDD型
    -- SVF条件
    cv_condition_request   CONSTANT VARCHAR2(13) := '[REQUEST_ID]=';           -- SVF条件
    -- コンカレントプログラム名
    cv_conc_name           CONSTANT VARCHAR2(12) := 'XXCFR003A20C';            -- コンカレントプログラム名
--
    -- *** ローカル変数 ***
    lv_svf_file_name   VARCHAR2(50);
    lv_svf_param1      VARCHAR2(50);
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ファイル名の設定
    lv_svf_file_name := cv_svf_name
                       || TO_CHAR (cd_creation_date, cv_yyyymmdd)
                       || TO_CHAR (cn_request_id);
--
    -- SVF抽出条件の設定
    lv_svf_param1 := cv_condition_request || TO_CHAR( in_org_request_id );
--
    -- ==========================================================
    -- コンカレント・プログラム名およびログイン・ユーザ情報取得
    -- ==========================================================
    BEGIN
      SELECT  fcp.concurrent_program_name   AS conc_name  --コンカレント・プログラム名
             ,xx00_global_pkg.user_name     AS user_name  --ログイン・ユーザ名
             ,xx00_global_pkg.resp_name     AS resp_name  --職責名
      INTO    lv_conc_name
             ,lv_user_name
             ,lv_resp_name
      FROM    fnd_concurrent_programs    fcp
      WHERE   fcp.concurrent_program_id = cn_program_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_conc_name;
    END;
--
    -- ===============================
    -- SVF起動
    -- ===============================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_svf_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_conc_name    => lv_conc_name          -- コンカレント名
     ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
     ,iv_file_id      => cv_svf_name           -- 帳票ID
     ,iv_output_mode  => iv_report_type        -- 出力区分
     ,iv_frm_file     => iv_svf_form_nm        -- 帳票フォームファイル名
     ,iv_vrq_file     => iv_svf_query_nm       -- 帳票クエリーファイル名
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
     ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                  -- 文書名
     ,iv_printer_name => NULL                  -- プリンタ名
     ,iv_request_id   => cn_request_id         -- 要求ID
     ,iv_nodata_msg   => NULL                  -- データなしメッセージ
     ,iv_svf_param1   => lv_svf_param1         -- SVF抽出条件1
     );
--
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_application       -- 'XXCFR'
                                                     ,cv_msg_xxcfr_00011   -- APIエラー
                                                     ,cv_tkn_api           -- トークン'API_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        cv_application
                                                       ,cv_dict_svf 
                                                      )  -- SVF起動
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg;
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
--#####################################  固定部 END   ##########################################
--
  END exe_svf;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_report_type              IN  VARCHAR2  -- 帳票区分
   ,iv_bill_type                IN  VARCHAR2  -- 請求書タイプ
   ,in_org_request_id           IN  NUMBER    -- 発行元要求ID
   ,in_target_cnt               IN  NUMBER    -- 対象件数
   ,ov_errbuf                   OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                  OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- ユーザー定義ローカル変数
    -- ===============================
    lv_svf_file_xml             VARCHAR2(100) DEFAULT NULL;             -- 帳票フォームファイル名
    lv_svf_file_vrq             VARCHAR2(100) DEFAULT NULL;             -- 帳票クエリーファイル名
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- カウンタの初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_report_type    => iv_report_type    -- 帳票区分
      ,iv_bill_type      => iv_bill_type      -- 請求書タイプ
      ,in_org_request_id => in_org_request_id -- 発行元要求ID
      ,in_target_cnt     => in_target_cnt     -- 対象件数
      ,ov_svf_file_xml   => lv_svf_file_xml   -- 帳票フォームファイル名
      ,ov_svf_file_vrq   => lv_svf_file_vrq   -- 帳票クエリーファイル名
      ,ov_errbuf         => lv_errbuf         -- エラー・メッセージ            --# 固定 #
      ,ov_retcode        => lv_retcode        -- リターン・コード              --# 固定 #
      ,ov_errmsg         => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- 初期処理成功の場合、対象件数カウント
    gn_target_cnt := in_target_cnt;
--
    -- ===============================
    -- SVF起動(A-2)
    -- ===============================
    exe_svf(
       iv_report_type    => iv_report_type    -- 帳票区分
      ,iv_svf_form_nm    => lv_svf_file_xml   -- 帳票フォームファイル名
      ,iv_svf_query_nm   => lv_svf_file_vrq   -- 帳票クエリーファイル名
      ,in_org_request_id => in_org_request_id -- 発行元要求ID
      ,ov_errbuf         => lv_errbuf         -- エラー・メッセージ            --# 固定 #
      ,ov_retcode        => lv_retcode        -- リターン・コード              --# 固定 #
      ,ov_errmsg         => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- 成功件数カウント
    gn_normal_cnt := in_target_cnt;
    -- 成功件数が0件の場合
    IF ( gn_normal_cnt = 0 ) THEN
      -- 警告終了
      ov_retcode := cv_status_warn;
      --メッセージ編集
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_application              -- アプリケーション
                     , iv_name          => cv_msg_xxcfr_00024          -- メッセージコード
                   );
      -- ログ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
    errbuf                      OUT VARCHAR2  -- エラーメッセージ #固定#
   ,retcode                     OUT VARCHAR2  -- エラーコード     #固定#
   ,iv_report_type              IN  VARCHAR2  -- 帳票区分
   ,iv_bill_type                IN  VARCHAR2  -- 請求書タイプ
   ,in_org_request_id           IN  NUMBER    -- 発行元要求ID
   ,in_target_cnt               IN  NUMBER    -- 対象件数
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
        iv_report_type              -- 帳票区分
      , iv_bill_type                -- 請求書タイプ
      , in_org_request_id           -- 発行元要求ID
      , in_target_cnt               -- 対象件数
      , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- 終了処理(A-3)
    -- ===============================
    -- 空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      -- 件数の設定
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      -- ログ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      --
    END IF;
--
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF( lv_retcode = cv_status_warn ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF( lv_retcode = cv_status_error ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_msg
                     );
    END IF;
--
    -- 終了メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
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
END XXCFR003A20C;
/
