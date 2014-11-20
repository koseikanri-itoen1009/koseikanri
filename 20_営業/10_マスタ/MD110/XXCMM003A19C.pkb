CREATE OR REPLACE PACKAGE BODY XXCMM003A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A19C(body)
 * Description      : HHT連携IFデータ作成
 * MD.050           : MD050_CMM_003_A19_HHT系連携IFデータ作成
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  file_open              ファイルオープン処理(A-2)
 *  output_cust_data       処理対象データ抽出処理(A-3)・抽出情報出力処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-5 終了処理)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/24    1.0   Takuya Kaihara   新規作成
 *  2009/03/09    1.1   Takuya Kaihara   プロファイル値共通化
 *  2009/04/13    1.2   Yutaka.Kuboshima 障害T1_0499,T1_0509の対応
 *  2009/04/28    1.3   Yutaka.Kuboshima 障害T1_0831の対応
 *  2009/06/09    1.4   Yutaka.Kuboshima 障害T1_1364の対応
 *  2009/08/24    1.5   Yutaka.Kuboshima 統合テスト障害0000487の対応
 *  2009/11/23    1.6   Yutaka.Kuboshima 障害E_本番_00329の対応
 *  2009/12/06    1.7   Yutaka.Kuboshima 障害E_本稼動_00327の対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  gv_xxcmm_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMM'; --メッセージ区分
  gv_xxccp_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCCP'; --メッセージ区分
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_out_file_dir  VARCHAR2(100);
  gv_out_file_file VARCHAR2(100);
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
  init_err_expt                  EXCEPTION; --初期処理エラー
  fopen_err_expt                 EXCEPTION; --ファイルオープンエラー
  no_date_expt                   EXCEPTION; --対象データ0件
  fclose_err_expt                EXCEPTION; --ファイルクローズエラー
  write_failure_expt             EXCEPTION; --CSVデータ出力エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A19C';                 --パッケージ名
  cv_comma                   CONSTANT VARCHAR2(2)   := ',';
  cv_dqu                     CONSTANT VARCHAR2(2)   := '"';                            --文字列括り
  cv_date_null               CONSTANT VARCHAR2(2)   := '';                             --空文字
  cv_hur_sps                 CONSTANT VARCHAR2(2)   := ' ';                            --半角スペース
  cv_hur_sls                 CONSTANT VARCHAR2(2)   := '/';                            --半角スラッシュ
--
  cv_fnd_month               CONSTANT VARCHAR2(10)  := 'YYYYMM';                       --日付書式(MONTH)
  cv_fnd_date                CONSTANT VARCHAR2(10)  := 'YYYYMMDD';                     --日付書式
  cv_fnd_slash_date          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                   --日付書式(YYYY/MM/DD)
  cv_fnd_sytem_date          CONSTANT VARCHAR2(25)  := 'YYYY/MM/DD HH24:MI:SS';        --システム日付
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
  cv_fnd_max_date            CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';             --日付書式(年月日時分秒)
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
  cv_trunc_dd                CONSTANT VARCHAR2(2)   := 'DD';                           --日付書式(DD)
  cv_trunc_mm                CONSTANT VARCHAR2(2)   := 'MM';                           --日付書式(MM)
  cv_proc_date_from          CONSTANT VARCHAR2(50)  := '最終更新日（開始）';           --最終更新日（開始）
  cv_proc_date_to            CONSTANT VARCHAR2(50)  := '最終更新日（終了）';           --最終更新日（終了）
--
  --メッセージ
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';             --ファイル名ノート
  cv_parameter_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00038';             --入力パラメータノート
  cv_no_data_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00301';             --対象データ無し
--
  --エラーメッセージ
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';             --プロファイル取得エラー
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';             --ファイルパス不正エラー
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';             --CSVデータ出力エラー
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
  cv_exist_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';             --CSVファイル存在チェック
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
  cv_emsg_file_close         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';             --ファイルクローズエラー
  cv_term_spec_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00343';             --期間指定エラー
  --トークン
  cv_ng_profile              CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                   --プロファイル取得失敗トークン
  cv_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';                    --ファイル名トークン
  cv_ng_word                 CONSTANT VARCHAR2(7)   := 'NG_WORD';                      --CSV出力エラートークン・NG_WORD
  cv_ng_data                 CONSTANT VARCHAR2(7)   := 'NG_DATA';                      --CSV出力エラートークン・NG_DATA
  cv_param                   CONSTANT VARCHAR2(5)   := 'PARAM';                        --パラメータトークン
  cv_value                   CONSTANT VARCHAR2(5)   := 'VALUE';                        --パラメータ値トークン
  cv_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';                      --値トークン
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_process_date     VARCHAR2(20);          --業務日付
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
  gd_process_date     DATE;                  --業務日付
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_date_from  IN  VARCHAR2,     --   コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to    IN  VARCHAR2,     --   コンカレント・パラメータ処理日(TO)
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_HHT_OUT_DIR';           --XXCMM:HHT(OUTBOUND)連携用CSVファイル出力先
    cv_out_file_file CONSTANT VARCHAR2(30) := 'XXCMM1_003A19_OUT_FILE_FIL';   --XXCMM: HHT系連携IFデータ作成用CSVファイル名
    cv_invalid_path  CONSTANT VARCHAR2(25) := 'CSV出力ディレクトリ';          --プロファイル取得失敗（ディレクトリ）
    cv_invalid_name  CONSTANT VARCHAR2(20) := 'CSV出力ファイル名';            --プロファイル取得失敗（ファイル名）
--
    -- *** ローカル変数 ***
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    lv_file_chk     BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
-- 2009/4/13 Ver1.2 add end by Yutaka.Kuboshima
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
    --CSV出力ディレクトリをプロファイルより取得。失敗時はエラー
    gv_out_file_dir := FND_PROFILE.VALUE(cv_out_file_dir);
    IF (gv_out_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_path);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --CSV出力ファイル名をプロファイルより取得。失敗時はエラー
    gv_out_file_file := FND_PROFILE.VALUE(cv_out_file_file);
    IF (gv_out_file_file IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_name);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    -- ファイル存在チェック
    UTL_FILE.FGETATTR(gv_out_file_dir, gv_out_file_file, lv_file_chk, ln_file_size, ln_block_size);
    IF (lv_file_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_exist_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
-- 2009/4/13 Ver1.2 add end by Yutaka.Kuboshima
--
    -- 業務日付取得処理
    gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date, cv_fnd_date);
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    gd_process_date := TO_DATE(gv_process_date, cv_fnd_date);
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
--
    -- パラメータチェック
    IF ( NVL(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), gv_process_date) > NVL(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), gv_process_date) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_term_spec_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
  EXCEPTION
    WHEN init_err_expt THEN                           --*** 初期処理例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --初期処理例外時、対象件数、エラー件数は0件固定とする
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : file_open
   * Description      : ファイルオープン処理(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    of_file_handler OUT UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    ov_errbuf       OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- プログラム名
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
    cn_record_byte CONSTANT NUMBER      := 4095;  --ファイル読み込み文字数
    cv_file_mode   CONSTANT VARCHAR2(1) := 'W';   --書き込みモードで開く
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      --ファイルオープン
      of_file_handler := UTL_FILE.FOPEN(gv_out_file_dir,
                                        gv_out_file_file,
                                        cv_file_mode,
                                        cn_record_byte);
    EXCEPTION
      --ファイルパスエラー
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_file_path_invalid_msg);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  EXCEPTION
    WHEN fopen_err_expt THEN                           --*** ファイルオープンエラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --ファイルオープンエラー時、対象件数、エラー件数は0件固定とする
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : output_cust_data
   * Description      : 処理対象データ抽出処理(A-3)・抽出情報出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_cust_data(
    iv_proc_date_from       IN  VARCHAR2,               --   コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to         IN  VARCHAR2,               --   コンカレント・パラメータ処理日(TO)
    io_file_handler         IN  UTL_FILE.FILE_TYPE,     --   ファイルハンドラ
    ov_errbuf               OUT VARCHAR2,               --   エラー・メッセージ                  --# 固定 #
    ov_retcode              OUT VARCHAR2,               --   リターン・コード                    --# 固定 #
    ov_errmsg               OUT VARCHAR2)               --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_cust_data'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cv_eff_last_date      CONSTANT VARCHAR2(15)     := '99991231';                --有効日_至
    cv_language_ja        CONSTANT VARCHAR2(2)      := 'JA';                      --言語(日本語)
    cv_enabled_flag       CONSTANT VARCHAR2(1)      := 'Y';                       --使用可能フラグ
    cv_a_flag             CONSTANT VARCHAR2(1)      := 'A';                       --有効フラグ
    cv_gyotai_syo         CONSTANT VARCHAR2(25)     := 'XXCMM_CUST_GYOTAI_SHO';   --業態分類(小分類)
    cv_hht_syohi          CONSTANT VARCHAR2(30)     := 'XXCOS1_CONSUMPTION_TAX_CLASS'; --HHT消費税区分
    cv_bill_to            CONSTANT VARCHAR2(7)      := 'BILL_TO';                 --使用目的・請求先
    cv_other_to           CONSTANT VARCHAR2(8)      := 'OTHER_TO';                --使用目的・出荷先
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    cv_base               CONSTANT VARCHAR2(2)      := '1';                       --顧客区分(拠点)
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
    cv_cust_cd            CONSTANT VARCHAR2(2)      := '10';                      --顧客区分(顧客)
    cv_ucust_cd           CONSTANT VARCHAR2(2)      := '12';                      --顧客区分(上様顧客)
    cv_round_cd           CONSTANT VARCHAR2(2)      := '15';                      --顧客区分(巡回)
    cv_plan_cd            CONSTANT VARCHAR2(2)      := '17';                      --顧客区分(計画立案用)
    cv_mc_sts             CONSTANT VARCHAR2(2)      := '20';                      --顧客ステータス(MC)
    cv_vd_24              CONSTANT VARCHAR2(2)      := '24';                      --フルサービス(消化)VD
    cv_vd_25              CONSTANT VARCHAR2(2)      := '25';                      --フルサービスVD
    cv_vd_26              CONSTANT VARCHAR2(2)      := '26';                      --納品VD
    cv_in_21              CONSTANT VARCHAR2(2)      := '21';                      --インショップ
    cv_vd_27              CONSTANT VARCHAR2(2)      := '27';                      --消化VD
    cv_vd_11              CONSTANT VARCHAR2(2)      := '11';                      --VD
    cv_pay_tm             CONSTANT VARCHAR2(8)      := '00_00_00';                --支払条件
    cv_oj_party           CONSTANT VARCHAR2(5)      := 'PARTY';                   --ノート・コード
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    cv_dept_div_mult      CONSTANT VARCHAR2(2)      := '1';                       --百貨店HHT区分(拠点複)
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
--
    cv_cdvd_code          CONSTANT VARCHAR2(1)      := '0';                       --カードベンダ区分
    cv_null_code          CONSTANT VARCHAR2(1)      := '0';                       --HHT書式(NULL)
    cv_zr_sts             CONSTANT VARCHAR2(1)      := '0';                       --ステータス「0」
    cv_on_sts             CONSTANT VARCHAR2(1)      := '1';                       --ステータス「1」
    cv_tw_sts             CONSTANT VARCHAR2(1)      := '2';                       --ステータス「2」
    cv_th_sts             CONSTANT VARCHAR2(1)      := '3';                       --ステータス「3」
    cv_err_cust_code_msg  CONSTANT VARCHAR2(20)     := '顧客コード';              --CSV出力エラー文字列
    cn_note_lenb          CONSTANT NUMBER           := 2000;                      --ノート上限値
    cv_ver_line           CONSTANT VARCHAR2(1)      := '|';                       --縦棒
    cv_null_sts           CONSTANT VARCHAR2(1)      := NULL;                      --NULLデータ
