CREATE OR REPLACE PACKAGE BODY XXCOS013A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS013A01C (body)
 * Description      : 販売実績情報より仕訳情報を作成し、AR請求取引に連携する処理
 * MD.050           : ARへの販売実績データ連携 MD050_COS_013_A01
 * Version          : 1.0
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_data               販売実績データ取得(A-2)
 *  edit_sum_data          請求取引集約処理（非大手量販店）(A-3)
 *  edit_dis_data          AR会計配分仕訳作成（非大手量販店）(A-4)
 *  edit_sum_bulk_data     AR請求取引情報集約処理（大手量販店）(A-5)
 *  edit_dis_bulk_data     AR会計配分仕訳作成（大手量販店）(A-6)
 *  insert_aroif_data      AR請求取引OIF登録処理(A-7)
 *  insert_ardis_data      AR会計配分OIF登録処理(A-8)
 *  upd_data               販売実績ヘッダ更新処理(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(終了処理A-10を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2009/01/14    1.0   R.HAN            新規作成
 *  2009/02/17    1.1   R.HAN            get_msgのパッケージ名修正
 *  2009/02/23    1.2   R.HAN            パラメータのログファイル出力対応
 *  2009/02/23    1.3   R.HAN            税コードの結合条件を追加
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START  ###############################
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--#######################  固定グローバル定数宣言部 END   ################################
--
--#######################  固定グローバル変数宣言部 START ################################
--
  gv_out_msg       VARCHAR2(2000);            -- 出力メッセージ
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--#######################  固定グローバル変数宣言部 END   ###############################
--
--##########################  固定共通例外宣言部 START  #################################
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
--##########################  固定共通例外宣言部 END   ###############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);       -- ロックエラー
  global_proc_date_err_expt EXCEPTION;         -- 業務日付取得例外
  global_select_data_expt   EXCEPTION;         -- データ取得例外
  global_insert_data_expt   EXCEPTION;         -- 登録処理例外
  global_update_data_expt   EXCEPTION;         -- 更新処理例外
  global_get_profile_expt   EXCEPTION;         -- プロファイル取得例外
  global_no_data_expt       EXCEPTION;         -- 対象データ０件エラー
  global_no_lookup_expt     EXCEPTION;         -- LOOKUP取得エラー
  global_term_id_expt       EXCEPTION;         -- 支払条件ID取得エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_xxccp_short_nm         CONSTANT VARCHAR2(10) := 'XXCCP';            -- 共通領域短縮アプリ名
  cv_xxcos_short_nm         CONSTANT VARCHAR2(10) := 'XXCOS';            -- 販物アプリケーション短縮名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOS013A01C';     -- パッケージ名
  cv_no_para_msg            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなしメッセージ
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- 業務日付取得エラー
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- プロファイル取得エラー
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013'; -- データ抽出エラーメッセージ
  cv_no_data_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- 対象データ無しメッセージ
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001'; -- ロックエラーメッセージ（販売実績TB）
  cv_data_insert_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010'; -- データ登録エラーメッセージ
  cv_data_update_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011'; -- データ更新エラーメッセージ
  cv_pro_mo_org_cd          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047'; -- 営業単位取得エラー
--
  cv_tkn_sales_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12751'; -- 販売実績ヘッダ
  cv_tkn_aroif_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12752'; -- AR請求取引OIF
  cv_tkn_ardis_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12753'; -- AR会計配分OIF
  cv_sales_nm_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12754'; -- 販売実績
  cv_pro_bks_id             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12755'; -- 会計帳簿ID
  cv_pro_org_cd             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12756'; -- 在庫組織コード
  cv_org_id_get_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12757'; -- 在庫組織ID
  cv_pro_company_cd         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12758'; -- 会社コード
  cv_var_elec_item_cd       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12759'; -- 変動電気料(品目コード)
  cv_busi_dept_cd           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12760'; -- 業務管理部
  cv_busi_emp_cd            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12761'; -- 業務管理部担当者
  cv_card_sale_cls_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12762'; -- カード売り区分取得エラー
  cv_tax_cls_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12763'; -- 消費税区分取得エラー
  cv_cust_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12764'; -- 顧客区分取得エラー
  cv_gyotai_err_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12765'; -- 業態小分類取得エラー
  cv_trxtype_err_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12766'; -- 取引タイプ取得エラー
  cv_itemdesp_err_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12767'; -- AR品目明細摘要取得エラー
  cv_tkn_ccid_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12768'; -- 勘定科目組合せマスタ
  cv_ccid_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12769'; -- CCID取得出来ないエラー
  cv_dis_item_cd            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12770'; -- 売上値引品目
  cv_jour_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12771'; -- 仕訳パターン取得エラー
  cv_tax_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12772'; -- 仮受消費税等(勘定科目用)
  cv_goods_msg              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12773'; -- 商品売上高(勘定科目用)
  cv_prod_msg               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12774'; -- 製品売上高(勘定科目用)
  cv_disc_msg               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12775'; -- 売上値引(勘定科目用)
  cv_success_aroif_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12776'; -- AR請求取引OIF成功件数メッセージ
  cv_success_ardis_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12777'; -- AR会計配分OIF成功件数メッセージ
  cv_term_id_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12778'; -- 支払条件ID取得エラー
  cv_tax_in_msg             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12779'; -- 内税コード取得エラー
  cv_tax_out_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12780'; -- 外税コード取得エラー
--
  -- トークン
  cv_tkn_pro                CONSTANT  VARCHAR2(20) := 'PROFILE';         -- プロファイル
  cv_tkn_tbl                CONSTANT  VARCHAR2(20) := 'TABLE';           -- テーブル名称
  cv_tkn_tbl_nm             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';      -- テーブル名称
  cv_tkn_lookup_type        CONSTANT  VARCHAR2(20) := 'LOOKUP_TYPE';     -- 参照タイプ
  cv_tkn_lookup_code        CONSTANT  VARCHAR2(20) := 'LOOKUP_CODE';     -- クイックコード
  cv_tkn_lookup_dff2        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE2';      -- 参照タイプのDFF2
  cv_tkn_lookup_dff3        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE3';      -- 参照タイプのDFF3
  cv_tkn_lookup_dff4        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE4';      -- 参照タイプのDFF4
  cv_tkn_lookup_dff5        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE5';      -- 参照タイプのDFF5
  cv_tkn_segment1           CONSTANT  VARCHAR2(20) := 'SEGMENT1';        -- 会社コード
  cv_tkn_segment2           CONSTANT  VARCHAR2(20) := 'SEGMENT2';        -- 部門コード
  cv_tkn_segment3           CONSTANT  VARCHAR2(20) := 'SEGMENT3';        -- 勘定科目コード
  cv_tkn_segment4           CONSTANT  VARCHAR2(20) := 'SEGMENT4';        -- 補助科目コード
  cv_tkn_segment5           CONSTANT  VARCHAR2(20) := 'SEGMENT5';        -- 顧客コード
  cv_tkn_segment6           CONSTANT  VARCHAR2(20) := 'SEGMENT6';        -- 企業コード
  cv_tkn_segment7           CONSTANT  VARCHAR2(20) := 'SEGMENT7';        -- 事業区分コード
  cv_tkn_segment8           CONSTANT  VARCHAR2(20) := 'SEGMENT8';        -- 予備
  cv_blank                  CONSTANT  VARCHAR2(1)  := '';                -- ブランク
  cv_and                    CONSTANT  VARCHAR2(6)  := ' AND ';           -- ブランク
  cv_tkn_key_data           CONSTANT  VARCHAR2(20) := 'KEY_DATA';        -- キー項目
--
  -- フラグ・区分定数
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';               -- フラグ値:Y
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';               -- フラグ値:N
  cv_card_class             CONSTANT  VARCHAR2(1)  := '1';               -- カード売り区分：カード= 1
  cv_cash_class             CONSTANT  VARCHAR2(1)  := '0';               -- カード売り区分：現金= 0
--
  -- クイックコードタイプ
  cv_qct_card_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_CARD_SALE_CLASS';         -- カード売区分特定マスタ
  cv_qct_gyotai_sho         CONSTANT  VARCHAR2(50) := 'XXCOS1_GYOTAI_SHO_MST_013_A01';  -- 業態小分類特定マスタ
  cv_qct_sale_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_SALE_CLASS_MST_013_A01';  -- 売上区分特定マスタ
  cv_qct_mkorg_cls          CONSTANT  VARCHAR2(50) := 'XXCOS1_MK_ORG_CLS_MST_013_A01';  -- 作成元区分特定マスタ
  cv_qct_dlv_slp_cls        CONSTANT  VARCHAR2(50) := 'XXCOS1_DLV_SLP_CLS_MST_013_A01'; -- 納品伝票区分特定マスタ
  cv_qcv_tax_cls            CONSTANT  VARCHAR2(50) := 'XXCOS1_CONSUMPTION_TAX_CLASS';   -- 消費税区分特定マスタ
  cv_qct_cust_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_CUS_CLASS_MST_013_A01';   -- 顧客区分特定マスタ
  cv_qct_item_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_ITEM_DTL_MST_013_A01';    -- AR品目明細摘要特定マスタ
  cv_qct_jour_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_JOUR_CLS_MST_013_A01';    -- AR会計配分仕訳特定マスタ
--
  -- クイックコード
  cv_qcc_code               CONSTANT  VARCHAR2(50) := 'XXCOS_013_A01%';                 -- クイックコード
  cv_attribute_y            CONSTANT  VARCHAR2(1)  := 'Y';                              -- DFF値'Y'
  cv_attribute_n            CONSTANT  VARCHAR2(1)  := 'N';                              -- DFF値'N'
  cv_attribute_a            CONSTANT  VARCHAR2(1)  := 'A';                              -- DFF値'A'
  cv_attribute_b            CONSTANT  VARCHAR2(1)  := 'B';                              -- DFF値'B'
  cv_enabled_yes            CONSTANT  VARCHAR2(1)  := 'Y';                              -- 使用可能フラグ定数:有効
  cv_attribute_1            CONSTANT  VARCHAR2(1)  := '1';                              -- DFF値'1'
  cv_attribute_2            CONSTANT  VARCHAR2(1)  := '2';                              -- DFF値'2'
--
  -- 請求取引OIFテーブルに設定する固定値
  cv_currency_code         CONSTANT  VARCHAR2(3)   := 'JPY';                            -- 通貨コード
  cv_line                  CONSTANT  VARCHAR2(4)   := 'LINE';                           -- 収益行
  cv_tax                   CONSTANT  VARCHAR2(3)   := 'TAX';                            -- 税金行
  cv_user                  CONSTANT  VARCHAR2(4)   := 'User';                           -- 換算タイプ用(Userを設定)
  cv_open                  CONSTANT  VARCHAR2(4)   := 'OPEN';                           -- ヘッダーDFF7(予備１)
  cv_wait                  CONSTANT  VARCHAR2(7)   := 'WAITING';                        -- ヘッダーDFF(予備)
  cv_round_rule_up         CONSTANT  VARCHAR2(10)  := 'UP';                             -- 切り上げ
  cv_round_rule_down       CONSTANT  VARCHAR2(10)  := 'DOWN';                           -- 切り下げ
  cv_round_rule_nearest    CONSTANT  VARCHAR2(10)  := 'NEAREST';                        -- 四捨五入
  cn_quantity              CONSTANT  NUMBER        := 1;                                -- 数量=1
  cn_con_rate              CONSTANT  NUMBER        := 1;                                -- 換算レート
  cn_percent               CONSTANT  NUMBER        := 100;                              -- 100
  cn_jour_cnt              CONSTANT  NUMBER        := 3;                                -- AR配分仕訳カウント
--
  -- AR会計配分OIFテーブルに設定する固定値
  cv_acct_rev              CONSTANT  VARCHAR2(4)   := 'REV';                            -- 配分タイプ：収益
  cv_acct_tax              CONSTANT  VARCHAR2(4)   := 'TAX';                            -- 配分タイプ：TAX
  cv_acct_rec              CONSTANT  VARCHAR2(4)   := 'REC';                            -- 配分タイプ：債権科目
  cv_nvd                   CONSTANT  VARCHAR2(4)   := 'NV';                             -- VD以外の業態と納品VD設定用
--
  -- 日付フォーマット
  cv_date_format_non_sep      CONSTANT VARCHAR2(20) := 'YYYYMMDD';
  cv_substr_st                CONSTANT NUMBER       := 7;
  cv_substr_cnt               CONSTANT NUMBER       := 2;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 販売実績ワークテーブル定義
  TYPE gr_sales_exp_rec IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- 販売実績ヘッダID
    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- 納品伝票番号
    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- 納品伝票区分
    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- 業態小分類
    , delivery_date             xxcos_sales_exp_headers.delivery_date%TYPE          -- 納品日
    , inspect_date              xxcos_sales_exp_headers.inspect_date%TYPE           -- 検収日
    , ship_to_customer_code     xxcos_sales_exp_headers.ship_to_customer_code%TYPE  -- 顧客【納品先】
    , tax_code                  xxcos_sales_exp_headers.tax_code%TYPE               -- 税金コード
    , tax_rate                  xxcos_sales_exp_headers.tax_rate%TYPE               -- 消費税率
    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 消費税区分
    , results_employee_code     xxcos_sales_exp_headers.results_employee_code%TYPE  -- 成績計上者コード
    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- 売上拠点コード
    , receiv_base_code          xxcos_sales_exp_headers.receiv_base_code%TYPE       -- 入金拠点コード
    , create_class              xxcos_sales_exp_headers.create_class%TYPE           -- 作成元区分
    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- カード売り区分
    , dlv_inv_line_no           xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE  -- 納品明細番号
    , item_code                 xxcos_sales_exp_lines.item_code%TYPE                -- 品目コード
    , sales_class               xxcos_sales_exp_lines.sales_class%TYPE              -- 売上区分
    , red_black_flag            xxcos_sales_exp_lines.red_black_flag%TYPE           -- 赤黒フラグ
    , goods_prod_cls            xxcos_good_prod_class_v.goods_prod_class_code%TYPE  -- 品目区分(製品・商品)
    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- 本体金額
    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- 消費税金額
    , cash_and_card             xxcos_sales_exp_lines.cash_and_card%TYPE            -- 現金・カード併用額
    , gccs_segment3             gl_code_combinations.segment3%TYPE                  -- 売上勘定科目コード
    , gcct_segment3             gl_code_combinations.segment3%TYPE                  -- 税金勘定科目コード
    , rcrm_receipt_id           ra_cust_receipt_methods.receipt_method_id%TYPE      -- 顧客支払方法ID
    , xchv_cust_id_s            xxcos_cust_hierarchy_v.ship_account_id%TYPE         -- 出荷先顧客ID
    , xchv_cust_id_b            xxcos_cust_hierarchy_v.bill_account_id%TYPE         -- 請求先顧客ID
    , xchv_cust_id_c            xxcos_cust_hierarchy_v.cash_account_id%TYPE         -- 入金先顧客ID
    , hcss_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- 顧客所在地参照ID(出荷先)
    , hcsb_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- 顧客所在地参照ID(請求先)
    , hcsc_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- 顧客所在地参照ID(入金先)
    , xchv_bill_pay_id          xxcos_cust_hierarchy_v.bill_payment_term_id%TYPE    -- 支払条件ID
    , xchv_bill_pay_id2         xxcos_cust_hierarchy_v.bill_payment_term2%TYPE      -- 支払条件2
    , xchv_bill_pay_id3         xxcos_cust_hierarchy_v.bill_payment_term3%TYPE      -- 支払条件3
    , xchv_tax_round            xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE     -- 税金－端数処理
    , rtt1_term_dd1             ra_terms_tl.name%TYPE                               -- 支払名称1
    , rtt2_term_dd2             ra_terms_tl.name%TYPE                               -- 支払名称2
    , rtt3_term_dd3             ra_terms_tl.name%TYPE                               -- 支払名称3
    , xseh_rowid                ROWID                                               -- ROWID
  );
--
  -- 仕訳パターンワークテーブル定義
  TYPE gr_jour_cls_rec IS RECORD(
      segment3_nm               fnd_lookup_values.description%TYPE                  -- 勘定科目名称
    , dlv_invoice_cls           fnd_lookup_values.attribute1%TYPE                   -- 納品伝票区分
    , item_prod_cls             fnd_lookup_values.attribute2%TYPE                   -- 品目コードOR製品・商品
    , cust_gyotai_sho           fnd_lookup_values.attribute3%TYPE                   -- 業態小分類
    , card_sale_cls             fnd_lookup_values.attribute4%TYPE                   -- カード売り区分
    , red_black_flag            fnd_lookup_values.attribute5%TYPE                   -- 赤黒フラグ
    , acct_type                 fnd_lookup_values.attribute6%TYPE                   -- 配分タイプ
    , segment2                  fnd_lookup_values.attribute7%TYPE                   -- 部門コード
    , segment3                  fnd_lookup_values.attribute8%TYPE                   -- 勘定科目コード
    , segment4                  fnd_lookup_values.attribute9%TYPE                   -- 補助勘定科目コード
    , segment5                  fnd_lookup_values.attribute10%TYPE                  -- 顧客コード
    , segment6                  fnd_lookup_values.attribute11%TYPE                  -- 企業コード
    , segment7                  fnd_lookup_values.attribute12%TYPE                  -- 事業区分コード
    , segment8                  fnd_lookup_values.attribute13%TYPE                  -- 予備１
    , amount_sign               fnd_lookup_values.attribute14%TYPE                  -- 金額符号
  );
--
  -- ワークテーブル定義
  TYPE gr_select_ccid IS RECORD(
      code_combination_id       gl_code_combinations.code_combination_id%TYPE       -- CCID
  );
  -- 品目明細ワークテーブル定義
  TYPE gr_sel_item_desp IS RECORD(
      description               fnd_lookup_values.description%TYPE                  -- 品目明細摘要
  );
  -- 取引タイプワークテーブル定義
  TYPE gr_sel_trx_type IS RECORD(
      attribute1                fnd_lookup_values.attribute1%TYPE                   -- 取引タイプ
  );
  -- AR会計配分集約用ワークテーブル定義
  TYPE gr_dis_sum IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- 販売実績ヘッダID
    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- 納品伝票番号
    , interface_line_dff4       VARCHAR2(20)                                        -- 自動採番:LINE
    , interface_tax_dff4        VARCHAR2(20)                                        -- 自動採番:TAX
    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- 納品伝票区分
    , item_code                 xxcos_sales_exp_lines.item_code%TYPE                -- 品目コード
    , goods_prod_cls            xxcos_good_prod_class_v.goods_prod_class_code%TYPE  -- 品目区分（製品・商品）
    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- 業態小分類
    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- 売上拠点コード
    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- カード売り区分
    , red_black_flag            xxcos_sales_exp_lines.red_black_flag%TYPE           -- 赤黒フラグ
    , gccs_segment3             gl_code_combinations.segment3%TYPE                  -- 売上勘定科目コード
    , gcct_segment3             gl_code_combinations.segment3%TYPE                  -- 税金勘定科目コード
    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- 本体金額
    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- 消費税金額
    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 消費税区分
  );
