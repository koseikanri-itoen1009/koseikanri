CREATE OR REPLACE PACKAGE BODY xxcmm003a37c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A37C(body)
 * Description      : チェーンマスタ連携IFデータ作成
 * MD.050           : MD050_CMM_003_A37_チェーンマスタ連携IFデータ作成
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  file_open              ファイルオープン処理(A-2)
 *  output_chain_data      処理対象データ抽出処理(A-3)・CSVファイル出力処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-5 終了処理)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/18    1.0   Yutaka.Kuboshima 新規作成
 *  2009-03-09    1.1   Yutaka.Kuboshima ファイル出力先のプロファイルの変更
 *  2011/10/31    1.2   Yasuhiro.Horikawa E_本稼動_08649 チェーン店名の最大長を文字数カウントに変更
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
  gv_out_file_name VARCHAR2(100);
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
  no_data_err_expt               EXCEPTION; --対象データ0件
  write_failure_expt             EXCEPTION; --CSVデータ出力エラー
  fclose_err_expt                EXCEPTION; --ファイルクローズエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A37C';      -- パッケージ名
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';                 -- カンマ
  cv_dqu                     CONSTANT VARCHAR2(1)   := '"';                 -- 文字列括り
--
  cv_trans_date              CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';  -- 連携日付書式
--
  --メッセージ
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';  -- ファイル名ノート
  --エラーメッセージ
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';  -- プロファイル取得エラー
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';  -- ファイルパス不正エラー
  cv_exist_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';  -- CSVファイル存在チェック
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';  -- CSVデータ出力エラー
  cv_no_data_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00001';  -- 対象データ無し
  cv_file_close_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';  -- ファイルクローズエラー
  cv_no_parameter            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  --トークン
  cv_ng_profile              CONSTANT VARCHAR2(10)  := 'NG_PROFILE';        -- プロファイル取得失敗トークン
  cv_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';           -- ファイルクローズエラートークン
  cv_ng_word                 CONSTANT VARCHAR2(10)  := 'NG_WORD';           -- CSV出力エラー項目名称トークン
  cv_ng_data                 CONSTANT VARCHAR2(10)  := 'NG_DATA';           -- CSV出力エラー項目値トークン
  cv_tkn_filename            CONSTANT VARCHAR2(10)  := 'FILE_NAME';         -- ファイル名
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
--    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_003A37_OUT_FILE_DIR';   -- チェーンマスタ連携IFデータ作成用CSVファイル出力先
    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';         --XXCMM:情報系(OUTBOUND)連携用CSVファイル出力先
-- 2009/03/09 modify end
    cv_out_file_file CONSTANT VARCHAR2(30) := 'XXCMM1_003A37_OUT_FILE_FIL';   -- チェーンマスタ連携IFデータ作成用CSVファイル名
    cv_invalid_path  CONSTANT VARCHAR2(25) := 'CSV出力ディレクトリ';          -- プロファイル取得失敗(ディレクトリ)
    cv_invalid_name  CONSTANT VARCHAR2(20) := 'CSV出力ファイル名';            -- プロファイル取得失敗(ファイル名)
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
    -- CSV出力ディレクトリをプロファイルより取得。失敗時はエラー
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
    -- CSV出力ファイル名をプロファイルより取得。失敗時はエラー
    gv_out_file_name := FND_PROFILE.VALUE(cv_out_file_file);
    IF (gv_out_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_name);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    -- ファイル存在チェック
    UTL_FILE.FGETATTR(gv_out_file_dir, gv_out_file_name, lv_file_chk, ln_file_size, ln_block_size);
    IF (lv_file_chk) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_exist_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
  EXCEPTION
    WHEN init_err_expt THEN                           --*** 初期処理例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
                                        gv_out_file_name,
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
  PROCEDURE output_chain_data(
    if_file_handler         IN  UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    ov_errbuf               OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode              OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg               OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_chain_data'; -- プログラム名
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
    cv_y_flag             CONSTANT VARCHAR2(1)     := 'Y';                      -- 有効フラグY
    cv_n_flag             CONSTANT VARCHAR2(1)     := 'N';                      -- 無効フラグN
    cv_language_ja        CONSTANT VARCHAR2(2)     := 'JA';                     -- 言語(日本語)
    cv_chain_code         CONSTANT VARCHAR2(30)    := 'XXCMM_CHAIN_CODE';       -- チェーン店コード
    cv_kigyo_gcode        CONSTANT VARCHAR2(30)    := 'XXCMM_KIGYO_GROUP_CODE'; -- 企業Gコード
    cv_kigyo_code         CONSTANT VARCHAR2(30)    := 'XX03_BUSINESS_TYPE';     -- 企業コード
--
    cv_comp_code          CONSTANT VARCHAR2(3)     := '001';                    -- 会社コード
    cv_tkn_chain_code     CONSTANT VARCHAR2(20)    := 'チェーンコード';         -- CSV出力エラー文字列
--
    -- *** ローカル変数 ***
    lv_collaboration_date VARCHAR2(14);     -- 連携日時(YYYYMMDDHH24MISS)
    lv_output_str         VARCHAR2(4095);   -- CSV出力文字列格納変数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- チェーンマスタ連携IFデータ作成カーソル
    CURSOR chain_data_cur
    IS
      SELECT flvc.chain_code      chain_code,
             flvc.chain_name      chain_name,
             flvc.chain_kana      chain_kana,
             flvc.kigyo_code      kigyo_code,
             ffvk.kigyo_name      kigyo_name,
             ffvk.kigyo_base_code kigyo_base_code,
             ffvk.kigyo_gcode     kigyo_gcode,
             flvk.kigyo_gname     kigyo_gname,
             flvc.base_code       base_code
      FROM (SELECT flv.lookup_code  chain_code,
                   flv.description  chain_name,
                   flv.attribute1   kigyo_code,
                   flv.attribute2   chain_kana,
                   flv.attribute3   base_code
            FROM fnd_lookup_values flv
            WHERE flv.language     = cv_language_ja
              AND flv.lookup_type  = cv_chain_code
              AND flv.enabled_flag = cv_y_flag) flvc,
           (SELECT ffv.flex_value   kigyo_code,
                   ffvt.description kigyo_name,
                   ffv.attribute1   kigyo_gcode,
                   ffv.attribute2   kigyo_base_code
            FROM fnd_flex_value_sets ffvs,
                 fnd_flex_values     ffv,
                 fnd_flex_values_tl  ffvt
            WHERE ffv.flex_value_set_id    = ffvs.flex_value_set_id
              AND ffv.flex_value_id        = ffvt.flex_value_id
              AND ffv.enabled_flag         = cv_y_flag
              AND ffvs.flex_value_set_name = cv_kigyo_code
              AND ffvt.language            = cv_language_ja
              AND ffv.summary_flag         = cv_n_flag) ffvk,
           (SELECT flv.lookup_code  kigyo_gcode,
                   flv.description  kigyo_gname
            FROM fnd_lookup_values flv
            WHERE flv.language     = cv_language_ja
              AND flv.lookup_type  = cv_kigyo_gcode
              AND flv.enabled_flag = cv_y_flag) flvk
      WHERE flvc.kigyo_code   = ffvk.kigyo_code(+)
        AND ffvk.kigyo_gcode  = flvk.kigyo_gcode(+)
      ORDER BY ffvk.kigyo_gcode, flvc.kigyo_code, flvc.chain_code;
--
    -- チェーンマスタ連携IFデータ作成カーソルレコード型
    chain_data_rec chain_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 連携日時取得
    lv_collaboration_date := TO_CHAR(SYSDATE, cv_trans_date);
    -- CSVファイル出力処理
    << out_loop >>
    FOR chain_data_rec IN chain_data_cur
    LOOP
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
      -- 出力文字列作成
      -- 会社コード
      lv_output_str := cv_dqu        || cv_comp_code || cv_dqu;
      -- チェーンコード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.chain_code, 1, 9)      || cv_dqu;
      -- チェーン店名(漢字)
