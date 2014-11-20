CREATE OR REPLACE PACKAGE BODY XXCFO002A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2013. All rights reserved.
 *
 * Package Name     : XXCFO002A02C(body)
 * Description      : 未承認経費支払依頼データ抽出
 * MD.050           : 未承認経費支払依頼データ抽出 MD050_CFO_002_A02
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_target_data        対象データ取得(A-2)
 *  output_data            データ出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/10/15    1.0   SCSK 中野 徹也   新規作成
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
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFO002A02C'; -- パッケージ名
--
  -- ファイル出力
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';                             -- メッセージ出力
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';                                -- ログ出力
--
  -- 書式フォーマット
  cv_format_date_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                         -- 日付フォーマット（YYYY/MM/DD）
--
  cd_min_date           CONSTANT DATE          := TO_DATE('1900/01/01','YYYY/MM/DD');   -- 最小日付
  cd_max_date           CONSTANT DATE          := TO_DATE('9999/12/31','YYYY/MM/DD');   -- 最大日付
  cv_userenv_lang       CONSTANT VARCHAR2(10)  := USERENV('LANG');                      -- 言語
  cv_yes                CONSTANT VARCHAR2(1)   := 'Y';                                  -- フラグ「Y」
  cv_msg_kbn_cfo        CONSTANT VARCHAR2(20)  := 'XXCFO';                              -- XXCFOアプリケーション短縮名
  cv_delimit            CONSTANT VARCHAR2(10)  := ',';                                  -- 区切り文字
  cv_enclosed           CONSTANT VARCHAR2(1)   := '"';                                  -- 単語囲み文字
  cv_hihun              CONSTANT VARCHAR2(1)   := '-';                                  -- ハイフン
  cv_pending_status     CONSTANT VARCHAR2(10)  := '30';                                 -- 30：部門最終承認待
  cv_language_ja        CONSTANT VARCHAR2(10)  := 'JA';                                 -- 抽出条件文字列'JA'
  --プロファイル
  cv_org_id             CONSTANT VARCHAR2(30)  := 'ORG_ID';                             -- 組織ID
--
  -- 参照タイプ
  cv_xx03_slip_type     CONSTANT VARCHAR2(30)  := 'XX03_SLIP_TYPES';                    -- 伝票種別
  cv_type_csv_header    CONSTANT VARCHAR2(30)  := 'XXCFO1_PAY_SLIP_HEAD';               -- エクセル出力用見出し
  cv_msg_token_001      CONSTANT VARCHAR2(30)  := 'CFO002A02001';                       -- メッセージトークン：請求書日付（自）
  cv_msg_token_002      CONSTANT VARCHAR2(30)  := 'CFO002A02002';                       -- メッセージトークン：請求書日付（至）
--
  -- メッセージ番号
  cv_msg_cfo_00015      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015';                    -- 業務日付取得エラーメッセージ
  cv_msg_cfo_00033      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00033';                    -- コンカレントパラメータエラーメッセージ
  cv_msg_prof_err       CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';                    -- プロファイル取得エラーメッセージ
  cv_msg_no_data_err    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004';                    -- 対象データなしエラーメッセージ
