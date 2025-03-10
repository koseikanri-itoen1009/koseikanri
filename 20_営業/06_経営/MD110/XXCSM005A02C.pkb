create or replace PACKAGE BODY XXCSM005A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM005A02C(body)
 * Description      : 速報出力商品ヘッダテーブル、及び速報出力商品明細テーブルのデータを基に、
 *                  : 日次速報帳票(群別販売速報／商品導入速報)に出力する商品情報を
 *                  : 情報系システムに連携するためのI/Fファイルを作成します。
 * MD.050           : MD050_CSM_005_A02_速報出力対象商品データIF
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  open_csv_file          ファイルオープン処理 (A-2)
 *  create_csv_rec         速報出力対象商品データ作成処理 (A-4)
 *  close_csv_file         ファイルクローズ処理処理 (A-5)
 *  submain                メイン処理プロシージャ
 *                           速報出力対象商品データ抽出処理 (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-07    1.0   M.Ohtsuki       新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;             -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;               -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;              -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                             -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                                        -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                             -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                                        -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                            -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;                     -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;                        -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;                     -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                                        -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- 想定外エラーメッセージ
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- 対象件数
  gn_normal_cnt             NUMBER;                                                                 -- 正常件数
  gn_error_cnt              NUMBER;                                                                 -- エラー件数
  gn_warn_cnt               NUMBER;                                                                 -- スキップ件数
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSM005A02C';                                 -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSM';                                        -- アプリケーション短縮名
  -- メッセージコード
  cv_xxccp_msg_008        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';                             -- コンカレント入力パラメータなし
  cv_xxcsm_msg_001        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00001';                             -- ファイル存在チェックエラーメッセージ
  cv_xxcsm_msg_002        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00002';                             -- ファイルオープンエラーメッセージ
  cv_xxcsm_msg_003        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00003';                             -- ファイルクローズエラーメッセージ
  cv_xxcsm_msg_019        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00019';                             -- 情報系システム連携対象無しエラーメッセージ
  cv_xxcsm_msg_020        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00020';                             -- 営業日取得エラーメッセージ
  cv_xxcsm_msg_031        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00031';                             -- 定期実行用プロファイル取得エラーメッセージ
  cv_xxcsm_msg_084        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00084';                             -- インターフェースファイル名
  --プロファイル名
  cv_file_dir             CONSTANT VARCHAR2(100) := 'XXCSM1_INFOSYS_FILE_DIR';                      -- 情報系データファイル作成ディレクトリ
  cv_file_name            CONSTANT VARCHAR2(100) := 'XXCSM1_NEWS_FLASH_FILE_NAME';                  -- 速報出力対象商品データファイル名
  -- トークンコード
  cv_tkn_directory        CONSTANT VARCHAR2(20) := 'DIRECTORY';
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cv_tkn_prf_name         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_sql_code         CONSTANT VARCHAR2(20) := 'SQL_CODE';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
  cv_operative_day        CONSTANT VARCHAR2(20) := 'OPERATIVE_DAY';
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand            UTL_FILE.FILE_TYPE;
  gv_file_dir             VARCHAR2(100);
  gv_file_name            VARCHAR2(100);
  gd_sysdate              DATE;
  gn_working_ym           NUMBER;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSV出力データ格納用レコード型定義
  TYPE g_get_data_rtype IS RECORD(
    company_cd             VARCHAR2(3)                                                              -- 会社コード
   ,subject_year           xxcsm_news_item_headers_all.subject_year%TYPE                            -- 年度
   ,year_month             xxcsm_news_item_headers_all.year_month%TYPE                              -- 年月
   ,news_division_code     xxcsm_news_item_headers_all.news_division_code%TYPE                      -- 速報区分
   ,item_group_kbn         xxcsm_news_item_lines_all.item_group_kbn%TYPE                            -- 商品(群)区分
   ,item_group_cd          xxcsm_news_item_lines_all.item_group_cd%TYPE                             -- 商品(群)
   ,indication_name        xxcsm_news_item_headers_all.indication_name%TYPE                         -- 表示名称
   ,indication_order       xxcsm_news_item_headers_all.indication_order%TYPE                        -- 表示順
   ,cprtn_date             DATE                                                                     -- 連携日時
   );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'init';                                         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf           VARCHAR2(4000);                                                             -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);                                                                -- リターン・コード
    lv_errmsg           VARCHAR2(4000);                                                             -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';                                         -- アプリケーション短縮名
    cn_next_day          CONSTANT NUMBER := 1;                                                      -- 翌営業日
    -- *** ローカル変数 ***
    lv_noprm_msg         VARCHAR2(4000);                                                            -- コンカレント入力パラメータなしメッセージ格納用
    lv_month             VARCHAR2(100);
    lv_msg               VARCHAR2(100);
    lv_tkn_value         VARCHAR2(100);
    -- ファイル存在チェック戻り値用
    lb_retcd             BOOLEAN;
    ln_file_size         NUMBER;
    ln_block_size        NUMBER;
    ld_process_date      DATE;
    ld_next_business_day DATE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =================================
    -- 入力パラメータなしメッセージ出力 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name                                       --アプリケーション短縮名
                       ,iv_name         => cv_xxccp_msg_008                                         --メッセージコード
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''                                                                                 -- 空行の挿入
    );
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    gv_file_dir   := FND_PROFILE.VALUE(cv_file_dir);
    gv_file_name  := FND_PROFILE.VALUE(cv_file_name);
    -- 速報出力対象商品データファイル名をメッセージ出力する
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                                                     --アプリケーション短縮名
                ,iv_name         => cv_xxcsm_msg_084                                                --メッセージコード
                ,iv_token_name1  => cv_tkn_file_name                                                --トークンコード1
                ,iv_token_value1 => gv_file_name                                                    --トークン値1
              );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                                                                                 -- 空行の挿入
    );
