CREATE OR REPLACE PACKAGE BODY XXCOP004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A01C(body)
 * Description      : アップロードファイルからの登録(リーフ便）
 * MD.050           : アップロードファイルからの登録(リーフ便） MD050_COP_004_A01
 * Version          : 1.1
 *
 * Program List
 * ----------------------   ----------------------------------------------------------
 *  Name                     Description
 * ----------------------   ----------------------------------------------------------
 *  chk_parameter_p          パラメータ妥当性チェック(A-2)
 *  get_format_pattern_p     クイックコード取得(リーフ便CSVファイルのフォーマット)(A-3)
 *  get_file_ul_interface_p  ファイルアップロードI/Fテーブルデータ抽出(A-4)
 *  chk_validate_data_f      データ妥当性チェック(A-5)
 *  chk_exist_forecast_p     引取計画データ登録チェック(A-6)
 *  reg_leaf_data_p          リーフ便データ登録・削除(A-7)
 *  judge_result_p           処理内容判定(A-8)
 *  output_report_p          アップロード内容の出力(A-11)
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/05    1.0  SCS.Tsubomatsu   新規作成
 *  2009/04/28    1.1  SCS.Kikuchi      T1_0645対応
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
  expt_XXCOP004A01          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP004A01C';           -- パッケージ名
  cv_date_format1           CONSTANT VARCHAR2(8)   := 'YYYYMMDD';               -- 日付フォーマット
  cv_date_format2           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- 日付フォーマット
  cv_date_format3           CONSTANT VARCHAR2(6)   := 'YYYYMM';                 -- 日付フォーマット
  cv_sep                    CONSTANT VARCHAR2(1)   := ',';                      -- CSV区切り文字(カンマ)
  cv_customer_class_code    CONSTANT VARCHAR2(1)   := '1';                      -- 顧客マスタ.顧客区分(1:拠点)
  cn_bucket_type            CONSTANT NUMBER        := 1;                        -- 需要APIバケットタイプ(1:Days)
  cv_mfds_attribute1        CONSTANT VARCHAR2(2)   := '01';                     -- フォーキャスト名.FORECAST分類
  cv_first_day              CONSTANT VARCHAR2(2)   := '01';                     -- 月初日
  cv_prod_class_code        CONSTANT VARCHAR2(1)   := '1';                      -- 商品区分(1:リーフ)
  -- パラメータ
  cv_param_file_id          CONSTANT VARCHAR2(40)  := 'ファイルID';             -- ファイルID
  cv_param_format_pattern   CONSTANT VARCHAR2(40)  := 'フォーマットパターン';   -- フォーマットパターン
  -- プロファイル
  cv_master_org_id          CONSTANT VARCHAR2(19)  := 'XXCMN_MASTER_ORG_ID';    -- マスタ組織ID
  cv_master_org_id_name     CONSTANT VARCHAR2(100) := 'XXCMN:マスタ組織';       -- マスタ組織ID
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_START
  cv_sales_org_code         CONSTANT VARCHAR2(30)  := 'XXCOP1_SALES_ORG_CODE';  -- 営業組織
  cv_sales_org_code_name    CONSTANT VARCHAR2(100) := 'XXCOP:営業組織';         -- 営業組織ID
  cv_item_org_code          CONSTANT VARCHAR2(100) := '組織コード';
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_END
  -- クイックコード
  cv_lookup_type            CONSTANT VARCHAR2(21)  := 'XXCOP1_FORMAT_PATTERN';  -- クイックコードタイプ
  cv_flv_enabled_flag       CONSTANT VARCHAR2(1)   := 'Y';                      -- 使用可能
  -- 処理結果
  cv_result_insert          CONSTANT VARCHAR2(100) := '(登録)';
  cv_result_update          CONSTANT VARCHAR2(100) := '(更新)';
  cv_result_delete          CONSTANT VARCHAR2(100) := '(削除)';
  -- 処理結果レポート見出し
  cv_title_upload_ok        CONSTANT VARCHAR2(40)  := '取込完了データ';
  cv_title_upload_ng        CONSTANT VARCHAR2(40)  := '取込失敗データ';
  -- メッセージ・アプリケーション名（アドオン：販物・計画領域）
  cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP';
  -- メッセージ名
  cv_message_00002          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00002';
  cv_message_00005          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00005';
  cv_message_00006          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00006';
  cv_message_00007          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00007';
  cv_message_00008          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00008';
  cv_message_00009          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00009';
  cv_message_00010          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00010';
  cv_message_00011          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00011';
  cv_message_00012          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00012';
  cv_message_00013          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00013';
  cv_message_00031          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00031';
  cv_message_00036          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00036';
  cv_message_00046          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00046';
  cv_message_10002          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10002';
  cv_message_10003          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10003';
  cv_message_10004          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10004';
  cv_message_10036          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10036';
  -- メッセージトークン
  cv_message_00002_token_1  CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_message_00005_token_1  CONSTANT VARCHAR2(9)   := 'PARAMETER';
  cv_message_00005_token_2  CONSTANT VARCHAR2(5)   := 'VALUE';
  cv_message_00006_token_1  CONSTANT VARCHAR2(5)   := 'VALUE';
  cv_message_00007_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00009_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00010_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00011_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00012_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00013_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_00013_token_2  CONSTANT VARCHAR2(5)   := 'VALUE';
  cv_message_00013_token_3  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00036_token_1  CONSTANT VARCHAR2(7)   := 'FILE_ID';
  cv_message_00036_token_2  CONSTANT VARCHAR2(10)  := 'FORMAT_PTN';
  cv_message_00036_token_3  CONSTANT VARCHAR2(13)  := 'UPLOAD_OBJECT';
  cv_message_00036_token_4  CONSTANT VARCHAR2(9)   := 'FILE_NAME';
  cv_message_00046_token_1  CONSTANT VARCHAR2(4)   := 'ITEM';
  cv_message_10002_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_10002_token_2  CONSTANT VARCHAR2(5)   := 'STORE';
  cv_message_10002_token_3  CONSTANT VARCHAR2(8)   := 'LOCATION';
  cv_message_10002_token_4  CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_message_10003_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_10003_token_2  CONSTANT VARCHAR2(5)   := 'STORE';
  cv_message_10003_token_3  CONSTANT VARCHAR2(8)   := 'LOCATION';
  cv_message_10003_token_4  CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_message_10003_token_5  CONSTANT VARCHAR2(4)   := 'DATE';
  cv_message_10004_token_1  CONSTANT VARCHAR2(4)   := 'DATE';
  cv_message_10031_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_10031_token_2  CONSTANT VARCHAR2(7)   := 'FILE_ID';
  -- テーブル名
  cv_table_xldos            CONSTANT VARCHAR2(100) := 'リーフ便データアドオンテーブル';
  cv_table_hca              CONSTANT VARCHAR2(100) := '顧客マスタ';
  cv_table_mil              CONSTANT VARCHAR2(100) := 'OPM保管場所マスタ';
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_START
  cv_table_mp               CONSTANT VARCHAR2(100) := '組織パラメータ';
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_END

  -- 桁数
  cn_len_code               CONSTANT NUMBER        := 4;    -- 拠点、出荷倉庫
  cn_len_target_month       CONSTANT NUMBER        := 6;    -- 対象年月
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_param_file_id          VARCHAR2(30);   --   パラメータ.FILE_ID
  gv_param_format_pattern   VARCHAR2(30);   --   パラメータ.フォーマット・パターン
  gn_param_file_id          NUMBER;         --   パラメータ.FILE_ID
  gn_param_format_pattern   NUMBER;         --   パラメータ.フォーマット・パターン
  gn_org_id                 NUMBER;         --   組織ID
  gv_upload_name            fnd_lookup_values.meaning%TYPE;                         -- ファイルアップロード名称
  gv_file_name              xxccp_mrp_file_ul_interface.file_name%TYPE;             -- ファイル名
  gd_upload_date            xxccp_mrp_file_ul_interface.creation_date%TYPE;         -- アップロード日時

--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_START
  gv_sales_org_code         mtl_parameters.organization_code%type;
  gn_sales_org_id           mtl_parameters.organization_id%type;
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_END
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  TYPE g_day_of_service_ttype IS TABLE OF VARCHAR2(2)     INDEX BY BINARY_INTEGER;    -- ドリンク便日付(最大20件)
--  TYPE g_warning_msg_ttype    IS TABLE OF VARCHAR2(4096)  INDEX BY BINARY_INTEGER;    -- 警告メッセージ
  TYPE g_error_msg_ttype      IS TABLE OF VARCHAR2(4096)  INDEX BY BINARY_INTEGER;    -- エラーメッセージ(複数行の場合あり)
  TYPE g_result_ttype         IS TABLE OF VARCHAR2(10)    INDEX BY BINARY_INTEGER;    -- 処理結果( (登録),(更新),(削除) の何れか)
--
  -- ===============================
  -- ユーザー定義グローバルRECORD型
  -- ===============================
  TYPE g_ifdata_rtype IS RECORD (
    whse_code             VARCHAR2(4)             -- 出荷倉庫
   ,base_code             VARCHAR2(4)             -- 拠点
   ,target_month          VARCHAR2(6)             -- 対象年月
   ,day_of_service_tab    g_day_of_service_ttype  -- ドリンク便日付
  );
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter_p
   * Description      : A-2.パラメータ妥当性チェック
   ***********************************************************************************/
  PROCEDURE chk_parameter_p(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter_p'; -- プログラム名
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
    lv_tkn_parameter  VARCHAR2(100);  -- メッセージに渡すTOKEN(＆PARAMETER)
    lv_tkn_item       VARCHAR2(100);  -- メッセージに渡すTOKEN(＆ITEM)
    ln_dummy          NUMBER;         -- NUMBER型変換用ダミー
--
    -- *** ローカル・ユーザ定義例外 ***
    chk_parameter_expt EXCEPTION;
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
    --==============================================================
    --パラメータ.FILE_IDのNUMBER型チェック
    --==============================================================
    BEGIN
      lv_tkn_parameter  := cv_param_file_id;
      lv_tkn_item       := gv_param_file_id;
      -- NULLの場合は例外処理を行う
      IF ( gv_param_file_id IS NULL ) THEN
        RAISE chk_parameter_expt;
      END IF;
      -- NUMBER型に変換して格納
      gn_param_file_id := TO_NUMBER( gv_param_file_id );
    EXCEPTION
      WHEN OTHERS THEN
        -- NUMBER型変換エラーの場合は例外処理を行う
        RAISE chk_parameter_expt;
    END;
--
    --==============================================================
    --パラメータ.フォーマットパターンのNUMBER型チェック
    --==============================================================
    BEGIN
      lv_tkn_parameter  := cv_param_format_pattern;
      lv_tkn_item       := gv_param_format_pattern;
      -- NULLの場合は例外処理を行う
      IF ( gv_param_format_pattern IS NULL ) THEN
        RAISE chk_parameter_expt;
      END IF;
      -- NUMBER型に変換して格納
      gn_param_format_pattern := TO_NUMBER( gv_param_format_pattern );
    EXCEPTION
      WHEN OTHERS THEN
        -- NUMBER型変換エラーの場合は例外処理を行う
        RAISE chk_parameter_expt;
    END;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** パラメータチェックエラー ***
    WHEN chk_parameter_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00005
                      ,iv_token_name1  => cv_message_00005_token_1
                      ,iv_token_value1 => lv_tkn_parameter
                      ,iv_token_name2  => cv_message_00005_token_2
                      ,iv_token_value2 => lv_tkn_item
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END chk_parameter_p;
--
  /**********************************************************************************
   * Procedure Name   : get_format_pattern_p
   * Description      : A-3.クイックコード取得(リーフ便CSVファイルのフォーマット)
   ***********************************************************************************/
  PROCEDURE get_format_pattern_p(
    iv_file_format OUT VARCHAR2    --   フォーマット・パターン
   ,ov_errbuf      OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2    --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_format_pattern_p'; -- プログラム名
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
    lv_description  fnd_lookup_values.description%TYPE;
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
    --==============================================================
    --クイックコードの取得
    --==============================================================
    SELECT flv.description description
    INTO   iv_file_format
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type
    AND    flv.lookup_code  = gv_param_format_pattern
    AND    flv.language     = USERENV( 'LANG' )
    AND    flv.enabled_flag = cv_flv_enabled_flag
    AND    NVL( flv.start_date_active, SYSDATE ) <= TRUNC( SYSDATE )
    AND    NVL( flv.end_date_active, SYSDATE ) >= TRUNC( SYSDATE )
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN  --*** 該当データなし ***
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00006
                      ,iv_token_name1  => cv_message_00006_token_1
                      ,iv_token_value1 => cv_lookup_type
                     );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END get_format_pattern_p;
--
  /**********************************************************************************
   * Procedure Name   : get_file_ul_interface_p
   * Description      : A-4.ファイルアップロードI/Fテーブルデータ抽出
   ***********************************************************************************/
  PROCEDURE get_file_ul_interface_p(
    o_ifdata_tab   OUT xxccp_common_pkg2.g_file_data_tbl   --   PL/SQL表：I/Fテーブルデータ
   ,ov_errbuf      OUT VARCHAR2                            --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2                            --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2)                           --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_file_ul_interface_p'; -- プログラム名
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
    --==============================================================
    --ファイルアップロードI/Fテーブルの情報取得
    --==============================================================
    xxcop_common_pkg.get_upload_table_info(
       in_file_id      => gn_param_file_id          -- ファイルID
      ,iv_format       => gn_param_format_pattern   -- フォーマットパターン
      ,ov_upload_name  => gv_upload_name            -- ファイルアップロード名称
      ,ov_file_name    => gv_file_name              -- ファイル名
      ,od_upload_date  => gd_upload_date            -- アップロード日時
      ,ov_retcode      => lv_retcode                -- リターンコード
      ,ov_errbuf       => lv_errbuf                 -- エラー・メッセージ
      ,ov_errmsg       => lv_errmsg                 -- ユーザー・エラー・メッセージ
    );
--
    --==============================================================
    --共通関数を使用し、ファイルアップロードI/Fテーブルのデータを行単位で取得する
    --==============================================================
    xxccp_common_pkg2.blob_to_varchar2(
      gn_param_file_id            -- ファイルＩＤ
     ,o_ifdata_tab                -- 変換後VARCHAR2データ
     ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                  -- リターン・コード             --# 固定 #
     ,lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --取得したデータの1行目はタイトル行のため破棄する
    --==============================================================
    IF ( o_ifdata_tab.COUNT > 0 ) THEN
      o_ifdata_tab.DELETE( o_ifdata_tab.FIRST );
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
  END get_file_ul_interface_p;
--
  /**********************************************************************************
   * Procedure Name   : chk_validate_data_f
   * Description      : A-5.データ妥当性チェック
   ***********************************************************************************/
  PROCEDURE chk_validate_data_f(
    iv_file_format      IN  VARCHAR2                              --   ファイルフォーマット
   ,i_ifdata_tab        IN  xxccp_common_pkg2.g_file_data_tbl     --   PL/SQL表：I/Fテーブルデータ
   ,in_ifdata_tab_idx   IN  NUMBER                                --   PL/SQL表：I/Fテーブルデータのインデックス番号
   ,o_csv_div_data_tab  OUT xxcop_common_pkg.g_char_ttype         --   PL/SQL表：CSV要素
   ,o_ifdata_rec        OUT g_ifdata_rtype                        --   レコード：ファイルアップロードI/Fテーブル要素
   ,io_error_msg_tab    IN  OUT    g_error_msg_ttype              --   PL/SQL表：エラーメッセージ
   ,ov_errbuf           OUT VARCHAR2                              --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2                              --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)                             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_validate_data_f'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_dummy            NUMBER;               -- 件数、NUMBER型確認用
    ld_dummy            DATE;                 -- DATE型確認用
    ln_index            NUMBER := 0;          -- CSVインデックス
    lv_tkn_item         VARCHAR2(100);        -- メッセージに渡すTOKEN(＆ITEM)
    lv_tkn_value        VARCHAR2(100);        -- メッセージに渡すTOKEN(＆VALUE)
    lb_blank_day        BOOLEAN := FALSE;     -- 1-20便日付のNull検出フラグ
    lv_date             VARCHAR2(8);          -- DATE型チェック用
    ld_work_day         DATE;                 -- 稼働日チェック用
--
    -- *** ローカルTABLE型 ***
    TYPE l_csv_item_name_ttype    IS TABLE OF VARCHAR2(20) INDEX BY BINARY_INTEGER;   -- CSV要素ごとの名称
--
    -- *** ローカルPL/SQL表 ***
    l_csv_item_name_tab   l_csv_item_name_ttype;          -- CSV要素ごとの名称
    l_file_format_tab     xxcop_common_pkg.g_char_ttype;  -- ファイルフォーマット
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
    --==============================================================
    --CSV要素ごとの名称設定
    --==============================================================
    l_csv_item_name_tab( 1 ) := '出荷倉庫';
    l_csv_item_name_tab( 2 ) := '拠点';
    l_csv_item_name_tab( 3 ) := '対象年月';
--
    <<csv_item_name_loop>>
    FOR i IN 1..20 LOOP
      l_csv_item_name_tab( i + 3 ) := i || '便日付';
    END LOOP csv_item_name_loop;
--
    --==============================================================
    --データのカンマ区切り
    --==============================================================
    xxcop_common_pkg.char_delim_partition(
      iv_char       => i_ifdata_tab( in_ifdata_tab_idx )   -- 対象文字列
     ,iv_delim      => cv_sep                              -- デリミタ
     ,o_char_tab    => o_csv_div_data_tab                  -- 分割結果
     ,ov_retcode    => lv_retcode                          -- リターンコード
     ,ov_errbuf     => lv_errbuf                           -- エラー・メッセージ
     ,ov_errmsg     => lv_errmsg                           -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 各要素のトリムを行う
    <<trim_loop>>
    FOR i IN o_csv_div_data_tab.FIRST..o_csv_div_data_tab.LAST LOOP
      o_csv_div_data_tab( i ) := LTRIM( RTRIM( o_csv_div_data_tab( i ) ) );
    END LOOP trim_loop;
--
    --==============================================================
    --ファイルフォーマット整合性チェック
    --==============================================================
    -- ファイルフォーマットのカンマ区切りを行う
    xxcop_common_pkg.char_delim_partition(
      iv_char       => iv_file_format                      -- 対象文字列
     ,iv_delim      => cv_sep                              -- デリミタ
     ,o_char_tab    => l_file_format_tab                   -- 分割結果
     ,ov_retcode    => lv_retcode                          -- リターンコード
     ,ov_errbuf     => lv_errbuf                           -- エラー・メッセージ
     ,ov_errmsg     => lv_errmsg                           -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ファイルフォーマットの要素数と「PL/SQL表：CSV要素」の要素数が異なる場合はエラーとする
    IF ( l_file_format_tab.COUNT <> o_csv_div_data_tab.COUNT ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00008
                     );
      IF ( ov_retcode = cv_status_normal ) THEN
        io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
      ELSE
        io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
      END IF;
      ov_retcode := cv_status_warn;
      -- 後続のチェックは行わない
      RETURN;
    END IF;
--
    --==============================================================
    --必須項目チェック
    --==============================================================
    <<check_not_null_loop>>
    -- PL/SQL表：CSV要素の出庫倉庫、拠点、対象年月(1-3番目)について必須チェックを行う
    FOR i IN 1..3 LOOP
      -- 要素が空白の場合はエラーとする
      IF ( o_csv_div_data_tab( i ) IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00009
                        ,iv_token_name1  => cv_message_00009_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( i )
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END LOOP check_not_null_loop;
--
    --==============================================================
    --1-20便入力チェック
    --==============================================================
    <<check_input_day_loop>>
    -- PL/SQL表：CSV要素の出庫倉庫、拠点、対象年月(1-3番目)について必須チェックを行う
    FOR i IN 4..23 LOOP
      -- 要素がNullの場合はNull検出フラグをセット
      IF ( o_csv_div_data_tab( i ) IS NULL ) THEN
        lb_blank_day := TRUE;
--
      -- 要素がNullでない場合
      ELSE
        IF lb_blank_day THEN
          -- 既にNullが見つかっている場合はエラー（中間の省略は不可）
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_application
                          ,iv_name         => cv_message_10036
                         );
          IF ( ov_retcode = cv_status_normal ) THEN
            io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
          ELSE
            io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
          END IF;
          ov_retcode := cv_status_warn;
          -- ループを抜ける
          EXIT check_input_day_loop;
        END IF;
      END IF;
    END LOOP check_input_day_loop;
--
    --==============================================================
    --顧客マスタ存在チェック
    --==============================================================
    -- 拠点が空白でない場合のみチェック対象とする
    IF ( o_csv_div_data_tab( 2 ) IS NOT NULL ) THEN
      SELECT COUNT( 'X' )
      INTO   ln_dummy
      FROM   hz_cust_accounts hca   -- 顧客マスタ
      WHERE  hca.customer_class_code = cv_customer_class_code
      AND    hca.account_number      = o_csv_div_data_tab( 2 )
      ;
      -- 拠点が顧客マスタに存在しない場合はエラーとする
      IF ( ln_dummy = 0 ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00013
                        ,iv_token_name1  => cv_message_00013_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( 2 )
                        ,iv_token_name2  => cv_message_00013_token_2
                        ,iv_token_value2 => o_csv_div_data_tab( 2 )
                        ,iv_token_name3  => cv_message_00013_token_3
                        ,iv_token_value3 => cv_table_hca
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --==============================================================
    --OPM保管場所マスタ存在チェック
    --==============================================================
    -- 出荷倉庫が空白でない場合のみチェック対象とする
    IF ( o_csv_div_data_tab( 1 ) IS NOT NULL ) THEN
      SELECT COUNT( 'X' )
      INTO   ln_dummy
      FROM   ic_whse_mst               iwm      -- OPM倉庫マスタ
            ,hr_all_organization_units haou     -- 在庫組織マスタ
            ,mtl_item_locations        mil      -- OPM保管場所マスタ
      WHERE  iwm.mtl_organization_id =   haou.organization_id
      AND    haou.organization_id    =   mil.organization_id
      AND    haou.date_from          <=  TRUNC(SYSDATE)
      AND   ( ( haou.date_to IS NULL ) OR ( haou.date_to >= TRUNC( SYSDATE ) ) )
      AND    mil.disable_date        IS NULL
      AND    mil.segment1            =   o_csv_div_data_tab( 1 )
      ;
      -- 出荷倉庫がOPM保管場所マスタに存在しない場合はエラーとする
      IF ( ln_dummy = 0 ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00013
                        ,iv_token_name1  => cv_message_00013_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( 1 )
                        ,iv_token_name2  => cv_message_00013_token_2
                        ,iv_token_value2 => o_csv_div_data_tab( 1 )
                        ,iv_token_name3  => cv_message_00013_token_3
                        ,iv_token_value3 => cv_table_mil
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --==============================================================
    --NUMBER型チェック
    --==============================================================
    <<check_numeric_loop>>
    -- PL/SQL表：CSV要素の対象年月、1-20便日付(3-23番目)について必須チェックを行う
    FOR i IN 3..23 LOOP
      -- 要素が空白でない場合のみチェック対象とする
      IF ( o_csv_div_data_tab( i ) IS NOT NULL ) THEN
        -- NUMBER型に変換できない場合はエラーとする
        IF ( xxcop_common_pkg.chk_number_format( o_csv_div_data_tab( i ) ) = FALSE ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_application
                          ,iv_name         => cv_message_00010
                          ,iv_token_name1  => cv_message_00010_token_1
                          ,iv_token_value1 => l_csv_item_name_tab( i )
                         );
          IF ( ov_retcode = cv_status_normal ) THEN
            io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
          ELSE
            io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
          END IF;
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
    END LOOP check_numeric_loop;
--
    --==============================================================
    --DATE型チェック・稼働日チェック
    --==============================================================
    -- PL/SQL表：CSV要素の対象年月について値チェックを行う（対象年月が空白でなく、NUMBER型の場合のみ）
    IF  ( o_csv_div_data_tab( 3 ) IS NOT NULL )
    AND ( xxcop_common_pkg.chk_number_format( o_csv_div_data_tab( 3 ) ) )
    THEN
      -- 6桁以外の場合、DATE型に変換できない場合はエラーとする
      IF ( LENGTHB( o_csv_div_data_tab( 3 ) ) <> cn_len_target_month )
      OR ( xxcop_common_pkg.chk_date_format( o_csv_div_data_tab( 3 ), cv_date_format3 ) = FALSE )
      THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00011
                        ,iv_token_name1  => cv_message_00011_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( 3 )
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    -- 対象年月が空白でなくNUMBER型かつDATE型の場合のみ
    IF  ( o_csv_div_data_tab( 3 ) IS NOT NULL )
    AND ( xxcop_common_pkg.chk_number_format( o_csv_div_data_tab( 3 ) ) )
    AND ( xxcop_common_pkg.chk_date_format( o_csv_div_data_tab( 3 ), cv_date_format3 ) )
    THEN
--
      <<check_isdate_loop>>
      -- PL/SQL表：CSV要素の対象年月と1-20便日付(4-23番目)について値チェックを行う
      FOR i IN 4..23 LOOP
        -- 要素が空白でなくNUMBER型の場合のみチェック対象とする
        IF  ( o_csv_div_data_tab( i ) IS NOT NULL )
        AND ( xxcop_common_pkg.chk_number_format( o_csv_div_data_tab( i ) ) )
        THEN
          -- 対象年月＋ｎ便日付を文字列として保存
          lv_date := o_csv_div_data_tab( 3 ) || LPAD( o_csv_div_data_tab( i ), 2, '0' );
          -- DATE型に変換できない場合はエラーとする
          IF ( xxcop_common_pkg.chk_date_format( lv_date, cv_date_format1 ) = FALSE ) THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_application
                            ,iv_name         => cv_message_00011
                            ,iv_token_name1  => cv_message_00011_token_1
                            ,iv_token_value1 => l_csv_item_name_tab( i )
                           );
            IF ( ov_retcode = cv_status_normal ) THEN
              io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
            ELSE
              io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
            END IF;
            ov_retcode := cv_status_warn;
--
          -- DATE型に変換できた場合
          ELSE
            -- 対象年月＋ｎ便日付を文字列として保存
            ld_work_day := TO_DATE( o_csv_div_data_tab( 3 ) || LPAD( o_csv_div_data_tab( i ), 2, '0' ), cv_date_format1 );
            -- 稼働日でない場合はエラーとする
            IF ( ld_work_day <> mrp_calendar.next_work_day(
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_MOD_START
--                                  arg_org_id  => gn_org_id
                                  arg_org_id  => gn_sales_org_id
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_MOD_END
                                 ,arg_bucket  => cn_bucket_type
                                 ,arg_date    => ld_work_day ) )
            THEN
              lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_application
                              ,iv_name         => cv_message_00046
                              ,iv_token_name1  => cv_message_00046_token_1
                              ,iv_token_value1 => l_csv_item_name_tab( i )
                             );
              IF ( ov_retcode = cv_status_normal ) THEN
                io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
              ELSE
                io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
              END IF;
              ov_retcode := cv_status_warn;
            END IF;
          END IF;
--
        END IF;
      END LOOP check_isdate_loop;
--
    END IF;
--
    --==============================================================
    --サイズチェック
    --==============================================================
    <<check_size_loop>>
    -- PL/SQL表：CSV要素の出荷倉庫、拠点(1-2番目)について必須チェックを行う
    FOR i IN 1..2 LOOP
      -- 要素が4バイトでない場合はエラーとする
      IF ( LENGTHB( o_csv_div_data_tab( i ) ) <> cn_len_code ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00012
                        ,iv_token_name1  => cv_message_00012_token_1
                        ,iv_token_value1 => l_csv_item_name_tab( i )
                       );
        IF ( ov_retcode = cv_status_normal ) THEN
          io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
        ELSE
          io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || CHR(13) || CHR(10) || lv_errmsg;
        END IF;
        ov_retcode := cv_status_warn;
      END IF;
    END LOOP check_size_loop;
--
    -- チェックエラーが発生した場合はレコードへの格納を行わず終了する
    IF ( ov_retcode <> cv_status_normal ) THEN
      RETURN;
    END IF;
--
    --==============================================================
    --レコードへの格納
    --==============================================================
    o_ifdata_rec.whse_code             := o_csv_div_data_tab( 1 );  -- 出荷倉庫
    o_ifdata_rec.base_code             := o_csv_div_data_tab( 2 );  -- 拠点
    o_ifdata_rec.target_month          := o_csv_div_data_tab( 3 );  -- 対象年月
--
    <<day_of_service_loop>>
    FOR i IN 4..23 LOOP
      o_ifdata_rec.day_of_service_tab( i - 3 ) := LPAD( o_csv_div_data_tab( i ), 2, '0' );  -- 1-20便日付
    END LOOP day_of_service_loop;
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
  END chk_validate_data_f;
--
  /**********************************************************************************
   * Procedure Name   : chk_exist_forecast_p
   * Description      : A-6.引取計画データ登録チェック
   ***********************************************************************************/
  PROCEDURE chk_exist_forecast_p(
    i_ifdata_rec        IN  g_ifdata_rtype                        --   レコード：ファイルアップロードI/Fテーブル要素
   ,in_ifdata_tab_idx   IN  NUMBER                                --   PL/SQL表：I/Fテーブルデータのインデックス番号
   ,io_error_msg_tab    IN  OUT g_error_msg_ttype                 --   PL/SQL表：エラーメッセージ
   ,ov_errbuf           OUT VARCHAR2                              --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2                              --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)                             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exist_forecast_p'; -- プログラム名
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
    lb_delete           BOOLEAN := TRUE;      -- 削除フラグ(1-20便が全てNullの場合はTRUE)
    ln_dummy            NUMBER;               -- 件数、NUMBER型確認用
    lv_tkn_item         VARCHAR2(100);        -- メッセージに渡すTOKEN(＆ITEM)
    lv_tkn_value        VARCHAR2(100);        -- メッセージに渡すTOKEN(＆VALUE)
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
    --==============================================================
    --1-20便入力チェック
    --==============================================================
    <<check_input_day_loop>>
    FOR i IN 1..20 LOOP
      IF ( i_ifdata_rec.day_of_service_tab( i ) IS NOT NULL ) THEN
        lb_delete := FALSE;
        EXIT check_input_day_loop;
      END IF;
    END LOOP check_input_day_loop;
--
    -- 1-20便が全てNullの場合はチェックを行わない
    IF ( lb_delete ) THEN
      RETURN;
    END IF;
--
    --==============================================================
    --引取計画データ登録チェック
    --==============================================================
    SELECT COUNT( 'X' )
    INTO   ln_dummy
    FROM   mrp_forecast_designators mfds    -- フォーキャスト名
          ,mrp_forecast_dates mfdt          -- フォーキャスト日付
          ,xxcop_item_categories1_v xicv    -- 計画_品目カテゴリビュー1
    WHERE  mfds.attribute3 = i_ifdata_rec.base_code
    AND    mfds.attribute2 = i_ifdata_rec.whse_code
    AND    mfds.attribute1 = cv_mfds_attribute1
    AND    mfds.organization_id = gn_org_id
    AND    mfds.organization_id = mfdt.organization_id
    AND    mfds.forecast_designator = mfdt.forecast_designator
    AND    mfdt.forecast_date BETWEEN TO_DATE(i_ifdata_rec.target_month || cv_first_day, cv_date_format1 )
                              AND     LAST_DAY( TO_DATE(i_ifdata_rec.target_month, cv_date_format3 ) )
    AND    mfdt.inventory_item_id = xicv.inventory_item_id
    AND    xicv.prod_class_code = cv_prod_class_code
    ;
    -- 該当データが存在する場合はエラーメッセージを設定
    IF ( ln_dummy > 0 ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_10004
                      ,iv_token_name1  => cv_message_10004_token_1
                      ,iv_token_value1 => i_ifdata_rec.target_month
                     );
      IF ( ov_retcode = cv_status_normal ) THEN
        io_error_msg_tab( in_ifdata_tab_idx ) := lv_errmsg;
      ELSE
        io_error_msg_tab( in_ifdata_tab_idx ) := io_error_msg_tab( in_ifdata_tab_idx ) || 
                                                 CHR(13) || CHR(10) || lv_errmsg;
      END IF;
      ov_retcode := cv_status_warn;
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
  END chk_exist_forecast_p;
--
  /**********************************************************************************
   * Procedure Name   : reg_leaf_data_p
   * Description      : A-7.リーフ便データ登録・削除
   ***********************************************************************************/
  PROCEDURE reg_leaf_data_p(
    i_ifdata_rec        IN  g_ifdata_rtype                 --   ファイルアップロードI/Fテーブル要素
   ,on_delete_count     OUT NUMBER                         --   削除件数
   ,on_insert_count     OUT NUMBER                         --   登録件数
   ,ov_errbuf           OUT VARCHAR2                       --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2                       --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)                      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reg_leaf_data_p'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_tkn_item         VARCHAR2(100);        -- メッセージに渡すTOKEN(＆ITEM)
    lv_tkn_value        VARCHAR2(100);        -- メッセージに渡すTOKEN(＆VALUE)
    lv_tkn_table        VARCHAR2(100);        -- メッセージに渡すTOKEN(＆TABLE)
    lv_tkn_store        VARCHAR2(100);        -- メッセージに渡すTOKEN(＆STORE)
    lv_tkn_location     VARCHAR2(100);        -- メッセージに渡すTOKEN(＆LOCATION)
    lv_tkn_yyyymm       VARCHAR2(100);        -- メッセージに渡すTOKEN(＆YYYYMM)
    lr_xldos_rowid      ROWID;                -- リーフ便データアドオンテーブル.ROWID
--
    -- *** ローカルTABLE型 ***
    TYPE l_xldow_rowid_ttype      IS TABLE OF ROWID INDEX BY BINARY_INTEGER;    -- リーフ便データアドオンテーブル.ROWID
--
    -- *** ローカルPL/SQL表 ***
    l_xldow_rowid_tab   l_xldow_rowid_ttype;  -- リーフ便データアドオンテーブル.ROWID
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
    -- 変数の初期化
    on_delete_count := 0;
    on_insert_count := 0;
--
    --==============================================================
    --対象レコードのロック
    --==============================================================
    BEGIN
      SELECT xldos.ROWID
      BULK COLLECT
      INTO   l_xldow_rowid_tab
      FROM   xxcop_leaf_day_of_service xldos
      WHERE  xldos.whse_code    = i_ifdata_rec.whse_code
      AND    xldos.base_code    = i_ifdata_rec.base_code
      AND    xldos.target_month = i_ifdata_rec.target_month
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00007
                        ,iv_token_name1  => cv_message_00007_token_1
                        ,iv_token_value1 => cv_table_xldos
                       );
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;                                            --# 任意 #
        RETURN;
    END;
--
    --==============================================================
    --対象レコードの削除
    --==============================================================
    BEGIN
      DELETE xxcop_leaf_day_of_service xldos
      WHERE  xldos.whse_code    = i_ifdata_rec.whse_code
      AND    xldos.base_code    = i_ifdata_rec.base_code
      AND    xldos.target_month = i_ifdata_rec.target_month
      ;
      -- 削除件数を取得
      on_delete_count := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_10002
                        ,iv_token_name1  => cv_message_10002_token_1
                        ,iv_token_value1 => cv_table_xldos
                        ,iv_token_name2  => cv_message_10002_token_2
                        ,iv_token_value2 => i_ifdata_rec.whse_code
                        ,iv_token_name3  => cv_message_10002_token_3
                        ,iv_token_value3 => i_ifdata_rec.base_code
                        ,iv_token_name4  => cv_message_10002_token_4
                        ,iv_token_value4 => i_ifdata_rec.target_month
                       );
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;                                            --# 任意 #
        RETURN;
    END;
--
    --==============================================================
    --リーフ便表データアドオンテーブルへの登録
    --==============================================================
    <<reg_leaf_day_loop>>
    FOR i IN 1..20 LOOP
      -- 1-20便日付がNullでない場合のみ登録する
      IF ( i_ifdata_rec.day_of_service_tab( i ) IS NOT NULL ) THEN
        BEGIN
          INSERT INTO xxcop_leaf_day_of_service (
            whse_code                     -- 出庫倉庫
           ,base_code                     -- 拠点
           ,target_month                  -- 対象年月
           ,day_of_service                -- 便
           ,created_by                    -- 作成者
           ,creation_date                 -- 作成日
           ,last_updated_by               -- 最終更新者
           ,last_update_date              -- 最終更新日
           ,last_update_login             -- 最終更新ログイン
           ,request_id                    -- 要求ID
           ,program_application_id        -- プログラムアプリケーションID
           ,program_id                    -- プログラムID
           ,program_update_date           -- プログラム更新日
          ) VALUES (
            i_ifdata_rec.whse_code                  -- 出庫倉庫
           ,i_ifdata_rec.base_code                  -- 拠点
           ,i_ifdata_rec.target_month               -- 対象年月
           ,i_ifdata_rec.day_of_service_tab( i )    -- 便
           ,cn_created_by                           -- 作成者
           ,cd_creation_date                        -- 作成日
           ,cn_last_updated_by                      -- 最終更新者
           ,cd_last_update_date                     -- 最終更新日
           ,cn_last_update_login                    -- 最終更新ログイン
           ,cn_request_id                           -- 要求ID
           ,cn_program_application_id               -- プログラムアプリケーションID
           ,cn_program_id                           -- プログラムID
           ,cd_program_update_date                  -- プログラム更新日
          )
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errmsg  := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_application
                            ,iv_name         => cv_message_10003
                            ,iv_token_name1  => cv_message_10003_token_1
                            ,iv_token_value1 => cv_table_xldos
                            ,iv_token_name2  => cv_message_10003_token_2
                            ,iv_token_value2 => i_ifdata_rec.whse_code
                            ,iv_token_name3  => cv_message_10003_token_3
                            ,iv_token_value3 => i_ifdata_rec.base_code
                            ,iv_token_name4  => cv_message_10003_token_4
                            ,iv_token_value4 => i_ifdata_rec.target_month
                            ,iv_token_name5  => cv_message_10003_token_5
                            ,iv_token_value5 => i_ifdata_rec.day_of_service_tab( i )
                           );
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            ov_retcode := cv_status_error;                                            --# 任意 #
            RETURN;
        END;
        -- 登録件数をカウント
        on_insert_count := on_insert_count + 1;
      END IF;
    END LOOP reg_leaf_day_loop;
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
  END reg_leaf_data_p;
--
  /**********************************************************************************
   * Procedure Name   : judge_result_p
   * Description      : A-8.処理内容判定
   ***********************************************************************************/
  PROCEDURE judge_result_p(
    in_delete_count     IN  NUMBER                                --   削除件数
   ,in_insert_count     IN  NUMBER                                --   登録件数
   ,in_ifdata_tab_idx   IN  NUMBER                                --   PL/SQL表：I/Fテーブルデータのインデックス番号
   ,io_result_tab       IN  OUT g_result_ttype                    --   PL/SQL表：処理結果
   ,ov_errbuf           OUT VARCHAR2                              --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2                              --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)                             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'judge_result_p'; -- プログラム名
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
    --==============================================================
    --処理結果の判定
    --==============================================================
    -- 登録件数が1以上の場合
    IF ( in_insert_count > 0 ) THEN
      -- 削除件数が1以上の場合
      IF ( in_delete_count > 0 ) THEN
        io_result_tab( in_ifdata_tab_idx ) := cv_result_update;  -- 更新
      ELSE
        io_result_tab( in_ifdata_tab_idx ) := cv_result_insert;  -- 登録
      END IF;
--
    -- 登録件数が0の場合
    ELSE
      io_result_tab( in_ifdata_tab_idx ) := cv_result_delete;  -- 削除
    END IF;
--
  EXCEPTION
--
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
  END judge_result_p;
--
  /**********************************************************************************
   * Procedure Name   : output_report_p
   * Description      : A-11.アップロード内容の出力
   ***********************************************************************************/
  PROCEDURE output_report_p(
    i_ifdata_tab        IN xxccp_common_pkg2.g_file_data_tbl      --   PL/SQL表：I/Fテーブルデータ
   ,i_error_msg_tab     IN g_error_msg_ttype                      --   PL/SQL表：エラーメッセージ
--   ,i_warning_msg_tab   IN g_warning_msg_ttype                    --   PL/SQL表：警告メッセージ
   ,i_result_tab        IN g_result_ttype                         --   PL/SQL表：処理結果
   ,iv_retcode          IN VARCHAR2                               --   リターン・コード
   ,iv_errmsg           IN VARCHAR2                               --   ユーザー・エラー・メッセージ(参照用)
   ,iv_notice           IN VARCHAR2                               --   ファイルアップロードI/Fテーブル削除時のエラー
   ,ov_errbuf           OUT VARCHAR2                              --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2                              --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)                             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_report_p'; -- プログラム名
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
    ln_loop             NUMBER;               -- ループ変数
    ln_dummy            NUMBER;               -- 件数、NUMBER型確認用
    lv_tkn_item         VARCHAR2(100);        -- メッセージに渡すTOKEN(＆ITEM)
    lv_tkn_value        VARCHAR2(100);        -- メッセージに渡すTOKEN(＆VALUE)
    lv_conc_name        fnd_concurrent_programs.concurrent_program_name%TYPE;   -- コンカレント名
    lv_report           VARCHAR2(4096);       -- 出力文字列
    lv_warn_msg_wk      VARCHAR2(4096);       -- 警告メッセージ編集用
    lv_error_msg_wk     VARCHAR2(4096);       -- エラーメッセージ編集用
--    lv_finish_msg       VARCHAR2(40);         -- 終了メッセージ
    lv_crlf             VARCHAR2(2) := CHR(13) || CHR(10);  -- 改行コード
--
    -- *** ローカルTABLE型 ***
    TYPE l_report_ttype IS TABLE OF VARCHAR2(4096) INDEX BY BINARY_INTEGER;  -- 出力文字列
--
    -- *** ローカルPL/SQL表 ***
    l_report_tab  l_report_ttype;   -- 出力文字列
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
    --==============================================================
    --ヘッダ情報を設定
    --==============================================================
    -- 出力文字列をセット
    l_report_tab( l_report_tab.COUNT + 1 ) := '';
    l_report_tab( l_report_tab.COUNT + 1 ) := xxccp_common_pkg.get_msg(
                                                iv_application  => cv_msg_application
                                               ,iv_name         => cv_message_00036
                                               ,iv_token_name1  => cv_message_00036_token_1
                                               ,iv_token_value1 => gn_param_file_id
                                               ,iv_token_name2  => cv_message_00036_token_2
                                               ,iv_token_value2 => gn_param_format_pattern
                                               ,iv_token_name3  => cv_message_00036_token_3
                                               ,iv_token_value3 => gv_upload_name
                                               ,iv_token_name4  => cv_message_00036_token_4
                                               ,iv_token_value4 => gv_file_name
                                              );
--
    --==============================================================
    --取込完了または取込失敗データを設定
    --==============================================================
    -- PL/SQL表：I/Fテーブルデータが存在する場合のみ実行
    IF ( i_ifdata_tab.COUNT > 0 ) THEN
      -- PL/SQL表：エラーメッセージが存在しない場合
      IF ( i_error_msg_tab.COUNT = 0 ) THEN
        --==============================================================
        --取込完了データを出力
        --==============================================================
        -- 見出しを設定
        l_report_tab( l_report_tab.COUNT + 1 ) := '';
        l_report_tab( l_report_tab.COUNT + 1 ) := cv_title_upload_ok;
--
        -- 取込完了データを設定（PL/SQL表：処理結果の件数分繰り返す）
        ln_loop := 0;
        <<set_upload_ok_loop>>
        WHILE ( ln_loop < i_result_tab.LAST ) LOOP
          -- PL/SQL表の次のレコードへ移動
          ln_loop := i_result_tab.NEXT( ln_loop );
--
          lv_report := LPAD( ( ln_loop - i_result_tab.FIRST + 1 ), 5 );   -- レコード番号（先頭半角スペース埋めで5桁に編集）
          lv_report := lv_report || ' ' || i_result_tab( ln_loop );       -- PL/SQL表：処理結果
          lv_report := lv_report || ' ' || i_ifdata_tab( ln_loop );       -- PL/SQL表：I/Fテーブルデータ
          l_report_tab( l_report_tab.COUNT + 1 ) := lv_report;
----
--          -- PL/SQL表：警告メッセージ（該当するインデックスが存在する場合のみ）
--          IF ( i_warning_msg_tab.EXISTS( ln_loop ) ) THEN
--            -- PL/SQL表：警告メッセージを編集（行ごとに先頭に半角スペース6桁を付与）
--            lv_warn_msg_wk := REPLACE( i_warning_msg_tab( ln_loop ), lv_crlf, lv_crlf || RPAD( ' ', 6 ) );
--            lv_warn_msg_wk := RPAD( ' ', 6 ) || lv_warn_msg_wk;
--            l_report_tab( l_report_tab.COUNT + 1 ) := lv_warn_msg_wk;
--          END IF;
        END LOOP set_upload_ok_loop;
--
      -- PL/SQL表：エラーメッセージが存在する場合
      ELSE
        --==============================================================
        --取込失敗データを出力
        --==============================================================
        -- 見出しを設定
        l_report_tab( l_report_tab.COUNT + 1 ) := '';
        l_report_tab( l_report_tab.COUNT + 1 ) := cv_title_upload_ng;
--
        -- 取込失敗データを設定（PL/SQL表：エラーメッセージの件数分繰り返す）
        ln_loop := 0;
        <<set_upload_ng_loop>>
        WHILE ( ln_loop < i_error_msg_tab.LAST ) LOOP
          -- PL/SQL表の次のレコードへ移動
          ln_loop := i_error_msg_tab.NEXT( ln_loop );
--
          lv_report := LPAD( ( ln_loop - i_ifdata_tab.FIRST + 1 ), 5 );   -- レコード番号（先頭半角スペース埋めで5桁に編集）
          lv_report := lv_report || ' ' || i_ifdata_tab( ln_loop );       -- PL/SQL表：I/Fテーブルデータ
--
          -- PL/SQL表：エラーメッセージを編集（行ごとに先頭に半角スペース6桁を付与）
          lv_error_msg_wk := REPLACE( i_error_msg_tab( ln_loop ), lv_crlf, lv_crlf || RPAD( ' ', 6 ) );
          lv_error_msg_wk := RPAD( ' ', 6 ) || lv_error_msg_wk;
--
          lv_report := lv_report || lv_crlf || lv_error_msg_wk;  -- PL/SQL表：エラーメッセージ
          l_report_tab( l_report_tab.COUNT + 1 ) := lv_report;
        END LOOP set_upload_ng_loop;
--
      END IF;
--
    END IF;
--
    --==============================================================
    --エラーメッセージの設定
    --==============================================================
    IF ( iv_errmsg IS NOT NULL ) THEN
      l_report_tab( l_report_tab.COUNT + 1 ) := iv_errmsg;
    END IF;
--
    IF ( iv_notice IS NOT NULL ) THEN
      l_report_tab( l_report_tab.COUNT + 1 ) := iv_notice;
    END IF;
--
    --==============================================================
    --完了メッセージの設定
    --==============================================================
    -- リターンコードが「エラー」でない場合
    IF ( iv_retcode <> cv_status_error ) THEN
      -- 各処理件数を設定
      gn_normal_cnt    := gn_target_cnt;
      gn_error_cnt     := 0;
    -- リターンコードが「エラー」の場合
    ELSE
      -- 各処理件数を設定
      gn_normal_cnt    := 0;
      gn_error_cnt     := i_error_msg_tab.COUNT;
    END IF;
--
    --==============================================================
    --処理結果レポートへの出力
    --==============================================================
    ln_loop := 0;
    <<output_report_loop>>
    WHILE ( ln_loop < l_report_tab.LAST ) LOOP
      -- PL/SQL表の次のレコードへ移動
      ln_loop := l_report_tab.NEXT( ln_loop );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => l_report_tab( ln_loop )
      );
    END LOOP output_report_loop;
    -- PL/SQL表：出力文字列の初期化
    l_report_tab.DELETE;
--
    --==============================================================
    --ログへの出力
    --==============================================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_application
                  ,iv_name         => cv_message_00036
                  ,iv_token_name1  => cv_message_00036_token_1
                  ,iv_token_value1 => gn_param_file_id
                  ,iv_token_name2  => cv_message_00036_token_2
                  ,iv_token_value2 => gn_param_format_pattern
                  ,iv_token_name3  => cv_message_00036_token_3
                  ,iv_token_value3 => gv_upload_name
                  ,iv_token_name4  => cv_message_00036_token_4
                  ,iv_token_value4 => gv_file_name
                 )
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
  END output_report_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errmsg2 VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(アップロード内容の出力)
    lv_notice  VARCHAR2(5000);  -- ファイルアップロードI/Fテーブル削除時のエラー(リターン・コードには反映させない)
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_file_format      VARCHAR2(256);    -- ファイルフォーマット
    ln_delete_count     NUMBER;           -- 削除件数
    ln_insert_count     NUMBER;           -- 登録件数
    ln_ifdata_tab_idx   NUMBER;           -- PL/SQL表：I/Fテーブルデータのインデックス番号
    ln_A_1_error_cnt    NUMBER := 0;      -- A-1エラー件数
--
    -- *** ローカルレコード ***
    l_ifdata_rec           g_ifdata_rtype;  -- ファイルアップロードI/Fテーブル要素
--
    -- *** ローカルPL/SQL表 ***
    l_csv_div_data_tab     xxcop_common_pkg.g_char_ttype;       -- CSV要素
    l_ifdata_tab           xxccp_common_pkg2.g_file_data_tbl;   -- I/Fテーブルデータ
--    l_warning_msg_tab      g_warning_msg_ttype;                 -- 警告メッセージ
    l_error_msg_tab        g_error_msg_ttype;                   -- エラーメッセージ：複数行の場合あり
    l_result_tab           g_result_ttype;                      -- 処理結果：(登録),(更新),(削除)の何れか
--
    -- *** ローカル・ユーザ定義例外 ***
    submain_expt EXCEPTION;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    BEGIN
--
      -- ===============================
      -- A-2.パラメータ妥当性チェック
      -- ===============================
      chk_parameter_p(
        lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,lv_retcode         -- リターン・コード             --# 固定 #
       ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-1.組織IDの取得
      -- ===============================
      BEGIN
        gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_master_org_id ) );  -- マスタ品目組織ID(固定値:113)
      EXCEPTION
        WHEN OTHERS THEN
          gn_org_id := NULL;
      END;
