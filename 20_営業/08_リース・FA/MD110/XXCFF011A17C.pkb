CREATE OR REPLACE PACKAGE BODY XXCFF011A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF011A17C(body)
 * Description      : リース会計基準開示データ出力
 * MD.050           : リース会計基準開示データ出力 MD050_CFF_011_A17
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   入力パラメータ値ログ出力処理(A-1)
 *  chk_period_name        会計期間チェック処理(A-2)
 *  get_first_period       会計期間期首取得処理(A-3)
 *  get_contract_info      リース契約情報取得処理(A-4)
 *  get_pay_planning       リース支払計画情報取得処理(A-5)
 *  out_csv_data           CSVデータ出力処理(A-6)
 *  get_asset_info         リース資産情報取得処理(A-8)
 *  get_lease_obl_info     リース債務情報取得処理(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   SCS山岸          新規作成
 *  2009/02/18    1.1   SCS山岸          [障害CFF_041] 初回、2回目同月支払の場合の不具合対応
 *  2009/02/24    1.2   SCS山岸          [障害CFF_054] リース満了月の場合の不具合対応
 *  2009/07/17    1.3   SCS萱原          [統合テスト障害0000417] 支払計画の当期支払リース料取得処理修正
 *  2009/07/31    1.4   SCS渡辺          [統合テスト障害0000417(追加)]
 *                                         ・取得価額、減価償却累計額の取得条件を修正
 *                                         ・支払利息相当額、当期支払リース料（控除額）の取得条件修正
 *                                         ・リース契約情報取得カーソルをリース種類で分割
 *  2009/08/28    1.5   SCS 渡辺         [統合テスト障害0001061(PT対応)]
 *  2016/09/14    1.6   SCSK 郭          E_本稼動_13658（自販機耐用年数変更対応）
 *  2018/03/27    1.7   SCSK 小路        E_本稼動_14830（IFRSリース資産対応）
 *  2020/04/06    1.8   SCSK 桑子        E_本稼動_16255 (会計基準帳票 修正対応)
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
  no_data_expt               EXCEPTION;     -- 対象データなし例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF011A17C'; -- パッケージ名
  cv_appl_short_name  CONSTANT VARCHAR2(100) := 'XXCFF';        -- アプリケーション短縮名
  cv_which            CONSTANT VARCHAR2(100) := 'LOG';          -- コンカレントログ出力先
  -- メッセージ
  cv_msg_close        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00038'; -- 会計期間仮クローズチェックエラー
  cv_msg_no_data      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062'; -- 対象データ無し
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
  cv_msg_req_chk      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00108'; -- 必須チェックエラー
  -- トークン値
  cv_tkv_com_or_cla   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50327'; -- リース会社、リース種別
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  -- トークン
  cv_tkn_book_type    CONSTANT VARCHAR2(50)  := 'BOOK_TYPE_CODE';   -- 資産台帳名
  cv_tkn_period_name  CONSTANT VARCHAR2(50)  := 'PERIOD_NAME';      -- 会計期間名
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
  cv_tkn_input_dta    CONSTANT VARCHAR2(50)  := 'INPUT';            -- パラメータ
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  -- リース種類
  cv_lease_kind_fin   CONSTANT VARCHAR2(1)   := '0';  -- Finリース
  cv_lease_kind_op    CONSTANT VARCHAR2(1)   := '1';  -- Opリース
  cv_lease_kind_qfin  CONSTANT VARCHAR2(1)   := '2';  -- 旧Finリース
  -- 資産台帳区分
  cv_book_class_1     CONSTANT VARCHAR2(1)   := '1';  -- 会計用
  cv_book_class_2     CONSTANT VARCHAR2(1)   := '2';  -- 法人税用
-- 2018/03/27 Ver.1.7 Y.Shoji ADD START
  cv_book_class_3     CONSTANT VARCHAR2(1)   := '3';  -- IFRS用
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  -- 契約ステータス
  cv_contr_st_201     CONSTANT VARCHAR2(3)   := '201'; -- 登録済み
-- 0000417 2009/07/31 ADD START --
  -- 除売却ステータス
  cv_processed        CONSTANT VARCHAR2(9)   := 'PROCESSED'; --処理済
  -- 会計IFフラグステータス
  cv_if_aft           CONSTANT VARCHAR2(1)   := '2'; --連携済
-- 0000417 2009/07/31 ADD END --
-- 2018/03/27 Ver.1.7 Y.Shoji ADD START
  cv_format_yyyy_mm   CONSTANT VARCHAR2(7)   := 'YYYY-MM';   --日付形式:YYYY-MM
  cv_format_mm        CONSTANT VARCHAR2(2)   := 'MM';        --日付形式:MM
  cv_source_code_dep  CONSTANT VARCHAR2(5)   := 'DEPRN';     --減価償却
  cv_lease_type_1     CONSTANT VARCHAR2(1)   := '1';         --原契約
  cv_lease_type_2     CONSTANT VARCHAR2(1)   := '2';         --再リース
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_csv_rtype IS RECORD (
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--     contract_header_id      xxcff_contract_headers.contract_header_id%TYPE
     contract_line_id        xxcff_contract_lines.contract_line_id%TYPE   -- リース契約明細ID
    ,object_code             xxcff_object_headers.object_code%TYPE        -- 物件コード
    ,lease_type              xxcff_contract_headers.lease_type%TYPE       -- リース区分
    ,cancellation_date       xxcff_contract_lines.cancellation_date%TYPE  -- 解約月
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
    ,lease_company           xxcff_contract_headers.lease_company%TYPE -- リース会社コード
    ,lease_company_name      VARCHAR2(240) -- リース会社名
    ,period_from             VARCHAR2(10) -- 出力期間（自）
    ,period_to               VARCHAR2(10) -- 出力期間（至）
    ,contract_number         xxcff_contract_headers.contract_number%TYPE -- 契約No
    ,lease_class_name        VARCHAR2(240) -- 分類
    ,lease_type_name         VARCHAR2(240) -- リース区分
    ,lease_start_date        DATE          -- リース開始日
    ,lease_end_date          DATE          -- リース終了日
    ,payment_frequency       xxcff_contract_headers.payment_frequency%TYPE -- 月数
    ,monthly_charge          NUMBER(15) -- 月間リース料
    ,gross_charge            NUMBER(15) -- リース料総額
    ,lease_charge_this_month NUMBER(15) -- 当期支払リース料
    ,lease_charge_future     NUMBER(15) -- 未経過リース料
    ,lease_charge_1year      NUMBER(15) -- 1年以内未経過リース料
    ,lease_charge_over_1year NUMBER(15) -- 1年越未経過リース料
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--    ,original_cost           NUMBER(15) -- 取得価額相当額
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
    ,lease_charge_debt       NUMBER(15) -- 未経過リース期末残高相当額
    ,interest_future         NUMBER(15) -- 未経過リース支払利息額
    ,tax_future              NUMBER(15) -- 未経過リース消費税額
    ,principal_1year         NUMBER(15) -- 1年以内元本
    ,interest_1year          NUMBER(15) -- 1年以内支払利息
    ,tax_1year               NUMBER(15) -- 1年以内消費税
    ,principal_over_1year    NUMBER(15) -- 1年越元本
    ,interest_over_1year     NUMBER(15) -- 1年越支払利息
    ,tax_over_1year          NUMBER(15) -- 1年越消費税
    ,principal_1to2year      NUMBER(15) -- 1年越2年以内元本
    ,interest_1to2year       NUMBER(15) -- 1年越2年以内支払利息
    ,tax_1to2year            NUMBER(15) -- 1年越2年以内消費税
    ,principal_2to3year      NUMBER(15) -- 2年超3年以内元本
    ,interest_2to3year       NUMBER(15) -- 2年超3年以内支払利息
    ,tax_2to3year            NUMBER(15) -- 2年超3年以内消費税
    ,principal_3to4year      NUMBER(15) -- 3年越4年以内元本
    ,interest_3to4year       NUMBER(15) -- 3年越4年以内支払利息
    ,tax_3to4year            NUMBER(15) -- 3年越4年以内消費税
    ,principal_4to5year      NUMBER(15) -- 4年越5年以内元本
    ,interest_4to5year       NUMBER(15) -- 4年越5年以内支払利息
    ,tax_4to5year            NUMBER(15) -- 4年越5年以内消費税
    ,principal_over_5year    NUMBER(15) -- 5年越元本
    ,interest_over_5year     NUMBER(15) -- 5年越支払利息
    ,tax_over_5year          NUMBER(15) -- 5年越消費税
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--    ,deprn_reserve           NUMBER(15) -- 減価償却累計額相当額 
--    ,bal_amount              NUMBER(15) -- 期末残高相当額
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
    ,interest_amount         NUMBER(15) -- 支払利息相当額
    ,deprn_amount            NUMBER(15) -- 減価償却相当額
    ,monthly_deduction       NUMBER(15) -- 月間リース料（控除額）
    ,gross_deduction         NUMBER(15) -- リース料総額（控除額）
    ,deduction_this_month    NUMBER(15) -- 当期支払リース料（控除額）
    ,deduction_future        NUMBER(15) -- 未経過リース料（控除額）
    ,deduction_1year         NUMBER(15) -- 1年以内未経過リース料（控除額）
    ,deduction_over_1year    NUMBER(15) -- 1年越未経過リース料（控除額）
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
     -- リース資産情報
    ,asset_number              fa_additions_b.asset_number%TYPE        -- 資産番号
    ,original_cost             fa_books.original_cost%TYPE             -- 当初取得価額
    ,cost                      fa_books.cost%TYPE                      -- 取得価額
    ,salvage_value             fa_books.salvage_value%TYPE             -- 残存価額
    ,adjusted_recoverable_cost fa_books.adjusted_recoverable_cost%TYPE -- 償却対象額
    ,kisyu_boka                NUMBER(15)                              -- 期首帳簿価額
    ,year_add_amount_new       NUMBER(15)                              -- 期中増加額(新規契約)
    ,year_add_amount_old       NUMBER(15)                              -- 期中増加額(既存契約)
    ,add_amount_new            NUMBER(15)                              -- 当月増加額(新規契約)
    ,add_amount_old            NUMBER(15)                              -- 当月増加額(既存契約)
    ,year_dec_amount           NUMBER(15)                              -- 期中減少額（償却終了）
    ,year_del_amount           NUMBER(15)                              -- 期中減少額（解約）
    ,dec_amount                NUMBER(15)                              -- 当月減少額（償却終了）
    ,delete_amount             NUMBER(15)                              -- 当月減少額（解約）
    ,deprn_reserve             NUMBER(15)                              -- 期末純帳簿価額
    ,month_deprn               NUMBER(15)                              -- 当月償却累計額
    ,ytd_deprn                 fa_deprn_summary.ytd_deprn%TYPE         -- 年償却累計額
    ,total_amount              fa_deprn_summary.deprn_reserve%TYPE     -- 償却累計額
    ,disc_seg                  fa_additions_b.attribute12%TYPE         -- 開示セグメント
    ,area                      fa_additions_b.attribute13%TYPE         -- 面積
     -- リース債務情報
    ,lease_original_cost       xxcff_contract_lines.original_cost%TYPE -- 取得価額
    ,kisyu_bal_amount          NUMBER(15)                              -- 期首残高
    ,lease_year_add_amount_new NUMBER(15)                              -- 期中増加額（新規契約）
    ,lease_year_add_amount_old NUMBER(15)                              -- 期中増加額（既存契約）
    ,lease_add_amount_new      NUMBER(15)                              -- 当月増加額（新規契約）
    ,lease_add_amount_old      NUMBER(15)                              -- 当月増加額（既存契約）
    ,lease_year_dec_amount     NUMBER(15)                              -- 期中減少額（債務返済）
    ,lease_year_del_amount     NUMBER(15)                              -- 期中減少額（解約）
    ,lease_dec_amount          NUMBER(15)                              -- 当月減少額（債務返済）
    ,lease_delete_amount       NUMBER(15)                              -- 当月減少額（解約）
    ,kimatsu_bal_amount        NUMBER(15)                              -- 期末残高
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
  /**********************************************************************************
   * Procedure Name   : get_lease_obl_info
   * Description      : リース債務情報取得処理(A-9)
   ***********************************************************************************/
  PROCEDURE get_lease_obl_info(
    io_csv_rec        IN OUT g_csv_rtype,  -- 1.CSV出力レコード
    ov_errbuf         OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_obl_info'; -- プログラム名
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
    lv_del_period_name     VARCHAR2(7);       -- 債務返済月
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
-- 2020/04/06 Ver.1.8 S.Kuwako ADD Start
    IF ( io_csv_rec.lease_start_date  < TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
-- 2020/04/06 Ver.1.8 S.Kuwako ADD End
      -- 1.期首残高の取得
      BEGIN
        SELECT xpp.fin_debt
             + xpp.fin_debt_rem
             + NVL(xpp.debt_re ,0)
             + NVL(xpp.debt_rem_re ,0)       AS kisyu_bal_amount -- 期首残高
        INTO   io_csv_rec.kisyu_bal_amount
        FROM   xxcff_pay_planning xpp
        WHERE  xpp.contract_line_id  =  io_csv_rec.contract_line_id
        AND    xpp.period_name       =  io_csv_rec.period_from
        AND    XPP.payment_frequency <> 1                           -- 支払回数1回目ではない
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          io_csv_rec.kisyu_bal_amount := 0;
      END;
-- 2020/04/06 Ver.1.8 S.Kuwako ADD Start
    ELSE
      io_csv_rec.kisyu_bal_amount := 0;
    END IF;
-- 2020/04/06 Ver.1.8 S.Kuwako ADD End
--
    -- 期中増加額の取得
    IF (  io_csv_rec.lease_start_date >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm)
      AND io_csv_rec.lease_start_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
      -- 2.原契約の場合、新規契約
      IF ( io_csv_rec.lease_type = cv_lease_type_1) THEN
        io_csv_rec.lease_year_add_amount_new := io_csv_rec.lease_original_cost;
        io_csv_rec.lease_year_add_amount_old := 0;
      -- 3.再リースの場合、既存契約
      ELSIF ( io_csv_rec.lease_type = cv_lease_type_2) THEN
        io_csv_rec.lease_year_add_amount_new := 0;
        io_csv_rec.lease_year_add_amount_old := io_csv_rec.lease_original_cost;
      END IF;
    ELSE
      io_csv_rec.lease_year_add_amount_new := 0;
      io_csv_rec.lease_year_add_amount_old := 0;
    END IF;
--
    -- 当月増加額の取得
    IF (  io_csv_rec.lease_start_date >= TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)
      AND io_csv_rec.lease_start_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
      -- 4.原契約の場合、新規契約
      IF ( io_csv_rec.lease_type = cv_lease_type_1) THEN
        io_csv_rec.lease_add_amount_new := io_csv_rec.lease_original_cost;
        io_csv_rec.lease_add_amount_old := 0;
      -- 5.再リースの場合、既存契約
      ELSIF ( io_csv_rec.lease_type = cv_lease_type_2) THEN
        io_csv_rec.lease_add_amount_new := 0;
        io_csv_rec.lease_add_amount_old := io_csv_rec.lease_original_cost;
      END IF;
    ELSE
      io_csv_rec.lease_add_amount_new := 0;
      io_csv_rec.lease_add_amount_old := 0;
    END IF;
--
    -- 6.債務返済月の取得
    BEGIN
      SELECT MAX(xpp.period_name) AS del_period_name
      INTO   lv_del_period_name
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id = io_csv_rec.contract_line_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_del_period_name := NULL;
    END;
--
    -- 7.期中減少額（債務返済）の取得
    IF (  TO_DATE(lv_del_period_name ,cv_format_yyyy_mm) >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm)
      AND TO_DATE(lv_del_period_name ,cv_format_yyyy_mm) <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
      io_csv_rec.lease_year_dec_amount := io_csv_rec.kisyu_bal_amount;
    ELSE
      io_csv_rec.lease_year_dec_amount := 0;
    END IF;
--
    -- 8.期中減少額(解約)の取得
    IF (  io_csv_rec.cancellation_date >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm)
-- 2020/04/06 Ver.1.8 S.Kuwako MOD Start
--      AND io_csv_rec.cancellation_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
      AND io_csv_rec.cancellation_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
      AND io_csv_rec.kisyu_bal_amount  >  0  )  THEN
-- 2020/04/06 Ver.1.8 S.Kuwako MOD End
      io_csv_rec.lease_year_del_amount := io_csv_rec.kisyu_bal_amount;
      -- 解約と債務返済が同月の場合、債務返済は0とする
      io_csv_rec.lease_year_dec_amount := 0;
-- 2020/04/06 Ver.1.8 S.Kuwako ADD Start
    ELSIF ( io_csv_rec.cancellation_date >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm)
      AND   io_csv_rec.cancellation_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
      AND   io_csv_rec.kisyu_bal_amount   = 0
      AND   io_csv_rec.lease_year_add_amount_new + io_csv_rec.lease_year_add_amount_old > 0 )  THEN
      io_csv_rec.lease_year_del_amount := io_csv_rec.lease_year_add_amount_new + io_csv_rec.lease_year_add_amount_old;
-- 2020/04/06 Ver.1.8 S.Kuwako ADD End
    ELSE
      io_csv_rec.lease_year_del_amount := 0;
    END IF;
--
    -- 9.当月減少額（債務返済）の取得
    IF (  lv_del_period_name = io_csv_rec.period_to
      AND io_csv_rec.lease_year_del_amount = 0     ) THEN
      io_csv_rec.lease_dec_amount := io_csv_rec.kisyu_bal_amount;
    ELSE
      io_csv_rec.lease_dec_amount := 0;
    END IF;
--
    -- 10.当月減少額（解約）の取得
    IF (  io_csv_rec.cancellation_date >= TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)
      AND io_csv_rec.cancellation_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
--
      BEGIN
        SELECT xpp.fin_debt_rem + NVL(xpp.debt_rem_re ,0) AS lease_year_del_amount
        INTO   io_csv_rec.lease_delete_amount
        FROM   xxcff_pay_planning xpp
        WHERE  xpp.contract_line_id = io_csv_rec.contract_line_id
        AND    xpp.period_name      = TO_CHAR(io_csv_rec.cancellation_date ,cv_format_yyyy_mm)
        ;
        -- 解約と債務返済が同月の場合、債務返済は0とする
        io_csv_rec.lease_dec_amount := 0;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          io_csv_rec.lease_delete_amount := 0;
      END;
--
    ELSE
      io_csv_rec.lease_delete_amount := 0;
    END IF;
--
    -- 11.期末残高の取得
    -- -- 期中減少額（解約）が存在しない場合
    IF (io_csv_rec.lease_year_del_amount = 0) THEN
      BEGIN
        SELECT xpp.fin_debt_rem  + NVL(xpp.debt_rem_re ,0) AS kimatsu_bal_amount -- 期末残高
        INTO   io_csv_rec.kimatsu_bal_amount
        FROM   xxcff_pay_planning xpp
        WHERE  xpp.contract_line_id  = io_csv_rec.contract_line_id
        AND    xpp.period_name       = io_csv_rec.period_to
        AND    xpp.payment_frequency = (SELECT MAX(xpp2.payment_frequency)
                                        FROM   xxcff_pay_planning xpp2
                                        WHERE  xpp2.contract_line_id  = io_csv_rec.contract_line_id
                                        AND    xpp2.period_name       = io_csv_rec.period_to)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          io_csv_rec.kimatsu_bal_amount := 0;
      END;
    ELSE
      io_csv_rec.kimatsu_bal_amount := 0;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END get_lease_obl_info;
--
  /**********************************************************************************
   * Procedure Name   : get_asset_info
   * Description      : リース資産情報取得処理(A-8)
   ***********************************************************************************/
  PROCEDURE get_asset_info(
    iv_book_type_code IN     VARCHAR2,     -- 1.資産台帳名
    io_csv_rec        IN OUT g_csv_rtype,  -- 2.CSV出力レコード
    ov_errbuf         OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_asset_info'; -- プログラム名
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
    CURSOR asset_cur
    IS
      SELECT
             /*+
               LEADING(main)
             */
             main.asset_number               AS asset_number               -- 資産番号
            ,main.original_cost              AS original_cost              -- 当初取得価額
            ,main.cost                       AS cost                       -- 取得価額
            ,main.salvage_value              AS salvage_value              -- 残存価額
            ,main.adjusted_recoverable_cost  AS adjusted_recoverable_cost  -- 償却対象額
            --過去年度の資産を次年度以降に資産追加した場合、
            --過去年度の減価償却サマリからは期首簿価が取れないため、
            --期末純帳簿価額＋年償却累計額で算出
            ,CASE
               WHEN (NVL(kisyu.kisyu_boka, 0)    = 0
                 AND main.date_placed_in_service < TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                 main.ytd_deprn + main.deprn_reserve
               ELSE
                 NVL(kisyu.kisyu_boka, 0)
             END                             AS kisyu_boka                -- 期首帳簿価額
            ,CASE
               WHEN (io_csv_rec.lease_type       =  cv_lease_type_1
                 AND main.date_placed_in_service <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
                 AND main.date_placed_in_service >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                 main.cost
               ELSE
                 0
             END                             AS year_add_amount_new       -- 期中増加額(新規契約)
            ,CASE
               WHEN (io_csv_rec.lease_type       =  cv_lease_type_2
                 AND main.date_placed_in_service <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
                 AND main.date_placed_in_service >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                 main.cost
               ELSE
                 0
             END                             AS year_add_amount_old       -- 期中増加額(既存契約)
            ,CASE
               WHEN (io_csv_rec.lease_type                            = cv_lease_type_1
                 AND TRUNC(main.date_placed_in_service ,cv_format_mm) = TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm) ) THEN
                 main.cost
               ELSE
                 0
             END                             AS add_amount_new            -- 当月増加額(新規契約)
            ,CASE
               WHEN (io_csv_rec.lease_type                            = cv_lease_type_2
                 AND TRUNC(main.date_placed_in_service ,cv_format_mm) = TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm) ) THEN
                 main.cost
               ELSE
                 0
             END                             AS add_amount_old            -- 当月増加額(既存契約)
            ,CASE
               WHEN (main.deprn_reserve = 0
                 AND main.nbv_retired   = 0) THEN
                 CASE
                   WHEN (NVL(kisyu.kisyu_boka, 0)    = 0
                     AND main.date_placed_in_service < TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                     main.ytd_deprn
                   ELSE
                     NVL(kisyu.kisyu_boka, 0)
                 END
               ELSE
                 0
             END                             AS year_dec_amount           -- 期中減少額（償却終了）
            ,CASE
               WHEN (main.date_retired <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
                 AND main.date_retired >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                 main.nbv_retired     -- 除売却帳簿価額
               ELSE
                 0
             END                             AS year_del_amount           -- 期中減少額（解約）
            ,CASE
               WHEN (main.deprn_reserve = 0
                 AND main.nbv_retired   = 0) THEN
                 CASE
                   WHEN (main.period_name = io_csv_rec.period_to) THEN
                     CASE
                       WHEN (NVL(kisyu.kisyu_boka, 0)    = 0
                         AND main.date_placed_in_service < TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                         main.ytd_deprn
                       ELSE
                         NVL(kisyu.kisyu_boka, 0)
                     END
                   ELSE
                     0
                   END
               ELSE
                 0
             END                             AS dec_amount                -- 当月減少額（償却終了）
            ,CASE
               WHEN (TRUNC(main.date_retired ,cv_format_mm) = TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm) ) THEN
                 main.nbv_retired      -- 除売却帳簿価額
               ELSE
                 0
             END                             AS delete_amount             -- 当月減少額（解約）
            ,main.deprn_reserve              AS deprn_reserve             -- 期末純帳簿価額
            ,CASE
               WHEN (main.period_name = io_csv_rec.period_to) THEN
                 main.month_deprn
               ELSE
                 0
             END                             AS month_deprn               -- 当月償却累計額
            ,main.ytd_deprn                  AS ytd_deprn                 -- 年償却累計額
            ,main.total_amount               AS total_amount              -- 償却累計額
            ,main.disc_seg                   AS disc_seg                  -- 開示セグメント
            ,main.area                       AS area                      -- 面積
      FROM   (SELECT /*+ LEADING(fdsp)
                         INDEX(fb FA_BOOKS_N1)
                         INDEX(fdp FA_DEPRN_PERIODS_U3)
                     */
                     fdsp_max.asset_id                   AS asset_id                     -- 資産ID
                    ,fdsp_max.book_type_code             AS book_type_code               -- 資産台帳
                    ,fdsp_max.asset_number               AS asset_number                 -- 資産番号
                    ,fb.original_cost                    AS original_cost                -- 当初取得価額
                    ,fb.cost                             AS cost                         -- 取得価額
                    ,fb.salvage_value                    AS salvage_value                -- 残存価額
                    ,fb.adjusted_recoverable_cost        AS adjusted_recoverable_cost    -- 償却対象額
                    ,fb.date_placed_in_service           AS date_placed_in_service       -- 事業供用日
                    ,CASE
                       WHEN (fb.cost                = 0
                         OR  fdsp_max.deprn_reserve = 0) THEN
                         0
                       ELSE
                         fb.cost - fdsp_max.deprn_reserve
                     END                                 AS deprn_reserve                -- 純帳簿価額
                    ,fdsp_max.period_name                AS period_name                  -- 会計期間
                    ,ret.date_retired                    AS date_retired                 -- 除売却日
                    ,NVL(ret.nbv_retired ,0)             AS nbv_retired                  -- 除売却帳簿価額
                    ,fdsp_max.deprn_amount               AS month_deprn                  -- 当月償却累計額
                    ,fdsp_max.ytd_deprn                  AS ytd_deprn                    -- 年償却累計額
                    ,fdsp_max.deprn_reserve              AS total_amount                 -- 償却累計額
                    ,fdsp_max.disc_seg                   AS disc_seg                     -- 開示セグメント
                    ,fdsp_max.area                       AS area                         -- 面積
              FROM   fa_books                                     fb       -- 資産台帳情報
                    ,fa_retirements                               ret      -- 除売却情報
                    ,(SELECT fdp.period_counter             AS period_counter
                            ,fdp.book_type_code             AS book_type_code
                      FROM   fa_deprn_periods fdp     -- 減価償却期間
                      WHERE  fdp.period_num     = 1
                      AND    fdp.period_name    = io_csv_rec.period_from
                      AND    fdp.book_type_code = iv_book_type_code
                     )                                            fdp1     -- 減価償却期間 年始
                    ,(SELECT /*+
                                LEADING(fab)
                              */
                             fds.asset_id                   AS asset_id                   -- 資産ID
                            ,fab.asset_number               AS asset_number               -- 資産番号
                            ,fds.book_type_code             AS book_type_code             -- 台帳
                            ,fdp.period_name                AS period_name                -- 期間名
                            ,fdp.period_close_date          AS period_close_date          -- 期間クローズ日
                            ,fds.deprn_reserve              AS deprn_reserve              -- 減価償却累計額相当額
                            ,fds.deprn_amount               AS deprn_amount               -- 償却額
                            ,fds.ytd_deprn                  AS ytd_deprn                  -- 年償却累計額
                            ,fab.attribute12                AS disc_seg                   -- 開示セグメント
                            ,fab.attribute13                AS area                       -- 面積
                      FROM   fa_additions_b    fab     -- 資産詳細情報
                            ,fa_deprn_summary  fds     -- 減価償却サマリ
                            ,fa_deprn_periods  fdp     -- 減価償却期間
                            ,(SELECT /*+
                                        LEADING(fab)
                                      */
                                     MAX(fdp.period_counter) period_counter
                              FROM   fa_additions_b    fab     -- 資産詳細情報
                                    ,fa_deprn_summary  fds     -- 減価償却サマリ
                                    ,fa_deprn_periods  fdp     -- 減価償却期間
                              WHERE  fab.attribute10       = TO_CHAR(io_csv_rec.contract_line_id)
                              AND    fab.asset_id          = fds.asset_id
                              AND    fds.book_type_code    = iv_book_type_code
                              AND    fds.book_type_code    = fdp.book_type_code
                              AND    fds.period_counter    = fdp.period_counter
                              AND    fds.deprn_source_code = cv_source_code_dep
                              AND    fdp.period_name       <= io_csv_rec.period_to
                             )                 fdp_max -- 対象月以前の減価償却期間最大の月
                      WHERE  fab.attribute10                    = TO_CHAR(io_csv_rec.contract_line_id)
                      AND    fab.asset_id                       = fds.asset_id
                      AND    fds.book_type_code                 = iv_book_type_code
                      AND    fds.book_type_code                 = fdp.book_type_code
                      AND    fds.period_counter                 = fdp.period_counter
                      AND    fds.deprn_source_code              = cv_source_code_dep
                      AND    fdp.period_counter                 = fdp_max.period_counter
                     ) fdsp_max                                            -- 対象月以前の最大の月の減価償却情報
              WHERE  NVL(fb.date_ineffective ,fdsp_max.period_close_date) >= fdsp_max.period_close_date
              AND    fb.date_effective                                    <  fdsp_max.period_close_date
              AND    fb.book_type_code                                    =  fdsp_max.book_type_code
              AND    fb.asset_id                                          =  fdsp_max.asset_id
              AND    NVL(fb.period_counter_fully_retired,9999999)         >= fdp1.period_counter               -- 当年度以降の除売却データ
              AND    fb.book_type_code                                    =  fdp1.book_type_code
              AND    fb.asset_id                                          =  ret.asset_id (+)
              AND    fb.book_type_code                                    =  ret.book_type_code (+)
              AND    fb.transaction_header_id_in                          =  ret.transaction_header_id_in (+)
             ) main                                 -- 償却
            ,(SELECT /*+
                         LEADING(fab)
                     */
                     fab.asset_id                  AS asset_id         -- 資産id
                    ,fb.book_type_code             AS book_type_code   -- 台帳
                    ,(fb.cost - fds.deprn_reserve) AS kisyu_boka       -- 期首簿価
              FROM   fa_additions_b    fab     -- 資産詳細情報
                    ,fa_books          fb      -- 資産台帳情報
                    ,fa_deprn_summary  fds     -- 減価償却サマリ
                    ,fa_deprn_periods  fdp     -- 減価償却期間
              WHERE  fab.attribute10                   = TO_CHAR(io_csv_rec.contract_line_id)
              AND    fab.asset_id                      = fb.asset_id
              AND    fb.book_type_code                 = iv_book_type_code
              AND    fb.date_effective                 <= fdp.period_close_date
              AND    NVL(fb.date_ineffective ,SYSDATE) >= fdp.period_close_date
              AND    fb.book_type_code                 = fds.book_type_code
              AND    fb.asset_id                       = fds.asset_id
              AND    fds.book_type_code                = fdp.book_type_code
              AND    fds.period_counter                = fdp.period_counter
              AND    fds.deprn_source_code             = cv_source_code_dep
              AND    fdp.period_num                    = 12
              AND    fdp.fiscal_year + 1               = TO_NUMBER(SUBSTR(io_csv_rec.period_from ,1 ,4))
             ) kisyu                                -- 期首
      WHERE  main.asset_id           = kisyu.asset_id(+)
      AND    main.book_type_code     = kisyu.book_type_code(+)
      ;
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
    <<asset_loop>>
    FOR l_rec IN asset_cur LOOP
      io_csv_rec.asset_number              := l_rec.asset_number;              -- 資産番号
      io_csv_rec.original_cost             := l_rec.original_cost;             -- 当初取得価額
      io_csv_rec.cost                      := l_rec.cost;                      -- 取得価額
      io_csv_rec.salvage_value             := l_rec.salvage_value;             -- 残存価額
      io_csv_rec.adjusted_recoverable_cost := l_rec.adjusted_recoverable_cost; -- 償却対象額
      io_csv_rec.kisyu_boka                := l_rec.kisyu_boka;                -- 期首帳簿価額
      io_csv_rec.year_add_amount_new       := l_rec.year_add_amount_new;       -- 期中増加額(新規契約)
      io_csv_rec.year_add_amount_old       := l_rec.year_add_amount_old;       -- 期中増加額(既存契約)
      io_csv_rec.add_amount_new            := l_rec.add_amount_new;            -- 当月増加額(新規契約)
      io_csv_rec.add_amount_old            := l_rec.add_amount_old;            -- 当月増加額(既存契約)
      io_csv_rec.year_dec_amount           := l_rec.year_dec_amount;           -- 期中減少額（償却終了）
      io_csv_rec.year_del_amount           := l_rec.year_del_amount;           -- 期中減少額（解約）
      io_csv_rec.dec_amount                := l_rec.dec_amount;                -- 当月減少額（償却終了）
      io_csv_rec.delete_amount             := l_rec.delete_amount;             -- 当月減少額（解約）
      io_csv_rec.deprn_reserve             := l_rec.deprn_reserve;             -- 期末純帳簿価額
      io_csv_rec.month_deprn               := l_rec.month_deprn;               -- 当月償却累計額
      io_csv_rec.ytd_deprn                 := l_rec.ytd_deprn;                 -- 年償却累計額
      io_csv_rec.total_amount              := l_rec.total_amount;              -- 償却累計額
      io_csv_rec.disc_seg                  := l_rec.disc_seg;                  -- 開示セグメント
      io_csv_rec.area                      := l_rec.area;                      -- 面積
    END LOOP asset_loop;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END get_asset_info;
--
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  /**********************************************************************************
   * Procedure Name   : out_csv_data
   * Description      : CSVデータ出力処理(A-6)
   ***********************************************************************************/
  PROCEDURE out_csv_data(
    iv_lease_kind IN     VARCHAR2,     -- 1.リース種類
    io_csv_rec    IN OUT g_csv_rtype,  -- 2.CSV出力レコード
    ov_errbuf     OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_data'; -- プログラム名
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
    cv_process_date CONSTANT DATE          := xxccp_common_pkg2.get_process_date;
    cv_lookup_type  CONSTANT VARCHAR2(100) := 'XXCFF1_LEASE_CSV_ITEM_NAME';
    cv_flag_y       CONSTANT VARCHAR2(1)   := 'Y';
    cv_sep_part     CONSTANT VARCHAR2(1)   := ',';
    cv_double_quat  CONSTANT VARCHAR2(1)   := '"';
--
    -- *** ローカル変数 ***
    lv_csv_row VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
    CURSOR csv_header_cur
    IS
      SELECT flv.description
        FROM fnd_lookup_values_vl flv
       WHERE flv.lookup_type = cv_lookup_type
         AND flv.enabled_flag = cv_flag_y
         AND NVL(flv.start_date_active,cv_process_date) <= cv_process_date
         AND NVL(flv.end_date_active,cv_process_date) >= cv_process_date
         AND flv.attribute1 = cv_flag_y
      ORDER BY flv.lookup_code;
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
    -- 1件目の場合CSVヘッダ出力
    IF (gn_target_cnt = 1) THEN
      -- ヘッダ行を編集
      <<csv_header_loop>>
      FOR l_rec IN csv_header_cur LOOP
        IF (csv_header_cur%ROWCOUNT > 1) THEN
          lv_csv_row := lv_csv_row ||cv_sep_part;
        END IF;
        lv_csv_row := lv_csv_row || cv_double_quat || l_rec.description || cv_double_quat;
      END LOOP csv_header_loop;
      -- 行末の','を取り除く
      lv_csv_row := RTRIM(lv_csv_row,cv_sep_part);
      -- OUTファイルに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_csv_row
      );
    END IF;
    -- OPリースの場合不要情報NULL
    IF iv_lease_kind = cv_lease_kind_op THEN
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      io_csv_rec.original_cost          := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      io_csv_rec.lease_charge_debt      := NULL;
      io_csv_rec.interest_future        := NULL;
      io_csv_rec.tax_future             := NULL;
      io_csv_rec.principal_1year        := NULL;
      io_csv_rec.interest_1year         := NULL;
      io_csv_rec.tax_1year              := NULL;
      io_csv_rec.principal_over_1year   := NULL;
      io_csv_rec.interest_over_1year    := NULL;
      io_csv_rec.tax_over_1year         := NULL;
      io_csv_rec.principal_1to2year     := NULL;
      io_csv_rec.interest_1to2year      := NULL;
      io_csv_rec.tax_1to2year           := NULL;
      io_csv_rec.principal_2to3year     := NULL;
      io_csv_rec.interest_2to3year      := NULL;
      io_csv_rec.tax_2to3year           := NULL;
      io_csv_rec.principal_3to4year     := NULL;
      io_csv_rec.interest_3to4year      := NULL;
      io_csv_rec.tax_3to4year           := NULL;
      io_csv_rec.principal_4to5year     := NULL;
      io_csv_rec.interest_4to5year      := NULL;
      io_csv_rec.tax_4to5year           := NULL;
      io_csv_rec.principal_over_5year   := NULL;
      io_csv_rec.interest_over_5year    := NULL;
      io_csv_rec.tax_over_5year         := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      io_csv_rec.deprn_reserve          := NULL;
--      io_csv_rec.bal_amount             := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      io_csv_rec.interest_amount        := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      io_csv_rec.deprn_amount           := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
    END IF;
    -- CSVデータ編集
    lv_csv_row := 
      cv_double_quat || io_csv_rec.lease_company         || cv_double_quat || cv_sep_part ||                   -- リース会社コード
      cv_double_quat || io_csv_rec.lease_company_name    || cv_double_quat || cv_sep_part ||                   -- リース会社名
      cv_double_quat || io_csv_rec.period_from           || cv_double_quat || cv_sep_part ||                   -- 出力期間（自）
      cv_double_quat || io_csv_rec.period_to             || cv_double_quat || cv_sep_part ||                   -- 出力期間（至）
      cv_double_quat || io_csv_rec.contract_number       || cv_double_quat || cv_sep_part ||                   -- 契約No
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      cv_double_quat || io_csv_rec.object_code           || cv_double_quat || cv_sep_part ||                   -- 物件コード
      cv_double_quat || io_csv_rec.asset_number          || cv_double_quat || cv_sep_part ||                   -- 資産番号
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      cv_double_quat || io_csv_rec.lease_class_name      || cv_double_quat || cv_sep_part ||                   -- 分類
      cv_double_quat || io_csv_rec.lease_type_name       || cv_double_quat || cv_sep_part ||                   -- リース区分
      cv_double_quat || TO_CHAR(io_csv_rec.lease_start_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||  -- リース開始日
      cv_double_quat || TO_CHAR(io_csv_rec.lease_end_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||    -- リース終了日
      TO_CHAR(io_csv_rec.payment_frequency)      || cv_sep_part ||                                             -- 月数
      TO_CHAR(io_csv_rec.monthly_charge)         || cv_sep_part ||                                             -- 月間リース料
      TO_CHAR(io_csv_rec.gross_charge)           || cv_sep_part ||                                             -- リース料総額
      TO_CHAR(io_csv_rec.lease_charge_this_month)|| cv_sep_part ||                                             -- 当期支払リース料
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      -- リース資産
      TO_CHAR(io_csv_rec.original_cost)                  || cv_sep_part ||                                     -- 当初取得価額
      TO_CHAR(io_csv_rec.cost)                           || cv_sep_part ||                                     -- 取得価額
      TO_CHAR(io_csv_rec.salvage_value)                  || cv_sep_part ||                                     -- 残存価額
      TO_CHAR(io_csv_rec.adjusted_recoverable_cost)      || cv_sep_part ||                                     -- 償却対象額
      TO_CHAR(io_csv_rec.kisyu_boka)                     || cv_sep_part ||                                     -- 期首帳簿価額
      TO_CHAR(io_csv_rec.year_add_amount_new)            || cv_sep_part ||                                     -- 期中増加額(新規契約)
      TO_CHAR(io_csv_rec.year_add_amount_old)            || cv_sep_part ||                                     -- 期中増加額(既存契約)
      TO_CHAR(io_csv_rec.add_amount_new)                 || cv_sep_part ||                                     -- 当月増加額(新規契約)
      TO_CHAR(io_csv_rec.add_amount_old)                 || cv_sep_part ||                                     -- 当月増加額(既存契約)
      TO_CHAR(io_csv_rec.year_dec_amount)                || cv_sep_part ||                                     -- 期中減少額(償却終了)
      TO_CHAR(io_csv_rec.year_del_amount)                || cv_sep_part ||                                     -- 期中減少額(解約)
      TO_CHAR(io_csv_rec.dec_amount)                     || cv_sep_part ||                                     -- 当月減少額(償却終了)
      TO_CHAR(io_csv_rec.delete_amount)                  || cv_sep_part ||                                     -- 当月減少額(解約)
      TO_CHAR(io_csv_rec.deprn_reserve)                  || cv_sep_part ||                                     -- 期末純帳簿価額
      TO_CHAR(io_csv_rec.month_deprn)                    || cv_sep_part ||                                     -- 当月償却累計額
      TO_CHAR(io_csv_rec.ytd_deprn)                      || cv_sep_part ||                                     -- 年償却累計額
      TO_CHAR(io_csv_rec.total_amount)                   || cv_sep_part ||                                     -- 償却累計額
      -- リース債務
      TO_CHAR(io_csv_rec.kisyu_bal_amount)               || cv_sep_part ||                                     -- 期首残高
      TO_CHAR(io_csv_rec.lease_year_add_amount_new)      || cv_sep_part ||                                     -- 期中増加額(新規契約)
      TO_CHAR(io_csv_rec.lease_year_add_amount_old)      || cv_sep_part ||                                     -- 期中増加額(既存契約)
      TO_CHAR(io_csv_rec.lease_add_amount_new)           || cv_sep_part ||                                     -- 当月増加額(新規契約)
      TO_CHAR(io_csv_rec.lease_add_amount_old)           || cv_sep_part ||                                     -- 当月増加額(既存契約)
      TO_CHAR(io_csv_rec.lease_year_dec_amount)          || cv_sep_part ||                                     -- 期中減少額(債務返済)
      TO_CHAR(io_csv_rec.lease_year_del_amount)          || cv_sep_part ||                                     -- 期中減少額(解約)
      TO_CHAR(io_csv_rec.lease_dec_amount)               || cv_sep_part ||                                     -- 当月減少額(債務返済)
      TO_CHAR(io_csv_rec.lease_delete_amount)            || cv_sep_part ||                                     -- 当月減少額(解約)
      TO_CHAR(io_csv_rec.kimatsu_bal_amount)             || cv_sep_part ||                                     -- 期末残高
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      TO_CHAR(io_csv_rec.lease_charge_future)    || cv_sep_part ||                                             -- 未経過リース料
      TO_CHAR(io_csv_rec.lease_charge_1year)     || cv_sep_part ||                                             -- 1年以内未経過リース料
      TO_CHAR(io_csv_rec.lease_charge_over_1year)|| cv_sep_part ||                                             -- 1年超未経過リース料
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      TO_CHAR(io_csv_rec.original_cost)          || cv_sep_part ||
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      TO_CHAR(io_csv_rec.lease_charge_debt)      || cv_sep_part ||                                             -- 未経過リース期末残高相当額
      TO_CHAR(io_csv_rec.interest_future)        || cv_sep_part ||                                             -- 未経過リース支払利息額
      TO_CHAR(io_csv_rec.tax_future)             || cv_sep_part ||                                             -- 未経過リース消費税額
      TO_CHAR(io_csv_rec.principal_1year)        || cv_sep_part ||                                             -- 1年以内元本額
      TO_CHAR(io_csv_rec.interest_1year)         || cv_sep_part ||                                             -- 1年以内支払利息
      TO_CHAR(io_csv_rec.tax_1year)              || cv_sep_part ||                                             -- 1年以内消費税
      TO_CHAR(io_csv_rec.principal_over_1year)   || cv_sep_part ||                                             -- 1年超元本額
      TO_CHAR(io_csv_rec.interest_over_1year)    || cv_sep_part ||                                             -- 1年超支払利息
      TO_CHAR(io_csv_rec.tax_over_1year)         || cv_sep_part ||                                             -- 1年超消費税額
      TO_CHAR(io_csv_rec.principal_1to2year)     || cv_sep_part ||                                             -- 1年超2年以内元本額
      TO_CHAR(io_csv_rec.interest_1to2year)      || cv_sep_part ||                                             -- 1年超2年以内支払利息
      TO_CHAR(io_csv_rec.tax_1to2year)           || cv_sep_part ||                                             -- 1年超2年以内消費税額
      TO_CHAR(io_csv_rec.principal_2to3year)     || cv_sep_part ||                                             -- 2年超3年以内元本額
      TO_CHAR(io_csv_rec.interest_2to3year)      || cv_sep_part ||                                             -- 2年超3年以内支払利息
      TO_CHAR(io_csv_rec.tax_2to3year)           || cv_sep_part ||                                             -- 2年超3年以内消費税額
      TO_CHAR(io_csv_rec.principal_3to4year)     || cv_sep_part ||                                             -- 3年超4年以内元本額
      TO_CHAR(io_csv_rec.interest_3to4year)      || cv_sep_part ||                                             -- 3年超4年以内支払利息
      TO_CHAR(io_csv_rec.tax_3to4year)           || cv_sep_part ||                                             -- 3年超4年以内消費税額
      TO_CHAR(io_csv_rec.principal_4to5year)     || cv_sep_part ||                                             -- 4年超5年以内元本額
      TO_CHAR(io_csv_rec.interest_4to5year)      || cv_sep_part ||                                             -- 4年超5年以内支払利息
      TO_CHAR(io_csv_rec.tax_4to5year)           || cv_sep_part ||                                             -- 4年超5年以内消費税額
      TO_CHAR(io_csv_rec.principal_over_5year)   || cv_sep_part ||                                             -- 5年超元本額
      TO_CHAR(io_csv_rec.interest_over_5year)    || cv_sep_part ||                                             -- 5年超支払利息
      TO_CHAR(io_csv_rec.tax_over_5year)         || cv_sep_part ||                                             -- 5年超消費税額
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      TO_CHAR(io_csv_rec.deprn_reserve)          || cv_sep_part ||
--      TO_CHAR(io_csv_rec.bal_amount)             || cv_sep_part ||
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      TO_CHAR(io_csv_rec.interest_amount)        || cv_sep_part ||                                             -- 支払利息相当額
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      TO_CHAR(io_csv_rec.deprn_amount)           || cv_sep_part ||
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      TO_CHAR(io_csv_rec.monthly_deduction)      || cv_sep_part ||                                             -- 月間リース料（控除額）
      TO_CHAR(io_csv_rec.gross_deduction)        || cv_sep_part ||                                             -- リース料総額（控除額）
      TO_CHAR(io_csv_rec.deduction_this_month)   || cv_sep_part ||                                             -- 当期支払リース料（控除額）
      TO_CHAR(io_csv_rec.deduction_future)       || cv_sep_part ||                                             -- 未経過リース料（控除額）
      TO_CHAR(io_csv_rec.deduction_1year)        || cv_sep_part ||                                             -- 1年以内未経過リース料（控除額）
-- 2018/03/27 Ver.1.7 Y.Shoji MODL Start
--      TO_CHAR(io_csv_rec.deduction_over_1year)   ;
      TO_CHAR(io_csv_rec.deduction_over_1year)   || cv_sep_part ||                                             -- 1年超未経過リース料（控除額）
      cv_double_quat || io_csv_rec.disc_seg      || cv_double_quat || cv_sep_part ||                           -- 開示セグメント
      cv_double_quat || io_csv_rec.area          || cv_double_quat ;                                           -- 面積
-- 2018/03/27 Ver.1.7 Y.Shoji MODL End
    -- OUTファイルに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_csv_row
    );
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END out_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : get_pay_planning
   * Description      : リース支払計画情報取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_pay_planning(
    id_start_date_1st IN     DATE,         -- 1.期首開始日
    id_start_date_now IN     DATE,         -- 2.当期開始日
    io_csv_rec        IN OUT g_csv_rtype,  -- 3.CSV出力レコード
    ov_errbuf         OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_payment_planning'; -- プログラム名
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
    CURSOR planning_cur
    IS
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--      SELECT xpp.contract_header_id
      SELECT xpp.contract_line_id
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
-- 0000417 2009/07/17 ADD START --
          ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/17 ADD END --
-- 0000417 2009/07/17 MOD START --            
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                 (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/17 MOD END --
                    (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                      xpp.lease_charge
                     ELSE 0 END)
-- 0000417 2009/07/17 ADD START --
                  ELSE 0 END)
-- 0000417 2009/07/17 ADD END --
               ELSE 0 END) AS lease_charge_this_month   -- 当期支払リース料
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.lease_charge
                 ELSE 0 END) AS lease_charge_future       -- 未経過リース料
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.lease_charge
                    ELSE 0 END)
                 ELSE 0 END) AS lease_charge_1year        -- 1年以内未経過リース料
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.lease_charge
                 ELSE 0 END) AS lease_charge_over_1year   -- 1年越未経過リース料
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_debt
                   xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS lease_charge_debt         -- 未経過リース期末残高相当額
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_interest_due
                   xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS interest_future           -- 未経過リース支払利息額
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_future                -- 未経過リース消費税額
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1year           -- 1年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1year            -- 1年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1year                 -- 1年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_debt
                   xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS principal_over_1year      -- 1年越元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_interest_due
                   xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS interest_over_1year       -- 1年越支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_over_1year            -- 1年越消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1to2year        -- 1年超2年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1to2year         -- 1年超2年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1to2year              -- 1年超2年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_2to3year        -- 2年超3年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_2to3year         -- 2年超3年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_2to3year              -- 2年超3年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_3to4year        -- 3年超4年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_3to4year         -- 3年超4年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_3to4year              -- 3年超4年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_4to5year        -- 4年超5年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_4to5year         -- 4年超5年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_4to5year              -- 4年超5年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_debt
                   xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS principal_over_5year      -- 5年越元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_interest_due
                   xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS interest_over_5year       -- 5年越支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_over_5year            -- 5年越消費税
-- 0000417 2009/07/31 ADD START --
           ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/31 ADD END --
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                  (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/31 MOD END --
                     (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                        xpp.fin_interest_due
                        xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                      ELSE 0 END)
-- 0000417 2009/07/31 ADD START --
                   ELSE 0 END)
-- 0000417 2009/07/31 ADD END --
                ELSE 0 END) AS interest_amount           -- 支払利息相当額
-- 0000417 2009/07/31 ADD START --
           ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/31 ADD END --
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                  (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/31 MOD END --
                     (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                        xpp.lease_deduction
                      ELSE 0 END)
-- 0000417 2009/07/31 ADD START --
                   ELSE 0 END)
-- 0000417 2009/07/31 ADD END --
                ELSE 0 END) AS deduction_this_month      -- 当期支払リース料（控除額）
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.lease_deduction
                 ELSE 0 END) AS deduction_future          -- 未経過リース料（控除額）
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.lease_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS deduction_1year           -- 1年以内未経過リース料（控除額）
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.lease_deduction
                 ELSE 0 END) AS deduction_over_1year      -- 1年越未経過リース料（控除額）
        FROM xxcff_contract_lines xcl
            ,xxcff_pay_planning xpp
       WHERE xcl.contract_line_id = xpp.contract_line_id
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--         AND xcl.contract_header_id = io_csv_rec.contract_header_id
         AND xcl.contract_line_id = io_csv_rec.contract_line_id
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
-- 0000417 2009/07/17 MOD START --
--         AND NOT (xpp.period_name >= TO_CHAR(xcl.cancellation_date,'YYYY-MM') AND
         AND NOT (xpp.period_name > TO_CHAR(xcl.cancellation_date,'YYYY-MM') AND
-- 0000417 2009/07/17 MOD END --
                  xcl.cancellation_date IS NOT NULL)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--      GROUP BY xpp.contract_header_id
      GROUP BY xpp.contract_line_id
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
      ;
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
    <<planning_loop>>
    FOR l_rec IN planning_cur LOOP
      io_csv_rec.lease_charge_this_month := l_rec.lease_charge_this_month; -- 当期支払リース料
      io_csv_rec.lease_charge_future     := l_rec.lease_charge_future;     -- 未経過リース料
      io_csv_rec.lease_charge_1year      := l_rec.lease_charge_1year;      -- 1年以内未経過リース料
      io_csv_rec.lease_charge_over_1year := l_rec.lease_charge_over_1year; -- 1年越未経過リース料
      io_csv_rec.lease_charge_debt       := l_rec.lease_charge_debt;       -- 未経過リース期末残高相当額
      io_csv_rec.interest_future         := l_rec.interest_future;         -- 未経過リース支払利息額
      io_csv_rec.tax_future              := l_rec.tax_future;              -- 未経過リース消費税額
      io_csv_rec.principal_1year         := l_rec.principal_1year;         -- 1年以内元本
      io_csv_rec.interest_1year          := l_rec.interest_1year;          -- 1年以内支払利息
      io_csv_rec.tax_1year               := l_rec.tax_1year;               -- 1年以内消費税
      io_csv_rec.principal_over_1year    := l_rec.principal_over_1year;    -- 1年越元本
      io_csv_rec.interest_over_1year     := l_rec.interest_over_1year;     -- 1年越支払利息
      io_csv_rec.tax_over_1year          := l_rec.tax_over_1year;          -- 1年越消費税
      io_csv_rec.principal_1to2year      := l_rec.principal_1to2year;      -- 1年越2年以内元本
      io_csv_rec.interest_1to2year       := l_rec.interest_1to2year;       -- 1年越2年以内支払利息
      io_csv_rec.tax_1to2year            := l_rec.tax_1to2year;            -- 1年越2年以内消費税
      io_csv_rec.principal_2to3year      := l_rec.principal_2to3year;      -- 2年超3年以内元本
      io_csv_rec.interest_2to3year       := l_rec.interest_2to3year;       -- 2年超3年以内支払利息
      io_csv_rec.tax_2to3year            := l_rec.tax_2to3year;            -- 2年超3年以内消費税
      io_csv_rec.principal_3to4year      := l_rec.principal_3to4year;      -- 3年越4年以内元本
      io_csv_rec.interest_3to4year       := l_rec.interest_3to4year;       -- 3年越4年以内支払利息
      io_csv_rec.tax_3to4year            := l_rec.tax_3to4year;            -- 3年越4年以内消費税
      io_csv_rec.principal_4to5year      := l_rec.principal_4to5year;      -- 4年越5年以内元本
      io_csv_rec.interest_4to5year       := l_rec.interest_4to5year;       -- 4年越5年以内支払利息
      io_csv_rec.tax_4to5year            := l_rec.tax_4to5year;            -- 4年越5年以内消費税
      io_csv_rec.principal_over_5year    := l_rec.principal_over_5year;    -- 5年越元本
      io_csv_rec.interest_over_5year     := l_rec.interest_over_5year;     -- 5年越支払利息
      io_csv_rec.tax_over_5year          := l_rec.tax_over_5year;          -- 5年越消費税
      io_csv_rec.interest_amount         := l_rec.interest_amount;         -- 支払利息相当額
      io_csv_rec.deduction_this_month    := l_rec.deduction_this_month;    -- 当期支払リース料（控除額）
      io_csv_rec.deduction_future        := l_rec.deduction_future;        -- 未経過リース料（控除額）
      io_csv_rec.deduction_1year         := l_rec.deduction_1year;         -- 1年以内未経過リース料（控除額）
      io_csv_rec.deduction_over_1year    := l_rec.deduction_over_1year;    -- 1年越未経過リース料（控除額）
    END LOOP planning_loop;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END get_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_info
   * Description      : リース契約情報取得処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_contract_info(
    iv_lease_company   IN  VARCHAR2,  --  1.リース会社
    iv_lease_kind      IN  VARCHAR2,  --  2.リース種類
    id_start_date_1st  IN  DATE,      --  3.期首開始日
    id_start_date_now  IN  DATE,      --  4.当期開始日
    iv_book_type_code  IN  VARCHAR2,  --  5.資産台帳名
    in_fiscal_year     IN  NUMBER,    --  6.会計年度
    in_period_num_1st  IN  NUMBER,    --  7.期首期間番号
    in_period_num_now  IN  NUMBER,    --  8.当期期間番号
    iv_period_from     IN  VARCHAR2,  --  9.出力期間（自）
    iv_period_to       IN  VARCHAR2,  -- 10.出力期間（至）
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
    iv_lease_class     IN  VARCHAR2,  -- 11.リース種別
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_info'; -- プログラム名
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
    cv_lease_type1 CONSTANT VARCHAR2(1) := '1'; -- リース区分：原契約
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
-- 0000417 2009/08/05 DEL START --
/*
    CURSOR contract_cur
    IS
      SELECT xch.contract_header_id             -- 契約内部ID
            ,xch.lease_company                  -- リース会社コード
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- リース会社
            ,xch.contract_number                -- 契約No
            ,(SELECT xlsv.lease_class_name
                FROM xxcff_lease_class_v xlsv
               WHERE xlsv.lease_class_code = xch.lease_class
              ) AS lease_class_name             -- リース種別
            ,(SELECT xltv.lease_type_name
                FROM xxcff_lease_type_v xltv
               WHERE xltv.lease_type_code = xch.lease_type
              ) AS lease_type_name              -- リース区分
            ,xch.lease_start_date               -- リース開始日
            ,xch.lease_end_date                 -- リース終了日
            ,xch.payment_frequency              -- 月数
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.second_charge
                 ELSE 0 END) AS monthly_charge  -- 月間リース料
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_charge
                 ELSE 0 END) AS gross_charge    -- リース料総額
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
--                           xcl.expiration_date IS NULL   THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
-- 0000417 2009/07/31 MOD END --
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- 取得価額総額
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
--                           xcl.expiration_date IS NULL   THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
-- 0000417 2009/07/31 MOD END --
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
-- 0000417 2009/07/31 MOD START --
--                      fds.deprn_reserve
                      NVL(fds.deprn_reserve,xcl.original_cost)
-- 0000417 2009/07/31 MOD END --
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- 減価償却累計額相当額
            ,SUM(fds.deprn_amount) AS deprn_amount -- 減価償却相当額
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- 月間リース料（控除額）
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- リース料総額（控除額）
        FROM xxcff_contract_headers xch       -- リース契約
       INNER JOIN xxcff_contract_lines xcl    -- リース契約明細
          ON xcl.contract_header_id = xch.contract_header_id
       LEFT JOIN fa_additions_b fab           -- 資産詳細情報
          ON fab.attribute10 = xcl.contract_line_id
-- 0000417 2009/07/31 ADD START --
       LEFT JOIN fa_retirements fret  -- 除売却
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = iv_book_type_code
         AND fret.transaction_header_id_out IS NULL
-- 0000417 2009/07/31 ADD END --
       LEFT JOIN fa_deprn_periods fdp         -- 減価償却期間
          ON fdp.book_type_code = iv_book_type_code
       LEFT JOIN fa_deprn_summary fds         -- 減価償却サマリ
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_company = NVL(iv_lease_company,xch.lease_company)
         AND xch.lease_type = cv_lease_type1
         AND xcl.lease_kind = iv_lease_kind
         AND EXISTS (
             SELECT 'x' FROM xxcff_pay_planning xpp
              WHERE xpp.contract_line_id = xcl.contract_line_id
                AND xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM')
             )
         AND xcl.contract_status > cv_contr_st_201
         AND fdp.fiscal_year = in_fiscal_year
         AND fdp.period_num >= in_period_num_1st
         AND fdp.period_num <= in_period_num_now
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
              ,xch.contract_header_id
      ORDER BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_start_date
      ;
    contract_rec contract_cur%ROWTYPE;
*/
-- 0000417 2009/08/05 DEL END --
--
-- 0000417 2009/08/05 ADD START --
    --FIN、旧FINリース取得対象カーソル
    CURSOR contract_cur
    IS
      SELECT
-- 0001061 2009/08/28 ADD START --
             /*+
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--               INDEX(XCH XXCFF_CONTRACT_HEADERS_N04)
               LEADING(XCL)
               USE_NL(XCL XOH)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
               USE_NL(XCH XLCV)
               USE_NL(XCH XLSV)
               USE_NL(XCH XLTV)
               USE_NL(XCH XCL)
               USE_NL(XCL FAB)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--               INDEX(XCL XXCFF_CONTRACT_LINES_U01)
               INDEX(XCL XXCFF_CONTRACT_LINES_N01)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
               INDEX(FDP FA_DEPRN_PERIODS_U2)
               INDEX(FDS FA_DEPRN_SUMMARY_U1)
               INDEX(FRET FA_RETIREMENTS_N1)
             */
-- 0001061 2009/08/28 ADD END --
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--             xch.contract_header_id             -- 契約内部ID
             xcl.contract_line_id contract_line_id  -- 契約明細ID
            ,xoh.object_code      object_code       -- 物件コード
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
            ,xch.lease_company                  -- リース会社コード
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- リース会社
            ,xch.contract_number                -- 契約No
            ,(SELECT xlsv.lease_class_name
                FROM xxcff_lease_class_v xlsv
               WHERE xlsv.lease_class_code = xch.lease_class
              ) AS lease_class_name             -- リース種別
            ,(SELECT xltv.lease_type_name
                FROM xxcff_lease_type_v xltv
               WHERE xltv.lease_type_code = xch.lease_type
              ) AS lease_type_name              -- リース区分
            ,xch.lease_start_date               -- リース開始日
            ,xch.lease_end_date                 -- リース終了日
            ,xch.payment_frequency              -- 月数
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
                           fret.date_retired  >= id_start_date_1st OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.second_charge
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_charge  -- 月間リース料
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
                           fret.date_retired  >= id_start_date_1st OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.gross_charge
                    ELSE 0 END)
                 ELSE 0 END) AS gross_charge    -- リース料総額
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
--                           fret.status <> cv_processed   THEN
--                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
--                      xcl.original_cost
--                    ELSE 0 END)
--                 ELSE 0 END) AS original_cost   -- 取得価額総額
--            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
--                           fret.status <> cv_processed   THEN
--                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
--                      NVL(fds.deprn_reserve,original_cost)
--                    ELSE 0 END)
--                 ELSE 0 END) AS deprn_reserve   -- 減価償却累計額相当額
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
            ,SUM(fds.deprn_amount) AS deprn_amount -- 減価償却相当額
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
                           fret.date_retired  >= id_start_date_1st OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.second_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_deduction -- 月間リース料（控除額）
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
                           fret.date_retired  >= id_start_date_1st OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS gross_deduction -- リース料総額（控除額）
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
            ,xoh.cancellation_date cancellation_date   -- 解約日
            ,xch.lease_type        lease_type          -- リース区分
            ,xcl.original_cost     lease_original_cost -- 取得価額
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
        FROM xxcff_contract_headers xch       -- リース契約
       INNER JOIN xxcff_contract_lines xcl    -- リース契約明細
          ON xcl.contract_header_id = xch.contract_header_id
