CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A07C(body)
 * Description      : 指定した営業員の指定した日の１時間ごとの訪問実績(訪問先)を表示します。
 *                    １週間前の訪問実績を同様に表示して比較の対象とします。
 * MD.050           : MD050_CSO_019_A07_営業員別訪問実績表
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_param              パラメータチェック(A-2)
 *  header_process         帳票ヘッダ処理(A-3)
 *  get_visit_time         時間別列処理(A-5)
 *  ins_upd_lines          配列の追加、更新(A-6)
 *  insert_row             ワークテーブルデータ登録(A-7)
 *  act_svf                SVF起動(A-8)
 *  delete_row             ワークテーブルデータ削除(A-9)
 *  submain                メイン処理プロシージャ
 *                           データ取得(A-4)
 *                           SVF起動APIエラーチェック(A-10)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-11)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-30    1.0   Kazuyo.Hosoi     新規作成
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF起動API埋め込み
 *  2009-03-05    1.1   Kazuyo.Hosoi     【障害対応031】発令日判断基準日修正
 *  2009-03-11    1.1   Kazuyo.Hosoi     【障害対応047】顧客区分、ステータス抽出条件変更
 *  2009-04-21    1.2   Daisuke.Abe      【T1_0681】業務処理日付対応
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897対応
 *  2009-05-20    1.4   Makoto.Ohtsuki   ＳＴ障害対応(T1_0696)
 *  2009-06-03    1.5   Kazuo.Satomura   ＳＴ障害対応(T1_0696 SQLERRMを削除)
 *  2009-11-25    1.6   Kazuo.Satomura   E_本稼動_00026対応
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A07C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  --
  cv_report_id           CONSTANT VARCHAR2(30)  := 'XXCSO019A07C';  -- 帳票ID
  -- 日付書式
  cv_format_date_ymd1    CONSTANT VARCHAR2(8)   := 'YYYYMMDD';      -- 日付フォーマット（年月日）
  cd_work_date           CONSTANT DATE          := xxcso_util_common_pkg.get_online_sysdate;  -- 現在日付
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00156';  -- パラメータ出力(訪問日)
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00131';  -- パラメータ出力(従業員コード)
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00133';  -- 必須項目未選択エラー
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00157';  -- 年月日の範囲間違いメッセージ
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00132';  -- 年月日の型違いエラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00134';  -- 権限外のオペレーションエラー
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00135';  -- 必須項目エラー
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00140';  -- 明細0件メッセージ
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00042';  -- ＤＢ登録・更新エラー
  -- トークンコード
  cv_tkn_entry           CONSTANT VARCHAR2(20) := 'ENTRY';
  cv_tkn_api_nm          CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_act             CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERRMSG';
  --
  cv_msg_prnthss_l       CONSTANT VARCHAR2(1)  := '(';
  cv_msg_prnthss_r       CONSTANT VARCHAR2(1)  := ')';
  --
  cn_user_id             CONSTANT NUMBER       := fnd_global.user_id;   -- ユーザーID
  cn_resp_id             CONSTANT NUMBER       := fnd_global.resp_id;   -- 職責ID
  cd_sysdate             CONSTANT DATE         := SYSDATE;              -- SYSDATE
  cv_rep_tp              CONSTANT VARCHAR2(1)  := '1';                  -- 帳票タイプ
  cv_true                CONSTANT VARCHAR2(4)  := 'TRUE';               -- 戻り値判断用
  cv_false               CONSTANT VARCHAR2(5)  := 'FALSE';              -- 戻り値判断用
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_total_count            NUMBER(10) DEFAULT 0;         -- 総軒数
  gn_total_count_1          NUMBER(10) DEFAULT 0;         -- 軒数計１
  gn_total_count_2          NUMBER(10) DEFAULT 0;         -- 軒数計２
  gn_total_count_3          NUMBER(10) DEFAULT 0;         -- 軒数計３
  gn_total_count_4          NUMBER(10) DEFAULT 0;         -- 軒数計４
  gn_total_count_5          NUMBER(10) DEFAULT 0;         -- 軒数計５
  gn_total_count_6          NUMBER(10) DEFAULT 0;         -- 軒数計６
  gn_total_count_7          NUMBER(10) DEFAULT 0;         -- 軒数計７
  gn_total_count_8          NUMBER(10) DEFAULT 0;         -- 軒数計８
  gn_total_count_9          NUMBER(10) DEFAULT 0;         -- 軒数計９
  gn_total_count_10         NUMBER(10) DEFAULT 0;         -- 軒数計１０
  gn_total_count_11         NUMBER(10) DEFAULT 0;         -- 軒数計１１
  gn_total_count_12         NUMBER(10) DEFAULT 0;         -- 軒数計１２
  gn_last_total_count       NUMBER(10) DEFAULT 0;         -- 総軒数(前週)
  gn_last_total_count_1     NUMBER(10) DEFAULT 0;         -- 軒数計１(前週)
  gn_last_total_count_2     NUMBER(10) DEFAULT 0;         -- 軒数計２(前週)
  gn_last_total_count_3     NUMBER(10) DEFAULT 0;         -- 軒数計３(前週)
  gn_last_total_count_4     NUMBER(10) DEFAULT 0;         -- 軒数計４(前週)
  gn_last_total_count_5     NUMBER(10) DEFAULT 0;         -- 軒数計５(前週)
  gn_last_total_count_6     NUMBER(10) DEFAULT 0;         -- 軒数計６(前週)
  gn_last_total_count_7     NUMBER(10) DEFAULT 0;         -- 軒数計７(前週)
  gn_last_total_count_8     NUMBER(10) DEFAULT 0;         -- 軒数計８(前週)
  gn_last_total_count_9     NUMBER(10) DEFAULT 0;         -- 軒数計９(前週)
  gn_last_total_count_10    NUMBER(10) DEFAULT 0;         -- 軒数計１０(前週)
  gn_last_total_count_11    NUMBER(10) DEFAULT 0;         -- 軒数計１１(前週)
  gn_last_total_count_12    NUMBER(10) DEFAULT 0;         -- 軒数計１２(前週)
