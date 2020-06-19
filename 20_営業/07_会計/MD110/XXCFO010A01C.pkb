CREATE OR REPLACE PACKAGE BODY XXCFO010A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO010A01C
 * Description     : 情報系システムへのデータ連携（勘定科目明細）
 * MD.050          : MD050_CFO_010_A01_情報系システムへのデータ連携（勘定科目明細）
 * MD.070          : MD050_CFO_010_A01_情報系システムへのデータ連携（勘定科目明細）
 * Version         : 1.3
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        入力パラメータ値ログ出力処理               (A-1)
 *  get_system_value  P        各種システム値取得処理                     (A-2)
 *  out_data_filename P        勘定科目明細データファイル情報ログ処理     (A-3)
 *  get_account_sum_no_param P 勘定科目明細データ集計(パラメータなし)処理 (A-4)
 *  get_account_sum   P        勘定科目明細データ集計(パラメータあり)処理 (A-5)
 *  put_account_data_file P    勘定科目明細データファイル出力処理         (A-6)
 *  out_no_target     P        0件メッセージ出力処理                      (A-7)
 *  submain           P        メイン処理プロシージャ
 *  main              P        コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-19    1.0  SCS 加藤 忠   初回作成
 *  2009-07-09    1.1  SCS 佐々木    [0000019]パフォーマンス改善
 *  2009-08-04    1.2  SCS 廣瀬      [0000928]パフォーマンス改善
 *  2020-06-19    1.3  SCSK小路      E_本稼動_16432対応
 ************************************************************************/
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO010A01C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';        -- アドオン：マスタ・経理・共通のアプリケーション短縮名
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- アドオン：共通・IF領域のアプリケーション短縮名
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- アドオン：会計・アドオン領域のアプリケーション短縮名
--
  -- メッセージ番号
  cv_msg_010a01_001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004'; --対象データが0件メッセージ
  cv_msg_010a01_002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; --プロファイル取得エラーメッセージ
  cv_msg_010a01_003  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00002'; --ファイル名出力メッセージ
  cv_msg_010a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015'; --処理日取得エラーメッセージ
  cv_msg_010a01_005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027'; --ファイルが存在しているメッセージ
  cv_msg_010a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00028'; --ファイルの場所が無効メッセージ
  cv_msg_010a01_007  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029'; --ファイルをオープンできないメッセージ
  cv_msg_010a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030'; --ファイルに書込みできないメッセージ
  cv_msg_010a01_009  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00032'; --データ取得エラーメッセージ
-- == 2020/06/19 V1.3 Added START   ===============================================================
  cv_msg_010a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-50004'; --企業コードスキップメッセージ
-- == 2020/06/19 V1.3 Added END     ===============================================================
--
  -- トークン
  cv_tkn_prof             CONSTANT VARCHAR2(20) := 'PROF_NAME';                   -- プロファイル名
  cv_tkn_file             CONSTANT VARCHAR2(20) := 'FILE_NAME';                   -- ファイル名
  cv_tkn_data             CONSTANT VARCHAR2(20) := 'DATA';                        -- エラーデータの説明
--
  -- 日本語辞書
  cv_dict_aplid_sqlgl     CONSTANT VARCHAR2(100) := 'CFO000A00001';               -- "アプリケーションID：SQLGL"
--
  -- プロファイル
  cv_data_filepath        CONSTANT VARCHAR2(40) := 'XXCFO1_ACCOUNT_SUMMARY_DATA_FILEPATH'; -- XXCFO:勘定科目明細データファイル格納パス
  cv_data_filename        CONSTANT VARCHAR2(40) := 'XXCFO1_ACCOUNT_SUMMARY_DATA_FILENAME'; -- XXCFO:勘定科目別データファイル名
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';            -- 会計帳簿ID
--
  -- アプリケーション短縮名
  cv_appl_shrt_name_gl    CONSTANT fnd_application.application_short_name%TYPE := 'SQLGL'; -- アプリケーション短縮名(一般会計)
--
  -- クイックコードタイプ
  cv_type_sales_source    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFO1_SALES_SOURCE'; -- 売上仕訳ソース名