--
  -- 販売実績ワークテーブル型定義
  TYPE g_sales_exp_ttype IS TABLE OF gr_sales_exp_rec INDEX BY BINARY_INTEGER;
  gt_sales_exp_tbl              g_sales_exp_ttype;                                  -- 販売実績データ
  gt_sales_norm_tbl             g_sales_exp_ttype;                                  -- 販売実績非大手量販店データ
  gt_sales_bulk_tbl             g_sales_exp_ttype;                                  -- 販売実績大手量販店データ
  gt_norm_card_tbl              g_sales_exp_ttype;                                  -- 販売実績非大手量販店カードデータ
  gt_bulk_card_tbl              g_sales_exp_ttype;                                  -- 販売実績大手量販店カードデータ
--
  TYPE g_sales_h_ttype   IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  gt_sales_h_tbl                     g_sales_h_ttype;                               -- 販売実績フラグ更新用
--
  TYPE g_jour_cls_ttype  IS TABLE OF gr_jour_cls_rec INDEX BY BINARY_INTEGER;
  gt_jour_cls_tbl                    g_jour_cls_ttype;                              -- 仕訳パターン
--
  TYPE g_ar_oif_ttype    IS TABLE OF ra_interface_lines_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ar_interface_tbl                g_ar_oif_ttype;                                -- AR請求取引OIF
--
  TYPE g_ar_dis_ttype    IS TABLE OF ra_interface_distributions_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ar_dis_tbl                      g_ar_dis_ttype;                                -- AR会計配分OIF
--
  TYPE g_dis_sum_ttype   IS TABLE OF gr_dis_sum INDEX BY BINARY_INTEGER;
  gt_ar_dis_sum_tbl                  g_dis_sum_ttype;                               -- AR会計配分集約用
  gt_ar_dis_bul_tbl                  g_dis_sum_ttype;                               -- AR会計配分集約用(BULK)
--
  TYPE g_sel_ccid_ttype  IS TABLE OF gr_select_ccid INDEX BY VARCHAR2( 200 );
  gt_sel_ccid_tbl                    g_sel_ccid_ttype;                              -- CCID
--
  TYPE g_sel_item_ttype  IS TABLE OF gr_sel_item_desp INDEX BY VARCHAR2( 200 );
  gt_sel_item_desp_tbl               g_sel_item_ttype;                              -- 品目明細摘要
--
  TYPE g_sel_trx_ttype   IS TABLE OF gr_sel_trx_type INDEX BY VARCHAR2( 200 );
  gt_sel_trx_type_tbl                g_sel_trx_ttype;                               -- 取引タイプ
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --初期取得
  gd_process_date                     DATE;                                         -- 業務日付
  gv_company_code                     VARCHAR2(30);                                 -- 会社コード
  gv_set_bks_id                       VARCHAR2(30);                                 -- 会計帳簿ID
  gv_org_cd                           VARCHAR2(30);                                 -- 在庫組織コード
  gv_org_id                           VARCHAR2(30);                                 -- 在庫組織ID
  gv_mo_org_id                        VARCHAR2(30);                                 -- 営業単位ID
  gv_var_elec_item_cd                 VARCHAR2(30);                                 -- 変動電気料(品目コード)
  gv_busi_dept_cd                     VARCHAR2(30);                                 -- 業務管理部
  gv_busi_emp_cd                      VARCHAR2(30);                                 -- 業務管理部担当者
  gv_sales_nm                         VARCHAR2(30);                                 -- 文字列:販売実績
  gv_tax_msg                          VARCHAR2(20);                                 -- 文字列:仮受消費税等
  gv_goods_msg                        VARCHAR2(20);                                 -- 文字列:商品売上高
  gv_prod_msg                         VARCHAR2(20);                                 -- 文字列:製品売上高
  gv_disc_msg                         VARCHAR2(20);                                 -- 文字列:売上値引
  gv_item_tax                         VARCHAR2(30);                                 -- 品目明細摘要(TAX)
  gv_dis_item_cd                      VARCHAR2(30);                                 -- 売上値引品目コード
--
  gt_cust_cls_cd                      hz_cust_accounts.customer_class_code%TYPE;    -- 顧客区分（上様）
  gt_cash_sale_cls                    fnd_lookup_values.lookup_code%TYPE;           -- カード売り区分(現金:0)
  gt_fvd_xiaoka                       fnd_lookup_values.meaning%TYPE;               -- 業態小分類-フルVD（消化）:'24'
  gt_gyotai_fvd                       fnd_lookup_values.meaning%TYPE;               -- 業態小分類-フルVD:'25'
  gt_vd_xiaoka                        fnd_lookup_values.meaning%TYPE;               -- 業態小分類-消化VD:'27'
  gt_no_tax_cls                       fnd_lookup_values.attribute3%TYPE;            -- 消費区分-非課税:4
  gt_in_tax_cls                       fnd_lookup_values.attribute2%TYPE;            -- 消費区分-内税:2205
  gt_out_tax_cls                      fnd_lookup_values.attribute2%TYPE;            -- 消費区分-外税:2105
  gn_aroif_cnt                        NUMBER;                                       -- 正常件数（AR請求取引OIF）
  gn_ardis_cnt                        NUMBER;                                       -- 正常件数（AR会計配分OIF）
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 仕訳パターンカーソル
  CURSOR jour_cls_cur
  IS
    SELECT
           flvl.description           segment3_nm     -- 勘定科目名称
         , flvl.attribute1            dlv_invoice_cls -- 納品伝票区分
         , flvl.attribute2            item_prod_cls   -- 品目コード OR 品目区分(製品・商品)
         , flvl.attribute3            cust_gyotai_sho -- 業態小分類
         , flvl.attribute4            card_sale_cls   -- カード売り区分
         , flvl.attribute5            red_black_flag  -- 赤黒フラグ
         , flvl.attribute6            acct_type       -- 配分タイプ(REC・REV・TAX)
         , flvl.attribute7            segment2        -- 部門コード
         , flvl.attribute8            segment3        -- 勘定科目コード
         , flvl.attribute9            segment4        -- 補助勘定科目コード
         , flvl.attribute10           segment5        -- 顧客コード
         , flvl.attribute11           segment6        -- 企業コード
         , flvl.attribute12           segment7        -- 事業区分コード
         , flvl.attribute13           segment8        -- 予備１
         , flvl.attribute14           amount_sign     -- 金額符号
    FROM
            fnd_lookup_values         flvl
    WHERE
            flvl.lookup_type          = cv_qct_jour_cls
      AND   flvl.lookup_code          LIKE cv_qcc_code
      AND   flvl.enabled_flag         = cv_enabled_yes
      AND   flvl.language             = USERENV( 'LANG' )
      AND   gd_process_date BETWEEN   NVL( flvl.start_date_active, gd_process_date )
                            AND       NVL( flvl.end_date_active,   gd_process_date );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'init';             -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--#####################  固定ローカル変数宣言部 END     ########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ct_pro_bks_id            CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';
                                                               -- 会計帳簿ID
    ct_pro_org_cd            CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
                                                               -- XXCOI:在庫組織コード
    ct_pro_mo_org_cd         CONSTANT VARCHAR2(50) := 'ORG_ID';
                                                               -- MO:営業単位
    ct_pro_company_cd        CONSTANT VARCHAR2(30) := 'XXCOI1_COMPANY_CODE';
                                                               -- XXCOI:会社コード
    ct_var_elec_item_cd      CONSTANT VARCHAR2(30) := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
                                                               -- XXCOS:変動電気料(品目コード)
    ct_busi_dept_cd          CONSTANT VARCHAR2(30) := 'XXCOS1_BIZ_MAN_DEPT_CODE';
                                                               -- XXCOS:業務管理部
    ct_busi_emp_cd           CONSTANT VARCHAR2(30) := 'XXCOS1_BIZ_MAN_EMP';
                                                               -- XXCOS:業務管理部担当者
    ct_dis_item_cd           CONSTANT VARCHAR2(30) := 'XXCOS1_DISCOUNT_ITEM_CODE';
                                                               -- XXCOS:売上値引品目
--
    -- *** ローカル変数 ***
    lv_profile_name          VARCHAR2(50);                     -- プロファイル名
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--##################  固定ステータス初期化部 END     ###################
--
    --===================================================
    -- コンカレント入力パラメータなしメッセージ出力
    --===================================================
    gv_out_msg :=  xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_nm
                    ,iv_name         => cv_no_para_msg
                    );
--
    -- メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
   );
--
    --===================================================
    -- コンカレント入力パラメータなしログ出力
    --===================================================
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_blank
    );
--
    -- メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_blank
    );
