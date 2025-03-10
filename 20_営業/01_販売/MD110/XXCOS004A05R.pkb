CREATE OR REPLACE PACKAGE BODY APPS.XXCOS004A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A05R (body)
 * Description      : 消化VD別掛率チェックリスト
 * MD.050           : 消化VD別掛率チェックリスト MD050_COS_004_A05
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  check_parameter        パラメータチェック処理(A-1)
 *  get_data               データ取得(A-2)
 *  insert_rpt_wrk_data    帳票ワークテーブル登録(A-3)
 *  execute_svf            ＳＶＦ起動(A-4)
 *  delete_rpt_wrk_data    帳票ワークテーブル削除(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/21    1.0   K.Kin            新規作成
 *  2009/02/04    1.1   K.Kin            [COS_015]顧客名の桁数あふれ不具合対応
 *  2009/02/24    1.2   K.Kin            基準日条件追加
 *  2009/02/26    1.3   K.Kin            削除処理のコメント削除
 *  2009/04/20    1.4   T.Kitajima       [T1_0662]従業員マスタとの外部結合
 *  2009/06/19    1.5   K.Kiriu          [T1_1437]データパージ不具合対応
 *  2009/09/25    1.6   N.Maeda          [0001155]設定掛率金額の設定値修正
 *                                       [0001378]出力桁数修正対応
 *  2009/10/16    1.7   S.Miyakoshi      [0001543]差額＝0の出力可能対応
 *  2010/02/23    1.8   K.Atsushiba      [E_本稼動_01670]異常掛率対応
 *  2011/04/18    1.9   Oukou            [E_本稼動_07098]消化計算後出力可能対応
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
  global_proc_date_err_expt EXCEPTION;
  global_api_err_expt       EXCEPTION;
  global_call_api_expt      EXCEPTION;
  global_require_param_expt EXCEPTION;
  global_insert_data_expt   EXCEPTION;
  global_delete_data_expt   EXCEPTION;
  global_nodata_expt        EXCEPTION;
  global_get_profile_expt   EXCEPTION;
    --*** 処理対象データロック例外 ***
  global_data_lock_expt     EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS004A05R'; -- パッケージ名
  --帳票関連
  cv_conc_name              CONSTANT VARCHAR2(100) := 'XXCOS004A05R';         -- コンカレント名
  cv_file_id                CONSTANT VARCHAR2(100) := 'XXCOS004A05R';         -- 帳票ＩＤ
  cv_extension_pdf          CONSTANT VARCHAR2(100) := '.pdf';                 -- 拡張子（ＰＤＦ）
  cv_frm_file               CONSTANT VARCHAR2(100) := 'XXCOS004A05S.xml';     -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT VARCHAR2(100) := 'XXCOS004A05S.vrq';     -- クエリー様式ファイル名
  cv_output_mode_pdf        CONSTANT VARCHAR2(1)   := '1';                    -- 出力区分（ＰＤＦ）
  --アプリケーション短縮名
  ct_xxcos_appl_short_name  CONSTANT fnd_application.application_short_name%TYPE
                                     := 'XXCOS';                    --販物短縮アプリ名
  --販物メッセージ
  ct_msg_lock_err           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00001';         --ロック取得エラーメッセージ
  ct_msg_get_profile_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00004';         --プロファイル取得エラー
  ct_msg_require_param_err  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00006';         --必須入力パラメータ未設定エラー
  ct_msg_insert_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00010';         --データ登録エラーメッセージ
  ct_msg_delete_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00012';         --データ削除エラーメッセージ
  ct_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00013';         --データ取得エラーメッセージ
  ct_msg_process_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00014';         --業務日付取得エラー
  ct_msg_call_api_err       CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00017';         --API呼出エラーメッセージ
  ct_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00018';         --明細0件用メッセージ
  ct_msg_svf_api            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00041';         --ＳＶＦ起動ＡＰＩ
  ct_msg_request            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00042';         --要求ＩＤ
  ct_msg_max_date           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00056';          --XXCOS:MAX日付
  ct_msg_profile_name       CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00043';         --プロファイル
  ct_msg_parameter          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11101';         --パラメータ出力メッセージ
  ct_msg_no_add             CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11102';         --未計算
  ct_msg_rpt_wrk_tbl        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11103';         --帳票ワークテーブル
  ct_msg_name_err           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00055';         --拠点コード
/* 2011/04/18 Ver1.9 ADD Start */
  ct_msg_parameter1         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11104';         --パラメータ出力メッセージ
/* 2011/04/18 Ver1.9 ADD Start */
  --トークン
  cv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';                --テーブル
  cv_tkn_profile            CONSTANT VARCHAR2(100) := 'PROFILE';              --プロファイル
  cv_tkn_table_name         CONSTANT VARCHAR2(100) := 'TABLE_NAME';           --テーブル名称
  cv_tkn_key_data           CONSTANT VARCHAR2(100) := 'KEY_DATA';             --キーデータ
  cv_tkn_api_name           CONSTANT VARCHAR2(100) := 'API_NAME';             --ＡＰＩ名称
  cv_tkn_param1             CONSTANT VARCHAR2(100) := 'PARAM1';               --第１入力パラメータ
  cv_tkn_param2             CONSTANT VARCHAR2(100) := 'PARAM2';               --第２入力パラメータ
/* 2011/04/18 Ver1.9 ADD Start */
  cv_tkn_param3             CONSTANT VARCHAR2(100) := 'PARAM3';               --第３入力パラメータ
/* 2011/04/18 Ver1.9 ADD END   */
  cv_tkn_request            CONSTANT VARCHAR2(100) := 'REQUEST';              --要求ＩＤ
  cv_tkn_profile_name       CONSTANT VARCHAR2(100) := 'PROFILE_NAME';         --プロファイル値
  cv_tkn_in_param           CONSTANT VARCHAR2(100) := 'IN_PARAM';             --入力パラメータ
  --プロファイル名称
  ct_prof_org_id            CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'ORG_ID';
  ct_prof_max_date          CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOS1_MAX_DATE';
  --クイックコードタイプ
  ct_sct_cust_type          CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_VD_UNCALCULATE_CLASS';  --クイックコードマスタ.タイプ
  ct_qct_cust_type          CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_CUS_CLASS_MST_004_A05';
  ct_qcc_cust_type          CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS_004_A05%';
  --使用可能フラグ定数
  ct_enabled_flag_yes       CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                     := 'Y';                              --使用可能
  --消化VD消化計算ヘッダ用フラグ
  ct_make_flag_yes          CONSTANT xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                     := 'Y';                              --作成済み
  ct_make_flag_no           CONSTANT xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                     := 'N';                              --未作成
  --フォーマット
  cv_fmt_date8              CONSTANT VARCHAR2(8)   := 'RRRRMMDD';
  cv_fmt_date               CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';
  cv_fmt_tax                CONSTANT VARCHAR2(7)   := '990.00';
  --パーセント定数
  cv_pr_tax                 CONSTANT VARCHAR2(7)   := '%';
  --金額ゼロ
  cn_amount_zero                  CONSTANT NUMBER  := 0;
  --未計算区分定数
  ct_uncalculate_class_normal     CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                                   := '0';                --通常
-- ******************** 2010/02/23 1.8 K.Aatsushiba ADD START ********************* --
  ct_uncalculate_class_abnormal   CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                                   := '4';                --異常掛率
-- ******************** 2010/02/23 1.8 K.Aatsushiba ADD End ********************* --                                                   
  --位置
  cn_pos_star               CONSTANT NUMBER        := 1;
  --桁数長さ
  cn_base_name_length       CONSTANT NUMBER        := 30;
  cn_party_name_length      CONSTANT NUMBER        := 30;
  cn_employee_name_length   CONSTANT NUMBER        := 30;
-- ******************** 2009/09/25 1.6 N.Maeda ADD START ********************* --
  ct_user_lang              CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
-- ******************** 2009/09/25 1.6 N.Maeda ADD  END  ********************* --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --帳票ワーク用テーブル型定義
  TYPE g_rpt_data_ttype
  IS
    TABLE OF
      xxcos_rep_dig_dv_list%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --パラメータ
  gv_sales_base_code              VARCHAR2(100);                      -- 拠点コード
  gv_customer_number              VARCHAR2(100);                      -- 顧客コード
/* 2011/04/18 Ver1.9 ADD Start */
  gd_due_date                     DATE;                               -- 締日
/* 2011/04/18 Ver1.9 ADD End   */
  --初期取得
  gd_process_date                 DATE;                               -- 業務日付
  gd_max_date                     DATE;                               -- MAX日付
  gv_no_add                       VARCHAR2(100);                      -- 未計算
  --帳票ワーク内部テーブル
  g_rpt_data_tab                  g_rpt_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_sales_base_code        IN      VARCHAR2,                       -- 拠点コード
    iv_customer_number        IN      VARCHAR2,                       -- 顧客コード
/* 2011/04/18 Ver1.9 ADD Start */
    iv_due_date               IN      VARCHAR2,                       -- 締日
/* 2011/04/18 Ver1.9 ADD End   */
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    --==================================
    -- 1.パラメータ出力
    --==================================
/* 2011/04/18 Ver1.9 MOD Start */
    IF ( iv_due_date IS NULL ) THEN
      lv_errmsg               := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_parameter,
          iv_token_name1        => cv_tkn_param1,
          iv_token_value1       => iv_sales_base_code,
          iv_token_name2        => cv_tkn_param2,
          iv_token_value2       => iv_customer_number
        );
    ELSE
      lv_errmsg               := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_parameter1,
          iv_token_name1        => cv_tkn_param1,
          iv_token_value1       => iv_sales_base_code,
          iv_token_name2        => cv_tkn_param2,
          iv_token_value2       => iv_customer_number,
          iv_token_name3        => cv_tkn_param3,
          iv_token_value3       => iv_due_date
        );
    END IF;
