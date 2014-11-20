CREATE OR REPLACE PACKAGE BODY XXCOS001A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A07C (body)
 * Description      : 入出庫一時表、納品ヘッダ・明細テーブルのデータの抽出を行う
 * MD.050           : VDコラム別取引データ抽出 (MD050_COS_001_A07)
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  inv_data_receive       入出庫データ抽出(A-1)
 *  inv_data_compute       入出庫データ導出(A-2)
 *  inv_data_register      入出庫データ登録(A-3)
 *  dlv_data_register      納品データ登録(A-4)
 *  data_update            コラム別転送済フラグ、販売実績連携済みフラグ更新(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   S.Miyakoshi      新規作成
 *  2009/02/16    1.1   S.Miyakoshi      [COS_062]カラム追加(VD_RESULTS_FORWARD_FLAG)
 *  2009/02/20    1.2   S.Miyakoshi      [COS_108]成績者をマスタより取得(入出庫データにおいて)
 *  2009/02/20    1.3   S.Miyakoshi      パラメータのログファイル出力対応
 *  2009/04/15    1.4   N.Maeda          [T1_0576]補充数ケース数に対する伝票区分別処理の追加
 *  2009/04/16    1.5   N.Maeda          [T1_0621]従業員絞込み条件の変更、出力ケース数の修正
 *  2009/04/17    1.6   T.Kitajima       [T1_0601]入出庫データ更新処理修正
 *  2009/04/22    1.7   T.Kitajima       [T1_0728]入力区分対応
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt,-20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- ロックエラー
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- クイックコード取得エラー
  lookup_types_expt EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCOS001A07C';           -- パッケージ名
--
  cv_application     CONSTANT VARCHAR2(5)   := 'XXCOS';                  -- アプリケーション名
--
  -- プロファイル
  -- XXCOS:MAX日付
  cv_prf_max_date    CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';
  -- GL会計帳簿ID
  cv_prf_bks_id      CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';
--
  -- エラーコード
  cv_msg_lock        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';       -- ロックエラー
  cv_msg_nodata      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';       -- 対象データ無しエラー
  cv_msg_pro         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';       -- プロファイル取得エラー
  cv_msg_add         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';       -- データ登録エラーメッセージ
  cv_msg_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';       -- データ更新エラーメッセージ
  cv_msg_get         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';       -- データ抽出エラーメッセージ
  cv_msg_max_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';       -- XXCOS:MAX日付
  cv_msg_lookup      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';       -- 参照コードマスタ
  cv_msg_target      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';       -- 対象件数メッセージ
  cv_msg_success     CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';       -- 成功件数メッセージ
  cv_msg_normal      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';       -- 正常終了メッセージ
  cv_msg_warn        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';       -- 警告終了メッセージ
  cv_msg_error       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';       -- エラー終了全ロールバックメッセージ
  cv_msg_parameter   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';       -- コンカレント入力パラメータなし
  cv_msg_tax_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10352';       -- 参照コードマスタ及びAR消費税マスタ
  cv_msg_inv_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10353';       -- 入出庫一時表
  cv_msg_vdh_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10354';       -- VDコラム別取引ヘッダテーブル
  cv_msg_vdl_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10355';       -- VDコラム別取引明細テーブル
  cv_msg_dlv_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10356';       -- 納品ヘッダテーブル及び納品明細テーブル
  cv_msg_dlv_h_table CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10357';       -- 納品ヘッダテーブル
  cv_msg_inv_cnt     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10358';       -- 入出庫情報抽出件数
  cv_msg_dlv_cnt     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10359';       -- 納品ヘッダ情報抽出件数
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10360';       -- 業務処理日取得エラー
  cv_msg_bks_id      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10361';       -- GL会計帳簿ID
  cv_msg_qck_error   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10362';       -- クイックコード取得エラーメッセージ
  cv_msg_invo_type   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10363';       -- 伝票区分
  cv_msg_dlv_cnt_l   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10364';       -- 納品明細情報抽出件数
  cv_msg_h_nor_cnt   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10365';       -- ヘッダ成功件数
  cv_msg_l_nor_cnt   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10366';       -- 明細成功件数
  cv_msg_input       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10043';       -- 入力区分
  -- トークン
  cv_tkn_table       CONSTANT VARCHAR2(20)  := 'TABLE_NAME';             -- テーブル名
  cv_tkn_tab         CONSTANT VARCHAR2(20)  := 'TABLE';                  -- テーブル名
  cv_tkn_colmun      CONSTANT VARCHAR2(20)  := 'COLMUN';                 -- 項目名
  cv_tkn_type        CONSTANT VARCHAR2(20)  := 'TYPE';                   -- クイックコードタイプ
  cv_tkn_key         CONSTANT VARCHAR2(20)  := 'KEY_DATA';               -- キーデータ
  cv_tkn_count       CONSTANT VARCHAR2(20)  := 'COUNT';                  -- 件数
  cv_tkn_profile     CONSTANT VARCHAR2(20)  := 'PROFILE';                -- プロファイル名
  cv_tkn_yes         CONSTANT VARCHAR2(1)   := 'Y';                      -- 判定:YES
  cv_tkn_no          CONSTANT VARCHAR2(1)   := 'N';                      -- 判定:NO
  cv_tkn_out         CONSTANT VARCHAR2(3)   := 'OUT';                    -- 出庫側
  cv_tkn_in          CONSTANT VARCHAR2(2)   := 'IN';                     -- 入庫側
  cv_default         CONSTANT VARCHAR2(1)   := '0';                      -- 初期値
  cv_one             CONSTANT VARCHAR2(1)   := '1';                      -- 判定:1
  cv_input_class     CONSTANT VARCHAR2(1)   := '5';                      -- テーブル・ロック条件
  cv_tkn_down        CONSTANT VARCHAR2(20)  := 'DOWN';                   -- 切捨て
  cv_tkn_up          CONSTANT VARCHAR2(20)  := 'UP';                     -- 切上げ
  cv_tkn_nearest     CONSTANT VARCHAR2(20)  := 'NEAREST';                -- 四捨五入
  cv_tkn_bill_to     CONSTANT VARCHAR2(20)  := 'BILL_TO';                -- BILL_TO
--
  -- クイックコードタイプ
  cv_qck_typ_tax     CONSTANT VARCHAR2(30)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';    -- 消費税区分
  cv_qck_invo_type   CONSTANT VARCHAR2(30)  := 'XXCOS1_INVOICE_TYPE';             -- 伝票区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
  cv_qck_input_type  CONSTANT VARCHAR2(30)  := 'XXCOS1_VD_COL_INPUT_CLASS';       -- 入力区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
--
  --フォーマット
  cv_fmt_date        CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                      -- DATE形式
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 消費税率格納用変数
  TYPE g_rec_tax_rate IS RECORD
    (
      rate                ar_vat_tax_all_b.tax_rate%TYPE,                     -- 消費税率
      code                ar_vat_tax_all_b.tax_code%TYPE,                     -- 消費税コード
      tax_class           fnd_lookup_values.attribute3%TYPE                   -- 消費税区分
    );
  TYPE g_tab_tax_rate IS TABLE OF g_rec_tax_rate INDEX BY PLS_INTEGER;
--
  -- 伝票区分格納用変数
  TYPE g_rec_qck_invoice_type IS RECORD
    (
      invoice_type        xxcoi_hht_inv_transactions.invoice_type%TYPE,       -- 伝票区分
      form                VARCHAR(3),                                         -- 伝票区分による形態
      change              VARCHAR(1)                                          -- 数量加工判定
    );
  TYPE g_tab_qck_invoice_type IS TABLE OF g_rec_qck_invoice_type INDEX BY PLS_INTEGER;
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
  -- 入力区分格納用変数
  TYPE g_rec_qck_input_type IS RECORD
    (
      slip_class          VARCHAR(1),                                         -- 伝票区分
      input_class         VARCHAR(1)                                          -- 入力区分
    );
  TYPE g_tab_qck_input_type IS TABLE OF g_rec_qck_input_type INDEX BY PLS_INTEGER;
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--
  -- 入出庫一時表データ格納用変数
  TYPE g_rec_inv_data IS RECORD
    (
      base_code           xxcoi_hht_inv_transactions.base_code%TYPE,                  -- 拠点コード
      employee_num        xxcoi_hht_inv_transactions.employee_num%TYPE,               -- 営業員コード
      invoice_no          xxcoi_hht_inv_transactions.invoice_no%TYPE,                 -- 伝票No.
      item_code           xxcoi_hht_inv_transactions.item_code%TYPE,                  -- 品目コード（品名コード）
      case_quant          xxcoi_hht_inv_transactions.case_quantity%TYPE,              -- ケース数
      case_in_quant       xxcoi_hht_inv_transactions.case_in_quantity%TYPE,           -- 入数
      quantity            xxcoi_hht_inv_transactions.quantity%TYPE,                   -- 本数
      invoice_type        xxcoi_hht_inv_transactions.invoice_type%TYPE,               -- 伝票区分
      outside_code        xxcoi_hht_inv_transactions.outside_code%TYPE,               -- 出庫側コード
      inside_code         xxcoi_hht_inv_transactions.inside_code%TYPE,                -- 入庫側コード
      invoice_date        xxcoi_hht_inv_transactions.invoice_date%TYPE,               -- 伝票日付
      column_no           xxcoi_hht_inv_transactions.column_no%TYPE,                  -- コラムNo.
      unit_price          xxcoi_hht_inv_transactions.unit_price%TYPE,                 -- 単価
      hot_cold_div        xxcoi_hht_inv_transactions.hot_cold_div%TYPE,               -- H/C
      total_quantity      xxcoi_hht_inv_transactions.total_quantity%TYPE,             -- 総本数
      item_id             xxcoi_hht_inv_transactions.inventory_item_id%TYPE,          -- 品目ID
      primary_code        xxcoi_hht_inv_transactions.primary_uom_code%TYPE,           -- 基準単位
      out_bus_low_type    xxcoi_hht_inv_transactions.outside_business_low_type%TYPE,  -- 出庫側業態区分
      in_bus_low_type     xxcoi_hht_inv_transactions.inside_business_low_type%TYPE,   -- 入庫側業態区分
      out_cus_code        xxcoi_hht_inv_transactions.outside_cust_code%TYPE,          -- 出庫側顧客コード
      in_cus_code         xxcoi_hht_inv_transactions.inside_cust_code%TYPE,           -- 入庫側顧客コード
      tax_div             xxcmm_cust_accounts.tax_div%TYPE,                           -- 消費税区分
      tax_round_rule      hz_cust_site_uses_all.tax_rounding_rule%TYPE,               -- 税金－端数処理
      inv_price           xxcoi_mst_vd_column.price%TYPE,                             -- 単価：VDコラムマスタより
--****************************** 2009/04/17 1.6 T.Kitajima MOD START ******************************--
--      perform_code        xxcos_vd_column_headers.performance_by_code%TYPE            -- 成績者コード
      perform_code        xxcos_vd_column_headers.performance_by_code%TYPE,           -- 成績者コード
      transaction_id      xxcoi_hht_inv_transactions.transaction_id%TYPE              -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima MOD START ******************************--
    );
  TYPE g_tab_inv_data IS TABLE OF g_rec_inv_data INDEX BY PLS_INTEGER;
--
  -- VDコラム別取引ヘッダテーブル登録用変数
  TYPE g_tab_order_noh_hht         IS TABLE OF xxcos_vd_column_headers.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.(HHT)
  TYPE g_tab_base_code             IS TABLE OF xxcos_vd_column_headers.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- 拠点コード
  TYPE g_tab_performance_by_code   IS TABLE OF xxcos_vd_column_headers.performance_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- 成績者コード
  TYPE g_tab_dlv_by_code           IS TABLE OF xxcos_vd_column_headers.dlv_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- 納品者コード
  TYPE g_tab_hht_invoice_no        IS TABLE OF xxcos_vd_column_headers.hht_invoice_no%TYPE
    INDEX BY PLS_INTEGER;   -- HHT伝票No.
  TYPE g_tab_dlv_date              IS TABLE OF xxcos_vd_column_headers.dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- 納品日
  TYPE g_tab_inspect_date          IS TABLE OF xxcos_vd_column_headers.inspect_date%TYPE
    INDEX BY PLS_INTEGER;   -- 検収日
  TYPE g_tab_customer_number       IS TABLE OF xxcos_vd_column_headers.customer_number%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客コード
  TYPE g_tab_system_class          IS TABLE OF xxcos_vd_column_headers.system_class%TYPE
    INDEX BY PLS_INTEGER;   -- 業態区分
  TYPE g_tab_invoice_type          IS TABLE OF xxcos_vd_column_headers.invoice_type%TYPE
    INDEX BY PLS_INTEGER;   -- 伝票区分
  TYPE g_tab_consumption_tax_class IS TABLE OF xxcos_vd_column_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;   -- 消費税区分
  TYPE g_tab_total_amount          IS TABLE OF xxcos_vd_column_headers.total_amount%TYPE
    INDEX BY PLS_INTEGER;   -- 合計金額
  TYPE g_tab_sales_consumption_tax IS TABLE OF xxcos_vd_column_headers.sales_consumption_tax%TYPE
    INDEX BY PLS_INTEGER;   -- 売上消費税額
  TYPE g_tab_tax_include           IS TABLE OF xxcos_vd_column_headers.tax_include%TYPE
    INDEX BY PLS_INTEGER;   -- 税込金額
  TYPE g_tab_red_black_flag        IS TABLE OF xxcos_vd_column_headers.red_black_flag%TYPE
    INDEX BY PLS_INTEGER;   -- 赤黒フラグ
  TYPE g_tab_cancel_correct_class  IS TABLE OF xxcos_vd_column_headers.cancel_correct_class%TYPE
    INDEX BY PLS_INTEGER;   -- 取消・訂正区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
  TYPE g_tab_gt_input_class        IS TABLE OF xxcos_vd_column_headers.input_class%TYPE
    INDEX BY PLS_INTEGER;   -- 入力区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--
  -- VDコラム別取引明細テーブル登録用変数
  TYPE g_tab_order_nol_hht         IS TABLE OF xxcos_vd_column_lines.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.(HHT)
  TYPE g_tab_line_no_hht           IS TABLE OF xxcos_vd_column_lines.line_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- 行No.(HHT)
  TYPE g_tab_item_code_self        IS TABLE OF xxcos_vd_column_lines.item_code_self%TYPE
    INDEX BY PLS_INTEGER;   -- 品名コード(自社)
  TYPE g_tab_content               IS TABLE OF xxcos_vd_column_lines.content%TYPE
    INDEX BY PLS_INTEGER;   -- 入数
  TYPE g_tab_inventory_item_id     IS TABLE OF xxcos_vd_column_lines.inventory_item_id%TYPE
    INDEX BY PLS_INTEGER;   -- 品目ID
  TYPE g_tab_standard_unit         IS TABLE OF xxcos_vd_column_lines.standard_unit%TYPE
    INDEX BY PLS_INTEGER;   -- 基準単位
  TYPE g_tab_case_number           IS TABLE OF xxcos_vd_column_lines.case_number%TYPE
    INDEX BY PLS_INTEGER;   -- ケース数
  TYPE g_tab_quantity              IS TABLE OF xxcos_vd_column_lines.quantity%TYPE
    INDEX BY PLS_INTEGER;   -- 数量
  TYPE g_tab_wholesale_unit_ploce  IS TABLE OF xxcos_vd_column_lines.wholesale_unit_ploce%TYPE
    INDEX BY PLS_INTEGER;   -- 卸単価
  TYPE g_tab_column_no             IS TABLE OF xxcos_vd_column_lines.column_no%TYPE
    INDEX BY PLS_INTEGER;   -- コラムNo.
  TYPE g_tab_h_and_c               IS TABLE OF xxcos_vd_column_lines.h_and_c%TYPE
    INDEX BY PLS_INTEGER;   -- H/C
  TYPE g_tab_replenish_number      IS TABLE OF xxcos_vd_column_lines.replenish_number%TYPE
    INDEX BY PLS_INTEGER;   -- 補充数
--
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
  TYPE g_tab_transaction_id        IS TABLE OF xxcoi_hht_inv_transactions.transaction_id%TYPE
    INDEX BY PLS_INTEGER;   -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- VDコラム別取引ヘッダテーブル登録データ
  gt_order_noh_hht      g_tab_order_noh_hht;            -- 受注No.(HHT)
  gt_base_code          g_tab_base_code;                -- 拠点コード
  gt_perform_code       g_tab_performance_by_code;      -- 成績者コード
  gt_dlv_code           g_tab_dlv_by_code;              -- 納品者コード
  gt_invoice_no         g_tab_hht_invoice_no;           -- HHT伝票No.
  gt_dlv_date           g_tab_dlv_date;                 -- 納品日
  gt_inspect_date       g_tab_inspect_date;             -- 検収日
  gt_cus_number         g_tab_customer_number;          -- 顧客コード
  gt_system_class       g_tab_system_class;             -- 業態区分
  gt_invoice_type       g_tab_invoice_type;             -- 伝票区分
  gt_tax_class          g_tab_consumption_tax_class;    -- 消費税区分
  gt_total_amount       g_tab_total_amount;             -- 合計金額
  gt_sales_tax          g_tab_sales_consumption_tax;    -- 売上消費税額
  gt_tax_include        g_tab_tax_include;              -- 税込金額
  gt_red_black_flag     g_tab_red_black_flag;           -- 赤黒フラグ
  gt_cancel_correct     g_tab_cancel_correct_class;     -- 取消・訂正区分
--
  -- VDコラム別取引明細テーブル登録データ
  gt_order_nol_hht      g_tab_order_nol_hht;            -- 受注No.(HHT)
  gt_line_no_hht        g_tab_line_no_hht;              -- 行No.(HHT)
  gt_item_code_self     g_tab_item_code_self;           -- 品名コード(自社)
  gt_content            g_tab_content;                  -- 入数
  gt_item_id            g_tab_inventory_item_id;        -- 品目ID
  gt_standard_unit      g_tab_standard_unit;            -- 基準単位
  gt_case_number        g_tab_case_number;              -- ケース数
  gt_quantity           g_tab_quantity;                 -- 数量
  gt_wholesale          g_tab_wholesale_unit_ploce;     -- 卸単価
  gt_column_no          g_tab_column_no;                -- コラムNo.
  gt_h_and_c            g_tab_h_and_c;                  -- H/C
  gt_replenish_num      g_tab_replenish_number;         -- 補充数
--
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
  gt_transaction_id     g_tab_transaction_id;           --  入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
  gt_input_class        g_tab_gt_input_class;           --  入力区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--
  gn_inv_target_cnt     NUMBER;                         -- 入出庫情報抽出件数
  gn_dlv_h_target_cnt   NUMBER;                         -- 納品ヘッダ情報抽出件数
  gn_dlv_l_target_cnt   NUMBER;                         -- 納品明細情報抽出件数
  gn_h_normal_cnt       NUMBER;                         -- 入出庫ヘッダ情報成功件数
  gn_l_normal_cnt       NUMBER;                         -- 入出庫明細情報成功件数
  gn_dlv_h_nor_cnt      NUMBER;                         -- 納品ヘッダ情報成功件数
  gn_dlv_l_nor_cnt      NUMBER;                         -- 納品明細情報成功件数
  gt_tax_rate           g_tab_tax_rate;                 -- 消費税率
  gt_qck_invoice_type   g_tab_qck_invoice_type;         -- 伝票区分
  gt_qck_input_type     g_tab_qck_input_type;           -- 入力区分
  gt_inv_data           g_tab_inv_data;                 -- 入出庫一時表抽出データ
  gd_process_date       DATE;                           -- 業務処理日
  gd_max_date           DATE;                           -- MAX日付
  gv_bks_id             VARCHAR2(50);                   -- GL会計帳簿ID
  gv_tkn1               VARCHAR2(50);                   -- エラーメッセージ用トークン１
  gv_tkn2               VARCHAR2(50);                   -- エラーメッセージ用トークン２
  gv_tkn3               VARCHAR2(50);                   -- エラーメッセージ用トークン３
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
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
    cv_application_ccp CONSTANT VARCHAR2(5)   := 'XXCCP';                  -- アプリケーション名
--
    -- *** ローカル変数 ***
    ld_process_date  DATE;              -- 業務処理日
    lv_max_date      VARCHAR2(50);      -- MAX日付
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    --==============================================================
    --「コンカレント入力パラメータなし」メッセージをログ出力
    --==============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    -- メッセージログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- 共通関数＜業務処理日取得＞の呼び出し
    --==============================================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日取得エラーの場合
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_process_date := TRUNC( ld_process_date );
    END IF;
--
    --==================================
    -- プロファイルの取得(XXCOS:MAX日付)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- プロファイル取得エラーの場合
    IF ( lv_max_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
    END IF;
--
    --==================================
    -- プロファイルの取得(GL会計帳簿ID)
    --==================================
    gv_bks_id := FND_PROFILE.VALUE( cv_prf_bks_id );
--
    -- プロファイル取得エラーの場合
    IF ( gv_bks_id IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_bks_id );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : inv_data_receive
   * Description      : 入出庫データ抽出(A-1)
   ***********************************************************************************/
  PROCEDURE inv_data_receive(
    on_target_cnt OUT NUMBER,       --   抽出件数
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inv_data_receive'; -- プログラム名
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
    -- 消費税率 and クイックコード：消費税コード、消費税区分
    CURSOR get_tax_rate_cur( gl_id VARCHAR2 )
    IS
      SELECT tax.tax_rate  tax_rate,  -- 消費税率
             tax.tax_code  tax_code,  -- 消費税コード
             qck.cla       cla        -- 消費税区分
      FROM   ar_vat_tax_all_b tax,    -- 税コードマスタ
             (
               SELECT look_val.attribute2   code,   -- 消費税コード
                      look_val.attribute3   cla     -- 消費税区分
               FROM   fnd_lookup_values     look_val,
                      fnd_lookup_types_tl   types_tl,
                      fnd_lookup_types      types,
                      fnd_application_tl    appl,
                      fnd_application       app
               WHERE  app.application_short_name = cv_application       -- XXCOS
               AND    look_val.lookup_type       = cv_qck_typ_tax       -- タイプ＝XXCOS1_CONSUMPTION_TAX_CLASS
               AND    look_val.enabled_flag      = cv_tkn_yes           -- 使用可能＝Y
               AND    gd_process_date           >= NVL(look_val.start_date_active, gd_process_date)
               AND    gd_process_date           <= NVL(look_val.end_date_active, gd_max_date)
               AND    types_tl.language          = USERENV( 'LANG' )    -- 言語＝JA
               AND    look_val.language          = USERENV( 'LANG' )    -- 言語＝JA
               AND    appl.language              = USERENV( 'LANG' )    -- 言語＝JA
               AND    appl.application_id        = types.application_id
               AND    app.application_id         = appl.application_id
               AND    types_tl.lookup_type       = look_val.lookup_type
               AND    types.lookup_type          = types_tl.lookup_type
               AND    types.security_group_id    = types_tl.security_group_id
               AND    types.view_application_id  = types_tl.view_application_id
               ORDER BY look_val.attribute3
             ) qck
      WHERE  tax.tax_code        = qck.code
      AND    tax.set_of_books_id = gl_id                -- GL会計帳簿ID
      AND    tax.enabled_flag    = cv_tkn_yes           -- 使用可能＝Y
      AND    gd_process_date    >= NVL(tax.start_date, gd_process_date)
      AND    gd_process_date    <= NVL(tax.end_date, gd_max_date)
      ;
--
    -- クイックコード：伝票区分
    CURSOR get_invoice_type_cur
    IS
      SELECT  look_val.lookup_code  lookup_code,  -- 伝票区分
              look_val.attribute1   form,         -- 伝票区分による形態
              look_val.attribute2   judge         -- 数量加工判定
      FROM    fnd_lookup_values     look_val
             ,fnd_lookup_types_tl   types_tl
             ,fnd_lookup_types      types
             ,fnd_application_tl    appl
             ,fnd_application       app
      WHERE   app.application_short_name = cv_application
      AND     look_val.lookup_type  = cv_qck_invo_type
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     types_tl.language     = USERENV( 'LANG' )
      AND     look_val.language     = USERENV( 'LANG' )
      AND     appl.language         = USERENV( 'LANG' )
      AND     appl.application_id   = types.application_id
      AND     app.application_id    = appl.application_id
      AND     types_tl.lookup_type  = look_val.lookup_type
      AND     types.lookup_type     = types_tl.lookup_type
      AND     types.security_group_id   = types_tl.security_group_id
      AND     types.view_application_id = types_tl.view_application_id;
--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
    -- クイックコード：入力区分
    CURSOR get_input_type_cur
    IS
      SELECT  look_val.meaning      slip_class,         -- 伝票区分
              look_val.attribute1   input_class         -- 伝票区分による形態
      FROM    fnd_lookup_values     look_val
             ,fnd_lookup_types_tl   types_tl
             ,fnd_lookup_types      types
             ,fnd_application_tl    appl
             ,fnd_application       app
      WHERE   app.application_short_name = cv_application
      AND     look_val.lookup_type  = cv_qck_input_type
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     types_tl.language     = USERENV( 'LANG' )
      AND     look_val.language     = USERENV( 'LANG' )
      AND     appl.language         = USERENV( 'LANG' )
      AND     appl.application_id   = types.application_id
      AND     app.application_id    = appl.application_id
      AND     types_tl.lookup_type  = look_val.lookup_type
      AND     types.lookup_type     = types_tl.lookup_type
      AND     types.security_group_id   = types_tl.security_group_id
      AND     types.view_application_id = types_tl.view_application_id;
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--
    -- 入出庫一時表対象レコードロック
    CURSOR get_inv_lock_cur
    IS
      SELECT  inv.last_updated_by         last_up  -- 最終更新者
      FROM    xxcoi_hht_inv_transactions  inv      -- 入出庫一時表
      WHERE   inv.invoice_type IN (
                                    SELECT  look_val.lookup_code  code
                                    FROM    fnd_lookup_values     look_val
                                           ,fnd_lookup_types_tl   types_tl
                                           ,fnd_lookup_types      types
                                           ,fnd_application_tl    appl
                                           ,fnd_application       app
                                    WHERE   app.application_short_name = cv_application
                                    AND     look_val.lookup_type  = cv_qck_invo_type
                                    AND     look_val.enabled_flag = cv_tkn_yes
                                    AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                                    AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                                    AND     types_tl.language     = USERENV( 'LANG' )
                                    AND     look_val.language     = USERENV( 'LANG' )
                                    AND     appl.language         = USERENV( 'LANG' )
                                    AND     appl.application_id   = types.application_id
                                    AND     app.application_id    = appl.application_id
                                    AND     types_tl.lookup_type  = look_val.lookup_type
                                    AND     types.lookup_type     = types_tl.lookup_type
                                    AND     types.security_group_id   = types_tl.security_group_id
                                    AND     types.view_application_id = types_tl.view_application_id
                                  )                               -- 伝票区分＝4,5,6,7
      AND    inv.column_if_flag = cv_tkn_no                       -- コラム別転送フラグ＝N
      AND    inv.status         = cv_one                          -- 処理ステータス＝1
      FOR UPDATE NOWAIT;
--
    -- 入出庫一時表データ抽出
    CURSOR get_inv_data_cur
    IS
      SELECT
         base_code                 base_code             -- 拠点コード
        ,employee_num              employee_num          -- 営業員コード
        ,invoice_no                invoice_no            -- 伝票No.
        ,item_code                 item_code             -- 品目コード（品名コード）
        ,case_quantity             case_quantity         -- ケース数
        ,case_in_quantity          case_in_quantity      -- 入数
        ,quantity                  quantity              -- 本数
        ,invoice_type              invoice_type          -- 伝票区分
        ,outside_code              outside_code          -- 出庫側コード
        ,inside_code               inside_code           -- 入庫側コード
        ,invoice_date              invoice_date          -- 伝票日付
        ,column_no                 column_no             -- コラムNo.
        ,unit_price                unit_price            -- 単価
        ,hot_cold_div              hot_cold_div          -- H/C
        ,total_quantity            total_quantity        -- 総本数
        ,inventory_item_id         inventory_item_id     -- 品目ID
        ,primary_uom_code          primary_uom_code      -- 基準単位
        ,outside_business_low_type out_busi_low_type     -- 出庫側業態区分
        ,inside_business_low_type  in_busi_low_type      -- 入庫側業態区分
        ,outside_cust_code         outside_cust_code     -- 出庫側顧客コード
        ,inside_cust_code          inside_cust_code      -- 入庫側顧客コード
        ,tax_div                   tax_div               -- 消費税区分
        ,tax_rounding_rule         tax_rounding_rule     -- 税金－端数処理
        ,price                     price                 -- 単価
        ,perform_code              perform_code          -- 成績者コード
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
        ,transaction_id            transaction_id        -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
      FROM
        (
          SELECT inv.base_code                 base_code                    -- 拠点コード
                ,inv.employee_num              employee_num                 -- 営業員コード
                ,inv.invoice_no                invoice_no                   -- 伝票No.
                ,inv.item_code                 item_code                    -- 品目コード（品名コード）
                ,inv.case_quantity             case_quantity                -- ケース数
                ,inv.case_in_quantity          case_in_quantity             -- 入数
                ,inv.quantity                  quantity                     -- 本数
                ,inv.invoice_type              invoice_type                 -- 伝票区分
                ,inv.outside_code              outside_code                 -- 出庫側コード
                ,inv.inside_code               inside_code                  -- 入庫側コード
                ,inv.invoice_date              invoice_date                 -- 伝票日付
                ,inv.column_no                 column_no                    -- コラムNo.
                ,inv.unit_price                unit_price                   -- 単価
                ,inv.hot_cold_div              hot_cold_div                 -- H/C
                ,inv.total_quantity            total_quantity               -- 総本数
                ,inv.inventory_item_id         inventory_item_id            -- 品目ID
                ,inv.primary_uom_code          primary_uom_code             -- 基準単位
                ,inv.outside_business_low_type outside_business_low_type    -- 出庫側業態区分
                ,inv.inside_business_low_type  inside_business_low_type     -- 入庫側業態区分
                ,inv.outside_cust_code         outside_cust_code            -- 出庫側顧客コード
                ,inv.inside_cust_code          inside_cust_code             -- 入庫側顧客コード
                ,cust.tax_div                  tax_div                      -- 消費税区分
                ,site.tax_rounding_rule        tax_rounding_rule            -- 税金－端数処理
                ,vd.price                      price                        -- 単価
                ,xsv.employee_number           perform_code                 -- 成績者コード
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
                ,inv.transaction_id            transaction_id               -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
          FROM   xxcoi_hht_inv_transactions    inv     -- 入出庫一時表
                ,hz_cust_accounts              hz_cus  -- アカウント
                ,xxcmm_cust_accounts           cust    -- 顧客追加情報
                ,hz_cust_acct_sites_all        acct    -- 顧客所在地
                ,hz_cust_site_uses_all         site    -- 顧客使用目的
                ,xxcoi_mst_vd_column           vd      -- VDコラムマスタ
                ,xxcos_salesreps_v             xsv     -- 担当営業員view
                ,(
                   SELECT  look_val.lookup_code  code
                   FROM    fnd_lookup_values     look_val
                          ,fnd_lookup_types_tl   types_tl
                          ,fnd_lookup_types      types
                          ,fnd_application_tl    appl
                          ,fnd_application       app
                   WHERE   app.application_short_name = cv_application
                   AND     look_val.lookup_type  = cv_qck_invo_type
                   AND     look_val.enabled_flag = cv_tkn_yes
                   AND     look_val.attribute1   = cv_tkn_out
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     types_tl.language     = USERENV( 'LANG' )
                   AND     look_val.language     = USERENV( 'LANG' )
                   AND     appl.language         = USERENV( 'LANG' )
                   AND     appl.application_id   = types.application_id
                   AND     app.application_id    = appl.application_id
                   AND     types_tl.lookup_type  = look_val.lookup_type
                   AND     types.lookup_type     = types_tl.lookup_type
                   AND     types.security_group_id   = types_tl.security_group_id
                   AND     types.view_application_id = types_tl.view_application_id
                 ) qck_invo    -- クイックコード：出庫側伝票区分
          WHERE  inv.invoice_type       = qck_invo.code           -- 伝票区分＝出庫側
          AND    inv.column_if_flag     = cv_tkn_no               -- コラム別転送フラグ＝N
          AND    inv.status             = cv_one                  -- 処理ステータス＝1
          AND    inv.outside_cust_code  = hz_cus.account_number   -- 入出庫一時表.出庫側顧客コード＝アカウント.顧客
          AND    hz_cus.cust_account_id = cust.customer_id        -- アカウント.顧客ID＝顧客追加情報.顧客ID
          AND    inv.column_no          = vd.column_no            -- 入出庫一時表.コラムNo.＝VDコラムマスタ.コラムNo.
          AND    vd.customer_id         = cust.customer_id        -- VDコラムマスタ.顧客ID＝顧客追加情報.顧客ID
          AND    cust.customer_id       = acct.cust_account_id    -- 顧客追加情報.顧客サイトID＝顧客所在地.顧客サイトID
          AND    acct.cust_acct_site_id = site.cust_acct_site_id  -- 顧客所在地.顧客サイトID＝顧客使用目的.顧客サイトID
          AND    site.site_use_code     = cv_tkn_bill_to          -- 顧客使用目的.使用目的＝BILL_TO
--************************* 2009/04/16 N.Maeda Var1.5 MOD START ****************************************************
--          AND    (
--                    xsv.account_number = inv.outside_cust_code    -- 担当営業員view.顧客番号＝入出庫一時表.出庫側顧客
--                  AND                                             -- 日付の適用範囲
--                    inv.invoice_date >= NVL(xsv.effective_start_date, gd_process_date)
--                  AND
--                    inv.invoice_date <= NVL(xsv.effective_end_date, gd_max_date)
--                 )
          AND    (
                    xsv.account_number = inv.outside_cust_code    -- 担当営業員view.顧客番号＝入出庫一時表.出庫側顧客
                  AND                                             -- 日付の適用範囲
                    inv.invoice_date >= NVL(xsv.effective_start_date, inv.invoice_date)
                  AND
                    inv.invoice_date <= NVL(xsv.effective_end_date, gd_max_date)
                 )
--************************* 2009/04/16 N.Maeda Var1.5 MOD END ******************************************************
          ORDER BY  inv.base_code              -- 拠点コード
                   ,inv.outside_cust_code      -- 出庫側顧客コード
                   ,inv.invoice_no             -- 伝票No.
                   ,inv.column_no              -- コラムNo.
        )
--
      UNION ALL
--
      SELECT
         base_code                 base_code                      -- 拠点コード
        ,employee_num              employee_num                   -- 営業員コード
        ,invoice_no                invoice_no                     -- 伝票No.
        ,item_code                 item_code                      -- 品目コード（品名コード）
        ,case_quantity             case_quantity                  -- ケース数
        ,case_in_quantity          case_in_quantity               -- 入数
        ,quantity                  quantity                       -- 本数
        ,invoice_type              invoice_type                   -- 伝票区分
        ,outside_code              outside_code                   -- 出庫側コード
        ,inside_code               inside_code                    -- 入庫側コード
        ,invoice_date              invoice_date                   -- 伝票日付
        ,column_no                 column_no                      -- コラムNo.
        ,unit_price                unit_price                     -- 単価
        ,hot_cold_div              hot_cold_div                   -- H/C
        ,total_quantity            total_quantity                 -- 総本数
        ,inventory_item_id         inventory_item_id              -- 品目ID
        ,primary_uom_code          primary_uom_code               -- 基準単位
        ,outside_business_low_type out_busi_low_type              -- 出庫側業態区分
        ,inside_business_low_type  in_busi_low_type               -- 入庫側業態区分
        ,outside_cust_code         outside_cust_code              -- 出庫側顧客コード
        ,inside_cust_code          inside_cust_code               -- 入庫側顧客コード
        ,tax_div                   tax_div                        -- 消費税区分
        ,tax_rounding_rule         tax_rounding_rule              -- 税金－端数処理
        ,price                     price                          -- 単価
        ,perform_code              perform_code                   -- 成績者コード
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
        ,transaction_id            transaction_id                 -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
      FROM
        (
          SELECT inv.base_code                 base_code                    -- 拠点コード
                ,inv.employee_num              employee_num                 -- 営業員コード
                ,inv.invoice_no                invoice_no                   -- 伝票No.
                ,inv.item_code                 item_code                    -- 品目コード（品名コード
                ,inv.case_quantity             case_quantity                -- ケース数
                ,inv.case_in_quantity          case_in_quantity             -- 入数
                ,inv.quantity                  quantity                     -- 本数
                ,inv.invoice_type              invoice_type                 -- 伝票区分
                ,inv.outside_code              outside_code                 -- 出庫側コード
                ,inv.inside_code               inside_code                  -- 入庫側コード
                ,inv.invoice_date              invoice_date                 -- 伝票日付
                ,inv.column_no                 column_no                    -- コラムNo.
                ,inv.unit_price                unit_price                   -- 単価
                ,inv.hot_cold_div              hot_cold_div                 -- H/C
                ,inv.total_quantity            total_quantity               -- 総本数
                ,inv.inventory_item_id         inventory_item_id            -- 品目ID
                ,inv.primary_uom_code          primary_uom_code             -- 基準単位
                ,inv.outside_business_low_type outside_business_low_type    -- 出庫側業態区分
                ,inv.inside_business_low_type  inside_business_low_type     -- 入庫側業態区分
                ,inv.outside_cust_code         outside_cust_code            -- 出庫側顧客コード
                ,inv.inside_cust_code          inside_cust_code             -- 入庫側顧客コード
                ,cust.tax_div                  tax_div                      -- 消費税区分
                ,site.tax_rounding_rule        tax_rounding_rule            -- 税金－端数処理
                ,vd.price                      price                        -- 単価
                ,xsv.employee_number           perform_code                 -- 成績者コード
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
                ,inv.transaction_id            transaction_id               -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
          FROM   xxcoi_hht_inv_transactions    inv     -- 入出庫一時表
                ,hz_cust_accounts              hz_cus  -- アカウント
                ,xxcmm_cust_accounts           cust    -- 顧客追加情報
                ,hz_cust_acct_sites_all        acct    -- 顧客所在地
                ,hz_cust_site_uses_all         site    -- 顧客使用目的
                ,xxcoi_mst_vd_column           vd      -- VDコラムマスタ
                ,xxcos_salesreps_v             xsv     -- 担当営業員view
                ,(
                   SELECT  look_val.lookup_code  code
                   FROM    fnd_lookup_values     look_val
                          ,fnd_lookup_types_tl   types_tl
                          ,fnd_lookup_types      types
                          ,fnd_application_tl    appl
                          ,fnd_application       app
                   WHERE   app.application_short_name = cv_application
                   AND     look_val.lookup_type  = cv_qck_invo_type
                   AND     look_val.enabled_flag = cv_tkn_yes
                   AND     look_val.attribute1   = cv_tkn_in
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     types_tl.language     = USERENV( 'LANG' )
                   AND     look_val.language     = USERENV( 'LANG' )
                   AND     appl.language         = USERENV( 'LANG' )
                   AND     appl.application_id   = types.application_id
                   AND     app.application_id    = appl.application_id
                   AND     types_tl.lookup_type  = look_val.lookup_type
                   AND     types.lookup_type     = types_tl.lookup_type
                   AND     types.security_group_id   = types_tl.security_group_id
                   AND     types.view_application_id = types_tl.view_application_id
                 ) qck_invo    -- クイックコード：入庫側伝票区分
          WHERE  inv.invoice_type       = qck_invo.code           -- 伝票区分＝入庫側
          AND    inv.column_if_flag     = cv_tkn_no               -- コラム別転送フラグ＝N
          AND    inv.status             = cv_one                  -- 処理ステータス＝1
          AND    inv.inside_cust_code   = hz_cus.account_number   -- 入出庫一時表.入庫側顧客コード＝アカウント.顧客
          AND    hz_cus.cust_account_id = cust.customer_id        -- アカウント.顧客ID＝顧客追加情報.顧客ID
          AND    inv.column_no          = vd.column_no            -- 入出庫一時表.コラムNo.＝VDコラムマスタ.コラムNo.
          AND    vd.customer_id         = cust.customer_id        -- VDコラムマスタ.顧客ID＝顧客追加情報.顧客ID
          AND    cust.customer_id       = acct.cust_account_id    -- 顧客追加情報.顧客サイトID＝顧客所在地.顧客サイトID
          AND    acct.cust_acct_site_id = site.cust_acct_site_id  -- 顧客所在地.顧客サイトID＝顧客使用目的.顧客サイトID
          AND    site.site_use_code     = cv_tkn_bill_to          -- 顧客使用目的.使用目的＝BILL_TO
--************************* 2009/04/16 N.Maeda Var1.5 MOD START ****************************************************
--          AND    (
--                    xsv.account_number = inv.inside_cust_code     -- 担当営業員view.顧客番号＝入出庫一時表.入庫側顧客
--                  AND                                             -- 日付の適用範囲
--                    inv.invoice_date >= NVL(xsv.effective_start_date, gd_process_date)
--                  AND
--                    inv.invoice_date <= NVL(xsv.effective_end_date, gd_max_date)
--                 )
          AND    (
                    xsv.account_number = inv.inside_cust_code     -- 担当営業員view.顧客番号＝入出庫一時表.入庫側顧客
                  AND                                             -- 日付の適用範囲
                    inv.invoice_date >= NVL(xsv.effective_start_date, inv.invoice_date)
                  AND
                    inv.invoice_date <= NVL(xsv.effective_end_date, gd_max_date)
                 )
--************************* 2009/04/16 N.Maeda Var1.5 MOD END ******************************************************
          ORDER BY  inv.base_code              -- 拠点コード
                   ,inv.inside_cust_code       -- 入庫側顧客コード
                   ,inv.invoice_no             -- 伝票No.
                   ,inv.column_no              -- コラムNo.
        )
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
    -- 抽出件数初期化
    on_target_cnt := 0;
--
    --==============================================================
    -- 入出庫一時表対象レコードロック
    --==============================================================
    OPEN  get_inv_lock_cur;
    CLOSE get_inv_lock_cur;
--
    --==============================================================
    -- データの取得
    --==============================================================
    -- 消費税率取得
    BEGIN
      -- カーソルOPEN
      OPEN  get_tax_rate_cur( gv_bks_id );
      -- バルクフェッチ
      FETCH get_tax_rate_cur BULK COLLECT INTO gt_tax_rate;
      -- カーソルCLOSE
      CLOSE get_tax_rate_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tax_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_get,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
--
        IF ( get_tax_rate_cur%ISOPEN ) THEN
          CLOSE get_tax_rate_cur;
        END IF;
--
        RAISE global_api_expt;
    END;
--
    -- 伝票区分取得
    BEGIN
      -- カーソルOPEN
      OPEN  get_invoice_type_cur;
      -- バルクフェッチ
      FETCH get_invoice_type_cur BULK COLLECT INTO gt_qck_invoice_type;
      -- カーソルCLOSE
      CLOSE get_invoice_type_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：伝票区分取得
        IF ( get_invoice_type_cur%ISOPEN ) THEN
          CLOSE get_invoice_type_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_invo_type );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_invo_type );
--
        RAISE lookup_types_expt;
    END;
--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
    -- 入力区分取得
    BEGIN
      -- カーソルOPEN
      OPEN  get_input_type_cur;
      -- バルクフェッチ
      FETCH get_input_type_cur BULK COLLECT INTO gt_qck_input_type;
      -- カーソルCLOSE
      CLOSE get_input_type_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：伝票区分取得
        IF ( get_input_type_cur%ISOPEN ) THEN
          CLOSE get_input_type_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_input_type );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--
    -- 入出庫データ取得
    BEGIN
      -- カーソルOPEN
      OPEN  get_inv_data_cur;
      -- バルクフェッチ
      FETCH get_inv_data_cur BULK COLLECT INTO gt_inv_data;
      -- 抽出件数セット
      on_target_cnt := get_inv_data_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE get_inv_data_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_inv_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_get,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
