CREATE OR REPLACE PACKAGE BODY XXCOS013A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS013A01C (body)
 * Description      : 販売実績情報より仕訳情報を作成し、AR請求取引に連携する処理
 * MD.050           : ARへの販売実績データ連携 MD050_COS_013_A01
 * Version          : 1.21
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
 *  2009/03/25    1.4   K.KIN            T1_0015、T1_0019、T1_0052、
 *                                       T1_0053、T1_0057、T1_0144対応
 *  2009/04/08    1.5   K.KIN            T1_0407
 *  2009/04/09    1.6   K.KIN            T1_0423
 *  2009/04/09    1.7   K.KIN            T1_0436
 *  2009/04/13    1.8   K.KIN            T1_0497
 *  2009/04/13    1.9   K.KIN            T1_0054,T1_0186,T1_0456,T1_0467
 *  2009/04/16    1.10  K.KIN            T1_0587
 *  2009/04/17    1.11  K.KIN            T1_0328
 *  2009/04/21    1.12  K.KIN            T1_0659
 *  2009/04/22    1.13  K.KIN            T1_0116
 *  2009/05/07    1.14  K.KIN            T1_0908
 *  2009/05/07    1.15  K.KIN            T1_0914、T1_0915
 *  2009/05/11    1.16  K.KIN            T1_0453、T1_0938
 *  2009/05/12    1.17  K.KIN            T1_0693
 *  2009/05/14    1.18  K.KIN            T1_0795
 *  2009/05/15    1.19  K.KIN            T1_0776
 *  2009/05/20    1.20  K.KIN            T1_1078
 *  2009/07/27    1.21  K.Kiriu          [0000829]PT対応
 *  2009/07/30    1.21  M.Sano           [0000829]PT追加対応
 *                                       [0000899]伝票入力者取得SQL条件追加
 *
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
  global_card_inf_expt      EXCEPTION;         -- カード会社取得エラー
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
  cv_employee_code_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12786'; -- 従業員コード
  cv_header_id_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12787'; -- ヘッダID
  cv_order_no_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00131'; -- 伝票番号
  cv_skip_rec_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12788'; -- スキップ件数メッセージ
  cv_term_id_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12778'; -- 支払条件ID取得エラー
  cv_tax_in_msg             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12779'; -- 内税コード取得エラー
  cv_tax_out_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12780'; -- 外税コード取得エラー
  cv_tkn_user_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00051'; -- 従業員マスタ
  cv_card_comp_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12781'; -- カード会社が未設定
  cv_cust_num_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12782'; -- カード会社のデータが顧客追加情報にない
  cv_receiv_base_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12783'; -- 入金拠点が未設定
  cv_org_sys_id_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12784'; -- 顧客所在地参照IDが未設定
  cv_jour_no_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12785'; -- 仕訳パターンない
  cv_receipt_id_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12789'; -- 支払方法が未設定
  cv_tax_no_msg             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12790'; -- 対象外税金コード取得エラー
/* 2009/07/30 Ver1.21 Add Start */
  cv_goods_prod_cls         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12791'; -- XXCOI:商品製品区分カテゴリセット名
  cv_no_cate_set_id_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12792'; -- カテゴリセットID取得エラー
  cv_no_cate_id_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12793'; -- カテゴリID取得エラーメッセージ
/* 2009/07/30 Ver1.21 Add End   */
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
  cv_tkn_cust_code          CONSTANT  VARCHAR2(20) := 'CUST_CODE';       -- 顧客コード
  cv_tkn_card_company       CONSTANT  VARCHAR2(20) := 'CARD_COMPANY';    -- カード会社
  cv_tkn_payment_term1      CONSTANT  VARCHAR2(20) := 'PAYMENT_TERM1';   -- 支払条件１
  cv_tkn_payment_term2      CONSTANT  VARCHAR2(20) := 'PAYMENT_TERM2';   -- 支払条件２
  cv_tkn_payment_term3      CONSTANT  VARCHAR2(20) := 'PAYMENT_TERM3';   -- 支払条件３
  cv_tkn_procedure_name     CONSTANT  VARCHAR2(20) := 'PROCEDURE_NAME';  -- プロシージャ名
  cv_tkn_invoice_cls        CONSTANT  VARCHAR2(20) := 'INVOICE_CLS';     -- 伝票区分
  cv_tkn_prod_cls           CONSTANT  VARCHAR2(20) := 'PROD_CLS';        -- 品目区分
  cv_tkn_gyotai_sho         CONSTANT  VARCHAR2(20) := 'GYOTAI_SHO';      -- 業態小分類
  cv_tkn_sale_cls           CONSTANT  VARCHAR2(20) := 'SALE_CLS';        -- カード売り区分
  cv_tkn_red_black_flag     CONSTANT  VARCHAR2(20) := 'RED_BLACK_FLAG';  -- 赤黒フラグ
  cv_tkn_header_id          CONSTANT  VARCHAR2(20) := 'HEADER_ID';       -- ヘッダID
  cv_tkn_order_no           CONSTANT  VARCHAR2(20) := 'ORDER_NO';        -- 伝票番号
--
  -- フラグ・区分定数
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';               -- フラグ値:Y
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';               -- フラグ値:N
  cv_card_class             CONSTANT  VARCHAR2(1)  := '1';               -- カード売り区分：カード= 1
  cv_cash_class             CONSTANT  VARCHAR2(1)  := '0';               -- カード売り区分：現金= 0
  cn_min_day                CONSTANT  NUMBER       := 1;                 -- 支払条件マスタの初日
  cn_max_day                CONSTANT  NUMBER       := 32;                -- 支払条件マスタの最大日
  cv_goods_prod_syo         CONSTANT  VARCHAR2(1)  := '1';               -- 品目区分：商品= 1
  cv_goods_prod_sei         CONSTANT  VARCHAR2(1)  := '2';               -- 品目区分：製品= 2
  cv_site_code              CONSTANT  VARCHAR2(10) := 'BILL_TO';         -- サイトコード
  cn_ship_flg_on            CONSTANT  NUMBER       := 1;                 -- 出荷先顧客フラグがON
  cn_ship_flg_off           CONSTANT  NUMBER       := 0;                 -- 出荷先顧客フラグがOFF
/* 2009/07/27 Ver1.21 Add Start */
  cv_cust_relate_status     CONSTANT  VARCHAR2(1)  := 'A';               -- 顧客関連ステータス(有効)
  cv_cust_bill              CONSTANT  VARCHAR2(1)  := '1';               -- 関連分類(請求)
  cv_cust_cash              CONSTANT  VARCHAR2(1)  := '2';               -- 関連分類(入金)
  cv_cust_class_uri         CONSTANT  VARCHAR2(2)  := '14';              -- 顧客区分(売掛金管理先顧客)
  cv_cust_class_cust        CONSTANT  VARCHAR2(2)  := '10';              -- 顧客区分(顧客)
  cv_cust_class_ue          CONSTANT  VARCHAR2(2)  := '12';              -- 顧客区分(上様)
/* 2009/07/27 Ver1.21 Add End   */
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
  cv_out_tax_cls            CONSTANT  VARCHAR2(50) := 'XXCOS1_CONS_TAX_NO_APPLICABLE';  -- 消費税区分(対象外)
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
  cv_hold                  CONSTANT  VARCHAR2(4)   := 'HOLD';                           -- ヘッダーDFF7(予備１)
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
  cv_date_format_on_sep       CONSTANT VARCHAR2(20) := 'YYYY/MM/DD';
  cv_date_format_yyyymm       CONSTANT VARCHAR2(8)  := 'YYYY/MM/';
  cv_substr_st                CONSTANT NUMBER       := 7;
  cv_substr_cnt               CONSTANT NUMBER       := 2;
/* 2009/07/27 Ver1.21 Add Start */
--
  -- 抽出条件用
  ct_lang                  CONSTANT  fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語
  cd_sysdate               CONSTANT  DATE           := SYSDATE;                          -- システム日付
/* 2009/07/27 Ver1.21 Add End   */
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
    , rcrm_receipt_id           ra_cust_receipt_methods.receipt_method_id%TYPE      -- 顧客支払方法ID
    , xchv_cust_id_s            xxcos_cust_hierarchy_v.ship_account_id%TYPE         -- 出荷先顧客ID
    , xchv_cust_id_b            xxcos_cust_hierarchy_v.bill_account_id%TYPE         -- 請求先顧客ID
    , xchv_cust_number_b        xxcos_cust_hierarchy_v.bill_account_number%TYPE     -- 請求先顧客コード
    , xchv_cust_id_c            xxcos_cust_hierarchy_v.cash_account_id%TYPE         -- 入金先顧客ID
    , hcss_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- 顧客所在地参照ID(出荷先)
    , hcsb_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- 顧客所在地参照ID(請求先)
    , hcsc_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- 顧客所在地参照ID(入金先)
    , xchv_bill_pay_id          xxcos_cust_hierarchy_v.bill_payment_term_id%TYPE    -- 支払条件ID
    , xchv_bill_pay_id2         xxcos_cust_hierarchy_v.bill_payment_term2%TYPE      -- 支払条件2
    , xchv_bill_pay_id3         xxcos_cust_hierarchy_v.bill_payment_term3%TYPE      -- 支払条件3
    , xchv_tax_round            xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE     -- 税金－端数処理
    , xseh_rowid                ROWID                                               -- ROWID
    , oif_trx_number            ra_interface_lines_all.trx_number%TYPE              -- AR取引番号
    , oif_dff4                  ra_interface_lines_all.interface_line_attribute4%TYPE -- DFF4：伝票No＋シーケンス
    , oif_tax_dff4              ra_interface_lines_all.interface_line_attribute4%TYPE -- DFF4税金用：伝票No＋シーケンス
    , line_id                   xxcos_sales_exp_lines.sales_exp_line_id%TYPE          -- 販売実績明細番号
    , card_receiv_base          xxcos_sales_exp_headers.receiv_base_code%TYPE         -- カードVD入金拠点コード
    , pay_cust_number           xxcos_cust_hierarchy_v.bill_account_number%TYPE       -- 支払条件用請求先顧客コード
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
    , attribute2                VARCHAR2(30)                                        -- 請求書発行区分
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
  TYPE g_v_od_data_ttype IS TABLE OF gr_sales_exp_rec INDEX BY VARCHAR(100);

  gt_sales_exp_tbl              g_sales_exp_ttype;                                  -- 販売実績データ
  gt_sales_exp_tbl2             g_sales_exp_ttype;                                  -- 販売実績データ
  gt_sales_skip_tbl             g_sales_exp_ttype;                                  -- 販売実績データ
  gt_sales_norm_tbl             g_sales_exp_ttype;                                  -- 販売実績非大手量販店データ
  gt_sales_norm_tbl2            g_sales_exp_ttype;                                  -- 販売実績非大手量販店データ（併用展開）
  gt_sales_bulk_tbl             g_sales_exp_ttype;                                  -- 販売実績大手量販店データ
  gt_sales_bulk_tbl2            g_sales_exp_ttype;                                  -- 販売実績大手量販店データ（併用展開）
  gt_sales_norm_order_tbl       g_v_od_data_ttype;                                  -- 販売実績非大手量販店データ(ソート)
  gt_sales_bulk_order_tbl       g_v_od_data_ttype;                                  -- 販売実績大手量販店データ(ソート)
--
--*** MIYATA DELETE START ***
gt_norm_card_tbl              g_sales_exp_ttype;                                  -- 販売実績非大手量販店カードデータ
gt_bulk_card_tbl              g_sales_exp_ttype;                                  -- 販売実績大手量販店カードデータ
--*** MIYATA DELETE END   ***
--
  TYPE g_sales_h_ttype   IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  gt_sales_h_tbl                     g_sales_h_ttype;                               -- 販売実績フラグ更新用
--
  TYPE g_jour_cls_ttype  IS TABLE OF gr_jour_cls_rec INDEX BY BINARY_INTEGER;
  gt_jour_cls_tbl                    g_jour_cls_ttype;                              -- 仕訳パターン
--
  TYPE g_ar_oif_ttype    IS TABLE OF ra_interface_lines_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ar_interface_tbl                g_ar_oif_ttype;                                -- AR請求取引OIF
  gt_ar_interface_tbl1               g_ar_oif_ttype;                                -- AR請求取引OIF
--
  TYPE g_ar_dis_ttype    IS TABLE OF ra_interface_distributions_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ar_dis_tbl                      g_ar_dis_ttype;                                -- AR会計配分OIF
  gt_ar_dis_tbl1                     g_ar_dis_ttype;                                -- AR会計配分OIF
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
/* 2009/07/30 Ver1.21 Add Start */
  gv_goods_prod_cls                   VARCHAR2(30);                                 -- 商品製品区分カテゴリセット名
  gt_category_id                      mtl_categories_b.category_id%TYPE;            -- カテゴリID
  gt_category_set_id                  mtl_category_sets_tl.category_set_id%TYPE;    -- カテゴリセットID
/* 2009/07/30 Ver1.21 Add End   */
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
  gn_warn_flag                        VARCHAR2(1) DEFAULT 'N';                      -- 警告フラグ
  gn_skip_cnt                         NUMBER DEFAULT 0;                             -- スキップ件数
  gv_skip_flag                        VARCHAR2(1);                                  -- スキップフラグ
  gt_exp_tax_cls                      fnd_lookup_values.meaning%TYPE;               -- 消費税区分(対象外)
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
/* 2009/07/27 Ver1.21 Mod Start */
--      AND   flvl.language             = USERENV( 'LANG' )
      AND   flvl.language             = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
    ct_busi_emp_cd           CONSTANT VARCHAR2(30) := 'XXCOS1_BIZ_MAN_DEPT_EMP';
                                                               -- XXCOS:業務管理部担当者
    ct_dis_item_cd           CONSTANT VARCHAR2(30) := 'XXCOS1_DISCOUNT_ITEM_CODE';
                                                               -- XXCOS:売上値引品目
/* 2009/07/30 Ver1.21 Add Start */
    ct_goods_prod_cls        CONSTANT VARCHAR2(30) := 'XXCOI1_GOODS_PRODUCT_CLASS';
                                                               -- XXCOI:商品製品区分カテゴリセット名
/* 2009/07/30 Ver1.21 Add End   */
--
    -- *** ローカル変数 ***
    lv_profile_name          VARCHAR2(50);                     -- プロファイル名
/* 2009/07/30 Ver1.21 Add Start */
    lt_category_set_id       mtl_category_sets_tl.category_set_id%TYPE;  -- カテゴリセットID
