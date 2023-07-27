CREATE OR REPLACE PACKAGE BODY APPS.XXCFO010A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO010A06C (body)
 * Description      : GLOIF仕訳の転送抽出
 * MD.050           : T_MD050_CFO_010_A06_GLOIF仕訳の転送抽出_EBSコンカレント
 * Version          : 1.4
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  to_csv_string          CSVファイル用文字列変換
 *  init                   初期処理(A-1)
 *  output_gloif           連携データ抽出処理(A-2)
 *                         I/Fファイル出力処理(A-3)
 *  bkup_oic_gloif         バックアップ処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-12-28    1.0   K.Tomie          新規作成
 *  2023-01-19    1.1   T.Mizutani       ファイル分割対応
 *  2023-03-01    1.2   F.Hasebe         シナリオテスト障害No.0039対応
 *  2023-03-01    1.3   Y.Ooyama         移行障害No.44対応
 *  2023-05-10    1.4   S.Yoshioka       開発残課題07対応
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
  -- ロックエラー例外
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name              CONSTANT VARCHAR2(100)  := 'XXCFO010A06C';            -- パッケージ名
  -- アプリケーション短縮名
  cv_msg_kbn_cfo           CONSTANT VARCHAR2(5)    := 'XXCFO';                   -- アドオン：会計・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_coi           CONSTANT VARCHAR2(5)    := 'XXCOI';                   -- アドオン：販物・在庫領域のアプリケーション短縮名
  -- 
  cv_msg_slash             CONSTANT VARCHAR2(1)    := '/';                       -- スラッシュ
  cn_max_linesize          CONSTANT BINARY_INTEGER := 32767;                     -- ファイルサイズ
  cv_open_mode_w           CONSTANT VARCHAR2(1)    := 'W';                       -- 読み込みモード
  cv_delim_comma           CONSTANT VARCHAR2(1)    := ',';                       -- カンマ
  cv_space                 CONSTANT VARCHAR2(1)    := ' ';                       -- LF置換単語
  -- Ver1.4 Add Start
  cv_lf_str                CONSTANT VARCHAR2(2)    := '\n';                      -- LF置換単語（FBDIファイル用改行コード置換）
  -- Ver1.4 Add End
  cv_execute_kbn_n         CONSTANT VARCHAR2(20)   := 'N';                       -- 実行区分 = 'N':夜間
  cv_execute_kbn_d         CONSTANT VARCHAR2(20)   := 'D';                       -- 実行区分 = 'D':定時
  cv_gloif_journal         CONSTANT VARCHAR2(20)   := '2';                       -- 連携パターン   = '2':GLOIF仕訳抽出
  cv_gloif_status_new      CONSTANT VARCHAR2(20)   := 'NEW';                     -- ステータス = NEW
  cv_status_code           CONSTANT VARCHAR2(20)   := 'NEW';                     -- ファイル出力固定値：Status Code
-- Ver1.1 Add Start
  cv_sales_sob             CONSTANT VARCHAR2(20)   := 'SALES-SOB';               -- SALES会計帳簿名
-- Ver1.1 Add End

  -- 書式
  cv_comma_edit            CONSTANT VARCHAR2(30)   := 'FM999,999,999';           -- 件数出力書式
  cv_date_ymd              CONSTANT VARCHAR2(30)   := 'YYYY/MM/DD';              -- 日付書式
  -- メッセージNo.
  cv_msg1                  CONSTANT VARCHAR2(2)    := '1.';                      -- 1
  cv_msg2                  CONSTANT VARCHAR2(2)    := '2.';                      -- 2
  -- プロファイル
  cv_oic_out_file_dir      CONSTANT VARCHAR2(100)  := 'XXCFO1_OIC_OUT_FILE_DIR'; -- XXCFO:OIC連携データファイル格納ディレクトリ名
-- Ver1.1 Add Start
  cv_div_cnt               CONSTANT VARCHAR2(60)   := 'XXCFO1_OIC_DIVCNT_GL_OIF'; -- XXCFO:OIC連携分割行数（EBS仕訳）
  -- グループID
  cn_init_group_id         CONSTANT NUMBER         := 1000;                       -- グループID初期値
  -- ファイル名用定数
  cv_extension             CONSTANT VARCHAR2(10)  := '.csv';                      -- ファイル分割時の拡張子
  cv_fmt_fileno            CONSTANT VARCHAR2(10)  := 'FM00';                      -- ファイル連番書式
-- Ver1.1 Add End
-- Ver1.3 Add Start
  cv_prf_max_h_cnt_per_b   CONSTANT VARCHAR2(60)   := 'XXCFO1_OIC_MAX_H_CNT_PER_BATCH'; -- XXCFO:仕訳バッチ内上限仕訳ヘッダ件数（OIC連携）
-- Ver1.3 Add End
  -- メッセージ
  cv_msg_cfo1_60001        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60001';        -- パラメータ出力メッセージ
  cv_msg_cfo1_60009        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60009';        -- パラメータ必須エラーメッセージ
  cv_msg_cfo1_60010        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60010';        -- パラメータ不正エラーメッセージ
  cv_msg_cfo1_60011        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60011';        -- OIC連携対象仕訳該当なしエラーメッセージ
  cv_msg_cfo1_00001        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00001';        -- プロファイル名取得エラーメッセージ
  cv_msg_coi1_00029        CONSTANT VARCHAR2(20)   := 'APP-XXCOI1-00029';        -- ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo1_00019        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00019';        -- ロックエラーメッセージ
  cv_msg_cfo1_60002        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60002';        -- IFファイル名出力メッセージ
  cv_msg_cfo1_00027        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00027';        -- 同一ファイル存在エラーメッセージ
  cv_msg_cfo1_00029        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00029';        -- ファイルオープンエラーメッセージ
  cv_msg_cfo1_00030        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00030';        -- ファイル書込みエラーメッセージ
  cv_msg_cfo1_00024        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00024';        -- 登録エラーメッセージ
  cv_msg_cfo1_00025        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00025';        -- 削除エラーメッセージ
  cv_msg_cfo1_60004        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60004';        -- 検索対象・件数メッセージ
  cv_msg_cfo1_60005        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60005';        -- ファイル出力対象・件数メッセージ
  -- トークンコード
  cv_tkn_param_name        CONSTANT VARCHAR2(30)   := 'PARAM_NAME';              -- トークン名(PARAM_NAME)
  cv_tkn_param_val         CONSTANT VARCHAR2(30)   := 'PARAM_VAL';               -- トークン名(PARAM_VAL)
  cv_tkn_prof_name         CONSTANT VARCHAR2(30)   := 'PROF_NAME';               -- トークン名(PROF_NAME)
  cv_tkn_dir_tok           CONSTANT VARCHAR2(30)   := 'DIR_TOK';                 -- トークン名(DIR_TOK)
  cv_tkn_table             CONSTANT VARCHAR2(30)   := 'TABLE';                   -- トークン名(TABLE)
  cv_tkn_count             CONSTANT VARCHAR2(30)   := 'COUNT';                   -- トークン名(COUNT)
  cv_tkn_file_name         CONSTANT VARCHAR2(30)   := 'FILE_NAME';               -- トークン名(FILE_NAME)
  cv_tkn_errmsg            CONSTANT VARCHAR2(30)   := 'ERRMSG';                  -- トークン名(ERRMSG)
  cv_tkn_target            CONSTANT VARCHAR2(30)   := 'TARGET';                  -- トークン名(TARGET)
-- Ver1.1 Add Start
  cv_tkn_sqlerrm           CONSTANT VARCHAR2(30)   := 'SQLERRM';                 -- SQLERRM
-- Ver1.1 Add End
  -- メッセージ出力用文字列(トークン)
  cv_msgtkn_cfo1_60013     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60013';        -- 実行区分
  cv_msgtkn_cfo1_60014     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60014';        -- 帳簿ID
  cv_msgtkn_cfo1_60015     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60015';        -- 仕訳ソース
  cv_msgtkn_cfo1_60016     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60016';        -- 仕訳カテゴリ
  cv_msgtkn_cfo1_60019     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60019';        -- OIC_GLOIFバックアップテーブル
  cv_msgtkn_cfo1_60020     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60020';        -- GLOIF
  cv_msgtkn_cfo1_60027     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60027';        -- GLOIF仕訳の転送
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 出力ファイル情報のレコード型宣言
  TYPE l_out_file_rtype IS RECORD(
      set_of_books_id     NUMBER               -- 帳簿ID
    , je_source           VARCHAR2(25)         -- 仕訳ソース
    , file_name           VARCHAR2(100)        -- ファイル名
    , file_handle         UTL_FILE.FILE_TYPE   -- ファイルハンドル
    , out_cnt             NUMBER               -- 出力件数
  );
  -- 出力ファイル情報のテーブル型宣言
  TYPE l_out_file_ttype IS TABLE OF l_out_file_rtype INDEX BY BINARY_INTEGER;
  -- GLOIFのROWIDのテーブル型宣言
  TYPE l_gi_rowid_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_oic_out_file_dir     VARCHAR2(100);                                        -- XXCFO:OIC連携データファイル格納ディレクトリ名
  gv_dir_path             ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;                  -- ディレクトリパス  
-- Ver1.1 Del Start
--  l_out_file_tab          l_out_file_ttype;                                     -- 出力ファイル情報テーブル変数
-- Ver1.1 Del End
  l_gi_rowid_tab          l_gi_rowid_ttype;                                     -- GLOIFのROWIDのテーブル変数
