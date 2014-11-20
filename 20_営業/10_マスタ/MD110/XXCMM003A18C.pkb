CREATE OR REPLACE PACKAGE BODY XXCMM003A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A18C(body)
 * Description      : 情報系連携IFデータ作成
 * MD.050           : MD050_CMM_003_A18_情報系連携IFデータ作成
 * Version          : 1.16
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  file_open              ファイルオープン処理(A-2)
 *  output_cust_data       処理対象データ抽出処理(A-3)・CSVファイル出力処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-5 終了処理)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/28    1.0   Takuya Kaihara   新規作成
 *  2009/02/23    1.1   Takuya Kaihara   ファイルクローズ処理修正
 *  2009/03/09    1.2   Takuya Kaihara   プロファイル値共通化
 *  2009/05/12    1.3   Yutaka.Kuboshima 障害T1_0176,T1_0831の対応
 *  2009/05/21    1.4   Yutaka.Kuboshima 障害T1_1131の対応
 *  2009/05/29    1.5   Yutaka.Kuboshima 障害T1_1263の対応
 *  2009/06/09    1.6   Yutaka.Kuboshima 障害T1_1364の対応
 *  2009/09/30    1.7   Yutaka.Kuboshima 障害0001350の対応
 *  2009/11/28    1.8   Hiroshi.Oshida   障害E_本稼動_00151の対応
 *  2009/11/23    1.9   Yutaka.Kuboshima 障害E_本番_00341の対応
 *  2009/12/02    1.10  Yutaka.Kuboshima 障害E_本稼動_00262の対応
 *  2009/12/25    1.11  Yutaka.Kuboshima 障害E_本稼動_00778の対応
 *  2010/01/08    1.12  Yutaka.Kuboshima 障害E_本稼動_00934の対応
 *  2010/02/25    1.13  Yutaka.Kuboshima 障害E_本稼動_01660の対応
 *  2010/04/06    1.14  Yutaka.Kuboshima 障害E_本稼動_01965の対応
 *  2010/09/22    1.15  Shigeto.Niki     障害E_本稼動_02021の対応
 *  2011/01/21    1.16  Shigeto.Niki     障害E_本稼動_02266の対応
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
  no_date_err_expt               EXCEPTION; --対象データ0件
  write_failure_expt             EXCEPTION; --CSVデータ出力エラー
  fclose_err_expt                EXCEPTION; --ファイルクローズエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A18C';      --パッケージ名
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';
  cv_dqu                     CONSTANT VARCHAR2(1)   := '"';                 --文字列括り
--
  cv_trans_date              CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';  --連携日付書式
  cv_fnd_date                CONSTANT VARCHAR2(10)  := 'YYYYMMDD';          --日付書式
  cv_fnd_slash_date          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        --日付書式(YYYY/MM/DD)
--
  --メッセージ
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';  --ファイル名ノート
  cv_no_parameter            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
--
  --エラーメッセージ
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';  --プロファイル取得エラー
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';  --ファイルパス不正エラー
  cv_exist_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';  --CSVファイル存在チェック
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';  --CSVデータ出力エラー
  cv_no_data_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00001';  --対象データ無し
  cv_file_close_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';  --ファイルクローズエラー
  --トークン
  cv_ng_profile              CONSTANT VARCHAR2(10)  := 'NG_PROFILE';        --プロファイル取得失敗トークン
  cv_file_name               CONSTANT VARCHAR2(9)   := 'FILE_NAME';         --ファイル名トークン
  cv_sqlerrm                 CONSTANT VARCHAR2(9)   := 'SQLERRM';           --ファイルクローズ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_process_date VARCHAR2(20);
  gn_nodate_err   NUMBER;
-- 2010/02/25 Ver1.13 E_本稼動_01660 add start by Yutaka.Kuboshima
  gn_seisan_org_id NUMBER;
-- 2010/02/25 Ver1.13 E_本稼動_01660 add end by Yutaka.Kuboshima
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';         --XXCMM:情報系(OUTBOUND)連携用CSVファイル出力先
    cv_out_file_file CONSTANT VARCHAR2(30) := 'XXCMM1_003A18_OUT_FILE_FIL';   --XXCMM: 情報系連携IFデータ作成用CSVファイル名
    cv_invalid_path  CONSTANT VARCHAR2(25) := 'CSV出力ディレクトリ';          --プロファイル取得失敗（ディレクトリ）
    cv_invalid_name  CONSTANT VARCHAR2(20) := 'CSV出力ファイル名';            --プロファイル取得失敗（ファイル名）
--
-- 2010/02/25 Ver1.13 E_本稼動_01660 add start by Yutaka.Kuboshima
    cv_seisan_ou     CONSTANT VARCHAR2(20) := 'ITOE-OU-MFG';                  --営業単位(生産OU)
-- 2010/02/25 Ver1.13 E_本稼動_01660 add start by Yutaka.Kuboshima
    -- *** ローカル変数 ***
    lv_file_chk     BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
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
    --ファイル存在チェック
    UTL_FILE.FGETATTR(gv_out_file_dir, gv_out_file_file, lv_file_chk, ln_file_size, ln_block_size);
    IF (lv_file_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_exist_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    -- 業務日付取得処理
    gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date, cv_fnd_date);
--
-- 2010/02/25 Ver1.13 E_本稼動_01660 add start by Yutaka.Kuboshima
    -- 生産OUの組織ID取得
    SELECT hou.organization_id
    INTO   gn_seisan_org_id
    FROM   hr_operating_units hou
    WHERE  hou.name = cv_seisan_ou
      AND  ROWNUM   = 1
    ;
