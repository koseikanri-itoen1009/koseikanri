CREATE OR REPLACE PACKAGE BODY APPS.XXCOS004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A02C (body)
 * Description      : 商品別売上計算
 * MD.050           : 商品別売上計算 MD050_COS_004_A02
 * Version          : 1.17
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  pram_chk               パラメータチェック(A-1)
 *  get_common_data        共通データ取得(A-2)
 *  get_object_data        店舗別用消化計算データ取得(A-3)
 *  calc_sales             商品別売上算処理(A-4)
 *  set_lines              販売実績明細作成(A-5)
 *  set_headers            販売実績ヘッダ作成(A-6)
 *  update_digestion       消化処理設定(A-7)
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
 *  ar_chk                 AR金額差異チェック処理(A-8)
 *  inv_chk                INV品目数差異チェック処理(A-9)
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   T.kitajima       新規作成
 *  2009/02/05    1.1   T.miyashita      [COS_022]単位換算の不具合
 *  2009/02/05    1.2   T.kitajima       [COS_023]赤黒フラグ設定不具合(仕様漏れ)
 *  2009/02/10    1.3   T.kitajima       [COS_041]納品伝票区分(1:納品)設定(仕様漏れ)
 *  2009/02/10    1.4   T.kitajima       [COS_047]差分明細の納品/基準単位(仕様漏れ)
 *  2009/02/19    1.5   T.kitajima       納品形態区分 メイン倉庫対応
 *  2009/02/24    1.6   T.kitajima       パラメータのログファイル出力対応
 *  2009/03/30    1.7   T.kitajima       [T1_0189]販売実績明細.納品明細番号の採番方法変更
 *  2009/04/20    1.8   T.kitajima       [T1_0657]データ取得0件エラー→警告終了へ
 *  2009/04/28    1.9   N.Maeda          [T1_0769]数量系、金額系の算出方法の修正
 *  2009/05/07    1.10  T.kitajima       [T1_0888]納品拠点取得方法変更
 *                                       [T1_0714]在庫品目数量0除外対応
 *  2009/05/26    1.11  T.kitajima       [T1_1217]単価四捨五入
 *  2009/06/09    1.12  T.kitajima       [T1_1371]行ロック
 *  2009/06/10    1.12  T.kitajima       [T1_1412]納品伝票番号取得処理変更
 *  2009/06/11    1.13  T.kitajima       [T1_1415]納品伝票番号取得処理変更
 *  2009/08/17    1.14  K.Kiriu          [0000430]PT対応
 *  2009/09/11    1.15  M.Sano           [0001345]PT対応
 *  2010/01/18    1.16  K.Atsushiba      [E_本稼動_01110]赤黒フラグの判定条件変更
 *  2010/02/15    1.17  M.Hokkanji       [E_本稼働_01393]店舗別消化計算情報のチェック処理
 *                                       を追加
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
  global_up_headers_expt      EXCEPTION; --店舗別用消化計算ヘッダ更新エラー
  global_up_inv_expt          EXCEPTION; --棚卸管理テーブル更新エラー
  global_quick_salse_err_expt EXCEPTION; --売上区分取得エラー
  global_quick_inv_err_expt   EXCEPTION; --棚卸ステータス
  global_select_err_expt      EXCEPTION; --SQL SELECTエラー
  global_call_api_expt        EXCEPTION; --APIエラー
--****************************** 2009/05/07 1.10 T.Kitajima ADD START ******************************--
  global_quick_not_inv_expt   EXCEPTION; --非在庫品目取得エラー
--****************************** 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
  global_data_lock_expt       EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
  global_inv_chk_err_expt     EXCEPTION; --INV品目データ不一致エラー
  global_ar_chk_err_expt      EXCEPTION; --AR金額不一致エラー
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS004A02C'; -- パッケージ名
--
  --アプリケーション短縮名
  ct_xxcos_appl_short_name  CONSTANT fnd_application.application_short_name%TYPE
                                      :=  'XXCOS';                   --販物短縮アプリ名
  --販物メッセージ
  ct_msg_pram_date          CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10951';               --パラメータメッセージ
  ct_msg_class_cd_err       CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10952';               --定期随時区分チェックエラーメッセージ
  ct_msg_base_cd_err        CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10953';               --拠点コード必須エラー
  ct_msg_item_cd_err        CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10954';               --差異品目コード取得エラーメッセージ
  ct_msg_making_cd_err      CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10955';               --作成元区分取得エラー
  ct_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00013';               --データ取得エラーメッセージ
  ct_msg_process_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00014';               --業務日付取得エラー
  cv_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00018';               --明細0件用メッセージ
  cv_msg_inser_lines_err    CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10956';               --販売実績明細登録エラー
  cv_msg_inser_headers_err  CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10957';               --販売実績ヘッダ登録エラー
  cv_msg_update_headers_err CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10958';               --店舗別用消化計算ヘッダ更新エラー
  cv_msg_update_inv_err     CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10959';               --棚卸管理テーブル更新エラー
  cv_msg_salse_class_err    CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10960';               --売上区分取得エラー
  cv_msg_inv_status_err     CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10961';               --棚卸ステータス取得エラー
  cv_msg_select_store_err   CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10962';               --店舗別用消化計算データ取得エラー
  cv_msg_deli_err           CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10965';               --納品形態取得エラー
  cv_msg_tan_err            CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10966';               --単位換算エラー
  ct_msg_gl_id_err          CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10967';               --GL会計帳簿ID取得エラーメッセージ
  ct_msg_inv_code_err       CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10968';               --在庫組織コード取得エラーメッセージ
  ct_msg_inv_id_err         CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10969';               --在庫組織ID取得エラーメッセージ
  ct_msg_dvl_ptn_calss_err  CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10971';               --商品別売上計算用納品形態区分取得エラーメッセージ
--****************************** 2009/05/07 1.10 T.Kitajima ADD START ******************************--
  ct_msg_delivery_base_err  CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10973';               --納品拠点取得エラーメッセージ
--****************************** 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
  ct_msg_shop_lock_err      CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10974';               --店舗別用消化計算テーブルロック取得エラーメッセージ
  ct_msg_inv_lock_err       CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10975';               --棚卸管理テーブルロック取得エラーメッセージ
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
  ct_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00004';               --プロファイル取得エラー
  cv_msg_ar_chk_err         CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10976';               --AR金額不一致エラーメッセージ
  cv_msg_inv_chk_err        CONSTANT fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-10977';               --INV品目データ不一致エラーメッセージ
  ct_msg_org_id             CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00047';               --MO:営業単位
  ct_msg_max_date           CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00056';               --XXCOS:MAX日付
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
  --クイックコードタイプ
  ct_qct_regular_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_REGULAR_ANY_CLASS';       --定期随時
  ct_qct_making_type        CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_MK_ORG_CLS_MST_004_A02';  --作成元区分
  ct_qct_tax_type           CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_CONSUMPTION_TAX_CLASS';   --HHT消費税区分
  ct_qct_gyo_type           CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_GYOTAI_SHO_MST_004_A01';  --業態小分類特定マスタ_004_A01
  ct_qct_cust_type          CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_CUS_CLASS_MST_004_A02';   --顧客区分特定マスタ
  ct_qct_sales_type         CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_SALE_CLASS_MST_004_A02';  --売上区分特定マスタ
  ct_qct_inv_type           CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_INV_STATUS_MST_004_A02';  --棚卸ステータス特定マスタ
--******************************* 2009/05/07 1.10 T.Kitajima ADD START ******************************--
  ct_qct_not_inv_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_NO_INV_ITEM_CODE';        --非在庫品目コード
--******************************* 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
  --クイックコード
  ct_qcc_sales_code         CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_01';               --消化計算（百貨店専門店）
  ct_qcc_it_code            CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A01%';                 --インショップ/当社直営店
  ct_qcc_digestion_code     CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_04';               --消化・VD消化
  ct_qcc_inv_digestion_code CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_03';               --消化
  ct_qcc_cust_code_1        CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_10%';              --拠点
  ct_qcc_cust_code_2        CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_004_A02_20%';              --顧客
  --トークン
  cv_tkn_parm_data1         CONSTANT  VARCHAR2(10) :=  'PARAM1';           --パラメータ1
  cv_tkn_parm_data2         CONSTANT  VARCHAR2(10) :=  'PARAM2';           --パラメータ2
  cv_tkn_parm_data3         CONSTANT  VARCHAR2(10) :=  'PARAM3';           --パラメータ3
  cv_tkn_parm_data4         CONSTANT  VARCHAR2(10) :=  'PARAM4';           --パラメータ4
  cv_tkn_parm_data5         CONSTANT  VARCHAR2(10) :=  'PARAM5';           --パラメータ5
  cv_tkn_profile            CONSTANT  VARCHAR2(10) :=  'PROFILE';          --プロファイル
  cv_tkn_quick1             CONSTANT  VARCHAR2(10) :=  'QUICK1';           --クイック
  cv_tkn_quick2             CONSTANT  VARCHAR2(10) :=  'QUICK2';           --クイック
  cv_tkn_table              CONSTANT  VARCHAR2(10) :=  'TABLE_NAME';       --テーブル名称
  cv_tkn_key_data           CONSTANT  VARCHAR2(10) :=  'KEY_DATA';         --キーデータ
  --プロファイル名称
  cv_Profile_item_cd        CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_DIGESTION_DIFF_ITEM_CODE';  -- 消化計算差異品目コード
  ct_prof_gl_set_of_bks_id  CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'GL_SET_OF_BKS_ID';                 -- GL会計帳簿ID
  ct_prof_organization_code CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOI1_ORGANIZATION_CODE';
                                                                             -- XXCOI:在庫組織コード
  ct_prof_dlv_ptn_cls       CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_PROD_SLS_CALC_DLV_PTN_CLS';
                                                                             -- XXCOS:商品別売上計算用納品形態区分
  --使用可能フラグ定数
  ct_enabled_flag_yes       CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                      := 'Y';                              --使用可能
  --拠点/顧客,上様フラグ
  ct_customer_flag_no       CONSTANT  fnd_lookup_values.attribute2%TYPE
                                      := 'N';                              --顧客,上様
  ct_customer_flag_yes      CONSTANT  fnd_lookup_values.attribute2%TYPE
                                      := 'Y';                              --拠点
  --店舗ヘッダ用フラグ
  ct_make_flag_yes          CONSTANT  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                      := 'Y';                              --作成済み
  ct_make_flag_no           CONSTANT  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                      := 'N';                              --未作成
  ct_un_calc_flag_0         CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                      := 0;                                --未計算フラグ
  ct_un_calc_flag_1         CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                      := 1;                                --未計算フラグ
  --赤黒フラグ
  ct_red_black_flag_0       CONSTANT  xxcos_sales_exp_lines.red_black_flag%TYPE
                                      := '0';                              --赤
  ct_red_black_flag_1       CONSTANT  xxcos_sales_exp_lines.red_black_flag%TYPE
                                      := '1';                              --黒
  --手数料計算インタフェース済フラグ
  ct_to_calculate_fees_flag CONSTANT  xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE
                                      := 'N';                              --NO
  --単価マスタ作成済フラグ
  ct_unit_price_mst_flag    CONSTANT  xxcos_sales_exp_lines.unit_price_mst_flag%TYPE
                                      := 'N';                              --NO
  --INVインタフェース済フラグ
  ct_inv_interface_flag     CONSTANT  xxcos_sales_exp_lines.inv_interface_flag%TYPE
                                      := 'N';                              --NO
  --ARインタフェース済フラグ
  ct_ar_interface_flag      CONSTANT  xxcos_sales_exp_headers.ar_interface_flag%TYPE
                                      := 'N';                              --NO
  --GLインタフェース済フラグ
  ct_gl_interface_flag      CONSTANT  xxcos_sales_exp_headers.gl_interface_flag%TYPE
                                      := 'N';                              --NO
  --情報システムインタフェース済フラグ
  ct_dwh_interface_flag     CONSTANT  xxcos_sales_exp_headers.dwh_interface_flag%TYPE
                                      := 'N';                              --NO
  --EDI送信済みフラグ
  ct_edi_interface_flag     CONSTANT  xxcos_sales_exp_headers.edi_interface_flag%TYPE
                                      := 'N';                              --NO
  --カード売り区分
  ct_card_flag_cash         CONSTANT  xxcos_sales_exp_headers.card_sale_class%TYPE
                                      := '0';                              --0:現金
  --AR税金マスタ有効フラグ
  ct_tax_enabled_yes        CONSTANT  ar_vat_tax_all_b.enabled_flag%TYPE
                                      := 'Y';                              --Y:有効
  --納品伝票区分
  ct_deliver_slip_div       CONSTANT  xxcos_sales_exp_headers.dlv_invoice_class%TYPE
                                      := '1';                              --1:納品
  cn_dmy                    CONSTANT  NUMBER := 0;
--******************************* 2009/04/28 1.9 N.Maeda ADD START **************************************************************
  cn_quantity_num           CONSTANT  NUMBER := 1;                         --数量系固定値(1)
  cn_differ_business_cost   CONSTANT  NUMBER := 0;                         --差異品目営業原価(0)
--******************************* 2009/04/28 1.9 N.Maeda ADD  END  **************************************************************
--******************************* 2009/05/07 1.10 T.Kitajima ADD START ******************************--
  cn_sales_zero             CONSTANT  NUMBER := 0;                         --在庫0
--******************************* 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
--******************************* 2009/06/10 1.12 T.Kitajima ADD START ******************************--
  cv_snq_i                  CONSTANT  VARCHAR2(1) :=  'I';
