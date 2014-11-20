CREATE OR REPLACE PACKAGE BODY XXCOK003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK003A01C(body)
 * Description      : 移行顧客の基準在庫を元に旧拠点から新拠点への保管場所転送情報を作成。
 * MD.050           : VD在庫保管場所転送情報の作成 MD050_COK_003_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_cust_shift_info    顧客移行情報の取得 (A-2)
 *  chk_transfer_cust      転送対象チェック (A-4)
 *  get_vd_inv_info        VD在庫保管場所転送情報取得 (A-5)
 *  chk_item_info          項目チェック (A-6)
 *  ins_mtl_txn_oif        資材取引OIF登録 (A-7)
 *  upd_status             顧客移行情報更新 (A-8)
 *  submain                メイン処理プロシージャ
 *                         セーブポイント設定 (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理 (A-9)
 *                         
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20    1.0   T.Kojima        新規作成
 *  2009/02/20    1.1   T.Kojima        [障害COK_051] 業態小分類 コード値修正
 *  2009/12/10    1.2   S.Moriyama      [E_本稼動_00405] VDコラムマスタ前月、当月判定時に空きコラム考慮を追加
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
  gn_normal_cnt    NUMBER;                    -- 成功件数
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
  lock_expt                         EXCEPTION;  -- ロック取得エラー
  item_chk_expt                     EXCEPTION;  -- 項目チェックエラー(品目チェック)
  primary_uom_chk_expt              EXCEPTION;  -- 項目チェックエラー(基準単位チェック)
  sec_inv_expt                      EXCEPTION;  -- 保管場所チェックエラー
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100) := 'XXCOK003A01C';          -- パッケージ名
  cv_appl_short_name_xxccp       CONSTANT VARCHAR2(10)  := 'XXCCP';                 -- アドオン：共通・IF領域
  cv_appl_short_name_xxcok       CONSTANT VARCHAR2(10)  := 'XXCOK';                 -- アドオン：個別開発領域
  cv_appl_short_name_xxcoi       CONSTANT VARCHAR2(10)  := 'XXCOI';                 -- アドオン：在庫領域
  cv_prm_job                     CONSTANT VARCHAR2(1)   := '1';                     -- 通常起動(夜間バッチ)
  cv_prm_recovery                CONSTANT VARCHAR2(1)   := '2';                     -- リカバリ起動
  cv_trnsfr_status_prev          CONSTANT VARCHAR2(1)   := '0';                     -- 未転送
  cv_trnsfr_status_trnsfr        CONSTANT VARCHAR2(1)   := '1';                     -- 転送済
  cv_trnsfr_status_reserve       CONSTANT VARCHAR2(1)   := '2';                     -- 保留
  cv_trnsfr_status_out           CONSTANT VARCHAR2(1)   := '3';                     -- 対象外
  cv_trnsfr_status_error         CONSTANT VARCHAR2(1)   := 'E';                     -- エラー判定用
--
  -- メッセージ
  cv_msg_prm                     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00076';      -- コンカレント入力パラメータメッセージ
  cv_msg_no_prm                  CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00077';      -- 入力パラメータ未設定エラー（起動区分）
  cv_msg_org_code_get_err        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005';      -- 在庫組織コード取得エラーメッセージ
  cv_msg_org_id_get_err          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006';      -- 在庫組織ID取得エラーメッセージ
  cv_msg_process_date_get_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011';      -- 業務日付取得エラーメッセージ
  cv_msg_oprtn_date_get_err      CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00078';      -- システム稼働日取得エラーメッセージ
  cv_msg_org_acct_period_get_err CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00026';      -- 在庫会計期間ステータス取得エラーメッセージ
  cv_msg_org_acct_period_err     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00043';      -- 在庫会計期間エラーメッセージ
  cv_msg_tran_type_name_get_err  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00022';      -- 取引タイプ名取得エラーメッセージ
  cv_msg_tran_type_id_get_err    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00012';      -- 取引タイプID取得エラーメッセージ
  cv_msg_no_data                 CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00001';      -- 対象データ無しメッセージ
  cv_msg_sec_inv_chk_err         CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10356';      -- 保管場所チェックエラーメッセージ
  cv_msg_item_status_chk_err     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10358';      -- 品目ステータス有効チェックエラーメッセージ
  cv_msg_sales_class_chk_err     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10359';      -- 品目売上対象区分有効チェックエラーメッセージ
  cv_msg_primary_uom_not_found   CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10360';      -- 基準単位存在チェックエラーメッセージ
  cv_msg_primary_uom_disable     CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10361';      -- 基準単位有効チェックエラーメッセージ
  cv_msg_lock_err                CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10384';      -- ロックエラーメッセージ(顧客移行情報) 
  cv_msg_unit_cust               CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00038';      -- 顧客単位件数メッセージ
  cv_msg_unit_column_no          CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00037';      -- コラムNo.単位件数メッセージ
  cv_msg_out_rec                 CONSTANT VARCHAR2(100) := 'APP-XXCOK1-10387';      -- 保管場所転送情報作成対象外件数メッセージ
