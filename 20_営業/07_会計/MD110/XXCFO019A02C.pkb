CREATE OR REPLACE PACKAGE BODY XXCFO019A02C AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A02C(body)
 * Description      : 電子帳簿仕訳の情報系システム連携
 * MD.050           : MD050_CFO_019_A02_電子帳簿仕訳の情報系システム連携
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_gl_je_wait         未連携データ取得処理(A-2)
 *  get_gl_je_control      管理テーブルデータ取得処理(A-3)
 *  get_gl_je              対象データ取得(A-4)
 *  get_flex_information   付加情報取得処理(A-5)
 *  chk_item               項目チェック処理(A-6)
 *  out_csv                ＣＳＶ出力処理(A-7)
 *  out_gl_je_wait         未連携テーブル登録処理(A-8)
 *  upd_gl_je_control      管理テーブル登録・更新処理(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ・終了処理(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-08-29    1.0   K.Onotsuka      新規作成
 *  2012-10-03    1.1   K.Onotsuka      結合テスト障害対応[障害No16:項目桁チェック戻り値格納変数の桁数変更]
 *                                                        [障害No19、20:管理テーブル登録条件修正]
 *                                                        [障害No22:抽出項目「資産管理キー在庫管理キー値」の編集内容変更]
 *  2012-12-18    1.2   T.Ishiwata      性能改善対応
 *  2014-12-08    1.3   K.Oomata        【E_本稼動_12291対応】
 *                                       処理対象仕訳データから仕訳カテゴリ「ICS残高移行」を除外。
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
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_target_cnt      NUMBER;                    -- 対象件数（連携分）
  gn_normal_cnt      NUMBER;                    -- 正常件数
  gn_error_cnt       NUMBER;                    -- エラー件数
  gn_warn_cnt        NUMBER;                    -- スキップ件数
  gn_target_wait_cnt NUMBER;                    -- 対象件数（未連携分）
  gn_wait_data_cnt   NUMBER;                    -- 未連携データ件数
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO019A02C'; -- パッケージ名
  --アプリケーション短縮名
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp              CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
  --プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';    -- 電子帳簿データファイル格納パス
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_GL_JOURNAL_I_FILENAME'; -- 電子帳簿仕訳追加ファイル名
  cv_upd_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_GL_JOURNAL_U_FILENAME'; -- 電子帳簿仕訳更新ファイル名
  cv_p_accounts               CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_P_ACCOUNTS';       -- 電子帳簿複数相手先複数勘定時文言
  cv_set_of_bks_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                      -- 会計帳簿ID
--2012/10/03 Add Start
  cv_gl_ctg_inv_cost          CONSTANT VARCHAR2(100) := 'XXCOI1_GL_CATEGORY_INV_COST';           -- 仕訳カテゴリ_在庫原価振替
--2012/10/03 Add End
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
  cv_not_proc_category        CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_NOT_PROC_CATEGORY';  -- XXCFO:電子帳簿仕訳抽出対象外仕訳カテゴリ
-- 2014/12/08 Ver.1.3 Add K.Oomata End
  --メッセージ
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10025';   --取得対象データ無しエラーメッセージ
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001';   --プロファイル名取得エラーメッセージ
  cv_msg_cff_00189            CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189';   --参照タイプ取得エラー
  cv_msg_cfo_00002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00002';   --ファイル名出力メッセージ
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015';   --業務日付取得エラーメッセージ
  cv_msg_cfo_00019            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00019';   --ロックエラーメッセージ
  cv_msg_cfo_00020            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00020';   --更新エラーメッセージ
  cv_msg_cfo_00024            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00024';   --登録エラーメッセージ
  cv_msg_cfo_00025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00025';   --削除エラーメッセージ
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00027';   --ファイル存在エラー
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00029';   --ファイルオープンエラーメッセージ
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00030';   --ファイル書き込み
  cv_msg_cfo_00031            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00031';   --クイックコード取得エラーメッセージ
  cv_msg_cfo_10001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10001';   --対象件数（連携分）メッセージ
  cv_msg_cfo_10002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10002';   --対象件数（未処理連携分）メッセージ
  cv_msg_cfo_10003            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10003';   --未連携件数メッセージ
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10007';   --未連携データ登録メッセージ
  cv_msg_cfo_10005            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10005';   --仕訳未転記メッセージ
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10010';   --未連携データチェックIDエラーメッセージ
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';   --桁数超過スキップメッセージ
  cv_msg_coi_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';   --ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_10017            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10017';   --電子帳簿仕訳パラメータ入力不備メッセージ
  cv_msg_cfo_10014            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10014';   --仕訳処理済データチェックエラーメッセージ
  cv_msg_cfo_10034            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10034';   --相手勘定情報取得なしメッセージ
  --トークンコード
  cv_tkn_prm_name             CONSTANT VARCHAR2(20)  := 'PARAM_NAME';     -- パラメータ名
  cv_tkn_param_val            CONSTANT VARCHAR2(20)  := 'PARAM_VAL';      -- パラメータ値
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';    -- ルックアップタイプ名
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';    -- ルックアップコード名
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';      -- プロファイル名
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';        -- ディレクトリ名
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';      -- ファイル名
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';          -- テーブル名
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';         -- SQLエラーメッセージ
  cv_tkn_get_data             CONSTANT VARCHAR2(20)  := 'GET_DATA';       -- テーブル名
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';       -- エラー情報
  cv_tkn_je_header_id         CONSTANT VARCHAR2(20)  := 'JE_HEADER_ID';   -- 仕訳ヘッダID
  cv_tkn_je_doc_seq_val       CONSTANT VARCHAR2(20)  := 'JE_DOC_SEQ_VAL'; -- 仕訳文書番号
  cv_tkn_doc_data             CONSTANT VARCHAR2(20)  := 'DOC_DATA';       -- データ内容(仕訳ヘッダID)
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20)  := 'DOC_DIST_ID';    -- 仕訳ヘッダID
  cv_tkn_cause                CONSTANT VARCHAR2(20)  := 'CAUSE';          -- 未連携データ登録理由
  cv_tkn_target               CONSTANT VARCHAR2(20)  := 'TARGET';         -- 未連携データ特定キー
  cv_tkn_meaning              CONSTANT VARCHAR2(20)  := 'MEANING';        -- 未連携エラー内容
  cv_tkn_key_item             CONSTANT VARCHAR2(20)  := 'KEY_ITEM';       -- エラー情報
  cv_tkn_key_value            CONSTANT VARCHAR2(20)  := 'KEY_VALUE';      -- エラー情報  
  --メッセージ出力用文字列(トークン)
  cv_msgtkn_cfo_11001         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11001'; -- '仕訳管理
  cv_msgtkn_cfo_11002         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11002'; -- '仕訳未連携
  cv_msgtkn_cfo_11003         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11003'; -- '仕訳ヘッダID
  cv_msgtkn_cfo_11004         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11004'; -- '仕訳明細番号
  cv_msgtkn_cfo_11005         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11005'; -- '相手勘定情報取得エラー
  cv_msgtkn_cfo_11006         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11006'; -- '未転記エラー
  cv_msgtkn_cfo_11007         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11007'; -- '明細チェックエラー
  cv_msgtkn_cfo_11039         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11039'; -- '対象仕訳情報
  cv_msgtkn_cfo_11041         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11041'; -- '仕訳データ
  --参照タイプ
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';     --電子帳簿処理実行日
  cv_lookup_item_chk_glje     CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_GLJE';  --電子帳簿項目チェック（仕訳）
  --ＣＳＶ出力フォーマット
  cv_date_format_ymdhms_deli  CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';     --ＣＳＶ出力フォーマット
  cv_date_format_ymd_deli     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                --ＣＳＶ出力フォーマット
  cv_date_format_ymdhms       CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';          --ＣＳＶ出力フォーマット
  cv_date_format_ymd          CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                  --ＣＳＶ出力フォーマット
  --ＣＳＶ
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- カンマ
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- 文字括り
  --実行モード
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- 定期実行
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- 手動実行
  --追加更新区分
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';                  -- 追加
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';                  -- 更新
  --データタイプ
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';                  -- 連携分
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                  -- 未連携分
  --情報抽出用
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                  -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                  -- 'N'
  cv_actual_flag_a            CONSTANT VARCHAR2(1)   := 'A';                  -- 実績フラグ：'A'(実績)
  cv_errlevel_header          CONSTANT VARCHAR2(10)  := 'HEAD';
  cv_errlevel_line            CONSTANT VARCHAR2(10)  := 'LINE';
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --言語
  cv_ref1_mtl                 CONSTANT VARCHAR2(10)  := 'MTL';    --資産管理キー在庫管理キー値
  cv_ref1_assets              CONSTANT VARCHAR2(10)  := 'Assets'; --資産管理キー在庫管理キー値
--
  cn_max_linesize             CONSTANT BINARY_INTEGER := 32767;
  --固定値
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- スラッシュ
  cv_status_p                 CONSTANT VARCHAR2(1)   := 'P';                  -- ステータス：'P'(未転記)
  --ファイル出力
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
  --項目属性
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2（属性チェックなし）
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  （数値チェック）
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    （日付型チェック）
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   （チェック）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --仕訳
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32764)   INDEX BY PLS_INTEGER;
  gt_data_tab                  g_layout_ttype;              --出力データ情報
  --項目チェック
  TYPE g_item_name_ttype        IS TABLE OF fnd_lookup_values.attribute1%type  
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype         IS TABLE OF fnd_lookup_values.attribute2%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype     IS TABLE OF fnd_lookup_values.attribute3%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype     IS TABLE OF fnd_lookup_values.attribute4%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype        IS TABLE OF fnd_lookup_values.attribute5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype      IS TABLE OF fnd_lookup_values.attribute6%type
                                            INDEX BY PLS_INTEGER;
  --
  gt_item_name                  g_item_name_ttype;          -- 項目名称
  gt_item_len                   g_item_len_ttype;           -- 項目の長さ
  gt_item_decimal               g_item_decimal_ttype;       -- 項目（小数点以下の長さ）
  gt_item_nullflg               g_item_nullflg_ttype;       -- 必須項目フラグ
  gt_item_attr                  g_item_attr_ttype;          -- 項目属性
  gt_item_cutflg                g_item_cutflg_ttype;        -- 切捨てフラグ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_exec_kbn                 VARCHAR2(1);   -- 処理実行区分
  gd_process_date             DATE;          -- 業務日付
  gn_set_of_bks_id            NUMBER;        -- 会計帳簿ID
  gv_ins_upd_kbn              VARCHAR2(1);   -- 追加更新区分
  gv_electric_exec_days       fnd_lookup_values.attribute1%TYPE; -- 電子帳簿処理実行日数
  gv_proc_target_time         fnd_lookup_values.attribute2%TYPE; -- 処理対象時刻
  gt_gl_je_header_id          xxcfo_gl_je_control.gl_je_header_id%TYPE DEFAULT NULL; -- 仕訳ヘッダID(A-6処理内判断用)
  gt_gl_je_header_id_to       xxcfo_gl_je_control.gl_je_header_id%TYPE;              -- 仕訳ヘッダID(出力対象データ抽出条件)
  gt_gl_je_header_id_from     xxcfo_gl_je_control.gl_je_header_id%TYPE DEFAULT NULL; -- 仕訳ヘッダID(出力対象データ抽出条件)
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言
  gv_file_path                all_directories.directory_name%TYPE DEFAULT NULL; --ファイルパス
  gv_dir_path                 all_directories.directory_path%TYPE DEFAULT NULL; --ディレクトリパス
  gv_file_name                VARCHAR2(100) DEFAULT NULL; --電子帳簿仕訳データ追加ファイル
  gv_full_name                VARCHAR2(200) DEFAULT NULL; --電子帳簿販売実績データ追加ファイル
  gv_electrinc_book_start_ymd VARCHAR2(100) DEFAULT NULL; --電子帳簿営業システム稼働開始年月日
  gv_electric_book_p_accounts VARCHAR2(100) DEFAULT NULL; --電子帳簿複数相手先複数勘定時文言
--2012/10/03 Add Start
  gv_gl_ctg_inv_cost          VARCHAR2(100);              --仕訳カテゴリ_在庫原価振替
--2012/10/03 Add End
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
  gv_not_proc_category        VARCHAR2(100);              --XXCFO:電子帳簿仕訳抽出対象外仕訳カテゴリ
