CREATE OR REPLACE PACKAGE BODY APPS.XXCCP007A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP007A08C(body)
 * Description      : 経費精算発生事由データ出力
 * MD.070           : 経費精算発生事由データ出力 (MD070_IPO_CCP_007_A08)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/12/02    1.0   Y.Shoji          [E_本稼動_13393]新規作成
 *  2015/12/16    1.1   Y.Shoji          [E_本稼動_13393]受入テスト障害対応
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
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP007A08C'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_gl_date_from       IN  VARCHAR2      --    1.GL記帳日 FROM
   ,iv_gl_date_to         IN  VARCHAR2      --    2.GL記帳日 TO
   ,iv_department_code    IN  VARCHAR2      --    3.部門コード
   ,iv_segment3_code1     IN  VARCHAR2      --    4.経費科目コード１
   ,iv_segment3_code2     IN  VARCHAR2      --    5.経費科目コード２
   ,iv_segment3_code3     IN  VARCHAR2      --    6.経費科目コード３
   ,iv_segment3_code4     IN  VARCHAR2      --    7.経費科目コード４
   ,iv_segment3_code5     IN  VARCHAR2      --    8.経費科目コード５
   ,iv_segment3_code6     IN  VARCHAR2      --    9.経費科目コード６
   ,iv_segment3_code7     IN  VARCHAR2      --   10.経費科目コード７
   ,iv_segment3_code8     IN  VARCHAR2      --   11.経費科目コード８
   ,iv_segment3_code9     IN  VARCHAR2      --   12.経費科目コード９
   ,iv_segment3_code10    IN  VARCHAR2      --   13.経費科目コード１０
   ,ov_errbuf             OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
    cv_msg_no_parameter     CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- パラメータなし
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
-- 2015.12.15 Ver1.1 Add Start
    cv_invoice_num_oie      CONSTANT VARCHAR2(4)  := 'OIE%';               -- 従業員経費精算
-- 2015.12.15 Ver1.1 Add End
--
    -- *** ローカル変数 ***