/* 2009/07/30 Ver1.21 Add End   */
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
    gv_busi_emp_cd := FND_PROFILE.VALUE( ct_busi_emp_cd );
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
/* 2009/07/30 Ver1.21 Add Start */
    -- ===============================
    -- XXCOS：商品製品区分カテゴリセット名
    -- ===============================
    gv_goods_prod_cls := FND_PROFILE.VALUE( ct_goods_prod_cls );
    -- プロファイルが取得できない場合
    IF ( gv_goods_prod_cls IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_goods_prod_cls                           -- メッセージID
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
/* 2009/07/30 Ver1.21 Add End */
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
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
    -- 消費税区分(対象外)
    BEGIN
      SELECT flvl.meaning
      INTO   gt_exp_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_out_tax_cls
        AND  flvl.enabled_flag           = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    -- クイックコード取得出来ない場合
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_tax_no_msg
                        , iv_token_name1   => cv_tkn_lookup_type
                        , iv_token_value1  => cv_out_tax_cls
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
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language                  = USERENV( 'LANG' )
        AND  flvl.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language                  = USERENV( 'LANG' )
        AND  flvl.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language                  = USERENV( 'LANG' )
        AND  flvl.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
/* 2009/07/30 Ver1.21 Add Start */
--
    -- カテゴリセットIDを取得
    BEGIN
      SELECT mcst.category_set_id  -- カテゴリセットID
      INTO   gt_category_set_id
      FROM   mtl_category_sets_tl mcst
/* 2009/07/27 Ver1.21 Mod Start */
--      WHERE  mcst.language          = USERENV( 'LANG' )
      WHERE  mcst.language          = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
      AND    mcst.category_set_name = gv_goods_prod_cls
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- カテゴリセットID取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_no_cate_set_id_msg
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --カテゴリIDを取得
    BEGIN
      SELECT mcb.category_id       -- カテゴリID
      INTO   gt_category_id
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b    mcb
      WHERE  mcsb.category_set_id = gt_category_set_id
      AND    mcsb.structure_id    = mcb.structure_id
      AND    mcb.segment1         = cv_goods_prod_syo
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- カテゴリID取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_no_cate_id_msg
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
/* 2009/07/30 Ver1.21 Add End   */
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
    lv_table_name   VARCHAR2(255);                                     -- テーブル名
    ln_bulk_idx     NUMBER DEFAULT 0;                                  -- 非大手量販店インデックス
    ln_norm_idx     NUMBER DEFAULT 0;                                  -- 大手量販店インデックス
    ln_start_idx    NUMBER DEFAULT 1;                                  -- 開始位置
    ln_end_idx      NUMBER DEFAULT 1;                                  -- 終了位置
    ln_key_bef      NUMBER DEFAULT 1;                                  -- 比較キー
    ln_pure_amount  NUMBER DEFAULT 0;                                  -- カードレコードの本体金額
    ln_tax_amount   NUMBER DEFAULT 0;                                  -- カードレコードの消費税金額
    lv_card_company VARCHAR2(9);                                       -- 顧客追加情報カード会社
    ln_sale_idx     NUMBER DEFAULT 0;                                  -- 販売実績インデックス
    ln_skip_idx     NUMBER DEFAULT 0;                                  -- スキップインデックス
    lv_sale_flag    VARCHAR2(1);                                       -- フラグ
    lv_skip_flag    VARCHAR2(1);                                       -- フラグ
    lt_xchv_cust_id              xxcos_cust_hierarchy_v.bill_account_id%TYPE;         -- 入金先顧客ID
    lt_receiv_base_code          xxcos_sales_exp_headers.receiv_base_code%TYPE ;      -- 入金拠点コード
    lt_hcsc_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE;       -- 顧客所在地参照ID(入金先)
    lt_skip_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    --  販売実績ヘッダID
    lt_receipt_id                ra_cust_receipt_methods.receipt_method_id%TYPE;      -- 顧客支払方法ID
    lt_bill_pay_id               xxcos_cust_hierarchy_v.bill_payment_term_id%TYPE;    -- 支払条件ID
    lt_bill_pay_id2              xxcos_cust_hierarchy_v.bill_payment_term2%TYPE;      -- 支払条件2
    lt_bill_pay_id3              xxcos_cust_hierarchy_v.bill_payment_term3%TYPE;      -- 支払条件3
    lv_heiyou_card_flag          VARCHAR2(1);                                         -- フラグ
    lv_heiyou_cash_flag          VARCHAR2(1);                                         -- フラグ
--
    -- *** ローカル・カーソル (販売実績データ抽出)***
    CURSOR sales_data_cur
    IS
      SELECT
/* 2009/07/27 Ver1.21 Mod Start */
--             xseh.sales_exp_header_id          sales_exp_header_id     -- 販売実績ヘッダID
--           , xseh.dlv_invoice_number           dlv_invoice_number      -- 納品伝票番号
--           , xseh.dlv_invoice_class            dlv_invoice_class       -- 納品伝票区分
--           , xseh.cust_gyotai_sho              cust_gyotai_sho         -- 業態小分類
--           , xseh.delivery_date                delivery_date           -- 納品日
--           , xseh.inspect_date                 inspect_date            -- 検収日
--           , xseh.ship_to_customer_code        ship_to_customer_code   -- 顧客【納品先】
--           , xseh.tax_code                     tax_code                -- 税金コード
--           , xseh.tax_rate                     tax_rate                -- 消費税率
--           , xseh.consumption_tax_class        consumption_tax_class   -- 消費税区分
--           , xseh.results_employee_code        results_employee_code   -- 成績計上者コード
--           , xseh.sales_base_code              sales_base_code         -- 売上拠点コード
--           , xseh.receiv_base_code             receiv_base_code        -- 入金拠点コード
--           , xseh.create_class                 create_class            -- 作成元区分
--           , NVL( xseh.card_sale_class, cv_cash_class )
--                                               card_sale_class         -- カード売り区分
             xsehv.sales_exp_header_id          sales_exp_header_id    -- 販売実績ヘッダID
           , xsehv.dlv_invoice_number           dlv_invoice_number     -- 納品伝票番号
           , xsehv.dlv_invoice_class            dlv_invoice_class      -- 納品伝票区分
           , xsehv.cust_gyotai_sho              cust_gyotai_sho        -- 業態小分類
           , xsehv.delivery_date                delivery_date          -- 納品日
           , xsehv.inspect_date                 inspect_date           -- 検収日
           , xsehv.ship_to_customer_code        ship_to_customer_code  -- 顧客【納品先】
           , xsehv.tax_code                     tax_code               -- 税金コード
           , xsehv.tax_rate                     tax_rate               -- 消費税率
           , xsehv.consumption_tax_class        consumption_tax_class  -- 消費税区分
           , xsehv.results_employee_code        results_employee_code  -- 成績計上者コード
           , xsehv.sales_base_code              sales_base_code        -- 売上拠点コード
           , xsehv.receiv_base_code             receiv_base_code       -- 入金拠点コード
           , xsehv.create_class                 create_class           -- 作成元区分
           , NVL( xsehv.card_sale_class, cv_cash_class )
                                               card_sale_class         -- カード売り区分
/* 2009/07/27 Ver1.21 Mod End   */
           , xsel.dlv_invoice_line_number      dlv_inv_line_no         -- 納品明細番号
           , xsel.item_code                    item_code               -- 品目コード
           , xsel.sales_class                  sales_class             -- 売上区分
           , xsel.red_black_flag               red_black_flag          -- 赤黒フラグ
/* 2009/07/27 Ver1.21 Mod Start */
--           , CASE 
--               WHEN mcavd.subinventory_code IS NULL THEN cv_goods_prod_sei
--               ELSE                            xgpc.goods_prod_class_code
--             END AS                            goods_prod_cls          -- 品目区分（製品・商品）
           , ( CASE
/* 2009/07/30 Ver1.21 Mod Start */
--                 WHEN (
--                        SELECT COUNT(1)
--                        FROM   mtl_category_accounts_v  mcav
--                        WHERE  mcav.subinventory_code = xsel.ship_from_subinventory_code
--                        AND    ROWNUM                 = 1
--                      ) = 0
                 WHEN NOT EXISTS (
                        SELECT 1
                        FROM   mtl_category_accounts  mca
                        WHERE  mca.category_id        = gt_category_id
                        AND    mca.organization_id    = gv_org_id
                        AND    mca.subinventory_code  = xsel.ship_from_subinventory_code
                        )
/* 2009/07/30 Ver1.21 Mod End   */
                 THEN
                   cv_goods_prod_sei
                 ELSE
                   (
                     SELECT  mcb.segment1           goods_prod_class_code
                     FROM    mtl_system_items_b     msib  --品目マスタ
                            ,mtl_item_categories    mic   --品目カテゴリマスタ
                            ,mtl_categories_b       mcb   --カテゴリマスタ
                     WHERE   msib.organization_id   = gv_org_id
                     AND     msib.segment1          = xsel.item_code
                     AND     msib.enabled_flag      = cv_y_flag
                     AND     cd_sysdate             BETWEEN NVL( msib.start_date_active, cd_sysdate )
                                                    AND     NVL( msib.end_date_active, cd_sysdate)
                     AND     msib.organization_id   = mic.organization_id
                     AND     msib.inventory_item_id = mic.inventory_item_id
                     AND     mic.category_set_id    = gt_category_set_id
                     AND     mic.category_id        = mcb.category_id
                     AND     (
                               mcb.disable_date IS NULL
                               OR
                               mcb.disable_date > cd_sysdate
                             )
                     AND     mcb.enabled_flag       = cv_y_flag
                     AND     cd_sysdate             BETWEEN NVL( mcb.start_date_active, cd_sysdate ) 
                                                    AND     NVL( mcb.end_date_active, cd_sysdate )
                   )
               END
             )                                 goods_prod_cls          -- 品目区分（製品・商品）
/* 2009/07/27 Ver1.21 Mod End   */
           , xsel.pure_amount                  pure_amount             -- 本体金額
           , xsel.tax_amount                   tax_amount              -- 消費税額
           , NVL( xsel.cash_and_card, 0 )      cash_and_card           -- 現金・カード併用額
/* 2009/07/27 Ver1.21 Mod Start */
--           , rcrmv.receipt_method_id           rcrm_receipt_id         -- 顧客支払方法ID
--           , xchv.ship_account_id              xchv_cust_id_s          -- 出荷先顧客ID
--           , xchv.bill_account_id              xchv_cust_id_b          -- 請求先顧客ID
--           , xchv.bill_account_number          xchv_cust_number_b      -- 請求先顧客コード
--           , xchv.cash_account_id              xchv_cust_id_c          -- 入金先顧客ID
           , (
               SELECT rcrm.receipt_method_id
               FROM   ra_cust_receipt_methods  rcrm
                     ,hz_cust_site_uses_all    scsua
               WHERE  rcrm.customer_id        = xsehv.bill_account_id
               AND    rcrm.primary_flag       = cv_y_flag
               AND    rcrm.site_use_id        = scsua.site_use_id
               AND    gd_process_date         BETWEEN NVL( rcrm.start_date, gd_process_date )
                                                  AND NVL( rcrm.end_date, gd_process_date )
               AND    scsua.cust_acct_site_id = hcsb.cust_acct_site_id
               AND    scsua.site_use_code     = cv_site_code
               AND    ROWNUM                  = 1
             )                                 rcrm_receipt_id         -- 顧客支払方法ID
           , xsehv.ship_account_id             xchv_cust_id_s          -- 出荷先顧客ID
           , xsehv.bill_account_id             xchv_cust_id_b          -- 請求先顧客ID
           , xsehv.bill_account_number         xchv_cust_number_b      -- 請求先顧客コード
           , xsehv.cash_account_id             xchv_cust_id_c          -- 入金先顧客ID
/* 2009/07/27 Ver1.21 Mod End   */
           , hcss.cust_acct_site_id            hcss_org_sys_id         -- 顧客所在地参照ID（出荷先）
           , hcsb.cust_acct_site_id            hcsb_org_sys_id         -- 顧客所在地参照ID（請求先）
           , hcsc.cust_acct_site_id            hcsc_org_sys_id         -- 顧客所在地参照ID（入金先）
/* 2009/07/27 Ver1.21 Mod Start */
--           , xchv.bill_payment_term_id         xchv_bill_pay_id        -- 支払条件ID
--           , xchv.bill_payment_term2           xchv_bill_pay_id2       -- 支払条件2
--           , xchv.bill_payment_term3           xchv_bill_pay_id3       -- 支払条件3
--           , xchv.bill_tax_round_rule          xchv_tax_round          -- 税金－端数処理
--           , xseh.rowid                        xseh_rowid              -- ROWID
           , hcub.payment_term_id               xchv_bill_pay_id       -- 支払条件ID
           , hcub.attribute2                    xchv_bill_pay_id2      -- 支払条件2
           , hcub.attribute3                    xchv_bill_pay_id3      -- 支払条件3
           , hcub.tax_rounding_rule             xchv_tax_round         -- 税金－端数処理
           , xsehv.xseh_rowid                  xseh_rowid              -- ROWID
/* 2009/07/27 Ver1.21 Mod End   */
           , NULL                              oif_trx_number          -- AR取引番号
           , NULL                              oif_dff4                -- DFF4：伝票No＋シーケンス
           , NULL                              oif_tax_dff4            -- DFF4税金用：伝票No＋シーケンス
           , xsel.sales_exp_line_id            line_id                 -- 販売実績明細番号
/* 2009/07/27 Ver1.21 Mod Start */
--           , xseh.receiv_base_code             card_receiv_base        -- カード入金拠点コード
--           , xchv.bill_account_number          pay_cust_number         -- 支払条件用請求先顧客コード
           , xsehv.receiv_base_code            card_receiv_base        -- カード入金拠点コード
           , xsehv.bill_account_number         pay_cust_number         -- 支払条件用請求先顧客コード
/* 2009/07/27 Ver1.21 Mod End   */
      FROM
             xxcos_sales_exp_headers           xseh                    -- 販売実績ヘッダテーブル(ロック用)
/* 2009/07/27 Ver1.21 Add Start */
           , (
               -- ①入金先顧客＆請求先顧客－出荷先顧客
               SELECT /*+
                          LEADING (xseh) 
                          INDEX   (xseh xxcos_sales_exp_headers_n02) 
                          USE_NL  (hcas)
                      */
                      xseh.sales_exp_header_id      sales_exp_header_id
                     ,xseh.dlv_invoice_number       dlv_invoice_number
                     ,xseh.dlv_invoice_class        dlv_invoice_class
                     ,xseh.cust_gyotai_sho          cust_gyotai_sho
                     ,xseh.delivery_date            delivery_date
                     ,xseh.inspect_date             inspect_date
                     ,xseh.ship_to_customer_code    ship_to_customer_code
                     ,xseh.tax_code                 tax_code
                     ,xseh.tax_rate                 tax_rate
                     ,xseh.consumption_tax_class    consumption_tax_class
                     ,xseh.results_employee_code    results_employee_code
                     ,xseh.sales_base_code          sales_base_code
                     ,xseh.receiv_base_code         receiv_base_code
                     ,xseh.create_class             create_class
                     ,xseh.card_sale_class          card_sale_class
                     ,xseh.rowid                    xseh_rowid
                     ,hcas.account_number           ship_account_number
                     ,hcas.cust_account_id          ship_account_id
                     ,hcas.customer_class_code      customer_class_code
                     ,hcab.account_number           bill_account_number
                     ,hcab.cust_account_id          bill_account_id
                     ,hcac.account_number           cash_account_number
                     ,hcac.cust_account_id          cash_account_id
               FROM   xxcos_sales_exp_headers  xseh
                     ,hz_cust_accounts         hcas     -- 出荷先顧客
                     ,hz_cust_acct_relate      hcar_sb  -- 顧客関連(請求)
                     ,hz_cust_accounts         hcab     -- 請求先顧客
                     ,hz_cust_accounts         hcac     -- 入金先顧客
               WHERE  xseh.ar_interface_flag            = cv_n_flag                   -- ARインタフェース済フラグ:N(未送信)
               AND    xseh.delivery_date               <= gd_process_date             -- 納品日 <= 業務日付
               AND    hcas.account_number               = xseh.ship_to_customer_code
               AND    hcar_sb.related_cust_account_id   = hcas.cust_account_id
               AND    hcar_sb.status                    = cv_cust_relate_status       -- 顧客関連ステータス:A(有効)
               AND    hcar_sb.attribute1                = cv_cust_bill                -- 関連分類:1(請求)
               AND    hcab.cust_account_id              = hcar_sb.cust_account_id
               AND    hcab.customer_class_code          = cv_cust_class_uri           -- 顧客区分(請求):14(売掛金管理先顧客)
               AND    hcac.cust_account_id              = hcab.cust_account_id
               AND    EXISTS (
                        SELECT /*+ USE_NL(ship_hasa_1 ship_hsua_1 ship_hzad_1 bill_hasa_1 bill_hsua_1 bill_hzad_1) */
                               'X'
                        FROM   hz_cust_acct_sites     ship_hasa_1
                              ,hz_cust_site_uses      ship_hsua_1
                              ,xxcmm_cust_accounts    ship_hzad_1
                              ,hz_cust_acct_sites     bill_hasa_1
                              ,hz_cust_site_uses      bill_hsua_1
                              ,xxcmm_cust_accounts    bill_hzad_1
                        WHERE  ship_hasa_1.cust_account_id     = hcas.cust_account_id
                        AND    ship_hsua_1.cust_acct_site_id   = ship_hasa_1.cust_acct_site_id
                        AND    ship_hzad_1.customer_id         = hcas.cust_account_id
                        AND    bill_hasa_1.cust_account_id     = hcab.cust_account_id
                        AND    bill_hsua_1.cust_acct_site_id   = bill_hasa_1.cust_acct_site_id
                        AND    bill_hsua_1.site_use_code       = cv_site_code                   -- サイトコード:BILL_TO
                        AND    bill_hzad_1.customer_id         = hcab.cust_account_id
                        AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id
                        AND    NOT EXISTS (
                                 SELECT /*+ USE_NL(cash_hcar_1) */
                                       'X'
                                FROM   hz_cust_acct_relate  cash_hcar_1
                                WHERE  cash_hcar_1.status                  = cv_cust_relate_status  -- 顧客関連ステータス:A(有効)
                                AND    cash_hcar_1.attribute1              = cv_cust_cash           -- 関連分類:2(入金)
                                AND    cash_hcar_1.related_cust_account_id = hcab.cust_account_id
                                AND    ROWNUM                              = 1
                               )
                        AND    ROWNUM                          = 1
                      )
               UNION ALL
               --②入金先顧客－請求先顧客－出荷先顧客
               SELECT /*+
                          LEADING (xseh)
                          INDEX   (xseh xxcos_sales_exp_headers_n02)
                          USE_NL  (hcas)
                      */
                      xseh.sales_exp_header_id      sales_exp_header_id
                     ,xseh.dlv_invoice_number       dlv_invoice_number
                     ,xseh.dlv_invoice_class        dlv_invoice_class
                     ,xseh.cust_gyotai_sho          cust_gyotai_sho
                     ,xseh.delivery_date            delivery_date
                     ,xseh.inspect_date             inspect_date
                     ,xseh.ship_to_customer_code    ship_to_customer_code
                     ,xseh.tax_code                 tax_code
                     ,xseh.tax_rate                 tax_rate
                     ,xseh.consumption_tax_class    consumption_tax_class
                     ,xseh.results_employee_code    results_employee_code
                     ,xseh.sales_base_code          sales_base_code
                     ,xseh.receiv_base_code         receiv_base_code
                     ,xseh.create_class             create_class
                     ,xseh.card_sale_class          card_sale_class
                     ,xseh.rowid                    xseh_rowid
                     ,hcas.account_number           ship_account_number
                     ,hcas.cust_account_id          ship_account_id
                     ,hcas.customer_class_code      customer_class_code
                     ,hcab.account_number           bill_account_number
                     ,hcab.cust_account_id          bill_account_id
                     ,hcac.account_number           cash_account_number
                     ,hcac.cust_account_id          cash_account_id
               FROM   xxcos_sales_exp_headers  xseh
                     ,hz_cust_accounts         hcas    -- 出荷先顧客
                     ,hz_cust_acct_relate      hcar_sb -- 顧客関連(請求)
                     ,hz_cust_accounts         hcab    -- 請求先顧客
                     ,hz_cust_acct_relate      hcar_sc -- 顧客関連(入金)
                     ,hz_cust_accounts         hcac    -- 入金先顧客
               WHERE  xseh.ar_interface_flag             = cv_n_flag                  -- ARインタフェース済フラグ:N(未送信)
               AND    xseh.delivery_date                <= gd_process_date            -- 納品日 <= 業務日付
               AND    hcas.account_number                = xseh.ship_to_customer_code
               AND    hcas.customer_class_code          IN ( cv_cust_class_cust, cv_cust_class_ue ) -- 顧客区分:10(顧客),12(上様)
               AND    hcar_sb.related_cust_account_id    = hcas.cust_account_id
               AND    hcar_sb.status                     = cv_cust_relate_status      -- 顧客関連(請求)ステータス:A(有効)
               AND    hcar_sb.attribute1                 = cv_cust_bill               -- 関連分類:1(請求)
               AND    hcab.cust_account_id               = hcar_sb.cust_account_id
               AND    hcar_sc.related_cust_account_id    = hcab.cust_account_id
               AND    hcar_sc.status                     = cv_cust_relate_status      -- 顧客関連(入金)ステータス:A(有効)
               AND    hcar_sc.attribute1                 = cv_cust_cash               -- 関連分類(入金)
               AND    hcac.cust_account_id               = hcar_sc.cust_account_id
               AND    hcac.customer_class_code           = cv_cust_class_uri          -- 顧客区分(入金):14(売掛金管理先顧客)
               AND    EXISTS (
                        SELECT /*+ USE_NL(ship_hasa_2 ship_hsua_2 ship_hzad_2 bill_hasa_2 bill_hsua_2 bill_hzad_2 cash_hasa_2 cash_hzad_2) */
                               'X'
                        FROM   hz_cust_acct_sites     ship_hasa_2
                              ,hz_cust_site_uses      ship_hsua_2
                              ,xxcmm_cust_accounts    ship_hzad_2
                              ,hz_cust_acct_sites     bill_hasa_2
                              ,hz_cust_site_uses      bill_hsua_2
                              ,xxcmm_cust_accounts    bill_hzad_2
                              ,hz_cust_acct_sites     cash_hasa_2
                              ,xxcmm_cust_accounts    cash_hzad_2
                        WHERE  ship_hasa_2.cust_account_id     = hcas.cust_account_id
                        AND    ship_hsua_2.cust_acct_site_id   = ship_hasa_2.cust_acct_site_id
                        AND    ship_hzad_2.customer_id         = hcas.cust_account_id
                        AND    bill_hasa_2.cust_account_id     = hcab.cust_account_id
                        AND    bill_hsua_2.cust_acct_site_id   = bill_hasa_2.cust_acct_site_id
                        AND    bill_hsua_2.site_use_code       = cv_site_code                   -- サイトコード:BILL_TO
                        AND    bill_hzad_2.customer_id         = hcab.cust_account_id
                        AND    cash_hasa_2.cust_account_id     = hcac.cust_account_id
                        AND    cash_hzad_2.customer_id         = hcac.cust_account_id
                        AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id
                        AND    ROWNUM                          = 1
                      )
               UNION ALL
               --③入金先顧客－請求先顧客＆出荷先顧客
               SELECT /*+
                          LEADING (xseh)
                          INDEX   (xseh xxcos_sales_exp_headers_n02)
                          USE_NL  (hcas)
                      */
                      xseh.sales_exp_header_id      sales_exp_header_id
                     ,xseh.dlv_invoice_number       dlv_invoice_number
                     ,xseh.dlv_invoice_class        dlv_invoice_class
                     ,xseh.cust_gyotai_sho          cust_gyotai_sho
                     ,xseh.delivery_date            delivery_date
                     ,xseh.inspect_date             inspect_date
                     ,xseh.ship_to_customer_code    ship_to_customer_code
                     ,xseh.tax_code                 tax_code
                     ,xseh.tax_rate                 tax_rate
                     ,xseh.consumption_tax_class    consumption_tax_class
                     ,xseh.results_employee_code    results_employee_code
                     ,xseh.sales_base_code          sales_base_code
                     ,xseh.receiv_base_code         receiv_base_code
                     ,xseh.create_class             create_class
                     ,xseh.card_sale_class          card_sale_class
                     ,xseh.rowid                    xseh_rowid
                     ,hcas.account_number           ship_account_number
                     ,hcas.cust_account_id          ship_account_id
                     ,hcas.customer_class_code      customer_class_code
                     ,hcab.account_number           bill_account_number
                     ,hcab.cust_account_id          bill_account_id
                     ,hcac.account_number           cash_account_number
                     ,hcac.cust_account_id          cash_account_id
               FROM   xxcos_sales_exp_headers  xseh
                     ,hz_cust_accounts         hcas     -- 出荷先顧客
                     ,hz_cust_accounts         hcab     -- 請求先顧客
                     ,hz_cust_acct_relate      hcar_sc  -- 顧客関連(入金)
                     ,hz_cust_accounts         hcac     -- 入金先顧客
               WHERE  xseh.ar_interface_flag            = cv_n_flag                  -- ARインタフェース済フラグ:N(未送信)
               AND    xseh.delivery_date               <= gd_process_date            -- 納品日 <= 業務日付
               AND    hcas.account_number               = xseh.ship_to_customer_code
               AND    hcas.customer_class_code         IN ( cv_cust_class_cust, cv_cust_class_ue ) -- 顧客区分:10(顧客),12(上様)
               AND    hcab.cust_account_id              = hcas.cust_account_id
               AND    hcar_sc.related_cust_account_id   = hcas.cust_account_id
               AND    hcar_sc.status                    = cv_cust_relate_status      -- 顧客関連(入金)ステータス:A(有効)
               AND    hcar_sc.attribute1                = cv_cust_cash               -- 関連分類(入金)
               AND    hcac.cust_account_id              = hcar_sc.cust_account_id
               AND    hcac.customer_class_code          = cv_cust_class_uri          -- 顧客区分(入金):14(売掛金管理先顧客)
               AND    EXISTS (
                        SELECT /*+ USE_NL(ship_hasa_3 ship_hsua_3 ship_hzad_3 bill_hasa_3 bill_hsua_3 cash_hasa_3 cash_hzad_3) */
                               'X'
                        FROM   hz_cust_acct_sites     ship_hasa_3
                              ,hz_cust_site_uses      ship_hsua_3
                              ,xxcmm_cust_accounts    ship_hzad_3
                              ,hz_cust_acct_sites     bill_hasa_3
                              ,hz_cust_site_uses      bill_hsua_3
                              ,hz_cust_acct_sites     cash_hasa_3
                              ,xxcmm_cust_accounts    cash_hzad_3
                        WHERE  ship_hasa_3.cust_account_id     = hcas.cust_account_id
                        AND    ship_hsua_3.cust_acct_site_id   = ship_hasa_3.cust_acct_site_id
                        AND    ship_hzad_3.customer_id         = hcas.cust_account_id
                        AND    bill_hasa_3.cust_account_id     = hcab.cust_account_id
                        AND    bill_hsua_3.cust_acct_site_id   = bill_hasa_3.cust_acct_site_id
                        AND    bill_hsua_3.site_use_code       = cv_site_code                   -- サイトコード:BILL_TO
                        AND    cash_hasa_3.cust_account_id     = hcac.cust_account_id
                        AND    cash_hzad_3.customer_id         = hcac.cust_account_id
                        AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id
                        AND    ROWNUM                          = 1
                      )
               AND    NOT EXISTS (
                        SELECT /*+ USE_NL(ex_hcar_3) */
                               'X'
                        FROM   hz_cust_acct_relate  ex_hcar_3
                        WHERE  ex_hcar_3.cust_account_id = hcas.cust_account_id
                        AND    ex_hcar_3.status          = cv_cust_relate_status -- 顧客関連ステータス:A(有効)
                        AND    ROWNUM                    = 1
                      )
               UNION ALL
               --④入金先顧客＆請求先顧客＆出荷先顧客
               SELECT /*+
                          LEADING (xseh)
                          INDEX   (xseh xxcos_sales_exp_headers_n02)
                          USE_NL  (hcas)
                          USE_NL  (hcab)
                      */
                      xseh.sales_exp_header_id      sales_exp_header_id
                     ,xseh.dlv_invoice_number       dlv_invoice_number
                     ,xseh.dlv_invoice_class        dlv_invoice_class
                     ,xseh.cust_gyotai_sho          cust_gyotai_sho
                     ,xseh.delivery_date            delivery_date
                     ,xseh.inspect_date             inspect_date
                     ,xseh.ship_to_customer_code    ship_to_customer_code
                     ,xseh.tax_code                 tax_code
                     ,xseh.tax_rate                 tax_rate
                     ,xseh.consumption_tax_class    consumption_tax_class
                     ,xseh.results_employee_code    results_employee_code
                     ,xseh.sales_base_code          sales_base_code
                     ,xseh.receiv_base_code         receiv_base_code
                     ,xseh.create_class             create_class
                     ,xseh.card_sale_class          card_sale_class
                     ,xseh.rowid                    xseh_rowid
                     ,hcas.account_number           ship_account_number
                     ,hcas.cust_account_id          ship_account_id
                     ,hcas.customer_class_code      customer_class_code
                     ,hcab.account_number           bill_account_number
                     ,hcab.cust_account_id          bill_account_id
                     ,hcac.account_number           cash_account_number
                     ,hcac.cust_account_id          cash_account_id
               FROM   xxcos_sales_exp_headers  xseh
                     ,hz_cust_accounts         hcas  -- 出荷先顧客
                     ,hz_cust_accounts         hcab  -- 請求先顧客
                     ,hz_cust_accounts         hcac  -- 入金先顧客
              WHERE   xseh.ar_interface_flag     = cv_n_flag                   -- ARインタフェース済フラグ:N(未送信)
              AND     xseh.delivery_date        <= gd_process_date             -- 納品日 <= 業務日付
              AND     hcas.account_number        = xseh.ship_to_customer_code
              AND     hcas.customer_class_code  IN ( cv_cust_class_cust, cv_cust_class_ue ) -- 顧客区分:10(顧客),12(上様)
              AND     hcab.cust_account_id       = hcas.cust_account_id
              AND     hcac.cust_account_id       = hcas.cust_account_id
              AND     EXISTS (
                        SELECT /*+ USE_NL(ship_hasa_4 ship_hsua_4 ship_hzad_4 bill_hasa_4 bill_hsua_4) */
                               'X'
                        FROM   hz_cust_acct_sites     ship_hasa_4
                              ,hz_cust_site_uses      ship_hsua_4
                              ,xxcmm_cust_accounts    ship_hzad_4
                              ,hz_cust_acct_sites     bill_hasa_4
                              ,hz_cust_site_uses      bill_hsua_4
                        WHERE  ship_hasa_4.cust_account_id     = hcas.cust_account_id
                        AND    ship_hsua_4.cust_acct_site_id   = ship_hasa_4.cust_acct_site_id
                        AND    ship_hzad_4.customer_id         = hcas.cust_account_id
                        AND    bill_hasa_4.cust_account_id     = hcab.cust_account_id
                        AND    bill_hsua_4.cust_acct_site_id   = bill_hasa_4.cust_acct_site_id
                        AND    bill_hsua_4.site_use_code       = cv_site_code                   -- サイトコード:BILL_TO
                        AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id
                        AND    ROWNUM                          = 1
                      )
              AND   NOT EXISTS (
                      SELECT /*+ USE_NL(ex_hcar_4) */
                             'X'
                      FROM   hz_cust_acct_relate  ex_hcar_4
                      WHERE  ex_hcar_4.cust_account_id = hcas.cust_account_id
                      AND    ex_hcar_4.status          = cv_cust_relate_status  -- 顧客関連ステータス:A(有効)
                      AND    ROWNUM                    = 1
                    )
             AND    NOT EXISTS (
                      SELECT /*+ USE_NL(ex_hcar_4) */
                             'X'
                      FROM   hz_cust_acct_relate  ex_hcar_4
                      WHERE  ex_hcar_4.related_cust_account_id = hcas.cust_account_id
                      AND    ex_hcar_4.status                  = cv_cust_relate_status  -- 顧客関連ステータス:A(有効)
                      AND    ROWNUM                            = 1
                    )
             )                                 xsehv                   -- 販売実績ヘッダテーブル(顧客階層込み)
/* 2009/07/27 Ver1.21 Add End   */
           , xxcos_sales_exp_lines             xsel                    -- 販売実績明細テーブル
           , ar_vat_tax_all_b                  avta                    -- 税金マスタ
/* 2009/07/27 Ver1.21 Del Start */
--           , hz_cust_accounts                  hcas                    -- 顧客マスタ（出荷先）
--           , hz_cust_accounts                  hcab                    -- 顧客マスタ（請求先）
--           , hz_cust_accounts                  hcac                    -- 顧客マスタ（入金先）
/* 2009/07/27 Ver1.21 Del End   */
           , hz_cust_acct_sites_all            hcss                    -- 顧客所在地（出荷先）
           , hz_cust_acct_sites_all            hcsb                    -- 顧客所在地（請求先）
           , hz_cust_acct_sites_all            hcsc                    -- 顧客所在地（入金先）
/* 2009/07/27 Ver1.21 Add Start */
           , hz_cust_site_uses_all             hcub                    -- 顧客サイト（請求）
/* 2009/07/27 Ver1.21 Add End   */
/* 2009/07/27 Ver1.21 Del Start */
--           , xxcos_good_prod_class_v           xgpc                    -- 品目区分View
--           , xxcos_cust_hierarchy_v            xchv                    -- 顧客階層ビュー
--           , ( SELECT DISTINCT
--                   mcav.subinventory_code      subinventory_code
--               FROM mtl_category_accounts_v    mcav                    -- 専門店View
--             ) mcavd
--           , ( SELECT DISTINCT
--                   rcrm.customer_id      customer_id
--                 , receipt_method_id     receipt_method_id
--               FROM ra_cust_receipt_methods           rcrm                    -- 顧客支払方法
--                  , hz_cust_site_uses_all             scsua                   -- 顧客使用目的
--               WHERE rcrm.primary_flag                     = cv_y_flag
--                 AND rcrm.site_use_id                      = scsua.site_use_id
--                 AND gd_process_date BETWEEN               NVL( rcrm.start_date, gd_process_date )
--                                     AND                   NVL( rcrm.end_date,   gd_process_date )
--                 AND scsua.site_use_code                   = cv_site_code
--             ) rcrmv
/* 2009/07/27 Ver1.21 Del End   */
      WHERE
/* 2009/07/27 Ver1.21 Mod Start   */
--          xseh.sales_exp_header_id              = xsel.sales_exp_header_id
--      AND xseh.dlv_invoice_number               = xsel.dlv_invoice_number
--      AND xseh.ar_interface_flag                = cv_n_flag
--      AND xseh.delivery_date                   <= gd_process_date
--      AND xsel.item_code                       <> gv_var_elec_item_cd
--      AND xchv.ship_account_number              = xseh.ship_to_customer_code
--      AND hcss.org_id                           = TO_NUMBER( gv_mo_org_id )
--      AND hcsb.org_id                           = TO_NUMBER( gv_mo_org_id )
--      AND hcsc.org_id                           = TO_NUMBER( gv_mo_org_id )
--      AND hcas.account_number                   = xseh.ship_to_customer_code
--      AND hcab.account_number                   = xchv.bill_account_number
--      AND hcac.account_number                   = xchv.cash_account_number
--      AND hcas.customer_class_code             <> gt_cust_cls_cd
--      AND ( xseh.cust_gyotai_sho               <> gt_gyotai_fvd
--         OR ( xseh.cust_gyotai_sho              = gt_gyotai_fvd
--           AND NVL( xseh.card_sale_class, cv_cash_class )
--                                               <> gt_cash_sale_cls )
--         OR ( xseh.cust_gyotai_sho              = gt_gyotai_fvd
--           AND NVL( xseh.card_sale_class, cv_cash_class )
--                                                = gt_cash_sale_cls
--           AND NVL( xsel.cash_and_card, 0 )    <> 0 ) )
--      AND avta.tax_code                         = xseh.tax_code
          xsehv.sales_exp_header_id             = xseh.sales_exp_header_id
      AND xsehv.sales_exp_header_id             = xsel.sales_exp_header_id
      AND xsehv.dlv_invoice_number              = xsel.dlv_invoice_number
      AND xsel.item_code                       <> gv_var_elec_item_cd
      AND hcss.cust_account_id                  = xsehv.ship_account_id
      AND hcss.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcsb.cust_account_id                  = xsehv.bill_account_id
      AND hcsb.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcsc.cust_account_id                  = xsehv.cash_account_id
      AND hcsc.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcub.cust_acct_site_id                = hcsb.cust_acct_site_id
      AND hcub.site_use_code                    = cv_site_code
      AND xsehv.customer_class_code            <> gt_cust_cls_cd
      AND ( xsehv.cust_gyotai_sho              <> gt_gyotai_fvd
         OR ( xsehv.cust_gyotai_sho             = gt_gyotai_fvd
           AND NVL( xsehv.card_sale_class, cv_cash_class )
                                               <> gt_cash_sale_cls )
         OR ( xsehv.cust_gyotai_sho = gt_gyotai_fvd
           AND NVL( xsehv.card_sale_class, cv_cash_class )
                                                = gt_cash_sale_cls
           AND NVL( xsel.cash_and_card, 0 )    <> 0 )
          )
      AND avta.tax_code                         = xsehv.tax_code
/* 2009/07/27 Ver1.21 Mod End   */
      AND avta.set_of_books_id                  = TO_NUMBER( gv_set_bks_id )
      AND avta.enabled_flag                     = cv_enabled_yes
      AND gd_process_date BETWEEN               NVL( avta.start_date, gd_process_date )
                          AND                   NVL( avta.end_date,   gd_process_date )
/* 2009/07/27 Ver1.21 Del Start */
--        AND xgpc.segment1( + )                = xsel.item_code
/* 2009/07/27 Ver1.21 Del End   */
/* 2009/07/27 Ver1.21 Mod Start */
--      AND xseh.create_class                     NOT IN (
--          SELECT
--              flvl.meaning                      meaning
      AND NOT EXISTS (
          SELECT
              'X'
/* 2009/07/27 Ver1.21 Mod End */
          FROM
              fnd_lookup_values                 flvl
          WHERE
              flvl.lookup_type                  = cv_qct_mkorg_cls
          AND flvl.lookup_code                  LIKE cv_qcc_code
          AND flvl.attribute2                   = cv_attribute_y
          AND flvl.enabled_flag                 = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--          AND flvl.language                     = USERENV( 'LANG' )
          AND flvl.language                     = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
          AND gd_process_date BETWEEN           NVL( flvl.start_date_active, gd_process_date )
                              AND               NVL( flvl.end_date_active,   gd_process_date )
/* 2009/07/27 Ver1.21 Add Start */
          AND flvl.meaning                      = xsehv.create_class
/* 2009/07/27 Ver1.21 Add End   */
          )
/* 2009/07/27 Ver1.21 Mod Start */
--      AND xsel.sales_class                      NOT IN (
--          SELECT
--              flvl.meaning                      meaning
      AND NOT EXISTS (
          SELECT
              'X'
/* 2009/07/27 Ver1.21 Mod End   */
          FROM
              fnd_lookup_values                 flvl
          WHERE
              flvl.lookup_type                  = cv_qct_sale_cls
          AND flvl.lookup_code                  LIKE cv_qcc_code
          AND flvl.attribute1                   = cv_attribute_y
          AND flvl.enabled_flag                 = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--          AND flvl.language                     = USERENV( 'LANG' )
          AND flvl.language                     = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
          AND gd_process_date BETWEEN           NVL( flvl.start_date_active, gd_process_date )
                              AND               NVL( flvl.end_date_active,   gd_process_date )
/* 2009/07/27 Ver1.21 Add Start */
          AND flvl.meaning                      = xsel.sales_class
/* 2009/07/27 Ver1.21 Add End   */
          )
/* 2009/07/27 Ver1.21 Del Start */
--      AND hcss.cust_account_id                  = hcas.cust_account_id
--      AND hcsb.cust_account_id                  = hcab.cust_account_id
--      AND hcsc.cust_account_id                  = hcac.cust_account_id
--      AND xchv.ship_account_id                  = hcas.cust_account_id
--      AND rcrmv.customer_id( + )                = hcab.cust_account_id
--      AND mcavd.subinventory_code( + )          = xsel.ship_from_subinventory_code
/* 2009/07/27 Ver1.21 Del End   */
/* 2009/07/27 Ver1.21 Mod Start */
--      ORDER BY xseh.sales_exp_header_id
--             , xseh.dlv_invoice_number
--             , xseh.dlv_invoice_class
--             , NVL( xseh.card_sale_class, cv_cash_class )
--             , xseh.cust_gyotai_sho
      ORDER BY xsehv.sales_exp_header_id
             , xsehv.dlv_invoice_number
             , xsehv.dlv_invoice_class
             , NVL( xsehv.card_sale_class, cv_cash_class )
             , xsehv.cust_gyotai_sho
/* 2009/07/27 Ver1.21 Mod End */
             , xsel.item_code
             , xsel.red_black_flag
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
    FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_tbl2;
--
    -- カーソルクローズ
    CLOSE sales_data_cur;
--
    --現金・カード併用とカードVDのレコード作成し、スキップ用ヘッダID取得する
    <<gt_sales_exp_tbl2_loop>>
    FOR sale_idx IN 1 .. gt_sales_exp_tbl2.COUNT LOOP
--
      IF ( gt_sales_exp_tbl2( sale_idx ).rcrm_receipt_id IS NULL ) THEN
        --スキップ処理
        ln_skip_idx := ln_skip_idx + 1;
        gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
                                                           := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
        --支払方法が設定させて未設定
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_receipt_id_msg
                      , iv_token_name1   => cv_tkn_header_id
                      , iv_token_value1  => gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id
                      , iv_token_name2   => cv_tkn_order_no
                      , iv_token_value2  => gt_sales_exp_tbl2( sale_idx ).dlv_invoice_number
                      , iv_token_name3   => cv_tkn_cust_code
                      , iv_token_value3  => gt_sales_exp_tbl2( sale_idx ).ship_to_customer_code
                    );
        gn_warn_flag := cv_y_flag;
        -- 空行出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => cv_blank
        );
--
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
--
        -- 空行出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => cv_blank
        );