--
  cv_account_type_e       CONSTANT gl_code_combinations.account_type%TYPE := 'E'; -- 勘定科目タイプ(費用)
  cv_account_type_r       CONSTANT gl_code_combinations.account_type%TYPE := 'R'; -- 勘定科目タイプ(収益)
  cv_actual_flag_a        CONSTANT gl_je_headers.actual_flag%TYPE := 'A';         -- 実績フラグ(実績)
  cv_status_p             CONSTANT gl_je_headers.status%TYPE := 'P';              -- 仕訳ステータス(転記済)
  cv_currency_code        CONSTANT gl_je_headers.currency_code%TYPE := 'JPY';     -- 通貨コード(円)
  cv_enabled_flag_y       CONSTANT fnd_lookup_values.enabled_flag%TYPE := 'Y';    -- 有効フラグ(有効)
  cv_closing_status_o     CONSTANT gl_period_statuses.closing_status%TYPE := 'O'; -- 会計期間のステータス(オープン)
  cv_closing_status_c     CONSTANT gl_period_statuses.closing_status%TYPE := 'C'; -- 会計期間のステータス(クローズ)
--
  -- 勘定科目明細データファイルの連携日付
  cv_put_file_date        CONSTANT VARCHAR2(14) := TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS');
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         -- ログ出力
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 勘定科目明細データ配列
  TYPE g_segment1_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_effective_date_ttype   IS TABLE OF VARCHAR2(8)
                                            INDEX BY PLS_INTEGER;
  TYPE g_segment2_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_segment3_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_segment4_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_segment5_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_segment6_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_attribute1_ttype       IS TABLE OF fnd_lookup_values.attribute1%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_entered_sum_ttype      IS TABLE OF NUMBER
                                            INDEX BY PLS_INTEGER;
  gt_segment1                   g_segment1_ttype;                     -- セグメント1(会社)
  gt_effective_date             g_effective_date_ttype;               -- 仕訳計上日
  gt_segment2                   g_segment2_ttype;                     -- セグメント2(部門)
  gt_segment3                   g_segment3_ttype;                     -- セグメント3(勘定科目)
  gt_segment4                   g_segment4_ttype;                     -- セグメント4(補助科目)
  gt_segment5                   g_segment5_ttype;                     -- セグメント5(顧客)
  gt_segment6                   g_segment6_ttype;                     -- セグメント6(企業)
  gt_attribute1                 g_attribute1_ttype;                   -- 通常・実績振替区分
  gt_entered_sum                g_entered_sum_ttype;                  -- 金額
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_data_filepath        VARCHAR2(500);                              -- XXCFO:勘定科目明細データファイル格納パス
  gv_data_filename        VARCHAR2(100);                              -- XXCFO:勘定科目別データファイル名
  gn_set_of_bks_id        NUMBER;                                     -- 会計帳簿ID
  gd_operation_date       DATE;                                       -- 処理日
  gn_appl_id_gl           fnd_application.application_id%TYPE;        -- アプリケーションID(一般会計)
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_period_name  IN  VARCHAR2,     --   会計期間
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
       iv_which        => cv_file_type_out     -- メッセージ出力
      ,iv_conc_param1  => iv_period_name       -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log     -- ログ出力
      ,iv_conc_param1  => iv_period_name       -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_system_value
   * Description      : 各種システム値取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_system_value(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_system_value'; -- プログラム名
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
    -- プロファイルからXXCFO:勘定科目明細データファイル格納パス
    gv_data_filepath := FND_PROFILE.VALUE( cv_data_filepath );
    -- 取得エラー時
    IF ( gv_data_filepath IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a01_002 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_data_filepath ))
                                                                       -- XXCFO:勘定科目明細データファイル格納パス
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFO:勘定科目別データファイル名
    gv_data_filename := FND_PROFILE.VALUE( cv_data_filename );
    -- 取得エラー時
    IF ( gv_data_filename IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a01_002 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_data_filename ))
                                                                       -- XXCFO:勘定科目別データファイル名
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからGL会計帳簿ID取得
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- 取得エラー時
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a01_002 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                       -- GL会計帳簿ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 業務処理日付取得処理
    gd_operation_date := xxccp_common_pkg2.get_process_date;
    -- 取得結果がNULLならばエラー
    IF ( gd_operation_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                    ,cv_msg_010a01_004 ) -- 処理日取得エラー
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「一般会計」のアプリケーションIDを取得
    gn_appl_id_gl := xxccp_common_pkg.get_application( cv_appl_shrt_name_gl );
    -- 取得結果がNULLならばエラー
    IF ( gn_appl_id_gl IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a01_009 -- データ取得エラー
                                                    ,cv_tkn_data       -- トークン'DATA'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_aplid_sqlgl 
                                                     ))
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
  END get_system_value;