--
  gn_cnt                    NUMBER DEFAULT 0;             -- 配列用カウンタ
  /* 2009.11.25 K.Satomura E_本稼動_00026対応 START */
  gn_resource_id NUMBER; -- リソースＩＤ
  /* 2009.11.25 K.Satomura E_本稼動_00026対応 END */
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 営業員別時間別訪問実績 レコード型定義
  TYPE g_vst_rslts_rtype IS RECORD(
     actual_end_date        xxcso_visit_sales_results_v.actual_end_date%TYPE     -- 実績終了日
    ,pure_amount_sum        xxcso_visit_sales_results_v.pure_amount_sum%TYPE     -- 本体金額合計
    ,account_number         xxcso_cust_accounts_v.account_number%TYPE            -- 顧客コード
    ,party_name             xxcso_cust_accounts_v.party_name%TYPE                -- 顧客名称
  );
  -- 営業員別訪問実績表帳票ワークテーブル レコード型定義
  TYPE g_rep_vst_slsemp_rtype IS RECORD(
    line_num                xxcso_rep_visit_salesemp.line_num%TYPE               -- 行番号
    ,report_id              xxcso_rep_visit_salesemp.report_id%TYPE              -- 帳票ＩＤ
    ,report_name            xxcso_rep_visit_salesemp.report_name%TYPE            -- 帳票タイトル
    ,output_date            xxcso_rep_visit_salesemp.output_date%TYPE            -- 出力日時
    ,visit_date             xxcso_rep_visit_salesemp.visit_date%TYPE             -- 訪問年月日
    ,base_code              xxcso_rep_visit_salesemp.base_code%TYPE              -- 拠点コード
    ,hub_name               xxcso_rep_visit_salesemp.hub_name%TYPE               -- 拠点名称
    ,employee_number        xxcso_rep_visit_salesemp.employee_number%TYPE        -- 営業員コード
    ,employee_name          xxcso_rep_visit_salesemp.employee_name%TYPE          -- 営業員名
    ,total_count            xxcso_rep_visit_salesemp.total_count%TYPE            -- 総軒数
    ,total_count_1          xxcso_rep_visit_salesemp.total_count_1%TYPE          -- 軒数計１
    ,total_count_2          xxcso_rep_visit_salesemp.total_count_2%TYPE          -- 軒数計２
    ,total_count_3          xxcso_rep_visit_salesemp.total_count_3%TYPE          -- 軒数計３
    ,total_count_4          xxcso_rep_visit_salesemp.total_count_4%TYPE          -- 軒数計４
    ,total_count_5          xxcso_rep_visit_salesemp.total_count_5%TYPE          -- 軒数計５
    ,total_count_6          xxcso_rep_visit_salesemp.total_count_6%TYPE          -- 軒数計６
    ,total_count_7          xxcso_rep_visit_salesemp.total_count_7%TYPE          -- 軒数計７
    ,total_count_8          xxcso_rep_visit_salesemp.total_count_8%TYPE          -- 軒数計８
    ,total_count_9          xxcso_rep_visit_salesemp.total_count_9%TYPE          -- 軒数計９
    ,total_count_10         xxcso_rep_visit_salesemp.total_count_10%TYPE         -- 軒数計１０
    ,total_count_11         xxcso_rep_visit_salesemp.total_count_11%TYPE         -- 軒数計１１
    ,total_count_12         xxcso_rep_visit_salesemp.total_count_12%TYPE         -- 軒数計１２
    ,visit_time_1           xxcso_rep_visit_salesemp.visit_time_1%TYPE           -- 訪問時刻１
    ,sales_amt_1            xxcso_rep_visit_salesemp.sales_amt_1%TYPE            -- 売上金額１
    ,account_number_1       xxcso_rep_visit_salesemp.account_number_1%TYPE       -- 顧客コード１
    ,customer_name_1        xxcso_rep_visit_salesemp.customer_name_1%TYPE        -- 顧客名称１
    ,visit_time_2           xxcso_rep_visit_salesemp.visit_time_2%TYPE           -- 訪問時刻２
    ,sales_amt_2            xxcso_rep_visit_salesemp.sales_amt_2%TYPE            -- 売上金額２
    ,account_number_2       xxcso_rep_visit_salesemp.account_number_2%TYPE       -- 顧客コード２
    ,customer_name_2        xxcso_rep_visit_salesemp.customer_name_2%TYPE        -- 顧客名称２
    ,visit_time_3           xxcso_rep_visit_salesemp.visit_time_3%TYPE           -- 訪問時刻３
    ,sales_amt_3            xxcso_rep_visit_salesemp.sales_amt_3%TYPE            -- 売上金額３
    ,account_number_3       xxcso_rep_visit_salesemp.account_number_3%TYPE       -- 顧客コード３
    ,customer_name_3        xxcso_rep_visit_salesemp.customer_name_3%TYPE        -- 顧客名称３
    ,visit_time_4           xxcso_rep_visit_salesemp.visit_time_4%TYPE           -- 訪問時刻４
    ,sales_amt_4            xxcso_rep_visit_salesemp.sales_amt_4%TYPE            -- 売上金額４
    ,account_number_4       xxcso_rep_visit_salesemp.account_number_4%TYPE       -- 顧客コード４
    ,customer_name_4        xxcso_rep_visit_salesemp.customer_name_4%TYPE        -- 顧客名称４
    ,visit_time_5           xxcso_rep_visit_salesemp.visit_time_5%TYPE           -- 訪問時刻５
    ,sales_amt_5            xxcso_rep_visit_salesemp.sales_amt_5%TYPE            -- 売上金額５
    ,account_number_5       xxcso_rep_visit_salesemp.account_number_5%TYPE       -- 顧客コード５
    ,customer_name_5        xxcso_rep_visit_salesemp.customer_name_5%TYPE        -- 顧客名称５
    ,visit_time_6           xxcso_rep_visit_salesemp.visit_time_6%TYPE           -- 訪問時刻６
    ,sales_amt_6            xxcso_rep_visit_salesemp.sales_amt_6%TYPE            -- 売上金額６
    ,account_number_6       xxcso_rep_visit_salesemp.account_number_6%TYPE       -- 顧客コード６
    ,customer_name_6        xxcso_rep_visit_salesemp.customer_name_6%TYPE        -- 顧客名称６
    ,visit_time_7           xxcso_rep_visit_salesemp.visit_time_7%TYPE           -- 訪問時刻７
    ,sales_amt_7            xxcso_rep_visit_salesemp.sales_amt_7%TYPE            -- 売上金額７
    ,account_number_7       xxcso_rep_visit_salesemp.account_number_7%TYPE       -- 顧客コード７
    ,customer_name_7        xxcso_rep_visit_salesemp.customer_name_7%TYPE        -- 顧客名称７
    ,visit_time_8           xxcso_rep_visit_salesemp.visit_time_8%TYPE           -- 訪問時刻８
    ,sales_amt_8            xxcso_rep_visit_salesemp.sales_amt_8%TYPE            -- 売上金額８
    ,account_number_8       xxcso_rep_visit_salesemp.account_number_8%TYPE       -- 顧客コード８
    ,customer_name_8        xxcso_rep_visit_salesemp.customer_name_8%TYPE        -- 顧客名称８
    ,visit_time_9           xxcso_rep_visit_salesemp.visit_time_9%TYPE           -- 訪問時刻９
    ,sales_amt_9            xxcso_rep_visit_salesemp.sales_amt_9%TYPE            -- 売上金額９
    ,account_number_9       xxcso_rep_visit_salesemp.account_number_9%TYPE       -- 顧客コード９
    ,customer_name_9        xxcso_rep_visit_salesemp.customer_name_9%TYPE        -- 顧客名称９
    ,visit_time_10          xxcso_rep_visit_salesemp.visit_time_10%TYPE          -- 訪問時刻１０
    ,sales_amt_10           xxcso_rep_visit_salesemp.sales_amt_10%TYPE           -- 売上金額１０
    ,account_number_10      xxcso_rep_visit_salesemp.account_number_10%TYPE      -- 顧客コード１０
    ,customer_name_10       xxcso_rep_visit_salesemp.customer_name_10%TYPE       -- 顧客名称１０
    ,visit_time_11          xxcso_rep_visit_salesemp.visit_time_11%TYPE          -- 訪問時刻１１
    ,sales_amt_11           xxcso_rep_visit_salesemp.sales_amt_11%TYPE           -- 売上金額１１
    ,account_number_11      xxcso_rep_visit_salesemp.account_number_11%TYPE      -- 顧客コード１１
    ,customer_name_11       xxcso_rep_visit_salesemp.customer_name_11%TYPE       -- 顧客名称１１
    ,visit_time_12          xxcso_rep_visit_salesemp.visit_time_12%TYPE          -- 訪問時刻１２
    ,sales_amt_12           xxcso_rep_visit_salesemp.sales_amt_12%TYPE           -- 売上金額１２
    ,account_number_12      xxcso_rep_visit_salesemp.account_number_12%TYPE      -- 顧客コード１２
    ,customer_name_12       xxcso_rep_visit_salesemp.customer_name_12%TYPE       -- 顧客名称１２
    ,last_total_count       xxcso_rep_visit_salesemp.last_total_count%TYPE       -- 前週総軒数
    ,last_total_count_1     xxcso_rep_visit_salesemp.last_total_count_1%TYPE     -- 前週軒数計１
    ,last_total_count_2     xxcso_rep_visit_salesemp.last_total_count_2%TYPE     -- 前週軒数計２
    ,last_total_count_3     xxcso_rep_visit_salesemp.last_total_count_3%TYPE     -- 前週軒数計３
    ,last_total_count_4     xxcso_rep_visit_salesemp.last_total_count_4%TYPE     -- 前週軒数計４
    ,last_total_count_5     xxcso_rep_visit_salesemp.last_total_count_5%TYPE     -- 前週軒数計５
    ,last_total_count_6     xxcso_rep_visit_salesemp.last_total_count_6%TYPE     -- 前週軒数計６
    ,last_total_count_7     xxcso_rep_visit_salesemp.last_total_count_7%TYPE     -- 前週軒数計７
    ,last_total_count_8     xxcso_rep_visit_salesemp.last_total_count_8%TYPE     -- 前週軒数計８
    ,last_total_count_9     xxcso_rep_visit_salesemp.last_total_count_9%TYPE     -- 前週軒数計９
    ,last_total_count_10    xxcso_rep_visit_salesemp.last_total_count_10%TYPE    -- 前週軒数計１０
    ,last_total_count_11    xxcso_rep_visit_salesemp.last_total_count_11%TYPE    -- 前週軒数計１１
    ,last_total_count_12    xxcso_rep_visit_salesemp.last_total_count_12%TYPE    -- 前週軒数計１２
    ,last_visit_time_1      xxcso_rep_visit_salesemp.last_visit_time_1%TYPE      -- 前週訪問時刻１
    ,last_sales_amt_1       xxcso_rep_visit_salesemp.last_sales_amt_1%TYPE       -- 前週売上金額１
    ,last_account_number_1  xxcso_rep_visit_salesemp.last_account_number_1%TYPE  -- 前週顧客コード１
    ,last_customer_name_1   xxcso_rep_visit_salesemp.last_customer_name_1%TYPE   -- 前週顧客名称１
    ,last_visit_time_2      xxcso_rep_visit_salesemp.last_visit_time_2%TYPE      -- 前週訪問時刻２
    ,last_sales_amt_2       xxcso_rep_visit_salesemp.last_sales_amt_2%TYPE       -- 前週売上金額２
    ,last_account_number_2  xxcso_rep_visit_salesemp.last_account_number_2%TYPE  -- 前週顧客コード２
    ,last_customer_name_2   xxcso_rep_visit_salesemp.last_customer_name_2%TYPE   -- 前週顧客名称２
    ,last_visit_time_3      xxcso_rep_visit_salesemp.last_visit_time_3%TYPE      -- 前週訪問時刻３
    ,last_sales_amt_3       xxcso_rep_visit_salesemp.last_sales_amt_3%TYPE       -- 前週売上金額３
    ,last_account_number_3  xxcso_rep_visit_salesemp.last_account_number_3%TYPE  -- 前週顧客コード３
    ,last_customer_name_3   xxcso_rep_visit_salesemp.last_customer_name_3%TYPE   -- 前週顧客名称３
    ,last_visit_time_4      xxcso_rep_visit_salesemp.last_visit_time_4%TYPE      -- 前週訪問時刻４
    ,last_sales_amt_4       xxcso_rep_visit_salesemp.last_sales_amt_4%TYPE       -- 前週売上金額４
    ,last_account_number_4  xxcso_rep_visit_salesemp.last_account_number_4%TYPE  -- 前週顧客コード４
    ,last_customer_name_4   xxcso_rep_visit_salesemp.last_customer_name_4%TYPE   -- 前週顧客名称４
    ,last_visit_time_5      xxcso_rep_visit_salesemp.last_visit_time_5%TYPE      -- 前週訪問時刻５
    ,last_sales_amt_5       xxcso_rep_visit_salesemp.last_sales_amt_5%TYPE       -- 前週売上金額５
    ,last_account_number_5  xxcso_rep_visit_salesemp.last_account_number_5%TYPE  -- 前週顧客コード５
    ,last_customer_name_5   xxcso_rep_visit_salesemp.last_customer_name_5%TYPE   -- 前週顧客名称５
    ,last_visit_time_6      xxcso_rep_visit_salesemp.last_visit_time_6%TYPE      -- 前週訪問時刻６
    ,last_sales_amt_6       xxcso_rep_visit_salesemp.last_sales_amt_6%TYPE       -- 前週売上金額６
    ,last_account_number_6  xxcso_rep_visit_salesemp.last_account_number_6%TYPE  -- 前週顧客コード６
    ,last_customer_name_6   xxcso_rep_visit_salesemp.last_customer_name_6%TYPE   -- 前週顧客名称６
    ,last_visit_time_7      xxcso_rep_visit_salesemp.last_visit_time_7%TYPE      -- 前週訪問時刻７
    ,last_sales_amt_7       xxcso_rep_visit_salesemp.last_sales_amt_7%TYPE       -- 前週売上金額７
    ,last_account_number_7  xxcso_rep_visit_salesemp.last_account_number_7%TYPE  -- 前週顧客コード７
    ,last_customer_name_7   xxcso_rep_visit_salesemp.last_customer_name_7%TYPE   -- 前週顧客名称７
    ,last_visit_time_8      xxcso_rep_visit_salesemp.last_visit_time_8%TYPE      -- 前週訪問時刻８
    ,last_sales_amt_8       xxcso_rep_visit_salesemp.last_sales_amt_8%TYPE       -- 前週売上金額８
    ,last_account_number_8  xxcso_rep_visit_salesemp.last_account_number_8%TYPE  -- 前週顧客コード８
    ,last_customer_name_8   xxcso_rep_visit_salesemp.last_customer_name_8%TYPE   -- 前週顧客名称８
    ,last_visit_time_9      xxcso_rep_visit_salesemp.last_visit_time_9%TYPE      -- 前週訪問時刻９
    ,last_sales_amt_9       xxcso_rep_visit_salesemp.last_sales_amt_9%TYPE       -- 前週売上金額９
    ,last_account_number_9  xxcso_rep_visit_salesemp.last_account_number_9%TYPE  -- 前週顧客コード９
    ,last_customer_name_9   xxcso_rep_visit_salesemp.last_customer_name_9%TYPE   -- 前週顧客名称９
    ,last_visit_time_10     xxcso_rep_visit_salesemp.last_visit_time_10%TYPE     -- 前週訪問時刻１０
    ,last_sales_amt_10      xxcso_rep_visit_salesemp.last_sales_amt_10%TYPE      -- 前週売上金額１０
    ,last_account_number_10 xxcso_rep_visit_salesemp.last_account_number_10%TYPE -- 前週顧客コード１０
    ,last_customer_name_10  xxcso_rep_visit_salesemp.last_customer_name_10%TYPE  -- 前週顧客名称１０
    ,last_visit_time_11     xxcso_rep_visit_salesemp.last_visit_time_11%TYPE     -- 前週訪問時刻１１
    ,last_sales_amt_11      xxcso_rep_visit_salesemp.last_sales_amt_11%TYPE      -- 前週売上金額１１
    ,last_account_number_11 xxcso_rep_visit_salesemp.last_account_number_11%TYPE -- 前週顧客コード１１
    ,last_customer_name_11  xxcso_rep_visit_salesemp.last_customer_name_11%TYPE  -- 前週顧客名称１１
    ,last_visit_time_12     xxcso_rep_visit_salesemp.last_visit_time_12%TYPE     -- 前週訪問時刻１２
    ,last_sales_amt_12      xxcso_rep_visit_salesemp.last_sales_amt_12%TYPE      -- 前週売上金額１２
    ,last_account_number_12 xxcso_rep_visit_salesemp.last_account_number_12%TYPE -- 前週顧客コード１２
    ,last_customer_name_12  xxcso_rep_visit_salesemp.last_customer_name_12%TYPE  -- 前週顧客名称１２
    ,created_by             xxcso_rep_visit_salesemp.created_by%TYPE             -- 作成者
    ,creation_date          xxcso_rep_visit_salesemp.creation_date%TYPE          -- 作成日
    ,last_updated_by        xxcso_rep_visit_salesemp.last_updated_by%TYPE        -- 最終更新者
    ,last_update_date       xxcso_rep_visit_salesemp.last_update_date%TYPE       -- 最終更新日
    ,last_update_login      xxcso_rep_visit_salesemp.last_update_login%TYPE      -- 最終更新ログイン
    ,request_id             xxcso_rep_visit_salesemp.request_id%TYPE             -- 要求ID
    ,program_application_id xxcso_rep_visit_salesemp.program_application_id%TYPE -- コンカレント・プログラム・アプリケーションID
    ,program_id             xxcso_rep_visit_salesemp.program_id%TYPE             -- コンカレント・プログラムID
    ,program_update_date    xxcso_rep_visit_salesemp.program_update_date%TYPE    -- プログラム更新日
  );
  -- 営業員別訪問実績表帳票ワークテーブル テーブル型定義
  TYPE g_rep_vst_slsemp_ttype IS TABLE OF g_rep_vst_slsemp_rtype INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_rep_vst_slsemp_tab      g_rep_vst_slsemp_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_visit_date       IN  VARCHAR2         -- 訪問日
    ,iv_employee_number  IN  VARCHAR2         -- 従業員コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- *** ローカル変数 ***
    -- メッセージ出力用
    lv_msg_vst_dt       VARCHAR2(5000);
    lv_msg_emp_num      VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 入力パラメータメッセージ出力
    -- ===========================
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    -- メッセージ取得(訪問日)
    lv_msg_vst_dt := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                  --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_01                             --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry                                 --トークンコード1
                       ,iv_token_value1 => iv_visit_date                                --トークン値1
                     );
    -- メッセージ取得(従業員コード)
    lv_msg_emp_num := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name         --アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_02    --メッセージコード
                        ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                        ,iv_token_value1 => iv_employee_number  --トークン値1
                      );