--
  -- トークン
  cv_tkn_pro                     CONSTANT VARCHAR2(25)  := 'PRO_TOK';               -- プロファイル名
  cv_tkn_org_code                CONSTANT VARCHAR2(25)  := 'ORG_CODE_TOK';          -- 在庫組織コード
  cv_tkn_lookup_type             CONSTANT VARCHAR2(25)  := 'LOOKUP_TYPE';           -- 参照タイプ
  cv_tkn_lookup_code             CONSTANT VARCHAR2(25)  := 'LOOKUP_CODE';           -- 参照コード
  cv_tkn_tran_type               CONSTANT VARCHAR2(25)  := 'TRANSACTION_TYPE_TOK';  -- 取引タイプ名
  cv_tkn_base_code               CONSTANT VARCHAR2(25)  := 'BASE_CODE';             -- 拠点コード
  cv_tkn_item_code               CONSTANT VARCHAR2(25)  := 'ITEM_CODE';             -- 品目コード
  cv_tkn_cust_code               CONSTANT VARCHAR2(25)  := 'CUSTOMER_CODE';         -- 顧客コード
  cv_tkn_column_no               CONSTANT VARCHAR2(25)  := 'COLUMN_NO';             -- コラムNo.
  cv_tkn_sub_inv_code            CONSTANT VARCHAR2(25)  := 'SUBINVENTORY_CODE';     -- 保管場所コード
  cv_tkn_trnsfr_sub_inv          CONSTANT VARCHAR2(25)  := 'TRANSFER_SUBINVENTORY'; -- 移動先保管場所コード
  cv_tkn_qty                     CONSTANT VARCHAR2(25)  := 'QUANTITY';              -- 数量
  cv_tkn_primary_uom             CONSTANT VARCHAR2(25)  := 'PRIMARY_UOM';           -- 基準単位
  cv_tkn_proc_date               CONSTANT VARCHAR2(25)  := 'PROC_DATE';             -- 処理日
  cv_tkn_target_date             CONSTANT VARCHAR2(25)  := 'TARGET_DATE';           -- 対象日
  cv_tkn_process_flag            CONSTANT VARCHAR2(25)  := 'PROCESS_FLAG';          -- 起動区分
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 顧客移行情報格納用
  TYPE g_cust_shift_info_rtype IS RECORD(
      hca_cust_account_id         hz_cust_accounts.cust_account_id%TYPE                    -- 1.顧客ID
    , xcsi_cust_shift_id          xxcok_cust_shift_info.cust_shift_id%TYPE                 -- 2.顧客移行情報ID
    , xcsi_cust_code              xxcok_cust_shift_info.cust_code%TYPE                     -- 3.顧客コード
    , xcsi_prev_base_code         xxcok_cust_shift_info.prev_base_code%TYPE                -- 4.旧担当拠点コード
    , xcsi_new_base_code          xxcok_cust_shift_info.new_base_code%TYPE                 -- 5.新担当拠点コード
    , xcsi_cust_shift_date        xxcok_cust_shift_info.cust_shift_date%TYPE               -- 6.顧客移行日
    , xcsi_vd_inv_trnsfr_status   xxcok_cust_shift_info.vd_inv_trnsfr_status%TYPE          -- 7.VD在庫保管場所転送ステータス
    , msi_sec_inv_code_out        mtl_secondary_inventories.secondary_inventory_name%TYPE  -- 8.出庫側保管場所コード
    , msi_sec_inv_code_in         mtl_secondary_inventories.secondary_inventory_name%TYPE  -- 9.入庫側保管場所コード
  );
  TYPE g_cust_shift_info_ttype IS TABLE OF g_cust_shift_info_rtype INDEX BY BINARY_INTEGER;

  -- VD在庫保管場所転送情報納用
  TYPE g_vd_inv_trnsfr_info_rtype IS RECORD(
      xmvc_column_no              xxcoi_mst_vd_column.column_no%TYPE                       --  1.コラムNo
    , xmvc_item_id                xxcoi_mst_vd_column.item_id%TYPE                         --  2.品目ID
    , msib_item_code              mtl_system_items_b.segment1%TYPE                         --  3.品目コード
    , xmvc_inv_qty                xxcoi_mst_vd_column.inventory_quantity%TYPE              --  4.基準在庫数
    , msib_primary_uom            mtl_system_items_b.primary_uom_code%TYPE                 --  5.基準単位
    , msib_item_status            mtl_system_items_b.inventory_item_status_code%TYPE       --  6.品目ステータス
    , msib_cust_order_flg         mtl_system_items_b.customer_order_enabled_flag%TYPE      --  7.顧客受注可能フラグ
    , msib_transaction_enable     mtl_system_items_b.mtl_transactions_enabled_flag%TYPE    --  8.取引可能
    , msib_stock_enabled_flg      mtl_system_items_b.stock_enabled_flag%TYPE               --  9.在庫保有可能フラグ
    , msib_return_enable          mtl_system_items_b.returnable_flag%TYPE                  -- 10.返品可能
    , iimb_sales_class            ic_item_mst_b.attribute26%TYPE                           -- 11.売上対象区分
  );
  TYPE g_vd_inv_trnsfr_info_ttype IS TABLE OF g_vd_inv_trnsfr_info_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_out_cnt                 NUMBER;                                          -- 保管場所転送情報作成対象外件数
  gn_target_column_no_cnt    NUMBER;                                          -- 対象件数(コラムNo.単位総数)
  gn_normal_column_no_cnt    NUMBER;                                          -- 成功件数(コラムNo.単位総数)
  gn_error_column_no_cnt     NUMBER;                                          -- エラー件数(コラムNo.単位総数)
  gt_org_id                  mtl_parameters.organization_id%TYPE;             -- 在庫組織ID
  gt_tran_type_id            mtl_transaction_types.transaction_type_id%TYPE;  -- 取引タイプID
  gd_proc_date               DATE;                                            -- 処理日
  gb_org_acct_period_flg     BOOLEAN;                                         -- 前月在庫会計期間オープンフラグ
  g_cust_shift_info_tab      g_cust_shift_info_ttype;                         -- PL/SQL表：顧客移行情報格納用
  gn_cust_cnt                NUMBER;                                          -- PL/SQL表インデックス
  g_vd_inv_trnsfr_info_tab   g_vd_inv_trnsfr_info_ttype;                      -- PL/SQL表：VD在庫保管場所転送情報納用
  gn_column_no_cnt           NUMBER;                                          -- PL/SQL表インデックス

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_process_flag IN  VARCHAR2      -- 起動区分
    , ov_errbuf       OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_prf_org_code     CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- プロファイル 在庫組織コード
    cv_lookup_type      CONSTANT VARCHAR2(30) := 'XXCOI1_TRANSACTION_TYPE_NAME';  -- 参照タイプ 取引タイプ名称
    cv_lookup_code      CONSTANT VARCHAR2(3)  := '290';                           -- 参照コード 取引タイプ(拠点分割VD在庫振替)
    cn_next_day         CONSTANT NUMBER       := 1;                               -- 翌日
    cn_proc_type        CONSTANT NUMBER       := 2;                               -- 処理区分：後
    cn_system_cal       CONSTANT NUMBER       := 1;                               -- カレンダー区分：システム稼働日カレンダー
--
    -- *** ローカル変数 ***
    lt_org_code                 mtl_parameters.organization_code%TYPE;            -- 在庫組織コード
    lt_sys_cal_code             bom_calendar_dates.calendar_code%TYPE;            -- システム稼働日カレンダーコード
    lt_tran_type_name           mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名
    ld_process_date             DATE;                                             -- 業務日付
    ld_oprtn_date               DATE;                                             -- システム稼動日
    ld_last_month_proc_date     DATE;                                             -- 前月処理日付(処理日付－１ヶ月の日付)
    lb_org_acct_period_flg      BOOLEAN;                                          -- 当月在庫会計期間オープンフラグ