--******************************* 2009/06/10 1.12 T.Kitajima ADD  END  ******************************--
/* 2009/08/17 Ver1.14 Add Start */
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語
/* 2009/08/17 Ver1.14 Add End   */
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
  ct_prof_org_id            CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'ORG_ID';                           --MO:営業単位
  ct_prof_max_date          CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_MAX_DATE';       --MAX日付
  ct_un_calc_flag_4         CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                      := '4';                              --未計算フラグ
  --棚卸区分
  ct_inventory_class_2      CONSTANT   xxcoi_inv_reception_monthly.inventory_kbn%TYPE
                                      := '2';                              --月末
  --棚卸対象区分
  ct_secondary_class_2      CONSTANT   mtl_secondary_inventories.attribute5%TYPE
                                      := '2';                              --消化
  --フォーマット
  cv_fmt_date               CONSTANT  VARCHAR2(10)  := 'RRRR/MM/DD';
  cv_fmt_yyyymm             CONSTANT  VARCHAR2(6)   := 'YYYYMM';
  cv_fmt_mm                 CONSTANT  VARCHAR2(6)   := 'MM';
  --完了フラグ
  ct_complete_flag_yes      CONSTANT  ra_customer_trx_all.complete_flag%TYPE
                                      := 'Y';                              --完了
  --明細タイプ
  ct_line_type_line         CONSTANT  ra_customer_trx_lines_all.line_type%TYPE
                                      := 'LINE';                           --LINE
  ct_qcc_customer_trx_type  CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS_004_A01%';        --ＡＲ取引タイプ特定マスタ
  ct_qct_customer_trx_type  CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_AR_TRX_TYPE_MST_004_A01';
                                                                  --ＡＲ取引タイプ特定マスタ_004_A01
  --存在フラグ
  cv_exists_flag_yes        CONSTANT  VARCHAR2(1) := 'Y';         --存在あり
  cv_exists_flag_no         CONSTANT  VARCHAR2(1) := 'N';         --存在なし
  --定期随時区分
  cv_exec_div_0             CONSTANT  VARCHAR2(1) := '0';         --定期随時区分(随時)
  cv_exec_div_1             CONSTANT  VARCHAR2(1) := '1';         --定期随時区分(定期)
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 店舗別用消化計算データ格納用変数
  TYPE g_rec_work_data IS RECORD
    (
      shop_digestion_hdr_id       xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE,      --店舗別用消化計算ヘッダID
      digestion_due_date          xxcos_shop_digestion_hdrs.digestion_due_date%TYPE,         --消化計算締年月日
      customer_number             xxcos_shop_digestion_hdrs.customer_number%TYPE,            --顧客コード
      sales_base_code             xxcos_shop_digestion_hdrs.sales_base_code%TYPE,            --売上拠点コード
      cust_account_id             xxcos_shop_digestion_hdrs.cust_account_id%TYPE,            --顧客ID
      digestion_exe_date          xxcos_shop_digestion_hdrs.digestion_exe_date%TYPE,         --消化計算実行日
      ar_sales_amount             xxcos_shop_digestion_hdrs.ar_sales_amount%TYPE,            --店舗別売上金額
      check_sales_amount          xxcos_shop_digestion_hdrs.check_sales_amount%TYPE,         --チェック用売上金額
      digestion_calc_rate         xxcos_shop_digestion_hdrs.digestion_calc_rate%TYPE,        --消化計算掛率
      master_rate                 xxcos_shop_digestion_hdrs.master_rate%TYPE,                --マスタ掛率
      balance_amount              xxcos_shop_digestion_hdrs.balance_amount%TYPE,             --差額
      cust_gyotai_sho             xxcos_shop_digestion_hdrs.cust_gyotai_sho%TYPE,            --業態小分類
      performance_by_code         xxcos_shop_digestion_hdrs.performance_by_code%TYPE,        --成績者コード
      sales_result_creation_date  xxcos_shop_digestion_hdrs.sales_result_creation_date%TYPE, --販売実績登録日
      sales_result_creation_flag  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE, --販売実績作成済フラグ
      pre_digestion_due_date      xxcos_shop_digestion_hdrs.pre_digestion_due_date%TYPE,     --前回消化計算締年月日
      uncalculate_class           xxcos_shop_digestion_hdrs.uncalculate_class%TYPE,          --未計算区分
      shop_digestion_ln_id        xxcos_shop_digestion_lns.shop_digestion_ln_id%TYPE,        --店舗別用消化計算明細ID
      digestion_ln_number         xxcos_shop_digestion_lns.digestion_ln_number%TYPE,         --枝番
      item_code                   xxcos_shop_digestion_lns.item_code%TYPE,                   --品目コード
      invent_seq                  xxcos_shop_digestion_lns.invent_seq%TYPE,                  --棚卸SEQ
      item_price                  xxcos_shop_digestion_lns.item_price%TYPE,                  --定価
      inventory_item_id           xxcos_shop_digestion_lns.inventory_item_id%TYPE,           --品目ID
      business_cost               xxcos_shop_digestion_lns.business_cost%TYPE,               --営業原価
      standard_cost               xxcos_shop_digestion_lns.standard_cost%TYPE,               --標準原価
      item_sales_amount           xxcos_shop_digestion_lns.item_sales_amount%TYPE,           --店舗品目別販売金額
      uom_code                    xxcos_shop_digestion_lns.uom_code%TYPE,                    --単位コード
      sales_quantity              xxcos_shop_digestion_lns.sales_quantity%TYPE,              --販売数
      delivery_base_code          xxcos_shop_digestion_lns.delivery_base_code%TYPE,          --納品拠点コード
      ship_from_subinventory_code xxcos_shop_digestion_lns.ship_from_subinventory_code%TYPE, --出荷元保管場所
      past_sale_base_code         xxcmm_cust_accounts.past_sale_base_code%TYPE,              --前月売上拠点コード
      tax_div                     xxcmm_cust_accounts.tax_div%TYPE,                          --消費税区分
      tax_rounding_rule           hz_cust_site_uses_all.tax_rounding_rule%TYPE,              --税金－端数処理
      tax_code                    ar_vat_tax_all_b.tax_code%TYPE,                            --AR税コード
      tax_rate                    ar_vat_tax_all_b.tax_rate%TYPE,                            --消費税率
      cash_receiv_base_code       xxcfr_cust_hierarchy_v.cash_receiv_base_code%TYPE            --入金拠点コード
  );
  --更新用
  TYPE g_tab_shop_digestion_hdr_id IS TABLE OF xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE
    INDEX BY PLS_INTEGER;   -- 店舗別用消化計算ヘッダID
  TYPE g_tab_invent_seq            IS TABLE OF xxcos_shop_digestion_lns.invent_seq%TYPE
    INDEX BY PLS_INTEGER;   -- 棚卸SEQ
  --テーブル定義
  TYPE g_tab_work_data             IS TABLE OF g_rec_work_data INDEX BY PLS_INTEGER;                     --店舗別用消化計算データ格納用変数
  TYPE g_tab_sales_exp_headers     IS TABLE OF xxcos_sales_exp_headers%ROWTYPE INDEX BY PLS_INTEGER;     --販売実績ヘッダ
  TYPE g_tab_sales_exp_lines       IS TABLE OF xxcos_sales_exp_lines%ROWTYPE INDEX BY PLS_INTEGER;       --販売実績明細
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_business_date                DATE;                                  --業務日付
  gd_last_month_date              DATE;                                  --先月末日付
  gn_list_cnt                     NUMBER;                                --対象件数
  gn_gl_id                        NUMBER;                                --会計帳簿ID
  gv_item_code                    VARCHAR2(10);                          --消化計算差異品目コード
  gv_dvl_ptn_class                VARCHAR2(10);                          --:商品別売上計算用納品形態区分
  gv_item_unit                    VARCHAR2(10);                          --消化計算差異品目単位
  gv_making_code                  VARCHAR2(1);                           --作成元区分
  gv_sales_class_vd               VARCHAR2(1);                           --消化・VD消化
  gv_inv_status                   VARCHAR2(1);                           --棚卸ステータス(消化)
  gt_tab_work_data                g_tab_work_data;                       --対象データ取得用
  gt_tab_sales_exp_headers        g_tab_sales_exp_headers;               --販売実績ヘッダ
  gt_tab_sales_exp_lines          g_tab_sales_exp_lines;                 --販売実績明細
  gt_tab_sales_exp_lines_ins      g_tab_sales_exp_lines;                 --販売実績明細
  gt_tab_shop_digestion_hdr_id    g_tab_shop_digestion_hdr_id;           --店舗別用消化計算ヘッダID
  gt_tab_invent_seq               g_tab_invent_seq;                      --棚卸SEQ
  gt_tab_invent_seq_up            g_tab_invent_seq;                      --棚卸SEQ
  gt_organization_code            mtl_parameters.organization_code%TYPE; --在庫組織コード
  gt_organization_id              mtl_parameters.organization_id%TYPE;   --在庫組織ID
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
  gt_un_calc_flag                 xxcos_shop_digestion_hdrs.uncalculate_class%TYPE;
                                                                         --未計算フラグ
  gn_org_id                       NUMBER;                                -- 営業単位
  gd_begi_month_date              DATE;                                  -- 前月開始日
  gv_month_date                   VARCHAR(6);                            -- 前月(年月)
  gd_max_date                     DATE;                                  -- MAX日付
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
--
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
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_pram_date
                    ,iv_token_name1  => cv_tkn_parm_data1
                    ,iv_token_value1 => iv_exec_div
                    ,iv_token_name2  => cv_tkn_parm_data2
                    ,iv_token_value2 => iv_base_code
                    ,iv_token_name3  => cv_tkn_parm_data3
                    ,iv_token_value3 => iv_customer_number
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
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
      ,buff   => NULL
    );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : pram_chk
   * Description      : パラーメータチェック(A-1)
   ***********************************************************************************/
  PROCEDURE pram_chk(
    iv_exec_div   IN            VARCHAR2,     -- 1.定期随時区分
    iv_base_code  IN            VARCHAR2,     -- 2.拠点コード
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
    --2.日付取得
    --==============================================================
--
    --前月終了年月日取得
    gd_last_month_date := LAST_DAY(ADD_MONTHS( gd_business_date ,-1 ));
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
    --前月開始年月日取得
    gd_begi_month_date := TRUNC( ADD_MONTHS( gd_business_date, -1 ), cv_fmt_mm );
    --前月年月取得
    gv_month_date      := TO_CHAR( gd_begi_month_date, cv_fmt_yyyymm );
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
--
    --==============================================================
    --3.定期随時区分のチェックをします。
    --==============================================================
    SELECT COUNT(flv.meaning)
    INTO   ln_cnt
/* 2009/08/17 Ver1.14 Mod Start */
--    FROM   fnd_application               fa,
--           fnd_lookup_types              flt,
--           fnd_lookup_values             flv
--    WHERE  fa.application_id                               = flt.application_id
--    AND    flt.lookup_type                                 = flv.lookup_type
--    AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--    AND    flv.lookup_type                                 = ct_qct_regular_type
--    AND    flv.lookup_code                                 = iv_exec_div
--    AND    flv.start_date_active                          <= gd_last_month_date
--    AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--    AND    flv.enabled_flag                                = ct_enabled_flag_yes
--    AND    flv.language                                    = USERENV( 'LANG' )
--    AND    ROWNUM                                          = 1
    FROM   fnd_lookup_values  flv
    WHERE  flv.lookup_type      = ct_qct_regular_type
    AND    flv.lookup_code      = iv_exec_div
    AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                AND     NVL( flv.end_date_active, gd_last_month_date )
    AND    flv.enabled_flag     = ct_enabled_flag_yes
    AND    flv.language         = ct_lang
    AND    ROWNUM               = 1
/* 2009/08/17 Ver1.14 Mod End   */
    ;
--
    IF ( ln_cnt = 0 ) THEN
      RAISE global_quick_err_expt;
    END IF;
    --==============================================================
    --3.随時実行の場合、拠点コードのチェックをします。
    --==============================================================
    IF ( iv_exec_div = 0 ) THEN
      IF ( iv_base_code IS NULL ) THEN
        RAISE global_base_err_expt;
      END IF;
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
      --==========================================================================
      --4.随時実行の場合、未計算区分に0:INV/ARともにデータが存在するをセットします
      --==========================================================================
      gt_un_calc_flag := ct_un_calc_flag_0;
    ELSE
      --========================================================================================
      --5.定期実行の場合、未計算区分に4:INV/ARともにデータが存在するが掛け率が異常をセットします
      --========================================================================================
      gt_un_calc_flag := ct_un_calc_flag_4;
    END IF;
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
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
    lv_pro_id   VARCHAR2(100);   --プロファイルID
    lv_err_code VARCHAR2(100);   --エラーID
    lv_org_id   VARCHAR2(5000);
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
    lv_str_profile_name   VARCHAR2(5000);                     --プロファイル名
    lv_max_date           VARCHAR2(5000);                     --MAX日付
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END **************************************************************
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
    --==============================================
    -- 1.「XXCOS1_DIGESTION_DIFF_ITEM_CODE: 消化計算差異品目コード」を取得します。
    --==============================================
    gv_item_code := FND_PROFILE.VALUE(cv_Profile_item_cd);
    --ディレクト未取得
    IF ( gv_item_code IS NULL ) THEN
      lv_err_code := ct_msg_item_cd_err;
      lv_pro_id   := cv_Profile_item_cd;
      RAISE global_get_profile_expt;
    END IF;
    --==============================================
    -- 2.クイックコード「作成元区分(消化計算（百貨店専門店）)」を取得します。
    --==============================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_making_code
/* 2009/08/17 Ver1.14 Mod Start */
--      FROM   fnd_application               fa,
--             fnd_lookup_types              flt,
--             fnd_lookup_values             flv
--      WHERE  fa.application_id                               = flt.application_id
--      AND    flt.lookup_type                                 = flv.lookup_type
--      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                                 = ct_qct_making_type
--      AND    flv.lookup_code                                 = ct_qcc_sales_code
--      AND    flv.start_date_active                          <= gd_last_month_date
--      AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--      AND    flv.enabled_flag                                = ct_enabled_flag_yes
--      AND    flv.language                                    = USERENV( 'LANG' )
--      AND    ROWNUM                                          = 1
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type      = ct_qct_making_type
      AND    flv.lookup_code      = ct_qcc_sales_code
      AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                  AND     NVL( flv.end_date_active, gd_last_month_date )
      AND    flv.enabled_flag     = ct_enabled_flag_yes
      AND    flv.language         = ct_lang
      AND    ROWNUM               = 1
/* 2009/08/17 Ver1.14 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_err_expt;
    END;
    --==============================================
    -- 3.クイックコード「売上区分(4：消化・VD消化)」を取得します。
    --==============================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_sales_class_vd
/* 2009/08/17 Ver1.14 Mod Start */
--      FROM   fnd_application               fa,
--             fnd_lookup_types              flt,
--             fnd_lookup_values             flv
--      WHERE  fa.application_id                               = flt.application_id
--      AND    flt.lookup_type                                 = flv.lookup_type
--      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                                 = ct_qct_sales_type
--      AND    flv.lookup_code                                 = ct_qcc_digestion_code
--      AND    flv.start_date_active                          <= gd_last_month_date
--      AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--      AND    flv.enabled_flag                                = ct_enabled_flag_yes
--      AND    flv.language                                    = USERENV( 'LANG' )
--      AND    ROWNUM                                          = 1
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type      = ct_qct_sales_type
      AND    flv.lookup_code      = ct_qcc_digestion_code
      AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                  AND     NVL( flv.end_date_active, gd_last_month_date )
      AND    flv.enabled_flag     = ct_enabled_flag_yes
      AND    flv.language         = ct_lang
      AND    ROWNUM               = 1
/* 2009/08/17 Ver1.14 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_salse_err_expt;
    END;
    --==============================================
    -- 4.クイックコード「棚卸ステータス(3：消化)」を取得します。
    --==============================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_inv_status
/* 2009/08/17 Ver1.14 Mod Start */
--      FROM   fnd_application               fa,
--             fnd_lookup_types              flt,
--             fnd_lookup_values             flv
--      WHERE  fa.application_id                               = flt.application_id
--      AND    flt.lookup_type                                 = flv.lookup_type
--      AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--      AND    flv.lookup_type                                 = ct_qct_inv_type
--      AND    flv.lookup_code                                 = ct_qcc_inv_digestion_code
--      AND    flv.start_date_active                          <= gd_last_month_date
--      AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--      AND    flv.enabled_flag                                = ct_enabled_flag_yes
--      AND    flv.language                                    = USERENV( 'LANG' )
--      AND    ROWNUM                                          = 1
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type      = ct_qct_inv_type
      AND    flv.lookup_code      = ct_qcc_inv_digestion_code
      AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                  AND     NVL( flv.end_date_active, gd_last_month_date )
      AND    flv.enabled_flag     = ct_enabled_flag_yes
      AND    flv.language         = ct_lang
      AND    ROWNUM               = 1
/* 2009/08/17 Ver1.14 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_quick_inv_err_expt;
    END;
--
    --============================================
    -- 5. 会計帳簿ID
    --============================================
    lv_gl_id := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
    --GL会計帳簿ID
    IF ( lv_gl_id IS NULL ) THEN
      lv_err_code := ct_msg_gl_id_err;
      lv_pro_id   := ct_prof_gl_set_of_bks_id;
      RAISE global_get_profile_expt;
    ELSE
      gn_gl_id := TO_NUMBER(lv_gl_id);
    END IF;
--
    --============================================
    -- 6.XXCOI:在庫組織コード
    --============================================
    gt_organization_code      := FND_PROFILE.VALUE( ct_prof_organization_code );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_organization_code IS NULL ) THEN
      lv_err_code := ct_msg_inv_code_err;
      lv_pro_id   := ct_prof_organization_code;
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --============================================
    -- 7. 在庫組織IDの取得
    --============================================
    gt_organization_id        := xxcoi_common_pkg.get_organization_id(
                                   iv_organization_code          => gt_organization_code
                                 );
    --
    IF ( gt_organization_id IS NULL ) THEN
      RAISE global_call_api_expt;
    END IF;

    --============================================
    -- 8. 差分品目の基準単位取得
    --============================================
    BEGIN
      SELECT msi.primary_unit_of_measure 
      INTO   gv_item_unit
      FROM   mtl_system_items_b msi
      WHERE  msi.segment1 = gv_item_code
      AND    msi.organization_id = gt_organization_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code := ct_msg_item_cd_err;
        lv_pro_id   := cv_Profile_item_cd;
        RAISE global_get_profile_expt;
    END;
    --==============================================
    -- 9.「XXCOS1_PROD_SLS_CALC_DLV_PTN_CLS:商品別売上計算用納品形態区分」を取得します。
    --==============================================
    gv_dvl_ptn_class := FND_PROFILE.VALUE(ct_prof_dlv_ptn_cls);
    --ディレクト未取得
    IF ( gv_dvl_ptn_class IS NULL ) THEN
      lv_err_code := ct_msg_dvl_ptn_calss_err;
      lv_pro_id   := ct_prof_dlv_ptn_cls;
      RAISE global_get_profile_expt;
    END IF;
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
    --==================================
    -- 10.MO:営業単位
    --==================================
    lv_org_id                 := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_org_id IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_org_id
                                 );
      lv_err_code := ct_msg_get_profile_err;
      lv_pro_id   := lv_str_profile_name;
      RAISE global_get_profile_expt;
    END IF;
--
    gn_org_id                 := TO_NUMBER( lv_org_id );
    --==================================
    -- 2.XXCOS:MAX日付
    --==================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_max_date IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_date
                                 );
      lv_err_code := ct_msg_get_profile_err;
      lv_pro_id   := lv_str_profile_name;
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
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
                                   iv_name               => lv_err_code,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_pro_id
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
                                   iv_token_value2       => ct_qcc_sales_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** クイックコード取得エラー例外ハンドラ ***
    WHEN global_quick_salse_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_salse_class_err,
                                   iv_token_name1        => cv_tkn_quick1,
                                   iv_token_value1       => ct_qct_sales_type,
                                   iv_token_name2        => cv_tkn_quick2,
                                   iv_token_value2       => ct_qcc_digestion_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** クイックコード取得エラー例外ハンドラ ***
    WHEN global_quick_inv_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_inv_status_err,
                                   iv_token_name1        => cv_tkn_quick1,
                                   iv_token_value1       => ct_qct_inv_type,
                                   iv_token_name2        => cv_tkn_quick2,
                                   iv_token_value2       => ct_qcc_inv_digestion_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 在庫組織ID取得エラー例外ハンドラ ***
    WHEN global_call_api_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_inv_id_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
   * Description      : 店舗別用消化計算データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_object_data(
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
    CURSOR get_data_cur
    IS
/* 2009/08/17 Ver1.14 Mod Start */
--      SELECT xsdh.shop_digestion_hdr_id         shop_digestion_hdr_id,            --店舗別用消化計算ヘッダID
/* 2009/09/11 Ver1.15 Mod Start */
--        SELECT /*+
--                 LEADING(xsdh)
--                 INDEX(xsdh xxcos_shop_digestion_hdrs_n04 )
--                 INDEX(xxca xxcmm_cust_accounts_pk)
--                 USE_NL(xchv.cust_hier.cash_hcar_3)
--                 USE_NL(xchv.cust_hier.bill_hasa_3)
--                 USE_NL(xchv.cust_hier.bill_hasa_4)
--                 USE_NL(flv xxca)
--               */
        SELECT /*+
                 LEADING(xsdh)
                 INDEX(xsdh xxcos_shop_digestion_hdrs_n04 )
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
/* 2009/09/11 Ver1.15 Mod Start */
             xsdh.shop_digestion_hdr_id         shop_digestion_hdr_id,            --店舗別用消化計算ヘッダID
/* 2009/08/17 Ver1.14 Mod End   */
             xsdh.digestion_due_date            digestion_due_date,               --消化計算締年月日
             xsdh.customer_number               customer_number,                  --顧客コード
             xsdh.sales_base_code               sales_base_code,                  --売上拠点コード
             xsdh.cust_account_id               cust_account_id,                  --顧客ID
             xsdh.digestion_exe_date            digestion_exe_date,               --消化計算実行日
             xsdh.ar_sales_amount               ar_sales_amount,                  --店舗別売上金額
             xsdh.check_sales_amount            check_sales_amount,               --チェック用売上金額
             xsdh.digestion_calc_rate           digestion_calc_rate,              --消化計算掛率
             xsdh.master_rate                   master_rate,                      --マスタ掛率
             xsdh.balance_amount                balance_amount,                   --差額
             xsdh.cust_gyotai_sho               cust_gyotai_sho,                  --業態小分類
             xsdh.performance_by_code           performance_by_code,              --成績者コード
             xsdh.sales_result_creation_date    sales_result_creation_date,       --販売実績登録日
             xsdh.sales_result_creation_flag    sales_result_creation_flag,       --販売実績作成済フラグ
             xsdh.pre_digestion_due_date        pre_digestion_due_date,           --前回消化計算締年月日
             xsdh.uncalculate_class             uncalculate_class,                --未計算区分
             xsdl.shop_digestion_ln_id          shop_digestion_ln_id,             --店舗別用消化計算明細ID
             xsdl.digestion_ln_number           digestion_ln_number,              --枝番
             xsdl.item_code                     item_code,                        --品目コード
             xsdl.invent_seq                    invent_seq,                       --棚卸SEQ
             xsdl.item_price                    item_price,                       --定価
             xsdl.inventory_item_id             inventory_item_id,                --品目ID
             xsdl.business_cost                 business_cost,                    --営業原価
             xsdl.standard_cost                 standard_cost,                    --標準原価
             xsdl.item_sales_amount             item_sales_amount,                --店舗品目別販売金額
             xsdl.uom_code                      uom_code,                         --単位コード
             xsdl.sales_quantity                sales_quantity,                   --販売数
             xsdl.delivery_base_code            delivery_base_code,               --納品拠点コード
             xsdl.ship_from_subinventory_code   ship_from_subinventory_code,      --出荷元保管場所
             xxca.past_sale_base_code           past_sale_base_code,              --前月売上拠点コード
             xxca.tax_div                       tax_div,                          --消費税区分
             hnas.tax_rounding_rule             tax_rounding_rule,                --税金－端数処理
             avta.tax_code                      tax_code,                         --AR税コード
             avta.tax_rate                      tax_rate,                         --消費税率
             xchv.cash_receiv_base_code         cash_receiv_base_code               --入金拠点コード
      FROM   xxcos_shop_digestion_hdrs xsdh,    -- 店舗別用消化計算ヘッダテーブル
             xxcos_shop_digestion_lns  xsdl,    -- 店舗別用消化計算明細テーブル
             hz_cust_accounts          hnas,    -- 顧客マスタ
             xxcmm_cust_accounts       xxca,    -- 顧客アドオンマスタ
/* 2009/08/17 Ver1.14 Mod Start */
--             xxcfr_cust_hierarchy_v    xchv,    -- 顧客階層VIEW
             xxcos_cust_hierarchy_v    xchv,    -- 顧客階層VIEW
/* 2009/08/17 Ver1.14 Mod End   */
             ar_vat_tax_all_b          avta,    -- AR税金マスタ
/* 2009/08/17 Ver1.14 Mod Start */
--             (SELECT flv.attribute3  tax_class,
--                     flv.attribute2  tax_code
--              FROM   fnd_application               fa,
--                     fnd_lookup_types              flt,
--                     fnd_lookup_values             flv
--              WHERE  fa.application_id                               = flt.application_id
--              AND    flt.lookup_type                                 = flv.lookup_type
--              AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--              AND    flv.lookup_type                                 = ct_qct_tax_type
--              AND    flv.start_date_active                          <= gd_last_month_date
--              AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--              AND    flv.enabled_flag                                = ct_enabled_flag_yes
--              AND    flv.language                                    = USERENV( 'LANG' )
--             ) tcm,
             fnd_lookup_values         flv,
/* 2009/08/17 Ver1.14 Mod End   */
             (
              SELECT hca.account_number  account_number         --顧客コード
              FROM   hz_cust_accounts    hca,                   --顧客マスタ
                     xxcmm_cust_accounts xca                    --顧客アドオン
              WHERE  hca.cust_account_id     = xca.customer_id --顧客マスタ.顧客ID   = 顧客アドオン.顧客ID
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_cust_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
--                             AND    flv.start_date_active                          <=    gd_last_month_date
--                             AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning                                     =    hca.customer_class_code
                             FROM   fnd_lookup_values  flv
                             WHERE  flv.lookup_type      = ct_qct_cust_type
                             AND    flv.lookup_code      LIKE ct_qcc_cust_code_2
                             AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                         AND     NVL( flv.end_date_active, gd_last_month_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = hca.customer_class_code
/* 2009/08/17 Ver1.14 Mod End   */
                            ) --顧客マスタ.顧客区分 = 10(顧客)
              AND    EXISTS (SELECT hcae.account_number --拠点コード
                               FROM   hz_cust_accounts    hcae,
/* 2009/08/17 Ver1.14 Mod Start */
--                                      xxcmm_cust_accounts xcae
                                      xxcmm_cust_accounts xcae,
                                      fnd_lookup_values   flv
/* 2009/08/17 Ver1.14 Mod End   */
                               WHERE  hcae.cust_account_id = xcae.customer_id--顧客マスタ.顧客ID =顧客アドオン.顧客ID
/* 2009/08/17 Ver1.14 Mod Start */
--                               AND    EXISTS (SELECT flv.meaning
--                                              FROM   fnd_application               fa,
--                                                     fnd_lookup_types              flt,
--                                                     fnd_lookup_values             flv
--                                              WHERE  fa.application_id                               =    flt.application_id
--                                              AND    flt.lookup_type                                 =    flv.lookup_type
--                                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                                              AND    flv.lookup_type                                 =    ct_qct_cust_type
--                                              AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_1
--                                              AND    flv.start_date_active                          <=    gd_last_month_date
--                                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                                              AND    flv.language                                    =    USERENV( 'LANG' )
--                                              AND    flv.meaning                                     =    hcae.customer_class_code
--                                             ) --顧客マスタ.顧客区分 = 1(拠点)
--                               AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
--                                               --顧客顧客アドオン.管理元拠点コード = INパラ拠点コード
                               AND    flv.lookup_type      = ct_qct_cust_type
                               AND    flv.lookup_code      LIKE ct_qcc_cust_code_1
                               AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                           AND     NVL( flv.end_date_active, gd_last_month_date )
                               AND    flv.enabled_flag     = ct_enabled_flag_yes
                               AND    flv.language         = ct_lang
                               AND    flv.meaning          = hcae.customer_class_code
                               AND    (
                                        ( iv_base_code IS NULL )
                                        OR
                                        ( iv_base_code IS NOT NULL AND  xcae.management_base_code = iv_base_code )
                                      ) --顧客顧客アドオン.管理元拠点コード = INパラ拠点コード
/* 2009/08/17 Ver1.14 Mod End   */
                               AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                              ) --管理拠点に所属する拠点コード=顧客アドオン.前月拠点or売上拠点
/* 2009/08/17 Ver1.14 Mod Start */
--              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード=INパラ(顧客コード)
              AND    (
                       ( iv_customer_number IS NULL )
                       OR
                       ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                     ) --顧客コード=INパラ(顧客コード)
/* 2009/08/17 Ver1.14 Mod End   */
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_it_code
--                             AND    flv.start_date_active                          <=    gd_last_month_date
--                             AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning = xca.business_low_type
                             FROM   fnd_lookup_values  flv
                             WHERE  flv.lookup_type      = ct_qct_gyo_type
                             AND    flv.lookup_code      LIKE ct_qcc_it_code
                             AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                         AND     NVL( flv.end_date_active, gd_last_month_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = xca.business_low_type
/* 2009/08/17 Ver1.14 Mod End   */
                            )  --業態小分類=インショップ,当社直営店
              UNION
              SELECT hca.account_number  account_number         --顧客コード
              FROM   hz_cust_accounts    hca,                   --顧客マスタ
                     xxcmm_cust_accounts xca                    --顧客アドオン
              WHERE  hca.cust_account_id     = xca.customer_id --顧客マスタ.顧客ID   = 顧客アドオン.顧客ID
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_cust_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
--                             AND    flv.start_date_active                          <=    gd_last_month_date
--                             AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning                                     =    hca.customer_class_code
                             FROM   fnd_lookup_values  flv
                             WHERE  flv.lookup_type      = ct_qct_cust_type
                             AND    flv.lookup_code      LIKE ct_qcc_cust_code_2
                             AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                         AND     NVL( flv.end_date_active, gd_last_month_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = hca.customer_class_code
/* 2009/08/17 Ver1.14 Mod End   */
                            ) --顧客マスタ.顧客区分 = 10(顧客)
              AND    (
                      xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                      OR
                      xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                     )--顧客アドオン.前月拠点or売上拠点 = INパラ拠点コード
/* 2009/08/17 Ver1.14 Mod Start */
--              AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード=INパラ(顧客コード)
              AND    (
                       ( iv_customer_number IS NULL )
                       OR
                       ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                     ) --顧客コード=INパラ(顧客コード)
/* 2009/08/17 Ver1.14 Mod End   */
              AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                             FROM   fnd_application               fa,
--                                    fnd_lookup_types              flt,
--                                    fnd_lookup_values             flv
--                             WHERE  fa.application_id                               =    flt.application_id
--                             AND    flt.lookup_type                                 =    flv.lookup_type
--                             AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                             AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                             AND    flv.lookup_code                                 LIKE ct_qcc_it_code
--                             AND    flv.start_date_active                          <=    gd_last_month_date
--                             AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                             AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                             AND    flv.language                                    =    USERENV( 'LANG' )
--                             AND    flv.meaning = xca.business_low_type
                             FROM   fnd_lookup_values  flv
                             WHERE  flv.lookup_type      = ct_qct_gyo_type
                             AND    flv.lookup_code      LIKE ct_qcc_it_code
                             AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                         AND     NVL( flv.end_date_active, gd_last_month_date )
                             AND    flv.enabled_flag     = ct_enabled_flag_yes
                             AND    flv.language         = ct_lang
                             AND    flv.meaning          = xca.business_low_type
/* 2009/08/17 Ver1.14 Mod End   */
                            )  --業態小分類=インショップ,当社直営店
             ) amt
      WHERE  amt.account_number = xsdh.customer_number                    --ヘッダ.顧客コード           = 取得した顧客コード
      AND    xsdh.shop_digestion_hdr_id                = xsdl.shop_digestion_hdr_id --ヘッダ.ヘッダID             = 明細.ヘッダID
      AND    xsdh.sales_result_creation_flag           = ct_make_flag_no            --ヘッダ.販売実績作成済フラグ = ‘N’