-- 2014/12/08 Ver.1.3 Add K.Oomata End
  gv_file_data                VARCHAR2(30000);
  gn_item_cnt                 NUMBER;             --チェック項目件数
  gv_0file_flg                VARCHAR2(1) DEFAULT 'N'; --0Byteファイル上書きフラグ
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --警告フラグ
  gv_wait_ins_flg             VARCHAR2(1) DEFAULT 'N'; --未連携登録済フラグ
  gv_line_skip_flg            VARCHAR2(1) DEFAULT 'N'; --明細スキップフラグ
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
    -- 対象データ取得カーソル(定期実行)
    CURSOR get_gl_je_data_fixed_cur( it_gl_je_header_id_from IN xxcfo_gl_je_control.gl_je_header_id%TYPE
                                    ,it_gl_je_header_id_to   IN xxcfo_gl_je_control.gl_je_header_id%TYPE
                                   )
    IS
      SELECT /*+ LEADING (gjh )
                 USE_NL (gjh gjl gjs gjb gcc gjc gdct)
                 INDEX (gjh GL_JE_HEADERS_U1) 
                 INDEX (gjl GL_JE_LINES_U1)
            */
             gjh.je_header_id                    AS je_header_id           -- 仕訳ヘッダーＩＤ
            ,gjh.period_name                     AS period_name            -- 会計期間
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- 有効日
            ,gjh.je_source                       AS je_source              -- 仕訳ソース
            ,gjs.user_je_source_name             AS user_je_source_name    -- 仕訳ソース名
            ,gjh.je_category                     AS je_category            -- 仕訳カテゴリ
            ,gjc.user_je_category_name           AS user_je_category_name  -- 仕訳カテゴリ名
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- 仕訳文書番号
            ,gjb.name                            AS bat_name               -- 仕訳バッチ名
            ,gjh.name                            AS name                   -- 仕訳名
            ,gjh.description                     AS description            -- 摘要
            ,gjl.je_line_num                     AS je_line_num            -- 仕訳明細番号
            ,gjl.description                     AS je_line_description    -- 仕訳明細摘要
            ,gcc.segment1                        AS aff_company_code       -- ＡＦＦ会社コード
            ,gcc.segment2                        AS aff_department_code    -- ＡＦＦ部門コード
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- 部門名称
            ,gcc.segment3                        AS aff_account_code       -- ＡＦＦ勘定科目コード
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- 勘定科目名称
            ,gcc.segment4                        AS aff_sub_account_code   -- ＡＦＦ補助科目コード
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- 補助科目名称
            ,gcc.segment5                        AS aff_partner_code       -- ＡＦＦ顧客コード
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- 顧客名称
            ,gcc.segment6                        AS aff_business_type_code -- ＡＦＦ企業コード
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- 企業名称
            ,gcc.segment7                        AS aff_project            -- ＡＦＦ予備１
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- 予備１名称
            ,gcc.segment8                        AS aff_future             -- ＡＦＦ予備２
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- 予備２名称
            ,gjl.code_combination_id             AS code_combination_id    -- 勘定科目組合せid
            ,gjl.entered_dr                      AS entered_dr             -- 借方金額
            ,gjl.entered_cr                      AS entered_cr             -- 貸方金額
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- 税区分
            ,gjl.attribute2                      AS attribute2             -- 増減事由
            ,gjl.attribute3                      AS attribute3             -- 伝票番号
            ,gjl.attribute4                      AS attribute4             -- 起票部門
            ,gjl.attribute5                      AS attribute5             -- 伝票入力者
            ,gjl.attribute6                      AS attribute6             -- 修正元伝票番号
            ,NULL                                AS account_code           -- 相手勘定勘定科目コード
            ,NULL                                AS account_name           -- 相手勘定勘定科目名称
            ,NULL                                AS sub_account_code       -- 相手勘定補助科目コード
            ,NULL                                AS sub_account_name       -- 相手勘定補助科目名称
            ,gjl.attribute8                      AS sales_exp_header_id    -- 販売実績ヘッダーID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --在庫原価振替
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- 資産管理キー在庫管理キー値
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- 補助簿文書番号 
            ,gjh.currency_code                   AS currency_code                -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type         -- レートタイプ
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- 換算日
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- 換算レート
            ,gjl.accounted_dr                    AS accounted_dr                 -- 借方機能通貨金額
            ,gjl.accounted_cr                    AS accounted_cr                 -- 貸方機能通貨金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- 連携日時
            ,gjl.status                          AS status                       -- ステータス
            ,'0'                                 AS data_type                    -- データタイプ('0':連携分)
      FROM   gl_je_headers        gjh  -- 仕訳ヘッダ
            ,gl_je_lines          gjl  -- 仕訳明細
            ,gl_je_sources_tl     gjs  -- 仕訳ソース
            ,gl_je_batches        gjb  -- 仕訳バッチ
            ,gl_code_combinations gcc  -- 勘定科目組合せマスタ
            ,gl_je_categories_tl  gjc  -- 仕訳カテゴリテーブル
            ,gl_daily_conversion_types gdct -- GLレートマスタ
      WHERE  gjh.je_header_id          = gjl.je_header_id
        AND  gjh.actual_flag           = cv_actual_flag_a
        AND  gjh.set_of_books_id       = gn_set_of_bks_id -- A-1.会計帳簿ID
        AND  gjl.code_combination_id   = gcc.code_combination_id
        AND  gjh.je_category           = gjc.je_category_name
        AND  gjc.language              = cv_lang
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
        AND  gjc.user_je_category_name <> gv_not_proc_category
-- 2014/12/08 Ver.1.3 Add K.Oomata End
        AND  gjh.je_source             = gjs.je_source_name
        AND  gjs.language              = cv_lang
        AND  gjh.je_batch_id = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND  gjh.je_header_id BETWEEN it_gl_je_header_id_from
                                        AND it_gl_je_header_id_to
      UNION ALL
--2012/12/18 Ver.1.2 Mod Start
--      SELECT gjh.je_header_id                    AS je_header_id           -- 仕訳ヘッダーＩＤ
      SELECT /*+ LEADING(xgjwc gjh) */
             gjh.je_header_id                    AS je_header_id           -- 仕訳ヘッダーＩＤ
--2012/12/18 Ver.1.2 Mod End
            ,gjh.period_name                     AS period_name            -- 会計期間
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- 有効日
            ,gjh.je_source                       AS je_source              -- 仕訳ソース
            ,gjs.user_je_source_name             AS user_je_source_name    -- 仕訳ソース名
            ,gjh.je_category                     AS je_category            -- 仕訳カテゴリ
            ,gjc.user_je_category_name           AS user_je_category_name  -- 仕訳カテゴリ名
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- 仕訳文書番号
            ,gjb.name                            AS bat_name               -- 仕訳バッチ名
            ,gjh.name                            AS name                   -- 仕訳名
            ,gjh.description                     AS description            -- 摘要
            ,gjl.je_line_num                     AS je_line_num            -- 仕訳明細番号
            ,gjl.description                     AS je_line_description    -- 仕訳明細摘要
            ,gcc.segment1                        AS aff_company_code       -- ＡＦＦ会社コード
            ,gcc.segment2                        AS aff_department_code    -- ＡＦＦ部門コード
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- 部門名称
            ,gcc.segment3                        AS aff_account_code       -- ＡＦＦ勘定科目コード
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- 勘定科目名称
            ,gcc.segment4                        AS aff_sub_account_code   -- ＡＦＦ補助科目コード
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- 補助科目名称
            ,gcc.segment5                        AS aff_partner_code       -- ＡＦＦ顧客コード
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- 顧客名称
            ,gcc.segment6                        AS aff_business_type_code -- ＡＦＦ企業コード
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- 企業名称
            ,gcc.segment7                        AS aff_project            -- ＡＦＦ予備１
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- 予備１名称
            ,gcc.segment8                        AS aff_future             -- ＡＦＦ予備２
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- 予備２名称
            ,gjl.code_combination_id             AS code_combination_id    -- 勘定科目組合せid
            ,gjl.entered_dr                      AS entered_dr             -- 借方金額
            ,gjl.entered_cr                      AS entered_cr             -- 貸方金額
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- 税区分
            ,gjl.attribute2                      AS attribute2             -- 増減事由
            ,gjl.attribute3                      AS attribute3             -- 伝票番号
            ,gjl.attribute4                      AS attribute4             -- 起票部門
            ,gjl.attribute5                      AS attribute5             -- 伝票入力者
            ,gjl.attribute6                      AS attribute6             -- 修正元伝票番号
            ,NULL                                AS account_code           -- 相手勘定勘定科目コード
            ,NULL                                AS account_name           -- 相手勘定勘定科目名称
            ,NULL                                AS sub_account_code       -- 相手勘定補助科目コード
            ,NULL                                AS sub_account_name       -- 相手勘定補助科目名称
            ,gjl.attribute8                      AS sales_exp_header_id    -- 販売実績ヘッダーID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --在庫原価振替
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- 資産管理キー在庫管理キー値
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- 補助簿文書番号 
            ,gjh.currency_code                   AS currency_code                -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type         -- レートタイプ
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- 換算日
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- 換算レート
            ,gjl.accounted_dr                    AS accounted_dr                 -- 借方機能通貨金額
            ,gjl.accounted_cr                    AS accounted_cr                 -- 貸方機能通貨金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- 連携日時
            ,gjl.status                          AS status                       -- ステータス
            ,'1'                                 AS data_type                    -- データタイプ('1':未連携)
      FROM   gl_je_headers             gjh   -- 仕訳ヘッダ
            ,gl_je_lines               gjl   -- 仕訳明細
            ,gl_je_batches             gjb   -- 仕訳バッチ
            ,gl_code_combinations      gcc   -- 勘定科目組合せマスタ
            ,gl_je_categories_tl       gjc   -- 仕訳カテゴリテーブル
            ,gl_je_sources_tl          gjs  -- 仕訳ソース
            ,gl_daily_conversion_types gdct  -- GLレートマスタ
            ,xxcfo_gl_je_wait_coop     xgjwc -- 仕訳未連携
      WHERE  gjh.je_header_id             = gjl.je_header_id
        AND  gjh.actual_flag              = cv_actual_flag_a
        AND  gjh.set_of_books_id          = gn_set_of_bks_id -- A-1.会計帳簿ID
        AND  gjl.code_combination_id      = gcc.code_combination_id
        AND  gjh.je_category              = gjc.je_category_name
        AND  gjc.language                 = cv_lang
        AND  gjh.je_source                = gjs.je_source_name
        AND  gjs.language                 = cv_lang
        AND  gjh.je_batch_id              = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND  xgjwc.gl_je_header_id        = gjh.je_header_id
      ORDER BY je_header_id
              ,je_line_num
      ;
    -- レコード型
    get_gl_je_data_fixed_rec   get_gl_je_data_fixed_cur%ROWTYPE;
--
    -- 対象データ取得カーソル(手動実行1) 会計期間指定のみ
    CURSOR get_gl_je_data_manual_cur1( iv_period_name          IN VARCHAR2
                                      ,iv_doc_seq_value_from   IN NUMBER
                                      ,iv_doc_seq_value_to     IN NUMBER
                                    )
    IS
      SELECT /*+ LEADING (gjh )
                 USE_NL (gjh gjl gjs gjb gcc gjc gdct)
                 INDEX (gjl GL_JE_LINES_U1)
            */
             gjh.je_header_id                    AS je_header_id           -- 仕訳ヘッダーＩＤ
            ,gjh.period_name                     AS period_name            -- 会計期間
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- 有効日
            ,gjh.je_source                       AS je_source              -- 仕訳ソース
            ,gjs.user_je_source_name             AS user_je_source_name    -- 仕訳ソース名
            ,gjh.je_category                     AS je_category            -- 仕訳カテゴリ
            ,gjc.user_je_category_name           AS user_je_category_name  -- 仕訳カテゴリ名
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- 仕訳文書番号
            ,gjb.name                            AS bat_name               -- 仕訳バッチ名
            ,gjh.name                            AS name                   -- 仕訳名
            ,gjh.description                     AS description            -- 摘要
            ,gjl.je_line_num                     AS je_line_num            -- 仕訳明細番号
            ,gjl.description                     AS je_line_description    -- 仕訳明細摘要
            ,gcc.segment1                        AS aff_company_code       -- ＡＦＦ会社コード
            ,gcc.segment2                        AS aff_department_code    -- ＡＦＦ部門コード
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- 部門名称
            ,gcc.segment3                        AS aff_account_code       -- ＡＦＦ勘定科目コード
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- 勘定科目名称
            ,gcc.segment4                        AS aff_sub_account_code   -- ＡＦＦ補助科目コード
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- 補助科目名称
            ,gcc.segment5                        AS aff_partner_code       -- ＡＦＦ顧客コード
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- 顧客名称
            ,gcc.segment6                        AS aff_business_type_code -- ＡＦＦ企業コード
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- 企業名称
            ,gcc.segment7                        AS aff_project            -- ＡＦＦ予備１
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- 予備１名称
            ,gcc.segment8                        AS aff_future             -- ＡＦＦ予備２
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- 予備２名称
            ,gjl.code_combination_id             AS code_combination_id    -- 勘定科目組合せid
            ,gjl.entered_dr                      AS entered_dr             -- 借方金額
            ,gjl.entered_cr                      AS entered_cr             -- 貸方金額
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- 税区分
            ,gjl.attribute2                      AS attribute2             -- 増減事由
            ,gjl.attribute3                      AS attribute3             -- 伝票番号
            ,gjl.attribute4                      AS attribute4             -- 起票部門
            ,gjl.attribute5                      AS attribute5             -- 伝票入力者
            ,gjl.attribute6                      AS attribute6             -- 修正元伝票番号
            ,NULL                                AS account_code           -- 相手勘定勘定科目コード
            ,NULL                                AS account_name           -- 相手勘定勘定科目名称
            ,NULL                                AS sub_account_code       -- 相手勘定補助科目コード
            ,NULL                                AS sub_account_name       -- 相手勘定補助科目名称
            ,gjl.attribute8                      AS sales_exp_header_id    -- 販売実績ヘッダーID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --在庫原価振替
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- 資産管理キー在庫管理キー値
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- 補助簿文書番号 
            ,gjh.currency_code                   AS currency_code                -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type         -- レートタイプ
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- 換算日
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- 換算レート
            ,gjl.accounted_dr                    AS accounted_dr                 -- 借方機能通貨金額
            ,gjl.accounted_cr                    AS accounted_cr                 -- 貸方機能通貨金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- 連携日時
            ,gjl.status                          AS status                       -- ステータス
            ,'0'                                 AS data_type                    -- データタイプ('0':連携分)
      FROM   gl_je_headers        gjh  -- 仕訳ヘッダ
            ,gl_je_lines          gjl  -- 仕訳明細
            ,gl_je_sources_tl     gjs  -- 仕訳ソース
            ,gl_je_batches        gjb  -- 仕訳バッチ
            ,gl_code_combinations gcc  -- 勘定科目組合せマスタ
            ,gl_je_categories_tl  gjc  -- 仕訳カテゴリテーブル
            ,gl_daily_conversion_types gdct -- GLレートマスタ
      WHERE  gjh.je_header_id          = gjl.je_header_id
        AND  gjh.actual_flag           = cv_actual_flag_a
        AND  gjh.set_of_books_id       = gn_set_of_bks_id -- A-1.会計帳簿ID
        AND  gjl.code_combination_id   = gcc.code_combination_id
        AND  gjh.je_category           = gjc.je_category_name
        AND  gjc.language              = cv_lang
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
        AND  gjc.user_je_category_name <> gv_not_proc_category
-- 2014/12/08 Ver.1.3 Add K.Oomata End
        AND  gjh.je_source             = gjs.je_source_name
        AND  gjs.language              = cv_lang
        AND  gjh.je_batch_id = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND  gjh.period_name = iv_period_name
      ORDER BY gjh.je_header_id
              ,gjl.je_line_num
      ;
