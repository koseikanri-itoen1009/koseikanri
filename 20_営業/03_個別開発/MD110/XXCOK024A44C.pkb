CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A44C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK024A44C (body)
 * Description      : 控除未作成入金相殺伝票CSV出力
 * MD.050           : 控除未作成入金相殺伝票CSV出力 MD050_COK_024_A44
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_receivable_slips   AR部門入力情報(未消込)データ抽出(A-2)
 *  chk_sales_deduction    販売控除情報（未消込）確認(A-3)
 *  output_data            データ出力(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/10/21    1.0   R.Oikawa         main新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000)  DEFAULT NULL;
  gv_sep_msg                VARCHAR2(2000)  DEFAULT NULL;
  gv_exec_user              VARCHAR2(100)   DEFAULT NULL;
  gv_conc_name              VARCHAR2(30)    DEFAULT NULL;
  gv_conc_status            VARCHAR2(30)    DEFAULT NULL;
  gn_target_cnt             NUMBER          DEFAULT NULL;    -- 対象件数
  gn_normal_cnt             NUMBER          DEFAULT NULL;    -- 正常件数
  gn_error_cnt              NUMBER          DEFAULT NULL;    -- エラー件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数警告例外 ***
  global_api_warn_expt      EXCEPTION;
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
  --*** 出力日 日付逆転チェック例外 ***
  global_date_rever_old_chk_expt    EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  --
  cv_pkg_name                 CONSTANT  VARCHAR2(100) := 'XXCOK024A44C';            -- パッケージ名
  cv_xxcok_short_name         CONSTANT  VARCHAR2(100) := 'XXCOK';                   -- 販物領域短縮アプリ名
  --
  cv_delimit                  CONSTANT  VARCHAR2(4)   := ',';                       -- 区切り文字
  cv_null                     CONSTANT  VARCHAR2(4)   := '';                        -- 空文字
  cv_half_space               CONSTANT  VARCHAR2(4)   := ' ';                       -- スペース
  cv_full_space               CONSTANT  VARCHAR2(4)   := '　';                      -- 全角スペース
  cv_const_y                  CONSTANT  VARCHAR2(1)   := 'Y';                       -- 'Y'
  cv_const_n                  CONSTANT  VARCHAR2(1)   := 'N';                       -- 'N'
  cv_perc                     CONSTANT  VARCHAR2(1)   := '%';                       -- '%'
  cv_lang                     CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );         -- 言語
  -- 数値
  cn_zero                     CONSTANT  NUMBER        := 0;                         -- 0
  cn_one                      CONSTANT  NUMBER        := 1;                         -- 1
  -- フラグ
  cv_flag_off                 CONSTANT VARCHAR2(1)    := '0';                       -- フラグOFF
  cv_flag_on                  CONSTANT VARCHAR2(1)    := '1';                       -- フラグON
  cv_flag_d                   CONSTANT VARCHAR2(1)    := 'D';                       -- 作成元区分(差額調整)
  cv_flag_u                   CONSTANT VARCHAR2(1)    := 'U';                       -- 作成元区分(アップロード)
  cv_flag_v                   CONSTANT VARCHAR2(1)    := 'V';                       -- 作成元区分 売上実績振替（振替割合）
  -- 書式マスク
  cv_date_format              CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';              -- 日付書式
  cv_date_format_time         CONSTANT  VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';   -- 日付書式(日時)
  cv_year_format              CONSTANT  VARCHAR2(10)  := 'YYYY';                    -- 日付書式(年)
  cv_month_format             CONSTANT  VARCHAR2(10)  := 'MM';                      -- 日付書式(日)
  --プロファイル
  cv_prof_trx_type            CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOK1_RA_TRX_TYPE_VARIABLE_CONS';     -- 取引タイプ_変動対価相殺
  -- 参照タイプ
  cv_type_header              CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XXCOK1_RECEIVABLE_SLIPS_HEAD';  -- 控除未作成入金相殺伝票用見出し
  cv_type_dec_pri_base        CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XXCOK1_DEC_PRIVILEGE_BASE';     -- 控除マスタ特権拠点
  cv_type_deduction_data      CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XXCOK1_DEDUCTION_DATA_TYPE';    -- 控除データ種類
  cv_type_slip_types          CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XX03_SLIP_TYPES';               -- 伝票種別
  cv_type_wf_statuses         CONSTANT  fnd_lookup_values.lookup_type%TYPE  := 'XX03_WF_STATUSES';              -- ステータス
  -- 参照タイプコード
  cv_code_eoh_024a44          CONSTANT  fnd_lookup_values.lookup_code%TYPE  := '024A44%';                       -- クイックコード（控除未作成入金相殺伝票用見出し）
  --メッセージ
  cv_msg_date_rever_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10651';              -- 日付逆転エラー
  cv_msg_parameter            CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10859';              -- パラメータ出力メッセージ
  cv_msg_proc_date_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00028';              -- 業務日付取得エラーメッセージ
  cv_msg_user_id_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10594';              -- ユーザーID取得エラーメッセージ
  cv_msg_user_base_code_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00012';              -- 所属拠点コード取得エラーメッセージ
  cv_msg_no_data_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00001';              -- 対象データなしエラーメッセージ
  cv_msg_profile_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00003';              -- プロファイル取得エラーメッセージ
  --トークン名
  cv_tkn_nm_rec_date_from     CONSTANT  VARCHAR2(100) := 'RECORD_DATE_FROM';              -- 計上日（FROM）
  cv_tkn_nm_rec_date_to       CONSTANT  VARCHAR2(100) := 'RECORD_DATE_TO';                -- 計上日（TO）
  cv_tkn_nm_cust_code         CONSTANT  VARCHAR2(100) := 'CUST_CODE';                     -- 顧客
  cv_tkn_nm_base_code         CONSTANT  VARCHAR2(100) := 'BASE_CODE';                     -- 起票部門
  cv_tkn_nm_user_name         CONSTANT  VARCHAR2(100) := 'USER_NAME';                     -- 入力者
  cv_tkn_nm_slip_line_type    CONSTANT  VARCHAR2(100) := 'SLIP_LINE_TYPE_NAME';           -- 請求内容
  cv_tkn_nm_payment_date      CONSTANT  VARCHAR2(100) := 'PAYMENT_SCHEDULED_DATE';        -- 入金予定日
  cv_tkn_nm_user_id           CONSTANT  VARCHAR2(100) := 'USER_ID';                       -- ユーザーID
  cv_tkn_nm_profile           CONSTANT  VARCHAR2(100) := 'PROFILE';                       -- プロファイル
  --支払条件
  cv_terms_name_00_00_00      CONSTANT  VARCHAR2(100) := '00_00_00';
  --月末日
  cv_last_day_30              CONSTANT  NUMBER        := 30;
  --
  cv_slip_type_80300          CONSTANT  VARCHAR2(5)   := '80300';                         -- 伝票種別:入金相殺
  cv_ar_status_appr           CONSTANT  VARCHAR2(2)   := '80';                            -- 承認済
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date           DATE                                                DEFAULT NULL; -- 業務日付
  gn_user_id                NUMBER                                              DEFAULT NULL; -- ユーザーID
  gv_user_base_code         VARCHAR2(150)                                       DEFAULT NULL; -- 所属拠点コード
  gv_privilege_flag         VARCHAR2(1)                                         DEFAULT NULL; -- 特権ユーザー判断フラグ
  gd_record_date_from       DATE                                                DEFAULT NULL; -- パラメータ：計上日(FROM)
  gd_record_date_to         DATE                                                DEFAULT NULL; -- パラメータ：計上日(TO)
  gv_cust_code              hz_cust_accounts.account_number%TYPE                DEFAULT NULL; -- パラメータ：顧客
  gv_base_code              xx03_receivable_slips.entry_department%TYPE         DEFAULT NULL; -- パラメータ：起票部門
  gv_user_name              per_all_people_f.full_name%TYPE                     DEFAULT NULL; -- パラメータ：入力者
  gv_slip_line_type_name    xx03_receivable_slips_line.slip_line_type_name%TYPE DEFAULT NULL; -- パラメータ：請求内容
  gd_payment_scheduled_date DATE                                                DEFAULT NULL; -- パラメータ：入金予定日
  gv_trans_type_name        xx03_receivable_slips.trans_type_name%TYPE          DEFAULT NULL; -- 取引タイプ
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  CURSOR get_receivable_slips_cur (
           id_record_date_from           IN DATE                                                 -- 計上日(FROM)
          ,id_record_date_to             IN DATE                                                 -- 計上日(TO)
          ,iv_cust_code                  IN hz_cust_accounts.account_number%TYPE                 -- 顧客
          ,iv_base_code                  IN xx03_receivable_slips.entry_department%TYPE          -- 起票部門
          ,iv_user_name                  IN per_all_people_f.employee_number%TYPE                -- 入力者
          ,iv_slip_line_type_name        IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- 請求内容
          ,id_payment_scheduled_date     IN DATE                                                 -- 入金予定日
          )
  IS
    SELECT    xrs.slip_type                 AS slip_type                       -- 伝票種別
             ,flv.description               AS slip_type_name                  -- 伝票種別名称
             ,xrs.receivable_num            AS receivable_num                  -- 伝票番号
             ,xrs.wf_status                 AS wf_status                       -- ステータス
             ,flv2.meaning                  AS wf_status_name                  -- ステータス名称
             ,xrs.entry_date                AS entry_date                      -- 起票日
             ,xrs.requestor_person_name     AS requestor_person_name           -- 申請者名
             ,xrs.approver_person_name      AS approver_person_name            -- 承認者名
             ,xrs.request_date              AS request_date                    -- 申請日
             ,xrs.approval_date             AS approval_date                   -- 承認日
             ,xrs.rejection_date            AS rejection_date                  -- 否認日
             ,xrs.account_approval_date     AS account_approval_date           -- 経理承認日
             ,xrs.ar_forward_date           AS ar_forward_date                 -- AR転送日
             ,xrs.approver_comments         AS approver_comments               -- 承認コメント
             ,xrs.invoice_date              AS invoice_date                    -- 請求書日付
             ,xrs.trans_type_name           AS trans_type_name                 -- 取引タイプ名
             ,hca.account_number            AS account_number                  -- 顧客コード
             ,xrs.customer_name             AS customer_name                   -- 顧客名
             ,xrs.customer_office_name      AS customer_office_name            -- 顧客事業所名
             ,xrs.receipt_method_name       AS receipt_method_name             -- 支払方法名
             ,xrs.terms_name                AS terms_name                      -- 支払条件名
             ,REPLACE( REPLACE( xrs.description, CHR(13), NULL)
                       ,CHR(10), NULL )     AS description                     -- 備考
             ,xrs.entry_department          AS entry_department                -- 起票部門
             ,ppv7.full_name                AS full_name                       -- 伝票入力者名
             ,xrs.gl_date                   AS gl_date                         -- 計上日
             ,xrs.payment_scheduled_date    AS payment_scheduled_date          -- 入金予定日
             ,xrsl.line_number              AS line_number                     -- 明細番号
             ,xrsl.slip_line_type_name      AS slip_line_type_name             -- 請求内容
             ,xrsl.slip_line_uom            AS slip_line_uom                   -- 単位
             ,xrsl.slip_line_unit_price     AS slip_line_unit_price            -- 単価
             ,xrsl.slip_line_quantity       AS slip_line_quantity              -- 数量
             ,xrsl.slip_line_entered_amount AS slip_line_entered_amount        -- 入力金額
             ,xrsl.tax_code                 AS tax_code                        -- 税区分コード
             ,xrsl.tax_name                 AS tax_name                        -- 税区分
             ,xrsl.entered_item_amount      AS entered_item_amount             -- 本体金額
             ,xrsl.entered_tax_amount       AS entered_tax_amount              -- 消費税額
             ,xrsl.slip_line_reciept_no     AS slip_line_reciept_no            -- 納品書番号
             ,REPLACE( REPLACE( xrsl.slip_description, CHR(13), NULL)
                       ,CHR(10), NULL )     AS slip_description                -- 備考（明細）
             ,xrsl.segment1                 AS segment1                        -- 会社
             ,xrsl.segment2                 AS segment2                        -- 部門
             ,xrsl.segment3                 AS segment3                        -- 勘定科目
             ,xrsl.segment4                 AS segment4                        -- 補助科目
             ,xrsl.segment5                 AS segment5                        -- 相手先
             ,xrsl.segment6                 AS segment6                        -- 事業区分
             ,xrsl.segment7                 AS segment7                        -- プロジェクト
             ,xrsl.segment8                 AS segment8                        -- 予備１
    FROM     xx03_receivable_slips      xrs                                    -- AR部門入力ヘッダー
            ,xx03_receivable_slips_line xrsl                                   -- AR部門入力明細
            ,fnd_lookup_values          flv                                    -- 参照表（伝票種別）
            ,fnd_lookup_values          flv2                                   -- 参照表（ステータス）
            ,hz_cust_accounts           hca                                    -- 顧客マスタ
            ,per_all_people_f           ppv7                                   -- 従業員マスタ
    WHERE    xrsl.receivable_id         = xrs.receivable_id
    AND      xrs.slip_type              = flv.lookup_code
    AND      flv.lookup_type            = cv_type_slip_types
    AND      flv.language               = cv_lang
    AND      flv.enabled_flag           = cv_const_y
    AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date
    AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
    AND      xrs.wf_status              = flv2.lookup_code
    AND      flv2.lookup_type           = cv_type_wf_statuses
    AND      flv2.language              = cv_lang
    AND      flv2.enabled_flag          = cv_const_y
    AND      NVL(flv2.start_date_active, gd_process_date) <= gd_process_date
    AND      NVL(flv2.end_date_active, gd_process_date)   >= gd_process_date
    AND      hca.cust_account_id        = xrs.customer_id
    AND      xrs.entry_person_id        = ppv7.person_id
    AND      NVL(ppv7.effective_start_date, gd_process_date) <= gd_process_date
    AND      NVL(ppv7.effective_end_date,   gd_process_date) >= gd_process_date
    AND      xrs.slip_type              = cv_slip_type_80300                    -- 伝票種別
    AND      xrs.trans_type_name        = gv_trans_type_name                    -- 取引タイプ名
    AND      xrs.wf_status              = cv_ar_status_appr                     -- ステータス（承認済）
    AND      xrsl.attribute8      IS NULL                                       -- 入金相殺消込ステータス
    AND      xrs.orig_invoice_num IS NULL                                       -- 修正元伝票番号
    AND      NOT EXISTS ( SELECT 1
                          FROM   xx03_receivable_slips xrs2
                          WHERE  xrs.receivable_num = xrs2.orig_invoice_num    -- AR部門入力.伝票番号= AR部門入力2.修正元伝票番号
                          AND    xrs2.wf_status = cv_ar_status_appr            -- ステータス(承認済)
                        )                                                      -- 伝票取消済みは除外
    AND      xrs.gl_date               >= id_record_date_from                  -- 計上日(FROM)
    AND      xrs.gl_date               <= id_record_date_to                    -- 計上日(TO)
    AND      ( 
               ( iv_cust_code IS NULL
               AND 1 = 1
               )
               OR
               ( iv_cust_code IS NOT NULL
               AND hca.account_number  = iv_cust_code
               )
             )                                                                 -- 顧客コード
    AND      ( 
               ( gv_privilege_flag      = cv_const_y                           -- 特権拠点
               AND iv_base_code IS NULL
               AND 1 = 1
               )
               OR
               ( gv_privilege_flag      = cv_const_y                           -- 特権拠点
               AND iv_base_code IS NOT NULL
               AND xrs.entry_department = iv_base_code
               )
               OR
               ( gv_privilege_flag     <> cv_const_y                           -- 特権拠点以外(所属拠点とパラメータ起票部門が同じ)
               AND gv_user_base_code    = iv_base_code
               AND xrs.entry_department = iv_base_code
               )
               OR
               ( gv_privilege_flag     <> cv_const_y                           -- 特権拠点以外(所属拠点とパラメータ起票部門が異なる)
               AND gv_user_base_code   <> iv_base_code
               AND 1 = 2
               )
             )                                                                 -- 起票部門
    AND      ( 
               ( iv_user_name IS NULL
               AND 1 = 1
               )
               OR
               ( iv_user_name IS NOT NULL
               AND ppv7.employee_number   = iv_user_name
               )
             )                                                                 -- 伝票入力者
    AND      ( 
               ( iv_slip_line_type_name IS NULL
               AND xrsl.slip_line_type_name IN ( SELECT amlv.name
                                                 FROM   ar_memo_lines_vl amlv
                                                 WHERE  amlv.attribute3 IS NOT NULL )
               )
               OR
               ( iv_slip_line_type_name IS NOT NULL
               AND xrsl.slip_line_type_name   = iv_slip_line_type_name
               )
             )                                                                 -- 請求内容
    AND      ( 
               ( id_payment_scheduled_date IS NULL
               AND 1 = 1
               )
               OR
               ( id_payment_scheduled_date IS NOT NULL
               AND TRUNC( xrs.payment_scheduled_date )  = id_payment_scheduled_date
               )
             )                                                                 -- 入金予定日
    ORDER BY 
             xrs.receivable_num                                                -- 伝票番号
            ,xrsl.line_number                                                  -- 明細番号
    ;