--
    --==================================================
    -- 出力用項目
    --==================================================
    lv_period_name               ap.ap_invoice_distributions_all.period_name%TYPE               DEFAULT NULL;  -- 会計期間
    lv_gl_date                   VARCHAR2(10)                                                   DEFAULT NULL;  -- GL記帳日
    lv_account_code              gl.gl_code_combinations.segment3%TYPE                          DEFAULT NULL;  -- 勘定科目（配分）
    lv_account_name              applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- 勘定科目名
    lv_sub_account_code          gl.gl_code_combinations.segment4%TYPE                          DEFAULT NULL;  -- 補助科目（配分）
    lv_sub_account_name          applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- 補助科目名
    lv_issued_department_code    ap.ap_invoices_all.attribute3%TYPE                             DEFAULT NULL;  -- 起票部門
    lv_department_code           gl.gl_code_combinations.segment2%TYPE                          DEFAULT NULL;  -- 部門（配分）
    lv_department_name           applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- 部門名（配分）
    lv_invoice_num               ap.ap_invoices_all.invoice_num%TYPE                            DEFAULT NULL;  -- 請求書番号
    lv_invoice_amount            VARCHAR2(15)                                                   DEFAULT NULL;  -- 請求書金額
    lv_amount                    VARCHAR2(15)                                                   DEFAULT NULL;  -- 配分金額
    lv_description               ap.ap_invoices_all.description%TYPE                            DEFAULT NULL;  -- 請求書摘要
    lv_dist_description          ap.ap_invoice_distributions_all.description%TYPE               DEFAULT NULL;  -- 請求書配分摘要
    lv_justification             ap.ap_invoice_distributions_all.justification%TYPE             DEFAULT NULL;  -- 経費発生事由
    lv_vendor_name               po.po_vendors.vendor_name%TYPE                                 DEFAULT NULL;  -- 仕入先名
    lv_vendor_code               po.po_vendors.segment1%TYPE                                    DEFAULT NULL;  -- 仕入先コード
    lv_partner_code              gl.gl_code_combinations.segment5%TYPE                          DEFAULT NULL;  -- 顧客コード（配分）
    lv_partner_name              applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- 顧客コード名
    lv_business_type_code        gl.gl_code_combinations.segment6%TYPE                          DEFAULT NULL;  -- 企業コード（配分）
    lv_business_type_name        applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- 企業コード名
    lv_pay_group                 ap.ap_invoices_all.pay_group_lookup_code%TYPE                  DEFAULT NULL;  -- 支払グループ
    lv_pay_curr_invoice_amount   VARCHAR2(15)                                                   DEFAULT NULL;  -- 支払済額
    lv_due_date                  VARCHAR2(10)                                                   DEFAULT NULL;  -- 支払期日
    lv_payment_status_flag       ap.ap_payment_schedules_all.payment_status_flag%TYPE           DEFAULT NULL;  -- 支払ステータス
    lv_hold_flag                 ap.ap_payment_schedules_all.hold_flag%TYPE                     DEFAULT NULL;  -- 支払予定保留フラグ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 経費精算データレコード取得
    CURSOR main_cur( iv_gl_date_from    IN VARCHAR2   --    1.GL記帳日 FROM
                    ,iv_gl_date_to      IN VARCHAR2   --    2.GL記帳日 TO
                    ,iv_department_code IN VARCHAR2   --    3.部門コード
                    ,iv_segment3_code1  IN VARCHAR2   --    4.経費科目コード１
                    ,iv_segment3_code2  IN VARCHAR2   --    5.経費科目コード２
                    ,iv_segment3_code3  IN VARCHAR2   --    6.経費科目コード３
                    ,iv_segment3_code4  IN VARCHAR2   --    7.経費科目コード４
                    ,iv_segment3_code5  IN VARCHAR2   --    8.経費科目コード５
                    ,iv_segment3_code6  IN VARCHAR2   --    9.経費科目コード６
                    ,iv_segment3_code7  IN VARCHAR2   --   10.経費科目コード７
                    ,iv_segment3_code8  IN VARCHAR2   --   11.経費科目コード８
                    ,iv_segment3_code9  IN VARCHAR2   --   12.経費科目コード９
                    ,iv_segment3_code10 IN VARCHAR2   --   13.経費科目コード１０
                   )
    IS
      SELECT
             aida.period_name                                  AS period_name               -- 会計期間
            ,aia.gl_date                                       AS gl_date                   -- GL記帳日
            ,gcc1.segment3                                     AS account_code              -- 勘定科目（配分）
            ,(SELECT a.aff_account_name        AS account_name
              FROM   apps.xxcff_aff_account_v a
              WHERE  gcc1.segment3 = a.aff_account_code)       AS account_name              -- 勘定科目名
            ,gcc1.segment4                                     AS sub_account_code          -- 補助科目（配分）
            ,(SELECT a.aff_sub_account_name    AS sub_account_name
              FROM   apps.xxcff_aff_sub_account_v a
              WHERE  gcc1.segment4 = a.aff_sub_account_code
              AND    gcc1.segment3 = a.aff_account_name)       AS sub_account_name          -- 補助科目名
            ,aia.attribute3                                    AS issued_department_code    -- 起票部門
            ,gcc1.segment2                                     AS department_code           -- 部門（配分）
            ,(SELECT a.aff_department_name     AS department_name
              FROM   apps.xxcff_aff_department_v a
              WHERE  gcc1.segment2 = a.aff_department_code)    AS department_name           -- 部門名（配分）
            ,aia.invoice_num                                   AS invoice_num               -- 請求書番号
            ,aia.invoice_amount                                AS invoice_amount            -- 請求書金額
            ,aida.amount                                       AS amount                    -- 配分金額
            ,aia.description                                   AS description               -- 請求書摘要
            ,aida.description                                  AS dist_description          -- 請求書配分摘要
            ,aida.justification                                AS justification             -- 経費発生事由
            ,pv.vendor_name                                    AS vendor_name               -- 仕入先名
            ,pv.segment1                                       AS vendor_code               -- 仕入先コード
            ,gcc1.segment5                                     AS partner_code              -- 顧客コード（配分）
            ,(SELECT a.aff_partner_name        AS partner_name
              FROM   apps.xxcff_aff_partner_v a
              WHERE  gcc1.segment5 = a.aff_partner_code)       AS partner_name              -- 顧客コード名
            ,gcc1.segment6                                     AS business_type_code        -- 企業コード（配分）
            ,(SELECT a.aff_business_type_name  AS business_type_name
              FROM   apps.xxcff_aff_business_type_v a
              WHERE  gcc1.segment6 = a.aff_business_type_code) AS business_type_name        -- 企業コード名
            ,aia.pay_group_lookup_code                         AS pay_group                 -- 支払グループ
            ,aia.pay_curr_invoice_amount                       AS pay_curr_invoice_amount   -- 支払済額
            ,apsa.due_date                                     AS due_date                  -- 支払期日
            ,apsa.payment_status_flag                          AS payment_status_flag       -- 支払ステータス
            ,apsa.hold_flag                                    AS hold_flag                 -- 支払予定保留フラグ
      FROM   apps.ap_invoices_all              aia    -- 請求書テーブル
            ,apps.ap_invoice_distributions_all aida   -- 請求書配分テーブル
            ,apps.fnd_lookup_values            flv1   -- 参照表
            ,apps.ap_terms_tl                  att    -- 支払条件テーブル
            ,apps.gl_code_combinations         gcc1   -- 勘定科目体系
            ,apps.ap_payment_schedules_all     apsa   -- 支払予定テーブル
            ,apps.po_vendors                   pv     -- 仕入先マスタ
      WHERE  aia.invoice_id                    = aida.invoice_id
      AND    aia.set_of_books_id               = aida.set_of_books_id
      AND    aia.pay_group_lookup_code         = flv1.lookup_code
      AND    flv1.lookup_type                  = 'PAY GROUP'
      AND    flv1.view_application_id          = 201                                     -- PO
      AND    flv1.language                     = userenv('LANG')
      AND    aia.terms_id                      = att.term_id
      AND    flv1.language                     = att.language
      AND    aida.dist_code_combination_id     = gcc1.code_combination_id
      AND    aia.invoice_id                    = apsa.invoice_id
      AND    aia.org_id                        = apsa.org_id
      AND    aia.vendor_id                     = pv.vendor_id
