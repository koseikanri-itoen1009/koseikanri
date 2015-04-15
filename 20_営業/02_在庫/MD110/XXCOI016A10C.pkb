CREATE OR REPLACE PACKAGE BODY XXCOI016A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A10C(body)
 * Description      : ロット別受払データ作成(月次)
 * MD.050           : MD050_COI_016_A10_ロット別受払データ作成(月次).doc
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_end               終了処理(A-6)
 *  cre_inout_data         ロット別受払（月次）データ登録・更新処理 (A-5)
 *  cal_inout_data         受払項目算出処理 (A-4)
 *  get_inout_data         受払データ取得処理(A-3)
 *  cre_carry_data         繰越データ作成処理(A-2)
 *  proc_init              初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/27    1.0   Y.Nagasue        新規作成
 *  2015/04/07    1.1   S.Yamashita      E_本稼動_12237（倉庫管理不具合対応）
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(20) := 'XXCOI016A10C'; -- パッケージ名
  cv_xxcoi_short_name          CONSTANT VARCHAR2(5)  := 'XXCOI';        -- アプリケーション短縮名
--
  -- メッセージ
  cv_msg_xxcoi1_00005          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
                                                  -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi1_00006          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006'; 
                                                  -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi1_00011          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011'; 
                                                  -- 業務日付取得エラーメッセージ
  cv_msg_xxcoi1_10455          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10455'; 
                                                  -- 起動フラグ不正エラー
  cv_msg_xxcoi1_10454          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10454'; 
                                                  -- ロット別受払データ作成（月次）コンカレント入力パラメータ
  cv_msg_xxcoi1_10456          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10456'; 
                                                  -- 処理済取引ID取得エラー
  cv_msg_xxcoi1_10457          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10457'; 
                                                  -- ロット別受払データ作成（月次）対象0件メッセージ
  cv_msg_xxcoi1_10458          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10458'; 
                                                  -- ロット別受払（月次）対象取引IDメッセージ
--
  -- トークン
  cv_tkn_pro_tok               CONSTANT VARCHAR2(20) := 'PRO_TOK';          -- トークン：プロファイル名
  cv_tkn_org_code_tok          CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';     -- トークン：在庫組織コード
  cv_tkn_base_code             CONSTANT VARCHAR2(20) := 'BASE_CODE';        -- トークン：拠点コード
  cv_tkn_base_name             CONSTANT VARCHAR2(20) := 'BASE_NAME';        -- トークン：拠点名
  cv_tkn_startup_flg           CONSTANT VARCHAR2(20) := 'STARTUP_FLG';      -- トークン：起動フラグ
  cv_tkn_startup_flg_name      CONSTANT VARCHAR2(20) := 'STARTUP_FLG_NAME'; -- トークン：起動フラグ名
  cv_tkn_subinv_code           CONSTANT VARCHAR2(20) := 'SUBINV_CODE';      -- トークン：保管場所コード
  cv_tkn_subinv_name           CONSTANT VARCHAR2(20) := 'SUBINV_NAME';      -- トークン：保管場所名
  cv_tkn_program_name          CONSTANT VARCHAR2(20) := 'PROGRAM_NAME';     -- トークン：プログラム名
  cv_tkn_min_trx_id            CONSTANT VARCHAR2(20) := 'MIN_TRX_ID';       -- トークン：最小取引ID
  cv_tkn_max_trx_id            CONSTANT VARCHAR2(20) := 'MAX_TRX_ID';       -- トークン：最大取引ID
--
  -- プロファイル名
  cv_xxcoi1_organization_code  CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:在庫組織コード
--
  -- 参照タイプ名
  ct_xxcoi1_lot_rep_month_type fnd_lookup_values.lookup_type%TYPE := 'XXCOI1_LOT_REP_MONTH_TYPE';
                                                  -- 参照タイプ：ロット別受払データ作成(月次)起動フラグ
--
  -- 取引タイプコード
  ct_trx_type_10               CONSTANT fnd_lookup_values.lookup_code%TYPE := '10';  -- 入出庫
  ct_trx_type_20               CONSTANT fnd_lookup_values.lookup_code%TYPE := '20';  -- 倉替
  ct_trx_type_70               CONSTANT fnd_lookup_values.lookup_code%TYPE := '70';  -- 消化VD補充
  ct_trx_type_90               CONSTANT fnd_lookup_values.lookup_code%TYPE := '90';  -- 工場返品
  ct_trx_type_100              CONSTANT fnd_lookup_values.lookup_code%TYPE := '100'; -- 工場返品振戻
  ct_trx_type_110              CONSTANT fnd_lookup_values.lookup_code%TYPE := '110'; -- 工場倉替
  ct_trx_type_120              CONSTANT fnd_lookup_values.lookup_code%TYPE := '120'; -- 工場倉替振戻
  ct_trx_type_130              CONSTANT fnd_lookup_values.lookup_code%TYPE := '130'; -- 廃却
  ct_trx_type_140              CONSTANT fnd_lookup_values.lookup_code%TYPE := '140'; -- 廃却振戻
  ct_trx_type_150              CONSTANT fnd_lookup_values.lookup_code%TYPE := '150'; -- 工場入庫
  ct_trx_type_160              CONSTANT fnd_lookup_values.lookup_code%TYPE := '160'; -- 工場入庫振戻
  ct_trx_type_170              CONSTANT fnd_lookup_values.lookup_code%TYPE := '170'; -- 売上出庫
  ct_trx_type_180              CONSTANT fnd_lookup_values.lookup_code%TYPE := '180'; -- 売上出庫振戻
  ct_trx_type_190              CONSTANT fnd_lookup_values.lookup_code%TYPE := '190'; -- 返品
  ct_trx_type_200              CONSTANT fnd_lookup_values.lookup_code%TYPE := '200'; -- 返品振戻
  ct_trx_type_320              CONSTANT fnd_lookup_values.lookup_code%TYPE := '320'; -- 顧客見本出庫
  ct_trx_type_330              CONSTANT fnd_lookup_values.lookup_code%TYPE := '330'; -- 顧客見本出庫振戻
  ct_trx_type_340              CONSTANT fnd_lookup_values.lookup_code%TYPE := '340'; -- 顧客協賛見本出庫
  ct_trx_type_350              CONSTANT fnd_lookup_values.lookup_code%TYPE := '350'; -- 顧客協賛見本出庫振戻
  ct_trx_type_360              CONSTANT fnd_lookup_values.lookup_code%TYPE := '360'; -- 顧客広告宣伝費A自社商品
  ct_trx_type_370              CONSTANT fnd_lookup_values.lookup_code%TYPE := '370'; -- 顧客広告宣伝費A自社商品振戻
  ct_trx_type_380              CONSTANT fnd_lookup_values.lookup_code%TYPE := '380'; -- 出荷確定
  ct_trx_type_390              CONSTANT fnd_lookup_values.lookup_code%TYPE := '390'; -- ロケーション移動
  ct_trx_type_400              CONSTANT fnd_lookup_values.lookup_code%TYPE := '400'; -- 在庫移動増
  ct_trx_type_410              CONSTANT fnd_lookup_values.lookup_code%TYPE := '410'; -- 在庫移動減
--
  -- ステータス等
  -- 顧客マスタ
  ct_cust_status_a             CONSTANT hz_cust_accounts.status%TYPE               := 'A'; -- ステータス：A
  ct_cust_class_code_1         CONSTANT hz_cust_accounts.customer_class_code%TYPE  := '1'; -- 顧客区分：1
  -- 起動フラグ：ロット別受払(月次).データ区分
  ct_data_type_1               CONSTANT xxcoi_lot_reception_monthly.data_type%TYPE := '1'; -- データ区分：1
  ct_data_type_2               CONSTANT xxcoi_lot_reception_monthly.data_type%TYPE := '2'; -- データ区分：2
  -- 保管場所区分
  ct_subinv_kbn_2              CONSTANT mtl_secondary_inventories.attribute1%TYPE  := '2'; -- 保管場所区分：2
  -- フラグ
  cv_flag_y                    CONSTANT VARCHAR2(1)                                := 'Y'; -- フラグ：Y
  cv_flag_n                    CONSTANT VARCHAR2(1)                                := 'N'; -- フラグ：N
--
  -- 書式
  cv_yyyymm                    CONSTANT VARCHAR2(6) := 'YYYYMM'; -- 年月変換用
--
  -- その他
  cn_minus_1                   CONSTANT NUMBER := -1; -- 固定値マイナス1
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ保持変数
  gt_base_code                 xxcoi_lot_reception_monthly.base_code%TYPE;               -- 拠点コード
  gt_subinv_code               xxcoi_lot_reception_monthly.subinventory_code%TYPE;       -- 保管場所コード
  gt_startup_flg               xxcoi_lot_reception_monthly.data_type%TYPE;               -- 起動フラグ（データ区分）
--
  -- 初期処理取得値
  gt_org_code                  mtl_parameters.organization_code%TYPE;                    -- 在庫組織コード
  gt_org_id                    mtl_parameters.organization_id%TYPE;                      -- 在庫組織ID
  gd_proc_date                 DATE;                                                     -- 業務日付
  gt_pre_exe_id                xxcoi_cooperation_control.transaction_id%TYPE;            -- 前回取引ID
  gt_no_data_flag              VARCHAR2(1);                                              -- 対象0件フラグ
  gt_max_trx_id                xxcoi_lot_transactions.transaction_id%TYPE;               -- 最大取引ID
  gt_min_trx_id                xxcoi_lot_transactions.transaction_id%TYPE;               -- 最小取引ID
--
  -- 前レコードロット情報保持用変数
  gt_bef_practice_month        xxcoi_lot_reception_monthly.practice_month%TYPE;          -- 取引年月
  gt_bef_base_code             xxcoi_lot_reception_monthly.base_code%TYPE;               -- 拠点コード
  gt_bef_subinventory_code     xxcoi_lot_reception_monthly.subinventory_code%TYPE;       -- 保管場所コード
  gt_bef_subinv_type           xxcoi_lot_reception_monthly.subinventory_type%TYPE;       -- 保管場所区分
  gt_bef_location_code         xxcoi_lot_reception_monthly.location_code%TYPE;           -- ロケーションコード
  gt_bef_parent_item_id        xxcoi_lot_reception_monthly.parent_item_id%TYPE;          -- 親品目ID
  gt_bef_child_item_id         xxcoi_lot_reception_monthly.child_item_id%TYPE;           -- 子品目ID
  gt_bef_lot                   xxcoi_lot_reception_monthly.lot%TYPE;                     -- ロット
  gt_bef_diff_sum_code         xxcoi_lot_reception_monthly.difference_summary_code%TYPE; -- 固有記号