--
  /**********************************************************************************
   * Procedure Name   : out_data_filename
   * Description      : 勘定科目明細データファイル情報ログ処理(A-3)
   ***********************************************************************************/
  PROCEDURE out_data_filename(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_data_filename'; -- プログラム名
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
    -- ファイル名出力メッセージ
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                  ,cv_msg_010a01_003
                                                  ,cv_tkn_file       -- トークン'FILE_NAME'
                                                  ,gv_data_filename) -- 勘定科目明細データファイル名
                                                 ,1
                                                 ,5000);
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg --ユーザー・エラーメッセージ
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
  END out_data_filename;
--
  /**********************************************************************************
   * Procedure Name   : get_account_sum_no_param
   * Description      : 勘定科目明細データ集計(パラメータなし)処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_account_sum_no_param(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_account_sum_no_param'; -- プログラム名
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
    -- 勘定科目明細データ抽出
    CURSOR get_account_sum_no_param_cur
    IS
-- == 2009/08/04 V1.2 Modified START ===============================================================
--      SELECT glcc.segment1                             segment1,
      SELECT /*+ ORDERED
                 USE_NL(inlv1.glps1 gljh gljl gsob glcc gljs fnss)
                 INDEX(gljh GL_JE_HEADERS_N2)
                 INDEX(gsob GL_SETS_OF_BOOKS_U2)
                 INDEX(gljl GL_JE_LINES_U1 )
                 INDEX(glcc GL_CODE_COMBINATIONS_U1)
                 INDEX(gljs GL_JE_SOURCES_TL_U1)
             */
             glcc.segment1                             segment1,
-- == 2009/08/04 V1.2 Modified END   ===============================================================
             TO_CHAR( gljl.effective_date,'YYYYMMDD' ) effective_date,
             glcc.segment2                             segment2,
             glcc.segment3                             segment3,
             glcc.segment4                             segment4,
             glcc.segment5                             segment5,
             glcc.segment6                             segment6,
             DECODE(glcc.account_type,cv_account_type_r,fnss.attribute1,NULL)   attribute1,
             SUM(DECODE( glcc.account_type,cv_account_type_e,
                          NVL( gljl.entered_dr,0 ) - NVL( gljl.entered_cr,0 ),
                          NVL( gljl.entered_cr,0 ) - NVL( gljl.entered_dr,0 ))) entered_sum
