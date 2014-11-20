CREATE OR REPLACE PACKAGE BODY XXCOI008A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A03C(body)
 * Description      : 情報系システムへの連携の為、EBSの月次在庫受払表(アドオン)をCSVファイルに出力
 * MD.050           : 月別受払残高情報系連携 <MD050_COI_008_A03>
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  create_csv_p           累計情報なし棚卸データCSV作成(A-9)
 *  create_csv_p           受払(在庫)CSVの作成(A-6)
 *  get_inv_info_p         棚卸情報取得(A-5)
 *  recept_month_cur_p     月次在庫受払表(累計)情報の抽出(A-4)
 *  get_open_period_p      オープン在庫会計期間取得(A-3)
 *  submain                メイン処理プロシージャ
 *                           ・ファイルのオープン処理(A-2)
 *                           ・ファイルのクローズ処理(A-7) 
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           ・件数表示処理(A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/07    1.0   S.Kanda          新規作成
 *  2009/04/08    1.1   T.Nakamura       [障害 T1_0197] 月次在庫受払表（累計）データを基に
 *                                                      受払残高情報を取得するよう変更
 *  2010/01/06    1.2   N.Abe            [E_本稼動_00630] 基準在庫変更の算出を変更
 *                                                        棚卸情報の送信を追加
 *  2010/02/03    1.3   H.Sasaki         [E_本稼動_01424] 数量項目が全て０のレコードは
 *                                                        連携しないよう修正
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI008A03C';
  cv_appl_short_name_ccp    CONSTANT VARCHAR2(10)  := 'XXCCP';         -- アドオン：共通・IF領域
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCOI';         -- アドオン：共通・IF領域
  cv_file_slash             CONSTANT VARCHAR2(2)   := '/';             -- ファイル区切り用
  cv_file_encloser          CONSTANT VARCHAR2(2)   := '"';             -- 文字データ括り用
  cv_inv_kbn_2              CONSTANT VARCHAR2(2)   := '2';             -- 棚卸区分(月末)
  cv_yes                    CONSTANT VARCHAR2(2)   := 'Y';             -- フラグ用変数
-- == 2009/04/08 V1.1 Added START ===============================================================
  cv_process_type_0         CONSTANT VARCHAR2(2)   := '0';             -- 処理区分(日次)
  cv_process_type_1         CONSTANT VARCHAR2(2)   := '1';             -- 処理区分(月次)
  cv_fmt_date               CONSTANT VARCHAR2(6)   := 'YYYYMM';        -- 日付型フォーマット
  cv_fmt_date_hyp           CONSTANT VARCHAR2(7)   := 'YYYY-MM';       -- 日付型フォーマット(ハイフン)
-- == 2009/04/08 V1.1 Added START ===============================================================
  --
  -- メッセージ定数
  cv_msg_xxcoi_00003        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00003';
  cv_msg_xxcoi_00004        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00004';
  cv_msg_xxcoi_00005        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';
  cv_msg_xxcoi_00006        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';
  cv_msg_xxcoi_00007        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00007';
  cv_msg_xxcoi_00008        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00008';
  cv_msg_xxcoi_00023        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00023';
  cv_msg_xxcoi_00027        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00027';
  cv_msg_xxcoi_00028        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';
  cv_msg_xxcoi_00029        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';
-- == 2009/04/08 V1.1 Added START ===============================================================
  cv_msg_xxcoi_10374        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10374';
  cv_msg_xxcoi_10375        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10375';
  cv_msg_xxcoi_00011        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';
  cv_msg_xxcoi_10376        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10376';
  cv_msg_xxcoi_10377        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10377';
-- == 2009/04/08 V1.1 Added END   ===============================================================
  --
  --トークン
  cv_tkn_pro                CONSTANT VARCHAR2(10)  := 'PRO_TOK';       -- プロファイル名用
  cv_tkn_dir                CONSTANT VARCHAR2(10)  := 'DIR_TOK';       -- プロファイル名用
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';         -- 件数メッセージ用
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';     -- ファイル名用
  cv_tkn_org_code           CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';  -- 在庫組織コード用
-- == 2009/04/08 V1.1 Added START ===============================================================
  cv_tkn_process_type       CONSTANT VARCHAR2(15)  := 'PROCESS_TYPE';  -- 処理区分用
  cv_tkn_month              CONSTANT VARCHAR2(15)  := 'MONTH';         -- 年月用
  cv_tkn_base_code          CONSTANT VARCHAR2(15)  := 'BASE_CODE';     -- 拠点コード用
  cv_tkn_subinventory       CONSTANT VARCHAR2(15)  := 'SUBINVENTORY';  -- 保管場所コード用
  cv_tkn_item_code          CONSTANT VARCHAR2(15)  := 'ITEM_CODE';     -- 品目コード用
-- == 2009/04/08 V1.1 Added END   ===============================================================
  --
  --ファイルオープンモード
  cv_file_mode              CONSTANT VARCHAR2(2)   := 'W';             -- オープンモード
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;                                  -- 業務処理日付取得用
  gv_dire_pass          VARCHAR2(100);                         -- ディレクトリパス名用
  gv_file_recept_month  VARCHAR2(50);                          -- 月別受払残高ファイル名用
  gv_organization_code  VARCHAR2(50);                          -- 在庫組織コード取得用
  gn_organization_id    mtl_parameters.organization_id%TYPE;   -- 在庫組織ID取得用
  gv_company_code       VARCHAR2(50);                          -- 会社コード取得用
  gv_file_name          VARCHAR2(150);                         -- ファイルパス名取得用
  gv_activ_file_h       UTL_FILE.FILE_TYPE;                    -- ファイルハンドル取得用
-- == 2009/04/08 V1.1 Added START ===============================================================
  gv_process_type          VARCHAR2(1);                        -- 処理区分
  gd_sysdate               DATE;                               -- システム日付
  gn_open_period_cnt       NUMBER;                             -- 在庫会計期間取得件数
  gn_month_begin_quantity  NUMBER;                             -- 月首棚卸高
  gn_inv_result            NUMBER;                             -- 棚卸結果
  gn_inv_result_bad        NUMBER;                             -- 棚卸結果(不良品)
  gn_inv_wear              NUMBER;                             -- 棚卸減耗
-- == 2009/04/08 V1.1 Added END   ===============================================================
--
  -- ==============================
  -- ユーザー定義カーソル
  -- ==============================
-- == 2009/04/08 V1.1 Added START ===============================================================
  -- オープン在庫会計期間取得カーソル
  CURSOR get_open_period_cur
  IS
    SELECT   TO_CHAR( oap.period_start_date, cv_fmt_date ) AS year_month
    FROM     org_acct_periods       oap
    WHERE    oap.organization_id  = gn_organization_id
    AND      oap.open_flag        = cv_yes
    AND      oap.period_name     <= TO_CHAR( gd_process_date, cv_fmt_date_hyp )
    ORDER BY year_month
  ;
  TYPE get_open_period_ttype IS TABLE OF get_open_period_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  get_open_period_tab        get_open_period_ttype;
-- == 2009/04/08 V1.1 Added END   ===============================================================
-- == 2009/04/08 V1.1 Moded START ===============================================================
--  -- 月別受払残高情報取得
--  CURSOR recept_month_cur
--  IS
--    SELECT xirm.practice_month          -- 年月
--         , xirm.base_code               -- 拠点コード
--         , xirm.subinventory_code       -- 保管場所
--         , xirm.subinventory_type       -- 保管場所区分
--         , xirm.operation_cost          -- 営業原価
--         , xirm.standard_cost           -- 標準原価
--         , xirm.month_begin_quantity    -- 月首棚卸高
--         , xirm.factory_stock           -- 工場入庫
--         , xirm.factory_stock_b         -- 工場入庫振戻
--         , xirm.change_stock            -- 倉替入庫
--         , xirm.warehouse_stock         -- 倉庫からの入庫
--         , xirm.truck_stock             -- 営業車からの入庫
--         , xirm.others_stock            -- 入出庫＿その他入庫
--         , xirm.goods_transfer_new      -- 商品振替(新商品)
--         , xirm.sales_shipped           -- 売上出庫
--         , xirm.sales_shipped_b         -- 売上出庫振戻
--         , xirm.return_goods            -- 返品
--         , xirm.return_goods_b          -- 返品振戻
--         , xirm.change_ship             -- 倉替出庫
--         , xirm.warehouse_ship          -- 倉庫へ出庫
--         , xirm.truck_ship              -- 営業車へ出庫
--         , xirm.others_ship             -- 入出庫＿その他出庫
--         , xirm.inventory_change_in     -- 基準在庫変更入庫
--         , xirm.inventory_change_out    -- 基準在庫変更出庫
--         , xirm.factory_return          -- 工場返品
--         , xirm.factory_return_b        -- 工場返品振戻
--         , xirm.factory_change          -- 工場倉替
--         , xirm.factory_change_b        -- 工場倉替振戻
--         , xirm.removed_goods           -- 廃却
--         , xirm.removed_goods_b         -- 廃却振戻
--         , xirm.goods_transfer_old      -- 商品振替(旧商品)
--         , xirm.sample_quantity         -- 見本出庫
--         , xirm.sample_quantity_b       -- 見本出庫振戻
--         , xirm.customer_sample_ship    -- 顧客見本出庫
--         , xirm.customer_sample_ship_b  -- 顧客見本出庫振戻
--         , xirm.customer_support_ss     -- 顧客協賛見本出庫
--         , xirm.customer_support_ss_b   -- 顧客協賛見本出庫振戻
--         , xirm.ccm_sample_ship         -- 顧客広告宣伝費A自社商品
--         , xirm.ccm_sample_ship_b       -- 顧客広告宣伝費A自社商品振戻
--         , xirm.inv_result              -- 棚卸結果
--         , xirm.inv_result_bad          -- 棚卸結果(不良品)
--         , xirm.inv_wear                -- 棚卸減耗
--         , xirm.last_update_date        -- 最終更新日
--         , msib.segment1                -- 品目コード
--    FROM   xxcoi_inv_reception_monthly  xirm  -- 月次在庫受払表テーブル
--         , mtl_system_items_b           msib  -- 品目マスタ
--         , org_acct_periods             oap   -- 在庫会計期間
--    WHERE  xirm.inventory_kbn       = cv_inv_kbn_2            -- 棚卸区分(月末)
--    AND    msib.inventory_item_id   = xirm.inventory_item_id  -- 品目ID
--    AND    msib.organization_id     = gn_organization_id      -- A-1.で取得した在庫組織ID
--    AND    oap.organization_id      = msib.organization_id    -- 組織ID
--    AND    xirm.practice_date                           -- 月次在庫受払表テーブル.年月日
--      BETWEEN oap.period_start_date                     -- 会計期間開始日
--      AND     oap.schedule_close_date                   -- クローズ予定日
--    AND    oap.open_flag            = cv_yes;           -- オープンフラグ
--
--    --
--    -- recept_monthレコード型
--    recept_month_rec   recept_month_cur%ROWTYPE;
    -- 月次在庫受払表(累計)情報抽出カーソル
    CURSOR recept_month_cur(
             iv_practice_date              IN VARCHAR2
           )
    IS
      SELECT xirs.organization_id          AS organization_id           -- 組織ID
           , xirs.inventory_item_id        AS inventory_item_id         -- 品目ID
           , xirs.practice_date            AS practice_date             -- 年月
           , xirs.base_code                AS base_code                 -- 拠点コード
           , xirs.subinventory_code        AS subinventory_code         -- 保管場所
           , xirs.subinventory_type        AS subinventory_type         -- 保管場所区分
           , xirs.operation_cost           AS operation_cost            -- 営業原価
           , xirs.standard_cost            AS standard_cost             -- 標準原価
           , xirs.factory_stock            AS factory_stock             -- 工場入庫
           , xirs.factory_stock_b          AS factory_stock_b           -- 工場入庫振戻
           , xirs.change_stock             AS change_stock              -- 倉替入庫
           , xirs.warehouse_stock          AS warehouse_stock           -- 倉庫より入庫
           , xirs.truck_stock              AS truck_stock               -- 営業車より入庫
           , xirs.others_stock             AS others_stock              -- 入出庫＿その他入庫
           , xirs.goods_transfer_new       AS goods_transfer_new        -- 商品振替(新商品)
           , xirs.sales_shipped            AS sales_shipped             -- 売上出庫
           , xirs.sales_shipped_b          AS sales_shipped_b           -- 売上出庫振戻
           , xirs.return_goods             AS return_goods              -- 返品
           , xirs.return_goods_b           AS return_goods_b            -- 返品振戻
           , xirs.change_ship              AS change_ship               -- 倉替出庫
           , xirs.warehouse_ship           AS warehouse_ship            -- 倉庫へ返庫
           , xirs.truck_ship               AS truck_ship                -- 営業車へ出庫
           , xirs.others_ship              AS others_ship               -- 入出庫＿その他出庫
           , xirs.inventory_change_in      AS inventory_change_in       -- 基準在庫変更入庫
           , xirs.inventory_change_out     AS inventory_change_out      -- 基準在庫変更出庫
           , xirs.factory_return           AS factory_return            -- 工場返品
           , xirs.factory_return_b         AS factory_return_b          -- 工場返品振戻
           , xirs.factory_change           AS factory_change            -- 工場倉替
           , xirs.factory_change_b         AS factory_change_b          -- 工場倉替振戻
           , xirs.removed_goods            AS removed_goods             -- 廃却
           , xirs.removed_goods_b          AS removed_goods_b           -- 廃却振戻
           , xirs.goods_transfer_old       AS goods_transfer_old        -- 商品振替(旧商品)
           , xirs.sample_quantity          AS sample_quantity           -- 見本出庫
           , xirs.sample_quantity_b        AS sample_quantity_b         -- 見本出庫振戻
           , xirs.customer_sample_ship     AS customer_sample_ship      -- 顧客見本出庫
           , xirs.customer_sample_ship_b   AS customer_sample_ship_b    -- 顧客見本出庫振戻
           , xirs.customer_support_ss      AS customer_support_ss       -- 顧客協賛見本出庫
           , xirs.customer_support_ss_b    AS customer_support_ss_b     -- 顧客協賛見本出庫振戻
           , xirs.ccm_sample_ship          AS ccm_sample_ship           -- 顧客広告宣伝費A自社商品
           , xirs.ccm_sample_ship_b        AS ccm_sample_ship_b         -- 顧客広告宣伝費A自社商品振戻
           , xirs.book_inventory_quantity  AS book_inventory_quantity   -- 帳簿在庫数
           , xirs.last_update_date         AS last_update_date          -- 最終更新日
           , msib.segment1                 AS segment1                  -- 品目コード
      FROM   xxcoi_inv_reception_sum       xirs                         -- 月次在庫受払表(累計)テーブル
           , mtl_system_items_b            msib                         -- 品目マスタ
      WHERE  xirs.practice_date            =  iv_practice_date          -- 年月
      AND    msib.inventory_item_id        =  xirs.inventory_item_id    -- 品目ID
      AND    msib.organization_id          =  gn_organization_id        -- A-1.で取得した在庫組織ID
      ;
      recept_month_rec   recept_month_cur%ROWTYPE;
-- == 2009/04/08 V1.1 Moded END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    --プロファイル取得用定数
    cv_pro_dire_out_info      CONSTANT VARCHAR2(30)  := 'XXCOI1_DIRE_OUT_INFO';
    cv_pro_file_recept_month  CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_RECEPT_MONTH';
    cv_pro_org_code           CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';
    cv_pro_company_code       CONSTANT VARCHAR2(30)  := 'XXCOI1_COMPANY_CODE';
--
    -- *** ローカル変数 ***
    lv_directory_path       VARCHAR2(100);     -- ディレクトリパス取得用
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
    -- ===============================
    --  初期化処理
    -- ===============================
    gd_process_date       :=  NULL;          -- 業務日付
    gv_dire_pass          :=  NULL;          -- ディレクトリパス名
    gv_file_recept_month  :=  NULL;          -- 月別受払残高ファイル名
    gv_organization_code  :=  NULL;          -- 在庫組織コード名
    gn_organization_id    :=  NULL;          -- 在庫組織ID名
    gv_company_code       :=  NULL;          -- 会社コード名
    gv_file_name          :=  NULL;          -- ファイルパス名
    lv_directory_path     :=  NULL;          -- ディレクトリフルパス
-- == 2009/04/08 V1.1 Added START ===============================================================
    gd_sysdate              := NULL;         -- システム日付
    gn_open_period_cnt      := 0;            -- 在庫会計期間取得件数
    gn_month_begin_quantity := NULL;         -- 月首棚卸高
    gn_inv_result           := NULL;         -- 棚卸結果
    gn_inv_result_bad       := NULL;         -- 棚卸結果(不良品)
    gn_inv_wear             := NULL;         -- 棚卸減耗
-- == 2009/04/08 V1.1 Added END   ===============================================================
    --
    -- ===============================
    --  1.SYSDATE取得
    -- ===============================
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    gd_process_date   :=  sysdate;
    gd_sysdate   :=  SYSDATE;
-- == 2009/04/08 V1.1 Moded END   ===============================================================
    --
    -- ====================================================
    -- 2.情報系_OUTBOUND格納ディレクトリ名情報を取得
    -- ====================================================
    gv_dire_pass      := fnd_profile.value( cv_pro_dire_out_info );
--
    -- ディレクトリ名情報が取得できなかった場合
    IF ( gv_dire_pass IS NULL ) THEN
      -- ディレクトリパス取得エラーメッセージ
      -- 「プロファイル:ディレクトリ名( PRO_TOK )の取得に失敗しました。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00003
                      , iv_token_name1  => cv_tkn_pro
                      , iv_token_value1 => cv_pro_dire_out_info
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- 3.月別受払残高ファイル名を取得
    -- =======================================
    gv_file_recept_month   := fnd_profile.value( cv_pro_file_recept_month );
    --
    -- 月別受払残高ファイル名が取得できなかった場合
    IF ( gv_file_recept_month IS NULL ) THEN
      -- ファイル名取得エラーメッセージ
      -- 「プロファイル:ファイル名( PRO_TOK )の取得に失敗しました。」
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00004
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_file_recept_month
                      );
      lv_errbuf    := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 4.在庫組織コードを取得
    -- =====================================
    gv_organization_code := fnd_profile.value( cv_pro_org_code );
    --
    -- 在庫組織コードが取得できなかった場合
    IF  ( gv_organization_code  IS NULL ) THEN
      -- 在庫組織コード取得エラーメッセージ
      -- 「プロファイル:在庫組織コード( PRO_TOK )の取得に失敗しました。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00005
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_org_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 在庫組織ID取得
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id( gv_organization_code );
    --
    -- 共通関数のリターンコードが取得できなかった場合
    IF ( gn_organization_id IS NULL ) THEN
      -- 在庫組織ID取得エラーメッセージ
      -- 「在庫組織コード( ORG_CODE_TOK )に対する在庫組織IDの取得に失敗しました。」
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00006
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      --
      RAISE global_api_expt;
    END IF;
    --
    -- =====================================
    -- 5.会社コードを取得
    -- =====================================
    gv_company_code  := fnd_profile.value( cv_pro_company_code );
    --
    -- 会社コードが取得できなかった場合
    IF  ( gv_company_code  IS NULL ) THEN
      -- 会社コード取得エラーメッセージ
      -- 「プロファイル:会社コード( PRO_TOK )の取得に失敗しました。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00007
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_company_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 6.メッセージの出力①
    -- =====================================
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    -- コンカレント入力パラメータなしメッセージを出力
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name
--                     , iv_name         => cv_msg_xxcoi_00023
--                    );
    -- 入力パラメータ.処理区分の内容を出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_10374
                     , iv_token_name1  => cv_tkn_process_type
                     , iv_token_value1 => gv_process_type
                    );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
    --
    -- 入力パラメータ.処理区分がNULLの場合
    IF ( gv_process_type IS NULL ) THEN
      -- 入力パラメータ未設定エラー（処理区分）
      -- 「入力パラメータ：処理区分が未設定です。」
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_10375
                      );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/04/08 V1.1 Moded END   ===============================================================
    -- =====================================
    -- 7.メッセージの出力②
    -- =====================================
    --
    -- 2.で取得したプロファイル値よりディレクトリパスを取得
    BEGIN
      SELECT directory_path
      INTO   lv_directory_path
      FROM   all_directories     -- ディレクトリ情報
      WHERE  directory_name = gv_dire_pass;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ディレクトリフルパス取得エラーメッセージ
        -- 「このディレクトリ名ではディレクトリパスは取得できません。
        -- （ディレクトリ名 = DIR_TOK ）」
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00029
                        , iv_token_name1  => cv_tkn_dir
                        , iv_token_value1 => gv_dire_pass
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
    -- IFファイル名（IFファイルのフルパス情報）を出力
    -- 'ディレクトリパス'と'/'と‘ファイル名'を結合
    gv_file_name  := lv_directory_path || cv_file_slash || gv_file_recept_month;
    --「ファイル： FILE_NAME 」
    --ファイル名出力メッセージ
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00028
                     , iv_token_name1  => cv_tkn_file_name
                     , iv_token_value1 => gv_file_name
                    );
    --
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
      );