--
    --==================================
    -- 業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務日付取得エラーの場合
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcos_short_nm, cv_process_date_msg );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得：会計帳簿ID
    -- ===============================
    gv_set_bks_id := FND_PROFILE.VALUE( ct_pro_bks_id );
    -- プロファイルが取得できない場合
    IF ( gv_set_bks_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_pro_bks_id                               -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得：在庫組織コード
    -- ===============================
    gv_org_cd := FND_PROFILE.VALUE( ct_pro_org_cd );
    -- プロファイルが取得できない場合
    IF ( gv_org_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_pro_org_cd                               -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 在庫組織ID取得
    -- ===============================
    gv_org_id := xxcoi_common_pkg.get_organization_id( gv_org_cd );
    -- 在庫組織ID取得できない場合はエラー
    IF ( gv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_nm
                     , iv_name        => cv_org_id_get_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- MO:営業単位取得
    --==================================
    gv_mo_org_id := FND_PROFILE.VALUE( ct_pro_mo_org_cd );
    -- プロファイルが取得できない場合
    IF ( gv_mo_org_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_pro_mo_org_cd                            -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOI:会社コード
    --==================================
    gv_company_code := FND_PROFILE.VALUE( ct_pro_company_cd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_company_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_pro_company_cd                           -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:変動電気料(品目コード)取得
    --==================================
    gv_var_elec_item_cd := FND_PROFILE.VALUE( ct_var_elec_item_cd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_var_elec_item_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_nm                          -- アプリケーション短縮名
        ,iv_name         => cv_var_elec_item_cd                        -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:業務管理部
    --==================================
    gv_busi_dept_cd := FND_PROFILE.VALUE( ct_busi_dept_cd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_busi_dept_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_busi_dept_cd                             -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:業務管理部担当者
    --==================================
    gv_busi_emp_cd := FND_PROFILE.VALUE( ct_busi_dept_cd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_busi_emp_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_busi_emp_cd                              -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:売上値引品目
    --==================================
    gv_dis_item_cd := FND_PROFILE.VALUE( ct_dis_item_cd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_dis_item_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_dis_item_cd                              -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 5.クイックコード取得
    --==================================
    -- カード売り区分=現金:0
    BEGIN
      SELECT flvl.lookup_code
      INTO   gt_cash_sale_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qct_card_cls
        AND  flvl.attribute3             = cv_attribute_y
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_card_sale_cls_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_card_cls
                      , iv_token_name2   => cv_tkn_lookup_dff3
                      , iv_token_value2  => cv_attribute_y
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- 消費税区分=非課税:4
    BEGIN
      SELECT flvl.attribute3
      INTO   gt_no_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qcv_tax_cls
        AND  flvl.attribute4             = cv_attribute_y
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_tax_cls_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qcv_tax_cls
                      , iv_token_name2   => cv_tkn_lookup_dff4
                      , iv_token_value2  => cv_attribute_y
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- 消費税区分=内税'2205'
    BEGIN
      SELECT flvl.attribute2
      INTO   gt_in_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qcv_tax_cls
        AND  flvl.attribute3             = cv_attribute_2
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_tax_in_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qcv_tax_cls
                      , iv_token_name2   => cv_tkn_lookup_dff3
                      , iv_token_value2  => cv_attribute_2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- 消費税区分=外税'2105'
    BEGIN
      SELECT flvl.attribute2
      INTO   gt_out_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qcv_tax_cls
        AND  flvl.attribute3             = cv_attribute_1
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    -- クイックコード取得出来ない場合
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_tax_out_msg
                        , iv_token_name1   => cv_tkn_lookup_type
                        , iv_token_value1  => cv_qcv_tax_cls
                        , iv_token_name2   => cv_tkn_lookup_dff3
                        , iv_token_value2  => cv_attribute_1
                      );
          lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- 顧客区分=上様:12
    BEGIN
      SELECT flvl.meaning
      INTO   gt_cust_cls_cd
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qct_cust_cls
        AND  flvl.lookup_code            LIKE cv_qcc_code
        AND  flvl.enabled_flag           = cv_enabled_yes
        AND  flvl.language               = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_cust_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_cust_cls
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- 業態小分類＝フルサービス（消化）VD :24
    BEGIN
      SELECT flvl.meaning                   meaning
      INTO   gt_fvd_xiaoka
      FROM   fnd_lookup_values              flvl
      WHERE  flvl.lookup_type               = cv_qct_gyotai_sho
        AND  flvl.lookup_code               LIKE cv_qcc_code
        AND  flvl.attribute2                = cv_attribute_a
        AND  flvl.enabled_flag              = cv_enabled_yes
        AND  flvl.language                  = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
                             AND            NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_gyotai_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_gyotai_sho
                      , iv_token_name2   => cv_tkn_lookup_dff2
                      , iv_token_value2  => cv_attribute_a
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- 業態小分類＝フルサービスVD :25
    BEGIN
      SELECT flvl.meaning                   meaning
      INTO   gt_gyotai_fvd
      FROM   fnd_lookup_values              flvl
      WHERE  flvl.lookup_type               = cv_qct_gyotai_sho
        AND  flvl.lookup_code               LIKE cv_qcc_code
        AND  flvl.attribute2                = cv_attribute_b
        AND  flvl.enabled_flag              = cv_enabled_yes
        AND  flvl.language                  = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
                             AND            NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_gyotai_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_gyotai_sho
                      , iv_token_name2   => cv_tkn_lookup_dff2
                      , iv_token_value2  => cv_attribute_b
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- 業態小分類＝消化VD :27
    BEGIN
      SELECT flvl.meaning                   meaning
      INTO   gt_vd_xiaoka
      FROM   fnd_lookup_values              flvl
      WHERE  flvl.lookup_type               = cv_qct_gyotai_sho
        AND  flvl.lookup_code               LIKE cv_qcc_code
        AND  flvl.attribute2                = cv_attribute_n
        AND  flvl.enabled_flag              = cv_enabled_yes
        AND  flvl.language                  = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
                             AND            NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_gyotai_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_gyotai_sho
                      , iv_token_name2   => cv_tkn_lookup_dff2
                      , iv_token_value2  => cv_attribute_n
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- クイックコード取得エラー
    WHEN global_no_lookup_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--##################################  固定例外処理部  END ####################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
      ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_table_name VARCHAR2(255);                                       -- テーブル名
    ln_bulk_idx   NUMBER DEFAULT 0;                                    -- 非大手量販店インデックス
    ln_norm_idx   NUMBER DEFAULT 0;                                    -- 大手量販店インデックス
--
    -- *** ローカル・カーソル (販売実績データ抽出)***
    CURSOR sales_data_cur
    IS
      SELECT
             xseh.sales_exp_header_id          sales_exp_header_id     -- 販売実績ヘッダID
           , xseh.dlv_invoice_number           dlv_invoice_number      -- 納品伝票番号
           , xseh.dlv_invoice_class            dlv_invoice_class       -- 納品伝票区分
           , xseh.cust_gyotai_sho              cust_gyotai_sho         -- 業態小分類
           , xseh.delivery_date                delivery_date           -- 納品日
           , xseh.inspect_date                 inspect_date            -- 検収日
           , xseh.ship_to_customer_code        ship_to_customer_code   -- 顧客【納品先】
           , xseh.tax_code                     tax_code                -- 税金コード
           , xseh.tax_rate                     tax_rate                -- 消費税率
           , xseh.consumption_tax_class        consumption_tax_class   -- 消費税区分
           , xseh.results_employee_code        results_employee_code   -- 成績計上者コード
           , xseh.sales_base_code              sales_base_code         -- 売上拠点コード
           , xseh.receiv_base_code             receiv_base_code        -- 入金拠点コード
           , xseh.create_class                 create_class            -- 作成元区分
           , NVL( xseh.card_sale_class, cv_cash_class )
                                               card_sale_class         -- カード売り区分
           , xsel.dlv_invoice_line_number      dlv_inv_line_no         -- 納品明細番号
           , xsel.item_code                    item_code               -- 品目コード
           , xsel.sales_class                  sales_class             -- 売上区分
           , xsel.red_black_flag               red_black_flag          -- 赤黒フラグ
           , xgpc.goods_prod_class_code        goods_prod_cls          -- 品目区分（製品・商品）
           , xsel.pure_amount                  pure_amount             -- 本体金額
           , xsel.tax_amount                   tax_amount              -- 消費税額
           , NVL( xsel.cash_and_card, 0 )      cash_and_card           -- 現金・カード併用額
           , gcc.segment3                      gccs_segment3           -- 売上勘定科目コード
           , gcct.segment3                     gcct_segment3           -- 税金勘定科目コード
           , rcrm.receipt_method_id            rcrm_receipt_id         -- 顧客支払方法ID
           , xchv.ship_account_id              xchv_cust_id_s          -- 出荷先顧客ID
           , xchv.bill_account_id              xchv_cust_id_b          -- 請求先顧客ID
           , xchv.cash_account_id              xchv_cust_id_c          -- 入金先顧客ID
           , hcss.cust_acct_site_id            hcss_org_sys_id         -- 顧客所在地参照ID（出荷先）
           , hcsb.cust_acct_site_id            hcsb_org_sys_id         -- 顧客所在地参照ID（請求先）
           , hcsc.cust_acct_site_id            hcsc_org_sys_id         -- 顧客所在地参照ID（入金先）
           , xchv.bill_payment_term_id         xchv_bill_pay_id        -- 支払条件ID
           , xchv.bill_payment_term2           xchv_bill_pay_id2       -- 支払条件2
           , xchv.bill_payment_term3           xchv_bill_pay_id3       -- 支払条件3
           , xchv.bill_tax_round_rule          xchv_tax_round          -- 税金－端数処理
           , SUBSTR(rtt1.name,1,2)             rtt1_term_dd1           -- 支払名称1の先頭２バイト
           , SUBSTR(rtt2.name,1,2)             rtt2_term_dd2           -- 支払名称2の先頭２バイト
           , SUBSTR(rtt3.name,1,2)             rtt3_term_dd3           -- 支払名称3の先頭２バイト
           , xseh.rowid                        xseh_rowid              -- ROWID
      FROM
             xxcos_sales_exp_headers           xseh                    -- 販売実績ヘッダテーブル
           , xxcos_sales_exp_lines             xsel                    -- 販売実績明細テーブル
           , mtl_system_items_b                msib                    -- 品目マスタ
           , gl_code_combinations              gcc                     -- 勘定科目組合せマスタ
           , gl_code_combinations              gcct                    -- 勘定科目組合せマスタ（TAX用）
           , ar_vat_tax_all_b                  avta                    -- 税金マスタ
           , hz_cust_accounts                  hcas                    -- 顧客マスタ（出荷先）
           , hz_cust_accounts                  hcab                    -- 顧客マスタ（請求先）
           , hz_cust_accounts                  hcac                    -- 顧客マスタ（入金先）
           , hz_cust_acct_sites_all            hcss                    -- 顧客所在地（出荷先）
           , hz_cust_acct_sites_all            hcsb                    -- 顧客所在地（請求先）
           , hz_cust_acct_sites_all            hcsc                    -- 顧客所在地（入金先）
           , ra_terms_tl                       rtt1                    -- AR支払条件(1)
           , ra_terms_tl                       rtt2                    -- AR支払条件(2)
           , ra_terms_tl                       rtt3                    -- AR支払条件(3)
           , ra_cust_receipt_methods           rcrm                    -- 顧客支払方法
           , xxcos_good_prod_class_v           xgpc                    -- 品目区分View
           , xxcos_cust_hierarchy_v            xchv                    -- 顧客階層ビュー
           , hz_cust_site_uses_all             scsua                   -- 顧客使用目的
      WHERE
          xseh.sales_exp_header_id              = xsel.sales_exp_header_id
      AND xseh.dlv_invoice_number               = xsel.dlv_invoice_number
      AND xseh.ar_interface_flag                = cv_n_flag
      AND xseh.delivery_date                   <= gd_process_date
      AND xsel.item_code                       <> gv_var_elec_item_cd
      AND xchv.ship_account_number              = xseh.ship_to_customer_code
      AND hcss.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcsb.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcsc.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcas.account_number                   = xseh.ship_to_customer_code
      AND hcab.account_number                   = xchv.bill_account_number
      AND hcac.account_number                   = xchv.cash_account_number
      AND hcas.customer_class_code             <> gt_cust_cls_cd
      AND ( xseh.cust_gyotai_sho               <> gt_gyotai_fvd
         OR ( xseh.cust_gyotai_sho              = gt_gyotai_fvd
           AND NVL( xseh.card_sale_class, cv_cash_class )
                                               <> gt_cash_sale_cls )
         OR ( xseh.cust_gyotai_sho              = gt_gyotai_fvd
           AND NVL( xseh.card_sale_class, cv_cash_class )
                                                = gt_cash_sale_cls
           AND NVL( xsel.cash_and_card, 0 )     > 0 ) )
      AND avta.tax_code                         = xseh.tax_code
      AND avta.set_of_books_id                  = TO_NUMBER( gv_set_bks_id )
      AND avta.enabled_flag                     = cv_enabled_yes
      AND gd_process_date BETWEEN               NVL( avta.start_date, gd_process_date )
                          AND                   NVL( avta.end_date,   gd_process_date )
      AND gcct.code_combination_id              = avta.tax_account_id
          AND msib.organization_id              = TO_NUMBER( gv_org_id )
          AND xsel.item_code                    = msib.segment1
          AND gcc.code_combination_id           = msib.sales_account
          AND xgpc.segment1( + )                = xsel.item_code
      AND xseh.create_class                     NOT IN (
          SELECT
              flvl.meaning                      meaning
          FROM
              fnd_lookup_values                 flvl
          WHERE
              flvl.lookup_type                  = cv_qct_mkorg_cls
          AND flvl.lookup_code                  LIKE cv_qcc_code
          AND flvl.attribute2                   = cv_attribute_y
          AND flvl.enabled_flag                 = cv_enabled_yes
          AND flvl.language                     = USERENV( 'LANG' )
          AND gd_process_date BETWEEN           NVL( flvl.start_date_active, gd_process_date )
                              AND               NVL( flvl.end_date_active,   gd_process_date )
          )
      AND xsel.sales_class                      NOT IN (
          SELECT
              flvl.meaning                      meaning
          FROM
              fnd_lookup_values                 flvl
          WHERE
              flvl.lookup_type                  = cv_qct_sale_cls
          AND flvl.lookup_code                  LIKE cv_qcc_code
          AND flvl.attribute1                   = cv_attribute_y
          AND flvl.enabled_flag                 = cv_enabled_yes
          AND flvl.language                     = USERENV( 'LANG' )
          AND gd_process_date BETWEEN           NVL( flvl.start_date_active, gd_process_date )
                              AND               NVL( flvl.end_date_active,   gd_process_date )
          )
      AND hcss.cust_account_id                  = hcas.cust_account_id
      AND hcsb.cust_account_id                  = hcab.cust_account_id
      AND hcsc.cust_account_id                  = hcac.cust_account_id
      AND xchv.ship_account_id                  = hcas.cust_account_id
      AND rcrm.customer_id                      = hcab.cust_account_id
      AND rcrm.primary_flag                     = cv_y_flag
      AND rcrm.site_use_id                      = scsua.site_use_id
      AND gd_process_date BETWEEN               NVL( rcrm.start_date, gd_process_date )
                          AND                   NVL( rcrm.end_date,   gd_process_date )
      AND scsua.site_use_code                   = 'BILL_TO'
      AND rtt1.term_id                          = xchv.bill_payment_term_id
      AND rtt1.language                         = USERENV( 'LANG' )
      AND rtt2.term_id                          = xchv.bill_payment_term2
      AND rtt2.language                         = USERENV( 'LANG' )
      AND rtt3.term_id                          = xchv.bill_payment_term3
      AND rtt3.language                         = USERENV( 'LANG' )
      ORDER BY xseh.sales_exp_header_id
             , xseh.dlv_invoice_number
             , xseh.dlv_invoice_class
             , NVL( xseh.card_sale_class, cv_cash_class )
             , xseh.cust_gyotai_sho
             , xsel.item_code
             , xsel.red_black_flag
             , gcc.segment3
             , gcct.segment3
    FOR UPDATE OF  xseh.sales_exp_header_id
    NOWAIT;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN  sales_data_cur;
    FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_tbl;
--
    -- カーソルクローズ
    CLOSE sales_data_cur;
--
    -- 対象処理件数
    gn_target_cnt   := gt_sales_exp_tbl.COUNT;
--
    IF ( gn_target_cnt > 0 ) THEN
      -- 非大手量販店データと大手量販店データの分離
      -- 抽出された販売実績データのループ
      <<gt_sales_exp_tbl_loop>>
      FOR sale_idx IN 1 .. gn_target_cnt LOOP
        IF ( gt_sales_exp_tbl( sale_idx ).receiv_base_code = gv_busi_dept_cd ) THEN
          -- 大手量販店データを抽出
          ln_bulk_idx := ln_bulk_idx + 1;
          gt_sales_bulk_tbl( ln_bulk_idx ) := gt_sales_exp_tbl( sale_idx );
        ELSE
          -- 非大手量販店データを抽出
          ln_norm_idx := ln_norm_idx + 1;
          gt_sales_norm_tbl( ln_norm_idx ) := gt_sales_exp_tbl( sale_idx );
        END IF;
      END LOOP gt_sales_exp_tbl_loop;                                  -- 販売実績データループ終了
    ELSIF ( gn_target_cnt = 0 ) THEN
      -- 対象データ無しメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_no_data_msg
                   );
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_warn;
      RAISE global_no_data_expt;
    ELSE
      ov_retcode := cv_status_error;
      RAISE global_select_data_expt;
    END IF;
--
    --=====================================
    -- 全角文字列取得
    --=====================================
    -- １．販売実績
    gv_sales_nm := xxccp_common_pkg.get_msg(
                       iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                     , iv_name              => cv_sales_nm_msg         -- メッセージID
                     );
    -- ２．仮受消費税等
    gv_tax_msg   := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxcos_short_nm              -- アプリケーション短縮名
                    , iv_name        => cv_tax_msg                     -- メッセージID(仮受消費税等)
                    );
    -- ３．商品売上高
    gv_goods_msg := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_short_nm            -- アプリケーション短縮名
                      , iv_name        => cv_goods_msg                 -- メッセージID(商品売上高)
                    );
    -- ４．製品売上高
    gv_prod_msg  := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_short_nm            -- アプリケーション短縮名
                      , iv_name        => cv_prod_msg                  -- メッセージID(製品売上高)
                    );
    -- ５．売上値引高
    gv_disc_msg  := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_short_nm            -- アプリケーション短縮名
                      , iv_name        => cv_disc_msg                  -- メッセージID(売上値引)
                    );
--
    --=====================================================================
    -- 品目明細摘要の取得(「仮受消費税等」のみ)(A-3 と A-5用)
    --=====================================================================
    BEGIN
      SELECT flvi.description
      INTO   gv_item_tax
      FROM   fnd_lookup_values              flvi                         -- AR品目明細摘要特定マスタ
      WHERE  flvi.lookup_type               = cv_qct_item_cls
        AND  flvi.lookup_code               LIKE cv_qcc_code
        AND  flvi.attribute1                = cv_tax
        AND  flvi.enabled_flag              = cv_enabled_yes
        AND  flvi.language                  = USERENV( 'LANG' )
        AND  gd_process_date BETWEEN        NVL( flvi.start_date_active, gd_process_date )
                             AND            NVL( flvi.end_date_active,   gd_process_date );
--
      -- AR品目明細摘要(仮受消費税等)取得出来ない場合
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_itemdesp_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_item_cls
                    );
        lv_errbuf  := lv_errmsg;
--
        RAISE global_no_lookup_expt;
    END;
--
      -- 取得したAR品目明細摘要をワークテーブルに設定する
      gt_sel_item_desp_tbl( cv_tax ).description := gv_item_tax;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm        -- アプリケーション短縮名
                         , iv_name         => cv_tkn_sales_msg         -- メッセージID
                       );
      lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_table_lock_msg
                         , iv_token_name1  => cv_tkn_tbl
                         , iv_token_value1 => lv_table_name
                       );
      lv_errbuf     := lv_errmsg;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
