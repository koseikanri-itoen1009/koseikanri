CREATE OR REPLACE PACKAGE BODY APPS.XXCOS013A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS013A01C (body)
 * Description      : 販売実績情報より仕訳情報を作成し、AR請求取引に連携する処理
 * MD.050           : ARへの販売実績データ連携 MD050_COS_013_A01
 * Version          : 1.27
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_data               販売実績データ取得(A-2-1)
 *  edit_sum_data          請求取引集約処理（非大手量販店）(A-3)
 *  edit_dis_data          AR会計配分仕訳作成（非大手量販店）(A-4)
 *  edit_sum_bulk_data     AR請求取引情報集約処理（大手量販店）(A-5)
 *  edit_dis_bulk_data     AR会計配分仕訳作成（大手量販店）(A-6)
 *  insert_aroif_data      AR請求取引OIF登録処理(A-7)
 *  insert_ardis_data      AR会計配分OIF登録処理(A-8)
 *  upd_data               販売実績ヘッダ更新処理(A-9)
 *  del_data               販売実績AR用ワーク削除処理(A-10)
 *  submain                メイン処理プロシージャ(A-2-2を含む)
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
 *  2009/08/20    1.22  K.Kiriu          [0000884]PT対応
 *  2009/08/24    1.22  K.Kiriu          [0001165]伝票入力者取得条件不正対応
 *  2009/08/28    1.23  K.Kiriu          [0001166]勘定科目取得条件不正対応
 *                                       [0001211]税金マスタテーブル結合削除
 *                                       [0001215]取得されないCCIDがNULLで設定される不正対応
 *  2009/10/02    1.24  K.Kiriu          [0001321]PT対応 ヒント句、フラグ更新処理追加
 *                                       [0001359]PT対応 メモリ対応
 *                                       [0001472]非大手の取引番号採番条件変更(請求先 -> 出荷先)
 *  2009/10/27    1.25  K.Kiriu          [E_最終移行リハ_00375]支払条件即時対応
 *  2009/11/05    1.26  K.Kiriu          [E_T4_00103]AR取引番号採番単位変更対応
 *                                       [E_最終移行リハ_00519]大手AR取引番号の採番形態変更対応
 *                                       [I_E_00648]顧客階層不具合対応
 *  2010/03/08    1.27  K.Atsushiba      [E_本稼動_01400]値引の仕訳、対象データなしのステイタス対応
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
/* 2009/10/02 Ver1.24 Add Start */
  global_delete_data_expt   EXCEPTION;         -- 削除処理エラー
/* 2009/10/02 Ver1.24 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_xxccp_short_nm         CONSTANT VARCHAR2(10) := 'XXCCP';            -- 共通領域短縮アプリ名
  cv_xxcos_short_nm         CONSTANT VARCHAR2(10) := 'XXCOS';            -- 販物アプリケーション短縮名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOS013A01C';     -- パッケージ名
/* 2009/10/02 Ver1.24 Del Start */
--  cv_no_para_msg            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなしメッセージ
/* 2009/10/02 Ver1.24 Del End   */
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- 業務日付取得エラー
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- プロファイル取得エラー
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013'; -- データ抽出エラーメッセージ
  cv_no_data_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- 対象データ無しメッセージ
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001'; -- ロックエラーメッセージ（販売実績TB）
  cv_data_insert_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010'; -- データ登録エラーメッセージ
  cv_data_update_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011'; -- データ更新エラーメッセージ
  cv_pro_mo_org_cd          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047'; -- 営業単位取得エラー
/* 2009/10/02 Ver1.24 Add Start */
  cv_data_delete_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00012'; -- データ削除エラーメッセージ
  cv_param_err_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00006'; -- 必須入力パラメータ未設定エラー
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
  cv_msg_param              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12794'; -- パラメーター出力
  cv_tkn_target_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12795'; -- 処理対象区分
  cv_tkn_create_c_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12796'; -- 作成元区分
  cv_tkn_ar_bukl_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12797'; -- XXCOS:AR結果セット取得件数(バルク)
  cv_tkn_if_bukl_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12798'; -- XXCOS:ARインターフェースバッチ作成件数
  cv_tkn_work_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12799'; -- 販売実績AR用ワーク
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/10/27 Ver1.25 Add Start */
  cv_tkn_spot_payment_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12800'; -- XXCOS:支払条件即時
/* 2009/10/27 Ver1.25 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
  cv_tkn_dlv_inp_user_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-14001'; -- XXCOS:AR大手量販店伝票入力者
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
  cv_tkn_param1             CONSTANT  VARCHAR2(20) := 'PARAM1';          -- パラメータ1
  cv_tkn_param2             CONSTANT  VARCHAR2(20) := 'PARAM2';          -- パラメータ2
  cv_tkn_in_param           CONSTANT VARCHAR2(20)  := 'IN_PARAM';        -- パラメータ名称
/* 2009/10/02 Ver1.24 Add End   */
--
  -- フラグ・区分定数
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';               -- フラグ値:Y
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';               -- フラグ値:N
/* 2009/10/02 Ver1.24 Add Start */
  cv_w_flag                 CONSTANT  VARCHAR2(1)  := 'W';               -- フラグ値:W
  cv_s_flag                 CONSTANT  VARCHAR2(1)  := 'S';               -- フラグ値:S
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2010/03/08 Ver1.27 Add Start   */
  cv_status_enable          CONSTANT VARCHAR2(1)   := 'A';               -- ステイタス：A（有効）
/* 2010/03/08 Ver1.27 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
  cv_major                 CONSTANT  VARCHAR2(1)     := '1';                             -- 処理対象区分(大手)
  cv_not_major             CONSTANT  VARCHAR2(1)     := '2';                             -- 処理対象区分(非大手)
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
    , request_id                NUMBER(15,0)                                          -- 要求ID
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
  TYPE g_sales_exp_id_bk IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- 販売実績ヘッダID
    , xseh_rowid                ROWID                                               -- ROWID
  );
/* 2009/10/02 Ver1.24 Add End   */
--
  -- 販売実績ワークテーブル型定義
  TYPE g_sales_exp_ttype IS TABLE OF gr_sales_exp_rec INDEX BY BINARY_INTEGER;
  TYPE g_v_od_data_ttype IS TABLE OF gr_sales_exp_rec INDEX BY VARCHAR(100);
/* 2009/10/02 Ver1.24 Add Start */
  TYPE g_sales_exp_ttype_bk IS TABLE OF g_sales_exp_id_bk INDEX BY BINARY_INTEGER;
/* 2009/10/02 Ver1.24 Add End   */
--
  gt_sales_exp_tbl              g_sales_exp_ttype;                                  -- 販売実績データ(メインSQL)
  gt_sales_exp_tbl2             g_sales_exp_ttype;                                  -- 販売実績データ(ワークテーブルインサート)
/* 2009/10/02 Ver1.24 Mod Start */
--  gt_sales_skip_tbl             g_sales_exp_ttype;                                  -- 販売実績データ
  gt_sales_skip_tbl             g_sales_exp_ttype_bk;                               -- 販売実績データ(スキップデータ)
  gt_sales_target_tbl           g_sales_exp_ttype_bk;                               -- 販売実績データ(総処理件数)
/* 2009/10/02 Ver1.24 Mod End   */
  gt_sales_norm_tbl             g_sales_exp_ttype;                                  -- 販売実績非大手量販店データ
  gt_sales_norm_tbl2            g_sales_exp_ttype;                                  -- 販売実績非大手量販店データ（インサート）
  gt_sales_bulk_tbl             g_sales_exp_ttype;                                  -- 販売実績大手量販店データ
  gt_sales_bulk_tbl2            g_sales_exp_ttype;                                  -- 販売実績大手量販店データ（インサート）
/* 2009/10/02 Ver1.24 Add Start */
  gt_sales_sum_tbl_brk          g_sales_exp_ttype;                                  -- 請求取引集約データ（ブレークデータ保持）
  gt_sales_dis_tbl_brk          g_sales_exp_ttype;                                  -- AR会計配分仕訳データ（ブレークデータ保持）
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/10/02 Ver1.24 Del Start */
--  gt_sales_norm_order_tbl       g_v_od_data_ttype;                                  -- 販売実績非大手量販店データ(ソート)
--  gt_sales_bulk_order_tbl       g_v_od_data_ttype;                                  -- 販売実績大手量販店データ(ソート)
--
----*** MIYATA DELETE START ***
--gt_norm_card_tbl              g_sales_exp_ttype;                                  -- 販売実績非大手量販店カードデータ
--gt_bulk_card_tbl              g_sales_exp_ttype;                                  -- 販売実績大手量販店カードデータ
----*** MIYATA DELETE END   ***
/* 2009/10/02 Ver1.24 Del End   */
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
/* 2010/03/08 Ver1.27 Add Start   */
  TYPE g_discount_item_ttype   IS TABLE OF VARCHAR2(9) INDEX BY VARCHAR2( 9 );
  gt_discount_item_tbl            g_discount_item_ttype;                               -- 値引品目
/* 2010/03/08 Ver1.27 Add End   */
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
/* 2010/03/08 Ver1.27 Del Start   */
--  gv_dis_item_cd                      VARCHAR2(30);                                 -- 売上値引品目コード
/* 2010/03/08 Ver1.27 Del End   */
/* 2009/07/30 Ver1.21 Add Start */
  gv_goods_prod_cls                   VARCHAR2(30);                                 -- 商品製品区分カテゴリセット名
  gt_category_id                      mtl_categories_b.category_id%TYPE;            -- カテゴリID
  gt_category_set_id                  mtl_category_sets_tl.category_set_id%TYPE;    -- カテゴリセットID
/* 2009/07/30 Ver1.21 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
  gn_ar_bulk_collect_cnt              NUMBER;                                       -- バルク処理件数
  gn_if_bulk_collect_cnt              NUMBER;                                       -- バルク処理件数(IF)
/* 2009/10/27 Ver1.25 Add Start */
  gt_spot_payment_code                ra_terms_tl.name%TYPE;                        -- 支払方法即時
/* 2009/10/27 Ver1.25 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
  gv_dlv_inp_user                     VARCHAR2(30);                                 -- 大手量販店伝票入力者
/* 2009/11/05 Ver1.26 Add End   */
--
  gn_fetch_first_flag                 NUMBER(1) DEFAULT 0;                              -- BULK処理の開始判定用 0:開始、1:2回目以降
  gn_fetch_end_flag                   NUMBER(1) DEFAULT 0;                              -- BULK処理の終了判定用 0:継続、1:終了
  --AR取引番号編集用
/* 2009/11/05 Ver1.26 Del Start */
--  gt_create_class_brk                 xxcos_sales_exp_headers.create_class%TYPE;        -- 作成区分(ブレーク判定用)
/* 2009/11/05 Ver1.26 Del End   */
  gt_invoice_number_brk               xxcos_sales_exp_headers.dlv_invoice_number%TYPE;  -- 納品伝票番号(ブレーク判定用)
  gt_invoice_class_brk                xxcos_sales_exp_headers.dlv_invoice_class%TYPE;   -- 納品伝票区分(非大手ブレーク判定用)
  gt_xchv_cust_id_s_brk               xxcos_cust_hierarchy_v.bill_account_id%TYPE;      -- 出荷先顧客(非大手ブレーク判定用)
  gt_xchv_cust_id_b_brk               xxcos_cust_hierarchy_v.bill_account_id%TYPE;      -- 請求先顧客(大手ブレーク判定用)
/* 2009/11/05 Ver1.26 Add Start */
  gt_pay_cust_number_brk              xxcos_cust_hierarchy_v.bill_account_number%TYPE;  -- 支払先請求顧客(大手ブレーク判定用)
/* 2009/11/05 Ver1.26 Add End   */
  gt_header_id_brk                    xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- 販売実績ヘッダID(ブレーク判定用)
  gt_cash_sale_cls_brk                xxcos_sales_exp_headers.card_sale_class%TYPE;     -- カード売り区分(ブレーク判定用)
  gt_sales_date_brk                   xxcos_sales_exp_headers.inspect_date%TYPE;        -- 売上計上日(大手ブレーク判定用)
  gv_trx_number_brk                   VARCHAR2(20);                                     -- AR取引番号(ブレーク判定用)
  gv_trx_number                       VARCHAR2(20);                                     -- AR取引番号
  gn_trx_number_id                    NUMBER;                                           -- 取引明細DFF3用:自動採番番号
  gn_trx_number_tax_id                NUMBER;                                           -- 取引明細DFF3用税金用:自動採番番号
  --請求取引集約処理用
  gv_sum_flag                         VARCHAR2(1);                                      -- 集約フラグ Y:集約 N:作成
  gv_trx_number_brk2                  VARCHAR2(20);                                     -- AR取引番号(ブレーク判定用)
  gt_header_id_brk2                   xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- 販売実績ヘッダID(ブレーク判定用)
  gt_prod_cls_brk2                    xxcos_good_prod_class_v.goods_prod_class_code%TYPE;  -- 品目区分(ブレーク判定用)
  gt_item_code_brk2                   xxcos_sales_exp_lines.item_code%TYPE;             -- 品目コード(ブレーク判定用)
  gn_amount                           NUMBER    DEFAULT 0;                              -- 本体金額(集約)
  gn_tax                              NUMBER    DEFAULT 0;                              -- 消費税額(集約)
  gn_term_amount                      NUMBER    DEFAULT 0;                              -- 本体金額(同一品目区分の合計計算用)
  gn_max_amount                       NUMBER    DEFAULT 0;                              -- 本体金額(品目区分の金額合計保持用)
  gt_goods_prod_class                 xxcos_good_prod_class_v.goods_prod_class_code%TYPE;  --品目区分
  gt_goods_item_code                  xxcos_sales_exp_lines.item_code%TYPE;                --品目コード
  --AR会計配分集約処理用
  gv_sum_flag_ar                      VARCHAR2(1);                                      -- 集約フラグ Y:集約 N:作成
  gt_invoice_number_ar_brk            xxcos_sales_exp_headers.dlv_invoice_number%TYPE;  -- 納品伝票番号(ブレーク処理用)
  gt_item_code_ar_brk                 xxcos_sales_exp_lines.item_code%TYPE;             -- 品目コード(ブレーク処理用)
  gt_prod_cls_ar_brk                  xxcos_good_prod_class_v.goods_prod_class_code%TYPE;  -- 品目区分（製品・商品）(ブレーク処理用)
  gt_gyotai_sho_ar_brk                xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;     -- 業態小分類(ブレーク処理用)
  gt_card_sale_class_ar_brk           xxcos_sales_exp_headers.card_sale_class%TYPE;     -- カード売り区分(ブレーク処理用)
  gt_tax_code_ar_brk                  xxcos_sales_exp_headers.tax_code%TYPE;            -- 税金コード(ブレーク処理用)
  gt_invoice_class_ar_brk             xxcos_sales_exp_headers.dlv_invoice_class%TYPE;   -- 納品伝票区分(ブレーク処理用)
  gt_red_black_flag_ar_brk            xxcos_sales_exp_lines.red_black_flag%TYPE;        -- 赤黒フラグ(ブレーク処理用)
  gt_header_id_ar_brk                 xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- 販売実績ヘッダID(ブレーク処理用)
  gv_trx_number_ar_brk                VARCHAR2(20);                                     -- AR取引番号(ブレーク処理用)
  gn_amount_ar                        NUMBER DEFAULT 0;                                 -- 本体金額(集約)
  gn_tax_ar                           NUMBER DEFAULT 0;                                 -- 後消費税額(集約)
  --出荷先顧客チェック用(大手のみ)
  gn_key_trx_number                   ra_interface_lines_all.trx_number%TYPE;                   --AR取引番号(収益行)
  gn_key_dff4                         ra_interface_lines_all.interface_line_attribute4%TYPE;    --収益行との紐付け
  gn_key_ship_customer_id             ra_interface_lines_all.orig_system_ship_customer_id%TYPE; --出荷先顧客
  gn_ship_flg                         NUMBER(1);                                                --チェックフラグ
  --件数取得用
  gn_work_cnt                         NUMBER DEFAULT 0;                                 -- ワーク作成件数
  gn_aroif_cnt_tmp                    NUMBER DEFAULT 0;                                 -- AR請求取引OIF(BUKL合計合算用)
  gn_ardis_cnt_tmp                    NUMBER DEFAULT 0;                                 -- AR会計配分OIF(BUKL合計合算用)
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
--
  --BULK処理カーソル(非大手)
  CURSOR bulk_data_cur
  IS
    SELECT   xseaw.sales_exp_header_id     sales_exp_header_id      --販売実績ヘッダID
            ,xseaw.dlv_invoice_number      dlv_invoice_number       --納品伝票番号
            ,xseaw.dlv_invoice_class       dlv_invoice_class        --納品伝票区分
            ,xseaw.cust_gyotai_sho         cust_gyotai_sho          --業態小分類
            ,xseaw.delivery_date           delivery_date            --納品日
            ,xseaw.inspect_date            inspect_date             --検収日
            ,xseaw.ship_to_customer_code   ship_to_customer_code    --顧客【納品先】
            ,xseaw.tax_code                tax_code                 --税金コード
            ,xseaw.tax_rate                tax_rate                 --消費税率
            ,xseaw.consumption_tax_class   consumption_tax_class    --消費税区分
            ,xseaw.results_employee_code   results_employee_code    --成績計上者コード
            ,xseaw.sales_base_code         sales_base_code          --売上拠点コード
            ,xseaw.receiv_base_code        receiv_base_code         --入金拠点コード
            ,xseaw.create_class            create_class             --作成元区分
            ,xseaw.card_sale_class         card_sale_class          --カード売り区分
            ,xseaw.dlv_inv_line_no         dlv_inv_line_no          --納品明細番号
            ,xseaw.item_code               item_code                --品目コード
            ,xseaw.sales_class             sales_class              --売上区分
            ,xseaw.red_black_flag          red_black_flag           --赤黒フラグ
            ,xseaw.goods_prod_cls          goods_prod_cls           --品目区分(製品・商品)
            ,xseaw.pure_amount             pure_amount              --本体金額
            ,xseaw.tax_amount              tax_amount               --消費税金額
            ,xseaw.cash_and_card           cash_and_card            --現金・カード併用額
            ,xseaw.rcrm_receipt_id         rcrm_receipt_id          --顧客支払方法ID
            ,xseaw.xchv_cust_id_s          xchv_cust_id_s           --出荷先顧客ID
            ,xseaw.xchv_cust_id_b          xchv_cust_id_b           --請求先顧客ID
            ,xseaw.xchv_cust_number_b      xchv_cust_number_b       --請求先顧客コード
            ,xseaw.xchv_cust_id_c          xchv_cust_id_c           --入金先顧客ID
            ,xseaw.hcss_org_sys_id         hcss_org_sys_id          --顧客所在地参照ID(出荷先)
            ,xseaw.hcsb_org_sys_id         hcsb_org_sys_id          --顧客所在地参照ID(請求先)
            ,xseaw.hcsc_org_sys_id         hcsc_org_sys_id          --顧客所在地参照ID(入金先)
            ,xseaw.xchv_bill_pay_id        xchv_bill_pay_id         --支払条件ID
            ,xseaw.xchv_bill_pay_id2       xchv_bill_pay_id2        --支払条件2
            ,xseaw.xchv_bill_pay_id3       xchv_bill_pay_id3        --支払条件3
            ,xseaw.xchv_tax_round          xchv_tax_round           --税金－端数処理
            ,xseaw.xseh_rowid              xseh_rowid               --販売実績ヘッダROWID
            ,xseaw.oif_trx_number          oif_trx_number           --AR取引番号
            ,xseaw.oif_dff4                oif_dff4                 --DFF4：伝票No＋シーケンス
            ,xseaw.oif_tax_dff4            oif_tax_dff4             --DFF4税金用：伝票No＋シーケンス
            ,xseaw.line_id                 line_id                  --販売実績明細番号
            ,xseaw.card_receiv_base        card_receiv_base         --カードVD入金拠点コード
            ,xseaw.pay_cust_number         pay_cust_number          --支払条件用請求先顧客コード
            ,xseaw.request_id              request_id               --要求ID
    FROM     xxcos_sales_exp_ar_work xseaw
    WHERE    xseaw.request_id = cn_request_id
    ORDER BY
/* 2009/11/05 Ver1.26 Mod Start */
--             xseaw.sales_exp_header_id --販売実績ヘッダID
--            ,xseaw.dlv_invoice_number  --納品伝票番号
--            ,xseaw.dlv_invoice_class   --納品伝票区分
--            ,xseaw.card_sale_class     --カード売り区分
--            ,xseaw.cust_gyotai_sho     --業態小分類
--            ,xseaw.goods_prod_cls      --品目区分
--            ,xseaw.item_code           --品目コード
--            ,xseaw.red_black_flag      --赤黒フラグ
--            ,xseaw.line_id             --販売実績明細番号
             xseaw.dlv_invoice_number  --納品伝票番号
            ,xseaw.dlv_invoice_class   --納品伝票区分
            ,xseaw.xchv_cust_id_s      --出荷先顧客
            ,xseaw.cust_gyotai_sho     --業態小分類
            ,xseaw.sales_exp_header_id --販売実績ヘッダID
            ,xseaw.card_sale_class     --カード売り区分
            ,xseaw.goods_prod_cls      --品目区分
/* 2010/03/08 Ver1.27 Add Start   */
            ,xseaw.item_code           --品目コード
            ,xseaw.red_black_flag      --赤黒フラグ
/* 2010/03/08 Ver1.27 Add End   */
/* 2009/11/05 Ver1.26 Mod End   */
    ;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
  --BULK処理カーソル(大手)
  CURSOR bulk_data_cur2
  IS
    SELECT   xseaw.sales_exp_header_id     sales_exp_header_id      --販売実績ヘッダID
            ,xseaw.dlv_invoice_number      dlv_invoice_number       --納品伝票番号
            ,xseaw.dlv_invoice_class       dlv_invoice_class        --納品伝票区分
            ,xseaw.cust_gyotai_sho         cust_gyotai_sho          --業態小分類
            ,xseaw.delivery_date           delivery_date            --納品日
            ,xseaw.inspect_date            inspect_date             --検収日
            ,xseaw.ship_to_customer_code   ship_to_customer_code    --顧客【納品先】
            ,xseaw.tax_code                tax_code                 --税金コード
            ,xseaw.tax_rate                tax_rate                 --消費税率
            ,xseaw.consumption_tax_class   consumption_tax_class    --消費税区分
            ,xseaw.results_employee_code   results_employee_code    --成績計上者コード
            ,xseaw.sales_base_code         sales_base_code          --売上拠点コード
            ,xseaw.receiv_base_code        receiv_base_code         --入金拠点コード
            ,xseaw.create_class            create_class             --作成元区分
            ,xseaw.card_sale_class         card_sale_class          --カード売り区分
            ,xseaw.dlv_inv_line_no         dlv_inv_line_no          --納品明細番号
            ,xseaw.item_code               item_code                --品目コード
            ,xseaw.sales_class             sales_class              --売上区分
            ,xseaw.red_black_flag          red_black_flag           --赤黒フラグ
            ,xseaw.goods_prod_cls          goods_prod_cls           --品目区分(製品・商品)
            ,xseaw.pure_amount             pure_amount              --本体金額
            ,xseaw.tax_amount              tax_amount               --消費税金額
            ,xseaw.cash_and_card           cash_and_card            --現金・カード併用額
            ,xseaw.rcrm_receipt_id         rcrm_receipt_id          --顧客支払方法ID
            ,xseaw.xchv_cust_id_s          xchv_cust_id_s           --出荷先顧客ID
            ,xseaw.xchv_cust_id_b          xchv_cust_id_b           --請求先顧客ID
            ,xseaw.xchv_cust_number_b      xchv_cust_number_b       --請求先顧客コード
            ,xseaw.xchv_cust_id_c          xchv_cust_id_c           --入金先顧客ID
            ,xseaw.hcss_org_sys_id         hcss_org_sys_id          --顧客所在地参照ID(出荷先)
            ,xseaw.hcsb_org_sys_id         hcsb_org_sys_id          --顧客所在地参照ID(請求先)
            ,xseaw.hcsc_org_sys_id         hcsc_org_sys_id          --顧客所在地参照ID(入金先)
            ,xseaw.xchv_bill_pay_id        xchv_bill_pay_id         --支払条件ID
            ,xseaw.xchv_bill_pay_id2       xchv_bill_pay_id2        --支払条件2
            ,xseaw.xchv_bill_pay_id3       xchv_bill_pay_id3        --支払条件3
            ,xseaw.xchv_tax_round          xchv_tax_round           --税金－端数処理
            ,xseaw.xseh_rowid              xseh_rowid               --販売実績ヘッダROWID
            ,xseaw.oif_trx_number          oif_trx_number           --AR取引番号
            ,xseaw.oif_dff4                oif_dff4                 --DFF4：伝票No＋シーケンス
            ,xseaw.oif_tax_dff4            oif_tax_dff4             --DFF4税金用：伝票No＋シーケンス
            ,xseaw.line_id                 line_id                  --販売実績明細番号
            ,xseaw.card_receiv_base        card_receiv_base         --カードVD入金拠点コード
            ,xseaw.pay_cust_number         pay_cust_number          --支払条件用請求先顧客コード
            ,xseaw.request_id              request_id               --要求ID
    FROM     xxcos_sales_exp_ar_work xseaw
    WHERE    xseaw.request_id = cn_request_id
    ORDER BY
             xseaw.inspect_date        --検収日(売上計上日)
            ,xseaw.dlv_invoice_class   --納品伝票区分
            ,xseaw.xchv_cust_id_b      --請求先顧客
            ,xseaw.pay_cust_number     --支払条件用請求先顧客コード
            ,xseaw.card_sale_class     --カード売り区分
            ,xseaw.sales_exp_header_id --販売実績ヘッダID
            ,xseaw.goods_prod_cls      --品目区分(製品・商品)
/* 2010/03/08 Ver1.27 Add Start   */
            ,xseaw.item_code           --品目コード
            ,xseaw.red_black_flag      --赤黒フラグ