--******************************* 2010/02/15 1.17 M.Hokkanji MOD START **************************************************************
      AND    xsdh.uncalculate_class                    IN (ct_un_calc_flag_0,gt_un_calc_flag) --ヘッダ.未計算区分(0、定期の場合のみ4)
--      AND    xsdh.uncalculate_class                    = ct_un_calc_flag_0          --ヘッダ.未計算区分           = 0
--******************************* 2010/02/15 1.17 M.Hokkanji MOD END   **************************************************************
      AND    xsdh.cust_account_id                      = hnas.cust_account_id       --ヘッダ.顧客ID               = 顧客マスタ.顧客ID
      AND    hnas.cust_account_id                      = xxca.customer_id           --顧客マスタ.顧客ID           = アドオン.顧客ID
/* 2009/08/17 Ver1.14 Mod Start */
--      AND    xxca.tax_div                              = tcm.tax_class              --顧客マスタ. 消費税区分      = 税コード特定マスタ.LOCKUPコード
--      AND    tcm.tax_code                              = avta.tax_code              --税コード特定マスタ.DFF2     = AR税金マスタ.税コード
      AND    flv.lookup_type                           = ct_qct_tax_type
      AND    gd_last_month_date                        BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                       AND     NVL( flv.end_date_active, gd_last_month_date )
      AND    flv.enabled_flag                          = ct_enabled_flag_yes
      AND    flv.language                              = ct_lang
      AND    flv.attribute3                            = xxca.tax_div               --税コード特定マスタ.DFF3     = 顧客マスタ. 消費税区分
      AND    flv.attribute2                            = avta.tax_code              --税コード特定マスタ.DFF2     = AR税金マスタ.税コード