--
  -- 受払項目計算結果保持用変数
  gt_factory_stock             xxcoi_lot_reception_monthly.factory_stock%TYPE;           -- 工場入庫
  gt_factory_stock_b           xxcoi_lot_reception_monthly.factory_stock_b%TYPE;         -- 工場入庫振戻
  gt_change_stock              xxcoi_lot_reception_monthly.change_stock%TYPE;            -- 倉替入庫
  gt_others_stock              xxcoi_lot_reception_monthly.others_stock%TYPE;            -- 入出庫＿その他入庫
  gt_truck_stock               xxcoi_lot_reception_monthly.truck_stock%TYPE;             -- 営業車より入庫
  gt_truck_ship                xxcoi_lot_reception_monthly.truck_ship%TYPE;              -- 営業車へ出庫
  gt_sales_shipped             xxcoi_lot_reception_monthly.sales_shipped%TYPE;           -- 売上出庫
  gt_sales_shipped_b           xxcoi_lot_reception_monthly.sales_shipped_b%TYPE;         -- 売上出庫振戻
  gt_return_goods              xxcoi_lot_reception_monthly.return_goods%TYPE;            -- 返品
  gt_return_goods_b            xxcoi_lot_reception_monthly.return_goods_b%TYPE;          -- 返品振戻
  gt_customer_sample_ship      xxcoi_lot_reception_monthly.customer_sample_ship%TYPE;    -- 顧客見本出庫
  gt_customer_sample_ship_b    xxcoi_lot_reception_monthly.customer_sample_ship_b%TYPE;  -- 顧客見本出庫振戻
  gt_customer_support_ss       xxcoi_lot_reception_monthly.customer_support_ss%TYPE;     -- 顧客協賛見本出庫
  gt_customer_support_ss_b     xxcoi_lot_reception_monthly.customer_support_ss_b%TYPE;   -- 顧客協賛見本出庫振戻
  gt_ccm_sample_ship           xxcoi_lot_reception_monthly.ccm_sample_ship%TYPE;         -- 顧客広告宣伝費A自社商品
  gt_ccm_sample_ship_b         xxcoi_lot_reception_monthly.ccm_sample_ship_b%TYPE;       -- 顧客広告宣伝費A自社商品振戻
  gt_vd_supplement_stock       xxcoi_lot_reception_monthly.vd_supplement_stock%TYPE;     -- 消化VD補充入庫
  gt_vd_supplement_ship        xxcoi_lot_reception_monthly.vd_supplement_ship%TYPE;      -- 消化VD補充出庫
  gt_removed_goods             xxcoi_lot_reception_monthly.removed_goods%TYPE;           -- 廃却
  gt_removed_goods_b           xxcoi_lot_reception_monthly.removed_goods_b%TYPE;         -- 廃却振戻
  gt_change_ship               xxcoi_lot_reception_monthly.change_ship%TYPE;             -- 倉替出庫
  gt_others_ship               xxcoi_lot_reception_monthly.others_ship%TYPE;             -- 入出庫＿その他出庫
  gt_factory_change            xxcoi_lot_reception_monthly.factory_change%TYPE;          -- 工場倉替
  gt_factory_change_b          xxcoi_lot_reception_monthly.factory_change_b%TYPE;        -- 工場倉替振戻
  gt_factory_return            xxcoi_lot_reception_monthly.factory_return%TYPE;          -- 工場返品
  gt_factory_return_b          xxcoi_lot_reception_monthly.factory_return_b%TYPE;        -- 工場返品振戻
  gt_location_decrease         xxcoi_lot_reception_monthly.location_decrease%TYPE;       -- ロケーション移動増
  gt_location_increase         xxcoi_lot_reception_monthly.location_increase%TYPE;       -- ロケーション移動減
  gt_adjust_decrease           xxcoi_lot_reception_monthly.adjust_decrease%TYPE;         -- 在庫調整増
  gt_adjust_increase           xxcoi_lot_reception_monthly.adjust_increase%TYPE;         -- 在庫調整減
  gt_book_inventory_quantity   xxcoi_lot_reception_monthly.book_inventory_quantity%TYPE; -- 帳簿在庫数
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 受払対象データ取得カーソル（定期実行）
  CURSOR get_rep_data_1_cur IS
    SELECT xlt.transaction_month             trx_month             -- 取引年月
          ,xlt.base_code                     base_code             -- 拠点コード
          ,xlt.subinventory_code             subinv_code           -- 保管場所コード
          ,msi1.attribute1                   subinv_type           -- 保管場所区分
          ,xlt.location_code                 location_code         -- ロケーションコード
          ,xlt.parent_item_id                parent_item_id        -- 親品目ID
          ,xlt.child_item_id                 child_item_id         -- 子品目ID
          ,xlt.lot                           lot                   -- ロット
          ,xlt.difference_summary_code       diff_sum_code         -- 固有記号
          ,xlt.transfer_subinventory         tran_subinv           -- 転送先保管場所コード
          ,msi2.attribute1                   tran_subinv_kbn       -- 転送先保管場所区分
          ,xlt.transaction_type_code         trx_type_code         -- 取引タイプコード
          ,xlt.reserve_transaction_type_code reserve_trx_type_code -- 引当時取引タイプコード
          ,SUM(xlt.summary_qty)              rep_qty               -- 受払数量
    FROM   xxcoi_lot_transactions    xlt                           -- ロット別取引明細
          ,mtl_secondary_inventories msi1                          -- 保管場所
          ,mtl_secondary_inventories msi2                          -- 転送先保管場所
          ,org_acct_periods          oap                           -- 在庫会計期間テーブル
    WHERE  xlt.transaction_id        > gt_pre_exe_id               -- 前回取引IDより大きい
    AND    xlt.organization_id       = gt_org_id                   -- 初期処理で取得した在庫組織ID
    AND    xlt.subinventory_code     = msi1.secondary_inventory_name
    AND    xlt.organization_id       = msi1.organization_id
    AND    xlt.transfer_subinventory = msi2.secondary_inventory_name(+)
    AND    xlt.organization_id       = msi2.organization_id(+)
    AND    xlt.transaction_month     = TO_CHAR( oap.period_start_date, cv_yyyymm )
    AND    xlt.organization_id       = oap.organization_id
    AND    oap.open_flag             = cv_flag_y                   -- 在庫会計期間オープンフラグ：Y
    GROUP BY
      xlt.transaction_month                                        -- 取引年月
     ,xlt.base_code                                                -- 拠点コード
     ,xlt.subinventory_code                                        -- 保管場所コード
     ,msi1.attribute1                                              -- 保管場所区分
     ,xlt.location_code                                            -- ロケーションコード
     ,xlt.parent_item_id                                           -- 親品目ID
     ,xlt.child_item_id                                            -- 子品目ID
     ,xlt.lot                                                      -- ロット
     ,xlt.difference_summary_code                                  -- 固有記号
     ,xlt.transfer_subinventory                                    -- 転送先保管場所コード
     ,msi2.attribute1                                              -- 転送先保管場所区分
     ,xlt.transaction_type_code                                    -- 取引タイプコード
     ,xlt.reserve_transaction_type_code                            -- 引当時取引タイプコード
    ORDER BY
      xlt.transaction_month                                        -- 取引年月
     ,xlt.base_code                                                -- 拠点コード
     ,xlt.subinventory_code                                        -- 保管場所コード
     ,xlt.location_code                                            -- ロケーションコード
     ,xlt.parent_item_id                                           -- 親品目ID
     ,xlt.child_item_id                                            -- 子品目ID
     ,xlt.lot                                                      -- ロット
     ,xlt.difference_summary_code                                  -- 固有記号
  ;
--
  -- 受払対象データ取得カーソル（随時実行）
  CURSOR get_rep_data_2_cur IS
    SELECT xlt.transaction_month             trx_month             -- 取引年月
          ,xlt.base_code                     base_code             -- 拠点コード
          ,xlt.subinventory_code             subinv_code           -- 保管場所コード
          ,msi1.attribute1                   subinv_type           -- 保管場所区分
          ,xlt.location_code                 location_code         -- ロケーションコード
          ,xlt.parent_item_id                parent_item_id        -- 親品目ID
          ,xlt.child_item_id                 child_item_id         -- 子品目ID
          ,xlt.lot                           lot                   -- ロット
          ,xlt.difference_summary_code       diff_sum_code         -- 固有記号
          ,xlt.transfer_subinventory         tran_subinv           -- 転送先保管場所コード
          ,msi2.attribute1                   tran_subinv_kbn       -- 転送先保管場所区分
          ,xlt.transaction_type_code         trx_type_code         -- 取引タイプコード
          ,xlt.reserve_transaction_type_code reserve_trx_type_code -- 引当時取引タイプコード
          ,SUM(xlt.summary_qty)              rep_qty               -- 受払数量
    FROM   xxcoi_lot_transactions    xlt                           -- ロット別取引明細
          ,mtl_secondary_inventories msi1                          -- 保管場所
          ,mtl_secondary_inventories msi2                          -- 転送先保管場所
          ,org_acct_periods          oap                           -- 在庫会計期間テーブル
    WHERE  xlt.transaction_id        > gt_pre_exe_id               -- 前回取引IDより大きい
    AND    xlt.organization_id       = gt_org_id                   -- 初期処理で取得した在庫組織ID
    AND    xlt.base_code             = gt_base_code                -- 入力パラメータ：拠点
    AND    xlt.subinventory_code     = gt_subinv_code              -- 入力パラメータ：保管場所
    AND    xlt.subinventory_code     = msi1.secondary_inventory_name
    AND    xlt.organization_id       = msi1.organization_id
    AND    xlt.transfer_subinventory = msi2.secondary_inventory_name(+)
    AND    xlt.organization_id       = msi2.organization_id(+)
    AND    xlt.transaction_month     = TO_CHAR( oap.period_start_date, cv_yyyymm )
    AND    xlt.organization_id       = oap.organization_id
    AND    oap.open_flag             = cv_flag_y                   -- 在庫会計期間オープンフラグ：Y
    GROUP BY
      xlt.transaction_month                                        -- 取引年月
     ,xlt.base_code                                                -- 拠点コード
     ,xlt.subinventory_code                                        -- 保管場所コード
     ,msi1.attribute1                                              -- 保管場所区分
     ,xlt.location_code                                            -- ロケーションコード
     ,xlt.parent_item_id                                           -- 親品目ID
     ,xlt.child_item_id                                            -- 子品目ID
     ,xlt.lot                                                      -- ロット
     ,xlt.difference_summary_code                                  -- 固有記号
     ,xlt.transfer_subinventory                                    -- 転送先保管場所コード
     ,msi2.attribute1                                              -- 転送先保管場所区分
     ,xlt.transaction_type_code                                    -- 取引タイプコード
     ,xlt.reserve_transaction_type_code                            -- 引当時取引タイプコード
    ORDER BY
      xlt.transaction_month                                        -- 取引年月
     ,xlt.base_code                                                -- 拠点コード
     ,xlt.subinventory_code                                        -- 保管場所コード
     ,xlt.location_code                                            -- ロケーションコード
     ,xlt.parent_item_id                                           -- 親品目ID
     ,xlt.child_item_id                                            -- 子品目ID
     ,xlt.lot                                                      -- ロット
     ,xlt.difference_summary_code                                  -- 固有記号
  ;
