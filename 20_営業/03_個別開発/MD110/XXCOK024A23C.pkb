CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A23C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A23C (body)
 * Description      : 控除マスタを元に、毎月定額で発生する控除データを作成し販売控除情報へ登録する
 * MD.050           : 定額控除データ作成 MD050_COK_024_A23
 * Version          : 1.1
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.初期処理
 *  get_data               A-2.定額控除条件抽出
 *  cre_sls_dedctn         A-3.販売控除データ登録
 *  submain                メイン処理プロシージャ
 *  main                   定額控除データ作成プロシージャ(A-4.終了処理を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/04/13    1.0   M.Sato           新規作成
 *  2021/04/06    1.1   K.Yoshikawa      定額控除複数明細対応
 *
 *****************************************************************************************/
--
--###########################  固定グローバル定数宣言部 START  ###########################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--############################  固定グローバル定数宣言部 END  ############################
--
--###########################  固定グローバル変数宣言部 START  ###########################
--
  gv_out_msg       VARCHAR2(2000);            -- 出力メッセージ
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--############################  固定グローバル変数宣言部 END  ############################
--
--##############################  固定共通例外宣言部 START  ##############################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
--###############################  固定共通例外宣言部 END  ###############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A23C';                    -- パッケージ名
  -- アプリケーション短縮名
  cv_xxccp_appl_name        CONSTANT VARCHAR2(10) := 'XXCCP';                           -- 共通領域短縮アプリ名
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                           -- 個別開発領域短縮アプリ名
  -- メッセージ名称
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';                -- 対象データなしエラーメッセージ
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';                -- 業務日付取得エラー
  cv_master_err_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10652';                -- マスタ不備エラーメッセージ
  cv_cus_chain_corp         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10648';                -- 顧客、チェーン、企業のいずれか1つ
  cv_base_cd                CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10638';                -- 拠点コード
-- 2021/04/06 Ver1.1 ADD Start
  cv_accounting_customer    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10793';                -- 計上顧客
-- 2021/04/06 Ver1.1 ADD End
  cv_deduction_amount       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10645';                -- 控除額
  cv_tax_cd                 CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10646';                -- 税コード
  cv_tax_credit             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10647';                -- 控除税額
  cv_target_rec_msg         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';                -- 対象件数メッセージ
  cv_success_rec_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';                -- 成功件数メッセージ
  cv_error_rec_msg          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';                -- エラー件数メッセージ
  cv_skip_rec_msg           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003';                -- スキップ件数メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';                -- 正常終了メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';                -- 警告終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';                -- エラー終了全ロールバック
  -- トークン
  cv_tkn_condition_no       CONSTANT VARCHAR2(20) := 'CONDITION_NO';                    -- 控除番号
  cv_tkn_column_name        CONSTANT VARCHAR2(20) := 'COLUMN_NAME';                     -- 項目名
  cv_cnt_token              CONSTANT VARCHAR2(20) := 'COUNT';                           -- 件数メッセージ用トークン名
  -- フラグ・区分定数
  cv_y_flag                 CONSTANT  VARCHAR2(1) := 'Y';                               -- フラグ値:Y
  -- 販売控除情報テーブルに設定する固定値
  cv_created_sec            CONSTANT  VARCHAR2(1) := 'F';                               -- 作成元区分
  cv_status                 CONSTANT  VARCHAR2(1) := 'N';                               -- ステータス
  cv_gl_rel_flag            CONSTANT  VARCHAR2(1) := 'N';                               -- GL連携フラグ
  cv_cancel_flag            CONSTANT  VARCHAR2(1) := 'N';                               -- 取消フラグ
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 定額控除条件ワークテーブル定義
  TYPE gr_dedctn_cond_rec IS RECORD(
       condition_id                 xxcok_condition_header.condition_id%TYPE                -- 控除条件ID
      ,condition_no                 xxcok_condition_header.condition_no%TYPE                -- 控除番号
      ,corp_code                    xxcok_condition_header.corp_code%TYPE                   -- 企業コード
      ,chain_code                   xxcok_condition_header.deduction_chain_code%TYPE        -- 控除用チェーンコード
      ,customer_code                xxcok_condition_header.customer_code%TYPE               -- 顧客コード(条件)
      ,data_type                    xxcok_condition_header.data_type%TYPE                   -- データ種類
      ,tax_code                     xxcok_condition_header.tax_code%TYPE                    -- 税コード
      ,condition_line_id            xxcok_condition_lines.condition_line_id%TYPE            -- 控除詳細ID
-- 2021/04/06 Ver1.1 MOD Start
--      ,accounting_base              xxcok_condition_lines.accounting_base%TYPE              -- 計上拠点
      ,accounting_customer_code     xxcok_condition_lines.accounting_customer_code%TYPE     -- 計上顧客
      ,sale_base_code               xxcmm_cust_accounts.sale_base_code%TYPE                 -- 売上拠点
-- 2021/04/06 Ver1.1 MOD End
      ,deduction_amount             xxcok_condition_lines.deduction_amount%TYPE             -- 控除額(本体)
      ,deduction_tax                xxcok_condition_lines.deduction_tax_amount%TYPE         -- 控除税額
  );
--
  -- ワークテーブル型定義
  TYPE g_dedctn_cond_ttype    IS TABLE OF gr_dedctn_cond_rec INDEX BY BINARY_INTEGER;
  gt_dedctn_cond_tbl        g_dedctn_cond_ttype;                                   -- 販売控除データ
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --初期取得
--
  gd_accounting_date                  DATE;                                         -- 控除データ計上日
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.初期処理
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                                 -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_process_date                   DATE;                                        -- 業務日付
--
    -- *** ローカル例外 ***

    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    -- 変数の初期化
    ld_process_date := NULL;
    --==================================
    -- １．業務日付取得
    --==================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務日付取得エラーの場合
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                             ,cv_process_date_msg
                                             );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    -- 正常に取得できていた場合
    ELSE
      -- 控除データの計上日を求める
      gd_accounting_date := ADD_MONTHS ( trunc ( ld_process_date , 'month' ) , 1 );
    --
    END IF;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
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
--#################################  固定例外処理部 END  #################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : A-2.定額控除条件抽出
   ***********************************************************************************/
  PROCEDURE get_data( ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
                     ,ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
                     ,ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_fix_dedcton_type     CONSTANT VARCHAR2(3)   := '070';      -- 定額控除タイプ
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル (定額控除条件抽出)***
    CURSOR fixed_deduction_cur
    IS
      SELECT xch.condition_id             AS condition_id       -- 控除条件ID
            ,xch.condition_no             AS condition_no       -- 控除番号
            ,xch.corp_code                AS corp_code          -- 企業コード
            ,xch.deduction_chain_code     AS chain_code         -- 控除用チェーンコード
            ,xch.customer_code            AS customer_code      -- 顧客コード(条件)
            ,xch.data_type                AS data_type          -- データ種類
            ,xch.tax_code                 AS tax_code           -- 税コード
            ,xcl.condition_line_id        AS condition_line_id  -- 控除詳細ID
-- 2021/04/06 Ver1.1 MOD Start
--            ,xcl.accounting_base          AS accounting_base    -- 計上拠点
            ,xcl.accounting_customer_code AS accounting_customer_code    -- 計上顧客
            ,xca.sale_base_code           AS sale_base_code     -- 売上拠点
-- 2021/04/06 Ver1.1 MOD Start
            ,xcl.deduction_amount         AS deduction_amount   -- 控除額(本体)
            ,xcl.deduction_tax_amount     AS deduction_tax      -- 控除税額
      FROM
             xxcok_condition_header       xch                   -- 控除条件テーブル
            ,xxcok_condition_lines        xcl                   -- 控除詳細テーブル
            ,fnd_lookup_values            flv                   -- 参照表
-- 2021/04/06 Ver1.1 ADD Start
            ,xxcmm_cust_accounts          xca                   -- 顧客追加情報
-- 2021/04/06 Ver1.1 ADD End
      WHERE 1 = 1
      AND xch.enabled_flag_h              = cv_y_flag                     -- 有効フラグ
      AND gd_accounting_date              BETWEEN xch.start_date_active   -- 開始日
                                          AND xch.end_date_active         -- 終了日
      AND flv.lookup_type                 = 'XXCOK1_DEDUCTION_DATA_TYPE'  -- 控除データ種類
      AND flv.lookup_code                 =  xch.data_type                -- データ種類
      AND flv.language                    = 'JA'                          -- 言語：JA
      AND flv.enabled_flag                = cv_y_flag                     -- 参照表:有効フラグ
      AND flv.attribute2                  = cv_fix_dedcton_type           -- 控除タイプ
      AND xcl.condition_id                = xch.condition_id              -- 控除条件ID
      AND xcl.enabled_flag_l              = cv_y_flag                     -- 控除詳細:有効フラグ
-- 2021/04/06 Ver1.1 ADD Start
      AND xcl.accounting_customer_code    = xca.customer_code(+)          -- 控除詳細:計上顧客
-- 2021/04/06 Ver1.1 ADD End
      ;
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    -- カーソルオープン
    OPEN  fixed_deduction_cur;
    -- データ取得
    FETCH fixed_deduction_cur BULK COLLECT INTO gt_dedctn_cond_tbl;
    -- カーソルクローズ
    CLOSE fixed_deduction_cur;
--
    -- 取得データが０件の場合
    IF ( gt_dedctn_cond_tbl.COUNT = 0 ) THEN
      -- 警告ステータスの格納
      ov_retcode := cv_status_warn;
      -- 対象なしメッセージの出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_short_nm
                   ,iv_name         => cv_data_get_msg
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --ユーザー・エラーメッセージ
      );
    END IF;