--
    -- 対象データ取得カーソル(手動実行2) 文書番号指定のみ
    CURSOR get_gl_je_data_manual_cur2( iv_period_name          IN VARCHAR2
                                      ,iv_doc_seq_value_from   IN NUMBER
                                      ,iv_doc_seq_value_to     IN NUMBER
                                    )
    IS
      SELECT /*+ LEADING (gjh )
                 USE_NL (gjh gjl gjs gjb gcc gjc gdct)
                 INDEX (gjl GL_JE_LINES_U1)
            */
             gjh.je_header_id                    AS je_header_id           -- 仕訳ヘッダーＩＤ
            ,gjh.period_name                     AS period_name            -- 会計期間
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- 有効日
            ,gjh.je_source                       AS je_source              -- 仕訳ソース
            ,gjs.user_je_source_name             AS user_je_source_name    -- 仕訳ソース名
            ,gjh.je_category                     AS je_category            -- 仕訳カテゴリ
            ,gjc.user_je_category_name           AS user_je_category_name  -- 仕訳カテゴリ名
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- 仕訳文書番号
            ,gjb.name                            AS bat_name               -- 仕訳バッチ名
            ,gjh.name                            AS name                   -- 仕訳名
            ,gjh.description                     AS description            -- 摘要
            ,gjl.je_line_num                     AS je_line_num            -- 仕訳明細番号
            ,gjl.description                     AS je_line_description    -- 仕訳明細摘要
            ,gcc.segment1                        AS aff_company_code       -- ＡＦＦ会社コード
            ,gcc.segment2                        AS aff_department_code    -- ＡＦＦ部門コード
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- 部門名称
            ,gcc.segment3                        AS aff_account_code       -- ＡＦＦ勘定科目コード
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- 勘定科目名称
            ,gcc.segment4                        AS aff_sub_account_code   -- ＡＦＦ補助科目コード
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- 補助科目名称
            ,gcc.segment5                        AS aff_partner_code       -- ＡＦＦ顧客コード
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- 顧客名称
            ,gcc.segment6                        AS aff_business_type_code -- ＡＦＦ企業コード
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- 企業名称
            ,gcc.segment7                        AS aff_project            -- ＡＦＦ予備１
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- 予備１名称
            ,gcc.segment8                        AS aff_future             -- ＡＦＦ予備２
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- 予備２名称
            ,gjl.code_combination_id             AS code_combination_id    -- 勘定科目組合せid
            ,gjl.entered_dr                      AS entered_dr             -- 借方金額
            ,gjl.entered_cr                      AS entered_cr             -- 貸方金額
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- 税区分
            ,gjl.attribute2                      AS attribute2             -- 増減事由
            ,gjl.attribute3                      AS attribute3             -- 伝票番号
            ,gjl.attribute4                      AS attribute4             -- 起票部門
            ,gjl.attribute5                      AS attribute5             -- 伝票入力者
            ,gjl.attribute6                      AS attribute6             -- 修正元伝票番号
            ,NULL                                AS account_code           -- 相手勘定勘定科目コード
            ,NULL                                AS account_name           -- 相手勘定勘定科目名称
            ,NULL                                AS sub_account_code       -- 相手勘定補助科目コード
            ,NULL                                AS sub_account_name       -- 相手勘定補助科目名称
            ,gjl.attribute8                      AS sales_exp_header_id    -- 販売実績ヘッダーID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --在庫原価振替
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- 資産管理キー在庫管理キー値
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- 補助簿文書番号 
            ,gjh.currency_code                   AS currency_code                -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type         -- レートタイプ
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- 換算日
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- 換算レート
            ,gjl.accounted_dr                    AS accounted_dr                 -- 借方機能通貨金額
            ,gjl.accounted_cr                    AS accounted_cr                 -- 貸方機能通貨金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- 連携日時
            ,gjl.status                          AS status                       -- ステータス
            ,'0'                                 AS data_type                    -- データタイプ('0':連携分)
      FROM   gl_je_headers        gjh  -- 仕訳ヘッダ
            ,gl_je_lines          gjl  -- 仕訳明細
            ,gl_je_sources_tl     gjs  -- 仕訳ソース
            ,gl_je_batches        gjb  -- 仕訳バッチ
            ,gl_code_combinations gcc  -- 勘定科目組合せマスタ
            ,gl_je_categories_tl  gjc  -- 仕訳カテゴリテーブル
            ,gl_daily_conversion_types gdct -- GLレートマスタ
      WHERE  gjh.je_header_id          = gjl.je_header_id
        AND  gjh.actual_flag           = cv_actual_flag_a
        AND  gjh.set_of_books_id       = gn_set_of_bks_id -- A-1.会計帳簿ID
        AND  gjl.code_combination_id   = gcc.code_combination_id
        AND  gjh.je_category           = gjc.je_category_name
        AND  gjc.language              = cv_lang
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
        AND  gjc.user_je_category_name <> gv_not_proc_category
-- 2014/12/08 Ver.1.3 Add K.Oomata End
        AND  gjh.je_source             = gjs.je_source_name
        AND  gjs.language              = cv_lang
        AND  gjh.je_batch_id           = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND gjh.doc_sequence_value     >= iv_doc_seq_value_from
        AND gjh.doc_sequence_value     <= iv_doc_seq_value_to
      ORDER BY gjh.je_header_id
              ,gjl.je_line_num
      ;