--
--
        -- 空行出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => cv_blank
        );
--
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        -- 空行出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => cv_blank
        );
      END IF;
      --カードVDフラグ
      lv_heiyou_card_flag := cv_n_flag;
      --現金・カード併用
      lv_heiyou_cash_flag := cv_n_flag;
--
      IF ( (   gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_fvd_xiaoka
            OR gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_gyotai_fvd )
        AND (  gt_sales_exp_tbl2( sale_idx ).card_sale_class = gt_cash_sale_cls
          AND  gt_sales_exp_tbl2( sale_idx ).cash_and_card  <> 0 ) ) THEN
--
        --現金・カード併用
        lv_heiyou_cash_flag := cv_y_flag;
--
      ELSIF ( ( gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_fvd_xiaoka
             OR gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_gyotai_fvd )
        AND   gt_sales_exp_tbl2( sale_idx ).card_sale_class = cv_card_class ) THEN
--
        --カードVD
        lv_heiyou_card_flag := cv_y_flag;
--
      END IF;
--
      IF ( lv_heiyou_cash_flag = cv_y_flag
        OR lv_heiyou_card_flag = cv_y_flag ) THEN
--
        lv_sale_flag := cv_y_flag;
        BEGIN
          BEGIN
            SELECT xcab.card_company                -- 顧客追加情報カード会社
                 , cst.customer_id                  -- 顧客追加情報顧客ID
                 , cst.receiv_base_code             -- 入金拠点
                 , cst.cust_acct_site_id            -- 顧客所在地参照ID
                 , cst.receipt_method_id            -- 顧客支払方法ID
                 , cst.bill_payment_term_id         -- 支払条件ID
                 , cst.bill_payment_term2           -- 支払条件2
                 , cst.bill_payment_term3           -- 支払条件3
            INTO   lv_card_company
                 , lt_xchv_cust_id
                 , lt_receiv_base_code
                 , lt_hcsc_org_sys_id
                 , lt_receipt_id
                 , lt_bill_pay_id
                 , lt_bill_pay_id2
                 , lt_bill_pay_id3
            FROM   xxcmm_cust_accounts       xcab   -- 顧客追加情報
                 , ( SELECT xca.customer_code          customer_code
                          , xca.customer_id            customer_id          -- 顧客追加情報顧客ID
                          , xca.receiv_base_code       receiv_base_code     -- 入金拠点
                          , hcasa.cust_acct_site_id    cust_acct_site_id    -- 顧客所在地参照ID
                          , rcrm.receipt_method_id     receipt_method_id    -- 顧客支払方法ID
                          , hcsua.payment_term_id      bill_payment_term_id -- 支払条件ID
                          , hcsua.attribute2           bill_payment_term2   -- 支払条件2
                          , hcsua.attribute3           bill_payment_term3   -- 支払条件3
                      FROM  xxcmm_cust_accounts       xca    -- 顧客追加情報
                          , hz_cust_acct_sites_all    hcasa  -- 顧客所在地マスタ
                          , hz_cust_site_uses_all     hcsua  -- 顧客使用目的マスタ
                          , hz_cust_accounts          hca    -- 顧客マスタ
                          , ra_cust_receipt_methods   rcrm   -- 顧客支払方法
                     WHERE  hcasa.cust_account_id     = xca.customer_id
                       AND  hcasa.org_id              = gv_mo_org_id
                       AND  hcasa.cust_acct_site_id   = hcsua.cust_acct_site_id
                       AND  hcsua.site_use_code       = cv_site_code
                       AND  hcsua.org_id              = gv_mo_org_id 
                       AND  xca.customer_id           = hca.cust_account_id
                       AND  rcrm.customer_id          = hca.cust_account_id
                       AND  rcrm.primary_flag         = cv_y_flag
                       AND  rcrm.site_use_id          = hcsua.site_use_id ) cst
            WHERE  xcab.customer_code        = gt_sales_exp_tbl2( sale_idx ).ship_to_customer_code
              AND  xcab.card_company         = cst.customer_code( + );
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
--
            lv_sale_flag := cv_n_flag;
