CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A07C (body)
 * Description      : 入出庫一時表、納品ヘッダ・明細テーブルのデータの抽出を行う
 * MD.050           : VDコラム別取引データ抽出 (MD050_COS_001_A07)
 * Version          : 1.19
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
 *  ins_err_msg            エラー情報登録処理(A-6)
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
 *  2009/05/07    1.8   N.Maeda          [T1_0821]VDコラム別取引情報テーブル.対象オリジナル伝票存在時対応
 *  2009/05/21    1.9   T.Kitajima       [T1_1039]販売実績連携済み更新方法修正
 *  2009/05/26    1.9   T.Kitajima       [T1_1177]件数制御修正
 *  2009/05/29    1.9   T.Kitajima       [T1_1120]org_id追加
 *  2009/06/02    1.10  N.Maeda          [T1_1192]端数処理(切上)の修正
 *  2009/07/17    1.11  N.Maeda          [T1_1438]ロック単位の変更
 *  2009/08/10    1.12  N.Maeda          [0000425]PT対応
 *  2009/09/04    1.13  N.Maeda          [0001211]消費税関連項目取得基準日修正
 *  2009/11/27    1.14  K.Atsushiba      [E_本稼動_00147]PT対応
 *  2010/02/03    1.15  N.Maeda          [E_本稼動_01441]入出庫データ連携時VDコラム取引用ヘッダ作成条件修正
 *  2010/03/18    1.16  S.Miyakoshi      [E_本稼動_01907]顧客使用目的、顧客所在地からの抽出時に有効条件追加
 *  2012/04/24    1.17  Y.Horikawa       [E_本稼動_09440]「売上値引金額」「売上消費税額」のマッピング不正の修正
 *  2014/10/16    1.18  Y.Enokido        [E_本稼動_09378]納品者の有効チェックを行う
 *  2014/11/27    1.19  K.Nakatsu        [E_本稼動_12599]汎用エラーリストテーブルへの出力追加
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
  insert_err_expt   EXCEPTION;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  global_ins_key_expt       EXCEPTION;                        -- 汎用エラーリスト登録例外（submainハンドリング用） 
  global_bulk_ins_expt      EXCEPTION;                        -- 汎用エラーリスト登録例外
  PRAGMA EXCEPTION_INIT(global_bulk_ins_expt, -24381);
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
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
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
  -- MO営業単位
  cv_pf_org_id       CONSTANT VARCHAR2(30)  := 'ORG_ID';              -- MO:営業単位
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
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
--****************************** 2014/11/27 1.19 K.Nakatsu DEL START ******************************--
--  cv_msg_parameter   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';       -- コンカレント入力パラメータなし
--****************************** 2014/11/27 1.19 K.Nakatsu DEL  END  ******************************--
-- *************** 2009/09/04 1.13 N.Maeda MOD START *****************************--
--  cv_msg_tax_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10352';       -- 参照コードマスタ及びAR消費税マスタ
  cv_msg_tax_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00190';       -- 消費税VIEW
-- *************** 2009/09/04 1.13 N.Maeda MOD  END  *****************************--
  cv_msg_inv_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10353';       -- 入出庫一時表
  cv_msg_vdh_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10354';       -- VDコラム別取引ヘッダテーブル
  cv_msg_vdl_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10355';       -- VDコラム別取引明細テーブル
  cv_msg_dlv_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10356';       -- 納品ヘッダテーブル及び納品明細テーブル
  cv_msg_dlv_h_table CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10357';       -- 納品ヘッダテーブル
  cv_msg_inv_cnt     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10358';       -- 入出庫情報抽出件数
  cv_msg_dlv_cnt     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00141';       -- 納品ヘッダ情報抽出件数
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10360';       -- 業務処理日取得エラー
  cv_msg_bks_id      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10361';       -- GL会計帳簿ID
  cv_msg_qck_error   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10362';       -- クイックコード取得エラーメッセージ
  cv_msg_invo_type   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10363';       -- 伝票区分
  cv_msg_dlv_cnt_l   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10364';       -- 納品明細情報抽出件数
  cv_msg_h_nor_cnt   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10365';       -- ヘッダ成功件数
  cv_msg_l_nor_cnt   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10366';       -- 明細成功件数
  cv_msg_input       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10043';       -- 入力区分
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
  cv_msg_mo          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';       -- MO:営業単位
  cv_data_loc        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00184';     -- 対象データロック中
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
--****************************** 2014/10/16 1.18 MOD START ******************************
  cv_empl_effect     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10367';       -- 納品者コード有効性チェック
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  cv_msg_cus_code    CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-00053';      -- 顧客コード
  cv_msg_dlv         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00080';      -- 納品者コード
  cv_msg_hht_inv_no  CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-00131';      -- HHT伝票No.
  cv_msg_dlv_date    CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-10169';      -- 納品日
  cv_msg_gen_errlst  CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-00213';      -- メッセージ用文字列
  cv_msg_err_out_flg CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-10260';      -- 汎用エラーリスト出力フラグ
  cv_tkn_err_out_flg CONSTANT VARCHAR2(30)  := 'GEN_ERR_OUT_FLAG';      -- 汎用エラーリスト出力フラグ
  cv_status_err_ins  CONSTANT VARCHAR2(1)   := '3';                     -- リターンコード
  cv_key_data        CONSTANT VARCHAR2(20)  := 'KEY_DATA';              -- 編集されたキー情報
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
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
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD START ******************************
  cv_tkn_a           CONSTANT VARCHAR2(1)   := 'A';                      -- 判定:A(有効)
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD END   ******************************
  cv_tkn_out         CONSTANT VARCHAR2(3)   := 'OUT';                    -- 出庫側
  cv_tkn_in          CONSTANT VARCHAR2(2)   := 'IN';                     -- 入庫側
  cv_default         CONSTANT VARCHAR2(1)   := '0';                      -- 初期値
  cv_one             CONSTANT VARCHAR2(1)   := '1';                      -- 判定:1
  cv_input_class     CONSTANT VARCHAR2(1)   := '5';                      -- テーブル・ロック条件
  cv_tkn_down        CONSTANT VARCHAR2(20)  := 'DOWN';                   -- 切捨て
  cv_tkn_up          CONSTANT VARCHAR2(20)  := 'UP';                     -- 切上げ
  cv_tkn_nearest     CONSTANT VARCHAR2(20)  := 'NEAREST';                -- 四捨五入
  cv_tkn_bill_to     CONSTANT VARCHAR2(20)  := 'BILL_TO';                -- BILL_TO
--******************** 2009/07/17 Ver1.11  N.Maeda ADD START ******************************************
  cv_tkn_order_number  CONSTANT  VARCHAR2(100)  :=  'ORDER_NUMBER';   -- 受注番号
  cv_digestion_ln_number CONSTANT VARCHAR2(20)  := 'DIGESTION_LN_NUMBER';  -- 枝番
  cv_invoice_no      CONSTANT VARCHAR2(20)  := 'INVOICE_NO';           -- HHT伝票番号
--******************** 2009/07/17 Ver1.11  N.Maeda ADD  END  ******************************************
--****************************** 2014/10/16 1.18 MOD START ******************************
  cv_hht_invoice_no  CONSTANT VARCHAR2(20)  := 'HHT_INVOICE_NO';       -- HHT伝票No.
  cv_customer_number CONSTANT VARCHAR2(20)  := 'CUSTOMER_NUMBER';      -- 顧客コード
  cv_dlv_by_code     CONSTANT VARCHAR2(20)  := 'DLV_BY_CODE';          -- 納品者コード
  cv_dlv_date        CONSTANT VARCHAR2(20)  := 'DLV_DATE';             -- 納品日
--****************************** 2014/10/16 1.18 MOD END   ******************************
--
  -- クイックコードタイプ
  cv_qck_typ_tax     CONSTANT VARCHAR2(30)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';    -- 消費税区分
  cv_qck_invo_type   CONSTANT VARCHAR2(30)  := 'XXCOS1_INVOICE_TYPE';             -- 伝票区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
  cv_qck_input_type  CONSTANT VARCHAR2(30)  := 'XXCOS1_VD_COL_INPUT_CLASS';       -- 入力区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
-- *************** 2009/08/10 1.12 N.Maeda ADD START *****************************--
  ct_user_lang       CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
-- *************** 2009/08/10 1.12 N.Maeda ADD  END  *****************************--
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
-- *************** 2009/09/04 1.13 N.Maeda ADD START *****************************--
      ,qck_start_date_active  fnd_lookup_values.start_date_active%TYPE        -- クイックコード適用開始日
      ,qck_end_date_active    fnd_lookup_values.end_date_active%TYPE          -- クイックコード適用終了日
-- *************** 2009/09/04 1.13 N.Maeda ADD  END  *****************************--
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
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD START ******************************************--
  TYPE g_get_inv_data_type IS RECORD
    (
      row_id              ROWID                                               -- 行ID
     ,order_no_hht        xxcos_dlv_headers.order_no_hht%TYPE                 -- 受注No.(HHT)
     ,digestion_ln_number xxcos_dlv_headers.digestion_ln_number%TYPE          -- 枝番
     ,hht_invoice_no      xxcos_dlv_headers.hht_invoice_no%TYPE               -- 伝票No.HHT
--****************************** 2014/10/16 1.18 MOD START ******************************
     ,customer_number     xxcos_dlv_headers.customer_number%TYPE              -- 顧客コード
     ,dlv_by_code         xxcos_dlv_headers.dlv_by_code%TYPE                  -- 納品者コード
     ,dlv_date            xxcos_dlv_headers.dlv_date%TYPE                     -- 納品日
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
     ,base_code           xxcos_dlv_headers.base_code%TYPE                    -- 拠点コード
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
    );
  TYPE g_tab_inv_data_type IS TABLE OF g_get_inv_data_type INDEX BY PLS_INTEGER;
--
  TYPE g_get_lines_type IS TABLE OF xxcos_vd_column_lines%ROWTYPE
  INDEX BY PLS_INTEGER;
--  TYPE g_get_lines_tab IS TABLE OF g_get_lines_type INDEX BY PLS_INTEGER;
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD  END  ******************************************--
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
  
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
  TYPE g_tab_set_clm_headers  IS TABLE OF      xxcos_vd_column_headers%ROWTYPE    INDEX BY PLS_INTEGER;
--
  TYPE g_rec_clm_headers IS RECORD
    (
     order_no_hht                    xxcos_vd_column_headers.order_no_hht%TYPE,            -- 受注No.(HHT)
     digestion_ln_number             xxcos_vd_column_headers.digestion_ln_number%TYPE,     -- 枝番
     order_no_ebs                    xxcos_vd_column_headers.order_no_ebs%TYPE,            -- 受注No.(EBS)
     base_code                       xxcos_vd_column_headers.base_code%TYPE,               -- 拠点コード
     performance_by_code             xxcos_vd_column_headers.performance_by_code%TYPE,     -- 成績者コード
     dlv_by_code                     xxcos_vd_column_headers.dlv_by_code%TYPE,             -- 納品者コード
     hht_invoice_no                  xxcos_vd_column_headers.hht_invoice_no%TYPE,          -- HHT伝票No.
     dlv_date                        xxcos_vd_column_headers.dlv_date%TYPE,                -- 納品日
     inspect_date                    xxcos_vd_column_headers.inspect_date%TYPE,            -- 検収日
     sales_classification            xxcos_vd_column_headers.sales_classification%TYPE,    -- 売上分類区分
     sales_invoice                   xxcos_vd_column_headers.sales_invoice%TYPE,           -- 売上伝票区分
     card_sale_class                 xxcos_vd_column_headers.card_sale_class%TYPE,         -- カード売区分
     dlv_time                        xxcos_vd_column_headers.dlv_time%TYPE,                -- 時間
     change_out_time_100             xxcos_vd_column_headers.change_out_time_100%TYPE,     -- つり銭切れ時間100円
     change_out_time_10              xxcos_vd_column_headers.change_out_time_10%TYPE,      -- つり銭切れ時間10円
     customer_number                 xxcos_vd_column_headers.customer_number%TYPE,         -- 顧客コード
     dlv_form                        xxcos_vd_column_headers.dlv_form%TYPE,-- 納品形態
     system_class                    xxcos_vd_column_headers.system_class%TYPE,            -- 業態区分
     invoice_type                    xxcos_vd_column_headers.invoice_type%TYPE,-- 伝票区分
     input_class                     xxcos_vd_column_headers.input_class%TYPE,             -- 入力区分
     consumption_tax_class           xxcos_vd_column_headers.consumption_tax_class%TYPE,   -- 消費税区分
     total_amount                    xxcos_vd_column_headers.total_amount%TYPE,            -- 合計金額
     sale_discount_amount            xxcos_vd_column_headers.sale_discount_amount%TYPE,    -- 売上値引額
     sales_consumption_tax           xxcos_vd_column_headers.sales_consumption_tax%TYPE,   -- 売上消費税額
     tax_include                     xxcos_vd_column_headers.tax_include%TYPE,             -- 税込金額
     keep_in_code                    xxcos_vd_column_headers.keep_in_code%TYPE,            -- 預け先コード
     department_screen_class         xxcos_vd_column_headers.department_screen_class%TYPE, -- 百貨店画面種別
     digestion_vd_rate_maked_date    xxcos_vd_column_headers.digestion_vd_rate_maked_date%TYPE,-- 消化VD掛率作成年月日
     red_black_flag                  xxcos_vd_column_headers.red_black_flag%TYPE,          -- 赤黒フラグ
     forward_flag                    xxcos_vd_column_headers.forward_flag%TYPE,-- 連携フラグ
     forward_date                    xxcos_vd_column_headers.forward_date%TYPE,-- 連携日付
     vd_results_forward_flag         xxcos_vd_column_headers.vd_results_forward_flag%TYPE,-- ベンダ納品実績情報連携済フラグ
     cancel_correct_class            xxcos_vd_column_headers.cancel_correct_class%TYPE,     -- 取消・訂正区分
     created_by                      xxcos_vd_column_headers.created_by%TYPE,-- 作成者
     creation_date                   xxcos_vd_column_headers.creation_date%TYPE,-- 作成日
     last_updated_by                 xxcos_vd_column_headers.last_updated_by%TYPE,-- 最終更新者
     last_update_date                xxcos_vd_column_headers.last_update_date%TYPE,-- 最終更新日
     last_update_login               xxcos_vd_column_headers.last_update_login%TYPE,-- 最終更新ログイン
     request_id                      xxcos_vd_column_headers.request_id%TYPE,-- 要求ID
     program_application_id          xxcos_vd_column_headers.program_application_id%TYPE,-- コンカレント・プログラム・アプリケーションID
     program_id                      xxcos_vd_column_headers.program_id%TYPE,-- コンカレント・プログラムID
     program_update_date             xxcos_vd_column_headers.program_update_date%TYPE,-- プログラム更新日
--******************** 2009/05/21 Ver1.9  T.Kitajima ADD START ******************************************
     h_rowid                         rowid                                                 -- レコードID
--******************** 2009/05/21 Ver1.9  T.Kitajima ADD  END  ******************************************

    );
  TYPE g_tab_clm_headers IS TABLE OF g_rec_clm_headers INDEX BY PLS_INTEGER;