--
    -- 対象件数を設定
    gn_target_cnt := gt_dedctn_cond_tbl.COUNT;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( fixed_deduction_cur%ISOPEN ) THEN
        CLOSE fixed_deduction_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( fixed_deduction_cur%ISOPEN ) THEN
        CLOSE fixed_deduction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( fixed_deduction_cur%ISOPEN ) THEN
        CLOSE fixed_deduction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  #####################################
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_sales_deducation
   * Description      : A-3.販売控除データ登録
   ***********************************************************************************/
  PROCEDURE insert_sales_deducation( 
                      ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
                     ,ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
                     ,ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_sales_deducation'; -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
  lv_column_name                      VARCHAR2(20);                                -- マスタ不備カラム名
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
    gn_normal_cnt := 0;
--
    gn_warn_cnt := 0;
--#############################  固定ステータス初期化部 END  #############################
--
    -- 販売控除データ登録ループ
    <<insert_loop>>
    FOR ln_ins_sls_dedctn IN 1..gt_dedctn_cond_tbl.COUNT LOOP
      -- ステータスを初期化
      lv_retcode  := cv_status_normal;
      -- 取得データの不備(NULL)チェック
      IF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).customer_code IS NULL
        AND gt_dedctn_cond_tbl(ln_ins_sls_dedctn).chain_code IS NULL
        AND gt_dedctn_cond_tbl(ln_ins_sls_dedctn).corp_code IS NULL )
      -- 顧客、チェーン、企業すべてNULLの場合
      THEN
        lv_column_name := cv_cus_chain_corp;
        lv_retcode := cv_status_warn;