-- 2015.12.15 Ver1.1 Add Start
      AND    aia.invoice_num                   LIKE cv_invoice_num_oie
-- 2015.12.15 Ver1.1 Add End
      AND    aia.gl_date                       BETWEEN TO_DATE(iv_gl_date_from ,'YYYY/MM/DD HH24:MI:SS')
                                               AND     TO_DATE(iv_gl_date_to   ,'YYYY/MM/DD HH24:MI:SS')
                                                                                           -- 1,2.GL記帳日 範囲指定
      AND    aia.attribute3                    = NVL(iv_department_code , aia.attribute3)  -- 3.部門コード
      AND (
            ( iv_segment3_code1             IS NULL
          AND iv_segment3_code2             IS NULL
          AND iv_segment3_code3             IS NULL
          AND iv_segment3_code4             IS NULL
          AND iv_segment3_code5             IS NULL
          AND iv_segment3_code6             IS NULL
          AND iv_segment3_code7             IS NULL
          AND iv_segment3_code8             IS NULL
          AND iv_segment3_code9             IS NULL
          AND iv_segment3_code10            IS NULL
            )
        OR  ( gcc1.segment3                 IN ( iv_segment3_code1       -- 4.経費科目コード１
                                                ,iv_segment3_code2       -- 5.経費科目コード２
                                                ,iv_segment3_code3       -- 6.経費科目コード３
                                                ,iv_segment3_code4       -- 7.経費科目コード４
                                                ,iv_segment3_code5       -- 8.経費科目コード５
                                                ,iv_segment3_code6       -- 9.経費科目コード６
                                                ,iv_segment3_code7       -- 10.経費科目コード７
                                                ,iv_segment3_code8       -- 11.経費科目コード８
                                                ,iv_segment3_code9       -- 12.経費科目コード９
                                                ,iv_segment3_code10      -- 13.経費科目コード１０
                                               )
            )
          )
      ORDER BY aida.period_name  -- 会計期間
              ,aia.gl_date       -- GL記帳日
              ,gcc1.segment3     -- 勘定科目コード
              ,gcc1.segment4     -- 補助科目コード
              ,aia.attribute3    -- 起票部門コード
              ,aia.invoice_num   -- 請求書番号
      ;
    -- メインカーソルレコード型
    main_rec  main_cur%ROWTYPE;
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
    -- ===============================
    -- init部
    -- ===============================
    --==============================================================
    -- 入力パラメータ出力
    --==============================================================
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => 'GL記帳日 FROM      : ' || iv_gl_date_from
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => 'GL記帳日 TO        : ' || iv_gl_date_to
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '部門コード         : ' || iv_department_code
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード１   : ' || iv_segment3_code1
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード２   : ' || iv_segment3_code2
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード３   : ' || iv_segment3_code3
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード４   : ' || iv_segment3_code4
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード５   : ' || iv_segment3_code5
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード６   : ' || iv_segment3_code6
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード７   : ' || iv_segment3_code7
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード８   : ' || iv_segment3_code8
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード９   : ' || iv_segment3_code9
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '経費科目コード１０ : ' || iv_segment3_code10
                     );