--
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_vst_dt
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_emp_num
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
     iv_visit_date         IN  VARCHAR2                                  -- 訪問日
    ,iv_employee_number    IN  VARCHAR2                                  -- 従業員コード
    ,od_visit_date         OUT DATE                                      -- 訪問日(DATE型)
    ,ov_full_name          OUT NOCOPY VARCHAR2                           -- 漢字氏名
    ,ov_work_base_code     OUT NOCOPY VARCHAR2                           -- 勤務地拠点コード
    ,ov_hub_name           OUT NOCOPY VARCHAR2                           -- 勤務地拠点名
    ,ov_errbuf             OUT NOCOPY VARCHAR2                           -- エラー・メッセージ            --# 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2                           -- リターン・コード              --# 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2                           -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_param';  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_vst_dt          CONSTANT VARCHAR2(20) := '訪問日';
    cv_emp_nm          CONSTANT VARCHAR2(20) := '従業員コード';
    -- *** ローカル変数 ***
    ld_process_date       DATE;                                     -- 業務処理日付格納用
    ld_sysdate            DATE;                                     -- システム日付
    lv_visit_date         VARCHAR2(8);                              -- 訪問日格納用
    lt_employee_number    xxcso_resources_v2.employee_number%TYPE;  -- 従業員コード
    lt_last_name          xxcso_resources_v2.last_name%TYPE;        -- 漢字姓
    lt_first_name         xxcso_resources_v2.first_name%TYPE;       -- 漢字名
    lv_work_base_code     VARCHAR2(150);                            -- 勤務地拠点コード
    lv_work_base_name     VARCHAR2(4000);                           -- 勤務地拠点名
    lv_retcd              VARCHAR2(5);                              -- 共通関数戻り値格納
    -- *** ローカル例外 ***
    chk_param_expt     EXCEPTION;  -- 見積ヘッダーＩＤ未入力エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- パラメータ必須チェック
    -- ===========================
    -- パラメータ訪問日が未入力
    IF (iv_visit_date IS NULL) THEN
      -- エラーメッセージ取得(訪問日)
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name         --アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_03    --メッセージコード
                     ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                     ,iv_token_value1 => cv_vst_dt           --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- パラメータ従業員コードが未入力
    IF (iv_employee_number IS NULL) THEN
      -- エラーメッセージ取得(従業員コード)
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name         --アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_03    --メッセージコード
                     ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                     ,iv_token_value1 => cv_emp_nm           --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- ===========================
    -- パラメータ（訪問日）チェック
    -- ===========================
    /* 20090421_abe_T1_0681 START*/
    --ld_sysdate      := TRUNC(SYSDATE);                      -- システム日付格納
    -- 業務処理日付取得
    ld_sysdate := TRUNC(xxccp_common_pkg2.get_process_date);
    /* 20090421_abe_T1_0681 END*/
--
    BEGIN
      SELECT iv_visit_date   visit_date  -- INパラメータ訪問日
      INTO   lv_visit_date
      FROM   dual
      WHERE  TO_DATE(iv_visit_date, cv_format_date_ymd1) <= ld_sysdate
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04    --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                       ,iv_token_value1 => cv_vst_dt           --トークン値1
                     );
        /* 2009.06.03 K.Satomura T1_0696対応 START */
        --lv_errbuf := lv_errmsg || SQLERRM;
        lv_errbuf := lv_errmsg;
        /* 2009.06.03 K.Satomura T1_0696対応 END */
        RAISE chk_param_expt;
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05    --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                       ,iv_token_value1 => cv_vst_dt           --トークン値1
                     );
        /* 2009.06.03 K.Satomura T1_0696対応 START */
        --lv_errbuf := lv_errmsg || SQLERRM;
        lv_errbuf := lv_errmsg;
        /* 2009.06.03 K.Satomura T1_0696対応 END */
        RAISE chk_param_expt;
    END;
    -- ===========================
    -- 従業員コードチェック
    -- ===========================
    lv_retcd   := xxcso_util_common_pkg.chk_responsibility(
                    in_user_id     => cn_user_id       -- ログインユーザＩＤ
                   ,in_resp_id     => cn_resp_id       -- 職位ＩＤ
                   ,iv_report_type => cv_rep_tp        -- 帳票タイプ（1:営業員別、2:営業員グループ別、その他は指定不可）
                  );
    BEGIN
      SELECT  xrv2.employee_number  employee_number -- 従業員コード
             ,xrv2.last_name        last_name       -- 漢字姓
             ,xrv2.first_name       first_name      -- 漢字名
             ,(CASE WHEN xrv2.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                      xrv2.work_base_code_new  -- 勤務地拠点コード（新）
                    ELSE
                      xrv2.work_base_code_old  -- 勤務地拠点コード（旧）
                    END
               ) work_base_code                -- 勤務地拠点コード
             ,(CASE WHEN xrv2.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                      xrv2.work_base_name_new  -- 勤務地拠点名（新）
                    ELSE
                      xrv2.work_base_name_old  -- 勤務地拠点名（旧）
                    END
               ) work_base_name                -- 勤務地拠点名
             /* 2009.11.25 K.Satomura E_本稼動_00026対応 START */
             ,xrv2.resource_id                 -- リソースＩＤ
             /* 2009.11.25 K.Satomura E_本稼動_00026対応 END */
      INTO    lt_employee_number
             ,lt_last_name
             ,lt_first_name
             ,lv_work_base_code
             ,lv_work_base_name
             /* 2009.11.25 K.Satomura E_本稼動_00026対応 START */
             ,gn_resource_id
             /* 2009.11.25 K.Satomura E_本稼動_00026対応 END */
      FROM   xxcso_resources_v2 xrv2           -- リソースマスタ(最新)VIEW
      WHERE (CASE WHEN xrv2.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                    xrv2.work_base_code_new  -- 勤務地拠点コード（新）
                  ELSE
                    xrv2.work_base_code_old  -- 勤務地拠点コード（旧）
                  END
             ) = ( SELECT (CASE WHEN xrv.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                                  xrv.work_base_code_new  -- 勤務地拠点コード（新）
                                ELSE
                                  xrv.work_base_code_old  -- 勤務地拠点コード（旧）
                                END
                           ) work_base_code2
                   FROM    xxcso_resources_v2 xrv
                   WHERE   xrv.user_id = cn_user_id
                  )
        AND xrv2.employee_number = iv_employee_number
        AND ((lv_retcd  =  cv_true
               AND xrv2.user_id = cn_user_id
              )
            OR (lv_retcd  =  cv_false
               AND 1 = 1
              ));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06    --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                       ,iv_token_value1 => iv_employee_number  --トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE chk_param_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
    -- OUTパラメータの設定
    od_visit_date      := TO_DATE(lv_visit_date, cv_format_date_ymd1);    -- 訪問日(DATE型)
    ov_full_name       := SUBSTRB(lt_last_name || lt_first_name, 1, 40);  -- 漢字氏名
    ov_work_base_code  := lv_work_base_code;   -- 勤務地拠点コード
    ov_hub_name        := lv_work_base_name;   -- 勤務地拠点名