/* 2011/04/18 Ver1.9 MOD End   */
    --
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => lv_errmsg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => NULL
    );
--
    --==================================
    -- 2.パラメータ変換
    --==================================
    gv_sales_base_code      := iv_sales_base_code;
    gv_customer_number      := iv_customer_number;
/* 2011/04/18 Ver1.9 ADD Start */
    gd_due_date             := TO_DATE(iv_due_date, cv_fmt_date);
/* 2011/04/18 Ver1.9 ADD End   */
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : パラメータチェック処理(A-1)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter';        -- プログラム名
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
    lv_org_id        VARCHAR2(5000);
    lv_max_date      VARCHAR2(5000);
    lv_profile_name  VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.業務日付取得
    --==================================
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date  IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 2.XXCOS:MAX日付
    --==================================
    lv_max_date               := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_max_date  IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 3.拠点コードの必須チェック
    --==================================
    IF ( gv_sales_base_code  IS NULL ) THEN
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_name_err
                                 );
      RAISE global_require_param_expt;
    END IF;
--
    --==================================
    -- 4.未計算取得
    --==================================
    gv_no_add                 := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_no_add
                                 );
--
  EXCEPTION
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_process_date_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_get_profile_err,
        iv_token_name1        => cv_tkn_profile,
        iv_token_value1       => lv_profile_name
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 必須入力パラメータ未設定例外ハンドラ ***
    WHEN global_require_param_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
       iv_application        => ct_xxcos_appl_short_name,
       iv_name               => ct_msg_require_param_err,
       iv_token_name1        => cv_tkn_in_param,
       iv_token_value1       => lv_profile_name
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   #######################################
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    ln_idx           NUMBER;
    ln_record_id     NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR data_cur
    IS
      SELECT xsvdh.digestion_due_date             digestion_due_date,               --消化計算締年月日
             xsvdh.sales_base_code                sales_base_code,                  --売上拠点コード
             hpb.party_name                       sales_base_name,                  --拠点名称
             xsvdh.performance_by_code            performance_by_code,              --成績計上者コード
             papf.per_information18               per_information18,                --氏
             papf.per_information19               per_information19,                --名
             xsvdh.customer_number                customer_number,                  --顧客コード
             hpc.party_name                       party_name,                       --顧客名称
             xsvdh.ar_sales_amount                ar_sales_amount,                  --売上金額
             xsvdh.sales_amount                   sales_amount,                     --販売金額
             xsvdh.balance_amount                 balance_amount,                   --差額
             xsvdh.digestion_calc_rate            digestion_calc_rate,              --消化計算掛率
             xsvdh.master_rate                    master_rate,                      --マスタ掛率
             xsvdh.uncalculate_class              uncalculate_class,                --未計算区分
             flv.description                      confirmation_message              --確認メッセージ
       FROM  xxcos_vd_digestion_hdrs              xsvdh,   --消化VD用消化計算ヘッダテーブル
             hz_cust_accounts                     hcaeb,   --顧客マスタ_拠点
             hz_parties                           hpb,     --パーティマスタ_拠点
             hz_cust_accounts                     hcaec,   --顧客マスタ_顧客
             hz_parties                           hpc,     --パーティマスタ_顧客
