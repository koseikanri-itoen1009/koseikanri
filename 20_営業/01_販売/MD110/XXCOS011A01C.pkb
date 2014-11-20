CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A01C (body)
 * Description      : SQL-LOADERによってEDI納品返品情報ワークテーブルに取込まれたEDI返品確定データを
 *                    EDIヘッダ情報テーブル、EDI明細情報テーブルにそれぞれ登録します。
 * MD.050           : 返品確定データ取込（MD050_COS_011_A01）
 * Version          : 1.9
 *
 * Program List
 * ----------------------------------- ----------------------------------------------------------
 *  Name                                Description
 * ----------------------------------- ----------------------------------------------------------
 *  init                               初期処理 (A-1)
 *  sel_in_edi_delivery_work           EDI納品返品情報ワークテーブルデータ抽出 (A-2)
 *  xxcos_in_edi_headers_edit          EDIヘッダ情報変数の編集(A-2)(1)
 *  xxcos_in_edi_lists_edit            EDI明細情報変数の編集(A-2)(2)
 *  data_check                         データ妥当性チェック (A-3)
 *  xxcos_in_edi_headers_add           EDIヘッダ情報変数への追加(A-4)
 *  xxcos_in_edi_headers_up            EDIヘッダ情報変数へ数量を加算(A-5)
 *  xxcos_in_edi_deli_wk_update        EDI納品返品情報ワークテーブルへの更新(A-6)
 *  xxcos_in_edi_headers_insert        EDIヘッダ情報テーブルへのデータ挿入(A-7)
 *  xxcos_in_edi_lines_insert          EDI明細情報テーブルへのデータ挿入(A-8)
 *  xxcos_in_edi_deli_work_delete      EDI納品返品情報ワークテーブルデータ削除(A-9)
 *  xxcos_in_edi_head_lock             EDIヘッダ情報テーブルロック(A-10)(1)
 *  xxcos_in_edi_line_lock             EDI明細情報テーブルロック(A-10)(2)
 *  xxcos_in_edi_head_delete           EDIヘッダ情報テーブルデータ削除(A-10)(3)
 *  xxcos_in_edi_line_delete           EDI明細情報テーブル削除(A-10)(4)
 *  xxcos_in_edi_head_line_delete      EDIヘッダ情報テーブル、EDI明細情報テーブルデータ削除(A-10)
 *  submain                            メイン処理プロシージャ
 *  main                               コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/27    1.0   K.Watanabe      新規作成
 *  2009/02/12    1.1   T.Ishiwata      [COS_058]顧客導出に営業単位を追加
 *                                      [COS_073]終了ステータスによる処理判定の修正
 *                                      [COS_082]伝票計の修正
 *                                      [COS_096]原単価（発注）の取得処理追加
 *                                      [COS_103]変換後顧客コード取得ロジックの修正
 *                                      [COS_118]EDI情報削除ロジックの修正
 *  2009/05/19    1.2   T.Kitajima      [T1_0242]品目取得時、OPM品目マスタ.発売（製造）開始日条件追加
 *                                      [T1_0243]品目取得時、子品目対象外条件追加
 *                                      [T1_1055]価格表、単価取得ロジック変更
 *  2009/05/28    1.3   T.Kitajima      [T1_0711]処理後件数対応
 *                                      [T1_1164]oracleエラー対応
 *  2009/06/04    1.4   T.Kitajima      [T1_1289]処理後件数対応
 *  2009/06/15    1.5   M.Sano          [T1_0700]「gt_err_edideli_work_data」配列の初期化対応
 *  2009/06/29    1.5   T.Tominaga      [T1_0022, T1_0023, T1_0024, T1_0042, T1_0201]
 *                                      ・ブレイク条件に店舗コードを追加
 *                                      ・各種チェック処理でエラーにしない対応
 *  2009/07/21    1.5   N.Maeda         [000644]端数処理追加
 *                                      [000437]PT考慮の追加
 *  2009/08/05    1.5   N.Maeda         [000437]レビュー指摘追加
 *  2009/08/06    1.5   M.Sano          [0000644]レビュー指摘対応
 *  2009/09/28    1.6   K.Satomura      [0001156,0001289]
 *  2010/03/02    1.7   M.Sano          [E_本稼動_01159]パラメータ(チェーン店)に「DEFAULT NULL」追加
 *  2010/04/23    1.8   T.Yoshimoto     [E_本稼動_02427]chain_peculiar_area_header登録データ変更
 *  2011/07/26    1.9   K.Kiriu         [E_本稼動_07906]流通BMS対応
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
  cd_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date; -- 業務処理日
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_line               CONSTANT VARCHAR2(3) := '   ';
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
  --*** データ抽出エラー例外 ***
  global_data_sel_expt      EXCEPTION;
  --対象データなし例外
  global_nodata_expt        EXCEPTION;
  -- ロックエラー
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT   VARCHAR2(100) := 'XXCOS011A01';               -- パッケージ名
--
  cv_application            CONSTANT   VARCHAR2(5)   := 'XXCOS';                     -- アプリケーション名
  -- プロファイル
  cv_prf_edi_del_date       CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_PURGE_TERM';     -- XXCOS:EDI情報削除期間
  cv_prf_case_code          CONSTANT   VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';      -- XXCOS:ケース単位コード
  cv_prf_orga_code1         CONSTANT   VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
  cv_prf_org_id             CONSTANT   VARCHAR2(50)  := 'ORG_ID';                    -- MO:営業単位
  -- クイックコード(タイプ)
  cv_lookup_type            CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';
  cv_lookup_type1           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_EXE_TYPE';
  cv_lookup_type2           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_STATUS';
  cv_lookup_type3           CONSTANT   VARCHAR2(50)  := 'XXCOS1_DATA_TYPE_CODE';
  cv_lookup_type4           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_CREATE_CLASS';   -- EDI作成元区分
  -- クイックコード(コード)
  cv_inv_num_err_flag       CONSTANT   VARCHAR2(1)   := '9';   -- 実行区分：「エラー」
  cv_creation_class_code    CONSTANT   VARCHAR2(10)  := '30';
  cv_customer_class_code10  CONSTANT   VARCHAR2(10)  := '10';  -- 顧客マスタ.顧客区分 = '10'(顧客)
  cv_customer_class_code18  CONSTANT   VARCHAR2(10)  := '18';  -- 顧客マスタ.顧客区分 = '18'(EDIチェーン店)
  cv_cust_site_use_code     CONSTANT   VARCHAR2(10)  := 'SHIP_TO';                   -- 顧客使用目的：出荷先
  cn_0                      CONSTANT   NUMBER := 0;
  cn_1                      CONSTANT   NUMBER := 1;
  cn_m1                     CONSTANT   NUMBER := -1;
  cv_y                      CONSTANT   VARCHAR2(1)   := 'Y';
-- ******************** 2009/09/28 1.6 K.Satomura MOD START *********************** --
  cv_n                      CONSTANT   VARCHAR2(1)   := 'N';
-- ******************** 2009/09/28 1.6 K.Satomura MOD END   *********************** --

  cv_0                      CONSTANT   VARCHAR2(1)   := '0';
  cv_1                      CONSTANT   VARCHAR2(1)   := '1';
  cv_2                      CONSTANT   VARCHAR2(1)   := '2';
  cv_par                    CONSTANT   VARCHAR2(1)   := '%';
  --* -------------------------------------------------------------------------------------------
  gv_msg_nodata_err         CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00003'; --対象データなしエラー
  gv_msg_in_param_none_err  CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00006'; --必須入力パラメータ未設定エラーメッセージ
  gv_msg_in_param_err       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00019'; --入力パラメータ不正エラーメッセージ
  gv_msg_in_none_err        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00015'; --必須項目未入力エラーメッセージ
  gv_msg_get_profile_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00004'; --プロファイル取得エラーメッセージ
  gv_msg_orga_id_err        CONSTANT   VARCHAR2(20)  := 'APP-XXCOI1-00006'; --在庫組織ID取得エラーメッセージ
  gv_msg_lock               CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00001'; --ロックエラーメッセージ
  gv_msg_nodata             CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00013'; --データ抽出エラーメッセージ
  gv_msg_cust_num_chg_err   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00020'; --顧客コード変換エラーメッセージ
  gv_msg_item_code_err      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00023'; --EDI連携品目コード区分エラーメッセージ
  gv_msg_product_code_err   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00024'; --商品コード変換エラーメッセージ
  gv_msg_price_list_err     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00022'; --価格表未設定エラーメッセージ
  gv_msg_data_update_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00011'; --データ更新エラーメッセージ
  gv_msg_data_delete_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00012'; --データ削除エラーメッセージ
  gv_msg_param_out_msg1     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12151'; --パラメータ出力メッセージ1
  gv_msg_param_out_msg2     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12152'; --パラメータ出力メッセージ2
  gv_msg_prod_cd_ng_rec_num CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00039'; --商品コードエラー件数メッセージ
  gv_msg_normal_msg         CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90004'; --正常終了メッセージ
  gv_msg_warning_msg        CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90005'; --警告終了メッセージ
  gv_msg_error_msg          CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90006'; --エラー終了全ロールバックメッセージ
  cv_msg_call_api_err       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00017'; --API呼出エラー
--****************************** 2009/05/19 1.2 T.Kitajima ADD START ******************************--
  cv_msg_price_err          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00123'; -- 単価取得エラーメッセージ
--****************************** 2009/05/19 1.2 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
  cv_msg_count              CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12176'; -- 処理件数メッセージ
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
--****************************** 2009/09/28 1.6 K.Satomura ADD START ******************************--
  cv_msg_item_err_type      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-11959';  -- EDI品目エラータイプ
  cv_msg_lookup_value       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- クイックコード
  cv_msg_mst_notfound       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-10002';  -- マスタチェックエラーメッセージ
--****************************** 2009/09/28 1.6 K.Satomura ADD END   ******************************--
  --* -------------------------------------------------------------------------------------------
  --トークン
  cv_msg_in_param           CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12168';  -- 実行区分
  --トークン プロファイル
  cv_msg_edi_del_date       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12169';  -- EDI情報削除期間
  cv_msg_case_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12153';  -- ケース単位コード
  cv_msg_orga_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12154';  -- 在庫組織コード
  cv_msg_org_id             CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00047';  -- MO:営業単位
  --トークン プロファイル
  cv_msg_in_file_name       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12171';  -- インターフェースファイル名
  --* -------------------------------------------------------------------------------------------
  cv_tkn_profile            CONSTANT   VARCHAR2(50) :=  'PROFILE';              --プロファイル
  cv_tkn_item               CONSTANT   VARCHAR2(50) :=  'ITEM';
  cv_tkn_org_code           CONSTANT   VARCHAR2(50) :=  'ORG_CODE_TOK';
  cv_tkn_in_param           CONSTANT   VARCHAR2(50) :=  'IN_PARAM';             --入力パラメータ
  cv_tkn_api_name           CONSTANT   VARCHAR2(50) :=  'API_NAME';             --API名
  cv_tkn_table_name         CONSTANT   VARCHAR2(50) :=  'TABLE';                --テーブル名
  cv_tkn_table_name1        CONSTANT   VARCHAR2(50) :=  'TABLE_NAME';           --テーブル名
  cv_tkn_key_data           CONSTANT   VARCHAR2(50) :=  'KEY_DATA';             --キーデータ
  cv_chain_shop_code        CONSTANT   VARCHAR2(50) :=  'CHAIN_SHOP_CODE';
  cv_shop_code              CONSTANT   VARCHAR2(50) :=  'SHOP_CODE';
  cv_prod_code              CONSTANT   VARCHAR2(50) :=  'PROD_CODE';
  cv_prod_type              CONSTANT   VARCHAR2(50) :=  'PROD_TYPE';
  cv_param1                 CONSTANT   VARCHAR2(50) :=  'PARAM1';
  cv_param2                 CONSTANT   VARCHAR2(50) :=  'PARAM2';
  cv_application1           CONSTANT   VARCHAR2(5)   := 'XXCOI';             -- アプリケーション名
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
  cv_tkn_cnt1               CONSTANT   VARCHAR2(50) :=  'COUNT1';            -- カウント1
  cv_tkn_cnt2               CONSTANT   VARCHAR2(50) :=  'COUNT2';            -- カウント2
  cv_tkn_cnt3               CONSTANT   VARCHAR2(50) :=  'COUNT3';            -- カウント3
  cv_tkn_cnt4               CONSTANT   VARCHAR2(50) :=  'COUNT4';            -- カウント4
  cv_tkn_cnt5               CONSTANT   VARCHAR2(50) :=  'COUNT5';            -- カウント5
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
--****************************** 2009/09/28 1.6 K.Satomura ADD START ******************************--
  cv_tkn_column_name        CONSTANT   VARCHAR2(50) :=  'COLMUN';            -- 列名
--****************************** 2009/09/28 1.6 K.Satomura ADD END   ******************************--
  --* -------------------------------------------------------------------------------------------
  --メッセージ用文字列
  cv_msg_str_profile_name   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12155';  -- プロファイル名
  cv_msg_edi_deli_work      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12156';  -- EDI納品返品情報ワークテーブル
  cv_msg_edi_headers        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12157';  -- EDIヘッダ情報テーブル
  cv_msg_edi_lines          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12158';  -- EDI明細情報テーブル
  cv_msg_mtl_cust_items     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12159';  -- 顧客品目
  cv_msg_shop_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12160';  -- 店コード
  cv_msg_class_name1        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12161';  -- 実行区分：「新規」
  cv_msg_class_name2        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12162';  -- 実行区分：「再実施」
  cv_msg_class_name3        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12163';  -- 実行区分：「エラー」
  cv_msg_data_type_code     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12164';  -- データ種コード：「返品確定」
  cv_msg_sum_order_qty      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12165';  -- 発注数量（合計、バラ）
  cv_msg_jan_code           CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12166';  -- JANコード
  cv_msg_none               CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12167';  -- なし
  --トークン プロファイル
  cv_msg_in_file_name1      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12172';  -- インターフェースファイル名
--****************************** 2009/06/29 1.5 T.Tominaga ADD START ******************************
  cv_data_type_32           CONSTANT   VARCHAR2(10)  := '32';                -- データ種コード：出庫確定
  cv_data_type_33           CONSTANT   VARCHAR2(10)  := '33';                -- データ種コード：返品確定
--****************************** 2009/06/29 1.5 T.Tominaga ADD END   ******************************
  --* -------------------------------------------------------------------------------------------
--****************************** 2009/05/19 1.2 T.Kitajima ADD START ******************************--
  cv_format_yyyymmdd        CONSTANT   VARCHAR2(20)  := 'YYYY/MM/DD';        -- 日付フォーマット
--****************************** 2009/05/19 1.2 T.Kitajima ADD  END  ******************************--
-- ************** 2009/07/22 N.Maeda ADD START ****************** --
  cv_date_time              CONSTANT   VARCHAR2(25)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_time                   CONSTANT   VARCHAR2(25)  := '23:59:59';
  cv_space                  CONSTANT   VARCHAR2(1)   := ' ';
-- ************** 2009/07/22 N.Maeda ADD  END  ****************** --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_status_work_warn        VARCHAR2(1) DEFAULT xxccp_common_pkg.set_status_normal;
  gv_status_work_err         VARCHAR2(1) DEFAULT xxccp_common_pkg.set_status_normal;
--
  --トークン プロファイル
  gv_in_file_name            VARCHAR2(50) DEFAULT NULL;     -- インターフェースファイル名
  gv_in_param                VARCHAR2(50) DEFAULT NULL;     -- 実行区分
  gv_prf_edi_del_date0       VARCHAR2(50) DEFAULT NULL;     -- EDI情報削除期間
  gv_prf_case_code0          VARCHAR2(50) DEFAULT NULL;     -- ケース単位コード
  gv_prf_orga_code0          VARCHAR2(50) DEFAULT NULL;     -- 在庫組織コード
--
  -- テーブル定義名称
  gv_tkn_edi_deli_work       VARCHAR2(50);     -- EDI納品返品情報ワークテーブル
  gv_tkn_edi_headers         VARCHAR2(50);     -- EDIヘッダ情報テーブル
  gv_tkn_edi_lines           VARCHAR2(50);     -- EDI明細情報テーブル
  gv_tkn_mtl_cust_items      VARCHAR2(50);     -- 顧客品目
  gv_tkn_shop_code           VARCHAR2(50);     -- 店コード
  gv_msg_tkn_org_id          VARCHAR2(50);     -- MO:営業単位
  gv_sum_order_qty           VARCHAR2(50);     -- 発注数量（合計、バラ）
  gv_jan_code                VARCHAR2(10);     -- JANコード
  gn_org_id                  NUMBER;           -- MO:営業単位
  gv_none                    VARCHAR2(10);     -- なし
  gv_run_class_name01        VARCHAR2(50) DEFAULT NULL; -- 実行区分：「新規」文言
  gv_run_class_name02        VARCHAR2(50) DEFAULT NULL; -- 実行区分：「再実施」文言
  gv_run_class_name1         VARCHAR2(2)  DEFAULT NULL; -- 実行区分：「新規」
  gv_run_class_name2         VARCHAR2(2)  DEFAULT NULL; -- 実行区分：「再実施」
  gv_run_class_name3         VARCHAR2(2)  DEFAULT NULL; -- 実行区分：「エラー」
  gv_run_data_type_code      VARCHAR2(50) DEFAULT NULL; -- データ種コード：「返品確定」
  gn_normal_headers_cnt      NUMBER DEFAULT 0; -- 正常件数(headers)
  gn_normal_lines_cnt        NUMBER DEFAULT 0; -- 正常件数(lines)
  -- 伝票番号
  gv_invoice_number          VARCHAR2(12) DEFAULT NULL;
--
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
  gn_msg_cnt                 NUMBER;                        -- メッセージ件数
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
-- ************** 2009/07/22 N.Maeda ADD START ****************** --
  gd_edi_del_consider_date   DATE;             -- EDI情報削除期間考慮日付作成
-- ************** 2009/07/22 N.Maeda ADD  END  ****************** --
-- ************** 2009/09/28 1.6 K.Satomura ADD START ****************** --
  gt_dummy_item_number     mtl_system_items_b.segment1%TYPE;
  gt_dummy_unit_of_measure mtl_system_items_b.primary_unit_of_measure%TYPE;
-- ************** 2009/09/28 1.6 K.Satomura ADD END   ****************** --
  --
  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- EDI納品返品情報ワークテーブルデータ格納用変数(xxcos_edi_delivery_work)
  TYPE g_rec_edideli_work_data IS RECORD(
                -- 納品返品ワークID
      delivery_return_work_id      xxcos_edi_delivery_work.delivery_return_work_id%TYPE,
                -- 媒体区分
      medium_class                 xxcos_edi_delivery_work.medium_class%TYPE,
                -- データ種コード
      data_type_code               xxcos_edi_delivery_work.data_type_code%TYPE,
                -- ファイルＮｏ
      file_no                      xxcos_edi_delivery_work.file_no%TYPE,
                -- 情報区分
      info_class                   xxcos_edi_delivery_work.info_class%TYPE,
                -- 処理日
      process_date                 xxcos_edi_delivery_work.process_date%TYPE,
                -- 処理時刻
      process_time                 xxcos_edi_delivery_work.process_time%TYPE,
                -- 拠点（部門）コード
      base_code                    xxcos_edi_delivery_work.base_code%TYPE,
                -- 拠点名（正式名）
      base_name                    xxcos_edi_delivery_work.base_name%TYPE,
                -- 拠点名（カナ）
      base_name_alt                xxcos_edi_delivery_work.base_name_alt%TYPE,
                -- ＥＤＩチェーン店コード
      edi_chain_code               xxcos_edi_delivery_work.edi_chain_code%TYPE,
                -- ＥＤＩチェーン店名（漢字）
      edi_chain_name               xxcos_edi_delivery_work.edi_chain_name%TYPE,
                -- ＥＤＩチェーン店名（カナ）
      edi_chain_name_alt           xxcos_edi_delivery_work.edi_chain_name_alt%TYPE,
                -- チェーン店コード
      chain_code                   xxcos_edi_delivery_work.chain_code%TYPE,
                -- チェーン店名（漢字）
      chain_name                   xxcos_edi_delivery_work.chain_name%TYPE,
                -- チェーン店名（カナ）
      chain_name_alt               xxcos_edi_delivery_work.chain_name_alt%TYPE,
                -- 帳票コード
      report_code                  xxcos_edi_delivery_work.report_code%TYPE,
                -- 帳票表示名
      report_show_name             xxcos_edi_delivery_work.report_show_name%TYPE,
                -- 顧客コード
      customer_code                xxcos_edi_delivery_work.customer_code%TYPE,
                -- 顧客名（漢字）
      customer_name                xxcos_edi_delivery_work.customer_name%TYPE,
                -- 顧客名（カナ）
      customer_name_alt            xxcos_edi_delivery_work.customer_name_alt%TYPE,
                -- 社コード
      company_code                 xxcos_edi_delivery_work.company_code%TYPE,
                -- 社名（漢字）
      company_name                 xxcos_edi_delivery_work.company_name%TYPE,
                -- 社名（カナ）
      company_name_alt             xxcos_edi_delivery_work.company_name_alt%TYPE,
                -- 店コード
      shop_code                    xxcos_edi_delivery_work.shop_code%TYPE,
                -- 店名（漢字）
      shop_name                    xxcos_edi_delivery_work.shop_name%TYPE,
                -- 店名（カナ）
      shop_name_alt                xxcos_edi_delivery_work.shop_name_alt%TYPE,
                -- 納入センターコード
      delivery_center_code         xxcos_edi_delivery_work.delivery_center_code%TYPE,
                -- 納入センター名（漢字）
      delivery_center_name         xxcos_edi_delivery_work.delivery_center_name%TYPE,
                -- 納入センター名（カナ）
      delivery_center_name_alt     xxcos_edi_delivery_work.delivery_center_name_alt%TYPE,
                -- 発注日
      order_date                   xxcos_edi_delivery_work.order_date%TYPE,
                -- センター納品日
      center_delivery_date         xxcos_edi_delivery_work.center_delivery_date%TYPE,
                -- 実納品日
      result_delivery_date         xxcos_edi_delivery_work.result_delivery_date%TYPE,
                -- 店舗納品日
      shop_delivery_date           xxcos_edi_delivery_work.shop_delivery_date%TYPE,
                -- データ作成日（ＥＤＩデータ中）
      data_creation_date_edi_data  xxcos_edi_delivery_work.data_creation_date_edi_data%TYPE,
                -- データ作成時刻（ＥＤＩデータ中）
      data_creation_time_edi_data  xxcos_edi_delivery_work.data_creation_time_edi_data%TYPE,
                -- 伝票区分
      invoice_class                xxcos_edi_delivery_work.invoice_class%TYPE,
                -- 小分類コード
      small_classification_code    xxcos_edi_delivery_work.small_classification_code%TYPE,
                -- 小分類名
      small_classification_name    xxcos_edi_delivery_work.small_classification_name%TYPE,
                -- 中分類コード
      middle_classification_code   xxcos_edi_delivery_work.middle_classification_code%TYPE,
                -- 中分類名
      middle_classification_name   xxcos_edi_delivery_work.middle_classification_name%TYPE,
                -- 大分類コード
      big_classification_code      xxcos_edi_delivery_work.big_classification_code%TYPE,
                -- 大分類名
      big_classification_name      xxcos_edi_delivery_work.big_classification_name%TYPE,
                -- 相手先部門コード
      other_party_department_code  xxcos_edi_delivery_work.other_party_department_code%TYPE,
                -- 相手先発注番号
      other_party_order_number     xxcos_edi_delivery_work.other_party_order_number%TYPE,
                -- チェックデジット有無区分
      check_digit_class            xxcos_edi_delivery_work.check_digit_class%TYPE,
                -- 伝票番号
      invoice_number               xxcos_edi_delivery_work.invoice_number%TYPE,
                -- チェックデジット
      check_digit                  xxcos_edi_delivery_work.check_digit%TYPE,
                -- 月限
      close_date                   xxcos_edi_delivery_work.close_date%TYPE,
                -- 受注Ｎｏ（ＥＢＳ）
      order_no_ebs                 xxcos_edi_delivery_work.order_no_ebs%TYPE,
                -- 特売区分
      ar_sale_class                xxcos_edi_delivery_work.ar_sale_class%TYPE,
                -- 配送区分
      delivery_classe              xxcos_edi_delivery_work.delivery_classe%TYPE,
                -- 便Ｎｏ
      opportunity_no               xxcos_edi_delivery_work.opportunity_no%TYPE,
                -- 連絡先
      contact_to                   xxcos_edi_delivery_work.contact_to%TYPE,
                -- ルートセールス
      route_sales                  xxcos_edi_delivery_work.route_sales%TYPE,
                -- 法人コード
      corporate_code               xxcos_edi_delivery_work.corporate_code%TYPE,
                -- メーカー名
      maker_name                   xxcos_edi_delivery_work.maker_name%TYPE,
                -- 地区コード
      area_code                    xxcos_edi_delivery_work.area_code%TYPE,
                -- 地区名（漢字）
      area_name                    xxcos_edi_delivery_work.area_name%TYPE,
                -- 地区名（カナ）
      area_name_alt                xxcos_edi_delivery_work.area_name_alt%TYPE,
                -- 取引先コード
      vendor_code                  xxcos_edi_delivery_work.vendor_code%TYPE,
                -- 取引先名（漢字）
      vendor_name                  xxcos_edi_delivery_work.vendor_name%TYPE,
                -- 取引先名１（カナ）
      vendor_name1_alt             xxcos_edi_delivery_work.vendor_name1_alt%TYPE,
                -- 取引先名２（カナ）
      vendor_name2_alt             xxcos_edi_delivery_work.vendor_name2_alt%TYPE,
                -- 取引先ＴＥＬ
      vendor_tel                   xxcos_edi_delivery_work.vendor_tel%TYPE,
                -- 取引先担当者
      vendor_charge                xxcos_edi_delivery_work.vendor_charge%TYPE,
                -- 取引先住所（漢字）
      vendor_address               xxcos_edi_delivery_work.vendor_address%TYPE,
                -- 届け先コード（伊藤園）
      deliver_to_code_itouen       xxcos_edi_delivery_work.deliver_to_code_itouen%TYPE,
                -- 届け先コード（チェーン店）
      deliver_to_code_chain        xxcos_edi_delivery_work.deliver_to_code_chain%TYPE,
                -- 届け先（漢字）
      deliver_to                   xxcos_edi_delivery_work.deliver_to%TYPE,
                -- 届け先１（カナ）
      deliver_to1_alt              xxcos_edi_delivery_work.deliver_to1_alt%TYPE,
                -- 届け先２（カナ）
      deliver_to2_alt              xxcos_edi_delivery_work.deliver_to2_alt%TYPE,
                -- 届け先住所（漢字）
      deliver_to_address           xxcos_edi_delivery_work.deliver_to_address%TYPE,
                -- 届け先住所（カナ）
      deliver_to_address_alt       xxcos_edi_delivery_work.deliver_to_address_alt%TYPE,
                -- 届け先ＴＥＬ
      deliver_to_tel               xxcos_edi_delivery_work.deliver_to_tel%TYPE,
                -- 帳合先コード
      balance_accounts_code        xxcos_edi_delivery_work.balance_accounts_code%TYPE,
                -- 帳合先社コード
      balance_accounts_company_code xxcos_edi_delivery_work.balance_accounts_company_code%TYPE,
                -- 帳合先店コード
      balance_accounts_shop_code   xxcos_edi_delivery_work.balance_accounts_shop_code%TYPE,
                -- 帳合先名（漢字）
      balance_accounts_name        xxcos_edi_delivery_work.balance_accounts_name%TYPE,
                -- 帳合先名（カナ）
      balance_accounts_name_alt    xxcos_edi_delivery_work.balance_accounts_name_alt%TYPE,
                -- 帳合先住所（漢字）
      balance_accounts_address     xxcos_edi_delivery_work.balance_accounts_address%TYPE,
                -- 帳合先住所（カナ）
      balance_accounts_address_alt xxcos_edi_delivery_work.balance_accounts_address_alt%TYPE,
                -- 帳合先ＴＥＬ
      balance_accounts_tel         xxcos_edi_delivery_work.balance_accounts_tel%TYPE,
                -- 受注可能日
      order_possible_date          xxcos_edi_delivery_work.order_possible_date%TYPE,
                -- 許容可能日
      permission_possible_date     xxcos_edi_delivery_work.permission_possible_date%TYPE,
                -- 先限年月日
      forward_month                xxcos_edi_delivery_work.forward_month%TYPE,
                -- 支払決済日
      payment_settlement_date      xxcos_edi_delivery_work.payment_settlement_date%TYPE,
                -- チラシ開始日
      handbill_start_date_active   xxcos_edi_delivery_work.handbill_start_date_active%TYPE,
                -- 請求締日
      billing_due_date             xxcos_edi_delivery_work.billing_due_date%TYPE,
                -- 出荷時刻
      shipping_time                xxcos_edi_delivery_work.shipping_time%TYPE,
                -- 納品予定時間
      delivery_schedule_time       xxcos_edi_delivery_work.delivery_schedule_time%TYPE,
                -- 発注時間
      order_time                   xxcos_edi_delivery_work.order_time%TYPE,
                -- 汎用日付項目１
      general_date_item1           xxcos_edi_delivery_work.general_date_item1%TYPE,
                -- 汎用日付項目２
      general_date_item2           xxcos_edi_delivery_work.general_date_item2%TYPE,
                -- 汎用日付項目３
      general_date_item3           xxcos_edi_delivery_work.general_date_item3%TYPE,
                -- 汎用日付項目４
      general_date_item4           xxcos_edi_delivery_work.general_date_item4%TYPE,
                -- 汎用日付項目５
      general_date_item5           xxcos_edi_delivery_work.general_date_item5%TYPE,
                -- 入出荷区分
      arrival_shipping_class       xxcos_edi_delivery_work.arrival_shipping_class%TYPE,
                -- 取引先区分
      vendor_class                 xxcos_edi_delivery_work.vendor_class%TYPE,
                -- 伝票内訳区分
      invoice_detailed_class       xxcos_edi_delivery_work.invoice_detailed_class%TYPE,
                -- 単価使用区分
      unit_price_use_class         xxcos_edi_delivery_work.unit_price_use_class%TYPE,
                -- サブ物流センターコード
      sub_distribution_center_code xxcos_edi_delivery_work.sub_distribution_center_code%TYPE,
                -- サブ物流センターコード名
      sub_distribution_center_name xxcos_edi_delivery_work.sub_distribution_center_name%TYPE,
                -- センター納品方法
      center_delivery_method       xxcos_edi_delivery_work.center_delivery_method%TYPE,
                -- センター利用区分
      center_use_class             xxcos_edi_delivery_work.center_use_class%TYPE,
                -- センター倉庫区分
      center_whse_class            xxcos_edi_delivery_work.center_whse_class%TYPE,
                -- センター地域区分
      center_area_class            xxcos_edi_delivery_work.center_area_class%TYPE,
                -- センター入荷区分
      center_arrival_class         xxcos_edi_delivery_work.center_arrival_class%TYPE,
                -- デポ区分
      depot_class                  xxcos_edi_delivery_work.depot_class%TYPE,
                -- ＴＣＤＣ区分
      tcdc_class                   xxcos_edi_delivery_work.tcdc_class%TYPE,
                -- ＵＰＣフラグ
      upc_flag                     xxcos_edi_delivery_work.upc_flag%TYPE,
                -- 一斉区分
      simultaneously_class         xxcos_edi_delivery_work.simultaneously_class%TYPE,
                -- 業務ＩＤ
      business_id                  xxcos_edi_delivery_work.business_id%TYPE,
                -- 倉直区分
      whse_directly_class          xxcos_edi_delivery_work.whse_directly_class%TYPE,
                -- 景品割戻区分
      premium_rebate_class         xxcos_edi_delivery_work.premium_rebate_class%TYPE,
                -- 項目種別
      item_type                    xxcos_edi_delivery_work.item_type%TYPE,
                -- 衣家食区分
      cloth_house_food_class       xxcos_edi_delivery_work.cloth_house_food_class%TYPE,
                -- 混在区分
      mix_class                    xxcos_edi_delivery_work.mix_class%TYPE,
                -- 在庫区分
      stk_class                    xxcos_edi_delivery_work.stk_class%TYPE,
                -- 最終修正場所区分
      last_modify_site_class       xxcos_edi_delivery_work.last_modify_site_class%TYPE,
                -- 帳票区分
      report_class                 xxcos_edi_delivery_work.report_class%TYPE,
                -- 追加・計画区分
      addition_plan_class          xxcos_edi_delivery_work.addition_plan_class%TYPE,
                -- 登録区分
      registration_class           xxcos_edi_delivery_work.registration_class%TYPE,
                -- 特定区分
      specific_class               xxcos_edi_delivery_work.specific_class%TYPE,
                -- 取引区分
      dealings_class               xxcos_edi_delivery_work.dealings_class%TYPE,
                -- 発注区分
      order_class                  xxcos_edi_delivery_work.order_class%TYPE,
                -- 集計明細区分
      sum_line_class               xxcos_edi_delivery_work.sum_line_class%TYPE,
                -- 出荷案内以外区分
      shipping_guidance_class      xxcos_edi_delivery_work.shipping_guidance_class%TYPE,
                -- 出荷区分
      shipping_class               xxcos_edi_delivery_work.shipping_class%TYPE,
                -- 商品コード使用区分
      product_code_use_class       xxcos_edi_delivery_work.product_code_use_class%TYPE,
                -- 積送品区分
      cargo_item_class             xxcos_edi_delivery_work.cargo_item_class%TYPE,
                -- Ｔ／Ａ区分
      ta_class                     xxcos_edi_delivery_work.ta_class%TYPE,
                -- 企画コード
      plan_code                    xxcos_edi_delivery_work.plan_code%TYPE,
                -- カテゴリーコード
      category_code                xxcos_edi_delivery_work.category_code%TYPE,
                -- カテゴリー区分
      category_class               xxcos_edi_delivery_work.category_class%TYPE,
                -- 運送手段
      carrier_means                xxcos_edi_delivery_work.carrier_means%TYPE,
                -- 売場コード
      counter_code                 xxcos_edi_delivery_work.counter_code%TYPE,
                -- 移動サイン
      move_sign                    xxcos_edi_delivery_work.move_sign%TYPE,
                -- ＥＯＳ・手書区分
      eos_handwriting_class        xxcos_edi_delivery_work.eos_handwriting_class%TYPE,
                -- 納品先課コード
      delivery_to_section_code     xxcos_edi_delivery_work.delivery_to_section_code%TYPE,
                -- 伝票内訳
      invoice_detailed             xxcos_edi_delivery_work.invoice_detailed%TYPE,
                -- 添付数
      attach_qty                   xxcos_edi_delivery_work.attach_qty%TYPE,
                -- フロア
      other_party_floor            xxcos_edi_delivery_work.other_party_floor%TYPE,
                -- ＴＥＸＴＮｏ
      text_no                      xxcos_edi_delivery_work.text_no%TYPE,
                -- インストアコード
      in_store_code                xxcos_edi_delivery_work.in_store_code%TYPE,
                -- タグ
      tag_data                     xxcos_edi_delivery_work.tag_data%TYPE,
                -- 競合
      competition_code             xxcos_edi_delivery_work.competition_code%TYPE,
                -- 請求口座
      billing_chair                xxcos_edi_delivery_work.billing_chair%TYPE,
                -- チェーンストアーコード
      chain_store_code             xxcos_edi_delivery_work.chain_store_code%TYPE,
                -- チェーンストアーコード略式名称
      chain_store_short_name       xxcos_edi_delivery_work.chain_store_short_name%TYPE,
                -- 直配送／引取料
      direct_delivery_rcpt_fee     xxcos_edi_delivery_work.direct_delivery_rcpt_fee%TYPE,
                -- 手形情報
      bill_info                    xxcos_edi_delivery_work.bill_info%TYPE,
                -- 摘要
      description                  xxcos_edi_delivery_work.description%TYPE,
                -- 内部コード
      interior_code                xxcos_edi_delivery_work.interior_code%TYPE,
                -- 発注情報　納品カテゴリー
      order_info_delivery_category xxcos_edi_delivery_work.order_info_delivery_category%TYPE,
                -- 仕入形態
      purchase_type                xxcos_edi_delivery_work.purchase_type%TYPE,
                -- 納品場所名（カナ）
      delivery_to_name_alt         xxcos_edi_delivery_work.delivery_to_name_alt%TYPE,
                -- 店出場所
      shop_opened_site             xxcos_edi_delivery_work.shop_opened_site%TYPE,
                -- 売場名
      counter_name                 xxcos_edi_delivery_work.counter_name%TYPE,
                -- 内線番号
      extension_number             xxcos_edi_delivery_work.extension_number%TYPE,
                -- 担当者名
      charge_name                  xxcos_edi_delivery_work.charge_name%TYPE,
                -- 値札
      price_tag                    xxcos_edi_delivery_work.price_tag%TYPE,
                -- 税種
      tax_type                     xxcos_edi_delivery_work.tax_type%TYPE,
                -- 消費税区分
      consumption_tax_class        xxcos_edi_delivery_work.consumption_tax_class%TYPE,
                -- ＢＲ
      brand_class                  xxcos_edi_delivery_work.brand_class%TYPE,
                -- ＩＤコード
      id_code                      xxcos_edi_delivery_work.id_code%TYPE,
                -- 百貨店コード
      department_code              xxcos_edi_delivery_work.department_code%TYPE,
                -- 百貨店名
      department_name              xxcos_edi_delivery_work.department_name%TYPE,
                -- 品別番号
      item_type_number             xxcos_edi_delivery_work.item_type_number%TYPE,
                -- 摘要（百貨店）
      description_department       xxcos_edi_delivery_work.description_department%TYPE,
                -- 値札方法
      price_tag_method             xxcos_edi_delivery_work.price_tag_method%TYPE,
                -- 自由欄
      reason_column                xxcos_edi_delivery_work.reason_column%TYPE,
                -- Ａ欄ヘッダ
      a_column_header              xxcos_edi_delivery_work.a_column_header%TYPE,
                -- Ｄ欄ヘッダ
      d_column_header              xxcos_edi_delivery_work.d_column_header%TYPE,
                -- ブランドコード
      brand_code                   xxcos_edi_delivery_work.brand_code%TYPE,
                -- ラインコード
      line_code                    xxcos_edi_delivery_work.line_code%TYPE,
                -- クラスコード
      class_code                   xxcos_edi_delivery_work.class_code%TYPE,
                -- Ａ－１欄
      a1_column                    xxcos_edi_delivery_work.a1_column%TYPE,
                -- Ｂ－１欄
      b1_column                    xxcos_edi_delivery_work.b1_column%TYPE,
                -- Ｃ－１欄
      c1_column                    xxcos_edi_delivery_work.c1_column%TYPE,
                -- Ｄ－１欄
      d1_column                    xxcos_edi_delivery_work.d1_column%TYPE,
                -- Ｅ－１欄
      e1_column                    xxcos_edi_delivery_work.e1_column%TYPE,
                -- Ａ－２欄
      a2_column                    xxcos_edi_delivery_work.a2_column%TYPE,
                -- Ｂ－２欄
      b2_column                    xxcos_edi_delivery_work.b2_column%TYPE,
                -- Ｃ－２欄
      c2_column                    xxcos_edi_delivery_work.c2_column%TYPE,
                -- Ｄ－２欄
      d2_column                    xxcos_edi_delivery_work.d2_column%TYPE,
                -- Ｅ－２欄
      e2_column                    xxcos_edi_delivery_work.e2_column%TYPE,
                -- Ａ－３欄
      a3_column                    xxcos_edi_delivery_work.a3_column%TYPE,
                -- Ｂ－３欄
      b3_column                    xxcos_edi_delivery_work.b3_column%TYPE,
                -- Ｃ－３欄
      c3_column                    xxcos_edi_delivery_work.c3_column%TYPE,
                -- Ｄ－３欄
      d3_column                    xxcos_edi_delivery_work.d3_column%TYPE,
                -- Ｅ－３欄
      e3_column                    xxcos_edi_delivery_work.e3_column%TYPE,
                -- Ｆ－１欄
      f1_column                    xxcos_edi_delivery_work.f1_column%TYPE,
                -- Ｇ－１欄
      g1_column                    xxcos_edi_delivery_work.g1_column%TYPE,
                -- Ｈ－１欄
      h1_column                    xxcos_edi_delivery_work.h1_column%TYPE,
                -- Ｉ－１欄
      i1_column                    xxcos_edi_delivery_work.i1_column%TYPE,
                -- Ｊ－１欄
      j1_column                    xxcos_edi_delivery_work.j1_column%TYPE,
                -- Ｋ－１欄
      k1_column                    xxcos_edi_delivery_work.k1_column%TYPE,
                -- Ｌ－１欄
      l1_column                    xxcos_edi_delivery_work.l1_column%TYPE,
                -- Ｆ－２欄
      f2_column                    xxcos_edi_delivery_work.f2_column%TYPE,
                -- Ｇ－２欄
      g2_column                    xxcos_edi_delivery_work.g2_column%TYPE,
                -- Ｈ－２欄
      h2_column                    xxcos_edi_delivery_work.h2_column%TYPE,
                -- Ｉ－２欄
      i2_column                    xxcos_edi_delivery_work.i2_column%TYPE,
                -- Ｊ－２欄
      j2_column                    xxcos_edi_delivery_work.j2_column%TYPE,
                -- Ｋ－２欄
      k2_column                    xxcos_edi_delivery_work.k2_column%TYPE,
                -- Ｌ－２欄
      l2_column                    xxcos_edi_delivery_work.l2_column%TYPE,
                -- Ｆ－３欄
      f3_column                    xxcos_edi_delivery_work.f3_column%TYPE,
                -- Ｇ－３欄
      g3_column                    xxcos_edi_delivery_work.g3_column%TYPE,
                -- Ｈ－３欄
      h3_column                    xxcos_edi_delivery_work.h3_column%TYPE,
                -- Ｉ－３欄
      i3_column                    xxcos_edi_delivery_work.i3_column%TYPE,
                -- Ｊ－３欄
      j3_column                    xxcos_edi_delivery_work.j3_column%TYPE,
                -- Ｋ－３欄
      k3_column                    xxcos_edi_delivery_work.k3_column%TYPE,
                -- Ｌ－３欄
      l3_column                    xxcos_edi_delivery_work.l3_column%TYPE,
                -- チェーン店固有エリア（ヘッダー）
      chain_peculiar_area_header   xxcos_edi_delivery_work.chain_peculiar_area_header%TYPE,
                -- 受注関連番号（仮）
      order_connection_number      xxcos_edi_delivery_work.order_connection_number%TYPE,
                -- 行Ｎｏ
      line_no                      xxcos_edi_delivery_work.line_no%TYPE,
                -- 欠品区分
      stockout_class               xxcos_edi_delivery_work.stockout_class%TYPE,
                -- 欠品理由
      stockout_reason              xxcos_edi_delivery_work.stockout_reason%TYPE,
                -- 商品コード（伊藤園）
      product_code_itouen          xxcos_edi_delivery_work.product_code_itouen%TYPE,
                -- 商品コード１
      product_code1                xxcos_edi_delivery_work.product_code1%TYPE,
                -- 商品コード２
      product_code2                xxcos_edi_delivery_work.product_code2%TYPE,
                -- ＪＡＮコード
      jan_code                     xxcos_edi_delivery_work.jan_code%TYPE,
                -- ＩＴＦコード
      itf_code                     xxcos_edi_delivery_work.itf_code%TYPE,
                -- 内箱ＩＴＦコード
      extension_itf_code           xxcos_edi_delivery_work.extension_itf_code%TYPE,
                -- ケース商品コード
      case_product_code            xxcos_edi_delivery_work.case_product_code%TYPE,
                -- ボール商品コード
      ball_product_code            xxcos_edi_delivery_work.ball_product_code%TYPE,
                -- 商品コード品種
      product_code_item_type       xxcos_edi_delivery_work.product_code_item_type%TYPE,
                -- 商品区分
      prod_class                   xxcos_edi_delivery_work.prod_class%TYPE,
                -- 商品名（漢字）
      product_name                 xxcos_edi_delivery_work.product_name%TYPE,
                -- 商品名１（カナ）
      product_name1_alt            xxcos_edi_delivery_work.product_name1_alt%TYPE,
                -- 商品名２（カナ）
      product_name2_alt            xxcos_edi_delivery_work.product_name2_alt%TYPE,
                -- 規格１
      item_standard1               xxcos_edi_delivery_work.item_standard1%TYPE,
                -- 規格２
      item_standard2               xxcos_edi_delivery_work.item_standard2%TYPE,
                -- 入数
      qty_in_case                  xxcos_edi_delivery_work.qty_in_case%TYPE,
                -- ケース入数
      num_of_cases                 xxcos_edi_delivery_work.num_of_cases%TYPE,
                -- ボール入数
      num_of_ball                  xxcos_edi_delivery_work.num_of_ball%TYPE,
                -- 色
      item_color                   xxcos_edi_delivery_work.item_color%TYPE,
                -- サイズ
      item_size                    xxcos_edi_delivery_work.item_size%TYPE,
                -- 賞味期限日
      expiration_date              xxcos_edi_delivery_work.expiration_date%TYPE,
                -- 製造日
      product_date                 xxcos_edi_delivery_work.product_date%TYPE,
                -- 発注単位数
      order_uom_qty                xxcos_edi_delivery_work.order_uom_qty%TYPE,
                -- 出荷単位数
      shipping_uom_qty             xxcos_edi_delivery_work.shipping_uom_qty%TYPE,
                -- 梱包単位数
      packing_uom_qty              xxcos_edi_delivery_work.packing_uom_qty%TYPE,
                -- 引合
      deal_code                    xxcos_edi_delivery_work.deal_code%TYPE,
                -- 引合区分
      deal_class                   xxcos_edi_delivery_work.deal_class%TYPE,
                -- 照合
      collation_code               xxcos_edi_delivery_work.collation_code%TYPE,
                -- 単位
      uom_code                     xxcos_edi_delivery_work.uom_code%TYPE,
                -- 単価区分
      unit_price_class             xxcos_edi_delivery_work.unit_price_class%TYPE,
                -- 親梱包番号
      parent_packing_number        xxcos_edi_delivery_work.parent_packing_number%TYPE,
                -- 梱包番号
      packing_number               xxcos_edi_delivery_work.packing_number%TYPE,
                -- 商品群コード
      product_group_code           xxcos_edi_delivery_work.product_group_code%TYPE,
                -- ケース解体不可フラグ
      case_dismantle_flag          xxcos_edi_delivery_work.case_dismantle_flag%TYPE,
                -- ケース区分
      case_class                   xxcos_edi_delivery_work.case_class%TYPE,
                -- 発注数量（バラ）
      indv_order_qty               xxcos_edi_delivery_work.indv_order_qty%TYPE,
                -- 発注数量（ケース）
      case_order_qty               xxcos_edi_delivery_work.case_order_qty%TYPE,
                -- 発注数量（ボール）
      ball_order_qty               xxcos_edi_delivery_work.ball_order_qty%TYPE,
                -- 発注数量（合計、バラ）
      sum_order_qty                xxcos_edi_delivery_work.sum_order_qty%TYPE,
                -- 出荷数量（バラ）
      indv_shipping_qty            xxcos_edi_delivery_work.indv_shipping_qty%TYPE,
                -- 出荷数量（ケース）
      case_shipping_qty            xxcos_edi_delivery_work.case_shipping_qty%TYPE,
                -- 出荷数量（ボール）
      ball_shipping_qty            xxcos_edi_delivery_work.ball_shipping_qty%TYPE,
                -- 出荷数量（パレット）
      pallet_shipping_qty          xxcos_edi_delivery_work.pallet_shipping_qty%TYPE,
                -- 出荷数量（合計、バラ）
      sum_shipping_qty             xxcos_edi_delivery_work.sum_shipping_qty%TYPE,
                -- 欠品数量（バラ）
      indv_stockout_qty            xxcos_edi_delivery_work.indv_stockout_qty%TYPE,
                -- 欠品数量（ケース）
      case_stockout_qty            xxcos_edi_delivery_work.case_stockout_qty%TYPE,
                -- 欠品数量（ボール）
      ball_stockout_qty            xxcos_edi_delivery_work.ball_stockout_qty%TYPE,
                -- 欠品数量（合計、バラ）
      sum_stockout_qty             xxcos_edi_delivery_work.sum_stockout_qty%TYPE,
                -- ケース個口数
      case_qty                     xxcos_edi_delivery_work.case_qty%TYPE,
                -- オリコン（バラ）個口数
      fold_container_indv_qty      xxcos_edi_delivery_work.fold_container_indv_qty%TYPE,
                -- 原単価（発注）
      order_unit_price             xxcos_edi_delivery_work.order_unit_price%TYPE,
                -- 原単価（出荷）
      shipping_unit_price          xxcos_edi_delivery_work.shipping_unit_price%TYPE,
                -- 原価金額（発注）
      order_cost_amt               xxcos_edi_delivery_work.order_cost_amt%TYPE,
                -- 原価金額（出荷）
      shipping_cost_amt            xxcos_edi_delivery_work.shipping_cost_amt%TYPE,
                -- 原価金額（欠品）
      stockout_cost_amt            xxcos_edi_delivery_work.stockout_cost_amt%TYPE,
                -- 売単価
      selling_price                xxcos_edi_delivery_work.selling_price%TYPE,
                -- 売価金額（発注）
      order_price_amt              xxcos_edi_delivery_work.order_price_amt%TYPE,
                -- 売価金額（出荷）
      shipping_price_amt           xxcos_edi_delivery_work.shipping_price_amt%TYPE,
                -- 売価金額（欠品）
      stockout_price_amt           xxcos_edi_delivery_work.stockout_price_amt%TYPE,
                -- Ａ欄（百貨店）
      a_column_department          xxcos_edi_delivery_work.a_column_department%TYPE,
                -- Ｄ欄（百貨店）
      d_column_department          xxcos_edi_delivery_work.d_column_department%TYPE,
                -- 規格情報・奥行き
      standard_info_depth          xxcos_edi_delivery_work.standard_info_depth%TYPE,
                -- 規格情報・高さ
      standard_info_height         xxcos_edi_delivery_work.standard_info_height%TYPE,
                -- 規格情報・幅
      standard_info_width          xxcos_edi_delivery_work.standard_info_width%TYPE,
                -- 規格情報・重量
      standard_info_weight         xxcos_edi_delivery_work.standard_info_weight%TYPE,
                -- 汎用引継ぎ項目１
      general_succeeded_item1      xxcos_edi_delivery_work.general_succeeded_item1%TYPE,
                -- 汎用引継ぎ項目２
      general_succeeded_item2      xxcos_edi_delivery_work.general_succeeded_item2%TYPE,
                -- 汎用引継ぎ項目３
      general_succeeded_item3      xxcos_edi_delivery_work.general_succeeded_item3%TYPE,
                -- 汎用引継ぎ項目４
      general_succeeded_item4      xxcos_edi_delivery_work.general_succeeded_item4%TYPE,
                -- 汎用引継ぎ項目５
      general_succeeded_item5      xxcos_edi_delivery_work.general_succeeded_item5%TYPE,
                -- 汎用引継ぎ項目６
      general_succeeded_item6      xxcos_edi_delivery_work.general_succeeded_item6%TYPE,
                -- 汎用引継ぎ項目７
      general_succeeded_item7      xxcos_edi_delivery_work.general_succeeded_item7%TYPE,
                -- 汎用引継ぎ項目８
      general_succeeded_item8      xxcos_edi_delivery_work.general_succeeded_item8%TYPE,
                -- 汎用引継ぎ項目９
      general_succeeded_item9      xxcos_edi_delivery_work.general_succeeded_item9%TYPE,
                -- 汎用引継ぎ項目１０
      general_succeeded_item10     xxcos_edi_delivery_work.general_succeeded_item10%TYPE,
                -- 汎用付加項目１
      general_add_item1            xxcos_edi_delivery_work.general_add_item1%TYPE,
                -- 汎用付加項目２
      general_add_item2            xxcos_edi_delivery_work.general_add_item2%TYPE,
                -- 汎用付加項目３
      general_add_item3            xxcos_edi_delivery_work.general_add_item3%TYPE,
                -- 汎用付加項目４
      general_add_item4            xxcos_edi_delivery_work.general_add_item4%TYPE,
                -- 汎用付加項目５
      general_add_item5            xxcos_edi_delivery_work.general_add_item5%TYPE,
                -- 汎用付加項目６
      general_add_item6            xxcos_edi_delivery_work.general_add_item6%TYPE,
                -- 汎用付加項目７
      general_add_item7            xxcos_edi_delivery_work.general_add_item7%TYPE,
                -- 汎用付加項目８
      general_add_item8            xxcos_edi_delivery_work.general_add_item8%TYPE,
                -- 汎用付加項目９
      general_add_item9            xxcos_edi_delivery_work.general_add_item9%TYPE,
                -- 汎用付加項目１０
      general_add_item10           xxcos_edi_delivery_work.general_add_item10%TYPE,
                -- チェーン店固有エリア（明細）
      chain_peculiar_area_line     xxcos_edi_delivery_work.chain_peculiar_area_line%TYPE,
                -- （伝票計）発注数量（バラ）
      invoice_indv_order_qty       xxcos_edi_delivery_work.invoice_indv_order_qty%TYPE,
                -- （伝票計）発注数量（ケース）
      invoice_case_order_qty       xxcos_edi_delivery_work.invoice_case_order_qty%TYPE,
                -- （伝票計）発注数量（ボール）
      invoice_ball_order_qty       xxcos_edi_delivery_work.invoice_ball_order_qty%TYPE,
                -- （伝票計）発注数量（合計、バラ）
      invoice_sum_order_qty        xxcos_edi_delivery_work.invoice_sum_order_qty%TYPE,
                -- （伝票計）出荷数量（バラ）
      invoice_indv_shipping_qty    xxcos_edi_delivery_work.invoice_indv_shipping_qty%TYPE,
                -- （伝票計）出荷数量（ケース）
      invoice_case_shipping_qty    xxcos_edi_delivery_work.invoice_case_shipping_qty%TYPE,
                -- （伝票計）出荷数量（ボール）
      invoice_ball_shipping_qty    xxcos_edi_delivery_work.invoice_ball_shipping_qty%TYPE,
                -- （伝票計）出荷数量（パレット）
      invoice_pallet_shipping_qty  xxcos_edi_delivery_work.invoice_pallet_shipping_qty%TYPE,
                -- （伝票計）出荷数量（合計、バラ）
      invoice_sum_shipping_qty     xxcos_edi_delivery_work.invoice_sum_shipping_qty%TYPE,
                -- （伝票計）欠品数量（バラ）
      invoice_indv_stockout_qty    xxcos_edi_delivery_work.invoice_indv_stockout_qty%TYPE,
                -- （伝票計）欠品数量（ケース）
      invoice_case_stockout_qty    xxcos_edi_delivery_work.invoice_case_stockout_qty%TYPE,
                -- （伝票計）欠品数量（ボール）
      invoice_ball_stockout_qty    xxcos_edi_delivery_work.invoice_ball_stockout_qty%TYPE,
                -- （伝票計）欠品数量（合計、バラ）
      invoice_sum_stockout_qty     xxcos_edi_delivery_work.invoice_sum_stockout_qty%TYPE,
                -- （伝票計）ケース個口数
      invoice_case_qty             xxcos_edi_delivery_work.invoice_case_qty%TYPE,
                -- （伝票計）オリコン（バラ）個口数
      invoice_fold_container_qty   xxcos_edi_delivery_work.invoice_fold_container_qty%TYPE,
                -- （伝票計）原価金額（発注）
      invoice_order_cost_amt       xxcos_edi_delivery_work.invoice_order_cost_amt%TYPE,
                -- （伝票計）原価金額（出荷）
      invoice_shipping_cost_amt    xxcos_edi_delivery_work.invoice_shipping_cost_amt%TYPE,
                -- （伝票計）原価金額（欠品）
      invoice_stockout_cost_amt    xxcos_edi_delivery_work.invoice_stockout_cost_amt%TYPE,
                -- （伝票計）売価金額（発注）
      invoice_order_price_amt      xxcos_edi_delivery_work.invoice_order_price_amt%TYPE,
                -- （伝票計）売価金額（出荷）
      invoice_shipping_price_amt   xxcos_edi_delivery_work.invoice_shipping_price_amt%TYPE,
                -- （伝票計）売価金額（欠品）
      invoice_stockout_price_amt   xxcos_edi_delivery_work.invoice_stockout_price_amt%TYPE,
                -- （総合計）発注数量（バラ）
      total_indv_order_qty         xxcos_edi_delivery_work.total_indv_order_qty%TYPE,
                -- （総合計）発注数量（ケース）
      total_case_order_qty         xxcos_edi_delivery_work.total_case_order_qty%TYPE,
                -- （総合計）発注数量（ボール）
      total_ball_order_qty         xxcos_edi_delivery_work.total_ball_order_qty%TYPE,
                -- （総合計）発注数量（合計、バラ）
      total_sum_order_qty          xxcos_edi_delivery_work.total_sum_order_qty%TYPE,
                -- （総合計）出荷数量（バラ）
      total_indv_shipping_qty      xxcos_edi_delivery_work.total_indv_shipping_qty%TYPE,
                -- （総合計）出荷数量（ケース）
      total_case_shipping_qty      xxcos_edi_delivery_work.total_case_shipping_qty%TYPE,
                -- （総合計）出荷数量（ボール）
      total_ball_shipping_qty      xxcos_edi_delivery_work.total_ball_shipping_qty%TYPE,
                -- （総合計）出荷数量（パレット）
      total_pallet_shipping_qty    xxcos_edi_delivery_work.total_pallet_shipping_qty%TYPE,
                -- （総合計）出荷数量（合計、バラ）
      total_sum_shipping_qty       xxcos_edi_delivery_work.total_sum_shipping_qty%TYPE,
                -- （総合計）欠品数量（バラ）
      total_indv_stockout_qty      xxcos_edi_delivery_work.total_indv_stockout_qty%TYPE,
                -- （総合計）欠品数量（ケース）
      total_case_stockout_qty      xxcos_edi_delivery_work.total_case_stockout_qty%TYPE,
                -- （総合計）欠品数量（ボール）
      total_ball_stockout_qty      xxcos_edi_delivery_work.total_ball_stockout_qty%TYPE,
                -- （総合計）欠品数量（合計、バラ）
      total_sum_stockout_qty       xxcos_edi_delivery_work.total_sum_stockout_qty%TYPE,
                -- （総合計）ケース個口数
      total_case_qty               xxcos_edi_delivery_work.total_case_qty%TYPE,
                -- （総合計）オリコン（バラ）個口数
      total_fold_container_qty     xxcos_edi_delivery_work.total_fold_container_qty%TYPE,
                -- （総合計）原価金額（発注）
      total_order_cost_amt         xxcos_edi_delivery_work.total_order_cost_amt%TYPE,
                -- （総合計）原価金額（出荷）
      total_shipping_cost_amt      xxcos_edi_delivery_work.total_shipping_cost_amt%TYPE,
                -- （総合計）原価金額（欠品）
      total_stockout_cost_amt      xxcos_edi_delivery_work.total_stockout_cost_amt%TYPE,
                -- （総合計）売価金額（発注）
      total_order_price_amt        xxcos_edi_delivery_work.total_order_price_amt%TYPE,
                -- （総合計）売価金額（出荷）
      total_shipping_price_amt     xxcos_edi_delivery_work.total_shipping_price_amt%TYPE,
                -- （総合計）売価金額（欠品）
      total_stockout_price_amt     xxcos_edi_delivery_work.total_stockout_price_amt%TYPE,
                -- トータル行数
      total_line_qty               xxcos_edi_delivery_work.total_line_qty%TYPE,
                -- トータル伝票枚数
      total_invoice_qty            xxcos_edi_delivery_work.total_invoice_qty%TYPE,
                -- チェーン店固有エリア（フッター）
      chain_peculiar_area_footer   xxcos_edi_delivery_work.chain_peculiar_area_footer%TYPE,
               --ステータス
      err_status                   xxcos_edi_delivery_work.err_status%TYPE,
               -- インタフェースファイル名
/* 2011/07/26 Ver1.9 Mod Start */
--      if_file_name                 xxcos_edi_delivery_work.if_file_name%TYPE
      if_file_name                 xxcos_edi_delivery_work.if_file_name%TYPE,
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
               -- 流通ＢＭＳヘッダデータ
      bms_header_data              xxcos_edi_delivery_work.bms_header_data%TYPE,
               -- 流通ＢＭＳ明細データ
      bms_line_data                xxcos_edi_delivery_work.bms_line_data%TYPE
/* 2011/07/26 Ver1.9 Add End   */
    );
  --
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  TYPE g_tab_edideli_work_data IS TABLE OF g_rec_edideli_work_data INDEX BY PLS_INTEGER;
  -- ===============================
  --  EDI納品返品情報ワークテーブル
  -- ===============================
  gt_edideli_work_data                 g_tab_edideli_work_data;
  -- ===============================
  -- エラーEDI納品返品情報ワークレコード型
  -- ===============================
  TYPE g_rec_err_edi_wk_data_rtype IS RECORD(
                -- 納品返品ワークID
      delivery_return_work_id      xxcos_edi_delivery_work.delivery_return_work_id%TYPE,
                --ステータス
      err_status1                  xxcos_edi_delivery_work.err_status%TYPE,
                --ステータス
      err_status2                  xxcos_edi_delivery_work.err_status%TYPE,
                -- ユーザー・エラー・メッセージ
      errmsg1                      VARCHAR2(5000),
                -- ユーザー・エラー・メッセージ
      errmsg2                      VARCHAR2(5000)
    );
  -- ===============================
  -- エラーEDI納品返品情報ワーク
  -- ===============================
  TYPE g_rec_err_edi_wk_data_ttype IS TABLE OF g_rec_err_edi_wk_data_rtype INDEX BY BINARY_INTEGER;
  gt_err_edideli_work_data  g_rec_err_edi_wk_data_ttype;
  --
  --
  -- ===============================
  -- 顧客データレコード型
  -- ===============================
  TYPE g_req_cust_acc_data_rtype IS RECORD(
       account_number    hz_cust_accounts.account_number%TYPE,       -- 顧客マスタ.顧客コード
       price_list_id     hz_cust_site_uses_all.price_list_id%TYPE,   -- 価格表ID
       chain_store_code  xxcmm_cust_accounts.chain_store_code%TYPE,  -- チェーン店コード(EDI)
       store_code        xxcmm_cust_accounts.store_code%TYPE,        -- 店舗コード
       edi_item_code_div xxcmm_cust_accounts.edi_item_code_div%TYPE  -- EDI連携品目コード区分
    );
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  -- 顧客データ テーブル型
  -- ===============================
  TYPE g_req_cust_acc_data_ttype IS TABLE OF g_req_cust_acc_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_cust_acc_data  g_req_cust_acc_data_ttype;
  --* -------------------------------------------------------------------------------------------
  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_prf_edi_del_date       VARCHAR2(50) DEFAULT NULL;  -- XXCOS:EDI情報削除期間
  gv_prf_case_code          VARCHAR2(50) DEFAULT NULL;  -- XXCOS:ケース単位コード
  gv_prf_orga_code          VARCHAR2(50) DEFAULT NULL;  -- XXCOI:在庫組織コード
  gv_prf_orga_id            VARCHAR2(50) DEFAULT NULL;  -- XXCOS:在庫組織ID
  gt_head_invoice_number_key VARCHAR2(12) DEFAULT NULL;  -- 伝票番号
  gt_edi_header_info_id      NUMBER       DEFAULT 0;     -- EDIヘッダ情報ID
--****************************** 2009/06/29 1.5 T.Tominaga ADD START ******************************
  gt_head_shop_invoice_key  VARCHAR2(50) DEFAULT NULL;  -- 店コード・伝票番号 ブレイク用変数
--****************************** 2009/06/29 1.5 T.Tominaga ADD  END  ******************************
--
  --* -------------------------------------------------------------------------------------------
  -- EDIヘッダ情報テーブルデータ登録用変数(xxcos_edi_headers)
  TYPE g_req_edi_headers_data_rtype IS RECORD(
       edi_header_info_id           xxcos_edi_headers.edi_header_info_id%TYPE,   -- EDIヘッダ情報ID
       medium_class                 xxcos_edi_headers.medium_class%TYPE,         -- 媒体区分
       data_type_code               xxcos_edi_headers.data_type_code%TYPE,       -- データ種コード
       file_no                      xxcos_edi_headers.file_no%TYPE,              -- ファイルＮｏ
       info_class                   xxcos_edi_headers.info_class%TYPE,           -- 情報区分
       process_date                 xxcos_edi_headers.process_date%TYPE,         -- 処理日
       process_time                 xxcos_edi_headers.process_time%TYPE,         -- 処理時刻
       base_code                    xxcos_edi_headers.base_code%TYPE,            -- 拠点（部門）コード
       base_name                    xxcos_edi_headers.base_name%TYPE,            -- 拠点名（正式名）
       base_name_alt                xxcos_edi_headers.base_name_alt%TYPE,        -- 拠点名（カナ）
       edi_chain_code               xxcos_edi_headers.edi_chain_code%TYPE,       -- ＥＤＩチェーン店コード
       edi_chain_name               xxcos_edi_headers.edi_chain_name%TYPE,       -- ＥＤＩチェーン店名（漢字）
       edi_chain_name_alt           xxcos_edi_headers.edi_chain_name_alt%TYPE,   -- ＥＤＩチェーン店名（カナ）
       chain_code                   xxcos_edi_headers.chain_code%TYPE,           -- チェーン店コード
       chain_name                   xxcos_edi_headers.chain_name%TYPE,           -- チェーン店名（漢字）
       chain_name_alt               xxcos_edi_headers.chain_name_alt%TYPE,       -- チェーン店名（カナ）
       report_code                  xxcos_edi_headers.report_code%TYPE,          -- 帳票コード
       report_show_name             xxcos_edi_headers.report_show_name%TYPE,     -- 帳票表示名
       customer_code                xxcos_edi_headers.customer_code%TYPE,        -- 顧客コード
       customer_name                xxcos_edi_headers.customer_name%TYPE,        -- 顧客名（漢字）
       customer_name_alt            xxcos_edi_headers.customer_name_alt%TYPE,    -- 顧客名（カナ）
       company_code                 xxcos_edi_headers.company_code%TYPE,         -- 社コード
       company_name                 xxcos_edi_headers.company_name%TYPE,         -- 社名（漢字）
       company_name_alt             xxcos_edi_headers.company_name_alt%TYPE,     -- 社名（カナ）
       shop_code                    xxcos_edi_headers.shop_code%TYPE,            -- 店コード
       shop_name                    xxcos_edi_headers.shop_name%TYPE,            -- 店名（漢字）
       shop_name_alt                xxcos_edi_headers.shop_name_alt%TYPE,        -- 店名（カナ）
                                                                                 -- 納入センターコード
       deli_center_code             xxcos_edi_headers.delivery_center_code%TYPE,
                                                                                 -- 納入センター名（漢字）
       deli_center_name             xxcos_edi_headers.delivery_center_name%TYPE,
                                                                                 -- 納入センター名（カナ）
       deli_center_name_alt         xxcos_edi_headers.delivery_center_name_alt%TYPE,
       order_date                   xxcos_edi_headers.order_date%TYPE,           -- 発注日
                                                                                 -- センター納品日
       center_delivery_date         xxcos_edi_headers.center_delivery_date%TYPE,
       result_delivery_date         xxcos_edi_headers.result_delivery_date%TYPE, -- 実納品日
       shop_delivery_date           xxcos_edi_headers.shop_delivery_date%TYPE,   -- 店舗納品日
                                                                          -- データ作成日（ＥＤＩデータ中）
       data_cd_edi_data             xxcos_edi_headers.data_creation_date_edi_data%TYPE,
                                                                          -- データ作成時刻（ＥＤＩデータ中）
       data_ct_edi_data             xxcos_edi_headers.data_creation_time_edi_data%TYPE,
       invoice_class                xxcos_edi_headers.invoice_class%TYPE,          -- 伝票区分
                                                                                   -- 小分類コード
       small_class_cd               xxcos_edi_headers.small_classification_code%TYPE,
                                                                                   -- 小分類名
       small_class_nm               xxcos_edi_headers.small_classification_name%TYPE,
                                                                                   -- 中分類コード
       mid_class_cd                 xxcos_edi_headers.middle_classification_code%TYPE,
                                                                                   -- 中分類名
       mid_class_nm                 xxcos_edi_headers.middle_classification_name%TYPE,
                                                                                   -- 大分類コード
       big_class_cd                 xxcos_edi_headers.big_classification_code%TYPE,
                                                                                   -- 大分類名
       big_class_nm                 xxcos_edi_headers.big_classification_name%TYPE,
                                                                                   -- 相手先部門コード
       other_par_dep_cd             xxcos_edi_headers.other_party_department_code%TYPE,
                                                                                   -- 相手先発注番号
       other_par_order_num          xxcos_edi_headers.other_party_order_number%TYPE,
                                                                                -- チェックデジット有無区分
       check_digit_class            xxcos_edi_headers.check_digit_class%TYPE,
       invoice_number               xxcos_edi_headers.invoice_number%TYPE,       -- 伝票番号
       check_digit                  xxcos_edi_headers.check_digit%TYPE,          -- チェックデジット
       close_date                   xxcos_edi_headers.close_date%TYPE,           -- 月限
       order_no_ebs                 xxcos_edi_headers.order_no_ebs%TYPE,         -- 受注Ｎｏ（ＥＢＳ）
       ar_sale_class                xxcos_edi_headers.ar_sale_class%TYPE,        -- 特売区分
       delivery_classe              xxcos_edi_headers.delivery_classe%TYPE,      -- 配送区分
       opportunity_no               xxcos_edi_headers.opportunity_no%TYPE,       -- 便Ｎｏ
       contact_to                   xxcos_edi_headers.contact_to%TYPE,           -- 連絡先
       route_sales                  xxcos_edi_headers.route_sales%TYPE,          -- ルートセールス
       corporate_code               xxcos_edi_headers.corporate_code%TYPE,       -- 法人コード
       maker_name                   xxcos_edi_headers.maker_name%TYPE,           -- メーカー名
       area_code                    xxcos_edi_headers.area_code%TYPE,            -- 地区コード
       area_name                    xxcos_edi_headers.area_name%TYPE,            -- 地区名（漢字）
       area_name_alt                xxcos_edi_headers.area_name_alt%TYPE,        -- 地区名（カナ）
       vendor_code                  xxcos_edi_headers.vendor_code%TYPE,          -- 取引先コード
       vendor_name                  xxcos_edi_headers.vendor_name%TYPE,          -- 取引先名（漢字）
       vendor_name1_alt             xxcos_edi_headers.vendor_name1_alt%TYPE,     -- 取引先名１（カナ）
       vendor_name2_alt             xxcos_edi_headers.vendor_name2_alt%TYPE,     -- 取引先名２（カナ）
       vendor_tel                   xxcos_edi_headers.vendor_tel%TYPE,           -- 取引先ＴＥＬ
       vendor_charge                xxcos_edi_headers.vendor_charge%TYPE,        -- 取引先担当者
       vendor_address               xxcos_edi_headers.vendor_address%TYPE,       -- 取引先住所（漢字）
                                                                                   -- 届け先コード（伊藤園）
       deli_to_cd_itouen            xxcos_edi_headers.deliver_to_code_itouen%TYPE,
                                                                                   -- 届け先コード（チェーン店）
       deli_to_cd_chain             xxcos_edi_headers.deliver_to_code_chain%TYPE,
       deli_to                      xxcos_edi_headers.deliver_to%TYPE,           -- 届け先（漢字）
       deli_to1_alt                 xxcos_edi_headers.deliver_to1_alt%TYPE,      -- 届け先１（カナ）
       deli_to2_alt                 xxcos_edi_headers.deliver_to2_alt%TYPE,      -- 届け先２（カナ）
       deli_to_add                  xxcos_edi_headers.vendor_address%TYPE,       -- 届け先住所（漢字）
       deli_to_add_alt              xxcos_edi_headers.deliver_to_address_alt%TYPE, -- 届け先住所（カナ）
       deli_to_tel                  xxcos_edi_headers.deliver_to_tel%TYPE,       -- 届け先ＴＥＬ
                                                                                   -- 帳合先コード
       bal_accounts_cd              xxcos_edi_headers.balance_accounts_code%TYPE,
                                                                                   -- 帳合先社コード
       bal_acc_comp_cd              xxcos_edi_headers.balance_accounts_company_code%TYPE,
                                                                                   -- 帳合先店コード
       bal_acc_shop_cd              xxcos_edi_headers.balance_accounts_shop_code%TYPE,
                                                                                   -- 帳合先名（漢字）
       bal_acc_name                 xxcos_edi_headers.balance_accounts_name%TYPE,
                                                                                   -- 帳合先名（カナ）
       bal_acc_name_alt             xxcos_edi_headers.balance_accounts_name_alt%TYPE,
                                                                                   -- 帳合先住所（漢字）
       bal_acc_add                  xxcos_edi_headers.balance_accounts_address%TYPE,
                                                                                   -- 帳合先住所（カナ）
       bal_acc_add_alt              xxcos_edi_headers.balance_accounts_address_alt%TYPE,
                                                                                   -- 帳合先ＴＥＬ
       bal_acc_tel                  xxcos_edi_headers.balance_accounts_tel%TYPE,
       order_possible_date          xxcos_edi_headers.order_possible_date%TYPE,    -- 受注可能日
                                                                                   -- 許容可能日
       perm_poss_date               xxcos_edi_headers.permission_possible_date%TYPE,
       forward_month                xxcos_edi_headers.forward_month%TYPE,          -- 先限年月日
                                                                                   -- 支払決済日
       pay_settl_date               xxcos_edi_headers.payment_settlement_date%TYPE,
                                                                                   -- チラシ開始日
       hand_st_date_act             xxcos_edi_headers.handbill_start_date_active%TYPE,
       billing_due_date             xxcos_edi_headers.billing_due_date%TYPE,     -- 請求締日
       shipping_time                xxcos_edi_headers.shipping_time%TYPE,        -- 出荷時刻
       deli_schedule_time           xxcos_edi_headers.delivery_schedule_time%TYPE, -- 納品予定時間
       order_time                   xxcos_edi_headers.order_time%TYPE,           -- 発注時間
       general_date_item1           xxcos_edi_headers.general_date_item1%TYPE,   -- 汎用日付項目１
       general_date_item2           xxcos_edi_headers.general_date_item2%TYPE,   -- 汎用日付項目２
       general_date_item3           xxcos_edi_headers.general_date_item3%TYPE,   -- 汎用日付項目３
       general_date_item4           xxcos_edi_headers.general_date_item4%TYPE,   -- 汎用日付項目４
       general_date_item5           xxcos_edi_headers.general_date_item5%TYPE,   -- 汎用日付項目５
       arr_shipping_class           xxcos_edi_headers.arrival_shipping_class%TYPE, -- 入出荷区分
       vendor_class                 xxcos_edi_headers.vendor_class%TYPE,         -- 取引先区分
       inv_detailed_class           xxcos_edi_headers.invoice_detailed_class%TYPE,   -- 伝票内訳区分
       unit_price_use_class         xxcos_edi_headers.unit_price_use_class%TYPE, -- 単価使用区分
                                                                            -- サブ物流センターコード
       sub_dist_center_cd           xxcos_edi_headers.sub_distribution_center_name%TYPE,
                                                                            -- サブ物流センターコード名
       sub_dist_center_nm           xxcos_edi_headers.sub_distribution_center_name%TYPE,
       center_deli_method           xxcos_edi_headers.center_delivery_method%TYPE, -- センター納品方法
       center_use_class             xxcos_edi_headers.center_use_class%TYPE,      -- センター利用区分
       center_whse_class            xxcos_edi_headers.center_whse_class%TYPE,     -- センター倉庫区分
       center_area_class            xxcos_edi_headers.center_area_class%TYPE,     -- センター地域区分
       center_arr_class             xxcos_edi_headers.center_arrival_class%TYPE,  -- センター入荷区分
       depot_class                  xxcos_edi_headers.depot_class%TYPE,           -- デポ区分
       tcdc_class                   xxcos_edi_headers.tcdc_class%TYPE,            -- ＴＣＤＣ区分
       upc_flag                     xxcos_edi_headers.upc_flag%TYPE,              -- ＵＰＣフラグ
       simultaneously_cls           xxcos_edi_headers.simultaneously_class%TYPE,  -- 一斉区分
       business_id                  xxcos_edi_headers.business_id%TYPE,           -- 業務ＩＤ
       whse_directly_cls            xxcos_edi_headers.whse_directly_class%TYPE,   -- 倉直区分
       premium_rebate_cls           xxcos_edi_headers.premium_rebate_class%TYPE,  -- 景品割戻区分
       item_type                    xxcos_edi_headers.item_type%TYPE,             -- 項目種別
       cloth_hous_fod_cls           xxcos_edi_headers.cloth_house_food_class%TYPE, -- 衣家食区分
       mix_class                    xxcos_edi_headers.mix_class%TYPE,             -- 混在区分
       stk_class                    xxcos_edi_headers.stk_class%TYPE,             -- 在庫区分
       last_mod_site_cls            xxcos_edi_headers.last_modify_site_class%TYPE, -- 最終修正場所区分
       report_class                 xxcos_edi_headers.report_class%TYPE,          -- 帳票区分
       add_plan_cls                 xxcos_edi_headers.addition_plan_class%TYPE,   -- 追加・計画区分
       registration_class           xxcos_edi_headers.registration_class%TYPE,    -- 登録区分
       specific_class               xxcos_edi_headers.specific_class%TYPE,        -- 特定区分
       dealings_class               xxcos_edi_headers.dealings_class%TYPE,        -- 取引区分
       order_class                  xxcos_edi_headers.order_class%TYPE,           -- 発注区分
       sum_line_class               xxcos_edi_headers.sum_line_class%TYPE,        -- 集計明細区分
       ship_guidance_cls            xxcos_edi_headers.shipping_guidance_class%TYPE, -- 出荷案内以外区分
       shipping_class               xxcos_edi_headers.shipping_class%TYPE,        -- 出荷区分
                                                                                    -- 商品コード使用区分
       prod_cd_use_cls              xxcos_edi_headers.product_code_use_class%TYPE,
       cargo_item_class             xxcos_edi_headers.cargo_item_class%TYPE,      -- 積送品区分
       ta_class                     xxcos_edi_headers.ta_class%TYPE,              -- Ｔ／Ａ区分
       plan_code                    xxcos_edi_headers.plan_code%TYPE,             -- 企画コード
       category_code                xxcos_edi_headers.category_code%TYPE,         -- カテゴリーコード
       category_class               xxcos_edi_headers.category_class%TYPE,        -- カテゴリー区分
       carrier_means                xxcos_edi_headers.carrier_means%TYPE,         -- 運送手段
       counter_code                 xxcos_edi_headers.counter_code%TYPE,          -- 売場コード
       move_sign                    xxcos_edi_headers.move_sign%TYPE,             -- 移動サイン
       eos_handwrit_cls             xxcos_edi_headers.eos_handwriting_class%TYPE, -- ＥＯＳ・手書区分
       deli_to_section_cd           xxcos_edi_headers.delivery_to_section_code%TYPE, -- 納品先課コード
       invoice_detailed             xxcos_edi_headers.invoice_detailed%TYPE,      -- 伝票内訳
       attach_qty                   xxcos_edi_headers.attach_qty%TYPE,            -- 添付数
       other_party_floor            xxcos_edi_headers.other_party_floor%TYPE,     -- フロア
       text_no                      xxcos_edi_headers.text_no%TYPE,               -- ＴＥＸＴＮｏ
       in_store_code                xxcos_edi_headers.in_store_code%TYPE,         -- インストアコード
       tag_data                     xxcos_edi_headers.tag_data%TYPE,              -- タグ
       competition_code             xxcos_edi_headers.competition_code%TYPE,      -- 競合
       billing_chair                xxcos_edi_headers.billing_chair%TYPE,         -- 請求口座
       chain_store_code             xxcos_edi_headers.chain_store_code%TYPE,      -- チェーンストアーコード
                                                                        -- チェーンストアーコード略式名称
       chain_st_sh_name             xxcos_edi_headers.chain_store_short_name%TYPE,
       dir_deli_rcpt_fee            xxcos_edi_headers.direct_delivery_rcpt_fee%TYPE, -- 直配送／引取料
       bill_info                    xxcos_edi_headers.bill_info%TYPE,              -- 手形情報
       description                  xxcos_edi_headers.description%TYPE,            -- 摘要
       interior_code                xxcos_edi_headers.interior_code%TYPE,          -- 内部コード
                                                                         -- 発注情報　納品カテゴリー
       order_in_deli_cate           xxcos_edi_headers.order_info_delivery_category%TYPE,
       purchase_type                xxcos_edi_headers.purchase_type%TYPE,          -- 仕入形態
                                                                                     -- 納品場所名（カナ）
       deli_to_name_alt             xxcos_edi_headers.delivery_to_name_alt%TYPE,
       shop_opened_site             xxcos_edi_headers.shop_opened_site%TYPE,        -- 店出場所
       counter_name                 xxcos_edi_headers.counter_name%TYPE,            -- 売場名
       extension_number             xxcos_edi_headers.extension_number%TYPE,        -- 内線番号
       charge_name                  xxcos_edi_headers.charge_name%TYPE,             -- 担当者名
       price_tag                    xxcos_edi_headers.price_tag%TYPE,               -- 値札
       tax_type                     xxcos_edi_headers.tax_type%TYPE,                -- 税種
       consump_tax_cls              xxcos_edi_headers.consumption_tax_class%TYPE,   -- 消費税区分
       brand_class                  xxcos_edi_headers.brand_class%TYPE,             -- ＢＲ
       id_code                      xxcos_edi_headers.id_code%TYPE,                 -- ＩＤコード
       department_code              xxcos_edi_headers.department_code%TYPE,         -- 百貨店コード
       department_name              xxcos_edi_headers.department_name%TYPE,         -- 百貨店名
       item_type_number             xxcos_edi_headers.item_type_number%TYPE,        -- 品別番号
       description_depart           xxcos_edi_headers.description_department%TYPE,  -- 摘要（百貨店）
       price_tag_method             xxcos_edi_headers.price_tag_method%TYPE,        -- 値札方法
       reason_column                xxcos_edi_headers.reason_column%TYPE,           -- 自由欄
       a_column_header              xxcos_edi_headers.a_column_header%TYPE,         -- Ａ欄ヘッダ
       d_column_header              xxcos_edi_headers.d_column_header%TYPE,         -- Ｄ欄ヘッダ
       brand_code                   xxcos_edi_headers.brand_code%TYPE,              -- ブランドコード
       line_code                    xxcos_edi_headers.line_code%TYPE,               -- ラインコード
       class_code                   xxcos_edi_headers.class_code%TYPE,              -- クラスコード
       a1_column                    xxcos_edi_headers.a1_column%TYPE,               -- Ａ－１欄
       b1_column                    xxcos_edi_headers.b1_column%TYPE,               -- Ｂ－１欄
       c1_column                    xxcos_edi_headers.c1_column%TYPE,               -- Ｃ－１欄
       d1_column                    xxcos_edi_headers.d1_column%TYPE,               -- Ｄ－１欄
       e1_column                    xxcos_edi_headers.e1_column%TYPE,               -- Ｅ－１欄
       a2_column                    xxcos_edi_headers.a2_column%TYPE,               -- Ａ－２欄
       b2_column                    xxcos_edi_headers.b2_column%TYPE,               -- Ｂ－２欄
       c2_column                    xxcos_edi_headers.c2_column%TYPE,               -- Ｃ－２欄
       d2_column                    xxcos_edi_headers.d2_column%TYPE,               -- Ｄ－２欄
       e2_column                    xxcos_edi_headers.e2_column%TYPE,               -- Ｅ－２欄
       a3_column                    xxcos_edi_headers.a3_column%TYPE,               -- Ａ－３欄
       b3_column                    xxcos_edi_headers.b3_column%TYPE,               -- Ｂ－３欄
       c3_column                    xxcos_edi_headers.c3_column%TYPE,               -- Ｃ－３欄
       d3_column                    xxcos_edi_headers.d3_column%TYPE,               -- Ｄ－３欄
       e3_column                    xxcos_edi_headers.e3_column%TYPE,               -- Ｅ－３欄
       f1_column                    xxcos_edi_headers.f1_column%TYPE,               -- Ｆ－１欄
       g1_column                    xxcos_edi_headers.g1_column%TYPE,               -- Ｇ－１欄
       h1_column                    xxcos_edi_headers.h1_column%TYPE,               -- Ｈ－１欄
       i1_column                    xxcos_edi_headers.i1_column%TYPE,               -- Ｉ－１欄
       j1_column                    xxcos_edi_headers.j1_column%TYPE,               -- Ｊ－１欄
       k1_column                    xxcos_edi_headers.k1_column%TYPE,               -- Ｋ－１欄
       l1_column                    xxcos_edi_headers.l1_column%TYPE,               -- Ｌ－１欄
       f2_column                    xxcos_edi_headers.f2_column%TYPE,               -- Ｆ－２欄
       g2_column                    xxcos_edi_headers.g2_column%TYPE,               -- Ｇ－２欄
       h2_column                    xxcos_edi_headers.h2_column%TYPE,               -- Ｈ－２欄
       i2_column                    xxcos_edi_headers.i2_column%TYPE,               -- Ｉ－２欄
       j2_column                    xxcos_edi_headers.j2_column%TYPE,               -- Ｊ－２欄
       k2_column                    xxcos_edi_headers.k2_column%TYPE,               -- Ｋ－２欄
       l2_column                    xxcos_edi_headers.l2_column%TYPE,               -- Ｌ－２欄
       f3_column                    xxcos_edi_headers.f3_column%TYPE,               -- Ｆ－３欄
       g3_column                    xxcos_edi_headers.g3_column%TYPE,               -- Ｇ－３欄
       h3_column                    xxcos_edi_headers.h3_column%TYPE,               -- Ｈ－３欄
       i3_column                    xxcos_edi_headers.i3_column%TYPE,               -- Ｉ－３欄
       j3_column                    xxcos_edi_headers.j3_column%TYPE,               -- Ｊ－３欄
       k3_column                    xxcos_edi_headers.k3_column%TYPE,               -- Ｋ－３欄
       l3_column                    xxcos_edi_headers.l3_column%TYPE,               -- Ｌ－３欄
                                                                 -- チェーン店固有エリア（ヘッダー）
-- 2010/04/23 v1.8 T.Yoshimoto Mod Start 本稼動#2427
--       chain_pecarea_head           xxcos_edi_headers.chain_peculiar_area_header%TYPE,
       chain_pe_area_head           xxcos_edi_headers.chain_peculiar_area_header%TYPE,
-- 2010/04/23 v1.8 T.Yoshimoto Mod Start 本稼動#2427
                                                                 -- 受注関連番号
       order_connect_num            xxcos_edi_headers.order_connection_number%TYPE,
                                                                 -- （伝票計）発注数量（バラ）
       inv_indv_order_qty           xxcos_edi_headers.invoice_indv_order_qty%TYPE,
                                                                 -- （伝票計）発注数量（ケース）
       inv_case_order_qty           xxcos_edi_headers.invoice_case_order_qty%TYPE,
                                                                 -- （伝票計）発注数量（ボール）
       inv_ball_order_qty           xxcos_edi_headers.invoice_ball_order_qty%TYPE,
                                                                 -- （伝票計）発注数量（合計、バラ）
       inv_sum_order_qty            xxcos_edi_headers.invoice_sum_order_qty%TYPE,
                                                                 -- （伝票計）出荷数量（バラ）
       inv_indv_ship_qty            xxcos_edi_headers.invoice_indv_shipping_qty%TYPE,
                                                                 -- （伝票計）出荷数量（ケース）
       inv_case_ship_qty            xxcos_edi_headers.invoice_case_shipping_qty%TYPE,
                                                                 -- （伝票計）出荷数量（ボール）
       inv_ball_ship_qty            xxcos_edi_headers.invoice_ball_shipping_qty%TYPE,
                                                                 -- （伝票計）出荷数量（パレット）
       inv_pall_ship_qty            xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE,
                                                                 -- （伝票計）出荷数量（合計、バラ）
       inv_sum_ship_qty             xxcos_edi_headers.invoice_sum_shipping_qty%TYPE,
                                                                 -- （伝票計）欠品数量（バラ）
       inv_indv_stock_qty           xxcos_edi_headers.invoice_indv_stockout_qty%TYPE,
                                                                 -- （伝票計）欠品数量（ケース）
       inv_case_stock_qty           xxcos_edi_headers.invoice_case_stockout_qty%TYPE,
                                                                 -- （伝票計）欠品数量（ボール）
       inv_ball_stock_qty           xxcos_edi_headers.invoice_ball_stockout_qty%TYPE,
                                                                 -- （伝票計）欠品数量（合計、バラ）
       inv_sum_stock_qty            xxcos_edi_headers.invoice_sum_stockout_qty%TYPE,
                                                                 -- （伝票計）ケース個口数
       inv_case_qty                 xxcos_edi_headers.invoice_case_qty%TYPE,
                                                                 -- （伝票計）オリコン（バラ）個口数
       inv_fold_cont_qty            xxcos_edi_headers.invoice_fold_container_qty%TYPE,
                                                                 -- （伝票計）原価金額（発注）
       inv_order_cost_amt           xxcos_edi_headers.invoice_order_cost_amt%TYPE,
                                                                 -- （伝票計）原価金額（出荷）
       inv_ship_cost_amt            xxcos_edi_headers.invoice_shipping_cost_amt%TYPE,
                                                                 -- （伝票計）原価金額（欠品）
       inv_stock_cost_amt           xxcos_edi_headers.invoice_stockout_cost_amt%TYPE,
                                                                 -- （伝票計）売価金額（発注）
       inv_order_price_amt          xxcos_edi_headers.invoice_order_price_amt%TYPE,
                                                                 -- （伝票計）売価金額（出荷）
       inv_ship_price_amt           xxcos_edi_headers.invoice_shipping_price_amt%TYPE,
                                                                  -- （伝票計）売価金額（欠品）
       inv_stock_price_amt          xxcos_edi_headers.invoice_stockout_price_amt%TYPE,
                                                                 -- （総合計）発注数量（バラ）
       tot_indv_order_qty           xxcos_edi_headers.total_indv_order_qty%TYPE,
                                                                 -- （総合計）発注数量（ケース）
       tot_case_order_qty           xxcos_edi_headers.total_case_order_qty%TYPE,
                                                                 -- （総合計）発注数量（ボール）
       tot_ball_order_qty           xxcos_edi_headers.total_ball_order_qty%TYPE,
                                                                 -- （総合計）発注数量（合計、バラ）
       tot_sum_order_qty            xxcos_edi_headers.total_sum_order_qty%TYPE,
                                                                 -- （総合計）出荷数量（バラ）
       tot_indv_ship_qty            xxcos_edi_headers.total_indv_shipping_qty%TYPE,
                                                                 -- （総合計）出荷数量（ケース）
       tot_case_ship_qty            xxcos_edi_headers.total_case_shipping_qty%TYPE,
                                                                 -- （総合計）出荷数量（ボール）
       tot_ball_ship_qty            xxcos_edi_headers.total_ball_shipping_qty%TYPE,
                                                                 -- （総合計）出荷数量（パレット）
       tot_pallet_ship_qty          xxcos_edi_headers.total_pallet_shipping_qty%TYPE,
                                                                 -- （総合計）出荷数量（合計、バラ）
       tot_sum_ship_qty             xxcos_edi_headers.total_sum_shipping_qty%TYPE,
                                                                 -- （総合計）欠品数量（バラ）
       tot_indv_stockout_qty        xxcos_edi_headers.total_indv_stockout_qty%TYPE,
                                                                 -- （総合計）欠品数量（ケース）
       tot_case_stockout_qty        xxcos_edi_headers.total_case_stockout_qty%TYPE,
                                                                 -- （総合計）欠品数量（ボール）
       tot_ball_stockout_qty        xxcos_edi_headers.total_case_stockout_qty%TYPE,
                                                                 -- （総合計）欠品数量（合計、バラ）
       tot_sum_stockout_qty         xxcos_edi_headers.total_case_stockout_qty%TYPE,
                                                                 -- （総合計）ケース個口数
       tot_case_qty                 xxcos_edi_headers.total_case_qty%TYPE,
                                                                 -- （総合計）オリコン（バラ）個口数
       tot_fold_container_qty       xxcos_edi_headers.total_fold_container_qty%TYPE,
                                                                  -- （総合計）原価金額（発注）
       tot_order_cost_amt           xxcos_edi_headers.total_order_cost_amt%TYPE,
                                                                 -- （総合計）原価金額（出荷）
       tot_ship_cost_amt            xxcos_edi_headers.total_shipping_cost_amt%TYPE,
                                                                 -- （総合計）原価金額（欠品）
       tot_stockout_cost_amt        xxcos_edi_headers.total_stockout_cost_amt%TYPE,
                                                                 -- （総合計）売価金額（発注）
       tot_order_price_amt          xxcos_edi_headers.total_order_price_amt%TYPE,
                                                                 -- （総合計）売価金額（出荷）
       tot_ship_price_amt           xxcos_edi_headers.total_shipping_price_amt%TYPE,
                                                                 -- （総合計）売価金額（欠品）
       tot_stockout_price_amt       xxcos_edi_headers.total_stockout_price_amt%TYPE,
                                                                 -- トータル行数
       tot_line_qty                 xxcos_edi_headers.total_line_qty%TYPE,
                                                                 -- トータル伝票枚数
       tot_invoice_qty              xxcos_edi_headers.total_invoice_qty%TYPE,
                                                                 -- チェーン店固有エリア（フッター）
       chain_pe_area_foot           xxcos_edi_headers.chain_peculiar_area_footer%TYPE,
                                                                 -- 変換後顧客コード
       conv_customer_code           xxcos_edi_headers.conv_customer_code%TYPE,
                                                                 -- 受注連携済フラグ
       order_forward_flag           xxcos_edi_headers.order_forward_flag%TYPE,
                                                                 -- 作成元区分
       creation_class               xxcos_edi_headers.creation_class%TYPE,
                                                                 -- EDI納品予定送信済フラグ
       edi_deli_sche_flg            xxcos_edi_headers.edi_delivery_schedule_flag%TYPE,
                                                                 -- 価格表ヘッダID
/* 2011/07/26 Ver1.9 Mod Start */
--       price_list_header_id         xxcos_edi_headers.price_list_header_id%TYPE
       price_list_header_id         xxcos_edi_headers.price_list_header_id%TYPE,
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
                                                                 -- 流通ＢＭＳヘッダデータ
       bms_header_data              xxcos_edi_headers.bms_header_data%TYPE
/* 2011/07/26 Ver1.9 Add End   */
   );
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  -- 顧客データ テーブル型
  TYPE g_req_edi_headers_data_ttype IS TABLE OF g_req_edi_headers_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_edi_headers_data  g_req_edi_headers_data_ttype;
  --* -------------------------------------------------------------------------------------------
  --* -------------------------------------------------------------------------------------------
  -- EDI明細情報テーブルデータ登録用変数(xxcos_edi_lines)
  TYPE g_req_edi_lines_data_rtype IS RECORD(
        edi_line_info_id             xxcos_edi_lines.edi_line_info_id%TYPE,    -- EDI明細情報ID
        invoice_number               xxcos_edi_headers.invoice_number%TYPE,    -- 伝票番号
        edi_header_info_id           xxcos_edi_lines.edi_header_info_id%TYPE,  -- EDIヘッダ情報ID
        line_no                      xxcos_edi_lines.line_no%TYPE,             -- 行Ｎｏ
        stockout_class               xxcos_edi_lines.stockout_class%TYPE,      -- 欠品区分
        stockout_reason              xxcos_edi_lines.stockout_reason%TYPE,     -- 欠品理由
                                                                                 -- 商品コード（伊藤園）
        product_code_itouen          xxcos_edi_lines.product_code_itouen%TYPE,
        product_code1                xxcos_edi_lines.product_code1%TYPE,       -- 商品コード１
        product_code2                xxcos_edi_lines.product_code2%TYPE,       -- 商品コード２
        jan_code                     xxcos_edi_lines.jan_code%TYPE,            -- ＪＡＮコード
        itf_code                     xxcos_edi_lines.itf_code%TYPE,            -- ＩＴＦコード
        extension_itf_code           xxcos_edi_lines.extension_itf_code%TYPE,  -- 内箱ＩＴＦコード
        case_product_code            xxcos_edi_lines.case_product_code%TYPE,   -- ケース商品コード
        ball_product_code            xxcos_edi_lines.ball_product_code%TYPE,   -- ボール商品コード
        prod_cd_item_type            xxcos_edi_lines.product_code_item_type%TYPE, -- 商品コード品種
        prod_class                   xxcos_edi_lines.prod_class%TYPE,          -- 商品区分
        product_name                 xxcos_edi_lines.product_name%TYPE,        -- 商品名（漢字）
        product_name1_alt            xxcos_edi_lines.product_name1_alt%TYPE,   -- 商品名１（カナ）
        product_name2_alt            xxcos_edi_lines.product_name2_alt%TYPE,   -- 商品名２（カナ）
        item_standard1               xxcos_edi_lines.item_standard1%TYPE,      -- 規格１
        item_standard2               xxcos_edi_lines.item_standard2%TYPE,      -- 規格２
        qty_in_case                  xxcos_edi_lines.qty_in_case%TYPE,         -- 入数
        num_of_cases                 xxcos_edi_lines.num_of_cases%TYPE,        -- ケース入数
        num_of_ball                  xxcos_edi_lines.num_of_ball%TYPE,         -- ボール入数
        item_color                   xxcos_edi_lines.item_color%TYPE,          -- 色
        item_size                    xxcos_edi_lines.item_size%TYPE,           -- サイズ
        expiration_date              xxcos_edi_lines.expiration_date%TYPE,     -- 賞味期限日
        product_date                 xxcos_edi_lines.product_date%TYPE,        -- 製造日
        order_uom_qty                xxcos_edi_lines.order_uom_qty%TYPE,       -- 発注単位数
        ship_uom_qty                 xxcos_edi_lines.shipping_uom_qty%TYPE,    -- 出荷単位数
        packing_uom_qty              xxcos_edi_lines.packing_uom_qty%TYPE,     -- 梱包単位数
        deal_code                    xxcos_edi_lines.deal_code%TYPE,           -- 引合
        deal_class                   xxcos_edi_lines.deal_class%TYPE,          -- 引合区分
        collation_code               xxcos_edi_lines.collation_code%TYPE,      -- 照合
        uom_code                     xxcos_edi_lines.uom_code%TYPE,            -- 単位
        unit_price_class             xxcos_edi_lines.unit_price_class%TYPE,    -- 単価区分
        parent_pack_num              xxcos_edi_lines.parent_packing_number%TYPE, -- 親梱包番号
        packing_number               xxcos_edi_lines.packing_number%TYPE,      -- 梱包番号
        product_group_code           xxcos_edi_lines.product_group_code%TYPE,  -- 商品群コード
        case_dismantle_flag          xxcos_edi_lines.case_dismantle_flag%TYPE, -- ケース解体不可フラグ
        case_class                   xxcos_edi_lines.case_class%TYPE,          -- ケース区分
        indv_order_qty               xxcos_edi_lines.indv_order_qty%TYPE,      -- 発注数量（バラ）
        case_order_qty               xxcos_edi_lines.case_order_qty%TYPE,      -- 発注数量（ケース）
        ball_order_qty               xxcos_edi_lines.ball_order_qty%TYPE,      -- 発注数量（ボール）
        sum_order_qty                xxcos_edi_lines.sum_order_qty%TYPE,       -- 発注数量（合計、バラ）
        indv_shipping_qty            xxcos_edi_lines.indv_shipping_qty%TYPE,   -- 出荷数量（バラ）
        case_shipping_qty            xxcos_edi_lines.case_shipping_qty%TYPE,   -- 出荷数量（ケース）
        ball_shipping_qty            xxcos_edi_lines.ball_shipping_qty%TYPE,   -- 出荷数量（ボール）
        pallet_shipping_qty          xxcos_edi_lines.pallet_shipping_qty%TYPE, -- 出荷数量（パレット）
        sum_shipping_qty             xxcos_edi_lines.sum_shipping_qty%TYPE,    -- 出荷数量（合計、バラ）
        indv_stockout_qty            xxcos_edi_lines.indv_stockout_qty%TYPE,   -- 欠品数量（バラ）
        case_stockout_qty            xxcos_edi_lines.case_stockout_qty%TYPE,   -- 欠品数量（ケース）
        ball_stockout_qty            xxcos_edi_lines.ball_stockout_qty%TYPE,   -- 欠品数量（ボール）
        sum_stockout_qty             xxcos_edi_lines.sum_stockout_qty%TYPE,    -- 欠品数量（合計、バラ）
        case_qty                     xxcos_edi_lines.case_qty%TYPE,            -- ケース個口数
                                                                               -- オリコン（バラ）個口数
        fold_cont_indv_qty           xxcos_edi_lines.FOLD_CONTAINER_INDV_QTY%TYPE,
        order_unit_price             xxcos_edi_lines.order_unit_price%TYPE,    -- 原単価（発注）
        shipping_unit_price          xxcos_edi_lines.shipping_unit_price%TYPE, -- 原単価（出荷）
        order_cost_amt               xxcos_edi_lines.order_cost_amt%TYPE,      -- 原価金額（発注）
        shipping_cost_amt            xxcos_edi_lines.shipping_cost_amt%TYPE,   -- 原価金額（出荷）
        stockout_cost_amt            xxcos_edi_lines.stockout_cost_amt%TYPE,   -- 原価金額（欠品）
        selling_price                xxcos_edi_lines.selling_price%TYPE,       -- 売単価
        order_price_amt              xxcos_edi_lines.order_price_amt%TYPE,     -- 売価金額（発注）
        shipping_price_amt           xxcos_edi_lines.shipping_price_amt%TYPE,  -- 売価金額（出荷）
        stockout_price_amt           xxcos_edi_lines.stockout_price_amt%TYPE,  -- 売価金額（欠品）
        a_col_department             xxcos_edi_lines.a_column_department%TYPE, -- Ａ欄（百貨店）
        d_col_department             xxcos_edi_lines.d_column_department%TYPE, -- Ｄ欄（百貨店）
        stand_info_depth             xxcos_edi_lines.standard_info_depth%TYPE, -- 規格情報・奥行き
        stand_info_height            xxcos_edi_lines.standard_info_height%TYPE, -- 規格情報・高さ
        stand_info_width             xxcos_edi_lines.standard_info_width%TYPE, -- 規格情報・幅
        stand_info_weight            xxcos_edi_lines.standard_info_weight%TYPE, -- 規格情報・重量
        gen_succeed_item1            xxcos_edi_lines.general_succeeded_item1%TYPE, -- 汎用引継ぎ項目１
        gen_succeed_item2            xxcos_edi_lines.general_succeeded_item2%TYPE, -- 汎用引継ぎ項目２
        gen_succeed_item3            xxcos_edi_lines.general_succeeded_item3%TYPE, -- 汎用引継ぎ項目３
        gen_succeed_item4            xxcos_edi_lines.general_succeeded_item4%TYPE, -- 汎用引継ぎ項目４
        gen_succeed_item5            xxcos_edi_lines.general_succeeded_item5%TYPE, -- 汎用引継ぎ項目５
        gen_succeed_item6            xxcos_edi_lines.general_succeeded_item6%TYPE, -- 汎用引継ぎ項目６
        gen_succeed_item7            xxcos_edi_lines.general_succeeded_item7%TYPE, -- 汎用引継ぎ項目７
        gen_succeed_item8            xxcos_edi_lines.general_succeeded_item8%TYPE, -- 汎用引継ぎ項目８
        gen_succeed_item9            xxcos_edi_lines.general_succeeded_item9%TYPE, -- 汎用引継ぎ項目９
        gen_succeed_item10           xxcos_edi_lines.general_succeeded_item10%TYPE, -- 汎用引継ぎ項目１０
        gen_add_item1                xxcos_edi_lines.general_add_item1%TYPE,       -- 汎用付加項目１
        gen_add_item2                xxcos_edi_lines.general_add_item2%TYPE,       -- 汎用付加項目２
        gen_add_item3                xxcos_edi_lines.general_add_item3%TYPE,       -- 汎用付加項目３
        gen_add_item4                xxcos_edi_lines.general_add_item4%TYPE,       -- 汎用付加項目４
        gen_add_item5                xxcos_edi_lines.general_add_item5%TYPE,       -- 汎用付加項目５
        gen_add_item6                xxcos_edi_lines.general_add_item6%TYPE,       -- 汎用付加項目６
        gen_add_item7                xxcos_edi_lines.general_add_item7%TYPE,       -- 汎用付加項目７
        gen_add_item8                xxcos_edi_lines.general_add_item8%TYPE,       -- 汎用付加項目８
        gen_add_item9                xxcos_edi_lines.general_add_item9%TYPE,       -- 汎用付加項目９
        gen_add_item10               xxcos_edi_lines.general_add_item10%TYPE,      -- 汎用付加項目１０
                                                                         -- チェーン店固有エリア（明細）
        chain_pec_a_line             xxcos_edi_lines.chain_peculiar_area_line%TYPE,
        item_code                    xxcos_edi_lines.item_code%TYPE,               -- 品目コード
        line_uom                     xxcos_edi_lines.line_uom%TYPE,                -- 明細単位
                                                                                   -- 受注関連明細番号
/* 2011/07/26 Ver1.9 Mod Start */
--        order_con_line_num           xxcos_edi_lines.order_connection_line_number%TYPE
        order_con_line_num           xxcos_edi_lines.order_connection_line_number%TYPE,
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
        bms_line_data                xxcos_edi_lines.bms_line_data%TYPE            -- 流通ＢＭＳ明細データ
/* 2011/07/26 Ver1.9 Add End   */
    );
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  -- 顧客データ テーブル型
  TYPE g_req_edi_lines_data_ttype IS TABLE OF g_req_edi_lines_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_edi_lines_data  g_req_edi_lines_data_ttype;
  --* -------------------------------------------------------------------------------------------
  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- 品目データレコード型
  -- ===============================
  TYPE ga_req_mtl_sys_items_rtype IS RECORD(
                         -- 品目マスタの品目ID
      inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE
                         -- 品目マスタの品目コード
     ,segment1           mtl_system_items_b.segment1%TYPE
                         -- 単位
     ,unit_of_measure    mtl_system_items_b.primary_unit_of_measure%TYPE
    );
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  -- 品目データ テーブル型
  -- ===============================
  TYPE ga_req_mtl_sys_items_ttype IS TABLE OF ga_req_mtl_sys_items_rtype INDEX BY BINARY_INTEGER;
  gt_req_mtl_sys_items  ga_req_mtl_sys_items_ttype;
  --
  gt_delivery_return_work_id          xxcos_edi_delivery_work.delivery_return_work_id%TYPE;
                          -- EDI納品返品情報ワーク変数の納品返品ワークID
  --* -------------------------------------------------------------------------------------------
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)(A-1)
   *                  :  入力パラメータ妥当性チェック
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN VARCHAR2,     --   実行区分：「新規」「再実行」
    iv_edi_chain_code IN VARCHAR2,     --   EDIチェーン店コード
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
-- ******************** 2009/09/28 1.6 K.Satomura ADD START *********************** --
    lv_tok_item_err_type VARCHAR2(100); -- メッセージトークン１
    lv_tok_lookup_value  VARCHAR2(100); -- メッセージトークン２
-- ******************** 2009/09/28 1.6 K.Satomura ADD END   *********************** --
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
  --* -------------------------------------------------------------------------------------------
    IF  ( iv_file_name  IS NULL ) THEN                 -- インタフェースファイル名がNULL
      -- インタフェースファイル名
      gv_in_file_name    :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_in_file_name
                         );
      lv_retcode         :=  cv_status_error;
      lv_errmsg          :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  gv_msg_in_param_none_err,
                         iv_token_name1        =>  cv_tkn_in_param,
                         iv_token_value1       =>  gv_in_file_name
                         );
    END IF;
    --* -------------------------------------------------------------------------------------------
    --エラーの場合、中断させる。
    IF  ( lv_retcode  <>  cv_status_normal )  THEN
      RAISE   global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --* -------------------------------------------------------------------------------------------
    IF  ( iv_run_class IS NULL ) THEN                 -- 実行区分のパラメタがNULL
      -- 実行区分
      gv_in_param       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  cv_msg_in_param
                        );
      lv_retcode        :=  cv_status_error;
      lv_errmsg         :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_in_param_none_err,
                        iv_token_name1        =>  cv_tkn_in_param,
                        iv_token_value1       =>  gv_in_param
                        );
    --* -------------------------------------------------------------------------------------------
    ELSIF  (( iv_run_class  =  gv_run_class_name1 )     -- 実行区分：「新規」
    OR      ( iv_run_class  =  gv_run_class_name2 ))    -- 実行区分：「再実施」
    THEN
      NULL;
    ELSE
      -- 実行区分
      gv_in_param       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  cv_msg_in_param
                        );
      lv_retcode        :=  cv_status_error;
      lv_errmsg         :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_in_param_err,
                        iv_token_name1        =>  cv_tkn_in_param,
                        iv_token_value1       =>  gv_in_param
                        );
    END IF;
    --* -------------------------------------------------------------------------------------------
    --エラーの場合、中断させる。
    IF  ( lv_retcode <> cv_status_normal )  THEN
      RAISE   global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-1. EDI情報削除期間の取得
    --==================================
    gv_prf_edi_del_date :=  FND_PROFILE.VALUE( cv_prf_edi_del_date );
    --
    IF  ( gv_prf_edi_del_date IS NULL )   THEN
      -- EDI情報削除期間
      gv_prf_edi_del_date0 :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_edi_del_date
                            );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_prf_edi_del_date0
                           );
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-2. ケース単位コードの取得
    --==================================
    gv_prf_case_code    :=  FND_PROFILE.VALUE( cv_prf_case_code );
    --
    IF  ( gv_prf_case_code  IS NULL )   THEN
      -- ケース単位コード
      gv_prf_case_code0    :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_case_code
                           );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_prf_case_code0
                           );
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-3. 在庫組織コードの取得
    --==================================
    gv_prf_orga_code    :=  FND_PROFILE.VALUE( cv_prf_orga_code1  );
    --
    IF  ( gv_prf_orga_code  IS NULL )   THEN
      -- 在庫組織コード
      gv_prf_orga_code0    :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_orga_code
                           );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_prf_orga_code0
                           );
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-4. 在庫組織ＩＤの取得
    --==================================
    gv_prf_orga_id      :=  xxcoi_common_pkg.get_organization_id(
                         gv_prf_orga_code
                         );
    --
    IF  ( gv_prf_orga_id       IS NULL )  THEN
      lv_errmsg          :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application1,
                         iv_name               =>  gv_msg_orga_id_err,
                         iv_token_name1        =>  cv_tkn_org_code,
                         iv_token_value1       =>  gv_prf_orga_code
                         );
      RAISE global_api_expt;
    END IF;
    --
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-5. MO:営業単位の取得
    --==================================
    gn_org_id :=  FND_PROFILE.VALUE( cv_prf_org_id );
    --
    IF  ( gn_org_id IS NULL )   THEN
      -- MO:営業単位
      gv_msg_tkn_org_id    :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_org_id
                            );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_msg_tkn_org_id
                           );
      RAISE global_api_expt;
    END IF;
    --
    --* -------------------------------------------------------------------------------------------
-- ******************** 2009/09/28 1.6 K.Satomura ADD START *********************** --
    --==================================
    -- 2-6. ダミー品目コードの取得
    --==================================
    BEGIN
      SELECT msi.segment1                dummy_item_code         -- ダミー品目コード
            ,msi.primary_unit_of_measure primary_unit_of_measure -- 基準単位
      INTO   gt_dummy_item_number
            ,gt_dummy_unit_of_measure
      FROM   fnd_lookup_values_vl flv -- 参照タイプコード
            ,mtl_system_items_b msi -- 品目マスタ
      WHERE  flv.lookup_type        = cv_lookup_type
      AND    flv.enabled_flag       = cv_y
      AND    flv.attribute1         = cv_1
      AND    TRUNC(cd_process_date) BETWEEN flv.start_date_active
                                        AND NVL(flv.end_date_active, TRUNC(cd_process_date))
      AND    flv.lookup_code        = msi.segment1   -- 参照タイプコード.コード=品目マスタ.品目コード
      AND    msi.organization_id    = gv_prf_orga_id -- 在庫組織ID
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- マスタチェックエラーを出力
        lv_tok_item_err_type := xxccp_common_pkg.get_msg(
                                   iv_application => cv_application
                                  ,iv_name        => cv_msg_item_err_type
                                );
        --
        lv_tok_lookup_value  := xxccp_common_pkg.get_msg(
                                   iv_application => cv_application
                                  ,iv_name        => cv_msg_lookup_value
                                );
        lv_errmsg            := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_application
                                  ,iv_name         => cv_msg_mst_notfound
                                  ,iv_token_name1  => cv_tkn_column_name
                                  ,iv_token_value1 => lv_tok_item_err_type
                                  ,iv_token_name2  => cv_tkn_table_name
                                  ,iv_token_value2 => lv_tok_lookup_value
                                );
        --
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
        --
    END;
-- ******************** 2009/09/28 1.6 K.Satomura ADD END   *********************** --
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_headers_add
   * Description      : EDIヘッダ情報変数への追加(A-4)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_headers_add(
    in_line_cnt1  IN NUMBER,       --   LOOP用カウンタ1
    in_line_cnt2  IN NUMBER,       --   LOOP用カウンタ2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_headers_add'; -- プログラム名
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
               -- （伝票計）発注数量（バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_order_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).indv_order_qty, 0);
               -- （伝票計）発注数量（ケース）
    gt_req_edi_headers_data(in_line_cnt1).inv_case_order_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).case_order_qty, 0);
               -- （伝票計）発注数量（ボール）
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_order_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).ball_order_qty, 0);
               -- （伝票計）発注数量（合計、バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_order_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).sum_order_qty, 0);
               -- （伝票計）出荷数量（バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).indv_shipping_qty, 0);
               -- （伝票計）出荷数量（ケース）
    gt_req_edi_headers_data(in_line_cnt1).inv_case_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).case_shipping_qty, 0);
               -- （伝票計）出荷数量（ボール）
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).ball_shipping_qty, 0);
               -- （伝票計）出荷数量（パレット）
    gt_req_edi_headers_data(in_line_cnt1).inv_pall_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).pallet_shipping_qty, 0);
               -- （伝票計）出荷数量（合計、バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).sum_shipping_qty, 0);
               -- （伝票計）欠品数量（バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_stock_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).indv_stockout_qty, 0);
               -- （伝票計）欠品数量（ケース）
    gt_req_edi_headers_data(in_line_cnt1).inv_case_stock_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).case_stockout_qty, 0);
               -- （伝票計）欠品数量（ボール）
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_stock_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).ball_stockout_qty, 0);
               -- （伝票計）欠品数量（合計、バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_stock_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).sum_stockout_qty, 0);
               -- （伝票計）ケース個口数
    gt_req_edi_headers_data(in_line_cnt1).inv_case_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).case_qty, 0);
               -- （伝票計）オリコン（バラ）個口数
    gt_req_edi_headers_data(in_line_cnt1).inv_fold_cont_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).fold_container_indv_qty, 0);
               -- （伝票計）原価金額（発注）
    gt_req_edi_headers_data(in_line_cnt1).inv_order_cost_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).order_cost_amt, 0);
               -- （伝票計）原価金額（出荷）
    gt_req_edi_headers_data(in_line_cnt1).inv_ship_cost_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).shipping_cost_amt, 0);
               -- （伝票計）原価金額（欠品）
    gt_req_edi_headers_data(in_line_cnt1).inv_stock_cost_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).stockout_cost_amt, 0);
               -- （伝票計）売価金額（発注）
    gt_req_edi_headers_data(in_line_cnt1).inv_order_price_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).order_price_amt, 0);
               -- （伝票計）売価金額（出荷）
    gt_req_edi_headers_data(in_line_cnt1).inv_ship_price_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).shipping_price_amt, 0);
               -- （伝票計）売価金額（欠品）
    gt_req_edi_headers_data(in_line_cnt1).inv_stock_price_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).stockout_price_amt, 0);
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END xxcos_in_edi_headers_add;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_headers_up
   * Description      : EDIヘッダ情報変数へ数量を加算(A-5)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_headers_up(
    in_line_cnt1   IN NUMBER,       --   LOOP用カウンタ1
    in_line_cnt2   IN NUMBER,       --   LOOP用カウンタ2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_headers_up'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)  ;   -- リターン・コード
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
               -- （伝票計）発注数量（バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_order_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_indv_order_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).indv_order_qty, 0);
               -- （伝票計）発注数量（ケース）
    gt_req_edi_headers_data(in_line_cnt1).inv_case_order_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_case_order_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).case_order_qty, 0);
               -- （伝票計）発注数量（ボール）
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_order_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ball_order_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).ball_order_qty, 0);
               -- （伝票計）発注数量（合計、バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_order_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_sum_order_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).sum_order_qty, 0);
               -- （伝票計）出荷数量（バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_indv_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).indv_shipping_qty, 0);
               -- （伝票計）出荷数量（ケース）
    gt_req_edi_headers_data(in_line_cnt1).inv_case_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_case_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).case_shipping_qty, 0);
               -- （伝票計）出荷数量（ボール）
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ball_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).ball_shipping_qty, 0);
               -- （伝票計）出荷数量（パレット）
    gt_req_edi_headers_data(in_line_cnt1).inv_pall_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_pall_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).pallet_shipping_qty, 0);
               -- （伝票計）出荷数量（合計、バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_sum_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).sum_shipping_qty, 0);
               -- （伝票計）欠品数量（バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_stock_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_indv_stock_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).indv_stockout_qty, 0);
               -- （伝票計）欠品数量（ケース）
    gt_req_edi_headers_data(in_line_cnt1).inv_case_stock_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_case_stock_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).case_stockout_qty, 0);
               -- （伝票計）欠品数量（ボール）
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_stock_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ball_stock_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).ball_stockout_qty, 0);
               -- （伝票計）欠品数量（合計、バラ）
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_stock_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_sum_stock_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).sum_stockout_qty, 0);
               -- （伝票計）ケース個口数
    gt_req_edi_headers_data(in_line_cnt1).inv_case_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_case_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).case_qty, 0);
               -- （伝票計）オリコン（バラ）個口数
    gt_req_edi_headers_data(in_line_cnt1).inv_fold_cont_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_fold_cont_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).fold_container_indv_qty, 0);
               -- （伝票計）原価金額（発注）
    gt_req_edi_headers_data(in_line_cnt1).inv_order_cost_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_order_cost_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).order_cost_amt, 0);
               -- （伝票計）原価金額（出荷）
    gt_req_edi_headers_data(in_line_cnt1).inv_ship_cost_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ship_cost_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).shipping_cost_amt, 0);
               -- （伝票計）原価金額（欠品）
    gt_req_edi_headers_data(in_line_cnt1).inv_stock_cost_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_stock_cost_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).stockout_cost_amt, 0);
               -- （伝票計）売価金額（発注）
    gt_req_edi_headers_data(in_line_cnt1).inv_order_price_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_order_price_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).order_price_amt, 0);
               -- （伝票計）売価金額（出荷）
    gt_req_edi_headers_data(in_line_cnt1).inv_ship_price_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ship_price_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).shipping_price_amt, 0);
               -- （伝票計）売価金額（欠品）
    gt_req_edi_headers_data(in_line_cnt1).inv_stock_price_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_stock_price_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).stockout_price_amt, 0);
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END xxcos_in_edi_headers_up;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_headers_edit
   * Description      : EDIヘッダ情報変数の編集(A-2)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_headers_edit(
    in_line_cnt1    IN NUMBER,       --   LOOP用カウンタ1
    in_line_cnt     IN NUMBER,       --   LOOP用カウンタ2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_headers_edit'; -- プログラム名
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
    ln_seq     NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    -- EDIヘッダ情報IDをシーケンスから取得する
    SELECT xxcos_edi_headers_s01.NEXTVAL
    INTO   ln_seq
    FROM   dual;
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --* -------------------------------------------------------------------------------------------
    -- EDIヘッダ情報テーブルデータ登録用変数(XXCOS_IN_EDI_HEADERS)
    --* -------------------------------------------------------------------------------------------
    -- EDIヘッダ情報ID
    gt_edi_header_info_id    := ln_seq;
    --
                -- EDIヘッダ情報ID
    gt_req_edi_headers_data(in_line_cnt1).edi_header_info_id   := ln_seq;
                -- 媒体区分
    gt_req_edi_headers_data(in_line_cnt1).medium_class   := gt_edideli_work_data(in_line_cnt).medium_class;
                -- データ種コード
    gt_req_edi_headers_data(in_line_cnt1).data_type_code := gt_edideli_work_data(in_line_cnt).data_type_code;
                -- ファイルＮｏ
    gt_req_edi_headers_data(in_line_cnt1).file_no        := gt_edideli_work_data(in_line_cnt).file_no;
                -- 情報区分
    gt_req_edi_headers_data(in_line_cnt1).info_class     := gt_edideli_work_data(in_line_cnt).info_class;
                -- 処理日
    gt_req_edi_headers_data(in_line_cnt1).process_date   := gt_edideli_work_data(in_line_cnt).process_date;
                -- 処理時刻
    gt_req_edi_headers_data(in_line_cnt1).process_time   := gt_edideli_work_data(in_line_cnt).process_time;
                -- 拠点（部門）コード
    gt_req_edi_headers_data(in_line_cnt1).base_code      := gt_edideli_work_data(in_line_cnt).base_code;
                -- 拠点名（正式名）
    gt_req_edi_headers_data(in_line_cnt1).base_name      := gt_edideli_work_data(in_line_cnt).base_name;
                -- 拠点名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).base_name_alt  := gt_edideli_work_data(in_line_cnt).base_name_alt;
                -- ＥＤＩチェーン店コード
    gt_req_edi_headers_data(in_line_cnt1).edi_chain_code := gt_edideli_work_data(in_line_cnt).edi_chain_code;
                -- ＥＤＩチェーン店名（漢字）
    gt_req_edi_headers_data(in_line_cnt1).edi_chain_name := gt_edideli_work_data(in_line_cnt).edi_chain_name;
                -- ＥＤＩチェーン店名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).edi_chain_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).edi_chain_name_alt;
                -- チェーン店コード
    gt_req_edi_headers_data(in_line_cnt1).chain_code     := gt_edideli_work_data(in_line_cnt).chain_code;
                -- チェーン店名（漢字）
    gt_req_edi_headers_data(in_line_cnt1).chain_name     := gt_edideli_work_data(in_line_cnt).chain_name;
                -- チェーン店名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).chain_name_alt := gt_edideli_work_data(in_line_cnt).chain_name_alt;
                -- 帳票コード
    gt_req_edi_headers_data(in_line_cnt1).report_code    := gt_edideli_work_data(in_line_cnt).report_code;
                -- 帳票表示名
    gt_req_edi_headers_data(in_line_cnt1).report_show_name
                                                   := gt_edideli_work_data(in_line_cnt).report_show_name;
                -- 顧客コード
    gt_req_edi_headers_data(in_line_cnt1).customer_code  := gt_edideli_work_data(in_line_cnt).customer_code;
                -- 顧客名（漢字）
    gt_req_edi_headers_data(in_line_cnt1).customer_name  := gt_edideli_work_data(in_line_cnt).customer_name;
                -- 顧客名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).customer_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).customer_name_alt;
                -- 社コード
    gt_req_edi_headers_data(in_line_cnt1).company_code   := gt_edideli_work_data(in_line_cnt).company_code;
                -- 社名（漢字）
    gt_req_edi_headers_data(in_line_cnt1).company_name   := gt_edideli_work_data(in_line_cnt).company_name;
                -- 社名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).company_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).company_name_alt;
                -- 店コード
    gt_req_edi_headers_data(in_line_cnt1).shop_code      := gt_edideli_work_data(in_line_cnt).shop_code;
                -- 店名（漢字）
    gt_req_edi_headers_data(in_line_cnt1).shop_name      := gt_edideli_work_data(in_line_cnt).shop_name;
                -- 店名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).shop_name_alt  := gt_edideli_work_data(in_line_cnt).shop_name_alt;
                -- 納入センターコード
    gt_req_edi_headers_data(in_line_cnt1).deli_center_code
                                                   := gt_edideli_work_data(in_line_cnt).delivery_center_code;
                -- 納入センター名（漢字）
    gt_req_edi_headers_data(in_line_cnt1).deli_center_name
                                                   := gt_edideli_work_data(in_line_cnt).delivery_center_name;
                -- 納入センター名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).deli_center_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).delivery_center_name_alt;
                -- 発注日
    gt_req_edi_headers_data(in_line_cnt1).order_date     := gt_edideli_work_data(in_line_cnt).order_date;
                -- センター納品日
    gt_req_edi_headers_data(in_line_cnt1).center_delivery_date
                                                   := gt_edideli_work_data(in_line_cnt).center_delivery_date;
                -- 実納品日
    gt_req_edi_headers_data(in_line_cnt1).result_delivery_date
                                                   := gt_edideli_work_data(in_line_cnt).result_delivery_date;
                -- 店舗納品日
    gt_req_edi_headers_data(in_line_cnt1).shop_delivery_date
                                                   := gt_edideli_work_data(in_line_cnt).shop_delivery_date;
                -- データ作成日（EDIデータ中）
    gt_req_edi_headers_data(in_line_cnt1).data_cd_edi_data
                                                   := gt_edideli_work_data(in_line_cnt).data_creation_date_edi_data;
                -- データ作成時刻（ＥＤＩデータ中）
    gt_req_edi_headers_data(in_line_cnt1).data_ct_edi_data
                                                   := gt_edideli_work_data(in_line_cnt).data_creation_time_edi_data;
                -- 伝票区分
    gt_req_edi_headers_data(in_line_cnt1).invoice_class  := gt_edideli_work_data(in_line_cnt).invoice_class;
                -- 小分類コード
    gt_req_edi_headers_data(in_line_cnt1).small_class_cd := gt_edideli_work_data(in_line_cnt).small_classification_code;
                -- 小分類名
    gt_req_edi_headers_data(in_line_cnt1).small_class_nm := gt_edideli_work_data(in_line_cnt).small_classification_name;
                -- 中分類コード
    gt_req_edi_headers_data(in_line_cnt1).mid_class_cd   := gt_edideli_work_data(in_line_cnt).middle_classification_code;
                -- 中分類名
    gt_req_edi_headers_data(in_line_cnt1).mid_class_nm   := gt_edideli_work_data(in_line_cnt).middle_classification_name;
                -- 大分類コード
    gt_req_edi_headers_data(in_line_cnt1).big_class_cd   := gt_edideli_work_data(in_line_cnt).big_classification_code;
                -- 大分類名
    gt_req_edi_headers_data(in_line_cnt1).big_class_nm   := gt_edideli_work_data(in_line_cnt).big_classification_name;
                -- 相手先部門コード
    gt_req_edi_headers_data(in_line_cnt1).other_par_dep_cd
                                                   := gt_edideli_work_data(in_line_cnt).other_party_department_code;
                -- 相手先発注番号
    gt_req_edi_headers_data(in_line_cnt1).other_par_order_num
                                                   := gt_edideli_work_data(in_line_cnt).other_party_order_number;
                -- チェックデジット有無区分
    gt_req_edi_headers_data(in_line_cnt1).check_digit_class
                                                   := gt_edideli_work_data(in_line_cnt).check_digit_class;
                -- 伝票番号
    gt_req_edi_headers_data(in_line_cnt1).invoice_number := gt_edideli_work_data(in_line_cnt).invoice_number;
                -- チェックデジット
    gt_req_edi_headers_data(in_line_cnt1).check_digit    := gt_edideli_work_data(in_line_cnt).check_digit;
                -- 月限
    gt_req_edi_headers_data(in_line_cnt1).close_date     := gt_edideli_work_data(in_line_cnt).close_date;
                -- 受注Ｎｏ（ＥＢＳ）
    gt_req_edi_headers_data(in_line_cnt1).order_no_ebs   := gt_edideli_work_data(in_line_cnt).order_no_ebs;
                -- 特売区分
    gt_req_edi_headers_data(in_line_cnt1).ar_sale_class  := gt_edideli_work_data(in_line_cnt).ar_sale_class;
                -- 配送区分
    gt_req_edi_headers_data(in_line_cnt1).delivery_classe
                                                   := gt_edideli_work_data(in_line_cnt).delivery_classe;
                -- 便Ｎｏ
    gt_req_edi_headers_data(in_line_cnt1).opportunity_no := gt_edideli_work_data(in_line_cnt).opportunity_no;
                -- 連絡先
    gt_req_edi_headers_data(in_line_cnt1).contact_to     := gt_edideli_work_data(in_line_cnt).contact_to;
                -- ルートセールス
    gt_req_edi_headers_data(in_line_cnt1).route_sales    := gt_edideli_work_data(in_line_cnt).route_sales;
                -- 法人コード
    gt_req_edi_headers_data(in_line_cnt1).corporate_code := gt_edideli_work_data(in_line_cnt).corporate_code;
                -- メーカー名
    gt_req_edi_headers_data(in_line_cnt1).maker_name     := gt_edideli_work_data(in_line_cnt).maker_name;
                -- 地区コード
    gt_req_edi_headers_data(in_line_cnt1).area_code      := gt_edideli_work_data(in_line_cnt).area_code;
                -- 地区名（漢字）
    gt_req_edi_headers_data(in_line_cnt1).area_name      := gt_edideli_work_data(in_line_cnt).area_name;
                -- 地区名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).area_name_alt  := gt_edideli_work_data(in_line_cnt).area_name_alt;
                -- 取引先コード
    gt_req_edi_headers_data(in_line_cnt1).vendor_code    := gt_edideli_work_data(in_line_cnt).vendor_code;
                -- 取引先名（漢字）
    gt_req_edi_headers_data(in_line_cnt1).vendor_name    := gt_edideli_work_data(in_line_cnt).vendor_name;
                -- 取引先名１（カナ）
    gt_req_edi_headers_data(in_line_cnt1).vendor_name1_alt
                                                   := gt_edideli_work_data(in_line_cnt).vendor_name1_alt;
                -- 取引先名２（カナ）
    gt_req_edi_headers_data(in_line_cnt1).vendor_name2_alt
                                                   := gt_edideli_work_data(in_line_cnt).vendor_name2_alt;
                -- 取引先ＴＥＬ
    gt_req_edi_headers_data(in_line_cnt1).vendor_tel     := gt_edideli_work_data(in_line_cnt).vendor_tel;
                -- 取引先担当者
    gt_req_edi_headers_data(in_line_cnt1).vendor_charge  := gt_edideli_work_data(in_line_cnt).vendor_charge;
                -- 取引先住所（漢字）
    gt_req_edi_headers_data(in_line_cnt1).vendor_address := gt_edideli_work_data(in_line_cnt).vendor_address;
                -- 届け先コード（伊藤園）
    gt_req_edi_headers_data(in_line_cnt1).deli_to_cd_itouen
                                                   := gt_edideli_work_data(in_line_cnt).deliver_to_code_itouen;
                -- 届け先コード（チェーン店）
    gt_req_edi_headers_data(in_line_cnt1).deli_to_cd_chain
                                                   := gt_edideli_work_data(in_line_cnt).deliver_to_code_chain;
                -- 届け先（漢字）
    gt_req_edi_headers_data(in_line_cnt1).deli_to        := gt_edideli_work_data(in_line_cnt).deliver_to;
                -- 届け先１（カナ）
    gt_req_edi_headers_data(in_line_cnt1).deli_to1_alt   := gt_edideli_work_data(in_line_cnt).deliver_to1_alt;
                -- 届け先２（カナ）
    gt_req_edi_headers_data(in_line_cnt1).deli_to2_alt   := gt_edideli_work_data(in_line_cnt).deliver_to2_alt;
                -- 届け先住所（漢字）
    gt_req_edi_headers_data(in_line_cnt1).deli_to_add    := gt_edideli_work_data(in_line_cnt).deliver_to_address;
                -- 届け先住所（カナ）
    gt_req_edi_headers_data(in_line_cnt1).deli_to_add_alt
                                                   := gt_edideli_work_data(in_line_cnt).deliver_to_address_alt;
                -- 届け先ＴＥＬ
    gt_req_edi_headers_data(in_line_cnt1).deli_to_tel    := gt_edideli_work_data(in_line_cnt).deliver_to_tel;
                -- 帳合先コード
    gt_req_edi_headers_data(in_line_cnt1).bal_accounts_cd
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_code;
                -- 帳合先社コード
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_comp_cd
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_company_code;
                -- 帳合先店コード
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_shop_cd
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_shop_code;
                -- 帳合先名（漢字）
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_name   := gt_edideli_work_data(in_line_cnt).balance_accounts_name;
                -- 帳合先名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_name_alt;
                -- 帳合先住所（漢字）
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_add    := gt_edideli_work_data(in_line_cnt).balance_accounts_address;
                -- 帳合先住所（カナ）
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_add_alt
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_address_alt;
                -- 帳合先ＴＥＬ
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_tel    := gt_edideli_work_data(in_line_cnt).balance_accounts_tel;
                -- 受注可能日
    gt_req_edi_headers_data(in_line_cnt1).order_possible_date
                                                   := gt_edideli_work_data(in_line_cnt).order_possible_date;
                -- 許容可能日
    gt_req_edi_headers_data(in_line_cnt1).perm_poss_date := gt_edideli_work_data(in_line_cnt).permission_possible_date;
                -- 先限年月日
    gt_req_edi_headers_data(in_line_cnt1).forward_month  := gt_edideli_work_data(in_line_cnt).forward_month;
                -- 支払決済日
    gt_req_edi_headers_data(in_line_cnt1).pay_settl_date := gt_edideli_work_data(in_line_cnt).payment_settlement_date;
                -- チラシ開始日
    gt_req_edi_headers_data(in_line_cnt1).hand_st_date_act
                                                   := gt_edideli_work_data(in_line_cnt).handbill_start_date_active;
                -- 請求締日
    gt_req_edi_headers_data(in_line_cnt1).billing_due_date
                                                   := gt_edideli_work_data(in_line_cnt).billing_due_date;
                -- 出荷時刻
    gt_req_edi_headers_data(in_line_cnt1).shipping_time  := gt_edideli_work_data(in_line_cnt).shipping_time;
                -- 納品予定時間
    gt_req_edi_headers_data(in_line_cnt1).deli_schedule_time
                                                   := gt_edideli_work_data(in_line_cnt).delivery_schedule_time;
                -- 発注時間
    gt_req_edi_headers_data(in_line_cnt1).order_time     := gt_edideli_work_data(in_line_cnt).order_time;
                -- 汎用日付項目１
    gt_req_edi_headers_data(in_line_cnt1).general_date_item1
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item1;
                -- 汎用日付項目２
    gt_req_edi_headers_data(in_line_cnt1).general_date_item2
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item2;
                -- 汎用日付項目３
    gt_req_edi_headers_data(in_line_cnt1).general_date_item3
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item3;
                -- 汎用日付項目４
    gt_req_edi_headers_data(in_line_cnt1).general_date_item4
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item4;
                -- 汎用日付項目５
    gt_req_edi_headers_data(in_line_cnt1).general_date_item5
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item5;
                -- 入出荷区分
    gt_req_edi_headers_data(in_line_cnt1).arr_shipping_class
                                                   := gt_edideli_work_data(in_line_cnt).arrival_shipping_class;
                -- 取引先区分
    gt_req_edi_headers_data(in_line_cnt1).vendor_class   := gt_edideli_work_data(in_line_cnt).vendor_class;
                -- 伝票内訳区分
    gt_req_edi_headers_data(in_line_cnt1).inv_detailed_class
                                                   := gt_edideli_work_data(in_line_cnt).invoice_detailed_class;
                -- 単価使用区分
    gt_req_edi_headers_data(in_line_cnt1).unit_price_use_class
                                                   := gt_edideli_work_data(in_line_cnt).unit_price_use_class;
                -- サブ物流センターコード
    gt_req_edi_headers_data(in_line_cnt1).sub_dist_center_cd
                                                   := gt_edideli_work_data(in_line_cnt).sub_distribution_center_code;
                -- サブ物流センターコード名
    gt_req_edi_headers_data(in_line_cnt1).sub_dist_center_nm
                                                   := gt_edideli_work_data(in_line_cnt).sub_distribution_center_name;
                -- センター納品方法
    gt_req_edi_headers_data(in_line_cnt1).center_deli_method
                                                   := gt_edideli_work_data(in_line_cnt).center_delivery_method;
                -- センター利用区分
    gt_req_edi_headers_data(in_line_cnt1).center_use_class
                                                   := gt_edideli_work_data(in_line_cnt).center_use_class;
                -- センター倉庫区分
    gt_req_edi_headers_data(in_line_cnt1).center_whse_class
                                                   := gt_edideli_work_data(in_line_cnt).center_whse_class;
                -- センター地域区分
    gt_req_edi_headers_data(in_line_cnt1).center_area_class
                                                   := gt_edideli_work_data(in_line_cnt).center_area_class;
                -- センター入荷区分
    gt_req_edi_headers_data(in_line_cnt1).center_arr_class
                                                   := gt_edideli_work_data(in_line_cnt).center_arrival_class;
                -- デポ区分
    gt_req_edi_headers_data(in_line_cnt1).depot_class    := gt_edideli_work_data(in_line_cnt).depot_class;
                -- ＴＣＤＣ区分
    gt_req_edi_headers_data(in_line_cnt1).tcdc_class     := gt_edideli_work_data(in_line_cnt).tcdc_class;
                -- ＵＰＣフラグ
    gt_req_edi_headers_data(in_line_cnt1).upc_flag       := gt_edideli_work_data(in_line_cnt).upc_flag;
                -- 一斉区分
    gt_req_edi_headers_data(in_line_cnt1).simultaneously_cls
                                                   := gt_edideli_work_data(in_line_cnt).simultaneously_class;
                -- 業務ＩＤ
    gt_req_edi_headers_data(in_line_cnt1).business_id    := gt_edideli_work_data(in_line_cnt).business_id;
                -- 倉直区分
    gt_req_edi_headers_data(in_line_cnt1).whse_directly_cls
                                                   := gt_edideli_work_data(in_line_cnt).whse_directly_class;
                -- 景品割戻区分
    gt_req_edi_headers_data(in_line_cnt1).premium_rebate_cls
                                                   := gt_edideli_work_data(in_line_cnt).premium_rebate_class;
                -- 項目種別
    gt_req_edi_headers_data(in_line_cnt1).item_type      := gt_edideli_work_data(in_line_cnt).item_type;
                -- 衣家食区分
    gt_req_edi_headers_data(in_line_cnt1).cloth_hous_fod_cls
                                                   := gt_edideli_work_data(in_line_cnt).cloth_house_food_class;
                -- 混在区分
    gt_req_edi_headers_data(in_line_cnt1).mix_class      := gt_edideli_work_data(in_line_cnt).mix_class;
                -- 在庫区分
    gt_req_edi_headers_data(in_line_cnt1).stk_class      := gt_edideli_work_data(in_line_cnt).stk_class;
                -- 最終修正場所区分
    gt_req_edi_headers_data(in_line_cnt1).last_mod_site_cls
                                                   := gt_edideli_work_data(in_line_cnt).last_modify_site_class;
                -- 帳票区分
    gt_req_edi_headers_data(in_line_cnt1).report_class   := gt_edideli_work_data(in_line_cnt).report_class;
                -- 追加・計画区分
    gt_req_edi_headers_data(in_line_cnt1).add_plan_cls   := gt_edideli_work_data(in_line_cnt).addition_plan_class;
                -- 登録区分
    gt_req_edi_headers_data(in_line_cnt1).registration_class
                                                   := gt_edideli_work_data(in_line_cnt).registration_class;
                -- 特定区分
    gt_req_edi_headers_data(in_line_cnt1).specific_class := gt_edideli_work_data(in_line_cnt).specific_class;
                -- 取引区分
    gt_req_edi_headers_data(in_line_cnt1).dealings_class := gt_edideli_work_data(in_line_cnt).dealings_class;
                -- 発注区分
    gt_req_edi_headers_data(in_line_cnt1).order_class    := gt_edideli_work_data(in_line_cnt).order_class;
                -- 集計明細区分
    gt_req_edi_headers_data(in_line_cnt1).sum_line_class := gt_edideli_work_data(in_line_cnt).sum_line_class;
                -- 出荷案内以外区分
    gt_req_edi_headers_data(in_line_cnt1).ship_guidance_cls
                                                   := gt_edideli_work_data(in_line_cnt).shipping_guidance_class;
                -- 出荷区分
    gt_req_edi_headers_data(in_line_cnt1).shipping_class := gt_edideli_work_data(in_line_cnt).shipping_class;
                -- 商品コード使用区分
    gt_req_edi_headers_data(in_line_cnt1).prod_cd_use_cls
                                                   := gt_edideli_work_data(in_line_cnt).product_code_use_class;
                -- 積送品区分
    gt_req_edi_headers_data(in_line_cnt1).cargo_item_class
                                                   := gt_edideli_work_data(in_line_cnt).cargo_item_class;
                -- Ｔ／Ａ区分
    gt_req_edi_headers_data(in_line_cnt1).ta_class       := gt_edideli_work_data(in_line_cnt).ta_class;
                -- 企画コード
    gt_req_edi_headers_data(in_line_cnt1).plan_code      := gt_edideli_work_data(in_line_cnt).plan_code;
                -- カテゴリーコード
    gt_req_edi_headers_data(in_line_cnt1).category_code  := gt_edideli_work_data(in_line_cnt).category_code;
                -- カテゴリー区分
    gt_req_edi_headers_data(in_line_cnt1).category_class := gt_edideli_work_data(in_line_cnt).category_class;
                -- 運送手段
    gt_req_edi_headers_data(in_line_cnt1).carrier_means  := gt_edideli_work_data(in_line_cnt).carrier_means;
                -- 売場コード
    gt_req_edi_headers_data(in_line_cnt1).counter_code   := gt_edideli_work_data(in_line_cnt).counter_code;
                -- 移動サイン
    gt_req_edi_headers_data(in_line_cnt1).move_sign      := gt_edideli_work_data(in_line_cnt).move_sign;
                -- ＥＯＳ・手書区分
    gt_req_edi_headers_data(in_line_cnt1).eos_handwrit_cls
                                                   := gt_edideli_work_data(in_line_cnt).eos_handwriting_class;
                -- 納品先課コード
    gt_req_edi_headers_data(in_line_cnt1).deli_to_section_cd
                                                   := gt_edideli_work_data(in_line_cnt).delivery_to_section_code;
                -- 伝票内訳
    gt_req_edi_headers_data(in_line_cnt1).invoice_detailed
                                                   := gt_edideli_work_data(in_line_cnt).invoice_detailed;
                -- 添付数
    gt_req_edi_headers_data(in_line_cnt1).attach_qty     := gt_edideli_work_data(in_line_cnt).attach_qty;
                -- フロア
    gt_req_edi_headers_data(in_line_cnt1).other_party_floor
                                                   := gt_edideli_work_data(in_line_cnt).other_party_floor;
                -- ＴＥＸＴＮｏ
    gt_req_edi_headers_data(in_line_cnt1).text_no        := gt_edideli_work_data(in_line_cnt).text_no;
                -- インストアコード
    gt_req_edi_headers_data(in_line_cnt1).in_store_code  := gt_edideli_work_data(in_line_cnt).in_store_code;
                -- タグ
    gt_req_edi_headers_data(in_line_cnt1).tag_data       := gt_edideli_work_data(in_line_cnt).tag_data;
                -- 競合
    gt_req_edi_headers_data(in_line_cnt1).competition_code
                                                   := gt_edideli_work_data(in_line_cnt).competition_code;
                -- 請求口座
    gt_req_edi_headers_data(in_line_cnt1).billing_chair  := gt_edideli_work_data(in_line_cnt).billing_chair;
                -- チェーンストアーコード
    gt_req_edi_headers_data(in_line_cnt1).chain_store_code
                                                   := gt_edideli_work_data(in_line_cnt).chain_store_code;
                -- チェーンストアーコード略式名称
    gt_req_edi_headers_data(in_line_cnt1).chain_st_sh_name
                                                   := gt_edideli_work_data(in_line_cnt).chain_store_short_name;
                -- 直配送／引取料
    gt_req_edi_headers_data(in_line_cnt1).dir_deli_rcpt_fee
                                                   := gt_edideli_work_data(in_line_cnt).direct_delivery_rcpt_fee;
                -- 手形情報
    gt_req_edi_headers_data(in_line_cnt1).bill_info      := gt_edideli_work_data(in_line_cnt).bill_info;
                -- 摘要
    gt_req_edi_headers_data(in_line_cnt1).description    := gt_edideli_work_data(in_line_cnt).description;
                -- 内部コード
    gt_req_edi_headers_data(in_line_cnt1).interior_code  := gt_edideli_work_data(in_line_cnt).interior_code;
                -- 発注情報　納品カテゴリー
    gt_req_edi_headers_data(in_line_cnt1).order_in_deli_cate
                                                   := gt_edideli_work_data(in_line_cnt).order_info_delivery_category;
                -- 仕入形態
    gt_req_edi_headers_data(in_line_cnt1).purchase_type  := gt_edideli_work_data(in_line_cnt).purchase_type;
                -- 納品場所名（カナ）
    gt_req_edi_headers_data(in_line_cnt1).deli_to_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).delivery_to_name_alt;
                -- 店出場所
    gt_req_edi_headers_data(in_line_cnt1).shop_opened_site
                                                   := gt_edideli_work_data(in_line_cnt).shop_opened_site;
                -- 売場名
    gt_req_edi_headers_data(in_line_cnt1).counter_name   := gt_edideli_work_data(in_line_cnt).counter_name;
                -- 内線番号
    gt_req_edi_headers_data(in_line_cnt1).extension_number
                                                   := gt_edideli_work_data(in_line_cnt).extension_number;
                -- 担当者名
    gt_req_edi_headers_data(in_line_cnt1).charge_name    := gt_edideli_work_data(in_line_cnt).charge_name;
                -- 値札
    gt_req_edi_headers_data(in_line_cnt1).price_tag      := gt_edideli_work_data(in_line_cnt).price_tag;
                -- 税種
    gt_req_edi_headers_data(in_line_cnt1).tax_type       := gt_edideli_work_data(in_line_cnt).tax_type;
                -- 消費税区分
    gt_req_edi_headers_data(in_line_cnt1).consump_tax_cls
                                                   := gt_edideli_work_data(in_line_cnt).consumption_tax_class;
                -- ＢＲ
    gt_req_edi_headers_data(in_line_cnt1).brand_class    := gt_edideli_work_data(in_line_cnt).brand_class;
                -- ＩＤコード
    gt_req_edi_headers_data(in_line_cnt1).id_code        := gt_edideli_work_data(in_line_cnt).id_code;
                -- 百貨店コード
    gt_req_edi_headers_data(in_line_cnt1).department_code
                                                   := gt_edideli_work_data(in_line_cnt).department_code;
                -- 百貨店名
    gt_req_edi_headers_data(in_line_cnt1).department_name
                                                   := gt_edideli_work_data(in_line_cnt).department_name;
                -- 品別番号
    gt_req_edi_headers_data(in_line_cnt1).item_type_number
                                                   := gt_edideli_work_data(in_line_cnt).item_type_number;
                -- 摘要（百貨店）
    gt_req_edi_headers_data(in_line_cnt1).description_depart
                                                   := gt_edideli_work_data(in_line_cnt).description_department;
                -- 値札方法
    gt_req_edi_headers_data(in_line_cnt1).price_tag_method
                                                   := gt_edideli_work_data(in_line_cnt).price_tag_method;
                -- 自由欄
    gt_req_edi_headers_data(in_line_cnt1).reason_column  := gt_edideli_work_data(in_line_cnt).reason_column;
                -- Ａ欄ヘッダ
    gt_req_edi_headers_data(in_line_cnt1).a_column_header
                                                   := gt_edideli_work_data(in_line_cnt).a_column_header;
                -- Ｄ欄ヘッダ
    gt_req_edi_headers_data(in_line_cnt1).d_column_header
                                                   := gt_edideli_work_data(in_line_cnt).d_column_header;
                -- ブランドコード
    gt_req_edi_headers_data(in_line_cnt1).brand_code     := gt_edideli_work_data(in_line_cnt).brand_code;
                -- ラインコード
    gt_req_edi_headers_data(in_line_cnt1).line_code      := gt_edideli_work_data(in_line_cnt).line_code;
                -- クラスコード
    gt_req_edi_headers_data(in_line_cnt1).class_code     := gt_edideli_work_data(in_line_cnt).class_code;
                -- Ａ－１欄
    gt_req_edi_headers_data(in_line_cnt1).a1_column      := gt_edideli_work_data(in_line_cnt).a1_column;
                -- Ｂ－１欄
    gt_req_edi_headers_data(in_line_cnt1).b1_column      := gt_edideli_work_data(in_line_cnt).b1_column;
                -- Ｃ－１欄
    gt_req_edi_headers_data(in_line_cnt1).c1_column      := gt_edideli_work_data(in_line_cnt).c1_column;
                -- Ｄ－１欄
    gt_req_edi_headers_data(in_line_cnt1).d1_column      := gt_edideli_work_data(in_line_cnt).d1_column;
                -- Ｅ－１欄
    gt_req_edi_headers_data(in_line_cnt1).e1_column      := gt_edideli_work_data(in_line_cnt).e1_column;
                -- Ａ－２欄
    gt_req_edi_headers_data(in_line_cnt1).a2_column      := gt_edideli_work_data(in_line_cnt).a2_column;
                -- Ｂ－２欄
    gt_req_edi_headers_data(in_line_cnt1).b2_column      := gt_edideli_work_data(in_line_cnt).b2_column;
                -- Ｃ－２欄
    gt_req_edi_headers_data(in_line_cnt1).c2_column      := gt_edideli_work_data(in_line_cnt).c2_column;
                -- Ｄ－２欄
    gt_req_edi_headers_data(in_line_cnt1).d2_column      := gt_edideli_work_data(in_line_cnt).d2_column;
                -- Ｅ－２欄
    gt_req_edi_headers_data(in_line_cnt1).e2_column      := gt_edideli_work_data(in_line_cnt).e2_column;
                -- Ａ－３欄
    gt_req_edi_headers_data(in_line_cnt1).a3_column      := gt_edideli_work_data(in_line_cnt).a3_column;
                -- Ｂ－３欄
    gt_req_edi_headers_data(in_line_cnt1).b3_column      := gt_edideli_work_data(in_line_cnt).b3_column;
                -- Ｃ－３欄
    gt_req_edi_headers_data(in_line_cnt1).c3_column      := gt_edideli_work_data(in_line_cnt).c3_column;
                -- Ｄ－３欄
    gt_req_edi_headers_data(in_line_cnt1).d3_column      := gt_edideli_work_data(in_line_cnt).d3_column;
                -- Ｅ－３欄
    gt_req_edi_headers_data(in_line_cnt1).e3_column      := gt_edideli_work_data(in_line_cnt).e3_column;
                -- Ｆ－１欄
    gt_req_edi_headers_data(in_line_cnt1).f1_column      := gt_edideli_work_data(in_line_cnt).f1_column;
                -- Ｇ－１欄
    gt_req_edi_headers_data(in_line_cnt1).g1_column      := gt_edideli_work_data(in_line_cnt).g1_column;
                -- Ｈ－１欄
    gt_req_edi_headers_data(in_line_cnt1).h1_column      := gt_edideli_work_data(in_line_cnt).h1_column;
                -- Ｉ－１欄
    gt_req_edi_headers_data(in_line_cnt1).i1_column      := gt_edideli_work_data(in_line_cnt).i1_column;
                -- Ｊ－１欄
    gt_req_edi_headers_data(in_line_cnt1).j1_column      := gt_edideli_work_data(in_line_cnt).j1_column;
                -- Ｋ－１欄
    gt_req_edi_headers_data(in_line_cnt1).k1_column      := gt_edideli_work_data(in_line_cnt).k1_column;
                -- Ｌ－１欄
    gt_req_edi_headers_data(in_line_cnt1).l1_column      := gt_edideli_work_data(in_line_cnt).l1_column;
                -- Ｆ－２欄
    gt_req_edi_headers_data(in_line_cnt1).f2_column      := gt_edideli_work_data(in_line_cnt).f2_column;
                -- Ｇ－２欄
    gt_req_edi_headers_data(in_line_cnt1).g2_column      := gt_edideli_work_data(in_line_cnt).g2_column;
                -- Ｈ－２欄
    gt_req_edi_headers_data(in_line_cnt1).h2_column      := gt_edideli_work_data(in_line_cnt).h2_column;
                -- Ｉ－２欄
    gt_req_edi_headers_data(in_line_cnt1).i2_column      := gt_edideli_work_data(in_line_cnt).i2_column;
                -- Ｊ－２欄
    gt_req_edi_headers_data(in_line_cnt1).j2_column      := gt_edideli_work_data(in_line_cnt).j2_column;
                -- Ｋ－２欄
    gt_req_edi_headers_data(in_line_cnt1).k2_column      := gt_edideli_work_data(in_line_cnt).k2_column;
                -- Ｌ－２欄
    gt_req_edi_headers_data(in_line_cnt1).l2_column      := gt_edideli_work_data(in_line_cnt).l2_column;
                -- Ｆ－３欄
    gt_req_edi_headers_data(in_line_cnt1).f3_column      := gt_edideli_work_data(in_line_cnt).f3_column;
                -- Ｇ－３欄
    gt_req_edi_headers_data(in_line_cnt1).g3_column      := gt_edideli_work_data(in_line_cnt).g3_column;
                -- Ｈ－３欄
    gt_req_edi_headers_data(in_line_cnt1).h3_column      := gt_edideli_work_data(in_line_cnt).h3_column;
                -- Ｉ－３欄
    gt_req_edi_headers_data(in_line_cnt1).i3_column      := gt_edideli_work_data(in_line_cnt).i3_column;
                -- Ｊ－３欄
    gt_req_edi_headers_data(in_line_cnt1).j3_column      := gt_edideli_work_data(in_line_cnt).j3_column;
                -- Ｋ－３欄
    gt_req_edi_headers_data(in_line_cnt1).k3_column      := gt_edideli_work_data(in_line_cnt).k3_column;
                -- Ｌ－３欄
    gt_req_edi_headers_data(in_line_cnt1).l3_column      := gt_edideli_work_data(in_line_cnt).l3_column;
                -- チェーン店固有エリア（ヘッダー）
-- 2010/04/23 v1.8 T.Yoshimoto Mod Start 本稼動#2427
--    gt_req_edi_headers_data(in_line_cnt1).chain_pecarea_head
    gt_req_edi_headers_data(in_line_cnt1).chain_pe_area_head
-- 2010/04/23 v1.8 T.Yoshimoto Mod End 本稼動#2427
                                                   := gt_edideli_work_data(in_line_cnt).chain_peculiar_area_header;
                -- 受注関連番号
    gt_req_edi_headers_data(in_line_cnt1).order_connect_num
                                                   := gt_edideli_work_data(in_line_cnt).order_connection_number;
                -- （総合計）発注数量（バラ）
    gt_req_edi_headers_data(in_line_cnt1).tot_indv_order_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_indv_order_qty;
                -- （総合計）発注数量（ケース）
    gt_req_edi_headers_data(in_line_cnt1).tot_case_order_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_case_order_qty;
                -- （総合計）発注数量（ボール）
    gt_req_edi_headers_data(in_line_cnt1).tot_ball_order_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_ball_order_qty;
                -- （総合計）発注数量（合計、バラ）
    gt_req_edi_headers_data(in_line_cnt1).tot_sum_order_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_sum_order_qty;
                -- （総合計）出荷数量（バラ）
    gt_req_edi_headers_data(in_line_cnt1).tot_indv_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_indv_shipping_qty;
                -- （総合計）出荷数量（ケース）
    gt_req_edi_headers_data(in_line_cnt1).tot_case_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_case_shipping_qty;
                -- （総合計）出荷数量（ボール）
    gt_req_edi_headers_data(in_line_cnt1).tot_ball_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_ball_shipping_qty;
                -- （総合計）出荷数量（パレット）
    gt_req_edi_headers_data(in_line_cnt1).tot_pallet_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_pallet_shipping_qty;
                -- （総合計）出荷数量（合計、バラ）
    gt_req_edi_headers_data(in_line_cnt1).tot_sum_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_sum_shipping_qty;
                -- （総合計）欠品数量（バラ）
    gt_req_edi_headers_data(in_line_cnt1).tot_indv_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_indv_stockout_qty;
                -- （総合計）欠品数量（ケース）
    gt_req_edi_headers_data(in_line_cnt1).tot_case_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_case_stockout_qty;
                -- （総合計）欠品数量（ボール）
    gt_req_edi_headers_data(in_line_cnt1).tot_ball_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_ball_stockout_qty;
                -- （総合計）欠品数量（合計、バラ）
    gt_req_edi_headers_data(in_line_cnt1).tot_sum_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_sum_stockout_qty;
                -- （総合計）ケース個口数
    gt_req_edi_headers_data(in_line_cnt1).tot_case_qty   := gt_edideli_work_data(in_line_cnt).total_case_qty;
                -- （総合計）オリコン（バラ）個口数
    gt_req_edi_headers_data(in_line_cnt1).tot_fold_container_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_fold_container_qty;
                -- （総合計）原価金額（発注）
    gt_req_edi_headers_data(in_line_cnt1).tot_order_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_order_cost_amt;
                -- （総合計）原価金額（出荷）
    gt_req_edi_headers_data(in_line_cnt1).tot_ship_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_shipping_cost_amt;
                -- （総合計）原価金額（欠品）
    gt_req_edi_headers_data(in_line_cnt1).tot_stockout_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_stockout_cost_amt;
                -- （総合計）売価金額（発注）
    gt_req_edi_headers_data(in_line_cnt1).tot_order_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_order_price_amt;
                -- （総合計）売価金額（出荷）
    gt_req_edi_headers_data(in_line_cnt1).tot_ship_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_shipping_price_amt;
                -- （総合計）売価金額（欠品）
    gt_req_edi_headers_data(in_line_cnt1).tot_stockout_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_stockout_price_amt;
                -- トータル行数
    gt_req_edi_headers_data(in_line_cnt1).tot_line_qty   := gt_edideli_work_data(in_line_cnt).total_line_qty;
                -- トータル伝票枚数
    gt_req_edi_headers_data(in_line_cnt1).tot_invoice_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_invoice_qty;
                -- チェーン店固有エリア（フッター）
    gt_req_edi_headers_data(in_line_cnt1).chain_pe_area_foot
                                                   := gt_edideli_work_data(in_line_cnt).chain_peculiar_area_footer;
/* 2011/07/26 Ver1.9 Add Start */
                --流通ＢＭＳヘッダデータ
    gt_req_edi_headers_data(in_line_cnt1).bms_header_data
                                                   := gt_edideli_work_data(in_line_cnt).bms_header_data;
/* 2011/07/26 Ver1.9 Add End   */
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END xxcos_in_edi_headers_edit;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_lists_edit
   * Description      : EDI明細情報変数の編集(A-2)(2)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_lists_edit(
    in_line_cnt    IN NUMBER,       --   LOOP用カウンタ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_lists_edit'; -- プログラム名
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
    ln_seq     NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    -- EDI明細情報IDをシーケンスから取得する
    SELECT xxcos_edi_lines_s01.NEXTVAL
    INTO   ln_seq
    FROM   dual;
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  --
  --* -------------------------------------------------------------------------------------------
  -- EDI明細情報テーブルデータ登録用変数(XXCOS_IN_EDI_LINES)
  --* -------------------------------------------------------------------------------------------
    gt_req_edi_lines_data(in_line_cnt).edi_line_info_id    := ln_seq;                     -- EDI明細情報ID
    gt_req_edi_lines_data(in_line_cnt).invoice_number      := gt_head_invoice_number_key; -- 伝票番号
    gt_req_edi_lines_data(in_line_cnt).edi_header_info_id  := gt_edi_header_info_id;      -- EDIヘッダ情報ID
                -- 行Ｎｏ
    gt_req_edi_lines_data(in_line_cnt).line_no          := gt_edideli_work_data(in_line_cnt).line_no;
                -- 欠品区分
    gt_req_edi_lines_data(in_line_cnt).stockout_class   := gt_edideli_work_data(in_line_cnt).stockout_class;
                -- 欠品理由
    gt_req_edi_lines_data(in_line_cnt).stockout_reason  := gt_edideli_work_data(in_line_cnt).stockout_reason;
                -- 商品コード（伊藤園）
    gt_req_edi_lines_data(in_line_cnt).product_code_itouen
                                                   := gt_edideli_work_data(in_line_cnt).product_code_itouen;
                -- 商品コード１
    gt_req_edi_lines_data(in_line_cnt).product_code1    := gt_edideli_work_data(in_line_cnt).product_code1;
                -- 商品コード２
    gt_req_edi_lines_data(in_line_cnt).product_code2    := gt_edideli_work_data(in_line_cnt).product_code2;
                -- ＪＡＮコード
    gt_req_edi_lines_data(in_line_cnt).jan_code         := gt_edideli_work_data(in_line_cnt).jan_code;
                -- ＩＴＦコード
    gt_req_edi_lines_data(in_line_cnt).itf_code         := gt_edideli_work_data(in_line_cnt).itf_code;
                -- 内箱ＩＴＦコード
    gt_req_edi_lines_data(in_line_cnt).extension_itf_code
                                                   := gt_edideli_work_data(in_line_cnt).extension_itf_code;
                -- ケース商品コード
    gt_req_edi_lines_data(in_line_cnt).case_product_code
                                                   := gt_edideli_work_data(in_line_cnt).case_product_code;
                -- ボール商品コード
    gt_req_edi_lines_data(in_line_cnt).ball_product_code
                                                   := gt_edideli_work_data(in_line_cnt).ball_product_code;
                -- 商品コード品種
    gt_req_edi_lines_data(in_line_cnt).prod_cd_item_type
                                                   := gt_edideli_work_data(in_line_cnt).product_code_item_type;
                -- 商品区分
    gt_req_edi_lines_data(in_line_cnt).prod_class       := gt_edideli_work_data(in_line_cnt).prod_class;
                -- 商品名（漢字）
    gt_req_edi_lines_data(in_line_cnt).product_name     := gt_edideli_work_data(in_line_cnt).product_name;
                -- 商品名２（カナ）
    gt_req_edi_lines_data(in_line_cnt).product_name1_alt
                                                   := gt_edideli_work_data(in_line_cnt).product_name1_alt;
                -- 商品名２（カナ）
    gt_req_edi_lines_data(in_line_cnt).product_name2_alt
                                                   := gt_edideli_work_data(in_line_cnt).product_name2_alt;
                -- 規格１
    gt_req_edi_lines_data(in_line_cnt).item_standard1   := gt_edideli_work_data(in_line_cnt).item_standard1;
                -- 規格２
    gt_req_edi_lines_data(in_line_cnt).item_standard2   := gt_edideli_work_data(in_line_cnt).item_standard2;
                -- 入数
    gt_req_edi_lines_data(in_line_cnt).qty_in_case      := gt_edideli_work_data(in_line_cnt).qty_in_case;
                -- ケース入数
    gt_req_edi_lines_data(in_line_cnt).num_of_cases     := gt_edideli_work_data(in_line_cnt).num_of_cases;
                -- ボール入数
    gt_req_edi_lines_data(in_line_cnt).num_of_ball      := gt_edideli_work_data(in_line_cnt).num_of_ball;
                -- 色
    gt_req_edi_lines_data(in_line_cnt).item_color       := gt_edideli_work_data(in_line_cnt).item_color;
                -- サイズ
    gt_req_edi_lines_data(in_line_cnt).item_size        := gt_edideli_work_data(in_line_cnt).item_size;
                -- 賞味期限日
    gt_req_edi_lines_data(in_line_cnt).expiration_date  := gt_edideli_work_data(in_line_cnt).expiration_date;
                -- 製造日
    gt_req_edi_lines_data(in_line_cnt).product_date     := gt_edideli_work_data(in_line_cnt).product_date;
                -- 発注単位数
    gt_req_edi_lines_data(in_line_cnt).order_uom_qty    := gt_edideli_work_data(in_line_cnt).order_uom_qty;
                -- 出荷単位数
    gt_req_edi_lines_data(in_line_cnt).ship_uom_qty     := gt_edideli_work_data(in_line_cnt).shipping_uom_qty;
                -- 梱包単位数
    gt_req_edi_lines_data(in_line_cnt).packing_uom_qty  := gt_edideli_work_data(in_line_cnt).packing_uom_qty;
                -- 引合
    gt_req_edi_lines_data(in_line_cnt).deal_code        := gt_edideli_work_data(in_line_cnt).deal_code;
                -- 引合区分
    gt_req_edi_lines_data(in_line_cnt).deal_class       := gt_edideli_work_data(in_line_cnt).deal_class;
                -- 照合
    gt_req_edi_lines_data(in_line_cnt).collation_code   := gt_edideli_work_data(in_line_cnt).collation_code;
                -- 単位
    gt_req_edi_lines_data(in_line_cnt).uom_code         := gt_edideli_work_data(in_line_cnt).uom_code;
                -- 単価区分
    gt_req_edi_lines_data(in_line_cnt).unit_price_class := gt_edideli_work_data(in_line_cnt).unit_price_class;
                -- 親梱包番号
    gt_req_edi_lines_data(in_line_cnt).parent_pack_num  := gt_edideli_work_data(in_line_cnt).parent_packing_number;
                -- 梱包番号
    gt_req_edi_lines_data(in_line_cnt).packing_number   := gt_edideli_work_data(in_line_cnt).packing_number;
                -- 商品群コード
    gt_req_edi_lines_data(in_line_cnt).product_group_code
                                                   := gt_edideli_work_data(in_line_cnt).product_group_code;
                -- ケース解体不可フラグ
    gt_req_edi_lines_data(in_line_cnt).case_dismantle_flag
                                                   := gt_edideli_work_data(in_line_cnt).case_dismantle_flag;
                -- ケース区分
    gt_req_edi_lines_data(in_line_cnt).case_class       := gt_edideli_work_data(in_line_cnt).case_class;
                -- 発注数量（バラ）
    gt_req_edi_lines_data(in_line_cnt).indv_order_qty   := gt_edideli_work_data(in_line_cnt).indv_order_qty;
                -- 発注数量（ケース）
    gt_req_edi_lines_data(in_line_cnt).case_order_qty   := gt_edideli_work_data(in_line_cnt).case_order_qty;
                -- 発注数量（ボール）
    gt_req_edi_lines_data(in_line_cnt).ball_order_qty   := gt_edideli_work_data(in_line_cnt).ball_order_qty;
                -- 発注数量（合計、バラ）
    gt_req_edi_lines_data(in_line_cnt).sum_order_qty    := gt_edideli_work_data(in_line_cnt).sum_order_qty;
                -- 出荷数量（バラ）
    gt_req_edi_lines_data(in_line_cnt).indv_shipping_qty
                                                   := gt_edideli_work_data(in_line_cnt).indv_shipping_qty;
                -- 出荷数量（ケース）
    gt_req_edi_lines_data(in_line_cnt).case_shipping_qty
                                                   := gt_edideli_work_data(in_line_cnt).case_shipping_qty;
                -- 出荷数量（ボール）
    gt_req_edi_lines_data(in_line_cnt).ball_shipping_qty
                                                   := gt_edideli_work_data(in_line_cnt).ball_shipping_qty;
                -- 出荷数量（パレット）
    gt_req_edi_lines_data(in_line_cnt).pallet_shipping_qty
                                                   := gt_edideli_work_data(in_line_cnt).pallet_shipping_qty;
                -- 出荷数量（合計、バラ）
    gt_req_edi_lines_data(in_line_cnt).sum_shipping_qty := gt_edideli_work_data(in_line_cnt).sum_shipping_qty;
                -- 欠品数量（バラ）
    gt_req_edi_lines_data(in_line_cnt).indv_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).indv_stockout_qty;
                -- 欠品数量（ケース）
    gt_req_edi_lines_data(in_line_cnt).case_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).case_stockout_qty;
                -- 欠品数量（ボール）
    gt_req_edi_lines_data(in_line_cnt).ball_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).ball_stockout_qty;
                -- 欠品数量（合計、バラ）
    gt_req_edi_lines_data(in_line_cnt).sum_stockout_qty := gt_edideli_work_data(in_line_cnt).sum_stockout_qty;
                -- ケース個口数
    gt_req_edi_lines_data(in_line_cnt).case_qty         := gt_edideli_work_data(in_line_cnt).case_qty;
                -- オリコン（バラ）個口数
    gt_req_edi_lines_data(in_line_cnt).fold_cont_indv_qty
                                                   := gt_edideli_work_data(in_line_cnt).fold_container_indv_qty;
                -- 原単価（出荷）
    gt_req_edi_lines_data(in_line_cnt).shipping_unit_price
                                                   := gt_edideli_work_data(in_line_cnt).shipping_unit_price;
                -- 原価金額（発注）
    gt_req_edi_lines_data(in_line_cnt).order_cost_amt   := gt_edideli_work_data(in_line_cnt).order_cost_amt;
                -- 原価金額（出荷）
    gt_req_edi_lines_data(in_line_cnt).shipping_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).shipping_cost_amt;
                -- 原価金額（欠品）
    gt_req_edi_lines_data(in_line_cnt).stockout_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).stockout_cost_amt;
                -- 売単価
    gt_req_edi_lines_data(in_line_cnt).selling_price    := gt_edideli_work_data(in_line_cnt).selling_price;
                -- 売価金額（発注）
    gt_req_edi_lines_data(in_line_cnt).order_price_amt  := gt_edideli_work_data(in_line_cnt).order_price_amt;
                -- 売価金額（出荷）
    gt_req_edi_lines_data(in_line_cnt).shipping_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).shipping_price_amt;
                -- 売価金額（欠品）
    gt_req_edi_lines_data(in_line_cnt).stockout_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).stockout_price_amt;
                -- Ａ欄（百貨店）
    gt_req_edi_lines_data(in_line_cnt).a_col_department := gt_edideli_work_data(in_line_cnt).a_column_department;
                -- Ｄ欄（百貨店）
    gt_req_edi_lines_data(in_line_cnt).d_col_department := gt_edideli_work_data(in_line_cnt).d_column_department;
                -- 規格情報・奥行き
    gt_req_edi_lines_data(in_line_cnt).stand_info_depth := gt_edideli_work_data(in_line_cnt).standard_info_depth;
                -- 規格情報・高さ
    gt_req_edi_lines_data(in_line_cnt).stand_info_height
                                                   := gt_edideli_work_data(in_line_cnt).standard_info_height;
                -- 規格情報・幅
    gt_req_edi_lines_data(in_line_cnt).stand_info_width := gt_edideli_work_data(in_line_cnt).standard_info_width;
                -- 規格情報・重量
    gt_req_edi_lines_data(in_line_cnt).stand_info_weight
                                                   := gt_edideli_work_data(in_line_cnt).standard_info_weight;
                -- 汎用引継ぎ項目１
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item1
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item1;
                -- 汎用引継ぎ項目２
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item2
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item2;
                -- 汎用引継ぎ項目３
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item3
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item3;
                -- 汎用引継ぎ項目４
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item4
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item4;
                -- 汎用引継ぎ項目５
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item5
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item5;
                -- 汎用引継ぎ項目６
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item6
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item6;
                -- 汎用引継ぎ項目７
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item7
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item7;
                -- 汎用引継ぎ項目８
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item8
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item8;
                -- 汎用引継ぎ項目９
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item9
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item9;
                -- 汎用引継ぎ項目１０
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item10
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item10;
                -- 汎用付加項目１
    gt_req_edi_lines_data(in_line_cnt).gen_add_item1    := gt_edideli_work_data(in_line_cnt).general_add_item1;
                -- 汎用付加項目２
    gt_req_edi_lines_data(in_line_cnt).gen_add_item2    := gt_edideli_work_data(in_line_cnt).general_add_item2;
                -- 汎用付加項目３
    gt_req_edi_lines_data(in_line_cnt).gen_add_item3    := gt_edideli_work_data(in_line_cnt).general_add_item3;
                -- 汎用付加項目４
    gt_req_edi_lines_data(in_line_cnt).gen_add_item4    := gt_edideli_work_data(in_line_cnt).general_add_item4;
                -- 汎用付加項目５
    gt_req_edi_lines_data(in_line_cnt).gen_add_item5    := gt_edideli_work_data(in_line_cnt).general_add_item5;
                -- 汎用付加項目６
    gt_req_edi_lines_data(in_line_cnt).gen_add_item6    := gt_edideli_work_data(in_line_cnt).general_add_item6;
                -- 汎用付加項目７
    gt_req_edi_lines_data(in_line_cnt).gen_add_item7    := gt_edideli_work_data(in_line_cnt).general_add_item7;
                -- 汎用付加項目８
    gt_req_edi_lines_data(in_line_cnt).gen_add_item8    := gt_edideli_work_data(in_line_cnt).general_add_item8;
                -- 汎用付加項目９
    gt_req_edi_lines_data(in_line_cnt).gen_add_item9    := gt_edideli_work_data(in_line_cnt).general_add_item9;
                -- 汎用付加項目１０
    gt_req_edi_lines_data(in_line_cnt).gen_add_item10   := gt_edideli_work_data(in_line_cnt).general_add_item10;
                -- チェーン店固有エリア（明細）
    gt_req_edi_lines_data(in_line_cnt).chain_pec_a_line := gt_edideli_work_data(in_line_cnt).chain_peculiar_area_line;
/* 2011/07/26 Ver1.9 Add Start */
                -- 流通ＢＭＳ明細データ
   gt_req_edi_lines_data(in_line_cnt).bms_line_data     := gt_edideli_work_data(in_line_cnt).bms_line_data;
/* 2011/07/26 Ver1.9 Add End   */
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END xxcos_in_edi_lists_edit;
--
  /**********************************************************************************
   * Procedure Name   : data_check
   * Description      : データ妥当性チェック(A-3)
   ***********************************************************************************/
  PROCEDURE data_check(
    in_line_cnt    IN NUMBER,       --   LOOP用カウンタ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- プログラム名
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
    lv_process_flag            VARCHAR2(1);                                 -- 各処理の処理結果フラグ
    lt_chain_account_number    hz_cust_accounts.account_number%TYPE;        -- 顧客コード(チェーン店)
    lt_head_price_list_id      hz_cust_site_uses_all.price_list_id%TYPE;    -- 価格表ID
    lt_unit_price              qp_list_lines.operand%TYPE;                  -- 単価
    lt_head_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE;  -- EDI連携品目コード区分
    lv_edi_chain_code          VARCHAR2(100) DEFAULT NULL; --ﾜｰｸ用ﾁｪｰﾝ店ｺｰﾄﾞ
    lv_store_code              VARCHAR2(100) DEFAULT NULL; --ﾜｰｸ用店ｺｰﾄﾞ
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
    lv_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --処理結果フラグの初期化
    lv_process_flag := cv_status_normal;
--
    --==============================================================
    -- ＥＤＩチェーン店コード
    gt_req_edi_headers_data(in_line_cnt).edi_chain_code := gt_edideli_work_data(in_line_cnt).edi_chain_code;
    -- 店コード
    gt_req_edi_headers_data(in_line_cnt).shop_code      := gt_edideli_work_data(in_line_cnt).shop_code;
    -- 発注数量（合計、バラ）
    gt_req_edi_lines_data(in_line_cnt).sum_order_qty    := gt_edideli_work_data(in_line_cnt).sum_order_qty;
    -- 伝票番号
    gt_req_edi_headers_data(in_line_cnt).invoice_number := gt_edideli_work_data(in_line_cnt).invoice_number;
    gt_req_edi_lines_data(in_line_cnt).invoice_number   := gt_edideli_work_data(in_line_cnt).invoice_number;
    -- 顧客コード
    gt_req_edi_headers_data(in_line_cnt).customer_code  := gt_edideli_work_data(in_line_cnt).customer_code;
    -- 商品コード２
    gt_req_edi_lines_data(in_line_cnt).product_code2    := gt_edideli_work_data(in_line_cnt).product_code2;
    -- 原単価(発注)
    gt_req_edi_lines_data(in_line_cnt).order_unit_price := gt_edideli_work_data(in_line_cnt).order_unit_price;
--****************************** 2009/06/29 1.5 T.Tominaga ADD START ******************************
    -- 品目ID
    gt_req_mtl_sys_items(in_line_cnt).inventory_item_id := NULL;
    -- 品目コード
    gt_req_mtl_sys_items(in_line_cnt).segment1          := NULL;
    -- 基準単価
    gt_req_mtl_sys_items(in_line_cnt).unit_of_measure   := NULL;
--****************************** 2009/06/29 1.5 T.Tominaga ADD END   ******************************
    --==============================================================
--****************************** 2009/06/29 1.5 T.Tominaga DEL START ******************************
--      --==============================================================
--      -- 店コードチェック
--      --==============================================================
--      IF  ( gt_req_edi_headers_data(in_line_cnt).shop_code IS NULL )  THEN
--        --* -------------------------------------------------------------
--        --必須エラーメッセージ  gv_msg_in_none_err
--        --* -------------------------------------------------------------
--        lv_process_flag :=  cv_status_error;
--        ov_retcode      :=  cv_status_warn;
--        -- 納品返品ワークID(error)
--        gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--        --ステータス(error)
--        gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--        -- トークン取得(店コード)
--        gv_tkn_shop_code :=  xxccp_common_pkg.get_msg(
--                         iv_application        =>  cv_application,
--                         iv_name               =>  cv_msg_shop_code
--                         );
--        -- ユーザー・エラー・メッセージ
--        gt_err_edideli_work_data(in_line_cnt).errmsg1  :=  xxccp_common_pkg.get_msg(
--                                                       iv_application  =>  cv_application,
--                                                       iv_name         =>  gv_msg_in_none_err,
--                                                       iv_token_name1  =>  cv_tkn_item,
--                                                       iv_token_value1 =>  gv_tkn_shop_code
--                                                       );
--      END IF;
--      --==============================================================
--      -- 発注数量（合計、バラ）チェック
--      --==============================================================
--      IF  ( NVL(gt_req_edi_lines_data(in_line_cnt).sum_order_qty, 0) = 0 )
--      THEN
--        --* -------------------------------------------------------------
--        --必須エラーメッセージ  gv_msg_in_none_err
--        --* -------------------------------------------------------------
--        lv_process_flag := cv_status_error;
--        ov_retcode      :=  cv_status_warn;
--        -- 納品返品ワークID(error)
--        gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--        --ステータス(error)
--        gt_err_edideli_work_data(in_line_cnt).err_status2 := cv_status_warn;
--        --トークン(発注数量（合計、バラ）)
--        gv_sum_order_qty :=  xxccp_common_pkg.get_msg(
--                         iv_application  =>  cv_application,
--                         iv_name         =>  cv_msg_sum_order_qty
--                         );
--        -- ユーザー・エラー・メッセージ
--        gt_err_edideli_work_data(in_line_cnt).errmsg2 :=  xxccp_common_pkg.get_msg(
--                                                      iv_application        =>  cv_application,
--                                                      iv_name               =>  gv_msg_in_none_err,
--                                                      iv_token_name1        =>  cv_tkn_item,
--                                                      iv_token_value1       =>  gv_sum_order_qty
--                                                      );
--      END IF;
--****************************** 2009/06/29 1.5 T.Tominaga DEL END   ******************************
    --==============================================================
    -- 上記までの処理でエラーがない場合
    --==============================================================
    IF ( lv_process_flag = cv_status_normal ) THEN
      --==============================================================
      -- 「顧客コード」の妥当性 チェック
      --==============================================================
      BEGIN
        -- ＥＤＩチェーン店コード
        lv_edi_chain_code := gt_edideli_work_data(in_line_cnt).edi_chain_code;
        -- 店コード
        lv_store_code     := gt_edideli_work_data(in_line_cnt).shop_code;
        --
        SELECT   cust.account_number         account_number,   -- 顧客マスタ.顧客コード
                 csua.price_list_id          price_list_id     -- 価格表ID
        INTO     gt_req_cust_acc_data(in_line_cnt).account_number,     -- 顧客コード
                 gt_req_cust_acc_data(in_line_cnt).price_list_id       -- 価格表ID
        FROM     hz_cust_accounts       cust,                   -- 顧客マスタ
                 hz_cust_site_uses_all  csua,                   -- 顧客使用目的
                 hz_cust_acct_sites_all casa,                   -- 顧客所在地
                 xxcmm_cust_accounts    xca                     -- 顧客追加情報
                                      -- 顧客マスタ.顧客ID   =  顧客所在地.顧客ID
        WHERE    cust.cust_account_id = casa.cust_account_id
                                    -- 顧客マスタ.顧客ID   =  顧客追加情報.顧客ID
          AND    cust.cust_account_id = xca.customer_id
                                      -- 顧客所在地.顧客所在地ID = 顧客使用目的.顧客所在地ID
          AND    casa.cust_acct_site_id = csua.cust_acct_site_id
                                     -- 顧客マスタ.顧客区分 = '10'(顧客)
          AND    cust.customer_class_code = cv_customer_class_code10
                                      -- 顧客マスタ.チェーン店コード(EDI) = A-2で抽出したEDIチェーン店コード
          AND    xca.chain_store_code = lv_edi_chain_code
                                      -- 顧客マスタ.店舗コード = A-2で抽出した店コード
          AND    xca.store_code       = lv_store_code
          AND    csua.site_use_code   = cv_cust_site_use_code            -- 顧客使用目的：SHIP_TO(出荷先)
          AND    casa.org_id          = gn_org_id                        -- 営業単位
          AND    csua.org_id          = casa.org_id
          AND    rownum = 1;
        --
        -- 価格表ID
        lt_head_price_list_id := gt_req_cust_acc_data(in_line_cnt).price_list_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- （対象データ無しエラー）
--****************************** 2009/06/29 1.5 T.Tominaga DEL START ******************************
--            --* -------------------------------------------------------------
--            --顧客コード変換エラーメッセージ  gv_msg_cust_num_chg_err
--            --* -------------------------------------------------------------
--            lv_process_flag :=  cv_status_error;
--            ov_retcode      :=  cv_status_warn;
--            -- 納品返品ワークID(error)
--            gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                  gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--            --ステータス(error)
--            gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--            -- ユーザー・エラー・メッセージ
--            gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                  xxccp_common_pkg.get_msg(
--                    iv_application  =>  cv_application,
--                   iv_name         =>  gv_msg_cust_num_chg_err,
--                    iv_token_name1  =>  cv_chain_shop_code,
--                    iv_token_name2  =>  cv_shop_code,
--                    iv_token_value1 =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code,
--                    iv_token_value2 =>  gt_req_edi_headers_data(in_line_cnt).shop_code
--                    );
--****************************** 2009/05/28 1.3 T.Kitajima DEL  END  ******************************--
          gt_req_cust_acc_data(in_line_cnt).account_number := NULL; --警告時に参照し添字エラーとなる為、初期化
      END;
    ELSE
      gt_req_cust_acc_data(in_line_cnt).account_number := NULL; --警告時に参照し添字エラーとなる為、初期化
    END IF;
    --* -------------------------------------------------------------
    -- 上記までの処理でエラーがない場合
    --* -------------------------------------------------------------
    IF ( lv_process_flag = cv_status_normal )  THEN
      --* -------------------------------------------------------------
      -- 「商品コード」の妥当性チェック
      --* -------------------------------------------------------------
      BEGIN
        --* -------------------------------------------------------------
        --== 「EDI連携品目コード区分」抽出 ==--
        --* -------------------------------------------------------------
        SELECT xca.edi_item_code_div,    -- 顧客追加情報.EDI連携品目コード区分
               cust.account_number       -- 顧客マスタ.顧客コード(チェーン店)
        INTO   lt_head_edi_item_code_div,
               lt_chain_account_number
        FROM   hz_cust_accounts       cust,                 -- 顧客マスタ
               xxcmm_cust_accounts    xca                   -- 顧客追加情報
        WHERE  cust.cust_account_id = xca.customer_id
                                    -- 顧客マスタ.チェーン店コード(EDI) = A-2で抽出したEDIチェーン店コード
          AND  xca.chain_store_code = gt_req_edi_headers_data(in_line_cnt).edi_chain_code
          AND  cust.customer_class_code = cv_customer_class_code18
        ;                                                   -- 顧客マスタ.顧客区分 = '18'(チェーン店)
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--            --* -------------------------------------------------------------
--            --EDI連携品目コード区分エラーメッセージ  gv_msg_item_code_err
--            --* -------------------------------------------------------------
--            lv_process_flag :=  cv_status_error;
--            ov_retcode      :=  cv_status_warn;
--            -- 納品返品ワークID(error)
--            gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                  gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--            --ステータス(error)
--            gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--            -- ユーザー・エラー・メッセージ
--            gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                  xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_application,
--                    iv_name          =>  gv_msg_item_code_err,
--                    iv_token_name1   =>  cv_chain_shop_code,
--                    iv_token_value1  =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code
--                    );
          NULL;
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
      END;
    END IF;
    --* -------------------------------------------------------------
    -- 上記までの処理でエラーがない場合
    --* -------------------------------------------------------------
    IF ( lv_process_flag = cv_status_normal )  THEN
      --* -------------------------------------------------------------
      -- 「EDI連携品目コード区分」が「NULL」または「0：なし」の場合
      --* -------------------------------------------------------------
      IF  (( lt_head_edi_item_code_div  IS NULL )
      OR   ( lt_head_edi_item_code_div  = cv_0 ))
      THEN
--****************************** 2009/06/29 1.5 T.Tominaga DEL START ******************************
--          --* -------------------------------------------------------------
--          --EDI連携品目コード区分エラーメッセージ  gv_msg_item_code_err
--          --* -------------------------------------------------------------
--          lv_process_flag :=  cv_status_error;
--          ov_retcode      :=  cv_status_warn;
--          -- 納品返品ワークID(error)
--          gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                  gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--          --ステータス(error)
--          gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--          -- ユーザー・エラー・メッセージ
--          gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                  xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_application,
--                    iv_name          =>  gv_msg_item_code_err,
--                    iv_token_name1   =>  cv_chain_shop_code,
--                    iv_token_value1  =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code
--                    );
        NULL;
--****************************** 2009/06/29 1.5 T.Tominaga DEL END   ******************************
      --* -------------------------------------------------------------
      -- 「EDI連携品目コード区分」が「2：JANコード」の場合
      --  品目マスタチェック (3-1)
      --* -------------------------------------------------------------
      ELSIF  ( lt_head_edi_item_code_div  = cv_2 )  THEN
        --* -------------------------------------------------------------
        --== 品目マスタ(JANコード)よりデータ抽出 ==--
        --* -------------------------------------------------------------
        BEGIN
--****************************** 2009/05/19 1.2 T.Kitajima MOD START ******************************--
--          SELECT mtl_item.inventory_item_id,        -- 品目ID
--                 mtl_item.segment1,                 -- 品目コード
--                 mtl_item.primary_unit_of_measure   -- 基準単位
--          INTO   gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
--                 gt_req_mtl_sys_items(in_line_cnt).segment1,
--                 gt_req_mtl_sys_items(in_line_cnt).unit_of_measure
--          FROM   mtl_system_items_b    mtl_item,
--                 ic_item_mst_b         mtl_item1
--          WHERE  mtl_item.segment1          = mtl_item1.item_no
--                                            -- 商品コード２
--            AND  mtl_item1.attribute21      = gt_req_edi_lines_data(in_line_cnt).product_code2
--                                            -- 在庫組織ID
--            AND  mtl_item.organization_id   = gv_prf_orga_id;
--
          SELECT ims.inventory_item_id,
                 ims.segment1,
                 ims.primary_unit_of_measure
            INTO gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
                 gt_req_mtl_sys_items(in_line_cnt).segment1,
                 gt_req_mtl_sys_items(in_line_cnt).unit_of_measure
            FROM (
                  SELECT msi.inventory_item_id,        -- 品目ID
                         msi.segment1,                 -- 品目コード
                         msi.primary_unit_of_measure   -- 基準単位
                    FROM mtl_system_items_b    msi,
                         ic_item_mst_b         iim,
                         xxcmn_item_mst_b      xim
                   WHERE msi.segment1          = iim.item_no
                                                    -- 商品コード２
                    AND  iim.attribute21      = gt_req_edi_lines_data(in_line_cnt).product_code2
                                                    -- 在庫組織ID
                    AND  msi.organization_id  = gv_prf_orga_id
                    AND xim.item_id           = iim.item_id         --OPM品目.品目ID        =OPM品目アドオン.品目ID
                    AND xim.item_id           = xim.parent_item_id  --OPM品目アドオン.品目ID=OPM品目アドオン.親品目ID
                    AND TO_DATE(iim.attribute13,cv_format_yyyymmdd) <= NVL( gt_edideli_work_data(in_line_cnt).shop_delivery_date, 
                                                                      NVL( gt_edideli_work_data(in_line_cnt).center_delivery_date, 
                                                                           NVL( gt_edideli_work_data(in_line_cnt).order_date, 
                                                                                gt_edideli_work_data(in_line_cnt).data_creation_date_edi_data
                                                                              )
                                                                         )
                                                                    )
                  ORDER BY iim.attribute13 DESC
                 ) ims
          WHERE ROWNUM  = 1
          ;
--****************************** 2009/05/19 1.2 T.Kitajima MOD  END  ******************************--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN  -- 検索データなし
            --* -------------------------------------------------------------
            -- 「EDI連携品目コード区分」が「2：JANコード」の場合
            --  品目マスタチェック (3-1) ケースＪＡＮコード
            --* -------------------------------------------------------------
            BEGIN
              --* -------------------------------------------------------------
              --== 品目マスタ(ケースJANコード)よりデータ抽出 ==--
              --* -------------------------------------------------------------
--****************************** 2009/05/19 1.2 T.Kitajima MOD START ******************************--
--              SELECT mtl_item.inventory_item_id,        -- 品目ID
--                     mtl_item.segment1                  -- 品目コード
--              INTO   gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
--                     gt_req_mtl_sys_items(in_line_cnt).segment1
--              FROM   mtl_system_items_b    mtl_item,
--                     ic_item_mst_b         mtl_item1,
--                     xxcmm_system_items_b  xxcmm_sib
--              WHERE  mtl_item.segment1      = mtl_item1.item_no
--                AND  mtl_item.segment1      = xxcmm_sib.item_code
--                                            -- 商品コード２
--                AND  xxcmm_sib.case_jan_code = gt_req_edi_lines_data(in_line_cnt).product_code2
--                                            -- 在庫組織ID
--                AND  mtl_item.organization_id = gv_prf_orga_id;
--
              SELECT ims.inventory_item_id,
                     ims.segment1
                INTO gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
                     gt_req_mtl_sys_items(in_line_cnt).segment1
                FROM (
                      SELECT msi.inventory_item_id inventory_item_id,   -- 品目ID
                             msi.segment1          segment1             -- 品目コード
                        FROM mtl_system_items_b    msi,
                             ic_item_mst_b         iim,
                             xxcmn_item_mst_b      xim,
                             xxcmm_system_items_b  xsi
                       WHERE msi.segment1        = iim.item_no
                         AND msi.segment1        = xsi.item_code
                                                     -- 商品コード２
                         AND xsi.case_jan_code   = gt_req_edi_lines_data(in_line_cnt).product_code2
                                                     -- 在庫組織ID
                         AND msi.organization_id = gv_prf_orga_id
                         AND xim.item_id         = iim.item_id         --OPM品目.品目ID        =OPM品目アドオン.品目ID
-- ******************** 2009/08/05 1.5 N.Maeda MOD START *********************** --
                         AND iim.item_id         = xim.parent_item_id  --OPM品目.品目ID=OPM品目アドオン.親品目ID
--                         AND xim.item_id         = xim.parent_item_id  --OPM品目アドオン.品目ID=OPM品目アドオン.親品目ID
-- ******************** 2009/08/05 1.5 N.Maeda MOD  END  *********************** --
                         AND TO_DATE(iim.attribute13,cv_format_yyyymmdd) <= NVL( gt_edideli_work_data(in_line_cnt).shop_delivery_date, 
                                                                           NVL( gt_edideli_work_data(in_line_cnt).center_delivery_date, 
                                                                                NVL( gt_edideli_work_data(in_line_cnt).order_date, 
                                                                                     gt_edideli_work_data(in_line_cnt).data_creation_date_edi_data
                                                                                   )
                                                                              )
                                                                         )
                       ORDER BY iim.attribute13 DESC
                     ) ims
              WHERE ROWNUM  = 1
              ;
--****************************** 2009/05/19 1.2 T.Kitajima MOD  END  ******************************--
              --* -------------------------------------------------------------
              --== A-1で抽出したケース単位ｺｰﾄﾞ
              --* -------------------------------------------------------------
              gt_req_mtl_sys_items(in_line_cnt).unit_of_measure := gv_prf_case_code;
            --
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--                  --* -------------------------------------------------------------
--                  -- 商品コード変換エラーメッセージ  gv_msg_product_code_err
--                  --* -------------------------------------------------------------
--                  lv_process_flag :=  cv_status_warn;
--                  ov_retcode      :=  cv_status_warn;
--                  -- 納品返品ワークID(error)
--                  gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                         gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--                  --ステータス(error)
--                  gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--                  --トークン(JANコード)
--                  gv_jan_code    :=  xxccp_common_pkg.get_msg(
--                                 iv_application        =>  cv_application,
--                                 iv_name               =>  cv_msg_jan_code
--                               );
--                  -- ユーザー・エラー・メッセージ
--                  gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                         xxccp_common_pkg.get_msg(
--                           iv_application   =>  cv_application,
--                           iv_name          =>  gv_msg_product_code_err,
--                           iv_token_name1   =>  cv_prod_code,
--                           iv_token_name2   =>  cv_prod_type,
--                           iv_token_value1  =>  gt_req_edi_lines_data(in_line_cnt).product_code2,
--                           iv_token_value2  =>  gv_jan_code
--                           );
--                  --* -------------------------------------------------------------
--                  --* JAN、ケースJANコードが存在しない場合、ダミー品目コードを取得
--                  --* -------------------------------------------------------------
--                  SELECT  flvv.lookup_code        -- コード
--                  INTO    gt_req_mtl_sys_items(in_line_cnt).segment1
--                  FROM    fnd_lookup_values_vl  flvv          -- ルックアップマスタ
--                  WHERE   flvv.lookup_type  = cv_lookup_type  -- ルックアップ.タイプ
--                    AND   flvv.enabled_flag       = cv_y                -- 有効
--                    AND   flvv.attribute1         = cv_1
--                    AND (( flvv.start_date_active IS NULL )
--                    OR   ( flvv.start_date_active <= cd_process_date ))
--                    AND (( flvv.end_date_active   IS NULL )
--                    OR   ( flvv.end_date_active   >= cd_process_date ));  -- 業務日付がFROM-TO内
-- ******************** 2009/09/28 1.6 K.Satomura MOD START *********************** --
            --NULL;
            gt_req_mtl_sys_items(in_line_cnt).segment1        := gt_dummy_item_number;
            gt_req_mtl_sys_items(in_line_cnt).unit_of_measure := gt_dummy_unit_of_measure;
-- ******************** 2009/09/28 1.6 K.Satomura MOD END   *********************** --
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
            END;
        END;
      --* -------------------------------------------------------------
      -- 「EDI連携品目コード区分」が「1：顧客品目」の場合
      --  顧客品目マスタチェック (3-2)
      --* -------------------------------------------------------------
      ELSIF  ( lt_head_edi_item_code_div  = cv_1 )  THEN
        --* -------------------------------------------------------------
        -- 「商品コード２」の妥当性チェック
        --* -------------------------------------------------------------
        BEGIN
          --* -------------------------------------------------------------
          --== 顧客マスタデータ抽出 ==--
          --* -------------------------------------------------------------
          SELECT mcix.inventory_item_id,         -- 品目ID
                 mtl_item.segment1,              -- 品目コード
                 mtci.attribute1                 -- 単位
          INTO   gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
                 gt_req_mtl_sys_items(in_line_cnt).segment1,
                 gt_req_mtl_sys_items(in_line_cnt).unit_of_measure
          FROM   hz_cust_accounts         cust,                  -- 顧客マスタ
                 mtl_customer_item_xrefs  mcix,                  -- 顧客品目相互参照
                 mtl_customer_items       mtci,                  -- 顧客品目
                 mtl_system_items_b       mtl_item,              -- 品目マスタ
                 mtl_parameters           mtl_parm               -- 顧客品目ﾊﾟﾗﾒｰﾀﾏｽﾀ
                                 -- 顧客マスタ.顧客コード = チェーン店の顧客コード
          WHERE  cust.account_number         = lt_chain_account_number
                                 -- 顧客マスタ.顧客区分 = '18'(チェーン店)
            AND  cust.customer_class_code    = cv_customer_class_code18
                                 -- 顧客品目.顧客ID = 顧客マスタ.顧客ID
            AND  mtci.customer_id            = cust.cust_account_id
                                 --顧客品目マスタ．顧客品目 ＝ 商品コード２
            AND  mtci.customer_item_number   = gt_req_edi_lines_data(in_line_cnt).product_code2
                                 -- 顧客品目.顧客品目ID = 顧客品目相互参照.顧客品目ID
            AND  mtci.customer_item_id       = mcix.customer_item_id
            AND  mcix.master_organization_id = mtl_parm.master_organization_id
                                 -- 在庫組織ID
            AND  mtl_parm.organization_id    = gv_prf_orga_id
                                 -- 顧客品目相互参照.品目ID = 品目マスタ.品目ID
            AND  mtl_item.inventory_item_id  = mcix.inventory_item_id
            AND  mtl_item.organization_id    = mtl_parm.organization_id
-- ******************** 2009/09/28 1.6 K.Satomura MOD START *********************** --
            AND  mtci.inactive_flag          = cv_n
            AND  mcix.inactive_flag          = cv_n
            AND  mcix.preference_number      = 
                 (
                   SELECT MIN(cix.preference_number)
                   FROM   mtl_customer_items      cit
                         ,mtl_customer_item_xrefs cix
                   WHERE  cit.customer_id          = cust.cust_account_id
                   AND    cit.customer_item_number = mtci.customer_item_number
                   AND    cit.customer_item_id     = cix.customer_item_id
                   AND    cit.inactive_flag        = cv_n
                   AND    cix.inactive_flag        = cv_n
                 )
-- ******************** 2009/09/28 1.6 K.Satomura MOD END   *********************** --
            ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--              --* -------------------------------------------------------------
--              --== 顧客品目が存在しない場合、ダミー品目コードを取得
--              --* -------------------------------------------------------------
--              SELECT  flvv.lookup_code        -- コード
--              INTO    gt_req_mtl_sys_items(in_line_cnt).segment1
--              FROM    fnd_lookup_values_vl  flvv        -- ルックアップマスタ
--              WHERE   flvv.lookup_type  = cv_lookup_type  -- ルックアップ.タイプ
--                AND   flvv.enabled_flag       = cv_y                -- 有効
--                AND   flvv.attribute1         = cv_1
--                AND (( flvv.start_date_active IS NULL )
--                OR   ( flvv.start_date_active <= cd_process_date ))
--                AND (( flvv.end_date_active   IS NULL )
--                OR   ( flvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
--              ;
--              --* -------------------------------------------------------------
--              -- 商品コード変換エラーメッセージ  gv_msg_product_code_err
--              --* -------------------------------------------------------------
--              lv_process_flag :=  cv_status_warn;
--              ov_retcode      :=  cv_status_warn;
--              -- 納品返品ワークID(error)
--              gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                      gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--              --ステータス(error)
--              gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--              --トークン(顧客品目)
--              gv_tkn_mtl_cust_items  :=  xxccp_common_pkg.get_msg(
--                                     iv_application  =>  cv_application,
--                                     iv_name         =>  cv_msg_mtl_cust_items
--                                     );
--              -- ユーザー・エラー・メッセージ
--              gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                      xxccp_common_pkg.get_msg(
--                        iv_application   =>  cv_application,
--                        iv_name          =>  gv_msg_product_code_err,
--                        iv_token_name1   =>  cv_prod_code,
--                       iv_token_name2   =>  cv_prod_type,
--                        iv_token_value1  =>  gt_req_edi_lines_data(in_line_cnt).product_code2,
--                        iv_token_value2  =>  gv_tkn_mtl_cust_items
--                        );
-- ******************** 2009/09/28 1.6 K.Satomura MOD START *********************** --
            --NULL;
            gt_req_mtl_sys_items(in_line_cnt).segment1        := gt_dummy_item_number;
            gt_req_mtl_sys_items(in_line_cnt).unit_of_measure := gt_dummy_unit_of_measure;
-- ******************** 2009/09/28 1.6 K.Satomura MOD END   *********************** --
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
        END;
      END IF;
    END IF;
    --* -------------------------------------------------------------
    -- 上記までの処理でエラーがない場合(警告は処理実行)
    --* -------------------------------------------------------------
    IF ( lv_process_flag <> cv_status_error )  THEN
      --* -------------------------------------------------------------
      -- 品目コードの設定
      --* -------------------------------------------------------------
      IF ( gt_req_mtl_sys_items(in_line_cnt).segment1 IS NOT NULL ) THEN
        gt_req_edi_lines_data(in_line_cnt).item_code := SUBSTRB(gt_req_mtl_sys_items(in_line_cnt).segment1,1,7);
      END IF;
      --* -------------------------------------------------------------
      -- 明細単位の設定 (4-1)(4-2)
      --* -------------------------------------------------------------
      IF ( gt_req_mtl_sys_items(in_line_cnt).unit_of_measure  IS NOT NULL ) THEN
        gt_req_edi_lines_data(in_line_cnt).line_uom := gt_req_mtl_sys_items(in_line_cnt).unit_of_measure;
      END IF;
      --* -------------------------------------------------------------
      -- 価格表から単価情報を取得 (5)
      -- 「原単価（発注）」が未設定（NULLまたは０）の場合
      --* -------------------------------------------------------------
      IF  (( gt_req_edi_lines_data(in_line_cnt).order_unit_price  IS NULL )
      OR   ( gt_req_edi_lines_data(in_line_cnt).order_unit_price  = 0     ))
      THEN
--****************************** 2009/05/19 1.2 T.Kitajima MOD START ******************************--
--        --* -------------------------------------------------------------
--        -- 顧客の価格表IDが設定されている場合
--        --* -------------------------------------------------------------
--        IF  ( lt_head_price_list_id IS NOT NULL ) THEN
--          --* -------------------------------------------------------------
--          -- 共通関数より取得する
--          --* -------------------------------------------------------------
--          lt_unit_price := xxcos_common2_pkg.get_unit_price(
--                        gt_req_mtl_sys_items(in_line_cnt).inventory_item_id, -- 品目ID
--                        lt_head_price_list_id,                               -- 価格表ID
--                        gt_req_edi_lines_data(in_line_cnt).line_uom          -- 明細単位
--                        );
--        ELSE
--          lt_unit_price := cn_m1;
--        END IF;
--        --* -------------------------------------------------------------
--        -- 共通関数より取得より単価が取得できた場合
--        --* -------------------------------------------------------------
--        IF ( lt_unit_price >= cn_0 ) THEN
--          gt_req_edi_lines_data(in_line_cnt).order_unit_price := lt_unit_price;
--        ELSE
--          --* -------------------------------------------------------------
--          --価格表未設定エラーメッセージ  gv_msg_price_list_err
--          --* -------------------------------------------------------------
--          lv_process_flag :=  cv_status_warn;
--          ov_retcode      :=  cv_status_warn;
--          -- 納品返品ワークID(error)
--          gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                  gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--          --ステータス(error)
--          gt_err_edideli_work_data(in_line_cnt).err_status2 := cv_status_warn;
--          -- ユーザー・エラー・メッセージ
--          gt_err_edideli_work_data(in_line_cnt).errmsg2 :=
--                  xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_application,
--                    iv_name          =>  gv_msg_price_list_err,
--                    iv_token_name1   =>  cv_chain_shop_code,
--                    iv_token_name2   =>  cv_shop_code,
--                    iv_token_value1  =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code,
--                    iv_token_value2  =>  gt_req_edi_headers_data(in_line_cnt).shop_code
--                    );
--        END IF;
--
        --* -------------------------------------------------------------
        -- 顧客の価格表IDが設定されている場合
        --* -------------------------------------------------------------
        IF  ( lt_head_price_list_id IS NOT NULL ) THEN
          --* -------------------------------------------------------------
          -- 共通関数より取得する
          --* -------------------------------------------------------------
          lt_unit_price := xxcos_common2_pkg.get_unit_price(
                        gt_req_mtl_sys_items(in_line_cnt).inventory_item_id, -- 品目ID
                        lt_head_price_list_id,                               -- 価格表ID
                        gt_req_edi_lines_data(in_line_cnt).line_uom          -- 明細単位
                        );
--
          --* -------------------------------------------------------------
          -- 共通関数より取得より単価が取得できた場合
          --* -------------------------------------------------------------
          IF ( lt_unit_price >= cn_0 ) THEN
            gt_req_edi_lines_data(in_line_cnt).order_unit_price := lt_unit_price;
          ELSE
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--              --* -------------------------------------------------------------
--              --単価取得エラーメッセージ  cv_msg_price_err
--              --* -------------------------------------------------------------
--              lv_process_flag :=  cv_status_warn;
--              ov_retcode      :=  cv_status_warn;
--              -- 納品返品ワークID(error)
--              gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                      gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--              --ステータス(error)
--              gt_err_edideli_work_data(in_line_cnt).err_status2 := cv_status_warn;
--              -- ユーザー・エラー・メッセージ
--              gt_err_edideli_work_data(in_line_cnt).errmsg2 :=
--                     xxccp_common_pkg.get_msg( cv_application, 
--                                               cv_msg_price_err 
--                                             );
            NULL;
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
          END IF;
        ELSE
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--            --* -------------------------------------------------------------
--            --価格表未設定エラーメッセージ  gv_msg_price_list_err
--            --* -------------------------------------------------------------
--            lv_process_flag :=  cv_status_warn;
--            ov_retcode      :=  cv_status_warn;
--            -- 納品返品ワークID(error)
--            gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                    gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--            --ステータス(error)
--            gt_err_edideli_work_data(in_line_cnt).err_status2 := cv_status_warn;
--            -- ユーザー・エラー・メッセージ
--            gt_err_edideli_work_data(in_line_cnt).errmsg2 :=
--                    xxccp_common_pkg.get_msg(
--                      iv_application   =>  cv_application,
--                      iv_name          =>  gv_msg_price_list_err,
--                      iv_token_name1   =>  cv_chain_shop_code,
--                      iv_token_name2   =>  cv_shop_code,
--                      iv_token_value1  =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code,
--                      iv_token_value2  =>  gt_req_edi_headers_data(in_line_cnt).shop_code
--                      );
          NULL;
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
        END IF;
--****************************** 2009/05/19 1.2 T.Kitajima MOD  END  ******************************--
      END IF;
-- ***************************** 2009/08/06 1.5 M.Sano    ADD  START ***************************** --
      --* -------------------------------------------------------------
      --  原価金額（発注）の再計算
      -- 「原価金額（発注）」が未設定（NULLまたは０）の場合
      --* -------------------------------------------------------------
      IF ( NVL(gt_edideli_work_data(in_line_cnt).order_cost_amt,0) = cv_0 ) THEN
        gt_edideli_work_data(in_line_cnt).order_cost_amt :=
          TRUNC( gt_req_edi_lines_data(in_line_cnt).order_unit_price * gt_req_edi_lines_data(in_line_cnt).sum_order_qty );
      END IF;
-- ***************************** 2009/08/06 1.5 M.Sano    ADD   END  ***************************** --
    END IF;
    -- * -------------------------------------------------------------
    -- * リターンコードの保持、
    -- * -------------------------------------------------------------
    IF ( lv_process_flag =  cv_status_warn ) THEN
      gv_status_work_warn :=  cv_status_warn;
--****************************** 2009/06/04 1.4 T.Kitajima DEL START ******************************--
--      gn_warn_cnt         :=  gn_warn_cnt  +  1;
--****************************** 2009/06/04 1.4 T.Kitajima DEL  END  ******************************--
    ELSIF ( lv_process_flag =  cv_status_error ) THEN
      gv_status_work_err  :=  cv_status_error;
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
      gn_error_cnt        :=  gn_error_cnt + 1;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
    END IF;
    --* -------------------------------------------------------------
    --  ヘッダキーブレイク編集
    --* -------------------------------------------------------------
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--    IF (( gt_head_invoice_number_key IS NULL )
--    OR  ( gt_head_invoice_number_key <> gt_req_edi_headers_data(in_line_cnt).invoice_number ))
    IF (( gt_head_shop_invoice_key IS NULL )
    OR  ( gt_head_shop_invoice_key <> gt_req_edi_headers_data(in_line_cnt).shop_code || gt_req_edi_headers_data(in_line_cnt).invoice_number ))
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
    THEN
      gn_normal_headers_cnt := gn_normal_headers_cnt + 1;  --ヘッダの添字インクリメント
      --* -------------------------------------------------------------
      -- 顧客コード(変換後顧客コード)
      --* -------------------------------------------------------------
      gt_req_edi_headers_data(gn_normal_headers_cnt).conv_customer_code := gt_req_cust_acc_data(in_line_cnt).account_number;
      --* -------------------------------------------------------------
      --  * Procedure Name   : xxcos_in_edi_headers_edit
      --  * Description      : EDIヘッダ情報変数の編集(A-2)(1)
      --* -------------------------------------------------------------
      xxcos_in_edi_headers_edit(
        gn_normal_headers_cnt, --   LOOP用カウンタ1
        in_line_cnt,           --   LOOP用カウンタ2
        lv_errbuf,     --   エラー・メッセージ
        lv_retcode,    --   リターン・コード
        lv_errmsg      --   ユーザー・エラー・メッセージ
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      --* -------------------------------------------------------------
      --  * Procedure Name   : xxcos_in_edi_lines_edit
      --  * Description      : EDI明細情報変数の編集(A-2)(2)
      --* -------------------------------------------------------------
      xxcos_in_edi_lists_edit(
        in_line_cnt,    --   LOOP用カウンタ
        lv_errbuf,     --   エラー・メッセージ
        lv_retcode,    --   リターン・コード
        lv_errmsg      --   ユーザー・エラー・メッセージ
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      gn_normal_lines_cnt := gn_normal_lines_cnt + 1;
      --* -------------------------------------------------------------
      -- * Procedure Name   : xxcos_in_edi_headers_add
      -- * Description      : EDIヘッダ情報変数への追加(A-4)
      --* -------------------------------------------------------------
      xxcos_in_edi_headers_add(
        gn_normal_headers_cnt,
        in_line_cnt,
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    ELSE
      --* -------------------------------------------------------------
      --  同一ヘッダ編集
      --* -------------------------------------------------------------
      --* -------------------------------------------------------------
      --  * Procedure Name   : xxcos_in_edi_lines_edit
      --  * Description      : EDI明細情報変数の編集(A-2)(2)
      --* -------------------------------------------------------------
      xxcos_in_edi_lists_edit(
        in_line_cnt,    --   LOOP用カウンタ
        lv_errbuf,     --   エラー・メッセージ
        lv_retcode,    --   リターン・コード
        lv_errmsg      --   ユーザー・エラー・メッセージ
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      gn_normal_lines_cnt := gn_normal_lines_cnt + 1;
      --* -------------------------------------------------------------
      -- * Procedure Name   : xxcos_in_edi_headers_up
      -- * Description      : EDIヘッダ情報変数へ数量を加算(A-5)
      --* -------------------------------------------------------------
      xxcos_in_edi_headers_up(
        gn_normal_headers_cnt,
        in_line_cnt,
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 伝票番号のセット
    gt_head_invoice_number_key  := gt_req_edi_headers_data(in_line_cnt).invoice_number;
--****************************** 2009/06/29 1.5 T.Tominaga ADD START ******************************
    -- ブレイクキー（店コード＋伝票番号）のセット
    gt_head_shop_invoice_key  := gt_req_edi_headers_data(in_line_cnt).shop_code || gt_req_edi_headers_data(in_line_cnt).invoice_number;
--****************************** 2009/06/29 1.5 T.Tominaga ADD END   ******************************
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
  END data_check;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_deli_wk_update
   * Description      : EDI納品返品情報ワークテーブルへの更新(A-6)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_deli_wk_update(
    iv_file_name  IN  VARCHAR2,     --   インタフェースファイル名
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_deli_wk_update'; -- プログラム名
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
    gv_run_class_name3 := cv_1;
    BEGIN
      --* -------------------------------------------------------------
      -- EDI納品返品情報ワークテーブル XXCOS_EDI_DELIVERY_WORK UPDATE
      --* -------------------------------------------------------------
      UPDATE xxcos_edi_delivery_work
         SET err_status             =  gv_run_class_name3,      -- ステータス
             last_updated_by        =  cn_last_updated_by,      -- 最終更新者
             last_update_date       =  cd_last_update_date,     -- 最終更新日
             last_update_login      =  cn_last_update_login,    -- 最終更新ログイン
             request_id             =  cn_request_id,           -- 要求ID
                                    -- コンカレント・プログラム・アプリケーションID
             program_application_id =  cn_program_application_id,
             program_id             =  cn_program_id,           -- コンカレント・プログラムID
             program_update_date    =  cd_program_update_date   -- プログラム更新日
      WHERE  if_file_name = iv_file_name;          -- インタフェースファイル名
--
      --コンカレントは異常終了させる為ここでコミットする
      COMMIT;
--
    EXCEPTION
      WHEN OTHERS THEN
      -- EDI納品返品情報ワークテーブル
      gv_tkn_edi_deli_work :=  xxccp_common_pkg.get_msg(
                           iv_application =>  cv_application,
                           iv_name        =>  cv_msg_edi_deli_work
                           );
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                 iv_application   =>  cv_application,
                 iv_name          =>  gv_msg_data_update_err,
                 iv_token_name1   =>  cv_tkn_table_name1,
                 iv_token_name2   =>  cv_tkn_key_data,
                 iv_token_value1  =>  gv_tkn_edi_deli_work,
                 iv_token_value2  =>  iv_file_name
                 );
      lv_errbuf  := SQLERRM;
      RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
----#################################  固定例外処理部 START   ####################################
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
  END xxcos_in_edi_deli_wk_update;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_headers_insert
   * Description      : EDIヘッダ情報テーブルへのデータ挿入(A-7)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_headers_insert(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_headers_insert'; -- プログラム名
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
    ln_edi_header_info_id    NUMBER  DEFAULT 0;
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
    --* -------------------------------------------------------------
    -- ループ開始：
    --* -------------------------------------------------------------
    <<xxcos_edi_headers_insert>>
    FOR  ln_no  IN  1..gn_normal_headers_cnt  LOOP
      --* -------------------------------------------------------------
      --* Description      : EDIヘッダ情報テーブルへのデータ挿入(A-7)
      --* -------------------------------------------------------------
      INSERT INTO xxcos_edi_headers
        (
          edi_header_info_id,                   -- EDIヘッダ情報ID
          medium_class,                         -- 媒体区分
          data_type_code,                       -- データ種コード
          file_no,                              -- ファイルNO
          info_class,                           -- 情報区分
          process_date,                         -- 処理日
          process_time,                         -- 処理時刻
          base_code,                            -- 拠点（部門）コード
          base_name,                            -- 拠点名（正式名）
          base_name_alt,                        -- 拠点名（カナ）
          edi_chain_code,                       -- EDIチェーン店コード
          edi_chain_name,                       -- EDIチェーン店名（漢字）
          edi_chain_name_alt,                   -- EDIチェーン店名（カナ）
          chain_code,                           -- チェーン店コード
          chain_name,                           -- チェーン店名（漢字）
          chain_name_alt,                       -- チェーン店名（カナ）
          report_code,                          -- 帳票コード
          report_show_name,                     -- 帳票表示名
          customer_code,                        -- 顧客コード
          customer_name,                        -- 顧客名（漢字）
          customer_name_alt,                    -- 顧客名（カナ）
          company_code,                         -- 社コード
          company_name,                         -- 社名（漢字）
          company_name_alt,                     -- 社名（カナ）
          shop_code,                            -- 店コード
          shop_name,                            -- 店名（漢字）
          shop_name_alt,                        -- 店名（カナ）
          delivery_center_code,                 -- 納入センターコード
          delivery_center_name,                 -- 納入センター名（漢字）
          delivery_center_name_alt,             -- 納入センター名（カナ）
          order_date,                           -- 発注日
          center_delivery_date,                 -- センター納品日
          result_delivery_date,                 -- 実納品日
          shop_delivery_date,                   -- 店舗納品日
          data_creation_date_edi_data,          -- データ作成日（EDIデータ中）
          data_creation_time_edi_data,          -- データ作成時刻（EDIデータ中）
          invoice_class,                        -- 伝票区分
          small_classification_code,            -- 小分類コード
          small_classification_name,            -- 小分類名
          middle_classification_code,           -- 中分類コード
          middle_classification_name,           -- 中分類名
          big_classification_code,              -- 大分類コード
          big_classification_name,              -- 大分類名
          other_party_department_code,          -- 相手先部門コード
          other_party_order_number,             -- 相手先発注番号
          check_digit_class,                    -- チェックデジット有無区分
          invoice_number,                       -- 伝票番号
          check_digit,                          -- チェックデジット
          close_date,                           -- 月限
          order_no_ebs,                         -- 受注NO（EBS）
          ar_sale_class,                        -- 特売区分
          delivery_classe,                      -- 配送区分
          opportunity_no,                       -- 便NO
          contact_to,                           -- 連絡先
          route_sales,                          -- ルートセールス
          corporate_code,                       -- 法人コード
          maker_name,                           -- メーカー名
          area_code,                            -- 地区コード
          area_name,                            -- 地区名（漢字）
          area_name_alt,                        -- 地区名（カナ）
          vendor_code,                          -- 取引先コード
          vendor_name,                          -- 取引先名（漢字）
          vendor_name1_alt,                     -- 取引先名１（カナ）
          vendor_name2_alt,                     -- 取引先名２（カナ）
          vendor_tel,                           -- 取引先TEL
          vendor_charge,                        -- 取引先担当者
          vendor_address,                       -- 取引先住所（漢字）
          deliver_to_code_itouen,               -- 届け先コード（伊藤園）
          deliver_to_code_chain,                -- 届け先コード（チェーン店）
          deliver_to,                           -- 届け先（漢字）
          deliver_to1_alt,                      -- 届け先１（カナ）
          deliver_to2_alt,                      -- 届け先２（カナ）
          deliver_to_address,                   -- 届け先住所（漢字）
          deliver_to_address_alt,               -- 届け先住所（カナ）
          deliver_to_tel,                       -- 届け先TEL
          balance_accounts_code,                -- 帳合先コード
          balance_accounts_company_code,        -- 帳合先社コード
          balance_accounts_shop_code,           -- 帳合先店コード
          balance_accounts_name,                -- 帳合先名（漢字）
          balance_accounts_name_alt,            -- 帳合先名（カナ）
          balance_accounts_address,             -- 帳合先住所（漢字）
          balance_accounts_address_alt,         -- 帳合先住所（カナ）
          balance_accounts_tel,                 -- 帳合先TEL
          order_possible_date,                  -- 受注可能日
          permission_possible_date,             -- 許容可能日
          forward_month,                        -- 先限年月日
          payment_settlement_date,              -- 支払決済日
          handbill_start_date_active,           -- チラシ開始日
          billing_due_date,                     -- 請求締日
          shipping_time,                        -- 出荷時刻
          delivery_schedule_time,               -- 納品予定時間
          order_time,                           -- 発注時間
          general_date_item1,                   -- 汎用日付項目１
          general_date_item2,                   -- 汎用日付項目２
          general_date_item3,                   -- 汎用日付項目３
          general_date_item4,                   -- 汎用日付項目４
          general_date_item5,                   -- 汎用日付項目５
          arrival_shipping_class,               -- 入出荷区分
          vendor_class,                         -- 取引先区分
          invoice_detailed_class,               -- 伝票内訳区分
          unit_price_use_class,                 -- 単価使用区分
          sub_distribution_center_code,         -- サブ物流センターコード
          sub_distribution_center_name,         -- サブ物流センターコード名
          center_delivery_method,               -- センター納品方法
          center_use_class,                     -- センター利用区分
          center_whse_class,                    -- センター倉庫区分
          center_area_class,                    -- センター地域区分
          center_arrival_class,                 -- センター入荷区分
          depot_class,                          -- デポ区分
          tcdc_class,                           -- TCDC区分
          upc_flag,                             -- UPCフラグ
          simultaneously_class,                 -- 一斉区分
          business_id,                          -- 業務ID
          whse_directly_class,                  -- 倉直区分
          premium_rebate_class,                 -- 景品割戻区分
          item_type,                            -- 項目種別
          cloth_house_food_class,               -- 衣家食区分
          mix_class,                            -- 混在区分
          stk_class,                            -- 在庫区分
          last_modify_site_class,               -- 最終修正場所区分
          report_class,                         -- 帳票区分
          addition_plan_class,                  -- 追加・計画区分
          registration_class,                   -- 登録区分
          specific_class,                       -- 特定区分
          dealings_class,                       -- 取引区分
          order_class,                          -- 発注区分
          sum_line_class,                       -- 集計明細区分
          shipping_guidance_class,              -- 出荷案内以外区分
          shipping_class,                       -- 出荷区分
          product_code_use_class,               -- 商品コード使用区分
          cargo_item_class,                     -- 積送品区分
          ta_class,                             -- T/A区分
          plan_code,                            -- 企画コード
          category_code,                        -- カテゴリーコード
          category_class,                       -- カテゴリー区分
          carrier_means,                        -- 運送手段
          counter_code,                         -- 売場コード
          move_sign,                            -- 移動サイン
          eos_handwriting_class,                -- EOS・手書区分
          delivery_to_section_code,             -- 納品先課コード
          invoice_detailed,                     -- 伝票内訳
          attach_qty,                           -- 添付数
          other_party_floor,                    -- フロア
          text_no,                              -- TEXTNO
          in_store_code,                        -- インストアコード
          tag_data,                             -- タグ
          competition_code,                     -- 競合
          billing_chair,                        -- 請求口座
          chain_store_code,                     -- チェーンストアーコード
          chain_store_short_name,               -- チェーンストアーコード略式名称
          direct_delivery_rcpt_fee,             -- 直配送／引取料
          bill_info,                            -- 手形情報
          description,                          -- 摘要
          interior_code,                        -- 内部コード
          order_info_delivery_category,         -- 発注情報　納品カテゴリー
          purchase_type,                        -- 仕入形態
          delivery_to_name_alt,                 -- 納品場所名（カナ）
          shop_opened_site,                     -- 店出場所
          counter_name,                         -- 売場名
          extension_number,                     -- 内線番号
          charge_name,                          -- 担当者名
          price_tag,                            -- 値札
          tax_type,                             -- 税種
          consumption_tax_class,                -- 消費税区分
          brand_class,                          -- BR
          id_code,                              -- IDコード
          department_code,                      -- 百貨店コード
          department_name,                      -- 百貨店名
          item_type_number,                     -- 品別番号
          description_department,               -- 摘要（百貨店）
          price_tag_method,                     -- 値札方法
          reason_column,                        -- 自由欄
          a_column_header,                      -- A欄ヘッダ
          d_column_header,                      -- D欄ヘッダ
          brand_code,                           -- ブランドコード
          line_code,                            -- ラインコード
          class_code,                           -- クラスコード
          a1_column,                            -- Ａ－１欄
          b1_column,                            -- Ｂ－１欄
          c1_column,                            -- Ｃ－１欄
          d1_column,                            -- Ｄ－１欄
          e1_column,                            -- Ｅ－１欄
          a2_column,                            -- Ａ－２欄
          b2_column,                            -- Ｂ－２欄
          c2_column,                            -- Ｃ－２欄
          d2_column,                            -- Ｄ－２欄
          e2_column,                            -- Ｅ－２欄
          a3_column,                            -- Ａ－３欄
          b3_column,                            -- Ｂ－３欄
          c3_column,                            -- Ｃ－３欄
          d3_column,                            -- Ｄ－３欄
          e3_column,                            -- Ｅ－３欄
          f1_column,                            -- Ｆ－１欄
          g1_column,                            -- Ｇ－１欄
          h1_column,                            -- Ｈ－１欄
          i1_column,                            -- Ｉ－１欄
          j1_column,                            -- Ｊ－１欄
          k1_column,                            -- Ｋ－１欄
          l1_column,                            -- Ｌ－１欄
          f2_column,                            -- Ｆ－２欄
          g2_column,                            -- Ｇ－２欄
          h2_column,                            -- Ｈ－２欄
          i2_column,                            -- Ｉ－２欄
          j2_column,                            -- Ｊ－２欄
          k2_column,                            -- Ｋ－２欄
          l2_column,                            -- Ｌ－２欄
          f3_column,                            -- Ｆ－３欄
          g3_column,                            -- Ｇ－３欄
          h3_column,                            -- Ｈ－３欄
          i3_column,                            -- Ｉ－３欄
          j3_column,                            -- Ｊ－３欄
          k3_column,                            -- Ｋ－３欄
          l3_column,                            -- Ｌ－３欄
          chain_peculiar_area_header,           -- チェーン店固有エリア（ヘッダー）
          order_connection_number,              -- 受注関連番号
          invoice_indv_order_qty,               -- （伝票計）発注数量（バラ）
          invoice_case_order_qty,               -- （伝票計）発注数量（ケース）
          invoice_ball_order_qty,               -- （伝票計）発注数量（ボール）
          invoice_sum_order_qty,                -- （伝票計）発注数量（合計、バラ）
          invoice_indv_shipping_qty,            -- （伝票計）出荷数量（バラ）
          invoice_case_shipping_qty,            -- （伝票計）出荷数量（ケース）
          invoice_ball_shipping_qty,            -- （伝票計）出荷数量（ボール）
          invoice_pallet_shipping_qty,          -- （伝票計）出荷数量（パレット）
          invoice_sum_shipping_qty,             -- （伝票計）出荷数量（合計、バラ）
          invoice_indv_stockout_qty,            -- （伝票計）欠品数量（バラ）
          invoice_case_stockout_qty,            -- （伝票計）欠品数量（ケース）
          invoice_ball_stockout_qty,            -- （伝票計）欠品数量（ボール）
          invoice_sum_stockout_qty,             -- （伝票計）欠品数量（合計、バラ）
          invoice_case_qty,                     -- （伝票計）ケース個口数
          invoice_fold_container_qty,           -- （伝票計）オリコン（バラ）個口数
          invoice_order_cost_amt,               -- （伝票計）原価金額（発注）
          invoice_shipping_cost_amt,            -- （伝票計）原価金額（出荷）
          invoice_stockout_cost_amt,            -- （伝票計）原価金額（欠品）
          invoice_order_price_amt,              -- （伝票計）売価金額（発注）
          invoice_shipping_price_amt,           -- （伝票計）売価金額（出荷）
          invoice_stockout_price_amt,           -- （伝票計）売価金額（欠品）
          total_indv_order_qty,                 -- （総合計）発注数量（バラ）
          total_case_order_qty,                 -- （総合計）発注数量（ケース）
          total_ball_order_qty,                 -- （総合計）発注数量（ボール）
          total_sum_order_qty,                  -- （総合計）発注数量（合計、バラ）
          total_indv_shipping_qty,              -- （総合計）出荷数量（バラ）
          total_case_shipping_qty,              -- （総合計）出荷数量（ケース）
          total_ball_shipping_qty,              -- （総合計）出荷数量（ボール）
          total_pallet_shipping_qty,            -- （総合計）出荷数量（パレット）
          total_sum_shipping_qty,               -- （総合計）出荷数量（合計、バラ）
          total_indv_stockout_qty,              -- （総合計）欠品数量（バラ）
          total_case_stockout_qty,              -- （総合計）欠品数量（ケース）
          total_ball_stockout_qty,              -- （総合計）欠品数量（ボール）
          total_sum_stockout_qty,               -- （総合計）欠品数量（合計、バラ）
          total_case_qty,                       -- （総合計）ケース個口数
          total_fold_container_qty,             -- （総合計）オリコン（バラ）個口数
          total_order_cost_amt,                 -- （総合計）原価金額（発注）
          total_shipping_cost_amt,              -- （総合計）原価金額（出荷）
          total_stockout_cost_amt,              -- （総合計）原価金額（欠品）
          total_order_price_amt,                -- （総合計）売価金額（発注）
          total_shipping_price_amt,             -- （総合計）売価金額（出荷）
          total_stockout_price_amt,             -- （総合計）売価金額（欠品）
          total_line_qty,                       -- トータル行数
          total_invoice_qty,                    -- トータル伝票枚数
          chain_peculiar_area_footer,           -- チェーン店固有エリア（フッター）
          conv_customer_code,                   -- 変換後顧客コード
          order_forward_flag,                   -- 受注連携済フラグ
          creation_class,                       -- 作成元区分
          edi_delivery_schedule_flag,           -- edi納品予定送信済フラグ
          price_list_header_id,                 -- 価格表ヘッダid
          created_by,                           -- 作成者
          creation_date,                        -- 作成日
          last_updated_by,                      -- 最終更新者
          last_update_date,                     -- 最終更新日
          last_update_login,                    -- 最終更新ログイン
          request_id,                           -- 要求ID
          program_application_id,               -- コンカレント・プログラム・アプリケーションID
          program_id,                           -- コンカレント・プログラムID
/* 2011/07/26 Ver1.9 Mod Start */
--          program_update_date                   -- プログラム更新日
          program_update_date,                  -- プログラム更新日
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
          bms_header_data                       -- 流通ＢＭＳヘッダデータ
/* 2011/07/26 Ver1.9 Add End   */
        )
      VALUES
        (
          gt_req_edi_headers_data(ln_no).edi_header_info_id,     -- EDIヘッダ情報ID
          gt_req_edi_headers_data(ln_no).medium_class,           -- 媒体区分
          gt_req_edi_headers_data(ln_no).data_type_code,         -- データ種コード
          gt_req_edi_headers_data(ln_no).file_no,                -- ファイルNO
          gt_req_edi_headers_data(ln_no).info_class,             -- 情報区分
          gt_req_edi_headers_data(ln_no).process_date,           -- 処理日
          gt_req_edi_headers_data(ln_no).process_time,           -- 処理時刻
          gt_req_edi_headers_data(ln_no).base_code,              -- 拠点（部門）コード
          gt_req_edi_headers_data(ln_no).base_name,              -- 拠点名（正式名）
          gt_req_edi_headers_data(ln_no).base_name_alt,          -- 拠点名（カナ）
          gt_req_edi_headers_data(ln_no).edi_chain_code,         -- EDIチェーン店コード
          gt_req_edi_headers_data(ln_no).edi_chain_name,         -- EDIチェーン店名（漢字）
          gt_req_edi_headers_data(ln_no).edi_chain_name_alt,     -- EDIチェーン店名（カナ）
          gt_req_edi_headers_data(ln_no).chain_code,             -- チェーン店コード
          gt_req_edi_headers_data(ln_no).chain_name,             -- チェーン店名（漢字）
          gt_req_edi_headers_data(ln_no).chain_name_alt,         -- チェーン店名（カナ）
          gt_req_edi_headers_data(ln_no).report_code,            -- 帳票コード
          gt_req_edi_headers_data(ln_no).report_show_name,       -- 帳票表示名
          gt_req_edi_headers_data(ln_no).customer_code,          -- 顧客コード
          gt_req_edi_headers_data(ln_no).customer_name,          -- 顧客名（漢字）
          gt_req_edi_headers_data(ln_no).customer_name_alt,      -- 顧客名（カナ）
          gt_req_edi_headers_data(ln_no).company_code,           -- 社コード
          gt_req_edi_headers_data(ln_no).company_name,           -- 社名（漢字）
          gt_req_edi_headers_data(ln_no).company_name_alt,       -- 社名（カナ）
          gt_req_edi_headers_data(ln_no).shop_code,              -- 店コード
          gt_req_edi_headers_data(ln_no).shop_name,              -- 店名（漢字）
          gt_req_edi_headers_data(ln_no).shop_name_alt,          -- 店名（カナ）
          gt_req_edi_headers_data(ln_no).deli_center_code,       -- 納入センターコード
          gt_req_edi_headers_data(ln_no).deli_center_name,       -- 納入センター名（漢字）
          gt_req_edi_headers_data(ln_no).deli_center_name_alt,   -- 納入センター名（カナ）
          gt_req_edi_headers_data(ln_no).order_date,             -- 発注日
          gt_req_edi_headers_data(ln_no).center_delivery_date,   -- センター納品日
          gt_req_edi_headers_data(ln_no).result_delivery_date,   -- 実納品日
          gt_req_edi_headers_data(ln_no).shop_delivery_date,     -- 店舗納品日
          gt_req_edi_headers_data(ln_no).data_cd_edi_data,       -- データ作成日（EDIデータ中）
          gt_req_edi_headers_data(ln_no).data_ct_edi_data,       -- データ作成時刻（EDIデータ中）
          gt_req_edi_headers_data(ln_no).invoice_class,          -- 伝票区分
          gt_req_edi_headers_data(ln_no).small_class_cd,         -- 小分類コード
          gt_req_edi_headers_data(ln_no).small_class_nm,         -- 小分類名
          gt_req_edi_headers_data(ln_no).mid_class_cd,           -- 中分類コード
          gt_req_edi_headers_data(ln_no).mid_class_nm,           -- 中分類名
          gt_req_edi_headers_data(ln_no).big_class_cd,           -- 大分類コード
          gt_req_edi_headers_data(ln_no).big_class_nm,           -- 大分類名
          gt_req_edi_headers_data(ln_no).other_par_dep_cd,       -- 相手先部門コード
          gt_req_edi_headers_data(ln_no).other_par_order_num,    -- 相手先発注番号
          gt_req_edi_headers_data(ln_no).check_digit_class,      -- チェックデジット有無区分
          gt_req_edi_headers_data(ln_no).invoice_number,         -- 伝票番号
          gt_req_edi_headers_data(ln_no).check_digit,            -- チェックデジット
          gt_req_edi_headers_data(ln_no).close_date,             -- 月限
          gt_req_edi_headers_data(ln_no).order_no_ebs,           -- 受注NO（EBS）
          gt_req_edi_headers_data(ln_no).ar_sale_class,          -- 特売区分
          gt_req_edi_headers_data(ln_no).delivery_classe,        -- 配送区分
          gt_req_edi_headers_data(ln_no).opportunity_no,         -- 便NO
          gt_req_edi_headers_data(ln_no).contact_to,             -- 連絡先
          gt_req_edi_headers_data(ln_no).route_sales,            -- ルートセールス
          gt_req_edi_headers_data(ln_no).corporate_code,         -- 法人コード
          gt_req_edi_headers_data(ln_no).maker_name,             -- メーカー名
          gt_req_edi_headers_data(ln_no).area_code,              -- 地区コード
          gt_req_edi_headers_data(ln_no).area_name,              -- 地区名（漢字）
          gt_req_edi_headers_data(ln_no).area_name_alt,          -- 地区名（カナ）
          gt_req_edi_headers_data(ln_no).vendor_code,            -- 取引先コード
          gt_req_edi_headers_data(ln_no).vendor_name,            -- 取引先名（漢字）
          gt_req_edi_headers_data(ln_no).vendor_name1_alt,       -- 取引先名１（カナ）
          gt_req_edi_headers_data(ln_no).vendor_name2_alt,       -- 取引先名２（カナ）
          gt_req_edi_headers_data(ln_no).vendor_tel,             -- 取引先TEL
          gt_req_edi_headers_data(ln_no).vendor_charge,          -- 取引先担当者
          gt_req_edi_headers_data(ln_no).vendor_address,         -- 取引先住所（漢字）
          gt_req_edi_headers_data(ln_no).deli_to_cd_itouen,      -- 届け先コード（伊藤園）
          gt_req_edi_headers_data(ln_no).deli_to_cd_chain,       -- 届け先コード（チェーン店）
          gt_req_edi_headers_data(ln_no).deli_to,                -- 届け先（漢字）
          gt_req_edi_headers_data(ln_no).deli_to1_alt,           -- 届け先１（カナ）
          gt_req_edi_headers_data(ln_no).deli_to2_alt,           -- 届け先２（カナ）
          gt_req_edi_headers_data(ln_no).deli_to_add,            -- 届け先住所（漢字）
          gt_req_edi_headers_data(ln_no).deli_to_add_alt,        -- 届け先住所（カナ）
          gt_req_edi_headers_data(ln_no).deli_to_tel,            -- 届け先TEL
          gt_req_edi_headers_data(ln_no).bal_accounts_cd,        -- 帳合先コード
          gt_req_edi_headers_data(ln_no).bal_acc_comp_cd,        -- 帳合先社コード
          gt_req_edi_headers_data(ln_no).bal_acc_shop_cd,        -- 帳合先店コード
          gt_req_edi_headers_data(ln_no).bal_acc_name,           -- 帳合先名（漢字）
          gt_req_edi_headers_data(ln_no).bal_acc_name_alt,       -- 帳合先名（カナ）
          gt_req_edi_headers_data(ln_no).bal_acc_add,            -- 帳合先住所（漢字）
          gt_req_edi_headers_data(ln_no).bal_acc_add_alt,        -- 帳合先住所（カナ）
          gt_req_edi_headers_data(ln_no).bal_acc_tel,            -- 帳合先TEL
          gt_req_edi_headers_data(ln_no).order_possible_date,    -- 受注可能日
          gt_req_edi_headers_data(ln_no).perm_poss_date,         -- 許容可能日
          gt_req_edi_headers_data(ln_no).forward_month,          -- 先限年月日
          gt_req_edi_headers_data(ln_no).pay_settl_date,         -- 支払決済日
          gt_req_edi_headers_data(ln_no).hand_st_date_act,       -- チラシ開始日
          gt_req_edi_headers_data(ln_no).billing_due_date,       -- 請求締日
          gt_req_edi_headers_data(ln_no).shipping_time,          -- 出荷時刻
          gt_req_edi_headers_data(ln_no).deli_schedule_time,     -- 納品予定時間
          gt_req_edi_headers_data(ln_no).order_time,             -- 発注時間
          gt_req_edi_headers_data(ln_no).general_date_item1,     -- 汎用日付項目１
          gt_req_edi_headers_data(ln_no).general_date_item2,     -- 汎用日付項目２
          gt_req_edi_headers_data(ln_no).general_date_item3,     -- 汎用日付項目３
          gt_req_edi_headers_data(ln_no).general_date_item4,     -- 汎用日付項目４
          gt_req_edi_headers_data(ln_no).general_date_item5,     -- 汎用日付項目５
          gt_req_edi_headers_data(ln_no).arr_shipping_class,     -- 入出荷区分
          gt_req_edi_headers_data(ln_no).vendor_class,           -- 取引先区分
          gt_req_edi_headers_data(ln_no).inv_detailed_class,     -- 伝票内訳区分
          gt_req_edi_headers_data(ln_no).unit_price_use_class,   -- 単価使用区分
          gt_req_edi_headers_data(ln_no).sub_dist_center_cd,     -- サブ物流センターコード
          gt_req_edi_headers_data(ln_no).sub_dist_center_nm,     -- サブ物流センターコード名
          gt_req_edi_headers_data(ln_no).center_deli_method,     -- センター納品方法
          gt_req_edi_headers_data(ln_no).center_use_class,       -- センター利用区分
          gt_req_edi_headers_data(ln_no).center_whse_class,      -- センター倉庫区分
          gt_req_edi_headers_data(ln_no).center_area_class,      -- センター地域区分
          gt_req_edi_headers_data(ln_no).center_arr_class,       -- センター入荷区分
          gt_req_edi_headers_data(ln_no).depot_class,            -- デポ区分
          gt_req_edi_headers_data(ln_no).tcdc_class,             -- TCDC区分
          gt_req_edi_headers_data(ln_no).upc_flag,               -- UPCフラグ
          gt_req_edi_headers_data(ln_no).simultaneously_cls,     -- 一斉区分
          gt_req_edi_headers_data(ln_no).business_id,            -- 業務ID
          gt_req_edi_headers_data(ln_no).whse_directly_cls,      -- 倉直区分
          gt_req_edi_headers_data(ln_no).premium_rebate_cls,     -- 景品割戻区分
          gt_req_edi_headers_data(ln_no).item_type,              -- 項目種別
          gt_req_edi_headers_data(ln_no).cloth_hous_fod_cls,     -- 衣家食区分
          gt_req_edi_headers_data(ln_no).mix_class,              -- 混在区分
          gt_req_edi_headers_data(ln_no).stk_class,              -- 在庫区分
          gt_req_edi_headers_data(ln_no).last_mod_site_cls,      -- 最終修正場所区分
          gt_req_edi_headers_data(ln_no).report_class,           -- 帳票区分
          gt_req_edi_headers_data(ln_no).add_plan_cls,           -- 追加・計画区分
          gt_req_edi_headers_data(ln_no).registration_class,     -- 登録区分
          gt_req_edi_headers_data(ln_no).specific_class,         -- 特定区分
          gt_req_edi_headers_data(ln_no).dealings_class,         -- 取引区分
          gt_req_edi_headers_data(ln_no).order_class,            -- 発注区分
          gt_req_edi_headers_data(ln_no).sum_line_class,         -- 集計明細区分
          gt_req_edi_headers_data(ln_no).ship_guidance_cls,      -- 出荷案内以外区分
          gt_req_edi_headers_data(ln_no).shipping_class,         -- 出荷区分
          gt_req_edi_headers_data(ln_no).prod_cd_use_cls,        -- 商品コード使用区分
          gt_req_edi_headers_data(ln_no).cargo_item_class,       -- 積送品区分
          gt_req_edi_headers_data(ln_no).ta_class,               -- T/A区分
          gt_req_edi_headers_data(ln_no).plan_code,              -- 企画コード
          gt_req_edi_headers_data(ln_no).category_code,          -- カテゴリーコード
          gt_req_edi_headers_data(ln_no).category_class,         -- カテゴリー区分
          gt_req_edi_headers_data(ln_no).carrier_means,          -- 運送手段
          gt_req_edi_headers_data(ln_no).counter_code,           -- 売場コード
          gt_req_edi_headers_data(ln_no).move_sign,              -- 移動サイン
          gt_req_edi_headers_data(ln_no).eos_handwrit_cls,       -- EOS・手書区分
          gt_req_edi_headers_data(ln_no).deli_to_section_cd,     -- 納品先課コード
          gt_req_edi_headers_data(ln_no).invoice_detailed,       -- 伝票内訳
          gt_req_edi_headers_data(ln_no).attach_qty,             -- 添付数
          gt_req_edi_headers_data(ln_no).other_party_floor,      -- フロア
          gt_req_edi_headers_data(ln_no).text_no,                -- TEXTNO
          gt_req_edi_headers_data(ln_no).in_store_code,          -- インストアコード
          gt_req_edi_headers_data(ln_no).tag_data,               -- タグ
          gt_req_edi_headers_data(ln_no).competition_code,       -- 競合
          gt_req_edi_headers_data(ln_no).billing_chair,          -- 請求口座
          gt_req_edi_headers_data(ln_no).chain_store_code,       -- チェーンストアーコード
          gt_req_edi_headers_data(ln_no).chain_st_sh_name,       -- チェーンストアーコード略式名称
          gt_req_edi_headers_data(ln_no).dir_deli_rcpt_fee,      -- 直配送／引取料
          gt_req_edi_headers_data(ln_no).bill_info,              -- 手形情報
          gt_req_edi_headers_data(ln_no).description,            -- 摘要
          gt_req_edi_headers_data(ln_no).interior_code,          -- 内部コード
          gt_req_edi_headers_data(ln_no).order_in_deli_cate,     -- 発注情報　納品カテゴリー
          gt_req_edi_headers_data(ln_no).purchase_type,          -- 仕入形態
          gt_req_edi_headers_data(ln_no).deli_to_name_alt,       -- 納品場所名（カナ）
          gt_req_edi_headers_data(ln_no).shop_opened_site,       -- 店出場所
          gt_req_edi_headers_data(ln_no).counter_name,           -- 売場名
          gt_req_edi_headers_data(ln_no).extension_number,       -- 内線番号
          gt_req_edi_headers_data(ln_no).charge_name,            -- 担当者名
          gt_req_edi_headers_data(ln_no).price_tag,              -- 値札
          gt_req_edi_headers_data(ln_no).tax_type,               -- 税種
          gt_req_edi_headers_data(ln_no).consump_tax_cls,        -- 消費税区分
          gt_req_edi_headers_data(ln_no).brand_class,            -- BR
          gt_req_edi_headers_data(ln_no).id_code,                -- IDコード
          gt_req_edi_headers_data(ln_no).department_code,        -- 百貨店コード
          gt_req_edi_headers_data(ln_no).department_name,        -- 百貨店名
          gt_req_edi_headers_data(ln_no).item_type_number,       -- 品別番号
          gt_req_edi_headers_data(ln_no).description_depart,     -- 摘要（百貨店）
          gt_req_edi_headers_data(ln_no).price_tag_method,       -- 値札方法
          gt_req_edi_headers_data(ln_no).reason_column,          -- 自由欄
          gt_req_edi_headers_data(ln_no).a_column_header,        -- A欄ヘッダ
          gt_req_edi_headers_data(ln_no).d_column_header,        -- D欄ヘッダ
          gt_req_edi_headers_data(ln_no).brand_code,             -- ブランドコード
          gt_req_edi_headers_data(ln_no).line_code,              -- ラインコード
          gt_req_edi_headers_data(ln_no).class_code,             -- クラスコード
          gt_req_edi_headers_data(ln_no).a1_column,              -- Ａ－１欄
          gt_req_edi_headers_data(ln_no).b1_column,              -- Ｂ－１欄
          gt_req_edi_headers_data(ln_no).c1_column,              -- Ｃ－１欄
          gt_req_edi_headers_data(ln_no).d1_column,              -- Ｄ－１欄
          gt_req_edi_headers_data(ln_no).e1_column,              -- Ｅ－１欄
          gt_req_edi_headers_data(ln_no).a2_column,              -- Ａ－２欄
          gt_req_edi_headers_data(ln_no).b2_column,              -- Ｂ－２欄
          gt_req_edi_headers_data(ln_no).c2_column,              -- Ｃ－２欄
          gt_req_edi_headers_data(ln_no).d2_column,              -- Ｄ－２欄
          gt_req_edi_headers_data(ln_no).e2_column,              -- Ｅ－２欄
          gt_req_edi_headers_data(ln_no).a3_column,              -- Ａ－３欄
          gt_req_edi_headers_data(ln_no).b3_column,              -- Ｂ－３欄
          gt_req_edi_headers_data(ln_no).c3_column,              -- Ｃ－３欄
          gt_req_edi_headers_data(ln_no).d3_column,              -- Ｄ－３欄
          gt_req_edi_headers_data(ln_no).e3_column,              -- Ｅ－３欄
          gt_req_edi_headers_data(ln_no).f1_column,              -- Ｆ－１欄
          gt_req_edi_headers_data(ln_no).g1_column,              -- Ｇ－１欄
          gt_req_edi_headers_data(ln_no).h1_column,              -- Ｈ－１欄
          gt_req_edi_headers_data(ln_no).i1_column,              -- Ｉ－１欄
          gt_req_edi_headers_data(ln_no).j1_column,              -- Ｊ－１欄
          gt_req_edi_headers_data(ln_no).k1_column,              -- Ｋ－１欄
          gt_req_edi_headers_data(ln_no).l1_column,              -- Ｌ－１欄
          gt_req_edi_headers_data(ln_no).f2_column,              -- Ｆ－２欄
          gt_req_edi_headers_data(ln_no).g2_column,              -- Ｇ－２欄
          gt_req_edi_headers_data(ln_no).h2_column,              -- Ｈ－２欄
          gt_req_edi_headers_data(ln_no).i2_column,              -- Ｉ－２欄
          gt_req_edi_headers_data(ln_no).j2_column,              -- Ｊ－２欄
          gt_req_edi_headers_data(ln_no).k2_column,              -- Ｋ－２欄
          gt_req_edi_headers_data(ln_no).l2_column,              -- Ｌ－２欄
          gt_req_edi_headers_data(ln_no).f3_column,              -- Ｆ－３欄
          gt_req_edi_headers_data(ln_no).g3_column,              -- Ｇ－３欄
          gt_req_edi_headers_data(ln_no).h3_column,              -- Ｈ－３欄
          gt_req_edi_headers_data(ln_no).i3_column,              -- Ｉ－３欄
          gt_req_edi_headers_data(ln_no).j3_column,              -- Ｊ－３欄
          gt_req_edi_headers_data(ln_no).k3_column,              -- Ｋ－３欄
          gt_req_edi_headers_data(ln_no).l3_column,              -- Ｌ－３欄
-- 2010/04/23 v1.8 T.Yoshimoto Mod Start 本稼動#2427
--          gt_req_edi_headers_data(ln_no).chain_pe_area_foot,     -- チェーン店固有エリア（ヘッダー）
          gt_req_edi_headers_data(ln_no).chain_pe_area_head,     -- チェーン店固有エリア（ヘッダー）
-- 2010/04/23 v1.8 T.Yoshimoto Mod End 本稼動#2427
          gt_req_edi_headers_data(ln_no).order_connect_num,      -- 受注関連番号
          gt_req_edi_headers_data(ln_no).inv_indv_order_qty,     -- （伝票計）発注数量（バラ）
          gt_req_edi_headers_data(ln_no).inv_case_order_qty,     -- （伝票計）発注数量（ケース）
          gt_req_edi_headers_data(ln_no).inv_ball_order_qty,     -- （伝票計）発注数量（ボール）
          gt_req_edi_headers_data(ln_no).inv_sum_order_qty,      -- （伝票計）発注数量（合計、バラ）
          gt_req_edi_headers_data(ln_no).inv_indv_ship_qty,      -- （伝票計）出荷数量（バラ）
          gt_req_edi_headers_data(ln_no).inv_case_ship_qty,      -- （伝票計）出荷数量（ケース）
          gt_req_edi_headers_data(ln_no).inv_ball_ship_qty,      -- （伝票計）出荷数量（ボール）
          gt_req_edi_headers_data(ln_no).inv_pall_ship_qty,      -- （伝票計）出荷数量（パレット）
          gt_req_edi_headers_data(ln_no).inv_sum_ship_qty,       -- （伝票計）出荷数量（合計、バラ）
          gt_req_edi_headers_data(ln_no).inv_indv_stock_qty,     -- （伝票計）欠品数量（バラ）
          gt_req_edi_headers_data(ln_no).inv_case_stock_qty,     -- （伝票計）欠品数量（ケース）
          gt_req_edi_headers_data(ln_no).inv_ball_stock_qty,     -- （伝票計）欠品数量（ボール）
          gt_req_edi_headers_data(ln_no).inv_sum_stock_qty,      -- （伝票計）欠品数量（合計、バラ）
          gt_req_edi_headers_data(ln_no).inv_case_qty,           -- （伝票計）ケース個口数
          gt_req_edi_headers_data(ln_no).inv_fold_cont_qty,      -- （伝票計）オリコン（バラ）個口数
          gt_req_edi_headers_data(ln_no).inv_order_cost_amt,     -- （伝票計）原価金額（発注）
          gt_req_edi_headers_data(ln_no).inv_ship_cost_amt,      -- （伝票計）原価金額（出荷）
          gt_req_edi_headers_data(ln_no).inv_stock_cost_amt,     -- （伝票計）原価金額（欠品）
          gt_req_edi_headers_data(ln_no).inv_order_price_amt,    -- （伝票計）売価金額（発注）
          gt_req_edi_headers_data(ln_no).inv_ship_price_amt,     -- （伝票計）売価金額（出荷）
          gt_req_edi_headers_data(ln_no).inv_stock_price_amt,    -- （伝票計）売価金額（欠品）
          gt_req_edi_headers_data(ln_no).tot_indv_order_qty,     -- （総合計）発注数量（バラ）
          gt_req_edi_headers_data(ln_no).tot_case_order_qty,     -- （総合計）発注数量（ケース）
          gt_req_edi_headers_data(ln_no).tot_ball_order_qty,     -- （総合計）発注数量（ボール）
          gt_req_edi_headers_data(ln_no).tot_sum_order_qty,      -- （総合計）発注数量（合計、バラ）
          gt_req_edi_headers_data(ln_no).tot_indv_ship_qty,      -- （総合計）出荷数量（バラ）
          gt_req_edi_headers_data(ln_no).tot_case_ship_qty,      -- （総合計）出荷数量（ケース）
          gt_req_edi_headers_data(ln_no).tot_ball_ship_qty,      -- （総合計）出荷数量（ボール）
          gt_req_edi_headers_data(ln_no).tot_pallet_ship_qty,    -- （総合計）出荷数量（パレット）
          gt_req_edi_headers_data(ln_no).tot_sum_ship_qty,       -- （総合計）出荷数量（合計、バラ）
          gt_req_edi_headers_data(ln_no).tot_indv_stockout_qty,  -- （総合計）欠品数量（バラ）
          gt_req_edi_headers_data(ln_no).tot_case_stockout_qty,  -- （総合計）欠品数量（ケース）
          gt_req_edi_headers_data(ln_no).tot_ball_stockout_qty,  -- （総合計）欠品数量（ボール）
          gt_req_edi_headers_data(ln_no).tot_sum_stockout_qty,   -- （総合計）欠品数量（合計、バラ）
          gt_req_edi_headers_data(ln_no).tot_case_qty,           -- （総合計）ケース個口数
          gt_req_edi_headers_data(ln_no).tot_fold_container_qty, -- （総合計）オリコン（バラ）個口数
          gt_req_edi_headers_data(ln_no).tot_order_cost_amt,     -- （総合計）原価金額（発注）
          gt_req_edi_headers_data(ln_no).tot_ship_cost_amt,      -- （総合計）原価金額（出荷）
          gt_req_edi_headers_data(ln_no).tot_stockout_cost_amt,  -- （総合計）原価金額（欠品）
          gt_req_edi_headers_data(ln_no).tot_order_price_amt,    -- （総合計）売価金額（発注）
          gt_req_edi_headers_data(ln_no).tot_ship_price_amt,     -- （総合計）売価金額（出荷）
          gt_req_edi_headers_data(ln_no).tot_stockout_price_amt, -- （総合計）売価金額（欠品）
          gt_req_edi_headers_data(ln_no).tot_line_qty,           -- トータル行数
          gt_req_edi_headers_data(ln_no).tot_invoice_qty,        -- トータル伝票枚数
          gt_req_edi_headers_data(ln_no).chain_pe_area_foot,     -- チェーン店固有エリア（フッター）
          gt_req_edi_headers_data(ln_no).conv_customer_code,     -- 変換後顧客コード
          gt_req_edi_headers_data(ln_no).order_forward_flag,     -- 受注連携済フラグ
          gt_req_edi_headers_data(ln_no).creation_class,         -- 作成元区分
          gt_req_edi_headers_data(ln_no).edi_deli_sche_flg,      -- edi納品予定送信済フラグ
          gt_req_edi_headers_data(ln_no).price_list_header_id,   -- 価格表ヘッダid
          cn_created_by,                      -- 作成者
          cd_creation_date,                   -- 作成日
          cn_last_updated_by,                 -- 最終更新者
          cd_last_update_date,                -- 最終更新日
          cn_last_update_login,               -- 最終更新ログイン
          cn_request_id,                      -- 要求ID
          cn_program_application_id,          -- コンカレント・プログラム・アプリケーションID
          cn_program_id,                      -- コンカレント・プログラムID
/* 2011/07/26 Ver1.9 Mod Start */
--          cd_program_update_date              -- プログラム更新日
          cd_program_update_date,             -- プログラム更新日
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
          gt_req_edi_headers_data(ln_no).bms_header_data         -- 流通ＢＭＳヘッダデータ
/* 2011/07/26 Ver1.9 Add End   */
        );
--
    END LOOP xxcos_edi_headers_insert;
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END xxcos_in_edi_headers_insert;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_lines_insert
   * Description      : EDI明細情報テーブルへのデータ挿入(A-8)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_lines_insert(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_lines_insert'; -- プログラム名
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
    lv_edi_header_info_id  NUMBER  DEFAULT 0;
--
    ln_edi_line_info_id    NUMBER  DEFAULT 0;
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
    --* -------------------------------------------------------------
    -- ループ開始：
    --* -------------------------------------------------------------
    <<xxcos_edi_lines_insert>>
    FOR  ln_no  IN  1..gn_normal_lines_cnt  LOOP
      --* -------------------------------------------------------------
      --* Description      : EDI明細情報テーブルへのデータ挿入(A-8)
      --* -------------------------------------------------------------
      INSERT  INTO  xxcos_edi_lines
        (
          edi_line_info_id,
          edi_header_info_id,
          line_no,
          stockout_class,
          stockout_reason,
          product_code_itouen,
          product_code1,
          product_code2,
          jan_code,
          itf_code,
          extension_itf_code,
          case_product_code,
          ball_product_code,
          product_code_item_type,
          prod_class,
          product_name,
          product_name1_alt,
          product_name2_alt,
          item_standard1,
          item_standard2,
          qty_in_case,
          num_of_cases,
          num_of_ball,
          item_color,
          item_size,
          expiration_date,
          product_date,
          order_uom_qty,
          shipping_uom_qty,
          packing_uom_qty,
          deal_code,
          deal_class,
          collation_code,
          uom_code,
          unit_price_class,
          parent_packing_number,
          packing_number,
          product_group_code,
          case_dismantle_flag,
          case_class,
          indv_order_qty,
          case_order_qty,
          ball_order_qty,
          sum_order_qty,
          indv_shipping_qty,
          case_shipping_qty,
          ball_shipping_qty,
          pallet_shipping_qty,
          sum_shipping_qty,
          indv_stockout_qty,
          case_stockout_qty,
          ball_stockout_qty,
          sum_stockout_qty,
          case_qty,
          fold_container_indv_qty,
          order_unit_price,
          shipping_unit_price,
          order_cost_amt,
          shipping_cost_amt,
          stockout_cost_amt,
          selling_price,
          order_price_amt,
          shipping_price_amt,
          stockout_price_amt,
          a_column_department,
          d_column_department,
          standard_info_depth,
          standard_info_height,
          standard_info_width,
          standard_info_weight,
          general_succeeded_item1,
          general_succeeded_item2,
          general_succeeded_item3,
          general_succeeded_item4,
          general_succeeded_item5,
          general_succeeded_item6,
          general_succeeded_item7,
          general_succeeded_item8,
          general_succeeded_item9,
          general_succeeded_item10,
          general_add_item1,
          general_add_item2,
          general_add_item3,
          general_add_item4,
          general_add_item5,
          general_add_item6,
          general_add_item7,
          general_add_item8,
          general_add_item9,
          general_add_item10,
          chain_peculiar_area_line,
          item_code,
          line_uom,
          order_connection_line_number,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
/* 2011/07/26 Ver1.9 Mod Start */
--          program_update_date
          program_update_date,
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
          bms_line_data
/* 2011/07/26 Ver1.9 Add End   */
        )
      VALUES
        (
          gt_req_edi_lines_data(ln_no).edi_line_info_id,        -- EDI明細情報ID
          gt_req_edi_lines_data(ln_no).edi_header_info_id,      -- EDIヘッダ情報ID
          gt_req_edi_lines_data(ln_no).line_no,                 -- 行ｎｏ
          gt_req_edi_lines_data(ln_no).stockout_class,          -- 欠品区分
          gt_req_edi_lines_data(ln_no).stockout_reason,         -- 欠品理由
          gt_req_edi_lines_data(ln_no).product_code_itouen,     -- 商品コード（伊藤園）
          gt_req_edi_lines_data(ln_no).product_code1,           -- 商品コード１
          gt_req_edi_lines_data(ln_no).product_code2,           -- 商品コード２
          gt_req_edi_lines_data(ln_no).jan_code,                -- JANコード
          gt_req_edi_lines_data(ln_no).itf_code,                -- ITFコード
          gt_req_edi_lines_data(ln_no).extension_itf_code,      -- 内箱ITFコード
          gt_req_edi_lines_data(ln_no).case_product_code,       -- ケース商品コード
          gt_req_edi_lines_data(ln_no).ball_product_code,       -- ボール商品コード
          gt_req_edi_lines_data(ln_no).prod_cd_item_type,       -- 商品コード品種
          gt_req_edi_lines_data(ln_no).prod_class,              -- 商品区分
          gt_req_edi_lines_data(ln_no).product_name,            -- 商品名（漢字）
          gt_req_edi_lines_data(ln_no).product_name1_alt,       -- 商品名１（カナ）
          gt_req_edi_lines_data(ln_no).product_name2_alt,       -- 商品名２（カナ）
          gt_req_edi_lines_data(ln_no).item_standard1,          -- 規格１
          gt_req_edi_lines_data(ln_no).item_standard2,          -- 規格２
          gt_req_edi_lines_data(ln_no).qty_in_case,             -- 入数
          gt_req_edi_lines_data(ln_no).num_of_cases,            -- ケース入数
          gt_req_edi_lines_data(ln_no).num_of_ball,             -- ボール入数
          gt_req_edi_lines_data(ln_no).item_color,              -- 色
          gt_req_edi_lines_data(ln_no).item_size,               -- サイズ
          gt_req_edi_lines_data(ln_no).expiration_date,         -- 賞味期限日
          gt_req_edi_lines_data(ln_no).product_date,            -- 製造日
          gt_req_edi_lines_data(ln_no).order_uom_qty,           -- 発注単位数
          gt_req_edi_lines_data(ln_no).ship_uom_qty,            -- 出荷単位数
          gt_req_edi_lines_data(ln_no).packing_uom_qty,         -- 梱包単位数
          gt_req_edi_lines_data(ln_no).deal_code,               -- 引合
          gt_req_edi_lines_data(ln_no).deal_class,              -- 引合区分
          gt_req_edi_lines_data(ln_no).collation_code,          -- 照合
          gt_req_edi_lines_data(ln_no).uom_code,                -- 単位
          gt_req_edi_lines_data(ln_no).unit_price_class,        -- 単価区分
          gt_req_edi_lines_data(ln_no).parent_pack_num,         -- 親梱包番号
          gt_req_edi_lines_data(ln_no).packing_number,          -- 梱包番号
          gt_req_edi_lines_data(ln_no).product_group_code,      -- 商品群コード
          gt_req_edi_lines_data(ln_no).case_dismantle_flag,     -- ケース解体不可フラグ
          gt_req_edi_lines_data(ln_no).case_class,              -- ケース区分
          gt_req_edi_lines_data(ln_no).indv_order_qty,          -- 発注数量（バラ）
          gt_req_edi_lines_data(ln_no).case_order_qty,          -- 発注数量（ケース）
          gt_req_edi_lines_data(ln_no).ball_order_qty,          -- 発注数量（ボール）
          gt_req_edi_lines_data(ln_no).sum_order_qty,           -- 発注数量（合計、バラ）
          gt_req_edi_lines_data(ln_no).indv_shipping_qty,       -- 出荷数量（バラ）
          gt_req_edi_lines_data(ln_no).case_shipping_qty,       -- 出荷数量（ケース）
          gt_req_edi_lines_data(ln_no).ball_shipping_qty,       -- 出荷数量（ボール）
          gt_req_edi_lines_data(ln_no).pallet_shipping_qty,     -- 出荷数量（パレット）
          gt_req_edi_lines_data(ln_no).sum_shipping_qty,        -- 出荷数量（合計、バラ）
          gt_req_edi_lines_data(ln_no).indv_stockout_qty,       -- 欠品数量（バラ）
          gt_req_edi_lines_data(ln_no).case_stockout_qty,       -- 欠品数量（ケース）
          gt_req_edi_lines_data(ln_no).ball_stockout_qty,       -- 欠品数量（ボール）
          gt_req_edi_lines_data(ln_no).sum_stockout_qty,        -- 欠品数量（合計、バラ）
          gt_req_edi_lines_data(ln_no).case_qty,                -- ケース個口数
          gt_req_edi_lines_data(ln_no).fold_cont_indv_qty,      -- オリコン（バラ）個口数
          gt_req_edi_lines_data(ln_no).order_unit_price,        -- 原単価（発注）
          gt_req_edi_lines_data(ln_no).shipping_unit_price,     -- 原単価（出荷）
          gt_req_edi_lines_data(ln_no).order_cost_amt,          -- 原価金額（発注）
          gt_req_edi_lines_data(ln_no).shipping_cost_amt,       -- 原価金額（出荷）
          gt_req_edi_lines_data(ln_no).stockout_cost_amt,       -- 原価金額（欠品）
          gt_req_edi_lines_data(ln_no).selling_price,           -- 売単価
          gt_req_edi_lines_data(ln_no).order_price_amt,         -- 売価金額（発注）
          gt_req_edi_lines_data(ln_no).shipping_price_amt,      -- 売価金額（出荷）
          gt_req_edi_lines_data(ln_no).stockout_price_amt,      -- 売価金額（欠品）
          gt_req_edi_lines_data(ln_no).a_col_department,        -- A欄（百貨店）
          gt_req_edi_lines_data(ln_no).d_col_department,        -- D欄（百貨店）
          gt_req_edi_lines_data(ln_no).stand_info_depth,        -- 規格情報・奥行き
          gt_req_edi_lines_data(ln_no).stand_info_height,       -- 規格情報・高さ
          gt_req_edi_lines_data(ln_no).stand_info_width,        -- 規格情報・幅
          gt_req_edi_lines_data(ln_no).stand_info_weight,       -- 規格情報・重量
          gt_req_edi_lines_data(ln_no).gen_succeed_item1,       -- 汎用引継ぎ項目１
          gt_req_edi_lines_data(ln_no).gen_succeed_item2,       -- 汎用引継ぎ項目２
          gt_req_edi_lines_data(ln_no).gen_succeed_item3,       -- 汎用引継ぎ項目３
          gt_req_edi_lines_data(ln_no).gen_succeed_item4,       -- 汎用引継ぎ項目４
          gt_req_edi_lines_data(ln_no).gen_succeed_item5,       -- 汎用引継ぎ項目５
          gt_req_edi_lines_data(ln_no).gen_succeed_item6,       -- 汎用引継ぎ項目６
          gt_req_edi_lines_data(ln_no).gen_succeed_item7,       -- 汎用引継ぎ項目７
          gt_req_edi_lines_data(ln_no).gen_succeed_item8,       -- 汎用引継ぎ項目８
          gt_req_edi_lines_data(ln_no).gen_succeed_item9,       -- 汎用引継ぎ項目９
          gt_req_edi_lines_data(ln_no).gen_succeed_item10,      -- 汎用引継ぎ項目１０
          gt_req_edi_lines_data(ln_no).gen_add_item1,           -- 汎用付加項目１
          gt_req_edi_lines_data(ln_no).gen_add_item2,           -- 汎用付加項目２
          gt_req_edi_lines_data(ln_no).gen_add_item3,           -- 汎用付加項目３
          gt_req_edi_lines_data(ln_no).gen_add_item4,           -- 汎用付加項目４
          gt_req_edi_lines_data(ln_no).gen_add_item5,           -- 汎用付加項目５
          gt_req_edi_lines_data(ln_no).gen_add_item6,           -- 汎用付加項目６
          gt_req_edi_lines_data(ln_no).gen_add_item7,           -- 汎用付加項目７
          gt_req_edi_lines_data(ln_no).gen_add_item8,           -- 汎用付加項目８
          gt_req_edi_lines_data(ln_no).gen_add_item9,           -- 汎用付加項目９
          gt_req_edi_lines_data(ln_no).gen_add_item10,          -- 汎用付加項目１０
          gt_req_edi_lines_data(ln_no).chain_pec_a_line,        -- チェーン店固有エリア（明細）
          gt_req_edi_lines_data(ln_no).item_code,               -- 品目コード
          gt_req_edi_lines_data(ln_no).line_uom,                -- ケースバラ区分
          gt_req_edi_lines_data(ln_no).order_con_line_num,      -- 受注関連明細番号
          cn_created_by,                          -- 作成者
          cd_creation_date,                       -- 作成日
          cn_last_updated_by,                     -- 最終更新者
          cd_last_update_date,                    -- 最終更新日
          cn_last_update_login,                   -- 最終更新ログイン
          cn_request_id,                          -- 要求ID
          cn_program_application_id,              -- コンカレント・プログラム・アプリケーションID
          cn_program_id,                          -- コンカレント・プログラムID
/* 2011/07/26 Ver1.9 Mod Start */
--          cd_program_update_date                  -- プログラム更新日
          cd_program_update_date,                 -- プログラム更新日
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
          gt_req_edi_lines_data(ln_no).bms_line_data            -- 流通ＢＭＳヘッダデータ
/* 2011/07/26 Ver1.9 Add End   */
        );
--
    END LOOP  xxcos_edi_lines_insert;
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
--
  --成功件数
  gn_normal_cnt := gn_normal_lines_cnt;
--
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--

    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END xxcos_in_edi_lines_insert;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_deli_work_delete
   * Description      : EDI納品返品情報ワークテーブルデータ削除(A-9)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_deli_work_delete(
    iv_file_name      IN  VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN  VARCHAR2,     --   実行区分：「新規」「再実行」
    iv_edi_chain_code IN  VARCHAR2,     --   EDIチェーン店コード
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_deli_work_delete'; -- プログラム名
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
    BEGIN
      DELETE FROM xxcos_edi_delivery_work edideliwk
       WHERE  edideliwk.if_file_name     = iv_file_name           -- インタフェースファイル名
         AND  edideliwk.err_status       = iv_run_class           -- 実行区分
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--         AND  edideliwk.data_type_code   = gv_run_data_type_code  -- データ種コード
         AND  edideliwk.data_type_code   IN ( cv_data_type_32, cv_data_type_33 )  -- データ種コード
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
         AND (( iv_edi_chain_code IS NOT NULL
         AND   edideliwk.edi_chain_code  =  iv_edi_chain_code )   -- EDIチェーン店コード
         OR  ( iv_edi_chain_code IS NULL ));
--
    EXCEPTION
      WHEN OTHERS THEN
        -- EDI納品返品情報ワークテーブル
        gv_tkn_edi_deli_work :=  xxccp_common_pkg.get_msg(
                             iv_application  =>  cv_application,
                             iv_name         =>  cv_msg_edi_deli_work
                             );
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_application,
                   iv_name          =>  gv_msg_data_delete_err,
                   iv_token_name1   =>  cv_tkn_table_name1,
                   iv_token_name2   =>  cv_tkn_key_data,
                   iv_token_value1  =>  gv_tkn_edi_deli_work,
                   iv_token_value2  =>  iv_file_name
                   );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
    --
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END xxcos_in_edi_deli_work_delete;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_head_lock
   * Description      : EDIヘッダ情報テーブルロック(A-10)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_head_lock(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_head_lock'; -- プログラム名
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
    -- ===============================
    -- EDIヘッダ情報ＴＢＬカーソル
    -- 作成元区分＝「０３」返品確定データ
    -- 情報削除期間が過ぎたデータ
    -- (店舗納入日、センター納入日、発注日、データ作成日)
    -- ===============================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    CURSOR headers_lock_cur( lv_param1 IN CHAR )
    CURSOR headers_lock_cur
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD End    ******************************************
    IS
      SELECT head.edi_header_info_id
      FROM   xxcos_edi_headers  head
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      WHERE  head.data_type_code = lv_param1
      WHERE  head.data_type_code IN ( cv_data_type_32, cv_data_type_33 )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
        AND  NVL(head.shop_delivery_date,
             NVL(head.center_delivery_date,
             NVL(head.order_date, TRUNC(head.data_creation_date_edi_data))))
-- ************** 2009/07/22 N.Maeda MOD START ****************** --
          <= gd_edi_del_consider_date
--          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date))
-- ************** 2009/07/22 N.Maeda MOD  END  ****************** --
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    -- テーブルロック(EDIヘッダ情報ＴＢＬカーソル)
    --==============================================================
    --カーソルオープン(ロックのチェック)
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    OPEN  headers_lock_cur( gv_run_data_type_code );
    OPEN  headers_lock_cur;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    --カーソルクローズ
    CLOSE headers_lock_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      gv_tkn_edi_headers :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_edi_headers
                         );
      ov_errmsg          :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  gv_msg_lock,
                         iv_token_name1        =>  cv_tkn_table_name,
                         iv_token_value1       =>  gv_tkn_edi_headers
                         );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      IF  ( headers_lock_cur%ISOPEN ) THEN
        CLOSE headers_lock_cur;
      END IF;
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
  END xxcos_in_edi_head_lock;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_line_lock
   * Description      : EDI明細情報テーブルロック(A-10)(2)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_line_lock(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_line_lock'; -- プログラム名
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
    lt_edi_header_info_id  xxcos_edi_headers.edi_header_info_id%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- ===============================
    -- EDIヘッダ情報ＴＢＬカーソル
    -- 作成元区分＝「０３」返品確定データ
    -- 情報削除期間が過ぎたデータ
    -- (店舗納入日、センター納入日、発注日、データ作成日)
    -- ===============================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    CURSOR headers_cur( lv_param1 IN CHAR )
    CURSOR headers_cur
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    IS
      SELECT head.edi_header_info_id
      FROM   xxcos_edi_headers  head
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      WHERE  head.data_type_code  = lv_param1
      WHERE  head.data_type_code  IN ( cv_data_type_32, cv_data_type_33 )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
        AND  NVL(head.shop_delivery_date,
             NVL(head.center_delivery_date,
             NVL(head.order_date, TRUNC(head.data_creation_date_edi_data))))
-- ************** 2009/07/22 N.Maeda MOD START ****************** --
          <= gd_edi_del_consider_date;
--          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date));
-- ************** 2009/07/22 N.Maeda MOD  END  ****************** --
    -- ===============================
    -- EDI明細情報ＴＢＬカーソル
    -- EDIヘッダ情報ＴＢＬのEDIヘッダID
    -- (店舗納入日、センター納入日、発注日、データ作成日)
    -- ===============================
    CURSOR lines_lock_cur(ln_param1 IN NUMBER)
    IS
      SELECT line.edi_line_info_id
      FROM   xxcos_edi_lines    line
      WHERE  line.edi_header_info_id = ln_param1
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
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    -- EDIヘッダ情報ＴＢＬカーソル検索
    --==============================================================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    OPEN headers_cur( gv_run_data_type_code );
    OPEN headers_cur;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    <<header_loop>>
    LOOP
      FETCH headers_cur INTO lt_edi_header_info_id;
      EXIT WHEN headers_cur%NOTFOUND;
      --==============================================================
      -- テーブルロック(EDI明細情報ＴＢＬカーソル)
      --==============================================================
      --カーソルオープン(ロックチェック)
      OPEN lines_lock_cur( lt_edi_header_info_id );
      --カーソルクローズ
      CLOSE lines_lock_cur;
    END LOOP header_loop;
    CLOSE headers_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      gv_tkn_edi_lines    :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  cv_msg_edi_lines
                          );
      ov_errmsg           :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  gv_msg_lock,
                          iv_token_name1        =>  cv_tkn_table_name,
                          iv_token_value1       =>  gv_tkn_edi_lines
                          );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      IF  ( headers_cur%ISOPEN ) THEN
        CLOSE headers_cur;
      END IF;
      IF  ( lines_lock_cur%ISOPEN ) THEN
        CLOSE lines_lock_cur;
      END IF;
----#################################  固定例外処理部 START   ####################################
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
  END xxcos_in_edi_line_lock;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_head_delete
   * Description      : EDIヘッダ情報テーブルデータ削除(A-10)(3)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_head_delete(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_head_delete'; -- プログラム名
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
    BEGIN
--
      --==============================================================
      -- EDIヘッダ情報ＴＢＬ削除 (店舗納入日、センター納入日、発注日、データ作成日)
      --==============================================================
      DELETE FROM   xxcos_edi_headers  head
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      WHERE  head.data_type_code  = gv_run_data_type_code
      WHERE  head.data_type_code  IN ( cv_data_type_32, cv_data_type_33 )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
        AND  NVL(head.shop_delivery_date,
             NVL(head.center_delivery_date,
             NVL(head.order_date, TRUNC(head.data_creation_date_edi_data))))
-- ************** 2009/07/22 N.Maeda MOD START ****************** --
          <= gd_edi_del_consider_date;
--          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date));
-- ************** 2009/07/22 N.Maeda MOD  END  ****************** --
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn_edi_headers :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_edi_headers
                           );
        lv_errmsg          :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_data_delete_err,
                           iv_token_name1        =>  cv_tkn_table_name1,
                           iv_token_name2        =>  cv_tkn_key_data,
                           iv_token_value1       =>  gv_tkn_edi_headers,
                           iv_token_value2       =>  NULL
                           );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END xxcos_in_edi_head_delete;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_line_delete
   * Description      : EDI明細情報テーブルデータ削除(A-10)(4)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_line_delete(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_line_delete'; -- プログラム名
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
    lt_edi_header_info_id  xxcos_edi_headers.edi_header_info_id%TYPE;
--
    -- *** ローカル・カーソル ***
    -- ===============================
    -- EDIヘッダ情報ＴＢＬカーソル
    -- 作成元区分＝「０３」返品確定データ
    -- 情報削除期間が過ぎたデータ
    -- (店舗納入日、センター納入日、発注日、データ作成日)
    -- ===============================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    CURSOR headers_lock_cur(lv_param1 IN NUMBER)
    CURSOR headers_lock_cur
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    IS
      SELECT head.edi_header_info_id
      FROM   xxcos_edi_headers  head
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      WHERE  head.data_type_code  = lv_param1
      WHERE  head.data_type_code  IN ( cv_data_type_32, cv_data_type_33 )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
        AND  NVL(head.shop_delivery_date,
             NVL(head.center_delivery_date,
             NVL(head.order_date, TRUNC(head.data_creation_date_edi_data))))
-- ************** 2009/07/22 N.Maeda MOD START ****************** --
          <= gd_edi_del_consider_date
--          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date))
-- ************** 2009/07/22 N.Maeda MOD  END  ****************** --
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
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    BEGIN
--
      --==============================================================
      -- EDIヘッダ情報ＴＢＬカーソル
      --==============================================================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      OPEN  headers_lock_cur( gv_run_data_type_code );
      OPEN  headers_lock_cur;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
      <<header_loop>>
      LOOP
        FETCH headers_lock_cur INTO lt_edi_header_info_id;
        EXIT WHEN headers_lock_cur%NOTFOUND;
        --==============================================================
        -- EDI明細情報ＴＢＬ削除 (店舗納入日、センター納入日、発注日、データ作成日)
        --==============================================================
        DELETE  FROM   xxcos_edi_lines    line
        WHERE  line.edi_header_info_id  =  lt_edi_header_info_id;
--
      END LOOP header_loop;
      CLOSE headers_lock_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn_edi_lines :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_edi_lines
                         );
        lv_errmsg        :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  gv_msg_data_delete_err,
                         iv_token_name1        =>  cv_tkn_table_name1,
                         iv_token_name2        =>  cv_tkn_key_data,
                         iv_token_value1       =>  gv_tkn_edi_lines,
                         iv_token_value2       =>  NULL
                         );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END xxcos_in_edi_line_delete;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_head_line_delete
   * Description      : EDIヘッダ情報テーブル、EDI明細情報テーブルデータ削除(A-10)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_head_line_delete(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_head_line_delete'; -- プログラム名
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
--
-- ************** 2009/07/22 N.Maeda ADD START ****************** --
   -- EDI情報削除期間考慮日付作成
   gd_edi_del_consider_date :=
     TO_DATE( ( TO_CHAR( TRUNC( cd_creation_date - TO_NUMBER( gv_prf_edi_del_date ) ) 
     , cv_format_yyyymmdd ) || cv_space || cv_time ) ,cv_date_time );
-- ************** 2009/07/22 N.Maeda ADD  END  ****************** --
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    -- テーブルロック(EDIヘッダ情報ＴＢＬカーソル)
    --==============================================================
    xxcos_in_edi_head_lock(
       lv_errbuf,          -- エラー・メッセージ           --# 固定 #
       lv_retcode,         -- リターン・コード             --# 固定 #
       lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --==============================================================
    -- テーブルロック(EDI明細情報ＴＢＬカーソル)
    --==============================================================
    xxcos_in_edi_line_lock(
       lv_errbuf,          -- エラー・メッセージ           --# 固定 #
       lv_retcode,         -- リターン・コード             --# 固定 #
       lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- * Procedure Name   : xxcos_in_edi_line_delete
    -- * Description      : EDI明細情報テーブルデータ削除(A-10)(3)
    --==============================================================
    xxcos_in_edi_line_delete(
       lv_errbuf,          -- エラー・メッセージ           --# 固定 #
       lv_retcode,         -- リターン・コード             --# 固定 #
       lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- * Procedure Name   : xxcos_in_edi_head_delete
    -- * Description      : EDIヘッダ情報テーブルデータ削除(A-10)(3)
    --==============================================================
    xxcos_in_edi_head_delete(
       lv_errbuf,          -- エラー・メッセージ           --# 固定 #
       lv_retcode,         -- リターン・コード             --# 固定 #
       lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END xxcos_in_edi_head_line_delete;
--
--
  /**********************************************************************************
   * Procedure Name   : sel_in_edi_delivery_work
   * Description      : EDI納品返品情報ワークテーブルデータ抽出 (A-2)
   *                  :  SQL-LOADERによってEDI納品返品情報ワークテーブルに取り込まれたレコードを
   *                     抽出します。同時にレコードロックを行います。
   ***********************************************************************************/
  PROCEDURE sel_in_edi_delivery_work(
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN VARCHAR2,     --   実行区分：「新規」「再実行」
    iv_edi_chain_code IN VARCHAR2,     --   EDIチェーン店コード
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sel_in_edi_delivery_work'; -- プログラム名
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
    lv_cur_param1 VARCHAR2(100) DEFAULT NULL;    -- 抽出カーソル用引渡しパラメタ１
    lv_cur_param2 VARCHAR2(100) DEFAULT NULL;    -- 抽出カーソル用引渡しパラメタ２
    lv_cur_param3 VARCHAR2(100) DEFAULT NULL;    -- 抽出カーソル用引渡しパラメタ３
    lv_cur_param4 VARCHAR2(255) DEFAULT NULL;    -- 抽出カーソル用引渡しパラメタ４
    ln_no         NUMBER        DEFAULT 0;       -- ループカウンター
--
    -- *** ローカル・カーソル ***
    --* -------------------------------------------------------------------------------------------
    -- EDI納品返品情報ワークテーブルデータ抽出
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    CURSOR get_edideli_work_data_cur( lv_cur_param1 CHAR, lv_cur_param2 CHAR, lv_cur_param3 CHAR, lv_cur_param4 CHAR )
    CURSOR get_edideli_work_data_cur( lv_cur_param1 CHAR, lv_cur_param3 CHAR, lv_cur_param4 CHAR )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    IS
    SELECT
      edideliwk.delivery_return_work_id       delivery_return_work_id,     -- 納品返品ワークID
      edideliwk.medium_class                  medium_class,                -- 媒体区分
      edideliwk.data_type_code                data_type_code,              -- データ種コード
      edideliwk.file_no                       file_no,                     -- ファイルNO
      edideliwk.info_class                    info_class,                  -- 情報区分
      edideliwk.process_date                  process_date,                -- 処理日
      edideliwk.process_time                  process_time,                -- 処理時刻
      edideliwk.base_code                     base_code,                   -- 拠点（部門）コード
      edideliwk.base_name                     base_name,                   -- 拠点名（正式名）
      edideliwk.base_name_alt                 base_name_alt,               -- 拠点名（カナ）
      edideliwk.edi_chain_code                edi_chain_code,              -- EDIチェーン店コード
      edideliwk.edi_chain_name                edi_chain_name,              -- EDIチェーン店名（漢字）
      edideliwk.edi_chain_name_alt            edi_chain_name_alt,          -- EDIチェーン店名（カナ）
      edideliwk.chain_code                    chain_code,                  -- チェーン店コード
      edideliwk.chain_name                    chain_name,                  -- チェーン店名（漢字）
      edideliwk.chain_name_alt                chain_name_alt,              -- チェーン店名（カナ）
      edideliwk.report_code                   report_code,                 -- 帳票コード
      edideliwk.report_show_name              report_show_name,            -- 帳票表示名
      edideliwk.customer_code                 customer_code,               -- 顧客コード
      edideliwk.customer_name                 customer_name,               -- 顧客名（漢字）
      edideliwk.customer_name_alt             customer_name_alt,           -- 顧客名（カナ）
      edideliwk.company_code                  company_code,                -- 社コード
      edideliwk.company_name                  company_name,                -- 社名（漢字）
      edideliwk.company_name_alt              company_name_alt,            -- 社名（カナ）
      edideliwk.shop_code                     shop_code,                   -- 店コード
      edideliwk.shop_name                     shop_name,                   -- 店名（漢字）
      edideliwk.shop_name_alt                 shop_name_alt,               -- 店名（カナ）
      edideliwk.delivery_center_code          delivery_center_code,        -- 納入センターコード
      edideliwk.delivery_center_name          delivery_center_name,        -- 納入センター名（漢字）
      edideliwk.delivery_center_name_alt      delivery_center_name_alt,    -- 納入センター名（カナ）
      edideliwk.order_date                    order_date,                  -- 発注日
      edideliwk.center_delivery_date          center_delivery_date,        -- センター納品日
      edideliwk.result_delivery_date          result_delivery_date,        -- 実納品日
      edideliwk.shop_delivery_date            shop_delivery_date,          -- 店舗納品日
      edideliwk.data_creation_date_edi_data   data_creation_date_edi_data, -- データ作成日（EDIデータ中）
      edideliwk.data_creation_time_edi_data   data_creation_time_edi_data, -- データ作成時刻（EDIデータ中）
      edideliwk.invoice_class                 invoice_class,               -- 伝票区分
      edideliwk.small_classification_code     small_classification_code,   -- 小分類コード
      edideliwk.small_classification_name     small_classification_name,   -- 小分類名
      edideliwk.middle_classification_code    middle_classification_code,  -- 中分類コード
      edideliwk.middle_classification_name    middle_classification_name,  -- 中分類名
      edideliwk.big_classification_code       big_classification_code,     -- 大分類コード
      edideliwk.big_classification_name       big_classification_name,     -- 大分類名
      edideliwk.other_party_department_code   other_party_department_code, -- 相手先部門コード
      edideliwk.other_party_order_number      other_party_order_number,    -- 相手先発注番号
      edideliwk.check_digit_class             check_digit_class,           -- チェックデジット有無区分
      edideliwk.invoice_number                invoice_number,              -- 伝票番号
      edideliwk.check_digit                   check_digit,                 -- チェックデジット
      edideliwk.close_date                    close_date,                  -- 月限
      edideliwk.order_no_ebs                  order_no_ebs,                -- 受注NO（EBS）
      edideliwk.ar_sale_class                 ar_sale_class,               -- 特売区分
      edideliwk.delivery_classe               delivery_classe,             -- 配送区分
      edideliwk.opportunity_no                opportunity_no,              -- 便NO
      edideliwk.contact_to                    contact_to,                  -- 連絡先
      edideliwk.route_sales                   route_sales,                 -- ルートセールス
      edideliwk.corporate_code                corporate_code,              -- 法人コード
      edideliwk.maker_name                    maker_name,                  -- メーカー名
      edideliwk.area_code                     area_code,                   -- 地区コード
      edideliwk.area_name                     area_name,                   -- 地区名（漢字）
      edideliwk.area_name_alt                 area_name_alt,               -- 地区名（カナ）
      edideliwk.vendor_code                   vendor_code,                 -- 取引先コード
      edideliwk.vendor_name                   vendor_name,                 -- 取引先名（漢字）
      edideliwk.vendor_name1_alt              vendor_name1_alt,            -- 取引先名１（カナ）
      edideliwk.vendor_name2_alt              vendor_name2_alt,            -- 取引先名２（カナ）
      edideliwk.vendor_tel                    vendor_tel,                  -- 取引先TEL
      edideliwk.vendor_charge                 vendor_charge,               -- 取引先担当者
      edideliwk.vendor_address                vendor_address,              -- 取引先住所（漢字）
      edideliwk.deliver_to_code_itouen        deliver_to_code_itouen,      -- 届け先コード（伊藤園）
      edideliwk.deliver_to_code_chain         deliver_to_code_chain,       -- 届け先コード（チェーン店）
      edideliwk.deliver_to                    deliver_to,                  -- 届け先（漢字）
      edideliwk.deliver_to1_alt               deliver_to1_alt,             -- 届け先１（カナ）
      edideliwk.deliver_to2_alt               deliver_to2_alt,             -- 届け先２（カナ）
      edideliwk.deliver_to_address            deliver_to_address,          -- 届け先住所（漢字）
      edideliwk.deliver_to_address_alt        deliver_to_address_alt,      -- 届け先住所（カナ）
      edideliwk.deliver_to_tel                deliver_to_tel,              -- 届け先TEL
      edideliwk.balance_accounts_code         balance_accounts_code,       -- 帳合先コード
      edideliwk.balance_accounts_company_code balance_accounts_company_code, -- 帳合先社コード
      edideliwk.balance_accounts_shop_code    balance_accounts_shop_code,  -- 帳合先店コード
      edideliwk.balance_accounts_name         balance_accounts_name,       -- 帳合先名（漢字）
      edideliwk.balance_accounts_name_alt     balance_accounts_name_alt,   -- 帳合先名（カナ）
      edideliwk.balance_accounts_address      balance_accounts_address,    -- 帳合先住所（漢字）
      edideliwk.balance_accounts_address_alt  balance_accounts_address_alt,-- 帳合先住所（カナ）
      edideliwk.balance_accounts_tel          balance_accounts_tel,        -- 帳合先TEL
      edideliwk.order_possible_date           order_possible_date,         -- 受注可能日
      edideliwk.permission_possible_date      permission_possible_date,    -- 許容可能日
      edideliwk.forward_month                 forward_month,               -- 先限年月日
      edideliwk.payment_settlement_date       payment_settlement_date,     -- 支払決済日
      edideliwk.handbill_start_date_active    handbill_start_date_active,  -- チラシ開始日
      edideliwk.billing_due_date              billing_due_date,            -- 請求締日
      edideliwk.shipping_time                 shipping_time,               -- 出荷時刻
      edideliwk.delivery_schedule_time        delivery_schedule_time,      -- 納品予定時間
      edideliwk.order_time                    order_time,                  -- 発注時間
      edideliwk.general_date_item1            general_date_item1,          -- 汎用日付項目１
      edideliwk.general_date_item2            general_date_item2,          -- 汎用日付項目２
      edideliwk.general_date_item3            general_date_item3,          -- 汎用日付項目３
      edideliwk.general_date_item4            general_date_item4,          -- 汎用日付項目４
      edideliwk.general_date_item5            general_date_item5,          -- 汎用日付項目５
      edideliwk.arrival_shipping_class        arrival_shipping_class,      -- 入出荷区分
      edideliwk.vendor_class                  vendor_class,                -- 取引先区分
      edideliwk.invoice_detailed_class        invoice_detailed_class,      -- 伝票内訳区分
      edideliwk.unit_price_use_class          unit_price_use_class,        -- 単価使用区分
      edideliwk.sub_distribution_center_code  sub_distribution_center_code,-- サブ物流センターコード
      edideliwk.sub_distribution_center_name  sub_distribution_center_name,-- サブ物流センターコード名
      edideliwk.center_delivery_method        center_delivery_method,      -- センター納品方法
      edideliwk.center_use_class              center_use_class,            -- センター利用区分
      edideliwk.center_whse_class             center_whse_class,           -- センター倉庫区分
      edideliwk.center_area_class             center_area_class,           -- センター地域区分
      edideliwk.center_arrival_class          center_arrival_class,        -- センター入荷区分
      edideliwk.depot_class                   depot_class,                 -- デポ区分
      edideliwk.tcdc_class                    tcdc_class,                  -- TCDC区分
      edideliwk.upc_flag                      upc_flag,                    -- UPCフラグ
      edideliwk.simultaneously_class          simultaneously_class,        -- 一斉区分
      edideliwk.business_id                   business_id,                 -- 業務ID
      edideliwk.whse_directly_class           whse_directly_class,         -- 倉直区分
      edideliwk.premium_rebate_class          premium_rebate_class,        -- 景品割戻区分
      edideliwk.item_type                     item_type,                   -- 項目種別
      edideliwk.cloth_house_food_class        cloth_house_food_class,      -- 衣家食区分
      edideliwk.mix_class                     mix_class,                   -- 混在区分
      edideliwk.stk_class                     stk_class,                   -- 在庫区分
      edideliwk.last_modify_site_class        last_modify_site_class,      -- 最終修正場所区分
      edideliwk.report_class                  report_class,                -- 帳票区分
      edideliwk.addition_plan_class           addition_plan_class,         -- 追加・計画区分
      edideliwk.registration_class            registration_class,          -- 登録区分
      edideliwk.specific_class                specific_class,              -- 特定区分
      edideliwk.dealings_class                dealings_class,              -- 取引区分
      edideliwk.order_class                   order_class,                 -- 発注区分
      edideliwk.sum_line_class                sum_line_class,              -- 集計明細区分
      edideliwk.shipping_guidance_class       shipping_guidance_class,     -- 出荷案内以外区分
      edideliwk.shipping_class                shipping_class,              -- 出荷区分
      edideliwk.product_code_use_class        product_code_use_class,      -- 商品コード使用区分
      edideliwk.cargo_item_class              cargo_item_class,            -- 積送品区分
      edideliwk.ta_class                      ta_class,                    -- T/A区分
      edideliwk.plan_code                     plan_code,                   -- 企画コード
      edideliwk.category_code                 category_code,               -- カテゴリーコード
      edideliwk.category_class                category_class,              -- カテゴリー区分
      edideliwk.carrier_means                 carrier_means,               -- 運送手段
      edideliwk.counter_code                  counter_code,                -- 売場コード
      edideliwk.move_sign                     move_sign,                   -- 移動サイン
      edideliwk.eos_handwriting_class         eos_handwriting_class,       -- EOS・手書区分
      edideliwk.delivery_to_section_code      delivery_to_section_code,    -- 納品先課コード
      edideliwk.invoice_detailed              invoice_detailed,            -- 伝票内訳
      edideliwk.attach_qty                    attach_qty,                  -- 添付数
      edideliwk.other_party_floor             other_party_floor,           -- フロア
      edideliwk.text_no                       text_no,                     -- TEXT_NO
      edideliwk.in_store_code                 in_store_code,               -- インストアコード
      edideliwk.tag_data                      tag_data,                    -- タグ
      edideliwk.competition_code              competition_code,            -- 競合
      edideliwk.billing_chair                 billing_chair,               -- 請求口座
      edideliwk.chain_store_code              chain_store_code,            -- チェーンストアーコード
      edideliwk.chain_store_short_name        chain_store_short_name,      -- チェーンストアーコード略式名称
      edideliwk.direct_delivery_rcpt_fee      direct_delivery_rcpt_fee,    -- 直配送／引取料
      edideliwk.bill_info                     bill_info,                   -- 手形情報
      edideliwk.description                   description,                 -- 摘要
      edideliwk.interior_code                 interior_code,               -- 内部コード
      edideliwk.order_info_delivery_category  order_info_delivery_category,-- 発注情報　納品カテゴリー
      edideliwk.purchase_type                 purchase_type,               -- 仕入形態
      edideliwk.delivery_to_name_alt          delivery_to_name_alt,        -- 納品場所名（カナ）
      edideliwk.shop_opened_site              shop_opened_site,            -- 店出場所
      edideliwk.counter_name                  counter_name,                -- 売場名
      edideliwk.extension_number              extension_number,            -- 内線番号
      edideliwk.charge_name                   charge_name,                 -- 担当者名
      edideliwk.price_tag                     price_tag,                   -- 値札
      edideliwk.tax_type                      tax_type,                    -- 税種
      edideliwk.consumption_tax_class         consumption_tax_class,       -- 消費税区分
      edideliwk.brand_class                   brand_class,                 -- BR
      edideliwk.id_code                       id_code,                     -- IDコード
      edideliwk.department_code               department_code,             -- 百貨店コード
      edideliwk.department_name               department_name,             -- 百貨店名
      edideliwk.item_type_number              item_type_number,            -- 品別番号
      edideliwk.description_department        description_department,      -- 摘要（百貨店）
      edideliwk.price_tag_method              price_tag_method,            -- 値札方法
      edideliwk.reason_column                 reason_column,               -- 自由欄
      edideliwk.a_column_header               a_column_header,             -- A欄ヘッダ
      edideliwk.d_column_header               d_column_header,             -- D欄ヘッダ
      edideliwk.brand_code                    brand_code,                  -- ブランドコード
      edideliwk.line_code                     line_code,                   -- ラインコード
      edideliwk.class_code                    class_code,                  -- クラスコード
      edideliwk.a1_column                     a1_column,                   -- Ａ－１欄
      edideliwk.b1_column                     b1_column,                   -- Ｂ－１欄
      edideliwk.c1_column                     c1_column,                   -- Ｃ－１欄
      edideliwk.d1_column                     d1_column,                   -- Ｄ－１欄
      edideliwk.e1_column                     e1_column,                   -- Ｅ－１欄
      edideliwk.a2_column                     a2_column,                   -- Ａ－２欄
      edideliwk.b2_column                     b2_column,                   -- Ｂ－２欄
      edideliwk.c2_column                     c2_column,                   -- Ｃ－２欄
      edideliwk.d2_column                     d2_column,                   -- Ｄ－２欄
      edideliwk.e2_column                     e2_column,                   -- Ｅ－２欄
      edideliwk.a3_column                     a3_column,                   -- Ａ－３欄
      edideliwk.b3_column                     b3_column,                   -- Ｂ－３欄
      edideliwk.c3_column                     c3_column,                   -- Ｃ－３欄
      edideliwk.d3_column                     d3_column,                   -- Ｄ－３欄
      edideliwk.e3_column                     e3_column,                   -- Ｅ－３欄
      edideliwk.f1_column                     f1_column,                   -- Ｆ－１欄
      edideliwk.g1_column                     g1_column,                   -- Ｇ－１欄
      edideliwk.h1_column                     h1_column,                   -- Ｈ－１欄
      edideliwk.i1_column                     i1_column,                   -- Ｉ－１欄
      edideliwk.j1_column                     j1_column,                   -- Ｊ－１欄
      edideliwk.k1_column                     k1_column,                   -- Ｋ－１欄
      edideliwk.l1_column                     l1_column,                   -- Ｌ－１欄
      edideliwk.f2_column                     f2_column,                   -- Ｆ－２欄
      edideliwk.g2_column                     g2_column,                   -- Ｇ－２欄
      edideliwk.h2_column                     h2_column,                   -- Ｈ－２欄
      edideliwk.i2_column                     i2_column,                   -- Ｉ－２欄
      edideliwk.j2_column                     j2_column,                   -- Ｊ－２欄
      edideliwk.k2_column                     k2_column,                   -- Ｋ－２欄
      edideliwk.l2_column                     l2_column,                   -- Ｌ－２欄
      edideliwk.f3_column                     f3_column,                   -- Ｆ－３欄
      edideliwk.g3_column                     g3_column,                   -- Ｇ－３欄
      edideliwk.h3_column                     h3_column,                   -- Ｈ－３欄
      edideliwk.i3_column                     i3_column,                   -- Ｉ－３欄
      edideliwk.j3_column                     j3_column,                   -- Ｊ－３欄
      edideliwk.k3_column                     k3_column,                   -- Ｋ－３欄
      edideliwk.l3_column                     l3_column,                   -- Ｌ－３欄
      edideliwk.chain_peculiar_area_header    chain_peculiar_area_header,  -- チェーン店固有エリア（ヘッダー）
      edideliwk.order_connection_number       order_connection_number,     -- 受注関連番号（仮）
      edideliwk.line_no                       line_no,                     -- 行ｎｏ
      edideliwk.stockout_class                stockout_class,              -- 欠品区分
      edideliwk.stockout_reason               stockout_reason,             -- 欠品理由
      edideliwk.product_code_itouen           product_code_itouen,         -- 商品コード（伊藤園）
      edideliwk.product_code1                 product_code1,               -- 商品コード１
      edideliwk.product_code2                 product_code2,               -- 商品コード２
      edideliwk.jan_code                      jan_code,                    -- JANコード
      edideliwk.itf_code                      itf_code,                    -- ITFコード
      edideliwk.extension_itf_code            extension_itf_code,          -- 内箱ITFコード
      edideliwk.case_product_code             case_product_code,           -- ケース商品コード
      edideliwk.ball_product_code             ball_product_code,           -- ボール商品コード
      edideliwk.product_code_item_type        product_code_item_type,      -- 商品コード品種
      edideliwk.prod_class                    prod_class,                  -- 商品区分
      edideliwk.product_name                  product_name,                -- 商品名（漢字）
      edideliwk.product_name1_alt             product_name1_alt,           -- 商品名１（カナ）
      edideliwk.product_name2_alt             product_name2_alt,           -- 商品名２（カナ）
      edideliwk.item_standard1                item_standard1,              -- 規格１
      edideliwk.item_standard2                item_standard2,              -- 規格２
      edideliwk.qty_in_case                   qty_in_case,                 -- 入数
      edideliwk.num_of_cases                  num_of_cases,                -- ケース入数
      edideliwk.num_of_ball                   num_of_ball,                 -- ボール入数
      edideliwk.item_color                    item_color,                  -- 色
      edideliwk.item_size                     item_size,                   -- サイズ
      edideliwk.expiration_date               expiration_date,             -- 賞味期限日
      edideliwk.product_date                  product_date,                -- 製造日
      edideliwk.order_uom_qty                 order_uom_qty,               -- 発注単位数
      edideliwk.shipping_uom_qty              shipping_uom_qty,            -- 出荷単位数
      edideliwk.packing_uom_qty               packing_uom_qty,             -- 梱包単位数
      edideliwk.deal_code                     deal_code,                   -- 引合
      edideliwk.deal_class                    deal_class,                  -- 引合区分
      edideliwk.collation_code                collation_code,              -- 照合
      edideliwk.uom_code                      uom_code,                    -- 単位
      edideliwk.unit_price_class              unit_price_class,            -- 単価区分
      edideliwk.parent_packing_number         parent_packing_number,       -- 親梱包番号
      edideliwk.packing_number                packing_number,              -- 梱包番号
      edideliwk.product_group_code            product_group_code,          -- 商品群コード
      edideliwk.case_dismantle_flag           case_dismantle_flag,         -- ケース解体不可フラグ
      edideliwk.case_class                    case_class,                  -- ケース区分
      edideliwk.indv_order_qty                indv_order_qty,              -- 発注数量（バラ）
      edideliwk.case_order_qty                case_order_qty,              -- 発注数量（ケース）
      edideliwk.ball_order_qty                ball_order_qty,              -- 発注数量（ボール）
      edideliwk.sum_order_qty                 sum_order_qty,               -- 発注数量（合計、バラ）
      edideliwk.indv_shipping_qty             indv_shipping_qty,           -- 出荷数量（バラ）
      edideliwk.case_shipping_qty             case_shipping_qty,           -- 出荷数量（ケース）
      edideliwk.ball_shipping_qty             ball_shipping_qty,           -- 出荷数量（ボール）
      edideliwk.pallet_shipping_qty           pallet_shipping_qty,         -- 出荷数量（パレット）
      edideliwk.sum_shipping_qty              sum_shipping_qty,            -- 出荷数量（合計、バラ）
      edideliwk.indv_stockout_qty             indv_stockout_qty,           -- 欠品数量（バラ）
      edideliwk.case_stockout_qty             case_stockout_qty,           -- 欠品数量（ケース）
      edideliwk.ball_stockout_qty             ball_stockout_qty,           -- 欠品数量（ボール）
      edideliwk.sum_stockout_qty              sum_stockout_qty,            -- 欠品数量（合計、バラ）
      edideliwk.case_qty                      case_qty,                    -- ケース個口数
      edideliwk.fold_container_indv_qty       fold_container_indv_qty,     -- オリコン（バラ）個口数
      edideliwk.order_unit_price              order_unit_price,            -- 原単価（発注）
      edideliwk.shipping_unit_price           shipping_unit_price,         -- 原単価（出荷）
      edideliwk.order_cost_amt                order_cost_amt,              -- 原価金額（発注）
-- ***************************** 2009/07/21 1.5 N.Maeda    MOD  START ***************************** --
      TRUNC( edideliwk.shipping_cost_amt )    shipping_cost_amt,           -- 原価金額（出荷）
      TRUNC( edideliwk.stockout_cost_amt )    stockout_cost_amt,           -- 原価金額（欠品）
--      edideliwk.shipping_cost_amt             shipping_cost_amt,           -- 原価金額（出荷）
--      edideliwk.stockout_cost_amt             stockout_cost_amt,           -- 原価金額（欠品）
-- ***************************** 2009/07/21 1.5 N.Maeda    MOD   END  ***************************** --
      edideliwk.selling_price                 selling_price,               -- 売単価
      edideliwk.order_price_amt               order_price_amt,             -- 売価金額（発注）
      edideliwk.shipping_price_amt            shipping_price_amt,          -- 売価金額（出荷）
      edideliwk.stockout_price_amt            stockout_price_amt,          -- 売価金額（欠品）
      edideliwk.a_column_department           a_column_department,         -- A欄（百貨店）
      edideliwk.d_column_department           d_column_department,         -- D欄（百貨店）
      edideliwk.standard_info_depth           standard_info_depth,         -- 規格情報・奥行き
      edideliwk.standard_info_height          standard_info_height,        -- 規格情報・高さ
      edideliwk.standard_info_width           standard_info_width,         -- 規格情報・幅
      edideliwk.standard_info_weight          standard_info_weight,        -- 規格情報・重量
      edideliwk.general_succeeded_item1       general_succeeded_item1,     -- 汎用引継ぎ項目１
      edideliwk.general_succeeded_item2       general_succeeded_item2,     -- 汎用引継ぎ項目２
      edideliwk.general_succeeded_item3       general_succeeded_item3,     -- 汎用引継ぎ項目３
      edideliwk.general_succeeded_item4       general_succeeded_item4,     -- 汎用引継ぎ項目４
      edideliwk.general_succeeded_item5       general_succeeded_item5,     -- 汎用引継ぎ項目５
      edideliwk.general_succeeded_item6       general_succeeded_item6,     -- 汎用引継ぎ項目６
      edideliwk.general_succeeded_item7       general_succeeded_item7,     -- 汎用引継ぎ項目７
      edideliwk.general_succeeded_item8       general_succeeded_item8,     -- 汎用引継ぎ項目８
      edideliwk.general_succeeded_item9       general_succeeded_item9,     -- 汎用引継ぎ項目９
      edideliwk.general_succeeded_item10      general_succeeded_item10,    -- 汎用引継ぎ項目１０
      edideliwk.general_add_item1             general_add_item1,           -- 汎用付加項目１
      edideliwk.general_add_item2             general_add_item2,           -- 汎用付加項目２
      edideliwk.general_add_item3             general_add_item3,           -- 汎用付加項目３
      edideliwk.general_add_item4             general_add_item4,           -- 汎用付加項目４
      edideliwk.general_add_item5             general_add_item5,           -- 汎用付加項目５
      edideliwk.general_add_item6             general_add_item6,           -- 汎用付加項目６
      edideliwk.general_add_item7             general_add_item7,           -- 汎用付加項目７
      edideliwk.general_add_item8             general_add_item8,           -- 汎用付加項目８
      edideliwk.general_add_item9             general_add_item9,           -- 汎用付加項目９
      edideliwk.general_add_item10            general_add_item10,          -- 汎用付加項目１０
      edideliwk.chain_peculiar_area_line      chain_peculiar_area_line,    -- チェーン店固有エリア（明細）
      edideliwk.invoice_indv_order_qty        invoice_indv_order_qty,      -- (伝票計）発注数量（バラ）
      edideliwk.invoice_case_order_qty        invoice_case_order_qty,      -- (伝票計）発注数量（ケース）
      edideliwk.invoice_ball_order_qty        invoice_ball_order_qty,      -- (伝票計）発注数量（ボール）
      edideliwk.invoice_sum_order_qty         invoice_sum_order_qty,       -- (伝票計）発注数量（合計、バラ）
      edideliwk.invoice_indv_shipping_qty     invoice_indv_shipping_qty,   -- (伝票計）出荷数量（バラ）
      edideliwk.invoice_case_shipping_qty     invoice_case_shipping_qty,   -- (伝票計）出荷数量（ケース）
      edideliwk.invoice_ball_shipping_qty     invoice_ball_shipping_qty,   -- (伝票計）出荷数量（ボール）
      edideliwk.invoice_pallet_shipping_qty   invoice_pallet_shipping_qty, -- (伝票計）出荷数量（パレット）
      edideliwk.invoice_sum_shipping_qty      invoice_sum_shipping_qty,    -- (伝票計）出荷数量（合計、バラ）
      edideliwk.invoice_indv_stockout_qty     invoice_indv_stockout_qty,   -- (伝票計）欠品数量（バラ）
      edideliwk.invoice_case_stockout_qty     invoice_case_stockout_qty,   -- (伝票計）欠品数量（ケース）
      edideliwk.invoice_ball_stockout_qty     invoice_ball_stockout_qty,   -- (伝票計）欠品数量（ボール）
      edideliwk.invoice_sum_stockout_qty      invoice_sum_stockout_qty,    -- (伝票計）欠品数量（合計、バラ）
      edideliwk.invoice_case_qty              invoice_case_qty,            -- (伝票計）ケース個口数
      edideliwk.invoice_fold_container_qty    invoice_fold_container_qty,  -- (伝票計）オリコン（バラ）個口数
      edideliwk.invoice_order_cost_amt        invoice_order_cost_amt,      -- (伝票計）原価金額（発注）
      edideliwk.invoice_shipping_cost_amt     invoice_shipping_cost_amt,   -- (伝票計）原価金額（出荷）
      edideliwk.invoice_stockout_cost_amt     invoice_stockout_cost_amt,   -- (伝票計）原価金額（欠品）
      edideliwk.invoice_order_price_amt       invoice_order_price_amt,     -- (伝票計）売価金額（発注）
      edideliwk.invoice_shipping_price_amt    invoice_shipping_price_amt,  -- (伝票計）売価金額（出荷）
      edideliwk.invoice_stockout_price_amt    invoice_stockout_price_amt,  -- (伝票計）売価金額（欠品）
      edideliwk.total_indv_order_qty          total_indv_order_qty,        -- (総合計）発注数量（バラ）
      edideliwk.total_case_order_qty          total_case_order_qty,        -- (総合計）発注数量（ケース）
      edideliwk.total_ball_order_qty          total_ball_order_qty,        -- (総合計）発注数量（ボール）
      edideliwk.total_sum_order_qty           total_sum_order_qty,         -- (総合計）発注数量（合計、バラ）
      edideliwk.total_indv_shipping_qty       total_indv_shipping_qty,     -- (総合計）出荷数量（バラ）
      edideliwk.total_case_shipping_qty       total_case_shipping_qty,     -- (総合計）出荷数量（ケース）
      edideliwk.total_ball_shipping_qty       total_ball_shipping_qty,     -- (総合計）出荷数量（ボール）
      edideliwk.total_pallet_shipping_qty     total_pallet_shipping_qty,   -- (総合計）出荷数量（パレット）
      edideliwk.total_sum_shipping_qty        total_sum_shipping_qty,      -- (総合計）出荷数量（合計、バラ）
      edideliwk.total_indv_stockout_qty       total_indv_stockout_qty,     -- (総合計）欠品数量（バラ）
      edideliwk.total_case_stockout_qty       total_case_stockout_qty,     -- (総合計）欠品数量（ケース）
      edideliwk.total_ball_stockout_qty       total_ball_stockout_qty,     -- (総合計）欠品数量（ボール）
      edideliwk.total_sum_stockout_qty        total_sum_stockout_qty,      -- (総合計）欠品数量（合計、バラ）
      edideliwk.total_case_qty                total_case_qty,              -- (総合計）ケース個口数
      edideliwk.total_fold_container_qty      total_fold_container_qty,    -- (総合計）オリコン（バラ）個口数
      edideliwk.total_order_cost_amt          total_order_cost_amt,        -- (総合計）原価金額（発注）
      edideliwk.total_shipping_cost_amt       total_shipping_cost_amt,     -- (総合計）原価金額（出荷）
      edideliwk.total_stockout_cost_amt       total_stockout_cost_amt,     -- (総合計）原価金額（欠品）
      edideliwk.total_order_price_amt         total_order_price_amt,       -- (総合計）売価金額（発注）
      edideliwk.total_shipping_price_amt      total_shipping_price_amt,    -- (総合計）売価金額（出荷）
      edideliwk.total_stockout_price_amt      total_stockout_price_amt,    -- (総合計）売価金額（欠品）
      edideliwk.total_line_qty                total_line_qty,              -- トータル行数
      edideliwk.total_invoice_qty             total_invoice_qty,           -- トータル伝票枚数
      edideliwk.chain_peculiar_area_footer    chain_peculiar_area_footer,  -- チェーン店固有エリア（フッター）
      edideliwk.err_status                    err_status,                  -- ステータス
/* 2011/07/26 Ver1.9 Mod Start */
--      edideliwk.if_file_name                  if_file_name                 -- インタフェースファイル名
      edideliwk.if_file_name                  if_file_name,                -- インタフェースファイル名
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
      edideliwk.bms_header_data               bms_header_data,             -- 流通ＢＭＳヘッダデータ
      edideliwk.bms_line_data                 bms_line_data                -- 流通ＢＭＳ明細データ
/* 2011/07/26 Ver1.9 Add End   */
    FROM    xxcos_edi_delivery_work    edideliwk                           -- EDI納品返品情報ワークテーブル
    WHERE   edideliwk.if_file_name     = lv_cur_param4          -- インタフェースファイル名
      AND   edideliwk.err_status       =    lv_cur_param1                  -- ステータス
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      AND   edideliwk.data_type_code   = lv_cur_param2          -- データ種コード
      AND   edideliwk.data_type_code   IN ( cv_data_type_32, cv_data_type_33 )  -- データ種コード
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
      AND (( lv_cur_param3 IS NOT NULL
        AND   edideliwk.edi_chain_code   =    lv_cur_param3 )              -- EDIチェーン店コード
        OR ( lv_cur_param3 IS NULL ))
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    ORDER BY edideliwk.invoice_number,edideliwk.line_no                    -- ソート条件（伝票番号、行NO）
    ORDER BY edideliwk.shop_code,                                          -- ソート条件（店コード）
             edideliwk.invoice_number,                                     -- ソート条件（伝票番号）
             edideliwk.line_no                                             -- ソート条件（行NO）
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    FOR UPDATE OF
            edideliwk.delivery_return_work_id NOWAIT;
    -- *** ローカル・レコード ***
--
  --* -------------------------------------------------------------------------------------------
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
    --==============================================================
    -- 実行区分のチェック
    --==============================================================
    --
    IF  ( iv_run_class  =  gv_run_class_name1 )  THEN     -- 実行区分：「新規」
      lv_cur_param1 := gv_run_class_name1;       -- 抽出カーソル用引渡しパラメタ１
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL START  ******************************************
--      lv_cur_param2 := gv_run_data_type_code;    -- 抽出カーソル用引渡しパラメタ２
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL END    ******************************************
    ELSIF  ( iv_run_class  =  gv_run_class_name2 )  THEN   -- 実行区分：「再実施」
      lv_cur_param1 := gv_run_class_name2;       -- 抽出カーソル用引渡しパラメタ１
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL START  ******************************************
--      lv_cur_param2 := gv_run_data_type_code;    -- 抽出カーソル用引渡しパラメタ２
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL END    ******************************************
    END IF;
    --
    lv_cur_param3 := iv_edi_chain_code;          -- 抽出カーソル用引渡しパラメタ３
    lv_cur_param4 := iv_file_name;               -- 抽出カーソル用引渡しパラメタ４
--
    --==============================================================
    -- EDI納品返品情報ワークテーブルデータ取得
    --==============================================================
    BEGIN
      -- カーソルOPEN
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      OPEN  get_edideli_work_data_cur( lv_cur_param1, lv_cur_param2, lv_cur_param3, lv_cur_param4 );
      OPEN  get_edideli_work_data_cur( lv_cur_param1, lv_cur_param3, lv_cur_param4 );
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
      --
      -- バルクフェッチ
      FETCH get_edideli_work_data_cur BULK COLLECT INTO gt_edideli_work_data;
      -- 抽出件数セット
      gn_target_cnt := get_edideli_work_data_cur%ROWCOUNT;
--****************************** 2009/06/04 1.4 T.Kitajima DEL START ******************************--
--      -- 正常件数 = 抽出件数
--      gn_normal_cnt := gn_target_cnt;
--****************************** 2009/06/04 1.4 T.Kitajima DEL  END  ******************************--
      --
      -- カーソルCLOSE
      CLOSE get_edideli_work_data_cur;
    EXCEPTION
      -- ロックエラー
      WHEN lock_expt THEN
        IF ( get_edideli_work_data_cur%ISOPEN ) THEN
          CLOSE get_edideli_work_data_cur;
        END IF;
        -- EDI納品返品情報ワークテーブル
        gv_tkn_edi_deli_work :=  xxccp_common_pkg.get_msg(
                             iv_application        =>  cv_application,
                             iv_name               =>  cv_msg_edi_deli_work
                             );
        lv_errmsg            :=  xxccp_common_pkg.get_msg(
                             iv_application        =>  cv_application,
                             iv_name               =>  gv_msg_lock,
                             iv_token_name1        =>  cv_tkn_table_name,
                             iv_token_value1       =>  gv_tkn_edi_deli_work
                             );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
      -- その他の抽出エラー
      WHEN OTHERS THEN
        IF ( get_edideli_work_data_cur%ISOPEN ) THEN
          CLOSE get_edideli_work_data_cur;
        END IF;
        lv_errbuf  := SQLERRM;
        RAISE global_data_sel_expt;
    END;
    --
    -- 対象データ無し
    IF  ( gn_target_cnt = 0 ) THEN
      RAISE global_nodata_expt;
    END IF;
    --
    -- ループ開始：
    <<xxcos_in_edi_headers_set>>
    FOR  ln_no  IN  1..gn_target_cnt  LOOP
-- 2009/06/15 Ver.1.5 M.Sano Add Start
      gt_err_edideli_work_data(ln_no).err_status1 := cv_status_normal;
      gt_err_edideli_work_data(ln_no).err_status2 := cv_status_normal;
-- 2009/06/15 Ver.1.5 M.Sano Add End
      --==============================================================
      -- * Procedure Name   : data_check
      -- * Description      : データ妥当性チェック(A-3)
      --==============================================================
      data_check(
        ln_no,
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      --==============================================================
      -- 警告情報の場合
      --==============================================================
      IF ( lv_retcode = cv_status_warn ) THEN
        --ステータス(error1)
        IF  ( gt_err_edideli_work_data(ln_no).err_status1 = cv_status_warn ) THEN
          --==============================================================
          -- エラー出力
          --==============================================================
          FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT,
               buff   => gt_err_edideli_work_data(ln_no).errmsg1 --ユーザー・エラーメッセージ
          );
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
          gn_msg_cnt := gn_msg_cnt + 1;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
        END IF;
        --ステータス(error2)
        IF  ( gt_err_edideli_work_data(ln_no).err_status2 = cv_status_warn ) THEN
          --==============================================================
          -- エラー出力
          --==============================================================
          FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT,
               buff   => gt_err_edideli_work_data(ln_no).errmsg2 --ユーザー・エラーメッセージ
          );
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
          gn_msg_cnt := gn_msg_cnt + 1;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
        END IF;
      --
      END IF;
    --
    END LOOP  xxcos_in_edi_headers_set;
    --* -------------------------------------------------------------------------------------------
    --  必須チェック、顧客情報チェックで１件でもエラーが有った場合
    --* -------------------------------------------------------------------------------------------
    IF  ( gv_status_work_err = cv_status_error ) THEN
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_deli_wk_update
      -- * Description      : EDI納品返品情報ワークテーブルへの更新(A-6)
      -- ***********************************************************************************
      xxcos_in_edi_deli_wk_update(
        iv_file_name,    --   インタフェースファイル名
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    --* -------------------------------------------------------------------------------------------
    --  必須チェック、顧客情報チェックで１件もエラーが無かった場合
    --* -------------------------------------------------------------------------------------------
    ELSE
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_headers_insert
      -- * Description      : EDIヘッダ情報テーブルへのデータ挿入(A-7)
      -- ***********************************************************************************
      xxcos_in_edi_headers_insert(
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_lines_insert
      -- * Description      : EDI明細情報テーブルへのデータ挿入(A-8)
      -- ***********************************************************************************
      xxcos_in_edi_lines_insert(
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_deli_work_delete
      -- * Description      : EDI納品返品情報ワークテーブルデータ削除(A-9)
      -- ***********************************************************************************
      xxcos_in_edi_deli_work_delete(
        iv_file_name,       -- インタフェースファイル名
        iv_run_class,       -- 実行区分：「新規」「再実行」
        iv_edi_chain_code,  -- EDIチェーン店コード
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- 対象データなし
    WHEN global_nodata_expt THEN
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_nodata_err
                           );
      --メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --正常終了とする
      ov_retcode := cv_status_normal;
    -- データ抽出エラー
    WHEN global_data_sel_expt THEN
      -- EDI納品返品情報ワークテーブル
      gv_tkn_edi_deli_work :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_edi_deli_work
                           );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_nodata,
                           iv_token_name1        =>  cv_tkn_table_name1,
                           iv_token_name2        =>  cv_tkn_key_data,
                           iv_token_value1       =>  gv_tkn_edi_deli_work,
                           iv_token_value2       =>  iv_file_name
                           );
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
--#####################################  固定部 END   ##########################################
--
  END sel_in_edi_delivery_work;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN VARCHAR2,     --   実行区分：「新規」「再実行」
    iv_edi_chain_code IN VARCHAR2,     --   EDIチェーン店コード
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- <カーソル名>
--    CURSOR <cursor_name>_cur
--    IS
--      SELECT
--      FROM
--      WHERE
    -- <カーソル名>レコード型
--    <cursor_name>_rec <cursor_name>_cur%ROWTYPE;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
    gn_msg_cnt    := 0;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
--
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --==============================================================
    -- プログラム初期処理(A-0) (コンカレントプログラム入力項目を出力)
    --==============================================================
    -- テーブル定義名称
    -- 実行区分：「新規」
    gv_run_class_name01  :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_class_name1
                         );
    --* -------------------------------------------------------------
    --== ルックアップマスタデータ抽出
    --* -------------------------------------------------------------
    SELECT  xlvv.lookup_code        -- コード
      INTO  gv_run_class_name1
      FROM  xxcos_lookup_values_v        xlvv        -- ルックアップマスタ
     WHERE  xlvv.lookup_type  = cv_lookup_type1 -- ルックアップ.タイプ
       AND  xlvv.meaning      = gv_run_class_name01
       AND (( xlvv.start_date_active IS NULL )
       OR   ( xlvv.start_date_active <= cd_process_date ))
       AND (( xlvv.end_date_active   IS NULL )
       OR   ( xlvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
       AND  rownum = 1;
--
    -- 実行区分：「再実施」
    gv_run_class_name02  :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_class_name2
                         );
    --* -------------------------------------------------------------
    --== ルックアップマスタデータ抽出
    --* -------------------------------------------------------------
    SELECT  xlvv.lookup_code        -- コード
      INTO  gv_run_class_name2
      FROM  xxcos_lookup_values_v        xlvv        -- ルックアップマスタ
     WHERE  xlvv.lookup_type  = cv_lookup_type1 -- ルックアップ.タイプ
       AND  xlvv.meaning      = gv_run_class_name02
       AND (( xlvv.start_date_active IS NULL )
       OR   ( xlvv.start_date_active <= cd_process_date ))
       AND (( xlvv.end_date_active   IS NULL )
       OR   ( xlvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
       AND  rownum = 1;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL START  ******************************************
--    --* --------------------------------------------------------------
--    -- データ種コード：「返品確定」
--    --* --------------------------------------------------------------
--    gv_run_data_type_code :=  xxccp_common_pkg.get_msg(
--                         iv_application        =>  cv_application,
--                          iv_name               =>  cv_msg_data_type_code
--                          );
----
--    SELECT  xlvv.meaning
--      INTO  gv_run_data_type_code
--      FROM  xxcos_lookup_values_v  xlvv
--     WHERE  xlvv.lookup_type   = cv_lookup_type3 -- ルックアップ.タイプ
--       AND  xlvv.description   = gv_run_data_type_code
--       AND (( xlvv.start_date_active IS NULL )
--       OR   ( xlvv.start_date_active <= cd_process_date ))
--       AND (( xlvv.end_date_active   IS NULL )
--       OR   ( xlvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
--       ;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL END    ******************************************
--
    --==============================================================
    -- プログラム初期処理(A-0) (コンカレントプログラム入力項目を出力)
    --==============================================================
    -- インタフェースファイル名
    lv_errmsg      :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  cv_msg_in_file_name1,
                   iv_token_name1        =>  cv_param1,
                   iv_token_value1       =>  iv_file_name
                   );
    --==============================================================
    -- 入力パラメータ「 インタフェースファイル名」出力
    --==============================================================
    FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT,
           buff   => lv_errmsg --ユーザー・エラーメッセージ
    );
    FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG,
           buff   => lv_errmsg --ユーザー・エラーメッセージ
    );
    --==============================================================
    -- プログラム初期処理(A-0) (コンカレントプログラム入力項目を出力)
    --==============================================================
    IF  ( iv_run_class  =  gv_run_class_name1 )  THEN     -- 実行区分：「新規」
      lv_errmsg    :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  gv_msg_param_out_msg1,
                   iv_token_name1        =>  cv_param1,
                   iv_token_value1       =>  iv_run_class
                   );
      --==============================================================
      -- 入力パラメータ「実行区分」「EDIチェーン店コード」出力
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_errmsg
      );
      --==============================================================
    ELSIF  ( iv_run_class  =  gv_run_class_name2 )  THEN    -- 実行区分：「再実施」
      lv_errmsg    :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  gv_msg_param_out_msg2,
                   iv_token_name1        =>  cv_param1,
                   iv_token_name2        =>  cv_param2,
                   iv_token_value1       =>  iv_run_class,
                   iv_token_value2       =>  iv_edi_chain_code
                   );
      --==============================================================
      -- 入力パラメータ「実行区分」「EDIチェーン店コード」出力
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_errmsg
      );
      --==============================================================
    ELSE
      lv_errmsg    :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  gv_msg_param_out_msg2,
                   iv_token_name1        =>  cv_param1,
                   iv_token_name2        =>  cv_param2,
                   iv_token_value1       =>  iv_run_class,
                   iv_token_value2       =>  iv_edi_chain_code
                   );
      --==============================================================
      -- 入力パラメータ「実行区分」「EDIチェーン店コード」出力
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_errmsg
      );
    END IF;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => NULL
    );
    --
    --==============================================================
    -- * Procedure Name   : init
    -- * Description      : 初期処理(A-1)
    -- *                  :  入力パラメータ妥当性チェック
    --==============================================================
    init(
      iv_file_name,       -- インタフェースファイル名
      iv_run_class,       -- 実行区分：「新規」「再実行」
      iv_edi_chain_code,  -- EDIチェーン店コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- * Procedure Name   : sel_in_edi_delivery_work(A-2)
    -- * Description      : EDI納品返品情報ワークテーブルデータ抽出 (A-2)
    -- *                  :  SQL-LOADERによってEDI納品返品情報ワークテーブルに取り込まれたレコードを
    -- *                     抽出します。同時にレコードロックを行います。
    --==============================================================
    sel_in_edi_delivery_work(
      iv_file_name,       -- インタフェースファイル名
      iv_run_class,       -- 実行区分：「新規」「再実行」
      iv_edi_chain_code,  -- EDIチェーン店コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- ステータスがエラーとなるデータがない場合
    --==============================================================
    IF ( gv_status_work_err <> cv_status_error ) THEN
      --==============================================================
      -- * Procedure Name   : xxcos_in_edi_head_line_delete
      -- * Description      : EDIヘッダ情報テーブル、EDI明細情報テーブルデータ削除(A-10)
      --==============================================================
      xxcos_in_edi_head_line_delete(
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--****************************** 2009/06/03 1.4 T.Kitajima MOD START ******************************--
----****************************** 2009/05/28 1.4 T.Kitajima MOD START ******************************--
----    --==============================================================
----    -- コンカレントステータス、件数の設定
----    --==============================================================
----    IF ( gv_status_work_err = cv_status_error ) THEN
----     ov_retcode    := cv_status_error;  --ステータス：エラー
----      gn_warn_cnt   := 0;                --警告件数：0
----     gn_normal_cnt := 0;                --正常件数：0
----      gn_error_cnt  := 1;
----    ELSIF ( gv_status_work_warn =  cv_status_warn ) THEN
----      ov_retcode    := cv_status_warn;   --ステータス：警告
----    END IF;
--      IF ( gv_status_work_err = cv_status_error ) THEN
--        ov_retcode    := cv_status_error;  --ステータス：エラー
--      ELSIF ( gn_warn_cnt != 0 ) THEN
--        ov_retcode    := cv_status_warn;   --ステータス：警告
--      END IF;
----****************************** 2009/05/28 1.3 T.Kitajima MOD  END  ******************************--
    IF    ( gv_status_work_err  =  cv_status_error ) THEN
      ov_retcode    := cv_status_error;  --ステータス：エラー
    ELSIF ( gv_status_work_warn =  cv_status_warn ) THEN
      ov_retcode    := cv_status_error;  --ステータス：エラー
      ov_retcode    := cv_status_warn;   --ステータス：警告
    END IF;
--****************************** 2009/06/03 1.4 T.Kitajima MOD  END  ******************************--
--
  EXCEPTION
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
    errbuf        OUT    VARCHAR2,     --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,     --   エラーコード     #固定#
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN VARCHAR2,     --   実行区分：「0:新規」「1:再実行」
-- ******************** 2010/03/02 1.7 M.Sano     MOD START *********************** --
--    iv_edi_chain_code IN VARCHAR2      --   EDIチェーン店コード
    iv_edi_chain_code IN VARCHAR2 DEFAULT NULL  --   EDIチェーン店コード
-- ******************** 2010/03/02 1.7 M.Sano     MOD END   *********************** --
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00039'; -- 警告件数メッセージ（商品コードエラー）
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
    --==============================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --==============================================================
    submain(
      iv_file_name,       --   インタフェースファイル名
      iv_run_class,       -- 実行区分：「新規」「再実行」
      iv_edi_chain_code,  -- EDIチェーン店コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--****************************** 2009/06/03 1.4 T.Kitajima DEL START ******************************--
----****************************** 2009/05/28 1.3 T.Kitajima ADD START ******************************--
--    --==============================================================
--    -- コンカレントステータス、件数の設定
--    --==============================================================
--    IF ( lv_retcode = cv_status_error ) THEN
--      gn_warn_cnt   := 0;                --警告件数：0
--      gn_normal_cnt := 0;                --正常件数：0
--      gn_error_cnt  := 1;
--    ELSIF ( lv_retcode = cv_status_warn ) THEN
--      gn_normal_cnt := gn_normal_cnt - gn_warn_cnt;
--    END IF;
----****************************** 2009/05/28 1.3 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/03 1.4 T.Kitajima DEL  END  ******************************--

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
    --==============================================================
    --* Description      : 終了処理(A-11)
    --==============================================================
--****************************** 2009/06/03 1.4 T.Kitajima MOD START ******************************--
--    --対象件数出力
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                iv_application  => cv_appl_short_name,
--                iv_name         => cv_target_rec_msg,
--                iv_token_name1  => cv_cnt_token,
--                iv_token_value1 => TO_CHAR(gn_target_cnt)
--                );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.OUTPUT,
--      buff   => gv_out_msg
--    );
--    --
--    --成功件数出力
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                iv_application  => cv_appl_short_name,
--                iv_name         => cv_success_rec_msg,
--                iv_token_name1  => cv_cnt_token,
--                iv_token_value1 => TO_CHAR(gn_normal_cnt)
--                );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.OUTPUT,
--      buff   => gv_out_msg
--    );
--    --
--    --エラー件数出力
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                iv_application  => cv_appl_short_name,
--                iv_name         => cv_error_rec_msg,
--                iv_token_name1  => cv_cnt_token,
--                iv_token_value1 => TO_CHAR(gn_error_cnt)
--                );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.OUTPUT,
--      buff   => gv_out_msg
--    );
--    --
--    --警告件数出力
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                iv_application  => cv_application,
--                iv_name         => cv_warn_rec_msg,
--                iv_token_name1  => cv_cnt_token,
--                iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.OUTPUT,
--      buff   => gv_out_msg
--    );
    IF ( gn_error_cnt != 0 ) THEN
      gn_warn_cnt := gn_target_cnt - gn_error_cnt;
    ELSE
      gn_warn_cnt := 0;
    END IF;
    gv_out_msg  := xxccp_common_pkg.get_msg(
                iv_application  => cv_application,
                iv_name         => cv_msg_count,
                iv_token_name1  => cv_tkn_cnt1,
                iv_token_value1 => TO_CHAR(gn_target_cnt),
                iv_token_name2  => cv_tkn_cnt2,
                iv_token_value2 => TO_CHAR(gn_normal_cnt),
                iv_token_name3  => cv_tkn_cnt3,
                iv_token_value3 => TO_CHAR(gn_error_cnt),
                iv_token_name4  => cv_tkn_cnt4,
                iv_token_value4 => TO_CHAR(gn_warn_cnt),
                iv_token_name5  => cv_tkn_cnt5,
                iv_token_value5 => TO_CHAR(gn_msg_cnt)
                );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
--****************************** 2009/06/04 1.4 T.Kitajima MOD  END  ******************************--
    --
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --
    --終了メッセージ
    IF  ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF  ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF  ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg  := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_short_name,
                iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
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
END XXCOS011A01C;
/