--
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** パラメータチェックエラー ***
    WHEN chk_param_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : header_process
   * Description      : 帳票ヘッダ処理(A-3)
   ***********************************************************************************/
  PROCEDURE header_process(
     id_visit_date          IN  DATE                     -- 訪問日
    ,od_lst_vst_dt          OUT DATE                     -- 訪問日前週
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'header_process';     -- プログラム名
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
    -- *** ローカル変数 ***
    ld_lst_vst_dt    DATE;          -- 訪問日前週格納用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- 訪問日前週 導出
    -- ======================
    SELECT (id_visit_date - 7)  -- 訪問日前週
    INTO   ld_lst_vst_dt
    FROM dual
    ;
--
    -- OUTパラメータに設定
    od_lst_vst_dt := ld_lst_vst_dt;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END header_process;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_time
   * Description      : 時間別列処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_visit_time(
     i_vst_rslts_dt_rec     IN  g_vst_rslts_rtype        -- 営業員別時間別訪問実績データ
    ,ov_time_line           OUT NOCOPY VARCHAR2          -- 時間別列
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_visit_time';     -- プログラム名
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
    cv_fmt_time       CONSTANT VARCHAR(4) := 'HH24';
    -- 訪問時間
    cv_visit_time_09  CONSTANT VARCHAR(2) := '09';
    cv_visit_time_10  CONSTANT VARCHAR(2) := '10';
    cv_visit_time_11  CONSTANT VARCHAR(2) := '11';
    cv_visit_time_12  CONSTANT VARCHAR(2) := '12';
    cv_visit_time_13  CONSTANT VARCHAR(2) := '13';
    cv_visit_time_14  CONSTANT VARCHAR(2) := '14';
    cv_visit_time_15  CONSTANT VARCHAR(2) := '15';
    cv_visit_time_16  CONSTANT VARCHAR(2) := '16';
    cv_visit_time_17  CONSTANT VARCHAR(2) := '17';
    cv_visit_time_18  CONSTANT VARCHAR(2) := '18';
    cv_visit_time_19  CONSTANT VARCHAR(2) := '19';
    -- 時間別列
    cv_time_line_1    CONSTANT VARCHAR(2) := '1';
    cv_time_line_2    CONSTANT VARCHAR(2) := '2';
    cv_time_line_3    CONSTANT VARCHAR(2) := '3';
    cv_time_line_4    CONSTANT VARCHAR(2) := '4';
    cv_time_line_5    CONSTANT VARCHAR(2) := '5';
    cv_time_line_6    CONSTANT VARCHAR(2) := '6';
    cv_time_line_7    CONSTANT VARCHAR(2) := '7';
    cv_time_line_8    CONSTANT VARCHAR(2) := '8';
    cv_time_line_9    CONSTANT VARCHAR(2) := '9';
    cv_time_line_10   CONSTANT VARCHAR(2) := '10';
    cv_time_line_11   CONSTANT VARCHAR(2) := '11';
    cv_time_line_12   CONSTANT VARCHAR(2) := '12';
    -- *** ローカル変数 ***
    lv_visit_time  VARCHAR(2);
    lv_time_line   VARCHAR(2);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- 訪問時間の導出
    -- ======================
    SELECT TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_time)  visit_time -- 訪問時間
    INTO   lv_visit_time
    FROM   dual
    ;
    -- ======================
    -- 時間別列の導出
    -- ======================
    -- 訪問時間が9時より前の場合
    IF (lv_visit_time < cv_visit_time_09) THEN
      -- 時間別列に'1'を設定
      lv_time_line := cv_time_line_1;
--
    -- 訪問時間が9時の場合
    ELSIF (lv_visit_time = cv_visit_time_09) THEN
      -- 時間別列に'2'を設定
      lv_time_line := cv_time_line_2;
--
    -- 訪問時間が10時の場合
    ELSIF (lv_visit_time = cv_visit_time_10) THEN
      -- 時間別列に'3'を設定
      lv_time_line := cv_time_line_3;
--
    -- 訪問時間が11時の場合
    ELSIF (lv_visit_time = cv_visit_time_11) THEN
      -- 時間別列に'4'を設定
      lv_time_line := cv_time_line_4;
--
    -- 訪問時間が12時の場合
    ELSIF (lv_visit_time = cv_visit_time_12) THEN
      -- 時間別列に'5'を設定
      lv_time_line := cv_time_line_5;
--
    -- 訪問時間が13時の場合
    ELSIF (lv_visit_time = cv_visit_time_13) THEN
      -- 時間別列に'6'を設定
      lv_time_line := cv_time_line_6;
--
    -- 訪問時間が14時の場合
    ELSIF (lv_visit_time = cv_visit_time_14) THEN
      -- 時間別列に'7'を設定
      lv_time_line := cv_time_line_7;
--
    -- 訪問時間が15時の場合
    ELSIF (lv_visit_time = cv_visit_time_15) THEN
      -- 時間別列に'8'を設定
      lv_time_line := cv_time_line_8;
--
    -- 訪問時間が16時の場合
    ELSIF (lv_visit_time = cv_visit_time_16) THEN
      -- 時間別列に'9'を設定
      lv_time_line := cv_time_line_9;
--
    -- 訪問時間が17時の場合
    ELSIF (lv_visit_time = cv_visit_time_17) THEN
      -- 時間別列に'10'を設定
      lv_time_line := cv_time_line_10;
--
    -- 訪問時間が18時の場合
    ELSIF (lv_visit_time = cv_visit_time_18) THEN
      -- 時間別列に'11'を設定
      lv_time_line := cv_time_line_11;
--
    -- 訪問時間が19時以降の場合
    ELSIF (lv_visit_time >= cv_visit_time_19) THEN
      -- 時間別列に'12'を設定
      lv_time_line := cv_time_line_12;
    END IF;
--
   --OUTパラメータに設定
   ov_time_line := lv_time_line;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_visit_time;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_lines
   * Description      : 配列の追加、更新(A-6)
   ***********************************************************************************/
  PROCEDURE ins_upd_lines(
     id_visit_date          IN  DATE                     -- 訪問日
    ,iv_time_line           IN  VARCHAR2                 -- 時間別列
    ,id_vst_dt              IN  DATE                     -- メインカーソルの処理日
    ,i_vst_rslts_dt_rec     IN  g_vst_rslts_rtype        -- 営業員別時間別訪問実績データ
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'ins_upd_lines';     -- プログラム名
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
    -- 時間別列
    cv_time_line_1    CONSTANT VARCHAR(2) := '1';
    cv_time_line_2    CONSTANT VARCHAR(2) := '2';
    cv_time_line_3    CONSTANT VARCHAR(2) := '3';
    cv_time_line_4    CONSTANT VARCHAR(2) := '4';
    cv_time_line_5    CONSTANT VARCHAR(2) := '5';
    cv_time_line_6    CONSTANT VARCHAR(2) := '6';
    cv_time_line_7    CONSTANT VARCHAR(2) := '7';
    cv_time_line_8    CONSTANT VARCHAR(2) := '8';
    cv_time_line_9    CONSTANT VARCHAR(2) := '9';
    cv_time_line_10   CONSTANT VARCHAR(2) := '10';
    cv_time_line_11   CONSTANT VARCHAR(2) := '11';
    cv_time_line_12   CONSTANT VARCHAR(2) := '12';
    -- フォーマット
    cv_fmt_tm         CONSTANT VARCHAR(7) := 'HH24:MI';
    -- *** ローカル変数 ***
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- メインカーソルの処理日が、INパラメータ訪問日の場合
    IF (id_vst_dt = id_visit_date) THEN
      -- ======================
      -- 軒数計の更新
      -- ======================
      -- 総件数のカウントアップ
      gn_total_count := gn_total_count + 1;
--
      -- 軒数計のカウントアップ
      -- 時間別列が'1'の場合
      IF (iv_time_line = cv_time_line_1) THEN
        gn_total_count_1 := gn_total_count_1 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_1;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num         := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_1     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_1      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_1 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_1  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'2'の場合
      ELSIF (iv_time_line = cv_time_line_2) THEN
        gn_total_count_2 := gn_total_count_2 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_2;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num         := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_2     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_2      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_2 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_2  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'3'の場合
      ELSIF (iv_time_line = cv_time_line_3) THEN
        gn_total_count_3 := gn_total_count_3 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_3;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num         := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_3     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_3      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_3 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_3  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'4'の場合
      ELSIF (iv_time_line = cv_time_line_4) THEN
        gn_total_count_4 := gn_total_count_4 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_4;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num         := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_4     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_4      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_4 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_4  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'5'の場合
      ELSIF (iv_time_line = cv_time_line_5) THEN
        gn_total_count_5 := gn_total_count_5 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_5;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num         := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_5     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_5      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_5 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_5  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'6'の場合
      ELSIF (iv_time_line = cv_time_line_6) THEN
        gn_total_count_6 := gn_total_count_6 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_6;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num         := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_6     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_6      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_6 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_6  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'7'の場合
      ELSIF (iv_time_line = cv_time_line_7) THEN
        gn_total_count_7 := gn_total_count_7 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_7;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num         := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_7     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_7      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_7 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_7  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'8'の場合
      ELSIF (iv_time_line = cv_time_line_8) THEN
        gn_total_count_8 := gn_total_count_8 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_8;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num         := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_8     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_8      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_8 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_8  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'9'の場合
      ELSIF (iv_time_line = cv_time_line_9) THEN
        gn_total_count_9 := gn_total_count_9 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_9;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num         := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_9     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_9      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_9 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_9  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'10'の場合
      ELSIF (iv_time_line = cv_time_line_10) THEN
        gn_total_count_10 := gn_total_count_10 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_10;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num          := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_10     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_10      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_10 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_10  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'11'の場合
      ELSIF (iv_time_line = cv_time_line_11) THEN
        gn_total_count_11 := gn_total_count_11 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_11;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num          := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_11     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_11      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_11 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_11  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
--
      -- 時間別列が'12'の場合
      ELSIF (iv_time_line = cv_time_line_12) THEN
        gn_total_count_12 := gn_total_count_12 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_total_count_12;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num          := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).visit_time_12     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm); -- 訪問時刻
        g_rep_vst_slsemp_tab(gn_cnt).sales_amt_12      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額
        g_rep_vst_slsemp_tab(gn_cnt).account_number_12 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード
        g_rep_vst_slsemp_tab(gn_cnt).customer_name_12  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称
      END IF;
    -- メインカーソルの処理日が、INパラメータ訪問日でない場合
    ELSE
      -- ======================
      -- 軒数計の更新
      -- ======================
      -- 総件数(前週)のカウントアップ
      gn_last_total_count := gn_last_total_count + 1;