--
-- 2009/06/09 Ver1.4 add start by Yutaka.Kuboshima
    cv_single_byte_err1   CONSTANT VARCHAR2(30)    := 'ﾊﾝｶｸｴﾗｰ';                --半角エラー時のダミー値1
    cv_single_byte_err2   CONSTANT VARCHAR2(30)    := '99-9999-9999';           --半角エラー時のダミー値2
-- 2009/06/09 Ver1.4 add end by Yutaka.Kuboshima
--
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    cv_min_time           CONSTANT VARCHAR2(7)      := '000000';                  --時分秒最小
    cv_max_time           CONSTANT VARCHAR2(7)      := '235959';                  --時分秒最大
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
    -- *** ローカル変数 ***
    lv_output_str                  VARCHAR2(4095)   := NULL;                      --出力文字列格納用変数
    ln_output_cnt                  NUMBER           := 0;                         --出力件数
    lv_coordinated_date            VARCHAR2(30)     := NULL;                      --連携日付取得
    lv_note_work                   VARCHAR2(5000)   := NULL;                      --ノート作業用変数
    lv_note_str                    VARCHAR2(5000)   := NULL;                      --ノート
--
-- 2009/06/09 Ver1.4 add start by Yutaka.Kuboshima
    lv_customer_name               VARCHAR2(1500);                              --顧客名称
    lv_customer_name_kana          VARCHAR2(1500);                              --顧客名カナ
    lv_address1                    VARCHAR2(1500);                              --住所１
    lv_address_lines_phonetic      VARCHAR2(1500);                              --電話番号
-- 2009/06/09 Ver1.4 add end by Yutaka.Kuboshima
--
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    ld_proc_date_from              DATE;                                        --パラメータ処理日(FROM)
    ld_proc_date_to                DATE;                                        --パラメータ処理日(TO)
    ld_process_date_next_f         DATE;                                        --翌業務月１日
    ld_process_date_next_l         DATE;                                        --翌業務月最終日
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    -- 差分連携対象顧客取得カーソル
    CURSOR def_cust_cur(p_proc_date_from IN DATE,
                        p_proc_date_to   IN DATE)
    IS
      SELECT /*+ FIRST_ROWS INDEX(hca hz_cust_accounts_u1) */
             hca.cust_account_id customer_id
      FROM   hz_cust_accounts hca
            ,( -- 顧客マスタ
               SELECT hca1.cust_account_id customer_id
               FROM   hz_cust_accounts hca1
               WHERE  hca1.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
               UNION
               -- 顧客追加情報マスタ
               SELECT xca2.customer_id customer_id
               FROM   xxcmm_cust_accounts xca2
               WHERE  xca2.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
               UNION
               -- パーティマスタ
               SELECT /*+ INDEX(hca3 hz_cust_accounts_n2) */
                      hca3.cust_account_id customer_id
               FROM   hz_cust_accounts hca3
                     ,hz_parties hp3
               WHERE  hca3.party_id = hp3.party_id
                 AND  hp3.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
               UNION
               -- 顧客使用目的マスタ
               SELECT hcas4.cust_account_id customer_id
               FROM   hz_cust_acct_sites hcas4
                     ,hz_cust_site_uses  hcsu4
               WHERE  hcas4.cust_acct_site_id = hcsu4.cust_acct_site_id
                 AND  hcsu4.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
               UNION
               -- 顧客事業所マスタ
               SELECT /*+ INDEX(hca5 hz_cust_accounts_n2) */
                      hca5.cust_account_id customer_id
               FROM   hz_cust_accounts hca5
                     ,hz_parties hp5
                     ,hz_party_sites hps5
                     ,hz_locations hl5
               WHERE  hca5.party_id = hp5.party_id
                 AND  hp5.party_id  = hps5.party_id
                 AND  hps5.location_id = hl5.location_id
                 AND  hl5.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
               UNION
               -- 支払条件マスタ
               SELECT /*+ FIRST_ROWS */
                      hcas6.cust_account_id customer_id
               FROM   hz_cust_acct_sites hcas6
                     ,hz_cust_site_uses  hcsu6
                     ,ra_terms           rt6
               WHERE  hcas6.cust_acct_site_id = hcsu6.cust_acct_site_id
                 AND  hcsu6.payment_term_id = rt6.term_id
                 AND  rt6.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
               UNION
               -- 組織拡張プロファイルマスタ
               SELECT hca7.cust_account_id customer_id
               FROM   hz_cust_accounts hca7
                     ,hz_parties hp7
                     ,hz_organization_profiles hop7
                     ,hz_org_profiles_ext_vl hopev7
               WHERE  hca7.party_id = hp7.party_id
                 AND  hp7.party_id  = hop7.party_id
                 AND  hop7.organization_profile_id = hopev7.organization_profile_id
-- 2009/12/06 Ver1.7 障害E_本稼動_00327 add start by Yutaka.Kuboshima
                 AND  hop7.effective_end_date IS NULL
-- 2009/12/06 Ver1.7 障害E_本稼動_00327 add end by Yutaka.Kuboshima
                 AND  hopev7.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to
-- 2009/12/06 Ver1.7 障害E_本稼動_00327 add start by Yutaka.Kuboshima
-- 担当営業員、ルートの有効開始日が
-- 最終更新日(開始) + 1 <= 有効開始日 <= 最終更新日(終了)の翌日付の場合も対象データとするように修正
               UNION
               -- 担当営業員
               SELECT hca8.cust_account_id customer_id
               FROM   hz_cust_accounts hca8
                     ,hz_parties hp8
                     ,hz_organization_profiles hop8
                     ,hz_org_profiles_ext_vl hopev8
                     ,ego_resource_agv era8
               WHERE  hca8.party_id = hp8.party_id
                 AND  hp8.party_id  = hop8.party_id
                 AND  hop8.organization_profile_id = hopev8.organization_profile_id
                 AND  hopev8.extension_id = era8.extension_id
                 AND  hop8.effective_end_date IS NULL
                 AND  hopev8.d_ext_attr1 BETWEEN (p_proc_date_from + 1) AND xxccp_common_pkg2.get_working_day(p_proc_date_to, 1)
               UNION
               -- ルート
               SELECT hca9.cust_account_id customer_id
               FROM   hz_cust_accounts hca9
                     ,hz_parties hp9
                     ,hz_organization_profiles hop9
                     ,hz_org_profiles_ext_vl hopev9
                     ,ego_route_agv era9
               WHERE  hca9.party_id = hp9.party_id
                 AND  hp9.party_id  = hop9.party_id
                 AND  hop9.organization_profile_id = hopev9.organization_profile_id
                 AND  hopev9.extension_id = era9.extension_id
                 AND  hop9.effective_end_date IS NULL
                 AND  hopev9.d_ext_attr3 BETWEEN (p_proc_date_from + 1) AND xxccp_common_pkg2.get_working_day(p_proc_date_to, 1)
-- 2009/12/06 Ver1.7 障害E_本稼動_00327 add end by Yutaka.Kuboshima
             ) def
      WHERE  hca.cust_account_id = def.customer_id
      ORDER BY hca.account_number;
