CREATE OR REPLACE PACKAGE BODY XXCOI003A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A12C(body)
 * Description      : HHT入出庫データ抽出
 * MD.050           : HHT入出庫データ抽出 MD050_COI_003_A12
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_hht_inv_if_data    HHT入出庫インターフェース情報の取得 (A-2)
 *  chk_hht_inv_if_data    HHT入出庫IFデータ妥当性チェック(B-3)
 *  cnv_subinv_code        HHT入出庫IFデータの保管場所コード変換(B-4)
 *  insert_hht_inv_tran    HHT入出庫IFのレコード追加(B-5)
 *  del_hht_inv_if_data    HHT入出庫IFのレコード削除(B-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/16    1.0   H.nakajima       main新規作成
 *  2009/02/18    1.1   K.Nakamura       [障害COI_011] 入出庫ジャーナル処理区分'0'の処理ステータス対応
 *  2009/04/21    1.2   H.Sasaki         [T1_0654]取込データの前後スペース削除
 *  2009/05/15    1.3   H.Sasaki         [T1_0785]データ抽出順序の変更
 *  2009/06/01    1.4   H.Sasaki         [T1_1272]入庫側コード、出庫側コード編集
 *  2010/01/29    1.5   H.Sasaki         [E_本稼動_01372]在庫会計期間チェックのエラーハンドリング変更
 *  2010/03/23    1.6   Y.Goto           [E_本稼動_01943]拠点の有効チェックを追加
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_expt                    EXCEPTION; -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(15)  := 'XXCOI003A12C'; -- パッケージ名
  cv_appl_short_name           CONSTANT VARCHAR2(10)  := 'XXCCP';        -- アドオン：共通・IF領域
  cv_application_short_name    CONSTANT VARCHAR2(10)  := 'XXCOI';        -- アプリケーション短縮名
--
  -- メッセージ
  cv_no_para_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008';     -- コンカレント入力パラメータなしメッセージ
  cv_org_code_get_err          CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';     -- 在庫組織コード取得エラーメッセージ
  cv_org_id_get_err            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';     -- 在庫組織ID取得エラーメッセージ
  cv_hht_name_get_err          CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10027';     -- HHTエラーリスト名取得エラーメッセージ
  cv_no_data_msg               CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';     -- 対象データ無しメッセージ
  cv_msg_process_date_get_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';     -- 業務日付取得エラーメッセージ
  cv_msg_lock_err              CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10170';     -- ロックエラーメッセージ(HHT入出庫IF)
  cv_msg_no_data               CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';     -- 対象データ無しメッセージ
  cv_record_type_is_null_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10172';     -- 必須項目（レコード種別）エラー
  cv_invoice_date_is_null_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10173';     -- 必須項目（伝票日付）エラー
  cv_base_code_is_null_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10174';     -- 必須項目（拠点コード）エラー
  cv_outside_code_is_null_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10175';     -- 必須項目（出庫側コード）エラー
  cv_inside_code_is_null_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10176';     -- 必須項目（入庫側コード）エラー
  cv_item_code_is_null_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10341';     -- 必須項目（品目コード）エラー
  cv_column_no_is_null_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10177';     -- 条件付必須項目（コラム№）エラー
  cv_invoice_type_is_null_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10178';     -- 条件付必須項目（伝票区分）エラー
  cv_employee_num_is_null_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10179';     -- 条件付必須項目（営業員コード）エラー
  cv_record_type_invalid_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10180';     -- 値（レコード種別）エラーメッセージ
  cv_invoice_type_invalid_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10181';     -- 値（伝票区分）エラーメッセージ
  cv_dept_flag_invalid_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10182';     -- 値（伝票区分）エラーメッセージ
  cv_hc_div_invalid_err        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10183';     -- 値（H/C）エラーメッセージ
  cv_quantity_invalid_err      CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10226';     -- 総本数換算エラー
  cv_item_code_invalid_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10227';     -- 品目存在チェックエラー
  cv_item_statu_invalid_err    CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10228';     -- 品目ステータス有効チェックエラー
  cv_sales_class_invalid_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10229';     -- 品目売上対象区分有効チェックエラー
  cv_primary_uom_notfound_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10318';     -- 基準単位存在チェックエラー
  cv_primary_uom_invalid_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10230';     -- 基準単位有効チェックエラー
  cv_msg_org_acct_period_err   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00026';     -- 在庫会計期間取得チェックエラー
  cv_invoice_date_invalid_err  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10231';     -- 在庫会計期間チェックエラー
  cv_inv_status_fix_err        CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10224';     -- 棚卸確定済チェックエラー
  cv_key_info                  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10342';     -- HHT入出庫データ用KEY情報
-- == 2010/03/23 V1.6 Added START ===============================================================
  cv_msg_get_aff_dept_date_err CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10417';     -- AFF部門取得エラー
  cv_aff_dept_inactive_err     CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10418';     -- AFF部門無効エラー
-- == 2010/03/23 V1.6 Added END   ===============================================================
--
  -- トークン
  cv_tkn_pro                   CONSTANT VARCHAR2(20)  := 'PRO_TOK';              -- プロファイル名
  cv_tkn_org_code              CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';         -- TKN：在庫組織コード
  cv_tkn_record_type           CONSTANT VARCHAR2(20)  := 'RECORD_TYPE';          -- TKN：ﾚｺｰﾄﾞ種別
  cv_tkn_invoice_type          CONSTANT VARCHAR2(20)  := 'INVOICE_TYPE';         -- TKN：伝票区分
  cv_tkn_dept_flag             CONSTANT VARCHAR2(20)  := 'DEPT_FLAG';            -- TKN：百貨店ﾌﾗｸﾞ
  cv_tkn_hc_div                CONSTANT VARCHAR2(20)  := 'HC_DIV';               -- TKN：HC区分
  cv_tkn_item_code             CONSTANT VARCHAR2(20)  := 'ITEM_CODE';            -- TKN：品目ｺｰﾄﾞ
  cv_tkn_primary_uom           CONSTANT VARCHAR2(20)  := 'PRIMARY_UOM';          -- TKN：基準単位
  cv_tkn_proc_date             CONSTANT VARCHAR2(20)  := 'INVOICE_DATE';         -- TKN：伝票日付
  cv_tkn_subinv                CONSTANT VARCHAR2(20)  := 'SUB_INV_CODE';         -- TKN：保管場所
  cv_tkn_target_date           CONSTANT VARCHAR2(20)  := 'TARGET_DATE';          -- TKN：対象日
  cv_tkn_base_code             CONSTANT VARCHAR2(20)  := 'BASE_CODE';            -- TKN：拠点ｺｰﾄﾞ
  cv_tkn_column_no             CONSTANT VARCHAR2(20)  := 'COLUMN_NO';            -- TKN：コラム№
  cv_tkn_invoice_no            CONSTANT VARCHAR2(20)  := 'INVOICE_NO';           -- TKN：伝票番号
-- == 2010/03/23 V1.6 Added START ===============================================================
  cv_tkn_slip_num              CONSTANT VARCHAR2(20)  := 'SLIP_NUM';             -- TKN：伝票番号
-- == 2010/03/23 V1.6 Added END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_hht_inv_rec IS RECORD(
     hht_rowid                 ROWID                                                   -- ROWID
    ,interface_id              xxcoi_in_hht_inv_transactions.interface_id%TYPE         -- インターフェースID
    ,base_code                 xxcoi_in_hht_inv_transactions.base_code%TYPE            -- 拠点コード
    ,record_type               xxcoi_in_hht_inv_transactions.record_type%TYPE          -- レコード種別
    ,employee_num              xxcoi_in_hht_inv_transactions.employee_num%TYPE         -- 営業員コード
    ,invoice_no                xxcoi_in_hht_inv_transactions.invoice_no%TYPE           -- 伝票№
    ,item_code                 xxcoi_in_hht_inv_transactions.item_code%TYPE            -- 品目コード（品名コード）
    ,case_quantity             xxcoi_in_hht_inv_transactions.case_quantity%TYPE        -- ケース数
    ,case_in_quantity          xxcoi_in_hht_inv_transactions.case_in_quantity%TYPE     -- 入数
    ,quantity                  xxcoi_in_hht_inv_transactions.quantity%TYPE             -- 本数
    ,invoice_type              xxcoi_in_hht_inv_transactions.invoice_type%TYPE         -- 伝票区分
    ,base_delivery_flag        xxcoi_in_hht_inv_transactions.base_delivery_flag%TYPE   -- 拠点間倉替フラグ
    ,outside_code              xxcoi_in_hht_inv_transactions.outside_code%TYPE         -- 出庫側コード
    ,inside_code               xxcoi_in_hht_inv_transactions.inside_code%TYPE          -- 入庫側コード
    ,invoice_date              xxcoi_in_hht_inv_transactions.invoice_date%TYPE         -- 伝票日付
    ,column_no                 xxcoi_in_hht_inv_transactions.column_no%TYPE            -- コラム№
    ,unit_price                xxcoi_in_hht_inv_transactions.unit_price%TYPE           -- 単価
    ,hot_cold_div              xxcoi_in_hht_inv_transactions.hot_cold_div%TYPE         -- H/C
    ,department_flag           xxcoi_in_hht_inv_transactions.department_flag%TYPE      -- 百貨店フラグ
    ,other_base_code           xxcoi_in_hht_inv_transactions.other_base_code%TYPE      -- 他拠点コード
    ,interface_date            xxcoi_in_hht_inv_transactions.interface_date%TYPE       -- 受信日時
  );
  --
  TYPE g_hht_inv_rec_type IS TABLE OF g_hht_inv_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_org_id                    mtl_parameters.organization_id%TYPE;                             -- 在庫組織ID
  gt_item_id                   mtl_system_items_b.inventory_item_id%TYPE;                       -- 品目ID
  gt_primary_uom_code          mtl_system_items_b.primary_uom_code%TYPE;                        -- 基準単位コード
  gt_primary_uom               mtl_system_items_b.primary_unit_of_measure%TYPE;                 -- 基準単位
  gd_process_date              DATE;                                                            -- 業務日付
  gt_file_name                 fnd_profile_option_values.profile_option_value%TYPE;             -- HHTエラーリストファイル名
  gt_outside_subinv_code       xxcoi_hht_inv_transactions.outside_subinv_code%TYPE;             -- 出庫側保管場所
  gt_inside_subinv_code        xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;              -- 入庫側保管場所
  gt_outside_base_code         xxcoi_hht_inv_transactions.outside_base_code%TYPE;               -- 出庫側拠点
  gt_inside_base_code          xxcoi_hht_inv_transactions.inside_base_code%TYPE;                -- 入庫側拠点
  gn_total_quantity            NUMBER;                                                          -- 総本数
  gt_outside_subinv_code_conv  xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE;    -- 出庫側保管場所変換区分
  gt_inside_subinv_code_conv   xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;     -- 入庫側保管場所変換区分
  gt_outside_business_low_type xxcoi_hht_inv_transactions.outside_business_low_type%TYPE;       -- 出庫側顧客小分類
  gt_inside_business_low_type  xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;        -- 入庫側顧客小分類
  gt_outside_cust_code         xxcoi_hht_inv_transactions.outside_cust_code%TYPE;               -- 出庫側顧客
  gt_inside_cust_code          xxcoi_hht_inv_transactions.inside_cust_code%TYPE;                -- 入庫側顧客
  gt_hht_program_div           xxcoi_hht_inv_transactions.hht_program_div%TYPE;                 -- HHTプログラム処理区分
  gt_item_convert_div          xxcoi_hht_inv_transactions.item_convert_div%TYPE;                -- 商品振替区分
  gt_stock_uncheck_list_div    xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;          -- 入庫未確認リスト対象区分
  gt_stock_balance_list_div    xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;          -- 入庫差異確認リスト対象区分
  gt_consume_vd_flag           xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;                 -- 消化VD補充対象ﾌﾗｸﾞ
  -- PL/SQL表
  g_hht_inv_if_tab             g_hht_inv_rec_type;                                      -- HHT入出庫一時表格納用
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT  nocopy VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT  nocopy VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT  nocopy VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_prf_org_code                       CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
    cv_prf_file_name                      CONSTANT VARCHAR2(30) := 'XXCOI1_HHT_ERR_DATA_NAME';
--
    -- *** ローカル変数 ***
    lt_org_code                       mtl_parameters.organization_code%TYPE;               -- 在庫組織コード
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
    -- コンカレント入力パラメータなしログ出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => cv_no_para_msg
                  );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- ===============================
    -- プロファイル取得：在庫組織コード
    -- ===============================
    lt_org_code := fnd_profile.value( cv_prf_org_code );
    -- プロファイルが取得できない場合
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_code_get_err
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 
    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'lt_org_code = '||lt_org_code);
