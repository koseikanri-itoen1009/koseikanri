CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A08C (spec)
 * Description      : 販売控除データCSV出力
 * MD.050           : 販売控除データCSV出力 MD050_COS_024_A08
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_order_list_cond    販売控除データ抽出(A-2)
 *  output_data            データ出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/09/20    1.0   H.Ishii          新規作成
 *
 *****************************************************************************************/
--
--#############################  固定グローバル定数宣言部 START  #############################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--#######################################  固定部 END  #######################################
--
--#############################  固定グローバル変数宣言部 START  #############################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
--
--#######################################  固定部 END  #######################################
--
--################################  固定共通例外宣言部 START  ################################
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
--#######################################  固定部 END  #######################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 出力日 日付逆転チェック例外 ***
  global_date_rever_old_chk_expt    EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) :=  'XXCOK024A08C';        -- パッケージ名
  cv_xxcok_short_name       CONSTANT  VARCHAR2(100) :=  'XXCOK';               -- 販物領域短縮アプリ名
  --メッセージ
  cv_msg_date_rever_err     CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10569';    -- 日付逆転エラーメッセージ
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10570';    -- 業務日付取得エラーメッセージ
  cv_msg_parameter          CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10571';    -- パラメータ出力メッセージ
  --トークン名
  cv_tkn_nm_base_code       CONSTANT  VARCHAR2(100) :=  'BASE_CODE';           -- 拠点コード
  cv_tkn_nm_date_from       CONSTANT  VARCHAR2(100) :=  'DATE_FROM';           -- 出力日(FROM)
  cv_tkn_nm_date_to         CONSTANT  VARCHAR2(100) :=  'DATE_TO';             -- 出力日(TO)
  --トークン値
  cv_msg_vl_order_li_from   CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10572';    -- 出力日(FROM)
  cv_msg_vl_order_li_to     CONSTANT  VARCHAR2(100) :=  'APP-XXCOK1-10573';    -- 出力日(TO)
  --受注一覧出力管理テーブル取得用
  cv_class_base             CONSTANT  VARCHAR2(2)   := '1';                    -- 顧客区分:拠点
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date              DATE;                                              -- 業務日付
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  -- 販売控除マスタ情報取得
  CURSOR get_order_list_data_cur(
           ip_customer_code           VARCHAR   -- 顧客番号
          ,ip_order_list_date_from    DATE      -- 出力日(FROM)
          ,ip_order_list_date_to      DATE      -- 出力日(TO)
          )
  IS
    SELECT xsdh.origin_kind                         AS origin_kind                            -- 作成元区分
          ,xsdh.deduction_no                        AS deduction_no                           -- 控除No.
          ,xsdh.customer_code                       AS customer_code                          -- 顧客番号
          ,xsdh.base_code                           AS base_code                              -- 拠点
          ,xsdh.condition_kind                      AS condition_kind                         -- 控除区分
          ,xsdh.condition_type                      AS condition_type                         -- 控除タイプ
          ,xsdh.data_type                           AS data_type                              -- データ種類
          ,xsdh.record_date                         AS record_date                            -- 計上日
          ,xsdh.condition_no                        AS condition_no                           -- 控除条件No.
          ,xsdl.deduction_no                        AS deduction_no                           -- 販売控除明細No.
          ,xsdl.condition_line_no                   AS condition_line_no                      -- 控除条件明細No.
          ,xsdl.status                              AS status                                 -- ステータス
          ,xsdl.item_code                           AS item_code                              -- 品目コード
          ,xsdl.quantity                            AS quantity                               -- 数量
          ,xsdl.uom_code                            AS uom_code                               -- 単位
          ,xsdl.unit_price                          AS unit_price                             -- 単価
          ,xsdl.deduction_unit_price                AS deduction_unit_price                   -- 控除単価
          ,xsdl.deduction_rate                      AS deduction_rate                         -- 控除率
          ,xsdl.deduction_amount                    AS deduction_amount                       -- 控除額
          ,xsdl.tax_code                            AS tax_code                               -- 税コード
          ,xsdl.tax_rate                            AS tax_rate                               -- 税率
          ,xsdl.tax_amount                          AS tax_amount                             -- 税額
          ,xsdl.accounting subject_kind             AS accounting subject_kind                -- 科目
          ,xsdl.gl_interface_flag                   AS gl_interface_flag                      -- GL連携フラグ
          ,xsdl.product_code                        AS product_code                           -- 製品コード
          ,xsdl.gl_date                             AS gl_date                                -- GL記帳日
          ,xsdl.recovery_date                       AS recovery_date                          -- リカバリー日付
          ,xsdl.canceled_recode_date                AS canceled_recode_date                   -- 取消計上日
      FROM xxcok_sales_deduction_headers xsdh                  -- 販売控除ヘッダ情報
          ,xxcok_sales_deduction_lines   xsdl                  -- 販売控除明細情報
     WHERE xsdh.deduction_header_id        = xsdl.deduction_header_id                        -- 販売控除ヘッダID
       AND xsdh.customer_code           LIKE NVL(ip_customer_code, '%')                      -- パラメータ：顧客番号
       AND xsdh.record_date          BETWEEN ip_order_list_date_from                         -- パラメータ：有効開始日
                                         AND ip_order_list_date_to                           -- パラメータ：有効終了日
    ORDER BY
           -- 伝票番号
          ,xsdh.origin_kind                         -- 作成元区分
          ,xsdh.customer_code                       -- 顧客番号
          ,xsdl.deduction_no                        -- 販売控除明細No
          ,xsdl.product_code                        -- 製品コード
          ,xsdl.condition_line_no                   -- 販売条件明細No
          
  ;
  --取得データ格納変数定義
  TYPE g_out_file_ttype IS TABLE OF get_order_list_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_customer_code                IN     VARCHAR2    -- 1.顧客番号
   ,iv_order_list_date_from         IN     VARCHAR2    -- 2.出力日(FROM)
   ,iv_order_list_date_to           IN     VARCHAR2    -- 3.出力日(TO)
   ,od_order_list_date_from         OUT    DATE        -- 1.出力日(FROM)_チェックOK
   ,od_order_list_date_to           OUT    DATE        -- 2.出力日(TO)_チェックOK
   ,ov_errbuf                       OUT    VARCHAR2    -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2    -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START  ##############################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#######################################  固定部 END  #######################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_para_msg                     VARCHAR2(5000);     -- パラメータ出力メッセージ
    lv_check_d_from                 VARCHAR2(100);      -- 出力日(FROM)文言
    lv_check_d_to                   VARCHAR2(100);      -- 出力日(TO)文言
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##############################  固定ステータス初期化部 START  ##############################
--
    ov_retcode := cv_status_normal;