--
    -- 対象データ取得カーソル(手動実行3) 会計期間、文書番号両方指定
    CURSOR get_gl_je_data_manual_cur3( iv_period_name          IN VARCHAR2
                                      ,iv_doc_seq_value_from   IN NUMBER
                                      ,iv_doc_seq_value_to     IN NUMBER
                                     )
    IS
      SELECT /*+ LEADING (gjh )
                 USE_NL (gjh gjl gjs gjb gcc gjc gdct)
                 INDEX (gjl GL_JE_LINES_U1)
            */
             gjh.je_header_id                    AS je_header_id           -- 仕訳ヘッダーＩＤ
            ,gjh.period_name                     AS period_name            -- 会計期間
            ,TO_CHAR(gjh.default_effective_date
                     ,cv_date_format_ymd)        AS default_effective_date -- 有効日
            ,gjh.je_source                       AS je_source              -- 仕訳ソース
            ,gjs.user_je_source_name             AS user_je_source_name    -- 仕訳ソース名
            ,gjh.je_category                     AS je_category            -- 仕訳カテゴリ
            ,gjc.user_je_category_name           AS user_je_category_name  -- 仕訳カテゴリ名
            ,gjh.doc_sequence_value              AS doc_sequence_value     -- 仕訳文書番号
            ,gjb.name                            AS bat_name               -- 仕訳バッチ名
            ,gjh.name                            AS name                   -- 仕訳名
            ,gjh.description                     AS description            -- 摘要
            ,gjl.je_line_num                     AS je_line_num            -- 仕訳明細番号
            ,gjl.description                     AS je_line_description    -- 仕訳明細摘要
            ,gcc.segment1                        AS aff_company_code       -- ＡＦＦ会社コード
            ,gcc.segment2                        AS aff_department_code    -- ＡＦＦ部門コード
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name    -- 部門名称
            ,gcc.segment3                        AS aff_account_code       -- ＡＦＦ勘定科目コード
            ,(SELECT xav.description
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name       -- 勘定科目名称
            ,gcc.segment4                        AS aff_sub_account_code   -- ＡＦＦ補助科目コード
            ,(SELECT xsav.description
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value
                 AND gcc.segment3 = xsav.PARENT_FLEX_VALUE_LOW
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name   -- 補助科目名称
            ,gcc.segment5                        AS aff_partner_code       -- ＡＦＦ顧客コード
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- 顧客名称
            ,gcc.segment6                        AS aff_business_type_code -- ＡＦＦ企業コード
            ,(SELECT xbtv.description
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- 企業名称
            ,gcc.segment7                        AS aff_project            -- ＡＦＦ予備１
            ,(SELECT xpv.description
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name       -- 予備１名称
            ,gcc.segment8                        AS aff_future             -- ＡＦＦ予備２
            ,(SELECT xfv.description
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name        -- 予備２名称
            ,gjl.code_combination_id             AS code_combination_id    -- 勘定科目組合せid
            ,gjl.entered_dr                      AS entered_dr             -- 借方金額
            ,gjl.entered_cr                      AS entered_cr             -- 貸方金額
            ,NVL(gjl.attribute1,gjl.tax_code)    AS tax_code               -- 税区分
            ,gjl.attribute2                      AS attribute2             -- 増減事由
            ,gjl.attribute3                      AS attribute3             -- 伝票番号
            ,gjl.attribute4                      AS attribute4             -- 起票部門
            ,gjl.attribute5                      AS attribute5             -- 伝票入力者
            ,gjl.attribute6                      AS attribute6             -- 修正元伝票番号
            ,NULL                                AS account_code           -- 相手勘定勘定科目コード
            ,NULL                                AS account_name           -- 相手勘定勘定科目名称
            ,NULL                                AS sub_account_code       -- 相手勘定補助科目コード
            ,NULL                                AS sub_account_name       -- 相手勘定補助科目名称
            ,gjl.attribute8                      AS sales_exp_header_id    -- 販売実績ヘッダーID
--2012/10/03 MOD Start
--            ,DECODE(gjc.user_je_category_name,cv_ref1_mtl,gjl.reference_1,
--                    DECODE(gjh.je_source,cv_ref1_assets,gjl.reference_1,NULL))
            ,(CASE
              WHEN gjc.user_je_category_name = cv_ref1_mtl THEN
                gjl.reference_1
              WHEN gjh.je_source = cv_ref1_assets THEN
                gjl.reference_1
              WHEN gjc.user_je_category_name = gv_gl_ctg_inv_cost THEN --在庫原価振替
                gjl.reference_1
              ELSE NULL
              END)
--2012/10/03 MOD End
                                                 AS reference_1                  -- 資産管理キー在庫管理キー値
            ,gjl.subledger_doc_sequence_value    AS subledger_doc_sequence_value -- 補助簿文書番号 
            ,gjh.currency_code                   AS currency_code                -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type         -- レートタイプ
            ,TO_CHAR(gjh.currency_conversion_date
                     ,cv_date_format_ymd)        AS currency_conversion_date     -- 換算日
            ,gjh.currency_conversion_rate        AS currency_conversion_rate     -- 換算レート
            ,gjl.accounted_dr                    AS accounted_dr                 -- 借方機能通貨金額
            ,gjl.accounted_cr                    AS accounted_cr                 -- 貸方機能通貨金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS cool_date                    -- 連携日時
            ,gjl.status                          AS status                       -- ステータス
            ,'0'                                 AS data_type                    -- データタイプ('0':連携分)
      FROM   gl_je_headers        gjh  -- 仕訳ヘッダ
            ,gl_je_lines          gjl  -- 仕訳明細
            ,gl_je_sources_tl     gjs  -- 仕訳ソース
            ,gl_je_batches        gjb  -- 仕訳バッチ
            ,gl_code_combinations gcc  -- 勘定科目組合せマスタ
            ,gl_je_categories_tl  gjc  -- 仕訳カテゴリテーブル
            ,gl_daily_conversion_types gdct -- GLレートマスタ
      WHERE  gjh.je_header_id          = gjl.je_header_id
        AND  gjh.actual_flag           = cv_actual_flag_a
        AND  gjh.set_of_books_id       = gn_set_of_bks_id -- A-1.会計帳簿ID
        AND  gjl.code_combination_id   = gcc.code_combination_id
        AND  gjh.je_category           = gjc.je_category_name
        AND  gjc.language              = cv_lang
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
        AND  gjc.user_je_category_name <> gv_not_proc_category
-- 2014/12/08 Ver.1.3 Add K.Oomata End
        AND  gjh.je_source             = gjs.je_source_name
        AND  gjs.language              = cv_lang
        AND  gjh.je_batch_id = gjb.je_batch_id
        AND  gjh.currency_conversion_type = gdct.conversion_type (+)
        AND  gjh.period_name = iv_period_name
        AND  gjh.doc_sequence_value       >= iv_doc_seq_value_from
        AND  gjh.doc_sequence_value       <= iv_doc_seq_value_to
      ORDER BY gjh.je_header_id
              ,gjl.je_line_num
      ;
--
  --仕訳未連携データ取得カーソル
  CURSOR  gl_je_wait_cur
  IS
    SELECT xgjwc.gl_je_header_id       -- 仕訳ヘッダーＩＤ
          ,xgjwc.rowid                 -- ROWID
      FROM xxcfo_gl_je_wait_coop xgjwc -- 仕訳未連携
    ;
    -- テーブル型
    TYPE gl_je_wait_ttype IS TABLE OF gl_je_wait_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gl_je_wait_tab gl_je_wait_ttype;
--
  --付加情報取得カーソル(借方用)
  CURSOR aff_data_dr_cur(
    in_je_header_id  IN NUMBER       -- A-4.仕訳ヘッダID
  )
  IS
    SELECT DECODE(sub_v.count
                 ,1
                 ,xav.flex_value
                 ,NULL)                        account_code     --相手先勘定科目コード
          ,DECODE(sub_v.count
                 ,1
                 ,xav.description
                 ,gv_electric_book_p_accounts) account_name     --相手先勘定科目名
          ,DECODE(sub_v.count
                 ,1
                 ,xsav.flex_value
                 ,NULL)                        sub_account_code --相手先補助科目コード
          ,DECODE(sub_v.count
                 ,1
                 ,xsav.description
                 ,gv_electric_book_p_accounts) sub_account_name --相手先補助科目名
      FROM xx03_accounts_v     xav                         --BFA 勘定科目ビュー
          ,xx03_sub_accounts_v xsav                        --BFA 補助科目ビュー
          ,(SELECT COUNT(1)           count
                  ,MAX(gccv.segment3) account_code     --勘定科目コード
                  ,MAX(gccv.segment4) sub_account_code --補助科目コード
              FROM gl_je_lines          gjlv           --仕訳明細
                  ,gl_code_combinations gccv           --勘定科目組合せ
             WHERE gjlv.code_combination_id = gccv.code_combination_id
               AND gjlv.je_header_id        = in_je_header_id
               AND gjlv.accounted_cr IS NULL
           ) sub_v
     WHERE xav.flex_value(+)             = sub_v.account_code
       AND xsav.parent_flex_value_low(+) = sub_v.account_code
       AND xsav.flex_value(+)            = sub_v.sub_account_code
     ;
    -- テーブル型(借方用)
    TYPE aff_data_dr_ttype IS TABLE OF aff_data_dr_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    aff_data_dr_tab aff_data_dr_ttype;
  --
  --付加情報取得カーソル(貸方用)
  CURSOR aff_data_cr_cur(
    in_je_header_id  IN NUMBER       -- A-4.仕訳ヘッダID
  )
  IS
    SELECT DECODE(sub_v.count
                 ,1
                 ,xav.flex_value
                 ,NULL)                        account_code     --相手先勘定科目コード
          ,DECODE(sub_v.count
                 ,1
                 ,xav.description
                 ,gv_electric_book_p_accounts) account_name     --相手先勘定科目名
          ,DECODE(sub_v.count
                 ,1
                 ,xsav.flex_value
                 ,NULL)                        sub_account_code --相手先補助科目コード
          ,DECODE(sub_v.count
                 ,1
                 ,xsav.description
                 ,gv_electric_book_p_accounts) sub_account_name --相手先補助科目名
      FROM xx03_accounts_v     xav                         --BFA 勘定科目ビュー
          ,xx03_sub_accounts_v xsav                        --BFA 補助科目ビュー
          ,(SELECT COUNT(1)           count
                  ,MAX(gccv.segment3) account_code     --勘定科目コード
                  ,MAX(gccv.segment4) sub_account_code --補助科目コード
              FROM gl_je_lines          gjlv           --仕訳明細
                  ,gl_code_combinations gccv           --勘定科目組合せ
             WHERE gjlv.code_combination_id = gccv.code_combination_id
               AND gjlv.je_header_id        = in_je_header_id
               AND gjlv.accounted_dr IS NULL
           ) sub_v
     WHERE xav.flex_value(+)             = sub_v.account_code
       AND xsav.parent_flex_value_low(+) = sub_v.account_code
       AND xsav.flex_value(+)            = sub_v.sub_account_code
     ;
    -- テーブル型(貸方用)
    TYPE aff_data_cr_ttype IS TABLE OF aff_data_cr_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    aff_data_cr_tab aff_data_cr_ttype;
--
  -- ===============================
  -- グローバル例外
  -- ===============================
  global_lock_expt                   EXCEPTION; -- ロック(ビジー)エラー
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn        IN  VARCHAR2, -- 1.追加更新区分
    iv_file_name          IN  VARCHAR2, -- 2.ファイル名
    iv_period_name        IN  VARCHAR2, -- 3.会計期間
    iv_doc_seq_value_from IN  VARCHAR2, -- 4.仕訳文書番号（From）
    iv_doc_seq_value_to   IN  VARCHAR2, -- 5.仕訳文書番号（To）
    iv_exec_kbn           IN  VARCHAR2, -- 6.定期手動区分
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
    lv_profile_name           fnd_profile_options.profile_option_name%TYPE;
    lv_lookup_type            fnd_lookup_values.lookup_type%TYPE;
    lv_lookup_code            fnd_lookup_values.lookup_code%TYPE;
    -- *** ファイル存在チェック用 ***
    lb_exists       BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length  NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
    lv_msg          VARCHAR2(3000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning             meaning    --項目名称
              , flv.attribute1          attribute1 --項目の長さ
              , flv.attribute2          attribute2 --項目の長さ（小数点以下）
              , flv.attribute3          attribute3 --必須フラグ
              , flv.attribute4          attribute4 --属性
              , flv.attribute5          attribute5 --切捨てフラグ
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         =       cv_lookup_item_chk_glje
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ORDER BY  flv.lookup_code
      ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- パラメータ出力
    --==============================================================
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out      -- メッセージ出力
      ,iv_conc_param1  => iv_ins_upd_kbn        -- 追加更新区分
      ,iv_conc_param2  => iv_file_name          -- ファイル名
      ,iv_conc_param3  => iv_period_name        -- 会計期間
      ,iv_conc_param4  => iv_doc_seq_value_from -- 仕訳文書番号（From）
      ,iv_conc_param5  => iv_doc_seq_value_to   -- 仕訳文書番号（To）
      ,iv_conc_param6  => iv_exec_kbn           -- 定期手動区分
      ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log      -- ログ出力
      ,iv_conc_param1  => iv_ins_upd_kbn        -- 追加更新区分
      ,iv_conc_param2  => iv_file_name          -- ファイル名
      ,iv_conc_param3  => iv_period_name        -- 会計期間
      ,iv_conc_param4  => iv_doc_seq_value_from -- 仕訳文書番号（From）
      ,iv_conc_param5  => iv_doc_seq_value_to   -- 仕訳文書番号（To）
      ,iv_conc_param6  => iv_exec_kbn           -- 定期手動区分
      ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    -- 定期手動区分が'1'（手動）の場合、チェックを行う
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      IF ( ( iv_period_name IS NULL )
        AND ( iv_doc_seq_value_from IS NULL )
        AND ( iv_doc_seq_value_to IS NULL ) )
        --①会計期間、	仕訳文書番号(From-To)が空白
      OR ( ( iv_doc_seq_value_from IS NOT NULL )
        AND ( iv_doc_seq_value_to IS NULL ) )
      OR ( ( iv_doc_seq_value_from IS NULL )
        AND ( iv_doc_seq_value_to IS NOT NULL ) )
        --②仕訳文書番号(From-To)どちらかが空白
      THEN
        --チェック①、②のどちらかに合致した場合、エラーとする
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_10017 -- パラメータ入力不備
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==================================
    -- 入力パラメータをグローバル変数に格納
    --==================================
    gv_ins_upd_kbn := iv_ins_upd_kbn; --追加更新区分
    gv_exec_kbn    := iv_exec_kbn;    --定期手動区分
--
    --==================================
    -- 業務日付取得
    --==================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00015 -- 業務日付取得エラー
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- クイックコード
    --==================================
    --電子帳簿処理実行日数情報
    BEGIN
      SELECT    flv.attribute1 -- 電子帳簿処理実行日数
              , flv.attribute2 -- 処理対象時刻
      INTO      gv_electric_exec_days
              , gv_proc_target_time
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         =       cv_lookup_book_date
      AND       flv.lookup_code         =       cv_pkg_name
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00031 -- クイックコード取得エラー
                                                    ,cv_tkn_lookup_type
                                                    ,cv_lookup_book_date
                                                    ,cv_tkn_lookup_code
                                                    ,cv_pkg_name
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END;
--
    --==================================
    -- クイックコード(項目チェック処理用)情報の取得
    --==================================
    OPEN get_chk_item_cur;
    -- データの一括取得
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name
            , gt_item_len
            , gt_item_decimal
            , gt_item_nullflg
            , gt_item_attr
            , gt_item_cutflg;
    -- 対象件数のセット
    gn_item_cnt := gt_item_name.COUNT;
--
    -- カーソルクローズ
    CLOSE get_chk_item_cur;
    --
    IF ( gt_item_name.COUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff   -- 'XXCFF'
                                                    ,cv_msg_cff_00189 -- 参照タイプ取得エラー
                                                    ,cv_tkn_lookup_type
                                                    ,cv_lookup_item_chk_glje
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END IF;
--
    --==================================
    -- プロファイルの取得
    --==================================
    --ファイル格納パス
    gv_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gv_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name
                                                    ,cv_data_filepath
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --会計帳簿ID
    gn_set_of_bks_id  := FND_PROFILE.VALUE( cv_set_of_bks_id );
    --
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name
                                                    ,cv_set_of_bks_id
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --電子帳簿複数相手先複数勘定時文言
    gv_electric_book_p_accounts  := FND_PROFILE.VALUE( cv_p_accounts );
    --
    IF ( gv_electric_book_p_accounts IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name
                                                    ,cv_p_accounts
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --ファイル名
    IF ( iv_file_name IS NOT NULL ) THEN
      gv_file_name  :=  iv_file_name;
    ELSIF ( iv_file_name IS NULL )
    AND ( gv_ins_upd_kbn = cv_ins_upd_0 ) THEN
      --追加ファイル名
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                      ,cv_tkn_prof_name
                                                      ,cv_add_filename
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSIF ( iv_file_name IS NULL )
    AND ( gv_ins_upd_kbn = cv_ins_upd_1 ) THEN
      --更新ファイル名
      gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                      ,cv_tkn_prof_name
                                                      ,cv_upd_filename
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--2012/10/03 Add Start
    --
    --仕訳カテゴリ_在庫原価振替
    gv_gl_ctg_inv_cost  := FND_PROFILE.VALUE( cv_gl_ctg_inv_cost );
    --
    IF ( gv_gl_ctg_inv_cost IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name
                                                    ,cv_gl_ctg_inv_cost
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--2012/10/03 Add End
-- 2014/12/08 Ver.1.3 Add K.Oomata Start
    --
    --XXCFO:電子帳簿仕訳抽出対象外仕訳カテゴリ
    gv_not_proc_category  := FND_PROFILE.VALUE( cv_not_proc_category );
    --
    IF ( gv_not_proc_category IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name
                                                    ,cv_not_proc_category
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2014/12/08 Ver.1.3 Add K.Oomata End
--
    --==================================
    -- ディレクトリパス取得
    --==================================
    BEGIN
      SELECT    ad.directory_path
      INTO      gv_dir_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gv_file_path;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_coi   -- 'XXCOI'
                                                    ,cv_msg_coi_00029 -- ディレクトリパス取得エラー
                                                    ,cv_tkn_dir_tok
                                                    ,gv_file_path
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
    --==================================
    -- IFファイル名出力
    --==================================
    --取得したディレクトリパスの末尾に'/'(スラッシュ)が存在する場合、
    --ディレクトリとファイル名の間に'/'連結は行わずにファイル名を出力する
    IF  SUBSTRB(gv_dir_path, -1, 1) = cv_slash    THEN
      gv_full_name :=  gv_dir_path || gv_file_name;
    ELSE
      gv_full_name :=  gv_dir_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_msg_kbn_cfo
              , iv_name         => cv_msg_cfo_00002
              , iv_token_name1  => cv_tkn_file_name
              , iv_token_value1 => gv_full_name
              );
    -- ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- 同一ファイル存在チェック
    --==================================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR( 
        location     =>  gv_file_path
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- 同一ファイルが存在した場合はエラー
    IF( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00027 -- ファイルが存在している
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_chk_item_cur%ISOPEN THEN
        CLOSE get_chk_item_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_je_wait
   * Description      : 未連携データ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_gl_je_wait(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_je_wait'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- 仕訳未連携データ取得
    --==============================================================
    --カーソルオープン
    OPEN gl_je_wait_cur;
    FETCH gl_je_wait_cur BULK COLLECT INTO gl_je_wait_tab;
    --カーソルクローズ
    CLOSE gl_je_wait_cur;
    --
--
  EXCEPTION
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
      -- カーソルクローズ
      IF gl_je_wait_cur%ISOPEN THEN
        CLOSE gl_je_wait_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_gl_je_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_je_control
   * Description      : 管理テーブルデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_gl_je_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_je_control'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 仕訳管理データカーソル(未処理仕訳)
    CURSOR gl_je_control_to_cur
    IS
      SELECT xgjc.gl_je_header_id     -- 仕訳ヘッダID
      FROM   xxcfo_gl_je_control xgjc -- 仕訳管理
      WHERE  xgjc.process_flag = cv_flag_n
      ORDER BY xgjc.gl_je_header_id DESC
              ,xgjc.creation_date   DESC
      ;
--
    -- 仕訳管理データカーソル(未処理仕訳)_ロック用
    CURSOR gl_je_control_to_lock_cur
    IS
      SELECT xgjc.gl_je_header_id     -- 仕訳ヘッダID
      FROM   xxcfo_gl_je_control xgjc -- 仕訳管理
      WHERE  xgjc.process_flag = cv_flag_n
      ORDER BY xgjc.gl_je_header_id DESC
              ,xgjc.creation_date   DESC
      FOR UPDATE NOWAIT
      ;
--
    -- レコード型
    TYPE gl_je_control_rec IS RECORD(
      gl_je_header_id  xxcfo_gl_je_control.gl_je_header_id%TYPE
    );
    -- テーブル型
    TYPE gl_je_control_ttype IS TABLE OF gl_je_control_rec INDEX BY BINARY_INTEGER;
    gl_je_control_tab  gl_je_control_ttype;
--
    -- 仕訳管理データカーソル(処理済仕訳)用
    CURSOR gl_je_control_from_cur
    IS
      SELECT MAX(xgjc.gl_je_header_id) gl_je_header_id -- 仕訳ヘッダID
      FROM   xxcfo_gl_je_control xgjc  -- 仕訳管理
      WHERE  xgjc.process_flag = cv_flag_y
      ;
    -- テーブル型
    TYPE gl_je_control_from_ttype IS TABLE OF gl_je_control_from_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gl_je_control_from_tab gl_je_control_from_ttype;
--
    -- ===============================
    -- ローカル定義例外
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
    --==============================================================
    --未処理仕訳ヘッダID取得
    --==============================================================
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --定期実行の場合、ロック用カーソルオープン
      OPEN gl_je_control_to_lock_cur;
      FETCH gl_je_control_to_lock_cur BULK COLLECT INTO gl_je_control_tab;
      --カーソルクローズ
      CLOSE gl_je_control_to_lock_cur;
    ELSE
      --手動実行の場合、ロック無しカーソルオープン
      OPEN gl_je_control_to_cur;
      FETCH gl_je_control_to_cur BULK COLLECT INTO gl_je_control_tab;
      --カーソルクローズ
      CLOSE gl_je_control_to_cur;
    END IF;
    --
    IF ( gl_je_control_tab.COUNT = 0 ) THEN
      -- 取得対象データ無し
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- 取得対象データ無しメッセージ
                                                     ,cv_tkn_get_data    -- トークン'GET_DATA'
                                                     ,cv_msgtkn_cfo_11001 --仕訳管理
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    IF ( gl_je_control_tab.COUNT < gv_electric_exec_days ) THEN
      --取得した管理データ件数より、電子帳簿処理実行日数が多い場合、仕訳ヘッダID(To)にNULLを設定する
      gt_gl_je_header_id_to := NULL;
    ELSE
      --電子帳簿処理実行日数分遡った管理データのヘッダIDを取得
      gt_gl_je_header_id_to := gl_je_control_tab( gv_electric_exec_days ).gl_je_header_id;
    END IF;
--
    --==============================================================
    --処理済最大仕訳ヘッダID取得(From)
    --==============================================================
    -- 仕訳管理データカーソル(最新の処理済仕訳)
    OPEN gl_je_control_from_cur;
    FETCH gl_je_control_from_cur BULK COLLECT INTO gl_je_control_from_tab;
    --カーソルクローズ
    CLOSE gl_je_control_from_cur;
    --
    IF ( gl_je_control_from_tab.COUNT = 0 )
    OR ( gl_je_control_from_tab(1).gl_je_header_id IS NULL ) THEN
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- 取得対象データ無しメッセージ
                                                     ,cv_tkn_get_data    -- トークン'GET_DATA'
                                                     ,cv_msgtkn_cfo_11001 --仕訳管理
                                                    )
                            ,1
                            ,5000);
      RAISE global_process_expt;
    END IF;
    --
    gt_gl_je_header_id_from := gl_je_control_from_tab(1).gl_je_header_id + 1;
--
    --==============================================================
    --ファイルオープン
    --==============================================================
    BEGIN
      gv_file_hand := UTL_FILE.FOPEN( 
                        location     => gv_file_path
                       ,filename     => gv_file_name
                       ,open_mode    => cv_open_mode_w
                                   );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00029 -- ファイルオープンエラー
                                                     )
                             ,1
                             ,5000);
        ov_errmsg  := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                    ,cv_msg_cfo_00019      -- テーブルロックエラー
                                                    ,cv_tkn_table          -- トークン'TABLE'
                                                    ,cv_msgtkn_cfo_11001  -- 仕訳管理
                                                   )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF gl_je_control_to_lock_cur%ISOPEN THEN
        CLOSE gl_je_control_to_lock_cur;
      END IF;
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
      -- カーソルクローズ
      IF gl_je_control_to_lock_cur%ISOPEN THEN
        CLOSE gl_je_control_to_lock_cur;
      END IF;
      IF gl_je_control_to_cur%ISOPEN THEN
        CLOSE gl_je_control_to_cur;
      END IF;
      IF gl_je_control_from_cur%ISOPEN THEN
        CLOSE gl_je_control_from_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_gl_je_control;
--
  /**********************************************************************************
   * Procedure Name   : out_gl_je_wait
   * Description      : 未連携テーブル登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE out_gl_je_wait(
    iv_cause        IN VARCHAR2,    -- 1.未連携データ登録理由
    iv_meaning      IN VARCHAR2,    -- 2.エラー内容
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_gl_je_wait'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_ctl_max_gl_je_header_id NUMBER; --最大仕訳ヘッダID(仕訳管理)
    ln_hd_max_gl_je_header_id  NUMBER; --最大仕訳ヘッダID(仕訳ヘッダ)
--
    -- ===============================
    -- ローカル・カーソル
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
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --定期実行の場合のみ、以下の処理を行う
      --==============================================================
      --仕訳未連携テーブル登録
      --==============================================================
      BEGIN
        INSERT INTO xxcfo_gl_je_wait_coop(
           gl_je_header_id        -- 仕訳ヘッダID
          ,created_by             -- 作成者
          ,creation_date          -- 作成日
          ,last_updated_by        -- 最終更新者
          ,last_update_date       -- 最終更新日
          ,last_update_login      -- 最終更新ログイン
          ,request_id             -- 要求ID
          ,program_application_id -- コンカレント・プログラム・アプリケーションID
          ,program_id             -- コンカレント・プログラムID
          ,program_update_date    -- プログラム更新日
          )
        VALUES (
           TO_NUMBER(gt_data_tab(1))
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        );
        --未連携登録件数カウント
        gn_wait_data_cnt := gn_wait_data_cnt + 1;
        --
        --==============================================================
        --メッセージ出力
        --==============================================================
        lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                       ,cv_msg_cfo_10007 -- 未連携データ登録
                                                       ,cv_tkn_cause     -- 'CAUSE'
                                                       ,iv_cause         -- トークン値
                                                       ,cv_tkn_target    -- 'TARGET'
                                                       ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                                 ,cv_msgtkn_cfo_11003)
                                                         || cv_msg_part || gt_data_tab(1)  --仕訳ヘッダID
                                                       ,cv_tkn_meaning   -- 'MEANING'
                                                       ,iv_meaning       -- トークン値
                                                      )
                              ,1
                              ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00024   -- データ登録エラー
                                                       ,cv_tkn_table       -- トークン'TABLE'
                                                       ,cv_msgtkn_cfo_11002 -- 仕訳未連携
                                                       ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                                       ,SQLERRM            -- SQLエラーメッセージ
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
    ELSE
      --手動実行の場合、メッセージのみ出力
      --==============================================================
      --メッセージ出力
      --==============================================================
      IF ( iv_cause = cv_msgtkn_cfo_11005 ) THEN
        --相手勘定情報未取得の場合
        lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                       ,cv_msg_cfo_10034 -- 相手勘定情報未取得
                                                       ,cv_tkn_key_item       -- トークン'KEY_ITEM'
                                                       ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                                 ,cv_msgtkn_cfo_11003) --仕訳ヘッダID
                                                       ,cv_tkn_key_value      -- トークン'KEY_VALUE'
                                                       ,gt_data_tab(1)  --仕訳ヘッダID
                                                      )
                              ,1
                              ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      ELSIF ( iv_cause = cv_msgtkn_cfo_11006 ) THEN
        --未転記エラーの場合
        lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                       ,cv_msg_cfo_10005 -- 仕訳未転記
                                                       ,cv_tkn_key_item       -- トークン'KEY_ITEM'
                                                       ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                                 ,cv_msgtkn_cfo_11003) --仕訳ヘッダID
                                                       ,cv_tkn_key_value      -- トークン'KEY_VALUE'
                                                       ,gt_data_tab(1)  --仕訳ヘッダID
                                                      )
                              ,1
                              ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
--
    END IF;
--
    --ステータスを警告に設定
    ov_retcode := cv_status_warn;
    --警告フラグを'Y'に設定する
    gv_warning_flg := cv_flag_y;
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
  END out_gl_je_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_flex_information
   * Description      : 付加情報取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_flex_information(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_flex_information'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --相手勘定情報の取得
    --==============================================================
    --カーソルオープン(借方用)
    OPEN aff_data_dr_cur(
            gt_data_tab(1)  --仕訳ヘッダID
           );
    FETCH aff_data_dr_cur BULK COLLECT INTO aff_data_dr_tab;
    --カーソルクローズ
    CLOSE aff_data_dr_cur;
    --
    --カーソルオープン(貸方用)
    OPEN aff_data_cr_cur(
            gt_data_tab(1)  --仕訳ヘッダID
           );
    FETCH aff_data_cr_cur BULK COLLECT INTO aff_data_cr_tab;
    --カーソルクローズ
    CLOSE aff_data_cr_cur;
--
    IF ( aff_data_dr_tab.COUNT = 0 )
    OR ( aff_data_cr_tab.COUNT = 0 ) THEN
      --0件の場合且つ、初回行読込または、ヘッダID切替時のみ登録を行う
      --==============================================================
      --未連携テーブル登録処理(A-8)
      --==============================================================
      out_gl_je_wait(
        iv_cause                    =>        cv_msgtkn_cfo_11005  -- '相手勘定情報取得エラー'
      , iv_meaning                  =>        NULL                 -- A-6のユーザーエラーメッセージ
      , ov_errbuf                   =>        lv_errbuf     -- エラーメッセージ
      , ov_retcode                  =>        lv_retcode    -- リターンコード
      , ov_errmsg                   =>        lv_errmsg     -- ユーザー・エラーメッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        --処理終了時に、作成したファイルを0Byteにする
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      ELSE
        --未連携登録済みフラグをYにする
        gv_wait_ins_flg := cv_flag_y;
      END IF;
    END IF;
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
      --カーソルクローズ
      IF aff_data_dr_cur%ISOPEN THEN
        CLOSE aff_data_dr_cur;
      END IF;
      --カーソルクローズ
      IF aff_data_cr_cur%ISOPEN THEN
        CLOSE aff_data_cr_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_flex_information;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-6)
   ***********************************************************************************/
  PROCEDURE chk_item(
    ov_errbuf             OUT VARCHAR2,   --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT VARCHAR2,   --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT VARCHAR2,   --   ユーザー・エラー・メッセージ        --# 固定 #
    ov_errlevel           OUT VARCHAR2,   --   エラーレベル
    ov_msgcode            OUT VARCHAR2)   --   メッセージコード
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル定義例外
    -- ===============================
    warn_expt        EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    ov_msgcode := NULL;
--
--###########################  固定部 END   ############################
--
    IF ( gt_gl_je_header_id IS NULL )
    OR ( gt_gl_je_header_id <> gt_data_tab(1) ) THEN
      --初回読込または、前回読込時のヘッダIDと現読込行のヘッダIDが異なる場合
      --未連携登録済フラグを初期化
      gv_wait_ins_flg := cv_flag_n;
      --==============================================================
      --付加情報取得処理(A-5)
      --==============================================================
      get_flex_information(
        ov_errbuf                     =>        lv_errbuf   -- エラー・メッセージ
       ,ov_retcode                    =>        lv_retcode  -- リターン・コード
       ,ov_errmsg                     =>        lv_errmsg); -- ユーザー・エラー・メッセージ
      IF ( lv_retcode <> cv_status_normal ) THEN
        --処理終了時に、作成したファイルを0Byteにする
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      END IF;
      --
      --以下のヘッダ単位のチェックを行う
      IF ( gv_exec_kbn = cv_exec_manual ) THEN
        --明細スキップフラグを初期化
        gv_line_skip_flg := cv_flag_n;
        IF ( gv_ins_upd_kbn = cv_ins_upd_1 ) THEN
          --手動実行且つ、更新の場合
          --==============================================================
          --処理済チェック
          --==============================================================
          IF ( gt_gl_je_header_id_from <= gt_data_tab(1) ) THEN
            --未処理仕訳を更新処理の対象としている為、エラーとする
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                    cv_msg_kbn_cfo        -- XXCFO
                                   ,cv_msg_cfo_10014      -- 仕訳処理済データチェックエラー
                                   ,cv_tkn_je_header_id   -- トークン'JE_HEADER_ID'
                                   ,gt_data_tab(1)         -- 仕訳ヘッダID
                                   ,cv_tkn_je_doc_seq_val -- トークン'JE_DOC_SEQ_VAL'
                                   ,gt_data_tab(8)         -- 仕訳文書番号
                                   )
                                 ,1
                                 ,5000);
            lv_errbuf := lv_errmsg;
            ov_errlevel := cv_errlevel_header;
            RAISE global_process_expt;
          END IF;
        END IF;
        --手動実行の場合
        --==============================================================
        -- 未連携データ存在チェック(ヘッダ単位)
        --==============================================================
        <<gl_je_wait_chk_loop>>
        FOR i IN 1 .. gl_je_wait_tab.COUNT LOOP
          IF gl_je_wait_tab( i ).gl_je_header_id = gt_data_tab(1) THEN  --仕訳ヘッダID
            --対象仕訳が未連携の場合、警告メッセージを出力
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                    cv_msg_kbn_cfo        -- XXCFO
                                   ,cv_msg_cfo_10010      -- 未連携データチェックIDエラー
                                   ,cv_tkn_doc_data       -- トークン'DOC_DATA'
                                   ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                             ,cv_msgtkn_cfo_11003)   -- '仕訳ヘッダID'
                                   ,cv_tkn_doc_dist_id    -- トークン'DOC_DIST_ID'
                                   ,gt_data_tab(1)         -- 仕訳ヘッダID
                                   )
                                 ,1
                                 ,5000);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            RAISE warn_expt;
          END IF;
        END LOOP;
      END IF;
      --
      --==============================================================
      -- 未転記チェック
      --==============================================================
      IF ( gt_data_tab(52) <> cv_status_p ) THEN
      --未転記(ステータス<>'P')の場合、以下の処理を行う
        --==============================================================
        --未連携テーブル登録処理(A-8)
        --==============================================================
        out_gl_je_wait(
          iv_cause                    =>        cv_msgtkn_cfo_11006   -- '未転記エラー'
        , iv_meaning                  =>        NULL                  -- A-6のユーザーエラーメッセージ
        , ov_errbuf                   =>        lv_errbuf     -- エラーメッセージ
        , ov_retcode                  =>        lv_retcode    -- リターンコード
        , ov_errmsg                   =>        lv_errmsg     -- ユーザー・エラーメッセージ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          --処理終了時に、作成したファイルを0Byteにする
          gv_0file_flg := cv_flag_y;
          RAISE global_process_expt;
        ELSE
          gv_wait_ins_flg := cv_flag_y; --未連携登録済
        END IF;
      END IF;
      --
    END IF;
    --
    IF ( gv_wait_ins_flg = cv_flag_n ) THEN
      --未連携登録がされていない(相手勘定取得済)の場合、以下を行う
      --==============================================================
      -- 取得した相手勘定情報をA-4取得データの該当項目に設定する
      --==============================================================
      IF ( gt_data_tab(30) IS NULL ) THEN
        --借方金額が空白(自身が貸方)の場合、相手勘定の借方を設定
        gt_data_tab(38) := aff_data_dr_tab(1).account_code;     -- 相手勘定勘定科目コード
        gt_data_tab(39) := aff_data_dr_tab(1).account_name;     -- 相手勘定勘定科目名称
        gt_data_tab(40) := aff_data_dr_tab(1).sub_account_code; -- 相手勘定補助科目コード
        gt_data_tab(41) := aff_data_dr_tab(1).sub_account_name; -- 相手勘定補助科目名称
      ELSIF ( gt_data_tab(31) IS NULL ) THEN
        --貸方金額が空白(自身が借方)の場合、相手勘定の貸方を設定
        gt_data_tab(38) := aff_data_cr_tab(1).account_code;     -- 相手勘定勘定科目コード
        gt_data_tab(39) := aff_data_cr_tab(1).account_name;     -- 相手勘定勘定科目名称
        gt_data_tab(40) := aff_data_cr_tab(1).sub_account_code; -- 相手勘定補助科目コード
        gt_data_tab(41) := aff_data_cr_tab(1).sub_account_name; -- 相手勘定補助科目名称
      END IF;
    END IF;
--
    IF ( gt_data_tab(52) = cv_status_p ) THEN
    --転記済みの場合、桁チェックを行う
      --==============================================================
      -- 項目桁チェック
      --==============================================================
      FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
        xxcfo_common_pkg2.chk_electric_book_item (
            iv_item_name                  =>        gt_item_name(ln_cnt)              --項目名称
          , iv_item_value                 =>        gt_data_tab(ln_cnt)                --変更前の値
          , in_item_len                   =>        gt_item_len(ln_cnt)               --項目の長さ
          , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --項目の長さ(小数点以下)
          , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --必須フラグ
          , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --項目属性
          , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --切捨てフラグ
          , ov_item_value                 =>        gt_data_tab(ln_cnt)                --項目の値
          , ov_errbuf                     =>        lv_errbuf                         --エラーメッセージ
          , ov_retcode                    =>        lv_retcode                        --リターンコード
          , ov_errmsg                     =>        lv_errmsg                         --ユーザー・エラーメッセージ
          );
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode          := lv_retcode;
          ov_errlevel         := cv_errlevel_line; --'LINE'
          ov_msgcode          := lv_errbuf;        --戻りメッセージコード
          ov_errmsg           := lv_errmsg;        --戻りメッセージ
          EXIT; --LOOPを抜ける
        ELSIF ( lv_retcode = cv_status_error ) THEN
          ov_errmsg   := lv_errmsg;
          ov_errlevel := cv_errlevel_line; --'LINE'
          RAISE global_api_others_expt;
        END IF;
        --
        IF ( ln_cnt = gt_item_name.COUNT ) THEN
          --全項目が正常値の場合
          ov_errlevel := cv_errlevel_line; --'LINE'
        END IF;
      END LOOP;
    END IF;
--
  EXCEPTION
--
    -- *** 未連携データ存在警告ハンドラ ***
    WHEN warn_expt THEN
      gv_line_skip_flg := cv_flag_y;
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  := cv_status_warn;      --警告
      ov_errlevel := cv_errlevel_header;  --エラーレベル
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
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : ＣＳＶ出力処理(A-7)
   ***********************************************************************************/
  PROCEDURE out_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_delimit                VARCHAR2(1);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
--
    --データ編集
    gv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    FOR ln_cnt  IN gt_item_name.FIRST..(gt_item_name.COUNT )  LOOP 
      IF  gt_item_attr(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) THEN
        --VARCHAR2,CHAR2
        gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot ||
                          REPLACE(REPLACE(REPLACE(gt_data_tab(ln_cnt),CHR(10),' '), '"', ' '), ',', ' ') || cv_quot;
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_num ) THEN
        --NUMBER
        gv_file_data  :=  gv_file_data || lv_delimit  || gt_data_tab(ln_cnt);
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_dat ) THEN
        --DATE
        gv_file_data  :=  gv_file_data || lv_delimit || gt_data_tab(ln_cnt);
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP;
    --連携日時
    gv_file_data  :=  gv_file_data || lv_delimit || gt_data_tab(51);
    --
    -- ====================================================
    -- ファイル書き込み
    -- ====================================================
    BEGIN
    UTL_FILE.PUT_LINE(gv_file_hand
                     ,gv_file_data
                     );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfo
                                ,cv_msg_cfo_00030)
                              ,1
                              ,5000
                              );
        --
        ov_errmsg  := lv_errmsg;
      RAISE  global_api_others_expt;
    END;
    --成功件数カウント
    gn_normal_cnt := gn_normal_cnt + 1;
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
  END out_csv;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_je
   * Description      : 対象データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_gl_je(
    iv_period_name          IN VARCHAR2, -- 1.会計期間
    iv_doc_seq_value_from   IN VARCHAR2, -- 2.仕訳文書番号（From）
    iv_doc_seq_value_to     IN VARCHAR2, -- 3.仕訳文書番号（To）
    it_gl_je_header_id_from IN xxcfo_gl_je_control.gl_je_header_id%TYPE, -- 4.仕訳ヘッダID(From)
    it_gl_je_header_id_to   IN xxcfo_gl_je_control.gl_je_header_id%TYPE, -- 5.仕訳ヘッダID(To)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_je'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_errlevel               VARCHAR2(10) DEFAULT NULL;
    lv_msgcode                VARCHAR2(5000); -- A-6の戻りメッセージコード(型桁チェック)
    lv_tkn_name1              VARCHAR2(50);  -- トークン名１
    lv_tkn_val1               VARCHAR2(50);  -- トークン値１
    lv_tkn_name2              VARCHAR2(50);  -- トークン名２
    lv_tkn_val2               VARCHAR2(50);  -- トークン値２
    lv_tkn_name3              VARCHAR2(50);  -- トークン名３
    lv_tkn_val3               VARCHAR2(50);  -- トークン値３
    lv_line_chk_skip_flg      VARCHAR2(1) DEFAULT 'N'; --明細チェックスキップフラグ
--
    -- ===============================
    -- ローカル・カーソル
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
    --==============================================================
    --対象データ取得
    --==============================================================
    --==============================================================
    -- 1 手動実行の場合
    --==============================================================
    IF  gv_exec_kbn          =   cv_exec_manual   THEN
      -- 会計期間指定
      IF (  iv_period_name        IS NOT NULL 
        AND iv_doc_seq_value_from IS NULL     ) THEN
        --カーソルオープン
        OPEN get_gl_je_data_manual_cur1( iv_period_name
                                       ,TO_NUMBER( iv_doc_seq_value_from )
                                       ,TO_NUMBER( iv_doc_seq_value_to )
                                        );
        <<main_loop>>
        LOOP
        FETCH get_gl_je_data_manual_cur1 INTO
              gt_data_tab(1)  -- 仕訳ヘッダーＩＤ
            , gt_data_tab(2)  -- 会計期間
            , gt_data_tab(3)  -- 有効日
            , gt_data_tab(4)  -- 仕訳ソース
            , gt_data_tab(5)  -- 仕訳ソース名
            , gt_data_tab(6)  -- 仕訳カテゴリ
            , gt_data_tab(7)  -- 仕訳カテゴリ名
            , gt_data_tab(8)  -- 仕訳文書番号
            , gt_data_tab(9)  -- 仕訳バッチ名
            , gt_data_tab(10) -- 仕訳名
            , gt_data_tab(11) -- 摘要
            , gt_data_tab(12) -- 仕訳明細番号
            , gt_data_tab(13) -- 仕訳明細摘要
            , gt_data_tab(14) -- ＡＦＦ会社コード
            , gt_data_tab(15) -- ＡＦＦ部門コード
            , gt_data_tab(16) -- 部門名称 
            , gt_data_tab(17) -- ＡＦＦ勘定科目コード
            , gt_data_tab(18) -- 勘定科目名称 
            , gt_data_tab(19) -- ＡＦＦ補助科目コード
            , gt_data_tab(20) -- 補助科目名称
            , gt_data_tab(21) -- ＡＦＦ顧客コード
            , gt_data_tab(22) -- 顧客名称
            , gt_data_tab(23) -- ＡＦＦ企業コード
            , gt_data_tab(24) -- 企業名称
            , gt_data_tab(25) -- ＡＦＦ予備１
            , gt_data_tab(26) -- 予備１名称
            , gt_data_tab(27) -- ＡＦＦ予備２
            , gt_data_tab(28) -- 予備２名称
            , gt_data_tab(29) -- 勘定科目組合せid
            , gt_data_tab(30) -- 借方金額
            , gt_data_tab(31) -- 貸方金額
            , gt_data_tab(32) -- 税区分
            , gt_data_tab(33) -- 増減事由
            , gt_data_tab(34) -- 伝票番号
            , gt_data_tab(35) -- 起票部門
            , gt_data_tab(36) -- 伝票入力者
            , gt_data_tab(37) -- 修正元伝票番号
            , gt_data_tab(38) -- 相手勘定勘定科目コード
            , gt_data_tab(39) -- 相手勘定勘定科目名称
            , gt_data_tab(40) -- 相手勘定補助科目コード
            , gt_data_tab(41) -- 相手勘定補助科目名称
            , gt_data_tab(42) -- 販売実績ヘッダーID
            , gt_data_tab(43) -- 資産管理キー在庫管理キー値 
            , gt_data_tab(44) -- 補助簿文書番号 
            , gt_data_tab(45) -- 通貨
            , gt_data_tab(46) -- レートタイプ
            , gt_data_tab(47) -- 換算日
            , gt_data_tab(48) -- 換算レート
            , gt_data_tab(49) -- 借方機能通貨金額
            , gt_data_tab(50) -- 貸方機能通貨金額
            , gt_data_tab(51) -- 連携日時
            , gt_data_tab(52) -- ステータス
            , gt_data_tab(53) -- データタイプ
            ;
          EXIT WHEN get_gl_je_data_manual_cur1%NOTFOUND;
--
          --==============================================================
          --項目チェック処理(A-6)
          --==============================================================
          chk_item(
            ov_errbuf                     =>        lv_errbuf    -- エラー・メッセージ
           ,ov_retcode                    =>        lv_retcode   -- リターン・コード
           ,ov_errmsg                     =>        lv_errmsg    -- ユーザー・エラー・メッセージ
           ,ov_errlevel                   =>        lv_errlevel  -- エラーレベル(HEAD,LINE)
           ,ov_msgcode                    =>        lv_msgcode); -- メッセージコード
          IF ( lv_errlevel = cv_errlevel_line ) 
          AND ( gv_line_skip_flg = cv_flag_n ) THEN
            IF ( lv_retcode = cv_status_normal ) THEN
              -- ヘッダ単位、明細単位のチェックともに正常の場合、CSV出力を行う
              --==============================================================
              -- CSV出力処理(A-7)
              --==============================================================
              out_csv (
                ov_errbuf                   =>        lv_errbuf
               ,ov_retcode                  =>        lv_retcode
               ,ov_errmsg                   =>        lv_errmsg);
              IF ( lv_retcode = cv_status_error ) THEN
                --処理終了時に、作成したファイルを0Byteにする
                gv_0file_flg := cv_flag_y;
                RAISE global_process_expt;
              END IF;
            ELSIF ( lv_retcode = cv_status_error )
              OR ( lv_retcode = cv_status_warn ) THEN
              --明細単位のチェックがエラーまたは警告の場合エラー終了
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                        ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                        ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                  ,cv_msgtkn_cfo_11003)
                                          || cv_msg_part || gt_data_tab(1) || ' '-- 仕訳ヘッダID
                                          || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                      ,cv_msgtkn_cfo_11004)
                                          || cv_msg_part || gt_data_tab(12)         -- 仕訳明細番号
                                        )
                                      ,1
                                      ,5000);
              ELSE
                lv_errmsg := lv_errmsg || ' ' 
                             || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                         ,cv_msgtkn_cfo_11003)
                             || cv_msg_part || gt_data_tab(1);-- 仕訳ヘッダID
              END IF;
              lv_errbuf := lv_errmsg;
              --処理終了時に、作成したファイルを0Byteにする
              gv_0file_flg := cv_flag_y;
              --処理を中断
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_errlevel = cv_errlevel_header ) THEN
            IF ( lv_retcode = cv_status_warn ) THEN
              --ヘッダ単位で警告の場合、警告フラグを'Y'にする
              gv_warning_flg := cv_flag_y;
              --明細スキップフラグを'Y'にする
              gv_line_skip_flg := cv_flag_y;
            ELSIF( lv_retcode = cv_status_error ) THEN
              --ヘッダ単位でエラーの場合、処理を終了する
              --処理終了時に、作成したファイルを0Byteにする
              gv_0file_flg := cv_flag_y;
              RAISE global_process_expt;
            END IF;
          END IF;