-- Ver1.1 Add Start
  l_out_sale_tab          l_out_file_ttype;                                     -- SALES出力ファイル情報テーブル変数
  l_out_ifrs_tab          l_out_file_ttype;                                     -- IFRS出力ファイル情報テーブル変数
  gn_divcnt               NUMBER := 0;                                          -- ファイル分割行数
  gv_fl_name_sales        XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- SALESファイル名(連番なし拡張子なし）
  gv_fl_name_ifrs         XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- IFRSファイル名(連番なし拡張子なし）
-- Ver1.3 Add Start
  gn_max_h_cnt_per_b      NUMBER := 0;                                          -- 仕訳バッチ内上限仕訳ヘッダ件数
-- Ver1.3 Add End
--
  /**********************************************************************************
   * Procedure Name   : open_output_file
   * Description      : 出力ファイルオープン処理
   ***********************************************************************************/
  PROCEDURE open_output_file(
    ov_errbuf              OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode             OUT VARCHAR2 -- リターンコード
   ,ov_errmsg              OUT VARCHAR2 -- ユーザーエラーメッセージ
   ,iv_output_file_name    IN  VARCHAR2 -- 出力ファイル名
   ,of_file_hand           OUT UTL_FILE.FILE_TYPE   -- ファイル・ハンドル
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_output_file'; -- プログラム名
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
--
    lv_msg          VARCHAR2(300)   DEFAULT NULL;   -- メッセージ出力用    
    -- ファイル出力関連
    lb_fexists      BOOLEAN;            -- ファイルが存在するかどうか
    ln_file_size    NUMBER;             -- ファイルの長さ
    ln_block_size   NUMBER;             -- ファイルシステムのブロックサイズ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- (1)ＵＴＬファイル存在チェック
    -- ====================================================
    UTL_FILE.FGETATTR(
      gv_dir_path,
      iv_output_file_name,
      lb_fexists,
      ln_file_size,
      ln_block_size
    );
--
    -- 前回ファイルが存在している
    IF ( lb_fexists ) THEN
        -- 空行挿入
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ''
        );
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     , cv_msg_cfo1_00027  -- 同一ファイル存在エラーメッセージ
                                                     )
                                                    , 1
                                                    , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
  -- ====================================================
  -- (2)ＵＴＬファイルオープン
  -- ====================================================
    BEGIN
      of_file_hand := UTL_FILE.FOPEN( gv_dir_path                -- ディレクトリパス
                                    , iv_output_file_name        -- ファイル名
                                    , cv_open_mode_w             -- オープンモード
                                    , cn_max_linesize            -- ファイル行サイズ
                                    );
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILENAME THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                     , cv_msg_cfo1_00029   -- ファイルオープンエラー
                                                     , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                     , SQLERRM             -- SQLERRM（ファイル名が無効）
                                                    )
                                                   , 1
                                                   , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.INVALID_OPERATION THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                     , cv_msg_cfo1_00029   -- ファイルオープンエラー
                                                     , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                     , SQLERRM             -- SQLERRM（ファイルをオープンできない）
                                                    )
                                                   , 1
                                                   , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                      , cv_msg_cfo1_00029   -- ファイルオープンエラー
                                                      , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                      , SQLERRM             -- SQLERRM（その他）
                                                     )
                                                    , 1
                                                    , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ファイル名をディレクトリパス付きで出力する。
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_kbn_cfo                                         -- 'XXCFO'
                  , iv_name         => cv_msg_cfo1_60002                                      -- IFファイル名出力メッセージ
                  , iv_token_name1  => cv_tkn_file_name                                       -- トークン(FILE_NAME)
                  , iv_token_value1 => gv_dir_path || cv_msg_slash ||iv_output_file_name      -- OIC連携対象のファイル名
                );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
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
  END open_output_file;
-- Ver1.1 Add End
--
-- Ver1.4 Add Start
  /**********************************************************************************
   * Function Name    : to_csv_string
   * Description      : CSVファイル用文字列変換
   ***********************************************************************************/
  FUNCTION to_csv_string(
              iv_string       IN VARCHAR2                   -- 対象文字列
             ,iv_lf_replace   IN VARCHAR2 DEFAULT NULL      -- LF置換単語
           )
    RETURN VARCHAR2
  IS
  --
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'to_csv_string';
    lv_changed_string   VARCHAR2(3000);           -- 変換後文字列(戻り値)
  --
  BEGIN
    -- 変換後文字列を初期化
    lv_changed_string := iv_string;
    -- 
    -- すべてのCR改行コード「CHAR(13)」をNULLに置換
    lv_changed_string := REPLACE( lv_changed_string , CHR(13) , NULL );
    --
    -- OIC共通関数のCSVファイル用文字列変換を実施
    RETURN xxccp_oiccommon_pkg.to_csv_string( lv_changed_string , iv_lf_replace );
    --
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END to_csv_string;
--
-- Ver1.4 Add End
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_execute_kbn      IN  VARCHAR2    -- 実行区分
    , in_set_of_books_id  IN  NUMBER      -- 帳簿ID
    , iv_je_source_name   IN  VARCHAR2    -- 仕訳ソース
    , iv_je_category_name IN  VARCHAR2    -- 仕訳カテゴリ
    , ov_errbuf           OUT VARCHAR2    -- エラー・メッセージ           # 固定 #
    , ov_retcode          OUT VARCHAR2    -- リターン・コード             # 固定 #
    , ov_errmsg           OUT VARCHAR2    -- ユーザー・エラー・メッセージ # 固定 #
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
--
    -- *** ローカル変数 ***
    lv_msg              VARCHAR2(300)   DEFAULT NULL;   -- メッセージ出力用    
    ln_exsist_cnt       NUMBER;                         -- OIC連携対象仕訳存在チェック用変数
    ln_out_file_tab_cnt NUMBER;                         -- 出力ファイル数カウント用
    -- ファイル出力関連
    lb_fexists          BOOLEAN;                        -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                         -- ファイルの長さ
    ln_block_size       NUMBER;                         -- ファイルシステムのブロックサイズ
-- Ver1.1 Add Start
    lv_fl_name          XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- ファイル名
    lv_fl_name_noext    XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- ファイル名（拡張子なし）
    lf_file_hand        UTL_FILE.FILE_TYPE;                               -- ファイル・ハンドル
-- Ver1.1 Add End
--
    -- *** ローカル・カーソル ***
    -- OIC連携対象仕訳情報取得
    CURSOR c_prog_journal_cur IS
      SELECT DISTINCT
          set_of_books_id    AS set_of_books_id   -- 帳簿ID
-- Ver1.1 Add Start
         , name              AS name              -- 会計帳簿名
-- Ver1.1 Add End
        , je_source          AS je_source         -- 仕訳ソース
        , file_name          AS file_name         -- ファイル名
      FROM
        xxcfo_oic_target_journal xotj                                            -- OIC連携対象仕訳テーブル
      WHERE
          xotj.if_pattern = cv_gloif_journal                                     -- 連携パターン（GLOIF仕訳の転送）
      AND xotj.set_of_books_id = NVL(in_set_of_books_id,  xotj.set_of_books_id)  -- 帳簿ID = 入力パラメータ「帳簿ID」
      AND xotj.je_source       = iv_je_source_name                               -- 仕訳ソース = 入力パラメータ「仕訳ソース」
      AND xotj.je_category     = NVL(iv_je_category_name, xotj.je_category)      -- 仕訳カテゴリ = 入力パラメータ「仕訳カテゴリ」
      ;
--
    -- *** ローカル・レコード ***
    c_journal_rec      c_prog_journal_cur%ROWTYPE;   -- OIC連携対象仕訳テーブル カーソルレコード型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- A-1-1.入力パラメータチェック
    -- ==============================================================
--
    -- (1)入力パラメータ出力
    -- ===================================================================
--
    -- 1.実行区分
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                 , iv_name         => cv_msg_cfo1_60001        -- パラメータ出力メッセージ
                 , iv_token_name1  => cv_tkn_param_name        -- トークン(PARAM_NAME)
                 , iv_token_value1 => cv_msgtkn_cfo1_60013     -- 実行区分
                 , iv_token_name2  => cv_tkn_param_val         -- トークン(PARAM_VAL)
                 , iv_token_value2 => iv_execute_kbn           -- パラメータ：実行区分
              );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
--
    -- 2.帳簿ID
    lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
                , iv_name         => cv_msg_cfo1_60001            -- パラメータ出力メッセージ
                , iv_token_name1  => cv_tkn_param_name            -- トークン(PARAM_NAME)
                , iv_token_value1 => cv_msgtkn_cfo1_60014         -- 帳簿ID
                , iv_token_name2  => cv_tkn_param_val             -- トークン(PARAM_VAL)
                , iv_token_value2 => TO_CHAR(in_set_of_books_id)  -- パラメータ：帳簿ID
              );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
--
    -- 3.仕訳ソース
    lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                , iv_name         => cv_msg_cfo1_60001        -- パラメータ出力メッセージ
                , iv_token_name1  => cv_tkn_param_name        -- トークン(PARAM_NAME)
                , iv_token_value1 => cv_msgtkn_cfo1_60015     -- 仕訳ソース
                , iv_token_name2  => cv_tkn_param_val         -- トークン(PARAM_VAL)
                , iv_token_value2 => iv_je_source_name        -- パラメータ：仕訳ソース
              );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
--
    -- 4.仕訳カテゴリ
    lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                , iv_name         => cv_msg_cfo1_60001        -- パラメータ出力メッセージ
                , iv_token_name1  => cv_tkn_param_name        -- トークン(PARAM_NAME)
                , iv_token_value1 => cv_msgtkn_cfo1_60016     -- 仕訳カテゴリ
                , iv_token_name2  => cv_tkn_param_val         -- トークン(PARAM_VAL)
                , iv_token_value2 => iv_je_category_name      -- パラメータ：仕訳カテゴリ
              );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- (2) 入力パラメータの必須チェック
    -- ===================================================================
    -- 入力パラメータ「実行区分」が未入力の場合、以下の例外処理を行う。
    IF ( iv_execute_kbn IS NULL ) THEN
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_60009  -- パラメータ必須エラー
                         , cv_tkn_param_name  -- トークン'PARAM_NAME'
                         , cv_msgtkn_cfo1_60013
                       )
                     , 1
                     , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- 入力パラメータ「仕訳ソース」が未入力の場合、以下の例外処理を行う。
    IF ( iv_je_source_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_60009  -- パラメータ必須エラー
                         , cv_tkn_param_name  -- トークン'PARAM_NAME'
                         , cv_msgtkn_cfo1_60015
                       )
                     , 1
                     , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (3) 入力パラメータの不正チェック
    -- ===================================================================
    -- 入力パラメータ「実行区分」が'N', 'D'以外の場合、以下の例外処理を行う。
    IF ( iv_execute_kbn NOT IN ( cv_execute_kbn_n , cv_execute_kbn_d ) ) THEN
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_60010  -- パラメータ不正エラー
                         , cv_tkn_param_name  -- トークン'PARAM_NAME'
                         , cv_msgtkn_cfo1_60013
                       )
                     , 1
                     , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (4) 入力パラメータの組み合わせがOIC連携対象仕訳に存在するかのチェック
    -- ===================================================================
    SELECT
      COUNT(1) AS count
    INTO
      ln_exsist_cnt
    FROM
      xxcfo_oic_target_journal xotj                                       -- OIC連携対象仕訳テーブル
    WHERE
        xotj.if_pattern      = cv_gloif_journal                           -- 連携パターン（GLOIF仕訳の転送）
    AND xotj.set_of_books_id = NVL(in_set_of_books_id,  set_of_books_id)  -- 帳簿ID = 入力パラメータ「帳簿ID」
    AND xotj.je_source       = iv_je_source_name                          -- 仕訳ソース = 入力パラメータ「仕訳ソース」
    AND xotj.je_category     = NVL(iv_je_category_name, je_category)      -- 仕訳カテゴリ = 入力パラメータ「仕訳カテゴリ」
    ;