--
    -- ===============================
    -- 在庫組織ID取得
    -- ===============================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_code );
    -- 共通関数のリターンコードがNULLの場合
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_id_get_err
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 
    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'gt_org_id = '||gt_org_id);
--
    -- ===============================
    -- プロファイル取得：HHTエラーリスト名
    -- ===============================
    gt_file_name := fnd_profile.value( cv_prf_file_name );
    -- プロファイルが取得できない場合
    IF ( gt_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_hht_name_get_err
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_file_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 
    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'gt_file_name = '||gt_file_name);
    -- ==============================================================
    -- 業務日付取得
    -- ==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_process_date_get_err
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 
    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'gd_process_date = '||gd_process_date);
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
  /**********************************************************************************
   * Procedure Name   : get_hht_inv_if_data
   * Description      : HHT入出庫インターフェース情報の取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_hht_inv_if_data(
      ov_errbuf    OUT nocopy VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT nocopy VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg    OUT nocopy VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hht_inv_if_data'; -- プログラム名
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
    -- 顧客移項情報取得
    CURSOR hht_inv_if_cur
    IS
-- == 2009/06/01 V1.4 Modified START ===============================================================
---- == 2009/04/21 V1.2 Modified START ===============================================================
--      SELECT 
----             ROWID                          AS hht_rowid                -- ROWID
----            ,xihit.interface_id             AS interface_id             -- インターフェースID
----            ,xihit.base_code                AS base_code                -- 拠点コード
----            ,xihit.record_type              AS record_type              -- レコード種別
----            ,xihit.employee_num             AS employee_num             -- 営業員コード
----            ,xihit.invoice_no               AS invoice_no               -- 伝票№
----            ,xihit.item_code                AS item_code                -- 品目コード（品名コード）
----            ,xihit.case_quantity            AS case_quantity            -- ケース数
----            ,xihit.case_in_quantity         AS case_in_quantity         -- 入数
----            ,xihit.quantity                 AS quantity                 -- 本数
----            ,xihit.invoice_type             AS invoice_type             -- 伝票区分
----            ,xihit.base_delivery_flag       AS base_delivery_flag       -- 拠点間倉替フラグ
----            ,xihit.outside_code             AS outside_code             -- 出庫側コード
----            ,xihit.inside_code              AS inside_code              -- 入庫側コード
----            ,xihit.invoice_date             AS invoice_date             -- 伝票日付
----            ,xihit.column_no                AS column_no                -- コラム№
----            ,xihit.unit_price               AS unit_price               -- 単価
----            ,xihit.hot_cold_div             AS hot_cold_div             -- h/c
----            ,xihit.department_flag          AS department_flag          -- 百貨店フラグ
----            ,xihit.other_base_code          AS other_base_code          -- 他拠点コード
----            ,xihit.interface_date           AS interface_date           -- 受信日時
----
--             ROWID                          AS hht_rowid                -- ROWID
--            ,xihit.interface_id             AS interface_id             -- インターフェースID
--            ,TRIM(xihit.base_code)          AS base_code                -- 拠点コード
--            ,TRIM(xihit.record_type)        AS record_type              -- レコード種別
--            ,TRIM(xihit.employee_num)       AS employee_num             -- 営業員コード
--            ,TRIM(xihit.invoice_no)         AS invoice_no               -- 伝票№
--            ,TRIM(xihit.item_code)          AS item_code                -- 品目コード（品名コード）
--            ,xihit.case_quantity            AS case_quantity            -- ケース数
--            ,xihit.case_in_quantity         AS case_in_quantity         -- 入数
--            ,xihit.quantity                 AS quantity                 -- 本数
--            ,TRIM(xihit.invoice_type)       AS invoice_type             -- 伝票区分
--            ,TRIM(xihit.base_delivery_flag) AS base_delivery_flag       -- 拠点間倉替フラグ
--            ,TRIM(xihit.outside_code)       AS outside_code             -- 出庫側コード
--            ,TRIM(xihit.inside_code)        AS inside_code              -- 入庫側コード
--            ,xihit.invoice_date             AS invoice_date             -- 伝票日付
--            ,TRIM(xihit.column_no)          AS column_no                -- コラム№
--            ,xihit.unit_price               AS unit_price               -- 単価
--            ,TRIM(xihit.hot_cold_div)       AS hot_cold_div             -- h/c
--            ,TRIM(xihit.department_flag)    AS department_flag          -- 百貨店フラグ
--            ,TRIM(xihit.other_base_code)    AS other_base_code          -- 他拠点コード
--            ,xihit.interface_date           AS interface_date           -- 受信日時
---- == 2009/04/21 V1.2 Modified END   ===============================================================
--      FROM   xxcoi_in_hht_inv_transactions xihit                        -- HHT入出庫情報IF
--      WHERE  TRUNC( NVL(xihit.invoice_date , gd_process_date ) ) <= TRUNC( gd_process_date )
---- == 2009/05/15 V1.3 Modified START ===============================================================
----      ORDER BY
----             xihit.base_code
----            ,xihit.record_type
----            ,xihit.invoice_type
----            ,xihit.department_flag
----            ,xihit.invoice_no
----            ,xihit.column_no
----            ,xihit.item_code
--      ORDER BY
--             xihit.interface_id
-- == 2009/05/15 V1.3 Modified END   ===============================================================
      SELECT
             ROWID                          AS hht_rowid                -- ROWID
            ,xihit.interface_id             AS interface_id             -- インターフェースID
            ,TRIM(xihit.base_code)          AS base_code                -- 拠点コード
            ,TRIM(xihit.record_type)        AS record_type              -- レコード種別
            ,TRIM(xihit.employee_num)       AS employee_num             -- 営業員コード
            ,TRIM(xihit.invoice_no)         AS invoice_no               -- 伝票№
            ,TRIM(xihit.item_code)          AS item_code                -- 品目コード（品名コード）
            ,xihit.case_quantity            AS case_quantity            -- ケース数
            ,xihit.case_in_quantity         AS case_in_quantity         -- 入数
            ,xihit.quantity                 AS quantity                 -- 本数
            ,TRIM(xihit.invoice_type)       AS invoice_type             -- 伝票区分
            ,TRIM(xihit.base_delivery_flag) AS base_delivery_flag       -- 拠点間倉替フラグ
            ,CASE   TRIM(xihit.record_type)
                WHEN  '20'  THEN          SUBSTRB(TRIM(xihit.outside_code), -5, 5)
                WHEN  '30'  THEN
                  CASE  TRIM(xihit.invoice_type)
                    WHEN  '1'  THEN       SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                    WHEN  '2'  THEN       SUBSTRB(TRIM(xihit.outside_code), -5, 5)
                    WHEN  '3'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '7'  THEN   TRIM(xihit.outside_code)
                        WHEN  '8'  THEN   TRIM(xihit.outside_code)
                        ELSE              SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                      END
                    WHEN  '4'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '4'  THEN   TRIM(xihit.outside_code)
                        WHEN  '5'  THEN   SUBSTRB(TRIM(xihit.outside_code), -4, 4)
                        ELSE              SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                      END
                    WHEN  '6'  THEN       SUBSTRB(TRIM(xihit.outside_code), -5, 5)
                    WHEN  '9'  THEN       SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                    ELSE                  TRIM(xihit.outside_code)
                  END
                WHEN  '40'  THEN
                  CASE  TRIM(xihit.invoice_type)
                    WHEN  '0'  THEN       SUBSTRB(TRIM(xihit.outside_code), -5, 5)
                    WHEN  '1'  THEN       SUBSTRB(TRIM(xihit.outside_code), -2, 2)
                    ELSE                  TRIM(xihit.outside_code)
                  END
                ELSE                      TRIM(xihit.outside_code)
             END                            AS outside_code             -- 出庫側コード
            ,CASE   TRIM(xihit.record_type)
                WHEN  '30'  THEN
                  CASE  TRIM(xihit.invoice_type)
                    WHEN  '1'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '7'  THEN   SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                        WHEN  '8'  THEN   SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                        ELSE              SUBSTRB(TRIM(xihit.inside_code), -5, 5)
                      END
                    WHEN  '2'  THEN       SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                    WHEN  '3'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '7'  THEN   TRIM(xihit.inside_code)
                        WHEN  '8'  THEN   TRIM(xihit.inside_code)
                        ELSE              SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                      END
                    WHEN  '4'  THEN       TRIM(xihit.inside_code)
                    WHEN  '5'  THEN
                      CASE  TRIM(xihit.department_flag)
                        WHEN  '3'  THEN   TRIM(xihit.inside_code)
                        WHEN  '6'  THEN   SUBSTRB(TRIM(xihit.inside_code), -4, 4)
                        ELSE              SUBSTRB(TRIM(xihit.inside_code), -2, 2)
                      END
                    WHEN  '6'  THEN       TRIM(xihit.inside_code)
                    WHEN  '7'  THEN       SUBSTRB(TRIM(xihit.inside_code), -5, 5)
                    WHEN  '9'  THEN       SUBSTRB(TRIM(xihit.inside_code), -4, 4)
                    ELSE                  TRIM(xihit.inside_code)
                  END
                ELSE                      TRIM(xihit.inside_code)
             END                            AS inside_code              -- 入庫側コード
            ,xihit.invoice_date             AS invoice_date             -- 伝票日付
            ,TRIM(xihit.column_no)          AS column_no                -- コラム№
            ,xihit.unit_price               AS unit_price               -- 単価
            ,TRIM(xihit.hot_cold_div)       AS hot_cold_div             -- h/c
            ,TRIM(xihit.department_flag)    AS department_flag          -- 百貨店フラグ
            ,TRIM(xihit.other_base_code)    AS other_base_code          -- 他拠点コード
            ,xihit.interface_date           AS interface_date           -- 受信日時
      FROM   xxcoi_in_hht_inv_transactions xihit                        -- HHT入出庫情報IF
      WHERE  TRUNC( NVL(xihit.invoice_date , gd_process_date ) ) <= TRUNC( gd_process_date )
      ORDER BY
             xihit.interface_id
-- == 2009/06/01 V1.4 Modified END   ===============================================================
      FOR UPDATE NOWAIT;
--
    no_data_expt    EXCEPTION;                                          -- 対象データなし
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN hht_inv_if_cur;
    --
    FETCH hht_inv_if_cur BULK COLLECT INTO g_hht_inv_if_tab;
    -- 処理対象件数取得
    gn_target_cnt := g_hht_inv_if_tab.COUNT;
    -- カーソルクローズ
    CLOSE hht_inv_if_cur;
    -- 処理対象件数0件判定
    IF ( gn_target_cnt = 0 ) THEN
        RAISE no_data_expt;
    END IF;
--
  EXCEPTION
--
    -- *** ロックエラーハンドラ ***
    WHEN lock_expt THEN
      -- カーソルがOPENしている場合
      IF ( hht_inv_if_cur%ISOPEN ) THEN
        CLOSE hht_inv_if_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_msg_lock_err
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      -- ステータスをエラーにする
      ov_retcode := cv_status_error;
    --
    -- *** 対象データなしハンドラ ***
    WHEN no_data_expt THEN
      gv_out_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_msg_no_data
                     );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => gv_out_msg
      );
      -- ステータスを正常にする
      ov_retcode := cv_status_normal;
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
  END get_hht_inv_if_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_hht_inv_if_data
   * Description      : HHT入出庫IFデータ妥当性チェック(B-3)
   ***********************************************************************************/
  PROCEDURE chk_hht_inv_if_data(
    in_work_count IN         NUMBER,       --   TABLE(INDEX)
    ov_errbuf     OUT nocopy VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT nocopy VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_hht_inv_if_data'; -- プログラム名
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
    cv_record_type_vd       CONSTANT VARCHAR2(2) := '20';                           -- レコード種別：VD初回
    cv_record_type_inv      CONSTANT VARCHAR2(2) := '30';                           -- レコード種別：入出庫
    cv_record_type_sample   CONSTANT VARCHAR2(2) := '40';                           -- レコード種別：見本
    cv_lookup_record_type   CONSTANT VARCHAR2(23) := 'XXCOI1_HHT_INV_DATA_DIV';     -- LOOKUP_TYPE：レコード種別
    cv_lookup_invoice_type  CONSTANT VARCHAR2(23) := 'XXCOI1_INVOICE_TYPE';         -- LOOKUP_TYPE：伝票区分
    cv_lookup_dept_flag     CONSTANT VARCHAR2(23) := 'XXCOI1_DEPARTMENT_FLAG';      -- LOOKUP_TYPE：百貨店ﾌﾗｸﾞ
    cv_lookup_hc_div        CONSTANT VARCHAR2(23) := 'XXCOI1_HOT_COLD_DIV';         -- LOOKUP_TYPE：H/C
    cv_sales_classs_target  CONSTANT VARCHAR2(1)  := '1';                           -- 売上対象区分：対象
    cv_item_status_opm      CONSTANT VARCHAR2(10) := 'OPM';                         -- ステータス：OPM
    cv_item_status_active   CONSTANT VARCHAR2(10) := 'Active';                      -- ステータス：Active
    cv_flg_y                CONSTANT VARCHAR2(1)  := 'Y';                           -- ﾌﾗｸﾞ値：Y
    --
    -- *** ローカル変数 ***
    --
    lt_lookup_meaning       fnd_lookup_values.meaning%TYPE;                         -- ﾚｺｰﾄﾞ種別格納変数
    lt_item_status          mtl_system_items_b.inventory_item_status_code%TYPE;     -- 品目ｽﾃｰﾀｽ
    lt_cust_order_flg       mtl_system_items_b.customer_order_enabled_flag%TYPE;    -- 顧客受注可能ﾌﾗｸﾞ
    lt_transaction_enable   mtl_system_items_b.mtl_transactions_enabled_flag%TYPE;  -- 取引可能ﾌﾗｸﾞ
    lt_stock_enabled_flg    mtl_system_items_b.stock_enabled_flag%TYPE;             -- 在庫保有可能ﾌﾗｸﾞ
    lt_return_enable        mtl_system_items_b.returnable_flag%TYPE;                -- 返品可能ﾌﾗｸﾞ
    lt_sales_class          ic_item_mst_b.attribute26%TYPE;                         -- 売上対象区分
    lt_disable_date         mtl_units_of_measure_tl.disable_date%TYPE;              -- 単位失効日
    lb_org_acct_period_flg  BOOLEAN;                                                -- 当月在庫会計期間オープンフラグ
    lv_key_info             VARCHAR2(5000);                                         -- HHT入出庫データ用KEY情報
    --
    -- *** ローカル・例外 ***
    not_null_expt           EXCEPTION;                                              -- 必須項目例外
    invalid_value_expt      EXCEPTION;                                              -- 不正値例外
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
    -- -------------------------------
    -- 1.必須項目チェック
    -- -------------------------------
    -- (1).レコード種別
    IF ( g_hht_inv_if_tab( in_work_count ).record_type IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_record_type_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (2).伝票日付
    ELSIF ( g_hht_inv_if_tab( in_work_count ).invoice_date IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_invoice_date_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (3).拠点コード
    ELSIF ( g_hht_inv_if_tab( in_work_count ).base_code IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_base_code_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (4).出庫側コード
    ELSIF ( g_hht_inv_if_tab( in_work_count ).outside_code IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_outside_code_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (5).入庫側コード
    ELSIF ( g_hht_inv_if_tab( in_work_count ).inside_code IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_inside_code_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    -- (6).品目コード
    ELSIF ( g_hht_inv_if_tab( in_work_count ).item_code IS NULL ) THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_item_code_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    END IF;
    -- -------------------------------
    -- 2.条件付必須項目チェック
    -- -------------------------------
    -- (1).コラム№
    IF g_hht_inv_if_tab( in_work_count ).record_type = cv_record_type_vd
    AND  g_hht_inv_if_tab( in_work_count ).column_no IS NULL THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_column_no_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    END IF;
    -- (2).伝票区分
    IF g_hht_inv_if_tab( in_work_count ).record_type IN( cv_record_type_inv , cv_record_type_sample)
    AND  g_hht_inv_if_tab( in_work_count ).invoice_type IS NULL THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_invoice_type_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    END IF;
    -- (3).営業員ｺｰﾄﾞ
    IF g_hht_inv_if_tab( in_work_count ).record_type = cv_record_type_sample
    AND  g_hht_inv_if_tab( in_work_count ).employee_num IS NULL THEN
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_employee_num_is_null_err
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE not_null_expt;
        --
    END IF;
    -- -------------------------------
    -- 3.レコード種別の値範囲チェック
    -- -------------------------------
    -- ﾚｺｰﾄﾞ種別のLOOKUPを取得
    lt_lookup_meaning := xxcoi_common_pkg.get_meaning( 
                                          iv_lookup_type => cv_lookup_record_type
                                        , iv_lookup_code => g_hht_inv_if_tab( in_work_count ).record_type 
                                     );
    -- 共通関数のリターンコードがNULLの場合
    IF ( lt_lookup_meaning IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_record_type_invalid_err
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).record_type
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
    -- -------------------------------
    -- 4.伝票区分の値範囲チェック
    -- -------------------------------
    IF g_hht_inv_if_tab( in_work_count ).invoice_type IS NOT NULL THEN
        -- 伝票区分のLOOKUPを取得
        lt_lookup_meaning := xxcoi_common_pkg.get_meaning( 
                                              iv_lookup_type => cv_lookup_invoice_type
                                            , iv_lookup_code => g_hht_inv_if_tab( in_work_count ).invoice_type 
                                         );
        -- 共通関数のリターンコードがNULLの場合
        IF ( lt_lookup_meaning IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_type_invalid_err
                     , iv_token_name1  => cv_tkn_invoice_type
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).invoice_type
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
        --
    END IF;
    -- -------------------------------
    -- 5.百貨店フラグの値範囲チェック
    -- -------------------------------
    IF g_hht_inv_if_tab( in_work_count ).department_flag IS NOT NULL THEN
        -- 百貨店フラグのLOOKUPを取得
        lt_lookup_meaning := xxcoi_common_pkg.get_meaning( 
                                              iv_lookup_type => cv_lookup_dept_flag
                                            , iv_lookup_code => g_hht_inv_if_tab( in_work_count ).department_flag 
                                         );
        -- 共通関数のリターンコードがNULLの場合
        IF ( lt_lookup_meaning IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_dept_flag_invalid_err
                     , iv_token_name1  => cv_tkn_dept_flag
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).department_flag
                   );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
        --
    END IF;
    -- -------------------------------
    -- 6.H/Cの値範囲チェック
    -- -------------------------------
    IF g_hht_inv_if_tab( in_work_count ).hot_cold_div IS NOT NULL THEN
        -- H/CのLOOKUPを取得
        lt_lookup_meaning := xxcoi_common_pkg.get_meaning( 
                                              iv_lookup_type => cv_lookup_hc_div
                                            , iv_lookup_code => g_hht_inv_if_tab( in_work_count ).hot_cold_div );
        -- 共通関数のリターンコードがNULLの場合
        IF ( lt_lookup_meaning IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_hc_div_invalid_err
                     , iv_token_name1  => cv_tkn_hc_div
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).hot_cold_div
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
        --
    END IF;
    -- -------------------------------
    -- 7.取引数量の０チェック
    -- -------------------------------
    -- 総本数の算出
    gn_total_quantity := ( NVL( g_hht_inv_if_tab( in_work_count ).case_quantity ,0 )
                             * NVL( g_hht_inv_if_tab( in_work_count ).case_in_quantity,0 ) ) 
                                 + NVL( g_hht_inv_if_tab( in_work_count ).quantity,0 ) ;
    -- 取引を作成しないVD初回は除く（単価、H/C更新のみ）
    IF g_hht_inv_if_tab( in_work_count ).record_type != cv_record_type_vd THEN
        -- 総本数0判定
        IF gn_total_quantity = 0 THEN
        --
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_quantity_invalid_err
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        --
        END IF;
    --
    END IF;
    -- -------------------------------
    -- 8.品目の妥当性チェック
    -- -------------------------------
    IF g_hht_inv_if_tab( in_work_count ).item_code IS NOT NULL THEN
        --
        xxcoi_common_pkg.get_item_info2(
            iv_item_code          => g_hht_inv_if_tab( in_work_count ).item_code    -- 1.品目コード
          , in_org_id             => gt_org_id                                      -- 2.在庫組織ID
          , ov_item_status        => lt_item_status                                 -- 3.品目ステータス
          , ov_cust_order_flg     => lt_cust_order_flg                              -- 4.顧客受注可能フラグ
          , ov_transaction_enable => lt_transaction_enable                          -- 5.取引可能
          , ov_stock_enabled_flg  => lt_stock_enabled_flg                           -- 6.在庫保有可能フラグ
          , ov_return_enable      => lt_return_enable                               -- 7.返品可能
          , ov_sales_class        => lt_sales_class                                 -- 8.売上対象区分
          , ov_primary_unit       => gt_primary_uom                                 -- 9.基準単位
          , on_inventory_item_id  => gt_item_id                                     --10.品目ID
          , ov_primary_uom_code   => gt_primary_uom_code                            --11.基準単位コード
          , ov_errbuf             => lv_errbuf                                      --11.エラー・メッセージ
          , ov_retcode            => lv_retcode                                     --12.リターン・コード
          , ov_errmsg             => lv_errmsg                                      --13.ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_item_code_invalid_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).item_code
                  );
          RAISE invalid_value_expt;
        END IF;
        -- 品目ステータスのチェック
        -- 有効でない場合
        IF ( NOT( lt_item_status IN( cv_item_status_opm , cv_item_status_active )
                  AND  lt_cust_order_flg     = cv_flg_y
                  AND  lt_transaction_enable = cv_flg_y
                  AND  lt_stock_enabled_flg  = cv_flg_y
                  AND  lt_return_enable      = cv_flg_y  ) )
        THEN
        --
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_item_statu_invalid_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).item_code
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        --
        END IF;
        -- 売上対象区分のチェック
        -- NULL または 対象で無い場合
        IF ( ( lt_sales_class IS NULL ) OR ( lt_sales_class <> cv_sales_classs_target ) ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_sales_class_invalid_err
                     , iv_token_name1  => cv_tkn_item_code
                     , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).item_code
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
    --
    -- -------------------------------
    -- 9.基準単位の妥当性チェック
    -- -------------------------------
        -- 基準単位の無効日取得
        xxcoi_common_pkg.get_uom_disable_info(
            iv_unit_code          => gt_primary_uom_code   -- 1.基準単位
          , od_disable_date       => lt_disable_date       -- 2.無効日
          , ov_errbuf             => lv_errbuf             -- 3.エラー・メッセージ
          , ov_retcode            => lv_retcode            -- 4.リターン・コード
          , ov_errmsg             => lv_errmsg             -- 5.ユーザー・エラー・メッセージ
        );
        -- 存在チェック
        -- 無効日が取得できなかった場合
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_primary_uom_notfound_err
                     , iv_token_name1  => cv_tkn_primary_uom
                     , iv_token_value1 => gt_primary_uom_code
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
        -- 有効チェック
        -- 有効でない場合
        IF ( TRUNC( NVL( lt_disable_date, SYSDATE + 1 ) ) <= TRUNC( SYSDATE ) ) THEN 
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_primary_uom_invalid_err
                     , iv_token_name1  => cv_tkn_primary_uom
                     , iv_token_value1 => gt_primary_uom_code
                  );
          lv_errbuf := lv_errmsg;
          RAISE invalid_value_expt;
        END IF;
    --
    END IF;
    -- -------------------------------
    -- 10.在庫会計期間チェック
    -- -------------------------------
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                         -- 在庫組織ID
      , id_target_date     => g_hht_inv_if_tab( in_work_count ).invoice_date    -- 伝票日付
      , ob_chk_result      => lb_org_acct_period_flg                            -- チェック結果
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    -- 在庫会計期間ステータスの取得に失敗した場合
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_org_acct_period_err
                     , iv_token_name1  => cv_tkn_target_date
                     , iv_token_value1 => TO_CHAR( g_hht_inv_if_tab( in_work_count ).invoice_date ,'yyyymmdd' )
                   );
-- == 2010/01/29 V1.5 Modified START ===============================================================
--      RAISE global_api_expt;
      RAISE invalid_value_expt;
-- == 2010/01/29 V1.5 Modified END   ===============================================================
    END IF;
    -- 当月在庫会計期間がクローズの場合
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_invoice_date_invalid_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( g_hht_inv_if_tab( in_work_count ).invoice_date ,'yyyymmdd' )
                   );
      lv_errbuf := lv_errmsg;
      RAISE invalid_value_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 必須項目例外ハンドラ ***
    WHEN not_null_expt THEN
        -- KEY情報出力
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => g_hht_inv_if_tab( in_work_count ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => g_hht_inv_if_tab( in_work_count ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => g_hht_inv_if_tab( in_work_count ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => g_hht_inv_if_tab( in_work_count ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => g_hht_inv_if_tab( in_work_count ).item_code
                     );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_key_info || lv_errmsg );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_key_info || lv_errbuf );
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
    --
    -- *** 不正値例外ハンドラ ***
    WHEN invalid_value_expt THEN
        -- KEY情報出力
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => g_hht_inv_if_tab( in_work_count ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => g_hht_inv_if_tab( in_work_count ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => g_hht_inv_if_tab( in_work_count ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => g_hht_inv_if_tab( in_work_count ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => g_hht_inv_if_tab( in_work_count ).item_code
                     );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_key_info || lv_errmsg );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_key_info || lv_errbuf );
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
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
  END chk_hht_inv_if_data;
--
  /**********************************************************************************
   * Procedure Name   : cnv_subinv_code
   * Description      : HHT入出庫IFデータの保管場所コード変換(B-4)
   ***********************************************************************************/
  PROCEDURE cnv_subinv_code(
    in_work_count IN         NUMBER,       --   TABLE(INDEX)
    ov_errbuf     OUT nocopy VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT nocopy VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cnv_subinv_code'; -- プログラム名
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
    cv_subinv_div_other         CONSTANT VARCHAR2(1) := '9';                                -- 棚卸対象：9（対象外）
    cv_date_format_yyyymm       CONSTANT VARCHAR2(6) := 'yyyymm';                           -- 日付書式（年月）
    ct_inventory_status_fix     CONSTANT xxcoi_inv_control.inventory_status%TYPE := '9';    -- 棚卸ステータス：確定済
    ct_inventory_kbn_month      CONSTANT xxcoi_inv_control.inventory_status%TYPE := '2';    -- 棚卸区分：月末
    --
    -- *** ローカル変数 ***
    --
    lt_outside_subinv_div       mtl_secondary_inventories.attribute1%TYPE;                  -- 出庫側保管場所区分
    lt_inside_subinv_div        mtl_secondary_inventories.attribute1%TYPE;                  -- 入庫側保管場所区分
    ln_work_count               NUMBER;                                                     -- 棚卸確定済件数
    lv_key_info                 VARCHAR2(5000);                                             -- HHT入出庫データ用KEY情報
-- == 2010/03/23 V1.6 Added START ===============================================================
    lt_start_date_active    fnd_flex_values.start_date_active%TYPE;                         -- AFF部門適用開始日
-- == 2010/03/23 V1.6 Added END   ===============================================================
    --
    -- *** ローカル・例外 ***
    cnv_subinv_expt             EXCEPTION;                                                  -- 保管場所変換例外
    inv_status_fix_expt         EXCEPTION;                                                  -- 棚卸確定済例外
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
    -- -------------------------------
    -- 1.保管場所コード変換
    -- -------------------------------
    xxcoi_common_pkg.convert_subinv_code(
         ov_errbuf                      => lv_errbuf                                            -- 1.エラーメッセージ
        ,ov_retcode                     => lv_retcode                                           -- 2.リターン・コード(1:正常、2:エラー)
        ,ov_errmsg                      => lv_errmsg                                            -- 3.ユーザー・エラーメッセージ
        ,iv_record_type                 => g_hht_inv_if_tab( in_work_count ).record_type        -- 4.レコード種別
        ,iv_invoice_type                => g_hht_inv_if_tab( in_work_count ).invoice_type       -- 5.伝票区分
        ,iv_department_flag             => g_hht_inv_if_tab( in_work_count ).department_flag    -- 6.百貨店フラグ
        ,iv_base_code                   => g_hht_inv_if_tab( in_work_count ).base_code          -- 7.拠点コード
        ,iv_outside_code                => g_hht_inv_if_tab( in_work_count ).outside_code       -- 8.出庫側コード
        ,iv_inside_code                 => g_hht_inv_if_tab( in_work_count ).inside_code        -- 9.入庫側コード
        ,id_transaction_date            => g_hht_inv_if_tab( in_work_count ).invoice_date       -- 10.取引日
        ,in_organization_id             => gt_org_id                                            -- 11.在庫組織ID
        ,iv_hht_form_flag               => NULL                                                 -- 12.HHT取引入力画面フラグ
        ,ov_outside_subinv_code         => gt_outside_subinv_code                               -- 13.出庫側保管場所コード
        ,ov_inside_subinv_code          => gt_inside_subinv_code                                -- 14.入庫側保管場所コード
        ,ov_outside_base_code           => gt_outside_base_code                                 -- 15.出庫側拠点コード
        ,ov_inside_base_code            => gt_inside_base_code                                  -- 16.入庫側拠点コード
        ,ov_outside_subinv_code_conv    => gt_outside_subinv_code_conv                          -- 17.出庫側保管場所変換区分
        ,ov_inside_subinv_code_conv     => gt_inside_subinv_code_conv                           -- 18.入庫側保管場所変換区分
        ,ov_outside_business_low_type   => gt_outside_business_low_type                         -- 19.出庫側業態小分類
        ,ov_inside_business_low_type    => gt_inside_business_low_type                          -- 20.入庫側業態小分類
        ,ov_outside_cust_code           => gt_outside_cust_code                                 -- 21.出庫側顧客コード
        ,ov_inside_cust_code            => gt_inside_cust_code                                  -- 22.入庫側顧客コード
        ,ov_hht_program_div             => gt_hht_program_div                                   -- 23.入出庫ジャーナル処理区分
        ,ov_item_convert_div            => gt_item_convert_div                                  -- 24.商品振替区分
        ,ov_stock_uncheck_list_div      => gt_stock_uncheck_list_div                            -- 25.入庫未確認リスト対象区分
        ,ov_stock_balance_list_div      => gt_stock_balance_list_div                            -- 26.入庫差異確認リスト対象区分
        ,ov_consume_vd_flag             => gt_consume_vd_flag                                   -- 27.消化VD補充対象フラグ
        ,ov_outside_subinv_div          => lt_outside_subinv_div                                -- 28.出庫側棚卸対象
        ,ov_inside_subinv_div           => lt_inside_subinv_div                                 -- 29.入庫側棚卸対象
      );
    --
    IF ( lv_retcode != cv_status_normal ) THEN
        RAISE cnv_subinv_expt;
    END IF;
    -- -------------------------------
    -- 2.保管場所の棚卸ｽﾃｰﾀｽﾁｪｯｸ
    -- -------------------------------
    -- 出庫側保管場所
    IF lt_outside_subinv_div <> cv_subinv_div_other THEN
        --
        SELECT 
                count(1)                -- 1.棚卸確定済件数
        INTO
                ln_work_count           -- 1.棚卸確定済件数
        FROM    
                xxcoi_inv_control xic
        WHERE   
                xic.subinventory_code    = gt_outside_subinv_code
        AND     xic.inventory_year_month = TO_CHAR(g_hht_inv_if_tab( in_work_count ).invoice_date,cv_date_format_yyyymm)
        AND     xic.inventory_kbn        = ct_inventory_kbn_month
        AND     xic.inventory_status     = ct_inventory_status_fix
        AND     ROWNUM                   = 1;
        --
        IF ln_work_count = 1 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application_short_name
                           , iv_name         => cv_inv_status_fix_err
                           , iv_token_name1  => cv_tkn_subinv
                           , iv_token_value1 => gt_outside_subinv_code
                         );
            --
            lv_errbuf := lv_errmsg;
            RAISE inv_status_fix_expt;
        END IF;
        --
    END IF;
    -- 入庫側保管場所
    IF gt_inside_subinv_code IS NOT NULL
        AND lt_inside_subinv_div <> cv_subinv_div_other THEN
        --
        SELECT 
                count(1)                -- 1.棚卸確定済件数
        INTO
                ln_work_count           -- 1.棚卸確定済件数
        FROM    
                xxcoi_inv_control xic
        WHERE   
                xic.subinventory_code    = gt_inside_subinv_code
        AND     xic.inventory_year_month = TO_CHAR(g_hht_inv_if_tab( in_work_count ).invoice_date,cv_date_format_yyyymm)
        AND     xic.inventory_kbn        = ct_inventory_kbn_month
        AND     xic.inventory_status     = ct_inventory_status_fix
        AND     ROWNUM                   = 1;
        --
        IF ln_work_count = 1 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application_short_name
                           , iv_name         => cv_inv_status_fix_err
                           , iv_token_name1  => cv_tkn_subinv
                           , iv_token_value1 => gt_inside_subinv_code
                         );
            --
            lv_errbuf := lv_errmsg;
            RAISE inv_status_fix_expt;
        END IF;
        --
    END IF;
--
-- == 2010/03/23 V1.6 Added START ===============================================================
    -- -------------------------------
    -- 3.AFF部門有効チェック
    -- -------------------------------
    -- 出庫側保管場所
    xxcoi_common_pkg.get_subinv_aff_active_date(
        in_organization_id     => gt_org_id                                         -- 在庫組織ID
      , iv_subinv_code         => gt_outside_subinv_code                            -- 保管場所コード
      , od_start_date_active   => lt_start_date_active                              -- 適用開始日
      , ov_errbuf              => lv_errbuf
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg
    );
    -- 適用開始日の取得に失敗した場合
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_get_aff_dept_date_err
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_outside_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).invoice_no
                   );
      RAISE cnv_subinv_expt;
    END IF;
    -- 伝票日付がAFF部門適用開始日以前の場合
    IF ( g_hht_inv_if_tab( in_work_count ).invoice_date < NVL( lt_start_date_active
                                                             , g_hht_inv_if_tab( in_work_count ).invoice_date ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_aff_dept_inactive_err
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_outside_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).invoice_no
                   );
      lv_errbuf := lv_errmsg;
      RAISE cnv_subinv_expt;
    END IF;
    -- 入庫側保管場所
    xxcoi_common_pkg.get_subinv_aff_active_date(
        in_organization_id     => gt_org_id                                         -- 在庫組織ID
      , iv_subinv_code         => gt_inside_subinv_code                             -- 保管場所コード
      , od_start_date_active   => lt_start_date_active                              -- 適用開始日
      , ov_errbuf              => lv_errbuf
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg
    );
    -- 適用開始日の取得に失敗した場合
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_msg_get_aff_dept_date_err
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_inside_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).invoice_no
                   );
      RAISE cnv_subinv_expt;
    END IF;
    -- 伝票日付がAFF部門適用開始日以前の場合
    IF ( g_hht_inv_if_tab( in_work_count ).invoice_date < NVL( lt_start_date_active
                                                             , g_hht_inv_if_tab( in_work_count ).invoice_date ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_aff_dept_inactive_err
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => gt_inside_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).invoice_no
                   );
      lv_errbuf := lv_errmsg;
      RAISE cnv_subinv_expt;
    END IF;