-- 0001061 2009/08/28 ADD START --
         AND xcl.lease_kind         = iv_lease_kind
         AND xcl.contract_status    > cv_contr_st_201
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
       INNER JOIN xxcff_object_headers xoh    -- リース物件
          ON xcl.object_header_id   = xoh.object_header_id
         AND (xoh.cancellation_date IS NULL
           OR xoh.cancellation_date >= id_start_date_1st)
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
-- 0001061 2009/08/28 ADD END --
       INNER JOIN fa_additions_b fab           -- 資産詳細情報
          ON fab.attribute10 = to_char(xcl.contract_line_id)
       LEFT JOIN fa_retirements fret  -- 除売却
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = iv_book_type_code
         AND fret.transaction_header_id_out IS NULL
       INNER JOIN fa_deprn_periods fdp         -- 減価償却期間
          ON fdp.book_type_code = iv_book_type_code
-- 0001061 2009/08/28 ADD START --
         AND fdp.fiscal_year = in_fiscal_year
         AND fdp.period_num >= in_period_num_1st
         AND fdp.period_num <= in_period_num_now
-- 0001061 2009/08/28 ADD END --
       LEFT JOIN fa_deprn_summary fds         -- 減価償却サマリ
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_company = NVL(iv_lease_company,xch.lease_company)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--         AND xch.lease_type = cv_lease_type1
         AND xch.lease_class   = NVL(iv_lease_class ,xch.lease_class)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