--
    -- *** 対象データなし *** 
    WHEN global_no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** データ取得例外 *** 
    WHEN global_select_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- クイックコード取得エラー
    WHEN global_no_lookup_expt THEN
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_nm
                      , iv_name         => cv_data_get_msg
                    );
      lv_errbuf  := lv_errmsg;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_sum_data
   * Description      : 請求取引集約処理（非大手量販店）(A-3)
   ***********************************************************************************/
  PROCEDURE edit_sum_data(
      ov_errbuf         OUT VARCHAR2         -- エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2         -- リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_sum_data';          -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                  -- リターン・コード
    lv_errmsg  VARCHAR2(5000);               -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_card_idx             NUMBER DEFAULT 0;           -- 生成したカードレコードのインデックス
    ln_card_pt              NUMBER DEFAULT 1;           -- カードレコードのインデックス現行位置
    ln_ar_idx               NUMBER DEFAULT 0;           -- 請求取引OIFインデックス
    ln_ar_sum               NUMBER DEFAULT 0;           -- AR配分OIF集約データインデックス;
    ln_trx_idx              NUMBER DEFAULT 0;           -- AR配分OIF集約データインデックス;
    lv_trx_type_nm          VARCHAR2(30);               -- 取引タイプ名称
    lv_trx_idx              VARCHAR2(30);               -- 取引タイプ(インデックス)
    lv_item_idx             VARCHAR2(30);               -- 品目明細摘要(インデックス)
    lv_item_desp            VARCHAR2(30);               -- 品目明細摘要(TAX以外)
    ln_term_id              NUMBER;                     -- 支払条件ID
    lv_cust_gyotai_sho      VARCHAR2(30);               -- 業態小分類
    ln_pure_amount          NUMBER DEFAULT 0;           -- カードレコードの本体金額
    ln_tax_amount           NUMBER DEFAULT 0;           -- カードレコードの消費税金額
    ln_tax                  NUMBER DEFAULT 0;           -- 集約後消費税金額
    ln_amount               NUMBER DEFAULT 0;           -- 集約後金額
    ln_tax_card             NUMBER DEFAULT 0;           -- 集約後消費税金額(カードレコード)
    ln_amount_card          NUMBER DEFAULT 0;           -- 集約後金額(カードレコード)
    ln_trx_number_id        NUMBER;                     -- 取引明細DFF3用:自動採番番号
--
    -- 集約キー(販売実績)
    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
                                                        -- 集約キー：販売実績ヘッダID
    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
                                                        -- 集約キー：納品伝票番号
    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
                                                        -- 集約キー：納品伝票区分
    lt_goods_prod_cls       xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                        -- 集約キー：品目区分（製品・商品）
    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
                                                        -- 集約キー：品目コード（非在庫）
    lt_card_sale_class      xxcos_sales_exp_headers.card_sale_class%TYPE;
                                                        -- 集約キー：カード売り区分
    lt_red_black_flag       xxcos_sales_exp_lines.red_black_flag%TYPE;
                                                        -- 集約キー：赤黒フラグ
--
    -- 集約キー(生成したカードレコード)
    lt_header_id_card       xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
                                                        -- 集約キー：販売実績ヘッダID
    lt_invo_number_card     xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
                                                        -- 集約キー：納品伝票番号
    lt_invo_class_card      xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
                                                        -- 集約キー：納品伝票区分
    lt_goods_prod_card      xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                        -- 集約キー：品目区分コード（製品・商品）
    lt_item_code_card       xxcos_sales_exp_lines.item_code%TYPE;
                                                        -- 集約キー：品目コード（非在庫）
--
    lv_sum_flag             VARCHAR2(1);                -- 集約フラグ
    lv_sum_card_flag        VARCHAR2(1);                -- カード集約フラグ
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソ ***
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
    --=====================================================================
    -- ４．フルサービスVDとフルサービス（消化）VDのカード・現金併用データの編集
    --=====================================================================
    <<gt_sales_norm_tbl_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
      -- 現金・カード併用の場合-->カード売り区分=現金:0 かつ 現金カード併用額>0
      IF ( (   gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho = gt_fvd_xiaoka
            OR gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho = gt_gyotai_fvd )
        AND (  gt_sales_norm_tbl( sale_norm_idx ).card_sale_class = gt_cash_sale_cls
          AND  gt_sales_norm_tbl( sale_norm_idx ).cash_and_card   > 0 ) ) THEN
--
        -- カードレコードの本体金額
        ln_pure_amount := gt_sales_norm_tbl( sale_norm_idx ).cash_and_card
                        / ( 1 + gt_sales_norm_tbl( sale_norm_idx ).tax_rate/cn_percent );
--
        -- 端数処理
        IF ( gt_sales_norm_tbl( sale_norm_idx ).xchv_tax_round    = cv_round_rule_up ) THEN
          -- 切り上げの場合
          ln_pure_amount := CEIL( ln_pure_amount );
--
        ELSIF ( gt_sales_norm_tbl( sale_norm_idx ).xchv_tax_round = cv_round_rule_down ) THEN
          -- 切り下げの場合
          ln_pure_amount := FLOOR( ln_pure_amount );
--
        ELSIF ( gt_sales_norm_tbl( sale_norm_idx ).xchv_tax_round = cv_round_rule_nearest ) THEN
          -- 四捨五入の場合
          ln_pure_amount := ROUND( ln_pure_amount );
        END IF;
--
        -- 課税の場合、カードレコードの消費税額を算出する
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax_amount := gt_sales_norm_tbl( sale_norm_idx ).cash_and_card - ln_pure_amount;
        ELSE
          ln_tax_amount := 0;
        END IF;
--
        --==============================================================
        --販売実績カードワークテーブルへのカードレコード登録
        --==============================================================
        ln_card_idx := ln_card_idx + 1;
--
        -- カードレコード全カラムの設定
        gt_norm_card_tbl( ln_card_idx ) := gt_sales_norm_tbl( sale_norm_idx );
--
        -- カードレコードカード売り区分、本体金額、消費税金額の設定
        gt_norm_card_tbl( ln_card_idx ).card_sale_class     := cv_card_class;
                                                            -- カード売り区分（１：カード）
        gt_norm_card_tbl( ln_card_idx ).pure_amount         := ln_pure_amount;
                                                            -- 本体金額
        gt_norm_card_tbl( ln_card_idx ).tax_amount          := ln_tax_amount;
                                                            -- 消費税金額
      END IF;
    END LOOP gt_sales_norm_tbl_loop;                        -- 非大手量販店併用データ編集終了
--
      --=====================================================================
      -- 請求取引集約処理（非大手量販店）開始
      --=====================================================================
    -- 集約キーの値セット
    lt_header_id        := gt_sales_norm_tbl( 1 ).sales_exp_header_id;
    lt_invoice_number   := gt_sales_norm_tbl( 1 ).dlv_invoice_number;
    lt_invoice_class    := gt_sales_norm_tbl( 1 ).dlv_invoice_class;
    lt_goods_prod_cls   := gt_sales_norm_tbl( 1 ).goods_prod_cls;
    lt_item_code        := gt_sales_norm_tbl( 1 ).item_code;
    lt_card_sale_class  := gt_sales_norm_tbl( 1 ).card_sale_class;
    lt_red_black_flag   := gt_sales_norm_tbl( 1 ).red_black_flag;
--
    -- ラストデータ登録為に、ダミーデータをセット
    gt_sales_norm_tbl( gt_sales_norm_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_sales_norm_tbl( gt_sales_norm_tbl.COUNT ).sales_exp_header_id;
    IF ( gt_norm_card_tbl.COUNT > 0 ) THEN
      gt_norm_card_tbl( gt_norm_card_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_norm_card_tbl( gt_norm_card_tbl.COUNT ).sales_exp_header_id;
    END IF;
--
    <<gt_sales_norm_sum_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
--
      --=====================================
      --5-1.販売実績元データの集約
      --=====================================
      IF (  lt_header_id        = gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id
        AND lt_invoice_number   = gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number
        AND lt_invoice_class    = gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_class
        AND ( lt_goods_prod_cls = gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls
          OR lt_item_code       = gt_sales_norm_tbl( sale_norm_idx ).item_code )
        AND lt_card_sale_class  = gt_sales_norm_tbl( sale_norm_idx ).card_sale_class
        AND lt_red_black_flag   = gt_sales_norm_tbl( sale_norm_idx ).red_black_flag
        ) THEN
--
        -- 集約するフラグ初期設定
        lv_sum_flag      := cv_y_flag;
        lv_sum_card_flag := cv_y_flag;
--
        -- 本体金額を集約する
        ln_amount := ln_amount + gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
--
        -- 課税の場合、消費税額を集約する
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax := ln_tax + gt_sales_norm_tbl( sale_norm_idx ).tax_amount;
        END IF;
--
        --=====================================
        --5-2.上記4で生成したカードレコードの集約
        --=====================================
        IF ( gt_sales_norm_tbl( sale_norm_idx ).card_sale_class = cv_card_class ) THEN
          <<gt_norm_card_tbl_loop>>
          FOR i IN ln_card_pt .. gt_norm_card_tbl.COUNT LOOP
            IF (  lt_header_id        = gt_norm_card_tbl( i ).sales_exp_header_id
              AND lt_invoice_number   = gt_norm_card_tbl( i ).dlv_invoice_number
              AND lt_invoice_class    = gt_norm_card_tbl( i ).dlv_invoice_class
              AND ( lt_goods_prod_cls = gt_norm_card_tbl( i ).goods_prod_cls
                OR  lt_item_code      = gt_norm_card_tbl( i ).item_code )
              ) THEN
              -- 本体金額を集約する
              ln_amount   := ln_amount + gt_norm_card_tbl( i ).pure_amount;
              -- 課税の場合、消費税額を集約する
              IF ( gt_norm_card_tbl( i ).consumption_tax_class != gt_no_tax_cls ) THEN
                ln_tax := ln_tax + gt_norm_card_tbl( i ).tax_amount;
              END IF;
            END IF;
            -- カードレコードの現ポイントをカウントする
            ln_card_pt := i;
          END LOOP gt_norm_card_tbl_loop;
--
        -- 生成したカードレコードだけの集約
        ELSIF ( ( gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho = gt_fvd_xiaoka
            OR gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho = gt_gyotai_fvd )
          AND gt_sales_norm_tbl( sale_norm_idx ).card_sale_class = gt_cash_sale_cls
          AND gt_sales_norm_tbl( sale_norm_idx ).cash_and_card > 0
          AND ln_card_pt < gt_norm_card_tbl.COUNT
          ) THEN
--
          ln_amount_card := 0;
          ln_tax_card  := 0;
--
          -- 生成したカードレコードだけの集約開始
          <<gt_norm_card_tbl_loop>>
          FOR i IN ln_card_pt .. gt_norm_card_tbl.COUNT LOOP
            IF (  lt_header_id        = gt_norm_card_tbl( i ).sales_exp_header_id
              AND lt_invoice_number   = gt_norm_card_tbl( i ).dlv_invoice_number
              AND lt_invoice_class    = gt_norm_card_tbl( i ).dlv_invoice_class
              AND ( lt_goods_prod_cls = gt_norm_card_tbl( i ).goods_prod_cls
                OR lt_item_code       = gt_norm_card_tbl( i ).item_code )
            ) THEN
              -- 本体金額を集約する
              ln_amount_card := ln_amount_card + gt_norm_card_tbl( i ).pure_amount;
              -- 課税の場合、消費税額を集約する
              IF ( gt_norm_card_tbl( i ).consumption_tax_class != gt_no_tax_cls ) THEN
                ln_tax_card  := ln_tax_card + gt_norm_card_tbl( i ).tax_amount;
              END IF;
            ELSE
              -- カードレコードの現ポイントをカウントする
              ln_card_pt := i;
              -- 集約フラグ’N'を設定
              lv_sum_card_flag := cv_n_flag;
--
            END IF;
--
          END LOOP gt_norm_card_tbl_loop;
--
        END IF; -- 生成したカードレコードだけの集約終了
      ELSE
--
        lv_sum_flag := cv_n_flag;
        ln_trx_idx  := sale_norm_idx - 1;
      END IF;
--
      IF ( lv_sum_flag = cv_n_flag OR lv_sum_card_flag = cv_n_flag ) THEN
        --=====================================================================
        -- １．支払条件IDの取得
        --=====================================================================
        IF ( SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                   , cv_substr_st, cv_substr_cnt )
             <= gt_sales_norm_tbl( ln_trx_idx ).rtt1_term_dd1 ) THEN
          -- 支払条件 ID
          ln_term_id := gt_sales_norm_tbl( ln_trx_idx ).xchv_bill_pay_id;
--
        ELSIF( SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               > gt_sales_norm_tbl( ln_trx_idx ).rtt1_term_dd1
           AND SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               <= gt_sales_norm_tbl( ln_trx_idx ).rtt2_term_dd2 ) THEN
          -- 第2支払条件 ID
          ln_term_id := gt_sales_norm_tbl( ln_trx_idx ).xchv_bill_pay_id2;
--
        ELSIF( SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               > gt_sales_norm_tbl( ln_trx_idx ).rtt2_term_dd2
           AND SUBSTR( TO_CHAR( gt_sales_norm_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               <= gt_sales_norm_tbl( ln_trx_idx ).rtt3_term_dd3 ) THEN
          -- 第3支払条件 ID
          ln_term_id := gt_sales_norm_tbl( ln_trx_idx ).xchv_bill_pay_id3;
        ELSE
          -- 支払条件IDの取得ができない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_term_id_msg
                      );
          lv_errbuf  := lv_errmsg;
--
          RAISE global_term_id_expt;
        END IF;
--
        --=====================================================================
        -- ２．取引タイプの取得
        --=====================================================================
        lv_trx_idx := gt_sales_norm_tbl( ln_trx_idx ).create_class
                   || gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class;
        IF ( gt_sel_trx_type_tbl.EXISTS( lv_trx_idx ) ) THEN
          lv_trx_type_nm := gt_sel_trx_type_tbl( lv_trx_idx ).attribute1;
        ELSE
          BEGIN
            SELECT flvm.attribute1 || flvd.attribute1
            INTO   lv_trx_type_nm
            FROM   fnd_lookup_values              flvm                     -- 作成元区分特定マスタ
                 , fnd_lookup_values              flvd                     -- 納品伝票区分特定マスタ
            WHERE  flvm.lookup_type               = cv_qct_mkorg_cls
              AND  flvd.lookup_type               = cv_qct_dlv_slp_cls
              AND  flvm.lookup_code               LIKE cv_qcc_code
              AND  flvd.lookup_code               LIKE cv_qcc_code
              AND  flvm.meaning                   = gt_sales_norm_tbl( ln_trx_idx ).create_class
              AND  flvd.meaning                   = gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class
              AND  flvm.enabled_flag              = cv_enabled_yes
              AND  flvd.enabled_flag              = cv_enabled_yes
              AND  flvm.language                  = USERENV( 'LANG' )
              AND  flvd.language                  = USERENV( 'LANG' )
              AND  gd_process_date BETWEEN        NVL( flvm.start_date_active, gd_process_date )
                                   AND            NVL( flvm.end_date_active,   gd_process_date )
              AND  gd_process_date BETWEEN        NVL( flvd.start_date_active, gd_process_date )
                                   AND            NVL( flvd.end_date_active,   gd_process_date );
--
          -- 取引タイプ取得出来ない場合
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_trxtype_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_mkorg_cls 
                                               || cv_and
                                               || cv_qct_dlv_slp_cls
                          );
              lv_errbuf  := lv_errmsg;
--
              RAISE global_no_lookup_expt;
          END;
--
          -- 取得した取引タイプをワークテーブルに設定する
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute1 := lv_trx_type_nm;
--
        END IF;
--
        --=====================================================================
        -- 3．品目明細摘要の取得(「仮受消費税等」以外)
        --=====================================================================
--
        -- 品目明細摘要の存在チェック-->存在している場合、取得必要がない
        IF ( gt_sales_norm_tbl( ln_trx_idx ).goods_prod_cls IS NULL ) THEN
          lv_item_idx := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class
                      || gt_sales_norm_tbl( ln_trx_idx ).item_code;
        ELSE
          lv_item_idx := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class
                      || gt_sales_norm_tbl( ln_trx_idx ).goods_prod_cls;
        END IF;
--
        IF ( gt_sel_item_desp_tbl.EXISTS( lv_item_idx ) ) THEN
          lv_item_desp := gt_sel_item_desp_tbl( lv_item_idx ).description;
        ELSE
          BEGIN
            SELECT flvi.description
            INTO   lv_item_desp
            FROM   fnd_lookup_values              flvi                     -- AR品目明細摘要特定マスタ
            WHERE  flvi.lookup_type               = cv_qct_item_cls
              AND  flvi.lookup_code               LIKE cv_qcc_code
              AND  flvi.attribute1                = gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class
              AND  flvi.attribute2                = NVL( gt_sales_norm_tbl( ln_trx_idx ).goods_prod_cls,
                                                         gt_sales_norm_tbl( ln_trx_idx ).item_code )
              AND  flvi.enabled_flag              = cv_enabled_yes
              AND  flvi.language                  = USERENV( 'LANG' )
              AND  gd_process_date BETWEEN        NVL( flvi.start_date_active, gd_process_date )
                                   AND            NVL( flvi.end_date_active,   gd_process_date );
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- AR品目明細摘要取得出来ない場合
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_itemdesp_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_item_cls
                          );
              lv_errbuf  := lv_errmsg;
--
              RAISE global_no_lookup_expt;
          END;
--
          -- 取得したAR品目明細摘要をワークテーブルに設定する
          gt_sel_item_desp_tbl( lv_item_idx ).description := lv_item_desp;
        END IF;
--
      END IF;
--
      --==============================================================
      -- ６．AR請求取引OIFデータ作成
      --==============================================================
--
      -- -- 集約フラグ’N'の場合、AR請求取引OIFデータ作成する
      IF ( lv_sum_flag = cv_n_flag ) THEN 
--
        -- AR請求取引OIFの収益行
        ln_ar_idx   := ln_ar_idx  + 1;
        ln_ar_sum   := ln_ar_sum  + 1;
--
        -- 取引明細DFF4用:自動採番番号
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR会計配分集約用データ格納
        gt_ar_dis_sum_tbl( ln_ar_sum ).sales_exp_header_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- 販売実績ヘッダID
        gt_ar_dis_sum_tbl( ln_ar_sum ).dlv_invoice_number
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- 納品伝票番号
        gt_ar_dis_sum_tbl( ln_ar_sum ).interface_line_dff4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- 納品伝票番号+自動採番
        gt_ar_dis_sum_tbl( ln_ar_sum ).dlv_invoice_class
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_class;
                                                        -- 納品伝票区分
        gt_ar_dis_sum_tbl( ln_ar_sum ).item_code        := gt_sales_norm_tbl( ln_trx_idx ).item_code;
                                                        -- 品目コード
        gt_ar_dis_sum_tbl( ln_ar_sum ).goods_prod_cls   := gt_sales_norm_tbl( ln_trx_idx ).goods_prod_cls;
                                                        -- 品目区分（製品・商品）
        -- 業態小分類の編集
        IF ( gt_sales_norm_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
          OR gt_sales_norm_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_gyotai_fvd
          OR gt_sales_norm_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_vd_xiaoka ) THEN
          lv_cust_gyotai_sho := cv_nvd;                 -- VD以外の業態・納品VD
        ELSE
          lv_cust_gyotai_sho := gt_sales_norm_tbl( ln_trx_idx ).cust_gyotai_sho;
                                                        -- フル(消化)VD・フルVD・消化VD
        END IF;
        gt_ar_dis_sum_tbl( ln_ar_sum ).cust_gyotai_sho  := lv_cust_gyotai_sho;
                                                        -- 業態小分類
        gt_ar_dis_sum_tbl( ln_ar_sum ).sales_base_code  := gt_sales_norm_tbl( ln_trx_idx ).sales_base_code;
                                                        -- 売上拠点コード
        gt_ar_dis_sum_tbl( ln_ar_sum ).card_sale_class  := gt_sales_norm_tbl( ln_trx_idx ).card_sale_class;
                                                        -- カード売り区分
        gt_ar_dis_sum_tbl( ln_ar_sum ).red_black_flag   := gt_sales_norm_tbl( ln_trx_idx ).red_black_flag;
                                                        -- 赤黒フラグ
        gt_ar_dis_sum_tbl( ln_ar_sum ).pure_amount      := ln_amount;
                                                        -- 集約後本体金額
        gt_ar_dis_sum_tbl( ln_ar_sum ).gccs_segment3    := gt_sales_norm_tbl( ln_trx_idx ).gccs_segment3;
                                                        -- 売上勘定科目コード
        gt_ar_dis_sum_tbl( ln_ar_sum ).tax_amount       := ln_tax;
                                                        -- 集約後消費税額
        gt_ar_dis_sum_tbl( ln_ar_sum ).gcct_segment3    := gt_sales_norm_tbl( ln_trx_idx ).gcct_segment3;
                                                        -- 消費税勘定科目コード
--
        -- AR請求取引OIFデータ作成(収益行)===>NO.1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- 取引明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- 取引ソース:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- 会計帳簿ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- 収益行
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- 品目明細摘要
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- 通貨
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount;
                                                        -- 収益行：本体金額
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        IF (  gt_sales_norm_tbl( sale_norm_idx ).card_sale_class = cv_cash_class
          AND gt_sales_norm_tbl( sale_norm_idx ).cash_and_card   = 0 ) THEN
        -- 現金の場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- 請求先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_b;
                                                        -- 請求先顧客ID
        ELSE
        -- カードの場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_norm_tbl( ln_trx_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_norm_tbl( ln_trx_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- 収益行のみ：AR取引番号
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_sales_norm_tbl( ln_trx_idx ).dlv_inv_line_no;
                                                        -- 収益行のみ：AR取引明細番号
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- 収益行のみ：数量=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount;
                                                        -- 収益行のみ：販売単価=本体金額
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_norm_tbl( ln_trx_idx ).tax_code;
                                                        -- 税金コード(税区分)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- ヘッダーDFFカテゴリ
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_base_code;
                                                        -- ヘッダーdff5(起票部門)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := gt_sales_norm_tbl( ln_trx_idx ).results_employee_code;
                                                        -- ヘッダーdff6(伝票入力者)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- ヘッダーDFF7(予備１)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- ヘッダーdff8(予備２)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- ヘッダーdff9(予備3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_sales_norm_tbl( ln_trx_idx ).receiv_base_code;
                                                        -- ヘッダーDFF11(入金拠点)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_sales_norm_tbl( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_sales_norm_tbl( ln_trx_idx ).tax_code = gt_out_tax_cls ) THEN
          -- 外税の場合、'N'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- 税込金額フラグ
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- 作成者
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- 作成日
--
        -- AR請求取引OIFデータ作成(税金行)===>NO.2
        ln_ar_idx := ln_ar_idx + 1;
--
        -- 取引明細DFF4用:自動採番番号
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR会計配分集約用データ格納
        gt_ar_dis_sum_tbl( ln_ar_sum ).interface_tax_dff4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- 納品伝票番号+自動採番
--
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- 取引明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- 取引ソース:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- 会計帳簿ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- 税金行
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- 品目明細摘要
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- 通貨
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax;
                                                        -- 税金行：消費税金額
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        IF (  gt_sales_norm_tbl( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_norm_tbl( ln_trx_idx ).cash_and_card   = 0 ) THEN
          -- 現金の場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- 請求先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_b;
                                                        -- 請求先顧客ID
        ELSE
        -- カードの場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- リンク先明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- リンク先明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := gt_sales_norm_tbl( ln_trx_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- リンク先明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_sales_norm_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- リンク先明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_norm_tbl( ln_trx_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_norm_tbl( ln_trx_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_norm_tbl( ln_trx_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_norm_tbl( ln_trx_idx ).tax_code;
                                                        -- 税金コード
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_sales_norm_tbl( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag 
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_sales_norm_tbl( ln_trx_idx ).tax_code = gt_out_tax_cls ) THEN
          -- 外税の場合、'N'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- 税込金額フラグ
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- 作成者
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- 作成日
      END IF;
--
      -- カード集約フラグ’N'の場合、カードのAR請求取引OIFデータ作成する
      IF ( lv_sum_card_flag = cv_n_flag AND ln_amount_card > 0 ) THEN   
--
        -- AR請求取引OIFの収益行
        ln_ar_idx   := ln_ar_idx  + 1;
        ln_card_idx := ln_card_pt - 1;
--
        -- 取引明細DFF4用:自動採番番号
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR請求取引OIFデータ作成(収益行)===>NO.3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_norm_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- 取引明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- 取引ソース:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- 会計帳簿ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- 収益行
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- 品目明細摘要
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- 通貨
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount_card;
                                                        -- 収益行：本体金額
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_norm_card_tbl( ln_card_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_norm_card_tbl( ln_card_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_norm_card_tbl( ln_card_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_norm_card_tbl( ln_card_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_norm_card_tbl( ln_card_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_norm_card_tbl( ln_card_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_norm_card_tbl( ln_card_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- 収益行のみ：AR取引番号
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_norm_card_tbl( ln_card_idx ).dlv_inv_line_no;
                                                        -- 収益行のみ：AR取引明細番号
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- 収益行のみ：数量=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount_card;
                                                        -- 収益行のみ：販売単価=本体金額
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_norm_card_tbl( ln_card_idx ).tax_code;
                                                        -- 税金コード(税区分)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- ヘッダーDFFカテゴリ
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gt_norm_card_tbl( ln_card_idx ).sales_base_code;
                                                        -- ヘッダーdff5(起票部門)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := gt_norm_card_tbl( ln_card_idx ).results_employee_code;
                                                        -- ヘッダーdff6(伝票入力者)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- ヘッダーDFF7(予備１)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- ヘッダーdff8(予備２)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- ヘッダーdff9(予備3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_norm_card_tbl( ln_card_idx ).receiv_base_code;
                                                        -- ヘッダーDFF11(入金拠点)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_norm_card_tbl( ln_card_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_norm_card_tbl( ln_card_idx ).tax_code = gt_out_tax_cls ) THEN
          -- 外税の場合、'N'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- 税込金額フラグ
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- 作成者
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- 作成日
--
        -- AR請求取引OIFデータ作成(税金行)===>NO.4
        ln_ar_idx := ln_ar_idx + 1;
--
        -- 取引明細DFF4用:自動採番番号
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_norm_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- 取引明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- 取引ソース:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- 会計帳簿ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- 税金行
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- 品目明細摘要
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- 通貨
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax_card;
                                                        -- 税金行：消費税金額
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_norm_card_tbl( ln_card_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_norm_card_tbl( ln_card_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_norm_card_tbl( ln_card_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_norm_card_tbl( ln_card_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- リンク先明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- リンク先明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := gt_norm_card_tbl( ln_card_idx ).dlv_invoice_number
                                                        || TO_CHAR( ln_trx_number_id );
                                                        -- リンク先明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF5
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_norm_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- リンク先明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_norm_card_tbl( ln_card_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_norm_card_tbl( ln_card_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_norm_card_tbl( ln_card_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_norm_card_tbl( ln_card_idx ).tax_code;
                                                        -- 税金コード
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_norm_card_tbl( ln_card_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag 
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_norm_card_tbl( ln_card_idx ).tax_code = gt_out_tax_cls ) THEN
          -- 外税の場合、'N'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- 税込金額フラグ
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- 作成者
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- 作成日
        -- 集約フラグのリセット
        lv_sum_card_flag := cv_y_flag;
        ln_amount_card := 0;
--
      END IF;                                           -- 集約キー毎にAR OIFデータの集約終了
--
      IF ( lv_sum_flag = cv_n_flag ) THEN 
        -- 集約キーと集約金額のリセット
        lt_header_id       := gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id;
        lt_invoice_number  := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number;
        lt_invoice_class   := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_class;
        lt_goods_prod_cls  := gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls;
        lt_item_code       := gt_sales_norm_tbl( sale_norm_idx ).item_code;
        lt_card_sale_class := gt_sales_norm_tbl( sale_norm_idx ).card_sale_class;
        lt_red_black_flag  := gt_sales_norm_tbl( sale_norm_idx ).red_black_flag;
        lv_sum_card_flag := cv_y_flag;
--
        ln_amount := gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax  := gt_sales_norm_tbl( sale_norm_idx ).tax_amount;
        ELSE
          ln_tax  := 0;
        END IF;
      END IF;
--
      -- 販売実績ヘッダ更新のため：ROWIDの設定
      gt_sales_h_tbl( sale_norm_idx ) := gt_sales_norm_tbl( sale_norm_idx ).xseh_rowid;
--
    END LOOP gt_sales_norm_sum_loop;                    -- 販売実績データループ終了
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_no_lookup_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_term_id_expt THEN
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
  END edit_sum_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_dis_data
   * Description      : AR会計配分仕訳作成（非大手量販店）(A-4)
   ***********************************************************************************/
  PROCEDURE edit_dis_data(
      ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_dis_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_ccid_idx         VARCHAR2(225);                                   -- セグメント１～８の結合（CCIDインデックス用）
    lv_tbl_nm           VARCHAR2(100);                                   -- 勘定科目組合せマスタテーブル
    lv_sum_flag         VARCHAR2(1);                                     -- 集約フラグ
    lt_ccid             gl_code_combinations.code_combination_id%TYPE;   -- 勘定科目CCID
    lt_segment3         fnd_lookup_values.attribute7%TYPE;               -- 勘定科目コード
--
    -- 集約キー
    lt_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE; -- 集約キー：納品伝票番号
    lt_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;  -- 集約キー：納品伝票区分
    lt_item_code        xxcos_sales_exp_lines.item_code%TYPE;            -- 集約キー：品目コード
    lt_prod_cls         xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                                         -- 品目区分（製品・商品）
    lt_gyotai_sho       xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;    -- 集約キー：業態小分類
    lt_card_sale_class  xxcos_sales_exp_headers.card_sale_class%TYPE;    -- 集約キー：カード売り区分
    lt_red_black_flag   xxcos_sales_exp_lines.red_black_flag%TYPE;       -- 集約キー：赤黒フラグ
    lt_gccs_segment3    gl_code_combinations.segment3%TYPE;              -- 集約キー：売上勘定科目コード
    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- 集約キー：税金コード
    ln_amount           NUMBER DEFAULT 0;                                -- 集約後金額
    ln_tax              NUMBER DEFAULT 0;                                -- 集約後消費税金額
    ln_ar_dis_idx       NUMBER DEFAULT 0;                                -- AR会計配分集約インデックス
    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR会計配分OIFインデックス
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- 仕訳生成カウント
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    non_jour_cls_expt         EXCEPTION;                -- 仕訳パターンなし
    non_ccid_expt             EXCEPTION;                -- CCID取得出来ないエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --=====================================
    -- 1.AR会計配分仕訳パターンの取得
    --=====================================
--
    -- カーソルオープン
    BEGIN
      OPEN  jour_cls_cur;
      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
    EXCEPTION
    -- 仕訳パターン取得失敗した場合
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_jour_nodata_msg
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => cv_qct_jour_cls
                       );
        lv_errbuf := lv_errmsg;
        RAISE non_jour_cls_expt;
    END;
    -- 仕訳パターン取得失敗した場合
    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_jour_nodata_msg
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_qct_jour_cls
                     );
      lv_errbuf := lv_errmsg;
      RAISE non_jour_cls_expt;
    END IF;
--
    -- カーソルクローズ
    CLOSE jour_cls_cur;
--
    --=====================================
    -- 3.AR会計配分データ作成
    --=====================================
--
    -- 集約キーの値セット
    lt_invoice_number   := gt_ar_dis_sum_tbl( 1 ).dlv_invoice_number;
    lt_invoice_class    := gt_ar_dis_sum_tbl( 1 ).dlv_invoice_class;
    lt_item_code        := gt_ar_dis_sum_tbl( 1 ).item_code;
    lt_prod_cls         := gt_ar_dis_sum_tbl( 1 ).goods_prod_cls;
    lt_gyotai_sho       := gt_ar_dis_sum_tbl( 1 ).cust_gyotai_sho;
    lt_card_sale_class  := gt_ar_dis_sum_tbl( 1 ).card_sale_class;
    lt_red_black_flag   := gt_ar_dis_sum_tbl( 1 ).red_black_flag;
    lt_gccs_segment3    := gt_ar_dis_sum_tbl( 1 ).gccs_segment3;
    lt_tax_code         := gt_ar_dis_sum_tbl( 1 ).gcct_segment3;
--
    -- ラストデータ登録為に、ダミーデータをセットする
    gt_ar_dis_sum_tbl( gt_ar_dis_sum_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_ar_dis_sum_tbl( gt_ar_dis_sum_tbl.COUNT ).sales_exp_header_id;
--
    <<gt_ar_dis_sum_tbl_loop>>
    FOR dis_sum_idx IN 1 .. gt_ar_dis_sum_tbl.COUNT LOOP
--
      -- AR会計配分データ集約開始
      IF (  lt_invoice_number  = gt_ar_dis_sum_tbl( dis_sum_idx ).dlv_invoice_number
        AND lt_invoice_class   = gt_ar_dis_sum_tbl( dis_sum_idx ).dlv_invoice_class
        AND ( lt_item_code     = gt_ar_dis_sum_tbl( dis_sum_idx ).item_code
          OR lt_prod_cls       = gt_ar_dis_sum_tbl( dis_sum_idx ).goods_prod_cls )
        AND lt_gyotai_sho      = gt_ar_dis_sum_tbl( dis_sum_idx ).cust_gyotai_sho
        AND lt_card_sale_class = gt_ar_dis_sum_tbl( dis_sum_idx ).card_sale_class
        AND lt_red_black_flag  = gt_ar_dis_sum_tbl( dis_sum_idx ).red_black_flag
        AND lt_gccs_segment3   = gt_ar_dis_sum_tbl( dis_sum_idx ).gccs_segment3
        AND lt_tax_code        = gt_ar_dis_sum_tbl( dis_sum_idx ).gcct_segment3
        ) THEN
--
        -- 集約するフラグ初期設定
        lv_sum_flag := cv_y_flag;
--
        -- 本体金額と消費税額を集約する
        ln_amount := ln_amount + gt_ar_dis_sum_tbl( dis_sum_idx ).pure_amount;
        ln_tax    := ln_tax    + gt_ar_dis_sum_tbl( dis_sum_idx ).tax_amount;
      ELSE
        lv_sum_flag := cv_n_flag;
        ln_dis_idx  := dis_sum_idx - 1;
      END IF;
--
      -- -- 集約フラグ’N'の場合、下記AR会計配分OIF作成処理を行う
      IF ( lv_sum_flag = cv_n_flag ) THEN   
--
        -- 仕訳生成カウント初期値
        ln_jour_cnt := 1;
--
        -- 仕訳パターンよりAR会計配分の仕訳を編集する
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
          IF (  gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = lt_invoice_class
            AND (  gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = lt_item_code
              OR ( gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> lt_item_code
                AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls = lt_prod_cls ) )
            AND ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = lt_gyotai_sho
              OR  gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL )
            AND ( gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = lt_card_sale_class
              OR  gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL )
            AND ( gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
              OR  gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL )
            ) THEN
--
            -- 一回の集約に３レコードを作成する
            EXIT WHEN ( ln_jour_cnt > cn_jour_cnt );
--
            -- 勘定科目の編集
            IF ( gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_goods_msg
              OR gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_prod_msg
              OR gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_disc_msg ) THEN
              --売上勘定科目コード
              lt_segment3 := gt_ar_dis_sum_tbl( ln_dis_idx ).gccs_segment3;
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_tax_msg ) THEN
              --税金勘定科目コード
              lt_segment3 := gt_ar_dis_sum_tbl( ln_dis_idx ).gcct_segment3;
            ELSE
              --OTHER勘定科目コード
              lt_segment3 := gt_jour_cls_tbl( jcls_idx ).segment3;
            END IF;
--
            --=====================================
            -- 2.勘定科目CCIDの取得
            --=====================================
            -- 勘定科目セグメント１～セグメント８よりCCID取得
            lv_ccid_idx := gv_company_code                                   -- セグメント１(会社コード)
                        || NVL( gt_jour_cls_tbl( jcls_idx ).segment2,        -- セグメント２（部門コード）
                                gt_ar_dis_sum_tbl( ln_dis_idx ).sales_base_code )
                                                                             -- セグメント２(販売実績の売上拠点コード)
                        || lt_segment3                                       -- セグメント３(勘定科目コード)
                        || gt_jour_cls_tbl( jcls_idx ).segment4              -- セグメント４(補助科目コード:現金のみ設定)
                        || gt_jour_cls_tbl( jcls_idx ).segment5              -- セグメント５(顧客コード)
                        || gt_jour_cls_tbl( jcls_idx ).segment6              -- セグメント６(企業コード)
                        || gt_jour_cls_tbl( jcls_idx ).segment7              -- セグメント７(事業区分コード)
                        || gt_jour_cls_tbl( jcls_idx ).segment8;             -- セグメント８(予備)
--
            -- CCIDの存在チェック-->存在している場合、取得必要がない
            IF ( gt_sel_ccid_tbl.EXISTS(  lv_ccid_idx ) ) THEN
              lt_ccid := gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id;
            ELSE
                  -- CCID取得共通関数よりCCIDを取得する
              lt_ccid := xxcok_common_pkg.get_code_combination_id_f (
                             gd_process_date
                           , gv_company_code
                           , NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                  gt_ar_dis_sum_tbl( ln_dis_idx ).sales_base_code )
                           , lt_segment3
                           , gt_jour_cls_tbl( jcls_idx ).segment4
                           , gt_jour_cls_tbl( jcls_idx ).segment5
                           , gt_jour_cls_tbl( jcls_idx ).segment6
                           , gt_jour_cls_tbl( jcls_idx ).segment7
                           , gt_jour_cls_tbl( jcls_idx ).segment8
                         );
--
              IF ( lt_ccid IS NULL ) THEN
                -- CCIDが取得できない場合
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm
                                , iv_name              => cv_ccid_nodata_msg
                                , iv_token_name1       => cv_tkn_segment1
                                , iv_token_value1      => gv_company_code
                                , iv_token_name2       => cv_tkn_segment2
                                , iv_token_value2      => NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                                               gt_ar_dis_sum_tbl( ln_dis_idx ).sales_base_code )
                                , iv_token_name3       => cv_tkn_segment3
                                , iv_token_value3      => lt_segment3
                                , iv_token_name4       => cv_tkn_segment4
                                , iv_token_value4      => gt_jour_cls_tbl( jcls_idx ).segment4
                                , iv_token_name5       => cv_tkn_segment5
                                , iv_token_value5      => gt_jour_cls_tbl( jcls_idx ).segment5
                                , iv_token_name6       => cv_tkn_segment6
                                , iv_token_value6      => gt_jour_cls_tbl( jcls_idx ).segment6
                                , iv_token_name7       => cv_tkn_segment7
                                , iv_token_value7      => gt_jour_cls_tbl( jcls_idx ).segment7
                                , iv_token_name8       => cv_tkn_segment8
                                , iv_token_value8      => gt_jour_cls_tbl( jcls_idx ).segment8
                              );
                lv_errbuf  := lv_errmsg;
                RAISE non_ccid_expt;
              END IF;
--
              -- 取得したCCIDをワークテーブルに設定する
              gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
--
            END IF;                                       -- CCID編集終了
--
            --=====================================
            -- AR会計配分OIFデータ設定
            --=====================================
            IF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rev ) THEN
              -- 収益行
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
--
              -- フルVD（消化）とフルVD場合の金額編集
              IF ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_fvd_xiaoka
                OR gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_gyotai_fvd ) THEN
                ln_amount := ln_amount + ln_tax;
              END IF;
--
              -- AR会計配分OIFの設定項目
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- 取引明細コンテキスト値「販売実績」をセット
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF1「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).interface_line_dff4;
                                                          -- 取引明細DFF4:納品伝票番号+自動採番
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5：「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rev;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_amount;
                                                          -- 金額(明細金額)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- パーセント(割合)100
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- 勘定科目組合せID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- 仕訳明細カテゴリ:営業単位IDをセット
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- 営業単位ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- 作成者
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- 作成日
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rec ) THEN
              -- 債権行(金額設定なし)
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
--
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- 取引明細コンテキスト値「販売実績」をセット
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF1「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).interface_line_dff4;
                                                          -- 取引明細DFF4納品伝票番号+自動採番
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5	「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rec;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- パーセント(割合)100
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- 勘定科目組合せID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- 仕訳明細カテゴリ:営業単位IDをセット
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- 営業単位ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- 作成者
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- 作成日
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_tax ) THEN
              -- 税金行
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- 取引明細コンテキスト値「販売実績」をセット
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF1「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).interface_tax_dff4;
                                                          -- 取引明細DFF4：納品伝票番号+自動採番
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_ar_dis_sum_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_tax;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_tax;
                                                          -- 金額(明細金額)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- パーセント(割合)100
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- 勘定科目組合せID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- 仕訳明細カテゴリ:営業単位ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- 営業単位ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- 作成者
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- 作成日
            END IF;
--
            -- 仕訳生成カウントセット
            ln_jour_cnt := ln_jour_cnt + 1;
          END IF;                                         -- 仕訳パターン毎にAR会計配分OIFデータの作成処理終了
--
        END LOOP gt_jour_cls_tbl_loop;                    -- 仕訳パターンよりデータ作成処理終了
--
      END IF;                                             -- 集約キー毎にAR会計配分OIFデータの集約終了
--
        -- 集約キーのリセット
        lt_invoice_number   := gt_ar_dis_sum_tbl( dis_sum_idx ).dlv_invoice_number;
        lt_invoice_class    := gt_ar_dis_sum_tbl( dis_sum_idx ).dlv_invoice_class;
        lt_item_code        := gt_ar_dis_sum_tbl( dis_sum_idx ).item_code;
        lt_prod_cls         := gt_ar_dis_sum_tbl( dis_sum_idx ).goods_prod_cls;
        lt_gyotai_sho       := gt_ar_dis_sum_tbl( dis_sum_idx ).cust_gyotai_sho;
        lt_card_sale_class  := gt_ar_dis_sum_tbl( dis_sum_idx ).card_sale_class;
        lt_red_black_flag   := gt_ar_dis_sum_tbl( dis_sum_idx ).red_black_flag;
        lt_gccs_segment3    := gt_ar_dis_sum_tbl( dis_sum_idx ).gccs_segment3;
        lt_tax_code         := gt_ar_dis_sum_tbl( dis_sum_idx ).gcct_segment3;
--
        -- 金額の設定
        ln_amount        := gt_ar_dis_sum_tbl( dis_sum_idx ).pure_amount;
        ln_tax           := gt_ar_dis_sum_tbl( dis_sum_idx ).tax_amount;
--
    END LOOP gt_ar_dis_sum_tbl_loop;                      -- AR会計配分集約データループ終了
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
    WHEN non_jour_cls_expt THEN
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN non_ccid_expt THEN
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END edit_dis_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_sum_bulk_data
   * Description      : 請求取引集約処理（大手量販店）(A-5)
   ***********************************************************************************/
  PROCEDURE edit_sum_bulk_data(
      ov_errbuf         OUT VARCHAR2         -- エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2         -- リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_sum_bulk_data';          -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                  -- リターン・コード
    lv_errmsg  VARCHAR2(5000);               -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_card_idx             NUMBER DEFAULT 0;           -- 生成したカードレコードのインデックス
    ln_card_pt              NUMBER DEFAULT 1;           -- カードレコードのインデックス現行位置
    ln_ar_idx               NUMBER DEFAULT 0;           -- 請求取引OIFインデックス
    ln_ar_bul               NUMBER DEFAULT 0;           -- AR会計配分集約インデックス
    ln_trx_idx              NUMBER DEFAULT 0;           -- AR配分OIF集約データインデックス;
--
    lv_trx_type_nm          VARCHAR2(30);               -- 取引タイプ名称
    lv_trx_idx              VARCHAR2(30);               -- 取引タイプ(インデックス)
    lv_item_idx             VARCHAR2(30);               -- 品目明細摘要(インデックス)
    lv_item_desp            VARCHAR2(30);               -- 品目明細摘要(TAX以外)
    ln_term_id              VARCHAR2(30);               -- 支払条件ID
    lv_cust_gyotai_sho      VARCHAR2(30);               -- 業態小分類
    ln_pure_amount          NUMBER DEFAULT 0;           -- カードレコードの本体金額
    ln_tax_amount           NUMBER DEFAULT 0;           -- カードレコードの消費税金額
    ln_tax                  NUMBER DEFAULT 0;           -- 集約後消費税金額
    ln_amount               NUMBER DEFAULT 0;           -- 集約後金額
    ln_tax_card             NUMBER DEFAULT 0;           -- 集約後消費税金額(カードレコード)
    ln_amount_card          NUMBER DEFAULT 0;           -- 集約後金額(カードレコード)
    ln_sales_h_tbl_idx      NUMBER DEFAULT 0;           -- 販売実績ヘッダ更新用インデックス
    ln_trx_number_id        NUMBER;                     -- 取引明細DFF4用:自動採番番号
--
    -- 集約キー(販売実績)
    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
                                                        -- 集約キー：販売実績ヘッダID
    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
                                                        -- 集約キー：納品伝票番号
    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
                                                        -- 集約キー：納品伝票区分
    lt_goods_prod_cls       xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                        -- 集約キー：品目区分（製品・商品）
    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
                                                        -- 集約キー：品目コード（非在庫）
    lt_card_sale_class      xxcos_sales_exp_headers.card_sale_class%TYPE;
                                                        -- 集約キー：カード売り区分
    lt_red_black_flag       xxcos_sales_exp_lines.red_black_flag%TYPE;
                                                        -- 集約キー：赤黒フラグ
--
    -- 集約キー(生成したカードレコード)
    lt_header_id_card       xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
                                                        -- 集約キー：販売実績ヘッダID
    lt_invo_number_card     xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
                                                        -- 集約キー：納品伝票番号
    lt_invo_class_card      xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
                                                        -- 集約キー：納品伝票区分
    lt_goods_prod_card      xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                        -- 集約キー：品目区分コード（製品・商品）
    lt_item_code_card       xxcos_sales_exp_lines.item_code%TYPE;
                                                        -- 集約キー：品目コード（非在庫）
--
    lv_sum_flag             VARCHAR2(1);                -- 集約フラグ
    lv_sum_card_flag        VARCHAR2(1);                -- カード集約フラグ
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソ ***
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
    -- 請求取引テーブルの非大手量販店データカウントセット
    ln_ar_idx := gt_ar_interface_tbl.COUNT;
--
    -- 販売実績ヘッダ更新用インデックス
    ln_sales_h_tbl_idx := gt_sales_h_tbl.COUNT;
--
    --=====================================================================
    -- ４．フルサービスVDとフルサービス（消化）VDのカード・現金併用データの編集
    --=====================================================================
    <<gt_sales_bulk_tbl_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
      -- 現金・カード併用の場合-->カード売り区分=現金:0 かつ 現金カード併用額>0
      IF ( (   gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho = gt_fvd_xiaoka
            OR gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho = gt_gyotai_fvd )
        AND (  gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class = gt_cash_sale_cls
          AND  gt_sales_bulk_tbl( sale_bulk_idx ).cash_and_card   > 0 ) ) THEN
--
        -- カードレコードの本体金額
        ln_pure_amount := gt_sales_bulk_tbl( sale_bulk_idx ).cash_and_card
                        / ( 1 + gt_sales_bulk_tbl( sale_bulk_idx ).tax_rate/cn_percent );
--
        -- 端数処理
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).xchv_tax_round    = cv_round_rule_up ) THEN
          -- 切り上げの場合
          ln_pure_amount := CEIL( ln_pure_amount );
--
        ELSIF ( gt_sales_bulk_tbl( sale_bulk_idx ).xchv_tax_round = cv_round_rule_down ) THEN
          -- 切り下げの場合
          ln_pure_amount := FLOOR( ln_pure_amount );
--
        ELSIF ( gt_sales_bulk_tbl( sale_bulk_idx ).xchv_tax_round = cv_round_rule_nearest ) THEN
          -- 四捨五入の場合
          ln_pure_amount := ROUND( ln_pure_amount );
        END IF;
--
        -- 課税の場合、カードレコードの消費税額を算出する
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax_amount := gt_sales_bulk_tbl( sale_bulk_idx ).cash_and_card - ln_pure_amount;
        ELSE
          ln_tax_amount := 0;
        END IF;
--
        --==============================================================
        --販売実績カードワークテーブルへのカードレコード登録
        --==============================================================
        ln_card_idx := ln_card_idx + 1;
--
        -- カードレコード全カラムの設定
        gt_bulk_card_tbl( ln_card_idx ) := gt_sales_bulk_tbl( sale_bulk_idx );
--
        -- カードレコードの売り区分、本体金額、消費税金額の設定
        gt_bulk_card_tbl( ln_card_idx ).card_sale_class  := cv_card_class;
                                                         -- カード売り区分（１：カード）
        gt_bulk_card_tbl( ln_card_idx ).pure_amount      := ln_pure_amount;
                                                         -- 本体金額
        gt_bulk_card_tbl( ln_card_idx ).tax_amount       := ln_tax_amount;
                                                         -- 消費税金額
      END IF;
--
    END LOOP gt_sales_bulk_tbl_loop;                                   -- 大手量販店併用データ編集終了
--
      --=====================================================================
      -- 請求取引集約処理（大手量販店）開始
      --=====================================================================
    -- 集約キーの値セット
    lt_header_id        := gt_sales_bulk_tbl( 1 ).sales_exp_header_id;
    lt_invoice_number   := gt_sales_bulk_tbl( 1 ).dlv_invoice_number;
    lt_invoice_class    := gt_sales_bulk_tbl( 1 ).dlv_invoice_class;
    lt_goods_prod_cls   := gt_sales_bulk_tbl( 1 ).goods_prod_cls;
    lt_item_code        := gt_sales_bulk_tbl( 1 ).item_code;
    lt_card_sale_class  := gt_sales_bulk_tbl( 1 ).card_sale_class;
    lt_red_black_flag   := gt_sales_bulk_tbl( 1 ).red_black_flag;
--
    -- ラストデータ登録為に、ダミーデータをセット
    gt_sales_bulk_tbl( gt_sales_bulk_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_sales_bulk_tbl( gt_sales_bulk_tbl.COUNT ).sales_exp_header_id;
    IF ( gt_bulk_card_tbl.COUNT > 0 ) THEN
      gt_bulk_card_tbl( gt_bulk_card_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_bulk_card_tbl( gt_bulk_card_tbl.COUNT ).sales_exp_header_id;
    END IF;
--
    <<gt_sales_bulk_sum_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
--
      --=====================================
      --5-1.販売実績元データの集約
      --=====================================
      IF (  lt_header_id        = gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id
        AND lt_invoice_number   = gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_number
        AND lt_invoice_class    = gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class
        AND ( lt_goods_prod_cls = gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls
          OR  lt_item_code      = gt_sales_bulk_tbl( sale_bulk_idx ).item_code )
        AND lt_card_sale_class  = gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class
        AND lt_red_black_flag   = gt_sales_bulk_tbl( sale_bulk_idx ).red_black_flag
         ) THEN
--
        -- 集約するフラグ初期設定
        lv_sum_flag      := cv_y_flag;
        lv_sum_card_flag := cv_y_flag;
--
        -- 本体金額を集約する
        ln_amount := ln_amount + gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
--
        -- 課税の場合、消費税額を集約する
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax := ln_tax + gt_sales_bulk_tbl( sale_bulk_idx ).tax_amount;
        END IF;
--
        --=====================================
        --5-2.上記4で生成したカードレコードの集約
        --=====================================
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class = cv_card_class ) THEN
          <<gt_bulk_card_tbl_loop>>
          FOR i IN ln_card_pt .. gt_bulk_card_tbl.COUNT LOOP
            IF (  lt_header_id        = gt_bulk_card_tbl( i ).sales_exp_header_id
              AND lt_invoice_number   = gt_bulk_card_tbl( i ).dlv_invoice_number
              AND lt_invoice_class    = gt_bulk_card_tbl( i ).dlv_invoice_class
              AND ( lt_goods_prod_cls = gt_bulk_card_tbl( i ).goods_prod_cls
                OR  lt_item_code      = gt_bulk_card_tbl( i ).item_code )
            ) THEN
              -- 本体金額を集約する
              ln_amount   := ln_amount + gt_bulk_card_tbl( i ).pure_amount;
              -- 課税の場合、消費税額を集約する
              IF ( gt_bulk_card_tbl( i ).consumption_tax_class != gt_no_tax_cls ) THEN
                ln_tax := ln_tax + gt_bulk_card_tbl( i ).tax_amount;
              END IF;
            END IF;
            -- カードレコードの現ポイントをカウントする
            ln_card_pt := i;
          END LOOP gt_bulk_card_tbl_loop;
--
        -- 生成したカードレコードだけの集約
        ELSIF ( ( gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho = gt_fvd_xiaoka
            OR gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho = gt_gyotai_fvd )
          AND gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class = gt_cash_sale_cls
          AND gt_sales_bulk_tbl( sale_bulk_idx ).cash_and_card > 0
          AND ln_card_pt < gt_bulk_card_tbl.COUNT
          ) THEN
          ln_amount_card := 0;
          ln_tax_card  := 0;
--
          -- 生成したカードレコードだけの集約開始
          FOR i IN ln_card_pt .. gt_bulk_card_tbl.COUNT LOOP
            IF (  lt_header_id        = gt_bulk_card_tbl( i ).sales_exp_header_id
              AND lt_invoice_number   = gt_bulk_card_tbl( i ).dlv_invoice_number
              AND lt_invoice_class    = gt_bulk_card_tbl( i ).dlv_invoice_class
              AND ( lt_goods_prod_cls = gt_bulk_card_tbl( i ).goods_prod_cls
                OR  lt_item_code      = gt_bulk_card_tbl( i ).item_code )
            ) THEN
              -- 本体金額を集約する
              ln_amount_card := ln_amount_card + gt_bulk_card_tbl( i ).pure_amount;
              -- 課税の場合、消費税額を集約する
              IF ( gt_bulk_card_tbl( i ).consumption_tax_class != gt_no_tax_cls ) THEN
                ln_tax_card  := ln_tax_card + gt_bulk_card_tbl( i ).tax_amount;
              END IF;
            ELSE
              -- カードレコードの現ポイントをカウントする
              ln_card_pt := i;
              -- 集約フラグ’N'を設定
              lv_sum_card_flag := cv_n_flag;
            END IF;
--
          END LOOP gt_bulk_card_tbl_loop;
--
        END IF; -- 生成したカードレコードだけの集約終了
      ELSE
--
        lv_sum_flag := cv_n_flag;
        ln_trx_idx  := sale_bulk_idx - 1;
      END IF;
--
      IF ( lv_sum_flag = cv_n_flag OR lv_sum_card_flag = cv_n_flag ) THEN
      --=====================================================================
        -- １．支払条件IDの取得
        --=====================================================================
        IF ( SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                   , cv_substr_st, cv_substr_cnt )
             <= gt_sales_bulk_tbl( ln_trx_idx ).rtt1_term_dd1 ) THEN
          -- 支払条件 ID
          ln_term_id := gt_sales_bulk_tbl( ln_trx_idx ).xchv_bill_pay_id;
--
        ELSIF( SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               > gt_sales_bulk_tbl( ln_trx_idx ).rtt1_term_dd1
           AND SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               <= gt_sales_bulk_tbl( ln_trx_idx ).rtt2_term_dd2 ) THEN
          -- 第2支払条件 ID
          ln_term_id := gt_sales_bulk_tbl( ln_trx_idx ).xchv_bill_pay_id2;
--
        ELSIF( SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               > gt_sales_bulk_tbl( ln_trx_idx ).rtt2_term_dd2
           AND SUBSTR( TO_CHAR( gt_sales_bulk_tbl( ln_trx_idx ).delivery_date, cv_date_format_non_sep )
                     , cv_substr_st, cv_substr_cnt )
               <= gt_sales_bulk_tbl( ln_trx_idx ).rtt3_term_dd3 ) THEN
          -- 第3支払条件 ID
          ln_term_id := gt_sales_bulk_tbl( ln_trx_idx ).xchv_bill_pay_id3;
--
        ELSE
          -- 支払条件IDの取得ができない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_term_id_msg
                      );
          lv_errbuf  := lv_errmsg;
--
          RAISE global_term_id_expt;
        END IF;
--
        --=====================================================================
        -- ２．取引タイプの取得
        --=====================================================================
        lv_trx_idx := gt_sales_bulk_tbl( ln_trx_idx ).create_class
                   || gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class;
        IF ( gt_sel_trx_type_tbl.EXISTS( lv_trx_idx ) ) THEN
          lv_trx_type_nm := gt_sel_trx_type_tbl( lv_trx_idx ).attribute1;
        ELSE
          BEGIN
            SELECT flvm.attribute1 || flvd.attribute1
            INTO   lv_trx_type_nm
            FROM   fnd_lookup_values              flvm                     -- 作成元区分特定マスタ
                 , fnd_lookup_values              flvd                     -- 納品伝票区分特定マスタ
            WHERE  flvm.lookup_type               = cv_qct_mkorg_cls
              AND  flvd.lookup_type               = cv_qct_dlv_slp_cls
              AND  flvm.lookup_code               LIKE cv_qcc_code
              AND  flvd.lookup_code               LIKE cv_qcc_code
              AND  flvm.meaning                   = gt_sales_bulk_tbl( ln_trx_idx ).create_class
              AND  flvd.meaning                   = gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class
              AND  flvm.enabled_flag              = cv_enabled_yes
              AND  flvd.enabled_flag              = cv_enabled_yes
              AND  flvm.language                  = USERENV( 'LANG' )
              AND  flvd.language                  = USERENV( 'LANG' )
              AND  gd_process_date BETWEEN        NVL( flvm.start_date_active, gd_process_date )
                                   AND            NVL( flvm.end_date_active,   gd_process_date )
              AND  gd_process_date BETWEEN        NVL( flvd.start_date_active, gd_process_date )
                                   AND            NVL( flvd.end_date_active,   gd_process_date );
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 取引タイプ取得出来ない場合
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_trxtype_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_mkorg_cls
                                               || cv_and
                                               || cv_qct_dlv_slp_cls
                         );
              lv_errbuf  := lv_errmsg;
--
              RAISE global_no_lookup_expt;
          END;
--
          -- 取得した取引タイプをワークテーブルに設定する
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute1 := lv_trx_type_nm;
--
        END IF;
--
        --=====================================================================
        -- 3．品目明細摘要の取得(「仮受消費税等」以外)
        --=====================================================================
--
        -- 品目明細摘要の存在チェック-->存在している場合、取得必要がない
        IF ( gt_sales_bulk_tbl( ln_trx_idx ).goods_prod_cls IS NULL ) THEN
          lv_item_idx := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class
                      || gt_sales_bulk_tbl( ln_trx_idx ).item_code;
        ELSE
          lv_item_idx := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class
                      || gt_sales_bulk_tbl( ln_trx_idx ).goods_prod_cls;
        END IF;
--
        IF ( gt_sel_item_desp_tbl.EXISTS( lv_item_idx ) ) THEN
          lv_item_desp := gt_sel_item_desp_tbl( lv_item_idx ).description;
        ELSE
          BEGIN
            SELECT flvi.description
            INTO   lv_item_desp
            FROM   fnd_lookup_values              flvi                     -- AR品目明細摘要特定マスタ
            WHERE  flvi.lookup_type               = cv_qct_item_cls
              AND  flvi.lookup_code               LIKE cv_qcc_code
              AND  flvi.attribute1                = gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class
              AND  flvi.attribute2                = NVL( gt_sales_bulk_tbl( ln_trx_idx ).goods_prod_cls,
                                                         gt_sales_bulk_tbl( ln_trx_idx ).item_code )
              AND  flvi.enabled_flag              = cv_enabled_yes
              AND  flvi.language                  = USERENV( 'LANG' )
              AND  gd_process_date BETWEEN        NVL( flvi.start_date_active, gd_process_date )
                                   AND            NVL( flvi.end_date_active,   gd_process_date );
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- AR品目明細摘要取得出来ない場合
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_itemdesp_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_item_cls
                          );
              lv_errbuf  := lv_errmsg;
--
              RAISE global_no_lookup_expt;
          END;
--
          -- 取得したAR品目明細摘要をワークテーブルに設定する
          gt_sel_item_desp_tbl( lv_item_idx ).description := lv_item_desp;
--
        END IF;
      END IF;
--
      --==============================================================
      -- ６．AR請求取引OIFデータ作成
      --==============================================================
--
      -- 集約フラグ’N'の場合、AR請求取引OIFデータ作成する
      IF ( lv_sum_flag = cv_n_flag ) THEN 
        -- AR請求取引OIFの収益行
        ln_ar_idx := ln_ar_idx + 1;
        ln_ar_bul := ln_ar_bul + 1;
--
        -- 取引明細DFF4用:自動採番番号
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR会計配分集約用データ格納(BULK)
        gt_ar_dis_bul_tbl( ln_ar_bul ).sales_exp_header_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- 販売実績ヘッダID
        gt_ar_dis_bul_tbl( ln_ar_bul ).dlv_invoice_number
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- 納品伝票番号
        gt_ar_dis_bul_tbl( ln_ar_bul ).interface_line_dff4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- 自動採番
        gt_ar_dis_bul_tbl( ln_ar_bul ).dlv_invoice_class
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_class;
                                                        -- 納品伝票区分
        gt_ar_dis_bul_tbl( ln_ar_bul ).item_code        := gt_sales_bulk_tbl( ln_trx_idx ).item_code;
                                                        -- 品目コード
        gt_ar_dis_bul_tbl( ln_ar_bul ).goods_prod_cls   := gt_sales_bulk_tbl( ln_trx_idx ).goods_prod_cls;
                                                        -- 品目区分（製品・商品）
        -- 業態小分類の編集
        IF ( gt_sales_bulk_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
          OR gt_sales_bulk_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_gyotai_fvd
          OR gt_sales_bulk_tbl( ln_trx_idx ).cust_gyotai_sho <> gt_vd_xiaoka ) THEN
          lv_cust_gyotai_sho := cv_nvd;                 -- VD以外の業態・納品VD
        ELSE
          lv_cust_gyotai_sho := gt_sales_bulk_tbl( ln_trx_idx ).cust_gyotai_sho;
                                                        -- フル(消化)VD・フルVD・消化VD
        END IF;
        gt_ar_dis_bul_tbl( ln_ar_bul ).cust_gyotai_sho  := lv_cust_gyotai_sho;
                                                        -- 業態小分類
        gt_ar_dis_bul_tbl( ln_ar_bul ).sales_base_code  := gt_sales_bulk_tbl( ln_trx_idx ).sales_base_code;
                                                        -- 売上拠点コード
        gt_ar_dis_bul_tbl( ln_ar_bul ).card_sale_class  := gt_sales_bulk_tbl( ln_trx_idx ).card_sale_class;
                                                        -- カード売り区分
        gt_ar_dis_bul_tbl( ln_ar_bul ).red_black_flag   := gt_sales_bulk_tbl( ln_trx_idx ).red_black_flag;
                                                        -- 赤黒フラグ
        gt_ar_dis_bul_tbl( ln_ar_bul ).gccs_segment3    := gt_sales_bulk_tbl( ln_trx_idx ).gccs_segment3;
                                                        -- 売上勘定科目コード
        gt_ar_dis_bul_tbl( ln_ar_bul ).pure_amount      := ln_amount;
                                                        -- 集約後本体金額
        gt_ar_dis_bul_tbl( ln_ar_bul ).gcct_segment3    := gt_sales_bulk_tbl( ln_trx_idx ).gcct_segment3;
                                                        -- 税金勘定科目コード(仮受消費税等)
        gt_ar_dis_bul_tbl( ln_ar_bul ).tax_amount       := ln_tax;
                                                        -- 集約後本体金額
--
        -- AR請求取引OIFデータ作成(収益行)===>NO.1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- 取引明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- 取引ソース:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- 会計帳簿ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- 収益行
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- 品目明細摘要
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- 通貨
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount;
                                                        -- 収益行：本体金額
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        IF (  gt_sales_bulk_tbl( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_bulk_tbl( ln_trx_idx ).cash_and_card   = 0 ) THEN
        -- 現金の場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- 請求先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_b;
                                                        -- 請求先顧客ID
        ELSE
        -- カードの場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_bulk_tbl( ln_trx_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_bulk_tbl( ln_trx_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := TO_CHAR( ln_trx_number_id );
                                                        -- 収益行のみ：AR取引番号
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_sales_bulk_tbl( ln_trx_idx ).dlv_inv_line_no;
                                                        -- 収益行のみ：AR取引明細番号
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- 収益行のみ：数量=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount;
                                                        -- 収益行のみ：販売単価=本体金額
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_bulk_tbl( ln_trx_idx ).tax_code;
                                                        -- 税金コード(税区分)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- ヘッダーDFFカテゴリ
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gv_busi_dept_cd;
                                                        -- ヘッダーdff5(起票部門)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := gv_busi_emp_cd;
                                                        -- ヘッダーdff6(伝票入力者)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- ヘッダーDFF7(予備１)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- ヘッダーdff8(予備２)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- ヘッダーdff9(予備3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).receiv_base_code;
                                                        -- ヘッダーDFF11(入金拠点)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_sales_bulk_tbl( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_sales_bulk_tbl( ln_trx_idx ).tax_code = gt_out_tax_cls ) THEN
          -- 外税の場合、'N'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- 税込金額フラグ
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- 作成者
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- 作成日
--
        -- AR請求取引OIFデータ作成(税金行)===>NO.2
        ln_ar_idx := ln_ar_idx + 1;
--
        -- 取引明細DFF4用:自動採番番号
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        -- AR会計配分集約用データ格納(BULK)
        gt_ar_dis_bul_tbl( ln_ar_bul ).interface_tax_dff4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- 自動採番
--
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- 取引明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- 取引ソース:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- 会計帳簿ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- 税金行
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- 品目明細摘要
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- 通貨
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax;
                                                        -- 税金行：消費税金額
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        IF (  gt_sales_bulk_tbl( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_bulk_tbl( ln_trx_idx ).cash_and_card   = 0 ) THEN
        -- 現金の場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- 請求先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_b;
                                                        -- 請求先顧客ID
        ELSE
        -- カードの場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- リンク先明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).dlv_invoice_number;
                                                        -- リンク先明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- リンク先明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).sales_exp_header_id;
                                                        -- リンク先明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_bulk_tbl( ln_trx_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_bulk_tbl( ln_trx_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_bulk_tbl( ln_trx_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_bulk_tbl( ln_trx_idx ).tax_code;
                                                        -- 税金コード
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位id
        IF ( gt_sales_bulk_tbl( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag 
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_sales_bulk_tbl( ln_trx_idx ).tax_code = gt_out_tax_cls ) THEN
          -- 外税の場合、'N'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- 税込金額フラグ
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- 作成者
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- 作成日
      END IF;
--
      -- -- カード集約フラグ’N'の場合、カードのAR請求取引OIFデータ作成する
      IF ( lv_sum_card_flag = cv_n_flag AND ln_amount_card > 0 ) THEN   
        -- AR請求取引OIFの収益行
        ln_ar_idx   := ln_ar_idx  + 1;
        ln_card_idx := ln_card_pt - 1;
--
        -- 取引明細DFF4用:自動採番番号
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        --  AR請求取引OIFデータ作成(収益行)===>NO.3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_bulk_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_bulk_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- 取引明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- 取引ソース:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- 会計帳簿ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- 収益行
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- 品目明細摘要
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- 通貨
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount_card;
                                                        -- 収益行：本体金額
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_bulk_card_tbl( ln_card_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_bulk_card_tbl( ln_card_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := TO_CHAR( ln_trx_number_id );
                                                        -- AR取引番号
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_bulk_card_tbl( ln_card_idx ).dlv_inv_line_no;
                                                        -- 収益行のみ：AR取引明細番号
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- 収益行のみ：数量=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount_card;
                                                        -- 収益行のみ：販売単価=本体金額
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_bulk_card_tbl( ln_card_idx ).tax_code;
                                                        -- 税金コード(税区分)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- ヘッダーDFFカテゴリ
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gv_busi_dept_cd;
                                                        -- ヘッダーdff5(起票部門)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := gv_busi_emp_cd;
                                                        -- ヘッダーdff6(伝票入力者)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- ヘッダーDFF7(予備１)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- ヘッダーdff8(予備２)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- ヘッダーdff9(予備3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_bulk_card_tbl( ln_card_idx ).receiv_base_code;
                                                        -- ヘッダーDFF11(入金拠点)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_bulk_card_tbl( ln_card_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_bulk_card_tbl( ln_card_idx ).tax_code = gt_out_tax_cls ) THEN
          -- 外税の場合、'N'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- 税込金額フラグ
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- 作成者
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- 作成日
--
        -- AR請求取引OIFデータ作成(税金行)===>NO.4
        ln_ar_idx := ln_ar_idx + 1;
--
        -- 取引明細DFF4用:自動採番番号
        BEGIN
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_bulk_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_bulk_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- 取引明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- 取引ソース:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- 会計帳簿ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- 税金行
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- 品目明細摘要
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- 通貨
        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax_card;
                                                        -- 税金行：消費税金額
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- リンク先明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_bulk_card_tbl( ln_card_idx ).dlv_invoice_number;
                                                        -- リンク先明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := TO_CHAR( ln_trx_number_id );
                                                        -- リンク先明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_bulk_card_tbl( ln_card_idx ).sales_exp_header_id;
                                                        -- リンク先明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_bulk_card_tbl( ln_card_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ（「User」を設定）
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート（1 を設定）
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_bulk_card_tbl( ln_card_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_bulk_card_tbl( ln_card_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_bulk_card_tbl( ln_card_idx ).tax_code;
                                                        -- 税金コード
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_bulk_card_tbl( ln_card_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag 
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_bulk_card_tbl( ln_card_idx ).tax_code = gt_out_tax_cls ) THEN
          -- 外税の場合、'N'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- 税込金額フラグ
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- 作成者
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- 作成日
        -- 集約フラグのリセット
        lv_sum_card_flag := cv_y_flag;
        ln_amount_card := 0;
--
      END IF;                                           -- 集約キー毎にAR OIFデータの集約終了
--
      IF ( lv_sum_flag = cv_n_flag ) THEN 
        -- 集約キーと集約金額のリセット
        lt_header_id       := gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id;
        lt_invoice_number  := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_number;
        lt_invoice_class   := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class;
        lt_goods_prod_cls  := gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls;
        lt_item_code       := gt_sales_bulk_tbl( sale_bulk_idx ).item_code;
        lt_card_sale_class := gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class;
        lt_red_black_flag  := gt_sales_bulk_tbl( sale_bulk_idx ).red_black_flag;
        lv_sum_card_flag := cv_y_flag;
--
        ln_amount := gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax  := gt_sales_bulk_tbl( sale_bulk_idx ).tax_amount;
        ELSE
          ln_tax  := 0;
        END IF;
      END IF;
--
      -- 販売実績ヘッダ更新のため：ROWIDの設定
      ln_sales_h_tbl_idx                   := ln_sales_h_tbl_idx + 1;
      gt_sales_h_tbl( ln_sales_h_tbl_idx ) := gt_sales_bulk_tbl( sale_bulk_idx ).xseh_rowid;
--
    END LOOP gt_sales_bulk_sum_loop;                    -- 販売実績データループ終了
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_no_lookup_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_term_id_expt THEN
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
  END edit_sum_bulk_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_dis_bulk_data
   * Description      : AR会計配分仕訳作成（大手量販店）(A-6)
   ***********************************************************************************/
  PROCEDURE edit_dis_bulk_data(
      ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_dis_bulk_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_ccid_idx         VARCHAR2(225);                                   -- セグメント１0８の結合（CCIDインデックス用）
    lv_tbl_nm           VARCHAR2(100);                                   -- 勘定科目組合せマスタテーブル
    lv_sum_flag         VARCHAR2(1);                                     -- 集約フラグ
    lt_ccid             gl_code_combinations.code_combination_id%TYPE;   -- 勘定科目CCID
    lt_segment3         fnd_lookup_values.attribute7%TYPE;               -- 勘定科目コード
--
    -- 集約キー
    lt_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE; -- 集約キー：納品伝票番号
    lt_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;  -- 集約キー：納品伝票区分
    lt_item_code        xxcos_sales_exp_lines.item_code%TYPE;            -- 集約キー：品目コード
    lt_prod_cls         xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
                                                                         -- 品目区分（製品・商品）
    lt_gyotai_sho       xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;    -- 集約キー：業態小分類
    lt_card_sale_class  xxcos_sales_exp_headers.card_sale_class%TYPE;    -- 集約キー：カード売り区分
    lt_red_black_flag   xxcos_sales_exp_lines.red_black_flag%TYPE;       -- 集約キー：赤黒フラグ
    lt_gccs_segment3    gl_code_combinations.segment3%TYPE;              -- 集約キー：売上勘定科目コード
    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- 集約キー：税金コード
    ln_amount           NUMBER DEFAULT 0;                                -- 集約後金額
    ln_tax              NUMBER DEFAULT 0;                                -- 集約後消費税金額
    ln_ar_dis_bul       NUMBER DEFAULT 0;                                -- AR会計配分集約インデックス
    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR会計配分OIFインデックス
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- 仕訳生成カウント
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    non_jour_cls_expt         EXCEPTION;                -- 仕訳パターンなし
    non_ccid_expt             EXCEPTION;                -- CCID取得出来ないエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- AR会計配分テーブルの非大手量販店データカウントセット
    ln_ar_dis_bul := gt_ar_dis_tbl.COUNT;
--
    --=====================================
    -- 1.AR会計配分仕訳パターンの取得
    --=====================================
--
    -- 仕訳パターン取得されてない場合
    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
     -- カーソルオープン
      BEGIN
        OPEN  jour_cls_cur;
        FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
      EXCEPTION
      -- 仕訳パターン取得失敗した場合
        WHEN OTHERS THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcos_short_nm
                           , iv_name         => cv_jour_nodata_msg
                           , iv_token_name1  => cv_tkn_lookup_type
                           , iv_token_value1 => cv_qct_jour_cls
                         );
          lv_errbuf := lv_errmsg;
          RAISE non_jour_cls_expt;
      END;
      -- 仕訳パターン取得失敗した場合
      IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_jour_nodata_msg
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => cv_qct_jour_cls
                       );
        lv_errbuf := lv_errmsg;
        RAISE non_jour_cls_expt;
      END IF;
--
      -- カーソルクローズ
      CLOSE jour_cls_cur;
    END IF;
--
    --=====================================
    -- 3.AR会計配分データ作成
    --=====================================
--
    -- 集約キーの値セット
    lt_invoice_number   := gt_ar_dis_bul_tbl( 1 ).dlv_invoice_number;
    lt_invoice_class    := gt_ar_dis_bul_tbl( 1 ).dlv_invoice_class;
    lt_item_code        := gt_ar_dis_bul_tbl( 1 ).item_code;
    lt_prod_cls         := gt_ar_dis_bul_tbl( 1 ).goods_prod_cls;
    lt_gyotai_sho       := gt_ar_dis_bul_tbl( 1 ).cust_gyotai_sho;
    lt_card_sale_class  := gt_ar_dis_bul_tbl( 1 ).card_sale_class;
    lt_red_black_flag   := gt_ar_dis_bul_tbl( 1 ).red_black_flag;
    lt_gccs_segment3    := gt_ar_dis_bul_tbl( 1 ).gccs_segment3;
    lt_tax_code         := gt_ar_dis_bul_tbl( 1 ).gcct_segment3;
--
    -- ラストデータ登録為に、ダミーデータをセットする
    gt_ar_dis_bul_tbl( gt_ar_dis_bul_tbl.COUNT + 1 ).sales_exp_header_id 
                        := gt_ar_dis_bul_tbl( gt_ar_dis_bul_tbl.COUNT ).sales_exp_header_id;
--
    <<gt_ar_dis_bul_tbl_loop>>
    FOR dis_sum_idx IN 1 .. gt_ar_dis_bul_tbl.COUNT LOOP
--
      -- AR会計配分データ集約開始(大手量)
      IF (  lt_invoice_number  = gt_ar_dis_bul_tbl( dis_sum_idx ).dlv_invoice_number
        AND lt_invoice_class   = gt_ar_dis_bul_tbl( dis_sum_idx ).dlv_invoice_class
        AND ( lt_item_code     = gt_ar_dis_bul_tbl( dis_sum_idx ).item_code
          OR lt_prod_cls       = gt_ar_dis_bul_tbl( dis_sum_idx ).goods_prod_cls )
        AND lt_gyotai_sho      = gt_ar_dis_bul_tbl( dis_sum_idx ).cust_gyotai_sho
        AND lt_card_sale_class = gt_ar_dis_bul_tbl( dis_sum_idx ).card_sale_class
        AND lt_red_black_flag  = gt_ar_dis_bul_tbl( dis_sum_idx ).red_black_flag
        AND lt_gccs_segment3   = gt_ar_dis_bul_tbl( dis_sum_idx ).gccs_segment3
        AND lt_tax_code        = gt_ar_dis_bul_tbl( dis_sum_idx ).gcct_segment3
        ) THEN
        -- 集約するフラグ初期設定
        lv_sum_flag := cv_y_flag;
--
        -- 本体金額と消費税額を集約する
        ln_amount := ln_amount + gt_ar_dis_bul_tbl( dis_sum_idx ).pure_amount;
        ln_tax    := ln_tax    + gt_ar_dis_bul_tbl( dis_sum_idx ).tax_amount;
      ELSE
        lv_sum_flag := cv_n_flag;
        ln_dis_idx  := dis_sum_idx - 1;
      END IF;
--
      -- 集約フラグ’N'の場合、下記AR会計配分OIF作成処理を行う
      IF ( lv_sum_flag = cv_n_flag ) THEN   
--
        -- 仕訳生成カウント初期値
        ln_jour_cnt := 1;
--
        -- 仕訳パターンよりAR会計配分の仕訳を編集する
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
          IF (  gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = lt_invoice_class
            AND (  gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = lt_item_code
              OR ( gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> lt_item_code
                AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls = lt_prod_cls ) )
            AND ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = lt_gyotai_sho
              OR  gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL )
            AND ( gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = lt_card_sale_class
              OR  gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL )
            AND ( gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
              OR  gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL )
            ) THEN
--
            -- 一回の集約に３レコードを作成する
            EXIT WHEN ( ln_jour_cnt > cn_jour_cnt );
--
            -- 勘定科目の編集
            IF ( gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_goods_msg
              OR gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_prod_msg
              OR gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_disc_msg ) THEN
              --売上勘定科目コード
              lt_segment3 := gt_ar_dis_bul_tbl( ln_dis_idx ).gccs_segment3;
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).segment3_nm = gv_tax_msg ) THEN
              --税金勘定科目コード
              lt_segment3 := gt_ar_dis_bul_tbl( ln_dis_idx ).gcct_segment3;
            ELSE
              --OTHER勘定科目コード
              lt_segment3 := gt_jour_cls_tbl( jcls_idx ).segment3;
            END IF;
--
            --=====================================
            -- 2.勘定科目CCIDの取得
            --=====================================
            -- 勘定科目セグメント１～セグメント８よりCCID取得
            lv_ccid_idx := gv_company_code                                   -- セグメント１(会社コード)
                        || NVL( gt_jour_cls_tbl( jcls_idx ).segment2,        -- セグメント２（部門コード）
                                gt_ar_dis_bul_tbl( ln_dis_idx ).sales_base_code )
                                                                             -- セグメント２(販売実績の売上拠点コード)
                        || lt_segment3                                       -- セグメント３(勘定科目コード)
                        || gt_jour_cls_tbl( jcls_idx ).segment4              -- セグメント４(補助科目コード:現金のみ設定)
                        || gt_jour_cls_tbl( jcls_idx ).segment5              -- セグメント５(顧客コード)
                        || gt_jour_cls_tbl( jcls_idx ).segment6              -- セグメント６(企業コード)
                        || gt_jour_cls_tbl( jcls_idx ).segment7              -- セグメント７(事業区分コード)
                        || gt_jour_cls_tbl( jcls_idx ).segment8;             -- セグメント８(予備)
--
            -- CCIDの存在チェック-->存在している場合、取得必要がない
            IF ( gt_sel_ccid_tbl.EXISTS(  lv_ccid_idx ) ) THEN
              lt_ccid := gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id;
            ELSE
              -- CCID取得共通関数よりCCIDを取得する
              lt_ccid := xxcok_common_pkg.get_code_combination_id_f (
                             gd_process_date
                           , gv_company_code
                           , NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                  gt_ar_dis_bul_tbl( ln_dis_idx ).sales_base_code )
                           , lt_segment3
                           , gt_jour_cls_tbl( jcls_idx ).segment4
                           , gt_jour_cls_tbl( jcls_idx ).segment5
                           , gt_jour_cls_tbl( jcls_idx ).segment6
                           , gt_jour_cls_tbl( jcls_idx ).segment7
                           , gt_jour_cls_tbl( jcls_idx ).segment8
                         );
              IF ( lt_ccid IS NULL ) THEN
                -- CCIDが取得できない場合
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm
                                , iv_name              => cv_ccid_nodata_msg
                                , iv_token_name1       => cv_tkn_segment1
                                , iv_token_value1      => gv_company_code
                                , iv_token_name2       => cv_tkn_segment2
                                , iv_token_value2      => NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                                               gt_ar_dis_bul_tbl( ln_dis_idx ).sales_base_code )
                                , iv_token_name3       => cv_tkn_segment3
                                , iv_token_value3      => lt_segment3
                                , iv_token_name4       => cv_tkn_segment4
                                , iv_token_value4      => gt_jour_cls_tbl( jcls_idx ).segment4
                                , iv_token_name5       => cv_tkn_segment5
                                , iv_token_value5      => gt_jour_cls_tbl( jcls_idx ).segment5
                                , iv_token_name6       => cv_tkn_segment6
                                , iv_token_value6      => gt_jour_cls_tbl( jcls_idx ).segment6
                                , iv_token_name7       => cv_tkn_segment7
                                , iv_token_value7      => gt_jour_cls_tbl( jcls_idx ).segment7
                                , iv_token_name8       => cv_tkn_segment8
                                , iv_token_value8      => gt_jour_cls_tbl( jcls_idx ).segment8
                              );
                lv_errbuf  := lv_errmsg;
                RAISE non_ccid_expt;
              END IF;
--
              -- 取得したCCIDをワークテーブルに設定する
              gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
--
            END IF;                                       -- CCID編集終了
--
          --=====================================
          -- AR会計配分OIFデータ設定
          --=====================================
            IF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rev ) THEN
              -- 収益行
              ln_ar_dis_bul := ln_ar_dis_bul + 1;
--
              -- フルVD（消化）とフルVD場合の金額編集
              IF ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_fvd_xiaoka
                OR gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_gyotai_fvd ) THEN
                ln_amount := ln_amount + ln_tax;
              END IF;
--
              -- AR会計配分OIFの設定項目
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- 取引明細コンテキスト値:「販売実績」をセット
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF1:「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute3
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute4
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).interface_line_dff4;
                                                          -- 取引明細DFF4:自動採番
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5:「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute7
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7:販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_bul ).account_class
                                                          := cv_acct_rev;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_bul ).amount       := ln_amount;
                                                          -- 金額(明細金額)
              gt_ar_dis_tbl( ln_ar_dis_bul ).percent      := cn_percent;
                                                          -- パーセント(割合):100
              gt_ar_dis_tbl( ln_ar_dis_bul ).code_combination_id
                                                          := lt_ccid;
                                                          -- 勘定科目組合せID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_bul ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- 仕訳明細カテゴリ:営業単位IDをセット
              gt_ar_dis_tbl( ln_ar_dis_bul ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- 営業単位ID
              gt_ar_dis_tbl( ln_ar_dis_bul ).created_by
                                                          := cn_created_by;
                                                          -- 作成者
              gt_ar_dis_tbl( ln_ar_dis_bul ).creation_date
                                                          := cd_creation_date;
                                                          -- 作成日
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rec ) THEN
              -- 債権行(金額設定なし)
              ln_ar_dis_bul := ln_ar_dis_bul + 1;
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- 取引明細コンテキスト:「販売実績」をセット
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF1:「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute3
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3:納品伝票番号をセット
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute4
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).interface_line_dff4;
                                                          -- 取引明細DFF4:自動採番
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5:「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute7
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_bul ).account_class
                                                          := cv_acct_rec;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_bul ).percent      := cn_percent;
                                                          -- パーセント(割合)100
              gt_ar_dis_tbl( ln_ar_dis_bul ).code_combination_id
                                                          := lt_ccid;
                                                          -- 勘定科目組合せID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_bul ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- 仕訳明細カテゴリ:営業単位IDをセット
              gt_ar_dis_tbl( ln_ar_dis_bul ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- 営業単位ID
              gt_ar_dis_tbl( ln_ar_dis_bul ).created_by
                                                          := cn_created_by;
                                                          -- 作成者
              gt_ar_dis_tbl( ln_ar_dis_bul ).creation_date
                                                          := cd_creation_date;
                                                          -- 作成日
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_tax ) THEN
              -- 税金行
              ln_ar_dis_bul := ln_ar_dis_bul + 1;
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- 取引明細コンテキスト値:「販売実績」をセット
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF1:「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute3
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute4
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).interface_tax_dff4;
                                                          -- 取引明細DFF4:自動採番
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5:「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_bul ).interface_line_attribute7
                                                          := gt_ar_dis_bul_tbl( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_bul ).account_class
                                                          := cv_acct_tax;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_bul ).amount       := ln_tax;
                                                          -- 金額(明細金額)
              gt_ar_dis_tbl( ln_ar_dis_bul ).percent      := cn_percent;
                                                          -- パーセント(割合):100
              gt_ar_dis_tbl( ln_ar_dis_bul ).code_combination_id
                                                          := lt_ccid;
                                                          -- 勘定科目組合せID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_bul ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- 仕訳明細カテゴリ:営業単位IDをセット
              gt_ar_dis_tbl( ln_ar_dis_bul ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- 営業単位ID
              gt_ar_dis_tbl( ln_ar_dis_bul ).created_by
                                                          := cn_created_by;
                                                          -- 作成者
              gt_ar_dis_tbl( ln_ar_dis_bul ).creation_date
                                                          := cd_creation_date;
                                                          -- 作成日
            END IF;
--
            -- 仕訳生成カウントセット
            ln_jour_cnt := ln_jour_cnt + 1;
          END IF;                                         -- 仕訳パターン毎にAR会計配分OIFデータの作成処理終了
--
        END LOOP gt_jour_cls_tbl_loop;                    -- 仕訳パターンよりデータ作成処理終了
--
      END IF;                                             -- 集約キー毎にAR会計配分OIFデータの集約終了
        -- 集約キーのリセット
        lt_invoice_number   := gt_ar_dis_bul_tbl( dis_sum_idx ).dlv_invoice_number;
        lt_invoice_class    := gt_ar_dis_bul_tbl( dis_sum_idx ).dlv_invoice_class;
        lt_item_code        := gt_ar_dis_bul_tbl( dis_sum_idx ).item_code;
        lt_prod_cls         := gt_ar_dis_bul_tbl( dis_sum_idx ).goods_prod_cls;
        lt_gyotai_sho       := gt_ar_dis_bul_tbl( dis_sum_idx ).cust_gyotai_sho;
        lt_card_sale_class  := gt_ar_dis_bul_tbl( dis_sum_idx ).card_sale_class;
        lt_red_black_flag   := gt_ar_dis_bul_tbl( dis_sum_idx ).red_black_flag;
        lt_gccs_segment3    := gt_ar_dis_bul_tbl( dis_sum_idx ).gccs_segment3;
        lt_tax_code         := gt_ar_dis_bul_tbl( dis_sum_idx ).gcct_segment3;
--
        -- 金額の設定
        ln_amount := gt_ar_dis_bul_tbl( dis_sum_idx ).pure_amount;
        ln_tax    := gt_ar_dis_bul_tbl( dis_sum_idx ).tax_amount;
--
    END LOOP gt_ar_dis_bul_tbl_loop;                      -- AR会計配分集約データループ終了
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
    WHEN non_jour_cls_expt THEN
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN non_ccid_expt THEN
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END edit_dis_bulk_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_aroif_data
   * Description      : AR請求取引OIF登録処理(A-7)
   ***********************************************************************************/
  PROCEDURE insert_aroif_data(
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2 )        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_aroif_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_tbl_nm VARCHAR2(255);                -- テーブル名
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
    --==============================================================
    -- 一般会計OIFテーブルへデータ登録
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_ar_interface_tbl.COUNT
        INSERT INTO
          ra_interface_lines_all
        VALUES
          gt_ar_interface_tbl(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      -- 登録に失敗した場合
      -- エラー件数設定
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm      -- アプリ短縮名
                      , iv_name              => cv_tkn_aroif_msg       -- メッセージID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                      , iv_token_name2       => cv_tkn_key_data
                      , iv_token_value2      => cv_blank
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END insert_aroif_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_ardis_data
   * Description      : AR会計配分OIF登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE insert_ardis_data(
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2 )        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_ardis_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_tbl_nm VARCHAR2(255);                -- テーブル名
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
    --==============================================================
    -- AR会計配分OIFテーブルへデータ登録
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_ar_dis_tbl.COUNT
        INSERT INTO
          ra_interface_distributions_all
        VALUES
          gt_ar_dis_tbl(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      -- 登録に失敗した場合
      -- エラー件数設定
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm      -- アプリ短縮名
                      , iv_name              => cv_tkn_ardis_msg       -- メッセージID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                      , iv_token_name2  => cv_tkn_key_data
                      , iv_token_value2 => cv_blank
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END insert_ardis_data;
--
  /***********************************************************************************
   * Procedure Name   : upd_data
   * Description      : 販売実績ヘッダ更新処理(A-9)
   ***********************************************************************************/
  PROCEDURE upd_data(
    ov_errbuf         OUT VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2 )        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'upd_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_tbl_nm VARCHAR2(255);                -- テーブル名
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- 販売実績ヘッダ更新処理
    --==============================================================
--
    -- 処理対象データのインタフェース済フラグを一括更新する
    BEGIN
      <<update_interface_flag>>
      FORALL i IN gt_sales_h_tbl.FIRST..gt_sales_h_tbl.LAST
        UPDATE
          xxcos_sales_exp_headers       xseh
        SET
          xseh.ar_interface_flag      = cv_y_flag,                     -- ARインタフェース済フラグ
          xseh.last_updated_by        = cn_last_updated_by,            -- 最終更新者
          xseh.last_update_date       = cd_last_update_date,           -- 最終更新日
          xseh.last_update_login      = cn_last_update_login,          -- 最終更新ログイン
          xseh.request_id             = cn_request_id,                 -- 要求ID
          xseh.program_application_id = cn_program_application_id,     -- コンカレント・プログラム・アプリID
          xseh.program_id             = cn_program_id,                 -- コンカレント・プログラムID
          xseh.program_update_date    = cd_program_update_date         -- プログラム更新日
        WHERE
          xseh.rowid                  = gt_sales_h_tbl( i );           -- 販売実績ROWID
--
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_update_data_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_update_data_expt THEN
      -- 更新に失敗した場合
      -- エラー件数設定
      gn_error_cnt := gn_target_cnt;
      lv_tbl_nm    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_tkn_sales_msg
                     );
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_data_update_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => lv_tbl_nm
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => cv_blank
                      );
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode   := cv_status_error;
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
  END upd_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
  (
      ov_errbuf    OUT VARCHAR2             --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2             --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )           --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_tbl_nm VARCHAR2(255);                -- テーブル名
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
    -- <カーソル名>レコード型
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
    gn_target_cnt    := 0;                  -- 対象件数
    gn_normal_cnt    := 0;                  -- 正常件数
    gn_error_cnt     := 0;                  -- エラー件数
    gn_aroif_cnt     := 0;                  -- AR請求取引OIF登録件数
    gn_ardis_cnt     := 0;                  -- AR会計配分OIF登録件数

--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode            -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.販売実績データ取得
    -- ===============================
    get_data(
        ov_errbuf  => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode            -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF (  lv_retcode = cv_status_warn ) THEN
      -- 販売実績データ抽出が0件時は、抽出レコードなし警告で終了
      RAISE global_no_data_expt;
    END IF;
--
      -- ===============================
      -- A-3.請求取引集約処理（非大手量販店）
      -- ===============================
    IF ( gt_sales_norm_tbl.COUNT > 0 ) THEN
      edit_sum_data(
           ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
         , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
         , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_process_expt;
      END IF;
    END IF;
--
      -- ===============================
      -- A-4.AR会計配分仕訳作成（非大手量販店）
      -- ===============================
    IF ( gt_ar_dis_sum_tbl.COUNT > 0 ) THEN
      edit_dis_data(
           ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
         , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
         , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_process_expt;
      END IF;
    END IF;
--
      -- ===============================
      -- A-5.AR請求取引情報集約処理（大手量販店）
      -- ===============================
    IF ( gt_sales_bulk_tbl.COUNT > 0 ) THEN
      edit_sum_bulk_data(
           ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
         , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
         , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_process_expt;
      END IF;
    END IF;
--
      -- ===============================
      -- A-6.AR会計配分仕訳作成（大手量販店）
      -- ===============================
    IF ( gt_ar_dis_bul_tbl.COUNT > 0 ) THEN
      edit_dis_bulk_data(
           ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
         , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
         , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- A-7.AR請求取引OIF登録処理
    -- ===============================
    insert_aroif_data(
          ov_errbuf       => lv_errbuf     -- エラー・メッセージ
        , ov_retcode      => lv_retcode    -- リターン・コード
        , ov_errmsg       => lv_errmsg     -- ユーザー・エラー・メッセージ
      );
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_insert_data_expt;
    END IF;
--
    -- ===============================
    -- A-8.AR会計配分OIF登録処理
    -- ===============================
    insert_ardis_data(
          ov_errbuf       => lv_errbuf     -- エラー・メッセージ
        , ov_retcode      => lv_retcode    -- リターン・コード
        , ov_errmsg       => lv_errmsg     -- ユーザー・エラー・メッセージ
      );
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_insert_data_expt;
    END IF;
--
    -- ===============================
    -- A-9.販売実績データの更新処理
    -- ===============================
    upd_data(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
      , ov_retcode => lv_retcode          -- リターン・コード
      , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_update_data_expt;
    END IF;
--
    -- 成功件数をセット
    gn_aroif_cnt  := gt_ar_interface_tbl.COUNT;                      -- AR請求取引OIF登録件数
    gn_ardis_cnt  := gt_ar_dis_tbl.COUNT;                            -- AR会計配分OIF登録件数
    gn_normal_cnt := gn_aroif_cnt + gn_ardis_cnt;
--
  EXCEPTION
    -- *** 対象データなし *** 
    WHEN global_no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** データ取得例外 *** 
    WHEN global_select_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 登録処理例外 ***
    WHEN global_insert_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 更新処理例外 ***
    WHEN global_update_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      errbuf      OUT VARCHAR2               -- エラー・メッセージ  --# 固定 #
    , retcode     OUT VARCHAR2 )             -- リターン・コード    --# 固定 #
  IS
--
--###########################  固定部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCCP';             -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(20) := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);         -- リターン・コード
    lv_errmsg          VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);       -- 終了メッセージコード
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        ov_errbuf  => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode             -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error OR lv_retcode = cv_status_warn) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --エラーメッセージ
      );
    END IF;
--
    -- ===============================
    -- A-7.終了処理
    -- ===============================
    --空行挿入
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力:AR請求取引OIF
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_success_aroif_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_aroif_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力:AR会計配分OIF
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_success_ardis_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_ardis_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --終了メッセージ
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxccp_short_nm
                    , iv_name        => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
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
END XXCOS013A01C;
/