--
      IF ( get_inv_data_cur%ISOPEN ) THEN
        CLOSE get_inv_data_cur;
      END IF;
--
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
    -- ロックエラー
    WHEN lock_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_inv_table );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_tab, gv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF ( get_inv_lock_cur%ISOPEN ) THEN
        CLOSE get_inv_lock_cur;
      END IF;
--
    -- クイックコード取得エラー
    WHEN lookup_types_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_qck_error, cv_tkn_table,  gv_tkn1,
                                                                                cv_tkn_type,   gv_tkn2,
                                                                                cv_tkn_colmun, gv_tkn3 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END inv_data_receive;
--
  /**********************************************************************************
   * Procedure Name   : inv_data_compute
   * Description      : 入出庫データ導出(A-2)
   ***********************************************************************************/
  PROCEDURE inv_data_compute(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inv_data_compute'; -- プログラム名
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
    -- 入出庫抽出データ変数
    lt_base_code           xxcoi_hht_inv_transactions.base_code%TYPE;                  -- 拠点コード
    lt_employee_num        xxcoi_hht_inv_transactions.employee_num%TYPE;               -- 営業員コード
    lt_invoice_no          xxcoi_hht_inv_transactions.invoice_no%TYPE;                 -- 伝票No.
    lt_item_code           xxcoi_hht_inv_transactions.item_code%TYPE;                  -- 品目コード（品名コード）
    lt_case_quant          xxcoi_hht_inv_transactions.case_quantity%TYPE;              -- ケース数
    lt_case_in_quant       xxcoi_hht_inv_transactions.case_in_quantity%TYPE;           -- 入数
    lt_quantity            xxcoi_hht_inv_transactions.quantity%TYPE;                   -- 本数
    lt_invoice_type        xxcoi_hht_inv_transactions.invoice_type%TYPE;               -- 伝票区分
    lt_outside_code        xxcoi_hht_inv_transactions.outside_code%TYPE;               -- 出庫側コード
    lt_inside_code         xxcoi_hht_inv_transactions.inside_code%TYPE;                -- 入庫側コード
    lt_invoice_date        xxcoi_hht_inv_transactions.invoice_date%TYPE;               -- 伝票日付
    lt_column_no           xxcoi_hht_inv_transactions.column_no%TYPE;                  -- コラムNo.
    lt_unit_price          xxcoi_hht_inv_transactions.unit_price%TYPE;                 -- 単価
    lt_hot_cold_div        xxcoi_hht_inv_transactions.hot_cold_div%TYPE;               -- H/C
    lt_item_id             xxcoi_hht_inv_transactions.inventory_item_id%TYPE;          -- 品目ID
    lt_primary_code        xxcoi_hht_inv_transactions.primary_uom_code%TYPE;           -- 基準単位
    lt_out_bus_low_type    xxcoi_hht_inv_transactions.outside_business_low_type%TYPE;  -- 出庫側業態区分
    lt_in_bus_low_type     xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;   -- 入庫側業態区分
    lt_out_cus_code        xxcoi_hht_inv_transactions.outside_cust_code%TYPE;          -- 出庫側顧客コード
    lt_in_cus_code         xxcoi_hht_inv_transactions.inside_cust_code%TYPE;           -- 入庫側顧客コード
    lt_tax_div             xxcmm_cust_accounts.tax_div%TYPE;                           -- 消費税区分
    lt_tax_round_rule      hz_cust_site_uses_all.tax_rounding_rule%TYPE;               -- 税金－端数処理
    lt_inv_price           xxcoi_mst_vd_column.price%TYPE;                             -- 単価：VDコラムマスタより
    lt_perform_code        xxcos_vd_column_headers.performance_by_code%TYPE;           -- 成績者コード
--
    lt_order_no_hht        xxcos_vd_column_headers.order_no_hht%TYPE;                  -- 受注No.(HHT)
    lt_customer_number     xxcos_vd_column_headers.customer_number%TYPE;               -- 顧客コード
    lt_system_class        xxcos_vd_column_headers.system_class%TYPE;                  -- 業態区分
    lt_total_amount        xxcos_vd_column_headers.total_amount%TYPE;                  -- 合計金額
    lt_sales_tax           xxcos_vd_column_headers.sales_consumption_tax%TYPE;         -- 売上消費税額
    lt_sales_tax_tempo     NUMBER;                                                     -- 売上消費税額：一時格納用
    lt_tax_include         xxcos_vd_column_headers.tax_include%TYPE;                   -- 税込金額
    lt_tax_include_tempo   xxcos_vd_column_headers.tax_include%TYPE;                   -- 税込金額：一時格納用
    lt_red_black_flag      xxcos_vd_column_headers.red_black_flag%TYPE;                -- 赤黒フラグ
    lt_cancel_correct      xxcos_vd_column_headers.cancel_correct_class%TYPE;          -- 取消・訂正区分
    lt_vd_quantity         xxcos_vd_column_lines.quantity%TYPE;                        -- 数量
    lt_replenish_number    xxcos_vd_column_lines.replenish_number%TYPE;                -- 補充数
--************************* 2009/04/15 N.Maeda Var1.4 ADD START ****************************************************
    lt_vd_replenish_number xxcos_vd_column_lines.replenish_number%TYPE;                -- 補充数(数量加工用)
    lt_vd_case_quant       xxcoi_hht_inv_transactions.case_quantity%TYPE;              -- ケース数(数量加工用)
--************************* 2009/04/15 N.Maeda Var1.4 ADD END ******************************************************
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
    lt_transaction_id      xxcoi_hht_inv_transactions.transaction_id%TYPE;             -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
    lt_input_class         xxcos_vd_column_headers.input_class%TYPE;                   -- 入力区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
    ln_inv_header_num      NUMBER DEFAULT  '1';                                        -- 入出庫ヘッダ件数ナンバー
    ln_inv_lines_num       NUMBER DEFAULT  '1';                                        -- 入出庫明細件数ナンバー
    ln_line_no             NUMBER DEFAULT  '1';                                        -- 行No.(HHT)
    lv_form                VARCHAR(3);                                                 -- 伝票区分による形態
    lv_change              VARCHAR(1);                                                 -- 数量加工判定
    ln_rate                NUMBER;                                                     -- 税率
--
    -- 受注No.(HHT)取得フラグ（0：取得済み、1：取得の必要あり）
    lv_order_no_flag       VARCHAR(1) DEFAULT  '1';
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
    -- ループ開始
    FOR inv_no IN 1..gn_inv_target_cnt LOOP
      -- 抽出データ取得
      lt_base_code        := gt_inv_data(inv_no).base_code;         -- 拠点コード
      lt_employee_num     := gt_inv_data(inv_no).employee_num;      -- 営業員コード
      lt_invoice_no       := gt_inv_data(inv_no).invoice_no;        -- 伝票No.
      lt_item_code        := gt_inv_data(inv_no).item_code;         -- 品目コード（品名コード）
      lt_case_quant       := gt_inv_data(inv_no).case_quant;        -- ケース数
      lt_case_in_quant    := gt_inv_data(inv_no).case_in_quant;     -- 入数
      lt_quantity         := gt_inv_data(inv_no).quantity;          -- 本数
      lt_invoice_type     := gt_inv_data(inv_no).invoice_type;      -- 伝票区分
      lt_outside_code     := gt_inv_data(inv_no).outside_code;      -- 出庫側コード
      lt_inside_code      := gt_inv_data(inv_no).inside_code;       -- 入庫側コード
      lt_invoice_date     := gt_inv_data(inv_no).invoice_date;      -- 伝票日付
      lt_column_no        := gt_inv_data(inv_no).column_no;         -- コラムNo.
      lt_unit_price       := gt_inv_data(inv_no).unit_price;        -- 単価
      lt_hot_cold_div     := gt_inv_data(inv_no).hot_cold_div;      -- H/C
      lt_replenish_number := gt_inv_data(inv_no).total_quantity;    -- 補充数
      lt_item_id          := gt_inv_data(inv_no).item_id;           -- 品目ID
      lt_primary_code     := gt_inv_data(inv_no).primary_code;      -- 基準単位
      lt_out_bus_low_type := gt_inv_data(inv_no).out_bus_low_type;  -- 出庫側業態区分
      lt_in_bus_low_type  := gt_inv_data(inv_no).in_bus_low_type;   -- 入庫側業態区分
      lt_out_cus_code     := gt_inv_data(inv_no).out_cus_code;      -- 出庫側顧客コード
      lt_in_cus_code      := gt_inv_data(inv_no).in_cus_code;       -- 入庫側顧客コード
      lt_tax_div          := gt_inv_data(inv_no).tax_div;           -- 消費税区分
      lt_tax_round_rule   := gt_inv_data(inv_no).tax_round_rule;    -- 税金－端数処理
      lt_inv_price        := gt_inv_data(inv_no).inv_price;         -- 単価：VDコラムマスタより
      lt_perform_code     := gt_inv_data(inv_no).perform_code;      -- 成績者コード
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
      lt_transaction_id   := gt_inv_data(inv_no).transaction_id;    -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--
      -- 受注No.(HHT)を取得する場合
      IF ( lv_order_no_flag = cv_one ) THEN
--
        --==============================================================
        -- 合計金額、税込金額、売上消費税額、行No.(HHT)の初期化
        --==============================================================
        lt_total_amount := 0;    -- 合計金額
        lt_tax_include  := 0;    -- 税込金額
        lt_sales_tax    := 0;    -- 売上消費税額
        ln_line_no      := 1;    -- 行No.(HHT)
--
        --==============================================================
        -- 受注No.(HHT)取得
        --==============================================================
        SELECT
          xxcos_dlv_headers_s01.NEXTVAL
        INTO
          lt_order_no_hht
        FROM
          dual
        ;
--
        lv_order_no_flag  := cv_default;                        -- 受注No.(HHT)取得フラグ初期化
--
      END IF;
--
      --==============================================================
      -- 顧客コード、業態区分、数量の導出（ヘッダ部）
      --==============================================================
      --== 出庫側、入庫側判定 ==--
      FOR i IN 1..gt_qck_invoice_type.COUNT LOOP
--
        IF ( gt_qck_invoice_type(i).invoice_type = lt_invoice_type ) THEN
          lv_form   := gt_qck_invoice_type(i).form;     -- 伝票区分による形態をセット
          lv_change := gt_qck_invoice_type(i).change;   -- 数量加工判定をセット
          EXIT;
        END IF;
--
      END LOOP;
--
      IF ( lv_form = cv_tkn_out ) THEN         -- 出庫側の場合
--
        --== 顧客コードセット ==--
        lt_customer_number := lt_out_cus_code;
--
        --== 業態区分セット ==--
        lt_system_class := lt_out_bus_low_type;
--
      ELSIF ( lv_form = cv_tkn_in ) THEN       -- 入庫側の場合
--
        --== 顧客コードセット ==--
        lt_customer_number := lt_in_cus_code;
--
        --== 業態区分セット ==--
        lt_system_class := lt_in_bus_low_type;
--
      END IF;
--
      IF ( lt_quantity >= 0 ) THEN           -- 数量が0以上の場合
--
        --== 赤黒フラグセット ==--
        lt_red_black_flag := cv_one;         -- 1をセット
--
        --== 取消・訂正区分セット ==--
        lt_cancel_correct := NULL;           -- NULLをセット
--
      ELSIF ( lt_quantity < 0 ) THEN         -- 数量がマイナスの場合
--
        --== 赤黒フラグセット ==--
        lt_red_black_flag := cv_default;     -- 0をセット
--
        --== 取消・訂正区分セット ==--
        lt_cancel_correct := cv_one;         -- 1をセット
--
      END IF;
--
      --== 数量加工 ==--
      IF ( lv_change = cv_tkn_yes ) THEN
        lt_vd_quantity := lt_quantity * -1;
--************************* 2009/04/15 N.Maeda Var1.4 ADD START ****************************************************
        lt_vd_replenish_number := lt_replenish_number * -1;
        lt_vd_case_quant       := lt_case_quant * -1;
--************************* 2009/04/15 N.Maeda Var1.4 ADD END ******************************************************
      ELSE
        lt_vd_quantity := lt_quantity;
--************************* 2009/04/15 N.Maeda Var1.4 ADD START ****************************************************
        lt_vd_replenish_number := lt_replenish_number;
        lt_vd_case_quant       := lt_case_quant;
--************************* 2009/04/15 N.Maeda Var1.4 ADD END ******************************************************
      END IF;
--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
      --入力区分
      --初期化
      lt_input_class := NULL;
      FOR i IN 1..gt_qck_input_type.COUNT LOOP
--
        IF ( gt_qck_input_type(i).slip_class = lt_invoice_type ) THEN
          lt_input_class   := gt_qck_input_type(i).input_class;     -- 伝票区分による入力区分をセット
          EXIT;
        END IF;
--
      END LOOP;
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
      --== 税率の算出 ==--
      FOR i IN 1..gt_tax_rate.COUNT LOOP
--
        IF ( gt_tax_rate(i).tax_class = lt_tax_div ) THEN
          ln_rate := 1 + gt_tax_rate(i).rate / 100;     -- 税率をセット
          EXIT;
        END IF;
--
      END LOOP;
--
      --==============================================================
      -- 合計金額の導出（ヘッダ部）
      --==============================================================
--************************* 2009/04/15 N.Maeda Var1.4 MOD START ****************************************************
--      -- 補充数×単価
--      lt_total_amount := lt_total_amount + lt_replenish_number * lt_unit_price;
      -- 補充数×単価
      lt_total_amount := lt_total_amount + lt_vd_replenish_number * lt_unit_price;
--************************* 2009/04/15 N.Maeda Var1.4 MOD END ******************************************************
--
      --==============================================================
      -- 税込み金額の導出（ヘッダ部）
      --==============================================================
--************************* 2009/04/15 N.Maeda Var1.4 MOD START ****************************************************
--      -- 本数×VDコラムマスタの単価
--      lt_tax_include_tempo := lt_replenish_number * lt_inv_price;
      -- 本数×VDコラムマスタの単価
      lt_tax_include_tempo := lt_vd_replenish_number * lt_inv_price;
--************************* 2009/04/15 N.Maeda Var1.4 MOD END ******************************************************
--
      -- ヘッダ変数格納用データ算出
      lt_tax_include := lt_tax_include + lt_tax_include_tempo;
--
      --==============================================================
      -- 売上消費税額の導出（ヘッダ部）
      --==============================================================
      -- 税込金額÷消費税率
      lt_sales_tax_tempo := lt_tax_include_tempo - ( lt_tax_include_tempo / ln_rate );
--
      -- 小数点以下の処理
      IF ( lt_tax_round_rule = cv_tkn_down ) THEN        -- 切捨て処理
--
        lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo );
