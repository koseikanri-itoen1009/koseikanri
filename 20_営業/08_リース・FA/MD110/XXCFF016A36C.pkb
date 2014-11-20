create or replace
PACKAGE BODY XXCFF016A36C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCFF016A36C(body)
 * Description      : リース契約明細メンテナンス
 * MD.050           : MD050_CFF_016_A36_リース契約明細メンテナンス.
 * Version          : 1.3
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  out_csv_data                 更新後データ出力の実行                    (A-9)
 *  insert_contract_histories    リース契約明細の履歴の作成                (A-8)
 *  update_pay_planning          支払計画再作成及びフラグ更新              (A-7)
 *  get_judge_lease              リース判定処理                            (A-6)
 *  update_contract_lines        データパッチ処理                          (A-5)
 *  get_backup_data              データバックアップの実行                  (A-4)
 *  out_csv_data                 更新前データ出力の実行                    (A-3)
 *  chk_param                    入力パラメータチェック処理                (A-2)
 *  init                         初期処理                                  (A-1)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/12    1.0   SCSK 古山         新規作成
 *  2013/07/11    1.1   SCSK 中村         E_本稼動_10871 消費税対応
 *  2014/01/31    1.2   SCSK 中野         E_本稼動_11242 リース契約明細更新の不具合対応
 *  2014/05/19    1.3   SCSK 中野         E_本稼動_11852 控除額更新不具合対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
  -- ロック(ビジー)エラー
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCFF016A36C';      -- パッケージ名
--
  -- 出力タイプ
  cv_file_type_out       CONSTANT VARCHAR2(10)  := 'OUTPUT';            -- 出力(ユーザメッセージ用出力先)
  cv_file_type_log       CONSTANT VARCHAR2(10)  := 'LOG';               -- ログ(システム管理者用出力先)
  -- アプリケーション短縮名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCFF';             -- アドオン：会計・リース・FA領域
  --
  cv_format_m            CONSTANT VARCHAR2(100) := 'MM';                -- TRUNC書式
  -- メッセージ名(本文)
  cv_msg_xxcff00123      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00123';  -- 存在チェックエラー
  cv_msg_xxcff00208      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00208';  -- 存在チェックエラー
  cv_msg_xxcff00186      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00186';  -- 会計期間取得エラー
  cv_msg_xxcff00157      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00157';  -- パラメータ必須エラー
  cv_msg_xxcff00195      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00195';  -- （仮）更新エラー
  cv_msg_xxcff00101      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00101';  -- 取得エラー
  cv_msg_xxcff00102      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102';  -- 登録エラー
  cv_msg_xxcff00197      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00197';  -- （仮）コンカレント発行エラー
  cv_msg_xxcff00198      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00198';  -- （仮）コンカレント待機エラー
  cv_msg_xxcff00199      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00199';  -- （仮）コンカレント処理エラー
  cv_msg_xxcff00200      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00200';  -- （仮）パラメータ型・桁数エラー
  cv_msg_xxcff00094      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094';  -- 共通関数エラー
  cv_msg_xxcff00007      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007';  -- ロックエラー
  cv_msg_xxcff00020      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00020';  -- プロファイル取得エラー
  cv_msg_xxcff00207      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00207';  -- メンテナンス項目値未入力エラー
  -- トークン
  cv_tkn_func_name       CONSTANT VARCHAR2(100) := 'FUNC_NAME';         -- 関数名
  cv_tkn_err_msg         CONSTANT VARCHAR2(100) := 'ERR_MSG';           -- エラーメッセージ
  cv_tkn_input           CONSTANT VARCHAR2(30)  := 'INPUT';
  cv_tkn_column          CONSTANT VARCHAR2(30)  := 'COLUMN_DATA';
  cv_tkn_get             CONSTANT VARCHAR2(30)  := 'GET_DATA';
  cv_tkn_table           CONSTANT VARCHAR2(15)  := 'TABLE_NAME';        -- テーブル名
  cv_tkn_info            CONSTANT VARCHAR2(15)  := 'INFO';
  cv_tkn_prof_name       CONSTANT VARCHAR2(100) := 'PROF_NAME';         -- プロファイル名
  cv_tkn_syori           CONSTANT VARCHAR2(100) := 'SYORI';             -- 処理名
  cv_tkn_request_id      CONSTANT VARCHAR2(100) := 'REQUEST_ID';        -- 要求ID
  cv_tkn_prm_name        CONSTANT VARCHAR2(100) := 'PARAM_NAME';        -- パラメータ
  -- トークン値
  cv_msg_cff_50210       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50210';  -- コンカレントパラメータ出力処理
  cv_msg_cff_50010       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50010';  -- 物件コード
  cv_msg_cff_50028       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50028';  -- 契約明細内部ID
  cv_msg_cff_50030       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50030';  -- リース契約明細テーブル
  cv_msg_cff_50040       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50040';  -- 契約番号
  cv_msg_cff_50070       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50070';  -- リース契約明細履歴テーブル
  cv_msg_cff_50088       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50088';  -- リース支払計画
  cv_msg_cff_50199       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50199';  -- (仮)更新事由
  cv_msg_cff_50223       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50223';  -- (仮)初回月額リース料
  cv_msg_cff_50224       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50224';  -- (仮)２回目以降月額リース料
  cv_msg_cff_50225       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50225';  -- (仮)初回月額消費税額
  cv_msg_cff_50226       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50226';  -- (仮)２回目以降消費税額
  cv_msg_cff_50110       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50110';  -- 見積現金購入価額
  cv_msg_cff_50200       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50200';  -- (仮)リース契約明細BK
  cv_msg_cff_50201       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50201';  -- (仮)リース支払計画BK
  cv_msg_cff_50202       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50202';  -- (仮)実行枝番
  cv_msg_cff_50203       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50203';  -- (仮)リース契約データCSV出力
  cv_msg_cff_50204       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50204';  -- (仮)リース物件データCSV出力
  cv_msg_cff_50205       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50205';  -- (仮)リース支払計画データCSV出力
  cv_msg_cff_50206       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50206';  -- (仮)リース会計基準情報CSV出力
  cv_msg_cff_50207       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50207';  -- (仮)リース種類判定
  cv_msg_cff_50208       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50208';  -- (仮)会計期間
  cv_msg_cff_50209       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50209';  -- (仮)支払計画作成
  cv_msg_cff_50222       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50222';  -- (仮)照合済フラグ
-- Add 2013/07/11 Ver.1.1 Start
  cv_msg_cff_50148       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50148';  -- 税金コード
-- Add 2013/07/11 Ver.1.1 Start
  -- プロファイル
  cv_prof_interval       CONSTANT VARCHAR2(100) := 'XXCOS1_INTERVAL';   -- XXCOS:待機間隔
  cv_prof_max_wait       CONSTANT VARCHAR2(100) := 'XXCOS1_MAX_WAIT';   -- XXCOS:最大待機時間
  -- リース種類
  cv_les_kind_fin        CONSTANT VARCHAR2(1)   := '0';                 -- Finリース
  -- 契約ステータス
  cv_ctrct_st_ctrct      CONSTANT VARCHAR2(3)   := '202';               -- 契約
  cv_ctrct_st_reles      CONSTANT VARCHAR2(3)   := '203';               -- 再リース
  cv_ctrct_st_mntnnc     CONSTANT VARCHAR2(3)   := '210';               -- 契約データメンテナンス
  -- 会計IFフラグ
  cv_acct_if_flag_unsent CONSTANT VARCHAR2(1)   := '1';                 -- 未送信
  cv_acct_if_flag_sent   CONSTANT VARCHAR2(1)   := '2';                 -- 送信済
  -- 照合済みフラグ
  cv_paymtch_flag_admin  CONSTANT VARCHAR2(1)   := '1';                 -- 照合済
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE gr_param_rec  IS RECORD(
      object_code           xxcff_object_headers.object_code%TYPE          -- 1 : 物件コード          (必須)
     ,contract_number       xxcff_contract_headers.contract_number%TYPE    -- 2 : 契約番号            (必須)
     ,update_reason         xxcff_contract_histories.update_reason%TYPE    -- 3 : 更新事由            (必須)
     ,first_charge          xxcff_contract_lines.first_charge%TYPE         -- 4 : 初回リース料        (任意)
     ,second_charge         xxcff_contract_lines.second_charge%TYPE        -- 5 : 2回目以降のリース料 (任意)
     ,first_tax_charge      xxcff_contract_lines.first_tax_charge%TYPE     -- 6 : 初回消費税          (任意)
     ,second_tax_charge     xxcff_contract_lines.second_tax_charge%TYPE    -- 7 : 2回目以降の消費税   (任意)
     ,estimated_cash_price  xxcff_contract_lines.estimated_cash_price%TYPE -- 8 : 見積現金購入価額    (任意)
-- Add 2013/07/11 Ver.1.1 Start
     ,tax_code              xxcff_contract_lines.tax_code%TYPE             -- 9 : 税金コード          (任意)
-- ADd 2013/07/11 Ver.1.1 End
    );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_period_name          fa_deprn_periods.period_name%TYPE;               -- 会計期間(リース台帳オープン期間)
  gd_period_close_date    fa_deprn_periods.calendar_period_close_date%TYPE;-- リース台帳オープン期間のカレンダ終了日
  gn_interval             NUMBER;                                          -- コンカレント待機間隔
  gn_max_wait             NUMBER;                                          -- コンカレント最大待機時間