--
--
  -- 取得データ格納変数定義 (全出力)
  TYPE g_out_file_ttype IS TABLE OF get_receivable_slips_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_record_date_from             IN     VARCHAR2     -- 計上日(FROM)
   ,iv_record_date_to               IN     VARCHAR2     -- 計上日(TO)
   ,iv_cust_code                    IN     VARCHAR2     -- 顧客
   ,iv_base_code                    IN     VARCHAR2     -- 起票部門
   ,iv_user_name                    IN     VARCHAR2     -- 入力者
   ,iv_slip_line_type_name          IN     VARCHAR2     -- 請求内容
   ,iv_payment_scheduled_date       IN     VARCHAR2     -- 入金予定日
   ,ov_errbuf                       OUT    VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_para_msg                     VARCHAR2(5000)  DEFAULT NULL;     -- パラメータ出力メッセージ
    lv_para_msg2                    VARCHAR2(5000)  DEFAULT NULL;     -- パラメータ出力メッセージ
    ln_option_param_count           NUMBER := cn_zero;                -- 任意パラメータ設定数
    ln_privilege_base               NUMBER := cn_zero;                -- 登録・更新特権（0：特権なし、1：特権あり）
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode        := cv_status_normal;
    gv_privilege_flag := NULL;
--
--###########################  固定部 END   ############################
--
    --========================================
    -- 1.パラメータ出力処理
    --========================================
    lv_para_msg   :=  xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name           -- アプリ短縮名
                                               ,iv_name               =>  cv_msg_parameter              -- パラメータ出力メッセージ
                                               ,iv_token_name1        =>  cv_tkn_nm_rec_date_from       -- トークン：計上日（FROM）
                                               ,iv_token_value1       =>  iv_record_date_from           --           計上日（FROM）
                                               ,iv_token_name2        =>  cv_tkn_nm_rec_date_to         -- トークン：計上日（TO）
                                               ,iv_token_value2       =>  iv_record_date_to             --           計上日（TO）
                                               ,iv_token_name3        =>  cv_tkn_nm_cust_code           -- トークン：顧客
                                               ,iv_token_value3       =>  iv_cust_code                  --           顧客
                                               ,iv_token_name4        =>  cv_tkn_nm_base_code           -- トークン：起票部門
                                               ,iv_token_value4       =>  iv_base_code                  --           起票部門
                                               ,iv_token_name5        =>  cv_tkn_nm_user_name           -- トークン：入力者
                                               ,iv_token_value5       =>  iv_user_name                  --           入力者
                                               ,iv_token_name6        =>  cv_tkn_nm_slip_line_type      -- トークン：請求内容
                                               ,iv_token_value6       =>  iv_slip_line_type_name        --           請求内容
                                               ,iv_token_name7        =>  cv_tkn_nm_payment_date        -- トークン：入金予定日
                                               ,iv_token_value7       =>  iv_payment_scheduled_date     --           入金予定日
                                               );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- パラメータを変数に格納
    gd_record_date_from       := TO_DATE( iv_record_date_from ,cv_date_format);       -- パラメータ：計上日(FROM)
    gd_record_date_to         := TO_DATE( iv_record_date_to ,cv_date_format);         -- パラメータ：計上日(TO)
    gv_cust_code              := iv_cust_code;                                        -- パラメータ：顧客
    gv_base_code              := iv_base_code;                                        -- パラメータ：起票部門
    gv_user_name              := iv_user_name;                                        -- パラメータ：入力者
    gv_slip_line_type_name    := iv_slip_line_type_name;                              -- パラメータ：請求内容
    gd_payment_scheduled_date := TO_DATE( iv_payment_scheduled_date ,cv_date_format); -- パラメータ：入金予定日