--
  -- 受払対象データ取得結果保持レコード
  g_get_rep_data_rec get_rep_data_1_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : proc_end
   * Description      : 終了処理(A-6)
   ***********************************************************************************/
  PROCEDURE proc_end(
    ov_errbuf     OUT VARCHAR2 --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2 --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2 --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_end'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- データ連携制御テーブル更新
    --==============================================================
    UPDATE xxcoi_cooperation_control xcc
    SET    xcc.last_cooperation_date  = gd_proc_date              -- 最終連携日時：業務日付
          ,xcc.transaction_id         = gt_max_trx_id             -- 取引ID：最大取引ID
          ,xcc.last_updated_by        = cn_last_updated_by        -- 最終更新者
          ,xcc.last_update_date       = cd_last_update_date       -- 最終更新日
          ,xcc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
          ,xcc.request_id             = cn_request_id             -- 要求ID
          ,xcc.program_application_id = cn_program_application_id -- アプリケーションID
          ,xcc.program_id             = cn_program_id             -- プログラムID
          ,xcc.program_update_date    = cd_program_update_date    -- プログラム更新日
    WHERE  xcc.program_short_name     = cv_pkg_name               -- プログラム名
    ;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_end;
--
  /**********************************************************************************
   * Procedure Name   : cre_inout_data
   * Description      : ロット別受払（月次）データ登録・更新処理 (A-5)
   ***********************************************************************************/
  PROCEDURE cre_inout_data(
    ov_errbuf     OUT VARCHAR2 --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2 --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2 --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cre_inout_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_exist_chk1       NUMBER;      -- ロット別受払（月次）存在チェック
    ln_exist_chk2       NUMBER;      -- ロット別受払（月次）当月データ存在チェック
    lv_proc_date_yyyymm VARCHAR2(6); -- 業務日付YYYYMM型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    ln_exist_chk1       := 0;                                  -- ロット別受払（月次）存在チェック
    ln_exist_chk2       := 0;                                  -- ロット別受払（月次）当月データ存在チェック
    lv_proc_date_yyyymm := TO_CHAR( gd_proc_date, cv_yyyymm ); -- 業務日付YYYYMM型
--
    --==============================================================
    -- 処理対象のデータが存在するかチェック
    --==============================================================
    SELECT COUNT(1)
    INTO   ln_exist_chk1                                           -- ロット別受払（月次）存在チェック
    FROM   xxcoi_lot_reception_monthly xlrm
    WHERE  xlrm.practice_month          = gt_bef_practice_month    -- 取引年月
    AND    xlrm.base_code               = gt_bef_base_code         -- 拠点コード
    AND    xlrm.subinventory_code       = gt_bef_subinventory_code -- 保管場所コード
    AND    xlrm.location_code           = gt_bef_location_code     -- ロケーションコード
    AND    xlrm.parent_item_id          = gt_bef_parent_item_id    -- 親品目ID
    AND    xlrm.child_item_id           = gt_bef_child_item_id     -- 子品目ID
    AND    xlrm.lot                     = gt_bef_lot               -- ロット
    AND    xlrm.difference_summary_code = gt_bef_diff_sum_code     -- 固有記号
    AND    xlrm.data_type               = gt_startup_flg           -- データ区分
    AND    ROWNUM                       = 1
    ;
--
    -- 対象データが存在しない場合は、新規作成
    IF ( ln_exist_chk1 = 0 ) THEN
      --==============================================================
      -- ロット別受払（月次）新規作成
      --==============================================================
      INSERT INTO xxcoi_lot_reception_monthly(
        base_code                                               -- 拠点コード
       ,organization_id                                         -- 在庫組織ID
       ,subinventory_code                                       -- 保管場所コード
       ,subinventory_type                                       -- 保管場所区分
       ,location_code                                           -- ロケーションコード
       ,practice_month                                          -- 年月
       ,practice_date                                           -- 年月日
       ,parent_item_id                                          -- 親品目ID
       ,child_item_id                                           -- 子品目ID
       ,lot                                                     -- ロット
       ,difference_summary_code                                 -- 固有記号
       ,month_begin_quantity                                    -- 月首棚卸高
       ,factory_stock                                           -- 工場入庫
       ,factory_stock_b                                         -- 工場入庫振戻
       ,change_stock                                            -- 倉替入庫
       ,others_stock                                            -- 入出庫＿その他入庫
       ,truck_stock                                             -- 営業車より入庫
       ,truck_ship                                              -- 営業車へ出庫
       ,sales_shipped                                           -- 売上出庫
       ,sales_shipped_b                                         -- 売上出庫振戻
       ,return_goods                                            -- 返品
       ,return_goods_b                                          -- 返品振戻
       ,customer_sample_ship                                    -- 顧客見本出庫
       ,customer_sample_ship_b                                  -- 顧客見本出庫振戻
       ,customer_support_ss                                     -- 顧客協賛見本出庫
       ,customer_support_ss_b                                   -- 顧客協賛見本出庫振戻
       ,ccm_sample_ship                                         -- 顧客広告宣伝費A自社商品
       ,ccm_sample_ship_b                                       -- 顧客広告宣伝費A自社商品振戻
       ,vd_supplement_stock                                     -- 消化VD補充入庫
       ,vd_supplement_ship                                      -- 消化VD補充出庫
       ,removed_goods                                           -- 廃却
       ,removed_goods_b                                         -- 廃却振戻
       ,change_ship                                             -- 倉替出庫
       ,others_ship                                             -- 入出庫＿その他出庫
       ,factory_change                                          -- 工場倉替
       ,factory_change_b                                        -- 工場倉替振戻
       ,factory_return                                          -- 工場返品
       ,factory_return_b                                        -- 工場返品振戻
       ,location_decrease                                       -- ロケーション移動増
       ,location_increase                                       -- ロケーション移動減
       ,adjust_decrease                                         -- 在庫調整増
       ,adjust_increase                                         -- 在庫調整減
       ,book_inventory_quantity                                 -- 帳簿在庫数
       ,data_type                                               -- データ区分
       ,created_by                                              -- 作成者
       ,creation_date                                           -- 作成日
       ,last_updated_by                                         -- 最終更新者
       ,last_update_date                                        -- 最終更新日
       ,last_update_login                                       -- 最終更新ログイン
       ,request_id                                              -- 要求ID
       ,program_application_id                                  -- コンカレント・プログラム・アプリケーションID
       ,program_id                                              -- コンカレント・プログラムID
       ,program_update_date                                     -- プログラム更新日
      )VALUES(
        gt_bef_base_code                                        -- 拠点コード
       ,gt_org_id                                               -- 在庫組織ID
       ,gt_bef_subinventory_code                                -- 保管場所コード
       ,gt_bef_subinv_type                                      -- 保管場所区分
       ,gt_bef_location_code                                    -- ロケーションコード
       ,gt_bef_practice_month                                   -- 年月
       ,LAST_DAY( TO_DATE( gt_bef_practice_month, cv_yyyymm ) ) -- 年月日
       ,gt_bef_parent_item_id                                   -- 親品目ID
       ,gt_bef_child_item_id                                    -- 子品目ID
       ,gt_bef_lot                                              -- ロット
       ,gt_bef_diff_sum_code                                    -- 固有記号
       ,0                                                       -- 月首棚卸高
       ,gt_factory_stock                                        -- 工場入庫
       ,(gt_factory_stock_b) * cn_minus_1                       -- 工場入庫振戻
       ,gt_change_stock                                         -- 倉替入庫
       ,gt_others_stock                                         -- 入出庫＿その他入庫
       ,gt_truck_stock                                          -- 営業車より入庫
       ,(gt_truck_ship) * cn_minus_1                            -- 営業車へ出庫
       ,(gt_sales_shipped) * cn_minus_1                         -- 売上出庫
       ,gt_sales_shipped_b                                      -- 売上出庫振戻
       ,gt_return_goods                                         -- 返品
       ,(gt_return_goods_b) * cn_minus_1                        -- 返品振戻
       ,(gt_customer_sample_ship) * cn_minus_1                  -- 顧客見本出庫
       ,gt_customer_sample_ship_b                               -- 顧客見本出庫振戻
       ,(gt_customer_support_ss) * cn_minus_1                   -- 顧客協賛見本出庫
       ,gt_customer_support_ss_b                                -- 顧客協賛見本出庫振戻
       ,(gt_ccm_sample_ship) * cn_minus_1                       -- 顧客広告宣伝費A自社商品
       ,gt_ccm_sample_ship_b                                    -- 顧客広告宣伝費A自社商品振戻
       ,gt_vd_supplement_stock                                  -- 消化VD補充入庫
       ,(gt_vd_supplement_ship) * cn_minus_1                    -- 消化VD補充出庫
       ,(gt_removed_goods) * cn_minus_1                         -- 廃却
       ,gt_removed_goods_b                                      -- 廃却振戻
       ,(gt_change_ship) * cn_minus_1                           -- 倉替出庫
       ,(gt_others_ship) * cn_minus_1                           -- 入出庫＿その他出庫
       ,(gt_factory_change) * cn_minus_1                        -- 工場倉替
       ,gt_factory_change_b                                     -- 工場倉替振戻
       ,(gt_factory_return) * cn_minus_1                        -- 工場返品
       ,gt_factory_return_b                                     -- 工場返品振戻
       ,gt_location_decrease                                    -- ロケーション移動増
       ,(gt_location_increase) * cn_minus_1                     -- ロケーション移動減
       ,gt_adjust_decrease                                      -- 在庫調整増
       ,(gt_adjust_increase) * cn_minus_1                       -- 在庫調整減
       ,gt_book_inventory_quantity                              -- 帳簿在庫数
       ,gt_startup_flg                                          -- データ区分
       ,cn_created_by                                           -- 作成者
       ,cd_creation_date                                        -- 作成日
       ,cn_last_updated_by                                      -- 最終更新者
       ,cd_last_update_date                                     -- 最終更新日
       ,cn_last_update_login                                    -- 最終更新ログイン
       ,cn_request_id                                           -- 要求ID
       ,cn_program_application_id                               -- コンカレント・プログラム・アプリケーションID
       ,cn_program_id                                           -- コンカレント・プログラムID
       ,cd_program_update_date                                  -- プログラム更新日
      );
--
      -- 成功件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;
--
    -- 対象データが存在する場合は、更新
    ELSE
      --==============================================================
      -- ロット別受払（月次）更新
      --==============================================================
      UPDATE xxcoi_lot_reception_monthly xlrm
      SET    xlrm.factory_stock           = xlrm.factory_stock           + gt_factory_stock
                                                                 -- 工場入庫
            ,xlrm.factory_stock_b         = xlrm.factory_stock_b         + (gt_factory_stock_b) * cn_minus_1
                                                                 -- 工場入庫振戻
            ,xlrm.change_stock            = xlrm.change_stock            + gt_change_stock
                                                                 -- 倉替入庫
            ,xlrm.others_stock            = xlrm.others_stock            + gt_others_stock
                                                                 -- 入出庫＿その他入庫
            ,xlrm.truck_stock             = xlrm.truck_stock             + gt_truck_stock
                                                                 -- 営業車より入庫
            ,xlrm.truck_ship              = xlrm.truck_ship              + (gt_truck_ship) * cn_minus_1
                                                                 -- 営業車へ出庫
            ,xlrm.sales_shipped           = xlrm.sales_shipped           + (gt_sales_shipped) * cn_minus_1
                                                                 -- 売上出庫
            ,xlrm.sales_shipped_b         = xlrm.sales_shipped_b         + gt_sales_shipped_b
                                                                 -- 売上出庫振戻
            ,xlrm.return_goods            = xlrm.return_goods            + gt_return_goods
                                                                 -- 返品
            ,xlrm.return_goods_b          = xlrm.return_goods_b          + (gt_return_goods_b) * cn_minus_1
                                                                 -- 返品振戻
            ,xlrm.customer_sample_ship    = xlrm.customer_sample_ship    + (gt_customer_sample_ship) * cn_minus_1
                                                                 -- 顧客見本出庫
            ,xlrm.customer_sample_ship_b  = xlrm.customer_sample_ship_b  + gt_customer_sample_ship_b
                                                                 -- 顧客見本出庫振戻
            ,xlrm.customer_support_ss     = xlrm.customer_support_ss     + (gt_customer_support_ss) * cn_minus_1
                                                                 -- 顧客協賛見本出庫
            ,xlrm.customer_support_ss_b   = xlrm.customer_support_ss_b   + gt_customer_support_ss_b
                                                                 -- 顧客協賛見本出庫振戻
            ,xlrm.ccm_sample_ship         = xlrm.ccm_sample_ship         + (gt_ccm_sample_ship) * cn_minus_1
                                                                 -- 顧客広告宣伝費A自社商品
            ,xlrm.ccm_sample_ship_b       = xlrm.ccm_sample_ship_b       + gt_ccm_sample_ship_b
                                                                 -- 顧客広告宣伝費A自社商品振戻
            ,xlrm.vd_supplement_stock     = xlrm.vd_supplement_stock     + gt_vd_supplement_stock
                                                                 -- 消化VD補充入庫
            ,xlrm.vd_supplement_ship      = xlrm.vd_supplement_ship      + (gt_vd_supplement_ship) * cn_minus_1
                                                                 -- 消化VD補充出庫
            ,xlrm.removed_goods           = xlrm.removed_goods           + (gt_removed_goods) * cn_minus_1
                                                                 -- 廃却
            ,xlrm.removed_goods_b         = xlrm.removed_goods_b         + gt_removed_goods_b
                                                                 -- 廃却振戻
            ,xlrm.change_ship             = xlrm.change_ship             + (gt_change_ship) * cn_minus_1
                                                                 -- 倉替出庫
            ,xlrm.others_ship             = xlrm.others_ship             + (gt_others_ship) * cn_minus_1
                                                                 -- 入出庫＿その他出庫
            ,xlrm.factory_change          = xlrm.factory_change          + (gt_factory_change) * cn_minus_1
                                                                 -- 工場倉替
            ,xlrm.factory_change_b        = xlrm.factory_change_b        + gt_factory_change_b
                                                                 -- 工場倉替振戻
            ,xlrm.factory_return          = xlrm.factory_return          + (gt_factory_return) * cn_minus_1
                                                                 -- 工場返品
            ,xlrm.factory_return_b        = xlrm.factory_return_b        + gt_factory_return_b
                                                                 -- 工場返品振戻
            ,xlrm.location_decrease       = xlrm.location_decrease       + gt_location_decrease
                                                                 -- ロケーション移動増
            ,xlrm.location_increase       = xlrm.location_increase       + (gt_location_increase) * cn_minus_1
                                                                 -- ロケーション移動減
            ,xlrm.adjust_decrease         = xlrm.adjust_decrease         + gt_adjust_decrease
                                                                 -- 在庫調整増
            ,xlrm.adjust_increase         = xlrm.adjust_increase         + (gt_adjust_increase) * cn_minus_1
                                                                 -- 在庫調整減
            ,xlrm.book_inventory_quantity = xlrm.book_inventory_quantity + gt_book_inventory_quantity
                                                                 -- 帳簿在庫数
            ,xlrm.last_updated_by         = cn_last_updated_by        -- 最終更新者
            ,xlrm.last_update_date        = cd_last_update_date       -- 最終更新日
            ,xlrm.last_update_login       = cn_last_update_login      -- 最終更新ログイン
            ,xlrm.request_id              = cn_request_id             -- 要求ID
            ,xlrm.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
            ,xlrm.program_id              = cn_program_id             -- コンカレント・プログラムID
            ,xlrm.program_update_date     = cd_program_update_date    -- プログラム更新日
      WHERE  xlrm.practice_month          = gt_bef_practice_month     -- 取引年月
      AND    xlrm.base_code               = gt_bef_base_code          -- 拠点コード
      AND    xlrm.subinventory_code       = gt_bef_subinventory_code  -- 保管場所コード
      AND    xlrm.location_code           = gt_bef_location_code      -- ロケーションコード
      AND    xlrm.parent_item_id          = gt_bef_parent_item_id     -- 親品目ID
      AND    xlrm.child_item_id           = gt_bef_child_item_id      -- 子品目ID
      AND    xlrm.lot                     = gt_bef_lot                -- ロット
      AND    xlrm.difference_summary_code = gt_bef_diff_sum_code      -- 固有記号
      AND    xlrm.data_type               = gt_startup_flg            -- データ区分
      ;
--
      -- 成功件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
--
    -- 処理対象の取引年月が業務日付より過去日の場合
    IF ( gt_bef_practice_month < lv_proc_date_yyyymm ) THEN
      --==============================================================
      -- 処理対象のデータで、当月データが存在するかチェック
      --==============================================================
      SELECT COUNT(1)
      INTO   ln_exist_chk2                                           -- ロット別受払（月次）存在チェック
      FROM   xxcoi_lot_reception_monthly xlrm
      WHERE  xlrm.practice_month          = lv_proc_date_yyyymm      -- 業務日付
      AND    xlrm.base_code               = gt_bef_base_code         -- 拠点コード
      AND    xlrm.subinventory_code       = gt_bef_subinventory_code -- 保管場所コード
      AND    xlrm.location_code           = gt_bef_location_code     -- ロケーションコード
      AND    xlrm.parent_item_id          = gt_bef_parent_item_id    -- 親品目ID
      AND    xlrm.child_item_id           = gt_bef_child_item_id     -- 子品目ID
      AND    xlrm.lot                     = gt_bef_lot               -- ロット
      AND    xlrm.difference_summary_code = gt_bef_diff_sum_code     -- 固有記号
      AND    xlrm.data_type               = gt_startup_flg           -- データ区分
      AND    ROWNUM                       = 1
      ;
--
      -- 対象データが存在しない場合は、新規作成
      IF ( ln_exist_chk2 = 0 ) THEN
        --==============================================================
        -- ロット別受払（月次）新規作成
        --==============================================================
        INSERT INTO xxcoi_lot_reception_monthly(
          base_code                  -- 拠点コード
         ,organization_id            -- 在庫組織ID
         ,subinventory_code          -- 保管場所コード
         ,subinventory_type          -- 保管場所区分
         ,location_code              -- ロケーションコード
         ,practice_month             -- 年月
         ,practice_date              -- 年月日
         ,parent_item_id             -- 親品目ID
         ,child_item_id              -- 子品目ID
         ,lot                        -- ロット
         ,difference_summary_code    -- 固有記号
         ,month_begin_quantity       -- 月首棚卸高
         ,factory_stock              -- 工場入庫
         ,factory_stock_b            -- 工場入庫振戻
         ,change_stock               -- 倉替入庫
         ,others_stock               -- 入出庫＿その他入庫
         ,truck_stock                -- 営業車より入庫
         ,truck_ship                 -- 営業車へ出庫
         ,sales_shipped              -- 売上出庫
         ,sales_shipped_b            -- 売上出庫振戻
         ,return_goods               -- 返品
         ,return_goods_b             -- 返品振戻
         ,customer_sample_ship       -- 顧客見本出庫
         ,customer_sample_ship_b     -- 顧客見本出庫振戻
         ,customer_support_ss        -- 顧客協賛見本出庫
         ,customer_support_ss_b      -- 顧客協賛見本出庫振戻
         ,ccm_sample_ship            -- 顧客広告宣伝費A自社商品
         ,ccm_sample_ship_b          -- 顧客広告宣伝費A自社商品振戻
         ,vd_supplement_stock        -- 消化VD補充入庫
         ,vd_supplement_ship         -- 消化VD補充出庫
         ,removed_goods              -- 廃却
         ,removed_goods_b            -- 廃却振戻
         ,change_ship                -- 倉替出庫
         ,others_ship                -- 入出庫＿その他出庫
         ,factory_change             -- 工場倉替
         ,factory_change_b           -- 工場倉替振戻
         ,factory_return             -- 工場返品
         ,factory_return_b           -- 工場返品振戻
         ,location_decrease          -- ロケーション移動増
         ,location_increase          -- ロケーション移動減
         ,adjust_decrease            -- 在庫調整増
         ,adjust_increase            -- 在庫調整減
         ,book_inventory_quantity    -- 帳簿在庫数
         ,data_type                  -- データ区分
         ,created_by                 -- 作成者
         ,creation_date              -- 作成日
         ,last_updated_by            -- 最終更新者
         ,last_update_date           -- 最終更新日
         ,last_update_login          -- 最終更新ログイン
         ,request_id                 -- 要求ID
         ,program_application_id     -- コンカレント・プログラム・アプリケーションID
         ,program_id                 -- コンカレント・プログラムID
         ,program_update_date        -- プログラム更新日
        )VALUES(
          gt_bef_base_code           -- 拠点コード
         ,gt_org_id                  -- 在庫組織ID
         ,gt_bef_subinventory_code   -- 保管場所コード
         ,gt_bef_subinv_type         -- 保管場所区分
         ,gt_bef_location_code       -- ロケーションコード
         ,lv_proc_date_yyyymm        -- 年月
         ,LAST_DAY( gd_proc_date )   -- 年月日
         ,gt_bef_parent_item_id      -- 親品目ID
         ,gt_bef_child_item_id       -- 子品目ID
         ,gt_bef_lot                 -- ロット
         ,gt_bef_diff_sum_code       -- 固有記号
         ,gt_book_inventory_quantity -- 月首棚卸高
         ,0                          -- 工場入庫
         ,0                          -- 工場入庫振戻
         ,0                          -- 倉替入庫
         ,0                          -- 入出庫＿その他入庫
         ,0                          -- 営業車より入庫
         ,0                          -- 営業車へ出庫
         ,0                          -- 売上出庫
         ,0                          -- 売上出庫振戻
         ,0                          -- 返品
         ,0                          -- 返品振戻
         ,0                          -- 顧客見本出庫
         ,0                          -- 顧客見本出庫振戻
         ,0                          -- 顧客協賛見本出庫
         ,0                          -- 顧客協賛見本出庫振戻
         ,0                          -- 顧客広告宣伝費A自社商品
         ,0                          -- 顧客広告宣伝費A自社商品
         ,0                          -- 消化VD補充入庫
         ,0                          -- 消化VD補充出庫
         ,0                          -- 廃却
         ,0                          -- 廃却振戻
         ,0                          -- 倉替出庫
         ,0                          -- 入出庫＿その他出庫
         ,0                          -- 工場倉替
         ,0                          -- 工場倉替振戻
         ,0                          -- 工場返品
         ,0                          -- 工場返品振戻
         ,0                          -- ロケーション移動増
         ,0                          -- ロケーション移動減
         ,0                          -- 在庫調整増
         ,0                          -- 在庫調整減
         ,gt_book_inventory_quantity -- 帳簿在庫数
         ,gt_startup_flg             -- データ区分
         ,cn_created_by              -- 作成者
         ,cd_creation_date           -- 作成日
         ,cn_last_updated_by         -- 最終更新者
         ,cd_last_update_date        -- 最終更新日
         ,cn_last_update_login       -- 最終更新ログイン
         ,cn_request_id              -- 要求ID
         ,cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,cn_program_id              -- コンカレント・プログラムID
         ,cd_program_update_date     -- プログラム更新日
        );
--
        -- 成功件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      -- 対象データが存在する場合は、更新
      ELSE
        --==============================================================
        -- ロット別受払（月次）更新
        --==============================================================
        UPDATE xxcoi_lot_reception_monthly xlrm
        SET    xlrm.month_begin_quantity    = xlrm.month_begin_quantity    + gt_book_inventory_quantity
                                                                   -- 月首棚卸高
              ,xlrm.book_inventory_quantity = xlrm.book_inventory_quantity + gt_book_inventory_quantity
                                                                   -- 帳簿在庫数
              ,xlrm.last_updated_by         = cn_last_updated_by        -- 最終更新者
              ,xlrm.last_update_date        = cd_last_update_date       -- 最終更新日
              ,xlrm.last_update_login       = cn_last_update_login      -- 最終更新ログイン
              ,xlrm.request_id              = cn_request_id             -- 要求ID
              ,xlrm.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
              ,xlrm.program_id              = cn_program_id             -- コンカレント・プログラムID
              ,xlrm.program_update_date     = cd_program_update_date    -- プログラム更新日
        WHERE  xlrm.practice_month          = lv_proc_date_yyyymm       -- 業務日付
        AND    xlrm.base_code               = gt_bef_base_code          -- 拠点コード
        AND    xlrm.subinventory_code       = gt_bef_subinventory_code  -- 保管場所コード
        AND    xlrm.location_code           = gt_bef_location_code      -- ロケーションコード
        AND    xlrm.parent_item_id          = gt_bef_parent_item_id     -- 親品目ID
        AND    xlrm.child_item_id           = gt_bef_child_item_id      -- 子品目ID
        AND    xlrm.lot                     = gt_bef_lot                -- ロット
        AND    xlrm.difference_summary_code = gt_bef_diff_sum_code      -- 固有記号
        AND    xlrm.data_type               = gt_startup_flg            -- データ区分
        ;
--
        -- 成功件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END IF;
--
    -- 変数のリセット
    -- 前レコードロット情報保持用変数
    gt_bef_practice_month      := NULL;      -- 取引年月
    gt_bef_base_code           := NULL;      -- 拠点コード
    gt_bef_subinventory_code   := NULL;      -- 保管場所コード
    gt_bef_subinv_type         := NULL;      -- 保管場所区分
    gt_bef_location_code       := NULL;      -- ロケーションコード
    gt_bef_parent_item_id      := NULL;      -- 親品目ID
    gt_bef_child_item_id       := NULL;      -- 子品目ID
    gt_bef_lot                 := NULL;      -- ロット
    gt_bef_diff_sum_code       := NULL;      -- 固有記号
--
    -- 受払項目計算結果保持用変数
    gt_factory_stock           := 0;         -- 工場入庫
    gt_factory_stock_b         := 0;         -- 工場入庫振戻
    gt_change_stock            := 0;         -- 倉替入庫
    gt_others_stock            := 0;         -- 入出庫＿その他入庫
    gt_truck_stock             := 0;         -- 営業車より入庫
    gt_truck_ship              := 0;         -- 営業車へ出庫
    gt_sales_shipped           := 0;         -- 売上出庫
    gt_sales_shipped_b         := 0;         -- 売上出庫振戻
    gt_return_goods            := 0;         -- 返品
    gt_return_goods_b          := 0;         -- 返品振戻
    gt_customer_sample_ship    := 0;         -- 顧客見本出庫
    gt_customer_sample_ship_b  := 0;         -- 顧客見本出庫振戻
    gt_customer_support_ss     := 0;         -- 顧客協賛見本出庫
    gt_customer_support_ss_b   := 0;         -- 顧客協賛見本出庫振戻
    gt_ccm_sample_ship         := 0;         -- 顧客広告宣伝費A自社商品
    gt_ccm_sample_ship_b       := 0;         -- 顧客広告宣伝費A自社商品振戻
    gt_vd_supplement_stock     := 0;         -- 消化VD補充入庫
    gt_vd_supplement_ship      := 0;         -- 消化VD補充出庫
    gt_removed_goods           := 0;         -- 廃却
    gt_removed_goods_b         := 0;         -- 廃却振戻
    gt_change_ship             := 0;         -- 倉替出庫
    gt_others_ship             := 0;         -- 入出庫＿その他出庫
    gt_factory_change          := 0;         -- 工場倉替
    gt_factory_change_b        := 0;         -- 工場倉替振戻
    gt_factory_return          := 0;         -- 工場返品
    gt_factory_return_b        := 0;         -- 工場返品振戻
    gt_location_decrease       := 0;         -- ロケーション移動増
    gt_location_increase       := 0;         -- ロケーション移動減
    gt_adjust_decrease         := 0;         -- 在庫調整増
    gt_adjust_increase         := 0;         -- 在庫調整減
    gt_book_inventory_quantity := 0;         -- 帳簿在庫数
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END cre_inout_data;
--
  /**********************************************************************************
   * Procedure Name   : cal_inout_data
   * Description      : 受払項目算出処理 (A-4)
   ***********************************************************************************/
  PROCEDURE cal_inout_data(
    ov_errbuf     OUT VARCHAR2 --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2 --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2 --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cal_inout_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_not_exist_flag VARCHAR2(1); -- 最終レコードフラグ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    -- 前レコードロット情報保持用変数
    gt_bef_practice_month      := NULL;      -- 取引年月
    gt_bef_base_code           := NULL;      -- 拠点コード
    gt_bef_subinventory_code   := NULL;      -- 保管場所コード
    gt_bef_subinv_type         := NULL;      -- 保管場所区分
    gt_bef_location_code       := NULL;      -- ロケーションコード
    gt_bef_parent_item_id      := NULL;      -- 親品目ID
    gt_bef_child_item_id       := NULL;      -- 子品目ID
    gt_bef_lot                 := NULL;      -- ロット
    gt_bef_diff_sum_code       := NULL;      -- 固有記号
--
    -- 受払項目計算結果保持用変数
    gt_factory_stock           := 0;         -- 工場入庫
    gt_factory_stock_b         := 0;         -- 工場入庫振戻
    gt_change_stock            := 0;         -- 倉替入庫
    gt_others_stock            := 0;         -- 入出庫＿その他入庫
    gt_truck_stock             := 0;         -- 営業車より入庫
    gt_truck_ship              := 0;         -- 営業車へ出庫
    gt_sales_shipped           := 0;         -- 売上出庫
    gt_sales_shipped_b         := 0;         -- 売上出庫振戻
    gt_return_goods            := 0;         -- 返品
    gt_return_goods_b          := 0;         -- 返品振戻
    gt_customer_sample_ship    := 0;         -- 顧客見本出庫
    gt_customer_sample_ship_b  := 0;         -- 顧客見本出庫振戻
    gt_customer_support_ss     := 0;         -- 顧客協賛見本出庫
    gt_customer_support_ss_b   := 0;         -- 顧客協賛見本出庫振戻
    gt_ccm_sample_ship         := 0;         -- 顧客広告宣伝費A自社商品
    gt_ccm_sample_ship_b       := 0;         -- 顧客広告宣伝費A自社商品振戻
    gt_vd_supplement_stock     := 0;         -- 消化VD補充入庫
    gt_vd_supplement_ship      := 0;         -- 消化VD補充出庫
    gt_removed_goods           := 0;         -- 廃却
    gt_removed_goods_b         := 0;         -- 廃却振戻
    gt_change_ship             := 0;         -- 倉替出庫
    gt_others_ship             := 0;         -- 入出庫＿その他出庫
    gt_factory_change          := 0;         -- 工場倉替
    gt_factory_change_b        := 0;         -- 工場倉替振戻
    gt_factory_return          := 0;         -- 工場返品
    gt_factory_return_b        := 0;         -- 工場返品振戻
    gt_location_decrease       := 0;         -- ロケーション移動増
    gt_location_increase       := 0;         -- ロケーション移動減
    gt_adjust_decrease         := 0;         -- 在庫調整増
    gt_adjust_increase         := 0;         -- 在庫調整減
    gt_book_inventory_quantity := 0;         -- 帳簿在庫数
--
    -- ローカル変数
    lv_not_exist_flag          := cv_flag_n; -- 最終レコードフラグ
--
    -- ------------------------------------
    -- 1レコード目フェッチ
    -- ------------------------------------
    -- 定期実行時
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
      FETCH get_rep_data_1_cur INTO g_get_rep_data_rec;
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
    -- 随時実行時
    ELSE
      FETCH get_rep_data_2_cur INTO g_get_rep_data_rec;
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
    END IF;
--
    <<rep_data_loop>>
    LOOP
      --==============================================================
      -- 受払項目の計算
      --==============================================================
      -- 取引タイプ：入出庫
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_10 ) THEN
        -- ------------------------------------
        -- 転送先保管場所、受払数量の＋－で分岐
        -- ------------------------------------
        -- 営業車より入庫
        IF( g_get_rep_data_rec.tran_subinv_kbn = ct_subinv_kbn_2     -- 転送先保管場所区分：営業車
          AND g_get_rep_data_rec.rep_qty >= 0 ) THEN                 -- 受払数量がプラス
          gt_truck_stock := gt_truck_stock + g_get_rep_data_rec.rep_qty;
        -- 営業車へ出庫
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn = ct_subinv_kbn_2  -- 転送先保管場所区分：営業車
          AND g_get_rep_data_rec.rep_qty < 0 ) THEN                  -- 受払数量がマイナス
          gt_truck_ship := gt_truck_ship + g_get_rep_data_rec.rep_qty;
        -- 入出庫＿その他入庫
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn <> ct_subinv_kbn_2 -- 転送先保管場所区分：営業車以外
          AND g_get_rep_data_rec.rep_qty >= 0 ) THEN                 -- 受払数量がプラス
          gt_others_stock := gt_others_stock + g_get_rep_data_rec.rep_qty;
        -- 入出庫＿その他出庫
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn <> ct_subinv_kbn_2 -- 転送先保管場所区分：営業車以外
          AND g_get_rep_data_rec.rep_qty < 0 ) THEN                  -- 受払数量がマイナス
          gt_others_ship := gt_others_ship + g_get_rep_data_rec.rep_qty;
        END IF;
      END IF;