--
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
    -- HHT連携IFデータ作成カーソル
-- 2009/08/24 Ver1.5 modify start by Yutaka.Kuboshima
-- 該当SQLを大幅改修
-- 差分連携される顧客を先に抽出する様に修正
--    CURSOR cust_data_cur
--    IS
--      SELECT hca.account_number                                          account_number,              --顧客コード
--             hp.party_name                                               party_name,                  --顧客名称
--             flvctc.lookup_code                                          tax_div,                     --消費税区分
--             DECODE( xca.business_low_type, cv_vd_24, cv_on_sts, cv_vd_25, cv_on_sts, cv_vd_26, cv_tw_sts, cv_null_sts, cv_date_null, cv_zr_sts )  vd_contract_form, --ベンダ契約形態
--             DECODE(rt.name, cv_pay_tm, cv_on_sts, cv_null_sts, cv_date_null, cv_th_sts )           mode_div,           --態様区分
--             xca.final_tran_date                                         final_tran_date,             --最終取引日
--             xca.final_call_date                                         final_call_date,             --最終訪問日
--             DECODE( xca.business_low_type, cv_in_21, cv_on_sts, cv_vd_27, cv_tw_sts, cv_null_sts, cv_date_null, cv_zr_sts )  entrust_dest_flg, --預け先判定フラグ
--             DECODE( flvgs.attribute1, cv_vd_11, cv_on_sts, cv_null_sts, cv_date_null, cv_zr_sts )  vd_cust_class_cd,   --VD顧客区分
--             hp.duns_number_c                                            duns_number_c,               --顧客ステータスコード
--             xca.change_amount                                           change_amount,               --つり銭
--             hp.organization_name_phonetic                               org_name_phonetic,           --顧客名カナ
--             hl.city || hl.address1 || hl.address2                       address1,                    --住所１
--             hl.address_lines_phonetic                                   address_lines_phonetic,      --電話番号
--             xca.sale_base_code                                          sale_base_code,              --売上拠点コード
--             xca.past_sale_base_code                                     past_sale_base_code,         --前月売上拠点コード
--             xca.rsv_sale_base_code                                      rsv_sale_base_code,          --予約売上拠点コード
--             xca.rsv_sale_base_act_date                                  rsv_sale_base_act_date,      --予約売上拠点有効開始日
--             hopera.resource_no                                          resource_no,                 --担当営業員コード
--             hopero.route_no                                             route_no,                    --ルートコード
--             hca.cust_account_id                                         cust_account_id,             --顧客ID
--             hca.party_id                                                party_id,                    --パーティID
--             hca.customer_class_code                                     customer_class_code,         --顧客区分
--             hopera2.resource_no                                         next_resource_no,            --次月担当営業員コード
--             hopera2.resource_s_date                                     next_resource_s_date,        --次月担当営業員適用月
--             hopero2.route_no                                            next_route_no,               --予約ルートコード
--             hopero2.route_s_date                                        next_route_s_date            --予約ルートコード適用月
--      FROM   hz_cust_accounts          hca,      --顧客マスタ
--             hz_locations              hl,       --顧客事業所マスタ
--             hz_cust_site_uses         hcsu,     --顧客使用目的マスタ
--             xxcmm_cust_accounts       xca,      --顧客追加情報マスタ
--             hz_party_sites            hps,      --パーティサイトマスタ
--             hz_cust_acct_sites        hcas,     --顧客所在地マスタ
--             hz_parties                hp,       --パーティマスタ
--             ra_terms                  rt,       --支払条件マスタ
----
--             (SELECT lookup_code    lookup_code,
--                     attribute1     attribute1
--             FROM    fnd_lookup_values flvs
--             WHERE   flvs.language     = cv_language_ja
--             AND     flvs.lookup_type  = cv_gyotai_syo
--             AND     flvs.enabled_flag = cv_enabled_flag) flvgs,    --クイックコード_参照コード(業態(小分類))
----
--             (SELECT flvc.lookup_code    lookup_code,
--                     flvc.attribute3     attribute3
--             FROM    fnd_lookup_values flvc
--             WHERE   flvc.language     = cv_language_ja
--             AND     flvc.lookup_type  = cv_hht_syohi
--             AND     flvc.enabled_flag = cv_enabled_flag) flvctc,   --クイックコード_参照コード(HHT消費税区分)
----
--             (SELECT hopviw1.party_id            party_id,
--                     erea.resource_no            resource_no,
--                     erea.resource_s_date        resource_s_date,
--                     hopev.last_update_date      last_update_date
---- 2009/04/28 Ver1.3 modify start by Yutaka.Kuboshima
----             FROM    hz_cust_accounts            hcaviw1,   --顧客マスタ
--             FROM    hz_parties                  hcaviw1,   --パーティマスタ
---- 2009/04/28 Ver1.3 modify end by Yutaka.Kuboshima
--                     hz_organization_profiles    hopviw1,   --組織プロファイルマスタ
--                     ego_resource_agv            erea,      --組織プロファイル拡張マスタ(営業員)
--                     hz_org_profiles_ext_vl      hopev
--             WHERE   (TO_DATE(gv_process_date, cv_fnd_date) + 1
--                     BETWEEN NVL(TRUNC(erea.resource_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                     AND     NVL(TRUNC(erea.resource_e_date, cv_trunc_dd), TO_DATE(cv_eff_last_date, cv_fnd_date)))
--             AND     hcaviw1.party_id  = hopviw1.party_id
--             AND     erea.extension_id = hopev.extension_id
--             AND     hopviw1.organization_profile_id = erea.organization_profile_id
--             AND     erea.extension_id = (SELECT erearow1.extension_id
--                                         FROM    hz_organization_profiles      hoprow1,       --組織プロファイルマスタ
--                                                 ego_resource_agv              erearow1       --組織プロファイル拡張マスタ(営業員)
--                                         WHERE   (TO_DATE(gv_process_date, cv_fnd_date) + 1
--                                                 BETWEEN NVL(TRUNC(erearow1.resource_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                                                 AND     NVL(TRUNC(erearow1.resource_e_date, cv_trunc_dd), TO_DATE(cv_eff_last_date, cv_fnd_date)))
--                                         AND     hcaviw1.party_id            = hoprow1.party_id
--                                         AND     hoprow1.organization_profile_id = erearow1.organization_profile_id
--                                         AND     ROWNUM = 1 ))  hopera, --組織プロファイル(担当営業員)
----
--             (SELECT hopnm.party_id              party_id,
--                     hopev.last_update_date      last_update_date,
--                     ereanm.resource_no          resource_no,
--                     ereanm.resource_s_date      resource_s_date
---- 2009/04/28 Ver1.3 modify start by Yutaka.Kuboshima
----             FROM    hz_cust_accounts            hcanm,     --顧客マスタ
--             FROM    hz_parties                  hcanm,     --パーティマスタ
---- 2009/04/28 Ver1.3 modify end by Yutaka.Kuboshima
--                     hz_organization_profiles    hopnm,     --組織プロファイルマスタ
--                     ego_resource_agv            ereanm,    --組織プロファイル拡張マスタ(営業員)
--                     hz_org_profiles_ext_vl      hopev
--             WHERE   NVL(TRUNC(ereanm.resource_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                     BETWEEN TRUNC(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1), cv_trunc_mm)
--                     AND     LAST_DAY(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1))
--             AND     hopnm.party_id                = hcanm.party_id
--             AND     ereanm.extension_id           = hopev.extension_id
--             AND     hopnm.organization_profile_id = ereanm.organization_profile_id
--             AND     ereanm.extension_id = (SELECT erevw.extension_id
--                                           FROM    (SELECT  erea.extension_id           extension_id,
--                                                            erea.resource_no            resource_no,
--                                                            erea.resource_s_date        resource_s_date,
--                                                            hop.party_id                party_id
--                                                   FROM     hz_organization_profiles    hop,       --組織プロファイルマスタ
--                                                            ego_resource_agv            erea       --組織プロファイル拡張マスタ(営業員)
--                                                   WHERE    NVL(TRUNC(erea.resource_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                                                            BETWEEN TRUNC(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1), cv_trunc_mm)
--                                                            AND     LAST_DAY(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1))
--                                                   AND      hop.organization_profile_id = erea.organization_profile_id
--                                                   ORDER BY erea.resource_s_date) erevw,
--                                                   hz_organization_profiles  hopex
--                                           WHERE  hopex.party_id = erevw.party_id
--                                           AND    hopnm.party_id = hopex.party_id
--                                           AND    ROWNUM = 1))   hopera2,  --組織プロファイルマスタ(次月担当営業員)
----
--             (SELECT hopviw2.party_id            party_id,
--                     eroa.route_no               route_no,
--                     eroa.route_s_date           route_s_date,
--                     hopev2.last_update_date     last_update_date
---- 2009/04/28 Ver1.3 modify start by Yutaka.Kuboshima
----             FROM    hz_cust_accounts            hcaviw2,   --顧客マスタ
--             FROM    hz_parties                  hcaviw2,   --パーティマスタ
---- 2009/04/28 Ver1.3 modify end by Yutaka.Kuboshima
--                     hz_organization_profiles    hopviw2,   --組織プロファイルマスタ
--                     ego_route_agv               eroa,      --組織プロファイル拡張マスタ(ルート)
--                     hz_org_profiles_ext_vl      hopev2
--             WHERE   (TO_DATE(gv_process_date, cv_fnd_date) + 1
--                     BETWEEN NVL(TRUNC(eroa.route_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                     AND     NVL(TRUNC(eroa.route_e_date, cv_trunc_dd), TO_DATE(cv_eff_last_date, cv_fnd_date)))
--             AND     hcaviw2.party_id  = hopviw2.party_id
--             AND     eroa.extension_id = hopev2.extension_id
--             AND     hopviw2.organization_profile_id = eroa.organization_profile_id
--             AND     eroa.extension_id = (SELECT eroarow2.extension_id
--                                         FROM    hz_organization_profiles      hoprow2,       --組織プロファイルマスタ
--                                                 ego_route_agv                 eroarow2       --組織プロファイル拡張マスタ(ルート)
--                                         WHERE   (TO_DATE(gv_process_date, cv_fnd_date) + 1
--                                                 BETWEEN NVL(TRUNC(eroarow2.route_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                                                 AND     NVL(TRUNC(eroarow2.route_e_date, cv_trunc_dd), TO_DATE(cv_eff_last_date, cv_fnd_date)))
--                                         AND     hcaviw2.party_id  = hoprow2.party_id
--                                         AND     hoprow2.organization_profile_id = eroarow2.organization_profile_id
--                                         AND     ROWNUM = 1 ))  hopero,  --組織プロファイル(ルート)
----
--             (SELECT hopnm.party_id              party_id,
--                     hopev.last_update_date      last_update_date,
--                     ereanm.route_no             route_no,
--                     ereanm.route_s_date         route_s_date
---- 2009/04/28 Ver1.3 modify start by Yutaka.Kuboshima
----             FROM    hz_cust_accounts            hcanm,     --顧客マスタ
--             FROM    hz_parties                  hcanm,     --パーティマスタ
---- 2009/04/28 Ver1.3 modify end by Yutaka.Kuboshima
--                     hz_organization_profiles    hopnm,     --組織プロファイルマスタ
--                     ego_route_agv               ereanm,    --組織プロファイル拡張マスタ(営業員)
--                     hz_org_profiles_ext_vl      hopev
--             WHERE   NVL(TRUNC(ereanm.route_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                     BETWEEN TRUNC(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1), cv_trunc_mm)
--                     AND     LAST_DAY(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1))
--             AND     hopnm.party_id                = hcanm.party_id
--             AND     ereanm.extension_id           = hopev.extension_id
--             AND     hopnm.organization_profile_id = ereanm.organization_profile_id
--             AND     ereanm.extension_id = (SELECT erevw.extension_id
--                                           FROM    (SELECT  erea.extension_id           extension_id,
--                                                            erea.route_no               route_no,
--                                                            erea.route_s_date           route_s_date,
--                                                            hop.party_id                party_id
--                                                   FROM     hz_organization_profiles    hop,       --組織プロファイルマスタ
--                                                            ego_route_agv               erea       --組織プロファイル拡張マスタ(営業員)
--                                                   WHERE    NVL(TRUNC(erea.route_s_date, cv_trunc_dd), TO_DATE(gv_process_date, cv_fnd_date) + 1)
--                                                            BETWEEN TRUNC(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1), cv_trunc_mm)
--                                                            AND     LAST_DAY(ADD_MONTHS(TO_DATE(gv_process_date, cv_fnd_date) + 1, 1))
--                                                   AND      hop.organization_profile_id = erea.organization_profile_id
--                                                   ORDER BY erea.route_s_date) erevw,
--                                                   hz_organization_profiles  hopex
--                                           WHERE  hopex.party_id = erevw.party_id
--                                           AND    hopnm.party_id = hopex.party_id
--                                           AND    ROWNUM = 1))   hopero2   --組織プロファイルマスタ(次月ルート)
----
--      WHERE  (hca.customer_class_code  IN ( cv_cust_cd, cv_ucust_cd, cv_round_cd, cv_plan_cd )
--      OR     (hca.customer_class_code  IS NULL
--      AND    hp.duns_number_c = cv_mc_sts))
--      AND    ((TRUNC(hca.last_update_date, cv_trunc_dd)      --顧客マスタ
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(xca.last_update_date, cv_trunc_dd)      --顧客追加情報マスタ
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hl.last_update_date, cv_trunc_dd)      --顧客事業所マスタ
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hp.last_update_date, cv_trunc_dd)      --パーティマスタ
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hcsu.last_update_date, cv_trunc_dd)      --顧客使用目的マスタ
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(rt.last_update_date, cv_trunc_dd)      --支払条件マスタ
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hopera.last_update_date, cv_trunc_dd)      --組織プロファイル(営業員)
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hopera2.last_update_date, cv_trunc_dd)      --組織プロファイル(次月営業員)
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hopero.last_update_date, cv_trunc_dd)      --組織プロファイル(ルート)
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) )
--      OR     (TRUNC(hopero2.last_update_date, cv_trunc_dd)      --組織プロファイル(次月ルート)
--             BETWEEN NVL(TO_DATE(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) )
--             AND     NVL(TO_DATE(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), cv_fnd_date), TO_DATE(gv_process_date, cv_fnd_date ) ) ) )
--      AND    xca.tax_div            = flvctc.attribute3 (+)        --消費税区分
--      AND    hca.party_id           = hopera.party_id (+)          --顧客マスタ           = 組織プロ拡張マスタ：パーティID(営業)
--      AND    hca.party_id           = hopera2.party_id (+)         --顧客マスタ           = 組織プロ拡張マスタ：パーティID(次月営業)
--      AND    hca.party_id           = hopero.party_id (+)          --顧客マスタ           = 組織プロ拡張マスタ：パーティID(ルート)
--      AND    hca.party_id           = hopero2.party_id (+)         --顧客マスタ           = 組織プロ拡張マスタ：パーティID(次月ルート)
--      AND    hca.cust_account_id    = xca.customer_id              --顧客マスタ           = 顧客追加情報マスタ：顧客ID
--      AND    hca.party_id           = hp.party_id                  --顧客マスタ           = パーティマスタ    ：パーティID
--      AND    hps.location_id        = hl.location_id               --パーティサイトマスタ = 事業所マスタ      ：ロケーションID
--      AND    hca.cust_account_id    = hcas.cust_account_id         --顧客マスタ           = 顧客所在地マスタ  ：顧客ID
--      AND    hcas.cust_acct_site_id = hcsu.cust_acct_site_id       --顧客所在地マスタ     = 使用目的マスタ    ：顧客サイトID
--      AND    xca.business_low_type  = flvgs.lookup_code (+)        --LOOKUP_参照(業態小)  = 顧客追加情報マスタ: 業態分類(小分類)
--      AND    hcsu.payment_term_id   = rt.term_id (+)               --使用目的マスタ       = 支払条件マスタ    : 支払条件ID
--      AND    hcsu.site_use_code     IN ( cv_bill_to, cv_other_to ) --使用目的マスタ(請求先・その他)
--      AND    hcsu.status            = cv_a_flag
--      AND    hl.location_id         = (SELECT MIN(hpsiv.location_id)
--                                      FROM    hz_cust_acct_sites     hcasiv,
--                                              hz_party_sites         hpsiv
--                                      WHERE   hcasiv.cust_account_id = hca.cust_account_id
--                                      AND     hcasiv.party_site_id   = hpsiv.party_site_id
--                                      AND     hpsiv.status           = cv_a_flag)      --ロケーションIDの最小値
---- 2009/04/28 Ver1.3 add start by Yutaka.Kuboshima
--      AND    hp.party_id            = hps.party_id
--      AND    hcas.party_site_id     = hps.party_site_id
---- 2009/04/28 Ver1.3 add end by Yutaka.Kuboshima
--      ORDER BY hca.account_number;
--
-- ↓ modify start
    -- HHT連携IFデータ作成カーソル
    CURSOR cust_data_cur(p_customer_id         IN NUMBER,
                         p_process_date_next_f IN DATE,
                         p_process_date_next_l IN DATE)
    IS
      SELECT /*+ FIRST_ROWS */
             hca.account_number                                          account_number,              --顧客コード
             hp.party_name                                               party_name,                  --顧客名称
             flvctc.lookup_code                                          tax_div,                     --消費税区分
             DECODE( xca.business_low_type, cv_vd_24, cv_on_sts, cv_vd_25, cv_on_sts, cv_vd_26, cv_tw_sts, cv_null_sts, cv_date_null, cv_zr_sts )  vd_contract_form, --ベンダ契約形態
             DECODE( rt.name, cv_pay_tm, cv_on_sts, cv_null_sts, cv_date_null, cv_th_sts )           mode_div,           --態様区分
             xca.final_tran_date                                         final_tran_date,             --最終取引日
             xca.final_call_date                                         final_call_date,             --最終訪問日
             DECODE( xca.business_low_type, cv_in_21, cv_on_sts, cv_vd_27, cv_tw_sts, cv_null_sts, cv_date_null, cv_zr_sts )  entrust_dest_flg, --預け先判定フラグ
             DECODE( flvgs.attribute1, cv_vd_11, cv_on_sts, cv_null_sts, cv_date_null, cv_zr_sts )  vd_cust_class_cd,   --VD顧客区分
             hp.duns_number_c                                            duns_number_c,               --顧客ステータスコード
             xca.change_amount                                           change_amount,               --つり銭
             hp.organization_name_phonetic                               org_name_phonetic,           --顧客名カナ
             hl.city || hl.address1 || hl.address2                       address1,                    --住所１
             hl.address_lines_phonetic                                   address_lines_phonetic,      --電話番号
             xca.sale_base_code                                          sale_base_code,              --売上拠点コード
             xca.past_sale_base_code                                     past_sale_base_code,         --前月売上拠点コード
             xca.rsv_sale_base_code                                      rsv_sale_base_code,          --予約売上拠点コード
             xca.rsv_sale_base_act_date                                  rsv_sale_base_act_date,      --予約売上拠点有効開始日
             hopera.resource_no                                          resource_no,                 --担当営業員コード
             hopero.route_no                                             route_no,                    --ルートコード
             hca.cust_account_id                                         cust_account_id,             --顧客ID
             hca.party_id                                                party_id,                    --パーティID
             hca.customer_class_code                                     customer_class_code,         --顧客区分
             hopera2.resource_no                                         next_resource_no,            --次月担当営業員コード
             hopera2.resource_s_date                                     next_resource_s_date,        --次月担当営業員適用月
             hopero2.route_no                                            next_route_no,               --予約ルートコード
             hopero2.route_s_date                                        next_route_s_date            --予約ルートコード適用月
      FROM   hz_cust_accounts          hca,      --顧客マスタ
             hz_locations              hl,       --顧客事業所マスタ
             hz_cust_site_uses         hcsu,     --顧客使用目的マスタ
             xxcmm_cust_accounts       xca,      --顧客追加情報マスタ
             hz_party_sites            hps,      --パーティサイトマスタ
             hz_cust_acct_sites        hcas,     --顧客所在地マスタ
             hz_parties                hp,       --パーティマスタ
             ra_terms                  rt,       --支払条件マスタ