--
    --========================================
    -- 2.入力パラメータチェック
    --========================================
    -- 計上日(FROM)が計上日(TO)より未来日の場合エラー
    IF ( gd_record_date_from > gd_record_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application => cv_xxcok_short_name,
                                            iv_name        => cv_msg_date_rever_err
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.業務日付取得処理
    --========================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application => cv_xxcok_short_name,
                                            iv_name        => cv_msg_proc_date_err
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.ユーザーID取得処理
    --========================================
    gn_user_id := fnd_global.user_id;
    IF ( gn_user_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application => cv_xxcok_short_name,
                                            iv_name        => cv_msg_user_id_err
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.所属拠点コード取得処理
    --========================================
    gv_user_base_code := xxcok_common_pkg.get_base_code_f(
                                                          id_proc_date => gd_process_date,
                                                          in_user_id   => gn_user_id
                                                         );
    IF ( gv_user_base_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcok_short_name,
                                            iv_name         => cv_msg_user_base_code_err,
                                            iv_token_name1  => cv_tkn_nm_user_id,
                                            iv_token_value1 => gn_user_id
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.特権ユーザー確認処理
    --========================================
    -- 6-1 特権拠点の所属ユーザーか確認
    BEGIN
      SELECT  COUNT(1)            AS privilege_base_cnt
      INTO    ln_privilege_base
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type      = cv_type_dec_pri_base
      AND     flv.lookup_code      = gv_user_base_code
      AND     flv.enabled_flag     = cv_const_y
      AND     flv.language         = cv_lang
      AND     gd_process_date BETWEEN flv.start_date_active 
                               AND NVL(flv.end_date_active,gd_process_date)
      ;
    END;
--
    -- 特権拠点ユーザーの判別
    IF (ln_privilege_base >= cn_one) THEN
      gv_privilege_flag  := cv_const_y;
    ELSE
      gv_privilege_flag  := cv_const_n;
      -- 6-2 パラメータの起票部門が未設定の場合、所属拠点を設定
      IF ( gv_base_code IS NULL ) THEN
        gv_base_code := gv_user_base_code;
      END IF;
    END IF;
--
    --======================================
    -- 7.XXCOK:取引タイプ_変動対価相殺の取得
    --======================================
    gv_trans_type_name := FND_PROFILE.VALUE( cv_prof_trx_type );
    IF ( gv_trans_type_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_msg_profile_err   -- プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_nm_profile
                    ,iv_token_value1 => cv_prof_trx_type
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_receivable_slips
   * Description      : AR部門入力情報(未消込)データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_receivable_slips(
    ov_errbuf                       OUT    VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receivable_slips'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
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
    ov_retcode    := cv_status_normal;
    gn_target_cnt := cn_zero;
--
--###########################  固定部 END   ############################
--
    -- 対象データ取得
    OPEN get_receivable_slips_cur (
            id_record_date_from       => gd_record_date_from        -- 計上日(FROM)
           ,id_record_date_to         => gd_record_date_to          -- 計上日(TO)
           ,iv_cust_code              => gv_cust_code               -- 顧客
           ,iv_base_code              => gv_base_code               -- 起票部門
           ,iv_user_name              => gv_user_name               -- 入力者
           ,iv_slip_line_type_name    => gv_slip_line_type_name     -- 請求内容
           ,id_payment_scheduled_date => gd_payment_scheduled_date  -- 入金予定日
          );
    FETCH get_receivable_slips_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_receivable_slips_cur;
    -- 処理件数カウント
    gn_target_cnt := gt_out_file_tab.COUNT;
--
    -- 抽出データが0件だった場合警告
    IF  gn_target_cnt = cn_zero THEN
      RAISE global_api_warn_expt;
    END IF;
--
--
  EXCEPTION
--##################################  固定例外処理部 START   #################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF get_receivable_slips_cur%ISOPEN THEN
        CLOSE get_receivable_slips_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_receivable_slips;
--
  /**********************************************************************************
   * Procedure Name   : chk_sales_deduction
   * Description      : 販売控除情報（未消込）確認(A-3)
   ***********************************************************************************/
  PROCEDURE chk_sales_deduction
  (
      iv_cust_code              IN     hz_cust_accounts.account_number%TYPE                 -- 顧客コード
     ,iv_slip_line_type_name    IN     xx03_receivable_slips_line.slip_line_type_name%TYPE  -- 請求内容
     ,iv_terms_name             IN     xx03_receivable_slips.terms_name%TYPE                -- 支払条件名
     ,id_invoice_date           IN     DATE                                                 -- 請求書日付
     ,id_payment_scheduled_date IN     DATE                                                 -- 入金予定日
     ,on_cnt                    OUT    NUMBER                                               -- 販売控除情報件数
     ,on_upload_cnt             OUT    NUMBER                                               -- 販売控除情報件数(アップロード)
     ,ov_errbuf                 OUT    VARCHAR2     -- エラー・メッセージ                   --# 固定 #
     ,ov_retcode                OUT    VARCHAR2     -- リターン・コード                     --# 固定 #
     ,ov_errmsg                 OUT    VARCHAR2     -- ユーザー・エラー・メッセージ         --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_sales_deduction'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_derivation_month       NUMBER  DEFAULT NULL;            -- 計上日導出用の月
    ln_derivation_date        NUMBER  DEFAULT NULL;            -- 計上日導出用の日
    ld_derivation_record_date DATE    DEFAULT NULL;            -- 計上日導出ロジックで導出した日付
    lb_derivation_err_flg     BOOLEAN DEFAULT FALSE;           -- 計上日導出フラグ エラーの場合、TRUE
    ln_cnt                    NUMBER  := 0;                    -- 販売控除件数
    ln_upload_cnt             NUMBER  := 0;                    -- 販売控除件数（アップロードのみ）
    -- *** ローカル・カーソル ***
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
    -- 対象計上日導出
    ------------------------------------------
    IF ( iv_terms_name = cv_terms_name_00_00_00 ) THEN
    -- 支払条件名が「00_00_00」の場合、A-2で取得した請求書日付を対象計上日とする。
      ld_derivation_record_date := id_invoice_date;
    ELSE
      BEGIN
        ln_derivation_month := TO_NUMBER( SUBSTR( iv_terms_name, 7, 2 ) );
        ln_derivation_date  := TO_NUMBER( SUBSTR( iv_terms_name, 1, 2 ) );
      EXCEPTION
        WHEN VALUE_ERROR THEN
        ld_derivation_record_date := NULL;
        lb_derivation_err_flg     := TRUE;
      END;
      --
      IF ( lb_derivation_err_flg = FALSE ) THEN
        BEGIN
          -- 入金予定日から1で取得した月を減算する。
          ld_derivation_record_date := ADD_MONTHS( id_payment_scheduled_date, -ln_derivation_month );
          --
          IF ( ln_derivation_date = cv_last_day_30 ) THEN
            -- 日が30の場合、減算した入金予定日の月末日を設定する。
            ld_derivation_record_date := TRUNC( LAST_DAY( ld_derivation_record_date ) );
          ELSE
            -- 日が30以外の場合、減算した入金予定日に2で取得した日を設定する。
            ld_derivation_record_date := TO_DATE( TO_CHAR( ld_derivation_record_date, cv_year_format ) 
                                                  || TO_CHAR( ld_derivation_record_date, cv_month_format ) 
                                                  || SUBSTR( iv_terms_name, 1, 2 ) , cv_date_format );
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            ld_derivation_record_date := NULL;
        END;
      END IF;
    END IF;
--
    ------------------------------------------
    -- 販売控除情報（未消込）取得
    ------------------------------------------
    BEGIN
      SELECT  /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
              COUNT(*)   AS cnt
      INTO    ln_cnt
      FROM    xxcok_sales_deduction xsd                                                           -- 販売控除情報
      WHERE   xsd.recon_slip_num IS NULL                                                          -- 支払伝票番号
      AND     xsd.status              = cv_const_n                                                -- ステータス:N(新規)
      AND     xsd.customer_code_from IN ( SELECT xchv.ship_account_number AS ship_account_number  -- 振替元顧客コード
                                          FROM   xxcfr_cust_hierarchy_v xchv
                                          WHERE  xchv.cash_account_number = iv_cust_code
                                          OR     xchv.bill_account_number = iv_cust_code
                                          OR     xchv.ship_account_number = iv_cust_code
                                        )
      AND     xsd.data_type          IN ( SELECT flv.lookup_code AS code                          -- データ種類
                                          FROM   fnd_lookup_values flv
                                          WHERE  flv.lookup_type          = cv_type_deduction_data
                                          AND    flv.language             = cv_lang
                                          AND    flv.enabled_flag         = cv_const_y
                                          AND    flv.attribute14          = ( SELECT amlv.attribute3
                                                                              FROM   ar_memo_lines_vl amlv
                                                                              WHERE  amlv.attribute3 IS NOT NULL
                                                                              AND    amlv.name =  iv_slip_line_type_name
                                                                            )
                                          AND    NVL(flv.start_date_active, gd_process_date) <= gd_process_date
                                          AND    NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
                                        )
      AND     xsd.record_date        <= ld_derivation_record_date                             -- 対象計上日導出ロジックで導出した日付
      AND     xsd.source_category    NOT IN ( cv_flag_d, cv_flag_u )                          -- 作成元区分 NOT IN  D:差額調整,U:アップロード
      AND     (
               ( xsd.source_category          = cv_flag_v                                     -- 作成元区分 = V:売上実績振替（振替割合）
                 AND xsd.report_decision_flag = cv_flag_on                                    -- 速報確定フラグ:1(実績振替確定済み)
               )
              OR
               ( xsd.source_category         <> cv_flag_v                                     -- 作成元区分がV:売上実績振替（振替割合）以外
                 AND xsd.report_decision_flag IS NULL                                         -- 速報確定フラグ IS NULL)
               )
              )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ln_cnt := 0;
    END;
--
    ------------------------------------------
    -- 販売控除情報アップロード（未消込）取得
    ------------------------------------------
    IF ( ln_cnt = 0 ) THEN 
      -- アップロードのデータのみ存在しているか確認
      BEGIN
        SELECT  /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
                COUNT(*)   AS cnt
        INTO    ln_upload_cnt
        FROM    xxcok_sales_deduction xsd                                                           -- 販売控除情報
        WHERE   xsd.recon_slip_num IS NULL                                                          -- 支払伝票番号
        AND     xsd.status              = cv_const_n                                                -- ステータス:N(新規)
        AND     xsd.customer_code_from IN ( SELECT xchv.ship_account_number AS ship_account_number  -- 振替元顧客コード
                                            FROM   xxcfr_cust_hierarchy_v xchv
                                            WHERE  xchv.cash_account_number = iv_cust_code
                                            OR     xchv.bill_account_number = iv_cust_code
                                            OR     xchv.ship_account_number = iv_cust_code
                                          )
        AND     xsd.data_type          IN ( SELECT flv.lookup_code AS code                          -- データ種類
                                            FROM   fnd_lookup_values flv
                                            WHERE  flv.lookup_type          = cv_type_deduction_data
                                            AND    flv.language             = cv_lang
                                            AND    flv.enabled_flag         = cv_const_y
                                            AND    flv.attribute14          = ( SELECT amlv.attribute3
                                                                                FROM   ar_memo_lines_vl amlv
                                                                                WHERE  amlv.attribute3 IS NOT NULL
                                                                                AND    amlv.name =  iv_slip_line_type_name
                                                                              )
                                            AND    NVL(flv.start_date_active, gd_process_date) <= gd_process_date
                                            AND    NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
                                          )
        AND     xsd.record_date        <= ld_derivation_record_date                           -- 対象計上日導出ロジックで導出した日付
        AND     xsd.source_category    = cv_flag_u                                            -- 作成元区分 = U:アップロード
        AND     xsd.report_decision_flag IS NULL                                              -- 速報確定フラグ IS NULL
        ;
      EXCEPTION
        WHEN OTHERS THEN
          ln_upload_cnt := 0;
      END;
    END IF;
--
    -- アウトパラメータに設定
    on_cnt        := ln_cnt;
    on_upload_cnt := ln_upload_cnt;
--
  EXCEPTION
--##################################  固定例外処理部 START   #################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END chk_sales_deduction;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : データ出力(A-4)
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
    lv_errbuf     VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg     VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_line_data              VARCHAR2(5000)  DEFAULT NULL;        -- OUTPUTデータ編集用
    ln_cnt                    NUMBER          := 0;                -- 販売控除情報件数
    ln_upload_cnt             NUMBER          := 0;                -- 販売控除情報件数(アップロード)
    lv_upload_flag            VARCHAR2(1)     DEFAULT NULL;        -- アップロードのみフラグ
--
    -- *** ローカル・カーソル ***
    --見出し取得用カーソル
    CURSOR header_cur
    IS
      SELECT  flv.description  head                                                -- 摘要：出力用見出し
      FROM    fnd_lookup_values flv
      WHERE   flv.language        = cv_lang                                        -- 言語
      AND     flv.lookup_type     = cv_type_header                                 -- 控除未作成入金相殺伝票用見出し
      AND     flv.lookup_code LIKE cv_code_eoh_024a44                              -- クイックコード（控除未作成入金相殺伝票用見出し）
      AND     gd_process_date    >= NVL( flv.start_date_active, gd_process_date )  -- 有効開始日
      AND     gd_process_date    <= NVL( flv.end_date_active,   gd_process_date )  -- 有効終了日
      AND     flv.enabled_flag    = cv_const_y                                     -- 使用可能
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
    ------------------------------------------
    -- データ出力
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
--
      -- ===============================
      -- A-3  販売控除情報（未消込）確認
      -- ===============================
      chk_sales_deduction( 
                            iv_cust_code              => gt_out_file_tab(i).account_number           -- 顧客
                           ,iv_slip_line_type_name    => gt_out_file_tab(i).slip_line_type_name      -- 請求内容
                           ,iv_terms_name             => gt_out_file_tab(i).terms_name               -- 支払条件名
                           ,id_invoice_date           => gt_out_file_tab(i).invoice_date             -- 請求書日付
                           ,id_payment_scheduled_date => gt_out_file_tab(i).payment_scheduled_date   -- 入金予定日
                           ,on_cnt                    => ln_cnt                                      -- 販売控除情報件数
                           ,on_upload_cnt             => ln_upload_cnt                               -- 販売控除情報件数(アップロード)
                           ,ov_errbuf                 => lv_errbuf                                   -- エラー・メッセージ           --# 固定 #
                           ,ov_retcode                => lv_retcode                                  -- リターン・コード             --# 固定 #
                           ,ov_errmsg                 => lv_errmsg                                   -- ユーザー・エラー・メッセージ --# 固定 #
                           );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- アップロードのみフラグの設定
      IF ( ln_upload_cnt = 0 ) THEN
        lv_upload_flag := NULL;
      ELSE
        lv_upload_flag := cv_const_y;
      END IF;
--
      -- 消込対象となる販売控除情報がない場合
      IF ( ln_cnt = 0 ) THEN
        --データを編集
        lv_line_data :=     gt_out_file_tab(i).slip_type                                          -- 伝票種別
           || cv_delimit || gt_out_file_tab(i).slip_type_name                                     -- 伝票種別名称
           || cv_delimit || gt_out_file_tab(i).receivable_num                                     -- 伝票番号
           || cv_delimit || gt_out_file_tab(i).wf_status                                          -- ステータス
           || cv_delimit || gt_out_file_tab(i).wf_status_name                                     -- ステータス名称
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).entry_date ,cv_date_format)                -- 起票日
           || cv_delimit || gt_out_file_tab(i).requestor_person_name                              -- 申請者名
           || cv_delimit || gt_out_file_tab(i).approver_person_name                               -- 承認者名
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).request_date ,cv_date_format)              -- 申請日
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).approval_date ,cv_date_format)             -- 承認日
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).rejection_date ,cv_date_format)            -- 否認日
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).account_approval_date ,cv_date_format)     -- 経理承認日
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).ar_forward_date ,cv_date_format)           -- AR転送日
           || cv_delimit || gt_out_file_tab(i).approver_comments                                  -- 承認コメント
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).invoice_date ,cv_date_format)              -- 請求書日付
           || cv_delimit || gt_out_file_tab(i).trans_type_name                                    -- 取引タイプ名
           || cv_delimit || gt_out_file_tab(i).account_number                                     -- 顧客コード
           || cv_delimit || gt_out_file_tab(i).customer_name                                      -- 顧客名
           || cv_delimit || gt_out_file_tab(i).customer_office_name                               -- 顧客事業所名
           || cv_delimit || gt_out_file_tab(i).receipt_method_name                                -- 支払方法名
           || cv_delimit || gt_out_file_tab(i).terms_name                                         -- 支払条件名
           || cv_delimit || gt_out_file_tab(i).description                                        -- 備考
           || cv_delimit || gt_out_file_tab(i).entry_department                                   -- 起票部門
           || cv_delimit || gt_out_file_tab(i).full_name                                          -- 伝票入力者名
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).gl_date ,cv_date_format)                   -- 計上日
           || cv_delimit || TO_CHAR(gt_out_file_tab(i).payment_scheduled_date ,cv_date_format)    -- 入金予定日
           || cv_delimit || gt_out_file_tab(i).line_number                                        -- 明細番号
           || cv_delimit || gt_out_file_tab(i).slip_line_type_name                                -- 請求内容
           || cv_delimit || gt_out_file_tab(i).slip_line_uom                                      -- 単位
           || cv_delimit || gt_out_file_tab(i).slip_line_unit_price                               -- 単価
           || cv_delimit || gt_out_file_tab(i).slip_line_quantity                                 -- 数量
           || cv_delimit || gt_out_file_tab(i).slip_line_entered_amount                           -- 入力金額
           || cv_delimit || gt_out_file_tab(i).tax_code                                           -- 税区分コード
           || cv_delimit || gt_out_file_tab(i).tax_name                                           -- 税区分
           || cv_delimit || gt_out_file_tab(i).entered_item_amount                                -- 本体金額
           || cv_delimit || gt_out_file_tab(i).entered_tax_amount                                 -- 消費税額
           || cv_delimit || gt_out_file_tab(i).slip_line_reciept_no                               -- 納品書番号
           || cv_delimit || gt_out_file_tab(i).slip_description                                   -- 備考（明細）
           || cv_delimit || gt_out_file_tab(i).segment1                                           -- 会社
           || cv_delimit || gt_out_file_tab(i).segment2                                           -- 部門
           || cv_delimit || gt_out_file_tab(i).segment3                                           -- 勘定科目
           || cv_delimit || gt_out_file_tab(i).segment4                                           -- 補助科目
           || cv_delimit || gt_out_file_tab(i).segment5                                           -- 相手先
           || cv_delimit || gt_out_file_tab(i).segment6                                           -- 事業区分
           || cv_delimit || gt_out_file_tab(i).segment7                                           -- プロジェクト
           || cv_delimit || gt_out_file_tab(i).segment8                                           -- 予備１
           || cv_delimit || lv_upload_flag                                                        -- アップロードのみフラグ
        ;
        -- データを出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_line_data
        );
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP data_output;
--
  EXCEPTION