--
-- == 2010/03/23 V1.6 Added END   ===============================================================
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--  保管場所変換例外
    WHEN cnv_subinv_expt THEN
        -- KEY情報出力
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => g_hht_inv_if_tab( in_work_count ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => g_hht_inv_if_tab( in_work_count ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => g_hht_inv_if_tab( in_work_count ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => g_hht_inv_if_tab( in_work_count ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => g_hht_inv_if_tab( in_work_count ).item_code
                     );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_key_info || lv_errmsg );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_key_info || lv_errbuf );
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
--  棚卸確定済例外
    WHEN inv_status_fix_expt THEN
        -- KEY情報出力
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application_short_name
                       , iv_name         => cv_key_info
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => g_hht_inv_if_tab( in_work_count ).base_code
                       , iv_token_name2  => cv_tkn_record_type
                       , iv_token_value2 => g_hht_inv_if_tab( in_work_count ).record_type
                       , iv_token_name3  => cv_tkn_invoice_type
                       , iv_token_value3 => g_hht_inv_if_tab( in_work_count ).invoice_type
                       , iv_token_name4  => cv_tkn_dept_flag
                       , iv_token_value4 => g_hht_inv_if_tab( in_work_count ).department_flag
                       , iv_token_name5  => cv_tkn_invoice_no
                       , iv_token_value5 => g_hht_inv_if_tab( in_work_count ).invoice_no
                       , iv_token_name6  => cv_tkn_column_no
                       , iv_token_value6 => g_hht_inv_if_tab( in_work_count ).column_no
                       , iv_token_name7  => cv_tkn_item_code
                       , iv_token_value7 => g_hht_inv_if_tab( in_work_count ).item_code
                     );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_key_info || lv_errmsg );
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_key_info || lv_errbuf );
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
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
  END cnv_subinv_code;