--
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
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
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
  -- VDコラム別取引ヘッダテーブル登録用変数
  TYPE g_tab_digestion_ln_number         IS TABLE OF xxcos_vd_column_headers.digestion_ln_number%TYPE
    INDEX BY PLS_INTEGER;                --枝番
  TYPE g_tab_order_no_ebs                IS TABLE OF xxcos_vd_column_headers.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;                -- 受注No.(EBS)
  TYPE g_tab_sales_classification        IS TABLE OF xxcos_vd_column_headers.sales_classification%TYPE
    INDEX BY PLS_INTEGER;                -- 売上分類区分
  TYPE g_tab_sales_invoice               IS TABLE OF xxcos_vd_column_headers.sales_invoice%TYPE
    INDEX BY PLS_INTEGER;                -- 売上伝票区分
  TYPE g_tab_card_sale_class             IS TABLE OF xxcos_vd_column_headers.card_sale_class%TYPE
    INDEX BY PLS_INTEGER;                -- カード売区分
  TYPE g_tab_dlv_time                    IS TABLE OF xxcos_vd_column_headers.dlv_time%TYPE
    INDEX BY PLS_INTEGER;                -- 時間
  TYPE g_tab_change_out_time_100         IS TABLE OF xxcos_vd_column_headers.change_out_time_100%TYPE
    INDEX BY PLS_INTEGER;                -- つり銭切れ時間100円
  TYPE g_tab_change_out_time_10          IS TABLE OF xxcos_vd_column_headers.change_out_time_10%TYPE
    INDEX BY PLS_INTEGER;                -- つり銭切れ時間10円
  TYPE g_tab_dlv_form                    IS TABLE OF xxcos_vd_column_headers.dlv_form%TYPE
    INDEX BY PLS_INTEGER;                -- 納品形態
  TYPE g_tab_sale_discount_amount        IS TABLE OF xxcos_vd_column_headers.sale_discount_amount%TYPE
    INDEX BY PLS_INTEGER;                -- 売上値引額
  TYPE g_tab_keep_in_code                IS TABLE OF xxcos_vd_column_headers.keep_in_code%TYPE
    INDEX BY PLS_INTEGER;                -- 預け先コード
  TYPE g_tab_department_screen_class     IS TABLE OF xxcos_vd_column_headers.department_screen_class%TYPE
    INDEX BY PLS_INTEGER;                -- 百貨店画面種別
  TYPE g_tab_digestion_vd_r_mak_d        IS TABLE OF xxcos_vd_column_headers.digestion_vd_rate_maked_date%TYPE--
    INDEX BY PLS_INTEGER;                -- 消化VD掛率作成年月日
  TYPE g_tab_forward_flag                IS TABLE OF xxcos_vd_column_headers.forward_flag%TYPE
    INDEX BY PLS_INTEGER;                -- 連携フラグ
  TYPE g_tab_forward_date                IS TABLE OF xxcos_vd_column_headers.forward_date%TYPE
    INDEX BY PLS_INTEGER;                -- 連携日付
  TYPE g_tab_vd_results_forward_f        IS TABLE OF xxcos_vd_column_headers.vd_results_forward_flag%TYPE--
    INDEX BY PLS_INTEGER;                 -- ベンダ納品実績情報連携済フラグ
  TYPE g_tab_created_by                  IS TABLE OF xxcos_vd_column_headers.created_by%TYPE
    INDEX BY PLS_INTEGER;                -- 作成者
  TYPE g_tab_creation_date               IS TABLE OF xxcos_vd_column_headers.creation_date%TYPE
    INDEX BY PLS_INTEGER;                -- 作成日
  TYPE g_tab_last_updated_by             IS TABLE OF xxcos_vd_column_headers.last_updated_by%TYPE
    INDEX BY PLS_INTEGER;                -- 最終更新者
  TYPE g_tab_last_update_date            IS TABLE OF xxcos_vd_column_headers.last_update_date%TYPE 
    INDEX BY PLS_INTEGER;                -- 最終更新日
  TYPE g_tab_last_update_login           IS TABLE OF xxcos_vd_column_headers.last_update_login%TYPE
    INDEX BY PLS_INTEGER;                -- 最終更新ログイン
  TYPE g_tab_request_id                  IS TABLE OF xxcos_vd_column_headers.request_id%TYPE 
    INDEX BY PLS_INTEGER;                -- 要求ID
  TYPE g_tab_program_appli_id            IS TABLE OF xxcos_vd_column_headers.program_application_id%TYPE
    INDEX BY PLS_INTEGER;                -- コンカレント・プログラム・アプリケーションID
  TYPE g_tab_program_id                  IS TABLE OF xxcos_vd_column_headers.program_id%TYPE
    INDEX BY PLS_INTEGER;                -- コンカレント・プログラムID
  TYPE g_tab_program_update_date         IS TABLE OF xxcos_vd_column_headers.program_update_date%TYPE
    INDEX BY PLS_INTEGER;                -- プログラム更新日
  --VDコラム別取引情報更新用変数
  TYPE g_tab_vd_row_id                   IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;                -- 行ID
  TYPE g_tab_vd_can_cor_class            IS TABLE OF xxcos_vd_column_headers.cancel_correct_class%TYPE
    INDEX BY PLS_INTEGER;                -- 取消訂正区分
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  TYPE g_err_key_ttype                   IS TABLE OF xxcos_gen_err_list%ROWTYPE
    INDEX BY BINARY_INTEGER;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
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
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ***************************************--
  gt_dev_set_order_noh_hht          g_tab_order_noh_hht;            -- 受注No.(HHT)
  gt_dev_set_digestion_ln           g_tab_digestion_ln_number;      -- 枝番
  gt_dev_set_order_no_ebs           g_tab_order_no_ebs;             -- 受注No.(EBS)
  gt_dev_set_base_code              g_tab_base_code;                -- 拠点コード
  gt_dev_set_perform_code           g_tab_performance_by_code;      -- 成績者コード
  gt_dev_set_dlv_code               g_tab_dlv_by_code;              -- 納品者コード
  gt_dev_set_invoice_no             g_tab_hht_invoice_no;           -- HHT伝票No.
  gt_dev_set_dlv_date               g_tab_dlv_date;                 -- 納品日
  gt_dev_set_inspect_date           g_tab_inspect_date;             -- 検収日
  gt_dev_set_sales_classif          g_tab_sales_classification;     -- 売上分類区分
  gt_dev_set_sales_invoice          g_tab_sales_invoice;            -- 売上伝票区分
  gt_dev_set_card_sale_class        g_tab_card_sale_class;          -- カード売区分
  gt_dev_set_dlv_time               g_tab_dlv_time;                 -- 時間
  gt_dev_set_out_time_100           g_tab_change_out_time_100;      -- つり銭切れ時間100円
  gt_dev_set_out_time_10            g_tab_change_out_time_10;       -- つり銭切れ時間10円
  gt_dev_set_cus_number             g_tab_customer_number;          -- 顧客コード
  gt_dev_set_dlv_form               g_tab_dlv_form;                 -- 納品形態
  gt_dev_set_system_class           g_tab_system_class;             -- 業態区分
  gt_dev_set_invoice_type           g_tab_invoice_type;             -- 伝票区分
  gt_dev_set_input_class            g_tab_gt_input_class;           --  入力区分
  gt_dev_set_tax_class              g_tab_consumption_tax_class;    -- 消費税区分
  gt_dev_set_total_amount           g_tab_total_amount;             -- 合計金額
  gt_dev_set_sales_tax              g_tab_sales_consumption_tax;    -- 売上消費税額
  gt_dev_set_sale_discount_a        g_tab_sale_discount_amount;     -- 税込値引額
  gt_dev_set_tax_include            g_tab_tax_include;              -- 税込金額
  gt_dev_set_keep_in_code           g_tab_keep_in_code;             -- 預け先コード
  gt_dev_set_depart_sc_clas         g_tab_department_screen_class;  -- 百貨店画面種別
  gt_dev_set_dig_vd_r_mak_d         g_tab_digestion_vd_r_mak_d;-- 消化VD掛率作成年月日
  gt_dev_set_red_black_flag         g_tab_red_black_flag;           -- 赤黒フラグ
  gt_dev_set_forward_flag           g_tab_forward_flag;             -- 連携フラグ
  gt_dev_set_forward_date           g_tab_forward_date;             -- 連携日付
  gt_dev_set_vd_results_for_f       g_tab_vd_results_forward_f;  -- ベンダ納品実績情報連携済フラグ
  gt_dev_set_cancel_correct         g_tab_cancel_correct_class;     -- 取消・訂正区分
  gt_dev_set_created_by             g_tab_created_by;               -- 作成者
  gt_dev_set_creation_date          g_tab_creation_date;            -- 作成日
  gt_dev_set_last_updated_by        g_tab_last_updated_by;          -- 最終更新者
  gt_dev_set_last_update_date       g_tab_last_update_date;         -- 最終更新日
  gt_dev_set_last_update_logi       g_tab_last_update_login;        -- 最終更新ログイン
  gt_dev_set_request_id             g_tab_request_id;               -- 要求ID
  gt_dev_set_program_appli_id       g_tab_program_appli_id;         -- コンカレント・プログラム・アプリケーションID
  gt_dev_set_program_id             g_tab_program_id;               -- コンカレント・プログラムID
  gt_dev_set_program_update_d       g_tab_program_update_date;      -- プログラム更新日
  gt_vd_row_id                      g_tab_vd_row_id;                 -- VDカラム別取引情報-行ID
  gt_vd_can_cor_class               g_tab_vd_can_cor_class;          -- VDカラム別取引情報-取消訂正区分
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ***************************************--
--******************** 2009/05/21 Ver1.9  T.Kitajima ADD START ******************************************
  gt_dlv_headers_row_id             g_tab_vd_row_id;                 -- 納品ヘッダテーブルレコードID
--******************** 2009/05/21 Ver1.9  T.Kitajima ADD  END  ******************************************
--
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  gt_err_key_msg_tab                g_err_key_ttype;                -- 汎用エラーリスト用keyメッセージ
  gv_prm_gen_err_out_flag           VARCHAR2(1);                    -- 汎用エラーリスト出力フラグ
  gn_msg_cnt                        NUMBER;                         -- 汎用エラーリスト用メッセージ件数
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
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
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
  gt_clm_headers        g_tab_clm_headers;              -- 納品ヘッダデータ格納用
  gt_set_clm_headers    g_tab_set_clm_headers;          -- 
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD START ******************************************--
  gt_inv_data_tab      g_tab_inv_data_type;            -- 対象伝票情報格納用
  gt_lines_tab         g_get_lines_type;                 -- 納品明細情報
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD  END  ******************************************--
  gd_process_date       DATE;                           -- 業務処理日
  gd_max_date           DATE;                           -- MAX日付
  gv_bks_id             VARCHAR2(50);                   -- GL会計帳簿ID
  gv_tkn1               VARCHAR2(50);                   -- エラーメッセージ用トークン１
  gv_tkn2               VARCHAR2(50);                   -- エラーメッセージ用トークン２
  gv_tkn3               VARCHAR2(50);                   -- エラーメッセージ用トークン３
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  gv_tkn4               VARCHAR2(2000);                 -- エラーメッセージ用トークン４
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
  gt_org_id             fnd_profile_option_values.profile_option_value%TYPE;      -- MO:営業単位
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
  gt_tr_count           NUMBER := 0;
  gt_insert_h_count     NUMBER := 0;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
    lv_para_msg      VARCHAR2(100);     -- パラメータ出力
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
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
--****************************** 2014/11/27 1.19 K.Nakatsu MOD START ******************************--
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
--    -- 「コンカレント入力パラメータなし」メッセージを出力
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
--    );
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => ''
--    );
----
--    --==============================================================
--    --「コンカレント入力パラメータなし」メッセージをログ出力
--    --==============================================================
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => ''
--    );
--    -- メッセージログ
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
--    );
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => ''
--    );
    -- パラメータ出力
    lv_para_msg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_application
                       , iv_name          =>  cv_msg_err_out_flg
                       , iv_token_name1   =>  cv_tkn_err_out_flg
                       , iv_token_value1  =>  gv_prm_gen_err_out_flag
                     );
--
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  lv_para_msg
    );
--
    --1行空白
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  NULL
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  NULL
    );
--
    -- メッセージログ
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  lv_para_msg
    );
--****************************** 2014/11/27 1.19 K.Nakatsu DEL  END  ******************************--
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
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
    -- ===============================
    --  MO:営業単位取得
    -- ===============================
    gt_org_id := FND_PROFILE.VALUE( cv_pf_org_id );
--
    -- プロファイル取得エラーの場合
    IF ( gt_org_id IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_mo );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
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
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
-- *************** 2009/09/04 1.13 N.Maeda MOD START *****************************--
      SELECT  xtv.tax_rate        tax_rate      -- 消費税率
             ,xtv.tax_code        tax_code      -- 税金コード
             ,xtv.hht_tax_class   tax_class -- 消費税区分
             ,xtv.start_date_active start_date_active -- 適用開始日
             ,xtv.end_date_active   end_date_active   -- 適用終了日
      FROM   xxcos_tax_v xtv
      WHERE  xtv.set_of_books_id = gl_id
      ;
