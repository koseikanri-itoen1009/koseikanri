CREATE OR REPLACE PACKAGE BODY APPS.XXCOS004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A01C (body)
 * Description      : 店舗別掛率作成
 * MD.050           : 店舗別掛率作成 MD050_COS_004_A01
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  pram_chk               パラメータチェック(A-1)
 *  data_del_former        店舗別用消化計算情報の前回データ削除(A-2)
 *  get_cust_data          顧客マスタデータ取得処理(A-3)
 *  data_del_now           店舗別用消化計算情報の今回データ削除(A-4)
 *  init_header            ヘッダ単位初期化処理(A-5)
 *  get_ar_data            AR取引情報取得処理(A-6)(A-7)
 *  get_inv_data           INV月次在庫受払い表情報取得処理(A-8)(A-9)(A-10)(A-11)
 *  set_header             店舗別用消化計算ヘッダ登録処理(A-12)
 *  insert_lines           店舗別用消化計算明細テーブル登録
 *  insert_headers         店舗別用消化計算ヘッダテーブル登録
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   T.Kitajima       新規作成
 *  2009/02/06    1.1   K.Kakishita      [COS_036]AR取引タイプマスタの抽出条件に営業単位を追加
 *  2009/02/10    1.2   T.kitajima       [COS_057]顧客区分絞り込み条件不足対応(仕様漏れ)
 *  2009/02/17    1.3   T.kitajima       get_msgのパッケージ名修正
 *  2009/02/24    1.4   T.kitajima       パラメータのログファイル出力対応
 *  2009/03/05    1.5   N.Maeda          棚卸減耗の抽出時の計算処理削除
 *                                       ・修正前
 *                                         ⇒sirm.inv_wear * -1
 *                                       ・修正後
 *                                         ⇒sirm.inv_wear
 *  2009/03/19    1.6   T.kitajima       [T1_0093] INV月次在庫受払い表情報取得修正
 *  2009/07/17    1.7   T.Tominaga       [0000429] PTの考慮、ロック処理の条件修正
 *  2009/08/03    1.7   N.Maeda          [0000429] レビュー指摘対応
 *  2009/12/16    1.8   N.Maeda          [E_本稼動_00486] 今回データ削除条件修正
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
  global_common_expt          EXCEPTION;                              --共通エラー
  global_get_profile_expt     EXCEPTION;                              --プロファイルエラー
  global_proc_date_err_expt   EXCEPTION;                              --業務日付取得エラー例外
  global_require_param_expt   EXCEPTION;                              --必須入力パラメータ未設定エラー例外
  global_call_api_expt        EXCEPTION;                              --API呼出エラー例外
  global_data_lock_expt       EXCEPTION;                              --ロックエラー
  global_data_del_expt        EXCEPTION;                              --削除エラー
  global_select_err_expt      EXCEPTION;                              --SELECTエラー
  global_no_data_expt         EXCEPTION;                              --対象データなし
  global_get_item_err_expt    EXCEPTION;                              --品目マスタ取得エラー
  global_insert_expt          EXCEPTION;                              --データ登録エラー
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );                --ロックエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                   CONSTANT  VARCHAR2(100) := 'XXCOS004A01C';
                                                                      -- パッケージ名
--
  --アプリケーション短縮名
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE
                                          := 'XXCOS';                 --販物短縮アプリ名
  --販物メッセージ
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00001';      --ロック取得エラーメッセージ
  cv_msg_nodata_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00003';      --対象データ無しエラー
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00004';      --プロファイル取得エラー
  ct_msg_require_param_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00006';      --必須入力パラメータ未設定エラー
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00012';      --データ削除エラーメッセージ
  ct_msg_process_date_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00014';      --業務日付取得エラー
  ct_msg_call_api_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00017';      --API呼出エラーメッセージ
  ct_msg_pram_date              CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10901';      --パラメータメッセージ
  ct_msg_select_count           CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10902';      --対象件数メッセージ
  ct_msg_warn_count             CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10903';      --警告件数メッセージ
  cv_msg_select_cust_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10909';      --顧客情報抽出エラー
  cv_msg_select_salesreps_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10911';      --営業担当員コード取得エラー
  cv_msg_select_ar_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10912';      --AR取引情報取得エラー
  cv_msg_select_inv_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10913';      --INV月次在庫受払表情報取得エラー
  cv_msg_select_item_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10914';      --品目マスタ情報取得エラー
  cv_msg_inser_lines_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10915';      --店舗別用消化計算明細テーブル登録エラー
  cv_msg_inser_headers_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10916';      --店舗別用消化計算ヘッダテーブル登録エラー
  --文字列用
  ct_msg_base_code              CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00055';      --拠点コード
  ct_msg_max_date               CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00056';      --XXCOS:MAX日付
  ct_msg_org_id                 CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00047';      --MO:営業単位
  ct_msg_get_organization_code  CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00048';      --XXCOI:在庫組織コード
  ct_msg_get_organization_id    CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10904';      --在庫組織IDの取得
  ct_msg_get_shop_hdr_name      CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10905';      --店舗別用消化計算ヘッダテーブル
  ct_msg_get_shop_line_name     CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10906';      --店舗別用消化計算明細テーブル
  ct_msg_get_shop_data_name     CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10907';      --店舗別用消化計算情報
  ct_msg_key_info1              CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10908';      --キー情報（消化計算締年月日）
  ct_msg_key_info2              CONSTANT  fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10910';      --キー情報（消化計算締年月日,顧客コード）
  --プロファイル名称
  ct_prof_max_date              CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_MAX_DATE';       --MAX日付
  ct_prof_org_id                CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'ORG_ID';                --MO:営業単位
  ct_prof_organization_code     CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOI1_ORGANIZATION_CODE';
                                                                      --XXCOI:在庫組織コード
  --クイックコードタイプ
  ct_qct_cust_type              CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS1_CUS_CLASS_MST_004_A01';
                                                                      --顧客区分特定マスタ
  ct_qct_gyo_type               CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS1_GYOTAI_SHO_MST_004_A01';
                                                                      --業態小分類特定マスタ_004_A01
  ct_qct_customer_trx_type      CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS1_AR_TRX_TYPE_MST_004_A01';
                                                                      --ＡＲ取引タイプ特定マスタ_004_A01
  --クイックコード
  ct_qcc_it_code                CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_004_A01%';        --インショップ/当社直営店
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--  ct_qcc_customer_trx_type1     CONSTANT  fnd_lookup_types.lookup_type%TYPE
--                                          := 'XXCOS_004_A01_1%';      --ＡＲ取引タイプ特定マスタ(通常)
--  ct_qcc_customer_trx_type2     CONSTANT  fnd_lookup_types.lookup_type%TYPE
--                                          := 'XXCOS_004_A01_2%';      --ＡＲ取引タイプ特定マスタ(売掛金訂正)
  ct_qcc_customer_trx_type      CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                          := 'XXCOS_004_A01%';        --ＡＲ取引タイプ特定マスタ
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
  ct_qcc_cust_code_1            CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_004_A01_1%';      --拠点
  ct_qcc_cust_code_2            CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_004_A01_2%';      --顧客
  --トークン
  cv_tkn_in_param               CONSTANT  VARCHAR2(100) := 'IN_PARAM';--キーデータ
  cv_tkn_parm_data1             CONSTANT  VARCHAR2(10)  := 'PARAM1';  --パラメータ1
  cv_tkn_parm_data2             CONSTANT  VARCHAR2(10)  := 'PARAM2';  --パラメータ2
  cv_tkn_cnt_data1              CONSTANT  VARCHAR2(10)  := 'COUNT1';  --カウント1
  cv_tkn_cnt_data2              CONSTANT  VARCHAR2(10)  := 'COUNT2';  --カウント2
  cv_tkn_cnt_data3              CONSTANT  VARCHAR2(10)  := 'COUNT3';  --カウント3
-- ************* 2009/12/16 1.8 N.Maeda ADD START ************* --
  cv_tkn_cnt_data4              CONSTANT  VARCHAR2(10)  := 'COUNT4';  --カウント4