--
    -- 組み合わせがOIC連携対象仕訳に存在しない場合、以下の例外処理を行う。
    IF ( ln_exsist_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfo     -- アドオン：会計・アドオン領域のアプリケーション短縮名
                     , iv_name         => cv_msg_cfo1_60011  -- OIC連携対象仕訳該当なしエラーエラーメッセージ
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1-2．プロファイル値を取得する
    -- ===============================
--
    -- 1.プロファイルからXXCFO:OIC連携データファイル格納ディレクトリ名取得
    -- ===================================================================
    gv_oic_out_file_dir := FND_PROFILE.VALUE( cv_oic_out_file_dir );
    -- プロファイル取得エラー時
    IF ( gv_oic_out_file_dir IS NULL ) THEN
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_00001  -- プロファイル取得エラー
                         , cv_tkn_prof_name   -- トークン'PROF_NAME'
                         , cv_oic_out_file_dir
                       )
                     , 1
                     , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- Ver1.1 Add Start
    -- 2.プロファイルからXXCFO:OIC連携分割行数（GLOIF）取得
    -- ===================================================================
    BEGIN
      gn_divcnt := TO_NUMBER(FND_PROFILE.VALUE( cv_div_cnt ));
      -- プロファイル取得エラー時
      IF ( gn_divcnt IS NULL ) THEN
        RAISE VALUE_ERROR; -- 下記の例外で処理させるため
      END IF;
    EXCEPTION
    -- *** 例外ハンドラ ***
    WHEN VALUE_ERROR THEN
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_00001  -- プロファイル取得エラー
                         , cv_tkn_prof_name   -- トークン'PROF_NAME'
                         , cv_div_cnt
                       )
                     , 1
                     , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
-- Ver1.1 Add End
--
-- Ver1.3 Add Start
    -- 3.XXCFO:仕訳バッチ内上限仕訳ヘッダ件数（OIC連携）取得
    -- ===================================================================
    BEGIN
      gn_max_h_cnt_per_b := TO_NUMBER(FND_PROFILE.VALUE( cv_prf_max_h_cnt_per_b ));
      -- プロファイル取得エラー時
      IF ( gn_max_h_cnt_per_b IS NULL ) THEN
        RAISE VALUE_ERROR; -- 下記の例外で処理させるため
      END IF;
    EXCEPTION
    -- *** 例外ハンドラ ***
    WHEN VALUE_ERROR THEN
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_00001  -- プロファイル取得エラー
                         , cv_tkn_prof_name   -- トークン'PROF_NAME'
                         , cv_prf_max_h_cnt_per_b
                       )
                     , 1
                     , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
-- Ver1.3 Add End
--
    -- ====================================================================================================
    -- A-1-3．プロファイル値「XXCFO:OIC連携データファイル格納ディレクトリ名」からディレクトリパスを取得する
    -- ====================================================================================================
--
    BEGIN
      SELECT
        RTRIM( ad.directory_path , cv_msg_slash )   AS  directory_path  -- ディレクトリパス
      INTO
        gv_dir_path
      FROM
        all_directories  ad
      WHERE
        ad.directory_name = gv_oic_out_file_dir                         -- プロファイル値「XXCFO:OIC連携データファイル格納ディレクトリ名」
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- ディレクトリパス取得エラーメッセージ
        lv_errmsg := SUBSTRB(
                           cv_msg1
                        || xxccp_common_pkg.get_msg(
                               cv_msg_kbn_coi         -- 'XXCOI'
                             , cv_msg_coi1_00029      -- ディレクトリパス取得エラー
                             , cv_tkn_dir_tok         -- トークン'DIR_TOK'
                             , gv_oic_out_file_dir    -- XXCFO:OIC連携データファイル格納ディレクトリ名
                           )
                       , 1
                       , 5000
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ディレクトリパス取得エラーメッセージ
    -- directory_nameは登録されているが、directory_pathが空白の時
    IF ( gv_dir_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(
                          cv_msg2
                       || xxccp_common_pkg.get_msg(
                              cv_msg_kbn_coi         -- 'XXCOI'
                            , cv_msg_coi1_00029      -- ディレクトリパス取得エラー
                            , cv_tkn_dir_tok         -- トークン'DIR_TOK'
                            , gv_oic_out_file_dir    -- XXCFO:OIC連携データファイル格納ディレクトリ名
                          )
                     , 1
                     , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =================================
    -- A-1-4．出力ファイルをオープンする
    -- =================================
    -- (1) 入力パラメータを条件に出力ファイル名をOIC連携対象仕訳テーブルから取得する。
    OPEN c_prog_journal_cur;
--
    -- (2) 上記(1)で取得したレコード数分以下の処理を繰り返す。
    ln_out_file_tab_cnt := 1;
-- Ver1.1 Add Start
    -- 各会計帳簿の出力ファイル名を初期化
    gv_fl_name_sales := NULL;
    gv_fl_name_ifrs := NULL;
-- Ver1.1 Add End
    <<data1_loop>>
    LOOP
      FETCH c_prog_journal_cur INTO c_journal_rec;
      EXIT WHEN c_prog_journal_cur%NOTFOUND;
-- Ver1.1 Del Start
--      -- 出力ファイル情報テーブル変数に値を格納する。
--      l_out_file_tab(ln_out_file_tab_cnt).set_of_books_id := c_journal_rec.set_of_books_id; -- 帳簿ID
--      l_out_file_tab(ln_out_file_tab_cnt).je_source       := c_journal_rec.je_source;       -- 仕訳ソース
--      l_out_file_tab(ln_out_file_tab_cnt).file_name       := c_journal_rec.file_name;       -- ファイル名
--      l_out_file_tab(ln_out_file_tab_cnt).out_cnt         := 0;                             -- 出力件数
--      -- (2-1) ファイル名をディレクトリパス付きで出力する。
--      lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_msg_kbn_cfo                                         -- 'XXCFO'
--                  , iv_name         => cv_msg_cfo1_60002                                      -- IFファイル名出力メッセージ
--                  , iv_token_name1  => cv_tkn_file_name                                       -- トークン(FILE_NAME)
--                  , iv_token_value1 => gv_dir_path || cv_msg_slash ||c_journal_rec.file_name  -- OIC連携対象のファイル名
--                );
--      -- メッセージ出力
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_msg
--      );
-- Ver1.1 Del End
--
-- Ver1.1 Add Start
      -- ファイル名
      lv_fl_name_noext := SUBSTRB(c_journal_rec.file_name, 1, INSTR(c_journal_rec.file_name, cv_extension) -1);
      lv_fl_name := lv_fl_name_noext || '_' || TO_CHAR(1, cv_fmt_fileno) || cv_extension;
--
      open_output_file(ov_errbuf           => lv_errbuf,
                       ov_retcode          => lv_retcode,
                       ov_errmsg           => lv_errmsg,
                       iv_output_file_name => lv_fl_name,
                       of_file_hand        => lf_file_hand
                      );
      IF lv_retcode = cv_status_error THEN
        RAISE global_api_expt;
      END IF;
--
      -- 出力ファイル情報テーブル変数に値を格納する。
      -- SALES会計帳簿の場合
      IF c_journal_rec.name = cv_sales_sob THEN
        l_out_sale_tab(1).set_of_books_id := c_journal_rec.set_of_books_id; -- 帳簿ID
        l_out_sale_tab(1).je_source       := c_journal_rec.je_source;       -- 仕訳ソース
        l_out_sale_tab(1).file_name       := lv_fl_name;                    -- ファイル名
        l_out_sale_tab(1).file_handle     := lf_file_hand;                  -- ファイルハンドル
        l_out_sale_tab(1).out_cnt         := 0;                             -- 出力件数
        gv_fl_name_sales                  := lv_fl_name_noext;              -- ファイル名(連番なし拡張子なし）
      ELSE
      -- IFRS会計帳簿の場合
        l_out_ifrs_tab(1).set_of_books_id := c_journal_rec.set_of_books_id; -- 帳簿ID
        l_out_ifrs_tab(1).je_source       := c_journal_rec.je_source;       -- 仕訳ソース
        l_out_ifrs_tab(1).file_name       := lv_fl_name;                    -- ファイル名
        l_out_ifrs_tab(1).file_handle     := lf_file_hand;                  -- ファイルハンドル
        l_out_ifrs_tab(1).out_cnt         := 0;                             -- 出力件数
        gv_fl_name_ifrs                   := lv_fl_name_noext;              -- ファイル名(連番なし拡張子なし）
      END IF;
-- Ver1.1 Add End
-- Ver1.1 Del Start
--      -- (2-2) 既に同一ファイルが存在していないかのチェックを行う。
--      UTL_FILE.FGETATTR(
--          gv_oic_out_file_dir
--        , c_journal_rec.file_name                            -- OIC連携対象のファイル名
--        , lb_fexists
--        , ln_file_size
--        , ln_block_size
--      );
--      -- 同一ファイル存在エラーメッセージ
--      IF ( lb_fexists ) THEN
--        -- 空行挿入
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => ''
--        );
--        lv_errmsg := SUBSTRB(
--                         xxccp_common_pkg.get_msg(
--                             cv_msg_kbn_cfo     -- 'XXCFO'
--                           , cv_msg_cfo1_00027  -- 同一ファイル存在エラーメッセージ
--                         )
--                       , 1
--                       , 5000
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--      END IF;
----
--      -- (2-3) ファイルオープンを行う。
--      BEGIN
--        l_out_file_tab(ln_out_file_tab_cnt).file_handle := UTL_FILE.FOPEN(
--                                                               gv_oic_out_file_dir        -- ディレクトリパス
--                                                             , c_journal_rec.file_name    -- ファイル名
--                                                             , cv_open_mode_w             -- オープンモード
--                                                             , cn_max_linesize            -- ファイル行サイズ
--                                                           );
----
--      EXCEPTION
--        -- 例外：ファイル名が無効
--        WHEN UTL_FILE.INVALID_FILENAME THEN
--          lv_errmsg := SUBSTRB(
--                           xxccp_common_pkg.get_msg(
--                               cv_msg_kbn_cfo      -- 'XXCFO'
--                             , cv_msg_cfo1_00029   -- ファイルオープンエラー
--                           )
--                         , 1
--                         , 5000
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        -- 例外：ファイルをオープンできない
--        WHEN UTL_FILE.INVALID_OPERATION THEN
--          lv_errmsg := SUBSTRB(
--                           xxccp_common_pkg.get_msg(
--                               cv_msg_kbn_cfo      -- 'XXCFO'
--                             , cv_msg_cfo1_00029   -- ファイルオープンエラー
--                           )
--                         , 1
--                         , 5000
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        -- 例外：その他
--        WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB(
--                           xxccp_common_pkg.get_msg(
--                               cv_msg_kbn_cfo      -- 'XXCFO'
--                             , cv_msg_cfo1_00029   -- ファイルオープンエラー
--                           )
--                         , 1
--                         , 5000
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
--      ln_out_file_tab_cnt := ln_out_file_tab_cnt + 1;
-- Ver1.1 Del End
    END LOOP data1_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
   * Procedure Name   : output_gloif
   * Description      : 連携データ抽出処理,I/Fファイル出力処理(A-2,A-3)
   ***********************************************************************************/
  PROCEDURE output_gloif(
      in_set_of_books_id  IN  NUMBER      -- 帳簿ID
    , iv_je_source_name   IN  VARCHAR2    -- 仕訳ソース
    , iv_je_category_name IN  VARCHAR2    -- 仕訳カテゴリ
    , ov_errbuf           OUT VARCHAR2    -- エラー・メッセージ           # 固定 #
    , ov_retcode          OUT VARCHAR2    -- リターン・コード             # 固定 #
    , ov_errmsg           OUT VARCHAR2    -- ユーザー・エラー・メッセージ # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2 (100) := 'output_gloif'; -- プログラム名
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
    ln_cnt              NUMBER := 0;                      -- 件数
    ln_out_file_tab_cnt NUMBER;                           -- 出力ファイル情報テーブル変数添字
    lv_file_data        VARCHAR2(30000)   DEFAULT NULL;   -- 出力１行分文字列変数
    ln_set_of_books_id  xxcfo_oic_target_journal.set_of_books_id%TYPE;
    lv_je_source        xxcfo_oic_target_journal.je_source%TYPE;
    lv_je_creation_date VARCHAR2(100);                    -- 現在日時（UTC）
-- Ver1.1 Add Start
    ln_out_file_idx     NUMBER;                                   -- 出力ファイルIndex
    ln_out_line         NUMBER;                                   -- ファイル毎出力行数
    lv_cur_sob          xxcfo_oic_target_journal.name%TYPE;       -- 会計帳簿名
    lv_file_name        xxcfo_oic_target_journal.file_name%TYPE;  -- 出力ファイル名（連番付き）
    lf_file_handle      UTL_FILE.FILE_TYPE;                       -- 出力ファイルハンドル
    lv_je_category_name gl_interface.user_je_category_name%TYPE;  -- 仕訳カテゴリ
    lv_period_name      gl_interface.period_name%TYPE;            -- 会計期間
    lv_currency_code    gl_interface.currency_code%TYPE;          -- 通貨コード
    lv_actual_flag      gl_interface.actual_flag%TYPE;            -- 残高タイプ
    lv_accounting_date  VARCHAR2(30);                             -- 記帳日
    ln_group_id         gl_interface.group_id%TYPE;               -- グループID
-- Ver1.1 Add End
--
    -- *** ローカル・カーソル ***
  CURSOR c_outbound_data1_cur IS
    SELECT
        gi.rowid                                             AS row_id                        --  1.ROWID
      , gi.status                                            AS status                        --  2.ステータス
      , TO_CHAR(gi.accounting_date, cv_date_ymd)             AS accounting_date               --  3.記帳日
      , gjs.je_source_name                                   AS je_source_name                --  4.仕訳ソース
      , gi.user_je_category_name                             AS user_je_category_name         --  5.仕訳カテゴリ
      , gjs.attribute2                                       AS cloud_source                  --  6.ERP Cloud仕訳ソース
      , gi.currency_code                                     AS currency_code                 --  7.通貨
      , gi.actual_flag                                       AS actual_flag                   --  8.残高タイプ
      , gi.code_combination_id                               AS code_combination_id           --  9.コード組合せID
-- Ver 1.2 Mod Start
--      , gi.segment1                                          AS segment1                      -- 10.会社
--      , gi.segment2                                          AS segment2                      -- 11.部門
--      , gi.segment3                                          AS segment3                      -- 12.勘定科目
--      , gi.segment3 || gi.segment4                           AS segment34                     -- 13.補助科目
--      , gi.segment5                                          AS segment5                      -- 14.顧客コード
--      , gi.segment6                                          AS segment6                      -- 15.企業コード
--      , gi.segment7                                          AS segment7                      -- 16.予備１
--      , gi.segment8                                          AS segment8                      -- 17.予備２
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment1
           ELSE
             gi.segment1
         END)                                                AS segment1                      -- 10.会社
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment2
           ELSE
             gi.segment2
         END)                                                AS segment2                      -- 11.部門
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment3
           ELSE
             gi.segment3
         END)                                                AS segment3                      -- 12.勘定科目
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment3 || gcc.segment4
           ELSE
             gi.segment3 || gi.segment4
         END)                                                AS segment34                     -- 13.補助科目
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment5
           ELSE
             gi.segment5
         END)                                                AS segment5                      -- 14.顧客コード
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment6
           ELSE
             gi.segment6
         END)                                                AS segment6                      -- 15.企業コード
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment7
           ELSE
             gi.segment7
         END)                                                AS segment7                      -- 16.予備１
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment8
           ELSE
             gi.segment8
         END)                                                AS segment8                      -- 17.予備２