--
      ELSIF ( lt_tax_round_rule = cv_tkn_up ) THEN       -- 切上げ処理
--
        lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo + .9 );
--
      ELSIF ( lt_tax_round_rule = cv_tkn_nearest ) THEN  -- 四捨五入処理
--
        lt_sales_tax_tempo := ROUND( lt_sales_tax_tempo );
--
      END IF;
--
      -- ヘッダ変数格納用データ算出
      lt_sales_tax := lt_sales_tax + lt_sales_tax_tempo;
--
      --==============================================================
      -- 入出庫明細へデータ格納
      --==============================================================
      gt_order_nol_hht(ln_inv_lines_num)  := lt_order_no_hht;      -- 受注No.(HHT)
      gt_line_no_hht(ln_inv_lines_num)    := ln_line_no;           -- 行No.(HHT)
      gt_item_code_self(ln_inv_lines_num) := lt_item_code;         -- 品名コード(自社)
      gt_content(ln_inv_lines_num)        := lt_case_in_quant;     -- 入数
      gt_item_id(ln_inv_lines_num)        := lt_item_id;           -- 品目ID
      gt_standard_unit(ln_inv_lines_num)  := lt_primary_code;      -- 基準単位
--************************* 2009/04/16 N.Maeda Var1.5 MOD START ****************************************************
--************************* 2009/04/15 N.Maeda Var1.4 MOD START ****************************************************
--      gt_case_number(ln_inv_lines_num)    := lt_case_quant;        -- ケース数
--      gt_case_number(ln_inv_lines_num)    := lt_vd_replenish_number;        -- ケース数
--************************* 2009/04/15 N.Maeda Var1.4 MOD END ******************************************************
      gt_case_number(ln_inv_lines_num)    := lt_vd_case_quant;        -- ケース数