--
      -- 取引タイプ：倉替
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_20 ) THEN
        -- ------------------------------------
        -- 転送先保管場所、受払数量の＋－で分岐
        -- ------------------------------------
        -- 営業車より入庫
        IF( g_get_rep_data_rec.tran_subinv_kbn = ct_subinv_kbn_2     -- 転送先保管場所区分：営業車
          AND g_get_rep_data_rec.rep_qty >= 0 ) THEN                 -- 受払数量がプラス
          gt_truck_stock := gt_truck_stock + g_get_rep_data_rec.rep_qty;
        -- 営業車へ出庫
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn = ct_subinv_kbn_2  -- 転送先保管場所区分：営業車
          AND g_get_rep_data_rec.rep_qty < 0 ) THEN                  -- 受払数量がマイナス
          gt_truck_ship := gt_truck_ship + g_get_rep_data_rec.rep_qty;
        -- 倉替入庫
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn <> ct_subinv_kbn_2 -- 転送先保管場所区分：営業車以外
          AND g_get_rep_data_rec.rep_qty >= 0 ) THEN                 -- 受払数量がプラス
          gt_change_stock := gt_change_stock + g_get_rep_data_rec.rep_qty;
        -- 倉替出庫
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn <> ct_subinv_kbn_2 -- 転送先保管場所区分：営業車以外
          AND g_get_rep_data_rec.rep_qty < 0 ) THEN                  -- 受払数量がマイナス
          gt_change_ship := gt_change_ship + g_get_rep_data_rec.rep_qty;
        END IF;
      END IF;
