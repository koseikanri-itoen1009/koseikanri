CREATE OR REPLACE PACKAGE BODY APPS.XXCOS004A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A04C (body)
 * Description      : 消化ＶＤ納品データ作成
 * MD.050           : 消化ＶＤ納品データ作成 MD050_COS_004_A04
 * Version          : 1.22
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  roundup                切上関数
 *  init                   初期処理(A-0)
 *  pram_chk               パラメータチェック(A-1)
 *  get_common_data        共通データ取得(A-2)
 *  get_object_data        消化ＶＤ用消化計算データ抽出処理(A-3)
 *  calc_sales             納品データ計算処理(A-4)
 *  set_lines              販売実績明細作成(A-5)
 *  set_headers            販売実績ヘッダ作成(A-6)
 *  update_digestion       消化ＶＤ用消化計算テーブル更新処理(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/1/14    1.0   T.miyashita       新規作成
 *  2009/02/04   1.1   T.miyashita       [COS_013]INV会計期間取得不具合
 *  2009/02/04   1.2   T.miyashita       [COS_017]基準単価と税抜基準単価の不具合
 *  2009/02/04   1.3   T.miyashita       [COS_024]販売金額の不具合
 *  2009/02/04   1.4   T.miyashita       [COS_028]作成元区分の不具合
 *  2009/02/19   1.5   T.miyashita       [COS_091]訪問・有効の軒数の取込漏れ対応
 *  2009/02/20   1.6   T.Miyashita       パラメータのログファイル出力対応
 *  2009/02/23   1.7   T.Miyashita       [COS_116]納品日セット不具合
 *  2009/02/23   1.8   T.Miyashita       [COS_122]営業担当員コードセット不具合
 *  2009/03/23   1.9   T.Kitajima        [T1_0099]INV会計期による
 *                                                出荷元保管場所、納品形態、納品拠点取得方法修正
 *  2009/03/30   1.10  T.Kitajima        [T1_0189]販売実績明細.納品明細番号の採番方法を変更
 *  2009/04/20   1.11  T.kitajima        [T1_0657]データ取得0件エラー→警告終了へ
 *  2009/04/21   1.12  T.kitajima        [T1_0699]納品形態固定対応(1:営業車)
 *  2009/04/22   1.13  T.kitajima        [T1_0697]対象データ取得処理日変更対応
 *  2009/04/27   1.13  N.Maeda           [T1_0697_0770]処理基準日取得処理の追加
 *                                       データ登録値の修正
 *  2009/05/07   1.14  T.kitajima        [T1_0888]納品拠点取得方法変更
 *                                       [T1_0911]売上区分クイックコード化
 *  2009/05/25   1.15  T.kitajima        [T1_1151]金額マイナス対応
 *                                       [T1_1122]切上対応
 *                                       [T1_1208]単価四捨五入
 *  2009/06/09   1.16  T.kitajima        [T1_1371]行ロック
 *  2009/06/10   1.16  T.kitajima        [T1_1412]納品伝票番号取得処理変更
 *  2009/06/11   1.17  T.kitajima        [T1_1415]納品伝票番号取得処理変更
 *  2009/06/12   1.18  T.kitajima        [T1_1432]VDコラム別取引ヘッダ更新条件変更
 *  2009/08/10   1.19  K.Kiriu           [0000431]PT対応
 *  2009/09/14   1.20  M.Sano            [0001345]PT対応
 *  2009/12/15   1.21  K.Atsushiba       [E_本稼動_00433]差額調整時の消費税金額の算出処理変更
 *  2010/01/12   1.22  K.Atsushiba       [E_本稼動_01111]消費税の差額金額算出方法変更
 *                                       [E_本稼動_01110]赤黒フラグ判定条件変更
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
  -- ユーザー定義例外
  -- ===============================
  global_common_expt          EXCEPTION; --共通エラー
  global_business_err_expt    EXCEPTION; --業務日付エラー
  global_quick_err_expt       EXCEPTION; --クイックコードエラー
  global_base_err_expt        EXCEPTION; --拠点必須エラー
  global_get_profile_expt     EXCEPTION; --プロファイル取得例外
  global_no_data_expt         EXCEPTION; --対象データ０件エラー
  global_insert_expt          EXCEPTION; --登録
  global_up_headers_expt      EXCEPTION; --消化ＶＤ用消化計算ヘッダ更新例外
  global_up_inv_expt          EXCEPTION; --ＶＤコラム別取引ヘッダ更新例外
  global_select_err_expt      EXCEPTION; --SQL SELECTエラー
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  global_call_api_expt        EXCEPTION;                                --API呼出エラー例外
--****************************** 2009/04/22 1.13 T.Kitajima ADD  END  ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  global_quick_salse_err_expt EXCEPTION;                                --売上区分取得エラー
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
  global_data_lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                  CONSTANT  VARCHAR2(100) := 'XXCOS004A04C';  -- パッケージ名
--
  --アプリケーション短縮名
  ct_xxcos_appl_short_name     CONSTANT  fnd_application.application_short_name%TYPE
                                      := 'XXCOS';                          --販物短縮アプリ名
  --共通メッセージ
  ct_msg_get_profile_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00004';               --プロファイル取得エラーメッセージ
  ct_msg_select_data_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00013';               --データ取得エラーメッセージ
  ct_msg_process_date_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00014';               --業務日付取得エラー
  cv_msg_api_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00017';               --API呼出エラーメッセージ
  cv_msg_nodata_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00018';               --明細0件用メッセージ
  cv_msg_period_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00026';               --会計期間情報取得エラーメッセージ
  --
  cv_msg_delivered_from        CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00160';               --納品形態取得
  cv_msg_uom_cnv               CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00161';               --単位換算取得
  cv_msg_discrete_cost         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00162';               --営業原価取得
  cv_msg_deli_err              CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11061';               --納品形態取得エラー
  cv_msg_tan_err               CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11062';               --単位換算取得エラー
  cv_msg_cost_err              CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11063';               --営業原価取得エラー
  cv_msg_prd_err               CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11064';               --会計期間取得エラー
  --販物メッセージ
  ct_msg_pram_date             CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11051';               --パラメータメッセージ
  ct_msg_class_cd_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11052';               --定期随時区分チェックエラーメッセージ
  ct_msg_base_cd_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11053';               --拠点コード必須エラー
  ct_msg_making_cd_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11054';               --作成元区分取得エラー
  cv_msg_inser_lines_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11055';               --販売実績明細登録エラー
  cv_msg_inser_headers_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11056';               --販売実績ヘッダ登録エラー
  cv_msg_update_headers_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11057';               --消化ＶＤ用消化計算ヘッダ更新エラー
  cv_msg_update_inv_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11058';               --ＶＤコラム別取引ヘッダ更新エラー
  cv_msg_select_vd_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11060';               --消化ＶＤ用消化計算データ取得エラー
  cv_msg_select_salesreps_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10911';               --営業担当員コード取得エラー
--****************************** 2009/03/23 1.9  T.kitajima ADD START ******************************--
  cv_msg_select_for_inv_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11065';               --出荷元保管場所取得エラーメッセージ
  cv_msg_select_ship_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11066';               --出荷拠点取得エラーメッセージ
--****************************** 2009/03/23 1.9  T.kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.12 T.Kitajima ADD START ******************************--
  ct_msg_get_organization_id   CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11155';               --在庫組織IDの取得
  ct_msg_get_calendar_code     CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11156';               --カレンダコードの取得
--****************************** 2009/04/22 1.12 T.Kitajima ADD START ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  cv_msg_salse_class_err       CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11175';               --売上区分取得エラー
  ct_msg_delivery_base_err  CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11176';               --納品拠点取得エラーメッセージ
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
  ct_msg_line_lock_err      CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11177';               --消化ＶＤ用消化計算テーブル取得エラーメッセージ
  ct_msg_vd_lock_err        CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11178';               --ＶＤコラム別取引ヘッダテーブルロック取得エラーメッセージ
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
  --クイックコードタイプ
  ct_qct_regular_type          CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_REGULAR_ANY_CLASS';       --定期随時
  ct_qct_making_type           CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_MK_ORG_CLS_MST_004_A04';  --作成元区分
  ct_qct_gyo_type              CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_GYOTAI_SHO_MST_004_A04';  --業態小分類特定マスタ_004_A04
  ct_qct_cust_type             CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_CUS_CLASS_MST_004_A04';   --顧客区分特定マスタ
  ct_qct_tax_type2             CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_CONSUMPTION_TAX_CLASS';   --税コード特定マスタ
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  ct_qct_sales_type            CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_SALE_CLASS_MST_004_A04';  --売上区分特定マスタ
  ct_qct_not_inv_type          CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_NO_INV_ITEM_CODE';        --非在庫品目コード
  ct_qct_hokan_type_mst        CONSTANT fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_HOKAN_TYPE_MST_004_A04';  --保管場所分類特定マスタ_004_A04
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
  --クイックコード
  ct_qcc_d_code                CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04%';                 --消化・VD消化
  ct_qcc_digestion_code        CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04_02';               --消化・VD消化
  ct_qcc_digestion_code_1      CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04_1%';               --消化・VD消化
  ct_qcc_digestion_code_2      CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04_2%';               --消化・VD消化
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  ct_qcc_sales_code            CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A04_04';               --消化・VD消化
  ct_qcc_hokan_type_mst        CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS_004_A04_%';                --保管場所分類特定マスタ
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--
  --トークン
  cv_tkn_parm_data1            CONSTANT  VARCHAR2(10) :=  'PARAM1';        --パラメータ1
  cv_tkn_parm_data2            CONSTANT  VARCHAR2(10) :=  'PARAM2';        --パラメータ2
  cv_tkn_parm_data3            CONSTANT  VARCHAR2(10) :=  'PARAM3';        --パラメータ3
  cv_tkn_parm_data4            CONSTANT  VARCHAR2(10) :=  'PARAM4';        --パラメータ4
  cv_tkn_parm_data5            CONSTANT  VARCHAR2(10) :=  'PARAM5';        --パラメータ5
  cv_tkn_profile               CONSTANT  VARCHAR2(10) :=  'PROFILE';       --プロファイル
  cv_tkn_quick1                CONSTANT  VARCHAR2(10) :=  'QUICK1';        --クイック
  cv_tkn_quick2                CONSTANT  VARCHAR2(10) :=  'QUICK2';        --クイック
  cv_tkn_table                 CONSTANT  VARCHAR2(10) :=  'TABLE_NAME';    --テーブル名称
  cv_tkn_key_data              CONSTANT  VARCHAR2(10) :=  'KEY_DATA';      --キーデータ
  cv_tkn_account_name          CONSTANT  VARCHAR2(30) :=  'ACCOUNT_NAME';  --期間名
  cv_tkn_api_name              CONSTANT  VARCHAR2(10) :=  'API_NAME';      --API名
  --プロファイル名称
  cv_profile_item_cd           CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_DIGESTION_DELI_DELAY_DAY';-- 消化ＶＤ納品データ作成猶予日数
--****************************** 2009/04/21 1.12 T.Kitajima ADD START ******************************--
  cv_profile_dlv_ptn           CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_DIGESTION_DLV_PTN_CLS';   -- 消化VD納品データ作成用納品形態区分
--****************************** 2009/04/21 1.12 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  ct_prof_organization_code    CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOI1_ORGANIZATION_CODE';       --XXCOI:在庫組織コード
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  --使用可能フラグ定数
  ct_enabled_flag_yes          CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                      := 'Y';                              --使用可能
  --拠点/顧客フラグ
  ct_customer_flag_no          CONSTANT  fnd_lookup_values.attribute2%TYPE
                                      := 'N';                              --顧客
  ct_customer_flag_yes         CONSTANT  fnd_lookup_values.attribute2%TYPE
                                      := 'Y';                              --拠点
  --店舗ヘッダ用フラグ
  ct_make_flag_yes             CONSTANT  xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                      := 'Y';                              --作成済み
  ct_make_flag_no              CONSTANT  xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                      := 'N';                              --未作成
  ct_un_calc_flag_0            CONSTANT  xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                      := 0;                                --未計算フラグ
  ct_un_calc_flag_1            CONSTANT  xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                      := 1;                                --未計算フラグ
  --赤黒フラグ
  ct_red_black_flag_0          CONSTANT  xxcos_sales_exp_lines.red_black_flag%TYPE
                                      := '0';                              --赤
  ct_red_black_flag_1          CONSTANT  xxcos_sales_exp_lines.red_black_flag%TYPE
                                      := '1';                              --黒
  --手数料計算インタフェース済フラグ
  ct_to_calculate_fees_flag    CONSTANT  xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE
                                      := 'N';                              --NO
  --単価マスタ作成済フラグ
  ct_unit_price_mst_flag       CONSTANT  xxcos_sales_exp_lines.unit_price_mst_flag%TYPE
                                      := 'N';                              --NO
  --INVインタフェース済フラグ
  ct_inv_interface_flag        CONSTANT  xxcos_sales_exp_lines.inv_interface_flag%TYPE
                                      := 'N';                              --NO
  --ARインタフェース済フラグ
  ct_ar_interface_flag         CONSTANT  xxcos_sales_exp_headers.ar_interface_flag%TYPE
                                      := 'N';                              --NO
  --GLインタフェース済フラグ
  ct_gl_interface_flag         CONSTANT  xxcos_sales_exp_headers.gl_interface_flag%TYPE
                                      := 'N';                              --NO
  --情報システムインタフェース済フラグ
  ct_dwh_interface_flag        CONSTANT  xxcos_sales_exp_headers.dwh_interface_flag%TYPE
                                      := 'N';                              --NO
  --EDI送信済みフラグ
  ct_edi_interface_flag        CONSTANT  xxcos_sales_exp_headers.edi_interface_flag%TYPE
                                      := 'N';                              --NO
  --AR税金マスタ有効フラグ
  ct_tax_enabled_yes           CONSTANT  ar_vat_tax_all_b.enabled_flag%TYPE
                                      := 'Y';                              --Y:有効
  ct_apply_flag_yes            CONSTANT  xxcmm_system_items_b_hst.apply_flag%TYPE
                                      := 'Y';                              --Y:有効
  --会計区分
  cv_inv                       CONSTANT  VARCHAR2(10) := '01';             --INV
  --カード売り区分
  cv_card_sale_class           CONSTANT  VARCHAR2(1)  := '1';              --1:現金
  --納品伝票区分
  cv_dlv_invoice_class_1       CONSTANT  VARCHAR2(1)  := '1';              --1:納品
  --納品伝票区分
  cv_dlv_invoice_class_3       CONSTANT  VARCHAR2(1)  := '3';              --3:納品訂正
  --端数処理区分
  cv_tax_rounding_rule_UP      CONSTANT  VARCHAR2(10) := 'UP';             --切上げ
  --端数処理区分
  cv_tax_rounding_rule_DOWN    CONSTANT  VARCHAR2(10) := 'DOWN';           --切捨て
  --端数処理区分
  cv_tax_rounding_rule_NEAREST CONSTANT  VARCHAR2(10) := 'NEAREST';        --四捨五入
  --会計帳簿
  ct_prof_gl_set_of_bks_id     CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'GL_SET_OF_BKS_ID';               --GL会計帳簿ID
  --カード売り区分
  ct_card_flag_cash            CONSTANT  xxcos_sales_exp_headers.card_sale_class%TYPE
                                      := '0';                              --0:現金
  --会計期間オープンステータス
  cv_open                      CONSTANT  VARCHAR2(10) := 'OPEN';           --OPEN
  --0
  cv_0                         CONSTANT  VARCHAR2(1)  := '0';              --0
  --1
  cv_1                         CONSTANT  VARCHAR2(1)  := '1';              --1
  --0
  cn_0                         CONSTANT  NUMBER       := 0;                --0
  --1
  cn_1                         CONSTANT  NUMBER       := 1;                --1
  --100
  cn_100                       CONSTANT  NUMBER       := 100;              --100
  --ダミー
  cn_dmy                       CONSTANT  NUMBER       := 0;
--****************************** 2009/05/07 1.14 T.Kitajima DEL START ******************************--
--  --売上区分
--  cv_sales_class_vd            CONSTANT  VARCHAR2(1)  := '4';              --消化・VD消化
--****************************** 2009/05/07 1.14 T.Kitajima DEL  END  ******************************--
  --y
  cv_y                         CONSTANT  VARCHAR2(1)  := 'Y';              --Y
  --MM
  cv_mm                        CONSTANT  VARCHAR2(2)  := 'MM';             --MM
  --登録区分
  cv_entry_class               CONSTANT  VARCHAR2(2)  := '5';              --消化VD
--****************************** 2009/03/23 1.9  T.kitajima ADD START ******************************--
  --棚卸対象区分
  ct_secondary_class_2         CONSTANT   mtl_secondary_inventories.attribute5%TYPE
                                          := '2';                     --消化
  cv_exists_flag_yes            CONSTANT VARCHAR2(1) := 'Y';          --存在あり
--****************************** 2009/03/23 1.9  T.kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  --稼働日ステータス
  cn_sales_oprtn_day_normal     CONSTANT NUMBER       := 0;           --稼働日
  cn_sales_oprtn_day_non        CONSTANT NUMBER       := 1;           --非稼働日
  cn_sales_oprtn_day_error      CONSTANT NUMBER       := 2;           --エラー
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
--****************************** 2009/06/10 1.16 T.Kitajima ADD START ******************************--
  cv_snq_i                      CONSTANT VARCHAR2(1)  := 'I';
--****************************** 2009/06/10 1.16 T.Kitajima ADD  END  ******************************--
/* 2009/08/10 Ver1.19 Mod Start */
  ct_lang                       CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語
/* 2009/08/10 Ver1.19 Mod Start */
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ＶＤ消化用消化計算データ格納用変数
  TYPE g_rec_work_data IS RECORD
    (
      vd_digestion_hdr_id         xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,        --消化ＶＤ用消化計算ヘッダID
      customer_number             xxcos_vd_digestion_hdrs.customer_number%TYPE,            --顧客コード
      digestion_due_date          xxcos_vd_digestion_hdrs.digestion_due_date%TYPE,         --消化計算締年月日
      cust_account_id             xxcos_vd_digestion_hdrs.cust_account_id%TYPE,            --顧客ID
      digestion_exe_date          xxcos_vd_digestion_hdrs.digestion_exe_date%TYPE,         --消化計算実行日
      ar_sales_amount             xxcos_vd_digestion_hdrs.ar_sales_amount%TYPE,            --売上金額
      sales_amount                xxcos_vd_digestion_hdrs.sales_amount%TYPE,               --販売金額
      digestion_calc_rate         xxcos_vd_digestion_hdrs.digestion_calc_rate%TYPE,        --消化計算掛率
      master_rate                 xxcos_vd_digestion_hdrs.master_rate%TYPE,                --マスタ掛率
      balance_amount              xxcos_vd_digestion_hdrs.balance_amount%TYPE,             --差額
      cust_gyotai_sho             xxcos_vd_digestion_hdrs.cust_gyotai_sho%TYPE,            --業態小分類
      tax_amount                  xxcos_vd_digestion_hdrs.tax_amount%TYPE,                 --消費税額
      delivery_date               xxcos_vd_digestion_hdrs.delivery_date%TYPE,              --納品日
      dlv_time                    xxcos_vd_digestion_hdrs.dlv_time%TYPE,                   --時間
      sales_result_creation_date  xxcos_vd_digestion_hdrs.sales_result_creation_date%TYPE, --販売実績登録日
      sales_result_creation_flag  xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE, --販売実績作成済フラグ
      pre_digestion_due_date      xxcos_vd_digestion_hdrs.pre_digestion_due_date%TYPE,     --前回消化計算締年月日
      uncalculate_class           xxcos_vd_digestion_hdrs.uncalculate_class%TYPE,          --未計算区分
      change_out_time_100         xxcos_vd_digestion_hdrs.change_out_time_100%TYPE,        --つり銭切れ時間100円
      change_out_time_10          xxcos_vd_digestion_hdrs.change_out_time_10%TYPE,         --つり銭切れ時間10円
      vd_digestion_ln_id          xxcos_vd_digestion_lns.vd_digestion_ln_id%TYPE,          --消化ＶＤ用消化計算明細ID
      digestion_ln_number         xxcos_vd_digestion_lns.digestion_ln_number%TYPE,         --枝番
      item_code                   xxcos_vd_digestion_lns.item_code%TYPE,                   --品目コード
      inventory_item_id           xxcos_vd_digestion_lns.inventory_item_id%TYPE,           --品目ID
      item_price                  xxcos_vd_digestion_lns.item_price%TYPE,                  --定価
      unit_price                  xxcos_vd_digestion_lns.unit_price%TYPE,                  --単価
      item_sales_amount           xxcos_vd_digestion_lns.item_sales_amount%TYPE,           --品目別販売金額
      uom_code                    xxcos_vd_digestion_lns.uom_code%TYPE,                    --単位コード
      sales_quantity              xxcos_vd_digestion_lns.sales_quantity%TYPE,              --販売数
      hot_cold_type               xxcos_vd_digestion_lns.hot_cold_type%TYPE,               --H/C
      column_no                   xxcos_vd_digestion_lns.column_no%TYPE,                   --コラムNo
      delivery_base_code          xxcos_vd_digestion_lns.delivery_base_code%TYPE,          --納品拠点コード
      ship_from_subinventory_code xxcos_vd_digestion_lns.ship_from_subinventory_code%TYPE, --出荷元保管場所
      sold_out_class              xxcos_vd_digestion_lns.sold_out_class%TYPE,              --売切区分
      sold_out_time               xxcos_vd_digestion_lns.sold_out_time%TYPE,               --売切時間
      tax_div                     xxcmm_cust_accounts.tax_div%TYPE,                        --消費税区分
      tax_uchizei_flag            fnd_lookup_values.attribute5%TYPE,                       --内税フラグ
      tax_rate                    ar_vat_tax_all_b.tax_rate%TYPE,                          --消費税率
      tax_rounding_rule           hz_cust_site_uses_all.tax_rounding_rule%TYPE,            --税金－端数処理
      tax_code                    ar_vat_tax_all_b.tax_code%TYPE,                          --AR税コード
      cash_receiv_base_code       xxcfr_cust_hierarchy_v.cash_receiv_base_code%TYPE,       --入金拠点コード
      party_id                    hz_cust_accounts.party_id%TYPE,                          --パーティID
      party_name                  hz_parties.party_name%TYPE,                              --顧客名
      sale_base_code              xxcmm_cust_accounts.sale_base_code%TYPE,                 --当月売上拠点コード
      past_sale_base_code         xxcmm_cust_accounts.past_sale_base_code%TYPE,            --前月売上拠点コード
      duns_number_c               hz_parties.duns_number_c%TYPE,                           --当月顧客ステータス
      past_customer_status        xxcmm_cust_accounts.past_customer_status%TYPE            --前月顧客ステータス
  );
  -- 販売員ポイント計算共通関数格納用変数
  TYPE g_rec_for_comfunc_inpara IS RECORD
    (
      resource_id                 xxcos_salesreps_v.resource_id%TYPE,                      --リソースID
      party_id                    hz_cust_accounts.party_id%TYPE,                          --パーティID
      party_name                  hz_parties.party_name%TYPE,                              --顧客名
      digestion_due_date          xxcos_vd_digestion_hdrs.digestion_due_date%TYPE,         --消化計算締年月日
      ar_sales_amount             xxcos_vd_digestion_hdrs.ar_sales_amount%TYPE,            --売上金額
      deli_seq                    VARCHAR2(12),                                            --納品伝票番号
      cust_status                 VARCHAR2(30)                                             --顧客ステータス
  );
  --更新用
  TYPE g_tab_vd_digestion_hdr_id IS TABLE OF xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE
    INDEX BY PLS_INTEGER;   -- 消化ＶＤ用消化計算ヘッダID
  --テーブル定義
  TYPE g_tab_work_data IS TABLE OF g_rec_work_data INDEX BY PLS_INTEGER;                         --消化ＶＤ用消化計算データ格納用変数
  TYPE g_tab_sales_exp_headers IS TABLE OF xxcos_sales_exp_headers%ROWTYPE INDEX BY PLS_INTEGER; --販売実績ヘッダ
  TYPE g_tab_sales_exp_lines IS TABLE OF xxcos_sales_exp_lines%ROWTYPE INDEX BY PLS_INTEGER;     --販売実績明細
  TYPE g_tab_for_comfunc_inpara IS TABLE OF g_rec_for_comfunc_inpara INDEX BY PLS_INTEGER;       --販売員ポイント計算共通関数格納用変数
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_business_date                    DATE;                          --業務日付
  gv_delay_days                       VARCHAR2(10);                  --消化ＶＤ納品データ作成猶予日数
  gd_delay_date                       DATE;                          --消化ＶＤ納品データ作成猶予日
  gv_making_code                      VARCHAR2(1);                   --作成元区分
  gt_tab_work_data                    g_tab_work_data;               --対象データ取得用
  gt_tab_sales_exp_headers            g_tab_sales_exp_headers;       --販売実績ヘッダ
  gt_tab_sales_exp_lines              g_tab_sales_exp_lines;         --販売実績明細
  gt_tab_sales_exp_lines_ins          g_tab_sales_exp_lines;         --販売実績明細
  gt_tab_vd_digestion_hdr_id          g_tab_vd_digestion_hdr_id;     --消化ＶＤ用消化計算ヘッダID
  gt_tab_for_comfunc_inpara           g_tab_for_comfunc_inpara;      --販売員ポイント計算共通関数用
  gv_exec_div                         VARCHAR2(100);                 --定期随時区分
  gv_base_code                        VARCHAR2(100);                 --拠点コード
  gv_customer_number                  VARCHAR2(100);                 --顧客コード
  gn_gl_id                            NUMBER;                        --会計帳簿ID
--****************************** 2009/04/21 1.12 T.Kitajima ADD START ******************************--
  gv_delay_ptn                        VARCHAR2(1);                   --納品形態区分
--****************************** 2009/04/21 1.12 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
  gt_organization_code                mtl_parameters.organization_code%TYPE;
                                                                     --在庫組織コード
  gt_organization_id                  mtl_parameters.organization_id%TYPE;
                                                                     -- 在庫組織ID
  gt_calendar_code                    bom_calendars.calendar_code%TYPE;
                                                                     -- カレンダコード
--****************************** 2009/04/22 1.13 T.Kitajima ADD  END  ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  gv_sales_class_vd                   VARCHAR2(1);                           --消化・VD消化(売上区分)
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--
--****************************** 2009/05/25 1.15 T.Kitajima ADD START ******************************--
  /**********************************************************************************
   * Procedure Name   : roundup
   * Description      : 切上関数
   ***********************************************************************************/
  FUNCTION roundup(in_number IN NUMBER, in_place IN INTEGER := 0)
  RETURN NUMBER
  IS
    ln_base NUMBER;
  BEGIN
    IF (in_number = 0)
      OR (in_number IS NULL)
    THEN
      RETURN 0;
    END IF;
--
    ln_base := 10 ** in_place ;
    RETURN CEIL( ABS( in_number ) * ln_base ) / ln_base * SIGN( in_number );
  END;
--****************************** 2009/05/25 1.15 T.Kitajima ADD  END  ******************************--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_exec_div        IN         VARCHAR2,     -- 1.定期随時区分
    iv_base_code       IN         VARCHAR2,     -- 2.拠点コード
    iv_customer_number IN         VARCHAR2,     -- 3.顧客コード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    --入力項目表示
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => ct_xxcos_appl_short_name,
                    iv_name         => ct_msg_pram_date,
                    iv_token_name1  => cv_tkn_parm_data1,
                    iv_token_value1 => iv_exec_div,
                    iv_token_name2  => cv_tkn_parm_data2,
                    iv_token_value2 => iv_base_code,
                    iv_token_name3  => cv_tkn_parm_data3,
                    iv_token_value3 => iv_customer_number
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- メッセージログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
  EXCEPTION
--#####################################  固定部 START ##########################################
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
   * Procedure Name   : pram_chk
   * Description      : パラーメータチェック(A-1)
   ***********************************************************************************/
  PROCEDURE pram_chk(
    iv_exec_div        IN       VARCHAR2,     -- 1.定期随時区分
    iv_base_code       IN       VARCHAR2,     -- 2.拠点コード
    iv_customer_number IN       VARCHAR2,     -- 3.顧客コード
    ov_errbuf     OUT    NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pram_chk'; -- プログラム名
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
    ln_cnt     NUMBER;          --カウンター
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
    --==============================================================
    --1.業務日付取得
    --==============================================================
    gd_business_date          := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_business_date IS NULL ) THEN
      RAISE global_business_err_expt;
    END IF;
--
    --==============================================================
    --2.定期随時区分のチェックをします。
    --==============================================================
    SELECT COUNT(flv.meaning)
    INTO   ln_cnt
/* 2009/08/10 Ver1.19 Mod Start */
--    FROM   fnd_application               fa,
--           fnd_lookup_types              flt,
--           fnd_lookup_values             flv
--    WHERE  fa.application_id                               = flt.application_id
--    AND    flt.lookup_type                                 = flv.lookup_type
--    AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--    AND    flv.lookup_type                                 = ct_qct_regular_type
--    AND    flv.lookup_code                                 = iv_exec_div
--    AND    flv.start_date_active                          <= gd_business_date
--    AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
--    AND    flv.enabled_flag                                = ct_enabled_flag_yes
--    AND    flv.language                                    = USERENV( 'LANG' )
--    AND    ROWNUM                                          = cn_1
    FROM   fnd_lookup_values             flv
    WHERE  flv.lookup_type    = ct_qct_regular_type
    AND    flv.lookup_code    = iv_exec_div
    AND    gd_business_date   BETWEEN NVL( flv.start_date_active, gd_business_date )
                              AND     NVL( flv.end_date_active, gd_business_date )
    AND    flv.enabled_flag   = ct_enabled_flag_yes
    AND    flv.language       = ct_lang
    AND    ROWNUM             = cn_1
/* 2009/08/10 Ver1.19 Mod End   */
    ;
--
    IF ( ln_cnt = cn_0 ) THEN
      RAISE global_quick_err_expt;
    END IF;
--
    --==============================================================
    --3.随時実行の場合、拠点コードのチェックをします。
    --==============================================================
    IF ( iv_exec_div = cv_0 ) THEN
      IF ( iv_base_code IS NULL ) THEN
        RAISE global_base_err_expt;
      END IF;
    END IF;
--
    gv_exec_div        := iv_exec_div;         --定期随時区分
    gv_base_code       := iv_base_code;        --拠点コード
    gv_customer_number := iv_customer_number;  --顧客コード
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_business_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** クイックコード取得例外ハンドラ ***
    WHEN global_quick_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_class_cd_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 拠点コード必須例外ハンドラ ***
    WHEN global_base_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_base_cd_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ###################################
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
  END pram_chk;
--
  /**********************************************************************************
   * Procedure Name   : get_common_data
   * Description      : 共通データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_common_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_common_data'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info VARCHAR2(5000);  --key情報
    lv_gl_id    VARCHAR2(100);   --GLID
    lv_err_code VARCHAR2(100);   --エラーID
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
    lv_str_api_name               VARCHAR2(5000);                     --関数名
    lt_organization_id            mtl_parameters.organization_id%TYPE;
                                                                      --在庫組織ID
    lt_organization_code          mtl_parameters.organization_code%TYPE;
                                                                      --在庫組織コード
    ln_date_index                 NUMBER;                             --日付用インデックス
    ln_delay_days                 NUMBER;                             --猶予日数
    ld_work_delay_date            DATE;                               --猶予日計算用
    ln_sales_oprtn_day            NUMBER;                             --戻り値:稼働日チェック用
--****************************** 2009/04/22 1.13 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/27 1.13 N.Maeda ADD START ******************************--
    ln_record_date_flg            NUMBER;                             --基準日判定用
--****************************** 2009/04/27 1.13 N.Maeda ADD  END  ******************************--
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
    --=======================================================================
    -- 1.クイックコード「作成元区分(消化計算（ＶＤ）)」を取得します。
    --=======================================================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_making_code
/* 2009/08/10 Ver1.19 Mod Start */
--      FROM   fnd_application               fa,
--             fnd_lookup_types              flt,
--             fnd_lookup_values             flv
--      WHERE  fa.application_id                               = flt.application_id
--      AND    flt.lookup_type                                 = flv.lookup_type
--      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                                 = ct_qct_making_type
--      AND    flv.lookup_code                                 = ct_qcc_digestion_code
--      AND    flv.start_date_active                          <= gd_business_date
--      AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
--      AND    flv.enabled_flag                                = ct_enabled_flag_yes
--      AND    flv.language                                    = USERENV( 'LANG' )
--      AND    ROWNUM                                          = cn_1
      FROM   fnd_lookup_values             flv
      WHERE  flv.lookup_type    = ct_qct_making_type
      AND    flv.lookup_code    = ct_qcc_digestion_code
      AND    gd_business_date   BETWEEN NVL( flv.start_date_active, gd_business_date )
                                AND     NVL( flv.end_date_active, gd_business_date )
      AND    flv.enabled_flag   = ct_enabled_flag_yes
      AND    flv.language       = ct_lang
      AND    ROWNUM             = cn_1
/* 2009/08/10 Ver1.19 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_err_expt;
    END;
--****************************** 2009/04/22 1.13 T.Kitajima ADD START ******************************--
    --============================================
    -- XXCOI:在庫組織コード
    --============================================
    gt_organization_code      := FND_PROFILE.VALUE( ct_prof_organization_code );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_organization_code IS NULL ) THEN
      lv_key_info := ct_prof_organization_code;
      RAISE global_get_profile_expt;
    END IF;
--
    --============================================
    -- 在庫組織IDの取得
    --============================================
    gt_organization_id        := xxcoi_common_pkg.get_organization_id(
                                   iv_organization_code          => gt_organization_code
                                 );
--
    IF ( gt_organization_id IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_organization_id
                                         );                      -- 在庫組織ID取得
      RAISE global_call_api_expt;
    END IF;
--
    --============================================
    -- 販売用カレンダコード取得
    --============================================
    lt_organization_id        := gt_organization_id;
    lt_organization_code      := gt_organization_code;
    --
    xxcos_common_pkg.get_sales_calendar_code(
      ion_organization_id     => lt_organization_id,             -- 在庫組織ＩＤ
      iov_organization_code   => lt_organization_code,           -- 在庫組織コード
      ov_calendar_code        => gt_calendar_code,               -- カレンダコード
      ov_errbuf               => lv_errbuf,                      -- エラー・メッセージエラー       #固定#
      ov_retcode              => lv_retcode,                     -- リターン・コード               #固定#
      ov_errmsg               => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );                      -- カレンダコード取得
      RAISE global_call_api_expt;
    END IF;
    --
    IF ( gt_calendar_code IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );                      -- カレンダコード取得
      RAISE global_call_api_expt;
    END IF;
--****************************** 2009/04/22 1.13 T.Kitajima ADD  END  ******************************--
    --====================================================================================
    -- 2.「XXCOS1_DIGESTION_DELI_DELAY_DAY: 消化ＶＤ納品データ作成猶予日数」を取得します。
    --====================================================================================
--****************************** 2009/04/22 1.13 T.Kitajima MOD START ******************************--
--    --猶予日数取得
--    gv_delay_days := FND_PROFILE.VALUE( cv_profile_item_cd );
--    --猶予日算出
--    gd_delay_date             := gd_business_date - gv_delay_days;
--    --未取得
--    IF ( gv_delay_days IS NULL ) THEN
--      lv_key_info := cv_profile_item_cd;
--      RAISE global_get_profile_expt;
--    END IF;
--
    --猶予日数取得
    gv_delay_days := FND_PROFILE.VALUE( cv_profile_item_cd );
--
    --未取得
    IF ( gv_delay_days IS NULL ) THEN
      lv_key_info := cv_profile_item_cd;
      RAISE global_get_profile_expt;
    END IF;
--
    --猶予日算出
    --初期化
    ld_work_delay_date := gd_business_date;
    ln_delay_days      := TO_NUMBER( gv_delay_days );
    ln_date_index      := 0;
    ln_sales_oprtn_day := NULL;
--****************************** 2009/04/27 1.13 N.Maeda MOD START ******************************--
    ln_record_date_flg := 0;
    <<day_loop>>
    LOOP
      --
      EXIT WHEN ( ln_record_date_flg = 1 );
      ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
                                               id_check_target_date     => ld_work_delay_date,
                                               iv_calendar_code         => gt_calendar_code
                                               );
--
      --稼働日判定
      IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
        ld_work_delay_date  := ld_work_delay_date - 1;
      ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
        ln_record_date_flg := 1;
      ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_error ) THEN
        lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );
        RAISE global_call_api_expt;
      END IF;
--
    END LOOP day_loop;
--****************************** 2009/04/27 1.13 N.Maeda MOD  END  ******************************--
--
    ln_sales_oprtn_day := NULL;
--
    <<delay_day_loop>>
    WHILE ( ln_delay_days <> ln_date_index ) LOOP
      --
      ld_work_delay_date  := ld_work_delay_date - 1;
      ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
                                             id_check_target_date     => ld_work_delay_date,
                                             iv_calendar_code         => gt_calendar_code
                                           );
      --稼働日判定
      IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
        ln_date_index := ln_date_index + 1;
      ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_error ) THEN
        lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );
        RAISE global_call_api_expt;
      END IF;
--
    END LOOP delay_day_loop;
--
    gd_delay_date             := ld_work_delay_date;
--
--****************************** 2009/04/22 1.13 T.Kitajima MOD  END  ******************************--
--
    --============================================
    -- 3. 会計帳簿ID
    --============================================
    lv_gl_id := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
    --GL会計帳簿ID
    IF ( lv_gl_id IS NULL ) THEN
      lv_key_info := ct_prof_gl_set_of_bks_id;
      RAISE global_get_profile_expt;
    ELSE
      gn_gl_id := TO_NUMBER( lv_gl_id );
    END IF;
--
--****************************** 2009/04/21 1.12 T.Kitajima ADD START ******************************--
    --============================================
    -- 4. 納品形態区分取得
    --============================================
    gv_delay_ptn := FND_PROFILE.VALUE( cv_profile_dlv_ptn );
    --納品形態区分
    IF ( gv_delay_ptn IS NULL ) THEN
      lv_key_info := cv_profile_dlv_ptn;
      RAISE global_get_profile_expt;
    END IF;
--****************************** 2009/04/21 1.12 T.Kitajima ADD  END  ******************************--
--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
    --==============================================
    -- 5.クイックコード「売上区分(4：消化・VD消化)」を取得します。
    --==============================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_sales_class_vd
/* 2009/08/10 Ver1.19 Mod Start */
--      FROM   fnd_application               fa,
--             fnd_lookup_types              flt,
--             fnd_lookup_values             flv
--      WHERE  fa.application_id                               = flt.application_id
--      AND    flt.lookup_type                                 = flv.lookup_type
--      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                                 = ct_qct_sales_type
--      AND    flv.lookup_code                                 = ct_qcc_sales_code
--      AND    flv.start_date_active                          <= gd_business_date
--      AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
--      AND    flv.enabled_flag                                = ct_enabled_flag_yes
--      AND    flv.language                                    = USERENV( 'LANG' )
--      AND    ROWNUM                                          = 1
      FROM   fnd_lookup_values             flv
      WHERE  flv.lookup_type    = ct_qct_sales_type
      AND    flv.lookup_code    = ct_qcc_sales_code
      AND    gd_business_date   BETWEEN NVL( flv.start_date_active, gd_business_date )
                                AND     NVL( flv.end_date_active, gd_business_date )
      AND    flv.enabled_flag   = ct_enabled_flag_yes
      AND    flv.language       = ct_lang
      AND    ROWNUM             = 1
/* 2009/08/10 Ver1.19 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_salse_err_expt;
    END;
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** プロファイル取得エラー例外ハンドラ ***
    WHEN global_get_profile_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_profile_err,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_key_info
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** クイックコード取得エラー例外ハンドラ ***
    WHEN global_quick_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_making_cd_err,
                                   iv_token_name1        => cv_tkn_quick1,
                                   iv_token_value1       => ct_qct_making_type,
                                   iv_token_name2        => cv_tkn_quick2,
                                   iv_token_value2       => ct_qcc_digestion_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/04/27 1.13 N.Maeda ADD START ******************************--
  WHEN global_call_api_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_str_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/04/27 1.13 N.Maeda ADD  END  ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
  WHEN global_quick_salse_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_salse_class_err,
                                   iv_token_name1        => cv_tkn_quick1,
                                   iv_token_value1       => ct_qct_sales_type,
                                   iv_token_name2        => cv_tkn_quick2,
                                   iv_token_value2       => ct_qcc_sales_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_common_data;
--
  /**********************************************************************************
   * Procedure Name   : get_object_data
   * Description      : 消化ＶＤ用消化計算データ抽出処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_object_data(
    iv_exec_div        IN         VARCHAR2,     -- 定期随時区分
    iv_base_code       IN         VARCHAR2,     -- 拠点コード
    iv_customer_number IN         VARCHAR2,     -- 顧客コード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_object_data'; -- プログラム名
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
    --定期用
    CURSOR get_data_cur1
    IS
/* 2009/08/10 Ver1.19 Mod Start */
--      SELECT xsdh.vd_digestion_hdr_id           vd_digestion_hdr_id,              --消化ＶＤ用消化計算ヘッダID
/* 2009/09/14 Ver1.20 Mod Start */
--      SELECT /*+
--               LEADING(xsdh)
--               INDEX(xsdh xxcos_shop_digestion_hdrs_n04)
--               INDEX(xxca xxcmm_cust_accounts_pk)
--               USE_NL(xchv.cust_hier.cash_hcar_3)
--               USE_NL(xchv.cust_hier.bill_hasa_3)
--               USE_NL(xchv.cust_hier.bill_hasa_4)
--               USE_NL(flv xxca)
--             */ 
      SELECT /*+
               LEADING(xsdh)
               INDEX(xsdh xxcos_vd_digestion_hdrs_n04)
               INDEX(xxca xxcmm_cust_accounts_pk)
               INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u1)
               INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u1)
               INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u1)
               INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u1)
               USE_NL(xchv.cust_hier.cash_hcar_3)
               USE_NL(xchv.cust_hier.bill_hasa_3)
               USE_NL(xchv.cust_hier.bill_hasa_4)
               USE_NL(flv xxca)
             */ 
/* 2009/09/14 Ver1.20 Mod Start */
             xsdh.vd_digestion_hdr_id           vd_digestion_hdr_id,              --消化ＶＤ用消化計算ヘッダID
/* 2009/08/10 Ver1.19 Mod End   */
             xsdh.customer_number               customer_number,                  --顧客コード
             xsdh.digestion_due_date            digestion_due_date,               --消化計算締年月日
             xsdh.cust_account_id               cust_account_id,                  --顧客ID
             xsdh.digestion_exe_date            digestion_exe_date,               --消化計算実行日
             xsdh.ar_sales_amount               ar_sales_amount,                  --売上金額
             xsdh.sales_amount                  sales_amount,                     --販売金額
             xsdh.digestion_calc_rate           digestion_calc_rate,              --消化計算掛率
             xsdh.master_rate                   master_rate,                      --マスタ掛率
             xsdh.balance_amount                balance_amount,                   --差額
             xsdh.cust_gyotai_sho               cust_gyotai_sho,                  --業態小分類
             xsdh.tax_amount                    tax_amount,                       --消費税額
             xsdh.delivery_date                 delivery_date,                    --納品日
             xsdh.dlv_time                      dlv_time,                         --時間
             xsdh.sales_result_creation_date    sales_result_creation_date,       --販売実績登録日
             xsdh.sales_result_creation_flag    sales_result_creation_flag,       --販売実績作成済フラグ
             xsdh.pre_digestion_due_date        pre_digestion_due_date,           --前回消化計算締年月日
             xsdh.uncalculate_class             uncalculate_class,                --未計算区分
             xsdh.change_out_time_100           change_out_time_100,              --つり銭切れ時間100円
             xsdh.change_out_time_10            change_out_time_10,               --つり銭切れ時間10円
             xsdl.vd_digestion_ln_id            vd_digestion_ln_id,               --消化ＶＤ用消化計算明細ID
             xsdl.digestion_ln_number           digestion_ln_number,              --枝番
             xsdl.item_code                     item_code,                        --品目コード
             xsdl.inventory_item_id             inventory_item_id,                --品目ID
             xsdl.item_price                    item_price,                       --定価
             xsdl.unit_price                    unit_price,                       --単価
             xsdl.item_sales_amount             item_sales_amount,                --品目別販売金額
             xsdl.uom_code                      uom_code,                         --単位コード
             xsdl.sales_quantity                sales_quantity,                   --販売数
             xsdl.hot_cold_type                 hot_cold_type,                    --H/C
             xsdl.column_no                     column_no,                        --コラムNo
             xsdl.delivery_base_code            delivery_base_code,               --納品拠点コード
             xsdl.ship_from_subinventory_code   ship_from_subinventory_code,      --出荷元保管場所
             xsdl.sold_out_class                sold_out_class,                   --売切区分
             xsdl.sold_out_time                 sold_out_time,                    --売切時間
             xxca.tax_div                       tax_div,                          --消費税区分
             flv.attribute5                     tax_uchizei_flag,                 --内税フラグ
             avta.tax_rate                      tax_rate,                         --消費税率
             xchv.bill_tax_round_rule           bill_tax_round_rule,              --税金－端数処理
             avta.tax_code                      tax_code,                         --AR税コード
             xchv.cash_receiv_base_code         cash_receiv_base_code,            --入金拠点コード
             hnas.party_id                      party_id,                         --パーティID
             part.party_name                    party_name,                       --パーティ名（正式名称）
             xxca.sale_base_code                sale_base_code,                   --当月売上拠点コード
             xxca.past_sale_base_code           past_sale_base_code,              --前月売上拠点コード
             part.duns_number_c                 duns_number_c,                    --当月顧客ステータス
             xxca.past_customer_status          past_customer_status              --前月顧客ステータス
      FROM   xxcos_vd_digestion_hdrs   xsdh,    -- 消化ＶＤ用消化計算ヘッダテーブル
             xxcos_vd_digestion_lns    xsdl,    -- 消化ＶＤ用消化計算明細テーブル
             hz_cust_accounts          hnas,    -- 顧客マスタ
             xxcmm_cust_accounts       xxca,    -- 顧客アドオンマスタ
/* 2009/08/10 Ver1.19 Mod Start */
--             xxcfr_cust_hierarchy_v    xchv,    -- 顧客階層VIEW
             xxcos_cust_hierarchy_v    xchv,    -- 顧客階層VIEW
/* 2009/08/10 Ver1.19 Mod End   */
             ar_vat_tax_all_b          avta,    -- AR税金マスタ
             hz_parties                part,    -- 顧客マスタ
/* 2009/08/10 Ver1.19 Del Start */
--             fnd_application           fa,
--             fnd_lookup_types          flt,
/* 2009/08/10 Ver1.19 Del End   */
             fnd_lookup_values         flv,
             (
              SELECT hca.account_number  account_number         --顧客コード
              FROM   hz_cust_accounts    hca,                   --顧客マスタ
                     xxcmm_cust_accounts xca                    --顧客アドオン
              WHERE  hca.cust_account_id     = xca.customer_id  --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               = flt.application_id
--                             AND    flt.lookup_type                                 = flv.lookup_type
--                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 = ct_qct_cust_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_2
--                             AND    flv.start_date_active                          <= gd_delay_date
--                             AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
--                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                             AND    flv.language                                    = USERENV( 'LANG' )
--                             AND    flv.meaning                                     = hca.customer_class_code
                             FROM   fnd_lookup_values             flv
                             WHERE  flv.lookup_type    = ct_qct_cust_type
                             AND    flv.lookup_code    LIKE ct_qcc_digestion_code_2
                             AND    gd_delay_date      BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                       AND     NVL( flv.end_date_active, gd_delay_date )
                             AND    flv.enabled_flag   = ct_enabled_flag_yes
                             AND    flv.language       = ct_lang
                             AND    flv.meaning        = hca.customer_class_code
/* 2009/08/10 Ver1.19 Mod End */
                            ) --顧客マスタ.顧客区分 = 10(顧客)
              AND    EXISTS (SELECT hcae.account_number --拠点コード
                             FROM   hz_cust_accounts    hcae,
/* 2009/08/10 Ver1.19 Mod Start */
--                                    xxcmm_cust_accounts xcae
                                    xxcmm_cust_accounts xcae,
                                    fnd_lookup_values   flv
/* 2009/08/10 Ver1.19 Mod End   */
                             WHERE  hcae.cust_account_id = xcae.customer_id --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
/* 2009/08/10 Ver1.19 Mod Start */
--                             AND    EXISTS (SELECT flv.meaning
--                                            FROM   fnd_application               fa,
--                                                   fnd_lookup_types              flt,
--                                                   fnd_lookup_values             flv
--                                            WHERE  fa.application_id                               = flt.application_id
--                                            AND    flt.lookup_type                                 = flv.lookup_type
--                                            AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                                            AND    flv.lookup_type                                 = ct_qct_cust_type
--                                            AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_1
--                                            AND    flv.start_date_active                          <= gd_delay_date
--                                            AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
--                                            AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                                            AND    flv.language                                    = USERENV( 'LANG' )
--                                            AND    flv.meaning                                     = hcae.customer_class_code
--                                           ) --顧客マスタ.顧客区分 = 1(拠点)
--                             AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
--                                             --顧客顧客アドオン.管理元拠点コード = INパラ(拠点コード)
                             AND    flv.lookup_type      = ct_qct_cust_type
                             AND    flv.lookup_code      LIKE ct_qcc_digestion_code_1
                             AND    gd_delay_date        BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                         AND     NVL( flv.end_date_active, gd_delay_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = hcae.customer_class_code
                             AND    (
                                      ( iv_base_code IS NULL )
                                      OR
                                      ( iv_base_code IS NOT NULL AND xcae.management_base_code = iv_base_code )
                                    ) --顧客顧客アドオン.管理元拠点コード = INパラ(拠点コード)
/* 2009/08/10 Ver1.19 Mod End   */
                             AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                            ) --管理拠点に所属する拠点コード = 顧客アドオン.前月拠点or売上拠点
/* 2009/08/10 Ver1.19 Mod Start */
--              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード = INパラ(顧客コード)
              AND    (
                       ( iv_customer_number IS NULL )
                       OR
                       ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                     ) --顧客コード = INパラ(顧客コード)
/* 2009/08/10 Ver1.19 Mod End   */
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_d_code
--                             AND    flv.start_date_active                          <=    gd_delay_date
--                             AND    NVL( flv.end_date_active, gd_delay_date )      >=    gd_delay_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning = xca.business_low_type
                             FROM   fnd_lookup_values             flv
                             WHERE  flv.lookup_type    = ct_qct_gyo_type
                             AND    flv.lookup_code    LIKE ct_qcc_d_code
                             AND    gd_delay_date      BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                       AND     NVL( flv.end_date_active, gd_delay_date )
                             AND    flv.enabled_flag   = ct_enabled_flag_yes
                             AND    flv.language       = ct_lang
                             AND    flv.meaning        = xca.business_low_type
/* 2009/08/10 Ver1.19 Mod End */
                            )  --業態小分類 = 消化・VD消化
              UNION
              SELECT hca.account_number  account_number         --顧客コード
              FROM   hz_cust_accounts    hca,                   --顧客マスタ
                     xxcmm_cust_accounts xca                    --顧客アドオン
              WHERE  hca.cust_account_id     = xca.customer_id  --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               = flt.application_id
--                             AND    flt.lookup_type                                 = flv.lookup_type
--                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 = ct_qct_cust_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_2
--                             AND    flv.start_date_active                          <= gd_delay_date
--                             AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
--                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                             AND    flv.language                                    = USERENV( 'LANG' )
--                             AND    flv.meaning                                     = hca.customer_class_code
                             FROM   fnd_lookup_values             flv
                             WHERE  flv.lookup_type    = ct_qct_cust_type
                             AND    flv.lookup_code    LIKE ct_qcc_digestion_code_2
                             AND    gd_delay_date      BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                       AND     NVL( flv.end_date_active, gd_delay_date )
                             AND    flv.enabled_flag   = ct_enabled_flag_yes
                             AND    flv.language       = ct_lang
                             AND    flv.meaning        = hca.customer_class_code
/* 2009/08/10 Ver1.19 Mod End   */
                            ) --顧客マスタ.顧客区分 = 10(顧客)
              AND    (
                      xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                      OR
                      xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                     ) --顧客アドオン.前月拠点or売上拠点 = INパラ(拠点コード)
