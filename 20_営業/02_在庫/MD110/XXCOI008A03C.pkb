CREATE OR REPLACE PACKAGE BODY XXCOI008A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A03C(body)
 * Description      : 情報系システムへの連携の為、EBSの月次在庫受払表(アドオン)をCSVファイルに出力
 * MD.050           : 月別受払残高情報系連携 <MD050_COI_008_A03>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  create_csv_p           受払(在庫)CSVの作成(A-4)
 *  recept_month_cur_p     月次在庫受払表情報の抽出(A-3)
 *  submain                メイン処理プロシージャ
 *                           ・ファイルのオープン処理(A-2)
 *                           ・ファイルのクローズ処理(A-5) 
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/07    1.0   S.Kanda          新規作成
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
  --
  --トークン
  cv_tkn_pro                CONSTANT VARCHAR2(10)  := 'PRO_TOK';       -- プロファイル名用
  cv_tkn_dir                CONSTANT VARCHAR2(10)  := 'DIR_TOK';       -- プロファイル名用
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';         -- 件数メッセージ用
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';     -- ファイル名用
  cv_tkn_org_code           CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';  -- 在庫組織コード用
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
--
  -- ==============================
  -- ユーザー定義カーソル
  -- ==============================
  -- 月別受払残高情報取得
  CURSOR recept_month_cur
  IS
    SELECT xirm.practice_month          -- 年月
         , xirm.base_code               -- 拠点コード
         , xirm.subinventory_code       -- 保管場所
         , xirm.subinventory_type       -- 保管場所区分
         , xirm.operation_cost          -- 営業原価
         , xirm.standard_cost           -- 標準原価
         , xirm.month_begin_quantity    -- 月首棚卸高
         , xirm.factory_stock           -- 工場入庫
         , xirm.factory_stock_b         -- 工場入庫振戻
         , xirm.change_stock            -- 倉替入庫
         , xirm.warehouse_stock         -- 倉庫からの入庫
         , xirm.truck_stock             -- 営業車からの入庫
         , xirm.others_stock            -- 入出庫＿その他入庫
         , xirm.goods_transfer_new      -- 商品振替(新商品)
         , xirm.sales_shipped           -- 売上出庫
         , xirm.sales_shipped_b         -- 売上出庫振戻
         , xirm.return_goods            -- 返品
         , xirm.return_goods_b          -- 返品振戻
         , xirm.change_ship             -- 倉替出庫
         , xirm.warehouse_ship          -- 倉庫へ出庫
         , xirm.truck_ship              -- 営業車へ出庫
         , xirm.others_ship             -- 入出庫＿その他出庫
         , xirm.inventory_change_in     -- 基準在庫変更入庫
         , xirm.inventory_change_out    -- 基準在庫変更出庫
         , xirm.factory_return          -- 工場返品
         , xirm.factory_return_b        -- 工場返品振戻
         , xirm.factory_change          -- 工場倉替
         , xirm.factory_change_b        -- 工場倉替振戻
         , xirm.removed_goods           -- 廃却
         , xirm.removed_goods_b         -- 廃却振戻
         , xirm.goods_transfer_old      -- 商品振替(旧商品)
         , xirm.sample_quantity         -- 見本出庫
         , xirm.sample_quantity_b       -- 見本出庫振戻
         , xirm.customer_sample_ship    -- 顧客見本出庫
         , xirm.customer_sample_ship_b  -- 顧客見本出庫振戻
         , xirm.customer_support_ss     -- 顧客協賛見本出庫
         , xirm.customer_support_ss_b   -- 顧客協賛見本出庫振戻
         , xirm.ccm_sample_ship         -- 顧客広告宣伝費A自社商品
         , xirm.ccm_sample_ship_b       -- 顧客広告宣伝費A自社商品振戻
         , xirm.inv_result              -- 棚卸結果
         , xirm.inv_result_bad          -- 棚卸結果(不良品)
         , xirm.inv_wear                -- 棚卸減耗
         , xirm.last_update_date        -- 最終更新日
         , msib.segment1                -- 品目コード
    FROM   xxcoi_inv_reception_monthly  xirm  -- 月次在庫受払表テーブル
         , mtl_system_items_b           msib  -- 品目マスタ
         , org_acct_periods             oap   -- 在庫会計期間
    WHERE  xirm.inventory_kbn       = cv_inv_kbn_2            -- 棚卸区分(月末)
    AND    msib.inventory_item_id   = xirm.inventory_item_id  -- 品目ID
    AND    msib.organization_id     = gn_organization_id      -- A-1.で取得した在庫組織ID
    AND    oap.organization_id      = msib.organization_id    -- 組織ID
    AND    xirm.practice_date                           -- 月次在庫受払表テーブル.年月日
      BETWEEN oap.period_start_date                     -- 会計期間開始日
      AND     oap.schedule_close_date                   -- クローズ予定日
    AND    oap.open_flag            = cv_yes;           -- オープンフラグ
    --
    -- recept_monthレコード型
    recept_month_rec   recept_month_cur%ROWTYPE;
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
    --
    -- ===============================
    --  1.SYSDATE取得
    -- ===============================
    gd_process_date   :=  sysdate;
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
    -- コンカレント入力パラメータなしメッセージを出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00023
                    );
    --
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
  /**********************************************************************************
   * Procedure Name   : create_csv_p
   * Description      : 受払(在庫)CSVの作成(A-4)
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
    lv_process_date     := TO_CHAR( gd_process_date , 'YYYYMMDDHH24MISS' );                    -- 連携日時
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
    -- 基準在庫変更  = カーソルで抽出した基準在庫変更入庫 + 基準在庫変更出庫
    ln_sum_inv_change := NVL( ir_recept_month_cur.inventory_change_in , 0 )
                           + NVL( ir_recept_month_cur.inventory_change_out , 0 );
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
    lv_recept_month := 
      cv_file_encloser || gv_company_code                       || cv_file_encloser || cv_csv_com || -- 1.会社コード
                          ir_recept_month_cur.practice_month                        || cv_csv_com || -- 2.年月
      cv_file_encloser || ir_recept_month_cur.base_code         || cv_file_encloser || cv_csv_com || -- 3.拠点（部門）コード
      cv_file_encloser || ir_recept_month_cur.subinventory_code || cv_file_encloser || cv_csv_com || -- 4.保管場所コード
      cv_file_encloser || ir_recept_month_cur.segment1          || cv_file_encloser || cv_csv_com || -- 5.商品コード
      cv_file_encloser || ir_recept_month_cur.subinventory_type || cv_file_encloser || cv_csv_com || -- 6.保管場所区分
                          ir_recept_month_cur.operation_cost                        || cv_csv_com || -- 7.営業原価
                          ir_recept_month_cur.standard_cost                         || cv_csv_com || -- 8.標準原価
                          ir_recept_month_cur.month_begin_quantity                  || cv_csv_com || -- 9.月首棚卸高
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
                          ir_recept_month_cur.inv_result                            || cv_csv_com || -- 24.棚卸結果
                          ir_recept_month_cur.inv_result_bad                        || cv_csv_com || -- 25.棚卸結果(不良品)
                          ir_recept_month_cur.inv_wear                              || cv_csv_com || -- 26.棚卸減耗
                          lv_last_update_date                                       || cv_csv_com || -- 27.更新日時
                          lv_process_date;                                                           -- 28.連携日時
--
    UTL_FILE.PUT_LINE(
        gv_activ_file_h     -- A-3.で取得したファイルハンドル
      , lv_recept_month        -- デリミタ＋上記CSV出力項目
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
  END create_csv_p;
--
  /**********************************************************************************
   * Procedure Name   : recept_month_cur_p
   * Description      : 月次在庫受払表情報の抽出(A-3)
   ***********************************************************************************/
  PROCEDURE recept_month_cur_p(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   , ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   , ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
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
    OPEN recept_month_cur;
      --
      <<recept_month_loop>>
      LOOP
        FETCH recept_month_cur INTO recept_month_rec;
        --次データがなくなったら終了
        EXIT WHEN recept_month_cur%NOTFOUND;
        --対象件数加算
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===============================
        -- A-4．月別受払残高CSVの作成
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
        -- 正常件数に加算
        gn_normal_cnt := gn_normal_cnt + 1;
      --
      --ループの終了
      END LOOP recept_month_loop;
      --
    --カーソルのクローズ
    CLOSE recept_month_cur;
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   , ov_retcode    OUT VARCHAR2    --   リターン・コード             --# 固定 #
   , ov_errmsg     OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ========================================
    -- A-3．月別受払残高情報の抽出
    -- ========================================
    -- A-3の処理内部でA-4を処理
    recept_month_cur_p(
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
    -- ===============================
    -- A-5．ファイルのクローズ処理
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
        ov_retcode => lv_retcode  -- エラー・メッセージ           --# 固定 #
      , ov_errbuf  => lv_errbuf   -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- A-6．件数表示処理
    --==============================================================
    -- エラー時は成功件数出力を０にセット
    --           エラー件数出力を１にセット
    IF( lv_retcode = cv_status_error ) THEN
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