--
      -- 取引タイプ：消化VD補充
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_70 ) THEN
        -- ------------------------------------
        -- 転送先保管場所、受払数量の＋－で分岐
        -- ------------------------------------
        -- 消化VD補充入庫
        IF ( g_get_rep_data_rec.rep_qty >= 0 ) THEN -- 受払数量がプラス
          gt_vd_supplement_stock := gt_vd_supplement_stock + g_get_rep_data_rec.rep_qty;
        -- 消化VD補充出庫
        ELSE                                        -- 受払数量がマイナス
          gt_vd_supplement_ship  := gt_vd_supplement_ship + g_get_rep_data_rec.rep_qty;
        END IF;
      END IF;
--
      -- 取引タイプ：工場返品
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_90 ) THEN
         gt_factory_return := gt_factory_return + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：工場返品振戻
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_100 ) THEN
         gt_factory_return_b := gt_factory_return_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：工場倉替
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_110 ) THEN
         gt_factory_change := gt_factory_change + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：工場倉替振戻
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_120 ) THEN
         gt_factory_change_b := gt_factory_change_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：廃却
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_130 ) THEN
         gt_removed_goods := gt_removed_goods + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：廃却振戻
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_140 ) THEN
         gt_removed_goods_b := gt_removed_goods_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：工場入庫
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_150 ) THEN
         gt_factory_stock := gt_factory_stock + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：工場入庫振戻
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_160 ) THEN
         gt_factory_stock_b := gt_factory_stock_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：返品
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_190 ) THEN
         gt_return_goods := gt_return_goods + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：返品振戻
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_200 ) THEN
         gt_return_goods_b := gt_return_goods_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：顧客見本出庫
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_320 ) THEN
         gt_customer_sample_ship := gt_customer_sample_ship + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：顧客見本出庫振戻
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_330 ) THEN
         gt_customer_sample_ship_b := gt_customer_sample_ship_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：売上出庫
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_170 ) THEN
         gt_sales_shipped := gt_sales_shipped + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：売上出庫振戻
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_180 ) THEN
         gt_sales_shipped_b := gt_sales_shipped_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：顧客協賛見本出庫
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_340 ) THEN
         gt_customer_support_ss := gt_customer_support_ss + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：顧客協賛見本出庫振戻
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_350 ) THEN
         gt_customer_support_ss_b := gt_customer_support_ss_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：顧客広告宣伝費A自社商品
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_360 ) THEN
         gt_ccm_sample_ship := gt_ccm_sample_ship + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：顧客広告宣伝費A自社商品振戻
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_370 ) THEN
         gt_ccm_sample_ship_b := gt_ccm_sample_ship_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：ロケーション移動
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_390 ) THEN
        -- ------------------------------------
        -- 受払数量の＋－で分岐
        -- ------------------------------------
        -- ロケーション移動増
        IF ( g_get_rep_data_rec.rep_qty >= 0 ) THEN
          gt_location_decrease := gt_location_decrease + g_get_rep_data_rec.rep_qty;
        -- ロケーション移動減
        ELSE
          gt_location_increase := gt_location_increase + g_get_rep_data_rec.rep_qty;
        END IF;
      END IF;