/* 2009/08/10 Ver1.19 Mod Start */
--              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード = INパラ(顧客コード)
              AND    (
                       ( iv_customer_number IS NULL )
                       OR
                       ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                     ) --顧客コード = INパラ(顧客コード)
/* 2009/08/10 Ver1.19 Mod End   */
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_d_code
--                             AND    flv.start_date_active                          <=    gd_delay_date
--                             AND    NVL( flv.end_date_active, gd_delay_date )      >=    gd_delay_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning = xca.business_low_type
                             FROM   fnd_lookup_values             flv
                             WHERE  flv.lookup_type     = ct_qct_gyo_type
                             AND    flv.lookup_code     LIKE ct_qcc_d_code
                             AND    gd_delay_date       BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                        AND     NVL( flv.end_date_active, gd_delay_date )
                             AND    flv.enabled_flag    = ct_enabled_flag_yes
                             AND    flv.language        = ct_lang
                             AND    flv.meaning         = xca.business_low_type
/* 2009/08/10 Ver1.19 Mod End   */
                            )  --業態小分類 = 消化・VD消化
             ) amt
      WHERE  amt.account_number = xsdh.customer_number                    --ヘッダ.顧客コード           = 取得した顧客コード
      AND    xsdh.vd_digestion_hdr_id        = xsdl.vd_digestion_hdr_id   --ヘッダ.ヘッダID             = 明細.ヘッダID
      AND    xsdh.sales_result_creation_flag = ct_make_flag_no            --ヘッダ.販売実績作成済フラグ = 'N'
      AND    xsdh.uncalculate_class          = ct_un_calc_flag_0          --ヘッダ.未計算区分           = 0
      AND    xsdh.digestion_due_date        <= gd_delay_date              --ヘッダ.消化計算締年月日    <= 業務日付－猶予日数
      AND    xsdh.cust_account_id            = hnas.cust_account_id       --ヘッダ.顧客ID               = 顧客マスタ.顧客ID
      AND    hnas.cust_account_id            = xxca.customer_id           --顧客マスタ.顧客ID           = アドオン.顧客ID
      AND    xxca.tax_div                    = flv.attribute3             --顧客マスタ. 消費税区分      = 税コード特定マスタ.LOOKUPコード
      AND    flv.attribute2                  = avta.tax_code              --税コード特定マスタ.DFF2     = AR税金マスタ.税コード
      AND    avta.set_of_books_id            = gn_gl_id                   --AR税金マスタ.セットブックス = GL会計帳簿ID
      AND    avta.start_date                <= xsdh.digestion_due_date                --AR税金マスタ.開始日 <= 消化ＶＤ用消化計算ヘッダ.消化計算締年月日
      AND    NVL( avta.end_date, xsdh.digestion_due_date ) >= xsdh.digestion_due_date --AR税金マスタ.終了日 >= 消化ＶＤ用消化計算ヘッダ.消化計算締年月日
      AND    avta.enabled_flag               = ct_tax_enabled_yes         --AR税金マスタ.有効           = 'Y'
      AND    xsdh.cust_account_id            = xchv.ship_account_id       --ヘッダ.顧客ID               = 顧客階層VIEW.出荷先顧客ID
      AND    xsdh.customer_number            = NVL( iv_customer_number,xsdh.customer_number )
                                                                          --消化ＶＤ用消化計算ヘッダ.顧客コード = INパラ(顧客コード)
