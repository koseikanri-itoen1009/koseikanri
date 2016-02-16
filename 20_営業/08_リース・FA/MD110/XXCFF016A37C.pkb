create or replace
PACKAGE BODY XXCFF016A37C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCFF016A37C(body)
 * Description      : 再リース待メンテナンスアップロード
 * MD.050           : MD050_CFF_016_A37_再リース待メンテナンスアップロード
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  update_pay_planning          支払計画の更新                            (A-9)
 *  insert_contract_histories    リース契約明細履歴の作成                  (A-8)
 *  update_contract_lines        リース契約明細の更新                      (A-7)
 *  insert_object_histories      リース物件履歴の作成                      (A-6)
 *  update_object                リース物件の更新                          (A-5)
 *  get_contract_lines           リース契約明細のチェック処理              (A-4)
 *  chk_param                    物件コードチェック処理                    (A-3)
 *  get_upload_data              ファイルアップロードIFデータ取得処理      (A-2)
 *  init                         初期処理                                  (A-1)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/01/14    1.0   SCSK 小路        新規作成
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCFF016A37C';      -- パッケージ名
--
  -- 出力タイプ
  cv_file_type_out        CONSTANT VARCHAR2(10)  := 'OUTPUT';            -- 出力(ユーザメッセージ用出力先)
  cv_file_type_log        CONSTANT VARCHAR2(10)  := 'LOG';               -- ログ(システム管理者用出力先)
  -- アプリケーション短縮名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCFF';             -- アドオン：会計・リース・FA領域
  -- 日付形式
  cv_format_yyyy_mm       CONSTANT VARCHAR2(7)   := 'YYYY-MM';           -- 日付形式：YYYY-MM
  cv_format_yyyymmdd      CONSTANT VARCHAR2(8)   := 'YYYYMMDD';           -- 日付形式：YYYYMMDD
  -- 更新用
  cv_description          CONSTANT VARCHAR2(23)  := '再リース待メンテナンス ';   -- 摘要
  -- メッセージ名(本文)
  cv_msg_xxcff00007       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007';  -- ロックエラー
  cv_msg_xxcff00094       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094';  -- 共通関数エラー
  cv_msg_xxcff00102       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102';  -- 登録エラー
  cv_msg_xxcff00104       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104';  -- 削除エラー
  cv_msg_xxcff00123       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00123';  -- 存在チェックエラー
  cv_msg_xxcff00165       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00165';  -- 取得対象データ無し
  cv_msg_xxcff00167       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00167';  -- アップロード初期出力メッセージ
  cv_msg_xxcff00186       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00186';  -- 会計期間取得エラー
  cv_msg_xxcff00195       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00195';  -- 更新エラー
  cv_msg_xxcff00237       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00237';  -- リース物件情報出力
  cv_msg_xxcff00238       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00238';  -- リース物件ステータスチェックエラー
  cv_msg_xxcff00239       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00239';  -- リース契約ステータス出力
  cv_msg_xxcff00240       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00240';  -- リース契約ステータスエラー
  cv_msg_xxcff00241       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00241';  -- リース支払計画更新期間数出力
  -- トークン
  cv_tkn_file_name        CONSTANT VARCHAR2(15)  := 'FILE_NAME';         -- ファイル名
  cv_tkn_csv_name         CONSTANT VARCHAR2(15)  := 'CSV_NAME';          -- CSVファイル名
  cv_tkn_func_name        CONSTANT VARCHAR2(15)  := 'FUNC_NAME';         -- 関数名
  cv_tkn_object_code      CONSTANT VARCHAR2(15)  := 'OBJECT_CODE';       -- 物件コード
  cv_tkn_object_status    CONSTANT VARCHAR2(15)  := 'OBJECT_STATUS';     -- 物件ステータス
  cv_tkn_re_lease_times   CONSTANT VARCHAR2(15)  := 'RE_LEASE_TIMES';    -- 再リース回数
  cv_tkn_contract_status  CONSTANT VARCHAR2(15)  := 'CONTRACT_STATUS';   -- 契約ステータス
  cv_tkn_column           CONSTANT VARCHAR2(15)  := 'COLUMN_DATA';       -- リース物件情報
  cv_tkn_get              CONSTANT VARCHAR2(15)  := 'GET_DATA';          -- リース契約明細情報
  cv_tkn_table            CONSTANT VARCHAR2(15)  := 'TABLE_NAME';        -- テーブル名
  cv_tkn_info             CONSTANT VARCHAR2(15)  := 'INFO';              -- SQLERRM
  cv_tkn_count            CONSTANT VARCHAR2(15)  := 'COUNT';             -- リース支払計画更新期間数
  -- トークン値
  cv_msg_cff_50014        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50014';  -- リース物件テーブル
  cv_msg_cff_50023        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50023';  -- リース物件履歴テーブル
  cv_msg_cff_50030        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50030';  -- リース契約明細テーブル
  cv_msg_cff_50070        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50070';  -- リース契約明細履歴テーブル
  cv_msg_cff_50131        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131';  -- BLOBデータ変換用関数
  cv_msg_cff_50175        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175';  -- ファイルアップロードI/Fテーブル
  cv_msg_cff_50210        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50210';  -- コンカレントパラメータ出力処理
  cv_msg_cff_50220        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50220';  -- リース契約明細
  cv_msg_cff_50283        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50283';  -- リース支払計画テーブル
  cv_msg_cff_50284        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50284';  -- 再リース待メンテナンス
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイルアップロードIFデータ
  g_file_upload_if_data_tab      xxccp_common_pkg2.g_file_data_tbl;
