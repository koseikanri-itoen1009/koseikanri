CREATE OR REPLACE
PACKAGE BODY XXCOK014A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A01C(body)
 * Description      : 販売実績情報・手数料計算条件からの販売手数料計算処理
 * MD.050           : 条件別販手販協計算処理 MD050_COK_014_A01
 * Version          : 1.3
 *
 * Program List
 * -------------------------- ------------------------------------------------------------
 *  Name                       Description
 * -------------------------- ------------------------------------------------------------
 *  main                      販売実績情報・手数料計算条件からの販売手数料計算処理
 *  submain                   メイン処理プロシージャ
 *  init_proc                 初期処理(A-1)
 *  del_bm_support_info       販手販協保持期間外データの削除(A-2)
 *  chk_customer_info         処理対象顧客データの判断(A-4,A-22,A-40)
 *  get_bm_support_add_info   販手販協計算付加情報の取得(A-5,A-23,A-41)
 *  del_bm_contract_err_info  販手条件エラーデータの削除(A-6,A-24)
 *  get_active_vendor_info    支払先データの取得(A-9,A-27)
 *  cal_bm_contract10_info    売価別条件の計算(A-10,A-28)
 *  cal_bm_contract20_info    容器区分別条件の計算(A-11,A-29)
 *  cal_bm_contract30_info    一律条件の計算(A-12,A-30)
 *  cal_bm_contract40_info    定額条件の計算(A-13,A-31)
 *  cal_bm_contract50_info    電気料条件の計算(A-14,A-32)
 *  ins_bm_contract_err_info  販手条件エラーデータの登録(A-17,A-35)
 *  upd_sales_exp_lines_info  販売実績連携結果の更新(A-17,A-35,A-46)
 *  del_pre_bm_support_info   前回販手販協計算結果データの削除(A-18,A-36,A-47)
 *  ins_bm_support_info       条件別販手販協計算データの登録(A-20,A-38,A-49)
 *  
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   K.Ezaki          新規作成
 *  2009/02/13    1.1   K.Ezaki          障害COK_039 支払条件未設定顧客スキップ
 *  2009/02/17    1.2   K.Ezaki          障害COK_040 フルベンダーサイト固定修正
 *  2009/02/26    1.3   K.Ezaki          障害COK_060 一律条件計算結果累積
 *  2009/02/26    1.3   K.Ezaki          障害COK_061 一律条件定額計算
 *  2009/02/25    1.3   K.Ezaki          障害COK_062 定額条件割戻率・割戻額未設定
 *  2009/03/25    1.4   S.Kayahara       最終行にスラッシュ追加
 *****************************************************************************************/