/* 2009/08/17 Ver1.14 Mod End   */
      AND    avta.set_of_books_id                      = gn_gl_id                   --AR税金マスタ.セットブックス = GL会計帳簿ID
      AND    avta.enabled_flag                         = ct_tax_enabled_yes         --AR税金マスタ.有効           = 'Y'
      AND    avta.start_date                          <=    gd_last_month_date      --AR税金マスタ.有効日自      <= 消化計算締日
      AND    NVL( avta.end_date, gd_last_month_date ) >=    gd_last_month_date      --AR税金マスタ.有効日至      >= 消化計算締日
      AND    xsdh.cust_account_id                      = xchv.ship_account_id       --ヘッダ.顧客ID               = 顧客階層VIEW.出荷先顧客ID
--****************************** 2009/05/07 1.10 T.Kitajima ADD START ******************************--
      AND    xsdl.sales_quantity                      != cn_sales_zero
      AND   NOT EXISTS(
                        SELECT flv.lookup_code               not_inv_code
/* 2009/08/17 Ver1.14 Mod Start */
--                        FROM   fnd_application               fa,
--                               fnd_lookup_types              flt,
--                               fnd_lookup_values             flv
--                        WHERE  fa.application_id                               = flt.application_id
--                        AND    flt.lookup_type                                 = flv.lookup_type
--                        AND    fa.application_short_name                       = ct_xxcos_appl_short_name
--                        AND    flv.lookup_type                                 = ct_qct_not_inv_type
--                        AND    flv.start_date_active                          <= gd_last_month_date
--                        AND    NVL( flv.end_date_active, gd_last_month_date ) >= gd_last_month_date
--                        AND    flv.enabled_flag                                = ct_enabled_flag_yes
--                        AND    flv.language                                    = USERENV( 'LANG' )
--                        AND    flv.lookup_code                                 = xsdl.item_code
                        FROM   fnd_lookup_values             flv
                        WHERE  flv.lookup_type      = ct_qct_not_inv_type
                        AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                    AND     NVL( flv.end_date_active, gd_last_month_date )
                        AND    flv.enabled_flag     = ct_enabled_flag_yes
                        AND    flv.language         = ct_lang
                        AND    flv.lookup_code      = xsdl.item_code
/* 2009/08/17 Ver1.14 Mod End   */
                      )
      ORDER BY xsdh.shop_digestion_hdr_id,xsdl.shop_digestion_ln_id
--****************************** 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      FOR UPDATE OF xsdh.shop_digestion_hdr_id,xsdl.invent_seq NOWAIT
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
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
      OPEN get_data_cur;
      -- バルクフェッチ
      FETCH get_data_cur BULK COLLECT INTO gt_tab_work_data;
      --取得件数
      gn_list_cnt := get_data_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE get_data_cur;
    EXCEPTION
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      WHEN global_data_lock_expt THEN
        -- カーソルCLOSE：納品ヘッダワークテーブルデータ取得
        IF ( get_data_cur%ISOPEN ) THEN
          CLOSE get_data_cur;
        END IF;
        RAISE global_data_lock_expt;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      WHEN OTHERS THEN
        -- カーソルCLOSE：納品ヘッダワークテーブルデータ取得
        IF ( get_data_cur%ISOPEN ) THEN
          CLOSE get_data_cur;
        END IF;
        --
        RAISE global_select_err_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --抽出対象が0件だった場合
    IF ( gn_list_cnt = 0 ) THEN
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
--****************************** 2009/04/20 1.8 T.kitajima MOD START ******************************--
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
--****************************** 2009/04/20 1.8 T.kitajima MOD  END  ******************************--
--
    -- *** SQL SELECT エラー ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  cv_msg_select_store_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
--
    -- *** ロック エラー ***
    WHEN global_data_lock_expt     THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_shop_lock_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
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
   * Description      : 商品別売上算処理(A-4)
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
    ln_index               NUMBER;        --INDEX一時保管
    lv_err_work            VARCHAR2(1);   --エラーワーク
    lv_organization_code   VARCHAR2(10);  --在庫組織コード
    lv_organization_id     NUMBER;        --在庫組織ＩＤ
    lv_delivered_from      VARCHAR2(1);   --納品形態
    ln_inventory_item_id   NUMBER;        --品目ＩＤ
    lv_after_uom_code      VARCHAR2(10);  --換算後単位コード
    ln_after_quantity      NUMBER;        --換算後数量
    ln_content             NUMBER;        --品入数
    ln_main_body_total     NUMBER;        --本体金額合計
    ln_business_cost_total NUMBER;        --営業原価合計
    ln_header_id           NUMBER;        --ヘッダID
    ln_line_id             NUMBER;        --明細ID
    ln_difference_money    NUMBER;        --差異金額
    lv_deli_seq            VARCHAR2(12);  --納品伝票番号
    ln_make_flg            NUMBER;        --ヘッダ作成フラグ
--******************************* 2009/03/30 1.7 T.kitajima ADD START ********************************************
    ln_line_index          NUMBER;        --販売実績明細テーブルの納品明細番号
--******************************* 2009/03/30 1.7 T.kitajima ADD  END  ********************************************
--******************************* 2009/05/07 1.10 T.Kitajima ADD START ******************************--
    lt_delivery_base_code  xxcos_sales_exp_lines.delivery_base_code%TYPE;
--******************************* 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
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
    ln_m                   := 1;
    ln_h                   := 1;
    ln_main_body_total     := 0;
    ln_business_cost_total := 0;
    ln_difference_money    := 0;
    lv_err_work            := cv_status_normal;
    ln_index               := 1;
    ln_make_flg            := 0;
--******************************* 2009/03/30 1.7 T.kitajima ADD START ********************************************
    ln_line_index          := 1;
--******************************* 2009/03/30 1.7 T.kitajima ADD  END  ********************************************
    --ヘッダシーケンス取得
    SELECT xxcos_sales_exp_headers_s01.nextval
    INTO   ln_header_id
    FROM   DUAL;
    --納品伝票番号シーケンス取得
--******************************* 2009/06/10 1.12 T.Kitajima MOD START ******************************--
--    lv_deli_seq := xxcos_def_pkg.set_order_number(NULL,NULL);
    SELECT cv_snq_i || TO_CHAR( ( lpad( XXCOS_CUST_PO_NUMBER_S01.nextval, 11, 0) ) )
      INTO lv_deli_seq
      FROM dual;
--******************************* 2009/06/10 1.12 T.Kitajima MOD  END  ******************************--
    -- ループ開始
    FOR ln_i IN 1..gn_list_cnt LOOP