--
--#######################################  固定部 END  #######################################
--
    --========================================
    -- パラメータ出力処理
    --========================================
    lv_para_msg             :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcok_short_name
     ,iv_name               =>  cv_msg_parameter
     ,iv_token_name1        =>  cv_tkn_nm_base_code
     ,iv_token_value1       =>  iv_customer_code
     ,iv_token_name2        =>  cv_tkn_nm_date_from
     ,iv_token_value2       =>  iv_order_list_date_from
     ,iv_token_name3        =>  cv_tkn_nm_date_to
     ,iv_token_value3       =>  iv_order_list_date_to
    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    od_order_list_date_from   := TO_DATE( iv_order_list_date_from, 'RRRR/MM/DD' );  -- 出力日 (FROM)
    od_order_list_date_to     := TO_DATE( iv_order_list_date_to, 'RRRR/MM/DD' );    -- 出力日(TO)
--
    --========================================
    -- 1.入力パラメータチェック
    --========================================
    -- 出力日(FROM)／ 出力日(TO)  日付逆転チェック
    IF ( od_order_list_date_from > od_order_list_date_to ) THEN
      RAISE global_date_rever_old_chk_expt;
    END IF;
--
    --========================================
    -- 2.業務日付取得処理
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name
       ,iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- ***出力日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_old_chk_expt THEN
      lv_check_d_from         :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name
       ,iv_name               =>  cv_msg_vl_order_li_from
      );
      lv_check_d_to           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name
       ,iv_name               =>  cv_msg_vl_order_li_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name
       ,iv_name               =>  cv_msg_date_rever_err
       ,iv_token_name1        =>  cv_tkn_nm_date_from
       ,iv_token_value1       =>  lv_check_d_from
       ,iv_token_name2        =>  cv_tkn_nm_date_to
       ,iv_token_value2       =>  lv_check_d_to
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--##################################  固定例外処理部 START  ##################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
--#######################################  固定部 END  #######################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_list_cond
   * Description      : 控除マスタデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_list_cond(
    iv_customer_code                IN     VARCHAR2    -- 1.顧客番号
   ,id_order_list_date_from         IN     DATE        -- 2.出力日(FROM)_チェックOK
   ,id_order_list_date_to           IN     DATE        -- 3.出力日(TO)_チェックOK
   ,ov_errbuf                       OUT    VARCHAR2    -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2    -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_list_cond'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START  ##############################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#######################################  固定部 END  #######################################
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
--##############################  固定ステータス初期化部 START  ##############################
--
    ov_retcode := cv_status_normal;
--
--#######################################  固定部 END  #######################################
--
    --対象データ取得
    OPEN get_order_list_data_cur(
             iv_customer_code              -- 顧客番号
            ,id_order_list_date_from,      -- 出力日(FROM)
            ,id_order_list_date_to         -- 出力日(TO)
            );
    FETCH get_order_list_data_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_order_list_data_cur;
    --処理件数カウント
    gn_target_cnt := gt_out_file_tab.COUNT;
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
--#######################################  固定部 END  #######################################
--
  END get_order_list_cond;
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
--############################  固定ローカル定数変数宣言部 START  ############################
--
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#######################################  固定部 END  #######################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ct_enabled_flg_y      CONSTANT  fnd_lookup_values.enabled_flag%TYPE := 'Y';                             -- 使用可能
    cv_lang               CONSTANT  VARCHAR2(100)                       := USERENV( 'LANG' );               -- 言語
    cv_type_header        CONSTANT  VARCHAR2(30)                        := 'XXCOK1_EXCEL_OUTPUT_HEADER_2';  -- 控除マスタ出力用見出し
    cv_code_eoh_024a08    CONSTANT  VARCHAR2(100)                       := '024A08%';                       -- クイックコード（控除マスタ出力用見出し）
    cv_delimit            CONSTANT  VARCHAR2(4)                         := ',';                             -- 区切り文字
    cv_enclosed           CONSTANT  VARCHAR2(4)                         := '"';                             -- 単語囲み文字
--
    -- *** ローカル変数 ***
    lv_line_data            VARCHAR2(5000);         -- OUTPUTデータ編集用
--
    -- *** ローカル・カーソル ***
    --見出し取得用カーソル
    CURSOR header_cur
    IS
      SELECT  flv.description  head                                             -- 摘要：出力用見出し
      FROM    fnd_lookup_values flv
      WHERE   flv.language        = cv_lang                                     -- 言語
      AND     flv.lookup_type     = cv_type_header                              -- 控除マスタ出力用見出し
      AND     flv.lookup_code  LIKE cv_code_eoh_024a08                          -- クイックコード（控除マスタ出力用見出し）
      AND     gd_proc_date       >= NVL( flv.start_date_active, gd_proc_date )  -- 有効開始日
      AND     gd_proc_date       <= NVL( flv.end_date_active,   gd_proc_date )  -- 有効終了日
      AND     flv.enabled_flag    = ct_enabled_flg_y                            -- 使用可能
      ORDER BY
              TO_NUMBER(flv.attribute1)
      ;
    --見出し
    TYPE l_header_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    lt_header_tab l_header_ttype;
--
  BEGIN
--
--##############################  固定ステータス初期化部 START  ##############################
--
    ov_retcode := cv_status_normal;
--
--#######################################  固定部 END  #######################################
--
    ------------------------------------------
    -- 見出しの出力
    ------------------------------------------
    -- データの見出しを取得
    OPEN  header_cur;
    FETCH header_cur BULK COLLECT INTO lt_header_tab;
    CLOSE header_cur;
--
    --データの見出しを編集
    <<data_head_output>>
    FOR i IN 1..lt_header_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_header_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_header_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --データの見出しを出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
--
    ------------------------------------------
    -- データ出力
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      --データを編集
      lv_line_data :=     cv_enclosed || gt_out_file_tab(i).origin_kind                || cv_enclosed  -- 作成元区分
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).deduction_no               || cv_enclosed  -- 控除No.
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).customer_code              || cv_enclosed  -- 顧客番号
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).base_code                  || cv_enclosed  -- 拠点
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).condition_kind             || cv_enclosed  -- 控除区分
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).condition_type             || cv_enclosed  -- 控除タイプ
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).data_type                  || cv_enclosed  -- データ種類
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).record_date                || cv_enclosed  -- 計上日
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).condition_no               || cv_enclosed  -- 控除条件No.
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).deduction_no               || cv_enclosed  -- 販売控除明細No.
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).condition_line_no          || cv_enclosed  -- 控除条件明細No.
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).status                     || cv_enclosed  -- ステータス
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).item_code                  || cv_enclosed  -- 品目コード
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).quantity                   || cv_enclosed  -- 数量
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).uom_code                   || cv_enclosed  -- 単位
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).unit_price                 || cv_enclosed  -- 単価
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).deduction_unit_price       || cv_enclosed  -- 控除単価
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).deduction_rate             || cv_enclosed  -- 控除率
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).deduction_amount           || cv_enclosed  -- 控除額
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).tax_code                   || cv_enclosed  -- 税コード
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).tax_rate                   || cv_enclosed  -- 税率
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).tax_amount                 || cv_enclosed  -- 税額
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).accounting subject_kind    || cv_enclosed  -- 科目
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).gl_interface_flag          || cv_enclosed  -- GL連携フラグ
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).product_code               || cv_enclosed  -- 製品コード
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).gl_date                    || cv_enclosed  -- GL記帳日
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).recovery_date              || cv_enclosed  -- リカバリー日付
         || cv_delimit || cv_enclosed || gt_out_file_tab(i).canceled_recode_date       || cv_enclosed  -- 取消日
      ;