/* 2009/08/10 Ver1.19 Mod Start */
--      AND    fa.application_id               = flt.application_id
--      AND    flt.lookup_type                 = flv.lookup_type
--      AND    fa.application_short_name       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                 = ct_qct_tax_type2
--      AND    flv.start_date_active          <= xsdh.digestion_due_date
--      AND    NVL( flv.end_date_active, xsdh.digestion_due_date ) >= xsdh.digestion_due_date
--      AND    flv.enabled_flag                = ct_enabled_flag_yes
--      AND    flv.language                    = USERENV( 'LANG' )
      AND    flv.lookup_type                 = ct_qct_tax_type2
      AND    xsdh.digestion_due_date         BETWEEN NVL( flv.start_date_active, xsdh.digestion_due_date )
                                             AND     NVL( flv.end_date_active, xsdh.digestion_due_date )
      AND    flv.enabled_flag                = ct_enabled_flag_yes
      AND    flv.language                    = ct_lang
/* 2009/08/10 Ver1.19 Mod End   */
      AND    hnas.party_id                   = part.party_id               --顧客マスタ.顧客ID = 顧客マスタ.顧客ID
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
      AND    xsdl.sales_quantity            != cn_0
      AND   NOT EXISTS(
                        SELECT flv.lookup_code               not_inv_code
/* 2009/08/10 Ver1.19 Mod Start */
--                        FROM   fnd_application               fa,
--                               fnd_lookup_types              flt,
--                               fnd_lookup_values             flv
--                        WHERE  fa.application_id                               = flt.application_id
--                        AND    flt.lookup_type                                 = flv.lookup_type
--                        AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                        AND    flv.lookup_type                                 = ct_qct_not_inv_type
--                        AND    flv.start_date_active                          <=    gd_business_date
--                        AND    NVL( flv.end_date_active, gd_business_date )   >=    gd_business_date
--                        AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                        AND    flv.language                                    = USERENV( 'LANG' )
--                        AND    flv.lookup_code                                 = xsdl.item_code
                        FROM   fnd_lookup_values             flv
                        WHERE  flv.lookup_type    = ct_qct_not_inv_type
                        AND    gd_business_date   BETWEEN NVL( flv.start_date_active, gd_business_date )
                                                  AND     NVL( flv.end_date_active, gd_business_date )
                        AND    flv.enabled_flag   = ct_enabled_flag_yes
                        AND    flv.language       = ct_lang
                        AND    flv.lookup_code    = xsdl.item_code
/* 2009/08/10 Ver1.19 Mod End   */
                      )
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
      ORDER BY xsdh.vd_digestion_hdr_id,xsdl.vd_digestion_ln_id
      ;
    --随時用
    CURSOR get_data_cur2
    IS
/* 2009/08/10 Ver1.19 Mod Start */
--      SELECT xsdh.vd_digestion_hdr_id           vd_digestion_hdr_id,              --消化ＶＤ用消化計算ヘッダID
/* 2009/09/14 Ver1.20 Mod Start */
--      SELECT /*+
--               LEADING(xsdh)
--               INDEX(xsdh xxcos_shop_digestion_hdrs_n04)
--               INDEX(xxca xxcmm_cust_accounts_pk)
--               USE_NL(xchv.cust_hier.cash_hcar_3)
--               USE_NL(xchv.cust_hier.bill_hasa_3)
--               USE_NL(xchv.cust_hier.bill_hasa_4)
--               USE_NL(flv xxca)
--             */
      SELECT /*+
               LEADING(xsdh)
               INDEX(xsdh xxcos_vd_digestion_hdrs_n04)
               INDEX(xxca xxcmm_cust_accounts_pk)
               INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u1)
               INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u1)
               INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u1)
               INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u1)
               USE_NL(xchv.cust_hier.cash_hcar_3)
               USE_NL(xchv.cust_hier.bill_hasa_3)
               USE_NL(xchv.cust_hier.bill_hasa_4)
               USE_NL(flv xxca)
             */
/* 2009/09/14 Ver1.20 Mod End   */
             xsdh.vd_digestion_hdr_id           vd_digestion_hdr_id,              --消化ＶＤ用消化計算ヘッダID
/* 2009/08/10 Ver1.19 Mod End   */
             xsdh.customer_number               customer_number,                  --顧客コード
             xsdh.digestion_due_date            digestion_due_date,               --消化計算締年月日
             xsdh.cust_account_id               cust_account_id,                  --顧客ID
             xsdh.digestion_exe_date            digestion_exe_date,               --消化計算実行日
             xsdh.ar_sales_amount               ar_sales_amount,                  --売上金額
             xsdh.sales_amount                  sales_amount,                     --販売金額
             xsdh.digestion_calc_rate           digestion_calc_rate,              --消化計算掛率
             xsdh.master_rate                   master_rate,                      --マスタ掛率
             xsdh.balance_amount                balance_amount,                   --差額
             xsdh.cust_gyotai_sho               cust_gyotai_sho,                  --業態小分類
             xsdh.tax_amount                    tax_amount,                       --消費税額
             xsdh.delivery_date                 delivery_date,                    --納品日
             xsdh.dlv_time                      dlv_time,                         --時間
             xsdh.sales_result_creation_date    sales_result_creation_date,       --販売実績登録日
             xsdh.sales_result_creation_flag    sales_result_creation_flag,       --販売実績作成済フラグ
             xsdh.pre_digestion_due_date        pre_digestion_due_date,           --前回消化計算締年月日
             xsdh.uncalculate_class             uncalculate_class,                --未計算区分
             xsdh.change_out_time_100           change_out_time_100,              --つり銭切れ時間100円
             xsdh.change_out_time_10            change_out_time_10,               --つり銭切れ時間10円
             xsdl.vd_digestion_ln_id            vd_digestion_ln_id,               --消化ＶＤ用消化計算明細ID
             xsdl.digestion_ln_number           digestion_ln_number,              --枝番
             xsdl.item_code                     item_code,                        --品目コード
             xsdl.inventory_item_id             inventory_item_id,                --品目ID
             xsdl.item_price                    item_price,                       --定価
             xsdl.unit_price                    unit_price,                       --単価
             xsdl.item_sales_amount             item_sales_amount,                --品目別販売金額
             xsdl.uom_code                      uom_code,                         --単位コード
             xsdl.sales_quantity                sales_quantity,                   --販売数
             xsdl.hot_cold_type                 hot_cold_type,                    --H/C
             xsdl.column_no                     column_no,                        --コラムNo
             xsdl.delivery_base_code            delivery_base_code,               --納品拠点コード
             xsdl.ship_from_subinventory_code   ship_from_subinventory_code,      --出荷元保管場所
             xsdl.sold_out_class                sold_out_class,                   --売切区分
             xsdl.sold_out_time                 sold_out_time,                    --売切時間
             xxca.tax_div                       tax_div,                          --消費税区分
             flv.attribute5                     tax_uchizei_flag,                 --内税フラグ
             avta.tax_rate                      tax_rate,                         --消費税率
             xchv.bill_tax_round_rule           bill_tax_round_rule,              --税金－端数処理
             avta.tax_code                      tax_code,                         --AR税コード
             xchv.cash_receiv_base_code         cash_receiv_base_code,            --入金拠点コード
             hnas.party_id                      party_id,                         --パーティID
             part.party_name                    party_name,                       --パーティ名（正式名称）
             xxca.sale_base_code                sale_base_code,                   --当月売上拠点コード
             xxca.past_sale_base_code           past_sale_base_code,              --前月売上拠点コード
             part.duns_number_c                 duns_number_c,                    --当月顧客ステータス
             xxca.past_customer_status          past_customer_status              --前月顧客ステータス
      FROM   xxcos_vd_digestion_hdrs   xsdh,    -- 消化ＶＤ用消化計算ヘッダテーブル
             xxcos_vd_digestion_lns    xsdl,    -- 消化ＶＤ用消化計算明細テーブル
             hz_cust_accounts          hnas,    -- 顧客マスタ
             xxcmm_cust_accounts       xxca,    -- 顧客アドオンマスタ