-- 2010/02/25 Ver1.13 E_本稼動_01660 add end by Yutaka.Kuboshima
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
      --ファイルオープンエラー時、対象件数、エラー件数は1件固定とする
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
   * Description      : 処理対象データ抽出処理(A-3)・CSVファイル出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_cust_data(
    io_file_handler         IN OUT UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
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
    -- *** ローカル定数 ***
    cv_bill_to            CONSTANT VARCHAR2(7)     := 'BILL_TO';                --使用目的・請求先
    cv_ship_to            CONSTANT VARCHAR2(7)     := 'SHIP_TO';                --使用目的・出荷先
    cv_cust_base          CONSTANT VARCHAR2(1)     := '1';                      --顧客区分・拠点
    cv_edi_mult           CONSTANT VARCHAR2(2)     := '18';                     --顧客区分・ＥＤＩチェーン店
    cv_dep_dist           CONSTANT VARCHAR2(2)     := '19';                     --顧客区分・百貨店伝区
    cv_eff_last_date      CONSTANT VARCHAR2(15)    := '99991231';               --有効日_至
    cv_y_flag             CONSTANT VARCHAR2(1)     := 'Y';                      --有効フラグY
    cv_a_flag             CONSTANT VARCHAR2(1)     := 'A';                      --有効フラグA
    cv_language_ja        CONSTANT VARCHAR2(2)     := 'JA';                     --言語(日本語)
    cv_gyotai_syo         CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_SHO';  --業態(小分類)
    cv_gyotai_chu         CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_CHU';  --業態(中分類)
    cv_gyotai_dai         CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_DAI';  --業態(大分類)
    cv_zero_data          CONSTANT VARCHAR2(1)     := '0';                      --サイト左詰
-- 2009/05/12 Ver1.3 障害T1_0176 add start by Yutaka.Kuboshima
    cv_organization       CONSTANT VARCHAR2(30)    := 'ORGANIZATION';           --オブジェクトタイプ(組織)
    cv_yosin_kbn          CONSTANT VARCHAR2(2)     := '13';                     --顧客区分・与信管理先顧客
    cv_urikake_kbn        CONSTANT VARCHAR2(2)     := '14';                     --顧客区分・売掛管理先顧客
-- 2010/02/25 Ver1.13 E_本稼動_01660 delete start by Yutaka.Kuboshima
--    cv_seisan_ou          CONSTANT VARCHAR2(20)    := 'ITOE-OU-MFG';            --営業単位(生産OU)
-- 2010/02/25 Ver1.13 E_本稼動_01660 delete start by Yutaka.Kuboshima
    cv_site_use_code      CONSTANT VARCHAR2(20)    := 'SITE_USE_CODE';          --参照タイプ(使用目的)
    cv_other_to           CONSTANT VARCHAR2(10)    := 'OTHER_TO';               --使用目的・その他
-- 2009/05/12 Ver1.3 障害T1_0176 add end by Yutaka.Kuboshima
--
    cv_comp_code          CONSTANT VARCHAR2(3)     := '001';                    --会社コード
    cv_auto_ex_flag       CONSTANT VARCHAR2(1)     := '2';                      --自動出展フラグ・関連顧客
    cv_ng_word            CONSTANT VARCHAR2(7)     := 'NG_WORD';                --CSV出力エラートークン・NG_WORD
    cv_ng_data            CONSTANT VARCHAR2(7)     := 'NG_DATA';                --CSV出力エラートークン・NG_DATA
    cv_err_cust_code_msg  CONSTANT VARCHAR2(20)    := '顧客コード';             --CSV出力エラー文字列
--
-- 2009/06/09 Ver1.6 add start by Yutaka.Kuboshima
    cv_single_byte_err1   CONSTANT VARCHAR2(30)    := 'ﾊﾝｶｸｴﾗｰ';                --半角エラー時のダミー値1
    cv_single_byte_err2   CONSTANT VARCHAR2(30)    := '99-9999-9999';           --半角エラー時のダミー値2
-- 2009/06/09 Ver1.6 add end by Yutaka.Kuboshima
--
-- 2009/12/25 Ver1.11 E_本稼動_00778 add start by Yutaka.Kuboshima
    cv_kokyaku_kbn        CONSTANT VARCHAR2(2)     := '10';                     --顧客区分・顧客
    cv_mc_kouho_sts       CONSTANT VARCHAR2(2)     := '10';                     --顧客ステータス・MC候補
    cv_mc_sts             CONSTANT VARCHAR2(2)     := '20';                     --顧客ステータス・MC
    cv_sp_kessai_sts      CONSTANT VARCHAR2(2)     := '25';                     --顧客ステータス・SP決裁済
-- 2009/12/25 Ver1.11 E_本稼動_00778 add end by Yutaka.Kuboshima
--
-- 2010/02/25 Ver1.13 E_本稼動_01660 add start by Yutaka.Kuboshima
    cv_uesama_kbn         CONSTANT VARCHAR2(2)     := '12';                     --顧客区分・上様顧客
-- 2010/02/25 Ver1.13 E_本稼動_01660 add end by Yutaka.Kuboshima
    -- *** ローカル変数 ***
    lv_header_str                  VARCHAR2(2000)  := NULL;                     --ヘッダメッセージ格納用変数
    lv_output_str                  VARCHAR2(4095)  := NULL;                     --出力文字列格納用変数
    ln_output_cnt                  NUMBER          := 0;                        --出力件数
    lv_coordinated_date            VARCHAR2(30)    := NULL;                     --連携日付取得
    lv_relate_cust_class           VARCHAR2(30)    := NULL;                     --関連分類
--
    lv_bill_number                 hz_cust_accounts.account_number%TYPE;        --顧客コード(A3-2)
    ln_bill_cust_id                hz_cust_accounts.cust_account_id%TYPE;       --顧客ID(A3-2)
    lv_bill_location               hz_cust_site_uses.location%TYPE;             --事業所(A3-2)
    lv_pay_account_num             hz_cust_accounts.account_number%TYPE;        --顧客コード(A3-3-1)
    ln_pay_cust_account_id         hz_cust_accounts.cust_account_id%TYPE;       --顧客ID(A3-3-1)
    lv_par_account_num             hz_cust_accounts.account_number%TYPE;        --顧客コード(A3-3-2)
    lv_relate_account_num          hz_cust_accounts.account_number%TYPE;        --顧客コード(A3-3-2)
--
-- 2009/06/09 Ver1.6 add start by Yutaka.Kuboshima
    lv_customer_name               VARCHAR2(1500);                               --顧客名称
    lv_customer_name_kana          VARCHAR2(1500);                               --顧客名カナ
    lv_customer_name_ryaku         VARCHAR2(1500);                               --顧客名略称
    lv_state                       VARCHAR2(1500);                               --都道府県
    lv_city                        VARCHAR2(1500);                               --市・区
    lv_address1                    VARCHAR2(1500);                               --住所１
    lv_address2                    VARCHAR2(1500);                               --住所２
    lv_fax                         VARCHAR2(1500);                               --FAX番号
    lv_address_lines_phonetic      VARCHAR2(1500);                              --電話番号
    lv_manager_name                VARCHAR2(1500);                              --店長名
    lv_rest_emp_name               VARCHAR2(1500);                              --担当者休日
    lv_mc_conf_info                VARCHAR2(1500);                              --MC:競合情報
    lv_mc_business_talk_details    VARCHAR2(1500);                              --MC:商談経緯
-- 2009/06/09 Ver1.6 add end by Yutaka.Kuboshima
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 情報系連携IFデータ作成カーソル
    CURSOR cust_data_cur
    IS
      SELECT  hca.account_number                             account_number,              --顧客コード
              hp.party_number                                party_number,                --パーティ番号
              hp.party_name                                  party_name,                  --顧客名称
              hopera.resource_no                             resource_no,                 --担当営業員コード
              xca.sale_base_code                             sale_base_code,              --売上拠点コード
              xca.past_sale_base_code                        past_charge_base_code,       --担当拠点コード(旧)
              hopera.resource_s_date                         resource_s_date,             --担当変更日
              xca.cnvs_business_person                       cnvs_business_person,        --獲得営業員コード
              xca.cnvs_base_code                             cnvs_base_code,              --獲得拠点コード
              xca.intro_business_person                      intro_business_person,       --紹介営業員コード
              xca.intro_base_code                            intro_base_code,             --紹介拠点コード
              hopero.route_no                                route_no,                    --ルートＮＯ
              xca.business_low_type                          business_low_type,           --業態小分類
              flvgc.lookup_code                              lookup_code_c,               --業態中分類
              flvgd.lookup_code                              lookup_code_s,               --業態大分類
              xca.delivery_form                              delivery_form,               --配送形態
              xca.establishment_location                     establishment_location,      --設置ロケーション
              xca.open_close_div                             open_close_div,              --オープン・クローズ
              hp.duns_number_c                               duns_number_c,               --顧客ステータスコード
              hp.attribute5                                  mc_importance_deg,           --ＭＣ重要度
              hp.attribute4                                  mc_hot_deg,                  --ＭＣＨＯＴ度
              LPAD(TO_CHAR(rtmin.due_months_forward),2,cv_zero_data)  due_months_forward, --サイト
              hca.creation_date                              creation_date,               --登録日
              xca.start_tran_date                            start_tran_date,             --取引開始日
              xca.new_point                                  new_point,                   --新規ポイント
              xca.stop_approval_reason                       stop_approval_reason,        --中止理由区分
              xca.stop_approval_date                         stop_approval_date,          --中止年月日
              hca.account_name                               account_name,                --顧客名略称
              hp.organization_name_phonetic                  organization_name_phonetic,  --顧客名カナ
              xca.receiv_base_code                           receiv_base_code,            --入金拠点コード
              xca.bill_base_code                             bill_base_code,              --請求拠点(部門)コード
              rtsum.name                                     termtl_name,                 --支払条件(締日・払日・サイト)
              xca.delivery_chain_code                        delivery_chain_code,         --納品チェーンＣＤ
              xca.sales_chain_code                           sales_chain_code,            --販売チェーンＣＤ
              xca.intro_chain_code1                          intro_chain_code1,           --紹介用１
              xca.intro_chain_code2                          intro_chain_code2,           --紹介用２
              xca.policy_chain_code                          policy_chain_code,           --営業政策用
              xca.store_code                                 store_code,                  --店舗コード
              xca.tax_div                                    tax_div,                     --消費税区分
-- 2009/10/01 Ver1.7 障害0001350 modify start by Yutaka.Kuboshima
--              hcsu.attribute1                                invoice_class,               --請求書発行区分
              xca.invoice_printing_unit                      invoice_printing_unit,       --請求書印刷単位
-- 2009/10/01 Ver1.7 障害0001350 modify end by Yutaka.Kuboshima
              hcsu.attribute7                                invoice_process_class,       --請求処理区分
              hca.account_number                             corporate_number,            --法人コード
              xmc.base_code                                  base_code,                   --本部担当拠点コード
              xmc.credit_limit                               credit_limit,                --与信限度枠
              xca.vist_target_div                            vist_target_div,             --訪問対象区分
              hca.customer_class_code                        customer_class_code,         --顧客区分
              xca.cnvs_date                                  cnvs_date,                   --顧客獲得日
              xca.final_tran_date                            final_tran_date,             --最終取引日
              xca.final_call_date                            final_call_date,             --最終訪問日
              xca.change_amount                              change_amount,               --釣銭
              xca.torihiki_form                              torihiki_form,               --取引形態
              hl.postal_code                                 postal_code,                 --郵便番号
              hl.state                                       state,                       --都道府県
              hl.city                                        city,                        --市・区
              hl.address1                                    address1,                    --住所1
              hl.address2                                    address2,                    --住所2
              hl.address3                                    address3,                    --地区コード
              hl.address_lines_phonetic                      address_lines_phonetic,      --電話番号
              xca.cust_store_name                            cust_store_name,             --顧客店舗名称
              xca.torihikisaki_code                          torihikisaki_code,           --取引先コード
              xca.industry_div                               industry_div,                --業種
              xca.selling_transfer_div                       selling_transfer_div,        --売上実績振替
              xca.center_edi_div                             center_edi_div,              --センターEDI区分
              xca.past_sale_base_code                        past_sale_base_code,         --前月売上拠点コード
              xca.rsv_sale_base_act_date                     rsv_sale_base_act_date,      --予約売上拠点有効開始日
              xca.rsv_sale_base_code                         rsv_sale_base_code,          --予約売上拠点コード
              xca.delivery_base_code                         delivery_base_code,          --納品拠点コード
              xca.sales_head_base_code                       sales_head_base_code,        --販売先本部担当拠点
              xca.vendor_machine_number                      vendor_machine_number,       --自動販売機番号
              xca.rate                                       rate,                        --消化ＶＤ掛率
              xca.conclusion_day1                            conclusion_day1,             --消化計算締め日１
              xca.conclusion_day2                            conclusion_day2,             --消化計算締め日２
              xca.conclusion_day3                            conclusion_day3,             --消化計算締め日３
              xca.contractor_supplier_code                   contractor_supplier_code,    --契約者仕入先コード
              xca.bm_pay_supplier_code1                      bm_pay_supplier_code1,       --紹介者ＢＭ支払仕入先コード１
              xca.bm_pay_supplier_code2                      bm_pay_supplier_code2,       --紹介者ＢＭ支払仕入先コード２
              xca.wholesale_ctrl_code                        wholesale_ctrl_code,         --問屋管理コード
              xca.ship_storage_code                          ship_storage_code,           --出荷元保管場所(EDI)
              xca.chain_store_code                           chain_store_code,            --チェーン店コード(EDI)
              xca.delivery_order                             delivery_order,              --配送順(EDI）
              xca.edi_district_code                          edi_district_code,           --EDI地区コード(EDI)
              xca.edi_district_name                          edi_district_name,           --EDI地区名(EDI）
              xca.edi_district_kana                          edi_district_kana,           --EDI地区名カナ(EDI)
              xca.tsukagatazaiko_div                         tsukagatazaiko_div,          --通過在庫型区分(EDI)
              xca.handwritten_slip_div                       handwritten_slip_div,        --EDI手書伝票伝送区分
              xca.deli_center_code                           deli_center_code,            --EDI納品センターコード
              xca.deli_center_name                           deli_center_name,            --EDI納品センター名
              xca.edi_forward_number                         edi_forward_number,          --EDI伝送追番
-- 2009/05/12 Ver1.3 障害T1_0176 modify start by Yutaka.Kuboshima
--              arvw.name                                      receipt_methods_name,        --支払方法名
--              hcsu.site_use_code                             site_use_code,               --使用目的
              TO_MULTI_BYTE(arvw.name)                       receipt_methods_name,        --支払方法名
              flvsuc.meaning                                 site_use_code,               --使用目的
-- 2009/05/12 Ver1.3 障害T1_0176 modify end by Yutaka.Kuboshima
              rtsum2.name                                    payment_term2,               --第2支払条件
              rtsum3.name                                    payment_term3,               --第3支払条件
              hcsu.attribute4                                ar_invoice_code,             --売掛コード１(請求書)
              hcsu.attribute5                                ar_location_code,            --売掛コード２(事業所)
              hcsu.attribute6                                ar_others_code,              --売掛コード３(その他)
              hcsu.attribute8                                invoice_sycle,               --請求書発行サイクル
              hp.attribute1                                  manager_name,                --店長名
              hp.attribute3                                  rest_emp_name,               --担当者休日
              hp.attribute6                                  mc_conf_info,                --MC:競合情報
              hp.attribute7                                  mc_business_talk_details,    --MC:商談経緯
              hps.party_site_number                          party_site_number,           --パーティサイト番号
              xca.established_site_name                      established_site_name,       --設置先名
              hp.attribute2                                  emp_number,                  --社員数
              hopero.route_s_date                            route_s_date,                --適用開始日(ルートＮＯ)
              xca.latitude                                   latitude,                    --緯度
              xca.longitude                                  longitude,                   --経度
              xmc.decide_div                                 decide_div,                  --判定区分
              xca.new_point_div                              new_point_div,               --新規ポイント区分
              xca.receiv_discount_rate                       receiv_discount_rate,        --入金値引率
              xca.vist_untarget_date                         vist_untarget_date,          --顧客対象外変更日
              xca.party_representative_name                  party_representative_name,   --代表者名（相手先）
              xca.party_emp_name                             party_emp_name,              --担当者（相手先）
              xca.operation_div                              operation_div,               --オペレーション区分
              xca.child_dept_shop_code                       child_dept_shop_code,        --百貨店伝区コード
              xca.past_customer_status                       past_customer_status,        --前月顧客ステータス
              xca.past_final_tran_date                       past_final_tran_date,        --前月最終取引日
              hca.cust_account_id                            cust_account_id,             --顧客ID
-- 2009/05/12 Ver1.3 障害T1_0831 add start by Yutaka.Kuboshima
              hp.party_id                                    party_id,                    --パーティID
              hl.address4                                    address4,                    --FAX番号
              hcp.cons_inv_flag                              cons_inv_flag,               --一括請求書発行フラグ
              TO_MULTI_BYTE(aah.hierarchy_name)              hierarchy_name,              --取引－自動消込基準セット名
              xmc.approval_date                              approval_date,               --決裁日付
              xmc.tdb_code                                   tbd_code,                    --TDBコード
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 delete start by Yutaka.Kuboshima
--              hcsu.price_list_id                             price_list_id,               --価格表
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 delete end by Yutaka.Kuboshima
              hcsu.tax_header_level_flag                     tax_header_level_flag,       --税金-計算
              hcsu.tax_rounding_rule                         tax_rounding_rule,           --税金-端数処理
              xca.cust_update_flag                           cust_update_flag,            --新規/更新フラグ
              xca.edi_item_code_div                          edi_item_code_div,           --EDI連携品目コード区分
              xca.edi_chain_code                             edi_chain_code,              --チェーン店コード(EDI)【親レコード用】
              xca.parnt_dept_shop_code                       parnt_dept_shop_code,        --百貨店伝区コード【親レコード用】
              xca.card_company_div                           card_company_div,            --カード会社区分
              xca.card_company                               card_company,                --カード会社コード
-- 2009/05/12 Ver1.3 障害T1_0831 add end by Yutaka.Kuboshima
-- 2009/09/30 Ver1.7 障害0001350 add start by Yutaka.Kuboshima
              xca.invoice_code                               invoice_code,                --請求書用コード
              xca.enclose_invoice_code                       enclose_invoice_code         --統括請求書用コード
-- 2009/09/30 Ver1.7 障害0001350 add end by Yutaka.Kuboshima
--
-- 2010/09/22 Ver1.15 障害E_本稼動_02021 add start by Shigeto.Niki
             ,xca.store_cust_code                            store_cust_code              --店舗営業用顧客コード
-- 2010/09/22 Ver1.15 障害E_本稼動_02021 add end by Shigeto.Niki
--
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 add start by Yutaka.Kuboshima
             ,hcas.cust_acct_site_id                         cust_acct_site_id            --顧客所在地ID
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 add end by Yutaka.Kuboshima
--
-- 2010/01/08 Ver1.12 E_本稼動_00934 add start by Yutaka.Kuboshima
             ,flvgd2.lookup_code                             business_high_type_kari      --業態大分類(仮)
             ,flvgc2.lookup_code                             business_mid_type_kari       --業態中分類(仮)
             ,hp.attribute8                                  business_low_type_kari       --業態小分類(仮)
-- 2010/01/08 Ver1.12 E_本稼動_00934 add end by Yutaka.Kuboshima
--
      FROM    hz_cust_accounts              hca,                      --顧客マスタ
              hz_locations                  hl,                       --顧客事業所マスタ
              hz_cust_site_uses             hcsu,                     --顧客使用目的マスタ
              hz_parties                    hp,                       --パーティマスタ
              hz_party_sites                hps,                      --パーティサイトマスタ
              xxcmm_cust_accounts           xca,                      --顧客追加情報マスタ
              xxcmm_mst_corporate           xmc,                      --顧客法人情報マスタ
              hz_cust_acct_sites            hcas,                     --顧客所在地マスタ
              ra_terms                      rtsum,
              ra_terms                      rtsum2,
              ra_terms                      rtsum3,
-- 2009/05/12 Ver1.3 障害T1_0831 add start by Yutaka.Kuboshima
              hz_customer_profiles          hcp,                      --顧客プロファイルマスタ
              ar_autocash_hierarchies       aah,                      --自動入金階層マスタ
-- 2009/05/12 Ver1.3 障害T1_0831 add end by Yutaka.Kuboshima
              (SELECT lookup_code           lookup_code,
                      attribute1            attribute1
              FROM    fnd_lookup_values flvs
              WHERE   language     = cv_language_ja
              AND     lookup_type  = cv_gyotai_syo
              AND     enabled_flag = cv_y_flag)    flvgs,            --クイックコード_参照コード(業態(小分類))
              (SELECT lookup_code           lookup_code,
                      attribute1            attribute1
              FROM    fnd_lookup_values flvs
              WHERE   language     = cv_language_ja
              AND     lookup_type  = cv_gyotai_chu
              AND     enabled_flag = cv_y_flag)    flvgc,            --クイックコード_参照コード(業態(中分類))
              (SELECT lookup_code           lookup_code
              FROM    fnd_lookup_values flvs
              WHERE   language     = cv_language_ja
              AND     lookup_type  = cv_gyotai_dai
              AND     enabled_flag = cv_y_flag)    flvgd,            --クイックコード_参照コード(業態(大分類))
--
-- 2010/01/08 Ver1.12 E_本稼動_00934 add start by Yutaka.Kuboshima
              (SELECT flvs.lookup_code           lookup_code,
                      flvs.attribute1            attribute1
              FROM    fnd_lookup_values flvs
              WHERE   flvs.language     = cv_language_ja
              AND     flvs.lookup_type  = cv_gyotai_syo
              AND     flvs.enabled_flag = cv_y_flag)    flvgs2,      --クイックコード_参照コード(業態(小分類))_業態小分類(仮)用
              (SELECT flvs.lookup_code           lookup_code,
                      flvs.attribute1            attribute1
              FROM    fnd_lookup_values flvs
              WHERE   flvs.language     = cv_language_ja
              AND     flvs.lookup_type  = cv_gyotai_chu
              AND     flvs.enabled_flag = cv_y_flag)    flvgc2,      --クイックコード_参照コード(業態(中分類))_業態小分類(仮)用
              (SELECT flvs.lookup_code           lookup_code
              FROM    fnd_lookup_values flvs
              WHERE   flvs.language     = cv_language_ja
              AND     flvs.lookup_type  = cv_gyotai_dai
              AND     flvs.enabled_flag = cv_y_flag)    flvgd2,      --クイックコード_参照コード(業態(大分類))_業態小分類(仮)用
-- 2010/01/08 Ver1.12 E_本稼動_00934 add end by Yutaka.Kuboshima
--
-- 2009/05/12 Ver1.3 障害T1_0176 add start by Yutaka.Kuboshima
              (SELECT lookup_code           lookup_code,
                      meaning               meaning
              FROM    fnd_lookup_values flvs
              WHERE   language     = cv_language_ja
              AND     lookup_type  = cv_site_use_code
              AND     enabled_flag = cv_y_flag)    flvsuc,           --クイックコード_参照コード(使用目的)
-- 2009/05/12 Ver1.3 障害T1_0176 add end by Yutaka.Kuboshima
              (SELECT armvw.name            name,
                     rcrmvw.customer_id     customer_id
              FROM   ar_receipt_methods            armvw,    --AR支払方法マスタ
                     ra_cust_receipt_methods       rcrmvw,   --支払方法情報マスタ
                     hz_cust_site_uses             hcsuvw    --顧客使用目的マスタ
              WHERE  (rcrmvw.primary_flag = cv_y_flag
                     AND TO_DATE(gv_process_date, cv_fnd_slash_date)
                     BETWEEN rcrmvw.start_date
                     AND NVL(rcrmvw.end_date, TO_DATE(cv_eff_last_date, cv_fnd_slash_date)))
              AND    armvw.receipt_method_id = rcrmvw.receipt_method_id         --AR支払方法 = 支払方法情報：支払方法ID
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 add start by Yutaka.Kuboshima
              AND    hcsuvw.site_use_code    = cv_bill_to
              AND    hcsuvw.status           = cv_a_flag
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 add end by Yutaka.Kuboshima
              AND    hcsuvw.site_use_id      = rcrmvw.site_use_id)  arvw,       --使用目的   = 支払方法情報：顧客所在地使用ID
--
             (SELECT   hopviw1.party_id              party_id,
                       ereaviw.resource_no           resource_no,
                       ereaviw.resource_s_date       resource_s_date
-- 2009/05/12 Ver1.3 障害T1_0831 modify start by Yutaka.Kuboshima
--              FROM     hz_cust_accounts              hcaviw1,   --顧客マスタ
              FROM     hz_parties                    hcaviw1,   --パーティマスタ
-- 2009/05/12 Ver1.3 障害T1_0831 modify end by Yutaka.Kuboshima
                       hz_organization_profiles      hopviw1,   --組織プロファイルマスタ
                       ego_resource_agv              ereaviw    --組織プロファイル拡張マスタ(営業員)
              WHERE   (TO_DATE(gv_process_date, cv_fnd_slash_date)
                       BETWEEN NVL(ereaviw.resource_s_date, TO_DATE(gv_process_date, cv_fnd_slash_date))
                       AND     NVL(ereaviw.resource_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date)))
              AND      hcaviw1.party_id  = hopviw1.party_id
              AND      hopviw1.organization_profile_id = ereaviw.organization_profile_id
-- 2009/11/23 Ver1.9 add start by Yutaka.Kuboshima
              AND      hopviw1.effective_end_date IS NULL
-- 2009/11/23 Ver1.9 add end by Yutaka.Kuboshima
              AND      ereaviw.extension_id            = (SELECT   erearow1.extension_id
                                                          FROM     hz_organization_profiles      hoprow1,       --組織プロファイルマスタ
                                                                   ego_resource_agv              erearow1       --組織プロファイル拡張マスタ(営業員)
                                                          WHERE   (TO_DATE(gv_process_date, cv_fnd_slash_date)
                                                                   BETWEEN NVL(erearow1.resource_s_date, TO_DATE(gv_process_date, cv_fnd_slash_date))
                                                                   AND     NVL(erearow1.resource_e_date, TO_DATE(cv_eff_last_date, cv_fnd_date)))
                                                          AND      hcaviw1.party_id            = hoprow1.party_id
                                                          AND      hoprow1.organization_profile_id = erearow1.organization_profile_id
-- 2009/11/23 Ver1.9 add start by Yutaka.Kuboshima
                                                          AND      hoprow1.effective_end_date IS NULL
-- 2009/11/23 Ver1.9 add end by Yutaka.Kuboshima
                                                          AND      ROWNUM = 1 ))  hopera, --組織プロファイル(担当営業員)
--
             (SELECT hopviw2.party_id              party_id,
                     eroaviw.route_no              route_no,
                     eroaviw.route_s_date          route_s_date
-- 2009/05/12 Ver1.3 障害T1_0831 modify start by Yutaka.Kuboshima
--              FROM     hz_cust_accounts              hcaviw2,   --顧客マスタ
              FROM     hz_parties                    hcaviw2,   --パーティマスタ
-- 2009/05/12 Ver1.3 障害T1_0831 modify end by Yutaka.Kuboshima
                     ego_route_agv                 eroaviw,                --組織プロファイル拡張マスタ(ルート)
                     hz_organization_profiles      hopviw2                 --組織プロファイルマスタ
              WHERE   (TO_DATE(gv_process_date, cv_fnd_slash_date)
                      BETWEEN NVL(eroaviw.route_s_date, TO_DATE(gv_process_date, cv_fnd_slash_date))
                      AND     NVL(eroaviw.route_e_date, TO_DATE(cv_eff_last_date, cv_fnd_slash_date)))
              AND     hcaviw2.party_id  = hopviw2.party_id
              AND     hopviw2.organization_profile_id = eroaviw.organization_profile_id
-- 2009/11/23 Ver1.9 add start by Yutaka.Kuboshima
              AND     hopviw2.effective_end_date IS NULL
-- 2009/11/23 Ver1.9 add end by Yutaka.Kuboshima
              AND     eroaviw.extension_id            = (SELECT  eroarow2.extension_id
                                                         FROM    ego_route_agv                 eroarow2,               --組織プロファイル拡張マスタ(ルート)
                                                                 hz_organization_profiles      hoprow2                 --組織プロファイルマスタ
                                                         WHERE   (TO_DATE(gv_process_date, cv_fnd_slash_date)
                                                                 BETWEEN NVL(eroarow2.route_s_date, TO_DATE(gv_process_date, cv_fnd_slash_date))
                                                                 AND     NVL(eroarow2.route_e_date, TO_DATE(cv_eff_last_date, cv_fnd_slash_date)))
                                                         AND     hcaviw2.party_id  = hoprow2.party_id
-- 2009/11/23 Ver1.9 add start by Yutaka.Kuboshima
                                                         AND     hoprow2.effective_end_date IS NULL
-- 2009/11/23 Ver1.9 add end by Yutaka.Kuboshima
                                                         AND     hoprow2.organization_profile_id = eroarow2.organization_profile_id
                                                         AND     ROWNUM = 1 ))  hopero, --組織プロファイル(ルート)
--
              (SELECT MIN(rtlmon.due_months_forward)  due_months_forward,
                     rtmon.term_id                    term_id
              FROM   ra_terms              rtmon,                         --支払条件マスタ
                     ra_terms_lines        rtlmon                         --支払条件明細マスタ
              WHERE rtmon.term_id             = rtlmon.term_id            --支払条件 = 支払条件明細：支払条件ID
              GROUP BY rtmon.term_id) rtmin
--
-- 2009/05/12 Ver1.3 障害T1_0176 modify start by Yutaka.Kuboshima
--      WHERE   (hca.customer_class_code NOT IN ( cv_cust_base, cv_edi_mult, cv_dep_dist )  --顧客区分(拠点,チェーン,百貨店以外)
--      OR      hca.customer_class_code IS NULL)                             --顧客区分NULL
      WHERE   (hca.customer_class_code <> cv_cust_base                     --顧客区分(拠点)以外
      OR      hca.customer_class_code IS NULL)                             --顧客区分NULL
-- 2009/05/12 Ver1.3 障害T1_0176 modify end by Yutaka.Kuboshima
      AND     hca.cust_account_id         = xca.customer_id (+)            --顧客 = 顧客追加：顧客ID
      AND     hca.cust_account_id         = xmc.customer_id (+)            --顧客 = 顧客法人：顧客ID
      AND     flvgs.attribute1            = flvgc.lookup_code (+)          --クイックS = クイックC
      AND     flvgc.attribute1            = flvgd.lookup_code (+)          --クイックC = クイックD
      AND     xca.business_low_type       = flvgs.lookup_code (+)          --顧客追加：業態分類 = クイックS
      AND     hca.cust_account_id         = arvw.customer_id (+)           --顧客 = 支払方法情報：顧客ID
      AND     hca.party_id                = hopera.party_id (+)            --顧客 = 組織：パーティID(営業)
      AND     hca.party_id                = hopero.party_id (+)            --顧客 = 組織：パーティID(ルート)
      AND     hca.party_id                = hp.party_id                    --顧客 = パーティ：パーティID
      AND     hps.location_id             = hl.location_id                 --パーティサイト = 事業所：ロケーションID
      AND     hcas.cust_acct_site_id      = hcsu.cust_acct_site_id         --所在地 = 使用目的：顧客サイトID
      AND     hp.party_id                 = hps.party_id                   --パーティ = パーティサイト：パーティID
      AND     hps.party_site_id           = hcas.party_site_id             --パーティサイト = 顧客所在地：パーティサイトID
      AND     hca.cust_account_id         = hcas.cust_account_id           --顧客 = 顧客所在地：顧客ID
-- 2009/05/12 Ver1.3 障害T1_0176 modify start by Yutaka.Kuboshima
--      AND     hcsu.site_use_code          = cv_bill_to                     --使用目的 = 請求先
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify start by Yutaka.Kuboshima
-- 顧客区分'10','12','14'の場合、請求先
-- 上記以外の顧客区分の場合、その他を抽出条件とするよう修正
--      AND     hcsu.site_use_code         IN (cv_bill_to, cv_other_to)      --使用目的 = 請求先 OR その他
      AND  ( (NVL(hca.customer_class_code, cv_kokyaku_kbn) IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn)
          AND hcsu.site_use_code          = cv_bill_to)
        OR   (NVL(hca.customer_class_code, cv_kokyaku_kbn) NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn)
          AND hcsu.site_use_code          = cv_other_to) )
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify end by Yutaka.Kuboshima
-- 2009/05/12 Ver1.3 障害T1_0176 modify end by Yutaka.Kuboshima
      AND     hcsu.payment_term_id        = rtmin.term_id (+)              --使用目的 = 支払条件：支払条件,支払条件ID
      AND     hcsu.payment_term_id        = rtsum.term_id (+)              --支払条件(締日・払日・サイト)
      AND     hcsu.attribute2             = rtsum2.term_id (+)             --第２支払条件
      AND     hcsu.attribute3             = rtsum3.term_id (+)             --第３支払条件
      AND     hl.location_id              = (SELECT MIN(hpsiv.location_id)
                                            FROM   hz_cust_acct_sites hcasiv,
                                                   hz_party_sites     hpsiv
                                            WHERE  hcasiv.cust_account_id = hca.cust_account_id
                                            AND    hcasiv.party_site_id   = hpsiv.party_site_id
                                            AND    hpsiv.status             = cv_a_flag)      --ロケーションIDの最小値