--
  gt_object_header_id     xxcff_object_headers.object_code%TYPE;           -- 物件内部ID
  gt_contract_line_id     xxcff_contract_lines.contract_line_id%TYPE;      -- 契約明細内部ID
  gt_first_charge         xxcff_contract_lines.first_charge%TYPE;          -- 初回月額リース料_リース料
  gt_first_tax_charge     xxcff_contract_lines.first_tax_charge%TYPE;      -- 初回消費税額_リース料
  gt_second_charge        xxcff_contract_lines.second_charge%TYPE;         -- 2回目以降月額リース料_リース料
  gt_second_tax_charge    xxcff_contract_lines.second_tax_charge%TYPE;     -- 2回目以降消費税額_リース料
  gt_first_deduction      xxcff_contract_lines.first_deduction%TYPE;       -- 初回月額リース料_控除額
  gt_second_deduction     xxcff_contract_lines.second_deduction%TYPE;      -- 2回目以降月額リース料_控除額
-- Add 2014/05/19 Ver.1.3 Start
  gt_first_tax_deduction  xxcff_contract_lines.first_tax_deduction%TYPE;   -- 初回月額消費税額_控除額
  gt_second_tax_deduction xxcff_contract_lines.second_tax_deduction%TYPE;  -- 2回目以降消費税額_控除額
-- Add 2014/05/19 Ver.1.3 End
  gt_estimated_cash_price xxcff_contract_lines.estimated_cash_price%TYPE;  -- 見積現金購入価額
  gt_life_in_months       xxcff_contract_lines.life_in_months%TYPE;        -- 法定耐用年数
  gt_contract_header_id   xxcff_contract_headers.contract_header_id%TYPE;  -- 契約内部ID
  gt_contract_date        xxcff_contract_headers.contract_date%TYPE;       -- TO_DATE(TO_CHAR(リース契約日,'YYYY/MM')||'/01','YYYY/MM/DD')
  gt_lease_type           xxcff_contract_headers.lease_type%TYPE;          -- リース区分
  gt_payment_frequency    xxcff_contract_headers.payment_frequency%TYPE;   -- 支払回数
--
  gr_param               gr_param_rec;