--
             (SELECT flvs.lookup_code    lookup_code,
                     flvs.attribute1     attribute1
             FROM    fnd_lookup_values flvs
             WHERE   flvs.language     = cv_language_ja
             AND     flvs.lookup_type  = cv_gyotai_syo
             AND     flvs.enabled_flag = cv_enabled_flag) flvgs,    --クイックコード_参照コード(業態(小分類))
--
             (SELECT flvc.lookup_code    lookup_code,
                     flvc.attribute3     attribute3
             FROM    fnd_lookup_values flvc
             WHERE   flvc.language     = cv_language_ja
             AND     flvc.lookup_type  = cv_hht_syohi
             AND     flvc.enabled_flag = cv_enabled_flag) flvctc,   --クイックコード_参照コード(HHT消費税区分)
--
             -- 組織プロファイル拡張マスタの結合を削除
             -- 日付項目の見直し
             (SELECT hopviw1.party_id            party_id,
                     erea.resource_no            resource_no,
                     erea.resource_s_date        resource_s_date
             FROM    hz_parties                  hcaviw1,   --パーティマスタ
                     hz_organization_profiles    hopviw1,   --組織プロファイルマスタ
                     ego_resource_agv            erea       --組織プロファイル拡張マスタ(営業員)
             WHERE   (gd_process_date + 1) BETWEEN erea.resource_s_date AND NVL(erea.resource_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date))
             AND     hcaviw1.party_id  = hopviw1.party_id
             AND     hopviw1.organization_profile_id = erea.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
             AND     hopviw1.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
             AND     erea.extension_id = (SELECT  erearow1.extension_id
                                          FROM    hz_organization_profiles      hoprow1,       --組織プロファイルマスタ
                                                  ego_resource_agv              erearow1       --組織プロファイル拡張マスタ(営業員)
                                          WHERE   (gd_process_date + 1) BETWEEN erearow1.resource_s_date AND NVL(erearow1.resource_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date))
                                          AND     hcaviw1.party_id            = hoprow1.party_id
                                          AND     hoprow1.organization_profile_id = erearow1.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
                                          AND     hoprow1.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
                                          AND     ROWNUM = 1 ))  hopera, --組織プロファイル(担当営業員)