-- 2009/05/12 Ver1.3 障害T1_0176 add start by Yutaka.Kuboshima
      AND     hcsu.site_use_id            = hcp.site_use_id(+)
      AND     hcp.autocash_hierarchy_id   = aah.autocash_hierarchy_id(+)
      AND     hcsu.site_use_code          = flvsuc.lookup_code(+)
-- 2009/05/12 Ver1.3 障害T1_0176 add end by Yutaka.Kuboshima
-- 2009/05/21 Ver1.4 障害T1_1131 add start by Yutaka.Kuboshima
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify start by Yutaka.Kuboshima
-- 使用目的の有効フラグの抽出条件を変更
--      AND     hcsu.status                 = cv_a_flag
      AND     hcsu.site_use_id            = (SELECT hcsu3.site_use_id
                                             FROM   (SELECT hcsu2.site_use_id
                                                           ,hcsu2.cust_acct_site_id
                                                           ,hcsu2.site_use_code
                                                     FROM   hz_cust_site_uses  hcsu2
                                                     ORDER BY hcsu2.status) hcsu3
                                             WHERE  hcsu.cust_acct_site_id = hcsu3.cust_acct_site_id
                                               AND  hcsu.site_use_code     = hcsu3.site_use_code
                                               AND  ROWNUM            = 1
                                            )
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify end by Yutaka.Kuboshima
-- 2009/05/21 Ver1.4 障害T1_1131 add end by Yutaka.Kuboshima
--
-- 2010/01/08 Ver1.12 E_本稼動_00934 add start by Yutaka.Kuboshima
      AND     flvgs2.attribute1           = flvgc2.lookup_code (+)         --クイックS2 = クイックC2
      AND     flvgc2.attribute1           = flvgd2.lookup_code (+)         --クイックC2 = クイックD2
      AND     hp.attribute8               = flvgs2.lookup_code (+)         --パーティ：業態小分類(仮) = クイックS2