-- == 2009/04/08 V1.1 Added START ===============================================================
    -- ===================================
    --  9.業務処理日付取得
    -- ===================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_process_date IS NULL) THEN
      -- 業務日付の取得に失敗しました。
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                      , iv_name          => cv_msg_xxcoi_00011
                     );
      lv_errbuf   := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/04/08 V1.1 Added END   ===============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
-- == 2010/01/06 V1.2 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : create_csv_i
   * Description      : 累計情報なし棚卸データCSV作成(A-9)
   ***********************************************************************************/
  PROCEDURE create_csv_i(
     iv_year_month IN  VARCHAR2     --   年月
   , ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   , ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   , ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_i'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode VARCHAR2(1);      -- リターン・コード
    lv_errmsg  VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_csv_com       CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ローカル変数 ***
    lv_recept_month     VARCHAR2(3000);  -- CSV出力用変数
    lv_process_date     VARCHAR2(14);    -- システム日付 格納用変数
    lv_last_update_date VARCHAR2(14);    -- 最終更新日 格納用変数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 受払全項目０で、棚卸のみ行われており、累計テーブルにデータが存在しない。
    -- 又は、受払全項目０で、月首在庫のみ存在し、累計テーブルにデータが存在しない。
    -- 累計情報なしデータ抽出
    CURSOR  get_no_sumdata_cur(
             iv_year_month              IN VARCHAR2
           )
    IS
      SELECT  xirm.base_code                                          -- 拠点コード
            , xirm.practice_month                                     -- 年月
            , xirm.subinventory_code                                  -- 保管場所
            , xirm.subinventory_type                                  -- 保管場所区分
            , msib.segment1                                           -- 品目コード
            , xirm.operation_cost                                     -- 営業原価
            , xirm.standard_cost                                      -- 標準原価
            , xirm.month_begin_quantity                               -- 月首棚卸高
            , xirm.inv_result                                         -- 棚卸結果
            , xirm.inv_result_bad                                     -- 棚卸結果(不良品)
            , xirm.inv_wear                                           -- 棚卸減耗 
            , xirm.last_update_date                                   -- 最終更新日
      FROM    xxcoi_inv_reception_monthly     xirm                    -- 月次在庫受払表
             ,mtl_system_items_b              msib                    -- Disc品目マスタ
      WHERE   xirm.practice_month         =   iv_year_month           -- 年月
      AND     xirm.inventory_kbn          =   cv_inv_kbn_2            -- 棚卸区分
      AND     xirm.organization_id        =   gn_organization_id      -- 組織ID
      AND     (xirm.inv_result            <>  0                       -- 棚卸結果
         OR    xirm.inv_result_bad        <>  0                       -- 棚卸結果(不良品)
         OR    xirm.month_begin_quantity  <>  0)                      -- 月首棚卸高
      AND     xirm.sales_shipped          =   0                       -- 売上出庫
      AND     xirm.sales_shipped_b        =   0                       -- 売上出庫振戻
      AND     xirm.return_goods           =   0                       -- 返品
      AND     xirm.return_goods_b         =   0                       -- 返品振戻
      AND     xirm.warehouse_ship         =   0                       -- 倉庫へ返庫
      AND     xirm.truck_ship             =   0                       -- 営業車へ出庫
      AND     xirm.others_ship            =   0                       -- 入出庫＿その他出庫
      AND     xirm.warehouse_stock        =   0                       -- 倉庫より入庫
      AND     xirm.truck_stock            =   0                       -- 営業車より入庫
      AND     xirm.others_stock           =   0                       -- 入出庫＿その他入庫
      AND     xirm.change_stock           =   0                       -- 倉替入庫
      AND     xirm.change_ship            =   0                       -- 倉替出庫
      AND     xirm.goods_transfer_old     =   0                       -- 商品振替（旧商品）
      AND     xirm.goods_transfer_new     =   0                       -- 商品振替（新商品）
      AND     xirm.sample_quantity        =   0                       -- 見本出庫
      AND     xirm.sample_quantity_b      =   0                       -- 見本出庫振戻
      AND     xirm.customer_sample_ship   =   0                       -- 顧客見本出庫
      AND     xirm.customer_sample_ship_b =   0                       -- 顧客見本出庫振戻
      AND     xirm.customer_support_ss    =   0                       -- 顧客協賛見本出庫
      AND     xirm.customer_support_ss_b  =   0                       -- 顧客協賛見本出庫振戻
      AND     xirm.ccm_sample_ship        =   0                       -- 顧客広告宣伝費A自社商品
      AND     xirm.ccm_sample_ship_b      =   0                       -- 顧客広告宣伝費A自社商品振戻
      AND     xirm.vd_supplement_stock    =   0                       -- 消化VD補充入庫
      AND     xirm.vd_supplement_ship     =   0                       -- 消化VD補充出庫
      AND     xirm.inventory_change_in    =   0                       -- 基準在庫変更入庫
      AND     xirm.inventory_change_out   =   0                       -- 基準在庫変更出庫
      AND     xirm.factory_return         =   0                       -- 工場返品
      AND     xirm.factory_return_b       =   0                       -- 工場返品振戻
      AND     xirm.factory_change         =   0                       -- 工場倉替
      AND     xirm.factory_change_b       =   0                       -- 工場倉替振戻
      AND     xirm.removed_goods          =   0                       -- 廃却
      AND     xirm.removed_goods_b        =   0                       -- 廃却振戻
      AND     xirm.factory_stock          =   0                       -- 工場入庫
      AND     xirm.factory_stock_b        =   0                       -- 工場入庫振戻
      AND     xirm.wear_decrease          =   0                       -- 棚卸減耗増
      AND     xirm.wear_increase          =   0                       -- 棚卸減耗減
      AND     xirm.selfbase_ship          =   0                       -- 保管場所移動＿自拠点出庫
      AND     xirm.selfbase_stock         =   0                       -- 保管場所移動＿自拠点入庫
      AND     xirm.inventory_item_id      =   msib.inventory_item_id  -- 品目ID
      AND     msib.organization_id        =   gn_organization_id      -- 組織ID
      AND NOT EXISTS (SELECT 1
                      FROM  xxcoi_inv_reception_sum xirs                      -- 月次在庫受払表(累計)
                      WHERE xirs.practice_date      = iv_year_month           -- 年月
                      AND   xirs.base_code          = xirm.base_code          -- 拠点コード
                      AND   xirs.subinventory_code  = xirm.subinventory_code  -- 保管場所
                      AND   xirs.inventory_item_id  = xirm.inventory_item_id  -- 品目ID
                     )
      ;
      get_no_sumdata_rec   get_no_sumdata_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数の初期化
    lv_recept_month     := NULL;
    lv_process_date     := NULL;
    lv_last_update_date := NULL;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    --累計テーブル未存在データ取得カーソルオープン
    OPEN get_no_sumdata_cur( 
           iv_year_month => iv_year_month
         );
      --
      <<no_sumdata_loop>>
      LOOP
        FETCH get_no_sumdata_cur INTO get_no_sumdata_rec;
        --次データがなくなったら終了
        EXIT WHEN get_no_sumdata_cur%NOTFOUND;
        --対象件数加算
        gn_target_cnt := gn_target_cnt + 1;
--
        lv_process_date     := TO_CHAR(gd_sysdate , 'YYYYMMDDHH24MISS' );                          -- 連携日時
        lv_last_update_date := TO_CHAR(get_no_sumdata_rec.last_update_date , 'YYYYMMDDHH24MISS');  -- 最終更新日
--
        -- =================================
        -- CSVファイル作成
        -- =================================
        --
        -- カーソルで取得した値をCSVファイルに格納します
        lv_recept_month := 
          cv_file_encloser || gv_company_code                       || cv_file_encloser || cv_csv_com || -- 1.会社コード
                              get_no_sumdata_rec.practice_month                         || cv_csv_com || -- 2.年月
          cv_file_encloser || get_no_sumdata_rec.base_code          || cv_file_encloser || cv_csv_com || -- 3.拠点（部門）コード
          cv_file_encloser || get_no_sumdata_rec.subinventory_code  || cv_file_encloser || cv_csv_com || -- 4.保管場所コード
          cv_file_encloser || get_no_sumdata_rec.segment1           || cv_file_encloser || cv_csv_com || -- 5.商品コード
          cv_file_encloser || get_no_sumdata_rec.subinventory_type  || cv_file_encloser || cv_csv_com || -- 6.保管場所区分
                              get_no_sumdata_rec.operation_cost                         || cv_csv_com || -- 7.営業原価
                              get_no_sumdata_rec.standard_cost                          || cv_csv_com || -- 8.標準原価
                              get_no_sumdata_rec.month_begin_quantity                   || cv_csv_com || -- 9.月首棚卸高
                              0                                                         || cv_csv_com || -- 10.工場入庫
                              0                                                         || cv_csv_com || -- 11.倉替入庫
                              0                                                         || cv_csv_com || -- 12.拠点内入庫
                              0                                                         || cv_csv_com || -- 13.振替入庫
                              0                                                         || cv_csv_com || -- 14.売上出庫
                              0                                                         || cv_csv_com || -- 15.顧客返品
                              0                                                         || cv_csv_com || -- 16.倉替出庫
                              0                                                         || cv_csv_com || -- 17.拠点内出庫
                              0                                                         || cv_csv_com || -- 18.基準在庫変更
                              0                                                         || cv_csv_com || -- 19.工場返品
                              0                                                         || cv_csv_com || -- 20.工場倉替
                              0                                                         || cv_csv_com || -- 21.廃却出庫
                              0                                                         || cv_csv_com || -- 22.振替出庫
                              0                                                         || cv_csv_com || -- 23.協賛見本
                              get_no_sumdata_rec.inv_result                             || cv_csv_com || -- 24.棚卸結果
                              get_no_sumdata_rec.inv_result_bad                         || cv_csv_com || -- 25.棚卸結果(不良品)
                              get_no_sumdata_rec.inv_wear                               || cv_csv_com || -- 26.棚卸減耗
                              lv_last_update_date                                       || cv_csv_com || -- 27.更新日時
                              lv_process_date;                                                           -- 28.連携日時
    --
        UTL_FILE.PUT_LINE(
            gv_activ_file_h     -- A-3.で取得したファイルハンドル
          , lv_recept_month     -- デリミタ＋上記CSV出力項目
          );
  --
        -- 正常件数に加算
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      --ループの終了
      END LOOP no_sumdata_loop;
      --
    --カーソルのクローズ
    CLOSE get_no_sumdata_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF get_no_sumdata_cur%ISOPEN THEN
        CLOSE get_no_sumdata_cur;
      END IF;
      --
      -- エラーメッセージ
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがオープンしている場合はクローズする
      IF get_no_sumdata_cur%ISOPEN THEN
        CLOSE get_no_sumdata_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがオープンしている場合はクローズする
      IF get_no_sumdata_cur%ISOPEN THEN
        CLOSE get_no_sumdata_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがオープンしている場合はクローズする
      IF get_no_sumdata_cur%ISOPEN THEN
        CLOSE get_no_sumdata_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_i;
-- == 2010/01/06 V1.2 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : create_csv_p
   * Description      : 受払(在庫)CSVの作成(A-6)
   ***********************************************************************************/
  PROCEDURE create_csv_p(
     ir_recept_month_cur   IN  recept_month_cur%ROWTYPE -- コラムNO.
   , ov_errbuf             OUT VARCHAR2                 -- エラー・メッセージ           --# 固定 #
   , ov_retcode            OUT VARCHAR2                 -- リターン・コード             --# 固定 #
   , ov_errmsg             OUT VARCHAR2)                -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_p'; -- プログラム名
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
    cv_csv_com       CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ローカル変数 ***
    lv_recept_month     VARCHAR2(3000);  -- CSV出力用変数
    lv_process_date     VARCHAR2(14);    -- システム日付 格納用変数
    lv_last_update_date VARCHAR2(14);    -- 最終更新日 格納用変数
    -- カーソル取得値の編集用変数
    ln_factory_stock    NUMBER;          -- 工場入庫
    ln_sum_stock        NUMBER;          -- 拠点内入庫
    ln_sales_shipped    NUMBER;          -- 売上出庫
    ln_return_goods     NUMBER;          -- 顧客返品
    ln_sum_ship         NUMBER;          -- 拠点内出庫
    ln_sum_inv_change   NUMBER;          -- 基準在庫変更
    ln_factory_return   NUMBER;          -- 工場返品
    ln_factory_change   NUMBER;          -- 工場倉替
    ln_removed_goods    NUMBER;          -- 廃却出庫
    ln_sum_sample       NUMBER;          -- 協賛見本
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
    -- 変数の初期化
    lv_recept_month     := NULL;
    lv_process_date     := NULL;
    lv_last_update_date := NULL;
    -- カーソル取得値の編集用変数の初期化
    ln_factory_stock    := 0;
    ln_sum_stock        := 0;
    ln_sales_shipped    := 0;
    ln_return_goods     := 0;
    ln_sum_ship         := 0;
    ln_sum_inv_change   := 0;
    ln_factory_return   := 0;
    ln_factory_change   := 0;
    ln_removed_goods    := 0;
    ln_sum_sample       := 0;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    lv_process_date     := TO_CHAR( gd_process_date , 'YYYYMMDDHH24MISS' );                    -- 連携日時
    lv_process_date     := TO_CHAR( gd_sysdate , 'YYYYMMDDHH24MISS' );                         -- 連携日時
-- == 2009/04/08 V1.1 Moded START ===============================================================
    lv_last_update_date := TO_CHAR(ir_recept_month_cur.last_update_date , 'YYYYMMDDHH24MISS'); -- 最終更新日
--
    -- ============================================
    -- カーソルで取得した項目を編集
    -- ============================================
    -- 工場入庫  = カーソルで抽出した工場入庫 - 工場入庫振戻
    ln_factory_stock := NVL( ir_recept_month_cur.factory_stock , 0 ) - NVL( ir_recept_month_cur.factory_stock_b , 0 );
    --
    -- 拠点内入庫  = カーソルで抽出した倉庫からの入庫 + 営業車からの入庫 + 入出庫＿その他入庫
    ln_sum_stock := NVL( ir_recept_month_cur.warehouse_stock , 0 )
                       + NVL( ir_recept_month_cur.truck_stock , 0 ) + NVL( ir_recept_month_cur.others_stock , 0 );
    --
    -- 売上出庫  = カーソルで抽出した売上出庫 - 売上出庫振戻
    ln_sales_shipped := NVL( ir_recept_month_cur.sales_shipped , 0 ) - NVL( ir_recept_month_cur.sales_shipped_b , 0 );
    --
    -- 顧客返品  = カーソルで抽出した返品ー返品振戻
    ln_return_goods := NVL( ir_recept_month_cur.return_goods , 0 ) - NVL( ir_recept_month_cur.return_goods_b , 0 );
    --
    -- 拠点内出庫  = カーソルで抽出した倉庫へ出庫 + 営業車へ出庫 + 入出庫＿その他出庫
    ln_sum_ship := NVL( ir_recept_month_cur.warehouse_ship , 0 )
                     + NVL( ir_recept_month_cur.truck_ship , 0 ) + NVL( ir_recept_month_cur.others_ship , 0 );
    --
-- == 2010/01/06 V1.2 Modified START ===============================================================
--    -- 基準在庫変更  = カーソルで抽出した基準在庫変更入庫 + 基準在庫変更出庫
--    ln_sum_inv_change := NVL( ir_recept_month_cur.inventory_change_in , 0 )
--                           + NVL( ir_recept_month_cur.inventory_change_out , 0 );
    -- 基準在庫変更  = カーソルで抽出した基準在庫変更入庫 - 基準在庫変更出庫
    ln_sum_inv_change := NVL( ir_recept_month_cur.inventory_change_in , 0 )
                           - NVL( ir_recept_month_cur.inventory_change_out , 0 );
-- == 2010/01/06 V1.2 Modified END   ===============================================================
    --
    -- 工場返品   = で抽出した工場返品 - 工場返品振戻
    ln_factory_return := NVL( ir_recept_month_cur.factory_return , 0 )
                           - NVL( ir_recept_month_cur.factory_return_b , 0 );
    --
    -- 工場倉替  = カーソルで抽出した工場倉替 - 工場倉替振戻
    ln_factory_change := NVL( ir_recept_month_cur.factory_change , 0 )
                           - NVL( ir_recept_month_cur.factory_change_b , 0 );
    --
    -- 廃却出庫  = カーソルで抽出した廃却 - 廃却振戻
    ln_removed_goods  := NVL( ir_recept_month_cur.removed_goods , 0 ) - NVL( ir_recept_month_cur.removed_goods_b , 0 );
    --
    -- 協賛見本  = カーソルで抽出した(見本出庫 - 見本出庫振戻)
    --                             + (顧客見本出庫 - 顧客見本主庫振戻)
    --                             + (顧客協賛見本出庫 - 顧客協賛見本出庫振戻)
    --                             + (顧客広告宣伝費A自社商品 - 顧客広告宣伝費A自社商品振戻)
    ln_sum_sample := (NVL( ir_recept_month_cur.sample_quantity , 0 ) - NVL( ir_recept_month_cur.sample_quantity_b , 0 ))
                       + (NVL( ir_recept_month_cur.customer_sample_ship , 0 )
                         - NVL( ir_recept_month_cur.customer_sample_ship_b , 0 ))
                       + (NVL( ir_recept_month_cur.customer_support_ss , 0 )
                         - NVL( ir_recept_month_cur.customer_support_ss_b , 0 ))
                       + (NVL( ir_recept_month_cur.ccm_sample_ship , 0 )
                         - NVL( ir_recept_month_cur.ccm_sample_ship_b , 0 ));
--
    -- =================================
    -- CSVファイル作成
    -- =================================
    --
    -- カーソルで取得した値をCSVファイルに格納します
-- == 2010/02/03 V1.3 Modified START ===============================================================
--    lv_recept_month := 
--      cv_file_encloser || gv_company_code                       || cv_file_encloser || cv_csv_com || -- 1.会社コード
---- == 2009/04/08 V1.1 Moded START ===============================================================
----                          ir_recept_month_cur.practice_month                        || cv_csv_com || -- 2.年月
--                          ir_recept_month_cur.practice_date                         || cv_csv_com || -- 2.年月
---- == 2009/04/08 V1.1 Moded END   ===============================================================
--      cv_file_encloser || ir_recept_month_cur.base_code         || cv_file_encloser || cv_csv_com || -- 3.拠点（部門）コード
--      cv_file_encloser || ir_recept_month_cur.subinventory_code || cv_file_encloser || cv_csv_com || -- 4.保管場所コード
--      cv_file_encloser || ir_recept_month_cur.segment1          || cv_file_encloser || cv_csv_com || -- 5.商品コード
--      cv_file_encloser || ir_recept_month_cur.subinventory_type || cv_file_encloser || cv_csv_com || -- 6.保管場所区分
--                          ir_recept_month_cur.operation_cost                        || cv_csv_com || -- 7.営業原価
--                          ir_recept_month_cur.standard_cost                         || cv_csv_com || -- 8.標準原価
---- == 2009/04/08 V1.1 Moded START ===============================================================
----                          ir_recept_month_cur.month_begin_quantity                  || cv_csv_com || -- 9.月首棚卸高
--                          gn_month_begin_quantity                                   || cv_csv_com || -- 9.月首棚卸高
---- == 2009/04/08 V1.1 Moded END   ===============================================================
--                          ln_factory_stock                                          || cv_csv_com || -- 10.工場入庫
--                          ir_recept_month_cur.change_stock                          || cv_csv_com || -- 11.倉替入庫
--                          ln_sum_stock                                              || cv_csv_com || -- 12.拠点内入庫
--                          ir_recept_month_cur.goods_transfer_new                    || cv_csv_com || -- 13.振替入庫
--                          ln_sales_shipped                                          || cv_csv_com || -- 14.売上出庫
--                          ln_return_goods                                           || cv_csv_com || -- 15.顧客返品
--                          ir_recept_month_cur.change_ship                           || cv_csv_com || -- 16.倉替出庫
--                          ln_sum_ship                                               || cv_csv_com || -- 17.拠点内出庫
--                          ln_sum_inv_change                                         || cv_csv_com || -- 18.基準在庫変更
--                          ln_factory_return                                         || cv_csv_com || -- 19.工場返品
--                          ln_factory_change                                         || cv_csv_com || -- 20.工場倉替
--                          ln_removed_goods                                          || cv_csv_com || -- 21.廃却出庫
--                          ir_recept_month_cur.goods_transfer_old                    || cv_csv_com || -- 22.振替出庫
--                          ln_sum_sample                                             || cv_csv_com || -- 23.協賛見本
---- == 2009/04/08 V1.1 Moded START ===============================================================
----                          ir_recept_month_cur.inv_result                            || cv_csv_com || -- 24.棚卸結果
----                          ir_recept_month_cur.inv_result_bad                        || cv_csv_com || -- 25.棚卸結果(不良品)
----                          ir_recept_month_cur.inv_wear                              || cv_csv_com || -- 26.棚卸減耗
--                          gn_inv_result                                             || cv_csv_com || -- 24.棚卸結果
--                          gn_inv_result_bad                                         || cv_csv_com || -- 25.棚卸結果(不良品)
--                          gn_inv_wear                                               || cv_csv_com || -- 26.棚卸減耗
---- == 2009/04/08 V1.1 Moded END   ===============================================================
--                          lv_last_update_date                                       || cv_csv_com || -- 27.更新日時
--                          lv_process_date;                                                           -- 28.連携日時
----
--    UTL_FILE.PUT_LINE(
--        gv_activ_file_h     -- A-3.で取得したファイルハンドル
--      , lv_recept_month        -- デリミタ＋上記CSV出力項目
--      );
--
    -- 9.から26.の数量項目が全て０のレコードはCSV出力しない
    IF  NOT(
              (gn_month_begin_quantity                =  0)     --  9.月首棚卸高
          AND (ln_factory_stock                       =  0)     -- 10.工場入庫
          AND (ir_recept_month_cur.change_stock       =  0)     -- 11.倉替入庫
          AND (ln_sum_stock                           =  0)     -- 12.拠点内入庫
          AND (ir_recept_month_cur.goods_transfer_new =  0)     -- 13.振替入庫
          AND (ln_sales_shipped                       =  0)     -- 14.売上出庫
          AND (ln_return_goods                        =  0)     -- 15.顧客返品
          AND (ir_recept_month_cur.change_ship        =  0)     -- 16.倉替出庫
          AND (ln_sum_ship                            =  0)     -- 17.拠点内出庫
          AND (ln_sum_inv_change                      =  0)     -- 18.基準在庫変更
          AND (ln_factory_return                      =  0)     -- 19.工場返品
          AND (ln_factory_change                      =  0)     -- 20.工場倉替
          AND (ln_removed_goods                       =  0)     -- 21.廃却出庫
          AND (ir_recept_month_cur.goods_transfer_old =  0)     -- 22.振替出庫
          AND (ln_sum_sample                          =  0)     -- 23.協賛見本
          AND (gn_inv_result                          =  0)     -- 24.棚卸結果
          AND (gn_inv_result_bad                      =  0)     -- 25.棚卸結果(不良品)
          AND (gn_inv_wear                            =  0)     -- 26.棚卸減耗
        )
    THEN
      lv_recept_month := 
        cv_file_encloser || gv_company_code                       || cv_file_encloser || cv_csv_com || --  1.会社コード
                            ir_recept_month_cur.practice_date                         || cv_csv_com || --  2.年月
        cv_file_encloser || ir_recept_month_cur.base_code         || cv_file_encloser || cv_csv_com || --  3.拠点（部門）コード
        cv_file_encloser || ir_recept_month_cur.subinventory_code || cv_file_encloser || cv_csv_com || --  4.保管場所コード
        cv_file_encloser || ir_recept_month_cur.segment1          || cv_file_encloser || cv_csv_com || --  5.商品コード
        cv_file_encloser || ir_recept_month_cur.subinventory_type || cv_file_encloser || cv_csv_com || --  6.保管場所区分
                            ir_recept_month_cur.operation_cost                        || cv_csv_com || --  7.営業原価
                            ir_recept_month_cur.standard_cost                         || cv_csv_com || --  8.標準原価
                            gn_month_begin_quantity                                   || cv_csv_com || --  9.月首棚卸高
                            ln_factory_stock                                          || cv_csv_com || -- 10.工場入庫
                            ir_recept_month_cur.change_stock                          || cv_csv_com || -- 11.倉替入庫
                            ln_sum_stock                                              || cv_csv_com || -- 12.拠点内入庫
                            ir_recept_month_cur.goods_transfer_new                    || cv_csv_com || -- 13.振替入庫
                            ln_sales_shipped                                          || cv_csv_com || -- 14.売上出庫
                            ln_return_goods                                           || cv_csv_com || -- 15.顧客返品
                            ir_recept_month_cur.change_ship                           || cv_csv_com || -- 16.倉替出庫
                            ln_sum_ship                                               || cv_csv_com || -- 17.拠点内出庫
                            ln_sum_inv_change                                         || cv_csv_com || -- 18.基準在庫変更
                            ln_factory_return                                         || cv_csv_com || -- 19.工場返品
                            ln_factory_change                                         || cv_csv_com || -- 20.工場倉替
                            ln_removed_goods                                          || cv_csv_com || -- 21.廃却出庫
                            ir_recept_month_cur.goods_transfer_old                    || cv_csv_com || -- 22.振替出庫
                            ln_sum_sample                                             || cv_csv_com || -- 23.協賛見本
                            gn_inv_result                                             || cv_csv_com || -- 24.棚卸結果
                            gn_inv_result_bad                                         || cv_csv_com || -- 25.棚卸結果(不良品)
                            gn_inv_wear                                               || cv_csv_com || -- 26.棚卸減耗
                            lv_last_update_date                                       || cv_csv_com || -- 27.更新日時
                            lv_process_date;                                                           -- 28.連携日時
      --
      UTL_FILE.PUT_LINE(
          gv_activ_file_h     -- A-3.で取得したファイルハンドル
        , lv_recept_month        -- デリミタ＋上記CSV出力項目
        );
      --
      -- 正常件数に加算
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
-- == 2010/02/03 V1.3 Modified END   ===============================================================
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
  END create_csv_p;
--
-- == 2009/04/08 V1.1 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : get_inv_info_p
   * Description      : 棚卸情報取得(A-5)
   ***********************************************************************************/
  PROCEDURE get_inv_info_p(
     ir_recept_month_rec   IN  recept_month_cur%ROWTYPE -- コラムNO.
   , ov_errbuf             OUT VARCHAR2                 -- エラー・メッセージ           --# 固定 #
   , ov_retcode            OUT VARCHAR2                 -- リターン・コード             --# 固定 #
   , ov_errmsg             OUT VARCHAR2)                -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_info_p'; -- プログラム名
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
    -- A-5．棚卸情報取得
    -- パラメータ「処理区分」が「0：日次」の場合
    IF ( gv_process_type = cv_process_type_0 ) THEN
--
      -- 在庫会計期間の件数＞1件の場合（前月締め処理前）
      IF ( gn_open_period_cnt > 1 ) THEN
--
        -- 月次在庫受払表(累計)の年月＜業務日付の年月の場合
        IF ( ir_recept_month_rec.practice_date < TO_CHAR( gd_process_date, cv_fmt_date ) ) THEN
--
          BEGIN
            -- 月首棚卸高を取得
            SELECT xirm.inv_result                                                      -- 棚卸結果
            INTO   gn_month_begin_quantity
            FROM   xxcoi_inv_reception_monthly   xirm                                   -- 月次在庫受払表テーブル
            WHERE  xirm.organization_id        = ir_recept_month_rec.organization_id    -- A-4で取得した組織ID
            AND    xirm.base_code              = ir_recept_month_rec.base_code          -- A-4で取得した拠点コード
            AND    xirm.subinventory_code      = ir_recept_month_rec.subinventory_code  -- A-4で取得した保管場所
            AND    xirm.practice_month         = TO_CHAR(
                                                     ADD_MONTHS(
                                                         TO_DATE( ir_recept_month_rec.practice_date, cv_fmt_date )
                                                       , -1 )
                                                   , cv_fmt_date )                      -- A-4で取得した年月の前月
            AND    xirm.inventory_item_id      = ir_recept_month_rec.inventory_item_id  -- A-4で取得した品目ID
            AND    xirm.inventory_kbn          = cv_inv_kbn_2                           -- 棚卸区分：'2'（月末）
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              gn_month_begin_quantity := 0;
          END;
--
        -- 月次在庫受払表(累計)の年月＝業務日付の年月の場合
        ELSE
          gn_month_begin_quantity := 0;
--
        END IF;
--
      -- 在庫会計期間の件数＝1件の場合（前月締め処理後）
      ELSE
--
        BEGIN
          -- 月首棚卸高を取得
          SELECT xirm.inv_result                                                      -- 棚卸結果
          INTO   gn_month_begin_quantity
          FROM   xxcoi_inv_reception_monthly   xirm                                   -- 月次在庫受払表テーブル
          WHERE  xirm.organization_id        = ir_recept_month_rec.organization_id    -- A-4で取得した組織ID
          AND    xirm.base_code              = ir_recept_month_rec.base_code          -- A-4で取得した拠点コード
          AND    xirm.subinventory_code      = ir_recept_month_rec.subinventory_code  -- A-4で取得した保管場所
          AND    xirm.practice_month         = TO_CHAR(
                                                   ADD_MONTHS(
                                                       TO_DATE( ir_recept_month_rec.practice_date, cv_fmt_date )
                                                     , -1 )
                                                 , cv_fmt_date )                      -- A-4で取得した年月の前月
          AND    xirm.inventory_item_id      = ir_recept_month_rec.inventory_item_id  -- A-4で取得した品目ID
          AND    xirm.inventory_kbn          = cv_inv_kbn_2                           -- 棚卸区分：'2'（月末）
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            gn_month_begin_quantity := 0;
        END;
--
      END IF;
--
      -- 棚卸結果を取得
      gn_inv_result     := ir_recept_month_rec.book_inventory_quantity;
      -- 棚卸結果(不良品)を取得
      gn_inv_result_bad := 0;
      -- 棚卸減耗を取得
      gn_inv_wear       := 0;
--
    -- パラメータ「処理区分」が「1：月次」の場合
    ELSE
--
      -- 月次在庫受払表(累計)の年月＜業務日付の年月の場合
      IF ( ir_recept_month_rec.practice_date < TO_CHAR( gd_process_date, cv_fmt_date ) ) THEN
--
        BEGIN
          -- 前月分棚卸情報を取得
          SELECT   xirm.month_begin_quantity                                            -- 月首棚卸高
                 , xirm.inv_result                                                      -- 棚卸結果
                 , xirm.inv_result_bad                                                  -- 棚卸結果(不良品)
                 , xirm.inv_wear                                                        -- 棚卸減耗
          INTO     gn_month_begin_quantity
                 , gn_inv_result
                 , gn_inv_result_bad
                 , gn_inv_wear
          FROM     xxcoi_inv_reception_monthly   xirm                                   -- 月次在庫受払表テーブル
          WHERE    xirm.organization_id        = ir_recept_month_rec.organization_id    -- A-4で取得した組織ID
          AND      xirm.base_code              = ir_recept_month_rec.base_code          -- A-4で取得した拠点コード
          AND      xirm.subinventory_code      = ir_recept_month_rec.subinventory_code  -- A-4で取得した保管場所
          AND      xirm.practice_month         = ir_recept_month_rec.practice_date      -- A-4で取得した年月の前月
          AND      xirm.inventory_item_id      = ir_recept_month_rec.inventory_item_id  -- A-4で取得した品目ID
          AND      xirm.inventory_kbn          = cv_inv_kbn_2                           -- 棚卸区分：'2'（月末）
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          -- 前月分棚卸情報取得エラーメッセージ
          -- 「前月分棚卸情報が取得できませんでした。月次在庫受払情報を確認して下さい。」
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                           , iv_name         => cv_msg_xxcoi_10377
                           , iv_token_name1  => cv_tkn_month
                           , iv_token_value1 => ir_recept_month_rec.practice_date
                           , iv_token_name2  => cv_tkn_base_code
                           , iv_token_value2 => ir_recept_month_rec.base_code
                           , iv_token_name3  => cv_tkn_subinventory
                           , iv_token_value3 => ir_recept_month_rec.subinventory_code
                           , iv_token_name4  => cv_tkn_item_code
                           , iv_token_value4 => ir_recept_month_rec.inventory_item_id
                         );
            lv_errbuf := lv_errmsg;
            --
            RAISE global_api_expt;
        END;