--
          IF ( gt_data_tab(53) = cv_data_type_0 ) THEN
            --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
            gn_target_cnt      := gn_target_cnt + 1;
          ELSE
            --データタイプが1(未連携分)の場合、対象件数（未連携分）に1カウント
            gn_target_wait_cnt := gn_target_wait_cnt + 1;
          END IF;
          --
          --行単位の処理終了時に、現読込行のヘッダIDを変数に格納する(ヘッダと明細の判断用)
          gt_gl_je_header_id := gt_data_tab(1);
        END LOOP main_loop;
        CLOSE get_gl_je_data_manual_cur1;
--
      -- 仕訳文書番号指定
      ELSIF (  iv_period_name     IS NULL 
        AND iv_doc_seq_value_from IS NOT NULL ) THEN
        OPEN get_gl_je_data_manual_cur2( iv_period_name
                                       ,TO_NUMBER( iv_doc_seq_value_from )
                                       ,TO_NUMBER( iv_doc_seq_value_to )
                                        );
        <<main_loop>>
        LOOP
        FETCH get_gl_je_data_manual_cur2 INTO
              gt_data_tab(1)  -- 仕訳ヘッダーＩＤ
            , gt_data_tab(2)  -- 会計期間
            , gt_data_tab(3)  -- 有効日
            , gt_data_tab(4)  -- 仕訳ソース
            , gt_data_tab(5)  -- 仕訳ソース名
            , gt_data_tab(6)  -- 仕訳カテゴリ
            , gt_data_tab(7)  -- 仕訳カテゴリ名
            , gt_data_tab(8)  -- 仕訳文書番号
            , gt_data_tab(9)  -- 仕訳バッチ名
            , gt_data_tab(10) -- 仕訳名
            , gt_data_tab(11) -- 摘要
            , gt_data_tab(12) -- 仕訳明細番号
            , gt_data_tab(13) -- 仕訳明細摘要
            , gt_data_tab(14) -- ＡＦＦ会社コード
            , gt_data_tab(15) -- ＡＦＦ部門コード
            , gt_data_tab(16) -- 部門名称 
            , gt_data_tab(17) -- ＡＦＦ勘定科目コード
            , gt_data_tab(18) -- 勘定科目名称 
            , gt_data_tab(19) -- ＡＦＦ補助科目コード
            , gt_data_tab(20) -- 補助科目名称
            , gt_data_tab(21) -- ＡＦＦ顧客コード
            , gt_data_tab(22) -- 顧客名称
            , gt_data_tab(23) -- ＡＦＦ企業コード
            , gt_data_tab(24) -- 企業名称
            , gt_data_tab(25) -- ＡＦＦ予備１
            , gt_data_tab(26) -- 予備１名称
            , gt_data_tab(27) -- ＡＦＦ予備２
            , gt_data_tab(28) -- 予備２名称
            , gt_data_tab(29) -- 勘定科目組合せid
            , gt_data_tab(30) -- 借方金額
            , gt_data_tab(31) -- 貸方金額
            , gt_data_tab(32) -- 税区分
            , gt_data_tab(33) -- 増減事由
            , gt_data_tab(34) -- 伝票番号
            , gt_data_tab(35) -- 起票部門
            , gt_data_tab(36) -- 伝票入力者
            , gt_data_tab(37) -- 修正元伝票番号
            , gt_data_tab(38) -- 相手勘定勘定科目コード
            , gt_data_tab(39) -- 相手勘定勘定科目名称
            , gt_data_tab(40) -- 相手勘定補助科目コード
            , gt_data_tab(41) -- 相手勘定補助科目名称
            , gt_data_tab(42) -- 販売実績ヘッダーID
            , gt_data_tab(43) -- 資産管理キー在庫管理キー値 
            , gt_data_tab(44) -- 補助簿文書番号 
            , gt_data_tab(45) -- 通貨
            , gt_data_tab(46) -- レートタイプ
            , gt_data_tab(47) -- 換算日
            , gt_data_tab(48) -- 換算レート
            , gt_data_tab(49) -- 借方機能通貨金額
            , gt_data_tab(50) -- 貸方機能通貨金額
            , gt_data_tab(51) -- 連携日時
            , gt_data_tab(52) -- ステータス
            , gt_data_tab(53) -- データタイプ
            ;
          EXIT WHEN get_gl_je_data_manual_cur2%NOTFOUND;