--************************* 2009/04/16 N.Maeda Var1.5 MOD END ******************************************************
      gt_quantity(ln_inv_lines_num)       := lt_vd_quantity;       -- 数量
      gt_wholesale(ln_inv_lines_num)      := lt_unit_price;        -- 卸単価
      gt_column_no(ln_inv_lines_num)      := lt_column_no;         -- コラムNo.
      gt_h_and_c(ln_inv_lines_num)        := lt_hot_cold_div;      -- H/C
--************************* 2009/04/15 N.Maeda Var1.4 MOD START ****************************************************
--      gt_replenish_num(ln_inv_lines_num)  := lt_replenish_number;  -- 補充数
      gt_replenish_num(ln_inv_lines_num)  := lt_vd_replenish_number;  -- 補充数
--************************* 2009/04/15 N.Maeda Var1.4 MOD END ******************************************************
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
      gt_transaction_id(ln_inv_lines_num) := lt_transaction_id;     -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
      gt_input_class(ln_inv_lines_num)    := lt_input_class;        -- 入力区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
      ln_line_no := ln_line_no + 1;                                -- 行No.(HHT)更新
      ln_inv_lines_num := ln_inv_lines_num + 1;                    -- 入出庫明細件数ナンバー更新
--
      IF ( inv_no = gn_inv_target_cnt ) THEN    -- ループが最後の場合