--
      -- 取引タイプ：在庫調整増
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_400 ) THEN
         gt_adjust_decrease := gt_adjust_decrease + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- 取引タイプ：在庫移動減
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_410 ) THEN
         gt_adjust_increase := gt_adjust_increase + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ------------------------------------
      -- 帳簿在庫数加算
      -- ------------------------------------
      gt_book_inventory_quantity := gt_book_inventory_quantity + g_get_rep_data_rec.rep_qty;
--
      --==============================================================
      -- 前レコード情報保持
      --==============================================================
      gt_bef_practice_month    := g_get_rep_data_rec.trx_month;      -- 取引年月
      gt_bef_base_code         := g_get_rep_data_rec.base_code;      -- 拠点コード
      gt_bef_subinventory_code := g_get_rep_data_rec.subinv_code;    -- 保管場所コード
      gt_bef_subinv_type       := g_get_rep_data_rec.subinv_type;    -- 保管場所区分
      gt_bef_location_code     := g_get_rep_data_rec.location_code;  -- ロケーションコード
      gt_bef_parent_item_id    := g_get_rep_data_rec.parent_item_id; -- 親品目ID
      gt_bef_child_item_id     := g_get_rep_data_rec.child_item_id;  -- 子品目ID
      gt_bef_lot               := g_get_rep_data_rec.lot;            -- ロット
      gt_bef_diff_sum_code     := g_get_rep_data_rec.diff_sum_code;  -- 固有記号
--
      --==============================================================
      -- データフェッチ
      --==============================================================
      -- 定期実行時
      IF ( gt_startup_flg = ct_data_type_1 ) THEN
        FETCH get_rep_data_1_cur INTO g_get_rep_data_rec;
        -- 新規レコードを取得できなかった場合、最終レコードフラグをYにする
        IF ( get_rep_data_1_cur%NOTFOUND ) THEN
          lv_not_exist_flag := cv_flag_y;
        -- 新規レコードを取得出来た場合は、対象件数カウント
        ELSE
          gn_target_cnt := gn_target_cnt + 1;
        END IF;
--
      -- 随時実行時
      ELSE
        FETCH get_rep_data_2_cur INTO g_get_rep_data_rec;
        -- 新規レコードを取得できなかった場合、最終レコードフラグをYにする
        IF ( get_rep_data_2_cur%NOTFOUND ) THEN
          lv_not_exist_flag := cv_flag_y;
        -- 新規レコードを取得出来た場合は、対象件数カウント
        ELSE
          gn_target_cnt := gn_target_cnt + 1;
        END IF;
      END IF;