-- == 2009/08/04 V1.2 Modified START ===============================================================
--      FROM gl_je_sources        gljs,
--           gl_je_headers        gljh,
--           gl_je_lines          gljl,
--           gl_code_combinations glcc,
--           fnd_lookup_values    fnss, -- クイックコード(売上仕訳ソース)
---- == 2009/07/09 V1.1 Modified START ===============================================================
----           ( SELECT glps1.period_name period_name
----             FROM   gl_period_statuses glps1
----             WHERE EXISTS (
----                   SELECT 'X'
----                   FROM ( SELECT TRUNC( glps2.start_date,'MM' ) start_date,
----                                 LAST_DAY( glps2.end_date )     end_date
----                          FROM gl_period_statuses glps2
----                          WHERE glps2.set_of_books_id = gn_set_of_bks_id
----                            AND glps2.application_id  = gn_appl_id_gl
----                            AND glps2.closing_status  = cv_closing_status_o
----                          UNION ALL
----                          SELECT TRUNC( glps3.start_date,'MM' ) start_date,
----                                 LAST_DAY( glps3.end_date )     end_date
----                          FROM gl_period_statuses glps3
----                          WHERE glps3.set_of_books_id  = gn_set_of_bks_id
----                            AND glps3.application_id   = gn_appl_id_gl
----                            AND glps3.closing_status   = cv_closing_status_c
----                            AND glps3.last_update_date >= gd_operation_date
----                        ) inlv2
----                   WHERE glps1.set_of_books_id = gn_set_of_bks_id
----                     AND glps1.application_id  = gn_appl_id_gl
----                     AND glps1.start_date      BETWEEN inlv2.start_date AND inlv2.end_date
----                   )
----           ) inlv1  -- 対象会計期間
--           (SELECT  glps1.period_name period_name
--            FROM    gl_period_statuses glps1
--                   ,(SELECT   TRUNC( glps2.start_date,'MM' )  start_date,
--                              LAST_DAY( glps2.end_date )      end_date
--                     FROM     gl_period_statuses glps2
--                     WHERE    glps2.set_of_books_id   = gn_set_of_bks_id
--                     AND      glps2.application_id    = gn_appl_id_gl
--                     AND      glps2.closing_status    = cv_closing_status_o
--                     UNION
--                     SELECT   TRUNC( glps3.start_date,'MM' )  start_date,
--                              LAST_DAY( glps3.end_date )      end_date
--                     FROM     gl_period_statuses glps3
--                     WHERE    glps3.set_of_books_id   = gn_set_of_bks_id
--                     AND      glps3.application_id    = gn_appl_id_gl
--                     AND      glps3.closing_status    = cv_closing_status_c
--                     AND      glps3.last_update_date >= gd_operation_date
--                    )         temp
--            WHERE   glps1.start_date BETWEEN temp.start_date AND temp.end_date
--            AND     glps1.set_of_books_id   =   gn_set_of_bks_id
--            AND     glps1.application_id    =   gn_appl_id_gl
--           )                    inlv1 -- 対象会計期間
---- == 2009/07/09 V1.1 Modified END   ===============================================================
---- == 2009/07/09 V1.1 Added START ===============================================================
--          ,gl_sets_of_books     gsob
---- == 2009/07/09 V1.1 Added END   ===============================================================
      FROM (SELECT  /*+ USE_NL(glps1 temp) 
                        INDEX(glps1 XX03_GL_PERIOD_STATUSES_N2)
                    */
                    glps1.period_name period_name
            FROM    gl_period_statuses glps1
                   ,(SELECT   /*+ INDEX(glps2 GL_PERIOD_STATUSES_U2) */
                              TRUNC( glps2.start_date,'MM' )  start_date,
                              LAST_DAY( glps2.end_date )      end_date
                     FROM     gl_period_statuses glps2
                     WHERE    glps2.set_of_books_id   = gn_set_of_bks_id
                     AND      glps2.application_id    = gn_appl_id_gl
                     AND      glps2.closing_status    = cv_closing_status_o
                     UNION
                     SELECT   TRUNC( glps3.start_date,'MM' )  start_date,
                              LAST_DAY( glps3.end_date )      end_date
                     FROM     gl_period_statuses glps3
                     WHERE    glps3.set_of_books_id   = gn_set_of_bks_id
                     AND      glps3.application_id    = gn_appl_id_gl
                     AND      glps3.closing_status    = cv_closing_status_c
                     AND      glps3.last_update_date >= gd_operation_date
                    )         temp
            WHERE   glps1.start_date BETWEEN temp.start_date AND temp.end_date
            AND     glps1.set_of_books_id   =   gn_set_of_bks_id
            AND     glps1.application_id    =   gn_appl_id_gl
           )                    inlv1, -- 対象会計期間
           gl_je_headers        gljh,
           gl_je_lines          gljl,
           gl_sets_of_books     gsob,
           gl_code_combinations glcc,
           gl_je_sources        gljs,
           fnd_lookup_values    fnss  -- クイックコード(売上仕訳ソース)
-- == 2009/08/04 V1.2 Modified END   ===============================================================
      WHERE gljh.set_of_books_id        = gn_set_of_bks_id
        AND gljh.actual_flag            = cv_actual_flag_a
        AND gljh.status                 = cv_status_p
        AND gljh.currency_code          = cv_currency_code
        AND gljh.period_name            = inlv1.period_name
        AND gljh.je_source              = gljs.je_source_name
        AND fnss.lookup_type(+)         = cv_type_sales_source
        AND fnss.language(+)            = USERENV( 'LANG' )
        AND fnss.enabled_flag(+)        = cv_enabled_flag_y
        AND NVL( fnss.start_date_active(+), gd_operation_date ) <= gd_operation_date
        AND NVL( fnss.end_date_active(+),   gd_operation_date ) >= gd_operation_date
        AND gljs.user_je_source_name    = fnss.lookup_code(+)
        AND gljl.je_header_id           = gljh.je_header_id
        AND glcc.account_type        IN ( cv_account_type_e,
                                          cv_account_type_r )
        AND glcc.code_combination_id    = gljl.code_combination_id