--
  /**********************************************************************************
   * Procedure Name   : insert_contract_histories
   * Description      : リース契約明細の履歴の作成(A-8)
   ***********************************************************************************/
  PROCEDURE insert_contract_histories(
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_contract_histories'; -- プログラム名
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
    -- ***   リース契約明細の履歴の作成    ***
    -- ***************************************
--
    -- =====================================
    -- リース契約明細の履歴の作成
    -- =====================================
    BEGIN
      INSERT INTO xxcff_contract_histories(
         contract_header_id                    -- 契約内部ID
        ,contract_line_id                      -- 契約明細内部ID
        ,history_num                           -- 変更履歴NO
        ,contract_status                       -- 契約ステータス
        ,first_charge                          -- 初回月額リース料_リース料
        ,first_tax_charge                      -- 初回消費税額_リース料
        ,first_total_charge                    -- 初回計_リース料
        ,second_charge                         -- 2回目以降月額リース料_リース料
        ,second_tax_charge                     -- 2回目以降消費税額_リース料
        ,second_total_charge                   -- 2回目以降計_リース料
        ,first_deduction                       -- 初回月額リース料_控除額
        ,first_tax_deduction                   -- 初回月額消費税額_控除額
        ,first_total_deduction                 -- 初回計_控除額
        ,second_deduction                      -- 2回目以降月額リース料_控除額
        ,second_tax_deduction                  -- 2回目以降消費税額_控除額
        ,second_total_deduction                -- 2回目以降計_控除額
        ,gross_charge                          -- 総額リース料_リース料
        ,gross_tax_charge                      -- 総額消費税_リース料
        ,gross_total_charge                    -- 総額計_リース料
        ,gross_deduction                       -- 総額リース料_控除額
        ,gross_tax_deduction                   -- 総額消費税_控除額
        ,gross_total_deduction                 -- 総額計_控除額
        ,lease_kind                            -- リース種類
        ,estimated_cash_price                  -- 見積現金購入価額
        ,present_value_discount_rate           -- 現在価値割引率
        ,present_value                         -- 現在価値
        ,life_in_months                        -- 法定耐用年数
        ,original_cost                         -- 取得価額
        ,calc_interested_rate                  -- 計算利子率
        ,object_header_id                      -- 物件内部ID
        ,asset_category                        -- 資産種類
        ,expiration_date                       -- 満了日
        ,cancellation_date                     -- 中途解約日
        ,vd_if_date                            -- リース契約情報連携日
        ,info_sys_if_date                      -- リース管理情報連携日
        ,first_installation_address            -- 初回設置場所
        ,first_installation_place              -- 初回設置先
-- Add 2013/07/11 Ver.1.1 Start
        ,tax_code                              -- 税金コード
-- Add 2013/07/11 Ver.1.1 End
        ,accounting_date                       -- 計上日
        ,accounting_if_flag                    -- 会計ＩＦフラグ
        ,description                           -- 摘要
        ,update_reason                         -- 更新事由
        ,period_name                           -- 会計期間
        ,created_by                            -- 作成者
        ,creation_date                         -- 作成日
        ,last_updated_by                       -- 最終更新者
        ,last_update_date                      -- 最終更新日
        ,last_update_login                     -- 最終更新ログイン
        ,request_id                            -- 要求ID
        ,program_application_id                -- コンカレント・プログラム・アプリケーションID
        ,program_id                            -- コンカレント・プログラムID
        ,program_update_date                   -- プログラム更新日
        )
      SELECT
         xcl.contract_header_id                -- 契約内部ID
        ,xcl.contract_line_id                  -- 契約明細内部ID
        ,xxcff_contract_histories_s1.NEXTVAL   -- 契約明細履歴シーケンス
        ,cv_ctrct_st_mntnnc                    -- 契約ステータス
        ,xcl.first_charge                      -- 初回月額リース料_リース料
        ,xcl.first_tax_charge                  -- 初回消費税額_リース料
        ,xcl.first_total_charge                -- 初回計_リース料
        ,xcl.second_charge                     -- 2回目以降月額リース料_リース料
        ,xcl.second_tax_charge                 -- 2回目以降消費税額_リース料
        ,xcl.second_total_charge               -- 2回目以降計_リース料
        ,xcl.first_deduction                   -- 初回月額リース料_控除額
        ,xcl.first_tax_deduction               -- 初回月額消費税額_控除額
        ,xcl.first_total_deduction             -- 初回計_控除額
        ,xcl.second_deduction                  -- 2回目以降月額リース料_控除額
        ,xcl.second_tax_deduction              -- 2回目以降消費税額_控除額
        ,xcl.second_total_deduction            -- 2回目以降計_控除額
        ,xcl.gross_charge                      -- 総額リース料_リース料
        ,xcl.gross_tax_charge                  -- 総額消費税_リース料
        ,xcl.gross_total_charge                -- 総額計_リース料
        ,xcl.gross_deduction                   -- 総額リース料_控除額
        ,xcl.gross_tax_deduction               -- 総額消費税_控除額
        ,xcl.gross_total_deduction             -- 総額計_控除額
        ,xcl.lease_kind                        -- リース種類
        ,xcl.estimated_cash_price              -- 見積現金購入価額
        ,xcl.present_value_discount_rate       -- 現在価値割引率
        ,xcl.present_value                     -- 現在価値
        ,xcl.life_in_months                    -- 法定耐用年数
        ,xcl.original_cost                     -- 取得価額
        ,xcl.calc_interested_rate              -- 計算利子率
        ,xcl.object_header_id                  -- 物件内部ID
        ,xcl.asset_category                    -- 資産種類
        ,xcl.expiration_date                   -- 満了日
        ,xcl.cancellation_date                 -- 中途解約日
        ,xcl.vd_if_date                        -- リース契約情報連携日
        ,xcl.info_sys_if_date                  -- リース管理情報連携日
        ,xcl.first_installation_address        -- 初回設置場所
        ,xcl.first_installation_place          -- 初回設置先
-- Add 2013/07/11 Ver.1.1 Start
        ,xcl.tax_code                          -- 税金コード
-- Add 2013/07/11 Ver.1.1 End
        ,gd_period_close_date                  -- 計上日
        ,cv_acct_if_flag_sent                  -- 会計ＩＦフラグ('2':送信済)
        ,NULL                                  -- 摘要
        ,gr_param.update_reason                -- 更新事由
        ,gt_period_name                        -- 会計期間
        ,xcl.created_by                        -- 作成者
        ,xcl.creation_date                     -- 作成日
        ,xcl.last_updated_by                   -- 最終更新者
        ,xcl.last_update_date                  -- 最終更新日
        ,xcl.last_update_login                 -- 最終更新ログイン
        ,xcl.request_id                        -- 要求ID
        ,xcl.program_application_id            -- コンカレント・プログラム・アプリケーションID
        ,xcl.program_id                        -- コンカレント・プログラムID
        ,xcl.program_update_date               -- プログラム更新日
      FROM   xxcff_contract_lines xcl          -- リース契約明細
      WHERE  xcl.contract_line_id = gt_contract_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00102
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50070
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => SQLERRM
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
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
  END insert_contract_histories;
--
  /**********************************************************************************
   * Procedure Name   : update_pay_planning
   * Description      : 支払計画再作成及びフラグ更新(A-7)
   ***********************************************************************************/
  PROCEDURE update_pay_planning(
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_pay_planning'; -- プログラム名
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
    cv_shori_type_1      CONSTANT VARCHAR2(1) := '1'; -- ｢登録｣
--
    -- *** ローカル変数 ***
    lt_payment_match_flag  xxcff_pay_planning.payment_match_flag%TYPE;  -- 照合済フラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***   支払計画再作成及びフラグ更新  ***
    -- ***************************************
--
    -- =====================================
    -- 照合済フラグの退避
    -- =====================================
    BEGIN
      SELECT
        xpp.payment_match_flag AS payment_match_flag   -- 照合済フラグ
      INTO
        lt_payment_match_flag
      FROM
        xxcff_pay_planning xpp
      WHERE  xpp.CONTRACT_LINE_ID = gt_contract_line_id
      AND    xpp.PERIOD_NAME      = gt_period_name
      AND    rownum               = 1
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00101
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50222
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => NULL
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- =====================================
    -- 支払計画再作成及びフラグ更新
    -- =====================================
    -- 関数の呼び出し(支払計画作成)
    xxcff003a05c.main(
      iv_shori_type         => cv_shori_type_1                      -- 1.処理区分
     ,in_contract_line_id   => gt_contract_line_id                  -- 2.契約明細内部ID
     ,ov_retcode            => lv_retcode
     ,ov_errbuf             => lv_errbuf
     ,ov_errmsg             => lv_errmsg
    );
    -- エラー判定
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- アプリケーション短縮名
                    ,iv_name          => cv_msg_xxcff00094          -- メッセージコード
                    ,iv_token_name1   => cv_tkn_func_name           -- トークンコード1
                    ,iv_token_value1  => cv_msg_cff_50209           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 支払計画フラグ更新(会計期間=オープン期間)
    BEGIN
      UPDATE xxcff_pay_planning xpp
      SET  xpp.accounting_if_flag     = cv_acct_if_flag_unsent          -- 会計IFフラグ('1':未送信)
          ,xpp.payment_match_flag     = lt_payment_match_flag           -- 照合フラグ
          ,xpp.last_updated_by        = cn_last_updated_by              -- 最終更新者
          ,xpp.last_update_date       = cd_last_update_date             -- 最終更新日
          ,xpp.last_update_login      = cn_last_update_login            -- 最終更新ログイン
          ,xpp.request_id             = cn_request_id                   -- 要求ID
          ,xpp.program_application_id = cn_program_application_id       -- コンカレント・プログラム・アプリケーションID
          ,xpp.program_id             = cn_program_id                   -- コンカレント・プログラムID
          ,xpp.program_update_date    = cd_program_update_date          -- プログラム更新日
      WHERE xpp.contract_line_id      = gt_contract_line_id
      AND   xpp.period_name           = gt_period_name
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50088
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 支払計画フラグ更新(会計期間<オープン期間)
    BEGIN
      UPDATE xxcff_pay_planning xpp
      SET  xpp.accounting_if_flag     = cv_acct_if_flag_sent            -- 会計IFフラグ('2':送信済)
          ,xpp.payment_match_flag     = cv_paymtch_flag_admin           -- 照合フラグ('1':照合済)
          ,xpp.last_updated_by        = cn_last_updated_by              -- 最終更新者
          ,xpp.last_update_date       = cd_last_update_date             -- 最終更新日
          ,xpp.last_update_login      = cn_last_update_login            -- 最終更新ログイン
          ,xpp.request_id             = cn_request_id                   -- 要求ID
          ,xpp.program_application_id = cn_program_application_id       -- コンカレント・プログラム・アプリケーションID
          ,xpp.program_id             = cn_program_id                   -- コンカレント・プログラムID
          ,xpp.program_update_date    = cd_program_update_date          -- プログラム更新日
      WHERE xpp.contract_line_id      = gt_contract_line_id
      AND   xpp.period_name           < gt_period_name
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50088
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
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
  END update_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : get_judge_lease
   * Description      : リース判定処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_judge_lease(
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_judge_lease'; -- プログラム名
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
    lt_first_after_charge           xxcff_contract_lines.first_charge%TYPE;                  -- 初回月額リース料(控除後)
    lt_second_after_charge          xxcff_contract_lines.second_charge%TYPE;                 -- 2回目以降月額リース料(控除後)
    lt_estimated_cash_price         xxcff_contract_lines.estimated_cash_price%TYPE;          -- 見積現金購入価額
    lt_lease_kind                   xxcff_contract_lines.lease_kind%TYPE;                    -- リース種類
    lt_present_value_discount_rate  xxcff_contract_lines.present_value_discount_rate %TYPE;  -- 現在価値割引率
    lt_present_value                xxcff_contract_lines.present_value%TYPE;                 -- 現在価値
    lt_original_cost                xxcff_contract_lines.original_cost%TYPE;                 -- 取得価額
    lt_calc_interested_rate         xxcff_contract_lines.calc_interested_rate%TYPE;          -- 計算利子率
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***       リース判定処理            ***
    -- ***************************************
--
    -- =====================================
    -- リース種別判定
    -- =====================================
    --控除後リース料算出
    lt_first_after_charge   := NVL(gr_param.first_charge,gt_first_charge) - NVL(gt_first_deduction,0);
    lt_second_after_charge  := NVL(gr_param.second_charge,gt_second_charge) - NVL(gt_second_deduction,0);
    lt_estimated_cash_price := NVL(gr_param.estimated_cash_price,gt_estimated_cash_price);
--
    -- 関数の呼び出し(リース種別判定)
    XXCFF003A03C.main(
      iv_lease_type                  => gt_lease_type                    -- 1.リース区分
     ,in_payment_frequency           => gt_payment_frequency             -- 2.支払回数
     ,in_first_charge                => lt_first_after_charge            -- 3.初回月額リース料(控除後)
     ,in_second_charge               => lt_second_after_charge           -- 4.２回目以降月額リース料（控除後）
     ,in_estimated_cash_price        => lt_estimated_cash_price          -- 5.見積現金購入価額
     ,in_life_in_months              => gt_life_in_months                -- 6.法定耐用年数
     ,id_contract_ym                 => gt_contract_date                 -- 7.契約年月
     ,ov_lease_kind                  => lt_lease_kind                    -- 8.リース種類
     ,on_present_value_discount_rate => lt_present_value_discount_rate   -- 9.現在価値割引率
     ,on_present_value               => lt_present_value                 -- 10.現在価値
     ,on_original_cost               => lt_original_cost                 -- 11.取得価額
     ,on_calc_interested_rate        => lt_calc_interested_rate          -- 12.計算利子率
     ,ov_errbuf                      => lv_errbuf
     ,ov_retcode                     => lv_retcode
     ,ov_errmsg                      => lv_errmsg
    );
    -- エラー判定
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- アプリケーション短縮名
                    ,iv_name          => cv_msg_xxcff00094          -- メッセージコード
                    ,iv_token_name1   => cv_tkn_func_name           -- トークンコード1
                    ,iv_token_value1  => cv_msg_cff_50207           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- リース契約明細に結果反映
    -- =====================================
    BEGIN
      UPDATE xxcff_contract_lines xcl
      SET  xcl.present_value               = lt_present_value                -- 現在価値
          ,xcl.original_cost               = lt_original_cost                -- 取得価額
          ,xcl.calc_interested_rate        = lt_calc_interested_rate         -- 計算利子率
          ,xcl.present_value_discount_rate = lt_present_value_discount_rate  -- 現在価値割引率
-- Del 2014/01/31 Ver.1.2 Start
--          ,xcl.lease_kind                  = lt_lease_kind                   -- リース種類
-- Del 2014/01/31 Ver.1.2 End
          ,xcl.last_updated_by             = cn_last_updated_by              -- 最終更新者
          ,xcl.last_update_date            = cd_last_update_date             -- 最終更新日
          ,xcl.last_update_login           = cn_last_update_login            -- 最終更新ログイン
          ,xcl.request_id                  = cn_request_id                   -- 要求ID
          ,xcl.program_application_id      = cn_program_application_id       -- コンカレント・プログラム・アプリケーションID
          ,xcl.program_id                  = cn_program_id                   -- コンカレント・プログラムID
          ,xcl.program_update_date         = cd_program_update_date          -- プログラム更新日
      WHERE xcl.contract_line_id           = gt_contract_line_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50030
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
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
  END get_judge_lease;
--
  /**********************************************************************************
   * Procedure Name   : update_contract_lines
   * Description      : データパッチ処理(A-5)
   ***********************************************************************************/
  PROCEDURE update_contract_lines(
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_contract_lines'; -- プログラム名
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
    lv_contract_line_id     xxcff_contract_lines.contract_line_id%TYPE;     -- 契約明細内部ID
    ln_payment_frequency    xxcff_contract_headers.payment_frequency%TYPE;  -- 支払回数
    ln_first_charge         xxcff_contract_lines.first_charge%TYPE;         -- 初回月額リース料_リース料
    ln_first_tax_charge     xxcff_contract_lines.first_tax_charge%TYPE;     -- 初回消費税額_リース料
    ln_first_total_charge   xxcff_contract_lines.first_total_charge%TYPE;   -- 初回計_リース料
    ln_second_charge        xxcff_contract_lines.second_charge%TYPE;        -- 2回目以降月額リース料_リース料
    ln_second_tax_charge    xxcff_contract_lines.second_tax_charge%TYPE;    -- 2回目以降消費税額_リース料
    ln_second_total_charge  xxcff_contract_lines.second_total_charge%TYPE;  -- 2回目以降計_リース料
    ln_gross_charge         xxcff_contract_lines.gross_charge%TYPE;         -- 総額リース料_リース料
    ln_gross_tax_charge     xxcff_contract_lines.gross_tax_charge%TYPE;     -- 総額消費税_リース料
    ln_gross_total_charge   xxcff_contract_lines.gross_total_charge%TYPE;   -- 総額計_リース料
    ln_estimated_cash_price xxcff_contract_lines.estimated_cash_price%TYPE; -- 見積現金購入価額
-- Add 2014/05/19 Ver.1.3 Start
    ln_gross_deduction       xxcff_contract_lines.gross_deduction%TYPE;       -- 総額リース料_控除額
    ln_gross_tax_deduction   xxcff_contract_lines.gross_tax_deduction%TYPE;   -- 総額消費税_控除額
    ln_gross_total_deduction xxcff_contract_lines.gross_total_deduction%TYPE; -- 総額計_控除額
-- Add 2014/05/19 Ver.1.3 End
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***      データパッチ処理           ***
    -- ***************************************
--
    -- =====================================
    -- リース契約明細更新用データ作成
    -- =====================================
    -- リース回数-1
    ln_payment_frequency   := gt_payment_frequency -1;
    -- 初回月額リース料_リース料
    ln_first_charge        := NVL(gr_param.first_charge,gt_first_charge);
    -- 初回消費税額_リース料
    ln_first_tax_charge    := NVL(gr_param.first_tax_charge,gt_first_tax_charge);
    -- 初回計_リース料
    ln_first_total_charge  := ln_first_charge + ln_first_tax_charge;
    -- 2回目以降月額リース料_リース料
    ln_second_charge       := NVL(gr_param.second_charge,gt_second_charge);
    -- 2回目以降消費税額_リース料
    ln_second_tax_charge   := NVL(gr_param.second_tax_charge,gt_second_tax_charge);
    -- 2回目以降計_リース料
    ln_second_total_charge := ln_second_charge + ln_second_tax_charge;
    -- 総額リース料_リース料
    ln_gross_charge        := ln_first_charge + (ln_second_charge * ln_payment_frequency);
    -- 総額消費税_リース料
    ln_gross_tax_charge    := ln_first_tax_charge + (ln_second_tax_charge * ln_payment_frequency);
    -- 総額計_リース料
    ln_gross_total_charge  := ln_first_total_charge + (ln_second_total_charge * ln_payment_frequency);
    -- 見積現金購入価額
    ln_estimated_cash_price := NVL(gr_param.estimated_cash_price,gt_estimated_cash_price);
-- Add 2014/05/19 Ver.1.3 Start
    -- 総額リース料_控除額
    ln_gross_deduction       := gt_first_deduction + (gt_second_deduction * ln_payment_frequency);
    -- 総額消費税_控除額
    ln_gross_tax_deduction   := gt_first_tax_deduction + (gt_second_tax_deduction * ln_payment_frequency);
    -- 総額計_控除額
    ln_gross_total_deduction := ln_gross_deduction + ln_gross_tax_deduction;
-- Add 2014/05/19 Ver.1.3 End
--
    -- =====================================
    -- リース契約明細のロックを取得
    -- =====================================
    BEGIN
      SELECT
        xcl.contract_line_id AS contract_line_id  -- 契約明細内部ID
      INTO
        lv_contract_line_id
      FROM
        xxcff_contract_lines xcl
      WHERE  xcl.contract_line_id  =  gt_contract_line_id
      FOR UPDATE OF xcl.contract_line_id NOWAIT;
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00007
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50030
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- =====================================
    -- リース契約明細テーブルの更新
    -- =====================================
    BEGIN
      UPDATE  xxcff_contract_lines xcl
      SET     xcl.first_charge            = ln_first_charge                 -- 初回月額リース料_リース料
             ,xcl.first_tax_charge        = ln_first_tax_charge             -- 初回消費税額_リース料
             ,xcl.first_total_charge      = ln_first_total_charge           -- 初回計_リース料
             ,xcl.second_charge           = ln_second_charge                -- 2回目以降月額リース料_リース料
             ,xcl.second_tax_charge       = ln_second_tax_charge            -- 2回目以降消費税額_リース料
             ,xcl.second_total_charge     = ln_second_total_charge          -- 2回目以降計_リース料
             ,xcl.gross_charge            = ln_gross_charge                 -- 総額リース料_リース料
             ,xcl.gross_tax_charge        = ln_gross_tax_charge             -- 総額消費税_リース料
             ,xcl.gross_total_charge      = ln_gross_total_charge           -- 総額計_リース料
-- Add 2014/05/19 Ver.1.3 Start
             ,xcl.gross_deduction         = ln_gross_deduction              -- 総額リース料_控除額
             ,xcl.gross_tax_deduction     = ln_gross_tax_deduction          -- 総額消費税_控除額
             ,xcl.gross_total_deduction   = ln_gross_total_deduction        -- 総額計_控除額
-- Add 2014/05/19 Ver.1.3 End
             ,xcl.estimated_cash_price    = ln_estimated_cash_price         -- 見積現金購入価額
-- Add 2013/07/11 Ver.1.1 Start
             ,xcl.tax_code                = NVL(gr_param.tax_code, xcl.tax_code) -- 税金コード
-- Add 2013/07/11 Ver.1.1 End
             ,xcl.last_updated_by         = cn_last_updated_by              -- 最終更新者
             ,xcl.last_update_date        = cd_last_update_date             -- 最終更新日
             ,xcl.last_update_login       = cn_last_update_login            -- 最終更新ログイン
             ,xcl.request_id              = cn_request_id                   -- 要求ID
             ,xcl.program_application_id  = cn_program_application_id       -- コンカレント・プログラム・アプリケーションID
             ,xcl.program_id              = cn_program_id                   -- コンカレント・プログラムID
             ,xcl.program_update_date     = cd_program_update_date          -- プログラム更新日
      WHERE   xcl.contract_line_id        = gt_contract_line_id             -- 契約明細内部ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50030
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
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
  END update_contract_lines;
--
  /**********************************************************************************
   * Procedure Name   : get_backup_data
   * Description      : データバックアップの実行(A-4)
   ***********************************************************************************/
  PROCEDURE get_backup_data(
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_backup_data'; -- プログラム名
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
    lv_run_line_num  xxcff_contract_lines_bk.run_line_num%TYPE;  -- 実行枝番
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***  データバックアップの実行の実行 ***
    -- ***************************************
--
    -- =====================================
    -- 実行枝番を取得
    -- =====================================
--
    --実行会計期間ごとの最大実行枝番＋１を取得
    BEGIN
      SELECT
         NVL(MAX(xclb.run_line_num), 0) + 1 AS run_line_num -- 最大実行枝番＋１
      INTO
         lv_run_line_num
      FROM
         xxcff_contract_lines_bk    xclb    -- リース契約明細BK
      WHERE  xclb.run_period_name    = gt_period_name
      AND    xclb.contract_header_id = gt_contract_header_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00101
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50202
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => NULL
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- =====================================
    -- リース契約明細バックアップ処理
    -- =====================================
    --リース契約明細の更新対象データのバックアップを取得
    BEGIN
      INSERT INTO xxcff_contract_lines_bk(
         contract_line_id                           -- 契約明細内部ID
        ,contract_header_id                         -- 契約内部ID
        ,contract_line_num                          -- 契約枝番
        ,contract_status                            -- 契約ステータス
        ,first_charge                               -- 初回月額リース料_リース料
        ,first_tax_charge                           -- 初回消費税額_リース料
        ,first_total_charge                         -- 初回計_リース料
        ,second_charge                              -- 2回目以降月額リース料_リース料
        ,second_tax_charge                          -- 2回目以降消費税額_リース料
        ,second_total_charge                        -- 2回目以降計_リース料
        ,first_deduction                            -- 初回月額リース料_控除額
        ,first_tax_deduction                        -- 初回月額消費税額_控除額
        ,first_total_deduction                      -- 初回計_控除額
        ,second_deduction                           -- 2回目以降月額リース料_控除額
        ,second_tax_deduction                       -- 2回目以降消費税額_控除額
        ,second_total_deduction                     -- 2回目以降計_控除額
        ,gross_charge                               -- 総額リース料_リース料
        ,gross_tax_charge                           -- 総額消費税_リース料
        ,gross_total_charge                         -- 総額計_リース料
        ,gross_deduction                            -- 総額リース料_控除額
        ,gross_tax_deduction                        -- 総額消費税_控除額
        ,gross_total_deduction                      -- 総額計_控除額
        ,lease_kind                                 -- リース種類
        ,estimated_cash_price                       -- 見積現金購入価額
        ,present_value_discount_rate                -- 現在価値割引率
        ,present_value                              -- 現在価値
        ,life_in_months                             -- 法定耐用年数
        ,original_cost                              -- 取得価額
        ,calc_interested_rate                       -- 計算利子率
        ,object_header_id                           -- 物件内部ID
        ,asset_category                             -- 資産種類
        ,expiration_date                            -- 満了日
        ,cancellation_date                          -- 中途解約日
        ,vd_if_date                                 -- リース契約情報連携日
        ,info_sys_if_date                           -- リース管理情報連携日
        ,first_installation_address                 -- 初回設置場所
        ,first_installation_place                   -- 初回設置先
-- Add 2013/07/11 Ver.1.1 Start
        ,tax_code                                   -- 税金コード
-- Add 2013/07/11 Ver.1.1 End
        ,run_period_name                            -- 実行会計期間
        ,run_line_num                               -- 実行枝番
        ,created_by                                 -- 作成者
        ,creation_date                              -- 作成日
        ,last_updated_by                            -- 最終更新者
        ,last_update_date                           -- 最終更新日
        ,last_update_login                          -- 最終更新ログイン
        ,request_id                                 -- 要求ID
        ,program_application_id                     -- コンカレント・プログラム・アプリケーションID
        ,program_id                                 -- コンカレント・プログラムID
        ,program_update_date)                       -- プログラム更新日
      SELECT
         xcl.contract_line_id
        ,xcl.contract_header_id
        ,xcl.contract_line_num
        ,xcl.contract_status
        ,xcl.first_charge
        ,xcl.first_tax_charge
        ,xcl.first_total_charge
        ,xcl.second_charge
        ,xcl.second_tax_charge
        ,xcl.second_total_charge
        ,xcl.first_deduction
        ,xcl.first_tax_deduction
        ,xcl.first_total_deduction
        ,xcl.second_deduction
        ,xcl.second_tax_deduction
        ,xcl.second_total_deduction
        ,xcl.gross_charge
        ,xcl.gross_tax_charge
        ,xcl.gross_total_charge
        ,xcl.gross_deduction
        ,xcl.gross_tax_deduction
        ,xcl.gross_total_deduction
        ,xcl.lease_kind
        ,xcl.estimated_cash_price
        ,xcl.present_value_discount_rate
        ,xcl.present_value
        ,xcl.life_in_months
        ,xcl.original_cost
        ,xcl.calc_interested_rate
        ,xcl.object_header_id
        ,xcl.asset_category
        ,xcl.expiration_date
        ,xcl.cancellation_date
        ,xcl.vd_if_date
        ,xcl.info_sys_if_date
        ,xcl.first_installation_address
        ,xcl.first_installation_place
-- Add 2013/07/11 Ver.1.1 Start
        ,xcl.tax_code
-- Add 2013/07/11 Ver.1.1 End
        ,gt_period_name
        ,lv_run_line_num
        ,xcl.created_by
        ,xcl.creation_date
        ,xcl.last_updated_by
        ,xcl.last_update_date
        ,xcl.last_update_login
        ,xcl.request_id
        ,xcl.program_application_id
        ,xcl.program_id
        ,xcl.program_update_date
      FROM   xxcff_contract_lines xcl                    --リース契約明細
      WHERE  xcl.contract_line_id = gt_contract_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00101
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50200
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => NULL
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- =====================================
    -- リース支払計画バックアップ処理
    -- =====================================
    --リース支払計画の更新対象データのバックアップを取得
    BEGIN
      INSERT INTO xxcff_pay_planning_bk(
         contract_line_id           -- 契約明細内部ID
        ,payment_frequency          -- 支払回数
        ,contract_header_id         -- 契約内部ID
        ,period_name                -- 会計期間
        ,payment_date               -- 支払日
        ,lease_charge               -- リース料
        ,lease_tax_charge           -- リース料_消費税
        ,lease_deduction            -- リース控除額
        ,lease_tax_deduction        -- リース控除額_消費税
        ,op_charge                  -- ＯＰリース料
        ,op_tax_charge              -- ＯＰリース料額_消費税
        ,fin_debt                   -- ＦＩＮリース債務額
        ,fin_tax_debt               -- ＦＩＮリース債務額_消費税
        ,fin_interest_due           -- ＦＩＮリース支払利息
        ,fin_debt_rem               -- ＦＩＮリース債務残
        ,fin_tax_debt_rem           -- ＦＩＮリース債務残_消費税
        ,accounting_if_flag         -- 会計ＩＦフラグ
        ,payment_match_flag         -- 照合済フラグ
        ,run_period_name            -- 実行会計期間
        ,run_line_num               -- 実行枝番
        ,created_by                 -- 作成者
        ,creation_date              -- 作成日
        ,last_updated_by            -- 最終更新者
        ,last_update_date           -- 最終更新日
        ,last_update_login          -- 最終更新ログイン
        ,request_id                 -- 要求ID
        ,program_application_id     -- コンカレント・プログラム・アプリケーションID
        ,program_id                 -- コンカレント・プログラムID
        ,program_update_date)       -- プログラム更新日
      SELECT
         xpp.contract_line_id
        ,xpp.payment_frequency
        ,xpp.contract_header_id
        ,xpp.period_name
        ,xpp.payment_date
        ,xpp.lease_charge
        ,xpp.lease_tax_charge
        ,xpp.lease_deduction
        ,xpp.lease_tax_deduction
        ,xpp.op_charge
        ,xpp.op_tax_charge 
        ,xpp.fin_debt 
        ,xpp.fin_tax_debt
        ,xpp.fin_interest_due 
        ,xpp.fin_debt_rem 
        ,xpp.fin_tax_debt_rem 
        ,xpp.accounting_if_flag
        ,xpp.payment_match_flag
        ,gt_period_name
        ,lv_run_line_num
        ,xpp.created_by
        ,xpp.creation_date
        ,xpp.last_updated_by
        ,xpp.last_update_date
        ,xpp.last_update_login
        ,xpp.request_id
        ,xpp.program_application_id
        ,xpp.program_id
        ,xpp.program_update_date
      FROM   xxcff_pay_planning xpp     --リース支払計画
      WHERE  xpp.contract_line_id = gt_contract_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00101
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50201
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => NULL
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
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
  END get_backup_data;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_data
   * Description      : データ出力の実行(A-3,A-9)
   ***********************************************************************************/
  PROCEDURE out_csv_data(
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_application  CONSTANT VARCHAR2(10) := 'XXCCP';
    cv_out_csv_01   CONSTANT VARCHAR2(20) := 'XXCCP008A01C';
    cv_out_csv_02   CONSTANT VARCHAR2(20) := 'XXCCP008A02C';
    cv_out_csv_03   CONSTANT VARCHAR2(20) := 'XXCCP008A03C';
    cv_out_csv_04   CONSTANT VARCHAR2(20) := 'XXCCP008A04C';
    cv_status_err   CONSTANT VARCHAR2(20) := 'ERROR';
--
    -- *** ローカル変数 ***
    ln_request_id NUMBER;
    lb_return     BOOLEAN;
    lv_phase      VARCHAR2(5000);
    lv_status     VARCHAR2(5000);
    lv_dev_phase  VARCHAR2(5000);
    lv_dev_status VARCHAR2(5000);
    lv_message    VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***     更新前データ出力の実行      ***
    -- ***************************************
--
    -- =====================================
    -- リース契約データCSV出力
    -- =====================================
    --コンカレント発行
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_out_csv_01
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => gr_param.contract_number  -- 契約番号
                       ,argument2   => NULL                      -- リース会社
                       ,argument3   => gr_param.object_code      -- 物件コード1
                       ,argument4   => NULL                      -- 物件コード2
                       ,argument5   => NULL                      -- 物件コード3
                       ,argument6   => NULL                      -- 物件コード4
                       ,argument7   => NULL                      -- 物件コード5
                       ,argument8   => NULL                      -- 物件コード6
                       ,argument9   => NULL                      -- 物件コード7
                       ,argument10  => NULL                      -- 物件コード8
                       ,argument11  => NULL                      -- 物件コード9
                       ,argument12  => NULL                      -- 物件コード10
                     );
    --
    IF (ln_request_id = 0) THEN
      -- コンカレント発行エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00197        -- メッセージコード
                     ,iv_token_name1  => cv_tkn_syori             -- トークンコード1
                     ,iv_token_value1 => cv_msg_cff_50203         -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレント待機
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => ln_request_id
                   ,interval   => gn_interval
                   ,max_wait   => gn_max_wait
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF (lb_return  = FALSE) THEN
      -- コンカレント待機エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00198         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_request_id         -- トークンコード1
                     ,iv_token_value1 => ln_request_id             -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    IF lv_status = cv_status_err THEN
      -- コンカレント処理エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00199         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_request_id         -- トークンコード1
                     ,iv_token_value1 => ln_request_id             -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
--
    -- =====================================
    -- リース物件データCSV出力
    -- =====================================
    --コンカレント発行
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_out_csv_02
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => gr_param.contract_number  -- 契約番号
                       ,argument2   => NULL                      -- リース会社
                       ,argument3   => gr_param.object_code      -- 物件コード1
                       ,argument4   => NULL                      -- 物件コード2
                       ,argument5   => NULL                      -- 物件コード3
                       ,argument6   => NULL                      -- 物件コード4
                       ,argument7   => NULL                      -- 物件コード5
                       ,argument8   => NULL                      -- 物件コード6
                       ,argument9   => NULL                      -- 物件コード7
                       ,argument10  => NULL                      -- 物件コード8
                       ,argument11  => NULL                      -- 物件コード9
                       ,argument12  => NULL                      -- 物件コード10
                     );
    --
    IF (ln_request_id = 0) THEN
      -- コンカレント発行エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00197        -- メッセージコード
                     ,iv_token_name1  => cv_tkn_syori             -- トークンコード1
                     ,iv_token_value1 => cv_msg_cff_50204         -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレント待機
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => ln_request_id
                   ,interval   => gn_interval
                   ,max_wait   => gn_max_wait
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF (lb_return  = FALSE) THEN
      -- コンカレント待機エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00198         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_request_id         -- トークンコード1
                     ,iv_token_value1 => ln_request_id             -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    IF lv_status = cv_status_err THEN
      -- コンカレント処理エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00199         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_request_id         -- トークンコード1
                     ,iv_token_value1 => ln_request_id             -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
--
    -- =====================================
    -- リース支払計画データCSV出力
    -- =====================================
    --コンカレント発行
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_out_csv_03
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => gr_param.contract_number  -- 契約番号
                       ,argument2   => NULL                      -- リース会社
                       ,argument3   => gr_param.object_code      -- 物件コード1
                       ,argument4   => NULL                      -- 物件コード2
                       ,argument5   => NULL                      -- 物件コード3
                       ,argument6   => NULL                      -- 物件コード4
                       ,argument7   => NULL                      -- 物件コード5
                       ,argument8   => NULL                      -- 物件コード6
                       ,argument9   => NULL                      -- 物件コード7
                       ,argument10  => NULL                      -- 物件コード8
                       ,argument11  => NULL                      -- 物件コード9
                       ,argument12  => NULL                      -- 物件コード10
                     );
    --
    IF (ln_request_id = 0) THEN
      -- コンカレント発行エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00197        -- メッセージコード
                     ,iv_token_name1  => cv_tkn_syori             -- トークンコード1
                     ,iv_token_value1 => cv_msg_cff_50205         -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレント待機
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => ln_request_id
                   ,interval   => gn_interval
                   ,max_wait   => gn_max_wait
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF (lb_return  = FALSE) THEN
      -- コンカレント待機エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00198         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_request_id         -- トークンコード1
                     ,iv_token_value1 => ln_request_id             -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    IF lv_status = cv_status_err THEN
      -- コンカレント処理エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00199         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_request_id         -- トークンコード1
                     ,iv_token_value1 => ln_request_id             -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
--
    -- =====================================
    -- リース会計基準情報データCSV出力
    -- =====================================
    --コンカレント発行
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_out_csv_04
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => gr_param.contract_number  -- 契約番号
                       ,argument2   => NULL                      -- リース会社
                       ,argument3   => gr_param.object_code      -- 物件コード1
                       ,argument4   => NULL                      -- 物件コード2
                       ,argument5   => NULL                      -- 物件コード3
                       ,argument6   => NULL                      -- 物件コード4
                       ,argument7   => NULL                      -- 物件コード5
                       ,argument8   => NULL                      -- 物件コード6
                       ,argument9   => NULL                      -- 物件コード7
                       ,argument10  => NULL                      -- 物件コード8
                       ,argument11  => NULL                      -- 物件コード9
                       ,argument12  => NULL                      -- 物件コード10
                     );
    --
    IF (ln_request_id = 0) THEN
      -- コンカレント発行エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00197        -- メッセージコード
                     ,iv_token_name1  => cv_tkn_syori             -- トークンコード1
                     ,iv_token_value1 => cv_msg_cff_50206         -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレント待機
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => ln_request_id
                   ,interval   => gn_interval
                   ,max_wait   => gn_max_wait
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF (lb_return  = FALSE) THEN
      -- コンカレント待機エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00198         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_request_id         -- トークンコード1
                     ,iv_token_value1 => ln_request_id             -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    IF lv_status = cv_status_err THEN
      -- コンカレント処理エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcff00199         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_request_id         -- トークンコード1
                     ,iv_token_value1 => ln_request_id             -- トークン値1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
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
  END out_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : 入力パラメータチェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
    iv_object_code           IN  VARCHAR2,      --   1.物件コード
    iv_contract_number       IN  VARCHAR2,      --   2.契約番号
    iv_update_reason         IN  VARCHAR2,      --   3.更新事由
    iv_first_charge          IN  VARCHAR2,      --   4.初回リース料
    iv_second_charge         IN  VARCHAR2,      --   5.2回目以降のリース料
    iv_first_tax_charge      IN  VARCHAR2,      --   6.初回消費税
    iv_second_tax_charge     IN  VARCHAR2,      --   7.2回目以降の消費税
    iv_estimated_cash_price  IN  VARCHAR2,      --   8.見積現金購入価額
-- Add 2013/07/11 Ver.1.1 Start
    iv_tax_code              IN  VARCHAR2,      --   9.税金コード
-- ADd 2013/07/11 Ver.1.1 End
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- プログラム名
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
    ln_upd_cnt       NUMBER;                                     -- 更新件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***    パラメータチェック処理       ***
    -- ***************************************
--
    -- =====================================
    -- 必須パラメータチェック
    -- =====================================
--
    -- 1 : 物件コード(必須)
    IF iv_object_code IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00157
                     ,iv_token_name1  => cv_tkn_input
                     ,iv_token_value1 => cv_msg_cff_50010
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 2 : 契約番号(必須)
    IF iv_contract_number IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00157
                     ,iv_token_name1  => cv_tkn_input
                     ,iv_token_value1 => cv_msg_cff_50040
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3 : 更新事由(必須)
    IF iv_update_reason IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00157
                     ,iv_token_name1  => cv_tkn_input
                     ,iv_token_value1 => cv_msg_cff_50199
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- メンテナンス項目チェック
    -- =====================================
    IF (iv_first_charge IS NULL) AND 
       (iv_second_charge IS NULL) AND 
       (iv_first_tax_charge IS NULL) AND 
       (iv_second_tax_charge IS NULL) AND 
-- Mod 2013/07/11 Ver.1.1 Start
--       (iv_estimated_cash_price IS NULL) THEN
       (iv_estimated_cash_price IS NULL) AND
       (iv_tax_code IS NULL) THEN
-- Mod 2013/07/11 Ver.1.1 End
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00207
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- パラメータ型・桁数チェック
    -- (パラメータ値の格納)
    -- =====================================
--
    -- 1 : 物件コード(必須)
    BEGIN
      gr_param.object_code := iv_object_code;
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00200
                       ,iv_token_name1  => cv_tkn_input
                       ,iv_token_value1 => cv_msg_cff_50010
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 2 : 契約番号(必須)
    BEGIN
      gr_param.contract_number := iv_contract_number;
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00200
                       ,iv_token_name1  => cv_tkn_input
                       ,iv_token_value1 => cv_msg_cff_50040
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 3 : 更新事由(必須)
    BEGIN
      gr_param.update_reason := iv_update_reason;
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00200
                       ,iv_token_name1  => cv_tkn_input
                       ,iv_token_value1 => cv_msg_cff_50199
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 4 : 初回リース料(任意)
    IF iv_first_charge IS NOT NULL THEN
      BEGIN
        gr_param.first_charge := TO_NUMBER(iv_first_charge);
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50223
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.first_charge := NULL;
    END IF;
--
    -- 5 : 2回目以降のリース料(任意)
    IF iv_second_charge IS NOT NULL THEN
      BEGIN
        gr_param.second_charge := TO_NUMBER(iv_second_charge);
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50224
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.second_charge := NULL;
    END IF;
--
    -- 6 : 初回消費税(任意)
    IF iv_first_tax_charge IS NOT NULL THEN
      BEGIN
        gr_param.first_tax_charge := TO_NUMBER(iv_first_tax_charge);
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50225
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.first_tax_charge := NULL;
    END IF;
--
    -- 7 : 2回目以降の消費税(任意)
    IF iv_second_tax_charge IS NOT NULL THEN
      BEGIN
        gr_param.second_tax_charge := TO_NUMBER(iv_second_tax_charge);
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50226
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.second_tax_charge := NULL;
    END IF;
--
    -- 8 : 見積現金購入価額(任意)
    IF iv_estimated_cash_price IS NOT NULL THEN
      BEGIN
        gr_param.estimated_cash_price := TO_NUMBER(iv_estimated_cash_price);
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50110
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.estimated_cash_price := NULL;
    END IF;
--
-- Add 2013/07/11 Ver.1.1 Start
    -- 9 : 税金コード(任意)
    IF iv_tax_code IS NOT NULL THEN
      BEGIN
        gr_param.tax_code := iv_tax_code;
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50148
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.tax_code := NULL;
    END IF;
-- ADd 2013/07/11 Ver.1.1 End
--
    -- =====================================
    -- データの存在チェック
    -- =====================================
    --リース物件
    BEGIN
      SELECT
        xoh.object_header_id AS object_header_id -- 物件内部ID
      INTO
        gt_object_header_id
      FROM
         xxcff_object_headers xoh                -- リース物件
      WHERE  xoh.object_code = gr_param.object_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- 物件内部IDが取得できない場合はエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00123
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => gr_param.object_code
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --リース契約明細
    BEGIN
      SELECT
         xcl.contract_line_id                  AS contract_line_id
        ,xcl.first_charge                      AS first_charge
        ,xcl.first_tax_charge                  AS first_tax_charge
        ,xcl.second_charge                     AS second_charge
        ,xcl.second_tax_charge                 AS second_tax_charge
        ,xcl.first_deduction                   AS first_deduction
        ,xcl.second_deduction                  AS second_deduction
-- Add 2014/05/19 Ver.1.3 Start
        ,xcl.first_tax_deduction               AS first_tax_deduction
        ,xcl.second_tax_deduction              AS second_tax_deduction
-- Add 2014/05/19 Ver.1.3 End
        ,xcl.estimated_cash_price              AS estimated_cash_price
        ,xcl.life_in_months                    AS life_in_months
        ,xch.contract_header_id                AS contract_header_id
        ,TRUNC(xch.contract_date, cv_format_m) AS contract_date
        ,xch.lease_type                        AS lease_type
        ,xch.payment_frequency                 AS payment_frequency
      INTO
         gt_contract_line_id           -- 契約明細内部ID
        ,gt_first_charge               -- 初回月額リース料_リース料
        ,gt_first_tax_charge           -- 初回消費税額_リース料
        ,gt_second_charge              -- 2回目以降月額リース料_リース料
        ,gt_second_tax_charge          -- 2回目以降消費税額_リース料
        ,gt_first_deduction            -- 初回月額リース料_控除額
        ,gt_second_deduction           -- 2回目以降月額リース料_控除額
-- Add 2014/05/19 Ver.1.3 Start
        ,gt_first_tax_deduction        -- 初回月額消費税額_控除額
        ,gt_second_tax_deduction       -- 2回目以降消費税額_控除額
-- Add 2014/05/19 Ver.1.3 End
        ,gt_estimated_cash_price       -- 見積現金購入価額
        ,gt_life_in_months             -- 法定耐用年数
        ,gt_contract_header_id         -- 契約内部ID
        ,gt_contract_date              -- リース契約日
        ,gt_lease_type                 -- リース区分
        ,gt_payment_frequency          -- 支払回数
      FROM
         xxcff_contract_lines    xcl   -- リース契約明細
        ,xxcff_contract_headers  xch   -- リース契約ヘッダ
        ,xxcff_object_headers    xoh   -- リース物件
      WHERE  xcl.object_header_id   = xoh.object_header_id
      AND    xch.contract_number    = gr_param.contract_number
      AND    xoh.object_code        = gr_param.object_code
      AND    xcl.contract_header_id = xch.contract_header_id
      AND    xcl.contract_status   IN (cv_ctrct_st_ctrct,cv_ctrct_st_reles)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- 契約明細情報が取得できない場合はエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00208
                       ,iv_token_name1  => cv_tkn_prm_name
                       ,iv_token_value1 => cv_msg_cff_50040
                       ,iv_token_name2  => cv_tkn_column
                       ,iv_token_value2 => gr_param.contract_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- 対象件数
    ln_upd_cnt    := SQL%ROWCOUNT;
    gn_target_cnt := ln_upd_cnt;    -- 対象件数
--
  EXCEPTION
--
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
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
       iv_which    => cv_file_type_log     -- 出力区分
      ,ov_retcode  => lv_retcode           -- リターンコード
      ,ov_errbuf   => lv_errbuf            -- エラーメッセージ
      ,ov_errmsg   => lv_errmsg            -- ユーザー・エラーメッセージ
    );
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- アプリケーション短縮名
                    ,iv_name          => cv_msg_xxcff00094          -- メッセージコード
                    ,iv_token_name1   => cv_tkn_func_name           -- トークンコード1
                    ,iv_token_value1  => cv_msg_cff_50210           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- =====================================
    -- リース台帳オープン期間取得
    -- =====================================
    BEGIN
      SELECT
         fdp.period_name                AS period_name
        ,fdp.calendar_period_close_date AS calendar_period_close_date
      INTO
         gt_period_name
        ,gd_period_close_date
      FROM
         fa_deprn_periods    fdp   -- 減価償却期間
        ,xxcff_lease_kind_v  xlkv  -- リース種類ビュー
      WHERE   fdp.book_type_code    = xlkv.book_type_code
      AND     xlkv.lease_kind_code  = cv_les_kind_fin        --'0':Finリース
      AND     fdp.period_close_date IS NULL                  -- オープン期間
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00186
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- プロファイル値の取得
    -- ============================================
    -- XXCOS:待機間隔
    gn_interval := TO_NUMBER(fnd_profile.value(cv_prof_interval));
    --
    IF (gn_interval IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- アプリケーション短縮名
                    ,iv_name          => cv_msg_xxcff00020          -- メッセージコード
                    ,iv_token_name1   => cv_tkn_prof_name           -- トークンコード1
                    ,iv_token_value1  => cv_prof_interval           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- XXCOS:最大待機時間
    gn_max_wait := TO_NUMBER(fnd_profile.value(cv_prof_max_wait));
    --
    IF (gn_max_wait IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- アプリケーション短縮名
                    ,iv_name          => cv_msg_xxcff00020          -- メッセージコード
                    ,iv_token_name1   => cv_tkn_prof_name           -- トークンコード1
                    ,iv_token_value1  => cv_prof_max_wait           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_object_code            IN    VARCHAR2,        --   1.物件コード
    iv_contract_number        IN    VARCHAR2,        --   2.契約番号
    iv_update_reason          IN    VARCHAR2,        --   3.更新事由
    iv_first_charge           IN    VARCHAR2,        --   4.初回リース料
    iv_second_charge          IN    VARCHAR2,        --   5.2回目以降のリース料
    iv_first_tax_charge       IN    VARCHAR2,        --   6.初回消費税
    iv_second_tax_charge      IN    VARCHAR2,        --   7.2回目以降の消費税
    iv_estimated_cash_price   IN    VARCHAR2,        --   8.見積現金購入価額
-- Add 2013/07/11 Ver.1.1 Start
    iv_tax_code               IN    VARCHAR2,        --   9.税金コード
-- ADd 2013/07/11 Ver.1.1 End
    ov_errbuf                 OUT   VARCHAR2,        --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT   VARCHAR2,        --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT   VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
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
    gn_target_cnt               := 0;
    gn_normal_cnt               := 0;
    gn_error_cnt                := 0;
    gn_warn_cnt                 := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ============================================
    -- A-1．初期処理
    -- ============================================
--
    init(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．入力パラメータチェック処理
    -- ============================================
--
    chk_param(
       iv_object_code            --   1.物件コード
      ,iv_contract_number        --   2.契約番号
      ,iv_update_reason          --   3.更新事由
      ,iv_first_charge           --   4.初回リース料
      ,iv_second_charge          --   5.2回目以降のリース料
      ,iv_first_tax_charge       --   6.初回消費税
      ,iv_second_tax_charge      --   7.2回目以降の消費税
      ,iv_estimated_cash_price   --   8.見積現金購入価額
-- Add 2013/07/11 Ver.1.1 Start
      ,iv_tax_code               --   9.税金コード
-- ADd 2013/07/11 Ver.1.1 End
      ,lv_errbuf                 --   エラー・メッセージ           --# 固定 #
      ,lv_retcode                --   リターン・コード             --# 固定 #
      ,lv_errmsg                 --   ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．更新前データ出力の実行
    -- ============================================
--
    out_csv_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4．データバックアップの実行
    -- ============================================
--
    get_backup_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-5．データパッチ処理
    -- ============================================
--
    update_contract_lines(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-6．リース判定処理
    -- ============================================
--
    get_judge_lease(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7．支払計画再作成及びフラグ更新
    -- ============================================
--
    update_pay_planning(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-8．リース契約明細の履歴の作成
    -- ============================================
--
    insert_contract_histories(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-9．更新後データ出力の実行
    -- ============================================
--
    out_csv_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 正常終了件数
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ***
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      gn_error_cnt  :=  gn_error_cnt + 1;
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode                   OUT   VARCHAR2,        --   エラーコード     #固定#
    iv_object_code            IN    VARCHAR2,        --   1.物件コード
    iv_contract_number        IN    VARCHAR2,        --   2.契約番号
    iv_update_reason          IN    VARCHAR2,        --   3.更新事由
    iv_first_charge           IN    VARCHAR2,        --   4.初回リース料
    iv_second_charge          IN    VARCHAR2,        --   5.2回目以降のリース料
    iv_first_tax_charge       IN    VARCHAR2,        --   6.初回消費税
    iv_second_tax_charge      IN    VARCHAR2,        --   7.2回目以降の消費税
-- Mod 2013/07/11 Ver.1.1 Start
--    iv_estimated_cash_price   IN    VARCHAR2         --   8.見積現金購入価額
    iv_estimated_cash_price   IN    VARCHAR2,        --   8.見積現金購入価額
    iv_tax_code               IN    VARCHAR2         --   9.税金コード
-- Mod 2013/07/11 Ver.1.1 End
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
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
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_file_type_out
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
       iv_object_code             --   1.物件コード
      ,iv_contract_number         --   2.契約番号
      ,iv_update_reason           --   3.更新事由
      ,iv_first_charge            --   4.初回リース料
      ,iv_second_charge           --   5.2回目以降のリース料
      ,iv_first_tax_charge        --   6.初回消費税
      ,iv_second_tax_charge       --   7.2回目以降の消費税
      ,iv_estimated_cash_price    --   8.見積現金購入価額
-- Add 2013/07/11 Ver.1.1 Start
      ,iv_tax_code                --   9.税金コード
-- ADd 2013/07/11 Ver.1.1 End
      ,lv_errbuf                  --   エラー・メッセージ           --# 固定 #
      ,lv_retcode                 --   リターン・コード             --# 固定 #
      ,lv_errmsg                  --   ユーザー・エラー・メッセージ --# 固定 #
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
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
--    --終了ステータスがエラーの場合はROLLBACKする
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
END XXCFF016A36C;
/
