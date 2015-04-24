CREATE OR REPLACE PACKAGE BODY XXCOI016A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A09C(spec)
 * Description      : ロット別受払データ作成(日次、累計)
 * MD.050           : MD050_COI_016_A09_ロット別受払データ作成(日次、累計).doc
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_end               終了処理(A-6)
 *  cre_inout_data         ロット別受払(日次・累計)データ登録・更新処理 (A-5)
 *  cal_inout_data         受払項目算出処理(A-4)
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
 *  2014/11/04    1.0   Y.Nagasue        新規作成
 *  2015/04/07    1.1   S.Yamashita      E_本稼動_12237（倉庫管理不具合対応）
 *  2015/04/20    1.2   S.Yamashita      E_本稼動_12237（倉庫管理不具合対応）
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
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCOI016A09C'; -- パッケージ名
  cv_xxcoi_short_name          CONSTANT VARCHAR2(5)   := 'XXCOI';        -- アプリケーション短縮名
--
  -- データ連携制御テーブル取得・更新用プログラム名
  ct_pgm_name1                 CONSTANT xxcoi_cooperation_control.program_short_name%TYPE := 'XXCOI016A09C'; 
                                                  -- プログラム名：日次
  ct_pgm_name2                 CONSTANT xxcoi_cooperation_control.program_short_name%TYPE := 'XXCOI016B09C'; 
                                                  -- プログラム名：累計
--
  -- メッセージ
  cv_msg_xxcoi1_00005          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
                                                  -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi1_00006          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006'; 
                                                  -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi1_00011          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011'; 
                                                  -- 業務日付取得エラーメッセージ
  cv_msg_xxcoi1_10599          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10599'; 
                                                  -- 起動区分不正エラー
  cv_msg_xxcoi1_10596          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10596'; 
                                                  -- ロット別受払データ作成(日次、累計)コンカレント入力パラメータ
  cv_msg_xxcoi1_10456          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10456'; 
                                                  -- 処理済取引ID取得エラー
  cv_msg_xxcoi1_10597          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10597'; 
                                                  -- ロット別受払データ作成(日次、累計)対象0件メッセージ
  cv_msg_xxcoi1_10598          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10598'; 
                                                  -- ロット別受払(日次、累計)対象取引IDメッセージ
--
  -- トークン
  cv_tkn_pro_tok               CONSTANT VARCHAR2(20) := 'PRO_TOK';          -- トークン：プロファイル名
  cv_tkn_org_code_tok          CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';     -- トークン：在庫組織コード
  cv_tkn_startup_flg           CONSTANT VARCHAR2(20) := 'STARTUP_FLG';      -- トークン：起動区分
  cv_tkn_startup_flg_name      CONSTANT VARCHAR2(20) := 'STARTUP_FLG_NAME'; -- トークン：起動区分名
  cv_tkn_program_name          CONSTANT VARCHAR2(20) := 'PROGRAM_NAME';     -- トークン：プログラム名
  cv_tkn_min_trx_id            CONSTANT VARCHAR2(20) := 'MIN_TRX_ID';       -- トークン：最小取引ID
  cv_tkn_max_trx_id            CONSTANT VARCHAR2(20) := 'MAX_TRX_ID';       -- トークン：最大取引ID
--
  -- プロファイル名
  cv_xxcoi1_organization_code  CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:在庫組織コード
--
  -- 参照タイプ名
  ct_xxcoi1_lot_rep_daily_type fnd_lookup_values.lookup_type%TYPE := 'XXCOI1_LOT_REP_DAILY_TYPE';
                                                  -- 参照タイプ：ロット別受払データ作成(月次)起動フラグ
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
  -- 保管場所区分
  ct_subinv_kbn_2              CONSTANT mtl_secondary_inventories.attribute1%TYPE := '2'; -- 保管場所区分：2
--
  -- フラグ
  cv_flag_y                    CONSTANT VARCHAR2(1) := 'Y'; -- フラグ：Y
  cv_flag_n                    CONSTANT VARCHAR2(1) := 'N'; -- フラグ：N
--
  -- 起動区分
  cv_startup_flg_1             CONSTANT VARCHAR2(1) := '1'; -- 起動区分：日次実行
  cv_startup_flg_2             CONSTANT VARCHAR2(1) := '2'; -- 起動区分：累計実行
--
  -- 書式
  cv_yyyymm                    CONSTANT VARCHAR2(6) := 'YYYYMM'; -- 年月変換用
--
  -- その他
  cn_minus_1                   CONSTANT NUMBER := -1; -- 固定値：マイナス1
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ保持変数
  gv_startup_flg               VARCHAR2(1); -- 起動区分
--
  -- 初期処理取得値
  gt_org_code                  mtl_parameters.organization_code%TYPE;                -- 在庫組織コード
  gt_org_id                    mtl_parameters.organization_id%TYPE;                  -- 在庫組織ID
  gd_proc_date                 DATE;                                                 -- 業務日付
  gt_pgm_name                  xxcoi_cooperation_control.program_short_name%TYPE;    -- データ連携制御テーブルプログラム名
  gt_pre_exe_id                xxcoi_cooperation_control.transaction_id%TYPE;        -- 前回取引ID
  gt_pre_exe_date              xxcoi_cooperation_control.last_cooperation_date%TYPE; -- 前回処理日
  gv_no_data_flag              VARCHAR2(1);                                          -- 対象0件フラグ
  gt_max_trx_id                xxcoi_lot_transactions.transaction_id%TYPE;           -- 最大取引ID
  gt_min_trx_id                xxcoi_lot_transactions.transaction_id%TYPE;           -- 最小取引ID
--
  -- 前レコードロット情報保持用変数
  gt_bef_practice_month        xxcoi_lot_reception_sum.practice_month%TYPE;            -- 取引年月
  gt_bef_practice_date         xxcoi_lot_reception_daily.practice_date%TYPE;           -- 取引日
  gt_bef_base_code             xxcoi_lot_reception_daily.base_code%TYPE;               -- 拠点コード
  gt_bef_subinventory_code     xxcoi_lot_reception_daily.subinventory_code%TYPE;       -- 保管場所コード
  gt_bef_subinv_type           xxcoi_lot_reception_daily.subinventory_type%TYPE;       -- 保管場所区分
  gt_bef_location_code         xxcoi_lot_reception_daily.location_code%TYPE;           -- ロケーションコード
  gt_bef_parent_item_id        xxcoi_lot_reception_daily.parent_item_id%TYPE;          -- 親品目ID
  gt_bef_child_item_id         xxcoi_lot_reception_daily.child_item_id%TYPE;           -- 子品目ID
  gt_bef_lot                   xxcoi_lot_reception_daily.lot%TYPE;                     -- ロット
  gt_bef_diff_sum_code         xxcoi_lot_reception_daily.difference_summary_code%TYPE; -- 固有記号