-- 0001061 2009/08/28 DEL START --
--         AND xcl.lease_kind = iv_lease_kind
--         AND xcl.contract_status > cv_contr_st_201
--         AND fdp.fiscal_year = in_fiscal_year
--         AND fdp.period_num >= in_period_num_1st
--         AND fdp.period_num <= in_period_num_now
-- 0001061 2009/08/28 DEL END --
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--              ,xch.contract_header_id
              ,xcl.contract_line_id
              ,xoh.object_code
              ,xch.lease_type
              ,xcl.original_cost
              ,xoh.cancellation_date
              ,fab.attribute12
              ,fab.attribute13
-- 2018/03/27 Ver.1.7 Y.Shoji MID End
      ORDER BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_start_date
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
              ,xoh.object_code
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ;
--
    --OPリース対象取得カーソル
    CURSOR contract_op_cur
    IS
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--      SELECT xch.contract_header_id             -- 契約内部ID
      SELECT /*+
                 LEADING(XCL)
                 USE_NL(XCL XCH)
                 USE_NL(XCL XOH)
                 USE_NL(XCL XPP)
                 INDEX(XCL XXCFF_CONTRACT_LINES_N01)
                 INDEX(XCH XXCFF_CONTRACT_HEADERS)
                 INDEX(XOH XXCFF_OBJECT_HEADERS)
              */
             xcl.contract_line_id               -- 契約明細ID
            ,xoh.object_code                    -- 物件コード
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
            ,xch.lease_company                  -- リース会社コード
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- リース会社
            ,xch.contract_number                -- 契約No
            ,(SELECT xlsv.lease_class_name
                FROM xxcff_lease_class_v xlsv
               WHERE xlsv.lease_class_code = xch.lease_class
              ) AS lease_class_name             -- リース種別
            ,(SELECT xltv.lease_type_name
                FROM xxcff_lease_type_v xltv
               WHERE xltv.lease_type_code = xch.lease_type
              ) AS lease_type_name              -- リース区分
            ,xch.lease_start_date               -- リース開始日
            ,xch.lease_end_date                 -- リース終了日
            ,xch.payment_frequency              -- 月数
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.second_charge
                 ELSE 0 END) AS monthly_charge  -- 月間リース料
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.gross_charge
                 ELSE 0 END) AS gross_charge    -- リース料総額
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--            ,NULL AS original_cost   -- 取得価額総額
--            ,NULL AS deprn_reserve   -- 減価償却累計額相当額
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
            ,NULL AS deprn_amount    -- 減価償却相当額
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- 月間リース料（控除額）
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- リース料総額（控除額）
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
            ,xcl.cancellation_date cancellation_date   -- 解約日
            ,xch.lease_type        lease_type          -- リース区分
            ,xcl.original_cost     lease_original_cost -- 取得価額
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
        FROM xxcff_contract_headers xch       -- リース契約
       INNER JOIN xxcff_contract_lines xcl    -- リース契約明細
          ON xcl.contract_header_id = xch.contract_header_id
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
       INNER JOIN xxcff_object_headers xoh    -- リース物件
          ON xcl.object_header_id  = xoh.object_header_id
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
       WHERE xch.lease_company = NVL(iv_lease_company,xch.lease_company)
         AND xch.lease_type = cv_lease_type1
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
         AND xch.lease_class   = NVL(iv_lease_class ,xch.lease_class)
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
         AND xcl.lease_kind = iv_lease_kind
         AND EXISTS (
             SELECT 'x' FROM xxcff_pay_planning xpp
              WHERE xpp.contract_line_id = xcl.contract_line_id
                AND xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM')
             )
         AND xcl.contract_status > cv_contr_st_201
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--              ,xch.contract_header_id
              ,xcl.contract_line_id
              ,xoh.object_code
              ,xch.lease_type
              ,xcl.original_cost
              ,xcl.cancellation_date
