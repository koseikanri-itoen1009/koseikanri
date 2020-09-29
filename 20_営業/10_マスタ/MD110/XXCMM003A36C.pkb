CREATE OR REPLACE PACKAGE BODY xxcmm003a36c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A36C(body)
 * Description      : 各諸マスタ連携IFデータ作成
 * MD.050           : MD050_CMM_003_A36_各諸マスタ連携IFデータ作成
 * Version          : 1.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  file_open              ファイルオープン処理(A-2)
 *  write_csv              CSVファイル出力処理(A-4)
 *  output_mst_data        処理対象データ抽出処理(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-5 終了処理)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/12    1.0   Akinori Takeshita   新規作成
 *  2009/03/09    1.1   Yutaka.Kuboshima    ファイル出力先のプロファイルの変更
 *  2009/04/02    1.2   Yutaka.Kuboshima    障害T1_0182、T1_0254の対応
 *  2009/04/15    1.3   Yutaka.Kuboshima    障害T1_0577の対応
 *  2009/05/28    1.4   Yutaka.Kuboshima    障害T1_1244の対応
 *  2009/06/03    1.5   Yutaka.Kuboshima    障害T1_1321の対応
 *  2009/06/30    1.6   Yutaka.Kuboshima    統合テスト障害0000328の対応
 *  2009/07/13    1.7   Yutaka.Kuboshima    統合テスト障害0000655,0000656の対応
 *  2009/09/30    1.8   Yutaka.Kuboshima    統合テスト障害0001350の対応
 *  2018/04/27    1.9   Haruka.Mori         E_本稼動_15041の対応
 *  2019/01/25    1.10  Yasuhiro.Shoji      E_本稼動_15490の対応
 *  2019/07/16    1.11  Kawaguch.Takuya     E_本稼動_15472の対応
 *  2020/08/21    1.12  Nobuo.Koyama        E_本稼動_15904の対応
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
-- 2009/04/02 Ver1.2 add start by Yutaka.Kuboshima
  gd_process_date  DATE;
-- 2009/04/02 Ver1.2 add end by Yutaka.Kuboshima
-- 2018/04/27 Ver1.9 add start by Haruka.Mori
  gn_bks_id        NUMBER;
-- 2018/04/27 Ver1.9 add end by Haruka.Mori
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
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A36C';      --パッケージ名
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';
  cv_dqu                     CONSTANT VARCHAR2(1)   := '"';                 --文字列括り
--
  --メッセージ
  cv_header_str_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00341';  --CSVファイルヘッダ文字列
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';  -- ファイル名ノート  
--
  --エラーメッセージ
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';  --プロファイル取得エラー
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';  --ファイルパス不正エラー
  cv_file_path_null_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00004';  --ファイルパスNULLエラー
  cv_file_name_null_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00006';  --ファイル名NULLエラー
  cv_exist_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';  --CSVファイル存在チェック
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';  --CSVデータ出力エラー
  cv_no_data_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00329';  --参照コード取得エラー
  cv_no_mst_data_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00330';  --マスタデータなし
  cv_file_close_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';  --ファイルクローズエラー
  --トークン
  cv_ng_profile              CONSTANT VARCHAR2(10)  := 'NG_PROFILE';        -- プロファイル取得失敗トークン
  cv_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';           -- ファイルクローズエラートークン
  cv_tkn_filename            CONSTANT VARCHAR2(10)  := 'FILE_NAME';         -- ファイル名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
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
-- 2009/03/09 modify start
--    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_003A36_OUT_FILE_DIR';   --XXCMM:各諸マスタ連携IFデータ作成用CSVファイル出力先
    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';         --XXCMM:情報系(OUTBOUND)連携用CSVファイル出力先
-- 2009/03/09 modify end
    cv_out_file_file CONSTANT VARCHAR2(30) := 'XXCMM1_003A36_OUT_FILE_FIL';   --XXCMM:各諸マスタ連携IFデータ作成用CSVファイル名
    cv_invalid_path  CONSTANT VARCHAR2(25) := 'CSV出力ディレクトリ';          --プロファイル取得失敗（ディレクトリ）
    cv_invalid_name  CONSTANT VARCHAR2(20) := 'CSV出力ファイル名';            --プロファイル取得失敗（ファイル名）
-- 2018/04/27 Ver1.9 add start by Haruka.Mori
    cv_prf_bks_id    CONSTANT VARCHAR2(50) := 'GL_SET_OF_BKS_ID';             --GL会計帳簿ID
    cv_invalid_id    CONSTANT VARCHAR2(20) := 'GL会計帳簿ID';                 --プロファイル取得失敗（GL会計帳簿ID）
-- 2018/04/27 Ver1.9 add end by Haruka.Mori
--
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
-- 2018/04/27 Ver1.9 add start by Haruka.Mori
    --帳簿IDをプロファイルより取得。失敗時はエラー
    gn_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );
    IF ( gn_bks_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_id);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
-- 2018/04/27 Ver1.9 end by Haruka.Mori
    --ファイル存在チェック
    UTL_FILE.FGETATTR(gv_out_file_dir, gv_out_file_file, lv_file_chk, ln_file_size, ln_block_size);
    IF lv_file_chk THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_exist_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
-- 2009/04/02 Ver1.2 add start by Yutaka.Kuboshima
    --業務日付取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
-- 2009/04/02 Ver1.2 add end by Yutaka.Kuboshima
  EXCEPTION
    WHEN init_err_expt THEN                           --*** 初期処理例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --初期処理例外時、対象件数、エラー件数は1件固定とする
      gn_target_cnt := 1;
      gn_error_cnt  := 1;
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
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxccp_msg_kbn,
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
      --ファイルオープンエラー時、対象件数、警告件数と、エラー件数は1件固定とする
      gn_target_cnt := 1;
      gn_warn_cnt := 1;
      gn_error_cnt  := 1;
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
   * Procedure Name   : write_csv
   * Description      : CSV出力
   ***********************************************************************************/
  PROCEDURE write_csv(
    ref_type         IN  VARCHAR2,            --   参照タイプ
    ref_code         IN  VARCHAR2,            --   参照コード
    ref_name         IN  VARCHAR2,            --   名称
    pt_ref_type      IN  VARCHAR2,            --   親参照タイプ
    pt_ref_code      IN  VARCHAR2,            --   親参照コード
    if_file_handler  IN  UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    ov_errbuf        OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode       OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg        OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'write_csv'; -- プログラム名
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
    cn_record_byte       CONSTANT NUMBER          := 4095;                --ファイル読み込み文字数
    cv_file_mode         CONSTANT VARCHAR2(1)     := 'W';                 --書き込みモードで開く
    cv_ng_word           CONSTANT VARCHAR2(7)     := 'NG_WORD';           --CSV出力エラートークン・NG_WORD
    cv_ng_data           CONSTANT VARCHAR2(7)     := 'NG_DATA';           --CSV出力エラートークン・NG_DATA
    cv_err_ref_type_msg  CONSTANT VARCHAR2(20)    := '参照タイプ';        --CSV出力エラー文字列
    cv_comp_code         CONSTANT VARCHAR2(3)     := '001';               --会社コード
--
    -- *** ローカル変数 ***
    lv_output_str        VARCHAR2(4095)           := NULL;                --出力文字列格納用変数
-- 2009/06/30 Ver1.6 add start by Yutaka.Kuboshima
    lv_meaning           VARCHAR2(200)            := NULL;                --名称用格納変数
-- 2009/06/30 Ver1.6 add end by Yutaka.Kuboshima
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
-- 2009/06/30 Ver1.7 add start by Yutaka.Kuboshima
      lv_meaning := xxcso_util_common_pkg.conv_multi_byte(ref_name);
-- 2009/06/30 Ver1.7 add end by Yutaka.Kuboshima
      --文字列出力    
      lv_output_str := cv_dqu        || cv_comp_code || cv_dqu;                       --会社コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(ref_type, 1, 30) || cv_dqu;     --参照タイプ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(ref_code, 1, 30) || cv_dqu;     --参照コード
-- 2009/06/30 Ver1.7 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(ref_name, 1, 80) || cv_dqu;     --名称
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(lv_meaning, 1, 80) || cv_dqu;     --名称
-- 2009/06/30 Ver1.7 modify end by Yutaka.Kuboshima
-- 2009/04/15 Ver1.3 modify start by Yutaka.Kuboshima
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_type, 1, 30) || cv_dqu;  --親参照タイプ
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_code, 1, 30) || cv_dqu;  --親参照コード
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_code, 1, 30) || cv_dqu;  --親参照コード
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_type, 1, 30) || cv_dqu;  --親参照タイプ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_type, 1, 30) || cv_dqu;  --親参照タイプ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(pt_ref_code, 1, 30) || cv_dqu;  --親参照コード
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
-- 2009/04/15 Ver1.3 modify end by Yutaka.Kuboshima
      --CSVファイル出力
      UTL_FILE.PUT_LINE(if_file_handler,lv_output_str);

    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR THEN  --*** ファイル書き込みエラー ***
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_write_err_msg,
                                              cv_ng_word,
                                              cv_err_ref_type_msg,
                                              cv_ng_data,
                                              ref_type);
        lv_errbuf  := lv_errmsg;
        RAISE write_failure_expt;

      WHEN OTHERS THEN
        RAISE;
    END;
--
  EXCEPTION
    WHEN write_failure_expt THEN       --*** ファイル書き込みエラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END write_csv;
