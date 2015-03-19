CREATE OR REPLACE PACKAGE BODY apps.XXCFF018A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF018A01C (body)
 * Description      : 償却シミュレーション結果リスト
 * MD.050           : 償却シミュレーション結果リスト (MD050_CFF_018_A01)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_csv             データ抽出処理(A-2)、CSV出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-4)
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-12-18    1.0   K.Kanada         新規作成  E_本稼動_08122対応
 *
 *****************************************************************************************/
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
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  init_err_expt               EXCEPTION;      -- 初期処理エラー
  chk_no_data_found_expt      EXCEPTION;      -- 対象データなし
  subprocedure_warn_expt      EXCEPTION;      -- サブ機能の警告終了
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFF018A01C';              -- パッケージ名
--
  -- DBMS_SQL複数行一括Fetchの件数
  cn_fetch_size               CONSTANT NUMBER        := 1000 ;
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcff          CONSTANT VARCHAR2(10)  := 'XXCFF';                     -- XXCFF
  -- 日付書式
  cv_format_YMD               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  cv_format_std               CONSTANT VARCHAR2(50)  := 'yyyy/mm/dd hh24:mi:ss';
  cv_format_YM                CONSTANT VARCHAR2(50)  := 'YYYY/MM';
  cv_format_period            CONSTANT VARCHAR2(50)  := 'YYYY-MM';
  -- 括り文字
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- 文字列括り
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- カンマ
  cv_parenthesis1             CONSTANT VARCHAR2(1)   := '(';                         -- 括弧
  cv_parenthesis2             CONSTANT VARCHAR2(1)   := ')';                         -- 括弧
  cv_sql_csv_start            CONSTANT VARCHAR2(20)  := ' ''"''||' ;
  cv_sql_csv_mid              CONSTANT VARCHAR2(20)  := '||''","''||' ;
  cv_sql_space                CONSTANT VARCHAR2(20)  := '          ' ;
  cv_sql_csv_end              CONSTANT VARCHAR2(20)  := '||''"''' ;
  -- メッセージコード
  cv_msg_cff_00220            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00220';          -- 入力パラメータ
  cv_msg_cff_50277            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50277';          -- メッセージ用トークン(WHATIFリクエストID)
  cv_msg_cff_50278            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50278';          -- メッセージ用トークン(開始期間)
  cv_msg_cff_50279            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50279';          -- メッセージ用トークン(期間数)
  cv_msg_cff_50280            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50280';          -- 償却シミュレーション結果リストヘッダ用トークン1
  cv_msg_cff_50281            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50281';          -- 償却シミュレーション結果リストヘッダ用トークン2(減価償却額)
  cv_msg_cff_50282            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50282';          -- 償却シミュレーション結果リスト対象データ無し
  cv_msg_cff_90000            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- 対象件数メッセージ
  cv_msg_cff_90001            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- 成功件数メッセージ
  cv_msg_cff_90002            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- エラー件数メッセージ
  cv_msg_cff_90003            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';          -- スキップ件数メッセージ
  cv_msg_cff_90004            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- 正常終了メッセージ
  cv_msg_cff_90005            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';          -- 警告メッセージ
  cv_msg_cff_90006            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- エラー終了全ロールバックメッセージ
  -- トークン
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- 入力パラメータ名
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- 入力パラメータ値
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- 件数
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_whatif_request_id               NUMBER;         -- 1.WHATIFリクエストID
  gd_period_date                     DATE;           -- 2.開始期間（日付型変換）
  gn_loop_cnt                        NUMBER;         -- ループ回数（3.期間数－1）
  gv_book_type_code                  XX01_SIM_ADDITIONS.BOOK_TYPE_CODE%TYPE ;           -- 固定資産台帳
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  --
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_whatif_request_id            IN  VARCHAR2     -- 1.WHATIFリクエストID
    ,iv_period_date                  IN  VARCHAR2     -- 2.開始期間
    ,iv_num_periods                  IN  VARCHAR2     -- 3.期間数
    ,ov_errbuf                       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    ,ov_retcode                      OUT VARCHAR2     -- リターン・コード             --# 固定 #
    ,ov_errmsg                       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_param_name1                  VARCHAR2(1000);  -- 入力パラメータ名1
    lv_param_name2                  VARCHAR2(1000);  -- 入力パラメータ名2
    lv_param_name3                  VARCHAR2(1000);  -- 入力パラメータ名3
    lv_param_1                      VARCHAR2(1000);  -- 1.WHATIFリクエストID
    lv_param_2                      VARCHAR2(1000);  -- 2.開始期間
    lv_param_3                      VARCHAR2(1000);  -- 3.期間数
    lv_csv_header                   VARCHAR2(5000);  -- CSVヘッダ項目出力用
    lv_csv_header_1                 VARCHAR2(5000);  -- 固定部
    lv_csv_header_depr_amt          VARCHAR2(20);    -- 文字「減価償却額」
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
    --==============================================================
    -- 1.入力パラメータ出力
    --==============================================================
    gn_whatif_request_id            := TO_NUMBER(iv_whatif_request_id) ;           -- 1.WHATIFリクエストID
    gd_period_date                  := TO_DATE(iv_period_date,cv_format_period) ;  -- 2.開始期間（日付型変換）  ついたち
    gn_loop_cnt                     := TO_NUMBER(iv_num_periods) - 1 ;             -- ループ回数（3.期間数－1）
    --
    -- 1.WHATIFリクエストID
    lv_param_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50277               -- メッセージコード
                      );
    lv_param_1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード   入力パラメータ「PARAM_NAME ：  PARAM_VALUE」
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name1                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_whatif_request_id           -- トークン値2
                      );
    -- 2.開始期間
    lv_param_name2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50278               -- メッセージコード
                      );
    lv_param_2  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード   入力パラメータ「PARAM_NAME ：  PARAM_VALUE」
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name2                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_period_date                 -- トークン値2
                      );
    -- 3.期間数
    lv_param_name3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50279               -- メッセージコード
                      );
    lv_param_3  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード   入力パラメータ「PARAM_NAME ：  PARAM_VALUE」
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name3                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_num_periods                 -- トークン値2
                      );
    --
    -- ログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''          || chr(10) ||
                 lv_param_1  || chr(10) ||      -- 1.WHATIFリクエストID
                 lv_param_2  || chr(10) ||      -- 2.開始期間
                 lv_param_3  || chr(10) ||      -- 3.期間数
                 ''
    );