-- ******************** 2009/09/25 1.6 N.Maeda DEL START ********************* --
--             fnd_application                      fa,      --アプリケーションマスタ
--             fnd_lookup_types                     flt,     --クイックコードタイプマスタ
-- ******************** 2009/09/25 1.6 N.Maeda DEL  END  ********************* --
             fnd_lookup_values                    flv,     --クイックコード値マスタ
             per_all_people_f                     papf     --従業員マスタ
      WHERE  xsvdh.sales_base_code = hcaeb.account_number
      AND    hcaeb.party_id                       = hpb.party_id
      AND    EXISTS (SELECT flv.meaning meaning
-- ******************** 2009/09/25 1.6 N.Maeda MOD START ********************* --
--                     FROM   fnd_application               fa,
--                            fnd_lookup_types              flt,
--                            fnd_lookup_values             flv
                     FROM   fnd_lookup_values             flv
--                     WHERE  fa.application_id                             = flt.application_id
--                     AND    flt.lookup_type                               = flv.lookup_type
--                     AND    fa.application_short_name                     = ct_xxcos_appl_short_name
--                     AND    flv.lookup_type                               = ct_qct_cust_type
                     WHERE  flv.lookup_type                               = ct_qct_cust_type
-- ******************** 2009/09/25 1.6 N.Maeda MOD  END  ********************* --
                     AND    flv.lookup_code                               LIKE ct_qcc_cust_type
                     AND    flv.start_date_active                         <= xsvdh.digestion_due_date
                     AND    NVL( flv.end_date_active, gd_max_date )       >= xsvdh.digestion_due_date
                     AND    flv.enabled_flag                              = ct_enabled_flag_yes
-- ******************** 2009/09/25 1.6 N.Maeda MOD START ********************* --
--                     AND    flv.language                                  = USERENV( 'LANG' )
                     AND    flv.language                                  = ct_user_lang
-- ******************** 2009/09/25 1.6 N.Maeda MOD  END  ********************* --
                     AND    flv.meaning                                   = hcaeb.customer_class_code
                    ) --顧客マスタ.顧客区分 = 1(拠点)
      AND    xsvdh.cust_account_id                         = hcaec.cust_account_id
      AND    hcaec.party_id                                = hpc.party_id
-- ******************** 2009/09/25 1.6 N.Maeda DEL START ********************* --
--      AND    fa.application_id                             = flt.application_id
--      AND    flt.lookup_type                               = flv.lookup_type
--      AND    fa.application_short_name                     = ct_xxcos_appl_short_name
-- ******************** 2009/09/25 1.6 N.Maeda DEL  END  ********************* --
      AND    flv.lookup_type                               = ct_sct_cust_type
      AND    flv.lookup_code                               = xsvdh.uncalculate_class
      AND    flv.start_date_active                         <= xsvdh.digestion_due_date
      AND    NVL( flv.end_date_active, gd_max_date )       >= xsvdh.digestion_due_date
-- ******************** 2009/09/25 1.6 N.Maeda MOD START ********************* --
--      AND    flv.language                                  = USERENV( 'LANG' )
      AND    flv.language                                  = ct_user_lang