--
      --データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#######################################  固定部 END  #######################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_customer_code                IN     VARCHAR2,  -- 1.顧客番号
    iv_order_list_date_from         IN     VARCHAR2,  -- 2.出力日(FROM)
    iv_order_list_date_to           IN     VARCHAR2,  -- 3.出力日(TO)
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--############################  固定ローカル定数変数宣言部 START  ############################
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
--#######################################  固定部 END  #######################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_order_list_date_from         DATE;             -- 出力日(FROM)_チェックOK
    ld_order_list_date_to           DATE;             -- 出力日(TO)_チェックOK
--
  BEGIN
--
--##############################  固定ステータス初期化部 START  ##############################
--
    ov_retcode := cv_status_normal;
--
--#######################################  固定部 END  #######################################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init(
      iv_customer_code,             -- 顧客番号
      iv_order_list_date_from,      -- 出力日(FROM)
      iv_order_list_date_to,        -- 出力日(TO)
      ld_order_list_date_from,      -- 出力日(FROM)_チェックOK
      ld_order_list_date_to,        -- 出力日(TO)_チェックOK
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  販売控除データ抽出
    -- ===============================
    get_order_list_cond(
      iv_customer_code,             -- 顧客番号
      ld_order_list_date_from,      -- 出力日(FROM)_チェックOK
      ld_order_list_date_to,        -- 出力日(TO)_チェックOK
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  データ出力
    -- ===============================
    output_data(
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--##################################  固定例外処理部 START  ##################################
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
--#######################################  固定部 END  #######################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,  -- エラー・メッセージ  --# 固定 #
    retcode                         OUT    VARCHAR2,  -- リターン・コード    --# 固定 #
    iv_customer_code                IN     VARCHAR2,  -- 1.顧客番号
    iv_order_list_date_from         IN     VARCHAR2,  -- 2.出力日(FROM)
    iv_order_list_date_to           IN     VARCHAR2   -- 3.出力日(TO)
  )
--
--######################################  固定部 START  ######################################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';               -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';    -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';    -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';    -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';               -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';    -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';    -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';    -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';              -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';                 -- コンカレントヘッダメッセージ出力先：ログ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);    -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);       -- リターン・コード
    lv_errmsg          VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);     -- 終了メッセージコード
--
  BEGIN
--
--######################################  固定部 START  ######################################
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
--#######################################  固定部 END  #######################################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_customer_code           -- 顧客番号
      ,iv_order_list_date_from    -- 出力日(FROM)
      ,iv_order_list_date_to      -- 出力日(TO)
      ,lv_errbuf                  -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                 -- リターン・コード             --# 固定 #
      ,lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
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
    -- エラーの場合、成功件数クリア
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
--
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
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
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
--#######################################  固定部 END  #######################################
--
END XXCOK024A08C;
/