--
      -- 月次在庫受払表(累計)の年月＝業務日付の年月の場合
      ELSE
        -- 月首棚卸高を取得
        BEGIN
          SELECT xirm.inv_result                                                      -- 棚卸結果
          INTO   gn_month_begin_quantity
          FROM   xxcoi_inv_reception_monthly   xirm                                   -- 月次在庫受払表テーブル
          WHERE  xirm.organization_id        = ir_recept_month_rec.organization_id    -- A-4で取得した組織ID
          AND    xirm.base_code              = ir_recept_month_rec.base_code          -- A-4で取得した拠点コード
          AND    xirm.subinventory_code      = ir_recept_month_rec.subinventory_code  -- A-4で取得した保管場所
          AND    xirm.practice_month         = TO_CHAR(
                                                   ADD_MONTHS(
                                                       TO_DATE( ir_recept_month_rec.practice_date, cv_fmt_date )
                                                     , -1 )
                                                 , cv_fmt_date )                      -- A-4で取得した年月の前月
          AND    xirm.inventory_item_id      = ir_recept_month_rec.inventory_item_id  -- A-4で取得した品目ID
          AND    xirm.inventory_kbn          = cv_inv_kbn_2                           -- 棚卸区分：'2'（月末）
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            gn_month_begin_quantity := 0;
        END;