--
        --==============================================================
        -- 入出庫ヘッダへデータ格納
        --==============================================================
        gt_order_noh_hht(ln_inv_header_num)  := lt_order_no_hht;       -- 受注No.(HHT)
        gt_base_code(ln_inv_header_num)      := lt_base_code;          -- 拠点コード
        gt_perform_code(ln_inv_header_num)   := lt_perform_code;       -- 成績者コード
        gt_dlv_code(ln_inv_header_num)       := lt_employee_num;       -- 納品者コード
        gt_invoice_no(ln_inv_header_num)     := lt_invoice_no;         -- HHT伝票No.
        gt_dlv_date(ln_inv_header_num)       := lt_invoice_date;       -- 納品日
        gt_inspect_date(ln_inv_header_num)   := lt_invoice_date;       -- 検収日
        gt_cus_number(ln_inv_header_num)     := lt_customer_number;    -- 顧客コード
        gt_system_class(ln_inv_header_num)   := lt_system_class;       -- 業態区分
        gt_invoice_type(ln_inv_header_num)   := lt_invoice_type;       -- 伝票区分
        gt_tax_class(ln_inv_header_num)      := lt_tax_div;            -- 消費税区分
        gt_total_amount(ln_inv_header_num)   := lt_total_amount;       -- 合計金額
        gt_sales_tax(ln_inv_header_num)      := lt_sales_tax;          -- 売上消費税額
        gt_tax_include(ln_inv_header_num)    := lt_tax_include;        -- 税込金額
        gt_red_black_flag(ln_inv_header_num) := lt_red_black_flag;     -- 赤黒フラグ
        gt_cancel_correct(ln_inv_header_num) := lt_cancel_correct;     -- 取消・訂正区分
        ln_inv_header_num := ln_inv_header_num + 1;                    -- 入出庫ヘッダ件数ナンバー更新
        lv_order_no_flag  := cv_one;                                   -- 受注No.(HHT)取得フラグ更新
