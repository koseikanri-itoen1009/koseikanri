CREATE OR REPLACE PACKAGE BODY APPS.XXCFO010A05C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 * 
 * Package Name    : XXCFO010A05C
 * Description     : EBS仕訳抽出
 * MD.050          : T_MD050_CFO_010_A05_EBS仕訳抽出_EBSコンカレント
 * Version         : 1.7
 * 
 * Program List
 * -------------------- -----------------------------------------------------
 *  Name                Description
 * -------------------- -----------------------------------------------------
 *  to_csv_string       CSVファイル用文字列変換
 *  init                初期処理（パラメータチェック・プロファイル取得）(A-1)
 *  data_outbound_proc1 GL仕訳データの抽出・ファイル出力処理            (A-2 ～ A-4-1)
 *  upd_oic_journal_h   OIC仕訳管理ヘッダテーブル更新処理               (A-4-2)
 *  file_close_proc     ファイルクローズ処理                            (共通)
 *  submain             メイン処理プロシージャ
 *  main                コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2023-01-11    1.0   T.Okuyama     初回作成
 *  2023-01-25    1.1   T.Mizutani    ファイル分割対応
 *  2023-03-01    1.2   Y.Ooyama      移行課題No.44対応
 *  2023-03-07    1.3   Y.Ooyama      シナリオテスト不具合No.0063対応
 *  2023-03-17    1.4   Y.Ooyama      シナリオテスト不具合No.0090対応
 *  2023-05-10    1.5   S.Yoshioka    開発残課題07対応
 *  2023-08-01    1.6   Y.Ryu         E_本稼動_19360【会計】ERP売掛管理仕訳転記処理の改善対応
 *  2023-11-15    1.7   Y.Ooyama      E_本稼動_19496 グループ会社統合対応
 ************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_slash     CONSTANT VARCHAR2(3) := '/';
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
  gn_target_cnt    NUMBER;                    -- 対象件数（総数）
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --*** ロック(ビジー)エラー例外 ***
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt,         -54);
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO010A05C'; -- パッケージ名
  cv_msg_kbn_cmm     CONSTANT VARCHAR2(5)   := 'XXCMM';        -- アドオン：マスタ・経理・共通のアプリケーション短縮名
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- アドオン：共通・IF領域のアプリケーション短縮名
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- アドオン：会計・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_coi     CONSTANT VARCHAR2(5)   := 'XXCOI';        -- アドオン：販物・在庫領域のアプリケーション短縮名
--
-- Ver1.2 Del Start
--  cv_group_id1       CONSTANT VARCHAR2(5)   := '1001';               -- Receivables（売掛管理）グループID1
--  cv_group_id2       CONSTANT VARCHAR2(5)   := '1002';               -- Receivables（売掛管理）グループID2
--  cv_group_id3       CONSTANT VARCHAR2(5)   := '1003';               -- Receivables（売掛管理）グループID3
--  cv_group_id4       CONSTANT VARCHAR2(5)   := '1004';               -- Receivables（売掛管理）グループID4
--  cv_group_id5       CONSTANT VARCHAR2(5)   := '1005';               -- Receivables（売掛管理）グループID5
-- Ver1.2 Del End
--
  cv_receivables     CONSTANT VARCHAR2(20) := 'Receivables';         -- ファイル分割対象の仕訳ソース名（売掛管理）
  cv_execute_kbn_n   CONSTANT VARCHAR2(20) := 'N';                   -- 実行区分 = 'N':夜間
  cv_execute_kbn_d   CONSTANT VARCHAR2(20) := 'D';                   -- 実行区分 = 'D':定時
  cv_ebs_journal     CONSTANT VARCHAR2(20) := '1';                   -- 連携パターン   = '1':EBS仕訳抽出
  cv_books_status    CONSTANT VARCHAR2(20) := 'P';                   -- 仕訳ステータス = 'P':転記済
  cv_status_code     CONSTANT VARCHAR2(20) := 'NEW';                 -- ファイル出力固定値：Status Code
  cv_je_source_ast   CONSTANT VARCHAR2(20) := 'Assets';              -- 仕訳ソース：資産管理
  cv_je_source_inv   CONSTANT VARCHAR2(20) := 'Inventory';           -- 仕訳ソース：在庫管理
-- Ver1.1 Add Start
  cv_sales_sob       CONSTANT VARCHAR2(20) := 'SALES-SOB';           -- SALES会計帳簿名
  -- グループID
  cn_init_group_id   CONSTANT NUMBER       := 1000;                  -- グループID初期値
  -- ファイル名用定数
  cv_extension       CONSTANT VARCHAR2(10) := '.csv';                -- ファイル分割時の拡張子
  cv_fmt_fileno      CONSTANT VARCHAR2(10) := 'FM00';                -- ファイル連番書式
-- Ver1.1 Add End
--
  -- メッセージ番号
  cv_msg_coi1_00029  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';    -- ディレクトリパス取得エラー
--
  cv_msg_cfo1_00001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';    -- プロファイル名取得エラーメッセージ
  cv_msg_cfo1_00019  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';    -- ロックエラーメッセージ
  cv_msg_cfo1_00020  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';    -- 更新エラーメッセージ
  cv_msg_cfo1_00024  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';    -- 登録エラーメッセージ
  cv_msg_cfo1_00027  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027';    -- 同一ファイル存在エラーメッセージ
  cv_msg_cfo1_00029  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';    -- ファイルオープンエラーメッセージ
  cv_msg_cfo1_00030  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030';    -- ファイル書込みエラーメッセージ
--
  cv_msg_cfo1_60001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60001';    -- パラメータ出力メッセージ
  cv_msg_cfo1_60002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60002';    -- IFファイル名出力メッセージ
  cv_msg_cfo1_60004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60004';    -- 検索対象・件数メッセージ
  cv_msg_cfo1_60005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60005';    -- ファイル出力対象・件数メッセージ
  cv_msg_cfo1_60009  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60009';    -- パラメータ必須エラーメッセージ
  cv_msg_cfo1_60010  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60010';    -- パラメータ不正エラーメッセージ
  cv_msg_cfo1_60011  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60011';    -- OIC連携対象仕訳該当なしエラーメッセージ
  cv_msg_cfo1_60012  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60012';    -- 未連携_最小仕訳ヘッダID出力メッセージ
  cv_msg_cfo1_60013  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60013';    -- トークン(実行区分)
  cv_msg_cfo1_60014  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60014';    -- トークン(会計帳簿ID)
  cv_msg_cfo1_60015  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60015';    -- トークン(仕訳ソース)
  cv_msg_cfo1_60016  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60016';    -- トークン(仕訳カテゴリ)
  cv_msg_cfo1_60017  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60017';    -- トークン(OIC仕訳管理ヘッダテーブル)
  cv_msg_cfo1_60018  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60018';    -- トークン(OIC仕訳管理明細テーブル)
  cv_msg_cfo1_60026  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60026';    -- トークン((EBS仕訳)
--
  cv_msg1            CONSTANT VARCHAR2(2)  := '1.';                  -- メッセージNo.
  cv_msg2            CONSTANT VARCHAR2(2)  := '2.';                  -- メッセージNo.
  cv_msg3            CONSTANT VARCHAR2(2)  := '3.';                  -- メッセージNo.
  cv_msg4            CONSTANT VARCHAR2(2)  := '4.';                  -- メッセージNo.
  cv_msg5            CONSTANT VARCHAR2(2)  := '5.';                  -- メッセージNo.
--
  -- トークン
  cv_tkn_param_name  CONSTANT VARCHAR2(20) := 'PARAM_NAME';          -- パラメータ名
  cv_tkn_param_val   CONSTANT VARCHAR2(20) := 'PARAM_VAL';           -- パラメータ値
  cv_tkn_ng_profile  CONSTANT VARCHAR2(20) := 'PROF_NAME';           -- プロファイル名
  cv_tkn_dir_tok     CONSTANT VARCHAR2(20) := 'DIR_TOK';             -- ディレクトリ名
  cv_tkn_file_name   CONSTANT VARCHAR2(20) := 'FILE_NAME';           -- ファイル名
  cv_tkn_date1       CONSTANT VARCHAR2(20) := 'DATE1';               -- 前回処理日時（YYYY/MM/DD HH24:MI:SS）
  cv_tkn_date2       CONSTANT VARCHAR2(20) := 'DATE2';               -- 今回処理日時（YYYY/MM/DD HH24:MI:SS）
  cv_tkn_target      CONSTANT VARCHAR2(20) := 'TARGET';              -- 検索対象、またはファイル出力対象
  cv_tkn_count       CONSTANT VARCHAR2(20) := 'COUNT';               -- 件数
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';               -- テーブル名
  cv_tkn_err_msg     CONSTANT VARCHAR2(20) := 'ERRMSG';              -- SQLERRM
  cv_tkn_sqlerrm     CONSTANT VARCHAR2(20) := 'SQLERRM';             -- SQLERRM
  cv_tkn_bookid      CONSTANT VARCHAR2(20) := 'BOOKID';              -- 会計帳簿ID
  cv_tkn_source      CONSTANT VARCHAR2(20) := 'SOURCE';              -- 仕訳ソース
  cv_tkn_category    CONSTANT VARCHAR2(20) := 'CATEGORY';            -- 仕訳カテゴリ
  cv_tkn_id1         CONSTANT VARCHAR2(20) := 'ID1';                 -- 未連携_最小仕訳ヘッダID(処理前)
  cv_tkn_id2         CONSTANT VARCHAR2(20) := 'ID2';                 -- 未連携_最小仕訳ヘッダID(処理後)
--
  -- プロファイル
  cv_data_filedir    CONSTANT VARCHAR2(60) := 'XXCFO1_OIC_OUT_FILE_DIR';  -- XXCFO:OIC連携データファイル格納ディレクトリ名
-- Ver1.1 Add Start
  cv_div_cnt         CONSTANT VARCHAR2(60) := 'XXCFO1_OIC_DIVCNT_GL_JE';  -- XXCFO:OIC連携分割行数（EBS仕訳）
-- Ver1.1 Add End
-- Ver1.2 Add Start
  cv_prf_max_h_cnt_per_b   CONSTANT VARCHAR2(60)   := 'XXCFO1_OIC_MAX_H_CNT_PER_BATCH'; -- XXCFO:仕訳バッチ内上限仕訳ヘッダ件数（OIC連携）
-- Ver1.2 Add End
--
  -- 処理日書式
  cv_proc_date_fm    CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_ymd        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  cv_comma_edit      CONSTANT VARCHAR2(30) := 'FM999,999,999';
--
  -- 現在日時（UTC）
  cd_utc_date        CONSTANT VARCHAR2(30) := TO_CHAR(SYS_EXTRACT_UTC(CURRENT_TIMESTAMP), cv_date_ymd);
--
-- Ver1.1 Add Start
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 出力ファイル名情報のレコード型宣言
  TYPE l_out_file_rtype IS RECORD(
      set_of_books_id     NUMBER               -- 帳簿ID
    , je_source           VARCHAR2(25)         -- 仕訳ソース
    , file_name           VARCHAR2(100)        -- ファイル名(連番付き)
    , file_handle         UTL_FILE.FILE_TYPE   -- ファイルハンドル
    , out_cnt             NUMBER               -- 出力件数
  );
  -- 出力ファイル名情報のテーブル型宣言
  TYPE l_out_file_ttype IS TABLE OF l_out_file_rtype INDEX BY BINARY_INTEGER;