/* 2009/08/10 Ver1.19 Mod Start */
--             xxcfr_cust_hierarchy_v    xchv,    -- 顧客階層VIEW
             xxcos_cust_hierarchy_v    xchv,    -- 顧客階層VIEW
/* 2009/08/10 Ver1.19 Mod End   */
             ar_vat_tax_all_b          avta,    -- AR税金マスタ
             hz_parties                part,    -- 顧客マスタ
/* 2009/08/10 Ver1.19 Del Start */
--             fnd_application           fa,
--             fnd_lookup_types          flt,
/* 2009/08/10 Ver1.19 Del End   */
             fnd_lookup_values         flv,
             (
              SELECT hca.account_number  account_number         --顧客コード
              FROM   hz_cust_accounts    hca,                   --顧客マスタ
                     xxcmm_cust_accounts xca                    --顧客アドオン
              WHERE  hca.cust_account_id     = xca.customer_id  --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               = flt.application_id
--                             AND    flt.lookup_type                                 = flv.lookup_type
--                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 = ct_qct_cust_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_2
--                             AND    flv.start_date_active                          <= gd_business_date
--                             AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
--                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                             AND    flv.language                                    = USERENV( 'LANG' )
--                             AND    flv.meaning                                     = hca.customer_class_code
                             FROM   fnd_lookup_values             flv
                             WHERE  flv.lookup_type    = ct_qct_cust_type
                             AND    flv.lookup_code    LIKE ct_qcc_digestion_code_2
                             AND    gd_business_date   BETWEEN NVL( flv.start_date_active, gd_business_date )
                                                       AND     NVL( flv.end_date_active, gd_business_date )
                             AND    flv.enabled_flag   = ct_enabled_flag_yes
                             AND    flv.language       = ct_lang
                             AND    flv.meaning        = hca.customer_class_code
/* 2009/08/10 Ver1.19 Mod End   */
                            ) --顧客マスタ.顧客区分 = 10(顧客)
              AND    EXISTS (SELECT hcae.account_number --拠点コード
                             FROM   hz_cust_accounts    hcae,
/* 2009/08/10 Ver1.19 Mod Start */
--                                    xxcmm_cust_accounts xcae
                                    xxcmm_cust_accounts xcae,
                                    fnd_lookup_values   flv
/* 2009/08/10 Ver1.19 Mod End   */
                             WHERE  hcae.cust_account_id = xcae.customer_id --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
/* 2009/08/10 Ver1.19 Mod Start */
--                             AND    EXISTS (SELECT flv.meaning
--                                            FROM   fnd_application               fa,
--                                                   fnd_lookup_types              flt,
--                                                   fnd_lookup_values             flv
--                                            WHERE  fa.application_id                               = flt.application_id
--                                            AND    flt.lookup_type                                 = flv.lookup_type
--                                            AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                                            AND    flv.lookup_type                                 = ct_qct_cust_type
--                                            AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_1
--                                            AND    flv.start_date_active                          <= gd_business_date
--                                            AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
--                                            AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                                            AND    flv.language                                    = USERENV( 'LANG' )
--                                            AND    flv.meaning                                     = hcae.customer_class_code
--                                           ) --顧客マスタ.顧客区分 = 1(拠点)
--                             AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
--                                             --顧客顧客アドオン.管理元拠点コード = INパラ(拠点コード)
                             AND    flv.lookup_type      = ct_qct_cust_type
                             AND    flv.lookup_code      LIKE ct_qcc_digestion_code_1
                             AND    gd_business_date     BETWEEN NVL( flv.start_date_active, gd_business_date)
                                                         AND     NVL( flv.end_date_active, gd_business_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = hcae.customer_class_code
                             AND    (
                                      ( iv_base_code IS NULL )
                                      OR
                                      ( iv_base_code IS NOT NULL AND xcae.management_base_code = iv_base_code )
                                    ) --顧客顧客アドオン.管理元拠点コード = INパラ(拠点コード)
/* 2009/08/10 Ver1.19 Mod End   */
                             AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                            ) --管理拠点に所属する拠点コード = 顧客アドオン.前月拠点or売上拠点
/* 2009/08/10 Ver1.19 Mod Start */
--              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード = INパラ(顧客コード)
              AND    (
                       ( iv_customer_number IS NULL )
                       OR
                       ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                     ) --顧客コード = INパラ(顧客コード)
/* 2009/08/10 Ver1.19 Mod End   */
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_d_code
--                             AND    flv.start_date_active                          <=    gd_business_date
--                             AND    NVL( flv.end_date_active, gd_business_date )   >=    gd_business_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning = xca.business_low_type
                             FROM   fnd_lookup_values             flv
                             WHERE  flv.lookup_type    = ct_qct_gyo_type
                             AND    flv.lookup_code    LIKE ct_qcc_d_code
                             AND    gd_business_date   BETWEEN NVL( flv.start_date_active, gd_business_date )
                                                       AND     NVL( flv.end_date_active, gd_business_date )
                             AND    flv.enabled_flag   = ct_enabled_flag_yes
                             AND    flv.language       = ct_lang
                             AND    flv.meaning        = xca.business_low_type
/* 2009/08/10 Ver1.19 Mod End   */
                            )  --業態小分類 = 消化・VD消化
              UNION
              SELECT hca.account_number  account_number         --顧客コード
              FROM   hz_cust_accounts    hca,                   --顧客マスタ
                     xxcmm_cust_accounts xca                    --顧客アドオン
              WHERE  hca.cust_account_id     = xca.customer_id  --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               = flt.application_id
--                             AND    flt.lookup_type                                 = flv.lookup_type
--                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 = ct_qct_cust_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_digestion_code_2
--                             AND    flv.start_date_active                          <= gd_business_date
--                             AND    NVL( flv.end_date_active, gd_business_date )   >= gd_business_date
--                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                             AND    flv.language                                    = USERENV( 'LANG' )
--                             AND    flv.meaning                                     = hca.customer_class_code
                             FROM   fnd_lookup_values             flv
                             WHERE  flv.lookup_type    = ct_qct_cust_type
                             AND    flv.lookup_code    LIKE ct_qcc_digestion_code_2
                             AND    gd_business_date   BETWEEN NVL( flv.start_date_active, gd_business_date )
                                                       AND     NVL( flv.end_date_active, gd_business_date )
                             AND    flv.enabled_flag   = ct_enabled_flag_yes
                             AND    flv.language       = ct_lang
                             AND    flv.meaning        = hca.customer_class_code
/* 2009/08/10 Ver1.19 Mod End   */
                            ) --顧客マスタ.顧客区分 = 10(顧客)
              AND    (
                      xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                      OR
                      xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                     ) --顧客アドオン.前月拠点or売上拠点 = INパラ(拠点コード)
/* 2009/08/10 Ver1.19 Mod Start */
--              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード = INパラ(顧客コード)
              AND    (
                       ( iv_customer_number IS NULL )
                       OR
                       ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                     ) --顧客コード = INパラ(顧客コード)
/* 2009/08/10 Ver1.19 Mod End   */
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_d_code
--                             AND    flv.start_date_active                          <=    gd_business_date
--                             AND    NVL( flv.end_date_active, gd_business_date )   >=    gd_business_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning = xca.business_low_type
                             FROM   fnd_lookup_values             flv
                             WHERE  flv.lookup_type    = ct_qct_gyo_type
                             AND    flv.lookup_code    LIKE ct_qcc_d_code
                             AND    gd_business_date   BETWEEN NVL( flv.start_date_active, gd_business_date )
                                                       AND     NVL( flv.end_date_active, gd_business_date )
                             AND    flv.enabled_flag   = ct_enabled_flag_yes
                             AND    flv.language       = ct_lang
                             AND    flv.meaning        = xca.business_low_type
/* 2009/08/10 Ver1.19 Mod End   */
                            )  --業態小分類 = 消化・VD消化
             ) amt
      WHERE  amt.account_number = xsdh.customer_number                    --ヘッダ.顧客コード           = 取得した顧客コード
      AND    xsdh.vd_digestion_hdr_id        = xsdl.vd_digestion_hdr_id   --ヘッダ.ヘッダID             = 明細.ヘッダID
      AND    xsdh.sales_result_creation_flag = ct_make_flag_no            --ヘッダ.販売実績作成済フラグ = 'N'
      AND    xsdh.uncalculate_class          = ct_un_calc_flag_0          --ヘッダ.未計算区分           = 0
      AND    xsdh.cust_account_id            = hnas.cust_account_id       --ヘッダ.顧客ID               = 顧客マスタ.顧客ID
      AND    hnas.cust_account_id            = xxca.customer_id           --顧客マスタ.顧客ID           = アドオン.顧客ID
      AND    xxca.tax_div                    = flv.attribute3             --顧客マスタ. 消費税区分      = 税コード特定マスタ.LOOKUPコード
      AND    flv.attribute2                  = avta.tax_code              --税コード特定マスタ.DFF2     = AR税金マスタ.税コード
      AND    avta.set_of_books_id            = gn_gl_id                   --AR税金マスタ.セットブックス = GL会計帳簿ID
      AND    avta.start_date                <= xsdh.digestion_due_date                --AR税金マスタ.開始日 <= 消化ＶＤ用消化計算ヘッダ.消化計算締年月日
      AND    NVL( avta.end_date, xsdh.digestion_due_date ) >= xsdh.digestion_due_date --AR税金マスタ.終了日 >= 消化ＶＤ用消化計算ヘッダ.消化計算締年月日
      AND    avta.enabled_flag               = ct_tax_enabled_yes         --AR税金マスタ.有効           = 'Y'
      AND    xsdh.cust_account_id            = xchv.ship_account_id       --ヘッダ.顧客ID               = 顧客階層VIEW.出荷先顧客ID
      AND    xsdh.customer_number            = NVL( iv_customer_number,xsdh.customer_number )
                                                                          --消化ＶＤ用消化計算ヘッダ.顧客コード = INパラ(顧客コード)
/* 2009/08/10 Ver1.19 Mod Start */
--      AND    fa.application_id               = flt.application_id
--      AND    flt.lookup_type                 = flv.lookup_type
--      AND    fa.application_short_name       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                 = ct_qct_tax_type2
--      AND    flv.start_date_active          <= xsdh.digestion_due_date
--      AND    NVL( flv.end_date_active, xsdh.digestion_due_date ) >= xsdh.digestion_due_date
--      AND    flv.enabled_flag                = ct_enabled_flag_yes
--      AND    flv.language                    = USERENV( 'LANG' )
      AND    flv.lookup_type                 = ct_qct_tax_type2
      AND    xsdh.digestion_due_date         BETWEEN NVL( flv.start_date_active, xsdh.digestion_due_date )
                                             AND     NVL( flv.end_date_active, xsdh.digestion_due_date )
      AND    flv.enabled_flag                = ct_enabled_flag_yes
      AND    flv.language                    = ct_lang
/* 2009/08/10 Ver1.19 Mod End   */
      AND    hnas.party_id                   = part.party_id               --顧客マスタ.顧客ID = 顧客マスタ.顧客ID
 --****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
      AND    xsdl.sales_quantity            != cn_0
      AND   NOT EXISTS(
                        SELECT flv.lookup_code               not_inv_code
/* 2009/08/10 Ver1.19 Mod Start */
--                        FROM   fnd_application               fa,
--                               fnd_lookup_types              flt,
--                               fnd_lookup_values             flv
--                        WHERE  fa.application_id                               = flt.application_id
--                        AND    flt.lookup_type                                 = flv.lookup_type
--                        AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                        AND    flv.lookup_type                                 = ct_qct_not_inv_type
--                        AND    flv.start_date_active                          <=    gd_business_date
--                        AND    NVL( flv.end_date_active, gd_business_date )   >=    gd_business_date
--                        AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                        AND    flv.language                                    = USERENV( 'LANG' )
--                        AND    flv.lookup_code                                 = xsdl.item_code
                        FROM   fnd_lookup_values             flv
                        WHERE  flv.lookup_type    = ct_qct_not_inv_type
                        AND    gd_business_date   BETWEEN NVL( flv.start_date_active, gd_business_date )
                                                  AND     NVL( flv.end_date_active, gd_business_date )
                        AND    flv.enabled_flag   = ct_enabled_flag_yes
                        AND    flv.language       = ct_lang
                        AND    flv.lookup_code    = xsdl.item_code
/* 2009/08/10 Ver1.19 Mod End   */
                      )
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
     ORDER BY xsdh.vd_digestion_hdr_id,xsdl.vd_digestion_ln_id
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
     FOR UPDATE OF xsdh.vd_digestion_hdr_id,xsdl.vd_digestion_ln_id NOWAIT
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
      ;
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
    --対象データ取得用カーソルOPEN
    BEGIN
      --定期の場合
      IF ( iv_exec_div = cv_1 ) THEN
        OPEN get_data_cur1;
        -- バルクフェッチ
        FETCH get_data_cur1 BULK COLLECT INTO gt_tab_work_data;
        --取得件数
        gn_target_cnt := get_data_cur1%ROWCOUNT;
        -- カーソルCLOSE
        CLOSE get_data_cur1;
      --随時の場合
      ELSIF ( iv_exec_div = cv_0 ) THEN
        OPEN get_data_cur2;
        -- バルクフェッチ
        FETCH get_data_cur2 BULK COLLECT INTO gt_tab_work_data;
        --取得件数
        gn_target_cnt := get_data_cur2%ROWCOUNT;
        -- カーソルCLOSE
        CLOSE get_data_cur2;
      END IF;
    EXCEPTION
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
      WHEN global_data_lock_expt THEN
        -- カーソルCLOSE：納品ヘッダワークテーブルデータ取得
        IF ( get_data_cur1%ISOPEN ) THEN
          CLOSE get_data_cur1;
        END IF;
        IF ( get_data_cur2%ISOPEN ) THEN
          CLOSE get_data_cur2;
        END IF;
        RAISE global_data_lock_expt;
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
      WHEN OTHERS THEN
        -- カーソルCLOSE：納品ヘッダワークテーブルデータ取得
        IF ( get_data_cur1%ISOPEN ) THEN
          CLOSE get_data_cur1;
        END IF;
        IF ( get_data_cur2%ISOPEN ) THEN
          CLOSE get_data_cur2;
        END IF;
        --
        RAISE global_select_err_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --抽出対象が0件だった場合
    IF ( gn_target_cnt = cn_0 ) THEN
      RAISE global_no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象データ０件エラー ***
    WHEN global_no_data_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  cv_msg_nodata_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--****************************** 2009/04/20 1.11 T.kitajima MOD START ******************************--
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
--****************************** 2009/04/20 1.11 T.kitajima MOD  END  ******************************--
    -- *** SQL SELECT エラー ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  cv_msg_select_vd_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
--
    -- *** ロック エラー ***
    WHEN global_data_lock_expt     THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_line_lock_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
--#####################################  固定部 START ##########################################
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
  END get_object_data;