-- == 2009/07/09 V1.1 Added START ===============================================================
        AND glcc.chart_of_accounts_id   =   gsob.chart_of_accounts_id
        AND gsob.set_of_books_id        =   gn_set_of_bks_id
        AND gljl.period_name            =   inlv1.period_name
-- == 2009/07/09 V1.1 Added END   ===============================================================
      GROUP BY glcc.segment1,
               TO_CHAR( gljl.effective_date,'YYYYMMDD' ),
               glcc.segment2,
               glcc.segment3,
               glcc.segment4,
               glcc.segment5,
               glcc.segment6,
               DECODE(glcc.account_type,cv_account_type_r,fnss.attribute1,NULL)
      ORDER BY glcc.segment1,
               TO_CHAR( gljl.effective_date,'YYYYMMDD' ),
               glcc.segment2,
               glcc.segment3,
               glcc.segment4,
               glcc.segment5,
               glcc.segment6,
               DECODE(glcc.account_type,cv_account_type_r,fnss.attribute1,NULL)
    ;
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
    -- カーソルオープン
    OPEN get_account_sum_no_param_cur;
--
    -- データの一括取得
    FETCH get_account_sum_no_param_cur BULK COLLECT INTO
          gt_segment1,
          gt_effective_date,
          gt_segment2,
          gt_segment3,
          gt_segment4,
          gt_segment5,
          gt_segment6,
          gt_attribute1,
          gt_entered_sum;
--
    -- 対象件数のセット
    gn_target_cnt := gt_segment1.COUNT;
--
    -- カーソルクローズ
    CLOSE get_account_sum_no_param_cur;
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
  END get_account_sum_no_param;
--
  /**********************************************************************************
   * Procedure Name   : get_account_sum
   * Description      : 勘定科目明細データ集計(パラメータあり)処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_account_sum(
    iv_period_name  IN  VARCHAR2,     --   会計期間
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_account_sum'; -- プログラム名
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
    -- 勘定科目明細データ抽出
    CURSOR get_account_sum_cur
    IS
-- == 2009/08/04 V1.2 Modified START ===============================================================
--      SELECT glcc.segment1                             segment1,
      SELECT /*+ ORDERED
                 USE_NL(inlv1.glps1 gljh gljl glcc gljs fnss)
                 INDEX(gljh GL_JE_HEADERS_N2)
                 INDEX(gljl GL_JE_LINES_U1 )
                 INDEX(glcc GL_CODE_COMBINATIONS_U1)
                 INDEX(gljs GL_JE_SOURCES_TL_U1)
             */
             glcc.segment1                             segment1,
-- == 2009/08/04 V1.2 Modified END   ===============================================================
             TO_CHAR( gljl.effective_date,'YYYYMMDD' ) effective_date,
             glcc.segment2                             segment2,
             glcc.segment3                             segment3,
             glcc.segment4                             segment4,
             glcc.segment5                             segment5,
             glcc.segment6                             segment6,
             DECODE(glcc.account_type,cv_account_type_r,fnss.attribute1,NULL)   attribute1,
             SUM(DECODE( glcc.account_type,cv_account_type_e,
                          NVL( gljl.entered_dr,0 ) - NVL( gljl.entered_cr,0 ),
                          NVL( gljl.entered_cr,0 ) - NVL( gljl.entered_dr,0 ))) entered_sum