--
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    -- GL記帳日FROM > GL記帳日TO の場合
    IF ( TO_DATE( iv_gl_date_from, 'YYYY/MM/DD HH24:MI:SS' ) > TO_DATE( iv_gl_date_to, 'YYYY/MM/DD HH24:MI:SS' ) ) THEN
      ov_errbuf  := 'GL記帳日 FROM は GL記帳日 TO 以前の日付を指定して下さい。';
      ov_retcode := cv_status_error;
    ELSE
--
      -- ===============================
      -- 処理部
      -- ===============================
--
      -- 項目名出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   =>           '"' || '会計期間'                || '"' -- 会計期間
                   || ',' || '"' || 'GL記帳日'                || '"' -- GL記帳日
                   || ',' || '"' || '勘定科目（配分）'        || '"' -- 勘定科目（配分）
                   || ',' || '"' || '勘定科目名'              || '"' -- 勘定科目名
                   || ',' || '"' || '補助科目（配分）'        || '"' -- 補助科目（配分）
                   || ',' || '"' || '補助科目名'              || '"' -- 補助科目名
                   || ',' || '"' || '起票部門'                || '"' -- 起票部門
                   || ',' || '"' || '部門（配分）'            || '"' -- 部門（配分）
                   || ',' || '"' || '部門名（配分）'          || '"' -- 部門名（配分）
                   || ',' || '"' || '請求書番号'              || '"' -- 請求書番号
                   || ',' || '"' || '請求書金額'              || '"' -- 請求書金額
                   || ',' || '"' || '配分金額'                || '"' -- 配分金額
                   || ',' || '"' || '請求書摘要'              || '"' -- 請求書摘要
                   || ',' || '"' || '請求書配分摘要'          || '"' -- 請求書配分摘要
                   || ',' || '"' || '経費発生事由'            || '"' -- 経費発生事由
                   || ',' || '"' || '仕入先名'                || '"' -- 仕入先名
                   || ',' || '"' || '仕入先コード'            || '"' -- 仕入先コード
                   || ',' || '"' || '顧客コード（配分）'      || '"' -- 顧客コード（配分）
                   || ',' || '"' || '顧客コード名'            || '"' -- 顧客コード名
                   || ',' || '"' || '企業コード（配分）'      || '"' -- 企業コード（配分）
                   || ',' || '"' || '企業コード名'            || '"' -- 企業コード名
                   || ',' || '"' || '支払グループ'            || '"' -- 支払グループ
                   || ',' || '"' || '支払済額'                || '"' -- 支払済額
                   || ',' || '"' || '支払期日'                || '"' -- 支払期日
                   || ',' || '"' || '支払ステータス'          || '"' -- 支払ステータス
                   || ',' || '"' || '支払予定保留フラグ'      || '"' -- 支払予定保留フラグ
      );
      -- データ部出力(CSV)
      FOR main_rec IN main_cur( iv_gl_date_from       --    1.GL記帳日 FROM
                               ,iv_gl_date_to         --    2.GL記帳日 TO
                               ,iv_department_code    --    3.部門コード
                               ,iv_segment3_code1     --    4.経費科目コード１
                               ,iv_segment3_code2     --    5.経費科目コード２
                               ,iv_segment3_code3     --    6.経費科目コード３
                               ,iv_segment3_code4     --    7.経費科目コード４
                               ,iv_segment3_code5     --    8.経費科目コード５
                               ,iv_segment3_code6     --    9.経費科目コード６
                               ,iv_segment3_code7     --   10.経費科目コード７
                               ,iv_segment3_code8     --   11.経費科目コード８
                               ,iv_segment3_code9     --   12.経費科目コード９
                               ,iv_segment3_code10    --   13.経費科目コード１０
                               ) LOOP
        --件数セット
        gn_target_cnt := gn_target_cnt + 1;