--
    --==================================================
    -- 2.台帳名取得
    --==================================================
    BEGIN
      SELECT distinct xsw.book_type_code
      INTO   gv_book_type_code
      FROM   xx01_sim_whatif xsw
      WHERE  xsw.whatif_request_id = gn_whatif_request_id
      AND    xsw.period_date       = gd_period_date ;
    EXCEPTION
      -- *** ０件の場合 ***
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50282               -- メッセージコード
                       );
        RAISE chk_no_data_found_expt;
    END ;
--
    --==================================================
    -- 3.CSVヘッダ項目出力
    --==================================================
    -- WHATIFリクエストID,台帳,資産番号,摘要,(カテゴリ)資産種類,(カテゴリ)償却申告,(カテゴリ)資産勘定,
    -- (カテゴリ)償却勘定,(カテゴリ)耐用年数,(カテゴリ)償却方法,(カテゴリ)リース種別,(事業所)申告地,
    -- (事業所)管理部門,(事業所)事業所,(事業所)場所,(事業所)本社/工場,(償却AFF)会社,(償却AFF)計上部門,
    -- (償却AFF)計上部門名,(償却AFF)勘定科目,償却方法,事業供用日,取得価額,初期年償却累計額,当初取得価額,
    -- 初期償却累計額,残存価額,初期帳簿価額,拡張減価償却,備忘価額,(yyyy/mm)減価償却額
    --==================================================
    -- CSVヘッダ文字1
    lv_csv_header_1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50280               -- メッセージコード
                      );
    -- CSVヘッダ文字「減価償却額」
    lv_csv_header_depr_amt := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50281               -- メッセージコード
                      );
    --出力文字列作成
    lv_csv_header := lv_csv_header_1 ;
    --
    << csv_header_loop >>
    FOR i IN 0..gn_loop_cnt
    LOOP
      lv_csv_header := lv_csv_header || cv_comma || cv_dqu ||
                       cv_parenthesis1 || TO_CHAR(ADD_MONTHS(gd_period_date,i),cv_format_YM) || cv_parenthesis2 || 
                       lv_csv_header_depr_amt || cv_dqu ;
                                                                          -- (yyyy/mm)減価償却額
    END LOOP ;
--
    --ヘッダのファイル出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** ０件の場合のエラーハンドラ ***
    WHEN chk_no_data_found_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** エラー終了 ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : データ抽出処理(A-2)、CSV出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
     ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
    ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
    ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    -- 動的SQL用
    lv_sql_str            VARCHAR2(32767) DEFAULT NULL;  -- 出力文字列格納用変数
    lv_edit_depr_amt      VARCHAR2(32767) DEFAULT NULL;  -- SELECT 減価償却額用変数
    lv_edit_period_date   VARCHAR2(100)   DEFAULT NULL;  -- SELECT 減価償却額用変数
    li_cid                INTEGER;
    li_row                INTEGER;
    l_sql_val_tab         DBMS_SQL.VARCHAR2_TABLE;