-- == 2009/08/04 V1.2 Modified START ===============================================================
--      FROM gl_je_sources        gljs,
--           gl_je_headers        gljh,
--           gl_je_lines          gljl,
--           gl_code_combinations glcc,
--           fnd_lookup_values    fnss, -- クイックコード(売上仕訳ソース)
--           (SELECT  glps1.period_name period_name
--             FROM gl_period_statuses glps1
--             WHERE EXISTS (
--                   SELECT 'X'
--                   FROM ( SELECT TRUNC( glps2.start_date,'MM' ) start_date,
--                                 LAST_DAY( glps2.end_date )     end_date
--                          FROM gl_period_statuses glps2
--                          WHERE glps2.set_of_books_id = gn_set_of_bks_id
--                            AND glps2.application_id  = gn_appl_id_gl
--                            AND glps2.period_name     = iv_period_name
--                        ) inlv2
--                   WHERE glps1.set_of_books_id = gn_set_of_bks_id
--                     AND glps1.application_id  = gn_appl_id_gl
--                     AND glps1.start_date      BETWEEN inlv2.start_date AND inlv2.end_date
--                   )
--           ) inlv1  -- 対象会計期間
      FROM (SELECT  /*+ USE_NL(glps1 temp) 
                        INDEX(glps1 XX03_GL_PERIOD_STATUSES_N2)
                    */
                    glps1.period_name period_name
            FROM    gl_period_statuses glps1
                   ,(SELECT /*+ INDEX(glps2 GL_PERIOD_STATUSES_U1) */
                            TRUNC( glps2.start_date,'MM' ) start_date,
                            LAST_DAY( glps2.end_date )     end_date
                     FROM   gl_period_statuses glps2
                     WHERE  glps2.set_of_books_id = gn_set_of_bks_id
                       AND  glps2.application_id  = gn_appl_id_gl
                       AND  glps2.period_name     = iv_period_name
                    )                  temp
            WHERE   glps1.start_date BETWEEN temp.start_date AND temp.end_date
            AND     glps1.set_of_books_id   =   gn_set_of_bks_id
            AND     glps1.application_id    =   gn_appl_id_gl
           )                    inlv1,  -- 対象会計期間
           gl_je_headers        gljh,
           gl_je_lines          gljl,
           gl_code_combinations glcc,
           gl_je_sources        gljs,
           fnd_lookup_values    fnss    -- クイックコード(売上仕訳ソース)
-- == 2009/08/04 V1.2 Modified END   ===============================================================
      WHERE gljh.set_of_books_id     = gn_set_of_bks_id
        AND gljh.actual_flag         = cv_actual_flag_a
        AND gljh.status              = cv_status_p
        AND gljh.currency_code       = cv_currency_code
        AND gljh.period_name         = inlv1.period_name
        AND gljh.je_source           = gljs.je_source_name
        AND fnss.lookup_type(+)      = cv_type_sales_source
        AND fnss.language(+)         = USERENV( 'LANG' )
        AND fnss.enabled_flag(+)     = cv_enabled_flag_y
        AND NVL( fnss.start_date_active(+), gd_operation_date ) <= gd_operation_date
        AND NVL( fnss.end_date_active(+), gd_operation_date )   >= gd_operation_date
        AND gljs.user_je_source_name = fnss.lookup_code(+)
        AND gljl.je_header_id        = gljh.je_header_id
        AND glcc.account_type        IN ( cv_account_type_e,
                                          cv_account_type_r )
        AND glcc.code_combination_id = gljl.code_combination_id
      GROUP BY glcc.segment1,
               TO_CHAR( gljl.effective_date,'YYYYMMDD' ),
               glcc.segment2,
               glcc.segment3,
               glcc.segment4,
               glcc.segment5,
               glcc.segment6,
               DECODE(glcc.account_type,cv_account_type_r,fnss.attribute1,NULL)
      ORDER BY glcc.segment1,
               TO_CHAR( gljl.effective_date,'YYYYMMDD' ),
               glcc.segment2,
               glcc.segment3,
               glcc.segment4,
               glcc.segment5,
               glcc.segment6,
               DECODE(glcc.account_type,cv_account_type_r,fnss.attribute1,NULL)
    ;
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
    -- カーソルオープン
    OPEN get_account_sum_cur;
--
    -- データの一括取得
    FETCH get_account_sum_cur BULK COLLECT INTO
          gt_segment1,
          gt_effective_date,
          gt_segment2,
          gt_segment3,
          gt_segment4,
          gt_segment5,
          gt_segment6,
          gt_attribute1,
          gt_entered_sum;
--
    -- 対象件数のセット
    gn_target_cnt := gt_segment1.COUNT;
--
    -- カーソルクローズ
    CLOSE get_account_sum_cur;
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
  END get_account_sum;