-- Ver1.1 Add End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_data_filedir         VARCHAR2(100);                                        -- XXCFO:OIC連携データファイル格納ディレクトリ名
  gv_file_path            ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;                  -- ファイルパス
  gv_para_exe_kbn         VARCHAR2(150);                                        -- パラメータ：実行区分
  gv_para_sob             VARCHAR2(150);                                        -- パラメータ：会計帳簿ID
  gv_para_source          VARCHAR2(150);                                        -- パラメータ：仕訳ソース
  gv_para_category        VARCHAR2(150);                                        -- パラメータ：仕訳カテゴリ
  gn_pre_sob_id           gl_je_headers.set_of_books_id%TYPE :=NULL;            -- 会計帳簿ID（前回値）
  gv_pre_source           gl_je_headers.je_source%TYPE       :=NULL;            -- 仕訳ソース（前回値）
  gv_pre_category         gl_je_headers.je_category%TYPE     :=NULL;            -- 仕訳カテゴリ（前回値）
--  gn_pre_header_id        gl_je_headers.je_header_id%TYPE    :=NULL;            -- 仕訳ヘッダID（前回値） -- Ver1.4 Del
  gn_pre_min_je_id        gl_je_headers.je_header_id%TYPE    :=NULL;            -- 未連携_最小仕訳ヘッダID（前回値）
--
  -- ファイル出力関連
-- Ver1.1 Add Start
  l_out_sale_tab          l_out_file_ttype;                                     -- SALES出力ファイル情報テーブル変数
  l_out_ifrs_tab          l_out_file_ttype;                                     -- IFRS出力ファイル情報テーブル変数
  gn_divcnt               NUMBER := 0;                                          -- ファイル分割行数
  gv_fl_name_sales        XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- SALESファイル名(連番なし拡張子なし）
  gv_fl_name_ifrs         XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- IFRSファイル名(連番なし拡張子なし）
-- Ver1.1 Add End
-- Ver1.1 Del Start
--  gf_file_hand_01         UTL_FILE.FILE_TYPE;                                   -- ファイル01・ハンドル
--  gf_file_hand_02         UTL_FILE.FILE_TYPE;                                   -- ファイル02・ハンドル
--  gf_file_hand_03         UTL_FILE.FILE_TYPE;                                   -- ファイル03・ハンドル
--  gf_file_hand_04         UTL_FILE.FILE_TYPE;                                   -- ファイル04・ハンドル
--  gf_file_hand_05         UTL_FILE.FILE_TYPE;                                   -- ファイル05・ハンドル
--  gn_cnt_fl_01            NUMBER := 0;                                          -- ファイル01件数
--  gn_cnt_fl_02            NUMBER := 0;                                          -- ファイル02件数
--  gn_cnt_fl_03            NUMBER := 0;                                          -- ファイル03件数
--  gn_cnt_fl_04            NUMBER := 0;                                          -- ファイル04件数
--  gn_cnt_fl_05            NUMBER := 0;                                          -- ファイル05件数
--  gn_fl_out_c             NUMBER := 0;                                          -- ファイル出力件数
--  gv_fl_name1             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- 売掛管理分割1ファイル名
--  gv_fl_name2             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- 売掛管理分割2ファイル名
--  gv_fl_name3             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- 売掛管理分割3ファイル名
--  gv_fl_name4             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- 売掛管理分割4ファイル名
--  gv_fl_name5             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- 売掛管理分割5ファイル名
-- Ver1.1 Del End
--
-- Ver1.2 Add Start
  gn_max_h_cnt_per_b      NUMBER := 0;                                          -- 仕訳バッチ内上限仕訳ヘッダ件数
-- Ver1.2 Add End
--
  cv_open_mode_w          CONSTANT VARCHAR2(1)    := 'w';                       -- ファイルオープンモード（上書き）
  cn_max_linesize         CONSTANT BINARY_INTEGER := 32767;                     -- ファイル行サイズ
--
  -- ==============================
  -- ユーザー定義グローバルカーソル
  -- ==============================
--
-- Ver1.1 Add Start
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
    lv_msgbuf       VARCHAR2(5000);     -- ユーザー・メッセージ
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
      gv_data_filedir,
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
      of_file_hand := UTL_FILE.FOPEN( gv_data_filedir            -- ディレクトリパス
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
    lv_msgbuf := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
                                        , iv_name         => cv_msg_cfo1_60002            -- IFファイル名出力メッセージ
                                        , iv_token_name1  => cv_tkn_file_name             -- トークン(FILE_NAME)
                                        , iv_token_value1 => gv_file_path || iv_output_file_name   -- OIC連携対象のファイル名
                                        );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
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
-- Ver1.5 Add Start
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
-- Ver1.5 Add End
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理（パラメータチェック・プロファイル取得）(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_execute_kbn          IN  VARCHAR2     -- 実行区分 夜間:'N'、定時:'D'
    , in_set_of_books_id      IN  NUMBER       -- 会計帳簿ID
    , iv_je_source_name       IN  VARCHAR2     -- 仕訳ソース
    , iv_je_category_name     IN  VARCHAR2     -- 仕訳カテゴリ
    , ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf    VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode   VARCHAR2(1);     -- リターン・コード
    lv_errmsg    VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
-- Ver1.1 Del Start
--    cv_extension        CONSTANT VARCHAR2(10)  := '.csv';            -- ファイル分割時の拡張子
--    cv_div1             CONSTANT VARCHAR2(10)  := '_1001';           -- ファイル分割時のグループID
--    cv_div2             CONSTANT VARCHAR2(10)  := '_1002';           -- ファイル分割時のグループID
--    cv_div3             CONSTANT VARCHAR2(10)  := '_1003';           -- ファイル分割時のグループID
--    cv_div4             CONSTANT VARCHAR2(10)  := '_1004';           -- ファイル分割時のグループID
--    cv_div5             CONSTANT VARCHAR2(10)  := '_1005';           -- ファイル分割時のグループID
-- Ver1.1 Del End
--
    -- *** ローカル変数 ***
    ln_cnt              NUMBER;                                           -- 件数
    ln_cnt2             NUMBER;                                           -- 件数
    lv_msgbuf           VARCHAR2(5000);                                   -- ユーザー・メッセージ
    lv_msg              VARCHAR(2);                                       -- MSG No.
    lv_fl_name          XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- ファイル名
-- Ver1.1 Add Start
    lv_fl_name_noext    XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- ファイル名（拡張子なし）
-- Ver1.1 Add End
    lf_file_hand        UTL_FILE.FILE_TYPE;                               -- ファイル・ハンドル
--
    -- ファイル出力関連
    lb_fexists          BOOLEAN;                                     -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                                      -- ファイルの長さ
    ln_block_size       NUMBER;                                      -- ファイルシステムのブロックサイズ
--
    -- *** ローカル・カーソル ***
--
    -- OIC連携対象仕訳情報取得
    CURSOR c_prog_journal_cur IS
      SELECT DISTINCT
             set_of_books_id    AS set_of_books_id   -- 会計帳簿ID
-- Ver1.1 Add Start
           , name               AS name              -- 会計帳簿名
-- Ver1.1 Add End
           , je_source          AS je_source         -- 仕訳ソース
           , file_name          AS file_name         -- ファイル名
      FROM   xxcfo_oic_target_journal                                     -- OIC連携対象仕訳テーブル
      WHERE  if_pattern = cv_ebs_journal                                  -- 連携パターン（EBS仕訳抽出）
      AND    set_of_books_id = NVL(in_set_of_books_id,  set_of_books_id)  -- 入力パラメータ「帳簿ID」
      AND    je_source       = iv_je_source_name                          -- 入力パラメータ「仕訳ソース」
      AND    je_category     = NVL(iv_je_category_name, je_category)      -- 入力パラメータ「仕訳カテゴリ」
      ORDER BY je_source, file_name desc;
--
    -- *** ローカル・レコード ***
--
    -- OIC連携対象仕訳テーブル カーソルレコード型
    c_journal_rec      c_prog_journal_cur%ROWTYPE;                   -- 出力ファイル名取得
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
    -- ===================================
    -- A-1-1．入力パラメータをチェックする
    -- ===================================
--
    -- (1) 入力パラメータ出力
    -- ===================================================================
    -- 1.実行区分
    gv_para_exe_kbn := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfo     -- 'XXCFO'
                         , iv_name         => cv_msg_cfo1_60013  -- パラメータ名（実行区分）
                        );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60001        -- パラメータ出力メッセージ
                    , iv_token_name1  => cv_tkn_param_name        -- トークン(PARAM_NAME)
                    , iv_token_value1 => gv_para_exe_kbn          -- 実行区分
                    , iv_token_name2  => cv_tkn_param_val         -- トークン(PARAM_VAL)
                    , iv_token_value2 => iv_execute_kbn           -- パラメータ：実行区分
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
    );
--
    -- 2.会計帳簿ID
    gv_para_sob := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfo      -- 'XXCFO'
                         , iv_name         => cv_msg_cfo1_60014   -- パラメータ名（帳簿ID）
                        );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60001            -- パラメータ出力メッセージ
                    , iv_token_name1  => cv_tkn_param_name            -- トークン(PARAM_NAME)
                    , iv_token_value1 => gv_para_sob                  -- 会計帳簿ID
                    , iv_token_name2  => cv_tkn_param_val             -- トークン(PARAM_VAL)
                    , iv_token_value2 => TO_CHAR(in_set_of_books_id)  -- パラメータ：帳簿ID
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
    );
--
    -- 3.仕訳ソース
    gv_para_source := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfo     -- 'XXCFO'
                         , iv_name         => cv_msg_cfo1_60015  -- パラメータ名（仕訳ソース）
                        );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60001        -- パラメータ出力メッセージ
                    , iv_token_name1  => cv_tkn_param_name        -- トークン(PARAM_NAME)
                    , iv_token_value1 => gv_para_source           -- 仕訳ソース
                    , iv_token_name2  => cv_tkn_param_val         -- トークン(PARAM_VAL)
                    , iv_token_value2 => iv_je_source_name        -- パラメータ：仕訳ソース
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
    );
--
    -- 4.仕訳カテゴリ
    gv_para_category := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfo      -- 'XXCFO'
                         , iv_name         => cv_msg_cfo1_60016   -- パラメータ名（仕訳ソース）
                        );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60001        -- パラメータ出力メッセージ
                    , iv_token_name1  => cv_tkn_param_name        -- トークン(PARAM_NAME)
                    , iv_token_value1 => gv_para_category         -- 仕訳カテゴリ
                    , iv_token_name2  => cv_tkn_param_val         -- トークン(PARAM_VAL)
                    , iv_token_value2 => iv_je_category_name      -- パラメータ：仕訳カテゴリ
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ログ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
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
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                    , cv_msg_cfo1_60009  -- パラメータ必須エラー
                                                    , cv_tkn_param_name  -- トークン'PARAM_NAME'
                                                    , gv_para_exe_kbn    -- 実行区分
                                                   )
                                                  , 1
                                                  , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「仕訳ソース」が未入力の場合、以下の例外処理を行う。
    IF ( iv_je_source_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                    , cv_msg_cfo1_60009  -- パラメータ必須エラー
                                                    , cv_tkn_param_name  -- トークン'PARAM_NAME'
                                                    , gv_para_source     -- 仕訳ソース
                                                   )
                                                  , 1
                                                  , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (3) 入力パラメータの不正チェック
    -- ===================================================================
    -- 入力パラメータ「実行区分」が'N', 'D'以外の場合、以下の例外処理を行う。
    IF ( iv_execute_kbn NOT IN ('N', 'D') ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                    , cv_msg_cfo1_60010  -- パラメータ不正エラー
                                                    , cv_tkn_param_name  -- トークン'PARAM_NAME'
                                                    , gv_para_exe_kbn
                                                   )
                                                  , 1
                                                  , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (4) 入力パラメータの組み合わせがOIC連携対象仕訳に存在するかのチェック
    -- ===================================================================
    SELECT COUNT(1) AS count
    INTO   ln_cnt
    FROM   xxcfo_oic_target_journal xxotj                                     -- OIC連携対象仕訳テーブル
    WHERE  xxotj.if_pattern      = cv_ebs_journal                             -- 連携パターン（EBS仕訳抽出）
    AND    xxotj.set_of_books_id = NVL(in_set_of_books_id,  set_of_books_id)  -- 入力パラメータ「帳簿ID」
    AND    xxotj.je_source       = iv_je_source_name                          -- 入力パラメータ「仕訳ソース」
    AND    xxotj.je_category     = NVL(iv_je_category_name, je_category);     -- 入力パラメータ「仕訳カテゴリ」