-- ******************** 2009/09/25 1.6 N.Maeda MOD  END  ********************* --
      AND    flv.enabled_flag                              = ct_enabled_flag_yes
      AND    xsvdh.sales_result_creation_flag              = ct_make_flag_no
      AND    xsvdh.sales_base_code IN(
                    SELECT
                      gv_sales_base_code sales_base_code
                    FROM
                      DUAL
                    UNION
                    SELECT hcae.account_number account_number      --拠点コード
                    FROM   hz_cust_accounts    hcae,
                           xxcmm_cust_accounts xcae
                    WHERE  hcae.cust_account_id = xcae.customer_id --顧客マスタ.顧客ID =顧客アドオン.顧客ID
                    AND    EXISTS (SELECT flv.meaning
-- ******************** 2009/09/25 1.6 N.Maeda MOD START ********************* --
--                                    FROM   fnd_application               fa,
--                                           fnd_lookup_types              flt,
--                                           fnd_lookup_values             flv
                                    FROM   fnd_lookup_values             flv
--                                    WHERE  fa.application_id                             = flt.application_id
--                                    AND    flt.lookup_type                               = flv.lookup_type
--                                    AND    fa.application_short_name                     = ct_xxcos_appl_short_name
--                                    AND    flv.lookup_type                               = ct_qct_cust_type
                                    WHERE  flv.lookup_type                               = ct_qct_cust_type
-- ******************** 2009/09/25 1.6 N.Maeda MOD  END  ********************* --
                                    AND    flv.lookup_code                               LIKE ct_qcc_cust_type
                                    AND    flv.start_date_active                         <= xsvdh.digestion_due_date
                                    AND    NVL( flv.end_date_active, gd_max_date )       >= xsvdh.digestion_due_date
                                    AND    flv.enabled_flag                              = ct_enabled_flag_yes
-- ******************** 2009/09/25 1.6 N.Maeda MOD START ********************* --
--                                    AND    flv.language                                  = USERENV( 'LANG' )
                                    AND    flv.language                                  = ct_user_lang
-- ******************** 2009/09/25 1.6 N.Maeda MOD  END  ********************* --
                                    AND    flv.meaning                                   = hcae.customer_class_code
                                   ) --顧客マスタ.顧客区分 = 1(拠点)
                    AND    xcae.management_base_code = gv_sales_base_code
                                     --顧客顧客アドオン.管理元拠点コード = INパラ拠点コード
             )--消化VD用消化計算ヘッダテーブル.売上拠点コード IN
      AND     xsvdh.customer_number      = NVL( gv_customer_number, xsvdh.customer_number )
      AND     xsvdh.performance_by_code  = papf.employee_number(+)
      AND     xsvdh.digestion_due_date   >= papf.effective_start_date(+)
      AND     xsvdh.digestion_due_date   <= papf.effective_end_date(+)
-- ******************** 2009/10/16 1.7 S.Miyakoshi MOD START ********************* --
--      AND     ( xsvdh.balance_amount      <> cn_amount_zero
--              OR ( xsvdh.ar_sales_amount  = cn_amount_zero
--                 AND xsvdh.sales_amount  = cn_amount_zero
--                 )
--              ) ;
      ;
-- ******************** 2009/10/16 1.7 S.Miyakoshi MOD  END  ********************* --
/* 2011/04/18 Ver1.9 ADD Start */
    CURSOR confirm_data_cur
    IS
      SELECT xsvdh.digestion_due_date             digestion_due_date,               --消化計算締年月日
             xsvdh.sales_base_code                sales_base_code,                  --売上拠点コード
             hpb.party_name                       sales_base_name,                  --拠点名称
             xsvdh.performance_by_code            performance_by_code,              --成績計上者コード
             papf.per_information18               per_information18,                --氏
             papf.per_information19               per_information19,                --名
             xsvdh.customer_number                customer_number,                  --顧客コード
             hpc.party_name                       party_name,                       --顧客名称
             xsvdh.ar_sales_amount                ar_sales_amount,                  --売上金額
             xsvdh.sales_amount                   sales_amount,                     --販売金額
             xsvdh.balance_amount                 balance_amount,                   --差額
             xsvdh.digestion_calc_rate            digestion_calc_rate,              --消化計算掛率
             xsvdh.master_rate                    master_rate,                      --マスタ掛率
             xsvdh.uncalculate_class              uncalculate_class,                --未計算区分
             flv.description                      confirmation_message              --確認メッセージ
       FROM  xxcos_vd_digestion_hdrs              xsvdh,                            --消化VD用消化計算ヘッダテーブル
             hz_cust_accounts                     hcaeb,                            --顧客マスタ_拠点
             hz_parties                           hpb,                              --パーティマスタ_拠点
             hz_cust_accounts                     hcaec,                            --顧客マスタ_顧客
             hz_parties                           hpc,                              --パーティマスタ_顧客
             fnd_lookup_values                    flv,                              --クイックコード値マスタ
             per_all_people_f                     papf                              --従業員マスタ
      WHERE  xsvdh.sales_base_code = hcaeb.account_number
      AND    hcaeb.party_id                       = hpb.party_id
      AND    EXISTS (SELECT flv.meaning meaning
                     FROM   fnd_lookup_values             flv
                     WHERE  flv.lookup_type                               = ct_qct_cust_type
                     AND    flv.lookup_code                               LIKE ct_qcc_cust_type
                     AND    flv.start_date_active                         <= xsvdh.digestion_due_date
                     AND    NVL( flv.end_date_active, gd_max_date )       >= xsvdh.digestion_due_date
                     AND    flv.enabled_flag                              = ct_enabled_flag_yes
                     AND    flv.language                                  = ct_user_lang
                     AND    flv.meaning                                   = hcaeb.customer_class_code
                    ) --顧客マスタ.顧客区分 = 1(拠点)
      AND    xsvdh.cust_account_id                         = hcaec.cust_account_id
      AND    hcaec.party_id                                = hpc.party_id
      AND    flv.lookup_type                               = ct_sct_cust_type
      AND    flv.lookup_code                               = xsvdh.uncalculate_class
      AND    flv.start_date_active                         <= xsvdh.digestion_due_date
      AND    NVL( flv.end_date_active, gd_max_date )       >= xsvdh.digestion_due_date
      AND    flv.language                                  = ct_user_lang
      AND    flv.enabled_flag                              = ct_enabled_flag_yes
      AND    xsvdh.sales_result_creation_flag              = ct_make_flag_yes
      AND    xsvdh.digestion_due_date                      = gd_due_date
      AND    xsvdh.sales_base_code IN(
                    SELECT
                      gv_sales_base_code sales_base_code
                    FROM
                      DUAL
                    UNION
                    SELECT hcae.account_number account_number      --拠点コード
                    FROM   hz_cust_accounts    hcae,
                           xxcmm_cust_accounts xcae
                    WHERE  hcae.cust_account_id = xcae.customer_id --顧客マスタ.顧客ID =顧客アドオン.顧客ID
                    AND    EXISTS (SELECT flv.meaning
                                    FROM   fnd_lookup_values             flv
                                    WHERE  flv.lookup_type                               = ct_qct_cust_type
                                    AND    flv.lookup_code                               LIKE ct_qcc_cust_type
                                    AND    flv.start_date_active                         <= xsvdh.digestion_due_date
                                    AND    NVL( flv.end_date_active, gd_max_date )       >= xsvdh.digestion_due_date
                                    AND    flv.enabled_flag                              = ct_enabled_flag_yes
                                    AND    flv.language                                  = ct_user_lang
                                    AND    flv.meaning                                   = hcae.customer_class_code
                                   ) --顧客マスタ.顧客区分 = 1(拠点)
                    AND    xcae.management_base_code = gv_sales_base_code
                                     --顧客顧客アドオン.管理元拠点コード = INパラ拠点コード
             ) --消化VD用消化計算ヘッダテーブル.売上拠点コード IN
      AND     xsvdh.customer_number      = NVL( gv_customer_number, xsvdh.customer_number )
      AND     xsvdh.performance_by_code  = papf.employee_number(+)
      AND     xsvdh.digestion_due_date   >= papf.effective_start_date(+)
      AND     xsvdh.digestion_due_date   <= papf.effective_end_date(+)
      ;