--      SELECT tax.tax_rate  tax_rate,  -- 消費税率
--             tax.tax_code  tax_code,  -- 消費税コード
--             qck.cla       cla        -- 消費税区分
--      FROM   ar_vat_tax_all_b tax,    -- 税コードマスタ
--             (
---- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
--               SELECT look_val.attribute2   code,   -- 消費税コード
--                      look_val.attribute3   cla     -- 消費税区分
--               FROM   fnd_lookup_values     look_val
--               WHERE  look_val.lookup_type       = cv_qck_typ_tax       -- タイプ＝XXCOS1_CONSUMPTION_TAX_CLASS
--               AND    look_val.enabled_flag      = cv_tkn_yes           -- 使用可能＝Y
--               AND    gd_process_date           >= NVL(look_val.start_date_active, gd_process_date)
--               AND    gd_process_date           <= NVL(look_val.end_date_active, gd_max_date)
--               AND    look_val.language          = ct_user_lang    -- 言語＝JA
--               ORDER BY look_val.attribute3
----
----               SELECT look_val.attribute2   code,   -- 消費税コード
----                      look_val.attribute3   cla     -- 消費税区分
----               FROM   fnd_lookup_values     look_val,
----                      fnd_lookup_types_tl   types_tl,
----                      fnd_lookup_types      types,
----                      fnd_application_tl    appl,
----                      fnd_application       app
----               WHERE  app.application_short_name = cv_application       -- XXCOS
----               AND    look_val.lookup_type       = cv_qck_typ_tax       -- タイプ＝XXCOS1_CONSUMPTION_TAX_CLASS
----               AND    look_val.enabled_flag      = cv_tkn_yes           -- 使用可能＝Y
----               AND    gd_process_date           >= NVL(look_val.start_date_active, gd_process_date)
----               AND    gd_process_date           <= NVL(look_val.end_date_active, gd_max_date)
----               AND    types_tl.language          = USERENV( 'LANG' )    -- 言語＝JA
----               AND    look_val.language          = USERENV( 'LANG' )    -- 言語＝JA
----               AND    appl.language              = USERENV( 'LANG' )    -- 言語＝JA
----               AND    appl.application_id        = types.application_id
----               AND    app.application_id         = appl.application_id
----               AND    types_tl.lookup_type       = look_val.lookup_type
----               AND    types.lookup_type          = types_tl.lookup_type
----               AND    types.security_group_id    = types_tl.security_group_id
----               AND    types.view_application_id  = types_tl.view_application_id
----               ORDER BY look_val.attribute3
---- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
--             ) qck
--      WHERE  tax.tax_code        = qck.code
--      AND    tax.set_of_books_id = gl_id                -- GL会計帳簿ID
--      AND    tax.enabled_flag    = cv_tkn_yes           -- 使用可能＝Y
--      AND    gd_process_date    >= NVL(tax.start_date, gd_process_date)
--      AND    gd_process_date    <= NVL(tax.end_date, gd_max_date)
--      ;
-- *************** 2009/09/04 1.13 N.Maeda MOD  END  *****************************--
--
    -- クイックコード：伝票区分
    CURSOR get_invoice_type_cur
    IS
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
      SELECT  look_val.lookup_code  lookup_code,  -- 伝票区分
              look_val.attribute1   form,         -- 伝票区分による形態
              look_val.attribute2   judge         -- 数量加工判定
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.lookup_type  = cv_qck_invo_type
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.language     = ct_user_lang;
--
--      SELECT  look_val.lookup_code  lookup_code,  -- 伝票区分
--              look_val.attribute1   form,         -- 伝票区分による形態
--              look_val.attribute2   judge         -- 数量加工判定
--      FROM    fnd_lookup_values     look_val
--             ,fnd_lookup_types_tl   types_tl
--             ,fnd_lookup_types      types
--             ,fnd_application_tl    appl
--             ,fnd_application       app
--      WHERE   app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_invo_type
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     types_tl.language     = USERENV( 'LANG' )
--      AND     look_val.language     = USERENV( 'LANG' )
--      AND     appl.language         = USERENV( 'LANG' )
--      AND     appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id;
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
    -- クイックコード：入力区分
    CURSOR get_input_type_cur
    IS
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
      SELECT  look_val.meaning      slip_class,         -- 伝票区分
              look_val.attribute1   input_class         -- 伝票区分による形態
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.lookup_type  = cv_qck_input_type
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.language     = ct_user_lang;
--
--      SELECT  look_val.meaning      slip_class,         -- 伝票区分
--              look_val.attribute1   input_class         -- 伝票区分による形態
--      FROM    fnd_lookup_values     look_val
--             ,fnd_lookup_types_tl   types_tl
--             ,fnd_lookup_types      types
--             ,fnd_application_tl    appl
--             ,fnd_application       app
--      WHERE   app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_input_type
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     types_tl.language     = USERENV( 'LANG' )
--      AND     look_val.language     = USERENV( 'LANG' )
--      AND     appl.language         = USERENV( 'LANG' )
--      AND     appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id;
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--
    -- 入出庫一時表対象レコードロック
    CURSOR get_inv_lock_cur
    IS
      SELECT  
-- *************** 2009/08/10 1.12 N.Maeda ADD START *****************************--
              /*+
                INDEX (inv XXCOI_HHT_INV_TRANSACTIONS_N06 )
              */
-- *************** 2009/08/10 1.12 N.Maeda ADD  END  *****************************--
              inv.last_updated_by         last_up  -- 最終更新者
      FROM    xxcoi_hht_inv_transactions  inv      -- 入出庫一時表
      WHERE   inv.invoice_type IN (
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
                                    SELECT  look_val.lookup_code  code
                                    FROM    fnd_lookup_values     look_val
                                    WHERE   look_val.lookup_type  = cv_qck_invo_type
                                    AND     look_val.enabled_flag = cv_tkn_yes
                                    AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                                    AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                                    AND     look_val.language     = ct_user_lang
--
--                                    SELECT  look_val.lookup_code  code
--                                    FROM    fnd_lookup_values     look_val
--                                           ,fnd_lookup_types_tl   types_tl
--                                           ,fnd_lookup_types      types
--                                           ,fnd_application_tl    appl
--                                           ,fnd_application       app
--                                    WHERE   app.application_short_name = cv_application
--                                    AND     look_val.lookup_type  = cv_qck_invo_type
--                                    AND     look_val.enabled_flag = cv_tkn_yes
--                                    AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                                    AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                                    AND     types_tl.language     = USERENV( 'LANG' )
--                                    AND     look_val.language     = USERENV( 'LANG' )
--                                    AND     appl.language         = USERENV( 'LANG' )
--                                    AND     appl.application_id   = types.application_id
--                                    AND     app.application_id    = appl.application_id
--                                    AND     types_tl.lookup_type  = look_val.lookup_type
--                                    AND     types.lookup_type     = types_tl.lookup_type
--                                    AND     types.security_group_id   = types_tl.security_group_id
--                                    AND     types.view_application_id = types_tl.view_application_id
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
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
        SELECT
-- *************** 2009/08/10 1.12 N.Maeda ADD START *****************************--
-- *************** 2009/11/27 1.14 K.Atsushiba Mod START *****************************--
             /*+
               INDEX ( vd XXCOI_MST_VD_COLUMN_U01 )
               INDEX (ACCT HZ_CUST_ACCT_SITES_N3)
             */
--             /*+
--               INDEX ( vd XXCOI_MST_VD_COLUMN_U01 )
--             */
-- *************** 2009/11/27 1.14 K.Atsushiba Mod End *****************************--
-- *************** 2009/08/10 1.12 N.Maeda ADD  END  *****************************--
                 inv.base_code                 base_code                    -- 拠点コード
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
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
                   SELECT  look_val.lookup_code  code
                   FROM    fnd_lookup_values     look_val
                   WHERE   look_val.lookup_type  = cv_qck_invo_type
                   AND     look_val.enabled_flag = cv_tkn_yes
                   AND     look_val.attribute1   = cv_tkn_out
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.language     = ct_user_lang
--
--                   SELECT  look_val.lookup_code  code
--                   FROM    fnd_lookup_values     look_val
--                          ,fnd_lookup_types_tl   types_tl
--                          ,fnd_lookup_types      types
--                          ,fnd_application_tl    appl
--                          ,fnd_application       app
--                   WHERE   app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_invo_type
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                   AND     look_val.attribute1   = cv_tkn_out
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     types_tl.language     = USERENV( 'LANG' )
--                   AND     look_val.language     = USERENV( 'LANG' )
--                   AND     appl.language         = USERENV( 'LANG' )
--                   AND     appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
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
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
          AND    acct.org_id            = gt_org_id               -- 顧客所在地.ORG_ID＝1145
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
          AND    site.site_use_code     = cv_tkn_bill_to          -- 顧客使用目的.使用目的＝BILL_TO
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD START ******************************
          AND    acct.status            = cv_tkn_a                --顧客所在地.ステータス   = 'A'(有効)
          AND    site.status            = cv_tkn_a                --顧客使用目的.ステータス = 'A'(有効)
          AND    site.primary_flag      = cv_tkn_yes              --顧客使用目的.主フラグ   = 'Y'(有効)
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD END   ******************************
--************************* 2009/04/16 N.Maeda Ver1.5 MOD START ****************************************************
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
--************************* 2009/04/16 N.Maeda Ver1.5 MOD END ******************************************************
          ORDER BY  inv.base_code              -- 拠点コード
                   ,inv.outside_cust_code      -- 出庫側顧客コード
                   ,inv.invoice_no             -- 伝票No.
                   ,inv.column_no              -- コラムNo.
        )
--
      UNION ALL
--
      SELECT
-- *************** 2009/08/10 1.12 N.Maeda ADD START *****************************--
             /*+
               INDEX ( vd XXCOI_MST_VD_COLUMN_U01 )
             */
-- *************** 2009/08/10 1.12 N.Maeda ADD  END  *****************************--
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
-- *************** 2009/11/27 1.14 K.Atsushiba Mod START *****************************--
          SELECT
        /*+
          INDEX(XSV.hopeb HZ_ORG_PROFILES_EXT_B_N1)
          INDEX(XSV.hopeb hz_org_profiles_ext_b_n1)
          INDEX(INV XXCOI_HHT_INV_TRANSACTIONS_N06)
          INDEX(ACCT HZ_CUST_ACCT_SITES_N3)
        */
                 inv.base_code                 base_code                    -- 拠点コード
--          SELECT inv.base_code                 base_code                    -- 拠点コード
-- *************** 2009/11/27 1.14 K.Atsushiba Mod End *****************************--
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
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
                   SELECT  look_val.lookup_code  code
                   FROM    fnd_lookup_values     look_val
                   WHERE   look_val.lookup_type  = cv_qck_invo_type
                   AND     look_val.enabled_flag = cv_tkn_yes
                   AND     look_val.attribute1   = cv_tkn_in
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.language     = ct_user_lang
--
--                   SELECT  look_val.lookup_code  code
--                   FROM    fnd_lookup_values     look_val
--                          ,fnd_lookup_types_tl   types_tl
--                          ,fnd_lookup_types      types
--                          ,fnd_application_tl    appl
--                          ,fnd_application       app
--                   WHERE   app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_invo_type
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                   AND     look_val.attribute1   = cv_tkn_in
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     types_tl.language     = USERENV( 'LANG' )
--                   AND     look_val.language     = USERENV( 'LANG' )
--                   AND     appl.language         = USERENV( 'LANG' )
--                   AND     appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
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
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
          AND    acct.org_id            = gt_org_id               -- 顧客所在地.ORG_ID＝1145
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
          AND    site.site_use_code     = cv_tkn_bill_to          -- 顧客使用目的.使用目的＝BILL_TO
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD START ******************************
          AND    acct.status            = cv_tkn_a                --顧客所在地.ステータス   = 'A'(有効)
          AND    site.status            = cv_tkn_a                --顧客使用目的.ステータス = 'A'(有効)
          AND    site.primary_flag      = cv_tkn_yes              --顧客使用目的.主フラグ   = 'Y'(有効)
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD END   ******************************
--************************* 2009/04/16 N.Maeda Ver1.5 MOD START ****************************************************
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
--************************* 2009/04/16 N.Maeda Ver1.5 MOD END ******************************************************
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
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--************************* 2009/04/15 N.Maeda Ver1.4 ADD START ****************************************************
    lt_vd_replenish_number xxcos_vd_column_lines.replenish_number%TYPE;                -- 補充数(数量加工用)
    lt_vd_case_quant       xxcoi_hht_inv_transactions.case_quantity%TYPE;              -- ケース数(数量加工用)
--************************* 2009/04/15 N.Maeda Ver1.4 ADD END ******************************************************
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
    lt_transaction_id      xxcoi_hht_inv_transactions.transaction_id%TYPE;             -- 入出庫一時表ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
    lt_input_class         xxcos_vd_column_headers.input_class%TYPE;                   -- 入力区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
-- ************ 2010/02/03 1.15 N.Maeda MOD START ************ --
    lt_next_index_customer xxcos_vd_column_headers.customer_number%TYPE;               -- ヘッダ作成判定用顧客コード
    lv_next_form           VARCHAR(3);                                                 -- ヘッダ作成判定用伝票区分による形態
-- ************ 2010/02/03 1.15 N.Maeda MOD  END  ************ --
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
--************************* 2009/04/15 N.Maeda Ver1.4 ADD START ****************************************************
        lt_vd_replenish_number := lt_replenish_number * -1;
        lt_vd_case_quant       := lt_case_quant * -1;
--************************* 2009/04/15 N.Maeda Ver1.4 ADD END ******************************************************
      ELSE
        lt_vd_quantity := lt_quantity;