--
          --==============================================================
          --項目チェック処理(A-6)
          --==============================================================
          chk_item(
            ov_errbuf                     =>        lv_errbuf    -- エラー・メッセージ
           ,ov_retcode                    =>        lv_retcode   -- リターン・コード
           ,ov_errmsg                     =>        lv_errmsg    -- ユーザー・エラー・メッセージ
           ,ov_errlevel                   =>        lv_errlevel  -- エラーレベル(HEAD,LINE)
           ,ov_msgcode                    =>        lv_msgcode); -- メッセージコード
          IF ( lv_errlevel = cv_errlevel_line ) 
          AND ( gv_line_skip_flg = cv_flag_n ) THEN
            IF ( lv_retcode = cv_status_normal ) THEN
              -- ヘッダ単位、明細単位のチェックともに正常の場合、CSV出力を行う
              --==============================================================
              -- CSV出力処理(A-7)
              --==============================================================
              out_csv (
                ov_errbuf                   =>        lv_errbuf
               ,ov_retcode                  =>        lv_retcode
               ,ov_errmsg                   =>        lv_errmsg);
              IF ( lv_retcode = cv_status_error ) THEN
                --処理終了時に、作成したファイルを0Byteにする
                gv_0file_flg := cv_flag_y;
                RAISE global_process_expt;
              END IF;
            ELSIF ( lv_retcode = cv_status_error )
              OR ( lv_retcode = cv_status_warn ) THEN
              --明細単位のチェックがエラーまたは警告の場合エラー終了
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                        ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                        ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                  ,cv_msgtkn_cfo_11003)
                                          || cv_msg_part || gt_data_tab(1) || ' '-- 仕訳ヘッダID
                                          || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                      ,cv_msgtkn_cfo_11004)
                                          || cv_msg_part || gt_data_tab(12)         -- 仕訳明細番号
                                        )
                                      ,1
                                      ,5000);
              ELSE
                lv_errmsg := lv_errmsg || ' ' 
                             || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                         ,cv_msgtkn_cfo_11003)
                             || cv_msg_part || gt_data_tab(1);-- 仕訳ヘッダID
              END IF;
              lv_errbuf := lv_errmsg;
              --処理終了時に、作成したファイルを0Byteにする
              gv_0file_flg := cv_flag_y;
              --処理を中断
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_errlevel = cv_errlevel_header ) THEN
            IF ( lv_retcode = cv_status_warn ) THEN
              --ヘッダ単位で警告の場合、警告フラグを'Y'にする
              gv_warning_flg := cv_flag_y;
              --明細スキップフラグを'Y'にする
              gv_line_skip_flg := cv_flag_y;
            ELSIF( lv_retcode = cv_status_error ) THEN
              --ヘッダ単位でエラーの場合、処理を終了する
              --処理終了時に、作成したファイルを0Byteにする
              gv_0file_flg := cv_flag_y;
              RAISE global_process_expt;
            END IF;
          END IF;