-- Ver 1.2 Mod End
      , gi.entered_dr                                        AS entered_dr                    -- 18.借方金額
      , gi.entered_cr                                        AS entered_cr                    -- 19.貸方金額
      , gi.accounted_dr                                      AS accounted_dr                  -- 20.換算後借方金額
      , gi.accounted_cr                                      AS accounted_cr                  -- 21.換算後貸方金額
-- Ver1.3 Mod Start
--      , gi.reference1                                        AS reference1                    -- 22.バッチ名
      , gi.reference1 || ' ' ||
          TO_CHAR(
            TRUNC(
              (DENSE_RANK() OVER(PARTITION BY gi.reference1 ORDER BY gi.reference1, gi.reference4) - 1)
              / gn_max_h_cnt_per_b
            ) + 1
          )                                                  AS reference1                    -- 22.バッチ名
-- Ver1.3 Mod End
      , gi.reference2                                        AS reference2                    -- 23.バッチ摘要
      , gi.reference4                                        AS reference4                    -- 24.仕訳名
      , gi.reference5                                        AS reference5                    -- 25.仕訳摘要
      , gi.reference10                                       AS reference10                   -- 26.仕訳明細摘要
      , gi.user_currency_conversion_type                     AS user_currency_conversion_type -- 27.換算タイプ
      , TO_CHAR( gi.currency_conversion_date , cv_date_ymd ) AS currency_conversion_date      -- 28.換算日
      , gi.currency_conversion_rate                          AS currency_conversion_rate      -- 29.換算レート
      , gi.group_id                                          AS group_id                      -- 30.グループID
      , gi.set_of_books_id                                   AS set_of_books_id               -- 31.会計帳簿ID
      , gi.attribute1                                        AS attribute1                    -- 32.消費税コード
      , gi.attribute2                                        AS attribute2                    -- 33.増減事由
      , gi.attribute3                                        AS attribute3                    -- 34.伝票番号
      , gi.attribute4                                        AS attribute4                    -- 35.起票部門
      , gi.attribute6                                        AS attribute6                    -- 36.修正元伝票番号
      , gi.attribute8                                        AS attribute8                    -- 37.販売実績ヘッダID
      , gi.attribute9                                        AS attribute9                    -- 38.稟議決裁番号
      , gi.attribute5                                        AS attribute5                    -- 39.ユーザID
      , gi.attribute7                                        AS attribute7                    -- 40.予備１
      , gi.attribute10                                       AS attribute10                   -- 41.電子データ受領
      , gi.jgzz_recon_ref                                    AS jgzz_recon_ref                -- 42.消込参照
      , gsob.name                                            AS name                          -- 43.会計帳簿名
      , gi.period_name                                       AS period_name                   -- 44.会計期間名
    FROM
        gl_interface              gi                                                          -- GLOIF
      , gl_sets_of_books          gsob                                                        -- 会計帳簿
      , gl_je_sources             gjs                                                         -- 仕訳ソース
      , gl_je_categories          gjc                                                         -- 仕訳カテゴリ
      , xxcfo_oic_target_journal  xotj                                                        -- OIC連携対象仕訳テーブル
-- Ver 1.2 Add Start
      , gl_code_combinations      gcc                                                         -- 勘定科目組合せ
-- Ver 1.2 Add End
    WHERE
        gi.status                = cv_status_code                                             -- ステータス:NEW
    AND gi.set_of_books_id       = gsob.set_of_books_id                                       -- 会計帳簿ID
    AND gi.user_je_source_name   = gjs.user_je_source_name                                    -- ユーザ仕訳ソース名
    AND gi.user_je_category_name = gjc.user_je_category_name                                  -- ユーザ仕訳カテゴリ名
    AND gi.set_of_books_id       = xotj.set_of_books_id                                       -- 帳簿ID
    AND gi.user_je_source_name   = xotj.je_source_name                                        -- ユーザ仕訳ソース名
    AND gi.user_je_category_name = xotj.je_category_name                                      -- ユーザ仕訳カテゴリ名
-- Ver 1.2 Add Start
    AND gi.code_combination_id   = gcc.code_combination_id(+)                                 -- 勘定科目組合せID
-- Ver 1.2 Add End
    AND xotj.if_pattern          = cv_gloif_journal                                           -- 連携パターン :GLOIF仕訳抽出
    AND xotj.set_of_books_id     = NVL( in_set_of_books_id , xotj.set_of_books_id)            -- 帳簿ID = 入力パラメータ「帳簿ID」
    AND xotj.je_source           = iv_je_source_name                                          -- 仕訳ソース = 入力パラメータ「仕訳ソース」
    AND xotj.je_category         = NVL( iv_je_category_name , xotj.je_category)               -- 仕訳カテゴリ = 入力パラメータ「仕訳カテゴリ」
    ORDER BY
        gi.set_of_books_id                                                                    -- 帳簿ID
-- Ver1.1 Add Start
      , gi.period_name                                                                        -- 会計期間
-- Ver1.1 Add End
      , gjs.je_source_name                                                                    -- 仕訳ソース
      , gjc.je_category_name                                                                  -- 仕訳カテゴリ
-- Ver1.1 Add Start
      , gi.currency_code                                                                      -- 通貨
      , gi.actual_flag                                                                        -- 残高タイプ
      , gi.accounting_date                                                                    -- 記帳日
-- Ver1.1 Add End
    FOR UPDATE OF gi.status NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    l_data1_rec      c_outbound_data1_cur%ROWTYPE;           -- GLOIF仕訳取得
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
    -- A-2-1．新規登録されたGLOIF仕訳の抽出
    -- =================================
    OPEN c_outbound_data1_cur;