--************************* 2009/04/15 N.Maeda Ver1.4 ADD START ****************************************************
        lt_vd_replenish_number := lt_replenish_number;
        lt_vd_case_quant       := lt_case_quant;
--************************* 2009/04/15 N.Maeda Ver1.4 ADD END ******************************************************
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
-- *************** 2009/09/04 1.13 N.Maeda MOD START *****************************--
--        IF ( gt_tax_rate(i).tax_class = lt_tax_div ) THEN
        -- クイックコード消費税区分 = 消費税区分
        IF  ( gt_tax_rate(i).tax_class = lt_tax_div )
        -- 伝票日付 ≧ NVL( クイックコード適用開始日 , 伝票日付 )
        AND ( lt_invoice_date >= NVL( gt_tax_rate(i).qck_start_date_active,lt_invoice_date ) )
        -- 伝票日付 ≦ NVL( クイックコード適用終了日 , A-0で取得したMAX日付 )
        AND ( lt_invoice_date <= NVL( gt_tax_rate(i).qck_end_date_active, gd_max_date ) ) THEN
-- *************** 2009/09/04 1.13 N.Maeda MOD  END  *****************************--
          ln_rate := 1 + gt_tax_rate(i).rate / 100;     -- 税率をセット
          EXIT;
        END IF;
--
      END LOOP;
--
      --==============================================================
      -- 合計金額の導出（ヘッダ部）
      --==============================================================
--************************* 2009/04/15 N.Maeda Ver1.4 MOD START ****************************************************
--      -- 補充数×単価
--      lt_total_amount := lt_total_amount + lt_replenish_number * lt_unit_price;
      -- 補充数×単価
      lt_total_amount := lt_total_amount + lt_vd_replenish_number * lt_unit_price;
--************************* 2009/04/15 N.Maeda Ver1.4 MOD END ******************************************************
--
      --==============================================================
      -- 税込み金額の導出（ヘッダ部）
      --==============================================================
--************************* 2009/04/15 N.Maeda Ver1.4 MOD START ****************************************************
--      -- 本数×VDコラムマスタの単価
--      lt_tax_include_tempo := lt_replenish_number * lt_inv_price;
      -- 本数×VDコラムマスタの単価
      lt_tax_include_tempo := lt_vd_replenish_number * lt_inv_price;
--************************* 2009/04/15 N.Maeda Ver1.4 MOD END ******************************************************
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
--*************************** 2009/06/02 Ver1.10 N.Maeda MOD START *****************************--
      -- 端数発生時処理
      IF ( lt_sales_tax_tempo <> TRUNC(lt_sales_tax_tempo) ) THEN
--
        -- 小数点以下の処理
        IF ( lt_tax_round_rule = cv_tkn_down ) THEN        -- 切捨て処理
--
          lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo );
--
        ELSIF ( lt_tax_round_rule = cv_tkn_up ) THEN       -- 切上げ処理
--
--          lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo + .9 );
--
          IF ( SIGN( lt_sales_tax_tempo ) <> -1 ) THEN
--
            lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo) + 1;
--
          ELSE
--
            lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo) - 1;
--
          END IF;
--
        ELSIF ( lt_tax_round_rule = cv_tkn_nearest ) THEN  -- 四捨五入処理
--
          lt_sales_tax_tempo := ROUND( lt_sales_tax_tempo );
--
        END IF;
--
--*************************** 2009/06/02 Ver1.10 N.Maeda MOD  END  *****************************--
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
--************************* 2009/04/16 N.Maeda Ver1.5 MOD START ****************************************************
--************************* 2009/04/15 N.Maeda Ver1.4 MOD START ****************************************************
--      gt_case_number(ln_inv_lines_num)    := lt_case_quant;        -- ケース数
--      gt_case_number(ln_inv_lines_num)    := lt_vd_replenish_number;        -- ケース数
--************************* 2009/04/15 N.Maeda Ver1.4 MOD END ******************************************************
      gt_case_number(ln_inv_lines_num)    := lt_vd_case_quant;        -- ケース数
--************************* 2009/04/16 N.Maeda Ver1.5 MOD END ******************************************************
      gt_quantity(ln_inv_lines_num)       := lt_vd_quantity;       -- 数量
      gt_wholesale(ln_inv_lines_num)      := lt_unit_price;        -- 卸単価
      gt_column_no(ln_inv_lines_num)      := lt_column_no;         -- コラムNo.
      gt_h_and_c(ln_inv_lines_num)        := lt_hot_cold_div;      -- H/C
--************************* 2009/04/15 N.Maeda Ver1.4 MOD START ****************************************************
--      gt_replenish_num(ln_inv_lines_num)  := lt_replenish_number;  -- 補充数
      gt_replenish_num(ln_inv_lines_num)  := lt_vd_replenish_number;  -- 補充数
--************************* 2009/04/15 N.Maeda Ver1.4 MOD END ******************************************************
----****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
      gt_transaction_id(ln_inv_lines_num) := lt_transaction_id;     -- 入出庫一時表ID
----****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
      gt_input_class(ln_inv_lines_num)    := lt_input_class;        -- 入力区分
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
      ln_line_no := ln_line_no + 1;                                -- 行No.(HHT)更新
      ln_inv_lines_num := ln_inv_lines_num + 1;                    -- 入出庫明細件数ナンバー更新
--
-- ************ 2010/02/03 1.15 N.Maeda ADD START ************ --
--
      -- 最終レコードでなければ次顧客情報を取得します。
      IF ( inv_no != gn_inv_target_cnt ) THEN
        --== 次データ出庫側、入庫側判定 ==--
        FOR i IN 1..gt_qck_invoice_type.COUNT LOOP
          IF ( gt_qck_invoice_type(i).invoice_type = gt_inv_data(inv_no + 1).invoice_type ) THEN
            lv_next_form   := gt_qck_invoice_type(i).form;     -- 伝票区分による形態をセット
            EXIT;
          END IF;
        END LOOP;
--
        --== 顧客コードセット判定 ==--
        IF ( lv_next_form = cv_tkn_out ) THEN         -- 出庫側の場合
          lt_next_index_customer := gt_inv_data(inv_no + 1).out_cus_code;
        ELSIF ( lv_next_form = cv_tkn_in ) THEN       -- 入庫側の場合
          lt_next_index_customer := gt_inv_data(inv_no + 1).in_cus_code;
        END IF;
      END IF;
--
-- ************ 2010/02/03 1.15 N.Maeda ADD  END  ************ --
--
      IF ( inv_no = gn_inv_target_cnt ) THEN    -- ループが最後の場合
--
        -- ヘッダ対象件数カウントアップ
        gt_tr_count := gt_tr_count + 1;
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
-- ************ 2010/02/03 1.15 N.Maeda MOD START ************ --
--      ELSIF ( lt_invoice_no != gt_inv_data(inv_no + 1).invoice_no ) THEN
      ELSIF ( lt_invoice_no != gt_inv_data(inv_no + 1).invoice_no )
         OR ( lt_base_code  != gt_inv_data(inv_no + 1).base_code )
         OR ( lt_customer_number != lt_next_index_customer ) THEN
-- ************ 2010/02/03 1.15 N.Maeda MOD  END  ************ --
--
        -- ヘッダ対象件数カウントアップ
        gt_tr_count := gt_tr_count + 1;
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
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--******************** 2009/05/26 Ver1.9  T.Kitajima MOD START ******************************************
--      on_normal_cnt := SQL%ROWCOUNT;
      on_normal_cnt := gt_order_noh_hht.COUNT;
--******************** 2009/05/26 Ver1.9  T.Kitajima MOD  END  ******************************************
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
--******************** 2009/05/26 Ver1.9  T.Kitajima MOD START ******************************************
--      on_normal_cnt_l := SQL%ROWCOUNT;
      on_normal_cnt_l := gt_order_nol_hht.COUNT;
--******************** 2009/05/26 Ver1.9  T.Kitajima MOD  END  ******************************************
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
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lt_order_no_hht                    xxcos_vd_column_headers.order_no_hht%TYPE;      --伝票No.(HHT)
    lt_cancel_correct_class            xxcos_vd_column_headers.cancel_correct_class%TYPE; --枝番最大値の取消し訂正区分
    lt_min_digestion_ln_number         xxcos_vd_column_headers.digestion_ln_number%TYPE;  --枝番最小値
    ln_vd_data_count                   NUMBER;
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD START ******************************************--
    lt_inv_row_id                      ROWID;                                             -- 対象ヘッダ行ID
    lt_inv_order_no_hht                xxcos_dlv_headers.order_no_hht%TYPE;               -- 受注No.(HHT)
    lt_inv_digestion_ln_number         xxcos_dlv_headers.digestion_ln_number%TYPE;        -- 枝番
    lt_inv_hht_invoice_no              xxcos_dlv_headers.hht_invoice_no%TYPE;             -- HHT伝票No.
    lt_lock_brak_order_no_hht          xxcos_dlv_headers.order_no_hht%TYPE;               -- ロック済み受注No.(HHT)
    lt_lock_err_order_no_hht          xxcos_dlv_headers.order_no_hht%TYPE;                -- ロックエラー受注No.(HHT)
    lt_data_count                      NUMBER;
    lt_dlv_line_count                  NUMBER;
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD  END  ******************************************--
--****************************** 2014/10/16 1.18 MOD START ******************************
    lt_inv_customer_number             xxcos_dlv_headers.customer_number%TYPE;            -- 顧客コード
    lt_inv_dlv_by_code                 xxcos_dlv_headers.dlv_by_code%TYPE;                -- 納品者コード
    lt_inv_dlv_date                    xxcos_dlv_headers.dlv_date%TYPE;                   -- 納品日
    lt_inv_dlv_date_yyyymmdd           VARCHAR2(10);                                      -- 納品日（メッセージ出力用）
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
    lt_inv_base_code                   xxcos_dlv_headers.base_code%TYPE;                  -- 拠点コード
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
    -- *** ローカル・カーソル ***
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD START ******************************************--
    -- 対象伝票取得カーソル
    CURSOR get_inv_cur
    IS
      SELECT /*+
               leading (head)
               INDEX   ( HEAD XXCOS_DLV_HEADERS_N02 )
               USE_NL  (LINE)
             */
             DISTINCT
             head.ROWID                      row_id                    -- 行ID
            ,head.order_no_hht               order_no_hht              -- 受注No.(HHT)
            ,head.digestion_ln_number        digestion_ln_number       -- 枝番
            ,head.hht_invoice_no             hht_invoice_no            -- HHT伝票No.
--****************************** 2014/10/16 1.18 MOD START ******************************
            ,head.customer_number            customer_number           -- 顧客コード
            ,head.dlv_by_code                dlv_by_code               -- 納品者コード
            ,head.dlv_date                   dlv_date                  -- 納品日
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
            ,head.base_code                  base_code                 -- 拠点コード
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
      FROM   xxcos_dlv_headers  head         -- 納品ヘッダ
            ,xxcos_dlv_lines    line         -- 納品明細テーブル
      WHERE  head.order_no_hht         = line.order_no_hht         -- ヘッダ.受注No.(HHT)＝明細.受注No.(HHT)
      AND    head.digestion_ln_number  = line.digestion_ln_number  -- ヘッダ.枝番＝明細.枝番
      AND    head.results_forward_flag = cv_default                -- 販売実績連携済みフラグ＝0
      AND    head.input_class          = cv_input_class            -- 入力区分＝5
      ORDER BY 
             head.order_no_hht,head.digestion_ln_number;
--
    -- 対象伝票ロック取得カーソル
    CURSOR get_inv_lock_cur
    IS
      SELECT 'Y'
      FROM   xxcos_dlv_headers  head
             ,xxcos_dlv_lines   line
      WHERE  head.order_no_hht         = line.order_no_hht         -- ヘッダ.受注No.(HHT)＝明細.受注No.(HHT)
      AND    head.digestion_ln_number  = line.digestion_ln_number  -- ヘッダ.枝番＝明細.枝番
      AND    head.order_no_hht         = lt_inv_order_no_hht
      FOR UPDATE OF head.order_no_hht,line.order_no_hht NOWAIT;
--
    -- 明細情報取得カーソル
    CURSOR get_line_cur
    IS
      SELECT line.order_no_hht           order_no_hht        -- 受注No.(HHT)
             ,line.line_no_hht            line_no_hht         -- 行No.(HHT)
             ,line.digestion_ln_number    digestion_ln_number -- 枝番
             ,line.order_no_ebs           order_no_ebs        -- 受注No.(EBS)
             ,line.line_number_ebs        line_number_ebs     -- 明細番号(EBS)
             ,line.item_code_self         item_code_self      -- 品名コード(自社)
             ,line.content                content             -- 入数
             ,line.inventory_item_id      inventory_item_id   -- 品目ID
             ,line.standard_unit          standard_unit       -- 基準単位
             ,line.case_number            case_number         -- ケース数
             ,DECODE( head.red_black_flag, '0', line.quantity * -1, line.quantity )
                                         quantity            -- 数量
             ,line.sale_class             sale_class          -- 売上区分
             ,line.wholesale_unit_ploce   wholesale_unit_ploce  -- 卸単価
             ,line.selling_price          selling_price       -- 売単価
             ,line.column_no              column_no           -- コラムNo.
             ,line.h_and_c                h_and_c             -- H/C
             ,line.sold_out_class         sold_out_class      -- 売切区分
             ,line.sold_out_time          sold_out_time       -- 売切時間
             ,DECODE( head.red_black_flag, '0', line.replenish_number * -1, line.replenish_number )
                                         replenish_number    -- 補充数
             ,line.cash_and_card          cash_and_card       -- 現金・カード併用額
             ,cn_created_by               cn_created_by       -- 作成者
             ,cd_creation_date            creation_date       -- 作成日
             ,cn_last_updated_by          last_updated_by     -- 最終更新者
             ,cd_last_update_date         last_update_date    -- 最終更新日
             ,cn_last_update_login        last_update_login   -- 最終更新ログイン
             ,cn_request_id               request_id          -- 要求ID
             ,cn_program_application_id   program_application_id-- コンカレント・プログラム・アプリケーションID
             ,cn_program_id               program_id          -- コンカレント・プログラムID
             ,cd_program_update_date      program_update_date -- プログラム更新日
      FROM   xxcos_dlv_headers  head      -- 納品ヘッダテーブル
             ,xxcos_dlv_lines    line      -- 納品明細テーブル
      WHERE  head.order_no_hht         = line.order_no_hht         -- ヘッダ.受注No.(HHT)＝明細.受注No.(HHT)
      AND    head.digestion_ln_number  = line.digestion_ln_number  -- ヘッダ.枝番＝明細.枝番
      AND    head.order_no_hht         = lt_inv_order_no_hht
      AND    line.digestion_ln_number  = lt_inv_digestion_ln_number;