--
  /**********************************************************************************
   * Procedure Name   : put_account_data_file
   * Description      : 勘定科目明細データファイル出力処理(A-6)
   ***********************************************************************************/
  PROCEDURE put_account_data_file(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_account_data_file'; -- プログラム名
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
    cv_open_mode_w    CONSTANT VARCHAR2(1)  := 'w';     -- ファイルオープンモード（上書き）
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';     -- CSV区切り文字
    cv_enclosed       CONSTANT VARCHAR2(1)  := '"';     -- 単語囲み文字
--
    -- *** ローカル変数 ***
    ln_normal_cnt   NUMBER;         -- 正常件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    -- ファイル出力関連
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- ファイル・ハンドルの宣言
    lv_csv_text         VARCHAR2(32000) ;       -- 出力１行分文字列変数
    lb_fexists          BOOLEAN;                -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                 -- ファイルの長さ
    ln_block_size       NUMBER;                 -- ファイルシステムのブロックサイズ
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
    -- ローカル変数の初期化
    ln_normal_cnt := 0;
--
    -- ====================================================
    -- ＵＴＬファイル存在チェック
    -- ====================================================
    UTL_FILE.FGETATTR( gv_data_filepath,
                       gv_data_filename,
                       lb_fexists,
                       ln_file_size,
                       ln_block_size );
--
    -- 前回ファイルが存在している
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a01_005 -- ファイルが存在している
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_data_filepath
                       ,gv_data_filename
                       ,cv_open_mode_w
                      ) ;
--
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
    <<out_loop>>
    FOR ln_loop_cnt IN gt_segment1.FIRST..gt_segment1.LAST LOOP
--
-- == 2020/06/19 V1.3 Modified START ===============================================================
--      -- 出力文字列作成
--      lv_csv_text := cv_enclosed || gt_segment1( ln_loop_cnt )   || cv_enclosed || cv_delimiter
--                  || gt_effective_date( ln_loop_cnt )                           || cv_delimiter
--                  || cv_enclosed || gt_segment2( ln_loop_cnt )   || cv_enclosed || cv_delimiter
--                  || cv_enclosed || gt_segment3( ln_loop_cnt )   || cv_enclosed || cv_delimiter
--                  || cv_enclosed || gt_segment4( ln_loop_cnt )   || cv_enclosed || cv_delimiter
--                  || cv_enclosed || gt_segment5( ln_loop_cnt )   || cv_enclosed || cv_delimiter
--                  || cv_enclosed || gt_segment6( ln_loop_cnt )   || cv_enclosed || cv_delimiter
--                  || TO_CHAR( gt_entered_sum( ln_loop_cnt ))                    || cv_delimiter
--                  || cv_enclosed || gt_attribute1( ln_loop_cnt ) || cv_enclosed || cv_delimiter
--                  || cv_put_file_date
--      ;
----
--      -- ====================================================
--      -- ファイル書き込み
--      -- ====================================================
--      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
--      -- ====================================================
--      -- 処理件数カウントアップ
--      -- ====================================================
--      ln_normal_cnt := ln_normal_cnt + 1 ;
      -- 企業コードが6桁以外の場合
      IF (length(gt_segment6( ln_loop_cnt )) <> 6 ) THEN
        -- 
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfo
                        ,iv_name         => cv_msg_010a01_010
                        ,iv_token_name1  => cv_tkn_data
                        ,iv_token_value1 => gt_segment6( ln_loop_cnt )
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
--
        ov_retcode := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
--
      ELSE
        -- 出力文字列作成
        lv_csv_text := cv_enclosed || gt_segment1( ln_loop_cnt )   || cv_enclosed || cv_delimiter
                    || gt_effective_date( ln_loop_cnt )                           || cv_delimiter
                    || cv_enclosed || gt_segment2( ln_loop_cnt )   || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_segment3( ln_loop_cnt )   || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_segment4( ln_loop_cnt )   || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_segment5( ln_loop_cnt )   || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_segment6( ln_loop_cnt )   || cv_enclosed || cv_delimiter
                    || TO_CHAR( gt_entered_sum( ln_loop_cnt ))                    || cv_delimiter
                    || cv_enclosed || gt_attribute1( ln_loop_cnt ) || cv_enclosed || cv_delimiter
                    || cv_put_file_date
        ;