--
    -- プロファイル値取得に失敗した場合
    IF (gv_file_dir IS NULL) THEN                                                                   -- CSVファイル出力先取得失敗時
      lv_tkn_value := cv_file_dir;
    ELSIF (gv_file_name IS NULL) THEN                                                               -- CSVファイル名取得失敗時
      lv_tkn_value := cv_file_name;
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg_031                                            --メッセージコード
                    ,iv_token_name1  => cv_tkn_prf_name                                             --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                                                --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ========================
    -- CSVファイル存在チェック 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => gv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- すでにファイルが存在した場合
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg_001                                            --メッセージコード
                    ,iv_token_name1  => cv_tkn_directory                                            --トークンコード1
                    ,iv_token_value1 => gv_file_dir                                                 --トークン値1
                    ,iv_token_name2  => cv_tkn_file_name                                            --トークンコード2
                    ,iv_token_value2 => gv_file_name                                                --トークン値2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    gd_sysdate := SYSDATE;
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- =====================
    -- 営業日日付取得 
    -- =====================
    ld_next_business_day := xxccp_common_pkg2.get_working_day(
                                       id_date        => ld_process_date                            -- 業務処理日付
                                      ,in_working_day => cn_next_day                                -- ('1’= 翌日)
                                       );
    IF (ld_next_business_day IS NULL) THEN                                                          -- 業務処理日付に失敗した場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 -- アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg_020                                            -- メッセージコード
                    ,iv_token_name1  => cv_operative_day                                            -- トークンコード1
                    ,iv_token_value1 => ld_process_date                                             -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gn_working_ym := TO_CHAR(ld_next_business_day,'YYYYMM');                                        -- 翌営業日の属する年月を格納
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : ファイルオープン処理 (A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2                                                          -- エラー・メッセージ
    ,ov_retcode        OUT NOCOPY VARCHAR2                                                          -- リターン・コード
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                                          -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'open_csv_file';                                        -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf         VARCHAR2(4000);                                                               -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);                                                                  -- リターン・コード
    lv_errmsg         VARCHAR2(4000);                                                               -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_w              CONSTANT VARCHAR2(1) := 'w';                                                  -- 書込 = w
    cn_max_size       CONSTANT NUMBER := 2047;                                                      -- 2047バイト
--
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd     BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt     EXCEPTION;                                                                    -- ファイル処理例外
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
    -- ========================
    -- CSVファイルオープン 
    -- ========================
    BEGIN
      -- ファイルオープン
      gf_file_hand := UTL_FILE.FOPEN(
                         location     => gv_file_dir                                                -- 情報系データファイルディレクトリ
                        ,filename     => gv_file_name                                               -- 速報出力対象商品ファイル名
                        ,open_mode    => cv_w                                                       -- 書込
                        ,max_linesize => cn_max_size                                                -- 2047バイト
                      );
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                               --アプリケーション短縮名
                      ,iv_name         => cv_xxcsm_msg_002                                          --メッセージコード
                      ,iv_token_name1  => cv_tkn_directory                                          --トークンコード1
                      ,iv_token_value1 => gv_file_dir                                               --トークン値1
                      ,iv_token_name2  => cv_tkn_file_name                                          --トークンコード2
                      ,iv_token_value2 => gv_file_name                                              --トークン値2
                      ,iv_token_name3  => cv_tkn_sql_code                                           --トークンコード3
                      ,iv_token_value3 => SQLERRM                                                   --トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : 速報出力対象商品データ作成処理 (A-4)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_news_item        IN  g_get_data_rtype                                                       -- 速報出力対象商品データ
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'create_csv_rec';                              -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                                               -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                                            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_sep_com           CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot         CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    lv_data              VARCHAR2(4000);                                                            -- 編集データ格納
--
    -- *** ローカル・レコード ***
    l_news_item_rec     g_get_data_rtype;                                                           -- INパラメータ.速報出力対象商品データ格納
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをレコード変数に格納
    l_news_item_rec := ir_news_item; -- 速報出力対象商品データ
--
    -- ======================
    -- CSV出力処理 
    -- ======================
      -- データ作成
    lv_data := 
      cv_sep_wquot  || l_news_item_rec.company_cd         || cv_sep_wquot                           -- 会社コード
      || cv_sep_com || TO_CHAR(l_news_item_rec.subject_year)                                        -- 対象年度
      || cv_sep_com || TO_CHAR(l_news_item_rec.year_month)                                          -- 年月
      || cv_sep_com ||
      cv_sep_wquot  || l_news_item_rec.news_division_code || cv_sep_wquot                           -- 速報区分
      || cv_sep_com ||
      cv_sep_wquot  || l_news_item_rec.item_group_kbn     || cv_sep_wquot                           -- 商品(群)区分
      || cv_sep_com ||
      cv_sep_wquot  || l_news_item_rec.item_group_cd      || cv_sep_wquot                           -- 商品(群)
      || cv_sep_com ||
      cv_sep_wquot  || l_news_item_rec.indication_name    || cv_sep_wquot                           -- 表示名称
      || cv_sep_com || TO_CHAR(l_news_item_rec.indication_order)                                    -- 表示順
      || cv_sep_com || TO_CHAR(l_news_item_rec.cprtn_date, 'yyyymmddhh24miss');                     -- 連携日時                                                                                            -- 連携日時
    -- データ出力
    UTL_FILE.PUT_LINE(
      file   => gf_file_hand
     ,buffer => lv_data
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : ファイルクローズ処理処理 (A-5)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2                                                          -- エラー・メッセージ
    ,ov_retcode        OUT NOCOPY VARCHAR2                                                          -- リターン・コード
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                                          -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'close_csv_file';                                  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf          VARCHAR2(4000);                                                              -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);                                                                 -- リターン・コード
    lv_errmsg          VARCHAR2(4000);                                                              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd     BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt     EXCEPTION;                                                                    -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================
    -- CSVファイルクローズ 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                               -- アプリケーション短縮名
                      ,iv_name         => cv_xxcsm_msg_003                                          -- メッセージコード
                      ,iv_token_name1  => cv_file_dir                                               -- トークンコード1
                      ,iv_token_value1 => gv_file_dir                                               -- トークン値1
                      ,iv_token_name2  => cv_file_name                                              -- トークンコード1
                      ,iv_token_value2 => gv_file_name                                              -- トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'submain';                                     -- プログラム名
    cv_company_cd        CONSTANT VARCHAR2(3)     := '001';                                         -- 会社コード
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                                               -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                                            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd        BOOLEAN;
    -- メッセージ出力用
    lv_msg               VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
    CURSOR get_news_item_cur                                                                        -- 速報出力対象商品データ取得
    IS
      SELECT    nih.subject_year             subject_year                                           -- 対象年度
               ,nih.year_month               year_month                                             -- 年月
               ,nih.indication_order         indication_order                                       -- 表示順
               ,nih.indication_name          indication_name                                        -- 表示名称
               ,nih.news_division_code       news_division_code                                     -- 速報区分コード
               ,nil.item_group_kbn           item_group_kbn                                         -- 商品(群)区分
               ,nil.item_group_cd            item_group_cd                                          -- 商品(群)コード
      FROM      xxcsm_news_item_headers_all  nih                                                    -- 速報出力商品ヘッダテーブル
               ,xxcsm_news_item_lines_all    nil                                                    -- 速報出力商品明細テーブル
      WHERE     nih.news_item_header_id = nil.news_item_header_id                                   -- ヘッダID
        AND     nih.year_month          = gn_working_ym                                             -- 年月 = 翌営業日の属する年月
      ORDER BY  nih.news_division_code                                                              -- 速報区分コード
               ,nih.indication_order                                                                -- 表示順
               ,nil.item_group_kbn                                                                  -- 商品(群)区分
               ,nil.item_group_cd;                                                                  -- 商品(群)コード
--
    -- *** ローカル・レコード ***
    get_news_item_rec   get_news_item_cur%ROWTYPE;
    l_get_data_rec       g_get_data_rtype;
    -- *** ローカル例外 ***
    no_data_expt         EXCEPTION;
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
--
    -- ========================================
    -- A-1.初期処理 
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf                                                                      -- エラー・メッセージ
      ,ov_retcode => lv_retcode                                                                     -- リターン・コード
      ,ov_errmsg  => lv_errmsg                                                                      -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- A-2.ファイルオープン処理 
    -- =========================================
    open_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- エラー・メッセージ
      ,ov_retcode   => lv_retcode                                                                   -- リターン・コード
      ,ov_errmsg    => lv_errmsg                                                                    -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.速報出力対象商品データ抽出処理
    -- ========================================
    -- カーソルオープン
    OPEN get_news_item_cur;
--
    <<get_data_loop>>                                                                               -- 速報出力対象商品データ取得LOOP
    LOOP
      FETCH get_news_item_cur INTO get_news_item_rec;
      -- 処理対象件数格納
      gn_target_cnt := get_news_item_cur%ROWCOUNT;
--
      EXIT WHEN get_news_item_cur%NOTFOUND
             OR get_news_item_cur%ROWCOUNT = 0;
      -- レコード変数初期化
      l_get_data_rec := NULL;
      -- 取得データを格納
      l_get_data_rec.company_cd                := cv_company_cd;                                    -- 会社コード
      l_get_data_rec.subject_year              := get_news_item_rec.subject_year;                   -- 対象年度
      l_get_data_rec.year_month                := get_news_item_rec.year_month;                     -- 年月
      l_get_data_rec.news_division_code        := get_news_item_rec.news_division_code;             -- 速報区分コード
      l_get_data_rec.item_group_kbn            := get_news_item_rec.item_group_kbn;                 -- 商品(群)区分
      l_get_data_rec.item_group_cd             := get_news_item_rec.item_group_cd;                  -- 商品(群)コード
      l_get_data_rec.indication_name           := get_news_item_rec.indication_name;                -- 表示名称
      l_get_data_rec.indication_order          := get_news_item_rec.indication_order;               -- 表示順
      l_get_data_rec.cprtn_date                := gd_sysdate;                                       -- 連携日時
--
      -- ========================================
      -- A-4.速報出力対象商品データ書込処理
      -- ========================================
      create_csv_rec(
        ir_news_item   =>  l_get_data_rec                                                           -- 速報出力対象商品データ
       ,ov_errbuf      =>  lv_errbuf                                                                -- エラー・メッセージ
       ,ov_retcode     =>  lv_retcode                                                               -- リターン・コード
       ,ov_errmsg      =>  lv_errmsg                                                                -- ユーザー・エラー・メッセージ
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- 正常件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP get_data_loop;
--
    -- カーソルクローズ
    CLOSE get_news_item_cur;
--
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg_019                                            --メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    -- ========================================
    -- A-5.ファイルクローズ処理
    -- ========================================
    close_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- エラー・メッセージ
      ,ov_retcode   => lv_retcode                                                                   -- リターン・コード
      ,ov_errmsg    => lv_errmsg                                                                    -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理対象データ0件例外ハンドラ ***
    WHEN no_data_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      -- カーソルがクローズされていない場合
      IF (get_news_item_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_news_item_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_news_item_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_news_item_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_news_item_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_news_item_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_process_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_news_item_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_news_item_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_news_item_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_news_item_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2                                                              -- エラー・メッセージ
    ,retcode       OUT NOCOPY VARCHAR2 )                                                            -- リターン・コード
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- プログラム名
    cv_xxcsm           CONSTANT VARCHAR2(100) := 'XXCSM';                                           -- アプリケーション短縮名 
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- 件数メッセージ用トークン名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(4000);                                                              -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);                                                                 -- リターン・コード
    lv_errmsg          VARCHAR2(4000);                                                              -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);                                                               -- 終了メッセージコード
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
    --空行の出力
    fnd_file.put_line(
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
       ov_errbuf   => lv_errbuf                                                                     -- エラー・メッセージ
      ,ov_retcode  => lv_retcode                                                                    -- リターン・コード
      ,ov_errmsg   => lv_errmsg                                                                     -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                                        --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                                                                        --エラーメッセージ
      );
      --件数の振替(エラーの場合、エラー件数を1件のみ表示させる。）
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
--
    -- =======================
    -- A-6.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSM005A02C;
/