-- ************* 2009/12/16 1.8 N.Maeda ADD  END  ************* --
  cv_tkn_profile                CONSTANT  VARCHAR2(100) := 'PROFILE'; --プロファイル
  cv_tkn_table                  CONSTANT  VARCHAR2(100) := 'TABLE';   --テーブル
  cv_tkn_table_name             CONSTANT  VARCHAR2(100) := 'TABLE_NAME';
                                                                      --テーブル名称
  cv_tkn_key_data               CONSTANT  VARCHAR2(100) := 'KEY_DATA';--キーデータ
  cv_tkn_api_name               CONSTANT  VARCHAR2(100) := 'API_NAME';--ＡＰＩ名称
  cv_tkn_diges_due_dt           CONSTANT  VARCHAR2(100) := 'DIGES_DUE_DT';
                                                                      --消化計算締年月日
  --フォーマット
  cv_fmt_date                   CONSTANT  VARCHAR2(10)  := 'RRRR/MM/DD';
  cv_fmt_yyyymm                 CONSTANT  VARCHAR2(6)   := 'YYYYMM';
  cv_fmt_mm                     CONSTANT  VARCHAR2(6)   := 'MM';
  --使用可能フラグ定数
  ct_enabled_flag_yes           CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                          := 'Y';                     --使用可能
  --店舗ヘッダ用フラグ
  ct_make_flag_yes              CONSTANT  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                          := 'Y';                     --作成済み
  ct_make_flag_no               CONSTANT  xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                          := 'N';                     --未作成
  --完了フラグ
  ct_complete_flag_yes          CONSTANT  ra_customer_trx_all.complete_flag%TYPE
                                          := 'Y';                     --完了
  --明細タイプ
  ct_line_type_line             CONSTANT  ra_customer_trx_lines_all.line_type%TYPE
                                          := 'LINE';                  --LINE
  --未計算区分
  ct_uncalc_class_0             CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                          := '0';
  ct_uncalc_class_1             CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                          := '1';
  ct_uncalc_class_2             CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                          := '2';
  ct_uncalc_class_3             CONSTANT  xxcos_shop_digestion_hdrs.uncalculate_class%TYPE
                                          := '3';
  --棚卸対象区分
  ct_secondary_class_2         CONSTANT   mtl_secondary_inventories.attribute5%TYPE
                                          := '2';                     --消化
  --棚卸区分
  ct_inventory_class_2         CONSTANT   xxcoi_inv_reception_monthly.inventory_kbn%TYPE
                                          := '2';                     --月末
  --Disc品目変更履歴アドオン(適用フラグ)
  ct_apply_flag_yes            CONSTANT   xxcmm_system_items_b_hst.apply_flag%TYPE
                                          := 'Y';                     --適用
  --未計算タイプ
  cv_uncalculate_type_init      CONSTANT  VARCHAR2(1) := '0';         --INIT
  cv_uncalculate_type_nof       CONSTANT  VARCHAR2(1) := '1';         --NOF
  cv_uncalculate_type_zero      CONSTANT  VARCHAR2(1) := '2';         --ZERO
  --存在フラグ
  cv_exists_flag_yes            CONSTANT  VARCHAR2(1) := 'Y';         --存在あり
  cv_exists_flag_no             CONSTANT  VARCHAR2(1) := 'N';         --存在なし
  --金額デフォルト
  cn_amount_default             CONSTANT  NUMBER      := 0;           --金額
--******************************* 2009/07/17 1.7 T.Tominaga ADD START ***************************************
  --言語コード
  ct_lang                       CONSTANT  fnd_lookup_values.language%TYPE
                                          := USERENV('LANG');
--******************************* 2009/07/17 1.7 T.Tominaga ADD END   ***************************************
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  --顧客情報テーブル
  TYPE g_rec_cust_data IS RECORD
    (
      --顧客マスタ.顧客ID
      cust_account_id           hz_cust_accounts.cust_account_id%TYPE,
      --顧客マスタ.顧客コード
      account_number            hz_cust_accounts.account_number%TYPE,
      --顧客マスタ.パーティID
      party_id                  hz_cust_accounts.party_id%TYPE,
      --顧客アドオンマスタ.消化計算用掛率
      rate                      xxcmm_cust_accounts.rate%TYPE,
      --顧客アドオンマスタ.前月売上拠点コード   or 売上拠点コード
      past_sale_base_code       xxcmm_cust_accounts.past_sale_base_code%TYPE,
      --顧客アドオンマスタ.業態小分類
      business_low_type         xxcmm_cust_accounts.business_low_type%TYPE,
      --顧客アドオンマスタ.納品拠点コード
      delivery_base_code        xxcmm_cust_accounts.delivery_base_code%TYPE,
      --店舗別用消化計算ヘッダ.店舗別用消化計算ヘッダID
      shop_digestion_hdr_id     xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE
-- ************* 2009/12/16 1.8 N.Maeda ADD START ************* --
      ,sales_result_creation_flag xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
-- ************* 2009/12/16 1.8 N.Maeda ADD  END  ************* --
  );
--
  --品目情報テーブル
  TYPE g_rec_item_data IS RECORD
    (
      --品目マスタ.品目コード
      segment1                  mtl_system_items_b.segment1%TYPE,
      --品目マスタ.単位コード
      primary_unit_of_measure   mtl_system_items_b.primary_unit_of_measure%TYPE,
      --品目営業履歴アドオン.定価
      fixed_price               xxcmm_system_items_b_hst.fixed_price%TYPE
  );
--
  --テーブル定義
  TYPE g_tab_cust_data          IS TABLE OF g_rec_cust_data                   INDEX BY PLS_INTEGER;
                                                                      --店舗別用消化計算データ格納用変数
  TYPE g_tab_item_data          IS TABLE OF g_rec_item_data                   INDEX BY PLS_INTEGER;
                                                                      --品目マスタ格納用
  TYPE g_tab_shop_lns           IS TABLE OF xxcos_shop_digestion_lns%ROWTYPE  INDEX BY PLS_INTEGER;
                                                                      --店舗別用消化計算明細テーブル
  TYPE g_tab_shop_hdrs          IS TABLE OF xxcos_shop_digestion_hdrs%ROWTYPE INDEX BY PLS_INTEGER;
                                                                      --店舗別用消化計算ヘッダテーブル
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --入力パラメータ
  gv_base_code                  VARCHAR2(10);                         -- 拠点コード
  gv_cust_code                  VARCHAR2(10);                         -- 顧客コード
  --グローバルカウンター
  gn_cust_cnt                   NUMBER;                               -- 顧客マスタ対象件数
  gn_ar_cnt                     NUMBER;                               -- AR取引情報ヘッダ対象件数
  gn_inv_cnt                    NUMBER;                               -- INV月次棚卸受払表対象件数
  gn_uncalc_cnt1                NUMBER;                               -- 未計算区分１件数
  gn_uncalc_cnt2                NUMBER;                               -- 未計算区分２件数
  gn_uncalc_cnt3                NUMBER;                               -- 未計算区分３件数
  gn_line_count                 NUMBER;                               -- 明細カウント
  gn_header_count               NUMBER;                               -- ヘッダカウント
-- ************* 2009/12/16 1.8 N.Maeda ADD START ************* --
  gn_creation_count             NUMBER;                               -- 販売実績連携済件数
-- ************* 2009/12/16 1.8 N.Maeda ADD  END  ************* --
  --
  gn_org_id                     NUMBER;                               -- 営業単位
  --日付関連
  gd_process_date               DATE;                                 -- 業務日付
  gd_begi_month_date            DATE;                                 -- 前月開始日
  gd_last_month_date            DATE;                                 -- 前月末日
  gv_month_date                 VARCHAR(6);                           -- 前月(年月)
  gd_max_date                   DATE;                                 -- MAX日付
--
  gt_organization_code          mtl_parameters.organization_code%TYPE;-- 在庫組織コード
  gt_organization_id            mtl_parameters.organization_id%TYPE;  -- 在庫組織ID
--
  gt_tab_cust_data              g_tab_cust_data;                      --対象顧客データ取得用
  gt_tab_item_data              g_tab_item_data;                      --品目マスタ一時格納用
  gt_tab_shop_hdrs              g_tab_shop_hdrs;                      --店舗別用消化計算ヘッダ格納用
  gt_tab_shop_lns               g_tab_shop_lns;                       --店舗別用消化計算明細格納用
  gt_tab_shop_del_hdrs          g_tab_shop_hdrs;                      --今回削除店舗別用消化計算ヘッダ格納用
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
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
    --入力項目表示
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_pram_date
                    ,iv_token_name1  => cv_tkn_parm_data1
                    ,iv_token_value1 => gv_base_code
                    ,iv_token_name2  => cv_tkn_parm_data2
                    ,iv_token_value2 => gv_cust_code
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : pram_chk
   * Description      : パラーメータチェック(A-1)
   ***********************************************************************************/
  PROCEDURE pram_chk(
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
    lv_org_id                     VARCHAR2(5000);
    lv_max_date                   VARCHAR2(5000);
    --エラーメッセージ用
    lv_str_api_name               VARCHAR2(5000);                     --関数名
    lv_str_profile_name           VARCHAR2(5000);                     --プロファイル名
    lv_str_in_param               VARCHAR2(5000);                     --入力パラメータ名
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
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
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
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 3.MO:営業単位
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
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_org_id                 := TO_NUMBER( lv_org_id );
--
    --============================================
    -- 4.XXCOI:在庫組織コード
    --============================================
    gt_organization_code      := FND_PROFILE.VALUE( ct_prof_organization_code );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_organization_code IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_organization_code
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --============================================
    -- 5. 在庫組織IDの取得
    --============================================
    gt_organization_id        := xxcoi_common_pkg.get_organization_id(
                                   iv_organization_code          => gt_organization_code
                                 );
    --
    IF ( gt_organization_id IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_organization_id
                                         );
      RAISE global_call_api_expt;
    END IF;
--
    --============================================
    -- 6. 日付取得
    --============================================
    --前月開始年月日取得
    gd_begi_month_date := TRUNC( ADD_MONTHS( gd_process_date, -1 ), cv_fmt_mm );
    --前月終了年月日取得
    gd_last_month_date := LAST_DAY( ADD_MONTHS( gd_process_date, -1 ) );
    --前月年月取得
    gv_month_date      := TO_CHAR( gd_begi_month_date, cv_fmt_yyyymm );
--
    --============================================
    -- 7. 拠点コード必須チェック
    --============================================
    IF ( gv_base_code IS NULL ) THEN
      lv_str_in_param         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_base_code
                                 );
      RAISE global_require_param_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** プロファイル取得例外ハンドラ ***
    WHEN global_get_profile_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_profile_err,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_str_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数エラー例外ハンドラ ***
    WHEN global_call_api_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_str_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 必須入力パラメータ未設定例外ハンドラ ***
    WHEN global_require_param_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_require_param_err,
                                   iv_token_name1        => cv_tkn_in_param,
                                   iv_token_value1       => lv_str_in_param
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
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
--####################################  固定部 END   ##########################################
--
  END pram_chk;