--
             -- 組織プロファイル拡張マスタの結合を削除
             -- 日付項目の見直し
             (SELECT hopnm.party_id              party_id,
                     ereanm.resource_no          resource_no,
                     ereanm.resource_s_date      resource_s_date
             FROM    hz_parties                  hcanm,     --パーティマスタ
                     hz_organization_profiles    hopnm,     --組織プロファイルマスタ
                     ego_resource_agv            ereanm     --組織プロファイル拡張マスタ(営業員)
             WHERE   ereanm.resource_s_date BETWEEN p_process_date_next_f AND p_process_date_next_l
             AND     hopnm.party_id                = hcanm.party_id
             AND     hopnm.organization_profile_id = ereanm.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
             AND     hopnm.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
             AND     ereanm.extension_id = (SELECT erevw.extension_id
                                            FROM   (SELECT   erea.extension_id           extension_id,
                                                             hop.party_id                party_id
                                                    FROM     hz_organization_profiles    hop,       --組織プロファイルマスタ
                                                             ego_resource_agv            erea       --組織プロファイル拡張マスタ(営業員)
                                                    WHERE    erea.resource_s_date BETWEEN p_process_date_next_f AND p_process_date_next_l
                                                    AND      hop.organization_profile_id = erea.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
                                                    AND      hop.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
                                                    ORDER BY erea.resource_s_date) erevw
                                            WHERE  hopnm.party_id = erevw.party_id
                                            AND    ROWNUM = 1))   hopera2,  --組織プロファイルマスタ(次月担当営業員)
--
             -- 組織プロファイル拡張マスタの結合を削除
             -- 日付項目の見直し
             (SELECT hopviw2.party_id            party_id,
                     eroa.route_no               route_no,
                     eroa.route_s_date           route_s_date
             FROM    hz_parties                  hcaviw2,   --パーティマスタ
                     hz_organization_profiles    hopviw2,   --組織プロファイルマスタ
                     ego_route_agv               eroa       --組織プロファイル拡張マスタ(ルート)
             WHERE   (gd_process_date + 1) BETWEEN eroa.route_s_date AND NVL(eroa.route_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date))
             AND     hcaviw2.party_id  = hopviw2.party_id
             AND     hopviw2.organization_profile_id = eroa.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
             AND     hopviw2.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
             AND     eroa.extension_id = (SELECT  eroarow2.extension_id
                                          FROM    hz_organization_profiles      hoprow2,       --組織プロファイルマスタ
                                                  ego_route_agv                 eroarow2       --組織プロファイル拡張マスタ(ルート)
                                          WHERE   (gd_process_date + 1) BETWEEN eroarow2.route_s_date AND NVL(eroarow2.route_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date))
                                          AND     hcaviw2.party_id  = hoprow2.party_id
                                          AND     hoprow2.organization_profile_id = eroarow2.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
                                          AND     hoprow2.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
                                          AND     ROWNUM = 1 ))  hopero,  --組織プロファイル(ルート)
--
             -- 組織プロファイル拡張マスタの結合を削除
             -- 日付項目の見直し
             (SELECT hopnm.party_id              party_id,
                     ereanm.route_no             route_no,
                     ereanm.route_s_date         route_s_date
             FROM    hz_parties                  hcanm,     --パーティマスタ
                     hz_organization_profiles    hopnm,     --組織プロファイルマスタ
                     ego_route_agv               ereanm     --組織プロファイル拡張マスタ(営業員)
             WHERE   ereanm.route_s_date BETWEEN p_process_date_next_f AND p_process_date_next_l
             AND     hopnm.party_id                = hcanm.party_id
             AND     hopnm.organization_profile_id = ereanm.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
             AND     hopnm.effective_end_date IS NULL
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
             AND     ereanm.extension_id = (SELECT erevw.extension_id
                                            FROM  (SELECT   erea.extension_id           extension_id,
                                                            hop.party_id                party_id
                                                   FROM     hz_organization_profiles    hop,       --組織プロファイルマスタ
                                                            ego_route_agv               erea       --組織プロファイル拡張マスタ(営業員)
                                                   WHERE    erea.route_s_date BETWEEN p_process_date_next_f AND p_process_date_next_l
                                                   AND      hop.organization_profile_id = erea.organization_profile_id
-- 2009/11/23 Ver1.6 add start by Yutaka.Kuboshima
                                                   AND      hop.effective_end_date IS NULL
                                                   ORDER BY erea.route_s_date) erevw
-- 2009/11/23 Ver1.6 add end by Yutaka.Kuboshima
                                            WHERE  hopnm.party_id = erevw.party_id
                                            AND    ROWNUM = 1))   hopero2   --組織プロファイルマスタ(次月ルート)
