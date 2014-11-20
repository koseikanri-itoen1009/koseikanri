CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A10C(body)
 * Description      : 受注一覧＆受注エラーリスト発行
 * MD.050           : MD050_COS_009_A10_受注一覧＆受注エラーリスト発行
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  exe_xxcos009a01r       受注一覧リスト発行処理(A-2)
 *  exe_xxcos010a05r_1     受注エラーリスト（受注）発行処理(A-3)
 *  exe_xxcos010a05r_2     受注エラーリスト（納品確定）発行処理(A-4)
 *  func_wait_for_request  コンカレント終了待機処理関数
 *  wait_for_request       コンカレント終了待機処理(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/12/20    1.0   K.Nakamura       main新規作成
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
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOS009A10C';            -- パッケージ名
  -- アプリケーション短縮名
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOS';                   -- アプリケーション
  cv_appl_short_name          CONSTANT VARCHAR2(5)  := 'XXCCP';                   -- アドオン：共通・IF領域
  -- プロファイル
  cv_interval                 CONSTANT VARCHAR2(30) := 'XXCOS1_INTERVAL_XXCOS009A10C'; -- XXCOS:待機間隔（受注一覧＆受注エラーリスト発行）
  cv_max_wait                 CONSTANT VARCHAR2(30) := 'XXCOS1_MAX_WAIT_XXCOS009A10C'; -- XXCOS:最大待機時間（受注一覧＆受注エラーリスト発行）
  -- コンカレント略称
  cv_xxcos009a012r            CONSTANT VARCHAR2(20) := 'XXCOS009A012R';           -- 受注一覧リスト（EDI用）（新規）
  cv_xxcos010a052r            CONSTANT VARCHAR2(20) := 'XXCOS010A052R';           -- 受注エラーリスト
  -- コンカレントdevステータス
  cv_dev_status_normal        CONSTANT VARCHAR2(10) := 'NORMAL';                  -- '正常'
  cv_dev_status_warn          CONSTANT VARCHAR2(10) := 'WARNING';                 -- '警告'
  -- メッセージ
  cv_msg_xxcos_00004          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00004';        -- プロファイル取得エラー
  cv_msg_xxcos_00005          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00005';        -- 日付逆転エラー
  cv_msg_xxcos_14551          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14551';        -- 受注一覧リスト
  cv_msg_xxcos_14552          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14552';        -- 受注エラーリスト（受注）
  cv_msg_xxcos_14553          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14553';        -- 受注エラーリスト（納品確定）
  cv_msg_xxcos_14554          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14554';        -- エラーリスト用EDI受信日(FROM)
  cv_msg_xxcos_14555          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14555';        -- エラーリスト用EDI受信日(TO)
  cv_msg_xxcos_14556          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14556';        -- パラメータ出力メッセージ
  cv_msg_xxcos_14557          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14557';        -- コンカレント起動エラーメッセージ
  cv_msg_xxcos_14558          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14558';        -- 待機時間経過メッセージ
  cv_msg_xxcos_14559          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14559';        -- コンカレント正常終了メッセージ
  cv_msg_xxcos_14560          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14560';        -- コンカレント警告終了メッセージ
  cv_msg_xxcos_14561          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14561';        -- コンカレントエラー終了メッセージ
  cv_msg_xxcos_14562          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14562';        -- エラー終了メッセージ
  -- トークンコード
  cv_tkn_param1               CONSTANT VARCHAR2(20) := 'PARAM1';                  -- パラメータ名１
  cv_tkn_param2               CONSTANT VARCHAR2(20) := 'PARAM2';                  -- パラメータ名２
  cv_tkn_param3               CONSTANT VARCHAR2(20) := 'PARAM3';                  -- パラメータ名３
  cv_tkn_param4               CONSTANT VARCHAR2(20) := 'PARAM4';                  -- パラメータ名４
  cv_tkn_param5               CONSTANT VARCHAR2(20) := 'PARAM5';                  -- パラメータ名５
  cv_tkn_param6               CONSTANT VARCHAR2(20) := 'PARAM6';                  -- パラメータ名６
  cv_tkn_param7               CONSTANT VARCHAR2(20) := 'PARAM7';                  -- パラメータ名７
  cv_tkn_date_from            CONSTANT VARCHAR2(20) := 'DATE_FROM';               -- パラメータFROM
  cv_tkn_date_to              CONSTANT VARCHAR2(20) := 'DATE_TO';                 -- パラメータTO
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROFILE';                 -- プロファイル名称
  cv_tkn_conc_name            CONSTANT VARCHAR2(20) := 'CONC_NAME';               -- コンカレント名称
  cv_tkn_request_id           CONSTANT VARCHAR2(20) := 'REQUEST_ID';              -- 要求ID
  -- エラーリスト種別
  cv_err_list_type_01         CONSTANT VARCHAR2(2)  := '01';                      -- 受注
  cv_err_list_type_02         CONSTANT VARCHAR2(2)  := '02';                      -- 納品確定
  -- 日付書式
  cv_yyyymmdd                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';              -- YYYY/MM/DD型
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_retcode                  VARCHAR2(1)  DEFAULT cv_status_normal; -- 親コンカレント用リターンコード
  gv_msg_xxcos_14551          VARCHAR2(30) DEFAULT NULL;             -- 受注一覧リスト
  gv_msg_xxcos_14552          VARCHAR2(30) DEFAULT NULL;             -- 受注エラーリスト（受注）
  gv_msg_xxcos_14553          VARCHAR2(30) DEFAULT NULL;             -- 受注エラーリスト（納品確定）
  gn_interval                 NUMBER       DEFAULT NULL;             -- コンカレント監視間隔
  gn_max_wait                 NUMBER       DEFAULT NULL;             -- コンカレント監視最大時間
  gn_request_id1              NUMBER       DEFAULT NULL;             -- 受注一覧リストの要求ID
  gn_request_id2              NUMBER       DEFAULT NULL;             -- 受注エラーリスト（受注）の要求ID
  gn_request_id3              NUMBER       DEFAULT NULL;             -- 受注エラーリスト（納品確定）の要求ID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_order_source             IN  VARCHAR2, -- 受注ソース
    iv_delivery_base_code       IN  VARCHAR2, -- 納品拠点コード
    iv_output_type              IN  VARCHAR2, -- 出力区分
    iv_output_quantity_type     IN  VARCHAR2, -- 出力数量区分
    iv_request_type             IN  VARCHAR2, -- 再発行区分
    iv_edi_received_date_from   IN  VARCHAR2, -- エラーリスト用EDI受信日(FROM)
    iv_edi_received_date_to     IN  VARCHAR2, -- エラーリスト用EDI受信日(TO)
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_param_msg                VARCHAR2(5000); -- パラメータ出力用
    lv_out_msg1                 VARCHAR2(40);   -- 出力用文字
    lv_out_msg2                 VARCHAR2(40);   -- 出力用文字
    ld_edi_received_date_from   DATE;           -- エラーリスト用EDI受信日(FROM)
    ld_edi_received_date_to     DATE;           -- エラーリスト用EDI受信日(TO)
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
                      , iv_name          => cv_msg_xxcos_14556          -- メッセージコード
                      , iv_token_name1   => cv_tkn_param1               -- トークンコード１
                      , iv_token_value1  => iv_order_source             -- 受注ソース
                      , iv_token_name2   => cv_tkn_param2               -- トークンコード２
                      , iv_token_value2  => iv_delivery_base_code       -- 納品拠点コード
                      , iv_token_name3   => cv_tkn_param3               -- トークンコード３
                      , iv_token_value3  => iv_output_type              -- 出力区分
                      , iv_token_name4   => cv_tkn_param4               -- トークンコード４
                      , iv_token_value4  => iv_output_quantity_type     -- 出力数量区分
                      , iv_token_name5   => cv_tkn_param5               -- トークンコード５
                      , iv_token_value5  => iv_request_type             -- 再発行区分
                      , iv_token_name6   => cv_tkn_param6               -- トークンコード６
                      , iv_token_value6  => iv_edi_received_date_from   -- エラーリスト用EDI受信日(FROM)
                      , iv_token_name7   => cv_tkn_param7               -- トークンコード７
                      , iv_token_value7  => iv_edi_received_date_to     -- エラーリスト用EDI受信日(TO)
                    );
    -- 出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    -- 出力空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    -- DATE型変換
    ld_edi_received_date_from := TO_DATE( iv_edi_received_date_from, cv_yyyymmdd );
    ld_edi_received_date_to   := TO_DATE( iv_edi_received_date_to, cv_yyyymmdd );
    -- 日付逆転チェック
    IF ( ld_edi_received_date_from > ld_edi_received_date_to ) THEN
      lv_out_msg1 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_14554 -- メッセージコード
                     );
      lv_out_msg2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_14555 -- メッセージコード
                     );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcos_00005 -- メッセージコード
                     , iv_token_name1  => cv_tkn_date_from   -- トークンコード１
                     , iv_token_value1 => lv_out_msg1        -- エラーリスト用EDI受信日(FROM)
                     , iv_token_name2  => cv_tkn_date_to     -- トークンコード２
                     , iv_token_value2 => lv_out_msg2        -- エラーリスト用EDI受信日(TO)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- プロファイルの取得
    --==================================
    BEGIN
      -- XXCOS:待機間隔（受注一覧＆受注エラーリスト発行）
      gn_interval := TO_NUMBER(FND_PROFILE.VALUE( cv_interval ));
      -- プロファイル値チェック
      IF ( gn_interval IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_00004  -- メッセージコード
                       , iv_token_name1  => cv_tkn_profile      -- トークンコード1
                       , iv_token_value1 => cv_interval         -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_00004  -- メッセージコード
                       , iv_token_name1  => cv_tkn_profile      -- トークンコード1
                       , iv_token_value1 => cv_interval         -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    BEGIN
      -- XXCOS:最大待機時間（受注一覧＆受注エラーリスト発行）
      gn_max_wait := TO_NUMBER(FND_PROFILE.VALUE( cv_max_wait ));
      -- プロファイル値チェック
      IF ( gn_max_wait IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_00004  -- メッセージコード
                       , iv_token_name1  => cv_tkn_profile      -- トークンコード1
                       , iv_token_value1 => cv_max_wait         -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_00004  -- メッセージコード
                       , iv_token_name1  => cv_tkn_profile      -- トークンコード1
                       , iv_token_value1 => cv_max_wait         -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- 固定文字
    gv_msg_xxcos_14551 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション短縮名
                            , iv_name         => cv_msg_xxcos_14551 -- メッセージコード
                          );
    gv_msg_xxcos_14552 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション短縮名
                            , iv_name         => cv_msg_xxcos_14552 -- メッセージコード
                          );
    gv_msg_xxcos_14553 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション短縮名
                            , iv_name         => cv_msg_xxcos_14553 -- メッセージコード
                          );
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
   * Procedure Name   : exe_xxcos009a01r
   * Description      : 受注一覧リスト発行処理(A-2)
   ***********************************************************************************/
  PROCEDURE exe_xxcos009a01r(
    iv_order_source             IN  VARCHAR2, -- 受注ソース
    iv_delivery_base_code       IN  VARCHAR2, -- 納品拠点コード
    iv_output_type              IN  VARCHAR2, -- 出力区分
    iv_output_quantity_type     IN  VARCHAR2, -- 出力数量区分
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_xxcos009a01r'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    --==============================================================
    -- コンカレント発行
    --==============================================================
    gn_request_id1 := fnd_request.submit_request(
                          application => cv_application              -- アプリケーション短縮名
                        , program     => cv_xxcos009a012r            -- コンカレントプログラム名
                        , description => NULL                        -- 摘要
                        , start_time  => NULL                        -- 開始時間
                        , sub_request => FALSE                       -- サブ要求
                        , argument1   => iv_order_source             -- 受注ソース
                        , argument2   => iv_delivery_base_code       -- 納品拠点コード
                        , argument3   => NULL                        -- 受注日(FROM)
                        , argument4   => NULL                        -- 受注日(TO)
                        , argument5   => NULL                        -- 出荷予定日(FROM)
                        , argument6   => NULL                        -- 出荷予定日(TO)
                        , argument7   => NULL                        -- 納品予定日(FROM)
                        , argument8   => NULL                        -- 納品予定日(TO)
                        , argument9   => NULL                        -- 入力者コード
                        , argument10  => NULL                        -- 出荷先コード
                        , argument11  => NULL                        -- 保管場所
                        , argument12  => NULL                        -- 受注番号
                        , argument13  => iv_output_type              -- 出力区分
                        , argument14  => NULL                        -- チェーン店コード
                        , argument15  => NULL                        -- 受信日(FROM)
                        , argument16  => NULL                        -- 受信日(TO)
                        , argument17  => NULL                        -- 納品日(FROM)
                        , argument18  => NULL                        -- 納品日(TO)
                        , argument19  => NULL                        -- ステータス
                        , argument20  => iv_output_quantity_type     -- 出力数量区分
                      );
    -- 正常以外の場合
    IF ( gn_request_id1 = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcos_14557 -- メッセージコード
                     , iv_token_name1  => cv_tkn_conc_name   -- トークンコード１
                     , iv_token_value1 => gv_msg_xxcos_14551 -- 受注一覧リスト
                   );
      lv_errbuf := lv_errmsg;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- 親コンカレント用リターンコード
      gv_retcode := cv_status_error;
    END IF;
--
    -- コミット発行
    COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END exe_xxcos009a01r;
--
  /**********************************************************************************
   * Procedure Name   : exe_xxcos010a05r_1
   * Description      : 受注エラーリスト（受注）発行処理(A-3)
   ***********************************************************************************/
  PROCEDURE exe_xxcos010a05r_1(
    iv_delivery_base_code       IN  VARCHAR2, -- 納品拠点コード
    iv_request_type             IN  VARCHAR2, -- 再発行区分
    iv_edi_received_date_from   IN  VARCHAR2, -- エラーリスト用EDI受信日(FROM)
    iv_edi_received_date_to     IN  VARCHAR2, -- エラーリスト用EDI受信日(TO)
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_xxcos010a05r_1'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    --==============================================================
    -- コンカレント発行
    --==============================================================
    gn_request_id2 := fnd_request.submit_request(
                          application => cv_application            -- アプリケーション短縮名
                        , program     => cv_xxcos010a052r          -- コンカレントプログラム名
                        , description => gv_msg_xxcos_14552        -- 摘要
                        , start_time  => NULL                      -- 開始時間
                        , sub_request => FALSE                     -- サブ要求
                        , argument1   => cv_err_list_type_01       -- エラーリスト種別
                        , argument2   => iv_request_type           -- 再発行区分
                        , argument3   => iv_delivery_base_code     -- 拠点コード
                        , argument4   => NULL                      -- チェーン店コード
                        , argument5   => iv_edi_received_date_from -- EDI受信日(FROM)
                        , argument6   => iv_edi_received_date_to   -- EDI受信日(TO)
                      );
    -- 正常以外の場合
    IF ( gn_request_id2 = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcos_14557 -- メッセージコード
                     , iv_token_name1  => cv_tkn_conc_name   -- トークンコード１
                     , iv_token_value1 => gv_msg_xxcos_14552 -- 受注エラーリスト（受注）
                   );
      lv_errbuf := lv_errmsg;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- 親コンカレント用リターンコード
      gv_retcode := cv_status_error;
    END IF;
--
    -- コミット発行
    COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END exe_xxcos010a05r_1;
--
  /**********************************************************************************
   * Procedure Name   : exe_xxcos010a05r_2
   * Description      : 受注エラーリスト（納品確定）発行処理(A-4)
   ***********************************************************************************/
  PROCEDURE exe_xxcos010a05r_2(
    iv_delivery_base_code       IN  VARCHAR2, -- 納品拠点コード
    iv_request_type             IN  VARCHAR2, -- 再発行区分
    iv_edi_received_date_from   IN  VARCHAR2, -- エラーリスト用EDI受信日(FROM)
    iv_edi_received_date_to     IN  VARCHAR2, -- エラーリスト用EDI受信日(TO)
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_xxcos010a05r_2'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    --==============================================================
    -- コンカレント発行
    --==============================================================
    gn_request_id3 := fnd_request.submit_request(
                          application => cv_application            -- アプリケーション短縮名
                        , program     => cv_xxcos010a052r          -- コンカレントプログラム名
                        , description => gv_msg_xxcos_14553        -- 摘要
                        , start_time  => NULL                      -- 開始時間
                        , sub_request => FALSE                     -- サブ要求
                        , argument1   => cv_err_list_type_02       -- エラーリスト種別
                        , argument2   => iv_request_type           -- 再発行区分
                        , argument3   => iv_delivery_base_code     -- 拠点コード
                        , argument4   => NULL                      -- チェーン店コード
                        , argument5   => iv_edi_received_date_from -- EDI受信日(FROM)
                        , argument6   => iv_edi_received_date_to   -- EDI受信日(TO)
                      );
    -- 正常以外の場合
    IF ( gn_request_id3 = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcos_14557 -- メッセージコード
                     , iv_token_name1  => cv_tkn_conc_name   -- トークンコード１
                     , iv_token_value1 => gv_msg_xxcos_14553 -- 受注エラーリスト（納品確定）
                   );
      lv_errbuf := lv_errmsg;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- 親コンカレント用リターンコード
      gv_retcode := cv_status_error;
    END IF;
--
    -- コミット発行
    COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END exe_xxcos010a05r_2;
--
  /**********************************************************************************
   * Procedure Name   : func_wait_for_request
   * Description      : コンカレント終了待機処理関数
   ***********************************************************************************/
  PROCEDURE func_wait_for_request(
    iv_msg_code                 IN  VARCHAR2, -- コンカレント名
    in_request_id               IN  NUMBER,   -- 要求ID
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_wait_for_request'; -- プログラム名
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
    -- *** ローカル変数 ***
    lb_wait_request           BOOLEAN        DEFAULT TRUE;
    lv_phase                  VARCHAR2(50)   DEFAULT NULL;
    lv_status                 VARCHAR2(50)   DEFAULT NULL;
    lv_dev_phase              VARCHAR2(50)   DEFAULT NULL;
    lv_dev_status             VARCHAR2(50)   DEFAULT NULL;
    lv_message                VARCHAR2(5000) DEFAULT NULL;
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
    -- コンカレント要求待機
    --==============================================================
    lb_wait_request := fnd_concurrent.wait_for_request(
                           request_id => in_request_id -- 要求ID
                         , interval   => gn_interval   -- コンカレント監視間隔
                         , max_wait   => gn_max_wait   -- コンカレント監視最大時間
                         , phase      => lv_phase      -- 要求フェーズ
                         , status     => lv_status     -- 要求ステータス
                         , dev_phase  => lv_dev_phase  -- 要求フェーズコード
                         , dev_status => lv_dev_status -- 要求ステータスコード
                         , message    => lv_message    -- 完了メッセージ
                       );
    -- 戻り値がFALSEの場合
    IF ( lb_wait_request = FALSE ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_xxcos_14558
                     , iv_token_name1  => cv_tkn_conc_name
                     , iv_token_value1 => iv_msg_code
                     , iv_token_name2  => cv_tkn_request_id
                     , iv_token_value2 => TO_CHAR(in_request_id)
                   );
      lv_errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- 親コンカレント用リターンコード
      gv_retcode := cv_status_error;
    ELSE
      -- 正常終了メッセージ出力
      IF ( lv_dev_status = cv_dev_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_14559
                       , iv_token_name1  => cv_tkn_conc_name
                       , iv_token_value1 => iv_msg_code
                       , iv_token_name2  => cv_tkn_request_id
                       , iv_token_value2 => TO_CHAR(in_request_id)
                     );
      -- 警告終了メッセージ出力
      ELSIF ( lv_dev_status = cv_dev_status_warn ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_14560
                       , iv_token_name1  => cv_tkn_conc_name
                       , iv_token_value1 => iv_msg_code
                       , iv_token_name2  => cv_tkn_request_id
                       , iv_token_value2 => TO_CHAR(in_request_id)
                     );
        -- 親コンカレント用リターンコード（既にエラーの場合はそのまま）
        IF ( gv_retcode = cv_status_normal ) THEN
          gv_retcode := cv_status_warn;
        END IF;
      -- エラー終了メッセージ出力
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_14561
                       , iv_token_name1  => cv_tkn_conc_name
                       , iv_token_value1 => iv_msg_code
                       , iv_token_name2  => cv_tkn_request_id
                       , iv_token_value2 => TO_CHAR(in_request_id)
                     );
        lv_errbuf := lv_errmsg;
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
        );
        --１行改行
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
        -- 親コンカレント用リターンコード
        gv_retcode := cv_status_error;
      END IF;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END func_wait_for_request;
--
  /**********************************************************************************
   * Procedure Name   : wait_for_request
   * Description      : コンカレント終了待機処理(A-5)
   ***********************************************************************************/
  PROCEDURE wait_for_request(
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wait_for_request'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    --==============================================================
    -- コンカレント要求待機（受注一覧リスト）
    --==============================================================
    -- コンカレント発行がエラーでは無い場合
    IF ( gn_request_id1 <> 0 ) THEN
      func_wait_for_request(
          gv_msg_xxcos_14551 -- コンカレント名
        , gn_request_id1     -- 要求ID
        , lv_errbuf          -- エラー・メッセージ           --# 固定 #
        , lv_retcode         -- リターン・コード             --# 固定 #
        , lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    END IF;
--
    --==============================================================
    -- コンカレント要求待機（受注エラーリスト（受注））
    --==============================================================
    -- コンカレント発行がエラーでは無い場合
    IF ( gn_request_id2 <> 0 ) THEN
      func_wait_for_request(
          gv_msg_xxcos_14552 -- コンカレント名
        , gn_request_id2     -- 要求ID
        , lv_errbuf          -- エラー・メッセージ           --# 固定 #
        , lv_retcode         -- リターン・コード             --# 固定 #
        , lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    END IF;
--
    --==============================================================
    -- コンカレント要求待機（受注エラーリスト（納品確定））
    --==============================================================
    -- コンカレント発行がエラーでは無い場合
    IF ( gn_request_id3 <> 0 ) THEN
      func_wait_for_request(
          gv_msg_xxcos_14553 -- コンカレント名
        , gn_request_id3     -- 要求ID
        , lv_errbuf          -- エラー・メッセージ           --# 固定 #
        , lv_retcode         -- リターン・コード             --# 固定 #
        , lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END wait_for_request;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_order_source             IN  VARCHAR2, -- 受注ソース
    iv_delivery_base_code       IN  VARCHAR2, -- 納品拠点コード
    iv_output_type              IN  VARCHAR2, -- 出力区分
    iv_output_quantity_type     IN  VARCHAR2, -- 出力数量区分
    iv_request_type             IN  VARCHAR2, -- 再発行区分
    iv_edi_received_date_from   IN  VARCHAR2, -- エラーリスト用EDI受信日(FROM)
    iv_edi_received_date_to     IN  VARCHAR2, -- エラーリスト用EDI受信日(TO)
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
        iv_order_source             -- 受注ソース
      , iv_delivery_base_code       -- 納品拠点コード
      , iv_output_type              -- 出力区分
      , iv_output_quantity_type     -- 出力数量区分
      , iv_request_type             -- 再発行区分
      , iv_edi_received_date_from   -- エラーリスト用EDI受信日(FROM)
      , iv_edi_received_date_to     -- エラーリスト用EDI受信日(TO)
      , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 受注一覧リスト発行処理(A-2)
    -- ===============================
    exe_xxcos009a01r(
        iv_order_source             -- 受注ソース
      , iv_delivery_base_code       -- 納品拠点コード
      , iv_output_type              -- 出力区分
      , iv_output_quantity_type     -- 出力数量区分
      , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- 受注エラーリスト（受注）発行処理(A-3)
    -- ===============================
    exe_xxcos010a05r_1(
        iv_delivery_base_code       -- 納品拠点コード
      , iv_request_type             -- 再発行区分
      , iv_edi_received_date_from   -- エラーリスト用EDI受信日(FROM)
      , iv_edi_received_date_to     -- エラーリスト用EDI受信日(TO)
      , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- 受注エラーリスト（納品確定）発行処理(A-4)
    -- ===============================
    exe_xxcos010a05r_2(
        iv_delivery_base_code       -- 納品拠点コード
      , iv_request_type             -- 再発行区分
      , iv_edi_received_date_from   -- エラーリスト用EDI受信日(FROM)
      , iv_edi_received_date_to     -- エラーリスト用EDI受信日(TO)
      , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- コンカレント終了待機処理(A-5)
    -- ===============================
    wait_for_request(
        lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
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
    errbuf                      OUT VARCHAR2, -- エラーメッセージ #固定#
    retcode                     OUT VARCHAR2, -- エラーコード     #固定#
    iv_order_source             IN  VARCHAR2, -- 受注ソース
    iv_delivery_base_code       IN  VARCHAR2, -- 納品拠点コード
    iv_output_type              IN  VARCHAR2, -- 出力区分
    iv_output_quantity_type     IN  VARCHAR2, -- 出力数量区分
    iv_request_type             IN  VARCHAR2, -- 再発行区分
    iv_edi_received_date_from   IN  VARCHAR2, -- エラーリスト用EDI受信日(FROM)
    iv_edi_received_date_to     IN  VARCHAR2  -- エラーリスト用EDI受信日(TO)
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
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
        iv_order_source             -- 受注ソース
      , iv_delivery_base_code       -- 納品拠点コード
      , iv_output_type              -- 出力区分
      , iv_output_quantity_type     -- 出力数量区分
      , iv_request_type             -- 再発行区分
      , iv_edi_received_date_from   -- エラーリスト用EDI受信日(FROM)
      , iv_edi_received_date_to     -- エラーリスト用EDI受信日(TO)
      , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      -- 出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- 出力空行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- ログ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- ログ空行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      --  終了ステータス
      gv_retcode := lv_retcode;
      --
    END IF;
--
    -- 終了メッセージ
    IF ( gv_retcode = cv_status_normal ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF( gv_retcode = cv_status_warn ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF( gv_retcode = cv_status_error ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_xxcos_14562
                     );
    END IF;
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := gv_retcode;
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
END XXCOS009A10C;
/