--
  /**********************************************************************************
   * Procedure Name   : data_del_former
   * Description      : 店舗別用消化計算情報の前回データ削除(A-2)
   ***********************************************************************************/
  PROCEDURE data_del_former(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_del_former'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT xsdh.shop_digestion_hdr_id
        FROM xxcos_shop_digestion_hdrs xsdh,
             xxcos_shop_digestion_lns  xsdl
       WHERE xsdh.digestion_due_date         < gd_last_month_date
         AND xsdh.sales_result_creation_flag = ct_make_flag_yes
--******************************* 2009/07/17 1.7 T.Tominaga ADD START ***************************************
--         AND xsdh.shop_digestion_hdr_id      = xsdl.shop_digestion_ln_id(+)
         AND xsdh.shop_digestion_hdr_id      = xsdl.shop_digestion_hdr_id(+)
--******************************* 2009/07/17 1.7 T.Tominaga ADD END   ***************************************
       FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
    l_lock_rec lock_cur%ROWTYPE;
--
    -- *** ローカル・関数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.データロック
    --==================================
    BEGIN
      FOR l_lock_rec IN lock_cur LOOP
        --==================================
        -- 1.ヘッダ部削除
        --==================================
        BEGIN
          DELETE
            FROM xxcos_shop_digestion_hdrs xsdh
           WHERE xsdh.shop_digestion_hdr_id = l_lock_rec.shop_digestion_hdr_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_str_table_name       := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => ct_msg_get_shop_hdr_name
                                       );
            RAISE global_data_del_expt;
        END;
