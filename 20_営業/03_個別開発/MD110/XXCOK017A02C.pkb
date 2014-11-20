CREATE OR REPLACE PACKAGE BODY XXCOK017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOK017A02C (body)
 * Description      : BM本振自社負担銀行手数料の振替
 * MD.050           : BM本振自社負担銀行手数料の振替 (MD050_COK_017A02)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理             (A-1)
 *  get_pmt_amt            振込額情報の取得     (A-2)
 *                         銀行手数料部門集計   (A-3)
 *  create_cr_data         部門別仕訳の作成     (A-4)
 *  create_dr_data         振替元仕訳の作成     (A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/06/13    1.0   T.Ishiwata       main新規作成
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
  --*** エラー終了 ***
  error_proc_expt                  EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOK017A02C';      -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_short_name          CONSTANT VARCHAR2(10)  := 'XXCCP';             -- XXCCP
  cv_appl_name_sqlgl          CONSTANT VARCHAR2(10)  := 'SQLGL';             -- SQLGL
  cv_appl_name_xxcok          CONSTANT VARCHAR2(10)  := 'XXCOK';             -- XXCOK
--
  -- メッセージコード
  cv_target_rec_msg           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';      -- 対象件数メッセージ
  cv_success_rec_msg          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';      -- 成功件数メッセージ
  cv_error_rec_msg            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';      -- エラー件数メッセージ
  cv_normal_msg               CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';      -- 正常終了メッセージ
  cv_error_msg                CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';      -- エラー終了全ロールバック
  cv_no_parameter_msg         CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90008';      -- コンカレント入力パラメータなし
  cv_msg_cok_10496            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10496';      -- 入力パラメータ出力メッセージ
  cv_msg_cok_00003            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';      -- プロファイル取得エラーメッセージ
  cv_msg_cok_00005            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00005';      -- 従業員取得エラーメッセージ
  cv_msg_cok_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00011';      -- 会計期間情報取得エラーメッセージ
  cv_msg_cok_00012            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00012';      -- 所属拠点コード取得エラーメッセージ
  cv_msg_cok_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00024';      -- グループID取得エラーメッセージ
  cv_msg_cok_00025            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00025';      -- 伝票番号取得エラーメッセージ
  cv_msg_cok_00028            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';      -- 業務処理日付取得エラーメッセージ
  cv_msg_cok_00042            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00042';      -- 会計期間未オープンエラーメッセージ
  cv_msg_cok_10497            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10497';      -- 計上日未来日チェック
  cv_msg_cok_10498            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10498';      -- 振込元銀行支店ID取得エラー
  cv_msg_cok_10499            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10499';      -- 銀行手数料の取得エラー
--
  -- *** 定数(トークン) ***
  cv_cnt_token                CONSTANT VARCHAR2(30)  := 'COUNT';             -- 件数
  cv_tkn_proc_date            CONSTANT VARCHAR2(30)  := 'PROC_DATE';         -- 計上日
  cv_tkn_profile              CONSTANT VARCHAR2(30)  := 'PROFILE';           -- プロファイル名
  cv_tkn_user_id              CONSTANT VARCHAR2(30)  := 'USER_ID';           -- ユーザID
  cv_tkn_bank_name            CONSTANT VARCHAR2(30)  := 'BANK_NAME';         -- 銀行名
  cv_tkn_ank_branch           CONSTANT VARCHAR2(30)  := 'BANK_BRANCH';       -- 銀行支店名
  cv_tkn_slp_code             CONSTANT VARCHAR2(30)  := 'SLIPPER_CODE';      -- 仕入先コード
  cv_tkn_p_amt                CONSTANT VARCHAR2(30)  := 'P_AMT_TAX_SUM';     -- 振込額合計
--
  -- プロファイル・オプション名
  cv_prof_org_id              CONSTANT VARCHAR2(50)  := 'ORG_ID';                              -- MO: 営業単位
  cv_prof_setof_id            CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';                    -- 会計帳簿ID
  cv_prof_setof_name          CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_NAME';                  -- 会計帳簿名
  cv_prof_aff1_code           CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF1_COMPANY_CODE';            -- 会社コード
  cv_prof_aff2_fin            CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF2_DEPT_FIN';                -- 部門コード_財務経理部
  cv_prof_aff2_adj            CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF2_DEPT_ADJ';                -- 部門コード_調整部署
  cv_prof_aff3_vdbm           CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF3_VEND_SALES_COMMISSION';   -- 勘定科目_自販機販売手数料
  cv_prof_aff3_fee            CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF3_FEE';                     -- 勘定科目_手数料
  cv_prof_aff4_trfee          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF4_TRANSFER_FEE';            -- 補助科目_手数料_振込手数料
  cv_prof_aff4_elec           CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF4_VEND_SALES_ELEC_COST';    -- 補助科目_自販機販売手数料_自販電気料
  cv_prof_aff4_rebate         CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF4_VEND_SALES_REBATE';       -- 補助科目_自販機販売手数料_自販リベート
  cv_prof_aff5_dummy          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF5_CUSTOMER_DUMMY';          -- 顧客コード_ダミー値
  cv_prof_aff6_dummy          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF6_COMPANY_DUMMY';           -- 企業コード_ダミー値
  cv_prof_aff7_dummy          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';      -- 予備コード１_ダミー値
  cv_prof_aff8_dummy          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';      -- 予備コード２_ダミー値
  cv_prof_gl_ctg_bm           CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_CATEGORY_BM';               -- 仕訳カテゴリ_販売手数料
  cv_prof_gl_ctg_cng          CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_CATEGORY_CNG';              -- 仕訳カテゴリ_振替伝票
  cv_prof_gl_src_cok          CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_SOURCE_COK';                -- 仕訳ソース_個別開発
  cv_prof_transf_bank         CONSTANT VARCHAR2(50)  := 'XXCOK1_TRANSFERRING_BANK';            -- 振込元銀行名
  cv_prof_transf_bankb        CONSTANT VARCHAR2(50)  := 'XXCOK1_TRANSFERRING_BANK_BRANCH';     -- 振込元支店名
  cv_prof_other_tax_code      CONSTANT VARCHAR2(50)  := 'XXCOK1_OTHER_TAX_CODE';               -- 対象外消費税コード
  cv_prof_bm_tax_rate         CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_TAX';                       -- 販売手数料_消費税率
--
  -- 言語
  cv_lang                     CONSTANT VARCHAR2(50)  := USERENV( 'LANG' );
  -- 会計期間ステータス
  cv_closing_status_open      CONSTANT VARCHAR2(1)   := 'O';                -- オープン
  -- 仕訳ステータス
  cv_je_status_new            CONSTANT VARCHAR2(3)   := 'NEW';              -- 新規
  -- 残高タイプ
  cv_balance_type_result      CONSTANT VARCHAR2(1)   := 'A';                -- 実績
  -- 通貨コード
  cv_currency_code            CONSTANT VARCHAR2(3)   := 'JPY';              -- JPY(日本円)
  -- ランク
  cn_rank_number              CONSTANT NUMBER        := 1;
  -- 銀行手数料マスタ条件
  cv_code_one                 CONSTANT VARCHAR2(3)   := 'ONE';              -- 特定銀行/特定支店
  cv_code_other               CONSTANT VARCHAR2(5)   := 'OTHER';            -- その他銀行
  cv_code_all                 CONSTANT VARCHAR2(3)   := 'ALL';              -- 全支店
--
  
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期処理取得値
  gd_process_date                  DATE                                  DEFAULT NULL;  -- 業務処理日付
  gd_gl_date                       DATE                                  DEFAULT NULL;  -- 計上日
  gn_prof_org_id                   NUMBER                                DEFAULT NULL;  -- 営業単位ID
  gn_prof_set_of_books_id          NUMBER                                DEFAULT NULL;  -- 会計帳簿ID
  gv_prof_set_of_books_name        VARCHAR2(100)                         DEFAULT NULL;  -- 会計帳簿名
  gv_prof_aff1_company_code        VARCHAR2(100)                         DEFAULT NULL;  -- 会社コード
  gv_prof_aff2_dept_fin            VARCHAR2(100)                         DEFAULT NULL;  -- 部門コード_財務経理部
  gv_prof_aff2_dept_adj            VARCHAR2(100)                         DEFAULT NULL;  -- 部門コード_調整部署
  gv_prof_aff3_fee                 VARCHAR2(100)                         DEFAULT NULL;  -- 勘定科目_手数料
  gv_prof_aff3_bm                  VARCHAR2(100)                         DEFAULT NULL;  -- 勘定科目_自販機販売手数料
  gv_prof_aff4_transfer_fee        VARCHAR2(100)                         DEFAULT NULL;  -- 補助科目_手数料_振込手数料
  gv_prof_aff4_elec_cost           VARCHAR2(100)                         DEFAULT NULL;  -- 補助科目_自販機販売手数料_自販電気料
  gv_prof_aff4_rebate              VARCHAR2(100)                         DEFAULT NULL;  -- 補助科目_自販機販売手数料_自販リベート
  gv_prof_aff5_dummy               VARCHAR2(100)                         DEFAULT NULL;  -- 顧客コード_ダミー値
  gv_prof_aff6_dummy               VARCHAR2(100)                         DEFAULT NULL;  -- 企業コード_ダミー値
  gv_prof_aff7_dummy               VARCHAR2(100)                         DEFAULT NULL;  -- 予備コード１_ダミー値
  gv_prof_aff8_dummy               VARCHAR2(100)                         DEFAULT NULL;  -- 予備コード２_ダミー値
  gv_prof_gl_category_bm           VARCHAR2(100)                         DEFAULT NULL;  -- 仕訳カテゴリ_販売手数料
  gv_prof_gl_category_cng          VARCHAR2(100)                         DEFAULT NULL;  -- 仕訳カテゴリ_振替伝票
  gv_prof_gl_source_cok            VARCHAR2(100)                         DEFAULT NULL;  -- 仕訳ソース_個別開発
  gv_prof_transf_bank              VARCHAR2(100)                         DEFAULT NULL;  -- 振込元銀行名
  gv_prof_transf_bankb             VARCHAR2(100)                         DEFAULT NULL;  -- 振込元支店名
  gv_prof_other_tax_code           VARCHAR2(100)                         DEFAULT NULL;  -- 対象外消費税コード
  gn_group_id                      NUMBER                                DEFAULT NULL;  -- グループID
  gv_batch_name                    VARCHAR2(100)                         DEFAULT NULL;  -- バッチ名
  gv_s_batch_name                  VARCHAR2(100)                         DEFAULT NULL;  -- 検索用バッチ名
  gn_period_year                   NUMBER                                DEFAULT NULL;  -- 会計年度
  gv_period_name                   VARCHAR2(100)                         DEFAULT NULL;  -- 会計期間名
  gv_closing_status                VARCHAR2(100)                         DEFAULT NULL;  -- 会計ステータス
  gt_user_name                     fnd_user.user_name%TYPE               DEFAULT NULL;  -- 従業員番号
  gt_section                       per_all_people_f.attribute28%TYPE     DEFAULT NULL;  -- 所属拠点CD
  gt_bank_branch_id                ap_bank_branches.bank_branch_id%TYPE  DEFAULT NULL;  -- 銀行支店ID
  gn_bank_charge_sum               NUMBER                                DEFAULT 0;     -- 銀行手数料(合計)
  gt_slip_number                   VARCHAR2(150)                         DEFAULT NULL;  -- 伝票番号
  gn_bm_tax_rate                   NUMBER                                DEFAULT 0;     -- 販売手数料_消費税率
  --
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 銀行手数料カーソル
  CURSOR bank_charge_cur
  IS
    -- VDBM本振金額（自社負担）
    -- 銀行手数料を含まない仕訳情報
    WITH  bm_gl_je  AS (
            SELECT    gjl.attribute3    AS org_slip_number  -- 伝票番号
                    , gjl.attribute7    AS supplier_code    -- 仕入先CD
                    , gcc.segment2      AS base_code        -- 部門CD
                    , gcc.segment5      AS customer_code    -- 顧客CD
            FROM      gl_je_batches        gjb   -- GL仕訳バッチ
                    , gl_je_sources_vl     gjsv  -- GL仕訳ソース
                    , gl_je_categories_vl  gjcv  -- GL仕訳カテゴリ
                    , gl_sets_of_books     gsob  -- GL会計帳簿
                    , gl_je_headers        gjh   -- GL仕訳ヘッダ
                    , gl_je_lines          gjl   -- GL仕訳明細
                    , gl_code_combinations gcc   -- AFF勘定科目組合せ
            WHERE     gsob.name                   =  gv_prof_set_of_books_name  -- 会計帳簿名
              AND     gjb.set_of_books_id         =  gsob.set_of_books_id
              AND     gjb.name                    LIKE gv_s_batch_name          -- 仕訳バッチ名
              AND     gjh.je_batch_id             =  gjb.je_batch_id
              AND     gjh.set_of_books_id         =  gjb.set_of_books_id
              AND     gjsv.user_je_source_name    =  gv_prof_gl_source_cok      -- 仕訳ソース名
              AND     gjh.je_source               =  gjsv.je_source_name
              AND     gjcv.user_je_category_name  =  gv_prof_gl_category_bm     -- 仕訳カテゴリ名
              AND     gjh.je_category             =  gjcv.je_category_name
              AND     gjl.je_header_id            =  gjh.je_header_id
              AND     gjl.code_combination_id     =  gcc.code_combination_id
              AND     gcc.chart_of_accounts_id    =  gsob.chart_of_accounts_id
              AND     gcc.segment1                =  gv_prof_aff1_company_code  -- AFF会社    ：伊藤園
              AND     gcc.segment3                =  gv_prof_aff3_bm            -- AFF勘定科目：自販機販売手数料
              AND     gcc.segment4                IN( gv_prof_aff4_rebate       -- AFF補助科目：自販機リベート
                                                    , gv_prof_aff4_elec_cost    -- AFF補助科目：自販機電気料
                                                  )
              AND     gcc.segment7                =  gv_prof_aff7_dummy         -- AFF予備1
              AND     gcc.segment8                =  gv_prof_aff8_dummy         -- AFF予備2
              -- 銀行手数料を含む仕訳情報
              AND     NOT EXISTS (  SELECT 'X'
                                    FROM    gl_je_lines           gjl2 -- GL仕訳明細
                                          , gl_code_combinations  gcc2 -- AFF勘定科目組合せ
                                    WHERE   gjl2.je_header_id         =  gjh.je_header_id
                                      AND   gcc2.code_combination_id  =  gjl2.code_combination_id
                                      AND   gcc2.chart_of_accounts_id =  gcc.chart_of_accounts_id    -- AFF体系ID
                                      AND   gcc2.segment1             =  gv_prof_aff1_company_code   -- AFF会社    ：伊藤園
                                      AND   gcc2.segment2             =  gv_prof_aff2_dept_fin       -- AFF部門    ：財務経理部
                                      AND   gcc2.segment3             =  gv_prof_aff3_fee            -- AFF勘定科目：手数料
                                      AND   gcc2.segment4             =  gv_prof_aff4_transfer_fee   -- AFF補助科目：振込手数料
                                      AND   gcc2.segment5             =  gv_prof_aff5_dummy          -- AFF顧客    ：定義なし
                                      AND   gcc2.segment6             =  gv_prof_aff6_dummy          -- AFF企業    ：定義なし
                                      AND   gcc2.segment7             =  gv_prof_aff7_dummy          -- AFF予備1
                                      AND   gcc2.segment8             =  gv_prof_aff8_dummy          -- AFF予備2
                      )
              AND     gjh.period_name   =  gv_period_name             -- 会計期間
            GROUP BY  gjl.attribute3    -- 伝票番号
                    , gjl.attribute7    -- 仕入先CD
                    , gcc.segment2      -- AFF部門CD
                    , gcc.segment5      -- AFF顧客CD
          )
          -- 振込手数料を含まない仕訳情報(振込金額順付き)
        , xbb_rank  AS (
            SELECT    xbb.supplier_code                     AS supplier_code    -- 仕入先CD
                    , je.base_code                          AS base_code        -- 部門CD
                    , xbb.cust_code                         AS cust_code        -- 顧客CD
                    , xbb.org_slip_number                   AS org_slip_number  -- 伝票番号
                    , NVL( SUM( xbb.payment_amt_tax ), 0 )  AS payment_amt_tax  -- 支払金額
                    , RANK() OVER( PARTITION BY xbb.supplier_code
                                   ORDER BY NVL( SUM( xbb.payment_amt_tax ), 0 ) DESC NULLS LAST
                                          , xbb.cust_code                        ASC
                                          , je.base_code                         ASC
                                          , MAX( xbb.bm_balance_id )             DESC
                                     )                      AS rank             -- 支払金額が一番多い順序
            FROM      xxcok_backmargin_balance xbb -- 販手残高
                    , bm_gl_je                      je  -- 振込手数料を含まない仕訳情報
            WHERE     xbb.supplier_code   =  je.supplier_code
              AND     xbb.cust_code       =  je.customer_code
              AND     xbb.org_slip_number =  je.org_slip_number
            GROUP BY  xbb.supplier_code   -- 仕入先CD
                    , je.base_code        -- 部門CD
                    , xbb.cust_code       -- 顧客CD
                    , xbb.org_slip_number -- 伝票番号
          )
    SELECT    rank.supplier_code         AS supplier_code     -- 仕入先CD
            , rank.base_code             AS dept_code         -- 部門CD
            , SUM(xbbs.payment_amt_tax)  AS p_amt_tax_sum     -- 振込額合計
    FROM  xbb_rank                 rank  -- 振込手数料を含まない仕訳情報(振込金額順付き)
         ,xxcok_backmargin_balance xbbs  -- 販手残高テーブル(合計算出用)
    WHERE rank.rank             =  cn_rank_number
      AND rank.supplier_code    =  xbbs.supplier_code
      AND rank.org_slip_number  =  xbbs.org_slip_number
    GROUP BY
      rank.supplier_code
    , rank.base_code    
    ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 銀行手数料レコード型
  bank_charge_rec bank_charge_cur%ROWTYPE;
  --
  TYPE bc_dept_sum_rtype IS RECORD(
     dept_code      bank_charge_rec.dept_code%TYPE                  -- 部門コード
    ,bank_charge    ap_bank_charge_lines.bank_charge_standard%TYPE  -- 銀行手数料
  );
  -- テーブル型の定義
  TYPE bank_charge_v_ttype IS TABLE OF bc_dept_sum_rtype INDEX BY VARCHAR2(100);
  --
  bank_charge_v_tab                bank_charge_v_ttype;
  --
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_gl_date    IN  VARCHAR2,     --   1.入力パラメータ：計上日
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
    cv_yyyymmdd_format  CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- 日付型書式
    cv_percent          CONSTANT VARCHAR2(1)   := '%';           -- ％文字列
--
    -- *** ローカル変数 ***
    lv_outmsg           VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode          BOOLEAN         DEFAULT TRUE;                -- メッセージ出力関数戻り値
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
    --入力パラメータをメッセージ出力
    --==============================================================
    lv_outmsg := xxccp_common_pkg.get_msg(
                    cv_appl_name_xxcok
                  , cv_msg_cok_10496
                  , cv_tkn_proc_date
                  , iv_gl_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_outmsg          -- メッセージ
                  , 1                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- 出力区分
                  , lv_outmsg          -- メッセージ
                  , 1                  -- 改行
                  );
--
    --==================================================
    -- 業務処理日付取得
    --==================================================
    gd_process_date :=  xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- プロファイル取得(営業単位ID)
    --==================================================
    gn_prof_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF( gn_prof_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_org_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(会計帳簿ID)
    --==================================================
    gn_prof_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_setof_id ) );
    IF( gn_prof_set_of_books_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_setof_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(会計帳簿名)
    --==================================================
    gv_prof_set_of_books_name := FND_PROFILE.VALUE( cv_prof_setof_name );
    IF( gv_prof_set_of_books_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_setof_name
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(会社コード)
    --==================================================
    gv_prof_aff1_company_code := FND_PROFILE.VALUE( cv_prof_aff1_code );
    IF( gv_prof_aff1_company_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff1_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(部門コード_財務経理部)
    --==================================================
    gv_prof_aff2_dept_fin := FND_PROFILE.VALUE( cv_prof_aff2_fin );
    IF( gv_prof_aff2_dept_fin IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff2_fin
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(部門コード_調整部署)
    --==================================================
    gv_prof_aff2_dept_adj := FND_PROFILE.VALUE( cv_prof_aff2_adj );
    IF( gv_prof_aff2_dept_adj IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff2_adj
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(勘定科目_自販機販売手数料)
    --==================================================
    gv_prof_aff3_bm := FND_PROFILE.VALUE( cv_prof_aff3_vdbm );
    IF( gv_prof_aff3_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff3_vdbm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(勘定科目_手数料)
    --==================================================
    gv_prof_aff3_fee := FND_PROFILE.VALUE( cv_prof_aff3_fee );
    IF( gv_prof_aff3_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff3_fee
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(補助科目_自販機販売手数料_自販電気料)
    --==================================================
    gv_prof_aff4_elec_cost := FND_PROFILE.VALUE( cv_prof_aff4_elec );
    IF( gv_prof_aff4_elec_cost IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff4_elec
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(補助科目_自販機販売手数料_自販リベート)
    --==================================================
    gv_prof_aff4_rebate := FND_PROFILE.VALUE( cv_prof_aff4_rebate );
    IF( gv_prof_aff4_rebate IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff4_rebate
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(補助科目_手数料_振込手数料)
    --==================================================
    gv_prof_aff4_transfer_fee := FND_PROFILE.VALUE( cv_prof_aff4_trfee );
    IF( gv_prof_aff4_transfer_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff4_trfee
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(顧客コード_ダミー値)
    --==================================================
    gv_prof_aff5_dummy := FND_PROFILE.VALUE( cv_prof_aff5_dummy );
    IF( gv_prof_aff5_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff5_dummy
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(企業コード_ダミー値)
    --==================================================
    gv_prof_aff6_dummy := FND_PROFILE.VALUE( cv_prof_aff6_dummy );
    IF( gv_prof_aff6_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff6_dummy
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(予備コード１_ダミー値)
    --==================================================
    gv_prof_aff7_dummy := FND_PROFILE.VALUE( cv_prof_aff7_dummy );
    IF( gv_prof_aff7_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff7_dummy
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(予備コード２_ダミー値)
    --==================================================
    gv_prof_aff8_dummy := FND_PROFILE.VALUE( cv_prof_aff8_dummy );
    IF( gv_prof_aff8_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff8_dummy
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(仕訳カテゴリ_販売手数料)
    --==================================================
    gv_prof_gl_category_bm := FND_PROFILE.VALUE( cv_prof_gl_ctg_bm );
    IF( gv_prof_gl_category_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_gl_ctg_bm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(仕訳カテゴリ_振替伝票)
    --==================================================
    gv_prof_gl_category_cng := FND_PROFILE.VALUE( cv_prof_gl_ctg_cng );
    IF( gv_prof_gl_category_cng IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_gl_ctg_cng
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(仕訳ソース_個別開発)
    --==================================================
    gv_prof_gl_source_cok := FND_PROFILE.VALUE( cv_prof_gl_src_cok );
    IF( gv_prof_gl_source_cok IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_gl_src_cok
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(振込元銀行名)
    --==================================================
    gv_prof_transf_bank := FND_PROFILE.VALUE( cv_prof_transf_bank );
    IF( gv_prof_transf_bank IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_transf_bank
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(振込元支店名)
    --==================================================
    gv_prof_transf_bankb := FND_PROFILE.VALUE( cv_prof_transf_bankb );
    IF( gv_prof_transf_bankb IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_transf_bankb
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(対象外消費税コード)
    --==================================================
    gv_prof_other_tax_code := FND_PROFILE.VALUE( cv_prof_other_tax_code );
    IF( gv_prof_other_tax_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_other_tax_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(販売手数料_消費税率)
    --==================================================
    gn_bm_tax_rate := TO_NUMBER(FND_PROFILE.VALUE( cv_prof_bm_tax_rate ));
    IF( gn_bm_tax_rate IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_bm_tax_rate
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- グループID取得
    --==================================================
    BEGIN
      SELECT TO_NUMBER( gjs.attribute1 ) AS group_id     -- グループID
      INTO gn_group_id
      FROM gl_je_sources gjs
      WHERE gjs.user_je_source_name = gv_prof_gl_source_cok
        AND gjs.language            = cv_lang
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_name_xxcok
                      , iv_name                 => cv_msg_cok_00024
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
       RAISE global_api_others_expt;
    END;
    IF( gn_group_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00024
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- バッチ名取得
    --==================================================
    gv_batch_name := xxcok_common_pkg.get_batch_name_f( gv_prof_gl_category_cng );
--
    --==================================================
    -- 検索バッチ名取得
    --==================================================
    gv_s_batch_name := gv_prof_gl_category_bm || '%'|| gv_prof_gl_source_cok || '%' ;
    --==================================================
    -- 計上日取得 / 未来日チェック
    --==================================================
    gd_gl_date := TO_DATE(iv_gl_date , cv_yyyymmdd_format);
    --
    -- 計上日が業務日付より未来日であればエラー
    IF( gd_process_date < gd_gl_date ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_10497
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- 会計期間情報取得
    --==================================================
    BEGIN
      xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf
      , ov_retcode                => lv_retcode
      , ov_errmsg                 => lv_errmsg
      , in_set_of_books_id        => gn_prof_set_of_books_id  -- 会計帳簿ID
      , iv_application_short_name => cv_appl_name_sqlgl    -- アプリケーション短縮名
      , id_object_date            => gd_gl_date               -- 計上日
      , on_period_year            => gn_period_year           -- 会計年度
      , ov_period_name            => gv_period_name           -- 会計期間名
      , ov_closing_status         => gv_closing_status        -- ステータス
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_name_xxcok
                      , iv_name                 => cv_msg_cok_00011
                      , iv_token_name1          => cv_tkn_proc_date
                      , iv_token_value1         => TO_CHAR( gd_gl_date, cv_yyyymmdd_format )
                      );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
    -- 会計期間ステータスがOPEN以外またはNULLの場合
    IF(    ( gv_closing_status <> cv_closing_status_open )
        OR ( gv_closing_status IS NULL                   )
    ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00042
                    , iv_token_name1          => cv_tkn_proc_date
                    , iv_token_value1         => TO_CHAR( gd_gl_date, cv_yyyymmdd_format )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- 従業員番号取得
    --==================================================
    BEGIN
      SELECT fu.user_name      user_name
           , papf.attribute28  dept_code
      INTO   gt_user_name
           , gt_section
      FROM   fnd_user             fu
           , per_all_people_f     papf
      WHERE  fu.user_id       = cn_created_by
        AND  papf.person_id   = fu.employee_id
        AND  gd_process_date BETWEEN papf.effective_start_date
                                 AND papf.effective_end_date
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_name_xxcok
                      , iv_name                 => cv_msg_cok_00005
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE global_api_others_expt;
    END;
--
    -- 所属拠点コードがNULLの場合
    IF( gt_section IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00012
                    , iv_token_name1          => cv_tkn_user_id
                    , iv_token_value1         => cn_created_by
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- 銀行支店ID
    --==================================================
    BEGIN
    SELECT abb.bank_branch_id
    INTO   gt_bank_branch_id
    FROM   ap_bank_branches abb
    WHERE  abb.bank_name        = gv_prof_transf_bank
      AND  abb.bank_branch_name = gv_prof_transf_bankb
    ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_name_xxcok
                      , iv_name                 => cv_msg_cok_10498
                      , iv_token_name1          => cv_tkn_bank_name
                      , iv_token_value1         => gv_prof_transf_bank
                      , iv_token_name2          => cv_tkn_ank_branch
                      , iv_token_value2         => gv_prof_transf_bankb
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE global_api_others_expt;
    END;
    --==================================================
    -- 伝票番号取得
    --==================================================
    gt_slip_number := xxcok_common_pkg.get_slip_number_f( cv_pkg_name );
    IF( gt_slip_number IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00025
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
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
   * Procedure Name   : get_pmt_amt
   * Description      : 振込額情報の取得 (A-2)
   *                    銀行手数料部門集計 (A-3)
   ***********************************************************************************/
  PROCEDURE get_pmt_amt(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_pmt_amt'; -- プログラム名
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
    lv_key_str        VARCHAR(100);
    lt_bank_charge_tx ap_bank_charge_lines.bank_charge_standard%TYPE DEFAULT 0;
    lt_bank_charge    NUMBER DEFAULT 0;
    lt_supplier_code  bank_charge_rec.supplier_code%TYPE;
    lt_p_amt_tax_sum  bank_charge_rec.p_amt_tax_sum%TYPE;
    
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
    --==================================================
    -- 銀行手数料ループ
    --==================================================
    << bank_charge_loop >>
    FOR bank_charge_rec IN bank_charge_cur LOOP
    --
      -- 初期化
      lt_bank_charge_tx := 0;
      lt_bank_charge    := 0;
      --
      -- 銀行手数料算出
      BEGIN
        SELECT /*+ LEADING(abc) */
          abcl.bank_charge_standard     -- 標準銀行手数料
        INTO lt_bank_charge_tx
        FROM ap_bank_charges      abc   -- 銀行手数料マスタ
            ,ap_bank_charge_lines abcl  -- 銀行手数料明細
        WHERE  abc.transferring_bank_branch_id = gt_bank_branch_id
          AND  abc.bank_charge_id              = abcl.bank_charge_id
          AND  abc.transferring_bank           = cv_code_one
          AND  abc.transferring_branch         = cv_code_one
          AND  abc.receiving_bank              = cv_code_other
          AND  abc.receiving_branch            = cv_code_all
          AND  bank_charge_rec.p_amt_tax_sum  >= NVL( abcl.trans_amount_from, 0 )
          AND  ( ( abcl.trans_amount_to IS NULL )
               OR (( abcl.trans_amount_to IS NOT NULL )
                  AND ( bank_charge_rec.p_amt_tax_sum  < abcl.trans_amount_to )
                  ) 
               )
        ;
        --
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
           lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appl_name_xxcok
                         , iv_name          => cv_msg_cok_10499
                         , iv_token_name1   => cv_tkn_slp_code
                         , iv_token_value1  => bank_charge_rec.supplier_code
                         , iv_token_name2   => cv_tkn_p_amt
                         , iv_token_value2  => bank_charge_rec.p_amt_tax_sum
                        );
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          RAISE global_process_expt;
        WHEN NO_DATA_FOUND THEN
           lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appl_name_xxcok
                         , iv_name          => cv_msg_cok_10499
                         , iv_token_name1   => cv_tkn_slp_code
                         , iv_token_value1  => bank_charge_rec.supplier_code
                         , iv_token_name2   => cv_tkn_p_amt
                         , iv_token_value2  => bank_charge_rec.p_amt_tax_sum
                        );
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          RAISE global_process_expt;
      END;
      -- 手数料がNULLの場合もエラー
      IF( lt_bank_charge_tx IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_name_xxcok
                      , iv_name          => cv_msg_cok_10499
                      , iv_token_name1   => cv_tkn_slp_code
                      , iv_token_value1  => bank_charge_rec.supplier_code
                      , iv_token_name2   => cv_tkn_p_amt
                      , iv_token_value2  => bank_charge_rec.p_amt_tax_sum
                     );
       lv_errbuf  := lv_errmsg;
       RAISE global_process_expt;
      END IF;
      --
      -- 税抜手数料算出
      lt_bank_charge := TRUNC(lt_bank_charge_tx / ( 1 + ( gn_bm_tax_rate / 100 ) ));
      --
      -- キー情報作成
      lv_key_str := bank_charge_rec.dept_code;
      --
      -- 部門別集計配列があれば加算。なければ配列生成。
      IF( bank_charge_v_tab.exists(lv_key_str) = TRUE ) THEN
        bank_charge_v_tab(lv_key_str).bank_charge := bank_charge_v_tab(lv_key_str).bank_charge + lt_bank_charge;
      ELSE
        bank_charge_v_tab(lv_key_str).dept_code   := bank_charge_rec.dept_code;
        bank_charge_v_tab(lv_key_str).bank_charge := lt_bank_charge;
      END IF;
      -- 全部門合計の銀行手数料算出
      gn_bank_charge_sum := gn_bank_charge_sum + lt_bank_charge;
    END LOOP bank_charge_loop;
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
  END get_pmt_amt;
--
  /**********************************************************************************
   * Procedure Name   : create_cr_data
   * Description      : 部門別仕訳の作成 (A-4)
   ***********************************************************************************/
  PROCEDURE create_cr_data(
    it_aff2_department  IN  VARCHAR2,     --   部門コード
    it_entered_dr       IN  NUMBER,       --   銀行手数料
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_cr_data'; -- プログラム名
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
    --一般会計OIFデータ挿入処理
    INSERT INTO gl_interface(
       status                         -- ステータス
      ,set_of_books_id                -- 会計帳簿ID
      ,accounting_date                -- 仕訳有効日付
      ,currency_code                  -- 通貨コード
      ,date_created                   -- 新規作成日付
      ,created_by                     -- 新規作成者ID
      ,actual_flag                    -- 残高タイプ
      ,user_je_category_name          -- 仕訳カテゴリ名
      ,user_je_source_name            -- 仕訳ソース名
      ,segment1                       -- 会社
      ,segment2                       -- 部門
      ,segment3                       -- 勘定科目
      ,segment4                       -- 補助科目
      ,segment5                       -- 顧客コード
      ,segment6                       -- 企業コード
      ,segment7                       -- 予備１
      ,segment8                       -- 予備２
      ,entered_dr                     -- 借方金額
      ,entered_cr                     -- 貸方金額
      ,reference1                     -- バッチ名
      ,reference4                     -- 仕訳名
      ,period_name                    -- 会計期間名
      ,group_id                       -- グループID
      ,attribute1                     -- 税区分
      ,attribute3                     -- 伝票番号
      ,attribute4                     -- 起票部門
      ,attribute5                     -- 伝票入力者
      ,context                        -- DFFコンテキスト
    )VALUES(
       cv_je_status_new               -- ステータス
      ,gn_prof_set_of_books_id        -- 会計帳簿ID
      ,gd_gl_date                     -- 仕訳有効日付
      ,cv_currency_code               -- 通貨コード
      ,SYSDATE                        -- 新規作成日付
      ,cn_created_by                  -- 新規作成者ID
      ,cv_balance_type_result         -- 残高タイプ
      ,gv_prof_gl_category_cng        -- 仕訳カテゴリ名
      ,gv_prof_gl_source_cok          -- 仕訳ソース名
      ,gv_prof_aff1_company_code      -- 会社
      ,it_aff2_department             -- 部門
      ,gv_prof_aff3_fee               -- 勘定科目
      ,gv_prof_aff4_transfer_fee      -- 補助科目
      ,gv_prof_aff5_dummy             -- 顧客コード
      ,gv_prof_aff6_dummy             -- 企業コード
      ,gv_prof_aff7_dummy             -- 予備１
      ,gv_prof_aff8_dummy             -- 予備２
      ,it_entered_dr
      ,NULL
      ,gv_batch_name                  -- バッチ名
      ,gt_slip_number                 -- 仕訳名
      ,gv_period_name                 -- 会計期間名
      ,gn_group_id                    -- グループID
      ,gv_prof_other_tax_code         -- 税区分
      ,gt_slip_number                 -- 伝票番号
      ,gt_section                     -- 起票部門
      ,gt_user_name                   -- 伝票入力者
      ,gv_prof_set_of_books_name      -- DFFコンテキスト
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_cr_data;
--
  /**********************************************************************************
   * Procedure Name   : create_dr_data
   * Description      : 振替元仕訳の作成 (A-5)
   ***********************************************************************************/
  PROCEDURE create_dr_data(
    it_entered_cr       IN  NUMBER,       --   銀行手数料合計
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_dr_data'; -- プログラム名
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
    --一般会計OIFデータ挿入処理
    INSERT INTO gl_interface(
       status                         -- ステータス
      ,set_of_books_id                -- 会計帳簿ID
      ,accounting_date                -- 仕訳有効日付
      ,currency_code                  -- 通貨コード
      ,date_created                   -- 新規作成日付
      ,created_by                     -- 新規作成者ID
      ,actual_flag                    -- 残高タイプ
      ,user_je_category_name          -- 仕訳カテゴリ名
      ,user_je_source_name            -- 仕訳ソース名
      ,segment1                       -- 会社
      ,segment2                       -- 部門
      ,segment3                       -- 勘定科目
      ,segment4                       -- 補助科目
      ,segment5                       -- 顧客コード
      ,segment6                       -- 企業コード
      ,segment7                       -- 予備１
      ,segment8                       -- 予備２
      ,entered_dr                     -- 借方金額
      ,entered_cr                     -- 貸方金額
      ,reference1                     -- バッチ名
      ,reference4                     -- 仕訳名
      ,period_name                    -- 会計期間名
      ,group_id                       -- グループID
      ,attribute1                     -- 税区分
      ,attribute3                     -- 伝票番号
      ,attribute4                     -- 起票部門
      ,attribute5                     -- 伝票入力者
      ,context                        -- DFFコンテキスト
    )VALUES(
       cv_je_status_new               -- ステータス
      ,gn_prof_set_of_books_id        -- 会計帳簿ID
      ,gd_gl_date                     -- 仕訳有効日付
      ,cv_currency_code               -- 通貨コード
      ,SYSDATE                        -- 新規作成日付
      ,cn_created_by                  -- 新規作成者ID
      ,cv_balance_type_result         -- 残高タイプ
      ,gv_prof_gl_category_cng        -- 仕訳カテゴリ名
      ,gv_prof_gl_source_cok          -- 仕訳ソース名
      ,gv_prof_aff1_company_code      -- 会社
      ,gv_prof_aff2_dept_adj          -- 部門
      ,gv_prof_aff3_fee               -- 勘定科目
      ,gv_prof_aff4_transfer_fee      -- 補助科目
      ,gv_prof_aff5_dummy             -- 顧客コード
      ,gv_prof_aff6_dummy             -- 企業コード
      ,gv_prof_aff7_dummy             -- 予備１
      ,gv_prof_aff8_dummy             -- 予備２
      ,NULL
      ,it_entered_cr
      ,gv_batch_name                  -- バッチ名
      ,gt_slip_number                 -- 仕訳名
      ,gv_period_name                 -- 会計期間名
      ,gn_group_id                    -- グループID
      ,gv_prof_other_tax_code         -- 税区分
      ,gt_slip_number                 -- 伝票番号
      ,gt_section                     -- 起票部門
      ,gt_user_name                   -- 伝票入力者
      ,gv_prof_set_of_books_name      -- DFFコンテキスト
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_dr_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_gl_date    IN  VARCHAR2,     --   計上日
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
    lv_end_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_key_str       VARCHAR2(5000) DEFAULT NULL;
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
    -- 初期処理 (A-1)
    -- ===============================
    init(
      iv_gl_date,        -- 計上日
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 振込額情報の取得(A-2) / 銀行手数料部門集計(A-3)
    -- ===============================
    get_pmt_amt(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
-- 
    -- 件数カウント
    gn_target_cnt := bank_charge_v_tab.count;
    --
    IF(gn_target_cnt > 0) THEN
      gn_target_cnt := gn_target_cnt + 1;
    END IF;
    -- 1番目の添字を設定
    lv_key_str := bank_charge_v_tab.first;
    -- 添字が取得できなくなるまでループ
    WHILE lv_key_str IS NOT NULL LOOP
      -- ===============================
      -- 部門別仕訳の作成 (A-4)
      -- ===============================
      create_cr_data(
        bank_charge_v_tab(lv_key_str).dept_code,         -- 部門コード
        bank_charge_v_tab(lv_key_str).bank_charge,       -- 銀行手数料
        lv_errbuf,                                       -- エラー・メッセージ           --# 固定 #
        lv_retcode,                                      -- リターン・コード             --# 固定 #
        lv_errmsg);                                      -- ユーザー・エラー・メッセージ --# 固定 #
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      -- 一般会計OIF登録件数
      gn_normal_cnt := gn_normal_cnt + 1;
      -- 次回の添字を設定
      lv_key_str := bank_charge_v_tab.next(lv_key_str);
    END LOOP;
    --
    -- ===============================
    -- 振替元仕訳の作成 (A-5)
    -- ===============================
    -- 部門別仕訳が1件もない場合は作成しない。
    IF( bank_charge_v_tab.count > 0 ) THEN
     create_dr_data(
       gn_bank_charge_sum,                              -- 銀行手数料
       lv_errbuf,                                       -- エラー・メッセージ           --# 固定 #
       lv_retcode,                                      -- リターン・コード             --# 固定 #
       lv_errmsg);                                      -- ユーザー・エラー・メッセージ --# 固定 #
     IF( lv_retcode = cv_status_error ) THEN
       lv_end_retcode := cv_status_error;
       RAISE global_process_expt;
     END IF;
     -- 一般会計OIF登録件数
     gn_normal_cnt := gn_normal_cnt + 1;
   END IF;
   --
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    iv_gl_date    IN  VARCHAR2       --   計上日
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
       iv_gl_date  -- 入力パラメータ「計上日」
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt   := 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
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
    --
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
END XXCOK017A02C;
/
