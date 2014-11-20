CREATE OR REPLACE PACKAGE BODY XXCFO008A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO008A02C(body)
 * Description      : 回収入金銀行預け入れ照合データ作成
 * MD.050           : 回収入金銀行預け入れ照合データ作成 MD050_CFO_008_A02
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_target_data        対象データ取得(A-2)
 *  output_std             データ出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/02/12    1.0  SCSK 石渡 賢和    新規作成
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100)      := 'XXCFO008A02C';                       -- パッケージ名
--
  -- ファイル出力
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';                             -- メッセージ出力
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';                                -- ログ出力
--
  -- 書式フォーマット
  cv_format_date_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                         -- 日付フォーマット（YYYY/MM/DD）
  cv_format_date_ym     CONSTANT VARCHAR2(10)  := 'YYYY-MM';                            -- 日付フォーマット（YYYY-MM）
--
  cd_min_date           CONSTANT DATE          := TO_DATE('1900/01/01','YYYY/MM/DD');   -- 最小日付
  cd_max_date           CONSTANT DATE          := TO_DATE('9999/12/31','YYYY/MM/DD');   -- 最大日付
  cv_userenv_lang       CONSTANT VARCHAR2(10)  := USERENV('LANG');                      -- 言語
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                                  -- フラグ「Y」
  cv_sqlgl              CONSTANT VARCHAR2(20)  := 'SQLGL';                              -- GLアプリケーション短縮名
  cv_msg_kbn_cfo        CONSTANT VARCHAR2(20)  := 'XXCFO';                              -- XXCFOアプリケーション短縮名
  cv_delimit            CONSTANT VARCHAR2(10)  := ',';                                  -- 区切り文字
  cv_enclosed           CONSTANT VARCHAR2(2)   := '"';                                  -- 単語囲み文字
  cv_code_001           CONSTANT VARCHAR2(3)   := '001';                                -- コード「001」
  cv_code_002           CONSTANT VARCHAR2(3)   := '002';                                -- コード「002」
  cv_code_003           CONSTANT VARCHAR2(3)   := '003';                                -- コード「003」
--
  -- プロファイル名
  cv_set_of_books_id    CONSTANT VARCHAR2(20) := 'GL_SET_OF_BKS_ID';                    -- プロファイル：会計帳簿ID
  cv_sys_cal_code       CONSTANT VARCHAR2(20) := 'XXCFO1_SYS_CAL_CODE';                 -- プロファイル：XXCFO:システム稼働日カレンダコード
  --
  -- 参照タイプ
  cv_008a02c_cond_mst   CONSTANT VARCHAR2(30)  := 'XXCFO_008A02C_COND_MST';              -- 回収入金銀行預け入れデータ特定マスタ
  cv_type_csv_header    CONSTANT VARCHAR2(100) := 'XXCFO1_CSV_HEADER';                   --エクセル出力用見出し
