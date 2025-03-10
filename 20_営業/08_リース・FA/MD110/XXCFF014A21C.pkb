CREATE OR REPLACE PACKAGE BODY XXCFF014A21C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF014A21C(body)
 * Description      : 別表16(4)リース資産
 * MD.050           : 別表16(4)リース資産 MD050_CFF_014_A21
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   入力パラメータ値ログ出力処理(A-1)
 *  get_period_name        会計期間情報取得処理(A-2)
 *  get_first_period       会計期間期首取得処理(A-3)
 *  get_contract_info      リース契約情報取得処理(A-4)
 *  get_pay_planning       リース支払計画情報取得処理(A-5)
 *  out_csv_data           CSVデータ出力処理(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.0   SCS山岸          新規作成
 *  2009/02/26    1.1   SCS山岸          [障害CFF_064] 解約時資産簿価の不具合対応
 *  2009/07/17    1.2   SCS萱原          [統合テスト障害0000417] 支払計画の当期支払リース料取得処理修正
 *  2009/07/31    1.3   SCS渡辺          [統合テスト障害0000417(追加)]
 *                                         ・取得価額、減価償却累計額の取得条件を修正
 *                                         ・支払利息相当額、当期支払リース料（控除額）の取得条件修正
 *                                         ・未経過リース期末残高相当額、未経過リース消費税額、
 *                                           解約時リース債務残高の取得方法修正
 *  2009/08/28    1.4   SCS 渡辺         [統合テスト障害0001062(PT対応)]
 *  2012/01/31    1.5   SCSK 中村        [E_本稼動_08123] リース解約日設定許可に伴うリース債務残高集計条件の修正
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
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF014A21C'; -- パッケージ名
  cv_appl_short_name  CONSTANT VARCHAR2(100) := 'XXCFF';        -- アプリケーション短縮名
  cv_which            CONSTANT VARCHAR2(100) := 'LOG';          -- コンカレントログ出力先
  -- メッセージ
  cv_msg_no_data      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062'; -- 対象データ無し
  -- リース種類
-- 2012/01/31 Ver.1.5 K.Nakamura DEL Start
-- 使用していないため削除
--  cv_lease_kind_fin   CONSTANT VARCHAR2(1)   := '0';  -- Finリース
--  cv_lease_kind_op    CONSTANT VARCHAR2(1)   := '1';  -- Opリース
-- 2012/01/31 Ver.1.5 K.Nakamura DEL End
  cv_lease_kind_qfin  CONSTANT VARCHAR2(1)   := '2';  -- 旧Finリース
-- 0000417 2009/07/31 ADD START --
  -- 除売却ステータス
  cv_processed        CONSTANT VARCHAR2(9)   := 'PROCESSED'; --処理済
  -- 会計IFフラグステータス
  cv_if_aft           CONSTANT VARCHAR2(1)   := '2'; --連携済
  -- 照合済フラグ
  cv_match   CONSTANT VARCHAR2(1)            := '1'; --照合済
-- 0000417 2009/07/31 ADD END --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_csv_rtype IS RECORD (
     contract_header_id      xxcff_contract_headers.contract_header_id%TYPE
    ,contract_line_id        xxcff_contract_lines.contract_line_id%TYPE
    ,lease_company           xxcff_contract_headers.lease_company%TYPE -- リース会社コード
    ,lease_company_name      VARCHAR2(240) -- リース会社名
    ,period_from             VARCHAR2(10) -- 出力期間（自）
    ,period_to               VARCHAR2(10) -- 出力期間（至）
    ,contract_number         xxcff_contract_headers.contract_number%TYPE -- 契約No
    ,contract_line_num       xxcff_contract_lines.contract_line_num%TYPE -- 契約明細No
    ,object_code             xxcff_object_headers.object_code%TYPE       -- 物件コード
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
    ,original_cost           NUMBER(15) -- 取得価額相当額
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
    ,deprn_reserve           NUMBER(15) -- 減価償却累計額相当額 
    ,bal_amount              NUMBER(15) -- 期末残高相当額
    ,interest_amount         NUMBER(15) -- 支払利息相当額
    ,deprn_amount            NUMBER(15) -- 減価償却相当額
    ,monthly_deduction       NUMBER(15) -- 月間リース料（控除額）
    ,gross_deduction         NUMBER(15) -- リース料総額（控除額）
    ,deduction_this_month    NUMBER(15) -- 当期支払リース料（控除額）
    ,deduction_future        NUMBER(15) -- 未経過リース料（控除額）
    ,deduction_1year         NUMBER(15) -- 1年以内未経過リース料（控除額）
    ,deduction_over_1year    NUMBER(15) -- 1年越未経過リース料（控除額）
    ,cancellation_date       xxcff_contract_lines.cancellation_date%TYPE -- 解約日
    ,cxl_amount              NUMBER(15) -- 解約時資産簿価
    ,cxl_debt_bal            NUMBER(15) -- 解約時リース債務残高
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : out_csv_data
   * Description      : CSVデータ出力処理(A-6)
   ***********************************************************************************/
  PROCEDURE out_csv_data(
    io_csv_rec    IN OUT g_csv_rtype,  -- 1.CSV出力レコード
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
         AND flv.attribute2 = cv_flag_y
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
    -- 解約時資産簿価
-- 2012/01/31 Ver.1.5 K.Nakamura MOD Start
--    IF io_csv_rec.cancellation_date IS NULL THEN
    -- 指定した会計期間時点で解約されていない場合（解約日がNULLまたは、解約日が指定した会計期間の翌月月初以降）
    --   解約日をNULL、解約時資産簿価および解約時リース債務残高を0で出力
    IF ( ( io_csv_rec.cancellation_date IS NULL )
      OR ( io_csv_rec.cancellation_date >= LAST_DAY(TO_DATE(io_csv_rec.period_to, 'YYYY-MM')) + 1 ) ) THEN
      io_csv_rec.cancellation_date := NULL;
      io_csv_rec.cxl_debt_bal      := 0;
-- 2012/01/31 Ver.1.5 K.Nakamura MOD End
      io_csv_rec.cxl_amount := 0;
    END IF;
    -- CSVデータ編集
    lv_csv_row := 
      cv_double_quat || io_csv_rec.lease_company         || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.lease_company_name    || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.period_from           || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.period_to             || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.contract_number       || cv_double_quat || cv_sep_part ||
      TO_CHAR(io_csv_rec.contract_line_num)      || cv_sep_part ||
      cv_double_quat || io_csv_rec.object_code           || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.lease_class_name      || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.lease_type_name       || cv_double_quat || cv_sep_part ||
      cv_double_quat || TO_CHAR(io_csv_rec.lease_start_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||
      cv_double_quat || TO_CHAR(io_csv_rec.lease_end_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||
      TO_CHAR(io_csv_rec.payment_frequency)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.monthly_charge)         || cv_sep_part ||
      TO_CHAR(io_csv_rec.gross_charge)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_this_month)|| cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_future)    || cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_1year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_over_1year)|| cv_sep_part ||
      TO_CHAR(io_csv_rec.original_cost)          || cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_debt)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_future)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_future)             || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_1year)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_1year)         || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_1year)              || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_over_1year)   || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_over_1year)    || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_over_1year)         || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_1to2year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_1to2year)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_1to2year)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_2to3year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_2to3year)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_2to3year)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_3to4year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_3to4year)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_3to4year)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_4to5year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_4to5year)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_4to5year)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_over_5year)   || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_over_5year)    || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_over_5year)         || cv_sep_part ||
      TO_CHAR(io_csv_rec.deprn_reserve)          || cv_sep_part ||
      TO_CHAR(io_csv_rec.bal_amount)             || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_amount)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.deprn_amount)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.monthly_deduction)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.gross_deduction)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.deduction_this_month)   || cv_sep_part ||
      TO_CHAR(io_csv_rec.deduction_future)       || cv_sep_part ||
      TO_CHAR(io_csv_rec.deduction_1year)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.deduction_over_1year)   || cv_sep_part ||
      cv_double_quat || TO_CHAR(io_csv_rec.cancellation_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||
      TO_CHAR(io_csv_rec.cxl_amount)             || cv_sep_part ||
      TO_CHAR(io_csv_rec.cxl_debt_bal)
      ;
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
-- 2012/01/31 Ver.1.5 K.Nakamura ADD Start
    iv_period_name    IN     VARCHAR2,     --   会計期間名
-- 2012/01/31 Ver.1.5 K.Nakamura ADD End
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
      SELECT xpp.contract_header_id
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
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name = TO_CHAR(id_start_date_now,'YYYY-MM') THEN
--                   xpp.fin_debt_rem
--                 ELSE 0 END) AS lease_charge_debt         -- 未経過リース期末残高相当額
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS lease_charge_debt         -- 未経過リース期末残高相当額
-- 0000417 2009/07/31 MOD END --
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_interest_due
                 ELSE 0 END) AS interest_future           -- 未経過リース支払利息額
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name = TO_CHAR(id_start_date_now,'YYYY-MM') THEN
--                   xpp.fin_tax_debt_rem
--                 ELSE 0 END) AS tax_future                -- 未経過リース消費税額
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_future                -- 未経過リース消費税額
-- 0000417 2009/07/31 MOD END --
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1year           -- 1年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1year            -- 1年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1year                 -- 1年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS principal_over_1year      -- 1年越元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.fin_interest_due
                 ELSE 0 END) AS interest_over_1year       -- 1年越支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_over_1year            -- 1年越消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1to2year        -- 1年超2年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1to2year         -- 1年超2年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1to2year              -- 1年超2年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_2to3year        -- 2年超3年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_2to3year         -- 2年超3年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_2to3year              -- 2年超3年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_3to4year        -- 3年超4年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_3to4year         -- 3年超4年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_3to4year              -- 3年超4年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_4to5year        -- 4年超5年以内元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_4to5year         -- 4年超5年以内支払利息
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_4to5year              -- 4年超5年以内消費税
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS principal_over_5year      -- 5年越元本
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_interest_due
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
                         xpp.fin_interest_due
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
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name = TO_CHAR(ADD_MONTHS(io_csv_rec.cancellation_date,-1),'YYYY-MM') THEN
--                   xpp.fin_debt_rem
--                 ELSE 0 END) AS cxl_debt_bal              -- 解約時リース債務残高
            ,SUM(CASE WHEN xpp.period_name = TO_CHAR(io_csv_rec.cancellation_date,'YYYY-MM') THEN
                   (CASE WHEN xpp.payment_match_flag = cv_match THEN
                      xpp.fin_debt_rem
                    ELSE
                      xpp.fin_debt_rem + xpp.fin_debt
                    END)
                 ELSE 0 END) AS cxl_debt_bal              -- 解約時リース債務残高