--
  -- テーブル取得用定義
  TYPE g_object_header_id_ttype      IS TABLE OF xxcff_object_headers.object_header_id%TYPE INDEX BY PLS_INTEGER;           -- 物件内部ID
  TYPE g_re_lease_times_ttype        IS TABLE OF xxcff_object_headers.re_lease_times%TYPE INDEX BY PLS_INTEGER;             -- 再リース回数
  TYPE g_contract_header_id_ttype    IS TABLE OF xxcff_contract_lines.contract_header_id%TYPE INDEX BY PLS_INTEGER;         -- 契約内部ID
  TYPE g_contract_line_id_ttype      IS TABLE OF xxcff_contract_lines.contract_line_id%TYPE INDEX BY PLS_INTEGER;           -- 契約明細内部ID
  TYPE g_contract_status_ttype       IS TABLE OF xxcff_contract_lines.contract_status%TYPE INDEX BY PLS_INTEGER;            -- 契約ステータス
  TYPE g_contract_status_name_ttype  IS TABLE OF xxcff_contract_status_v.contract_status_name%TYPE INDEX BY PLS_INTEGER;    -- 契約ステータス名
--
  g_object_header_id_tab           g_object_header_id_ttype;                     -- 物件内部ID
  g_re_lease_times_tab             g_re_lease_times_ttype;                       -- 再リース回数
  g_contract_header_id_tab         g_contract_header_id_ttype;                   -- 契約内部ID
  g_contract_line_id_tab           g_contract_line_id_ttype;                     -- 契約明細内部ID
  g_contract_status_tab            g_contract_status_ttype;                      -- 契約ステータス
  g_contract_status_name_tab       g_contract_status_name_ttype;                 -- 契約ステータス名
--
  gt_period_name                   fa_deprn_periods.period_name%TYPE;            -- 会計期間(リース台帳最終クローズ期間)