--
      ELSIF ( lt_invoice_no != gt_inv_data(inv_no + 1).invoice_no ) THEN
--
        --==============================================================
        -- 入出庫ヘッダへデータ格納
        --==============================================================
        gt_order_noh_hht(ln_inv_header_num)  := lt_order_no_hht;       -- 受注No.(HHT)
        gt_base_code(ln_inv_header_num)      := lt_base_code;          -- 拠点コード
        gt_perform_code(ln_inv_header_num)   := lt_perform_code;       -- 成績者コード
        gt_dlv_code(ln_inv_header_num)       := lt_employee_num;       -- 納品者コード
        gt_invoice_no(ln_inv_header_num)     := lt_invoice_no;         -- HHT伝票No.
        gt_dlv_date(ln_inv_header_num)       := lt_invoice_date;       -- 納品日
        gt_inspect_date(ln_inv_header_num)   := lt_invoice_date;       -- 検収日
        gt_cus_number(ln_inv_header_num)     := lt_customer_number;    -- 顧客コード
        gt_system_class(ln_inv_header_num)   := lt_system_class;       -- 業態区分
        gt_invoice_type(ln_inv_header_num)   := lt_invoice_type;       -- 伝票区分
        gt_tax_class(ln_inv_header_num)      := lt_tax_div;            -- 消費税区分
        gt_total_amount(ln_inv_header_num)   := lt_total_amount;       -- 合計金額
        gt_sales_tax(ln_inv_header_num)      := lt_sales_tax;          -- 売上消費税額
        gt_tax_include(ln_inv_header_num)    := lt_tax_include;        -- 税込金額
        gt_red_black_flag(ln_inv_header_num) := lt_red_black_flag;     -- 赤黒フラグ
        gt_cancel_correct(ln_inv_header_num) := lt_cancel_correct;     -- 取消・訂正区分
        ln_inv_header_num := ln_inv_header_num + 1;                    -- 入出庫ヘッダ件数ナンバー更新
        lv_order_no_flag  := cv_one;                                   -- 受注No.(HHT)取得フラグ更新
--
      END IF;
--
    END LOOP;
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
  END inv_data_compute;