--
      --正常時単位換算を行う。
      IF ( lv_err_work = cv_status_normal ) THEN
          lv_after_uom_code := NULL; --必ずNULLを設定しておくこと。
          --単位換算より設定
          xxcos_common_pkg.get_uom_cnv(
                                       gt_tab_work_data(ln_i).uom_code,
                                       gt_tab_work_data(ln_i).sales_quantity,
                                       gt_tab_work_data(ln_i).item_code,
                                       lv_organization_code,
                                       ln_inventory_item_id,
                                       lv_organization_id,
                                       lv_after_uom_code,
                                       ln_after_quantity,
                                       ln_content,
                                       lv_errbuf,
                                       lv_retcode,
                                       lv_errmsg
                                      );
          IF ( lv_retcode = cv_status_error ) THEN
            --取得エラー
            lv_err_work   := cv_status_warn;
            ov_errmsg     := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => cv_msg_tan_err,
                                         iv_token_name1        => cv_tkn_parm_data1,
                                         iv_token_value1       => gt_tab_work_data(ln_i).shop_digestion_hdr_id,
                                         iv_token_name2        => cv_tkn_parm_data2,
                                         iv_token_value2       => gt_tab_work_data(ln_i).shop_digestion_ln_id,
                                         iv_token_name3        => cv_tkn_parm_data3,
                                         iv_token_value3       => gt_tab_work_data(ln_i).uom_code,
                                         iv_token_name4        => cv_tkn_parm_data4,
                                         iv_token_value4       => gt_tab_work_data(ln_i).sales_quantity,
                                         iv_token_name5        => cv_tkn_parm_data5,
                                         iv_token_value5       => gt_tab_work_data(ln_i).item_code
                                       );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => ov_errmsg
            );
          END IF;
--******************************* 2009/05/07 1.10 T.Kitajima ADD START ******************************--
          --納品拠点コード取得
          BEGIN
            lt_delivery_base_code := NULL;
            --
            SELECT msi.attribute7
              INTO lt_delivery_base_code
              FROM mtl_secondary_inventories msi
             --保管場所マスタ.出荷元保管場所コード = 出荷元保管場所コード
             WHERE msi.secondary_inventory_name    = gt_tab_work_data(ln_i).ship_from_subinventory_code
               --保管場所マスタ.組織ID             = 在庫組織ID
               AND msi.organization_id             = gt_organization_id
            ;
          EXCEPTION
            WHEN OTHERS THEN
              --取得エラー
              lv_err_work   := cv_status_warn;
              ov_errmsg     := xxccp_common_pkg.get_msg(
                                 iv_application        => ct_xxcos_appl_short_name,
                                 iv_name               => ct_msg_delivery_base_err,
                                 iv_token_name1        => cv_tkn_parm_data1,
                                 iv_token_value1       => gt_tab_work_data(ln_i).customer_number,
                                 iv_token_name2        => cv_tkn_parm_data2,
                                 iv_token_value2       => gt_tab_work_data(ln_i).ship_from_subinventory_code
                               );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT,
                buff   => ov_errmsg
              );
          END;
--******************************* 2009/05/07 1.10 T.Kitajima ADD  END  ******************************--
      END IF;
      --
      --正常時のみ.単位換算にてエラーになった場合は、設定処理スルー
      IF ( lv_err_work = cv_status_normal ) THEN
        --1.納品番号採番(保留)
        --未決事項
        --2.明細データ設定
        --明細シーケンス取得
        SELECT xxcos_sales_exp_lines_s01.nextval
        INTO   ln_line_id
        FROM   DUAL;
        --
        gt_tab_sales_exp_lines(ln_m).sales_exp_line_id            := ln_line_id;                                         --販売実績明細ID
        gt_tab_sales_exp_lines(ln_m).sales_exp_header_id          := ln_header_id;                                       --販売実績ヘッダID
        gt_tab_sales_exp_lines(ln_m).dlv_invoice_number           := lv_deli_seq;                                        --納品伝票番号
--******************************* 2009/03/30 1.7 T.kitajima MOD  END  ********************************************
--        gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := gt_tab_work_data(ln_i).shop_digestion_ln_id;        --納品明細番号
        gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := ln_line_index;                                      --納品明細番号
        ln_line_index                                             := ln_line_index + 1; 
--******************************* 2009/03/30 1.7 T.kitajima MOD  END  ********************************************
        gt_tab_sales_exp_lines(ln_m).order_invoice_line_number    := NULL;                                               --注文明細番号
        gt_tab_sales_exp_lines(ln_m).sales_class                  := gv_sales_class_vd;                                  --売上区分
        gt_tab_sales_exp_lines(ln_m).delivery_pattern_class       := gv_dvl_ptn_class;                                   --納品形態区分
        gt_tab_sales_exp_lines(ln_m).item_code                    := gt_tab_work_data(ln_i).item_code;                   --品目コード
        gt_tab_sales_exp_lines(ln_m).dlv_qty                      := gt_tab_work_data(ln_i).sales_quantity;              --納品数量
        gt_tab_sales_exp_lines(ln_m).standard_qty                 := ln_after_quantity;                                  --基準数量
        gt_tab_sales_exp_lines(ln_m).dlv_uom_code                 := gt_tab_work_data(ln_i).uom_code;                    --納品単位
        gt_tab_sales_exp_lines(ln_m).standard_uom_code            := gt_tab_work_data(ln_i).uom_code;                    --基準単位
--******************************* 2009/04/28 1.9 N.Maeda MOD START **************************************************************
--        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               := gt_tab_work_data(ln_i).item_price;                  --納品単価
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := gt_tab_work_data(ln_i).item_price;                  --税抜基準単価
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price          := gt_tab_work_data(ln_i).item_price;                  --基準単価
        gt_tab_sales_exp_lines(ln_m).business_cost                := gt_tab_work_data(ln_i).business_cost;               --営業原価
        gt_tab_sales_exp_lines(ln_m).sale_amount                  := ROUND(gt_tab_work_data(ln_i).item_sales_amount *
                                                                           (gt_tab_work_data(ln_i).digestion_calc_rate / 100),0);
                                                                                                                         --売上金額
        gt_tab_sales_exp_lines(ln_m).pure_amount                  := gt_tab_sales_exp_lines(ln_m).sale_amount;           --本体金額
--******************************* 2009/05/26 1.11 T.Kitajima MOD START *******************************--
--        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               :=
--                            TRUNC( ( gt_tab_sales_exp_lines(ln_m).sale_amount / gt_tab_sales_exp_lines(ln_m).dlv_qty ) , 2 );  --納品単価
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded :=
--                            TRUNC( ( gt_tab_sales_exp_lines(ln_m).pure_amount / gt_tab_sales_exp_lines(ln_m).dlv_qty ) , 2 );  --税抜基準単価
--        gt_tab_sales_exp_lines(ln_m).standard_unit_price          :=
--                            TRUNC( ( gt_tab_sales_exp_lines(ln_m).sale_amount / gt_tab_sales_exp_lines(ln_m).standard_qty ) , 2 ); --基準単価
        gt_tab_sales_exp_lines(ln_m).dlv_unit_price               :=
                            ROUND( ( gt_tab_sales_exp_lines(ln_m).sale_amount / gt_tab_sales_exp_lines(ln_m).dlv_qty ) , 2 );  --納品単価
        gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded :=
                            ROUND( ( gt_tab_sales_exp_lines(ln_m).pure_amount / gt_tab_sales_exp_lines(ln_m).dlv_qty ) , 2 );  --税抜基準単価
        gt_tab_sales_exp_lines(ln_m).standard_unit_price          :=
                            ROUND( ( gt_tab_sales_exp_lines(ln_m).sale_amount / gt_tab_sales_exp_lines(ln_m).standard_qty ) , 2 ); --基準単価
--******************************* 2009/05/26 1.11 T.Kitajima MOD  END *******************************--
--******************************* 2009/04/28 1.9 N.Maeda MOD  END  **************************************************************
        --赤黒フラグ取得
/* 2010/01/18 Ver1.16 Mod Start */
        IF ( gt_tab_sales_exp_lines(ln_m).dlv_qty < 0 ) THEN
--        IF ( gt_tab_sales_exp_lines(ln_m).sale_amount < 0 ) THEN
/* 2010/01/18 Ver1.16 Mod Start */
          gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_0;                                --赤
        ELSE
          gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_1;                                --黒
        END IF;
        gt_tab_sales_exp_lines(ln_m).tax_amount                   := 0;                                                  --消費税金額
        gt_tab_sales_exp_lines(ln_m).cash_and_card                := 0;                                                  --現金/カード併用額
        gt_tab_sales_exp_lines(ln_m).ship_from_subinventory_code  := gt_tab_work_data(ln_i).ship_from_subinventory_code; --出荷元保管場所
--******************************* 2009/05/07 1.10 T.Kitajima MOD START ******************************--
--        gt_tab_sales_exp_lines(ln_m).delivery_base_code           := gt_tab_work_data(ln_i).delivery_base_code;          --納品拠点コード
        gt_tab_sales_exp_lines(ln_m).delivery_base_code           := lt_delivery_base_code;                              --納品拠点コード
--******************************* 2009/05/07 1.10 T.Kitajima MOD  END  ******************************--
        gt_tab_sales_exp_lines(ln_m).hot_cold_class               := NULL;                                               --Ｈ＆Ｃ
        gt_tab_sales_exp_lines(ln_m).column_no                    := NULL;                                               --コラムNo
        gt_tab_sales_exp_lines(ln_m).sold_out_class               := NULL;                                               --売切区分
        gt_tab_sales_exp_lines(ln_m).sold_out_time                := NULL;                                               --売切時間
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
        --棚卸テーブル更新用
        gt_tab_invent_seq(ln_m)                                   := gt_tab_work_data(ln_i).invent_seq;                  --棚卸SEQ
        --3.売上計算
        --本体金額合計
        ln_main_body_total     := ln_main_body_total     + gt_tab_sales_exp_lines(ln_m).pure_amount;
        --営業原価合計
        ln_business_cost_total := ln_business_cost_total + gt_tab_sales_exp_lines(ln_m).business_cost;
        --取得カウントが最大を超えたか
        IF ( gt_tab_work_data.COUNT < ln_i + 1 ) THEN
          ln_make_flg := 1;
        ELSE
          IF ( gt_tab_work_data(ln_i).shop_digestion_hdr_id != gt_tab_work_data(ln_i + 1).shop_digestion_hdr_id ) THEN
            ln_make_flg := 1;
          END IF;
        END IF;
        --ヘッダIDが違う場合はヘッダデータ設定、差分計算、差分明細を作成する。
        IF ( ln_make_flg = 1 ) THEN
          ln_make_flg := 0;
          --4.ヘッダデータ設定
          gt_tab_sales_exp_headers(ln_h).sales_exp_header_id         := ln_header_id;                                    --販売実績ヘッダID
          gt_tab_sales_exp_headers(ln_h).dlv_invoice_number          := lv_deli_seq;                                     --納品伝票番号
          gt_tab_sales_exp_headers(ln_h).order_invoice_number        := NULL;                                            --注文伝票番号
          gt_tab_sales_exp_headers(ln_h).order_number                := NULL;                                            --受注番号
          gt_tab_sales_exp_headers(ln_h).order_no_hht                := NULL;                                            --受注No（HHT)
          gt_tab_sales_exp_headers(ln_h).digestion_ln_number         := NULL;                                            --受注No（HHT）枝番
          gt_tab_sales_exp_headers(ln_h).order_connection_number     := NULL;                                            --受注関連番号
          gt_tab_sales_exp_headers(ln_h).dlv_invoice_class           := ct_deliver_slip_div;                             --納品伝票区分
          gt_tab_sales_exp_headers(ln_h).cancel_correct_class        := NULL;                                            --取消・訂正区分
          gt_tab_sales_exp_headers(ln_h).input_class                 := NULL;                                            --入力区分
          gt_tab_sales_exp_headers(ln_h).cust_gyotai_sho             := gt_tab_work_data(ln_i).cust_gyotai_sho;          --業態小分類
          gt_tab_sales_exp_headers(ln_h).delivery_date               := gt_tab_work_data(ln_i).digestion_due_date;       --納品日
          gt_tab_sales_exp_headers(ln_h).orig_delivery_date          := gt_tab_work_data(ln_i).digestion_due_date;       --オリジナル納品日
          gt_tab_sales_exp_headers(ln_h).inspect_date                := gt_tab_work_data(ln_i).digestion_due_date;       --検収日
          gt_tab_sales_exp_headers(ln_h).orig_inspect_date           := gt_tab_work_data(ln_i).digestion_due_date;       --オリジナル検収日
          gt_tab_sales_exp_headers(ln_h).ship_to_customer_code       := gt_tab_work_data(ln_i).customer_number;          --顧客【納品先】
          gt_tab_sales_exp_headers(ln_h).sale_amount_sum             := gt_tab_work_data(ln_i).ar_sales_amount;          --売上金額合計
          gt_tab_sales_exp_headers(ln_h).pure_amount_sum             := gt_tab_work_data(ln_i).ar_sales_amount;          --本体金額合計
          gt_tab_sales_exp_headers(ln_h).tax_amount_sum              := 0;                                               --消費税金額合計
          gt_tab_sales_exp_headers(ln_h).consumption_tax_class       := gt_tab_work_data(ln_i).tax_div;                  --消費税区分
          gt_tab_sales_exp_headers(ln_h).tax_code                    := gt_tab_work_data(ln_i).tax_code;                 --税金コード
          gt_tab_sales_exp_headers(ln_h).tax_rate                    := gt_tab_work_data(ln_i).tax_rate;                 --消費税率
          gt_tab_sales_exp_headers(ln_h).results_employee_code       := gt_tab_work_data(ln_i).performance_by_code;      --成績計上者コード
          gt_tab_sales_exp_headers(ln_h).sales_base_code             := gt_tab_work_data(ln_i).sales_base_code;          --売上拠点コード
          gt_tab_sales_exp_headers(ln_h).receiv_base_code            := gt_tab_work_data(ln_i).cash_receiv_base_code;    --入金拠点コード
          gt_tab_sales_exp_headers(ln_h).order_source_id             := NULL;                                            --受注ソースID
          gt_tab_sales_exp_headers(ln_h).card_sale_class             := ct_card_flag_cash;                               --カード売り区分
          gt_tab_sales_exp_headers(ln_h).invoice_class               := NULL;                                            --伝票区分
          gt_tab_sales_exp_headers(ln_h).invoice_classification_code := NULL;                                            --伝票分類コード
          gt_tab_sales_exp_headers(ln_h).change_out_time_100         := NULL;                                            --つり銭切れ時間１００円
          gt_tab_sales_exp_headers(ln_h).change_out_time_10          := NULL;                                            --つり銭切れ時間１０円
          gt_tab_sales_exp_headers(ln_h).ar_interface_flag           := ct_ar_interface_flag;                            --ARインタフェース済フラグ
          gt_tab_sales_exp_headers(ln_h).gl_interface_flag           := ct_gl_interface_flag;                            --GLインタフェース済フラグ
          gt_tab_sales_exp_headers(ln_h).dwh_interface_flag          := ct_dwh_interface_flag;                           --情報システムインタフェース済フラグ
          gt_tab_sales_exp_headers(ln_h).edi_interface_flag          := ct_edi_interface_flag;                           --EDI送信済みフラグ
          gt_tab_sales_exp_headers(ln_h).edi_send_date               := NULL;                                            --EDI送信日時
          gt_tab_sales_exp_headers(ln_h).hht_dlv_input_date          := NULL;                                            --HHT納品入力日時
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
          --店舗テーブル更新用
          gt_tab_shop_digestion_hdr_id(ln_h)                         := gt_tab_work_data(ln_i).shop_digestion_hdr_id;    --店舗別用消化計算ヘッダID
          --5.差分計算
          ln_difference_money := gt_tab_work_data(ln_i).ar_sales_amount - ln_main_body_total;
          IF ( ln_difference_money = 0 ) THEN
            NULL; --差異なし
          ELSE
            --明細シーケンス取得
            SELECT xxcos_sales_exp_lines_s01.nextval
            INTO   ln_line_id
            FROM   DUAL;
            --明細カウントUP
            ln_m := ln_m + 1;
            gt_tab_invent_seq(ln_m)                                   := cn_dmy;                                           --ダミーセット
            --
            gt_tab_sales_exp_lines(ln_m).sales_exp_line_id            := ln_line_id;                                       --販売実績明細ID
            gt_tab_sales_exp_lines(ln_m).sales_exp_header_id          := ln_header_id;                                     --販売実績ヘッダID
            gt_tab_sales_exp_lines(ln_m).dlv_invoice_number           := lv_deli_seq;                                      --納品伝票番号