--
      -- 差分抽出条件を別SQLに移動
      WHERE  (hca.customer_class_code  IN ( cv_cust_cd, cv_ucust_cd, cv_round_cd, cv_plan_cd )
      OR     (hca.customer_class_code  IS NULL
      AND    hp.duns_number_c = cv_mc_sts))
      AND    xca.tax_div            = flvctc.attribute3 (+)        --消費税区分
      AND    hca.party_id           = hopera.party_id (+)          --顧客マスタ           = 組織プロ拡張マスタ：パーティID(営業)
      AND    hca.party_id           = hopera2.party_id (+)         --顧客マスタ           = 組織プロ拡張マスタ：パーティID(次月営業)
      AND    hca.party_id           = hopero.party_id (+)          --顧客マスタ           = 組織プロ拡張マスタ：パーティID(ルート)
      AND    hca.party_id           = hopero2.party_id (+)         --顧客マスタ           = 組織プロ拡張マスタ：パーティID(次月ルート)
      AND    hca.cust_account_id    = xca.customer_id              --顧客マスタ           = 顧客追加情報マスタ：顧客ID
      AND    hca.party_id           = hp.party_id                  --顧客マスタ           = パーティマスタ    ：パーティID
      AND    hps.location_id        = hl.location_id               --パーティサイトマスタ = 事業所マスタ      ：ロケーションID
      AND    hca.cust_account_id    = hcas.cust_account_id         --顧客マスタ           = 顧客所在地マスタ  ：顧客ID
      AND    hcas.cust_acct_site_id = hcsu.cust_acct_site_id       --顧客所在地マスタ     = 使用目的マスタ    ：顧客サイトID
      AND    xca.business_low_type  = flvgs.lookup_code (+)        --LOOKUP_参照(業態小)  = 顧客追加情報マスタ: 業態分類(小分類)
      AND    hcsu.payment_term_id   = rt.term_id (+)               --使用目的マスタ       = 支払条件マスタ    : 支払条件ID
      AND    hcsu.site_use_code     IN ( cv_bill_to, cv_other_to ) --使用目的マスタ(請求先・その他)
      AND    hcsu.status            = cv_a_flag
      AND    hl.location_id         = (SELECT MIN(hpsiv.location_id)
                                      FROM    hz_cust_acct_sites     hcasiv,
                                              hz_party_sites         hpsiv
                                      WHERE   hcasiv.cust_account_id = hca.cust_account_id
                                      AND     hcasiv.party_site_id   = hpsiv.party_site_id
                                      AND     hpsiv.status           = cv_a_flag)      --ロケーションIDの最小値
      AND    hp.party_id            = hps.party_id
      AND    hcas.party_site_id     = hps.party_site_id
      AND    hca.cust_account_id    = p_customer_id;
--
-- 2009/08/24 Ver1.5 modify end by Yutaka.Kuboshima
--
    --ノートカーソル
    CURSOR note_data_cur(p_party_id IN NUMBER)
    IS
      SELECT REPLACE(jnt.notes, CHR(10), cv_date_null)  notes,  --ノート
             jnt.last_update_date             last_update_date  --最終更新日
      FROM   jtf_notes_b   jnb,                                 --ノートマスタ
             jtf_notes_tl  jnt                                  --ノート内容マスタ
      WHERE  jnb.jtf_note_id = jnt.jtf_note_id
      AND    jnb.source_object_id = p_party_id
      AND    jnb.source_object_code = cv_oj_party
      AND    jnt.language = cv_language_ja
      ORDER BY jnb.jtf_note_id DESC;
--
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    -- 拠点検索カーソル
    CURSOR serch_base_cur(p_sale_base_code IN VARCHAR2)
    IS
      SELECT xca.management_base_code management_base_code, -- 管理元拠点コード
             xca.dept_hht_div         dept_hht_div          -- 百貨店HHT区分
      FROM hz_cust_accounts    hca,                         -- 顧客マスタ
           xxcmm_cust_accounts xca                          -- 顧客追加情報マスタ
      WHERE hca.cust_account_id     = xca.customer_id
        AND hca.customer_class_code = cv_base
        AND hca.account_number      = p_sale_base_code;
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
-- 2009/08/24 Ver1.5 add start by Yutaka.Kuboshima
    -- 差分連携対象顧客取得カーソルレコード型
    def_cust_rec def_cust_cur%ROWTYPE;
-- 2009/08/24 Ver1.5 add end by Yutaka.Kuboshima
    -- HHT連携IFデータ作成カーソルレコード型
    cust_data_rec cust_data_cur%ROWTYPE;
    -- ノートカーソルレコード型
    note_data_rec note_data_cur%ROWTYPE;
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
    serch_base_rec serch_base_cur%ROWTYPE;
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
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
    --更新日時の取得
    lv_coordinated_date := TO_CHAR(sysdate, cv_fnd_sytem_date);