--
        --==================================
        -- 2.明細部削除
        --==================================
        BEGIN
          DELETE
            FROM xxcos_shop_digestion_lns xsds
           WHERE xsds.shop_digestion_hdr_id = l_lock_rec.shop_digestion_hdr_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_str_table_name       := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => ct_msg_get_shop_line_name
                                       );
            RAISE global_data_del_expt;
        END;
      END LOOP;
    EXCEPTION
      --削除エラー
      WHEN global_data_del_expt THEN
        lv_str_key_data         := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_key_info1,
                                     iv_token_name1        => cv_tkn_diges_due_dt,
                                     iv_token_value1       => TO_CHAR( gd_last_month_date, cv_fmt_date )
                                   );
        RAISE global_data_del_expt;
      --ロックエラー
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      --テーブル名取得
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_shop_data_name
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_str_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 処理対象データ削除ハンドラ ***
    WHEN global_data_del_expt THEN
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_delete_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
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
  END data_del_former;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_data
   * Description      : 顧客マスタデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_data(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_data'; -- プログラム名
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
      SELECT hca.cust_account_id cust_account_id,                     --顧客マスタ.顧客ID
             hca.account_number  account_number,                      --顧客マスタ.顧客コード
             hca.party_id        party_id,                            --顧客マスタ.パーティID
             xca.rate            rate,                                --顧客アドオンマスタ.消化計算用掛率
             NVL( xca.past_sale_base_code, xca.sale_base_code ) base_code,
                                                                      --顧客アドオンマスタ.前月売上拠点コード
                                                                      -- or 売上拠点コード
             xca.business_low_type business_low_type,                 --顧客アドオンマスタ.業態小分類
             xca.delivery_base_code delivery_base_code,               --顧客アドオンマスタ.納品拠点コード
             xsh.shop_digestion_hdr_id                                --店舗別用消化計算ヘッダ.店舗別用消化計算ヘッダID
-- ************* 2009/12/16 1.8 N.Maeda ADD START ************* --
             ,xsh.sales_result_creation_flag   sales_result_creation_flag   -- 販売実績連携フラグ
-- ************* 2009/12/16 1.8 N.Maeda ADD  END  ************* --
        FROM hz_cust_accounts          hca,                           --顧客マスタ
             xxcmm_cust_accounts       xca,                           --顧客アドオンマスタ
             xxcos_shop_digestion_hdrs xsh                            --店舗別用消化計算ヘッダテーブル
       -- 顧客マスタ.顧客ID = 顧客アドオンマスタ.顧客ID
       WHERE hca.cust_account_id       = xca.customer_id
         --顧客アドオンマスタ.業態小分類=インショップ,当社直営店
         AND EXISTS (SELECT flv.meaning                   meaning
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--                       FROM fnd_application               fa,
--                            fnd_lookup_types              flt,
--                            fnd_lookup_values             flv
--                      WHERE fa.application_id                               =    flt.application_id
--                        AND flt.lookup_type                                 =    flv.lookup_type
--                        AND fa.application_short_name                       =    ct_xxcos_appl_short_name
                       FROM fnd_lookup_values             flv
                      WHERE flv.lookup_type                                 =    ct_qct_gyo_type
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
                        AND flv.lookup_code                                 LIKE ct_qcc_it_code
                        AND flv.start_date_active                          <=    gd_last_month_date
                        AND NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
                        AND flv.enabled_flag                                =    ct_enabled_flag_yes
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--                        AND flv.language                                    =    USERENV( 'LANG' )
                        AND flv.language                                    =    ct_lang
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
                        AND flv.meaning                                     =    xca.business_low_type
             )
         --NVL(顧客アドオン.前月売上拠点コード,顧客アドオン.売上拠点コード) IN 拠点コードに属する拠点情報サブクエリ
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--         AND NVL( xca.past_sale_base_code, xca.sale_base_code ) IN (
--                    SELECT gv_base_code         base_code             -- ユーザー拠点コード
--                      FROM DUAL
--                    UNION
         AND ( ( NVL( xca.past_sale_base_code, xca.sale_base_code ) = gv_base_code )  -- ユーザー拠点コード
             OR ( EXISTS (
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
                    SELECT hcai.account_number  base_code             -- ユーザー拠点コード
                      FROM hz_cust_accounts    hcai,                  -- 顧客マスタ
                           xxcmm_cust_accounts xcai                   -- 顧客アドオンマスタ
                     -- 顧客マスタ.顧客ID = 顧客アドオンマスタ.顧客ID
                     WHERE hcai.cust_account_id      = xcai.customer_id
                       --顧客アドオンマスタ.管理元拠点コード = パラメータの拠点コード
                       AND xcai.management_base_code = gv_base_code
                       --顧客マスタ.顧客区分 = 1(拠点)
                       AND EXISTS (SELECT flv.meaning                   meaning
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--                                   FROM   fnd_application               fa,
--                                          fnd_lookup_types              flt,
--                                          fnd_lookup_values             flv
--                                   WHERE  fa.application_id                               =    flt.application_id
--                                     AND  flt.lookup_type                                 =    flv.lookup_type
--                                     AND  fa.application_short_name                       =    ct_xxcos_appl_short_name
--                                     AND  flv.lookup_type                                 =    ct_qct_cust_type
                                    FROM  fnd_lookup_values             flv
                                   WHERE  flv.lookup_type                                 =    ct_qct_cust_type
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
                                     AND  flv.lookup_code                                 LIKE ct_qcc_cust_code_1
                                     AND  flv.start_date_active                          <=    gd_last_month_date
                                     AND  NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
                                     AND  flv.enabled_flag                                =    ct_enabled_flag_yes
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--                                     AND  flv.language                                    =    USERENV( 'LANG' )
                                     AND  flv.language                                    =    ct_lang
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
                                     AND  flv.meaning                                     =    hcai.customer_class_code
                                  )
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
                       AND hcai.account_number       = NVL( xca.past_sale_base_code, xca.sale_base_code )
                    )
                )
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
             )
-- ****************************** 2009/08/03 1.7 N.Maeda    MOD START ***************************************
--         --顧客マスタ.顧客コード = NVL(INパラ(顧客コード),顧客マスタ.顧客コード)
--         AND hca.account_number                = NVL( gv_cust_code, hca.account_number )
--
         -- INパラ(顧客コード) = null or INパラ(顧客コード) != null and 顧客マスタ.顧客コード = INパラ(顧客コード)
         AND ( ( gv_cust_code IS NULL )
           OR ( gv_cust_code IS NOT NULL AND hca.account_number = gv_cust_code) )
-- ****************************** 2009/08/03 1.7 N.Maeda    MOD  END  ***************************************
         --店舗別用消化計算ヘッダ.消化計算締年月日(+) = 前月終了年月日
         AND xsh.digestion_due_date(+)         = gd_last_month_date
         --顧客マスタ.顧客ID = 店舗別用消化計算ヘッダ.顧客ID(+)
         AND hca.cust_account_id               = xsh.cust_account_id(+)
-- ************* 2009/12/16 1.8 N.Maeda DEL START ************* --
--         --店舗別用消化計算ヘッダ.販売実績作成フラグ(+) = 'N'
--         AND xsh.sales_result_creation_flag(+) = ct_make_flag_no
-- ************* 2009/12/16 1.8 N.Maeda DEL  END  ************* --
         --NVL(顧客アドオンマスタ.中止決済日,前月終了年月日) BETWEEN 前月開始日 AND 前月終了年月日
         AND NVL( xca.stop_approval_date, gd_last_month_date ) BETWEEN gd_begi_month_date AND gd_last_month_date
         --顧客マスタ.顧客区分 = 10:顧客(2009/02/10 1.2)
         AND EXISTS (SELECT flv.meaning
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--                     FROM   fnd_application               fa,
--                            fnd_lookup_types              flt,
--                            fnd_lookup_values             flv
--                     WHERE  fa.application_id                               =    flt.application_id
--                     AND    flt.lookup_type                                 =    flv.lookup_type
--                     AND    fa.application_short_name                       =    ct_xxcos_appl_short_name
--                     AND    flv.lookup_type                                 =    ct_qct_cust_type
                   FROM     fnd_lookup_values             flv
                   WHERE    flv.lookup_type                                 =    ct_qct_cust_type
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
                     AND    flv.lookup_code                                 LIKE ct_qcc_cust_code_2
                     AND    flv.start_date_active                          <=    gd_last_month_date
                     AND    NVL( flv.end_date_active, gd_last_month_date ) >=    gd_last_month_date
                     AND    flv.enabled_flag                                =    ct_enabled_flag_yes
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--                     AND    flv.language                                    =    USERENV( 'LANG' )
                     AND    flv.language                                    =    ct_lang
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
                     AND    flv.meaning                                     =    hca.customer_class_code
                    )
      ORDER BY hca.account_number --顧客マスタ.顧客コード
    ;
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
    --対象データ取得用カーソルOPEN
    BEGIN
      OPEN get_data_cur;
      -- バルクフェッチ
      FETCH get_data_cur BULK COLLECT INTO gt_tab_cust_data;
      --取得件数
      gn_cust_cnt := get_data_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE get_data_cur;
    EXCEPTION
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
    IF ( gn_cust_cnt = 0 ) THEN
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
      ov_retcode := cv_status_warn;
    -- *** SQL SELECT エラー ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_cust_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => gv_base_code,
                                   iv_token_name2        => cv_tkn_parm_data2,
                                   iv_token_value2       => gv_cust_code
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
  END get_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : data_del_now
   * Description      : 店舗別用消化計算情報の今回データ削除(A-4)
   ***********************************************************************************/
  PROCEDURE data_del_now(
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_del_now'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
    lt_customer_number            xxcos_shop_digestion_hdrs.customer_number%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur(
      it_customer_number          xxcos_shop_digestion_hdrs.customer_number%TYPE
    )
    IS
      SELECT xsdh.customer_number        customer_number
        FROM xxcos_shop_digestion_hdrs   xsdh,
             xxcos_shop_digestion_lns    xsdl
       WHERE xsdh.digestion_due_date         = gd_last_month_date
--******************************* 2009/07/17 1.7 T.Tominaga ADD START ***************************************
--         AND xsdh.shop_digestion_hdr_id      = xsdl.shop_digestion_ln_id(+)
         AND xsdh.shop_digestion_hdr_id      = xsdl.shop_digestion_hdr_id(+)
--******************************* 2009/07/17 1.7 T.Tominaga ADD END   ***************************************
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
    l_lock_rec lock_cur%ROWTYPE;
--
    -- *** ローカル・関数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.消化VD情報データロック
    --==================================
    <<lock_loop>>
    FOR i IN 1..gt_tab_shop_del_hdrs.COUNT LOOP
      --顧客コード設定
      lt_customer_number := gt_tab_shop_del_hdrs(i).customer_number;
      --==================================
      -- 1.消化VD情報データロック
      --==================================
      BEGIN
        OPEN lock_cur( it_customer_number => gt_tab_shop_del_hdrs(i).customer_number );
        CLOSE lock_cur;
      EXCEPTION
        WHEN global_data_lock_expt THEN
          RAISE global_data_lock_expt;
      END;
  --
-- ************* 2009/12/16 1.8 N.Maeda MOD START ************* --
--      --==================================
--      -- 1.ヘッダ部削除
--      --==================================
--      BEGIN
--        DELETE
--          FROM xxcos_shop_digestion_hdrs xsdh
--         WHERE xsdh.customer_number            = gt_tab_shop_del_hdrs(i).customer_number
--           AND xsdh.digestion_due_date         = gd_last_month_date
--        ;
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_str_table_name       := xxccp_common_pkg.get_msg(
--                                       iv_application        => ct_xxcos_appl_short_name,
--                                       iv_name               => ct_msg_get_shop_hdr_name
--                                     );
--          RAISE global_data_del_expt;
--      END;
  --
      --==================================
      -- 1.明細部削除
      --==================================
      BEGIN
        DELETE
          FROM xxcos_shop_digestion_lns xsds
         WHERE xsds.customer_number            = gt_tab_shop_del_hdrs(i).customer_number
           AND xsds.digestion_due_date         = gd_last_month_date
           AND EXISTS ( SELECT 'Y'
                        FROM   xxcos_shop_digestion_hdrs xsdh
                        WHERE  xsdh.shop_digestion_hdr_id      = xsds.shop_digestion_hdr_id
                        AND  xsdh.sales_result_creation_flag   = ct_make_flag_no            -- 販売実績未作成
                      )
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_str_table_name       := xxccp_common_pkg.get_msg(
                                       iv_application        => ct_xxcos_appl_short_name,
                                       iv_name               => ct_msg_get_shop_line_name
                                     );
          RAISE global_data_del_expt;
      END;
--
      --==================================
      -- 2.ヘッダ部削除
      --==================================
      BEGIN
        DELETE
          FROM xxcos_shop_digestion_hdrs xsdh
         WHERE xsdh.customer_number            = gt_tab_shop_del_hdrs(i).customer_number
           AND xsdh.digestion_due_date         = gd_last_month_date
           AND xsdh.sales_result_creation_flag = ct_make_flag_no            -- 販売実績未作成
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_str_table_name       := xxccp_common_pkg.get_msg(
                                       iv_application        => ct_xxcos_appl_short_name,
                                       iv_name               => ct_msg_get_shop_hdr_name
                                     );
          RAISE global_data_del_expt;
      END;
--
-- ************* 2009/12/16 1.8 N.Maeda MOD  END  ************* --
--
    END LOOP lock_loop;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --テーブル名取得
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_shop_data_name
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_str_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 処理対象データ削除ハンドラ ***
    WHEN global_data_del_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      lv_str_key_data         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_key_info2,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => TO_CHAR( gd_last_month_date, cv_fmt_date ),
                                   iv_token_name2        => cv_tkn_parm_data2,
                                   iv_token_value2       => lt_customer_number
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_delete_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_del_now;
--
  /**********************************************************************************
   * Procedure Name   : init_header
   * Description      : ヘッダ単位初期化処理(A-5)
   ***********************************************************************************/
  PROCEDURE init_header(
    it_party_id                    IN  hz_cust_accounts.party_id%TYPE,--  パーティID
    it_customer_number             IN  xxcos_shop_digestion_hdrs.customer_number%TYPE,
                                                                      --  顧客コード
    ot_shop_digestion_hdr_id       OUT xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE,
                                                                      --  店舗別用消化計算ヘッダID
    ov_ar_uncalculate_type         OUT VARCHAR2,                      --  AR未計算区分
    ov_inv_uncalculate_type        OUT VARCHAR2,                      --  INV未計算区分
    on_sales_amount                OUT NUMBER,                        --  店舗別売上金額
    on_check_amount                OUT NUMBER,                        --  チェック用店舗別売上金額
    ot_performance_by_code         OUT xxcos_shop_digestion_hdrs.performance_by_code%TYPE,
                                                                      --  営業担当員コード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_header'; -- プログラム名
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
    --==================================
    -- 1.消化VD用消化計算ヘッダIDの取得
    --==================================
    BEGIN
      SELECT xxcos_shop_digestion_hdrs_s01.NEXTVAL       shop_digestion_hdr_id
        INTO ot_shop_digestion_hdr_id
        FROM dual
      ;
    END;
--
    --==================================
    -- 2.各種変数クリア処理
    --==================================
    ov_ar_uncalculate_type   := cv_uncalculate_type_init;
    ov_inv_uncalculate_type  := cv_uncalculate_type_init;
    on_sales_amount          := cn_amount_default;
    on_check_amount          := cn_amount_default;
--
    --==================================
    -- 3.営業担当員コード取得
    --==================================
    BEGIN
      SELECT xsv.employee_number
        INTO ot_performance_by_code
        FROM xxcos_salesreps_v xsv
       WHERE xsv.party_id                                         = it_party_id
         AND xsv.effective_start_date                            <= gd_last_month_date
         AND NVL( xsv.effective_end_date, gd_last_month_date )   >= gd_last_month_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_select_err_expt;
    END;
--
  EXCEPTION
    -- *** SQL SELECT エラー ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_salesreps_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => it_customer_number
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
  END init_header;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_data
   * Description      : AR取引情報取得処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_ar_data(
    it_cust_account_id     IN  hz_cust_accounts.cust_account_id%TYPE, --顧客ID
    it_account_number      IN  hz_cust_accounts.account_number%TYPE,  --顧客コード
    ov_ar_uncalculate_type OUT VARCHAR2,                              --AR未計算区分
    on_sales_amount        OUT NUMBER,                                --店舗別売上金額
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_data'; -- プログラム名
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
    ln_ar_amount                        NUMBER;                       --売上金額合計
    lv_exists_flag                      VARCHAR2(1);
--
    -- *** ローカル・カーソル ***
    -- AR取引情報取得処理
    CURSOR ar_cur
    IS
      SELECT rctlgda.gl_date                     gl_date,             --売上計上日
             rctla.extended_amount               extended_amount      --本体金額
        FROM ra_customer_trx_all                 rcta,                --AR取引情報テーブル
             ra_customer_trx_lines_all           rctla,               --AR取引明細テーブル
             ra_cust_trx_line_gl_dist_all        rctlgda,             --AR取引明細会計配分テーブル
             ra_cust_trx_types_all               rctta                --AR取引タイプマスタ
       WHERE rcta.ship_to_customer_id          = it_cust_account_id
         AND rcta.customer_trx_id              = rctla.customer_trx_id
         AND rctla.customer_trx_id             = rctlgda.customer_trx_id
         AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
         AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
         AND rctla.line_type                   = ct_line_type_line
         AND rcta.complete_flag                = ct_complete_flag_yes
         AND rctlgda.gl_date                  >= gd_begi_month_date
         AND rctlgda.gl_date                  <= gd_last_month_date
         AND rcta.org_id                       = gn_org_id
         AND EXISTS(SELECT cv_exists_flag_yes               exists_flag
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--                      FROM fnd_application                  fa,
--                           fnd_lookup_types                 flt,
--                           fnd_lookup_values                flv
--                     WHERE fa.application_id           =    flt.application_id
--                       AND flt.lookup_type             =    flv.lookup_type
--                       AND fa.application_short_name   =    ct_xxcos_appl_short_name
--                       AND flv.lookup_type             =    ct_qct_customer_trx_type
--                       AND flv.lookup_code             LIKE ct_qcc_customer_trx_type1
                      FROM fnd_lookup_values                flv
                     WHERE flv.lookup_type             =    ct_qct_customer_trx_type
                       AND flv.lookup_code             LIKE ct_qcc_customer_trx_type
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
                       AND flv.meaning                 =    rctta.name
                       AND rctlgda.gl_date            >=    flv.start_date_active
                       AND rctlgda.gl_date            <=    NVL( flv.end_date_active, gd_max_date )
                       AND flv.enabled_flag            =    ct_enabled_flag_yes
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--                       AND flv.language                =    USERENV( 'LANG' )
--                       AND ROWNUM                      =    1
                       AND flv.language                =    ct_lang
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
             )
--******************************* 2009/07/17 1.7 T.Tominaga MOD START ***************************************
--      UNION ALL
--      SELECT rctlgda.gl_date                     gl_date,             --売上計上日
--             rctla.extended_amount               extended_amount      --本体金額
--        FROM ra_customer_trx_all                 rcta,                --請求取引情報テーブル
--             ra_customer_trx_lines_all           rctla,               --請求取引明細テーブル
--             ra_cust_trx_line_gl_dist_all        rctlgda,             --請求取引明細会計配分テーブル
--             ra_cust_trx_types_all               rctta                --請求取引タイプマスタ
--       WHERE rcta.ship_to_customer_id          = it_cust_account_id
--         AND rcta.customer_trx_id              = rctla.customer_trx_id
--         AND rctla.customer_trx_id             = rctlgda.customer_trx_id
--         AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
--         AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
--         AND rctla.line_type                   = ct_line_type_line
--         AND rcta.complete_flag                = ct_complete_flag_yes
--         AND rctlgda.gl_date                  >= gd_begi_month_date
--         AND rctlgda.gl_date                  <= gd_last_month_date
--         AND rcta.org_id                       = gn_org_id
--         AND rcta.org_id                       = rctta.org_id
--         AND EXISTS(SELECT cv_exists_flag_yes               exists_flag
--                      FROM fnd_application                  fa,
--                           fnd_lookup_types                 flt,
--                           fnd_lookup_values                flv
--                     WHERE fa.application_id           =    flt.application_id
--                       AND flt.lookup_type             =    flv.lookup_type
--                       AND fa.application_short_name   =    ct_xxcos_appl_short_name
--                       AND flv.lookup_type             =    ct_qct_customer_trx_type
--                       AND flv.lookup_code             LIKE ct_qcc_customer_trx_type2
--                       AND flv.meaning                 =    rctta.name
--                       AND rctlgda.gl_date            >=    flv.start_date_active
--                       AND rctlgda.gl_date            <=    NVL( flv.end_date_active, gd_max_date )
--                       AND flv.enabled_flag            =    ct_enabled_flag_yes
--                       AND flv.language                =    USERENV( 'LANG' )
--                       AND ROWNUM                      =    1
--             )
--         AND rcta.previous_customer_trx_id     IS NULL
--      UNION ALL
--      SELECT rctlgda.gl_date                     gl_date,             --売上計上日
--             rctla.extended_amount               extended_amount      --本体金額
--        FROM ra_customer_trx_all                 rcta,                --請求取引情報テーブル
--             ra_customer_trx_lines_all           rctla,               --請求取引明細テーブル
--             ra_cust_trx_line_gl_dist_all        rctlgda,             --請求取引明細会計配分テーブル
--             ra_cust_trx_types_all               rctta,               --請求取引タイプマスタ
--             ra_customer_trx_all                 rcta2,               --請求取引情報テーブル(元)
--             ra_cust_trx_types_all               rctta2               --請求取引タイプマスタ(元)
--       WHERE rcta.ship_to_customer_id          = it_cust_account_id
--         AND rcta.customer_trx_id              = rctla.customer_trx_id
--         AND rctla.customer_trx_id             = rctlgda.customer_trx_id
--         AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
--         AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
--         AND rctla.line_type                   = ct_line_type_line
--         AND rcta.complete_flag                = ct_complete_flag_yes
--         AND rctlgda.gl_date                  >= gd_begi_month_date
--         AND rctlgda.gl_date                  <= gd_last_month_date
--         AND rcta.org_id                       = gn_org_id
--         AND rcta.org_id                       = rctta.org_id
--         AND EXISTS(SELECT cv_exists_flag_yes               exists_flag
--                      FROM fnd_application                  fa,
--                           fnd_lookup_types                 flt,
--                           fnd_lookup_values                flv
--                     WHERE fa.application_id           =    flt.application_id
--                       AND flt.lookup_type             =    flv.lookup_type
--                       AND fa.application_short_name   =    ct_xxcos_appl_short_name
--                       AND flv.lookup_type             =    ct_qct_customer_trx_type
--                       AND flv.lookup_code             LIKE ct_qcc_customer_trx_type2
--                       AND flv.meaning                 =    rctta.name
--                       AND rctlgda.gl_date            >=    flv.start_date_active
--                       AND rctlgda.gl_date            <=    NVL( flv.end_date_active, gd_max_date )
--                       AND flv.enabled_flag            =    ct_enabled_flag_yes
--                       AND flv.language                =    USERENV( 'LANG' )
--                       AND ROWNUM                      =    1
--             )
--         AND rcta.previous_customer_trx_id     = rcta2.customer_trx_id
--         AND rcta2.cust_trx_type_id            = rctta2.cust_trx_type_id
--         AND rcta2.org_id                      = rctta2.org_id
--         AND EXISTS(SELECT cv_exists_flag_yes               exists_flag
--                      FROM fnd_application                  fa,
--                           fnd_lookup_types                 flt,
--                           fnd_lookup_values                flv
--                     WHERE fa.application_id           =    flt.application_id
--                       AND flt.lookup_type             =    flv.lookup_type
--                       AND fa.application_short_name   =    ct_xxcos_appl_short_name
--                       AND flv.lookup_type             =    ct_qct_customer_trx_type
--                       AND flv.lookup_code             LIKE ct_qcc_customer_trx_type1
--                       AND flv.meaning                 =    rctta2.name
--                       AND rctlgda.gl_date            >=    flv.start_date_active
--                       AND rctlgda.gl_date            <=    NVL( flv.end_date_active, gd_max_date )
--                       AND flv.enabled_flag            =    ct_enabled_flag_yes
--                       AND flv.language                =    USERENV( 'LANG' )
--                       AND ROWNUM                      =    1
--             )
--******************************* 2009/07/17 1.7 T.Tominaga MOD END   ***************************************
      ;
    -- AR取引情報 レコード型
    l_ar_rec ar_cur%ROWTYPE;
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
    lv_exists_flag            := cv_exists_flag_no;
    ln_ar_amount              := cn_amount_default;
    --
    -- ===================================================
    --1.AR取引情報
    -- ===================================================
    BEGIN
      <<ar_loop>>
      FOR ar_rec IN ar_cur
      LOOP
        --セット
        l_ar_rec                := ar_rec;
        -- 存在フラグ
        lv_exists_flag          := cv_exists_flag_yes;
        -- ===================================================
        -- A-7  売上金額集計処理
        -- ===================================================
        ln_ar_amount            := ln_ar_amount + l_ar_rec.extended_amount;
      --
      END LOOP ar_loop;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_select_err_expt;
    END;
    --
    IF ( lv_exists_flag = cv_exists_flag_no ) THEN
      ov_ar_uncalculate_type := cv_uncalculate_type_nof;
    ELSIF ( ln_ar_amount = cn_amount_default ) THEN
      ov_ar_uncalculate_type := cv_uncalculate_type_zero;
    ELSE
      ov_ar_uncalculate_type := cv_uncalculate_type_init;
    END IF;
    -- 返却
    on_sales_amount              := ln_ar_amount;
--
  EXCEPTION
    -- *** SQL SELECT エラー ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_ar_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => it_account_number
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
  END get_ar_data;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_data
   * Description      : INV月次在庫受払い表情報取得処理(A-8)
   ***********************************************************************************/
  PROCEDURE get_inv_data(
    it_tab_cust_data         IN g_rec_cust_data,                      --顧客情報
    it_shop_digestion_hdr_id IN xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE,
                                                                      --店舗別用消化計算ヘッダID
    ov_inv_uncalculate_type  OUT VARCHAR2,                            --INV未計算区分
    on_check_amount          OUT NUMBER,                              --チェック用店舗別売上金額
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_data'; -- プログラム名
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
    lv_exists_flag                      VARCHAR2(1);
    lv_branch_num                       NUMBER;                       --枝番
    ln_check_amount                     NUMBER;                       --チェック用店舗別売上金額
    lt_inventory_item_id                xxcoi_inv_reception_monthly.inventory_item_id%TYPE;
--
    -- *** ローカル・カーソル ***
    -- INV取引情報取得処理
    CURSOR inv_cur
    IS
      SELECT sirm.inv_seq                inv_seq,                     --棚卸SEQ
             sirm.inventory_item_id      inventory_item_id,           --品目ID
             sirm.organization_id        organization_id,             --在庫組織ID
             sirm.operation_cost         operation_cost,              --営業原価
             sirm.standard_cost          standard_cost,               --標準原価
             sirm.inv_wear               inv_wear,                    --販売数(棚卸減耗)
--             sirm.inv_wear * -1          inv_wear,                    --販売数(棚卸減耗)
             sirm.subinventory_code      subinventory_code            --保管場所
        FROM xxcoi_inv_reception_monthly sirm,
             mtl_secondary_inventories   msi
       --INV月次在庫受払表.保管場所      = 保管場所マスタ.保管場所
       WHERE sirm.subinventory_code = msi.secondary_inventory_name
         --保管場所マスタ.[DFF2]棚卸区分   = '2'「消化」
         AND msi.attribute5         = ct_secondary_class_2
         --保管場所マスタ.[DFF4]顧客コード = 顧客コード
         AND msi.attribute4         = it_tab_cust_data.account_number
         --保管場所マスタ.[DFF7]拠点コード = 納品拠点コード
--******************************* 2009/03/19 1.6 T.Kitajima MOD START ***************************************
--         --保管場所マスタ.[DFF7]拠点コード = 納品拠点コード
--         AND msi.attribute7         = it_tab_cust_data.delivery_base_code
--         --INV月次在庫受払表.拠点コード    = 納品拠点コード
--         AND sirm.base_code         = it_tab_cust_data.delivery_base_code
         --保管場所マスタ.[DFF7]拠点コード = 顧客アドオンマスタ.前月売上拠点コード or 売上拠点コード
         AND msi.attribute7         = it_tab_cust_data.past_sale_base_code
         --INV月次在庫受払表.拠点コード    = 顧客アドオンマスタ.前月売上拠点コード or 売上拠点コード
         AND sirm.base_code         = it_tab_cust_data.past_sale_base_code
--******************************* 2009/03/19 1.6 T.Kitajima MOD  END  ***************************************
         --INV月次在庫受払表.組織ID        = 在庫組織ID
         AND sirm.organization_id   = gt_organization_id
         --INV月次在庫受払表.年月          = 前月年月
         AND sirm.practice_month    = gv_month_date
         --INV月次在庫受払表.棚卸区分      = '2'「月末」
         AND sirm.inventory_kbn     = ct_inventory_class_2
      ;
    -- INV取引情報 レコード型
    l_inv_rec inv_cur%ROWTYPE;
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
    lv_exists_flag            := cv_exists_flag_no;
    lv_branch_num             := 1;
    ln_check_amount           := 0;
    --
    --INVデータループ
    BEGIN
      <<inv_loop>>
      FOR inv_rec IN inv_cur LOOP
        --セット
        l_inv_rec            := inv_rec;
        lv_exists_flag       := cv_exists_flag_yes;
        lt_inventory_item_id := l_inv_rec.inventory_item_id;
--
        -- ===============================
        -- A-9.品目マスタデータ取得処理
        -- ===============================
        IF ( gt_tab_item_data.COUNT = 0 ) OR
           ( gt_tab_item_data.EXISTS( lt_inventory_item_id )  = FALSE ) THEN
--
          --品目マスタから取得
          BEGIN
            SELECT itm.segment1                segment1,
                   itm.primary_unit_of_measure primary_unit_of_measure,
                   itm.fixed_price             fixed_price
              INTO gt_tab_item_data(lt_inventory_item_id)
              FROM (SELECT mib.segment1                segment1,                    --品目コード
                           mib.primary_unit_of_measure primary_unit_of_measure,     --単位コード
                           csi.fixed_price             fixed_price                  --定価
                      FROM mtl_system_items_b         mib,                          --品目マスタ
                           xxcmm_system_items_b_hst   csi                           --Disc品目変更履歴アドオン
                     --品目マスタ.品目ID               = 品目ID
                     WHERE mib.inventory_item_id      = lt_inventory_item_id
                       --品目マスタ.在庫組織ID           = 在庫組織ID
                       AND mib.organization_id        = gt_organization_id
                       --品目マスタ.品目コード           = Disc品目変更履歴アドオン.品目コード
                       AND mib.segment1               = csi.item_code
                       --Disc品目変更履歴アドオン.適用日 ≦前月終了年月日
                       AND csi.apply_date            <= gd_last_month_date
                       --Disc品目変更履歴アドオン.適用フラグ = 'Y'
                       AND csi.apply_flag             = ct_apply_flag_yes
                       --Disc品目変更履歴アドオン.定価 IS NOT NULL
                       AND csi.fixed_price            IS NOT NULL
                     ORDER BY mib.segment1,
                              csi.apply_date DESC
                   ) itm
             WHERE ROWNUM                     = 1
            ;
          EXCEPTION
            WHEN OTHERS THEN
              RAISE global_get_item_err_expt;
          END;
        END IF;
--
        -- ===============================
        -- A-10.店舗別用消化計算明細登録処理
        -- ===============================
        --店舗別用消化計算明細ID
        SELECT xxcos_shop_digestion_lns_s01.NEXTVAL
          INTO gt_tab_shop_lns(gn_line_count).shop_digestion_ln_id
          FROM DUAL
        ;
        --店舗別用消化計算ヘッダID
        gt_tab_shop_lns(gn_line_count).shop_digestion_hdr_id
                                          := it_shop_digestion_hdr_id;
        --消化計算締年月日
        gt_tab_shop_lns(gn_line_count).digestion_due_date
                                          := gd_last_month_date;
        --顧客コード
        gt_tab_shop_lns(gn_line_count).customer_number
                                          := it_tab_cust_data.account_number;
        --枝番
        gt_tab_shop_lns(gn_line_count).digestion_ln_number
                                          := lv_branch_num;
        lv_branch_num                     := lv_branch_num + 1;
        --品目コード
        gt_tab_shop_lns(gn_line_count).item_code
                                          := gt_tab_item_data(lt_inventory_item_id).segment1;
        --棚卸SEQ
        gt_tab_shop_lns(gn_line_count).invent_seq
                                          := l_inv_rec.inv_seq;
        --定価
        gt_tab_shop_lns(gn_line_count).item_price
                                          := gt_tab_item_data(lt_inventory_item_id).fixed_price;
        --品目ID
        gt_tab_shop_lns(gn_line_count).inventory_item_id
                                          := lt_inventory_item_id;
        --営業原価
        gt_tab_shop_lns(gn_line_count).business_cost
                                          := l_inv_rec.operation_cost;
        --標準原価
        gt_tab_shop_lns(gn_line_count).standard_cost
                                          := l_inv_rec.standard_cost;
        --店舗品目別販売金額
        gt_tab_shop_lns(gn_line_count).item_sales_amount
                                          := l_inv_rec.inv_wear * gt_tab_shop_lns(gn_line_count).item_price;
        --単位コード
        gt_tab_shop_lns(gn_line_count).uom_code
                                          := gt_tab_item_data(lt_inventory_item_id).primary_unit_of_measure;
        --販売数
        gt_tab_shop_lns(gn_line_count).sales_quantity
                                          := l_inv_rec.inv_wear;
        --納品拠点コード
        gt_tab_shop_lns(gn_line_count).delivery_base_code
                                          := it_tab_cust_data.delivery_base_code;
        --出荷元保管場所
        gt_tab_shop_lns(gn_line_count).ship_from_subinventory_code
                                          := l_inv_rec.subinventory_code;
        --作成者
        gt_tab_shop_lns(gn_line_count).created_by
                                          := cn_created_by;
        --作成日
        gt_tab_shop_lns(gn_line_count).creation_date
                                          := cd_creation_date;
        --最終更新者
        gt_tab_shop_lns(gn_line_count).last_updated_by
                                          := cn_last_updated_by;
        --最終更新日
        gt_tab_shop_lns(gn_line_count).last_update_date
                                          := cd_last_update_date;
        --最終更新ﾛｸﾞｲﾝ
        gt_tab_shop_lns(gn_line_count).last_update_login
                                          := cn_last_update_login;
        --要求ID
        gt_tab_shop_lns(gn_line_count).request_id
                                          := cn_request_id;
        --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        gt_tab_shop_lns(gn_line_count).program_application_id
                                          := cn_program_application_id;
        --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        gt_tab_shop_lns(gn_line_count).program_id
                                          := cn_program_id;
        --ﾌﾟﾛｸﾞﾗﾑ更新日
        gt_tab_shop_lns(gn_line_count).program_update_date
                                          := cd_program_update_date;
--
      -- ===============================
      -- A-11.チェック用売上金額集計処理
      -- ===============================
        ln_check_amount                   := ln_check_amount
                                               + TO_NUMBER( gt_tab_shop_lns(gn_line_count).item_sales_amount );
--
        --明細カウントアップ
        gn_line_count                     := gn_line_count + 1;
--
      END LOOP inv_loop;
--
    EXCEPTION
      WHEN global_get_item_err_expt THEN
        RAISE global_get_item_err_expt;
      WHEN OTHERS THEN
        RAISE global_select_err_expt;
    END;
--
    --取得できているか
    IF ( lv_exists_flag = cv_exists_flag_no ) THEN
      ov_inv_uncalculate_type := cv_uncalculate_type_nof;
    --チェック用売上合計が0か
    ELSIF ( ln_check_amount = 0 ) THEN
      ov_inv_uncalculate_type := cv_uncalculate_type_zero;
    ELSE
      ov_inv_uncalculate_type := cv_uncalculate_type_init;
    END IF;
    --チェック金額返却
    on_check_amount := ln_check_amount;
--
  EXCEPTION
    -- *** 品目マスタ取得 エラー ***
    WHEN global_get_item_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_item_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => lt_inventory_item_id
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** SQL SELECT エラー ***
    WHEN global_select_err_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => cv_msg_select_inv_err,
                                   iv_token_name1        => cv_tkn_parm_data1,
                                   iv_token_value1       => it_tab_cust_data.account_number
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
  END get_inv_data;
--
  /**********************************************************************************
   * Procedure Name   : set_header
   * Description      : 店舗別用消化計算ヘッダ登録処理(A-12)
   ***********************************************************************************/
  PROCEDURE set_header(
    it_tab_cust_data         IN g_rec_cust_data,                      --顧客情報
    it_shop_digestion_hdr_id IN xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE,
                                                                      --店舗別用消化計算ヘッダID
    iv_ar_uncalculate_type   IN VARCHAR2,                             --AR未計算区分
    iv_inv_uncalculate_type  IN VARCHAR2,                             --INV未計算区分
    in_sales_amount          IN NUMBER,                               --店舗別売上金額
    in_check_amount          IN NUMBER,                               --チェック用店舗別売上金額
    it_performance_by_code   IN xxcos_shop_digestion_hdrs.performance_by_code%TYPE,
                                                                      --営業担当員コード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_header'; -- プログラム名
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
      --店舗別用消化計算ヘッダID
      gt_tab_shop_hdrs(gn_header_count).shop_digestion_hdr_id
                                          := it_shop_digestion_hdr_id;
      --消化計算締年月日
      gt_tab_shop_hdrs(gn_header_count).digestion_due_date
                                          := gd_last_month_date;
      --顧客コード
      gt_tab_shop_hdrs(gn_header_count).customer_number
                                          := it_tab_cust_data.account_number;
      --売上拠点コード
      gt_tab_shop_hdrs(gn_header_count).sales_base_code
                                          := it_tab_cust_data.past_sale_base_code;
      --顧客ID
      gt_tab_shop_hdrs(gn_header_count).cust_account_id
                                          := it_tab_cust_data.cust_account_id;
      --消化計算実行日
      gt_tab_shop_hdrs(gn_header_count).digestion_exe_date
                                          := gd_process_date;
      --店舗別売上金額
      gt_tab_shop_hdrs(gn_header_count).ar_sales_amount
                                          := in_sales_amount;
      --チェック用売上金額
      gt_tab_shop_hdrs(gn_header_count).check_sales_amount
                                          := in_check_amount;
      --消化計算掛率
      IF ( in_sales_amount = 0 )
        OR ( in_check_amount  = 0 )
      THEN
        gt_tab_shop_hdrs(gn_header_count).digestion_calc_rate
                                          := 0;
      ELSE
        gt_tab_shop_hdrs(gn_header_count).digestion_calc_rate
                                          := ROUND( (in_sales_amount / in_check_amount) * 100, 2 );
      END IF;
      --マスタ掛率
      gt_tab_shop_hdrs(gn_header_count).master_rate
                                          := it_tab_cust_data.rate * 100;
      --差額
      gt_tab_shop_hdrs(gn_header_count).balance_amount
                                          := ROUND( in_sales_amount - ( in_check_amount * it_tab_cust_data.rate ), 0 );
      --業態小分類
      gt_tab_shop_hdrs(gn_header_count).cust_gyotai_sho
                                          := it_tab_cust_data.business_low_type;
      --成績者コード
      gt_tab_shop_hdrs(gn_header_count).performance_by_code
                                          := it_performance_by_code;
      --販売実績登録日
      gt_tab_shop_hdrs(gn_header_count).sales_result_creation_date
                                          := NULL;
      --販売実績作成済フラグ
      gt_tab_shop_hdrs(gn_header_count).sales_result_creation_flag
                                          := ct_make_flag_no;
      --前回消化計算締年月日
      gt_tab_shop_hdrs(gn_header_count).pre_digestion_due_date
                                          := gd_begi_month_date -1;
      --未計算区分
      IF ( iv_ar_uncalculate_type  = cv_uncalculate_type_nof )
        AND ( iv_inv_uncalculate_type = cv_uncalculate_type_nof )
      THEN
        gt_tab_shop_hdrs(gn_header_count).uncalculate_class
                                          := ct_uncalc_class_1;
        gn_uncalc_cnt1                    := gn_uncalc_cnt1 + 1;
      ELSIF ( ( iv_ar_uncalculate_type   = cv_uncalculate_type_nof )
        AND   ( iv_inv_uncalculate_type  != cv_uncalculate_type_nof ) )
        OR  ( ( iv_ar_uncalculate_type   = cv_uncalculate_type_zero )
        AND   ( iv_inv_uncalculate_type  = cv_uncalculate_type_init ) )
      THEN
        gt_tab_shop_hdrs(gn_header_count).uncalculate_class
                                          := ct_uncalc_class_2;
        gn_uncalc_cnt2                    := gn_uncalc_cnt2 + 1;
      ELSIF ( ( iv_ar_uncalculate_type  != cv_uncalculate_type_nof )
        AND   ( iv_inv_uncalculate_type  = cv_uncalculate_type_nof ) )
        OR  ( ( iv_ar_uncalculate_type   = cv_uncalculate_type_init )
        AND   ( iv_inv_uncalculate_type  = cv_uncalculate_type_zero ) )
      THEN
        gt_tab_shop_hdrs(gn_header_count).uncalculate_class
                                          := ct_uncalc_class_3;
        gn_uncalc_cnt3                    := gn_uncalc_cnt3 + 1;
      ELSE
        gt_tab_shop_hdrs(gn_header_count).uncalculate_class
                                          := ct_uncalc_class_0;
      END IF;
      --作成者
      gt_tab_shop_hdrs(gn_header_count).created_by
                                          := cn_created_by;
      --作成日
      gt_tab_shop_hdrs(gn_header_count).creation_date
                                          := cd_creation_date;
      --最終更新者
      gt_tab_shop_hdrs(gn_header_count).last_updated_by
                                          := cn_last_updated_by;
      --最終更新日
      gt_tab_shop_hdrs(gn_header_count).last_update_date
                                          := cd_last_update_date;
      --最終更新ﾛｸﾞｲﾝ
      gt_tab_shop_hdrs(gn_header_count).last_update_login
                                          := cn_last_update_login;
      --要求ID
      gt_tab_shop_hdrs(gn_header_count).request_id
                                          := cn_request_id;
      --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      gt_tab_shop_hdrs(gn_header_count).program_application_id
                                          := cn_program_application_id;
      --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      gt_tab_shop_hdrs(gn_header_count).program_id
                                          := cn_program_id;
      --ﾌﾟﾛｸﾞﾗﾑ更新日
      gt_tab_shop_hdrs(gn_header_count).program_update_date
                                          := cd_program_update_date;
      --ヘッダカウントアップ
      gn_header_count                     := gn_header_count + 1;
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
  END set_header;
--
  /**********************************************************************************
   * Procedure Name   : insert_lines
   * Description      : 店舗別用消化計算明細テーブル登録
   ***********************************************************************************/
  PROCEDURE insert_lines(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_lines'; -- プログラム名
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
      FORALL ln_i IN 1..gt_tab_shop_lns.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_shop_digestion_lns VALUES gt_tab_shop_lns(ln_i);
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
  END insert_lines;
--
  /**********************************************************************************
   * Procedure Name   : insert_headers
   * Description      : 店舗別用消化計算ヘッダテーブル登録
   ***********************************************************************************/
  PROCEDURE insert_headers(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_headers'; -- プログラム名
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
      FORALL ln_i IN 1..gt_tab_shop_hdrs.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_shop_digestion_hdrs VALUES gt_tab_shop_hdrs(ln_i);
      --対象件数を正常件数に
      gn_normal_cnt := SQL%ROWCOUNT;
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
  END insert_headers;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code        IN         VARCHAR2,     -- 拠点コード
    iv_customer_number  IN         VARCHAR2,     -- 顧客コード
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lt_shop_digestion_hdr_id     xxcos_shop_digestion_hdrs.shop_digestion_hdr_id%TYPE;  --  店舗別用消化計算ヘッダID
    lv_ar_uncalculate_type       VARCHAR2(1);                                           --  AR未計算区分
    lv_inv_uncalculate_type      VARCHAR2(1);                                           --  INV未計算区分
    ln_sales_amount              NUMBER;                                                --  店舗別売上金額
    ln_check_amount              NUMBER;                                                --  チェック用店舗別売上金額
    ln_index                     NUMBER;
    lt_performance_by_code       xxcos_shop_digestion_hdrs.performance_by_code%TYPE;    --  営業担当員コード
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
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_error_cnt    := 0;
    gn_warn_cnt     := 0;
    gn_cust_cnt     := 0;
    gn_ar_cnt       := 0;
    gn_inv_cnt      := 0;
    gn_uncalc_cnt1  := 0;
    gn_uncalc_cnt2  := 0;
    gn_uncalc_cnt3  := 0;
    gn_line_count   := 1;
    gn_header_count := 1;
    ln_index        := 1;
    gv_base_code    := iv_base_code;
    gv_cust_code    := iv_customer_number;
-- ************* 2009/12/16 1.8 N.Maeda ADD START ************* --
    gn_creation_count := 0;
-- ************* 2009/12/16 1.8 N.Maeda ADD  END  ************* --
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
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- A-1.パラメータチェック
    -- ===============================
    pram_chk(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- A-2.店舗別用消化計算情報の前回データ削除
    -- ===============================
    data_del_former(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    ELSE
      COMMIT;
    END IF;
--
    -- ===============================
    -- A-3.顧客マスタデータ取得処理
    -- ===============================
    get_cust_data(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- <処理部、ループ部名> (処理結果によって後続処理を制御する場合)
    -- ===============================
    <<gt_tab_cust_data_loop>>
    FOR i IN 1..gt_tab_cust_data.COUNT LOOP
-- ************* 2009/12/16 1.8 N.Maeda ADD START ************* --
      -- 販売実績未連携時のみ処理実行
      IF ( gt_tab_cust_data(i).sales_result_creation_flag != ct_make_flag_yes )
      OR ( gt_tab_cust_data(i).sales_result_creation_flag IS NULL ) THEN
-- ************* 2009/12/16 1.8 N.Maeda ADD  END  ************* --
        -- ===============================
        -- A-5.ヘッダ単位初期化処理
        -- ===============================
        init_header(
           gt_tab_cust_data(i).party_id          -- 顧客パーティID
          ,gt_tab_cust_data(i).account_number    -- 顧客コード
          ,lt_shop_digestion_hdr_id              -- 店舗別用消化計算ヘッダID
          ,lv_ar_uncalculate_type                -- AR未計算区分
          ,lv_inv_uncalculate_type               -- INV未計算区分
          ,ln_sales_amount                       -- 店舗別売上金額
          ,ln_check_amount                       -- チェック用店舗別売上金額
          ,lt_performance_by_code                -- 営業担当員コード
          ,lv_errbuf                             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                            -- リターン・コード             --# 固定 #
          ,lv_errmsg                             -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          RAISE global_common_expt;
        END IF;
--
        -- ===============================
        -- A-6.AR取引情報取得処理
        -- ===============================
        get_ar_data(
           gt_tab_cust_data(i).cust_account_id   -- 顧客ID
          ,gt_tab_cust_data(i).account_number    -- 顧客コード
          ,lv_ar_uncalculate_type                -- AR未計算区分
          ,ln_sales_amount                       -- 店舗別売上金額
          ,lv_errbuf                             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                            -- リターン・コード             --# 固定 #
          ,lv_errmsg                             -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          RAISE global_common_expt;
        ELSE
          IF ( lv_ar_uncalculate_type != cv_uncalculate_type_nof ) THEN
            gn_ar_cnt := gn_ar_cnt +1;
          END IF;
        END IF;
--
        -- ===============================
        -- A-8.INV月次在庫受払表情報取得処理
        -- ===============================
        get_inv_data(
           gt_tab_cust_data(i)                   -- 顧客情報
          ,lt_shop_digestion_hdr_id              -- 店舗別用消化計算ヘッダID
          ,lv_inv_uncalculate_type               -- INV未計算区分
          ,ln_check_amount                       -- チェック用店舗別売上金額
          ,lv_errbuf                             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                            -- リターン・コード             --# 固定 #
          ,lv_errmsg                             -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          RAISE global_common_expt;
        ELSE
          IF ( lv_inv_uncalculate_type != cv_uncalculate_type_nof ) THEN
            gn_inv_cnt := gn_inv_cnt + 1;
          END IF;
        END IF;
--
        -- ===============================
        -- A-12.店舗別用消化計算ヘッダ登録処理
        -- ===============================
        set_header(
           gt_tab_cust_data(i)                   -- 顧客情報
          ,lt_shop_digestion_hdr_id              -- 店舗別用消化計算ヘッダID
          ,lv_ar_uncalculate_type                -- AR未計算区分
          ,lv_inv_uncalculate_type               -- INV未計算区分
          ,ln_sales_amount                       -- 店舗別売上金額
          ,ln_check_amount                       -- チェック用店舗別売上金額
          ,lt_performance_by_code                -- 営業担当員コード
          ,lv_errbuf                             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                            -- リターン・コード             --# 固定 #
          ,lv_errmsg                             -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          RAISE global_common_expt;
        END IF;
--
        --削除用ヘッダID保管
        gt_tab_shop_del_hdrs(ln_index).shop_digestion_hdr_id := gt_tab_cust_data(i).shop_digestion_hdr_id;
        gt_tab_shop_del_hdrs(ln_index).customer_number       := gt_tab_cust_data(i).account_number;
        --
        ln_index                                             := ln_index + 1;
-- ************* 2009/12/16 1.8 N.Maeda ADD START ************* --
      ELSIF ( gt_tab_cust_data(i).sales_result_creation_flag = ct_make_flag_yes ) THEN
        gn_creation_count := gn_creation_count + 1;
      END IF;
-- ************* 2009/12/16 1.8 N.Maeda ADD  END  ************* --
    END LOOP gt_tab_cust_data_loop;
--
    -- ===============================
    -- A-4.店舗別用消化計算情報の今回データ削除
    -- ===============================
    data_del_now(
       lv_errbuf                             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                            -- リターン・コード             --# 固定 #
      ,lv_errmsg                             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
--
  -- ===============================
  -- 店舗別用消化計算明細テーブル登録
  -- ===============================
    insert_lines(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
      IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
--
  -- ===============================
  -- 店舗別用消化計算ヘッダテーブル登録
  -- ===============================
    insert_headers(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
      IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_common_expt;
    END IF;
--
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
    errbuf                    OUT VARCHAR2,    --   エラー・メッセージ  --# 固定 #
    retcode                   OUT VARCHAR2,    --   リターン・コード    --# 固定 #
    iv_base_code              IN  VARCHAR2,    -- 1.拠点コード
    iv_customer_number        IN  VARCHAR2     -- 2.顧客コード
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
       iv_base_code         -- 1.拠点コード
      ,iv_customer_number   -- 2.顧客コード
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
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
      --初期化
      gn_uncalc_cnt1 := 0;
      gn_uncalc_cnt2 := 0;
      gn_uncalc_cnt3 := 0;
      gn_cust_cnt    := 0;
      gn_ar_cnt      := 0;
      gn_inv_cnt     := 0;
      gn_normal_cnt  := 0;
-- ************* 2009/12/16 1.8 N.Maeda ADD START ************* --
      gn_creation_count := 0;
-- ************* 2009/12/16 1.8 N.Maeda ADD  END  ************* --
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_select_count
                    ,iv_token_name1  => cv_tkn_cnt_data1
                    ,iv_token_value1 => TO_CHAR(gn_cust_cnt)
                    ,iv_token_name2  => cv_tkn_cnt_data2
                    ,iv_token_value2 => TO_CHAR(gn_ar_cnt)
                    ,iv_token_name3  => cv_tkn_cnt_data3
                    ,iv_token_value3 => TO_CHAR(gn_inv_cnt)
-- ************* 2009/12/16 1.8 N.Maeda ADD START ************* --
                    ,iv_token_name4  => cv_tkn_cnt_data4
                    ,iv_token_value4  => TO_CHAR(gn_creation_count)
-- ************* 2009/12/16 1.8 N.Maeda ADD  END  ************* --
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
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_warn_count
                    ,iv_token_name1  => cv_tkn_cnt_data1
                    ,iv_token_value1 => TO_CHAR(gn_uncalc_cnt1)
                    ,iv_token_name2  => cv_tkn_cnt_data2
                    ,iv_token_value2 => TO_CHAR(gn_uncalc_cnt2)
                    ,iv_token_name3  => cv_tkn_cnt_data3
                    ,iv_token_value3 => TO_CHAR(gn_uncalc_cnt3)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/*
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
*/
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
END XXCOS004A01C;
/