/* 2011/04/18 Ver1.9 ADD END */
--
    -- *** ローカル・レコード ***
    l_data_rec                          data_cur%ROWTYPE;
/* 2011/04/18 Ver1.9 ADD START */
    l_confirm_data_rec                  confirm_data_cur%ROWTYPE;
/* 2011/04/18 Ver1.9 ADD END   */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_idx      := 0;
--
    --==================================
    -- 1.データ取得
    --==================================
/* 2011/04/18 Ver1.9 ADD START */
    IF ( gd_due_date IS NULL ) THEN
/* 2011/04/18 Ver1.9 ADD END   */
      <<loop_get_data>>
      FOR l_data_rec IN data_cur
      LOOP
        -- レコードIDの取得
        BEGIN
          SELECT
            xxcos_rep_dig_dv_list_s01.NEXTVAL  record_id
          INTO
            ln_record_id
          FROM
            dual
          ;
        END;
        ln_idx                  := ln_idx + 1;
        --
        g_rpt_data_tab(ln_idx).record_id                    := ln_record_id;                     --レコードid
        g_rpt_data_tab(ln_idx).digestion_date               := l_data_rec.digestion_due_date;    --消化計算締年月日
        g_rpt_data_tab(ln_idx).base_code                    := l_data_rec.sales_base_code;       --売上拠点コード
        g_rpt_data_tab(ln_idx).base_name                    := SUBSTRB( l_data_rec.sales_base_name,
                                                            cn_pos_star, cn_base_name_length );  --売上拠点名称
        g_rpt_data_tab(ln_idx).employee_num                 := l_data_rec.performance_by_code;   --営業員コード
        g_rpt_data_tab(ln_idx).employee_name                := SUBSTRB( l_data_rec.per_information18 
                                                            || l_data_rec.per_information19,
                                                            cn_pos_star, cn_employee_name_length );
        g_rpt_data_tab(ln_idx).party_num                    := l_data_rec.customer_number;       --顧客コード
        g_rpt_data_tab(ln_idx).customer_name                := SUBSTRB( l_data_rec.party_name,
                                                            cn_pos_star, cn_party_name_length ); --顧客名称
        g_rpt_data_tab(ln_idx).dlv_invoice_amount           := l_data_rec.ar_sales_amount;       --納品伝票金額
-- ******************** 2009/09/25 1.6 N.Maeda DEL START ********************* --
--      g_rpt_data_tab(ln_idx).digest_sale_amount           := l_data_rec.sales_amount;          --設定掛率金額
--      g_rpt_data_tab(ln_idx).balance                      := l_data_rec.balance_amount;        --差額
-- ******************** 2009/09/25 1.6 N.Maeda DEL  END  ********************* --
-- ******************** 2010/02/23 1.8 K.Aatsushiba MOD START ********************* --
        IF ( l_data_rec.uncalculate_class  IN (  ct_uncalculate_class_normal
                                                ,ct_uncalculate_class_abnormal)) THEN
--      IF ( l_data_rec.uncalculate_class  = ct_uncalculate_class_normal ) THEN
-- ******************** 2010/02/23 1.8 K.Aatsushiba MOD END ********************* --
-- ******************** 2009/09/25 1.6 N.Maeda MOD START ********************* --
          g_rpt_data_tab(ln_idx).account_rate               :=  SUBSTRB( ( TO_CHAR( l_data_rec.digestion_calc_rate, cv_fmt_tax )
                                                                        || cv_pr_tax),1,8);
--        g_rpt_data_tab(ln_idx).account_rate               := TO_CHAR( l_data_rec.digestion_calc_rate, cv_fmt_tax )
--                                                          || cv_pr_tax;
-- ******************** 2009/09/25 1.6 N.Maeda MOD  END  ********************* --
-- ******************** 2009/09/25 1.6 N.Maeda ADD START ********************* --
          g_rpt_data_tab(ln_idx).balance                    := l_data_rec.balance_amount;                --差額