--
    -- =================================
    -- A-3-1．I/Fファイル出力処理
    -- =================================
    --
    lv_je_creation_date := TO_CHAR(SYS_EXTRACT_UTC(CURRENT_TIMESTAMP), cv_date_ymd );
-- Ver1.1 Add Start
    ln_out_file_idx := 0;             -- 出力ファイルIndex
    ln_out_line := 0;                 -- ファイル毎出力行数
    lv_cur_sob := ' ';                -- 現在会計帳簿名
    ln_group_id := cn_init_group_id;  -- グループID
-- Ver1.1 Add End
    --
    <<main_loop>>
    LOOP
      FETCH c_outbound_data1_cur INTO l_data1_rec;
      EXIT WHEN c_outbound_data1_cur%NOTFOUND;
-- Ver1.1 Add Start
      -- 会計帳簿名が切り替わった場合
      IF l_data1_rec.name <> lv_cur_sob THEN
        --現在会計帳簿名を設定
        lv_cur_sob := l_data1_rec.name;
        -- 変数初期化
        ln_out_line := 0;                -- ファイル毎出力行数初期化
        ln_out_file_idx := 1;            -- 出力ファイルIndex初期化
        ln_group_id := ln_group_id + 1;  -- グループID
      ELSE
        -- 分割行数をこえてかつ
        -- 会計帳簿ID、会計期間、仕訳ソース名、仕訳カテゴリ、通貨コード、実績フラグ、仕訳計上日
        -- が変わった場合、出力ファイルを切り替える
        IF ln_out_line >= gn_divcnt
        AND (
             ln_set_of_books_id   <> l_data1_rec.set_of_books_id        -- 帳簿ID
          OR lv_period_name       <> l_data1_rec.period_name            -- 会計期間
          OR lv_je_source         <> l_data1_rec.je_source_name         -- 仕訳ソース
          OR lv_je_category_name  <> l_data1_rec.user_je_category_name  -- 仕訳カテゴリー
          OR lv_currency_code     <> l_data1_rec.currency_code          -- 通貨コード
          OR lv_actual_flag       <> l_data1_rec.actual_flag            -- 残高タイプ
          OR lv_accounting_date   <> l_data1_rec.accounting_date        -- 記帳日
        ) THEN
          -- 変数初期化
          ln_out_line := 0;                        -- ファイル毎出力行数初期化
          ln_out_file_idx := ln_out_file_idx + 1;  -- 出力ファイルIndexを+1
          ln_group_id := ln_group_id + 1;          -- グループID
--
          -- 新しい出力ファイル名（連番あり）を設定
          IF l_data1_rec.name = cv_sales_sob THEN
            lv_file_name := gv_fl_name_sales;
          ELSE
            lv_file_name := gv_fl_name_ifrs;
          END IF;
          lv_file_name := lv_file_name || '_' || TO_CHAR(ln_out_file_idx, cv_fmt_fileno) || cv_extension;
--
          -- 新しい出力ファイル名（連番あり）をオープン
          open_output_file(ov_errbuf           => lv_errbuf,
                           ov_retcode          => lv_retcode,
                           ov_errmsg           => lv_errmsg,
                           iv_output_file_name => lv_file_name,
                           of_file_hand        => lf_file_handle
                          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
--
          --出力ファイル情報設定
          IF l_data1_rec.name = cv_sales_sob THEN
            l_out_sale_tab(ln_out_file_idx).file_name := lv_file_name;
            l_out_sale_tab(ln_out_file_idx).file_handle := lf_file_handle;
            l_out_sale_tab(ln_out_file_idx).out_cnt := 0;
          ELSE
            l_out_ifrs_tab(ln_out_file_idx).file_name := lv_file_name;
            l_out_ifrs_tab(ln_out_file_idx).file_handle := lf_file_handle;
            l_out_ifrs_tab(ln_out_file_idx).out_cnt := 0;
          END IF;
        END IF;
      END IF;
--
      ln_out_line := ln_out_line + 1;   -- ファイル毎出力行数を+1
--
      -- 出力用ファイルハンドルを取得
      IF l_data1_rec.name = cv_sales_sob THEN
        l_out_sale_tab(ln_out_file_idx).out_cnt := l_out_sale_tab(ln_out_file_idx).out_cnt + 1;
        lf_file_handle := l_out_sale_tab(ln_out_file_idx).file_handle;
      ELSE
        l_out_ifrs_tab(ln_out_file_idx).out_cnt := l_out_ifrs_tab(ln_out_file_idx).out_cnt + 1;
        lf_file_handle := l_out_ifrs_tab(ln_out_file_idx).file_handle;
      END IF;
--
      -- キーブレーク項目を保存
      ln_set_of_books_id   := l_data1_rec.set_of_books_id;        -- 帳簿ID
      lv_period_name       := l_data1_rec.period_name;            -- 会計期間
      lv_je_source         := l_data1_rec.je_source_name;         -- 仕訳ソース
      lv_je_category_name  := l_data1_rec.user_je_category_name;  -- 仕訳カテゴリー
      lv_currency_code     := l_data1_rec.currency_code;          -- 通貨コード
      lv_actual_flag       := l_data1_rec.actual_flag;            -- 残高タイプ
      lv_accounting_date   := l_data1_rec.accounting_date;        -- 記帳日
-- Ver1.1 Add End
-- Ver1.1 Del Start
--      -- (1) 対象データの「帳簿ID」、「仕訳ソース」から、出力ファイルハンドルを取得する。
--      ln_set_of_books_id := l_data1_rec.set_of_books_id; -- 帳簿ID
--      lv_je_source       := l_data1_rec.je_source_name;  -- 仕訳ソース
--      -- 初期化
--      ln_out_file_tab_cnt := 1;
--      <<target_file_loop>>
--      LOOP
--        IF ( 
--             ( ln_set_of_books_id = l_out_file_tab(ln_out_file_tab_cnt).set_of_books_id )
--             AND
--             ( lv_je_source = l_out_file_tab(ln_out_file_tab_cnt).je_source )
--            ) THEN
--          EXIT;
--        END IF;
--        ln_out_file_tab_cnt := ln_out_file_tab_cnt + 1;
--      END LOOP target_file_loop;
-- Ver1.1 Del End
      -- 対象データ件数カウント
      gn_target_cnt := gn_target_cnt + 1 ;
      -- (2) 取得したファイルハンドルにて、ファイル出力する。
      -- 変数の初期化
      lv_file_data := NULL;
      -- データ編集
      lv_file_data := cv_status_code;                                                                                                               --   1.*Status Code
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --   2.*Ledger ID
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.accounting_date;                                                                --   3.*Effective Date of Transaction
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.cloud_source , cv_space );                   --   4.*Journal Source
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.user_je_category_name , cv_space );          --   5.*Journal Category
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.currency_code , cv_space );                  --   6.*Currency Code
      lv_file_data := lv_file_data || cv_delim_comma || lv_je_creation_date;                                                                                    --   7.*Journal Entry Creation Date
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.actual_flag , cv_space );                    --   8.*Actual Flag
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment1 , cv_space );                       --   9.Segment1
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment2 , cv_space );                       --  10.Segment2
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment3 , cv_space );                       --  11.Segment3
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment34 , cv_space );                      --  12.Segment4
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment5 , cv_space );                       --  13.Segment5
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment6 , cv_space );                       --  14.Segment6
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment7 , cv_space );                       --  15.Segment7
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment8 , cv_space );                       --  16.Segment8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  17.Segment9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  18.Segment10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  19.Segment11
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  20.Segment12
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  21.Segment13
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  22.Segment14
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  23.Segment15
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  24.Segment16
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  25.Segment17
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  26.Segment18
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  27.Segment19
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  28.Segment20
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  29.Segment21
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  30.Segment22
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  31.Segment23
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  32.Segment24
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  33.Segment25
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  34.Segment26
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  35.Segment27
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  36.Segment28
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  37.Segment29
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  38.Segment30
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.entered_dr ;                                                                    --  39.Entered Debit Amount
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.entered_cr ;                                                                    --  40.Entered Credit Amount
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.accounted_dr ;                                                                  --  41.Converted Debit Amount
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.accounted_cr ;                                                                  --  42.Converted Credit Amount
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference1 , cv_space );                     --  43.REFERENCE1 (Batch Name)
      -- Ver1.4 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference2 , cv_space );                     --  44.REFERENCE2 (Batch Description)
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.reference2 , cv_lf_str );                                        --  44.REFERENCE2 (Batch Description)
      -- Ver1.4 Mod End
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  45.REFERENCE3
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference4 , cv_space );                     --  46.REFERENCE4 (Journal Entry Name)
      -- Ver1.4 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference5 , cv_space );                     --  47.REFERENCE5 (Journal Entry Description)
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.reference5 , cv_lf_str );                                        --  47.REFERENCE5 (Journal Entry Description)
      -- Ver1.4 Mod End
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  48.REFERENCE6 (Journal Entry Reference)
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  49.REFERENCE7 (Journal Entry Reversal flag)
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  50.REFERENCE8 (Journal Entry Reversal Period)
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  51.REFERENCE9 (Journal Reversal Method)
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference10 , cv_space );                    --  52.REFERENCE10 (Journal Entry Line Description)
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  53.Reference column 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  54.Reference column 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  55.Reference column 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  56.Reference column 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  57.Reference column 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  58.Reference column 6
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  59.Reference column 7
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  60.Reference column 8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  61.Reference column 9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  62.Reference column 10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  63.Statistical Amount
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.user_currency_conversion_type , cv_space );  --  64.Currency Conversion Type
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.currency_conversion_date ;                                                      --  65.Currency Conversion Date
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.currency_conversion_rate ;                                                      --  66.Currency Conversion Rate
-- Ver1.1 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.group_id ;                                                                      --  67.Interface Group Identifier
      lv_file_data := lv_file_data || cv_delim_comma || ln_group_id;                                                                                --  67.Interface Group Identifier