--
        -- ====================================================
        -- ファイル書き込み
        -- ====================================================
        UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
        -- ====================================================
        -- 処理件数カウントアップ
        -- ====================================================
        ln_normal_cnt := ln_normal_cnt + 1 ;
--
      END IF;
-- == 2020/06/19 V1.3 Modified END   ===============================================================
--
    END LOOP out_loop;
--
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
    gn_normal_cnt := ln_normal_cnt;
--
  EXCEPTION
--
    -- *** ファイルの場所が無効です ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a01_006 -- ファイルの場所が無効
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 要求どおりにファイルをオープンできないか、または操作できません ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a01_007 -- ファイルをオープンできない
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 書込み操作中にオペレーティング・システムのエラーが発生しました ***
    WHEN UTL_FILE.WRITE_ERROR THEN
      --↓ファイルクローズ関数を追加
      IF ( UTL_FILE.IS_OPEN ( lf_file_hand )) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      gn_normal_cnt := ln_normal_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_010a01_008 -- ファイルに書込みできない
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_account_data_file;
--
  /**********************************************************************************
   * Procedure Name   : out_no_target
   * Description      : 0件メッセージ出力処理(A-7)
   ***********************************************************************************/
  PROCEDURE out_no_target(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_no_target'; -- プログラム名
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
    -- 対象データが0件メッセージ
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                  ,cv_msg_010a01_001)
                                                 ,1
                                                 ,5000);
    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
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
  END out_no_target;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     --   会計期間
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- PL/SQL表の初期化
    gt_segment1.DELETE;         -- セグメント1(会社)
    gt_effective_date.DELETE;   -- 仕訳計上日
    gt_segment2.DELETE;         -- セグメント2(部門)
    gt_segment3.DELETE;         -- セグメント3(勘定科目)
    gt_segment4.DELETE;         -- セグメント4(補助科目)
    gt_segment5.DELETE;         -- セグメント5(顧客)
    gt_segment6.DELETE;         -- セグメント6(企業)
    gt_attribute1.DELETE;       -- 通常・実績振替区分
    gt_entered_sum.DELETE;      -- 金額
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  入力パラメータ値ログ出力処理(A-1)
    -- =====================================================
    init(
       iv_period_name        -- 会計期間
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  各種システム値取得処理(A-2)
    -- =====================================================
    get_system_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  勘定科目明細データファイル情報ログ処理(A-3)
    -- =====================================================
    out_data_filename(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    IF ( iv_period_name IS NULL ) THEN
--
      -- オープン会計期間の実績仕訳データと、会計期間をクローズした当日の実績仕訳データが連携対象
      -- =====================================================
      --  勘定科目明細データ集計(パラメータなし)処理(A-4)
      -- =====================================================
      get_account_sum_no_param(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
    ELSE
--
      -- コンカレントパラメータ会計期間の実績仕訳データが連携対象
      -- =====================================================
      --  勘定科目明細データ集計(パラメータあり)処理(A-5)
      -- =====================================================
      get_account_sum(
         iv_period_name        -- 会計期間
        ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    IF ( gn_target_cnt > 0 ) THEN
--
      -- =====================================================
      --  勘定科目明細データファイル出力処理(A-6)
      -- =====================================================
      put_account_data_file(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
-- == 2020/06/19 V1.3 Added START   ===============================================================
      ov_retcode := lv_retcode;
-- == 2020/06/19 V1.3 Added END     ===============================================================
--
    ELSE
--
      -- =====================================================
      --  0件メッセージ出力処理(A-7)
      -- =====================================================
      out_no_target(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
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
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_period_name  IN  VARCHAR2       --   会計期間
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
       iv_period_name   -- 会計期間
      ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,lv_retcode       -- リターン・コード             --# 固定 #
      ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 会計チーム標準：異常終了時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
-- == 2020/06/19 V1.3 Added START   ===============================================================
      gn_warn_cnt   := 0;
-- == 2020/06/19 V1.3 Added END     ===============================================================
      gn_error_cnt  := 1;
    END IF;
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
-- == 2020/06/19 V1.3 Added START   ===============================================================
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
-- == 2020/06/19 V1.3 Added END     ===============================================================
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
END XXCFO010A01C;
/