--
  ------------------------------------------------------------
  -- ユーザー定義グローバル定数
  ------------------------------------------------------------
  -- パッケージ定義
  cv_pkg_name       CONSTANT VARCHAR2(12) := 'XXCOK014A01C';                     -- パッケージ名
  -- 初期値
  cv_msg_part       CONSTANT VARCHAR2(3)  := ' : ';                              -- メッセージデリミタ
  cv_msg_cont       CONSTANT VARCHAR2(1)  := '.';                                -- カンマ
  cn_zero           CONSTANT NUMBER       := 0;                                  -- 数値:0
  cn_one            CONSTANT NUMBER       := 1;                                  -- 数値:1
  cn_two            CONSTANT NUMBER       := 2;                                  -- 数値:2
  cv_zero           CONSTANT VARCHAR2(1)  := '0';                                -- 文字:0
  cv_one            CONSTANT VARCHAR2(1)  := '1';                                -- 文字:1
  cv_msg_wq         CONSTANT VARCHAR2(1)  := '"';                                -- ダブルクォーテイション
  cv_msg_c          CONSTANT VARCHAR2(1)  := ',';                                -- コンマ
  cv_csv_sep        CONSTANT VARCHAR2(1)  := ',';                                -- CSVセパレータ
  cv_yes            CONSTANT VARCHAR2(1)  := 'Y';                                -- 文字:Y
  cv_no             CONSTANT VARCHAR2(1)  := 'N';                                -- 文字:N
  cv_output         CONSTANT VARCHAR2(6)  := 'OUTPUT';                           -- ヘッダログ出力
  cv_language       CONSTANT VARCHAR2(4)  := 'LANG';                             -- 言語
  -- 日付書式
  cv_format1        CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                       -- 書式１
  cv_format2        CONSTANT VARCHAR2(6)  := 'YYYYMM';                           -- 書式２
  cv_format3        CONSTANT VARCHAR2(2)  := 'MM';                               -- 書式３
  -- ベンダー区分
  cv_vendor_type1   CONSTANT VARCHAR2(1)  := '1';                                -- フルベンダー
  cv_vendor_type2   CONSTANT VARCHAR2(1)  := '2';                                -- フルベンダー消化
  cv_vendor_type3   CONSTANT VARCHAR2(1)  := '3';                                -- 一般
  -- 顧客区分
  cv_cust_type1     CONSTANT VARCHAR2(2)  := '10';                               -- 顧客
  cv_cust_type2     CONSTANT VARCHAR2(2)  := '13';                               -- 請求顧客
  -- 業態区分
  cv_bus_type       CONSTANT VARCHAR2(2)  := '11';                               -- ベンダー
  -- 業態小分類区分
  cv_bus_type1      CONSTANT VARCHAR2(2)  := '25';                               -- フルベンダー
  cv_bus_type2      CONSTANT VARCHAR2(2)  := '24';                               -- フルベンダー消化
  -- 請求区分
  cv_bill_site_use  CONSTANT VARCHAR2(7)  := 'BILL_TO';                          -- 請求
  -- 容器群ダミーコード
  cv_ves_dmmy       CONSTANT VARCHAR2(4)  := '9999';                             -- 容器群ダミーコード
  -- 会計カレンダステータス
  cv_cal_op_status  CONSTANT VARCHAR2(1)  := 'O';                                -- オープン
  -- 連携ステータス
  cv_if_status0     CONSTANT VARCHAR2(1)  := '0';                                -- 未処理
  cv_if_status1     CONSTANT VARCHAR2(1)  := '1';                                -- 処理済
  cv_if_status2     CONSTANT VARCHAR2(1)  := '2';                                -- 不要
  -- 支払先退避
  cn_bm1_set        CONSTANT PLS_INTEGER  := 1;                                  -- BM1退避
  cn_bm2_set        CONSTANT PLS_INTEGER  := 2;                                  -- BM2退避
  cn_bm3_set        CONSTANT PLS_INTEGER  := 3;                                  -- BM3退避
  -- 支払区分
  cv_bm1_type       CONSTANT VARCHAR2(3)  := 'BM1';                              -- 契約者仕入先コード
  cv_bm2_type       CONSTANT VARCHAR2(3)  := 'BM2';                              -- 紹介者BM支払仕入先コード１
  cv_bm3_type       CONSTANT VARCHAR2(3)  := 'BM3';                              -- 紹介者BM支払仕入先コード２
  cv_en1_type       CONSTANT VARCHAR2(3)  := 'EN1';                              -- 電気料
  -- 支払月
  cv_month_type1    CONSTANT VARCHAR2(2)  := '40';                               -- 当月
  cv_month_type2    CONSTANT VARCHAR2(2)  := '50';                               -- 翌月
  -- サイト
  cv_site_type1     CONSTANT VARCHAR2(2)  := '00';                               -- 当月
  cv_site_type2     CONSTANT VARCHAR2(2)  := '01';                               -- 翌月
  -- BM支払区分
  cv_bm_pay1_type   CONSTANT VARCHAR2(1)  := '1';                                -- FB支払案内有
  cv_bm_pay2_type   CONSTANT VARCHAR2(1)  := '2';                                -- FB支払案内無
  cv_bm_pay3_type   CONSTANT VARCHAR2(1)  := '3';                                -- AP支払
  cv_bm_pay4_type   CONSTANT VARCHAR2(1)  := '4';                                -- 現金持参
  -- 計算条件
  cv_cal_type10     CONSTANT VARCHAR2(2)  := '10';                               -- 売価別条件
  cv_cal_type20     CONSTANT VARCHAR2(2)  := '20';                               -- 容器区分別条件
  cv_cal_type30     CONSTANT VARCHAR2(2)  := '30';                               -- 一律条件
  cv_cal_type40     CONSTANT VARCHAR2(2)  := '40';                               -- 定額条件
  cv_cal_type50     CONSTANT VARCHAR2(2)  := '50';                               -- 電気料(固定)／電気料（変動）
  cv_cal_type60     CONSTANT VARCHAR2(2)  := '60';                               -- 入金値引額
  -- WHOカラム
  cn_created_by     CONSTANT NUMBER       := fnd_global.user_id;                 -- 作成者のユーザーID
  cn_last_upd_by    CONSTANT NUMBER       := fnd_global.user_id;                 -- 最終更新者のユーザーID
  cn_last_upd_login CONSTANT NUMBER       := fnd_global.login_id;                -- 最終更新者のログインID
  cn_request_id     CONSTANT NUMBER       := fnd_global.conc_request_id;         -- 要求ID
  cn_prg_appl_id    CONSTANT NUMBER       := fnd_global.prog_appl_id;            -- コンカレントアプリケーションID
  cn_program_id     CONSTANT NUMBER       := fnd_global.conc_program_id;         -- コンカレントプログラムID
  -- アプリケーション短縮名
  cv_ap_type_xxccp  CONSTANT VARCHAR2(5)  := 'XXCCP';                            -- 共通
  cv_ap_type_xxcok  CONSTANT VARCHAR2(5)  := 'XXCOK';                            -- 個別開発
  cv_ap_type_sqlgl  CONSTANT VARCHAR2(5)  := 'SQLGL';                            -- 会計
  cv_ap_type_ar     CONSTANT VARCHAR2(2)  := 'AR';                               -- 請求
  -- ステータス・コード
  cv_status_normal  CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- 異常:2
  cv_customer_err   CONSTANT VARCHAR2(1)  := 8;                                  -- 処理対象外顧客エラー:8
  cv_contract_err   CONSTANT VARCHAR2(1)  := 9;                                  -- 販手条件エラー:9
  -- 共通メッセージ定義
  cv_normal_msg     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';                 -- 正常終了メッセージ
  cv_warn_msg       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005';                 -- 警告終了メッセージ
  cv_error_msg      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90007';                 -- エラー終了メッセージ
  cv_mainmsg_90000  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';                 -- 対象件数出力
  cv_mainmsg_90001  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';                 -- 成功件数出力
  cv_mainmsg_90002  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';                 -- エラー件数出力
  cv_mainmsg_90003  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003';                 -- スキップ件数出力
  -- 個別メッセージ定義
  cv_prmmsg_00022   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00022';                 -- 業務日付入力パラメータ
  cv_prmmsg_00044   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00044';                 -- 実行区分入力パラメータ
  cv_prmmsg_00028   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';                 -- 業務日付取得エラー
  cv_prmmsg_00003   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';                 -- プロファイル値取得エラー
  cv_prmmsg_00051   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00051';                 -- 販手販協保持期間外情報ロックエラー
  cv_prmmsg_10398   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10398';                 -- 販手販協保持期間外情報削除エラー
  cv_prmmsg_10399   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10399';                 -- 契約情報取得エラー
  cv_prmmsg_00036   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00036';                 -- 締め・支払日取得エラー
  cv_prmmsg_00027   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00027';                 -- 営業日取得エラー
  cv_prmmsg_00079   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00079';                 -- 請求先顧客取得エラー
  cv_prmmsg_00011   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00011';                 -- 会計カレンダ情報取得エラー
  cv_prmmsg_00080   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00080';                 -- 販手条件エラー情報ロックエラー
  cv_prmmsg_10400   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10400';                 -- 販手条件エラー情報削除エラー
  cv_prmmsg_10401   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10401';                 -- 販手条件エラー情報登録エラー
  cv_prmmsg_10426   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10426';                 -- 販手条件取得エラー
  cv_prmmsg_10427   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10427';                 -- 支払先情報取得エラー
  cv_prmmsg_00081   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00081';                 -- 販売実績連携結果更新ロックエラー
  cv_prmmsg_10402   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10402';                 -- 販売実績連携結果更新エラー
  cv_prmmsg_10403   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10403';                 -- 販手販協前回計算情報削除エラー
  cv_prmmsg_10404   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10404';                 -- 販手販協計算情報登録エラー
  cv_prmmsg_10405   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10405';                 -- 販売実績取得エラー
  cv_prmmsg_00100   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00100';                 -- 機能例外エラー
  cv_prmmsg_00101   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00101';                 -- 共通機能例外エラー
  -- メッセージトークン定義
  cv_tkn_bis_date   CONSTANT VARCHAR2(13) := 'BUSINESS_DATE';                    -- 業務日付トークン
  cv_tkn_proc_date  CONSTANT VARCHAR2(9)  := 'PROC_DATE';                        -- 処理日トークン
  cv_tkn_proc_type  CONSTANT VARCHAR2(9)  := 'PROC_TYPE';                        -- 実行区分トークン
  cv_tkn_profile    CONSTANT VARCHAR2(7)  := 'PROFILE';                          -- プロファイルトークン
  cv_tkn_dept_code  CONSTANT VARCHAR2(9)  := 'DEPT_CODE';                        -- 部門コードトークン
  cv_tkn_cust_code  CONSTANT VARCHAR2(9)  := 'CUST_CODE';                        -- 顧客コードトークン
  cv_tkn_vend_code  CONSTANT VARCHAR2(11) := 'VENDOR_CODE';                      -- 仕入先コードトークン
  cv_tkn_close_date CONSTANT VARCHAR2(10) := 'CLOSE_DATE';                       -- 締め日トークン
  cv_tkn_pay_date   CONSTANT VARCHAR2(8)  := 'PAY_DATE';                         -- 支払日トークン
  cv_tkn_sales_amt  CONSTANT VARCHAR2(9)  := 'SALES_AMT';                        -- 売価トークン
  cv_tkn_cont_type  CONSTANT VARCHAR2(14) := 'CONTAINER_TYPE';                   -- 容器区分トークン
  cv_tkn_count      CONSTANT VARCHAR2(5)  := 'COUNT';                            -- 件数出力トークン
  cv_tkn_errmsg     CONSTANT VARCHAR2(6)  := 'ERRMSG';                           -- エラーメッセージトークン
  -- プロファイル定義
  cv_pro_org_code   CONSTANT VARCHAR2(30) := 'ORG_ID';                           -- 組織ID
  cv_pro_books_code CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';                 -- 会計帳簿ID
  cv_pro_bm_sup_fm  CONSTANT VARCHAR2(30) := 'XXCOK1_BM_SUPPORT_PERIOD_FROM';    -- 条件別販手販協計算処理期間(From)
  cv_pro_bm_sup_to  CONSTANT VARCHAR2(30) := 'XXCOK1_BM_SUPPORT_PERIOD_TO';      -- 条件別販手販協計算処理期間(To)
  cv_pro_sales_ret  CONSTANT VARCHAR2(30) := 'XXCOK1_SALES_RETENTION_PERIOD';    -- 販手販協計算結果保持期間
  cv_pro_elec_ch    CONSTANT VARCHAR2(30) := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';     -- 電気料(変動)品目コード
  cv_pro_vendor     CONSTANT VARCHAR2(30) := 'XXCOK1_VENDOR_DUMMY_CODE';         -- 仕入先ダミーコード
  -- 参照表定義
  cv_lk_bm_dis_type CONSTANT VARCHAR2(30) := 'XXCOK1_BM_DISTRICT_PARA_MST';      -- 販手販協計算実行区分
  cv_lk_itm_yk_type CONSTANT VARCHAR2(30) := 'XXCMM_ITM_YOKIGUN';                -- 容器群区分
  cv_lk_cust_type   CONSTANT VARCHAR2(30) := 'XXCMM_CUST_GYOTAI_SHO';            -- 顧客業態小分類区分
  cv_lk_no_inv_type CONSTANT VARCHAR2(30) := 'XXCOK1_NO_INV_ITEM_MST';           -- 非在庫品目区分
  ------------------------------------------------------------
  -- ユーザー定義グローバル変数
  ------------------------------------------------------------
  gv_language       fnd_languages.iso_language%TYPE DEFAULT NULL;                -- 言語
  gd_proc_date      DATE                            DEFAULT NULL;                -- 業務日付
  gv_proc_type      VARCHAR2(1)                     DEFAULT NULL;                -- 実行区分
  gn_target_cnt     NUMBER                          DEFAULT 0;                   -- 対象件数
  gn_normal_cnt     NUMBER                          DEFAULT 0;                   -- 正常件数
  gn_warning_cnt    NUMBER                          DEFAULT 0;                   -- 警告件数
  gn_error_cnt      NUMBER                          DEFAULT 0;                   -- エラー件数
  gn_customer_cnt   NUMBER                          DEFAULT 0;                   -- 顧客件数
  gn_contract_cnt   NUMBER                          DEFAULT 0;                   -- 販手条件エラー件数
  gd_limit_date     DATE                            DEFAULT NULL;                -- 販手販協保持期限日
  gn_pro_org_id     NUMBER                          DEFAULT NULL;                -- 組織ID
  gn_pro_books_id   NUMBER                          DEFAULT NULL;                -- 会計帳簿ID
  gn_pro_bm_sup_fm  NUMBER                          DEFAULT NULL;                -- 条件別販手販協計算処理期間(From)
  gn_pro_bm_sup_to  NUMBER                          DEFAULT NULL;                -- 条件別販手販協計算処理期間(To)
  gn_pro_sales_ret  NUMBER                          DEFAULT NULL;                -- 販手販協計算結果保持期間
  gv_pro_elec_ch    VARCHAR2(7)                     DEFAULT NULL;                -- 電気料(変動)品目コード
  gv_pro_vendor     VARCHAR2(9)                     DEFAULT NULL;                -- 仕入先ダミーコード
  gv_pro_vendor_s   VARCHAR2(9)                     DEFAULT NULL;                -- 仕入先サイトダミーコード
  gv_bm1_vendor     VARCHAR2(9)                     DEFAULT NULL;                -- BM1仕入先コード
  gv_bm1_vendor_s   VARCHAR2(9)                     DEFAULT NULL;                -- BM1仕入先サイトコード
  gv_sales_upd_flg  VARCHAR2(1)                     DEFAULT NULL;                -- 販売実績更新フラグ
  ------------------------------------------------------------
  -- ユーザー定義グローバルテーブル・レコード型
  ------------------------------------------------------------
  -- 支払条件退避テーブル型
  TYPE g_term_name_ttype IS TABLE OF ra_terms_tl.name%TYPE INDEX BY BINARY_INTEGER;
  -- 締め日情報退避レコード型
  TYPE g_close_date_rtype IS RECORD (
     start_date xxcok_cond_bm_support.closing_date%TYPE                          -- 販手計算開始日
    ,end_date   xxcok_cond_bm_support.closing_date%TYPE                          -- 販手計算終了日
    ,close_date xxcok_cond_bm_support.closing_date%TYPE                          -- 締め日
    ,pay_date   xxcok_cond_bm_support.expect_payment_date%TYPE                   -- 支払日
    ,term_name  ra_terms_tl.name%TYPE                                            -- 支払条件
  );
  -- 締め日情報退避テーブル型
  TYPE g_close_date_ttype IS TABLE OF g_close_date_rtype INDEX BY BINARY_INTEGER;
  -- 複数支払条件情報退避レコード型
  TYPE g_many_term_rtype IS RECORD (
     to_close_date xxcok_cond_bm_support.closing_date%TYPE                       -- 今回締め日
    ,to_pay_date   xxcok_cond_bm_support.expect_payment_date%TYPE                -- 今回支払日
    ,to_term_name  ra_terms_tl.name%TYPE                                         -- 今回支払条件
    ,fm_close_date xxcok_cond_bm_support.closing_date%TYPE                       -- 前回締め日
    ,fm_pay_date   xxcok_cond_bm_support.expect_payment_date%TYPE                -- 前回支払日
    ,fm_term_name  ra_terms_tl.name%TYPE                                         -- 前回支払条件
    ,end_date      xxcok_cond_bm_support.closing_date%TYPE                       -- 販手計算終了日
  );
  -- 複数支払条件情報退避テーブル型
  TYPE g_many_term_ttype IS TABLE OF g_many_term_rtype INDEX BY BINARY_INTEGER;
  -- 計算条件退避テーブル型
  TYPE g_calculation_ttype IS TABLE OF xxcok_mst_bm_contract.calc_type%TYPE INDEX BY BINARY_INTEGER;
  -- 支払先チェック退避レコード型
  TYPE g_vendor_rtype IS RECORD (
     bm_type     VARCHAR2(3)                                                     -- 支払区分
    ,vendor_code po_vendors.segment1%TYPE                                        -- 仕入先コード
  );
  -- 支払先チェック退避テーブル型
  TYPE g_vendor_ttype IS TABLE OF g_vendor_rtype INDEX BY BINARY_INTEGER;
  -- 販手販協計算登録情報退避レコード型
  TYPE g_bm_support_rtype IS RECORD (
     bm_type              VARCHAR2(3)                                            -- 支払区分
    ,base_code            xxcok_cond_bm_support.base_code%TYPE                   -- 拠点コード
    ,emp_code             xxcok_cond_bm_support.emp_code%TYPE                    -- 担当者コード
    ,delivery_cust_code   xxcok_cond_bm_support.delivery_cust_code%TYPE          -- 顧客【納品先】
    ,demand_to_cust_code  xxcok_cond_bm_support.demand_to_cust_code%TYPE         -- 顧客【請求先】
    ,acctg_year           xxcok_cond_bm_support.acctg_year%TYPE                  -- 会計年度
    ,chain_store_code     xxcok_cond_bm_support.chain_store_code%TYPE            -- チェーン店コード
    ,supplier_code        xxcok_cond_bm_support.supplier_code%TYPE               -- 仕入先コード
    ,supplier_site_code   xxcok_cond_bm_support.supplier_site_code%TYPE          -- 仕入先サイトコード
    ,calc_type            xxcok_cond_bm_support.calc_type%TYPE                   -- 計算条件
    ,delivery_date        xxcok_cond_bm_support.delivery_date%TYPE               -- 納品日年月
    ,delivery_qty         xxcok_cond_bm_support.delivery_qty%TYPE                -- 納品数量
    ,delivery_unit_type   xxcok_cond_bm_support.delivery_unit_type%TYPE          -- 納品単位
    ,selling_amt_tax      xxcok_cond_bm_support.selling_amt_tax%TYPE             -- 売上金額(税込)
    ,rebate_rate          xxcok_cond_bm_support.rebate_rate%TYPE                 -- 割戻率
    ,rebate_amt           xxcok_cond_bm_support.rebate_amt%TYPE                  -- 割戻額
    ,container_type       xxcok_cond_bm_support.container_type_code%TYPE         -- 容器区分コード
    ,selling_price        xxcok_cond_bm_support.selling_price%TYPE               -- 売価金額
    ,cond_bm_amt_tax      xxcok_cond_bm_support.cond_bm_amt_tax%TYPE             -- 条件別手数料額(税込)
    ,cond_bm_amt_no_tax   xxcok_cond_bm_support.cond_bm_amt_no_tax%TYPE          -- 条件別手数料額(税抜)
    ,cond_tax_amt         xxcok_cond_bm_support.cond_tax_amt%TYPE                -- 条件別消費税額
    ,electric_amt_tax     xxcok_cond_bm_support.electric_amt_tax%TYPE            -- 電気料(税込)
    ,electric_amt_no_tax  xxcok_cond_bm_support.electric_amt_no_tax%TYPE         -- 電気料(税抜)
    ,electric_tax_amt     xxcok_cond_bm_support.electric_tax_amt%TYPE            -- 電気料消費税額
    ,csh_rcpt_dis_amt     xxcok_cond_bm_support.csh_rcpt_discount_amt%TYPE       -- 入金値引額
    ,csh_rcpt_dis_amt_tax xxcok_cond_bm_support.csh_rcpt_discount_amt_tax%TYPE   -- 入金値引消費税額
    ,tax_class            xxcok_cond_bm_support.consumption_tax_class%TYPE       -- 消費税区分
    ,tax_code             xxcok_cond_bm_support.tax_code%TYPE                    -- 税金コード
    ,tax_rate             xxcok_cond_bm_support.tax_rate%TYPE                    -- 消費税率
    ,term_code            xxcok_cond_bm_support.term_code%TYPE                   -- 支払条件
    ,closing_date         xxcok_cond_bm_support.closing_date%TYPE                -- 締め日
    ,expect_payment_date  xxcok_cond_bm_support.expect_payment_date%TYPE         -- 支払予定日
    ,calc_period_from     xxcok_cond_bm_support.calc_target_period_from%TYPE     -- 計算対象期間(From)
    ,calc_period_to       xxcok_cond_bm_support.calc_target_period_to%TYPE       -- 計算対象期間(To)
    ,cond_bm_if_status    xxcok_cond_bm_support.cond_bm_interface_status%TYPE    -- 連携ステータス(条件別販手販協)
    ,cond_bm_if_date      xxcok_cond_bm_support.cond_bm_interface_date%TYPE      -- 連携日(条件別販手販協)
    ,bm_interface_status  xxcok_cond_bm_support.bm_interface_status%TYPE         -- 連携ステータス(販手残高)
    ,bm_interface_date    xxcok_cond_bm_support.bm_interface_date%TYPE           -- 連携日(販手残高)
    ,ar_interface_status  xxcok_cond_bm_support.ar_interface_status%TYPE         -- 連携ステータス(AR)
    ,ar_interface_date    xxcok_cond_bm_support.ar_interface_date%TYPE           -- 連携日(AR)
  );
  -- 販手販協計算登録情報退避テーブル型
  TYPE g_bm_support_ttype IS TABLE OF g_bm_support_rtype INDEX BY BINARY_INTEGER;
  ------------------------------------------------------------
  -- ユーザー定義例外
  ------------------------------------------------------------
  -- 共通例外
  global_process_expt    EXCEPTION;                                              -- 処理部共通例外
  global_api_expt        EXCEPTION;                                              -- 共通関数例外
  global_api_others_expt EXCEPTION;                                              -- 共通関数OTHERS例外
  global_lock_expt       EXCEPTION;                                              -- グローバル例外
  -- プラグマ
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  --
  /**********************************************************************************
   * Procedure Name   : ins_bm_support_info
   * Description      : 条件別販手販協計算データの登録(A-20,A-38,A-49)
   ***********************************************************************************/
  PROCEDURE ins_bm_support_info(
     ov_errbuf        OUT VARCHAR2                                -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                                -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                                -- ユーザー・エラーメッセージ
    ,iv_vendor_type   IN  VARCHAR2                                -- ベンダー区分
    ,id_fm_close_date IN  xxcok_cond_bm_support.closing_date%TYPE -- 前回締め日
    ,id_to_close_date IN  xxcok_cond_bm_support.closing_date%TYPE -- 今回締め日
    ,it_bm_support    IN  g_bm_support_ttype                      -- 販手販協計算登録情報
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'ins_bm_support_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000);   -- エラーメッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000);   -- メッセージ
    lb_retcode  BOOLEAN;          -- メッセージ戻り値
    ln_cnt      PLS_INTEGER := 0; -- カウンタ
    ln_ins_cnt  PLS_INTEGER := 0; -- 登録件数カウンタ
  --
  BEGIN
  --
    --===============================================
    -- A-0.初期化
    --===============================================
    lv_retcode := cv_status_normal;
    --===============================================
    -- A-1.条件別販手販協計算登録
    --===============================================
    BEGIN
      << bm_support_all_loop >>
      FOR ln_cnt IN it_bm_support.FIRST..it_bm_support.LAST LOOP
        -------------------------------------------------
        -- 条件別販手販協計算登録
        -------------------------------------------------
        INSERT INTO xxcok_cond_bm_support(
           cond_bm_support_id        -- 条件別販手販協ID
          ,base_code                 -- 拠点コード
          ,emp_code                  -- 担当者コード
          ,delivery_cust_code        -- 顧客【納品先】
          ,demand_to_cust_code       -- 顧客【請求先】
          ,acctg_year                -- 会計年度
          ,chain_store_code          -- チェーン店コード
          ,supplier_code             -- 仕入先コード
          ,supplier_site_code        -- 仕入先サイトコード
          ,calc_type                 -- 計算条件
          ,delivery_date             -- 納品日年月
          ,delivery_qty              -- 納品数量
          ,delivery_unit_type        -- 納品単位
          ,selling_amt_tax           -- 売上金額(税込)
          ,rebate_rate               -- 割戻率
          ,rebate_amt                -- 割戻額
          ,container_type_code       -- 容器区分コード
          ,selling_price             -- 売価金額
          ,cond_bm_amt_tax           -- 条件別手数料額(税込)
          ,cond_bm_amt_no_tax        -- 条件別手数料額(税抜)
          ,cond_tax_amt              -- 条件別消費税額
          ,electric_amt_tax          -- 電気料(税込)
          ,electric_amt_no_tax       -- 電気料(税抜)
          ,electric_tax_amt          -- 電気料消費税額
          ,csh_rcpt_discount_amt     -- 入金値引額
          ,csh_rcpt_discount_amt_tax -- 入金値引消費税額
          ,consumption_tax_class     -- 消費税区分
          ,tax_code                  -- 税金コード
          ,tax_rate                  -- 消費税率
          ,term_code                 -- 支払条件
          ,closing_date              -- 締め日
          ,expect_payment_date       -- 支払予定日
          ,calc_target_period_from   -- 計算対象期間(From)
          ,calc_target_period_to     -- 計算対象期間(To)
          ,cond_bm_interface_status  -- 連携ステータス(条件別販手販協)
          ,cond_bm_interface_date    -- 連携日(条件別販手販協)
          ,bm_interface_status       -- 連携ステータス(販手残高)
          ,bm_interface_date         -- 連携日(販手残高)
          ,ar_interface_status       -- 連携ステータス(AR)
          ,ar_interface_date         -- 連携日(AR)
          ,created_by                -- 作成者
          ,creation_date             -- 作成日
          ,last_updated_by           -- 最終更新者
          ,last_update_date          -- 最終更新日
          ,last_update_login         -- 最終更新ログイン
          ,request_id                -- 要求ID
          ,program_application_id    -- コンカレント・プログラム・アプリケーションID
          ,program_id                -- コンカレント・プログラムID
          ,program_update_date       -- プログラム更新日
        ) VALUES (
           xxcok_cond_bm_support_s01.NEXTVAL            -- 条件別販手販協ID
          ,it_bm_support( ln_cnt ).base_code            -- 拠点コード
          ,it_bm_support( ln_cnt ).emp_code             -- 担当者コード
          ,it_bm_support( ln_cnt ).delivery_cust_code   -- 顧客【納品先】
          ,it_bm_support( ln_cnt ).demand_to_cust_code  -- 顧客【請求先】
          ,it_bm_support( ln_cnt ).acctg_year           -- 会計年度
          ,it_bm_support( ln_cnt ).chain_store_code     -- チェーン店コード
          ,it_bm_support( ln_cnt ).supplier_code        -- 仕入先コード
          ,it_bm_support( ln_cnt ).supplier_site_code   -- 仕入先サイトコード
          ,it_bm_support( ln_cnt ).calc_type            -- 計算条件
          ,it_bm_support( ln_cnt ).delivery_date        -- 納品日年月
          ,it_bm_support( ln_cnt ).delivery_qty         -- 納品数量
          ,it_bm_support( ln_cnt ).delivery_unit_type   -- 納品単位
          ,it_bm_support( ln_cnt ).selling_amt_tax      -- 売上金額(税込)
          ,it_bm_support( ln_cnt ).rebate_rate          -- 割戻率
          ,it_bm_support( ln_cnt ).rebate_amt           -- 割戻額
          ,it_bm_support( ln_cnt ).container_type       -- 容器区分コード
          ,it_bm_support( ln_cnt ).selling_price        -- 売価金額
          ,it_bm_support( ln_cnt ).cond_bm_amt_tax      -- 条件別手数料額(税込)
          ,it_bm_support( ln_cnt ).cond_bm_amt_no_tax   -- 条件別手数料額(税抜)
          ,it_bm_support( ln_cnt ).cond_tax_amt         -- 条件別消費税額
          ,it_bm_support( ln_cnt ).electric_amt_tax     -- 電気料(税込)
          ,it_bm_support( ln_cnt ).electric_amt_no_tax  -- 電気料(税抜)
          ,it_bm_support( ln_cnt ).electric_tax_amt     -- 電気料消費税額
          ,it_bm_support( ln_cnt ).csh_rcpt_dis_amt     -- 入金値引額
          ,it_bm_support( ln_cnt ).csh_rcpt_dis_amt_tax -- 入金値引消費税額
          ,it_bm_support( ln_cnt ).tax_class            -- 消費税区分
          ,it_bm_support( ln_cnt ).tax_code             -- 税金コード
          ,it_bm_support( ln_cnt ).tax_rate             -- 消費税率
          ,it_bm_support( ln_cnt ).term_code            -- 支払条件
          ,it_bm_support( ln_cnt ).closing_date         -- 締め日
          ,it_bm_support( ln_cnt ).expect_payment_date  -- 支払予定日
          ,it_bm_support( ln_cnt ).calc_period_from     -- 計算対象期間(From)
          ,it_bm_support( ln_cnt ).calc_period_to       -- 計算対象期間(To)
          ,it_bm_support( ln_cnt ).cond_bm_if_status    -- 連携ステータス(条件別販手販協)
          ,it_bm_support( ln_cnt ).cond_bm_if_date      -- 連携日(条件別販手販協)
          ,it_bm_support( ln_cnt ).bm_interface_status  -- 連携ステータス(販手残高)
          ,it_bm_support( ln_cnt ).bm_interface_date    -- 連携日(販手残高)
          ,it_bm_support( ln_cnt ).ar_interface_status  -- 連携ステータス(AR)
          ,it_bm_support( ln_cnt ).ar_interface_date    -- 連携日(AR)
          ,cn_created_by                                -- 作成者
          ,SYSDATE                                      -- 作成日
          ,cn_last_upd_by                               -- 最終更新者
          ,SYSDATE                                      -- 最終更新日
          ,cn_last_upd_login                            -- 最終更新ログイン
          ,cn_request_id                                -- 要求ID
          ,cn_prg_appl_id                               -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                                -- コンカレント・プログラムID
          ,SYSDATE                                      -- プログラム更新日
        );
        -- 登録件数をインクリメント
        ln_ins_cnt := ln_ins_cnt + 1;
      END LOOP bm_support_all_loop;
    EXCEPTION
      ----------------------------------------------------------
      -- 条件別販手販協計算登録例外
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10404
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => it_bm_support( ln_ins_cnt ).delivery_cust_code
                        ,iv_token_name2  => cv_tkn_close_date
                        ,iv_token_value2 => TO_CHAR( id_to_close_date,cv_format1 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- 出力区分
                        ,iv_message  => lv_out_msg      -- メッセージ
                        ,in_new_line => cn_zero         -- 改行
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END ins_bm_support_info;
  --
  /**********************************************************************************
   * Procedure Name   : del_pre_bm_support_info
   * Description      : 前回販手販協計算結果データの削除(A-18,A-36,A-47)
   ***********************************************************************************/
  PROCEDURE del_pre_bm_support_info(
     ov_errbuf        OUT VARCHAR2                                -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                                -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                                -- ユーザー・エラーメッセージ
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE    -- 顧客コード
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE -- 締め日
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_pre_bm_support_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 条件別販手販協テーブルロック
    CURSOR bm_support_del_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- 顧客コード
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- 締め日
    )
    IS
      SELECT xcs.cond_bm_support_id AS bm_support_id -- 前回販手販協計算結果
      FROM   xxcok_cond_bm_support xcs -- 条件別販手販協テーブル
      WHERE  xcs.delivery_cust_code = iv_customer_code
      AND    xcs.closing_date       = id_close_date
      FOR UPDATE NOWAIT;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.前回販手販協計算結果データ削除ロック処理
    -------------------------------------------------
    -- ロック処理
    OPEN bm_support_del_cur(
       iv_customer_code -- 顧客コード
      ,id_close_date    -- 締め日
    );
    CLOSE bm_support_del_cur;
    -------------------------------------------------
    -- 2.前回販手販協計算結果データ削除処理
    -------------------------------------------------
    BEGIN
      DELETE FROM xxcok_cond_bm_support xcs
      WHERE  xcs.delivery_cust_code = iv_customer_code
      AND    xcs.closing_date       = id_close_date;
    EXCEPTION
      ----------------------------------------------------------
      -- 前回販手販協計算結果データ削除例外
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10403
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => iv_customer_code
                        ,iv_token_name2  => cv_tkn_close_date
                        ,iv_token_value2 => TO_CHAR( id_close_date,cv_format1 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- 出力区分
                        ,iv_message  => lv_out_msg      -- メッセージ
                        ,in_new_line => cn_zero         -- 改行
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ロック例外ハンドラ
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00051
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END del_pre_bm_support_info;
  --
  /**********************************************************************************
   * Procedure Name   : upd_sales_exp_lines_info
   * Description      : 販売実績連携結果の更新(A-17,A-35,A-46)
   ***********************************************************************************/
  PROCEDURE upd_sales_exp_lines_info(
     ov_errbuf           OUT VARCHAR2                                           -- エラーメッセージ
    ,ov_retcode          OUT VARCHAR2                                           -- リターン・コード
    ,ov_errmsg           OUT VARCHAR2                                           -- ユーザー・エラーメッセージ
    ,iv_if_status        IN  xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE  -- 手数料計算インタフェース済フラグ
    ,iv_customer_code    IN  hz_cust_accounts.account_number%TYPE               -- 顧客コード
    ,iv_invoice_num      IN  xxcos_sales_exp_lines.dlv_invoice_number%TYPE      -- 納品伝票番号
    ,iv_invoice_line_num IN  xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE -- 納品明細番号
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_sales_exp_lines_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 販売実績明細テーブルロック
    CURSOR sales_exp_lines_upd_cur(
       iv_invoice_num      IN xxcos_sales_exp_lines.dlv_invoice_number%TYPE      -- 納品伝票番号
      ,iv_invoice_line_num IN xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE -- 納品明細番号
    )
    IS
      SELECT xsl.sales_exp_line_id AS sales_exp_line_id -- 販売実績明細
      FROM   xxcos_sales_exp_lines xsl -- 販売実績明細テーブル
      WHERE  xsl.dlv_invoice_number      = iv_invoice_num
      AND    xsl.dlv_invoice_line_number = iv_invoice_line_num
      FOR UPDATE NOWAIT;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.販売実績明細テーブルロック処理
    -------------------------------------------------
    -- ロック処理
    OPEN sales_exp_lines_upd_cur(
       iv_invoice_num      -- 納品伝票番号
      ,iv_invoice_line_num -- 納品明細番号
    );
    CLOSE sales_exp_lines_upd_cur;
    -------------------------------------------------
    -- 2.販売実績連携結果更新処理
    -------------------------------------------------
    BEGIN
      UPDATE xxcos_sales_exp_lines -- 販売実績明細テーブル
      SET    to_calculate_fees_flag = iv_if_status      -- 手数料計算インタフェース済フラグ
            ,last_updated_by        = cn_last_upd_by    -- 最終更新者
            ,last_update_date       = SYSDATE           -- 最終更新日
            ,last_update_login      = cn_last_upd_login -- 最終更新ログイン
            ,request_id             = cn_request_id     -- 要求ID
            ,program_application_id = cn_prg_appl_id    -- コンカレント・プログラム・アプリケーションID
            ,program_id             = cn_program_id     -- コンカレント・プログラムID
            ,program_update_date    = SYSDATE           -- プログラム更新日
      WHERE  dlv_invoice_number      = iv_invoice_num
      AND    dlv_invoice_line_number = iv_invoice_line_num;
    EXCEPTION
      ----------------------------------------------------------
      -- 販売実績連携結果更新例外
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10402
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => iv_customer_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- 出力区分
                        ,iv_message  => lv_out_msg      -- メッセージ
                        ,in_new_line => cn_zero         -- 改行
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ロック例外ハンドラ
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00081
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END upd_sales_exp_lines_info;
  --
  /**********************************************************************************
   * Procedure Name   : ins_bm_contract_err_info
   * Description      : 販手条件エラーデータの登録(A-17,A-35)
   ***********************************************************************************/
  PROCEDURE ins_bm_contract_err_info(
     ov_errbuf         OUT VARCHAR2                                     -- エラーメッセージ
    ,ov_retcode        OUT VARCHAR2                                     -- リターン・コード
    ,ov_errmsg         OUT VARCHAR2                                     -- ユーザー・エラーメッセージ
    ,iv_base_code      IN  xxcos_sales_exp_headers.sales_base_code%TYPE -- 拠点コード
    ,iv_customer_code  IN  hz_cust_accounts.account_number%TYPE         -- 顧客コード
    ,iv_item_code      IN  xxcos_sales_exp_lines.item_code%TYPE         -- 品目コード
    ,iv_container_type IN  fnd_lookup_values.attribute1%TYPE            -- 容器区分コード
    ,in_retail_amount  IN  xxcos_sales_exp_lines.dlv_unit_price%TYPE    -- 売価
    ,in_sales_amount   IN  xxcos_sales_exp_lines.sale_amount%TYPE       -- 売上金額(税込)
    ,id_close_date     IN  xxcok_cond_bm_support.closing_date%TYPE      -- 締め日
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'ins_bm_contract_err_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- メッセージ戻り値
  --
  BEGIN
  --
    --===============================================
    -- A-0.初期化
    --===============================================
    ov_retcode := cv_status_normal;
    --===============================================
    -- A-1.販手条件エラー登録
    --===============================================
    BEGIN
      INSERT INTO xxcok_bm_contract_err(
         base_code              -- 拠点コード
        ,cust_code              -- 顧客コード
        ,item_code              -- 品目コード
        ,container_type_code    -- 容器区分コード
        ,selling_price          -- 売価
        ,selling_amt_tax        -- 売上金額(税込)
        ,closing_date           -- 締め日
        ,created_by             -- 作成者
        ,creation_date          -- 作成日
        ,last_updated_by        -- 最終更新者
        ,last_update_date       -- 最終更新日
        ,last_update_login      -- 最終更新ログイン
        ,request_id             -- 要求ID
        ,program_application_id -- コンカレント・プログラム・アプリケーションID
        ,program_id             -- コンカレント・プログラムID
        ,program_update_date    -- プログラム更新日
      ) VALUES (
         iv_base_code      -- 拠点コード
        ,iv_customer_code  -- 顧客コード
        ,iv_item_code      -- 品目コード
        ,iv_container_type -- 容器区分コード
        ,in_retail_amount  -- 売価
        ,in_sales_amount   -- 売上金額(税込)
        ,id_close_date     -- 締め日
        ,cn_created_by     -- 作成者
        ,SYSDATE           -- 作成日
        ,cn_last_upd_by    -- 最終更新者
        ,SYSDATE           -- 最終更新日
        ,cn_last_upd_login -- 最終更新ログイン
        ,cn_request_id     -- 要求ID
        ,cn_prg_appl_id    -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id     -- コンカレント・プログラムID
        ,SYSDATE           -- プログラム更新日
      );
    EXCEPTION
      ----------------------------------------------------------
      -- 販手条件エラー登録例外
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10401
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_base_code
                        ,iv_token_name2  => cv_tkn_cust_code
                        ,iv_token_value2 => iv_customer_code
                        ,iv_token_name3  => cv_tkn_close_date
                        ,iv_token_value3 => TO_CHAR( id_close_date,cv_format1 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- 出力区分
                        ,iv_message  => lv_out_msg      -- メッセージ
                        ,in_new_line => cn_zero         -- 改行
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
    END;
    --===============================================
    -- A-2.販手条件エラーメッセージ出力
    --===============================================
    IF ( ov_retcode = cv_status_normal ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_10426
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_customer_code
                      ,iv_token_name2  => cv_tkn_sales_amt
                      ,iv_token_value2 => TO_CHAR( in_retail_amount )
                      ,iv_token_name3  => cv_tkn_cont_type
                      ,iv_token_value3 => iv_container_type
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END ins_bm_contract_err_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract60_info
   * Description      : 入金値引額の計算(A-43)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract60_info(
     ov_errbuf        OUT VARCHAR2                                             -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                                             -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                                             -- ユーザー・エラーメッセージ
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE                 -- 顧客コード
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE              -- 締め日
    ,in_sale_amount   IN  xxcos_sales_exp_lines.sale_amount%TYPE               -- 売上金額
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE                -- 消費税率
    ,in_discount_rate IN  xxcmm_cust_accounts.receiv_discount_rate%TYPE        -- 入金値引率
    ,on_rc_amount     OUT xxcok_cond_bm_support.csh_rcpt_discount_amt%TYPE     -- 入金値引額
    ,on_rc_amount_tax OUT xxcok_cond_bm_support.csh_rcpt_discount_amt_tax%TYPE -- 入金値引消費税額
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract60_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    -- 計算結果退避
    ln_rc_amount     xxcok_cond_bm_support.csh_rcpt_discount_amt%TYPE     := NULL; -- 入金値引額
    ln_rc_amount_tax xxcok_cond_bm_support.csh_rcpt_discount_amt_tax%TYPE := NULL; -- 入金値引消費税額
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.入金値引額計算
    -------------------------------------------------
    -- 入金値引額＝売上金額×入金値引率
    ln_rc_amount := NVL( in_sale_amount,cn_zero ) * ( NVL( in_discount_rate,cn_zero ) / 100 );
    -- 入金値引額税抜き＝入金値引額÷(1＋(100/販売実績情報.消費税率))
    ln_rc_amount_tax := ROUND( NVL( ln_rc_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
    -- 入金値引消費税額＝販売手数料－販売手数料税抜き
    ln_rc_amount_tax := ln_rc_amount - ln_rc_amount_tax;
    -------------------------------------------------
    -- 3.戻り値設定
    -------------------------------------------------
    on_rc_amount     := ln_rc_amount;     -- 入金値引額
    on_rc_amount_tax := ln_rc_amount_tax; -- 入金値引消費税額
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract60_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract50_info
   * Description      : 電気料条件の計算(A-14,A-32)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract50_info(
     ov_errbuf        OUT VARCHAR2                                           -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                                           -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                                           -- ユーザー・エラーメッセージ
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE               -- 顧客コード
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE            -- 締め日
    ,iv_calculat_type IN  xxcok_mst_bm_contract.calc_type%TYPE               -- 計算条件
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE              -- 消費税率
    ,iv_con_tax_class IN  xxcos_sales_exp_headers.consumption_tax_class%TYPE -- 消費税区分
    ,on_el_amount     OUT xxcok_cond_bm_support.electric_amt_tax%TYPE        -- 電気料
    ,on_el_amount_tax OUT xxcok_cond_bm_support.electric_tax_amt%TYPE        -- 電気料消費税額
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract50_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    -- 計算結果退避
    ln_el_amount     xxcok_cond_bm_support.electric_amt_tax%TYPE := NULL; -- 電気料
    ln_el_amount_tax xxcok_cond_bm_support.electric_tax_amt%TYPE := NULL; -- 電気料消費税額
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 販手条件情報カーソル定義
    CURSOR contract_mst_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- 顧客コード
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- 締め日
      ,iv_calculat_type IN xxcok_mst_bm_contract.calc_type%TYPE    -- 計算条件
    )
    IS
      SELECT xmb.calc_type AS calc_type -- 計算条件
            ,xmb.bm1_amt   AS bm1_amt   -- BM1金額
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y：計算対象
      AND    xmb.calc_type        = iv_calculat_type
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- 販手条件情報レコード定義
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ローカル例外
    --===============================
    contract_err_expt EXCEPTION; -- 販手条件エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.電気料条件判定
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code -- 顧客コード
      ,id_close_date    -- 締め日：今回締め日
      ,iv_calculat_type -- 計算条件
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- 条件存在チェック
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- カーソルクローズ
      CLOSE contract_mst_cur;
      -- 販手条件エラー
      RAISE contract_err_expt;
    END IF;
    -- カーソルクローズ
    CLOSE contract_mst_cur;
    -------------------------------------------------
    -- 2.電気料条件計算
    -------------------------------------------------
    -- 税区分が非課税の場合
    IF ( iv_con_tax_class = cv_zero ) THEN
      -- 電気料＝0
      ln_el_amount := cn_zero;
      -- 電気料消費税額＝0
      ln_el_amount_tax := cn_zero;
    -- 税区分が非課税以外の場合
    ELSE
      -- 電気料＝BM1金額
      ln_el_amount := NVL( contract_mst_rec.bm1_amt,cn_zero );
      -- 電気料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
      ln_el_amount_tax := ROUND( NVL( ln_el_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
      -- 電気料消費税額＝販売手数料－販売手数料税抜き
      ln_el_amount_tax := ln_el_amount - ln_el_amount_tax;
    END IF;
    -------------------------------------------------
    -- 3.戻り値設定
    -------------------------------------------------
    on_el_amount     := ln_el_amount;     -- 電気料
    on_el_amount_tax := ln_el_amount_tax; -- 電気料消費税額
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 販手条件エラー例外ハンドラ
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract50_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract40_info
   * Description      : 定額条件の計算(A-13,A-31)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract40_info(
     ov_errbuf        OUT VARCHAR2                                -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                                -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                                -- ユーザー・エラーメッセージ
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE    -- 顧客コード
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE -- 締め日
    ,iv_bm_type       IN  VARCHAR2                                -- 支払区分
    ,iv_calculat_type IN  xxcok_mst_bm_contract.calc_type%TYPE    -- 計算条件
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE   -- 消費税率
    ,on_bm_amt        OUT xxcok_mst_bm_contract.bm1_amt%TYPE      -- 割戻額
    ,on_bm_amount     OUT xxcos_sales_exp_lines.sale_amount%TYPE  -- 販売手数料
    ,on_bm_amount_tax OUT xxcos_sales_exp_lines.tax_amount%TYPE   -- 販売手数料消費税額
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract40_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    -- 計算結果退避
    ln_bm_amt        xxcok_mst_bm_contract.bm1_amt%TYPE     := NULL; -- 割戻額
    ln_bm_amount     xxcos_sales_exp_lines.sale_amount%TYPE := NULL; -- 販売手数料
    ln_bm_amount_tax xxcos_sales_exp_lines.tax_amount%TYPE  := NULL; -- 販売手数料消費税額
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 販手条件情報カーソル定義
    CURSOR contract_mst_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- 顧客コード
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- 締め日
      ,iv_calculat_type IN xxcok_mst_bm_contract.calc_type%TYPE    -- 計算条件
    )
    IS
      SELECT xmb.calc_type AS calc_type -- 計算条件
            ,xmb.bm1_amt   AS bm1_amt   -- BM1金額
            ,xmb.bm2_amt   AS bm2_amt   -- BM2金額
            ,xmb.bm3_amt   AS bm3_amt   -- BM3金額
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y：計算対象
      AND    xmb.calc_type        = iv_calculat_type
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- 販手条件情報レコード定義
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ローカル例外
    --===============================
    contract_err_expt EXCEPTION; -- 販手条件エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.定額条件判定
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code -- 顧客コード
      ,id_close_date    -- 締め日：今回締め日
      ,iv_calculat_type -- 計算条件
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- 条件存在チェック
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- カーソルクローズ
      CLOSE contract_mst_cur;
      -- 販手条件エラー
      RAISE contract_err_expt;
    END IF;
    -- カーソルクローズ
    CLOSE contract_mst_cur;
    -------------------------------------------------
    -- 2.定額条件計算
    -------------------------------------------------
    -- 契約者仕入先判定
    IF ( iv_bm_type = cv_bm1_type ) THEN
      -- 割戻額退避
      ln_bm_amt := NVL( contract_mst_rec.bm1_amt,cn_zero );
      -- 販売手数料＝BM1金額
      ln_bm_amount := NVL( contract_mst_rec.bm1_amt,cn_zero );
      -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
      ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
      -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
      ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
    -- 紹介者BM支払仕入先１判定
    ELSIF ( iv_bm_type = cv_bm2_type ) THEN
      -- 割戻額退避
      ln_bm_amt := NVL( contract_mst_rec.bm2_amt,cn_zero );
      -- 販売手数料＝BM2金額
      ln_bm_amount := NVL( contract_mst_rec.bm2_amt,cn_zero );
      -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
      ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
      -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
      ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
    -- 紹介者BM支払仕入先３判定
    ELSIF ( iv_bm_type = cv_bm3_type ) THEN
      -- 割戻額退避
      ln_bm_amt := NVL( contract_mst_rec.bm3_amt,cn_zero );
      -- 販売手数料＝BM3金額
      ln_bm_amount := NVL( contract_mst_rec.bm3_amt,cn_zero );
      -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
      ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
      -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
      ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
    END IF;
    -------------------------------------------------
    -- 3.戻り値設定
    -------------------------------------------------
    on_bm_amt        := ln_bm_amt;        -- 割戻額
    on_bm_amount     := ln_bm_amount;     -- 販売手数料
    on_bm_amount_tax := ln_bm_amount_tax; -- 販売手数料消費税額
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 販手条件エラー例外ハンドラ
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract40_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract30_info
   * Description      : 一律条件の計算(A-12,A-30)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract30_info(
     ov_errbuf        OUT VARCHAR2                                -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                                -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                                -- ユーザー・エラーメッセージ
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE    -- 顧客コード
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE -- 締め日
    ,iv_bm_type       IN  VARCHAR2                                -- 支払区分
    ,iv_calculat_type IN  xxcok_mst_bm_contract.calc_type%TYPE    -- 計算条件
    ,in_sales_amount  IN  xxcos_sales_exp_lines.sale_amount%TYPE  -- 売上金額
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE   -- 消費税率
    ,in_dlv_quantity  IN  xxcos_sales_exp_lines.dlv_qty%TYPE      -- 納品数量
    ,on_bm_pct        OUT xxcok_mst_bm_contract.bm1_pct%TYPE      -- 割戻率
    ,on_bm_amt        OUT xxcok_mst_bm_contract.bm1_amt%TYPE      -- 割戻額
    ,on_bm_amount     OUT xxcos_sales_exp_lines.sale_amount%TYPE  -- 販売手数料
    ,on_bm_amount_tax OUT xxcos_sales_exp_lines.tax_amount%TYPE   -- 販売手数料消費税額
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract30_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    -- 計算結果退避
    ln_bm_pct        xxcok_mst_bm_contract.bm1_pct%TYPE       := NULL; -- 割戻率
    ln_bm_amt        xxcok_mst_bm_contract.bm1_amt%TYPE       := NULL; -- 割戻額
    ln_bm_amount     xxcos_sales_exp_lines.sale_amount%TYPE := NULL; -- 販売手数料
    ln_bm_amount_tax xxcos_sales_exp_lines.tax_amount%TYPE  := NULL; -- 販売手数料消費税額
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 販手条件情報カーソル定義
    CURSOR contract_mst_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- 顧客コード
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- 締め日
      ,iv_calculat_type IN xxcok_mst_bm_contract.calc_type%TYPE    -- 計算条件
    )
    IS
      SELECT xmb.calc_type AS calc_type -- 計算条件
            ,xmb.bm1_pct   AS bm1_pct   -- BM1率(%)
            ,xmb.bm1_amt   AS bm1_amt   -- BM1金額
            ,xmb.bm2_pct   AS bm2_pct   -- BM2率(%)
            ,xmb.bm2_amt   AS bm2_amt   -- BM2金額
            ,xmb.bm3_pct   AS bm3_pct   -- BM3率(%)
            ,xmb.bm3_amt   AS bm3_amt   -- BM3金額
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y：計算対象
      AND    xmb.calc_type        = iv_calculat_type
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- 販手条件情報レコード定義
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ローカル例外
    --===============================
    contract_err_expt EXCEPTION; -- 販手条件エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.一律条件判定
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code -- 顧客コード
      ,id_close_date    -- 締め日：今回締め日
      ,iv_calculat_type -- 計算条件
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- 条件存在チェック
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- カーソルクローズ
      CLOSE contract_mst_cur;
      -- 販手条件エラー
      RAISE contract_err_expt;
    END IF;
    -- カーソルクローズ
    CLOSE contract_mst_cur;
    -------------------------------------------------
    -- 2.一律条件計算
    -------------------------------------------------
    -- 契約者仕入先判定
    IF ( iv_bm_type = cv_bm1_type ) THEN
      -- 計算方法（率・金額）判定
      IF ( contract_mst_rec.bm1_pct IS NOT NULL ) THEN
        -- 割戻率退避
        ln_bm_pct := NVL( contract_mst_rec.bm1_pct,cn_zero );
        -- 販売手数料＝販売実績情報.売上金額×BM1率（%）
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm1_pct,cn_zero ) / 100 ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- 割戻額退避
        ln_bm_amt := NVL( contract_mst_rec.bm1_amt,cn_zero );
        -- 販売手数料＝販売実績情報.納品数量×BM1金額
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm1_amt,cn_zero ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- 紹介者BM支払仕入先１判定
    ELSIF ( iv_bm_type = cv_bm2_type ) THEN
      -- 計算方法（率・金額）判定
      IF ( contract_mst_rec.bm2_pct IS NOT NULL ) THEN
        -- 割戻率退避
        ln_bm_pct := NVL( contract_mst_rec.bm2_pct,cn_zero );
        -- 販売手数料＝販売実績情報.売上金額×BM2率（%）
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm2_pct,cn_zero ) / 100 ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- 割戻額退避
        ln_bm_amt := NVL( contract_mst_rec.bm2_amt,cn_zero );
        -- 販売手数料＝販売実績情報.納品数量×BM2金額
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm2_amt,cn_zero ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- 紹介者BM支払仕入先３判定
    ELSIF ( iv_bm_type = cv_bm3_type ) THEN
      -- 計算方法（率・金額）判定
      IF ( contract_mst_rec.bm3_pct IS NOT NULL ) THEN
        -- 割戻率退避
        ln_bm_pct := NVL( contract_mst_rec.bm3_pct,cn_zero );
        -- 販売手数料＝販売実績情報.売上金額×BM3率（%）
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm3_pct,cn_zero ) / 100 ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- 割戻額退避
        ln_bm_amt := NVL( contract_mst_rec.bm3_amt,cn_zero );
        -- 販売手数料＝販売実績情報.納品数量×BM3金額
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm3_amt,cn_zero ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    END IF;
    -------------------------------------------------
    -- 3.戻り値設定
    -------------------------------------------------
    on_bm_pct        := ln_bm_pct;        -- 割戻率
    on_bm_amt        := ln_bm_amt;        -- 割戻額
    on_bm_amount     := ln_bm_amount;     -- 販売手数料
    on_bm_amount_tax := ln_bm_amount_tax; -- 販売手数料消費税額
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 販手条件エラー例外ハンドラ
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract30_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract20_info
   * Description      : 容器区分別条件の計算(A-11,A-29)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract20_info(
     ov_errbuf         OUT VARCHAR2                                -- エラーメッセージ
    ,ov_retcode        OUT VARCHAR2                                -- リターン・コード
    ,ov_errmsg         OUT VARCHAR2                                -- ユーザー・エラーメッセージ
    ,iv_customer_code  IN  hz_cust_accounts.account_number%TYPE    -- 顧客コード
    ,id_close_date     IN  xxcok_cond_bm_support.closing_date%TYPE -- 締め日
    ,iv_bm_type        IN  VARCHAR2                                -- 支払区分
    ,iv_calculat_type  IN  xxcok_mst_bm_contract.calc_type%TYPE    -- 計算条件
    ,iv_container_type IN  fnd_lookup_values.attribute1%TYPE       -- 容器区分
    ,in_sales_amount   IN  xxcos_sales_exp_lines.sale_amount%TYPE  -- 売上金額
    ,in_tax_rate       IN  xxcos_sales_exp_headers.tax_rate%TYPE   -- 消費税率
    ,in_dlv_quantity   IN  xxcos_sales_exp_lines.dlv_qty%TYPE      -- 納品数量
    ,on_bm_pct         OUT xxcok_mst_bm_contract.bm1_pct%TYPE      -- 割戻率
    ,on_bm_amt         OUT xxcok_mst_bm_contract.bm1_amt%TYPE      -- 割戻額
    ,on_bm_amount      OUT xxcos_sales_exp_lines.sale_amount%TYPE  -- 販売手数料
    ,on_bm_amount_tax  OUT xxcos_sales_exp_lines.tax_amount%TYPE   -- 販売手数料消費税額
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract20_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    -- 計算結果退避
    ln_bm_pct        xxcok_mst_bm_contract.bm1_pct%TYPE     := NULL; -- 割戻率
    ln_bm_amt        xxcok_mst_bm_contract.bm1_amt%TYPE     := NULL; -- 割戻額
    ln_bm_amount     xxcos_sales_exp_lines.sale_amount%TYPE := NULL; -- 販売手数料
    ln_bm_amount_tax xxcos_sales_exp_lines.tax_amount%TYPE  := NULL; -- 販売手数料消費税額
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 販手条件情報カーソル定義
    CURSOR contract_mst_cur(
       iv_customer_code  IN hz_cust_accounts.account_number%TYPE           -- 顧客コード
      ,id_close_date     IN xxcok_cond_bm_support.closing_date%TYPE        -- 締め日
      ,iv_calculat_type  IN xxcok_mst_bm_contract.calc_type%TYPE           -- 計算条件
      ,iv_container_type IN xxcok_mst_bm_contract.container_type_code%TYPE -- 容器区分
    )
    IS
      SELECT xmb.calc_type           AS calc_type           -- 計算条件
            ,xmb.container_type_code AS container_type_code -- 容器区分
            ,xmb.bm1_pct             AS bm1_pct             -- BM1率(%)
            ,xmb.bm1_amt             AS bm1_amt             -- BM1金額
            ,xmb.bm2_pct             AS bm2_pct             -- BM2率(%)
            ,xmb.bm2_amt             AS bm2_amt             -- BM2金額
            ,xmb.bm3_pct             AS bm3_pct             -- BM3率(%)
            ,xmb.bm3_amt             AS bm3_amt             -- BM3金額
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code           = iv_customer_code
      AND    xmb.calc_target_flag    = cv_yes -- Y：計算対象
      AND    xmb.calc_type           = iv_calculat_type
      AND    xmb.container_type_code = iv_container_type
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- 販手条件情報レコード定義
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ローカル例外
    --===============================
    contract_err_expt EXCEPTION; -- 販手条件エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.容器区分別条件判定
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code  -- 顧客コード
      ,id_close_date     -- 締め日：今回締め日
      ,iv_calculat_type  -- 計算条件
      ,iv_container_type -- 容器区分
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- 条件存在チェック
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- カーソルクローズ
      CLOSE contract_mst_cur;
      -- 販手条件エラー
      RAISE contract_err_expt;
    END IF;
    -- カーソルクローズ
    CLOSE contract_mst_cur;
    -------------------------------------------------
    -- 2.容器区分別条件計算
    -------------------------------------------------
    -- 契約者仕入先判定
    IF ( iv_bm_type = cv_bm1_type ) THEN
      -- 計算方法（率・金額）判定
      IF ( contract_mst_rec.bm1_pct IS NOT NULL ) THEN
        -- 割戻率退避
        ln_bm_pct := NVL( contract_mst_rec.bm1_pct,cn_zero );
        -- 販売手数料＝販売実績情報.売上金額×BM1率（%）
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm1_pct,cn_zero ) / 100 ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- 割戻額退避
        ln_bm_amt := NVL( contract_mst_rec.bm1_amt,cn_zero );
        -- 販売手数料＝販売実績情報.納品数量×BM1金額
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm1_amt,cn_zero ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- 紹介者BM支払仕入先１判定
    ELSIF ( iv_bm_type = cv_bm2_type ) THEN
      -- 計算方法（率・金額）判定
      IF ( contract_mst_rec.bm2_pct IS NOT NULL ) THEN
        -- 割戻率退避
        ln_bm_pct := NVL( contract_mst_rec.bm2_pct,cn_zero );
        -- 販売手数料＝販売実績情報.売上金額×BM2率（%）
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm2_pct,cn_zero ) / 100 ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- 割戻額退避
        ln_bm_amt := NVL( contract_mst_rec.bm2_amt,cn_zero );
        -- 販売手数料＝販売実績情報.納品数量×BM2金額
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm2_amt,cn_zero ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- 紹介者BM支払仕入先３判定
    ELSIF ( iv_bm_type = cv_bm3_type ) THEN
      -- 計算方法（率・金額）判定
      IF ( contract_mst_rec.bm3_pct IS NOT NULL ) THEN
        -- 割戻率退避
        ln_bm_pct := NVL( contract_mst_rec.bm3_pct,cn_zero );
        -- 販売手数料＝販売実績情報.売上金額×BM3率（%）
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm3_pct,cn_zero ) / 100 ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- 割戻額退避
        ln_bm_amt := NVL( contract_mst_rec.bm3_amt,cn_zero );
        -- 販売手数料＝販売実績情報.納品数量×BM3金額
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm3_amt,cn_zero ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    END IF;
    -------------------------------------------------
    -- 3.戻り値設定
    -------------------------------------------------
    on_bm_pct        := ln_bm_pct;        -- 割戻率
    on_bm_amt        := ln_bm_amt;        -- 割戻額
    on_bm_amount     := ln_bm_amount;     -- 販売手数料
    on_bm_amount_tax := ln_bm_amount_tax; -- 販売手数料消費税額
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 販手条件エラー例外ハンドラ
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract20_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract10_info
   * Description      : 売価別条件の計算(A-10,A-28)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract10_info(
     ov_errbuf        OUT VARCHAR2                                  -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                                  -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                                  -- ユーザー・エラーメッセージ
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE      -- 顧客コード
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE   -- 締め日
    ,iv_bm_type       IN  VARCHAR2                                  -- 支払区分
    ,iv_calculat_type IN  xxcok_mst_bm_contract.calc_type%TYPE      -- 計算条件
    ,in_retail_amount IN  xxcos_sales_exp_lines.dlv_unit_price%TYPE -- 売価
    ,in_sales_amount  IN  xxcos_sales_exp_lines.sale_amount%TYPE    -- 売上金額
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE     -- 消費税率
    ,in_dlv_quantity  IN  xxcos_sales_exp_lines.dlv_qty%TYPE        -- 納品数量
    ,on_bm_pct        OUT xxcok_mst_bm_contract.bm1_pct%TYPE        -- 割戻率
    ,on_bm_amt        OUT xxcok_mst_bm_contract.bm1_amt%TYPE        -- 割戻額
    ,on_bm_amount     OUT xxcos_sales_exp_lines.sale_amount%TYPE    -- 販売手数料
    ,on_bm_amount_tax OUT xxcos_sales_exp_lines.tax_amount%TYPE     -- 販売手数料消費税額
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract10_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    -- 計算結果退避
    ln_bm_pct        xxcok_mst_bm_contract.bm1_pct%TYPE     := NULL; -- 割戻率
    ln_bm_amt        xxcok_mst_bm_contract.bm1_amt%TYPE     := NULL; -- 割戻額
    ln_bm_amount     xxcos_sales_exp_lines.sale_amount%TYPE := NULL; -- 販売手数料
    ln_bm_amount_tax xxcos_sales_exp_lines.tax_amount%TYPE  := NULL; -- 販売手数料消費税額
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 販手条件情報カーソル定義
    CURSOR contract_mst_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE      -- 顧客コード
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE   -- 締め日
      ,iv_calculat_type IN xxcok_mst_bm_contract.calc_type%TYPE      -- 計算条件
      ,in_retail        IN xxcos_sales_exp_lines.dlv_unit_price%TYPE -- 売価
    )
    IS
      SELECT xmb.calc_type     AS calc_type     -- 計算条件
            ,xmb.selling_price AS selling_price -- 売価
            ,xmb.bm1_pct       AS bm1_pct       -- BM1率(%)
            ,xmb.bm1_amt       AS bm1_amt       -- BM1金額
            ,xmb.bm2_pct       AS bm2_pct       -- BM2率(%)
            ,xmb.bm2_amt       AS bm2_amt       -- BM2金額
            ,xmb.bm3_pct       AS bm3_pct       -- BM3率(%)
            ,xmb.bm3_amt       AS bm3_amt       -- BM3金額
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y：計算対象
      AND    xmb.calc_type        = iv_calculat_type
      AND    xmb.selling_price    = in_retail
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- 販手条件情報レコード定義
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ローカル例外
    --===============================
    contract_err_expt EXCEPTION; -- 販手条件エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.売価別条件判定
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code -- 顧客コード
      ,id_close_date    -- 締め日：今回締め日
      ,iv_calculat_type -- 計算条件
      ,in_retail_amount -- 売価：納品単価
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- 条件存在チェック
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- カーソルクローズ
      CLOSE contract_mst_cur;
      -- 販手条件エラー
      RAISE contract_err_expt;
    END IF;
    -- カーソルクローズ
    CLOSE contract_mst_cur;
    --
    -------------------------------------------------
    -- 2.売価別条件計算
    -------------------------------------------------
    -- 契約者仕入先判定
    IF ( iv_bm_type = cv_bm1_type ) THEN
      -- 計算方法（率・金額）判定
      IF ( contract_mst_rec.bm1_pct IS NOT NULL ) THEN
        -- 割戻率退避
        ln_bm_pct := NVL( contract_mst_rec.bm1_pct,cn_zero );
        -- 販売手数料＝販売実績情報.売上金額×BM1率（%）
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm1_pct,cn_zero ) / 100 ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- 割戻額退避
        ln_bm_amt := NVL( contract_mst_rec.bm1_amt,cn_zero );
        -- 販売手数料＝販売実績情報.納品数量×BM1金額
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm1_amt,cn_zero ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- 紹介者BM支払仕入先１判定
    ELSIF ( iv_bm_type = cv_bm2_type ) THEN
      -- 計算方法（率・金額）判定
      IF ( contract_mst_rec.bm2_pct IS NOT NULL ) THEN
        -- 割戻率退避
        ln_bm_pct := NVL( contract_mst_rec.bm2_pct,cn_zero );
        -- 販売手数料＝販売実績情報.売上金額×BM2率（%）
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm2_pct,cn_zero ) / 100 ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- 割戻額退避
        ln_bm_amt := NVL( contract_mst_rec.bm2_amt,cn_zero );
        -- 販売手数料＝販売実績情報.納品数量×BM2金額
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm2_amt,cn_zero ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- 紹介者BM支払仕入先３判定
    ELSIF ( iv_bm_type = cv_bm3_type ) THEN
      -- 計算方法（率・金額）判定
      IF ( contract_mst_rec.bm3_pct IS NOT NULL ) THEN
        -- 割戻率退避
        ln_bm_pct := NVL( contract_mst_rec.bm3_pct,cn_zero );
        -- 販売手数料＝販売実績情報.売上金額×BM3率（%）
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm3_pct,cn_zero ) / 100 ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- 割戻額退避
        ln_bm_amt := NVL( contract_mst_rec.bm3_amt,cn_zero );
        -- 販売手数料＝販売実績情報.納品数量×BM3金額
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm3_amt,cn_zero ) );
        -- 販売手数料税抜き＝販売手数料÷(1＋(100/販売実績情報.消費税率))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- 販売手数料消費税額＝販売手数料－販売手数料税抜き
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    END IF;
    -------------------------------------------------
    -- 3.戻り値設定
    -------------------------------------------------
    on_bm_pct        := ln_bm_pct;        -- 割戻率
    on_bm_amt        := ln_bm_amt;        -- 割戻額
    on_bm_amount     := ln_bm_amount;     -- 販売手数料
    on_bm_amount_tax := ln_bm_amount_tax; -- 販売手数料消費税額
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 販手条件エラー例外ハンドラ
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract10_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_active_vendor_info
   * Description      : 支払先データの取得(A-9,A-27)
   ***********************************************************************************/
  PROCEDURE get_active_vendor_info(
     ov_errbuf        OUT VARCHAR2                                          -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                                          -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                                          -- ユーザー・エラーメッセージ
    ,iv_vendor_type   IN  VARCHAR2                                          -- ベンダー区分
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE              -- 顧客コード
    ,id_pay_work_date IN  xxcok_cond_bm_support.expect_payment_date%TYPE    -- 支払予定日
    ,iv_vendor_code1  IN  xxcmm_cust_accounts.contractor_supplier_code%TYPE -- 契約者仕入先コード
    ,iv_vendor_code2  IN  xxcmm_cust_accounts.bm_pay_supplier_code1%TYPE    -- 紹介者BM支払仕入先コード１
    ,iv_vendor_code3  IN  xxcmm_cust_accounts.bm_pay_supplier_code2%TYPE    -- 紹介者BM支払仕入先コード２
    ,in_elc_cnt       IN  NUMBER                                            -- 電気料計算条件有無
    ,ot_bm_support    OUT g_bm_support_ttype                                -- 支払先情報
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_active_vendor_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000);   -- エラーメッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000);   -- メッセージ
    lb_retcode  BOOLEAN;          -- APIリターン・メッセージ用
    ln_cnt      PLS_INTEGER := 0; -- カウンタ
    ln_vend_cnt PLS_INTEGER := 0; -- 仕入先カウンタ
    ln_pay_cnt  PLS_INTEGER := 0; -- 支払先カウンタ
    -- 支払先テーブル定義
    lt_vendor_chk g_vendor_ttype;     -- 支払先チェック
    lt_bm_support g_bm_support_ttype; -- 支払先情報
    -- 仕入先情報退避
    lv_vendor_code1 po_vendors.segment1%TYPE := NULL; -- 仕入先コード１
    lv_vendor_code2 po_vendors.segment1%TYPE := NULL; -- 仕入先コード２
    lv_vendor_code3 po_vendors.segment1%TYPE := NULL; -- 仕入先コード３
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 支払先情報カーソル定義
    CURSOR vendor_info_cur(
       iv_vendor_code   IN po_vendors.segment1%TYPE                       -- 仕入先コード
      ,id_pay_work_date IN xxcok_cond_bm_support.expect_payment_date%TYPE -- 締め日
    )
    IS
      SELECT pvd.segment1         AS vendor_code      -- 仕入先コード
            ,pvs.vendor_site_code AS vendor_site_code -- 仕入先サイトコード
      FROM   po_vendors          pvd -- 仕入先マスタ
            ,po_vendor_sites_all pvs -- 仕入先サイトマスタ
      WHERE  pvd.segment1     = iv_vendor_code
      AND    pvd.enabled_flag = cv_yes -- Y：有効
      AND    pvd.vendor_id    = pvs.vendor_id
      AND    pvs.attribute4   IN ( cv_bm_pay1_type
                                  ,cv_bm_pay2_type
                                  ,cv_bm_pay3_type
                                  ,cv_bm_pay4_type )
      AND    NVL( pvs.inactive_date,id_pay_work_date ) >= id_pay_work_date
      AND    id_pay_work_date BETWEEN NVL( pvd.start_date_active,id_pay_work_date )
                              AND     NVL( pvd.end_date_active,id_pay_work_date );
    --===============================
    -- ローカル例外
    --===============================
    contract_err_expt EXCEPTION; -- 販手条件エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -- 引数退避
    lv_vendor_code1 := iv_vendor_code1; -- 仕入先１退避
    lv_vendor_code2 := iv_vendor_code2; -- 仕入先２退避
    lv_vendor_code3 := iv_vendor_code3; -- 仕入先３退避
    -- テーブル定義初期化
    lt_vendor_chk.DELETE;
    lt_bm_support.DELETE;
    -- BM1退避
    lt_vendor_chk( cn_bm1_set ).bm_type := cv_bm1_type;
    -- 契約者仕入先コード退避
    lt_vendor_chk( cn_bm1_set ).vendor_code := lv_vendor_code1;
    -- BM2退避
    lt_vendor_chk( cn_bm2_set ).bm_type := cv_bm2_type;
    -- 紹介者BM支払仕入先コード１退避
    lt_vendor_chk( cn_bm2_set ).vendor_code := lv_vendor_code2;
    -- BM3退避
    lt_vendor_chk( cn_bm3_set ).bm_type := cv_bm3_type;
    -- 紹介者BM支払仕入先コード２退避
    lt_vendor_chk( cn_bm3_set ).vendor_code := lv_vendor_code3;
    -------------------------------------------------
    -- 1.フルベンダー支払先取得
    -------------------------------------------------
    IF ( iv_vendor_type = cv_vendor_type1 ) THEN
      -------------------------------------------------
      -- 支払先情報チェックループ
      -------------------------------------------------
      << vendor_chk_all_loop >>
      FOR ln_vend_cnt IN lt_vendor_chk.FIRST..lt_vendor_chk.LAST LOOP
        -- 支払先情報取得
        << payment_chk_all_loop >>
        FOR vendor_info_rec IN vendor_info_cur(
           lt_vendor_chk( ln_vend_cnt ).vendor_code -- 仕入先コード：BM1～BM3
          ,id_pay_work_date                         -- 支払予定日
          )
        LOOP
          -- 支払区分：BM1～BM3
          lt_bm_support( ln_pay_cnt ).bm_type := lt_vendor_chk( ln_vend_cnt ).bm_type;
          -- 仕入先コード
          lt_bm_support( ln_pay_cnt ).supplier_code := vendor_info_rec.vendor_code;
          -- 仕入先サイトコード
          lt_bm_support( ln_pay_cnt ).supplier_site_code := vendor_info_rec.vendor_site_code;
          -- BM1の仕入先情報を退避する
          IF ( lt_bm_support( ln_pay_cnt ).bm_type = cv_bm1_type ) THEN
            -- BM1仕入先コード
            gv_bm1_vendor := lt_bm_support( ln_pay_cnt ).supplier_code;
            -- BM1仕入先サイトコード
            gv_bm1_vendor_s := lt_bm_support( ln_pay_cnt ).supplier_site_code;
          END IF;
          -- インクリメント
          ln_pay_cnt := ln_pay_cnt + cn_one;
        END LOOP payment_chk_all_loop;
      END LOOP vendor_chk_all_loop;
    -------------------------------------------------
    -- 2.フルベンダー（消化）支払先取得
    -------------------------------------------------
    ELSIF ( iv_vendor_type = cv_vendor_type2 ) THEN
      -------------------------------------------------
      -- ベンダーチェック
      -------------------------------------------------
      << vendor_chk_point_loop >>
      FOR ln_vend_cnt IN lt_vendor_chk.FIRST..lt_vendor_chk.LAST LOOP
        -- 契約者仕入先コードチェック
        IF ( lv_vendor_code1 IS NOT NULL ) THEN
          -- BM1退避
          lt_bm_support( ln_pay_cnt ).bm_type := cv_bm1_type;
          -- 契約者仕入先コード退避
          lt_bm_support( ln_pay_cnt ).supplier_code := lv_vendor_code1;
          -- 仕入先サイトコード
          lt_bm_support( ln_pay_cnt ).supplier_site_code := lv_vendor_code1;
          -- BM1仕入先コード
          gv_bm1_vendor := lv_vendor_code1;
          -- BM1仕入先サイトコード
          gv_bm1_vendor_s := lv_vendor_code1;
          -- インクリメント
          ln_pay_cnt := ln_pay_cnt + cn_one;
          -- 仕入先クリア
          lv_vendor_code1 := NULL;
        -- 紹介者BM支払仕入先コード１チェック
        ELSIF ( lv_vendor_code2 IS NOT NULL ) THEN
          -- BM2退避
          lt_bm_support( ln_pay_cnt ).bm_type := cv_bm2_type;
          -- 紹介者BM支払仕入先コード１退避
          lt_bm_support( ln_pay_cnt ).supplier_code := lv_vendor_code2;
          -- 仕入先サイトコード
          lt_bm_support( ln_pay_cnt ).supplier_site_code := lv_vendor_code2;
          -- インクリメント
          ln_pay_cnt := ln_pay_cnt + cn_one;
          -- 仕入先クリア
          lv_vendor_code2 := NULL;
        -- 紹介者BM支払仕入先コード２チェック
        ELSIF ( lv_vendor_code3 IS NOT NULL ) THEN
          -- BM2退避
          lt_bm_support( ln_pay_cnt ).bm_type := cv_bm3_type;
          -- 紹介者BM支払仕入先コード２退避
          lt_bm_support( ln_pay_cnt ).supplier_code := lv_vendor_code3;
          -- 仕入先サイトコード
          lt_bm_support( ln_pay_cnt ).supplier_site_code := lv_vendor_code3;
          -- インクリメント
          ln_pay_cnt := ln_pay_cnt + cn_one;
          -- 仕入先クリア
          lv_vendor_code3 := NULL;
        END IF;
      END LOOP vendor_chk_point_loop;
    END IF;
    -------------------------------------------------
    -- 3.電気料条件設定
    -------------------------------------------------
    -- 電気料計算有りの場合は配列を拡張
    IF ( ln_pay_cnt <> cn_zero ) AND
       ( in_elc_cnt <> cn_zero ) THEN
      -- 支払区分：EN1
      lt_bm_support( lt_bm_support.LAST + 1 ).bm_type := cv_en1_type;
      -- 仕入先ダミーコード
      lt_bm_support( lt_bm_support.LAST + 1 ).supplier_code := gv_bm1_vendor;
      -- 仕入先サイトダミーコード
      lt_bm_support( lt_bm_support.LAST + 1 ).supplier_site_code := gv_bm1_vendor_s;
    END IF;
    -------------------------------------------------
    -- 4.支払先チェック
    -------------------------------------------------
    IF ( ln_pay_cnt = cn_zero ) OR
       ( gv_bm1_vendor IS NULL ) THEN
      -- 支払先情報取得エラー
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_10427
                      ,iv_token_name1  => cv_tkn_vend_code
                      ,iv_token_value1 => iv_customer_code
                      ,iv_token_name2  => cv_tkn_pay_date
                      ,iv_token_value2 => id_pay_work_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_warn;
    END IF;
    -------------------------------------------------
    -- 5.戻り値設定
    -------------------------------------------------
    ot_bm_support := lt_bm_support; -- 支払先情報
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 販手条件エラー例外ハンドラ
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END get_active_vendor_info;
  --
  /**********************************************************************************
   * Procedure Name   : del_bm_contract_err_info
   * Description      : 販手条件エラーデータの削除(A-6,A-24)
   ***********************************************************************************/
  PROCEDURE del_bm_contract_err_info(
     ov_errbuf        OUT VARCHAR2                             -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                             -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                             -- ユーザー・エラーメッセージ
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE -- 顧客コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_bm_contract_err_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 販手条件エラーテーブルロック
    CURSOR bm_contract_err_del_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE -- 顧客コード
    )
    IS
      SELECT xbe.cust_code AS bm_contract_err -- 販手条件
      FROM   xxcok_bm_contract_err xbe -- 販手条件エラーテーブル
      WHERE  xbe.cust_code = iv_customer_code
      FOR UPDATE NOWAIT;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.販手条件エラーデータ削除ロック処理
    -------------------------------------------------
    -- ロック処理
    OPEN bm_contract_err_del_cur(
       iv_customer_code -- 顧客コード
    );
    CLOSE bm_contract_err_del_cur;
    -------------------------------------------------
    -- 2.販手条件エラーデータ削除処理
    -------------------------------------------------
    BEGIN
      DELETE FROM xxcok_bm_contract_err xbe
      WHERE xbe.cust_code = iv_customer_code;
    EXCEPTION
      ----------------------------------------------------------
      -- 販手条件エラーデータ削除例外
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10400
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => iv_customer_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- 出力区分
                        ,iv_message  => lv_out_msg      -- メッセージ
                        ,in_new_line => cn_zero         -- 改行
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ロック例外ハンドラ
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00080
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END del_bm_contract_err_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_bm_support_add_info
   * Description      : 販手販協計算付加情報の取得(A-5,A-23,A-41)
   ***********************************************************************************/
  PROCEDURE get_bm_support_add_info(
     ov_errbuf        OUT VARCHAR2                                       -- エラーメッセージ
    ,ov_retcode       OUT VARCHAR2                                       -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2                                       -- ユーザー・エラーメッセージ
    ,iv_vendor_type   IN  VARCHAR2                                       -- ベンダー区分
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE           -- 顧客コード
    ,id_pay_date      IN  xxcok_cond_bm_support.expect_payment_date%TYPE -- 支払日
    ,od_pay_work_date OUT xxcok_cond_bm_support.expect_payment_date%TYPE -- 支払予定日
    ,ov_period_year   OUT gl_period_statuses.period_year%TYPE            -- 会計年度
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_bm_support_add_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    -- 付加情報退避
    ld_pay_work_date   xxcok_cond_bm_support.expect_payment_date%TYPE := NULL; -- 営業日を考慮した支払日
    lv_appl_short_name fnd_application.application_short_name%TYPE    := NULL; -- アプリケーション短縮名
    lv_period_year     gl_period_statuses.period_year%TYPE            := NULL; -- 会計年度
    lv_period_name     gl_period_statuses.period_name%TYPE            := NULL; -- 会計期間名
    lv_closing_status  gl_period_statuses.closing_status%TYPE         := NULL; -- 会計カレンダステータス
    --===============================
    -- ローカル例外
    --===============================
    work_date_err_expt EXCEPTION; -- 営業日取得エラー
    calendar_err_expt  EXCEPTION; -- 会計カレンダ情報取得エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.支払予定日取得（共通）
    -------------------------------------------------
    BEGIN
      -- 営業日取得
      ld_pay_work_date := xxcok_common_pkg.get_operating_day_f(
         id_proc_date => id_pay_date -- 処理日：今回支払日
        ,in_days      => cn_zero     -- 日数：条件別販手販協計算処理期間(From)
        ,in_proc_type => cn_one      -- 処理区分：前
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- 営業日取得エラー
        RAISE work_date_err_expt;
    END;
    -------------------------------------------------
    -- 2.会計年度取得（共通）
    -------------------------------------------------
    IF ( iv_vendor_type = cv_vendor_type1 ) THEN
      lv_appl_short_name := cv_ap_type_sqlgl; -- アプリケーション短縮名：SQLGL
    ELSE
      lv_appl_short_name := cv_ap_type_ar;    -- アプリケーション短縮名：AR
    END IF;
    -- 会計カレンダ情報取得
    xxcok_common_pkg.get_acctg_calendar_p(
       ov_errbuf                 => lv_errbuf          -- エラーメッセージ
      ,ov_retcode                => lv_retcode         -- リターン・コード
      ,ov_errmsg                 => lv_errmsg          -- ユーザー・エラーメッセージ
      ,in_set_of_books_id        => gn_pro_books_id    -- 会計帳簿ID
      ,iv_application_short_name => lv_appl_short_name -- アプリケーション短縮名
      ,id_object_date            => ld_pay_work_date   -- 対象日
      ,on_period_year            => lv_period_year     -- 会計年度
      ,ov_period_name            => lv_period_name     -- 会計期間名
      ,ov_closing_status         => lv_closing_status  -- ステータス
    );
    -- ステータスエラー判定
    IF ( lv_retcode = cv_status_error ) OR
       ( lv_closing_status <> cv_cal_op_status ) THEN
      RAISE calendar_err_expt;
    END IF;
    -------------------------------------------------
    -- 3.戻り値設定
    -------------------------------------------------
    od_pay_work_date := ld_pay_work_date; -- 支払予定日
    ov_period_year   := lv_period_year;   -- 会計年度
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 営業日取得例外ハンドラ
    ----------------------------------------------------------
    WHEN work_date_err_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00027
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- 会計カレンダ情報取得例外ハンドラ
    ----------------------------------------------------------
    WHEN calendar_err_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00011
                      ,iv_token_name1  => cv_tkn_proc_date
                      ,iv_token_value1 => TO_CHAR( ld_pay_work_date,cv_format1 )
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END get_bm_support_add_info;
  --
  /**********************************************************************************
   * Procedure Name   : chk_customer_info
   * Description      : 処理対象顧客データの判断(A-4,A-22,A-40)
   ***********************************************************************************/
  PROCEDURE chk_customer_info(
     ov_errbuf         OUT VARCHAR2                             -- エラーメッセージ
    ,ov_retcode        OUT VARCHAR2                             -- リターン・コード
    ,ov_errmsg         OUT VARCHAR2                             -- ユーザー・エラーメッセージ
    ,iv_vendor_type    IN  VARCHAR2                             -- ベンダー区分
    ,iv_customer_code  IN  hz_cust_accounts.account_number%TYPE -- 顧客コード
    ,ov_bill_cust_code OUT hz_cust_accounts.account_number%TYPE -- 請求先顧客コード
    ,ot_many_term      OUT g_many_term_ttype                    -- 複数支払条件
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_customer_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    -- カウンタ
    ln_term_cnt  PLS_INTEGER := 0; -- 支払条件カウンタ
    ln_close_cnt PLS_INTEGER := 0; -- 締め日カウンタ
    ln_match_cnt PLS_INTEGER := 0; -- 締め日ソート用カウンタ
    -- 処理結果
    ld_pre_month1 DATE   := NULL; -- 前月処理日退避
    ld_pre_month2 DATE   := NULL; -- 前々月処理日退避
    ln_bill_cycle NUMBER := NULL; -- 請求書発行サイクル退避
    -- 支払情報テーブル定義
    lt_term_name  g_term_name_ttype;  -- 支払条件退避
    lt_close_date g_close_date_ttype; -- 締め日情報退避
    -- 処理結果タイプ定義
    lv_bill_cust_code hz_cust_accounts.account_number%TYPE           := NULL; -- 請求先顧客コード
    ld_close_date     xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- 締め日
    ld_pay_date       xxcok_cond_bm_support.expect_payment_date%TYPE := NULL; -- 支払日
    ld_to_close_date  xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- 今回締め日
    ld_to_pay_date    xxcok_cond_bm_support.expect_payment_date%TYPE := NULL; -- 今回支払日
    ld_fm_close_date  xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- 前回締め日
    ld_fm_pay_date    xxcok_cond_bm_support.expect_payment_date%TYPE := NULL; -- 前回支払日
    ld_stert_date     xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- 販手販協計算開始日
    ld_end_date       xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- 販手販協計算終了日
    lv_term_name1     ra_terms_tl.name%TYPE                          := NULL; -- 支払条件1
    lv_term_name2     ra_terms_tl.name%TYPE                          := NULL; -- 支払条件2
    lv_term_name3     ra_terms_tl.name%TYPE                          := NULL; -- 支払条件3
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 契約情報カーソル定義
    CURSOR contract_info_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE -- 顧客コード
    )
    IS
      SELECT xcm.install_account_number AS in_account_number -- 設置先顧客コード
            ,xcm.close_day_code         AS close_day_code      -- 締め日
            ,xcm.transfer_day_code      AS transfer_day_code   -- 振込日
            ,xcm.transfer_month_code    AS transfer_month_code -- 振込月
      FROM   xxcso_contract_managements xcm
            ,( SELECT MAX( contract_number ) AS contract_number   -- 契約番号
                     ,install_account_id     AS in_account_number -- 設置先顧客ID
               FROM   xxcso_contract_managements xcm -- 契約管理テーブル
                     ,hz_cust_accounts           hca -- 顧客マスタ
                     ,xxcmm_cust_accounts        xca -- 顧客マスタアドオン
               WHERE  hca.account_number      = iv_customer_code
               AND    hca.customer_class_code = cv_cust_type1 -- 顧客区分：顧客
               AND    hca.cust_account_id     = xca.customer_id
               AND    xca.business_low_type   = cv_bus_type1 -- 業態小分類区分：フルベンダー
               AND    hca.cust_account_id     = xcm.install_account_id
               AND    xcm.status              = cv_one -- 確定済
               GROUP BY install_account_id ) ina
      WHERE  xcm.contract_number    = ina.contract_number
      AND    xcm.install_account_id = ina.in_account_number
      AND    xcm.status             = cv_one -- 確定済
      AND    ROWNUM                 = 1;
    -- 契約情報レコード定義
    contract_info_rec contract_info_cur%ROWTYPE;
    -- 請求先顧客情報カーソル定義
    CURSOR bill_cust_info_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE -- 顧客コード
      ,in_org_id        IN hz_cust_acct_sites_all.org_id%TYPE   -- 組織ID
      ,iv_language      IN ra_terms_tl.language%TYPE            -- 言語
    )
    IS
      SELECT hca.account_number AS customer_code -- 顧客コード
            ,rt1.name           AS term_name1    -- 支払条件１
            ,rt2.name           AS term_name2    -- 支払条件２
            ,rt3.name           AS term_name3    -- 支払条件３
            ,hcu.attribute8     AS bill_cycle    -- 請求書発行サイクル
      FROM   hz_cust_accounts       hca -- 顧客マスタ
            ,hz_cust_acct_sites_all hcs -- 顧客サイトマスタ
            ,hz_cust_site_uses_all  hcu -- 顧客サイト使用目的
            ,ra_terms_tl            rt1 -- 支払条件マスタ１
            ,ra_terms_tl            rt2 -- 支払条件マスタ２
            ,ra_terms_tl            rt3 -- 支払条件マスタ３
      WHERE  hca.account_number    = iv_customer_code
      AND    hca.cust_account_id   = hcs.cust_account_id
      AND    hcs.org_id            = in_org_id
      AND    hcs.cust_acct_site_id = hcu.cust_acct_site_id
      AND    hcu.org_id            = in_org_id
      AND    hcu.site_use_code     = cv_bill_site_use -- 請求先
      AND    hcu.payment_term_id   = rt1.term_id
      AND    rt1.language          = iv_language
      AND    hcu.attribute2        = rt2.term_id(+)
      AND    rt2.language(+)       = iv_language
      AND    hcu.attribute3        = rt3.term_id(+)
      AND    rt3.language(+)       = iv_language
      AND    ROWNUM                = 1;
    -- 請求先顧客情報レコード定義
    bill_cust_info_rec bill_cust_info_cur%ROWTYPE;
    --===============================
    -- ローカル例外
    --===============================
    contract_err_expt   EXCEPTION; -- 契約情報取得エラー
    bill_cust_err_expt  EXCEPTION; -- 請求先顧客取得エラー
    close_date_err_expt EXCEPTION; -- 締め・支払日取得エラー
    work_date_err_expt  EXCEPTION; -- 営業日取得エラー
    customer_err_expt   EXCEPTION; -- 処理対象外顧客エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -- 前月の処理日を取得
    ld_pre_month1 := ADD_MONTHS( gd_proc_date , - cn_one );
    -- 前々月の処理日を取得
    ld_pre_month2 := ADD_MONTHS( gd_proc_date , - cn_two );
    -------------------------------------------------
    -- 1.フルベンダー契約情報取得
    -------------------------------------------------
    IF ( iv_vendor_type = cv_vendor_type1 ) THEN
      -------------------------------------------------
      -- 契約情報取得
      -------------------------------------------------
      OPEN contract_info_cur(
         iv_customer_code -- 顧客コード
      );
      FETCH contract_info_cur INTO contract_info_rec;
      -- 契約情報チェック
      IF ( contract_info_cur%NOTFOUND ) THEN
        RAISE contract_err_expt;
      END IF;
      -- 当月振込月判定
      IF ( contract_info_rec.transfer_month_code = cv_month_type1 ) THEN
        -- 当月支払条件生成
        lt_term_name( cn_bm1_set ) :=
             TO_CHAR( TO_NUMBER( contract_info_rec.close_day_code ) ,'FM00' )    || '_' ||
             TO_CHAR( TO_NUMBER( contract_info_rec.transfer_day_code ) ,'FM00' ) || '_' ||
             cv_site_type1;
      -- 翌月振込月判定
      ELSIF ( contract_info_rec.transfer_month_code = cv_month_type2 ) THEN
        -- 翌月支払条件生成
        lt_term_name( cn_bm1_set ) :=
             TO_CHAR( TO_NUMBER( contract_info_rec.close_day_code ) ,'FM00' )    || '_' ||
             TO_CHAR( TO_NUMBER( contract_info_rec.transfer_day_code ) ,'FM00' ) || '_' ||
             cv_site_type2;
      -- 振込月取得判定
      ELSIF ( contract_info_rec.transfer_month_code IS NULL ) OR
            ( contract_info_rec.transfer_month_code <> cv_month_type1 ) OR
            ( contract_info_rec.transfer_month_code <> cv_month_type2 ) THEN
        -- 契約情報取得エラー
        RAISE contract_err_expt;
      END IF;
    -------------------------------------------------
    -- 2.フルベンダー(消化)・一般契約情報取得
    -------------------------------------------------
    ELSIF ( iv_vendor_type = cv_vendor_type2 ) OR
          ( iv_vendor_type = cv_vendor_type3 ) THEN
      -------------------------------------------------
      -- 請求先顧客コード取得
      -------------------------------------------------
      lv_bill_cust_code := xxcok_common_pkg.get_bill_to_cust_code_f(
         iv_ship_to_cust_code => iv_customer_code -- 納品先顧客コード
      );
      -- 請求先顧客コード取得判定
      IF ( lv_bill_cust_code IS NULL ) THEN
        RAISE bill_cust_err_expt;
      END IF;
      -------------------------------------------------
      -- 請求先顧客情報取得
      -------------------------------------------------
      OPEN bill_cust_info_cur(
         lv_bill_cust_code -- 請求先顧客コード
        ,gn_pro_org_id     -- 組織ID
        ,gv_language       -- 言語
      );
      FETCH bill_cust_info_cur INTO bill_cust_info_rec;
      -- 請求先顧客情報チェック
      IF ( bill_cust_info_cur%NOTFOUND ) THEN
        RAISE bill_cust_err_expt;
      END IF;
      -- 支払条件退避
      lv_term_name1 := bill_cust_info_rec.term_name1;
      lv_term_name2 := bill_cust_info_rec.term_name2;
      lv_term_name3 := bill_cust_info_rec.term_name3;
      -- 請求書発行サイクル退避
      ln_bill_cycle := TO_NUMBER( bill_cust_info_rec.bill_cycle );
      -------------------------------------------------
      -- 有効支払条件チェック
      -------------------------------------------------
      << vendor_chk_point_loop >>
      FOR ln_term_cnt IN cn_bm1_set..cn_bm3_set LOOP
        -- 契約者支払条件チェック
        IF ( lv_term_name1 IS NOT NULL ) THEN
          -- BM1退避
          lt_term_name( ln_match_cnt ) := lv_term_name1;
          -- 支払条件クリア
          lv_term_name1 := NULL;
          -- 配列インクリメント
          ln_match_cnt := ln_match_cnt + cn_one;
        -- 紹介者BM２支払条件チェック
        ELSIF ( lv_term_name2 IS NOT NULL ) THEN
          -- BM2退避
          lt_term_name( ln_match_cnt ) := lv_term_name2;
          -- 支払条件クリア
          lv_term_name2 := NULL;
          -- 配列インクリメント
          ln_match_cnt := ln_match_cnt + cn_one;
        -- 紹介者BM３支払条件チェック
        ELSIF ( lv_term_name3 IS NOT NULL ) THEN
          -- BM3退避
          lt_term_name( ln_match_cnt ) := lv_term_name3;
          -- 支払条件クリア
          lv_term_name3 := NULL;
          -- 配列インクリメント
          ln_match_cnt := ln_match_cnt + cn_one;
        END IF;
      END LOOP vendor_chk_point_loop;
    END IF;
    -------------------------------------------------
    -- 3.支払条件変換処理
    -------------------------------------------------
    << term_change_loop >>
    FOR ln_term_cnt IN lt_term_name.FIRST..lt_term_name.LAST LOOP
      -------------------------------------------------
      -- 今回締め・支払日取得
      -------------------------------------------------
      BEGIN
        -- 締め・支払日取得
        xxcok_common_pkg.get_close_date_p(
           ov_errbuf     => lv_errbuf                                -- エラーメッセージ
          ,ov_retcode    => lv_retcode                               -- リターン・コード
          ,ov_errmsg     => lv_errmsg                                -- ユーザー・エラーメッセージ
          ,id_proc_date  => gd_proc_date                             -- 処理日
          ,iv_pay_cond   => lt_term_name( ln_term_cnt )              -- 支払条件
          ,od_close_date => lt_close_date( ln_close_cnt ).close_date -- 締め日
          ,od_pay_date   => lt_close_date( ln_close_cnt ).pay_date   -- 支払日
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- 締め・支払日取得エラー
          RAISE close_date_err_expt;
      END;
      -- 支払条件退避
      lt_close_date( ln_close_cnt ).term_name := lt_term_name( ln_term_cnt );
      -- インクリメント
      ln_close_cnt := ln_close_cnt + cn_one;
      -------------------------------------------------
      -- 前回締め・支払日取得
      -------------------------------------------------
      BEGIN
        -- 締め・支払日取得
        xxcok_common_pkg.get_close_date_p(
           ov_errbuf     => lv_errbuf                                -- エラーメッセージ
          ,ov_retcode    => lv_retcode                               -- リターン・コード
          ,ov_errmsg     => lv_errmsg                                -- ユーザー・エラーメッセージ
          ,id_proc_date  => ld_pre_month1                            -- 処理日
          ,iv_pay_cond   => lt_term_name( ln_term_cnt )              -- 支払条件
          ,od_close_date => lt_close_date( ln_close_cnt ).close_date -- 締め日
          ,od_pay_date   => lt_close_date( ln_close_cnt ).pay_date   -- 支払日
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- 締め・支払日取得エラー
          RAISE close_date_err_expt;
      END;
      -- 支払条件退避
      lt_close_date( ln_close_cnt ).term_name := lt_term_name( ln_term_cnt );
      -- インクリメント
      ln_close_cnt := ln_close_cnt + cn_one;
      -------------------------------------------------
      -- 前々回締め・支払日取得
      -------------------------------------------------
      BEGIN
        -- 締め・支払日取得
        xxcok_common_pkg.get_close_date_p(
           ov_errbuf     => lv_errbuf                                -- エラーメッセージ
          ,ov_retcode    => lv_retcode                               -- リターン・コード
          ,ov_errmsg     => lv_errmsg                                -- ユーザー・エラーメッセージ
          ,id_proc_date  => ld_pre_month2                            -- 処理日
          ,iv_pay_cond   => lt_term_name( ln_term_cnt )              -- 支払条件
          ,od_close_date => lt_close_date( ln_close_cnt ).close_date -- 締め日
          ,od_pay_date   => lt_close_date( ln_close_cnt ).pay_date   -- 支払日
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- 締め・支払日取得エラー
          RAISE close_date_err_expt;
      END;
      -- 支払条件退避
      lt_close_date( ln_close_cnt ).term_name := lt_term_name( ln_term_cnt );
      -- インクリメント
      ln_close_cnt := ln_close_cnt + cn_one;
    END LOOP term_change_loop;
    -------------------------------------------------
    -- 4.販手販協計算算出
    -------------------------------------------------
    << close_change_loop >>
    FOR ln_close_cnt IN lt_close_date.FIRST..lt_close_date.LAST LOOP
      -------------------------------------------------
      -- 販手販協計算開始日取得
      -------------------------------------------------
      BEGIN
        -- 営業日取得
        lt_close_date( ln_close_cnt ).start_date := xxcok_common_pkg.get_operating_day_f(
           id_proc_date => lt_close_date( ln_close_cnt ).close_date -- 処理日：締め日
          ,in_days      => gn_pro_bm_sup_fm                         -- 日数：条件別販手販協計算処理期間(From)
          ,in_proc_type => cn_one                                   -- 処理区分：前
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- 営業日取得エラー
          RAISE work_date_err_expt;
      END;
      -------------------------------------------------
      -- 販手販協計算終了日取得
      -------------------------------------------------
      BEGIN
        -------------------------------------------------
        -- フルベンダー販手販協計算終了日取得
        -------------------------------------------------
        IF ( iv_vendor_type = cv_vendor_type1 ) THEN
          -- 営業日取得
          lt_close_date( ln_close_cnt ).end_date := xxcok_common_pkg.get_operating_day_f(
             id_proc_date => lt_close_date( ln_close_cnt ).close_date -- 処理日：締め日
            ,in_days      => gn_pro_bm_sup_to                         -- 日数：条件別販手販協計算処理期間(To)
            ,in_proc_type => cn_one                                   -- 処理区分：前
          );
        --------------------------------------------------------
        -- フルベンダー(消化)・一般販手販協計算終了日取得
        --------------------------------------------------------
        ELSIF ( iv_vendor_type = cv_vendor_type2 ) OR
              ( iv_vendor_type = cv_vendor_type3 ) THEN
          -- 営業日取得
          lt_close_date( ln_close_cnt ).end_date := xxcok_common_pkg.get_operating_day_f(
             id_proc_date => lt_close_date( ln_close_cnt ).close_date -- 処理日：締め日
            ,in_days      => ln_bill_cycle                            -- 日数：請求書発行サイクル
            ,in_proc_type => cn_one                                   -- 処理区分：前
          );
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          -- 営業日取得エラー
          RAISE work_date_err_expt;
      END;
      ---------------------------------------------------------
      -- 販手販協計算開始日≦業務日付≦販手販協計算終了日判定
      ---------------------------------------------------------
      IF ( lt_close_date( ln_close_cnt ).start_date <= gd_proc_date ) AND
         ( lt_close_date( ln_close_cnt ).end_date >= gd_proc_date ) THEN
        -- 今回締め・今回支払日・支払条件退避
        ot_many_term( ln_term_cnt ).to_close_date := lt_close_date( ln_close_cnt ).close_date;
        ot_many_term( ln_term_cnt ).to_pay_date   := lt_close_date( ln_close_cnt ).pay_date;
        ot_many_term( ln_term_cnt ).to_term_name  := lt_close_date( ln_close_cnt ).term_name;
        ot_many_term( ln_term_cnt ).end_date      := lt_close_date( ln_close_cnt ).end_date;
        -- 支払条件インクリメント
        ln_term_cnt := ln_term_cnt + cn_one;
      END IF;
    END LOOP close_change_loop;
    -------------------------------------------------
    -- 5.処理対象顧客存在チェック
    -------------------------------------------------
    IF ( ot_many_term.COUNT = cn_zero ) THEN
      RAISE customer_err_expt;
    END IF;
    -------------------------------------------------
    -- 6.締め日クイックソート
    -------------------------------------------------
    << close_date_all_loop >>
    FOR ln_close_cnt IN lt_close_date.FIRST..lt_close_date.LAST LOOP
      << close_date_point_loop >>
      FOR ln_match_cnt IN lt_close_date.FIRST..lt_close_date.LAST LOOP
        -- 締め日大小判定
        IF ( lt_close_date( ln_close_cnt ).close_date < lt_close_date( ln_match_cnt ).close_date ) THEN
          -- レコード退避
          ld_stert_date := lt_close_date( ln_close_cnt ).start_date;
          ld_end_date   := lt_close_date( ln_close_cnt ).end_date;
          ld_close_date := lt_close_date( ln_close_cnt ).close_date;
          ld_pay_date   := lt_close_date( ln_close_cnt ).pay_date;
          lv_term_name1 := lt_close_date( ln_close_cnt ).term_name;
          -- 大データ置換
          lt_close_date( ln_close_cnt ).start_date := lt_close_date( ln_match_cnt ).start_date;
          lt_close_date( ln_close_cnt ).end_date   := lt_close_date( ln_match_cnt ).end_date;
          lt_close_date( ln_close_cnt ).close_date := lt_close_date( ln_match_cnt ).close_date;
          lt_close_date( ln_close_cnt ).pay_date   := lt_close_date( ln_match_cnt ).pay_date;
          lt_close_date( ln_close_cnt ).term_name  := lt_close_date( ln_match_cnt ).term_name;
          -- 小データ置換
          lt_close_date( ln_match_cnt ).start_date := ld_stert_date;
          lt_close_date( ln_match_cnt ).end_date   := ld_end_date;
          lt_close_date( ln_match_cnt ).close_date := ld_close_date;
          lt_close_date( ln_match_cnt ).pay_date   := ld_pay_date;
          lt_close_date( ln_match_cnt ).term_name  := lv_term_name1;
        END IF;
      END LOOP close_date_point_loop;
    END LOOP close_date_all_loop;
    -------------------------------------------------
    -- 7.前回締め支払日取得
    -------------------------------------------------
    << many_term_all_loop >>
    FOR ln_term_cnt IN ot_many_term.FIRST..ot_many_term.LAST LOOP
      << close_date_point_loop >>
      FOR ln_close_cnt IN lt_close_date.FIRST..lt_close_date.LAST LOOP
        -- 締め日一致判定
        IF ( ot_many_term( ln_term_cnt ).to_close_date = lt_close_date( ln_close_cnt ).close_date ) THEN
          -- １件前のレコード（前回締め日）退避
          ot_many_term( ln_term_cnt ).fm_close_date := lt_close_date( ln_close_cnt - cn_one ).close_date;
          ot_many_term( ln_term_cnt ).fm_pay_date   := lt_close_date( ln_close_cnt - cn_one ).pay_date;
          ot_many_term( ln_term_cnt ).fm_term_name  := lt_close_date( ln_close_cnt - cn_one ).term_name;
        END IF;
      END LOOP close_date_point_loop;
    END LOOP many_term_all_loop;
    -------------------------------------------------
    -- 8.支払条件クイックソート
    -------------------------------------------------
    << many_term_sort_all_loop >>
    FOR ln_close_cnt IN ot_many_term.FIRST..ot_many_term.LAST LOOP
      << many_term_sort_point_loop >>
      FOR ln_match_cnt IN ot_many_term.FIRST..ot_many_term.LAST LOOP
        -- 締め日大小判定
        IF ( ot_many_term( ln_close_cnt ).to_close_date < ot_many_term( ln_match_cnt ).to_close_date ) THEN
          -- レコード退避
          ld_to_close_date := ot_many_term( ln_close_cnt ).to_close_date;
          ld_to_pay_date   := ot_many_term( ln_close_cnt ).to_pay_date;
          lv_term_name1    := ot_many_term( ln_close_cnt ).to_term_name;
          ld_fm_close_date := ot_many_term( ln_close_cnt ).fm_close_date;
          ld_fm_pay_date   := ot_many_term( ln_close_cnt ).fm_pay_date;
          lv_term_name2    := ot_many_term( ln_close_cnt ).fm_term_name;
          ld_end_date      := ot_many_term( ln_close_cnt ).end_date;
          -- 大データ置換
          ot_many_term( ln_close_cnt ).to_close_date := ot_many_term( ln_match_cnt ).to_close_date;
          ot_many_term( ln_close_cnt ).to_pay_date   := ot_many_term( ln_match_cnt ).to_pay_date;
          ot_many_term( ln_close_cnt ).to_term_name  := ot_many_term( ln_match_cnt ).to_term_name;
          ot_many_term( ln_close_cnt ).fm_close_date := ot_many_term( ln_match_cnt ).fm_close_date;
          ot_many_term( ln_close_cnt ).fm_pay_date   := ot_many_term( ln_match_cnt ).fm_pay_date;
          ot_many_term( ln_close_cnt ).fm_term_name  := ot_many_term( ln_match_cnt ).fm_term_name;
          ot_many_term( ln_close_cnt ).end_date      := ot_many_term( ln_match_cnt ).end_date;
          -- 小データ置換
          ot_many_term( ln_match_cnt ).to_close_date := ld_to_close_date;
          ot_many_term( ln_match_cnt ).to_pay_date   := ld_to_pay_date;
          ot_many_term( ln_match_cnt ).to_term_name  := lv_term_name1;
          ot_many_term( ln_match_cnt ).fm_close_date := ld_fm_close_date;
          ot_many_term( ln_match_cnt ).fm_pay_date   := ld_fm_pay_date;
          ot_many_term( ln_match_cnt ).fm_term_name  := lv_term_name2;
          ot_many_term( ln_match_cnt ).end_date      := ld_end_date;
        END IF;
      END LOOP many_term_sort_point_loop;
    END LOOP many_term_sort_all_loop;
    -------------------------------------------------
    -- 9.戻り値設定
    -------------------------------------------------
    ov_bill_cust_code := lv_bill_cust_code; -- 請求先顧客コード
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 請求先顧客取得例外ハンドラ
    ----------------------------------------------------------
    WHEN bill_cust_err_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00079
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_customer_code
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- 契約情報取得例外ハンドラ
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_10399
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_customer_code
                    );
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- 締め・支払日取得例外ハンドラ
    ----------------------------------------------------------
    WHEN close_date_err_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00036
                    );
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- 営業日取得例外ハンドラ
    ----------------------------------------------------------
    WHEN work_date_err_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00027
                    );
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- 処理対象外顧客例外ハンドラ
    ----------------------------------------------------------
    WHEN customer_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_customer_err;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END chk_customer_info;
  --
  /**********************************************************************************
   * Procedure Name   : del_bm_support_info
   * Description      : 販手販協保持期間外データの削除(A-2)
   ***********************************************************************************/
  PROCEDURE del_bm_support_info(
     ov_errbuf  OUT VARCHAR2 -- エラーメッセージ
    ,ov_retcode OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラーメッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_bm_support_info'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- APIリターン・メッセージ用
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 条件別販手販協テーブルロック
    CURSOR bm_support_del_cur(
       in_proc_date IN DATE -- 業務日付
    )
    IS
      SELECT xbs.cond_bm_support_id AS bm_support_id -- 条件別販手販協ID
      FROM   xxcok_cond_bm_support xbs -- 条件別販手販協テーブル
      WHERE  xbs.closing_date < in_proc_date
      FOR UPDATE NOWAIT;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.販手販協保持期間外データ削除ロック処理
    -------------------------------------------------
    -- ロック処理
    OPEN bm_support_del_cur(
       gd_limit_date -- 販手販協保持期限日取得
    );
    CLOSE bm_support_del_cur;
    -------------------------------------------------
    -- 2.販手販協保持期間外データ削除処理
    -------------------------------------------------
    BEGIN
      DELETE FROM xxcok_cond_bm_support xbs
      WHERE xbs.closing_date < gd_limit_date;
    EXCEPTION
      ----------------------------------------------------------
      -- 販手販協保持期間外データ削除例外
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10398
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- 出力区分
                        ,iv_message  => lv_out_msg      -- メッセージ
                        ,in_new_line => cn_zero         -- 改行
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
    ----------------------------------------------------------
    -- ロック例外ハンドラ
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00051
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END del_bm_support_info;
  --
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
     ov_errbuf    OUT VARCHAR2 -- エラーメッセージ
    ,ov_retcode   OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg    OUT VARCHAR2 -- ユーザー・エラーメッセージ
    ,iv_proc_date IN  VARCHAR2 -- 業務日付
    ,iv_proc_type IN  VARCHAR2 -- 実行区分
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- メッセージ戻り値
    -- エラーメッセージ用
    lv_prof_err fnd_profile_options.profile_option_name%TYPE := NULL; -- プロファイル退避
    ln_user_err fnd_user.user_id%TYPE                        := NULL; -- ユーザID退避
    --===============================
    -- ローカル例外
    --===============================
    get_date_err_expt EXCEPTION; -- 業務処理日付取得エラー
    get_prof_err_expt EXCEPTION; -- プロファイル取得エラー
    get_dept_err_expt EXCEPTION; -- 所属部門取得エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -- 処理区分退避
    gv_proc_type := iv_proc_type;
    -- 言語設定
    gv_language  := USERENV( cv_language );
    -------------------------------------------------
    -- 1.コンカレント入力パラメータメッセージ出力
    -------------------------------------------------
    -- コンカレントパラメータ.業務日付メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00022
                    ,iv_token_name1  => cv_tkn_bis_date
                    ,iv_token_value1 => iv_proc_date
                  );
    -- コンカレントパラメータ.業務日付メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- 出力区分
                    ,iv_message  => lv_out_msg      -- メッセージ
                    ,in_new_line => cn_zero         -- 改行
                  );
    -- コンカレントパラメータ.実行区分パターンメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00044
                    ,iv_token_name1  => cv_tkn_proc_type
                    ,iv_token_value1 => iv_proc_type
                  );
    -- コンカレントパラメータ.実行区分パターンメッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- 出力区分
                    ,iv_message  => lv_out_msg      -- メッセージ
                    ,in_new_line => cn_one          -- 改行
                  );
    -------------------------------------------------
    -- 2.日付変換
    -------------------------------------------------
    IF ( iv_proc_date IS NOT NULL ) THEN
      gd_proc_date := fnd_date.canonical_to_date( iv_proc_date );
    -------------------------------------------------
    -- 3.業務処理日付取得
    -------------------------------------------------
    ELSE
      gd_proc_date := xxccp_common_pkg2.get_process_date;
    END IF;
    -- NULLの場合はエラー
    IF( gd_proc_date IS NULL ) THEN
      RAISE get_date_err_expt;
    END IF;
    -------------------------------------------------
    -- 4.組織IDプロファイル取得
    -------------------------------------------------
    gn_pro_org_id := TO_NUMBER( fnd_profile.value( cv_pro_org_code ) );
    -- NULLの場合はエラー
    IF ( gn_pro_org_id IS NULL ) THEN
      lv_prof_err := cv_pro_org_code;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 5.会計帳簿IDプロファイル取得
    -------------------------------------------------
    gn_pro_books_id := TO_NUMBER( fnd_profile.value( cv_pro_books_code ) );
    -- NULLの場合はエラー
    IF ( gn_pro_books_id IS NULL ) THEN
      lv_prof_err := cv_pro_books_code;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 6.条件別販手販協計算処理期間(From)プロファイル取得
    -------------------------------------------------
    gn_pro_bm_sup_fm := TO_NUMBER( fnd_profile.value( cv_pro_bm_sup_fm ) );
    -- NULLの場合はエラー
    IF ( gn_pro_bm_sup_fm IS NULL ) THEN
      lv_prof_err := cv_pro_bm_sup_fm;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 7.条件別販手販協計算処理期間(To)プロファイル取得
    -------------------------------------------------
    gn_pro_bm_sup_to := TO_NUMBER( fnd_profile.value( cv_pro_bm_sup_to ) );
    -- NULLの場合はエラー
    IF ( gn_pro_bm_sup_to IS NULL ) THEN
      lv_prof_err := cv_pro_bm_sup_to;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 8.販手販協計算結果保持期間プロファイル取得
    -------------------------------------------------
    gn_pro_sales_ret := TO_NUMBER( fnd_profile.value( cv_pro_sales_ret ) );
    -- NULLの場合はエラー
    IF ( gn_pro_sales_ret IS NULL ) THEN
      lv_prof_err := cv_pro_sales_ret;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 9.電気料(変動)品目コードプロファイル取得
    -------------------------------------------------
    gv_pro_elec_ch := fnd_profile.value( cv_pro_elec_ch );
    -- NULLの場合はエラー
    IF ( gv_pro_elec_ch IS NULL ) THEN
      lv_prof_err := cv_pro_elec_ch;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 10.仕入先ダミーコードプロファイル取得
    -------------------------------------------------
    gv_pro_vendor := fnd_profile.value( cv_pro_vendor );
    -- NULLの場合はエラー
    IF ( gv_pro_vendor IS NULL ) THEN
      lv_prof_err := cv_pro_vendor;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 11.仕入先サイトダミーコードプロファイル取得
    -------------------------------------------------
    gv_pro_vendor_s := fnd_profile.value( cv_pro_vendor );
    -- NULLの場合はエラー
    IF ( gv_pro_vendor_s IS NULL ) THEN
      lv_prof_err := cv_pro_vendor;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 12.販手販協保持期限日取得
    -------------------------------------------------
    gd_limit_date := ADD_MONTHS( TRUNC( gd_proc_date,cv_format3 ), - gn_pro_sales_ret );
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 業務処理日付取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_date_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00028
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- プロファイル取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_prof_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00003
                      ,iv_token_name1  => cv_tkn_profile
                      ,iv_token_value1 => lv_prof_err
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_zero         -- 改行
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END init_proc;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf    OUT VARCHAR2 -- エラーメッセージ
    ,ov_retcode   OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg    OUT VARCHAR2 -- ユーザー・エラーメッセージ
    ,iv_proc_date IN  VARCHAR2 -- 業務日付
    ,iv_proc_type IN  VARCHAR2 -- 実行区分
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf   VARCHAR2(5000); -- エラーメッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg  VARCHAR2(2000); -- メッセージ
    lb_retcode  BOOLEAN;        -- メッセージ戻り値
    -- カウンタ
    ln_full_cnt PLS_INTEGER := 0; -- フルベンダーカウンタ
    ln_term_cnt PLS_INTEGER := 0; -- 支払条件カウンタ
    ln_calc_cnt PLS_INTEGER := 0; -- 計算条件カウンタ
    ln_vend_cnt PLS_INTEGER := 0; -- 仕入先カウンタ
    ln_pay_cnt  PLS_INTEGER := 0; -- 支払先カウンタ
    ln_chk_cnt  PLS_INTEGER := 0; -- 支払先チェックカウンタ
    ln_sup_cnt  PLS_INTEGER := 0; -- 販協計算結果登録カウンタ
    ln_sale_cnt PLS_INTEGER := 0; -- 販売実績ループカウンタ
    ln_elc_cnt  PLS_INTEGER := 0; -- 電気料計算カウンタ
    -- フラグ
    ln_row_flg   NUMBER      := 0;     -- 配列拡張フラグ
    lv_vend_type VARCHAR2(1) := NULL;  -- ベンダー区分
    lv_bus_type  VARCHAR2(2) := NULL;  -- 業態小分類区分
    lv_el_flg1   VARCHAR2(1) := cv_no; -- 電気料(固定)算出済フラグ
    lv_el_flg2   VARCHAR2(1) := cv_no; -- 電気料(変動)算出済フラグ
    -- テーブル型定義
    lt_many_term   g_many_term_ttype;   -- 複数支払条件
    lt_calculation g_calculation_ttype; -- 計算条件
    lt_bm_vendor   g_bm_support_ttype;  -- 支払先情報
    lt_bm_support  g_bm_support_ttype;  -- 販手計算情報
    -- タイプ定義
    lv_bill_cust_code hz_cust_accounts.account_number%TYPE                 := NULL; -- 請求先顧客コード
    ld_pay_work_date  xxcok_cond_bm_support.expect_payment_date%TYPE       := NULL; -- 営業日を考慮した支払日
    ld_period_fm_date xxcok_cond_bm_support.calc_target_period_from%TYPE   := NULL; -- 計算対象期間(From)
    lv_period_year    gl_period_statuses.period_year%TYPE                  := NULL; -- 会計年度
    ln_bm_pct         xxcok_mst_bm_contract.bm1_pct%TYPE                   := NULL; -- 割戻率
    ln_bm_amt         xxcok_mst_bm_contract.bm1_amt%TYPE                   := NULL; -- 割戻額
    ln_bm_amount      xxcos_sales_exp_lines.sale_amount%TYPE               := NULL; -- 販売手数料
    ln_bm_amount_tax  xxcos_sales_exp_lines.tax_amount%TYPE                := NULL; -- 販売手数料消費税額
    ln_el_amount      xxcok_cond_bm_support.electric_amt_tax%TYPE          := NULL; -- 電気料
    ln_el_amount_tax  xxcok_cond_bm_support.electric_tax_amt%TYPE          := NULL; -- 電気料消費税額
    ln_rc_amount      xxcok_cond_bm_support.csh_rcpt_discount_amt%TYPE     := NULL; -- 入金値引額
    ln_rc_amount_tax  xxcok_cond_bm_support.csh_rcpt_discount_amt_tax%TYPE := NULL; -- 入金値引消費税額
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 顧客情報カーソル定義（フルベンダー・フルベンダー(消化)）
    CURSOR customer_main_cur(
       iv_proc_type IN fnd_lookup_values.lookup_code%TYPE -- 実行区分
      ,iv_bus_type  IN fnd_lookup_values.lookup_code%TYPE -- 業態小分類区分
      ,in_org_id    IN hz_cust_acct_sites_all.org_id%TYPE -- 組織ID
      ,iv_language  IN fnd_lookup_values.language%TYPE    -- 言語
    )
    IS
      SELECT hca.account_number           AS customer_code  -- 顧客コード
            ,xca.contractor_supplier_code AS bm_vend_code1  -- 契約者仕入先コード
            ,xca.bm_pay_supplier_code1    AS bm_vend_code2  -- 紹介者BM支払仕入先コード１
            ,xca.bm_pay_supplier_code2    AS bm_vend_code3  -- 紹介者BM支払仕入先コード２
            ,xca.delivery_chain_code      AS del_chain_code -- 納品先チェーンコード
      FROM   hz_cust_accounts       hca -- 顧客マスタ
            ,xxcmm_cust_accounts    xca -- 顧客マスタアドオン
            ,hz_cust_acct_sites_all hcs -- 顧客サイトマスタ
            ,hz_party_sites         hzp -- 顧客パーティサイト
            ,hz_locations           hls -- 事業所マスタ
            ,fnd_lookup_values      flv -- クイックコード
      WHERE  hca.customer_class_code = cv_cust_type1 -- 顧客区分：顧客
      AND    hca.cust_account_id     = xca.customer_id
      AND    xca.business_low_type   = iv_bus_type
      AND    hca.cust_account_id     = hcs.cust_account_id
      AND    hcs.org_id              = in_org_id
      AND    hcs.party_site_id       = hzp.party_site_id
      AND    hzp.location_id         = hls.location_id
      AND    flv.lookup_type         = cv_lk_bm_dis_type -- 販手販協計算実行区分
      AND    flv.language            = iv_language
      AND    flv.lookup_code         = iv_proc_type
      AND    SUBSTR ( hls.address3,1,2 ) IN ( flv.attribute1
                                             ,flv.attribute2
                                             ,flv.attribute3
                                             ,flv.attribute4
                                             ,flv.attribute5
                                             ,flv.attribute6
                                             ,flv.attribute7
                                             ,flv.attribute8
                                             ,flv.attribute9
                                             ,flv.attribute10
                                             ,flv.attribute11
                                             ,flv.attribute12
                                             ,flv.attribute13
                                             ,flv.attribute14
                                             ,flv.attribute15 );
    -- 顧客情報レコード定義
    customer_main_rec customer_main_cur%ROWTYPE;
    -- 顧客情報カーソル定義（一般）
    CURSOR customer_ip_main_cur(
       iv_proc_type IN fnd_lookup_values.lookup_code%TYPE -- 実行区分
      ,in_org_id    IN hz_cust_acct_sites_all.org_id%TYPE -- 組織ID
      ,iv_language  IN fnd_lookup_values.language%TYPE    -- 言語
    )
    IS
      SELECT hca.account_number                      AS customer_code  -- 顧客コード
            ,xca.delivery_chain_code                 AS del_chain_code -- 納品先チェーンコード
            ,NVL( xca.receiv_discount_rate,cn_zero ) AS discount_rate  -- 入金値引率
      FROM   hz_cust_accounts       hca -- 顧客マスタ
            ,xxcmm_cust_accounts    xca -- 顧客マスタアドオン
            ,hz_cust_acct_sites_all hcs -- 顧客サイトマスタ
            ,hz_party_sites         hzp -- 顧客パーティサイト
            ,hz_locations           hls -- 事業所マスタ
            ,fnd_lookup_values      fl1 -- クイックコード１
            ,fnd_lookup_values      fl2 -- クイックコード
      WHERE  hca.customer_class_code = cv_cust_type1 -- 顧客区分：顧客
      AND    hca.cust_account_id     = xca.customer_id
      AND    hca.cust_account_id     = hcs.cust_account_id
      AND    hcs.org_id              = in_org_id
      AND    hcs.party_site_id       = hzp.party_site_id
      AND    hzp.location_id         = hls.location_id
      AND    fl1.lookup_type         = cv_lk_bm_dis_type -- 販手販協計算実行区分
      AND    fl1.language            = iv_language
      AND    fl1.lookup_code         = iv_proc_type
      AND    SUBSTR ( hls.address3,1,2 ) IN ( fl1.attribute1
                                             ,fl1.attribute2
                                             ,fl1.attribute3
                                             ,fl1.attribute4
                                             ,fl1.attribute5
                                             ,fl1.attribute6
                                             ,fl1.attribute7
                                             ,fl1.attribute8
                                             ,fl1.attribute9
                                             ,fl1.attribute10
                                             ,fl1.attribute11
                                             ,fl1.attribute12
                                             ,fl1.attribute13
                                             ,fl1.attribute14
                                             ,fl1.attribute15 )
      AND    fl2.lookup_type         = cv_lk_cust_type -- 顧客業態区分
      AND    fl2.language            = iv_language
      AND    fl2.attribute1          <> cv_bus_type -- 11：VD以外
      AND    xca.business_low_type   = fl2.lookup_code;
    -- 顧客情報レコード定義
    customer_ip_main_rec customer_ip_main_cur%ROWTYPE;
    -- 販売実績情報カーソル定義（フルベンダー・フルベンダー消化）
    CURSOR sales_exp_main_cur(
       iv_bus_type      IN fnd_lookup_values.lookup_code%TYPE      -- 業態小分類区分
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- 締め日
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- 顧客コード
      ,iv_language      IN fnd_lookup_values.language%TYPE         -- 言語
    )
    IS
      SELECT xsh.dlv_invoice_number            AS invoice_num      -- 納品伝票番号
            ,xsh.sales_base_code               AS sales_base_code  -- 売上拠点コード
            ,xsh.results_employee_code         AS employee_code    -- 成績計上者コード
            ,xsh.ship_to_customer_code         AS ship_cust_code   -- 顧客【納品先】
            ,xsh.consumption_tax_class         AS con_tax_class    -- 消費税区分
            ,xsh.tax_code                      AS tax_code         -- 税金コード
            ,NVL( xsh.tax_rate,cn_zero )       AS tax_rate         -- 消費税率
            ,xsl.dlv_invoice_line_number       AS invoice_line_num -- 納品明細番号
            ,xsl.item_code                     AS item_code        -- 品目コード
            ,NVL( xsl.dlv_qty,cn_zero )        AS dlv_quantity     -- 納品数量
            ,xsl.dlv_uom_code                  AS dlv_uom_code     -- 納品単位
            ,NVL( xsl.dlv_unit_price,cn_zero ) AS dlv_unit_price   -- 納品単価
            ,NVL( xsl.sale_amount,cn_zero )    AS sales_amount     -- 売上金額
            ,NVL( xsl.pure_amount,cn_zero )    AS body_amount      -- 本体金額
            ,NVL( xsl.tax_amount,cn_zero )     AS tax_amount       -- 消費税金額
            ,NVL( fl1.attribute1,cv_ves_dmmy ) AS container_type   -- 容器区分
      FROM   xxcos_sales_exp_headers xsh -- 販売実績ヘッダーテーブル
            ,xxcos_sales_exp_lines   xsl -- 販売実績明細テーブル
            ,xxcmm_system_items_b    xsi -- disc品目マスタアドオン
            ,fnd_lookup_values       fl1 -- クイックコード１
      WHERE  xsh.cust_gyotai_sho        = iv_bus_type
      AND    xsh.delivery_date         <= id_close_date
      AND    xsh.dlv_invoice_number     = xsl.dlv_invoice_number
      AND    xsh.ship_to_customer_code  = iv_customer_code
      AND    xsl.to_calculate_fees_flag = cv_no -- N：未処理
      AND    xsl.item_code              = xsi.item_code
      AND    xsi.vessel_group           = fl1.lookup_code(+)
      AND    fl1.lookup_type(+)         = cv_lk_itm_yk_type -- 容器群区分
      AND    fl1.language(+)            = iv_language
      AND    NOT EXISTS ( SELECT 'X'
                          FROM   fnd_lookup_values fl2 -- クイックコード２
                          WHERE  xsl.item_code   = fl2.lookup_code
                          AND    fl2.lookup_type = cv_lk_no_inv_type -- 非在庫品目区分
                          AND    fl2.language    = iv_language );
    -- 販売実績情報レコード定義
    sales_exp_main_rec sales_exp_main_cur%ROWTYPE;
    -- 販売実績情報カーソル定義（一般）
    CURSOR sales_exp_ip_main_cur(
       id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- 締め日
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- 顧客コード
      ,iv_language      IN fnd_lookup_values.language%TYPE         -- 言語
    )
    IS
      SELECT xsh.dlv_invoice_number            AS invoice_num      -- 納品伝票番号
            ,xsh.sales_base_code               AS sales_base_code  -- 売上拠点コード
            ,xsh.results_employee_code         AS employee_code    -- 成績計上者コード
            ,xsh.ship_to_customer_code         AS ship_cust_code   -- 顧客【納品先】
            ,xsh.consumption_tax_class         AS con_tax_class    -- 消費税区分
            ,xsh.tax_code                      AS tax_code         -- 税金コード
            ,NVL( xsh.tax_rate,cn_zero )       AS tax_rate         -- 消費税率
            ,xsl.dlv_invoice_line_number       AS invoice_line_num -- 納品明細番号
            ,xsl.item_code                     AS item_code        -- 品目コード
            ,NVL( xsl.dlv_qty,cn_zero )        AS dlv_quantity     -- 納品数量
            ,xsl.dlv_uom_code                  AS dlv_uom_code     -- 納品単位
            ,NVL( xsl.dlv_unit_price,cn_zero ) AS dlv_unit_price   -- 納品単価
            ,NVL( xsl.sale_amount,cn_zero )    AS sales_amount     -- 売上金額
            ,NVL( xsl.pure_amount,cn_zero )    AS body_amount      -- 本体金額
            ,NVL( xsl.tax_amount,cn_zero )     AS tax_amount       -- 消費税金額
            ,NVL( fl1.attribute1,cv_ves_dmmy ) AS container_type   -- 容器区分
      FROM   xxcos_sales_exp_headers xsh -- 販売実績ヘッダーテーブル
            ,xxcos_sales_exp_lines   xsl -- 販売実績明細テーブル
            ,xxcmm_system_items_b    xsi -- disc品目マスタアドオン
            ,fnd_lookup_values       fl1 -- クイックコード１
      WHERE  xsh.delivery_date         <= id_close_date
      AND    xsh.dlv_invoice_number     = xsl.dlv_invoice_number
      AND    xsh.ship_to_customer_code  = iv_customer_code
      AND    xsl.to_calculate_fees_flag = cv_no -- N：未処理
      AND    xsl.item_code              = xsi.item_code
      AND    xsi.vessel_group           = fl1.lookup_code(+)
      AND    fl1.lookup_type(+)         = cv_lk_itm_yk_type -- 容器群区分
      AND    fl1.language(+)            = iv_language
      AND    NOT EXISTS ( SELECT 'X'
                          FROM   fnd_lookup_values fl2 -- クイックコード２
                          WHERE  xsh.cust_gyotai_sho = fl2.lookup_code
                          AND    fl2.lookup_type     = cv_lk_cust_type -- 顧客業態小分類区分
                          AND    fl2.language        = iv_language
                          AND    fl2.attribute1      = cv_bus_type ) -- 11：VD以外
      AND    NOT EXISTS ( SELECT 'X'
                          FROM   fnd_lookup_values fl3 -- クイックコード３
                          WHERE  xsl.item_code   = fl3.lookup_code
                          AND    fl3.lookup_type = cv_lk_no_inv_type -- 非在庫品目区分
                          AND    fl3.language    = iv_language );
    -- 販売実績情報レコード定義
    sales_exp_ip_main_rec sales_exp_ip_main_cur%ROWTYPE;
    -- 販手条件集約情報カーソル定義
    CURSOR contract_mst_grp_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE         -- 顧客コード
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE      -- 締め日
    )
    IS
      SELECT xmb.calc_type AS calc_type -- 計算条件
      FROM   xxcok_mst_bm_contract xmb -- 販手条件マスタ
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y：計算対象
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date )
      GROUP BY xmb.calc_type;
    -- 販手条件集約情報レコード定義
    contract_mst_grp_rec contract_mst_grp_cur%ROWTYPE;
    --===============================
    -- ローカル例外
    --===============================
    customer_chk_expt  EXCEPTION; -- 対象外顧客情報エラー
    customer_err_expt  EXCEPTION; -- 顧客情報エラー
    sales_exp_err_expt EXCEPTION; -- 販売実績情報エラー
    contract_err_expt  EXCEPTION; -- 販手条件エラー
  --
  BEGIN
  --
    --===============================================
    -- A-0.初期化
    --===============================================
    lv_retcode := cv_status_normal;
    --===============================================
    -- A-01.初期処理
    --===============================================
    init_proc(
       ov_errbuf    => lv_errbuf    -- エラーメッセージ
      ,ov_retcode   => lv_retcode   -- リターン・コード
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラーメッセージ
      ,iv_proc_date => iv_proc_date -- 業務日付
      ,iv_proc_type => iv_proc_type -- 実行区分
    );
    -- ステータスエラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --===============================================
    -- A-02.販手販協保持期間外データの削除
    --===============================================
    del_bm_support_info(
       ov_errbuf  => lv_errbuf  -- エラーメッセージ
      ,ov_retcode => lv_retcode -- リターン・コード
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラーメッセージ 
    );
    -- ステータスエラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -------------------------------------------------
    -- フルベンダー情報ループ
    -------------------------------------------------
    << full_vendor_loop >>
    FOR ln_full_cnt IN cn_one..cn_two LOOP
      --***************************************************************************************************************
      -- ベンダー切替時変数初期化処理
      --***************************************************************************************************************
      ln_term_cnt := 0;     -- 支払条件カウンタ
      ln_calc_cnt := 0;     -- 計算条件カウンタ
      ln_vend_cnt := 0;     -- 仕入先カウンタ
      ln_pay_cnt  := 0;     -- 支払先カウンタ
      ln_sale_cnt := 0;     -- 販売実績ループカウンタ
      lv_el_flg1  := cv_no; -- 電気料(固定)算出済フラグ
      lv_el_flg2  := cv_no; -- 電気料(変動)算出済フラグ
      -- タイプ定義
      lv_bill_cust_code := NULL; -- 請求先顧客コード
      ld_pay_work_date  := NULL; -- 営業日を考慮した支払日
      ld_period_fm_date := NULL; -- 計算対象期間(From)
      lv_period_year    := NULL; -- 会計年度
      ln_bm_pct         := NULL; -- 割戻率
      ln_bm_amt         := NULL; -- 割戻額
      ln_bm_amount      := NULL; -- 販売手数料
      ln_bm_amount_tax  := NULL; -- 販売手数料消費税額
      ln_el_amount      := NULL; -- 電気料
      ln_el_amount_tax  := NULL; -- 電気料消費税額
      -- グローバル変数
      gn_contract_cnt   := 0;    -- 販手条件エラー件数
      gv_sales_upd_flg  := NULL; -- 販売実績更新フラグ
      -- テーブル型定義
      lt_many_term.DELETE;   -- 複数支払条件
      lt_calculation.DELETE; -- 計算条件
      lt_bm_vendor.DELETE;   -- 支払先情報
      lt_bm_support.DELETE;  -- 販手計算情報
      -- カーソルクローズ
      IF ( customer_main_cur%ISOPEN ) THEN
        CLOSE customer_main_cur;
      END IF;
      IF ( sales_exp_main_cur%ISOPEN  ) THEN
        CLOSE sales_exp_main_cur;
      END IF;
      --===============================================
      -- A-03.顧客データの取得（フルベンダー）
      -- A-21.顧客データの取得（フルベンダー消化）
      --===============================================
      -- 実行ベンダーの判定
      IF ( ln_full_cnt = cn_one ) THEN
        -- フルベンダー設定
        lv_vend_type := cv_vendor_type1;-- ベンダー区分
        lv_bus_type  := cv_bus_type1;   -- 業態小分類区分
      ELSIF ( ln_full_cnt = cn_two ) THEN
        -- フルベンダー消化設定
        lv_vend_type := cv_vendor_type2;-- ベンダー区分
        lv_bus_type  := cv_bus_type2;   -- 業態小分類区分
      END IF;
      -------------------------------------------------
      -- 顧客情報ループ
      -------------------------------------------------
      OPEN customer_main_cur(
         iv_proc_type  -- 実行区分
        ,lv_bus_type   -- 業態小分類区分
        ,gn_pro_org_id -- 組織ID
        ,gv_language   -- 言語
      );
      << customer_main_loop2 >>
      LOOP
        FETCH customer_main_cur INTO customer_main_rec;
        EXIT WHEN customer_main_cur%NOTFOUND;
        --*************************************************************************************************************
        -- 顧客情報単位の処理 START
        --*************************************************************************************************************
        BEGIN
          -------------------------------------------------
          -- 初期処理
          -------------------------------------------------
          -- 顧客の件数をインクリメント
          gn_customer_cnt := gn_customer_cnt + cn_one;
          -- 販売実績ループ初期化
          ln_sale_cnt := 0;
          -- 販手条件計算配列ポインタ初期化
          ln_sup_cnt := 0;
          -- 販売実績更新不要
          gv_sales_upd_flg := cv_no;
          -- 電気料(固定)未算出
          lv_el_flg1 := cv_no;
          -- BM1仕入先コード初期化
          gv_bm1_vendor := NULL;
          -- BM1仕入先サイトコード初期化
          gv_bm1_vendor_s := NULL;
          -- 支払先情報配列初期化
          lt_bm_vendor.DELETE;
          -- 販手条件計算結果配列初期化
          lt_bm_support.DELETE;
          -- 複数支払条件配列初期化
          lt_many_term.DELETE;
          -- 販売実績カーソルクローズ
          IF ( sales_exp_main_cur%ISOPEN ) THEN
            CLOSE sales_exp_main_cur;
          END IF;
          --===================================================
          -- A-04.処理対象顧客データの判断（フルベンダー）
          -- A-22.処理対象顧客データの判断（フルベンダー消化）
          --===================================================
          chk_customer_info(
             ov_errbuf         => lv_errbuf                       -- エラーメッセージ
            ,ov_retcode        => lv_retcode                      -- リターン・コード
            ,ov_errmsg         => lv_errmsg                       -- ユーザー・エラーメッセージ 消化
            ,iv_vendor_type    => lv_vend_type                    -- ベンダー区分
            ,iv_customer_code  => customer_main_rec.customer_code -- 顧客コード
            ,ov_bill_cust_code => lv_bill_cust_code               -- 請求先顧客コード
            ,ot_many_term      => lt_many_term                    -- 複数支払条件
          );
          -- 処理対象外顧客判定
          IF ( lv_retcode = cv_customer_err ) THEN
            -- 顧客情報スキップ
            RAISE customer_chk_expt;
          -- ステータス警告判定
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- 顧客情報スキップ
            RAISE customer_err_expt;
          -- ステータスエラー判定
          ELSIF ( lv_retcode = cv_status_error ) THEN
            -- 処理部共通エラー
            RAISE global_process_expt;
          END IF;
          -------------------------------------------------
          -- 複数支払条件ループ
          -------------------------------------------------
          << many_term_all_loop >>
          FOR ln_term_cnt IN lt_many_term.FIRST..lt_many_term.LAST LOOP
            -------------------------------------------------
            -- 初期処理
            -------------------------------------------------
            -- 販売実績ループ初期化
            ln_sale_cnt := 0;
            -- 販手条件計算配列ポインタ初期化
            ln_sup_cnt := 0;
            -- 販売実績更新不要
            gv_sales_upd_flg := cv_no;
            -- 電気料(固定)未算出
            lv_el_flg1 := cv_no;
            -- BM1仕入先コード初期化
            gv_bm1_vendor := NULL;
            -- BM1仕入先サイトコード初期化
            gv_bm1_vendor_s := NULL;
            -- 支払先情報配列初期化
            lt_bm_vendor.DELETE;
            -- 販手条件計算結果配列初期化
            lt_bm_support.DELETE;
            -- 販売実績カーソルクローズ
            IF ( sales_exp_main_cur%ISOPEN ) THEN
              CLOSE sales_exp_main_cur;
            END IF;
            -------------------------------------------------
            -- 販手販協計算終了日＝業務日付判定
            -------------------------------------------------
            IF ( lt_many_term( ln_term_cnt ).end_date = gd_proc_date ) THEN
              -- 販売実績更新要
              gv_sales_upd_flg := cv_yes;
            END IF;
            --=====================================================
            -- A-05.販手販協計算付加情報の取得（フルベンダー）
            -- A-23.販手販協計算付加情報の取得（フルベンダー消化）
            --=====================================================
            get_bm_support_add_info(
               ov_errbuf        => lv_errbuf                               -- エラーメッセージ
              ,ov_retcode       => lv_retcode                              -- リターン・コード
              ,ov_errmsg        => lv_errmsg                               -- ユーザー・エラーメッセージ 
              ,iv_vendor_type   => lv_vend_type                            -- ベンダー区分
              ,iv_customer_code => customer_main_rec.customer_code         -- 顧客コード
              ,id_pay_date      => lt_many_term( ln_term_cnt ).to_pay_date -- 今回支払日
              ,od_pay_work_date => ld_pay_work_date                        -- 支払予定日
              ,ov_period_year   => lv_period_year                          -- 会計年度
            );
            -- ステータス警告判定
            IF ( lv_retcode = cv_status_warn ) THEN
              -- 顧客情報スキップ
              RAISE customer_err_expt;
            ELSIF ( lv_retcode = cv_status_error ) THEN
              -- 処理部共通エラー
              RAISE global_process_expt;
            END IF;
            --=====================================================
            -- A-06.販手条件エラーデータの削除（フルベンダー）
            -- A-24.販手条件エラーデータの削除（フルベンダー消化）
            --=====================================================
            del_bm_contract_err_info(
               ov_errbuf        => lv_errbuf                       -- エラーメッセージ
              ,ov_retcode       => lv_retcode                      -- リターン・コード
              ,ov_errmsg        => lv_errmsg                       -- ユーザー・エラーメッセージ 
              ,iv_customer_code => customer_main_rec.customer_code -- 顧客コード
            );
            -- ステータス警告判定
            IF ( lv_retcode = cv_status_warn ) THEN
              -- 顧客情報スキップ
              RAISE customer_err_expt;
            -- ステータスエラー判定
            ELSIF ( lv_retcode = cv_status_error ) THEN
              -- 処理部共通エラー
              RAISE global_process_expt;
            END IF;
            --===============================================
            -- A-07.販売実績データの取得（フルベンダー）
            -- A-25.販売実績データの取得（フルベンダー消化）
            --===============================================
            OPEN sales_exp_main_cur(
               lv_bus_type                               -- 業態小分類区分
              ,lt_many_term( ln_term_cnt ).to_close_date -- 締め日：今回締め日
              ,customer_main_rec.customer_code           -- 顧客コード
              ,gv_language                               -- 言語
            );
            << sales_exp_main_loop >>
            LOOP
              FETCH sales_exp_main_cur INTO sales_exp_main_rec;
              EXIT WHEN sales_exp_main_cur%NOTFOUND;
              --*******************************************************************************************************
              -- 販売実績情報単位の処理 START
              --*******************************************************************************************************
              BEGIN
                -------------------------------------------------
                -- 初期処理
                -------------------------------------------------
                -- 対象件数インクリメント
                gn_target_cnt := gn_target_cnt + cn_one;
                -- 販売実績ループインクリメント
                ln_sale_cnt := ln_sale_cnt + cn_one;
                -- 電気料(変動)未算出
                lv_el_flg2 := cv_no;
                -------------------------------------------------
                -- 計算条件・支払先取得判定
                -------------------------------------------------
                -- 販売実績ループの初回または支払先情報が存在しない場合
                IF ( ln_sale_cnt = cn_one ) OR
                   ( lt_bm_vendor.COUNT = cn_zero ) THEN
                  --===============================================
                  -- A-08.計算条件の取得（フルベンダー）
                  -- A-26.計算条件の取得（フルベンダー消化）
                  --===============================================
                  -------------------------------------------------
                  -- 計算条件初期処理
                  -------------------------------------------------
                  -- 計算条件カウンタ初期化
                  ln_calc_cnt := cn_zero;
                  -- 計算条件配列初期化
                  lt_calculation.DELETE;
                  -- 計算条件カーソルクローズ
                  IF ( contract_mst_grp_cur%ISOPEN ) THEN
                    CLOSE contract_mst_grp_cur;
                  END IF;
                  -------------------------------------------------
                  -- 計算条件集約情報取得ループ
                  -------------------------------------------------
                  OPEN contract_mst_grp_cur(
                     customer_main_rec.customer_code           -- 顧客コード
                    ,lt_many_term( ln_term_cnt ).to_close_date -- 締め日：今回締め日
                  );
                  << contract_mst_grp_loop >>
                  LOOP
                    FETCH contract_mst_grp_cur INTO contract_mst_grp_rec;
                    EXIT WHEN contract_mst_grp_cur%NOTFOUND;
                    -- 計算条件カウンタインクリメント
                    ln_calc_cnt := ln_calc_cnt + cn_one;
                    -- 計算条件退避
                    lt_calculation( ln_calc_cnt ) := contract_mst_grp_rec.calc_type;
                    -- 電気料計算チェック
                    IF ( contract_mst_grp_rec.calc_type = cv_cal_type50 ) THEN
                      -- 電気料計算インクリメント
                      ln_elc_cnt := ln_elc_cnt + cn_one;
                    END IF;
                  END LOOP contract_mst_grp_loop;
                  -------------------------------------------------
                  -- 計算条件取得結果判定
                  -------------------------------------------------
                  IF ( ln_calc_cnt = cn_zero ) THEN
                    -- 販手条件エラースキップ
                    RAISE contract_err_expt;
                  END IF;
                  --===============================================
                  -- A-09.支払先データの取得（フルベンダー）
                  -- A-27.支払先データの取得（フルベンダー消化）
                  --===============================================
                  get_active_vendor_info(
                     ov_errbuf        => lv_errbuf                       -- エラーメッセージ
                    ,ov_retcode       => lv_retcode                      -- リターン・コード
                    ,ov_errmsg        => lv_errmsg                       -- ユーザー・エラーメッセージ 
                    ,iv_vendor_type   => lv_vend_type                    -- ベンダー区分
                    ,iv_customer_code => customer_main_rec.customer_code -- 顧客コード
                    ,id_pay_work_date => ld_pay_work_date                -- 支払予定日
                    ,iv_vendor_code1  => customer_main_rec.bm_vend_code1 -- 契約者仕入先コード
                    ,iv_vendor_code2  => customer_main_rec.bm_vend_code2 -- 紹介者BM支払仕入先コード１
                    ,iv_vendor_code3  => customer_main_rec.bm_vend_code3 -- 紹介者BM支払仕入先コード２
                    ,in_elc_cnt       => ln_elc_cnt                      -- 電気料計算条件有無
                    ,ot_bm_support    => lt_bm_vendor                    -- 支払先情報
                  );
                  -- ステータス警告判定
                  IF ( lv_retcode = cv_status_warn ) THEN
                    -- 顧客情報スキップ
                    RAISE customer_err_expt;
                  -- ステータスエラー判定
                  ELSIF ( lv_retcode = cv_status_error ) THEN
                    -- 処理部共通エラー
                    RAISE global_process_expt;
                  END IF;
                END IF;
                -------------------------------------------------
                -- 支払先情報ループ
                -------------------------------------------------
                << bm_vendor_all_loop >>
                FOR ln_vend_cnt IN lt_bm_vendor.FIRST..lt_bm_vendor.LAST LOOP
                  --***************************************************************************************************
                  -- 支払先情報単位の処理 START
                  --***************************************************************************************************
                  BEGIN
                    -------------------------------------------------
                    -- 計算条件集約情報ループ
                    -------------------------------------------------
                    << calculation_all_loop >>
                    FOR ln_calc_cnt IN lt_calculation.FIRST..lt_calculation.LAST LOOP
                      --***********************************************************************************************
                      -- 計算条件集約情報単位の処理 START
                      --***********************************************************************************************
                      BEGIN
                        -------------------------------------------------
                        -- 初期処理
                        -------------------------------------------------
                        -- チェック用フラグ初期化
                        ln_row_flg := cn_zero;
                        --===============================================
                        -- A-10.売価別条件の計算（フルベンダー）
                        -- A-28.売価別条件の計算（フルベンダー消化）
                        --===============================================
                        -- 計算条件が10:売価別条件かつ品目が電気料（変動）以外かつ
                        -- 支払区分が電気料以外の場合
                        IF ( lt_calculation( ln_calc_cnt ) = cv_cal_type10 ) AND
                           ( lt_bm_vendor( ln_vend_cnt ).bm_type <> cv_en1_type ) AND
                           ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) THEN
                          -------------------------------------------------
                          -- 売価別計算処理
                          -------------------------------------------------
                          cal_bm_contract10_info(
                             ov_errbuf        => lv_errbuf                                 -- エラーメッセージ
                            ,ov_retcode       => lv_retcode                                -- リターン・コード
                            ,ov_errmsg        => lv_errmsg                                 -- ユーザーメッセージ 
                            ,iv_customer_code => customer_main_rec.customer_code           -- 顧客コード
                            ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- 締め日：今回締め日
                            ,iv_bm_type       => lt_bm_vendor( ln_vend_cnt ).bm_type       -- 支払区分：BM1～BM3
                            ,iv_calculat_type => lt_calculation( ln_calc_cnt )             -- 計算条件
                            ,in_retail_amount => sales_exp_main_rec.dlv_unit_price         -- 売価：納品単価
                            ,in_sales_amount  => sales_exp_main_rec.sales_amount           -- 売上金額
                            ,in_tax_rate      => sales_exp_main_rec.tax_rate               -- 消費税率
                            ,in_dlv_quantity  => sales_exp_main_rec.dlv_quantity           -- 納品数量
                            ,on_bm_pct        => ln_bm_pct                                 -- 割戻率
                            ,on_bm_amt        => ln_bm_amt                                 -- 割戻額
                            ,on_bm_amount     => ln_bm_amount                              -- 販売手数料
                            ,on_bm_amount_tax => ln_bm_amount_tax                          -- 販売手数料消費税額
                          );
                          -- 販手条件エラー判定
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- ステータスエラー判定
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列存在チェック
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- 売価存在チェックループ
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type10_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- 売価が一致し、かつ支払区分も一致する場合は一致した時点の配列項目に累積する
                              IF ( lt_bm_support( ln_chk_cnt ).selling_price =
                                                               sales_exp_main_rec.dlv_unit_price ) AND
                                 ( lt_bm_support( ln_chk_cnt ).bm_type =
                                                               lt_bm_vendor( ln_vend_cnt ).bm_type ) THEN
                                -- 既存売価有り
                                ln_row_flg := cn_two;
                                -- 現在の配列へ累積
                                ln_sup_cnt := ln_chk_cnt;
                                -- ループEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type10_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列設定
                          ----------------------------------------------------------
                          -- 初回実行時
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- 配列初期値セット
                            ln_sup_cnt := cn_zero;
                          -- 一致しない場合
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- 配列を拡張
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- 計算結果退避
                          -------------------------------------------------
                          -- 支払区分：BM1～BM3
                          lt_bm_support( ln_sup_cnt ).bm_type := lt_bm_vendor( ln_vend_cnt ).bm_type;
                          -- 仕入先コード
                          lt_bm_support( ln_sup_cnt ).supplier_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_code;
                          -- 仕入先サイトコード
                          lt_bm_support( ln_sup_cnt ).supplier_site_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_site_code;
                          -- 計算条件
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type10;
                          -- 納品数量
                          lt_bm_support( ln_sup_cnt ).delivery_qty :=
                            NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                              sales_exp_main_rec.dlv_quantity;
                          -- 納品単位
                          lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_main_rec.dlv_uom_code;
                          -- 売上金額
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- 割戻率
                          lt_bm_support( ln_sup_cnt ).rebate_rate := ln_bm_pct;
                          -- 割戻額
                          lt_bm_support( ln_sup_cnt ).rebate_amt := ln_bm_amt;
                          -- 売価金額
                          lt_bm_support( ln_sup_cnt ).selling_price := sales_exp_main_rec.dlv_unit_price;
                          -- フルベンダーの場合
                          IF ( lv_vend_type = cv_vendor_type1 ) THEN
                            -- 条件別手数料額(税込)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax,cn_zero ) +
                                ln_bm_amount;
                            -- 条件別手数料額(税抜)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax,cn_zero ) +
                                ln_bm_amount - ln_bm_amount_tax;
                            -- 条件別消費税額
                            lt_bm_support( ln_sup_cnt ).cond_tax_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_tax_amt,cn_zero ) +
                                ln_bm_amount_tax;
                          -- フルベンダー消化の場合
                          ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                            -- 入金値引額
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt,cn_zero ) +
                                ln_bm_amount;
                            -- 入金値引消費税額
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax,cn_zero ) +
                                ln_bm_amount_tax;
                          END IF;
                        --===============================================
                        -- A-11.容器区分別条件の計算（フルベンダー）
                        -- A-29.容器区分別条件の計算（フルベンダー消化）
                        --===============================================
                        -- 計算条件が20:容器区分別条件かつ品目が電気料（変動）以外かつ
                        -- 支払区分が電気料以外の場合
                        ELSIF ( lt_calculation( ln_calc_cnt ) = cv_cal_type20 ) AND
                              ( lt_bm_vendor( ln_vend_cnt ).bm_type <> cv_en1_type ) AND
                              ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) THEN
                          -------------------------------------------------
                          -- 容器区分別計算処理
                          -------------------------------------------------
                          cal_bm_contract20_info(
                             ov_errbuf         => lv_errbuf                                 -- エラーメッセージ
                            ,ov_retcode        => lv_retcode                                -- リターン・コード
                            ,ov_errmsg         => lv_errmsg                                 -- ユーザーメッセージ 
                            ,iv_customer_code  => customer_main_rec.customer_code           -- 顧客コード
                            ,id_close_date     => lt_many_term( ln_term_cnt ).to_close_date -- 締め日：今回締め日
                            ,iv_bm_type        => lt_bm_vendor( ln_vend_cnt ).bm_type       -- 支払区分：BM1～BM3
                            ,iv_calculat_type  => lt_calculation( ln_calc_cnt )             -- 計算条件
                            ,iv_container_type => sales_exp_main_rec.container_type         -- 容器区分
                            ,in_sales_amount   => sales_exp_main_rec.sales_amount           -- 売上金額
                            ,in_tax_rate       => sales_exp_main_rec.tax_rate               -- 消費税率
                            ,in_dlv_quantity   => sales_exp_main_rec.dlv_quantity           -- 納品数量
                            ,on_bm_pct         => ln_bm_pct                                 -- 割戻率
                            ,on_bm_amt         => ln_bm_amt                                 -- 割戻額
                            ,on_bm_amount      => ln_bm_amount                              -- 販売手数料
                            ,on_bm_amount_tax  => ln_bm_amount_tax                          -- 販売手数料消費税額
                          );
                          -- 販手条件エラー判定
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- ステータスエラー判定
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列存在チェック
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- 容器区分存在チェックループ
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type20_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- 容器区分が一致し、かつ支払区分も一致する場合は一致した時点の配列項目に累積する
                              IF ( lt_bm_support( ln_chk_cnt ).container_type =
                                                               sales_exp_main_rec.container_type ) AND
                                 ( lt_bm_support( ln_chk_cnt ).bm_type =
                                                               lt_bm_vendor( ln_vend_cnt ).bm_type ) THEN
                                -- 既存容器区分有り
                                ln_row_flg := cn_two;
                                -- 現在の配列へ累積
                                ln_sup_cnt := ln_chk_cnt;
                                -- ループEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type20_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列設定
                          ----------------------------------------------------------
                          -- 初回実行時
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- 配列初期値セット
                            ln_sup_cnt := cn_zero;
                          -- 一致しない場合
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- 配列を拡張
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- 計算結果退避
                          -------------------------------------------------
                          -- 支払区分：BM1～BM3
                          lt_bm_support( ln_sup_cnt ).bm_type := lt_bm_vendor( ln_vend_cnt ).bm_type;
                          -- 仕入先コード
                          lt_bm_support( ln_sup_cnt ).supplier_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_code;
                          -- 仕入先サイトコード
                          lt_bm_support( ln_sup_cnt ).supplier_site_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_site_code;
                          -- 計算条件
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type20;
                          -- 納品数量
                          lt_bm_support( ln_sup_cnt ).delivery_qty :=
                            NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                              sales_exp_main_rec.dlv_quantity;
                          -- 納品単位
                          lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_main_rec.dlv_uom_code;
                          -- 売上金額
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- 割戻率
                          lt_bm_support( ln_sup_cnt ).rebate_rate := ln_bm_pct;
                          -- 割戻額
                          lt_bm_support( ln_sup_cnt ).rebate_amt := ln_bm_amt;
                          -- 容器区分
                          lt_bm_support( ln_sup_cnt ).container_type := sales_exp_main_rec.container_type;
                          -- フルベンダーの場合
                          IF ( lv_vend_type = cv_vendor_type1 ) THEN
                            -- 条件別手数料額(税込)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax,cn_zero ) +
                                ln_bm_amount;
                            -- 条件別手数料額(税抜)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax,cn_zero ) +
                                ln_bm_amount - ln_bm_amount_tax;
                            -- 条件別消費税額
                            lt_bm_support( ln_sup_cnt ).cond_tax_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_tax_amt,cn_zero ) +
                                ln_bm_amount_tax;
                          -- フルベンダー消化の場合
                          ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                            -- 入金値引額
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt,cn_zero ) +
                                ln_bm_amount;
                            -- 入金値引消費税額
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax,cn_zero ) +
                                ln_bm_amount_tax;
                          END IF;
                        --===============================================
                        -- A-12.一律条件の計算（フルベンダー）
                        -- A-30.一律条件の計算（フルベンダー消化）
                        --===============================================
                        -- 計算条件が30:一律条件かつ品目が電気料（変動）以外かつ
                        -- 支払区分が電気料以外の場合
                        ELSIF ( lt_calculation( ln_calc_cnt ) = cv_cal_type30 ) AND
                              ( lt_bm_vendor( ln_vend_cnt ).bm_type <> cv_en1_type ) AND
                              ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) THEN
                          -------------------------------------------------
                          -- 一律計算処理
                          -------------------------------------------------
                          cal_bm_contract30_info(
                             ov_errbuf        => lv_errbuf                                 -- エラーメッセージ
                            ,ov_retcode       => lv_retcode                                -- リターン・コード
                            ,ov_errmsg        => lv_errmsg                                 -- ユーザーメッセージ 
                            ,iv_customer_code => customer_main_rec.customer_code           -- 顧客コード
                            ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- 締め日：今回締め日
                            ,iv_bm_type       => lt_bm_vendor( ln_vend_cnt ).bm_type       -- 支払区分：BM1～BM3
                            ,iv_calculat_type => lt_calculation( ln_calc_cnt )             -- 計算条件
                            ,in_sales_amount  => sales_exp_main_rec.sales_amount           -- 売上金額
                            ,in_tax_rate      => sales_exp_main_rec.tax_rate               -- 消費税率
                            ,in_dlv_quantity  => sales_exp_main_rec.dlv_quantity           -- 納品数量
                            ,on_bm_pct        => ln_bm_pct                                 -- 割戻率
                            ,on_bm_amt        => ln_bm_amt                                 -- 割戻額
                            ,on_bm_amount     => ln_bm_amount                              -- 販売手数料
                            ,on_bm_amount_tax => ln_bm_amount_tax                          -- 販売手数料消費税額
                          );
                          -- 販手条件エラー判定
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- ステータスエラー判定
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列存在チェック
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- 支払区分存在チェックループ
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type30_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- 支払区分が一致する場合は一致した時点の配列項目に累積する
                              IF ( lt_bm_support( ln_chk_cnt ).bm_type =
                                                               lt_bm_vendor( ln_vend_cnt ).bm_type ) THEN
                                -- 既存容器区分有り
                                ln_row_flg := cn_two;
                                -- 現在の配列へ累積
                                ln_sup_cnt := ln_chk_cnt;
                                -- ループEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type30_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列設定
                          ----------------------------------------------------------
                          -- 初回実行時
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- 配列初期値セット
                            ln_sup_cnt := cn_zero;
                          -- 一致しない場合
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- 配列を拡張
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- 計算結果退避
                          -------------------------------------------------
                          -- 支払区分：BM1～BM3
                          lt_bm_support( ln_sup_cnt ).bm_type := lt_bm_vendor( ln_vend_cnt ).bm_type;
                          -- 仕入先コード
                          lt_bm_support( ln_sup_cnt ).supplier_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_code;
                          -- 仕入先サイトコード
                          lt_bm_support( ln_sup_cnt ).supplier_site_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_site_code;
                          -- 計算条件
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type30;
                          -- 納品数量
                          lt_bm_support( ln_sup_cnt ).delivery_qty :=
                            NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                              sales_exp_main_rec.dlv_quantity;
                          -- 納品単位
                          lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_main_rec.dlv_uom_code;
                          -- 売上金額
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- 割戻率
                          lt_bm_support( ln_sup_cnt ).rebate_rate := ln_bm_pct;
                          -- 割戻額
                          lt_bm_support( ln_sup_cnt ).rebate_amt := ln_bm_amt;
                          -- フルベンダーの場合
                          IF ( lv_vend_type = cv_vendor_type1 ) THEN
                            -- 条件別手数料額(税込)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax,cn_zero ) +
                                ln_bm_amount;
                            -- 条件別手数料額(税抜)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax,cn_zero ) +
                                ln_bm_amount - ln_bm_amount_tax;
                            -- 条件別消費税額
                            lt_bm_support( ln_sup_cnt ).cond_tax_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_tax_amt,cn_zero ) +
                                ln_bm_amount_tax;
                          -- フルベンダー消化の場合
                          ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                            -- 入金値引額
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt,cn_zero ) +
                                ln_bm_amount;
                            -- 入金値引消費税額
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax,cn_zero ) +
                                ln_bm_amount_tax;
                          END IF;
                        --===============================================
                        -- A-13.定額条件の計算（フルベンダー）
                        -- A-31.定額条件の計算（フルベンダー消化）
                        --===============================================
                        -- 計算条件が40:定額条件かつ品目が電気料（変動）以外かつ
                        -- 支払区分が電気料以外の場合
                        ELSIF ( lt_calculation( ln_calc_cnt ) = cv_cal_type40 ) AND
                              ( lt_bm_vendor( ln_vend_cnt ).bm_type <> cv_en1_type ) AND
                              ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) THEN
                          -------------------------------------------------
                          -- 定額計算処理
                          -------------------------------------------------
                          cal_bm_contract40_info(
                             ov_errbuf        => lv_errbuf                                 -- エラーメッセージ
                            ,ov_retcode       => lv_retcode                                -- リターン・コード
                            ,ov_errmsg        => lv_errmsg                                 -- ユーザーメッセージ 
                            ,iv_customer_code => customer_main_rec.customer_code           -- 顧客コード
                            ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- 締め日：今回締め日
                            ,iv_bm_type       => lt_bm_vendor( ln_vend_cnt ).bm_type       -- 支払区分：BM1～BM3
                            ,iv_calculat_type => lt_calculation( ln_calc_cnt )             -- 計算条件
                            ,in_tax_rate      => sales_exp_main_rec.tax_rate               -- 消費税率
                            ,on_bm_amt        => ln_bm_amt                                 -- 割戻額
                            ,on_bm_amount     => ln_bm_amount                              -- 販売手数料
                            ,on_bm_amount_tax => ln_bm_amount_tax                          -- 販売手数料消費税額
                          );
                          -- 販手条件エラー判定
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- ステータスエラー判定
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列存在チェック
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- 支払区分存在チェックループ
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type40_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- 支払区分が一致する場合は一致した時点の配列項目に累積する
                              IF ( lt_bm_support( ln_chk_cnt ).bm_type =
                                                               lt_bm_vendor( ln_vend_cnt ).bm_type ) THEN
                                -- 既存容器区分有り
                                ln_row_flg := cn_two;
                                -- 現在の配列へ累積
                                ln_sup_cnt := ln_chk_cnt;
                                -- ループEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type40_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列設定
                          ----------------------------------------------------------
                          -- 初回実行時
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- 配列初期値セット
                            ln_sup_cnt := cn_zero;
                          -- 一致しない場合
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- 配列を拡張
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- 計算結果退避
                          -------------------------------------------------
                          -- 支払区分：BM1～BM3
                          lt_bm_support( ln_sup_cnt ).bm_type := lt_bm_vendor( ln_vend_cnt ).bm_type;
                          -- 仕入先コード
                          lt_bm_support( ln_sup_cnt ).supplier_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_code;
                          -- 仕入先サイトコード
                          lt_bm_support( ln_sup_cnt ).supplier_site_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_site_code;
                          -- 計算条件
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type40;
                          -- 納品数量
                          lt_bm_support( ln_sup_cnt ).delivery_qty :=
                            NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                              sales_exp_main_rec.dlv_quantity;
                          -- 納品単位
                          lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_main_rec.dlv_uom_code;
                          -- 売上金額
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- フルベンダーの場合
                          IF ( lv_vend_type = cv_vendor_type1 ) THEN
                            -- 条件別手数料額(税込)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax := ln_bm_amount;
                            -- 条件別手数料額(税抜)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax := ln_bm_amount - ln_bm_amount_tax;
                            -- 条件別消費税額
                            lt_bm_support( ln_sup_cnt ).cond_tax_amt := ln_bm_amount_tax;
                          -- フルベンダー消化の場合
                          ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                            -- 入金値引額
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt := ln_bm_amount;
                            -- 入金値引消費税額
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax := ln_bm_amount_tax;
                          END IF;
                        --===============================================
                        -- A-14.電気料条件の計算（フルベンダー）
                        -- A-32.電気料条件の計算（フルベンダー消化）
                        --===============================================
                        -- 計算条件が50:電気料（固定）かつ品目が電気料（変動）以外かつ
                        -- 電気料（固定）計算が顧客情報内で初回の場合
                        ELSIF ( lt_calculation( ln_calc_cnt ) = cv_cal_type50 ) AND
                              ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) AND
                              ( lv_el_flg1 = cv_no ) THEN
                          -------------------------------------------------
                          -- 電気料（固定）計算処理
                          -------------------------------------------------
                          cal_bm_contract50_info(
                             ov_errbuf        => lv_errbuf                                 -- エラーメッセージ
                            ,ov_retcode       => lv_retcode                                -- リターン・コード
                            ,ov_errmsg        => lv_errmsg                                 -- ユーザー・エラーメッセージ 
                            ,iv_customer_code => customer_main_rec.customer_code           -- 顧客コード
                            ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- 締め日：今回締め日
                            ,iv_calculat_type => lt_calculation( ln_calc_cnt )             -- 計算条件
                            ,in_tax_rate      => sales_exp_main_rec.tax_rate               -- 消費税率
                            ,iv_con_tax_class => sales_exp_main_rec.con_tax_class          -- 消費税区分
                            ,on_el_amount     => ln_el_amount                              -- 電気料
                            ,on_el_amount_tax => ln_el_amount_tax                          -- 電気料消費税額
                          );
                          -- 販手条件エラー判定
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- ステータスエラー判定
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列存在チェック
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- 電気料支払区分存在チェックループ
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type50_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- 支払区分が一致する場合は一致した時点の配列項目に累積する
                              IF ( lt_bm_support( ln_chk_cnt ).bm_type = cv_en1_type ) THEN
                                -- 既存電気料有り
                                ln_row_flg := cn_two;
                                -- 現在の配列へ累積
                                ln_sup_cnt := ln_chk_cnt;
                                -- ループEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type50_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列設定
                          ----------------------------------------------------------
                          -- 初回実行時
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- 配列初期値セット
                            ln_sup_cnt := cn_zero;
                          -- 一致しない場合
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- 配列を拡張
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- 計算結果退避
                          -------------------------------------------------
                          -- 支払区分：EN1
                          lt_bm_support( ln_sup_cnt ).bm_type := cv_en1_type;
                          -- 計算条件
                          lt_bm_support( ln_sup_cnt ).calc_type := lt_calculation( ln_calc_cnt );
                          -- 仕入先コード
                          lt_bm_support( ln_sup_cnt ).supplier_code := gv_bm1_vendor;
                          -- 仕入先サイトコード
                          lt_bm_support( ln_sup_cnt ).supplier_site_code := gv_bm1_vendor_s;
                          -- 売上金額
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax := cn_zero;
                          -- 電気料(税込)
                          lt_bm_support( ln_sup_cnt ).electric_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_amt_tax,cn_zero ) +
                              ln_el_amount;
                          -- 電気料(税抜)
                          lt_bm_support( ln_sup_cnt ).electric_amt_no_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_amt_no_tax,cn_zero ) +
                              ln_el_amount - ln_el_amount_tax;
                          -- 電気料消費税額
                          lt_bm_support( ln_sup_cnt ).electric_tax_amt :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_tax_amt,cn_zero ) +
                              ln_el_amount_tax;
                          -- 電気料(固定)算出済
                          lv_el_flg1 := cv_yes;
                        --===============================================
                        -- A-15.電気料（変動）の計算（フルベンダー）
                        -- A-33.電気料（変動）の計算（フルベンダー消化）
                        --===============================================
                        -- 品目が電気料（変動）かつ電気料（変動）計算が
                        -- 販売実績情報内で初回の場合
                        ELSIF ( sales_exp_main_rec.item_code = gv_pro_elec_ch ) AND
                              ( lv_el_flg2 = cv_no ) THEN
                          ----------------------------------------------------------
                          -- 配列存在チェック
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- 電気料支払区分存在チェックループ
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_elc_type50_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- 支払区分が一致する場合は一致した時点の配列項目に累積する
                              IF ( lt_bm_support( ln_chk_cnt ).bm_type = cv_en1_type ) THEN
                                -- 既存電気料有り
                                ln_row_flg := cn_two;
                                -- 現在の配列へ累積
                                ln_sup_cnt := ln_chk_cnt;
                                -- ループEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_elc_type50_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- 配列設定
                          ----------------------------------------------------------
                          -- 初回実行時
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- 配列初期値セット
                            ln_sup_cnt := cn_zero;
                          -- 一致しない場合
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- 配列を拡張
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- 計算結果退避
                          -------------------------------------------------
                          -- 支払区分：EN1
                          lt_bm_support( ln_sup_cnt ).bm_type := cv_en1_type;
                          -- 仕入先コード
                          lt_bm_support( ln_sup_cnt ).supplier_code := gv_bm1_vendor;
                          -- 仕入先サイトコード
                          lt_bm_support( ln_sup_cnt ).supplier_site_code := gv_bm1_vendor_s;
                          -- 計算条件
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type50;
                          -- 売上金額
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax := cn_zero;
                          -- 電気料(税込)
                          lt_bm_support( ln_sup_cnt ).electric_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- 電気料(税抜)
                          lt_bm_support( ln_sup_cnt ).electric_amt_no_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_amt_no_tax,cn_zero ) +
                              sales_exp_main_rec.body_amount;
                          -- 電気料消費税額
                          lt_bm_support( ln_sup_cnt ).electric_tax_amt :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_tax_amt,cn_zero ) +
                              sales_exp_main_rec.tax_amount;
                          -- 電気料(変動)算出済
                          lv_el_flg2 := cv_yes;
                        END IF;
                      --***********************************************************************************************
                      -- 計算条件集約情報単位の処理 END
                      --***********************************************************************************************
                      EXCEPTION
                        ----------------------------------------------------------
                        -- 販手条件エラー例外ハンドラ
                        ----------------------------------------------------------
                        WHEN contract_err_expt THEN
                          --=====================================================
                          -- A-16.販手条件エラーデータの登録（フルベンダー）
                          -- A-34.販手条件エラーデータの登録（フルベンダー消化）
                          --=====================================================
                          ins_bm_contract_err_info(
                             ov_errbuf         => lv_errbuf                                 -- エラーメッセージ
                            ,ov_retcode        => lv_retcode                                -- リターン・コード
                            ,ov_errmsg         => lv_errmsg                                 -- ユーザーメッセージ 
                            ,iv_base_code      => sales_exp_main_rec.sales_base_code        -- 拠点コード
                            ,iv_customer_code  => customer_main_rec.customer_code           -- 顧客コード
                            ,iv_item_code      => sales_exp_main_rec.item_code              -- 品目コード
                            ,iv_container_type => sales_exp_main_rec.container_type         -- 容器区分コード
                            ,in_retail_amount  => sales_exp_main_rec.dlv_unit_price         -- 売価
                            ,in_sales_amount   => sales_exp_main_rec.sales_amount           -- 売上金額(税込)
                            ,id_close_date     => lt_many_term( ln_term_cnt ).to_close_date -- 締め日
                          );
                          -- ステータスエラー判定
                          IF ( lv_retcode = cv_status_error ) THEN
                            -- 支払先情報の処理部共通例外へ
                            RAISE global_process_expt;
                          END IF;
                          -- 販手条件エラー件数をインクリメント
                          gn_contract_cnt := gn_contract_cnt + cn_one;
                        ----------------------------------------------------------
                        -- 処理部共通例外ハンドラ
                        ----------------------------------------------------------
                        WHEN global_process_expt THEN
                          -- 支払先情報の処理部共通例外へ
                          RAISE global_process_expt;
                      END;
                      -- BM1（初回の支払情報）で販手条件エラーが発生した場合、後続の支払先をスキップする
                      IF ( gn_contract_cnt <> cn_zero ) THEN
                        -- 支払先情報の販手条件エラー例外へ
                        RAISE contract_err_expt;
                      END IF;
                    ----------------------------------------------------------
                    -- 販手販協計算ループ
                    ----------------------------------------------------------
                    END LOOP calculation_all_loop;
                  --***************************************************************************************************
                  -- 支払先情報単位の処理 END
                  --***************************************************************************************************
                  EXCEPTION
                    ----------------------------------------------------------
                    -- 販手条件エラー例外ハンドラ
                    ----------------------------------------------------------
                    WHEN contract_err_expt THEN
                      -- 販売実績情報のスキップ例外へ
                      RAISE sales_exp_err_expt;
                    ----------------------------------------------------------
                    -- 処理部共通例外ハンドラ
                    ----------------------------------------------------------
                    WHEN global_process_expt THEN
                      -- 販売実績情報の処理部共通例外へ
                      RAISE global_process_expt;
                  END;
                ----------------------------------------------------------
                -- 支払先情報ループ
                ----------------------------------------------------------
                END LOOP bm_vendor_all_loop;
                --=================================================
                -- A-17.販売実績連携結果の更新（フルベンダー）
                -- A-35.販売実績連携結果の更新（フルベンダー消化）
                --=================================================
                -- 販手販協計算終了日＝業務日付の場合、
                -- 販手条件エラーが発生していない場合は更新
                IF ( gv_sales_upd_flg = cv_yes ) AND
                   ( gn_contract_cnt = cn_zero ) THEN
                  -- 販売実績連携結果の更新
                  upd_sales_exp_lines_info(
                     ov_errbuf           => lv_errbuf                           -- エラーメッセージ
                    ,ov_retcode          => lv_retcode                          -- リターン・コード
                    ,ov_errmsg           => lv_errmsg                           -- ユーザー・エラーメッセージ 
                    ,iv_if_status        => cv_yes                              -- 手数料計算インタフェース済フラグ
                    ,iv_customer_code    => customer_main_rec.customer_code     -- 顧客コード
                    ,iv_invoice_num      => sales_exp_main_rec.invoice_num      -- 納品伝票番号
                    ,iv_invoice_line_num => sales_exp_main_rec.invoice_line_num -- 納品明細番号
                  );
                END IF;
                -- ステータス警告判定
                IF ( lv_retcode = cv_status_warn ) THEN
                  -- 販売実績情報スキップ
                  RAISE sales_exp_err_expt;
                -- ステータスエラー判定
                ELSIF ( lv_retcode = cv_status_error ) THEN
                  -- 処理部共通エラー
                  RAISE global_process_expt;
                END IF;
                -- 販手条件エラー件数をクリア
                gn_contract_cnt := cn_zero;
              --*******************************************************************************************************
              -- 販売実績情報単位の処理 END
              --*******************************************************************************************************
              EXCEPTION
                ----------------------------------------------------------
                -- 顧客情報スキップ処理例外ハンドラ
                ----------------------------------------------------------
                WHEN customer_err_expt THEN
                  -- 顧客情報のスキップ例外へ
                  RAISE customer_err_expt;
                ----------------------------------------------------------
                -- 販売実績情報スキップ処理例外ハンドラ
                ----------------------------------------------------------
                WHEN sales_exp_err_expt THEN
                  IF ( gn_contract_cnt <> cn_zero ) THEN
                    -- 販手条件エラー件数を合算
                    gn_warning_cnt := gn_warning_cnt + gn_contract_cnt;
                  ELSE
                    -- 警告件数をインクリメント
                    gn_warning_cnt := gn_warning_cnt + cn_one;
                  END IF;
                  -- 販手条件エラー件数をクリア
                  gn_contract_cnt := cn_zero;
                ----------------------------------------------------------
                -- 販手条件エラー（計算条件集約情報取得時）例外ハンドラ
                ----------------------------------------------------------
                WHEN contract_err_expt THEN
                  --=====================================================
                  -- A-16.販手条件エラーデータの登録（フルベンダー）
                  -- A-34.販手条件エラーデータの登録（フルベンダー消化）
                  --=====================================================
                  ins_bm_contract_err_info(
                     ov_errbuf         => lv_errbuf                                 -- エラーメッセージ
                    ,ov_retcode        => lv_retcode                                -- リターン・コード
                    ,ov_errmsg         => lv_errmsg                                 -- ユーザー・エラーメッセージ 
                    ,iv_base_code      => sales_exp_main_rec.sales_base_code        -- 拠点コード
                    ,iv_customer_code  => customer_main_rec.customer_code           -- 顧客コード
                    ,iv_item_code      => sales_exp_main_rec.item_code              -- 品目コード
                    ,iv_container_type => sales_exp_main_rec.container_type         -- 容器区分コード
                    ,in_retail_amount  => sales_exp_main_rec.dlv_unit_price         -- 売価
                    ,in_sales_amount   => sales_exp_main_rec.sales_amount           -- 売上金額(税込)
                    ,id_close_date     => lt_many_term( ln_term_cnt ).to_close_date -- 締め日
                  );
                  -- ステータスエラー判定
                  IF ( lv_retcode = cv_status_error ) THEN
                    RAISE global_process_expt;
                  END IF;
                  -- 警告件数をインクリメント
                  gn_warning_cnt := gn_warning_cnt + cn_one;
                ----------------------------------------------------------
                -- 処理部共通例外ハンドラ
                ----------------------------------------------------------
                WHEN global_process_expt THEN
                  -- 顧客情報の処理部共通例外へ
                  RAISE global_process_expt;
              END;
            ----------------------------------------------------------
            -- 販売実績データループ
            ----------------------------------------------------------
            END LOOP sales_exp_main_loop;
            ----------------------------------------------------------
            -- 計算結果登録処理
            ----------------------------------------------------------
            -- 販売実績が存在しない場合は処理を行わない
            IF ( lt_bm_support.COUNT <> cn_zero ) THEN
              --============================================================
              -- A-18.前回販手販協計算結果データの削除（フルベンダー）
              -- A-36.前回販手販協計算結果データの削除（フルベンダー消化）
              --============================================================
              del_pre_bm_support_info(
                 ov_errbuf        => lv_errbuf                                 -- エラーメッセージ
                ,ov_retcode       => lv_retcode                                -- リターン・コード
                ,ov_errmsg        => lv_errmsg                                 -- ユーザー・エラーメッセージ 
                ,iv_customer_code => customer_main_rec.customer_code           -- 顧客コード
                ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- 締め日
              );
              -- ステータス警告判定
              IF ( lv_retcode = cv_status_warn ) THEN
                -- 顧客情報スキップ
                RAISE customer_err_expt;
              -- ステータスエラー判定
              ELSIF ( lv_retcode = cv_status_error ) THEN
                -- 処理部共通エラー
                RAISE global_process_expt;
              END IF;
              --==============================================================
              -- A-19.販手販協計算登録情報の付加情報設定（フルベンダー）
              -- A-37.販手販協計算登録情報の付加情報設定（フルベンダー消化）
              --==============================================================
              << bm_support_all_loop >>
              FOR ln_vend_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                -------------------------------------------------
                -- 計算結果退避
                -------------------------------------------------
                -- 拠点コード
                lt_bm_support( ln_vend_cnt ).base_code := sales_exp_main_rec.sales_base_code;
                -- 担当者コード
                lt_bm_support( ln_vend_cnt ).emp_code := sales_exp_main_rec.employee_code;
                -- 顧客【納品先】
                lt_bm_support( ln_vend_cnt ).delivery_cust_code := sales_exp_main_rec.ship_cust_code;
                -- 顧客【請求先】
                lt_bm_support( ln_vend_cnt ).demand_to_cust_code := lv_bill_cust_code;
                -- 会計年度
                lt_bm_support( ln_vend_cnt ).acctg_year := lv_period_year;
                -- チェーン店コード
                lt_bm_support( ln_vend_cnt ).chain_store_code := customer_main_rec.del_chain_code;
                -- 納品日年月
                lt_bm_support( ln_vend_cnt ).delivery_date :=
                  TO_CHAR( lt_many_term( ln_term_cnt ).to_close_date,cv_format2 );
                -- 消費税区分
                lt_bm_support( ln_vend_cnt ).tax_class := sales_exp_main_rec.con_tax_class;
                -- 税金コード
                lt_bm_support( ln_vend_cnt ).tax_code := sales_exp_main_rec.tax_code;
                -- 消費税率
                lt_bm_support( ln_vend_cnt ).tax_rate := sales_exp_main_rec.tax_rate;
                -- 支払条件
                lt_bm_support( ln_vend_cnt ).term_code := lt_many_term( ln_term_cnt ).to_term_name;
                -- 締め日
                lt_bm_support( ln_vend_cnt ).closing_date := lt_many_term( ln_term_cnt ).to_close_date;
                -- 支払予定日
                lt_bm_support( ln_vend_cnt ).expect_payment_date := ld_pay_work_date;
                -- 計算対象期間(From)＋１日
                ld_period_fm_date := lt_many_term( ln_term_cnt ).fm_close_date + cn_one;
                lt_bm_support( ln_vend_cnt ).calc_period_from := ld_period_fm_date; 
                -- 計算対象期間(To)
                lt_bm_support( ln_vend_cnt ).calc_period_to := lt_many_term( ln_term_cnt ).to_close_date;
                -- フルベンダーの場合
                IF ( lv_vend_type = cv_vendor_type1 ) THEN
                  -- 連携ステータス(条件別販手販協)
                  lt_bm_support( ln_vend_cnt ).cond_bm_if_status := cv_if_status0;
                  -- 連携日(条件別販手販協)
                  lt_bm_support( ln_vend_cnt ).cond_bm_if_date := NULL;
                  -- 連携ステータス(販手残高)
                  lt_bm_support( ln_vend_cnt ).bm_interface_status := cv_if_status0;
                  -- 連携日(販手残高)
                  lt_bm_support( ln_vend_cnt ).bm_interface_date := NULL;
                  -- 連携ステータス(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                  -- 連携日(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                -- フルベンダー消化の場合
                ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                  -- 連携ステータス(条件別販手販協)
                  lt_bm_support( ln_vend_cnt ).cond_bm_if_status := cv_if_status2;
                  -- 連携日(条件別販手販協)
                  lt_bm_support( ln_vend_cnt ).cond_bm_if_date := NULL;
                  -- 連携ステータス(販手残高)
                  lt_bm_support( ln_vend_cnt ).bm_interface_status := cv_if_status2;
                  -- 連携日(販手残高)
                  lt_bm_support( ln_vend_cnt ).bm_interface_date := NULL;
                  -- 販手販協計算終了日＝業務日付の場合
                  IF ( gv_sales_upd_flg = cv_yes ) THEN
                    -- 支払区分が電気料の場合
                    IF ( lt_bm_support( ln_vend_cnt ).bm_type = cv_en1_type ) THEN
                      -- 連携ステータス(AR)
                      lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                      -- 連携日(AR)
                      lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                    ELSE
                      -- 連携ステータス(AR)
                      lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status0;
                      -- 連携日(AR)
                      lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                    END IF;
                  -- 販手販協計算終了日＝業務日付でない場合
                  ELSE
                    -- 連携ステータス(AR)
                    lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                    -- 連携日(AR)
                    lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                  END IF;
                END IF;
              END LOOP bm_support_all_loop;
              --=========================================================
              -- A-20.条件別販手販協計算データの登録（フルベンダー）
              -- A-38.条件別販手販協計算データの登録（フルベンダー消化）
              --=========================================================
              ins_bm_support_info(
                 ov_errbuf        => lv_errbuf                                 -- エラーメッセージ
                ,ov_retcode       => lv_retcode                                -- リターン・コード
                ,ov_errmsg        => lv_errmsg                                 -- ユーザー・エラーメッセージ 
                ,iv_vendor_type   => lv_vend_type                              -- ベンダー区分
                ,id_fm_close_date => lt_many_term( ln_term_cnt ).fm_close_date -- 前回締め日
                ,id_to_close_date => lt_many_term( ln_term_cnt ).to_close_date -- 今回締め日
                ,it_bm_support    => lt_bm_support                             -- 販手販協計算登録情報
              );
              -- ステータスエラー判定
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
              -- 正常処理件数へ登録に成功した件数を加算
              gn_normal_cnt := gn_normal_cnt + lt_bm_support.COUNT;
            END IF;
          -------------------------------------------------
          -- 複数支払条件ループ
          -------------------------------------------------
          END LOOP many_term_all_loop;
          -------------------------------------------------
          -- COMMIT判定
          -------------------------------------------------
          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
            -- 顧客単位にCOMMIT
            COMMIT;
          END IF;
          -------------------------------------------------
        --*************************************************************************************************************
        -- 顧客情報単位の処理 END
        --*************************************************************************************************************
        EXCEPTION
          ----------------------------------------------------------
          -- 顧客情報スキップ処理（処理対象外顧客）例外ハンドラ
          ----------------------------------------------------------
          WHEN customer_chk_expt THEN
            -- 顧客情報をスキップ
            NULL;
          ----------------------------------------------------------
          -- 顧客情報スキップ処理例外ハンドラ
          ----------------------------------------------------------
          WHEN customer_err_expt THEN
            -- 警告件数をインクリメント
            gn_warning_cnt := gn_warning_cnt + cn_one;
          ----------------------------------------------------------
          -- 処理部共通例外ハンドラ
          ----------------------------------------------------------
          WHEN global_process_expt THEN
            -- submainの処理部共通例外へ
            RAISE global_process_expt;
        END;
      ----------------------------------------------------------
      -- 顧客情報ループ
      ----------------------------------------------------------
      END LOOP customer_main_loop2;
    ----------------------------------------------------------
    -- フルベンダー情報ループ
    ----------------------------------------------------------
    END LOOP full_vendor_loop;
    --*****************************************************************************************************************
    -- 一般切替時変数初期化処理
    --*****************************************************************************************************************
    ln_term_cnt := 0;     -- 支払条件カウンタ
    ln_calc_cnt := 0;     -- 計算条件カウンタ
    ln_vend_cnt := 0;     -- 仕入先カウンタ
    ln_pay_cnt  := 0;     -- 支払先カウンタ
    ln_sale_cnt := 0;     -- 販売実績ループカウンタ
    lv_el_flg1  := cv_no; -- 電気料(固定)算出済フラグ
    lv_el_flg2  := cv_no; -- 電気料(変動)算出済フラグ
    -- タイプ定義
    lv_bill_cust_code := NULL; -- 請求先顧客コード
    ld_pay_work_date  := NULL; -- 営業日を考慮した支払日
    ld_period_fm_date := NULL; -- 計算対象期間(From)
    lv_period_year    := NULL; -- 会計年度
    ln_bm_pct         := NULL; -- 割戻率
    ln_bm_amt         := NULL; -- 割戻額
    ln_bm_amount      := NULL; -- 販売手数料
    ln_bm_amount_tax  := NULL; -- 販売手数料消費税額
    ln_el_amount      := NULL; -- 電気料
    ln_el_amount_tax  := NULL; -- 電気料消費税額
    -- グローバル変数
    gn_contract_cnt   := 0;    -- 販手条件エラー件数
    gv_sales_upd_flg  := NULL; -- 販売実績更新フラグ
    -- テーブル型定義
    lt_many_term.DELETE;   -- 複数支払条件
    lt_calculation.DELETE; -- 計算条件
    lt_bm_vendor.DELETE;   -- 支払先情報
    lt_bm_support.DELETE;  -- 販手計算情報
    -- カーソルクローズ
    IF ( customer_main_cur%ISOPEN ) THEN
      CLOSE customer_main_cur;
    END IF;
    IF ( sales_exp_main_cur%ISOPEN  ) THEN
      CLOSE sales_exp_main_cur;
    END IF;
    --===============================================
    -- A-39.顧客データの取得（一般）
    --===============================================
    OPEN customer_ip_main_cur(
       iv_proc_type  -- 実行区分
      ,gn_pro_org_id -- 組織ID
      ,gv_language   -- 言語
    );
    << customer_main_loop3 >>
    LOOP
      FETCH customer_ip_main_cur INTO customer_ip_main_rec;
      EXIT WHEN customer_ip_main_cur%NOTFOUND;
      --***************************************************************************************************************
      -- 顧客情報単位の処理 START
      --***************************************************************************************************************
      BEGIN
        -------------------------------------------------
        -- 初期処理
        -------------------------------------------------
        -- 顧客の件数をインクリメント
        gn_customer_cnt := gn_customer_cnt + cn_one;
        -- 販売実績ループ初期化
        ln_sale_cnt := 0;
        -- 販手条件計算配列ポインタ初期化
        ln_sup_cnt := 0;
        -- 販売実績更新不要
        gv_sales_upd_flg := cv_no;
        -- 電気料(変動)未算出
        lv_el_flg2 := cv_no;
        -- 販手条件計算結果配列初期化
        lt_bm_support.DELETE;
        -- 複数支払条件配列初期化
        lt_many_term.DELETE;   
        -- 販売実績カーソルクローズ
        IF ( sales_exp_ip_main_cur%ISOPEN ) THEN
          CLOSE sales_exp_ip_main_cur;
        END IF;
        --===============================================
        -- A-40.処理対象顧客データの判断（一般）
        --===============================================
        chk_customer_info(
           ov_errbuf         => lv_errbuf                          -- エラーメッセージ
          ,ov_retcode        => lv_retcode                         -- リターン・コード
          ,ov_errmsg         => lv_errmsg                          -- ユーザー・エラーメッセージ 
          ,iv_vendor_type    => cv_vendor_type3                    -- ベンダー区分：一般
          ,iv_customer_code  => customer_ip_main_rec.customer_code -- 顧客コード
          ,ov_bill_cust_code => lv_bill_cust_code                  -- 請求先顧客コード
          ,ot_many_term      => lt_many_term                       -- 複数支払条件
        );
        -- 処理対象外顧客判定
        IF ( lv_retcode = cv_customer_err ) THEN
          -- 顧客情報スキップ
          RAISE customer_chk_expt;
        -- ステータス警告判定
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- 顧客情報スキップ
          RAISE customer_err_expt;
        -- ステータスエラー判定
        ELSIF ( lv_retcode = cv_status_error ) THEN
          -- 処理部共通エラー
          RAISE global_process_expt;
        END IF;
        -------------------------------------------------
        -- 複数支払条件ループ
        -------------------------------------------------
        << many_term_all_loop >>
        FOR ln_term_cnt IN lt_many_term.FIRST..lt_many_term.LAST LOOP
          -------------------------------------------------
          -- 初期処理
          -------------------------------------------------
          -- 販売実績ループ初期化
          ln_sale_cnt := 0;
          -- 販手条件計算配列ポインタ初期化
          ln_sup_cnt := 0;
          -- 販売実績更新不要
          gv_sales_upd_flg := cv_no;
          -- 電気料(変動)未算出
          lv_el_flg2 := cv_no;
          -- 販手条件計算結果配列初期化
          lt_bm_support.DELETE;
          -- 販売実績カーソルクローズ
          IF ( sales_exp_ip_main_cur%ISOPEN ) THEN
            CLOSE sales_exp_ip_main_cur;
          END IF;
          -------------------------------------------------
          -- 販手販協計算終了日＝業務日付判定
          -------------------------------------------------
          IF ( lt_many_term( ln_term_cnt ).end_date = gd_proc_date ) THEN
            -- 販売実績更新要
            gv_sales_upd_flg := cv_yes;
          END IF;
          --=================================================
          -- A-41.販手販協計算付加情報の取得（一般）
          --=================================================
          get_bm_support_add_info(
             ov_errbuf        => lv_errbuf                               -- エラーメッセージ
            ,ov_retcode       => lv_retcode                              -- リターン・コード
            ,ov_errmsg        => lv_errmsg                               -- ユーザー・エラーメッセージ 
            ,iv_vendor_type   => cv_vendor_type3                         -- ベンダー区分：一般
            ,iv_customer_code => customer_ip_main_rec.customer_code      -- 顧客コード
            ,id_pay_date      => lt_many_term( ln_term_cnt ).to_pay_date -- 今回支払日
            ,od_pay_work_date => ld_pay_work_date                        -- 支払予定日
            ,ov_period_year   => lv_period_year                          -- 会計年度
          );
          -- ステータスエラー判定
          IF ( lv_retcode = cv_status_warn ) THEN
            -- 顧客情報スキップ
            RAISE customer_err_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            -- 処理部共通エラー
            RAISE global_process_expt;
          END IF;
          --===============================================
          -- A-42.販売実績データの取得（一般）
          --===============================================
          OPEN sales_exp_ip_main_cur(
             lt_many_term( ln_term_cnt ).to_close_date -- 締め日：今回締め日
            ,customer_ip_main_rec.customer_code        -- 顧客コード
            ,gv_language                               -- 言語
          );
          << sales_exp_main_loop >>
          LOOP
            FETCH sales_exp_ip_main_cur INTO sales_exp_ip_main_rec;
            EXIT WHEN sales_exp_ip_main_cur%NOTFOUND;
            --*********************************************************************************************************
            -- 販売実績情報単位の処理 START
            --*********************************************************************************************************
            BEGIN
              -------------------------------------------------
              -- 初期処理
              -------------------------------------------------
              -- 対象件数インクリメント
              gn_target_cnt := gn_target_cnt + cn_one;
              -- 販売実績ループインクリメント
              ln_sale_cnt := ln_sale_cnt + cn_one;
              -- チェック用フラグ初期化
              ln_row_flg := cn_zero;
              --===============================================
              -- A-43.値引額の計算（一般）
              --===============================================
              -- 品目が電気料（変動）以外かつ入金値引率が設定されている顧客のみ
              IF ( customer_ip_main_rec.discount_rate <> cn_zero ) AND
                 ( sales_exp_ip_main_rec.item_code <> gv_pro_elec_ch ) THEN
                -------------------------------------------------
                -- 入金値引額計算処理
                -------------------------------------------------
                cal_bm_contract60_info(
                   ov_errbuf        => lv_errbuf                                 -- エラーメッセージ
                  ,ov_retcode       => lv_retcode                                -- リターン・コード
                  ,ov_errmsg        => lv_errmsg                                 -- ユーザー・エラーメッセージ 
                  ,iv_customer_code => customer_ip_main_rec.customer_code        -- 顧客コード
                  ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- 締め日：今回締め日
                  ,in_sale_amount   => sales_exp_ip_main_rec.sales_amount        -- 売上金額
                  ,in_tax_rate      => sales_exp_ip_main_rec.tax_rate            -- 消費税率
                  ,in_discount_rate => customer_ip_main_rec.discount_rate        -- 入金値引率
                  ,on_rc_amount     => ln_rc_amount                              -- 入金値引額
                  ,on_rc_amount_tax => ln_rc_amount_tax                          -- 入金値引消費税額
                );
                -- 販手条件エラー判定
                IF ( lv_retcode = cv_contract_err ) THEN
                  RAISE contract_err_expt;
                -- ステータスエラー判定
                ELSIF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
                ----------------------------------------------------------
                -- 配列存在チェック
                ----------------------------------------------------------
                IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                  ln_row_flg := cn_one;
                END IF;
                ----------------------------------------------------------
                -- 値引額支払区分存在チェックループ
                ----------------------------------------------------------
                IF ( ln_row_flg = cn_one ) THEN
                  << bm_rcpt_type60_chk_loop >>
                  FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                    -- 支払区分が一致する場合は一致した時点の配列項目に累積する
                    IF ( lt_bm_support( ln_chk_cnt ).bm_type = cv_bm1_type ) THEN
                      -- 既存売価有り
                      ln_row_flg := cn_two;
                      -- 現在の配列へ累積
                      ln_sup_cnt := ln_chk_cnt;
                      -- ループEXIT
                      EXIT;
                    END IF;
                  END LOOP bm_rcpt_type60_chk_loop;
                END IF;
                ----------------------------------------------------------
                -- 配列設定
                ----------------------------------------------------------
                -- 初回実行時
                IF ( ln_row_flg = cn_zero ) THEN
                  -- 配列初期値セット
                  ln_sup_cnt := cn_zero;
                -- 一致しない場合
                ELSIF ( ln_row_flg = cn_one ) THEN
                  -- 配列を拡張
                  ln_sup_cnt := lt_bm_support.LAST + 1;
                END IF;
                -------------------------------------------------
                -- 計算結果退避
                -------------------------------------------------
                -- 支払区分：BM1
                lt_bm_support( ln_sup_cnt ).bm_type := cv_bm1_type;
                -- 仕入先ダミーコード
                lt_bm_support( ln_sup_cnt ).supplier_code := gv_pro_vendor;
                -- 仕入先サイトダミーコード
                lt_bm_support( ln_sup_cnt ).supplier_site_code := gv_pro_vendor_s;
                -- 計算条件
                lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type60;
                -- 納品数量
                lt_bm_support( ln_sup_cnt ).delivery_qty :=
                  NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                    sales_exp_ip_main_rec.dlv_quantity;
                -- 納品単位
                lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_ip_main_rec.dlv_uom_code;
                -- 売上金額
                lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                  NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                    sales_exp_ip_main_rec.sales_amount;
                -- 入金値引額
                lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt :=
                  NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt,cn_zero ) +
                    ln_rc_amount;
                -- 入金値引消費税額
                lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax :=
                  NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax,cn_zero ) +
                    ln_rc_amount_tax;
              --===============================================
              -- A-44.電気料（変動）の計算（一般）
              --===============================================
              -- 品目が電気料（変動）の場合
              ELSIF ( sales_exp_ip_main_rec.item_code = gv_pro_elec_ch ) THEN
                ----------------------------------------------------------
                -- 配列存在チェック
                ----------------------------------------------------------
                IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                  ln_row_flg := cn_one;
                END IF;
                ----------------------------------------------------------
                -- 電気料支払区分存在チェックループ
                ----------------------------------------------------------
                IF ( ln_row_flg = cn_one ) THEN
                  << bm_rcpt_type50_chk_loop >>
                  FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                    -- 支払区分が一致する場合は一致した時点の配列項目に累積する
                    IF ( lt_bm_support( ln_chk_cnt ).bm_type = cv_en1_type ) THEN
                      -- 既存売価有り
                      ln_row_flg := cn_two;
                      -- 現在の配列へ累積
                      ln_sup_cnt := ln_chk_cnt;
                      -- ループEXIT
                      EXIT;
                    END IF;
                  END LOOP bm_rcpt_type50_chk_loop;
                END IF;
                ----------------------------------------------------------
                -- 配列設定
                ----------------------------------------------------------
                -- 初回実行時
                IF ( ln_row_flg = cn_zero ) THEN
                  -- 配列初期値セット
                  ln_sup_cnt := cn_zero;
                -- 一致しない場合
                ELSIF ( ln_row_flg = cn_one ) THEN
                  -- 配列を拡張
                  ln_sup_cnt := lt_bm_support.LAST + 1;
                END IF;
                -------------------------------------------------
                -- 計算結果退避
                -------------------------------------------------
                -- 支払区分：EN1
                lt_bm_support( ln_sup_cnt ).bm_type := cv_en1_type;
                -- 仕入先ダミーコード
                lt_bm_support( ln_sup_cnt ).supplier_code := gv_pro_vendor;
                -- 仕入先サイトダミーコード
                lt_bm_support( ln_sup_cnt ).supplier_site_code := gv_pro_vendor_s;
                -- 計算条件
                lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type50;
                -- 売上金額
                lt_bm_support( ln_sup_cnt ).selling_amt_tax := cn_zero;
                -- 電気料(税込)
                lt_bm_support( ln_sup_cnt ).electric_amt_tax :=
                  NVL( lt_bm_support( ln_sup_cnt ).electric_amt_tax,cn_zero ) +
                    sales_exp_ip_main_rec.sales_amount;
                -- 電気料(税抜)
                lt_bm_support( ln_sup_cnt ).electric_amt_no_tax :=
                  NVL( lt_bm_support( ln_sup_cnt ).electric_amt_no_tax,cn_zero ) +
                    sales_exp_ip_main_rec.body_amount;
                -- 電気料消費税額
                lt_bm_support( ln_sup_cnt ).electric_tax_amt :=
                  NVL( lt_bm_support( ln_sup_cnt ).electric_tax_amt,cn_zero ) +
                    sales_exp_ip_main_rec.tax_amount;
                -- 電気料(変動)算出済
                lv_el_flg2 := cv_yes;
              END IF;
              --===============================================
              -- A-45.販売実績連携結果の更新（一般）
              --===============================================
              -- 販手販協計算終了日＝業務日付の場合は更新
              IF ( gv_sales_upd_flg = cv_yes ) THEN
                -- 入金値引率が設定されているまたは
                -- 入金値引率が設定されず、変動電気料の計算が行われた場合
                IF ( customer_ip_main_rec.discount_rate <> cn_zero ) OR
                   ( (customer_ip_main_rec.discount_rate = cn_zero ) AND ( lv_el_flg2 = cv_yes ) ) THEN
                  -- 販売実績連携結果更新
                  upd_sales_exp_lines_info(
                     ov_errbuf           => lv_errbuf                              -- エラーメッセージ
                    ,ov_retcode          => lv_retcode                             -- リターン・コード
                    ,ov_errmsg           => lv_errmsg                              -- ユーザー・エラーメッセージ
                    ,iv_if_status        => cv_yes                                 -- 手数料計算インタフェース済フラグ
                    ,iv_customer_code    => customer_ip_main_rec.customer_code     -- 顧客コード
                    ,iv_invoice_num      => sales_exp_ip_main_rec.invoice_num      -- 納品伝票番号
                    ,iv_invoice_line_num => sales_exp_ip_main_rec.invoice_line_num -- 納品明細番号
                  );
                -- 入金値引率が設定されていない場合
                ELSE
                  -- 販売実績連携不要更新
                  upd_sales_exp_lines_info(
                     ov_errbuf           => lv_errbuf                              -- エラーメッセージ
                    ,ov_retcode          => lv_retcode                             -- リターン・コード
                    ,ov_errmsg           => lv_errmsg                              -- ユーザー・エラーメッセージ
                    ,iv_if_status        => cv_yes                                 -- 手数料計算インタフェース済フラグ
                    ,iv_customer_code    => customer_ip_main_rec.customer_code     -- 顧客コード
                    ,iv_invoice_num      => sales_exp_ip_main_rec.invoice_num      -- 納品伝票番号
                    ,iv_invoice_line_num => sales_exp_ip_main_rec.invoice_line_num -- 納品明細番号
                  );
                END IF;
                -- ステータス警告判定
                IF ( lv_retcode = cv_status_warn ) THEN
                  -- 販売実績情報スキップ
                  RAISE sales_exp_err_expt;
                -- ステータスエラー判定
                ELSIF ( lv_retcode = cv_status_error ) THEN
                  -- 処理部共通エラー
                  RAISE global_process_expt;
                END IF;
              END IF;
            --*********************************************************************************************************
            -- 販売実績情報単位の処理 END
            --*********************************************************************************************************
            EXCEPTION
              ----------------------------------------------------------
              -- 顧客情報スキップ処理例外ハンドラ
              ----------------------------------------------------------
              WHEN customer_err_expt THEN
                -- 顧客情報のスキップ例外へ
                RAISE customer_err_expt;
              ----------------------------------------------------------
              -- 販売実績情報スキップ処理例外ハンドラ
              ----------------------------------------------------------
              WHEN sales_exp_err_expt THEN
                -- 警告件数をインクリメント
                gn_warning_cnt := gn_warning_cnt + cn_one;
              ----------------------------------------------------------
              -- 処理部共通例外ハンドラ
              ----------------------------------------------------------
              WHEN global_process_expt THEN
                -- 顧客情報の処理部共通例外へ
                RAISE global_process_expt;
            END;
          ----------------------------------------------------------
          -- 販売実績データループ
          ----------------------------------------------------------
          END LOOP sales_exp_main_loop;
          ----------------------------------------------------------
          -- 計算結果登録処理
          ----------------------------------------------------------
          -- 販売実績が存在しない場合は処理を行わない
          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
            --========================================================
            -- A-46.前回販手販協計算結果データの削除（一般）
            --========================================================
            -- 前回販手販協計算結果データの削除
            del_pre_bm_support_info(
               ov_errbuf        => lv_errbuf                                 -- エラーメッセージ
              ,ov_retcode       => lv_retcode                                -- リターン・コード
              ,ov_errmsg        => lv_errmsg                                 -- ユーザー・エラーメッセージ 
              ,iv_customer_code => customer_ip_main_rec.customer_code        -- 顧客コード
              ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- 締め日
            );
            -- ステータス警告判定
            IF ( lv_retcode = cv_status_warn ) THEN
              -- 顧客情報スキップ
              RAISE customer_err_expt;
            -- ステータスエラー判定
            ELSIF ( lv_retcode = cv_status_error ) THEN
              -- 処理部共通エラー
              RAISE global_process_expt;
            END IF;
            --=========================================================
            -- A-47.販手販協計算登録情報の付加情報設定（一般）
            --=========================================================
            << bm_support_all_loop >>
            FOR ln_vend_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
              -------------------------------------------------
              -- 計算結果退避
              -------------------------------------------------
              -- 拠点コード
              lt_bm_support( ln_vend_cnt ).base_code := sales_exp_ip_main_rec.sales_base_code;
              -- 担当者コード
              lt_bm_support( ln_vend_cnt ).emp_code := sales_exp_ip_main_rec.employee_code;
              -- 顧客【納品先】
              lt_bm_support( ln_vend_cnt ).delivery_cust_code := sales_exp_ip_main_rec.ship_cust_code;
              -- 顧客【請求先】
              lt_bm_support( ln_vend_cnt ).demand_to_cust_code := lv_bill_cust_code;
              -- 会計年度
              lt_bm_support( ln_vend_cnt ).acctg_year := lv_period_year;
              -- チェーン店コード
              lt_bm_support( ln_vend_cnt ).chain_store_code := customer_ip_main_rec.del_chain_code;
              -- 納品日年月
              lt_bm_support( ln_vend_cnt ).delivery_date :=
                TO_CHAR( lt_many_term( ln_term_cnt ).to_close_date,cv_format2 );
              -- 消費税区分
              lt_bm_support( ln_vend_cnt ).tax_class := sales_exp_ip_main_rec.con_tax_class;
              -- 税金コード
              lt_bm_support( ln_vend_cnt ).tax_code := sales_exp_ip_main_rec.tax_code;
              -- 消費税率
              lt_bm_support( ln_vend_cnt ).tax_rate := sales_exp_ip_main_rec.tax_rate;
              -- 支払条件
              lt_bm_support( ln_vend_cnt ).term_code := lt_many_term( ln_term_cnt ).to_term_name;
              -- 締め日
              lt_bm_support( ln_vend_cnt ).closing_date := lt_many_term( ln_term_cnt ).to_close_date;
              -- 支払予定日
              lt_bm_support( ln_vend_cnt ).expect_payment_date := ld_pay_work_date;
              -- 計算対象期間(From)＋１日
              ld_period_fm_date := lt_many_term( ln_term_cnt ).fm_close_date + cn_one;
              lt_bm_support( ln_vend_cnt ).calc_period_from := ld_period_fm_date; 
              -- 計算対象期間(To)
              lt_bm_support( ln_vend_cnt ).calc_period_to := lt_many_term( ln_term_cnt ).to_close_date;
              -- 連携ステータス(条件別販手販協)
              lt_bm_support( ln_vend_cnt ).cond_bm_if_status := cv_if_status2;
              -- 連携日(条件別販手販協)
              lt_bm_support( ln_vend_cnt ).cond_bm_if_date := NULL;
              -- 連携ステータス(販手残高)
              lt_bm_support( ln_vend_cnt ).bm_interface_status := cv_if_status2;
              -- 連携日(販手残高)
              lt_bm_support( ln_vend_cnt ).bm_interface_date := NULL;
              -- 販手販協計算終了日＝業務日付の場合
              IF ( gv_sales_upd_flg = cv_yes ) THEN
                -- 支払区分が電気料の場合
                IF ( lt_bm_support( ln_vend_cnt ).bm_type = cv_en1_type ) THEN
                  -- 連携ステータス(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                  -- 連携日(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                ELSE
                  -- 連携ステータス(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status0;
                  -- 連携日(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                END IF;
              -- 販手販協計算終了日＝業務日付でない場合
              ELSE
                -- 連携ステータス(AR)
                lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                -- 連携日(AR)
                lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
              END IF;
            END LOOP bm_support_all_loop;
            --=====================================================
            -- A-48.条件別販手販協計算データの登録（一般）
            --=====================================================
            ins_bm_support_info(
               ov_errbuf        => lv_errbuf                                 -- エラーメッセージ
              ,ov_retcode       => lv_retcode                                -- リターン・コード
              ,ov_errmsg        => lv_errmsg                                 -- ユーザー・エラーメッセージ 
              ,iv_vendor_type   => cv_vendor_type1                           -- ベンダー区分：一般
              ,id_fm_close_date => lt_many_term( ln_term_cnt ).fm_close_date -- 前回締め日
              ,id_to_close_date => lt_many_term( ln_term_cnt ).to_close_date -- 今回締め日
              ,it_bm_support    => lt_bm_support                             -- 販手販協計算登録情報
            );
            -- ステータスエラー判定
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            -- 正常処理件数をインクリメント
            gn_normal_cnt := gn_normal_cnt + lt_bm_support.COUNT;
          END IF;
        -------------------------------------------------
        -- 複数支払条件ループ
        -------------------------------------------------
        END LOOP many_term_all_loop;
        -------------------------------------------------
        -- COMMIT判定
        -------------------------------------------------
        IF ( lt_bm_support.COUNT <> cn_zero ) THEN
          -- 顧客単位にCOMMIT
          COMMIT;
        END IF;
      --***************************************************************************************************************
      -- 顧客情報単位の処理 END
      --***************************************************************************************************************
      EXCEPTION
        ----------------------------------------------------------
        -- 顧客情報スキップ処理（処理対象外顧客）例外ハンドラ
        ----------------------------------------------------------
        WHEN customer_chk_expt THEN
          -- 顧客情報をスキップ
          NULL;
        ----------------------------------------------------------
        -- 顧客情報スキップ処理例外ハンドラ
        ----------------------------------------------------------
        WHEN customer_err_expt THEN
          -- 警告件数をインクリメント
          gn_warning_cnt := gn_warning_cnt + cn_one;
        ----------------------------------------------------------
        -- 処理部共通例外ハンドラ
        ----------------------------------------------------------
        WHEN global_process_expt THEN
          -- submainの処理部共通例外へ
          RAISE global_process_expt;
      END;
    ----------------------------------------------------------
    -- 顧客情報ループ
    ----------------------------------------------------------
    END LOOP customer_main_loop3;
    --=====================================================
    -- 終了判定
    --=====================================================
    -- 警告が発生している場合
    IF ( gn_warning_cnt <> cn_zero ) THEN
      -- 警告終了
      ov_retcode := cv_status_warn;
    ELSE
      -- 正常終了
      ov_retcode := cv_status_normal;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 処理部共通例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      IF ( lv_errmsg IS NULL ) THEN
        -- メッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_00100
                        ,iv_token_name1  => cv_tkn_errmsg
                        ,iv_token_value1 => SUBSTRB( SQLERRM,1,5000 )
                      );
        -- メッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- 出力区分
                        ,iv_message  => lv_out_msg      -- メッセージ
                        ,in_new_line => cn_zero         -- 改行
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
        ov_retcode := cv_status_error;
      ELSE
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
        ov_retcode := cv_status_error;
      END IF;
      -- エラー件数をインクリメント
      gn_error_cnt := gn_error_cnt + cn_one;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      IF ( lv_errmsg IS NULL ) THEN
        -- メッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_00101
                        ,iv_token_name1  => cv_tkn_errmsg
                        ,iv_token_value1 => SUBSTRB( SQLERRM,1,5000 )
                      );
        -- メッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- 出力区分
                        ,iv_message  => lv_out_msg      -- メッセージ
                        ,in_new_line => cn_zero         -- 改行
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
      ELSE
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
      END IF;
      -- エラー件数をインクリメント
      gn_error_cnt := gn_error_cnt + cn_one;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      IF ( lv_errmsg IS NULL ) THEN
        -- メッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_00100
                        ,iv_token_name1  => cv_tkn_errmsg
                        ,iv_token_value1 => SUBSTRB( SQLERRM,1,5000 )
                      );
        -- メッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- 出力区分
                        ,iv_message  => lv_out_msg      -- メッセージ
                        ,in_new_line => cn_zero         -- 改行
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
      ELSE
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
      END IF;
      -- エラー件数をインクリメント
      gn_error_cnt := gn_error_cnt + cn_one;
  --
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
     errbuf       OUT VARCHAR2 -- エラーメッセージ
    ,retcode      OUT VARCHAR2 -- リターン・コード
    ,iv_proc_date IN  VARCHAR2 -- 業務日付
    ,iv_proc_type IN  VARCHAR2 -- 実行区分
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf  VARCHAR2(5000); -- エラーメッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    lv_errmsg  VARCHAR2(5000); -- ユーザー・エラーメッセージ
    lv_out_msg VARCHAR2(2000); -- メッセージ
    lb_retcode BOOLEAN;        -- メッセージ戻り値
    -- メッセージ退避
    lv_message_code VARCHAR2(5000); -- 処理終了メッセージ
  --
  BEGIN
  --
    --===============================================
    -- 初期化
    --===============================================
    lv_out_msg := NULL;
    --===============================================
    -- コンカレントヘッダ出力
    --===============================================
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --===============================================
    -- サブメイン処理
    --===============================================
    submain(
       ov_errbuf    => lv_errbuf    -- エラーメッセージ
      ,ov_retcode   => lv_retcode   -- リターン・コード
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラーメッセージ
      ,iv_proc_date => iv_proc_date -- 業務日付
      ,iv_proc_type => iv_proc_type -- 実行区分
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_errmsg       -- メッセージ
                      ,in_new_line => cn_one          -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.log    -- 出力区分
                      ,iv_message  => lv_errbuf       -- メッセージ
                      ,in_new_line => cn_one          -- 改行
                    );
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      -- 警告時改行出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => NULL            -- メッセージ
                      ,in_new_line => cn_one          -- 改行
                    );
    END IF;
    --===============================================
    -- A-50.終了処理
    --===============================================
    -------------------------------------------------
    -- 1.販売実績取得エラーメッセージ出力
    -------------------------------------------------
    IF ( lv_retcode = cv_status_normal ) AND
       ( gn_target_cnt = cn_zero ) THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_ap_type_xxcok
                      ,iv_name        => cv_prmmsg_10405
                    );
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- 出力区分
                      ,iv_message  => lv_out_msg      -- メッセージ
                      ,in_new_line => cn_one          -- 改行
                    );
    END IF;
    -------------------------------------------------
    -- 2.対象件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- 出力区分
                    ,iv_message  => lv_out_msg      -- メッセージ
                    ,in_new_line => cn_zero         -- 改行
                  );
    -------------------------------------------------
    -- 3.成功件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- 出力区分
                    ,iv_message  => lv_out_msg      -- メッセージ
                    ,in_new_line => cn_zero         -- 改行
                  );
    -------------------------------------------------
    -- 4.エラー件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- 出力区分
                    ,iv_message  => lv_out_msg      -- メッセージ
                    ,in_new_line => cn_zero         -- 改行
                  );
    -------------------------------------------------
    -- 5.スキップ件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90003
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_warning_cnt )
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- 出力区分
                    ,iv_message  => lv_out_msg      -- メッセージ
                    ,in_new_line => cn_one          -- 改行
                  );
    -------------------------------------------------
    -- 6.終了メッセージ出力
    -------------------------------------------------
    -- 終了メッセージ判断
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => lv_message_code
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- 出力区分
                    ,iv_message  => lv_out_msg      -- メッセージ
                    ,in_new_line => cn_zero         -- 改行
                  );
    -- ステータスセット
    retcode := lv_retcode;
    -- ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 共通関数例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
  --
  END main;
  --
END XXCOK014A01C;
/