-- 2010/01/08 Ver1.12 E_本稼動_00934 add end by Yutaka.Kuboshima
--
      ORDER BY hca.account_number;
--
    -- 顧客一括更新情報カーソルレコード型
    cust_data_rec cust_data_cur%ROWTYPE;
--
-- 2009/05/12 Ver1.3 障害T1_0176 add start by Yutaka.Kuboshima
    -- 関連顧客取得カーソル
    CURSOR cust_acct_relate_cur(p_cust_account_id IN NUMBER)
    IS
      SELECT hcar.attribute1    attribute1,
             hca.account_number account_number,
             hp.party_name      party_name
      FROM hz_cust_accounts hca,
           hz_parties hp,
           hz_cust_acct_relate hcar
      WHERE hca.party_id                 = hp.party_id
        AND hca.cust_account_id          = hcar.cust_account_id
        AND hcar.related_cust_account_id = p_cust_account_id
        AND hca.customer_class_code      = cv_urikake_kbn
        AND hcar.status                  = cv_a_flag
        AND ROWNUM = 1;
    -- 関連顧客情報カーソルレコード型
    cust_acct_relate_rec cust_acct_relate_cur%ROWTYPE;
--
    -- 生産OU側顧客所在地取得カーソル
    CURSOR mfg_cust_acct_site_cur(p_cust_account_id IN NUMBER)
    IS
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify start by Yutaka.Kuboshima
--      SELECT hcasa.attribute18 attribute18
--      FROM hz_cust_acct_sites_all hcasa,
--           hr_operating_units hou
--      WHERE hcasa.org_id          = hou.organization_id
--        AND hcasa.cust_account_id = p_cust_account_id
--        AND hou.name              = cv_seisan_ou
--        AND ROWNUM = 1;
      SELECT hcasa.attribute18 attribute18
      FROM   hz_cust_acct_sites_all hcasa
      WHERE hcasa.org_id          = gn_seisan_org_id
        AND hcasa.cust_account_id = p_cust_account_id
        AND ROWNUM = 1;
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify end by Yutaka.Kuboshima
    -- 生産OU側顧客所在地取得カーソルレコード型
    mfg_cust_acct_site_rec mfg_cust_acct_site_cur%ROWTYPE;