--
      --==============================================================
      -- 登録・更新処理実行判定
      --==============================================================
      -- 最終レコードの場合、登録・更新処理を実行し、ループを抜ける
      IF ( lv_not_exist_flag = cv_flag_y ) THEN
        --==============================================================
        -- ロット別受払（月次）データ登録・更新処理 (A-5)
        --==============================================================
        cre_inout_data(
          ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- エラー処理
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ------------------------------------
        -- ループを抜ける
        -- ------------------------------------
        EXIT;
--
      -- 最終レコード以外の場合
      ELSE
        --==============================================================
        -- 取得したレコード情報と前レコード情報が完全一致するかチェック
        --==============================================================
        -- 一致する場合は取引タイプ、引当時取引タイプコード別数量の計算を継続
        IF (
              gt_bef_practice_month    = g_get_rep_data_rec.trx_month      -- 取引年月
          AND gt_bef_base_code         = g_get_rep_data_rec.base_code      -- 拠点コード
          AND gt_bef_subinventory_code = g_get_rep_data_rec.subinv_code    -- 保管場所コード
          AND gt_bef_location_code     = g_get_rep_data_rec.location_code  -- ロケーションコード
          AND gt_bef_parent_item_id    = g_get_rep_data_rec.parent_item_id -- 親品目ID
          AND gt_bef_child_item_id     = g_get_rep_data_rec.child_item_id  -- 子品目ID
          AND gt_bef_lot               = g_get_rep_data_rec.lot            -- ロット
          AND gt_bef_diff_sum_code     = g_get_rep_data_rec.diff_sum_code  -- 固有記号
        ) THEN
          -- 取引タイプ、引当時取引タイプコード別数量の計算を継続(何もしない)
          NULL;
--
        -- 一致しない場合は、登録・更新処理を実行
        ELSE
          --==============================================================
          -- ロット別受払（月次）データ登録・更新処理 (A-5)
          --==============================================================
          cre_inout_data(
            ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
           ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
           ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- エラー処理
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP rep_data_loop;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END cal_inout_data;
--
  /**********************************************************************************
   * Procedure Name   : get_inout_data
   * Description      : 受払データ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_inout_data(
    ov_errbuf     OUT VARCHAR2 --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2 --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2 --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inout_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- 受払データ取得
    --==============================================================
    -- カーソルオープン
    -- 定期実行時は、全拠点・全保管場所を対象
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
      OPEN get_rep_data_1_cur;
    -- 随時実行時は、入力パラメータで指定した拠点・保管場所のみ
    ELSE
      OPEN get_rep_data_2_cur;
    END IF;
--
    --==============================================================
    -- 受払項目算出処理(A-4)
    --==============================================================
    cal_inout_data(
      ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー処理
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- カーソルクローズ
    IF ( get_rep_data_1_cur%ISOPEN ) THEN
      CLOSE get_rep_data_1_cur;
    END IF;
--
    IF ( get_rep_data_2_cur%ISOPEN ) THEN
      CLOSE get_rep_data_2_cur;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( get_rep_data_1_cur%ISOPEN ) THEN
        CLOSE get_rep_data_1_cur;
      END IF;
--
      IF ( get_rep_data_2_cur%ISOPEN ) THEN
        CLOSE get_rep_data_2_cur;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( get_rep_data_1_cur%ISOPEN ) THEN
        CLOSE get_rep_data_1_cur;
      END IF;
--
      IF ( get_rep_data_2_cur%ISOPEN ) THEN
        CLOSE get_rep_data_2_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_inout_data;
--
  /**********************************************************************************
   * Procedure Name   : cre_carry_data
   * Description      : 繰越データ作成処理(A-2)
   ***********************************************************************************/
  PROCEDURE cre_carry_data(
    ov_errbuf     OUT VARCHAR2 --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2 --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2 --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cre_carry_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_data_cre_judge NUMBER; -- 繰越データ作成判定
--
    -- *** ローカル・カーソル ***
    -- ロット別受払（月次）前月データ取得カーソル
    CURSOR get_pre_mounth_data_cur(
      iv_practice_month VARCHAR2 -- 対象年月
    )IS
      SELECT xlrm.base_code               base_code               -- 拠点コード
            ,xlrm.subinventory_code       subinventory_code       -- 保管場所コード
            ,xlrm.subinventory_type       subinventory_type       -- 保管場所区分
            ,xlrm.location_code           location_code           -- ロケーションコード
            ,xlrm.parent_item_id          parent_item_id          -- 親品目ID
            ,xlrm.child_item_id           child_item_id           -- 子品目ID
            ,xlrm.lot                     lot                     -- ロット
            ,xlrm.difference_summary_code difference_summary_code -- 固有記号
            ,xlrm.book_inventory_quantity book_inventory_quantity -- 帳簿在庫数
      FROM   xxcoi_lot_reception_monthly xlrm
      WHERE  xlrm.practice_month          = iv_practice_month     -- 対象年月
      AND    xlrm.book_inventory_quantity > 0
    ;
--
    -- *** ローカル・レコード ***
    l_get_pre_mounth_data_rec get_pre_mounth_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2015/04/07 E_本稼動_12237 V1.1 DEL START
--    -- 変数初期化
--    ln_data_cre_judge := 0; -- 繰越データ作成判定
--
--    --==============================================================
--    -- 初回起動の判定
--    --==============================================================
--    -- 定期実行の場合のみ件数取得
--    IF ( gt_startup_flg = ct_data_type_1 ) THEN
--      SELECT COUNT(1)
--      INTO   ln_data_cre_judge
--      FROM   xxcoi_lot_reception_monthly xlrm
--      WHERE  xlrm.practice_month = TO_CHAR( gd_proc_date, cv_yyyymm ) -- 業務日付の年月
--      AND    ROWNUM              = 1
--      ;
--    -- 随時実行の場合、繰越データ作成判定を1とし、後続の処理を行わない
--    ELSE
--      ln_data_cre_judge := 1;
--    END IF;
--
--    --==============================================================
--    -- データ抽出、繰越データ作成
--    --==============================================================
--    -- 繰越データ作成判定が0の場合のみ実施
--    IF ( ln_data_cre_judge = 0 ) THEN
--
-- 2015/04/07 E_本稼動_12237 V1.1 DEL END
-- 2015/04/07 E_本稼動_12237 V1.1 ADD START
    -- 定期実行の場合のみ繰越処理を行う
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
-- 2015/04/07 E_本稼動_12237 V1.1 ADD END
      -- カーソルオープン
      OPEN get_pre_mounth_data_cur(
        iv_practice_month => TO_CHAR( ADD_MONTHS( gd_proc_date, -1 ), cv_yyyymm ) -- 業務日付の前月
      );
--
      <<pre_mounth_data_loop>>
      LOOP
        -- データフェッチ
        FETCH get_pre_mounth_data_cur INTO l_get_pre_mounth_data_rec;
        EXIT WHEN get_pre_mounth_data_cur%NOTFOUND;
--
        -- 取得件数カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
-- 2015/04/07 E_本稼動_12237 V1.1 ADD START
        -- 変数初期化
        ln_data_cre_judge := 0; -- 繰越データ作成判定
--
        -- 年月＝業務日付月の当月データが存在するかチェック
        SELECT COUNT(1) AS cnt
        INTO   ln_data_cre_judge
        FROM   xxcoi_lot_reception_monthly xlrm  -- ロット別受払(月次)
        WHERE  xlrm.practice_month          = TO_CHAR( gd_proc_date, cv_yyyymm ) -- 年月
        AND    xlrm.base_code               = l_get_pre_mounth_data_rec.base_code            -- 拠点コード
        AND    xlrm.subinventory_code       = l_get_pre_mounth_data_rec.subinventory_code    -- 保管場所コード
        AND    xlrm.location_code           = l_get_pre_mounth_data_rec.location_code        -- ロケーションコード
        AND    xlrm.parent_item_id          = l_get_pre_mounth_data_rec.parent_item_id       -- 親品目ID
        AND    xlrm.child_item_id           = l_get_pre_mounth_data_rec.child_item_id        -- 子品目ID
        AND    xlrm.lot                     = l_get_pre_mounth_data_rec.lot                  -- ロット
        AND    xlrm.difference_summary_code = l_get_pre_mounth_data_rec.difference_summary_code -- 固有記号
        AND    ROWNUM = 1
        ;
--
        -- 年月＝業務日付月の当月データが存在しない場合
        IF ( ln_data_cre_judge = 0 ) THEN
-- 2015/04/07 E_本稼動_12237 V1.1 ADD END
--
          -- 繰越データ作成
          INSERT INTO xxcoi_lot_reception_monthly(
            base_code                                         -- 拠点コード
           ,organization_id                                   -- 在庫組織ID
           ,subinventory_code                                 -- 保管場所コード
           ,subinventory_type                                 -- 保管場所区分
           ,location_code                                     -- ロケーションコード
           ,practice_month                                    -- 年月
           ,practice_date                                     -- 年月日
           ,parent_item_id                                    -- 親品目ID
           ,child_item_id                                     -- 子品目ID
           ,lot                                               -- ロット
           ,difference_summary_code                           -- 固有記号
           ,month_begin_quantity                              -- 月首棚卸高
           ,factory_stock                                     -- 工場入庫
           ,factory_stock_b                                   -- 工場入庫振戻
           ,change_stock                                      -- 倉替入庫
           ,others_stock                                      -- 入出庫＿その他入庫
           ,truck_stock                                       -- 営業車より入庫
           ,truck_ship                                        -- 営業車へ出庫
           ,sales_shipped                                     -- 売上出庫
           ,sales_shipped_b                                   -- 売上出庫振戻
           ,return_goods                                      -- 返品
           ,return_goods_b                                    -- 返品振戻
           ,customer_sample_ship                              -- 顧客見本出庫
           ,customer_sample_ship_b                            -- 顧客見本出庫振戻
           ,customer_support_ss                               -- 顧客協賛見本出庫
           ,customer_support_ss_b                             -- 顧客協賛見本出庫振戻
           ,ccm_sample_ship                                   -- 顧客広告宣伝費A自社商品
           ,ccm_sample_ship_b                                 -- 顧客広告宣伝費A自社商品振戻
           ,vd_supplement_stock                               -- 消化VD補充入庫
           ,vd_supplement_ship                                -- 消化VD補充出庫
           ,removed_goods                                     -- 廃却
           ,removed_goods_b                                   -- 廃却振戻
           ,change_ship                                       -- 倉替出庫
           ,others_ship                                       -- 入出庫＿その他出庫
           ,factory_change                                    -- 工場倉替
           ,factory_change_b                                  -- 工場倉替振戻
           ,factory_return                                    -- 工場返品
           ,factory_return_b                                  -- 工場返品振戻
           ,location_decrease                                 -- ロケーション移動増
           ,location_increase                                 -- ロケーション移動減
           ,adjust_decrease                                   -- 在庫調整増
           ,adjust_increase                                   -- 在庫調整減
           ,book_inventory_quantity                           -- 帳簿在庫数
           ,data_type                                         -- データ区分
           ,created_by                                        -- 作成者
           ,creation_date                                     -- 作成日
           ,last_updated_by                                   -- 最終更新者
           ,last_update_date                                  -- 最終更新日
           ,last_update_login                                 -- 最終更新ログイン
           ,request_id                                        -- 要求ID
           ,program_application_id                            -- コンカレント・プログラム・アプリケーションID
           ,program_id                                        -- コンカレント・プログラムID
           ,program_update_date                               -- プログラム更新日
          )VALUES(
            l_get_pre_mounth_data_rec.base_code               -- 拠点コード
           ,gt_org_id                                         -- 在庫組織ID
           ,l_get_pre_mounth_data_rec.subinventory_code       -- 保管場所コード
           ,l_get_pre_mounth_data_rec.subinventory_type       -- 保管場所区分
           ,l_get_pre_mounth_data_rec.location_code           -- ロケーションコード
           ,TO_CHAR( gd_proc_date, cv_yyyymm )                -- 年月
           ,LAST_DAY( gd_proc_date )                          -- 年月日
           ,l_get_pre_mounth_data_rec.parent_item_id          -- 親品目ID
           ,l_get_pre_mounth_data_rec.child_item_id           -- 子品目ID
           ,l_get_pre_mounth_data_rec.lot                     -- ロット
           ,l_get_pre_mounth_data_rec.difference_summary_code -- 固有記号
           ,l_get_pre_mounth_data_rec.book_inventory_quantity -- 月首棚卸高
           ,0                                                 -- 工場入庫
           ,0                                                 -- 工場入庫振戻
           ,0                                                 -- 倉替入庫
           ,0                                                 -- 入出庫＿その他入庫
           ,0                                                 -- 営業車より入庫
           ,0                                                 -- 営業車へ出庫
           ,0                                                 -- 売上出庫
           ,0                                                 -- 売上出庫振戻
           ,0                                                 -- 返品
           ,0                                                 -- 返品振戻
           ,0                                                 -- 顧客見本出庫
           ,0                                                 -- 顧客見本出庫振戻
           ,0                                                 -- 顧客協賛見本出庫
           ,0                                                 -- 顧客協賛見本出庫振戻
           ,0                                                 -- 顧客広告宣伝費A自社商品
           ,0                                                 -- 顧客広告宣伝費A自社商品振戻
           ,0                                                 -- 消化VD補充入庫
           ,0                                                 -- 消化VD補充出庫
           ,0                                                 -- 廃却
           ,0                                                 -- 廃却振戻
           ,0                                                 -- 倉替出庫
           ,0                                                 -- 入出庫＿その他出庫
           ,0                                                 -- 工場倉替
           ,0                                                 -- 工場倉替振戻
           ,0                                                 -- 工場返品
           ,0                                                 -- 工場返品振戻
           ,0                                                 -- ロケーション移動増
           ,0                                                 -- ロケーション移動減
           ,0                                                 -- 在庫調整増
           ,0                                                 -- 在庫調整減
           ,l_get_pre_mounth_data_rec.book_inventory_quantity -- 帳簿在庫数
           ,gt_startup_flg                                    -- データ区分
           ,cn_created_by                                     -- 作成者
           ,cd_creation_date                                  -- 作成日
           ,cn_last_updated_by                                -- 最終更新者
           ,cd_last_update_date                               -- 最終更新日
           ,cn_last_update_login                              -- 最終更新ログイン
           ,cn_request_id                                     -- 要求ID
           ,cn_program_application_id                         -- コンカレント・プログラム・アプリケーションID
           ,cn_program_id                                     -- コンカレント・プログラムID
           ,cd_program_update_date                            -- プログラム更新日
          );
--
-- 2015/04/07 E_本稼動_12237 V1.1 ADD START
        -- 年月＝業務日付月の当月データが存在する場合は更新
        ELSE
          UPDATE xxcoi_lot_reception_monthly -- ロット別受払(月次)
          SET    month_begin_quantity     = l_get_pre_mounth_data_rec.book_inventory_quantity     -- 月首在庫数
                ,book_inventory_quantity  = book_inventory_quantity
                                              + l_get_pre_mounth_data_rec.book_inventory_quantity -- 帳簿在庫数
                ,last_updated_by          = cn_last_updated_by             -- 最終更新者
                ,last_update_date         = cd_last_update_date            -- 最終更新日
                ,last_update_login        = cn_last_update_login           -- 最終更新ログイン
                ,request_id               = cn_request_id                  -- 要求ID
                ,program_application_id   = cn_program_application_id      -- アプリケーションID
                ,program_id               = cn_program_id                  -- プログラムID
                ,program_update_date      = cd_program_update_date         -- プログラム更新日
          WHERE  practice_month           = TO_CHAR( gd_proc_date, cv_yyyymm )           -- 年月
          AND    base_code                = l_get_pre_mounth_data_rec.base_code          -- 拠点コード
          AND    subinventory_code        = l_get_pre_mounth_data_rec.subinventory_code  -- 保管場所コード
          AND    location_code            = l_get_pre_mounth_data_rec.location_code      -- ロケーションコード
          AND    parent_item_id           = l_get_pre_mounth_data_rec.parent_item_id     -- 親品目ID
          AND    child_item_id            = l_get_pre_mounth_data_rec.child_item_id      -- 子品目ID
          AND    lot                      = l_get_pre_mounth_data_rec.lot                -- ロット
          AND    difference_summary_code  = l_get_pre_mounth_data_rec.difference_summary_code  -- 固有記号
          ;
        END IF;
-- 2015/04/07 E_本稼動_12237 V1.1 ADD END
        -- 成功件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP pre_mounth_data_loop;
--
      -- カーソルクローズ
      CLOSE get_pre_mounth_data_cur;
--
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      IF ( get_pre_mounth_data_cur%ISOPEN ) THEN
        CLOSE get_pre_mounth_data_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END cre_carry_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT VARCHAR2 --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2 --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2 --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- 入力パラメータ名称
    lt_base_name        hz_parties.party_name%TYPE;                 -- 拠点名
    lt_subinv_name      mtl_secondary_inventories.description%TYPE; -- 保管場所名
    lt_startup_flg_name fnd_lookup_values.meaning%TYPE;             -- 起動フラグ名
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
    -- グローバル変数初期化
    --==============================================================
    -- 入力パラメータ名称
    lt_base_name        := NULL;      -- 拠点名
    lt_subinv_name      := NULL;      -- 保管場所名
    lt_startup_flg_name := NULL;      -- 起動フラグ名
    -- 初期処理取得値
    gt_org_code         := NULL;      -- 在庫組織コード
    gt_org_id           := NULL;      -- 在庫組織ID
    gd_proc_date        := NULL;      -- 業務日付
    gt_pre_exe_id       := NULL;      -- 前回取引ID
    gt_no_data_flag     := cv_flag_n; -- 対象0件フラグ
    gt_max_trx_id       := NULL;      -- 最大取引ID
    gt_min_trx_id       := NULL;      -- 最小取引ID
--
    --==============================================================
    -- 在庫組織コード取得
    --==============================================================
    gt_org_code := FND_PROFILE.VALUE( cv_xxcoi1_organization_code );
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcoi_short_name
                    ,iv_name               => cv_msg_xxcoi1_00005
                    ,iv_token_name1        => cv_tkn_pro_tok              -- プロファイル名
                    ,iv_token_value1       => cv_xxcoi1_organization_code
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 在庫組織ID取得
    --==============================================================
    gt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gt_org_code
                 );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcoi_short_name
                    ,iv_name               => cv_msg_xxcoi1_00006
                    ,iv_token_name1        => cv_tkn_org_code_tok         -- 在庫組織コード
                    ,iv_token_value1       => gt_org_code
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 業務日付取得
    --==============================================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcoi_short_name
                    ,iv_name               => cv_msg_xxcoi1_00011
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    -- 1.起動フラグのチェック
    -- 未取得の場合は、パラメータ出力後にハンドリング
    lt_startup_flg_name := xxcoi_common_pkg.get_meaning(
                             iv_lookup_type => ct_xxcoi1_lot_rep_month_type -- 参照タイプ名
                            ,iv_lookup_code => gt_startup_flg               -- 参照タイプコード
                           );
--
    -- 2.拠点名称取得
    IF ( gt_base_code IS NOT NULL) THEN
      SELECT hp.party_name party_name -- パーティ名
      INTO   lt_base_name
      FROM   hz_parties       hp
            ,hz_cust_accounts hca
      WHERE  hca.account_number      = gt_base_code         -- 入力パラメータ.拠点コード
      AND    hca.customer_class_code = ct_cust_class_code_1 -- 顧客区分：拠点
      AND    hca.status              = ct_cust_status_a     -- ステータス：有効
      AND    hca.party_id            = hp.party_id
      ;
    END IF;
--
    -- 3.保管場所名取得
    IF ( gt_subinv_code IS NOT NULL ) THEN
      SELECT msi.description description -- 保管場所名
      INTO   lt_subinv_name
      FROM   mtl_secondary_inventories msi
      WHERE  msi.secondary_inventory_name              = gt_subinv_code -- 入力パラメータ.保管場所
      AND    msi.attribute7                            = gt_base_code   -- 入力パラメータ.拠点コード
      AND    NVL( msi.disable_date, gd_proc_date + 1 ) > gd_proc_date   -- 無効日チェック
      AND    msi.organization_id                       = gt_org_id      -- 在庫組織ID
      ;
    END IF;
--
    --==============================================================
    -- 入力パラメータメッセージ出力
    --==============================================================
    -- メッセージ取得
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application        => cv_xxcoi_short_name
                  ,iv_name               => cv_msg_xxcoi1_10454
                  ,iv_token_name1        => cv_tkn_base_code        -- 拠点コード
                  ,iv_token_value1       => gt_base_code
                  ,iv_token_name2        => cv_tkn_base_name        -- 拠点名
                  ,iv_token_value2       => lt_base_name
                  ,iv_token_name3        => cv_tkn_subinv_code      -- 保管場所コード
                  ,iv_token_value3       => gt_subinv_code
                  ,iv_token_name4        => cv_tkn_subinv_name      -- 保管場所名
                  ,iv_token_value4       => lt_subinv_name
                  ,iv_token_name5        => cv_tkn_startup_flg      -- 起動フラグ
                  ,iv_token_value5       => gt_startup_flg
                  ,iv_token_name6        => cv_tkn_startup_flg_name -- 起動フラグ名
                  ,iv_token_value6       => lt_startup_flg_name
                 );
--
    -- メッセージ出力(出力の表示)
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_errmsg
    );