--
    -- 組み合わせがOIC連携対象仕訳に存在しない場合、以下の例外処理を行う。
    IF ( ln_cnt = 0 ) THEN
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
    gv_data_filedir := FND_PROFILE.VALUE( cv_data_filedir );
    -- プロファイル取得エラー時
    IF ( gv_data_filedir IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                     , cv_msg_cfo1_00001  -- プロファイル取得エラー
                                                     , cv_tkn_ng_profile  -- トークン'PROF_NAME'
                                                     , cv_data_filedir
                                                    )
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- Ver1.1 Add Start
    -- 2.プロファイルからXXCFO:OIC連携分割行数（EBS仕訳）取得
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
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                     , cv_msg_cfo1_00001  -- プロファイル取得エラー
                                                     , cv_tkn_ng_profile  -- トークン'PROF_NAME'
                                                     , cv_div_cnt
                                                    )
                                                 , 1
                                                 , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
-- Ver1.1 Add End
--
-- Ver1.2 Add Start
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
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                     , cv_msg_cfo1_00001  -- プロファイル取得エラー
                                                     , cv_tkn_ng_profile  -- トークン'PROF_NAME'
                                                     , cv_prf_max_h_cnt_per_b
                                                    )
                                                 , 1
                                                 , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
-- Ver1.2 Add End
--
    -- ====================================================================================================
    -- A-1-3．プロファイル値「XXCFO:OIC連携データファイル格納ディレクトリ名」からディレクトリパスを取得する
    -- ====================================================================================================
    BEGIN
      SELECT RTRIM( ad.directory_path , cv_msg_slash )   AS  directory_path  -- ディレクトリパス
      INTO   gv_file_path
      FROM   all_directories  ad
      WHERE  ad.directory_name = gv_data_filedir;                         -- プロファイル値「XXCFO:OIC連携データファイル格納ディレクトリ名」
    EXCEPTION
      WHEN OTHERS THEN
        -- ディレクトリパス取得エラーメッセージ
        lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_coi         -- 'XXCOI'
                                                                 , cv_msg_coi1_00029      -- ディレクトリパス取得エラー
                                                                 , cv_tkn_dir_tok         -- トークン'DIR_TOK'
                                                                 , gv_data_filedir        -- XXCFO:OIC連携データファイル格納ディレクトリ名
                                                                )
                                                               , 1
                                                               , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ディレクトリパス取得エラーメッセージ
    -- directory_nameは登録されているが、directory_pathが空白の時
    IF ( gv_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_coi         -- 'XXCOI'
                                                               , cv_msg_coi1_00029      -- ディレクトリパス取得エラー
                                                               , cv_tkn_dir_tok         -- トークン'DIR_TOK'
                                                               , gv_data_filedir        -- XXCFO:OIC連携データファイル格納ディレクトリ名
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =================================
    -- A-1-4．出力ファイルをオープンする
    -- =================================
    -- (1) 入力パラメータを条件に出力ファイル名をOIC連携対象仕訳テーブルから取得する。
    -- ファイル名をファイルパス/ファイル名で出力する
    gv_file_path := gv_file_path || cv_msg_slash;
-- Ver1.1 Add Start
    -- 各会計帳簿の出力ファイル名を初期化
    gv_fl_name_sales := NULL;
    gv_fl_name_ifrs := NULL;
-- Ver1.1 Add End
--
    <<data1_loop>>
    ln_cnt := 1;
    FOR c_journal_rec IN c_prog_journal_cur LOOP
-- Ver1.1 Add Start
      -- ファイル名
      lv_fl_name_noext := SUBSTRB(c_journal_rec.file_name, 1, INSTR(c_journal_rec.file_name, cv_extension) -1);
      lv_fl_name  := lv_fl_name_noext || '_' || TO_CHAR(1, cv_fmt_fileno) || cv_extension;
--
-- Ver1.1 Del Start
--      -- (2-2) ファイル名をディレクトリパス付きで出力する。
--      lv_msgbuf := xxccp_common_pkg.get_msg(
--                                             iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                           , iv_name         => cv_msg_cfo1_60002            -- IFファイル名出力メッセージ
--                                           , iv_token_name1  => cv_tkn_file_name             -- トークン(FILE_NAME)
--                                           , iv_token_value1 => gv_file_path || lv_fl_name   -- OIC連携対象のファイル名
--                                           );
--      -- メッセージ出力
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_msgbuf
--      );
-- Ver1.1 Del End
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
--
      ln_cnt := ln_cnt + 1;