--
    -- パーティ関連取得カーソル
    CURSOR hz_relationships_cur(p_party_id IN NUMBER)
    IS
      SELECT hca.account_number account_number,
             hp.party_name      party_name
      FROM hz_cust_accounts hca,
           hz_parties hp,
           hz_relationships hr
      WHERE hca.party_id            = hp.party_id
        AND hp.party_id             = hr.subject_id
-- 2010/02/25 Ver1.13 E_本稼動_01660 add start by Yutaka.Kuboshima
        AND hr.subject_type         = cv_organization
-- 2010/02/25 Ver1.13 E_本稼動_01660 add end by Yutaka.Kuboshima
        AND hr.object_type          = cv_organization
        AND hr.object_id            = p_party_id
        AND hca.customer_class_code = cv_yosin_kbn
        AND hr.status               = cv_a_flag
        AND ROWNUM = 1;
    -- パーティ関連取得カーソルレコード型
    hz_relationships_rec hz_relationships_cur%ROWTYPE;
-- 2009/05/12 Ver1.3 障害T1_0176 add end by Yutaka.Kuboshima
--
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 add start by Yutaka.Kuboshima
    -- 請求先に紐付く価格表を出力していたが、
    -- 正しくは出荷先に紐付く価格表を出力するのが正しい
    --
    -- 価格表取得カーソル
    CURSOR price_list_cur(p_cust_acct_site_id IN NUMBER)
    IS
      SELECT price_list_id price_list_id
      FROM   hz_cust_acct_sites hcas
            ,hz_cust_site_uses hcsu
      WHERE  hcas.cust_acct_site_id = hcsu.cust_acct_site_id
        AND  hcsu.site_use_code     = cv_ship_to
        AND  hcsu.status            = cv_a_flag
        AND  hcas.cust_acct_site_id = p_cust_acct_site_id
        AND  ROWNUM = 1;
    -- 価格表取得カーソルレコード型
    price_list_rec price_list_cur%ROWTYPE;
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 add end by Yutaka.Kuboshima
--
-- 2009/12/25 Ver1.11 E_本稼動_00778 add start by Yutaka.Kuboshima
    -- 担当営業員所属拠点取得カーソル
    CURSOR resource_location_code_cur(p_employee_number IN VARCHAR2)
    IS
      SELECT paaf.ass_attribute5 location_code
      FROM   per_all_people_f papf
            ,per_all_assignments_f paaf
            ,per_periods_of_service ppos
      WHERE  papf.person_id = paaf.person_id
        AND  paaf.period_of_service_id = ppos.period_of_service_id
        AND  papf.effective_start_date = ppos.date_start
        AND  ppos.actual_termination_date IS NULL
        AND  papf.employee_number = p_employee_number;
    -- 担当営業員所属拠点取得カーソルレコード型
    resource_location_code_rec resource_location_code_cur%ROWTYPE;
-- 2009/12/25 Ver1.11 E_本稼動_00778 add end by Yutaka.Kuboshima
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --連携日付の取得
    lv_coordinated_date := TO_CHAR(sysdate, cv_trans_date);
--
    --情報系連携IFデータカーソルループ
    << cust_for_loop >>
    FOR cust_data_rec IN cust_data_cur
    LOOP
      -- ===============================
      -- 請求先顧客の取得
      -- ===============================
      BEGIN
        --請求先の顧客を取得
        SELECT hca.account_number                 account_number,             --顧客コード
               hca.cust_account_id                cust_account_id,            --顧客ID
               hcsu.location                      location                    --事業所
        INTO   lv_bill_number,
               ln_bill_cust_id,
               lv_bill_location
        FROM   hz_cust_accounts                   hca,                        --顧客マスタ
               hz_cust_acct_sites                 hcas,                       --顧客所在地マスタ
               hz_cust_site_uses                  hcsu,                       --顧客使用目的マスタ
               hz_party_sites                     hps                         --パーティサイトマスタ
-- 2010/02/25 Ver1.13 E_本稼動_01660 delete start by Yutaka.Kuboshima
--               hz_locations                       hl                          --顧客事業所マスタ
-- 2010/02/25 Ver1.13 E_本稼動_01660 delete end by Yutaka.Kuboshima
        WHERE  hcas.cust_acct_site_id = hcsu.cust_acct_site_id                --顧客サイトID
        AND    hca.cust_account_id    = hcas.cust_account_id                  --顧客ID
        AND    hcsu.site_use_code     = cv_bill_to
