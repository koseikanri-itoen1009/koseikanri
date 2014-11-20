CREATE OR REPLACE PACKAGE BODY APPS.XXCCP008A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A04C(body)
 * Description      : リース会計基準情報CSV出力
 * Version          : 1.00
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
 *  2012/10/24    1.00  SCSK 高崎美和    新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  -- アプリケーション短縮名
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP008A04C';   -- パッケージ名
  -- 物件コード指定有無フラグ コード値
  cv_obj_code_param_off     CONSTANT VARCHAR2(1)  := '0';              -- 物件コードの指定無し
  cv_obj_code_param_on      CONSTANT VARCHAR2(1)  := '1';              -- 物件コードの指定有り
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_obj_code_param         VARCHAR2(1);               -- 物件コード指定有無フラグ
  -- 以下パラメータ --
  gv_contract_number        xxcff_contract_headers.contract_number%TYPE;   -- パラメータ：契約番号
  gv_lease_company          xxcff_contract_headers.lease_company%TYPE;     -- パラメータ：リース会社
  gv_object_code_01         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード1
  gv_object_code_02         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード2
  gv_object_code_03         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード3
  gv_object_code_04         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード4
  gv_object_code_05         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード5
  gv_object_code_06         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード6
  gv_object_code_07         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード7
  gv_object_code_08         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード8
  gv_object_code_09         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード9
  gv_object_code_10         xxcff_object_headers.object_code%TYPE;         -- パラメータ：物件コード10
--
  --==================================================
  -- グローバルカーソル
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
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
    cv_delimit              CONSTANT  VARCHAR2(10)  := ',';     -- 区切り文字
    cv_enclosed             CONSTANT  VARCHAR2(2)   := '"';     -- 単語囲み文字
    -- リース区分
    cv_lease_type_orgn      CONSTANT  VARCHAR2(1)   := '1';     -- 原契約
    cv_lease_type_re        CONSTANT  VARCHAR2(1)   := '2';     -- 再リース
    -- リース種類
    cv_lease_kind_fin       CONSTANT  VARCHAR2(1)   := '0';     -- FINリース
    cv_lease_kind_op        CONSTANT  VARCHAR2(1)   := '1';     -- OPリース
    cv_lease_kind_old_fin   CONSTANT  VARCHAR2(1)   := '2';     -- 旧FINリース
    -- 資産台帳名
    cv_book_type_code_old   CONSTANT  VARCHAR2(15)  := '旧リース台帳';
    cv_book_type_code_fin   CONSTANT  VARCHAR2(15)  := 'FINリース台帳';
    -- 資産会計年度・資産カレンダー
    cv_fiscal_year_name     CONSTANT  VARCHAR2(30)  := 'XXCFF_FISCAL_YEAR';
    cv_calendar_type        CONSTANT  VARCHAR2(15)  := 'XXCFF_CALENDAR';
    --
--
    -- *** ローカル変数 ***
    lv_period_name_from               fa_deprn_periods.period_name%TYPE;        -- 出力期間(自)
    lv_period_name_to                 fa_deprn_periods.period_name%TYPE;        -- 出力期間(至)
    ln_period_counter_from            fa_deprn_periods.period_counter%TYPE;     -- 期間ID(自)
    ln_period_counter_to              fa_deprn_periods.period_counter%TYPE;     -- 期間ID(至)
    ld_fiscal_start_date              DATE;                                     -- 期首開始日
    ld_fiscal_end_date                DATE;                                     -- 期末終了日
    ld_base_start_date                DATE;                                     -- 基準開始日
--
    -- ===============================================
    -- ローカル例外処理
    -- ===============================================
    err_prm_expt            EXCEPTION;   -- 入力パラメータ例外
    err_period_expt         EXCEPTION;   -- 会計期間取得例外
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
    -- 基準会計期間 取得カーソル
    CURSOR l_base_period_cur
    IS
      SELECT fdpbs.fiscal_year           AS fiscal_year           -- 会計年度
           , fdpst.period_name           AS period_name_from      -- 期首 会計期間名
           , fdpst.period_counter        AS period_counter_from   -- 期首 期間ID
           , fdpbs.period_name           AS period_name_to        -- 基準 会計期間
           , fdpbs.period_counter        AS period_counter_to     -- 基準 期間ID
           , ffy.start_date              AS fiscal_start_date     -- 期首開始日
           , ffy.end_date                AS fiscal_end_date       -- 期末終了日
           , fcp.start_date              AS base_start_date       -- 基準開始日
        FROM (
                SELECT MAX(fdp.period_name) AS max_period_name
                  FROM fa_deprn_periods    fdp
                 WHERE -- 当期 減価償却期間.資産台帳名 = FINリース台帳
                       fdp.book_type_code    = cv_book_type_code_fin
                   AND fdp.period_close_date IS NOT NULL
             ) fdpmx
           , fa_deprn_periods    fdpbs   -- 基準 減価償却期間
           , fa_deprn_periods    fdpst   -- 期首 減価償却期間
           , fa_fiscal_year      ffy     -- 資産会計年度
           , fa_calendar_periods fcp     -- 資産カレンダー
       WHERE -- 基準 減価償却期間.資産台帳名 = FINリース台帳
             fdpbs.book_type_code    = cv_book_type_code_fin
             -- 基準 減価償却期間.会計期間名 = クローズ会計期間の最大
         AND fdpbs.period_name       = fdpmx.max_period_name
             -- 期首 減価償却期間.資産台帳名 = FINリース台帳
         AND fdpst.book_type_code    = cv_book_type_code_fin
             -- 期首 減価償却期間.期間番号 = 1 ※期首
         AND fdpst.period_num        = 1
             -- 期首 減価償却期間.会計年度 = 基準 減価償却期間.会計年度
         AND fdpst.fiscal_year       = fdpbs.fiscal_year
             -- 資産会計年度.会計年度      = 基準 減価償却期間.会計年度
         AND ffy.fiscal_year         = fdpbs.fiscal_year
         AND ffy.fiscal_year_name    = cv_fiscal_year_name
             -- 資産カレンダー.会計期間名 = クローズ会計期間の最大
         AND fcp.period_name         = fdpmx.max_period_name
         AND fcp.calendar_type       = cv_calendar_type
    ;
    l_base_period_rec l_base_period_cur%ROWTYPE;