-- Ver1.1 Mod End
      -- Ver1.4 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.name , cv_space );                           --  68.Context field for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute1 , cv_space );                     --  69.ATTRIBUTE1 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute2 , cv_space );                     --  70.ATTRIBUTE2 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute3 , cv_space );                     --  71.Attribute3 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute4 , cv_space );                     --  72.Attribute4 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute6 , cv_space );                     --  73.Attribute5 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute8 , cv_space );                     --  74.Attribute6 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute9 , cv_space );                     --  75.Attribute7 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute5 , cv_space );                     --  76.Attribute8 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute7 , cv_space );                     --  77.Attribute9 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute10 , cv_space );                    --  78.Attribute10 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.jgzz_recon_ref , cv_space );                  --  79.Attribute11 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.name , cv_lf_str );                                              --  68.Context field for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute1 , cv_lf_str );                                        --  69.ATTRIBUTE1 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute2 , cv_lf_str );                                        --  70.ATTRIBUTE2 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute3 , cv_lf_str );                                        --  71.Attribute3 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute4 , cv_lf_str );                                        --  72.Attribute4 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute6 , cv_lf_str );                                        --  73.Attribute5 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute8 , cv_lf_str );                                        --  74.Attribute6 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute9 , cv_lf_str );                                        --  75.Attribute7 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute5 , cv_lf_str );                                        --  76.Attribute8 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute7 , cv_lf_str );                                        --  77.Attribute9 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute10 , cv_lf_str );                                       --  78.Attribute10 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.jgzz_recon_ref , cv_lf_str );                                    --  79.Attribute11 Value for Captured Information DFF
      -- Ver1.4 Mod End
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  80.Attribute12 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  81.Attribute13 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  82.Attribute14 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  83.Attribute15 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  84.Attribute16 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  85.Attribute17 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  86.Attribute18 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  87.Attribute19 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  88.Attribute20 Value for Captured Information DFF
      -- Ver1.4 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.name , cv_space );                           --  89.Context field for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.name , cv_lf_str );                                              --  89.Context field for Captured Information DFF
      -- Ver1.4 Mod End
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  90.Average Journal Flag
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  91.Clearing Company
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.name , cv_space );                           --  92.Ledger Name
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  93.Encumbrance Type ID
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  94.Reconciliation Reference
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.period_name , cv_space );                    --  95.Period Name
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  96.REFERENCE 18
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  97.REFERENCE 19
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  98.REFERENCE 20
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  99.Attribute Date 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 100.Attribute Date 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 101.Attribute Date 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 102.Attribute Date 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 103.Attribute Date 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 104.Attribute Date 6
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 105.Attribute Date 7
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 106.Attribute Date 8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 107.Attribute Date 9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 108.Attribute Date 10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 109.Attribute Number 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 110.Attribute Number 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 111.Attribute Number 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 112.Attribute Number 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 113.Attribute Number 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 114.Attribute Number 6
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 115.Attribute Number 7
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 116.Attribute Number 8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 117.Attribute Number 9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 118.Attribute Number 10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 119.Global Attribute Category
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 120.Global Attribute 1 
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 121.Global Attribute 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 122.Global Attribute 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 123.Global Attribute 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 124.Global Attribute 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 125.Global Attribute 6 
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 126.Global Attribute 7
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 127.Global Attribute 8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 128.Global Attribute 9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 129.Global Attribute 10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 130.Global Attribute 11
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 131.Global Attribute 12
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 132.Global Attribute 13
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 133.Global Attribute 14
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 134.Global Attribute 15
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 135.Global Attribute 16
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 136.Global Attribute 17
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 137.Global Attribute 18
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 138.Global Attribute 19 
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 139.Global Attribute 20 
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 140.Global Attribute Date 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 141.Global Attribute Date 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 142.Global Attribute Date 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 143.Global Attribute Date 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 144.Global Attribute Date 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 145.Global Attribute Number 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 146.Global Attribute Number 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 147.Global Attribute Number 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 148.Global Attribute Number 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 149.Global Attribute Number 5
--
      -- ファイル書込み
      BEGIN
        UTL_FILE.PUT_LINE(
-- Ver1.1 Mod Start
--            l_out_file_tab(ln_out_file_tab_cnt).file_handle
            lf_file_handle
-- Ver1.1 Mod End
          , lv_file_data
        );
        -- 出力件数カウント
-- Ver1.1 Del Start
--        l_out_file_tab(ln_out_file_tab_cnt).out_cnt :=l_out_file_tab(ln_out_file_tab_cnt).out_cnt + 1;
-- Ver1.1 Del End
        gn_normal_cnt := gn_normal_cnt + 1;
        -- 対象データのROWIDを取得する。
        l_gi_rowid_tab(gn_normal_cnt) := l_data1_rec.row_id;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  SUBSTRB(
                            xxccp_common_pkg.get_msg(
                                cv_msg_kbn_cfo      -- 'XXCFO'
                              , cv_msg_cfo1_00030    -- ファイル書き込みエラー
                            )   
                          , 1
                          , 5000
                        );
          lv_errbuf := lv_errmsg || SQLERRM;
          -- ファイルをクローズ
          UTL_FILE.FCLOSE(
-- Ver1.1 Mod Start
--            l_out_file_tab(ln_out_file_tab_cnt).file_handle
            lf_file_handle
-- Ver1.1 Mod End
          );
          RAISE global_process_expt;
      END;
    END LOOP main_loop;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfo            -- 'XXCFO'
                     , iv_name         => cv_msg_cfo1_00019         -- ロックエラーメッセージ
                     , iv_token_name1  => cv_tkn_table              -- トークン名1：TARGET
                     , iv_token_value1 => cv_msgtkn_cfo1_60020      -- トークン値1：GLOIF
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
  END output_gloif;