--
  /**********************************************************************************
   * Procedure Name   : update_pay_planning
   * Description      : 支払計画の更新(A-9)
   ***********************************************************************************/
  PROCEDURE update_pay_planning(
    in_loop_cnt              IN  NUMBER,        --   ループカウンタ
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
    cv_accounting_if_flag_1    CONSTANT VARCHAR2(1) := '1';                -- 未送信
    cv_accounting_if_flag_3    CONSTANT VARCHAR2(1) := '3';                -- 照合不可
--
    -- *** ローカル変数 ***
    ln_upd_cnt                 NUMBER;         -- ループカウンタ
    TYPE l_rowid_ttype         IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_pay_rowid               l_rowid_ttype;
--
    -- *** ローカル・カーソル ***
    CURSOR pay_data_cur
    IS
      SELECT xpp.rowid  AS row_id   -- 更新用行ID
      FROM   xxcff_pay_planning  xpp
      WHERE  xpp.contract_header_id = g_contract_header_id_tab(in_loop_cnt)
      AND    xpp.contract_line_id   = g_contract_line_id_tab(in_loop_cnt)
      AND    xpp.accounting_if_flag = cv_accounting_if_flag_1
      FOR UPDATE NOWAIT;
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
    -- ***       支払計画の更新            ***
    -- ***************************************
--
    -- =====================================
    -- 1.リース支払計画のロックを取得
    -- =====================================
    BEGIN
      -- カーソルのオープン
      OPEN   pay_data_cur;
      -- 更新対象データ取得
      FETCH  pay_data_cur BULK COLLECT INTO lt_pay_rowid;
      -- カーソルのクローズ
      CLOSE pay_data_cur;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00007
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50283
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 更新対象が存在する場合
    IF ( lt_pay_rowid.COUNT > 0 ) THEN
      BEGIN
        FORALL ln_upd_cnt IN lt_pay_rowid.FIRST..lt_pay_rowid.LAST
        -- 会計IFフラグ更新
          UPDATE xxcff_pay_planning xpp
          SET    xpp.accounting_if_flag     = cv_accounting_if_flag_3         -- 会計IFフラグ('3':照合不可)
                ,xpp.last_updated_by        = cn_last_updated_by              -- 最終更新者
                ,xpp.last_update_date       = cd_last_update_date             -- 最終更新日
                ,xpp.last_update_login      = cn_last_update_login            -- 最終更新ログイン
                ,xpp.request_id             = cn_request_id                   -- 要求ID
                ,xpp.program_application_id = cn_program_application_id       -- コンカレント・プログラム・アプリケーションID
                ,xpp.program_id             = cn_program_id                   -- コンカレント・プログラムID
                ,xpp.program_update_date    = cd_program_update_date          -- プログラム更新日
          WHERE  xpp.ROWID = lt_pay_rowid(ln_upd_cnt)
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00195
                         ,iv_token_name1  => cv_tkn_table
                         ,iv_token_value1 => cv_msg_cff_50283
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      -- リース支払計画更新期間数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcff00241
                      ,iv_token_name1  => cv_tkn_object_code
                      ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                      ,iv_token_name2  => cv_tkn_count
                      ,iv_token_value2 => TO_NUMBER(lt_pay_rowid.COUNT)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
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
      --例外発生時、カーソルがオープンされていた場合、カーソルをクローズする。
      IF ( pay_data_cur%ISOPEN ) THEN
        CLOSE   pay_data_cur;
      END IF;
--
  END update_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : insert_contract_histories
   * Description      : リース契約明細履歴の作成(A-8)
   ***********************************************************************************/
  PROCEDURE insert_contract_histories(
    in_loop_cnt              IN  NUMBER,        --   ループカウンタ
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
    cv_if_flag_sent       CONSTANT VARCHAR2(1)   := '2';                       -- 送信済
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
        ,tax_code                              -- 税金コード
        ,accounting_date                       -- 計上日
        ,accounting_if_flag                    -- 会計ＩＦフラグ
        ,description                           -- 摘要
        ,update_reason                         -- 更新事由
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
         xcl.contract_header_id                                 contract_header_id             -- 契約内部ID
        ,xcl.contract_line_id                                   contract_line_id               -- 契約明細内部ID
        ,xxcff_contract_histories_s1.NEXTVAL                    history_num                    -- 契約明細履歴シーケンス(変更履歴NO)
        ,xcl.contract_status                                    contract_status                -- 契約ステータス
        ,xcl.first_charge                                       first_charge                   -- 初回月額リース料_リース料
        ,xcl.first_tax_charge                                   first_tax_charge               -- 初回消費税額_リース料
        ,xcl.first_total_charge                                 first_total_charge             -- 初回計_リース料
        ,xcl.second_charge                                      second_charge                  -- 2回目以降月額リース料_リース料
        ,xcl.second_tax_charge                                  second_tax_charge              -- 2回目以降消費税額_リース料
        ,xcl.second_total_charge                                second_total_charge            -- 2回目以降計_リース料
        ,xcl.first_deduction                                    first_deduction                -- 初回月額リース料_控除額
        ,xcl.first_tax_deduction                                first_tax_deduction            -- 初回月額消費税額_控除額
        ,xcl.first_total_deduction                              first_total_deduction          -- 初回計_控除額
        ,xcl.second_deduction                                   second_deduction               -- 2回目以降月額リース料_控除額
        ,xcl.second_tax_deduction                               second_tax_deduction           -- 2回目以降消費税額_控除額
        ,xcl.second_total_deduction                             second_total_deduction         -- 2回目以降計_控除額
        ,xcl.gross_charge                                       gross_charge                   -- 総額リース料_リース料
        ,xcl.gross_tax_charge                                   gross_tax_charge               -- 総額消費税_リース料
        ,xcl.gross_total_charge                                 gross_total_charge             -- 総額計_リース料
        ,xcl.gross_deduction                                    gross_deduction                -- 総額リース料_控除額
        ,xcl.gross_tax_deduction                                gross_tax_deduction            -- 総額消費税_控除額
        ,xcl.gross_total_deduction                              gross_total_deduction          -- 総額計_控除額
        ,xcl.lease_kind                                         lease_kind                     -- リース種類
        ,xcl.estimated_cash_price                               estimated_cash_price           -- 見積現金購入価額
        ,xcl.present_value_discount_rate                        present_value_discount_rate    -- 現在価値割引率
        ,xcl.present_value                                      present_value                  -- 現在価値
        ,xcl.life_in_months                                     life_in_months                 -- 法定耐用年数
        ,xcl.original_cost                                      original_cost                  -- 取得価額
        ,xcl.calc_interested_rate                               calc_interested_rate           -- 計算利子率
        ,xcl.object_header_id                                   object_header_id               -- 物件内部ID
        ,xcl.asset_category                                     asset_category                 -- 資産種類
        ,xcl.expiration_date                                    expiration_date                -- 満了日
        ,xcl.cancellation_date                                  cancellation_date              -- 中途解約日
        ,xcl.vd_if_date                                         vd_if_date                     -- リース契約情報連携日
        ,xcl.info_sys_if_date                                   info_sys_if_date               -- リース管理情報連携日
        ,xcl.first_installation_address                         first_installation_address     -- 初回設置場所
        ,xcl.first_installation_place                           first_installation_place       -- 初回設置先
        ,xcl.tax_code                                           tax_code                       -- 税金コード
        ,LAST_DAY(TO_DATE(gt_period_name, cv_format_yyyy_mm))   accounting_date                -- 計上日
        ,cv_if_flag_sent                                        accounting_if_flag             -- 会計ＩＦフラグ('2':送信済)
        ,cv_description || TO_CHAR(SYSDATE, cv_format_yyyymmdd) description                    -- 摘要
        ,NULL                                                   update_reason                  -- 更新事由
        ,cn_created_by                                          created_by                     -- 作成者
        ,cd_creation_date                                       creation_date                  -- 作成日
        ,cn_last_updated_by                                     last_updated_by                -- 最終更新者
        ,cd_last_update_date                                    last_update_date               -- 最終更新日
        ,cn_last_update_login                                   last_update_login              -- 最終更新ログイン
        ,cn_request_id                                          request_id                     -- 要求ID
        ,cn_program_application_id                              program_application_id         -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id                                          program_id                     -- コンカレント・プログラムID
        ,cd_program_update_date                                 program_update_date            -- プログラム更新日
      FROM   xxcff_contract_lines xcl          -- リース契約明細
      WHERE  xcl.contract_header_id = g_contract_header_id_tab(in_loop_cnt)
      AND    xcl.contract_line_id   = g_contract_line_id_tab(in_loop_cnt)
      ;
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
   * Procedure Name   : update_contract_lines
   * Description      : リース契約明細の更新(A-7)
   ***********************************************************************************/
  PROCEDURE update_contract_lines(
    in_loop_cnt              IN  NUMBER,        --   ループカウンタ
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
    cv_contract_status_204    CONSTANT VARCHAR2(3)   := '204';       -- 満了
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
    -- ***    リース契約明細の更新         ***
    -- ***************************************
--
    -- =====================================
    -- リース契約明細テーブルの更新
    -- =====================================
    BEGIN
      UPDATE  xxcff_contract_lines xcl
      SET     xcl.contract_status         = cv_contract_status_204                                 -- 契約ステータス
             ,xcl.expiration_date         = LAST_DAY(TO_DATE(gt_period_name, cv_format_yyyy_mm))   -- 満了日
             ,xcl.last_updated_by         = cn_last_updated_by                                     -- 最終更新者
             ,xcl.last_update_date        = cd_last_update_date                                    -- 最終更新日
             ,xcl.last_update_login       = cn_last_update_login                                   -- 最終更新ログイン
             ,xcl.request_id              = cn_request_id                                          -- 要求ID
             ,xcl.program_application_id  = cn_program_application_id                              -- コンカレント・プログラム・アプリケーションID
             ,xcl.program_id              = cn_program_id                                          -- コンカレント・プログラムID
             ,xcl.program_update_date     = cd_program_update_date                                 -- プログラム更新日
      WHERE   xcl.contract_header_id  = g_contract_header_id_tab(in_loop_cnt)           -- 契約内部ID
      AND     xcl.contract_line_id    = g_contract_line_id_tab(in_loop_cnt)             -- 契約明細内部ID
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
   * Procedure Name   : insert_object_histories
   * Description      : リース物件履歴の作成(A-6)
   ***********************************************************************************/
  PROCEDURE insert_object_histories(
    in_loop_cnt              IN  NUMBER,        --   ループカウンタ
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_object_histories'; -- プログラム名
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
    accounting_if_flag_2    CONSTANT VARCHAR2(1)   := '2';                        -- 会計ＩＦフラグ：送信済
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
    -- ***    リース物件履歴の作成         ***
    -- ***************************************
--
    -- =====================================
    -- リース物件履歴の作成
    -- =====================================
    BEGIN
      INSERT INTO xxcff_object_histories(
         object_header_id         -- 物件内部ID
        ,history_num              -- 変更履歴NO
        ,object_code              -- 物件コード
        ,lease_class              -- リース種別
        ,lease_type               -- リース区分
        ,re_lease_times           -- 再リース回数
        ,po_number                -- 発注番号
        ,registration_number      -- 登録番号
        ,age_type                 -- 年式
        ,model                    -- 機種
        ,serial_number            -- 機番
        ,quantity                 -- 数量
        ,manufacturer_name        -- メーカー名
        ,department_code          -- 管理部門コード
        ,owner_company            -- 本社／工場
        ,installation_address     -- 現設置場所
        ,installation_place       -- 現設置先
        ,chassis_number           -- 車台番号
        ,re_lease_flag            -- 再リース要フラグ
        ,cancellation_type        -- 解約区分
        ,cancellation_date        -- 中途解約日
        ,dissolution_date         -- 中途解約キャンセル日
        ,bond_acceptance_flag     -- 証書受領フラグ
        ,bond_acceptance_date     -- 証書受領日
        ,expiration_date          -- 満了日
        ,object_status            -- 物件ステータス
        ,active_flag              -- 物件有効フラグ
        ,info_sys_if_date         -- リース管理情報連携日
        ,generation_date          -- 発生日
        ,customer_code            -- 顧客コード
        ,accounting_date          -- 計上日
        ,accounting_if_flag       -- 会計ＩＦフラグ
        ,description              -- 摘要
        ,created_by               -- 作成者
        ,creation_date            -- 作成日
        ,last_updated_by          -- 最終更新者
        ,last_update_date         -- 最終更新日
        ,last_update_login        -- 最終更新ﾛｸﾞｲﾝ
        ,request_id               -- 要求ID
        ,program_application_id   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,program_id               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,program_update_date      -- ﾌﾟﾛｸﾞﾗﾑ更新日
        )
      SELECT xoh.object_header_id                                   object_header_id        -- 物件内部ID
            ,apps.xxcff_object_histories_s1.NEXTVAL                 history_num             -- 変更履歴NO
            ,xoh.object_code                                        object_code             -- 物件コード
            ,xoh.lease_class                                        lease_class             -- リース種別
            ,xoh.lease_type                                         lease_type              -- リース区分
            ,xoh.re_lease_times                                     re_lease_times          -- 再リース回数
            ,xoh.po_number                                          po_number               -- 発注番号
            ,xoh.registration_number                                registration_number     -- 登録番号
            ,xoh.age_type                                           age_type                -- 年式
            ,xoh.model                                              model                   -- 機種
            ,xoh.serial_number                                      serial_number           -- 機番
            ,xoh.quantity                                           quantity                -- 数量
            ,xoh.manufacturer_name                                  manufacturer_name       -- メーカー名
            ,xoh.department_code                                    department_code         -- 管理部門コード
            ,xoh.owner_company                                      owner_company           -- 本社／工場
            ,xoh.installation_address                               installation_address    -- 現設置場所
            ,xoh.installation_place                                 installation_place      -- 現設置先
            ,xoh.chassis_number                                     chassis_number          -- 車台番号
            ,xoh.re_lease_flag                                      re_lease_flag           -- 再リース要フラグ
            ,xoh.cancellation_type                                  cancellation_type       -- 解約区分
            ,xoh.cancellation_date                                  cancellation_date       -- 中途解約日
            ,xoh.dissolution_date                                   dissolution_date        -- 中途解約キャンセル日
            ,xoh.bond_acceptance_flag                               bond_acceptance_flag    -- 証書受領フラグ
            ,xoh.bond_acceptance_date                               bond_acceptance_date    -- 証書受領日
            ,xoh.expiration_date                                    expiration_date         -- 満了日
            ,xoh.object_status                                      object_status           -- 物件ステータス
            ,xoh.active_flag                                        active_flag             -- 物件有効フラグ
            ,xoh.info_sys_if_date                                   info_sys_if_date        -- リース管理情報連携日
            ,xoh.generation_date                                    generation_date         -- 発生日
            ,xoh.customer_code                                      customer_code           -- 顧客コード
            ,LAST_DAY(TO_DATE(gt_period_name, cv_format_yyyy_mm))   accounting_date         -- 計上日
            ,accounting_if_flag_2                                   accounting_if_flag      -- 会計ＩＦフラグ
            ,cv_description || TO_CHAR(SYSDATE, cv_format_yyyymmdd) description             -- 摘要
            ,cn_created_by                                          created_by              -- 作成者
            ,cd_creation_date                                       creation_date           -- 作成日
            ,cn_last_updated_by                                     last_updated_by         -- 最終更新者
            ,cd_last_update_date                                    last_update_date        -- 最終更新日
            ,cn_last_update_login                                   last_update_login       -- 最終更新ﾛｸﾞｲﾝ
            ,cn_request_id                                          request_id              -- 要求ID
            ,cn_program_application_id                              program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
            ,cn_program_id                                          program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
            ,cd_program_update_date                                 program_update_date     -- ﾌﾟﾛｸﾞﾗﾑ更新日
      FROM   xxcff_object_headers xoh
      WHERE  xoh.object_header_id = g_object_header_id_tab(in_loop_cnt)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- リース物件履歴が作成できない場合はエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00102
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50023
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
  END insert_object_histories;
--
  /**********************************************************************************
   * Procedure Name   : update_object
   * Description      : リース物件の更新(A-5)
   ***********************************************************************************/
  PROCEDURE update_object(
    in_loop_cnt              IN  NUMBER,        --   ループカウンタ
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_object'; -- プログラム名
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
    cv_object_status_103    CONSTANT VARCHAR2(3)   := '103';                 -- 再リース待ち
    cv_lease_type_2         CONSTANT VARCHAR2(1)   := '2';                   -- 再リース
    cv_re_lease_flag_0      CONSTANT VARCHAR2(1)   := '0';                   -- 再リース要
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
    -- ***      リース物件の更新           ***
    -- ***************************************
--
    -- =====================================
    -- リース物件の更新
    -- =====================================
    BEGIN
      UPDATE xxcff_object_headers xoh   -- リース物件
      SET    xoh.object_status          = cv_object_status_103                   -- 物件ステータス
            ,xoh.lease_type             = cv_lease_type_2                        -- リース区分 2：再リース
            ,xoh.re_lease_flag          = cv_re_lease_flag_0                     -- 再リースフラグ 0:要
            ,xoh.re_lease_times         = g_re_lease_times_tab(in_loop_cnt) + 1  -- 再リース回数
            ,xoh.expiration_date        = NULL                                   -- 満了日
            ,xoh.cancellation_type      = NULL                                   -- 解約区分
            ,xoh.cancellation_date      = NULL                                   -- 中途解約日
            ,xoh.last_updated_by        = cn_last_updated_by                     -- 最終更新者
            ,xoh.last_update_date       = cd_last_update_date                    -- 最終更新日
            ,xoh.last_update_login      = cn_last_update_login                   -- 最終更新ログイン
            ,xoh.request_id             = cn_request_id                          -- 要求ID
            ,xoh.program_application_id = cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
            ,xoh.program_id             = cn_program_id                          -- コンカレント・プログラムID
            ,xoh.program_update_date    = cd_program_update_date                 -- プログラム更新日
      WHERE  xoh.object_header_id = g_object_header_id_tab(in_loop_cnt)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- リース物件情報が更新できない場合はエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50014
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
  END update_object;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_lines
   * Description      : リース契約明細のチェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_contract_lines(
    in_loop_cnt              IN  NUMBER,        --   ループカウンタ
    ov_errbuf                OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_lines'; -- プログラム名
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
    cv_contract_status_201    CONSTANT VARCHAR2(3)   := '201';       -- 登録済
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_contract_header_id          xxcff_contract_lines.contract_header_id%TYPE;       -- 契約内部ID
    lt_contract_line_id            xxcff_contract_lines.contract_line_id%TYPE;         -- 契約明細内部ID
    lt_contract_status             xxcff_contract_lines.contract_status%TYPE;          -- 契約ステータス
    lt_contract_status_name        xxcff_contract_status_v.contract_status_name%TYPE;  -- 契約ステータス名
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
    -- ***   リース契約明細のチェック処理  ***
    -- ***************************************
--
    -- =====================================
    -- リース契約明細の取得
    -- =====================================
    BEGIN
      SELECT xcl.contract_header_id AS contract_header_id    -- 契約内部ID
            ,xcl.contract_line_id   AS contract_header_id    -- 契約明細内部ID
            ,xcl.contract_status    AS contract_status       -- 契約ステータス
            ,( SELECT xcs.contract_status_name
               FROM   xxcff_contract_status_v xcs   -- 契約ステータスビュー
               WHERE  xcs.contract_status_code = xcl.contract_status
             )                      AS contract_status_name  -- 契約ステータス名
      INTO   lt_contract_header_id
            ,lt_contract_line_id
            ,lt_contract_status
            ,lt_contract_status_name
      FROM   xxcff_contract_lines xcl                -- リース契約明細
      WHERE  EXISTS (
                     SELECT 1
                     FROM   xxcff_contract_headers xch      -- リース契約明細
                     WHERE  xch.contract_header_id = xcl.contract_header_id
                     AND    xcl.object_header_id   = g_object_header_id_tab(in_loop_cnt)      -- 物件内部ID
                     AND    xch.re_lease_times     = g_re_lease_times_tab(in_loop_cnt)        -- 再リース回数
                    )
      FOR UPDATE NOWAIT
      ;
--
      -- 契約ステータスが201の場合は警告
      IF ( lt_contract_status = cv_contract_status_201 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00240
                        ,iv_token_name1  => cv_tkn_object_code
                        ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
        ov_retcode := cv_status_warn;
      END IF;
--
      -- 取得した契約内部ID、契約明細内部ID、契約ステータスをセット
      g_contract_header_id_tab(in_loop_cnt)   := lt_contract_header_id;
      g_contract_line_id_tab(in_loop_cnt)     := lt_contract_line_id;
      g_contract_status_tab(in_loop_cnt)      := lt_contract_status;
      g_contract_status_name_tab(in_loop_cnt) := lt_contract_status_name;
--
    EXCEPTION
      WHEN lock_expt THEN
        -- リース契約明細テーブルがロックできない場合はエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00007
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50030
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        -- リース契約明細情報が取得できない場合は警告
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00165
                        ,iv_token_name1  => cv_tkn_get
                        ,iv_token_value1 => cv_msg_cff_50220
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
        ov_retcode := cv_status_warn;
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
  END get_contract_lines;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : 物件コードチェック処理(A-3)
   ***********************************************************************************/
  PROCEDURE chk_param(
    in_loop_cnt              IN  NUMBER,        --   ループカウンタ
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
    cv_object_status_102    CONSTANT VARCHAR2(3)   := '102';                 -- 契約済
    cv_object_status_104    CONSTANT VARCHAR2(3)   := '104';                 -- 再リース契約済
    cv_object_status_107    CONSTANT VARCHAR2(3)   := '107';                 -- 満了
    cv_object_status_110    CONSTANT VARCHAR2(3)   := '110';                 -- 中途解約（自己都合）
    cv_object_status_111    CONSTANT VARCHAR2(3)   := '111';                 -- 中途解約（保険対応）
    cv_object_status_112    CONSTANT VARCHAR2(3)   := '112';                 -- 中途解約（満了）
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_object_header_id     xxcff_object_headers.object_header_id%TYPE;      -- 物件内部ID
    lt_object_status        xxcff_object_headers.object_status%TYPE;         -- 物件ステータス
    lt_object_status_name   xxcff_object_status_v.object_status_name%TYPE;   -- 物件ステータス
    lt_re_lease_times       xxcff_object_headers.re_lease_times%TYPE;        -- 再リース回数
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
    -- データの存在チェック
    -- =====================================
    -- 1.リース物件情報の取得
    BEGIN
      SELECT xoh.object_header_id AS object_header_id    -- 物件内部ID
            ,xoh.object_status    AS object_status       -- 物件ステータス
            ,( SELECT xos.object_status_name
               FROM   xxcff_object_status_v xos     -- 物件ステータスビュー
               WHERE  xos.object_status_code = xoh.object_status
             )                    AS object_status_name  -- 物件ステータス名
            ,xoh.re_lease_times   AS re_lease_times      -- 再リース回数
      INTO   lt_object_header_id
            ,lt_object_status
            ,lt_object_status_name
            ,lt_re_lease_times
      FROM   xxcff_object_headers xoh                -- リース物件
      WHERE  xoh.object_code = g_file_upload_if_data_tab(in_loop_cnt)
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN lock_expt THEN
        -- リース物件テーブルがロックできない場合はエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00007
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50014
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN NO_DATA_FOUND THEN
        -- リース物件情報が取得できない場合は警告
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00123
                        ,iv_token_name1  => cv_tkn_column
                        ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
        ov_retcode := cv_status_warn;
    END;
--
    -- リース物件情報が取得できた場合
    IF ( ov_retcode = cv_status_normal ) THEN
      -- 2.物件ステータスのチェック
      -- 2-1.物件ステータスが「102：契約済」「104：再リース契約済」「107：満了」「110：中途解約(自己都合)」
      -- 「111：中途解約(保険対応)」「112：中途解約(満了)」のいずれかの場合
      IF ( lt_object_status IN ( cv_object_status_102         -- 契約済
                                ,cv_object_status_104         -- 再リース契約済
                                ,cv_object_status_107         -- 満了
                                ,cv_object_status_110         -- 中途解約（自己都合）
                                ,cv_object_status_111         -- 中途解約（保険対応）
                                ,cv_object_status_112) ) THEN -- 中途解約（満了）
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00237
                        ,iv_token_name1  => cv_tkn_object_code
                        ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                        ,iv_token_name2  => cv_tkn_object_status
                        ,iv_token_value2 => lt_object_status_name
                        ,iv_token_name3  => cv_tkn_re_lease_times
                        ,iv_token_value3 => lt_re_lease_times
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
--
        -- 取得した物件内部IDと再リース回数をセット
        g_object_header_id_tab(in_loop_cnt) := lt_object_header_id;
        g_re_lease_times_tab(in_loop_cnt)   := lt_re_lease_times;
--
      -- 2-2.物件ステータスが2-1以外の場合
      ELSE
        -- 警告
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00238
                        ,iv_token_name1  => cv_tkn_object_code
                        ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                        ,iv_token_name2  => cv_tkn_object_status
                        ,iv_token_value2 => lt_object_status_name
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
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
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードIFデータ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- プログラム名
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
    --ファイルアップロードIFデータを取得
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id                 -- ファイルID
     ,ov_file_data => g_file_upload_if_data_tab  -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                 -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_name                       -- XXCFF
                                                    ,cv_msg_xxcff00094                    -- 共通関数エラー
                                                    ,cv_tkn_func_name                     -- トークン'FUNC_NAME'
                                                    ,cv_msg_cff_50131 )                   -- BLOBデータ変換用関数
                                                    || cv_msg_part
                                                    || lv_errmsg                          --共通関数内ｴﾗｰﾒｯｾｰｼﾞ
                                                    ,1
                                                    ,5000)
      ;
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       --   1.ファイルID
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
    -- リース種類
    cv_les_kind_fin        CONSTANT VARCHAR2(1)   := '0';                 -- Finリース
--
    -- *** ローカル変数 ***
    lv_file_name    xxccp_mrp_file_ul_interface.file_name%TYPE; -- 取得ファイル名
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
--
      --アップロードCSVファイル名取得
      SELECT xfu.file_name    AS file_name
      INTO   lv_file_name
      FROM   xxccp_mrp_file_ul_interface  xfu
      WHERE  xfu.file_id = in_file_id
      ;
--
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG      --ログ(システム管理者用メッセージ)出力
       ,buff   => xxccp_common_pkg.get_msg(cv_app_name,   cv_msg_xxcff00167
                                          ,cv_tkn_file_name, cv_msg_cff_50284
                                          ,cv_tkn_csv_name,  lv_file_name)
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => xxccp_common_pkg.get_msg(cv_app_name, cv_msg_xxcff00167
                                          ,cv_tkn_file_name, cv_msg_cff_50284
                                          ,cv_tkn_csv_name,  lv_file_name)
      );
--
    -- コンカレントパラメータ値出力(出力の表示)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(ログ)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- リース台帳最終クローズ期間取得
    -- ============================================
    BEGIN
      SELECT  MAX(fdp.period_name)     AS  period_name        -- 期間名称
      INTO    gt_period_name                                  -- リース台帳オープン期間
      FROM    fa_deprn_periods      fdp                       -- 減価償却期間
             ,xxcff_lease_kind_v    xlkv                      -- リース種類ビュー
      WHERE   fdp.book_type_code    = xlkv.book_type_code     -- 資産台帳コード
      AND     xlkv.lease_kind_code  = cv_les_kind_fin         -- リース種類コード（Finリース）
      AND     fdp.period_close_date IS NOT NULL               -- クローズされた会計期間
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_app_name         -- アプリケーション短縮名
                      ,iv_name          => cv_msg_xxcff00186   -- メッセージコード
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
    in_file_id                IN    NUMBER,          --   1.ファイルID
    iv_file_format            IN    VARCHAR2,        --   2.ファイルフォーマット
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
    cv_contract_status_204    CONSTANT VARCHAR2(3)   := '204';       -- 満了
    cv_contract_status_206    CONSTANT VARCHAR2(3)   := '206';       -- 中途解約(自己都合)
    cv_contract_status_207    CONSTANT VARCHAR2(3)   := '207';       -- 中途解約(保険対応)
    cv_contract_status_208    CONSTANT VARCHAR2(3)   := '208';       -- 中途解約(満了)
--
    -- *** ローカル変数 ***
    ln_loop_cnt               NUMBER;                                -- ループ時のカウント
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
    ln_loop_cnt                 := 0;
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
       in_file_id        -- 1.ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．ファイルアップロードIFデータ取得処理
    -- ============================================
--
    get_upload_data(
       in_file_id        -- 1.ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- メインループ1
    <<MAIN_LOOP_1>>
    FOR ln_loop_cnt IN g_file_upload_if_data_tab.FIRST .. g_file_upload_if_data_tab.LAST LOOP
--
      --１行目の場合カラム行の処理となる為、スキップして２行目の処理に遷移する
      IF ( ln_loop_cnt <> 1 ) THEN
--
        -- 対象件数の取得
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ============================================
        -- A-3．物件コードチェック処理
        -- ============================================
--
        chk_param(
           ln_loop_cnt               --   ループカウンタ
          ,lv_errbuf                 --   エラー・メッセージ           --# 固定 #
          ,lv_retcode                --   リターン・コード             --# 固定 #
          ,lv_errmsg                 --   ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
        ELSE
          -- ============================================
          -- A-4．リース契約明細のチェック処理
          -- ============================================
--
          get_contract_lines(
             ln_loop_cnt       -- ループカウンタ
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
          END IF;
        END IF;
      END IF;
    END LOOP MAIN_LOOP_1;
--
    -- 対象件数が0の場合、エラー
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00165
                     ,iv_token_name1  => cv_tkn_get
                     ,iv_token_value1 => cv_msg_cff_50175
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数が1件以上あり、スキップ件数が0の時
    IF (  gn_target_cnt > 0 
      AND gn_warn_cnt   = 0 ) THEN
      -- メインループ2
      <<MAIN_LOOP_2>>
      FOR ln_loop_cnt IN 2 .. g_object_header_id_tab.LAST LOOP
        -- ============================================
        -- A-5．リース物件の更新
        -- ============================================
--
        update_object(
           ln_loop_cnt       -- ループカウンタ
          ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
          ,lv_retcode        -- リターン・コード             --# 固定 #
          ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ============================================
        -- A-6．リース物件履歴の作成
        -- ============================================
--
        insert_object_histories(
           ln_loop_cnt       -- ループカウンタ
          ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
          ,lv_retcode        -- リターン・コード             --# 固定 #
          ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 契約明細のステータスチェック
        -- 1.ステータスが「204：満了」「206：中途解約(自己都合)」、「207：中途解約(保険対応)」「208：中途解約(満了)」の場合
        IF ( g_contract_status_tab(ln_loop_cnt) IN ( cv_contract_status_204          -- 満了
                                                    ,cv_contract_status_206          -- 中途解約(自己都合)
                                                    ,cv_contract_status_207          -- 中途解約(保険対応)
                                                    ,cv_contract_status_208 ) ) THEN -- 中途解約(満了)
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcff00239
                          ,iv_token_name1  => cv_tkn_object_code
                          ,iv_token_value1 => g_file_upload_if_data_tab(ln_loop_cnt)
                          ,iv_token_name2  => cv_tkn_contract_status
                          ,iv_token_value2 => g_contract_status_name_tab(ln_loop_cnt)
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
        -- 2.ステータスが1以外（「202：契約」「203：再リース」）の場合
        ELSE
          -- ============================================
          -- A-7．リース契約明細の更新
          -- ============================================
--
          update_contract_lines(
             ln_loop_cnt       -- ループカウンタ
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-8．リース契約明細履歴の作成
          -- ============================================
--
          insert_contract_histories(
             ln_loop_cnt       -- ループカウンタ
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-9．支払計画の更新
          -- ============================================
--
          update_pay_planning(
             ln_loop_cnt       -- ループカウンタ
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- 正常件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP MAIN_LOOP_2;
    END IF;
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
    in_file_id                IN    NUMBER,          --   1.ファイルID(必須)
    iv_file_format            IN    VARCHAR2         --   2.ファイルフォーマット(必須)
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
       in_file_id                 --   1.ファイルID
      ,iv_file_format             --   2.ファイルフォーマット
      ,lv_errbuf                  --   エラー・メッセージ           --# 固定 #
      ,lv_retcode                 --   リターン・コード             --# 固定 #
      ,lv_errmsg                  --   ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ============================================
    -- A-10．終了処理
    -- ============================================
    BEGIN
      -- ファイルアップロードI/Fテーブルを削除
      DELETE 
      FROM   xxccp_mrp_file_ul_interface  xmfui    --ファイルアップロードI/Fテーブル
      WHERE  xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_app_name               -- 'XXCFF'
                                                       ,cv_msg_xxcff00104         -- 削除エラー
                                                       ,cv_tkn_table              -- トークン'TABLE_NAME'
                                                       ,cv_msg_cff_50175          -- ファイルアップロードI/Fテーブル
                                                       ,cv_tkn_info               -- トークン'INFO'
                                                       ,SUBSTRB(SQLERRM,1,2000) ) -- メッセージ
                                                       ,1
                                                       ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        RAISE global_api_others_expt;
    END;
--
    -- スキップ対象の物件が存在した場合
    IF ( gn_warn_cnt > 0 ) THEN
      -- ステータスをエラーにする
      lv_retcode := cv_status_error;
    END IF;
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
END XXCFF016A37C;
/
