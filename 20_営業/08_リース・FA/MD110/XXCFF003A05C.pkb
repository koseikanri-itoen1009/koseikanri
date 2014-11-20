create or replace
PACKAGE BODY XXCFF003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A05C(body)
 * Description      : 支払計画作成
 * MD.050           : MD050_CFF_003_A05_支払計画作成.doc
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_process_date       業務処理日付取得処理           (A-1)
 *  chk_data_validy        入力項目チェック処理           (A-2)
 *  get_contract_info      リース契約情報抽出処理         (A-3)
 *  ins_pat_planning       リース支払計画作成処理         (A-5)
 *  upd_pat_planning       リース支払計画控除額変更処理   (A-6)
 *  can_pat_planning       リース支払計画中途解約処理     (A-7)
 *  del_pat_planning       リース支払計画削除処理         (A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor          Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2008/12/02     1.0   SCS礒崎祐次     新規作成
 * 2008/12/25     1.0   SCS礒崎祐次     照合済フラグは、0,1に変更
 * 2008/1/13      1.0   SCS礒崎祐次     頻度が年の場合の支払日対応
 * 2009/1/22      1.0   SCS礒崎祐次     ＦＩＮリース債務残が０にならない場合は
 *                                      支払利息の調整を行う
 * 2009/2/5       1.1   SCS礒崎祐次     [障害CFF_010] 支払回数算出不具合対応
 * 2009/7/9       1.2   SCS萱原伸哉     [統合テスト障害00000417]中途解約日更新時の条件変更
 * 2011/12/19     1.3   SCSK中村健一    [E_本稼動_08123] 中途解約時の更新条件変更
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
  --
  --ステータス・コード
  cv_status_normal  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn    CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;          --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                     --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;          --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                     --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;         --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;  --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;     --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;  --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                     --PROGRAM_UPDATE_DATE
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg        VARCHAR2(2000);
  gv_sep_msg        VARCHAR2(2000);
  gv_exec_user      VARCHAR2(100);
  gv_conc_name      VARCHAR2(30);
  gv_conc_status    VARCHAR2(30);
  gn_target_cnt     NUMBER;                       -- 対象件数
  gn_normal_cnt     NUMBER;                       -- 正常件数
  gn_error_cnt      NUMBER;                       -- エラー件数
  gn_warn_cnt       NUMBER;                       -- スキップ件数
--
--################################  固定部 END   ##################################
--
  cv_msg_part       CONSTANT VARCHAR2(1) := ':';  -- コロン
  cv_msg_cont       CONSTANT VARCHAR2(1) := '.';  -- ピリオド
  --
--cv_const_n        CONSTANT VARCHAR2(1) := 'N';  -- 'N'
--cv_const_y        CONSTANT VARCHAR2(1) := 'Y';  -- 'Y'
  cv_const_0        CONSTANT VARCHAR2(1) := '0';  -- '未照合'
  cv_const_1        CONSTANT VARCHAR2(1) := '1';  -- '照合済'
  --
  cv_null_byte      CONSTANT VARCHAR2(1) := '';  -- ''
  --
  cv_shori_type1    CONSTANT VARCHAR2(1) := '1';  -- '追加'
  cv_shori_type2    CONSTANT VARCHAR2(1) := '2';  -- '控除額変更'
  cv_shori_type3    CONSTANT VARCHAR2(1) := '3';  -- '中途解約'
  cv_shori_type4    CONSTANT VARCHAR2(1) := '4';  -- '解約'
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  
  lock_expt              EXCEPTION;     -- ロック取得エラー
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  --
--################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF003A05C'; -- パッケージ名
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';
--
  -- メッセージ番号
  -- 契約明細内部IDエラー
  cv_msg_cff_00005   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00005';
  -- ロックエラー
  cv_msg_cff_00007   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00007';
  -- 処理区分エラー
  cv_msg_cff_00060   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00060';
  -- 業務処理日付取得エラー
  cv_msg_cff_00092   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00092';
  -- メッセージトークン
  cv_tk_cff_00005_01 CONSTANT VARCHAR2(15)  := 'INPUT';       -- カラム論理名
  cv_tk_cff_00101_01 CONSTANT VARCHAR2(15)  := 'TABLE_NAME';  -- テーブル名
--
  -- トークン
  cv_msg_cff_50028   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50028';  -- 契約明細内部ID
  cv_msg_cff_50088   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50088';  -- リース支払計画
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date             date;                                                -- 業務日付
  gn_payment_frequency        xxcff_contract_headers.payment_frequency%TYPE;       -- 支払回数
  gn_lease_class              xxcff_contract_headers.lease_class%TYPE;             -- リース種別
  gn_lease_type               xxcff_contract_headers.lease_type%TYPE;              -- リース区分
  gn_first_payment_date       xxcff_contract_headers.first_payment_date%TYPE;      -- 初回支払日
  gn_second_payment_date      xxcff_contract_headers.second_payment_date%TYPE;     -- ２回目支払日
  gn_third_payment_date       xxcff_contract_headers.third_payment_date%TYPE;      -- ３回目以降支払日
  gn_payment_type             xxcff_contract_headers.payment_type%TYPE;            -- 頻度
  gn_contract_header_id       xxcff_contract_headers.contract_header_id%TYPE;      -- 契約内部ID
  gn_contract_line_id         xxcff_contract_lines.contract_line_id%TYPE;          -- 契約明細内部ID
  gn_first_charge             xxcff_contract_lines.first_charge%TYPE;              -- 初回月額リース料_リース料
  gn_first_tax_charge         xxcff_contract_lines.first_tax_charge%TYPE;          -- 初回消費税額_リース料
  gn_first_deduction          xxcff_contract_lines.first_deduction%TYPE;           -- 初回月額リース料_控除額
  gn_first_tax_deduction      xxcff_contract_lines.first_tax_deduction%TYPE;       -- 初回消費税額_控除額
  gn_second_charge            xxcff_contract_lines.second_charge%TYPE;             -- ２回目月額リース料_リース料
  gn_second_tax_charge        xxcff_contract_lines.second_tax_charge%TYPE;         -- ２回目消費税額_リース料
  gn_second_deduction         xxcff_contract_lines.second_deduction%TYPE;          -- ２回目以降月額リース料_控除額
  gn_second_tax_deduction     xxcff_contract_lines.second_tax_deduction%TYPE;      -- ２回目以降消費税額_控除額
  gn_gross_tax_charge         xxcff_contract_lines.gross_tax_charge%TYPE;          -- 総額消費税_リース料
  gn_gross_tax_deduction      xxcff_contract_lines.gross_tax_deduction%TYPE;       -- 総額消費税_控除額
  gn_original_cost            xxcff_contract_lines.original_cost%TYPE;             -- 取得価格
  gn_calc_interested_rate     xxcff_contract_lines.calc_interested_rate%TYPE;      -- 計算利子率
-- == 2011/12/19 V1.3 Added START ======================================================================================
  gd_cancellation_date        xxcff_contract_lines.cancellation_date%TYPE;         -- 中途解約日
-- == 2011/12/19 V1.3 Added END   ======================================================================================
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : 業務処理日付取得処理(A-1)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf              OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- プログラム名
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
-- 
    --*** ローカル定数 ***
--
    --*** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 業務処理日付取得処理
    -- ***************************************************
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF (gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,      -- アプリケーション短縮名：XXCFF
                     cv_msg_cff_00092     -- メッセージ：業務処理日付取得エラー
                     ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
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
  END get_process_date;
--
 /**********************************************************************************
   * Procedure Name   : chk_data_validy 
   * Description      : 入力項目チェック処理 (A-2)
   ***********************************************************************************/
  PROCEDURE chk_data_validy(
    iv_shori_type          IN  VARCHAR2         -- 処理区分
   ,in_contract_line_id    IN  NUMBER           -- 契約明細内部ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2  -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2  -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_data_validy'; -- プログラム名
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
--
    --*** ローカル定数 ***
--
    --*** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- ***************************************************
    -- 1.必須チェック
    -- ***************************************************
    -- 処理区分
    IF ((iv_shori_type < cv_shori_type1) OR (iv_shori_type > cv_shori_type4)) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,       -- アプリケーション短縮名：XXCFF
                     cv_msg_cff_00060      -- メッセージ：処理区分エラー
                     ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 契約明細内部ID
    IF (in_contract_line_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,       -- アプリケーション短縮名：XXCFF
                     cv_msg_cff_00005,     -- メッセージ：契約明細内部ID必須エラー
                     cv_tk_cff_00005_01,   -- トークン名：INPUT
                     cv_msg_cff_50028      -- トークン  ：契約明細内部ID
                     ),1,5000);
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
  END chk_data_validy;
--
 /**********************************************************************************
   * Procedure Name   : get_contract_info
   * Description      : リース契約情報抽出処理       (A-3)
   ***********************************************************************************/
  PROCEDURE get_contract_info(
    in_contract_line_id  IN  NUMBER            -- 契約明細内部ID
   ,ov_errbuf            OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode           OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg            OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
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
--
    --*** ローカル定数 ***
--
    --*** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.リース契約、リース契約明細の取得
    -- ***************************************************
    --
    SELECT  xch.payment_frequency         -- 支払回数
           ,xch.lease_class               -- リース種別
           ,xch.lease_type                -- リース区分
           ,xch.first_payment_date        -- 初回支払日
           ,xch.second_payment_date       -- ２回目支払日
           ,xch.third_payment_date        -- ３回目以降支払日
           ,xch.payment_type              -- 頻度
           ,xcl.contract_header_id        -- 契約内部ID
           ,xcl.contract_line_id          -- 契約明細内部ID
           ,xcl.first_charge              -- 初回月額リース料_リース料
           ,xcl.first_tax_charge          -- 初回消費税額_リース料
           ,xcl.first_deduction           -- 初回月額リース料_控除額
           ,xcl.first_tax_deduction       -- 初回消費税額_控除額
           ,xcl.second_charge             -- ２回目月額リース料_リース料
           ,xcl.second_tax_charge         -- ２回目消費税額_リース料
           ,xcl.second_deduction          -- ２回目以降月額リース料_控除額
           ,xcl.second_tax_deduction      -- ２回目以降消費税額_控除額
           ,xcl.gross_tax_charge          -- 総額消費税_リース料
           ,xcl.gross_tax_deduction       -- 総額消費税_控除額
           ,xcl.original_cost             -- 取得価格
           ,xcl.calc_interested_rate      -- 計算利子率
-- == 2011/12/19 V1.3 Added START ======================================================================================
           ,xcl.cancellation_date         -- 中途解約日
-- == 2011/12/19 V1.3 Added END   ======================================================================================
    INTO    gn_payment_frequency          -- 支払回数
           ,gn_lease_class                -- リース種別
           ,gn_lease_type                 -- リース区分
           ,gn_first_payment_date         -- 初回支払日
           ,gn_second_payment_date        -- ２回目支払日
           ,gn_third_payment_date         -- ３回目以降支払日
           ,gn_payment_type               -- 頻度
           ,gn_contract_header_id         -- 契約内部ID
           ,gn_contract_line_id           -- 契約明細内部ID
           ,gn_first_charge               -- 初回月額リース料_リース料
           ,gn_first_tax_charge           -- 初回消費税額_リース料
           ,gn_first_deduction            -- 初回月額リース料_控除額
           ,gn_first_tax_deduction        -- 初回消費税額_控除額
           ,gn_second_charge              -- ２回目月額リース料_リース料
           ,gn_second_tax_charge          -- ２回目消費税額_リース料
           ,gn_second_deduction           -- ２回目以降月額リース料_控除額
           ,gn_second_tax_deduction       -- ２回目以降消費税額_控除額
           ,gn_gross_tax_charge           -- 総額消費税_リース料
           ,gn_gross_tax_deduction        -- 総額消費税_控除額
           ,gn_original_cost              -- 取得価格
           ,gn_calc_interested_rate       -- 計算利子率
-- == 2011/12/19 V1.3 Added START ======================================================================================
           ,gd_cancellation_date          -- 中途解約日
-- == 2011/12/19 V1.3 Added END   ======================================================================================
    FROM    xxcff_contract_headers  xch   -- リース契約
           ,xxcff_contract_lines    xcl   -- リース契約明細
    WHERE  xcl.contract_header_id  = xch.contract_header_id
    AND    xcl.contract_line_id    = in_contract_line_id;
--
--#################################  固定例外処理部 START   ####################################
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
  END get_contract_info;
--
 /**********************************************************************************
   * Procedure Name   : ins_pat_planning
   * Description      : リース支払計画作成処理 (A-5)
   ***********************************************************************************/
  PROCEDURE ins_pat_planning(
    in_contract_line_id    IN  NUMBER            -- 契約明細内部ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_pat_planning'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cv_gn_lease_type1        CONSTANT VARCHAR2(1) := '1';  -- '原契約'
    cv_accounting_if_flag0   CONSTANT VARCHAR2(1) := '0';  -- '対象外'
    cv_accounting_if_flag1   CONSTANT VARCHAR2(1) := '1';  -- '未送信'
-- 00000417 2009/07/06 ADD START
    cv_accounting_if_flag2   CONSTANT VARCHAR2(1) := '2';  -- '送信済'
-- 00000417 2009/07/06 ADD END    
    cn_last_payment_date     CONSTANT NUMBER(2)   :=  31;  -- '31日'
    cv_payment_type_0        CONSTANT VARCHAR2(1) := '0';  -- '月'
    cv_payment_type_1        CONSTANT VARCHAR2(1) := '1';  -- '年'
--
    --*** ローカル変数 ***
    ln_cnt                   NUMBER;      -- 処理対象件数
    ln_month                 NUMBER;      -- 月数
--
    ln_calc_interested_rate  xxcff_contract_lines.calc_interested_rate%TYPE; -- 計算利子率
    ld_payment_date          xxcff_pay_planning.payment_date%TYPE;           -- 支払日
    ld_period_name           xxcff_pay_planning.period_name%TYPE;            -- 会計期間
    ln_lease_charge          xxcff_pay_planning.lease_charge%TYPE;           -- リース料
    ln_tax_charge            xxcff_pay_planning.lease_tax_charge%TYPE;       -- リース料_消費税額
    ln_lease_deduction       xxcff_pay_planning.lease_deduction%TYPE;        -- リース控除額
    ln_lease_tax_deduction   xxcff_pay_planning.lease_tax_deduction%TYPE;    -- リース控除額_消費税
    ln_op_charge             xxcff_pay_planning.op_charge%TYPE;              -- ＯＰリース料
    ln_op_tax_charge         xxcff_pay_planning.op_tax_charge%TYPE;          -- ＯＰリース料額_消費税
    ln_fin_debt              xxcff_pay_planning.fin_debt%TYPE;               -- ＦＩＮリース債務額
    ln_fin_tax_debt          xxcff_pay_planning.fin_tax_debt%TYPE;           -- ＦＩＮリース債務額_消費税
    ln_fin_interest_due      xxcff_pay_planning.fin_interest_due%TYPE;       -- ＦＩＮリース支払利息
    ln_fin_debt_rem          xxcff_pay_planning.fin_debt_rem%TYPE;           -- ＦＩＮリース債務残
    ln_fin_tax_debt_rem      xxcff_pay_planning.fin_tax_debt_rem%TYPE;       -- ＦＩＮリース債務残_消費税
    ln_accounting_if_flag    xxcff_pay_planning.accounting_if_flag%TYPE;     -- 会計IFフラグ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR pay_data_cur	
    IS
      SELECT payment_frequency
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id   = in_contract_line_id
      FOR UPDATE OF xpp.payment_frequency NOWAIT;
--
    -- *** ローカル・レコード ***
     pay_data_rec pay_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.リース支払計画をロックする
    -- ***************************************************
--
    BEGIN
    --カーソルのオープン
      OPEN pay_data_cur;
      CLOSE pay_data_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff
                     , cv_msg_cff_00007
                     , cv_tk_cff_00101_01
                     , cv_msg_cff_50088
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- 2.支払計画が存在する場合は削除する
    -- ==================================
    DELETE
    FROM xxcff_pay_planning xpp
    WHERE  xpp.contract_line_id  = in_contract_line_id;
--
    -- ==================================
    -- 3.支払計画の作成
    -- ==================================
    --計算利子率は月率にする
    ln_calc_interested_rate := round(gn_calc_interested_rate/12,7);
--
    --初期化
    ln_cnt           := 1;
    -- 該当件数分ループする
    FOR ln_cnt IN 1..gn_payment_frequency LOOP
--
      --支払日
      IF (ln_cnt = 1) THEN
        ld_payment_date := gn_first_payment_date;
      ELSIF (ln_cnt = 2) THEN
        ld_payment_date := gn_second_payment_date;
      ELSE
        IF (gn_payment_type = cv_payment_type_0) THEN
          --3回目支払日が31日
          IF (gn_third_payment_date = cn_last_payment_date) THEN
            ld_payment_date := LAST_DAY(ADD_MONTHS(gn_second_payment_date,ln_cnt-2));
          --3回目支払日が31日以外
          ELSE
            ld_payment_date := ADD_MONTHS(gn_second_payment_date,ln_cnt-2);
          END IF;
        ELSE
          ln_month := (ln_cnt-2) * 12;
          ld_payment_date := ADD_MONTHS(gn_second_payment_date,ln_month); 
        END IF;
      END IF;
--
      --会計期間
      ld_period_name := TO_CHAR(ld_payment_date,'YYYY-MM');
--
      --リース料
      IF (ln_cnt = 1) THEN
        ln_lease_charge := gn_first_charge;
      ELSE
        ln_lease_charge := gn_second_charge;
      END IF;
--
      --リース料_消費税
      IF (ln_cnt = 1) THEN
        ln_tax_charge := gn_first_tax_charge;
      ELSE
        ln_tax_charge := gn_second_tax_charge;
      END IF;
--
      --リース控除額
      IF (ln_cnt = 1) THEN
        ln_lease_deduction := gn_first_deduction;
      ELSE
        ln_lease_deduction := gn_second_deduction;
      END IF;
--
      --リース控除額_消費税
      IF (ln_cnt = 1) THEN
        ln_lease_tax_deduction := gn_first_tax_deduction;
      ELSE
        ln_lease_tax_deduction := gn_second_tax_deduction;
      END IF;
--
      --ＯＰリース料
      IF (ln_cnt = 1) THEN
        ln_op_charge := gn_first_charge - gn_first_deduction;
      ELSE
        ln_op_charge := gn_second_charge - gn_second_deduction;
      END IF;
--
      --ＯＰリース料額_消費税額
      IF (ln_cnt = 1) THEN
        ln_op_tax_charge := gn_first_tax_charge - gn_first_tax_deduction;
      ELSE
        ln_op_tax_charge := gn_second_tax_charge - gn_second_tax_deduction;
      END IF;
--
      --ＦＩＮリース支払利息      
      IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_interest_due := round(gn_original_cost * ln_calc_interested_rate);
        ELSE
          ln_fin_interest_due := round(ln_fin_debt_rem * ln_calc_interested_rate);
        END IF;
      END IF;
--
      --ＦＩＮリース債務額
      IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_debt := gn_first_charge - gn_first_deduction - ln_fin_interest_due;
        ELSE
          ln_fin_debt := gn_second_charge - gn_second_deduction - ln_fin_interest_due;
       END IF;
      END IF;
      --
      --ＦＩＮリース債務額_消費税
      IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_tax_debt := gn_first_tax_charge - gn_first_tax_deduction;
        ELSE
          ln_fin_tax_debt := gn_second_tax_charge - gn_second_tax_deduction;
        END IF;
      END IF;
--
      --ＦＩＮリース債務残
       IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_debt_rem := gn_original_cost - ln_fin_debt;
        ELSE
          ln_fin_debt_rem := ln_fin_debt_rem - ln_fin_debt;
          --支払回数が最終回で０にならない場合
          IF ((ln_cnt = gn_payment_frequency) AND (ln_fin_debt_rem <> 0)) THEN
              --ＦＩＮリース債務額
              ln_fin_debt := ln_fin_debt +  ln_fin_debt_rem;
              --支払利息
              ln_fin_interest_due := ln_fin_interest_due - ln_fin_debt_rem;
              --ＦＩＮリース債務残          
              ln_fin_debt_rem := 0;
          ELSE
            IF (ln_fin_debt_rem < 0) THEN
              ln_fin_debt_rem := 0;
            END IF;          
          END IF;    
        END IF;
      END IF;
--
      --ＦＩＮリース債務残_消費税
       IF (gn_lease_type  = cv_gn_lease_type1) THEN
        IF (ln_cnt = 1) THEN
          ln_fin_tax_debt_rem  := gn_gross_tax_charge - gn_gross_tax_deduction - ln_fin_tax_debt;
        ELSE
          ln_fin_tax_debt_rem  := ln_fin_tax_debt_rem - ln_fin_tax_debt;
            IF (ln_fin_tax_debt_rem< 0) THEN
              ln_fin_tax_debt_rem := 0;
            END IF;          
        END IF;
      END IF;
--
      --会計IFフラグ
      IF ( ld_period_name < TO_CHAR(gd_process_date,'YYYY-MM')) THEN
-- 00000417 2009/07/06  START
--        ln_accounting_if_flag := cv_accounting_if_flag0;
        ln_accounting_if_flag := cv_accounting_if_flag2;
-- 00000417 2009/07/06  END
      ELSE
        ln_accounting_if_flag := cv_accounting_if_flag1;
      END IF;
--
      -- ==================================
      -- 支払計画の登録
      -- ==================================
       INSERT INTO xxcff_pay_planning(
         contract_line_id                                 -- 契約明細内部ID
       , payment_frequency                                -- 支払回数
       , contract_header_id                               -- 契約内部ID
       , period_name                                      -- 会計期間
       , payment_date                                     -- 支払日
       , lease_charge                                     -- リース料
       , lease_tax_charge                                 -- リース料_消費税
       , lease_deduction                                  -- リース控除額
       , lease_tax_deduction                              -- リース控除額_消費税
       , op_charge                                        -- ＯＰリース料
       , op_tax_charge                                    -- ＯＰリース料額_消費税
       , fin_debt                                         -- ＦＩＮリース債務額
       , fin_tax_debt                                     -- ＦＩＮリース債務額_消費税
       , fin_interest_due                                 -- ＦＩＮリース支払利息
       , fin_debt_rem                                     -- ＦＩＮリース債務残
       , fin_tax_debt_rem                                 -- ＦＩＮリース債務残_消費税
       , accounting_if_flag                               -- 会計ＩＦフラグ
       , payment_match_flag                               -- 照合済フラグ
       , created_by                                       -- 作成者
       , creation_date                                    -- 作成日
       , last_updated_by                                  -- 最終更新者
       , last_update_date                                 -- 最終更新日
       , last_update_login                                -- 最終更新ﾛｸﾞｲﾝ
       , request_id                                       -- 要求ID
       , program_application_id                           -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
       , program_id                                       -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
       , program_update_date                              -- ﾌﾟﾛｸﾞﾗﾑ更新日
       )
       VALUES(
         gn_contract_line_id                              -- 契約内部明細ID
       , ln_cnt                                           -- 支払回数
       , gn_contract_header_id                            -- 契約内部ID
       , ld_period_name                                   -- 会計期間
       , ld_payment_date                                  -- 支払日
       , ln_lease_charge                                  -- リース料
       , ln_tax_charge                                    -- リース料_消費税
       , ln_lease_deduction                               -- リース控除額 
       , ln_lease_tax_deduction                           -- リース控除額_消費税額
       , ln_op_charge                                     -- ＯＰリース料
       , ln_op_tax_charge                                 -- ＯＰリース料額_消費税
       , ln_fin_debt                                      -- ＦＩＮリース債務額
       , ln_fin_tax_debt                                  -- ＦＩＮリース債務額_消費税
       , ln_fin_interest_due                              -- ＦＩＮリース支払利息
       , ln_fin_debt_rem                                  -- ＦＩＮリース債務残
       , ln_fin_tax_debt_rem                              -- ＦＩＮリース債務残_消費税
       , ln_accounting_if_flag                            -- 会計ＩＦフラグ
       , cv_const_0                                       -- 照合済フラグ
       , cn_created_by                                    -- 作成者
       , cd_creation_date                                 -- 作成日
       , cn_last_updated_by                               -- 最終更新者
       , cd_last_update_date                              -- 最終更新日
       , cn_last_update_login                             -- 最終更新ﾛｸﾞｲﾝ
       , cn_request_id                                    -- 要求ID
       , cn_program_application_id                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
       , cn_program_id                                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
       , cd_program_update_date                           -- ﾌﾟﾛｸﾞﾗﾑ更新日
    );
    END LOOP;
--
--#################################  固定例外処理部 START   ####################################
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
  END ins_pat_planning;
--
  /**********************************************************************************
   * Procedure Name   : upd_pat_planning 
   * Description      : リース支払計画控除額変更処理   (A-6)
   ***********************************************************************************/
  PROCEDURE upd_pat_planning(
    in_contract_line_id    IN  NUMBER            -- 契約明細内部ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_pat_planning'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cv_accounting_if_flag1   CONSTANT VARCHAR2(1) := '1';  -- '未送信'
--
    --*** ローカル変数 ***
    ln_payment_frequency     xxcff_contract_headers.payment_frequency%TYPE;  --支払回数
    ln_lease_charge          NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT lease_charge         --リース料
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id  =  in_contract_line_id
      AND    xpp.payment_frequency >= ln_payment_frequency
      FOR UPDATE OF xpp.lease_charge NOWAIT;
--
    -- *** ローカル・レコード ***
     pay_data_rec pay_data_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.MIN値を取得する
    -- ***************************************************
    SELECT  MIN(xpp.payment_frequency)         -- 支払回数
    INTO    ln_payment_frequency               -- 支払回数
    FROM    xxcff_pay_planning xpp
    WHERE  xpp.contract_line_id   = in_contract_line_id
    AND    xpp.accounting_if_flag = cv_accounting_if_flag1
    AND    xpp.period_name        >= TO_CHAR(gd_process_date,'YYYY-MM');
--    
    --支払回数が取得できない場合は０を設定する
    ln_payment_frequency  := NVL(ln_payment_frequency,0);
--
    --該当データが存在しない場合
    IF (ln_payment_frequency = 0) THEN
      RETURN;  
    END IF;
--
    -- ***************************************************
    -- 2.リース支払計画をロックする
    -- ***************************************************
--
    BEGIN
    --カーソルのオープン
      OPEN pay_data_cur;
      CLOSE pay_data_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff
                     , cv_msg_cff_00007
                     , cv_tk_cff_00101_01
                     , cv_msg_cff_50088
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--    
    -- ***************************************************
    -- 3.リース支払計画を対象外にする
    -- ***************************************************
--
    UPDATE xxcff_pay_planning xpp  -- リース支払計画
    SEt    xpp.lease_charge            = gn_second_charge                       -- ２回目月額リース料_リース料
         , xpp.lease_tax_charge        = gn_second_tax_charge                   -- ２回目消費税額_リース料
         , xpp.lease_deduction         = gn_second_deduction                    -- ２回目以降月額リース料_控除額
         , xpp.lease_tax_deduction     = gn_second_tax_deduction                -- ２回目以降消費税額_控除額
         , xpp.last_updated_by         = cn_last_updated_by                     -- 最終更新者
         , xpp.last_update_date        = cd_last_update_date                    -- 最終更新日
         , xpp.last_update_login       = cn_last_update_login                   -- 最終更新ﾛｸﾞｲﾝ
         , xpp.request_id              = cn_request_id                          -- 要求ID
         , xpp.program_application_id  = cn_program_application_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
         , xpp.program_id              = cn_program_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
         , xpp.program_update_date     = cd_program_update_date                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
    WHERE  xpp.contract_line_id   =  in_contract_line_id
    AND    xpp.payment_frequency  >= ln_payment_frequency;
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
  END upd_pat_planning;
--
  /**********************************************************************************
   * Procedure Name   : can_pat_planning 
   * Description      : リース支払計画中途解約処理     (A-7)
   ***********************************************************************************/
  PROCEDURE can_pat_planning(
    in_contract_line_id    IN  NUMBER            -- 契約明細内部ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'can_pat_planning'; -- プログラム名
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
--
    --*** ローカル定数 ***
    cv_accounting_if_flag0   CONSTANT VARCHAR2(1) := '0';  -- '対象外'    
    cv_accounting_if_flag1   CONSTANT VARCHAR2(1) := '1';  -- '未送信'    
--
    --*** ローカル変数 ***
    ln_payment_frequency     xxcff_contract_headers.payment_frequency%TYPE;  --支払回数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT xpp.payment_frequency
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id   =  in_contract_line_id
      AND    xpp.payment_frequency  >= ln_payment_frequency
      FOR UPDATE OF xpp.payment_frequency NOWAIT;
--
    -- *** ローカル・レコード ***
     pay_data_rec pay_data_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.MIN値を取得する
    -- ***************************************************
    ln_payment_frequency  := 0;
--
    SELECT MIN(xpp.payment_frequency)
    INTO   ln_payment_frequency
    FROM   xxcff_pay_planning xpp
    WHERE  xpp.contract_line_id   = in_contract_line_id
    AND    xpp.accounting_if_flag = cv_accounting_if_flag1
-- == 2011/12/19 V1.3 Modified START ===================================================================================
--    AND    xpp.period_name        >= TO_CHAR(gd_process_date,'YYYY-MM');
    AND    xpp.period_name        >= TO_CHAR(gd_cancellation_date,'YYYY-MM');
-- == 2011/12/19 V1.3 Modified END   ===================================================================================
--    
    --支払回数が取得できない場合は０を設定する
    ln_payment_frequency  := NVL(ln_payment_frequency,0);
--
    --該当データが存在しない場合
    IF (ln_payment_frequency = 0) THEN
      RETURN;  
    END IF;
--
    -- ***************************************************
    -- 2.リース支払計画をロックする
    -- ***************************************************
    BEGIN
    --カーソルのオープン
      OPEN pay_data_cur;
      CLOSE pay_data_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff
                     , cv_msg_cff_00007
                     , cv_tk_cff_00101_01
                     , cv_msg_cff_50088
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--    
    -- ***************************************************
    -- 3.リース支払計画を対象外にする
    -- ***************************************************
    --
    UPDATE xxcff_pay_planning xpp  -- リース支払計画
    SET    xpp.accounting_if_flag      = cv_accounting_if_flag0                 -- 会計IFフラグ
         , xpp.last_updated_by         = cn_last_updated_by                     -- 最終更新者
         , xpp.last_update_date        = cd_last_update_date                    -- 最終更新日
         , xpp.last_update_login       = cn_last_update_login                   -- 最終更新ﾛｸﾞｲﾝ
         , xpp.request_id              = cn_request_id                          -- 要求ID
         , xpp.program_application_id  = cn_program_application_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
         , xpp.program_id              = cn_program_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
         , xpp.program_update_date     = cd_program_update_date                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
    WHERE  xpp.contract_line_id        = in_contract_line_id
-- 00000417 2009/07/09 ADD START
      AND    xpp.payment_match_flag =  cv_const_0
-- 00000417 2009/07/09 ADD END
    AND    xpp.payment_frequency      >= ln_payment_frequency;
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
  END can_pat_planning;
--  
  /**********************************************************************************
   * Procedure Name   : del_pat_planning
   * Description      : リース支払計画削除処理       (A-8)
   ***********************************************************************************/
  PROCEDURE del_pat_planning(
    in_contract_line_id    IN  NUMBER            -- 契約明細内部ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2   -- エラー・メッセージ
   ,ov_retcode             OUT NOCOPY VARCHAR2   -- リターン・コード
   ,ov_errmsg              OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_pat_planning'; -- プログラム名
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
--
    --*** ローカル定数 ***
--
    --*** ローカル変数 ***
    ln_payment_frequency NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR pay_data_cur
    IS
      SELECT payment_frequency
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id   = in_contract_line_id
      FOR UPDATE OF xpp.payment_frequency NOWAIT;
--
    -- *** ローカル・レコード ***
     pay_data_rec pay_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************************
    -- 1.リース支払計画をロックする
    -- ***************************************************
    BEGIN
    --カーソルのオープン
      OPEN pay_data_cur;
      CLOSE pay_data_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff
                     , cv_msg_cff_00007
                     , cv_tk_cff_00101_01
                     , cv_msg_cff_50088
                      );                                              
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ***************************************************
    -- 2.リース支払計画の削除する。
    -- ***************************************************
    DELETE
    FROM   xxcff_pay_planning xpp
    WHERE  xpp.contract_line_id   = in_contract_line_id;
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
  END del_pat_planning;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_shori_type        IN  VARCHAR2,            --   処理区分
    in_contract_line_id  IN  NUMBER,              --   契約明細内部ID
    ov_errbuf            OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_check_flag        VARCHAR2(1);     -- エラーチェック用フラグ
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ==================================
    -- 業務処理日付取得処理         (A-1)
    -- ==================================
    get_process_date(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================
    -- 入力項目チェック処理         (A-2)
    -- ==================================
    chk_data_validy(
      iv_shori_type,       -- 処理区分
      in_contract_line_id, -- 契約明細内部ID
      lv_errbuf,           -- エラー・メッセージ           --# 固定 #
      lv_retcode,          -- リターン・コード             --# 固定 #
      lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================
    -- リース契約情報抽出処理      (A-3)
    -- ==================================
    get_contract_info(
      in_contract_line_id, -- 契約明細内部ID
      lv_errbuf,           -- エラー・メッセージ           --# 固定 #
      lv_retcode,          -- リターン・コード             --# 固定 #
      lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================
    -- リース支払計画作成処理      (A-5)
    -- ==================================
    IF (iv_shori_type = cv_shori_type1) THEN
      ins_pat_planning(
        in_contract_line_id, -- 契約明細内部ID
        lv_errbuf,           -- エラー・メッセージ           --# 固定 #
        lv_retcode,          -- リターン・コード             --# 固定 #
        lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
    -- ==================================
    -- リース支払計画控除額変更処理 (A-6)
    -- ==================================
    ELSIF (iv_shori_type = cv_shori_type2) THEN
      upd_pat_planning(
        in_contract_line_id, -- 契約明細内部ID
        lv_errbuf,           -- エラー・メッセージ           --# 固定 #
        lv_retcode,          -- リターン・コード             --# 固定 #
        lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
    -- ==================================
    -- リース支払計画中途解約処理   (A-7)
    -- ==================================
    ELSIF (iv_shori_type = cv_shori_type3) THEN
      can_pat_planning(
        in_contract_line_id, -- 契約明細内部ID
        lv_errbuf,           -- エラー・メッセージ           --# 固定 #
        lv_retcode,          -- リターン・コード             --# 固定 #
        lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
    -- ==================================
    -- リース支払計画削除処理       (A-8)
    -- ==================================
    ELSIF (iv_shori_type = cv_shori_type4) THEN
      del_pat_planning(
        in_contract_line_id, -- 契約明細内部ID
        lv_errbuf,           -- エラー・メッセージ           --# 固定 #
        lv_retcode,          -- リターン・コード             --# 固定 #
        lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
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
    iv_shori_type              IN VARCHAR2            --   1.処理区分
   ,in_contract_line_id        IN NUMBER              --   2.契約明細内部ID
   ,ov_errbuf                  OUT NOCOPY VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT NOCOPY VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_shori_type         -- 1.処理区分
      ,in_contract_line_id   -- 2.契約明細内部ID
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー・メッセージ
    ov_errbuf  := lv_errbuf;
    --ステータスセット
    ov_retcode := lv_retcode;
    -- ユーザー・エラー・メッセージ
    ov_errmsg  := lv_errmsg;
--
    --終了ステータスがエラーの場合はROLLBACKする
    IF (ov_retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCFF003A05C;
/