--
-- 2009/08/24 Ver1.5 modify start by Yutaka.Kuboshima
-- データ取得処理大幅改修
-- 差分連携される顧客を先に抽出する様に修正
--    --HHT連携IFデータ作成カーソルループ
--    << cust_for_loop >>
--    FOR cust_data_rec IN cust_data_cur
--    LOOP
--      --ノート取り付け
--      << note_for_loop >>
--      FOR  note_data_rec IN note_data_cur(cust_data_rec.party_id)
--      LOOP
--        lv_note_work := TO_CHAR(note_data_rec.last_update_date, cv_fnd_slash_date) || cv_hur_sps || note_data_rec.notes;
--        --ノートが2000バイトに達した時点で処理を中断する。
--        IF ( LENGTHB(lv_note_str || lv_note_work) <= cn_note_lenb ) THEN
--          lv_note_str := lv_note_str || lv_note_work || cv_ver_line;
--        ELSE
--          EXIT;
--        END IF;
--      END LOOP note_for_loop;
--      --縦線削除
--      lv_note_str := SUBSTRB(lv_note_str, 1, LENGTHB(lv_note_str) - 1);
----
---- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
--      -- 売上拠点に設定されている拠点を検索します。
--      OPEN serch_base_cur(cust_data_rec.sale_base_code);
--      FETCH serch_base_cur INTO serch_base_rec;
--      CLOSE serch_base_cur;
--      -- 売上拠点に設定されている百貨店HHT区分'1'の場合
--      IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
--        -- 売上拠点コードを管理元拠点コードに設定
--        cust_data_rec.sale_base_code      := serch_base_rec.management_base_code;
--      END IF;
--      -- 変数初期化
--      serch_base_rec := NULL;
--      -- 前月売上拠点に設定されている拠点を検索します。
--      OPEN serch_base_cur(cust_data_rec.past_sale_base_code);
--      FETCH serch_base_cur INTO serch_base_rec;
--      CLOSE serch_base_cur;
--      -- 前月売上拠点に設定されている百貨店HHT区分'1'の場合
--      IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
--        -- 前月売上拠点コードを管理元拠点コードに設定
--        cust_data_rec.past_sale_base_code := serch_base_rec.management_base_code;
--      END IF;
--      -- 変数初期化
--      serch_base_rec := NULL;
--      -- 予約売上拠点に設定されている拠点を検索します。
--      OPEN serch_base_cur(cust_data_rec.rsv_sale_base_code);
--      FETCH serch_base_cur INTO serch_base_rec;
--      CLOSE serch_base_cur;
--      -- 予約売上拠点に設定されている百貨店HHT区分'1'の場合
--      IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
--        -- 予約売上拠点コードを管理元拠点コードに設定
--        cust_data_rec.rsv_sale_base_code  := serch_base_rec.management_base_code;
--      END IF;
--      -- 変数初期化
--      serch_base_rec := NULL;
---- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
--      -- ===============================
--      -- 出力値設定
--      -- ===============================
---- 2009/06/09 Ver1.4 add start by Yutaka.Kuboshima
--      -- 顧客名称設定
--      lv_customer_name            := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.party_name);
--      -- 顧客名カナ設定
--      lv_customer_name_kana       := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.org_name_phonetic);
--      -- 半角変換不可文字が存在する場合
--      IF (LENGTH(lv_customer_name_kana) <> LENGTHB(lv_customer_name_kana)) THEN
--        lv_customer_name_kana := cv_single_byte_err1;
--      END IF;
--      -- 住所１設定
--      lv_address1                 := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.address1);
--      -- 電話番号設定
--      lv_address_lines_phonetic   := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.address_lines_phonetic);
--      -- 半角変換不可文字が存在する場合
--      IF (LENGTH(lv_address_lines_phonetic) <> LENGTHB(lv_address_lines_phonetic)) THEN
--        lv_address_lines_phonetic := cv_single_byte_err2;
--      END IF;
---- 2009/06/09 Ver1.4 add end by Yutaka.Kuboshima
--      --出力文字列作成
--      lv_output_str := lv_output_str || cv_dqu   || NVL(SUBSTRB(cust_data_rec.account_number, 1, 9), cv_date_null)                    || cv_dqu;  --顧客コード
---- 2009/06/09 Ver1.4 modify start by Yutaka.Kuboshima
----      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.party_name, 1, 50), cv_date_null)             || cv_dqu;  --顧客名称
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_customer_name, 1, 50), cv_date_null)                     || cv_dqu;  --顧客名称
---- 2009/06/09 Ver1.4 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.tax_div, 1, 1), cv_date_null)                 || cv_dqu;  --消費税区分
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.vd_contract_form, 1, 1), cv_date_null)        || cv_dqu;  --ベンダ契約形態
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.mode_div, 1, 1), cv_date_null)                || cv_dqu;  --態様区分
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.final_tran_date, cv_fnd_date), cv_null_code);                       --最終取引日
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.final_call_date, cv_fnd_date), cv_null_code);                       --最終訪問日
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.entrust_dest_flg, 1, 1), cv_date_null)        || cv_dqu;  --預け先判定フラグ
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cv_cdvd_code, 1, 1), cv_date_null)                          || cv_dqu;  --カードベンダ区分
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.vd_cust_class_cd, 1, 1), cv_date_null)        || cv_dqu;  --ＶＤ顧客区分
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.duns_number_c, 1, 2), cv_date_null)           || cv_dqu;  --顧客ステータスコード
--      lv_output_str := lv_output_str || cv_comma || SUBSTRB(NVL(TO_CHAR(cust_data_rec.change_amount), cv_null_code), 1, 5);                       --つり銭
---- 2009/06/09 Ver1.4 modify start by Yutaka.Kuboshima
----      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.org_name_phonetic, 1, 30), cv_date_null)      || cv_dqu;  --顧客名カナ
----      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.address1, 1, 60), cv_date_null)               || cv_dqu;  --住所１
----      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.address_lines_phonetic, 1, 15), cv_date_null) || cv_dqu;  --電話番号
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_customer_name_kana, 1, 30), cv_date_null)                || cv_dqu;  --顧客名カナ
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_address1, 1, 60), cv_date_null)                          || cv_dqu;  --住所１
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_address_lines_phonetic, 1, 15), cv_date_null)            || cv_dqu;  --電話番号
---- 2009/06/09 Ver1.4 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_note_str, 1, 2000), cv_date_null)                        || cv_dqu;  --ノート
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.sale_base_code, 1, 4), cv_date_null)          || cv_dqu;  --売上拠点コード
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.past_sale_base_code, 1, 4), cv_date_null)     || cv_dqu;  --前月売上拠点コード
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.rsv_sale_base_code, 1, 4), cv_date_null)      || cv_dqu;  --予約売上拠点コード
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.rsv_sale_base_act_date, cv_fnd_date), cv_null_code);                --予約売上拠点有効開始日
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.resource_no, 1, 5), cv_date_null)             || cv_dqu;  --担当営業員コード
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.next_resource_no, 1, 5), cv_date_null)        || cv_dqu;  --次月担当営業員コード
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.next_resource_s_date, cv_fnd_month), cv_null_code);                 --次月担当営業員適用月
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.route_no, 1, 7), cv_date_null)                || cv_dqu;  --ルートコード
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.next_route_no, 1, 7), cv_date_null)           || cv_dqu;  --予約ルートコード
--      lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.next_route_s_date, cv_fnd_month), cv_null_code);                    --予約ルートコード適用月
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.customer_class_code, 1, 2), cv_date_null)     || cv_dqu;  --顧客区分
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(lv_coordinated_date, cv_date_null)                                  || cv_dqu;  --更新日時
----
--      --文字列出力
--      BEGIN
--        --CSVファイル出力
--        UTL_FILE.PUT_LINE(io_file_handler,lv_output_str);
--        --コンカレント出力
--        --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_output_str);
--      EXCEPTION
--        WHEN UTL_FILE.WRITE_ERROR THEN  --*** ファイル書き込みエラー ***
--          lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
--                                                cv_write_err_msg,
--                                                cv_ng_word,
--                                                cv_err_cust_code_msg,
--                                                cv_ng_data,
--                                                cust_data_rec.account_number);
--          lv_errbuf  := lv_errmsg;
--        RAISE write_failure_expt;
--      END;
--      --出力件数カウント
--      ln_output_cnt := ln_output_cnt + 1;
----
--      --変数初期化
--      lv_output_str := NULL;
--      lv_note_str   := NULL;
---- 2009/06/09 Ver1.4 add start by Yutaka.Kuboshima
--      lv_customer_name          := NULL;
--      lv_customer_name_kana     := NULL;
--      lv_address1               := NULL;
--      lv_address_lines_phonetic := NULL;
---- 2009/06/09 Ver1.4 add end by Yutaka.Kuboshima
----
--    END LOOP cust_for_loop;
--
--  ↓modify start
    -- パラメータ処理日(FROM)
    -- '000000'を付けて'YYYYMMDDHH24MISS'型に変換
    ld_proc_date_from := TO_DATE(NVL(REPLACE(iv_proc_date_from, cv_hur_sls, cv_date_null), gv_process_date ) || cv_min_time, cv_fnd_max_date);
    -- パラメータ処理日(TO)
    -- '235959'を付けて'YYYYMMDDHH24MISS'型に変換
    ld_proc_date_to   := TO_DATE(NVL(REPLACE(iv_proc_date_to, cv_hur_sls, cv_date_null), gv_process_date ) || cv_max_time, cv_fnd_max_date);
    -- 翌業務月１日
    ld_process_date_next_f := TRUNC(ADD_MONTHS(gd_process_date + 1, 1), cv_trunc_mm);
    -- 翌業務月最終日
    ld_process_date_next_l := LAST_DAY(ADD_MONTHS(gd_process_date + 1, 1));
    --差分対象連携顧客取得カーソルループ
    << def_cust_loop >>
    FOR def_cust_rec IN def_cust_cur(ld_proc_date_from,
                                     ld_proc_date_to)
    LOOP
      --HHT連携IFデータ作成カーソルループ
      << cust_for_loop >>
      FOR cust_data_rec IN cust_data_cur(def_cust_rec.customer_id,
                                         ld_process_date_next_f,
                                         ld_process_date_next_l)
      LOOP
        --ノート取り付け
        << note_for_loop >>
        FOR  note_data_rec IN note_data_cur(cust_data_rec.party_id)
        LOOP
          lv_note_work := TO_CHAR(note_data_rec.last_update_date, cv_fnd_slash_date) || cv_hur_sps || note_data_rec.notes;
          --ノートが2000バイトに達した時点で処理を中断する。
          IF ( LENGTHB(lv_note_str || lv_note_work) <= cn_note_lenb ) THEN
            lv_note_str := lv_note_str || lv_note_work || cv_ver_line;
          ELSE
            EXIT;
          END IF;
        END LOOP note_for_loop;
        --縦線削除
        lv_note_str := SUBSTRB(lv_note_str, 1, LENGTHB(lv_note_str) - 1);