--
        -- 棚卸結果を取得
        gn_inv_result     := ir_recept_month_rec.book_inventory_quantity;
        -- 棚卸結果(不良品)を取得
        gn_inv_result_bad := 0;
        -- 棚卸減耗を取得
        gn_inv_wear       := 0;
--
      END IF;
--
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
  END get_inv_info_p;
--
-- == 2009/04/08 V1.1 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : recept_month_cur_p
   * Description      : 月次在庫受払表(累計)情報の抽出(A-4)
   ***********************************************************************************/
  PROCEDURE recept_month_cur_p(
-- == 2009/04/08 V1.1 Moded END   ===============================================================
--     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
--   , ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
--   , ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
     iv_year_month IN  VARCHAR2     --   年月
   , ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   , ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   , ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
-- == 2009/04/08 V1.1 Moded END   ===============================================================
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'recept_month_cur_p'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode VARCHAR2(1);      -- リターン・コード
    lv_errmsg  VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
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
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    --月別受払残高データ取得カーソルオープン
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    OPEN recept_month_cur;
    OPEN recept_month_cur( 
           iv_practice_date => iv_year_month
         );
-- == 2009/04/08 V1.1 Moded END   ===============================================================
      --
      <<recept_month_loop>>
      LOOP
        FETCH recept_month_cur INTO recept_month_rec;
        --次データがなくなったら終了
        EXIT WHEN recept_month_cur%NOTFOUND;
-- == 2010/02/03 V1.3 Deleted START ===============================================================
--        --対象件数加算
--        gn_target_cnt := gn_target_cnt + 1;
-- == 2010/02/03 V1.3 Deleted END   ===============================================================
--
-- == 2009/04/08 V1.1 Added START ===============================================================
        -- ===============================
        -- A-5．棚卸情報取得
        -- ===============================
        get_inv_info_p(
            ir_recept_month_rec   => recept_month_rec        -- コラムNO.
          , ov_errbuf             => lv_errbuf               -- エラー・メッセージ           --# 固定 #
          , ov_retcode            => lv_retcode              -- リターン・コード             --# 固定 #
          , ov_errmsg             => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          -- エラー処理
          RAISE global_process_expt;
        END IF;
--
-- == 2009/04/08 V1.1 Added END   ===============================================================
        -- ===============================
        -- A-6．月別受払残高CSVの作成
        -- ===============================
        create_csv_p(
            ir_recept_month_cur   => recept_month_rec        -- コラムNO.
          , ov_errbuf             => lv_errbuf               -- エラー・メッセージ           --# 固定 #
          , ov_retcode            => lv_retcode              -- リターン・コード             --# 固定 #
          , ov_errmsg             => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          -- エラー処理
          RAISE global_process_expt;
        END IF;
--
-- == 2010/02/03 V1.3 Deleted START ===============================================================
--        -- 正常件数に加算
--        gn_normal_cnt := gn_normal_cnt + 1;
-- == 2010/02/03 V1.3 Deleted END   ===============================================================
      --
      --ループの終了
      END LOOP recept_month_loop;
      --
    --カーソルのクローズ
    CLOSE recept_month_cur;
-- == 2010/02/03 V1.3 Added START ===============================================================
    -- 対象件数設定
    gn_target_cnt :=  gn_normal_cnt;
-- == 2010/02/03 V1.3 Added END   ===============================================================
    --
-- == 2009/04/08 V1.1 Deleted START ===============================================================
--    -- データが０件で終了した場合
--    IF ( gn_target_cnt = 0 ) THEN
--      -- 対象データ無しメッセージ
--      -- 「対象データはありません。」
--      gv_out_msg   := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_appl_short_name
--                      , iv_name         => cv_msg_xxcoi_00008
--                      );
--      -- メッセージ出力
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => gv_out_msg
--      );
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.LOG
--        , buff   => gv_out_msg
--      );
--    END IF;
-- == 2009/04/08 V1.1 Deleted END   ===============================================================
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF recept_month_cur%ISOPEN THEN
        CLOSE recept_month_cur;
      END IF;
      --
      -- エラーメッセージ
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがオープンしている場合はクローズする
      IF recept_month_cur%ISOPEN THEN
        CLOSE recept_month_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがオープンしている場合はクローズする
      IF recept_month_cur%ISOPEN THEN
        CLOSE recept_month_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがオープンしている場合はクローズする
      IF recept_month_cur%ISOPEN THEN
        CLOSE recept_month_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END recept_month_cur_p;