-- 2021/04/06 Ver1.1 MOD Start
      ---- 拠点コードがNULLであった場合
      -- 計上顧客コードがNULLであった場合
--      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_base IS NULL ) THEN
      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_customer_code IS NULL ) THEN
--        lv_column_name := cv_base_cd;
        lv_column_name := cv_accounting_customer;
-- 2021/04/06 Ver1.1 MOD End
        lv_retcode := cv_status_warn;
      -- 控除額がNULLであった場合
      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).deduction_amount IS NULL ) THEN
        lv_column_name := cv_deduction_amount;
        lv_retcode := cv_status_warn;
      -- 税コードがNULLであった場合
      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).tax_code IS NULL ) THEN
        lv_column_name := cv_tax_cd;
        lv_retcode := cv_status_warn;
      -- 控除税額がNULLであった場合
      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).deduction_tax IS NULL ) THEN
        lv_column_name := cv_tax_credit;
        lv_retcode := cv_status_warn;
      END IF;
--
      -- マスタの不備の有無を判断
      IF ( lv_retcode = cv_status_warn) THEN
        -- 不備があればマスタ不備エラーメッセージの出力
        gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_short_nm
                     ,iv_name         => cv_master_err_msg
                     ,iv_token_name1  => cv_tkn_condition_no
                     ,iv_token_value1 => gt_dedctn_cond_tbl(ln_ins_sls_dedctn).condition_no
                     ,iv_token_name2  => cv_tkn_column_name
                     ,iv_token_value2 => lv_column_name
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg                --ユーザー・エラーメッセージ
        );
        -- スキップ件数のインクリメント
        gn_warn_cnt := gn_warn_cnt + 1;
        -- 警告ステータスを戻す
        ov_retcode := lv_retcode;
      -- マスタに不備がない場合
      ELSE
        -- 販売控除データを登録する
        INSERT INTO xxcok_sales_deduction(
             sales_deduction_id                                       -- 販売控除ID
            ,base_code_from                                           -- 振替元拠点
            ,base_code_to                                             -- 振替先拠点
            ,customer_code_from                                       -- 振替元顧客コード
            ,customer_code_to                                         -- 振替先顧客コード
            ,deduction_chain_code                                     -- 控除用チェーンコード
            ,corp_code                                                -- 企業コード
            ,record_date                                              -- 計上日
            ,source_category                                          -- 作成元区分
            ,source_line_id                                           -- 作成元明細ID
            ,condition_id                                             -- 控除条件ID
            ,condition_no                                             -- 控除番号
            ,condition_line_id                                        -- 控除詳細ID
            ,data_type                                                -- データ種類
            ,status                                                   -- ステータス
            ,item_code                                                -- 品目コード
            ,sales_uom_code                                           -- 販売単位
            ,sales_unit_price                                         -- 販売単価
            ,sales_quantity                                           -- 販売数量
            ,sale_pure_amount                                         -- 売上本体金額
            ,sale_tax_amount                                          -- 売上消費税額
            ,deduction_uom_code                                       -- 控除単位
            ,deduction_unit_price                                     -- 控除単価
            ,deduction_quantity                                       -- 控除数量
            ,deduction_amount                                         -- 控除額
            ,tax_code                                                 -- 税コード
            ,tax_rate                                                 -- 税率
            ,recon_tax_code                                           -- 消込時税コード
            ,recon_tax_rate                                           -- 消込時税率
            ,deduction_tax_amount                                     -- 控除税額
            ,remarks                                                  -- 備考
            ,application_no                                           -- 申請書No.
            ,gl_if_flag                                               -- GL連携フラグ
            ,gl_base_code                                             -- GL計上拠点
            ,gl_date                                                  -- GL記帳日
            ,recovery_date                                            -- リカバリー日付
            ,cancel_flag                                              -- 取消フラグ
            ,cancel_gl_date                                           -- 取消GL記帳日
            ,cancel_user                                              -- 取消実施ユーザ
            ,recon_base_code                                          -- 消込時計上拠点
            ,recon_slip_num                                           -- 支払伝票番号
            ,carry_payment_slip_num                                   -- 繰越時支払伝票番号
            ,report_decision_flag                                     -- 速報確定フラグ
            ,gl_interface_id                                          -- GL連携ID
            ,cancel_gl_interface_id                                   -- 取消GL連携ID
            ,created_by                                               -- 作成者
            ,creation_date                                            -- 作成日
            ,last_updated_by                                          -- 最終更新者
            ,last_update_date                                         -- 最終更新日
            ,last_update_login                                        -- 最終更新ログイン
            ,request_id                                               -- 要求ID
            ,program_application_id                                   -- コンカレント・プログラム・アプリケーションID
            ,program_id                                               -- コンカレント・プログラムID
            ,program_update_date                                      -- プログラム更新日
          )VALUES(
             xxcok_sales_deduction_s01.nextval                        -- 販売控除ID
-- 2021/04/06 Ver1.1 MOD Start
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_base    -- 振替元拠点
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).sale_base_code     -- 振替元拠点
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_base    -- 振替先拠点
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).sale_base_code     -- 振替先拠点
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).customer_code      -- 振替元顧客コード
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_customer_code      -- 振替元顧客コード
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).customer_code      -- 振替先顧客コード
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_customer_code      -- 振替先顧客コード
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).chain_code         -- 控除用チェーンコード
            ,NULL                                                       -- 控除用チェーンコード
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).corp_code          -- 企業コード
            ,NULL                                                       -- 企業コード