-- 0000417 2009/07/31 MOD END --
        FROM xxcff_pay_planning xpp
       WHERE xpp.contract_line_id = io_csv_rec.contract_line_id
         AND xpp.contract_header_id = io_csv_rec.contract_header_id
-- 0000417 2009/07/17 MOD START --
--         AND NOT (xpp.period_name >= TO_CHAR(io_csv_rec.cancellation_date,'YYYY-MM') AND
         AND NOT (xpp.period_name > TO_CHAR(io_csv_rec.cancellation_date,'YYYY-MM') AND
-- 0000417 2009/07/17 MOD END --
-- 2012/01/31 Ver.1.5 K.Nakamura ADD Start
                  io_csv_rec.cancellation_date < LAST_DAY(TO_DATE(iv_period_name, 'YYYY-MM')) + 1 AND
-- 2012/01/31 Ver.1.5 K.Nakamura ADD End
                  io_csv_rec.cancellation_date IS NOT NULL)
      GROUP BY xpp.contract_header_id
              ,xpp.contract_line_id
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
      io_csv_rec.cxl_debt_bal            := l_rec.cxl_debt_bal;            -- 解約時リース債務残高
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
    iv_book_type_code  IN  VARCHAR2,  --  1.資産台帳名
    id_start_date_1st  IN  DATE,      --  2.期首開始日
    id_start_date_now  IN  DATE,      --  3.当期開始日
    in_fiscal_year     IN  NUMBER,    --  4.会計年度
    in_period_num_1st  IN  NUMBER,    --  5.期首期間番号
    in_period_num_now  IN  NUMBER,    --  6.当期期間番号
    iv_period_from     IN  VARCHAR2,  --  7.出力期間（自）
    iv_period_to       IN  VARCHAR2,  --  8.出力期間（至）
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
    cd_contract_date_fr CONSTANT DATE   := TO_DATE('2008/04/01','YYYY/MM/DD');
    cd_contract_date_to CONSTANT DATE   := TO_DATE('2008/05/01','YYYY/MM/DD');
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
-- 0000417 2009/08/06 DEL START --
/*
    CURSOR contract_cur
    IS
      SELECT xch.contract_header_id             -- 契約内部ID
            ,xcl.contract_line_id               -- 契約明細内部ID
            ,xch.lease_company                  -- リース会社コード
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- リース会社
            ,xch.contract_number                -- 契約No
            ,xcl.contract_line_num              -- 契約明細No
            ,xoh.object_code                    -- 物件コード
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
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
-- 0000417 2009/07/31 MOD END --
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- 取得価額総額
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
-- 0000417 2009/07/31 MOD END --
-- 0000417 2009/07/31 MOD START --
--                      fds.deprn_reserve
                      NVL(fds.deprn_reserve,xcl.original_cost)
-- 0000417 2009/07/31 MOD END --
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- 減価償却累計額相当額
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_from) >= iv_period_from THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) <= iv_period_to THEN
                      fds.deprn_amount
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_amount    -- 減価償却相当額
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- 月間リース料（控除額）
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- リース料総額（控除額）
            ,xcl.cancellation_date              -- 中途解約日
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.original_cost
                 ELSE 0 END) - SUM(fds.deprn_amount) AS cxl_amount -- 解約時資産簿価
        FROM xxcff_contract_headers xch       -- リース契約
       INNER JOIN xxcff_contract_lines xcl    -- リース契約明細
          ON xcl.contract_header_id = xch.contract_header_id
       INNER JOIN xxcff_object_headers xoh    -- リース物件
          ON xcl.object_header_id = xoh.object_header_id
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
       WHERE xch.lease_type = cv_lease_type1
         AND xcl.lease_kind = cv_lease_kind_qfin
         AND xch.contract_date >= cd_contract_date_fr
         AND xch.contract_date <  cd_contract_date_to
         AND xcl.contract_line_id = fab.attribute10
         AND fdp.period_name <= iv_period_to
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xcl.contract_line_num
              ,xoh.object_code
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
              ,xcl.cancellation_date
              ,xch.contract_header_id
              ,xcl.contract_line_id
      ORDER BY xcl.cancellation_date DESC
              ,xch.lease_company
              ,xch.contract_number
              ,xcl.contract_line_num
              ,xch.lease_start_date
      ;
*/
-- 0000417 2009/08/06 DEL END --
--
-- 0000417 2009/08/06 ADD START --
    CURSOR contract_cur
    IS
      SELECT 
-- 0001062 2009/08/28 ADD START --
            /*+
              INDEX(XCL XXCFF_CONTRACT_LINES_U01)
              INDEX(FDP FA_DEPRN_PERIODS_U2)
              INDEX(FDS FA_DEPRN_SUMMARY_U1)
              INDEX(FRET FA_RETIREMENTS_N1)
            */
-- 0001062 2009/08/28 ADD END --
             xch.contract_header_id             -- 契約内部ID
            ,xcl.contract_line_id               -- 契約明細内部ID
            ,xch.lease_company                  -- リース会社コード
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- リース会社
            ,xch.contract_number                -- 契約No
            ,xcl.contract_line_num              -- 契約明細No
            ,xoh.object_code                    -- 物件コード
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
-- 2012/01/31 Ver.1.5 K.Nakamura ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.second_charge
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_charge  -- 月間リース料
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.gross_charge
                    ELSE 0 END)
                 ELSE 0 END) AS gross_charge    -- リース料総額
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- 取得価額総額
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      NVL(fds.deprn_reserve,original_cost)
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- 減価償却累計額相当額
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_from) >= iv_period_from THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) <= iv_period_to THEN
                      fds.deprn_amount
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_amount    -- 減価償却相当額
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.second_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_deduction -- 月間リース料（控除額）
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD Start
                           (xcl.cancellation_date IS NULL) OR
                           (xcl.cancellation_date >= LAST_DAY(TO_DATE(iv_period_to, 'YYYY-MM')) + 1) OR