--
-- == 2009/04/08 V1.1 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : get_open_period_p
   * Description      : オープン在庫会計期間取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_open_period_p(
     ov_errbuf             OUT VARCHAR2                 -- エラー・メッセージ           --# 固定 #
   , ov_retcode            OUT VARCHAR2                 -- リターン・コード             --# 固定 #
   , ov_errmsg             OUT VARCHAR2)                -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_open_period_p'; -- プログラム名
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
    -- カーソルオープン
    OPEN  get_open_period_cur;
--
    -- カーソルデータ取得
    FETCH get_open_period_cur BULK COLLECT INTO get_open_period_tab;
--
    -- カーソルのクローズ
    CLOSE get_open_period_cur;
--
    -- ===============================
    -- 対象件数カウント
    -- ===============================
    gn_open_period_cnt := get_open_period_tab.COUNT;
--
    -- ===============================
    -- 在庫会計期間取得チェック
    -- ===============================
    IF ( gn_open_period_cnt = 0 ) THEN
      -- 在庫会計期間取得エラーメッセージ
      -- 「当月以前のオープンしている在庫会計期間が取得できませんでした。在庫会計期間を確認して下さい。」
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_10376
                   );
      lv_errbuf := lv_errmsg;
      --
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
  END get_open_period_p;