/* 2010/03/08 Ver1.27 Add End   */
    ;
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
--    , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
--    , ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
      iv_target       IN  VARCHAR2    -- 処理対象区分
    , iv_create_class IN  VARCHAR2    -- 作成元区分
    , ov_errbuf       OUT VARCHAR2    -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2    -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2 )  -- ユーザー・エラー・メッセージ --# 固定 #
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Add Start */
    ct_ar_bulk_collect_cnt   CONSTANT VARCHAR2(30) := 'XXCOS1_AR_BULK_COLLECT_COUNT';
                                                              -- XXCOS:AR結果セット取得件数(バルク)
    ct_if_bulk_collect_cnt   CONSTANT VARCHAR2(31) := 'XXCOS1_AR_IF_BULK_COLLECT_COUNT';
                                                              -- XXCOS:ARインターフェースバッチ作成件数
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/10/27 Ver1.25 Add Start */
    ct_spot_payment_cd       CONSTANT VARCHAR2(24) := 'XXCOS1_SPOT_PAYMENT_CODE';
                                                              -- XXCOS:支払条件即時
/* 2009/10/27 Ver1.25 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
    ct_dlv_inp_user          CONSTANT VARCHAR2(30) := 'XXCOS1_AR_MAJOR_DLV_INPUT_USER';
                                                              -- XXCOS:AR大手量販店伝票入力者
/* 2009/11/05 Ver1.26 Add End   */
--
    -- *** ローカル変数 ***
    lv_profile_name          VARCHAR2(50);                     -- プロファイル名
/* 2009/07/30 Ver1.21 Add Start */
    lt_category_set_id       mtl_category_sets_tl.category_set_id%TYPE;  -- カテゴリセットID
/* 2009/07/30 Ver1.21 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
    lv_param_name            VARCHAR2(50);                     -- パラメータ名
/* 2009/10/02 Ver1.24 Add End   */
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
/* 2010/03/08 Ver1.27 Add Start   */
  -- 値引品目取得カーソル
  CURSOR discount_item_cur
  IS
    SELECT  flv.lookup_code     item_code
    FROM    fnd_lookup_values  flv
    WHERE   flv.lookup_type      = ct_dis_item_cd
    AND     flv.language         = ct_lang
    AND     flv.enabled_flag     = cv_enabled_yes
    AND     gd_process_date BETWEEN   NVL( flv.start_date_active, gd_process_date )
                            AND       NVL( flv.end_date_active,   gd_process_date );
  --
  discount_item_rec           discount_item_cur%ROWTYPE;