--******************************* 2009/03/30 1.7 T.kitajima MOD  END  ********************************************
--            gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := gt_tab_work_data(ln_i).shop_digestion_ln_id + 1;
            gt_tab_sales_exp_lines(ln_m).dlv_invoice_line_number      := ln_line_index;                                    --納品明細番号
--******************************* 2009/03/30 1.7 T.kitajima MOD  END  ********************************************
            gt_tab_sales_exp_lines(ln_m).order_invoice_line_number    := NULL;                                             --注文明細番号
            gt_tab_sales_exp_lines(ln_m).sales_class                  := gv_sales_class_vd;                                --売上区分
            gt_tab_sales_exp_lines(ln_m).delivery_pattern_class       := gv_dvl_ptn_class;                                 --納品形態区分
            --赤黒フラグ取得
            IF ( ln_difference_money < 0 ) THEN
              gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_0;                              --赤
            ELSE
              gt_tab_sales_exp_lines(ln_m).red_black_flag             := ct_red_black_flag_1;                              --黒
            END IF;
            gt_tab_sales_exp_lines(ln_m).item_code                    := gv_item_code;                                     --品目コード
--******************************* 2009/04/28 1.9 N.Maeda MOD START **************************************************************
--            gt_tab_sales_exp_lines(ln_m).dlv_qty                      := 0;                                                --納品数量
--            gt_tab_sales_exp_lines(ln_m).standard_qty                 := 0;                                                --基準数量
            gt_tab_sales_exp_lines(ln_m).dlv_qty                      := ln_difference_money;                              --納品数量
            gt_tab_sales_exp_lines(ln_m).standard_qty                 := ln_difference_money;                              --基準数量
            gt_tab_sales_exp_lines(ln_m).dlv_uom_code                 := gv_item_unit;                                     --納品単位
            gt_tab_sales_exp_lines(ln_m).standard_uom_code            := gv_item_unit;                                     --基準単位
--            gt_tab_sales_exp_lines(ln_m).dlv_unit_price               := ln_difference_money;                              --納品単価
--            gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := ln_difference_money;                              --税抜基準単価
            gt_tab_sales_exp_lines(ln_m).dlv_unit_price               := cn_quantity_num;                                  --納品単価
            gt_tab_sales_exp_lines(ln_m).standard_unit_price_excluded := cn_quantity_num;                                  --税抜基準単価
--            gt_tab_sales_exp_lines(ln_m).standard_unit_price          := ln_difference_money;                              --基準単価
--            gt_tab_sales_exp_lines(ln_m).business_cost                := ln_difference_money ;                             --営業原価
            gt_tab_sales_exp_lines(ln_m).standard_unit_price          := cn_quantity_num;                                  --基準単価
            gt_tab_sales_exp_lines(ln_m).business_cost                := cn_differ_business_cost;                          --営業原価
            gt_tab_sales_exp_lines(ln_m).sale_amount                  := ln_difference_money;                              --売上金額
            gt_tab_sales_exp_lines(ln_m).pure_amount                  := ln_difference_money;                              --本体金額
--******************************* 2009/04/28 1.9 N.Maeda MOD  END  **************************************************************
            gt_tab_sales_exp_lines(ln_m).tax_amount                   := 0;                                                --消費税金額
            gt_tab_sales_exp_lines(ln_m).cash_and_card                := 0;                                                --現金/カード併用額
            gt_tab_sales_exp_lines(ln_m).ship_from_subinventory_code  := NULL;                                             --出荷元保管場所
            gt_tab_sales_exp_lines(ln_m).delivery_base_code           := gt_tab_sales_exp_lines(ln_m-1).delivery_base_code;--納品拠点コード
            gt_tab_sales_exp_lines(ln_m).hot_cold_class               := NULL;                                             --Ｈ＆Ｃ
            gt_tab_sales_exp_lines(ln_m).column_no                    := NULL;                                             --コラムNo
            gt_tab_sales_exp_lines(ln_m).sold_out_class               := NULL;                                             --売切区分
            gt_tab_sales_exp_lines(ln_m).sold_out_time                := NULL;                                             --売切時間
            gt_tab_sales_exp_lines(ln_m).to_calculate_fees_flag       := ct_to_calculate_fees_flag;                        --手数料計算インタフェース済フラグ
            gt_tab_sales_exp_lines(ln_m).unit_price_mst_flag          := ct_unit_price_mst_flag;                           --単価マスタ作成済フラグ
            gt_tab_sales_exp_lines(ln_m).inv_interface_flag           := ct_inv_interface_flag;                            --INVインタフェース済フラグ
            gt_tab_sales_exp_lines(ln_m).created_by                   := cn_created_by;                                    --作成者
            gt_tab_sales_exp_lines(ln_m).creation_date                := cd_creation_date;                                 --作成日
            gt_tab_sales_exp_lines(ln_m).last_updated_by              := cn_last_updated_by;                               --最終更新者
            gt_tab_sales_exp_lines(ln_m).last_update_date             := cd_last_update_date;                              --最終更新日
            gt_tab_sales_exp_lines(ln_m).last_update_login            := cn_last_update_login;                             --最終更新ﾛｸﾞｲﾝ
            gt_tab_sales_exp_lines(ln_m).request_id                   := cn_request_id;                                    --要求ID
            gt_tab_sales_exp_lines(ln_m).program_application_id       := cn_program_application_id;                        --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
            gt_tab_sales_exp_lines(ln_m).program_id                   := cn_program_id;                                    --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
            gt_tab_sales_exp_lines(ln_m).program_update_date          := cd_program_update_date;                           --ﾌﾟﾛｸﾞﾗﾑ更新日
          END IF;
          --合計金額初期化
          ln_main_body_total     := 0;
          ln_business_cost_total := 0;
          ln_difference_money    := 0;
          --ヘッダカウントUP
          ln_h := ln_h + 1;
          --対象件数
          gn_target_cnt := gn_target_cnt +1;
--******************************* 2009/03/30 1.7 T.kitajima ADD START ********************************************
          --納品明細番号初期化
          ln_line_index := 1; 
--******************************* 2009/03/30 1.7 T.kitajima ADD  END  ********************************************
          --ヘッダシーケンス取得
          SELECT xxcos_sales_exp_headers_s01.nextval
          INTO   ln_header_id
          FROM   DUAL;
          --納品伝票番号シーケンス取得
--******************************* 2009/06/11 1.13 T.Kitajima MOD START ******************************--
--        lv_deli_seq := xxcos_def_pkg.set_order_number(NULL,NULL);
          SELECT cv_snq_i || TO_CHAR( ( lpad( XXCOS_CUST_PO_NUMBER_S01.nextval, 11, 0) ) )
            INTO lv_deli_seq
            FROM dual;
--******************************* 2009/06/11 1.13 T.Kitajima MOD  END  ******************************--
          --次のINDEX値を保管
          ln_index := ln_m + 1;
        END IF;
      ELSE
        --取得カウントが最大を超えたか
        IF ( gt_tab_work_data.COUNT < ln_i + 1 ) THEN
          ln_make_flg := 1;
        ELSE
          IF ( gt_tab_work_data(ln_i).shop_digestion_hdr_id != gt_tab_work_data(ln_i + 1).shop_digestion_hdr_id ) THEN
            ln_make_flg := 1;
          END IF;
        END IF;
        --ヘッダIDが違う場合はヘッダデータ設定、差分計算、差分明細を作成する。
        IF ( ln_make_flg = 1 ) THEN
          ln_make_flg := 0;
          --ノーマルを設定し通常処理へ戻る
          lv_err_work := cv_status_normal;
          --テーブル変数のエラーINDEX分を削除
          gt_tab_sales_exp_lines.DELETE(ln_index,ln_m);
          gt_tab_invent_seq.DELETE(ln_index,ln_m);
          --スキップ件数
--****************************** 2009/05/07 1.10 T.Kitajima MOD START ******************************--
--          gn_warn_cnt := gn_warn_cnt + ( ln_m - ln_index );
          gn_warn_cnt := gn_warn_cnt + 1;
--****************************** 2009/05/07 1.10 T.Kitajima MOD  END ******************************--
          --対象件数
          gn_target_cnt := gn_target_cnt +1;
          --次のINDEX値を保管
          ln_index := ln_m + 1;
        END IF;
      END IF;
      --明細カウントUP
      ln_m := ln_m + 1;
    END LOOP;
--
    --テーブルコレクションの入れ替え。
--
    --初期化
    ln_index := 1;
--
    --明細分ループする
    FOR ln_i IN 1..ln_m LOOP
      IF ( gt_tab_sales_exp_lines.EXISTS(ln_i) ) THEN
        gt_tab_sales_exp_lines_ins(ln_index) := gt_tab_sales_exp_lines(ln_i);
        ln_index := ln_index + 1;
      END IF;
    END LOOP;
    --初期化
    ln_index := 1;
    --更新対象分ループする
    FOR ln_i IN 1..ln_m LOOP
      IF ( gt_tab_invent_seq.EXISTS(ln_i) ) THEN
        IF ( gt_tab_invent_seq(ln_i) != cn_dmy ) THEN
          gt_tab_invent_seq_up(ln_index)       := gt_tab_invent_seq(ln_i);
          ln_index := ln_index + 1;
        END IF;
      END IF;
    END LOOP;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    IF (gn_warn_cnt > 0 ) THEN
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
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_inser_lines_err
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
--
    BEGIN
      FORALL ln_i in 1..gt_tab_sales_exp_headers.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_headers VALUES gt_tab_sales_exp_headers(ln_i);
      --対象件数を正常件数に
--****************************** 2009/05/07 1.10 T.Kitajima MOD START ******************************--
--      gn_normal_cnt := SQL%ROWCOUNT;
      gn_normal_cnt := gt_tab_sales_exp_headers.COUNT;
--****************************** 2009/05/07 1.10 T.Kitajima MOD  END  ******************************--

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
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_inser_headers_err
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
  END set_headers;