--
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD  END  ******************************************--
-- ******************* 2009/07/17 Ver1.11 N.Maeda DEL START ******************************************--
--    CURSOR headers_lock_cur
--    IS
----******************** 2009/05/07 Ver1.8  N.Maeda MOD START ******************************************
----      SELECT head.creation_date  creation_date
----      FROM   xxcos_dlv_headers   head                     -- 納品ヘッダテーブル
----      WHERE  head.results_forward_flag = cv_default       -- 販売実績連携済みフラグ＝0
----      AND    head.input_class          = cv_input_class   -- 入力区分＝5
--      SELECT head.order_no_hht               order_no_hht,              -- 受注No.(HHT)
--             head.digestion_ln_number        digestion_ln_number,       -- 枝番
--             head.order_no_ebs               order_no_ebs,              -- 受注No.(EBS)
--             head.base_code                  base_code,                 -- 拠点コード
--             head.performance_by_code        performance_by_code,       -- 成績者コード
--             head.dlv_by_code                dlv_by_code,               -- 納品者コード
--             head.hht_invoice_no             hht_invoice_no,            -- HHT伝票No.
--             head.dlv_date                   dlv_date,                  -- 納品日
--             head.inspect_date               inspect_date,              -- 検収日
--             head.sales_classification       sales_classification,      -- 売上分類区分
--             head.sales_invoice              sales_invoice,             -- 売上伝票区分
--             head.card_sale_class            card_sale_class,           -- カード売区分
--             head.dlv_time                   dlv_time,                  -- 時間
--             head.change_out_time_100        change_out_time_100,       -- つり銭切れ時間100円
--             head.change_out_time_10         change_out_time_10,        -- つり銭切れ時間10円
--             head.customer_number            customer_number,           -- 顧客コード
--             NULL                            dlv_form,                  -- 納品形態
--             head.system_class               system_class,              -- 業態区分
--             NULL                            invoice_type,              -- 伝票区分
--             head.input_class                input_class,               -- 入力区分
--             head.consumption_tax_class      consumption_tax_class,     -- 消費税区分
--             head.total_amount               total_amount,              -- 合計金額
--             head.sale_discount_amount       sale_discount_amount,      -- 売上値引額
--             head.sales_consumption_tax      sales_consumption_tax,     -- 売上消費税額
--             head.tax_include                tax_include,               -- 税込金額
--             head.keep_in_code               keep_in_code,              -- 預け先コード
--             head.department_screen_class    department_screen_class,   -- 百貨店画面種別
--             NULL                            digestion_vd_rate_maked_date, -- 消化VD掛率作成年月日
--             head.red_black_flag             red_black_flag,            -- 赤黒フラグ
--             'N'                             forward_flag,              -- 連携フラグ
--             NULL                            forward_date,              -- 連携日付
--             'N'                             vd_results_forward_flag,   -- ベンダ納品実績情報連携済フラグ
--             head.cancel_correct_class       cancel_correct_class,       -- 取消・訂正区分
--             cn_created_by                   created_by,                  -- 作成者
--             cd_creation_date                creation_date,               -- 作成日
--             cn_last_updated_by              last_updated_by,             -- 最終更新者
--             cd_last_update_date             last_update_date,            -- 最終更新日
--             cn_last_update_login            last_update_login,           -- 最終更新ログイン
--             cn_request_id                   request_id,                  -- 要求ID
--             cn_program_application_id       program_application_id,      -- コンカレント・プログラム・アプリケーションID
--             cn_program_id                   program_id,                  -- コンカレント・プログラムID
--             cd_program_update_date          program_update_date,         -- プログラム更新日
----******************** 2009/05/21 Ver1.9  T.Kitajima ADD START ******************************************
--             rowid                           h_rowid                       -- レコードID
----******************** 2009/05/21 Ver1.9  T.Kitajima ADD  END  ******************************************
--      FROM   xxcos_dlv_headers  head         -- 納品ヘッダテーブル
--      WHERE  head.results_forward_flag = cv_default       -- 販売実績連携済みフラグ＝0
--      AND    head.input_class          = cv_input_class   -- 入力区分＝5
----******************** 2009/05/07 Ver1.8  N.Maeda MOD  END  ******************************************
----    FOR UPDATE NOWAIT;
----
--    CURSOR lines_lock_cur
--    IS
--      SELECT line.creation_date  creation_date
--      FROM   xxcos_dlv_headers   head,                             -- 納品ヘッダテーブル
--             xxcos_dlv_lines     line                              -- 納品明細テーブル
--      WHERE  head.results_forward_flag = cv_default                -- 販売実績連携済みフラグ＝0
--      AND    head.input_class          = cv_input_class            -- 入力区分＝5
--      AND    head.order_no_hht         = line.order_no_hht         -- ヘッダ.受注No.(HHT)＝明細.受注No.(HHT)
--      AND    head.digestion_ln_number  = line.digestion_ln_number  -- ヘッダ.枝番＝明細.枝番
--    FOR UPDATE NOWAIT;
----
-- ******************* 2009/07/17 Ver1.11 N.Maeda DEL  END  ******************************************--
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
    CURSOR vd_lock_cur
    IS
      SELECT xvch.ROWID
      FROM   xxcos_vd_column_headers xvch
      WHERE  xvch.order_no_hht = lt_inv_order_no_hht
    FOR UPDATE OF xvch.order_no_hht NOWAIT;
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--
    -- *** ローカル・レコード ***
--
--****************************** 2014/10/16 1.18 MOD START ******************************
    ln_rs_cnt              NUMBER;
    --納品者コード例外
    dlv_by_code_expt       EXCEPTION;
--****************************** 2014/10/16 1.18 MOD END   ******************************
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
--****************************** 2014/10/16 1.18 MOD START ******************************
    ln_rs_cnt       := 0;
--****************************** 2014/10/16 1.18 MOD END   ******************************
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
    ln_vd_data_count:= 0;
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--
--******************** 2009/07/17 Ver1.11  N.Maeda MOD START ******************************************
--
    lt_data_count   := 0;
    lt_dlv_line_count := 0;
    lt_lock_brak_order_no_hht := 0;
    lt_lock_err_order_no_hht  := 0;
--
    --==============================================================
    -- 対象伝票情報取得
    --==============================================================
    OPEN  get_inv_cur;
    FETCH get_inv_cur BULK COLLECT INTO gt_inv_data_tab;
    CLOSE get_inv_cur;
--
    <<get_inv_loop>>
    FOR i IN 1..gt_inv_data_tab.COUNT LOOP
--
      on_target_cnt   := gt_inv_data_tab.COUNT;
      -- 対象伝票情報セット
      lt_inv_row_id                := gt_inv_data_tab(i).row_id;               -- 行ID
      lt_inv_order_no_hht          := gt_inv_data_tab(i).order_no_hht;         -- 受注No.(HHT)
      lt_inv_digestion_ln_number   := gt_inv_data_tab(i).digestion_ln_number;  -- 枝番
      lt_inv_hht_invoice_no        := gt_inv_data_tab(i).hht_invoice_no;       -- HHT伝票NO.
--****************************** 2014/10/16 1.18 MOD START ******************************
      lt_inv_customer_number       := gt_inv_data_tab(i).customer_number;      -- 顧客コード
      lt_inv_dlv_by_code           := gt_inv_data_tab(i).dlv_by_code;          -- 納品者コード
      lt_inv_dlv_date              := gt_inv_data_tab(i).dlv_date;             -- 納品日
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
      lt_inv_base_code             := gt_inv_data_tab(i).base_code;            -- 拠点コード
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
      BEGIN
        -- ===================
        -- 明細単位ロック取得
        -- ===================
        IF ( lt_lock_err_order_no_hht  <> lt_inv_order_no_hht ) THEN
--
          IF ( lt_lock_brak_order_no_hht <> lt_inv_order_no_hht ) THEN
--
            OPEN  get_inv_lock_cur;
            CLOSE get_inv_lock_cur;
--
          END IF;
--
          --ロック済みキーデータ
          lt_lock_brak_order_no_hht := lt_inv_order_no_hht;
--****************************** 2014/10/16 1.18 MOD START ******************************
          -- 抽出件数初期化
          ln_rs_cnt       := 0;
          BEGIN
            SELECT COUNT(1)
            INTO   ln_rs_cnt
            FROM   xxcos_rs_info2_v  xriv
            WHERE  xriv.employee_number                                   =  lt_inv_dlv_by_code
            AND    NVL(xriv.effective_start_date      ,lt_inv_dlv_date)  <=  lt_inv_dlv_date
            AND    NVL(xriv.effective_end_date        ,lt_inv_dlv_date)  >=  lt_inv_dlv_date
            AND    NVL(xriv.per_effective_start_date  ,lt_inv_dlv_date)  <=  lt_inv_dlv_date
            AND    NVL(xriv.per_effective_end_date    ,lt_inv_dlv_date)  >=  lt_inv_dlv_date
            AND    NVL(xriv.paa_effective_start_date  ,lt_inv_dlv_date)  <=  lt_inv_dlv_date
            AND    NVL(xriv.paa_effective_end_date    ,lt_inv_dlv_date)  >=  lt_inv_dlv_date
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
          --
          IF (ln_rs_cnt = 0 ) THEN
            RAISE dlv_by_code_expt;
          END IF;
--****************************** 2014/10/16 1.18 MOD END   ******************************
          --添え字のカウントアップ
          lt_data_count := lt_data_count + 1;
--
--
          -- ========================
          -- ヘッダデータ取得
          -- ========================
          SELECT head.order_no_hht               order_no_hht,              -- 1.受注No.(HHT)
                 head.digestion_ln_number        digestion_ln_number,       -- 2.枝番
                 head.order_no_ebs               order_no_ebs,              -- 3.受注No.(EBS)
                 head.base_code                  base_code,                 -- 4.拠点コード
                 head.performance_by_code        performance_by_code,       -- 5.成績者コード
                 head.dlv_by_code                dlv_by_code,               -- 6.納品者コード
                 head.hht_invoice_no             hht_invoice_no,            -- 7.HHT伝票No.
                 head.dlv_date                   dlv_date,                  -- 8.納品日
                 head.inspect_date               inspect_date,              -- 9.検収日
                 head.sales_classification       sales_classification,      -- 10.売上分類区分
                 head.sales_invoice              sales_invoice,             -- 11.売上伝票区分
                 head.card_sale_class            card_sale_class,           -- 12.カード売区分
                 head.dlv_time                   dlv_time,                  -- 13.時間
                 head.change_out_time_100        change_out_time_100,       -- 14.つり銭切れ時間100円
                 head.change_out_time_10         change_out_time_10,        -- 15.つり銭切れ時間10円
                 head.customer_number            customer_number,           -- 16.顧客コード
                 NULL                            dlv_form,                  -- 17.納品形態
                 head.system_class               system_class,              -- 18.業態区分
                 NULL                            invoice_type,              -- 19.伝票区分
                 head.input_class                input_class,               -- 20.入力区分
                 head.consumption_tax_class      consumption_tax_class,     -- 21.消費税区分
                 head.total_amount               total_amount,              -- 22.合計金額
                 head.sale_discount_amount       sale_discount_amount,      -- 23.売上値引額
                 head.sales_consumption_tax      sales_consumption_tax,     -- 24.売上消費税額
                 head.tax_include                tax_include,               -- 25.税込金額
                 head.keep_in_code               keep_in_code,              -- 26.預け先コード
                 head.department_screen_class    department_screen_class,   -- 27.百貨店画面種別
                 NULL                            digestion_vd_rate_maked_date, -- 28.消化VD掛率作成年月日
                 head.red_black_flag             red_black_flag,            -- 29.赤黒フラグ
                 'N'                             forward_flag,              -- 30.連携フラグ
                 NULL                            forward_date,              -- 31.連携日付
                 'N'                             vd_results_forward_flag,   -- 32.ベンダ納品実績情報連携済フラグ
                 head.cancel_correct_class       cancel_correct_class,      -- 33.取消・訂正区分
                 cn_created_by                   created_by,                -- 34.作成者
                 cd_creation_date                creation_date,             -- 35.作成日
                 cn_last_updated_by              last_updated_by,           -- 36.最終更新者
                 cd_last_update_date             last_update_date,          -- 37.最終更新日
                 cn_last_update_login            last_update_login,         -- 38.最終更新ログイン
                 cn_request_id                   request_id,                -- 39.要求ID
                 cn_program_application_id       program_application_id,    -- 40.コンカレント・プログラム・アプリケーションID
                 cn_program_id                   program_id,                -- 41.コンカレント・プログラムID
                 cd_program_update_date          program_update_date,       -- 42.プログラム更新日
                 lt_inv_row_id                   row_id                     -- 43.行ID
          INTO   gt_dev_set_order_noh_hht(lt_data_count)
                 ,gt_dev_set_digestion_ln(lt_data_count)
                 ,gt_dev_set_order_no_ebs(lt_data_count)
                 ,gt_dev_set_base_code(lt_data_count)
                 ,gt_dev_set_perform_code(lt_data_count)
                 ,gt_dev_set_dlv_code(lt_data_count)
                 ,gt_dev_set_invoice_no(lt_data_count)
                 ,gt_dev_set_dlv_date(lt_data_count)
                 ,gt_dev_set_inspect_date(lt_data_count)
                 ,gt_dev_set_sales_classif(lt_data_count)
                 ,gt_dev_set_sales_invoice(lt_data_count)
                 ,gt_dev_set_card_sale_class(lt_data_count)
                 ,gt_dev_set_dlv_time(lt_data_count)
                 ,gt_dev_set_out_time_100(lt_data_count)
                 ,gt_dev_set_out_time_10(lt_data_count)
                 ,gt_dev_set_cus_number(lt_data_count)
                 ,gt_dev_set_dlv_form(lt_data_count)
                 ,gt_dev_set_system_class(lt_data_count)
                 ,gt_dev_set_invoice_type(lt_data_count)
                 ,gt_dev_set_input_class(lt_data_count)
                 ,gt_dev_set_tax_class(lt_data_count)
                 ,gt_dev_set_total_amount(lt_data_count)
                 ,gt_dev_set_sale_discount_a(lt_data_count)
                 ,gt_dev_set_sales_tax(lt_data_count)
                 ,gt_dev_set_tax_include(lt_data_count)
                 ,gt_dev_set_keep_in_code(lt_data_count)
                 ,gt_dev_set_depart_sc_clas(lt_data_count)
                 ,gt_dev_set_dig_vd_r_mak_d(lt_data_count)
                 ,gt_dev_set_red_black_flag(lt_data_count)
                 ,gt_dev_set_forward_flag(lt_data_count)
                 ,gt_dev_set_forward_date(lt_data_count)
                 ,gt_dev_set_vd_results_for_f(lt_data_count)
                 ,gt_dev_set_cancel_correct(lt_data_count)
                 ,gt_dev_set_created_by(lt_data_count)
                 ,gt_dev_set_creation_date(lt_data_count)
                 ,gt_dev_set_last_updated_by(lt_data_count)
                 ,gt_dev_set_last_update_date(lt_data_count)
                 ,gt_dev_set_last_update_logi(lt_data_count)
                 ,gt_dev_set_request_id(lt_data_count)
                 ,gt_dev_set_program_appli_id(lt_data_count)
                 ,gt_dev_set_program_id(lt_data_count)
                 ,gt_dev_set_program_update_d(lt_data_count)
                 ,gt_dlv_headers_row_id(lt_data_count)
          FROM   xxcos_dlv_headers         head   -- 納品ヘッダ
          WHERE  head.ROWID = lt_inv_row_id;