/* 2010/03/08 Ver1.27 Add End   */
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
    -- コンカレント入力パラメータ出力
    --===================================================
    gv_out_msg :=  xxccp_common_pkg.get_msg(
/* 2009/10/02 Ver1.24 Mod Start */
--                     iv_application  => cv_xxccp_short_nm
--                    ,iv_name         => cv_no_para_msg
                     iv_application  => cv_xxcos_short_nm
                    ,iv_name         => cv_msg_param
                    ,iv_token_name1  => cv_tkn_param1      --トークンコード１
                    ,iv_token_value1 => iv_target          --処理区分
                    ,iv_token_name2  => cv_tkn_param2      --トークンコード２
                    ,iv_token_value2 => iv_create_class    --作成元区分
/* 2009/10/02 Ver1.24 Mod End */
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
    -- コンカレント入力パラメータログ出力
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
/* 2009/10/02 Ver1.24 Add Start */
    --==================================
    --パラメータチェック
    --==================================
    IF ( iv_target IS NULL ) THEN
      lv_param_name := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_short_nm    -- アプリケーション短縮名
                         ,iv_name        => cv_tkn_target_msg    -- 処理対象区分
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_param_err_msg
                    , iv_token_name1  => cv_tkn_in_param
                    , iv_token_value1 => lv_param_name
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF ( iv_create_class IS NULL ) THEN
      lv_param_name := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_short_nm    -- アプリケーション短縮名
                         ,iv_name        => cv_tkn_create_c_msg  -- 作成元区分
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_param_err_msg
                    , iv_token_name1  => cv_tkn_in_param
                    , iv_token_value1 => lv_param_name
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2010/03/08 Ver1.27 Del Start   */
--    gv_dis_item_cd := FND_PROFILE.VALUE( ct_dis_item_cd );
--
--    -- プロファイルが取得できない場合はエラー
--    IF ( gv_dis_item_cd IS NULL ) THEN
--      lv_profile_name := xxccp_common_pkg.get_msg(
--         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
--        ,iv_name        => cv_dis_item_cd                              -- メッセージID
--      );
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_xxcos_short_nm
--                     , iv_name         => cv_pro_msg
--                     , iv_token_name1  => cv_tkn_pro
--                     , iv_token_value1 => lv_profile_name
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
/* 2010/03/08 Ver1.27 Del End   */
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
/* 2009/10/02 Ver1.24 Add Start */
    -- ===============================
    -- XXCOS:AR結果セット取得件数(バルク)
    -- ===============================
    gn_ar_bulk_collect_cnt := TO_NUMBER( FND_PROFILE.VALUE( ct_ar_bulk_collect_cnt ) );
    -- プロファイルが取得できない場合
    IF ( gn_ar_bulk_collect_cnt IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_tkn_ar_bukl_msg                          -- メッセージID
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
    -- ===============================
    -- XXCOS:ARインターフェースバッチ作成件数
    -- ===============================
    gn_if_bulk_collect_cnt := TO_NUMBER( FND_PROFILE.VALUE( ct_if_bulk_collect_cnt ) );
    -- プロファイルが取得できない場合
    IF ( gn_if_bulk_collect_cnt IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_tkn_if_bukl_msg                          -- メッセージID
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
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/10/27 Ver1.25 Add Start */
    -- ===============================
    -- XXCOS:支払条件即時
    -- ===============================
    gt_spot_payment_code := FND_PROFILE.VALUE( ct_spot_payment_cd );
    -- プロファイルが取得できない場合
    IF ( gt_spot_payment_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_tkn_spot_payment_msg                     -- メッセージID
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
/* 2009/10/27 Ver1.25 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
    -- ===============================
    -- XXCOS:AR大手量販店伝票入力者
    -- ===============================
    gv_dlv_inp_user := FND_PROFILE.VALUE( ct_dlv_inp_user );
    -- プロファイルが取得できない場合
    IF ( gv_dlv_inp_user IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- アプリケーション短縮名
        ,iv_name        => cv_tkn_dlv_inp_user_msg                     -- メッセージID
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
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
    --=====================================
    -- AR会計配分仕訳パターンの取得
    --=====================================
--
    BEGIN
      -- カーソルオープン
      OPEN  jour_cls_cur;
      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
      -- カーソルクローズ
      CLOSE jour_cls_cur;
    EXCEPTION
    -- 仕訳パターン取得失敗した場合
      WHEN OTHERS THEN
        IF ( jour_cls_cur%ISOPEN ) THEN
          CLOSE jour_cls_cur;
        END IF;
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_jour_nodata_msg
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => cv_qct_jour_cls
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- 仕訳パターンに1件も存在しない場合
    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_jour_nodata_msg
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_qct_jour_cls
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
/* 2009/10/02 Ver1.24 Add End   */
--
/* 2010/03/08 Ver1.27 Add Start   */
    --=====================================
    -- 値引品目の取得
    --=====================================
    BEGIN
      OPEN  discount_item_cur;
      --
      <<discount_item_loop>>
      LOOP
        FETCH discount_item_cur INTO discount_item_rec;
        EXIT WHEN discount_item_cur%NOTFOUND;
        --
        gt_discount_item_tbl(discount_item_rec.item_code) := discount_item_rec.item_code;
        --
      END LOOP discount_item_loop;
      --
      CLOSE discount_item_cur;
    EXCEPTION
      WHEN OTHERS THEN
        IF ( discount_item_cur%ISOPEN ) THEN
          CLOSE discount_item_cur;
        END IF;
        --
        -- エラーメッセージ作成
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_dis_item_cd
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => ct_dis_item_cd
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
/* 2010/03/08 Ver1.27 Add End   */
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
   * Description      : データ取得(A-2-1)
   ***********************************************************************************/
  PROCEDURE get_data(
/* 2009/10/02 Ver1.24 Mod Start */
--      ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
--    , ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
--    , ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
      iv_target        IN  VARCHAR2         -- 処理対象区分
    , iv_create_class  IN  VARCHAR2         -- 作成元区分
    , ov_errbuf        OUT VARCHAR2         -- エラー・メッセージ           --# 固定 #
    , ov_retcode       OUT VARCHAR2         -- リターン・コード             --# 固定 #
    , ov_errmsg        OUT VARCHAR2 )       -- ユーザー・エラー・メッセージ --# 固定 #
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Del Start */
--    ln_bulk_idx     NUMBER DEFAULT 0;                                  -- 非大手量販店インデックス
--    ln_norm_idx     NUMBER DEFAULT 0;                                  -- 大手量販店インデックス
--    ln_start_idx    NUMBER DEFAULT 1;                                  -- 開始位置
--    ln_end_idx      NUMBER DEFAULT 1;                                  -- 終了位置
--    ln_key_bef      NUMBER DEFAULT 1;                                  -- 比較キー
/* 2009/10/02 Ver1.24 Del End   */
    ln_pure_amount  NUMBER DEFAULT 0;                                  -- カードレコードの本体金額
    ln_tax_amount   NUMBER DEFAULT 0;                                  -- カードレコードの消費税金額
    lv_card_company VARCHAR2(9);                                       -- 顧客追加情報カード会社
    ln_sale_idx     NUMBER DEFAULT 0;                                  -- 販売実績インデックス
    ln_skip_idx     NUMBER DEFAULT 0;                                  -- スキップインデックス
    lv_sale_flag    VARCHAR2(1);                                       -- フラグ
/* 2009/10/02 Ver1.24 Del Start */
--    lv_skip_flag    VARCHAR2(1);                                       -- フラグ
/* 2009/10/02 Ver1.24 Del End   */
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
/* 2009/08/20 Ver1.22 Add Start */
    lt_break_header_id           xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    -- ヘッダブレーク用
    lv_break_flag                VARCHAR2(1);                                         -- ヘッダブレークフラグ(支払条件)
/* 2009/08/20 Ver1.22 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
    lv_break_flag2              VARCHAR2(1);                                          -- ヘッダブレークフラグ(カード会社)
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
    lv_receipt_id_flag           VARCHAR2(1);                                         -- 支払方法エラーフラグ
    ln_sale_idx_bk               NUMBER DEFAULT 0;                                    -- 配列の添字用
/* 2009/10/02 Ver1.24 Add End   */
--
    -- *** ローカル・カーソル (販売実績データ抽出)***
    CURSOR sales_data_cur
    IS
      SELECT
/* 2009/10/02 Ver1.24 Start */
              /*+
                  USE_NL(xsehv)
              */
/* 2009/10/02 Ver1.24 End   */
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
/* 2010/03/08 Ver1.27 Add Start   */
               AND    scsua.status            = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
               AND    scsua.primary_flag      = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
/* 2010/03/08 Ver1.27 Add Start   */
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
/* 2009/10/02 Ver1.24 Add Start */
           , cn_request_id                     request_id              -- 要求ID
/* 2009/10/02 Ver1.24 Add End   */
      FROM
             xxcos_sales_exp_headers           xseh                    -- 販売実績ヘッダテーブル(ロック用)
/* 2009/07/27 Ver1.21 Add Start */
           , (
               -- ①入金先顧客＆請求先顧客－出荷先顧客
/* 2009/10/02 Ver1.24 Mod Start */
--               SELECT /*+
--                          LEADING (xseh) 
--                          INDEX   (xseh xxcos_sales_exp_headers_n02) 
--                          USE_NL  (hcas)
--                      */
/* 2009/11/05 Ver1.26 Mod Start */
--               SELECT /*+
--                          LEADING(xseh) 
--                          INDEX(xseh xxcos_sales_exp_headers_n02)
--                          USE_NL(xseh hcas hcar_sb hcab hcac)
--                      */
               SELECT /*+
                          LEADING(xseh)
                          INDEX(xseh xxcos_sales_exp_headers_n02)
                          USE_NL(xseh flvl hcas hcar_sb hcab hcac)
                      */
/* 2009/11/05 Ver1.26 Mod Start */
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/11/05 Ver1.26 Add Start */
                     ,fnd_lookup_values        flvl     -- クイックコード
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Mod Start */
--               WHERE  xseh.ar_interface_flag            = cv_n_flag                   -- ARインタフェース済フラグ:N(未送信)
               WHERE  xseh.ar_interface_flag           IN ( cv_n_flag, cv_w_flag )    -- ARインタフェース済フラグ:N(未送信) W(警告)
/* 2009/10/02 Ver1.24 Mod End   */
               AND    xseh.delivery_date               <= gd_process_date             -- 納品日 <= 業務日付
/* 2009/10/02 Ver1.24 Add Start */
/* 2009/11/05 Ver1.26 Del Start */
--               AND    xseh.create_class                 = iv_create_class             -- パラメータ.作成元区分
/* 2009/11/05 Ver1.26 Del End   */
               AND    (
                        ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
                        OR
                        (
                          ( iv_target = cv_not_major )
                          AND
                          ( 
                            ( xseh.receiv_base_code <> gv_busi_dept_cd )
                            OR
                            ( xseh.receiv_base_code IS NULL )
                          )
                        )
                      )                                                               -- パラメータ.処理対象区分 1:大手 2:非大手
/* 2009/10/02 Ver1.24 Add End   */
               AND    hcas.account_number               = xseh.ship_to_customer_code
               AND    hcar_sb.related_cust_account_id   = hcas.cust_account_id
               AND    hcar_sb.status                    = cv_cust_relate_status       -- 顧客関連ステータス:A(有効)
               AND    hcar_sb.attribute1                = cv_cust_bill                -- 関連分類:1(請求)
               AND    hcab.cust_account_id              = hcar_sb.cust_account_id
               AND    hcab.customer_class_code          = cv_cust_class_uri           -- 顧客区分(請求):14(売掛金管理先顧客)
               AND    hcac.cust_account_id              = hcab.cust_account_id
/* 2009/11/05 Ver1.26 Add Start */
               AND    flvl.lookup_type                  = cv_qct_mkorg_cls
               AND    flvl.lookup_code                  LIKE cv_qcc_code
               AND    flvl.attribute2                   IS NULL
               AND    flvl.attribute3                   = iv_create_class             -- パラメータ.作成元区分
               AND    flvl.enabled_flag                 = cv_enabled_yes
               AND    flvl.language                     = ct_lang
               AND    gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                      AND     NVL( flvl.end_date_active,   gd_process_date )
               AND    flvl.meaning                      = xseh.create_class
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ship_hsua_1.status              = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
                        AND    bill_hsua_1.status              = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
                        AND    ship_hasa_1.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    bill_hasa_1.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    bill_hsua_1.primary_flag        = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
                        AND    ship_hsua_1.primary_flag        = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
/* 2010/03/08 Ver1.27 Add Start   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--               SELECT /*+
--                          LEADING (xseh)
--                          INDEX   (xseh xxcos_sales_exp_headers_n02)
--                          USE_NL  (hcas)
--                      */
/* 2009/11/05 Ver1.26 Mod Start */
--               SELECT /*+
--                          LEADING(xseh)
--                          INDEX(xseh xxcos_sales_exp_headers_n02)
--                          USE_NL(xseh hcas hcar_sb hcab hcar_sc hcac)
--                      */
               SELECT /*+
                          LEADING(xseh)
                          INDEX(xseh xxcos_sales_exp_headers_n02)
                          USE_NL(xseh flvl hcas hcar_sb hcab hcac)
                      */
/* 2009/11/05 Ver1.26 Mod End   */
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/11/05 Ver1.26 Add Start */
                     ,fnd_lookup_values        flvl    -- クイックコード
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Mod Start */
--               WHERE  xseh.ar_interface_flag             = cv_n_flag                  -- ARインタフェース済フラグ:N(未送信)
               WHERE  xseh.ar_interface_flag            IN ( cv_n_flag, cv_w_flag )   -- ARインタフェース済フラグ:N(未送信) W(警告)
/* 2009/10/02 Ver1.24 Mod End   */
               AND    xseh.delivery_date                <= gd_process_date            -- 納品日 <= 業務日付
/* 2009/10/02 Ver1.24 Add Start */
/* 2009/11/05 Ver1.26 Del Start */
--               AND    xseh.create_class                  = iv_create_class            -- パラメータ.作成元区分
/* 2009/11/05 Ver1.26 Del End   */
               AND    (
                        ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
                        OR
                        (
                          ( iv_target = cv_not_major )
                          AND
                          ( 
                            ( xseh.receiv_base_code <> gv_busi_dept_cd )
                            OR
                            ( xseh.receiv_base_code IS NULL )
                          )
                        )
                      )                                                               -- パラメータ.処理対象区分 1:大手 2:非大手
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/11/05 Ver1.26 Add Start */
               AND    flvl.lookup_type                   = cv_qct_mkorg_cls
               AND    flvl.lookup_code                   LIKE cv_qcc_code
               AND    flvl.attribute2                    IS NULL
               AND    flvl.attribute3                    = iv_create_class            -- パラメータ.作成元区分
               AND    flvl.enabled_flag                  = cv_enabled_yes
               AND    flvl.language                      = ct_lang
               AND    gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                      AND     NVL( flvl.end_date_active,   gd_process_date )
               AND    flvl.meaning                       = xseh.create_class
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ship_hsua_2.status              = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
                        AND    bill_hsua_2.status              = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
                        AND    cash_hasa_2.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    bill_hasa_2.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    ship_hasa_2.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    bill_hsua_2.primary_flag        = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
                        AND    ship_hsua_2.primary_flag        = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ROWNUM                          = 1
                      )
               UNION ALL
               --③入金先顧客－請求先顧客＆出荷先顧客
/* 2009/10/02 Ver1.24 Mod Start */
--               SELECT /*+
--                          LEADING (xseh)
--                          INDEX   (xseh xxcos_sales_exp_headers_n02)
--                          USE_NL  (hcas)
--                      */
/* 2009/11/05 Ver1.26 Mod Start */
--               SELECT /*+
--                          LEADING(xseh)
--                          INDEX(xseh xxcos_sales_exp_headers_n02)
--                          USE_NL(xseh hcas hcab hcar_sc hcac)
--                      */
               SELECT /*+
                          LEADING(xseh)
                          INDEX(xseh xxcos_sales_exp_headers_n02)
                          USE_NL(xseh flvl hcas hcar_sb hcab hcac)
                      */
/* 2009/11/05 Ver1.26 Mod End   */
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/11/05 Ver1.26 Add Start */
                     ,fnd_lookup_values        flvl     -- クイックコード
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Mod Start */
--               WHERE  xseh.ar_interface_flag            = cv_n_flag                  -- ARインタフェース済フラグ:N(未送信)
               WHERE  xseh.ar_interface_flag           IN ( cv_n_flag, cv_w_flag )   -- ARインタフェース済フラグ:N(未送信) W(警告)
/* 2009/10/02 Ver1.24 Mod End   */
               AND    xseh.delivery_date               <= gd_process_date            -- 納品日 <= 業務日付
/* 2009/10/02 Ver1.24 Add Start */
/* 2009/11/05 Ver1.26 Del Start */
--               AND    xseh.create_class                 = iv_create_class            -- パラメータ.作成元区分
/* 2009/11/05 Ver1.26 Del End   */
               AND    (
                        ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
                        OR
                        (
                          ( iv_target = cv_not_major )
                          AND
                          ( 
                            ( xseh.receiv_base_code <> gv_busi_dept_cd )
                            OR
                            ( xseh.receiv_base_code IS NULL )
                          )
                        )
                      )                                                               -- パラメータ.処理対象区分 1:大手 2:非大手
/* 2009/10/02 Ver1.24 Add End   */
               AND    hcas.account_number               = xseh.ship_to_customer_code
               AND    hcas.customer_class_code         IN ( cv_cust_class_cust, cv_cust_class_ue ) -- 顧客区分:10(顧客),12(上様)
               AND    hcab.cust_account_id              = hcas.cust_account_id
               AND    hcar_sc.related_cust_account_id   = hcas.cust_account_id
               AND    hcar_sc.status                    = cv_cust_relate_status      -- 顧客関連(入金)ステータス:A(有効)
               AND    hcar_sc.attribute1                = cv_cust_cash               -- 関連分類(入金)
               AND    hcac.cust_account_id              = hcar_sc.cust_account_id
               AND    hcac.customer_class_code          = cv_cust_class_uri          -- 顧客区分(入金):14(売掛金管理先顧客)
/* 2009/11/05 Ver1.26 Add Start */
               AND    flvl.lookup_type                  = cv_qct_mkorg_cls
               AND    flvl.lookup_code                  LIKE cv_qcc_code
               AND    flvl.attribute2                   IS NULL
               AND    flvl.attribute3                   = iv_create_class            -- パラメータ.作成元区分
               AND    flvl.enabled_flag                 = cv_enabled_yes
               AND    flvl.language                     = ct_lang
               AND    gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                      AND     NVL( flvl.end_date_active,   gd_process_date )
               AND    flvl.meaning                      = xseh.create_class
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ship_hsua_3.status              = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
                        AND    bill_hsua_3.status              = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
                        AND    cash_hasa_3.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    bill_hasa_3.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    ship_hasa_3.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    bill_hsua_3.primary_flag        = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
                        AND    ship_hsua_3.primary_flag        = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
/* 2010/03/08 Ver1.27 Add Start   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--               SELECT /*+
--                          LEADING (xseh)
--                          INDEX   (xseh xxcos_sales_exp_headers_n02)
--                          USE_NL  (hcas)
--                          USE_NL  (hcab)
--                      */
/* 2009/11/05 Ver1.26 Mod Start */
--               SELECT /*+
--                          LEADING (xseh)
--                          INDEX   (xseh xxcos_sales_exp_headers_n02)
--                          USE_NL  (hcas hcab hcac)
--                      */
               SELECT /*+
                          LEADING(xseh)
                          INDEX(xseh xxcos_sales_exp_headers_n02)
                          USE_NL(xseh flvl hcas hcar_sb hcab hcac)
                      */
/* 2009/11/05 Ver1.26 Mod End   */
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/11/05 Ver1.26 Add Start */
                     ,fnd_lookup_values        flvl  -- クイックコード
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Mod Start */
--              WHERE   xseh.ar_interface_flag     = cv_n_flag                   -- ARインタフェース済フラグ:N(未送信)
               WHERE  xseh.ar_interface_flag    IN ( cv_n_flag, cv_w_flag )    -- ARインタフェース済フラグ:N(未送信) W(警告)
/* 2009/10/02 Ver1.24 Mod End   */
               AND    xseh.delivery_date        <= gd_process_date             -- 納品日 <= 業務日付
/* 2009/10/02 Ver1.24 Add Start */
/* 2009/11/05 Ver1.26 Del Start */
--               AND    xseh.create_class          = iv_create_class             -- パラメータ.作成元区分
/* 2009/11/05 Ver1.26 Del End   */
               AND    (
                        ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
                        OR
                        (
                          ( iv_target = cv_not_major )
                          AND
                          ( 
                            ( xseh.receiv_base_code <> gv_busi_dept_cd )
                            OR
                            ( xseh.receiv_base_code IS NULL )
                          )
                        )
                      )                                                               -- パラメータ.処理対象区分 1:大手 2:非大手
/* 2009/10/02 Ver1.24 Add End   */
              AND     hcas.account_number        = xseh.ship_to_customer_code
              AND     hcas.customer_class_code  IN ( cv_cust_class_cust, cv_cust_class_ue ) -- 顧客区分:10(顧客),12(上様)
              AND     hcab.cust_account_id       = hcas.cust_account_id
              AND     hcac.cust_account_id       = hcas.cust_account_id
/* 2009/11/05 Ver1.26 Add Start */
              AND     flvl.lookup_type           = cv_qct_mkorg_cls
              AND     flvl.lookup_code           LIKE cv_qcc_code
              AND     flvl.attribute2            IS NULL
              AND     flvl.attribute3            = iv_create_class                    -- パラメータ.作成元区分
              AND     flvl.enabled_flag          = cv_enabled_yes
              AND     flvl.language              = ct_lang
              AND     gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                      AND     NVL( flvl.end_date_active,   gd_process_date )
              AND     flvl.meaning               = xseh.create_class
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ship_hsua_4.status              = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
                        AND    bill_hsua_4.status              = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
                        AND    bill_hasa_4.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    ship_hasa_4.status              = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                        AND    bill_hsua_4.primary_flag        = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
                        AND    ship_hsua_4.primary_flag        = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ROWNUM                          = 1
                      )
/* 2009/11/05 Ver1.26 Mod Start */
--              AND   NOT EXISTS (
--                      SELECT /*+ USE_NL(ex_hcar_4) */
--                             'X'
--                      FROM   hz_cust_acct_relate  ex_hcar_4
--                      WHERE  ex_hcar_4.cust_account_id = hcas.cust_account_id
--                      AND    ex_hcar_4.status          = cv_cust_relate_status  -- 顧客関連ステータス:A(有効)
--                      AND    ROWNUM                    = 1
--                    )
--             AND    NOT EXISTS (
--                      SELECT /*+ USE_NL(ex_hcar_4) */
--                             'X'
--                      FROM   hz_cust_acct_relate  ex_hcar_4
--                      WHERE  ex_hcar_4.related_cust_account_id = hcas.cust_account_id
--                      AND    ex_hcar_4.status                  = cv_cust_relate_status  -- 顧客関連ステータス:A(有効)
--                      AND    ROWNUM                            = 1
--                    )
              AND     NOT EXISTS (
                        SELECT /*+
                                  USE_NL(ex_hcar_4)
                               */
                               'X'
                        FROM   hz_cust_acct_relate ex_hcar_4
                        WHERE  (
                                  ex_hcar_4.cust_account_id         = hcas.cust_account_id 
                               OR ex_hcar_4.related_cust_account_id = hcas.cust_account_id
                               )
                        AND    ex_hcar_4.status                     = cv_cust_relate_status  -- 顧客関連ステータス:A(有効)
                        AND    ex_hcar_4.attribute1                 = cv_cust_cash           -- 関連分類(入金)
                      )
/* 2009/11/05 Ver1.26 Mod End   */
             )                                 xsehv                   -- 販売実績ヘッダテーブル(顧客階層込み)
/* 2009/07/27 Ver1.21 Add End   */
           , xxcos_sales_exp_lines             xsel                    -- 販売実績明細テーブル
/* 2009/08/28 Ver1.23 Del Start */
--           , ar_vat_tax_all_b                  avta                    -- 税金マスタ
/* 2009/08/28 Ver1.23 Del End   */
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
/* 2010/03/08 Ver1.27 Add Start   */
      AND hcsc.status                           = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
      AND hcsb.status                           = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
      AND hcss.status                           = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
      AND hcub.primary_flag                     = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
/* 2010/03/08 Ver1.27 Add Start   */
/* 2009/08/28 Ver1.23 Del Start */
--      AND avta.tax_code                         = xsehv.tax_code
/* 2009/07/27 Ver1.21 Mod End   */
--      AND avta.set_of_books_id                  = TO_NUMBER( gv_set_bks_id )
--      AND avta.enabled_flag                     = cv_enabled_yes
--      AND gd_process_date BETWEEN               NVL( avta.start_date, gd_process_date )
--                          AND                   NVL( avta.end_date,   gd_process_date )
/* 2009/08/28 Ver1.23 Del End   */
/* 2009/07/27 Ver1.21 Del Start */
--        AND xgpc.segment1( + )                = xsel.item_code
/* 2009/07/27 Ver1.21 Del End   */
/* 2009/07/27 Ver1.21 Mod Start */
--      AND xseh.create_class                     NOT IN (
--          SELECT
--              flvl.meaning                      meaning
/* 2009/11/05 Ver1.26 Del Start */
--      AND NOT EXISTS (
--          SELECT
--              'X'
--/* 2009/07/27 Ver1.21 Mod End */
--          FROM
--              fnd_lookup_values                 flvl
--          WHERE
--              flvl.lookup_type                  = cv_qct_mkorg_cls
--          AND flvl.lookup_code                  LIKE cv_qcc_code
--          AND flvl.attribute2                   = cv_attribute_y
--          AND flvl.enabled_flag                 = cv_enabled_yes
--/* 2009/07/27 Ver1.21 Mod Start */
----          AND flvl.language                     = USERENV( 'LANG' )
--          AND flvl.language                     = ct_lang
--/* 2009/07/27 Ver1.21 Mod End   */
--          AND gd_process_date BETWEEN           NVL( flvl.start_date_active, gd_process_date )
--                              AND               NVL( flvl.end_date_active,   gd_process_date )
--/* 2009/07/27 Ver1.21 Add Start */
--          AND flvl.meaning                      = xsehv.create_class
--/* 2009/07/27 Ver1.21 Add End   */
--          )
/* 2009/11/05 Ver1.26 Del End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--      ORDER BY xsehv.sales_exp_header_id
--             , xsehv.dlv_invoice_number
--             , xsehv.dlv_invoice_class
--             , NVL( xsehv.card_sale_class, cv_cash_class )
--             , xsehv.cust_gyotai_sho
/* 2009/07/27 Ver1.21 Mod End */
--             , xsel.item_code
--             , xsel.red_black_flag
      ORDER BY
        xseh.sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--    FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_tbl2;
--
--    -- カーソルクローズ
--    CLOSE sales_data_cur;
--
    LOOP
--
      EXIT WHEN sales_data_cur%NOTFOUND;
--
      --1バルク処理毎の初期化
      ln_sale_idx := 0;
      gt_sales_exp_tbl.DELETE;
      gt_sales_exp_tbl2.DELETE;
--
      FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_tbl2 LIMIT gn_ar_bulk_collect_cnt;
/* 2009/10/02 Ver1.24 Mod End   */
      --現金・カード併用とカードVDのレコード作成し、スキップ用ヘッダID取得する
      <<gt_sales_exp_tbl2_loop>>
      FOR sale_idx IN 1 .. gt_sales_exp_tbl2.COUNT LOOP
/* 2009/10/02 Ver1.24 Add Start */
        --処理総件数、販売実績ヘッダ更新の為、配列に保持
        ln_sale_idx_bk                                          := ln_sale_idx_bk + 1;
        gt_sales_target_tbl(ln_sale_idx_bk).sales_exp_header_id := gt_sales_exp_tbl2(sale_idx).sales_exp_header_id;
        gt_sales_target_tbl(ln_sale_idx_bk).xseh_rowid          := gt_sales_exp_tbl2(sale_idx).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/08/20 Ver1.22 Add Start */
        --ブレーク用変数(支払条件)初期化
        lv_break_flag := cv_n_flag;
/* 2010/03/08 Ver1.27 Add Start   */
        -- 品目が値引品目の場合、製品商品区分をNULLにする
        IF ( gt_discount_item_tbl.EXISTS(gt_sales_exp_tbl2(sale_idx).item_code) = TRUE ) THEN
          gt_sales_exp_tbl2(sale_idx).goods_prod_cls := NULL;
        END IF;
/* 2010/03/08 Ver1.27 Add End   */
        --ヘッダ単位の処理の為のブレーク処理
        IF ( lt_break_header_id IS NULL )
          OR
           ( lt_break_header_id <> gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id )
        THEN
          --ブレーク処理用変数初期化
          lv_break_flag       := cv_y_flag;                                          --ブレーク処理実行(支払条件)
/* 2009/11/05 Ver1.26 Add Start */
          lv_break_flag2      := cv_y_flag;                                          --ブレーク処理実行(カード会社)
/* 2009/11/05 Ver1.26 Add End   */
          lt_break_header_id  := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;  --ブレーク判定値の設定
          lv_sale_flag        := cv_y_flag;                                          --作成対象判定用のフラグ
/* 2009/10/02 Ver1.24 Mod Start */
          lv_receipt_id_flag  := cv_n_flag;                                          --支払方法エラー判定フラグ
/* 2009/10/02 Ver1.24 Mod End   */
          --SQL取得用変数初期化
          lv_card_company     := NULL;  --カード会社
          lt_xchv_cust_id     := NULL;  --カード会社(顧客追加情報)
          lt_receiv_base_code := NULL;  --カード会社(入金拠点)
          lt_hcsc_org_sys_id  := NULL;  --カード会社(顧客所在地参照)
          lt_receipt_id       := NULL;  --カード会社(顧客支払方法)
          lt_bill_pay_id      := NULL;  --カード会社(支払条件)
          lt_bill_pay_id2     := NULL;  --カード会社(支払条件2)
          lt_bill_pay_id3     := NULL;  --カード会社(支払条件3)
        END IF;
--
/* 2009/08/20 Ver1.22 Add End   */
        IF ( gt_sales_exp_tbl2( sale_idx ).rcrm_receipt_id IS NULL ) THEN
/* 2009/10/02 Ver1.24 Del Start */
--          --スキップ処理
--          ln_skip_idx := ln_skip_idx + 1;
--          gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
--                                                             := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Del End   */
/* 2009/08/20 Ver1.22 Add Start */
          --ヘッダ単位でチェックする
          IF ( lv_break_flag = cv_y_flag ) THEN
/* 2009/08/20 Ver1.22 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
            --スキップ処理
            ln_skip_idx := ln_skip_idx + 1;
            gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
                                                               := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
            gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid := gt_sales_exp_tbl2(sale_idx).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
--
            --支払方法が未設定
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
/* 2009/10/02 Ver1.24 Add Start */
            lv_receipt_id_flag := cv_y_flag;
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/08/20 Ver1.22 Add Start */
--
          END IF;  --ヘッダ単位チェックEND
--
/* 2009/08/20 Ver1.22 Add End   */
        END IF;
--
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
/* 2009/08/20 Ver1.22 Mod Start */
--        lv_sale_flag := cv_y_flag;
--        BEGIN
          --ヘッダ単位で1度のみチェックする
/* 2009/11/05 Ver1.26 Mod Start */
--          IF ( lv_break_flag = cv_y_flag ) THEN
          IF ( lv_break_flag2 = cv_y_flag ) THEN
/* 2009/11/05 Ver1.26 Mod End   */
--
/* 2009/08/20 Ver1.22 Mod End   */
            BEGIN
/* 2009/11/05 Ver1.26 Add Start */
              --カード会社の取得を実行済にする
              lv_break_flag2 := cv_n_flag;
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2010/03/08 Ver1.27 Add Start   */
                         AND  hcsua.status            = cv_status_enable         --顧客使用目的.ステータス = 'A'(有効)
                         AND  hcasa.status            = cv_status_enable         --顧客所在地.ステータス   = 'A'(有効)
                         AND  hcsua.primary_flag      = cv_y_flag                --顧客使用目的.主フラグ   = 'Y'(オン)
/* 2010/03/08 Ver1.27 Add Start   */
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
/* 2009/08/20 Ver1.22 Mod Start */
--        END;
          END IF;  --ヘッダ単位の処理END
--
/* 2009/08/20 Ver1.22 Mod End   */
/* 2009/10/02 Ver1.24 Mod Start */
--          IF ( lv_sale_flag = cv_y_flag ) THEN
          --支払方法未設定、もしくは、カード会社情報でエラーの場合は作成しない
          IF (
               ( lv_sale_flag = cv_y_flag )
            AND
               ( lv_receipt_id_flag = cv_n_flag  )
             )
          THEN
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Add Start */
            -- 要求ID
            gt_sales_exp_tbl( ln_sale_idx ).request_id         := gt_sales_exp_tbl2( sale_idx ).request_id;
/* 2009/10/02 Ver1.24 Add End   */
--
          ELSE
/* 2009/10/02 Ver1.24 Del Start */
--          --スキップ処理
--          ln_skip_idx := ln_skip_idx + 1;
--          gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
--                                                          := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Del End   */
/* 2009/08/20 Ver1.22 Add Start */
            --カード会社情報のチェックでエラーの場合、ヘッダ単位でメッセージを出力する
/* 2009/11/05 Ver1.26 Mod Start */
--            IF ( lv_break_flag = cv_y_flag ) THEN
            IF ( lv_break_flag2 = cv_n_flag ) THEN
--
              --フラグをメッセージ出力済にする
              lv_break_flag2 := cv_s_flag;
/* 2009/11/05 Ver1.26 Mod End   */
/* 2009/08/20 Ver1.22 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
              --スキップ処理
              ln_skip_idx := ln_skip_idx + 1;
              gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
                                                            := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
              gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid := gt_sales_exp_tbl2(sale_idx).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/08/20 Ver1.22 Add Start */
            END IF;
/* 2009/08/20 Ver1.22 Add End   */
          END IF;
        ELSE
/* 2009/10/02 Ver1.24 Add Start */
          --支払方法未設定でエラーの場合は作成しない
          IF ( lv_receipt_id_flag = cv_n_flag ) THEN
--
/* 2009/10/02 Ver1.24 Add End   */
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
            END IF;
--
/* 2009/10/02 Ver1.24 Add Start */
          END IF;
/* 2009/10/02 Ver1.24 Add End   */
--
        END IF;
--
      END LOOP gt_sales_exp_tbl2_loop;                                  -- 販売実績データループ終了
--
/* 2009/10/02 Ver1.24 Mod Start */
      --AR販売実績ワークテーブル作成
      FORALL i IN 1..gt_sales_exp_tbl.COUNT
        INSERT INTO
          xxcos_sales_exp_ar_work
        VALUES
          gt_sales_exp_tbl(i)
        ;
--
      --ワークテーブルの作成件数
      gn_work_cnt := gn_work_cnt + gt_sales_exp_tbl.COUNT;
--
--    -- 対象処理件数
--    gn_target_cnt   := gt_sales_exp_tbl2.COUNT;
      -- 対象処理件数
      gn_target_cnt   := gn_target_cnt + gt_sales_exp_tbl2.COUNT;
--
    END LOOP;
--
    --配列の削除
    gt_sales_exp_tbl.DELETE;
    gt_sales_exp_tbl2.DELETE;
--
    CLOSE sales_data_cur;
/* 2009/10/02 Ver1.24 Mod End   */
--
    IF ( gn_target_cnt > 0 ) THEN
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- 非大手量販店データと大手量販店データの分離
--      -- 抽出された販売実績データのループ
--      <<gt_sales_exp_tbl_loop>>
--      FOR sale_idx IN 1 .. gt_sales_exp_tbl.COUNT LOOP
--        IF ( gt_sales_exp_tbl( sale_idx ).receiv_base_code = gv_busi_dept_cd ) THEN
--          -- 大手量販店データを抽出
--          lv_skip_flag := cv_n_flag;
--          -- スキップ処理
--          IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
--            <<gt_sales_skip_tbl_loop>>
--            FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
--              IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
--                  = gt_sales_exp_tbl( sale_idx ).sales_exp_header_id ) THEN
--                lv_skip_flag := cv_y_flag;
--                EXIT;
--              END IF;
--            END LOOP gt_sales_skip_tbl_loop;
--          END IF;
--
--          IF ( lv_skip_flag = cv_n_flag ) THEN
--            ln_bulk_idx := ln_bulk_idx + 1;
--            gt_sales_bulk_tbl( ln_bulk_idx )                  := gt_sales_exp_tbl( sale_idx );
--          END IF;
--        ELSE
--          -- 非大手量販店データを抽出
--          lv_skip_flag := cv_n_flag;
--          -- スキップ処理
--          IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
--            <<gt_sales_skip_tbl_loop>>
--            FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
--              IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
--                  = gt_sales_exp_tbl( sale_idx ).sales_exp_header_id ) THEN
--                lv_skip_flag := cv_y_flag;
--                EXIT;
--              END IF;
--            END LOOP gt_sales_skip_tbl_loop;
--          END IF;
--
--          IF ( lv_skip_flag = cv_n_flag ) THEN
--            ln_norm_idx := ln_norm_idx + 1;
--            gt_sales_norm_tbl( ln_norm_idx )                  := gt_sales_exp_tbl( sale_idx );
--          END IF;
--        END IF;
--      END LOOP gt_sales_exp_tbl_loop;                                  -- 販売実績データループ終了
      NULL;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Del Start */
--    ln_sale_norm_idx2       NUMBER DEFAULT 0;           -- 生成したカードレコードのインデックス
--    ln_card_pt              NUMBER DEFAULT 1;           -- カードレコードのインデックス現行位置
/* 2009/10/02 Ver1.24 Del Start */
    ln_ar_idx               NUMBER DEFAULT 0;           -- 請求取引OIFインデックス
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_trx_idx              NUMBER DEFAULT 0;           -- AR配分OIF集約データインデックス;
    ln_trx_idx              NUMBER DEFAULT 1;           -- AR配分OIF集約データインデックス;
/* 2009/10/02 Ver1.24 Mod End   */
--
    lv_trx_type_nm          VARCHAR2(30);               -- 取引タイプ名称
    lv_trx_idx              VARCHAR2(30);               -- 取引タイプ(インデックス)
    lv_item_idx             VARCHAR2(30);               -- 品目明細摘要(インデックス)
    lv_item_desp            VARCHAR2(30);               -- 品目明細摘要(TAX以外)
    ln_term_id              NUMBER;                     -- 支払条件ID
/* 2009/10/02 Ver1.24 Del Start */
--    lv_cust_gyotai_sho      VARCHAR2(30);               -- 業態小分類
--    ln_pure_amount          NUMBER DEFAULT 0;           -- カードレコードの本体金額
--    ln_tax_amount           NUMBER DEFAULT 0;           -- カードレコードの消費税金額
--    ln_tax                  NUMBER DEFAULT 0;           -- 集約後消費税金額
--    ln_amount               NUMBER DEFAULT 0;           -- 集約後金額
--    ln_trx_number_id        NUMBER;                     -- 取引明細DFF3用:自動採番番号
--    ln_trx_number_tax_id    NUMBER;                     -- 取引明細DFF3用税金用:自動採番番号
/* 2009/10/02 Ver1.24 Del End   */
    lv_trx_sent_dv          VARCHAR2(30);               -- 請求書発行区分
/* 2009/10/02 Ver1.24 Del Start */
--    lv_trx_number           VARCHAR2(20);               -- AR取引番号
/* 2009/10/02 Ver1.24 Del End   */
    ln_trx_number_small     NUMBER;                     -- 取引番号:自動採番
/* 2009/10/02 Ver1.24 Del Start */
--    ln_term_amount          NUMBER DEFAULT 0;           -- 一時金額
--    ln_max_amount           NUMBER DEFAULT 0;           -- 最大金額
--
--    -- *** 取引NO取得キー
--      -- 作成区分
--    lt_create_class         xxcos_sales_exp_headers.create_class%TYPE;
--      -- 納品伝票番号
--    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
--      -- 納品伝票区分
--    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
--      -- 請求先顧客
--    lt_xchv_cust_id_b       xxcos_cust_hierarchy_v.bill_account_id%TYPE;
--
--    -- *** 集約キー(販売実績)
--      -- 販売実績ヘッダID
--    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
--      -- AR取引番号
--    lt_trx_number           VARCHAR2(20);
--     --カード売り区分
--    lt_cash_sale_cls        xxcos_sales_exp_headers.card_sale_class%TYPE;
--
--    lv_sum_flag             VARCHAR2(1);                -- 集約フラグ
--    lv_sum_card_flag        VARCHAR2(1);                -- カード集約フラグ
/* 2009/10/02 Ver1.24 Del End   */
    lv_employee_name        VARCHAR2(100);              -- 伝票入力者
/* 2009/10/02 Ver1.24 Del Start */
--    lv_idx_key              VARCHAR2(300);              -- PL/SQL表ソート用インデックス文字列
--    ln_now_index            VARCHAR2(300);
--    ln_first_index          VARCHAR2(300);
--    ln_smb_idx              NUMBER DEFAULT 0;           -- 生成したインデックス
/* 2009/10/02 Ver1.24 Del End   */
    lv_tbl_nm               VARCHAR2(100);              -- 従業員マスタ
    lv_employee_nm          VARCHAR2(100);              -- 従業員
    lv_header_id_nm         VARCHAR2(100);              -- ヘッダID
    lv_order_no_nm          VARCHAR2(100);              -- 伝票番号
    lv_key_info             VARCHAR2(100);              -- 伝票番号
/* 2009/10/02 Ver1.24 Del Start */
--      -- 品目区分
--    lt_goods_prod_class     xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
/* 2009/10/02 Ver1.24 Del End   */
    lv_err_flag             VARCHAR2(1);                -- エラー用フラグ
    ln_skip_idx             NUMBER DEFAULT 0;           -- スキップ用インデックス;
/* 2009/10/02 Ver1.24 Mod Start */
--    lt_goods_item_code      xxcos_sales_exp_lines.item_code%TYPE;
--    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
--    lt_prod_cls             xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
/* 2009/10/02 Ver1.24 Mod End   */
    lt_inspect_date        xxcos_sales_exp_headers.inspect_date%TYPE;          -- 検収日
    ln_key_dff4             VARCHAR2(100);              -- DFF4
    ln_key_trx_number       VARCHAR2(20);               -- 取引No
    ln_key_ship_customer_id NUMBER;                     -- 出荷先顧客ID
    ln_start_index          NUMBER DEFAULT 1;           -- 取引No毎の開始位置
    ln_ship_flg             NUMBER DEFAULT 0;           -- 出荷先顧客フラグ
/* 2009/10/27 Ver1.25 Add Start */
    lt_spot_term_id         ra_terms_tl.term_id%TYPE;   -- 支払条件ID(即時)
    lv_term_chk_flag        VARCHAR2(1);                -- 支払条件チェック実行フラグ
/* 2009/10/27 Ver1.25 Add End   */
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
/* 2009/10/02 Ver1.24 Del Start */
--    --=====================================================================
--    -- 集計前データ展開
--    --=====================================================================
--
--    --テーブルソールする
--    -- 正常データのみのPL/SQL表作成
--    <<loop_make_sort_data>>
--    FOR i IN 1..gt_sales_norm_tbl.COUNT LOOP
--      --ソートキーは販売実績ヘッダID、カード売り区分、販売実績明細ID
--      lv_idx_key := gt_sales_norm_tbl(i).sales_exp_header_id
--                    || gt_sales_norm_tbl(i).dlv_invoice_number
--                    || gt_sales_norm_tbl(i).dlv_invoice_class
--                    || gt_sales_norm_tbl(i).card_sale_class
--                    || gt_sales_norm_tbl(i).cust_gyotai_sho
--                    || gt_sales_norm_tbl(i).goods_prod_cls
--                    || gt_sales_norm_tbl(i).item_code
--                    || gt_sales_norm_tbl(i).red_black_flag
--                    || gt_sales_norm_tbl(i).line_id;
--      gt_sales_norm_order_tbl(lv_idx_key) := gt_sales_norm_tbl(i);
--    END LOOP loop_make_sort_data;
--
--    IF gt_sales_norm_order_tbl.COUNT = 0 THEN
--      RETURN;
--    END IF;
--
--    ln_first_index := gt_sales_norm_order_tbl.first;
--    ln_now_index := ln_first_index;
--
--    WHILE ln_now_index IS NOT NULL LOOP
--
--      ln_smb_idx := ln_smb_idx + 1;
--      gt_sales_norm_tbl2(ln_smb_idx) := gt_sales_norm_order_tbl(ln_now_index);
--      -- 次のインデックスを取得する
--      ln_now_index := gt_sales_norm_order_tbl.next(ln_now_index);
--
--    END LOOP;--ソート完了
--
/* 2009/10/02 Ver1.24 Del End   */
    --スキップカウントセット
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_norm_tbl2_loop>>
--    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl2.COUNT LOOP
--
--      -- AR取引番号の自動採番
--      IF (  NVL( lt_create_class, 'X' )       <> gt_sales_norm_tbl2( sale_norm_idx ).create_class        -- 作成元区分
--         OR NVL( lt_invoice_number, 'X' )     <> gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number  -- 納品伝票No
--         OR NVL( lt_invoice_class, 'X' )      <> NVL( gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_class, 'X' )   -- 納品伝票区分
--         OR lt_xchv_cust_id_b                 <> gt_sales_norm_tbl2( sale_norm_idx ).xchv_cust_id_b      -- 請求先顧客
--         OR (  (  gt_fvd_xiaoka                =  gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho      -- フルサービス（消化）VD :24
--               OR gt_gyotai_fvd                =  gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho )    -- フルサービス VD :25
--             AND ( lt_header_id                 <> gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id  -- 販売実績ヘッダID
--             OR NVL( lt_cash_sale_cls, 'X' ) <> gt_sales_norm_tbl2( sale_norm_idx ).card_sale_class ) )   --カード売り区分
--         )
    <<gt_sales_norm_tbl_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
--
      -- AR取引番号の自動採番
/* 2009/11/05 Ver1.26 Mod Start */
--      IF (  NVL( gt_create_class_brk, 'X' )     <> gt_sales_norm_tbl( sale_norm_idx ).create_class        -- 作成元区分
--         OR NVL( gt_invoice_number_brk, 'X' )   <> gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number  -- 納品伝票No
      IF (  NVL( gt_invoice_number_brk, 'X' )   <> gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number  -- 納品伝票No
/* 2009/11/05 Ver1.26 Mod End   */
         OR NVL( gt_invoice_class_brk, 'X' )    <> NVL( gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_class, 'X' )   -- 納品伝票区分
         OR gt_xchv_cust_id_s_brk               <> gt_sales_norm_tbl( sale_norm_idx ).xchv_cust_id_s      -- 出荷先顧客
         OR (
              (    gt_fvd_xiaoka    =  gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho   -- フルサービス（消化）VD :24
                OR gt_gyotai_fvd    =  gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho   -- フルサービス VD :25
              )
              AND
              (    gt_header_id_brk                 <> gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id  -- 販売実績ヘッダID
                OR NVL( gt_cash_sale_cls_brk, 'X' ) <> gt_sales_norm_tbl( sale_norm_idx ).card_sale_class      -- カード売り区分
              )
            )
         )
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        lv_trx_number := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number
        gv_trx_number := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number
/* 2009/10/02 Ver1.24 Mod End   */
                           || LPAD( TO_CHAR( ln_trx_number_small )
                                            ,cn_pad_num_char
                                            ,cv_pad_char
                                           );
--
      END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- 納品伝票番号＋シーケンスの採番
--      IF (   NVL( lt_trx_number , 'X' )     <> lv_trx_number                                            -- AR取引番号
--         OR  lt_header_id                   <> gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id   -- 販売実績ヘッダID
--         )
--
      -- 納品伝票番号＋シーケンスの採番
      IF (   NVL( gv_trx_number_brk , 'X' )  <> gv_trx_number                                           -- AR取引番号
         OR  gt_header_id_brk                <> gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id  -- 販売実績ヘッダID
         )
/* 2009/10/02 Ver1.24 Mod End   */
      THEN
          -- 取引明細DFF4用:自動採番番号
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
/* 2009/10/02 Ver1.24 Mod Start */
--            ln_trx_number_id
            gn_trx_number_id
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--            ln_trx_number_tax_id
            gn_trx_number_tax_id
/* 2009/10/02 Ver1.24 Mod End   */
          FROM
            dual
          ;
        END;
      END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- 取引番号キー
--      lt_invoice_class    := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_class;
--      lt_create_class     := gt_sales_norm_tbl2( sale_norm_idx ).create_class;
--      lt_invoice_number   := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number;
--      lt_xchv_cust_id_b   := gt_sales_norm_tbl2( sale_norm_idx ).xchv_cust_id_b;
--      lt_cash_sale_cls    := gt_sales_norm_tbl2( sale_norm_idx ).card_sale_class;
--
--
--      -- 納品伝票番号＋シーケンスの採番の集約キーの値セット
--      lt_trx_number       := lv_trx_number;
--      lt_header_id        := gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id;
--
--
--        -- AR取引番号
--      gt_sales_norm_tbl2( sale_norm_idx ).oif_trx_number   := lv_trx_number;
--        -- DFF4
--      gt_sales_norm_tbl2( sale_norm_idx ).oif_dff4         := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number
--                                                                  || TO_CHAR( ln_trx_number_id );
--        -- DFF4税金用
--      gt_sales_norm_tbl2( sale_norm_idx ).oif_tax_dff4     := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number
--                                                                  || TO_CHAR( ln_trx_number_tax_id );
--
--      -- 業態小分類の編集
--      IF ( gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
--        AND gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho <> gt_gyotai_fvd) THEN
--
--          gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho := cv_nvd;                 -- VD以外の業態・納品VD
--
--      END IF;
--
--    END LOOP gt_sales_norm_tbl2_loop;
--
      -- 取引番号キー
      gt_invoice_class_brk    := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_class;
/* 2009/11/05 Ver1.26 Del Start */
--      gt_create_class_brk     := gt_sales_norm_tbl( sale_norm_idx ).create_class;
/* 2009/11/05 Ver1.26 Del End   */
      gt_invoice_number_brk   := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number;
      gt_xchv_cust_id_s_brk   := gt_sales_norm_tbl( sale_norm_idx ).xchv_cust_id_s;
      gt_cash_sale_cls_brk    := gt_sales_norm_tbl( sale_norm_idx ).card_sale_class;
--
      -- 納品伝票番号＋シーケンスの採番の集約キーの値セット
      gv_trx_number_brk       := gv_trx_number;
      gt_header_id_brk        := gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id;
--
      -- AR取引番号
      gt_sales_norm_tbl( sale_norm_idx ).oif_trx_number   := gv_trx_number;
      -- DFF4
      gt_sales_norm_tbl( sale_norm_idx ).oif_dff4         := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number
                                                                || TO_CHAR( gn_trx_number_id );
      -- DFF4税金用
      gt_sales_norm_tbl( sale_norm_idx ).oif_tax_dff4     := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number
                                                                || TO_CHAR( gn_trx_number_tax_id );
--
      -- 業態小分類の編集
      IF (
             gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
         AND gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho <> gt_gyotai_fvd
         )
      THEN
--
          gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho := cv_nvd;   -- VD以外の業態・納品VD
--
      END IF;
--
    END LOOP gt_sales_norm_tbl_loop;
/* 2009/10/02 Ver1.24 Mod End   */
--
    --=====================================================================
    -- 請求取引集約処理（非大手量販店）開始
    --=====================================================================
/* 2009/10/02 Ver1.24 Mod Start */
--    -- 集約キーの値セット
--    lt_trx_number       := gt_sales_norm_tbl2( 1 ).oif_trx_number;            -- AR取引番号
--    lt_header_id        := gt_sales_norm_tbl2( 1 ).sales_exp_header_id;   -- 販売実績ヘッダID
--
--    -- ラストデータ登録為に、ダミーデータをセット
--    gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT + 1 ).sales_exp_header_id
--                        := gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT ).sales_exp_header_id;
--
--    lt_item_code        := gt_sales_norm_tbl2( 1 ).item_code;
--    lt_prod_cls         := gt_sales_norm_tbl2( 1 ).goods_prod_cls;
--
    -- 最初のBUKL処理の場合
    IF ( gn_fetch_first_flag = 0 ) THEN
      -- 集約キーの値セット
      gv_trx_number_brk2  := gt_sales_norm_tbl( 1 ).oif_trx_number;        -- AR取引番号
      gt_header_id_brk2   := gt_sales_norm_tbl( 1 ).sales_exp_header_id;   -- 販売実績ヘッダID
      gt_item_code_brk2   := gt_sales_norm_tbl( 1 ).item_code;             -- 品目コード
      gt_prod_cls_brk2    := gt_sales_norm_tbl( 1 ).goods_prod_cls;        -- 商品区分
    END IF;
    -- 2回目以降のBUKL処理の場合、保持していた前レコードをインサート用変数に移す
    IF ( gt_sales_sum_tbl_brk.COUNT <> 0 ) THEN
      gt_sales_norm_tbl2( ln_trx_idx ) := gt_sales_sum_tbl_brk( ln_trx_idx );
    END IF;
    -- 最後のBULK処理の最終レコードの場合
    IF ( gn_fetch_end_flag = 1 ) THEN
      -- ラストデータ登録為に、ダミーデータをセット(カウント0を考慮し-1を設定)
      gt_sales_norm_tbl( gt_sales_norm_tbl.COUNT + 1 ).sales_exp_header_id
                           := -1;
    END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_norm_sum_loop>>