-- 2010/02/25 Ver1.13 E_本稼動_01660 delete start by Yutaka.Kuboshima
--        AND    hps.location_id        = hl.location_id
-- 2010/02/25 Ver1.13 E_本稼動_01660 delete end by Yutaka.Kuboshima
        AND    hps.party_site_id      = hcas.party_site_id
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify start by Yutaka.Kuboshima
--
--        AND    hcsu.site_use_id = (SELECT hcsun.bill_to_site_use_id
--                                  FROM    hz_cust_accounts        hcan,       --顧客マスタ
--                                          hz_cust_acct_sites      hcasn,      --顧客所在地マスタ
--                                          hz_cust_site_uses       hcsun,      --顧客使用目的マスタ
--                                          hz_party_sites          hpsn,       --パーティサイトマスタ
--                                          hz_locations            hln         --顧客事業所マスタ
--                                  WHERE   hcan.account_number     = cust_data_rec.account_number
--                                  AND     hcasn.cust_acct_site_id = hcsun.cust_acct_site_id
--                                  AND     hcan.cust_account_id    = hcasn.cust_account_id
--                                  AND     hcsun.site_use_code     = cv_ship_to
--                                  AND     hpsn.location_id        = hln.location_id
--                                  AND     hpsn.party_site_id      = hcasn.party_site_id
---- 2009/05/21 Ver1.4 障害T1_1131 add start by Yutaka.Kuboshima
--                                  AND     hcsun.status            = cv_a_flag
---- 2009/05/21 Ver1.4 障害T1_1131 add end by Yutaka.Kuboshima
--                                  AND     hln.location_id         = (SELECT MIN(hpsiva.location_id)
--                                                                    FROM    hz_cust_acct_sites hcasiva,
--                                                                            hz_party_sites     hpsiva
--                                                                    WHERE  hcasiva.cust_account_id = hcan.cust_account_id
--                                                                    AND    hcasiva.party_site_id   = hpsiva.party_site_id
--                                                                    AND    hpsiva.status           = cv_a_flag))      --ロケーションIDの最小値
        AND    hcsu.site_use_id       = (SELECT hcsun.bill_to_site_use_id
                                         FROM   hz_cust_acct_sites hcasn    --顧客所在地マスタ
                                               ,hz_cust_site_uses  hcsun    --顧客使用目的マスタ
                                         WHERE  hcasn.cust_acct_site_id = hcsun.cust_acct_site_id
                                           AND  hcasn.cust_acct_site_id = cust_data_rec.cust_acct_site_id
                                           AND  hcsun.site_use_code     = cv_ship_to
                                           AND  hcsun.status            = cv_a_flag)
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify end by Yutaka.Kuboshima
-- 2009/05/21 Ver1.4 障害T1_1131 add start by Yutaka.Kuboshima
        AND    hcsu.status            = cv_a_flag
-- 2009/05/21 Ver1.4 障害T1_1131 add end by Yutaka.Kuboshima
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify start by Yutaka.Kuboshima
--        AND     hl.location_id         = (SELECT MIN(hpsiv.location_id)
--                                         FROM   hz_cust_acct_sites hcasiv,
--                                                hz_party_sites     hpsiv
--                                         WHERE  hcasiv.cust_account_id = hca.cust_account_id
--                                         AND    hcasiv.party_site_id   = hpsiv.party_site_id
--                                         AND    hpsiv.status             = cv_a_flag);      --ロケーションIDの最小値
        AND    ROWNUM                 = 1
        ;
-- 2010/02/25 Ver1.13 E_本稼動_01660 modify start by Yutaka.Kuboshima
--
      EXCEPTION
        --*** 対象レコードなしエラー ***
        WHEN NO_DATA_FOUND THEN
          lv_bill_number   := NULL;
          ln_bill_cust_id  := NULL;
          lv_bill_location := NULL;
        WHEN TOO_MANY_ROWS THEN
          RAISE;
        WHEN OTHERS THEN
          RAISE;
      END;
--
      --
      -- ===============================
      -- 請求先顧客の取得
      -- ===============================
      BEGIN
        --３．入金先の顧客を取得します。
        --①顧客コード・顧客IDを抽出します。
        SELECT hca.account_number                 account_number,                           --顧客コード
               hca.cust_account_id                cust_account_id,                          --顧客ID
               hcara.attribute1                   attribute1                                --関連顧客
        INTO   lv_pay_account_num,
               ln_pay_cust_account_id,
               lv_relate_cust_class
        FROM   hz_cust_accounts                   hca,                                      --顧客マスタ
               hz_cust_acct_relate                hcara                                     --関連顧客マスタ
        WHERE  hcara.related_cust_account_id = cust_data_rec.cust_account_id
        AND    hcara.cust_account_id         = ln_bill_cust_id
        AND    hca.cust_account_id           = hcara.cust_account_id
-- 2009/11/28 Ver1.8 障害 本稼動_00151 add start by Hiroshi.Oshida
        AND    hcara.status                  = cv_a_flag;
-- 2009/11/28 Ver1.8 障害 本稼動_00151 add end by Hiroshi.Oshida
        
      EXCEPTION
        --*** 対象レコードなしエラー ***
        WHEN NO_DATA_FOUND THEN
          lv_pay_account_num     := NULL;
          ln_pay_cust_account_id := NULL;
          lv_relate_cust_class   := NULL;
        WHEN TOO_MANY_ROWS THEN
          RAISE;
        WHEN OTHERS THEN
          RAISE;
      END;
--
      IF (lv_pay_account_num IS NOT NULL) THEN
        BEGIN
          --② ①で顧客IDが取得できた場合、親の顧客IDを抽出します。
          SELECT hca.account_number                 account_number                            --顧客コード
          INTO   lv_par_account_num
          FROM   hz_cust_accounts                   hca,                                      --顧客マスタ
                 hz_cust_acct_relate                hcara                                     --関連顧客マスタ
          WHERE  hcara.related_cust_account_id = ln_pay_cust_account_id
          AND    hca.cust_account_id           = hcara.cust_account_id
          AND    hcara.attribute1              = cv_auto_ex_flag
-- 2009/11/28 Ver1.8 障害 本稼動_00151 add start by Hiroshi.Oshida
          AND    hcara.status                  = cv_a_flag
-- 2009/11/28 Ver1.8 障害 本稼動_00151 add end by Hiroshi.Oshida
-- 2010/02/25 Ver1.13 E_本稼動_01660 add start by Yutaka.Kuboshima
          AND    ROWNUM                        = 1
          ;
-- 2010/02/25 Ver1.13 E_本稼動_01660 add end by Yutaka.Kuboshima
        EXCEPTION
          --*** 対象レコードなしエラー ***
          WHEN NO_DATA_FOUND THEN
            lv_par_account_num := NULL;
          WHEN TOO_MANY_ROWS THEN
            RAISE;
          WHEN OTHERS THEN
            RAISE;
        END;
--
        IF (lv_par_account_num IS NOT NULL) THEN
          lv_pay_account_num := lv_par_account_num;
        ELSIF (lv_par_account_num IS NULL AND NVL(lv_relate_cust_class, '0') <> cv_auto_ex_flag) THEN
          lv_pay_account_num := NULL;
        END IF;
      END IF;
--
-- 2009/05/12 Ver1.3 障害T1_0176 add start by Yutaka.Kuboshima
      -- 関連顧客情報取得
      OPEN cust_acct_relate_cur(cust_data_rec.cust_account_id);
      FETCH cust_acct_relate_cur INTO cust_acct_relate_rec;
      CLOSE cust_acct_relate_cur;
      -- 生産OU側顧客所在地情報取得
      OPEN mfg_cust_acct_site_cur(cust_data_rec.cust_account_id);
      FETCH mfg_cust_acct_site_cur INTO mfg_cust_acct_site_rec;
      CLOSE mfg_cust_acct_site_cur;
      -- パーティ関連情報取得
      OPEN hz_relationships_cur(cust_data_rec.party_id);
      FETCH hz_relationships_cur INTO hz_relationships_rec;
      CLOSE hz_relationships_cur;
-- 2009/05/12 Ver1.3 障害T1_0176 add end by Yutaka.Kuboshima
--
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 add start by Yutaka.Kuboshima
      -- 価格表取得
      OPEN price_list_cur(cust_data_rec.cust_acct_site_id);
      FETCH price_list_cur INTO price_list_rec;
      CLOSE price_list_cur;
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 add end by Yutaka.Kuboshima
--
      -- ===============================
      -- 出力値設定
      -- ===============================
--
--
-- 2009/06/09 Ver1.6 add start by Yutaka.Kuboshima
      -- 顧客名称設定
      lv_customer_name            := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.party_name);
      -- 顧客名カナ設定
      lv_customer_name_kana       := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.organization_name_phonetic);
      -- 半角変換不可文字が存在する場合
      IF (LENGTH(lv_customer_name_kana) <> LENGTHB(lv_customer_name_kana)) THEN
        lv_customer_name_kana := cv_single_byte_err1;
      END IF;
      -- 顧客名略称設定
      lv_customer_name_ryaku      := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.account_name);
      -- 都道府県設定
      lv_state                    := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.state);
      -- 市・区設定
      lv_city                     := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.city);
      -- 住所１設定
      lv_address1                 := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.address1);
      -- 住所２設定
      lv_address2                 := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.address2);
      -- FAX設定
      lv_fax                      := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.address4);
      -- 半角変換不可文字が存在する場合
      IF (LENGTH(lv_fax) <> LENGTHB(lv_fax)) THEN
        lv_fax := cv_single_byte_err2;
      END IF;
      -- 電話番号設定
      lv_address_lines_phonetic   := xxccp_common_pkg.chg_double_to_single_byte(cust_data_rec.address_lines_phonetic);
      -- 半角変換不可文字が存在する場合
      IF (LENGTH(lv_address_lines_phonetic) <> LENGTHB(lv_address_lines_phonetic)) THEN
        lv_address_lines_phonetic := cv_single_byte_err2;
      END IF;
      -- 店長名設定
      lv_manager_name             := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.manager_name);
      -- 担当者休日設定
      lv_rest_emp_name            := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.rest_emp_name);
      -- MC:競合情報設定
      lv_mc_conf_info             := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.mc_conf_info);
      -- MC:商談経緯設定
      lv_mc_business_talk_details := xxcso_util_common_pkg.conv_multi_byte(cust_data_rec.mc_business_talk_details);