-- Ver1.1 Add End
-- Ver1.1 Del Start
--      -- (2-1) 仕訳ソース名が'Receivables'（売掛管理）の場合、グループID（1001, 1002, 1003, 1004, 1005）で細分化したファイル名にする。
--      IF ( c_journal_rec.je_source = cv_receivables AND iv_execute_kbn = cv_execute_kbn_n ) THEN       -- 仕訳ソース名（売掛管理で夜間）
--        lv_fl_name  := SUBSTRB(c_journal_rec.file_name, 1, INSTR(c_journal_rec.file_name,'.csv') -1);  -- 拡張子なしのファイル名
--        gv_fl_name1 := lv_fl_name || cv_div1 || cv_extension;                                          -- 売掛管理分割ファイル1
--        gv_fl_name2 := lv_fl_name || cv_div2 || cv_extension;                                          -- 売掛管理分割ファイル2
--        gv_fl_name3 := lv_fl_name || cv_div3 || cv_extension;                                          -- 売掛管理分割ファイル3
--        gv_fl_name4 := lv_fl_name || cv_div4 || cv_extension;                                          -- 売掛管理分割ファイル4
--        gv_fl_name5 := lv_fl_name || cv_div5 || cv_extension;                                          -- 売掛管理分割ファイル5
--        gn_fl_out_c := 5;
----
--        -- (2-2) ファイル名をディレクトリパス付きで出力する。                                  -- 売掛管理の分割した５ファイル
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IFファイル名出力メッセージ
--                                             , iv_token_name1  => cv_tkn_file_name             -- トークン(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name1  -- OIC連携対象のファイル名
--                                             );
--        -- メッセージ出力
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IFファイル名出力メッセージ
--                                             , iv_token_name1  => cv_tkn_file_name             -- トークン(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name2  -- OIC連携対象のファイル名
--                                             );
--        -- メッセージ出力
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IFファイル名出力メッセージ
--                                             , iv_token_name1  => cv_tkn_file_name             -- トークン(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name3  -- OIC連携対象のファイル名
--                                             );
--        -- メッセージ出力
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IFファイル名出力メッセージ
--                                             , iv_token_name1  => cv_tkn_file_name             -- トークン(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name4  -- OIC連携対象のファイル名
--                                             );
--        -- メッセージ出力
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IFファイル名出力メッセージ
--                                             , iv_token_name1  => cv_tkn_file_name             -- トークン(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name5  -- OIC連携対象のファイル名
--                                             );
--        -- メッセージ出力
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
----
--        -- (2-3) 既に同一ファイルが存在していないか、売掛管理の分割ファイル数分チェックを行う。
--        <<data2_loop>>
--        ln_cnt2 := 1;
--        FOR i in 1..5 LOOP
--          CASE WHEN ln_cnt2 = 1 THEN
--                 lv_fl_name := gv_fl_name1;
--               WHEN ln_cnt2 = 2 THEN
--                 lv_fl_name := gv_fl_name2;
--               WHEN ln_cnt2 = 3 THEN
--                 lv_fl_name := gv_fl_name3;
--               WHEN ln_cnt2 = 4 THEN
--                 lv_fl_name := gv_fl_name4;
--               WHEN ln_cnt2 = 5 THEN
--                 lv_fl_name := gv_fl_name5;
--               ELSE
--                 NULL;
--          END CASE;
----
--          UTL_FILE.FGETATTR( gv_data_filedir
--                           , lv_fl_name                                         -- 売掛管理分割ファイル名
--                           , lb_fexists
--                           , ln_file_size
--                           , ln_block_size );
----
--          -- 同一ファイル存在エラーメッセージ
--          IF ( lb_fexists ) THEN
--            -- 空行挿入
--            FND_FILE.PUT_LINE(
--                which  => FND_FILE.OUTPUT
--              , buff   => ''
--            );
--            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
--                                                         , cv_msg_cfo1_00027  -- 同一ファイル存在エラーメッセージ
--                                                         )
--                                                        , 1
--                                                        , 5000);
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
--          END IF;
----
--          -- (2-4) 売掛管理の分割した５ファイルをオープンする。
--          BEGIN
--            lf_file_hand := UTL_FILE.FOPEN( gv_data_filedir               -- ディレクトリパス
--                                             , lv_fl_name                 -- ファイル名
--                                             , cv_open_mode_w             -- オープンモード
--                                             , cn_max_linesize            -- ファイル行サイズ
--                                             );
----
--            CASE WHEN ln_cnt2 = 1 THEN
--                   gf_file_hand_01 := lf_file_hand;
--                 WHEN ln_cnt2 = 2 THEN
--                   gf_file_hand_02 := lf_file_hand;
--                 WHEN ln_cnt2 = 3 THEN
--                   gf_file_hand_03 := lf_file_hand;
--                 WHEN ln_cnt2 = 4 THEN
--                   gf_file_hand_04 := lf_file_hand;
--                 WHEN ln_cnt2 = 5 THEN
--                   gf_file_hand_05 := lf_file_hand;
--                 ELSE
--                   NULL;
--            END CASE;
----
--          EXCEPTION
--            WHEN UTL_FILE.INVALID_FILENAME THEN
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
--                                                           , cv_msg_cfo1_00029   -- ファイルオープンエラー
--                                                           , cv_tkn_sqlerrm      -- トークン'SQLERRM'
--                                                           , SQLERRM             -- SQLERRM（ファイル名が無効）
--                                                          )
--                                                         , 1
--                                                         , 5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_process_expt;
----
--            WHEN UTL_FILE.INVALID_OPERATION THEN
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
--                                                           , cv_msg_cfo1_00029   -- ファイルオープンエラー
--                                                           , cv_tkn_sqlerrm      -- トークン'SQLERRM'
--                                                           , SQLERRM             -- SQLERRM（ファイルをオープンできない）
--                                                          )
--                                                         , 1
--                                                         , 5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_process_expt;
----
--            WHEN OTHERS THEN
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
--                                                            , cv_msg_cfo1_00029   -- ファイルオープンエラー
--                                                            , cv_tkn_sqlerrm      -- トークン'SQLERRM'
--                                                            , SQLERRM             -- SQLERRM（その他）
--                                                           )
--                                                          , 1
--                                                          , 5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_process_expt;
--          END;
----
--          ln_cnt2 := ln_cnt2 + 1;
--        END LOOP data2_loop;
----
--      ELSE
--        -- 分割ファイル以外のオープン処理
--        IF ( c_journal_rec.je_source = cv_receivables AND iv_execute_kbn = cv_execute_kbn_d ) THEN       -- 仕訳ソース名（売掛管理で定時）
--          lv_fl_name  := SUBSTRB(c_journal_rec.file_name, 1, INSTR(c_journal_rec.file_name,'.csv') -1);  -- 拡張子なしのファイル名
--          lv_fl_name  := lv_fl_name || cv_div1 || cv_extension;                                          -- 売掛管理ファイル1
--        ELSE
--          lv_fl_name := c_journal_rec.file_name;                                                         -- 売掛管理以外のファイル1
--        END IF;
----
--        -- (2-2) ファイル名をディレクトリパス付きで出力する。
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IFファイル名出力メッセージ
--                                             , iv_token_name1  => cv_tkn_file_name             -- トークン(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || lv_fl_name   -- OIC連携対象のファイル名
--                                             );
--        -- メッセージ出力
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
----
--        -- (2-3) 既に同一ファイルが存在していないかのチェックを行う。
--        UTL_FILE.FGETATTR( gv_data_filedir
--                         , lv_fl_name
--                         , lb_fexists
--                         , ln_file_size
--                         , ln_block_size );
----
--        -- 同一ファイル存在エラーメッセージ
--        IF ( lb_fexists ) THEN
--          -- 空行挿入
--          FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--            , buff   => ''
--          );
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
--                                                       , cv_msg_cfo1_00027  -- 同一ファイル存在エラーメッセージ
--                                                       )
--                                                      , 1
--                                                      , 5000);
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        END IF;
----
--        -- (2-4) 売掛管理以外のファイルオープンを行う。
--        BEGIN
--          lf_file_hand := UTL_FILE.FOPEN( gv_data_filedir            -- ディレクトリパス
--                                        , lv_fl_name                 -- ファイル名
--                                        , cv_open_mode_w             -- オープンモード
--                                        , cn_max_linesize            -- ファイル行サイズ
--                                        );
----
--          CASE WHEN ln_cnt =  1 THEN
--                 gv_fl_name1 := lv_fl_name;
--                 gf_file_hand_01 := lf_file_hand;      -- Journal_SALES or Journal_IFRS
--                 gn_fl_out_c := gn_fl_out_c + 1;
--               WHEN ln_cnt =  2 THEN
--                 gv_fl_name2 := lv_fl_name;
--                 gf_file_hand_02 := lf_file_hand;      -- Journal_IFRS
--                 gn_fl_out_c := gn_fl_out_c + 1;
--              ELSE
--                 NULL;
--          END CASE;
----
--        EXCEPTION
--          WHEN UTL_FILE.INVALID_FILENAME THEN
--            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
--                                                         , cv_msg_cfo1_00029   -- ファイルオープンエラー
--                                                         , cv_tkn_sqlerrm      -- トークン'SQLERRM'
--                                                         , SQLERRM             -- SQLERRM（ファイル名が無効）
--                                                        )
--                                                       , 1
--                                                       , 5000);
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
----
--          WHEN UTL_FILE.INVALID_OPERATION THEN
--            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
--                                                         , cv_msg_cfo1_00029   -- ファイルオープンエラー
--                                                         , cv_tkn_sqlerrm      -- トークン'SQLERRM'
--                                                         , SQLERRM             -- SQLERRM（ファイルをオープンできない）
--                                                        )
--                                                       , 1
--                                                       , 5000);
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
----
--          WHEN OTHERS THEN
--            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
--                                                          , cv_msg_cfo1_00029   -- ファイルオープンエラー
--                                                          , cv_tkn_sqlerrm      -- トークン'SQLERRM'
--                                                          , SQLERRM             -- SQLERRM（その他）
--                                                         )
--                                                        , 1
--                                                        , 5000);
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
--        END;
----
--        ln_cnt := ln_cnt + 1;
--      END IF;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : file_close_proc
   * Description      : ファイルクローズ処理 (A-5-1)
   ***********************************************************************************/
  PROCEDURE file_close_proc(
      ov_errbuf       OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode      OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg       OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_close_proc'; -- プログラム名
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
    -- A-6-1．すべてのファイルをクローズする
    -- =====================================
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
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_01 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_01 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_02 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_02 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_03 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_03 );
--    END IF;
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_04 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_04 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_05 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_05 );
--    END IF;
-- Ver1.1 Del End
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
  END file_close_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_oic_journal_h
   * Description      : OIC仕訳管理ヘッダテーブル更新処理 (A-4-2)
   ***********************************************************************************/
  PROCEDURE upd_oic_journal_h(
      ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_oic_journal_h'; -- プログラム名
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
    ln_unsent_header_id          gl_je_headers.je_header_id%TYPE;       -- 未連携_最小仕訳ヘッダID
    lv_msgbuf                    VARCHAR2(5000);                        -- ユーザー・メッセージ
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
    -- ===============================
    -- (1) 仕訳ヘッダから新たな「未連携_最小仕訳ヘッダID」を取得する。
    -- ===============================
    -- A-2で取得した「帳簿ID」、「仕訳カテゴリ」のいずれかが前回値と異なる場合
    -- (1) 仕訳ヘッダから新たな「未連携_最小仕訳ヘッダID」を取得する。
    SELECT
      MIN(gjh.je_header_id)     AS je_header_id
      INTO ln_unsent_header_id                                    -- 未連携_最小仕訳ヘッダID
    FROM
      gl_je_headers             gjh                               -- 仕訳ヘッダ
-- Ver1.1 Del Start
--    , xxcfo_oic_journal_mng_l   xxojl                             -- OIC仕訳管理明細テーブル
-- Ver1.1 Del End
    WHERE
-- Ver1.4 Mod Start
--        gjh.je_header_id     >= gn_pre_header_id                  -- 仕訳ヘッダID（前回値）
        gjh.je_header_id     >= gn_pre_min_je_id                  -- 未連携_最小仕訳ヘッダID（前回値）
-- Ver1.4 Mod End
    AND gjh.set_of_books_id   = gn_pre_sob_id                     -- 会計帳簿ID（前回値）
    AND gjh.je_source         = gv_pre_source                     -- 仕訳ソース（前回値）
    AND gjh.je_category       = gv_pre_category                   -- 仕訳カテゴリ（前回値）
-- Ver1.4 Add Start
    AND gjh.status           <> cv_books_status                   -- ステータス:「転記済」以外
-- Ver1.4 Add End
    AND NOT EXISTS (
            SELECT 1
            FROM   xxcfo_oic_journal_mng_l   xxojl                -- OIC仕訳管理明細テーブル
            WHERE  xxojl.set_of_books_id   = gn_pre_sob_id        -- 会計帳簿ID（前回値）
            AND    xxojl.je_source         = gv_pre_source        -- 仕訳ソース（前回値）
            AND    xxojl.je_category       = gv_pre_category      -- 仕訳カテゴリ（前回値）
            AND    xxojl.je_header_id      = gjh.je_header_id     -- 仕訳ヘッダID
        )
    ;
--
    -- (2)「未連携_最小仕訳ヘッダID」が取得できなかった場合、仕訳ヘッダの「最大仕訳ヘッダID」を取得する。
    IF ( ln_unsent_header_id IS NULL ) THEN
      SELECT
        MAX(gjh.je_header_id)   AS je_header_id                   -- 未連携_仕訳ヘッダID
        INTO ln_unsent_header_id
      FROM
        gl_je_headers  gjh                                        -- 仕訳ヘッダ
      ;
    END IF;
--
    -- (3) 処理前後の未連携_最小仕訳ヘッダIDをメッセージ出力する。
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60012                 -- パラメータ出力メッセージ
                    , iv_token_name1  => cv_tkn_bookid                     -- トークン(BOOKID)
                    , iv_token_value1 => TO_CHAR(gn_pre_sob_id)            -- 会計帳簿ID（前回値）
                    , iv_token_name2  => cv_tkn_source                     -- トークン(SOURCE)
                    , iv_token_value2 => gv_pre_source                     -- 仕訳ソース（前回値）
                    , iv_token_name3  => cv_tkn_category                   -- トークン(CATEGORY)
                    , iv_token_value3 => gv_pre_category                   -- 仕訳カテゴリ（前回値）
                    , iv_token_name4  => cv_tkn_id1                        -- トークン(ID1)
                    , iv_token_value4 => TO_CHAR(gn_pre_min_je_id)         -- 未連携_最小仕訳ヘッダID(処理前)
                    , iv_token_name5  => cv_tkn_id2                        -- トークン(ID2)
                    , iv_token_value5 => TO_CHAR(ln_unsent_header_id)      -- 未連携_最小仕訳ヘッダID(処理後) 
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- (4)  OIC仕訳管理ヘッダテーブル更新
    BEGIN
      UPDATE xxcfo_oic_journal_mng_h
      SET    unsent_min_je_header_id = ln_unsent_header_id,         -- 未連携_仕訳ヘッダID
             last_updated_by         = cn_last_updated_by,          -- 最終更新者
             last_update_date        = cd_last_update_date,         -- 最終更新日
             last_update_login       = cn_last_update_login,        -- 最終更新ログイン
             request_id              = cn_request_id,               -- 要求ID
             program_application_id  = cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
             program_id              = cn_program_id,               -- コンカレント・プログラムID
             program_update_date     = cd_program_update_date       -- プログラム更新日
      WHERE  set_of_books_id    = gn_pre_sob_id                  -- 会計帳簿ID（前回値）
      AND    je_source          = gv_pre_source                  -- 仕訳ソース（前回値）
      AND    je_category        = gv_pre_category;               -- 仕訳カテゴリ（前回値）
--
    EXCEPTION
      WHEN OTHERS THEN
        -- データ更新エラー
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo        -- 'XXCFO'
                                                      , cv_msg_cfo1_00020     -- 更新エラー
                                                      , cv_tkn_table          -- トークン'TABLE'
                                                      , cv_msg_cfo1_60017     -- OIC仕訳管理ヘッダテーブル
                                                      , cv_tkn_err_msg        -- トークン'ERR_MSG'
                                                      , SQLERRM               -- SQLERRM
                                                     )
                                                    , 1
                                                    , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END upd_oic_journal_h;