--
        --==================================================
        -- 出力用項目設定
        --==================================================
        lv_period_name               := main_rec.period_name;                            -- 会計期間
        lv_gl_date                   := TO_CHAR( main_rec.gl_date, 'YYYY/MM/DD' );       -- GL記帳日
        lv_account_code              := main_rec.account_code;                           -- 勘定科目（配分）
        lv_account_name              := main_rec.account_name;                           -- 勘定科目名
        lv_sub_account_code          := main_rec.sub_account_code;                       -- 補助科目（配分）
        lv_sub_account_name          := main_rec.sub_account_name;                       -- 補助科目名
        lv_issued_department_code    := main_rec.issued_department_code;                 -- 起票部門
        lv_department_code           := main_rec.department_code;                        -- 部門（配分）
        lv_department_name           := main_rec.department_name;                        -- 部門名（配分）
        lv_invoice_num               := main_rec.invoice_num;                            -- 請求書番号
        lv_invoice_amount            := TO_CHAR( main_rec.invoice_amount );              -- 請求書金額
        lv_amount                    := TO_CHAR( main_rec.amount );                      -- 配分金額
        lv_description               := main_rec.description;                            -- 請求書摘要
        lv_dist_description          := main_rec.dist_description;                       -- 請求書配分摘要
        lv_justification             := main_rec.justification;                          -- 経費発生事由
        lv_vendor_name               := main_rec.vendor_name;                            -- 仕入先名
        lv_vendor_code               := main_rec.vendor_code;                            -- 仕入先コード
        lv_partner_code              := main_rec.partner_code;                           -- 顧客コード（配分）
        lv_partner_name              := main_rec.partner_name;                           -- 顧客コード名
        lv_business_type_code        := main_rec.business_type_code;                     -- 企業コード（配分）
        lv_business_type_name        := main_rec.business_type_name;                     -- 企業コード名
        lv_pay_group                 := main_rec.pay_group;                              -- 支払グループ
        lv_pay_curr_invoice_amount   := TO_CHAR( main_rec.pay_curr_invoice_amount );     -- 支払済額
        lv_due_date                  := TO_CHAR( main_rec.due_date, 'YYYY/MM/DD' );      -- 支払期日
        lv_payment_status_flag       := main_rec.payment_status_flag;                    -- 支払ステータス
        lv_hold_flag                 := main_rec.hold_flag;                              -- 支払予定保留フラグ
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => 
                               '"' || lv_period_name               || '"' -- 会計期間
                     || ',' || '"' || lv_gl_date                   || '"' -- GL記帳日
                     || ',' || '"' || lv_account_code              || '"' -- 勘定科目（配分）
                     || ',' || '"' || lv_account_name              || '"' -- 勘定科目名
                     || ',' || '"' || lv_sub_account_code          || '"' -- 補助科目（配分）
                     || ',' || '"' || lv_sub_account_name          || '"' -- 補助科目名
                     || ',' || '"' || lv_issued_department_code    || '"' -- 起票部門
                     || ',' || '"' || lv_department_code           || '"' -- 部門（配分）
                     || ',' || '"' || lv_department_name           || '"' -- 部門名（配分）
                     || ',' || '"' || lv_invoice_num               || '"' -- 請求書番号
                     || ',' || '"' || lv_invoice_amount            || '"' -- 請求書金額
                     || ',' || '"' || lv_amount                    || '"' -- 配分金額
                     || ',' || '"' || lv_description               || '"' -- 請求書摘要
                     || ',' || '"' || lv_dist_description          || '"' -- 請求書配分摘要
                     || ',' || '"' || lv_justification             || '"' -- 経費発生事由
                     || ',' || '"' || lv_vendor_name               || '"' -- 仕入先名
                     || ',' || '"' || lv_vendor_code               || '"' -- 仕入先コード
                     || ',' || '"' || lv_partner_code              || '"' -- 顧客コード（配分）
                     || ',' || '"' || lv_partner_name              || '"' -- 顧客コード名
                     || ',' || '"' || lv_business_type_code        || '"' -- 企業コード（配分）
                     || ',' || '"' || lv_business_type_name        || '"' -- 企業コード名
                     || ',' || '"' || lv_pay_group                 || '"' -- 支払グループ
                     || ',' || '"' || lv_pay_curr_invoice_amount   || '"' -- 支払済額
                     || ',' || '"' || lv_due_date                  || '"' -- 支払期日
                     || ',' || '"' || lv_payment_status_flag       || '"' -- 支払ステータス
                     || ',' || '"' || lv_hold_flag                 || '"' -- 支払予定保留フラグ
        );
      END LOOP;