--
  /**********************************************************************************
   * Procedure Name   : bkup_oic_gloif
   * Description      : バックアップ処理(A-4)
   ***********************************************************************************/
  PROCEDURE bkup_oic_gloif (
      ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ           # 固定 #
    , ov_retcode    OUT VARCHAR2      -- リターン・コード             # 固定 #
    , ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bkup_oic_gloif'; -- プログラム名
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
    -- A-2で取得した抽出データを1件ずつ取得し、以下の処理を繰り返し行う。
    <<bkup_loop>>
    FOR i IN 1..l_gi_rowid_tab.COUNT LOOP
      -- =================================
      -- A-4-1．OIC_GLOIFバックアップテーブル登録処理
      -- =================================
      BEGIN
        INSERT INTO xxcfo_oic_gloif_bkup (
            status                            --   1.Status
          , set_of_books_id                   --   2.Set Of Books Id
          , accounting_date                   --   3.Accounting Date
          , currency_code                     --   4.Currency Code
          , date_created                      --   5.Date Created
          , created_by                        --   6.Created By
          , actual_flag                       --   7.Actual Flag
          , user_je_category_name             --   8.User Je Category Name
          , user_je_source_name               --   9.User Je Source Name
          , currency_conversion_date          --  10.Currency Conversion Date
          , encumbrance_type_id               --  11.Encumbrance Type Id
          , budget_version_id                 --  12.Budget Version Id
          , user_currency_conversion_type     --  13.User Currency Conversion Type
          , currency_conversion_rate          --  14.Currency Conversion Rate
          , average_journal_flag              --  15.Average Journal Flag
          , originating_bal_seg_value         --  16.Originating Bal Seg Value
          , segment1                          --  17.Segment1
          , segment2                          --  18.Segment2
          , segment3                          --  19.Segment3
          , segment4                          --  20.Segment4
          , segment5                          --  21.Segment5
          , segment6                          --  22.Segment6
          , segment7                          --  23.Segment7
          , segment8                          --  24.Segment8
          , segment9                          --  25.Segment9
          , segment10                         --  26.Segment10
          , segment11                         --  27.Segment11
          , segment12                         --  28.Segment12
          , segment13                         --  29.Segment13
          , segment14                         --  30.Segment14
          , segment15                         --  31.Segment15
          , segment16                         --  32.Segment16
          , segment17                         --  33.Segment17
          , segment18                         --  34.Segment18
          , segment19                         --  35.Segment19
          , segment20                         --  36.Segment20
          , segment21                         --  37.Segment21
          , segment22                         --  38.Segment22
          , segment23                         --  39.Segment23
          , segment24                         --  40.Segment24
          , segment25                         --  41.Segment25
          , segment26                         --  42.Segment26
          , segment27                         --  43.Segment27
          , segment28                         --  44.Segment28
          , segment29                         --  45.Segment29
          , segment30                         --  46.Segment30
          , entered_dr                        --  47.Entered Dr
          , entered_cr                        --  48.Entered Cr
          , accounted_dr                      --  49.Accounted Dr
          , accounted_cr                      --  50.Accounted Cr
          , transaction_date                  --  51.Transaction Date
          , reference1                        --  52.Reference1
          , reference2                        --  53.Reference2
          , reference3                        --  54.Reference3
          , reference4                        --  55.Reference4
          , reference5                        --  56.Reference5
          , reference6                        --  57.Reference6
          , reference7                        --  58.Reference7
          , reference8                        --  59.Reference8
          , reference9                        --  60.Reference9
          , reference10                       --  61.Reference10
          , reference11                       --  62.Reference11
          , reference12                       --  63.Reference12
          , reference13                       --  64.Reference13
          , reference14                       --  65.Reference14
          , reference15                       --  66.Reference15
          , reference16                       --  67.Reference16
          , reference17                       --  68.Reference17
          , reference18                       --  69.Reference18
          , reference19                       --  70.Reference19
          , reference20                       --  71.Reference20
          , reference21                       --  72.Reference21
          , reference22                       --  73.Reference22
          , reference23                       --  74.Reference23
          , reference24                       --  75.Reference24
          , reference25                       --  76.Reference25
          , reference26                       --  77.Reference26
          , reference27                       --  78.Reference27
          , reference28                       --  79.Reference28
          , reference29                       --  80.Reference29
          , reference30                       --  81.Reference30
          , je_batch_id                       --  82.Je Batch Id
          , period_name                       --  83.Period Name
          , je_header_id                      --  84.Je Header Id
          , je_line_num                       --  85.Je Line Num
          , chart_of_accounts_id              --  86.Chart Of Accounts Id
          , functional_currency_code          --  87.Functional Currency Code
          , code_combination_id               --  88.Code Combination Id
          , date_created_in_gl                --  89.Date Created In Gl
          , warning_code                      --  90.Warning Code
          , status_description                --  91.Status Description
          , stat_amount                       --  92.Stat Amount
          , group_id                          --  93.Group Id
          , request_id                        --  94.Request Id
          , subledger_doc_sequence_id         --  95.Subledger Doc Sequence Id
          , subledger_doc_sequence_value      --  96.Subledger Doc Sequence Value
          , attribute1                        --  97.Attribute1
          , attribute2                        --  98.Attribute2
          , gl_sl_link_id                     --  99.Gl Sl Link Id
          , gl_sl_link_table                  -- 100.Gl Sl Link Table
          , attribute3                        -- 101.Attribute3
          , attribute4                        -- 102.Attribute4
          , attribute5                        -- 103.Attribute5
          , attribute6                        -- 104.Attribute6
          , attribute7                        -- 105.Attribute7
          , attribute8                        -- 106.Attribute8
          , attribute9                        -- 107.Attribute9
          , attribute10                       -- 108.Attribute10
          , attribute11                       -- 109.Attribute11
          , attribute12                       -- 110.Attribute12
          , attribute13                       -- 111.Attribute13
          , attribute14                       -- 112.Attribute14
          , attribute15                       -- 113.Attribute15
          , attribute16                       -- 114.Attribute16
          , attribute17                       -- 115.Attribute17
          , attribute18                       -- 116.Attribute18
          , attribute19                       -- 117.Attribute19
          , attribute20                       -- 118.Attribute20
          , context                           -- 119.Context
          , context2                          -- 120.Context2
          , invoice_date                      -- 121.Invoice Date
          , tax_code                          -- 122.Tax Code
          , invoice_identifier                -- 123.Invoice Identifier
          , invoice_amount                    -- 124.Invoice Amount
          , context3                          -- 125.Context3
          , ussgl_transaction_code            -- 126.Ussgl Transaction Code
          , descr_flex_error_message          -- 127.Descr Flex Error Message
          , jgzz_recon_ref                    -- 128.Jgzz Recon Ref
          , reference_date                    -- 129.Reference Date
          , bk_created_by                     -- 130.作成者
          , bk_creation_date                  -- 131.作成日
          , bk_last_updated_by                -- 132.最終更新者
          , bk_last_update_date               -- 133.最終更新日
          , bk_last_update_login              -- 134.最終更新ログイン
          , bk_request_id                     -- 135.要求ID
          , bk_program_application_id         -- 136.コンカレント・プログラムのアプリケーションID
          , bk_program_id                     -- 137.コンカレント・プログラムID
          , bk_program_update_date            -- 138.プログラムによる更新日
        )
        SELECT
            gi.status                        AS status                                           --   1.Status
          , gi.set_of_books_id               AS set_of_books_id                                  --   2.Set Of Books Id
          , gi.accounting_date               AS accounting_date                                  --   3.Accounting Date
          , gi.currency_code                 AS currency_code                                    --   4.Currency Code
          , gi.date_created                  AS date_created                                     --   5.Date Created
          , gi.created_by                    AS created_by                                       --   6.Created By
          , gi.actual_flag                   AS actual_flag                                      --   7.Actual Flag
          , gi.user_je_category_name         AS user_je_category_name                            --   8.User Je Category Name
          , gi.user_je_source_name           AS user_je_source_name                              --   9.User Je Source Name
          , gi.currency_conversion_date      AS currency_conversion_date                         --  10.Currency Conversion Date
          , gi.encumbrance_type_id           AS encumbrance_type_id                              --  11.Encumbrance Type Id
          , gi.budget_version_id             AS budget_version_id                                --  12.Budget Version Id
          , gi.user_currency_conversion_type AS user_currency_conversion_type                    --  13.User Currency Conversion Type
          , gi.currency_conversion_rate      AS currency_conversion_rate                         --  14.Currency Conversion Rate
          , gi.average_journal_flag          AS average_journal_flag                             --  15.Average Journal Flag
          , gi.originating_bal_seg_value     AS originating_bal_seg_value                        --  16.Originating Bal Seg Value
          , gi.segment1                      AS segment1                                         --  17.Segment1
          , gi.segment2                      AS segment2                                         --  18.Segment2
          , gi.segment3                      AS segment3                                         --  19.Segment3
          , gi.segment4                      AS segment4                                         --  20.Segment4
          , gi.segment5                      AS segment5                                         --  21.Segment5
          , gi.segment6                      AS segment6                                         --  22.Segment6
          , gi.segment7                      AS segment7                                         --  23.Segment7
          , gi.segment8                      AS segment8                                         --  24.Segment8
          , gi.segment9                      AS segment9                                         --  25.Segment9
          , gi.segment10                     AS segment10                                        --  26.Segment10
          , gi.segment11                     AS segment11                                        --  27.Segment11
          , gi.segment12                     AS segment12                                        --  28.Segment12
          , gi.segment13                     AS segment13                                        --  29.Segment13
          , gi.segment14                     AS segment14                                        --  30.Segment14
          , gi.segment15                     AS segment15                                        --  31.Segment15
          , gi.segment16                     AS segment16                                        --  32.Segment16
          , gi.segment17                     AS segment17                                        --  33.Segment17
          , gi.segment18                     AS segment18                                        --  34.Segment18
          , gi.segment19                     AS segment19                                        --  35.Segment19
          , gi.segment20                     AS segment20                                        --  36.Segment20
          , gi.segment21                     AS segment21                                        --  37.Segment21
          , gi.segment22                     AS segment22                                        --  38.Segment22
          , gi.segment23                     AS segment23                                        --  39.Segment23
          , gi.segment24                     AS segment24                                        --  40.Segment24
          , gi.segment25                     AS segment25                                        --  41.Segment25
          , gi.segment26                     AS segment26                                        --  42.Segment26
          , gi.segment27                     AS segment27                                        --  43.Segment27
          , gi.segment28                     AS segment28                                        --  44.Segment28
          , gi.segment29                     AS segment29                                        --  45.Segment29
          , gi.segment30                     AS segment30                                        --  46.Segment30
          , gi.entered_dr                    AS entered_dr                                       --  47.Entered Dr
          , gi.entered_cr                    AS entered_cr                                       --  48.Entered Cr
          , gi.accounted_dr                  AS accounted_dr                                     --  49.Accounted Dr
          , gi.accounted_cr                  AS accounted_cr                                     --  50.Accounted Cr
          , gi.transaction_date              AS transaction_date                                 --  51.Transaction Date
          , gi.reference1                    AS reference1                                       --  52.Reference1
          , gi.reference2                    AS reference2                                       --  53.Reference2
          , gi.reference3                    AS reference3                                       --  54.Reference3
          , gi.reference4                    AS reference4                                       --  55.Reference4
          , gi.reference5                    AS reference5                                       --  56.Reference5
          , gi.reference6                    AS reference6                                       --  57.Reference6
          , gi.reference7                    AS reference7                                       --  58.Reference7
          , gi.reference8                    AS reference8                                       --  59.Reference8
          , gi.reference9                    AS reference9                                       --  60.Reference9
          , gi.reference10                   AS reference10                                      --  61.Reference10
          , gi.reference11                   AS reference11                                      --  62.Reference11
          , gi.reference12                   AS reference12                                      --  63.Reference12
          , gi.reference13                   AS reference13                                      --  64.Reference13
          , gi.reference14                   AS reference14                                      --  65.Reference14
          , gi.reference15                   AS reference15                                      --  66.Reference15
          , gi.reference16                   AS reference16                                      --  67.Reference16
          , gi.reference17                   AS reference17                                      --  68.Reference17
          , gi.reference18                   AS reference18                                      --  69.Reference18
          , gi.reference19                   AS reference19                                      --  70.Reference19
          , gi.reference20                   AS reference20                                      --  71.Reference20
          , gi.reference21                   AS reference21                                      --  72.Reference21
          , gi.reference22                   AS reference22                                      --  73.Reference22
          , gi.reference23                   AS reference23                                      --  74.Reference23
          , gi.reference24                   AS reference24                                      --  75.Reference24
          , gi.reference25                   AS reference25                                      --  76.Reference25
          , gi.reference26                   AS reference26                                      --  77.Reference26
          , gi.reference27                   AS reference27                                      --  78.Reference27
          , gi.reference28                   AS reference28                                      --  79.Reference28
          , gi.reference29                   AS reference29                                      --  80.Reference29
          , gi.reference30                   AS reference30                                      --  81.Reference30
          , gi.je_batch_id                   AS je_batch_id                                      --  82.Je Batch Id
          , gi.period_name                   AS period_name                                      --  83.Period Name
          , gi.je_header_id                  AS je_header_id                                     --  84.Je Header Id
          , gi.je_line_num                   AS je_line_num                                      --  85.Je Line Num
          , gi.chart_of_accounts_id          AS chart_of_accounts_id                             --  86.Chart Of Accounts Id
          , gi.functional_currency_code      AS functional_currency_code                         --  87.Functional Currency Code
          , gi.code_combination_id           AS code_combination_id                              --  88.Code Combination Id
          , gi.date_created_in_gl            AS date_created_in_gl                               --  89.Date Created In Gl
          , gi.warning_code                  AS warning_code                                     --  90.Warning Code
          , gi.status_description            AS status_description                               --  91.Status Description
          , gi.stat_amount                   AS stat_amount                                      --  92.Stat Amount
          , gi.group_id                      AS group_id                                         --  93.Group Id
          , gi.request_id                    AS request_id                                       --  94.Request Id
          , gi.subledger_doc_sequence_id     AS subledger_doc_sequence_id                        --  95.Subledger Doc Sequence Id
          , gi.subledger_doc_sequence_value  AS subledger_doc_sequence_value                     --  96.Subledger Doc Sequence Value
          , gi.attribute1                    AS attribute1                                       --  97.Attribute1
          , gi.attribute2                    AS attribute2                                       --  98.Attribute2
          , gi.gl_sl_link_id                 AS gl_sl_link_id                                    --  99.Gl Sl Link Id
          , gi.gl_sl_link_table              AS gl_sl_link_table                                 -- 100.Gl Sl Link Table
          , gi.attribute3                    AS attribute3                                       -- 101.Attribute3
          , gi.attribute4                    AS attribute4                                       -- 102.Attribute4
          , gi.attribute5                    AS attribute5                                       -- 103.Attribute5
          , gi.attribute6                    AS attribute6                                       -- 104.Attribute6
          , gi.attribute7                    AS attribute7                                       -- 105.Attribute7
          , gi.attribute8                    AS attribute8                                       -- 106.Attribute8
          , gi.attribute9                    AS attribute9                                       -- 107.Attribute9
          , gi.attribute10                   AS attribute10                                      -- 108.Attribute10
          , gi.attribute11                   AS attribute11                                      -- 109.Attribute11
          , gi.attribute12                   AS attribute12                                      -- 110.Attribute12
          , gi.attribute13                   AS attribute13                                      -- 111.Attribute13
          , gi.attribute14                   AS attribute14                                      -- 112.Attribute14
          , gi.attribute15                   AS attribute15                                      -- 113.Attribute15
          , gi.attribute16                   AS attribute16                                      -- 114.Attribute16
          , gi.attribute17                   AS attribute17                                      -- 115.Attribute17
          , gi.attribute18                   AS attribute18                                      -- 116.Attribute18
          , gi.attribute19                   AS attribute19                                      -- 117.Attribute19
          , gi.attribute20                   AS attribute20                                      -- 118.Attribute20
          , gi.context                       AS context                                          -- 119.Context
          , gi.context2                      AS context2                                         -- 120.Context2
          , gi.invoice_date                  AS invoice_date                                     -- 121.Invoice Date
          , gi.tax_code                      AS tax_code                                         -- 122.Tax Code
          , gi.invoice_identifier            AS invoice_identifier                               -- 123.Invoice Identifier
          , gi.invoice_amount                AS invoice_amount                                   -- 124.Invoice Amount
          , gi.context3                      AS context3                                         -- 125.Context3
          , gi.ussgl_transaction_code        AS ussgl_transaction_code                           -- 126.Ussgl Transaction Code
          , gi.descr_flex_error_message      AS descr_flex_error_message                         -- 127.Descr Flex Error Message
          , gi.jgzz_recon_ref                AS jgzz_recon_ref                                   -- 128.Jgzz Recon Ref
          , gi.reference_date                AS reference_date                                   -- 129.Reference Date
          , cn_created_by                    AS bk_created_by                                    -- 130.作成者
          , cd_creation_date                 AS bk_creation_date                                 -- 131.作成日
          , cn_last_updated_by               AS bk_last_updated_by                               -- 132.最終更新者
          , cd_last_update_date              AS bk_last_update_date                              -- 133.最終更新日
          , cn_last_update_login             AS bk_last_update_login                             -- 134.最終更新ログイン
          , cn_request_id                    AS bk_request_id                                    -- 135.要求ID
          , cn_program_application_id        AS bk_program_application_id                        -- 136.コンカレント・プログラムのアプリケーションID
          , cn_program_id                    AS bk_program_id                                    -- 137.コンカレント・プログラムID
          , cd_program_update_date           AS bk_program_update_date                           -- 138.プログラムによる更新日
        FROM
          gl_interface gi
        WHERE
          gi.rowid = l_gi_rowid_tab(i) -- ROWID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- 登録エラーメッセージ
          lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfo        -- 'XXCFO'
                             , cv_msg_cfo1_00024     -- 登録エラー
                             , cv_tkn_table          -- トークン'TABLE'
                             , cv_msgtkn_cfo1_60019  -- OIC_GLOIFバックアップテーブル
                             , cv_tkn_errmsg         -- トークン'ERRMSG'
                             , SQLERRM               -- SQLERRM
                           )
                         , 1
                         , 5000
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;  
      END;
      -- =================================
      -- A-4-2．GL_INTERFACE(GLOIF)テーブル削除処理
      -- =================================
      BEGIN
        DELETE FROM
          gl_interface gi
        WHERE
          gi.rowid = l_gi_rowid_tab(i) -- ROWID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- 削除エラーメッセージ
          lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfo        -- 'XXCFO'
                             , cv_msg_cfo1_00025     -- 削除エラー
                             , cv_tkn_table          -- トークン'TABLE'
                             , cv_msgtkn_cfo1_60020  -- GLOIF
                             , cv_tkn_errmsg         -- トークン'ERRMSG'
                             , SQLERRM               -- SQLERRM
                           )
                         , 1
                         , 5000
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP bkup_loop;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END bkup_oic_gloif;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_execute_kbn      IN  VARCHAR2    -- 実行区分
    , in_set_of_books_id  IN  NUMBER      -- 帳簿ID
    , iv_je_source_name   IN  VARCHAR2    -- 仕訳ソース
    , iv_je_category_name IN  VARCHAR2    -- 仕訳カテゴリ    
    , ov_errbuf           OUT VARCHAR2    --   エラー・メッセージ           # 固定 #
    , ov_retcode          OUT VARCHAR2    --   リターン・コード             # 固定 #
    , ov_errmsg           OUT VARCHAR2    --   ユーザー・エラー・メッセージ # 固定 #
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- A-1．初期処理 
    -- ===============================
    init (
        iv_execute_kbn      -- 実行区分
      , in_set_of_books_id  -- 帳簿ID
      , iv_je_source_name   -- 仕訳ソース
      , iv_je_category_name -- 仕訳カテゴリ
      , lv_errbuf           -- エラー・メッセージ           # 固定 #
      , lv_retcode          -- リターン・コード             # 固定 #
      , lv_errmsg           -- ユーザー・エラー・メッセージ # 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2．連携データ抽出処理 , A-3．I/Fファイル出力処理
    -- ===============================
    output_gloif ( 
        in_set_of_books_id  -- 帳簿ID
      , iv_je_source_name   -- 仕訳ソース
      , iv_je_category_name -- 仕訳カテゴリ
      , lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , lv_retcode          -- リターン・コード             --# 固定 #
      , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4．バックアップ処理
    -- ===============================
    bkup_oic_gloif ( 
        lv_errbuf           -- エラー・メッセージ           # 固定 #
      , lv_retcode          -- リターン・コード             # 固定 #
      , lv_errmsg           -- ユーザー・エラー・メッセージ # 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
      errbuf              OUT VARCHAR2    -- エラー・メッセージ # 固定 #
    , retcode             OUT VARCHAR2    -- リターン・コード   # 固定 #
    , iv_execute_kbn      IN  VARCHAR2    -- 実行区分
    , in_set_of_books_id  IN  NUMBER      -- 帳簿ID
    , iv_je_source_name   IN  VARCHAR2    -- 仕訳ソース
    , iv_je_category_name IN  VARCHAR2    -- 仕訳カテゴリ
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
    lv_msgbuf          VARCHAR2(5000);  -- ユーザー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        iv_execute_kbn      -- 実行区分
      , in_set_of_books_id  -- 帳簿ID
      , iv_je_source_name   -- 仕訳ソース
      , iv_je_category_name -- 仕訳カテゴリ
      , lv_errbuf           -- エラー・メッセージ           # 固定 #
      , lv_retcode          -- リターン・コード             # 固定 #
      , lv_errmsg           -- ユーザー・エラー・メッセージ # 固定 #
    );
--
    -- ===============================================
    -- A-5．終了処理
    -- ===============================================
    -- エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
      gn_normal_cnt := 0;
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- A-5-1．ファイルクローズ
    -- ===============================================
-- Ver1.1 Add Start
    IF gv_fl_name_sales IS NOT NULL THEN
      <<file_close_loop>>
      FOR i IN 1..l_out_sale_tab.COUNT LOOP
        IF ( UTL_FILE.IS_OPEN ( l_out_sale_tab(i).file_handle ) ) THEN
          UTL_FILE.FCLOSE( l_out_sale_tab(i).file_handle );
        END IF;
      END LOOP file_close_loop;
    END IF;
--
    IF gv_fl_name_ifrs IS NOT NULL THEN
      <<file_close_loop2>>
      FOR i IN 1..l_out_ifrs_tab.COUNT LOOP
        IF ( UTL_FILE.IS_OPEN ( l_out_ifrs_tab(i).file_handle ) ) THEN
          UTL_FILE.FCLOSE( l_out_ifrs_tab(i).file_handle );
        END IF;
      END LOOP file_close_loop2;
    END IF;
-- Ver1.1 Add End
-- Ver1.1 Del Start
--    <<file_close_loop>>
--    FOR i IN 1..l_out_file_tab.COUNT LOOP
--      IF ( UTL_FILE.IS_OPEN ( l_out_file_tab(i).file_handle ) ) THEN
--        UTL_FILE.FCLOSE( l_out_file_tab(i).file_handle );
--      END IF;
--    END LOOP file_close_loop;
-- Ver1.1 Del End
--
    -- A-5-2．抽出件数メッセージ出力
    -- ===============================================
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    lv_msgbuf := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo                           -- 'XXCFO'
                   , iv_name         => cv_msg_cfo1_60004                        -- 検索対象・件数メッセージ
                   , iv_token_name1  => cv_tkn_target                            -- トークン(TARGET)
                   , iv_token_value1 => cv_msgtkn_cfo1_60027                     -- GLOIF仕訳の転送
                   , iv_token_name2  => cv_tkn_count                             -- トークン(COUNT)
                   , iv_token_value2 => TO_CHAR(gn_target_cnt, cv_comma_edit)    -- 抽出件数
                 );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- A-5-3．出力件数メッセージ出力（ファイル数分）
    -- ===============================================
-- Ver1.1 Add Start
    -- SALES ファイル出力件数出力
    IF gv_fl_name_sales IS NOT NULL THEN
      <<log_out_loop>>
      FOR i IN 1..l_out_sale_tab.COUNT LOOP
        lv_msgbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
                        , iv_name         => cv_msg_cfo1_60005                 -- ファイル出力対象・件数メッセージ
                        , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                        , iv_token_value1 => l_out_sale_tab(i).file_name       -- GL仕訳連携データファイル
                        , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                        , iv_token_value2 => TO_CHAR(l_out_sale_tab(i).out_cnt, cv_comma_edit)   -- 出力件数
                       );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_msgbuf
        );
      END LOOP log_out_loop;
    END IF;