-- 2021/04/06 Ver1.1 MOD End
            ,gd_accounting_date                                       -- 計上日
            ,cv_created_sec                                           -- 作成元区分
            ,NULL                                                     -- 作成元明細ID
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).condition_id       -- 控除条件ID
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).condition_no       -- 控除番号
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).condition_line_id  -- 控除詳細ID
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).data_type          -- データ種類
            ,cv_status                                                -- ステータス
            ,NULL                                                     -- 品目コード
            ,NULL                                                     -- 販売単位
            ,NULL                                                     -- 販売単価
            ,NULL                                                     -- 販売数量
            ,NULL                                                     -- 売上本体金額
            ,NULL                                                     -- 売上消費税額
            ,NULL                                                     -- 控除単位
            ,NULL                                                     -- 控除単価
            ,NULL                                                     -- 控除数量
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).deduction_amount   -- 控除額
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).tax_code           -- 税コード
            ,NULL                                                     -- 税率
            ,NULL                                                     -- 消込時税コード
            ,NULL                                                     -- 消込時税率
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).deduction_tax      -- 控除税額
            ,NULL                                                     -- 備考
            ,NULL                                                     -- 申請書No.
            ,cv_gl_rel_flag                                           -- GL連携フラグ
            ,NULL                                                     -- GL計上拠点
            ,NULL                                                     -- GL記帳日
            ,NULL                                                     -- リカバリー日付
            ,cv_cancel_flag                                           -- 取消フラグ
            ,NULL                                                     -- 取消GL記帳日
            ,NULL                                                     -- 取消実施ユーザ
            ,NULL                                                     -- 消込時計上拠点
            ,NULL                                                     -- 支払伝票番号
            ,NULL                                                     -- 繰越時支払伝票番号
            ,NULL                                                     -- 速報確定フラグ
            ,NULL                                                     -- GL連携ID
            ,NULL                                                     -- 取消GL連携ID
            ,cn_created_by                                            -- 作成者
            ,cd_creation_date                                         -- 作成日
            ,cn_last_updated_by                                       -- 最終更新者
            ,cd_last_update_date                                      -- 最終更新日
            ,cn_last_update_login                                     -- 最終更新ログイン
            ,cn_request_id                                            -- 要求ID
            ,cn_program_application_id                                -- コンカレント・プログラム・アプリケーションID
            ,cn_program_id                                            -- コンカレント・プログラムID
            ,cd_program_update_date                                   -- プログラム更新日
        );
        -- 正常件数をインクリメント
        gn_normal_cnt := gn_normal_cnt + 1;
      --
      END IF;
    --
    END LOOP insert_loop;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
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
--#################################  固定例外処理部 END  #################################
--
  END insert_sales_deducation;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf    OUT VARCHAR2             --   エラー・メッセージ           --# 固定 #
                    ,ov_retcode   OUT VARCHAR2             --   リターン・コード             --# 固定 #
                    ,ov_errmsg    OUT VARCHAR2 )           --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);                                        -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                                           -- リターン・コード
    lv_errmsg  VARCHAR2(5000);                                        -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END  #####################################
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
    -- <カーソル名>