--    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl2.COUNT LOOP
--
--      --=====================================
--      --  販売実績元データの集約
--      --=====================================
--      IF (  lt_trx_number   = gt_sales_norm_tbl2( sale_norm_idx ).oif_trx_number
--         AND lt_header_id   = gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id
--         )
--      THEN
--
--        -- 集約するフラグ初期設定
--        lv_sum_flag      := cv_y_flag;
--
--        -- 本体金額を集約する
--        ln_amount := ln_amount + gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
--
--        IF ( (
--               (
--                  NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
--               OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
--               )
--             AND
--               NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_norm_tbl2( sale_norm_idx ).goods_prod_cls, 'X' )
--             )
--           OR
--             (
--               (
--                   NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
--               AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
--               )
--               AND lt_item_code = gt_sales_norm_tbl2( sale_norm_idx ).item_code
--             )
--           )THEN
--             ln_term_amount := ln_term_amount + gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
--        ELSIF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
--             ln_max_amount       := ln_term_amount;
--             ln_term_amount      := gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
--             lt_goods_prod_class := lt_prod_cls;
--             lt_goods_item_code  := lt_item_code;
--        END IF;
--        lt_item_code        := gt_sales_norm_tbl2( sale_norm_idx ).item_code;
--        lt_prod_cls         := gt_sales_norm_tbl2( sale_norm_idx ).goods_prod_cls;
--
--        -- 課税の場合、消費税額を集約する
--        IF ( gt_sales_norm_tbl2( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax := ln_tax + gt_sales_norm_tbl2( sale_norm_idx ).tax_amount;
--        END IF;
--
--      ELSE
--
--        IF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
--             lt_goods_prod_class := lt_prod_cls;
--             lt_goods_item_code  := lt_item_code;
--        END IF;
--        ln_max_amount       := 0;
--        ln_term_amount      := 0;
--        lt_item_code        := gt_sales_norm_tbl2( sale_norm_idx ).item_code;
--        lt_prod_cls         := gt_sales_norm_tbl2( sale_norm_idx ).goods_prod_cls;
--
--        lv_sum_flag := cv_n_flag;
--        ln_trx_idx  := sale_norm_idx - 1;
--      END IF;
--
--      IF ( lv_sum_flag = cv_n_flag ) THEN
--
    <<gt_sales_norm_sum_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
--
      --=====================================
      --  販売実績元データの集約
      --=====================================
--
      -- ループ毎の初期化
      lv_err_flag := cv_n_flag; --エラーフラグOFF
--
      --AR取引番号、販売実績ヘッダIDで集約
      IF (   gv_trx_number_brk2 = gt_sales_norm_tbl( sale_norm_idx ).oif_trx_number
         AND gt_header_id_brk2  = gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id
         )
      THEN
--
        -- インサート用の配列を保持
        gt_sales_norm_tbl2( ln_trx_idx ) := gt_sales_norm_tbl( sale_norm_idx );
        -- 集約するフラグ初期設定
        gv_sum_flag                      := cv_y_flag;
        -- 本体金額を集約する
        gn_amount                        := gn_amount + gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
--
        --品目明細適用取得判定 ( 異なる品目区分で合計金額が最大の品目明細適用を取得 )
        IF (
             (
               (
                  NVL( gt_prod_cls_brk2, 'X' ) = cv_goods_prod_syo
               OR NVL( gt_prod_cls_brk2, 'X' ) = cv_goods_prod_sei
               )
             AND
               NVL( gt_prod_cls_brk2, 'X' ) = NVL( gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls, 'X' )
             )
           OR
             (
               (
                   NVL( gt_prod_cls_brk2, 'X' ) <> cv_goods_prod_syo
               AND NVL( gt_prod_cls_brk2, 'X' ) <> cv_goods_prod_sei
               )
               AND gt_item_code_brk2 = gt_sales_norm_tbl( sale_norm_idx ).item_code
             )
           )
        THEN
--
          --品目区分単位の合計を保持
          gn_term_amount := gn_term_amount + gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
--
        --前の品目区分の合計より合計金額が大きい場合
        ELSIF ( ABS( gn_term_amount ) >= ABS( gn_max_amount ) ) THEN
          gn_max_amount       := gn_term_amount;                                  -- 最大の金額を保持
          gn_term_amount      := gt_sales_norm_tbl( sale_norm_idx ).pure_amount;  -- 品目区分単位の合計金額初期化
          gt_goods_prod_class := gt_prod_cls_brk2;                                 -- 最大金額の品目区分を設定
          gt_goods_item_code  := gt_item_code_brk2;                                -- 最大金額の品目コードを設定
        END IF;
--
        gt_item_code_brk2 := gt_sales_norm_tbl( sale_norm_idx ).item_code;
        gt_prod_cls_brk2  := gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls;
--
        -- 課税の場合、消費税額を集約する
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          gn_tax := gn_tax + gt_sales_norm_tbl( sale_norm_idx ).tax_amount;
        END IF;
--
      ELSE
--
        IF ( ABS( gn_term_amount ) >= ABS( gn_max_amount ) ) THEN
          gt_goods_prod_class := gt_prod_cls_brk2;
          gt_goods_item_code  := gt_item_code_brk2;
        END IF;
        gn_max_amount       := 0;
/* 2009/11/15 Ver1.26 Mod Start */
--        gn_term_amount      := 0;
        gn_term_amount      := gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
/* 2009/11/15 Ver1.26 Mod End   */
        gt_item_code_brk2   := gt_sales_norm_tbl( sale_norm_idx ).item_code;
        gt_prod_cls_brk2    := gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls;
        gv_sum_flag         := cv_n_flag;
--
      END IF;
--
      IF ( gv_sum_flag = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Del Start */
--        --エラーフラグOFF
--        lv_err_flag := cv_n_flag;
/* 2009/10/02 Ver1.24 Del End   */
        lt_inspect_date := gt_sales_norm_tbl2( ln_trx_idx ).inspect_date;
/* 2009/10/27 Ver1.25 Add Start */
        lt_spot_term_id  := NULL;
        --=====================================================================
        -- ０．支払条件ID（即時）の取得
        --=====================================================================
        BEGIN
          SELECT /*+
                    INDEX(rtv0.t ra_terms_tl_n1)
                 */
                 rtv0.term_id     --即時の支払条件ID
          INTO   lt_spot_term_id
          FROM   ra_terms_vl rtv0
          WHERE  rtv0.term_id IN (
                   gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id
                  ,gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id2
                  ,gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id3
                 )
          AND    rtv0.name    = gt_spot_payment_code                                     -- 即時
          AND    lt_inspect_date  BETWEEN NVL( rtv0.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                  AND     NVL( rtv0.end_date_active  , lt_inspect_date )
          AND    ROWNUM       = 1;
--
          lv_term_chk_flag := cv_n_flag;   --即時の支払条件が存在するので支払条件IDの取得は実行しない
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_term_chk_flag := cv_y_flag; --即時の支払条件が取得できない場合、支払条件IDの取得を実行
        END;
/* 2009/10/27 Ver1.25 Add End   */
        --=====================================================================
        -- １．支払条件IDの取得
        --=====================================================================
/* 2009/10/27 Ver1.25 Add Start */
        --支払条件に即時が含まれる場合
        IF ( lv_term_chk_flag = cv_y_flag ) THEN
--
/* 2009/10/27 Ver1.25 Add End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value6  => lt_header_id
                            , iv_token_value6  => gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/27 Ver1.25 Add Start */
        --支払条件に即時が含まれる場合
        ELSE
          ln_term_id := lt_spot_term_id;
        END IF;
/* 2009/10/27 Ver1.25 Add End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value2  => lt_header_id
                            , iv_token_value2  => gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( lt_goods_prod_class IS NULL ) THEN
        IF ( gt_goods_prod_class IS NULL ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_item_idx := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--                      || lt_goods_item_code;
                      || gt_goods_item_code;
/* 2009/10/02 Ver1.24 Mod End   */
        ELSE
          lv_item_idx := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--                      || lt_goods_prod_class;
                      || gt_goods_prod_class;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--              AND  flvi.attribute2                = NVL( lt_goods_prod_class,
--                                                         lt_goods_item_code )
              AND  flvi.attribute2                = NVL( gt_goods_prod_class,
                                                         gt_goods_item_code )
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value2  => lt_header_id
                            , iv_token_value2  =>  gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                            iv_data_value2        =>  lt_header_id,
                            iv_data_value2        =>  gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id,
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Add Start */
         gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_norm_tbl2( ln_trx_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
      END IF;
--
      --==============================================================
      -- ４．AR請求取引OIFデータ作成
      --==============================================================
--
      -- -- 集約フラグ’N'の場合、AR請求取引OIFデータ作成する
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
      IF ( gv_sum_flag = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod Start */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount;
        gt_ar_interface_tbl( ln_ar_idx ).amount         := gn_amount;
/* 2009/10/02 Ver1.24 Mod Start */
                                                        -- 収益行：本体金額
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --内税時、金額は本体＋税金
/* 2009/10/02 Ver1.24 Mod Start */
--          gt_ar_interface_tbl( ln_ar_idx ).amount       := ln_amount + ln_tax;
          gt_ar_interface_tbl( ln_ar_idx ).amount       := gn_amount + gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                                                        := ln_amount;
                                                        := gn_amount;
/* 2009/10/02 Ver1.24 Mod End   */
                                                        -- 収益行のみ：販売単価=本体金額
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --内税時、販売単価は本体＋税金
/* 2009/10/02 Ver1.24 Mod Start */
--          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := ln_amount + ln_tax;
          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := gn_amount + gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax;
        gt_ar_interface_tbl( ln_ar_idx ).amount         := gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
--        -- 集約キーと集約金額のリセット
--        lt_trx_number      := gt_sales_norm_tbl2( sale_norm_idx ).oif_trx_number;        -- AR取引番号
--        lt_header_id       := gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id;   -- 販売実績ヘッダID
--
--        ln_amount := gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
--        IF ( gt_sales_norm_tbl2( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax  := gt_sales_norm_tbl2( sale_norm_idx ).tax_amount;
--        ELSE
--          ln_tax  := 0;
--        END IF;
--
      IF ( gv_sum_flag = cv_n_flag ) THEN
        --現レコードをインサート用配列に設定する
        gt_sales_norm_tbl2( ln_trx_idx ) := gt_sales_norm_tbl( sale_norm_idx );
        -- 集約キーと集約金額のリセット
        gv_trx_number_brk2 := gt_sales_norm_tbl( sale_norm_idx ).oif_trx_number;        -- AR取引番号
        gt_header_id_brk2  := gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id;   -- 販売実績ヘッダID
        gn_amount          := gt_sales_norm_tbl( sale_norm_idx ).pure_amount;           -- 本体金額
        --非課税の場合、消費税は0
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          gn_tax  := gt_sales_norm_tbl( sale_norm_idx ).tax_amount;
        ELSE
          gn_tax  := 0;
        END IF;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;
--
    END LOOP gt_sales_norm_sum_loop;                    -- 販売実績データループ終了
--
/* 2009/10/02 Ver1.24 Add Start */
    -- 次回のBULK処理の為、ループ終了時点のインサート用変数を保持
    gt_sales_sum_tbl_brk( ln_trx_idx ) := gt_sales_norm_tbl2( ln_trx_idx );
/* 2009/10/02 Ver1.24 Add End   */
--
/* 2009/10/02 Ver1.24 Del Start */
--    <<gt_sales_bulk_check_loop>>
--    FOR ln_ar_idx IN 1 .. gt_ar_interface_tbl.COUNT LOOP
--      -- 開始：1取引No内での出荷先顧客チェック
--
--      -- KEYが代わったら
--      IF (
--           (
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NULL )
--              AND
--              ( gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4 <> NVL( ln_key_dff4, 'X') )
--           )
--           OR
--           (
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NOT NULL )
--              AND
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number <> NVL( ln_key_trx_number, 'X') )
--           )
--         )THEN
--
--        -- 出荷先顧客フラグがONの場合
--        IF ( ln_ship_flg = cn_ship_flg_on )
--        THEN
--          <<gt_sales_bulk_ship_clear_loop>>
--          FOR start_index IN ln_start_index .. ln_ar_idx - 1 LOOP
--            -- 開始：1取引No内での出荷先顧客チェック
--
--            -- 出荷先顧客IDをクリア
--            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
--            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
--            -- 最後の行
--            IF ( gt_ar_interface_tbl.COUNT = ln_ar_idx )
--            THEN
--              -- 出荷先顧客IDをクリア
--              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id := NULL;
--              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id  := NULL;
--            END IF;
--
--            -- 終了：1取引No内での出荷先顧客チェック
--          END LOOP gt_sales_bulk_ship_clear_loop;
--        END IF;
--
--        -- 取引Noを取得
--        ln_key_trx_number := gt_ar_interface_tbl( ln_ar_idx ).trx_number;
--
--        -- DFF4を取得
--        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
--        -- 出荷先顧客IDを取得
--        ln_key_ship_customer_id := gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id;
--
--        -- 取引Noの開始位置を取得
--        ln_start_index := ln_ar_idx;
--
--        -- フラグを初期化
--        ln_ship_flg := cn_ship_flg_off;
--
--      ELSE
--        -- 出荷先顧客が同じか？
--        IF ( gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id <> ln_key_ship_customer_id ) THEN
--          -- 違う場合、出荷先顧客フラグをONにする
--          ln_ship_flg := cn_ship_flg_on;
--
--        END IF;
--        -- DFF4を取得
--        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
--        IF ( ln_ship_flg = cn_ship_flg_on AND ln_ar_idx = gt_ar_interface_tbl.COUNT ) THEN
--          <<gt_sales_bulk_ship_clear_loop>>
--          FOR start_index IN ln_start_index .. ln_ar_idx LOOP
--            -- 開始：1取引No内での出荷先顧客チェック
--
--            -- 出荷先顧客IDをクリア
--            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
--            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
--            -- 終了：1取引No内での出荷先顧客チェック
--          END LOOP gt_sales_bulk_ship_clear_loop;
--        END IF;
--
--      END IF;
--      -- 終了：1取引No内での出荷先顧客チェック
--    END LOOP gt_sales_bulk_check_loop;
/* 2009/10/02 Ver1.24 Del Start */
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
/* 2009/10/02 Ver1.24 Del Start */
--    -- 集約キー
--    lt_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE; -- 集約キー：納品伝票番号
--    lt_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;  -- 集約キー：納品伝票区分
--    lt_item_code        xxcos_sales_exp_lines.item_code%TYPE;            -- 集約キー：品目コード
--    lt_prod_cls         xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
--                                                                         -- 品目区分（製品・商品）
--    lt_gyotai_sho       xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;    -- 集約キー：業態小分類
--    lt_card_sale_class  xxcos_sales_exp_headers.card_sale_class%TYPE;    -- 集約キー：カード売り区分
--    lt_red_black_flag   xxcos_sales_exp_lines.red_black_flag%TYPE;       -- 集約キー：赤黒フラグ
--    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- 集約キー：税金コード
--    lt_header_id        xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- 集約キー：販売実績ヘッダID
--    ln_amount           NUMBER DEFAULT 0;                                -- 集約後金額
--    ln_tax              NUMBER DEFAULT 0;                                -- 集約後消費税金額
    ln_ar_dis_idx       NUMBER DEFAULT 0;                                -- AR会計配分集約インデックス
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR会計配分OIFインデックス
    ln_dis_idx          NUMBER DEFAULT 1;                                -- AR会計配分OIFインデックス
/* 2009/10/02 Ver1.24 Mod End   */
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- 仕訳生成カウント
    lv_rec_flag         VARCHAR2(1);                                     -- RECフラグ
/* 2009/10/02 Ver1.24 Del Start */
--    -- AR取引番号
--    lt_trx_number       VARCHAR2(20);
/* 2009/10/02 Ver1.24 Del End   */
    lv_err_flag         VARCHAR2(1);                                     -- エラー用フラグ
    lv_jour_flag        VARCHAR2(1);                                     -- エラー用フラグ
    ln_skip_idx         NUMBER DEFAULT 0;                                -- スキップ用インデックス;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
/* 2009/10/02 Ver1.24 Del Start */
--    non_jour_cls_expt         EXCEPTION;                -- 仕訳パターンなし
/* 2009/10/02 Ver1.24 Del End   */
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
/* 2009/10/02 Ver1.24 Del Start */
--    --=====================================
--    -- 1.AR会計配分仕訳パターンの取得
--    --=====================================
--
--    -- カーソルオープン
--    BEGIN
--      OPEN  jour_cls_cur;
--      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
--    EXCEPTION
--    -- 仕訳パターン取得失敗した場合
--      WHEN OTHERS THEN
--        lv_errmsg    := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_xxcos_short_nm
--                         , iv_name         => cv_jour_nodata_msg
--                         , iv_token_name1  => cv_tkn_lookup_type
--                         , iv_token_value1 => cv_qct_jour_cls
--                       );
--        lv_errbuf := lv_errmsg;
--        RAISE non_jour_cls_expt;
--    END;
--    -- 仕訳パターン取得失敗した場合
--    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
--      lv_errmsg    := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_xxcos_short_nm
--                       , iv_name         => cv_jour_nodata_msg
--                       , iv_token_name1  => cv_tkn_lookup_type
--                       , iv_token_value1 => cv_qct_jour_cls
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE non_jour_cls_expt;
--    END IF;
--
--    -- カーソルクローズ
--    CLOSE jour_cls_cur;
--
    --スキップカウントセット
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
    --=====================================
    -- 3.AR会計配分データ作成
    --=====================================
/* 2009/10/02 Ver1.24 Mod Start */
--    -- 集約キーの値セット
--    lt_invoice_number   := gt_sales_norm_tbl2( 1 ).dlv_invoice_number;
--    lt_item_code        := gt_sales_norm_tbl2( 1 ).item_code;
--    lt_prod_cls         := gt_sales_norm_tbl2( 1 ).goods_prod_cls;
--    lt_gyotai_sho       := gt_sales_norm_tbl2( 1 ).cust_gyotai_sho;
--    lt_card_sale_class  := gt_sales_norm_tbl2( 1 ).card_sale_class;
--    lt_tax_code         := gt_sales_norm_tbl2( 1 ).tax_code;
--    lt_invoice_class    := gt_sales_norm_tbl2( 1 ).dlv_invoice_class;
--    lt_red_black_flag   := gt_sales_norm_tbl2( 1 ).red_black_flag;
--    lt_header_id        := gt_sales_norm_tbl2( 1 ).sales_exp_header_id;
--
--    -- ラストデータ登録為に、ダミーデータをセットする
--    gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT + 1 ).sales_exp_header_id
--                        := gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT ).sales_exp_header_id;
--
    -- 最初のBUKL処理の場合
    IF ( gn_fetch_first_flag = 0 ) THEN
      -- 集約キーの値セット
      gt_invoice_number_ar_brk   := gt_sales_norm_tbl( 1 ).dlv_invoice_number;
      gt_item_code_ar_brk        := gt_sales_norm_tbl( 1 ).item_code;
      gt_prod_cls_ar_brk         := gt_sales_norm_tbl( 1 ).goods_prod_cls;
      gt_gyotai_sho_ar_brk       := gt_sales_norm_tbl( 1 ).cust_gyotai_sho;
      gt_card_sale_class_ar_brk  := gt_sales_norm_tbl( 1 ).card_sale_class;
      gt_tax_code_ar_brk         := gt_sales_norm_tbl( 1 ).tax_code;
      gt_invoice_class_ar_brk    := gt_sales_norm_tbl( 1 ).dlv_invoice_class;
      gt_red_black_flag_ar_brk   := gt_sales_norm_tbl( 1 ).red_black_flag;
      gt_header_id_ar_brk        := gt_sales_norm_tbl( 1 ).sales_exp_header_id;
    END IF;
    -- 2回目以降のBUKL処理の場合、保持していた前レコードをインサート用変数に移す
    IF ( gt_sales_dis_tbl_brk.COUNT <> 0 ) THEN
      gt_sales_norm_tbl2( ln_dis_idx ) := gt_sales_dis_tbl_brk( ln_dis_idx );
    END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_norm_tbl2_loop>>
--    FOR dis_sum_idx IN 1 .. gt_sales_norm_tbl2.COUNT LOOP
--
--      -- AR会計配分データ集約開始
--      IF ( lt_invoice_number = gt_sales_norm_tbl2( dis_sum_idx ).dlv_invoice_number
--        AND
--          (
--            (
--              (
--                 NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
--              OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
--              )
--            AND
--              NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_norm_tbl2( dis_sum_idx ).goods_prod_cls, 'X' )
--            )
--          OR
--            (
--              (
--                  NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
--              AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
--              )
--              AND lt_item_code = gt_sales_norm_tbl2( dis_sum_idx ).item_code
--            )
--          )
--        AND lt_gyotai_sho      = gt_sales_norm_tbl2( dis_sum_idx ).cust_gyotai_sho
--        AND lt_card_sale_class = gt_sales_norm_tbl2( dis_sum_idx ).card_sale_class
--        AND lt_tax_code        = gt_sales_norm_tbl2( dis_sum_idx ).tax_code
--        AND lt_header_id       = gt_sales_norm_tbl2( dis_sum_idx ).sales_exp_header_id
--        )
--      THEN
--
--        -- 集約するフラグ初期設定
--        lv_sum_flag := cv_y_flag;
--
--       -- 本体金額と消費税額を集約する
--        ln_amount := ln_amount + gt_sales_norm_tbl2( dis_sum_idx ).pure_amount;
--        ln_tax    := ln_tax    + gt_sales_norm_tbl2( dis_sum_idx ).tax_amount;
--      ELSE
--        lv_sum_flag := cv_n_flag;
--        ln_dis_idx  := dis_sum_idx - 1;
--      END IF;
--
    <<gt_sales_norm_tbl_loop>>
    FOR dis_sum_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
--
      -- AR会計配分データ集約開始
      IF ( gt_invoice_number_ar_brk = gt_sales_norm_tbl( dis_sum_idx ).dlv_invoice_number
        AND
          (
            (
              (
                 NVL( gt_prod_cls_ar_brk, 'X' ) = cv_goods_prod_syo
              OR NVL( gt_prod_cls_ar_brk, 'X' ) = cv_goods_prod_sei
              )
            AND NVL( gt_prod_cls_ar_brk, 'X' ) = NVL( gt_sales_norm_tbl( dis_sum_idx ).goods_prod_cls, 'X' )
            )
          OR
            (
              (
                  NVL( gt_prod_cls_ar_brk, 'X' ) <> cv_goods_prod_syo
              AND NVL( gt_prod_cls_ar_brk, 'X' ) <> cv_goods_prod_sei
              )
            AND gt_item_code_ar_brk = gt_sales_norm_tbl( dis_sum_idx ).item_code
            )
          )
        AND gt_gyotai_sho_ar_brk      = gt_sales_norm_tbl( dis_sum_idx ).cust_gyotai_sho
        AND gt_card_sale_class_ar_brk = gt_sales_norm_tbl( dis_sum_idx ).card_sale_class
        AND gt_tax_code_ar_brk        = gt_sales_norm_tbl( dis_sum_idx ).tax_code
        AND gt_header_id_ar_brk       = gt_sales_norm_tbl( dis_sum_idx ).sales_exp_header_id
        )
      THEN
--
        -- インサート用の配列を保持
        gt_sales_norm_tbl2( ln_dis_idx ) := gt_sales_norm_tbl( dis_sum_idx );
        -- 集約するフラグ初期設定
        gv_sum_flag_ar                   := cv_y_flag;
        -- 本体金額と消費税額を集約する
        gn_amount_ar                     := gn_amount_ar + gt_sales_norm_tbl( dis_sum_idx ).pure_amount;
        gn_tax_ar                        := gn_tax_ar    + gt_sales_norm_tbl( dis_sum_idx ).tax_amount;
--
      ELSE
--
        gv_sum_flag_ar := cv_n_flag;
--
      END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
      -- -- 集約フラグ’N'の場合、下記AR会計配分OIF作成処理を行う
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
      IF ( gv_sum_flag_ar = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( NVL( lt_trx_number, 'X' ) <> gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number ) THEN
        IF ( NVL( gv_trx_number_ar_brk, 'X' ) <> gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_rec_flag := cv_y_flag;
        ELSE
          lv_rec_flag := cv_n_flag;
        END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--        lt_trx_number      := gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number;        -- AR取引番号
        gv_trx_number_ar_brk  := gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number;        -- AR取引番号
/* 2009/10/02 Ver1.24 Mod End   */
--
        -- 仕訳生成カウント初期値
        ln_jour_cnt := 1;
        lv_jour_flag := cv_n_flag;
--
        -- 仕訳パターンよりAR会計配分の仕訳を編集する
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
/* 2009/10/02 Ver1.24 Mod Start */
--          IF (  gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = lt_invoice_class
--            AND (  gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = lt_item_code
--              OR ( gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> lt_item_code
--                AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls = lt_prod_cls ) )
--            AND ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = lt_gyotai_sho
--              OR  gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL )
--            AND ( gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = lt_card_sale_class
--              OR  gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL )
--            AND ( gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
--              OR  gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL )
--            ) THEN
--
          IF (   gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = gt_invoice_class_ar_brk
             AND (
                    gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = gt_item_code_ar_brk
                 OR
                   (   gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> gt_item_code_ar_brk
                   AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls   = gt_prod_cls_ar_brk
                   )
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_gyotai_sho_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = gt_card_sale_class_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).red_black_flag  = gt_red_black_flag_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL
                 )
             )
          THEN
/* 2009/10/02 Ver1.24 Mod End */
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
/* 2009/08/28 Ver1.23 Mod Start */
--                             gd_process_date
                             gt_sales_norm_tbl2( ln_dis_idx ).inspect_date
/* 2009/08/28 Ver1.23 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                                , iv_token_value9      => lt_header_id
--                                , iv_token_name10      => cv_tkn_order_no
--                                , iv_token_value10     => lt_invoice_number
                                , iv_token_value9      => gt_header_id_ar_brk
                                , iv_token_name10      => cv_tkn_order_no
                                , iv_token_value10     => gt_invoice_number_ar_brk
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/08/28 Ver1.23 Mod Start */
--              END IF;
----
--              -- 取得したCCIDをワークテーブルに設定する
--              gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
              ELSE
                -- 共通関数より取得できた場合、取得したCCIDをワークテーブルに設定する
                gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
--
              END IF;
/* 2009/08/28 Ver1.23 Mod End   */
--
            END IF;                                       -- CCID編集終了
--
            --スキップ処理
            IF ( lv_err_flag = cv_y_flag ) THEN
               ln_skip_idx := ln_skip_idx + 1;
               gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add Start */
               gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_norm_tbl2( ln_dis_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_amount;
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := gn_amount_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- 金額(明細金額)
              IF ( gt_sales_norm_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --内税時、金額は本体＋税金
/* 2009/10/02 Ver1.24 Mod Start */
--                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := ln_amount + ln_tax;
                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := gn_amount_ar + gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
              END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_amount;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := gn_amount_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- パーセント(割合)
              IF ( gt_sales_norm_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --内税時、 パーセント(割合は本体＋税金
/* 2009/10/02 Ver1.24 Mod Start */
--                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := ln_amount + ln_tax;
                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := gn_amount_ar + gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_tax;
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- 金額(明細金額)
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_tax;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( ln_jour_cnt = 1 AND dis_sum_idx <> gt_sales_norm_tbl2.COUNT ) THEN
        --仕訳が１件もない場合エラー
        IF ( ln_jour_cnt = 1 ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application       => cv_xxcos_short_nm
                          , iv_name              => cv_jour_no_msg
                          , iv_token_name1       => cv_tkn_invoice_cls
/* 2009/10/02 Ver1.24 Mod Start */
--                          , iv_token_value1      => lt_invoice_class
--                          , iv_token_name2       => cv_tkn_prod_cls
--                          , iv_token_value2      => NVL( lt_prod_cls, lt_item_code )
--                          , iv_token_name3       => cv_tkn_gyotai_sho
--                          , iv_token_value3      => lt_gyotai_sho
--                          , iv_token_name4       => cv_tkn_sale_cls
--                          , iv_token_value4      => lt_card_sale_class
--                          , iv_token_name5       => cv_tkn_red_black_flag
--                          , iv_token_value5      => lt_red_black_flag
--                          , iv_token_name6       => cv_tkn_header_id
--                          , iv_token_value6      => lt_header_id
--                          , iv_token_name7       => cv_tkn_order_no
--                          , iv_token_value7      => lt_invoice_number
                          , iv_token_value1      => gt_invoice_class_ar_brk
                          , iv_token_name2       => cv_tkn_prod_cls
                          , iv_token_value2      => NVL( gt_prod_cls_ar_brk, gt_item_code_ar_brk )
                          , iv_token_name3       => cv_tkn_gyotai_sho
                          , iv_token_value3      => gt_gyotai_sho_ar_brk
                          , iv_token_name4       => cv_tkn_sale_cls
                          , iv_token_value4      => gt_card_sale_class_ar_brk
                          , iv_token_name5       => cv_tkn_red_black_flag
                          , iv_token_value5      => gt_red_black_flag_ar_brk
                          , iv_token_name6       => cv_tkn_header_id
                          , iv_token_value6      => gt_header_id_ar_brk
                          , iv_token_name7       => cv_tkn_order_no
                          , iv_token_value7      => gt_invoice_number_ar_brk
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Add Start */
             gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_norm_tbl2( ln_dis_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
          END IF;
        END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--        -- 金額の設定
--        ln_amount        := gt_sales_norm_tbl2( dis_sum_idx ).pure_amount;
--        ln_tax           := gt_sales_norm_tbl2( dis_sum_idx ).tax_amount;
        -- 金額の設定
        gn_amount_ar  := gt_sales_norm_tbl( dis_sum_idx ).pure_amount;
        gn_tax_ar     := gt_sales_norm_tbl( dis_sum_idx ).tax_amount;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;                                             -- 集約キー毎にAR会計配分OIFデータの集約終了
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- 集約キーのリセット
--      lt_invoice_number   := gt_sales_norm_tbl2( dis_sum_idx ).dlv_invoice_number;
--      lt_item_code        := gt_sales_norm_tbl2( dis_sum_idx ).item_code;
--      lt_prod_cls         := gt_sales_norm_tbl2( dis_sum_idx ).goods_prod_cls;
--      lt_gyotai_sho       := gt_sales_norm_tbl2( dis_sum_idx ).cust_gyotai_sho;
--      lt_card_sale_class  := gt_sales_norm_tbl2( dis_sum_idx ).card_sale_class;
--      lt_tax_code         := gt_sales_norm_tbl2( dis_sum_idx ).tax_code;
--      lt_invoice_class    := gt_sales_norm_tbl2( dis_sum_idx ).dlv_invoice_class;
--      lt_red_black_flag   := gt_sales_norm_tbl2( dis_sum_idx ).red_black_flag;
--      lt_header_id        := gt_sales_norm_tbl2( dis_sum_idx ).sales_exp_header_id;
--
      --現レコードをインサート用配列に設定する
      gt_sales_norm_tbl2( ln_dis_idx ) := gt_sales_norm_tbl( dis_sum_idx );
      -- 集約キーのリセット
      gt_invoice_number_ar_brk   := gt_sales_norm_tbl( dis_sum_idx ).dlv_invoice_number;
      gt_item_code_ar_brk        := gt_sales_norm_tbl( dis_sum_idx ).item_code;
      gt_prod_cls_ar_brk         := gt_sales_norm_tbl( dis_sum_idx ).goods_prod_cls;
      gt_gyotai_sho_ar_brk       := gt_sales_norm_tbl( dis_sum_idx ).cust_gyotai_sho;
      gt_card_sale_class_ar_brk  := gt_sales_norm_tbl( dis_sum_idx ).card_sale_class;
      gt_tax_code_ar_brk         := gt_sales_norm_tbl( dis_sum_idx ).tax_code;
      gt_invoice_class_ar_brk    := gt_sales_norm_tbl( dis_sum_idx ).dlv_invoice_class;
      gt_red_black_flag_ar_brk   := gt_sales_norm_tbl( dis_sum_idx ).red_black_flag;
      gt_header_id_ar_brk        := gt_sales_norm_tbl( dis_sum_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    END LOOP gt_sales_norm_tbl2_loop;                      -- AR会計配分集約データループ終了
    END LOOP gt_sales_norm_tbl_loop;                      -- AR会計配分集約データループ終了
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Add Start */
    -- 次回のBULK処理の為、ループ終了時点のインサート用変数を保持
    gt_sales_dis_tbl_brk( ln_dis_idx ) := gt_sales_norm_tbl2( ln_dis_idx );
--
/* 2009/10/02 Ver1.24 Add End   */
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
/* 2009/10/02 Ver1.24 Del Start */
--    WHEN non_jour_cls_expt THEN
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
/* 2009/10/02 Ver1.24 Del End   */
--
    WHEN non_ccid_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- カーソルクローズ
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- カーソルクローズ
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- カーソルクローズ
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
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
/* 2009/11/05 Ver1.26 Mod Start */
--    cn_pad_num_char         CONSTANT NUMBER := 3;            -- PAD関数で埋め込む文字数
    cn_pad_num_char         CONSTANT NUMBER := 2;            -- PAD関数で埋め込む文字数
/* 2009/11/05 Ver1.26 Mod End   */
--
    -- *** ローカル変数 ***
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_sale_bulk_idx2       NUMBER DEFAULT 0;           -- 生成したカードレコードのインデックス
--    ln_card_pt              NUMBER DEFAULT 1;           -- カードレコードのインデックス現行位置
/* 2009/10/02 Ver1.24 Mod End   */
    ln_ar_idx               NUMBER DEFAULT 0;           -- 請求取引OIFインデックス
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_trx_idx              NUMBER DEFAULT 0;           -- AR配分OIF集約データインデックス;
    ln_trx_idx              NUMBER DEFAULT 1;           -- AR配分OIF集約データインデックス;
/* 2009/10/02 Ver1.24 Mod End   */
    lv_trx_type_nm          VARCHAR2(30);               -- 取引タイプ名称
    lv_trx_idx              VARCHAR2(30);               -- 取引タイプ(インデックス)
    lv_item_idx             VARCHAR2(30);               -- 品目明細摘要(インデックス)
    lv_item_desp            VARCHAR2(30);               -- 品目明細摘要(TAX以外)
    ln_term_id              VARCHAR2(30);               -- 支払条件ID
/* 2009/10/02 Ver1.24 Del Start */
--    lv_cust_gyotai_sho      VARCHAR2(30);               -- 業態小分類
--    ln_pure_amount          NUMBER DEFAULT 0;           -- カードレコードの本体金額
--    ln_tax_amount           NUMBER DEFAULT 0;           -- カードレコードの消費税金額
--    ln_tax                  NUMBER DEFAULT 0;           -- 集約後消費税金額
--    ln_amount               NUMBER DEFAULT 0;           -- 集約後金額
--    ln_trx_number_id        NUMBER;                     -- 取引明細DFF3用:自動採番番号
--    ln_trx_number_tax_id    NUMBER;                     -- 取引明細DFF3用税金用:自動採番番号
/* 2009/10/02 Ver1.24 Del End   */
    lv_trx_sent_dv          VARCHAR2(30);               -- 請求書発行区分
/* 2009/10/02 Ver1.24 Del Start */
--    lv_trx_number           VARCHAR2(20);               -- AR取引番号
/* 2009/10/02 Ver1.24 Del End   */
    ln_trx_number_large     NUMBER;                    -- 取引番号:自動採番
/* 2009/10/02 Ver1.24 Del Start */
--    ln_sales_h_tbl_idx      NUMBER DEFAULT 0;           -- 販売実績ヘッダ更新用インデックス
--    ln_key_trx_number       VARCHAR2(20);               -- 取引No
--    ln_key_dff4             VARCHAR2(100);              -- DFF4
--    ln_key_ship_customer_id NUMBER;                     -- 出荷先顧客ID
--    ln_start_index          NUMBER DEFAULT 1;           -- 取引No毎の開始位置
--    ln_ship_flg             NUMBER DEFAULT 0;           -- 出荷先顧客フラグ
--    ln_term_amount          NUMBER DEFAULT 0;           -- 一時金額
--    ln_max_amount           NUMBER DEFAULT 0;           -- 最大金額
--
--    -- *** 取引NO取得キー
--      -- 作成区分
--    lt_create_class         xxcos_sales_exp_headers.create_class%TYPE;
--      -- 納品伝票番号
--    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
--      -- 納品伝票区分
--    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
--      -- 請求先顧客
--    lt_xchv_cust_id_b       xxcos_cust_hierarchy_v.bill_account_id%TYPE;
--      -- 売上計上日
--    lt_sales_date           xxcos_sales_exp_headers.inspect_date%TYPE;
--
--    -- *** 集約キー(販売実績)
--      -- 販売実績ヘッダID
--    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
--      -- AR取引番号
--    lt_trx_number           VARCHAR2(20);
--     --カード売り区分
--    lt_cash_sale_cls        xxcos_sales_exp_headers.card_sale_class%TYPE;
--
--    lv_sum_flag             VARCHAR2(1);                -- 集約フラグ
--    lv_sum_card_flag        VARCHAR2(1);                -- カード集約フラグ
/* 2009/10/02 Ver1.24 Del End   */
/* 2009/11/05 Ver1.26 Del Start */
--    lv_employee_name        VARCHAR2(100);              -- 伝票入力者
/* 2009/11/05 Ver1.26 Del End   */
/* 2009/10/02 Ver1.24 Del Start */
--    lv_idx_key              VARCHAR2(300);              -- PL/SQL表ソート用インデックス文字列
--    ln_now_index            VARCHAR2(300);
--    ln_first_index          VARCHAR2(300);
--    ln_smb_idx              NUMBER DEFAULT 0;           -- 生成したインデックス
/* 2009/10/02 Ver1.24 Del End   */
    lv_tbl_nm               VARCHAR2(100);              -- 従業員マスタ
    lv_employee_nm          VARCHAR2(100);              -- 従業員
    lv_header_id_nm         VARCHAR2(100);              -- ヘッダID
    lv_order_no_nm          VARCHAR2(100);              -- 伝票番号
    lv_key_info             VARCHAR2(100);              -- 伝票番号
/* 2009/10/02 Ver1.24 Del Start */
--      -- 品目区分
--    lt_goods_prod_class     xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
/* 2009/10/02 Ver1.24 Del End   */
    lv_err_flag             VARCHAR2(1);                -- エラー用フラグ
    ln_skip_idx             NUMBER DEFAULT 0;           -- スキップ用インデックス;
/* 2009/10/02 Ver1.24 Del Start */
--    lt_goods_item_code      xxcos_sales_exp_lines.item_code%TYPE;
--    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
--    lt_prod_cls             xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
/* 2009/10/02 Ver1.24 Del End   */
    lt_inspect_date         xxcos_sales_exp_headers.inspect_date%TYPE;          -- 検収日
/* 2009/10/27 Ver1.25 Add Start */
    lt_spot_term_id         ra_terms_tl.term_id%TYPE;   -- 支払条件ID(即時)
    lv_term_chk_flag        VARCHAR2(1);                -- 支払条件チェック実行フラグ
/* 2009/10/27 Ver1.25 Add End   */
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
/* 2009/10/02 Ver1.24 Del Start */
--    --=====================================================================
--    -- 集計前データ展開
--    --=====================================================================
--
--    --テーブルソールする
--    -- 正常データのみのPL/SQL表作成
--    <<loop_make_sort_data>>
--    FOR i IN 1..gt_sales_bulk_tbl.COUNT LOOP
--      --ソートキーは販売実績ヘッダID、カード売り区分、販売実績明細ID
--      lv_idx_key := gt_sales_bulk_tbl(i).sales_exp_header_id
--                    || gt_sales_bulk_tbl(i).dlv_invoice_number
--                    || gt_sales_bulk_tbl(i).dlv_invoice_class
--                    || gt_sales_bulk_tbl(i).card_sale_class
--                    || gt_sales_bulk_tbl(i).cust_gyotai_sho
--                    || gt_sales_bulk_tbl(i).goods_prod_cls
--                    || gt_sales_bulk_tbl(i).item_code
--                    || gt_sales_bulk_tbl(i).red_black_flag
--                    || gt_sales_bulk_tbl(i).line_id;
--      gt_sales_bulk_order_tbl(lv_idx_key) := gt_sales_bulk_tbl(i);
--    END LOOP loop_make_sort_data;
--
--    IF gt_sales_bulk_order_tbl.COUNT = 0 THEN
--      RETURN;
--    END IF;
--
--    ln_first_index := gt_sales_bulk_order_tbl.first;
--    ln_now_index := ln_first_index;
--
--    WHILE ln_now_index IS NOT NULL LOOP
--
--      ln_smb_idx := ln_smb_idx + 1;
--      gt_sales_bulk_tbl2(ln_smb_idx) := gt_sales_bulk_order_tbl(ln_now_index);
--      -- 次のインデックスを取得する
--      ln_now_index := gt_sales_bulk_order_tbl.next(ln_now_index);
--
--    END LOOP;--ソート完了
--
--    -- 請求取引テーブルの非大手量販店データカウントセット
--    ln_ar_idx := gt_ar_interface_tbl.COUNT;
/* 2009/10/02 Ver1.24 Del End   */
--
    --スキップカウントセット
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_bulk_tbl2_loop>>
--    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl2.COUNT LOOP
--
--
--      -- AR取引番号の自動採番
--      IF (  NVL( lt_create_class, 'X' )        <> gt_sales_bulk_tbl2( sale_bulk_idx ).create_class        -- 作成元区分
--         OR lt_sales_date                      <> gt_sales_bulk_tbl2( sale_bulk_idx ).inspect_date  -- 売上計上日
--         OR NVL( lt_invoice_class, 'X' )       <> NVL( gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_class, 'X' )   -- 納品伝票区分
--         OR lt_xchv_cust_id_b                  <> gt_sales_bulk_tbl2( sale_bulk_idx ).xchv_cust_id_b      -- 請求先顧客
--         OR (  ( gt_fvd_xiaoka                 =  gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho      -- フルサービス（消化）VD :24
--               OR gt_gyotai_fvd                =  gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho )    -- フルサービス VD :25
--             AND ( lt_header_id                 <> gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id  -- 販売実績ヘッダID
--             OR NVL( lt_cash_sale_cls, 'X' ) <> gt_sales_bulk_tbl2( sale_bulk_idx ).card_sale_class ) )   --カード売り区分
--         )
--
    <<gt_sales_bulk_tbl_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
--
      -- AR取引番号の自動採番
/* 2009/11/05 Ver1.26 Mod Start */
--      IF (  NVL( gt_create_class_brk, 'X' )     <> gt_sales_bulk_tbl( sale_bulk_idx ).create_class   -- 作成元区分
--         OR gt_sales_date_brk                   <> gt_sales_bulk_tbl( sale_bulk_idx ).inspect_date   -- 売上計上日
      IF (  gt_sales_date_brk                   <> gt_sales_bulk_tbl( sale_bulk_idx ).inspect_date   -- 売上計上日
/* 2009/11/05 Ver1.26 Mod End   */
         OR NVL( gt_invoice_class_brk, 'X' )    <> NVL( gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class, 'X' )   -- 納品伝票区分
/* 2009/11/05 Ver1.26 Mod Start */
--         OR gt_xchv_cust_id_b_brk               <> gt_sales_bulk_tbl( sale_bulk_idx ).xchv_cust_id_b      -- 請求先顧客
         OR (
              (    gt_xchv_cust_id_b_brk        <> gt_sales_bulk_tbl( sale_bulk_idx ).xchv_cust_id_b   -- 請求先顧客
                OR gt_pay_cust_number_brk       <> gt_sales_bulk_tbl( sale_bulk_idx ).pay_cust_number  -- 支払請求先顧客
              )
            )  --請求先が異なるか、カード会社が異なる場合
/* 2009/11/05 Ver1.26 Mod End   */
         OR (
              (    gt_fvd_xiaoka    =  gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho   -- フルサービス（消化）VD :24
                OR gt_gyotai_fvd    =  gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho   -- フルサービス VD :25
              )
              AND
/* 2009/11/05 Ver1.26 Mod Start */
--              (    gt_header_id_brk                 <> gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id  -- 販売実績ヘッダID
--                OR NVL( gt_cash_sale_cls_brk, 'X' ) <> gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class      -- カード売り区分
              (
                NVL( gt_cash_sale_cls_brk, 'X' ) <> gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class      -- カード売り区分
/* 2009/11/05 Ver1.26 Mod End   */
              )
            )
         )
      THEN
/* 2009/10/02 Ver1.24 Mod End   */
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
        -- AR取引番号の編集 売上計上日(YYYYMMDD：8桁) + 請求先顧客番号(9桁)＋納品伝票区分(1桁)＋シーケンス2桁
/* 2009/10/02 Ver1.24 Mod Start */
--        lv_trx_number := TO_CHAR( gt_sales_bulk_tbl2( sale_bulk_idx ).inspect_date,cv_date_format_non_sep )
        gv_trx_number := TO_CHAR( gt_sales_bulk_tbl( sale_bulk_idx ).inspect_date, cv_date_format_non_sep )
/* 2009/10/02 Ver1.24 Mod End   */
                           || gt_sales_bulk_tbl( sale_bulk_idx ).xchv_cust_number_b
/* 2009/11/05 Ver1.26 Add Start */
                           || gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class
/* 2009/11/05 Ver1.26 Add End   */
                           || LPAD( TO_CHAR( ln_trx_number_large )
                                            ,cn_pad_num_char
                                            ,cv_pad_char
                                           );
--
      END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- 納品伝票番号＋シーケンスの採番
--      IF (  NVL(  lt_trx_number, 'X' )    <> lv_trx_number                                            -- AR取引番号
--         OR  lt_header_id                 <> gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id   -- 販売実績ヘッダID
--         )
      -- 納品伝票番号＋シーケンスの採番
      IF (  NVL(  gv_trx_number_brk, 'X' )  <> gv_trx_number                                            -- AR取引番号
         OR  gt_header_id_brk               <> gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id   -- 販売実績ヘッダID
         )
/* 2009/10/02 Ver1.24 Mod End   */
      THEN
          -- 取引明細DFF4用:自動採番番号
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
/* 2009/10/02 Ver1.24 Mod Start */
--            ln_trx_number_id
            gn_trx_number_id
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--            ln_trx_number_tax_id
            gn_trx_number_tax_id
/* 2009/10/02 Ver1.24 Mod End   */
          FROM
            dual
          ;
        END;
      END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- 取引番号キー
--      lt_invoice_class    := gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_class;
--      lt_create_class     := gt_sales_bulk_tbl2( sale_bulk_idx ).create_class;
--      lt_sales_date       := gt_sales_bulk_tbl2( sale_bulk_idx ).inspect_date;
--      lt_xchv_cust_id_b   := gt_sales_bulk_tbl2( sale_bulk_idx ).xchv_cust_id_b;
--      lt_cash_sale_cls    := gt_sales_bulk_tbl2( sale_bulk_idx ).card_sale_class;
--
--
--      -- 納品伝票番号＋シーケンスの採番の集約キーの値セット
--      lt_trx_number       := lv_trx_number;
--      lt_header_id        := gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id;
--
--
--        -- AR取引番号
--      gt_sales_bulk_tbl2( sale_bulk_idx ).oif_trx_number   := lv_trx_number;
--        -- DFF4
--      gt_sales_bulk_tbl2( sale_bulk_idx ).oif_dff4         := gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_number
--                                                                  || TO_CHAR( ln_trx_number_id );
--      gt_sales_bulk_tbl2( sale_bulk_idx ).oif_tax_dff4     := gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_number
--                                                                    || TO_CHAR( ln_trx_number_tax_id );
--
--        -- 業態小分類の編集
--      IF ( gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
--        AND gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho <> gt_gyotai_fvd) THEN
--
--          gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho := cv_nvd;                 -- VD以外の業態・納品VD
--
--      END IF;
--
--    END LOOP gt_sales_bulk_tbl2_loop;
--
      -- 取引番号キー
      gt_invoice_class_brk    := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class;
/* 2009/11/05 Ver1.26 Del Start */
--      gt_create_class_brk     := gt_sales_bulk_tbl( sale_bulk_idx ).create_class;
/* 2009/11/05 Ver1.26 Del End   */
      gt_sales_date_brk       := gt_sales_bulk_tbl( sale_bulk_idx ).inspect_date;
      gt_xchv_cust_id_b_brk   := gt_sales_bulk_tbl( sale_bulk_idx ).xchv_cust_id_b;
/* 2009/11/05 Ver1.26 Add Start */
      gt_pay_cust_number_brk  := gt_sales_bulk_tbl( sale_bulk_idx ).pay_cust_number;
/* 2009/11/05 Ver1.26 Add End   */
      gt_cash_sale_cls_brk    := gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class;
--
      -- 納品伝票番号＋シーケンスの採番の集約キーの値セット
      gv_trx_number_brk       := gv_trx_number;
      gt_header_id_brk        := gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id;
--
      -- AR取引番号
      gt_sales_bulk_tbl( sale_bulk_idx ).oif_trx_number   := gv_trx_number;
      -- DFF4
      gt_sales_bulk_tbl( sale_bulk_idx ).oif_dff4         := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_number
                                                                  || TO_CHAR( gn_trx_number_id );
      -- DFF4税金用
      gt_sales_bulk_tbl( sale_bulk_idx ).oif_tax_dff4     := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_number
                                                                  || TO_CHAR( gn_trx_number_tax_id );
--
      -- 業態小分類の編集
      IF (
             gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
         AND gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho <> gt_gyotai_fvd
         )
      THEN
--
          gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho := cv_nvd;  -- VD以外の業態・納品VD
--
      END IF;
--
    END LOOP gt_sales_bulk_tbl_loop;
/* 2009/10/02 Ver1.24 Mod End   */
--
    --=====================================================================
    -- 請求取引集約処理（大手量販店）開始
    --=====================================================================
/* 2009/10/02 Ver1.24 Mod Start */
--    -- 集約キーの値セット
--    lt_trx_number       := gt_sales_bulk_tbl2( 1 ).oif_trx_number;            -- AR取引番号
--    lt_header_id        := gt_sales_bulk_tbl2( 1 ).sales_exp_header_id;   -- 販売実績ヘッダID
--
--    -- ラストデータ登録為に、ダミーデータをセット
--    gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT + 1 ).sales_exp_header_id
--                        := gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT ).sales_exp_header_id;
--
--    lt_item_code        := gt_sales_bulk_tbl2( 1 ).item_code;
--    lt_prod_cls         := gt_sales_bulk_tbl2( 1 ).goods_prod_cls;
--
    -- 最初のBUKL処理の場合
    IF ( gn_fetch_first_flag = 0 ) THEN
      -- 集約キーの値セット
      gv_trx_number_brk2  := gt_sales_bulk_tbl( 1 ).oif_trx_number;        -- AR取引番号
      gt_header_id_brk2   := gt_sales_bulk_tbl( 1 ).sales_exp_header_id;   -- 販売実績ヘッダID
      gt_item_code_brk2   := gt_sales_bulk_tbl( 1 ).item_code;             -- 品目コード
      gt_prod_cls_brk2    := gt_sales_bulk_tbl( 1 ).goods_prod_cls;        -- 商品区分
    END IF;
    -- 2回目以降のBUKL処理の場合、保持していた前レコードをインサート用変数に移す
    IF ( gt_sales_sum_tbl_brk.COUNT <> 0 ) THEN
      gt_sales_bulk_tbl2( ln_trx_idx ) := gt_sales_sum_tbl_brk( ln_trx_idx );
    END IF;
    -- 最後のBULK処理の最終レコードの場合
    IF ( gn_fetch_end_flag = 1 ) THEN
      -- ラストデータ登録為に、ダミーデータをセット(カウント0を考慮し-1を設定)
      gt_sales_bulk_tbl( gt_sales_bulk_tbl.COUNT + 1 ).sales_exp_header_id
                           := -1;
    END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_bulk_sum_loop>>
--    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl2.COUNT LOOP
--
--     --=====================================
--     --  販売実績元データの集約
--     --=====================================
--     IF (  lt_trx_number   = gt_sales_bulk_tbl2( sale_bulk_idx ).oif_trx_number
--         AND lt_header_id   = gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id
--         )
--      THEN
--
--        -- 集約するフラグ初期設定
--        lv_sum_flag      := cv_y_flag;
--
--        -- 本体金額を集約する
--        ln_amount := ln_amount + gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
--
--       IF ( (
--               (
--                  NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
--               OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
--               )
--             AND
--               NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_bulk_tbl2( sale_bulk_idx ).goods_prod_cls, 'X' )
--             )
--           OR
--             (
--               (
--                   NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
--               AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
--               )
--               AND lt_item_code = gt_sales_bulk_tbl2( sale_bulk_idx ).item_code
--             )
--           )THEN
--             ln_term_amount := ln_term_amount + gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
--        ELSIF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
--             ln_max_amount       := ln_term_amount;
--             ln_term_amount      := gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
--             lt_goods_prod_class := lt_prod_cls;
--             lt_goods_item_code  := lt_item_code;
--        END IF;
--        lt_item_code        := gt_sales_bulk_tbl2( sale_bulk_idx ).item_code;
--        lt_prod_cls         := gt_sales_bulk_tbl2( sale_bulk_idx ).goods_prod_cls;
--
--        -- 課税の場合、消費税額を集約する
--        IF ( gt_sales_bulk_tbl2( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax := ln_tax + gt_sales_bulk_tbl2( sale_bulk_idx ).tax_amount;
--        END IF;
--
--      ELSE
--
--        IF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
--             lt_goods_prod_class := lt_prod_cls;
--             lt_goods_item_code  := lt_item_code;
--        END IF;
--        ln_max_amount       := 0;
--        ln_term_amount      := 0;
--        lt_item_code        := gt_sales_bulk_tbl2( sale_bulk_idx ).item_code;
--        lt_prod_cls         := gt_sales_bulk_tbl2( sale_bulk_idx ).goods_prod_cls;
--
--        lv_sum_flag := cv_n_flag;
--        ln_trx_idx  := sale_bulk_idx - 1;
--      END IF;
--
--      IF ( lv_sum_flag = cv_n_flag ) THEN
--
    <<gt_sales_bulk_sum_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
--
      -- ループ毎の初期化
      lv_err_flag := cv_n_flag; --エラーフラグOFF
--
      --=====================================
      --  販売実績元データの集約
      --=====================================
      IF (   gv_trx_number_brk2  = gt_sales_bulk_tbl( sale_bulk_idx ).oif_trx_number
         AND gt_header_id_brk2   = gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id
         )
      THEN
--
        -- インサート用の配列を保持
        gt_sales_bulk_tbl2( ln_trx_idx ) := gt_sales_bulk_tbl( sale_bulk_idx );
        -- 集約するフラグ初期設定
        gv_sum_flag                      := cv_y_flag;
        -- 本体金額を集約する
        gn_amount                        := gn_amount + gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
--
        --品目明細適用取得判定 ( 異なる品目区分で合計金額が最大の品目明細適用を取得 )
        IF (
             (
               (
                  NVL( gt_prod_cls_brk2, 'X' ) = cv_goods_prod_syo
               OR NVL( gt_prod_cls_brk2, 'X' ) = cv_goods_prod_sei
               )
             AND
               NVL( gt_prod_cls_brk2, 'X' ) = NVL( gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls, 'X' )
             )
           OR
             (
               (
                   NVL( gt_prod_cls_brk2, 'X' ) <> cv_goods_prod_syo
               AND NVL( gt_prod_cls_brk2, 'X' ) <> cv_goods_prod_sei
               )
               AND gt_item_code_brk2 = gt_sales_bulk_tbl( sale_bulk_idx ).item_code
             )
           )
        THEN
--
          --品目区分単位の合計を保持
          gn_term_amount := gn_term_amount + gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
--
        --前の品目区分の合計より合計金額が大きい場合
        ELSIF ( ABS( gn_term_amount ) >= ABS( gn_max_amount ) ) THEN
          gn_max_amount       := gn_term_amount;
          gn_term_amount      := gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
          gt_goods_prod_class := gt_prod_cls_brk2;
          gt_goods_item_code  := gt_item_code_brk2;
        END IF;
--
        gt_item_code_brk2  := gt_sales_bulk_tbl( sale_bulk_idx ).item_code;
        gt_prod_cls_brk2   := gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls;
--
        -- 課税の場合、消費税額を集約する
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          gn_tax := gn_tax + gt_sales_bulk_tbl( sale_bulk_idx ).tax_amount;
        END IF;
--
      ELSE
--
        IF ( ABS( gn_term_amount ) >= ABS( gn_max_amount ) ) THEN
          gt_goods_prod_class := gt_prod_cls_brk2;
          gt_goods_item_code  := gt_item_code_brk2;
        END IF;
        gn_max_amount       := 0;
/* 2009/11/05 Ver1.26 Mod Start */
--        gn_term_amount      := 0;
        gn_term_amount      := gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
/* 2009/11/05 Ver1.26 Mod End   */
        gt_item_code_brk2   := gt_sales_bulk_tbl( sale_bulk_idx ).item_code;
        gt_prod_cls_brk2    := gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls;
        gv_sum_flag         := cv_n_flag;
--
      END IF;
--
      IF ( gv_sum_flag = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Del Start */
--        --エラーフラグOFF
--        lv_err_flag := cv_n_flag;
/* 2009/10/02 Ver1.24 Del End   */
        lt_inspect_date := gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date;
/* 2009/10/27 Ver1.25 Add Start */
        lt_spot_term_id  := NULL;
        --=====================================================================
        -- ０．支払条件ID（即時）の取得
        --=====================================================================
        BEGIN
          SELECT /*+
                    INDEX(rtv0.t ra_terms_tl_n1)
                 */
                 rtv0.term_id     --即時の支払条件ID
          INTO   lt_spot_term_id
          FROM   ra_terms_vl rtv0
          WHERE  rtv0.term_id IN (
                   gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id
                  ,gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id2
                  ,gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id3
                 )
          AND    rtv0.name    = gt_spot_payment_code                                     -- 即時
          AND    lt_inspect_date  BETWEEN NVL( rtv0.start_date_active, lt_inspect_date ) -- 検収日時点で有効
                                  AND     NVL( rtv0.end_date_active  , lt_inspect_date )
          AND    ROWNUM       = 1;
--
          lv_term_chk_flag := cv_n_flag;   --即時の支払条件が存在するので支払条件IDの取得は実行しない
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_term_chk_flag := cv_y_flag; --即時の支払条件が取得できない場合、支払条件IDの取得を実行
        END;
/* 2009/10/27 Ver1.25 Add End   */
        --=====================================================================
        -- １．支払条件IDの取得
        --=====================================================================
/* 2009/10/27 Ver1.25 Add Start */
        --支払条件に即時が含まれない場合
        IF ( lv_term_chk_flag = cv_y_flag ) THEN
--
/* 2009/10/27 Ver1.25 Add End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value6  => lt_header_id
                            , iv_token_value6  => gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/27 Ver1.25 Add Start */
        --支払条件に即時が含まれる場合
        ELSE
          ln_term_id := lt_spot_term_id;
        END IF;
/* 2009/10/27 Ver1.25 Add End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value2  => lt_header_id
                            , iv_token_value2  => gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( lt_goods_prod_class IS NULL ) THEN
        IF ( gt_goods_prod_class IS NULL ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_item_idx := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--                      || lt_goods_item_code;
                      || gt_goods_item_code;
/* 2009/10/02 Ver1.24 Mod End   */
        ELSE
          lv_item_idx := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--                      || lt_goods_prod_class;
                      || gt_goods_prod_class;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--              AND  flvi.attribute2                = NVL( lt_goods_prod_class,
--                                                         lt_goods_item_code )
              AND  flvi.attribute2                = NVL( gt_goods_prod_class,
                                                         gt_goods_item_code )
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value2  => lt_header_id
                            , iv_token_value2  => gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/11/05 Ver1.26 Del Start */
--        --伝票入力者取得
--        BEGIN
--          SELECT fu.user_name
--          INTO   lv_employee_name
--          FROM   fnd_user             fu
--                ,per_all_people_f     papf
--          WHERE  fu.employee_id       = papf.person_id
--/* 2009/07/30 Ver1.21 ADD START */
--/* 2009/08/24 Ver1.23 Mod START */
----            AND  gt_sales_norm_tbl2( ln_trx_idx ).inspect_date
--            AND  gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date
--/* 2009/08/24 Ver1.23 Mod End   */
--                   BETWEEN papf.effective_start_date AND papf.effective_end_date
--/* 2009/07/30 Ver1.21 ADD End   */
--            AND  papf.employee_number = gv_busi_emp_cd;
----
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- 伝票入力者取得出来ない場合
--              lv_tbl_nm :=xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_tkn_user_msg
--                            );
--
--              lv_employee_nm :=xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_employee_code_msg
--                            );
--
--              lv_header_id_nm :=xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_header_id_msg
--                            );
--
--              lv_order_no_nm  :=xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_order_no_msg
--                            );
--
--              xxcos_common_pkg.makeup_key_info(
--                            iv_item_name1         =>  lv_employee_nm,
--                            iv_data_value1        =>  gv_busi_emp_cd,
--                            iv_item_name2         =>  lv_header_id_nm,
--/* 2009/10/02 Ver1.24 Mod Start */
----                            iv_data_value2        =>  lt_header_id,
--                            iv_data_value2        =>  gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id,
--/* 2009/10/02 Ver1.24 Mod End   */
--                            iv_item_name3         =>  lv_order_no_nm,
--                            iv_data_value3        =>  gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number,
--                            ov_key_info           =>  lv_key_info,                --編集されたキー情報
--                            ov_errbuf             =>  lv_errbuf,                  --エラーメッセージ
--                            ov_retcode            =>  lv_retcode,                 --リターンコード
--                            ov_errmsg             =>  lv_errmsg                   --ユーザ・エラー・メッセージ
--                          );
----
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_data_get_msg
--                            , iv_token_name1   => cv_tkn_tbl_nm
--                            , iv_token_value1  => lv_tbl_nm
--                            , iv_token_name2   => cv_tkn_key_data
--                            , iv_token_value2  => lv_key_info
--                          );
--              lv_errbuf  := lv_errmsg;
----
--              lv_err_flag  := cv_y_flag;
--              gn_warn_flag := cv_y_flag;
----
--              -- 空行出力
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => cv_blank
--              );
----
--              -- メッセージ出力
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => lv_errmsg
--              );
----
--              -- 空行出力
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => cv_blank
--              );
----
--               -- 空行出力
--               FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT
--                 ,buff   => cv_blank
--               );
----
--               -- メッセージ出力
--               FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT
--                 ,buff   => lv_errmsg
--               );
----
--               -- 空行出力
--               FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT
--                 ,buff   => cv_blank
--               );
----
--        END;
/* 2009/11/05 Ver1.26 Del End */
      END IF;