--
      -- 成功件数＝対象件数
      gn_normal_cnt  := gn_target_cnt;
      -- 対象件数=0であればメッセージ出力
      IF (gn_target_cnt = 0) THEN
       FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => CHR(10) || '対象データはありません。'
       );
      END IF;
    END IF;
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
    errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_gl_date_from       IN  VARCHAR2      --    1.GL記帳日 FROM
   ,iv_gl_date_to         IN  VARCHAR2      --    2.GL記帳日 TO
   ,iv_department_code    IN  VARCHAR2      --    3.部門コード
   ,iv_segment3_code1     IN  VARCHAR2      --    4.経費科目コード１
   ,iv_segment3_code2     IN  VARCHAR2      --    5.経費科目コード２
   ,iv_segment3_code3     IN  VARCHAR2      --    6.経費科目コード３
   ,iv_segment3_code4     IN  VARCHAR2      --    7.経費科目コード４
   ,iv_segment3_code5     IN  VARCHAR2      --    8.経費科目コード５
   ,iv_segment3_code6     IN  VARCHAR2      --    9.経費科目コード６
   ,iv_segment3_code7     IN  VARCHAR2      --   10.経費科目コード７
   ,iv_segment3_code8     IN  VARCHAR2      --   11.経費科目コード８
   ,iv_segment3_code9     IN  VARCHAR2      --   12.経費科目コード９
   ,iv_segment3_code10    IN  VARCHAR2      --   13.経費科目コード１０
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
       iv_gl_date_from       --    1.GL記帳日 FROM
      ,iv_gl_date_to         --    2.GL記帳日 TO
      ,iv_department_code    --    3.部門コード
      ,iv_segment3_code1     --    4.経費科目コード１
      ,iv_segment3_code2     --    5.経費科目コード２
      ,iv_segment3_code3     --    6.経費科目コード３
      ,iv_segment3_code4     --    7.経費科目コード４
      ,iv_segment3_code5     --    8.経費科目コード５
      ,iv_segment3_code6     --    9.経費科目コード６
      ,iv_segment3_code7     --   10.経費科目コード７
      ,iv_segment3_code8     --   11.経費科目コード８
      ,iv_segment3_code9     --   12.経費科目コード９
      ,iv_segment3_code10    --   13.経費科目コード１０
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
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
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP007A08C;
/