--
          -- ================================
          -- 取消訂正区分最新値
          -- ================================
          BEGIN
            SELECT head.cancel_correct_class
            INTO   lt_cancel_correct_class
            FROM   xxcos_dlv_headers  head         -- 納品ヘッダテーブル
            WHERE  head.order_no_hht         = lt_inv_order_no_hht
            AND    head.results_forward_flag = cv_default       -- 販売実績連携済みフラグ＝0
            AND    head.input_class          = cv_input_class   -- 入力区分＝5
            AND    head.cancel_correct_class IS NOT NULL
            AND    head.digestion_ln_number  = ( SELECT
                                                 MAX( head.digestion_ln_number )
                                               FROM   xxcos_dlv_headers  head         -- 納品ヘッダテーブル
                                               WHERE  head.order_no_hht         = lt_inv_order_no_hht
                                               AND    head.results_forward_flag = cv_default
                                               AND    head.input_class          = cv_input_class );
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
--
          IF ( lt_cancel_correct_class IS NOT NULL ) THEN
            gt_dev_set_cancel_correct(lt_data_count) := lt_cancel_correct_class;
          END IF;
--
          BEGIN
            SELECT MIN( head.digestion_ln_number )
            INTO   lt_min_digestion_ln_number
            FROM   xxcos_dlv_headers  head         -- 納品ヘッダテーブル
            WHERE head.order_no_hht          = lt_inv_order_no_hht
            AND    head.results_forward_flag = cv_default
            AND    head.input_class          = cv_input_class;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
--
          IF ( lt_min_digestion_ln_number IS NOT NULL ) AND ( lt_min_digestion_ln_number <> '0' ) THEN
            <<vd_loop>>
            FOR vd_lock_rec IN vd_lock_cur LOOP
              ln_vd_data_count := ln_vd_data_count + 1;
              gt_vd_row_id(ln_vd_data_count)          := vd_lock_rec.ROWID;
              gt_vd_can_cor_class(ln_vd_data_count)   := lt_cancel_correct_class;
            END LOOP vd_loop;
          END IF;
--
          -- =============
          -- 明細情報取得
          -- =============
          <<get_line_loop>>
          FOR get_line_rec IN get_line_cur LOOP
--
            -- 明細情報件数カウントアップ
            lt_dlv_line_count := lt_dlv_line_count + 1;
            -- 変数へデータをセット
            gt_lines_tab(lt_dlv_line_count) := get_line_rec;
--
          END LOOP get_line_loop;
--
        ELSE
--
          -- スキップ件数カウントアップ
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
--
      EXCEPTION
        -- ロックエラー
        WHEN lock_expt THEN
          -- スキップ件数カウントアップ
          gn_warn_cnt := gn_warn_cnt + 1;
          -- ロックエラー・キーデータセット
          lt_lock_err_order_no_hht := lt_inv_order_no_hht;
          -- ロックエラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application,            --アプリケーション短縮名
                         iv_name          => cv_data_loc,               --メッセージコード
                         iv_token_name1   => cv_tkn_order_number,       --トークンコード1
                         iv_token_value1  => lt_inv_order_no_hht,       --受注No.(HHT)
                         iv_token_name2   => cv_invoice_no,             --トークンコード2
                         iv_token_value2  => lt_inv_hht_invoice_no);    --HHT伝票NO.
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
--****************************** 2014/10/16 1.18 MOD START ******************************
--
        WHEN dlv_by_code_expt THEN
          -- エラーメッセージを追加すること
          gn_warn_cnt := gn_warn_cnt + 1;
          -- 表示用にDATE型をVARCHAR型へ
          lt_inv_dlv_date_yyyymmdd  := TO_CHAR(lt_inv_dlv_date,'YYYY/MM/DD');
          -- 納品者コード有効性チェック・メッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application,                             --アプリケーション短縮名
                         iv_name          => cv_empl_effect,                             --メッセージコード
                         iv_token_name1   => cv_hht_invoice_no,                          -- トークンコード1
                         iv_token_value1  => lt_inv_hht_invoice_no,                      -- HHT伝票No.
                         iv_token_name2   => cv_customer_number,                         -- トークンコード2
                         iv_token_value2  => lt_inv_customer_number,                     -- 顧客コード
                         iv_token_name3   => cv_dlv_by_code,                             -- トークンコード3
                         iv_token_value3  => lt_inv_dlv_by_code,                         -- 納品者コード
                         iv_token_name4   => cv_dlv_date,                                -- トークンコード4
                         iv_token_value4  => lt_inv_dlv_date_yyyymmdd);                  -- 納品日（メッセージ出力用）
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
--
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
          -- キー情報編集
          xxcos_common_pkg.makeup_key_info(
              iv_item_name1     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv )         --  項目名称１
            , iv_item_name2     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_hht_inv_no )  --  項目名称２
            , iv_item_name3     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code )    --  項目名称３
            , iv_item_name4     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_date )    --  項目名称４
            , iv_data_value1    =>  lt_inv_dlv_by_code                         --  納品者コード
            , iv_data_value2    =>  lt_inv_hht_invoice_no                      --  HHT伝票No.
            , iv_data_value3    =>  lt_inv_customer_number                     --  顧客コード
            , iv_data_value4    =>  lt_inv_dlv_date_yyyymmdd                   --  納品日
            , ov_key_info       =>  gv_tkn4                                    --  キー情報
            , ov_errbuf         =>  lv_errbuf                                  --  エラー・メッセージエラー
            , ov_retcode        =>  lv_retcode                                 --  リターン・コード
            , ov_errmsg         =>  lv_errmsg                                  --  ユーザー・エラー・メッセージ
          );
          -- 汎用エラーリスト用キー情報保持
          IF (gv_prm_gen_err_out_flag = cv_tkn_yes) THEN
            --  汎用エラーリスト出力要の場合
            gn_msg_cnt  :=  gn_msg_cnt + 1;
            --  汎用エラーリスト用キー情報
            --  納品拠点
            gt_err_key_msg_tab(gn_msg_cnt).base_code      :=  lt_inv_base_code;
            --  エラーメッセージ名
            gt_err_key_msg_tab(gn_msg_cnt).message_name   :=  cv_empl_effect;
            --  キーメッセージ
            gt_err_key_msg_tab(gn_msg_cnt).message_text   :=  SUBSTRB(gv_tkn4, 1, 2000);
          END IF;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
      END;
--
    END LOOP get_inv_loop;
--
    BEGIN
      FORALL i IN 1..gt_dev_set_order_noh_hht.COUNT
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
        VALUES
            (
                 gt_dev_set_order_noh_hht(i),
                 gt_dev_set_digestion_ln(i),
                 gt_dev_set_order_no_ebs(i),
                 gt_dev_set_base_code(i),
                 gt_dev_set_perform_code(i),
                 gt_dev_set_dlv_code(i),
                 gt_dev_set_invoice_no(i),
                 gt_dev_set_dlv_date(i),
                 gt_dev_set_inspect_date(i),
                 gt_dev_set_sales_classif(i),
                 gt_dev_set_sales_invoice(i),
                 gt_dev_set_card_sale_class(i),
                 gt_dev_set_dlv_time(i),
                 gt_dev_set_out_time_100(i),
                 gt_dev_set_out_time_10(i),
                 gt_dev_set_cus_number(i),
                 gt_dev_set_dlv_form(i),
                 gt_dev_set_system_class(i),
                 gt_dev_set_invoice_type(i),
                 gt_dev_set_input_class(i),
                 gt_dev_set_tax_class(i),
                 gt_dev_set_total_amount(i),
--****************************** 2012/04/24 1.17 MOD START ******************************
--                 gt_dev_set_sales_tax(i),
--                 gt_dev_set_sale_discount_a(i),
                 gt_dev_set_sale_discount_a(i),
                 gt_dev_set_sales_tax(i),
--****************************** 2012/04/24 1.17 MOD END   ******************************
                 gt_dev_set_tax_include(i),
                 gt_dev_set_keep_in_code(i),
                 gt_dev_set_depart_sc_clas(i),
                 gt_dev_set_dig_vd_r_mak_d(i),
                 gt_dev_set_red_black_flag(i),
                 gt_dev_set_forward_flag(i),
                 gt_dev_set_forward_date(i),
                 gt_dev_set_vd_results_for_f(i),
                 gt_dev_set_cancel_correct(i),
                 gt_dev_set_created_by(i),
                 gt_dev_set_creation_date(i),
                 gt_dev_set_last_updated_by(i),
                 gt_dev_set_last_update_date(i),
                 gt_dev_set_last_update_logi(i),
                 gt_dev_set_request_id(i),
                 gt_dev_set_program_appli_id(i),
                 gt_dev_set_program_id(i),
                 gt_dev_set_program_update_d(i)
                 );
         -- ヘッダ登録件数セット
         gt_insert_h_count := gt_dev_set_order_noh_hht.COUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdh_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE insert_err_expt;
    END;
--
     BEGIN
       FORALL l IN 1..gt_lines_tab.COUNT
         INSERT INTO
           xxcos_vd_column_lines
         VALUES
           gt_lines_tab(l);
     EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdl_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE insert_err_expt;
     END;