--
          IF ( gt_data_tab(53) = cv_data_type_0 ) THEN
            --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
            gn_target_cnt      := gn_target_cnt + 1;
          ELSE
            --データタイプが1(未連携分)の場合、対象件数（未連携分）に1カウント
            gn_target_wait_cnt := gn_target_wait_cnt + 1;
          END IF;
          --
          --行単位の処理終了時に、現読込行のヘッダIDを変数に格納する(ヘッダと明細の判断用)
          gt_gl_je_header_id := gt_data_tab(1);
        END LOOP main_loop;
        CLOSE get_gl_je_data_manual_cur2;
      ELSE
        --会計期間、仕訳文書番号両方指定されている場合
        OPEN get_gl_je_data_manual_cur3( iv_period_name
                                       ,TO_NUMBER( iv_doc_seq_value_from )
                                       ,TO_NUMBER( iv_doc_seq_value_to )
                                        );
        <<main_loop>>
        LOOP
        FETCH get_gl_je_data_manual_cur3 INTO
              gt_data_tab(1)  -- 仕訳ヘッダーＩＤ
            , gt_data_tab(2)  -- 会計期間
            , gt_data_tab(3)  -- 有効日
            , gt_data_tab(4)  -- 仕訳ソース
            , gt_data_tab(5)  -- 仕訳ソース名
            , gt_data_tab(6)  -- 仕訳カテゴリ
            , gt_data_tab(7)  -- 仕訳カテゴリ名
            , gt_data_tab(8)  -- 仕訳文書番号
            , gt_data_tab(9)  -- 仕訳バッチ名
            , gt_data_tab(10) -- 仕訳名
            , gt_data_tab(11) -- 摘要
            , gt_data_tab(12) -- 仕訳明細番号
            , gt_data_tab(13) -- 仕訳明細摘要
            , gt_data_tab(14) -- ＡＦＦ会社コード
            , gt_data_tab(15) -- ＡＦＦ部門コード
            , gt_data_tab(16) -- 部門名称 
            , gt_data_tab(17) -- ＡＦＦ勘定科目コード
            , gt_data_tab(18) -- 勘定科目名称 
            , gt_data_tab(19) -- ＡＦＦ補助科目コード
            , gt_data_tab(20) -- 補助科目名称
            , gt_data_tab(21) -- ＡＦＦ顧客コード
            , gt_data_tab(22) -- 顧客名称
            , gt_data_tab(23) -- ＡＦＦ企業コード
            , gt_data_tab(24) -- 企業名称
            , gt_data_tab(25) -- ＡＦＦ予備１
            , gt_data_tab(26) -- 予備１名称
            , gt_data_tab(27) -- ＡＦＦ予備２
            , gt_data_tab(28) -- 予備２名称
            , gt_data_tab(29) -- 勘定科目組合せid
            , gt_data_tab(30) -- 借方金額
            , gt_data_tab(31) -- 貸方金額
            , gt_data_tab(32) -- 税区分
            , gt_data_tab(33) -- 増減事由
            , gt_data_tab(34) -- 伝票番号
            , gt_data_tab(35) -- 起票部門
            , gt_data_tab(36) -- 伝票入力者
            , gt_data_tab(37) -- 修正元伝票番号
            , gt_data_tab(38) -- 相手勘定勘定科目コード
            , gt_data_tab(39) -- 相手勘定勘定科目名称
            , gt_data_tab(40) -- 相手勘定補助科目コード
            , gt_data_tab(41) -- 相手勘定補助科目名称
            , gt_data_tab(42) -- 販売実績ヘッダーID
            , gt_data_tab(43) -- 資産管理キー在庫管理キー値 
            , gt_data_tab(44) -- 補助簿文書番号 
            , gt_data_tab(45) -- 通貨
            , gt_data_tab(46) -- レートタイプ
            , gt_data_tab(47) -- 換算日
            , gt_data_tab(48) -- 換算レート
            , gt_data_tab(49) -- 借方機能通貨金額
            , gt_data_tab(50) -- 貸方機能通貨金額
            , gt_data_tab(51) -- 連携日時
            , gt_data_tab(52) -- ステータス
            , gt_data_tab(53) -- データタイプ
            ;
          EXIT WHEN get_gl_je_data_manual_cur3%NOTFOUND;
--
          --==============================================================
          --項目チェック処理(A-6)
          --==============================================================
          chk_item(
            ov_errbuf                     =>        lv_errbuf    -- エラー・メッセージ
           ,ov_retcode                    =>        lv_retcode   -- リターン・コード
           ,ov_errmsg                     =>        lv_errmsg    -- ユーザー・エラー・メッセージ
           ,ov_errlevel                   =>        lv_errlevel  -- エラーレベル(HEAD,LINE)
           ,ov_msgcode                    =>        lv_msgcode); -- メッセージコード
          IF ( lv_errlevel = cv_errlevel_line ) 
          AND ( gv_line_skip_flg = cv_flag_n ) THEN
            IF ( lv_retcode = cv_status_normal ) THEN
              -- ヘッダ単位、明細単位のチェックともに正常の場合、CSV出力を行う
              --==============================================================
              -- CSV出力処理(A-7)
              --==============================================================
              out_csv (
                ov_errbuf                   =>        lv_errbuf
               ,ov_retcode                  =>        lv_retcode
               ,ov_errmsg                   =>        lv_errmsg);
              IF ( lv_retcode = cv_status_error ) THEN
                --処理終了時に、作成したファイルを0Byteにする
                gv_0file_flg := cv_flag_y;
                RAISE global_process_expt;
              END IF;
            ELSIF ( lv_retcode = cv_status_error )
              OR ( lv_retcode = cv_status_warn ) THEN
              --明細単位のチェックがエラーまたは警告の場合エラー終了
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                        ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                        ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                  ,cv_msgtkn_cfo_11003)
                                          || cv_msg_part || gt_data_tab(1) || ' '-- 仕訳ヘッダID
                                          || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                      ,cv_msgtkn_cfo_11004)
                                          || cv_msg_part || gt_data_tab(12)         -- 仕訳明細番号
                                        )
                                      ,1
                                      ,5000);
              ELSE
                lv_errmsg := lv_errmsg || ' ' 
                             || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                         ,cv_msgtkn_cfo_11003)
                             || cv_msg_part || gt_data_tab(1);-- 仕訳ヘッダID
              END IF;
              lv_errbuf := lv_errmsg;
              --処理終了時に、作成したファイルを0Byteにする
              gv_0file_flg := cv_flag_y;
              --処理を中断
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_errlevel = cv_errlevel_header ) THEN
            IF ( lv_retcode = cv_status_warn ) THEN
              --ヘッダ単位で警告の場合、警告フラグを'Y'にする
              gv_warning_flg := cv_flag_y;
              --明細スキップフラグを'Y'にする
              gv_line_skip_flg := cv_flag_y;
            ELSIF( lv_retcode = cv_status_error ) THEN
              --ヘッダ単位でエラーの場合、処理を終了する
              --処理終了時に、作成したファイルを0Byteにする
              gv_0file_flg := cv_flag_y;
              RAISE global_process_expt;
            END IF;
          END IF;
--
          IF ( gt_data_tab(53) = cv_data_type_0 ) THEN
            --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
            gn_target_cnt      := gn_target_cnt + 1;
          ELSE
            --データタイプが1(未連携分)の場合、対象件数（未連携分）に1カウント
            gn_target_wait_cnt := gn_target_wait_cnt + 1;
          END IF;
          --
          --行単位の処理終了時に、現読込行のヘッダIDを変数に格納する(ヘッダと明細の判断用)
          gt_gl_je_header_id := gt_data_tab(1);
        END LOOP main_loop;
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
--
    --==============================================================
    -- 2 定時実行の場合
    --==============================================================
    ELSIF gv_exec_kbn        =   cv_exec_fixed_period   THEN
      --カーソルオープン
      OPEN get_gl_je_data_fixed_cur( it_gl_je_header_id_from
                                    ,it_gl_je_header_id_to
                                     );
      <<main_loop>>
      LOOP
      FETCH get_gl_je_data_fixed_cur INTO
            gt_data_tab(1)  -- 仕訳ヘッダーＩＤ
          , gt_data_tab(2)  -- 会計期間
          , gt_data_tab(3)  -- 有効日
          , gt_data_tab(4)  -- 仕訳ソース
          , gt_data_tab(5)  -- 仕訳ソース名
          , gt_data_tab(6)  -- 仕訳カテゴリ
          , gt_data_tab(7)  -- 仕訳カテゴリ名
          , gt_data_tab(8)  -- 仕訳文書番号
          , gt_data_tab(9)  -- 仕訳バッチ名
          , gt_data_tab(10) -- 仕訳名
          , gt_data_tab(11) -- 摘要
          , gt_data_tab(12) -- 仕訳明細番号
          , gt_data_tab(13) -- 仕訳明細摘要
          , gt_data_tab(14) -- ＡＦＦ会社コード
          , gt_data_tab(15) -- ＡＦＦ部門コード
          , gt_data_tab(16) -- 部門名称 
          , gt_data_tab(17) -- ＡＦＦ勘定科目コード
          , gt_data_tab(18) -- 勘定科目名称 
          , gt_data_tab(19) -- ＡＦＦ補助科目コード
          , gt_data_tab(20) -- 補助科目名称
          , gt_data_tab(21) -- ＡＦＦ顧客コード
          , gt_data_tab(22) -- 顧客名称
          , gt_data_tab(23) -- ＡＦＦ企業コード
          , gt_data_tab(24) -- 企業名称
          , gt_data_tab(25) -- ＡＦＦ予備１
          , gt_data_tab(26) -- 予備１名称
          , gt_data_tab(27) -- ＡＦＦ予備２
          , gt_data_tab(28) -- 予備２名称
          , gt_data_tab(29) -- 勘定科目組合せid
          , gt_data_tab(30) -- 借方金額
          , gt_data_tab(31) -- 貸方金額
          , gt_data_tab(32) -- 税区分
          , gt_data_tab(33) -- 増減事由
          , gt_data_tab(34) -- 伝票番号
          , gt_data_tab(35) -- 起票部門
          , gt_data_tab(36) -- 伝票入力者
          , gt_data_tab(37) -- 修正元伝票番号
          , gt_data_tab(38) -- 相手勘定勘定科目コード
          , gt_data_tab(39) -- 相手勘定勘定科目名称
          , gt_data_tab(40) -- 相手勘定補助科目コード
          , gt_data_tab(41) -- 相手勘定補助科目名称
          , gt_data_tab(42) -- 販売実績ヘッダーID
          , gt_data_tab(43) -- 資産管理キー在庫管理キー値 
          , gt_data_tab(44) -- 補助簿文書番号 
          , gt_data_tab(45) -- 通貨
          , gt_data_tab(46) -- レートタイプ
          , gt_data_tab(47) -- 換算日
          , gt_data_tab(48) -- 換算レート
          , gt_data_tab(49) -- 借方機能通貨金額
          , gt_data_tab(50) -- 貸方機能通貨金額
          , gt_data_tab(51) -- 連携日時
          , gt_data_tab(52) -- ステータス
          , gt_data_tab(53) -- データタイプ
          ;
        EXIT WHEN get_gl_je_data_fixed_cur%NOTFOUND;