--
    -- <カーソル名>レコード型
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END  #####################################
--
    -- グローバル変数の初期化
    gn_target_cnt        := 0;    -- 対象件数
    gn_normal_cnt        := 0;    -- 正常件数
    gn_error_cnt         := 0;    -- エラー件数
    gn_warn_cnt          := 0;    -- スキップ件数
    gd_accounting_date   := NULL; -- 控除データ計上日
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init( ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
         ,ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
         ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.定額控除条件抽出
    -- ===============================
    get_data(
        ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
       ,ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
       ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ステータスが正常（データが1件以上抽出）であればA-3を実行する
    IF ( lv_retcode = cv_status_normal ) THEN
      -- ===============================
      -- A-3.販売控除データ登録
      -- ===============================
      insert_sales_deducation(
          ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
         ,ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
         ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
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
--#####################################  固定部 END  #####################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 定額控除データ作成プロシージャ(A-4.終了処理を含む)
   **********************************************************************************/
--
--
  PROCEDURE main( errbuf      OUT VARCHAR2               -- エラー・メッセージ  --# 固定 #
                 ,retcode     OUT VARCHAR2 )             -- リターン・コード    --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCOK';             -- アドオン：個別開発領域
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf          VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);         -- リターン・コード
    lv_errmsg          VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);       -- 終了メッセージコード
--
--#####################################  固定部 END  #####################################
--
  BEGIN
--
--####################################  固定部 START  ####################################--
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
--
--#####################################  固定部 END  #####################################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain( ov_errbuf  => lv_errbuf              -- エラー・メッセージ           --# 固定 #
            ,ov_retcode => lv_retcode             -- リターン・コード             --# 固定 #
            ,ov_errmsg  => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
    -- ===============================
    -- A-4.終了処理
    -- ===============================
--
    -- エラー発生時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_warn_cnt     := 0;
      gn_error_cnt    := 1;
    END IF;
--
    --エラー出力
    IF (lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --エラーメッセージ
      );
    END IF;
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_target_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_success_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_skip_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_warn_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_error_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --終了メッセージ
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                           ,iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
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
--
--#####################################  固定部 END  #####################################
--
  END main;
--
END XXCOK024A23C;
/