--
  /**********************************************************************************
   * Procedure Name   : update_digestion
   * Description      : 消化処理設定(A-7)
   ***********************************************************************************/
  PROCEDURE update_digestion(
    iv_base_code       IN         VARCHAR2,     -- 拠点コード
    iv_customer_number IN         VARCHAR2,     -- 顧客コード
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
    iv_exec_div        IN         VARCHAR2,     -- 定期随時区分
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
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
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
    CURSOR lock_cur( it_inventory_seq xxcoi_inv_control.inventory_seq%TYPE )
    IS
      SELECT inventory_seq
        FROM xxcoi_inv_control
       WHERE inventory_seq     = it_inventory_seq
       FOR UPDATE NOWAIT
    ;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
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
      FORALL ln_i in 1..gt_tab_shop_digestion_hdr_id.COUNT SAVE EXCEPTIONS
        UPDATE xxcos_shop_digestion_hdrs
           SET sales_result_creation_flag = ct_make_flag_yes,
               sales_result_creation_date = gd_business_date,
               last_updated_by            = cn_last_updated_by,
               last_update_date           = cd_last_update_date,
               last_update_login          = cn_last_update_login,
               request_id                 = cn_request_id,
               program_application_id     = cn_program_application_id,
               program_id                 = cn_program_id,
               program_update_date        = cd_program_update_date
         WHERE shop_digestion_hdr_id      = gt_tab_shop_digestion_hdr_id(ln_i);
    EXCEPTION
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        RAISE global_up_headers_expt;
    END;
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
    -- 定期随時区分が定期の場合のみ未計算区分が1(INV/ARともにデータが存在しないデータを更新する。)
    IF (iv_exec_div = cv_exec_div_1) THEN
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
      -- ===============================
      -- 2.販売実績作成分更新処理
      -- ===============================
      BEGIN
/* 2009/08/17 Ver1.14 Mod Start */
--      UPDATE xxcos_shop_digestion_hdrs
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
--         AND sales_result_creation_flag = ct_make_flag_no
--         AND customer_number IN (
        UPDATE xxcos_shop_digestion_hdrs xsdh
           SET xsdh.sales_result_creation_flag = ct_make_flag_yes,
               xsdh.sales_result_creation_date = gd_business_date,
               xsdh.last_updated_by            = cn_last_updated_by,
               xsdh.last_update_date           = cd_last_update_date,
               xsdh.last_update_login          = cn_last_update_login,
               xsdh.request_id                 = cn_request_id,
               xsdh.program_application_id     = cn_program_application_id,
               xsdh.program_id                 = cn_program_id,
               xsdh.program_update_date        = cd_program_update_date
         WHERE xsdh.uncalculate_class          = ct_un_calc_flag_1
           AND xsdh.sales_result_creation_flag = ct_make_flag_no
           AND EXISTS (
/* 2009/08/17 Ver1.14 Mod End   */
                 SELECT hca.account_number  account_number         --顧客コード
                 FROM   hz_cust_accounts    hca,                   --顧客マスタ
                        xxcmm_cust_accounts xca                    --顧客アドオン
                 WHERE  hca.cust_account_id     = xca.customer_id  --顧客マスタ.顧客ID   = 顧客アドオン.顧客ID
/* 2009/08/17 Ver1.14 Add Start */
                 AND    xca.customer_code       = xsdh.customer_number --顧客アドオン.顧客コード = 消化VD用消化計算ヘッダ.顧客コード
/* 2009/08/17 Ver1.14 Add End   */
                 AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                              FROM   fnd_application               fa,
--                                     fnd_lookup_types              flt,
--                                     fnd_lookup_values             flv
--                              WHERE  fa.application_id                               =    flt.application_id
--                              AND    flt.lookup_type                                 =    flv.lookup_type
--                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                              AND    flv.lookup_type                                 =    ct_qct_cust_type
--                              AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
--                              AND    flv.start_date_active                          <=    gd_last_month_date
--                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                              AND    flv.language                                    =    USERENV( 'LANG' )
--                              AND    flv.meaning                                     =    hca.customer_class_code
                                FROM   fnd_lookup_values  flv
                                WHERE  flv.lookup_type      = ct_qct_cust_type
                                AND    flv.lookup_code      LIKE ct_qcc_cust_code_2
                                AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                            AND     NVL( flv.end_date_active, gd_last_month_date )
                                AND    flv.enabled_flag     = ct_enabled_flag_yes
                                AND    flv.language         = ct_lang
                                AND    flv.meaning          = hca.customer_class_code
/* 2009/08/17 Ver1.14 Mod End   */
                               ) --顧客マスタ.顧客区分 = 10(顧客)
                 AND    EXISTS (SELECT hcae.account_number --拠点コード
                                  FROM   hz_cust_accounts    hcae,
/* 2009/08/17 Ver1.14 Mod Start */
--                                       xxcmm_cust_accounts xcae
                                         xxcmm_cust_accounts xcae,
                                         fnd_lookup_values   flv
/* 2009/08/17 Ver1.14 Mod End   */
                                  WHERE  hcae.cust_account_id = xcae.customer_id--顧客マスタ.顧客ID =顧客アドオン.顧客ID
/* 2009/08/17 Ver1.14 Mod Start */
--                                AND    EXISTS (SELECT flv.meaning
--                                               FROM   fnd_application               fa,
--                                                      fnd_lookup_types              flt,
--                                                      fnd_lookup_values             flv
--                                               WHERE  fa.application_id                               =    flt.application_id
--                                               AND    flt.lookup_type                                 =    flv.lookup_type
--                                               AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                                               AND    flv.lookup_type                                 =    ct_qct_cust_type
--                                               AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_1
--                                               AND    flv.start_date_active                          <=    gd_last_month_date
--                                               AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                                               AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                                               AND    flv.language                                    =    USERENV( 'LANG' )
--                                               AND    flv.meaning                                     =    hcae.customer_class_code
--                                              ) --顧客マスタ.顧客区分 = 1(拠点)
--                                AND    xcae.management_base_code = NVL( iv_base_code,xcae.management_base_code )
--                                                --顧客顧客アドオン.管理元拠点コード = INパラ拠点コード
                                  AND    flv.lookup_type      = ct_qct_cust_type
                                  AND    flv.lookup_code      LIKE ct_qcc_cust_code_1
                                  AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                              AND     NVL( flv.end_date_active, gd_last_month_date )
                                  AND    flv.enabled_flag     = ct_enabled_flag_yes
                                  AND    flv.language         = ct_lang
                                  AND    flv.meaning          = hcae.customer_class_code
                                  AND    (
                                           ( iv_base_code IS NULL )
                                           OR
                                           ( iv_base_code IS NOT NULL AND xcae.management_base_code = iv_base_code )
                                         ) --顧客顧客アドオン.管理元拠点コード = INパラ拠点コード
/* 2009/08/17 Ver1.14 Mod End   */
                                  AND    hcae.account_number = NVL( xca.past_sale_base_code,xca.sale_base_code )
                                 ) --管理拠点に所属する拠点コード=顧客アドオン.前月拠点or売上拠点
/* 2009/08/17 Ver1.14 Mod Start */
--               AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード=INパラ(顧客コード)
                 AND    (
                          ( iv_customer_number IS NULL )
                          OR
                          ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                        ) --顧客コード=INパラ(顧客コード)
/* 2009/08/17 Ver1.14 Mod End   */
                 AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                              FROM   fnd_application               fa,
--                                     fnd_lookup_types              flt,
--                                     fnd_lookup_values             flv
--                              WHERE  fa.application_id                               =    flt.application_id
--                              AND    flt.lookup_type                                 =    flv.lookup_type
--                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                              AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                              AND    flv.lookup_code                                 LIKE ct_qcc_it_code
--                              AND    flv.start_date_active                          <=    gd_last_month_date
--                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                              AND    flv.language                                    =    USERENV( 'LANG' )
--                              AND    flv.meaning = xca.business_low_type
                                FROM   fnd_lookup_values  flv
                                WHERE  flv.lookup_type      = ct_qct_gyo_type
                                AND    flv.lookup_code      LIKE ct_qcc_it_code
                                AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                            AND     NVL( flv.end_date_active, gd_last_month_date )
                                AND    flv.enabled_flag     = ct_enabled_flag_yes
                                AND    flv.language         = ct_lang
                                AND    flv.meaning          = xca.business_low_type
/* 2009/08/17 Ver1.14 Mod End   */
                               )  --業態小分類=インショップ,当社直営店
                 UNION
                 SELECT hca.account_number  account_number         --顧客コード
                 FROM   hz_cust_accounts    hca,                   --顧客マスタ
                        xxcmm_cust_accounts xca                    --顧客アドオン
                 WHERE  hca.cust_account_id     = xca.customer_id --顧客マスタ.顧客ID   = 顧客アドオン.顧客ID
/* 2009/08/17 Ver1.14 Add Start */
                 AND    xca.customer_code       = xsdh.customer_number --顧客マスタ.顧客コード = 消化VD用消化計算ヘッダ.顧客コード
/* 2009/08/17 Ver1.14 Add End   */
                 AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                              FROM   fnd_application               fa,
--                                     fnd_lookup_types              flt,
--                                     fnd_lookup_values             flv
--                              WHERE  fa.application_id                               =    flt.application_id
--                              AND    flt.lookup_type                                 =    flv.lookup_type
--                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                              AND    flv.lookup_type                                 =    ct_qct_cust_type
--                              AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
--                              AND    flv.start_date_active                          <=    gd_last_month_date
--                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                              AND    flv.language                                    =    USERENV( 'LANG' )
--                              AND    flv.meaning                                     =    hca.customer_class_code
                                FROM   fnd_lookup_values  flv
                                WHERE  flv.lookup_type      = ct_qct_cust_type
                                AND    flv.lookup_code      LIKE ct_qcc_cust_code_2
                                AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                            AND     NVL( flv.end_date_active, gd_last_month_date )
                                AND    flv.enabled_flag     = ct_enabled_flag_yes
                                AND    flv.language         = ct_lang
                                AND    flv.meaning          = hca.customer_class_code
/* 2009/08/17 Ver1.14 Mod End   */
                               ) --顧客マスタ.顧客区分 = 10(顧客)
                 AND    (
                         xca.past_sale_base_code = NVL( iv_base_code,xca.past_sale_base_code )
                         OR
                         xca.sale_base_code = NVL( iv_base_code,xca.sale_base_code )
                        )--顧客アドオン.前月拠点or売上拠点 = INパラ拠点コード
/* 2009/08/17 Ver1.14 Mod Start */
--               AND    hca.account_number = NVL( iv_customer_number,hca.account_number ) --顧客コード=INパラ(顧客コード)
                 AND    (
                          ( iv_customer_number IS NULL )
                          OR
                          ( iv_customer_number IS NOT NULL AND hca.account_number = iv_customer_number )
                        ) --顧客コード=INパラ(顧客コード)
/* 2009/08/17 Ver1.14 Mod End   */
                 AND    EXISTS (SELECT flv.meaning
/* 2009/08/17 Ver1.14 Mod Start */
--                              FROM   fnd_application               fa,
--                                     fnd_lookup_types              flt,
--                                     fnd_lookup_values             flv
--                              WHERE  fa.application_id                               =    flt.application_id
--                              AND    flt.lookup_type                                 =    flv.lookup_type
--                              AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                              AND    flv.lookup_type                                 =    ct_qct_gyo_type
--                              AND    flv.lookup_code                                 LIKE ct_qcc_it_code
--                              AND    flv.start_date_active                          <=    gd_last_month_date
--                              AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
--                              AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--                              AND    flv.language                                    =    USERENV( 'LANG' )
--                              AND    flv.meaning = xca.business_low_type
                                FROM   fnd_lookup_values  flv
                                WHERE  flv.lookup_type      = ct_qct_gyo_type
                                AND    flv.lookup_code      LIKE ct_qcc_it_code
                                AND    gd_last_month_date   BETWEEN NVL( flv.start_date_active, gd_last_month_date )
                                                            AND     NVL( flv.end_date_active, gd_last_month_date )
                                AND    flv.enabled_flag     = ct_enabled_flag_yes
                                AND    flv.language         = ct_lang
                                AND    flv.meaning          = xca.business_low_type
/* 2009/08/17 Ver1.14 Mod End   */
                               )  --業態小分類=インショップ,当社直営店
               )
         ;
      EXCEPTION
        -- エラー処理（データ追加エラー）
        WHEN OTHERS THEN
          RAISE global_up_headers_expt;
      END;
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
    END IF;
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
    -- ===============================
    -- 3.棚卸管理テーブル更新処理
    -- ===============================
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
    BEGIN
      FOR ln_i in 1..gt_tab_invent_seq_up.COUNT LOOP
          OPEN lock_cur( gt_tab_invent_seq_up(ln_i) );
          CLOSE lock_cur;
      END LOOP;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- カーソルCLOSE：納品ヘッダワークテーブルデータ取得
        IF ( lock_cur%ISOPEN ) THEN
          CLOSE lock_cur;
        END IF;
        RAISE global_data_lock_expt;
    END;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
   BEGIN
      FORALL ln_i in 1..gt_tab_invent_seq_up.COUNT SAVE EXCEPTIONS
        UPDATE xxcoi_inv_control
           SET inventory_status           = gv_inv_status,
               last_updated_by            = cn_last_updated_by,
               last_update_date           = cd_last_update_date,
               last_update_login          = cn_last_update_login,
               request_id                 = cn_request_id,
               program_application_id     = cn_program_application_id,
               program_id                 = cn_program_id,
               program_update_date        = cd_program_update_date
         WHERE inventory_seq              = gt_tab_invent_seq_up(ln_i);
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
    --店舗別用消化計算ヘッダ更新例外
    WHEN global_up_headers_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_update_headers_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --棚卸管理テーブル更新例外
    WHEN global_up_inv_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        =>  ct_xxcos_appl_short_name
                     ,iv_name               =>  cv_msg_update_inv_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