--
  /**********************************************************************************
   * Procedure Name   : data_outbound_proc1
   * Description      : GL仕訳データの抽出・ファイル出力処理 (A-2 ～ A-4-1)
   ***********************************************************************************/
  PROCEDURE data_outbound_proc1(
      iv_execute_kbn          IN  VARCHAR2     -- 実行区分 夜間:'N'、定時:'D'
    , in_set_of_books_id      IN  NUMBER       -- 会計帳簿ID
    , iv_je_source_name       IN  VARCHAR2     -- 仕訳ソース
    , iv_je_category_name     IN  VARCHAR2     -- 仕訳カテゴリ
    , ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_outbound_proc1'; -- プログラム名
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
    cv_space          CONSTANT VARCHAR2(1)  := ' ';                         -- LF置換単語（FBDIファイル用文字列置換）
    -- Ver1.5 Add Start
    cv_lf_str         CONSTANT VARCHAR2(2)  := '\n';                        -- LF置換単語（FBDIファイル用改行コード置換）
    -- Ver1.5 Add End
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';                         -- CSV区切り文字
    cv_fixed_n        CONSTANT VARCHAR2(1)  := 'N';                         -- 固定出力文字
    ln_sales_sob      CONSTANT NUMBER       := fnd_profile.value('XXCMN_SALES_SET_OF_BOOKS_ID');
    ln_ifrs_sob       CONSTANT NUMBER       := fnd_profile.value('XXCFF1_IFRS_SET_OF_BKS_ID');
--
    -- *** ローカル変数 ***
    ln_cnt            NUMBER := 0;                                          -- 件数
    lv_csv_text       VARCHAR2(30000)                    DEFAULT NULL;      -- 出力１行分文字列変数
    lv_attribute6     gl_je_lines.reference_1%TYPE    := NULL;              -- 売実績ヘッダID / 資産管理キー在庫管理キー
    ln_oic_header_id  gl_je_headers.je_header_id%TYPE := NULL;              -- OIC仕訳管理明細登録ヘッダID
    ln_sob_kbn        NUMBER := 0;                                          -- 帳簿ID別ファイル作成区分
-- Ver1.1 Add Start
    ln_out_file_idx   NUMBER;                                               -- 出力ファイルIndex
    ln_out_line       NUMBER;                                               -- ファイル毎出力行数
    lv_cur_sob        xxcfo_oic_target_journal.name%TYPE;                   -- 会計帳簿名
    lv_file_name      xxcfo_oic_target_journal.file_name%TYPE;              -- 出力ファイル名(連番付き)
    lf_file_handle    UTL_FILE.FILE_TYPE;                                   -- 出力ファイルハンドル
    ln_group_id       gl_interface.group_id%TYPE;                           -- グループID
-- Ver1.1 Add End
--
    -- *** ローカル・カーソル ***
  CURSOR c_outbound_data1_cur
  IS
    SELECT
-- Ver1.3 Add Start
        /*+ 
            LEADING(xxot xxojh gjh)
            INDEX(xxot XXCFO_OIC_TARGET_JOURNAL_U01)
            INDEX(gjh GL_JE_HEADERS_U1)
            USE_NL(xxojh gjh gjl gcc gsob gjb gjs)
        */
-- Ver1.3 Add End
        TO_CHAR(gjl.effective_date, cv_date_ymd)            AS effective_date         --  1.記帳日
      , gjh.je_source                                       AS je_source              --  2.仕訳ソース
      , gjh.je_category                                     AS je_category            --  3.仕訳カテゴリ
      , xxot.je_category_name                               AS je_category_name       --  3.仕訳カテゴリ名
      , gjs.attribute2                                      AS cloud_source           --  4.ERP Cloud仕訳ソース
      , gjh.currency_code                                   AS currency_code          --  5.通貨
      , gjh.actual_flag                                     AS actual_flag            --  6.残高タイプ
      , gcc.segment1                                        AS segment1               --  7.会社
      , gcc.segment2                                        AS segment2               --  8.部門
      , gcc.segment3                                        AS segment3               --  9.勘定科目
      , gcc.segment3 || gcc.segment4                        AS segment34              -- 10.補助科目
      , gcc.segment5                                        AS segment5               -- 11.顧客コード
      , gcc.segment6                                        AS segment6               -- 12.企業コード
      , gcc.segment7                                        AS segment7               -- 13.予備１
      , gcc.segment8                                        AS segment8               -- 14.予備２
      , gjl.entered_dr                                      AS entered_dr             -- 15.借方金額
      , gjl.entered_cr                                      AS entered_cr             -- 16.貸方金額
      , gjl.accounted_dr                                    AS accounted_dr           -- 17.換算後借方金額
      , gjl.accounted_cr                                    AS accounted_cr           -- 18.換算後貸方金額
-- Ver1.2 Mod Start
--      , gjb.name                                            AS b_name                 -- 19.バッチ名
      , gjb.name || ' ' ||
          TO_CHAR(
            TRUNC(
              (DENSE_RANK() OVER(PARTITION BY gjh.je_batch_id ORDER BY gjh.je_batch_id, gjh.je_header_id) - 1)
              / gn_max_h_cnt_per_b
            ) + 1
          )                                                 AS b_name                 -- 19.バッチ名
-- Ver1.2 Mod End
      , gjb.description                                     AS b_description          -- 20.バッチ摘要
      , gjh.name                                            AS h_name                 -- 21.仕訳名
      , gjh.description                                     AS h_description          -- 22.仕訳摘要
      , gjl.description                                     AS l_description          -- 23.仕訳明細摘要
      , gjh.currency_conversion_type                        AS conv_type              -- 24.換算タイプ
      , TO_CHAR(gjh.currency_conversion_date, cv_date_ymd)  AS conv_date              -- 25.換算日
      , gjh.currency_conversion_rate                        AS conv_rate              -- 26.換算レート
      , gjh.set_of_books_id                                 AS set_of_books_id        -- 27.会計帳簿ID
      , gjl.attribute1                                      AS attribute1             -- 28.消費税コード
      , gjl.attribute2                                      AS attribute2             -- 29.増減事由
      , gjl.attribute3                                      AS attribute3             -- 30.伝票番号
      , gjl.attribute4                                      AS attribute4             -- 31.起票部門
      , gjl.attribute6                                      AS attribute6             -- 32.修正元伝票番号
      , gjl.attribute8                                      AS attribute8             -- 33.販売実績ヘッダID
      , gjl.reference_1                                     AS reference_1            -- 34.資産管理キー在庫管理キー
      , gjl.attribute9                                      AS attribute9             -- 35.稟議決裁番号
      , gjl.attribute5                                      AS attribute5             -- 36.ユーザID
      , gjl.attribute7                                      AS attribute7             -- 37.予備１
      , gjl.attribute10                                     AS attribute10            -- 38.電子データ受領
      , gjl.jgzz_recon_ref                                  AS jgzz_recon_ref         -- 39.消込参照
      , gjl.je_line_num                                     AS je_line_num            -- 40.仕訳明細番号
      , gjl.code_combination_id                             AS code_combination_id    -- 41.勘定科目組合せID
      , gjl.subledger_doc_sequence_value                    AS subledger_value        -- 42.補助簿文書番号
-- Ver1.7 Add Start
      , gjl.attribute15                                     AS drafting_company       -- 43.伝票作成会社
-- Ver1.7 Add End
      , gsob.name                                           AS sob_name               -- 44.会計帳簿名
      , gjh.period_name                                     AS period_name            -- 45.会計期間名
      , gjh.je_header_id                                    AS je_header_id           -- 46.仕訳ヘッダID
-- Ver1.2 Del Start
--      , (CASE WHEN gjh.je_source = cv_receivables AND iv_execute_kbn = cv_execute_kbn_n THEN
--                DECODE( MOD(DENSE_RANK() OVER(
--                          ORDER BY
--                              gjh.set_of_books_id       -- 会計帳簿ID
--                            , gjh.je_source             -- 仕訳ソース
--                            , gjh.je_category           -- 仕訳カテゴリ
--                            , gjh.je_header_id          -- 仕訳ヘッダID
--                          ), 5)
--                        , 0, cv_group_id1, 1, cv_group_id2, 2, cv_group_id3, 3, cv_group_id4, 4, cv_group_id5
--                      )
--              WHEN gjh.je_source  = cv_receivables
--              AND  iv_execute_kbn = cv_execute_kbn_d THEN
--                     cv_group_id1
--              ELSE
--                     NULL
--         END)                                               AS group_id               -- 47.グループID
-- Ver1.2 Del End
      , xxojh.unsent_min_je_header_id                       AS min_je_header_id       -- 48.未連携_最小仕訳ヘッダID
    FROM
        gl_sets_of_books          gsob                                -- 会計帳簿
      , gl_je_batches             gjb                                 -- 仕訳バッチ
      , gl_je_headers             gjh                                 -- 仕訳ヘッダ
      , gl_je_lines               gjl                                 -- 仕訳明細
      , gl_code_combinations      gcc                                 -- 勘定科目組合せ
      , gl_je_sources             gjs                                 -- 仕訳ソース
      , xxcfo_oic_target_journal  xxot                                -- OIC連携対象仕訳テーブル
      , xxcfo_oic_journal_mng_h   xxojh                               -- OIC仕訳管理ヘッダテーブル
    WHERE
        gjh.status               = cv_books_status                    -- ステータス:転記済
    AND gjh.set_of_books_id      = gsob.set_of_books_id               -- 会計帳簿ID
    AND gjh.je_batch_id          = gjb.je_batch_id                    -- 仕訳バッチID
    AND gjh.je_header_id         = gjl.je_header_id                   -- 仕訳ヘッダID
    AND gjl.code_combination_id  = gcc.code_combination_id            -- CCID
    AND gjh.je_source            = gjs.je_source_name                 -- 仕訳ソース名
-- Ver1.3 Mod Start
--    AND gjh.set_of_books_id      = xxot.set_of_books_id               -- 会計帳簿ID
--    AND gjh.je_source            = xxot.je_source                     -- 仕訳ソース
--    AND gjh.je_category          = xxot.je_category                   -- 仕訳カテゴリ
    AND xxojh.set_of_books_id    = xxot.set_of_books_id               -- 会計帳簿ID
    AND xxojh.je_source          = xxot.je_source                     -- 仕訳ソース
    AND xxojh.je_category        = xxot.je_category                   -- 仕訳カテゴリ
-- Ver1.3 Mod End
    AND gjh.set_of_books_id      = xxojh.set_of_books_id              -- 会計帳簿ID
    AND gjh.je_source            = xxojh.je_source                    -- 仕訳ソース
    AND gjh.je_category          = xxojh.je_category                  -- 仕訳カテゴリ
    AND gjh.je_header_id        >= xxojh.unsent_min_je_header_id      -- 未連携_最小仕訳ヘッダID
    AND NOT EXISTS (
          SELECT 1
          FROM   xxcfo_oic_journal_mng_l  xxojl                    -- OIC仕訳管理明細テーブル
          WHERE  xxojl.set_of_books_id  = gjh.set_of_books_id      -- 会計帳簿ID
          AND    xxojl.je_source        = gjh.je_source            -- 仕訳ソース
          AND    xxojl.je_category      = gjh.je_category          -- 仕訳カテゴリ
          AND    xxojl.je_header_id     = gjh.je_header_id         -- 仕訳ヘッダID
        )
    AND xxot.if_pattern          = cv_ebs_journal                     -- 連携パターン :EBS仕訳抽出
    AND xxot.set_of_books_id     = NVL(in_set_of_books_id,  xxot.set_of_books_id) -- 入力パラメータ「帳簿ID」
    AND xxot.je_source           = iv_je_source_name                              -- 入力パラメータ「仕訳ソース」
    AND xxot.je_category         = NVL(iv_je_category_name, xxot.je_category)     -- 入力パラメータ「仕訳カテゴリ」
    ORDER BY
        gjh.set_of_books_id                                        -- 会計帳簿ID
      , gjh.je_source                                              -- 仕訳ソース
      , gjh.je_category                                            -- 仕訳カテゴリ
-- Ver1.2 Del Start
--      , group_id                                                   -- グループID
-- Ver1.2 Del End
      , gjh.je_header_id                                           -- 仕訳ヘッダID
      , gjl.je_line_num                                            -- 仕訳明細番号
    FOR UPDATE OF xxojh.unsent_min_je_header_id NOWAIT;
--
    -- *** ローカル・レコード ***
    data1_tbl_rec      c_outbound_data1_cur%ROWTYPE;           -- GL仕訳取得
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================================
    -- A-2.GL仕訳連携データの抽出
    -- =======================================
-- Ver1.1 Add Start
    -- 各変数初期化
    ln_out_file_idx := 0;             -- 出力ファイルIndex
    ln_out_line := 0;                 -- ファイル毎出力行数
    lv_cur_sob := ' ';                -- 現在会計帳簿名
    ln_group_id := cn_init_group_id;  -- グループID
-- Ver1.1 Add End
--
    <<data_loop>>
    FOR data1_tbl_rec IN c_outbound_data1_cur LOOP
-- Ver1.1 Add Start
      -- 会計帳簿名が切り替わった場合
      IF data1_tbl_rec.sob_name <> lv_cur_sob THEN
        --現在会計帳簿名を設定
        lv_cur_sob := data1_tbl_rec.sob_name;
        -- 変数初期化
        ln_out_line := 0;                -- ファイル毎出力行数初期化
        ln_out_file_idx := 1;            -- 出力ファイルIndex初期化
        ln_group_id := ln_group_id + 1;  -- グループID
      ELSE
        -- 分割行数をこえて仕訳ヘッダーIDが変わった場合、出力ファイルを切り替える
        IF ln_out_line >= gn_divcnt
        AND data1_tbl_rec.je_header_id <> ln_oic_header_id THEN
          -- 変数初期化
          ln_out_line := 0;                        -- ファイル毎出力行数初期化
          ln_out_file_idx := ln_out_file_idx + 1;  -- 出力ファイルIndexを+1
          ln_group_id := ln_group_id + 1;          -- グループID
--
          -- 新しい出力ファイル名（連番あり）を設定
          IF data1_tbl_rec.sob_name = cv_sales_sob THEN
            lv_file_name := gv_fl_name_sales;
          ELSE
            lv_file_name := gv_fl_name_ifrs;
          END IF;
          lv_file_name := lv_file_name || '_' || TO_CHAR(ln_out_file_idx, cv_fmt_fileno) || cv_extension;
--
-- Ver1.6 Add Start
          -- ファイルクローズ
          IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
            UTL_FILE.FCLOSE( lf_file_handle );
          END IF;
-- Ver1.6 Add End
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
          IF data1_tbl_rec.sob_name = cv_sales_sob THEN
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
      IF data1_tbl_rec.sob_name = cv_sales_sob THEN
        l_out_sale_tab(ln_out_file_idx).out_cnt := l_out_sale_tab(ln_out_file_idx).out_cnt + 1;
        lf_file_handle := l_out_sale_tab(ln_out_file_idx).file_handle;
      ELSE
        l_out_ifrs_tab(ln_out_file_idx).out_cnt := l_out_ifrs_tab(ln_out_file_idx).out_cnt + 1;
        lf_file_handle := l_out_ifrs_tab(ln_out_file_idx).file_handle;
      END IF;
-- Ver1.1 Add End
      -- 74.売実績ヘッダID / 資産管理キー在庫管理キーの編集
      -- 仕訳ソースが「資産管理」or「在庫管理」の場合、資産管理キー在庫管理キーをDFF6にマッピングする。
      IF ( data1_tbl_rec.je_source = cv_je_source_ast OR data1_tbl_rec.je_source = cv_je_source_inv ) THEN
        lv_attribute6 := data1_tbl_rec.reference_1;
      ELSE
      -- 上記以外の場合、販売実績ヘッダIDをDFF6にマッピングする。
        lv_attribute6 := data1_tbl_rec.attribute8;
      END IF;
--
      -- ファイル出力行列編集
      lv_csv_text := cv_status_code                                                      || cv_delimiter     --   1.固定値：Status Code
        || NULL || cv_delimiter                                                                              --   2.Ledger ID
        || data1_tbl_rec.effective_date                                                  || cv_delimiter     --   3.記帳日
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.cloud_source, cv_space )     || cv_delimiter     --   4.ERP Cloud仕訳ソース
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.je_category_name, cv_space ) || cv_delimiter     --   5.仕訳カテゴリ名
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.currency_code, cv_space )    || cv_delimiter     --   6.通貨
        || cd_utc_date                                                                   || cv_delimiter     --   7.現在日時（UTC）
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.actual_flag, cv_space )      || cv_delimiter     --   8.残高タイプ
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment1, cv_space )         || cv_delimiter     --   9.会社
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment2, cv_space )         || cv_delimiter     --  10.部門
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment3, cv_space )         || cv_delimiter     --  11.勘定科目
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment34,cv_space)          || cv_delimiter     --  12.補助科目
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment5, cv_space )         || cv_delimiter     --  13.顧客コード
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment6, cv_space )         || cv_delimiter     --  14.企業コード
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment7, cv_space )         || cv_delimiter     --  15.予備１
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment8, cv_space )         || cv_delimiter     --  16.予備２
        || NULL || cv_delimiter                                                                              --  17.Segment9
        || NULL || cv_delimiter                                                                              --  18.Segment10
        || NULL || cv_delimiter                                                                              --  19.Segment11
        || NULL || cv_delimiter                                                                              --  20.Segment12
        || NULL || cv_delimiter                                                                              --  21.Segment13
        || NULL || cv_delimiter                                                                              --  22.Segment14
        || NULL || cv_delimiter                                                                              --  23.Segment15
        || NULL || cv_delimiter                                                                              --  24.Segment16
        || NULL || cv_delimiter                                                                              --  25.Segment17
        || NULL || cv_delimiter                                                                              --  26.Segment18
        || NULL || cv_delimiter                                                                              --  27.Segment19
        || NULL || cv_delimiter                                                                              --  28.Segment20
        || NULL || cv_delimiter                                                                              --  29.Segment21
        || NULL || cv_delimiter                                                                              --  30.Segment22
        || NULL || cv_delimiter                                                                              --  31.Segment23
        || NULL || cv_delimiter                                                                              --  32.Segment24
        || NULL || cv_delimiter                                                                              --  33.Segment25
        || NULL || cv_delimiter                                                                              --  34.Segment26
        || NULL || cv_delimiter                                                                              --  35.Segment27
        || NULL || cv_delimiter                                                                              --  36.Segment28
        || NULL || cv_delimiter                                                                              --  37.Segment29
        || NULL || cv_delimiter                                                                              --  38.Segment30
        || data1_tbl_rec.entered_dr                                                    || cv_delimiter       --  39.借方金額
        || data1_tbl_rec.entered_cr                                                    || cv_delimiter       --  40.貸方金額
        || data1_tbl_rec.accounted_dr                                                  || cv_delimiter       --  41.換算後借方金額
        || data1_tbl_rec.accounted_cr                                                  || cv_delimiter       --  42.換算後貸方金額
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.b_name , cv_space )        || cv_delimiter       --  43.バッチ名
        -- Ver1.5 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.b_description , cv_space ) || cv_delimiter       --  44.バッチ摘要
        || to_csv_string( data1_tbl_rec.b_description , cv_lf_str )                    || cv_delimiter       --  44.バッチ摘要
        -- Ver1.5 Mod End
        || NULL || cv_delimiter                                                                              --  45.REFERENCE3
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.h_name , cv_space )        || cv_delimiter       --  46.仕訳名
        -- Ver1.5 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.h_description , cv_space ) || cv_delimiter       --  47.仕訳摘要
        || to_csv_string( data1_tbl_rec.h_description , cv_lf_str )                    || cv_delimiter       --  47.仕訳摘要
        -- Ver1.5 Mod End
        || NULL || cv_delimiter                                                                              --  48.REFERENCE6
        || NULL || cv_delimiter                                                                              --  49.REFERENCE7
        || NULL || cv_delimiter                                                                              --  50.REFERENCE8
        || NULL || cv_delimiter                                                                              --  51.REFERENCE9
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.l_description , cv_space ) || cv_delimiter       --  52.仕訳明細摘要
        || NULL || cv_delimiter                                                                              --  53.Reference column 1
        || NULL || cv_delimiter                                                                              --  54.Reference column 2
        || NULL || cv_delimiter                                                                              --  55.Reference column 3
        || NULL || cv_delimiter                                                                              --  56.Reference column 4
        || NULL || cv_delimiter                                                                              --  57.Reference column 5
        || NULL || cv_delimiter                                                                              --  58.Reference column 6
        || NULL || cv_delimiter                                                                              --  59.Reference column 7
        || NULL || cv_delimiter                                                                              --  60.Reference column 8
        || NULL || cv_delimiter                                                                              --  61.Reference column 9
        || NULL || cv_delimiter                                                                              --  62.Reference column 10
        || NULL || cv_delimiter                                                                              --  63.Statistical Amount
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.conv_type, cv_space )   || cv_delimiter          --  64.換算タイプ
        || data1_tbl_rec.conv_date                                                  || cv_delimiter          --  65.換算日
        || data1_tbl_rec.conv_rate                                                  || cv_delimiter          --  66.換算レート