--
--
--    --==============================================================
--    -- テーブルロック
--    --==============================================================
--    OPEN  headers_lock_cur;
----******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
--    FETCH headers_lock_cur BULK COLLECT INTO gt_clm_headers;
----******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--    CLOSE headers_lock_cur;
----
--    OPEN  lines_lock_cur;
--    CLOSE lines_lock_cur;
--
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
--    <<headers_loop>>
--    FOR header_id IN 1..gt_clm_headers.COUNT LOOP
--      lt_order_no_hht   :=   gt_clm_headers( header_id ).order_no_hht;              -- 受注No.(HHT)
----
--      BEGIN
--        SELECT head.cancel_correct_class
--        INTO   lt_cancel_correct_class
--        FROM   xxcos_dlv_headers  head         -- 納品ヘッダテーブル
--        WHERE  head.order_no_hht         = lt_order_no_hht
--        AND    head.results_forward_flag = cv_default       -- 販売実績連携済みフラグ＝0
--        AND    head.input_class          = cv_input_class   -- 入力区分＝5
--        AND    head.cancel_correct_class IS NOT NULL
--        AND    head.digestion_ln_number  = ( SELECT
--                                               MAX( head.digestion_ln_number )
--                                             FROM   xxcos_dlv_headers  head         -- 納品ヘッダテーブル
--                                             WHERE head.order_no_hht          = lt_order_no_hht
--                                             AND    head.results_forward_flag = cv_default
--                                             AND    head.input_class          = cv_input_class );
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          NULL;
--      END;
----
--      IF ( lt_cancel_correct_class IS NOT NULL ) THEN
--        gt_clm_headers( header_id ).cancel_correct_class := lt_cancel_correct_class;
--      END IF;
----
--      BEGIN
--        SELECT MIN( head.digestion_ln_number )
--        INTO   lt_min_digestion_ln_number
--        FROM   xxcos_dlv_headers  head         -- 納品ヘッダテーブル
--        WHERE head.order_no_hht          = lt_order_no_hht
--        AND    head.results_forward_flag = cv_default
--        AND    head.input_class          = cv_input_class;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          NULL;
--      END;
----
--      IF ( lt_min_digestion_ln_number IS NOT NULL ) AND ( lt_min_digestion_ln_number <> '0' ) THEN
--        <<vd_loop>>
--        FOR vd_lock_rec IN vd_lock_cur LOOP
--          ln_vd_data_count := ln_vd_data_count + 1;
--          gt_vd_row_id(ln_vd_data_count)          := vd_lock_rec.ROWID;
--          gt_vd_can_cor_class(ln_vd_data_count)   := lt_cancel_correct_class;
--        END LOOP vd_loop;
--      END IF;
----
--      gt_dev_set_order_noh_hht(header_id)       := gt_clm_headers(header_id).order_no_hht;
--      gt_dev_set_digestion_ln(header_id) := gt_clm_headers(header_id).digestion_ln_number;
--      gt_dev_set_order_no_ebs(header_id)        := gt_clm_headers(header_id).order_no_ebs;
--      gt_dev_set_base_code(header_id)           := gt_clm_headers(header_id).base_code;
--      gt_dev_set_perform_code(header_id)        := gt_clm_headers(header_id).performance_by_code;
--      gt_dev_set_dlv_code(header_id)            := gt_clm_headers(header_id).dlv_by_code;
--      gt_dev_set_invoice_no(header_id)          := gt_clm_headers(header_id).hht_invoice_no;
--      gt_dev_set_dlv_date(header_id)            := gt_clm_headers(header_id).dlv_date;
--      gt_dev_set_inspect_date(header_id)        := gt_clm_headers(header_id).inspect_date;
--      gt_dev_set_sales_classif(header_id) := gt_clm_headers(header_id).sales_classification;
--      gt_dev_set_sales_invoice(header_id)       := gt_clm_headers(header_id).sales_invoice;
--      gt_dev_set_card_sale_class(header_id)     := gt_clm_headers(header_id).card_sale_class;
--      gt_dev_set_dlv_time(header_id)            := gt_clm_headers(header_id).dlv_time;
--      gt_dev_set_out_time_100(header_id) := gt_clm_headers(header_id).change_out_time_100;
--      gt_dev_set_out_time_10(header_id)  := gt_clm_headers(header_id).change_out_time_10;
--      gt_dev_set_cus_number(header_id)          := gt_clm_headers(header_id).customer_number;
--      gt_dev_set_dlv_form(header_id)            := gt_clm_headers(header_id).dlv_form;
--      gt_dev_set_system_class(header_id)        := gt_clm_headers(header_id).system_class;
--      gt_dev_set_invoice_type(header_id)        := gt_clm_headers(header_id).invoice_type;
--      gt_dev_set_input_class(header_id)         := gt_clm_headers(header_id).input_class;
--      gt_dev_set_tax_class(header_id) := gt_clm_headers(header_id).consumption_tax_class;
--      gt_dev_set_total_amount(header_id)        := gt_clm_headers(header_id).total_amount;
--      gt_dev_set_sale_discount_a(header_id) := gt_clm_headers(header_id).sale_discount_amount;
--      gt_dev_set_sales_tax(header_id) := gt_clm_headers(header_id).sales_consumption_tax;
--      gt_dev_set_tax_include(header_id)         := gt_clm_headers(header_id).tax_include;
--      gt_dev_set_keep_in_code(header_id)        := gt_clm_headers(header_id).keep_in_code;
--      gt_dev_set_depart_sc_clas(header_id) := gt_clm_headers(header_id).department_screen_class;
--      gt_dev_set_dig_vd_r_mak_d(header_id) := gt_clm_headers(header_id).digestion_vd_rate_maked_date;
--      gt_dev_set_red_black_flag(header_id)      := gt_clm_headers(header_id).red_black_flag;
--      gt_dev_set_forward_flag(header_id)        := gt_clm_headers(header_id).forward_flag;
--      gt_dev_set_forward_date(header_id)        := gt_clm_headers(header_id).forward_date;
--      gt_dev_set_vd_results_for_f(header_id) := gt_clm_headers(header_id).vd_results_forward_flag;
--      gt_dev_set_cancel_correct(header_id)      := gt_clm_headers(header_id).cancel_correct_class;
--      gt_dev_set_created_by(header_id)          := gt_clm_headers(header_id).created_by;
--      gt_dev_set_creation_date(header_id)       := gt_clm_headers(header_id).creation_date;
--      gt_dev_set_last_updated_by(header_id)     := gt_clm_headers(header_id).last_updated_by;
--      gt_dev_set_last_update_date(header_id)    := gt_clm_headers(header_id).last_update_date;
--      gt_dev_set_last_update_logi(header_id)   := gt_clm_headers(header_id).last_update_login;
--      gt_dev_set_request_id(header_id)          := gt_clm_headers(header_id).request_id;
--      gt_dev_set_program_appli_id(header_id) := gt_clm_headers(header_id).program_application_id;
--      gt_dev_set_program_id(header_id)          := gt_clm_headers(header_id).program_id;
--      gt_dev_set_program_update_d(header_id) := gt_clm_headers(header_id).program_update_date;
----******************** 2009/05/21 Ver1.9  T.Kitajima ADD START ******************************************
--      gt_dlv_headers_row_id(header_id)          := gt_clm_headers(header_id).h_rowid;
----******************** 2009/05/21 Ver1.9  T.Kitajima ADD  END  ******************************************
--    END LOOP headers_loop;
----
----
----******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
----
--    --==============================================================
--    -- VDコラム別取引ヘッダテーブルへ登録
--    --==============================================================
--    BEGIN
----******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
--      FORALL i IN 1..gt_dev_set_order_noh_hht.COUNT
----******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--        INSERT INTO
--          xxcos_vd_column_headers
--            (
--                 order_no_hht,                   -- 受注No.(HHT)
--                 digestion_ln_number,            -- 枝番
--                 order_no_ebs,                   -- 受注No.(EBS)
--                 base_code,                      -- 拠点コード
--                 performance_by_code,            -- 成績者コード
--                 dlv_by_code,                    -- 納品者コード
--                 hht_invoice_no,                 -- HHT伝票No.
--                 dlv_date,                       -- 納品日
--                 inspect_date,                   -- 検収日
--                 sales_classification,           -- 売上分類区分
--                 sales_invoice,                  -- 売上伝票区分
--                 card_sale_class,                -- カード売区分
--                 dlv_time,                       -- 時間
--                 change_out_time_100,            -- つり銭切れ時間100円
--                 change_out_time_10,             -- つり銭切れ時間10円
--                 customer_number,                -- 顧客コード
--                 dlv_form,                       -- 納品形態
--                 system_class,                   -- 業態区分
--                 invoice_type,                   -- 伝票区分
--                 input_class,                    -- 入力区分
--                 consumption_tax_class,          -- 消費税区分
--                 total_amount,                   -- 合計金額
--                 sale_discount_amount,           -- 売上値引額
--                 sales_consumption_tax,          -- 売上消費税額
--                 tax_include,                    -- 税込金額
--                 keep_in_code,                   -- 預け先コード
--                 department_screen_class,        -- 百貨店画面種別
--                 digestion_vd_rate_maked_date,   -- 消化VD掛率作成年月日
--                 red_black_flag,                 -- 赤黒フラグ
--                 forward_flag,                   -- 連携フラグ
--                 forward_date,                   -- 連携日付
--                 vd_results_forward_flag,        -- ベンダ納品実績情報連携済フラグ
--                 cancel_correct_class,           -- 取消・訂正区分
--                 created_by,                     -- 作成者
--                 creation_date,                  -- 作成日
--                 last_updated_by,                -- 最終更新者
--                 last_update_date,               -- 最終更新日
--                 last_update_login,              -- 最終更新ログイン
--                 request_id,                     -- 要求ID
--                 program_application_id,         -- コンカレント・プログラム・アプリケーションID
--                 program_id,                     -- コンカレント・プログラムID
--                 program_update_date             -- プログラム更新日
--            )
--        VALUES
--          (
----******************** 2009/05/07 Ver1.8  N.Maeda MOD START ******************************************
----        SELECT head.order_no_hht,              -- 受注No.(HHT)
----               head.digestion_ln_number,       -- 枝番
----               head.order_no_ebs,              -- 受注No.(EBS)
----               head.base_code,                 -- 拠点コード
----               head.performance_by_code,       -- 成績者コード
----               head.dlv_by_code,               -- 納品者コード
----               head.hht_invoice_no,            -- HHT伝票No.
----               head.dlv_date,                  -- 納品日
----               head.inspect_date,              -- 検収日
----               head.sales_classification,      -- 売上分類区分
----               head.sales_invoice,             -- 売上伝票区分
----               head.card_sale_class,           -- カード売区分
----               head.dlv_time,                  -- 時間
----               head.change_out_time_100,       -- つり銭切れ時間100円
----               head.change_out_time_10,        -- つり銭切れ時間10円
----               head.customer_number,           -- 顧客コード
----                 NULL,                           -- 納品形態
----               head.system_class,              -- 業態区分
----                 NULL,                           -- 伝票区分
----               head.input_class,               -- 入力区分
----               head.consumption_tax_class,     -- 消費税区分
----               head.total_amount,              -- 合計金額
----               head.sale_discount_amount,      -- 売上値引額
----               head.sales_consumption_tax,     -- 売上消費税額
----               head.tax_include,               -- 税込金額
----               head.keep_in_code,              -- 預け先コード
----               head.department_screen_class,   -- 百貨店画面種別
----                 NULL,                           -- 消化VD掛率作成年月日
----               head.red_black_flag,            -- 赤黒フラグ
----                 'N',                            -- 連携フラグ
----                 NULL,                           -- 連携日付
----                 'N',                            -- ベンダ納品実績情報連携済フラグ
----               head.cancel_correct_class,      -- 取消・訂正区分
----                 gt_clm_headers.cancel_correct_class,      -- 取消・訂正区分
----                 cn_created_by,                  -- 作成者
----                 cd_creation_date,               -- 作成日
----                 cn_last_updated_by,             -- 最終更新者
----                 cd_last_update_date,            -- 最終更新日
----                 cn_last_update_login,           -- 最終更新ログイン
----                 cn_request_id,                  -- 要求ID
----                 cn_program_application_id,      -- コンカレント・プログラム・アプリケーションID
----                 cn_program_id,                  -- コンカレント・プログラムID
----                 cd_program_update_date          -- プログラム更新日
----        FROM   xxcos_dlv_headers  head         -- 納品ヘッダテーブル
----        WHERE  head.results_forward_flag = cv_default       -- 販売実績連携済みフラグ＝0
----        AND    head.input_class          = cv_input_class;  -- 入力区分＝5
--                 gt_dev_set_order_noh_hht(i),
--                 gt_dev_set_digestion_ln(i),
--                 gt_dev_set_order_no_ebs(i),
--                 gt_dev_set_base_code(i),
--                 gt_dev_set_perform_code(i),
--                 gt_dev_set_dlv_code(i),
--                 gt_dev_set_invoice_no(i),
--                 gt_dev_set_dlv_date(i),
--                 gt_dev_set_inspect_date(i),
--                 gt_dev_set_sales_classif(i),
--                 gt_dev_set_sales_invoice(i),
--                 gt_dev_set_card_sale_class(i),
--                 gt_dev_set_dlv_time(i),
--                 gt_dev_set_out_time_100(i),
--                 gt_dev_set_out_time_10(i),
--                 gt_dev_set_cus_number(i),
--                 gt_dev_set_dlv_form(i),
--                 gt_dev_set_system_class(i),
--                 gt_dev_set_invoice_type(i),
--                 gt_dev_set_input_class(i),
--                 gt_dev_set_tax_class(i),
--                 gt_dev_set_total_amount(i),
--                 gt_dev_set_sales_tax(i),
--                 gt_dev_set_sale_discount_a(i),
--                 gt_dev_set_tax_include(i),
--                 gt_dev_set_keep_in_code(i),
--                 gt_dev_set_depart_sc_clas(i),
--                 gt_dev_set_dig_vd_r_mak_d(i),
--                 gt_dev_set_red_black_flag(i),
--                 gt_dev_set_forward_flag(i),
--                 gt_dev_set_forward_date(i),
--                 gt_dev_set_vd_results_for_f(i),
--                 gt_dev_set_cancel_correct(i),
--                 gt_dev_set_created_by(i),
--                 gt_dev_set_creation_date(i),
--                 gt_dev_set_last_updated_by(i),
--                 gt_dev_set_last_update_date(i),
--                 gt_dev_set_last_update_logi(i),
--                 gt_dev_set_request_id(i),
--                 gt_dev_set_program_appli_id(i),
--                 gt_dev_set_program_id(i),
--                 gt_dev_set_program_update_d(i)
--                 );
----******************** 2009/05/07 Ver1.8  N.Maeda MOD  END  ******************************************
----
--    -- ヘッダ抽出件数セット
----******************** 2009/05/26 Ver1.9  T.Kitajima MOD START ******************************************
----    on_target_cnt := SQL%ROWCOUNT;
--    on_target_cnt := gt_dev_set_order_noh_hht.COUNT;
----******************** 2009/05/26 Ver1.9  T.Kitajima MOD  END  ******************************************
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdh_table );
--        gv_tkn2    := NULL;
--        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
--                                                cv_tkn_table,   gv_tkn1,
--                                                cv_tkn_key,     gv_tkn2 );
--        lv_errbuf  := lv_errmsg;
--        RAISE global_api_expt;
--    END;
----
--    --==============================================================
--    -- VDコラム別取引明細テーブルへ登録
--    --==============================================================
--    BEGIN
--      INSERT INTO
--        xxcos_vd_column_lines
--          (
--               order_no_hht,                -- 受注No.(HHT)
--               line_no_hht,                 -- 行No.(HHT)
--               digestion_ln_number,         -- 枝番
--               order_no_ebs,                -- 受注No.(EBS)
--               line_number_ebs,             -- 明細番号(EBS)
--               item_code_self,              -- 品名コード(自社)
--               content,                     -- 入数
--               inventory_item_id,           -- 品目ID
--               standard_unit,               -- 基準単位
--               case_number,                 -- ケース数
--               quantity,                    -- 数量
--               sale_class,                  -- 売上区分
--               wholesale_unit_ploce,        -- 卸単価
--               selling_price,               -- 売単価
--               column_no,                   -- コラムNo.
--               h_and_c,                     -- H/C
--               sold_out_class,              -- 売切区分
--               sold_out_time,               -- 売切時間
--               replenish_number,            -- 補充数
--               cash_and_card,               -- 現金・カード併用額
--               created_by,                  -- 作成者
--               creation_date,               -- 作成日
--               last_updated_by,             -- 最終更新者
--               last_update_date,            -- 最終更新日
--               last_update_login,           -- 最終更新ログイン
--               request_id,                  -- 要求ID
--               program_application_id,      -- コンカレント・プログラム・アプリケーションID
--               program_id,                  -- コンカレント・プログラムID
--               program_update_date          -- プログラム更新日
--          )
--        SELECT line.order_no_hht,           -- 受注No.(HHT)
--               line.line_no_hht,            -- 行No.(HHT)
--               line.digestion_ln_number,    -- 枝番
--               line.order_no_ebs,           -- 受注No.(EBS)
--               line.line_number_ebs,        -- 明細番号(EBS)
--               line.item_code_self,         -- 品名コード(自社)
--               line.content,                -- 入数
--               line.inventory_item_id,      -- 品目ID
--               line.standard_unit,          -- 基準単位
--               line.case_number,            -- ケース数
--               DECODE( head.red_black_flag, '0', line.quantity * -1, line.quantity ),
--                                            -- 数量
--               line.sale_class,             -- 売上区分
--               line.wholesale_unit_ploce,   -- 卸単価
--               line.selling_price,          -- 売単価
--               line.column_no,              -- コラムNo.
--               line.h_and_c,                -- H/C
--               line.sold_out_class,         -- 売切区分
--               line.sold_out_time,          -- 売切時間
--               DECODE( head.red_black_flag, '0', line.replenish_number * -1, line.replenish_number ),
--                                            -- 補充数
--               line.cash_and_card,          -- 現金・カード併用額
--               cn_created_by,               -- 作成者
--               cd_creation_date,            -- 作成日
--               cn_last_updated_by,          -- 最終更新者
--               cd_last_update_date,         -- 最終更新日
--               cn_last_update_login,        -- 最終更新ログイン
--               cn_request_id,               -- 要求ID
--               cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
--               cn_program_id,               -- コンカレント・プログラムID
--               cd_program_update_date       -- プログラム更新日
--        FROM   xxcos_dlv_headers  head,     -- 納品ヘッダテーブル
--               xxcos_dlv_lines    line      -- 納品明細テーブル
--        WHERE  head.results_forward_flag = cv_default                -- 販売実績連携済みフラグ＝0
--        AND    head.input_class          = cv_input_class            -- 入力区分＝5
--        AND    head.order_no_hht         = line.order_no_hht         -- ヘッダ.受注No.(HHT)＝明細.受注No.(HHT)
--        AND    head.digestion_ln_number  = line.digestion_ln_number; -- ヘッダ.枝番＝明細.枝番
----
--    -- 明細抽出件数セット
--    on_target_cnt_l := SQL%ROWCOUNT;
--
--    EXCEPTION
--      WHEN OTHERS THEN
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdl_table );
--        gv_tkn2    := NULL;
--        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
--                                                cv_tkn_table,   gv_tkn1,
--                                                cv_tkn_key,     gv_tkn2 );
--        lv_errbuf  := lv_errmsg;
--        RAISE insert_err_expt;
--    END;
--
--  EXCEPTION
--    -- ロックエラー
--    WHEN lock_expt THEN
--      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_table );
--      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_tab, gv_tkn1 );
--      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
----
--      IF ( headers_lock_cur%ISOPEN ) THEN
--        CLOSE headers_lock_cur;
--      END IF;
----
--      IF ( lines_lock_cur%ISOPEN ) THEN
--        CLOSE lines_lock_cur;
--      END IF;
--
  EXCEPTION