--
          END;
          IF ( lv_sale_flag = cv_n_flag OR lv_card_company IS NULL ) THEN
--
            lv_sale_flag := cv_n_flag;
            -- カード会社が未設定
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application   => cv_xxcos_short_nm
                          , iv_name          => cv_card_comp_msg
                          , iv_token_name1   => cv_tkn_cust_code
                          , iv_token_value1  => gt_sales_exp_tbl2( sale_idx ).ship_to_customer_code
                        );
            gn_warn_flag := cv_y_flag;
--
          ELSIF ( lt_xchv_cust_id IS NULL ) THEN
--
            lv_sale_flag := cv_n_flag;
            -- カード会社のデータが顧客追加情報にない
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application   => cv_xxcos_short_nm
                          , iv_name          => cv_cust_num_msg
                          , iv_token_name1   => cv_tkn_card_company
                          , iv_token_value1  => lv_card_company
                        );
            gn_warn_flag := cv_y_flag;
--
          ELSIF ( lt_receiv_base_code IS NULL ) THEN
--
            lv_sale_flag := cv_n_flag;
            -- カード会社の入金拠点が未設定
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application   => cv_xxcos_short_nm
                          , iv_name          => cv_receiv_base_msg
                          , iv_token_name1   => cv_tkn_card_company
                          , iv_token_value1  => lv_card_company
                        );
            gn_warn_flag := cv_y_flag;
--
          ELSIF ( lt_hcsc_org_sys_id IS NULL ) THEN
--
            lv_sale_flag := cv_n_flag;
            -- カード会社の顧客所在地参照IDが未設定
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application   => cv_xxcos_short_nm
                          , iv_name          => cv_org_sys_id_msg
                          , iv_token_name1   => cv_tkn_card_company
                          , iv_token_value1  => lv_card_company
                        );
            gn_warn_flag := cv_y_flag;
--
          END IF;
        END;
        IF ( lv_sale_flag = cv_y_flag ) THEN
--
          -- *** カードレコード全カラムの設定 ***
          ln_sale_idx := ln_sale_idx + 1;
--
          gt_sales_exp_tbl( ln_sale_idx )                  := gt_sales_exp_tbl2( sale_idx );
          -- カード売り区分（１：カード）
          gt_sales_exp_tbl( ln_sale_idx ).card_sale_class  := cv_card_class;
          -- 本体金額
          gt_sales_exp_tbl( ln_sale_idx ).pure_amount      := gt_sales_exp_tbl2( sale_idx ).cash_and_card;
          -- 税金は０を固定
          gt_sales_exp_tbl( ln_sale_idx ).tax_amount       := 0;
          -- 税金コードは消費税区分(対象外)にする
          gt_sales_exp_tbl( ln_sale_idx ).tax_code         := gt_exp_tax_cls;
          -- 併用額は０を固定
          gt_sales_exp_tbl( ln_sale_idx ).cash_and_card    := 0;
--
          IF ( lv_heiyou_card_flag = cv_y_flag ) THEN
--
            -- 本体金額
            gt_sales_exp_tbl( ln_sale_idx ).pure_amount    := gt_sales_exp_tbl2( sale_idx ).pure_amount
                                                                  + gt_sales_exp_tbl2( sale_idx ).tax_amount;
          END IF;
--
          -- 入金先顧客
          gt_sales_exp_tbl( ln_sale_idx ).xchv_cust_id_c   := lt_xchv_cust_id;
          -- 入金拠点
          gt_sales_exp_tbl( ln_sale_idx ).card_receiv_base := lt_receiv_base_code;
          -- 入金先顧客所在地ID
          gt_sales_exp_tbl( ln_sale_idx ).hcsc_org_sys_id  := lt_hcsc_org_sys_id;
          -- 支払方法
          gt_sales_exp_tbl( ln_sale_idx ).rcrm_receipt_id  := lt_receipt_id;
          -- 支払条件１
          gt_sales_exp_tbl( ln_sale_idx ).xchv_bill_pay_id  := lt_bill_pay_id;
          -- 支払条件２
          gt_sales_exp_tbl( ln_sale_idx ).xchv_bill_pay_id2 := lt_bill_pay_id2;
          -- 支払条件３
          gt_sales_exp_tbl( ln_sale_idx ).xchv_bill_pay_id3 := lt_bill_pay_id3;
          -- 請求先顧客コード
          gt_sales_exp_tbl( ln_sale_idx ).pay_cust_number   := lv_card_company;
--
          IF ( gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho <> gt_gyotai_fvd ) THEN
            -- *** 現金レコード全カラムの設定 ***
            ln_sale_idx := ln_sale_idx + 1;
            gt_sales_exp_tbl( ln_sale_idx )                  := gt_sales_exp_tbl2( sale_idx );
            -- カード売り区分（0：現金）
            gt_sales_exp_tbl( ln_sale_idx ).card_sale_class  := cv_cash_class;
            -- 本体金額
            gt_sales_exp_tbl( ln_sale_idx ).pure_amount      := gt_sales_exp_tbl2( sale_idx ).pure_amount
                                                                  + gt_sales_exp_tbl2( sale_idx ).tax_amount;
            -- 税金は０を固定
            gt_sales_exp_tbl( ln_sale_idx ).tax_amount       := 0;
            -- 税金コードは消費税区分(対象外)にする
            gt_sales_exp_tbl( ln_sale_idx ).tax_code         := gt_exp_tax_cls;
            -- 併用額は０を固定
            gt_sales_exp_tbl( ln_sale_idx ).cash_and_card    := 0;
          END IF;
--
        ELSE
          --スキップ処理
          ln_skip_idx := ln_skip_idx + 1;
          gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
                                                           := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
--
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
--
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
--
--
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
--
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
        END IF;
      ELSE
        -- 対象外データセット
        ln_sale_idx := ln_sale_idx + 1;
        gt_sales_exp_tbl( ln_sale_idx )                    := gt_sales_exp_tbl2( sale_idx );
--
        -- 業態小分類24、25時に税金を０に固定、本体金額は税込みします。
        IF (  gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_fvd_xiaoka
           OR gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_gyotai_fvd ) THEN
          -- 税金を０に固定
          gt_sales_exp_tbl( ln_sale_idx ).tax_amount       := 0;
          -- 税金コードは消費税区分(対象外)にする
          gt_sales_exp_tbl( ln_sale_idx ).tax_code         := gt_exp_tax_cls;
--
            gt_sales_exp_tbl( ln_sale_idx ).pure_amount      := gt_sales_exp_tbl2( sale_idx ).pure_amount
                                                                + gt_sales_exp_tbl2( sale_idx ).tax_amount;
--
        END IF;
--
      END IF;
--
    END LOOP gt_sales_exp_tbl2_loop;                                  -- 販売実績データループ終了
--
    -- 対象処理件数
    gn_target_cnt   := gt_sales_exp_tbl2.COUNT;
--
    IF ( gn_target_cnt > 0 ) THEN
--
      -- 非大手量販店データと大手量販店データの分離
      -- 抽出された販売実績データのループ
      <<gt_sales_exp_tbl_loop>>
      FOR sale_idx IN 1 .. gt_sales_exp_tbl.COUNT LOOP
        IF ( gt_sales_exp_tbl( sale_idx ).receiv_base_code = gv_busi_dept_cd ) THEN
          -- 大手量販店データを抽出
          lv_skip_flag := cv_n_flag;
          -- スキップ処理
          IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
            <<gt_sales_skip_tbl_loop>>
            FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
              IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
                  = gt_sales_exp_tbl( sale_idx ).sales_exp_header_id ) THEN
                lv_skip_flag := cv_y_flag;
                EXIT;
              END IF;
            END LOOP gt_sales_skip_tbl_loop;
          END IF;
--
          IF ( lv_skip_flag = cv_n_flag ) THEN
            ln_bulk_idx := ln_bulk_idx + 1;
            gt_sales_bulk_tbl( ln_bulk_idx )                  := gt_sales_exp_tbl( sale_idx );
          END IF;
        ELSE
          -- 非大手量販店データを抽出
          lv_skip_flag := cv_n_flag;
          -- スキップ処理
          IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
            <<gt_sales_skip_tbl_loop>>
            FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
              IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
                  = gt_sales_exp_tbl( sale_idx ).sales_exp_header_id ) THEN
                lv_skip_flag := cv_y_flag;
                EXIT;
              END IF;
            END LOOP gt_sales_skip_tbl_loop;
          END IF;
--
          IF ( lv_skip_flag = cv_n_flag ) THEN
            ln_norm_idx := ln_norm_idx + 1;
            gt_sales_norm_tbl( ln_norm_idx )                  := gt_sales_exp_tbl( sale_idx );
          END IF;
        END IF;
      END LOOP gt_sales_exp_tbl_loop;                                  -- 販売実績データループ終了
--
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
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvi.language                  = USERENV( 'LANG' )
        AND  flvi.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
    cv_pad_char             CONSTANT VARCHAR2(1) := '0';     -- PAD関数で埋め込む文字
    cn_pad_num_char         CONSTANT NUMBER := 8;            -- PAD関数で埋め込む文字数
--
    -- *** ローカル変数 ***
    ln_sale_norm_idx2       NUMBER DEFAULT 0;           -- 生成したカードレコードのインデックス
    ln_card_pt              NUMBER DEFAULT 1;           -- カードレコードのインデックス現行位置
    ln_ar_idx               NUMBER DEFAULT 0;           -- 請求取引OIFインデックス
    ln_trx_idx              NUMBER DEFAULT 0;           -- AR配分OIF集約データインデックス;
--
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
    ln_trx_number_id        NUMBER;                     -- 取引明細DFF3用:自動採番番号
    ln_trx_number_tax_id    NUMBER;                     -- 取引明細DFF3用税金用:自動採番番号
    lv_trx_sent_dv          VARCHAR2(30);               -- 請求書発行区分
    lv_trx_number           VARCHAR2(20);               -- AR取引番号
    ln_trx_number_small     NUMBER;                     -- 取引番号:自動採番
    ln_term_amount          NUMBER DEFAULT 0;           -- 一時金額
    ln_max_amount           NUMBER DEFAULT 0;           -- 最大金額
--
    -- *** 取引NO取得キー
      -- 作成区分
    lt_create_class         xxcos_sales_exp_headers.create_class%TYPE;
      -- 納品伝票番号
    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
      -- 納品伝票区分
    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
      -- 請求先顧客
    lt_xchv_cust_id_b       xxcos_cust_hierarchy_v.bill_account_id%TYPE;
--
    -- *** 集約キー(販売実績)
      -- 販売実績ヘッダID
    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
      -- AR取引番号
    lt_trx_number           VARCHAR2(20);
     --カード売り区分
    lt_cash_sale_cls        xxcos_sales_exp_headers.card_sale_class%TYPE;
--
    lv_sum_flag             VARCHAR2(1);                -- 集約フラグ
    lv_sum_card_flag        VARCHAR2(1);                -- カード集約フラグ
    lv_employee_name        VARCHAR2(100);              -- 伝票入力者
    lv_idx_key              VARCHAR2(300);              -- PL/SQL表ソート用インデックス文字列
    ln_now_index            VARCHAR2(300);
    ln_first_index          VARCHAR2(300);
    ln_smb_idx              NUMBER DEFAULT 0;           -- 生成したインデックス
    lv_tbl_nm               VARCHAR2(100);              -- 従業員マスタ
    lv_employee_nm          VARCHAR2(100);              -- 従業員
    lv_header_id_nm         VARCHAR2(100);              -- ヘッダID
    lv_order_no_nm          VARCHAR2(100);              -- 伝票番号
    lv_key_info             VARCHAR2(100);              -- 伝票番号
      -- 品目区分
    lt_goods_prod_class     xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
    lv_err_flag             VARCHAR2(1);                -- エラー用フラグ
    ln_skip_idx             NUMBER DEFAULT 0;           -- スキップ用インデックス;
    lt_goods_item_code      xxcos_sales_exp_lines.item_code%TYPE;
    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
    lt_prod_cls             xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
    lt_inspect_date        xxcos_sales_exp_headers.inspect_date%TYPE;          -- 検収日
    ln_key_dff4             VARCHAR2(100);              -- DFF4
    ln_key_trx_number       VARCHAR2(20);               -- 取引No
    ln_key_ship_customer_id NUMBER;                     -- 出荷先顧客ID
    ln_start_index          NUMBER DEFAULT 1;           -- 取引No毎の開始位置
    ln_ship_flg             NUMBER DEFAULT 0;           -- 出荷先顧客フラグ
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
    -- 集計前データ展開
    --=====================================================================
--
    --テーブルソールする
    -- 正常データのみのPL/SQL表作成
    <<loop_make_sort_data>>
    FOR i IN 1..gt_sales_norm_tbl.COUNT LOOP
      --ソートキーは販売実績ヘッダID、カード売り区分、販売実績明細ID
      lv_idx_key := gt_sales_norm_tbl(i).sales_exp_header_id
                    || gt_sales_norm_tbl(i).dlv_invoice_number
                    || gt_sales_norm_tbl(i).dlv_invoice_class
                    || gt_sales_norm_tbl(i).card_sale_class
                    || gt_sales_norm_tbl(i).cust_gyotai_sho
                    || gt_sales_norm_tbl(i).goods_prod_cls
                    || gt_sales_norm_tbl(i).item_code
                    || gt_sales_norm_tbl(i).red_black_flag
                    || gt_sales_norm_tbl(i).line_id;
      gt_sales_norm_order_tbl(lv_idx_key) := gt_sales_norm_tbl(i);
    END LOOP loop_make_sort_data;
--
    IF gt_sales_norm_order_tbl.COUNT = 0 THEN
      RETURN;
    END IF;
--
    ln_first_index := gt_sales_norm_order_tbl.first;
    ln_now_index := ln_first_index;
--
    WHILE ln_now_index IS NOT NULL LOOP
--
      ln_smb_idx := ln_smb_idx + 1;
      gt_sales_norm_tbl2(ln_smb_idx) := gt_sales_norm_order_tbl(ln_now_index);
      -- 次のインデックスを取得する
      ln_now_index := gt_sales_norm_order_tbl.next(ln_now_index);
--
    END LOOP;--ソート完了
--
    --スキップカウントセット
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
--
    <<gt_sales_norm_tbl2_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl2.COUNT LOOP
--
      -- AR取引番号の自動採番
      IF (  NVL( lt_create_class, 'X' )       <> gt_sales_norm_tbl2( sale_norm_idx ).create_class        -- 作成元区分
         OR NVL( lt_invoice_number, 'X' )     <> gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number  -- 納品伝票No
         OR NVL( lt_invoice_class, 'X' )      <> NVL( gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_class, 'X' )   -- 納品伝票区分
         OR lt_xchv_cust_id_b                 <> gt_sales_norm_tbl2( sale_norm_idx ).xchv_cust_id_b      -- 請求先顧客
         OR (  (  gt_fvd_xiaoka                =  gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho      -- フルサービス（消化）VD :24
               OR gt_gyotai_fvd                =  gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho )    -- フルサービス VD :25
             AND ( lt_header_id                 <> gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id  -- 販売実績ヘッダID
             OR NVL( lt_cash_sale_cls, 'X' ) <> gt_sales_norm_tbl2( sale_norm_idx ).card_sale_class ) )   --カード売り区分
         )
      THEN
--
        BEGIN
          SELECT
            xxcos_trx_number_small_s01.NEXTVAL
          INTO
            ln_trx_number_small
          FROM
            dual
          ;
        END;
--
        -- AR取引番号の編集 納品伝票番号＋シーケンス8桁
        lv_trx_number := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number
                           || LPAD( TO_CHAR( ln_trx_number_small )
                                            ,cn_pad_num_char
                                            ,cv_pad_char
                                           );
--
      END IF;
--
--
      -- 納品伝票番号＋シーケンスの採番
      IF (   NVL( lt_trx_number , 'X' )     <> lv_trx_number                                            -- AR取引番号
         OR  lt_header_id                   <> gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id   -- 販売実績ヘッダID
         )
      THEN
          -- 取引明細DFF4用:自動採番番号
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_tax_id
          FROM
            dual
          ;
        END;
      END IF;
--
--
      -- 取引番号キー
      lt_invoice_class    := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_class;
      lt_create_class     := gt_sales_norm_tbl2( sale_norm_idx ).create_class;
      lt_invoice_number   := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number;
      lt_xchv_cust_id_b   := gt_sales_norm_tbl2( sale_norm_idx ).xchv_cust_id_b;
      lt_cash_sale_cls    := gt_sales_norm_tbl2( sale_norm_idx ).card_sale_class;
--
--
      -- 納品伝票番号＋シーケンスの採番の集約キーの値セット
      lt_trx_number       := lv_trx_number;
      lt_header_id        := gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id;
--
--
        -- AR取引番号
      gt_sales_norm_tbl2( sale_norm_idx ).oif_trx_number   := lv_trx_number;
        -- DFF4
      gt_sales_norm_tbl2( sale_norm_idx ).oif_dff4         := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number
                                                                  || TO_CHAR( ln_trx_number_id );
        -- DFF4税金用
      gt_sales_norm_tbl2( sale_norm_idx ).oif_tax_dff4     := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number
                                                                  || TO_CHAR( ln_trx_number_tax_id );
--
      -- 業態小分類の編集
      IF ( gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
        AND gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho <> gt_gyotai_fvd) THEN