-- Ver1.1 Mod Start
--        || data1_tbl_rec.group_id                                                   || cv_delimiter          --  67.グループID
        || ln_group_id                                                              || cv_delimiter          --  67.グループID
-- Ver1.1 Mod End
        -- Ver1.5 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.sob_name, cv_space )    || cv_delimiter          --  68.会計帳簿名
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute1, cv_space )  || cv_delimiter          --  69.消費税コード
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute2, cv_space )  || cv_delimiter          --  70.増減事由
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute3, cv_space )  || cv_delimiter          --  71.伝票番号
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute4, cv_space )  || cv_delimiter          --  72.起票部門
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute6, cv_space )  || cv_delimiter          --  73.修正元伝票番号
--        || xxccp_oiccommon_pkg.to_csv_string(lv_attribute6, cv_space ) || cv_delimiter                       --  74.売実績ヘッダID / 資産管理キー在庫管理キー
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute9, cv_space )  || cv_delimiter          --  75.稟議決裁番号
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute5, cv_space )  || cv_delimiter          --  76.ユーザID
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute7, cv_space )  || cv_delimiter          --  77.予備１
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute10, cv_space ) || cv_delimiter          --  78.電子データ受領
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.jgzz_recon_ref, cv_space )      || cv_delimiter  --  79.消込参照
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.je_line_num, cv_space )         || cv_delimiter  --  80.仕訳明細番号
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.code_combination_id, cv_space ) || cv_delimiter  --  81.勘定科目組合せID
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.subledger_value, cv_space )     || cv_delimiter  --  82.補助簿文書番号
        || to_csv_string( data1_tbl_rec.sob_name, cv_lf_str )                         || cv_delimiter        --  68.会計帳簿名
        || to_csv_string( data1_tbl_rec.attribute1, cv_lf_str )                       || cv_delimiter        --  69.消費税コード
        || to_csv_string( data1_tbl_rec.attribute2, cv_lf_str )                       || cv_delimiter        --  70.増減事由
        || to_csv_string( data1_tbl_rec.attribute3, cv_lf_str )                       || cv_delimiter        --  71.伝票番号
        || to_csv_string( data1_tbl_rec.attribute4, cv_lf_str )                       || cv_delimiter        --  72.起票部門
        || to_csv_string( data1_tbl_rec.attribute6, cv_lf_str )                       || cv_delimiter        --  73.修正元伝票番号
        || to_csv_string(lv_attribute6, cv_lf_str )                                   || cv_delimiter        --  74.売実績ヘッダID / 資産管理キー在庫管理キー
        || to_csv_string( data1_tbl_rec.attribute9, cv_lf_str )                       || cv_delimiter        --  75.稟議決裁番号
        || to_csv_string( data1_tbl_rec.attribute5, cv_lf_str )                       || cv_delimiter        --  76.ユーザID
        || to_csv_string( data1_tbl_rec.attribute7, cv_lf_str )                       || cv_delimiter        --  77.予備１
        || to_csv_string( data1_tbl_rec.attribute10, cv_lf_str )                      || cv_delimiter        --  78.電子データ受領
        || to_csv_string( data1_tbl_rec.jgzz_recon_ref, cv_lf_str )                   || cv_delimiter        --  79.消込参照
        || to_csv_string( data1_tbl_rec.je_line_num, cv_lf_str )                      || cv_delimiter        --  80.仕訳明細番号
        || to_csv_string( data1_tbl_rec.code_combination_id, cv_lf_str )              || cv_delimiter        --  81.勘定科目組合せID
        || to_csv_string( data1_tbl_rec.subledger_value, cv_lf_str )                  || cv_delimiter        --  82.補助簿文書番号
        -- Ver1.5 Mod End