--
  /**********************************************************************************
   * Procedure Name   : output_mst_data
   * Description      : 処理対象データ抽出処理(A-3)・CSVファイル出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_mst_data(
    if_file_handler         IN  UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    ov_errbuf               OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode              OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg               OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_mst_data'; -- プログラム名
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
    cv_y_flag             CONSTANT VARCHAR2(1)     := 'Y';                      --有効フラグY
    cv_language_ja        CONSTANT VARCHAR2(2)     := 'JA';                     --言語(日本語)
--
    cv_auto_ex_flag       CONSTANT VARCHAR2(1)     := '2';                      --自動出展フラグ・関連顧客
    cv_ng_word            CONSTANT VARCHAR2(7)     := 'NG_WORD';                --CSV出力エラートークン・NG_WORD
    cv_ng_data            CONSTANT VARCHAR2(7)     := 'NG_DATA';                --CSV出力エラートークン・NG_DATA
    cv_lookup_type        CONSTANT VARCHAR2(11)    := 'LOOKUP_TYPE';            --抽出データ取得エラートークン
    cv_ng_table           CONSTANT VARCHAR2(5)     := 'TABLE';                  --マスタデータ取得エラートークン
    cv_err_cust_code_msg  CONSTANT VARCHAR2(20)    := '顧客コード';             --CSV出力エラー文字列
-- 2009/04/02 Ver1.2 add start by Yutaka.Kuboshima
    cv_max_date           CONSTANT VARCHAR2(8)     := '99991231';               --MAX日付
    cv_date_format        CONSTANT VARCHAR2(8)     := 'YYYYMMDD';               --日付書式
-- 2009/04/02 Ver1.2 add end by Yutaka.Kuboshima
--
    -- *** ローカル変数 ***
    lv_header_str                  VARCHAR2(2000)  := NULL;                     --ヘッダメッセージ格納用変数
    ln_output_cnt                  NUMBER          := 0;                        --出力件数
    ln_warn_cnt                    NUMBER          := 0;                        --警告件数
    ln_data_cnt                    NUMBER          := 0;                        --出力データ件数
--
  BEGIN

    --ファイルヘッダー出力
    lv_header_str := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_header_str_msg);

    -- ===============================
    -- 1.参照コード情報の取得
    -- ===============================
    --1-1.インスタンスタイプ取得
    DECLARE

      CURSOR lookup_cur IS
                            SELECT
                                   lookup_type AS lv_ref_type 
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja
                            AND   lookup_type = 'CSI_INST_TYPE_CODE'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      lookup_rec lookup_cur%ROWTYPE;

    BEGIN

      OPEN lookup_cur;

        << lookup_loop >>
        LOOP

          FETCH lookup_cur INTO lookup_rec;
          EXIT WHEN lookup_cur%NOTFOUND;

            -- ファイル出力
           write_csv(
               lookup_rec.lv_ref_type     -- 参照タイプ
              ,lookup_rec.lv_ref_code     -- 参照コード
              ,lookup_rec.lv_ref_name     -- 名称
              ,lookup_rec.lv_pt_ref_type  -- 親参照タイプ
              ,lookup_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
           );

          --カーソルカウント
          ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE lookup_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'CSI_INST_TYPE_CODE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
        
      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;

      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-2.顧客区分取得
    DECLARE

      CURSOR custkbn_cur IS
                             SELECT
                                    lookup_type AS lv_ref_type 
                                   ,lookup_code AS lv_ref_code 
                                   ,meaning     AS lv_ref_name                                 
                                   ,NULL        AS lv_pt_ref_type
                                   ,NULL        AS lv_pt_ref_code
                             FROM  fnd_lookup_values
                             WHERE language = cv_language_ja 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                             AND   lookup_type = 'CUSTOMER_CLASS'
                             AND   lookup_type = 'CUSTOMER CLASS'
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                             AND   enabled_flag = cv_y_flag
                             ORDER BY lookup_code;

      custkbn_rec custkbn_cur%ROWTYPE;

    BEGIN

      OPEN custkbn_cur;

        << custkbn_loop >>
        LOOP

          FETCH custkbn_cur INTO custkbn_rec;
          EXIT WHEN custkbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               custkbn_rec.lv_ref_type     -- 参照タイプ
              ,custkbn_rec.lv_ref_code     -- 参照コード
              ,custkbn_rec.lv_ref_name     -- 名称
              ,custkbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,custkbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE custkbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                              'CUSTOMER_CLASS');
                                              'CUSTOMER CLASS');
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-3.性別区分取得
    DECLARE

      CURSOR gender_cur IS
                            SELECT
                                   lookup_type AS lv_ref_type 
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type     
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja
                            AND   lookup_type = 'PQH_GENDER'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      gender_rec gender_cur%ROWTYPE;

    BEGIN

      OPEN gender_cur;

        << gender_loop >>
        LOOP

          FETCH gender_cur INTO gender_rec;
          EXIT WHEN gender_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               gender_rec.lv_ref_type     -- 参照タイプ
              ,gender_rec.lv_ref_code     -- 参照コード
              ,gender_rec.lv_ref_name     -- 名称
              ,gender_rec.lv_pt_ref_type  -- 親参照タイプ
              ,gender_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE gender_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'PQH_GENDER');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-4.リース会社コード取得
    DECLARE

      CURSOR lease_cur IS
                           SELECT
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                 ,meaning     AS lv_ref_name                                 
                                 ,description AS lv_ref_name
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                 ,NULL        AS lv_pt_ref_type
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja 
                           AND   lookup_type = 'XXCFF1_LEASE_COMPANY'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      lease_rec lease_cur%ROWTYPE;

    BEGIN

      OPEN lease_cur;

        << lease_loop >>
        LOOP

          FETCH lease_cur INTO lease_rec;
          EXIT WHEN lease_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               lease_rec.lv_ref_type     -- 参照タイプ
              ,lease_rec.lv_ref_code     -- 参照コード
              ,lease_rec.lv_ref_name     -- 名称
              ,lease_rec.lv_pt_ref_type  -- 親参照タイプ
              ,lease_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE lease_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCFF1_LEASE_COMPANY');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-5.再リース区分取得
    DECLARE

      CURSOR leasekbn_cur IS
                              SELECT
                                     lookup_type AS lv_ref_type
                                    ,lookup_code AS lv_ref_code
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                    ,meaning     AS lv_ref_name
                                    ,description AS lv_ref_name
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCFF1_LEASE_TYPE'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      leasekbn_rec leasekbn_cur%ROWTYPE;

    BEGIN

      OPEN leasekbn_cur;

        << leasekbn_loop >>
        LOOP

          FETCH leasekbn_cur INTO leasekbn_rec;
          EXIT WHEN leasekbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               leasekbn_rec.lv_ref_type     -- 参照タイプ
              ,leasekbn_rec.lv_ref_code     -- 参照コード
              ,leasekbn_rec.lv_ref_name     -- 名称
              ,leasekbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,leasekbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE leasekbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCFF1_LEASE_TYPE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-6.センターEDI区分取得
    DECLARE

      CURSOR edikbn_cur IS
                            SELECT  
                                   lookup_type AS lv_ref_type 
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja 
                            AND   lookup_type = 'XXCMM_CUST_CENTER_EDI_KBN'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      edikbn_rec edikbn_cur%ROWTYPE;

    BEGIN

      OPEN edikbn_cur;

        << edikbn_loop >>
        LOOP

          FETCH edikbn_cur INTO edikbn_rec;
          EXIT WHEN edikbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               edikbn_rec.lv_ref_type     -- 参照タイプ
              ,edikbn_rec.lv_ref_code     -- 参照コード
              ,edikbn_rec.lv_ref_name     -- 名称
              ,edikbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,edikbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE edikbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_CENTER_EDI_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-7.地区コード取得
    DECLARE

      CURSOR chikucode_cur IS
                               SELECT  
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCMM_CUST_CHIKU_CODE'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      chikucode_rec chikucode_cur%ROWTYPE;

    BEGIN

      OPEN chikucode_cur;

        << chikucode_loop >>
        LOOP

          FETCH chikucode_cur INTO chikucode_rec;
          EXIT WHEN chikucode_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               chikucode_rec.lv_ref_type     -- 参照タイプ
              ,chikucode_rec.lv_ref_code     -- 参照コード
              ,chikucode_rec.lv_ref_name     -- 名称
              ,chikucode_rec.lv_pt_ref_type  -- 親参照タイプ
              ,chikucode_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE chikucode_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_CHIKU_CODE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-8.中止理由区分取得
    DECLARE

      CURSOR chushi_cur IS
                            SELECT  
                                   lookup_type AS lv_ref_type 
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja 
                            AND   lookup_type = 'XXCMM_CUST_CHUSHI_RIYU'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      chushi_rec chushi_cur%ROWTYPE;

    BEGIN

      OPEN chushi_cur;

        << chushi_loop >>
        LOOP

          FETCH chushi_cur INTO chushi_rec;
          EXIT WHEN chushi_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               chushi_rec.lv_ref_type     -- 参照タイプ
              ,chushi_rec.lv_ref_code     -- 参照コード
              ,chushi_rec.lv_ref_name     -- 名称
              ,chushi_rec.lv_pt_ref_type  -- 親参照タイプ
              ,chushi_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE chushi_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_CHUSHI_RIYU');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-9.業務中分類取得
    DECLARE

      CURSOR chu_gyotai_cur IS
                                SELECT
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                      ,NULL        AS lv_pt_ref_type
--                                      ,NULL        AS lv_pt_ref_code
                                      ,'XXCMM_CUST_GYOTAI_DAI' AS lv_pt_ref_type
                                      ,attribute1              AS lv_pt_ref_code
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCMM_CUST_GYOTAI_CHU'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      chu_gyotai_rec chu_gyotai_cur%ROWTYPE;
     
    BEGIN

      OPEN chu_gyotai_cur;

        << chu_gyotai_loop >>
        LOOP

          FETCH chu_gyotai_cur INTO chu_gyotai_rec;
          EXIT WHEN chu_gyotai_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               chu_gyotai_rec.lv_ref_type     -- 参照タイプ
              ,chu_gyotai_rec.lv_ref_code     -- 参照コード
              ,chu_gyotai_rec.lv_ref_name     -- 名称
              ,chu_gyotai_rec.lv_pt_ref_type  -- 親参照タイプ
              ,chu_gyotai_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE chu_gyotai_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_GYOTAI_CHU');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-10.業態大分類取得
    DECLARE

      CURSOR dai_gyotai_cur IS
                                SELECT  
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCMM_CUST_GYOTAI_DAI'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      dai_gyotai_rec dai_gyotai_cur%ROWTYPE;

    BEGIN

      OPEN dai_gyotai_cur;

        << dai_gyotai_loop >>
        LOOP

          FETCH dai_gyotai_cur INTO dai_gyotai_rec;
          EXIT WHEN dai_gyotai_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               dai_gyotai_rec.lv_ref_type     -- 参照タイプ
              ,dai_gyotai_rec.lv_ref_code     -- 参照コード
              ,dai_gyotai_rec.lv_ref_name     -- 名称
              ,dai_gyotai_rec.lv_pt_ref_type  -- 親参照タイプ
              ,dai_gyotai_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE dai_gyotai_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_GYOTAI_DAI');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-11.業種取得
    DECLARE

      CURSOR gyoshu_cur IS
                          SELECT
                                 lookup_type AS lv_ref_type 
                                ,lookup_code AS lv_ref_code 
                                ,meaning     AS lv_ref_name                                 
                                ,NULL        AS lv_pt_ref_type     
                                ,NULL        AS lv_pt_ref_code
                          FROM  fnd_lookup_values
                          WHERE language = cv_language_ja
                          AND   lookup_type = 'XXCMM_CUST_GYOTAI_KBN'
                          AND   enabled_flag = cv_y_flag
                          ORDER BY lookup_code;

      gyoshu_rec gyoshu_cur%ROWTYPE;

    BEGIN

      OPEN gyoshu_cur;

        << gyoshu_loop >>
        LOOP

          FETCH gyoshu_cur INTO gyoshu_rec;
          EXIT WHEN gyoshu_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               gyoshu_rec.lv_ref_type     -- 参照タイプ
              ,gyoshu_rec.lv_ref_code     -- 参照コード
              ,gyoshu_rec.lv_ref_name     -- 名称
              ,gyoshu_rec.lv_pt_ref_type  -- 親参照タイプ
              ,gyoshu_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE gyoshu_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_GYOTAI_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-12.業態小分類取得
    DECLARE

      CURSOR sho_gyotai_cur IS
                                SELECT
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                      ,NULL        AS lv_pt_ref_type
--                                      ,NULL        AS lv_pt_ref_code
                                      ,'XXCMM_CUST_GYOTAI_CHU' AS lv_pt_ref_type
                                      ,attribute1              AS lv_pt_ref_code
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCMM_CUST_GYOTAI_SHO'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      sho_gyotai_rec sho_gyotai_cur%ROWTYPE;

    BEGIN

      OPEN sho_gyotai_cur;

        << sho_gyotai_loop >>
        LOOP

          FETCH sho_gyotai_cur INTO sho_gyotai_rec;
          EXIT WHEN sho_gyotai_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               sho_gyotai_rec.lv_ref_type     -- 参照タイプ
              ,sho_gyotai_rec.lv_ref_code     -- 参照コード
              ,sho_gyotai_rec.lv_ref_name     -- 名称
              ,sho_gyotai_rec.lv_pt_ref_type  -- 親参照タイプ
              ,sho_gyotai_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sho_gyotai_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_GYOTAI_SHO');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-13.配送形態取得
    DECLARE

      CURSOR haisou_cur IS
                            SELECT
                                   lookup_type AS lv_ref_type
                                  ,lookup_code AS lv_ref_code 
                                  ,meaning     AS lv_ref_name                                 
                                  ,NULL        AS lv_pt_ref_type
                                  ,NULL        AS lv_pt_ref_code
                            FROM  fnd_lookup_values
                            WHERE language = cv_language_ja 
                            AND   lookup_type = 'XXCMM_CUST_HAISO_KETAI'
                            AND   enabled_flag = cv_y_flag
                            ORDER BY lookup_code;

      haisou_rec haisou_cur%ROWTYPE;

    BEGIN

      OPEN haisou_cur;

        << haisou_loop >>
        LOOP

          FETCH haisou_cur INTO haisou_rec;
          EXIT WHEN haisou_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               haisou_rec.lv_ref_type     -- 参照タイプ
              ,haisou_rec.lv_ref_code     -- 参照コード
              ,haisou_rec.lv_ref_name     -- 名称
              ,haisou_rec.lv_pt_ref_type  -- 親参照タイプ
              ,haisou_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE haisou_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_HAISO_KETAI');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;
      
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-14.訪問対象区分取得
    DECLARE

      CURSOR houmon_target_cur IS
                                   SELECT  
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type     
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja 
                                   AND   lookup_type = 'XXCMM_CUST_HOMON_TAISYO_KBN'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      houmon_target_rec houmon_target_cur%ROWTYPE;

    BEGIN

      OPEN houmon_target_cur;

        << houmon_target_loop >>
        LOOP

          FETCH houmon_target_cur INTO houmon_target_rec;
          EXIT WHEN houmon_target_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               houmon_target_rec.lv_ref_type     -- 参照タイプ
              ,houmon_target_rec.lv_ref_code     -- 参照コード
              ,houmon_target_rec.lv_ref_name     -- 名称
              ,houmon_target_rec.lv_pt_ref_type  -- 親参照タイプ
              ,houmon_target_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE houmon_target_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_HOMON_TAISYO_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-15.顧客ステータス取得
    DECLARE

      CURSOR cust_status_cur IS
                                 SELECT
                                        lookup_type AS lv_ref_type 
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja 
                                 AND   lookup_type = 'XXCMM_CUST_KOKYAKU_STATUS'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      cust_status_rec cust_status_cur%ROWTYPE;

    BEGIN

      OPEN cust_status_cur;

        << cust_status_loop >>
        LOOP

          FETCH cust_status_cur INTO cust_status_rec;
          EXIT WHEN cust_status_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               cust_status_rec.lv_ref_type     -- 参照タイプ
              ,cust_status_rec.lv_ref_code     -- 参照コード
              ,cust_status_rec.lv_ref_name     -- 名称
              ,cust_status_rec.lv_pt_ref_type  -- 親参照タイプ
              ,cust_status_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE cust_status_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_KOKYAKU_STATUS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-16.MCHOT取得
    DECLARE

      CURSOR mchot_cur IS
                           SELECT
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
                                 ,meaning     AS lv_ref_name                                 
                                 ,NULL        AS lv_pt_ref_type
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja
                           AND   lookup_type = 'XXCMM_CUST_MCHOTDO'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      mchot_rec mchot_cur%ROWTYPE;

    BEGIN

      OPEN mchot_cur;

        << mchot_loop >>
        LOOP

          FETCH mchot_cur INTO mchot_rec;
          EXIT WHEN mchot_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               mchot_rec.lv_ref_type     -- 参照タイプ
              ,mchot_rec.lv_ref_code     -- 参照コード
              ,mchot_rec.lv_ref_name     -- 名称
              ,mchot_rec.lv_pt_ref_type  -- 親参照タイプ
              ,mchot_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE mchot_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_MCHOTDO');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;    

    --1-17.MC重要度取得
    DECLARE

      CURSOR mc_jyuyou_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCMM_CUST_MCJUYODO'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      mc_jyuyou_rec mc_jyuyou_cur%ROWTYPE;

    BEGIN

      OPEN mc_jyuyou_cur;

        << mc_jyuyou_loop >>
        LOOP

          FETCH mc_jyuyou_cur INTO mc_jyuyou_rec;
          EXIT WHEN mc_jyuyou_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               mc_jyuyou_rec.lv_ref_type     -- 参照タイプ
              ,mc_jyuyou_rec.lv_ref_code     -- 参照コード
              ,mc_jyuyou_rec.lv_ref_name     -- 名称
              ,mc_jyuyou_rec.lv_pt_ref_type  -- 親参照タイプ
              ,mc_jyuyou_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE mc_jyuyou_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_MCJUYODO');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;    

    --1-18.オープン・クローズ取得
    DECLARE

      CURSOR open_close_cur IS
                                SELECT  
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCMM_CUST_OPEN_CLOSE_KBN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      open_close_rec open_close_cur%ROWTYPE;

    BEGIN

      OPEN open_close_cur;

        << open_close_loop >>
        LOOP

          FETCH open_close_cur INTO open_close_rec;
          EXIT WHEN open_close_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               open_close_rec.lv_ref_type     -- 参照タイプ
              ,open_close_rec.lv_ref_code     -- 参照コード
              ,open_close_rec.lv_ref_name     -- 名称
              ,open_close_rec.lv_pt_ref_type  -- 親参照タイプ
              ,open_close_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE open_close_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_OPEN_CLOSE_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-19.請求書発行区分取得
    DECLARE

      CURSOR invoice_cur IS
                             SELECT
                                    lookup_type AS lv_ref_type 
                                   ,lookup_code AS lv_ref_code 
                                   ,meaning     AS lv_ref_name                                 
                                   ,NULL        AS lv_pt_ref_type
                                   ,NULL        AS lv_pt_ref_code
                             FROM  fnd_lookup_values
                             WHERE language = cv_language_ja 
                             AND   lookup_type = 'XXCMM_CUST_SEKYUSYO_HAKKO_KBN'
                             AND   enabled_flag = cv_y_flag
                             ORDER BY lookup_code;

      invoice_rec invoice_cur%ROWTYPE;

    BEGIN

      OPEN invoice_cur;

        << invoice_loop >>
        LOOP

          FETCH invoice_cur INTO invoice_rec;
          EXIT WHEN invoice_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               invoice_rec.lv_ref_type     -- 参照タイプ
              ,invoice_rec.lv_ref_code     -- 参照コード
              ,invoice_rec.lv_ref_name     -- 名称
              ,invoice_rec.lv_pt_ref_type  -- 親参照タイプ
              ,invoice_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE invoice_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_SEKYUSYO_HAKKO_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-20.請求処理区分取得
    DECLARE

      CURSOR seikyuu_syori_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja 
                                   AND   lookup_type = 'XXCMM_CUST_SEKYUSYO_SHUT_KSK'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

     seikyuu_syori_rec seikyuu_syori_cur%ROWTYPE;

    BEGIN

      OPEN seikyuu_syori_cur;

        << seikyuu_syori_loop >>
        LOOP

          FETCH seikyuu_syori_cur INTO seikyuu_syori_rec;
          EXIT WHEN seikyuu_syori_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               seikyuu_syori_rec.lv_ref_type     -- 参照タイプ
              ,seikyuu_syori_rec.lv_ref_code     -- 参照コード
              ,seikyuu_syori_rec.lv_ref_name     -- 名称
              ,seikyuu_syori_rec.lv_pt_ref_type  -- 親参照タイプ
              ,seikyuu_syori_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE seikyuu_syori_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_SEKYUSYO_SHUT_KSK');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-21.新規ポイント区分取得
    DECLARE

      CURSOR new_point_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCMM_CUST_SHINKI_POINT_KBN'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      new_point_rec new_point_cur%ROWTYPE;

    BEGIN

      OPEN new_point_cur;

        << new_point_loop >>
        LOOP

          FETCH new_point_cur INTO new_point_rec;
          EXIT WHEN new_point_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               new_point_rec.lv_ref_type     -- 参照タイプ
              ,new_point_rec.lv_ref_code     -- 参照コード
              ,new_point_rec.lv_ref_name     -- 名称
              ,new_point_rec.lv_pt_ref_type  -- 親参照タイプ
              ,new_point_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE new_point_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_SHINKI_POINT_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-22.判定区分取得
    DECLARE

      CURSOR judge_cur IS
                           SELECT 
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
                                 ,meaning     AS lv_ref_name                                 
                                 ,NULL        AS lv_pt_ref_type
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja 
                           AND   lookup_type = 'XXCMM_CUST_SOHYO_KBN'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      judge_rec judge_cur%ROWTYPE;

    BEGIN

      OPEN judge_cur;

        << judge_loop >>
        LOOP

          FETCH judge_cur INTO judge_rec;
          EXIT WHEN judge_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               judge_rec.lv_ref_type     -- 参照タイプ
              ,judge_rec.lv_ref_code     -- 参照コード
              ,judge_rec.lv_ref_name     -- 名称
              ,judge_rec.lv_pt_ref_type  -- 親参照タイプ
              ,judge_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE judge_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_SOHYO_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-23.EDI手書伝票伝送取得
    DECLARE

      CURSOR tegaki_den_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCMM_CUST_TEGAKI_DENSOU_KBN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      tegaki_den_rec tegaki_den_cur%ROWTYPE;

    BEGIN

      OPEN tegaki_den_cur;

        << tegaki_loop >>
        LOOP

          FETCH tegaki_den_cur INTO tegaki_den_rec;
          EXIT WHEN tegaki_den_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               tegaki_den_rec.lv_ref_type     -- 参照タイプ
              ,tegaki_den_rec.lv_ref_code     -- 参照コード
              ,tegaki_den_rec.lv_ref_name     -- 名称
              ,tegaki_den_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tegaki_den_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tegaki_den_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_TEGAKI_DENSOU_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-24.取引形態取得
    DECLARE

      CURSOR torihiki_cur IS
                              SELECT  
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCMM_CUST_TORIHIKI_KETAI'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      torihiki_rec torihiki_cur%ROWTYPE;

    BEGIN

      OPEN torihiki_cur;

        << torihiki_loop >>
        LOOP

          FETCH torihiki_cur INTO torihiki_rec;
          EXIT WHEN torihiki_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               torihiki_rec.lv_ref_type     -- 参照タイプ
              ,torihiki_rec.lv_ref_code     -- 参照コード
              ,torihiki_rec.lv_ref_name     -- 名称
              ,torihiki_rec.lv_pt_ref_type  -- 親参照タイプ
              ,torihiki_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE torihiki_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_TORIHIKI_KETAI');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-25.通過在庫型区分取得
    DECLARE

      CURSOR tuuka_zaiko_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type 
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type     
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja 
                                 AND   lookup_type = 'XXCMM_CUST_TSUKAGATAZAIKO_KBN'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      tuuka_zaiko_rec tuuka_zaiko_cur%ROWTYPE;

    BEGIN

      OPEN tuuka_zaiko_cur;

        << tuuka_zaiko_loop >>
        LOOP

          FETCH tuuka_zaiko_cur INTO tuuka_zaiko_rec;
          EXIT WHEN tuuka_zaiko_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               tuuka_zaiko_rec.lv_ref_type     -- 参照タイプ
              ,tuuka_zaiko_rec.lv_ref_code     -- 参照コード
              ,tuuka_zaiko_rec.lv_ref_name     -- 名称
              ,tuuka_zaiko_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tuuka_zaiko_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tuuka_zaiko_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_TSUKAGATAZAIKO_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-26.売上実績振取得
    DECLARE

      CURSOR uriage_jisseki_cur IS
                                    SELECT 
                                           lookup_type AS lv_ref_type 
                                          ,lookup_code AS lv_ref_code 
                                          ,meaning     AS lv_ref_name                                 
                                          ,NULL        AS lv_pt_ref_type
                                          ,NULL        AS lv_pt_ref_code
                                    FROM  fnd_lookup_values
                                    WHERE language = cv_language_ja 
                                    AND   lookup_type = 'XXCMM_CUST_URIAGE_JISSEKI_FURI'
                                    AND   enabled_flag = cv_y_flag
                                    ORDER BY lookup_code;

      uriage_jisseki_rec uriage_jisseki_cur%ROWTYPE;

    BEGIN

      OPEN uriage_jisseki_cur;

        << uriage_jisseki_loop >>
        LOOP

          FETCH uriage_jisseki_cur INTO uriage_jisseki_rec;
          EXIT WHEN uriage_jisseki_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               uriage_jisseki_rec.lv_ref_type     -- 参照タイプ
              ,uriage_jisseki_rec.lv_ref_code     -- 参照コード
              ,uriage_jisseki_rec.lv_ref_name     -- 名称
              ,uriage_jisseki_rec.lv_pt_ref_type  -- 親参照タイプ
              ,uriage_jisseki_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE uriage_jisseki_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_URIAGE_JISSEKI_FURI');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-27.売上実績振取得
    DECLARE

      CURSOR secchi_loca_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type
                                       ,lookup_code AS lv_ref_code
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja 
                                 AND   lookup_type = 'XXCMM_CUST_VD_SECCHI_BASYO'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      secchi_loca_rec secchi_loca_cur%ROWTYPE;

    BEGIN

      OPEN secchi_loca_cur;

        << secchi_loop >>
        LOOP

          FETCH secchi_loca_cur INTO secchi_loca_rec;
          EXIT WHEN secchi_loca_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               secchi_loca_rec.lv_ref_type     -- 参照タイプ
              ,secchi_loca_rec.lv_ref_code     -- 参照コード
              ,secchi_loca_rec.lv_ref_name     -- 名称
              ,secchi_loca_rec.lv_pt_ref_type  -- 親参照タイプ
              ,secchi_loca_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE secchi_loca_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_VD_SECCHI_BASYO');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-28.営業形態取得
    DECLARE

      CURSOR eigyo_keitai_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCMM_EIGYOKETAI'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      eigyo_keitai_rec eigyo_keitai_cur%ROWTYPE;

    BEGIN

      OPEN eigyo_keitai_cur;

        << eigyo_keitai_loop >>
        LOOP

          FETCH eigyo_keitai_cur INTO eigyo_keitai_rec;
          EXIT WHEN eigyo_keitai_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               eigyo_keitai_rec.lv_ref_type     -- 参照タイプ
              ,eigyo_keitai_rec.lv_ref_code     -- 参照コード
              ,eigyo_keitai_rec.lv_ref_name     -- 名称
              ,eigyo_keitai_rec.lv_pt_ref_type  -- 親参照タイプ
              ,eigyo_keitai_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE eigyo_keitai_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_EIGYOKETAI');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-29.請求書発行サイクル取得
    DECLARE

      CURSOR invoice_cycle_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja
                                   AND   lookup_type = 'XXCMM_INVOICE_ISSUE_CYCLE'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      invoice_cycle_rec invoice_cycle_cur%ROWTYPE;

    BEGIN

      OPEN invoice_cycle_cur;

        << invoice_loop >>
        LOOP

          FETCH invoice_cycle_cur INTO invoice_cycle_rec;
          EXIT WHEN invoice_cycle_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               invoice_cycle_rec.lv_ref_type     -- 参照タイプ
              ,invoice_cycle_rec.lv_ref_code     -- 参照コード
              ,invoice_cycle_rec.lv_ref_name     -- 名称
              ,invoice_cycle_rec.lv_pt_ref_type  -- 親参照タイプ
              ,invoice_cycle_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE invoice_cycle_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_INVOICE_ISSUE_CYCLE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-30.経理群取得
    DECLARE

      CURSOR keirigun_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCMM_ITM_KERIGUN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      keirigun_rec keirigun_cur%ROWTYPE;

    BEGIN

      OPEN keirigun_cur;

        << keirigun_loop >>
        LOOP

          FETCH keirigun_cur INTO keirigun_rec;
          EXIT WHEN keirigun_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               keirigun_rec.lv_ref_type     -- 参照タイプ
              ,keirigun_rec.lv_ref_code     -- 参照コード
              ,keirigun_rec.lv_ref_name     -- 名称
              ,keirigun_rec.lv_pt_ref_type  -- 親参照タイプ
              ,keirigun_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE keirigun_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_KERIGUN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-31.容器群コード取得
    DECLARE

      CURSOR youkigun_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCMM_ITM_YOKIGUN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      youkigun_rec youkigun_cur%ROWTYPE;
     
    BEGIN

      OPEN youkigun_cur;

        << youkigun_loop >>
        LOOP

          FETCH youkigun_cur INTO youkigun_rec;
          EXIT WHEN youkigun_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               youkigun_rec.lv_ref_type     -- 参照タイプ
              ,youkigun_rec.lv_ref_code     -- 参照コード
              ,youkigun_rec.lv_ref_name     -- 名称
              ,youkigun_rec.lv_pt_ref_type  -- 親参照タイプ
              ,youkigun_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE youkigun_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_YOKIGUN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-32.問屋管理コード取得
    DECLARE

      CURSOR tonya_cur IS
                           SELECT 
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
                                 ,meaning     AS lv_ref_name                                 
                                 ,NULL        AS lv_pt_ref_type
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja
                           AND   lookup_type = 'XXCMM_TONYA_CODE'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      tonya_rec tonya_cur%ROWTYPE;

    BEGIN

      OPEN tonya_cur;

        << tonya_loop >>
        LOOP

          FETCH tonya_cur INTO tonya_rec;
          EXIT WHEN tonya_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               tonya_rec.lv_ref_type     -- 参照タイプ
              ,tonya_rec.lv_ref_code     -- 参照コード
              ,tonya_rec.lv_ref_name     -- 名称
              ,tonya_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tonya_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tonya_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_TONYA_CODE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-33.計算条件-容器区分取得
    DECLARE

      CURSOR youkikbn_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCMM_YOKI_KUBUN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      youkikbn_rec youkikbn_cur%ROWTYPE;

    BEGIN

      OPEN youkikbn_cur;

        << youkikbn_loop >>
        LOOP

          FETCH youkikbn_cur INTO youkikbn_rec;
          EXIT WHEN youkikbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               youkikbn_rec.lv_ref_type     -- 参照タイプ
              ,youkikbn_rec.lv_ref_code     -- 参照コード
              ,youkikbn_rec.lv_ref_name     -- 名称
              ,youkikbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,youkikbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE youkikbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_YOKI_KUBUN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-34.社員・外部委託区分取得
    DECLARE

      CURSOR emp_class_cur IS
                               SELECT
                                      lookup_type AS lv_ref_type
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCMN_EMPLOYEE_CLASS'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      emp_class_rec emp_class_cur%ROWTYPE;

    BEGIN

      OPEN emp_class_cur;

        << emp_class_loop >>
        LOOP

          FETCH emp_class_cur INTO emp_class_rec;
          EXIT WHEN emp_class_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               emp_class_rec.lv_ref_type     -- 参照タイプ
              ,emp_class_rec.lv_ref_code     -- 参照コード
              ,emp_class_rec.lv_ref_name     -- 名称
              ,emp_class_rec.lv_pt_ref_type  -- 親参照タイプ
              ,emp_class_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE emp_class_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMN_EMPLOYEE_CLASS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-35.保管場所区分取得
    DECLARE

      CURSOR hokankbn_cur IS 
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCOI_SECINV_HOKANBASYO_KUBUN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      hokankbn_rec hokankbn_cur%ROWTYPE;

    BEGIN

      OPEN hokankbn_cur;

        << hokankbn_loop >>
        LOOP

          FETCH hokankbn_cur INTO hokankbn_rec;
          EXIT WHEN hokankbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               hokankbn_rec.lv_ref_type     -- 参照タイプ
              ,hokankbn_rec.lv_ref_code     -- 参照コード
              ,hokankbn_rec.lv_ref_name     -- 名称
              ,hokankbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,hokankbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE hokankbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOI_SECINV_HOKANBASYO_KUBUN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-36.計算条件取得
    DECLARE

      CURSOR calc_type_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCOK1_BM_CALC_TYPE'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      calc_type_rec calc_type_cur%ROWTYPE;

    BEGIN

      OPEN calc_type_cur;

        << calc_type_loop >>
        LOOP

          FETCH calc_type_cur INTO calc_type_rec;
          EXIT WHEN calc_type_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               calc_type_rec.lv_ref_type     -- 参照タイプ
              ,calc_type_rec.lv_ref_code     -- 参照コード
              ,calc_type_rec.lv_ref_name     -- 名称
              ,calc_type_rec.lv_pt_ref_type  -- 親参照タイプ
              ,calc_type_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE calc_type_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOK1_BM_CALC_TYPE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-37.拠点分割移行情報ステータス取得
    DECLARE

      CURSOR shift_status_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type     
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCOK1_CUST_SHIFT_STATUS'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      shift_status_rec shift_status_cur%ROWTYPE;

    BEGIN

      OPEN shift_status_cur;

        << shift_status_loop >>
        LOOP

          FETCH shift_status_cur INTO shift_status_rec;
          EXIT WHEN shift_status_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               shift_status_rec.lv_ref_type     -- 参照タイプ
              ,shift_status_rec.lv_ref_code     -- 参照コード
              ,shift_status_rec.lv_ref_name     -- 名称
              ,shift_status_rec.lv_pt_ref_type  -- 親参照タイプ
              ,shift_status_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE shift_status_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOK1_CUST_SHIFT_STATUS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-38.年次移行区分取得
    DECLARE

      CURSOR annual_kbn_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCOK1_SHIFT_DIVIDE'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      annual_kbn_rec annual_kbn_cur%ROWTYPE;

    BEGIN

      OPEN annual_kbn_cur;

        << annual_kbn_loop >>
        LOOP

          FETCH annual_kbn_cur INTO annual_kbn_rec;
          EXIT WHEN annual_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               annual_kbn_rec.lv_ref_type     -- 参照タイプ
              ,annual_kbn_rec.lv_ref_code     -- 参照コード
              ,annual_kbn_rec.lv_ref_name     -- 名称
              ,annual_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,annual_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE annual_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOK1_SHIFT_DIVIDE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-39.カード売り区分取得
    DECLARE

      CURSOR card_sale_cur IS
                               SELECT
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCOS1_CARD_SALE_CLASS'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      card_sale_rec card_sale_cur%ROWTYPE;

    BEGIN

      OPEN card_sale_cur;

        << card_sale_loop >>
        LOOP

          FETCH card_sale_cur INTO card_sale_rec;
          EXIT WHEN card_sale_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               card_sale_rec.lv_ref_type     -- 参照タイプ
              ,card_sale_rec.lv_ref_code     -- 参照コード
              ,card_sale_rec.lv_ref_name     -- 名称
              ,card_sale_rec.lv_pt_ref_type  -- 親参照タイプ
              ,card_sale_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE card_sale_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_CARD_SALE_CLASS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-40.納品形態取得
    DECLARE

      CURSOR dliy_pattn_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCOS1_DELIVERY_PATTERN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      dliy_pattn_rec dliy_pattn_cur%ROWTYPE;

    BEGIN

      OPEN dliy_pattn_cur;

        << dliy_pattn_loop >>
        LOOP

          FETCH dliy_pattn_cur INTO dliy_pattn_rec;
          EXIT WHEN dliy_pattn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               dliy_pattn_rec.lv_ref_type     -- 参照タイプ
              ,dliy_pattn_rec.lv_ref_code     -- 参照コード
              ,dliy_pattn_rec.lv_ref_name     -- 名称
              ,dliy_pattn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,dliy_pattn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE dliy_pattn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_DELIVERY_PATTERN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-41.HC区分取得
    DECLARE

      CURSOR hckbn_cur IS
                           SELECT 
                                  lookup_type AS lv_ref_type 
                                 ,lookup_code AS lv_ref_code 
                                 ,meaning     AS lv_ref_name                                 
                                 ,NULL        AS lv_pt_ref_type     
                                 ,NULL        AS lv_pt_ref_code
                           FROM  fnd_lookup_values
                           WHERE language = cv_language_ja 
                           AND   lookup_type = 'XXCOS1_HC_CLASS'
                           AND   enabled_flag = cv_y_flag
                           ORDER BY lookup_code;

      hckbn_rec hckbn_cur%ROWTYPE;

    BEGIN

      OPEN hckbn_cur;

        << hckbn_loop >>
        LOOP

          FETCH hckbn_cur INTO hckbn_rec;
          EXIT WHEN hckbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               hckbn_rec.lv_ref_type     -- 参照タイプ
              ,hckbn_rec.lv_ref_code     -- 参照コード
              ,hckbn_rec.lv_ref_name     -- 名称
              ,hckbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,hckbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE hckbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_HC_CLASS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-42.売上区分取得
    DECLARE

      CURSOR salekbn_cur IS
                             SELECT 
                                    lookup_type AS lv_ref_type 
                                   ,lookup_code AS lv_ref_code
                                   ,meaning     AS lv_ref_name                                 
                                   ,NULL        AS lv_pt_ref_type
                                   ,NULL        AS lv_pt_ref_code
                             FROM  fnd_lookup_values
                             WHERE language = cv_language_ja 
                             AND   lookup_type = 'XXCOS1_SALE_CLASS'
                             AND   enabled_flag = cv_y_flag
                             ORDER BY lookup_code;

      salekbn_rec salekbn_cur%ROWTYPE;

    BEGIN

      OPEN salekbn_cur;

        << salekbn_loop >>
        LOOP

          FETCH salekbn_cur INTO salekbn_rec;
          EXIT WHEN salekbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               salekbn_rec.lv_ref_type     -- 参照タイプ
              ,salekbn_rec.lv_ref_code     -- 参照コード
              ,salekbn_rec.lv_ref_name     -- 名称
              ,salekbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,salekbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE salekbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_SALE_CLASS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;    

    --1-43.売上返品区分取得
    DECLARE

      CURSOR sales_return_cur IS 
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type     
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCOS1_SALES_RETURN_CLASS'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      sales_return_rec sales_return_cur%ROWTYPE;
     
    BEGIN

      OPEN sales_return_cur;

        << sales_return >>
        LOOP

          FETCH sales_return_cur INTO sales_return_rec;
          EXIT WHEN sales_return_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               sales_return_rec.lv_ref_type     -- 参照タイプ
              ,sales_return_rec.lv_ref_code     -- 参照コード
              ,sales_return_rec.lv_ref_name     -- 名称
              ,sales_return_rec.lv_pt_ref_type  -- 親参照タイプ
              ,sales_return_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sales_return_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCOS1_SALES_RETURN_CLASS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-44.獲得・紹介区分取得
    DECLARE

      CURSOR kakutoku_kbn_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCSM1_ACQ_INTR_EMP_KBN'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      kakutoku_kbn_rec kakutoku_kbn_cur%ROWTYPE;

    BEGIN

      OPEN kakutoku_kbn_cur;

        << kakutoku_loop >>
        LOOP

          FETCH kakutoku_kbn_cur INTO kakutoku_kbn_rec;
          EXIT WHEN kakutoku_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               kakutoku_kbn_rec.lv_ref_type     -- 参照タイプ
              ,kakutoku_kbn_rec.lv_ref_code     -- 参照コード
              ,kakutoku_kbn_rec.lv_ref_name     -- 名称
              ,kakutoku_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,kakutoku_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE kakutoku_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSM1_ACQ_INTR_EMP_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    
    --1-45.商品(群)区分取得
    DECLARE

      CURSOR goods_grp_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCSM1_ITEMGROUP_KBN'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      goods_grp_rec goods_grp_cur%ROWTYPE;

    BEGIN

      OPEN goods_grp_cur;

        << goods_loop >>
        LOOP

          FETCH goods_grp_cur INTO goods_grp_rec;
          EXIT WHEN goods_grp_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               goods_grp_rec.lv_ref_type     -- 参照タイプ
              ,goods_grp_rec.lv_ref_code     -- 参照コード
              ,goods_grp_rec.lv_ref_name     -- 名称
              ,goods_grp_rec.lv_pt_ref_type  -- 親参照タイプ
              ,goods_grp_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE goods_grp_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSM1_ITEMGROUP_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-46.速報区分取得
    DECLARE

      CURSOR news_kbn_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type     
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja
                              AND   lookup_type = 'XXCSM1_NEWS_ITEM_KBN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      news_kbn_rec news_kbn_cur%ROWTYPE;

    BEGIN

      OPEN news_kbn_cur;

        << news_kbn_loop >>
        LOOP

          FETCH news_kbn_cur INTO news_kbn_rec;
          EXIT WHEN news_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               news_kbn_rec.lv_ref_type     -- 参照タイプ
              ,news_kbn_rec.lv_ref_code     -- 参照コード
              ,news_kbn_rec.lv_ref_name     -- 名称
              ,news_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,news_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE news_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSM1_NEWS_ITEM_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-47.ポイント区分取得
    DECLARE

      CURSOR point_kbn_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSM1_POINT_DATA_KBN'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      point_kbn_rec point_kbn_cur%ROWTYPE;

    BEGIN

      OPEN point_kbn_cur;

        << point_kbn_loop >>
        LOOP

          FETCH point_kbn_cur INTO point_kbn_rec;
          EXIT WHEN point_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               point_kbn_rec.lv_ref_type     -- 参照タイプ
              ,point_kbn_rec.lv_ref_code     -- 参照コード
              ,point_kbn_rec.lv_ref_name     -- 名称
              ,point_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,point_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE point_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSM1_POINT_DATA_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-48.製造メーカー取得
    DECLARE

      CURSOR maker_kbn_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSO_CSI_MAKER_CODE'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      maker_kbn_rec maker_kbn_cur%ROWTYPE;

    BEGIN

      OPEN maker_kbn_cur;

        << maker_kbn >>
        LOOP

          FETCH maker_kbn_cur INTO maker_kbn_rec;
          EXIT WHEN maker_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               maker_kbn_rec.lv_ref_type     -- 参照タイプ
              ,maker_kbn_rec.lv_ref_code     -- 参照コード
              ,maker_kbn_rec.lv_ref_name     -- 名称
              ,maker_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,maker_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE maker_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO_CSI_MAKER_CODE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-49.特殊機区分取得
    DECLARE

      CURSOR tokushuki_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSO_CSI_TOKUSHUKI'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      tokushuki_rec tokushuki_cur%ROWTYPE;

    BEGIN

      OPEN tokushuki_cur;

        << tokushuki_loop >>
        LOOP

          FETCH tokushuki_cur INTO tokushuki_rec;
          EXIT WHEN tokushuki_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               tokushuki_rec.lv_ref_type     -- 参照タイプ
              ,tokushuki_rec.lv_ref_code     -- 参照コード
              ,tokushuki_rec.lv_ref_name     -- 名称
              ,tokushuki_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tokushuki_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tokushuki_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO_CSI_TOKUSHUKI');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-50.訪問区分取得
    DECLARE

      CURSOR houmon_kbn_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                AND   lookup_type = 'XXCSO1_ASN_HOUMON_KUBUN'
                                AND   lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      houmon_kbn_rec houmon_kbn_cur%ROWTYPE;

    BEGIN

      OPEN houmon_kbn_cur;

        << houmon_kbn_loop >>
        LOOP

          FETCH houmon_kbn_cur INTO houmon_kbn_rec;
          EXIT WHEN houmon_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               houmon_kbn_rec.lv_ref_type     -- 参照タイプ
              ,houmon_kbn_rec.lv_ref_code     -- 参照コード
              ,houmon_kbn_rec.lv_ref_name     -- 名称
              ,houmon_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,houmon_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE houmon_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                              'XXCSO1_ASN_HOUMON_KUBUN');
                                              'XXCSO_ASN_HOUMON_KUBUN');
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-51.什器移動区分取得
    DECLARE

      CURSOR csi_job_kbn_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type 
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja
                                 AND   lookup_type = 'XXCSO1_CSI_JOB_KBN'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      csi_job_kbn_rec csi_job_kbn_cur%ROWTYPE;

    BEGIN

      OPEN csi_job_kbn_cur;

        << csi_job_loop >>
        LOOP

          FETCH csi_job_kbn_cur INTO csi_job_kbn_rec;
          EXIT WHEN csi_job_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               csi_job_kbn_rec.lv_ref_type     -- 参照タイプ
              ,csi_job_kbn_rec.lv_ref_code     -- 参照コード
              ,csi_job_kbn_rec.lv_ref_name     -- 名称
              ,csi_job_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,csi_job_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE csi_job_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOB_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-52.最終設置区分取得
    DECLARE

      CURSOR csi_job_kbn2_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja
                                  AND   lookup_type = 'XXCSO1_CSI_JOB_KBN2'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

     csi_job_kbn2_rec csi_job_kbn2_cur%ROWTYPE;

    BEGIN

      OPEN csi_job_kbn2_cur;

        << csi_job_kbn2 >>
        LOOP

          FETCH csi_job_kbn2_cur INTO csi_job_kbn2_rec;
          EXIT WHEN csi_job_kbn2_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               csi_job_kbn2_rec.lv_ref_type     -- 参照タイプ
              ,csi_job_kbn2_rec.lv_ref_code     -- 参照コード
              ,csi_job_kbn2_rec.lv_ref_name     -- 名称
              ,csi_job_kbn2_rec.lv_pt_ref_type  -- 親参照タイプ
              ,csi_job_kbn2_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE csi_job_kbn2_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOB_KBN2');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-53.機器状態１(稼動状態)取得
    DECLARE

      CURSOR final_setubi_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type     
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCSO1_CSI_JOTAI_KBN1'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      final_setubi_rec final_setubi_cur%ROWTYPE;

    BEGIN

      OPEN final_setubi_cur;

        << final_setubi_loop >>
        LOOP

          FETCH final_setubi_cur INTO final_setubi_rec;
          EXIT WHEN final_setubi_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               final_setubi_rec.lv_ref_type     -- 参照タイプ
              ,final_setubi_rec.lv_ref_code     -- 参照コード
              ,final_setubi_rec.lv_ref_name     -- 名称
              ,final_setubi_rec.lv_pt_ref_type  -- 親参照タイプ
              ,final_setubi_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE final_setubi_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOTAI_KBN1');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-54.機器状態２(状態詳細)取得
    DECLARE

      CURSOR final_setubi2_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type     
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja 
                                   AND   lookup_type = 'XXCSO1_CSI_JOTAI_KBN2'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      final_setubi2_rec final_setubi2_cur%ROWTYPE;

    BEGIN

      OPEN final_setubi2_cur;

        << final_setubi2_loop >>
        LOOP

          FETCH final_setubi2_cur INTO final_setubi2_rec;
          EXIT WHEN final_setubi2_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               final_setubi2_rec.lv_ref_type     -- 参照タイプ
              ,final_setubi2_rec.lv_ref_code     -- 参照コード
              ,final_setubi2_rec.lv_ref_name     -- 名称
              ,final_setubi2_rec.lv_pt_ref_type  -- 親参照タイプ
              ,final_setubi2_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE final_setubi2_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOTAI_KBN2');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-55.機器状態３(廃棄情報)取得
    DECLARE

      CURSOR final_setubi3_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja 
                                   AND   lookup_type = 'XXCSO1_CSI_JOTAI_KBN3'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      final_setubi3_rec final_setubi3_cur%ROWTYPE;

    BEGIN

      OPEN final_setubi3_cur;

        << final_setubi3_loop >>
        LOOP

          FETCH final_setubi3_cur INTO final_setubi3_rec;
          EXIT WHEN final_setubi3_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               final_setubi3_rec.lv_ref_type     -- 参照タイプ
              ,final_setubi3_rec.lv_ref_code     -- 参照コード
              ,final_setubi3_rec.lv_ref_name     -- 名称
              ,final_setubi3_rec.lv_pt_ref_type  -- 親参照タイプ
              ,final_setubi3_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE final_setubi3_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_JOTAI_KBN3');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-56.転売完了区分取得
    DECLARE

      CURSOR csi_kanryo_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCSO1_CSI_KANRYO_KBN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      csi_kanryo_rec csi_kanryo_cur%ROWTYPE;

    BEGIN

      OPEN csi_kanryo_cur;

        << csi_kanryo_loop >>
        LOOP

          FETCH csi_kanryo_cur INTO csi_kanryo_rec;
          EXIT WHEN csi_kanryo_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               csi_kanryo_rec.lv_ref_type     -- 参照タイプ
              ,csi_kanryo_rec.lv_ref_code     -- 参照コード
              ,csi_kanryo_rec.lv_ref_name     -- 名称
              ,csi_kanryo_rec.lv_pt_ref_type  -- 親参照タイプ
              ,csi_kanryo_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE csi_kanryo_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_KANRYO_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-57.最終作業進捗区分取得
    DECLARE

      CURSOR sintyoku_kbn_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja 
                                  AND   lookup_type = 'XXCSO1_CSI_SINTYOKU_KBN'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      sintyoku_kbn_rec sintyoku_kbn_cur%ROWTYPE;

    BEGIN

      OPEN sintyoku_kbn_cur;

        << sintyoku_loop >>
        LOOP

          FETCH sintyoku_kbn_cur INTO sintyoku_kbn_rec;
          EXIT WHEN sintyoku_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               sintyoku_kbn_rec.lv_ref_type     -- 参照タイプ
              ,sintyoku_kbn_rec.lv_ref_code     -- 参照コード
              ,sintyoku_kbn_rec.lv_ref_name     -- 名称
              ,sintyoku_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,sintyoku_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sintyoku_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_SINTYOKU_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-58.最終設置進捗区分取得
    DECLARE

      CURSOR sintyoku_kbn2_cur IS
                                   SELECT 
                                          lookup_type AS lv_ref_type 
                                         ,lookup_code AS lv_ref_code 
                                         ,meaning     AS lv_ref_name                                 
                                         ,NULL        AS lv_pt_ref_type     
                                         ,NULL        AS lv_pt_ref_code
                                   FROM  fnd_lookup_values
                                   WHERE language = cv_language_ja
                                   AND   lookup_type = 'XXCSO1_CSI_SINTYOKU_KBN2'
                                   AND   enabled_flag = cv_y_flag
                                   ORDER BY lookup_code;

      sintyoku_kbn2_rec sintyoku_kbn2_cur%ROWTYPE;

    BEGIN

      OPEN sintyoku_kbn2_cur;

        << sintyoku_kbn2_loop >>
        LOOP

          FETCH sintyoku_kbn2_cur INTO sintyoku_kbn2_rec;
          EXIT WHEN sintyoku_kbn2_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               sintyoku_kbn2_rec.lv_ref_type     -- 参照タイプ
              ,sintyoku_kbn2_rec.lv_ref_code     -- 参照コード
              ,sintyoku_kbn2_rec.lv_ref_name     -- 名称
              ,sintyoku_kbn2_rec.lv_pt_ref_type  -- 親参照タイプ
              ,sintyoku_kbn2_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sintyoku_kbn2_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_SINTYOKU_KBN2');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-59.転売廃棄状況フラグ取得
    DECLARE

      CURSOR tenhai_flg_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type
                                      ,lookup_code AS lv_ref_code
                                      ,meaning     AS lv_ref_name
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCSO1_CSI_TENHAI_FLG'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      tenhai_flg_rec tenhai_flg_cur%ROWTYPE;
     
    BEGIN

      OPEN tenhai_flg_cur;

        << tenhai_loop >>
        LOOP

          FETCH tenhai_flg_cur INTO tenhai_flg_rec;
          EXIT WHEN tenhai_flg_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               tenhai_flg_rec.lv_ref_type     -- 参照タイプ
              ,tenhai_flg_rec.lv_ref_code     -- 参照コード
              ,tenhai_flg_rec.lv_ref_name     -- 名称
              ,tenhai_flg_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tenhai_flg_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tenhai_flg_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_CSI_TENHAI_FLG');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-60.有効訪問区分取得
    DECLARE

      CURSOR visit_kbn_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSO1_EFFECTIVE_VISIT_CL'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      visit_kbn_rec visit_kbn_cur%ROWTYPE;

    BEGIN

      OPEN visit_kbn_cur;

        << visit_kbn_loop >>
        LOOP

          FETCH visit_kbn_cur INTO visit_kbn_rec;
          EXIT WHEN visit_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               visit_kbn_rec.lv_ref_type     -- 参照タイプ
              ,visit_kbn_rec.lv_ref_code     -- 参照コード
              ,visit_kbn_rec.lv_ref_name     -- 名称
              ,visit_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,visit_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE visit_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_EFFECTIVE_VISIT_CL');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;    

    --1-61.廃棄フラグ取得
    DECLARE

      CURSOR haiki_kbn_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCSO1_HAIKI_FLG'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      haiki_kbn_rec haiki_kbn_cur%ROWTYPE;

    BEGIN

      OPEN haiki_kbn_cur;

        << haiki_kbn_loop >>
        LOOP

          FETCH haiki_kbn_cur INTO haiki_kbn_rec;
          EXIT WHEN haiki_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               haiki_kbn_rec.lv_ref_type     -- 参照タイプ
              ,haiki_kbn_rec.lv_ref_code     -- 参照コード
              ,haiki_kbn_rec.lv_ref_name     -- 名称
              ,haiki_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,haiki_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE haiki_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_HAIKI_FLG');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-62.IB作業データ削除フラグ取得
    DECLARE

      CURSOR sakujyo_kbn_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type 
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL        AS lv_pt_ref_type     
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja
                                 AND   lookup_type = 'XXCSO1_IB_IBWRK_SAKUJYO_FLG'
                                 AND   enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      sakujyo_kbn_rec sakujyo_kbn_cur%ROWTYPE;

    BEGIN

      OPEN sakujyo_kbn_cur;

        << sakujyo_kbn_loop >>
        LOOP

          FETCH sakujyo_kbn_cur INTO sakujyo_kbn_rec;
          EXIT WHEN sakujyo_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               sakujyo_kbn_rec.lv_ref_type     -- 参照タイプ
              ,sakujyo_kbn_rec.lv_ref_code     -- 参照コード
              ,sakujyo_kbn_rec.lv_ref_name     -- 名称
              ,sakujyo_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,sakujyo_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sakujyo_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_IB_IBWRK_SAKUJYO_FLG');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;


    --1-63.ステータス取得
    DECLARE

      CURSOR inst_status_cur IS
                                 SELECT 
                                        lookup_type AS lv_ref_type
                                       ,lookup_code AS lv_ref_code 
                                       ,meaning     AS lv_ref_name                                 
                                       ,NULL AS lv_pt_ref_type     
                                       ,NULL        AS lv_pt_ref_code
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja
                                 AND   lookup_type = 'XXCSO1_INSTANCE_STATUS'
                                 AND    enabled_flag = cv_y_flag
                                 ORDER BY lookup_code;

      inst_status_rec inst_status_cur%ROWTYPE;

    BEGIN

      OPEN inst_status_cur;

        << inst_status_loop >>
        LOOP

          FETCH inst_status_cur INTO inst_status_rec;
          EXIT WHEN inst_status_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               inst_status_rec.lv_ref_type     -- 参照タイプ
              ,inst_status_rec.lv_ref_code     -- 参照コード
              ,inst_status_rec.lv_ref_name     -- 名称
              ,inst_status_rec.lv_pt_ref_type  -- 親参照タイプ
              ,inst_status_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE inst_status_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_INSTANCE_STATUS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-64.見積区分取得
    DECLARE

      CURSOR quote_kbn_cur IS
                               SELECT  
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type     
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja 
                               AND   lookup_type = 'XXCSO1_QUOTE_DIVISION'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      quote_kbn_rec quote_kbn_cur%ROWTYPE;

    BEGIN

      OPEN quote_kbn_cur;

        << quote_kbn_loop >>
        LOOP

          FETCH quote_kbn_cur INTO quote_kbn_rec;
          EXIT WHEN quote_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               quote_kbn_rec.lv_ref_type     -- 参照タイプ
              ,quote_kbn_rec.lv_ref_code     -- 参照コード
              ,quote_kbn_rec.lv_ref_name     -- 名称
              ,quote_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,quote_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE quote_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_QUOTE_DIVISION');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-65.見積ステータスコード取得
    DECLARE

      CURSOR quote_status_cur IS
                                  SELECT 
                                         lookup_type AS lv_ref_type 
                                        ,lookup_code AS lv_ref_code 
                                        ,meaning     AS lv_ref_name                                 
                                        ,NULL        AS lv_pt_ref_type     
                                        ,NULL        AS lv_pt_ref_code
                                  FROM  fnd_lookup_values
                                  WHERE language = cv_language_ja
                                  AND   lookup_type = 'XXCSO1_QUOTE_STATUS'
                                  AND   enabled_flag = cv_y_flag
                                  ORDER BY lookup_code;

      quote_status_rec quote_status_cur%ROWTYPE;

    BEGIN

      OPEN quote_status_cur;

        << quote_status_loop >>
        LOOP

          FETCH quote_status_cur INTO quote_status_rec;
          EXIT WHEN quote_status_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               quote_status_rec.lv_ref_type     -- 参照タイプ
              ,quote_status_rec.lv_ref_code     -- 参照コード
              ,quote_status_rec.lv_ref_name     -- 名称
              ,quote_status_rec.lv_pt_ref_type  -- 親参照タイプ
              ,quote_status_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE quote_status_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_QUOTE_STATUS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-66.見積種類取得
    DECLARE

      CURSOR quote_type_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type     
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja 
                                AND   lookup_type = 'XXCSO1_QUOTE_TYPE'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      quote_type_rec quote_type_cur%ROWTYPE;

    BEGIN

      OPEN quote_type_cur;

        << quote_type_loop >>
        LOOP

          FETCH quote_type_cur INTO quote_type_rec;
          EXIT WHEN quote_type_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               quote_type_rec.lv_ref_type     -- 参照タイプ
              ,quote_type_rec.lv_ref_code     -- 参照コード
              ,quote_type_rec.lv_ref_name     -- 名称
              ,quote_type_rec.lv_pt_ref_type  -- 親参照タイプ
              ,quote_type_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE quote_type_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_QUOTE_TYPE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-67.最終整備内容取得
    DECLARE

      CURSOR sagyo_lvl_cur IS
                               SELECT 
                                      lookup_type AS lv_ref_type 
                                     ,lookup_code AS lv_ref_code 
                                     ,meaning     AS lv_ref_name                                 
                                     ,NULL        AS lv_pt_ref_type
                                     ,NULL        AS lv_pt_ref_code
                               FROM  fnd_lookup_values
                               WHERE language = cv_language_ja
                               AND   lookup_type = 'XXCSO1_SAGYO_LEVEL'
                               AND   enabled_flag = cv_y_flag
                               ORDER BY lookup_code;

      sagyo_lvl_rec sagyo_lvl_cur%ROWTYPE;

    BEGIN

      OPEN sagyo_lvl_cur;

        << sagyo_lvl_loop >>
        LOOP

          FETCH sagyo_lvl_cur INTO sagyo_lvl_rec;
          EXIT WHEN sagyo_lvl_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               sagyo_lvl_rec.lv_ref_type     -- 参照タイプ
              ,sagyo_lvl_rec.lv_ref_code     -- 参照コード
              ,sagyo_lvl_rec.lv_ref_name     -- 名称
              ,sagyo_lvl_rec.lv_pt_ref_type  -- 親参照タイプ
              ,sagyo_lvl_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE sagyo_lvl_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_SAGYO_LEVEL');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-68.資産区分取得
    DECLARE

      CURSOR seisan_kbn_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCSO1_SHISAN_KBN'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      seisan_kbn_rec seisan_kbn_cur%ROWTYPE;

    BEGIN

      OPEN seisan_kbn_cur;

        << seisan_kbn_loop >>
        LOOP

          FETCH seisan_kbn_cur INTO seisan_kbn_rec;
          EXIT WHEN seisan_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               seisan_kbn_rec.lv_ref_type     -- 参照タイプ
              ,seisan_kbn_rec.lv_ref_code     -- 参照コード
              ,seisan_kbn_rec.lv_ref_name     -- 名称
              ,seisan_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,seisan_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE seisan_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_SHISAN_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-69.作業会社コード取得
    DECLARE

      CURSOR syozoku_mst_cur IS
-- 2009/04/03 Ver1.2 modify start by Yutaka.Kuboshima
--                                 SELECT 
--                                        lookup_type AS lv_ref_type 
--                                       ,lookup_code AS lv_ref_code 
--                                       ,meaning     AS lv_ref_name                                 
--                                       ,NULL        AS lv_pt_ref_type
--                                       ,NULL        AS lv_pt_ref_code
                                 SELECT DISTINCT
                                        lookup_type AS lv_ref_type
                                       ,attribute1  AS lv_ref_code
                                       ,attribute6  AS lv_ref_name
                                       ,NULL        AS lv_pt_ref_type
                                       ,NULL        AS lv_pt_ref_code
-- 2009/04/03 Ver1.2 modify end by Yutaka.Kuboshima
                                 FROM  fnd_lookup_values
                                 WHERE language = cv_language_ja
                                 AND   lookup_type = 'XXCSO1_SYOZOKU_MST'
                                 AND   enabled_flag = cv_y_flag
-- 2009/04/03 Ver1.2 modify start by Yutaka.Kuboshima
--                                 ORDER BY lookup_code;
                                 ORDER BY attribute1;
-- 2009/04/03 Ver1.2 modify end by Yutaka.Kuboshima
      syozoku_mst_rec syozoku_mst_cur%ROWTYPE;
     
    BEGIN

      OPEN syozoku_mst_cur;

        << syozoku_mst_loop >>
        LOOP

          FETCH syozoku_mst_cur INTO syozoku_mst_rec;
          EXIT WHEN syozoku_mst_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               syozoku_mst_rec.lv_ref_type     -- 参照タイプ
              ,syozoku_mst_rec.lv_ref_code     -- 参照コード
              ,syozoku_mst_rec.lv_ref_name     -- 名称
              ,syozoku_mst_rec.lv_pt_ref_type  -- 親参照タイプ
              ,syozoku_mst_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE syozoku_mst_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_SYOZOKU_MST');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-70.事業所コード取得
    DECLARE

      CURSOR jigyosyo_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
-- 2009/04/03 Ver1.2 modify start by Yutaka.Kuboshima
--                                    ,lookup_code AS lv_ref_code 
--                                    ,meaning     AS lv_ref_name                                 
                                    ,attribute2  AS lv_ref_code
                                    ,attribute7  AS lv_ref_name
-- 2009/04/03 Ver1.2 modify end by Yutaka.Kuboshima
                                    ,'XXCSO1_SYOZOKU_MST_DFF1' AS lv_pt_ref_type     
                                    ,attribute1  AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja
                              AND   lookup_type = 'XXCSO1_SYOZOKU_MST'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

     jigyosyo_rec jigyosyo_cur%ROWTYPE;

    BEGIN

      OPEN jigyosyo_cur;

        << jigyosyo_loop >>
        LOOP

          FETCH jigyosyo_cur INTO jigyosyo_rec;
          EXIT WHEN jigyosyo_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               jigyosyo_rec.lv_ref_type     -- 参照タイプ
              ,jigyosyo_rec.lv_ref_code     -- 参照コード
              ,jigyosyo_rec.lv_ref_name     -- 名称
              ,jigyosyo_rec.lv_pt_ref_type  -- 親参照タイプ
              ,jigyosyo_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE jigyosyo_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_SYOZOKU_MST');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-71.タスクテーブル削除フラグ取得
    DECLARE

      CURSOR task_del_cur IS 
                              SELECT  
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja 
                              AND   lookup_type = 'XXCSO1_TASK_DELETE_FLG'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      task_del_rec task_del_cur%ROWTYPE;

    BEGIN

      OPEN task_del_cur;

        << task_del_loop >>
        LOOP

          FETCH task_del_cur INTO task_del_rec;
          EXIT WHEN task_del_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               task_del_rec.lv_ref_type     -- 参照タイプ
              ,task_del_rec.lv_ref_code     -- 参照コード
              ,task_del_rec.lv_ref_name     -- 名称
              ,task_del_rec.lv_pt_ref_type  -- 親参照タイプ
              ,task_del_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE task_del_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_TASK_DELETE_FLG');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-72.店納価格税区分取得
    DECLARE

      CURSOR tax_div_cur IS 
                             SELECT 
                                    lookup_type AS lv_ref_type 
                                   ,lookup_code AS lv_ref_code 
                                   ,meaning     AS lv_ref_name                                 
                                   ,NULL        AS lv_pt_ref_type     
                                   ,NULL        AS lv_pt_ref_code
                             FROM  fnd_lookup_values
                             WHERE language = cv_language_ja
                             AND   lookup_type = 'XXCSO1_TAX_DIVISION'
                             AND   enabled_flag = cv_y_flag
                             ORDER BY lookup_code;

      tax_div_rec tax_div_cur%ROWTYPE;
     
    BEGIN

      OPEN tax_div_cur;

        << tax_div_loop >>
        LOOP

          FETCH tax_div_cur INTO tax_div_rec;
          EXIT WHEN tax_div_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               tax_div_rec.lv_ref_type     -- 参照タイプ
              ,tax_div_rec.lv_ref_code     -- 参照コード
              ,tax_div_rec.lv_ref_name     -- 名称
              ,tax_div_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tax_div_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tax_div_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_TAX_DIVISION');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-73.転売廃棄業者取得
    DECLARE

      CURSOR tenhai_tan_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCSO1_TENHAI_TANTO'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      tenhai_tan_rec tenhai_tan_cur%ROWTYPE;

    BEGIN

      OPEN tenhai_tan_cur;

        << tenhai_tan_loop >>
        LOOP

          FETCH tenhai_tan_cur INTO tenhai_tan_rec;
          EXIT WHEN tenhai_tan_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               tenhai_tan_rec.lv_ref_type     -- 参照タイプ
              ,tenhai_tan_rec.lv_ref_code     -- 参照コード
              ,tenhai_tan_rec.lv_ref_name     -- 名称
              ,tenhai_tan_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tenhai_tan_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tenhai_tan_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_TENHAI_TANTO');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-74.単価区分取得
    DECLARE

      CURSOR unit_price_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type
                                      ,lookup_code AS lv_ref_code
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type     
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCSO1_UNIT_PRICE_DIVISION'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      unit_price_rec unit_price_cur%ROWTYPE;
     
    BEGIN

      OPEN unit_price_cur;

        << unit_price_loop >>
        LOOP

          FETCH unit_price_cur INTO unit_price_rec;
          EXIT WHEN unit_price_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               unit_price_rec.lv_ref_type     -- 参照タイプ
              ,unit_price_rec.lv_ref_code     -- 参照コード
              ,unit_price_rec.lv_ref_name     -- 名称
              ,unit_price_rec.lv_pt_ref_type  -- 親参照タイプ
              ,unit_price_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE unit_price_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_UNIT_PRICE_DIVISION');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    
    --1-75.他社コード１取得
    DECLARE

      CURSOR tasya_code_cur IS
                                SELECT 
                                       lookup_type AS lv_ref_type 
                                      ,lookup_code AS lv_ref_code 
                                      ,meaning     AS lv_ref_name                                 
                                      ,NULL        AS lv_pt_ref_type
                                      ,NULL        AS lv_pt_ref_code
                                FROM  fnd_lookup_values
                                WHERE language = cv_language_ja
                                AND   lookup_type = 'XXCSO1_VEN_TASYA_CODE'
                                AND   enabled_flag = cv_y_flag
                                ORDER BY lookup_code;

      tasya_code_rec tasya_code_cur%ROWTYPE;
     
    BEGIN

      OPEN tasya_code_cur;

        << tasya_code_loop >>
        LOOP

          FETCH tasya_code_cur INTO tasya_code_rec;
          EXIT WHEN tasya_code_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               tasya_code_rec.lv_ref_type     -- 参照タイプ
              ,tasya_code_rec.lv_ref_code     -- 参照コード
              ,tasya_code_rec.lv_ref_name     -- 名称
              ,tasya_code_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tasya_code_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tasya_code_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_VEN_TASYA_CODE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-76.作業依頼中フラグ取得
    DECLARE

      CURSOR req_code_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type     
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja
                              AND   lookup_type = 'XXCSO1_WK_REQ_FLG'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      req_code_rec req_code_cur%ROWTYPE;
     
    BEGIN

      OPEN req_code_cur;

        << req_code_loop >>
        LOOP

          FETCH req_code_cur INTO req_code_rec;
          EXIT WHEN req_code_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               req_code_rec.lv_ref_type     -- 参照タイプ
              ,req_code_rec.lv_ref_code     -- 参照コード
              ,req_code_rec.lv_ref_name     -- 名称
              ,req_code_rec.lv_pt_ref_type  -- 親参照タイプ
              ,req_code_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE req_code_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_WK_REQ_FLG');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --1-77.リース区分取得
    DECLARE

      CURSOR req_code_cur IS
                              SELECT 
                                     lookup_type AS lv_ref_type 
                                    ,lookup_code AS lv_ref_code 
                                    ,meaning     AS lv_ref_name                                 
                                    ,NULL        AS lv_pt_ref_type     
                                    ,NULL        AS lv_pt_ref_code
                              FROM  fnd_lookup_values
                              WHERE language = cv_language_ja
                              AND   lookup_type = 'XXCSO1_LEASE_KBN'
                              AND   enabled_flag = cv_y_flag
                              ORDER BY lookup_code;

      req_code_rec req_code_cur%ROWTYPE;
     
    BEGIN

      OPEN req_code_cur;

        << req_code_loop >>
        LOOP

          FETCH req_code_cur INTO req_code_rec;
          EXIT WHEN req_code_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               req_code_rec.lv_ref_type     -- 参照タイプ
              ,req_code_rec.lv_ref_code     -- 参照コード
              ,req_code_rec.lv_ref_name     -- 名称
              ,req_code_rec.lv_pt_ref_type  -- 親参照タイプ
              ,req_code_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE req_code_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_LEASE_KBN');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
-- 2009/05/28 Ver1.4 add start by Yutaka.Kuboshima
    -- 1-78.新規評価対象区分取得
    DECLARE
      CURSOR eva_code_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCSM1_EVALURATION_KBN'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      eva_code_rec eva_code_cur%ROWTYPE;
    BEGIN
      OPEN eva_code_cur;
        << eva_code_loop >>
        LOOP
          FETCH eva_code_cur INTO eva_code_rec;
          EXIT WHEN eva_code_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               eva_code_rec.lv_ref_type     -- 参照タイプ
              ,eva_code_rec.lv_ref_code     -- 参照コード
              ,eva_code_rec.lv_ref_name     -- 名称
              ,eva_code_rec.lv_pt_ref_type  -- 親参照タイプ
              ,eva_code_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE eva_code_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSM1_EVALURATION_KBN');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
-- 2009/05/28 Ver1.4 add end by Yutaka.Kuboshima
-- 2009/06/03 Ver1.5 add start by Yutaka.Kuboshima
    -- 1-79.消費税区分取得
    DECLARE
      CURSOR syohizei_kbn_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_CSUT_SYOHIZEI_KBN'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      syohizai_kbn_rec syohizei_kbn_cur%ROWTYPE;
    BEGIN
      OPEN syohizei_kbn_cur;
        << syohizai_kbn_loop >>
        LOOP
          FETCH syohizei_kbn_cur INTO syohizai_kbn_rec;
          EXIT WHEN syohizei_kbn_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               syohizai_kbn_rec.lv_ref_type     -- 参照タイプ
              ,syohizai_kbn_rec.lv_ref_code     -- 参照コード
              ,syohizai_kbn_rec.lv_ref_name     -- 名称
              ,syohizai_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,syohizai_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE syohizei_kbn_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CSUT_SYOHIZEI_KBN');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
-- 2009/06/03 Ver1.5 add end by Yutaka.Kuboshim
-- 2009/07/13 Ver1.7 障害0000655,0000656 add start by Yutaka.Kuboshima
    -- 1-80.関連分類取得
    DECLARE
      CURSOR relation_class_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_CUST_KANREN_BUNRUI'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      relation_class_rec relation_class_cur%ROWTYPE;
    BEGIN
      OPEN relation_class_cur;
        << relation_class_loop >>
        LOOP
          FETCH relation_class_cur INTO relation_class_rec;
          EXIT WHEN relation_class_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               relation_class_rec.lv_ref_type     -- 参照タイプ
              ,relation_class_rec.lv_ref_code     -- 参照コード
              ,relation_class_rec.lv_ref_name     -- 名称
              ,relation_class_rec.lv_pt_ref_type  -- 親参照タイプ
              ,relation_class_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE relation_class_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_KANREN_BUNRUI');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-81.税金－計算取得
    DECLARE
      CURSOR tax_calculation_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'AR_TAX_CALCULATION_LEVEL'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      tax_calculation_rec tax_calculation_cur%ROWTYPE;
    BEGIN
      OPEN tax_calculation_cur;
        << tax_calculation_loop >>
        LOOP
          FETCH tax_calculation_cur INTO tax_calculation_rec;
          EXIT WHEN tax_calculation_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               tax_calculation_rec.lv_ref_type     -- 参照タイプ
              ,tax_calculation_rec.lv_ref_code     -- 参照コード
              ,tax_calculation_rec.lv_ref_name     -- 名称
              ,tax_calculation_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tax_calculation_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE tax_calculation_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'AR_TAX_CALCULATION_LEVEL');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-82.税金－端数処理取得
    DECLARE
      CURSOR tax_rounding_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'AR_TAX_ROUNDING_RULE'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      tax_rounding_rec tax_rounding_cur%ROWTYPE;
    BEGIN
      OPEN tax_rounding_cur;
        << tax_rounding_loop >>
        LOOP
          FETCH tax_rounding_cur INTO tax_rounding_rec;
          EXIT WHEN tax_rounding_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               tax_rounding_rec.lv_ref_type     -- 参照タイプ
              ,tax_rounding_rec.lv_ref_code     -- 参照コード
              ,tax_rounding_rec.lv_ref_name     -- 名称
              ,tax_rounding_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tax_rounding_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE tax_rounding_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'AR_TAX_ROUNDING_RULE');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-83.新規／更新フラグ取得
    DECLARE
      CURSOR update_flag_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_CUST_UPDATE_FLG'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      update_flag_rec update_flag_cur%ROWTYPE;
    BEGIN
      OPEN update_flag_cur;
        << update_flag_loop >>
        LOOP
          FETCH update_flag_cur INTO update_flag_rec;
          EXIT WHEN update_flag_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               update_flag_rec.lv_ref_type     -- 参照タイプ
              ,update_flag_rec.lv_ref_code     -- 参照コード
              ,update_flag_rec.lv_ref_name     -- 名称
              ,update_flag_rec.lv_pt_ref_type  -- 親参照タイプ
              ,update_flag_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE update_flag_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_UPDATE_FLG');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-84.カード会社区分取得
    DECLARE
      CURSOR card_company_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_CUST_CARD_COMPANY_KBN'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      card_company_rec card_company_cur%ROWTYPE;
    BEGIN
      OPEN card_company_cur;
        << card_company_loop >>
        LOOP
          FETCH card_company_cur INTO card_company_rec;
          EXIT WHEN card_company_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               card_company_rec.lv_ref_type     -- 参照タイプ
              ,card_company_rec.lv_ref_code     -- 参照コード
              ,card_company_rec.lv_ref_name     -- 名称
              ,card_company_rec.lv_pt_ref_type  -- 親参照タイプ
              ,card_company_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE card_company_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CUST_CARD_COMPANY_KBN');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-85.売上対象区分取得
    DECLARE
      CURSOR sales_target_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMN_SALES_TARGET_CLASS'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      sales_target_rec sales_target_cur%ROWTYPE;
    BEGIN
      OPEN sales_target_cur;
        << sales_target_loop >>
        LOOP
          FETCH sales_target_cur INTO sales_target_rec;
          EXIT WHEN sales_target_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               sales_target_rec.lv_ref_type     -- 参照タイプ
              ,sales_target_rec.lv_ref_code     -- 参照コード
              ,sales_target_rec.lv_ref_name     -- 名称
              ,sales_target_rec.lv_pt_ref_type  -- 親参照タイプ
              ,sales_target_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE sales_target_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMN_SALES_TARGET_CLASS');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-86.率区分取得
    DECLARE
      CURSOR rate_class_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_ITM_RATE_CLASS'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      rate_class_rec rate_class_cur%ROWTYPE;
    BEGIN
      OPEN rate_class_cur;
        << rate_class_loop >>
        LOOP
          FETCH rate_class_cur INTO rate_class_rec;
          EXIT WHEN rate_class_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               rate_class_rec.lv_ref_type     -- 参照タイプ
              ,rate_class_rec.lv_ref_code     -- 参照コード
              ,rate_class_rec.lv_ref_name     -- 名称
              ,rate_class_rec.lv_pt_ref_type  -- 親参照タイプ
              ,rate_class_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE rate_class_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_RATE_CLASS');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-87.内容量単位取得
    DECLARE
      CURSOR net_uom_code_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_ITM_NET_UOM_CODE'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      net_uom_code_rec net_uom_code_cur%ROWTYPE;
    BEGIN
      OPEN net_uom_code_cur;
        << net_uom_code_loop >>
        LOOP
          FETCH net_uom_code_cur INTO net_uom_code_rec;
          EXIT WHEN net_uom_code_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               net_uom_code_rec.lv_ref_type     -- 参照タイプ
              ,net_uom_code_rec.lv_ref_code     -- 参照コード
              ,net_uom_code_rec.lv_ref_name     -- 名称
              ,net_uom_code_rec.lv_pt_ref_type  -- 親参照タイプ
              ,net_uom_code_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE net_uom_code_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_NET_UOM_CODE');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-88.バラ茶区分取得
    DECLARE
      CURSOR barachakubun_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_ITM_BARACHAKUBUN'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      barachakubun_rec barachakubun_cur%ROWTYPE;
    BEGIN
      OPEN barachakubun_cur;
        << barachakubun_loop >>
        LOOP
          FETCH barachakubun_cur INTO barachakubun_rec;
          EXIT WHEN barachakubun_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               barachakubun_rec.lv_ref_type     -- 参照タイプ
              ,barachakubun_rec.lv_ref_code     -- 参照コード
              ,barachakubun_rec.lv_ref_name     -- 名称
              ,barachakubun_rec.lv_pt_ref_type  -- 親参照タイプ
              ,barachakubun_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE barachakubun_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_BARACHAKUBUN');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-89.商品分類取得
    DECLARE
      CURSOR item_relation_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMN_D02'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      item_relation_rec item_relation_cur%ROWTYPE;
    BEGIN
      OPEN item_relation_cur;
        << item_relation_loop >>
        LOOP
          FETCH item_relation_cur INTO item_relation_rec;
          EXIT WHEN item_relation_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               item_relation_rec.lv_ref_type     -- 参照タイプ
              ,item_relation_rec.lv_ref_code     -- 参照コード
              ,item_relation_rec.lv_ref_name     -- 名称
              ,item_relation_rec.lv_pt_ref_type  -- 親参照タイプ
              ,item_relation_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE item_relation_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMN_D02');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-90.新商品区分取得
    DECLARE
      CURSOR shinsyohinkubun_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_ITM_SHINSYOHINKUBUN'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      shinsyohinkubun_rec shinsyohinkubun_cur%ROWTYPE;
    BEGIN
      OPEN shinsyohinkubun_cur;
        << shinsyohinkubun_loop >>
        LOOP
          FETCH shinsyohinkubun_cur INTO shinsyohinkubun_rec;
          EXIT WHEN shinsyohinkubun_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               shinsyohinkubun_rec.lv_ref_type     -- 参照タイプ
              ,shinsyohinkubun_rec.lv_ref_code     -- 参照コード
              ,shinsyohinkubun_rec.lv_ref_name     -- 名称
              ,shinsyohinkubun_rec.lv_pt_ref_type  -- 親参照タイプ
              ,shinsyohinkubun_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE shinsyohinkubun_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_SHINSYOHINKUBUN');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-91.専門店仕入先取得
    DECLARE
      CURSOR senmonten_shiiresaki_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.description AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_ITM_SENMONTEN_SHIIRESAKI'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      senmonten_shiiresaki_rec senmonten_shiiresaki_cur%ROWTYPE;
    BEGIN
      OPEN senmonten_shiiresaki_cur;
        << senmonten_shiiresaki_loop >>
        LOOP
          FETCH senmonten_shiiresaki_cur INTO senmonten_shiiresaki_rec;
          EXIT WHEN senmonten_shiiresaki_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               senmonten_shiiresaki_rec.lv_ref_type     -- 参照タイプ
              ,senmonten_shiiresaki_rec.lv_ref_code     -- 参照コード
              ,senmonten_shiiresaki_rec.lv_ref_name     -- 名称
              ,senmonten_shiiresaki_rec.lv_pt_ref_type  -- 親参照タイプ
              ,senmonten_shiiresaki_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE senmonten_shiiresaki_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_SENMONTEN_SHIIRESAKI');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-92.経理容器群コード取得
    DECLARE
      CURSOR keriyokigun_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_ITM_KERIYOKIGUN'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      keriyokigun_rec keriyokigun_cur%ROWTYPE;
    BEGIN
      OPEN keriyokigun_cur;
        << keriyokigun_loop >>
        LOOP
          FETCH keriyokigun_cur INTO keriyokigun_rec;
          EXIT WHEN keriyokigun_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               keriyokigun_rec.lv_ref_type     -- 参照タイプ
              ,keriyokigun_rec.lv_ref_code     -- 参照コード
              ,keriyokigun_rec.lv_ref_name     -- 名称
              ,keriyokigun_rec.lv_pt_ref_type  -- 親参照タイプ
              ,keriyokigun_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE keriyokigun_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_KERIYOKIGUN');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-93.ブランド群取得
    DECLARE
      CURSOR brandgun_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_ITM_BRANDGUN'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      brandgun_rec brandgun_cur%ROWTYPE;
    BEGIN
      OPEN brandgun_cur;
        << brandgun_loop >>
        LOOP
          FETCH brandgun_cur INTO brandgun_rec;
          EXIT WHEN brandgun_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               brandgun_rec.lv_ref_type     -- 参照タイプ
              ,brandgun_rec.lv_ref_code     -- 参照コード
              ,brandgun_rec.lv_ref_name     -- 名称
              ,brandgun_rec.lv_pt_ref_type  -- 親参照タイプ
              ,brandgun_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP;
      CLOSE brandgun_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_ITM_BRANDGUN');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
-- 2009/07/13 Ver1.7 障害0000655,0000656 add end by Yutaka.Kuboshima
-- 2009/09/30 Ver1.8 障害0001350 add start by Yutaka.Kuboshima
    -- 1-94.請求書印刷単位取得
    DECLARE
      CURSOR inv_print_unit_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_INVOICE_PRINTING_UNIT'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      inv_print_unit_rec inv_print_unit_cur%ROWTYPE;
    BEGIN
      OPEN inv_print_unit_cur;
        << inv_print_unit_loop >>
        LOOP
          FETCH inv_print_unit_cur INTO inv_print_unit_rec;
          EXIT WHEN inv_print_unit_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               inv_print_unit_rec.lv_ref_type     -- 参照タイプ
              ,inv_print_unit_rec.lv_ref_code     -- 参照コード
              ,inv_print_unit_rec.lv_ref_name     -- 名称
              ,inv_print_unit_rec.lv_pt_ref_type  -- 親参照タイプ
              ,inv_print_unit_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP inv_print_unit_loop;
      CLOSE inv_print_unit_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_INVOICE_PRINTING_UNIT');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
-- 2009/09/30 Ver1.8 障害0001350 add end by Yutaka.Kuboshima
--
-- 2019/01/25 Ver1.10 add start by Yasuhiro.Shoji
    -- 1-95.カテゴリー商品計上区分取得
    DECLARE
      CURSOR category_product_div_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCMM_CATEGORY_PRODUCT_DIV'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      category_product_div_rec category_product_div_cur%ROWTYPE;
    BEGIN
      OPEN category_product_div_cur;
        << category_product_div_loop >>
        LOOP
          FETCH category_product_div_cur INTO category_product_div_rec;
          EXIT WHEN category_product_div_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               category_product_div_rec.lv_ref_type     -- 参照タイプ
              ,category_product_div_rec.lv_ref_code     -- 参照コード
              ,category_product_div_rec.lv_ref_name     -- 名称
              ,category_product_div_rec.lv_pt_ref_type  -- 親参照タイプ
              ,category_product_div_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP category_product_div_loop;
      CLOSE category_product_div_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCMM_CATEGORY_PRODUCT_DIV');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
-- 2019/01/25 Ver1.10 add end by Yasuhiro.Shoji
-- 2019/04/03 Ver1.11 add start
    -- 1-96.消費税コード（軽減税率対応用）取得
    DECLARE
      CURSOR category_product_div_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCFO1_TAX_CODE'
        AND    flv.enabled_flag = cv_y_flag
        ORDER BY flv.lookup_code;
      tax_code_rec category_product_div_cur%ROWTYPE;
    BEGIN
      OPEN category_product_div_cur;
        << category_product_div_loop >>
        LOOP
          FETCH category_product_div_cur INTO tax_code_rec;
          EXIT WHEN category_product_div_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               tax_code_rec.lv_ref_type     -- 参照タイプ
              ,tax_code_rec.lv_ref_code     -- 参照コード
              ,tax_code_rec.lv_ref_name     -- 名称
              ,tax_code_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tax_code_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP category_product_div_loop;
      CLOSE category_product_div_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCFO1_TAX_CODE');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
    -- 1-97.消費税履歴（軽減税率対応用）取得
    DECLARE
      CURSOR category_product_div_cur
      IS
        SELECT flv.lookup_type   AS lv_ref_type
              ,flv.lookup_code   AS lv_ref_code
              ,flv.meaning       AS lv_ref_name
              ,'XXCFO1_TAX_CODE' AS lv_pt_ref_type
              ,flv.tag           AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCFO1_TAX_CODE_HISTORIES'
        AND    flv.enabled_flag = cv_y_flag
        AND    gd_process_date BETWEEN flv.start_date_active AND NVL(flv.end_date_active, TO_DATE(cv_max_date, cv_date_format))
        ORDER BY flv.lookup_code;
      tax_code_histories_rec category_product_div_cur%ROWTYPE;
    BEGIN
      OPEN category_product_div_cur;
        << category_product_div_loop >>
        LOOP
          FETCH category_product_div_cur INTO tax_code_histories_rec;
          EXIT WHEN category_product_div_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               tax_code_histories_rec.lv_ref_type     -- 参照タイプ
              ,tax_code_histories_rec.lv_ref_code     -- 参照コード
              ,tax_code_histories_rec.lv_ref_name     -- 名称
              ,tax_code_histories_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tax_code_histories_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP category_product_div_loop;
      CLOSE category_product_div_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCFO1_TAX_CODE_HISTORIES');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
-- 2019/04/03 Ver1.11 add end
-- 2020/08/21 Ver1.12 add start
    -- 1-98.BM税区分取得
    DECLARE
      CURSOR bm_tax_kbn_cur
      IS
        SELECT flv.lookup_type AS lv_ref_type
              ,flv.lookup_code AS lv_ref_code
              ,flv.meaning     AS lv_ref_name
              ,NULL            AS lv_pt_ref_type
              ,NULL            AS lv_pt_ref_code
        FROM   fnd_lookup_values flv
        WHERE  flv.language = cv_language_ja
        AND    flv.lookup_type = 'XXCSO1_BM_TAX_KBN'
        AND    flv.enabled_flag = cv_y_flag
        AND    gd_process_date BETWEEN flv.start_date_active AND NVL(flv.end_date_active, TO_DATE(cv_max_date, cv_date_format))
        ORDER BY flv.lookup_code;
      bm_tax_kbn_rec bm_tax_kbn_cur%ROWTYPE;
    BEGIN
      OPEN bm_tax_kbn_cur;
        << bm_tax_kbn_loop >>
        LOOP
          FETCH bm_tax_kbn_cur INTO bm_tax_kbn_rec;
          EXIT WHEN bm_tax_kbn_cur%NOTFOUND;
            -- ファイル出力
            write_csv(
               bm_tax_kbn_rec.lv_ref_type     -- 参照タイプ
              ,bm_tax_kbn_rec.lv_ref_code     -- 参照コード
              ,bm_tax_kbn_rec.lv_ref_name     -- 名称
              ,bm_tax_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,bm_tax_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );
            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;
        END LOOP bm_tax_kbn_loop;
      CLOSE bm_tax_kbn_cur;
      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_data_err_msg,
                                              cv_lookup_type,
                                              'XXCSO1_BM_TAX_KBN');
        ov_retcode := cv_status_warn;
        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;
      END IF;
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      ln_data_cnt := 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
-- 2020/08/21 Ver1.12 add end
    -- ===============================
    -- 2.品目カテゴリの取得
    -- =============================== 
    DECLARE

      CURSOR hinmoku_cat_cur IS
                                 SELECT
                                        DECODE(mtl_set_tl.category_set_name
                                              ,'政策群コード'
                                              ,'CATEGORY_SEISAKUGUN'
                                              ,'商品製品区分' 
                                              ,'CATEGORY_SYOHIN_KBN'
-- 2009/07/13 Ver1.7 障害0000656 add start by Yutaka.Kuboshima
                                              ,'本社商品区分'
                                              ,'CATEGORY_HONSYA_SYOHIN_KBN'
-- 2009/07/13 Ver1.7 障害0000656 add end by Yutaka.Kuboshima
                                        )                  AS lv_ref_type
                                       ,mtl_b.segment1     AS lv_ref_code
                                       ,mtl_tl.description AS lv_ref_name
                                       ,NULL               AS lv_pt_ref_type       
                                       ,NULL               AS lv_pt_ref_code
                                FROM   mtl_categories_b mtl_b           
                                      ,mtl_category_sets_b mtl_set
                                      ,mtl_category_sets_tl mtl_set_tl
                                      ,mtl_categories_tl mtl_tl
                                WHERE mtl_set_tl.category_set_id = mtl_set.category_set_id
                                AND   mtl_set.structure_id = mtl_b.structure_id
                                AND   mtl_tl.category_id = mtl_b.category_id
                                AND   mtl_set_tl.language = cv_language_ja
                                AND   mtl_tl.language = cv_language_ja
-- 2009/07/13 Ver1.7 障害0000656 modify start by Yutaka.Kuboshima
--                                AND   mtl_set_tl.category_set_name IN ('政策群コード', '商品製品区分')
                                AND   mtl_set_tl.category_set_name IN ('政策群コード', '商品製品区分', '本社商品区分')
-- 2009/07/13 Ver1.7 障害0000656 modify end by Yutaka.Kuboshima
                                ORDER BY mtl_set_tl.category_set_name
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                        ,mtl_b.attribute1;
                                        ,mtl_b.segment1;
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
      hinmoku_cat_rec hinmoku_cat_cur%ROWTYPE;
     
    BEGIN

      OPEN hinmoku_cat_cur;

        << hinmoku_cat_loop >>
        LOOP

          FETCH hinmoku_cat_cur INTO hinmoku_cat_rec;
          EXIT WHEN hinmoku_cat_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               hinmoku_cat_rec.lv_ref_type     -- 参照タイプ
              ,hinmoku_cat_rec.lv_ref_code     -- 参照コード
              ,hinmoku_cat_rec.lv_ref_name     -- 名称
              ,hinmoku_cat_rec.lv_pt_ref_type  -- 親参照タイプ
              ,hinmoku_cat_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE hinmoku_cat_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'MTL_CATEGORIES_B');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 3.支払条件マスタの取得
    -- ===============================
    DECLARE

      CURSOR shiharai_mst_cur IS
                                  SELECT  
                                          'RA_TERMS_TL' AS lv_ref_type
                                         ,name          AS lv_ref_code
                                         ,description   AS lv_ref_name
                                         ,NULL          AS lv_pt_ref_type      
                                         ,NULL          AS lv_pt_ref_code
                                  FROM   ra_terms_tl
                                  WHERE  language = cv_language_ja
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                  ORDER BY description;
                                  ORDER BY name;
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
      shiharai_mst_rec shiharai_mst_cur%ROWTYPE;

    BEGIN

      OPEN shiharai_mst_cur;

        << shiharai_mst_loop >>
        LOOP

          FETCH shiharai_mst_cur INTO shiharai_mst_rec;
          EXIT WHEN shiharai_mst_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               shiharai_mst_rec.lv_ref_type     -- 参照タイプ
              ,shiharai_mst_rec.lv_ref_code     -- 参照コード
              ,shiharai_mst_rec.lv_ref_name     -- 名称
              ,shiharai_mst_rec.lv_pt_ref_type  -- 親参照タイプ
              ,shiharai_mst_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE shiharai_mst_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'RA_TERM_TL');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 4.チェーン店(EDI)の取得
    -- ===============================
    DECLARE

      CURSOR edi_chain_cur IS
                               SELECT
                                       'EDI_CHAIN_CODE'      AS lv_ref_type
                                      ,xxcust.edi_chain_code AS lv_ref_code
                                      ,hzcust.account_name   AS lv_ref_name
                                      ,NULL                  AS lv_pt_ref_type
                                      ,NULL                  AS lv_pt_ref_code
                               FROM    xxcmm_cust_accounts xxcust
                                      ,hz_cust_accounts hzcust
                               WHERE  hzcust.cust_account_id = xxcust.customer_id
                               AND    hzcust.customer_class_code = '18'
                               AND    xxcust.edi_chain_code IS NOT NULL
                               ORDER BY xxcust.edi_chain_code;

      edi_chain_rec edi_chain_cur%ROWTYPE;

    BEGIN

      OPEN edi_chain_cur;

        << edi_chain_loop >>
        LOOP

          FETCH edi_chain_cur INTO edi_chain_rec;
          EXIT WHEN edi_chain_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               edi_chain_rec.lv_ref_type     -- 参照タイプ
              ,edi_chain_rec.lv_ref_code     -- 参照コード
              ,edi_chain_rec.lv_ref_name     -- 名称
              ,edi_chain_rec.lv_pt_ref_type  -- 親参照タイプ
              ,edi_chain_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE edi_chain_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'HZ_CUST_ACCOUNTS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 5.百貨店伝区の取得
    -- ===============================
    DECLARE

      CURSOR depart_cur IS
                            SELECT 
                                   'HYAKKATENDENKU_CODE'          AS  lv_ref_type
                                  ,cmm_cust.parnt_dept_shop_code  AS  lv_ref_code
                                  ,hz_cust.ACCOUNT_NAME           AS  lv_ref_name
                                  ,NULL                           AS  lv_pt_ref_type
                                  ,NULL                           AS  lv_pt_ref_code
                            FROM   hz_cust_accounts  hz_cust
                                  ,xxcmm_cust_accounts cmm_cust
                            WHERE hz_cust.CUST_ACCOUNT_ID = cmm_cust.CUSTOMER_ID
                            AND   hz_cust.CUSTOMER_CLASS_CODE = '19'
                            AND   cmm_cust.parnt_dept_shop_code IS NOT NULL
                            ORDER BY cmm_cust.parnt_dept_shop_code;

      depart_rec depart_cur%ROWTYPE;

    BEGIN

      OPEN depart_cur;

        << depart_loop >>
        LOOP

          FETCH depart_cur INTO depart_rec;
          EXIT WHEN depart_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               depart_rec.lv_ref_type     -- 参照タイプ
              ,depart_rec.lv_ref_code     -- 参照コード
              ,depart_rec.lv_ref_name     -- 名称
              ,depart_rec.lv_pt_ref_type  -- 親参照タイプ
              ,depart_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE depart_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'HYAKKATENDENKU_CODE');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 6.OPM保管場所マスタ情報取得
    -- ===============================
    DECLARE

      CURSOR opm_loc_cur IS
-- 2009/04/03 Ver1.2 modify start by Yutaka.Kuboshima
--                             SELECT  
--                                    'MTL_ITEM_LOCATIONS'   AS lv_ref_type 
--                                   ,inventory_location_id  AS lv_ref_code
--                                   ,description            AS lv_ref_name
--                                   ,NULL                   AS lv_pt_ref_type
--                                   ,NULL                   AS lv_pt_ref_code
--                            FROM   mtl_item_locations
--                            ORDER BY inventory_location_id;
                             SELECT  
                                    'IC_WHSE_MST'          AS lv_ref_type 
                                   ,whse_code              AS lv_ref_code
                                   ,whse_name              AS lv_ref_name
                                   ,NULL                   AS lv_pt_ref_type
                                   ,NULL                   AS lv_pt_ref_code
                            FROM   ic_whse_mst
                            ORDER BY whse_code;
-- 2009/04/03 Ver1.2 modify end by Yutaka.Kuboshima

      opm_loc_rec opm_loc_cur%ROWTYPE;

    BEGIN

      OPEN opm_loc_cur;

        << opm_loc_loop >>
        LOOP

          FETCH opm_loc_cur INTO opm_loc_rec;
          EXIT WHEN opm_loc_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               opm_loc_rec.lv_ref_type     -- 参照タイプ
              ,opm_loc_rec.lv_ref_code     -- 参照コード
              ,opm_loc_rec.lv_ref_name     -- 名称
              ,opm_loc_rec.lv_pt_ref_type  -- 親参照タイプ
              ,opm_loc_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE opm_loc_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'MTL_ITEM_LOCATIONS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 7.仕入先マスタ取得
    -- ===============================
    DECLARE

      CURSOR vendor_cur IS
                            SELECT  
                                    'PO_VENDORS'  AS lv_ref_type 
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                                   ,vendor_id     AS lv_ref_code
                                   ,segment1      AS lv_ref_code  
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima
                                   ,vendor_name   AS lv_ref_name
                                   ,NULL          AS lv_pt_ref_type  
                                   ,NULL          AS lv_pt_ref_code
                            FROM   po_vendors
-- 2009/04/02 Ver1.2 modify start by Yutaka.Kuboshima
--                            ORDER BY vendor_id;
                            ORDER BY segment1;
-- 2009/04/02 Ver1.2 modify end by Yutaka.Kuboshima

      vendor_rec vendor_cur%ROWTYPE;

    BEGIN

      OPEN vendor_cur;

        << vendor_loop >>
        LOOP

          FETCH vendor_cur INTO vendor_rec;
          EXIT WHEN vendor_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               vendor_rec.lv_ref_type     -- 参照タイプ
              ,vendor_rec.lv_ref_code     -- 参照コード
              ,vendor_rec.lv_ref_name     -- 名称
              ,vendor_rec.lv_pt_ref_type  -- 親参照タイプ
              ,vendor_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE vendor_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'PO_VEDORS');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 8.税金マスタ取得
    -- ===============================
    DECLARE

      CURSOR tax_cur IS
                         SELECT
                                'AR_VAT_TAX_ALL_B'  AS lv_ref_type 
                               ,tax_code            AS lv_ref_code
                               ,description         AS lv_ref_name
                               ,NULL                AS lv_pt_ref_type
                               ,NULL  AS lv_pt_ref_code
                        FROM   ar_vat_tax_all_b
                        WHERE  enabled_flag = cv_y_flag
-- 2009/04/02 Ver1.2 add start by Yutaka.Kuboshima
                        AND    gd_process_date BETWEEN start_date AND NVL(end_date, TO_DATE(cv_max_date, cv_date_format))
-- 2009/04/02 Ver1.2 add end by Yutaka.Kuboshima
-- 2018/04/27 Ver1.9 add start by Haruka.Mori
                        AND    set_of_books_id = gn_bks_id   --帳簿ID
-- 2018/04/27 Ver1.9 add end by Haruka.Mori
                        ORDER BY tax_code;

      tax_rec tax_cur%ROWTYPE;

    BEGIN

      OPEN tax_cur;

        << tax_loop >>
        LOOP

          FETCH tax_cur INTO tax_rec;
          EXIT WHEN tax_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               tax_rec.lv_ref_type     -- 参照タイプ
              ,tax_rec.lv_ref_code     -- 参照コード
              ,tax_rec.lv_ref_name     -- 名称
              ,tax_rec.lv_pt_ref_type  -- 親参照タイプ
              ,tax_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE tax_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'AR_VAT_TAX_ALL_B');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 9.AFF勘定科目取得
    -- ===============================
    DECLARE

      CURSOR aff_kamoku_cur IS
                                SELECT 
                                       fndsets.flex_value_set_name  AS lv_ref_type 
                                      ,fnd.flex_value               AS lv_ref_code
                                      ,fndtl.description            AS lv_ref_name
                                      ,NULL                         AS lv_pt_ref_type  
                                      ,NULL                         AS lv_pt_ref_code
                                FROM   fnd_flex_value_sets fndsets
                                      ,fnd_flex_values fnd 
                                      ,fnd_flex_values_tl fndtl
                                WHERE fnd.flex_value_set_id = fndsets.flex_value_set_id
                                AND   fndtl.flex_value_id = fnd.flex_value_id
                                AND   fndtl.language = cv_language_ja
                                AND   fnd.enabled_flag = cv_y_flag
                                AND   fndsets.flex_value_set_name = 'XX03_ACCOUNT'
                                ORDER BY fnd.flex_value;
                        
      aff_kamoku_rec aff_kamoku_cur%ROWTYPE;

    BEGIN

      OPEN aff_kamoku_cur;

        << aff_kamoku_loop >>
        LOOP

          FETCH aff_kamoku_cur INTO aff_kamoku_rec;
          EXIT WHEN aff_kamoku_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               aff_kamoku_rec.lv_ref_type     -- 参照タイプ
              ,aff_kamoku_rec.lv_ref_code     -- 参照コード
              ,aff_kamoku_rec.lv_ref_name     -- 名称
              ,aff_kamoku_rec.lv_pt_ref_type  -- 親参照タイプ
              ,aff_kamoku_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE aff_kamoku_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'AFF勘定科目');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 10.AFF明細/分類取得
    -- ===============================
    DECLARE

      CURSOR aff_meisai_cur IS
                                SELECT
                                       DISTINCT fndsets.flex_value_set_name  AS lv_ref_type 
                                      ,fnd.flex_value     AS lv_ref_code
                                      ,fndtl.description  AS lv_ref_name
                                      ,'XX03_ACCOUNT'     AS lv_pt_ref_type  
                                      ,fnd.parent_flex_value_low  AS lv_pt_ref_code
                                FROM    fnd_flex_value_sets fndsets
                                      ,fnd_flex_values fnd
                                      ,fnd_flex_values_tl fndtl
                                WHERE fnd.flex_value_set_id = fndsets.flex_value_set_id
                                AND   fndtl.flex_value_id = fnd.flex_value_id
                                AND   fndtl.language = cv_language_ja  
                                AND   fnd.enabled_flag = cv_y_flag
                                AND   fndsets.flex_value_set_name = 'XX03_SUB_ACCOUNT'
                                ORDER BY fnd.flex_value;
                        
      aff_meisai_rec aff_meisai_cur%ROWTYPE;

    BEGIN

      OPEN aff_meisai_cur;

        << aff_meisai_loop >>
        LOOP

          FETCH aff_meisai_cur INTO aff_meisai_rec;
          EXIT WHEN aff_meisai_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               aff_meisai_rec.lv_ref_type     -- 参照タイプ
              ,aff_meisai_rec.lv_ref_code     -- 参照コード
              ,aff_meisai_rec.lv_ref_name     -- 名称
              ,aff_meisai_rec.lv_pt_ref_type  -- 親参照タイプ
              ,aff_meisai_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE aff_meisai_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              'AFF明細/分類');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    -- ===============================
    -- 11.通常・実績振替区分の取得
    -- ===============================
    DECLARE

      CURSOR furikae_kbn_cur IS
                                 SELECT 
                                        fndsets.flex_value_set_name  AS lv_ref_type 
                                       ,fnd.flex_value               AS lv_ref_code
                                       ,fndtl.description            AS lv_ref_name
                                       ,NULL                         AS lv_pt_ref_type  
                                       ,NULL                         AS lv_pt_ref_code
                                 FROM   fnd_flex_value_sets fndsets
                                       ,fnd_flex_values fnd
                                       ,fnd_flex_values_tl fndtl
                                 WHERE fnd.flex_value_set_id = fndsets.flex_value_set_id
                                 AND   fndtl.flex_value_id = fnd.flex_value_id
                                 AND   fndtl.language = cv_language_ja  
                                 AND   fnd.enabled_flag = cv_y_flag
                                 AND   fndsets.flex_value_set_name = 'XXCFO1_NORM_TRNSFER_TYPE'
                                 ORDER BY fnd.flex_value;
                        
      furikae_kbn_rec furikae_kbn_cur%ROWTYPE;

    BEGIN

      OPEN furikae_kbn_cur;

        << furikae_kbn_loop >>
        LOOP

          FETCH furikae_kbn_cur INTO furikae_kbn_rec;
          EXIT WHEN furikae_kbn_cur%NOTFOUND;

            -- ファイル出力
            write_csv(
               furikae_kbn_rec.lv_ref_type     -- 参照タイプ
              ,furikae_kbn_rec.lv_ref_code     -- 参照コード
              ,furikae_kbn_rec.lv_ref_name     -- 名称
              ,furikae_kbn_rec.lv_pt_ref_type  -- 親参照タイプ
              ,furikae_kbn_rec.lv_pt_ref_code  -- 親参照コード
              ,if_file_handler
              ,lv_errbuf
              ,lv_retcode
              ,lv_errmsg
            );

            --カーソルカウント
            ln_data_cnt := ln_data_cnt + 1;  

        END LOOP;

      CLOSE furikae_kbn_cur;

      --参照コード取得エラー
      IF (ln_data_cnt = 0) THEN

        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_no_mst_data_err_msg,
                                              cv_ng_table,
                                              '通常実績・振替区分');
        ov_retcode := cv_status_warn;

        --警告メッセージ出力
        FND_FILE.PUT_LINE(which  => FND_FILE.LOG  ,buff   => lv_errmsg);
        --警告カウントアップ
        ln_warn_cnt := ln_warn_cnt + 1;

      END IF;

      --出力件数カウント
      ln_output_cnt := ln_output_cnt + ln_data_cnt;
      
      ln_data_cnt := 0;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;

    --出力件数カウントをグローバル変数へ
    gn_target_cnt := ln_output_cnt;
    gn_warn_cnt := ln_warn_cnt;
    gn_normal_cnt := ln_output_cnt;

--
  EXCEPTION
    WHEN write_failure_expt THEN                       --*** CSVデータ出力エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --CSVデータ出力エラー時、対象件数、警告件数と、エラー件数は1件固定とする
      gn_target_cnt := 1;
      gn_warn_cnt := 1;
      gn_error_cnt  := 1;
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
  END output_mst_data;
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
    gn_warn_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
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
    -- ===============================
    -- コンカレントメッセージ出力
    -- ===============================
    --IFファイル名出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => gv_xxccp_msg_kbn
                 ,iv_name         => cv_file_name_msg
                 ,iv_token_name1  => cv_tkn_filename
                 ,iv_token_value1 => gv_out_file_file
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
    output_mst_data(
       lf_file_handler         -- ファイルハンドラ
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    BEGIN

      --ファイルクローズ処理
      IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
        --ファイルクローズ
        UTL_FILE.FCLOSE(lf_file_handler);
      END IF;

    EXCEPTION

     WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_file_close_err_msg,
                                              cv_sqlerrm,
                                              SQLERRM);
        lv_errbuf := lv_errmsg;
        --ファイルクローズエラー発生
        RAISE fclose_err_expt;

    END;
    
    IF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    ELSIF (lv_retcode = cv_status_error) THEN
      --エラー処理
      RAISE global_process_expt;
    END IF;

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
    --警告件数出力
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
END xxcmm003a36c;
/