--
    -- =============================================================
    -- リース会計基準情報 取得カーソル パラメータ.契約番号が指定有り
    -- =============================================================
    CURSOR l_cont_planning_cur
    IS
      SELECT
             cont_head.lease_company                                                     AS lease_company       -- リース契約ヘッダ.リース会社
           , (  -- リース会社ビューより、リース会社名を取得
                SELECT a.lease_company_name
                  FROM xxcff_lease_company_v a   --リース会社ビュー
                 WHERE cont_head.lease_company = a.lease_company_code
             )                                                                           AS lease_company_name  -- リース会社ビュー.リース会社名
           , lv_period_name_from                                                         AS period_name_from    -- 期首 会計期間名
           , lv_period_name_to                                                           AS period_name_to      -- 基準 会計期間
           , cont_head.contract_number                                                   AS contract_number     -- リース契約ヘッダ.契約番号
           , (  -- リース種別ビューより、リース種別名を取得
                SELECT a.lease_class_name
                  FROM xxcff_lease_class_v a     --リース種別ビュー
                 WHERE cont_head.lease_class = a.lease_class_code
             )                                                                           AS lease_class_name    -- リース種別ビュー.リース種別名称
           , -- リース契約ヘッダ.リース区分より区分名を判定
             CASE cont_head.lease_type
               WHEN cv_lease_type_orgn  THEN '原契約'
               WHEN cv_lease_type_re    THEN '再リース'
             END                                                                         AS lease_type_name
           , TO_CHAR( cont_head.lease_start_date , 'yyyy/mm/dd' )                        AS lease_start_date    -- リース契約ヘッダ.リース開始日
           , TO_CHAR( cont_head.lease_end_date   , 'yyyy/mm/dd' )                        AS lease_end_date      -- リース契約ヘッダ.リース終了日
           , cont_head.payment_frequency                                                 AS payment_frequency   -- リース契約ヘッダ.支払回数
           , cont_line.second_charge                                                     AS second_charge       -- リース契約明細.2回目以降月額リース料_リース料
           , cont_line.gross_charge                                                      AS gross_charge        -- リース契約明細.総額リース料_リース料
           , (  -- 当期支払リース料               リース支払計画.リース料を集計         範囲：期首～基準期間 
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL(pay_plan_st.payment_frequency , 1 )
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency          
             )                                                                           AS lcharge_year
           , (  -- 未経過リース料                 リース支払計画.リース料を集計         範囲：基準期間 + 1ヶ月 ～
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  = pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency > pay_plan_bs.payment_frequency
             )                                                                           AS lcharge_future
           , (  -- 1年以内未経過リース料          リース支払計画.リース料を集計         範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS lcharge_fut_1year
           , (  -- 1年超未経過リース料            リース支払計画.リース料を集計         範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS lcharge_fut_ov1year
           , (  -- リース契約明細.取得価額
                SELECT cont_line_a.original_cost
                  FROM xxcff_contract_lines     cont_line_a
                 WHERE cont_line_a.object_header_id   = obj_head.object_header_id
                   AND cont_line_a.contract_header_id = cont_head.contract_header_id
                   AND cont_line_a.lease_kind        <> cv_lease_kind_op --opリース以外
             )                                                                           AS original_cost
                -- 未経過リース期末残高相当額     リース支払計画.FINリース債務残          範囲：基準期間 時点
           , NVL( pay_plan_bs.fin_debt_rem , 0 )                                         AS fin_debt_rem
           , (  -- 未経過リース支払利息           リース支払計画.FINリース支払利息 を集計 範囲：基準期間 + 1ヶ月 ～
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  = pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency > pay_plan_bs.payment_frequency
             )                                                                           AS fin_interest_due
                -- 未経過リース消費税額           リース支払計画.FINリース債務残_消費税   範囲：基準期間 時点
           , NVL( pay_plan_bs.fin_tax_debt_rem , 0 )                                     AS fin_tax_debt_rem
           , (  -- 1年以内元本額                  リース支払計画.FINリース債務額を集計         範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_debt_1year
           , (  -- 1年以内支払利息                リース支払計画.FINリース支払利息 を集計      範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_int_due_1year
           , (  -- 1年以内消費税                  リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_tax_debt_1year
           , (  -- 1年超元本額                    リース支払計画.FINリース債務額を集計         範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_debt_ov1year
           , (  -- 1年超支払利息                  リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_int_due_ov1year
           , (  -- 1年超消費税                    リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_tax_debt_ov1year
           , (  -- 1年超2年以内元本額             リース支払計画.FINリース債務額を集計         範囲：基準期間 +13ヶ月 ～ +24ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_debt_1to2year
           , (  -- 1年超2年以内支払利息           リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +13ヶ月 ～ +24ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_int_due_1to2year
           , (  -- 1年超2年以内消費税             リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +13ヶ月 ～ +24ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_tax_debt_1to2year
            ,(  -- 2年超3年以内元本額             リース支払計画.FINリース債務額を集計         範囲：基準期間 +25ヶ月 ～ +36ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_debt_2to3year
           , (  -- 2年超3年以内支払利息            リース支払計画.FINリース支払利息 を集計     範囲：基準期間 +25ヶ月 ～ +36ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_int_due_2to3year
           , (  -- 2年超3年以内消費税             リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +25ヶ月 ～ +36ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_tax_debt_2to3year
           , (  -- 3年超4年以内元本額             リース支払計画.FINリース債務額を集計         範囲：基準期間 +37ヶ月 ～ +48ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
             )                                                                           AS fin_debt_3to4year
           , (  -- 3年超4年以内支払利息           リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +37ヶ月 ～ +48ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
              )                                                                          AS fin_int_due_3to4year
           , (  -- 3年超4年以内消費税             リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +37ヶ月 ～ +48ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
             )                                                                           AS fin_tax_debt_3to4year
           , (  -- 4年超5年以内元本額             リース支払計画.FINリース債務額を集計         範囲：基準期間 +49ヶ月 ～ +60ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_debt_4to5year
           , (  -- 4年超5年以内支払利息           リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +49ヶ月 ～ +60ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_int_due_4to5year
           , (  -- 4年超5年以内消費税             リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +49ヶ月 ～ +60ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_tax_debt_4to5year
           , (  -- 5年超元本額                    リース支払計画.FINリース債務額を集計         範囲：基準期間 +61ヶ月 ～
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_debt_ov5year
           , (  -- 5年超支払利息                  リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +61ヶ月 ～
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_int_due_ov5year
           , (  -- 5年超消費税                    リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +61ヶ月 ～
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_tax_debt_ov5year
           , NVL( -- 減価償却累計額相当額
                  (
                     SELECT fdsum.deprn_reserve
                       FROM xxcff_contract_lines     cont_line_a  -- リース契約明細
                          , fa_additions_b           fab          -- 標準:資産詳細情報
                          , fa_deprn_summary         fdsum        -- 標準:減価償却サマリ情報
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        -- リース種類 がOP以外
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =
                            (
                               SELECT MAX( period_counter )
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                                     , cv_book_type_code_fin
                                                                                                     , cv_book_type_code_old
                                                                            )
                                  AND fdsum.period_counter       >= ln_period_counter_from
                                  AND fdsum.period_counter       <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS deprn_reserve
           , NVL( -- 期末残高相当額
                  (
                     SELECT fdsum.adjusted_cost - fdsum.deprn_reserve
                       FROM xxcff_contract_lines     cont_line_a
                          , fa_additions_b           fab
                          , fa_deprn_summary         fdsum
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =  
                            (
                               SELECT MAX( period_counter )
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                                       , cv_book_type_code_fin
                                                                                                       , cv_book_type_code_old
                                                                              )
                                  AND   fdsum.period_counter          >= ln_period_counter_from
                                  AND   fdsum.period_counter          <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS bal_amount
           , (  -- 支払利息相当額                 リース支払計画.FINリース支払利息 を集計      範囲：期首～基準期間
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL( pay_plan_st.payment_frequency , 1 ) 
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency
             )                                                                           AS interest_amount
           , NVL( -- 減価償却相当額
                  (
                     SELECT fdsum.ytd_deprn
                       FROM xxcff_contract_lines     cont_line_a
                          , fa_additions_b           fab
                          , fa_deprn_summary         fdsum
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin 
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =  
                            (
                               SELECT MAX(period_counter)
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin 
                                                                                                     , cv_book_type_code_fin
                                                                                                     , cv_book_type_code_old
                                                                            )
                                  AND fdsum.period_counter          >= ln_period_counter_from
                                  AND fdsum.period_counter          <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS deprn_amount
           , cont_line.second_deduction                                                  AS monthly_deduction -- 月間リース料(控除額)
           , cont_line.gross_deduction                                                   AS gross_deduction   -- リース料総額(控除額)
           , (  -- 当期支払リース料(控除額)       リース支払計画.リース控除額 を集計           範囲：期首～基準期間
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL( pay_plan_st.payment_frequency , 1 )
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency
             )                                                                           AS lded_year
           , (  -- 未経過リース料(控除額)         リース支払計画.リース控除額 を集計           範囲：基準期間 + 1ヶ月 ～
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
             )                                                                           AS lded_future
           , (  -- 1年以内未経過リース料(控除額)  リース支払計画.リース控除額 を集計           範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS lded_fut_1year
           , (  -- 1年超未経過リース料(控除額)    リース支払計画.リース控除額 を集計           範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS lded_fut_ov1year
           , -- リース契約明細.リース種類よりリース種類名称を判定
             CASE cont_line.lease_kind
               WHEN cv_lease_kind_fin     THEN 'FIN'
               WHEN cv_lease_kind_op      THEN 'OP'
               WHEN cv_lease_kind_old_fin THEN '旧FIN'
             END                                                                         AS lease_kind_name   -- リース種類名称
           , cont_line.contract_line_num                                                 AS contract_line_num -- リース契約明細.契約枝番
           , obj_head.object_code                                                        AS object_code       -- リース物件.物件コード
           , obj_head.department_code                                                    AS department_code   -- リース物件.管理部門コード
           , (  -- 管理部門ビューより、管理部門名称を取得
                SELECT a.department_name
                  FROM xxcff_department_v a
                 WHERE obj_head.department_code = a.department_code
             )                                                                           AS department_name  -- 管理部門ビュー.管理部門名
           , cont_line.contract_status                                                   AS contract_status  -- リース契約明細.契約スタータス
           , (  -- 契約ステータスビューより、契約ステータス名称を取得
                SELECT a.contract_status_name
                  FROM xxcff_contract_status_v a
                 WHERE cont_line.contract_status = a.contract_status_code
             )                                                                           AS contract_status_name -- 契約ステータスビュー.契約スタータス名
           , obj_head.object_status                                                      AS object_status        -- リース物件.物件スタータス
           , (  -- 物件ステータスビューより、物件ステータス名称を取得
                SELECT a.object_status_name
                  FROM xxcff_object_status_v a
                 WHERE obj_head.object_status = a.object_status_code
             )                                                                           AS object_status_name   -- 物件ステータスビュー.物件スタータス名
           , cont_head.re_lease_times                                                    AS cont_re_lease_times  -- 契約ヘッダ.再リース回数
           , obj_head.re_lease_times                                                     AS obj_re_lease_times   -- リース物件.再リース回数
           , (  --資産番号取得
                SELECT fab.asset_number
                  FROM xxcff_contract_lines     cont_line_a
                     , fa_additions_b           fab
                 WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                   AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                   AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
             )                                                                           AS asset_number
           , (  -- 種類
                SELECT ffvt.description
                  FROM xxcff_contract_lines     cont_line_a
                     , fa_additions_b           fab
                     , fa_categories_b          fcb
                     , fnd_flex_value_sets      ffvs
                     , fnd_flex_values          ffv
                     , fnd_flex_values_tl       ffvt
                 WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                   AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                   AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                   AND fab.asset_category_id         = fcb.category_id
                   AND fcb.segment1                  = ffv.flex_value
                   AND ffvs.flex_value_set_name      = 'XXCFF_CATEGORY'
                   AND ffvs.flex_value_set_id        = ffv.flex_value_set_id
                   AND ffv.flex_value_id             = ffvt.flex_value_id
                   AND ffvt.language                 = 'JA'
             )                                                                           AS category_name        -- 種類
           , --当年度リース月数
             CASE
               -- リース開始日が当年度より前
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') <  TRUNC( ld_fiscal_start_date , 'MM')
                 THEN
                   CASE
                      -- リース終了日が当年度より前
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') <  TRUNC( ld_fiscal_start_date , 'MM')
                        THEN 0
                      -- リース終了日が当年度中でかつ、基準年月以前
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                       AND   TRUNC( cont_head.lease_end_date , 'MM') <= TRUNC( ld_base_start_date   , 'MM')
                             -- 期首～リース終了までの月数
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(cont_head.lease_end_date ), TRUNC( ld_fiscal_start_date ))) + 1
                      -- リース終了日が基準年月より後
                      --   ※ リース終了日を迎えていない場合、再契約して継続する可能性があるので当年度終了であっても12と表示
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >  TRUNC( ld_base_start_date   , 'MM')
                        THEN 12
                   END
               -- リース開始日が当年度中
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                AND   TRUNC( cont_head.lease_start_date , 'MM') <= TRUNC( ld_fiscal_end_date   , 'MM')
                 THEN 
                   CASE
                      -- リース終了日が当年度
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                       AND   TRUNC( cont_head.lease_end_date , 'MM') <= TRUNC( ld_fiscal_end_date   , 'MM')
                             -- リース開始日～リース終了日までの月数
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(cont_head.lease_end_date ), TRUNC( cont_head.lease_start_date ) ) ) + 1
                      -- リース終了日が当年度より後
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >  TRUNC( ld_fiscal_end_date   , 'MM')
                             -- リース開始日～期末までの月数
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(ld_fiscal_end_date ), TRUNC( cont_head.lease_start_date ) ) ) + 1
                   END
               -- リース開始日が当年度より後
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') >  TRUNC( ld_fiscal_end_date   , 'MM')
                 THEN 0
             END                                                                         AS lease_mcount
        FROM xxcff_contract_headers   cont_head      -- リース契約ヘッダ
           , xxcff_contract_lines     cont_line      -- リース契約明細
           , xxcff_object_headers     obj_head       -- リース物件
           , ( -- 各契約毎の最大再リース回数
               SELECT cont_head.contract_number          AS contract_number
                    , cont_head.lease_company            AS lease_company
                    , MAX(cont_head.re_lease_times)      AS re_lease_times
                 FROM xxcff_contract_headers   cont_head      -- リース契約ヘッダ
                WHERE cont_head.contract_number = gv_contract_number
                GROUP BY cont_head.contract_number , cont_head.lease_company
             ) cont_head_max
           , xxcff_pay_planning       pay_plan_st    -- 期首：リース支払計画
           , xxcff_pay_planning       pay_plan_bs    -- 基準：リース支払計画
       WHERE -- リース契約ヘッダ.契約内部ID = リース契約明細.契約内部ID
             cont_head.contract_header_id = cont_line.contract_header_id
             -- リース契約明細.物件内部ID = リース物件.物件内部ID
         AND cont_line.object_header_id   = obj_head.object_header_id
             -- 契約の最大再リース回数
         AND cont_head.contract_number = cont_head_max.contract_number
         AND cont_head.lease_company   = cont_head_max.lease_company
         AND cont_head.re_lease_times  = cont_head_max.re_lease_times
             -- 期首：リース支払計画.会計期間  += 出力期間(自)
         AND pay_plan_st.period_name(+)   = lv_period_name_from
             -- 基準：リース支払計画.会計期間  += 出力期間(至)
         AND pay_plan_bs.period_name(+)   = lv_period_name_to
             -- 期首：リース支払計画.契約明細内部ID  += リース契約明細.契約明細内部ID
         AND pay_plan_st.contract_line_id(+)   = cont_line.contract_line_id
             -- 基準：リース支払計画.契約明細内部ID  += リース契約明細.契約明細内部ID
         AND pay_plan_bs.contract_line_id(+)   = cont_line.contract_line_id
             -- リース契約ヘッダ.契約番号 = :パラメータ契約番号
         AND cont_head.contract_number    = gv_contract_number
             -- リース契約ヘッダ.リース会社 = :パラメータリース会社
         AND ( gv_lease_company IS NULL
             OR
               cont_head.lease_company    = gv_lease_company
             )
             -- 物件コードの指定がある場合は、いずれかに合致するもの
         AND (
               gv_obj_code_param = cv_obj_code_param_off
             OR
               (
                 gv_obj_code_param = cv_obj_code_param_on
                 AND
                 -- リース物件.物件コード パラメタ1～10のいずれか
                 obj_head.object_code IN ( gv_object_code_01
                                         , gv_object_code_02
                                         , gv_object_code_03
                                         , gv_object_code_04
                                         , gv_object_code_05
                                         , gv_object_code_06
                                         , gv_object_code_07
                                         , gv_object_code_08
                                         , gv_object_code_09
                                         , gv_object_code_10
                                      )
               )
             )
       ORDER BY cont_head.contract_number
              , obj_head.object_code
    ;
    -- =============================================================
    -- リース会計基準情報 取得カーソル パラメータ.契約番号が未指定
    -- =============================================================
    CURSOR l_no_cont_planning_cur
    IS
      SELECT
             cont_head.lease_company                                                     AS lease_company       -- リース契約ヘッダ.リース会社
           , (  -- リース会社ビューより、リース会社名を取得
                SELECT a.lease_company_name
                  FROM xxcff_lease_company_v a   --リース会社ビュー
                 WHERE cont_head.lease_company = a.lease_company_code
             )                                                                           AS lease_company_name  -- リース会社ビュー.リース会社名
           , lv_period_name_from                                                         AS period_name_from    -- 期首 会計期間名
           , lv_period_name_to                                                           AS period_name_to      -- 基準 会計期間
           , cont_head.contract_number                                                   AS contract_number     -- リース契約ヘッダ.契約番号
           , (  -- リース種別ビューより、リース種別名を取得
                SELECT a.lease_class_name
                  FROM xxcff_lease_class_v a     --リース種別ビュー
                 WHERE cont_head.lease_class = a.lease_class_code
             )                                                                           AS lease_class_name    -- リース種別ビュー.リース種別名称
           , -- リース契約ヘッダ.リース区分より区分名を判定
             CASE cont_head.lease_type
               WHEN cv_lease_type_orgn  THEN '原契約'
               WHEN cv_lease_type_re    THEN '再リース'
             END                                                                         AS lease_type_name
           , TO_CHAR( cont_head.lease_start_date , 'yyyy/mm/dd' )                        AS lease_start_date    -- リース契約ヘッダ.リース開始日
           , TO_CHAR( cont_head.lease_end_date   , 'yyyy/mm/dd' )                        AS lease_end_date      -- リース契約ヘッダ.リース終了日
           , cont_head.payment_frequency                                                 AS payment_frequency   -- リース契約ヘッダ.支払回数
           , cont_line.second_charge                                                     AS second_charge       -- リース契約明細.2回目以降月額リース料_リース料
           , cont_line.gross_charge                                                      AS gross_charge        -- リース契約明細.総額リース料_リース料
           , (  -- 当期支払リース料               リース支払計画.リース料を集計         範囲：期首～基準期間 
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL(pay_plan_st.payment_frequency , 1 )
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency          
             )                                                                           AS lcharge_year
           , (  -- 未経過リース料                 リース支払計画.リース料を集計         範囲：基準期間 + 1ヶ月 ～
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  = pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency > pay_plan_bs.payment_frequency
             )                                                                           AS lcharge_future
           , (  -- 1年以内未経過リース料          リース支払計画.リース料を集計         範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS lcharge_fut_1year
           , (  -- 1年超未経過リース料            リース支払計画.リース料を集計         範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS lcharge_fut_ov1year
           , (  -- リース契約明細.取得価額
                SELECT cont_line_a.original_cost
                  FROM xxcff_contract_lines     cont_line_a
                 WHERE cont_line_a.object_header_id   = obj_head.object_header_id
                   AND cont_line_a.contract_header_id = cont_head.contract_header_id
                   AND cont_line_a.lease_kind        <> cv_lease_kind_op --opリース以外
             )                                                                           AS original_cost
                -- 未経過リース期末残高相当額     リース支払計画.FINリース債務残          範囲：基準期間 時点
           , NVL( pay_plan_bs.fin_debt_rem , 0 )                                         AS fin_debt_rem
           , (  -- 未経過リース支払利息           リース支払計画.FINリース支払利息 を集計 範囲：基準期間 + 1ヶ月 ～
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  = pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency > pay_plan_bs.payment_frequency
             )                                                                           AS fin_interest_due
                -- 未経過リース消費税額           リース支払計画.FINリース債務残_消費税   範囲：基準期間 時点
           , NVL( pay_plan_bs.fin_tax_debt_rem , 0 )                                     AS fin_tax_debt_rem
           , (  -- 1年以内元本額                  リース支払計画.FINリース債務額を集計         範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_debt_1year
           , (  -- 1年以内支払利息                リース支払計画.FINリース支払利息 を集計      範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_int_due_1year
           , (  -- 1年以内消費税                  リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_tax_debt_1year
           , (  -- 1年超元本額                    リース支払計画.FINリース債務額を集計         範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_debt_ov1year
           , (  -- 1年超支払利息                  リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_int_due_ov1year
           , (  -- 1年超消費税                    リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_tax_debt_ov1year
           , (  -- 1年超2年以内元本額             リース支払計画.FINリース債務額を集計         範囲：基準期間 +13ヶ月 ～ +24ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_debt_1to2year
           , (  -- 1年超2年以内支払利息           リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +13ヶ月 ～ +24ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_int_due_1to2year
           , (  -- 1年超2年以内消費税             リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +13ヶ月 ～ +24ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_tax_debt_1to2year
            ,(  -- 2年超3年以内元本額             リース支払計画.FINリース債務額を集計         範囲：基準期間 +25ヶ月 ～ +36ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_debt_2to3year
           , (  -- 2年超3年以内支払利息            リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +25ヶ月 ～ +36ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_int_due_2to3year
           , (  -- 2年超3年以内消費税             リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +25ヶ月 ～ +36ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_tax_debt_2to3year
           , (  -- 3年超4年以内元本額             リース支払計画.FINリース債務額を集計         範囲：基準期間 +37ヶ月 ～ +48ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
             )                                                                           AS fin_debt_3to4year
           , (  -- 3年超4年以内支払利息           リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +37ヶ月 ～ +48ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
              )                                                                          AS fin_int_due_3to4year
           , (  -- 3年超4年以内消費税             リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +37ヶ月 ～ +48ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
             )                                                                           AS fin_tax_debt_3to4year
           , (  -- 4年超5年以内元本額             リース支払計画.FINリース債務額を集計         範囲：基準期間 +49ヶ月 ～ +60ヶ月
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_debt_4to5year
           , (  -- 4年超5年以内支払利息           リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +49ヶ月 ～ +60ヶ月
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_int_due_4to5year
           , (  -- 4年超5年以内消費税             リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +49ヶ月 ～ +60ヶ月
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_tax_debt_4to5year
           , (  -- 5年超元本額                    リース支払計画.FINリース債務額を集計         範囲：基準期間 +61ヶ月 ～
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_debt_ov5year
           , (  -- 5年超支払利息                  リース支払計画.FINリース支払利息 を集計      範囲：基準期間 +61ヶ月 ～
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_int_due_ov5year
           , (  -- 5年超消費税                    リース支払計画.FINリース債務額_消費税を集計  範囲：基準期間 +61ヶ月 ～
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_tax_debt_ov5year
           , NVL( -- 減価償却累計額相当額
                  (
                     SELECT fdsum.deprn_reserve
                       FROM xxcff_contract_lines     cont_line_a  -- リース契約明細
                          , fa_additions_b           fab          -- 標準:資産詳細情報
                          , fa_deprn_summary         fdsum        -- 標準:減価償却サマリ情報
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        -- リース種類 がOP以外
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =
                            (
                               SELECT MAX( period_counter )
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                                     , cv_book_type_code_fin
                                                                                                     , cv_book_type_code_old
                                                                            )
                                  AND fdsum.period_counter       >= ln_period_counter_from
                                  AND fdsum.period_counter       <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS deprn_reserve
           , NVL( -- 期末残高相当額
                  (
                     SELECT fdsum.adjusted_cost - fdsum.deprn_reserve
                       FROM xxcff_contract_lines     cont_line_a
                          , fa_additions_b           fab
                          , fa_deprn_summary         fdsum
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =  
                            (
                               SELECT MAX( period_counter )
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                                       , cv_book_type_code_fin
                                                                                                       , cv_book_type_code_old
                                                                              )
                                  AND   fdsum.period_counter          >= ln_period_counter_from
                                  AND   fdsum.period_counter          <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS bal_amount
           , (  -- 支払利息相当額                 リース支払計画.FINリース支払利息 を集計      範囲：期首～基準期間
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL( pay_plan_st.payment_frequency , 1 ) 
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency
             )                                                                           AS interest_amount
           , NVL( -- 減価償却相当額
                  (
                     SELECT fdsum.ytd_deprn
                       FROM xxcff_contract_lines     cont_line_a
                          , fa_additions_b           fab
                          , fa_deprn_summary         fdsum
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin 
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =  
                            (
                               SELECT MAX(period_counter)
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin 
                                                                                                     , cv_book_type_code_fin
                                                                                                     , cv_book_type_code_old
                                                                            )
                                  AND fdsum.period_counter          >= ln_period_counter_from
                                  AND fdsum.period_counter          <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS deprn_amount
           , cont_line.second_deduction                                                  AS monthly_deduction -- 月間リース料(控除額)
           , cont_line.gross_deduction                                                   AS gross_deduction   -- リース料総額(控除額)
           , (  -- 当期支払リース料(控除額)       リース支払計画.リース控除額 を集計           範囲：期首～基準期間
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL( pay_plan_st.payment_frequency , 1 )
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency
             )                                                                           AS lded_year
           , (  -- 未経過リース料(控除額)         リース支払計画.リース控除額 を集計           範囲：基準期間 + 1ヶ月 ～
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
             )                                                                           AS lded_future
           , (  -- 1年以内未経過リース料(控除額)  リース支払計画.リース控除額 を集計           範囲：基準期間 + 1ヶ月 ～ +12ヶ月
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS lded_fut_1year
           , (  -- 1年超未経過リース料(控除額)    リース支払計画.リース控除額 を集計           範囲：基準期間 +13ヶ月 ～
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS lded_fut_ov1year
           , -- リース契約明細.リース種類よりリース種類名称を判定
             CASE cont_line.lease_kind
               WHEN cv_lease_kind_fin     THEN 'FIN'
               WHEN cv_lease_kind_op      THEN 'OP'
               WHEN cv_lease_kind_old_fin THEN '旧FIN'
             END                                                                         AS lease_kind_name   -- リース種類名称
           , cont_line.contract_line_num                                                 AS contract_line_num -- リース契約明細.契約枝番
           , obj_head.object_code                                                        AS object_code       -- リース物件.物件コード
           , obj_head.department_code                                                    AS department_code   -- リース物件.管理部門コード
           , (  -- 管理部門ビューより、管理部門名称を取得
                SELECT a.department_name
                  FROM xxcff_department_v a
                 WHERE obj_head.department_code = a.department_code
             )                                                                           AS department_name  -- 管理部門ビュー.管理部門名
           , cont_line.contract_status                                                   AS contract_status  -- リース契約明細.契約スタータス
           , (  -- 契約ステータスビューより、契約ステータス名称を取得
                SELECT a.contract_status_name
                  FROM xxcff_contract_status_v a
                 WHERE cont_line.contract_status = a.contract_status_code
             )                                                                           AS contract_status_name -- 契約ステータスビュー.契約スタータス名
           , obj_head.object_status                                                      AS object_status        -- リース物件.物件スタータス
           , (  -- 物件ステータスビューより、物件ステータス名称を取得
                SELECT a.object_status_name
                  FROM xxcff_object_status_v a
                 WHERE obj_head.object_status = a.object_status_code
             )                                                                           AS object_status_name   -- 物件ステータスビュー.物件スタータス名
           , cont_head.re_lease_times                                                    AS cont_re_lease_times  -- 契約ヘッダ.再リース回数
           , obj_head.re_lease_times                                                     AS obj_re_lease_times   -- リース物件.再リース回数
           , (  --資産番号取得
                SELECT fab.asset_number
                  FROM xxcff_contract_lines     cont_line_a
                     , fa_additions_b           fab
                 WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                   AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                   AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
             )                                                                           AS asset_number
           , (  -- 種類
                SELECT ffvt.description
                  FROM xxcff_contract_lines     cont_line_a
                     , fa_additions_b           fab
                     , fa_categories_b          fcb
                     , fnd_flex_value_sets      ffvs
                     , fnd_flex_values          ffv
                     , fnd_flex_values_tl       ffvt
                 WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                   AND cont_line_a.lease_kind       <> cv_lease_kind_op --op以外
                   AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                   AND fab.asset_category_id         = fcb.category_id
                   AND fcb.segment1                  = ffv.flex_value
                   AND ffvs.flex_value_set_name      = 'XXCFF_CATEGORY'
                   AND ffvs.flex_value_set_id        = ffv.flex_value_set_id
                   AND ffv.flex_value_id             = ffvt.flex_value_id
                   AND ffvt.language                 = 'JA'
             )                                                                           AS category_name        -- 種類
           , --当年度リース月数
             CASE
               -- リース開始日が当年度より前
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') <  TRUNC( ld_fiscal_start_date , 'MM')
                 THEN
                   CASE
                      -- リース終了日が当年度より前
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') <  TRUNC( ld_fiscal_start_date , 'MM')
                        THEN 0
                      -- リース終了日が当年度中でかつ、基準年月以前
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                       AND   TRUNC( cont_head.lease_end_date , 'MM') <= TRUNC( ld_base_start_date   , 'MM')
                             -- 期首～リース終了までの月数
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(cont_head.lease_end_date ), TRUNC( ld_fiscal_start_date ))) + 1
                      -- リース終了日が基準年月より後
                      --   ※ リース終了日を迎えていない場合、再契約して継続する可能性があるので当年度終了であっても12と表示
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >  TRUNC( ld_base_start_date   , 'MM')
                        THEN 12
                   END
               -- リース開始日が当年度中
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                AND   TRUNC( cont_head.lease_start_date , 'MM') <= TRUNC( ld_fiscal_end_date   , 'MM')
                 THEN 
                   CASE
                      -- リース終了日が当年度
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                       AND   TRUNC( cont_head.lease_end_date , 'MM') <= TRUNC( ld_fiscal_end_date   , 'MM')
                             -- リース開始日～リース終了日までの月数
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(cont_head.lease_end_date ), TRUNC( cont_head.lease_start_date ) ) ) + 1
                      -- リース終了日が当年度より後
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >  TRUNC( ld_fiscal_end_date   , 'MM')
                             -- リース開始日～期末までの月数
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(ld_fiscal_end_date ), TRUNC( cont_head.lease_start_date ) ) ) + 1
                   END
               -- リース開始日が当年度より後
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') >  TRUNC( ld_fiscal_end_date   , 'MM')
                 THEN 0
             END                                                                         AS lease_mcount
        FROM xxcff_contract_headers   cont_head      -- リース契約ヘッダ
           , xxcff_contract_lines     cont_line      -- リース契約明細
           , xxcff_object_headers     obj_head       -- リース物件
           , xxcff_pay_planning       pay_plan_st    -- 期首：リース支払計画
           , xxcff_pay_planning       pay_plan_bs    -- 基準：リース支払計画
       WHERE -- リース契約ヘッダ.契約内部ID = リース契約明細.契約内部ID
             cont_head.contract_header_id = cont_line.contract_header_id
             -- リース契約明細.物件内部ID = リース物件.物件内部ID
         AND cont_line.object_header_id   = obj_head.object_header_id
             -- リース契約ヘッダ.再リース回数 = リース物件.再リース回数
         AND cont_head.re_lease_times = obj_head.re_lease_times
             -- 期首：リース支払計画.会計期間  += 出力期間(自)
         AND pay_plan_st.period_name(+)   = lv_period_name_from
             -- 基準：リース支払計画.会計期間  += 出力期間(至)
         AND pay_plan_bs.period_name(+)   = lv_period_name_to
             -- 期首：リース支払計画.契約明細内部ID  += リース契約明細.契約明細内部ID
         AND pay_plan_st.contract_line_id(+)   = cont_line.contract_line_id
             -- 基準：リース支払計画.契約明細内部ID  += リース契約明細.契約明細内部ID
         AND pay_plan_bs.contract_line_id(+)   = cont_line.contract_line_id
             -- リース契約ヘッダ.リース会社 = :パラメータ.リース会社
         AND ( gv_lease_company IS NULL
             OR
               cont_head.lease_company    = gv_lease_company
             )
         AND -- リース物件.物件コード パラメタ1～10のいずれか
             obj_head.object_code IN ( gv_object_code_01
                                     , gv_object_code_02
                                     , gv_object_code_03
                                     , gv_object_code_04
                                     , gv_object_code_05
                                     , gv_object_code_06
                                     , gv_object_code_07
                                     , gv_object_code_08
                                     , gv_object_code_09
                                     , gv_object_code_10
                                     )
       ORDER BY cont_head.contract_number
              , obj_head.object_code
    ;
    TYPE l_cont_planning_ttype IS TABLE OF l_cont_planning_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_cont_planning_tab l_cont_planning_ttype;
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
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
--
    -- ===============================================
    -- 入力パラメータ.物件コードチェック
    -- ===============================================
    -- パラメータ.物件コード1～10の内、一つでも指定されている場合は物件コード指定有無フラグを有りにする。
    gv_obj_code_param := cv_obj_code_param_off;
    IF ( gv_object_code_01 IS NOT NULL ) OR
       ( gv_object_code_02 IS NOT NULL ) OR
       ( gv_object_code_03 IS NOT NULL ) OR
       ( gv_object_code_04 IS NOT NULL ) OR
       ( gv_object_code_05 IS NOT NULL ) OR
       ( gv_object_code_06 IS NOT NULL ) OR
       ( gv_object_code_07 IS NOT NULL ) OR
       ( gv_object_code_08 IS NOT NULL ) OR
       ( gv_object_code_09 IS NOT NULL ) OR
       ( gv_object_code_10 IS NOT NULL )
      THEN
       gv_obj_code_param := cv_obj_code_param_on;
    END IF;
    -- ===============================================
    -- リース会社・物件コードチェック
    -- ===============================================
    -- パラメータ.物件コード1～10が全て未指定の場合、パラメータ.契約番号、パラメータ.リース会社は共に必須
    IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
       ( ( gv_lease_company IS NULL ) OR ( gv_contract_number IS NULL ) ) 
      THEN
        lv_errmsg  := '物件コードが未指定時は、契約番号とリース会社を指定して下さい。';
        lv_errbuf  := lv_errmsg;
        RAISE err_prm_expt;
    END IF;
--
    -- ===============================================
    -- リース会計基準情報 抽出処理
    -- ===============================================
    -- 基準会計期間 取得カーソル
    OPEN l_base_period_cur;
    FETCH l_base_period_cur INTO l_base_period_rec;
    CLOSE l_base_period_cur;
    --基準会計期間が取得できない場合
    IF l_base_period_rec.period_name_to IS NULL THEN
      lv_errmsg  := '会計期間の取得に失敗しました。';
      lv_errbuf  := lv_errmsg;
      RAISE err_period_expt;
    END IF;
    --
    lv_period_name_from    := l_base_period_rec.period_name_from;     -- 出力期間(自)
    lv_period_name_to      := l_base_period_rec.period_name_to;       -- 出力期間(至)
    ln_period_counter_from := l_base_period_rec.period_counter_from;  -- 期間ID(自)
    ln_period_counter_to   := l_base_period_rec.period_counter_to;    -- 期間ID(至)
    ld_fiscal_start_date   := l_base_period_rec.fiscal_start_date;    -- 期首開始日
    ld_fiscal_end_date     := l_base_period_rec.fiscal_end_date;      -- 期末終了日
    ld_base_start_date     := l_base_period_rec.base_start_date;      -- 期末終了日
--
    -- リース会計基準情報 取得カーソル
    IF gv_contract_number IS NULL THEN
       -- パラメータ.契約番号が未指定
        OPEN l_no_cont_planning_cur;
        FETCH l_no_cont_planning_cur BULK COLLECT INTO l_cont_planning_tab;
        CLOSE l_no_cont_planning_cur;
    ELSE
       -- パラメータ.契約番号が指定有り
        OPEN l_cont_planning_cur;
        FETCH l_cont_planning_cur BULK COLLECT INTO l_cont_planning_tab;
        CLOSE l_cont_planning_cur;
    END IF;
    --処理件数カウント
    gn_target_cnt := l_cont_planning_tab.COUNT;
--
    -- 見出し
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => 'リース会計基準情報'
    );
    -- 項目名
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   =>          cv_enclosed || 'リース会社'                    || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース会社名'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '出力期間(自)'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '出力期間(至)'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '契約NO'                        || cv_enclosed
         || cv_delimit || cv_enclosed || '分類'                          || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース区分'                    || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース開始日'                  || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース終了日'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '月数'                          || cv_enclosed
         || cv_delimit || cv_enclosed || '月間リース料'                  || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース料総額'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '当期支払リース料'              || cv_enclosed
         || cv_delimit || cv_enclosed || '未経過リース料'                || cv_enclosed
         || cv_delimit || cv_enclosed || '1年以内未経過リース料'         || cv_enclosed
         || cv_delimit || cv_enclosed || '1年超未経過リース料'           || cv_enclosed
         || cv_delimit || cv_enclosed || '取得価額相当額'                || cv_enclosed
         || cv_delimit || cv_enclosed || '未経過リース期末残高相当額'    || cv_enclosed
         || cv_delimit || cv_enclosed || '未経過リース支払利息'          || cv_enclosed
         || cv_delimit || cv_enclosed || '未経過リース消費税額'          || cv_enclosed
         || cv_delimit || cv_enclosed || '1年以内元本額'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '1年以内支払利息'               || cv_enclosed
         || cv_delimit || cv_enclosed || '1年以内消費税'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '1年超元本額'                   || cv_enclosed
         || cv_delimit || cv_enclosed || '1年超支払利息'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '1年超消費税'                   || cv_enclosed
         || cv_delimit || cv_enclosed || '1年超2年以内元本額'            || cv_enclosed
         || cv_delimit || cv_enclosed || '1年超2年以内支払利息'          || cv_enclosed
         || cv_delimit || cv_enclosed || '1年超2年以内消費税'            || cv_enclosed
         || cv_delimit || cv_enclosed || '2年超3年以内元本額'            || cv_enclosed
         || cv_delimit || cv_enclosed || '2年超3年以内支払利息'          || cv_enclosed
         || cv_delimit || cv_enclosed || '2年超3年以内消費税'            || cv_enclosed
         || cv_delimit || cv_enclosed || '3年超4年以内元本額'            || cv_enclosed
         || cv_delimit || cv_enclosed || '3年超4年以内支払利息'          || cv_enclosed
         || cv_delimit || cv_enclosed || '3年超4年以内消費税'            || cv_enclosed
         || cv_delimit || cv_enclosed || '4年超5年以内元本額'            || cv_enclosed
         || cv_delimit || cv_enclosed || '4年超5年以内支払利息'          || cv_enclosed
         || cv_delimit || cv_enclosed || '4年超5年以内消費税'            || cv_enclosed
         || cv_delimit || cv_enclosed || '5年超元本額'                   || cv_enclosed
         || cv_delimit || cv_enclosed || '5年超支払利息'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '5年超消費税'                   || cv_enclosed
         || cv_delimit || cv_enclosed || '減価償却累計額相当額'          || cv_enclosed
         || cv_delimit || cv_enclosed || '期末残高相当額'                || cv_enclosed
         || cv_delimit || cv_enclosed || '支払利息相当額'                || cv_enclosed
         || cv_delimit || cv_enclosed || '減価償却相当額'                || cv_enclosed
         || cv_delimit || cv_enclosed || '月間リース料(控除額)'          || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース料総額(控除額)'          || cv_enclosed
         || cv_delimit || cv_enclosed || '当期支払リース料(控除額)'      || cv_enclosed
         || cv_delimit || cv_enclosed || '未経過リース料(控除額)'        || cv_enclosed
         || cv_delimit || cv_enclosed || '1年以内未経過リース料(控除額)' || cv_enclosed
         || cv_delimit || cv_enclosed || '1年超未経過リース料(控除額)'   || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース種類'                    || cv_enclosed
         || cv_delimit || cv_enclosed || '契約枝番'                      || cv_enclosed
         || cv_delimit || cv_enclosed || '物件コード'                    || cv_enclosed
         || cv_delimit || cv_enclosed || '管理部門'                      || cv_enclosed
         || cv_delimit || cv_enclosed || '管理部門名'                    || cv_enclosed
         || cv_delimit || cv_enclosed || '契約ステータス'                || cv_enclosed
         || cv_delimit || cv_enclosed || '契約ステータス名'              || cv_enclosed
         || cv_delimit || cv_enclosed || '物件ステータス'                || cv_enclosed
         || cv_delimit || cv_enclosed || '物件ステータス名'              || cv_enclosed
         || cv_delimit || cv_enclosed || '(契約)再リース回数'            || cv_enclosed
         || cv_delimit || cv_enclosed || '(物件)再リース回数'            || cv_enclosed
         || cv_delimit || cv_enclosed || '資産番号'                      || cv_enclosed
         || cv_delimit || cv_enclosed || '種類'                          || cv_enclosed
         || cv_delimit || cv_enclosed || '当年度リース月数'              || cv_enclosed
    );
    -- データの出力
    <<lines_loop>>
    FOR i IN 1 .. l_cont_planning_tab.COUNT LOOP
        -- 項目値
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   =>          cv_enclosed || l_cont_planning_tab( i ).lease_company          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_company_name     || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).period_name_from       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).period_name_to         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).contract_number        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_class_name       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_type_name        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_start_date       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_end_date         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).payment_frequency      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).second_charge          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).gross_charge           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lcharge_year           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lcharge_future         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lcharge_fut_1year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lcharge_fut_ov1year    || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).original_cost          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_rem           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_interest_due       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_rem       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_1year         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_1year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_1year     || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_ov1year       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_ov1year    || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_ov1year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_1to2year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_1to2year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_1to2year  || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_2to3year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_2to3year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_2to3year  || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_3to4year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_3to4year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_3to4year  || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_4to5year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_4to5year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_4to5year  || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_ov5year       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_ov5year    || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_ov5year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).deprn_reserve          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).bal_amount             || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).interest_amount        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).deprn_amount           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).monthly_deduction      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).gross_deduction        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lded_year              || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lded_future            || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lded_fut_1year         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lded_fut_ov1year       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_kind_name        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).contract_line_num      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).object_code            || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).department_code        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).department_name        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).contract_status        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).contract_status_name   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).object_status          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).object_status_name     || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).cont_re_lease_times    || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).obj_re_lease_times     || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).asset_number           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).category_name          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_mcount           || cv_enclosed
        );
        --成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP lines_loop;
--
--
    -- 対象件数０件の場合、終了ステータスを「警告」にする
    IF (gn_target_cnt = 0) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '対象データが存在しません。'
      );
      ov_retcode := cv_status_warn;
    END IF;
--
--
  EXCEPTION
    -- *** 入力パラメータ例外ハンドラ ***
    WHEN err_prm_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- 異常件数カウント
      gn_error_cnt := gn_error_cnt + 1;
    -- *** 会計期間取得例外ハンドラ ***
    WHEN err_period_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- 異常件数カウント
      gn_error_cnt := gn_error_cnt + 1;
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
    errbuf              OUT VARCHAR2,       --   エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,       --   リターン・コード    --# 固定 #
    iv_contract_number  IN  VARCHAR2,       --    1.契約番号
    iv_lease_company    IN  VARCHAR2,       --    2.リース会社
    iv_object_code_01   IN  VARCHAR2,       --    3.物件コード1
    iv_object_code_02   IN  VARCHAR2,       --    4.物件コード2
    iv_object_code_03   IN  VARCHAR2,       --    5.物件コード3
    iv_object_code_04   IN  VARCHAR2,       --    6.物件コード4
    iv_object_code_05   IN  VARCHAR2,       --    7.物件コード5
    iv_object_code_06   IN  VARCHAR2,       --    8.物件コード6
    iv_object_code_07   IN  VARCHAR2,       --    9.物件コード7
    iv_object_code_08   IN  VARCHAR2,       --   10.物件コード8
    iv_object_code_09   IN  VARCHAR2,       --   11.物件コード9
    iv_object_code_10   IN  VARCHAR2        --   12.物件コード10
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
    -- パラメータをグローバル変数に設定
    gv_contract_number := iv_contract_number;  -- 契約番号
    gv_lease_company   := iv_lease_company;    -- リース会社
    gv_object_code_01  := iv_object_code_01;   -- 物件コード1
    gv_object_code_02  := iv_object_code_02;   -- 物件コード2
    gv_object_code_03  := iv_object_code_03;   -- 物件コード3
    gv_object_code_04  := iv_object_code_04;   -- 物件コード4
    gv_object_code_05  := iv_object_code_05;   -- 物件コード5
    gv_object_code_06  := iv_object_code_06;   -- 物件コード6
    gv_object_code_07  := iv_object_code_07;   -- 物件コード7
    gv_object_code_08  := iv_object_code_08;   -- 物件コード8
    gv_object_code_09  := iv_object_code_09;   -- 物件コード9
    gv_object_code_10  := iv_object_code_10;   -- 物件コード10
    -- プログラム入力項目を出力
    -- 契約番号
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '契約番号：' || gv_contract_number
    );
    -- リース会社
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'リース会社：' || gv_lease_company
    );
    -- 物件コード1
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード1：' || gv_object_code_01
    );
    -- 物件コード2
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード2：' || gv_object_code_02
    );
    -- 物件コード3
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード3：' || gv_object_code_03
    );
    -- 物件コード4
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード4：' || gv_object_code_04
    );
    -- 物件コード5
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード5：' || gv_object_code_05
    );
    -- 物件コード6
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード6：' || gv_object_code_06
    );
    -- 物件コード7
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード7：' || gv_object_code_07
    );
    -- 物件コード8
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード8：' || gv_object_code_08
    );
    -- 物件コード9
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード9：' || gv_object_code_09
    );
    -- 物件コード10
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード10：' || gv_object_code_10
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
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
    --エラーの場合、成功件数クリア
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
    --
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
END XXCCP008A04C;
/