--
          gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho := cv_nvd;                 -- VD以外の業態・納品VD
--
      END IF;
--
    END LOOP gt_sales_norm_tbl2_loop;
--
      --=====================================================================
      -- 請求取引集約処理（非大手量販店）開始
      --=====================================================================
    -- 集約キーの値セット
    lt_trx_number       := gt_sales_norm_tbl2( 1 ).oif_trx_number;            -- AR取引番号
    lt_header_id        := gt_sales_norm_tbl2( 1 ).sales_exp_header_id;   -- 販売実績ヘッダID
--
    -- ラストデータ登録為に、ダミーデータをセット
    gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT + 1 ).sales_exp_header_id
                        := gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT ).sales_exp_header_id;
--
    lt_item_code        := gt_sales_norm_tbl2( 1 ).item_code;
    lt_prod_cls         := gt_sales_norm_tbl2( 1 ).goods_prod_cls;
--
    <<gt_sales_norm_sum_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl2.COUNT LOOP
--
     --=====================================
     --  販売実績元データの集約
     --=====================================
      IF (  lt_trx_number   = gt_sales_norm_tbl2( sale_norm_idx ).oif_trx_number
         AND lt_header_id   = gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id
         )
      THEN
--
        -- 集約するフラグ初期設定
        lv_sum_flag      := cv_y_flag;
--
        -- 本体金額を集約する
        ln_amount := ln_amount + gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
--
        IF ( (
               (
                  NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
               OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
               )
             AND
               NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_norm_tbl2( sale_norm_idx ).goods_prod_cls, 'X' )
             )
           OR
             (
               (
                   NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
               AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
               )
               AND lt_item_code = gt_sales_norm_tbl2( sale_norm_idx ).item_code
             )
           )THEN
             ln_term_amount := ln_term_amount + gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
        ELSIF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
             ln_max_amount       := ln_term_amount;
             ln_term_amount      := gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
             lt_goods_prod_class := lt_prod_cls;
             lt_goods_item_code  := lt_item_code;
        END IF;
        lt_item_code        := gt_sales_norm_tbl2( sale_norm_idx ).item_code;
        lt_prod_cls         := gt_sales_norm_tbl2( sale_norm_idx ).goods_prod_cls;
--
        -- 課税の場合、消費税額を集約する
        IF ( gt_sales_norm_tbl2( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax := ln_tax + gt_sales_norm_tbl2( sale_norm_idx ).tax_amount;
        END IF;
--
      ELSE
--
        IF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
             lt_goods_prod_class := lt_prod_cls;
             lt_goods_item_code  := lt_item_code;
        END IF;
        ln_max_amount       := 0;
        ln_term_amount      := 0;
        lt_item_code        := gt_sales_norm_tbl2( sale_norm_idx ).item_code;
        lt_prod_cls         := gt_sales_norm_tbl2( sale_norm_idx ).goods_prod_cls;
--
        lv_sum_flag := cv_n_flag;
        ln_trx_idx  := sale_norm_idx - 1;
      END IF;
--
      IF ( lv_sum_flag = cv_n_flag ) THEN
--
        --エラーフラグOFF
        lv_err_flag := cv_n_flag;
        lt_inspect_date := gt_sales_norm_tbl2( ln_trx_idx ).inspect_date;
        --=====================================================================
        -- １．支払条件IDの取得
        --=====================================================================
        BEGIN
--
          SELECT term_id
          INTO   ln_term_id
          FROM
            ( SELECT term_id
                    ,cutoff_date
              FROM
                ( --****支払条件１（当月）
                   SELECT rtv11.term_id
                         ,CASE WHEN rtv11.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )  -- 納品月の末日
                                 ELSE  DECODE( rtv11.due_cutoff_day -1, 0
                                                -- 月日付0日の場合、納品月の前月末日を取得
                                               ,TO_DATE( TO_CHAR( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                  cn_min_day, cv_date_format_on_sep ) -1
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR  ( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                         TO_NUMBER( rtv11.due_cutoff_day -1 ), cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv11                           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv11.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv11.end_date_active  , lt_inspect_date )
                     AND  rtv11.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv11.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id         -- 顧客階層ビューの支払条件１
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                   --****支払条件１（翌月）
                   SELECT rtv12.term_id
                         ,CASE WHEN rtv12.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 )  ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY(ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- 納品翌月の末日
                                 ELSE  DECODE( rtv12.due_cutoff_day -1 ,0
                                                -- 月日付0日の場合、納品月の末日
                                               ,LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                  cv_date_format_yyyymm ) || TO_NUMBER( rtv12.due_cutoff_day -1 )
                                                                  , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv12           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv12.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv12.end_date_active  , lt_inspect_date )
                     AND  rtv12.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv12.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id         -- 顧客階層ビューの支払条件１
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                  --****支払条件２（当月）
                   SELECT rtv21.term_id
                         ,CASE WHEN rtv21.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )  -- 納品月の末日
                                 ELSE  DECODE( rtv21.due_cutoff_day -1, 0
                                                -- 月日付0日の場合、納品月の前月末日を取得
                                               ,TO_DATE( TO_CHAR( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                  cn_min_day, cv_date_format_on_sep ) -1
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR  ( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                         TO_NUMBER( rtv21.due_cutoff_day -1 )
                                                         , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv21           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv21.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv21.end_date_active  , lt_inspect_date )
                     AND  rtv21.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv21.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id2        -- 顧客階層ビューの支払条件２
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                  --****支払条件２（翌月）
                   SELECT rtv22.term_id
                         ,CASE WHEN rtv22.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 )  ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY(ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- 納品翌月の末日
                                 ELSE  DECODE( rtv22.due_cutoff_day -1 ,0
                                                -- 月日付0日の場合、納品月の末日
                                               ,LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                  cv_date_format_yyyymm ) || TO_NUMBER( rtv22.due_cutoff_day -1 )
                                                                  , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv22           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv22.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv22.end_date_active  , lt_inspect_date )
                     AND  rtv22.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv22.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id2        -- 顧客階層ビューの支払条件２
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                  --****支払条件３（当月）
                   SELECT rtv31.term_id
                         ,CASE WHEN rtv31.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )  -- 納品月の末日
                                 ELSE  DECODE( rtv31.due_cutoff_day -1, 0
                                                -- 月日付0日の場合、納品月の前月末日を取得
                                               ,TO_DATE( TO_CHAR( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                  cn_min_day, cv_date_format_on_sep ) -1
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR  ( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                         TO_NUMBER( rtv31.due_cutoff_day -1 )
                                                         , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv31           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv31.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv31.end_date_active  , lt_inspect_date )
                     AND  rtv31.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv31.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id3        -- 顧客階層ビューの支払条件３
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                  --****支払条件３（翌月）
                   SELECT rtv32.term_id
                         ,CASE WHEN rtv32.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 )  ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY(ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- 納品翌月の末日
                                 ELSE  DECODE( rtv32.due_cutoff_day -1 ,0
                                                -- 月日付0日の場合、納品月の末日
                                               ,LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                  cv_date_format_yyyymm ) || TO_NUMBER( rtv32.due_cutoff_day -1 )
                                                                  , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv32           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv32.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv32.end_date_active  , lt_inspect_date )
                     AND  rtv32.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv32.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id3        -- 顧客階層ビューの支払条件３
                     AND  ROWNUM = 1
                ) rtv
              WHERE TRUNC( rtv.cutoff_date ) >= gt_sales_norm_tbl2( ln_trx_idx ).inspect_date      -- 納品日
              ORDER BY rtv.cutoff_date
            )
          WHERE  ROWNUM = 1;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 支払条件IDの取得ができない場合
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_term_id_msg
                            , iv_token_name1   => cv_tkn_cust_code
                            , iv_token_value1  => gt_sales_norm_tbl2( ln_trx_idx ).pay_cust_number
                            , iv_token_name2   => cv_tkn_payment_term1
                            , iv_token_value2  => gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id
                            , iv_token_name3   => cv_tkn_payment_term2
                            , iv_token_value3  => gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id2
                            , iv_token_name4   => cv_tkn_payment_term3
                            , iv_token_value4  => gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id3
                            , iv_token_name5   => cv_tkn_procedure_name
                            , iv_token_value5  => cv_prg_name
                            , iv_token_name6   => cv_tkn_header_id
                            , iv_token_value6  => lt_header_id
                            , iv_token_name7   => cv_tkn_order_no
                            , iv_token_value7  => gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              --エラーフラグON
              lv_err_flag := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
        --=====================================================================
        -- ２．取引タイプの取得
        --=====================================================================
--
        lv_trx_idx := gt_sales_norm_tbl2( ln_trx_idx ).create_class
                   || gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class;
        IF ( gt_sel_trx_type_tbl.EXISTS( lv_trx_idx ) ) THEN
          lv_trx_type_nm := gt_sel_trx_type_tbl( lv_trx_idx ).attribute1;
          lv_trx_sent_dv := gt_sel_trx_type_tbl( lv_trx_idx ).attribute2;
        ELSE
          BEGIN
/* 2009/07/27 Ver1.21 Mod Start */
--            SELECT flvm.attribute1 || flvd.attribute1
            SELECT /*+ USE_NL( flvd ) */
                   flvm.attribute1 || flvd.attribute1
/* 2009/07/27 Ver1.21 Mod End   */
                 , rctt.attribute1
            INTO   lv_trx_type_nm
                 , lv_trx_sent_dv
            FROM   fnd_lookup_values              flvm                     -- 作成元区分特定マスタ
                 , fnd_lookup_values              flvd                     -- 納品伝票区分特定マスタ
                 , ra_cust_trx_types_all          rctt                     -- 取引タイプマスタ
            WHERE  flvm.lookup_type               = cv_qct_mkorg_cls
              AND  flvd.lookup_type               = cv_qct_dlv_slp_cls
              AND  flvm.lookup_code               LIKE cv_qcc_code
              AND  flvd.lookup_code               LIKE cv_qcc_code
              AND  flvm.meaning                   = gt_sales_norm_tbl2( ln_trx_idx ).create_class
              AND  flvd.meaning                   = gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
              AND  rctt.name                      = flvm.attribute1 || flvd.attribute1
              AND  rctt.org_id                    = gv_mo_org_id
              AND  flvm.enabled_flag              = cv_enabled_yes
              AND  flvd.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--              AND  flvm.language                  = USERENV( 'LANG' )
--              AND  flvd.language                  = USERENV( 'LANG' )
              AND  flvm.language                  = ct_lang
              AND  flvd.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
                            , iv_token_name2   => cv_tkn_header_id
                            , iv_token_value2  => lt_header_id
                            , iv_token_name3   => cv_tkn_order_no
                            , iv_token_value3  => gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              --エラーフラグON
              lv_err_flag := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
          -- 取得した取引タイプをワークテーブルに設定する
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute1 := lv_trx_type_nm;
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute2 := lv_trx_sent_dv;
--
        END IF;
--
        --=====================================================================
        -- ３．品目明細摘要の取得(「仮受消費税等」以外)
        --=====================================================================
--
        -- 品目明細摘要の存在チェック-->存在している場合、取得必要がない
        IF ( lt_goods_prod_class IS NULL ) THEN
          lv_item_idx := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
                      || lt_goods_item_code;
        ELSE
          lv_item_idx := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
                      || lt_goods_prod_class;
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
              AND  flvi.attribute1                = gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
              AND  flvi.attribute2                = NVL( lt_goods_prod_class,
                                                         lt_goods_item_code )
              AND  flvi.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--              AND  flvi.language                  = USERENV( 'LANG' )
              AND  flvi.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
                            , iv_token_name2   => cv_tkn_header_id
                            , iv_token_value2  => lt_header_id
                            , iv_token_name3   => cv_tkn_order_no
                            , iv_token_value3  => gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              --エラーフラグON
              lv_err_flag := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
          -- 取得したAR品目明細摘要をワークテーブルに設定する
          gt_sel_item_desp_tbl( lv_item_idx ).description := lv_item_desp;
        END IF;
--
        --伝票入力者取得
        BEGIN
          SELECT fu.user_name
          INTO   lv_employee_name
          FROM   fnd_user             fu
                ,per_all_people_f     papf
          WHERE  fu.employee_id       = papf.person_id
/* 2009/07/30 Ver1.21 ADD START */
            AND  gt_sales_norm_tbl2( ln_trx_idx ).inspect_date
                   BETWEEN papf.effective_start_date AND papf.effective_end_date
/* 2009/07/30 Ver1.21 ADD End   */
            AND  papf.employee_number = gt_sales_norm_tbl2( ln_trx_idx ).results_employee_code;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 伝票入力者取得出来ない場合
              lv_tbl_nm :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_tkn_user_msg
                            );
--
              lv_employee_nm :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_employee_code_msg
                            );
--
              lv_header_id_nm :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_header_id_msg
                            );
--
              lv_order_no_nm  :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_order_no_msg
                            );
--
              xxcos_common_pkg.makeup_key_info(
                            iv_item_name1         =>  lv_employee_nm,
                            iv_data_value1        =>  gt_sales_norm_tbl2( ln_trx_idx ).results_employee_code,
                            iv_item_name2         =>  lv_header_id_nm,
                            iv_data_value2        =>  lt_header_id,
                            iv_item_name3         =>  lv_order_no_nm,
                            iv_data_value3        =>  gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number,
                            ov_key_info           =>  lv_key_info,                --編集されたキー情報
                            ov_errbuf             =>  lv_errbuf,                  --エラーメッセージ
                            ov_retcode            =>  lv_retcode,                 --リターンコード
                            ov_errmsg             =>  lv_errmsg                   --ユーザ・エラー・メッセージ
                          );
--
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_data_get_msg
                            , iv_token_name1   => cv_tkn_tbl_nm
                            , iv_token_value1  => lv_tbl_nm
                            , iv_token_name2   => cv_tkn_key_data
                            , iv_token_value2  => lv_key_info
                          );
              lv_errbuf  := lv_errmsg;
--
              --エラーフラグON
              lv_err_flag := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
        END;
      END IF;
--
      --スキップ処理
      IF ( lv_err_flag = cv_y_flag ) THEN
         ln_skip_idx := ln_skip_idx + 1;
         gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id;
      END IF;
--
      --==============================================================
      -- ４．AR請求取引OIFデータ作成
      --==============================================================
--
      -- -- 集約フラグ’N'の場合、AR請求取引OIFデータ作成する
      IF ( lv_sum_flag = cv_n_flag ) THEN
--
        -- AR請求取引OIFの収益行
        ln_ar_idx   := ln_ar_idx  + 1;
--
        -- AR請求取引OIFデータ作成(収益行)===>NO.1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).oif_dff4;
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id;
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
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --内税時、金額は本体＋税金
          gt_ar_interface_tbl( ln_ar_idx ).amount       := ln_amount + ln_tax;
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        IF (  gt_sales_norm_tbl2( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_norm_tbl2( ln_trx_idx ).cash_and_card   = 0 ) THEN
        -- 現金の場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- 請求先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_b;
                                                        -- 請求先顧客ID
        ELSE
        -- カードの場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_norm_tbl2( ln_trx_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_norm_tbl2( ln_trx_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := gt_sales_norm_tbl2( ln_trx_idx ).oif_trx_number;
                                                        -- 収益行のみ：AR取引番号

        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_sales_norm_tbl2( ln_trx_idx ).dlv_inv_line_no;
                                                        -- 収益行のみ：AR取引明細番号

        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- 収益行のみ：数量=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount;
                                                        -- 収益行のみ：販売単価=本体金額
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --内税時、販売単価は本体＋税金
          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := ln_amount + ln_tax;
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_norm_tbl2( ln_trx_idx ).tax_code;
                                                        -- 税金コード(税区分)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- ヘッダーDFFカテゴリ
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).sales_base_code;
                                                        -- ヘッダーdff5(起票部門)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := lv_employee_name;
                                                        -- ヘッダーdff6(伝票入力者)
        IF( lv_trx_sent_dv = cv_n_flag ) THEN
          gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_hold;
                                                        -- ヘッダーDFF7(予備１)
        ELSIF( lv_trx_sent_dv = cv_y_flag ) THEN
          gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- ヘッダーDFF7(予備１)
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- ヘッダーdff8(予備２)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- ヘッダーdff9(予備3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).card_receiv_base;
                                                        -- ヘッダーDFF11(入金拠点)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_out_tax_cls 
          OR gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_exp_tax_cls ) THEN
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
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).oif_tax_dff4;
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id;
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
        IF (  gt_sales_norm_tbl2( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_norm_tbl2( ln_trx_idx ).cash_and_card   = 0 ) THEN
          -- 現金の場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- 請求先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_b;
                                                        -- 請求先顧客ID
        ELSE
        -- カードの場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- リンク先明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_ar_interface_tbl( ln_ar_idx - 1 ).interface_line_attribute3;
                                                        -- リンク先明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := gt_ar_interface_tbl( ln_ar_idx - 1 ).interface_line_attribute4;
                                                        -- リンク先明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id;
                                                        -- リンク先明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_norm_tbl2( ln_trx_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_norm_tbl2( ln_trx_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_norm_tbl2( ln_trx_idx ).tax_code;
                                                        -- 税金コード
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_out_tax_cls  
          OR gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_exp_tax_cls ) THEN
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
      END IF;
--
      IF ( lv_sum_flag = cv_n_flag ) THEN
        -- 集約キーと集約金額のリセット
        lt_trx_number      := gt_sales_norm_tbl2( sale_norm_idx ).oif_trx_number;        -- AR取引番号
        lt_header_id       := gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id;   -- 販売実績ヘッダID
--
        ln_amount := gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
        IF ( gt_sales_norm_tbl2( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax  := gt_sales_norm_tbl2( sale_norm_idx ).tax_amount;
        ELSE
          ln_tax  := 0;
        END IF;
      END IF;
--
    END LOOP gt_sales_norm_sum_loop;                    -- 販売実績データループ終了
    <<gt_sales_bulk_check_loop>>
    FOR ln_ar_idx IN 1 .. gt_ar_interface_tbl.COUNT LOOP
      -- 開始：1取引No内での出荷先顧客チェック
--
      -- KEYが代わったら
      IF (
           (
              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NULL )
              AND
              ( gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4 <> NVL( ln_key_dff4, 'X') )
           )
           OR
           (
              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NOT NULL )
              AND
              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number <> NVL( ln_key_trx_number, 'X') )
           )
         )THEN
--
        -- 出荷先顧客フラグがONの場合
        IF ( ln_ship_flg = cn_ship_flg_on )
        THEN
          <<gt_sales_bulk_ship_clear_loop>>
          FOR start_index IN ln_start_index .. ln_ar_idx - 1 LOOP
            -- 開始：1取引No内での出荷先顧客チェック
--
            -- 出荷先顧客IDをクリア
            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
            -- 最後の行
            IF ( gt_ar_interface_tbl.COUNT = ln_ar_idx )
            THEN
              -- 出荷先顧客IDをクリア
              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id := NULL;
              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id  := NULL;
            END IF;
--
            -- 終了：1取引No内での出荷先顧客チェック
          END LOOP gt_sales_bulk_ship_clear_loop;
        END IF;
--
        -- 取引Noを取得
        ln_key_trx_number := gt_ar_interface_tbl( ln_ar_idx ).trx_number;
--
        -- DFF4を取得
        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
        -- 出荷先顧客IDを取得
        ln_key_ship_customer_id := gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id;
--
        -- 取引Noの開始位置を取得
        ln_start_index := ln_ar_idx;
--
        -- フラグを初期化
        ln_ship_flg := cn_ship_flg_off;
--
      ELSE
        -- 出荷先顧客が同じか？
        IF ( gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id <> ln_key_ship_customer_id ) THEN
          -- 違う場合、出荷先顧客フラグをONにする
          ln_ship_flg := cn_ship_flg_on;
--
        END IF;
        -- DFF4を取得
        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
        IF ( ln_ship_flg = cn_ship_flg_on AND ln_ar_idx = gt_ar_interface_tbl.COUNT ) THEN
          <<gt_sales_bulk_ship_clear_loop>>
          FOR start_index IN ln_start_index .. ln_ar_idx LOOP
            -- 開始：1取引No内での出荷先顧客チェック
--
            -- 出荷先顧客IDをクリア
            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
            -- 終了：1取引No内での出荷先顧客チェック
          END LOOP gt_sales_bulk_ship_clear_loop;
        END IF;
--
      END IF;
      -- 終了：1取引No内での出荷先顧客チェック
    END LOOP gt_sales_bulk_check_loop;
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
    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- 集約キー：税金コード
    lt_header_id        xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- 集約キー：販売実績ヘッダID
    ln_amount           NUMBER DEFAULT 0;                                -- 集約後金額
    ln_tax              NUMBER DEFAULT 0;                                -- 集約後消費税金額
    ln_ar_dis_idx       NUMBER DEFAULT 0;                                -- AR会計配分集約インデックス
    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR会計配分OIFインデックス
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- 仕訳生成カウント
    lv_rec_flag         VARCHAR2(1);                                     -- RECフラグ
    -- AR取引番号
    lt_trx_number       VARCHAR2(20);
    lv_err_flag         VARCHAR2(1);                                     -- エラー用フラグ
    lv_jour_flag        VARCHAR2(1);                                     -- エラー用フラグ
    ln_skip_idx         NUMBER DEFAULT 0;                                -- スキップ用インデックス;
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
    --スキップカウントセット
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
    --=====================================
    -- 3.AR会計配分データ作成
    --=====================================
    -- 集約キーの値セット
    lt_invoice_number   := gt_sales_norm_tbl2( 1 ).dlv_invoice_number;
    lt_item_code        := gt_sales_norm_tbl2( 1 ).item_code;
    lt_prod_cls         := gt_sales_norm_tbl2( 1 ).goods_prod_cls;
    lt_gyotai_sho       := gt_sales_norm_tbl2( 1 ).cust_gyotai_sho;
    lt_card_sale_class  := gt_sales_norm_tbl2( 1 ).card_sale_class;
    lt_tax_code         := gt_sales_norm_tbl2( 1 ).tax_code;
    lt_invoice_class    := gt_sales_norm_tbl2( 1 ).dlv_invoice_class;
    lt_red_black_flag   := gt_sales_norm_tbl2( 1 ).red_black_flag;
    lt_header_id        := gt_sales_norm_tbl2( 1 ).sales_exp_header_id;
--
    -- ラストデータ登録為に、ダミーデータをセットする
    gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT + 1 ).sales_exp_header_id
                        := gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT ).sales_exp_header_id;