--
    -- インサートエラー
    WHEN insert_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--******************** 2009/07/17 Ver1.11  N.Maeda MOD  END  ******************************************
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
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- 連携済みフラグ更新
    --==============================================================
    BEGIN
--******************** 2009/05/21 Ver1.9  T.Kitajima MOD START ******************************************
--      UPDATE
--        xxcos_dlv_headers  head   -- 納品ヘッダテーブル
--      SET
--        head.results_forward_flag   = cv_one,                      -- 販売実績連携済みフラグ
--        head.results_forward_date   = cd_last_update_date,         -- 販売実績連携済み日付
--        head.last_updated_by        = cn_last_updated_by,          -- 最終更新者
--        head.last_update_date       = cd_last_update_date,         -- 最終更新日
--        head.last_update_login      = cn_last_update_login,        -- 最終更新ログイン
--        head.request_id             = cn_request_id,               -- 要求ID
--        head.program_application_id = cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
--        head.program_id             = cn_program_id,               -- コンカレント・プログラムID
--        head.program_update_date    = cd_program_update_date       -- プログラム更新日
--      WHERE  head.results_forward_flag = cv_default                -- 販売実績連携済みフラグ＝0
--      AND    head.input_class          = cv_input_class;           -- 入力区分＝5
--
      FORALL i in 1..gt_dlv_headers_row_id.COUNT
        UPDATE xxcos_dlv_headers  head   -- 納品ヘッダテーブル
           SET head.results_forward_flag   = cv_one,                      -- 販売実績連携済みフラグ
               head.results_forward_date   = cd_last_update_date,         -- 販売実績連携済み日付
               head.last_updated_by        = cn_last_updated_by,          -- 最終更新者
               head.last_update_date       = cd_last_update_date,         -- 最終更新日
               head.last_update_login      = cn_last_update_login,        -- 最終更新ログイン
               head.request_id             = cn_request_id,               -- 要求ID
               head.program_application_id = cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
               head.program_id             = cn_program_id,               -- コンカレント・プログラムID
               head.program_update_date    = cd_program_update_date       -- プログラム更新日
         WHERE head.rowid                  = gt_dlv_headers_row_id(i)
      ;
--******************** 2009/05/21 Ver1.9  T.Kitajima MOD  END  ******************************************
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
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
    --==============================================================
    -- VDカラム別取引情報取消訂正区分更新
    --==============================================================
    IF ( gt_vd_row_id.COUNT > 0 ) THEN
      BEGIN
        <<vd_update_loop>>
        FORALL i IN 1..gt_vd_row_id.COUNT
          UPDATE
            xxcos_vd_column_headers  head   -- 納品ヘッダテーブル
          SET
            head.cancel_correct_class   = gt_vd_can_cor_class(i),      -- 取消訂正区分
            head.last_updated_by        = cn_last_updated_by,          -- 最終更新者
            head.last_update_date       = cd_last_update_date,         -- 最終更新日
            head.last_update_login      = cn_last_update_login,        -- 最終更新ログイン
            head.request_id             = cn_request_id,               -- 要求ID
            head.program_application_id = cn_program_application_id,   -- コンカレント・プログラム・アプリケーションID
            head.program_id             = cn_program_id,               -- コンカレント・プログラムID
            head.program_update_date    = cd_program_update_date       -- プログラム更新日
          WHERE  head.rowid             = gt_vd_row_id(i);
--
      EXCEPTION
        WHEN OTHERS THEN
          gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdh_table );
          gv_tkn2    := NULL;
          lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update,
                                                  cv_tkn_table,   gv_tkn1,
                                                  cv_tkn_key,     gv_tkn2 );
          lv_errbuf  := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
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
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
--
  /**********************************************************************************
   * Procedure Name   : ins_err_msg
   * Description      : エラー情報登録処理(A-6)
   ***********************************************************************************/
--
  PROCEDURE ins_err_msg(
    ov_errbuf       OUT     VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT     VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT     VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_err_msg'; -- プログラム名
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
    lv_outmsg       VARCHAR2(5000);   --  エラーメッセージ
    lv_table_name   VARCHAR2(100);    --  テーブル名称
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
    FOR ln_set_cnt  IN  1 .. gn_msg_cnt LOOP
      -- ===============================
      --  キー情報以外の設定
      -- ===============================
      --  汎用エラーリストID
      SELECT  xxcos_gen_err_list_s01.NEXTVAL
      INTO    gt_err_key_msg_tab(ln_set_cnt).gen_err_list_id
      FROM    dual;
      --
      gt_err_key_msg_tab(ln_set_cnt).concurrent_program_name  :=  cv_pkg_name;                  --  コンカレント名
      gt_err_key_msg_tab(ln_set_cnt).business_date            :=  gd_process_date;              --  登録業務日付
      gt_err_key_msg_tab(ln_set_cnt).created_by               :=  cn_created_by;                --  作成者
      gt_err_key_msg_tab(ln_set_cnt).creation_date            :=  SYSDATE;                      --  作成日
      gt_err_key_msg_tab(ln_set_cnt).last_updated_by          :=  cn_last_updated_by;           --  最終更新者
      gt_err_key_msg_tab(ln_set_cnt).last_update_date         :=  SYSDATE;                      --  最終更新日
      gt_err_key_msg_tab(ln_set_cnt).last_update_login        :=  cn_last_update_login;         --  最終更新ログイン
      gt_err_key_msg_tab(ln_set_cnt).request_id               :=  cn_request_id;                --  要求ID
      gt_err_key_msg_tab(ln_set_cnt).program_application_id   :=  cn_program_application_id;    --  コンカレント・プログラム・アプリケーションID
      gt_err_key_msg_tab(ln_set_cnt).program_id               :=  cn_program_id;                --  コンカレント・プログラムID
      gt_err_key_msg_tab(ln_set_cnt).program_update_date      :=  SYSDATE;                      --  プログラム更新日
    END LOOP;
    --
    -- ===============================
    --  汎用エラーリスト登録
    -- ===============================
    FORALL ln_cnt IN 1 .. gn_msg_cnt  SAVE EXCEPTIONS
      INSERT  INTO  xxcos_gen_err_list VALUES gt_err_key_msg_tab(ln_cnt);
--
  EXCEPTION
    -- *** バルクインサート例外処理 ***
    WHEN global_bulk_ins_expt THEN
      gn_error_cnt  :=  SQL%BULK_EXCEPTIONS.COUNT;        --  エラー件数
      ov_retcode    :=  cv_status_err_ins;                --  ステータス（エラー）
      ov_errmsg     :=  NULL;                             --  ユーザー・エラー・メッセージ
      ov_errbuf     :=  NULL;                             --  エラー・メッセージ
      --
      --  テーブル名称
      lv_table_name :=  xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_application
                          , iv_name         =>  cv_msg_gen_errlst
                        );
      --
      <<output_error_loop>>
      FOR ln_cnt IN 1 .. gn_error_cnt  LOOP
        -- エラーメッセージ生成
        lv_outmsg :=  SUBSTRB(
                        xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_application
                          , iv_name           =>  cv_msg_add
                          , iv_token_name1    =>  cv_tkn_table
                          , iv_token_value1   =>  lv_table_name
                          , iv_token_name2    =>  cv_key_data
                          , iv_token_value2   =>  cv_prg_name||cv_msg_part||SQLERRM(-SQL%BULK_EXCEPTIONS(ln_cnt).ERROR_CODE)
                        ), 1, 5000
                      );
        -- エラーメッセージ出力
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_outmsg
        );
        FND_FILE.PUT_LINE(
            which   =>  FND_FILE.LOG
          , buff    =>  lv_outmsg
        );
      END LOOP output_error_loop;
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
  END ins_err_msg;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
    iv_gen_err_out_flag  IN         VARCHAR2,     --  汎用エラーリスト出力フラグ
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
    ov_errbuf            OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
    gn_msg_cnt                :=  0;                                --  汎用エラーリスト出力件数
    gv_prm_gen_err_out_flag   :=  iv_gen_err_out_flag;              --  汎用エラーリスト出力フラグ
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
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
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
      -- =======================================================
      -- A-6.エラー情報登録処理
      -- =======================================================
    IF (gn_msg_cnt <> 0) THEN
      --  汎用エラーリスト出力対象有りの場合
      ins_err_msg(
          ov_errbuf       =>  lv_errbuf     -- エラー・メッセージ           --# 固定 #
        , ov_retcode      =>  lv_retcode    -- リターン・コード             --# 固定 #
        , ov_errmsg       =>  lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_err_ins) THEN
        -- INSERT時エラー
        RAISE global_ins_key_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
    -- スキップ発生時
    IF ( gn_warn_cnt <> 0 ) THEN
      -- ステータス警告
      ov_retcode := cv_status_warn;
    END IF;
    -- 警告処理（対象データ無しエラー）gt_tr_count
    IF (  gn_inv_target_cnt + gn_dlv_h_target_cnt = 0  ) THEN
--    IF (  gn_inv_target_cnt + gn_dlv_h_target_cnt = 0  ) THEN
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
--****************************** 2014/11/27 1.19 K.Nakatsu MOD START ******************************--
--    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_gen_err_out_flag  IN VARCHAR2 --  汎用エラーリスト出力フラグ
--****************************** 2014/11/27 1.19 K.Nakatsu MOD  END  ******************************--
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
--****************************** 2014/11/27 1.19 K.Nakatsu MOD START ******************************--
--       lv_errbuf   -- エラー・メッセージ           --# 固定 #
       NVL(iv_gen_err_out_flag, cv_tkn_no)         --  汎用エラーリスト出力フラグ
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--****************************** 2014/11/27 1.19 K.Nakatsu MOD  END  ******************************--
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
      gn_warn_cnt      := 0;
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
--******************** 2009/07/17 Ver1.11  N.Maeda MOD START ******************************************
--    --入出庫情報抽出件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_inv_cnt
--                    ,iv_token_name1  => cv_tkn_count
--                    ,iv_token_value1 => TO_CHAR( gn_inv_target_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => gv_out_msg
--    );
----    --
    --納品ヘッダ情報抽出件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_dlv_h_target_cnt + gt_tr_count )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --
--    --納品明細情報抽出件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_dlv_cnt_l
--                    ,iv_token_name1  => cv_tkn_count
--                    ,iv_token_value1 => TO_CHAR( gn_dlv_l_target_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => gv_out_msg
--    );
    --
    --ヘッダ成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_h_nor_cnt
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_h_normal_cnt + gt_insert_h_count )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --
--    --明細成功件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_l_nor_cnt
--                    ,iv_token_name1  => cv_tkn_count
--                    ,iv_token_value1 => TO_CHAR( gn_l_normal_cnt + gn_dlv_l_nor_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => gv_out_msg
--    );
    --
    --
    --スキップ件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
--******************** 2009/07/17 Ver1.11  N.Maeda MOD  END  ******************************************
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