--
  -- メッセージ番号
  cv_msg_prof_err       CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';                    -- プロファイル取得エラーメッセージ
  cv_msg_no_data_err    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004';                    -- 対象データ取得エラーメッセージ
  cv_msg_no_data_err2   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00032';                    -- データ取得エラーメッセージ
  cv_msg_sale_count     CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00042';                    -- 売上金額件数メッセージ
  cv_msg_fieldwork_cnt  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00043';                    -- 現金実査件数メッセージ
  cv_msg_deposit_cnt    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00044';                    -- 預入金額件数メッセージ
  cv_msg_gl_appl_id     CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00045';                    -- GLアプリケーションIDメッセージ
  -- トークンコード
  cv_tkn_prof           CONSTANT VARCHAR2(10) := 'PROF_NAME';
  cv_tkn_data           CONSTANT VARCHAR2(10) := 'DATA';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 件数
  gn_sale_amount_cnt        NUMBER;                                        -- 売上金額件数
  gn_fieldwork_amount_cnt   NUMBER;                                        -- 現金実査件数
  gn_deposit_amount_cnt     NUMBER;                                        -- 預入金額件数
  --
  gn_set_of_books_id        NUMBER;                                        -- 会計帳簿ID
  gv_sys_cal_code           bom_calendar_dates.calendar_code%TYPE;         -- システム稼動日カレンダーコード
  gn_gl_application_id      fnd_application.application_id%TYPE;           -- GLアプリケーションID
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 対象データ取得カーソル
  CURSOR get_target_data_cur(  iv_base_code   gl_code_combinations.segment2%TYPE
                              ,iv_period_name gl_period_statuses.period_name%TYPE
                            )
  IS
    SELECT
       iv_base_code                                     AS  base_code                    -- 拠点コード
      ,TO_CHAR(bcd.calendar_date, cv_format_date_ymd )  AS  calendar_date                -- 日付
      ,sales_v.amount                                   AS  sale_amount                  -- 売上金額
      ,jissa.amount                                     AS  fieldwork_amount             -- 現金実査
      ,payment.amount*-1                                AS  deposit_amount               -- 預入金額
    FROM
       bom_calendar_dates   bcd                                  -- 稼働日カレンダー
      ,gl_period_statuses   gps                                  -- 会計期間テーブル
      ,(
        SELECT /*+ USE_NL(gjh1 gjl1 gcc1) */
          gjl1.effective_date                                   AS effective_date
         ,SUM(NVL(gjl1.entered_dr,0) - NVL(gjl1.entered_cr,0))  AS amount
        FROM
          gl_je_headers        gjh1
         ,gl_je_lines          gjl1
         ,gl_code_combinations gcc1
         ,fnd_lookup_values    flv1
        WHERE
            gjh1.je_header_id        = gjl1.je_header_id
        AND gjh1.period_name         = gjl1.period_name
        AND gjl1.code_combination_id = gcc1.code_combination_id
        AND flv1.lookup_type         = cv_008a02c_cond_mst                  -- 回収入金銀行預け入れデータ特定マスタ
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    >= NVL(flv1.start_date_active ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    <= NVL(flv1.end_date_active   ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND flv1.enabled_flag        = cv_y
        AND flv1.language            = cv_userenv_lang
        AND flv1.lookup_code         = cv_code_001
        AND gjh1.set_of_books_id     = gn_set_of_books_id
        AND gjh1.period_name         = iv_period_name                       -- 会計期間（YYYY-MM）
        AND gcc1.segment1            = flv1.attribute1                      -- 会社コード
        AND gcc1.segment2            = iv_base_code                         -- 部門コード
        AND gcc1.segment3            = flv1.attribute2                      -- 勘定科目：11104（現金）
        AND gjh1.je_source           IN (flv1.attribute3, flv1.attribute4)  -- 仕訳作成ソース：4（販売実績）、Receivables（売掛管理）
        AND gjh1.actual_flag         = 'A'                       -- 実績
        AND gjl1.status              = 'P'                       -- 転記
        GROUP BY
          gjl1.effective_date
      ) sales_v                                                             -- 売上金額インラインビュー
      ,(
        SELECT /*+ USE_NL(gjh2 gjl2 gcc2) */
         gjl2.effective_date                                   AS effective_date
        ,SUM(NVL(gjl2.entered_dr,0) - NVL(gjl2.entered_cr,0))   AS amount
        from
          gl_je_headers        gjh2
         ,gl_je_lines          gjl2
         ,gl_code_combinations gcc2
         ,fnd_lookup_values    flv2
        WHERE
            gjh2.je_header_id        = gjl2.je_header_id
        AND gjh2.period_name         = gjl2.period_name
        AND gjl2.code_combination_id = gcc2.code_combination_id
        AND flv2.lookup_type         = cv_008a02c_cond_mst                  -- 回収入金銀行預け入れデータ特定マスタ
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    >= NVL(flv2.start_date_active ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    <= NVL(flv2.end_date_active   ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND flv2.enabled_flag        = cv_y
        AND flv2.language            = cv_userenv_lang
        AND flv2.lookup_code         = cv_code_002
        AND gjh2.set_of_books_id     = gn_set_of_books_id
        AND gjh2.period_name         = iv_period_name            -- 会計期間（YYYY-MM）
        AND gcc2.segment1            = flv2.attribute1           -- 会社コード
        AND gcc2.segment2            = iv_base_code              -- 部門コード
        AND gcc2.segment3            = flv2.attribute2           -- 勘定科目：14917（現預金実査仮勘定）
        AND gjh2.je_source           = flv2.attribute3           -- 仕訳作成ソース：1（GL部門入力）
        AND gjh2.actual_flag         = 'A'                       -- 実績
        AND gjl2.status              = 'P'                       -- 転記
        GROUP BY
          gjl2.effective_date
      ) jissa
      ,(
        SELECT /*+ USE_NL(gjh3 gjl3 gcc3) */
          gjl3.effective_date                                   AS effective_date
         ,SUM(NVL(gjl3.entered_dr,0) - NVL(gjl3.entered_cr,0))  AS amount
        FROM
          gl_je_headers        gjh3
         ,gl_je_lines          gjl3
         ,gl_code_combinations gcc3
         ,fnd_lookup_values    flv3
        WHERE
            gjh3.je_header_id        = gjl3.je_header_id
        AND gjh3.period_name         = gjl3.period_name
        AND gjl3.code_combination_id = gcc3.code_combination_id
        AND flv3.lookup_type         = cv_008a02c_cond_mst                  -- 回収入金銀行預け入れデータ特定マスタ
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    >= NVL(flv3.start_date_active ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    <= NVL(flv3.end_date_active   ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND flv3.enabled_flag        = cv_y
        AND flv3.language            = cv_userenv_lang
        AND flv3.lookup_code         = cv_code_003
        AND gjh3.set_of_books_id     = gn_set_of_books_id
        AND gjh3.period_name         = iv_period_name            -- 会計期間（YYYY-MM）
        AND gcc3.segment1            = flv3.attribute1           -- 会社コード
        AND gcc3.segment2            = iv_base_code              -- 部門コード
        AND gcc3.segment3            = flv3.attribute2           -- 勘定科目：11104（現金）
        AND gjh3.je_source           = flv3.attribute3           -- 仕訳作成ソース：1（GL部門入力）
        AND gjl3.description      LIKE flv3.attribute5           -- %預け入れ%
        AND gjh3.actual_flag         = 'A'                       -- 実績
        AND gjl3.status              = 'P'                       -- 転記
        GROUP BY
          gjl3.effective_date
      ) payment
    WHERE
        gps.start_date    <= bcd.calendar_date
    AND gps.end_date      >= bcd.calendar_date
    AND bcd.calendar_code  = gv_sys_cal_code
    AND gps.period_name    = iv_period_name                      -- 会計期間（YYYY-MM）
    AND gps.application_id = gn_gl_application_id
    AND bcd.calendar_date  = sales_v.effective_date(+)
    AND bcd.calendar_date  = jissa.effective_date(+)
    AND bcd.calendar_date  = payment.effective_date(+)
    ORDER BY
    bcd.calendar_date
    ;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 対象データ取得カーソルレコード型
  TYPE g_target_data_ttype IS TABLE OF get_target_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_target_data_tab       g_target_data_ttype;
  
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code   IN VARCHAR2,     --   1.拠点コード
    iv_period_name IN VARCHAR2,     --   2.対象年月
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- コンカレントパラメータ出力
    --==============================================================
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,iv_conc_param1  => iv_period_name     -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_base_code       -- コンカレントパラメータ２
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
--
    --==============================================================
    -- プロファイルオプション値の取得
    --==============================================================
    -- プロファイル：会計帳簿ID
    gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_books_id ) );
    -- 取得エラー時
    IF ( gn_set_of_books_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_prof_err      -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_set_of_books_id); -- トークン：SET_OF_BOOKS_ID
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- プロファイル：XXCFO:システム稼働日カレンダコード
    gv_sys_cal_code := FND_PROFILE.VALUE( cv_sys_cal_code );
    -- 取得エラー時
    IF ( gv_sys_cal_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_prof_err      -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_sys_cal_code);    -- トークン：XXCFO1_SYS_CAL_CODE
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- GLアプリケーションIDの取得
    --==============================================================
    BEGIN
      SELECT fa.application_id
      INTO   gn_gl_application_id
      FROM   fnd_application fa
      WHERE  fa.application_short_name = cv_sqlgl
      ;
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_no_data_err2  -- メッセージ：APP-XXCFO1-00032
                                           ,iv_token_name1  => cv_tkn_data          -- トークンコード
                                           ,iv_token_value1 => cv_msg_gl_appl_id);  -- トークン：APP-XXCFO1-00045
      lv_errbuf := SQLERRM;
      --
      RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_target_data
   * Description      : 対象データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    iv_base_code   IN VARCHAR2,     --   1.拠点コード
    iv_period_name IN VARCHAR2,     --   2.対象年月
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_data'; -- プログラム名
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 対象データ取得カーソル
    OPEN  get_target_data_cur( iv_base_code
                              ,iv_period_name
                             );
    FETCH get_target_data_cur BULK COLLECT INTO gt_target_data_tab;
    CLOSE get_target_data_cur;
--
    --対象件数セット
    gn_target_cnt := gt_target_data_tab.COUNT;
    -- ０件警告時
    IF ( gt_target_data_tab.COUNT = 0 ) THEN
      gn_warn_cnt := 1;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                            ,iv_name         => cv_msg_no_data_err   -- メッセージ：APP-XXCFO1-00004
                                            ); 
      ov_errbuf  := lv_errmsg;
      ov_retcode := cv_status_warn;
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
      IF( get_target_data_cur%ISOPEN ) THEN
        CLOSE get_target_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : データ出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    iv_period_name                  IN     VARCHAR2,  -- 2.対象年月
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_line_data            VARCHAR2(5000);         -- OUTPUTデータ編集用
--
    -- *** ローカル・カーソル ***
    --見出し取得用カーソル
    CURSOR get_csv_header_cur
    IS
      SELECT  flv.description  head
      FROM    fnd_lookup_values flv
      WHERE   flv.language      = cv_userenv_lang
      AND     flv.lookup_type   = cv_type_csv_header
      AND     TO_DATE( iv_period_name, cv_format_date_ym ) 
                               >= NVL( flv.start_date_active, TO_DATE( iv_period_name, cv_format_date_ym ) )
      AND     TO_DATE( iv_period_name, cv_format_date_ym ) 
                               <= NVL( flv.end_date_active,   TO_DATE( iv_period_name, cv_format_date_ym ) )
      AND     flv.enabled_flag  = cv_y
      ORDER BY
              flv.lookup_code
      ;
    --見出し
    TYPE l_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    lt_head_tab l_head_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------
    -- 見出しの出力
    ------------------------------------------
    -- データの見出しを取得
    OPEN  get_csv_header_cur;
    FETCH get_csv_header_cur BULK COLLECT INTO lt_head_tab;
    CLOSE get_csv_header_cur;
--
    --データの見出しを編集
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --データの見出しを出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- データ出力
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_target_data_tab.COUNT LOOP
      --データを編集
      lv_line_data :=     cv_enclosed || gt_target_data_tab(i).base_code           || cv_enclosed  -- 拠点コード
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).calendar_date       || cv_enclosed  -- 日付
         || cv_delimit                || gt_target_data_tab(i).sale_amount                         -- 売上金額
         || cv_delimit                || gt_target_data_tab(i).fieldwork_amount                    -- 現金実査
         || cv_delimit                || gt_target_data_tab(i).deposit_amount                      -- 預入金額
      ;
      --データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
      --各件数のカウント(0円以外の場合にカウント)
      IF ( gt_target_data_tab(i).sale_amount      <> 0 )  THEN
        gn_sale_amount_cnt := gn_sale_amount_cnt + 1;                -- 売上金額件数
      END IF;
      IF ( gt_target_data_tab(i).fieldwork_amount <> 0 )  THEN
        gn_fieldwork_amount_cnt := gn_fieldwork_amount_cnt + 1;      -- 現金実査件数
      END IF;
      IF ( gt_target_data_tab(i).deposit_amount   <> 0 )  THEN
        gn_deposit_amount_cnt := gn_deposit_amount_cnt + 1;          -- 預入金額件数
      END IF;
--
    END LOOP data_output;
    --
    -- ０件警告時
    IF ( gn_sale_amount_cnt + gn_fieldwork_amount_cnt + gn_deposit_amount_cnt = 0 ) THEN
      gn_warn_cnt := 1;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                            ,iv_name         => cv_msg_no_data_err   -- メッセージ：APP-XXCFO1-00004
                                            ); 
      ov_errbuf  := lv_errmsg;
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
      IF( get_csv_header_cur%ISOPEN ) THEN
        CLOSE get_csv_header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code   IN VARCHAR2,     --   1.拠点コード
    iv_period_name IN VARCHAR2,     --   2.対象年月
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    gn_sale_amount_cnt      := 0;
    gn_fieldwork_amount_cnt := 0;
    gn_deposit_amount_cnt   := 0;
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  初期処理 (A-1)
    -- =====================================================
    init(
       iv_base_code       => iv_base_code           -- 1.拠点コード
      ,iv_period_name     => iv_period_name         -- 2.対象年月
      ,ov_errbuf          => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数のカウント
      gn_error_cnt := 1;
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  対象データ取得 (A-2)
    -- =====================================================
    get_target_data(
       iv_base_code       => iv_base_code           -- 1.拠点コード
      ,iv_period_name     => iv_period_name         -- 2.対象年月
      ,ov_errbuf          => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数のカウント
      gn_error_cnt := 1;
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    -- データ出力 (A-3)
    -- ===============================
    output_data(
       iv_period_name     => iv_period_name         -- 2.対象年月
      ,ov_errbuf          => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数のカウント
      gn_error_cnt := 1;
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    --
    ov_errmsg  := lv_errmsg;
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
--
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_period_name IN VARCHAR2,      --   1.対象年月
    iv_base_code   IN VARCHAR2       --   2.拠点コード
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
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
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
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
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
       iv_base_code    -- 拠点コード
      ,iv_period_name  -- 対象年月
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
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
         which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --売上金額件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_sale_count
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_sale_amount_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --現金実査件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_fieldwork_cnt
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_fieldwork_amount_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --預入金額件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_deposit_cnt
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_deposit_amount_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
END XXCFO008A02C;
/