-- 2018/03/27 Ver.1.7 Y.Shoji MID End
      ORDER BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_start_date
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
              ,xoh.object_code
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ;
    contract_rec contract_cur%ROWTYPE;
-- 0000417 2009/08/05 ADD END --
--
    -- *** ローカル・レコード ***
    l_csv_rec  g_csv_rtype;
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
-- 0000417 2009/08/05 ADD START --
    -- リース種別がFINリース、旧FINリースの場合
    IF iv_lease_kind IN (cv_lease_kind_fin,cv_lease_kind_qfin) THEN
-- 0000417 2009/08/05 ADD END --
      OPEN contract_cur;
      <<main_loop>>
      LOOP
        FETCH contract_cur INTO contract_rec;
        EXIT WHEN contract_cur%NOTFOUND;
-- 0000417 2009/08/05 ADD START --
        IF (contract_rec.deprn_amount IS NOT NULL) THEN
-- 0000417 2009/08/05 ADD END --
          -- 対象件数インクリメント
          gn_target_cnt := gn_target_cnt + 1;
          -- 初期化
          l_csv_rec := NULL;
          -- 取得値を格納
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--          l_csv_rec.contract_header_id  := contract_rec.contract_header_id;
          l_csv_rec.contract_line_id    := contract_rec.contract_line_id;
          l_csv_rec.object_code         := contract_rec.object_code;
          l_csv_rec.lease_type          := contract_rec.lease_type;
          l_csv_rec.lease_original_cost := contract_rec.lease_original_cost;
          l_csv_rec.cancellation_date   := contract_rec.cancellation_date;
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
          l_csv_rec.lease_company       := contract_rec.lease_company;
          l_csv_rec.lease_company_name  := contract_rec.lease_company_name;
          l_csv_rec.period_from         := iv_period_from;
          l_csv_rec.period_to           := iv_period_to;
          l_csv_rec.contract_number     := contract_rec.contract_number;
          l_csv_rec.lease_class_name    := contract_rec.lease_class_name;
          l_csv_rec.lease_type_name     := contract_rec.lease_type_name;
          l_csv_rec.lease_start_date    := contract_rec.lease_start_date;
          l_csv_rec.lease_end_date      := contract_rec.lease_end_date;
          l_csv_rec.payment_frequency   := contract_rec.payment_frequency;
          l_csv_rec.monthly_charge      := contract_rec.monthly_charge;
          l_csv_rec.gross_charge        := contract_rec.gross_charge;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--          l_csv_rec.original_cost       := contract_rec.original_cost;