--
  /**********************************************************************************
   * Procedure Name   : inv_data_register
   * Description      : 入出庫データ登録(A-3)
   ***********************************************************************************/
  PROCEDURE inv_data_register(
    on_normal_cnt   OUT NUMBER,       --   ヘッダ成功件数
    on_normal_cnt_l OUT NUMBER,       --   明細成功件数
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inv_data_register'; -- プログラム名
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
    -- 件数初期化
    on_normal_cnt   := 0;
    on_normal_cnt_l := 0;
--
    --==============================================================
    -- VDコラム別取引ヘッダテーブルへ登録
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_order_noh_hht.COUNT
        INSERT INTO xxcos_vd_column_headers
          (
            order_no_hht,                   -- 受注No.(HHT)
            digestion_ln_number,            -- 枝番
            order_no_ebs,                   -- 受注No.(EBS)
            base_code,                      -- 拠点コード
            performance_by_code,            -- 成績者コード
            dlv_by_code,                    -- 納品者コード
            hht_invoice_no,                 -- HHT伝票No.
            dlv_date,                       -- 納品日
            inspect_date,                   -- 検収日
            sales_classification,           -- 売上分類区分
            sales_invoice,                  -- 売上伝票区分
            card_sale_class,                -- カード売区分
            dlv_time,                       -- 時間
            change_out_time_100,            -- つり銭切れ時間100円
            change_out_time_10,             -- つり銭切れ時間10円
            customer_number,                -- 顧客コード
            dlv_form,                       -- 納品形態
            system_class,                   -- 業態区分
            invoice_type,                   -- 伝票区分
            input_class,                    -- 入力区分
            consumption_tax_class,          -- 消費税区分
            total_amount,                   -- 合計金額
            sale_discount_amount,           -- 売上値引額
            sales_consumption_tax,          -- 売上消費税額
            tax_include,                    -- 税込金額
            keep_in_code,                   -- 預け先コード
            department_screen_class,        -- 百貨店画面種別
            digestion_vd_rate_maked_date,   -- 消化VD掛率作成済年月日
            red_black_flag,                 -- 赤黒フラグ
            forward_flag,                   -- 連携フラグ
            forward_date,                   -- 連携日付
            vd_results_forward_flag,        -- ベンダ納品実績情報連携済フラグ
            cancel_correct_class,           -- 取消・訂正区分
            created_by,                     -- 作成者
            creation_date,                  -- 作成日
            last_updated_by,                -- 最終更新者
            last_update_date,               -- 最終更新日
            last_update_login,              -- 最終更新ログイン
            request_id,                     -- 要求ID
            program_application_id,         -- コンカレント・プログラム・アプリケーションID
            program_id,                     -- コンカレント・プログラムID
            program_update_date             -- プログラム更新日
          )
        VALUES
          (
            gt_order_noh_hht(i),            -- 受注No.(HHT)
            0,                              -- 枝番
            NULL,                           -- 受注No.(EBS)
            gt_base_code(i),                -- 拠点コード
            gt_perform_code(i),             -- 成績者コード
            gt_dlv_code(i),                 -- 納品者コード
            gt_invoice_no(i),               -- HHT伝票No.
            gt_dlv_date(i),                 -- 納品日
            gt_inspect_date(i),             -- 検収日
            NULL,                           -- 売上分類区分
            NULL,                           -- 売上伝票区分
            NULL,                           -- カード売区分
            NULL,                           -- 時間
            NULL,                           -- つり銭切れ時間100円
            NULL,                           -- つり銭切れ時間10円
            gt_cus_number(i),               -- 顧客コード
            NULL,                           -- 納品形態
            gt_system_class(i),             -- 業態区分
            gt_invoice_type(i),             -- 伝票区分
--****************************** 2009/04/22 1.7 T.Kitajima MOD START ******************************--
--            NULL,                           -- 入力区分
            gt_input_class(i),              -- 入力区分
--****************************** 2009/04/22 1.7 T.Kitajima MOD  END  ******************************--
            gt_tax_class(i),                -- 消費税区分
            gt_total_amount(i),             -- 合計金額
            NULL,                           -- 売上値引額
            gt_sales_tax(i),                -- 売上消費税額
            gt_tax_include(i),              -- 税込金額
            NULL,                           -- 預け先コード
            NULL,                           -- 百貨店画面種別
            NULL,                           -- 消化VD掛率作成済年月日
            gt_red_black_flag(i),           -- 赤黒フラグ
            'N',                            -- 連携フラグ
            NULL,                           -- 連携日付
            'N',                            -- ベンダ納品実績情報連携済フラグ
            gt_cancel_correct(i),           -- 取消・訂正区分
            cn_created_by,                  -- 作成者
            cd_creation_date,               -- 作成日
            cn_last_updated_by,             -- 最終更新者
            cd_last_update_date,            -- 最終更新日
            cn_last_update_login,           -- 最終更新ログイン
            cn_request_id,                  -- 要求ID
            cn_program_application_id,      -- コンカレント・プログラム・アプリケーションID
            cn_program_id,                  -- コンカレント・プログラムID
            cd_program_update_date          -- プログラム更新日
          );
--
      -- ヘッダ成功件数セット
      on_normal_cnt := SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdh_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- VDコラム別取引明細テーブルへ登録
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_order_nol_hht.COUNT
        INSERT INTO xxcos_vd_column_lines
          (
            order_no_hht,                   -- 受注No.(HHT)
            line_no_hht,                    -- 行No.(HHT)
            digestion_ln_number,            -- 枝番
            order_no_ebs,                   -- 受注No.(EBS)
            line_number_ebs,                -- 明細番号(EBS)
            item_code_self,                 -- 品名コード(自社)
            content,                        -- 入数
            inventory_item_id,              -- 品目ID
            standard_unit,                  -- 基準単位
            case_number,                    -- ケース数
            quantity,                       -- 数量
            sale_class,                     -- 売上区分
            wholesale_unit_ploce,           -- 卸単価
            selling_price,                  -- 売単価
            column_no,                      -- コラムNo.
            h_and_c,                        -- H/C
            sold_out_class,                 -- 売切区分
            sold_out_time,                  -- 売切時間
            replenish_number,               -- 補充数
            cash_and_card,                  -- 現金・カード併用額
            created_by,                     -- 作成者
            creation_date,                  -- 作成日
            last_updated_by,                -- 最終更新者
            last_update_date,               -- 最終更新日
            last_update_login,              -- 最終更新ログイン
            request_id,                     -- 要求ID
            program_application_id,         -- コンカレント・プログラム・アプリケーションID
            program_id,                     -- コンカレント・プログラムID
            program_update_date             -- プログラム更新日
          )
        VALUES
          (
            gt_order_nol_hht(i),               -- 受注No.(HHT)
            gt_line_no_hht(i),                 -- 行No.(HHT)
            0,                              -- 枝番
            NULL,                           -- 受注No.(EBS)
            NULL,                           -- 明細番号(EBS)
            gt_item_code_self(i),              -- 品名コード(自社)
            gt_content(i),                     -- 入数
            gt_item_id(i),                     -- 品目ID
            gt_standard_unit(i),               -- 基準単位
            gt_case_number(i),                 -- ケース数
            gt_quantity(i),                    -- 数量
            NULL,                           -- 売上区分
            gt_wholesale(i),                   -- 卸単価
            NULL,                           -- 売単価
            gt_column_no(i),                   -- コラムNo.
            gt_h_and_c(i),                     -- H/C
            NULL,                           -- 売切区分
            NULL,                           -- 売切時間
            gt_replenish_num(i),               -- 補充数
            NULL,                           -- 現金・カード併用額
            cn_created_by,                  -- 作成者
            cd_creation_date,               -- 作成日
            cn_last_updated_by,             -- 最終更新者
            cd_last_update_date,            -- 最終更新日
            cn_last_update_login,           -- 最終更新ログイン
            cn_request_id,                  -- 要求ID
            cn_program_application_id,      -- コンカレント・プログラム・アプリケーションID
            cn_program_id,                  -- コンカレント・プログラムID
            cd_program_update_date          -- プログラム更新日
          );
--
      -- 明細成功件数セット
      on_normal_cnt_l := SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdl_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END inv_data_register;
--
  /**********************************************************************************
   * Procedure Name   : dlv_data_register
   * Description      : 納品データ登録(A-4)
   ***********************************************************************************/
  PROCEDURE dlv_data_register(
    on_target_cnt   OUT NUMBER,       --   ヘッダ抽出件数
    on_target_cnt_l OUT NUMBER,       --   明細抽出件数
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlv_data_register'; -- プログラム名
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
    CURSOR headers_lock_cur
    IS
      SELECT head.creation_date  creation_date
      FROM   xxcos_dlv_headers   head                     -- 納品ヘッダテーブル
      WHERE  head.results_forward_flag = cv_default       -- 販売実績連携済みフラグ＝0
      AND    head.input_class          = cv_input_class   -- 入力区分＝5
      FOR UPDATE NOWAIT;
--
    CURSOR lines_lock_cur
    IS
      SELECT line.creation_date  creation_date
      FROM   xxcos_dlv_headers   head,                             -- 納品ヘッダテーブル
             xxcos_dlv_lines     line                              -- 納品明細テーブル
      WHERE  head.results_forward_flag = cv_default                -- 販売実績連携済みフラグ＝0
      AND    head.input_class          = cv_input_class            -- 入力区分＝5
      AND    head.order_no_hht         = line.order_no_hht         -- ヘッダ.受注No.(HHT)＝明細.受注No.(HHT)
      AND    head.digestion_ln_number  = line.digestion_ln_number  -- ヘッダ.枝番＝明細.枝番
      FOR UPDATE NOWAIT;
--
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
    -- 抽出件数初期化
    on_target_cnt   := 0;
    on_target_cnt_l := 0;
--
    --==============================================================
    -- テーブルロック
    --==============================================================
    OPEN  headers_lock_cur;
    CLOSE headers_lock_cur;
--
    OPEN  lines_lock_cur;
    CLOSE lines_lock_cur;
--
    --==============================================================
    -- VDコラム別取引ヘッダテーブルへ登録
    --==============================================================
    BEGIN
      INSERT INTO
        xxcos_vd_column_headers
          (
               order_no_hht,                   -- 受注No.(HHT)
               digestion_ln_number,            -- 枝番
               order_no_ebs,                   -- 受注No.(EBS)
               base_code,                      -- 拠点コード
               performance_by_code,            -- 成績者コード
               dlv_by_code,                    -- 納品者コード
               hht_invoice_no,                 -- HHT伝票No.
               dlv_date,                       -- 納品日
               inspect_date,                   -- 検収日
               sales_classification,           -- 売上分類区分
               sales_invoice,                  -- 売上伝票区分
               card_sale_class,                -- カード売区分
               dlv_time,                       -- 時間
               change_out_time_100,            -- つり銭切れ時間100円
               change_out_time_10,             -- つり銭切れ時間10円
               customer_number,                -- 顧客コード
               dlv_form,                       -- 納品形態
               system_class,                   -- 業態区分
               invoice_type,                   -- 伝票区分
               input_class,                    -- 入力区分
               consumption_tax_class,          -- 消費税区分
               total_amount,                   -- 合計金額
               sale_discount_amount,           -- 売上値引額
               sales_consumption_tax,          -- 売上消費税額
               tax_include,                    -- 税込金額
               keep_in_code,                   -- 預け先コード
               department_screen_class,        -- 百貨店画面種別
               digestion_vd_rate_maked_date,   -- 消化VD掛率作成年月日
               red_black_flag,                 -- 赤黒フラグ
               forward_flag,                   -- 連携フラグ
               forward_date,                   -- 連携日付
               vd_results_forward_flag,        -- ベンダ納品実績情報連携済フラグ
               cancel_correct_class,           -- 取消・訂正区分
               created_by,                     -- 作成者
               creation_date,                  -- 作成日
               last_updated_by,                -- 最終更新者
               last_update_date,               -- 最終更新日
               last_update_login,              -- 最終更新ログイン
               request_id,                     -- 要求ID
               program_application_id,         -- コンカレント・プログラム・アプリケーションID
               program_id,                     -- コンカレント・プログラムID
               program_update_date             -- プログラム更新日
          )
        SELECT head.order_no_hht,              -- 受注No.(HHT)
               head.digestion_ln_number,       -- 枝番
               head.order_no_ebs,              -- 受注No.(EBS)
               head.base_code,                 -- 拠点コード
               head.performance_by_code,       -- 成績者コード
               head.dlv_by_code,               -- 納品者コード
               head.hht_invoice_no,            -- HHT伝票No.
               head.dlv_date,                  -- 納品日
               head.inspect_date,              -- 検収日
               head.sales_classification,      -- 売上分類区分
               head.sales_invoice,             -- 売上伝票区分
               head.card_sale_class,           -- カード売区分
               head.dlv_time,                  -- 時間
               head.change_out_time_100,       -- つり銭切れ時間100円
               head.change_out_time_10,        -- つり銭切れ時間10円
               head.customer_number,           -- 顧客コード
               NULL,                           -- 納品形態
               head.system_class,              -- 業態区分
               NULL,                           -- 伝票区分
               head.input_class,               -- 入力区分
               head.consumption_tax_class,     -- 消費税区分
               head.total_amount,              -- 合計金額
               head.sale_discount_amount,      -- 売上値引額
               head.sales_consumption_tax,     -- 売上消費税額
               head.tax_include,               -- 税込金額
               head.keep_in_code,              -- 預け先コード
               head.department_screen_class,   -- 百貨店画面種別
               NULL,                           -- 消化VD掛率作成年月日
               head.red_black_flag,            -- 赤黒フラグ
               'N',                            -- 連携フラグ
               NULL,                           -- 連携日付
               'N',                            -- ベンダ納品実績情報連携済フラグ
               head.cancel_correct_class,      -- 取消・訂正区分
               cn_created_by,                  -- 作成者
               cd_creation_date,               -- 作成日
               cn_last_updated_by,             -- 最終更新者
               cd_last_update_date,            -- 最終更新日
               cn_last_update_login,           -- 最終更新ログイン
               cn_request_id,                  -- 要求ID
               cn_program_application_id,      -- コンカレント・プログラム・アプリケーションID
               cn_program_id,                  -- コンカレント・プログラムID
               cd_program_update_date          -- プログラム更新日
        FROM   xxcos_dlv_headers  head         -- 納品ヘッダテーブル
        WHERE  head.results_forward_flag = cv_default       -- 販売実績連携済みフラグ＝0
        AND    head.input_class          = cv_input_class;  -- 入力区分＝5
--
    -- ヘッダ抽出件数セット
    on_target_cnt := SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdh_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- VDコラム別取引明細テーブルへ登録
    --==============================================================
    BEGIN
      INSERT INTO
        xxcos_vd_column_lines
          (
               order_no_hht,                -- 受注No.(HHT)
               line_no_hht,                 -- 行No.(HHT)
               digestion_ln_number,         -- 枝番
               order_no_ebs,                -- 受注No.(EBS)
               line_number_ebs,             -- 明細番号(EBS)
               item_code_self,              -- 品名コード(自社)
               content,                     -- 入数
               inventory_item_id,           -- 品目ID
               standard_unit,               -- 基準単位
               case_number,                 -- ケース数
               quantity,                    -- 数量
               sale_class,                  -- 売上区分
               wholesale_unit_ploce,        -- 卸単価
               selling_price,               -- 売単価
               column_no,                   -- コラムNo.
               h_and_c,                     -- H/C
               sold_out_class,              -- 売切区分
               sold_out_time,               -- 売切時間
               replenish_number,            -- 補充数
               cash_and_card,               -- 現金・カード併用額
               created_by,                  -- 作成者
               creation_date,               -- 作成日
               last_updated_by,             -- 最終更新者
               last_update_date,            -- 最終更新日
               last_update_login,           -- 最終更新ログイン
               request_id,                  -- 要求ID
               program_application_id,      -- コンカレント・プログラム・アプリケーションID
               program_id,                  -- コンカレント・プログラムID
               program_update_date          -- プログラム更新日
          )
        SELECT line.order_no_hht,           -- 受注No.(HHT)
               line.line_no_hht,            -- 行No.(HHT)
               line.digestion_ln_number,    -- 枝番
               line.order_no_ebs,           -- 受注No.(EBS)
               line.line_number_ebs,        -- 明細番号(EBS)
               line.item_code_self,         -- 品名コード(自社)
               line.content,                -- 入数
               line.inventory_item_id,      -- 品目ID
               line.standard_unit,          -- 基準単位
               line.case_number,            -- ケース数
               DECODE( head.red_black_flag, '0', line.quantity * -1, line.quantity ),
                                            -- 数量
               line.sale_class,             -- 売上区分
               line.wholesale_unit_ploce,   -- 卸単価
               line.selling_price,          -- 売単価
               line.column_no,              -- コラムNo.
               line.h_and_c,                -- H/C
               line.sold_out_class,         -- 売切区分
               line.sold_out_time,          -- 売切時間
               DECODE( head.red_black_flag, '0', line.replenish_number * -1, line.replenish_number ),
                                            -- 補充数
               line.cash_and_card,          -- 現金・カード併用額
               cn_created_by,               -- 作成者
               cd_creation_date,            -- 作成日
               cn_last_updated_by,          -- 最終更新者
               cd_last_update_date,         -- 最終更新日
               cn_last_update_login,        -- 最終更新ログイン
               cn_request_id,               -- 要求ID
               cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
               cn_program_id,               -- コンカレント・プログラムID
               cd_program_update_date       -- プログラム更新日
        FROM   xxcos_dlv_headers  head,     -- 納品ヘッダテーブル
               xxcos_dlv_lines    line      -- 納品明細テーブル
        WHERE  head.results_forward_flag = cv_default                -- 販売実績連携済みフラグ＝0
        AND    head.input_class          = cv_input_class            -- 入力区分＝5
        AND    head.order_no_hht         = line.order_no_hht         -- ヘッダ.受注No.(HHT)＝明細.受注No.(HHT)
        AND    head.digestion_ln_number  = line.digestion_ln_number; -- ヘッダ.枝番＝明細.枝番
--
--
    -- 明細抽出件数セット
    on_target_cnt_l := SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdl_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
    -- ロックエラー
    WHEN lock_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_table );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_tab, gv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF ( headers_lock_cur%ISOPEN ) THEN
        CLOSE headers_lock_cur;
      END IF;
--
      IF ( lines_lock_cur%ISOPEN ) THEN
        CLOSE lines_lock_cur;
      END IF;
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
  END dlv_data_register;
--
  /**********************************************************************************
   * Procedure Name   : data_update
   * Description      : コラム別転送済フラグ、販売実績連携済みフラグ更新(A-5)
   ***********************************************************************************/
  PROCEDURE data_update(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_update'; -- プログラム名
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
    --==============================================================
    -- コラム転送フラグ更新
    --==============================================================
    BEGIN
--****************************** 2009/04/17 1.6 T.Kitajima MOD START ******************************--
--      UPDATE
--        xxcoi_hht_inv_transactions  inv   -- 入出庫一時表
--      SET
--        inv.column_if_flag         = cv_tkn_yes,                  -- コラム転送フラグ
--        inv.column_if_date         = cd_last_update_date,         -- コラム別転送日
--        inv.last_updated_by        = cn_last_updated_by,          -- 最終更新者
--        inv.last_update_date       = cd_last_update_date,         -- 最終更新日
--        inv.last_update_login      = cn_last_update_login,        -- 最終更新ログイン
--        inv.request_id             = cn_request_id,               -- 要求ID
--        inv.program_application_id = cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
--        inv.program_id             = cn_program_id,               -- コンカレント・プログラムID
--        inv.program_update_date    = cd_program_update_date       -- プログラム更新日
--      WHERE  inv.invoice_type IN (
--                                     SELECT  look_val.lookup_code  code
--                                     FROM    fnd_lookup_values     look_val
--                                            ,fnd_lookup_types_tl   types_tl
--                                            ,fnd_lookup_types      types
--                                            ,fnd_application_tl    appl
--                                            ,fnd_application       app
--                                     WHERE   app.application_short_name = cv_application
--                                     AND     look_val.lookup_type  = cv_qck_invo_type
--                                     AND     look_val.enabled_flag = cv_tkn_yes
--                                     AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                                     AND     gd_process_date      >= look_val.start_date_active
--                                     AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                                     AND     types_tl.language     = USERENV( 'LANG' )
--                                     AND     look_val.language     = USERENV( 'LANG' )
--                                     AND     appl.language         = USERENV( 'LANG' )
--                                     AND     appl.application_id   = types.application_id
--                                     AND     app.application_id    = appl.application_id
--                                     AND     types_tl.lookup_type  = look_val.lookup_type
--                                     AND     types.lookup_type     = types_tl.lookup_type
--                                     AND     types.security_group_id   = types_tl.security_group_id
--                                     AND     types.view_application_id = types_tl.view_application_id
--                                   )                              -- 伝票区分＝4,5,6,7
--      AND    inv.column_if_flag = cv_tkn_no                       -- コラム別転送フラグ＝N
--      AND    inv.status         = cv_one;                         -- 処理ステータス＝1
      FORALL i in 1..gt_transaction_id.COUNT
        UPDATE xxcoi_hht_inv_transactions  inv   -- 入出庫一時表
           SET inv.column_if_flag         = cv_tkn_yes,                  -- コラム転送フラグ
               inv.column_if_date         = cd_last_update_date,         -- コラム別転送日
               inv.last_updated_by        = cn_last_updated_by,          -- 最終更新者
               inv.last_update_date       = cd_last_update_date,         -- 最終更新日
               inv.last_update_login      = cn_last_update_login,        -- 最終更新ログイン
               inv.request_id             = cn_request_id,               -- 要求ID
               inv.program_application_id = cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
               inv.program_id             = cn_program_id,               -- コンカレント・プログラムID
               inv.program_update_date    = cd_program_update_date       -- プログラム更新日
         WHERE inv.transaction_id         = gt_transaction_id(i)
        ;
--****************************** 2009/04/17 1.6 T.Kitajima MOD START ******************************--
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_inv_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- 販売実績連携済みフラグ更新
    --==============================================================
    BEGIN
      UPDATE
        xxcos_dlv_headers  head   -- 納品ヘッダテーブル
      SET
        head.results_forward_flag   = cv_one,                      -- 販売実績連携済みフラグ
        head.results_forward_date   = cd_last_update_date,         -- 販売実績連携済み日付
        head.last_updated_by        = cn_last_updated_by,          -- 最終更新者
        head.last_update_date       = cd_last_update_date,         -- 最終更新日
        head.last_update_login      = cn_last_update_login,        -- 最終更新ログイン
        head.request_id             = cn_request_id,               -- 要求ID
        head.program_application_id = cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
        head.program_id             = cn_program_id,               -- コンカレント・プログラムID
        head.program_update_date    = cd_program_update_date       -- プログラム更新日
      WHERE  head.results_forward_flag = cv_default                -- 販売実績連携済みフラグ＝0
      AND    head.input_class          = cv_input_class;           -- 入力区分＝5
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_h_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END data_update;
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
--
    -- *** ローカル変数 ***
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
--
    -- グローバル変数の初期化
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    gn_warn_cnt         := 0;
    gn_inv_target_cnt   := 0;
    gn_dlv_h_target_cnt := 0;
    gn_dlv_l_target_cnt := 0;
    gn_h_normal_cnt     := 0;
    gn_l_normal_cnt     := 0;
    gn_dlv_h_nor_cnt    := 0;
    gn_dlv_l_nor_cnt    := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-0)
    -- ===============================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 入出庫データ抽出(A-1)
    -- ===============================
    inv_data_receive(
      gn_inv_target_cnt,   -- 入出庫情報抽出件数
      lv_errbuf,           -- エラー・メッセージ           --# 固定 #
      lv_retcode,          -- リターン・コード             --# 固定 #
      lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --== 入出庫情報が1件以上ある場合、A-2、A-3の処理を行います。 ==--
    IF ( gn_inv_target_cnt >= 1 ) THEN
      -- ===============================
      -- 入出庫データ導出(A-2)
      -- ===============================
      inv_data_compute(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラー処理
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 入出庫データ登録(A-3)
      -- ===============================
      inv_data_register(
        gn_h_normal_cnt,      -- 入出庫ヘッダ情報成功件数
        gn_l_normal_cnt,      -- 入出庫明細情報成功件数
        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
        lv_retcode,           -- リターン・コード             --# 固定 #
        lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラー処理
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- 納品データ登録(A-4)
    -- ===============================
    dlv_data_register(
      gn_dlv_h_target_cnt, -- 納品ヘッダ情報抽出件数
      gn_dlv_l_target_cnt, -- 納品明細情報抽出件数
      lv_errbuf,           -- エラー・メッセージ           --# 固定 #
      lv_retcode,          -- リターン・コード             --# 固定 #
      lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 納品情報成功件数セット
    gn_dlv_h_nor_cnt    := gn_dlv_h_target_cnt;
    gn_dlv_l_nor_cnt    := gn_dlv_l_target_cnt;
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
      -- =======================================================
      -- コラム別転送済フラグ、販売実績連携済みフラグ更新(A-5)
      -- =======================================================
      data_update(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラー処理
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    -- 警告処理（対象データ無しエラー）
    IF (  gn_inv_target_cnt + gn_dlv_h_target_cnt = 0  ) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata );
      FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
      ov_retcode := cv_status_warn;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- 成功件数初期化
      gn_h_normal_cnt  := 0;
      gn_l_normal_cnt  := 0;
      gn_dlv_h_nor_cnt := 0;
      gn_dlv_l_nor_cnt := 0;
--
      FND_FILE.PUT_LINE(
         which => FND_FILE.OUTPUT
        ,buff  => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which => FND_FILE.LOG
        ,buff  => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    --入出庫情報抽出件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_inv_cnt
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_inv_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --
    --納品ヘッダ情報抽出件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_dlv_cnt
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_dlv_h_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --
    --納品明細情報抽出件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_dlv_cnt_l
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_dlv_l_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --
    --ヘッダ成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_h_nor_cnt
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_h_normal_cnt + gn_dlv_h_nor_cnt )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --
    --明細成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_l_nor_cnt
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_l_normal_cnt + gn_dlv_l_nor_cnt )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS001A07C;
/