-- ******************** 2009/09/25 1.6 N.Maeda ADD  END  ********************* --
        ELSE
          g_rpt_data_tab(ln_idx).account_rate               := gv_no_add;                         --消化計算掛率
-- ******************** 2009/09/25 1.6 N.Maeda ADD START ********************* --
          g_rpt_data_tab(ln_idx).balance                    := cn_amount_zero;                    --差額
-- ******************** 2009/09/25 1.6 N.Maeda ADD  END  ********************* --
        END IF;
-- ******************** 2009/09/25 1.6 N.Maeda MOD START ********************* --
-- ******************** 2009/09/25 1.6 N.Maeda ADD START ********************* --
        g_rpt_data_tab(ln_idx).digest_sale_amount         := ROUND( l_data_rec.sales_amount 
                                                                      * ( l_data_rec.master_rate / 100 ) ); --設定掛率金額
-- ******************** 2009/09/25 1.6 N.Maeda ADD  END  ********************* --
        g_rpt_data_tab(ln_idx).setting_account_rate         := SUBSTRB( ( TO_CHAR( l_data_rec.master_rate, cv_fmt_tax )
                                                                        || cv_pr_tax ),1,8);
--      g_rpt_data_tab(ln_idx).setting_account_rate         := TO_CHAR( l_data_rec.master_rate, cv_fmt_tax )
--                                                          || cv_pr_tax;
-- ******************** 2009/09/25 1.6 N.Maeda MOD  END  ********************* --
        g_rpt_data_tab(ln_idx).uncalculate_class            := l_data_rec.uncalculate_class;     --未計算区分
        IF ( l_data_rec.uncalculate_class  <> ct_uncalculate_class_normal ) THEN
-- ******************** 2009/09/25 1.6 N.Maeda MOD START ********************* --
          g_rpt_data_tab(ln_idx).confirmation_message       := SUBSTRB(l_data_rec.confirmation_message,1,40);  --確認メッセージ
--        g_rpt_data_tab(ln_idx).confirmation_message       := l_data_rec.confirmation_message;  --確認メッセージ
-- ******************** 2009/09/25 1.6 N.Maeda MOD  END  ********************* --
        END IF;
        g_rpt_data_tab(ln_idx).created_by                   := cn_created_by;
        g_rpt_data_tab(ln_idx).creation_date                := cd_creation_date;
        g_rpt_data_tab(ln_idx).last_updated_by              := cn_last_updated_by;
        g_rpt_data_tab(ln_idx).last_update_date             := cd_last_update_date;
        g_rpt_data_tab(ln_idx).last_update_login            := cn_last_update_login;
        g_rpt_data_tab(ln_idx).request_id                   := cn_request_id;
        g_rpt_data_tab(ln_idx).program_application_id       := cn_program_application_id;
        g_rpt_data_tab(ln_idx).program_id                   := cn_program_id;
        g_rpt_data_tab(ln_idx).program_update_date          := cd_program_update_date;
/* 2011/04/18 Ver1.9 ADD Start */
        g_rpt_data_tab(ln_idx).digestion_due_date           := NULL;
/* 2011/04/18 Ver1.9 ADD END   */
        --
      END LOOP loop_get_data;
/* 2011/04/18 Ver1.9 ADD START */
    ELSE
      <<loop_get_data>>
      FOR l_confirm_data_rec IN confirm_data_cur
      LOOP
        -- レコードIDの取得
        BEGIN
          SELECT
            xxcos_rep_dig_dv_list_s01.NEXTVAL  record_id
          INTO
            ln_record_id
          FROM
            dual
          ;
        END;
        ln_idx                  := ln_idx + 1;
        --
        g_rpt_data_tab(ln_idx).record_id                    := ln_record_id;                             --レコードid
        g_rpt_data_tab(ln_idx).digestion_date               := l_confirm_data_rec.digestion_due_date;    --消化計算締年月日
        g_rpt_data_tab(ln_idx).base_code                    := l_confirm_data_rec.sales_base_code;       --売上拠点コード
        g_rpt_data_tab(ln_idx).base_name                    := SUBSTRB( l_confirm_data_rec.sales_base_name,
                                                            cn_pos_star, cn_base_name_length );          --売上拠点名称
        g_rpt_data_tab(ln_idx).employee_num                 := l_confirm_data_rec.performance_by_code;   --営業員コード
        g_rpt_data_tab(ln_idx).employee_name                := SUBSTRB( l_confirm_data_rec.per_information18 
                                                            || l_confirm_data_rec.per_information19,
                                                            cn_pos_star, cn_employee_name_length );
        g_rpt_data_tab(ln_idx).party_num                    := l_confirm_data_rec.customer_number;       --顧客コード
        g_rpt_data_tab(ln_idx).customer_name                := SUBSTRB( l_confirm_data_rec.party_name,
                                                            cn_pos_star, cn_party_name_length );         --顧客名称
        g_rpt_data_tab(ln_idx).dlv_invoice_amount           := l_confirm_data_rec.ar_sales_amount;       --納品伝票金額
        IF ( l_confirm_data_rec.uncalculate_class  IN (  ct_uncalculate_class_normal
                                                ,ct_uncalculate_class_abnormal)) THEN
          g_rpt_data_tab(ln_idx).account_rate               :=  SUBSTRB( ( TO_CHAR( l_confirm_data_rec.digestion_calc_rate, cv_fmt_tax )
                                                                        || cv_pr_tax),1,8);
          g_rpt_data_tab(ln_idx).balance                    := l_confirm_data_rec.balance_amount;        --差額
        ELSE
          g_rpt_data_tab(ln_idx).account_rate               := gv_no_add;                                --消化計算掛率
          g_rpt_data_tab(ln_idx).balance                    := cn_amount_zero;                           --差額
        END IF;
        g_rpt_data_tab(ln_idx).digest_sale_amount         := ROUND( l_confirm_data_rec.sales_amount 
                                                                      * ( l_confirm_data_rec.master_rate / 100 ) );    --設定掛率金額
        g_rpt_data_tab(ln_idx).setting_account_rate         := SUBSTRB( ( TO_CHAR( l_confirm_data_rec.master_rate, cv_fmt_tax )
                                                                        || cv_pr_tax ),1,8);
        g_rpt_data_tab(ln_idx).uncalculate_class            := l_confirm_data_rec.uncalculate_class;                   --未計算区分
        IF ( l_confirm_data_rec.uncalculate_class  <> ct_uncalculate_class_normal ) THEN
          g_rpt_data_tab(ln_idx).confirmation_message       := SUBSTRB(l_confirm_data_rec.confirmation_message,1,40);  --確認メッセージ
        END IF;
        g_rpt_data_tab(ln_idx).created_by                   := cn_created_by;
        g_rpt_data_tab(ln_idx).creation_date                := cd_creation_date;
        g_rpt_data_tab(ln_idx).last_updated_by              := cn_last_updated_by;
        g_rpt_data_tab(ln_idx).last_update_date             := cd_last_update_date;
        g_rpt_data_tab(ln_idx).last_update_login            := cn_last_update_login;
        g_rpt_data_tab(ln_idx).request_id                   := cn_request_id;
        g_rpt_data_tab(ln_idx).program_application_id       := cn_program_application_id;
        g_rpt_data_tab(ln_idx).program_id                   := cn_program_id;
        g_rpt_data_tab(ln_idx).program_update_date          := cd_program_update_date;
        g_rpt_data_tab(ln_idx).digestion_due_date           := gd_due_date;
        --
      END LOOP loop_get_data;
    END IF;