--
  /**********************************************************************************
   * Procedure Name   : calc_sales
   * Description      : 納品データ計算処理(A-4)
   ***********************************************************************************/
  PROCEDURE calc_sales(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_sales'; -- プログラム名
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
    ln_i                   NUMBER;        --カウンター
    ln_m                   NUMBER;        --明細カウンター
    ln_h                   NUMBER;        --ヘッダカウンター
    ln_delete_start_index  NUMBER;        --削除開始ポイントINDEX一時保管
    ln_index               NUMBER;        --INDEX一時保管
    lv_err_work            VARCHAR2(1);   --エラーワーク
    lv_organization_code   VARCHAR2(10);  --在庫組織コード
    lv_organization_id     NUMBER;        --在庫組織ＩＤ
--****************************** 2009/04/21 1.12 T.Kitajima DEL START ******************************--
--    lv_delivered_from      VARCHAR2(1);   --納品形態
--****************************** 2009/04/21 1.12 T.Kitajima DEL  END  ******************************--
    ln_inventory_item_id   NUMBER;        --品目ＩＤ
    lv_after_uom_code      VARCHAR2(10);  --換算後単位コード
    ln_after_quantity      NUMBER;        --換算後数量
    ln_content             NUMBER;        --品入数
    ln_amount_work_total   NUMBER;        --消化計算掛率済み品目別販売合計金額
--****************************** 2009/04/27 1.13 N.Maeda    ADD START ******************************--
    ln_tax_work_total      NUMBER;        --明細消費税額合計
    ln_amount_work_data    NUMBER;        -- 本体金額合計
    ln_count_data          NUMBER := 0;
--****************************** 2009/04/27 1.13 N.Maeda    ADD  END  ******************************--
    ln_header_id           NUMBER;        --ヘッダID
    ln_line_id             NUMBER;        --明細ID
    ln_difference_money    NUMBER;        --差異金額
    lv_deli_seq            VARCHAR2(12);  --納品伝票番号
    ld_base_date           DATE;          --基準日
    lv_status              VARCHAR2(10);  --ステータス
    ld_from_date           DATE;          --会計(FROM)
    ld_to_date             DATE;          --会計(TO)
    ln_amount_work         NUMBER;        --売上金額計算WORK
    ln_amount_work_max     NUMBER;        --最大売上金額計算WORK
    ln_tax_work            NUMBER;        --消費税金額計算WORK
    ln_tax_work_calccomp   NUMBER;        --消費税金額計算WORK（計算完了）
    ln_i_max               NUMBER;        --テーブル変数から読み込んだ最大売上金額を持つレコードの一時保管インデックス
    ln_m_max               NUMBER;        --テーブル変数に書き出した最大売上金額を持つレコードの一時保管インデックス
    lv_discrete_cost       VARCHAR2(12);  --営業原価
    ln_err_line_flag       NUMBER;        --エラー明細フラグ
    lt_performance_by_code xxcos_shop_digestion_hdrs.performance_by_code%TYPE; --成績者コード
    lt_resource_id         jtf_rs_resource_extns.resource_id%TYPE;             --リソースID
--**************************** 2009/03/23 1.9  T.kitajima ADD START ****************************
    lt_ship_from_subinventory_code xxcos_vd_digestion_lns.ship_from_subinventory_code%TYPE; --出荷元保管場所
    lt_delivery_base_code          xxcos_vd_digestion_lns.delivery_base_code%TYPE;          --納品拠点コード
--**************************** 2009/03/23 1.9  T.kitajima ADD  END  ****************************
--**************************** 2009/03/30 1.10 T.kitajima ADD START ****************************
    ln_line_index          NUMBER;        --納品明細番号
--**************************** 2009/03/30 1.10 T.kitajima ADD  END  ****************************
--**************************** 2009/04/27 1.13 T.kitajima ADD START ****************************
    ln_amount_data         NUMBER;        -- 本体金額一時格納用
--**************************** 2009/04/27 1.13 T.kitajima ADD  END  ****************************
    lv_out_msg             VARCHAR(5000);
/* 2010/01/12 Ver1.22 Add Start */
    ln_tax_amount_total          NUMBER;     -- 税額合計(明細)
    ln_ar_tax_total              NUMBER;     -- AR税金額合計
    ln_tax_rounding_af           NUMBER;     -- 端数処理後の税額
    ln_max_tax                   NUMBER;     -- 最大の消化計算掛率済み品目別販売金額の税額
    ln_difference_tax            NUMBER;     -- 税額差額
    ln_pure_amount_total         NUMBER;
    ln_diff_pure_amount          NUMBER;
/* 2010/01/12 Ver1.22 Add End */
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
    --初期化
    ln_m                   := cn_1;
    ln_h                   := cn_1;
/* 2010/01/12 Ver1.22 Add Start */
    ln_tax_amount_total  := cn_0;
    ln_pure_amount_total := cn_0;
/* 2010/01/12 Ver1.22 Add End */
    ln_amount_work_total   := cn_0;
--****************************** 2009/04/27 1.13 N.Maeda    ADD START ******************************--
    ln_tax_work_total      := cn_0;
    ln_amount_work_data    := cn_0;
--****************************** 2009/04/27 1.13 N.Maeda    ADD  END  ******************************--
    ln_difference_money    := cn_0;
    lv_err_work            := cv_status_normal;
    ln_delete_start_index  := cn_1;
    ln_index               := cn_1;
    ln_amount_work_max     := null;
    ln_err_line_flag       := cn_0;
    ln_line_index          := 1;
    --ヘッダシーケンス取得
    SELECT xxcos_sales_exp_headers_s01.nextval
    INTO   ln_header_id
    FROM   DUAL;
    --納品伝票番号シーケンス取得
--******************************* 2009/06/10 1.16 T.Kitajima MOD START ******************************--
--    lv_deli_seq := xxcos_def_pkg.set_order_number( NULL,NULL );
    SELECT cv_snq_i || TO_CHAR( ( lpad( XXCOS_CUST_PO_NUMBER_S01.nextval, 11, 0) ) )
      INTO lv_deli_seq
      FROM dual;
--******************************* 2009/06/10 1.16 T.Kitajima MOD  END  ******************************--
    -- ループ開始
    <<keisan_loop>>
    FOR ln_i IN 1..gn_target_cnt LOOP
--
      --正常時のみ納品形態、単位換算を行う。
      IF ( lv_err_work = cv_status_normal ) THEN
--**************************** 2009/03/23 1.9  T.kitajima MOD START ****************************
--        --納品形態取得
--        xxcos_common_pkg.get_delivered_from(
--          gt_tab_work_data(ln_i).ship_from_subinventory_code,  --出荷元保管場所(IN)
--          gt_tab_work_data(ln_i).sale_base_code,               --売上拠点(IN)
--          gt_tab_work_data(ln_i).delivery_base_code,           --出荷拠点(IN)
--          lv_organization_code,                                --在庫組織コード(INOUT)
--          lv_organization_id,                                  --在庫組織ＩＤ(INOUT)
--          lv_delivered_from,                                   --納品形態(OUT)
--          lv_errbuf,                                           --エラー･メッセージ(OUT)
--          lv_retcode,                                          --リターンコード(OUT)
--          lv_errmsg                                            --ユーザ･エラー･メッセージ(OUT)
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          --取得エラー
--          lv_err_work     := cv_status_warn;
--          ov_errmsg       := xxccp_common_pkg.get_msg(
--                               iv_application        => ct_xxcos_appl_short_name,
--                               iv_name               => cv_msg_deli_err,
--                               iv_token_name1        => cv_tkn_parm_data1,
--                               iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                               iv_token_name2        => cv_tkn_parm_data2,
--                               iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                               iv_token_name3        => cv_tkn_parm_data3,
--                               iv_token_value3       => gt_tab_work_data(ln_i).ship_from_subinventory_code,
--                               iv_token_name4        => cv_tkn_parm_data4,
--                               iv_token_value4       => gt_tab_work_data(ln_i).sale_base_code,
--                               iv_token_name5        => cv_tkn_parm_data5,
--                               iv_token_value5       => gt_tab_work_data(ln_i).delivery_base_code
--                             );
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT,
--            buff   => ov_errmsg
--          );
--        ELSE
--          --単位換算より設定
--          --
--          lv_after_uom_code := NULL; --必ずNULLを設定しておくこと。
--          --
--          xxcos_common_pkg.get_uom_cnv(
--            gt_tab_work_data(ln_i).uom_code,        --換算前単位コード(IN)
--            gt_tab_work_data(ln_i).sales_quantity,  --換算前数量(IN)
--            gt_tab_work_data(ln_i).item_code,       --品目コード(INOUT)
--            lv_organization_code,                   --在庫組織コード(INOUT)
--            ln_inventory_item_id,                   --品目ID(INOUT)
--            lv_organization_id,                     --在庫組織ＩＤ(INOUT)
--            lv_after_uom_code,                      --換算後単位コード(INOUT)
--            ln_after_quantity,                      --換算後数量(OUT)
--            ln_content,                             --入数(OUT)
--            lv_errbuf,                              --エラー･メッセージ(OUT)
--            lv_retcode,                             --リターンコード(OUT)
--            lv_errmsg                               --ユーザ･エラー･メッセージ(OUT)
--          );
--          IF ( lv_retcode = cv_status_error ) THEN
--            --取得エラー
--            lv_err_work   := cv_status_warn;
--            ov_errmsg     := xxccp_common_pkg.get_msg(
--                               iv_application        => ct_xxcos_appl_short_name,
--                               iv_name               => cv_msg_tan_err,
--                               iv_token_name1        => cv_tkn_parm_data1,
--                               iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                               iv_token_name2        => cv_tkn_parm_data2,
--                               iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                               iv_token_name3        => cv_tkn_parm_data3,
--                               iv_token_value3       => gt_tab_work_data(ln_i).uom_code,
--                               iv_token_name4        => cv_tkn_parm_data4,
--                               iv_token_value4       => gt_tab_work_data(ln_i).sales_quantity,
--                               iv_token_name5        => cv_tkn_parm_data5,
--                               iv_token_value5       => gt_tab_work_data(ln_i).item_code
--                             );
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT,
--              buff   => ov_errmsg
--            );
--          ELSE
--            BEGIN
--              --営業原価を取得
--              SELECT
--                xsibh.discrete_cost                     discrete_cost                  --営業原価
--              INTO
--                lv_discrete_cost
--              FROM
--                (
--                  SELECT
--                    xsibh.discrete_cost                 discrete_cost                  --営業原価
--                  FROM
--                    xxcmm_system_items_b_hst          xsibh                            --品目営業履歴アドオンマスタ
--                  WHERE
--                    xsibh.item_code                    = gt_tab_work_data(ln_i).item_code
--                  AND xsibh.apply_date                <= gt_tab_work_data(ln_i).digestion_due_date
--                  AND xsibh.apply_flag                 = ct_apply_flag_yes
--                  AND xsibh.discrete_cost             IS NOT NULL
--                  ORDER BY
--                    xsibh.apply_date                  desc
--                ) xsibh
--              WHERE
--                ROWNUM                                = 1
--              ;
--            EXCEPTION
--              WHEN OTHERS THEN
--                lv_retcode := cv_status_error;
--            END;
--            IF ( lv_retcode = cv_status_error ) THEN
--              --取得エラー
--              lv_err_work   := cv_status_warn;
--              ov_errmsg     := xxccp_common_pkg.get_msg(
--                                 iv_application        => ct_xxcos_appl_short_name,
--                                 iv_name               => cv_msg_cost_err,
--                                 iv_token_name1        => cv_tkn_parm_data1,
--                                 iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                                 iv_token_name2        => cv_tkn_parm_data2,
--                                 iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                                 iv_token_name3        => cv_tkn_parm_data3,
--                                 iv_token_value3       => gt_tab_work_data(ln_i).item_code,
--                                 iv_token_name4        => cv_tkn_parm_data4,
--                                 iv_token_value4       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
--                               );
--              FND_FILE.PUT_LINE(
--                which  => FND_FILE.OUTPUT,
--                buff   => ov_errmsg
--              );
--            ELSE
--              --会計期間情報取得より設定
--              xxcos_common_pkg.get_account_period(
--                cv_inv,                                    --会計区分(IN)
--                gt_tab_work_data(ln_i).digestion_due_date, --基準日(IN)
--                lv_status,                                 --ステータス(OUT)
--                ld_from_date,                              --会計(FROM)(OUT)
--                ld_to_date,                                --会計(TO)(OUT)
--                lv_errbuf,                                 --エラー･メッセージ(OUT)
--                lv_retcode,                                --リターンコード(OUT)
--                lv_errmsg                                  --ユーザ･エラー･メッセージ(OUT)
--              );
--              IF ( lv_retcode = cv_status_error ) THEN
--                --取得エラー
--                lv_err_work   := cv_status_warn;
--                ov_errmsg     := xxccp_common_pkg.get_msg(
--                                   iv_application        => ct_xxcos_appl_short_name,
--                                   iv_name               => cv_msg_prd_err,
--                                   iv_token_name1        => cv_tkn_parm_data1,
--                                   iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                                   iv_token_name2        => cv_tkn_parm_data2,
--                                   iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                                   iv_token_name3        => cv_tkn_parm_data3,
--                                   iv_token_value3       => cv_inv,
--                                   iv_token_name4        => cv_tkn_parm_data4,
--                                   iv_token_value4       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
--                                 );
--                FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT,
--                  buff   => ov_errmsg
--                );
--              ELSE
--                IF ( lv_status <> cv_open ) THEN
--                  --会計期間情報取得より設定
--                  xxcos_common_pkg.get_account_period(
--                    cv_inv,           --会計区分(IN)
--                    NULL,             --基準日(IN)
--                    lv_status,        --ステータス(OUT)
--                    ld_from_date,     --会計(FROM)(OUT)
--                    ld_to_date,       --会計(TO)(OUT)
--                    lv_errbuf,        --エラー･メッセージ(OUT)
--                    lv_retcode,       --リターンコード(OUT)
--                    lv_errmsg         --ユーザ･エラー･メッセージ(OUT)
--                  );
--                  IF ( lv_retcode = cv_status_error ) THEN
--                    --取得エラー
--                    lv_err_work   := cv_status_warn;
--                    ov_errmsg     := xxccp_common_pkg.get_msg(
--                                       iv_application        => ct_xxcos_appl_short_name,
--                                       iv_name               => cv_msg_prd_err,
--                                       iv_token_name1        => cv_tkn_parm_data1,
--                                       iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                                       iv_token_name2        => cv_tkn_parm_data2,
--                                       iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                                       iv_token_name3        => cv_tkn_parm_data3,
--                                       iv_token_value3       => cv_inv,
--                                       iv_token_name4        => cv_tkn_parm_data4,
--                                       iv_token_value4       => NULL
--                                     );
--                    FND_FILE.PUT_LINE(
--                      which  => FND_FILE.OUTPUT,
--                      buff   => ov_errmsg
--                    );
--                  ELSE
--                    gt_tab_sales_exp_headers(ln_h).delivery_date := ld_from_date;                              --納品日
--                  END IF;
--                ELSE
--                  gt_tab_sales_exp_headers(ln_h).delivery_date   := gt_tab_work_data(ln_i).digestion_due_date; --納品日
--                END IF;
--                IF TRUNC(gt_tab_sales_exp_headers(ln_h).delivery_date, cv_mm ) = TRUNC( gd_business_date, cv_mm ) THEN --当月なら
--                  gt_tab_sales_exp_headers(ln_h).sales_base_code := gt_tab_work_data(ln_i).sale_base_code;      --当月売上拠点コード
--                  gt_tab_for_comfunc_inpara(ln_h).cust_status    := gt_tab_work_data(ln_i).duns_number_c;       --当月顧客ステータス(DFF14)
--                ELSE --前月なら
--                  gt_tab_sales_exp_headers(ln_h).sales_base_code := gt_tab_work_data(ln_i).past_sale_base_code;  --前月売上拠点コード
--                  gt_tab_for_comfunc_inpara(ln_h).cust_status    := gt_tab_work_data(ln_i).past_customer_status; --前月顧客ステータス(DFF14)
--                END IF;
--                --==================================
--                -- 営業担当員コード取得
--                --==================================
--                BEGIN
--                  SELECT xsv.employee_number,
--                         xsv.resource_id
--                    INTO lt_performance_by_code,
--                         lt_resource_id
--                    FROM xxcos_salesreps_v xsv
--                   WHERE xsv.party_id                                                                 = gt_tab_work_data(ln_i).party_id
--                     AND xsv.effective_start_date                                                    <= gt_tab_sales_exp_headers(ln_h).delivery_date
--                     AND NVL( xsv.effective_end_date, gt_tab_sales_exp_headers(ln_h).delivery_date ) >= gt_tab_sales_exp_headers(ln_h).delivery_date
--                  ;
--                EXCEPTION
--                  WHEN OTHERS THEN
--                    --取得エラー
--                    lv_err_work   := cv_status_warn;
--                    ov_errmsg     := xxccp_common_pkg.get_msg(
--                                       iv_application        => ct_xxcos_appl_short_name,
--                                       iv_name               => cv_msg_select_salesreps_err,
--                                       iv_token_name1        => cv_tkn_parm_data1,
--                                       iv_token_value1       => gt_tab_work_data(ln_i).customer_number
--                                     );
--                    FND_FILE.PUT_LINE(
--                      which  => FND_FILE.OUTPUT,
--                      buff   => ov_errmsg
--                    );
--                END;
--              END IF;
--            END IF;
--          END IF;
--        END IF;
        lv_after_uom_code := NULL; --必ずNULLを設定しておくこと。
        lt_ship_from_subinventory_code := NULL;
--
        --==================================
        -- 単位換算より設定
        --==================================
        xxcos_common_pkg.get_uom_cnv(
          gt_tab_work_data(ln_i).uom_code,        --換算前単位コード(IN)
          gt_tab_work_data(ln_i).sales_quantity,  --換算前数量(IN)
          gt_tab_work_data(ln_i).item_code,       --品目コード(INOUT)
          lv_organization_code,                   --在庫組織コード(INOUT)
          ln_inventory_item_id,                   --品目ID(INOUT)
          lv_organization_id,                     --在庫組織ＩＤ(INOUT)
          lv_after_uom_code,                      --換算後単位コード(INOUT)
          ln_after_quantity,                      --換算後数量(OUT)
          ln_content,                             --入数(OUT)
          lv_errbuf,                              --エラー･メッセージ(OUT)
          lv_retcode,                             --リターンコード(OUT)
          lv_errmsg                               --ユーザ･エラー･メッセージ(OUT)
        );
        IF ( lv_retcode = cv_status_error ) THEN
          --取得エラー
          lv_err_work   := cv_status_warn;
          lv_out_msg    := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => cv_msg_tan_err,
                             iv_token_name1        => cv_tkn_parm_data1,
                             iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                             iv_token_name2        => cv_tkn_parm_data2,
                             iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
                             iv_token_name3        => cv_tkn_parm_data3,
                             iv_token_value3       => gt_tab_work_data(ln_i).uom_code,
                             iv_token_name4        => cv_tkn_parm_data4,
                             iv_token_value4       => gt_tab_work_data(ln_i).sales_quantity,
                             iv_token_name5        => cv_tkn_parm_data5,
                             iv_token_value5       => gt_tab_work_data(ln_i).item_code
                           );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT,
            buff   => lv_out_msg
          );
          lv_out_msg := NULL;
        ELSE
          BEGIN
            --営業原価を取得
            SELECT
              xsibh.discrete_cost                     discrete_cost                  --営業原価
            INTO
              lv_discrete_cost
            FROM
              (
                SELECT
                  xsibh.discrete_cost                 discrete_cost                  --営業原価
                FROM
                  xxcmm_system_items_b_hst          xsibh                            --品目営業履歴アドオンマスタ
                WHERE
                  xsibh.item_code                    = gt_tab_work_data(ln_i).item_code
                AND xsibh.apply_date                <= gt_tab_work_data(ln_i).digestion_due_date
                AND xsibh.apply_flag                 = ct_apply_flag_yes
                AND xsibh.discrete_cost             IS NOT NULL
                ORDER BY
                  xsibh.apply_date                  desc
              ) xsibh
            WHERE
              ROWNUM                                = 1
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_retcode := cv_status_error;
          END;
          IF ( lv_retcode = cv_status_error ) THEN
            --取得エラー
            lv_err_work   := cv_status_warn;
            lv_out_msg    := xxccp_common_pkg.get_msg(
                               iv_application        => ct_xxcos_appl_short_name,
                               iv_name               => cv_msg_cost_err,
                               iv_token_name1        => cv_tkn_parm_data1,
                               iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                               iv_token_name2        => cv_tkn_parm_data2,
                               iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
                               iv_token_name3        => cv_tkn_parm_data3,
                               iv_token_value3       => gt_tab_work_data(ln_i).item_code,
                               iv_token_name4        => cv_tkn_parm_data4,
                               iv_token_value4       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
                             );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT,
              buff   => lv_out_msg
            );
            lv_out_msg := NULL;
          ELSE
            --会計期間情報取得より設定
            xxcos_common_pkg.get_account_period(
              cv_inv,                                    --会計区分(IN)
              gt_tab_work_data(ln_i).digestion_due_date, --基準日(IN)
              lv_status,                                 --ステータス(OUT)
              ld_from_date,                              --会計(FROM)(OUT)
              ld_to_date,                                --会計(TO)(OUT)
              lv_errbuf,                                 --エラー･メッセージ(OUT)
              lv_retcode,                                --リターンコード(OUT)
              lv_errmsg                                  --ユーザ･エラー･メッセージ(OUT)
            );
            IF ( lv_retcode = cv_status_error ) THEN
              --取得エラー
              lv_err_work   := cv_status_warn;
              lv_out_msg    := xxccp_common_pkg.get_msg(
                                 iv_application        => ct_xxcos_appl_short_name,
                                 iv_name               => cv_msg_prd_err,
                                 iv_token_name1        => cv_tkn_parm_data1,
                                 iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                 iv_token_name2        => cv_tkn_parm_data2,
                                 iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
                                 iv_token_name3        => cv_tkn_parm_data3,
                                 iv_token_value3       => cv_inv,
                                 iv_token_name4        => cv_tkn_parm_data4,
                                 iv_token_value4       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
                               );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT,
                buff   => lv_out_msg
              );
              lv_out_msg := NULL;
            ELSE
              IF ( lv_status <> cv_open ) THEN
                --会計期間情報取得より設定
                xxcos_common_pkg.get_account_period(
                  cv_inv,           --会計区分(IN)
                  NULL,             --基準日(IN)
                  lv_status,        --ステータス(OUT)
                  ld_from_date,     --会計(FROM)(OUT)
                  ld_to_date,       --会計(TO)(OUT)
                  lv_errbuf,        --エラー･メッセージ(OUT)
                  lv_retcode,       --リターンコード(OUT)
                  lv_errmsg         --ユーザ･エラー･メッセージ(OUT)
                );
                IF ( lv_retcode = cv_status_error ) THEN
                  --取得エラー
                  lv_err_work   := cv_status_warn;
                  lv_out_msg    := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => cv_msg_prd_err,
                                     iv_token_name1        => cv_tkn_parm_data1,
                                     iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                     iv_token_name2        => cv_tkn_parm_data2,
                                     iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
                                     iv_token_name3        => cv_tkn_parm_data3,
                                     iv_token_value3       => cv_inv,
                                     iv_token_name4        => cv_tkn_parm_data4,
                                     iv_token_value4       => NULL
                                   );
                  FND_FILE.PUT_LINE(
                    which  => FND_FILE.OUTPUT,
                    buff   => lv_out_msg
                  );
                  lv_out_msg := NULL;
                ELSE
                  gt_tab_sales_exp_headers(ln_h).delivery_date := ld_from_date;                              --納品日
                END IF;
              ELSE
                gt_tab_sales_exp_headers(ln_h).delivery_date   := gt_tab_work_data(ln_i).digestion_due_date; --納品日
              END IF;
              IF TRUNC(gt_tab_sales_exp_headers(ln_h).delivery_date, cv_mm ) = TRUNC( gd_business_date, cv_mm ) THEN --当月なら
                gt_tab_sales_exp_headers(ln_h).sales_base_code := gt_tab_work_data(ln_i).sale_base_code;      --当月売上拠点コード
                gt_tab_for_comfunc_inpara(ln_h).cust_status    := gt_tab_work_data(ln_i).duns_number_c;       --当月顧客ステータス(DFF14)