--
    -- IFRS ファイル出力件数出力
    IF gv_fl_name_ifrs IS NOT NULL THEN
      <<log_out_loop2>>
      FOR i IN 1..l_out_ifrs_tab.COUNT LOOP
        lv_msgbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
                        , iv_name         => cv_msg_cfo1_60005                 -- ファイル出力対象・件数メッセージ
                        , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                        , iv_token_value1 => l_out_ifrs_tab(i).file_name       -- GL仕訳連携データファイル
                        , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                        , iv_token_value2 => TO_CHAR(l_out_ifrs_tab(i).out_cnt, cv_comma_edit)   -- 出力件数
                       );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_msgbuf
        );
      END LOOP log_out_loop2;
    END IF;
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
-- Ver1.1 Add End
-- Ver1.1 Del Start
--    <<out_cnt_loop>>
--    FOR i IN 1..l_out_file_tab.COUNT LOOP
--      lv_msgbuf := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_cfo                                           -- 'XXCFO'
--                     , iv_name         => cv_msg_cfo1_60005                                        -- ファイル出力対象・件数メッセージ
--                     , iv_token_name1  => cv_tkn_target                                            -- トークン(TARGET)
--                     , iv_token_value1 => l_out_file_tab(i).file_name                              -- 出力ファイル名
--                     , iv_token_name2  => cv_tkn_count                                             -- トークン(COUNT)
--                     , iv_token_value2 => TO_CHAR(NVL(l_out_file_tab(i).out_cnt,0), cv_comma_edit) -- 出力件数
--                   );
--      -- メッセージ出力
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_msgbuf
--      );
--      -- 空行挿入
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => ''
--      );
--    END LOOP out_cnt_loop;
-- Ver1.1 Del End
--
    -- A-5-4．対象・成功・エラー件数メッセージ出力（合計）
    -- ===============================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- A-5-5．処理終了メッセージ出力
    -- ===============================================
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
--###########################  固定部 START   #####################################################
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
END XXCFO010A06C;
/