--
    -- *** ロック エラー ***
    WHEN global_data_lock_expt     THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_inv_lock_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
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
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
--
  /**********************************************************************************
   * Procedure Name   : ar_chk
   * Description      : AR金額差異チェック(A-08)
   ***********************************************************************************/
  PROCEDURE ar_chk(
    it_rec_work_data IN g_rec_work_data, --顧客情報
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ar_chk'; -- プログラム名
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
    ln_extended_amount   ra_customer_trx_lines_all.extended_amount%TYPE; --本体金額(AR)
    ln_ar_sales_amount   xxcos_shop_digestion_hdrs.ar_sales_amount%TYPE; --店舗別売上金額
    
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
    -- 初期化
    BEGIN
      -- AR金額取得
      SELECT SUM(rctla.extended_amount)          extended_amount      --本体金額
        INTO ln_extended_amount
        FROM ra_customer_trx_all                 rcta,                --AR取引情報テーブル
             ra_customer_trx_lines_all           rctla,               --AR取引明細テーブル
             ra_cust_trx_line_gl_dist_all        rctlgda,             --AR取引明細会計配分テーブル
             ra_cust_trx_types_all               rctta                --AR取引タイプマスタ
       WHERE rcta.ship_to_customer_id          = it_rec_work_data.cust_account_id
         AND rcta.customer_trx_id              = rctla.customer_trx_id
         AND rctla.customer_trx_id             = rctlgda.customer_trx_id
         AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
         AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
         AND rctla.line_type                   = ct_line_type_line
         AND rcta.complete_flag                = ct_complete_flag_yes
         AND rctlgda.gl_date                  >= gd_begi_month_date
         AND rctlgda.gl_date                  <= gd_last_month_date
         AND rcta.org_id                       = gn_org_id
         AND EXISTS(SELECT cv_exists_flag_yes exists_flag
                      FROM fnd_lookup_values flv
                     WHERE flv.lookup_type   =    ct_qct_customer_trx_type
                       AND flv.lookup_code   LIKE ct_qcc_customer_trx_type
                       AND flv.meaning       =    rctta.name
                       AND rctlgda.gl_date   >=    flv.start_date_active
                       AND rctlgda.gl_date   <=    NVL( flv.end_date_active, gd_max_date )
                       AND flv.enabled_flag  =    ct_enabled_flag_yes
                       AND flv.language      =    ct_lang
             );
      -- 取得に失敗した場合
      IF (ln_extended_amount IS NULL ) THEN
        RAISE global_ar_chk_err_expt;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_ar_chk_err_expt;
    END;
    -- 店舗別用消化計算ヘッダテーブルから店舗別売上金額を取得
    BEGIN
      SELECT xsdh.ar_sales_amount extended_amount
        INTO ln_ar_sales_amount
        FROM xxcos_shop_digestion_hdrs xsdh--店舗別用消化計算ヘッダテーブル
       WHERE xsdh.cust_account_id = it_rec_work_data.cust_account_id
         AND xsdh.sales_base_code = it_rec_work_data.past_sale_base_code
         AND xsdh.digestion_due_date = gd_last_month_date;
      -- 取得に失敗した場合
      IF (ln_ar_sales_amount IS NULL ) THEN
        RAISE global_ar_chk_err_expt;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_ar_chk_err_expt;
    END;
    -- ARから取得した金額と店舗別用消化計算ヘッダテーブルから取得した金額が一致しないもしくは
    -- ARから取得した金額が0の場合ARチェックエラーとする。
    IF ((ln_extended_amount <> ln_ar_sales_amount) OR
        (ln_ar_sales_amount = 0) ) THEN
      RAISE global_ar_chk_err_expt;
    END IF;
--
  EXCEPTION
    -- *** ARチェックエラー ***
    WHEN global_ar_chk_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_ar_chk_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => it_rec_work_data.customer_number
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
  END ar_chk;
--
  /**********************************************************************************
   * Procedure Name   : inv_chk
   * Description      : INV品目数差異チェック処理(A-9)
   ***********************************************************************************/
  PROCEDURE inv_chk(
    it_rec_work_data IN g_rec_work_data, --顧客情報
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inv_chk'; -- プログラム名
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
    ln_amount NUMBER; -- 対象データ取得
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
    -- 初期化
    BEGIN
      SELECT A.inv_wear
        INTO ln_amount
        FROM (
               SELECT sirm.inventory_item_id      inventory_item_id,           --品目ID
                      sirm.subinventory_code      subinventory_code ,           --保管場所
                      SUM(sirm.inv_wear)          inv_wear                     --販売数(棚卸減耗)
                 FROM xxcoi_inv_reception_monthly sirm,
                      mtl_secondary_inventories   msi
                  --INV月次在庫受払表.保管場所      = 保管場所マスタ.保管場所
                WHERE sirm.subinventory_code = msi.secondary_inventory_name
                  --保管場所マスタ.[DFF2]棚卸区分   = '2'「消化」
                  AND msi.attribute5         = ct_secondary_class_2
                  --保管場所マスタ.[DFF4]顧客コード = 顧客コード
                  AND msi.attribute4         = it_rec_work_data.customer_number
                  --保管場所マスタ.[DFF7]拠点コード = 納品拠点コード
                  --保管場所マスタ.[DFF7]拠点コード = 顧客アドオンマスタ.前月売上拠点コード or 売上拠点コード
                  AND msi.attribute7         =it_rec_work_data.past_sale_base_code
                  --INV月次在庫受払表.拠点コード    = 顧客アドオンマスタ.前月売上拠点コード or 売上拠点コード
                  AND sirm.base_code         =it_rec_work_data.past_sale_base_code
                  --INV月次在庫受払表.組織ID        = 在庫組織ID
                  AND sirm.organization_id   = gt_organization_id
                  --INV月次在庫受払表.年月          = 前月年月
                  AND sirm.practice_month    = gv_month_date
                  --INV月次在庫受払表.棚卸区分      = '2'「月末」
                  AND sirm.inventory_kbn     = ct_inventory_class_2
                  GROUP BY sirm.inventory_item_id,           --品目ID
                           sirm.subinventory_code            --保管場所
             ) A
       WHERE NOT EXISTS (
                          SELECT B.inventory_item_id,        --品目ID
                                 B.subinventory_code,
                                 B.inv_wear
                            FROM (
                              SELECT xsdl.inventory_item_id inventory_item_id --品目ID
                                    ,xsdl.ship_from_subinventory_code subinventory_code -- 保管場所
                                    ,SUM(xsdl.sales_quantity) inv_wear --販売数(棚卸減耗)
                                FROM xxcos_shop_digestion_lns xsdl -- 店舗別用消化計算明細テーブル
                                    ,xxcos_shop_digestion_hdrs xsdh
                               WHERE xsdl.delivery_base_code = it_rec_work_data.past_sale_base_code
                                 AND xsdl.customer_number = it_rec_work_data.customer_number --顧客コード
                                 AND xsdl.digestion_due_date = gd_last_month_date
                                 AND xsdh.shop_digestion_hdr_id = xsdl.shop_digestion_hdr_id --店舗別用消化計算ヘッダID
                                 AND xsdh.uncalculate_class = ct_un_calc_flag_0 --未計算区分
                               GROUP BY xsdl.inventory_item_id
                                       ,xsdl.ship_from_subinventory_code
                                 ) B
                           WHERE B.inventory_item_id = A.inventory_item_id
                             AND B.subinventory_code = A.subinventory_code
                             AND B.inv_wear          = A.inv_wear
                        )
       AND ROWNUM = 1;
       IF (ln_amount IS NOT NULL) THEN
         RAISE global_inv_chk_err_expt;
       END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    BEGIN
      SELECT A.inv_wear
        INTO ln_amount
        FROM (
               SELECT xsdl.inventory_item_id inventory_item_id --品目ID
                     ,xsdl.ship_from_subinventory_code subinventory_code -- 保管場所
                     ,SUM(xsdl.sales_quantity) inv_wear --販売数(棚卸減耗)
                 FROM xxcos_shop_digestion_lns xsdl -- 店舗別用消化計算明細テーブル
                     ,xxcos_shop_digestion_hdrs xsdh
                WHERE xsdl.delivery_base_code = it_rec_work_data.past_sale_base_code
                  AND xsdl.customer_number = it_rec_work_data.customer_number --顧客コード
                  AND xsdl.digestion_due_date = gd_last_month_date
                  AND xsdh.shop_digestion_hdr_id = xsdl.shop_digestion_hdr_id --店舗別用消化計算ヘッダID
                  AND xsdh.uncalculate_class = ct_un_calc_flag_0 --未計算区分
                GROUP BY xsdl.inventory_item_id
                        ,xsdl.ship_from_subinventory_code
             ) A
       WHERE NOT EXISTS (
               SELECT B.inventory_item_id,        --品目ID
                      B.subinventory_code,
                      B.inv_wear
                 FROM (
                         SELECT sirm.inventory_item_id      inventory_item_id,           --品目ID
                                sirm.subinventory_code      subinventory_code ,           --保管場所
                                SUM(sirm.inv_wear)          inv_wear                     --販売数(棚卸減耗)
                           FROM xxcoi_inv_reception_monthly sirm,
                                mtl_secondary_inventories   msi
                            --INV月次在庫受払表.保管場所      = 保管場所マスタ.保管場所
                          WHERE sirm.subinventory_code = msi.secondary_inventory_name
                            --保管場所マスタ.[DFF2]棚卸区分   = '2'「消化」
                            AND msi.attribute5         = ct_secondary_class_2
                            --保管場所マスタ.[DFF4]顧客コード = 顧客コード
                            AND msi.attribute4         = it_rec_work_data.customer_number
                            --保管場所マスタ.[DFF7]拠点コード = 納品拠点コード
                            --保管場所マスタ.[DFF7]拠点コード = 顧客アドオンマスタ.前月売上拠点コード or 売上拠点コード
                            AND msi.attribute7         = it_rec_work_data.past_sale_base_code
                            --INV月次在庫受払表.拠点コード    = 顧客アドオンマスタ.前月売上拠点コード or 売上拠点コード
                            AND sirm.base_code         = it_rec_work_data.past_sale_base_code
                            --INV月次在庫受払表.組織ID        = 在庫組織ID
                            AND sirm.organization_id   = gt_organization_id
                            --INV月次在庫受払表.年月          = 前月年月
                            AND sirm.practice_month    = gv_month_date
                            --INV月次在庫受払表.棚卸区分      = '2'「月末」
                            AND sirm.inventory_kbn     = ct_inventory_class_2
                            GROUP BY sirm.inventory_item_id,           --品目ID
                                     sirm.subinventory_code            --保管場所
                      ) B
                WHERE B.inventory_item_id = A.inventory_item_id
                  AND B.subinventory_code = A.subinventory_code
                  AND B.inv_wear          = A.inv_wear
                        )
       AND ROWNUM = 1;
       IF (ln_amount IS NOT NULL) THEN
         RAISE global_inv_chk_err_expt;
       END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
    -- *** INVチェックエラー ***
    WHEN global_inv_chk_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_inv_chk_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => it_rec_work_data.customer_number
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
  END inv_chk;
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END **************************************************************
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
    lv_err_emp  VARCHAR2(1);     -- リターン・コード一時保管
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
    lv_customer_number xxcos_shop_digestion_hdrs.customer_number%TYPE;  -- 顧客コード
    ln_cust_account_id xxcos_shop_digestion_hdrs.cust_account_id%TYPE;  -- 顧客ID
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
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
       iv_exec_div        -- 1.定期随時区分
      ,iv_base_code       -- 2.拠点コード
      ,iv_customer_number -- 3.顧客コード
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-1.パラメータチェック
    -- ===============================
    pram_chk(
       iv_exec_div        -- 1.定期随時区分
      ,iv_base_code       -- 2.拠点コード
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-2.共通データ取得
    -- ===============================
    get_common_data(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-3.店舗別用消化計算データ取得
    -- ===============================
    get_object_data(
       iv_base_code       -- 拠点コード
      ,iv_customer_number -- 顧客コード
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
        gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      END IF;
      RAISE global_common_expt;
    END IF;
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
    --==============================================================
    --随時実行の場合、店舗別用消化計算が最新かどうかチェックを行います。
    --==============================================================
    IF ( iv_exec_div = cv_exec_div_0 ) THEN
      <<gt_tab_work_data_loop>>
      FOR ln_i IN 1..gt_tab_work_data.COUNT LOOP
        --==============================================================
        --ループの初回か顧客が変更された場合にチェック処理を行います。
        --==============================================================
        IF (lv_customer_number IS NULL OR
            lv_customer_number <> gt_tab_work_data(ln_i).customer_number) THEN
          -- ===============================
          -- A-9.ARデータチェック処理
          -- ===============================
          ar_chk(
             gt_tab_work_data(ln_i)                -- 店舗別用消化計算データ
            ,lv_errbuf                             -- エラー・メッセージ           --# 固定 #
            ,lv_retcode                            -- リターン・コード             --# 固定 #
            ,lv_errmsg                             -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_common_expt;
          END IF;
          -- ===============================
          -- A-10.INVデータチェック処理
          -- ===============================
          inv_chk(
             gt_tab_work_data(ln_i)                -- 店舗別用消化計算データ
            ,lv_errbuf                             -- エラー・メッセージ           --# 固定 #
            ,lv_retcode                            -- リターン・コード             --# 固定 #
            ,lv_errmsg                             -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_common_expt;
          END IF;
          lv_customer_number := gt_tab_work_data(ln_i).customer_number;
          ln_cust_account_id := gt_tab_work_data(ln_i).cust_account_id;
        END IF;
      END LOOP gt_tab_work_data_loop;
    END IF;
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
    -- ===============================
    -- A-4．商品別売上算処理
    -- ===============================
    calc_sales(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      RAISE global_common_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_err_emp := lv_retcode;
    END IF;
    -- ===============================
    -- A-5．販売実績明細作成
    -- ===============================
    set_lines(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      gn_normal_cnt := 0;
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-6．販売実績ヘッダ作成
    -- ===============================
    set_headers(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      gn_normal_cnt := 0;
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-7．消化処理設定
    -- ===============================
    update_digestion(
       iv_base_code       -- 拠点コード
      ,iv_customer_number -- 顧客コード
--******************************* 2010/02/15 1.17 M.Hokkanji ADD START **************************************************************
      ,iv_exec_div        -- 定期随時区分
--******************************* 2010/02/15 1.17 M.Hokkanji ADD END   **************************************************************
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/06/09 1.12 T.Kitajima ADD START ******************************--
      gn_error_cnt  := 1;
--****************************** 2009/06/09 1.12 T.Kitajima ADD  END  ******************************--
      gn_normal_cnt := 0;
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- <処理部、ループ部名> (処理結果によって後続処理を制御する場合)
    -- ===============================
    --データ作成時の警告有無
    IF ( lv_err_emp = cv_status_warn ) THEN
      ov_retcode := lv_err_emp;
    END IF;
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
       iv_which   => cv_log_header_out
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
       iv_exec_div        -- 1.定期随時区分
      ,iv_base_code       -- 2.拠点コード
      ,iv_customer_number -- 3.顧客コード
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
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
    IF (lv_retcode != cv_status_normal) THEN
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
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
END XXCOS004A02C;
/