--
      --スキップ処理
      IF ( lv_err_flag = cv_y_flag ) THEN
         ln_skip_idx := ln_skip_idx + 1;
         gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add Start */
         gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_bulk_tbl2( ln_trx_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
      END IF;
      --==============================================================
      -- ４．AR請求取引OIFデータ作成
      --==============================================================
--
      -- -- 集約フラグ’N'の場合、AR請求取引OIFデータ作成する
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
      IF ( gv_sum_flag = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount;
        gt_ar_interface_tbl( ln_ar_idx ).amount         := gn_amount;
/* 2009/10/02 Ver1.24 Mod End   */
                                                        -- 収益行：本体金額
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --内税時、金額は本体＋税金
/* 2009/10/02 Ver1.24 Mod Start */
--          gt_ar_interface_tbl( ln_ar_idx ).amount       := ln_amount + ln_tax;
          gt_ar_interface_tbl( ln_ar_idx ).amount       := gn_amount + gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                                                        := ln_amount;
                                                        := gn_amount;
/* 2009/10/02 Ver1.24 Mod End   */
                                                        -- 収益行のみ：販売単価=本体金額
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --内税時、販売単価は本体＋税金
/* 2009/10/02 Ver1.24 Mod Start */
--          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := ln_amount + ln_tax;
          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := gn_amount + gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_bulk_tbl2( ln_trx_idx ).tax_code;
                                                        -- 税金コード(税区分)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- ヘッダーDFFカテゴリ
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
/* 2009/11/05 Ver1.26 Mod Start */
--                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).sales_base_code;
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).receiv_base_code;
/* 2009/11/05 Ver1.26 Mod End   */
                                                        -- ヘッダーdff5(起票部門)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