-- 2009/06/09 Ver1.6 add end by Yutaka.Kuboshima
--
-- 2009/12/25 Ver1.11 E_本稼動_00778 add start by Yutaka.Kuboshima
      -- 顧客区分設定
      -- 顧客区分がNULLの場合
      IF (cust_data_rec.customer_class_code IS NULL) THEN
        -- 顧客区分に'10'(顧客)をセット
        cust_data_rec.customer_class_code := cv_kokyaku_kbn;
      END IF;
      -- 顧客ステータスが'10'(MC候補),'20'(MC),'25'(SP決裁済)の場合
      IF (cust_data_rec.duns_number_c IN (cv_mc_kouho_sts, cv_mc_sts, cv_sp_kessai_sts)) THEN
        -- 獲得拠点設定
        -- 獲得拠点がNULLの場合
        IF (cust_data_rec.cnvs_base_code IS NULL) THEN
          -- 売上拠点がNULLの場合
          IF (cust_data_rec.sale_base_code IS NULL) THEN
            -- 担当営業員の所属拠点を取得
            OPEN resource_location_code_cur(cust_data_rec.resource_no);
            FETCH resource_location_code_cur INTO resource_location_code_rec;
            CLOSE resource_location_code_cur;
            -- 獲得拠点に担当営業員の所属拠点をセット
            cust_data_rec.cnvs_base_code := resource_location_code_rec.location_code;
          ELSE
            -- 獲得拠点に売上拠点をセット
            cust_data_rec.cnvs_base_code := cust_data_rec.sale_base_code;
          END IF;
        END IF;
        -- 獲得営業員設定
        -- 獲得営業員がNULLの場合
        IF (cust_data_rec.cnvs_business_person IS NULL) THEN
          -- 獲得営業員に担当営業員をセット
          cust_data_rec.cnvs_business_person := cust_data_rec.resource_no;
        END IF;
-- 2010/01/08 Ver1.12 E_本稼動_00934 add start by  Yutaka.Kuboshima
        -- 業態設定
        -- 業態小分類がNULLの場合
        IF (cust_data_rec.business_low_type IS NULL) THEN
          -- 業態小分類に業態小分類(仮)をセット
          cust_data_rec.business_low_type := cust_data_rec.business_low_type_kari;
          -- 業態中分類に業態中分類(仮)をセット
          cust_data_rec.lookup_code_c     := cust_data_rec.business_mid_type_kari;
          -- 業態大分類に業態大分類(仮)をセット
          cust_data_rec.lookup_code_s     := cust_data_rec.business_high_type_kari;
        END IF;
-- 2010/01/08 Ver1.12 E_本稼動_00934 add end by  Yutaka.Kuboshima
      END IF;
-- 2009/12/25 Ver1.11 E_本稼動_00778 add end by Yutaka.Kuboshima
      --出力文字列作成
      lv_output_str := cv_dqu        || cv_comp_code || cv_dqu;                                                                    --会社コード
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.account_number, 1, 9);                                   --顧客コード
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.party_number, 1, 10);                                    --パーティ番号
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.party_name, 1, 100)                || cv_dqu;  --顧客名称
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_customer_name, 1, 100)                        || cv_dqu;  --顧客名称
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.resource_no, 1, 5)                 || cv_dqu;  --担当営業員コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.sale_base_code, 1, 4)              || cv_dqu;  --売上拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.past_charge_base_code, 1, 4)       || cv_dqu;  --担当拠点コード(旧)
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.resource_s_date, cv_fnd_date);                           --担当変更日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cnvs_business_person, 1, 5)        || cv_dqu;  --獲得営業員コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cnvs_base_code, 1, 4)              || cv_dqu;  --獲得拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.intro_business_person, 1, 5)       || cv_dqu;  --紹介営業員コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.intro_base_code, 1, 4)             || cv_dqu;  --紹介拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.route_no, 1, 7)                    || cv_dqu;  --ルートNo
-- 2009/05/29 Ver1.5 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.business_low_type, 1, 2)           || cv_dqu;  --業態大分類
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.lookup_code_s, 1, 2)               || cv_dqu;  --業態大分類
-- 2009/05/29 Ver1.5 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.lookup_code_c, 1, 2)               || cv_dqu;  --業態中分類
-- 2009/05/29 Ver1.5 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.lookup_code_s, 1, 2)               || cv_dqu;  --業態小分類
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.business_low_type, 1, 2)           || cv_dqu;  --業態小分類
-- 2009/05/29 Ver1.5 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.delivery_form, 1, 1)               || cv_dqu;  --配送形態
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.establishment_location, 1, 2)      || cv_dqu;  --設置ロケーション
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.open_close_div, 1, 1)              || cv_dqu;  --オープン・クローズ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.duns_number_c, 1, 2)               || cv_dqu;  --顧客ステータスコード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.mc_Importance_deg, 1, 1)           || cv_dqu;  --ＭＣ重要度
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.mc_hot_deg, 1, 1)                  || cv_dqu;  --ＭＣＨＯＴ度
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.due_months_forward, 1, 2)          || cv_dqu;  --サイト
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.creation_date, cv_fnd_date);                             --登録日
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.start_tran_date, cv_fnd_date);                           --取引開始日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || cv_auto_ex_flag                                          || cv_dqu;  --自動出展フラグ
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.new_point), 1, 3);                               --新規ポイント
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.stop_approval_reason, 1, 1)        || cv_dqu;  --中止理由区分
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.stop_approval_date, cv_fnd_date);                        --中止年月日
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.account_name, 1, 80)               || cv_dqu;  --顧客名略称
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.organization_name_phonetic, 1, 50) || cv_dqu;  --顧客名カナ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_customer_name_ryaku, 1, 80)                   || cv_dqu;  --顧客名略称
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_customer_name_kana, 1, 50)                    || cv_dqu;  --顧客名カナ
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_pay_account_num, 1, 9);                                             --売掛コードＡ（入金顧客）
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_bill_number, 1, 9);                                                 --売掛コードＢ（請求顧客）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.receiv_base_code, 1, 4)            || cv_dqu;  --入金拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.bill_base_code, 1, 4)              || cv_dqu;  --請求拠点（部門）コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.termtl_name, 1, 8)                 || cv_dqu;  --支払条件（締日・払日・サイト）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.delivery_chain_code, 1, 9)         || cv_dqu;  --納品チェーンＣＤ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.sales_chain_code, 1, 9)            || cv_dqu;  --販売チェーンＣＤ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.intro_chain_code1, 1, 30)          || cv_dqu;  --紹介用１
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.intro_chain_code2, 1, 30)          || cv_dqu;  --紹介用２
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.policy_chain_code, 1, 30)          || cv_dqu;  --営業政策用
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.store_code, 1, 10)                 || cv_dqu;  --店舗コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tax_div, 1, 1)                     || cv_dqu;  --消費税区分
-- 2009/10/01 Ver1.7 障害0001350 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_class, 1, 1)               || cv_dqu;  --請求書発行区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_printing_unit, 1, 1) || cv_dqu;        --請求書印刷単位
-- 2009/10/01 Ver1.7 障害0001350 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_process_class, 1, 1)       || cv_dqu;  --請求処理区分
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.corporate_number, 1, 9);                                 --法人コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.base_code, 1, 4)                   || cv_dqu;  --本部担当拠点コード
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.credit_limit), 1, 9);                            --与信限度枠
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.vist_target_div, 1, 1)             || cv_dqu;  --訪問対象区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.customer_class_code, 1, 2)         || cv_dqu;  --顧客区分
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.cnvs_date, cv_fnd_date);                                 --顧客獲得日
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.final_tran_date, cv_fnd_date);                           --最終取引日
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.final_call_date, cv_fnd_date);                           --最終訪問日
-- 2011/01/21 Ver1.16 障害E_本稼動_02266 modify start by Shigeto.Niki
--      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.change_amount), 1, 4);                           --釣銭
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.change_amount), 1, 10);                          --釣銭
-- 2011/01/21 Ver1.16 障害E_本稼動_02266 modify end by Shigeto.Niki
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.torihiki_form, 1, 1)               || cv_dqu;  --取引形態
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.postal_code, 1, 7)                 || cv_dqu;  --郵便番号
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.state, 1, 30)                      || cv_dqu;  --都道府県
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.city, 1, 30)                       || cv_dqu;  --市・区
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address1, 1, 240)                  || cv_dqu;  --住所1
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address2, 1, 240)                  || cv_dqu;  --住所2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_state, 1, 30)                                 || cv_dqu;  --都道府県
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_city, 1, 30)                                  || cv_dqu;  --市・区
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_address1, 1, 240)                             || cv_dqu;  --住所1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_address2, 1, 240)                             || cv_dqu;  --住所2
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address3, 1, 5)                    || cv_dqu;  --地区コード
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address_lines_phonetic, 1, 30)     || cv_dqu;  --電話番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_address_lines_phonetic, 1, 30)                || cv_dqu;  --電話番号
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cust_store_name, 1, 30)            || cv_dqu;  --顧客店舗名称
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.torihikisaki_code, 1, 8)           || cv_dqu;  --取引先コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.industry_div, 1, 2)                || cv_dqu;  --業種
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.selling_transfer_div, 1, 1)        || cv_dqu;  --売上実績振替
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.center_edi_div, 1, 1)              || cv_dqu;  --センターEDI区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.past_sale_base_code, 1, 4)         || cv_dqu;  --前月売上拠点コード
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.rsv_sale_base_act_date, cv_fnd_date);                    --予約売上拠点有効開始日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.rsv_sale_base_code, 1, 4)          || cv_dqu;  --予約売上拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.delivery_base_code, 1, 4)          || cv_dqu;  --納品拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.sales_head_base_code, 1, 4)        || cv_dqu;  --販売先本部担当拠点
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.vendor_machine_number, 1, 30)      || cv_dqu;  --自動販売機番号
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.rate), 1, 4);                                    --消化ＶＤ掛率
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.conclusion_day1), 1, 2);                         --消化計算締め日１
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.conclusion_day2), 1, 2);                         --消化計算締め日２
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.conclusion_day3), 1, 2);                         --消化計算締め日３
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.contractor_supplier_code, 1, 9)    || cv_dqu;  --契約者仕入先コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.bm_pay_supplier_code1, 1, 9)       || cv_dqu;  --紹介者ＢＭ支払仕入先コード１
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.bm_pay_supplier_code2, 1, 9)       || cv_dqu;  --紹介者ＢＭ支払仕入先コード２
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.wholesale_ctrl_code, 1, 9)         || cv_dqu;  --問屋管理コード（旧事業所マスタの事業所）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.ship_storage_code, 1, 10)          || cv_dqu;  --出荷元保管場所（EDI）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.chain_store_code, 1, 4)            || cv_dqu;  --チェーン店コード（EDI）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.delivery_order, 1, 14)             || cv_dqu;  --配送順（EDI）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_district_code, 1, 8)           || cv_dqu;  --EDI地区コード（EDI）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_district_name, 1, 40)          || cv_dqu;  --EDI地区名（EDI）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_district_kana, 1, 20)          || cv_dqu;  --EDI地区名カナ（EDI）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tsukagatazaiko_div, 1, 2)          || cv_dqu;  --通過在庫型区分（EDI）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.handwritten_slip_div, 1, 1)        || cv_dqu;  --EDI手書伝票伝送区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.deli_center_code, 1, 8)            || cv_dqu;  --EDI納品センターコード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.deli_center_name, 1, 20)           || cv_dqu;  --EDI納品センター名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_forward_number, 1, 2)          || cv_dqu;  --EDI伝送追番
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.receipt_methods_name, 1, 50)       || cv_dqu;  --支払方法名
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_bill_location, 1, 9);                                               --請求先事業所
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.site_use_code, 1, 20)              || cv_dqu;  --使用目的
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.payment_term2, 1, 8)               || cv_dqu;  --第2支払条件
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.payment_term3, 1, 8)               || cv_dqu;  --第3支払条件
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.ar_invoice_code, 1, 12)            || cv_dqu;  --売掛コード１（請求書）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.ar_location_code, 1, 12)           || cv_dqu;  --売掛コード２（事業所）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.ar_others_code, 1, 12)             || cv_dqu;  --売掛コード３（その他）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_sycle, 1, 1)               || cv_dqu;  --請求書発行サイクル
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.manager_name, 1, 150)              || cv_dqu;  --店長名
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.rest_emp_name, 1, 150)             || cv_dqu;  --担当者休日
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.mc_conf_info, 1, 150)              || cv_dqu;  --MC:競合情報
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.mc_business_talk_details, 1, 150)  || cv_dqu;  --MC:商談経緯
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_manager_name, 1, 150)                         || cv_dqu;  --店長名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_rest_emp_name, 1, 150)                        || cv_dqu;  --担当者休日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_mc_conf_info, 1, 150)                         || cv_dqu;  --MC:競合情報
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_mc_business_talk_details, 1, 150)             || cv_dqu;  --MC:商談経緯
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.party_site_number, 1, 32);                               --パーティサイト番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.established_site_name, 1, 30)      || cv_dqu;  --設置先名
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.emp_number, 1, 15);                                      --社員数
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.route_s_date, cv_fnd_date);                              --適用開始日（ルートＮＯ）
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.latitude, 1, 10);                                        --緯度
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.longitude, 1, 10);                                       --経度
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.decide_div, 1, 1)                  || cv_dqu;  --判定区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.new_point_div, 1, 1)               || cv_dqu;  --新規ポイント区分
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(TO_CHAR(cust_data_rec.receiv_discount_rate), 1, 4);                         --入金値引率
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.vist_untarget_date, cv_fnd_date);                        --顧客対象外変更日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.party_representative_name, 1, 20)  || cv_dqu;  --代表者名（相手先）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.party_emp_name, 1, 20)             || cv_dqu;  --担当者（相手先）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.operation_div, 1, 1)               || cv_dqu;  --オペレーション区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.child_dept_shop_code, 1, 3)        || cv_dqu;  --百貨店伝区コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.past_customer_status, 1, 2)        || cv_dqu;  --前月顧客ステータス
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.past_final_tran_date, cv_fnd_date);                      --前月最終取引日
-- 2009/05/12 Ver1.3 障害T1_0176 add start by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(hz_relationships_rec.party_name, 1, 100) || cv_dqu;          --与信管理先顧客名称
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(hz_relationships_rec.account_number, 1, 9) || cv_dqu;        --与信管理先顧客番号
-- 2009/06/09 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.address4, 1, 30) || cv_dqu;                    --住所4(FAX番号)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_fax, 1, 30) || cv_dqu;                                    --住所4(FAX番号)
-- 2009/06/09 Ver1.6 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cons_inv_flag, 1, 1) || cv_dqu;                --一括請求書発行フラグ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.hierarchy_name, 1, 30) || cv_dqu;              --取引－自動消込基準セット名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(mfg_cust_acct_site_rec.attribute18, 1, 9) || cv_dqu;         --配送先コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_acct_relate_rec.party_name, 1, 100) || cv_dqu;          --関連顧客名称(親)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_acct_relate_rec.account_number, 1, 9) || cv_dqu;        --関連顧客番号(親)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_acct_relate_rec.attribute1, 1, 1) || cv_dqu;            --関連分類
      lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.approval_date, cv_fnd_date);                             --決裁日付
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tbd_code, 1, 12) || cv_dqu;                    --TDBコード
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(TO_CHAR(cust_data_rec.price_list_id), 1, 50) || cv_dqu;      --価格表
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(TO_CHAR(price_list_rec.price_list_id), 1, 50) || cv_dqu;      --価格表
-- 2009/12/02 Ver1.10 障害E_本稼動_00262 modify end by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tax_header_level_flag, 1, 1) || cv_dqu;        --税金－計算
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.tax_rounding_rule, 1, 7) || cv_dqu;            --税金－端数処理
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.cust_update_flag, 1, 1) || cv_dqu;             --新規/更新フラグ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_item_code_div, 1, 1) || cv_dqu;            --EDI連携品目コード区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.edi_chain_code, 1, 4) || cv_dqu;               --チェーン店コード(EDI)【親レコード用】
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.parnt_dept_shop_code, 1, 3) || cv_dqu;         --百貨店伝区コード【親レコード用】
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.card_company_div, 1, 1) || cv_dqu;             --カード会社区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.card_company, 1, 9) || cv_dqu;                 --カード会社コード
-- 2009/05/12 Ver1.3 障害T1_0176 add end by Yutaka.Kuboshima
-- 2009/09/30 Ver1.7 障害0001350 add start by Yutaka.Kuboshima
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.invoice_code, 1, 9) || cv_dqu;                 --請求書用コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(cust_data_rec.enclose_invoice_code, 1, 9) || cv_dqu;         --統括請求書用コード
-- 2009/09/30 Ver1.7 障害0001350 add end by Yutaka.Kuboshima
-- 2010/09/22 Ver1.15 障害E_本稼動_02021 add start by Shigeto.Niki
      lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.store_cust_code, 1, 9);                                  --店舗営業用顧客コード