--
  /**********************************************************************************
   * Procedure Name   : insert_hht_inv_tran
   * Description      : HHT入出庫IFのレコード追加(B-5)
   ***********************************************************************************/
  PROCEDURE insert_hht_inv_tran(
    in_work_count IN         NUMBER,       --   TABLE(INDEX)
    ov_errbuf     OUT nocopy VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT nocopy VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'insert_hht_inv_tran';  -- プログラム名
    cv_record_type_20 CONSTANT VARCHAR2(2)   := '20';                   -- レコード種別：VD初回
    cv_dummy          CONSTANT VARCHAR2(2)   := '99';                   -- 伝票区分：ダミー
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
    cv_hht_program_div_0     CONSTANT VARCHAR2(1) := '0'; -- 入出庫ジャーナル処理区分：処理対象外
    cv_hht_inv_tran_status_0 CONSTANT VARCHAR2(1) := '0'; -- 処理ステータス：未処理
    cv_hht_inv_tran_status_1 CONSTANT VARCHAR2(1) := '1'; -- 処理ステータス：処理済
    cv_hht_inv_if_status     CONSTANT VARCHAR2(1) := 'N';
    --
    -- *** ローカル変数 ***
    --
    -- *** ローカル・例外 ***
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- -------------------------------
    -- 1.HHT入出庫一時表への登録
    -- -------------------------------
    INSERT INTO XXCOI_HHT_INV_TRANSACTIONS(
         transaction_id                                         -- 1.入出庫一時表ID
        ,interface_id                                           -- 2.インターフェースID
        ,form_header_id                                         -- 3.画面入力用ヘッダID
        ,base_code                                              -- 4.拠点コード
        ,record_type                                            -- 5.レコード種別
        ,employee_num                                           -- 6.営業員コード
        ,invoice_no                                             -- 7.伝票№
        ,item_code                                              -- 8.品目コード（品名コード）
        ,case_quantity                                          -- 9.ケース数
        ,case_in_quantity                                       -- 10.入数
        ,quantity                                               -- 11.本数
        ,invoice_type                                           -- 12.伝票区分
        ,base_delivery_flag                                     -- 13.拠点間倉替フラグ
        ,outside_code                                           -- 14.出庫側コード
        ,inside_code                                            -- 15.入庫側コード
        ,invoice_date                                           -- 16.伝票日付
        ,column_no                                              -- 17.コラム№
        ,unit_price                                             -- 18.単価
        ,hot_cold_div                                           -- 19.H/C
        ,department_flag                                        -- 20.百貨店フラグ
        ,interface_date                                         -- 21.受信日時
        ,other_base_code                                        -- 22.他拠点コード
        ,outside_subinv_code                                    -- 23.出庫側保管場所
        ,inside_subinv_code                                     -- 24.入庫側保管場所
        ,outside_base_code                                      -- 25.出庫側拠点
        ,inside_base_code                                       -- 26.入庫側拠点
        ,total_quantity                                         -- 27.総本数
        ,inventory_item_id                                      -- 28.品目ID
        ,primary_uom_code                                       -- 29.基準単位
        ,outside_subinv_code_conv_div                           -- 30.出庫側保管場所変換区分
        ,inside_subinv_code_conv_div                            -- 31.入庫側保管場所変換区分
        ,outside_business_low_type                              -- 32.出庫側業態区分
        ,inside_business_low_type                               -- 33.入庫側業態区分
        ,outside_cust_code                                      -- 34.出庫側顧客コード
        ,inside_cust_code                                       -- 35.入庫側顧客コード
        ,hht_program_div                                        -- 36.入出庫ジャーナル処理区分
        ,consume_vd_flag                                        -- 37.消化VD補充対象フラグ
        ,item_convert_div                                       -- 38.商品振替区分
        ,stock_uncheck_list_div                                 -- 39.入庫未確認リスト対象区分
        ,stock_balance_list_div                                 -- 40.入庫差異確認リスト対象区分
        ,status                                                 -- 41.処理ステータス
        ,column_if_flag                                         -- 42.コラム別転送済フラグ
        ,column_if_date                                         -- 43.コラム別転送日
        ,sample_if_flag                                         -- 44.見本転送済フラグ
        ,sample_if_date                                         -- 45.見本転送日
        ,output_flag                                            -- 46.出力済フラグ
        ,last_update_date                                       -- 47.最終更新日
        ,last_updated_by                                        -- 48.最終更新者
        ,creation_date                                          -- 49.作成日
        ,created_by                                             -- 50.作成者
        ,last_update_login                                      -- 51.最終更新ユーザ
        ,request_id                                             -- 52.要求ID
        ,program_application_id                                 -- 53.プログラムアプリケーションID
        ,program_id                                             -- 54.プログラムID
        ,program_update_date                                    -- 55.プログラム更新日
    )
    VALUES(
         xxcoi_hht_inv_transactions_s01.NEXTVAL                  -- 1.入出庫一時表ID
        ,g_hht_inv_if_tab( in_work_count ).interface_id          -- 2.インターフェースID
        ,NULL                                                    -- 3.画面入力用ヘッダID
        ,g_hht_inv_if_tab( in_work_count ).base_code             -- 4.拠点コード
        ,g_hht_inv_if_tab( in_work_count ).record_type           -- 5.レコード種別
        ,g_hht_inv_if_tab( in_work_count ).employee_num          -- 6.営業員コード
        ,g_hht_inv_if_tab( in_work_count ).invoice_no            -- 7.伝票№
        ,g_hht_inv_if_tab( in_work_count ).item_code             -- 8.品目コード（品名コード）
        ,g_hht_inv_if_tab( in_work_count ).case_quantity         -- 9.ケース数
        ,g_hht_inv_if_tab( in_work_count ).case_in_quantity      -- 10.入数
        ,g_hht_inv_if_tab( in_work_count ).quantity              -- 11.本数
        ,DECODE( g_hht_inv_if_tab( in_work_count ).record_type
                 ,cv_record_type_20,cv_dummy, g_hht_inv_if_tab( in_work_count ).invoice_type )         -- 12.伝票区分
        ,g_hht_inv_if_tab( in_work_count ).base_delivery_flag    -- 13.拠点間倉替フラグ
        ,g_hht_inv_if_tab( in_work_count ).outside_code          -- 14.出庫側コード
        ,g_hht_inv_if_tab( in_work_count ).inside_code           -- 15.入庫側コード
        ,g_hht_inv_if_tab( in_work_count ).invoice_date          -- 16.伝票日付
        ,g_hht_inv_if_tab( in_work_count ).column_no             -- 17.コラム№
        ,g_hht_inv_if_tab( in_work_count ).unit_price            -- 18.単価
        ,g_hht_inv_if_tab( in_work_count ).hot_cold_div          -- 19.H/C
        ,g_hht_inv_if_tab( in_work_count ).department_flag       -- 20.百貨店フラグ
        ,g_hht_inv_if_tab( in_work_count ).interface_date        -- 21.受信日時
        ,g_hht_inv_if_tab( in_work_count ).other_base_code       -- 22.他拠点コード
        ,gt_outside_subinv_code                                  -- 23.出庫側保管場所
        ,gt_inside_subinv_code                                   -- 24.入庫側保管場所
        ,gt_outside_base_code                                    -- 25.出庫側拠点
        ,gt_inside_base_code                                     -- 26.入庫側拠点
        ,gn_total_quantity                                       -- 27.総本数
        ,gt_item_id                                              -- 28.品目ID
        ,gt_primary_uom_code                                     -- 29.基準単位
        ,gt_outside_subinv_code_conv                             -- 30.出庫側保管場所変換区分
        ,gt_inside_subinv_code_conv                              -- 31.入庫側保管場所変換区分
        ,gt_outside_business_low_type                            -- 32.出庫側業態区分
        ,gt_inside_business_low_type                             -- 33.入庫側業態区分
        ,gt_outside_cust_code                                    -- 34.出庫側顧客コード
        ,gt_inside_cust_code                                     -- 35.入庫側顧客コード
        ,gt_hht_program_div                                      -- 36.入出庫ジャーナル処理区分
        ,gt_consume_vd_flag                                      -- 37.消化VD補充対象フラグ
        ,gt_item_convert_div                                     -- 38.商品振替区分
        ,gt_stock_uncheck_list_div                               -- 39.入庫未確認リスト対象区分
        ,gt_stock_balance_list_div                               -- 40.入庫差異確認リスト対象区分
        ,DECODE( gt_hht_program_div
                 ,cv_hht_program_div_0 ,cv_hht_inv_tran_status_1
                 ,cv_hht_inv_tran_status_0 )                     -- 41.処理ステータス
        ,cv_hht_inv_if_status                                    -- 42.コラム別転送済フラグ
        ,NULL                                                    -- 43.コラム別転送日
        ,cv_hht_inv_if_status                                    -- 44.見本転送済フラグ
        ,NULL                                                    -- 45.見本転送日
        ,cv_hht_inv_if_status                                    -- 46.出力済フラグ
        ,SYSDATE                                                 -- 47.最終更新日
        ,cn_last_updated_by                                      -- 48.最終更新者
        ,SYSDATE                                                 -- 49.作成日
        ,cn_created_by                                           -- 50.作成者
        ,cn_last_update_login                                    -- 51.最終更新ユーザ
        ,cn_request_id                                           -- 52.要求ID
        ,cn_program_application_id                               -- 53.プログラムアプリケーションID
        ,cn_program_id                                           -- 54.プログラムID
        ,cd_program_update_date                                  -- 55.プログラム更新日
    );
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
  END insert_hht_inv_tran;
--
  /**********************************************************************************
   * Procedure Name   : del_hht_inv_if_data
   * Description      : HHT入出庫IFのレコード削除(B-7)
   ***********************************************************************************/
  PROCEDURE del_hht_inv_if_data(
    in_work_count IN         NUMBER,       --   TABLE(INDEX)
    ov_errbuf     OUT nocopy VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT nocopy VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_hht_inv_if_data'; -- プログラム名
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
    -- *** ローカル・例外 ***
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- -------------------------------
    -- 1.HHT入出庫IFの削除
    -- -------------------------------
    DELETE 
    FROM xxcoi_in_hht_inv_transactions xihit    
    WHERE xihit.ROWID = g_hht_inv_if_tab( in_work_count ).hht_rowid;
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
  END del_hht_inv_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT nocopy VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT nocopy VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT nocopy VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_work_count    NUMBER := 0;                       -- LOOP件数
    lv_work_status   VARCHAR2(1) := cv_status_normal;   -- 制御用ステータス
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
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
    -- ===========================================
    -- 初期処理 (B-1)
    -- ===========================================
    init(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
    --
        -- エラー件数のカウントアップ
        gn_error_cnt := gn_error_cnt + 1;
        -- Initのエラーは処理中断
        RAISE global_process_expt;
    --
    END IF;
--
    -- ===========================================
    -- HHT入出庫IFデータ抽出 (B-2)
    -- ===========================================
    get_hht_inv_if_data(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 0件の場合は正常
    IF ( lv_retcode = cv_status_error ) THEN
    --
        -- エラー件数のカウントアップ
        gn_error_cnt := gn_error_cnt + 1;
        -- ロック、またはOTHERS例外のため処理中断
        RAISE global_process_expt;
    --
    END IF;
    --
    <<hht_inv_if_loop>>
    FOR ln_work_count IN 1..gn_target_cnt LOOP
    -- 警告ステータスリセット
    lv_work_status := cv_status_normal;
    -- ===========================================
    -- HHT入出庫IFデータ妥当性チェック (B-3)
    -- ===========================================
        chk_hht_inv_if_data(
            ln_work_count        -- TABLE(INDEX)
          , lv_errbuf            -- エラー・メッセージ           --# 固定 #
          , lv_retcode           -- リターン・コード             --# 固定 #
          , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 警告
        IF ( lv_retcode = cv_status_warn ) THEN
        --
            -- エラー件数のカウントアップ
            gn_error_cnt := gn_error_cnt + 1;
            -- 警告ステータスセット
            lv_work_status := cv_status_warn;
        -- 異常
        ELSIF ( lv_retcode = cv_status_error ) THEN
        --
            -- エラー件数のカウントアップ
            gn_error_cnt := gn_error_cnt + 1;
            -- OTHERS例外のため処理中断
            RAISE global_process_expt;
    -- ===========================================
    -- HHT入出庫IFデータの保管場所コード変換 (B-4)
    -- ===========================================
        -- 正常
        ELSE
        --
            cnv_subinv_code(
                ln_work_count        -- TABLE(INDEX)
              , lv_errbuf            -- エラー・メッセージ           --# 固定 #
              , lv_retcode           -- リターン・コード             --# 固定 #
              , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
            );
            --
            IF ( lv_retcode = cv_status_warn ) THEN
            --
                -- エラー件数のカウントアップ
                gn_error_cnt := gn_error_cnt + 1;
                -- 警告ステータスセット
                lv_work_status := cv_status_warn;
            --
            ELSIF ( lv_retcode = cv_status_error ) THEN
            --
                -- エラー件数のカウントアップ
                gn_error_cnt := gn_error_cnt + 1;
                -- OTHERS例外のため処理中断
                RAISE global_process_expt;
            --
            END IF;
        --
        END IF;
        --
    -- ===========================================
    -- HHT入出庫IFデータの HHT入出庫一時表の追加 (B-5)
    -- ===========================================
        IF lv_work_status = cv_status_normal THEN
            insert_hht_inv_tran(
                    ln_work_count        -- TABLE(INDEX)
                  , lv_errbuf            -- エラー・メッセージ           --# 固定 #
                  , lv_retcode           -- リターン・コード             --# 固定 #
                  , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
                );
             --
             IF ( lv_retcode != cv_status_normal ) THEN
             -- エラー件数のカウントアップ
                gn_error_cnt := gn_error_cnt + 1;
             -- OTHERS例外のため処理中断
                RAISE global_process_expt;
             END IF;
        --
    -- ===========================================
    --  HHT入出庫IFデータのHHTエラーリスト表追加(B-6)
    -- ===========================================
        ELSE
            -- 
            xxcoi_common_pkg.add_hht_err_list_data(
                 ov_errbuf              => lv_errbuf                                        -- エラー・メッセージ           --# 固定 #
                ,ov_retcode             => lv_retcode                                       -- リターン・コード             --# 固定 #
                ,ov_errmsg              => lv_errmsg                                        -- ユーザー・エラー・メッセージ --# 固定 #
                ,iv_base_code           => g_hht_inv_if_tab( ln_work_count ).base_code      -- 1.拠点コード
                ,iv_origin_shipment     => g_hht_inv_if_tab( ln_work_count ).outside_code   -- 2.出庫側コード
                ,iv_data_name           => gt_file_name                                     -- 3.ファイル名（入出庫データ）
                ,id_transaction_date    => g_hht_inv_if_tab( ln_work_count ).invoice_date   -- 4.伝票日付
                ,iv_entry_number        => g_hht_inv_if_tab( ln_work_count ).invoice_no     -- 5.伝票№
                ,iv_party_num           => g_hht_inv_if_tab( ln_work_count ).inside_code    -- 6.入庫側コード
                ,iv_performance_by_code => g_hht_inv_if_tab( ln_work_count ).employee_num   -- 7.営業員コード
                ,iv_item_code           => g_hht_inv_if_tab( ln_work_count ).item_code      -- 8.品目コード
                ,iv_error_message       => lv_errmsg                                        -- 9.エラー内容
            );
            --
            IF ( lv_retcode != cv_status_normal ) THEN
            --
                -- エラー件数のカウントアップ
                gn_error_cnt := gn_error_cnt + 1;
                -- OTHERS例外のため処理中断
                RAISE global_process_expt;
            --
            END IF;
            --
        END IF;
        --
    -- ===========================================
    --  HHT入出庫IFのレコード削除(B-7)
    -- ===========================================
        del_hht_inv_if_data(
                ln_work_count        -- TABLE(INDEX)
              , lv_errbuf            -- エラー・メッセージ           --# 固定 #
              , lv_retcode           -- リターン・コード             --# 固定 #
              , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
            );
             --
        IF ( lv_retcode != cv_status_normal ) THEN
        --
            -- エラー件数のカウントアップ
            gn_error_cnt := gn_error_cnt + 1;
            -- OTHERS例外のため処理中断
            RAISE global_process_expt;
        --
        END IF;
    --
    END LOOP hht_inv_if_loop;
    -- ===========================================
    --  終了処理(B-8)
    -- ===========================================
    -- 正常処理件数の設定
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt - gn_error_cnt;
    -- 警告ステータス設定
    IF gn_error_cnt > 0 THEN
        ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf        OUT nocopy VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT nocopy  VARCHAR2       --   リターン・コード    --# 固定 #
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
END XXCOI003A12C;
/