--
      -- プロファイルからマスタ品目組織IDが取得出来ない、または数値でない場合
      IF ( gn_org_id IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00002
                        ,iv_token_name1  => cv_message_00002_token_1
                        ,iv_token_value1 => cv_master_org_id_name
                       );
        lv_retcode := cv_status_error;
        ln_A_1_error_cnt := 1;
        RAISE submain_expt;
      END IF;
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_START
      -- ===============================
      --  営業組織コードの取得
      -- ===============================
      BEGIN
        gv_sales_org_code := fnd_profile.value(cv_sales_org_code);
      EXCEPTION
        WHEN OTHERS THEN
          gv_sales_org_code := NULL;
      END;
      -- プロファイル：営業組織が取得出来ない場合
      IF ( gv_sales_org_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00002
                      ,iv_token_name1  => cv_message_00002_token_1
                      ,iv_token_value1 => cv_sales_org_code_name
                     );
        lv_retcode   := cv_status_error;
        ln_A_1_error_cnt := 1;
        RAISE submain_expt;
      END IF;
      -- ===============================
      --  営業組織IDの取得
      -- ===============================
      BEGIN
        SELECT organization_id
        INTO   gn_sales_org_id
        FROM   mtl_parameters
        WHERE  organization_code = gv_sales_org_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gn_sales_org_id := NULL;
      END;
      -- 営業組織IDが取得出来ない場合
      IF ( gn_sales_org_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_message_00013
                      ,iv_token_name1  => cv_message_00013_token_1
                      ,iv_token_value1 => cv_item_org_code
                      ,iv_token_name2  => cv_message_00013_token_2
                      ,iv_token_value2 => gv_sales_org_code
                      ,iv_token_name3  => cv_message_00013_token_3
                      ,iv_token_value3 => cv_table_mp
                     );
        lv_retcode   := cv_status_error;
        ln_A_1_error_cnt := 1;
        RAISE submain_expt;
      END IF;