--
    <<gt_sales_norm_tbl2_loop>>
    FOR dis_sum_idx IN 1 .. gt_sales_norm_tbl2.COUNT LOOP
--
      -- AR会計配分データ集約開始
      IF ( lt_invoice_number = gt_sales_norm_tbl2( dis_sum_idx ).dlv_invoice_number
        AND
          (
            (
              (
                 NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
              OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
              )
            AND
              NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_norm_tbl2( dis_sum_idx ).goods_prod_cls, 'X' )
            )
          OR
            (
              (
                  NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
              AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
              )
              AND lt_item_code = gt_sales_norm_tbl2( dis_sum_idx ).item_code
            )
          )
        AND lt_gyotai_sho      = gt_sales_norm_tbl2( dis_sum_idx ).cust_gyotai_sho
        AND lt_card_sale_class = gt_sales_norm_tbl2( dis_sum_idx ).card_sale_class
        AND lt_tax_code        = gt_sales_norm_tbl2( dis_sum_idx ).tax_code
        AND lt_header_id       = gt_sales_norm_tbl2( dis_sum_idx ).sales_exp_header_id
        )
      THEN
--
        -- 集約するフラグ初期設定
        lv_sum_flag := cv_y_flag;
--
        -- 本体金額と消費税額を集約する
        ln_amount := ln_amount + gt_sales_norm_tbl2( dis_sum_idx ).pure_amount;
        ln_tax    := ln_tax    + gt_sales_norm_tbl2( dis_sum_idx ).tax_amount;
      ELSE
        lv_sum_flag := cv_n_flag;
        ln_dis_idx  := dis_sum_idx - 1;
      END IF;
--
      -- -- 集約フラグ’N'の場合、下記AR会計配分OIF作成処理を行う
      IF ( lv_sum_flag = cv_n_flag ) THEN

        IF ( NVL( lt_trx_number, 'X' ) <> gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number ) THEN
          lv_rec_flag := cv_y_flag;
        ELSE
          lv_rec_flag := cv_n_flag;
        END IF;
        lt_trx_number      := gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number;        -- AR取引番号
--
        -- 仕訳生成カウント初期値
        ln_jour_cnt := 1;
        lv_jour_flag := cv_n_flag;
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
            lt_segment3 := gt_jour_cls_tbl( jcls_idx ).segment3;
--
            --=====================================
            -- 2.勘定科目CCIDの取得
            --=====================================
            -- 勘定科目セグメント１～セグメント８よりCCID取得
            lv_ccid_idx := gv_company_code                                   -- セグメント１(会社コード)
                        || NVL( gt_jour_cls_tbl( jcls_idx ).segment2,        -- セグメント２（部門コード）
                                gt_sales_norm_tbl2( ln_dis_idx ).sales_base_code )
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
                                  gt_sales_norm_tbl2( ln_dis_idx ).sales_base_code )
                           , lt_segment3
                           , gt_jour_cls_tbl( jcls_idx ).segment4
                           , gt_jour_cls_tbl( jcls_idx ).segment5
                           , gt_jour_cls_tbl( jcls_idx ).segment6
                           , gt_jour_cls_tbl( jcls_idx ).segment7
                           , gt_jour_cls_tbl( jcls_idx ).segment8
                         );
--
              --エラーフラグOFF
              lv_err_flag := cv_n_flag;
              IF ( lt_ccid IS NULL ) THEN
                -- CCIDが取得できない場合
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm
                                , iv_name              => cv_ccid_nodata_msg
                                , iv_token_name1       => cv_tkn_segment1
                                , iv_token_value1      => gv_company_code
                                , iv_token_name2       => cv_tkn_segment2
                                , iv_token_value2      => NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                                               gt_sales_norm_tbl2( ln_dis_idx ).sales_base_code )
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
                                , iv_token_name9       => cv_tkn_header_id
                                , iv_token_value9      => lt_header_id
                                , iv_token_name10      => cv_tkn_order_no
                                , iv_token_value10     => lt_invoice_number
                              );
                lv_errbuf  := lv_errmsg;
                lv_err_flag  := cv_y_flag;
                gn_warn_flag := cv_y_flag;
                -- 空行出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => cv_blank
                );
--
                -- メッセージ出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => lv_errmsg
                );
--
                -- 空行出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => cv_blank
                );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
              END IF;
--
              -- 取得したCCIDをワークテーブルに設定する
              gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
--
            END IF;                                       -- CCID編集終了
--
            --スキップ処理
            IF ( lv_err_flag = cv_y_flag ) THEN
               ln_skip_idx := ln_skip_idx + 1;
               gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
            END IF;
            --=====================================
            -- AR会計配分OIFデータ設定
            --=====================================
            IF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rev ) THEN
              -- 収益行
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
--
              -- AR会計配分OIFの設定項目
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- 取引明細コンテキスト値「販売実績」をセット
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF1「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).oif_dff4;
                                                          -- 取引明細DFF4:納品伝票番号+自動採番
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5：「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rev;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_amount;
                                                          -- 金額(明細金額)
              IF ( gt_sales_norm_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --内税時、金額は本体＋税金
                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := ln_amount + ln_tax;
              END IF;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_amount;
                                                          -- パーセント(割合)
              IF ( gt_sales_norm_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --内税時、 パーセント(割合は本体＋税金
                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := ln_amount + ln_tax;
              END IF;
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
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rec AND lv_rec_flag = cv_y_flag ) THEN
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
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).oif_dff4;
                                                          -- 取引明細DFF4納品伝票番号+自動採番
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5	「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rec;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- パーセント(割合)
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
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).oif_tax_dff4;
                                                          -- 取引明細DFF4：納品伝票番号+自動採番
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_tax;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_tax;
                                                          -- 金額(明細金額)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_tax;
                                                          -- パーセント(割合)
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
        IF ( ln_jour_cnt = 1 AND dis_sum_idx <> gt_sales_norm_tbl2.COUNT ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application       => cv_xxcos_short_nm
                          , iv_name              => cv_jour_no_msg
                          , iv_token_name1       => cv_tkn_invoice_cls
                          , iv_token_value1      => lt_invoice_class
                          , iv_token_name2       => cv_tkn_prod_cls
                          , iv_token_value2      => NVL( lt_prod_cls, lt_item_code )
                          , iv_token_name3       => cv_tkn_gyotai_sho
                          , iv_token_value3      => lt_gyotai_sho
                          , iv_token_name4       => cv_tkn_sale_cls
                          , iv_token_value4      => lt_card_sale_class
                          , iv_token_name5       => cv_tkn_red_black_flag
                          , iv_token_value5      => lt_red_black_flag
                          , iv_token_name6       => cv_tkn_header_id
                          , iv_token_value6      => lt_header_id
                          , iv_token_name7       => cv_tkn_order_no
                          , iv_token_value7      => lt_invoice_number
                        );
          lv_errbuf  := lv_errmsg;
          lv_jour_flag  := cv_y_flag;
          gn_warn_flag := cv_y_flag;
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
--
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
--
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
--
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
          --スキップ処理
          IF ( lv_jour_flag = cv_y_flag ) THEN
             ln_skip_idx := ln_skip_idx + 1;
             gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
          END IF;
        END IF;
--
--
        -- 金額の設定
        ln_amount        := gt_sales_norm_tbl2( dis_sum_idx ).pure_amount;
        ln_tax           := gt_sales_norm_tbl2( dis_sum_idx ).tax_amount;
      END IF;                                             -- 集約キー毎にAR会計配分OIFデータの集約終了
--
      -- 集約キーのリセット
      lt_invoice_number   := gt_sales_norm_tbl2( dis_sum_idx ).dlv_invoice_number;
      lt_item_code        := gt_sales_norm_tbl2( dis_sum_idx ).item_code;
      lt_prod_cls         := gt_sales_norm_tbl2( dis_sum_idx ).goods_prod_cls;
      lt_gyotai_sho       := gt_sales_norm_tbl2( dis_sum_idx ).cust_gyotai_sho;
      lt_card_sale_class  := gt_sales_norm_tbl2( dis_sum_idx ).card_sale_class;
      lt_tax_code         := gt_sales_norm_tbl2( dis_sum_idx ).tax_code;
      lt_invoice_class    := gt_sales_norm_tbl2( dis_sum_idx ).dlv_invoice_class;
      lt_red_black_flag   := gt_sales_norm_tbl2( dis_sum_idx ).red_black_flag;
      lt_header_id        := gt_sales_norm_tbl2( dis_sum_idx ).sales_exp_header_id;
--
    END LOOP gt_sales_norm_tbl2_loop;                      -- AR会計配分集約データループ終了
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
    cv_pad_char             CONSTANT VARCHAR2(1) := '0';     -- PAD関数で埋め込む文字
    cn_pad_num_char         CONSTANT NUMBER := 3;            -- PAD関数で埋め込む文字数
--
    -- *** ローカル変数 ***
    ln_sale_bulk_idx2       NUMBER DEFAULT 0;           -- 生成したカードレコードのインデックス
    ln_card_pt              NUMBER DEFAULT 1;           -- カードレコードのインデックス現行位置
    ln_ar_idx               NUMBER DEFAULT 0;           -- 請求取引OIFインデックス
    ln_trx_idx              NUMBER DEFAULT 0;           -- AR配分OIF集約データインデックス;
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
    ln_trx_number_id        NUMBER;                     -- 取引明細DFF3用:自動採番番号
    ln_trx_number_tax_id    NUMBER;                     -- 取引明細DFF3用税金用:自動採番番号
    lv_trx_sent_dv          VARCHAR2(30);               -- 請求書発行区分
    lv_trx_number           VARCHAR2(20);               -- AR取引番号
    ln_trx_number_large     NUMBER;                    -- 取引番号:自動採番
    ln_sales_h_tbl_idx      NUMBER DEFAULT 0;           -- 販売実績ヘッダ更新用インデックス
    ln_key_trx_number       VARCHAR2(20);               -- 取引No
    ln_key_dff4             VARCHAR2(100);              -- DFF4
    ln_key_ship_customer_id NUMBER;                     -- 出荷先顧客ID
    ln_start_index          NUMBER DEFAULT 1;           -- 取引No毎の開始位置
    ln_ship_flg             NUMBER DEFAULT 0;           -- 出荷先顧客フラグ
    ln_term_amount          NUMBER DEFAULT 0;           -- 一時金額
    ln_max_amount           NUMBER DEFAULT 0;           -- 最大金額
--
    -- *** 取引NO取得キー
      -- 作成区分
    lt_create_class         xxcos_sales_exp_headers.create_class%TYPE;
      -- 納品伝票番号
    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
      -- 納品伝票区分
    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
      -- 請求先顧客
    lt_xchv_cust_id_b       xxcos_cust_hierarchy_v.bill_account_id%TYPE;
      -- 売上計上日
    lt_sales_date           xxcos_sales_exp_headers.inspect_date%TYPE;
--
    -- *** 集約キー(販売実績)
      -- 販売実績ヘッダID
    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
      -- AR取引番号
    lt_trx_number           VARCHAR2(20);
     --カード売り区分
    lt_cash_sale_cls        xxcos_sales_exp_headers.card_sale_class%TYPE;
--
    lv_sum_flag             VARCHAR2(1);                -- 集約フラグ
    lv_sum_card_flag        VARCHAR2(1);                -- カード集約フラグ
    lv_employee_name        VARCHAR2(100);              -- 伝票入力者
    lv_idx_key              VARCHAR2(300);              -- PL/SQL表ソート用インデックス文字列
    ln_now_index            VARCHAR2(300);
    ln_first_index          VARCHAR2(300);
    ln_smb_idx              NUMBER DEFAULT 0;           -- 生成したインデックス
    lv_tbl_nm               VARCHAR2(100);              -- 従業員マスタ
    lv_employee_nm          VARCHAR2(100);              -- 従業員
    lv_header_id_nm         VARCHAR2(100);              -- ヘッダID
    lv_order_no_nm          VARCHAR2(100);              -- 伝票番号
    lv_key_info             VARCHAR2(100);              -- 伝票番号
      -- 品目区分
    lt_goods_prod_class     xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
    lv_err_flag             VARCHAR2(1);                -- エラー用フラグ
    ln_skip_idx             NUMBER DEFAULT 0;           -- スキップ用インデックス;
    lt_goods_item_code      xxcos_sales_exp_lines.item_code%TYPE;
    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
    lt_prod_cls             xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
    lt_inspect_date        xxcos_sales_exp_headers.inspect_date%TYPE;          -- 検収日
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
    -- 集計前データ展開
    --=====================================================================
--
    --テーブルソールする
    -- 正常データのみのPL/SQL表作成
    <<loop_make_sort_data>>
    FOR i IN 1..gt_sales_bulk_tbl.COUNT LOOP
      --ソートキーは販売実績ヘッダID、カード売り区分、販売実績明細ID
      lv_idx_key := gt_sales_bulk_tbl(i).sales_exp_header_id
                    || gt_sales_bulk_tbl(i).dlv_invoice_number
                    || gt_sales_bulk_tbl(i).dlv_invoice_class
                    || gt_sales_bulk_tbl(i).card_sale_class
                    || gt_sales_bulk_tbl(i).cust_gyotai_sho
                    || gt_sales_bulk_tbl(i).goods_prod_cls
                    || gt_sales_bulk_tbl(i).item_code
                    || gt_sales_bulk_tbl(i).red_black_flag
                    || gt_sales_bulk_tbl(i).line_id;
      gt_sales_bulk_order_tbl(lv_idx_key) := gt_sales_bulk_tbl(i);
    END LOOP loop_make_sort_data;
--
    IF gt_sales_bulk_order_tbl.COUNT = 0 THEN
      RETURN;
    END IF;
--
    ln_first_index := gt_sales_bulk_order_tbl.first;
    ln_now_index := ln_first_index;
--
    WHILE ln_now_index IS NOT NULL LOOP
--
      ln_smb_idx := ln_smb_idx + 1;
      gt_sales_bulk_tbl2(ln_smb_idx) := gt_sales_bulk_order_tbl(ln_now_index);
      -- 次のインデックスを取得する
      ln_now_index := gt_sales_bulk_order_tbl.next(ln_now_index);
--
    END LOOP;--ソート完了
--
    -- 請求取引テーブルの非大手量販店データカウントセット
    ln_ar_idx := gt_ar_interface_tbl.COUNT;
--
    --スキップカウントセット
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
--
    <<gt_sales_bulk_tbl2_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl2.COUNT LOOP
--
--
      -- AR取引番号の自動採番
      IF (  NVL( lt_create_class, 'X' )        <> gt_sales_bulk_tbl2( sale_bulk_idx ).create_class        -- 作成元区分
         OR lt_sales_date                      <> gt_sales_bulk_tbl2( sale_bulk_idx ).inspect_date  -- 売上計上日
         OR NVL( lt_invoice_class, 'X' )       <> NVL( gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_class, 'X' )   -- 納品伝票区分
         OR lt_xchv_cust_id_b                  <> gt_sales_bulk_tbl2( sale_bulk_idx ).xchv_cust_id_b      -- 請求先顧客
         OR (  ( gt_fvd_xiaoka                 =  gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho      -- フルサービス（消化）VD :24
               OR gt_gyotai_fvd                =  gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho )    -- フルサービス VD :25
             AND ( lt_header_id                 <> gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id  -- 販売実績ヘッダID
             OR NVL( lt_cash_sale_cls, 'X' ) <> gt_sales_bulk_tbl2( sale_bulk_idx ).card_sale_class ) )   --カード売り区分
         )
      THEN
--
        BEGIN
          SELECT
            xxcos_trx_number_large_s01.NEXTVAL
          INTO
            ln_trx_number_large
          FROM
            dual
          ;
        END;
--
        -- AR取引番号の編集 売上計上日(YYYYMMDD：8桁) + 請求先顧客番号(9桁)＋シーケンス3桁
        lv_trx_number := TO_CHAR( gt_sales_bulk_tbl2( sale_bulk_idx ).inspect_date,cv_date_format_non_sep )
                           || gt_sales_bulk_tbl2( sale_bulk_idx ).xchv_cust_number_b
                           || LPAD( TO_CHAR( ln_trx_number_large )
                                            ,cn_pad_num_char
                                            ,cv_pad_char
                                           );
--
      END IF;
--
--
      -- 納品伝票番号＋シーケンスの採番
      IF (  NVL(  lt_trx_number, 'X' )    <> lv_trx_number                                            -- AR取引番号
         OR  lt_header_id                 <> gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id   -- 販売実績ヘッダID
         )
      THEN
          -- 取引明細DFF4用:自動採番番号
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_id
          FROM
            dual
          ;
        END;
--
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
            ln_trx_number_tax_id
          FROM
            dual
          ;
        END;
      END IF;