--
--****************************** 2009/05/07 1.14 T.Kitajima DEL START ******************************--
--                --==================================
--                -- 出荷拠点(納品拠点)取得
--                --==================================
--                BEGIN
--                  SELECT xca.delivery_base_code delivery_base_code                --顧客アドオンマスタ.納品拠点コード
--                    INTO lt_delivery_base_code
--                    FROM xxcmm_cust_accounts       xca                            --顧客アドオンマスタ
--                   --顧客アドオン.顧客コード = 顧客コード
--                   WHERE xca.customer_code      =  gt_tab_work_data(ln_i).customer_number
--                  ;
--                EXCEPTION
--                  WHEN OTHERS THEN
--                    --取得エラー
--                    lv_err_work   := cv_status_warn;
--                    ov_errmsg     := xxccp_common_pkg.get_msg(
--                                       iv_application        => ct_xxcos_appl_short_name,
--                                       iv_name               => cv_msg_select_ship_err,
--                                       iv_token_name1        => cv_tkn_parm_data1,
--                                       iv_token_value1       => gt_tab_work_data(ln_i).customer_number
--                                     );
--                    FND_FILE.PUT_LINE(
--                      which  => FND_FILE.OUTPUT,
--                      buff   => ov_errmsg
--                    );
--                END;
--****************************** 2009/05/07 1.14 T.Kitajima DEL  END  ******************************--
                --==================================
                -- 出荷元保管場所取得
                --==================================
                BEGIN
                  SELECT msi.secondary_inventory_name    secondary_inventory_name,       --保管場所
                         msi.attribute7                  attribute7                      --納品拠点コード
                    INTO lt_ship_from_subinventory_code,
                         lt_delivery_base_code
                    FROM mtl_secondary_inventories       msi                            --保管場所マスタ
                   WHERE msi.organization_id                                                    = gt_organization_id
                     AND msi.attribute7                                                         = gt_tab_sales_exp_headers(ln_h).sales_base_code
                     AND NVL( msi.disable_date, gt_tab_sales_exp_headers(ln_h).delivery_date ) >= gt_tab_sales_exp_headers(ln_h).delivery_date
                     AND EXISTS(
                           SELECT
                             cv_exists_flag_yes            exists_flag
/* 2009/08/10 Ver1.19 Mod Start */
--                           FROM
--                             fnd_application               fa,
--                             fnd_lookup_types              flt,
--                             fnd_lookup_values             flv
--                           WHERE
--                             fa.application_id             = flt.application_id
--                           AND flt.lookup_type             = flv.lookup_type
--                           AND fa.application_short_name   = ct_xxcos_appl_short_name
--                           AND flv.lookup_type             = ct_qct_hokan_type_mst
--                           AND flv.lookup_code             LIKE ct_qcc_hokan_type_mst
--                           AND flv.meaning                 = msi.attribute13
--                           AND gt_tab_sales_exp_headers(ln_h).delivery_date >= flv.start_date_active
--                           AND gt_tab_sales_exp_headers(ln_h).delivery_date <= NVL( flv.end_date_active, gt_tab_sales_exp_headers(ln_h).delivery_date )
--                           AND flv.enabled_flag            = ct_enabled_flag_yes
--                           AND flv.language                = USERENV( 'LANG' )
--                           AND ROWNUM                      = 1
                           FROM
                             fnd_lookup_values             flv
                           WHERE
                             flv.lookup_type               = ct_qct_hokan_type_mst
                           AND flv.lookup_code             LIKE ct_qcc_hokan_type_mst
                           AND flv.meaning                 = msi.attribute13
                           AND gt_tab_sales_exp_headers(ln_h).delivery_date  BETWEEN NVL( flv.start_date_active,  gt_tab_sales_exp_headers(ln_h).delivery_date )
                                                                             AND     NVL( flv.end_date_active, gt_tab_sales_exp_headers(ln_h).delivery_date )
                           AND flv.enabled_flag            = ct_enabled_flag_yes
                           AND flv.language                = ct_lang
                           AND ROWNUM                      = 1
/* 2009/08/10 Ver1.19 Mod End   */
                         )
                  ;
                EXCEPTION
                  WHEN OTHERS THEN
                    --取得エラー
                    lv_err_work   := cv_status_warn;
                    lv_out_msg    := xxccp_common_pkg.get_msg(
                                       iv_application        => ct_xxcos_appl_short_name,
                                       iv_name               => cv_msg_select_for_inv_err,
                                       iv_token_name1        => cv_tkn_parm_data1,
                                       iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                       iv_token_name2        => cv_tkn_parm_data2,
                                       iv_token_value2       => gt_tab_sales_exp_headers(ln_h).sales_base_code
                                     );
                    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT,
                      buff   => lv_out_msg
                    );
                 lv_out_msg := NULL;
                END;
--
              ELSE --前月なら
                gt_tab_sales_exp_headers(ln_h).sales_base_code := gt_tab_work_data(ln_i).past_sale_base_code;        --前月売上拠点コード
                gt_tab_for_comfunc_inpara(ln_h).cust_status    := gt_tab_work_data(ln_i).past_customer_status;       --前月顧客ステータス(DFF14)
                lt_ship_from_subinventory_code                 := gt_tab_work_data(ln_i).ship_from_subinventory_code;--出荷元保管場所
--****************************** 2009/05/07 1.14 T.Kitajima DEL START ******************************--
--                lt_delivery_base_code                          := gt_tab_work_data(ln_i).delivery_base_code;         --出荷拠点
--****************************** 2009/05/07 1.14 T.Kitajima DEL  END  ******************************--
--****************************** 2009/05/07 1.14 T.Kitajima ADD START ******************************--
                 --納品拠点コード取得
                 BEGIN
                   lt_delivery_base_code := NULL;
                   --
                   SELECT msi.attribute7
                     INTO lt_delivery_base_code
                     FROM mtl_secondary_inventories msi
                    --保管場所マスタ.出荷元保管場所コード = 出荷元保管場所コード
                    WHERE msi.secondary_inventory_name    = lt_ship_from_subinventory_code
                      --保管場所マスタ.組織ID             = 在庫組織ID
                      AND msi.organization_id             = gt_organization_id
                   ;
                 EXCEPTION
                   WHEN OTHERS THEN
                     --取得エラー
                     lv_err_work   := cv_status_warn;
                     lv_out_msg    := xxccp_common_pkg.get_msg(
                                        iv_application        => ct_xxcos_appl_short_name,
                                        iv_name               => ct_msg_delivery_base_err,
                                        iv_token_name1        => cv_tkn_parm_data1,
                                        iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                        iv_token_name2        => cv_tkn_parm_data2,
                                        iv_token_value2       => lt_ship_from_subinventory_code
                                      );
                     FND_FILE.PUT_LINE(
                       which  => FND_FILE.OUTPUT,
                       buff   => lv_out_msg
                     );
                     lv_out_msg := NULL;
                END;
--****************************** 2009/05/07 1.14 T.Kitajima ADD  END  ******************************--
              END IF;
--
--
              --==================================
              -- 営業担当員コード取得
              --==================================
              BEGIN
/* 2009/08/10 Ver1.19 Mod Start */
--                SELECT xsv.employee_number,
                SELECT /*+ USE_NL( xsv.hop ) */
                       xsv.employee_number,
/* 2009/08/10 Ver1.19 Mod End   */
                       xsv.resource_id
                  INTO lt_performance_by_code,
                       lt_resource_id
                  FROM xxcos_salesreps_v xsv
                 WHERE xsv.party_id                                                                 = gt_tab_work_data(ln_i).party_id
                   AND xsv.effective_start_date                                                    <= gt_tab_sales_exp_headers(ln_h).delivery_date
                   AND NVL( xsv.effective_end_date, gt_tab_sales_exp_headers(ln_h).delivery_date ) >= gt_tab_sales_exp_headers(ln_h).delivery_date
                ;
              EXCEPTION
                WHEN OTHERS THEN
                  --取得エラー
                  lv_err_work   := cv_status_warn;
                  lv_out_msg    := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => cv_msg_select_salesreps_err,
                                     iv_token_name1        => cv_tkn_parm_data1,
                                     iv_token_value1       => gt_tab_work_data(ln_i).customer_number
                                   );
                  FND_FILE.PUT_LINE(
                    which  => FND_FILE.OUTPUT,
                    buff   => lv_out_msg
                  );
                  lv_out_msg := NULL;
              END;
--
--****************************** 2009/04/21 1.12 T.Kitajima DEL START ******************************--
--              --==================================
--              -- 納品形態取得
--              --==================================
--              xxcos_common_pkg.get_delivered_from(
--                lt_ship_from_subinventory_code,                      --出荷元保管場所(IN)
--                gt_tab_sales_exp_headers(ln_h).sales_base_code,      --売上拠点(IN)
--                lt_delivery_base_code,                               --出荷拠点(IN)
--                lv_organization_code,                                --在庫組織コード(INOUT)
--                lv_organization_id,                                  --在庫組織ＩＤ(INOUT)
--                lv_delivered_from,                                   --納品形態(OUT)
--                lv_errbuf,                                           --エラー･メッセージ(OUT)
--                lv_retcode,                                          --リターンコード(OUT)
--                lv_errmsg                                            --ユーザ･エラー･メッセージ(OUT)
--              );
--              IF ( lv_retcode = cv_status_error ) THEN
--                --取得エラー
--                lv_err_work     := cv_status_warn;
--                ov_errmsg       := xxccp_common_pkg.get_msg(
--                                     iv_application        => ct_xxcos_appl_short_name,
--                                     iv_name               => cv_msg_deli_err,
--                                     iv_token_name1        => cv_tkn_parm_data1,
--                                     iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
--                                     iv_token_name2        => cv_tkn_parm_data2,
--                                     iv_token_value2       => TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd'),
--                                     iv_token_name3        => cv_tkn_parm_data3,
--                                     iv_token_value3       => lt_ship_from_subinventory_code,
--                                     iv_token_name4        => cv_tkn_parm_data4,
--                                     iv_token_value4       => gt_tab_sales_exp_headers(ln_h).sales_base_code,
--                                     iv_token_name5        => cv_tkn_parm_data5,
--                                     iv_token_value5       => lt_delivery_base_code
--                                   );
--                FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT,
--                  buff   => ov_errmsg
--                );
--              END IF;
--****************************** 2009/04/21 1.12 T.Kitajima DEL  END  ******************************--
            END IF;
          END IF;
        END IF;
--**************************** 2009/03/23 1.9  T.kitajima MOD  END  ****************************
      END IF;
      --
      --正常時のみ設定する
      --共通関数でエラーがあった場合は、設定処理スルー
      IF ( lv_err_work = cv_status_normal ) THEN
        --明細シーケンス取得
        SELECT xxcos_sales_exp_lines_s01.nextval
        INTO   ln_line_id
        FROM   DUAL;
        --
        --明細データ設定
        gt_tab_sales_exp_lines(ln_m).sales_exp_line_id            := ln_line_id;                                         --販売実績明細ID
        gt_tab_sales_exp_lines(ln_m).sales_exp_header_id          := ln_header_id;                                       --販売実績ヘッダID
        gt_tab_sales_exp_lines(ln_m).dlv_invoice_number           := lv_deli_seq;                                        --納品伝票番号
--**************************** 2009/03/30 1.10 T.kitajima MOD START ****************************
--        gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := gt_tab_work_data(ln_i).vd_digestion_ln_id;          --納品明細番号
        gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := ln_line_index;                                      --納品明細番号
        ln_line_index                                             := ln_line_index + 1;
--**************************** 2009/03/30 1.10 T.kitajima MOD  END  ****************************
        gt_tab_sales_exp_lines(ln_m).order_invoice_line_number    := NULL;                                               --注文明細番号
--**************************** 2009/05/07 1.14 T.kitajima MOD START ****************************
--        gt_tab_sales_exp_lines(ln_m).sales_class                  := cv_sales_class_vd;                                  --売上区分
        gt_tab_sales_exp_lines(ln_m).sales_class                  := gv_sales_class_vd;                                  --売上区分
--**************************** 2009/05/07 1.14 T.kitajima MOD  END  ****************************
--****************************** 2009/04/21 1.12 T.Kitajima MOD START ******************************--
--        gt_tab_sales_exp_lines(ln_m).delivery_pattern_class       := lv_delivered_from;                                  --納品形態区分
        gt_tab_sales_exp_lines(ln_m).delivery_pattern_class       := gv_delay_ptn;                                       --納品形態区分
--****************************** 2009/04/21 1.12 T.Kitajima MOD  END  ******************************--
        gt_tab_sales_exp_lines(ln_m).item_code                    := gt_tab_work_data(ln_i).item_code;                   --品目コード
        gt_tab_sales_exp_lines(ln_m).dlv_qty                      := gt_tab_work_data(ln_i).sales_quantity;              --納品数量
        gt_tab_sales_exp_lines(ln_m).standard_qty                 := ln_after_quantity;                                  --基準数量
        gt_tab_sales_exp_lines(ln_m).dlv_uom_code                 := gt_tab_work_data(ln_i).uom_code;                    --納品単位
        gt_tab_sales_exp_lines(ln_m).standard_uom_code            := lv_after_uom_code;                                  --基準単位
--**************************** 2009/04/27 1.13 N.Maeda MOD START *********************************************************************
--        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               := gt_tab_work_data(ln_i).unit_price;                  --納品単価
--        --
--        IF gt_tab_work_data(ln_i).tax_uchizei_flag = cv_y THEN --内税
--          --消費税額計算
--          ln_tax_work := gt_tab_work_data(ln_i).unit_price
--                            - ( gt_tab_work_data(ln_i).unit_price / ( cn_1 + gt_tab_work_data(ln_i).tax_rate / cn_100 ) );
--          --
--          IF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_UP ) THEN         --切上げ
--            ln_tax_work_calccomp                                    := gt_tab_work_data(ln_i).unit_price - CEIL( ln_tax_work );
--          ELSIF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_DOWN ) THEN    --切捨て
--            ln_tax_work_calccomp                                    := gt_tab_work_data(ln_i).unit_price - TRUNC( ln_tax_work );
--          ELSIF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_NEAREST ) THEN --四捨五入
--            ln_tax_work_calccomp                                    := gt_tab_work_data(ln_i).unit_price - ROUND( ln_tax_work );
--          ELSE
--            RAISE global_api_others_expt;
--          END IF;
--          --
--          gt_tab_sales_exp_lines(ln_m).standard_unit_price          := gt_tab_work_data(ln_i).unit_price;                --基準単価
--          gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := ln_tax_work_calccomp;                             --税抜基準単価
--        ELSE --外税または非課税
--          gt_tab_sales_exp_lines(ln_m).standard_unit_price          := gt_tab_work_data(ln_i).unit_price;                --基準単価
--          gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := gt_tab_work_data(ln_i).unit_price;                --税抜基準単価
--        END IF;
        --
        gt_tab_sales_exp_lines(ln_m).business_cost                := lv_discrete_cost;                                   --営業原価
        --
        --消化計算掛率済み品目別販売金額＝ROUND（品目別販売金額＊（消化計算掛率／１００））
        ln_amount_work := ROUND( gt_tab_work_data(ln_i).item_sales_amount * ( gt_tab_work_data(ln_i).digestion_calc_rate / cn_100 ) );
        gt_tab_sales_exp_lines(ln_m).sale_amount                  := ln_amount_work;                                     --売上金額
        --消費税金額＝消化計算掛率済み品目別販売金額－（消化計算掛率済み品目別販売金額／（１＋消費税率／１００））
        ln_tax_work := ln_amount_work - ( ln_amount_work / ( cn_1 + gt_tab_work_data(ln_i).tax_rate / cn_100 ) );
        --
        IF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_UP ) THEN         --切上げ
--****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
--          gt_tab_sales_exp_lines(ln_m).tax_amount                 := CEIL( ln_tax_work );                                --消費税金額
----          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_work - CEIL( ln_tax_work );               --本体金額
--          ln_amount_data                                          := ln_amount_work - CEIL( ln_tax_work );               --本体金額
          gt_tab_sales_exp_lines(ln_m).tax_amount                 := roundup( ln_tax_work );                             --消費税金額
          ln_amount_data                                          := ln_amount_work - roundup( ln_tax_work );            --本体金額
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_data;
        ELSIF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_DOWN ) THEN    --切捨て
          gt_tab_sales_exp_lines(ln_m).tax_amount                 := TRUNC( ln_tax_work );                               --消費税金額
--          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_work - TRUNC( ln_tax_work );              --本体金額
          ln_amount_data                                          := ln_amount_work - TRUNC( ln_tax_work );              --本体金額
          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_data;
        ELSIF ( gt_tab_work_data(ln_i).tax_rounding_rule = cv_tax_rounding_rule_NEAREST ) THEN --四捨五入
          gt_tab_sales_exp_lines(ln_m).tax_amount                 := ROUND( ln_tax_work );                               --消費税金額
--          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_work - ROUND( ln_tax_work );              --本体金額
          ln_amount_data                                          := ln_amount_work - ROUND( ln_tax_work );              --本体金額
          gt_tab_sales_exp_lines(ln_m).pure_amount                := ln_amount_data;
        ELSE
          RAISE global_api_others_expt;
        END IF;
/* 2010/01/12 Ver1.22 Add Start */
        -- 端数処理後の税額を設定
        ln_tax_rounding_af := gt_tab_sales_exp_lines(ln_m).tax_amount;
/* 2010/01/12 Ver1.22 Add End */
        --
--****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
--        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               :=
--                                                        TRUNC ( ( ln_amount_work / gt_tab_work_data(ln_i).sales_quantity ) , 2 );  --納品単価
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded :=
--                                                            TRUNC ( ( ln_amount_data / gt_tab_work_data(ln_i).sales_quantity ) , 2 );  --税抜基準単価
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price          := TRUNC ( ( ln_amount_work / ln_after_quantity ) , 2 ); --基準単価
        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               :=
                                                        ROUND ( ( ln_amount_work / gt_tab_work_data(ln_i).sales_quantity ) , 2 );  --納品単価
        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded :=
                                                            ROUND ( ( ln_amount_data / gt_tab_work_data(ln_i).sales_quantity ) , 2 );  --税抜基準単価
        gt_tab_sales_exp_lines(ln_m).standard_unit_price          := ROUND ( ( ln_amount_work / ln_after_quantity ) , 2 ); --基準単価
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
--**************************** 2009/04/27 1.13 N.Maeda MOD  END  *********************************************************************
        --赤黒フラグ取得
/* 2010/01/12 Ver1.22 Mod Start */
        IF ( gt_tab_sales_exp_lines(ln_m).dlv_qty < cn_0 ) THEN
--        IF ( gt_tab_sales_exp_lines(ln_m).sale_amount < cn_0 ) THEN
/* 2010/01/12 Ver1.22 Mod End */
          gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_0;                                --赤
        ELSE
          gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_1;                                --黒
        END IF;
        --
        gt_tab_sales_exp_lines(ln_m).cash_and_card                := cn_0;                                               --現金/カード併用額
--**************************** 2009/03/23 1.9  T.kitajima MOD START ****************************
--        gt_tab_sales_exp_lines(ln_m).ship_from_subinventory_code  := gt_tab_work_data(ln_i).ship_from_subinventory_code; --出荷元保管場所
--        gt_tab_sales_exp_lines(ln_m).delivery_base_code           := gt_tab_work_data(ln_i).delivery_base_code;          --納品拠点コード
        gt_tab_sales_exp_lines(ln_m).ship_from_subinventory_code  := lt_ship_from_subinventory_code;                     --出荷元保管場所
        gt_tab_sales_exp_lines(ln_m).delivery_base_code           := lt_delivery_base_code;                              --納品拠点コード
--**************************** 2009/03/23 1.9  T.kitajima MOD  END  ****************************
        gt_tab_sales_exp_lines(ln_m).hot_cold_class               := gt_tab_work_data(ln_i).hot_cold_type;               --Ｈ＆Ｃ
        gt_tab_sales_exp_lines(ln_m).column_no                    := gt_tab_work_data(ln_i).column_no;                   --コラムNo
        gt_tab_sales_exp_lines(ln_m).sold_out_class               := gt_tab_work_data(ln_i).sold_out_class;              --売切区分
        gt_tab_sales_exp_lines(ln_m).sold_out_time                := gt_tab_work_data(ln_i).sold_out_time;               --売切時間
        gt_tab_sales_exp_lines(ln_m).to_calculate_fees_flag       := ct_to_calculate_fees_flag;                          --手数料計算インタフェース済フラグ
        gt_tab_sales_exp_lines(ln_m).unit_price_mst_flag          := ct_unit_price_mst_flag;                             --単価マスタ作成済フラグ
        gt_tab_sales_exp_lines(ln_m).inv_interface_flag           := ct_inv_interface_flag;                              --INVインタフェース済フラグ
        gt_tab_sales_exp_lines(ln_m).created_by                   := cn_created_by;                                      --作成者
        gt_tab_sales_exp_lines(ln_m).creation_date                := cd_creation_date;                                   --作成日
        gt_tab_sales_exp_lines(ln_m).last_updated_by              := cn_last_updated_by;                                 --最終更新者
        gt_tab_sales_exp_lines(ln_m).last_update_date             := cd_last_update_date;                                --最終更新日
        gt_tab_sales_exp_lines(ln_m).last_update_login            := cn_last_update_login;                               --最終更新ﾛｸﾞｲﾝ
        gt_tab_sales_exp_lines(ln_m).request_id                   := cn_request_id;                                      --要求ID
        gt_tab_sales_exp_lines(ln_m).program_application_id       := cn_program_application_id;                          --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        gt_tab_sales_exp_lines(ln_m).program_id                   := cn_program_id;                                      --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        gt_tab_sales_exp_lines(ln_m).program_update_date          := cd_program_update_date;                             --ﾌﾟﾛｸﾞﾗﾑ更新日
        --売上計算
        --消化計算掛率済み品目別販売金額の合計額計算
        ln_amount_work_total     := ln_amount_work_total     + ln_amount_work;