--
      -- 軒数計(前週)のカウントアップ
      -- 時間別列が'1'の場合
      IF (iv_time_line = cv_time_line_1) THEN
        gn_last_total_count_1 := gn_last_total_count_1 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_1;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num              := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_1     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_1      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_1 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_1  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称(前週)
--
      -- 時間別列が'2'の場合
      ELSIF (iv_time_line = cv_time_line_2) THEN
        gn_last_total_count_2 := gn_last_total_count_2 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_2;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num              := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_2     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_2      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_2 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_2  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称(前週)
--
      -- 時間別列が'3'の場合
      ELSIF (iv_time_line = cv_time_line_3) THEN
        gn_last_total_count_3 := gn_last_total_count_3 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_3;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num              := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_3     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_3      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_3 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_3  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称(前週)
--
      -- 時間別列が'4'の場合
      ELSIF (iv_time_line = cv_time_line_4) THEN
        gn_last_total_count_4 := gn_last_total_count_4 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_4;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num              := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_4     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_4      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_4 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_4  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称(前週)
--
      -- 時間別列が'5'の場合
      ELSIF (iv_time_line = cv_time_line_5) THEN
        gn_last_total_count_5 := gn_last_total_count_5 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_5;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num              := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_5     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_5      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_5 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_5  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称(前週)
--
      -- 時間別列が'6'の場合
      ELSIF (iv_time_line = cv_time_line_6) THEN
        gn_last_total_count_6 := gn_last_total_count_6 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_6;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num              := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_6     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_6      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_6 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_6  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称(前週)
--
      -- 時間別列が'7'の場合
      ELSIF (iv_time_line = cv_time_line_7) THEN
        gn_last_total_count_7 := gn_last_total_count_7 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_7;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num              := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_7     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_7      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_7 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_7  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称(前週)
--
      -- 時間別列が'8'の場合
      ELSIF (iv_time_line = cv_time_line_8) THEN
        gn_last_total_count_8 := gn_last_total_count_8 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_8;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num              := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_8     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_8      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_8 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_8  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称(前週)
--
      -- 時間別列が'9'の場合
      ELSIF (iv_time_line = cv_time_line_9) THEN
        gn_last_total_count_9 := gn_last_total_count_9 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_9;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num              := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_9     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_9      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000); -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_9 := i_vst_rslts_dt_rec.account_number;              -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_9  := i_vst_rslts_dt_rec.party_name;                  -- 顧客名称(前週)
--
      -- 時間別列が'10'の場合
      ELSIF (iv_time_line = cv_time_line_10) THEN
        gn_last_total_count_10 := gn_last_total_count_10 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_10;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num               := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_10     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_10      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000);
        -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_10 := i_vst_rslts_dt_rec.account_number;  -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_10  := i_vst_rslts_dt_rec.party_name;      -- 顧客名称(前週)
--
      -- 時間別列が'11'の場合
      ELSIF (iv_time_line = cv_time_line_11) THEN
        gn_last_total_count_11 := gn_last_total_count_11 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_11;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num               := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_11     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_11      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000);
        -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_11 := i_vst_rslts_dt_rec.account_number;  -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_11  := i_vst_rslts_dt_rec.party_name;      -- 顧客名称(前週)