--
--
      -- 取引番号キー
      lt_invoice_class    := gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_class;
      lt_create_class     := gt_sales_bulk_tbl2( sale_bulk_idx ).create_class;
      lt_sales_date       := gt_sales_bulk_tbl2( sale_bulk_idx ).inspect_date;
      lt_xchv_cust_id_b   := gt_sales_bulk_tbl2( sale_bulk_idx ).xchv_cust_id_b;
      lt_cash_sale_cls    := gt_sales_bulk_tbl2( sale_bulk_idx ).card_sale_class;
--
--
      -- 納品伝票番号＋シーケンスの採番の集約キーの値セット
      lt_trx_number       := lv_trx_number;
      lt_header_id        := gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id;
--
--
        -- AR取引番号
      gt_sales_bulk_tbl2( sale_bulk_idx ).oif_trx_number   := lv_trx_number;
        -- DFF4
      gt_sales_bulk_tbl2( sale_bulk_idx ).oif_dff4         := gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_number
                                                                  || TO_CHAR( ln_trx_number_id );
      gt_sales_bulk_tbl2( sale_bulk_idx ).oif_tax_dff4     := gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_number
                                                                    || TO_CHAR( ln_trx_number_tax_id );
--
        -- 業態小分類の編集
      IF ( gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
        AND gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho <> gt_gyotai_fvd) THEN
--
          gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho := cv_nvd;                 -- VD以外の業態・納品VD
--
      END IF;
--
    END LOOP gt_sales_bulk_tbl2_loop;
--
      --=====================================================================
      -- 請求取引集約処理（大手量販店）開始
      --=====================================================================
    -- 集約キーの値セット
    lt_trx_number       := gt_sales_bulk_tbl2( 1 ).oif_trx_number;            -- AR取引番号
    lt_header_id        := gt_sales_bulk_tbl2( 1 ).sales_exp_header_id;   -- 販売実績ヘッダID
--
    -- ラストデータ登録為に、ダミーデータをセット
    gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT + 1 ).sales_exp_header_id
                        := gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT ).sales_exp_header_id;
--
    lt_item_code        := gt_sales_bulk_tbl2( 1 ).item_code;
    lt_prod_cls         := gt_sales_bulk_tbl2( 1 ).goods_prod_cls;
--
    <<gt_sales_bulk_sum_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl2.COUNT LOOP
--
     --=====================================
     --  販売実績元データの集約
     --=====================================
      IF (  lt_trx_number   = gt_sales_bulk_tbl2( sale_bulk_idx ).oif_trx_number
         AND lt_header_id   = gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id
         )
      THEN
--
        -- 集約するフラグ初期設定
        lv_sum_flag      := cv_y_flag;
--
        -- 本体金額を集約する
        ln_amount := ln_amount + gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
--
       IF ( (
               (
                  NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
               OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
               )
             AND
               NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_bulk_tbl2( sale_bulk_idx ).goods_prod_cls, 'X' )
             )
           OR
             (
               (
                   NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
               AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
               )
               AND lt_item_code = gt_sales_bulk_tbl2( sale_bulk_idx ).item_code
             )
           )THEN
             ln_term_amount := ln_term_amount + gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
        ELSIF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
             ln_max_amount       := ln_term_amount;
             ln_term_amount      := gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
             lt_goods_prod_class := lt_prod_cls;
             lt_goods_item_code  := lt_item_code;
        END IF;
        lt_item_code        := gt_sales_bulk_tbl2( sale_bulk_idx ).item_code;
        lt_prod_cls         := gt_sales_bulk_tbl2( sale_bulk_idx ).goods_prod_cls;
--
        -- 課税の場合、消費税額を集約する
        IF ( gt_sales_bulk_tbl2( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax := ln_tax + gt_sales_bulk_tbl2( sale_bulk_idx ).tax_amount;
        END IF;
--
      ELSE
--
        IF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
             lt_goods_prod_class := lt_prod_cls;
             lt_goods_item_code  := lt_item_code;
        END IF;
        ln_max_amount       := 0;
        ln_term_amount      := 0;
        lt_item_code        := gt_sales_bulk_tbl2( sale_bulk_idx ).item_code;
        lt_prod_cls         := gt_sales_bulk_tbl2( sale_bulk_idx ).goods_prod_cls;
--
        lv_sum_flag := cv_n_flag;
        ln_trx_idx  := sale_bulk_idx - 1;
      END IF;
--
      IF ( lv_sum_flag = cv_n_flag ) THEN
--
        --エラーフラグOFF
        lv_err_flag := cv_n_flag;
        lt_inspect_date := gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date;
        --=====================================================================
        -- １．支払条件IDの取得
        --=====================================================================
        BEGIN
--
          SELECT term_id
          INTO   ln_term_id
          FROM
            ( SELECT term_id
                    ,cutoff_date
              FROM
                ( --****支払条件１（当月）
                   SELECT rtv11.term_id
                         ,CASE WHEN rtv11.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )  -- 納品月の末日
                                 ELSE  DECODE( rtv11.due_cutoff_day -1, 0
                                                -- 月日付0日の場合、納品月の前月末日を取得
                                               ,TO_DATE( TO_CHAR( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                  cn_min_day, cv_date_format_on_sep ) -1
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR  ( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                         TO_NUMBER( rtv11.due_cutoff_day -1 ), cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv11                           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv11.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv11.end_date_active  , lt_inspect_date )
                     AND  rtv11.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv11.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id         -- 顧客階層ビューの支払条件１
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                   --****支払条件１（翌月）
                   SELECT rtv12.term_id
                         ,CASE WHEN rtv12.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY(ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- 納品翌月の末日
                                 ELSE  DECODE( rtv12.due_cutoff_day -1 ,0
                                                -- 月日付0日の場合、納品月の末日
                                               ,LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                  cv_date_format_yyyymm ) || TO_NUMBER( rtv12.due_cutoff_day -1 )
                                                                  , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv12           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv12.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv12.end_date_active  , lt_inspect_date )
                     AND  rtv12.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv12.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id         -- 顧客階層ビューの支払条件１
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                  --****支払条件２（当月）
                   SELECT rtv21.term_id
                         ,CASE WHEN rtv21.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )  -- 納品月の末日
                                 ELSE  DECODE( rtv21.due_cutoff_day -1, 0
                                                -- 月日付0日の場合、納品月の前月末日を取得
                                               ,TO_DATE( TO_CHAR( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                  cn_min_day, cv_date_format_on_sep ) -1
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR  ( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                         TO_NUMBER( rtv21.due_cutoff_day -1 )
                                                         , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv21           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv21.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv21.end_date_active  , lt_inspect_date )
                     AND  rtv21.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv21.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id2        -- 顧客階層ビューの支払条件２
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                  --****支払条件２（翌月）
                   SELECT rtv22.term_id
                         ,CASE WHEN rtv22.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY(ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- 納品翌月の末日
                                 ELSE  DECODE( rtv22.due_cutoff_day -1 ,0
                                                -- 月日付0日の場合、納品月の末日
                                               ,LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                  cv_date_format_yyyymm ) || TO_NUMBER( rtv22.due_cutoff_day -1 )
                                                                  , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv22           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv22.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv22.end_date_active  , lt_inspect_date )
                     AND  rtv22.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv22.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id2        -- 顧客階層ビューの支払条件２
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                  --****支払条件３（当月）
                   SELECT rtv31.term_id
                         ,CASE WHEN rtv31.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )  -- 納品月の末日
                                 ELSE  DECODE( rtv31.due_cutoff_day -1, 0
                                                -- 月日付0日の場合、納品月の前月末日を取得
                                               ,TO_DATE( TO_CHAR( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                  cn_min_day, cv_date_format_on_sep ) -1
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR  ( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                         TO_NUMBER( rtv31.due_cutoff_day -1 )
                                                         , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv31           -- 支払条件マスタ
                   WHERE  lt_inspect_date   BETWEEN NVL( rtv31.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                                AND NVL( rtv31.end_date_active  , lt_inspect_date )
                     AND  rtv31.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv31.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id3        -- 顧客階層ビューの支払条件３
                     AND  ROWNUM = 1
--
                  UNION ALL
--
                  --****支払条件３（翌月）
                   SELECT rtv32.term_id
                         ,CASE WHEN rtv32.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) ) -- 支払日-1>末日
                                 THEN  LAST_DAY(ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- 納品翌月の末日
                                 ELSE  DECODE( rtv32.due_cutoff_day -1 ,0
                                                -- 月日付0日の場合、納品月の末日
                                               ,LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )
                                                -- 指定日の-1日を取得
                                               ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                  cv_date_format_yyyymm ) || TO_NUMBER( rtv32.due_cutoff_day -1 )
                                                                  , cv_date_format_on_sep
                                                       )
                                             )
                          END cutoff_date
                   FROM   ra_terms_vl      rtv32           -- 支払条件マスタ
                   WHERE  lt_inspect_date  BETWEEN NVL( rtv32.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                               AND NVL( rtv32.end_date_active  , lt_inspect_date )
                     AND  rtv32.due_cutoff_day IS NOT NULL                                         -- 締開始日or最終月日付が未設定は対象外
                     AND  rtv32.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id3        -- 顧客階層ビューの支払条件３
                     AND  ROWNUM = 1
                ) rtv
              WHERE TRUNC( rtv.cutoff_date ) >= gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date      -- 検収日
              ORDER BY rtv.cutoff_date
            )
          WHERE  ROWNUM = 1;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 支払条件IDの取得ができない場合
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_term_id_msg
                            , iv_token_name1   => cv_tkn_cust_code
                            , iv_token_value1  => gt_sales_bulk_tbl2( ln_trx_idx ).pay_cust_number
                            , iv_token_name2   => cv_tkn_payment_term1
                            , iv_token_value2  => gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id
                            , iv_token_name3   => cv_tkn_payment_term2
                            , iv_token_value3  => gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id2
                            , iv_token_name4   => cv_tkn_payment_term3
                            , iv_token_value4  => gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id3
                            , iv_token_name5   => cv_tkn_procedure_name
                            , iv_token_value5  => cv_prg_name
                            , iv_token_name6   => cv_tkn_header_id
                            , iv_token_value6  => lt_header_id
                            , iv_token_name7   => cv_tkn_order_no
                            , iv_token_value7  => gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              lv_err_flag  := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
        --=====================================================================
        -- ２．取引タイプの取得
        --=====================================================================
--
        lv_trx_idx := gt_sales_bulk_tbl2( ln_trx_idx ).create_class
                   || gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class;
        IF ( gt_sel_trx_type_tbl.EXISTS( lv_trx_idx ) ) THEN
          lv_trx_type_nm := gt_sel_trx_type_tbl( lv_trx_idx ).attribute1;
          lv_trx_sent_dv := gt_sel_trx_type_tbl( lv_trx_idx ).attribute2;
        ELSE
          BEGIN
/* 2009/07/27 Ver1.21 Mod Start */
--            SELECT flvm.attribute1 || flvd.attribute1
            SELECT /*+ USE_NL( flvd ) */
                   flvm.attribute1 || flvd.attribute1
/* 2009/07/27 Ver1.21 Mod End   */
                 , rctt.attribute1
            INTO   lv_trx_type_nm
                 , lv_trx_sent_dv
            FROM   fnd_lookup_values              flvm                     -- 作成元区分特定マスタ
                 , fnd_lookup_values              flvd                     -- 納品伝票区分特定マスタ
                 , ra_cust_trx_types_all          rctt                     -- 取引タイプマスタ
            WHERE  flvm.lookup_type               = cv_qct_mkorg_cls
              AND  flvd.lookup_type               = cv_qct_dlv_slp_cls
              AND  flvm.lookup_code               LIKE cv_qcc_code
              AND  flvd.lookup_code               LIKE cv_qcc_code
              AND  flvm.meaning                   = gt_sales_bulk_tbl2( ln_trx_idx ).create_class
              AND  flvd.meaning                   = gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
              AND  rctt.name                      = flvm.attribute1 || flvd.attribute1
              AND  rctt.org_id                    = gv_mo_org_id
              AND  flvm.enabled_flag              = cv_enabled_yes
              AND  flvd.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--              AND  flvm.language                  = USERENV( 'LANG' )
--              AND  flvd.language                  = USERENV( 'LANG' )
              AND  flvm.language                  = ct_lang
              AND  flvd.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
                            , iv_token_name2   => cv_tkn_header_id
                            , iv_token_value2  => lt_header_id
                            , iv_token_name3   => cv_tkn_order_no
                            , iv_token_value3  => gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              lv_err_flag  := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
          -- 取得した取引タイプをワークテーブルに設定する
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute1 := lv_trx_type_nm;
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute2 := lv_trx_sent_dv;
--
        END IF;
--
        --=====================================================================
        -- ３．品目明細摘要の取得(「仮受消費税等」以外)
        --=====================================================================
--
        -- 品目明細摘要の存在チェック-->存在している場合、取得必要がない
        IF ( lt_goods_prod_class IS NULL ) THEN
          lv_item_idx := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
                      || lt_goods_item_code;
        ELSE
          lv_item_idx := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
                      || lt_goods_prod_class;
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
              AND  flvi.attribute1                = gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
              AND  flvi.attribute2                = NVL( lt_goods_prod_class,
                                                         lt_goods_item_code )
              AND  flvi.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--              AND  flvi.language                  = USERENV( 'LANG' )
              AND  flvi.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
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
                            , iv_token_name2   => cv_tkn_header_id
                            , iv_token_value2  => lt_header_id
                            , iv_token_name3   => cv_tkn_order_no
                            , iv_token_value3  => gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              lv_err_flag  := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
          -- 取得したAR品目明細摘要をワークテーブルに設定する
          gt_sel_item_desp_tbl( lv_item_idx ).description := lv_item_desp;
--
        END IF;
        --伝票入力者取得
        BEGIN
          SELECT fu.user_name
          INTO   lv_employee_name
          FROM   fnd_user             fu
                ,per_all_people_f     papf
          WHERE  fu.employee_id       = papf.person_id
/* 2009/07/30 Ver1.21 ADD START */
            AND  gt_sales_norm_tbl2( ln_trx_idx ).inspect_date
                   BETWEEN papf.effective_start_date AND papf.effective_end_date
/* 2009/07/30 Ver1.21 ADD End   */
            AND  papf.employee_number = gv_busi_emp_cd;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 伝票入力者取得出来ない場合
              lv_tbl_nm :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_tkn_user_msg
                            );
--
              lv_employee_nm :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_employee_code_msg
                            );
--
              lv_header_id_nm :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_header_id_msg
                            );
--
              lv_order_no_nm  :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_order_no_msg
                            );
--
              xxcos_common_pkg.makeup_key_info(
                            iv_item_name1         =>  lv_employee_nm,
                            iv_data_value1        =>  gv_busi_emp_cd,
                            iv_item_name2         =>  lv_header_id_nm,
                            iv_data_value2        =>  lt_header_id,
                            iv_item_name3         =>  lv_order_no_nm,
                            iv_data_value3        =>  gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number,
                            ov_key_info           =>  lv_key_info,                --編集されたキー情報
                            ov_errbuf             =>  lv_errbuf,                  --エラーメッセージ
                            ov_retcode            =>  lv_retcode,                 --リターンコード
                            ov_errmsg             =>  lv_errmsg                   --ユーザ・エラー・メッセージ
                          );
--
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_data_get_msg
                            , iv_token_name1   => cv_tkn_tbl_nm
                            , iv_token_value1  => lv_tbl_nm
                            , iv_token_name2   => cv_tkn_key_data
                            , iv_token_value2  => lv_key_info
                          );
              lv_errbuf  := lv_errmsg;
--
              lv_err_flag  := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
        END;
      END IF;
--
      --スキップ処理
      IF ( lv_err_flag = cv_y_flag ) THEN
         ln_skip_idx := ln_skip_idx + 1;
         gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id;
      END IF;
      --==============================================================
      -- ４．AR請求取引OIFデータ作成
      --==============================================================
--
      -- -- 集約フラグ’N'の場合、AR請求取引OIFデータ作成する
      IF ( lv_sum_flag = cv_n_flag ) THEN
--
        -- AR請求取引OIFの収益行
        ln_ar_idx   := ln_ar_idx  + 1;
--
        -- AR請求取引OIFデータ作成(収益行)===>NO.1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).oif_dff4;
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id;
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
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --内税時、金額は本体＋税金
          gt_ar_interface_tbl( ln_ar_idx ).amount       := ln_amount + ln_tax;
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- 取引タイプ名
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- 支払条件ID
        IF (  gt_sales_bulk_tbl2( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_bulk_tbl2( ln_trx_idx ).cash_and_card   = 0 ) THEN
        -- 現金の場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- 請求先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_b;
                                                        -- 請求先顧客ID
        ELSE
        -- カードの場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_bulk_tbl2( ln_trx_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := gt_sales_bulk_tbl2( ln_trx_idx ).oif_trx_number;
                                                        -- 収益行のみ：AR取引番号
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_inv_line_no;
                                                        -- 収益行のみ：AR取引明細番号
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- 収益行のみ：数量=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
                                                        := ln_amount;
                                                        -- 収益行のみ：販売単価=本体金額
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --内税時、販売単価は本体＋税金
          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := ln_amount + ln_tax;
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_bulk_tbl2( ln_trx_idx ).tax_code;
                                                        -- 税金コード(税区分)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- ヘッダーDFFカテゴリ
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).sales_base_code;
                                                        -- ヘッダーdff5(起票部門)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := lv_employee_name;
                                                        -- ヘッダーdff6(伝票入力者)
        IF( lv_trx_sent_dv = cv_n_flag ) THEN
          gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_hold;
                                                        -- ヘッダーDFF7(予備１)
        ELSIF( lv_trx_sent_dv = cv_y_flag ) THEN
          gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- ヘッダーDFF7(予備１)
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- ヘッダーdff8(予備２)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- ヘッダーdff9(予備3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).card_receiv_base;
                                                        -- ヘッダーDFF11(入金拠点)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_out_tax_cls 
          OR gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_exp_tax_cls ) THEN
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
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- 取引明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number;
                                                        -- 取引明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).oif_tax_dff4;
                                                        -- 取引明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- 取引明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id;
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
        IF (  gt_sales_bulk_tbl2( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_bulk_tbl2( ln_trx_idx ).cash_and_card   = 0 ) THEN
          -- 現金の場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- 請求先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_b;
                                                        -- 請求先顧客ID
        ELSE
        -- カードの場合
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- 入金先顧客所在地参照ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_c;
                                                        -- 入金先顧客ID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcss_org_sys_id;
                                                        -- 出荷先顧客所在地参照ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_s;
                                                        -- 出荷先顧客ID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- リンク先明細コンテキスト:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF1:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_ar_interface_tbl( ln_ar_idx - 1 ).interface_line_attribute3;
                                                        -- リンク先明細DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := gt_ar_interface_tbl( ln_ar_idx - 1 ).interface_line_attribute4;
                                                        -- リンク先明細DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- リンク先明細DFF5:「販売実績」を設定
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id;
                                                        -- リンク先明細DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).rcrm_receipt_id;
                                                        -- 支払方法ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- 換算タイプ:「User」を設定
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- 換算レート:1 を設定
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date;
                                                        -- 取引日(請求書日付):販.検収日
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_bulk_tbl2( ln_trx_idx ).delivery_date;
                                                        -- GL記帳日(仕訳計上日):販.納品日
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_bulk_tbl2( ln_trx_idx ).tax_code;
                                                        -- 税金コード
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- 営業単位ID
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- 内税の場合、'Y'を設定
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- 税込金額フラグ
        ELSIF( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_out_tax_cls 
          OR gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_exp_tax_cls ) THEN
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
      END IF;