--
  -- 受払項目計算結果保持用変数
  gt_factory_stock             xxcoi_lot_reception_daily.factory_stock%TYPE;           -- 工場入庫
  gt_factory_stock_b           xxcoi_lot_reception_daily.factory_stock_b%TYPE;         -- 工場入庫振戻
  gt_change_stock              xxcoi_lot_reception_daily.change_stock%TYPE;            -- 倉替入庫
  gt_others_stock              xxcoi_lot_reception_daily.others_stock%TYPE;            -- 入出庫＿その他入庫
  gt_truck_stock               xxcoi_lot_reception_daily.truck_stock%TYPE;             -- 営業車より入庫
  gt_truck_ship                xxcoi_lot_reception_daily.truck_ship%TYPE;              -- 営業車へ出庫
  gt_sales_shipped             xxcoi_lot_reception_daily.sales_shipped%TYPE;           -- 売上出庫
  gt_sales_shipped_b           xxcoi_lot_reception_daily.sales_shipped_b%TYPE;         -- 売上出庫振戻
  gt_return_goods              xxcoi_lot_reception_daily.return_goods%TYPE;            -- 返品
  gt_return_goods_b            xxcoi_lot_reception_daily.return_goods_b%TYPE;          -- 返品振戻
  gt_customer_sample_ship      xxcoi_lot_reception_daily.customer_sample_ship%TYPE;    -- 顧客見本出庫
  gt_customer_sample_ship_b    xxcoi_lot_reception_daily.customer_sample_ship_b%TYPE;  -- 顧客見本出庫振戻
  gt_customer_support_ss       xxcoi_lot_reception_daily.customer_support_ss%TYPE;     -- 顧客協賛見本出庫
  gt_customer_support_ss_b     xxcoi_lot_reception_daily.customer_support_ss_b%TYPE;   -- 顧客協賛見本出庫振戻
  gt_ccm_sample_ship           xxcoi_lot_reception_daily.ccm_sample_ship%TYPE;         -- 顧客広告宣伝費A自社商品
  gt_ccm_sample_ship_b         xxcoi_lot_reception_daily.ccm_sample_ship_b%TYPE;       -- 顧客広告宣伝費A自社商品振戻
  gt_vd_supplement_stock       xxcoi_lot_reception_daily.vd_supplement_stock%TYPE;     -- 消化VD補充入庫
  gt_vd_supplement_ship        xxcoi_lot_reception_daily.vd_supplement_ship%TYPE;      -- 消化VD補充出庫
  gt_removed_goods             xxcoi_lot_reception_daily.removed_goods%TYPE;           -- 廃却
  gt_removed_goods_b           xxcoi_lot_reception_daily.removed_goods_b%TYPE;         -- 廃却振戻
  gt_change_ship               xxcoi_lot_reception_daily.change_ship%TYPE;             -- 倉替出庫
  gt_others_ship               xxcoi_lot_reception_daily.others_ship%TYPE;             -- 入出庫＿その他出庫
  gt_factory_change            xxcoi_lot_reception_daily.factory_change%TYPE;          -- 工場倉替
  gt_factory_change_b          xxcoi_lot_reception_daily.factory_change_b%TYPE;        -- 工場倉替振戻
  gt_factory_return            xxcoi_lot_reception_daily.factory_return%TYPE;          -- 工場返品
  gt_factory_return_b          xxcoi_lot_reception_daily.factory_return_b%TYPE;        -- 工場返品振戻
  gt_location_decrease         xxcoi_lot_reception_daily.location_decrease%TYPE;       -- ロケーション移動増
  gt_location_increase         xxcoi_lot_reception_daily.location_increase%TYPE;       -- ロケーション移動減
  gt_adjust_decrease           xxcoi_lot_reception_daily.adjust_decrease%TYPE;         -- 在庫調整増
  gt_adjust_increase           xxcoi_lot_reception_daily.adjust_increase%TYPE;         -- 在庫調整減
  gt_book_inventory_quantity   xxcoi_lot_reception_daily.book_inventory_quantity%TYPE; -- 帳簿在庫数
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 受払対象データ取得カーソル
  CURSOR get_rep_data_cur IS
    SELECT xlt.transaction_month             trx_month             -- 取引年月
          ,xlt.transaction_date              trx_date              -- 取引日
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
     ,xlt.transaction_date                                         -- 取引日
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
     ,xlt.transaction_date                                         -- 取引日
     ,xlt.base_code                                                -- 拠点コード
     ,xlt.subinventory_code                                        -- 保管場所コード
     ,xlt.location_code                                            -- ロケーションコード
     ,xlt.parent_item_id                                           -- 親品目ID
     ,xlt.child_item_id                                            -- 子品目ID
     ,xlt.lot                                                      -- ロット
     ,xlt.difference_summary_code                                  -- 固有記号
  ;
  -- 受払対象データ格納用レコード
  g_get_rep_data_rec get_rep_data_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : proc_end
   * Description      : 終了処理(A-6)
   ***********************************************************************************/
  PROCEDURE proc_end(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
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
          ,xcc.transaction_id         = NVL( gt_max_trx_id, xcc.transaction_id )
                                                                  -- 取引ID：最大取引ID(NULLの場合は更新しない)
          ,xcc.last_updated_by        = cn_last_updated_by        -- 最終更新者
          ,xcc.last_update_date       = cd_last_update_date       -- 最終更新日
          ,xcc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
          ,xcc.request_id             = cn_request_id             -- 要求ID
          ,xcc.program_application_id = cn_program_application_id -- アプリケーションID
          ,xcc.program_id             = cn_program_id             -- プログラムID
          ,xcc.program_update_date    = cd_program_update_date    -- プログラム更新日
    WHERE  xcc.program_short_name     = gt_pgm_name               -- プログラム名：前回取引ID取得時のプログラム名
    ;
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
  END proc_end;
--
  /**********************************************************************************
   * Procedure Name   : cre_inout_data
   * Description      : ロット別受払(日次・累計)データ登録・更新処理 (A-5)
   ***********************************************************************************/
  PROCEDURE cre_inout_data(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
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
    ln_exist_chk1       NUMBER;      -- 存在チェック
    ln_exist_chk2       NUMBER;      -- 当日(当月)データ存在チェック
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
    ln_exist_chk1       := 0;                                  -- 存在チェック
    ln_exist_chk2       := 0;                                  -- 当日(当月)データ存在チェック
    lv_proc_date_yyyymm := TO_CHAR( gd_proc_date, cv_yyyymm ); -- 業務日付YYYYMM型
--
    --==============================================================
    -- 日次データ作成
    --==============================================================
    IF ( gv_startup_flg = cv_startup_flg_1 ) THEN
--
      --==============================================================
      -- ロット別受払(日次)存在チェック
      --==============================================================
      SELECT COUNT(1)
      INTO   ln_exist_chk1                                           -- 存在チェック
      FROM   xxcoi_lot_reception_daily xlrd
      WHERE  xlrd.practice_date           = gt_bef_practice_date     -- 取引日
      AND    xlrd.base_code               = gt_bef_base_code         -- 拠点コード
      AND    xlrd.subinventory_code       = gt_bef_subinventory_code -- 保管場所コード
      AND    xlrd.location_code           = gt_bef_location_code     -- ロケーションコード
      AND    xlrd.parent_item_id          = gt_bef_parent_item_id    -- 親品目ID
      AND    xlrd.child_item_id           = gt_bef_child_item_id     -- 子品目ID
      AND    xlrd.lot                     = gt_bef_lot               -- ロット
      AND    xlrd.difference_summary_code = gt_bef_diff_sum_code     -- 固有記号
      AND    ROWNUM = 1
      ;
--
      -- 存在しない場合は、登録処理
      IF ( ln_exist_chk1 = 0 ) THEN
        --==============================================================
        -- ロット別受払(日次)新規作成
        --==============================================================
        INSERT INTO xxcoi_lot_reception_daily(
          base_code                              -- 拠点コード
         ,organization_id                        -- 在庫組織ID
         ,subinventory_code                      -- 保管場所
         ,subinventory_type                      -- 保管場所区分
         ,location_code                          -- ロケーションコード
         ,practice_date                          -- 年月日
         ,parent_item_id                         -- 親品目ID
         ,child_item_id                          -- 子品目ID
         ,lot                                    -- ロット
         ,difference_summary_code                -- 固有記号
         ,previous_inventory_quantity            -- 前日在庫数
         ,factory_stock                          -- 工場入庫
         ,factory_stock_b                        -- 工場入庫振戻
         ,change_stock                           -- 倉替入庫
         ,others_stock                           -- 入出庫＿その他入庫
         ,truck_stock                            -- 営業車より入庫
         ,truck_ship                             -- 営業車へ出庫
         ,sales_shipped                          -- 売上出庫
         ,sales_shipped_b                        -- 売上出庫振戻
         ,return_goods                           -- 返品
         ,return_goods_b                         -- 返品振戻
         ,customer_sample_ship                   -- 顧客見本出庫
         ,customer_sample_ship_b                 -- 顧客見本出庫振戻
         ,customer_support_ss                    -- 顧客協賛見本出庫
         ,customer_support_ss_b                  -- 顧客協賛見本出庫振戻
         ,ccm_sample_ship                        -- 顧客広告宣伝費A自社商品
         ,ccm_sample_ship_b                      -- 顧客広告宣伝費A自社商品振戻
         ,vd_supplement_stock                    -- 消化VD補充入庫
         ,vd_supplement_ship                     -- 消化VD補充出庫
         ,removed_goods                          -- 廃却
         ,removed_goods_b                        -- 廃却振戻
         ,change_ship                            -- 倉替出庫
         ,others_ship                            -- 入出庫＿その他出庫
         ,factory_change                         -- 工場倉替
         ,factory_change_b                       -- 工場倉替振戻
         ,factory_return                         -- 工場返品
         ,factory_return_b                       -- 工場返品振戻
         ,location_decrease                      -- ロケーション移動増
         ,location_increase                      -- ロケーション移動減
         ,adjust_decrease                        -- 在庫調整増
         ,adjust_increase                        -- 在庫調整減
         ,book_inventory_quantity                -- 帳簿在庫数
         ,created_by                             -- 作成者
         ,creation_date                          -- 作成日
         ,last_updated_by                        -- 最終更新者
         ,last_update_date                       -- 最終更新日
         ,last_update_login                      -- 最終更新ログイン
         ,request_id                             -- 要求ID
         ,program_application_id                 -- アプリケーションID
         ,program_id                             -- プログラムID
         ,program_update_date                    -- プログラム更新日
        )VALUES(
          gt_bef_base_code                       -- 拠点コード
         ,gt_org_id                              -- 在庫組織ID
         ,gt_bef_subinventory_code               -- 保管場所
         ,gt_bef_subinv_type                     -- 保管場所区分
         ,gt_bef_location_code                   -- ロケーションコード
         ,gt_bef_practice_date                   -- 年月日
         ,gt_bef_parent_item_id                  -- 親品目ID
         ,gt_bef_child_item_id                   -- 子品目ID
         ,gt_bef_lot                             -- ロット
         ,gt_bef_diff_sum_code                   -- 固有記号
         ,0                                      -- 前日在庫数
         ,gt_factory_stock                       -- 工場入庫
         ,(gt_factory_stock_b) * cn_minus_1      -- 工場入庫振戻
         ,gt_change_stock                        -- 倉替入庫
         ,gt_others_stock                        -- 入出庫＿その他入庫
         ,gt_truck_stock                         -- 営業車より入庫
         ,(gt_truck_ship) * cn_minus_1           -- 営業車へ出庫
         ,(gt_sales_shipped) * cn_minus_1        -- 売上出庫
         ,gt_sales_shipped_b                     -- 売上出庫振戻
         ,gt_return_goods                        -- 返品
         ,(gt_return_goods_b) * cn_minus_1       -- 返品振戻
         ,(gt_customer_sample_ship) * cn_minus_1 -- 顧客見本出庫
         ,gt_customer_sample_ship_b              -- 顧客見本出庫振戻
         ,(gt_customer_support_ss) * cn_minus_1  -- 顧客協賛見本出庫
         ,gt_customer_support_ss_b               -- 顧客協賛見本出庫振戻
         ,(gt_ccm_sample_ship) * cn_minus_1      -- 顧客広告宣伝費A自社商品
         ,gt_ccm_sample_ship_b                   -- 顧客広告宣伝費A自社商品振戻
         ,gt_vd_supplement_stock                 -- 消化VD補充入庫
         ,(gt_vd_supplement_ship) * cn_minus_1   -- 消化VD補充出庫
         ,(gt_removed_goods) * cn_minus_1        -- 廃却
         ,gt_removed_goods_b                     -- 廃却振戻
         ,(gt_change_ship) * cn_minus_1          -- 倉替出庫
         ,(gt_others_ship) * cn_minus_1          -- 入出庫＿その他出庫
         ,(gt_factory_change) * cn_minus_1       -- 工場倉替
         ,gt_factory_change_b                    -- 工場倉替振戻
         ,(gt_factory_return) * cn_minus_1       -- 工場返品
         ,gt_factory_return_b                    -- 工場返品振戻
         ,gt_location_decrease                   -- ロケーション移動増
         ,(gt_location_increase) * cn_minus_1    -- ロケーション移動減
         ,gt_adjust_decrease                     -- 在庫調整増
         ,(gt_adjust_increase) * cn_minus_1      -- 在庫調整減
         ,gt_book_inventory_quantity             -- 帳簿在庫数
         ,cn_created_by                          -- 作成者
         ,cd_creation_date                       -- 作成日
         ,cn_last_updated_by                     -- 最終更新者
         ,cd_last_update_date                    -- 最終更新日
         ,cn_last_update_login                   -- 最終更新ログイン
         ,cn_request_id                          -- 要求ID
         ,cn_program_application_id              -- アプリケーションID
         ,cn_program_id                          -- プログラムID
         ,cd_program_update_date                 -- プログラム更新日
        );
--
        -- 成功件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      -- 存在する場合は、更新処理
      ELSE
        --==============================================================
        -- ロット別受払(日次)更新
        --==============================================================
        UPDATE xxcoi_lot_reception_daily xlrd
        SET    xlrd.factory_stock           = xlrd.factory_stock           + gt_factory_stock
                                                                        -- 工場入庫
              ,xlrd.factory_stock_b         = xlrd.factory_stock_b         + (gt_factory_stock_b) * cn_minus_1
                                                                        -- 工場入庫振戻
              ,xlrd.change_stock            = xlrd.change_stock            + gt_change_stock
                                                                        -- 倉替入庫
              ,xlrd.others_stock            = xlrd.others_stock            + gt_others_stock
                                                                        -- 入出庫＿その他入庫
              ,xlrd.truck_stock             = xlrd.truck_stock             + gt_truck_stock
                                                                        -- 営業車より入庫
              ,xlrd.truck_ship              = xlrd.truck_ship              + (gt_truck_ship) * cn_minus_1
                                                                        -- 営業車へ出庫
              ,xlrd.sales_shipped           = xlrd.sales_shipped           + (gt_sales_shipped) * cn_minus_1
                                                                        -- 売上出庫
              ,xlrd.sales_shipped_b         = xlrd.sales_shipped_b         + gt_sales_shipped_b
                                                                        -- 売上出庫振戻
              ,xlrd.return_goods            = xlrd.return_goods            + gt_return_goods
                                                                        -- 返品
              ,xlrd.return_goods_b          = xlrd.return_goods_b          + (gt_return_goods_b) * cn_minus_1
                                                                        -- 返品振戻
              ,xlrd.customer_sample_ship    = xlrd.customer_sample_ship    + (gt_customer_sample_ship) * cn_minus_1
                                                                        -- 顧客見本出庫
              ,xlrd.customer_sample_ship_b  = xlrd.customer_sample_ship_b  + gt_customer_sample_ship_b
                                                                        -- 顧客見本出庫振戻
              ,xlrd.customer_support_ss     = xlrd.customer_support_ss     + (gt_customer_support_ss) * cn_minus_1
                                                                        -- 顧客協賛見本出庫
              ,xlrd.customer_support_ss_b   = xlrd.customer_support_ss_b   + gt_customer_support_ss_b
                                                                        -- 顧客協賛見本出庫振戻
              ,xlrd.ccm_sample_ship         = xlrd.ccm_sample_ship         + (gt_ccm_sample_ship) * cn_minus_1
                                                                        -- 顧客広告宣伝費A自社商品
              ,xlrd.ccm_sample_ship_b       = xlrd.ccm_sample_ship_b       + gt_ccm_sample_ship_b
                                                                        -- 顧客広告宣伝費A自社商品振戻
              ,xlrd.vd_supplement_stock     = xlrd.vd_supplement_stock     + gt_vd_supplement_stock
                                                                        -- 消化VD補充入庫
              ,xlrd.vd_supplement_ship      = xlrd.vd_supplement_ship      + (gt_vd_supplement_ship) * cn_minus_1
                                                                        -- 消化VD補充出庫
              ,xlrd.removed_goods           = xlrd.removed_goods           + (gt_removed_goods) * cn_minus_1
                                                                        -- 廃却
              ,xlrd.removed_goods_b         = xlrd.removed_goods_b         + gt_removed_goods_b
                                                                        -- 廃却振戻
              ,xlrd.change_ship             = xlrd.change_ship             + (gt_change_ship) * cn_minus_1
                                                                        -- 倉替出庫
              ,xlrd.others_ship             = xlrd.others_ship             + (gt_others_ship) * cn_minus_1
                                                                        -- 入出庫＿その他出庫
              ,xlrd.factory_change          = xlrd.factory_change          + (gt_factory_change) * cn_minus_1
                                                                        -- 工場倉替
              ,xlrd.factory_change_b        = xlrd.factory_change_b        + gt_factory_change_b
                                                                        -- 工場倉替振戻
              ,xlrd.factory_return          = xlrd.factory_return          + (gt_factory_return) * cn_minus_1
                                                                        -- 工場返品
              ,xlrd.factory_return_b        = xlrd.factory_return_b        + gt_factory_return_b
                                                                        -- 工場返品振戻
              ,xlrd.location_decrease       = xlrd.location_decrease       + gt_location_decrease
                                                                        -- ロケーション移動増
              ,xlrd.location_increase       = xlrd.location_increase       + (gt_location_increase) * cn_minus_1
                                                                        -- ロケーション移動減
              ,xlrd.adjust_decrease         = xlrd.adjust_decrease         + gt_adjust_decrease
                                                                        -- 在庫調整増
              ,xlrd.adjust_increase         = xlrd.adjust_increase         + (gt_adjust_increase) * cn_minus_1
                                                                        -- 在庫調整減
              ,xlrd.book_inventory_quantity = xlrd.book_inventory_quantity + gt_book_inventory_quantity
                                                                        -- 帳簿在庫数
              ,xlrd.last_updated_by         = cn_last_updated_by        -- 最終更新者
              ,xlrd.last_update_date        = cd_last_update_date       -- 最終更新日
              ,xlrd.last_update_login       = cn_last_update_login      -- 最終更新ログイン
              ,xlrd.request_id              = cn_request_id             -- 要求ID
              ,xlrd.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
              ,xlrd.program_id              = cn_program_id             -- コンカレント・プログラムID
              ,xlrd.program_update_date     = cd_program_update_date    -- プログラム更新日
        WHERE  xlrd.practice_date           = gt_bef_practice_date      -- 取引日
        AND    xlrd.base_code               = gt_bef_base_code          -- 拠点コード
        AND    xlrd.subinventory_code       = gt_bef_subinventory_code  -- 保管場所コード
        AND    xlrd.location_code           = gt_bef_location_code      -- ロケーションコード
        AND    xlrd.parent_item_id          = gt_bef_parent_item_id     -- 親品目ID
        AND    xlrd.child_item_id           = gt_bef_child_item_id      -- 子品目ID
        AND    xlrd.lot                     = gt_bef_lot                -- ロット
        AND    xlrd.difference_summary_code = gt_bef_diff_sum_code      -- 固有記号
        ;
--
        -- 成功件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END IF;
--
      -- 取引日が業務日付より過去日の場合
      IF ( gt_bef_practice_date < gd_proc_date ) THEN
        --==============================================================
        -- ロット別受払(日次)当日データ存在チェック
        --==============================================================
        SELECT COUNT(1)
        INTO   ln_exist_chk2                                           -- 当日データ存在チェック
        FROM   xxcoi_lot_reception_daily xlrd
        WHERE  xlrd.practice_date           = gd_proc_date             -- 取引日(業務日付)
        AND    xlrd.base_code               = gt_bef_base_code         -- 拠点コード
        AND    xlrd.subinventory_code       = gt_bef_subinventory_code -- 保管場所コード
        AND    xlrd.location_code           = gt_bef_location_code     -- ロケーションコード
        AND    xlrd.parent_item_id          = gt_bef_parent_item_id    -- 親品目ID
        AND    xlrd.child_item_id           = gt_bef_child_item_id     -- 子品目ID
        AND    xlrd.lot                     = gt_bef_lot               -- ロット
        AND    xlrd.difference_summary_code = gt_bef_diff_sum_code     -- 固有記号
        AND    ROWNUM                       = 1
        ;
--
        -- 当日データが存在しない場合は、新規作成
        IF ( ln_exist_chk2 = 0 ) THEN
          --==============================================================
          -- ロット別受払(日次)当日繰越データ作成
          --==============================================================
          INSERT INTO xxcoi_lot_reception_daily(
            base_code                   -- 拠点コード
           ,organization_id             -- 在庫組織ID
           ,subinventory_code           -- 保管場所
           ,subinventory_type           -- 保管場所区分
           ,location_code               -- ロケーションコード
           ,practice_date               -- 年月日
           ,parent_item_id              -- 親品目ID
           ,child_item_id               -- 子品目ID
           ,lot                         -- ロット
           ,difference_summary_code     -- 固有記号
           ,previous_inventory_quantity -- 前日在庫数
           ,factory_stock               -- 工場入庫
           ,factory_stock_b             -- 工場入庫振戻
           ,change_stock                -- 倉替入庫
           ,others_stock                -- 入出庫＿その他入庫
           ,truck_stock                 -- 営業車より入庫
           ,truck_ship                  -- 営業車へ出庫
           ,sales_shipped               -- 売上出庫
           ,sales_shipped_b             -- 売上出庫振戻
           ,return_goods                -- 返品
           ,return_goods_b              -- 返品振戻
           ,customer_sample_ship        -- 顧客見本出庫
           ,customer_sample_ship_b      -- 顧客見本出庫振戻
           ,customer_support_ss         -- 顧客協賛見本出庫
           ,customer_support_ss_b       -- 顧客協賛見本出庫振戻
           ,ccm_sample_ship             -- 顧客広告宣伝費A自社商品
           ,ccm_sample_ship_b           -- 顧客広告宣伝費A自社商品振戻
           ,vd_supplement_stock         -- 消化VD補充入庫
           ,vd_supplement_ship          -- 消化VD補充出庫
           ,removed_goods               -- 廃却
           ,removed_goods_b             -- 廃却振戻
           ,change_ship                 -- 倉替出庫
           ,others_ship                 -- 入出庫＿その他出庫
           ,factory_change              -- 工場倉替
           ,factory_change_b            -- 工場倉替振戻
           ,factory_return              -- 工場返品
           ,factory_return_b            -- 工場返品振戻
           ,location_decrease           -- ロケーション移動増
           ,location_increase           -- ロケーション移動減
           ,adjust_decrease             -- 在庫調整増
           ,adjust_increase             -- 在庫調整減
           ,book_inventory_quantity     -- 帳簿在庫数
           ,created_by                  -- 作成者
           ,creation_date               -- 作成日
           ,last_updated_by             -- 最終更新者
           ,last_update_date            -- 最終更新日
           ,last_update_login           -- 最終更新ログイン
           ,request_id                  -- 要求ID
           ,program_application_id      -- アプリケーションID
           ,program_id                  -- プログラムID
           ,program_update_date         -- プログラム更新日
          )VALUES(
            gt_bef_base_code            -- 拠点コード
           ,gt_org_id                   -- 在庫組織ID
           ,gt_bef_subinventory_code    -- 保管場所
           ,gt_bef_subinv_type          -- 保管場所区分
           ,gt_bef_location_code        -- ロケーションコード
           ,gd_proc_date                -- 年月日
           ,gt_bef_parent_item_id       -- 親品目ID
           ,gt_bef_child_item_id        -- 子品目ID
           ,gt_bef_lot                  -- ロット
           ,gt_bef_diff_sum_code        -- 固有記号
           ,gt_book_inventory_quantity  -- 前日在庫数
           ,0                           -- 工場入庫
           ,0                           -- 工場入庫振戻
           ,0                           -- 倉替入庫
           ,0                           -- 入出庫＿その他入庫
           ,0                           -- 営業車より入庫
           ,0                           -- 営業車へ出庫
           ,0                           -- 売上出庫
           ,0                           -- 売上出庫振戻
           ,0                           -- 返品
           ,0                           -- 返品振戻
           ,0                           -- 顧客見本出庫
           ,0                           -- 顧客見本出庫振戻
           ,0                           -- 顧客協賛見本出庫
           ,0                           -- 顧客協賛見本出庫振戻
           ,0                           -- 顧客広告宣伝費A自社商品
           ,0                           -- 顧客広告宣伝費A自社商品振戻
           ,0                           -- 消化VD補充入庫
           ,0                           -- 消化VD補充出庫
           ,0                           -- 廃却
           ,0                           -- 廃却振戻
           ,0                           -- 倉替出庫
           ,0                           -- 入出庫＿その他出庫
           ,0                           -- 工場倉替
           ,0                           -- 工場倉替振戻
           ,0                           -- 工場返品
           ,0                           -- 工場返品振戻
           ,0                           -- ロケーション移動増
           ,0                           -- ロケーション移動減
           ,0                           -- 在庫調整増
           ,0                           -- 在庫調整減
           ,gt_book_inventory_quantity  -- 帳簿在庫数
           ,cn_created_by               -- 作成者
           ,cd_creation_date            -- 作成日
           ,cn_last_updated_by          -- 最終更新者
           ,cd_last_update_date         -- 最終更新日
           ,cn_last_update_login        -- 最終更新ログイン
           ,cn_request_id               -- 要求ID
           ,cn_program_application_id   -- アプリケーションID
           ,cn_program_id               -- プログラムID
           ,cd_program_update_date      -- プログラム更新日
          );
--
          -- 成功件数カウントアップ
          gn_normal_cnt := gn_normal_cnt + 1;
--
        -- 当日データが存在する場合は、更新
        ELSE
          --==============================================================
          -- ロット別受払(日次)当日データ更新
          --==============================================================
          UPDATE xxcoi_lot_reception_daily xlrd
          SET    xlrd.previous_inventory_quantity = xlrd.previous_inventory_quantity + gt_book_inventory_quantity
                                                                              -- 前日在庫数
                ,xlrd.book_inventory_quantity     = xlrd.book_inventory_quantity + gt_book_inventory_quantity
                                                                              -- 帳簿在庫数
                ,xlrd.last_updated_by             = cn_last_updated_by        -- 最終更新者
                ,xlrd.last_update_date            = cd_last_update_date       -- 最終更新日
                ,xlrd.last_update_login           = cn_last_update_login      -- 最終更新ログイン
                ,xlrd.request_id                  = cn_request_id             -- 要求ID
                ,xlrd.program_application_id      = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
                ,xlrd.program_id                  = cn_program_id             -- コンカレント・プログラムID
                ,xlrd.program_update_date         = cd_program_update_date    -- プログラム更新日
          WHERE  xlrd.practice_date               = gd_proc_date              -- 取引日(業務日付)
          AND    xlrd.base_code                   = gt_bef_base_code          -- 拠点コード
          AND    xlrd.subinventory_code           = gt_bef_subinventory_code  -- 保管場所コード
          AND    xlrd.location_code               = gt_bef_location_code      -- ロケーションコード
          AND    xlrd.parent_item_id              = gt_bef_parent_item_id     -- 親品目ID
          AND    xlrd.child_item_id               = gt_bef_child_item_id      -- 子品目ID
          AND    xlrd.lot                         = gt_bef_lot                -- ロット
          AND    xlrd.difference_summary_code     = gt_bef_diff_sum_code      -- 固有記号
          ;
--
          -- 成功件数カウントアップ
          gn_normal_cnt := gn_normal_cnt + 1;
--
        END IF;
--
      END IF;
--
    --==============================================================
    -- 累計データ作成
    --==============================================================
    ELSE
--
      --==============================================================
      -- ロット別受払(累計)存在チェック
      --==============================================================
      SELECT COUNT(1)
      INTO   ln_exist_chk1                                           -- 存在チェック
      FROM   xxcoi_lot_reception_sum xlrs
      WHERE  xlrs.practice_month          = gt_bef_practice_month    -- 取引年月
      AND    xlrs.base_code               = gt_bef_base_code         -- 拠点コード
      AND    xlrs.subinventory_code       = gt_bef_subinventory_code -- 保管場所コード
      AND    xlrs.location_code           = gt_bef_location_code     -- ロケーションコード
      AND    xlrs.parent_item_id          = gt_bef_parent_item_id    -- 親品目ID
      AND    xlrs.child_item_id           = gt_bef_child_item_id     -- 子品目ID
      AND    xlrs.lot                     = gt_bef_lot               -- ロット
      AND    xlrs.difference_summary_code = gt_bef_diff_sum_code     -- 固有記号
      AND    ROWNUM                       = 1
      ;
--
      -- 存在しない場合は、登録処理
      IF ( ln_exist_chk1 = 0 ) THEN
        --==============================================================
        -- ロット別受払(累計)新規作成
        --==============================================================
        INSERT INTO xxcoi_lot_reception_sum(
          base_code                              -- 拠点コード
         ,organization_id                        -- 在庫組織ID
         ,subinventory_code                      -- 保管場所コード
         ,subinventory_type                      -- 保管場所区分
         ,location_code                          -- ロケーションコード
         ,practice_month                         -- 年月
         ,parent_item_id                         -- 親品目ID
         ,child_item_id                          -- 子品目ID
         ,lot                                    -- ロット
         ,difference_summary_code                -- 固有記号
         ,month_begin_quantity                   -- 月首棚卸高
         ,factory_stock                          -- 工場入庫
         ,factory_stock_b                        -- 工場入庫振戻
         ,change_stock                           -- 倉替入庫
         ,others_stock                           -- 入出庫＿その他入庫
         ,truck_stock                            -- 営業車より入庫
         ,truck_ship                             -- 営業車へ出庫
         ,sales_shipped                          -- 売上出庫
         ,sales_shipped_b                        -- 売上出庫振戻
         ,return_goods                           -- 返品
         ,return_goods_b                         -- 返品振戻
         ,customer_sample_ship                   -- 顧客見本出庫
         ,customer_sample_ship_b                 -- 顧客見本出庫振戻
         ,customer_support_ss                    -- 顧客協賛見本出庫
         ,customer_support_ss_b                  -- 顧客協賛見本出庫振戻
         ,ccm_sample_ship                        -- 顧客広告宣伝費A自社商品
         ,ccm_sample_ship_b                      -- 顧客広告宣伝費A自社商品振戻
         ,vd_supplement_stock                    -- 消化VD補充入庫
         ,vd_supplement_ship                     -- 消化VD補充出庫
         ,removed_goods                          -- 廃却
         ,removed_goods_b                        -- 廃却振戻
         ,change_ship                            -- 倉替出庫
         ,others_ship                            -- 入出庫＿その他出庫
         ,factory_change                         -- 工場倉替
         ,factory_change_b                       -- 工場倉替振戻
         ,factory_return                         -- 工場返品
         ,factory_return_b                       -- 工場返品振戻
         ,location_decrease                      -- ロケーション移動増
         ,location_increase                      -- ロケーション移動減
         ,adjust_decrease                        -- 在庫調整増
         ,adjust_increase                        -- 在庫調整減
         ,book_inventory_quantity                -- 帳簿在庫数
         ,created_by                             -- 作成者
         ,creation_date                          -- 作成日
         ,last_updated_by                        -- 最終更新者
         ,last_update_date                       -- 最終更新日
         ,last_update_login                      -- 最終更新ログイン
         ,request_id                             -- 要求ID
         ,program_application_id                 -- アプリケーションID
         ,program_id                             -- プログラムID
         ,program_update_date                    -- プログラム更新日
        )VALUES(
          gt_bef_base_code                       -- 拠点コード
         ,gt_org_id                              -- 在庫組織ID
         ,gt_bef_subinventory_code               -- 保管場所コード
         ,gt_bef_subinv_type                     -- 保管場所区分
         ,gt_bef_location_code                   -- ロケーションコード
         ,gt_bef_practice_month                  -- 年月
         ,gt_bef_parent_item_id                  -- 親品目ID
         ,gt_bef_child_item_id                   -- 子品目ID
         ,gt_bef_lot                             -- ロット
         ,gt_bef_diff_sum_code                   -- 固有記号
         ,0                                      -- 月首棚卸高
         ,gt_factory_stock                       -- 工場入庫
         ,(gt_factory_stock_b) * cn_minus_1      -- 工場入庫振戻
         ,gt_change_stock                        -- 倉替入庫
         ,gt_others_stock                        -- 入出庫＿その他入庫
         ,gt_truck_stock                         -- 営業車より入庫
         ,(gt_truck_ship) * cn_minus_1           -- 営業車へ出庫
         ,(gt_sales_shipped) * cn_minus_1        -- 売上出庫
         ,gt_sales_shipped_b                     -- 売上出庫振戻
         ,gt_return_goods                        -- 返品
         ,(gt_return_goods_b) * cn_minus_1       -- 返品振戻
         ,(gt_customer_sample_ship) * cn_minus_1 -- 顧客見本出庫
         ,gt_customer_sample_ship_b              -- 顧客見本出庫振戻
         ,(gt_customer_support_ss) * cn_minus_1  -- 顧客協賛見本出庫
         ,gt_customer_support_ss_b               -- 顧客協賛見本出庫振戻
         ,(gt_ccm_sample_ship) * cn_minus_1      -- 顧客広告宣伝費A自社商品
         ,gt_ccm_sample_ship_b                   -- 顧客広告宣伝費A自社商品振戻
         ,gt_vd_supplement_stock                 -- 消化VD補充入庫
         ,(gt_vd_supplement_ship) * cn_minus_1   -- 消化VD補充出庫
         ,(gt_removed_goods) * cn_minus_1        -- 廃却
         ,gt_removed_goods_b                     -- 廃却振戻
         ,(gt_change_ship) * cn_minus_1          -- 倉替出庫
         ,(gt_others_ship) * cn_minus_1          -- 入出庫＿その他出庫
         ,(gt_factory_change) * cn_minus_1       -- 工場倉替
         ,gt_factory_change_b                    -- 工場倉替振戻
         ,(gt_factory_return) * cn_minus_1       -- 工場返品
         ,gt_factory_return_b                    -- 工場返品振戻
         ,gt_location_decrease                   -- ロケーション移動増
         ,(gt_location_increase) * cn_minus_1    -- ロケーション移動減
         ,gt_adjust_decrease                     -- 在庫調整増
         ,(gt_adjust_increase) * cn_minus_1      -- 在庫調整減
         ,gt_book_inventory_quantity             -- 帳簿在庫数
         ,cn_created_by                          -- 作成者
         ,cd_creation_date                       -- 作成日
         ,cn_last_updated_by                     -- 最終更新者
         ,cd_last_update_date                    -- 最終更新日
         ,cn_last_update_login                   -- 最終更新ログイン
         ,cn_request_id                          -- 要求ID
         ,cn_program_application_id              -- アプリケーションID
         ,cn_program_id                          -- プログラムID
         ,cd_program_update_date                 -- プログラム更新日
        );
--
        -- 成功件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      -- 存在する場合は、更新
      ELSE
        --==============================================================
        -- ロット別受払(累計)更新
        --==============================================================
        UPDATE xxcoi_lot_reception_sum xlrs
        SET    xlrs.factory_stock           = xlrs.factory_stock           + gt_factory_stock
                                                                        -- 工場入庫
              ,xlrs.factory_stock_b         = xlrs.factory_stock_b         + (gt_factory_stock_b) * cn_minus_1
                                                                        -- 工場入庫振戻
              ,xlrs.change_stock            = xlrs.change_stock            + gt_change_stock
                                                                        -- 倉替入庫
              ,xlrs.others_stock            = xlrs.others_stock            + gt_others_stock
                                                                        -- 入出庫＿その他入庫
              ,xlrs.truck_stock             = xlrs.truck_stock             + gt_truck_stock
                                                                        -- 営業車より入庫
              ,xlrs.truck_ship              = xlrs.truck_ship              + (gt_truck_ship) * cn_minus_1
                                                                        -- 営業車へ出庫
              ,xlrs.sales_shipped           = xlrs.sales_shipped           + (gt_sales_shipped) * cn_minus_1
                                                                        -- 売上出庫
              ,xlrs.sales_shipped_b         = xlrs.sales_shipped_b         + gt_sales_shipped_b
                                                                        -- 売上出庫振戻
              ,xlrs.return_goods            = xlrs.return_goods            + gt_return_goods
                                                                        -- 返品
              ,xlrs.return_goods_b          = xlrs.return_goods_b          + (gt_return_goods_b) * cn_minus_1
                                                                        -- 返品振戻
              ,xlrs.customer_sample_ship    = xlrs.customer_sample_ship    + (gt_customer_sample_ship) * cn_minus_1
                                                                        -- 顧客見本出庫
              ,xlrs.customer_sample_ship_b  = xlrs.customer_sample_ship_b  + gt_customer_sample_ship_b
                                                                        -- 顧客見本出庫振戻
              ,xlrs.customer_support_ss     = xlrs.customer_support_ss     + (gt_customer_support_ss) * cn_minus_1
                                                                        -- 顧客協賛見本出庫
              ,xlrs.customer_support_ss_b   = xlrs.customer_support_ss_b   + gt_customer_support_ss_b
                                                                        -- 顧客協賛見本出庫振戻
              ,xlrs.ccm_sample_ship         = xlrs.ccm_sample_ship         + (gt_ccm_sample_ship) * cn_minus_1
                                                                        -- 顧客広告宣伝費A自社商品
              ,xlrs.ccm_sample_ship_b       = xlrs.ccm_sample_ship_b       + gt_ccm_sample_ship_b
                                                                        -- 顧客広告宣伝費A自社商品振戻
              ,xlrs.vd_supplement_stock     = xlrs.vd_supplement_stock     + gt_vd_supplement_stock
                                                                        -- 消化VD補充入庫
              ,xlrs.vd_supplement_ship      = xlrs.vd_supplement_ship      + (gt_vd_supplement_ship) * cn_minus_1
                                                                        -- 消化VD補充出庫
              ,xlrs.removed_goods           = xlrs.removed_goods           + (gt_removed_goods) * cn_minus_1
                                                                        -- 廃却
              ,xlrs.removed_goods_b         = xlrs.removed_goods_b         + gt_removed_goods_b
                                                                        -- 廃却振戻
              ,xlrs.change_ship             = xlrs.change_ship             + (gt_change_ship) * cn_minus_1
                                                                        -- 倉替出庫
              ,xlrs.others_ship             = xlrs.others_ship             + (gt_others_ship) * cn_minus_1
                                                                        -- 入出庫＿その他出庫
              ,xlrs.factory_change          = xlrs.factory_change          + (gt_factory_change) * cn_minus_1
                                                                        -- 工場倉替
              ,xlrs.factory_change_b        = xlrs.factory_change_b        + gt_factory_change_b
                                                                        -- 工場倉替振戻
              ,xlrs.factory_return          = xlrs.factory_return          + (gt_factory_return) * cn_minus_1
                                                                        -- 工場返品
              ,xlrs.factory_return_b        = xlrs.factory_return_b        + gt_factory_return_b
                                                                        -- 工場返品振戻
              ,xlrs.location_decrease       = xlrs.location_decrease       + gt_location_decrease
                                                                        -- ロケーション移動増
              ,xlrs.location_increase       = xlrs.location_increase       + (gt_location_increase) * cn_minus_1
                                                                        -- ロケーション移動減
              ,xlrs.adjust_decrease         = xlrs.adjust_decrease         + gt_adjust_decrease
                                                                        -- 在庫調整増
              ,xlrs.adjust_increase         = xlrs.adjust_increase         + (gt_adjust_increase) * cn_minus_1
                                                                        -- 在庫調整減
              ,xlrs.book_inventory_quantity = xlrs.book_inventory_quantity + gt_book_inventory_quantity
                                                                        -- 帳簿在庫数
              ,xlrs.last_updated_by         = cn_last_updated_by        -- 最終更新者
              ,xlrs.last_update_date        = cd_last_update_date       -- 最終更新日
              ,xlrs.last_update_login       = cn_last_update_login      -- 最終更新ログイン
              ,xlrs.request_id              = cn_request_id             -- 要求ID
              ,xlrs.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
              ,xlrs.program_id              = cn_program_id             -- コンカレント・プログラムID
              ,xlrs.program_update_date     = cd_program_update_date    -- プログラム更新日
        WHERE  xlrs.practice_month          = gt_bef_practice_month     -- 取引年月
        AND    xlrs.base_code               = gt_bef_base_code          -- 拠点コード
        AND    xlrs.subinventory_code       = gt_bef_subinventory_code  -- 保管場所コード
        AND    xlrs.location_code           = gt_bef_location_code      -- ロケーションコード
        AND    xlrs.parent_item_id          = gt_bef_parent_item_id     -- 親品目ID
        AND    xlrs.child_item_id           = gt_bef_child_item_id      -- 子品目ID
        AND    xlrs.lot                     = gt_bef_lot                -- ロット
        AND    xlrs.difference_summary_code = gt_bef_diff_sum_code      -- 固有記号
        ;
--
        -- 成功件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END IF;
--
      -- 取引年月が業務日付の年月より過去の場合
      IF ( gt_bef_practice_month < lv_proc_date_yyyymm ) THEN
--
        --==============================================================
        -- ロット別受払(累計)当月データ存在チェック
        --==============================================================
        SELECT COUNT(1)
        INTO   ln_exist_chk2                                           -- 存在チェック
        FROM   xxcoi_lot_reception_sum xlrs
        WHERE  xlrs.practice_month          = lv_proc_date_yyyymm      -- 取引年月
        AND    xlrs.base_code               = gt_bef_base_code         -- 拠点コード
        AND    xlrs.subinventory_code       = gt_bef_subinventory_code -- 保管場所コード
        AND    xlrs.location_code           = gt_bef_location_code     -- ロケーションコード
        AND    xlrs.parent_item_id          = gt_bef_parent_item_id    -- 親品目ID
        AND    xlrs.child_item_id           = gt_bef_child_item_id     -- 子品目ID
        AND    xlrs.lot                     = gt_bef_lot               -- ロット
        AND    xlrs.difference_summary_code = gt_bef_diff_sum_code     -- 固有記号
        AND    ROWNUM                       = 1
        ;
--
        -- 当月データが存在しない場合は、新規作成
        IF ( ln_exist_chk2 = 0 ) THEN
--
          --==============================================================
          -- ロット別受払(累計)当月データ新規作成
          --==============================================================
          INSERT INTO xxcoi_lot_reception_sum(
            base_code                  -- 拠点コード
           ,organization_id            -- 在庫組織ID
           ,subinventory_code          -- 保管場所コード
           ,subinventory_type          -- 保管場所区分
           ,location_code              -- ロケーションコード
           ,practice_month             -- 年月
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
           ,created_by                 -- 作成者
           ,creation_date              -- 作成日
           ,last_updated_by            -- 最終更新者
           ,last_update_date           -- 最終更新日
           ,last_update_login          -- 最終更新ログイン
           ,request_id                 -- 要求ID
           ,program_application_id     -- アプリケーションID
           ,program_id                 -- プログラムID
           ,program_update_date        -- プログラム更新日
          )VALUES(
            gt_bef_base_code           -- 拠点コード
           ,gt_org_id                  -- 在庫組織ID
           ,gt_bef_subinventory_code   -- 保管場所コード
           ,gt_bef_subinv_type         -- 保管場所区分
           ,gt_bef_location_code       -- ロケーションコード
           ,lv_proc_date_yyyymm        -- 年月
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
           ,0                          -- 顧客広告宣伝費A自社商品振戻
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
           ,cn_created_by              -- 作成者
           ,cd_creation_date           -- 作成日
           ,cn_last_updated_by         -- 最終更新者
           ,cd_last_update_date        -- 最終更新日
           ,cn_last_update_login       -- 最終更新ログイン
           ,cn_request_id              -- 要求ID
           ,cn_program_application_id  -- アプリケーションID
           ,cn_program_id              -- プログラムID
           ,cd_program_update_date     -- プログラム更新日
          );
--
          -- 成功件数カウントアップ
          gn_normal_cnt := gn_normal_cnt + 1;
--
        -- 当月データが存在する場合は、更新
        ELSE
--
          --==============================================================
          -- ロット別受払(累計)当月データ更新
          --==============================================================
          UPDATE xxcoi_lot_reception_sum xlrs
          SET    xlrs.month_begin_quantity    = xlrs.month_begin_quantity + gt_book_inventory_quantity
                                                                          -- 月初棚卸高
                ,xlrs.book_inventory_quantity = xlrs.book_inventory_quantity + gt_book_inventory_quantity
                                                                          -- 帳簿在庫数
                ,xlrs.last_updated_by         = cn_last_updated_by        -- 最終更新者
                ,xlrs.last_update_date        = cd_last_update_date       -- 最終更新日
                ,xlrs.last_update_login       = cn_last_update_login      -- 最終更新ログイン
                ,xlrs.request_id              = cn_request_id             -- 要求ID
                ,xlrs.program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
                ,xlrs.program_id              = cn_program_id             -- コンカレント・プログラムID
                ,xlrs.program_update_date     = cd_program_update_date    -- プログラム更新日
          WHERE  xlrs.practice_month          = lv_proc_date_yyyymm       -- 取引年月
          AND    xlrs.base_code               = gt_bef_base_code          -- 拠点コード
          AND    xlrs.subinventory_code       = gt_bef_subinventory_code  -- 保管場所コード
          AND    xlrs.location_code           = gt_bef_location_code      -- ロケーションコード
          AND    xlrs.parent_item_id          = gt_bef_parent_item_id     -- 親品目ID
          AND    xlrs.child_item_id           = gt_bef_child_item_id      -- 子品目ID
          AND    xlrs.lot                     = gt_bef_lot                -- ロット
          AND    xlrs.difference_summary_code = gt_bef_diff_sum_code      -- 固有記号
          ;
--
          -- 成功件数カウントアップ
          gn_normal_cnt := gn_normal_cnt + 1;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -- 変数のリセット
    -- 前レコードロット情報保持用変数
    gt_bef_practice_month        := NULL;      -- 取引年月
    gt_bef_practice_date         := NULL;      -- 取引日
    gt_bef_base_code             := NULL;      -- 拠点コード
    gt_bef_subinventory_code     := NULL;      -- 保管場所コード
    gt_bef_subinv_type           := NULL;      -- 保管場所区分
    gt_bef_location_code         := NULL;      -- ロケーションコード
    gt_bef_parent_item_id        := NULL;      -- 親品目ID
    gt_bef_child_item_id         := NULL;      -- 子品目ID
    gt_bef_lot                   := NULL;      -- ロット
    gt_bef_diff_sum_code         := NULL;      -- 固有記号
--
    -- 受払項目計算結果保持用変数
    gt_factory_stock             := 0;         -- 工場入庫
    gt_factory_stock_b           := 0;         -- 工場入庫振戻
    gt_change_stock              := 0;         -- 倉替入庫
    gt_others_stock              := 0;         -- 入出庫＿その他入庫
    gt_truck_stock               := 0;         -- 営業車より入庫
    gt_truck_ship                := 0;         -- 営業車へ出庫
    gt_sales_shipped             := 0;         -- 売上出庫
    gt_sales_shipped_b           := 0;         -- 売上出庫振戻
    gt_return_goods              := 0;         -- 返品
    gt_return_goods_b            := 0;         -- 返品振戻
    gt_customer_sample_ship      := 0;         -- 顧客見本出庫
    gt_customer_sample_ship_b    := 0;         -- 顧客見本出庫振戻
    gt_customer_support_ss       := 0;         -- 顧客協賛見本出庫
    gt_customer_support_ss_b     := 0;         -- 顧客協賛見本出庫振戻
    gt_ccm_sample_ship           := 0;         -- 顧客広告宣伝費A自社商品
    gt_ccm_sample_ship_b         := 0;         -- 顧客広告宣伝費A自社商品振戻
    gt_vd_supplement_stock       := 0;         -- 消化VD補充入庫
    gt_vd_supplement_ship        := 0;         -- 消化VD補充出庫
    gt_removed_goods             := 0;         -- 廃却
    gt_removed_goods_b           := 0;         -- 廃却振戻
    gt_change_ship               := 0;         -- 倉替出庫
    gt_others_ship               := 0;         -- 入出庫＿その他出庫
    gt_factory_change            := 0;         -- 工場倉替
    gt_factory_change_b          := 0;         -- 工場倉替振戻
    gt_factory_return            := 0;         -- 工場返品
    gt_factory_return_b          := 0;         -- 工場返品振戻
    gt_location_decrease         := 0;         -- ロケーション移動増
    gt_location_increase         := 0;         -- ロケーション移動減
    gt_adjust_decrease           := 0;         -- 在庫調整増
    gt_adjust_increase           := 0;         -- 在庫調整減
    gt_book_inventory_quantity   := 0;         -- 帳簿在庫数
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
  END cre_inout_data;
--
  /**********************************************************************************
   * Procedure Name   : cal_inout_data
   * Description      : 受払項目算出処理(A-4)
   ***********************************************************************************/
  PROCEDURE cal_inout_data(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
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
    gt_bef_practice_month        := NULL;      -- 取引年月
    gt_bef_practice_date         := NULL;      -- 取引日
    gt_bef_base_code             := NULL;      -- 拠点コード
    gt_bef_subinventory_code     := NULL;      -- 保管場所コード
    gt_bef_subinv_type           := NULL;      -- 保管場所区分
    gt_bef_location_code         := NULL;      -- ロケーションコード
    gt_bef_parent_item_id        := NULL;      -- 親品目ID
    gt_bef_child_item_id         := NULL;      -- 子品目ID
    gt_bef_lot                   := NULL;      -- ロット
    gt_bef_diff_sum_code         := NULL;      -- 固有記号
--
    -- 受払項目計算結果保持用変数
    gt_factory_stock             := 0;         -- 工場入庫
    gt_factory_stock_b           := 0;         -- 工場入庫振戻
    gt_change_stock              := 0;         -- 倉替入庫
    gt_others_stock              := 0;         -- 入出庫＿その他入庫
    gt_truck_stock               := 0;         -- 営業車より入庫
    gt_truck_ship                := 0;         -- 営業車へ出庫
    gt_sales_shipped             := 0;         -- 売上出庫
    gt_sales_shipped_b           := 0;         -- 売上出庫振戻
    gt_return_goods              := 0;         -- 返品
    gt_return_goods_b            := 0;         -- 返品振戻
    gt_customer_sample_ship      := 0;         -- 顧客見本出庫
    gt_customer_sample_ship_b    := 0;         -- 顧客見本出庫振戻
    gt_customer_support_ss       := 0;         -- 顧客協賛見本出庫
    gt_customer_support_ss_b     := 0;         -- 顧客協賛見本出庫振戻
    gt_ccm_sample_ship           := 0;         -- 顧客広告宣伝費A自社商品
    gt_ccm_sample_ship_b         := 0;         -- 顧客広告宣伝費A自社商品振戻
    gt_vd_supplement_stock       := 0;         -- 消化VD補充入庫
    gt_vd_supplement_ship        := 0;         -- 消化VD補充出庫
    gt_removed_goods             := 0;         -- 廃却
    gt_removed_goods_b           := 0;         -- 廃却振戻
    gt_change_ship               := 0;         -- 倉替出庫
    gt_others_ship               := 0;         -- 入出庫＿その他出庫
    gt_factory_change            := 0;         -- 工場倉替
    gt_factory_change_b          := 0;         -- 工場倉替振戻
    gt_factory_return            := 0;         -- 工場返品
    gt_factory_return_b          := 0;         -- 工場返品振戻
    gt_location_decrease         := 0;         -- ロケーション移動増
    gt_location_increase         := 0;         -- ロケーション移動減
    gt_adjust_decrease           := 0;         -- 在庫調整増
    gt_adjust_increase           := 0;         -- 在庫調整減
    gt_book_inventory_quantity   := 0;         -- 帳簿在庫数
--
    -- ローカル変数
    lv_not_exist_flag            := cv_flag_n; -- 最終レコードフラグ
--
    -- ------------------------------------
    -- 1レコード目フェッチ
    -- ------------------------------------
    FETCH get_rep_data_cur INTO g_get_rep_data_rec;
    -- 対象件数カウント
    gn_target_cnt := gn_target_cnt + 1;
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
      gt_bef_practice_date     := g_get_rep_data_rec.trx_date;       -- 取引日
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
      FETCH get_rep_data_cur INTO g_get_rep_data_rec;
      -- 新規レコードを取得できなかった場合は、最終レコードフラグを'Y'にする
      IF ( get_rep_data_cur%NOTFOUND ) THEN
        lv_not_exist_flag := cv_flag_y;
      -- 新規レコードを取得できた場合は、対象件数をカウントする
      ELSE
        gn_target_cnt := gn_target_cnt + 1;
      END IF;
--
      --==============================================================
      -- 登録・更新処理実行判定
      --==============================================================
      -- 最終レコードの場合、登録・更新処理を実行し、ループを抜ける
      IF ( lv_not_exist_flag = cv_flag_y ) THEN
        --==============================================================
        -- ロット別受払(日次・累計)データ登録・更新処理 (A-5)
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
      ELSE
        -- ------------------------------------
        -- 日次実行の場合
        -- ------------------------------------
        IF ( gv_startup_flg = cv_startup_flg_1 ) THEN
          --==============================================================
          -- 取得したレコード情報と前レコード情報が完全一致するかチェック
          --==============================================================
          -- 一致する場合は、取引タイプ、引当時取引タイプコード別数量の計算を継続
          IF (
                gt_bef_practice_date     = g_get_rep_data_rec.trx_date       -- 取引日
            AND gt_bef_base_code         = g_get_rep_data_rec.base_code      -- 拠点コード
            AND gt_bef_subinventory_code = g_get_rep_data_rec.subinv_code    -- 保管場所コード
            AND gt_bef_subinv_type       = g_get_rep_data_rec.subinv_type    -- 保管場所区分
            AND gt_bef_location_code     = g_get_rep_data_rec.location_code  -- ロケーションコード
            AND gt_bef_parent_item_id    = g_get_rep_data_rec.parent_item_id -- 親品目ID
            AND gt_bef_child_item_id     = g_get_rep_data_rec.child_item_id  -- 子品目ID
            AND gt_bef_lot               = g_get_rep_data_rec.lot            -- ロット
            AND gt_bef_diff_sum_code     = g_get_rep_data_rec.diff_sum_code  -- 固有記号
          ) THEN
            NULL;
--
          -- 一致しない場合は、登録・更新処理を実行
          ELSE
            --==============================================================
            -- ロット別受払(日次・累計)データ登録・更新処理 (A-5)
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
        -- ------------------------------------
        -- 累計実行の場合
        -- ------------------------------------
        ELSE
          --==============================================================
          -- 取得したレコード情報と前レコード情報が完全一致するかチェック
          --==============================================================
          -- 一致する場合は、取引タイプ、引当時取引タイプコード別数量の計算を継続
          IF (
                gt_bef_practice_month    = g_get_rep_data_rec.trx_month      -- 取引日
            AND gt_bef_base_code         = g_get_rep_data_rec.base_code      -- 拠点コード
            AND gt_bef_subinventory_code = g_get_rep_data_rec.subinv_code    -- 保管場所コード
            AND gt_bef_subinv_type       = g_get_rep_data_rec.subinv_type    -- 保管場所区分
            AND gt_bef_location_code     = g_get_rep_data_rec.location_code  -- ロケーションコード
            AND gt_bef_parent_item_id    = g_get_rep_data_rec.parent_item_id -- 親品目ID
            AND gt_bef_child_item_id     = g_get_rep_data_rec.child_item_id  -- 子品目ID
            AND gt_bef_lot               = g_get_rep_data_rec.lot            -- ロット
            AND gt_bef_diff_sum_code     = g_get_rep_data_rec.diff_sum_code  -- 固有記号

          ) THEN
            NULL;
          -- 一致しない場合は、登録・更新処理を実行
          ELSE
            --==============================================================
            -- ロット別受払(日次・累計)データ登録・更新処理 (A-5)
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
      END IF;
--
    END LOOP rep_data_loop;
--
  EXCEPTION
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
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
    OPEN get_rep_data_cur;
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
    CLOSE get_rep_data_cur;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( get_rep_data_cur%ISOPEN ) THEN
        CLOSE get_rep_data_cur;
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
      -- カーソルクローズ
      IF ( get_rep_data_cur%ISOPEN ) THEN
        CLOSE get_rep_data_cur;
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
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
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
    -- 日次繰越データ作成用カーソル
    CURSOR pre_date_cur(
      id_practice_date DATE -- 対象日
    )IS
      SELECT xlrd.base_code               base_code          -- 拠点コード
            ,xlrd.subinventory_code       subinv_code        -- 保管場所
            ,xlrd.subinventory_type       subinv_type        -- 保管場所区分
            ,xlrd.location_code           location_code      -- ロケーションコード
            ,xlrd.parent_item_id          parent_item_id     -- 親品目ID
            ,xlrd.child_item_id           child_item_id      -- 子品目ID
            ,xlrd.lot                     lot                -- ロット
            ,xlrd.difference_summary_code diff_sum_code      -- 固有記号
            ,xlrd.book_inventory_quantity book_inv_qty       -- 帳簿在庫数
      FROM   xxcoi_lot_reception_daily xlrd                  -- ロット別受払(日次)
      WHERE  xlrd.practice_date           = id_practice_date -- 対象日
      AND    xlrd.book_inventory_quantity > 0
    ;
--
    -- 累計繰越データ作成用カーソル
    CURSOR pre_sum_cur(
      iv_practice_month VARCHAR2 -- 対象年月
    )IS
      SELECT xlrs.base_code               base_code           -- 拠点コード
            ,xlrs.subinventory_code       subinv_code         -- 保管場所
            ,xlrs.subinventory_type       subinv_type         -- 保管場所区分
            ,xlrs.location_code           location_code       -- ロケーションコード
            ,xlrs.parent_item_id          parent_item_id      -- 親品目ID
            ,xlrs.child_item_id           child_item_id       -- 子品目ID
            ,xlrs.lot                     lot                 -- ロット
            ,xlrs.difference_summary_code diff_sum_code       -- 固有記号
            ,xlrs.book_inventory_quantity book_inv_qty        -- 帳簿在庫数
      FROM   xxcoi_lot_reception_sum xlrs                     -- ロット別受払(累計)
      WHERE  xlrs.practice_month          = iv_practice_month -- 対象年月
      AND    xlrs.book_inventory_quantity > 0
    ;
--
    -- *** ローカル・レコード ***
    l_pre_date_rec pre_date_cur%ROWTYPE; -- 日次繰越データ格納用レコード
    l_pre_sum_rec  pre_sum_cur%ROWTYPE;  -- 累計繰越データ格納用レコード
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
-- 2015/04/07 E_本稼動_12237 V1.1 DEL START
--    -- 変数初期化
--    ln_data_cre_judge := 0;
--
    --==============================================================
    -- 初回起動の判定
    --==============================================================
--    -- 日次実行の場合
--    IF ( gv_startup_flg = cv_startup_flg_1 ) THEN
--      SELECT COUNT(1)
--      INTO   ln_data_cre_judge
--      FROM   xxcoi_lot_reception_daily xlrd
--      WHERE  xlrd.practice_date = gd_proc_date -- 業務日付
--      AND    ROWNUM = 1
--      ;
--    -- 累計実行の場合
--    ELSE
--      SELECT COUNT(1)
--      INTO   ln_data_cre_judge
--      FROM   xxcoi_lot_reception_sum xlrs
--      WHERE  xlrs.practice_month = TO_CHAR( gd_proc_date, cv_yyyymm ) -- 業務日付の年月
--      AND    ROWNUM = 1
--      ;
--    END IF;
-- 2015/04/07 E_本稼動_12237 V1.1 DEL END
--
    --==============================================================
    -- 繰越データ作成
    --==============================================================
-- 2015/04/07 E_本稼動_12237 V1.1 DEL START
--    -- 繰越データ作成判定が0の場合のみ実行
--    IF ( ln_data_cre_judge = 0 ) THEN
-- 2015/04/07 E_本稼動_12237 V1.1 DEL END
    -- 日次実行
    IF ( gv_startup_flg = cv_startup_flg_1 ) THEN
      -- 日次繰越データ作成用カーソルオープン
      OPEN pre_date_cur(
        id_practice_date => gt_pre_exe_date -- 前回処理日
      );
--
      <<pre_date_loop>>
      LOOP
        -- データフェッチ
        FETCH pre_date_cur INTO l_pre_date_rec;
        EXIT WHEN pre_date_cur%NOTFOUND;
--
        -- 取得件数カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
-- 2015/04/07 E_本稼動_12237 V1.1 ADD START
        -- 変数初期化
        ln_data_cre_judge := 0;
--
        -- 年月日＝業務日付の当日データが存在するかチェック
        SELECT COUNT(1) AS cnt
        INTO   ln_data_cre_judge
        FROM   xxcoi_lot_reception_daily xlrd  -- ロット別受払(日次)
        WHERE  xlrd.practice_date           = gd_proc_date                  -- 年月日
        AND    xlrd.base_code               = l_pre_date_rec.base_code      -- 拠点コード
        AND    xlrd.subinventory_code       = l_pre_date_rec.subinv_code    -- 保管場所コード
        AND    xlrd.location_code           = l_pre_date_rec.location_code  -- ロケーションコード
        AND    xlrd.parent_item_id          = l_pre_date_rec.parent_item_id -- 親品目ID
        AND    xlrd.child_item_id           = l_pre_date_rec.child_item_id  -- 子品目ID
        AND    xlrd.lot                     = l_pre_date_rec.lot            -- ロット
        AND    xlrd.difference_summary_code = l_pre_date_rec.diff_sum_code  -- 固有記号
        AND    ROWNUM = 1
        ;
--
        -- 年月日＝業務日付の当日データが存在しない場合
        IF ( ln_data_cre_judge = 0 ) THEN
-- 2015/04/07 E_本稼動_12237 V1.1 ADD END
          -- 繰越データ作成
          INSERT INTO xxcoi_lot_reception_daily(
            base_code                     -- 拠点コード
           ,organization_id               -- 在庫組織ID
           ,subinventory_code             -- 保管場所
           ,subinventory_type             -- 保管場所区分
           ,location_code                 -- ロケーションコード
           ,practice_date                 -- 年月日
           ,parent_item_id                -- 親品目ID
           ,child_item_id                 -- 子品目ID
           ,lot                           -- ロット
           ,difference_summary_code       -- 固有記号
           ,previous_inventory_quantity   -- 前日在庫数
           ,factory_stock                 -- 工場入庫
           ,factory_stock_b               -- 工場入庫振戻
           ,change_stock                  -- 倉替入庫
           ,others_stock                  -- 入出庫＿その他入庫
           ,truck_stock                   -- 営業車より入庫
           ,truck_ship                    -- 営業車へ出庫
           ,sales_shipped                 -- 売上出庫
           ,sales_shipped_b               -- 売上出庫振戻
           ,return_goods                  -- 返品
           ,return_goods_b                -- 返品振戻
           ,customer_sample_ship          -- 顧客見本出庫
           ,customer_sample_ship_b        -- 顧客見本出庫振戻
           ,customer_support_ss           -- 顧客協賛見本出庫
           ,customer_support_ss_b         -- 顧客協賛見本出庫振戻
           ,ccm_sample_ship               -- 顧客広告宣伝費A自社商品
           ,ccm_sample_ship_b             -- 顧客広告宣伝費A自社商品振戻
           ,vd_supplement_stock           -- 消化VD補充入庫
           ,vd_supplement_ship            -- 消化VD補充出庫
           ,removed_goods                 -- 廃却
           ,removed_goods_b               -- 廃却振戻
           ,change_ship                   -- 倉替出庫
           ,others_ship                   -- 入出庫＿その他出庫
           ,factory_change                -- 工場倉替
           ,factory_change_b              -- 工場倉替振戻
           ,factory_return                -- 工場返品
           ,factory_return_b              -- 工場返品振戻
           ,location_decrease             -- ロケーション移動増
           ,location_increase             -- ロケーション移動減
           ,adjust_decrease               -- 在庫調整増
           ,adjust_increase               -- 在庫調整減
           ,book_inventory_quantity       -- 帳簿在庫数
           ,created_by                    -- 作成者
           ,creation_date                 -- 作成日
           ,last_updated_by               -- 最終更新者
           ,last_update_date              -- 最終更新日
           ,last_update_login             -- 最終更新ログイン
           ,request_id                    -- 要求ID
           ,program_application_id        -- アプリケーションID
           ,program_id                    -- プログラムID
           ,program_update_date           -- プログラム更新日
          )VALUES(
            l_pre_date_rec.base_code      -- 拠点コード
           ,gt_org_id                     -- 在庫組織ID
           ,l_pre_date_rec.subinv_code    -- 保管場所
           ,l_pre_date_rec.subinv_type    -- 保管場所区分
           ,l_pre_date_rec.location_code  -- ロケーションコード
           ,gd_proc_date                  -- 年月日
           ,l_pre_date_rec.parent_item_id -- 親品目ID
           ,l_pre_date_rec.child_item_id  -- 子品目ID
           ,l_pre_date_rec.lot            -- ロット
           ,l_pre_date_rec.diff_sum_code  -- 固有記号
           ,l_pre_date_rec.book_inv_qty   -- 前日在庫数
           ,0                             -- 工場入庫
           ,0                             -- 工場入庫振戻
           ,0                             -- 倉替入庫
           ,0                             -- 入出庫＿その他入庫
           ,0                             -- 営業車より入庫
           ,0                             -- 営業車へ出庫
           ,0                             -- 売上出庫
           ,0                             -- 売上出庫振戻
           ,0                             -- 返品
           ,0                             -- 返品振戻
           ,0                             -- 顧客見本出庫
           ,0                             -- 顧客見本出庫振戻
           ,0                             -- 顧客協賛見本出庫
           ,0                             -- 顧客協賛見本出庫振戻
           ,0                             -- 顧客広告宣伝費A自社商品
           ,0                             -- 顧客広告宣伝費A自社商品振戻
           ,0                             -- 消化VD補充入庫
           ,0                             -- 消化VD補充出庫
           ,0                             -- 廃却
           ,0                             -- 廃却振戻
           ,0                             -- 倉替出庫
           ,0                             -- 入出庫＿その他出庫
           ,0                             -- 工場倉替
           ,0                             -- 工場倉替振戻
           ,0                             -- 工場返品
           ,0                             -- 工場返品振戻
           ,0                             -- ロケーション移動増
           ,0                             -- ロケーション移動減
           ,0                             -- 在庫調整増
           ,0                             -- 在庫調整減
           ,l_pre_date_rec.book_inv_qty   -- 帳簿在庫数
           ,cn_created_by                 -- 作成者
           ,cd_creation_date              -- 作成日
           ,cn_last_updated_by            -- 最終更新者
           ,cd_last_update_date           -- 最終更新日
           ,cn_last_update_login          -- 最終更新ログイン
           ,cn_request_id                 -- 要求ID
           ,cn_program_application_id     -- アプリケーションID
           ,cn_program_id                 -- プログラムID
           ,cd_program_update_date        -- プログラム更新日
          );
--
-- 2015/04/07 E_本稼動_12237 V1.1 ADD START
        -- 年月日＝業務日付の当日データが存在する場合は更新
        ELSE
          UPDATE xxcoi_lot_reception_daily  -- ロット別受払(日次)
          SET    previous_inventory_quantity = l_pre_date_rec.book_inv_qty     -- 前日在庫数
                ,book_inventory_quantity     = book_inventory_quantity
                                                 + l_pre_date_rec.book_inv_qty -- 帳簿在庫数
                ,last_updated_by             = cn_last_updated_by              -- 最終更新者
                ,last_update_date            = cd_last_update_date             -- 最終更新日
                ,last_update_login           = cn_last_update_login            -- 最終更新ログイン
                ,request_id                  = cn_request_id                   -- 要求ID
                ,program_application_id      = cn_program_application_id       -- アプリケーションID
                ,program_id                  = cn_program_id                   -- プログラムID
                ,program_update_date         = cd_program_update_date          -- プログラム更新日
          WHERE  practice_date               = gd_proc_date                  -- 年月日
          AND    base_code                   = l_pre_date_rec.base_code      -- 拠点コード
          AND    subinventory_code           = l_pre_date_rec.subinv_code    -- 保管場所コード
          AND    location_code               = l_pre_date_rec.location_code  -- ロケーションコード
          AND    parent_item_id              = l_pre_date_rec.parent_item_id -- 親品目ID
          AND    child_item_id               = l_pre_date_rec.child_item_id  -- 子品目ID
          AND    lot                         = l_pre_date_rec.lot            -- ロット
          AND    difference_summary_code     = l_pre_date_rec.diff_sum_code  -- 固有記号
          ;
        END IF;
-- 2015/04/07 E_本稼動_12237 V1.1 ADD END
--
        -- 成功件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP pre_date_loop;
--
      -- 日次繰越データ作成用カーソルクローズ
      CLOSE pre_date_cur;
--
    -- 累計実行
    ELSE
-- 2015/04/20 E_本稼動_12237 V1.2 ADD START
      -- 当月の初回起動の場合
      IF ( TO_CHAR(gt_pre_exe_date,cv_yyyymm) <> TO_CHAR(gd_proc_date,cv_yyyymm) ) THEN
-- 2015/04/20 E_本稼動_12237 V1.2 ADD END
      -- 累計繰越データ作成用カーソルオープン
      OPEN pre_sum_cur(
        iv_practice_month => TO_CHAR( ADD_MONTHS( gd_proc_date, -1 ), cv_yyyymm ) -- 業務日付の前月
      );
--
      <<pre_sum_loop>>
      LOOP
--
        -- データフェッチ
        FETCH pre_sum_cur INTO l_pre_sum_rec;
        EXIT WHEN pre_sum_cur%NOTFOUND;
--
        -- 取得件数カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
-- 2015/04/07 E_本稼動_12237 V1.1 ADD START
        -- 変数初期化
        ln_data_cre_judge := 0;
--
        -- 年月＝業務日付月の当月データが存在するかチェック
        SELECT COUNT(1) AS cnt
        INTO   ln_data_cre_judge
        FROM   xxcoi_lot_reception_sum xlrs  -- ロット別受払(累計)
        WHERE  xlrs.practice_month          = TO_CHAR( gd_proc_date, cv_yyyymm ) -- 年月
        AND    xlrs.base_code               = l_pre_sum_rec.base_code            -- 拠点コード
        AND    xlrs.subinventory_code       = l_pre_sum_rec.subinv_code          -- 保管場所コード
        AND    xlrs.location_code           = l_pre_sum_rec.location_code        -- ロケーションコード
        AND    xlrs.parent_item_id          = l_pre_sum_rec.parent_item_id       -- 親品目ID
        AND    xlrs.child_item_id           = l_pre_sum_rec.child_item_id        -- 子品目ID
        AND    xlrs.lot                     = l_pre_sum_rec.lot                  -- ロット
        AND    xlrs.difference_summary_code = l_pre_sum_rec.diff_sum_code        -- 固有記号
        AND    ROWNUM = 1
        ;
--
        -- 年月＝業務日付月の当月データが存在しない場合
        IF ( ln_data_cre_judge = 0 ) THEN
-- 2015/04/07 E_本稼動_12237 V1.1 ADD END
          -- 繰越データ作成
          INSERT INTO xxcoi_lot_reception_sum(
            base_code                          -- 拠点コード
           ,organization_id                    -- 在庫組織ID
           ,subinventory_code                  -- 保管場所コード
           ,subinventory_type                  -- 保管場所区分
           ,location_code                      -- ロケーションコード
           ,practice_month                     -- 年月
           ,parent_item_id                     -- 親品目ID
           ,child_item_id                      -- 子品目ID
           ,lot                                -- ロット
           ,difference_summary_code            -- 固有記号
           ,month_begin_quantity               -- 月首棚卸高
           ,factory_stock                      -- 工場入庫
           ,factory_stock_b                    -- 工場入庫振戻
           ,change_stock                       -- 倉替入庫
           ,others_stock                       -- 入出庫＿その他入庫
           ,truck_stock                        -- 営業車より入庫
           ,truck_ship                         -- 営業車へ出庫
           ,sales_shipped                      -- 売上出庫
           ,sales_shipped_b                    -- 売上出庫振戻
           ,return_goods                       -- 返品
           ,return_goods_b                     -- 返品振戻
           ,customer_sample_ship               -- 顧客見本出庫
           ,customer_sample_ship_b             -- 顧客見本出庫振戻
           ,customer_support_ss                -- 顧客協賛見本出庫
           ,customer_support_ss_b              -- 顧客協賛見本出庫振戻
           ,ccm_sample_ship                    -- 顧客広告宣伝費A自社商品
           ,ccm_sample_ship_b                  -- 顧客広告宣伝費A自社商品振戻
           ,vd_supplement_stock                -- 消化VD補充入庫
           ,vd_supplement_ship                 -- 消化VD補充出庫
           ,removed_goods                      -- 廃却
           ,removed_goods_b                    -- 廃却振戻
           ,change_ship                        -- 倉替出庫
           ,others_ship                        -- 入出庫＿その他出庫
           ,factory_change                     -- 工場倉替
           ,factory_change_b                   -- 工場倉替振戻
           ,factory_return                     -- 工場返品
           ,factory_return_b                   -- 工場返品振戻
           ,location_decrease                  -- ロケーション移動増
           ,location_increase                  -- ロケーション移動減
           ,adjust_decrease                    -- 在庫調整増
           ,adjust_increase                    -- 在庫調整減
           ,book_inventory_quantity            -- 帳簿在庫数
           ,created_by                         -- 作成者
           ,creation_date                      -- 作成日
           ,last_updated_by                    -- 最終更新者
           ,last_update_date                   -- 最終更新日
           ,last_update_login                  -- 最終更新ログイン
           ,request_id                         -- 要求ID
           ,program_application_id             -- アプリケーションID
           ,program_id                         -- プログラムID
           ,program_update_date                -- プログラム更新日
          )VALUES(
            l_pre_sum_rec.base_code            -- 拠点コード
           ,gt_org_id                          -- 在庫組織ID
           ,l_pre_sum_rec.subinv_code          -- 保管場所コード
           ,l_pre_sum_rec.subinv_type          -- 保管場所区分
           ,l_pre_sum_rec.location_code        -- ロケーションコード
           ,TO_CHAR( gd_proc_date, cv_yyyymm ) -- 年月
           ,l_pre_sum_rec.parent_item_id       -- 親品目ID
           ,l_pre_sum_rec.child_item_id        -- 子品目ID
           ,l_pre_sum_rec.lot                  -- ロット
           ,l_pre_sum_rec.diff_sum_code        -- 固有記号
           ,l_pre_sum_rec.book_inv_qty         -- 月首棚卸高
           ,0                                  -- 工場入庫
           ,0                                  -- 工場入庫振戻
           ,0                                  -- 倉替入庫
           ,0                                  -- 入出庫＿その他入庫
           ,0                                  -- 営業車より入庫
           ,0                                  -- 営業車へ出庫
           ,0                                  -- 売上出庫
           ,0                                  -- 売上出庫振戻
           ,0                                  -- 返品
           ,0                                  -- 返品振戻
           ,0                                  -- 顧客見本出庫
           ,0                                  -- 顧客見本出庫振戻
           ,0                                  -- 顧客協賛見本出庫
           ,0                                  -- 顧客協賛見本出庫振戻
           ,0                                  -- 顧客広告宣伝費A自社商品
           ,0                                  -- 顧客広告宣伝費A自社商品振戻
           ,0                                  -- 消化VD補充入庫
           ,0                                  -- 消化VD補充出庫
           ,0                                  -- 廃却
           ,0                                  -- 廃却振戻
           ,0                                  -- 倉替出庫
           ,0                                  -- 入出庫＿その他出庫
           ,0                                  -- 工場倉替
           ,0                                  -- 工場倉替振戻
           ,0                                  -- 工場返品
           ,0                                  -- 工場返品振戻
           ,0                                  -- ロケーション移動増
           ,0                                  -- ロケーション移動減
           ,0                                  -- 在庫調整増
           ,0                                  -- 在庫調整減
           ,l_pre_sum_rec.book_inv_qty         -- 帳簿在庫数
           ,cn_created_by                      -- 作成者
           ,cd_creation_date                   -- 作成日
           ,cn_last_updated_by                 -- 最終更新者
           ,cd_last_update_date                -- 最終更新日
           ,cn_last_update_login               -- 最終更新ログイン
           ,cn_request_id                      -- 要求ID
           ,cn_program_application_id          -- アプリケーションID
           ,cn_program_id                      -- プログラムID
           ,cd_program_update_date             -- プログラム更新日
          );
--
-- 2015/04/07 E_本稼動_12237 V1.1 ADD START
        -- 年月＝業務日付月の当月データが存在する場合は更新
        ELSE
          UPDATE xxcoi_lot_reception_sum -- ロット別受払(累計)
          SET    month_begin_quantity     = l_pre_sum_rec.book_inv_qty     -- 月首在庫数
                ,book_inventory_quantity  = book_inventory_quantity
                                              + l_pre_sum_rec.book_inv_qty -- 帳簿在庫数
                ,last_updated_by          = cn_last_updated_by             -- 最終更新者
                ,last_update_date         = cd_last_update_date            -- 最終更新日
                ,last_update_login        = cn_last_update_login           -- 最終更新ログイン
                ,request_id               = cn_request_id                  -- 要求ID
                ,program_application_id   = cn_program_application_id      -- アプリケーションID
                ,program_id               = cn_program_id                  -- プログラムID
                ,program_update_date      = cd_program_update_date         -- プログラム更新日
          WHERE  practice_month           = TO_CHAR( gd_proc_date, cv_yyyymm ) -- 年月
          AND    base_code                = l_pre_sum_rec.base_code            -- 拠点コード
          AND    subinventory_code        = l_pre_sum_rec.subinv_code          -- 保管場所コード
          AND    location_code            = l_pre_sum_rec.location_code        -- ロケーションコード
          AND    parent_item_id           = l_pre_sum_rec.parent_item_id       -- 親品目ID
          AND    child_item_id            = l_pre_sum_rec.child_item_id        -- 子品目ID
          AND    lot                      = l_pre_sum_rec.lot                  -- ロット
          AND    difference_summary_code  = l_pre_sum_rec.diff_sum_code        -- 固有記号
          ;
        END IF;
-- 2015/04/07 E_本稼動_12237 V1.1 ADD END
        -- 成功件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP pre_sum_loop;
--
      -- 累計繰越データ作成用カーソルクローズ
      CLOSE pre_sum_cur;
--
-- 2015/04/20 E_本稼動_12237 V1.2 ADD START
      END IF;
-- 2015/04/20 E_本稼動_12237 V1.2 ADD END
    END IF;
--
-- 2015/04/07 E_本稼動_12237 V1.1 DEL START
--    END IF;
-- 2015/04/07 E_本稼動_12237 V1.1 DEL END
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
      -- カーソルクローズ
      IF ( pre_date_cur%ISOPEN ) THEN
        CLOSE pre_date_cur;
      END IF;
--
      IF ( pre_sum_cur%ISOPEN ) THEN
        CLOSE pre_sum_cur;
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
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- 変数初期化
    --==============================================================
    -- 入力パラメータ名称
    lt_startup_flg_name := NULL;      -- 起動フラグ名
    -- 初期処理取得値
    gt_org_code         := NULL;      -- 在庫組織コード
    gt_org_id           := NULL;      -- 在庫組織ID
    gd_proc_date        := NULL;      -- 業務日付
    gt_pgm_name         := NULL;      -- データ連携制御テーブルプログラム名
    gt_pre_exe_id       := NULL;      -- 前回取引ID
    gt_pre_exe_date     := NULL;      -- 前回処理日
    gv_no_data_flag     := cv_flag_n; -- 対象0件フラグ
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
    -- 起動区分のチェック
    -- 未取得の場合は、パラメータ出力後にハンドリング
    lt_startup_flg_name := xxcoi_common_pkg.get_meaning(
                             iv_lookup_type => ct_xxcoi1_lot_rep_daily_type -- 参照タイプ名
                            ,iv_lookup_code => gv_startup_flg               -- 参照タイプコード
                           );
--
    --==============================================================
    -- 入力パラメータメッセージ出力
    --==============================================================
    -- メッセージ取得
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application        => cv_xxcoi_short_name
                  ,iv_name               => cv_msg_xxcoi1_10596
                  ,iv_token_name1        => cv_tkn_startup_flg      -- 起動区分
                  ,iv_token_value1       => gv_startup_flg
                  ,iv_token_name2        => cv_tkn_startup_flg_name -- 起動区分名
                  ,iv_token_value2       => lt_startup_flg_name
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
                    ,iv_name               => cv_msg_xxcoi1_10599
                    ,iv_token_name1        => cv_tkn_startup_flg
                    ,iv_token_value1       => gv_startup_flg
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 前回取引ID、前回処理日取得
    --==============================================================
    -- データ連携制御テーブルプログラム名セット
    -- 日次実行
    IF ( gv_startup_flg = cv_startup_flg_1 ) THEN
      gt_pgm_name := ct_pgm_name1;
    -- 累計実行
    ELSE
      gt_pgm_name := ct_pgm_name2;
    END IF;
--
    -- 前回取引ID、前回処理日取得
    BEGIN
      SELECT xcc.transaction_id        transaction_id        -- 前回取引ID
            ,xcc.last_cooperation_date last_cooperation_date -- 前回処理日
      INTO   gt_pre_exe_id
            ,gt_pre_exe_date
      FROM   xxcoi_cooperation_control xcc
      WHERE  xcc.program_short_name = gt_pgm_name -- プログラム名
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application        => cv_xxcoi_short_name
                      ,iv_name               => cv_msg_xxcoi1_10456
                      ,iv_token_name1        => cv_tkn_program_name -- プログラム名
                      ,iv_token_value1       => gt_pgm_name
                     );
      RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 最小取引ID、最大取引ID取得
    --==============================================================
    SELECT MIN(xlt.transaction_id) min_trx_id     -- 最小取引ID
          ,MAX(xlt.transaction_id) max_trx_id     -- 最大取引ID
    INTO   gt_min_trx_id
          ,gt_max_trx_id
    FROM   xxcoi_lot_transactions xlt
    WHERE  xlt.transaction_id > gt_pre_exe_id     -- 前回処理済ID
    ;
--
    -- NULLの場合は、対象0件フラグを'Y'にする
    IF ( gt_max_trx_id IS NULL ) THEN
      gv_no_data_flag := cv_flag_y;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           
   ,ov_retcode OUT VARCHAR2 -- リターン・コード             
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ 
  )IS
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
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    proc_init(
      ov_errbuf  => lv_errbuf  -- エラー・メッセージ           
     ,ov_retcode => lv_retcode -- リターン・コード             
     ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
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
    IF ( gv_no_data_flag = cv_flag_n ) THEN
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
    END IF;
--
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
    errbuf         OUT VARCHAR2 -- エラー・メッセージ  --# 固定 #
   ,retcode        OUT VARCHAR2 -- リターン・コード    --# 固定 #
   ,iv_startup_flg IN  VARCHAR2 -- 起動区分
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
    gv_startup_flg := iv_startup_flg;
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
    IF ( gv_no_data_flag = cv_flag_y ) THEN
      -- 対象0件メッセージ出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10597
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    ELSE
      -- 対象取引IDメッセージ出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10598
                      ,iv_token_name1  => cv_tkn_min_trx_id      -- 最小取引ID
                      ,iv_token_value1 => TO_CHAR(gt_min_trx_id)
                      ,iv_token_name2  => cv_tkn_max_trx_id      -- 最大取引ID
                      ,iv_token_value2 => TO_CHAR(gt_max_trx_id)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
--
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
END XXCOI016A09C;
/