--##################################  固定例外処理部 START   #################################
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
      IF header_cur%ISOPEN THEN
        CLOSE header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--##################################  固定部 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain( iv_record_date_from             IN     VARCHAR2  -- 計上日(FROM)
                    ,iv_record_date_to               IN     VARCHAR2  -- 計上日(TO)
                    ,iv_cust_code                    IN     VARCHAR2  -- 顧客
                    ,iv_base_code                    IN     VARCHAR2  -- 起票部門
                    ,iv_user_name                    IN     VARCHAR2  -- 入力者
                    ,iv_slip_line_type_name          IN     VARCHAR2  -- 請求内容
                    ,iv_payment_scheduled_date       IN     VARCHAR2  -- 入金予定日
                    ,ov_errbuf                       OUT    VARCHAR2  -- エラー・メッセージ           --# 固定 #
                    ,ov_retcode                      OUT    VARCHAR2  -- リターン・コード             --# 固定 #
                    ,ov_errmsg                       OUT    VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
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
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init( 
          iv_record_date_from       => iv_record_date_from            -- 計上日(FROM)
         ,iv_record_date_to         => iv_record_date_to              -- 計上日(TO)
         ,iv_cust_code              => iv_cust_code                   -- 顧客
         ,iv_base_code              => iv_base_code                   -- 起票部門
         ,iv_user_name              => iv_user_name                   -- 入力者
         ,iv_slip_line_type_name    => iv_slip_line_type_name         -- 請求内容
         ,iv_payment_scheduled_date => iv_payment_scheduled_date      -- 入金予定日
         ,ov_errbuf                 => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
         ,ov_retcode                => lv_retcode                     -- リターン・コード             --# 固定 #
         ,ov_errmsg                 => lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
         );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  支払未連携控除データ抽出
    -- ===============================
    get_receivable_slips( 
                          ov_errbuf  => lv_errbuf      -- エラー・メッセージ           --# 固定 #
                         ,ov_retcode => lv_retcode     -- リターン・コード             --# 固定 #
                         ,ov_errmsg  => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
                         );