/* 2009/11/05 Ver1.26 Mod Start */
--                                                        := lv_employee_name;
                                                        := gv_dlv_inp_user;
/* 2009/11/05 Ver1.26 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax;
        gt_ar_interface_tbl( ln_ar_idx ).amount         := gn_tax;
/* 2009/10/02 Ver1.24 Mod Start */
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
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
--        -- 集約キーと集約金額のリセット
--        lt_trx_number      := gt_sales_bulk_tbl2( sale_bulk_idx ).oif_trx_number;        -- AR取引番号
--        lt_header_id       := gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id;   -- 販売実績ヘッダID
--
--        ln_amount := gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
--        IF ( gt_sales_bulk_tbl2( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax  := gt_sales_bulk_tbl2( sale_bulk_idx ).tax_amount;
--        ELSE
--          ln_tax  := 0;
--        END IF;
--
      IF ( gv_sum_flag = cv_n_flag ) THEN
        --現レコードをインサート用配列に設定する
        gt_sales_bulk_tbl2( ln_trx_idx ) := gt_sales_bulk_tbl( sale_bulk_idx );
        -- 集約キーと集約金額のリセット
        gv_trx_number_brk2  := gt_sales_bulk_tbl( sale_bulk_idx ).oif_trx_number;        -- AR取引番号
        gt_header_id_brk2   := gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id;   -- 販売実績ヘッダID
        gn_amount           := gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;           -- 本体金額
        --非課税の場合、消費税は0
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          gn_tax  := gt_sales_bulk_tbl( sale_bulk_idx ).tax_amount;
        ELSE
          gn_tax  := 0;
        END IF;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;
--
    END LOOP gt_sales_bulk_sum_loop;                    -- 販売実績データループ終了
--
/* 2009/10/02 Ver1.24 Add Start */
    -- 次回のBULK処理の為、ループ終了時点のインサート用変数を保持
    gt_sales_sum_tbl_brk( ln_trx_idx ) := gt_sales_bulk_tbl2( ln_trx_idx );
/* 2009/10/02 Ver1.24 Add End   */
--
/* 2009/10/02 Ver1.24 Del Start */
--    <<gt_sales_bulk_check_loop>>
--    FOR ln_ar_idx IN 1 .. gt_ar_interface_tbl.COUNT LOOP
--      -- 開始：1取引No内での出荷先顧客チェック
--
--      -- KEYが代わったら
--      IF (
--           (
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NULL )
--              AND
--              ( gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4 <> NVL( ln_key_dff4, 'X') )
--           )
--           OR
--           (
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NOT NULL )
--              AND
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number <> NVL( ln_key_trx_number, 'X') )
--           )
--         )THEN
--
--        -- 出荷先顧客フラグがONの場合
--        IF ( ln_ship_flg = cn_ship_flg_on )
--        THEN
--          <<gt_sales_bulk_ship_clear_loop>>
--          FOR start_index IN ln_start_index .. ln_ar_idx - 1 LOOP
--            -- 開始：1取引No内での出荷先顧客チェック
--
--            -- 出荷先顧客IDをクリア
--            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
--            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
--            -- 最後の行
--            IF ( gt_ar_interface_tbl.COUNT = ln_ar_idx )
--            THEN
--              -- 出荷先顧客IDをクリア
--              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id := NULL;
--              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id  := NULL;
--            END IF;
--
--            -- 終了：1取引No内での出荷先顧客チェック
--          END LOOP gt_sales_bulk_ship_clear_loop;
--        END IF;
--
--        -- 取引Noを取得
--        ln_key_trx_number := gt_ar_interface_tbl( ln_ar_idx ).trx_number;
--
--        -- DFF4を取得
--        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
--        -- 出荷先顧客IDを取得
--        ln_key_ship_customer_id := gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id;
--
--        -- 取引Noの開始位置を取得
--        ln_start_index := ln_ar_idx;
--
--        -- フラグを初期化
--        ln_ship_flg := cn_ship_flg_off;
--
--      ELSE
--        -- 出荷先顧客が同じか？
--        IF ( gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id <> ln_key_ship_customer_id ) THEN
--          -- 違う場合、出荷先顧客フラグをONにする
--          ln_ship_flg := cn_ship_flg_on;
--
--        END IF;
--        -- DFF4を取得
--        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
--        IF ( ln_ship_flg = cn_ship_flg_on AND ln_ar_idx = gt_ar_interface_tbl.COUNT ) THEN
--          <<gt_sales_bulk_ship_clear_loop>>
--          FOR start_index IN ln_start_index .. ln_ar_idx LOOP
--            -- 開始：1取引No内での出荷先顧客チェック
--
--            -- 出荷先顧客IDをクリア
--            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
--            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
--            -- 終了：1取引No内での出荷先顧客チェック
--          END LOOP gt_sales_bulk_ship_clear_loop;
--        END IF;
--
--      END IF;
--      -- 終了：1取引No内での出荷先顧客チェック
--    END LOOP gt_sales_bulk_check_loop;
/* 2009/10/02 Ver1.24 Del End   */
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
/* 2009/10/02 Ver1.24 Del Start */
--    -- 集約キー
--    lt_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE; -- 集約キー：納品伝票番号
--    lt_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;  -- 集約キー：納品伝票区分
--    lt_item_code        xxcos_sales_exp_lines.item_code%TYPE;            -- 集約キー：品目コード
--    lt_prod_cls         xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
--                                                                         -- 品目区分（製品・商品）
--    lt_gyotai_sho       xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;    -- 集約キー：業態小分類
--    lt_card_sale_class  xxcos_sales_exp_headers.card_sale_class%TYPE;    -- 集約キー：カード売り区分
--    lt_red_black_flag   xxcos_sales_exp_lines.red_black_flag%TYPE;       -- 集約キー：赤黒フラグ
--    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- 集約キー：税金コード
--    lt_header_id        xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- 集約キー：販売実績ヘッダID
--    ln_amount           NUMBER DEFAULT 0;                                -- 集約後金額
--    ln_tax              NUMBER DEFAULT 0;                                -- 集約後消費税金額
/* 2009/10/02 Ver1.24 Del End   */
    ln_ar_dis_idx       NUMBER DEFAULT 0;                                -- AR会計配分集約インデックス
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR会計配分OIFインデックス
    ln_dis_idx          NUMBER DEFAULT 1;                                -- AR会計配分OIFインデックス
/* 2009/10/02 Ver1.24 Mod End   */
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- 仕訳生成カウント
    lv_rec_flag         VARCHAR2(1);                                     -- RECフラグ
/* 2009/10/02 Ver1.24 Del Start */
--    -- AR取引番号
--    lt_trx_number       VARCHAR2(20);
/* 2009/10/02 Ver1.24 Del End   */
    lv_err_flag         VARCHAR2(1);                                     -- エラー用フラグ
    lv_jour_flag        VARCHAR2(1);                                     -- エラー用フラグ
    ln_skip_idx         NUMBER DEFAULT 0;                                -- スキップ用インデックス;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
/* 2009/10/02 Ver1.24 Del Start */
--    non_jour_cls_expt         EXCEPTION;                -- 仕訳パターンなし
/* 2009/10/02 Ver1.24 Del End   */
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
/* 2009/10/02 Ver1.24 Del Start */
--    -- 請求取引テーブルの非大手量販店データカウントセット
--    ln_ar_dis_idx := gt_ar_dis_tbl.COUNT;
--
--    --=====================================
--    -- 1.AR会計配分仕訳パターンの取得
--    --=====================================
--
--    -- カーソルオープン
--    BEGIN
--      OPEN  jour_cls_cur;
--      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
--    EXCEPTION
--    -- 仕訳パターン取得失敗した場合
--      WHEN OTHERS THEN
--        lv_errmsg    := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_xxcos_short_nm
--                         , iv_name         => cv_jour_nodata_msg
--                         , iv_token_name1  => cv_tkn_lookup_type
--                         , iv_token_value1 => cv_qct_jour_cls
--                       );
--        lv_errbuf := lv_errmsg;
--        RAISE non_jour_cls_expt;
--    END;
--    -- 仕訳パターン取得失敗した場合
--    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
--      lv_errmsg    := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_xxcos_short_nm
--                       , iv_name         => cv_jour_nodata_msg
--                       , iv_token_name1  => cv_tkn_lookup_type
--                       , iv_token_value1 => cv_qct_jour_cls
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE non_jour_cls_expt;
--    END IF;
--
--    -- カーソルクローズ
--    CLOSE jour_cls_cur;
/* 2009/10/02 Ver1.24 Del End   */
--
    --スキップカウントセット
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
    --=====================================
    -- 3.AR会計配分データ作成
    --=====================================