/* 2010/01/12 Ver1.22 Add Start */
        --消化計算掛率済み品目別税金額の合計額計算
        ln_tax_amount_total     := ln_tax_amount_total  + gt_tab_sales_exp_lines(ln_m).tax_amount;
        --消化計算掛率済み品目別本体金額の合計額計算
        ln_pure_amount_total    := ln_pure_amount_total + gt_tab_sales_exp_lines(ln_m).pure_amount;
/* 2010/01/12 Ver1.22 Add End */
        --最大の消化計算掛率済み品目別販売金額と読み込んだテーブルインデックスと書き出したテーブルインデックスを保存

--****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
--        IF ( ln_amount_work_max <= ln_amount_work ) THEN
        IF   ( ln_amount_work_max <= ln_amount_work )
          OR ( ln_amount_work_max IS NULL )
        THEN
          ln_amount_work_max := ln_amount_work; --最大の消化計算掛率済み品目別販売金額
/* 2010/01/12 Ver1.22 Add Start */
          ln_max_tax := ln_tax_rounding_af;
/* 2010/01/12 Ver1.22 Add End */
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
          ln_i_max := ln_i; --現在の読込テーブルインデックス
          ln_m_max := ln_m; --現在の書出テーブルインデックス
        END IF;
        --
      ELSE --共通関数エラーの場合
        --明細エラーフラグを立てる
        ln_err_line_flag := cn_1;
        --ダミーをセットする
        gt_tab_sales_exp_lines(ln_m).sales_exp_line_id := cn_dmy;
        --ノーマルを設定し通常処理へ戻る
        lv_err_work := cv_status_normal;
      END IF;
      --
      --次のレコードが無い または 次のレコードでキーブレイクする場合
      IF ( gt_tab_work_data.COUNT < ln_i + cn_1 )
        OR
         ( ( gt_tab_work_data(ln_i).vd_digestion_hdr_id <> gt_tab_work_data(ln_i + cn_1).vd_digestion_hdr_id )
          OR ( gt_tab_work_data(ln_i).digestion_due_date <> gt_tab_work_data(ln_i + cn_1).digestion_due_date ) )
      THEN
        --１ヘッダの中でエラー明細が１件でも存在したか？
        IF ( ln_err_line_flag = cn_1 ) THEN --存在した
          --テーブル変数のエラーINDEX分を削除
          gt_tab_sales_exp_lines.DELETE(ln_delete_start_index,ln_m);
          --スキップ件数
          gn_warn_cnt := gn_warn_cnt + cn_1;
          --エラー明細フラグリセット
          ln_err_line_flag := cn_0;
--****************************** 2009/04/27 1.13 T.Kitajima ADD START ******************************--
          -- 明細カウント取得
          ln_count_data := ln_m;
--****************************** 2009/04/27 1.13 T.Kitajima ADD  END  ******************************--
--**************************** 2009/03/30 1.10 T.kitajima ADD START ****************************
          --納品明細番号初期化
          ln_line_index := 1;
--**************************** 2009/03/30 1.10 T.kitajima ADD  END  ****************************
        ELSE --存在しなかった
          --ヘッダデータ設定
          gt_tab_vd_digestion_hdr_id(ln_h)                           := gt_tab_work_data(ln_i).vd_digestion_hdr_id;      --販売実績ヘッダID
          gt_tab_sales_exp_headers(ln_h).sales_exp_header_id         := ln_header_id;                                    --販売実績ヘッダID
          gt_tab_sales_exp_headers(ln_h).dlv_invoice_number          := lv_deli_seq;                                     --納品伝票番号
          gt_tab_sales_exp_headers(ln_h).order_invoice_number        := NULL;                                            --注文伝票番号
          gt_tab_sales_exp_headers(ln_h).order_number                := NULL;                                            --受注番号
          gt_tab_sales_exp_headers(ln_h).order_no_hht                := NULL;                                            --受注No（HHT)
          gt_tab_sales_exp_headers(ln_h).digestion_ln_number         := NULL;                                            --受注No（HHT）枝番
          gt_tab_sales_exp_headers(ln_h).order_connection_number     := NULL;                                            --受注関連番号
          IF ( gt_tab_work_data(ln_i).ar_sales_amount >= cn_0 ) THEN
            gt_tab_sales_exp_headers(ln_h).dlv_invoice_class         := cv_dlv_invoice_class_1;                          --納品伝票区分
          ELSE
            gt_tab_sales_exp_headers(ln_h).dlv_invoice_class         := cv_dlv_invoice_class_3;                          --納品伝票区分
          END IF;
          gt_tab_sales_exp_headers(ln_h).cancel_correct_class        := NULL;                                            --取消・訂正区分
          gt_tab_sales_exp_headers(ln_h).input_class                 := NULL;                                            --入力区分
          gt_tab_sales_exp_headers(ln_h).cust_gyotai_sho             := gt_tab_work_data(ln_i).cust_gyotai_sho;          --業態小分類
          gt_tab_sales_exp_headers(ln_h).orig_delivery_date          := gt_tab_work_data(ln_i).delivery_date;            --オリジナル納品日
          gt_tab_sales_exp_headers(ln_h).inspect_date                := gt_tab_work_data(ln_i).digestion_due_date;       --検収日
          gt_tab_sales_exp_headers(ln_h).orig_inspect_date           := gt_tab_work_data(ln_i).digestion_due_date;       --オリジナル検収日
          gt_tab_sales_exp_headers(ln_h).ship_to_customer_code       := gt_tab_work_data(ln_i).customer_number;          --顧客【納品先】
          gt_tab_sales_exp_headers(ln_h).sale_amount_sum             := gt_tab_work_data(ln_i).ar_sales_amount;          --売上金額合計
--****************************** 2009/04/27 1.13 N.Maeda    ADD START ******************************--
--          gt_tab_sales_exp_headers(ln_h).pure_amount_sum             := gt_tab_work_data(ln_i).ar_sales_amount
--                                                                              - gt_tab_work_data(ln_i).tax_amount;       --本体金額合計
--          gt_tab_sales_exp_headers(ln_h).tax_amount_sum              := gt_tab_work_data(ln_i).tax_amount;               --消費税金額合計
--****************************** 2009/04/27 1.13 N.Maeda    ADD  END  ******************************--
          gt_tab_sales_exp_headers(ln_h).consumption_tax_class       := gt_tab_work_data(ln_i).tax_div;                  --消費税区分
          gt_tab_sales_exp_headers(ln_h).tax_code                    := gt_tab_work_data(ln_i).tax_code;                 --税金コード
          gt_tab_sales_exp_headers(ln_h).tax_rate                    := gt_tab_work_data(ln_i).tax_rate;                 --消費税率
          gt_tab_sales_exp_headers(ln_h).results_employee_code       := lt_performance_by_code;                          --成績計上者コード
          gt_tab_sales_exp_headers(ln_h).receiv_base_code            := gt_tab_work_data(ln_i).cash_receiv_base_code;    --入金拠点コード
          gt_tab_sales_exp_headers(ln_h).order_source_id             := NULL;                                            --受注ソースID
          gt_tab_sales_exp_headers(ln_h).card_sale_class             := ct_card_flag_cash;                               --カード売り区分
          gt_tab_sales_exp_headers(ln_h).invoice_class               := NULL;                                            --伝票区分
          gt_tab_sales_exp_headers(ln_h).invoice_classification_code := NULL;                                            --伝票分類コード
          gt_tab_sales_exp_headers(ln_h).change_out_time_100         := gt_tab_work_data(ln_i).change_out_time_100;      --つり銭切れ時間１００円
          gt_tab_sales_exp_headers(ln_h).change_out_time_10          := gt_tab_work_data(ln_i).change_out_time_10;       --つり銭切れ時間１０円
          gt_tab_sales_exp_headers(ln_h).ar_interface_flag           := ct_ar_interface_flag;                            --ARインタフェース済フラグ
          gt_tab_sales_exp_headers(ln_h).gl_interface_flag           := ct_gl_interface_flag;                            --GLインタフェース済フラグ
          gt_tab_sales_exp_headers(ln_h).dwh_interface_flag          := ct_dwh_interface_flag;                           --情報システムインタフェース済フラグ
          gt_tab_sales_exp_headers(ln_h).edi_interface_flag          := ct_edi_interface_flag;                           --EDI送信済みフラグ
          gt_tab_sales_exp_headers(ln_h).edi_send_date               := NULL;                                            --EDI送信日時
          gt_tab_sales_exp_headers(ln_h).hht_dlv_input_date          := TO_DATE(TO_CHAR(gt_tab_work_data(ln_i).digestion_due_date,'yyyymmdd')
                                                                         || NVL(gt_tab_work_data(ln_i).dlv_time,'0000'),'yyyymmddhh24miss');
                                                                                                                         --HHT納品入力日時
          gt_tab_sales_exp_headers(ln_h).dlv_by_code                 := NULL;                                            --納品者コード
          gt_tab_sales_exp_headers(ln_h).create_class                := gv_making_code;                                  --作成元区分
          gt_tab_sales_exp_headers(ln_h).business_date               := gd_business_date;                                --登録業務日付
          gt_tab_sales_exp_headers(ln_h).created_by                  := cn_created_by;                                   --作成者
          gt_tab_sales_exp_headers(ln_h).creation_date               := cd_creation_date;                                --作成日
          gt_tab_sales_exp_headers(ln_h).last_updated_by             := cn_last_updated_by;                              --最終更新者
          gt_tab_sales_exp_headers(ln_h).last_update_date            := cd_last_update_date;                             --最終更新日
          gt_tab_sales_exp_headers(ln_h).last_update_login           := cn_last_update_login;                            --最終更新ﾛｸﾞｲﾝ
          gt_tab_sales_exp_headers(ln_h).request_id                  := cn_request_id;                                   --要求ID
          gt_tab_sales_exp_headers(ln_h).program_application_id      := cn_program_application_id;                       --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          gt_tab_sales_exp_headers(ln_h).program_id                  := cn_program_id;                                   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          gt_tab_sales_exp_headers(ln_h).program_update_date         := cd_program_update_date;                          --ﾌﾟﾛｸﾞﾗﾑ更新日
          --
          gt_tab_for_comfunc_inpara(ln_h).resource_id                := lt_resource_id;                            -- リソースID
          gt_tab_for_comfunc_inpara(ln_h).party_id                   := gt_tab_work_data(ln_i).party_id;           -- パーティID
          gt_tab_for_comfunc_inpara(ln_h).party_name                 := gt_tab_work_data(ln_i).party_name;         -- パーティ名称（顧客名称）
          gt_tab_for_comfunc_inpara(ln_h).digestion_due_date         := gt_tab_work_data(ln_i).digestion_due_date; -- 訪問日時 ＝ 消化計算締日
          gt_tab_for_comfunc_inpara(ln_h).ar_sales_amount            := gt_tab_work_data(ln_i).ar_sales_amount;    -- 合計金額
          gt_tab_for_comfunc_inpara(ln_h).deli_seq                   := lv_deli_seq;                               -- DFF13（登録元ソース番号）＝ 受注No.（HHT）
          --
          --
          --差分計算
          --差額 ＝ AR売上金額 － 消化計算掛率済み品目別販売金額の合計額
          ln_difference_money := gt_tab_work_data(ln_i).ar_sales_amount - ln_amount_work_total;
/* 2010/01/12 Ver1.22 Mod Start */
          -- 税金額差額算出
          ln_difference_tax   := gt_tab_work_data(ln_i).tax_amount - ln_tax_amount_total;
          --
          -- 本体金額の差額算出
          ln_diff_pure_amount := gt_tab_work_data(ln_i).ar_sales_amount - ln_pure_amount_total;
          IF ( ln_difference_money = cn_0 AND ln_difference_tax = cn_0 AND ln_diff_pure_amount = cn_0 ) THEN
--          IF ( ln_difference_money = cn_0 ) THEN
/* 2010/01/12 Ver1.22 Mod End */
            NULL; --差異なし
          ELSE
            --差額を最大の消化計算掛率済み品目別販売金額に加算する
            --最大の消化計算掛率済み品目別販売金額＋差額
            ln_amount_work_max := ln_amount_work_max + ln_difference_money;
/* 2009/12/15 Ver1.21 Mod Start */
/* 2010/01/12 Ver1.22 Mod Start */
            --消費税額の再計算
            ln_max_tax := ln_max_tax + ln_difference_tax;
            gt_tab_sales_exp_lines(ln_m_max).tax_amount := ln_max_tax;
            -- 本体金額の再計算
            IF ( gt_tab_work_data(ln_m_max).tax_rate > 0 ) THEN
              -- 税抜き本体金額の場合
              gt_tab_sales_exp_lines(ln_m_max).pure_amount :=   gt_tab_sales_exp_lines(ln_m_max).pure_amount
                                                              + ln_diff_pure_amount;
            ELSE
              -- 税込み本体金額の場合
              gt_tab_sales_exp_lines(ln_m_max).pure_amount :=   gt_tab_sales_exp_lines(ln_m_max).sale_amount
                                                              - gt_tab_sales_exp_lines(ln_m_max).tax_amount
                                                              + ln_diff_pure_amount;
            END IF;
--            --差額を加算した最大の消化計算掛率済み品目別販売金額－（差額を加算した最大の消化計算掛率済み品目別販売金額／（１＋消費税率／１００））
--            ln_tax_work := ln_amount_work_max - gt_tab_sales_exp_lines(ln_m_max).pure_amount;
--             gt_tab_sales_exp_lines(ln_m_max).tax_amount := ln_tax_work;
/* 2010/01/12 Ver1.22 Mod End */
--            ln_tax_work := ln_amount_work_max - ( ln_amount_work_max / ( cn_1 + gt_tab_work_data(ln_i_max).tax_rate / cn_100 ) );
/* 2009/12/15 Ver1.21 Mod End */
            --売上金額
            gt_tab_sales_exp_lines(ln_m_max).sale_amount      := ln_amount_work_max;
            --
/* 2009/12/15 Ver1.21 Del Start */
--            --消費税額の小数点を端数処理し、消費税金額と本体金額を再計算し、出力変数へ再びセットし直す。
--            IF ( gt_tab_work_data(ln_i_max).tax_rounding_rule    = cv_tax_rounding_rule_UP )      THEN    --切上げ
----****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
----             gt_tab_sales_exp_lines(ln_m_max).tax_amount     := CEIL( ln_tax_work );                       --消費税金額
----              gt_tab_sales_exp_lines(ln_m_max).pure_amount    := ln_amount_work_max - CEIL( ln_tax_work );  --本体金額
--             gt_tab_sales_exp_lines(ln_m_max).tax_amount     := roundup( ln_tax_work );                       --消費税金額
--              gt_tab_sales_exp_lines(ln_m_max).pure_amount    := ln_amount_work_max - roundup( ln_tax_work );  --本体金額
----****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
--            ELSIF ( gt_tab_work_data(ln_i_max).tax_rounding_rule = cv_tax_rounding_rule_DOWN )    THEN    --切捨て
--              gt_tab_sales_exp_lines(ln_m_max).tax_amount     := TRUNC( ln_tax_work );                      --消費税金額
--              gt_tab_sales_exp_lines(ln_m_max).pure_amount    := ln_amount_work_max - TRUNC( ln_tax_work ); --本体金額
--            ELSIF ( gt_tab_work_data(ln_i_max).tax_rounding_rule = cv_tax_rounding_rule_NEAREST ) THEN    --四捨五入
--              gt_tab_sales_exp_lines(ln_m_max).tax_amount     := ROUND( ln_tax_work );                      --消費税金額
--              gt_tab_sales_exp_lines(ln_m_max).pure_amount    := ln_amount_work_max - ROUND( ln_tax_work ); --本体金額
--            ELSE
--              RAISE global_api_others_expt;
--            END IF;
/* 2009/12/15 Ver1.21 Del End */
--****************************** 2009/05/25 1.15 T.Kitajima MOD START  ******************************--
            --調整後単価計算
            gt_tab_sales_exp_lines(ln_m_max).dlv_unit_price               :=
              ROUND ( ( gt_tab_sales_exp_lines(ln_m_max).sale_amount / gt_tab_sales_exp_lines(ln_m_max).dlv_qty ) , 2 );  --納品単価
            gt_tab_sales_exp_lines(ln_m_max).standard_unit_price_excluded :=
              ROUND ( ( gt_tab_sales_exp_lines(ln_m_max).pure_amount / gt_tab_sales_exp_lines(ln_m_max).dlv_qty ) , 2 );  --税抜基準単価
            gt_tab_sales_exp_lines(ln_m_max).standard_unit_price          :=
              ROUND ( ( gt_tab_sales_exp_lines(ln_m_max).sale_amount / gt_tab_sales_exp_lines(ln_m_max).standard_qty ) , 2 );  --基準単価
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END   ******************************--
          END IF;
--
--****************************** 2009/04/27 1.13 N.Maeda    ADD START ******************************--
          FOR ln_a IN (ln_count_data + 1)..ln_m LOOP
            ln_tax_work_total        := ln_tax_work_total        + gt_tab_sales_exp_lines(ln_a).tax_amount;
            ln_amount_work_data      := ln_amount_work_data      + gt_tab_sales_exp_lines(ln_a).pure_amount;
          END LOOP;
          gt_tab_sales_exp_headers(ln_h).pure_amount_sum             := ln_amount_work_data;
          gt_tab_sales_exp_headers(ln_h).tax_amount_sum              := ln_tax_work_total;
          ln_tax_work_total          := 0;
          ln_amount_work_data        := 0;
          -- 明細カウント取得
          ln_count_data              := ln_m;
--****************************** 2009/05/25 1.15 T.Kitajima MOD START ******************************--
--          ln_amount_work_max         := cn_0;
          ln_amount_work_max         := NULL;
--****************************** 2009/05/25 1.15 T.Kitajima MOD  END  ******************************--
          ln_i_max                   := cn_0;
          ln_m_max                   := cn_0;
--****************************** 2009/04/27 1.13 N.Maeda    ADD  END  ******************************--
--
/* 2010/01/12 Ver1.22 Add Start */
          ln_tax_amount_total     := cn_0;
          ln_ar_tax_total         := cn_0;
          ln_tax_rounding_af      := cn_0;
          ln_max_tax              := cn_0;
          ln_difference_tax       := cn_0;
          ln_pure_amount_total    := cn_0;
          ln_diff_pure_amount     := cn_0;
/* 2010/01/12 Ver1.22 Add Start */

          --消化計算掛率済み品目別販売合計金額の初期化
          ln_amount_work_total   := cn_0;
          --差額の初期化
          ln_difference_money    := cn_0;
          --ヘッダカウントUP
          ln_h := ln_h + cn_1;
--**************************** 2009/03/30 1.10 T.kitajima ADD START ****************************
          --納品明細番号初期化
          ln_line_index := 1;
--**************************** 2009/03/30 1.10 T.kitajima ADD  END  ****************************
          --ヘッダシーケンス取得
          SELECT xxcos_sales_exp_headers_s01.nextval
          INTO   ln_header_id
          FROM   DUAL;
          --納品伝票番号シーケンス取得
--******************************* 2009/06/11 1.17 T.Kitajima MOD START ******************************--
--         lv_deli_seq := xxcos_def_pkg.set_order_number(NULL,NULL);
         SELECT cv_snq_i || TO_CHAR( ( lpad( XXCOS_CUST_PO_NUMBER_S01.nextval, 11, 0) ) )
           INTO lv_deli_seq
           FROM dual;
--******************************* 2009/06/11 1.17 T.Kitajima MOD  END  ******************************--
        END IF;
        --次の削除開始ポイントINDEX値を保管
        ln_delete_start_index := ln_m + cn_1;
      END IF;
      --明細カウントUP
      ln_m := ln_m + cn_1;
    END LOOP keisan_loop;