--
  -- トークンコード
  cv_tkn_prof            CONSTANT VARCHAR2(10) := 'PROF_NAME';        -- プロファイルチェック
  cv_tkn_param_name_from CONSTANT VARCHAR2(15) := 'PARAM_NAME_FROM';  -- 大小チェックFrom 文字用
  cv_tkn_param_name_to   CONSTANT VARCHAR2(15) := 'PARAM_NAME_TO';    -- 大小チェックTo 文字用
  cv_tkn_param_val_from  CONSTANT VARCHAR2(15) := 'PARAM_VAL_FROM';   -- 大小チェックFrom 値用
  Cv_tkn_param_val_to    CONSTANT VARCHAR2(15) := 'PARAM_VAL_TO';     -- 大小チェックTo 値用
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
   gd_process_date            DATE;                                                     -- 業務日付
   gn_org_id                  NUMBER;                                                   -- 組織ID
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 対象データ取得カーソル
  CURSOR get_target_data_cur(  iv_invoice_date_from  VARCHAR2
                              ,iv_invoice_date_to    VARCHAR2
                            )
  IS
  SELECT /*+ USE_NL( xps flv papf xadv )
             INDEX( xps XX03_PAYMENT_SLIPS_N15 )
             USE_NL( xadv.FFLEXVALSET xadv.FFLEXVAL xadv.FFLEXVALTL )
             LEADING( xps ) */
        xps.entry_department || cv_hihun 
            || xadv.aff_department_name   AS entry_department       -- 起票部門
       ,xps.requestor_person_name         AS requestor_person_name  -- 申請者
       ,xps.approver_person_name          AS approver_person_name   -- 承認者
       ,xps.invoice_num                   AS invoice_num            -- 伝票番号
       ,flv.description                   AS invoice_class          -- 伝票種別
       ,xps.vendor_name                   AS vendor_name            -- 仕入先
       ,xps.vendor_invoice_num            AS vendor_invoice_num     -- 受領請求書番号
       ,TO_CHAR(xps.invoice_date, cv_format_date_ymd)  AS invoice_date  -- 請求書日付
       ,TO_CHAR(xps.gl_date, cv_format_date_ymd)       AS gl_date       -- 計上日
       ,xps.inv_amount                    AS inv_amount             -- 合計金額
       ,xps.invoice_currency_code         AS invoice_currency_code  -- 通貨
  FROM  xx03_payment_slips      xps    -- 支払伝票
       ,fnd_lookup_values       flv    -- 参照タイプ
       ,per_all_people_f        papf   -- 従業員マスタ
       ,xxcff_aff_department_v  xadv   -- 部門VIEW
  WHERE xps.org_id       = gn_org_id
  AND   xps.wf_status    = cv_pending_status  -- ステータス:30(部門最終承認待)
  AND   xps.slip_type    = flv.lookup_code
  AND   flv.lookup_type  = cv_xx03_slip_type  -- 伝票種別
  AND   flv.language     = cv_language_ja
  AND   flv.enabled_flag = cv_yes
  AND   NVL(flv.start_date_active, xps.entry_date ) <= xps.entry_date
  AND   NVL(flv.end_date_active, xps.entry_date )   >= xps.entry_date
  AND   papf.person_id   = xps.entry_person_id
  AND   papf.effective_start_date <= xps.entry_date
  AND   papf.effective_end_date   >= xps.entry_date
  AND   xadv.aff_department_code   = xps.entry_department
  AND   NVL(xadv.start_date_active, xps.entry_date) <= xps.entry_date
  AND   NVL(xadv.end_date_active,   xps.entry_date) >= xps.entry_date
  AND   NVL(TO_DATE(iv_invoice_date_from, cv_format_date_ymd), xps.invoice_date)
                                      <= xps.invoice_date  -- パラメータ請求書日（自）
  AND   NVL(TO_DATE(iv_invoice_date_to, cv_format_date_ymd), xps.invoice_date)
                                      >= xps.invoice_date  -- パラメータ請求書日（至）
  ORDER BY
        xps.entry_department  -- 起票部門コード
       ,papf.employee_number  -- 申請者社員番号
       ,xps.invoice_num       -- 伝票番号
  ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 対象データ取得カーソルレコード型
  TYPE g_target_data_ttype IS TABLE OF get_target_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_target_data_tab       g_target_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_invoice_date_from IN  VARCHAR2,     --   1.請求書日付(from)
    iv_invoice_date_to   IN  VARCHAR2,     --   2.請求書日付(to)
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
       iv_which        => cv_file_type_log     -- ログ出力
      ,iv_conc_param1  => iv_invoice_date_from -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_invoice_date_to   -- コンカレントパラメータ２
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 業務日付取得
    --==================================
--
    -- 共通関数から業務日付を取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 取得エラー時
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- アプリケーション短縮名
                                            ,cv_msg_cfo_00015);    -- メッセージ：APP-XXCFO1-00015
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- プロファイル組織ID取得
    --==============================================================
--
    -- プロファイルから組織ID取得
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_prof_err      -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_org_id);          -- トークン：ORG_ID
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- コンカレントパラメータチェック
    --==============================================================