--
    -- 空行出力(出力の表示)
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => ''
    );
--
    -- メッセージ出力(ログ)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_errmsg
    );
--
    -- 空行出力(ログ)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => ''
    );
--
    -- 起動フラグ不正エラーハンドリング
    IF ( lt_startup_flg_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcoi_short_name
                    ,iv_name               => cv_msg_xxcoi1_10455
                    ,iv_token_name1        => cv_tkn_startup_flg
                    ,iv_token_value1       => gt_startup_flg
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 前回取引ID取得
    --==============================================================
    BEGIN
      SELECT xcc.transaction_id transaction_id
      INTO   gt_pre_exe_id
      FROM   xxcoi_cooperation_control xcc
      WHERE  xcc.program_short_name = cv_pkg_name -- プログラム名
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application        => cv_xxcoi_short_name
                      ,iv_name               => cv_msg_xxcoi1_10456
                      ,iv_token_name1        => cv_tkn_program_name -- プログラム名
                      ,iv_token_value1       => cv_pkg_name
                     );
      RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 最小取引ID、最大取引ID取得
    --==============================================================
    -- 定期実行時
    -- 前回処理済以降のデータ
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
      SELECT MIN(xlt.transaction_id) min_trx_id     -- 最小取引ID
            ,MAX(xlt.transaction_id) max_trx_id     -- 最大取引ID
      INTO   gt_min_trx_id
            ,gt_max_trx_id
      FROM   xxcoi_lot_transactions xlt
      WHERE  xlt.transaction_id > gt_pre_exe_id     -- 前回処理済ID
      ;
    -- 随時実行時
    -- 前回処理済以降かつ、入力パラメータで指定した拠点・保管場所のデータ
    ELSE
      SELECT MIN(xlt.transaction_id) min_trx_id     -- 最小取引ID
            ,MAX(xlt.transaction_id) max_trx_id     -- 最大取引ID
      INTO   gt_min_trx_id
            ,gt_max_trx_id
      FROM   xxcoi_lot_transactions xlt
      WHERE  xlt.transaction_id    > gt_pre_exe_id  -- 前回処理済ID
      AND    xlt.base_code         = gt_base_code   -- 入力パラメータ.拠点
      AND    xlt.subinventory_code = gt_subinv_code -- 入力パラメータ.保管場所
      ;
    END IF;
--
    -- NULLの場合は、対象0件フラグを'Y'にする
    IF ( gt_max_trx_id IS NULL ) THEN
      gt_no_data_flag := cv_flag_y;
    END IF;
--
    --==============================================================
    -- 随時データ削除
    --==============================================================
    -- 定期実行時
    -- 全ての随時実行データ
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
      DELETE
      FROM   xxcoi_lot_reception_monthly xlrm
      WHERE  xlrm.data_type         = ct_data_type_2 -- データ区分：2
      ;
    -- 随時実行時
    -- 入力パラメータで指定した拠点・保管場所のデータ
    ELSE
      DELETE
      FROM   xxcoi_lot_reception_monthly xlrm
      WHERE  xlrm.data_type         = ct_data_type_2 -- データ区分：2
      AND    xlrm.base_code         = gt_base_code   -- 入力パラメータ.拠点
      AND    xlrm.subinventory_code = gt_subinv_code -- 入力パラメータ.保管場所
      ;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    proc_init(
      ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー処理
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 繰越データ作成処理(A-2)
    -- ===============================
    cre_carry_data(
      ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー処理
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 対象0件フラグが'N'の場合のみ実施
    IF ( gt_no_data_flag = cv_flag_n ) THEN
      -- ===============================
      -- 受払データ取得処理(A-3)
      -- ===============================
      get_inout_data(
        ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- エラー処理
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 定期実行時のみ、処理を行う
      IF ( gt_startup_flg = ct_data_type_1 ) THEN
        -- ===============================
        -- 終了処理(A-6)
        -- ===============================
        proc_end(
          ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- エラー処理
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END IF;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
    errbuf               OUT VARCHAR2 -- エラーメッセージ #固定#
   ,retcode              OUT VARCHAR2 -- エラーコード     #固定#
   ,iv_login_base_code   IN  VARCHAR2 -- 拠点コード
   ,iv_subinventory_code IN  VARCHAR2 -- 保管場所コード
   ,iv_startup_flg       IN  VARCHAR2 -- 起動フラグ
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
    -- 入力パラメータ格納
    gt_base_code   := iv_login_base_code;
    gt_subinv_code := iv_subinventory_code;
    gt_startup_flg := iv_startup_flg;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー時処理
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf --エラーメッセージ
      );
      -- エラー時件数セット
      gn_error_cnt  := 1;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
    ELSE
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
--
    IF ( gt_no_data_flag = cv_flag_y ) THEN
      -- 対象0件メッセージ出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10457
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    ELSE
      -- 対象取引IDメッセージ出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10458
                      ,iv_token_name1  => cv_tkn_min_trx_id
                      ,iv_token_value1 => TO_CHAR(gt_min_trx_id)
                      ,iv_token_name2  => cv_tkn_max_trx_id
                      ,iv_token_value2 => TO_CHAR(gt_max_trx_id)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
--
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSE
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
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOI016A10C;
/