--
      -- 時間別列が'12'の場合
      ELSIF (iv_time_line = cv_time_line_12) THEN
        gn_last_total_count_12 := gn_last_total_count_12 + 1;
        -- 配列用カウンタへ格納
        gn_cnt := gn_last_total_count_12;
        -- 配列へのデータ格納
        g_rep_vst_slsemp_tab(gn_cnt).line_num               := gn_cnt; -- 行番号
        g_rep_vst_slsemp_tab(gn_cnt).last_visit_time_12     := TO_CHAR(i_vst_rslts_dt_rec.actual_end_date, cv_fmt_tm);
        -- 訪問時刻(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_sales_amt_12      := ROUND(i_vst_rslts_dt_rec.pure_amount_sum/1000);
        -- 売上金額(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_account_number_12 := i_vst_rslts_dt_rec.account_number;  -- 顧客コード(前週)
        g_rep_vst_slsemp_tab(gn_cnt).last_customer_name_12  := i_vst_rslts_dt_rec.party_name;      -- 顧客名称(前週)
      END IF;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_upd_lines;
--
  /**********************************************************************************
   * Procedure Name   : insert_row
   * Description      : ワークテーブルデータ登録(A-7)
   ***********************************************************************************/
  PROCEDURE insert_row(
     id_visit_date          IN  DATE                               -- 訪問年月日
    ,iv_employee_number     IN  VARCHAR2                           -- 従業員コード
    ,iv_work_base_code      IN  VARCHAR2                           -- 拠点コード
    ,iv_hub_name            IN  VARCHAR2                           -- 拠点名称
    ,iv_full_name           IN  VARCHAR2                           -- 漢字氏名
    ,ov_errbuf              OUT NOCOPY VARCHAR2                    -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                    -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                    -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_row';     -- プログラム名
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
    cv_report_name      CONSTANT VARCHAR2(40)  := '≪営業員別訪問実績表≫'; -- 帳票タイトル
    cv_tkn_tbl_nm       CONSTANT VARCHAR2(100) := '営業員別訪問実績表帳票ワークテーブルの登録';
    -- *** ローカル変数 ***
    ld_lst_vst_dt       DATE;               -- 訪問日前週格納用
    -- *** ローカル例外 ***
    insert_row_expt     EXCEPTION;          -- ワークテーブル出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      <<insert_row_loop>>
      FOR i IN 1..g_rep_vst_slsemp_tab.COUNT LOOP
        -- ======================
        -- ワークテーブルデータ登録
        -- ======================
        INSERT INTO xxcso_rep_visit_salesemp
          ( line_num                      -- 行番号
           ,report_id                     -- 帳票ＩＤ
           ,report_name                   -- 帳票タイトル
           ,output_date                   -- 出力日時
           ,visit_date                    -- 訪問年月日
           ,base_code                     -- 拠点コード
           ,hub_name                      -- 拠点名称
           ,employee_number               -- 営業員コード
           ,employee_name                 -- 営業員名
           ,total_count                   -- 総軒数
           ,total_count_1                 -- 軒数計１
           ,total_count_2                 -- 軒数計２
           ,total_count_3                 -- 軒数計３
           ,total_count_4                 -- 軒数計４
           ,total_count_5                 -- 軒数計５
           ,total_count_6                 -- 軒数計６
           ,total_count_7                 -- 軒数計７
           ,total_count_8                 -- 軒数計８
           ,total_count_9                 -- 軒数計９
           ,total_count_10                -- 軒数計１０
           ,total_count_11                -- 軒数計１１
           ,total_count_12                -- 軒数計１２
           ,visit_time_1                  -- 訪問時刻１
           ,sales_amt_1                   -- 売上金額１
           ,account_number_1              -- 顧客コード１
           ,customer_name_1               -- 顧客名称１
           ,visit_time_2                  -- 訪問時刻２
           ,sales_amt_2                   -- 売上金額２
           ,account_number_2              -- 顧客コード２
           ,customer_name_2               -- 顧客名称２
           ,visit_time_3                  -- 訪問時刻３
           ,sales_amt_3                   -- 売上金額３
           ,account_number_3              -- 顧客コード３
           ,customer_name_3               -- 顧客名称３
           ,visit_time_4                  -- 訪問時刻４
           ,sales_amt_4                   -- 売上金額４
           ,account_number_4              -- 顧客コード４
           ,customer_name_4               -- 顧客名称４
           ,visit_time_5                  -- 訪問時刻５
           ,sales_amt_5                   -- 売上金額５
           ,account_number_5              -- 顧客コード５
           ,customer_name_5               -- 顧客名称５
           ,visit_time_6                  -- 訪問時刻６
           ,sales_amt_6                   -- 売上金額６
           ,account_number_6              -- 顧客コード６
           ,customer_name_6               -- 顧客名称６
           ,visit_time_7                  -- 訪問時刻７
           ,sales_amt_7                   -- 売上金額７
           ,account_number_7              -- 顧客コード７
           ,customer_name_7               -- 顧客名称７
           ,visit_time_8                  -- 訪問時刻８
           ,sales_amt_8                   -- 売上金額８
           ,account_number_8              -- 顧客コード８
           ,customer_name_8               -- 顧客名称８
           ,visit_time_9                  -- 訪問時刻９
           ,sales_amt_9                   -- 売上金額９
           ,account_number_9              -- 顧客コード９
           ,customer_name_9               -- 顧客名称９
           ,visit_time_10                 -- 訪問時刻１０
           ,sales_amt_10                  -- 売上金額１０
           ,account_number_10             -- 顧客コード１０
           ,customer_name_10              -- 顧客名称１０
           ,visit_time_11                 -- 訪問時刻１１
           ,sales_amt_11                  -- 売上金額１１
           ,account_number_11             -- 顧客コード１１
           ,customer_name_11              -- 顧客名称１１
           ,visit_time_12                 -- 訪問時刻１２
           ,sales_amt_12                  -- 売上金額１２
           ,account_number_12             -- 顧客コード１２
           ,customer_name_12              -- 顧客名称１２
           ,last_total_count              -- 前週総軒数
           ,last_total_count_1            -- 前週軒数計１
           ,last_total_count_2            -- 前週軒数計２
           ,last_total_count_3            -- 前週軒数計３
           ,last_total_count_4            -- 前週軒数計４
           ,last_total_count_5            -- 前週軒数計５
           ,last_total_count_6            -- 前週軒数計６
           ,last_total_count_7            -- 前週軒数計７
           ,last_total_count_8            -- 前週軒数計８
           ,last_total_count_9            -- 前週軒数計９
           ,last_total_count_10           -- 前週軒数計１０
           ,last_total_count_11           -- 前週軒数計１１
           ,last_total_count_12           -- 前週軒数計１２
           ,last_visit_time_1             -- 前週訪問時刻１
           ,last_sales_amt_1              -- 前週売上金額１
           ,last_account_number_1         -- 前週顧客コード１
           ,last_customer_name_1          -- 前週顧客名称１
           ,last_visit_time_2             -- 前週訪問時刻２
           ,last_sales_amt_2              -- 前週売上金額２
           ,last_account_number_2         -- 前週顧客コード２
           ,last_customer_name_2          -- 前週顧客名称２
           ,last_visit_time_3             -- 前週訪問時刻３
           ,last_sales_amt_3              -- 前週売上金額３
           ,last_account_number_3         -- 前週顧客コード３
           ,last_customer_name_3          -- 前週顧客名称３
           ,last_visit_time_4             -- 前週訪問時刻４
           ,last_sales_amt_4              -- 前週売上金額４
           ,last_account_number_4         -- 前週顧客コード４
           ,last_customer_name_4          -- 前週顧客名称４
           ,last_visit_time_5             -- 前週訪問時刻５
           ,last_sales_amt_5              -- 前週売上金額５
           ,last_account_number_5         -- 前週顧客コード５
           ,last_customer_name_5          -- 前週顧客名称５
           ,last_visit_time_6             -- 前週訪問時刻６
           ,last_sales_amt_6              -- 前週売上金額６
           ,last_account_number_6         -- 前週顧客コード６
           ,last_customer_name_6          -- 前週顧客名称６
           ,last_visit_time_7             -- 前週訪問時刻７
           ,last_sales_amt_7              -- 前週売上金額７
           ,last_account_number_7         -- 前週顧客コード７
           ,last_customer_name_7          -- 前週顧客名称７
           ,last_visit_time_8             -- 前週訪問時刻８
           ,last_sales_amt_8              -- 前週売上金額８
           ,last_account_number_8         -- 前週顧客コード８
           ,last_customer_name_8          -- 前週顧客名称８
           ,last_visit_time_9             -- 前週訪問時刻９
           ,last_sales_amt_9              -- 前週売上金額９
           ,last_account_number_9         -- 前週顧客コード９
           ,last_customer_name_9          -- 前週顧客名称９
           ,last_visit_time_10            -- 前週訪問時刻１０
           ,last_sales_amt_10             -- 前週売上金額１０
           ,last_account_number_10        -- 前週顧客コード１０
           ,last_customer_name_10         -- 前週顧客名称１０
           ,last_visit_time_11            -- 前週訪問時刻１１
           ,last_sales_amt_11             -- 前週売上金額１１
           ,last_account_number_11        -- 前週顧客コード１１
           ,last_customer_name_11         -- 前週顧客名称１１
           ,last_visit_time_12            -- 前週訪問時刻１２
           ,last_sales_amt_12             -- 前週売上金額１２
           ,last_account_number_12        -- 前週顧客コード１２
           ,last_customer_name_12         -- 前週顧客名称１２
           ,created_by                    -- 作成者
           ,creation_date                 -- 作成日
           ,last_updated_by               -- 最終更新者
           ,last_update_date              -- 最終更新日
           ,last_update_login             -- 最終更新ログイン
           ,request_id                    -- 要求ID
           ,program_application_id        -- コンカレント・プログラム・アプリケーションID
           ,program_id                    -- コンカレント・プログラムID
           ,program_update_date           -- プログラム更新日
          )
        VALUES
         (  g_rep_vst_slsemp_tab(i).line_num                      -- 行番号
           ,cv_report_id                                          -- 帳票ＩＤ(未定)
           ,cv_report_name                                        -- 帳票タイトル
           ,cd_sysdate                                            -- 出力日時
           ,id_visit_date                                         -- 訪問年月日
           ,iv_work_base_code                                     -- 拠点コード
           ,iv_hub_name                                           -- 拠点名称
           ,iv_employee_number                                    -- 営業員コード
           ,iv_full_name                                          -- 営業員名
           ,gn_total_count                                        -- 総軒数
           ,gn_total_count_1                                      -- 軒数計１
           ,gn_total_count_2                                      -- 軒数計２
           ,gn_total_count_3                                      -- 軒数計３
           ,gn_total_count_4                                      -- 軒数計４
           ,gn_total_count_5                                      -- 軒数計５
           ,gn_total_count_6                                      -- 軒数計６
           ,gn_total_count_7                                      -- 軒数計７
           ,gn_total_count_8                                      -- 軒数計８
           ,gn_total_count_9                                      -- 軒数計９
           ,gn_total_count_10                                     -- 軒数計１０
           ,gn_total_count_11                                     -- 軒数計１１
           ,gn_total_count_12                                     -- 軒数計１２
           ,g_rep_vst_slsemp_tab(i).visit_time_1                  -- 訪問時刻１
           ,g_rep_vst_slsemp_tab(i).sales_amt_1                   -- 売上金額１
           ,g_rep_vst_slsemp_tab(i).account_number_1              -- 顧客コード１
           ,g_rep_vst_slsemp_tab(i).customer_name_1               -- 顧客名称１
           ,g_rep_vst_slsemp_tab(i).visit_time_2                  -- 訪問時刻２
           ,g_rep_vst_slsemp_tab(i).sales_amt_2                   -- 売上金額２
           ,g_rep_vst_slsemp_tab(i).account_number_2              -- 顧客コード２
           ,g_rep_vst_slsemp_tab(i).customer_name_2               -- 顧客名称２
           ,g_rep_vst_slsemp_tab(i).visit_time_3                  -- 訪問時刻３
           ,g_rep_vst_slsemp_tab(i).sales_amt_3                   -- 売上金額３
           ,g_rep_vst_slsemp_tab(i).account_number_3              -- 顧客コード３
           ,g_rep_vst_slsemp_tab(i).customer_name_3               -- 顧客名称３
           ,g_rep_vst_slsemp_tab(i).visit_time_4                  -- 訪問時刻４
           ,g_rep_vst_slsemp_tab(i).sales_amt_4                   -- 売上金額４
           ,g_rep_vst_slsemp_tab(i).account_number_4              -- 顧客コード４
           ,g_rep_vst_slsemp_tab(i).customer_name_4               -- 顧客名称４
           ,g_rep_vst_slsemp_tab(i).visit_time_5                  -- 訪問時刻５
           ,g_rep_vst_slsemp_tab(i).sales_amt_5                   -- 売上金額５
           ,g_rep_vst_slsemp_tab(i).account_number_5              -- 顧客コード５
           ,g_rep_vst_slsemp_tab(i).customer_name_5               -- 顧客名称５
           ,g_rep_vst_slsemp_tab(i).visit_time_6                  -- 訪問時刻６
           ,g_rep_vst_slsemp_tab(i).sales_amt_6                   -- 売上金額６
           ,g_rep_vst_slsemp_tab(i).account_number_6              -- 顧客コード６
           ,g_rep_vst_slsemp_tab(i).customer_name_6               -- 顧客名称６
           ,g_rep_vst_slsemp_tab(i).visit_time_7                  -- 訪問時刻７
           ,g_rep_vst_slsemp_tab(i).sales_amt_7                   -- 売上金額７
           ,g_rep_vst_slsemp_tab(i).account_number_7              -- 顧客コード７
           ,g_rep_vst_slsemp_tab(i).customer_name_7               -- 顧客名称７
           ,g_rep_vst_slsemp_tab(i).visit_time_8                  -- 訪問時刻８
           ,g_rep_vst_slsemp_tab(i).sales_amt_8                   -- 売上金額８
           ,g_rep_vst_slsemp_tab(i).account_number_8              -- 顧客コード８
           ,g_rep_vst_slsemp_tab(i).customer_name_8               -- 顧客名称８
           ,g_rep_vst_slsemp_tab(i).visit_time_9                  -- 訪問時刻９
           ,g_rep_vst_slsemp_tab(i).sales_amt_9                   -- 売上金額９
           ,g_rep_vst_slsemp_tab(i).account_number_9              -- 顧客コード９
           ,g_rep_vst_slsemp_tab(i).customer_name_9               -- 顧客名称９
           ,g_rep_vst_slsemp_tab(i).visit_time_10                 -- 訪問時刻１０
           ,g_rep_vst_slsemp_tab(i).sales_amt_10                  -- 売上金額１０
           ,g_rep_vst_slsemp_tab(i).account_number_10             -- 顧客コード１０
           ,g_rep_vst_slsemp_tab(i).customer_name_10              -- 顧客名称１０
           ,g_rep_vst_slsemp_tab(i).visit_time_11                 -- 訪問時刻１１
           ,g_rep_vst_slsemp_tab(i).sales_amt_11                  -- 売上金額１１
           ,g_rep_vst_slsemp_tab(i).account_number_11             -- 顧客コード１１
           ,g_rep_vst_slsemp_tab(i).customer_name_11              -- 顧客名称１１
           ,g_rep_vst_slsemp_tab(i).visit_time_12                 -- 訪問時刻１２
           ,g_rep_vst_slsemp_tab(i).sales_amt_12                  -- 売上金額１２
           ,g_rep_vst_slsemp_tab(i).account_number_12             -- 顧客コード１２
           ,g_rep_vst_slsemp_tab(i).customer_name_12              -- 顧客名称１２
           ,gn_last_total_count                                   -- 前週総軒数
           ,gn_last_total_count_1                                 -- 前週軒数計１
           ,gn_last_total_count_2                                 -- 前週軒数計２
           ,gn_last_total_count_3                                 -- 前週軒数計３
           ,gn_last_total_count_4                                 -- 前週軒数計４
           ,gn_last_total_count_5                                 -- 前週軒数計５
           ,gn_last_total_count_6                                 -- 前週軒数計６
           ,gn_last_total_count_7                                 -- 前週軒数計７
           ,gn_last_total_count_8                                 -- 前週軒数計８
           ,gn_last_total_count_9                                 -- 前週軒数計９
           ,gn_last_total_count_10                                -- 前週軒数計１０
           ,gn_last_total_count_11                                -- 前週軒数計１１
           ,gn_last_total_count_12                                -- 前週軒数計１２
           ,g_rep_vst_slsemp_tab(i).last_visit_time_1             -- 前週訪問時刻１
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_1              -- 前週売上金額１
           ,g_rep_vst_slsemp_tab(i).last_account_number_1         -- 前週顧客コード１
           ,g_rep_vst_slsemp_tab(i).last_customer_name_1          -- 前週顧客名称１
           ,g_rep_vst_slsemp_tab(i).last_visit_time_2             -- 前週訪問時刻２
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_2              -- 前週売上金額２
           ,g_rep_vst_slsemp_tab(i).last_account_number_2         -- 前週顧客コード２
           ,g_rep_vst_slsemp_tab(i).last_customer_name_2          -- 前週顧客名称２
           ,g_rep_vst_slsemp_tab(i).last_visit_time_3             -- 前週訪問時刻３
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_3              -- 前週売上金額３
           ,g_rep_vst_slsemp_tab(i).last_account_number_3         -- 前週顧客コード３
           ,g_rep_vst_slsemp_tab(i).last_customer_name_3          -- 前週顧客名称３
           ,g_rep_vst_slsemp_tab(i).last_visit_time_4             -- 前週訪問時刻４
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_4              -- 前週売上金額４
           ,g_rep_vst_slsemp_tab(i).last_account_number_4         -- 前週顧客コード４
           ,g_rep_vst_slsemp_tab(i).last_customer_name_4          -- 前週顧客名称４
           ,g_rep_vst_slsemp_tab(i).last_visit_time_5             -- 前週訪問時刻５
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_5              -- 前週売上金額５
           ,g_rep_vst_slsemp_tab(i).last_account_number_5         -- 前週顧客コード５
           ,g_rep_vst_slsemp_tab(i).last_customer_name_5          -- 前週顧客名称５
           ,g_rep_vst_slsemp_tab(i).last_visit_time_6             -- 前週訪問時刻６
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_6              -- 前週売上金額６
           ,g_rep_vst_slsemp_tab(i).last_account_number_6         -- 前週顧客コード６
           ,g_rep_vst_slsemp_tab(i).last_customer_name_6          -- 前週顧客名称６
           ,g_rep_vst_slsemp_tab(i).last_visit_time_7             -- 前週訪問時刻７
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_7              -- 前週売上金額７
           ,g_rep_vst_slsemp_tab(i).last_account_number_7         -- 前週顧客コード７
           ,g_rep_vst_slsemp_tab(i).last_customer_name_7          -- 前週顧客名称７
           ,g_rep_vst_slsemp_tab(i).last_visit_time_8             -- 前週訪問時刻８
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_8              -- 前週売上金額８
           ,g_rep_vst_slsemp_tab(i).last_account_number_8         -- 前週顧客コード８
           ,g_rep_vst_slsemp_tab(i).last_customer_name_8          -- 前週顧客名称８
           ,g_rep_vst_slsemp_tab(i).last_visit_time_9             -- 前週訪問時刻９
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_9              -- 前週売上金額９
           ,g_rep_vst_slsemp_tab(i).last_account_number_9         -- 前週顧客コード９
           ,g_rep_vst_slsemp_tab(i).last_customer_name_9          -- 前週顧客名称９
           ,g_rep_vst_slsemp_tab(i).last_visit_time_10            -- 前週訪問時刻１０
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_10             -- 前週売上金額１０
           ,g_rep_vst_slsemp_tab(i).last_account_number_10        -- 前週顧客コード１０
           ,g_rep_vst_slsemp_tab(i).last_customer_name_10         -- 前週顧客名称１０
           ,g_rep_vst_slsemp_tab(i).last_visit_time_11            -- 前週訪問時刻１１
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_11             -- 前週売上金額１１
           ,g_rep_vst_slsemp_tab(i).last_account_number_11        -- 前週顧客コード１１
           ,g_rep_vst_slsemp_tab(i).last_customer_name_11         -- 前週顧客名称１１
           ,g_rep_vst_slsemp_tab(i).last_visit_time_12            -- 前週訪問時刻１２
           ,g_rep_vst_slsemp_tab(i).last_sales_amt_12             -- 前週売上金額１２
           ,g_rep_vst_slsemp_tab(i).last_account_number_12        -- 前週顧客コード１２
           ,g_rep_vst_slsemp_tab(i).last_customer_name_12         -- 前週顧客名称１２
           ,cn_created_by                                         -- 作成者
           ,cd_creation_date                                      -- 作成日
           ,cn_last_updated_by                                    -- 最終更新者
           ,cd_last_update_date                                   -- 最終更新日
           ,cn_last_update_login                                  -- 最終更新ログイン
           ,cn_request_id                                         -- 要求ID
           ,cn_program_application_id                             -- コンカレント・プログラム・アプリケーションID
           ,cn_program_id                                         -- コンカレント・プログラムID
           ,cd_program_update_date                                -- プログラム更新日
         );
      END LOOP insert_row_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_09        --メッセージコード
                 ,iv_token_name1  => cv_tkn_act              --トークンコード1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --トークン値1
                 ,iv_token_name2  => cv_tkn_errmsg           --トークンコード2
                 ,iv_token_value2 => SQLERRM                 --トークン値2
                );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_row_expt;
    END;
--
  EXCEPTION
    -- *** ワークテーブル出力処理例外 ***
    WHEN insert_row_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_row;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF起動(A-8)
   ***********************************************************************************/
  PROCEDURE act_svf(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'act_svf';     -- プログラム名
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
    cv_tkn_api_nm_svf CONSTANT  VARCHAR2(20) := 'SVF起動';
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCSO019A07S.xml';  -- フォーム様式ファイル名
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCSO019A07S.vrq';  -- クエリー様式ファイル名
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';  
    -- *** ローカル変数 ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- SVF起動処理 
    -- ======================
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR (cd_creation_date, cv_format_date_ymd1)
                     || TO_CHAR (cn_request_id);
--
    BEGIN
      SELECT  user_concurrent_program_name,
              xx00_global_pkg.user_name   ,
              xx00_global_pkg.resp_name
      INTO    lv_conc_name,
              lv_user_name,
              lv_resp_name
      FROM    fnd_concurrent_programs_tl
      WHERE   concurrent_program_id =cn_request_id
      AND     LANGUAGE = 'JA'
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_pkg_name;
    END;
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_conc_name    => lv_conc_name          -- コンカレント名
     ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
     ,iv_file_id      => lv_file_id            -- 帳票ID
     ,iv_output_mode  => cv_output_mode        -- 出力区分(=1：PDF出力）
     ,iv_frm_file     => cv_svf_form_name      -- フォーム様式ファイル名
     ,iv_vrq_file     => cv_svf_query_name     -- クエリー様式ファイル名
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
     ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                  -- 文書名
     ,iv_printer_name => NULL                  -- プリンタ名
     ,iv_request_id   => cn_request_id         -- 要求ID
     ,iv_nodata_msg   => NULL                  -- データなしメッセージ
     );
--
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_07        --メッセージコード
                 ,iv_token_name1  => cv_tkn_api_nm           --トークンコード1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --トークン値1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_row
   * Description      : ワークテーブルデータ削除(A-9)
   ***********************************************************************************/
  PROCEDURE delete_row(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_row';     -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==========================
    -- ワークテーブルデータ削除
    -- ==========================
    DELETE FROM xxcso_rep_visit_salesemp xrvs -- 営業員別訪問実績表帳票ワークテーブル
    WHERE xrvs.request_id = cn_request_id;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_row;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     iv_visit_date       IN  VARCHAR2          -- 訪問日
    ,iv_employee_number  IN  VARCHAR2          -- 従業員コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
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
    cv_cstmr_cls_cd10      CONSTANT VARCHAR(2) := '10';      -- 顧客区分:10 (顧客)
    cv_cstmr_cls_cd12      CONSTANT VARCHAR(2) := '12';      -- 顧客区分:12 (上様顧客)
    cv_cstmr_cls_cd15      CONSTANT VARCHAR(2) := '15';      -- 顧客区分:15 (巡回)
    cv_cstmr_cls_cd16      CONSTANT VARCHAR(2) := '16';      -- 顧客区分:16 (問屋帳合先)
    --
    cv_cstmr_sttus25       CONSTANT VARCHAR(2) := '25';      -- 顧客ステータス:25 (SP決済済)
    cv_cstmr_sttus30       CONSTANT VARCHAR(2) := '30';      -- 顧客ステータス:30 (承認済)
    cv_cstmr_sttus40       CONSTANT VARCHAR(2) := '40';      -- 顧客ステータス:40 (顧客)
    cv_cstmr_sttus50       CONSTANT VARCHAR(2) := '50';      -- 顧客ステータス:50 (休止)
    cv_cstmr_sttus99       CONSTANT VARCHAR(2) := '99';      -- 顧客ステータス:99 (対象外)
    -- *** ローカル変数 ***
    -- ループカウンタ
    ln_loop_cnt            NUMBER DEFAULT 1;
    -- OUTパラメータ格納用
    ld_visit_date          DATE;             -- 訪問日
    ld_lst_vst_dt          DATE;             -- 訪問日前週
    ld_vst_dt              DATE;             -- 処理日
    lv_time_line           VARCHAR(2);       -- 時間別列
    lv_full_name           VARCHAR(40);      -- 漢字氏名
    lv_work_base_code      VARCHAR2(150);    -- 勤務地拠点コード
    lv_hub_name            VARCHAR2(4000);   -- 勤務地拠点名
    -- メッセージ格納用
    lv_msg                 VARCHAR2(5000);
    -- SVF起動API戻り値格納用
    lv_errbuf_svf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_svf         VARCHAR2(1);     -- リターン・コード
    lv_errmsg_svf          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    -- *** ローカル・カーソル ***
    -- 営業員別時間別訪問実績 抽出カーソル 
    CURSOR get_vst_rslts_data_cur(
              id_vst_dt   IN  DATE     -- 処理日
             /* 2009.11.25 K.Satomura E_本稼動_00026対応 START */
             --,iv_emp_num  IN VARCHAR2  -- 従業員コード
             ,in_resource_id IN NUMBER -- リソースＩＤ
             /* 2009.11.25 K.Satomura E_本稼動_00026対応 END */
           )
    IS
      SELECT  xvsrv.actual_end_date  actual_end_date -- 実績終了日
             ,xvsrv.pure_amount_sum  pure_amount_sum -- 本体金額合計
             ,xcav.account_number    account_number  -- 顧客コード
             ,xcav.party_name        party_name      -- 顧客名称
      FROM    xxcso_cust_accounts_v       xcav           -- 顧客マスタVIEW
             /* 2009.11.25 K.Satomura E_本稼動_00026対応 START */
             --,xxcso_resources_v2          xrv2           -- リソースマスタ(最新)VIEW
             /* 2009.11.25 K.Satomura E_本稼動_00026対応 END */
             ,xxcso_visit_sales_results_v xvsrv          -- 訪問売上実績VIEW
      WHERE  TRUNC(xvsrv.actual_end_date) = id_vst_dt
        /* 2009.11.25 K.Satomura E_本稼動_00026対応 START */
        --AND  xvsrv.owner_id               = xrv2.resource_id
        AND  xvsrv.owner_id               = in_resource_id
        /* 2009.11.25 K.Satomura E_本稼動_00026対応 END */
        AND  xvsrv.party_id               = xcav.party_id
        /* 2009.11.25 K.Satomura E_本稼動_00026対応 START */
        --AND  xrv2.employee_number         = iv_emp_num
        /* 2009.11.25 K.Satomura E_本稼動_00026対応 END */
        AND  ((xcav.customer_class_code    = cv_cstmr_cls_cd10
                AND xcav.customer_status    IN (cv_cstmr_sttus25, cv_cstmr_sttus30,
                                                  cv_cstmr_sttus40, cv_cstmr_sttus50))
          OR  (xcav.customer_class_code    = cv_cstmr_cls_cd12
                AND xcav.customer_status    IN (cv_cstmr_sttus30, cv_cstmr_sttus40))
          OR  (xcav.customer_class_code    = cv_cstmr_cls_cd15
                AND xcav.customer_status    = cv_cstmr_sttus99)
          OR  (xcav.customer_class_code    = cv_cstmr_cls_cd16
                AND xcav.customer_status    = cv_cstmr_sttus99)
             )
      ORDER BY
         xvsrv.actual_end_date ASC
        ,xvsrv.pure_amount_sum DESC
        ,xcav.account_number   ASC
    ;
--
    -- *** ローカル・レコード ***
    l_vst_rslts_dt_cur_rec     get_vst_rslts_data_cur%ROWTYPE;
    l_vst_rslts_dt_rec         g_vst_rslts_rtype;
    -- *** ローカル・例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カウンタの初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -- ========================================
    -- A-1.初期処理
    -- ========================================
    init(
       iv_visit_date       => iv_visit_date          -- 訪問日
      ,iv_employee_number  => iv_employee_number     -- 従業員コード
      ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-2.パラメータチェック
    -- ========================================
    chk_param(
       iv_visit_date       => iv_visit_date          -- 訪問日
      ,iv_employee_number  => iv_employee_number     -- 従業員コード
      ,od_visit_date       => ld_visit_date          -- 訪問日(DATE型)
      ,ov_full_name        => lv_full_name           -- 漢字氏名
      ,ov_work_base_code   => lv_work_base_code      -- 勤務地拠点コード
      ,ov_hub_name         => lv_hub_name            -- 勤務地拠点名
      ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-3.帳票ヘッダ処理
    -- ========================================
    header_process(
       id_visit_date       => ld_visit_date          -- 訪問日
      ,od_lst_vst_dt       => ld_lst_vst_dt          -- 訪問日前週
      ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-4.データ取得
    -- ========================================
--
    <<get_vst_slsemp_data_loop1>>
    LOOP
      -- 3回目にEXIT
      EXIT WHEN ln_loop_cnt >= 3;
--
      IF ln_loop_cnt = 1 THEN
        -- カーソルに渡す処理日に、INパラメータ訪問日を設定
        ld_vst_dt := ld_visit_date;
      ELSIF ln_loop_cnt = 2 THEN
        -- カーソルに渡す処理日に、訪問日前週を設定
        ld_vst_dt := ld_lst_vst_dt;
      END IF;
--
      -- カーソルオープン
      OPEN  get_vst_rslts_data_cur(
               id_vst_dt   => ld_vst_dt          -- 処理日
              /* 2009.11.25 K.Satomura E_本稼動_00026対応 START */
              --,iv_emp_num  => iv_employee_number -- 従業員コード
              ,in_resource_id => gn_resource_id -- リソースＩＤ
              /* 2009.11.25 K.Satomura E_本稼動_00026対応 END */
            );
--
      <<get_vst_slsemp_data_loop2>>
      LOOP
--
        FETCH get_vst_rslts_data_cur INTO l_vst_rslts_dt_cur_rec;
--
        -- 処理対象データが存在しなかった場合EXIT
        EXIT WHEN get_vst_rslts_data_cur%NOTFOUND
        OR  get_vst_rslts_data_cur%ROWCOUNT = 0;
--
        -- 処理対象件数カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
--
        -- レコード変数初期化
        l_vst_rslts_dt_rec := NULL;
--
        -- 取得データを格納
        l_vst_rslts_dt_rec.actual_end_date := l_vst_rslts_dt_cur_rec.actual_end_date;  -- 実績終了日
        l_vst_rslts_dt_rec.pure_amount_sum := l_vst_rslts_dt_cur_rec.pure_amount_sum;  -- 本体金額合計
        l_vst_rslts_dt_rec.account_number  := l_vst_rslts_dt_cur_rec.account_number;   -- 顧客コード
        l_vst_rslts_dt_rec.party_name      := l_vst_rslts_dt_cur_rec.party_name;       -- 顧客名称
--
        -- ========================================
        -- A-5.時間別列処理
        -- ========================================
        get_visit_time(
           i_vst_rslts_dt_rec  => l_vst_rslts_dt_rec     -- 営業員別時間別訪問実績データ
          ,ov_time_line        => lv_time_line           -- 時間別列
          ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
          ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
          ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        -- ========================================
        -- A-6.配列の追加、更新
        -- ========================================
        ins_upd_lines(
           id_visit_date       => ld_visit_date          -- 訪問日
          ,iv_time_line        => lv_time_line           -- 時間別列
          ,id_vst_dt           => ld_vst_dt              -- メインカーソルの処理日
          ,i_vst_rslts_dt_rec  => l_vst_rslts_dt_rec     -- 営業員別時間別訪問実績データ
          ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
          ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
          ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP get_vst_slsemp_data_loop2;
      -- カーソルクローズ
      CLOSE get_vst_rslts_data_cur;
      -- LOOP件数をカウントアップ
      ln_loop_cnt := ln_loop_cnt + 1;
--
    END LOOP get_vst_slsemp_data_loop1;
--
    -- 処理対象データが0件の場合
    IF gn_target_cnt = 0 THEN
      -- 0件メッセージ出力
      lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name         --アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_08    --メッセージコード
                );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_msg                                 --ユーザー・エラーメッセージ
      );
--
      ov_retcode := cv_status_normal;
    ELSE
      -- ========================================
      -- A-7.ワークテーブルデータ登録
      -- ========================================
      insert_row(
         id_visit_date       => ld_visit_date          -- 訪問年月日
        ,iv_employee_number  => iv_employee_number     -- 従業員コード
        ,iv_work_base_code   => lv_work_base_code      -- 拠点コード
        ,iv_hub_name         => lv_hub_name            -- 拠点名称
        ,iv_full_name        => lv_full_name           -- 漢字氏名
        ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
        ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
        ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-8.SVF起動
      -- ========================================
      act_svf(
         ov_errbuf     => lv_errbuf_svf                    -- エラー・メッセージ            --# 固定 #
        ,ov_retcode    => lv_retcode_svf                   -- リターン・コード              --# 固定 #
        ,ov_errmsg     => lv_errmsg_svf                    -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode_svf <> cv_status_error) THEN
        gn_normal_cnt := gn_total_count + gn_last_total_count;
      END IF;
--
      -- ========================================
      -- A-9.ワークテーブルデータ削除
      -- ========================================
      delete_row(
         ov_errbuf     => lv_errbuf                        -- エラー・メッセージ            --# 固定 #
        ,ov_retcode    => lv_retcode                       -- リターン・コード              --# 固定 #
        ,ov_errmsg     => lv_errmsg                        -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-10.SVF起動APIエラーチェック
      -- ========================================
      IF (lv_retcode_svf = cv_status_error) THEN
        lv_errmsg := lv_errmsg_svf;
        lv_errbuf := lv_errbuf_svf;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_vst_rslts_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_vst_rslts_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_vst_rslts_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_vst_rslts_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_vst_rslts_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_vst_rslts_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf             OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode            OUT NOCOPY VARCHAR2    --   リターン・コード    --# 固定 #
    ,iv_visit_date      IN  VARCHAR2           --   訪問日
    ,iv_employee_number IN  VARCHAR2           --   従業員コード
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
--
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--    cv_log_msg         CONSTANT VARCHAR2(100) := 'システムエラーが発生しました。システム管理者に確認してください。';
    /* 2009.05.20 M.Ohtsuki T1_0696対応 END */
    -- エラーメッセージ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_log             CONSTANT VARCHAR2(3)   := 'LOG';  -- コンカレントヘッダメッセージ出力 出力区分
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
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
       iv_visit_date       => iv_visit_date      -- 訪問日
      ,iv_employee_number  => iv_employee_number -- 従業員コード
      ,ov_errbuf           => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.LOG
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
         ,buff   => SUBSTRB(
                    cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf,1,5000
                    )
    /* 2009.05.20 M.Ohtsuki T1_0696対応 END */
       );
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--       fnd_file.put_line(
--          which  => FND_FILE.LOG
--         ,buff   => SUBSTRB(
--                      cv_log_msg ||cv_msg_prnthss_l||
--                      cv_pkg_name||cv_msg_cont||
--                      cv_prg_name||cv_msg_part||
--                      lv_errbuf  ||cv_msg_prnthss_r,1,5000
--                    )
--       );                                                     --エラーメッセージ
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
    END IF;
--
    -- =======================
    -- A-11.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO019A07C;
/