/* 2011/04/18 Ver1.9 ADD END   */
--
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      NULL;
    ELSE
      --対象件数
      gn_target_cnt           := g_rpt_data_tab.COUNT;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : 帳票ワークテーブル登録(A-3)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- プログラム名
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
    lv_table_name    VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    --==================================
    -- 1.消化VD別掛率チェックリスト帳票ワークテーブル登録処理
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
      FORALL i IN 1..g_rpt_data_tab.COUNT --SAVE EXCEPTIONS
      INSERT INTO
        xxcos_rep_dig_dv_list
      VALUES
        g_rpt_data_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- 正常件数
    gn_normal_cnt           := g_rpt_data_tab.COUNT;
--
  EXCEPTION
    WHEN global_insert_data_expt  THEN
      --テーブル名取得
      lv_table_name         := xxccp_common_pkg.get_msg(
                                 iv_application        => ct_xxcos_appl_short_name,
                                 iv_name               => ct_msg_rpt_wrk_tbl
                               );
      --
      ov_errmsg             := xxccp_common_pkg.get_msg(
                                 iv_application        => ct_xxcos_appl_short_name,
                                 iv_name               => ct_msg_insert_data_err,
                                 iv_token_name1        => cv_tkn_table_name,
                                 iv_token_value1       => lv_table_name,
                                 iv_token_name2        => cv_tkn_key_data,
                                 iv_token_value2       => NULL
                               );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : ＳＶＦ起動(A-4)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- プログラム名
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_api_name      VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.明細0件用メッセージ取得
    --==================================
    lv_nodata_msg             := xxccp_common_pkg.get_msg(
                                   iv_application          => ct_xxcos_appl_short_name,
                                   iv_name                 => ct_msg_nodata_err
                                 );
    --出力ファイル編集
    lv_file_name              := cv_file_id ||
                                   TO_CHAR( SYSDATE, cv_fmt_date8 ) ||
                                   TO_CHAR( cn_request_id ) ||
                                   cv_extension_pdf
                                 ;
    --==================================
    -- 2.SVF起動
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              => lv_retcode,
      ov_errbuf               => lv_errbuf,
      ov_errmsg               => lv_errmsg,
      iv_conc_name            => cv_conc_name,
      iv_file_name            => lv_file_name,
      iv_file_id              => cv_file_id,
      iv_output_mode          => cv_output_mode_pdf,
      iv_frm_file             => cv_frm_file,
      iv_vrq_file             => cv_vrq_file,
      iv_org_id               => NULL,
      iv_user_name            => NULL,
      iv_resp_name            => NULL,
      iv_doc_name             => NULL,
      iv_printer_name         => NULL,
      iv_request_id           => TO_CHAR( cn_request_id ),
      iv_nodata_msg           => lv_nodata_msg,
      iv_svf_param1           => NULL,
      iv_svf_param2           => NULL,
      iv_svf_param3           => NULL,
      iv_svf_param4           => NULL,
      iv_svf_param5           => NULL,
      iv_svf_param6           => NULL,
      iv_svf_param7           => NULL,
      iv_svf_param8           => NULL,
      iv_svf_param9           => NULL,
      iv_svf_param10          => NULL,
      iv_svf_param11          => NULL,
      iv_svf_param12          => NULL,
      iv_svf_param13          => NULL,
      iv_svf_param14          => NULL,
      iv_svf_param15          => NULL
    );
    --
    IF ( lv_retcode  <> cv_status_normal ) THEN
      RAISE global_call_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_call_api_expt  THEN
      lv_api_name             := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_svf_api
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : 帳票ワークテーブル削除(A-5)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- プログラム名
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
    lv_profile_name  VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT
        xrdr.record_id        record_id
      FROM
        xxcos_rep_dig_dv_list    xrdr                 --消化VD別掛率チェックリスト帳票ワークテーブル
      WHERE
        xrdr.request_id       = cn_request_id         --要求ID
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.帳票ワークテーブルデータロック
    --==================================
    BEGIN
      -- ロック用カーソルオープン
      OPEN lock_cur;
      -- ロック用カーソルクローズ
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 2.帳票ワークテーブル削除
    --==================================
    BEGIN
      DELETE FROM
          xxcos_rep_dig_dv_list  xrdr
      WHERE
          xrdr.request_id     =   cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --要求ID文字列取得
        lv_profile_name           := xxccp_common_pkg.get_msg(
                                       iv_application        => ct_xxcos_appl_short_name,
                                       iv_name               => ct_msg_request,
                                       iv_token_name1        => cv_tkn_request,
                                       iv_token_value1       => TO_CHAR( cn_request_id )
                                     );
        --
        RAISE global_delete_data_expt;
    END;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --テーブル名取得
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_delete_data_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --テーブル名取得
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_delete_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_sales_base_code      IN      VARCHAR2,       -- 1.拠点
    iv_customer_number      IN      VARCHAR2,       -- 2.顧客コード