--
    --テーブルコレクションの入れ替え。
    --明細分ループする
    FOR ln_i IN 1..ln_m LOOP
      IF ( gt_tab_sales_exp_lines.EXISTS(ln_i) ) THEN
        gt_tab_sales_exp_lines_ins(ln_index) := gt_tab_sales_exp_lines(ln_i);
        ln_index := ln_index + cn_1;
      END IF;
    END LOOP;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    IF ( gn_warn_cnt > cn_0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--#####################################  固定部 START ##########################################
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
  END calc_sales;
--
  /**********************************************************************************
   * Procedure Name   : set_lines
   * Description      : 販売実績明細作成(A-5)
   ***********************************************************************************/
  PROCEDURE set_lines(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_lines'; -- プログラム名
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
    ln_i    NUMBER;
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
    BEGIN
      FORALL ln_i in 1..gt_tab_sales_exp_lines_ins.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_lines VALUES gt_tab_sales_exp_lines_ins(ln_i);
    EXCEPTION
--
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, SQLERRM);
        RAISE global_insert_expt;
--
    END;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --登録例外
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        =>  ct_xxcos_appl_short_name,
                     iv_name               =>  cv_msg_inser_lines_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  固定部 START ##########################################
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
  END set_lines;
--
  /**********************************************************************************
   * Procedure Name   : set_headers
   * Description      : 販売実績ヘッダ作成(A-6)
   ***********************************************************************************/
  PROCEDURE set_headers(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_headers'; -- プログラム名
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
    ln_i    NUMBER;
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
    -- 共通関数＜訪問有効情報登録＞
    FOR i IN 1..gt_tab_for_comfunc_inpara.COUNT LOOP
--
      IF ( gt_tab_for_comfunc_inpara(i).ar_sales_amount > 0 ) THEN
--
        xxcos_task_pkg.task_entry(
          lv_errbuf                                       -- エラー・メッセージ
         ,lv_retcode                                      -- リターン・コード
         ,lv_errmsg                                       -- ユーザー・エラー・メッセージ
         ,gt_tab_for_comfunc_inpara(i).resource_id        -- リソースID
         ,gt_tab_for_comfunc_inpara(i).party_id           -- パーティID
         ,gt_tab_for_comfunc_inpara(i).party_name         -- パーティ名称（顧客名称）
         ,gt_tab_for_comfunc_inpara(i).digestion_due_date -- 訪問日時 ＝ 消化計算締日
         ,NULL                                            -- 詳細内容
         ,gt_tab_for_comfunc_inpara(i).ar_sales_amount    -- 合計金額
         ,cv_0                                            -- 入力区分
         ,cv_entry_class                                  -- DFF12（登録区分）＝ 5
         ,gt_tab_for_comfunc_inpara(i).deli_seq           -- DFF13（登録元ソース番号）＝ 受注No.（HHT）
         ,gt_tab_for_comfunc_inpara(i).cust_status        -- DFF14（顧客ステータス）
        );
--
        --エラーチェック
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END LOOP;
--
    BEGIN
      FORALL ln_i in 1..gt_tab_sales_exp_headers.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_headers VALUES gt_tab_sales_exp_headers(ln_i);
      --対象件数を正常件数に
      gn_normal_cnt := gt_tab_sales_exp_headers.COUNT;
    EXCEPTION
--
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        RAISE global_insert_expt;
--
    END;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --登録例外
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        =>  ct_xxcos_appl_short_name,
                     iv_name               =>  cv_msg_inser_headers_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  固定部 START ##########################################
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
  END set_headers;
--
  /**********************************************************************************
   * Procedure Name   : update_digestion
   * Description      : 消化ＶＤ用消化計算テーブル更新処理(A-7)
   ***********************************************************************************/
  PROCEDURE update_digestion(
    iv_base_code       IN         VARCHAR2,     -- 拠点コード
    iv_customer_number IN         VARCHAR2,     -- 顧客コード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_digestion'; -- プログラム名
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
    ln_i  NUMBER;  --カウンター
--
    -- *** ローカル・カーソル ***
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
    CURSOR lock_cur
    IS
/* 2009/08/10 Ver1.19 Mod Start */
--      SELECT digestion_vd_rate_maked_date
      SELECT /*+
               INDEX(xxcos_vd_column_headers xxcos_vd_column_headers_n05)
             */
             digestion_vd_rate_maked_date
/* 2009/08/10 Ver1.19 Mod End   */
        FROM xxcos_vd_column_headers
--****************************** 2009/06/12 1.18 T.Kitajima ADD START ******************************--
--       WHERE digestion_vd_rate_maked_date IS NOT NULL
       WHERE digestion_vd_rate_maked_date IS NOT NULL
         AND (    forward_date IS NULL
               OR forward_flag = ct_make_flag_no
             )
--****************************** 2009/06/12 1.18 T.Kitajima ADD  END  ******************************--
       FOR UPDATE NOWAIT
    ;
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
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
    -- ===============================
    -- 1.販売実績作成分更新処理
    -- ===============================
    BEGIN
      FORALL ln_i in 1..gt_tab_vd_digestion_hdr_id.COUNT SAVE EXCEPTIONS
        UPDATE xxcos_vd_digestion_hdrs
           SET sales_result_creation_flag = ct_make_flag_yes,
               sales_result_creation_date = gd_business_date,
               last_updated_by            = cn_last_updated_by,
               last_update_date           = cd_last_update_date,
               last_update_login          = cn_last_update_login,
               request_id                 = cn_request_id,
               program_application_id     = cn_program_application_id,
               program_id                 = cn_program_id,
               program_update_date        = cd_program_update_date
         WHERE vd_digestion_hdr_id        = gt_tab_vd_digestion_hdr_id(ln_i);
    EXCEPTION
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        RAISE global_up_headers_expt;
    END;
    -- ===============================
    -- 2.販売実績作成分更新処理
    -- ===============================
    BEGIN
/* 2009/08/10 Ver1.19 Mod Start */
--      UPDATE xxcos_vd_digestion_hdrs
--         SET sales_result_creation_flag = ct_make_flag_yes,
--             sales_result_creation_date = gd_business_date,
--             last_updated_by            = cn_last_updated_by,
--             last_update_date           = cd_last_update_date,
--             last_update_login          = cn_last_update_login,
--             request_id                 = cn_request_id,
--             program_application_id     = cn_program_application_id,
--             program_id                 = cn_program_id,
--             program_update_date        = cd_program_update_date
--       WHERE uncalculate_class          = ct_un_calc_flag_1
--       AND   sales_result_creation_flag = ct_make_flag_no
--       AND   digestion_due_date        <= DECODE( gv_exec_div, cn_0, digestion_due_date, gd_delay_date )
--       AND   customer_number IN ( --顧客コード(9BYTE)
      UPDATE xxcos_vd_digestion_hdrs xvdh
         SET xvdh.sales_result_creation_flag = ct_make_flag_yes,
             xvdh.sales_result_creation_date = gd_business_date,
             xvdh.last_updated_by            = cn_last_updated_by,
             xvdh.last_update_date           = cd_last_update_date,
             xvdh.last_update_login          = cn_last_update_login,
             xvdh.request_id                 = cn_request_id,
             xvdh.program_application_id     = cn_program_application_id,
             xvdh.program_id                 = cn_program_id,
             xvdh.program_update_date        = cd_program_update_date
       WHERE xvdh.uncalculate_class          = ct_un_calc_flag_1
       AND   xvdh.sales_result_creation_flag = ct_make_flag_no
       AND   (
               ( gv_exec_div = cn_0 )
               OR
               ( gv_exec_div <> cn_0 AND xvdh.digestion_due_date <= gd_delay_date )
             )
       AND   EXISTS (
/* 2009/08/10 Ver1.19 Mod End   */
             SELECT hca.account_number  account_number         --顧客コード(30BYTE)
             FROM   hz_cust_accounts    hca,                   --顧客マスタ
                    xxcmm_cust_accounts xca                    --顧客アドオン
             WHERE  hca.cust_account_id     = xca.customer_id  --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
/* 2009/08/10 Ver1.19 Add Start */
             AND    xca.customer_code       = xvdh.customer_number  --顧客アドオン.顧客コード = 消化VD用消化計算ヘッダ.顧客コード
/* 2009/08/10 Ver1.19 Add End   */
             AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                            FROM   fnd_application               fa,
--                                   fnd_lookup_types              flt,
--                                   fnd_lookup_values             flv
--                            WHERE  fa.application_id                               = flt.application_id
--                            AND    flt.lookup_type                                 = flv.lookup_type
--                            AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                            AND    flv.lookup_type                                 = ct_qct_cust_type
--                            AND    flv.start_date_active                          <= gd_delay_date
--                            AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
--                            AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                            AND    flv.language                                    = USERENV( 'LANG' )
--                            AND    flv.meaning                                     = hca.customer_class_code
                            FROM   fnd_lookup_values             flv
                            WHERE  flv.lookup_type    = ct_qct_cust_type
                            AND    gd_delay_date      BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                      AND     NVL( flv.end_date_active, gd_delay_date )
                            AND    flv.enabled_flag   = ct_enabled_flag_yes
                            AND    flv.language       = ct_lang
                            AND    flv.meaning        = hca.customer_class_code
/* 2009/08/10 Ver1.19 Mod End   */
                           ) --顧客マスタ.顧客区分 = 10(顧客)
             AND    EXISTS (SELECT hcae.account_number --拠点コード
                              FROM   hz_cust_accounts    hcae,
/* 2009/08/10 Ver1.19 Mod Start */
--                                     xxcmm_cust_accounts xcae
                                     xxcmm_cust_accounts xcae,
                                     fnd_lookup_values   flv
/* 2009/08/10 Ver1.19 Mod End   */
                              WHERE  hcae.cust_account_id = xcae.customer_id--顧客マスタ.顧客ID = 顧客アドオン.顧客ID
/* 2009/08/10 Ver1.19 Mod Start */
--                              AND    EXISTS (SELECT flv.meaning
--                                             FROM   fnd_application               fa,
--                                                    fnd_lookup_types              flt,
--                                                    fnd_lookup_values             flv
--                                             WHERE  fa.application_id                               = flt.application_id
--                                             AND    flt.lookup_type                                 = flv.lookup_type
--                                             AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                                             AND    flv.lookup_type                                 = ct_qct_cust_type
--                                             AND    flv.start_date_active                          <= gd_delay_date
--                                             AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
--                                             AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                                             AND    flv.language                                    = USERENV( 'LANG' )
--                                             AND    flv.meaning                                     = hcae.customer_class_code
--                                            ) --顧客マスタ.顧客区分 = 1(拠点)
--                              AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
--                                              --顧客顧客アドオン.管理元拠点コード = INパラ拠点コード
                              AND    flv.lookup_type      = ct_qct_cust_type
                              AND    gd_delay_date        BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                          AND     NVL( flv.end_date_active, gd_delay_date )
                              AND    flv.enabled_flag     = ct_enabled_flag_yes
                              AND    flv.language         = ct_lang
                              AND    flv.meaning          = hcae.customer_class_code
                              AND    (
                                       ( iv_base_code IS NULL )
                                       OR
                                       ( iv_base_code IS NOT NULL AND xcae.management_base_code = iv_base_code )
                                     ) --顧客顧客アドオン.管理元拠点コード = INパラ拠点コード
/* 2009/08/10 Ver1.19 Mod End   */
                              AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                           ) --管理拠点に所属する拠点コード = 顧客アドオン.前月拠点or売上拠点
/* 2009/08/10 Ver1.19 Mod Start */
--             AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード = INパラ(顧客コード)
             AND    (
                      ( iv_customer_number IS NULL )
                      OR
                      ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                    ) --顧客コード = INパラ(顧客コード)
/* 2009/08/10 Ver1.19 Mod End   */
             AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                            FROM   fnd_application               fa,
--                                   fnd_lookup_types              flt,
--                                   fnd_lookup_values             flv
--                            WHERE  fa.application_id                               =    flt.application_id
--                            AND    flt.lookup_type                                 =    flv.lookup_type
--                            AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                            AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                            AND    flv.lookup_code                                 LIKE ct_qcc_d_code
--                            AND    flv.start_date_active                          <=    gd_delay_date
--                            AND    NVL( flv.end_date_active, gd_delay_date )      >=    gd_delay_date
--                            AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                            AND    flv.language                                    =    USERENV( 'LANG' )
--                            AND    flv.meaning                                     =    xca.business_low_type
                            FROM   fnd_lookup_values             flv
                            WHERE  flv.lookup_type    = ct_qct_gyo_type
                            AND    flv.lookup_code    LIKE ct_qcc_d_code
                            AND    gd_delay_date      BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                      AND     NVL( flv.end_date_active, gd_delay_date )
                            AND    flv.enabled_flag   = ct_enabled_flag_yes
                            AND    flv.language       = ct_lang
                            AND    flv.meaning        = xca.business_low_type
/* 2009/08/10 Ver1.19 Mod End   */
                           )  --業態小分類 = 消化・VD消化
             UNION
             SELECT hca.account_number  account_number         --顧客コード
             FROM   hz_cust_accounts    hca,                   --顧客マスタ
                    xxcmm_cust_accounts xca                    --顧客アドオン
             WHERE  hca.cust_account_id     = xca.customer_id  --顧客マスタ.顧客ID = 顧客アドオン.顧客ID
/* 2009/08/10 Ver1.19 Add Start */
             AND    xca.customer_code       = xvdh.customer_number  --顧客アドオン.顧客コード = 消化VD用消化計算ヘッダ.顧客コード
/* 2009/08/10 Ver1.19 Add End   */
             AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                            FROM   fnd_application               fa,
--                                   fnd_lookup_types              flt,
--                                   fnd_lookup_values             flv
--                            WHERE  fa.application_id                               = flt.application_id
--                            AND    flt.lookup_type                                 = flv.lookup_type
--                            AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                            AND    flv.lookup_type                                 = ct_qct_cust_type
--                            AND    flv.start_date_active                          <= gd_delay_date
--                            AND    NVL( flv.end_date_active, gd_delay_date )      >= gd_delay_date
--                            AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                            AND    flv.language                                    = USERENV( 'LANG' )
--                            AND    flv.meaning                                     = hca.customer_class_code
                            FROM   fnd_lookup_values             flv
                            WHERE  flv.lookup_type   = ct_qct_cust_type
                            AND    gd_delay_date     BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                     AND     NVL( flv.end_date_active, gd_delay_date )
                            AND    flv.enabled_flag  = ct_enabled_flag_yes
                            AND    flv.language      = ct_lang
                            AND    flv.meaning       = hca.customer_class_code
/* 2009/08/10 Ver1.19 Mod End   */
                           ) --顧客マスタ.顧客区分 = 10(顧客)
             AND    (
                     xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                     OR
                     xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                    )--顧客アドオン.前月拠点or売上拠点 = INパラ拠点コード
/* 2009/08/10 Ver1.19 Mod Start */
--             AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード = INパラ(顧客コード)
             AND    (
                      ( iv_customer_number IS NULL )
                      OR
                      ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                    ) --顧客コード = INパラ(顧客コード)
/* 2009/08/10 Ver1.19 Mod End   */
             AND    EXISTS (SELECT flv.meaning
/* 2009/08/10 Ver1.19 Mod Start */
--                            FROM   fnd_application               fa,
--                                   fnd_lookup_types              flt,
--                                   fnd_lookup_values             flv
--                            WHERE  fa.application_id                               =    flt.application_id
--                            AND    flt.lookup_type                                 =    flv.lookup_type
--                            AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                            AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                            AND    flv.lookup_code                                 LIKE ct_qcc_d_code
--                            AND    flv.start_date_active                          <=    gd_delay_date
--                            AND    NVL( flv.end_date_active, gd_delay_date )      >=    gd_delay_date
--                            AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                            AND    flv.language                                    =    USERENV( 'LANG' )
--                            AND    flv.meaning                                     =    xca.business_low_type
                            FROM   fnd_lookup_values             flv
                            WHERE  flv.lookup_type    = ct_qct_gyo_type
                            AND    flv.lookup_code    LIKE ct_qcc_d_code
                            AND    gd_delay_date      BETWEEN NVL( flv.start_date_active, gd_delay_date )
                                                      AND     NVL( flv.end_date_active, gd_delay_date )
                            AND    flv.enabled_flag   = ct_enabled_flag_yes
                            AND    flv.language       = ct_lang
                            AND    flv.meaning        = xca.business_low_type
/* 2009/08/10 Ver1.19 Mod End   */
                           )  --業態小分類 = 消化・VD消化
                                )
      ;
    EXCEPTION
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        RAISE global_up_headers_expt;
    END;
    -- ========================================
    -- 3.ＶＤコラム別取引ヘッダテーブル更新処理
    -- ========================================
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
    BEGIN
      OPEN lock_cur;
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- カーソルCLOSE：納品ヘッダワークテーブルデータ取得
        IF ( lock_cur%ISOPEN ) THEN
          CLOSE lock_cur;
        END IF;
        RAISE global_data_lock_expt;
    END;
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
    BEGIN
/* 2009/08/10 Ver1.19 Mod Start */
--      UPDATE xxcos_vd_column_headers
      UPDATE /*+
               INDEX(xxcos_vd_column_headers  xxcos_vd_column_headers_n05)
             */
             xxcos_vd_column_headers
/* 2009/08/10 Ver1.19 Mod Start */
         SET
             forward_flag               = ct_make_flag_yes,
             forward_date               = gd_business_date,
             last_updated_by            = cn_last_updated_by,
             last_update_date           = cd_last_update_date,
             last_update_login          = cn_last_update_login,
             request_id                 = cn_request_id,
             program_application_id     = cn_program_application_id,
             program_id                 = cn_program_id,
             program_update_date        = cd_program_update_date
--****************************** 2009/06/12 1.18 T.Kitajima ADD START ******************************--
--           WHERE digestion_vd_rate_maked_date IS NOT NULL;
           WHERE digestion_vd_rate_maked_date IS NOT NULL
             AND (    forward_date IS NULL
                   OR forward_flag = ct_make_flag_no
                 );
--****************************** 2009/06/12 1.18 T.Kitajima ADD  END  ******************************--
    EXCEPTION
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        RAISE global_up_inv_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --消化ＶＤ用消化計算ヘッダ更新例外
    WHEN global_up_headers_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name,
                      iv_name               =>  cv_msg_update_headers_err
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --ＶＤコラム別取引ヘッダ更新例外
    WHEN global_up_inv_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name,
                      iv_name               =>  cv_msg_update_inv_err
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/06/09 1.16 T.Kitajima ADD START ******************************--
--
    -- *** ロック エラー ***
    WHEN global_data_lock_expt     THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_vd_lock_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--****************************** 2009/06/09 1.16 T.Kitajima ADD  END  ******************************--
--#####################################  固定部 START ##########################################
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
  END update_digestion;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_exec_div        IN         VARCHAR2,     -- 1.定期随時区分
    iv_base_code       IN         VARCHAR2,     -- 2.拠点コード
    iv_customer_number IN         VARCHAR2,     -- 3.顧客コード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    gn_target_cnt := cn_0;
    gn_normal_cnt := cn_0;
    gn_error_cnt  := cn_0;
    gn_warn_cnt   := cn_0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- A-0.初期処理
    -- ===============================
    init(
      iv_exec_div,        -- 1.定期随時区分
      iv_base_code,       -- 2.拠点コード
      iv_customer_number, -- 3.顧客コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-1.パラメータチェック
    -- ===============================
    pram_chk(
      iv_exec_div,        -- 1.定期随時区分
      iv_base_code,       -- 2.拠点コード
      iv_customer_number, -- 3.顧客コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-2.共通データ取得
    -- ===============================
    get_common_data(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ====================================
    -- A-3.消化ＶＤ用消化計算データ抽出処理
    -- ====================================
    get_object_data(
      iv_exec_div,        -- 定期随時区分
      iv_base_code,       -- 拠点コード
      iv_customer_number, -- 顧客コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-4．納品データ計算処理
    -- ===============================
    calc_sales(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================
    -- A-5．販売実績明細作成
    -- ===============================
    set_lines(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-6．販売実績ヘッダ作成
    -- ===============================
    set_headers(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ========================================
    -- A-7．消化ＶＤ用消化計算テーブル更新処理
    -- ========================================
    update_digestion(
      iv_base_code,       -- 拠点コード
      iv_customer_number, -- 顧客コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- <処理部、ループ部名> (処理結果によって後続処理を制御する場合)
    -- ===============================
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_common_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
    errbuf             OUT NOCOPY VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode            OUT NOCOPY VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_exec_div        IN  VARCHAR2,             -- 1.定期随時区分
    iv_base_code       IN  VARCHAR2,             -- 2.拠点コード
    iv_customer_number IN  VARCHAR2              -- 3.顧客コード
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
      iv_which   => cv_log_header_out,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
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
      iv_exec_div,        -- 1.定期随時区分
      iv_base_code,       -- 2.拠点コード
      iv_customer_number, -- 3.顧客コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --*** エラー出力は要件によって使い分けてください ***--
    --エラー出力
/*
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
*/
    --エラー出力：「警告」かつ「mainでメッセージを出力」する要件のある場合
    IF ( lv_retcode != cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_0;
      gn_error_cnt  := cn_1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt + gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_success_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_skip_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
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
END XXCOS004A04C;
/