-- 2012/01/31 Ver.1.5 K.Nakamura ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS gross_deduction -- リース料総額（控除額）
            ,xcl.cancellation_date              -- 中途解約日
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.original_cost
                 ELSE 0 END) - SUM(fds.deprn_amount) AS cxl_amount -- 解約時資産簿価
        FROM xxcff_contract_headers xch       -- リース契約
       INNER JOIN xxcff_contract_lines xcl    -- リース契約明細
          ON xcl.contract_header_id = xch.contract_header_id
-- 0001062 2009/08/28 ADD START --
         AND xcl.lease_kind         = cv_lease_kind_qfin
-- 0001062 2009/08/28 ADD END --
       INNER JOIN xxcff_object_headers xoh    -- リース物件
          ON xcl.object_header_id = xoh.object_header_id
       INNER JOIN fa_additions_b fab           -- 資産詳細情報
-- 0001062 2009/08/28 MOD START --
--          ON fab.attribute10 = xcl.contract_line_id
          ON fab.attribute10 = to_char(XCL.CONTRACT_LINE_ID)
-- 0001062 2009/08/28 MOD END --
       LEFT JOIN fa_retirements fret  -- 除売却
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = iv_book_type_code
         AND fret.transaction_header_id_out IS NULL
       INNER JOIN fa_deprn_periods fdp         -- 減価償却期間
          ON fdp.book_type_code = iv_book_type_code
