CREATE OR REPLACE PACKAGE BODY XXCFF020A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCFF020A01C(body)
 * Description      : 登録済み支払計画の支払料金、支払回数の変更
 * MD.050           : MD050_CFF_020_A01_リース料変更プログラム
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_target_data        対象データ抽出(A-2)
 *  output_csv             各種情報CSV出力(A-3)
 *  create_pay_planning    新支払計画データ作成(A-4)
 *  ins_backup             データバックアップ(A-5)
 *  replace_pay_planning   新支払計画登録(A-6)
 *  upd_contract_data      契約情報更新(A-7)
 *  ins_adjustment_oif     修正OIF作成(A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/10/02    1.0   H.Sasaki         新規作成(E_本稼動_14830)
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_comm               CONSTANT VARCHAR2(3) := ',';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
  gn_warn_cnt               NUMBER;                    -- スキップ件数
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  
  conc_error_expt           EXCEPTION;            --  コンカレント起動時の例外処理
  procedure_expt            EXCEPTION;            --  各プロシージャ結果に対する例外(SUBMAIN)
  lock_expt                 EXCEPTION;            --  ロックエラー
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(30) :=  'XXCFF020A01C';                 --  パッケージ名
  cv_app_kbn_cff                CONSTANT VARCHAR2(5)  :=  'XXCFF';                        --  アプリケーション短縮名
  cv_app_kbn_ccp                CONSTANT VARCHAR2(5)  :=  'XXCCP';                        --  アプリケーション短縮名
  --
  cv_msg_cff_00020              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00020';             --  プロファイル取得エラー
  cv_msg_cff_00194              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00194';             --  リース月次締期間取得エラー
  cv_msg_cff_00123              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00123';             --  存在チェックエラー
  cv_msg_cff_00094              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00094';             --  共通関数エラー
  cv_msg_cff_00292              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00292';             --  リース料変更不可エラーメッセージ
  cv_msg_cff_00165              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00165';             --  取得対象データ無し
  cv_msg_cff_00007              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00007';             --  ロックエラー
  cv_msg_cff_00293              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00293';             --  支払回数妥当性チェックエラー（リース料変更）
  cv_msg_cff_00294              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00294';             --  リース料変更実施エラーメッセージ
  cv_msg_cff_00268              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00268';             --  資産カテゴリ情報取得エラー
  cv_msg_cff_00089              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00089';             --  割引率取得エラー
  cv_msg_cff_00197              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00197';             --  コンカレント発行エラー
  cv_msg_cff_00198              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00198';             --  コンカレント待機エラー
  cv_msg_cff_00199              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00199';             --  コンカレント処理エラー
  cv_msg_cff_00102              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00102';             --  登録エラー
  --
  cv_msg_cff_50210              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50210';             --  (固定文字列)コンカレントパラメータ出力処理
  cv_msg_cff_50323              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50323';             --  (固定文字列)リース判定処理
  cv_msg_cff_50303              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50303';             --  (固定文字列)資産カテゴリチェック
  cv_msg_cff_50219              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50219';             --  (固定文字列)リース契約ヘッダ
  cv_msg_cff_50220              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50220';             --  (固定文字列)リース契約明細
  cv_msg_cff_50088              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50088';             --  (固定文字列)リース支払計画
  cv_msg_cff_50203              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50203';             --  (固定文字列)リース契約データCSV出力
  cv_msg_cff_50204              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50204';             --  (固定文字列)リース物件データCSV出力
  cv_msg_cff_50205              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50205';             --  (固定文字列)リース支払計画データCSV出力
  cv_msg_cff_50206              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50206';             --  (固定文字列)リース会計基準情報CSV出力
  cv_msg_cff_50256              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50256';             --  (固定文字列)資産詳細情報
  --
  cv_tok_cff_00020_1            CONSTANT VARCHAR2(30) :=  'PROF_NAME';                    --  (トークン)APP-XXCFF1-00020
  cv_tok_cff_00194_1            CONSTANT VARCHAR2(30) :=  'BOOK_ID';                      --  (トークン)APP-XXCFF1-00194
  cv_tok_cff_00123_1            CONSTANT VARCHAR2(30) :=  'COLUMN_DATA ';                 --  (トークン)APP-XXCFF1-00123
  cv_tok_cff_00094_1            CONSTANT VARCHAR2(30) :=  'FUNC_NAME';                    --  (トークン)APP-XXCFF1-00094
  cv_tok_cff_00165_1            CONSTANT VARCHAR2(30) :=  'GET_DATA';                     --  (トークン)APP-XXCFF1-00165
  cv_tok_cff_00007_1            CONSTANT VARCHAR2(30) :=  'TABLE_NAME';                   --  (トークン)APP-XXCFF1-00007
  cv_tok_cff_00293_1            CONSTANT VARCHAR2(30) :=  'FREQUENCY';                    --  (トークン)APP-XXCFF1-00293
  cv_tok_cff_00268_1            CONSTANT VARCHAR2(30) :=  'CATEGORY';                     --  (トークン)APP-XXCFF1-00268
  cv_tok_cff_00268_2            CONSTANT VARCHAR2(30) :=  'BOOK_TYPE_CODE';               --  (トークン)APP-XXCFF1-00268
  cv_tok_cff_00197_1            CONSTANT VARCHAR2(30) :=  'SYORI';                        --  (トークン)APP-XXCFF1-00197
  cv_tok_cff_00198_1            CONSTANT VARCHAR2(30) :=  'REQUEST_ID';                   --  (トークン)APP-XXCFF1-00198
  cv_tok_cff_00199_1            CONSTANT VARCHAR2(30) :=  'REQUEST_ID';                   --  (トークン)APP-XXCFF1-00199
  cv_tok_cff_00102_1            CONSTANT VARCHAR2(30) :=  'TABLE_NAME';                   --  (トークン)APP-XXCFF1-00102
  cv_tok_cff_00102_2            CONSTANT VARCHAR2(30) :=  'INFO';                         --  (トークン)APP-XXCFF1-00102
  --
  cv_prof_ifrs_sob_id           CONSTANT VARCHAR2(30) :=  'XXCFF1_IFRS_SET_OF_BKS_ID';    --  (プロファイル)XXCFF:IFRS帳簿ID
  cv_prof_ifrs_lease_books      CONSTANT VARCHAR2(30) :=  'XXCFF1_IFRS_LEASE_BOOKS';      --  (プロファイル)XXCFF:台帳名_IFRSリース台帳
  cv_prof_conc_interval         CONSTANT VARCHAR2(30) :=  'XXCOS1_INTERVAL';              --  (プロファイル)XXCOS:待機間隔
  cv_prof_conc_max_wait         CONSTANT VARCHAR2(30) :=  'XXCOS1_MAX_WAIT';              --  (プロファイル)XXCOS:最大待機時間
  --
  cv_prg_contract_csv           CONSTANT VARCHAR2(30) :=  'XXCCP008A01C';                 --  (コンカレント)リース契約データCSV出力
  cv_prg_object_csv             CONSTANT VARCHAR2(30) :=  'XXCCP008A02C';                 --  (コンカレント)リース物件データCSV出力
  cv_prg_pay_planning_csv       CONSTANT VARCHAR2(30) :=  'XXCCP008A03C';                 --  (コンカレント)リース支払計画データCSV出力
  cv_prg_accounting_csv         CONSTANT VARCHAR2(30) :=  'XXCCP008A04C';                 --  (コンカレント)リース会計基準情報CSV出力
  --
  cv_lease_class_2              CONSTANT VARCHAR2(1)  :=  '2';                            --  リース種別：2
  cv_dummy_code                 CONSTANT VARCHAR2(1)  :=  '*';                            --  ダミーコード
  cv_separator                  CONSTANT VARCHAR2(1)  :=  '-';                            --  セパレータ
  cv_dev_status_error           CONSTANT VARCHAR2(5)  :=  'ERROR';                        --  ステータス：ERROR
  cv_date_format                CONSTANT VARCHAR2(7)  :=  'YYYY-MM';                      --  日付フォーマット
  cv_date_format_ymd            CONSTANT VARCHAR2(10) :=  'YYYY/MM/DD';                   --  日付フォーマット
  cv_flag_1                     CONSTANT VARCHAR2(1)  :=  '1';                            --  フラグ固定値：1
  cv_flag_2                     CONSTANT VARCHAR2(1)  :=  '2';                            --  フラグ固定値：2
  cv_flag_y                     CONSTANT VARCHAR2(1)  :=  'Y';                            --  フラグ固定値：Y
  cv_contract_status_210        CONSTANT VARCHAR2(3)  :=  '210';                          --  契約ステータス：210(データメンテナンス)
  cv_update_reason              CONSTANT VARCHAR2(20) :=  'リース料更新';                 --  契約明細履歴．更新事由
  cv_oif_status_p               CONSTANT VARCHAR2(7)  :=  'PENDING';                      --  更新OIF．ステータス
  cv_oif_amortized_yes          CONSTANT VARCHAR2(3)  :=  'YES';                          --  更新OIF．修正額償却フラグ
  cv_lang                       CONSTANT VARCHAR2(2)  :=  USERENV('LANG');                --  言語
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_target_rtype IS RECORD(
      object_header_id          xxcff_object_headers.object_header_id%TYPE            --  物件内部ID
    , lease_class               xxcff_object_headers.lease_class%TYPE                 --  リース種別
    , owner_company             xxcff_object_headers.owner_company%TYPE               --  本社／工場
    , contract_header_id        xxcff_contract_headers.contract_header_id%TYPE        --  契約内部ID
    , contract_line_id          xxcff_contract_lines.contract_line_id%TYPE            --  契約明細内部ID
    , payment_frequency         xxcff_pay_planning.payment_frequency%TYPE             --  次回支払回数
    , asset_category            xxcff_contract_lines.asset_category%TYPE              --  資産出離
    , contract_number           xxcff_contract_headers.contract_number%TYPE           --  契約番号
    , lease_company             xxcff_contract_headers.lease_company%TYPE             --  リース会社
    , second_payment_date       xxcff_contract_headers.second_payment_date%TYPE       --  2回目支払日
    , third_payment_date        xxcff_contract_headers.third_payment_date%TYPE        --  3回目以降支払日
    , lease_deduction           xxcff_pay_planning.lease_deduction%TYPE               --  リース控除額
    , lease_tax_charge          xxcff_pay_planning.lease_tax_charge%TYPE              --  リース料_消費税
    , lease_tax_deduction       xxcff_pay_planning.lease_tax_deduction%TYPE           --  リース控除額_消費税
    , fin_debt_rem              xxcff_pay_planning.fin_debt_rem%TYPE                  --  ＦＩＮリース債務残
    , fin_debt                  xxcff_pay_planning.fin_debt%TYPE                      --  ＦＩＮリース債務額
    , fin_tax_debt              xxcff_pay_planning.fin_tax_debt%TYPE                  --  ＦＩＮリース債務額_消費税
    , tax_code                  xxcff_contract_lines.tax_code%TYPE                    --  税コード
    , asset_category_id         NUMBER                                                --  資産カテゴリCCID
    , deprn_method              fa_category_book_defaults.deprn_method%TYPE           --  償却方法
    , asset_category_code       VARCHAR2(210)                                         --  資産カテゴリコード
    , remaining_frequency       xxcff_pay_planning.payment_frequency%TYPE             --  残り支払回数
    , discount_rate             xxcff_discount_rate_mst.discount_rate_01%TYPE         --  割引率
    , present_value             NUMBER                                                --  現在価値
    , sum_old_tax_charge        xxcff_pay_planning.lease_tax_charge%TYPE              --  変更前消費税額(合計)
    , sum_new_tax_charge        xxcff_pay_planning.lease_tax_charge%TYPE              --  変更後消費税額(合計)
  );
  TYPE g_new_pay_plan_ttype IS TABLE OF xxcff_pay_planning%ROWTYPE INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_param_object_code          xxcff_object_headers.object_code%TYPE;                    --  (起動パラメータ)物件コード
  gt_param_new_frequency        xxcff_contract_headers.payment_frequencY%TYPE;            --  (起動パラメータ)変更後支払回数
  gt_param_new_charge           xxcff_contract_lines.second_charge%TYPE;                  --  (起動パラメータ)変更後リース料
  gt_param_new_tax_charge       xxcff_contract_lines.second_tax_charge%TYPE;              --  (起動パラメータ)変更後税額
  gt_param_new_tax_code         xxcff_contract_lines.tax_code%TYPE;                       --  (起動パラメータ)変更後税コード
  gt_prof_ifrs_sob_id           fnd_profile_option_values.profile_option_value%TYPE;      --  (プロファイル値)IFRS帳簿ID
  gt_prof_ifrs_lease_books      fnd_profile_option_values.profile_option_value%TYPE;      --  (プロファイル値)IFRSリース台帳名
  gn_prof_conc_interval         NUMBER;                                                   --  (プロファイル)コンカレントの待機間隔
  gn_prof_conc_max_wait         NUMBER;                                                   --  (プロファイル)コンカレントの最大待機時間
  gd_ifrs_period_date           DATE;                                                     --  IFRS会計期間
  gt_ifrs_period_name           xxcff_pay_planning.period_name%TYPE;                      --  会計期間名
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_object_code    IN  VARCHAR2        --  物件コード
    , iv_new_frequency  IN  VARCHAR2        --  変更後支払回数
    , iv_new_charge     IN  VARCHAR2        --  変更後リース料
    , iv_new_tax_charge IN  VARCHAR2        --  変更後税額
    , iv_new_tax_code   IN  VARCHAR2        --  変更後税コード
    , ov_errbuf         OUT VARCHAR2        --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2        --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2        --  ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- ===============================
    --  パラメータ保持
    -- ===============================
    gt_param_object_code    :=  iv_object_code;                         --  物件コード
    gt_param_new_frequency  :=  TO_NUMBER( iv_new_frequency );          --  変更後支払回数
    gt_param_new_charge     :=  TO_NUMBER( iv_new_charge );             --  変更後リース料
    gt_param_new_tax_charge :=  TO_NUMBER( iv_new_tax_charge );         --  変更後税額
    gt_param_new_tax_code   :=  iv_new_tax_code;                        --  変更後税コード
    --
    -- ===============================
    --  プロファイル値取得
    -- ===============================
    --  IFRS帳簿ID
    gt_prof_ifrs_sob_id       :=  TO_NUMBER( fnd_profile.value( cv_prof_ifrs_sob_id ) );
    IF ( gt_prof_ifrs_sob_id IS NULL ) THEN
      --  プロファイル値が取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  アプリケーション短縮名
                      , iv_name           =>  cv_msg_cff_00020          --  メッセージコード
                      , iv_token_name1    =>  cv_tok_cff_00020_1        --  トークンコード1
                      , iv_token_value1   =>  cv_prof_ifrs_sob_id       --  トークン値1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --  IFRSリース台帳名
    gt_prof_ifrs_lease_books  :=  fnd_profile.value( cv_prof_ifrs_lease_books );
    IF ( gt_prof_ifrs_lease_books IS NULL ) THEN
      --  プロファイル値が取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  アプリケーション短縮名
                      , iv_name           =>  cv_msg_cff_00020          --  メッセージコード
                      , iv_token_name1    =>  cv_tok_cff_00020_1        --  トークンコード1
                      , iv_token_value1   =>  cv_prof_ifrs_lease_books  --  トークン値1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
   --  コンカレントの待機間隔
    gn_prof_conc_interval     :=  TO_NUMBER( fnd_profile.value( cv_prof_conc_interval ) );
    IF ( gn_prof_conc_interval IS NULL ) THEN
      --  プロファイル値が取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  アプリケーション短縮名
                      , iv_name           =>  cv_msg_cff_00020          --  メッセージコード
                      , iv_token_name1    =>  cv_tok_cff_00020_1        --  トークンコード1
                      , iv_token_value1   =>  cv_prof_conc_interval     --  トークン値1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --  コンカレントの最大待機時間
    gn_prof_conc_max_wait     :=  TO_NUMBER( fnd_profile.value( cv_prof_conc_max_wait ) );
    IF ( gn_prof_conc_max_wait IS NULL ) THEN
      --  プロファイル値が取得できない場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  アプリケーション短縮名
                      , iv_name           =>  cv_msg_cff_00020          --  メッセージコード
                      , iv_token_name1    =>  cv_tok_cff_00020_1        --  トークンコード1
                      , iv_token_value1   =>  cv_prof_conc_max_wait     --  トークン値1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  会計期間取得
    -- ===============================
    BEGIN
      --  取得される年月の翌月1日
      SELECT  ADD_MONTHS( TO_DATE( xlcp.period_name, cv_date_format ), 1 )   ifrs_period_date
      INTO    gd_ifrs_period_date
      FROM    xxcff_lease_closed_periods    xlcp
      WHERE   xlcp.set_of_books_id    =   gt_prof_ifrs_sob_id
      AND     xlcp.period_name IS NOT NULL
      ;
      --  会計期間名
      gt_ifrs_period_name :=  TO_CHAR( gd_ifrs_period_date, cv_date_format );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  会計期間が取得できなかった場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff            --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00194          --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00194_1        --  トークンコード1
                        , iv_token_value1   =>  gt_prof_ifrs_sob_id       --  トークン値1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    --  システム用ログ出力（パラメータと会計期間）
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_app_kbn_cff            --  アプリケーション短縮名
                    , iv_name           =>  cv_msg_cff_50210          --  メッセージコード
                  )                 ||  cv_msg_part ||
                  iv_object_code    ||  cv_msg_comm ||
                  iv_new_frequency  ||  cv_msg_comm ||
                  iv_new_charge     ||  cv_msg_comm ||
                  iv_new_tax_charge ||  cv_msg_comm ||
                  iv_new_tax_code   ||  cv_msg_comm ||
                  TO_CHAR( gd_ifrs_period_date, cv_date_format_ymd )
                  ;
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
    --  空行挿入
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  ''
    );
    --
  EXCEPTION
    -- *** PROCEDURE内エラー ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Description      : 対象データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
      or_target_data    OUT g_target_rtype  --  対象データ
    , ov_errbuf         OUT VARCHAR2        --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2        --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2        --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_data'; -- プログラム名
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
    lt_ret_dff4                     fnd_lookup_values.attribute4%TYPE;                --  DFF4(日本基準連携)
    lt_ret_dff5                     fnd_lookup_values.attribute5%TYPE;                --  DFF5(IFRS連携)
    lt_ret_dff6                     fnd_lookup_values.attribute6%TYPE;                --  DFF6(仕訳作成)
    lt_ret_dff7                     fnd_lookup_values.attribute7%TYPE;                --  DFF7(リース判定処理)
    lt_check_payment_frequency      xxcff_contract_headers.payment_frequency%TYPE;    --  変更前支払回数
    lt_check_lease_charge           xxcff_pay_planning.lease_charge%TYPE;             --  変更前リース料
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
    -- ===============================
    --  物件情報取得
    -- ===============================
    BEGIN
      SELECT  xoh.object_header_id    object_header_id    --  物件ID
            , xoh.lease_class         lease_class         --  リース種別
            , xoh.owner_company       owner_company       --  本社／工場
      INTO    or_target_data.object_header_id
            , or_target_data.lease_class
            , or_target_data.owner_company
      FROM    xxcff_object_headers    xoh                 --  リース物件
      WHERE   xoh.object_code   =   gt_param_object_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  物件情報が取得できない場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff            --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00123          --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00123_1        --  トークンコード1
                        , iv_token_value1   =>  gt_param_object_code      --  トークン値1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===============================
    --  リース判定処理確認
    -- ===============================
    xxcff_common2_pkg.get_lease_class_info(
        iv_lease_class  =>  or_target_data.lease_class
      , ov_ret_dff4     =>  lt_ret_dff4           --  DFF4(日本基準連携)
      , ov_ret_dff5     =>  lt_ret_dff5           --  DFF5(IFRS連携)
      , ov_ret_dff6     =>  lt_ret_dff6           --  DFF6(仕訳作成)
      , ov_ret_dff7     =>  lt_ret_dff7           --  DFF7(リース判定処理)
      , ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      --  共通関数が正常終了しなかった場合
      lv_errmsg :=  SUBSTRB(
                      xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00094        --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00094_1      --  トークンコード1
                        , iv_token_value1   =>  cv_msg_cff_50323        --  トークン値1
                      )
                      || cv_msg_part || lv_errmsg                       --  共通関数から戻されたメッセージ
                      , 1, 5000
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    IF ( NVL( lt_ret_dff7, cv_dummy_code ) <> cv_lease_class_2 ) THEN
      --  リース判定処理が2以外の場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  アプリケーション短縮名
                      , iv_name           =>  cv_msg_cff_00292          --  メッセージコード
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  支払計画取得
    -- ===============================
    BEGIN
      SELECT  xch.contract_header_id                    contract_header_id        --  契約内部ID
            , xcl.contract_line_id                      contract_line_id          --  契約明細内部ID
            , xpp.payment_frequency                     payment_frequency         --  次回支払回数
            , xcl.asset_category                        asset_category            --  資産種類
            , xch.contract_number                       contract_number           --  契約番号
            , xch.lease_company                         lease_company             --  リース会社
            , xch.second_payment_date                   second_payment_date       --  2回目支払日
            , xch.third_payment_date                    third_payment_date        --  3回目以降支払日
            , xpp.lease_tax_charge                      lease_tax_charge          --  リース料_消費税
            , xpp.lease_deduction                       lease_deduction           --  リース控除額
            , xpp.lease_tax_deduction                   lease_tax_deduction       --  リース控除額_消費税
            , xpp.fin_debt_rem                          fin_debt_rem              --  ＦＩＮリース債務残
            , xpp.fin_debt                              fin_debt                  --  ＦＩＮリース債務額
            , xpp.fin_tax_debt                          fin_tax_debt              --  ＦＩＮリース債務額_消費税
            , xcl.tax_code                              tax_code                  --  税コード
            , xch.payment_frequency                     check_payment_frequency   --  変更前支払回数
            , xpp.lease_charge                          check_lease_charge        --  変更前リース料
      INTO    or_target_data.contract_header_id
            , or_target_data.contract_line_id
            , or_target_data.payment_frequency
            , or_target_data.asset_category
            , or_target_data.contract_number
            , or_target_data.lease_company
            , or_target_data.second_payment_date
            , or_target_data.third_payment_date
            , or_target_data.lease_tax_charge
            , or_target_data.lease_deduction
            , or_target_data.lease_tax_deduction
            , or_target_data.fin_debt_rem
            , or_target_data.fin_debt
            , or_target_data.fin_tax_debt
            , or_target_data.tax_code
            , lt_check_payment_frequency
            , lt_check_lease_charge
      FROM    xxcff_contract_headers      xch                   --  リース契約
            , xxcff_contract_lines        xcl                   --  リース契約明細
            , xxcff_pay_planning          xpp                   --  支払計画
      WHERE   xcl.contract_header_id      =   xch.contract_header_id
      AND     xcl.contract_line_id        =   xpp.contract_line_id
      AND     xcl.object_header_id        =   or_target_data.object_header_id
      AND     xpp.period_name             =   gt_ifrs_period_name
      AND     xpp.payment_frequency       <>  1                 --  支払回数1回目は除く
      ;
      --  変更前の消費税合計を取得
      SELECT  SUM( xpp.lease_tax_charge )               lease_tax_charge          --  リース料_消費税
      INTO    or_target_data.sum_old_tax_charge
      FROM    xxcff_pay_planning          xpp                   --  支払計画
      WHERE   xpp.contract_line_id    =   or_target_data.contract_line_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00165        --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00165_1      --  トークンコード1
                        , iv_token_value1   =>  cv_msg_cff_50088        --  トークン値1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===============================
    --  支払回数チェック
    -- ===============================
    IF ( gt_param_new_frequency < or_target_data.payment_frequency ) THEN
      --  変更後支払回数が、次回支払回数より小さい場合
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff                                    --  アプリケーション短縮名
                      , iv_name           =>  cv_msg_cff_00293                                  --  メッセージコード
                      , iv_token_name1    =>  cv_tok_cff_00293_1                                --  トークンコード1
                      , iv_token_value1   =>  TO_CHAR( or_target_data.payment_frequency - 1 )   --  トークン値1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    ELSE
      --  残り支払回数：変更後支払回数 - 次回支払回数 + 1
      or_target_data.remaining_frequency  :=  gt_param_new_frequency - or_target_data.payment_frequency + 1;
    END IF;
    --
    -- ===============================
    --  変更内容チェック
    -- ===============================
    IF ( gt_param_new_frequency = lt_check_payment_frequency AND gt_param_new_charge = lt_check_lease_charge ) THEN
      --  支払回数と、2回目以降のリース料がともに現行支払計画と代わらない場合は処理を中断
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff          --  アプリケーション短縮名
                      , iv_name           =>  cv_msg_cff_00294        --  メッセージコード
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ===============================
    --  資産カテゴリ取得
    -- ===============================
    xxcff_common1_pkg.chk_fa_category(
        iv_segment1       =>  or_target_data.asset_category       --  資産種類
      , iv_segment2       =>  NULL                                --  申告償却
      , iv_segment3       =>  NULL                                --  資産勘定
      , iv_segment4       =>  NULL                                --  償却科目
      , iv_segment5       =>  CEIL( gt_param_new_frequency / 12 ) --  耐用年数
      , iv_segment6       =>  NULL                                --  償却方法
      , iv_segment7       =>  or_target_data.lease_class          --  リース種別
      , on_category_id    =>  or_target_data.asset_category_id    --  資産カテゴリCCID
      , ov_errbuf         =>  lv_errbuf                           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode                          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg                           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      --  共通関数が正常終了しなかった場合
      lv_errmsg :=  SUBSTRB(
                      xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00094        --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00094_1      --  トークンコード1
                        , iv_token_value1   =>  cv_msg_cff_50303        --  トークン値1
                      )
                      || cv_msg_part || lv_errmsg                       --  共通関数から戻されたメッセージ
                      , 1, 5000
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    BEGIN
      SELECT  fcbd.deprn_method   deprn_method      --  償却方法
            , fca.segment1 || cv_separator ||
              fca.segment2 || cv_separator ||
              fca.segment3 || cv_separator ||
              fca.segment4 || cv_separator ||
              fca.segment5 || cv_separator ||
              fca.segment6 || cv_separator ||
              fca.segment7        category_code     --  資産カテゴリコード
      INTO    or_target_data.deprn_method
            , or_target_data.asset_category_code
      FROM    fa_category_book_defaults   fcbd      --  資産カテゴリ償却基準
            , fa_categories               fca       --  資産カテゴリ
      WHERE   fcbd.category_id      =   fca.category_id
      AND     fcbd.category_id      =   or_target_data.asset_category_id
      AND     fcbd.book_type_code   =   gt_prof_ifrs_lease_books
      AND     gd_ifrs_period_date BETWEEN fcbd.start_dpis
                                  AND     NVL( fcbd.end_dpis ,gd_ifrs_period_date )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  資産カテゴリが取得できなかった場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff                                --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00268                              --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00268_1                            --  トークンコード1
                        , iv_token_value1   =>  TO_CHAR( or_target_data.asset_category_id )   --  トークン値1
                        , iv_token_name2    =>  cv_tok_cff_00268_2                            --  トークンコード2
                        , iv_token_value2   =>  gt_prof_ifrs_lease_books                      --  トークン値2
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
  EXCEPTION
    WHEN global_process_expt THEN
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
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : 各種情報CSV出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
      ir_target_data    IN  g_target_rtype  --  対象データ
    , ov_errbuf         OUT VARCHAR2        --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2        --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2        --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    ln_request_id             NUMBER;           --  要求ID
    lb_wait_result            BOOLEAN;          --  コンカレント待機成否
    lv_phase                  VARCHAR2(50);     --  Phase
    lv_status                 VARCHAR2(50);     --  Status
    lv_dev_phase              VARCHAR2(50);     --  Dev_phase
    lv_dev_status             VARCHAR2(50);     --  Dev_status
    lv_message                VARCHAR2(5000);   --  Message
    lv_token_value            VARCHAR2(30);     --  メッセージ用トークン保持変数
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
    -- ============================================
    --  コンカレント起動：リース契約データCSV出力
    -- ============================================
    ln_request_id :=  fnd_request.submit_request(
                          application     =>  cv_app_kbn_ccp                  --  Application
                        , program         =>  cv_prg_contract_csv             --  Program
                        , description     =>  NULL                            --  Description
                        , start_time      =>  NULL                            --  Start_time
                        , sub_request     =>  FALSE                           --  Sub_request
                        , argument1       =>  ir_target_data.contract_number  --   1.契約番号
                        , argument2       =>  ir_target_data.lease_company    --   2.リース会社
                        , argument3       =>  NULL                            --   3.物件コード1
                        , argument4       =>  NULL                            --   4.物件コード2
                        , argument5       =>  NULL                            --   5.物件コード3
                        , argument6       =>  NULL                            --   6.物件コード4
                        , argument7       =>  NULL                            --   7.物件コード5
                        , argument8       =>  NULL                            --   8.物件コード6
                        , argument9       =>  NULL                            --   9.物件コード7
                        , argument10      =>  NULL                            --  10.物件コード8
                        , argument11      =>  NULL                            --  11.物件コード9
                        , argument12      =>  NULL                            --  12.物件コード10
                      );
    --
    --  起動失敗
    IF ( ln_request_id = 0 ) THEN
      lv_token_value  :=  cv_msg_cff_50203;
      RAISE conc_error_expt;
    END IF;
    --
    --  コンカレント起動のためコミット
    COMMIT;
    --
    --  コンカレントの終了待機
    lb_wait_result  :=  fnd_concurrent.wait_for_request(
                            request_id    =>  ln_request_id             --  Request_id
                          , interval      =>  gn_prof_conc_interval     --  Interval
                          , max_wait      =>  gn_prof_conc_max_wait     --  Max_wait
                          , phase         =>  lv_phase                  --  Phase
                          , status        =>  lv_status                 --  Status
                          , dev_phase     =>  lv_dev_phase              --  Dev_phase
                          , dev_status    =>  lv_dev_status             --  Dev_status
                          , message       =>  lv_message                --  Message
                        );
    --
    -- コンカレント待機失敗
    IF ( lb_wait_result = FALSE ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- コンカレント異常終了
    IF ( lv_dev_status = cv_dev_status_error ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- ============================================
    --  コンカレント起動：リース物件データCSV出力
    -- ============================================
    ln_request_id :=  fnd_request.submit_request(
                          application     =>  cv_app_kbn_ccp                  --  Application
                        , program         =>  cv_prg_object_csv               --  Program
                        , description     =>  NULL                            --  Description
                        , start_time      =>  NULL                            --  Start_time
                        , sub_request     =>  FALSE                           --  Sub_request
                        , argument1       =>  ir_target_data.contract_number  --   1.契約番号
                        , argument2       =>  ir_target_data.lease_company    --   2.リース会社
                        , argument3       =>  NULL                            --   3.物件コード1
                        , argument4       =>  NULL                            --   4.物件コード2
                        , argument5       =>  NULL                            --   5.物件コード3
                        , argument6       =>  NULL                            --   6.物件コード4
                        , argument7       =>  NULL                            --   7.物件コード5
                        , argument8       =>  NULL                            --   8.物件コード6
                        , argument9       =>  NULL                            --   9.物件コード7
                        , argument10      =>  NULL                            --  10.物件コード8
                        , argument11      =>  NULL                            --  11.物件コード9
                        , argument12      =>  NULL                            --  12.物件コード10
                      );
    --
    --  起動失敗
    IF ( ln_request_id = 0 ) THEN
      lv_token_value  :=  cv_msg_cff_50204;
      RAISE conc_error_expt;
    END IF;
    --
    --  コンカレント起動のためコミット
    COMMIT;
    --
    --  コンカレントの終了待機
    lb_wait_result  :=  fnd_concurrent.wait_for_request(
                            request_id    =>  ln_request_id             --  Request_id
                          , interval      =>  gn_prof_conc_interval     --  Interval
                          , max_wait      =>  gn_prof_conc_max_wait     --  Max_wait
                          , phase         =>  lv_phase                  --  Phase
                          , status        =>  lv_status                 --  Status
                          , dev_phase     =>  lv_dev_phase              --  Dev_phase
                          , dev_status    =>  lv_dev_status             --  Dev_status
                          , message       =>  lv_message                --  Message
                        );
    --
    -- コンカレント待機失敗
    IF ( lb_wait_result = FALSE ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- コンカレント異常終了
    IF ( lv_dev_status = cv_dev_status_error ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- ============================================
    --  コンカレント起動；リース支払計画データCSV出力
    -- ============================================
    ln_request_id :=  fnd_request.submit_request(
                          application     =>  cv_app_kbn_ccp                  --  Application
                        , program         =>  cv_prg_pay_planning_csv         --  Program
                        , description     =>  NULL                            --  Description
                        , start_time      =>  NULL                            --  Start_time
                        , sub_request     =>  FALSE                           --  Sub_request
                        , argument1       =>  ir_target_data.contract_number  --   1.契約番号
                        , argument2       =>  ir_target_data.lease_company    --   2.リース会社
                        , argument3       =>  NULL                            --   3.物件コード1
                        , argument4       =>  NULL                            --   4.物件コード2
                        , argument5       =>  NULL                            --   5.物件コード3
                        , argument6       =>  NULL                            --   6.物件コード4
                        , argument7       =>  NULL                            --   7.物件コード5
                        , argument8       =>  NULL                            --   8.物件コード6
                        , argument9       =>  NULL                            --   9.物件コード7
                        , argument10      =>  NULL                            --  10.物件コード8
                        , argument11      =>  NULL                            --  11.物件コード9
                        , argument12      =>  NULL                            --  12.物件コード10
                      );
    --
    --  起動失敗
    IF ( ln_request_id = 0 ) THEN
      lv_token_value  :=  cv_msg_cff_50205;
      RAISE conc_error_expt;
    END IF;
    --
    --  コンカレント起動のためコミット
    COMMIT;
    --
    --  コンカレントの終了待機
    lb_wait_result  :=  fnd_concurrent.wait_for_request(
                            request_id    =>  ln_request_id             --  Request_id
                          , interval      =>  gn_prof_conc_interval     --  Interval
                          , max_wait      =>  gn_prof_conc_max_wait     --  Max_wait
                          , phase         =>  lv_phase                  --  Phase
                          , status        =>  lv_status                 --  Status
                          , dev_phase     =>  lv_dev_phase              --  Dev_phase
                          , dev_status    =>  lv_dev_status             --  Dev_status
                          , message       =>  lv_message                --  Message
                        );
    --
    -- コンカレント待機失敗
    IF ( lb_wait_result = FALSE ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- コンカレント異常終了
    IF ( lv_dev_status = cv_dev_status_error ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- ============================================
    --  コンカレント起動：リース会計基準情報CSV出力
    -- ============================================
    ln_request_id :=  fnd_request.submit_request(
                          application     =>  cv_app_kbn_ccp                  --  Application
                        , program         =>  cv_prg_accounting_csv           --  Program
                        , description     =>  NULL                            --  Description
                        , start_time      =>  NULL                            --  Start_time
                        , sub_request     =>  FALSE                           --  Sub_request
                        , argument1       =>  ir_target_data.contract_number  --   1.契約番号
                        , argument2       =>  ir_target_data.lease_company    --   2.リース会社
                        , argument3       =>  NULL                            --   3.物件コード1
                        , argument4       =>  NULL                            --   4.物件コード2
                        , argument5       =>  NULL                            --   5.物件コード3
                        , argument6       =>  NULL                            --   6.物件コード4
                        , argument7       =>  NULL                            --   7.物件コード5
                        , argument8       =>  NULL                            --   8.物件コード6
                        , argument9       =>  NULL                            --   9.物件コード7
                        , argument10      =>  NULL                            --  10.物件コード8
                        , argument11      =>  NULL                            --  11.物件コード9
                        , argument12      =>  NULL                            --  12.物件コード10
                      );
    --
    --  起動失敗
    IF ( ln_request_id = 0 ) THEN
      lv_token_value  :=  cv_msg_cff_50206;
      RAISE conc_error_expt;
    END IF;
    --
    --  コンカレント起動のためコミット
    COMMIT;
    --
    --  コンカレントの終了待機
    lb_wait_result  :=  fnd_concurrent.wait_for_request(
                            request_id    =>  ln_request_id             --  Request_id
                          , interval      =>  gn_prof_conc_interval     --  Interval
                          , max_wait      =>  gn_prof_conc_max_wait     --  Max_wait
                          , phase         =>  lv_phase                  --  Phase
                          , status        =>  lv_status                 --  Status
                          , dev_phase     =>  lv_dev_phase              --  Dev_phase
                          , dev_status    =>  lv_dev_status             --  Dev_status
                          , message       =>  lv_message                --  Message
                        );
    --
    -- コンカレント待機失敗
    IF ( lb_wait_result = FALSE ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- コンカレント異常終了
    IF ( lv_dev_status = cv_dev_status_error ) THEN
      RAISE conc_error_expt;
    END IF;
    --
  EXCEPTION
    -- *** コンカレント起動例外ハンドラ ***
    WHEN conc_error_expt THEN
      IF ( ln_request_id = 0 ) THEN
        --  コンカレントの起動に失敗した場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff              --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00197            --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00197_1          --  トークンコード1
                        , iv_token_value1   =>  lv_token_value              --  トークン値1
                      );
      ELSIF ( lb_wait_result = FALSE ) THEN
        --  コンカレントの待機に失敗した場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff              --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00198            --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00198_1          --  トークンコード1
                        , iv_token_value1   =>  TO_CHAR( ln_request_id )    --  トークン値1
                      );
      ELSIF ( lv_dev_status = cv_dev_status_error ) THEN
        --  コンカレントの結果がエラーの場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff              --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00199            --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00199_1          --  トークンコード1
                        , iv_token_value1   =>  TO_CHAR( ln_request_id )    --  トークン値1
                      );
      END IF;
      --
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  :=  cv_status_error;
    WHEN global_process_expt THEN
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
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : create_pay_planning
   * Description      : 新支払計画データ作成(A-4)
   ***********************************************************************************/
  PROCEDURE create_pay_planning(
      ior_target_data   IN OUT  g_target_rtype        --  対象データ
    , ot_new_pay_plan   OUT     g_new_pay_plan_ttype  --  新支払計画
    , ov_errbuf         OUT     VARCHAR2              --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT     VARCHAR2              --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT     VARCHAR2              --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_pay_planning'; -- プログラム名
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
    --  初期化
    ot_new_pay_plan.DELETE;
    --
    -- ===============================
    --  割引率取得
    -- ===============================
    BEGIN
      --  残り支払回数に基づく割引率
      SELECT  CASE  CEIL( ior_target_data.remaining_frequency / 12 )
                WHEN  1   THEN  xdrm.discount_rate_01
                WHEN  2   THEN  xdrm.discount_rate_02
                WHEN  3   THEN  xdrm.discount_rate_03
                WHEN  4   THEN  xdrm.discount_rate_04
                WHEN  5   THEN  xdrm.discount_rate_05
                WHEN  6   THEN  xdrm.discount_rate_06
                WHEN  7   THEN  xdrm.discount_rate_07
                WHEN  8   THEN  xdrm.discount_rate_08
                WHEN  9   THEN  xdrm.discount_rate_09
                WHEN  10  THEN  xdrm.discount_rate_10
                WHEN  11  THEN  xdrm.discount_rate_11
                WHEN  12  THEN  xdrm.discount_rate_12
                WHEN  13  THEN  xdrm.discount_rate_13
                WHEN  14  THEN  xdrm.discount_rate_14
                WHEN  15  THEN  xdrm.discount_rate_15
                WHEN  16  THEN  xdrm.discount_rate_16
                WHEN  17  THEN  xdrm.discount_rate_17
                WHEN  18  THEN  xdrm.discount_rate_18
                WHEN  19  THEN  xdrm.discount_rate_19
                WHEN  20  THEN  xdrm.discount_rate_20
                WHEN  21  THEN  xdrm.discount_rate_21
                WHEN  22  THEN  xdrm.discount_rate_22
                WHEN  23  THEN  xdrm.discount_rate_23
                WHEN  24  THEN  xdrm.discount_rate_24
                WHEN  25  THEN  xdrm.discount_rate_25
                WHEN  26  THEN  xdrm.discount_rate_26
                WHEN  27  THEN  xdrm.discount_rate_27
                WHEN  28  THEN  xdrm.discount_rate_28
                WHEN  29  THEN  xdrm.discount_rate_29
                WHEN  30  THEN  xdrm.discount_rate_30
                WHEN  31  THEN  xdrm.discount_rate_31
                WHEN  32  THEN  xdrm.discount_rate_32
                WHEN  33  THEN  xdrm.discount_rate_33
                WHEN  34  THEN  xdrm.discount_rate_34
                WHEN  35  THEN  xdrm.discount_rate_35
                WHEN  36  THEN  xdrm.discount_rate_36
                WHEN  37  THEN  xdrm.discount_rate_37
                WHEN  38  THEN  xdrm.discount_rate_38
                WHEN  39  THEN  xdrm.discount_rate_39
                WHEN  40  THEN  xdrm.discount_rate_40
                WHEN  41  THEN  xdrm.discount_rate_41
                WHEN  42  THEN  xdrm.discount_rate_42
                WHEN  43  THEN  xdrm.discount_rate_43
                WHEN  44  THEN  xdrm.discount_rate_44
                WHEN  45  THEN  xdrm.discount_rate_45
                WHEN  46  THEN  xdrm.discount_rate_46
                WHEN  47  THEN  xdrm.discount_rate_47
                WHEN  48  THEN  xdrm.discount_rate_48
                WHEN  49  THEN  xdrm.discount_rate_49
                WHEN  50  THEN  xdrm.discount_rate_50
              END           discount_rate
      INTO    ior_target_data.discount_rate
      FROM    xxcff_discount_rate_mst   xdrm
      WHERE   xdrm.application_date   =   gd_ifrs_period_date
      ;
      IF ( ior_target_data.discount_rate IS NULL ) THEN
        RAISE NO_DATA_FOUND;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff                                --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00089                              --  メッセージコード
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===============================
    --  現在価値算出
    -- ===============================
    ior_target_data.present_value :=  0;
    <<calc_loop>>
    FOR ln_count IN 1 .. ior_target_data.remaining_frequency LOOP
      ior_target_data.present_value :=  ior_target_data.present_value + ( gt_param_new_charge - ior_target_data.lease_deduction ) / POWER( 1 + ( ior_target_data.discount_rate / 100 / 12 ), ln_count );
    END LOOP  calc_loop;
    --  結果を四捨五入
    ior_target_data.present_value :=  ROUND( ior_target_data.present_value, 0 );
    --
    -- ===============================
    --  新支払計画を作成
    -- ===============================
    <<pay_plan_loop>>     --  残り支払回数分ループ
    FOR ln_count IN 1 .. ior_target_data.remaining_frequency LOOP
      --  1.契約明細内部ID
      ot_new_pay_plan( ln_count ).contract_line_id        :=  ior_target_data.contract_line_id;
      --
      --  2.支払回数：次回支払回数から、残り回数分1ずつ増分
      ot_new_pay_plan( ln_count ).payment_frequency       :=  ior_target_data.payment_frequency + ln_count - 1;
      --
      --  3.契約内部ID
      ot_new_pay_plan( ln_count ).contract_header_id      :=  ior_target_data.contract_header_id;
      --
      --  4.会計期間：A-1で取得した会計期間名から、残り回数分1月ずつ増分
      ot_new_pay_plan( ln_count ).period_name             :=  TO_CHAR( ADD_MONTHS( TO_DATE( gt_ifrs_period_name, cv_date_format ), ln_count - 1 ), cv_date_format );
      --
      --  5.支払日
      IF ( ior_target_data.third_payment_date = 31 ) THEN
        --  3回目以降支払日が31にの場合、2回目支払日に月加算し、各月の最終日
        ot_new_pay_plan( ln_count ).payment_date        :=  LAST_DAY( ADD_MONTHS( ior_target_data.second_payment_date, ior_target_data.payment_frequency + ln_count - 3 ) );
      ELSE
        --  31日以外の場合は、2回目支払日に月加算
        ot_new_pay_plan( ln_count ).payment_date        :=  ADD_MONTHS( ior_target_data.second_payment_date, ior_target_data.payment_frequency + ln_count - 3 );
      END IF;
      --
      --  6.リース料：パラメータ．変更後リース料
      ot_new_pay_plan( ln_count ).lease_charge            :=  gt_param_new_charge;
      --
      --  7.リース料_消費税：パラメータ．変更後税額
      ot_new_pay_plan( ln_count ).lease_tax_charge        :=  gt_param_new_tax_charge;
      --
      --  8.リース控除額：支払回数2回目以降は全月同値
      ot_new_pay_plan( ln_count ).lease_deduction         :=  ior_target_data.lease_deduction;
      --
      --  9.リース控除額_消費税：支払回数2回目以降は全月同値
      ot_new_pay_plan( ln_count ).lease_tax_deduction     :=  ior_target_data.lease_tax_deduction;
      --
      --  10.ＯＰリース料：6.リース料 - 8.リース控除額
      ot_new_pay_plan( ln_count ).op_charge               :=  ot_new_pay_plan( ln_count ).lease_charge - ot_new_pay_plan( ln_count ).lease_deduction;
      --
      --  11.ＯＰリース料額_消費税：7.リース料_消費税 - 9.リース控除額_消費税
      ot_new_pay_plan( ln_count ).op_tax_charge           :=  ot_new_pay_plan( ln_count ).lease_tax_charge - ot_new_pay_plan( ln_count ).lease_tax_deduction;
      --
      --  14.ＦＩＮリース支払利息
      IF ( ln_count = 1 ) THEN
        --  上記で算出した現在価値 * 上記で取得した割引率
        ot_new_pay_plan( ln_count ).fin_interest_due      :=  ROUND( ior_target_data.present_value * ROUND( ( ior_target_data.discount_rate / 100 / 12 ), 7 ), 0 );
      ELSE
        --  1回前の 15.FINリース債務残 * 割引率
        ot_new_pay_plan( ln_count ).fin_interest_due      :=  ROUND( ot_new_pay_plan( ln_count - 1 ).fin_debt_rem * ROUND( ( ior_target_data.discount_rate / 100 / 12 ), 7 ), 0 );
      END IF;
      --
      --  12.ＦＩＮリース債務額：6.リース料 - 8.リース控除額 - 14.ＦＩＮリース支払利息
      ot_new_pay_plan( ln_count ).fin_debt                :=  ot_new_pay_plan( ln_count ).lease_charge - ot_new_pay_plan( ln_count ).lease_deduction - ot_new_pay_plan( ln_count ).fin_interest_due;
      --
      --  13.ＦＩＮリース債務額_消費税：7.リース料_消費税 - 9.リース控除額_消費税
      ot_new_pay_plan( ln_count ).fin_tax_debt            :=  ot_new_pay_plan( ln_count ).lease_tax_charge - ot_new_pay_plan( ln_count ).lease_tax_deduction;
      --
      --  15.ＦＩＮリース債務残
      IF ( ln_count = 1 ) THEN
        --  上記で算出した現在価値 - 12.ＦＩＮリース債務額
        ot_new_pay_plan( ln_count ).fin_debt_rem          :=  ior_target_data.present_value - ot_new_pay_plan( ln_count ).fin_debt;
      ELSE
        --  1回前の 15.ＦＩＮリース債務残 - 12.ＦＩＮリース債務額
        ot_new_pay_plan( ln_count ).fin_debt_rem          :=  ot_new_pay_plan( ln_count - 1 ).fin_debt_rem - ot_new_pay_plan( ln_count ).fin_debt;
      END IF;
      IF ( ot_new_pay_plan( ln_count ).fin_debt_rem < 0 ) THEN
        --  マイナス値となった場合は0に置換
        ot_new_pay_plan( ln_count ).fin_debt_rem          :=  0;
      END IF;
      IF ( ln_count = ior_target_data.remaining_frequency AND ot_new_pay_plan( ln_count ).fin_debt_rem <> 0 ) THEN
        --  最終処理で、15.ＦＩＮリース債務が0になっていない場合
        --  12.ＦＩＮリース債務額 に 15.ＦＩＮリース債務残を加算
        ot_new_pay_plan( ln_count ).fin_debt              :=  ot_new_pay_plan( ln_count ).fin_debt + ot_new_pay_plan( ln_count ).fin_debt_rem;
        --  14.ＦＩＮリース支払利息 から 15.ＦＩＮリース債務残を減算
        ot_new_pay_plan( ln_count ).fin_interest_due      :=  ot_new_pay_plan( ln_count ).fin_interest_due - ot_new_pay_plan( ln_count ).fin_debt_rem;
        --  15.ＦＩＮリース債務残を0に置換
        ot_new_pay_plan( ln_count ).fin_debt_rem          :=  0;
      END IF;
      --
      --  16.ＦＩＮリース債務残_消費税
      IF ( ln_count = 1 ) THEN
        --  13.ＦＩＮリース債務額_消費税 * ( 残り支払回数 - 1 )
        ot_new_pay_plan( ln_count ).fin_tax_debt_rem      :=  ot_new_pay_plan( ln_count ).fin_tax_debt * ( ior_target_data.remaining_frequency - 1 );
      ELSE
        --  1回前のFINリース債務残_消費税 - 13.ＦＩＮリース債務額_消費税
        ot_new_pay_plan( ln_count ).fin_tax_debt_rem      :=  ot_new_pay_plan( ln_count - 1 ).fin_tax_debt_rem - ot_new_pay_plan( ln_count ).fin_tax_debt;
      END IF;
      IF ( ot_new_pay_plan( ln_count ).fin_tax_debt_rem < 0 ) THEN
        --  マイナス値となった場合は0に置換
        ot_new_pay_plan( ln_count ).fin_tax_debt_rem      :=  0;
      END IF;
      --
      --  17.会計IFフラグ：固定値1
      ot_new_pay_plan( ln_count ).accounting_if_flag      :=  cv_flag_1;
      --
      --  18.照合済フラグ：固定値1
      ot_new_pay_plan( ln_count ).payment_match_flag      :=  cv_flag_1;
      --
      --  19.作成者
      ot_new_pay_plan( ln_count ).created_by              :=  cn_created_by;
      --
      --  20.作成日
      ot_new_pay_plan( ln_count ).creation_date           :=  cd_creation_date;
      --
      --  21.最終更新者
      ot_new_pay_plan( ln_count ).last_updated_by         :=  cn_last_updated_by;
      --
      --  22.最終更新日
      ot_new_pay_plan( ln_count ).last_update_date        :=  cd_last_update_date;
      --
      --  23.最終更新ログイン
      ot_new_pay_plan( ln_count ).last_update_login       :=  cn_last_update_login;
      --
      --  24.要求ID
      ot_new_pay_plan( ln_count ).request_id              :=  cn_request_id;
      --
      --  25.コンカレント・プログラム・アプリケーションID
      ot_new_pay_plan( ln_count ).program_application_id  :=  cn_program_application_id;
      --
      --  26.コンカレント・プログラムID
      ot_new_pay_plan( ln_count ).program_id              :=  cn_program_id;
      --
      --  27.プログラム更新日
      ot_new_pay_plan( ln_count ).program_update_date     :=  cd_program_update_date;
      --
      --  28.リース債務額_再リース
      ot_new_pay_plan( ln_count ).debt_re                 :=  NULL;
      --
      --  29.リース支払利息_再リース
      ot_new_pay_plan( ln_count ).interest_due_re         :=  NULL;
      --
      --  30.リース債務残_再リース
      ot_new_pay_plan( ln_count ).debt_rem_re             :=  NULL;
    END LOOP  pay_plan_loop;
    --
  EXCEPTION
    WHEN global_process_expt THEN
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
  END create_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : ins_backup
   * Description      : データバックアップ(A-5)
   ***********************************************************************************/
  PROCEDURE ins_backup(
      ir_target_data    IN  g_target_rtype  --  対象データ
    , ov_errbuf         OUT VARCHAR2        --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2        --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2        --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_backup'; -- プログラム名
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
    ln_run_line_num       NUMBER;           --  実行枝番
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
    -- ===============================
    --  実行枝番取得
    -- ===============================
    SELECT  NVL( MAX( xchb.run_line_num ), 0 ) + 1    run_line_num      --  実行枝番(最大実行枝番+1)
    INTO    ln_run_line_num
    FROM    xxcff_contract_lines_bk       xchb
    WHERE   xchb.run_period_name      =   gt_ifrs_period_name
    AND     xchb.contract_header_id   =   ir_target_data.contract_header_id
    ;
    --
    INSERT INTO xxcff_contract_headers_bk(
        contract_header_id                --   1.契約内部ID
      , contract_number                   --   2.契約番号
      , lease_class                       --   3.リース種別
      , lease_type                        --   4.リース区分
      , lease_company                     --   5.リース会社
      , re_lease_times                    --   6.再リース回数
      , comments                          --   7.件名
      , contract_date                     --   8.リース契約日
      , payment_frequency                 --   9.支払回数
      , payment_type                      --  10.頻度
      , payment_years                     --  11.年数
      , lease_start_date                  --  12.リース開始日
      , lease_end_date                    --  13.リース終了日
      , first_payment_date                --  14.初回支払日
      , second_payment_date               --  15.回目支払日
      , third_payment_date                --  16.回目以降支払日
      , start_period_name                 --  17.費用計上開始会計期間
      , lease_payment_flag                --  18.リース支払計画完了フラグ
      , tax_code                          --  19.税金コード
      , run_period_name                   --  20.実行会計期間
      , run_line_num                      --  21.実行枝番
      , created_by                        --  22.作成者
      , creation_date                     --  23.作成日
      , last_updated_by                   --  24.最終更新者
      , last_update_date                  --  25.最終更新日
      , last_update_login                 --  26.最終更新ログイン
      , request_id                        --  27.要求ID
      , program_application_id            --  28.コンカレント・プログラム・アプリケーションID
      , program_id                        --  29.コンカレント・プログラムID
      , program_update_date               --  30.プログラム更新日
    )
    SELECT
        xch.contract_header_id            --   1.契約内部ID
      , xch.contract_number               --   2.契約番号
      , xch.lease_class                   --   3.リース種別
      , xch.lease_type                    --   4.リース区分
      , xch.lease_company                 --   5.リース会社
      , xch.re_lease_times                --   6.再リース回数
      , xch.comments                      --   7.件名
      , xch.contract_date                 --   8.リース契約日
      , xch.payment_frequency             --   9.支払回数
      , xch.payment_type                  --  10.頻度
      , xch.payment_years                 --  11.年数
      , xch.lease_start_date              --  12.リース開始日
      , xch.lease_end_date                --  13.リース終了日
      , xch.first_payment_date            --  14.初回支払日
      , xch.second_payment_date           --  15.回目支払日
      , xch.third_payment_date            --  16.回目以降支払日
      , xch.start_period_name             --  17.費用計上開始会計期間
      , xch.lease_payment_flag            --  18.リース支払計画完了フラグ
      , xch.tax_code                      --  19.税金コード
      , gt_ifrs_period_name               --  20.実行会計期間
      , ln_run_line_num                   --  21.実行枝番
      , cn_created_by                     --  22.作成者
      , cd_creation_date                  --  23.作成日
      , cn_last_updated_by                --  24.最終更新者
      , cd_last_update_date               --  25.最終更新日
      , cn_last_update_login              --  26.最終更新ログイン
      , cn_request_id                     --  27.要求ID
      , cn_program_application_id         --  28.コンカレント・プログラム・アプリケーションID
      , cn_program_id                     --  29.コンカレント・プログラムID
      , cd_program_update_date            --  30.プログラム更新日
    FROM    xxcff_contract_headers    xch
    WHERE   xch.contract_header_id    =   ir_target_data.contract_header_id
    ;
    --
    INSERT INTO xxcff_contract_lines_bk(
        contract_line_id                  --   1.契約明細内部ID
      , contract_header_id                --   2.契約内部ID
      , contract_line_num                 --   3.契約枝番
      , contract_status                   --   4.契約ステータス
      , first_charge                      --   5.初回月額リース料_リース料
      , first_tax_charge                  --   6.初回消費税額_リース料
      , first_total_charge                --   7.初回計_リース料
      , second_charge                     --   8.回目以降月額リース料_リース料
      , second_tax_charge                 --   9.回目以降消費税額_リース料
      , second_total_charge               --  10.回目以降計_リース料
      , first_deduction                   --  11.初回月額リース料_控除額
      , first_tax_deduction               --  12.初回月額消費税額_控除額
      , first_total_deduction             --  13.初回計_控除額
      , second_deduction                  --  14.回目以降月額リース料_控除額
      , second_tax_deduction              --  15.回目以降消費税額_控除額
      , second_total_deduction            --  16.回目以降計_控除額
      , gross_charge                      --  17.総額リース料_リース料
      , gross_tax_charge                  --  18.総額消費税_リース料
      , gross_total_charge                --  19.総額計_リース料
      , gross_deduction                   --  20.総額リース料_控除額
      , gross_tax_deduction               --  21.総額消費税_控除額
      , gross_total_deduction             --  22.総額計_控除額
      , lease_kind                        --  23.リース種類
      , estimated_cash_price              --  24.見積現金購入価額
      , present_value_discount_rate       --  25.現在価値割引率
      , present_value                     --  26.現在価値
      , life_in_months                    --  27.法定耐用年数
      , original_cost                     --  28.取得価額
      , calc_interested_rate              --  29.計算利子率
      , object_header_id                  --  30.物件内部ID
      , asset_category                    --  31.資産種類
      , expiration_date                   --  32.満了日
      , cancellation_date                 --  33.中途解約日
      , vd_if_date                        --  34.リース契約情報連携日
      , info_sys_if_date                  --  35.リース管理情報連携日
      , first_installation_address        --  36.初回設置場所
      , first_installation_place          --  37.初回設置先
      , run_period_name                   --  38.実行会計期間
      , run_line_num                      --  39.実行枝番
      , created_by                        --  40.作成者
      , creation_date                     --  41.作成日
      , last_updated_by                   --  42.最終更新者
      , last_update_date                  --  43.最終更新日
      , last_update_login                 --  44.最終更新ログイン
      , request_id                        --  45.要求ID
      , program_application_id            --  46.コンカレント・プログラム・アプリケーションID
      , program_id                        --  47.コンカレント・プログラムID
      , program_update_date               --  48.プログラム更新日
      , tax_code                          --  49.税金コード
      , original_cost_type1               --  50.リース負債額_原契約
      , original_cost_type2               --  51.リース負債額_再リース
    )
    SELECT
        xcl.contract_line_id              --   1.契約明細内部ID
      , xcl.contract_header_id            --   2.契約内部ID
      , xcl.contract_line_num             --   3.契約枝番
      , xcl.contract_status               --   4.契約ステータス
      , xcl.first_charge                  --   5.初回月額リース料_リース料
      , xcl.first_tax_charge              --   6.初回消費税額_リース料
      , xcl.first_total_charge            --   7.初回計_リース料
      , xcl.second_charge                 --   8.回目以降月額リース料_リース料
      , xcl.second_tax_charge             --   9.回目以降消費税額_リース料
      , xcl.second_total_charge           --  10.回目以降計_リース料
      , xcl.first_deduction               --  11.初回月額リース料_控除額
      , xcl.first_tax_deduction           --  12.初回月額消費税額_控除額
      , xcl.first_total_deduction         --  13.初回計_控除額
      , xcl.second_deduction              --  14.回目以降月額リース料_控除額
      , xcl.second_tax_deduction          --  15.回目以降消費税額_控除額
      , xcl.second_total_deduction        --  16.回目以降計_控除額
      , xcl.gross_charge                  --  17.総額リース料_リース料
      , xcl.gross_tax_charge              --  18.総額消費税_リース料
      , xcl.gross_total_charge            --  19.総額計_リース料
      , xcl.gross_deduction               --  20.総額リース料_控除額
      , xcl.gross_tax_deduction           --  21.総額消費税_控除額
      , xcl.gross_total_deduction         --  22.総額計_控除額
      , xcl.lease_kind                    --  23.リース種類
      , xcl.estimated_cash_price          --  24.見積現金購入価額
      , xcl.present_value_discount_rate   --  25.現在価値割引率
      , xcl.present_value                 --  26.現在価値
      , xcl.life_in_months                --  27.法定耐用年数
      , xcl.original_cost                 --  28.取得価額
      , xcl.calc_interested_rate          --  29.計算利子率
      , xcl.object_header_id              --  30.物件内部ID
      , xcl.asset_category                --  31.資産種類
      , xcl.expiration_date               --  32.満了日
      , xcl.cancellation_date             --  33.中途解約日
      , xcl.vd_if_date                    --  34.リース契約情報連携日
      , xcl.info_sys_if_date              --  35.リース管理情報連携日
      , xcl.first_installation_address    --  36.初回設置場所
      , xcl.first_installation_place      --  37.初回設置先
      , gt_ifrs_period_name               --  38.実行会計期間
      , ln_run_line_num                   --  39.実行枝番
      , cn_created_by                     --  40.作成者
      , cd_creation_date                  --  41.作成日
      , cn_last_updated_by                --  42.最終更新者
      , cd_last_update_date               --  43.最終更新日
      , cn_last_update_login              --  44.最終更新ログイン
      , cn_request_id                     --  45.要求ID
      , cn_program_application_id         --  46.コンカレント・プログラム・アプリケーションID
      , cn_program_id                     --  47.コンカレント・プログラムID
      , cd_program_update_date            --  48.プログラム更新日
      , xcl.tax_code                      --  49.税金コード
      , xcl.original_cost_type1           --  50.リース負債額_原契約
      , xcl.original_cost_type2           --  51.リース負債額_再リース
    FROM    xxcff_contract_lines      xcl
    WHERE   xcl.contract_line_id    =   ir_target_data.contract_line_id
    ;
    --
    INSERT INTO xxcff_pay_planning_bk(
        contract_line_id                  --   1.契約明細内部ID
      , payment_frequency                 --   2.支払回数
      , contract_header_id                --   3.契約内部ID
      , period_name                       --   4.会計期間
      , payment_date                      --   5.支払日
      , lease_charge                      --   6.リース料
      , lease_tax_charge                  --   7.リース料_消費税
      , lease_deduction                   --   8.リース控除額
      , lease_tax_deduction               --   9.リース控除額_消費税
      , op_charge                         --  10.ＯＰリース料
      , op_tax_charge                     --  11.ＯＰリース料額_消費税
      , fin_debt                          --  12.ＦＩＮリース債務額
      , fin_tax_debt                      --  13.ＦＩＮリース債務額_消費税
      , fin_interest_due                  --  14.ＦＩＮリース支払利息
      , fin_debt_rem                      --  15.ＦＩＮリース債務残
      , fin_tax_debt_rem                  --  16.ＦＩＮリース債務残_消費税
      , accounting_if_flag                --  17.会計ＩＦフラグ
      , payment_match_flag                --  18.照合済フラグ
      , run_period_name                   --  19.実行会計期間
      , run_line_num                      --  20.実行枝番
      , created_by                        --  21.作成者
      , creation_date                     --  22.作成日
      , last_updated_by                   --  23.最終更新者
      , last_update_date                  --  24.最終更新日
      , last_update_login                 --  25.最終更新ログイン
      , request_id                        --  26.要求ID
      , program_application_id            --  27.コンカレント・プログラム・アプリケーションID
      , program_id                        --  28.コンカレント・プログラムID
      , program_update_date               --  29.プログラム更新日
      , debt_re                           --  30.リース債務額_再リース
      , interest_due_re                   --  31.リース支払利息_再リース
      , debt_rem_re                       --  32.リース債務残_再リース
    )
    SELECT
        xpp.contract_line_id              --   1.契約明細内部ID
      , xpp.payment_frequency             --   2.支払回数
      , xpp.contract_header_id            --   3.契約内部ID
      , xpp.period_name                   --   4.会計期間
      , xpp.payment_date                  --   5.支払日
      , xpp.lease_charge                  --   6.リース料
      , xpp.lease_tax_charge              --   7.リース料_消費税
      , xpp.lease_deduction               --   8.リース控除額
      , xpp.lease_tax_deduction           --   9.リース控除額_消費税
      , xpp.op_charge                     --  10.ＯＰリース料
      , xpp.op_tax_charge                 --  11.ＯＰリース料額_消費税
      , xpp.fin_debt                      --  12.ＦＩＮリース債務額
      , xpp.fin_tax_debt                  --  13.ＦＩＮリース債務額_消費税
      , xpp.fin_interest_due              --  14.ＦＩＮリース支払利息
      , xpp.fin_debt_rem                  --  15.ＦＩＮリース債務残
      , xpp.fin_tax_debt_rem              --  16.ＦＩＮリース債務残_消費税
      , xpp.accounting_if_flag            --  17.会計ＩＦフラグ
      , xpp.payment_match_flag            --  18.照合済フラグ
      , gt_ifrs_period_name               --  19.実行会計期間
      , ln_run_line_num                   --  20.実行枝番
      , cn_created_by                     --  21.作成者
      , cd_creation_date                  --  22.作成日
      , cn_last_updated_by                --  23.最終更新者
      , cd_last_update_date               --  24.最終更新日
      , cn_last_update_login              --  25.最終更新ログイン
      , cn_request_id                     --  26.要求ID
      , cn_program_application_id         --  27.コンカレント・プログラム・アプリケーションID
      , cn_program_id                     --  28.コンカレント・プログラムID
      , cd_program_update_date            --  29.プログラム更新日
      , xpp.debt_re                       --  30.リース債務額_再リース
      , xpp.interest_due_re               --  31.リース支払利息_再リース
      , xpp.debt_rem_re                   --  32.リース債務残_再リース
    FROM    xxcff_pay_planning        xpp
    WHERE   xpp.contract_line_id      =   ir_target_data.contract_line_id
    ;
  EXCEPTION
    WHEN global_process_expt THEN
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
  END ins_backup;
--
  /**********************************************************************************
   * Procedure Name   : replace_pay_planning
   * Description      : 新支払計画登録(A-6)
   ***********************************************************************************/
  PROCEDURE replace_pay_planning(
      ir_target_data    IN  g_target_rtype          --  対象データ
    , it_new_pay_plan   IN  g_new_pay_plan_ttype    --  新支払計画
    , ov_errbuf         OUT VARCHAR2                --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2                --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2                --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'replace_pay_planning'; -- プログラム名
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
    ln_dummy            NUMBER;             --  ダミー変数
--
    -- *** ローカル・カーソル ***
    CURSOR  xpp_lock_cur
    IS
      SELECT  xpp.contract_line_id
      FROM    xxcff_pay_planning  xpp
      WHERE   xpp.contract_line_id    =   ir_target_data.contract_line_id
      FOR UPDATE NOWAIT
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
    -- ===============================
    --  対象データロック
    -- ===============================
    BEGIN
      OPEN  xpp_lock_cur;
      CLOSE xpp_lock_cur;
    EXCEPTION
      WHEN lock_expt THEN
        --  ロックの取得に失敗した場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00007        --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00007_1      --  トークンコード1
                        , iv_token_value1   =>  cv_msg_cff_50088        --  トークン値1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ============================================
    --  支払計画 元データの削除
    -- ============================================
    --  該当契約明細内部IDで、次回支払回数以降のデータを削除
    DELETE  xxcff_pay_planning    xpp
    WHERE   xpp.contract_line_id    =   ir_target_data.contract_line_id
    AND     xpp.payment_frequency   >=  ir_target_data.payment_frequency
    ;
    --
    -- ============================================
    --  新支払計画登録
    -- ============================================
    BEGIN
      --  A-4で生成した支払計画を挿入
      FORALL ins_cnt IN 1 .. it_new_pay_plan.COUNT
        INSERT INTO xxcff_pay_planning VALUES it_new_pay_plan(ins_cnt)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff              --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00102            --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00102_1          --  トークンコード1
                        , iv_token_value1   =>  cv_msg_cff_50088            --  トークン値1
                        , iv_token_name2    =>  cv_tok_cff_00102_2          --  トークンコード2
                        , iv_token_value2   =>  SQLERRM                     --  トークン値2
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      IF ( xpp_lock_cur%ISOPEN ) THEN
        CLOSE xpp_lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( xpp_lock_cur%ISOPEN ) THEN
        CLOSE xpp_lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( xpp_lock_cur%ISOPEN ) THEN
        CLOSE xpp_lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( xpp_lock_cur%ISOPEN ) THEN
        CLOSE xpp_lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END replace_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : upd_contract_data
   * Description      : 契約情報更新(A-7)
   ***********************************************************************************/
  PROCEDURE upd_contract_data(
      ior_target_data   IN OUT  g_target_rtype        --  対象データ
    , ov_errbuf         OUT VARCHAR2                  --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2                  --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2                  --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_contract_data'; -- プログラム名
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
    ln_dummy                        NUMBER;             --  ダミー変数
    ln_sum_lease_charge             NUMBER;             --  リース料（合計）
    ln_sum_lease_tax_charge         NUMBER;             --  消費税額（合計）
    ln_sum_lease_deduction          NUMBER;             --  リース料_控除額（合計）
    ln_sum_lease_tax_deduction      NUMBER;             --  消費税_控除額（合計）
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
    -- ===============================
    --  対象データロック
    -- ===============================
    BEGIN
      SELECT  1
      INTO    ln_dummy
      FROM    xxcff_contract_headers    xch
      WHERE   xch.contract_header_id  =   ior_target_data.contract_header_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN lock_expt THEN
        --  ロックの取得に失敗した場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00007        --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00007_1      --  トークンコード1
                        , iv_token_value1   =>  cv_msg_cff_50219        --  トークン値1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    BEGIN
      SELECT  1
      INTO    ln_dummy
      FROM    xxcff_contract_lines      xcl
      WHERE   xcl.contract_line_id    =   ior_target_data.contract_line_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN lock_expt THEN
        --  ロックの取得に失敗した場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  アプリケーション短縮名
                        , iv_name           =>  cv_msg_cff_00007        --  メッセージコード
                        , iv_token_name1    =>  cv_tok_cff_00007_1      --  トークンコード1
                        , iv_token_value1   =>  cv_msg_cff_50220        --  トークン値1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===============================
    --  リース契約ヘッダ更新
    -- ===============================
    UPDATE  xxcff_contract_headers  xch
    SET     xch.payment_frequency   =   gt_param_new_frequency                    --  支払回数
          , xch.payment_years       =   CEIL( gt_param_new_frequency / 12 )       --  年数
          , xch.lease_end_date      =   ADD_MONTHS( xch.lease_end_date, gt_param_new_frequency - xch.payment_frequency )
                                                                                  --  リース終了日
          , created_by              =   cn_created_by                             --  作成者
          , creation_date           =   cd_creation_date                          --  作成日
          , last_updated_by         =   cn_last_updated_by                        --  最終更新者
          , last_update_date        =   cd_last_update_date                       --  最終更新日
          , last_update_login       =   cn_last_update_login                      --  最終更新ログイン
          , request_id              =   cn_request_id                             --  要求ID
          , program_application_id  =   cn_program_application_id                 --  コンカレント・プログラム・アプリケーションID
          , program_id              =   cn_program_id                             --  コンカレント・プログラムID
          , program_update_date     =   cd_program_update_date                    --  プログラム更新日
    WHERE   xch.contract_header_id  =   ior_target_data.contract_header_id
    ;
    -- ===============================
    --  変更後支払計画取得
    -- ===============================
    SELECT  SUM( xpp.lease_charge )           SUM_LEASE_CHARGE              --  リース料（合計）
          , SUM( xpp.lease_tax_charge )       SUM_LEASE_TAX_CHARGE          --  消費税額（合計）
          , SUM( xpp.lease_deduction )        SUM_LEASE_DEDUCTION           --  リース料_控除額（合計）
          , SUM( xpp.lease_tax_deduction )    SUM_LEASE_TAX_DEDUCTION       --  消費税_控除額（合計）
    INTO    ln_sum_lease_charge
          , ior_target_data.sum_new_tax_charge
          , ln_sum_lease_deduction
          , ln_sum_lease_tax_deduction
    FROM    xxcff_pay_planning    xpp
    WHERE   xpp.contract_line_id    =   ior_target_data.contract_line_id
    ;
    -- ===============================
    --  リース契約明細更新
    -- ===============================
    UPDATE  xxcff_contract_lines    xcl
    SET
            xcl.second_charge                 =   gt_param_new_charge                                     --  2回目以降月額リース料_リース料
          , xcl.second_tax_charge             =   gt_param_new_tax_charge                                 --  2回目以降消費税額_リース料
          , xcl.second_total_charge           =   gt_param_new_charge + gt_param_new_tax_charge           --  2回目以降計_リース料
          , xcl.gross_charge                  =   ln_sum_lease_charge                                     --  総額リース料_リース料
          , xcl.gross_tax_charge              =   ior_target_data.sum_new_tax_charge                          --  総額消費税_リース料
          , xcl.gross_total_charge            =   ln_sum_lease_charge + ior_target_data.sum_new_tax_charge    --  総額計_リース料
          , xcl.gross_deduction               =   ln_sum_lease_deduction                                  --  総額リース料_控除額
          , xcl.gross_tax_deduction           =   ln_sum_lease_tax_deduction                              --  総額消費税_控除額
          , xcl.gross_total_deduction         =   ln_sum_lease_deduction + ln_sum_lease_tax_deduction     --  総額計_控除額
          , xcl.present_value_discount_rate   =   ior_target_data.discount_rate / 100                     --  現在価値割引率
          , xcl.present_value                 =   xcl.present_value + ior_target_data.present_value - ( ior_target_data.fin_debt_rem + ior_target_data.fin_debt )
                                                                                                          --  現在価値
          , xcl.original_cost                 =   xcl.original_cost + ior_target_data.present_value - ( ior_target_data.fin_debt_rem + ior_target_data.fin_debt )
                                                                                                          --  取得価額
          , xcl.calc_interested_rate          =   ior_target_data.discount_rate / 100                      --  計算利子率
          , xcl.tax_code                      =   gt_param_new_tax_code                                   --  税コード
          , created_by                        =   cn_created_by                                           --  作成者
          , creation_date                     =   cd_creation_date                                        --  作成日
          , last_updated_by                   =   cn_last_updated_by                                      --  最終更新者
          , last_update_date                  =   cd_last_update_date                                     --  最終更新日
          , last_update_login                 =   cn_last_update_login                                    --  最終更新ログイン
          , request_id                        =   cn_request_id                                           --  要求ID
          , program_application_id            =   cn_program_application_id                               --  コンカレント・プログラム・アプリケーションID
          , program_id                        =   cn_program_id                                           --  コンカレント・プログラムID
          , program_update_date               =   cd_program_update_date                                  --  プログラム更新日
    WHERE   xcl.contract_line_id    =   ior_target_data.contract_line_id
    ;
    --
    -- ===============================
    --  リース契約明細履歴登録
    -- ===============================
    INSERT INTO xxcff_contract_histories(
        contract_header_id                --   1.契約内部ID
      , contract_line_id                  --   2.契約明細内部ID
      , history_num                       --   3.変更履歴NO
      , contract_status                   --   4.契約ステータス
      , first_charge                      --   5.初回月額リース料_リース料
      , first_tax_charge                  --   6.初回消費税額_リース料
      , first_total_charge                --   7.初回計_リース料
      , second_charge                     --   8.回目以降月額リース料_リース料
      , second_tax_charge                 --   9.回目以降消費税額_リース料
      , second_total_charge               --  10.回目以降計_リース料
      , first_deduction                   --  11.初回月額リース料_控除額
      , first_tax_deduction               --  12.初回月額消費税額_控除額
      , first_total_deduction             --  13.初回計_控除額
      , second_deduction                  --  14.回目以降月額リース料_控除額
      , second_tax_deduction              --  15.回目以降消費税額_控除額
      , second_total_deduction            --  16.回目以降計_控除額
      , gross_charge                      --  17.総額リース料_リース料
      , gross_tax_charge                  --  18.総額消費税_リース料
      , gross_total_charge                --  19.総額計_リース料
      , gross_deduction                   --  20.総額リース料_控除額
      , gross_tax_deduction               --  21.総額消費税_控除額
      , gross_total_deduction             --  22.総額計_控除額
      , lease_kind                        --  23.リース種類
      , estimated_cash_price              --  24.見積現金購入価額
      , present_value_discount_rate       --  25.現在価値割引率
      , present_value                     --  26.現在価値
      , life_in_months                    --  27.法定耐用年数
      , original_cost                     --  28.取得価額
      , calc_interested_rate              --  29.計算利子率
      , object_header_id                  --  30.物件内部ID
      , asset_category                    --  31.資産種類
      , expiration_date                   --  32.満了日
      , cancellation_date                 --  33.中途解約日
      , vd_if_date                        --  34.リース契約情報連携日
      , info_sys_if_date                  --  35.リース管理情報連携日
      , first_installation_address        --  36.初回設置場所
      , first_installation_place          --  37.初回設置先
      , accounting_date                   --  38.計上日
      , accounting_if_flag                --  39.会計ＩＦフラグ
      , description                       --  40.摘要
      , created_by                        --  41.作成者
      , creation_date                     --  42.作成日
      , last_updated_by                   --  43.最終更新者
      , last_update_date                  --  44.最終更新日
      , last_update_login                 --  45.最終更新ログイン
      , request_id                        --  46.要求ID
      , program_application_id            --  47.コンカレント・プログラム・アプリケーションID
      , program_id                        --  48.コンカレント・プログラムID
      , program_update_date               --  49.プログラム更新日
      , update_reason                     --  50.更新事由
      , period_name                       --  51.会計期間
      , tax_code                          --  52.税金コード
    )
    SELECT
        xcl.contract_header_id                --   2.契約内部ID
      , xcl.contract_line_id                  --   1.契約明細内部ID
      , xxcff_contract_histories_s1.NEXTVAL   --   3.変更履歴NO
      , cv_contract_status_210                --   4.契約ステータス
      , xcl.first_charge                      --   5.初回月額リース料_リース料
      , xcl.first_tax_charge                  --   6.初回消費税額_リース料
      , xcl.first_total_charge                --   7.初回計_リース料
      , xcl.second_charge                     --   8.回目以降月額リース料_リース料
      , xcl.second_tax_charge                 --   9.回目以降消費税額_リース料
      , xcl.second_total_charge               --  10.回目以降計_リース料
      , xcl.first_deduction                   --  11.初回月額リース料_控除額
      , xcl.first_tax_deduction               --  12.初回月額消費税額_控除額
      , xcl.first_total_deduction             --  13.初回計_控除額
      , xcl.second_deduction                  --  14.回目以降月額リース料_控除額
      , xcl.second_tax_deduction              --  15.回目以降消費税額_控除額
      , xcl.second_total_deduction            --  16.回目以降計_控除額
      , xcl.gross_charge                      --  17.総額リース料_リース料
      , xcl.gross_tax_charge                  --  18.総額消費税_リース料
      , xcl.gross_total_charge                --  19.総額計_リース料
      , xcl.gross_deduction                   --  20.総額リース料_控除額
      , xcl.gross_tax_deduction               --  21.総額消費税_控除額
      , xcl.gross_total_deduction             --  22.総額計_控除額
      , xcl.lease_kind                        --  23.リース種類
      , xcl.estimated_cash_price              --  24.見積現金購入価額
      , xcl.present_value_discount_rate       --  25.現在価値割引率
      , xcl.present_value                     --  26.現在価値
      , xcl.life_in_months                    --  27.法定耐用年数
      , xcl.original_cost                     --  28.取得価額
      , xcl.calc_interested_rate              --  29.計算利子率
      , xcl.object_header_id                  --  30.物件内部ID
      , xcl.asset_category                    --  31.資産種類
      , xcl.expiration_date                   --  32.満了日
      , xcl.cancellation_date                 --  33.中途解約日
      , xcl.vd_if_date                        --  34.リース契約情報連携日
      , xcl.info_sys_if_date                  --  35.リース管理情報連携日
      , xcl.first_installation_address        --  36.初回設置場所
      , xcl.first_installation_place          --  37.初回設置先
      , LAST_DAY( gd_ifrs_period_date )       --  38.計上日
      , cv_flag_2                             --  39.会計ＩＦフラグ
      , NULL                                  --  40.摘要
      , cn_created_by                         --  41.作成者
      , cd_creation_date                      --  42.作成日
      , cn_last_updated_by                    --  43.最終更新者
      , cd_last_update_date                   --  44.最終更新日
      , cn_last_update_login                  --  45.最終更新ログイン
      , cn_request_id                         --  46.要求ID
      , cn_program_application_id             --  47.コンカレント・プログラム・アプリケーションID
      , cn_program_id                         --  48.コンカレント・プログラムID
      , cd_program_update_date                --  49.プログラム更新日
      , cv_update_reason                      --  50.更新事由
      , gt_ifrs_period_name                   --  51.会計期間
      , xcl.tax_code                          --  52.税金コード
    FROM    xxcff_contract_lines    xcl
    WHERE   xcl.contract_line_id    =   ior_target_data.contract_line_id
    ;
  EXCEPTION
    WHEN global_process_expt THEN
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
  END upd_contract_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_adjustment_oif
   * Description      : 修正OIF作成(A-8)
   ***********************************************************************************/
  PROCEDURE ins_adjustment_oif(
      ir_target_data    IN  g_target_rtype  --  対象データ
    , ov_errbuf         OUT VARCHAR2        --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2        --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2        --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_adjustment_oif'; -- プログラム名
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
    ln_dummy            NUMBER;             --  ダミー変数
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
    -- ===============================
    --  OIF作成
    -- ===============================
    INSERT INTO xx01_adjustment_oif(
        adjustment_oif_id                       --   1
      , book_type_code                          --   2
      , asset_number_old                        --   3
      , dpis_old                                --   4
      , category_id_old                         --   5
      , cat_attribute_category_old              --   6
      , created_by                              --   7
      , creation_date                           --   8
      , last_updated_by                         --   9
      , last_update_date                        --  10
      , last_update_login                       --  11
      , request_id                              --  12
      , program_application_id                  --  13
      , program_id                              --  14
      , program_update_date                     --  15
      , posting_flag                            --  16
      , status                                  --  17
      , amortized_flag                          --  18
      , amortization_start_date                 --  19
      , asset_number_new                        --  20
      , description                             --  21
      , tag_number                              --  22
      , category_id_new                         --  23
      , serial_number                           --  24
      , asset_key_ccid                          --  25
      , key_segment1                            --  26
      , key_segment2                            --  27
      , transaction_units                       --  28
      , parent_asset_id                         --  29
      , lease_id                                --  30
      , model_number                            --  31
      , in_use_flag                             --  32
      , inventorial                             --  33
      , owned_leased                            --  34
      , new_used                                --  35
      , cat_attribute1                          --  36
      , cat_attribute2                          --  37
      , cat_attribute3                          --  38
      , cat_attribute4                          --  39
      , cat_attribute5                          --  40
      , cat_attribute6                          --  41
      , cat_attribute7                          --  42
      , cat_attribute8                          --  43
      , cat_attribute9                          --  44
      , cat_attribute10                         --  45
      , cat_attribute11                         --  46
      , cat_attribute12                         --  47
      , cat_attribute13                         --  48
      , cat_attribute14                         --  49
      , cat_attribute15                         --  50
      , cat_attribute16                         --  51
      , cat_attribute17                         --  52
      , cat_attribute18                         --  53
      , cat_attribute19                         --  54
      , cat_attribute20                         --  55
      , cat_attribute21                         --  56
      , cat_attribute22                         --  57
      , cat_attribute23                         --  58
      , cat_attribute24                         --  59
      , cat_attribute25                         --  60
      , cat_attribute26                         --  61
      , cat_attribute27                         --  62
      , cat_attribute28                         --  63
      , cat_attribute29                         --  64
      , cat_attribute30                         --  65
      , cat_attribute_category_new              --  66
      , cost                                    --  67
      , original_cost                           --  68
      , salvage_value                           --  69
      , percent_salvage_value                   --  70
      , allowed_deprn_limit_amount              --  71
      , allowed_deprn_limit                     --  72
      , depreciate_flag                         --  73
      , dpis_new                                --  74
      , deprn_method_code                       --  75
      , basic_rate                              --  76
      , adjusted_rate                           --  77
      , life_years                              --  78
      , life_months                             --  79
      , bonus_rule                              --  80
    )
    SELECT
      --  ★は変更する項目、それ以外は現行データの情報を使用する
      xx01_adjustment_oif_s.NEXTVAL             --   1.シーケンス
    , fb.book_type_code                         --   2.台帳名
    , fab.asset_number                          --   3.資産番号
    , fb.date_placed_in_service                 --   4.事業供用日（修正前）
    , fab.asset_category_id                     --   5.資産カテゴリID（修正前）
    , fab.attribute_category_code               --   6.資産カテゴリコード（修正前）
    , cn_created_by                             --   7.作成者
    , cd_creation_date                          --   8.作成日
    , cn_last_updated_by                        --   9.最終更新者
    , cd_last_update_date                       --  10.最終更新日
    , cn_last_update_login                      --  11.最終更新ログインID
    , cn_request_id                             --  12.リクエストID
    , cn_program_application_id                 --  13.アプリケーションID
    , cn_program_id                             --  14.プログラムID
    , cd_program_update_date                    --  15.プログラム最終更新日
    , cv_flag_y                                 --  16.転記チェックフラグ
    , cv_oif_status_p                           --  17.ステータス
    , cv_oif_amortized_yes                      --  18.★修正額償却フラグ
    , gd_ifrs_period_date                       --  19.★償却開始日
    , fab.asset_number                          --  20.資産番号（修正後）
    , fat.description                           --  21.摘要（修正後）
    , fab.tag_number                            --  22.現品票番号
    , ir_target_data.asset_category_id          --  23.★資産カテゴリID（修正後）
    , fab.serial_number                         --  24.シリアル番号
    , fab.asset_key_ccid                        --  25.資産キーCCID
    , fak.segment1                              --  26.資産キーセグメント1
    , fak.segment2                              --  27.資産キーセグメント2
    , fab.current_units                         --  28.単位
    , fab.parent_asset_id                       --  29.親資産ID
    , fab.lease_id                              --  30.リースID
    , fab.model_number                          --  31.モデル
    , fab.in_use_flag                           --  32.使用状況
    , fab.inventorial                           --  33.実地棚卸フラグ
    , fab.owned_leased                          --  34.所有権
    , fab.new_used                              --  35.新品/中古
    , fab.attribute1                            --  36.カテゴリDFF1
    , fab.attribute2                            --  37.カテゴリDFF2
    , fab.attribute3                            --  38.カテゴリDFF3
    , fab.attribute4                            --  39.カテゴリDFF4
    , fab.attribute5                            --  40.カテゴリDFF5
    , fab.attribute6                            --  41.カテゴリDFF6
    , fab.attribute7                            --  42.カテゴリDFF7
    , fab.attribute8                            --  43.カテゴリDFF8
    , fab.attribute9                            --  44.カテゴリDFF9
    , fab.attribute10                           --  45.カテゴリDFF10
    , fab.attribute11                           --  46.カテゴリDFF11
    , fab.attribute12                           --  47.カテゴリDFF12
    , fab.attribute13                           --  48.カテゴリDFF13
    , fab.attribute14                           --  49.カテゴリDFF14
    , fab.attribute15                           --  50.カテゴリDFF15
    , fab.attribute16                           --  51.カテゴリDFF16
    , fab.attribute17                           --  52.カテゴリDFF17
    , fab.attribute18                           --  53.カテゴリDFF18
    , fab.attribute19                           --  54.カテゴリDFF19
    , fab.attribute20                           --  55.カテゴリDFF20
    , fab.attribute21                           --  56.カテゴリDFF21
    , fab.attribute22                           --  57.カテゴリDFF22
    , fab.attribute23                           --  58.カテゴリDFF23
    , fab.attribute24                           --  59.カテゴリDFF24
    , fab.attribute25                           --  60.カテゴリDFF27
    , fab.attribute26                           --  61.カテゴリDFF25
    , fab.attribute27                           --  62.カテゴリDFF26
    , fab.attribute28                           --  63.カテゴリDFF28
    , fab.attribute29                           --  64.カテゴリDFF29
    , fab.attribute30                           --  65.カテゴリDFF30
    , ir_target_data.asset_category_code        --  66.★資産カテゴリコード（修正後）
    , ( SELECT xcl.original_cost FROM xxcff_contract_lines xcl WHERE xcl.contract_line_id = ir_target_data.contract_line_id )
                                                --  67.★取得価額
    , fb.original_cost                          --  68.当初取得価額
    , fb.salvage_value                          --  69.残存価額
    , fb.percent_salvage_value                  --  70.残存価額%
    , fb.allowed_deprn_limit_amount             --  71.償却限度額
    , fb.allowed_deprn_limit                    --  72.償却限度率
    , fb.depreciate_flag                        --  73.償却費計上フラグ
    , fb.date_placed_in_service                 --  74.事業供用日（修正後）
    , ir_target_data.deprn_method               --  75.★償却方法
    , fb.basic_rate                             --  76.普通償却率
    , fb.adjusted_rate                          --  77.割増後償却率
    , TRUNC( gt_param_new_frequency / 12 )      --  78.★耐用年数
    , gt_param_new_frequency - TRUNC( gt_param_new_frequency / 12 ) * 12
                                                --  79.★月数
    , fb.bonus_rule                             --  80.ボーナスルール
    FROM    fa_additions_b            fab       --  資産詳細情報
          , fa_additions_tl           fat       --  資産詳細情報(TL)
          , fa_asset_keywords         fak       --  資産キーワード
          , fa_books                  fb        --  資産台帳情報
    WHERE   fab.asset_id                  =   fat.asset_id
    AND     fat.language                  =   cv_lang
    AND     fab.asset_id                  =   fb.asset_id
    AND     fb.book_type_code             =   gt_prof_ifrs_lease_books
    AND     fb.date_ineffective IS NULL
    AND     fab.asset_key_ccid            =   fak.code_combination_id(+)
    AND     fab.attribute10               =   TO_CHAR( ir_target_data.contract_line_id )
    ;
    --
    IF ( SQL%ROWCOUNT = 0 ) THEN
      --  更新対象データが存在しない場合、メッセージを表示（処理は正常終了）
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff          --  アプリケーション短縮名
                      , iv_name           =>  cv_msg_cff_00165        --  メッセージコード
                      , iv_token_name1    =>  cv_tok_cff_00165_1      --  トークンコード1
                      , iv_token_value1   =>  cv_msg_cff_50256        --  トークン値1
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
    END IF;
    --
    IF ( ir_target_data.sum_new_tax_charge <> ir_target_data.sum_old_tax_charge ) THEN
      --  税額が変更されている場合
      INSERT INTO xxcff_fa_transactions(
          fa_transaction_id             --   1.リース取引内部ID
        , contract_header_id            --   2.契約内部ID
        , contract_line_id              --   3.契約明細内部ID
        , object_header_id              --   4.物件内部ID
        , period_name                   --   5.会計期間
        , transaction_type              --   6.取引タイプ
        , movement_type                 --   7.移動タイプ
        , book_type_code                --   8.資産台帳名
        , lease_class                   --   9.リース種別
        , owner_company                 --  10.本社／工場
        , gl_if_flag                    --  11.GL連携フラグ
        , tax_charge                    --  12.税額
        , tax_code                      --  13.税コード
        , created_by                    --  14.作成者
        , creation_date                 --  15.作成日
        , last_updated_by               --  16.最終更新者
        , last_update_date              --  17.最終更新日
        , last_update_login             --  18.最終更新ログイン
        , request_id                    --  19.要求ID
        , program_application_id        --  20.アプリケーションID
        , program_id                    --  21.プログラムID
        , program_update_date           --  22.プログラム更新日
      )VALUES(
          xxcff_fa_transactions_s1.NEXTVAL                                          --   1
        , ir_target_data.contract_header_id                                         --   2
        , ir_target_data.contract_line_id                                           --   3
        , ir_target_data.object_header_id                                           --   4
        , gt_ifrs_period_name                                                       --   5
        , '4'                                                                       --   6
        , NULL                                                                      --   7
        , gt_prof_ifrs_lease_books                                                  --   8
        , ir_target_data.lease_class                                                --   9
        , ir_target_data.owner_company                                              --  10
        , '1'                                                                       --  11
        , ir_target_data.sum_new_tax_charge - ir_target_data.sum_old_tax_charge     --  12
        , gt_param_new_tax_code                                                     --  13
        , cn_created_by                                                             --  14
        , cd_creation_date                                                          --  15
        , cn_last_updated_by                                                        --  16
        , cd_last_update_date                                                       --  17
        , cn_last_update_login                                                      --  18
        , cn_request_id                                                             --  19
        , cn_program_application_id                                                 --  20
        , cn_program_id                                                             --  21
        , cd_program_update_date                                                    --  22
      );
    END IF;
  EXCEPTION
    WHEN global_process_expt THEN
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
  END ins_adjustment_oif;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_object_code    IN  VARCHAR2        --  物件コード
    , iv_new_frequency  IN  VARCHAR2        --  変更後支払回数
    , iv_new_charge     IN  VARCHAR2        --  変更後リース料
    , iv_new_tax_charge IN  VARCHAR2        --  変更後税額
    , iv_new_tax_code   IN  VARCHAR2        --  変更後税コード
    , ov_errbuf         OUT VARCHAR2        --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2        --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2        --  ユーザー・エラー・メッセージ --# 固定 #
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
    lr_target_data        g_target_rtype;                                       --  対象データ保持用
    lt_new_pay_plan       g_new_pay_plan_ttype;                                 --  新規支払計画
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --  初期化
    lr_target_data  :=  NULL;
    lt_new_pay_plan.DELETE;
    -- ===============================
    --  初期処理(A-1)
    -- ===============================
    init(
        iv_object_code    =>  iv_object_code      --  物件コード
      , iv_new_frequency  =>  iv_new_frequency    --  変更後支払回数
      , iv_new_charge     =>  iv_new_charge       --  変更後リース料
      , iv_new_tax_charge =>  iv_new_tax_charge   --  変更後税額
      , iv_new_tax_code   =>  iv_new_tax_code     --  変更後税コード
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  対象データ抽出(A-2)
    -- ===============================
    get_target_data(
        or_target_data    =>  lr_target_data      --  対象データ
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  各種情報CSV出力(A-3)  変更前データ
    -- ===============================
    --  COMMITされてしまうため、最初に実行する
    output_csv(
        ir_target_data    =>  lr_target_data      --  対象データ
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  新支払計画データ作成(A-4)
    -- ===============================
    create_pay_planning(
        ior_target_data   =>  lr_target_data      --  対象データ
      , ot_new_pay_plan   =>  lt_new_pay_plan     --  新支払計画
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  データバックアップ(A-5)
    -- ===============================
    ins_backup(
        ir_target_data    =>  lr_target_data      --  対象データ
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  新支払計画登録(A-6)
    -- ===============================
    replace_pay_planning(
        ir_target_data    =>  lr_target_data      --  対象データ
      , it_new_pay_plan   =>  lt_new_pay_plan     --  新支払計画
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  契約情報更新(A-7)
    -- ===============================
    upd_contract_data(
        ior_target_data   =>  lr_target_data      --  対象データ
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  修正OIF作成(A-8)
    -- ===============================
    ins_adjustment_oif(
        ir_target_data    =>  lr_target_data      --  対象データ
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  各種情報CSV出力(A-3)  変更後データ
    -- ===============================
    --  COMMITされてしまうため、全処理正常時（最後）に実行
    output_csv(
        ir_target_data    =>  lr_target_data      --  対象データ
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    --
  EXCEPTION
    --  各プロシージャでの処理結果に対する例外
    WHEN procedure_expt THEN
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  lv_errbuf;
      ov_retcode  :=  lv_retcode;
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
      errbuf            OUT VARCHAR2          --  エラーメッセージ #固定#
    , retcode           OUT VARCHAR2          --  エラーコード     #固定#
    , iv_object_code    IN  VARCHAR2          --  物件コード
    , iv_new_frequency  IN  VARCHAR2          --  変更後支払回数
    , iv_new_charge     IN  VARCHAR2          --  変更後リース料
    , iv_new_tax_charge IN  VARCHAR2          --  変更後税額
    , iv_new_tax_code   IN  VARCHAR2          --  変更後税コード
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
        iv_object_code    =>  iv_object_code      --  物件コード
      , iv_new_frequency  =>  iv_new_frequency    --  変更後支払回数
      , iv_new_charge     =>  iv_new_charge       --  変更後リース料
      , iv_new_tax_charge =>  iv_new_tax_charge   --  変更後税額
      , iv_new_tax_code   =>  iv_new_tax_code     --  変更後税コード
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
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
    --
    --  本処理は対象1件のみ
    gn_target_cnt :=  1;
    gn_normal_cnt :=  CASE WHEN lv_retcode = cv_status_normal THEN 1 ELSE 0 END;
    gn_error_cnt  :=  gn_target_cnt - gn_normal_cnt;
    --
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
END XXCFF020A01C;
/