--
-- == 2009/04/08 V1.1 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- == 2009/04/08 V1.1 Moded START ===============================================================
--     ov_errbuf     OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
--   , ov_retcode    OUT VARCHAR2    --   リターン・コード             --# 固定 #
--   , ov_errmsg     OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
     iv_process_type IN  VARCHAR2    --   処理区分
   , ov_errbuf       OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode      OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg       OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
-- == 2009/04/08 V1.1 Moded END   ===============================================================
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100)  := 'submain'; -- プログラム名
    cn_max_linesize   CONSTANT BINARY_INTEGER := 32767;
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);                   -- リターン・コード
    lv_errmsg       VARCHAR2(5000);                -- ユーザー・エラー・メッセージ
    --
    -- ファイルの存在チェック用変数
    lb_exists       BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length  NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
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
    -- *** ローカル例外 ***
    remain_file_expt           EXCEPTION;
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
    -- 初期化処理
    -- ===============================
    -- グローバル変数の初期化
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gv_activ_file_h  := NULL;            -- ファイルハンドル
-- == 2009/04/08 V1.1 Added START ===============================================================
    gv_process_type  := iv_process_type; -- 起動パラメータ：処理区分
-- == 2009/04/08 V1.1 Added END   ===============================================================
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ========================================
    --  A-1. 初期処理
    -- ========================================
    init(
        ov_errbuf    => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2．ファイルオープン処理
    -- ========================================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR( 
        location     =>  gv_dire_pass
      , filename     =>  gv_file_recept_month
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
--
    -- 同一ファイルが存在した場合はエラー
    IF( lb_exists = TRUE ) THEN
      RAISE remain_file_expt;
--
    ELSE
      -- ファイルオープン処理実行
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_dire_pass          -- ディレクトリパス
                          , filename     => gv_file_recept_month  -- ファイル名
                          , open_mode    => cv_file_mode          -- オープンモード
                          , max_linesize => cn_max_linesize       -- ファイルサイズ
                         );
    END IF;
    --
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    -- ========================================
--    -- A-3．月別受払残高情報の抽出
--    -- ========================================
--    -- A-3の処理内部でA-4を処理
--    recept_month_cur_p(
--        ov_errbuf    => lv_errbuf         -- エラー・メッセージ           --# 固定 #
--      , ov_retcode   => lv_retcode        -- リターン・コード             --# 固定 #
--      , ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
--    );
--    --
--    -- 終了パラメータ判定
--    IF (lv_retcode = cv_status_error) THEN
--      -- エラー処理
--      RAISE global_process_expt;
--    END IF;
--
    -- ========================================
    -- A-3．オープン在庫会計期間取得
    -- ========================================
    get_open_period_p(
        ov_errbuf    => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- 在庫会計期間単位処理ループ
    <<open_period_loop>>
    FOR i IN 1 .. get_open_period_tab.COUNT LOOP
      -- ========================================
      -- A-4．月別受払残高情報の抽出
      -- ========================================
      -- A-4の処理内部でA-5, A-6を処理
      recept_month_cur_p(
          iv_year_month => get_open_period_tab(i).year_month  -- 年月
        , ov_errbuf     => lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode    => lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg     => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        -- エラー処理
        RAISE global_process_expt;
      END IF;
--
-- == 2010/01/06 V1.2 Added START ===============================================================
      IF (    (gv_process_type = cv_process_type_1)
          AND (LAST_DAY(TO_DATE(get_open_period_tab(i).year_month, cv_fmt_date)) < gd_process_date)
         )
      THEN
        -- 処理区分：１（月次）かつ、締月（前月）の場合
        -- ========================================
        -- A-9．累計情報なし棚卸データCSV作成
        -- ========================================
        create_csv_i(
            iv_year_month => get_open_period_tab(i).year_month  -- 年月
          , ov_errbuf     => lv_errbuf         -- エラー・メッセージ           --# 固定 #
          , ov_retcode    => lv_retcode        -- リターン・コード             --# 固定 #
          , ov_errmsg     => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          -- エラー処理
          RAISE global_process_expt;
        END IF;
      END IF;
-- == 2010/01/06 V1.2 Added END   ===============================================================
      --
    END LOOP open_period_loop;
--
    -- データが０件で終了した場合
    IF ( gn_target_cnt = 0 ) THEN
      -- 対象データ無しメッセージ
      -- 「対象データはありません。」
      gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00008
                      );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => gv_out_msg
      );
    END IF;
-- 
-- == 2009/04/08 V1.1 Moded END   ===============================================================
    --
    -- ===============================
    -- A-7．ファイルのクローズ処理
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gv_activ_file_h
      );
--
  EXCEPTION
    -- カーソルのクローズをここに記述する
    -- *** ファイル存在チェックエラー ***
    -- 「ファイル「 FILE_NAME 」はすでに存在します。」
    WHEN remain_file_expt THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00027
                        , iv_token_name1  => cv_tkn_file_name
                        , iv_token_value1 => gv_file_recept_month
                      );
      lv_errbuf    := lv_errmsg;
      --
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode   := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- CSVファイルがオープンしていればクローズする
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- CSVファイルがオープンしていればクローズする
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- CSVファイルがオープンしていればクローズする
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
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
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
--    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_process_type IN  VARCHAR2       --   処理区分
-- == 2009/04/08 V1.1 Moded END   ===============================================================
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================
    -- 変数の初期化
    -- ===============================
    lv_errbuf    := NULL;   -- エラー・メッセージ
    lv_retcode   := NULL;   -- リターン・コード
    lv_errmsg    := NULL;   -- ユーザー・エラー・メッセージ
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
-- == 2009/04/08 V1.1 Moded START ===============================================================
--        ov_retcode => lv_retcode  -- エラー・メッセージ           --# 固定 #
--      , ov_errbuf  => lv_errbuf   -- リターン・コード             --# 固定 #
--      , ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        iv_process_type => iv_process_type -- 処理区分
      , ov_retcode      => lv_retcode      -- エラー・メッセージ           --# 固定 #
      , ov_errbuf       => lv_errbuf       -- リターン・コード             --# 固定 #
      , ov_errmsg       => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
-- == 2009/04/08 V1.1 Moded END   ===============================================================
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
    --
    --==============================================================
    -- A-8．件数表示処理
    --==============================================================
    -- エラー時は成功件数出力を０にセット
    --           エラー件数出力を１にセット
    IF( lv_retcode = cv_status_error ) THEN
-- == 2009/04/08 V1.1 Added START ===============================================================
      gn_target_cnt := 0;
-- == 2009/04/08 V1.1 Added END   ===============================================================
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      -- 正常終了メッセージ
      -- 「処理が正常終了しました。」
      lv_message_code := cv_normal_msg;
    --
    ELSIF(lv_retcode = cv_status_error) THEN
      -- エラー終了全ロールバックメッセージ
      -- 「処理がエラー終了しました。データは全件処理前の状態に戻しました。」
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      --
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
END XXCOI008A03C;
/