--20090428_Ver1.1_T1_0645_SCS.Kikuchi_ADD_END
--
      -- ===============================
      -- A-3.クイックコード取得(リーフ便CSVファイルのフォーマット)
      -- ===============================
      get_format_pattern_p(
        lv_file_format              -- ファイルフォーマット
       ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode                  -- リターン・コード             --# 固定 #
       ,lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-4.ファイルアップロードI/Fテーブルデータ抽出
      -- ===============================
      get_file_ul_interface_p(
        l_ifdata_tab                -- PL/SQL表：I/Fテーブルデータ
       ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
       ,lv_retcode                  -- リターン・コード             --# 固定 #
       ,lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- Loop-1.I/Fテーブル対象データ
      -- ===============================
      -- I/Fテーブル対象データが存在する場合のみ
      IF ( l_ifdata_tab.COUNT > 0 ) THEN
        <<ul_interface_loop>>
        FOR ln_ifdata_tab_idx IN l_ifdata_tab.FIRST..l_ifdata_tab.LAST LOOP
--
          -- 空白行は読み飛ばす
          IF ( l_ifdata_tab( ln_ifdata_tab_idx ) IS NOT NULL ) THEN
            -- 処理件数をカウント
            gn_target_cnt := gn_target_cnt + 1;
            -- ===============================
            -- A-5.データ妥当性チェック
            -- ===============================
            chk_validate_data_f(
              lv_file_format              -- ファイルフォーマット
             ,l_ifdata_tab                -- PL/SQL表：I/Fテーブルデータ
             ,ln_ifdata_tab_idx           -- PL/SQL表：I/Fテーブルデータのインデックス番号
             ,l_csv_div_data_tab          -- PL/SQL表：CSV要素
             ,l_ifdata_rec                -- レコード：ファイルアップロードI/Fテーブル要素
             ,l_error_msg_tab             -- PL/SQL表：エラーメッセージ
             ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
             ,lv_retcode                  -- リターン・コード             --# 固定 #
             ,lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
--
            IF ( lv_retcode = cv_status_warn ) THEN
              -- チェックエラーの場合は終了ステータスを「エラー」とし、処理を続行する
              ov_retcode := cv_status_error;
            ELSIF ( lv_retcode = cv_status_error ) THEN
              -- それ以外のエラーの場合は処理を中断する
              RAISE submain_expt;
            END IF;
--
            -- A-5.データ妥当性チェックの終了ステータスが「正常」の場合のみ
            IF ( lv_retcode = cv_status_normal ) THEN
--
              -- ===============================
              -- A-6.引取計画データ登録チェック
              -- ===============================
              chk_exist_forecast_p(
                l_ifdata_rec                -- レコード：ファイルアップロードI/Fテーブル要素
               ,ln_ifdata_tab_idx           -- PL/SQL表：I/Fテーブルデータのインデックス番号
               ,l_error_msg_tab             -- PL/SQL表：エラーメッセージ
               ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
               ,lv_retcode                  -- リターン・コード             --# 固定 #
               ,lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
--
              IF ( lv_retcode = cv_status_warn ) THEN
                -- チェックエラーの場合は終了ステータスを「エラー」とし、処理を続行する
                ov_retcode := cv_status_error;
              ELSIF ( lv_retcode = cv_status_error ) THEN
                -- それ以外のエラーの場合は処理を中断する
                RAISE submain_expt;
              END IF;
--
            END IF;
--
            -- 終了ステータスが「エラー」以外の場合のみ
            IF ( ov_retcode <> cv_status_error ) THEN
--
              -- ===============================
              -- A-7.リーフ便データ登録・削除
              -- ===============================
              reg_leaf_data_p(
                l_ifdata_rec                -- ファイルアップロードI/Fテーブル要素
               ,ln_delete_count             -- 削除件数
               ,ln_insert_count             -- 登録件数
               ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
               ,lv_retcode                  -- リターン・コード             --# 固定 #
               ,lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
--
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE submain_expt;
              END IF;
--
              -- ===============================
              -- A-8.処理内容判定
              -- ===============================
              judge_result_p(
                ln_delete_count             -- 削除件数
               ,ln_insert_count             -- 登録件数
               ,ln_ifdata_tab_idx           -- PL/SQL表：I/Fテーブルデータのインデックス番号
               ,l_result_tab                -- PL/SQL表：処理結果
               ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
               ,lv_retcode                  -- リターン・コード             --# 固定 #
               ,lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
--
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE submain_expt;
              END IF;
--
            END IF;
          END IF;
        END LOOP ul_interface_loop;
      END IF;
--
    EXCEPTION
      WHEN submain_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
        -- PL/SQL表の削除
        l_ifdata_tab.DELETE;
--        l_warning_msg_tab.DELETE;
        l_error_msg_tab.DELETE;
        l_result_tab.DELETE;
    END;
--
    -- ===============================
    -- A-9.トランザクションの確定
    -- ===============================
    IF ( ov_retcode = cv_status_error ) THEN
      -- 終了ステータスが「エラー」の場合はロールバックする
      ROLLBACK;
    ELSE
      -- 終了ステータスが「エラー」以外の場合はコミットする
      COMMIT;
    END IF;
--
    
    -- ===============================
    -- A-10.ファイルアップロードI/Fテーブルの削除
    -- ===============================
    xxcop_common_pkg.delete_upload_table(
      in_file_id   => gn_param_file_id            -- ファイルＩＤ
     ,ov_retcode   => lv_retcode                  -- リターンコード
     ,ov_errbuf    => lv_errbuf                   -- エラー・メッセージ
     ,ov_errmsg    => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
--
    -- 戻り値が正常でない場合（※ov_retcodeは変更しない）
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ロックエラー以外の場合（ロックエラーは共通関数内でAPP-XXCOP1-00007出力済み）
      IF ( lv_errbuf IS NOT NULL ) THEN
        lv_notice  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00031
                        ,iv_token_name1  => cv_message_10031_token_1
                        ,iv_token_value1 => 'ファイルアップロードI/Fテーブル'
                        ,iv_token_name2  => cv_message_10031_token_2
                        ,iv_token_value2 => gn_param_file_id
                       );
      END IF;
    ELSE
      COMMIT;
    END IF;
--
    -- ===============================
    -- A-11.アップロード内容の出力
    -- ===============================
    output_report_p(
      l_ifdata_tab                -- PL/SQL表：I/Fテーブルデータ
     ,l_error_msg_tab             -- PL/SQL表：エラーメッセージ
--     ,l_warning_msg_tab           -- PL/SQL表：警告メッセージ
     ,l_result_tab                -- PL/SQL表：処理結果
     ,ov_retcode                  -- リターン・コード
     ,lv_errmsg                   -- ユーザー・エラー・メッセージ(参照用)
     ,lv_notice                   -- ファイルアップロードI/Fテーブル削除時のエラー
     ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,lv_retcode                  -- リターン・コード             --# 固定 #
     ,lv_errmsg2);                -- ユーザー・エラー・メッセージ --# 固定 #
--

    gn_error_cnt := gn_error_cnt + ln_A_1_error_cnt;
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf            OUT VARCHAR2,    --   エラー・メッセージ  --# 固定 #
    retcode           OUT VARCHAR2,    --   リターン・コード    --# 固定 #
    in_file_id        IN  VARCHAR2,    --   FILE_ID
    in_format_pattern IN  VARCHAR2     --   フォーマット・パターン
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
    -- パラメータの格納
    -- ===============================================
    gv_param_file_id        := in_file_id;
    gv_param_format_pattern := in_format_pattern;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
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
--    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOP004A01C;
/