--
    -- パラメータ請求書日付(from)と請求書日付(to)のチェック
    IF ( iv_invoice_date_from > iv_invoice_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo               -- アプリケーション短縮名：XXCFO
                                            ,cv_msg_cfo_00033             -- 値大小チェックエラー
                                            ,cv_tkn_param_name_from       -- トークン'PARAM_NAME_FROM'
                                            ,xxcfr_common_pkg.lookup_dictionary(
                                               cv_msg_kbn_cfo
                                              ,cv_msg_token_001
                                             )                            -- 請求書日付（自）
                                            ,cv_tkn_param_name_to         -- トークン'PARAM_NAME_TO'
                                            ,xxcfr_common_pkg.lookup_dictionary(
                                               cv_msg_kbn_cfo
                                              ,cv_msg_token_002
                                             )                            -- 請求書日付（至）
                                            ,cv_tkn_param_val_from        -- トークン'PARAM_VAL_FROM'
                                            ,iv_invoice_date_from         -- パラメータ：請求書日付（自）
                                            ,cv_tkn_param_val_to          -- トークン'PARAM_VAL_TO'
                                            ,iv_invoice_date_to           -- パラメータ：請求書日付（至）
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
    iv_invoice_date_from IN VARCHAR2,      --   1.請求書日付(from)
    iv_invoice_date_to   IN VARCHAR2,      --   2.請求書日付(to)
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
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
    OPEN  get_target_data_cur( iv_invoice_date_from
                              ,iv_invoice_date_to
                             );
    FETCH get_target_data_cur BULK COLLECT INTO gt_target_data_tab;
    CLOSE get_target_data_cur;
--
    --対象件数セット
    gn_target_cnt := gt_target_data_tab.COUNT;
--
    -- 対象件数0件の場合、警告
    IF ( gt_target_data_tab.COUNT = 0 ) THEN
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
      SELECT  flv.description   head
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type  = cv_type_csv_header
      AND     flv.language     = cv_language_ja
      AND     flv.enabled_flag = cv_yes
      AND     NVL(flv.start_date_active, gd_process_date ) <= gd_process_date
      AND     NVL(flv.end_date_active, gd_process_date )   >= gd_process_date
      ORDER BY
              flv.lookup_code
      ;
    -- 見出し用変数定義
    TYPE l_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
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
      lv_line_data :=     cv_enclosed || gt_target_data_tab(i).entry_department           || cv_enclosed  -- 起票部門
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).requestor_person_name      || cv_enclosed  -- 申請者
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).approver_person_name       || cv_enclosed  -- 承認者
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).invoice_num                || cv_enclosed  -- 伝票番号
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).invoice_class              || cv_enclosed  -- 伝票種別
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).vendor_name                || cv_enclosed  -- 仕入先
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).vendor_invoice_num         || cv_enclosed  -- 受領請求書番号
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).invoice_date               || cv_enclosed  -- 請求書日付
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).gl_date                    || cv_enclosed  -- 計上日
         || cv_delimit                || gt_target_data_tab(i).inv_amount                                 -- 合計金額
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).invoice_currency_code      || cv_enclosed  -- 通貨
      ;
      --データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
    --
    END LOOP data_output;
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_invoice_date_from IN  VARCHAR2,     --   1.請求書日付(from)
    iv_invoice_date_to   IN  VARCHAR2,     --   2.請求書日付(to)
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- 初期処理 (A-1)
    -- ===============================
    init(
       iv_invoice_date_from  => iv_invoice_date_from  -- 1.請求書日付(from)
      ,iv_invoice_date_to    => iv_invoice_date_to    -- 2.請求書日付(to)
      ,ov_errbuf             => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode            => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg             => lv_errmsg );          -- ユーザー・エラー・メッセージ --# 固定 #
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
       iv_invoice_date_from  => iv_invoice_date_from  -- 1.請求書日付(from)
      ,iv_invoice_date_to    => iv_invoice_date_to    -- 2.請求書日付(to)
      ,ov_errbuf             => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode            => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg             => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数のカウント
      gn_error_cnt := 1;
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn ) THEN
      -- 警告の場合、ステータスとメッセージを制御
      ov_errbuf   := lv_errbuf;
      ov_retcode  := lv_retcode;
      ov_errmsg   := lv_errmsg;
    END IF;
    --
--
    -- =====================================================
    --  データ出力 (A-3)
    -- =====================================================
    output_data(
       ov_errbuf             => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode            => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg             => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数のカウント
      gn_error_cnt := 1;
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
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
    errbuf                OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode               OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_invoice_date_from  IN  VARCHAR2,      --   1.請求書日付(from)
    iv_invoice_date_to    IN  VARCHAR2       --   2.請求書日付(to)
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
       iv_invoice_date_from    -- 1.請求書日付(from)
      ,iv_invoice_date_to      -- 2.請求書日付(to)
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
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
END XXCFO002A02C;
/