-- 2010/09/22 Ver1.15 障害E_本稼動_02021 add end by Shigeto.Niki
      lv_output_str := lv_output_str || cv_comma || lv_coordinated_date;                                                           --連携日時
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
      lv_output_str           := NULL;
-- 2009/05/12 Ver1.3 障害T1_0176 add start by Yutaka.Kuboshima
      cust_acct_relate_rec    := NULL;
      mfg_cust_acct_site_rec  := NULL;
      hz_relationships_rec    := NULL;
-- 2009/05/12 Ver1.3 障害T1_0176 add end by Yutaka.Kuboshima
-- 2009/06/09 Ver1.6 add start by Yutaka.Kuboshima
      lv_customer_name            := NULL;
      lv_customer_name_kana       := NULL;
      lv_customer_name_ryaku      := NULL;
      lv_state                    := NULL;
      lv_city                     := NULL;
      lv_address1                 := NULL;
      lv_address2                 := NULL;
      lv_fax                      := NULL;
      lv_address_lines_phonetic   := NULL;
      lv_manager_name             := NULL;
      lv_rest_emp_name            := NULL;
      lv_mc_conf_info             := NULL;
      lv_mc_business_talk_details := NULL;
-- 2009/06/09 Ver1.6 add end by Yutaka.Kuboshima
--
-- 2010/04/06 Ver1.14 E_本稼動_01965 add start by Yutaka.Kuboshima
      price_list_rec              := NULL;
      resource_location_code_rec  := NULL;
-- 2010/04/06 Ver1.14 E_本稼動_01965 add end by Yutaka.Kuboshima
--
    END LOOP cust_for_loop;
--
    gn_target_cnt := ln_output_cnt;
    gn_normal_cnt := ln_output_cnt;
--
    --対象データ0件エラー
    IF (ln_output_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_data_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE no_date_err_expt;
    END IF;
--
  EXCEPTION
    WHEN no_date_err_expt THEN                         --*** 対象データなしエラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      gn_nodate_err := 1;
      --対象データが0件の時、エラー件数は0件固定とする
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
    WHEN write_failure_expt THEN                       --*** CSVデータ出力エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --CSVデータ出力エラー時、対象件数、エラー件数は0件固定とする
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_nodate_err := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
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
       lf_file_handler         -- ファイルハンドラ
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
                                              cv_file_close_err_msg,
                                              cv_sqlerrm,
                                              SQLERRM);
        lv_errbuf := lv_errmsg;
        RAISE fclose_err_expt;
    END;
    IF (lv_retcode = cv_status_error) THEN
      -- 対象データなしエラーの場合、ファイルを削除します
      IF ( gn_nodate_err = 1 ) THEN
        -- ファイル削除
        UTL_FILE.FREMOVE(gv_out_file_dir, gv_out_file_file);
      END IF;
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
/*
    --ファイルクローズ処理
    IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
      --ファイルクローズ
      UTL_FILE.FCLOSE(lf_file_handler);
    END IF;
    IF (lv_retcode = cv_status_error) THEN
      --エラー処理
      RAISE global_process_expt;
    END IF;
*/
--
  EXCEPTION
    WHEN fclose_err_expt THEN                         --*** ファイルクローズエラー ***
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
    retcode                   OUT VARCHAR2      --リターン・コード    --# 固定 #
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
    -- 入力パラメータなしメッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => gv_xxccp_msg_kbn
                 ,iv_name         => cv_no_parameter
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf                 --エラー・メッセージ           --# 固定 #
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
END XXCMM003A18C;
/