--
    -- ===============================
    -- ユーザー定義例外
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
    -- ===============================
    -- データ抽出処理(A-2)
    -- ===============================
    ------------------------------
    -- 1.SQL文編集
    ------------------------------
    --減価償却額のSELECT句編集
    << sql_edit_depr_amt_loop >>
    FOR j IN 0..gn_loop_cnt
    LOOP
      lv_edit_period_date := TO_CHAR(ADD_MONTHS(gd_period_date,j),cv_format_YMD) ;
      lv_edit_depr_amt    := lv_edit_depr_amt || cv_sql_csv_mid
                                          || '(SELECT xsw.depreciation'
                               || chr(10) || ' FROM xx01_sim_whatif xsw'
                               || chr(10) || ' WHERE xsw.whatif_request_id = xsa.whatif_request_id'
                               || chr(10) || ' AND xsw.book_type_code = xsa.book_type_code'
                               || chr(10) || ' AND xsw.asset_number = xsa.asset_number'
                               || chr(10) || ' AND xsw.period_date = TO_DATE(''' || lv_edit_period_date || ''',''yyyy/mm/dd''))'
                               || chr(10) ;
    END LOOP sql_edit_depr_amt_loop ;
--
    --
    --SELECT句編集
    lv_sql_str        := 'SELECT'
    ||chr(10)||cv_sql_csv_start|| 'xsa.whatif_request_id'                                           --whatifリクエストid
    ||chr(10)|| cv_sql_csv_mid || 'xsa.book_type_code'                                              --台帳
    ||chr(10)|| cv_sql_csv_mid || 'xsa.asset_number'                                                --資産番号
    ||chr(10)|| cv_sql_csv_mid || 'xsa.description'                                                 --摘要
    ||chr(10)|| cv_sql_csv_mid || 'category.segment1'                                               --(カテゴリ)資産種類
    ||chr(10)|| cv_sql_csv_mid || 'category.segment2'                                               --(カテゴリ)償却申告
    ||chr(10)|| cv_sql_csv_mid || 'category.segment3'                                               --(カテゴリ)資産勘定
    ||chr(10)|| cv_sql_csv_mid || 'category.segment4'                                               --(カテゴリ)償却勘定
    ||chr(10)|| cv_sql_csv_mid || 'category.segment5'                                               --(カテゴリ)耐用年数
    ||chr(10)|| cv_sql_csv_mid || 'category.segment6'                                               --(カテゴリ)償却方法
    ||chr(10)|| cv_sql_csv_mid || 'category.segment7'                                               --(カテゴリ)リース種別
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment1'                                                 --(事業所)申告地
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment2'                                                 --(事業所)管理部門
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment3'                                                 --(事業所)事業所
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment4'                                                 --(事業所)場所
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment5'                                                 --(事業所)本社/工場
    ||chr(10)|| cv_sql_csv_mid || 'deprn_acct_code.segment1'                                        --(償却aff)会社
    ||chr(10)|| cv_sql_csv_mid || 'deprn_acct_code.segment2'                                        --(償却aff)計上部門
    ||chr(10)|| cv_sql_csv_mid || '(SELECT aff_department_name'
    ||chr(10)|| cv_sql_space   || ' FROM xxcff_aff_department_v aff_dep'
    ||chr(10)|| cv_sql_space   || ' WHERE aff_dep.aff_department_code = deprn_acct_code.segment2)'  --(償却aff)計上部門名
    ||chr(10)|| cv_sql_csv_mid || 'deprn_acct_code.segment3'                                        --(償却aff)勘定科目
    ||chr(10)|| cv_sql_csv_mid || 'xsa.deprn_method_code'                                           --償却方法
    ||chr(10)|| cv_sql_csv_mid || 'TO_CHAR(xsa.date_placed_in_service,''yyyy/mm/dd'')'              --事業供用日
    ||chr(10)|| cv_sql_csv_mid || 'xsa.cost'                                                        --取得価額
    ||chr(10)|| cv_sql_csv_mid || 'xsa.fst_ytd_deprn'                                               --初期年償却累計額
    ||chr(10)|| cv_sql_csv_mid || 'xsa.original_cost'                                               --当初取得価額
    ||chr(10)|| cv_sql_csv_mid || 'xsa.fst_deprn_reserve'                                           --初期償却累計額
    ||chr(10)|| cv_sql_csv_mid || 'xsa.salvage_value'                                               --残存価額
    ||chr(10)|| cv_sql_csv_mid || 'xsa.fst_nbv'                                                     --初期帳簿価額
    ||chr(10)|| cv_sql_csv_mid || 'xsa.extended_deprn_flag'                                         --拡張減価償却
    ||chr(10)|| cv_sql_csv_mid || 'xsa.recoverable_cost'                                            --備忘価額
    ||chr(10)|| lv_edit_depr_amt || cv_sql_csv_end 
    ||chr(10) ;
    --
    --FROM WHERE ORDER-BY 句編集
    lv_sql_str := lv_sql_str || 'FROM xx01_sim_additions xsa'
                    ||chr(10)|| '    ,fa_categories_b category'
                    ||chr(10)|| '    ,fa_locations locate'
                    ||chr(10)|| '    ,gl_code_combinations deprn_acct_code'
                    ||chr(10)|| 'WHERE xsa.asset_category_id = category.category_id'
                    ||chr(10)|| 'AND xsa.location_id = locate.location_id'
                    ||chr(10)|| 'AND xsa.expense_code_combination_id = deprn_acct_code.code_combination_id'
                    ||chr(10)|| 'AND xsa.whatif_request_id = ' || gn_whatif_request_id
                    ||chr(10)|| 'AND xsa.book_type_code = ''' || gv_book_type_code || ''' '
                    ||chr(10)|| 'ORDER BY xsa.book_type_code'
                    ||chr(10)|| '        ,xsa.asset_number'
                    ||chr(10) ;
--
--
-- SQL確認用 Debug
--FND_FILE.PUT_LINE(
--   which  => FND_FILE.LOG
--  ,buff   => 'debug //// lv_sql_str' || chr(10) || lv_sql_str
--);
--
    ------------------------------
    -- 2.SQL文実行
    ------------------------------
    li_cid := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(li_cid, lv_sql_str, DBMS_SQL.NATIVE);
    DBMS_SQL.DEFINE_ARRAY(li_cid, 1, l_sql_val_tab, cn_fetch_size, 1);
    li_row := DBMS_SQL.EXECUTE(li_cid);
    << sql_fetch_loop >>
    LOOP
      li_row := DBMS_SQL.FETCH_ROWS(li_cid);
      DBMS_SQL.COLUMN_VALUE(li_cid, 1, l_sql_val_tab);
      EXIT WHEN li_row != cn_fetch_size ;
    END LOOP sql_fetch_loop ;
    --
    -- カーソルクローズ
    DBMS_SQL.close_cursor(li_cid);
    --
    -- 対象件数
    gn_target_cnt := l_sql_val_tab.COUNT ;
--
    -- ===============================
    -- CSV出力(A-3)
    -- ===============================
    << file_output_loop >>
    FOR k IN 1..l_sql_val_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => l_sql_val_tab(k)
      );
      gn_normal_cnt := gn_normal_cnt + 1 ;
    END LOOP file_output_loop ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_whatif_request_id            IN  VARCHAR2     -- 1.WHATIFリクエストID
    ,iv_period_date                  IN  VARCHAR2     -- 2.開始期間
    ,iv_num_periods                  IN  VARCHAR2     -- 3.期間数
    ,ov_errbuf                       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    ,ov_retcode                      OUT VARCHAR2     -- リターン・コード             --# 固定 #
    ,ov_errmsg                       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_whatif_request_id           => iv_whatif_request_id           -- 1.WHATIFリクエストID
      ,iv_period_date                 => iv_period_date                 -- 2.開始期間
      ,iv_num_periods                 => iv_num_periods                 -- 3.期間数
      ,ov_errbuf                      => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode                     => lv_retcode                     -- リターン・コード             --# 固定 #
      ,ov_errmsg                      => lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE subprocedure_warn_expt;
    END IF;
--
    -- ===============================
    -- データ抽出処理(A-2)、CSV出力(A-3)
    -- ===============================
    output_csv(
      ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE subprocedure_warn_expt;
    END IF;
--
  EXCEPTION
    -- 対象データなし警告
    WHEN subprocedure_warn_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
    errbuf                          OUT    VARCHAR2      -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2      -- エラーコード     #固定#
   ,iv_whatif_request_id            IN     VARCHAR2      -- 1.WHATIFリクエストID (数値)
   ,iv_period_date                  IN     VARCHAR2      -- 2.開始期間 (YYYY-MM)
   ,iv_num_periods                  IN     VARCHAR2      -- 3.期間数 (数値)
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_whatif_request_id           => iv_whatif_request_id           -- 1.WHATIFリクエストID
      ,iv_period_date                 => iv_period_date                 -- 2.開始期間
      ,iv_num_periods                 => iv_num_periods                 -- 3.期間数
      ,ov_errbuf                      => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode                     => lv_retcode                     -- リターン・コード             --# 固定 #
      ,ov_errmsg                      => lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- 対象件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- 成功件数出力
    --==================================================
    IF( lv_retcode = cv_status_error )
    THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- エラー件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal)
    THEN
      lv_message_code := cv_msg_cff_90004;
    ELSIF(lv_retcode = cv_status_warn)
    THEN
      lv_message_code := cv_msg_cff_90005;
    ELSIF(lv_retcode = cv_status_error)
    THEN
      lv_message_code := cv_msg_cff_90006;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error)
    THEN
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
END XXCFF018A01C;
/