-- Ver1.7 Mod Start
--        || NULL || cv_delimiter                                                                              --  83.Attribute15 Value for Captured Information
        || to_csv_string( data1_tbl_rec.drafting_company, cv_lf_str )                 || cv_delimiter        --  83.Attribute15 Value for Captured Information
-- Ver1.7 Mod End
        || NULL || cv_delimiter                                                                              --  84.Attribute16 Value for Captured Information
        || NULL || cv_delimiter                                                                              --  85.Attribute17 Value for Captured Information
        || NULL || cv_delimiter                                                                              --  86.Attribute18 Value for Captured Information
        || NULL || cv_delimiter                                                                              --  87.Attribute19 Value for Captured Information
        || NULL || cv_delimiter                                                                              --  88.Attribute20 Value for Captured Information
        -- Ver1.5 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.sob_name, cv_space )    || cv_delimiter          --  89.会計帳簿名
        || to_csv_string( data1_tbl_rec.sob_name, cv_lf_str )                         || cv_delimiter        --  89.会計帳簿名
        -- Ver1.5 Mod End
        || NULL || cv_delimiter                                                                              --  90.Average Journal Flag
        || NULL || cv_delimiter                                                                              --  91.Clearing Company
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.sob_name, cv_space )    || cv_delimiter          --  92.会計帳簿名
        || NULL || cv_delimiter                                                                              --  93.Encumbrance Type ID
        || NULL || cv_delimiter                                                                              --  94.Reconciliation Reference
-- Ver1.1 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.sob_name, cv_space )    || cv_delimiter          --  95.会計帳簿名
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.period_name, cv_space )    || cv_delimiter       --  95.会計期間名
-- Ver1.1 Mod End
        || NULL || cv_delimiter                                                                              --  96.REFERENCE 18
        || NULL || cv_delimiter                                                                              --  97.REFERENCE 19
        || NULL || cv_delimiter                                                                              --  98.REFERENCE 20
        || NULL || cv_delimiter                                                                              --  99.Attribute Date 1
        || NULL || cv_delimiter                                                                              -- 100.Attribute Date 2
        || NULL || cv_delimiter                                                                              -- 101.Attribute Date 3
        || NULL || cv_delimiter                                                                              -- 102.Attribute Date 4
        || NULL || cv_delimiter                                                                              -- 103.Attribute Date 5
        || NULL || cv_delimiter                                                                              -- 104.Attribute Date 6
        || NULL || cv_delimiter                                                                              -- 105.Attribute Date 7
        || NULL || cv_delimiter                                                                              -- 106.Attribute Date 8
        || NULL || cv_delimiter                                                                              -- 107.Attribute Date 9
        || NULL || cv_delimiter                                                                              -- 108.Attribute Date 10
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.je_header_id, cv_space ) || cv_delimiter         -- 109.仕訳ヘッダID
        || NULL || cv_delimiter                                                                              -- 110.Attribute Number 2
        || NULL || cv_delimiter                                                                              -- 111.Attribute Number 3
        || NULL || cv_delimiter                                                                              -- 112.Attribute Number 4
        || NULL || cv_delimiter                                                                              -- 113.Attribute Number 5
        || NULL || cv_delimiter                                                                              -- 114.Attribute Number 6
        || NULL || cv_delimiter                                                                              -- 115.Attribute Number 7
        || NULL || cv_delimiter                                                                              -- 116.Attribute Number 8
        || NULL || cv_delimiter                                                                              -- 117.Attribute Number 9
        || NULL || cv_delimiter                                                                              -- 118.Attribute Number 10
        || NULL || cv_delimiter                                                                              -- 119.Global Attribute Category
        || NULL || cv_delimiter                                                                              -- 120.Global Attribute 1 
        || NULL || cv_delimiter                                                                              -- 121.Global Attribute 2
        || NULL || cv_delimiter                                                                              -- 122.Global Attribute 3
        || NULL || cv_delimiter                                                                              -- 123.Global Attribute 4
        || NULL || cv_delimiter                                                                              -- 124.Global Attribute 5
        || NULL || cv_delimiter                                                                              -- 125.Global Attribute 6 
        || NULL || cv_delimiter                                                                              -- 126.Global Attribute 7
        || NULL || cv_delimiter                                                                              -- 127.Global Attribute 8
        || NULL || cv_delimiter                                                                              -- 128.Global Attribute 9
        || NULL || cv_delimiter                                                                              -- 129.Global Attribute 10
        || NULL || cv_delimiter                                                                              -- 130.Global Attribute 11
        || NULL || cv_delimiter                                                                              -- 131.Global Attribute 12
        || NULL || cv_delimiter                                                                              -- 132.Global Attribute 13
        || NULL || cv_delimiter                                                                              -- 133.Global Attribute 14
        || NULL || cv_delimiter                                                                              -- 134.Global Attribute 15
        || NULL || cv_delimiter                                                                              -- 135.Global Attribute 16
        || NULL || cv_delimiter                                                                              -- 136.Global Attribute 17
        || NULL || cv_delimiter                                                                              -- 137.Global Attribute 18
        || NULL || cv_delimiter                                                                              -- 138.Global Attribute 19 
        || NULL || cv_delimiter                                                                              -- 139.Global Attribute 20 
        || NULL || cv_delimiter                                                                              -- 140.Global Attribute Date 1
        || NULL || cv_delimiter                                                                              -- 141.Global Attribute Date 2
        || NULL || cv_delimiter                                                                              -- 142.Global Attribute Date 3
        || NULL || cv_delimiter                                                                              -- 143.Global Attribute Date 4
        || NULL || cv_delimiter                                                                              -- 144.Global Attribute Date 5
        || NULL || cv_delimiter                                                                              -- 145.Global Attribute Number 1
        || NULL || cv_delimiter                                                                              -- 146.Global Attribute Number 2
        || NULL || cv_delimiter                                                                              -- 147.Global Attribute Number 3
        || NULL || cv_delimiter                                                                              -- 148.Global Attribute Number 4
        || NULL                                                                                              -- 149.Global Attribute Number 5
      ;
--
      -- =======================================
      -- A-3.GL仕訳連携データのファイル出力
      -- =======================================
      -- ファイル書き込み
-- Ver1.1 Add Start
      UTL_FILE.PUT_LINE( lf_file_handle, lv_csv_text );
-- Ver1.1 Add End
-- Ver1.1 Del Start
--      IF ( iv_execute_kbn = cv_execute_kbn_n AND data1_tbl_rec.je_source = cv_receivables ) THEN       -- 夜間実行＆売掛管理
--        CASE WHEN data1_tbl_rec.group_id = cv_group_id1 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_01, lv_csv_text );
--               gn_cnt_fl_01 := gn_cnt_fl_01 + 1;
--             WHEN data1_tbl_rec.group_id = cv_group_id2 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_02, lv_csv_text );
--               gn_cnt_fl_02 := gn_cnt_fl_02 + 1;
--             WHEN data1_tbl_rec.group_id = cv_group_id3 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_03, lv_csv_text );
--               gn_cnt_fl_03 := gn_cnt_fl_03 + 1;
--             WHEN data1_tbl_rec.group_id = cv_group_id4 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_04, lv_csv_text );
--               gn_cnt_fl_04 := gn_cnt_fl_04 + 1;
--             WHEN data1_tbl_rec.group_id = cv_group_id5 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_05, lv_csv_text );
--               gn_cnt_fl_05 := gn_cnt_fl_05 + 1;
--            ELSE
--               NULL;
--        END CASE;
--      ELSE                                                                            -- 分割対象外
--        IF ( ln_sob_kbn = 0 OR data1_tbl_rec.set_of_books_id  = ln_sob_kbn ) THEN
--          UTL_FILE.PUT_LINE( gf_file_hand_01, lv_csv_text );                          -- Journal_SALES or Journal_IFRS
--          ln_sob_kbn := data1_tbl_rec.set_of_books_id;
--          gn_cnt_fl_01 := gn_cnt_fl_01 + 1;
--        ELSE
--          UTL_FILE.PUT_LINE( gf_file_hand_02, lv_csv_text );                          -- Journal_IFRS
--          gn_cnt_fl_02 := gn_cnt_fl_02 + 1;
--        END IF;
--      END IF;
-- Ver1.1 Del End
      ln_cnt := ln_cnt + 1;
--
      -- =================================
      -- A-4-1.OIC仕訳管理明細テーブル登録
      -- =================================
      -- 仕訳ヘッダID単位に明細テーブルへ登録する
      IF ( ln_oic_header_id IS NULL OR ln_oic_header_id != data1_tbl_rec.je_header_id ) THEN
        BEGIN
          INSERT INTO xxcfo_oic_journal_mng_l(
             set_of_books_id
           , je_source
           , je_category
           , je_header_id
           , created_by
           , creation_date
           , last_updated_by
           , last_update_date
           , last_update_login
           , request_id
           , program_application_id
           , program_id
           , program_update_date
          ) VALUES (
             data1_tbl_rec.set_of_books_id          -- 会計帳簿ID
           , data1_tbl_rec.je_source                -- 仕訳ソース
           , data1_tbl_rec.je_category              -- 仕訳カテゴリ
           , data1_tbl_rec.je_header_id             -- 仕訳ヘッダID
           , cn_created_by                          -- 作成者
           , cd_creation_date                       -- 作成日
           , cn_last_updated_by                     -- 最終更新者
           , cd_last_update_date                    -- 最終更新日
           , cn_last_update_login                   -- 最終更新ログイン
           , cn_request_id                          -- 要求ID
           , cn_program_application_id              -- コンカレント・プログラムのアプリケーションID
           , cn_program_id                          -- コンカレント・プログラムID
           , cd_program_update_date                 -- プログラムによる更新日
          );
--
        EXCEPTION
          WHEN OTHERS THEN
            -- データ登録エラー
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo        -- 'XXCFO'
                                                          , cv_msg_cfo1_00024     -- 登録エラー
                                                          , cv_tkn_table          -- トークン'TABLE'
                                                          , cv_msg_cfo1_60018     -- OIC仕訳管理明細テーブル
                                                          , cv_tkn_err_msg        -- トークン'ERR_MSG'
                                                          , SQLERRM               -- SQLERRM
                                                         )
                                                        , 1
                                                        , 5000);
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
--
      IF ( ln_oic_header_id IS NULL ) THEN
        gn_pre_sob_id    := data1_tbl_rec.set_of_books_id;  -- 会計帳簿ID（前回値）
        gv_pre_source    := data1_tbl_rec.je_source;        -- 仕訳ソース（前回値）
        gv_pre_category  := data1_tbl_rec.je_category;      -- 仕訳カテゴリ（前回値）
        gn_pre_min_je_id := data1_tbl_rec.min_je_header_id; -- 未連携_最小仕訳ヘッダID（前回値）
      END IF;
--
      ln_oic_header_id := data1_tbl_rec.je_header_id;       -- 登録した仕訳ヘッダID
--
      -- ==========================================================================
      -- A-4-2.OIC仕訳管理ヘッダテーブル更新（「未連携_最小仕訳ヘッダID」の最新化）
      -- ==========================================================================
      -- 「帳簿ID」、「仕訳カテゴリ」のいずれかが前回値と異なる場合、ヘッダテーブルの更新処理を行う。
      IF ( ( gn_pre_sob_id   != data1_tbl_rec.set_of_books_id )
        OR ( gv_pre_category != data1_tbl_rec.je_category ) )   THEN
        upd_oic_journal_h(
            lv_errbuf             -- エラー・メッセージ            # 固定 #
          , lv_retcode            -- リターン・コード              # 固定 #
          , lv_errmsg);           -- ユーザー・エラー・メッセージ  # 固定 #
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        gn_pre_sob_id    := data1_tbl_rec.set_of_books_id;  -- 会計帳簿ID（前回値）
        gv_pre_source    := data1_tbl_rec.je_source;        -- 仕訳ソース（前回値）
        gv_pre_category  := data1_tbl_rec.je_category;      -- 仕訳カテゴリ（前回値）
        gn_pre_min_je_id := data1_tbl_rec.min_je_header_id; -- 未連携_最小仕訳ヘッダID（前回値）