--          l_csv_rec.deprn_reserve       := contract_rec.deprn_reserve;
--          l_csv_rec.deprn_amount        := contract_rec.deprn_amount;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
          l_csv_rec.monthly_deduction   := contract_rec.monthly_deduction;
          l_csv_rec.gross_deduction     := contract_rec.gross_deduction;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--          l_csv_rec.bal_amount          := contract_rec.original_cost - contract_rec.deprn_reserve;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
          -- ============================================
          -- A-5．リース支払計画情報取得処理
          -- ============================================
          get_pay_planning(
             id_start_date_1st
            ,id_start_date_now
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
          -- ============================================
          -- A-8．リース資産情報取得処理
          -- ============================================
          get_asset_info(
             iv_book_type_code
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          -- ============================================
          -- A-9．リース債務情報取得処理
          -- ============================================
          get_lease_obl_info(
             l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
          -- ============================================
          -- A-6．CSVデータ出力処理
          -- ============================================
          out_csv_data(
             iv_lease_kind
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          -- 成功件数インクリメント
          gn_normal_cnt := gn_normal_cnt + 1;
-- 0000417 2009/08/05 ADD START --
        END IF;
-- 0000417 2009/08/05 ADD END --
      END LOOP main_loop;
-- 0000417 2009/08/05 ADD START --
      -- 対象件数が0件だった場合は警告終了
      IF (contract_cur%ROWCOUNT = 0) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name,cv_msg_no_data);
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
-- 0000417 2009/08/05 ADD END --
--
-- 0000417 2009/08/05 ADD START --
    IF iv_lease_kind = cv_lease_kind_op THEN
      OPEN contract_op_cur;
      <<main_loop2>>
      LOOP
        FETCH contract_op_cur INTO contract_rec;
        EXIT WHEN contract_op_cur%NOTFOUND;
          -- 対象件数インクリメント
          gn_target_cnt := gn_target_cnt + 1;
          -- 初期化
          l_csv_rec := NULL;
          -- 取得値を格納
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--          l_csv_rec.contract_header_id  := contract_rec.contract_header_id;
          l_csv_rec.contract_line_id    := contract_rec.contract_line_id;
          l_csv_rec.object_code         := contract_rec.object_code;
          l_csv_rec.cancellation_date   := contract_rec.cancellation_date;
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
          l_csv_rec.lease_company       := contract_rec.lease_company;
          l_csv_rec.lease_company_name  := contract_rec.lease_company_name;
          l_csv_rec.period_from         := iv_period_from;
          l_csv_rec.period_to           := iv_period_to;
          l_csv_rec.contract_number     := contract_rec.contract_number;
          l_csv_rec.lease_class_name    := contract_rec.lease_class_name;
          l_csv_rec.lease_type_name     := contract_rec.lease_type_name;
          l_csv_rec.lease_start_date    := contract_rec.lease_start_date;
          l_csv_rec.lease_end_date      := contract_rec.lease_end_date;
          l_csv_rec.payment_frequency   := contract_rec.payment_frequency;
          l_csv_rec.monthly_charge      := contract_rec.monthly_charge;
          l_csv_rec.gross_charge        := contract_rec.gross_charge;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--          l_csv_rec.original_cost       := contract_rec.original_cost;
--          l_csv_rec.deprn_reserve       := contract_rec.deprn_reserve;
--          l_csv_rec.deprn_amount        := contract_rec.deprn_amount;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
          l_csv_rec.monthly_deduction   := contract_rec.monthly_deduction;
          l_csv_rec.gross_deduction     := contract_rec.gross_deduction;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--          l_csv_rec.bal_amount          := contract_rec.original_cost - contract_rec.deprn_reserve;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
          -- ============================================
          -- A-5．リース支払計画情報取得処理
          -- ============================================
          get_pay_planning(
             id_start_date_1st
            ,id_start_date_now
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          -- ============================================
          -- A-6．CSVデータ出力処理
          -- ============================================
          out_csv_data(
             iv_lease_kind
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          -- 成功件数インクリメント
          gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP main_loop2;
      -- 対象件数が0件だった場合は警告終了
      IF (contract_op_cur%ROWCOUNT = 0) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name,cv_msg_no_data);
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
-- 0000417 2009/08/05 ADD END --
--
-- 0000417 2009/08/05 MOD START --
--    CLOSE contract_cur;
    IF (contract_cur%ISOPEN) THEN
      CLOSE contract_cur;
    END IF;
    IF (contract_op_cur%ISOPEN) THEN
      CLOSE contract_op_cur;
    END IF;
-- 0000417 2009/08/05 MOD END --
--
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
      -- エラー件数インクリメント
      gn_error_cnt := gn_error_cnt + 1;
      -- カーソルクローズ
      IF (contract_cur%ISOPEN) THEN
        CLOSE contract_cur;
      END IF;
-- 0000417 2009/08/05 ADD START --
      IF (contract_op_cur%ISOPEN) THEN
        CLOSE contract_op_cur;
      END IF;
-- 0000417 2009/08/05 ADD END --
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
  END get_contract_info;
--
  /**********************************************************************************
   * Procedure Name   : get_first_period
   * Description      : 会計期間期首取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_first_period(
    iv_lease_kind     IN  VARCHAR2,     -- 1.リース種類
    in_fiscal_year    IN  NUMBER,       -- 2.会計年度
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
    iv_book_type_code IN  VARCHAR2,     -- 3.資産台帳名
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
    ov_period_from    OUT VARCHAR2,     -- 4.出力期間（自）
    on_period_num_1st OUT NUMBER,       -- 5.期間番号
    od_start_date_1st OUT DATE,         -- 6.期首開始日
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_first_period'; -- プログラム名
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
    cn_period_num_1st CONSTANT NUMBER(1) := 1;  -- 期首期間番号
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR period_1st_cur
    IS
      SELECT fcp.period_name AS period_from    -- 出力期間（自）
            ,fcp.period_num  AS period_num     -- 期間番号
            ,fcp.start_date  AS start_date_1st -- 期首開始日
        FROM fa_calendar_periods fcp  -- 資産カレンダ
            ,fa_calendar_types fct    -- 資産カレンダタイプ
            ,fa_fiscal_year ffy       -- 資産会計年度
            ,fa_book_controls fbc     -- 資産台帳マスタ
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--            ,xxcff_lease_kind_v xlk   -- リース種類ビュー
--       WHERE fbc.book_type_code = xlk.book_type_code
--         AND xlk.lease_kind_code = iv_lease_kind
       WHERE fbc.book_type_code = iv_book_type_code
-- 2018/03/27 Ver.1.7 Y.Shoji MOD END
         AND fbc.deprn_calendar = fcp.calendar_type
         AND ffy.fiscal_year = in_fiscal_year
         AND ffy.fiscal_year_name = fct.fiscal_year_name
         AND fct.calendar_type = fcp.calendar_type
         AND fcp.start_date >= ffy.start_date
         AND fcp.end_date <= ffy.end_date
         AND fcp.period_num = cn_period_num_1st;
    period_1st_rec period_1st_cur%ROWTYPE;
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
    OPEN period_1st_cur;
    FETCH period_1st_cur INTO period_1st_rec;
    CLOSE period_1st_cur;
    -- 戻り値設定
    ov_period_from    := period_1st_rec.period_from;     -- 出力期間（自）
    on_period_num_1st := period_1st_rec.period_num;      -- 期間番号
    od_start_date_1st := period_1st_rec.start_date_1st;  -- 期首開始日
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END get_first_period;
--
  /**********************************************************************************
   * Procedure Name   : chk_period_name
   * Description      : 会計期間チェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE chk_period_name(
    iv_period_name    IN  VARCHAR2,     -- 1.会計期間名
    iv_lease_kind     IN  VARCHAR2,     -- 2.リース種類
    iv_book_class     IN  VARCHAR2,     -- 3.資産台帳区分
    on_fiscal_year    OUT NUMBER,       -- 4.会計年度
    ov_period_to      OUT VARCHAR2,     -- 5.出力期間（至）
    on_period_num_now OUT NUMBER,       -- 6.期間番号
    od_start_date_now OUT DATE,         -- 7.当期開始日
    ov_book_type_code OUT VARCHAR2,     -- 8.資産台帳名
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_name'; -- プログラム名
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
    lt_book_type_code  fa_book_controls.book_type_code%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR period_cur(
      iv_book_type_code_c VARCHAR2
    )IS
      SELECT fdp.deprn_run   AS deprn_run      -- 減価償却実行フラグ
            ,fdp.fiscal_year AS fiscal_year    -- 会計期間
            ,fdp.period_name AS period_to      -- 出力期間（至）
            ,fdp.period_num  AS period_num     -- 期間番号
            ,fcp.start_date  AS start_date_now -- 当期開始日
        FROM fa_deprn_periods fdp     -- 減価償却期間
            ,fa_calendar_periods fcp  -- 資産カレンダ
            ,fa_book_controls fbc     -- 資産台帳マスタ
       WHERE fbc.book_type_code = iv_book_type_code_c
         AND fdp.period_name = iv_period_name
         AND fdp.book_type_code = fbc.book_type_code
         AND fbc.deprn_calendar = fcp.calendar_type
         AND fdp.period_name = fcp.period_name;
    period_rec period_cur%ROWTYPE;
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
    -- 資産台帳名取得
    SELECT (CASE iv_book_class
            WHEN cv_book_class_1 THEN xlk.book_type_code
            WHEN cv_book_class_2 THEN xlk.book_type_code_tax
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
            WHEN cv_book_class_3 THEN xlk.book_type_code_ifrs
-- 2018/03/27 Ver.1.7 Y.Shoji ADD END
            ELSE NULL END)
      INTO lt_book_type_code
      FROM xxcff_lease_kind_v xlk
     WHERE xlk.lease_kind_code = iv_lease_kind;
    -- 減価償却期間情報取得
    OPEN period_cur(
      lt_book_type_code
    );
    FETCH period_cur INTO period_rec;
    CLOSE period_cur;
    IF (NVL(period_rec.deprn_run,'N') != 'Y') THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name,cv_msg_close
                     ,cv_tkn_book_type,lt_book_type_code
                     ,cv_tkn_period_name,iv_period_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- 戻り値設定
    on_fiscal_year    := period_rec.fiscal_year;      -- 会計年度
    ov_period_to      := period_rec.period_to;        -- 出力期間（至）
    on_period_num_now := period_rec.period_num;       -- 期間番号
    od_start_date_now := period_rec.start_date_now;   -- 当期開始日
    ov_book_type_code := lt_book_type_code;           -- 資産台帳名
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 共通処理例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END chk_period_name;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    xxcff_common1_pkg.put_log_param(
       iv_which    => cv_which     -- 出力区分
      ,ov_retcode  => lv_retcode   --リターンコード
      ,ov_errbuf   => lv_errbuf    --エラーメッセージ
      ,ov_errmsg   => lv_errmsg    --ユーザー・エラーメッセージ
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name   IN    VARCHAR2,        -- 1.会計期間名
    iv_lease_kind    IN    VARCHAR2,        -- 2.リース種類
    iv_book_class    IN    VARCHAR2,        -- 3.資産台帳区分
    iv_lease_company IN    VARCHAR2,        -- 4.リース会社コード
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
    iv_lease_class   IN    VARCHAR2,        -- 5.リース種別
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
    ov_errbuf        OUT   VARCHAR2,        --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT   VARCHAR2,        --   リターン・コード             --# 固定 #
    ov_errmsg        OUT   VARCHAR2)        --   ユーザー・エラー・メッセージ --# 固定 #
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
    lt_book_type_code fa_book_controls.book_type_code%TYPE;  -- 資産台帳名
    lt_fiscal_year    fa_deprn_periods.fiscal_year%TYPE;     -- 会計年度
    lt_period_from    fa_deprn_periods.period_name%TYPE;     -- 出力期間（自）
    lt_period_to      fa_deprn_periods.period_name%TYPE;     -- 出力期間（至）
    lt_period_num_1st fa_deprn_periods.period_num%TYPE;      -- 期首期間番号
    lt_period_num_now fa_deprn_periods.period_num%TYPE;      -- 当期期間番号
    ld_start_date_1st DATE;                                  -- 期首開始日
    ld_start_date_now DATE;                                  -- 当期開始日
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--    CURSOR <cursor_name>_cur
--    IS
--      SELECT
--      FROM
--      WHERE
--    -- <カーソル名>レコード型
--    <cursor_name>_rec <cursor_name>_cur%ROWTYPE;
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
    -- ============================================
    -- A-1．入力パラメータ値ログ出力処理
    -- ============================================
    init(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
    -- リース会社とリース種別がNULLの場合
    IF (  iv_lease_company IS NULL
      AND iv_lease_class   IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                              cv_appl_short_name
                                             ,cv_msg_req_chk       -- 必須チェックエラー
                                             ,cv_tkn_input_dta
                                             ,cv_tkv_com_or_cla    -- リース会社、リース種別
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
    -- ============================================
    -- A-2．会計期間チェック処理
    -- ============================================
    chk_period_name(
       iv_period_name         -- 1.会計期間名
      ,iv_lease_kind          -- 2.リース種類
      ,iv_book_class          -- 3.資産台帳区分
      ,lt_fiscal_year         -- 4.会計年度
      ,lt_period_to           -- 5.出力期間（至）
      ,lt_period_num_now      -- 6.期間番号
      ,ld_start_date_now      -- 7.当期開始日
      ,lt_book_type_code      -- 8.資産台帳名
      ,lv_errbuf              --   エラー・メッセージ           --# 固定 #
      ,lv_retcode             --   リターン・コード             --# 固定 #
      ,lv_errmsg              --   ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．会計期間期首取得処理
    -- ============================================
    get_first_period(
       iv_lease_kind          -- 1.リース種類
      ,lt_fiscal_year         -- 2.会計年度
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      ,lt_book_type_code      -- 3.資産台帳名
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ,lt_period_from         -- 4.出力期間（自）
      ,lt_period_num_1st      -- 5.期間番号
      ,ld_start_date_1st      -- 6.期首開始日
      ,lv_errbuf              --   エラー・メッセージ           --# 固定 #
      ,lv_retcode             --   リターン・コード             --# 固定 #
      ,lv_errmsg              --   ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4．リース契約情報取得処理
    -- ============================================
    get_contract_info(
       iv_lease_company     --  1.リース会社
      ,iv_lease_kind        --  2.リース種類
      ,ld_start_date_1st    --  3.期首開始日
      ,ld_start_date_now    --  4.当期開始日
      ,lt_book_type_code    --  5.資産台帳名
      ,lt_fiscal_year       --  6.会計年度
      ,lt_period_num_1st    --  7.期首期間番号
      ,lt_period_num_now    --  8.当期期間番号
      ,lt_period_from       --  9.出力期間（自）
      ,lt_period_to         -- 10.出力期間（至）
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      ,iv_lease_class       -- 11.リース種別
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ,lv_errbuf            --   エラー・メッセージ           --# 固定 #
      ,lv_retcode           --   リターン・コード             --# 固定 #
      ,lv_errmsg            --   ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告処理
      --submainの終了ステータス(ov_retcode)のセットや
      --エラーメッセージをセットするロジックなどを記述して下さい。
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
    errbuf           OUT   VARCHAR2,        --   エラー・メッセージ  --# 固定 #
    retcode          OUT   VARCHAR2,        --   リターン・コード    --# 固定 #
    iv_period_name   IN    VARCHAR2,        -- 1.会計期間名
    iv_lease_kind    IN    VARCHAR2,        -- 2.リース種類
    iv_book_class    IN    VARCHAR2,        -- 3.資産台帳区分
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--    iv_lease_company IN    VARCHAR2         -- 4.リース会社コード
    iv_lease_company IN    VARCHAR2,        -- 4.リース会社コード
    iv_lease_class   IN    VARCHAR2         -- 5.リース種別
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
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
      ,iv_which   => cv_which
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
       iv_period_name   -- 1.会計期間名
      ,iv_lease_kind    -- 2.リース種類
      ,iv_book_class    -- 3.資産台帳区分
      ,iv_lease_company -- 4.リース会社コード
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      ,iv_lease_class   -- 5.リース種別
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ============================================
    -- A-7．終了処理
    -- ============================================
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
    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
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
END XXCFF011A17C;
/