/* 2009/10/02 Ver1.24 Mod Start */
--    -- 集約キーの値セット
--    lt_invoice_number   := gt_sales_bulk_tbl2( 1 ).dlv_invoice_number;
--    lt_item_code        := gt_sales_bulk_tbl2( 1 ).item_code;
--    lt_prod_cls         := gt_sales_bulk_tbl2( 1 ).goods_prod_cls;
--    lt_gyotai_sho       := gt_sales_bulk_tbl2( 1 ).cust_gyotai_sho;
--    lt_card_sale_class  := gt_sales_bulk_tbl2( 1 ).card_sale_class;
--    lt_tax_code         := gt_sales_bulk_tbl2( 1 ).tax_code;
--    lt_invoice_class    := gt_sales_bulk_tbl2( 1 ).dlv_invoice_class;
--    lt_red_black_flag   := gt_sales_bulk_tbl2( 1 ).red_black_flag;
--    lt_header_id        := gt_sales_bulk_tbl2( 1 ).sales_exp_header_id;
--
--    -- ラストデータ登録為に、ダミーデータをセットする
--    gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT + 1 ).sales_exp_header_id
--                        := gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT ).sales_exp_header_id;
--
    -- 最初のBUKL処理の場合
    IF ( gn_fetch_first_flag = 0 ) THEN
      -- 集約キーの値セット
      gt_invoice_number_ar_brk   := gt_sales_bulk_tbl( 1 ).dlv_invoice_number;
      gt_item_code_ar_brk        := gt_sales_bulk_tbl( 1 ).item_code;
      gt_prod_cls_ar_brk         := gt_sales_bulk_tbl( 1 ).goods_prod_cls;
      gt_gyotai_sho_ar_brk       := gt_sales_bulk_tbl( 1 ).cust_gyotai_sho;
      gt_card_sale_class_ar_brk  := gt_sales_bulk_tbl( 1 ).card_sale_class;
      gt_tax_code_ar_brk         := gt_sales_bulk_tbl( 1 ).tax_code;
      gt_invoice_class_ar_brk    := gt_sales_bulk_tbl( 1 ).dlv_invoice_class;
      gt_red_black_flag_ar_brk   := gt_sales_bulk_tbl( 1 ).red_black_flag;
      gt_header_id_ar_brk        := gt_sales_bulk_tbl( 1 ).sales_exp_header_id;
    END IF;
    -- 2回目以降のBUKL処理の場合、保持していた前レコードをインサート用変数に移す
    IF ( gt_sales_dis_tbl_brk.COUNT <> 0 ) THEN
      gt_sales_bulk_tbl2( ln_dis_idx ) := gt_sales_dis_tbl_brk( ln_dis_idx );
    END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_bulk_tbl2_loop>>
--    FOR dis_sum_idx IN 1 .. gt_sales_bulk_tbl2.COUNT LOOP
--
--      -- AR会計配分データ集約開始
--      IF ( lt_invoice_number = gt_sales_bulk_tbl2( dis_sum_idx ).dlv_invoice_number
--        AND
--          (
--            (
--              (
--                 NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
--              OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
--              )
--            AND
--              NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_bulk_tbl2( dis_sum_idx ).goods_prod_cls, 'X' )
--            )
--          OR
--            (
--              (
--                  NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
--              AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
--              )
--              AND lt_item_code = gt_sales_bulk_tbl2( dis_sum_idx ).item_code
--            )
--          )
--        AND lt_gyotai_sho      = gt_sales_bulk_tbl2( dis_sum_idx ).cust_gyotai_sho
--        AND lt_card_sale_class = gt_sales_bulk_tbl2( dis_sum_idx ).card_sale_class
--        AND lt_tax_code        = gt_sales_bulk_tbl2( dis_sum_idx ).tax_code
--        AND lt_header_id       = gt_sales_bulk_tbl2( dis_sum_idx ).sales_exp_header_id
--        )
--      THEN
--
--        -- 集約するフラグ初期設定
--        lv_sum_flag := cv_y_flag;
--
--        -- 本体金額と消費税額を集約する
--        ln_amount := ln_amount + gt_sales_bulk_tbl2( dis_sum_idx ).pure_amount;
--        ln_tax    := ln_tax    + gt_sales_bulk_tbl2( dis_sum_idx ).tax_amount;
--      ELSE
--        lv_sum_flag := cv_n_flag;
--        ln_dis_idx  := dis_sum_idx - 1;
--      END IF;
--
--
    <<gt_sales_bulk_tbl_loop>>
    FOR dis_sum_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
--
      -- AR会計配分データ集約開始
      IF ( gt_invoice_number_ar_brk = gt_sales_bulk_tbl( dis_sum_idx ).dlv_invoice_number
        AND
          (
            (
              (
                 NVL( gt_prod_cls_ar_brk, 'X' ) = cv_goods_prod_syo
              OR NVL( gt_prod_cls_ar_brk, 'X' ) = cv_goods_prod_sei
              )
            AND
              NVL( gt_prod_cls_ar_brk, 'X' ) = NVL( gt_sales_bulk_tbl( dis_sum_idx ).goods_prod_cls, 'X' )
            )
          OR
            (
              (
                  NVL( gt_prod_cls_ar_brk, 'X' ) <> cv_goods_prod_syo
              AND NVL( gt_prod_cls_ar_brk, 'X' ) <> cv_goods_prod_sei
              )
              AND gt_item_code_ar_brk = gt_sales_bulk_tbl( dis_sum_idx ).item_code
            )
          )
        AND gt_gyotai_sho_ar_brk      = gt_sales_bulk_tbl( dis_sum_idx ).cust_gyotai_sho
        AND gt_card_sale_class_ar_brk = gt_sales_bulk_tbl( dis_sum_idx ).card_sale_class
        AND gt_tax_code_ar_brk        = gt_sales_bulk_tbl( dis_sum_idx ).tax_code
        AND gt_header_id_ar_brk       = gt_sales_bulk_tbl( dis_sum_idx ).sales_exp_header_id
        )
      THEN
--
        -- インサート用の配列を保持
        gt_sales_bulk_tbl2( ln_dis_idx ) := gt_sales_bulk_tbl( dis_sum_idx );
        -- 集約するフラグ初期設定
        gv_sum_flag_ar                   := cv_y_flag;
        -- 本体金額と消費税額を集約する
        gn_amount_ar                     := gn_amount_ar + gt_sales_bulk_tbl( dis_sum_idx ).pure_amount;
        gn_tax_ar                        := gn_tax_ar    + gt_sales_bulk_tbl( dis_sum_idx ).tax_amount;
--
      ELSE
--
        gv_sum_flag_ar := cv_n_flag;
--
      END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
      -- -- 集約フラグ’N'の場合、下記AR会計配分OIF作成処理を行う
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
      IF ( gv_sum_flag_ar = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( NVL( lt_trx_number, 'X' ) <> gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number ) THEN
        IF ( NVL( gv_trx_number_ar_brk, 'X' ) <> gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_rec_flag := cv_y_flag;
        ELSE
          lv_rec_flag := cv_n_flag;
        END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--        lt_trx_number      := gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number;        -- AR取引番号
        gv_trx_number_ar_brk  := gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number;        -- AR取引番号
/* 2009/10/02 Ver1.24 Mod End   */
--
        -- 仕訳生成カウント初期値
        ln_jour_cnt := 1;
        lv_jour_flag := cv_n_flag;
--
        -- 仕訳パターンよりAR会計配分の仕訳を編集する
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
/* 2009/10/02 Ver1.24 Mod Start */
--          IF (  gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = lt_invoice_class
--            AND (  gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = lt_item_code
--              OR ( gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> lt_item_code
--                AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls = lt_prod_cls ) )
--            AND ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = lt_gyotai_sho
--              OR  gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL )
--            AND ( gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = lt_card_sale_class
--              OR  gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL )
--            AND ( gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
--              OR  gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL )
--            ) THEN
--
          IF (   gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = gt_invoice_class_ar_brk
             AND (
                    gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = gt_item_code_ar_brk
                 OR
                   (   gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> gt_item_code_ar_brk
                   AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls   = gt_prod_cls_ar_brk )
                   )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_gyotai_sho_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = gt_card_sale_class_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).red_black_flag  = gt_red_black_flag_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL
                 )
             )
          THEN
/* 2009/10/02 Ver1.24 Mod End */
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
/* 2009/08/28 Ver1.23 Mod Start */
--                             gd_process_date
                             gt_sales_bulk_tbl2( ln_dis_idx ).inspect_date
/* 2009/08/28 Ver1.23 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--                                , iv_token_value9      => lt_header_id
--                                , iv_token_name10      => cv_tkn_order_no
--                                , iv_token_value10     => lt_invoice_number
                                , iv_token_value9      => gt_header_id_ar_brk
                                , iv_token_name10      => cv_tkn_order_no
                                , iv_token_value10     => gt_invoice_number_ar_brk
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/08/28 Ver1.23 Add Start */
              ELSE
                -- 共通関数から取得できた場合、取得したCCIDをワークテーブルに設定する
                gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
/* 2009/08/28 Ver1.23 Add End   */
              END IF;
--
              --スキップ処理
              IF ( lv_err_flag = cv_y_flag ) THEN
                 ln_skip_idx := ln_skip_idx + 1;
                 gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add Start */
                 gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_bulk_tbl2( ln_dis_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
              END IF;
/* 2009/08/28 Ver1.23 Del Start */
--              -- 取得したCCIDをワークテーブルに設定する
--              gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
/* 2009/08/28 Ver1.23 Del End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_amount;
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := gn_amount_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- 金額(明細金額)
              IF ( gt_sales_bulk_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --内税時、金額は本体＋税金
/* 2009/10/02 Ver1.24 Mod Start */
--                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := ln_amount + ln_tax;
                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := gn_amount_ar + gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
              END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_amount;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := gn_amount_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- パーセント(割合)
              IF ( gt_sales_bulk_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --内税時、パーセント(割合)は本体＋税金
/* 2009/10/02 Ver1.24 Mod Start */
--                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := ln_amount + ln_tax;
                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := gn_amount_ar + gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_tax;
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- 金額(明細金額)
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_tax;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( ln_jour_cnt = 1 AND dis_sum_idx <> gt_sales_bulk_tbl2.COUNT ) THEN
        --仕訳が１件もない場合エラー
        IF ( ln_jour_cnt = 1  ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application       => cv_xxcos_short_nm
                          , iv_name              => cv_jour_no_msg
                          , iv_token_name1       => cv_tkn_invoice_cls
/* 2009/10/02 Ver1.24 Mod Start */
--                          , iv_token_value1      => lt_invoice_class
--                          , iv_token_name2       => cv_tkn_prod_cls
--                          , iv_token_value2      => NVL( lt_prod_cls, lt_item_code )
--                          , iv_token_name3       => cv_tkn_gyotai_sho
--                          , iv_token_value3      => lt_gyotai_sho
--                          , iv_token_name4       => cv_tkn_sale_cls
--                          , iv_token_value4      => lt_card_sale_class
--                          , iv_token_name5       => cv_tkn_red_black_flag
--                          , iv_token_value5      => lt_red_black_flag
--                          , iv_token_name6       => cv_tkn_header_id
--                          , iv_token_value6      => lt_header_id
--                          , iv_token_name7       => cv_tkn_order_no
--                          , iv_token_value7      => lt_invoice_number
--
                          , iv_token_value1      => gt_invoice_class_ar_brk
                          , iv_token_name2       => cv_tkn_prod_cls
                          , iv_token_value2      => NVL( gt_prod_cls_ar_brk, gt_item_code_ar_brk )
                          , iv_token_name3       => cv_tkn_gyotai_sho
                          , iv_token_value3      => gt_gyotai_sho_ar_brk
                          , iv_token_name4       => cv_tkn_sale_cls
                          , iv_token_value4      => gt_card_sale_class_ar_brk
                          , iv_token_name5       => cv_tkn_red_black_flag
                          , iv_token_value5      => gt_red_black_flag_ar_brk
                          , iv_token_name6       => cv_tkn_header_id
                          , iv_token_value6      => gt_header_id_ar_brk
                          , iv_token_name7       => cv_tkn_order_no
                          , iv_token_value7      => gt_invoice_number_ar_brk
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Add Start */
             gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_bulk_tbl2( ln_dis_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
          END IF;
        END IF;
--
/* 2009/10/02 Ver1.24 Mod Start */
--        -- 金額の設定
--        ln_amount        := gt_sales_bulk_tbl2( dis_sum_idx ).pure_amount;
--        ln_tax           := gt_sales_bulk_tbl2( dis_sum_idx ).tax_amount;
        -- 金額の設定
        gn_amount_ar   := gt_sales_bulk_tbl( dis_sum_idx ).pure_amount;
        gn_tax_ar      := gt_sales_bulk_tbl( dis_sum_idx ).tax_amount;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;                                             -- 集約キー毎にAR会計配分OIFデータの集約終了
--
/* 2009/10/02 Ver1.24 Add Start */
      --現レコードをインサート用配列に設定する
      gt_sales_bulk_tbl2( ln_dis_idx ) := gt_sales_bulk_tbl( dis_sum_idx );
      -- 集約キーのリセット
      gt_invoice_number_ar_brk   := gt_sales_bulk_tbl( dis_sum_idx ).dlv_invoice_number;
      gt_item_code_ar_brk        := gt_sales_bulk_tbl( dis_sum_idx ).item_code;
      gt_prod_cls_ar_brk         := gt_sales_bulk_tbl( dis_sum_idx ).goods_prod_cls;
      gt_gyotai_sho_ar_brk       := gt_sales_bulk_tbl( dis_sum_idx ).cust_gyotai_sho;
      gt_card_sale_class_ar_brk  := gt_sales_bulk_tbl( dis_sum_idx ).card_sale_class;
      gt_tax_code_ar_brk         := gt_sales_bulk_tbl( dis_sum_idx ).tax_code;
      gt_invoice_class_ar_brk    := gt_sales_bulk_tbl( dis_sum_idx ).dlv_invoice_class;
      gt_red_black_flag_ar_brk   := gt_sales_bulk_tbl( dis_sum_idx ).red_black_flag;
      gt_header_id_ar_brk        := gt_sales_bulk_tbl( dis_sum_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add End  */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    END LOOP gt_sales_bulk_tbl2_loop;                      -- AR会計配分集約データループ終了
    END LOOP gt_sales_bulk_tbl_loop;                      -- AR会計配分集約データループ終了
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Add Start */
    -- 次回のBULK処理の為、ループ終了時点のインサート用変数を保持
    gt_sales_dis_tbl_brk( ln_dis_idx ) := gt_sales_bulk_tbl2( ln_dis_idx );
--
/* 2009/10/02 Ver1.24 Add End   */
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
/* 2009/10/02 Ver1.24 Del Start */
--    WHEN non_jour_cls_expt THEN
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
/* 2009/10/02 Ver1.24 Del End   */
--
    WHEN non_ccid_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- カーソルクローズ
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--     END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- カーソルクローズ
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- カーソルクローズ
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
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
/* 2009/10/02 Ver1.24 Add Start */
    iv_target         IN  VARCHAR2,         --   処理対象区分
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
    --出荷先顧客チェック用
    ln_start_index        NUMBER DEFAULT 1;
    --インサート処理用
    ln_start              NUMBER;               -- 開始位置
    ln_end                NUMBER;               -- 終了位置
    ln_run_flag           NUMBER;               -- 処理継続フラグ(0:継続、1:終了)
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
    --初期化
    gt_ar_interface_tbl.DELETE; --AR請求取引OIF用配列(警告データ込み)
--
/* 2009/10/02 Ver1.24 Add End   */
--
    IF ( gt_ar_interface_tbl1.COUNT > 0 ) THEN
--
/* 2009/10/02 Ver1.24 Add Start */
--
      --大手処理のみ出荷先顧客のチェック
      IF ( iv_target = cv_major ) THEN
--
        <<gt_ship_check_loop>>
        FOR ln_ar_idx IN 1 .. gt_ar_interface_tbl1.COUNT LOOP
--
          -- 取引番号が変わったら
          IF (
               (
                  ( gt_ar_interface_tbl1( ln_ar_idx ).trx_number IS NULL )
                  AND
                  ( gt_ar_interface_tbl1( ln_ar_idx ).link_to_line_attribute4 <> NVL( gn_key_dff4, 'X') )
               )
             OR
               (
                  ( gt_ar_interface_tbl1( ln_ar_idx ).trx_number IS NOT NULL )
                  AND
                  ( gt_ar_interface_tbl1( ln_ar_idx ).trx_number <> NVL( gn_key_trx_number, 'X') )
               )
             )
          THEN
--
            -- 出荷先顧客フラグがONの場合
            IF ( gn_ship_flg = cn_ship_flg_on ) THEN
--
              -- 同一の取引番号の出荷先顧客情報をクリア
              <<gt_ship_clear_loop>>
              FOR start_index IN ln_start_index .. ln_ar_idx - 1 LOOP
--
                -- 出荷先顧客ID・住所IDをクリア
                gt_ar_interface_tbl1( start_index ).orig_system_ship_customer_id := NULL;
                gt_ar_interface_tbl1( start_index ).orig_system_ship_address_id  := NULL;
--
              END LOOP gt_ship_clear_loop;
--
              -- 最終行の判定(最終行の取引番号が異なる場合)
              IF ( gt_ar_interface_tbl1.COUNT = ln_ar_idx ) THEN
                -- 出荷先顧客ID・住所IDをクリア
                gt_ar_interface_tbl1( ln_ar_idx ).orig_system_ship_customer_id := NULL;
                gt_ar_interface_tbl1( ln_ar_idx ).orig_system_ship_address_id  := NULL;
              END IF;
--
              -- 既にOIFに書き込まれているデータの更新
              -- 収益行
              UPDATE  ra_interface_lines_all rila
              SET     rila.orig_system_ship_customer_id = NULL -- 出荷先顧客ID
                     ,rila.orig_system_ship_address_id  = NULL -- 出荷先顧客住所ID
              WHERE   rila.trx_number = gn_key_trx_number
              ;
              -- 税金行
              UPDATE  ra_interface_lines_all rila
              SET     rila.orig_system_ship_customer_id = NULL -- 出荷先顧客ID
                     ,rila.orig_system_ship_address_id  = NULL -- 出荷先顧客住所ID
              WHERE   rila.link_to_line_attribute4 IN (
                        SELECT rilas.interface_line_attribute4 interface_line_attribute4
                        FROM   ra_interface_lines_all rilas
                        WHERE  rilas.trx_number = gn_key_trx_number )
              ;
--
            END IF;
--
            --初期化
            gn_ship_flg             := cn_ship_flg_off;                                                -- フラグを初期化
            gn_key_trx_number       := gt_ar_interface_tbl1( ln_ar_idx ).trx_number;                   -- 取引Noを取得
            gn_key_dff4             := gt_ar_interface_tbl1( ln_ar_idx ).interface_line_attribute4;    -- 取引明細DFF4を取得
            gn_key_ship_customer_id := gt_ar_interface_tbl1( ln_ar_idx ).orig_system_ship_customer_id; -- 出荷先顧客IDを取得
            ln_start_index          := ln_ar_idx;                                                      -- 取引Noの開始位置を取得
--
          ELSE
--
            -- 出荷先顧客の差異チェック
            IF ( gt_ar_interface_tbl1( ln_ar_idx ).orig_system_ship_customer_id <> gn_key_ship_customer_id ) THEN
              -- 出荷先顧客フラグをONにする
              gn_ship_flg := cn_ship_flg_on;
            END IF;
--
            -- 取引明細DFF4のみ取得(税金行に取引番号が無い為)
            gn_key_dff4 := gt_ar_interface_tbl1( ln_ar_idx ).interface_line_attribute4;
--
            -- 最終行の判定(最終行の取引番号が同じ場合)
            IF ( gn_ship_flg = cn_ship_flg_on AND ln_ar_idx = gt_ar_interface_tbl1.COUNT ) THEN
--
              -- 同一の取引番号の出荷先顧客情報をクリア
              <<gt_ship_clear_loop>>
              FOR start_index IN ln_start_index .. ln_ar_idx LOOP
--
                -- 出荷先顧客ID・住所IDをクリア
                gt_ar_interface_tbl1( start_index ).orig_system_ship_customer_id := NULL;
                gt_ar_interface_tbl1( start_index ).orig_system_ship_address_id  := NULL;
--
              END LOOP gt_ship_clear_loop;
--
              -- 既にOIFに書き込まれているデータの更新
              -- 収益行
              UPDATE  ra_interface_lines_all rila
              SET     rila.orig_system_ship_customer_id = NULL -- 出荷先顧客ID
                     ,rila.orig_system_ship_address_id  = NULL -- 出荷先顧客住所ID
              WHERE   rila.trx_number = gn_key_trx_number
              ;
              -- 税金行
              UPDATE  ra_interface_lines_all rila
              SET     rila.orig_system_ship_customer_id = NULL -- 出荷先顧客ID
                     ,rila.orig_system_ship_address_id  = NULL -- 出荷先顧客住所ID
              WHERE   rila.link_to_line_attribute4 IN (
                        SELECT rilas.interface_line_attribute4 interface_line_attribute4
                        FROM   ra_interface_lines_all rilas
                        WHERE  rilas.trx_number = gn_key_trx_number )
              ;
--
            END IF;
--
          END IF;
--
        END LOOP gt_ship_check_loop;
--
      END IF;
/* 2009/10/02 Ver1.24 Add End   */
--
      BEGIN
/* 2009/10/02 Ver1.24 Mod Start */
--        FORALL i IN 1..gt_ar_interface_tbl1.COUNT
--          INSERT INTO
--            ra_interface_lines_all
--          VALUES
--            gt_ar_interface_tbl1(i)
--         ;
--
        -- 初期値設定
        ln_start    := 1;
        ln_end      := gn_if_bulk_collect_cnt;   --BUKL(if)処理件数
        ln_run_flag := 0;
--
        -- 対象データがBUKL処理件数より小さい場合
        IF ( gn_if_bulk_collect_cnt > gt_ar_interface_tbl1.COUNT ) THEN
          ln_end      := gt_ar_interface_tbl1.COUNT; --配列の件数
          ln_run_flag := 1;                          --最終の処理
        END IF;
--
        <<bulk_loop>>
        LOOP
          FORALL i IN ln_start..ln_end
            INSERT INTO
              ra_interface_lines_all
            VALUES
              gt_ar_interface_tbl1(i)
            ;
--
          -- 処理を継続するかチェック
          EXIT WHEN ln_run_flag = 1;
--
          -- 次の対象データの配列位置を設定
          ln_start := ln_end + 1;
          -- 最終 + BULK処理件数よりも配列の件数が多い場合
          IF ( ln_end + gn_if_bulk_collect_cnt < gt_ar_interface_tbl1.COUNT ) THEN
            ln_end := ln_end + gn_if_bulk_collect_cnt;
          ELSE
            ln_end      := gt_ar_interface_tbl1.COUNT; -- 配列の件数
            ln_run_flag := 1;                          -- 最終の処理
          END IF;
        END LOOP bulk_loop;
--
/* 2009/10/02 Ver1.24 Mod End   */
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_insert_data_expt;
      END;
    END IF;
--
/* 2009/10/02 Ver1.24 Add Start */
    --処理件数取得
    gn_aroif_cnt_tmp := gn_aroif_cnt_tmp + gt_ar_interface_tbl1.COUNT;
/* 2009/10/02 Ver1.24 Add Start */
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
/* 2009/10/02 Ver1.24 Add Start */
    ln_start      NUMBER;                       -- 開始位置
    ln_end        NUMBER;                       -- 終了位置
    ln_run_flag   NUMBER;                       -- 処理継続フラグ(0:継続、1:終了)
/* 2009/10/02 Ver1.24 Add End */
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
/* 2009/10/02 Ver1.24 Add Start */
    --初期化
    gt_ar_dis_tbl.DELETE;  --  AR会計配分OIF用配列(警告データ込み)
/* 2009/10/02 Ver1.24 Add End   */
    IF ( gt_ar_dis_tbl1.COUNT > 0 ) THEN 
      BEGIN
/* 2009/10/02 Ver1.24 Mod Start */
--        FORALL i IN 1..gt_ar_dis_tbl1.COUNT
--          INSERT INTO
--            ra_interface_distributions_all
--          VALUES
--            gt_ar_dis_tbl1(i)
--          ;
--
        -- 初期値設定
        ln_start    := 1;
        ln_end      := gn_if_bulk_collect_cnt;   --BUKL(if)処理件数
        ln_run_flag := 0;
--
        -- 対象データがBUKL処理件数より小さい場合
        IF ( gn_if_bulk_collect_cnt > gt_ar_dis_tbl1.COUNT ) THEN
          ln_end      := gt_ar_dis_tbl1.COUNT; --配列の件数
          ln_run_flag := 1;                    --最終の処理
        END IF;
--
        <<bulk_loop>>
        LOOP
          FORALL i IN ln_start..ln_end
            INSERT INTO
              ra_interface_distributions_all
            VALUES
              gt_ar_dis_tbl1(i)
            ;
--
          -- 処理を継続するかチェック
          EXIT WHEN ln_run_flag = 1;
--
          -- 次の対象データの配列位置を設定
          ln_start := ln_end + 1;
          -- 最終 + BULK処理件数よりも配列の件数が多い場合
          IF ( ln_end + gn_if_bulk_collect_cnt < gt_ar_dis_tbl1.COUNT ) THEN
            ln_end := ln_end + gn_if_bulk_collect_cnt;
          ELSE
            -- 対象データが10000件以下の場合
            ln_end      := gt_ar_dis_tbl1.COUNT;  --配列の件数
            ln_run_flag := 1;                     --最終の処理
          END IF;
        END LOOP bulk_loop;
--
/* 2009/10/02 Ver1.24 Mod End   */
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_insert_data_expt;
      END;
    END IF;
--
/* 2009/10/02 Ver1.24 Add Start */
    --処理件数取得
    gn_ardis_cnt_tmp := gn_ardis_cnt_tmp + gt_ar_dis_tbl1.COUNT;
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--    ov_errbuf         OUT VARCHAR2,         -- エラー・メッセージ           --# 固定 #
--    ov_retcode        OUT VARCHAR2,         -- リターン・コード             --# 固定 #
--    ov_errmsg         OUT VARCHAR2 )        -- ユーザー・エラー・メッセージ --# 固定 #
      iv_target       IN  VARCHAR2    -- 処理対象区分
    , iv_create_class IN  VARCHAR2    -- 作成元区分
    , ov_errbuf       OUT VARCHAR2    -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2    -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2 )  -- ユーザー・エラー・メッセージ --# 固定 #
/* 2009/10/02 Ver1.24 Mod End   */
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
    lv_tbl_nm           VARCHAR2(255);          -- テーブル名
    lv_skip_flag        VARCHAR2(1);            -- フラグ
    ln_sales_h_tbl_idx  NUMBER DEFAULT 0;       -- 販売実績ヘッダ更新用インデックス
/* 2009/10/02 Ver1.24 Add Start */
    ln_start            NUMBER;                 -- 開始位置
    ln_end              NUMBER;                 -- 終了位置
    ln_run_flag         NUMBER;                 -- 処理継続フラグ(0:継続、1:終了)
    lv_table_name       VARCHAR2(255);          -- テーブル名
/* 2009/10/02 Ver1.24 Add End   */
--
    -- *** ローカル・カーソル ***
    CURSOR no_target_cur
    IS
/* 2009/11/05 Ver1.26 Mod Start */
--      SELECT xseh.rowid  xseh_rowid
      SELECT /*+
               INDEX(xseh xxcos_sales_exp_headers_n02)
             */
             xseh.rowid  xseh_rowid
/* 2009/11/05 Ver1.26 Mod End   */
      FROM   xxcos_sales_exp_headers xseh
      WHERE  xseh.ar_interface_flag   = cv_n_flag          -- 全処理終了後Nで残っているもの
      AND    xseh.delivery_date      <= gd_process_date    -- 納品日 <= 業務日付
/* 2009/11/05 Ver1.26 Del Start */
--      AND    xseh.create_class        = iv_create_class    -- パラメータ.作成元区分
/* 2009/11/05 Ver1.26 Del End   */
      AND    (
               ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
               OR
               (
                 ( iv_target = cv_not_major )
                 AND
                 (
                   ( xseh.receiv_base_code <> gv_busi_dept_cd )
                   OR
                   ( xseh.receiv_base_code IS NULL )
                 )
               )
             )                                             -- パラメータ.処理対象区分 1:大手 2:非大手
/* 2009/11/05 Ver1.26 Add Start */
      AND    EXISTS (
             SELECT
                 'X'
             FROM
                 fnd_lookup_values   flvl
             WHERE
                 flvl.lookup_type       = cv_qct_mkorg_cls
             AND flvl.lookup_code       LIKE cv_qcc_code
             AND flvl.attribute3        = iv_create_class    -- パラレル処理区分が引数と同じ
             AND flvl.enabled_flag      = cv_enabled_yes
             AND flvl.language          = ct_lang
             AND gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                 AND     NVL( flvl.end_date_active,   gd_process_date )
             AND flvl.meaning           = xseh.create_class
             )
/* 2009/11/05 Ver1.26 Add End   */
      FOR UPDATE OF
             xseh.sales_exp_header_id
      NOWAIT
      ;
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
    -- 販売実績ヘッダ更新処理(正常終了)
    --==============================================================
--
/* 2009/10/02 Ver1.24 Mod Start */
--      FOR sale_idx IN 1 .. gt_sales_exp_tbl2.COUNT LOOP
    FOR sale_idx IN 1 .. gt_sales_target_tbl.COUNT LOOP
/* 2009/10/02 Ver1.24 Mod End   */
--
      lv_skip_flag := cv_n_flag;
      IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
        <<gt_sales_skip_tbl_loop>>
        FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
          IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                  = gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id ) THEN
              = gt_sales_target_tbl( sale_idx ).sales_exp_header_id ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
            lv_skip_flag := cv_y_flag;
            EXIT;
          END IF;
        END LOOP gt_sales_skip_tbl_loop;
      END IF;
--
      IF ( lv_skip_flag = cv_n_flag ) THEN
        ln_sales_h_tbl_idx := ln_sales_h_tbl_idx + 1;
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_sales_h_tbl( ln_sales_h_tbl_idx )                  := gt_sales_exp_tbl2( sale_idx ).xseh_rowid;
        gt_sales_h_tbl( ln_sales_h_tbl_idx )  := gt_sales_target_tbl( sale_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;
    END LOOP gt_sales_exp_tbl2_loop;                                  -- 販売実績データループ終了
--
    -- 処理対象データのインタフェース済フラグを一括更新する
    BEGIN
/* 2009/10/02 Ver1.24 Mod Start */
--      <<update_interface_flag>>
--      FORALL i IN gt_sales_h_tbl.FIRST..gt_sales_h_tbl.LAST
--        UPDATE
--          xxcos_sales_exp_headers       xseh
--        SET
--          xseh.ar_interface_flag      = cv_y_flag,                     -- ARインタフェース済フラグ
--          xseh.last_updated_by        = cn_last_updated_by,            -- 最終更新者
--          xseh.last_update_date       = cd_last_update_date,           -- 最終更新日
--          xseh.last_update_login      = cn_last_update_login,          -- 最終更新ログイン
--          xseh.request_id             = cn_request_id,                 -- 要求ID
--          xseh.program_application_id = cn_program_application_id,     -- コンカレント・プログラム・アプリID
--          xseh.program_id             = cn_program_id,                 -- コンカレント・プログラムID
--          xseh.program_update_date    = cd_program_update_date         -- プログラム更新日
--        WHERE
--          xseh.rowid                  = gt_sales_h_tbl( i );           -- 販売実績ROWID
--
      -- 初期値設定
      ln_start    := 1;
      ln_end      := gn_ar_bulk_collect_cnt; --BUKL処理件数
      ln_run_flag := 0;
--
      -- 対象データがBUKL処理件数より小さい場合
      IF ( gn_ar_bulk_collect_cnt > gt_sales_h_tbl.COUNT ) THEN
        ln_end      := gt_sales_h_tbl.COUNT; --配列の件数
        ln_run_flag := 1;                    --最終の処理
      END IF;
      --
      <<n_update_loop>>
      LOOP
        FORALL i IN ln_start..ln_end
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
        -- 処理を継続するかチェック
        EXIT WHEN  ln_run_flag = 1;
--
        -- 次の対象データの配列位置を設定
        ln_start := ln_end + 1;
        -- 最終 + BULK処理件数よりも配列の件数が多い場合
        IF ( ln_end + gn_ar_bulk_collect_cnt < gt_sales_h_tbl.COUNT ) THEN
          ln_end := ln_end + gn_ar_bulk_collect_cnt;
        ELSE
          ln_end      := gt_sales_h_tbl.COUNT; -- 配列の件数
          ln_run_flag := 1;                    -- 最終の処理
        END IF;
--
      END LOOP n_update_loop;  --正常データ更新ループ完了
--
      -- 初期化
      gt_sales_h_tbl.DELETE;
      ln_start            := 1;
      ln_end              := gn_ar_bulk_collect_cnt; --BUKL処理件数
      ln_run_flag         := 0;
      ln_sales_h_tbl_idx  := 0;
--
      --==============================================================
      -- 販売実績ヘッダ更新処理(警告終了)
      --==============================================================
      FOR sale_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
        ln_sales_h_tbl_idx := ln_sales_h_tbl_idx + 1;
        gt_sales_h_tbl( ln_sales_h_tbl_idx ) := gt_sales_skip_tbl( sale_idx ).xseh_rowid; --ROWIDセット
      END LOOP;
--
      -- 対象データがBUKL処理件数より小さい場合
      IF ( gn_ar_bulk_collect_cnt > gt_sales_h_tbl.COUNT ) THEN
        ln_end      := gt_sales_h_tbl.COUNT; --配列の件数
        ln_run_flag := 1;                    --最終の処理
      END IF;
      --
      <<w_update_loop>>
      LOOP
        FORALL i IN ln_start..ln_end
          UPDATE
            xxcos_sales_exp_headers       xseh
          SET
            xseh.ar_interface_flag      = cv_w_flag,                     -- ARインタフェーススキップ
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
        -- 処理を継続するかチェック
        EXIT WHEN  ln_run_flag = 1;
--
        -- 次の対象データの配列位置を設定
        ln_start := ln_end + 1;
        -- 最終 + BULK処理件数よりも配列の件数が多い場合
        IF ( ln_end + gn_ar_bulk_collect_cnt < gt_sales_h_tbl.COUNT ) THEN
          ln_end := ln_end + gn_ar_bulk_collect_cnt;
        ELSE
          ln_end      := gt_sales_h_tbl.COUNT; -- 配列の件数
          ln_run_flag := 1;                    -- 最終の処理
        END IF;
--
      END LOOP w_update_loop;  --警告データ更新ループ完了
--
      -- 初期化
      gt_sales_h_tbl.DELETE;
      ln_start    := 1;
      ln_end      := gn_ar_bulk_collect_cnt; --BUKL処理件数
      ln_run_flag := 0;
--
      --==============================================================
      -- 販売実績ヘッダ更新処理(対象外)
      --==============================================================
      --カーソルオープン
      OPEN no_target_cur;
--
      LOOP
--
        EXIT WHEN no_target_cur%NOTFOUND;
--
        gt_sales_h_tbl.DELETE;
--
        FETCH no_target_cur BULK COLLECT INTO gt_sales_h_tbl LIMIT gn_ar_bulk_collect_cnt;
--
        --対象外データの更新
        FORALL i IN 1..gt_sales_h_tbl.COUNT
          UPDATE
            xxcos_sales_exp_headers       xseh
          SET
            xseh.ar_interface_flag      = cv_s_flag,                     -- ARインタフェース対象外
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
      END LOOP;
--
      --カーソルクローズ
      CLOSE no_target_cur;
/* 2009/10/02 Ver1.24 Mod End   */
    EXCEPTION
/* 2009/10/02 Ver1.24 Mod Start */
--      WHEN OTHERS THEN
--          RAISE global_update_data_expt;
      WHEN lock_expt THEN
        IF ( no_target_cur%ISOPEN ) THEN
          CLOSE no_target_cur;
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
        RAISE global_api_expt;
      WHEN OTHERS THEN
        IF ( no_target_cur%ISOPEN ) THEN
          CLOSE no_target_cur;
        END IF;
        RAISE global_update_data_expt;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Add Start */
  /***********************************************************************************
   * Procedure Name   : del_data
   * Description      :  販売実績AR用ワーク削除処理(A-10)
   ***********************************************************************************/
  PROCEDURE del_data(
      ov_errbuf       OUT VARCHAR2    -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2    -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2 )  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'del_data'; -- プログラム名
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
    lv_tbl_nm           VARCHAR2(255);          -- テーブル名
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
    -- 販売実績AR用ワーク削除処理
    --==============================================================
    BEGIN
      DELETE FROM xxcos_sales_exp_ar_work xseaw
      WHERE xseaw.request_id = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_delete_data_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_delete_data_expt THEN
      -- 削除に失敗した場合
      -- エラー件数設定
      gn_error_cnt := gn_target_cnt;
      lv_tbl_nm    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_tkn_work_msg
                     );
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_data_delete_msg
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
  END del_data;
/* 2009/10/02 Ver1.24 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
  (
/* 2009/10/02 Ver1.24 Mod Start */
--      ov_errbuf    OUT VARCHAR2             --   エラー・メッセージ           --# 固定 #
--    , ov_retcode   OUT VARCHAR2             --   リターン・コード             --# 固定 #
--    , ov_errmsg    OUT VARCHAR2 )           --   ユーザー・エラー・メッセージ --# 固定 #
      iv_target       IN  VARCHAR2    -- 処理対象区分 1:大手 2:非大手
    , iv_create_class IN  VARCHAR2    -- 作成元区分
    , ov_errbuf       OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2    --   リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2 )  --   ユーザー・エラー・メッセージ --# 固定 #
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Del Start */
--    lv_tbl_nm VARCHAR2(255);                -- テーブル名
/* 2009/10/02 Ver1.24 Del End   */
/* 2009/10/02 Ver1.24 Mod Start */
    lv_errbuf_bk  VARCHAR2(5000);           -- エラー・メッセージ(対象データ無し時の退避用)
    lv_errmsg_bk  VARCHAR2(5000);           -- ユーザー・エラー・メッセージ(対象データ無し時の退避用)
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--        ov_errbuf  => lv_errbuf             -- エラー・メッセージ           --# 固定 #
--      , ov_retcode => lv_retcode            -- リターン・コード             --# 固定 #
--      , ov_errmsg  => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
        iv_target       => iv_target        -- 処理対象区分
      , iv_create_class => iv_create_class  -- 作成元区分
      , ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      , ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
      , ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