/* 2011/04/18 Ver1.9 ADD Start */
    iv_due_date             IN      VARCHAR2,       -- 3.締日
/* 2011/04/18 Ver1.9 ADD End   */
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
/* 2009/06/19 Ver1.5 Add Start */
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
/* 2009/06/19 Ver1.5 Add End   */

--
--###########################  固定部 END   ####################################
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt             := 0;
    gn_normal_cnt             := 0;
    gn_error_cnt              := 0;
    gn_warn_cnt               := 0;
--
    -- ===============================
    -- A-0  初期処理
    -- ===============================
    init(
      iv_sales_base_code        => iv_sales_base_code,         -- 1.拠点
      iv_customer_number        => iv_customer_number,         -- 2.顧客コード
/* 2011/04/18 Ver1.9 ADD Start */
      iv_due_date               => iv_due_date,                -- 3.締日
/* 2011/04/18 Ver1.9 ADD End   */
      ov_errbuf                 => lv_errbuf,                  -- エラー・メッセージ
      ov_retcode                => lv_retcode,                 -- リターン・コード
      ov_errmsg                 => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode  = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1  パラメータチェック処理
    -- ===============================
    check_parameter(
      ov_errbuf                 => lv_errbuf,                  -- エラー・メッセージ
      ov_retcode                => lv_retcode,                 -- リターン・コード
      ov_errmsg                 => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode  = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  データ取得
    -- ===============================
    get_data(
      ov_errbuf               => lv_errbuf,                -- エラー・メッセージ
      ov_retcode              => lv_retcode,               -- リターン・コード
      ov_errmsg               => lv_errmsg                 -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode  = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  帳票ワークテーブル登録
    -- ===============================
    insert_rpt_wrk_data(
      ov_errbuf               => lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              => lv_retcode,                 -- リターン・コード
      ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode  = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    -- ===============================
    -- A-4  ＳＶＦ起動
    -- ===============================
    execute_svf(
      ov_errbuf               => lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              => lv_retcode,                 -- リターン・コード
      ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
--
/* 2009/06/19 Ver1.5 Mod Start */
--    IF ( lv_retcode  = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
    --エラーでもワークテーブルを削除する為、エラー情報を保持
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
/* 2009/06/19 Ver1.5 Mod End   */
--
    -- ===============================
    -- A-3  帳票ワークテーブル削除
    -- ===============================
    delete_rpt_wrk_data(
      ov_errbuf               => lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              => lv_retcode,                 -- リターン・コード
      ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode  = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
/* 2009/06/19 Ver1.5 Add Start */
    COMMIT;
--
    --SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
/* 2009/06/19 Ver1.5 Add End   */
--
    --明細０件時の警告終了制御
    IF ( g_rpt_data_tab.COUNT  = 0 ) THEN
      ov_retcode  := cv_status_warn;
    END IF;
--
  EXCEPTION
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_sales_base_code      IN      VARCHAR2,       -- 1.拠点
    iv_customer_number      IN      VARCHAR2        -- 2.顧客コード
/* 2011/04/18 Ver1.9 ADD Start */
   ,iv_due_date             IN      VARCHAR2        -- 3.締日
/* 2011/04/18 Ver1.9 ADD End   */
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';  -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';     -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
      iv_which    => cv_log_header_log,
      ov_retcode  => lv_retcode,
      ov_errbuf   => lv_errbuf,
      ov_errmsg   => lv_errmsg
    );
    --
    IF ( lv_retcode  = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_sales_base_code,                -- 1.拠点
      iv_customer_number,                -- 2．顧客コード
/* 2011/04/18 Ver1.9 ADD Start */
      iv_due_date,                       -- 3.締日
/* 2011/04/18 Ver1.9 ADD End   */
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode  <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
      which   => FND_FILE.LOG,
      buff    => NULL
    );
    --対象件数出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_target_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_success_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_error_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_skip_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => NULL
    );
    --終了メッセージ
    IF ( lv_retcode  = cv_status_normal ) THEN
      lv_message_code  := cv_normal_msg;
    ELSIF ( lv_retcode  = cv_status_warn ) THEN
      lv_message_code  := cv_warn_msg;
    ELSIF ( lv_retcode  = cv_status_error ) THEN
      lv_message_code  := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG,
       buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode  = cv_status_error ) THEN
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
END XXCOS004A05R;
/