--
      IF ( lv_sum_flag = cv_n_flag ) THEN
        -- 集約キーと集約金額のリセット
        lt_trx_number      := gt_sales_bulk_tbl2( sale_bulk_idx ).oif_trx_number;        -- AR取引番号
        lt_header_id       := gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id;   -- 販売実績ヘッダID
--
        ln_amount := gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
        IF ( gt_sales_bulk_tbl2( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_tax  := gt_sales_bulk_tbl2( sale_bulk_idx ).tax_amount;
        ELSE
          ln_tax  := 0;
        END IF;
      END IF;
--
    END LOOP gt_sales_bulk_sum_loop;                    -- 販売実績データループ終了
--
--
    <<gt_sales_bulk_check_loop>>
    FOR ln_ar_idx IN 1 .. gt_ar_interface_tbl.COUNT LOOP
      -- 開始：1取引No内での出荷先顧客チェック
--
      -- KEYが代わったら
      IF (
           (
              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NULL )
              AND
              ( gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4 <> NVL( ln_key_dff4, 'X') )
           )
           OR
           (
              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NOT NULL )
              AND
              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number <> NVL( ln_key_trx_number, 'X') )
           )
         )THEN
--
        -- 出荷先顧客フラグがONの場合
        IF ( ln_ship_flg = cn_ship_flg_on )
        THEN
          <<gt_sales_bulk_ship_clear_loop>>
          FOR start_index IN ln_start_index .. ln_ar_idx - 1 LOOP
            -- 開始：1取引No内での出荷先顧客チェック
--
            -- 出荷先顧客IDをクリア
            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
            -- 最後の行
            IF ( gt_ar_interface_tbl.COUNT = ln_ar_idx )
            THEN
              -- 出荷先顧客IDをクリア
              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id := NULL;
              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id  := NULL;
            END IF;
--
            -- 終了：1取引No内での出荷先顧客チェック
          END LOOP gt_sales_bulk_ship_clear_loop;
        END IF;
--
        -- 取引Noを取得
        ln_key_trx_number := gt_ar_interface_tbl( ln_ar_idx ).trx_number;
--
        -- DFF4を取得
        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
        -- 出荷先顧客IDを取得
        ln_key_ship_customer_id := gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id;
--
        -- 取引Noの開始位置を取得
        ln_start_index := ln_ar_idx;
--
        -- フラグを初期化
        ln_ship_flg := cn_ship_flg_off;
--
      ELSE
        -- 出荷先顧客が同じか？
        IF ( gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id <> ln_key_ship_customer_id ) THEN
          -- 違う場合、出荷先顧客フラグをONにする
          ln_ship_flg := cn_ship_flg_on;
--
        END IF;
        -- DFF4を取得
        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
        IF ( ln_ship_flg = cn_ship_flg_on AND ln_ar_idx = gt_ar_interface_tbl.COUNT ) THEN
          <<gt_sales_bulk_ship_clear_loop>>
          FOR start_index IN ln_start_index .. ln_ar_idx LOOP
            -- 開始：1取引No内での出荷先顧客チェック
--
            -- 出荷先顧客IDをクリア
            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
            -- 終了：1取引No内での出荷先顧客チェック
          END LOOP gt_sales_bulk_ship_clear_loop;
        END IF;
--
      END IF;
      -- 終了：1取引No内での出荷先顧客チェック
    END LOOP gt_sales_bulk_check_loop;
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
    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- 集約キー：税金コード
    lt_header_id        xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- 集約キー：販売実績ヘッダID
    ln_amount           NUMBER DEFAULT 0;                                -- 集約後金額
    ln_tax              NUMBER DEFAULT 0;                                -- 集約後消費税金額
    ln_ar_dis_idx       NUMBER DEFAULT 0;                                -- AR会計配分集約インデックス
    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR会計配分OIFインデックス
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- 仕訳生成カウント
    lv_rec_flag         VARCHAR2(1);                                     -- RECフラグ
    -- AR取引番号
    lt_trx_number       VARCHAR2(20);
    lv_err_flag         VARCHAR2(1);                                     -- エラー用フラグ
    lv_jour_flag        VARCHAR2(1);                                     -- エラー用フラグ
    ln_skip_idx         NUMBER DEFAULT 0;                                -- スキップ用インデックス;
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
    -- 請求取引テーブルの非大手量販店データカウントセット
    ln_ar_dis_idx := gt_ar_dis_tbl.COUNT;
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
    --スキップカウントセット
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
    --=====================================
    -- 3.AR会計配分データ作成
    --=====================================
    -- 集約キーの値セット
    lt_invoice_number   := gt_sales_bulk_tbl2( 1 ).dlv_invoice_number;
    lt_item_code        := gt_sales_bulk_tbl2( 1 ).item_code;
    lt_prod_cls         := gt_sales_bulk_tbl2( 1 ).goods_prod_cls;
    lt_gyotai_sho       := gt_sales_bulk_tbl2( 1 ).cust_gyotai_sho;
    lt_card_sale_class  := gt_sales_bulk_tbl2( 1 ).card_sale_class;
    lt_tax_code         := gt_sales_bulk_tbl2( 1 ).tax_code;
    lt_invoice_class    := gt_sales_bulk_tbl2( 1 ).dlv_invoice_class;
    lt_red_black_flag   := gt_sales_bulk_tbl2( 1 ).red_black_flag;
    lt_header_id        := gt_sales_bulk_tbl2( 1 ).sales_exp_header_id;
--
    -- ラストデータ登録為に、ダミーデータをセットする
    gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT + 1 ).sales_exp_header_id
                        := gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT ).sales_exp_header_id;
--
    <<gt_sales_bulk_tbl2_loop>>
    FOR dis_sum_idx IN 1 .. gt_sales_bulk_tbl2.COUNT LOOP
--
      -- AR会計配分データ集約開始
      IF ( lt_invoice_number = gt_sales_bulk_tbl2( dis_sum_idx ).dlv_invoice_number
        AND
          (
            (
              (
                 NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
              OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
              )
            AND
              NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_bulk_tbl2( dis_sum_idx ).goods_prod_cls, 'X' )
            )
          OR
            (
              (
                  NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
              AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
              )
              AND lt_item_code = gt_sales_bulk_tbl2( dis_sum_idx ).item_code
            )
          )
        AND lt_gyotai_sho      = gt_sales_bulk_tbl2( dis_sum_idx ).cust_gyotai_sho
        AND lt_card_sale_class = gt_sales_bulk_tbl2( dis_sum_idx ).card_sale_class
        AND lt_tax_code        = gt_sales_bulk_tbl2( dis_sum_idx ).tax_code
        AND lt_header_id       = gt_sales_bulk_tbl2( dis_sum_idx ).sales_exp_header_id
        )
      THEN
--
        -- 集約するフラグ初期設定
        lv_sum_flag := cv_y_flag;
--
        -- 本体金額と消費税額を集約する
        ln_amount := ln_amount + gt_sales_bulk_tbl2( dis_sum_idx ).pure_amount;
        ln_tax    := ln_tax    + gt_sales_bulk_tbl2( dis_sum_idx ).tax_amount;
      ELSE
        lv_sum_flag := cv_n_flag;
        ln_dis_idx  := dis_sum_idx - 1;
      END IF;
--
      -- -- 集約フラグ’N'の場合、下記AR会計配分OIF作成処理を行う
      IF ( lv_sum_flag = cv_n_flag ) THEN
--
        IF ( NVL( lt_trx_number, 'X' ) <> gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number ) THEN
          lv_rec_flag := cv_y_flag;
        ELSE
          lv_rec_flag := cv_n_flag;
        END IF;
        lt_trx_number      := gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number;        -- AR取引番号
--
        -- 仕訳生成カウント初期値
        ln_jour_cnt := 1;
        lv_jour_flag := cv_n_flag;
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
            lt_segment3 := gt_jour_cls_tbl( jcls_idx ).segment3;
--
            --=====================================
            -- 2.勘定科目CCIDの取得
            --=====================================
            -- 勘定科目セグメント１～セグメント８よりCCID取得
            lv_ccid_idx := gv_company_code                                   -- セグメント１(会社コード)
                        || NVL( gt_jour_cls_tbl( jcls_idx ).segment2,        -- セグメント２（部門コード）
                                gt_sales_bulk_tbl2( ln_dis_idx ).sales_base_code )
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
                                  gt_sales_bulk_tbl2( ln_dis_idx ).sales_base_code )
                           , lt_segment3
                           , gt_jour_cls_tbl( jcls_idx ).segment4
                           , gt_jour_cls_tbl( jcls_idx ).segment5
                           , gt_jour_cls_tbl( jcls_idx ).segment6
                           , gt_jour_cls_tbl( jcls_idx ).segment7
                           , gt_jour_cls_tbl( jcls_idx ).segment8
                         );
--
              --エラーフラグOFF
              lv_err_flag := cv_n_flag;
              IF ( lt_ccid IS NULL ) THEN
                -- CCIDが取得できない場合
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm
                                , iv_name              => cv_ccid_nodata_msg
                                , iv_token_name1       => cv_tkn_segment1
                                , iv_token_value1      => gv_company_code
                                , iv_token_name2       => cv_tkn_segment2
                                , iv_token_value2      => NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                                               gt_sales_bulk_tbl2( ln_dis_idx ).sales_base_code )
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
                                , iv_token_name9       => cv_tkn_header_id
                                , iv_token_value9      => lt_header_id
                                , iv_token_name10      => cv_tkn_order_no
                                , iv_token_value10     => lt_invoice_number
                              );
                lv_errbuf  := lv_errmsg;
                lv_err_flag  := cv_y_flag;
                gn_warn_flag := cv_y_flag;
                -- 空行出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => cv_blank
                );
--
                -- メッセージ出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => lv_errmsg
                );
--
                -- 空行出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => cv_blank
                );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- メッセージ出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- 空行出力
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
              END IF;
--
              --スキップ処理
              IF ( lv_err_flag = cv_y_flag ) THEN
                 ln_skip_idx := ln_skip_idx + 1;
                 gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
              END IF;
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
              -- AR会計配分OIFの設定項目
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- 取引明細コンテキスト値「販売実績」をセット
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF1「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).oif_dff4;
                                                          -- 取引明細DFF4:納品伝票番号+自動採番
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5：「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rev;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_amount;
                                                          -- 金額(明細金額)
              IF ( gt_sales_bulk_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --内税時、金額は本体＋税金
                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := ln_amount + ln_tax;
              END IF;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_amount;
                                                          -- パーセント(割合)
              IF ( gt_sales_bulk_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --内税時、パーセント(割合)は本体＋税金
                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := ln_amount + ln_tax;
              END IF;
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
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rec AND lv_rec_flag = cv_y_flag ) THEN
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
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).oif_dff4;
                                                          -- 取引明細DFF4納品伝票番号+自動採番
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5	「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rec;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- パーセント(割合)
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
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- 取引明細DFF3：納品伝票番号
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).oif_tax_dff4;
                                                          -- 取引明細DFF4：納品伝票番号+自動採番
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- 取引明細DFF5「販売実績」を設定
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- 取引明細DFF7：販売実績ヘッダID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_tax;
                                                          -- 勘定科目区分(配分タイプ)
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_tax;
                                                          -- 金額(明細金額)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_tax;
                                                          -- パーセント(割合)
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
        IF ( ln_jour_cnt = 1 AND dis_sum_idx <> gt_sales_bulk_tbl2.COUNT ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application       => cv_xxcos_short_nm
                          , iv_name              => cv_jour_no_msg
                          , iv_token_name1       => cv_tkn_invoice_cls
                          , iv_token_value1      => lt_invoice_class
                          , iv_token_name2       => cv_tkn_prod_cls
                          , iv_token_value2      => NVL( lt_prod_cls, lt_item_code )
                          , iv_token_name3       => cv_tkn_gyotai_sho
                          , iv_token_value3      => lt_gyotai_sho
                          , iv_token_name4       => cv_tkn_sale_cls
                          , iv_token_value4      => lt_card_sale_class
                          , iv_token_name5       => cv_tkn_red_black_flag
                          , iv_token_value5      => lt_red_black_flag
                          , iv_token_name6       => cv_tkn_header_id
                          , iv_token_value6      => lt_header_id
                          , iv_token_name7       => cv_tkn_order_no
                          , iv_token_value7      => lt_invoice_number
                        );
          lv_errbuf  := lv_errmsg;
          lv_jour_flag  := cv_y_flag;
          gn_warn_flag := cv_y_flag;
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
--
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
--
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
--
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
--
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          -- 空行出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
          --スキップ処理
          IF ( lv_jour_flag = cv_y_flag ) THEN
             ln_skip_idx := ln_skip_idx + 1;
             gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
          END IF;
        END IF;
--
        -- 金額の設定
        ln_amount        := gt_sales_bulk_tbl2( dis_sum_idx ).pure_amount;
        ln_tax           := gt_sales_bulk_tbl2( dis_sum_idx ).tax_amount;
      END IF;                                             -- 集約キー毎にAR会計配分OIFデータの集約終了
--
      -- 集約キーのリセット
      lt_invoice_number   := gt_sales_bulk_tbl2( dis_sum_idx ).dlv_invoice_number;
      lt_item_code        := gt_sales_bulk_tbl2( dis_sum_idx ).item_code;
      lt_prod_cls         := gt_sales_bulk_tbl2( dis_sum_idx ).goods_prod_cls;
      lt_gyotai_sho       := gt_sales_bulk_tbl2( dis_sum_idx ).cust_gyotai_sho;
      lt_card_sale_class  := gt_sales_bulk_tbl2( dis_sum_idx ).card_sale_class;
      lt_tax_code         := gt_sales_bulk_tbl2( dis_sum_idx ).tax_code;
      lt_invoice_class    := gt_sales_bulk_tbl2( dis_sum_idx ).dlv_invoice_class;
      lt_red_black_flag   := gt_sales_bulk_tbl2( dis_sum_idx ).red_black_flag;
      lt_header_id        := gt_sales_bulk_tbl2( dis_sum_idx ).sales_exp_header_id;
--
    END LOOP gt_sales_bulk_tbl2_loop;                      -- AR会計配分集約データループ終了
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
    lv_tbl_nm     VARCHAR2(255);                -- テーブル名
    ln_ar_idx     NUMBER DEFAULT 0;             -- 請求取引OIFインデックス
    lv_skip_flag  VARCHAR2(1);                  -- フラグ
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
    <<gt_ar_interface_tbl_loop>>
    FOR sale_idx IN 1 .. gt_ar_interface_tbl.COUNT LOOP
      lv_skip_flag := cv_n_flag;
      -- スキップ処理
      IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
        <<gt_sales_skip_tbl_loop>>
        FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
          IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
              = gt_ar_interface_tbl( sale_idx ).interface_line_attribute7 ) THEN
            lv_skip_flag := cv_y_flag;
            EXIT;
          END IF;
        END LOOP gt_sales_skip_tbl_loop;
      END IF;
--
      IF ( lv_skip_flag = cv_n_flag ) THEN
        ln_ar_idx := ln_ar_idx + 1;
        gt_ar_interface_tbl1( ln_ar_idx )                  := gt_ar_interface_tbl( sale_idx );
      END IF;
    END LOOP gt_ar_interface_tbl_loop;
--
    IF ( gt_ar_interface_tbl1.COUNT > 0 ) THEN 
      BEGIN
        FORALL i IN 1..gt_ar_interface_tbl1.COUNT
          INSERT INTO
            ra_interface_lines_all
          VALUES
            gt_ar_interface_tbl1(i)
          ;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_insert_data_expt;
      END;
    END IF;
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
    lv_tbl_nm     VARCHAR2(255);                -- テーブル名
    ln_ar_dis_idx NUMBER DEFAULT 0;             -- 請求取引OIFインデックス
    lv_skip_flag  VARCHAR2(1);                  -- フラグ
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
    <<gt_ar_dis_tbl_loop>>
    FOR sale_idx IN 1 .. gt_ar_dis_tbl.COUNT LOOP
      lv_skip_flag := cv_n_flag;
      -- スキップ処理
      IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
        <<gt_sales_skip_tbl_loop>>
        FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
          IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
              = gt_ar_dis_tbl( sale_idx ).interface_line_attribute7 ) THEN
            lv_skip_flag := cv_y_flag;
            EXIT;
          END IF;
        END LOOP gt_sales_skip_tbl_loop;
      END IF;
--
      IF ( lv_skip_flag = cv_n_flag ) THEN
        ln_ar_dis_idx := ln_ar_dis_idx + 1;
        gt_ar_dis_tbl1( ln_ar_dis_idx )                  := gt_ar_dis_tbl( sale_idx );
      END IF;
    END LOOP gt_ar_dis_tbl_loop;
--
    IF ( gt_ar_dis_tbl1.COUNT > 0 ) THEN 
      BEGIN
        FORALL i IN 1..gt_ar_dis_tbl1.COUNT
          INSERT INTO
            ra_interface_distributions_all
          VALUES
            gt_ar_dis_tbl1(i)
          ;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_insert_data_expt;
      END;
    END IF;
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
    lv_tbl_nm           VARCHAR2(255);                -- テーブル名
    lv_skip_flag        VARCHAR2(1);                  -- フラグ
    ln_sales_h_tbl_idx  NUMBER DEFAULT 0;           -- 販売実績ヘッダ更新用インデックス
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
      FOR sale_idx IN 1 .. gt_sales_exp_tbl2.COUNT LOOP
--
          lv_skip_flag := cv_n_flag;
          IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
            <<gt_sales_skip_tbl_loop>>
            FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
              IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
                  = gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id ) THEN
                lv_skip_flag := cv_y_flag;
                EXIT;
              END IF;
            END LOOP gt_sales_skip_tbl_loop;
          END IF;
--
          IF ( lv_skip_flag = cv_n_flag ) THEN
            ln_sales_h_tbl_idx := ln_sales_h_tbl_idx + 1;
            gt_sales_h_tbl( ln_sales_h_tbl_idx )                  := gt_sales_exp_tbl2( sale_idx ).xseh_rowid;
          END IF;
      END LOOP gt_sales_exp_tbl2_loop;                                  -- 販売実績データループ終了
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
    IF ( gt_sales_norm_tbl2.COUNT > 0 ) THEN
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
    IF ( gt_sales_bulk_tbl2.COUNT > 0 ) THEN
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
    gn_aroif_cnt  := gt_ar_interface_tbl1.COUNT;                      -- AR請求取引OIF登録件数
    gn_ardis_cnt  := gt_ar_dis_tbl1.COUNT;                            -- AR会計配分OIF登録件数
    gn_normal_cnt := gn_aroif_cnt + gn_ardis_cnt;
--
    IF ( gn_warn_flag = cv_y_flag ) THEN
--
      IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
        --スキップ件数計算する
        <<gt_sales_exp_tbl2_loop>>
        FOR sale_idx IN 1 .. gt_sales_exp_tbl2.COUNT LOOP
          gv_skip_flag := cv_n_flag;
          -- スキップ処理
            <<gt_sales_skip_tbl_loop>>
            FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
              IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
                  = gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id ) THEN
                gv_skip_flag := cv_y_flag;
                EXIT;
              END IF;
            END LOOP gt_sales_skip_tbl_loop;
--
          IF ( gv_skip_flag = cv_y_flag ) THEN
            gn_skip_cnt := gn_skip_cnt + 1;
          END IF;
        END LOOP gt_sales_exp_tbl2_loop;
      END IF;
--
      RAISE global_card_inf_expt;
    END IF;
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
    WHEN global_card_inf_expt THEN
      ov_retcode := cv_status_warn;
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
--
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
--
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_skip_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