--
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name,
                                             iv_name               =>  cv_msg_no_data_err
                                            );
      RAISE global_api_warn_expt;
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  データ出力
    -- ===============================
    output_data(
                 ov_errbuf  => lv_errbuf              -- エラー・メッセージ           --# 固定 #
                ,ov_retcode => lv_retcode             -- リターン・コード             --# 固定 #
                ,ov_errmsg  => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
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
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,iv_record_date_from             IN     VARCHAR2          -- 計上日(FROM)
   ,iv_record_date_to               IN     VARCHAR2          -- 計上日(TO)
   ,iv_cust_code                    IN     VARCHAR2          -- 顧客
   ,iv_base_code                    IN     VARCHAR2          -- 起票部門
   ,iv_user_name                    IN     VARCHAR2          -- 入力者
   ,iv_slip_line_type_name          IN     VARCHAR2          -- 請求内容
   ,iv_payment_scheduled_date       IN     VARCHAR2          -- 入金予定日
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100)   DEFAULT NULL;  -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   ###########################
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
       iv_record_date_from             -- 計上日(FROM)
      ,iv_record_date_to               -- 計上日(TO)
      ,iv_cust_code                    -- 顧客
      ,iv_base_code                    -- 起票部門
      ,iv_user_name                    -- 入力者
      ,iv_slip_line_type_name          -- 請求内容
      ,iv_payment_scheduled_date       -- 入金予定日
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- A-4.終了処理
    -- ===============================
--
    --エラー出力
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --エラーの場合成功件数クリア、エラー件数固定
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_zero;
      gn_error_cnt  := cn_one;
    END IF;
    --
    --対象件数出力
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
    --成功件数出力
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
    --エラー件数出力
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
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
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--###########################  固定例外処理部 START   ###################################
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
--###########################  固定部 END   ###################################################
--
END XXCOK024A44C;
/