--
      END IF;
    END LOOP data_loop;
--
    -- 全件処理後、最終の値でヘッダテーブルの更新処理を行う。
    IF ( gn_pre_sob_id IS NOT NULL ) THEN
      upd_oic_journal_h(
          lv_errbuf             -- エラー・メッセージ            # 固定 #
        , lv_retcode            -- リターン・コード              # 固定 #
        , lv_errmsg);           -- ユーザー・エラー・メッセージ  # 固定 #
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
-- Ver1.6 Add Start
    -- ファイルクローズ
    IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
      UTL_FILE.FCLOSE( lf_file_handle );
    END IF;
-- Ver1.6 Add End
    -- GL仕訳連携の対象件数をセット
    gn_target_cnt  := ln_cnt;                    -- 連携データの件数
    -- 正常件数 = 対象件数（総数）
    gn_normal_cnt  := gn_target_cnt;
--
  EXCEPTION
    WHEN global_lock_expt THEN  -- テーブルロックエラー
      -- ファイルクローズ
-- Ver1.6 Mod Start
--      file_close_proc( lv_errbuf             -- エラー・メッセージ            # 固定 #
--                     , lv_retcode            -- リターン・コード              # 固定 #
--                     , lv_errmsg);           -- ユーザー・エラー・メッセージ  # 固定 #
      IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
        UTL_FILE.FCLOSE( lf_file_handle );
      END IF;
-- Ver1.6 Mod End
      --
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                    , cv_msg_cfo1_00019   -- ロックエラーメッセージ
                                                    , cv_tkn_table        -- トークン(TABLE)
                                                    , cv_msg_cfo1_60017   -- OIC仕訳管理ヘッダテーブル
                                                   )
                                                  , 1
                                                  , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN UTL_FILE.WRITE_ERROR THEN
      -- ファイルクローズ
-- Ver1.6 Mod Start
--      file_close_proc( lv_errbuf             -- エラー・メッセージ            # 固定 #
--                     , lv_retcode            -- リターン・コード              # 固定 #
--                     , lv_errmsg);           -- ユーザー・エラー・メッセージ  # 固定 #
      IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
        UTL_FILE.FCLOSE( lf_file_handle );
      END IF;
-- Ver1.6 Mod End
      --
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                    , cv_msg_cfo1_00030   -- ファイル書き込みエラー
                                                    , cv_tkn_sqlerrm      -- トークン'SQLERRM'
                                                    , SQLERRM             -- SQLERRM
                                                   )
                                                  , 1
                                                  , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
-- Ver1.6 Add Start
          -- ファイルクローズ
          IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
            UTL_FILE.FCLOSE( lf_file_handle );
          END IF;
-- Ver1.6 Add End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
-- Ver1.6 Add Start
          -- ファイルクローズ
          IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
            UTL_FILE.FCLOSE( lf_file_handle );
          END IF;
-- Ver1.6 Add End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルクローズ
-- Ver1.6 Mod Start
--      file_close_proc( lv_errbuf             -- エラー・メッセージ            # 固定 #
--                     , lv_retcode            -- リターン・コード              # 固定 #
--                     , lv_errmsg);           -- ユーザー・エラー・メッセージ  # 固定 #
      IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
        UTL_FILE.FCLOSE( lf_file_handle );
      END IF;
-- Ver1.6 Mod End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルクローズ
-- Ver1.6 Mod Start
--      file_close_proc( lv_errbuf             -- エラー・メッセージ            # 固定 #
--                     , lv_retcode            -- リターン・コード              # 固定 #
--                     , lv_errmsg);           -- ユーザー・エラー・メッセージ  # 固定 #
      IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
        UTL_FILE.FCLOSE( lf_file_handle );
      END IF;
-- Ver1.6 Mod End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_outbound_proc1;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_execute_kbn          IN  VARCHAR2     -- 実行区分 夜間:'N'、定時:'D'
    , in_set_of_books_id      IN  NUMBER       -- 会計帳簿ID
    , iv_je_source_name       IN  VARCHAR2     -- 仕訳ソース
    , iv_je_category_name     IN  VARCHAR2     -- 仕訳カテゴリ
    , ov_errbuf               OUT VARCHAR2     -- エラー・メッセージ            # 固定 #
    , ov_retcode              OUT VARCHAR2     -- リターン・コード              # 固定 #
    , ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ  # 固定 #
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ======================================================
    --  初期処理（パラメータチェック・プロファイル取得）(A-1)
    -- ======================================================
    init(
        iv_execute_kbn          -- 実行区分 夜間:'N'、定時:'D'
      , in_set_of_books_id      -- 会計帳簿ID
      , iv_je_source_name       -- 仕訳ソース
      , iv_je_category_name     -- 仕訳カテゴリ
      , lv_errbuf               -- エラー・メッセージ            # 固定 #
      , lv_retcode              -- リターン・コード              # 固定 #
      , lv_errmsg);             -- ユーザー・エラー・メッセージ  # 固定 #
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  GL仕訳データの抽出・ファイル出力処理 (A-2 ～ A-4-1)
    -- =====================================================
    data_outbound_proc1(
        iv_execute_kbn          -- 実行区分 夜間:'N'、定時:'D'
      , in_set_of_books_id      -- 会計帳簿ID
      , iv_je_source_name       -- 仕訳ソース
      , iv_je_category_name     -- 仕訳カテゴリ
      , lv_errbuf               -- エラー・メッセージ            # 固定 #
      , lv_retcode              -- リターン・コード              # 固定 #
      , lv_errmsg);             -- ユーザー・エラー・メッセージ  # 固定 #
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
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
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                  OUT VARCHAR2      -- エラー・メッセージ   # 固定 #
    , retcode                 OUT VARCHAR2      -- リターン・コード     # 固定 #
    , iv_execute_kbn          IN  VARCHAR2      -- 実行区分 夜間:'N'、定時:'D'
    , in_set_of_books_id      IN  NUMBER        -- 会計帳簿ID
    , iv_je_source_name       IN  VARCHAR2      -- 仕訳ソース
    , iv_je_category_name     IN  VARCHAR2      -- 仕訳カテゴリ
  )
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
    ln_cnt             NUMBER := 0;     -- ファイル数
    ln_cnt2            NUMBER := 0;     -- 出力件数
    lv_fl_name         XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- ファイル名
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
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
        iv_execute_kbn           -- 実行区分 夜間:'N'、定時:'D'
      , in_set_of_books_id       -- 会計帳簿ID
      , iv_je_source_name        -- 仕訳ソース
      , iv_je_category_name      -- 仕訳カテゴリ
      , lv_errbuf                -- エラー・メッセージ            # 固定 #
      , lv_retcode               -- リターン・コード              # 固定 #
      , lv_errmsg                -- ユーザー・エラー・メッセージ  # 固定 #
    );
--
    -- エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt  := 1;                                   -- エラー件数
--
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
      );
    END IF;
--
    -- =============
    -- A-5．終了処理
    -- =============
-- Ver1.6 Del Start
--    -- A-5-1．オープンしているすべてのファイルをクローズする
--    -- =====================================================
---- Ver1.1 Add Start
--    IF gv_fl_name_sales IS NOT NULL THEN
--      <<file_close_loop>>
--      FOR i IN 1..l_out_sale_tab.COUNT LOOP
--        IF ( UTL_FILE.IS_OPEN ( l_out_sale_tab(i).file_handle ) ) THEN
--          UTL_FILE.FCLOSE( l_out_sale_tab(i).file_handle );
--        END IF;
--      END LOOP file_close_loop;
--    END IF;
----
--    IF gv_fl_name_ifrs IS NOT NULL THEN
--      <<file_close_loop2>>
--      FOR i IN 1..l_out_ifrs_tab.COUNT LOOP
--        IF ( UTL_FILE.IS_OPEN ( l_out_ifrs_tab(i).file_handle ) ) THEN
--          UTL_FILE.FCLOSE( l_out_ifrs_tab(i).file_handle );
--        END IF;
--      END LOOP file_close_loop2;
--    END IF;
---- Ver1.1 Add End
-- Ver1.6 Del End
-- Ver1.1 Del Start
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_01 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_01 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_02 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_02 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_03 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_03 );
--    END IF;
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_04 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_04 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_05 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_05 );
--    END IF;
-- Ver1.1 Del End
--
    -- A-5-2．抽出件数を出力する
    -- =========================
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    ln_cnt := gn_target_cnt;                                               -- GL仕訳連携の件数
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60004                 -- 検索対象・件数メッセージ
                    , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
                    , iv_token_value1 => cv_msg_cfo1_60026                 -- トークン(EBS仕訳)
                    , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- 抽出件数
                   );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- A-5-3．出力件数をファイル数分出力する
    -- =====================================
    -- 1.GL仕訳連携ファイル出力件数出力
-- Ver1.1 Add Start
    -- SALES GL仕訳連携ファイル出力件数出力
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
    -- IFRS GL仕訳連携ファイル出力件数出力
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
-- Ver1.1 Add End
-- Ver1.1 Del Start
--    <<data_loop>>
--    ln_cnt := 1;
--    FOR i in 1..gn_fl_out_c LOOP
--      CASE WHEN ln_cnt = 1 THEN
--             lv_fl_name := gv_fl_name1;
--             ln_cnt2    := gn_cnt_fl_01;
--           WHEN ln_cnt = 2 THEN
--             lv_fl_name := gv_fl_name2;
--             ln_cnt2    := gn_cnt_fl_02;
--           WHEN ln_cnt = 3 THEN
--             lv_fl_name := gv_fl_name3;
--             ln_cnt2    := gn_cnt_fl_03;
--           WHEN ln_cnt = 4 THEN
--             lv_fl_name := gv_fl_name4;
--             ln_cnt2    := gn_cnt_fl_04;
--           WHEN ln_cnt = 5 THEN
--             lv_fl_name := gv_fl_name5;
--             ln_cnt2    := gn_cnt_fl_05;
--           ELSE
--             NULL;
--      END CASE;
--      -- 1.GL仕訳連携ファイル出力件数出力
--      lv_msgbuf := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
--                      , iv_name         => cv_msg_cfo1_60005                 -- ファイル出力対象・件数メッセージ
--                      , iv_token_name1  => cv_tkn_target                     -- トークン(TARGET)
--                      , iv_token_value1 => lv_fl_name                        -- GL仕訳連携データファイル
--                      , iv_token_name2  => cv_tkn_count                      -- トークン(COUNT)
--                      , iv_token_value2 => TO_CHAR(ln_cnt2, cv_comma_edit)   -- 出力件数
--                     );
--      -- メッセージ出力
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_msgbuf
--      );
--      ln_cnt := ln_cnt + 1;
--    END LOOP data_loop;
-- Ver1.1 Del End
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --
    -- A-5-4．対象件数、およびI/Fファイルへの出力件数（成功件数／エラー件数）を出力する
    -- ================================================================================
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt, cv_comma_edit)    -- 対象件数
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt, cv_comma_edit)    -- 成功件数
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt, cv_comma_edit)    -- エラー件数
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- A-5-5．終了ステータスにより、該当する処理終了メッセージを出力する
    -- =================================================================
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
    --ス テータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
END XXCFO010A05C;
/