--
        --==============================================================
        --項目チェック処理(A-6)
        --==============================================================
        chk_item(
          ov_errbuf                     =>        lv_errbuf    -- エラー・メッセージ
         ,ov_retcode                    =>        lv_retcode   -- リターン・コード
         ,ov_errmsg                     =>        lv_errmsg    -- ユーザー・エラー・メッセージ
         ,ov_errlevel                   =>        lv_errlevel  -- エラーレベル(HEAD,LINE,P)
         ,ov_msgcode                    =>        lv_msgcode); -- メッセージコード
        IF ( lv_errlevel = cv_errlevel_line ) THEN
          IF ( lv_retcode = cv_status_normal ) THEN
            -- 明細単位のチェックが正常の場合、CSV出力を行う
            --==============================================================
            -- CSV出力処理(A-7)
            --==============================================================
            out_csv (
              ov_errbuf                   =>        lv_errbuf
             ,ov_retcode                  =>        lv_retcode
             ,ov_errmsg                   =>        lv_errmsg);
            IF ( lv_retcode = cv_status_error ) THEN
              --処理終了時に、作成したファイルを0Byteにする
              gv_0file_flg := cv_flag_y;
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
              --明細単位のチェックが警告且つ、定期実行の場合
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                --桁数オーバーの場合、警告メッセージを出力し、後続処理は行わない
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                        ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                        ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo 
                                                                  ,cv_msgtkn_cfo_11003)
                                          || cv_msg_part || gt_data_tab(1) || ' '-- 仕訳ヘッダID
                                          || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                      ,cv_msgtkn_cfo_11004)
                                          || cv_msg_part || gt_data_tab(12)         -- 仕訳明細番号
                                        )
                                      ,1
                                      ,5000);
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg
                );
              ELSIF ( gv_wait_ins_flg = cv_flag_n ) THEN
                --まだ未連携に登録されていない場合
                --==============================================================
                --未連携テーブル登録処理(A-8)
                --==============================================================
                out_gl_je_wait(
                  iv_cause                    =>        cv_msgtkn_cfo_11007 -- '明細チェックエラー'
                , iv_meaning                  =>        lv_errmsg     -- A-6のユーザーエラーメッセージ
                , ov_errbuf                   =>        lv_errbuf     -- エラーメッセージ
                , ov_retcode                  =>        lv_retcode    -- リターンコード
                , ov_errmsg                   =>        lv_errmsg     -- ユーザー・エラーメッセージ
                );
                IF ( lv_retcode = cv_status_error ) THEN
                  --処理終了時に、作成したファイルを0Byteにする
                  gv_0file_flg := cv_flag_y;
                  RAISE global_process_expt;
                ELSE
                  gv_wait_ins_flg := cv_flag_y; --登録済
                END IF;
              END IF;
            END IF;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            --明細単位のチェックがエラーの場合、処理終了時に、作成したファイルを0Byteにする
            gv_0file_flg := cv_flag_y;
            --処理を中断
            RAISE global_process_expt;
          END IF;
        ELSIF ( lv_errlevel = cv_errlevel_header )
          AND ( lv_retcode = cv_status_error ) THEN
          --ヘッダ単位でエラーの場合、処理を終了する
          --処理終了時に、作成したファイルを0Byteにする
          gv_0file_flg := cv_flag_y;
          RAISE global_process_expt;
        END IF;
--
        IF ( gt_data_tab(53) = cv_data_type_0 ) THEN
          --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --データタイプが1(未連携分)の場合、対象件数（未連携分）に1カウント
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          --内部の処理で警告が発生した場合、警告フラグにYを設定する
          gv_warning_flg := cv_flag_y;
        END IF;
        --行単位の処理終了時に、現読込行のヘッダIDを変数に格納する(ヘッダと明細の判断用)
        gt_gl_je_header_id := gt_data_tab(1);
      END LOOP main_loop;
      CLOSE get_gl_je_data_fixed_cur;
    END IF;
--
    --==================================================================
    -- 0件の場合はメッセージ出力
    --==================================================================
    IF ( gn_target_cnt + gn_target_wait_cnt ) = 0 THEN
      gv_warning_flg := cv_flag_y; --警告フラグをYにする
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_10025      -- 取得対象データ無しメッセージ
                                                      ,cv_tkn_get_data       -- トークン'GET_DATA' 
                                                      ,cv_msgtkn_cfo_11039   -- 対象仕訳情報
                                                     )
                            ,1
                            ,5000
                          );
      --ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_gl_je_data_fixed_cur%ISOPEN THEN
        CLOSE get_gl_je_data_fixed_cur;
      END IF;
      IF get_gl_je_data_manual_cur1%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur1;
      END IF;
      IF get_gl_je_data_manual_cur2%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur2;
      END IF;
      IF get_gl_je_data_manual_cur3%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_gl_je_data_fixed_cur%ISOPEN THEN
        CLOSE get_gl_je_data_fixed_cur;
      END IF;
      IF get_gl_je_data_manual_cur1%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur1;
      END IF;
      IF get_gl_je_data_manual_cur2%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur2;
      END IF;
      IF get_gl_je_data_manual_cur3%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_gl_je_data_fixed_cur%ISOPEN THEN
        CLOSE get_gl_je_data_fixed_cur;
      END IF;
      IF get_gl_je_data_manual_cur1%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur1;
      END IF;
      IF get_gl_je_data_manual_cur2%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur2;
      END IF;
      IF get_gl_je_data_manual_cur3%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_gl_je_data_fixed_cur%ISOPEN THEN
        CLOSE get_gl_je_data_fixed_cur;
      END IF;
      IF get_gl_je_data_manual_cur1%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur1;
      END IF;
      IF get_gl_je_data_manual_cur2%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur2;
      END IF;
      IF get_gl_je_data_manual_cur3%ISOPEN THEN
        CLOSE get_gl_je_data_manual_cur3;
      END IF;
    -- *** 共通関数例外ハンドラ ***
--
--#####################################  固定部 END   ##########################################
--
  END get_gl_je;
--
  /**********************************************************************************
   * Procedure Name   : upd_gl_je_control
   * Description      : 管理テーブル登録・更新処理(A-9)
   ***********************************************************************************/
  PROCEDURE upd_gl_je_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_gl_je_control'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_ctl_max_gl_je_header_id NUMBER; --最大仕訳ヘッダID(仕訳管理)
    ln_hd_max_gl_je_header_id  NUMBER; --最大仕訳ヘッダID(仕訳ヘッダ)
--
    -- ===============================
    -- ローカル・カーソル
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
      --==============================================================
      --未連携データ削除
      --==============================================================
      --A-2で取得した未連携データを条件に、削除を行う
      <<delete_loop>>
      FOR i IN 1 .. gl_je_wait_tab.COUNT LOOP
        BEGIN
          DELETE FROM xxcfo_gl_je_wait_coop xgjwc --仕訳未連携
          WHERE xgjwc.rowid = gl_je_wait_tab( i ).rowid
          ;
        EXCEPTION
          WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                  ( cv_msg_kbn_cfo     -- XXCFO
                                    ,cv_msg_cfo_00025   -- データ削除エラー
                                    ,cv_tkn_table       -- トークン'TABLE'
                                    ,cv_msgtkn_cfo_11002 -- 仕訳未連携
                                    ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                    ,SQLERRM            -- SQLエラーメッセージ
                                   )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        END;
      END LOOP;
--
      --==============================================================
      --仕訳管理テーブル更新
      --==============================================================
      BEGIN
        UPDATE xxcfo_gl_je_control xgjc --仕訳管理
        SET xgjc.process_flag           = cv_flag_y                 -- 処理済フラグ
           ,xgjc.last_updated_by        = cn_last_updated_by        -- 最終更新者
           ,xgjc.last_update_date       = cd_last_update_date       -- 最終更新日
           ,xgjc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
           ,xgjc.request_id             = cn_request_id             -- 要求ID
           ,xgjc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
           ,xgjc.program_id             = cn_program_id             -- プログラムID
           ,xgjc.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE xgjc.process_flag         = cv_flag_n                 -- 処理済フラグ'N'
          AND xgjc.gl_je_header_id      <= gt_gl_je_header_id_to    -- A-3で取得した仕訳ヘッダID(To)
        ;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00020   -- データ更新エラー
                                                       ,cv_tkn_table       -- トークン'TABLE'
                                                       ,cv_msgtkn_cfo_11001 -- 仕訳管理
                                                       ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                                       ,SQLERRM            -- SQLエラーメッセージ
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      --==============================================================
      --仕訳管理テーブル登録
      --==============================================================
      --仕訳管理データから最大の仕訳ヘッダIDを取得
      BEGIN
        SELECT MAX(xgjc.gl_je_header_id)
          INTO ln_ctl_max_gl_je_header_id
          FROM xxcfo_gl_je_control xgjc
        ;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfo   -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- 取得対象データ無しメッセージ
                                                     ,cv_tkn_get_data    -- トークン'GET_DATA'
                                                     ,cv_msgtkn_cfo_11041 --仕訳データ
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      --当日作成された仕訳ヘッダIDの最大値を取得
      BEGIN
--2012/12/18 Ver.1.2 Mod Start
--        SELECT NVL(MAX(gjh.je_header_id),ln_ctl_max_gl_je_header_id)
        SELECT /*+ INDEX(gjh GL_JE_HEADERS_U1) */
               NVL(MAX(gjh.je_header_id),ln_ctl_max_gl_je_header_id)
--2012/12/18 Ver.1.2 Mod End
          INTO ln_hd_max_gl_je_header_id
          FROM gl_je_headers gjh
         WHERE gjh.je_header_id > ln_ctl_max_gl_je_header_id
           AND gjh.creation_date < ( gd_process_date + 1 + NVL(gv_proc_target_time,0) / 24 )
        ;
      END;
--
      --仕訳管理テーブル登録
      BEGIN
        INSERT INTO xxcfo_gl_je_control(
           business_date          -- 業務日付
          ,gl_je_header_id        -- 仕訳ヘッダID
          ,process_flag           -- 処理済フラグ
          ,created_by             -- 作成者
          ,creation_date          -- 作成日
          ,last_updated_by        -- 最終更新者
          ,last_update_date       -- 最終更新日
          ,last_update_login      -- 最終更新ログイン
          ,request_id             -- 要求ID
          ,program_application_id -- コンカレント・プログラム・アプリケーションID
          ,program_id             -- コンカレント・プログラムID
          ,program_update_date    -- プログラム更新日
        ) VALUES (
           gd_process_date
          ,ln_hd_max_gl_je_header_id
          ,cv_flag_n
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        );
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00024   -- データ登録エラー
                                                       ,cv_tkn_table       -- トークン'TABLE'
                                                       ,cv_msgtkn_cfo_11001 -- 仕訳管理
                                                       ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                                       ,SQLERRM            -- SQLエラーメッセージ
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
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
  END upd_gl_je_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn        IN  VARCHAR2, -- 1.追加更新区分
    iv_file_name          IN  VARCHAR2, -- 2.ファイル名
    iv_period_name        IN  VARCHAR2, -- 3.会計期間
    iv_doc_seq_value_from IN  VARCHAR2, -- 4.仕訳文書番号（From）
    iv_doc_seq_value_to   IN  VARCHAR2, -- 5.仕訳文書番号（To）
    iv_exec_kbn           IN  VARCHAR2, -- 6.定期手動区分
    ov_errbuf             OUT VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
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
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
    gn_target_wait_cnt := 0;
    gn_wait_data_cnt   := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_ins_upd_kbn        -- 1.追加更新区分
      ,iv_file_name          -- 2.ファイル名
      ,iv_period_name        -- 3.会計期間
      ,iv_doc_seq_value_from -- 4.仕訳文書番号（From）
      ,iv_doc_seq_value_to   -- 5.仕訳文書番号（To）
      ,iv_exec_kbn           -- 6.定期手動区分
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 未連携データ取得処理(A-2)
    -- ===============================
    get_gl_je_wait(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告フラグをYにする
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- 管理テーブルデータ取得処理(A-3)
    -- ===============================
    get_gl_je_control(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告フラグをYにする
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- 対象データ取得(A-4)
    -- ===============================
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
      --手動実行の場合
      get_gl_je(
        iv_period_name,        -- 1.会計期間
        iv_doc_seq_value_from, -- 2.仕訳文書番号(From)
        iv_doc_seq_value_to,   -- 3.仕訳文書番号(To)
        NULL,                  -- 4.仕訳ヘッダID(From)
        NULL,                  -- 5.仕訳ヘッダID(To)
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    ELSIF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --定期実行の場合
      get_gl_je(
        NULL,                   -- 1.会計期間
        NULL,                   -- 2.仕訳文書番号（From）
        NULL,                   -- 3.仕訳文書番号（To）
        gt_gl_je_header_id_from,-- 4.仕訳ヘッダID(From)
        gt_gl_je_header_id_to,  -- 5.仕訳ヘッダID(To)
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告フラグをYにする
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- 管理テーブル登録・更新処理(A-9)
    -- ===============================
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --定期実行の場合のみ、以下の処理を行う
      upd_gl_je_control(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        --処理終了時に、作成したファイルを0Byteにする
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      END IF;
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
    errbuf                OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode               OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_ins_upd_kbn        IN  VARCHAR2,      -- 1.追加更新区分
    iv_file_name          IN  VARCHAR2,      -- 2.ファイル名
    iv_period_name        IN  VARCHAR2,      -- 3.会計期間
    iv_doc_seq_value_from IN  VARCHAR2,      -- 4.仕訳文書番号（From）
    iv_doc_seq_value_to   IN  VARCHAR2,      -- 5.仕訳文書番号（To）
    iv_exec_kbn           IN  VARCHAR2       -- 6.定期手動区分
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
       iv_ins_upd_kbn                              -- 1.追加更新区分
      ,iv_file_name                                -- 2.ファイル名
      ,iv_period_name                              -- 3.会計期間
      ,iv_doc_seq_value_from                       -- 4.仕訳文書番号（From）
      ,iv_doc_seq_value_to                         -- 5.仕訳文書番号（To）
      ,iv_exec_kbn                                 -- 6.定期手動区分
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 会計チーム標準：異常終了時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_wait_data_cnt   := 0;
    END IF;
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
    END IF;
--
    --内部で警告が発生し、エラー終了でない場合、ステータスを警告にする
    IF ( lv_retcode <> cv_status_error )
    AND ( gv_warning_flg = cv_flag_y ) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    -- ====================================================
    -- ファイルクローズ
    -- ====================================================
    -- ファイルがオープンされている場合はクローズする
    IF ( UTL_FILE.IS_OPEN ( gv_file_hand )) THEN
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    -- ====================================================
    -- ファイル0Byte更新
    -- ====================================================
    -- 手動実行且つ、A-5以降の処理でエラーが発生していた場合、
    -- ファイルを再度オープン＆クローズし、0Byteに更新する
    IF ( ( iv_exec_kbn = cv_exec_manual )
    AND ( lv_retcode = cv_status_error )
    AND ( gv_0file_flg = cv_flag_y ) ) THEN
      BEGIN
        gv_file_hand := UTL_FILE.FOPEN( gv_file_path
                                       ,gv_file_name
                                       ,cv_open_mode_w
                                      );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029 -- ファイルオープンエラー
                                                       )
                                                       ,1
                                                       ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
      END;
      --ファイルクローズ
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力（連携分）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力（未連携処理分）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_wait_cnt)
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
    --未連携件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_wait_data_cnt)
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
END XXCFO019A02C;
/