--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- コンカレント入力パラメータメッセージ出力
    -- ==============================================================
    -- 入力パラメータがなかった場合
    IF ( iv_process_flag IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcok
                     , iv_name         => cv_msg_no_prm
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcok
                    , iv_name         => cv_msg_prm
                    , iv_token_name1  => cv_tkn_process_flag
                    , iv_token_value1 => iv_process_flag
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- ==============================================================
    -- 在庫組織ID取得
    -- ==============================================================
    -- 在庫組織コード取得
    lt_org_code := fnd_profile.value( cv_prf_org_code );
    -- プロファイルから在庫組織コードが取得できない場合
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_org_code_get_err
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 在庫組織ID取得
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_code );
    -- 在庫組織IDが取得できない場合
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_org_id_get_err
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => TO_CHAR( lt_org_code )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- 処理日取得
    -- ==============================================================
    -- 業務日付取得
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_process_date_get_err
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    
    -- 起動区分がリカバリの場合:処理日＝業務日付
    IF ( iv_process_flag = cv_prm_recovery ) THEN
      gd_proc_date := ld_process_date;
    -- 起動区分が通常起動の場合:処理日＝翌システム稼動日
    ELSE
      -- システム稼動日取得(翌システム稼動日)
      gd_proc_date := xxcok_common_pkg.get_operating_day_f (
                          id_proc_date     => ld_process_date  -- 処理日：業務日付
                        , in_days          => cn_next_day      -- 日数：1
                        , in_proc_type     => cn_proc_type     -- 処理区分：後
                        , in_calendar_type => cn_system_cal    -- カレンダー区分：システム稼働日カレンダー
                      );
      -- システム稼動日が取得できない場合
      IF ( gd_proc_date IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcok
                       , iv_name         => cv_msg_oprtn_date_get_err
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ==============================================================
    -- 在庫会計期間ステータス取得
    -- ==============================================================
    -- 当月在庫会計期間ステータス取得
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id               -- 在庫組織ID
      , id_target_date     => gd_proc_date            -- 処理日
      , ob_chk_result      => lb_org_acct_period_flg  -- チェック結果
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    -- 在庫会計期間ステータスの取得に失敗した場合
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_org_acct_period_get_err
                     , iv_token_name1  => cv_tkn_target_date
                     , iv_token_value1 => TO_CHAR( gd_proc_date )
                   );
      RAISE global_api_expt;
    END IF;
    -- 当月在庫会計期間がクローズの場合
    IF ( NOT lb_org_acct_period_flg ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcok
                     , iv_name         => cv_msg_org_acct_period_err
                     , iv_token_name1  => cv_tkn_proc_date
                     , iv_token_value1 => TO_CHAR( gd_proc_date )
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 処理日の1ヶ月前の日付を取得
    ld_last_month_proc_date := ADD_MONTHS( gd_proc_date, -1 );
    -- 前月在庫会計期間ステータス取得
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                  -- 在庫組織ID
      , id_target_date     => ld_last_month_proc_date    -- 処理日
      , ob_chk_result      => gb_org_acct_period_flg     -- チェック結果
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    -- 在庫会計期間ステータスの取得に失敗した場合
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_org_acct_period_get_err
                     , iv_token_name1  => cv_tkn_target_date
                     , iv_token_value1 => TO_CHAR( ld_last_month_proc_date )
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- 取引タイプID取得
    -- ==============================================================
    -- 取引タイプ名取得
    lt_tran_type_name := xxcoi_common_pkg.get_meaning( cv_lookup_type, cv_lookup_code );
    -- 共通関数のリターンコードがNULLの場合
    IF ( lt_tran_type_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_tran_type_name_get_err
                     , iv_token_name1  => cv_tkn_lookup_type
                     , iv_token_value1 => cv_lookup_type
                     , iv_token_name2  => cv_tkn_lookup_code
                     , iv_token_value2 => cv_lookup_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    
    -- 取引タイプID取得
    gt_tran_type_id := xxcoi_common_pkg.get_transaction_type_id( lt_tran_type_name );
    -- 共通関数のリターンコードがNULLの場合
    IF ( gt_tran_type_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_tran_type_id_get_err
                     , iv_token_name1  => cv_tkn_tran_type
                     , iv_token_value1 => lt_tran_type_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
   * Procedure Name   : get_cust_shift_info
   * Description      : 顧客移行情報の取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_cust_shift_info(
      on_cust_shift_cnt  OUT NUMBER        -- 取得件数
    , ov_errbuf          OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode         OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg          OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_shift_info'; -- プログラム名
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
    cv_status_fix  CONSTANT VARCHAR2(1) := 'A';   -- ステータス：確定
    cv_fvd         CONSTANT VARCHAR2(2) := '25';  -- フルVD
    cv_fvds        CONSTANT VARCHAR2(2) := '24';  -- フルVD(消化)
    cv_svd         CONSTANT VARCHAR2(2) := '27';  -- 消化VD
    cv_v           CONSTANT VARCHAR2(1) := 'V';   -- 保管場所コード変換用：VD(フルVD/フルVD(消化)/消化VD共通)
    cv_f           CONSTANT VARCHAR2(1) := 'F';   -- 保管場所コード変換用：フルVD/フルVD(消化)
    cv_s           CONSTANT VARCHAR2(1) := 'S';   -- 保管場所コード変換用：消化VD
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 顧客移項情報取得
    CURSOR cust_shift_info_cur
    IS
      SELECT hca.cust_account_id         AS cust_account_id               -- 1.顧客ID
           , xcs.cust_shift_id           AS cust_shift_id                 -- 2.顧客移行情報ID
           , xcs.cust_code               AS cust_code                     -- 3.顧客コード
           , xcs.prev_base_code          AS prev_base_code                -- 4.旧担当拠点コード
           , xcs.new_base_code           AS new_base_code                 -- 5.新担当拠点コード
           , xcs.cust_shift_date         AS cust_shift_date               -- 6.顧客移行日
           , CASE WHEN xca.business_low_type = cv_fvd                     -- 7.VD在庫保管場所転送ステータス
                    OR xca.business_low_type = cv_fvds                    
                    OR xca.business_low_type = cv_svd 
                  THEN                                                    --  業態（小分類）:フルVD/フルVD(消化)/消化VD
                    xcs.vd_inv_trnsfr_status                              --    取得したVD在庫保管場所転送ステータス
                  ELSE                                                    --  業態（小分類）:その他
                    cv_trnsfr_status_out                                  --    対象外に設定
             END                         AS vd_inv_trnsfr_status          -- 7.VD在庫保管場所転送ステータス
           , CASE WHEN xca.business_low_type = cv_fvd                     -- 8.出庫側保管場所コード  
                    OR xca.business_low_type = cv_fvds                    
                  THEN                                                    --  業態（小分類）:フルVD/フルVD(消化)
                    cv_v || xcs.prev_base_code || cv_f                    --    'V'+旧担当拠点コード+'F'
                  WHEN xca.business_low_type = cv_svd THEN                --  業態（小分類）:消化VD
                    cv_v || xcs.prev_base_code || cv_s                    --    'V'+旧担当拠点コード+'S'
                  ELSE                                                    --  業態（小分類）:その他
                    ''                                                    --    NULL
             END                         AS sec_inv_code_out              --  出庫側保管場所コード
           , CASE WHEN xca.business_low_type = cv_fvd                     -- 9.入庫側保管場所コード
                    OR xca.business_low_type = cv_fvds                    
                  THEN                                                    --  業態（小分類）:フルVD/フルVD(消化)
                    cv_v || xcs.new_base_code  || cv_f                    --    'V'+新担当拠点コード+'F'
                  WHEN xca.business_low_type = cv_svd THEN                --  業態（小分類）:消化VD
                    cv_v || xcs.new_base_code  || cv_s                    --    'V'+新担当拠点コード+'S'
                  ELSE                                                    --  業態（小分類）:その他
                    ''                                                    --    NULL
             END                         AS sec_inv_code_in               --  入庫側保管場所コード
      FROM   xxcok_cust_shift_info       xcs                              -- 顧客移行情報テーブル
           , hz_cust_accounts            hca                              -- 顧客マスタ
           , xxcmm_cust_accounts         xca                              -- 顧客追加情報テーブル
      WHERE  xcs.status                  =   cv_status_fix                -- ステータス（確定）
      AND    xcs.cust_shift_date         <=  gd_proc_date                 -- 顧客移行日 <= 処理日
      AND    xcs.vd_inv_trnsfr_status                                     -- VD在庫保管場所転送ステータス
        IN ( cv_trnsfr_status_prev, cv_trnsfr_status_reserve )            --    ｢未転送｣ ｢保留｣
      AND    xcs.cust_code               =   hca.account_number           -- 顧客コード
      AND    hca.cust_account_id         =   xca.customer_id;             -- 顧客ID

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
    -- カーソルオープン
    OPEN cust_shift_info_cur;
    
    FETCH cust_shift_info_cur BULK COLLECT INTO g_cust_shift_info_tab;

    -- 顧客件数セット
    on_cust_shift_cnt := g_cust_shift_info_tab.COUNT;

    -- カーソルクローズ
    CLOSE cust_shift_info_cur;
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
      -- カーソルがオープンしていたらクローズ
      IF ( cust_shift_info_cur%ISOPEN ) THEN
        CLOSE cust_shift_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_cust_shift_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_transfer_cust
   * Description      : 転送対象チェック (A-4)
   ***********************************************************************************/
  PROCEDURE chk_transfer_cust(
      ov_trnsfr_status       OUT   VARCHAR2        -- 転送ステータス
    , ov_errbuf              OUT   VARCHAR2        -- エラー・メッセージ           --# 固定 #
    , ov_retcode             OUT   VARCHAR2        -- リターン・コード             --# 固定 #
    , ov_errmsg              OUT   VARCHAR2 )      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_transfer_cust'; -- プログラム名
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
    ln_last_manth_fix_info        NUMBER;  -- 前月VD在庫確定情報
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
    -- 初期値：転送対象(「転送済」更新対象)
    ov_trnsfr_status := cv_trnsfr_status_trnsfr;  

    -- VD在庫保管場所転送ステータスが「対象外」の場合(A-2で業態（小分類）:フルVD/フルVD(消化)/消化VD以外)
    IF ( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_vd_inv_trnsfr_status = cv_trnsfr_status_out ) THEN
      -- 「対象外」更新対象とする
      ov_trnsfr_status := cv_trnsfr_status_out;

    -- 業態（小分類）:フルVD/フルVD(消化)/消化VDの顧客で前月在庫会計期間がオープンかつ顧客移行日が当月の場合
    ELSIF ( gb_org_acct_period_flg ) 
      AND ( TRUNC( gd_proc_date , 'MM' ) <= TRUNC( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_date ) )
    THEN
      -- VD在庫保管場所転送ステータスが「保留」の場合
      IF ( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_vd_inv_trnsfr_status = cv_trnsfr_status_reserve ) THEN
        -- 「保留」更新対象とする
        ov_trnsfr_status := cv_trnsfr_status_reserve;

      -- VD在庫保管場所転送ステータスが「未転送」の場合
      ELSIF ( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_vd_inv_trnsfr_status = cv_trnsfr_status_prev ) THEN
        -- 顧客移行日が月初の場合
        IF ( TRUNC( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_date, 'DD' )
           = TRUNC( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_date, 'MM' ) )
        THEN
          --「保留」更新対象とする
          ov_trnsfr_status := cv_trnsfr_status_reserve;

        -- 顧客移行日が月初以外の場合
        ELSE
-- 2009/12/10 Ver.1.2 [E_本稼動_00405] SCS S.Moriyama UPD START
--          -- 前月VD在庫確定情報抽出
--          SELECT   count(ROWID)                                                                  -- 前月VD在庫確定情報
--          INTO     ln_last_manth_fix_info
--          FROM     xxcoi_mst_vd_column   xmvc1                                                   -- VDコラムマスタ
--          WHERE    xmvc1.customer_id = g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id  -- 顧客ID
--          AND NOT EXISTS (
--            SELECT ROWID 
--            FROM   xxcoi_mst_vd_column xmvc2
--            WHERE  xmvc2.customer_id                   = xmvc1.customer_id
--            AND    xmvc2.column_no                     = xmvc1.column_no
--            AND    xmvc2.last_month_item_id            = xmvc1.item_id
--            AND    xmvc2.last_month_inventory_quantity = xmvc1.inventory_quantity
--            AND    xmvc2.last_month_price              = xmvc1.price
--          )
--          AND    ROWNUM = 1;
          -- 前月VD在庫確定情報抽出
          SELECT   count(ROWID)                                                                  -- 前月VD在庫確定情報
          INTO     ln_last_manth_fix_info
          FROM     xxcoi_mst_vd_column   xmvc1                                                   -- VDコラムマスタ
          WHERE    xmvc1.customer_id = g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id  -- 顧客ID
          AND NOT EXISTS (
            SELECT ROWID 
            FROM   xxcoi_mst_vd_column xmvc2
            WHERE  xmvc2.customer_id                           = xmvc1.customer_id
            AND    xmvc2.column_no                             = xmvc1.column_no
            AND    NVL(xmvc2.last_month_item_id,-1)            = NVL(xmvc1.item_id,-1)
            AND    NVL(xmvc2.last_month_inventory_quantity,-1) = NVL(xmvc1.inventory_quantity,-1)
            AND    NVL(xmvc2.last_month_price,-1)              = NVL(xmvc1.price,-1)
          )
          AND    ROWNUM = 1;
-- 2009/12/10 Ver.1.2 [E_本稼動_00405] SCS S.Moriyama UPD END
          -- 前月VD在庫確定情報が0件の場合
          IF ( ln_last_manth_fix_info = 0 ) THEN
            --「保留」更新対象とする
            ov_trnsfr_status := cv_trnsfr_status_reserve;
          END IF;
        END IF;
      END IF;
    END IF;
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
  END chk_transfer_cust;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_inv_info（顧客移項情報ループ部）
   * Description      : VD在庫保管場所転送情報取得 (A-5)
   ***********************************************************************************/
  PROCEDURE get_vd_inv_info(
      on_vd_inv_info_cnt  OUT NUMBER        -- 取得件数
    , ov_errbuf           OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode          OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg           OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_vd_inv_info'; -- プログラム名
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
    ln_sec_inv_cnt         NUMBER;                                                  -- 保管場所チェック用カウンタ
    lt_tkn_sub_inv_code    mtl_secondary_inventories.secondary_inventory_name%TYPE; -- トークン(保管場所コード)
    lt_tkn_base_code       xxcok_cust_shift_info.cust_code%TYPE;                    -- トークン(顧客コード)
--
    -- *** ローカル・カーソル ***
--
    -- 前月VD在庫取得用カーソル
    CURSOR vd_inv_last_month_cur
    IS
      SELECT xmvc.column_no                      AS xmvc_column_no           --  1.コラムNo.
           , xmvc.last_month_item_id             AS xmvc_item_id             --  2.品目ID(前月末品目ID)
           , msib.segment1                       AS msib_item_code           --  3.品目コード
           , xmvc.last_month_inventory_quantity  AS xmvc_inv_qty             --  4.基準在庫数(前月末基準在庫数)
           , msib.primary_uom_code               AS msib_primary_uom         --  5.基準単位
           , msib.inventory_item_status_code     AS msib_item_status         --  6.品目ステータス
           , msib.customer_order_enabled_flag    AS msib_cust_order_flg      --  7.顧客受注可能フラグ
           , msib.mtl_transactions_enabled_flag  AS msib_transaction_enable  --  8.取引可能
           , msib.stock_enabled_flag             AS msib_stock_enabled_flg   --  9.在庫保有可能フラグ
           , msib.returnable_flag                AS msib_return_enable       -- 10.返品可能
           , iimb.attribute26                    AS iimb_sales_class         -- 11.売上対象区分
      FROM   xxcoi_mst_vd_column                 xmvc                        -- VDコラムマスタ
           , mtl_system_items_b                  msib                        -- Disc品目マスタ
           , ic_item_mst_b                       iimb                        -- OPM品目マスタ
      WHERE  xmvc.customer_id
             = g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id
      AND    xmvc.last_month_item_id            = msib.inventory_item_id     -- 前月末品目ID
      AND    xmvc.organization_id               = msib.organization_id       -- 在庫組織ID
      AND    xmvc.last_month_inventory_quantity > 0                          -- 前月末基準在庫数 > 0
      AND    iimb.item_no                       = msib.segment1;             -- 品目コード

    -- 当月VD在庫取得用カーソル
    CURSOR vd_inv_this_month_cur
    IS
      SELECT xmvc.column_no                      AS xmvc_column_no           --  1.コラムNo.
           , xmvc.item_id                        AS xmvc_item_id             --  2.品目ID
           , msib.segment1                       AS msib_item_code           --  3.品目コード
           , xmvc.inventory_quantity             AS xmvc_inv_qty             --  4.基準在庫数
           , msib.primary_uom_code               AS msib_primary_uom         --  5.基準単位
           , msib.inventory_item_status_code     AS msib_item_status         --  6.品目ステータス
           , msib.customer_order_enabled_flag    AS msib_cust_order_flg      --  7.顧客受注可能フラグ
           , msib.mtl_transactions_enabled_flag  AS msib_transaction_enable  --  8.取引可能
           , msib.stock_enabled_flag             AS msib_stock_enabled_flg   --  9.在庫保有可能フラグ
           , msib.returnable_flag                AS msib_return_enable       -- 10.返品可能
           , iimb.attribute26                    AS iimb_sales_class         -- 11.売上対象区分
      FROM   xxcoi_mst_vd_column                 xmvc                        -- VDコラムマスタ
           , mtl_system_items_b                  msib                        -- Disc品目マスタ
           , ic_item_mst_b                       iimb                        -- OPM品目マスタ
      WHERE  xmvc.customer_id
             = g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id
      AND    xmvc.item_id                       = msib.inventory_item_id     -- 品目ID
      AND    xmvc.organization_id               = msib.organization_id       -- 在庫組織ID
      AND    xmvc.inventory_quantity            > 0                          -- 基準在庫数 > 0
      AND    iimb.item_no                       = msib.segment1;             -- 品目コード


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

    -- VD在庫保管場所転送ステータスが「保留」
    IF ( g_cust_shift_info_tab( gn_cust_cnt ).xcsi_vd_inv_trnsfr_status = cv_trnsfr_status_reserve ) THEN
        
      -- 前月末情報取得
      -- カーソルオープン
      OPEN vd_inv_last_month_cur;
      -- フェッチ
      FETCH vd_inv_last_month_cur BULK COLLECT INTO g_vd_inv_trnsfr_info_tab;
      -- VD在庫保管場所転送情報取得件数セット
      on_vd_inv_info_cnt      := g_vd_inv_trnsfr_info_tab.COUNT;
      -- カーソルクローズ
      CLOSE vd_inv_last_month_cur;

    -- VD在庫保管場所転送ステータスが「未転送」
    ELSE

      -- 当月情報取得
      -- カーソルオープン
      OPEN vd_inv_this_month_cur;
      -- フェッチ
      FETCH vd_inv_this_month_cur BULK COLLECT INTO g_vd_inv_trnsfr_info_tab;
      -- VD在庫保管場所転送情報取得件数セット
      on_vd_inv_info_cnt      := g_vd_inv_trnsfr_info_tab.COUNT;
      -- カーソルクローズ
      CLOSE vd_inv_this_month_cur;

    END IF;

    -- 取得件数0件の場合(中止顧客)
    IF ( on_vd_inv_info_cnt = 0 ) THEN
      RETURN;
    END IF;

    -- 保管場所チェック処理
    -- 出庫側保管場所チェック
    SELECT COUNT(1)
    INTO   ln_sec_inv_cnt
    FROM   mtl_secondary_inventories msi                                -- 保管場所マスタ
    WHERE  msi.secondary_inventory_name 
           = g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out  -- 出庫側保管場所コード
    AND    msi.organization_id               =   gt_org_id
    AND    TRUNC( NVL( msi.disable_date, SYSDATE + 1 ) )  > TRUNC( SYSDATE );
    
    -- 保管場所が特定できなかった場合
    IF ( ln_sec_inv_cnt = 0 ) THEN
      lt_tkn_sub_inv_code := g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out;
      lt_tkn_base_code      := g_cust_shift_info_tab( gn_cust_cnt ).xcsi_prev_base_code;
      RAISE sec_inv_expt;
    END IF;


    --入庫側保管場所チェック
    SELECT COUNT(1)
    INTO   ln_sec_inv_cnt
    FROM   mtl_secondary_inventories msi                                -- 保管場所マスタ
    WHERE  msi.secondary_inventory_name 
           = g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in   -- 入庫側保管場所コード
    AND    msi.organization_id               =   gt_org_id
    AND    TRUNC( NVL( msi.disable_date, SYSDATE + 1 ) )  > TRUNC( SYSDATE );
    
    -- 保管場所が特定できなかった場合
    IF ( ln_sec_inv_cnt = 0 ) THEN
      lt_tkn_sub_inv_code := g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in;
      lt_tkn_base_code      := g_cust_shift_info_tab( gn_cust_cnt ).xcsi_new_base_code;
      RAISE sec_inv_expt;
    END IF;

--
  EXCEPTION
    -- *** 保管場所チェックエラー ***
    WHEN sec_inv_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcok
                     , iv_name         => cv_msg_sec_inv_chk_err
                     , iv_token_name1  => cv_tkn_cust_code
                     , iv_token_value1 => g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_code
                     , iv_token_name2  => cv_tkn_base_code
                     , iv_token_value2 => lt_tkn_base_code
                     , iv_token_name3  => cv_tkn_sub_inv_code
                     , iv_token_value3 => lt_tkn_sub_inv_code
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ステータスを警告にする
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
      -- カーソルがオープンしていたらクローズ
      IF ( vd_inv_last_month_cur%ISOPEN ) THEN
        CLOSE vd_inv_last_month_cur;
      END IF;
      IF ( vd_inv_this_month_cur%ISOPEN ) THEN
        CLOSE vd_inv_this_month_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_vd_inv_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_item_info
   * Description      : 項目チェック (A-6)
   ***********************************************************************************/
  PROCEDURE chk_item_info(
      ov_errbuf       OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_info'; -- プログラム名
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
    cv_status_Inactive      CONSTANT VARCHAR2(10) := 'Inactive';          -- ステータス：Inactive
    cv_flg_y                CONSTANT VARCHAR2(1)  := 'Y';                 -- フラグ値：Y
    cv_sales_classs_target  CONSTANT VARCHAR2(1)  := '1';                 -- 売上対象区分：対象
--
    -- *** ローカル変数 ***
    lt_disable_date           mtl_units_of_measure_tl.disable_date%TYPE;  -- 無効日
    lv_msg_name               VARCHAR2(100);                              -- メッセージ
    
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
    -- 品目ステータス有効チェック
    IF ( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_item_status = cv_status_Inactive         -- 品目ステータス
      OR NOT ( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_cust_order_flg     = cv_flg_y      -- 顧客受注可能フラグ
        AND    g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_transaction_enable = cv_flg_y      -- 取引可能
        AND    g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_stock_enabled_flg  = cv_flg_y      -- 在庫保有可能フラグ
        AND    g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_return_enable      = cv_flg_y ) )  -- 返品可能
    THEN
      lv_msg_name := cv_msg_item_status_chk_err;
      RAISE item_chk_expt;
    END IF;

    -- 品目売上対象区分有効チェック
    IF ( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).iimb_sales_class != cv_sales_classs_target ) THEN
      lv_msg_name := cv_msg_sales_class_chk_err;
      RAISE item_chk_expt;
    END IF;

    -- 基準単位の無効日取得
    xxcoi_common_pkg.get_uom_disable_info(
        iv_unit_code          => g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_primary_uom  -- 1.基準単位
      , od_disable_date       => lt_disable_date                                                -- 2.無効日
      , ov_errbuf             => lv_errbuf                                                      -- 3.エラー・メッセージ
      , ov_retcode            => lv_retcode                                                     -- 4.リターン・コード
      , ov_errmsg             => lv_errmsg                                                      -- 5.ユーザー・エラー・メッセージ
    );

    -- 基準単位の存在チェック
    IF ( lv_retcode != cv_status_normal ) THEN
      lv_msg_name := cv_msg_primary_uom_not_found;
      RAISE primary_uom_chk_expt;
    END IF;

    -- 基準単位の有効チェック
    IF ( TRUNC( NVL( lt_disable_date, SYSDATE + 1 ) ) <= TRUNC( SYSDATE ) ) THEN 
      lv_msg_name := cv_msg_primary_uom_disable;
      RAISE primary_uom_chk_expt;
    END IF;

--
  EXCEPTION
    -- *** 項目チェックエラー(品目チェック)ハンドラ ***
    WHEN item_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcok
                      , iv_name         => lv_msg_name
                      , iv_token_name1  => cv_tkn_cust_code
                      , iv_token_value1 => g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_code
                      , iv_token_name2  => cv_tkn_column_no
                      , iv_token_value2 => TO_CHAR( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_column_no )
                      , iv_token_name3  => cv_tkn_item_code
                      , iv_token_value3 => g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_item_code
                      , iv_token_name4  => cv_tkn_sub_inv_code
                      , iv_token_value4 => g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out
                      , iv_token_name5  => cv_tkn_trnsfr_sub_inv
                      , iv_token_value5 => g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in
                      , iv_token_name6  => cv_tkn_qty
                      , iv_token_value6 => TO_CHAR( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_inv_qty )
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ステータスを警告にする
      ov_retcode := cv_status_warn;
    -- *** 項目チェックエラー(基準単位チェック) ***
    WHEN primary_uom_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcok
                      , iv_name         => lv_msg_name
                      , iv_token_name1  => cv_tkn_primary_uom
                      , iv_token_value1 => g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_primary_uom
                      , iv_token_name2  => cv_tkn_cust_code
                      , iv_token_value2 => g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_code
                      , iv_token_name3  => cv_tkn_column_no
                      , iv_token_value3 => TO_CHAR( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_column_no )
                      , iv_token_name4  => cv_tkn_item_code
                      , iv_token_value4 => g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_item_code
                      , iv_token_name5  => cv_tkn_sub_inv_code
                      , iv_token_value5 => g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out
                      , iv_token_name6  => cv_tkn_trnsfr_sub_inv
                      , iv_token_value6 => g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in
                      , iv_token_name7  => cv_tkn_qty
                      , iv_token_value7 => TO_CHAR( g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_inv_qty )
                    );
      IF ( lv_errbuf IS NULL ) THEN
        lv_errbuf  := lv_errmsg;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ステータスを警告にする
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
  END chk_item_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_mtl_txn_oif
   * Description      : 資材取引OIF登録 (A-7)
   ***********************************************************************************/
  PROCEDURE ins_mtl_txn_oif(
      ov_errbuf       OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mtl_txn_oif'; -- プログラム名
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
    cn_oif_process_flg       CONSTANT NUMBER := 1;  -- プロセスフラグ：処理対象
    cn_oif_transaction_mode  CONSTANT NUMBER := 3;  -- 取引モード：バックグラウンド
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
    -- 資材取引OIFへVD在庫保管場所転送情報を登録
    -- 品目ID/基準在庫数…VD在庫保管場所転送ステータス:未転送 当月情報/保留：前月末情報
    INSERT INTO mtl_transactions_interface(
        source_code                                                    --  1.ソースコード
      , source_header_id                                               --  2.ソースヘッダID
      , source_line_id                                                 --  3.ソースラインID
      , process_flag                                                   --  4.プロセスフラグ
      , transaction_mode                                               --  5.取引モード
      , transaction_type_id                                            --  6.取引タイプID
      , transaction_date                                               --  7.取引日
      , inventory_item_id                                              --  8.品目ID
      , subinventory_code                                              --  9.保管場所
      , organization_id                                                -- 10.在庫組織ID
      , transaction_quantity                                           -- 11.取引数量
      , primary_quantity                                               -- 12.基準単位数量
      , transaction_uom                                                -- 13.取引単位
      , transfer_subinventory                                          -- 14.移動先保管場所
      , transfer_organization                                          -- 15.移動先在庫組織
      , created_by                                                     -- 16.作成者
      , creation_date                                                  -- 17.作成日
      , last_updated_by                                                -- 18.最終更新者
      , last_update_date                                               -- 19.最終更新日
      , last_update_login                                              -- 20.最終更新ユーザ
      , request_id                                                     -- 21.要求ID
      , program_application_id                                         -- 22.プログラムアプリケーションID
      , program_id                                                     -- 23.プログラムID
      , program_update_date                                            -- 24.プログラム更新日
    )
    VALUES(
        cv_pkg_name                                                    --  1.プログラム短縮名
      , g_cust_shift_info_tab( gn_cust_cnt ).hca_cust_account_id       --  2.顧客ID
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_column_no    --  3.コラムNo.
      , cn_oif_process_flg                                             --  4.処理対象(固定)
      , cn_oif_transaction_mode                                        --  5.バックグラウンド(固定)
      , gt_tran_type_id                                                --  6.取引タイプID(拠点分割VD在庫振替)
      , g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_date      --  7.顧客移行日
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_item_id      --  8.品目ID
      , g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_out      --  9.出庫側保管場所コード
      , gt_org_id                                                      -- 10.在庫組織ID
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_inv_qty      -- 11.基準在庫数
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).xmvc_inv_qty      -- 12.基準在庫数
      , g_vd_inv_trnsfr_info_tab( gn_column_no_cnt ).msib_primary_uom  -- 13.基準単位
      , g_cust_shift_info_tab( gn_cust_cnt ).msi_sec_inv_code_in       -- 14.入庫側保管場所コード
      , gt_org_id                                                      -- 15.在庫組織ID
      , cn_created_by                                                  -- 16.作成者
      , SYSDATE                                                        -- 17.システム日付
      , cn_last_updated_by                                             -- 18.最終更新者
      , SYSDATE                                                        -- 19.システム日付
      , cn_last_update_login                                           -- 20.最終更新者ログイン
      , cn_request_id                                                  -- 21.要求ID
      , cn_program_application_id                                      -- 22.プログラムアプリケーションID
      , cn_program_id                                                  -- 23.プログラムID
      , SYSDATE                                                        -- 24.システム日付
    );
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
  END ins_mtl_txn_oif;
--
  /**********************************************************************************
   * Procedure Name   : upd_status
   * Description      : 顧客移行情報更新 (A-8)
   ***********************************************************************************/
  PROCEDURE upd_status(
      iv_trnsfr_status      IN  VARCHAR2      -- 転送ステータス
    , ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode            OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg             OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_status'; -- プログラム名
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
    CURSOR upd_cust_shift_info_tbl_cur
    IS
      -- 顧客移行情報テーブルのロック取得
      SELECT xcs.cust_shift_id            -- 顧客移行情報ID
      FROM   xxcok_cust_shift_info   xcs  -- 顧客移行情報テーブル
      WHERE  xcs.cust_shift_id = g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_shift_id
      FOR UPDATE NOWAIT;
      
--
    -- *** ローカル・レコード ***
    upd_cust_shift_info_tbl_rec  upd_cust_shift_info_tbl_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- VD在庫保管場所転送ステータス更新
    -- ===============================
    -- カーソルオープン
    OPEN upd_cust_shift_info_tbl_cur;

    -- レコード読込
    FETCH upd_cust_shift_info_tbl_cur INTO upd_cust_shift_info_tbl_rec;

    -- VD在庫保管場所転送ステータス更新 
    UPDATE xxcok_cust_shift_info      xcs
    SET    xcs.vd_inv_trnsfr_status = iv_trnsfr_status                            -- 1.VD在庫保管場所転送ステータス
         , last_updated_by          = cn_last_updated_by                          -- 2.最終更新者
         , last_update_date         = SYSDATE                                     -- 3.システム日付
         , last_update_login        = cn_last_update_login                        -- 4.最終更新者ログイン
         , request_id               = cn_request_id                               -- 5.要求ID
         , program_application_id   = cn_program_application_id                   -- 6.プログラムアプリケーションID
         , program_id               = cn_program_id                               -- 7.プログラムID
         , program_update_date      = SYSDATE                                     -- 8.システム日付
    WHERE  xcs.cust_shift_id        = upd_cust_shift_info_tbl_rec.cust_shift_id;
    
    -- カーソルクローズ
    CLOSE upd_cust_shift_info_tbl_cur;

--
  EXCEPTION
    -- *** ロックエラーハンドラ ***
    WHEN lock_expt THEN
      -- カーソルがオープンしていたらクローズ
      IF ( upd_cust_shift_info_tbl_cur%ISOPEN ) THEN
        CLOSE upd_cust_shift_info_tbl_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcok
                      , iv_name         => cv_msg_lock_err
                      , iv_token_name1  => cv_tkn_cust_code
                      , iv_token_value1 => g_cust_shift_info_tab( gn_cust_cnt ).xcsi_cust_code
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ステータスを警告にする
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
      -- カーソルがオープンしていたらクローズ
      IF ( upd_cust_shift_info_tbl_cur%ISOPEN ) THEN
        CLOSE upd_cust_shift_info_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_status;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_process_flag IN  VARCHAR2      -- 起動区分
    , ov_errbuf       OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2      -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2 )    -- ユーザー・エラー・メッセージ --# 固定 #
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
    lt_trnsfr_status        xxcok_cust_shift_info.vd_inv_trnsfr_status%TYPE;  -- 転送ステータス(顧客移行情報更新用)
    ln_cust_shift_cnt       NUMBER DEFAULT 0;                                 -- 取得件数：顧客移行情報(A-2)
    ln_vd_inv_info_cnt      NUMBER DEFAULT 0;                                 -- 取得件数：VD在庫保管場所転送情報(A-5)
    ln_target_column_no_cnt NUMBER DEFAULT 0;                                 -- 対象件数  (１顧客単位コラム数)
    ln_normal_column_no_cnt NUMBER DEFAULT 0;                                 -- 成功件数  (１顧客単位コラム数)
    ln_error_column_no_cnt  NUMBER DEFAULT 0;                                 -- エラー件数(１顧客単位コラム数)

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
    gn_target_cnt           := 0;  -- 対象件数
    gn_normal_cnt           := 0;  -- 成功件数
    gn_error_cnt            := 0;  -- エラー件数
    gn_warn_cnt             := 0;  -- スキップ件数
    gn_out_cnt              := 0;  -- 保管場所転送情報作成対象外件数
    gn_target_column_no_cnt := 0;  -- 対象件数  (コラムNo.単位総数)
    gn_normal_column_no_cnt := 0;  -- 成功件数  (コラムNo.単位総数)
    gn_error_column_no_cnt  := 0;  -- エラー件数(コラムNo.単位総数)
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
        iv_process_flag => iv_process_flag  -- 起動区分
      , ov_errbuf       => lv_errbuf        -- エラー・メッセージ
      , ov_retcode      => lv_retcode       -- リターン・コード
      , ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 顧客移行情報の取得 (A-2)
    -- ===============================
    get_cust_shift_info(
        on_cust_shift_cnt  => ln_cust_shift_cnt  -- 取得件数
      , ov_errbuf          => lv_errbuf          -- エラー・メッセージ
      , ov_retcode         => lv_retcode         -- リターン・コード
      , ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;

    -- 取得件数0件の場合
    IF ( ln_cust_shift_cnt = 0 ) THEN
      -- 対象データ無しメッセージ出力
      gv_out_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_xxcok
                       , iv_name         => cv_msg_no_data
                     );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      RETURN;
    END IF;

    -- 対象件数セット(顧客単位)
    gn_target_cnt := ln_cust_shift_cnt;

    <<cust_loop>>  -- 顧客単位ループ
    FOR i IN 1 .. ln_cust_shift_cnt LOOP
      -- 初期化
      gn_cust_cnt             := i;                        -- PL/SQL表インデックス
      ln_vd_inv_info_cnt      := 0;
      ln_target_column_no_cnt := 0;
      ln_normal_column_no_cnt := 0;
      ln_error_column_no_cnt  := 0;
--
      -- ===============================
      -- セーブポイント設定 (A-3)
      -- ===============================
      SAVEPOINT cust_point;
--
--
      -- ===============================
      -- 転送対象チェック (A-4)
      -- ===============================
      chk_transfer_cust(
          ov_trnsfr_status  => lt_trnsfr_status  -- 転送ステータス
        , ov_errbuf         => lv_errbuf         -- エラー・メッセージ
        , ov_retcode        => lv_retcode        -- リターン・コード
        , ov_errmsg         => lv_errmsg         -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 転送対象の場合
      IF ( lt_trnsfr_status = cv_trnsfr_status_trnsfr ) THEN
--
        -- ===============================
        -- VD在庫保管場所転送情報取得 (A-5)
        -- ===============================
        get_vd_inv_info(
            on_vd_inv_info_cnt  => ln_vd_inv_info_cnt  -- 取得件数
          , ov_errbuf           => lv_errbuf           -- エラー・メッセージ
          , ov_retcode          => lv_retcode          -- リターン・コード
          , ov_errmsg           => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;

        -- 保管場所チェックエラーが発生した場合
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => lv_errmsg -- ユーザー・エラーメッセージ
          );
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => lv_errbuf -- エラーメッセージ
          );
          -- エラー件数
          gn_error_cnt := gn_error_cnt + 1;
          -- 転送ステータスにエラーをセット(更新対象外とする)
          lt_trnsfr_status := cv_trnsfr_status_error;
          -- 取得件数リセット
          ln_vd_inv_info_cnt := 0;
          -- ステータスを警告にする
          ov_retcode := cv_status_warn;

        -- 顧客に対するVD在庫保管場所転送情報が存在しない場合(中止顧客)
        ELSIF ( lv_retcode = cv_status_normal AND ln_vd_inv_info_cnt = 0 ) THEN
          -- 「対象外」更新対象とする
          lt_trnsfr_status := cv_trnsfr_status_out;
        END IF;
--
      END IF;

      -- VD在庫保管場所転送情報が存在する場合
      IF ( ln_vd_inv_info_cnt > 0 ) THEN

        -- 対象件数(１顧客単位コラム数)セット
        ln_target_column_no_cnt := ln_vd_inv_info_cnt;

        <<column_no_loop>>  -- コラムNo.単位ループ
        FOR j IN 1 .. ln_vd_inv_info_cnt LOOP
          -- 初期化
          gn_column_no_cnt := j;  -- PL/SQL表インデックス
--
          -- ===============================
          -- 項目チェック (A-6)
          -- ===============================
          chk_item_info(
              ov_errbuf   => lv_errbuf   -- エラー・メッセージ
            , ov_retcode  => lv_retcode  -- リターン・コード
            , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          -- 項目チェックエラーが発生した場合
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- メッセージ出力
            FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg -- ユーザー・エラーメッセージ
            );
            FND_FILE.PUT_LINE(
                which  => FND_FILE.LOG
              , buff   => lv_errbuf -- エラーメッセージ
            );
            -- エラー件数(１顧客単位コラム数)セット
            ln_error_column_no_cnt := ln_error_column_no_cnt + 1;
            -- ステータスを警告にする
            ov_retcode := cv_status_warn;
          -- 項目チェックOK
          ELSE
--
            -- ===============================
            -- 資材取引OIF登録 (A-7)
            -- ===============================
            ins_mtl_txn_oif(
                ov_errbuf   => lv_errbuf   -- エラー・メッセージ
              , ov_retcode  => lv_retcode  -- リターン・コード
              , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            -- 成功件数(コラムNo.単位総数)
            ln_normal_column_no_cnt := ln_normal_column_no_cnt + 1;
--
          END IF;
        END LOOP column_no_loop;
      END IF;
--
      -- 転送ステータスがエラー以外の場合
      IF ( lt_trnsfr_status != cv_trnsfr_status_error ) THEN
        -- ===============================
        -- 顧客移行情報更新 (A-8)
        -- ===============================
        upd_status(
            iv_trnsfr_status  => lt_trnsfr_status  -- 転送ステータス
          , ov_errbuf         => lv_errbuf         -- エラー・メッセージ
          , ov_retcode        => lv_retcode        -- リターン・コード
          , ov_errmsg         => lv_errmsg         -- ユーザー・エラー・メッセージ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        -- ロックエラーが発生した場合
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => lv_errmsg -- ユーザー・エラーメッセージ
          );
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => lv_errbuf -- エラーメッセージ
          );
          
          -- エラー件数 (VD保管場所転送ステータス未更新)
          gn_error_cnt := gn_error_cnt + 1;
          -- ステータスを警告にする
          ov_retcode := cv_status_warn;
          -- セーブポイントまでロールバック
          ROLLBACK TO SAVEPOINT cust_point;
        -- ステータスを更新した場合
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          -- 転送ステータスを「転送済」に更新した場合
          IF ( lt_trnsfr_status = cv_trnsfr_status_trnsfr ) THEN
            -- 成功件数
            gn_normal_cnt := gn_normal_cnt + 1;
          -- 転送ステータスを「保留」  に更新した場合
          ELSIF  ( lt_trnsfr_status = cv_trnsfr_status_reserve ) THEN
            -- スキップ件数
            gn_warn_cnt   := gn_warn_cnt + 1;
          -- 転送ステータスを「対象外」に更新した場合
          ELSIF  ( lt_trnsfr_status = cv_trnsfr_status_out ) THEN
            -- 保管場所転送情報作成対象外件数
            gn_out_cnt    := gn_out_cnt + 1;
          END IF;
          -- 顧客単位の対象件数/成功件数/エラー件数を総件数に加算
          gn_target_column_no_cnt := gn_target_column_no_cnt + ln_target_column_no_cnt;
          gn_normal_column_no_cnt := gn_normal_column_no_cnt + ln_normal_column_no_cnt;
          gn_error_column_no_cnt  := gn_error_column_no_cnt  + ln_error_column_no_cnt;
        END IF;
      END IF;

    END LOOP cust_loop;

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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf          OUT VARCHAR2     --  エラーメッセージ #固定#
    , retcode         OUT VARCHAR2     --  エラーコード     #固定#
    , iv_process_flag IN  VARCHAR2 )   --  起動区分
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
        iv_process_flag => iv_process_flag  -- 起動区分
      , ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      , ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
      , ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ステータス：異常
    IF ( lv_retcode = cv_status_error ) THEN
      -- 件数セット
      gn_target_cnt           := 0;
      gn_normal_cnt           := 0;
      gn_error_cnt            := 1;
      gn_warn_cnt             := 0;
      gn_target_column_no_cnt := 0;
      gn_normal_column_no_cnt := 0;
      gn_error_column_no_cnt  := 0;
      -- エラー出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg -- ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf -- エラーメッセージ
      );
    END IF;
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    
    -- 顧客単位件数メッセージ
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcok
                , iv_name         => cv_msg_unit_cust
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );

    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 保管場所転送情報作成対象外件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcok
                    , iv_name         => cv_msg_out_rec
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_out_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- コラムNo.単位件数メッセージ
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_xxcok
                , iv_name         => cv_msg_unit_column_no
              );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 対象件数(コラムNo.単位総数)出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_column_no_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 成功件数(コラムNo.単位総数)出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_column_no_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- エラー件数(コラムNo.単位総数)出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_column_no_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
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
END XXCOK003A01C;
/