-- 2011/10/31 Ver.1.2 Mod Start
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.chain_name, 1, 50)     || cv_dqu;
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTR(chain_data_rec.chain_name, 1, 25)      || cv_dqu;
-- 2011/10/31 Ver.1.2 Mod End
      -- チェーン店名(カナ)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.chain_kana, 1, 25)     || cv_dqu;
      -- 企業コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_code, 1, 6)      || cv_dqu;
      -- 企業名
-- 2011/10/31 Ver.1.2 Mod Start
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_name, 1, 50)     || cv_dqu;
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTR(chain_data_rec.kigyo_name, 1, 25)      || cv_dqu;
-- 2011/10/31 Ver.1.2 Mod End
      -- 本部担当拠点コード(企業)
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_base_code, 1, 4) || cv_dqu;
      -- 企業Gコード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_gcode, 1, 6)     || cv_dqu;
      -- 企業G名
-- 2011/10/31 Ver.1.2 Mod Start
--      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.kigyo_gname, 1, 50)    || cv_dqu;
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTR(chain_data_rec.kigyo_gname, 1, 25)     || cv_dqu;
-- 2011/10/31 Ver.1.2 Mod End
      -- 本部担当拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || SUBSTRB(chain_data_rec.base_code, 1, 4)       || cv_dqu;
      -- 連携日時
      lv_output_str := lv_output_str || cv_comma || lv_collaboration_date;
      BEGIN
        -- CSVファイル出力
        UTL_FILE.PUT_LINE(if_file_handler,lv_output_str);
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR THEN   --*** ファイル書き込みエラー ***
          lv_errmsg     := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                                    cv_write_err_msg,
                                                    cv_ng_word,
                                                    cv_tkn_chain_code,
                                                    cv_ng_data,
                                                    chain_data_rec.chain_code);
          lv_errbuf     := lv_errmsg;
          -- エラー件数カウント
          gn_error_cnt  := gn_error_cnt + 1;
        RAISE write_failure_expt;
      END;
      -- 成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
      -- 変数初期化
      lv_output_str := NULL;
    END LOOP out_loop;
    -- 対象データなし
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_data_err_msg);
      lv_errbuf := lv_errmsg;
      RAISE no_data_err_expt;
    END IF;
--
  EXCEPTION
    WHEN no_data_err_expt THEN                         --*** 対象データなしエラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN write_failure_expt THEN                       --*** CSVデータ出力エラー ***
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
  END output_chain_data;
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
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 初期処理エラー時は処理を中断
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- コンカレントメッセージ出力
    -- ===============================
    --IFファイル名出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => gv_xxccp_msg_kbn
                 ,iv_name         => cv_file_name_msg
                 ,iv_token_name1  => cv_tkn_filename
                 ,iv_token_value1 => gv_out_file_name
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
    output_chain_data(
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
      IF (gn_target_cnt = 0) THEN
        -- ファイル削除
        UTL_FILE.FREMOVE(gv_out_file_dir, gv_out_file_name);
      END IF;
      -- エラー処理
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
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
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
END xxcmm003a37c;
/