/* 2009/10/02 Ver1.24 Mod End   */
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2-1.販売実績データ取得
    -- ===============================
    get_data(
/* 2009/10/02 Ver1.24 Mod Start */
--        ov_errbuf  => lv_errbuf             -- エラー・メッセージ           --# 固定 #
--      , ov_retcode => lv_retcode            -- リターン・コード             --# 固定 #
--      , ov_errmsg  => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
        iv_target       => iv_target        -- 処理対象区分
      , iv_create_class => iv_create_class  -- 作成元区分
      , ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      , ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
      , ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
/* 2009/10/02 Ver1.24 Mod End   */
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
/* 2010/03/08 Ver1.27 Mod Start   */
    ELSIF (  gn_target_cnt = 0 ) THEN
--    ELSIF (  lv_retcode = cv_status_warn ) THEN
/* 2010/03/08 Ver1.27 Mod End   */
/* 2009/10/02 Ver1.24 Add Start */
      --エラーの退避
      lv_errbuf_bk  := lv_errbuf;
      lv_errmsg_bk  := lv_errmsg;
      -- ===============================
      -- A-9.販売実績データの更新処理(対象外データ更新の為)
      -- ===============================
      upd_data(
          iv_target       => iv_target        -- 処理対象区分
        , iv_create_class => iv_create_class  -- 作成元区分         
        , ov_errbuf       => lv_errbuf           -- エラー・メッセージ
        , ov_retcode      => lv_retcode          -- リターン・コード
        , ov_errmsg       => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_update_data_expt;
      END IF;
--
      --更新処理でエラーがない場合、退避した値を戻す
      lv_errbuf  := lv_errbuf_bk;
      lv_errmsg  := lv_errmsg_bk;
/* 2009/10/02 Ver1.24 Add Start */
      -- 販売実績データ抽出が0件時は、抽出レコードなし警告で終了
      RAISE global_no_data_expt;
    END IF;
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- ===============================
--      -- A-3.請求取引集約処理（非大手量販店）
--      -- ===============================
--    IF ( gt_sales_norm_tbl.COUNT > 0 ) THEN
--      edit_sum_data(
--           ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
--         , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
--         , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_process_expt;
--      END IF;
--    END IF;
--
--      -- ===============================
--      -- A-4.AR会計配分仕訳作成（非大手量販店）
--      -- ===============================
--    IF ( gt_sales_norm_tbl2.COUNT > 0 ) THEN
--      edit_dis_data(
--           ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
--         , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
--         , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_process_expt;
--      END IF;
--    END IF;
--
--      -- ===============================
--      -- A-5.AR請求取引情報集約処理（大手量販店）
--      -- ===============================
--    IF ( gt_sales_bulk_tbl.COUNT > 0 ) THEN
--      edit_sum_bulk_data(
--           ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
--         , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
--         , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_process_expt;
--      END IF;
--    END IF;
--
--      -- ===============================
--      -- A-6.AR会計配分仕訳作成（大手量販店）
--      -- ===============================
--    IF ( gt_sales_bulk_tbl2.COUNT > 0 ) THEN
--      edit_dis_bulk_data(
--           ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
--         , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
--         , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_process_expt;
--      END IF;
--    END IF;
--
--    -- ===============================
--    -- A-7.AR請求取引OIF登録処理
--    -- ===============================
--    insert_aroif_data(
--          ov_errbuf       => lv_errbuf     -- エラー・メッセージ
--        , ov_retcode      => lv_retcode    -- リターン・コード
--        , ov_errmsg       => lv_errmsg     -- ユーザー・エラー・メッセージ
--      );
--    IF ( lv_retcode = cv_status_error ) THEN
--      gn_error_cnt := gn_target_cnt;
--      RAISE global_insert_data_expt;
--    END IF;
--
--    -- ===============================
--    -- A-8.AR会計配分OIF登録処理
--    -- ===============================
--    insert_ardis_data(
--          ov_errbuf       => lv_errbuf     -- エラー・メッセージ
--        , ov_retcode      => lv_retcode    -- リターン・コード
--        , ov_errmsg       => lv_errmsg     -- ユーザー・エラー・メッセージ
--      );
--    IF ( lv_retcode = cv_status_error ) THEN
--      gn_error_cnt := gn_target_cnt;
--      RAISE global_insert_data_expt;
--    END IF;
--
    -- ワークテーブルに件数がある場合処理実行
    IF ( gn_work_cnt <> 0 ) THEN
--
      -- 非大手処理の場合
      IF ( iv_target = cv_not_major ) THEN
--
        -- ===============================
        -- A-2-2.販売実績AR用ワークデータ取得
        -- ===============================
        OPEN bulk_data_cur;
--
        LOOP
--
          --初期化
          gt_sales_norm_tbl.DELETE;    -- メインSQL用配列
          gt_ar_interface_tbl1.DELETE; -- AR請求取引OIFインサート用配列
          gt_ar_dis_tbl1.DELETE;       -- AR会計配分OIFインサート用配列
--
          --リミット毎に処理する
          FETCH bulk_data_cur BULK COLLECT INTO gt_sales_norm_tbl LIMIT gn_ar_bulk_collect_cnt;
--
          EXIT WHEN gn_fetch_end_flag = 1;
--
          -- データ有無チェック
          IF ( bulk_data_cur%NOTFOUND ) THEN
            gn_fetch_end_flag := 1; --最後のBULK処理
          END IF;
--
          -- ===============================
          -- A-3.請求取引集約処理（非大手量販店）
          -- ===============================
          edit_sum_data(
               ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
             , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
             , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- A-4.AR会計配分仕訳作成（非大手量販店）
          -- ===============================
          edit_dis_data(
               ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
             , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
             , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- A-7.AR請求取引OIF登録処理
          -- ===============================
          insert_aroif_data(
               iv_target       => iv_target     -- 処理対象区分
             , ov_errbuf       => lv_errbuf     -- エラー・メッセージ
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
          --2回目以降のBUKL処理で初期処理をさせない
          gn_fetch_first_flag := 1;
--
        END LOOP;
--
      -- 大手処理の場合
      ELSIF ( iv_target = cv_major ) THEN
--
        -- ===============================
        -- A-2-2.販売実績AR用ワークデータ取得
        -- ===============================
/* 2009/11/05 Ver1.26 Mod Start */
--        OPEN bulk_data_cur;
        OPEN bulk_data_cur2;
/* 2009/11/05 Ver1.26 Mod End   */
--
        LOOP
--
          --初期化
          gt_sales_bulk_tbl.DELETE;    -- メインSQL用配列
          gt_ar_interface_tbl1.DELETE; -- AR請求取引OIFインサート用配列
          gt_ar_dis_tbl1.DELETE;       -- AR会計配分OIFインサート用配列
--
          --リミット毎に処理する
/* 2009/11/05 Ver1.26 Mod Start */
--          FETCH bulk_data_cur BULK COLLECT INTO gt_sales_bulk_tbl LIMIT gn_ar_bulk_collect_cnt;
          FETCH bulk_data_cur2 BULK COLLECT INTO gt_sales_bulk_tbl LIMIT gn_ar_bulk_collect_cnt;
/* 2009/11/05 Ver1.26 Mod End   */
--
          EXIT WHEN gn_fetch_end_flag = 1;
--
          -- データ有無チェック
/* 2009/11/05 Ver1.26 Mod Start */
--          IF ( bulk_data_cur%NOTFOUND ) THEN
          IF ( bulk_data_cur2%NOTFOUND ) THEN
/* 2009/11/05 Ver1.26 Mod End   */
            gn_fetch_end_flag := 1; --最後のBULK処理
          END IF;
--
          -- ===============================
          -- A-5.AR請求取引情報集約処理（大手量販店）
          -- ===============================
          edit_sum_bulk_data(
               ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
             , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
             , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- A-6.AR会計配分仕訳作成（大手量販店）
          -- ===============================
          edit_dis_bulk_data(
               ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
             , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
             , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- A-7.AR請求取引OIF登録処理
          -- ===============================
          insert_aroif_data(
               iv_target       => iv_target     -- 処理対象区分
             , ov_errbuf       => lv_errbuf     -- エラー・メッセージ
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
          --2回目以降のBUKL処理で初期処理をさせない
          gn_fetch_first_flag := 1;
--
        END LOOP;
--
      END IF;
--
      -- 配列削除
      gt_jour_cls_tbl.DELETE;
      gt_sel_ccid_tbl.DELETE;
--
    END IF;
--
/* 2009/10/02 Ver1.24 Mod End   */
    -- ===============================
    -- A-9.販売実績データの更新処理
    -- ===============================
    upd_data(
/* 2009/10/02 Ver1.24 Mod Start */
--        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
--      , ov_retcode => lv_retcode          -- リターン・コード
--      , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
        iv_target       => iv_target        -- 処理対象区分
      , iv_create_class => iv_create_class  -- 作成元区分         
      , ov_errbuf       => lv_errbuf           -- エラー・メッセージ
      , ov_retcode      => lv_retcode          -- リターン・コード
      , ov_errmsg       => lv_errmsg           -- ユーザー・エラー・メッセージ
/* 2009/10/02 Ver1.24 Mod End   */
      );
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_update_data_expt;
    END IF;
/* 2009/10/02 Ver1.24 Add Start */
    IF ( gn_work_cnt <> 0 ) THEN
      -- ===============================
      -- A-10.販売実績AR用ワーク削除処理
      -- ===============================
      del_data(
          ov_errbuf       => lv_errbuf           -- エラー・メッセージ
        , ov_retcode      => lv_retcode          -- リターン・コード
        , ov_errmsg       => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_update_data_expt;
      END IF;
    END IF;
/* 2009/10/02 Ver1.24 Add End   */
--
    -- 成功件数をセット
/* 2009/10/02 Ver1.24 Mod Start */
--    gn_aroif_cnt  := gt_ar_interface_tbl1.COUNT;                      -- AR請求取引OIF登録件数
--    gn_ardis_cnt  := gt_ar_dis_tbl1.COUNT;                            -- AR会計配分OIF登録件数
    gn_aroif_cnt  := gn_aroif_cnt_tmp;             -- AR請求取引OIF登録件数
    gn_ardis_cnt  := gn_ardis_cnt_tmp;             -- AR会計配分OIF登録件数
/* 2009/10/02 Ver1.24 Mod End   */
    gn_normal_cnt := gn_aroif_cnt + gn_ardis_cnt;
--
    IF ( gn_warn_flag = cv_y_flag ) THEN
--
      IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
        --スキップ件数計算する
/* 2009/10/02 Ver1.24 Mod Start */
--        <<gt_sales_exp_tbl2_loop>>
--        FOR sale_idx IN 1 .. gt_sales_exp_tbl2.COUNT LOOP
        <<gt_sales_target_tbl_loop>>
        FOR sale_idx IN 1 .. gt_sales_target_tbl.COUNT LOOP
/* 2009/10/02 Ver1.24 Mod End   */
          gv_skip_flag := cv_n_flag;
          -- スキップ処理
          <<gt_sales_skip_tbl_loop>>
          FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
            IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                  = gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id ) THEN
                = gt_sales_target_tbl( sale_idx ).sales_exp_header_id ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
              gv_skip_flag := cv_y_flag;
              EXIT;
            END IF;
          END LOOP gt_sales_skip_tbl_loop;
--
          IF ( gv_skip_flag = cv_y_flag ) THEN
            gn_skip_cnt := gn_skip_cnt + 1;
          END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--        END LOOP gt_sales_exp_tbl2_loop;
        END LOOP gt_sales_target_tbl_loop;
/* 2009/10/02 Ver1.24 Mod End   */
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
/* 2010/03/08 Ver1.27 Mod Start   */
      ov_retcode := cv_status_normal;
--      ov_retcode := cv_status_warn;
/* 2010/03/08 Ver1.27 Mod End   */
    -- *** データ取得例外 ***
    WHEN global_select_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 登録処理例外 ***
    WHEN global_insert_data_expt THEN
/* 2009/10/02 Ver1.24 Add Start */
      IF ( bulk_data_cur%ISOPEN ) THEN
        CLOSE bulk_data_cur;
      END IF;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
      IF ( bulk_data_cur2%ISOPEN ) THEN
        CLOSE bulk_data_cur2;
      END IF;
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
      IF ( bulk_data_cur%ISOPEN ) THEN
        CLOSE bulk_data_cur;
      END IF;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
      IF ( bulk_data_cur2%ISOPEN ) THEN
        CLOSE bulk_data_cur2;
      END IF;
/* 2009/11/05 Ver1.26 Add End   */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
/* 2009/10/02 Ver1.24 Add Start */
      IF ( bulk_data_cur%ISOPEN ) THEN
        CLOSE bulk_data_cur;
      END IF;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
      IF ( bulk_data_cur2%ISOPEN ) THEN
        CLOSE bulk_data_cur2;
      END IF;
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--      errbuf      OUT VARCHAR2               -- エラー・メッセージ  --# 固定 #
--    , retcode     OUT VARCHAR2 )             -- リターン・コード    --# 固定 #
      errbuf          OUT   VARCHAR2    -- エラー・メッセージ  --# 固定 #
    , retcode         OUT   VARCHAR2    -- リターン・コード    --# 固定 #
    , iv_target       IN    VARCHAR2    -- 処理対象区分 1:大手 2:非大手
    , iv_create_class IN    VARCHAR2 )  -- 作成元区分
/* 2009/10/02 Ver1.24 Add End   */
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
/* 2009/10/02 Ver1.24 Add Start */
--        ov_errbuf  => lv_errbuf              -- エラー・メッセージ           --# 固定 #
--      , ov_retcode => lv_retcode             -- リターン・コード             --# 固定 #
--      , ov_errmsg  => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
        iv_target       => iv_target         -- 処理対象区分 1:大手 2:非大手
      , iv_create_class => iv_create_class   -- 作成元区分
      , ov_errbuf       => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode      => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg       => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
/* 2009/10/02 Ver1.24 Add End   */
    );
--
    --エラー出力
/* 2010/03/08 Ver1.27 Mod Start   */
    IF (lv_retcode = cv_status_error OR lv_retcode = cv_status_warn OR gn_target_cnt = 0 ) THEN
--    IF (lv_retcode = cv_status_error OR lv_retcode = cv_status_warn) THEN
/* 2010/03/08 Ver1.27 Mod End   */
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