-- 0001062 2009/08/28 ADD START --
         AND fdp.period_name <= iv_period_to
-- 0001062 2009/08/28 ADD END --
       LEFT JOIN fa_deprn_summary fds         -- 減価償却サマリ
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_type = cv_lease_type1
-- 0001062 2009/08/28 DEL START --
--         AND xcl.lease_kind = cv_lease_kind_qfin
-- 0001062 2009/08/28 DEL END --
         AND xch.contract_date >= cd_contract_date_fr
         AND xch.contract_date <  cd_contract_date_to
-- 0001062 2009/08/28 DEL START --
--         AND xcl.contract_line_id = fab.attribute10
--         AND fdp.period_name <= iv_period_to
-- 0001062 2009/08/28 DEL END --
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xcl.contract_line_num
              ,xoh.object_code
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
              ,xcl.cancellation_date
              ,xch.contract_header_id
              ,xcl.contract_line_id
      ORDER BY xcl.cancellation_date DESC
              ,xch.lease_company
              ,xch.contract_number
              ,xcl.contract_line_num
              ,xch.lease_start_date
      ;
-- 0000417 2009/08/06 ADD START --
--
    contract_rec contract_cur%ROWTYPE;
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
    OPEN contract_cur;
    <<main_loop>>
    LOOP
      FETCH contract_cur INTO contract_rec;
      EXIT WHEN contract_cur%NOTFOUND;
      -- 対象件数インクリメント
      gn_target_cnt := gn_target_cnt + 1;
      -- 初期化
      l_csv_rec := NULL;
      -- 取得値を格納
      l_csv_rec.contract_header_id  := contract_rec.contract_header_id;
      l_csv_rec.contract_line_id    := contract_rec.contract_line_id;
      l_csv_rec.lease_company       := contract_rec.lease_company;
      l_csv_rec.lease_company_name  := contract_rec.lease_company_name;
      l_csv_rec.period_from         := iv_period_from;
      l_csv_rec.period_to           := iv_period_to;
      l_csv_rec.contract_number     := contract_rec.contract_number;
      l_csv_rec.contract_line_num   := contract_rec.contract_line_num;
      l_csv_rec.object_code         := contract_rec.object_code;
      l_csv_rec.lease_class_name    := contract_rec.lease_class_name;
      l_csv_rec.lease_type_name     := contract_rec.lease_type_name;
      l_csv_rec.lease_start_date    := contract_rec.lease_start_date;
      l_csv_rec.lease_end_date      := contract_rec.lease_end_date;
      l_csv_rec.payment_frequency   := contract_rec.payment_frequency;
      l_csv_rec.monthly_charge      := contract_rec.monthly_charge;
      l_csv_rec.gross_charge        := contract_rec.gross_charge;
      l_csv_rec.original_cost       := contract_rec.original_cost;
      l_csv_rec.deprn_reserve       := contract_rec.deprn_reserve;
      l_csv_rec.deprn_amount        := contract_rec.deprn_amount;
      l_csv_rec.monthly_deduction   := contract_rec.monthly_deduction;
      l_csv_rec.gross_deduction     := contract_rec.gross_deduction;
      l_csv_rec.bal_amount          := contract_rec.original_cost - contract_rec.deprn_reserve;
      l_csv_rec.cancellation_date   := contract_rec.cancellation_date;
      l_csv_rec.cxl_amount          := contract_rec.cxl_amount;
      -- ============================================
      -- A-5．リース支払計画情報取得処理
      -- ============================================
      get_pay_planning(
         id_start_date_1st
        ,id_start_date_now
-- 2012/01/31 Ver.1.5 K.Nakamura ADD Start
        ,iv_period_to
-- 2012/01/31 Ver.1.5 K.Nakamura ADD End
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
         l_csv_rec
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg);
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- 成功件数インクリメント
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP main_loop;
    -- 対象件数が0件だった場合は警告終了
    IF (contract_cur%ROWCOUNT = 0) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name,cv_msg_no_data);
      ov_retcode := cv_status_warn;
    END IF;
    CLOSE contract_cur;
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
    in_fiscal_year    IN  NUMBER,       -- 1.会計年度
    ov_period_from    OUT VARCHAR2,     -- 2.出力期間（自）
    on_period_num_1st OUT NUMBER,       -- 3.期間番号
    od_start_date_1st OUT DATE,         -- 4.期首開始日
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
            ,xxcff_lease_kind_v xlk   -- リース種類ビュー
       WHERE fbc.book_type_code = xlk.book_type_code
         AND xlk.lease_kind_code = cv_lease_kind_qfin
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
   * Procedure Name   : get_period_name
   * Description      : 会計期間情報取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_period_name(
    iv_period_name    IN  VARCHAR2,     -- 1.会計期間名
    on_fiscal_year    OUT NUMBER,       -- 2.会計年度
    ov_period_to      OUT VARCHAR2,     -- 3.出力期間（至）
    on_period_num_now OUT NUMBER,       -- 4.期間番号
    od_start_date_now OUT DATE,         -- 5.当期開始日
    ov_book_type_code OUT VARCHAR2,     -- 6.資産台帳名
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_period_name'; -- プログラム名
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
    CURSOR period_cur
    IS
      SELECT fdp.fiscal_year AS fiscal_year    -- 会計期間
            ,fdp.period_name AS period_to      -- 出力期間（至）
            ,fdp.period_num  AS period_num     -- 期間番号
            ,fcp.start_date  AS start_date_now -- 当期開始日
            ,fbc.book_type_code AS book_type_code -- 資産台帳名
        FROM fa_deprn_periods fdp     -- 減価償却期間
            ,fa_calendar_periods fcp  -- 資産カレンダ
            ,fa_book_controls fbc     -- 資産台帳マスタ
            ,xxcff_lease_kind_v xlk   -- リース種類ビュー
       WHERE xlk.lease_kind_code = cv_lease_kind_qfin
         AND fdp.book_type_code = xlk.book_type_code
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
    -- 減価償却期間情報取得
    OPEN period_cur;
    FETCH period_cur INTO period_rec;
    CLOSE period_cur;
    -- 戻り値設定
    on_fiscal_year    := period_rec.fiscal_year;      -- 会計年度
    ov_period_to      := period_rec.period_to;        -- 出力期間（至）
    on_period_num_now := period_rec.period_num;       -- 期間番号
    od_start_date_now := period_rec.start_date_now;   -- 当期開始日
    ov_book_type_code := period_rec.book_type_code;   -- 資産台帳名
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
  END get_period_name;
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
    -- ============================================
    -- A-2．会計期間情報取得処理
    -- ============================================
    get_period_name(
       iv_period_name         -- 1.会計期間名
      ,lt_fiscal_year         -- 2.会計年度
      ,lt_period_to           -- 3.出力期間（至）
      ,lt_period_num_now      -- 4.期間番号
      ,ld_start_date_now      -- 5.当期開始日
      ,lt_book_type_code      -- 6.資産台帳名
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
       lt_fiscal_year         -- 1.会計年度
      ,lt_period_from         -- 2.出力期間（自）
      ,lt_period_num_1st      -- 3.期間番号
      ,ld_start_date_1st      -- 4.期首開始日
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
    -- A-4．会計期間期首取得処理
    -- ============================================
    get_contract_info(
       lt_book_type_code    --  1.資産台帳名
      ,ld_start_date_1st    --  2.期首開始日
      ,ld_start_date_now    --  3.当期開始日
      ,lt_fiscal_year       --  4.会計年度
      ,lt_period_num_1st    --  5.期首期間番号
      ,lt_period_num_now    --  6.当期期間番号
      ,lt_period_from       --  7.出力期間（自）
      ,lt_period_to         --  8.出力期間（至）
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
    iv_period_name   IN    VARCHAR2         -- 1.会計期間名
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
END XXCFF014A21C;
/