--
        -- 売上拠点に設定されている拠点を検索します。
        OPEN serch_base_cur(cust_data_rec.sale_base_code);
        FETCH serch_base_cur INTO serch_base_rec;
        CLOSE serch_base_cur;
        -- 売上拠点に設定されている百貨店HHT区分'1'の場合
        IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
          -- 売上拠点コードを管理元拠点コードに設定
          cust_data_rec.sale_base_code      := serch_base_rec.management_base_code;
        END IF;
        -- 変数初期化
        serch_base_rec := NULL;
        -- 前月売上拠点に設定されている拠点を検索します。
        OPEN serch_base_cur(cust_data_rec.past_sale_base_code);
        FETCH serch_base_cur INTO serch_base_rec;
        CLOSE serch_base_cur;
        -- 前月売上拠点に設定されている百貨店HHT区分'1'の場合
        IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
          -- 前月売上拠点コードを管理元拠点コードに設定
          cust_data_rec.past_sale_base_code := serch_base_rec.management_base_code;
        END IF;
        -- 変数初期化
        serch_base_rec := NULL;
        -- 予約売上拠点に設定されている拠点を検索します。
        OPEN serch_base_cur(cust_data_rec.rsv_sale_base_code);
        FETCH serch_base_cur INTO serch_base_rec;
        CLOSE serch_base_cur;
        -- 予約売上拠点に設定されている百貨店HHT区分'1'の場合
        IF (NVL(serch_base_rec.dept_hht_div, 0) = cv_dept_div_mult) THEN
          -- 予約売上拠点コードを管理元拠点コードに設定
          cust_data_rec.rsv_sale_base_code  := serch_base_rec.management_base_code;
        END IF;
        -- 変数初期化
        serch_base_rec := NULL;
        -- ===============================
        -- 出力値設定
        -- ===============================
        -- 顧客名称設定
        lv_customer_name            := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.party_name);
        -- 顧客名カナ設定
        lv_customer_name_kana       := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.org_name_phonetic);
        -- 半角変換不可文字が存在する場合
        IF (LENGTH(lv_customer_name_kana) <> LENGTHB(lv_customer_name_kana)) THEN
          lv_customer_name_kana := cv_single_byte_err1;
        END IF;
        -- 住所１設定
        lv_address1                 := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.address1);
        -- 電話番号設定
        lv_address_lines_phonetic   := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.address_lines_phonetic);
        -- 半角変換不可文字が存在する場合
        IF (LENGTH(lv_address_lines_phonetic) <> LENGTHB(lv_address_lines_phonetic)) THEN
          lv_address_lines_phonetic := cv_single_byte_err2;
        END IF;
        --出力文字列作成
        lv_output_str := lv_output_str || cv_dqu   || NVL(SUBSTRB(cust_data_rec.account_number, 1, 9), cv_date_null)                    || cv_dqu;  --顧客コード
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_customer_name, 1, 50), cv_date_null)                     || cv_dqu;  --顧客名称
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.tax_div, 1, 1), cv_date_null)                 || cv_dqu;  --消費税区分
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.vd_contract_form, 1, 1), cv_date_null)        || cv_dqu;  --ベンダ契約形態
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.mode_div, 1, 1), cv_date_null)                || cv_dqu;  --態様区分
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.final_tran_date, cv_fnd_date), cv_null_code);                       --最終取引日
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.final_call_date, cv_fnd_date), cv_null_code);                       --最終訪問日
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.entrust_dest_flg, 1, 1), cv_date_null)        || cv_dqu;  --預け先判定フラグ
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cv_cdvd_code, 1, 1), cv_date_null)                          || cv_dqu;  --カードベンダ区分
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.vd_cust_class_cd, 1, 1), cv_date_null)        || cv_dqu;  --ＶＤ顧客区分
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.duns_number_c, 1, 2), cv_date_null)           || cv_dqu;  --顧客ステータスコード
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(NVL(TO_CHAR(cust_data_rec.change_amount), cv_null_code), 1, 5);                       --つり銭
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_customer_name_kana, 1, 30), cv_date_null)                || cv_dqu;  --顧客名カナ
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_address1, 1, 60), cv_date_null)                          || cv_dqu;  --住所１
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_address_lines_phonetic, 1, 15), cv_date_null)            || cv_dqu;  --電話番号
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(lv_note_str, 1, 2000), cv_date_null)                        || cv_dqu;  --ノート
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.sale_base_code, 1, 4), cv_date_null)          || cv_dqu;  --売上拠点コード
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.past_sale_base_code, 1, 4), cv_date_null)     || cv_dqu;  --前月売上拠点コード
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.rsv_sale_base_code, 1, 4), cv_date_null)      || cv_dqu;  --予約売上拠点コード
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.rsv_sale_base_act_date, cv_fnd_date), cv_null_code);                --予約売上拠点有効開始日
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.resource_no, 1, 5), cv_date_null)             || cv_dqu;  --担当営業員コード
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.next_resource_no, 1, 5), cv_date_null)        || cv_dqu;  --次月担当営業員コード
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.next_resource_s_date, cv_fnd_month), cv_null_code);                 --次月担当営業員適用月
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.route_no, 1, 7), cv_date_null)                || cv_dqu;  --ルートコード
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.next_route_no, 1, 7), cv_date_null)           || cv_dqu;  --予約ルートコード
        lv_output_str := lv_output_str || cv_comma || NVL(TO_CHAR(cust_data_rec.next_route_s_date, cv_fnd_month), cv_null_code);                    --予約ルートコード適用月
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(SUBSTRB(cust_data_rec.customer_class_code, 1, 2), cv_date_null)     || cv_dqu;  --顧客区分
        lv_output_str := lv_output_str || cv_comma || cv_dqu || NVL(lv_coordinated_date, cv_date_null)                                  || cv_dqu;  --更新日時
--
        --文字列出力
        BEGIN
          --CSVファイル出力
          UTL_FILE.PUT_LINE(io_file_handler,lv_output_str);
          --コンカレント出力
          --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_output_str);
        EXCEPTION
          WHEN UTL_FILE.WRITE_ERROR THEN  --*** ファイル書き込みエラー ***
            lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                                  cv_write_err_msg,
                                                  cv_ng_word,
                                                  cv_err_cust_code_msg,
                                                  cv_ng_data,
                                                  cust_data_rec.account_number);
            lv_errbuf  := lv_errmsg;
          RAISE write_failure_expt;
        END;
        --出力件数カウント
        ln_output_cnt := ln_output_cnt + 1;
--
        --変数初期化
        lv_output_str := NULL;
        lv_note_str   := NULL;
        lv_customer_name          := NULL;
        lv_customer_name_kana     := NULL;
        lv_address1               := NULL;
        lv_address_lines_phonetic := NULL;
--
      END LOOP cust_for_loop;
    END LOOP def_cust_loop;
-- 2009/08/24 Ver1.5 modify end by Yutaka.Kuboshima
--
    gn_target_cnt := ln_output_cnt;
    gn_normal_cnt := ln_output_cnt;
--
    --対象データ0件
    IF (ln_output_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_data_msg);
      lv_errbuf := lv_errmsg;
      RAISE no_date_expt;
    END IF;
--
  EXCEPTION
    WHEN no_date_expt THEN                             --*** 対象データなし (正常終了) ***
      ov_retcode := cv_status_normal;
      --対象データが0件の時、件数は0件固定とする
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
      --コンカレント出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
      --ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
    WHEN write_failure_expt THEN                       --*** CSVデータ出力エラー ***
-- 2009/04/13 Ver1.2 add start by Yutaka.Kuboshima
      IF (serch_base_cur%ISOPEN) THEN
        CLOSE serch_base_cur;
      END IF;
-- 2009/04/13 Ver1.2 add end by Yutaka.Kuboshima
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --対象データが0件の時、エラー件数は0件固定とする
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date_from         IN  VARCHAR2,     --コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to           IN  VARCHAR2,     --コンカレント・パラメータ処理日(TO)
    ov_errbuf                 OUT VARCHAR2,     --エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     --リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)     --ユーザー・エラー・メッセージ --# 固定 #
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
    lf_file_handler   UTL_FILE.FILE_TYPE;  --ファイルハンドラ
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
    gn_target_cnt     := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_warn_cnt       := 0;
--
    --パラメータ出力
    --新規登録日又は更新日（開始）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_proc_date_from
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_proc_date_from
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --新規登録日又は更新日（終了）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_proc_date_to
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_proc_date_to
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_proc_date_from   -- コンカレント・パラメータ処理日(FROM)
      ,iv_proc_date_to    -- コンカレント・パラメータ処理日(TO)
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    --初期処理エラー時は処理を中断
    IF (lv_retcode = cv_status_error) THEN
      --エラー処理
      RAISE global_process_expt;
    END IF;
--
    --I/Fファイル名出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxccp_msg_kbn
                    ,iv_name         => cv_file_name_msg
                    ,iv_token_name1  => cv_file_name
                    ,iv_token_value1 => gv_out_file_file
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- ファイルオープン処理(A-2)
    -- ===============================
    file_open(
       lf_file_handler    -- ファイルハンドラ
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 処理対象データ抽出処理(A-3)・抽出情報出力処理(A-4)
    -- ===============================
    output_cust_data(
      iv_proc_date_from        -- コンカレント・パラメータ処理日(FROM)
      ,iv_proc_date_to         -- コンカレント・パラメータ処理日(TO)
      ,lf_file_handler         -- ファイルハンドラ
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    BEGIN
      -- ファイルクローズ処理
      IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(lf_file_handler);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        IF (lv_retcode = cv_status_error) THEN
          -- コンカレントメッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf --エラーメッセージ
          );
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_emsg_file_close,
                                              cv_sqlerrm,
                                              SQLERRM);
        lv_errbuf := lv_errmsg;
        RAISE fclose_err_expt;
    END;
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN fclose_err_expt THEN                           --*** ファイルクローズエラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
    errbuf                    OUT VARCHAR2,     --エラー・メッセージ  --# 固定 #
    retcode                   OUT VARCHAR2,     --リターン・コード    --# 固定 #
    iv_proc_date_from         IN  VARCHAR2,     -- コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to           IN  VARCHAR2      -- コンカレント・パラメータ処理日(TO)
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
      iv_proc_date_from          --コンカレント・パラメータ処理日(FROM)
      ,iv_proc_date_to           --コンカレント・パラメータ処理日(TO)
      ,lv_errbuf                 --エラー・メッセージ           --# 固定 #
      ,lv_retcode                --リターン・コード             --# 固定 #
      ,lv_errmsg                 --ユーザー・エラー・メッセージ --# 固定 #
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
END XXCMM003A19C;
/
