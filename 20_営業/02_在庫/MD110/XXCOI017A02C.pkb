CREATE OR REPLACE PACKAGE BODY APPS.XXCOI017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI017A02C(body)
 * Description      : ロット別引当情報CSVをワークフロー形式で配信します。
 * MD.050           : ロット別出荷情報配信 <MD050_COI_017_A02>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_data            CSV出力処理(A-2)
 *  upd_lot_reserve_info   ロット別引当情報更新処理(A-3)
 *  submain                メイン処理プロシージャ
 *                         終了処理(A-4)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/08/01    1.0   K.Kiriu          新規作成
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
  --*** ロックエラー ***
  global_lock_expt          EXCEPTION;
  --*** 警告時 ***
  global_warn_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_expt,-54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI017A02C';             -- パッケージ名
  -- アプリケーション
  cv_app_xxcoi          CONSTANT VARCHAR2(5)   := 'XXCOI';                    -- アプリケーション短縮名(在庫)
  -- プロファイル
  cv_organization_code  CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:在庫組織コード
  -- メッセージ
  cv_msg_xxcoi_00005    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00005';         -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi_00006    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00006';         -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi_10039    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10039';         -- ロック取得エラーメッセージ
  cv_msg_xxcoi_10531    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10531';         -- 着日逆転エラーメッセージ
  cv_msg_xxcoi_10716    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10716';         -- 配信対象データなしエラーメッセージ
  cv_msg_xxcoi_10717    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10717';         -- ロット別出荷情報配信コンカレント入力パラメータ
  cv_msg_xxcoi_10718    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10718';         -- ロット別引当情報テーブル更新エラーメッセージ
  -- トークン
  cv_tkn_pro_tok        CONSTANT VARCHAR2(7)   := 'PRO_TOK';                  -- プロファイル
  cv_tkn_org_code_tok   CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';             -- 在庫組織コード
  cv_tkn_param1         CONSTANT VARCHAR2(6)   := 'PARAM1';                   -- パラメータ1
  cv_tkn_param2         CONSTANT VARCHAR2(6)   := 'PARAM2';                   -- パラメータ2
  cv_tkn_param3         CONSTANT VARCHAR2(6)   := 'PARAM3';                   -- パラメータ3
  cv_tkn_param_name1    CONSTANT VARCHAR2(11)  := 'PARAM_NAME1';              -- パラメータ1（名称）
  cv_tkn_err_msg        CONSTANT VARCHAR2(11)  := 'ERR_MSG';                  -- エラーメッセージ
  -- フォーマット
  cv_fmt_date           CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';               -- 日時
  cv_fmt_date_time_s    CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';    -- 日時分秒(セパレートあり)
  cv_fmt_date_time      CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';         -- 日時分秒(セパレートなし)
  -- 顧客関連
  cv_cust_cls_cd_base   CONSTANT VARCHAR2(1)   := '1';                        -- 顧客区分(1:拠点)
  -- WF関連
  cv_ope_div            CONSTANT VARCHAR2(2)   := '14';                       -- 処理区分:14(ロット別出荷情報)
  cv_wf_class           CONSTANT VARCHAR2(1)   := '9';                        -- 対象:9(単一拠点対象ユーザー)
  -- ロット別引当情報抽出関連
  cv_p_shipping_st_10   CONSTANT VARCHAR2(2)   := '10';                       -- 引当未
  cv_p_shipping_st_20   CONSTANT VARCHAR2(2)   := '20';                       -- 引当済
  cv_p_shipping_st_25   CONSTANT VARCHAR2(2)   := '25';                       -- 出荷仮確定
  cv_p_shipping_st_30   CONSTANT VARCHAR2(2)   := '30';                       -- 出荷確定
  -- 出力項目関連
  cv_company_name       CONSTANT VARCHAR2(5)   := 'ITOEN';                    -- 会社名
  cv_data_type          CONSTANT VARCHAR2(3)   := '620';                      -- 出荷情報
  cv_branch_no_header   CONSTANT VARCHAR2(2)   := '10';                       -- 伝送用枝番(ヘッダ)
  cv_branch_no_line     CONSTANT VARCHAR2(2)   := '20';                       -- 伝送用枝番(明細)
  cv_data_class         CONSTANT VARCHAR2(1)   := '0';                        -- データ区分
  cv_null               CONSTANT VARCHAR2(1)   := '';                         -- NULL
  -- ファイル操作関連
  cv_file_mode          CONSTANT VARCHAR2(1)   := 'W';                        -- 上書
  -- その他汎用
  cv_yes                CONSTANT VARCHAR2(1)   := 'Y';                        -- Y
  cv_sep_hyphen         CONSTANT VARCHAR2(1)   := '-';                        -- ハイフン
  cv_sep_underscore     CONSTANT VARCHAR2(1)   := '_';                        -- アンダースコア
  cv_sep_comma          CONSTANT VARCHAR2(1)   := ',';                        -- カンマ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE row_id_tbl IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  gt_rowid_tbl  row_id_tbl;               -- ロット別取引情報テーブルROWID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_organization_id    mtl_parameters.organization_id%TYPE   DEFAULT NULL;  -- 在庫組織ID
  gt_base_code          hz_cust_accounts.account_number%TYPE  DEFAULT NULL;  -- 拠点コード
  gd_request_date_from  DATE                                  DEFAULT NULL;  -- パラメータ着日(From)
  gd_request_date_to    DATE                                  DEFAULT NULL;  -- パラメータ着日(To)
--
  -- ===============================
  -- カーソル定義
  -- ===============================
  -- ロット別引当情報
  CURSOR g_target_data_cur(
     it_organization_id   mtl_parameters.organization_id%TYPE   -- 在庫組織ID
    ,it_base_code         hz_cust_accounts.account_number%TYPE  -- 拠点コード
    ,id_request_date_from DATE                                  -- 着日(From)
    ,id_request_date_to   DATE                                  -- 着日(To)
  )
  IS
    SELECT  /*+
              LEADING( xlri )
              USE_NL( xlri msi )
            */
            xlri.rowid                        row_id                       -- ロット別引当情報ROWID
           ,xlri.slip_num                     slip_num                     -- 伝票No
           ,xlri.base_code                    base_code                    -- 拠点コード
           ,xlri.base_name                    base_name                    -- 拠点名
           ,xlri.order_number                 order_number                 -- 受注番号
           ,xlri.parent_shipping_status       parent_shipping_status       -- 出荷情報ステータス(受注番号単位)
           ,xlri.parent_shipping_status_name  parent_shipping_status_name  -- 出荷情報ステータス名称(受注番号単位)
           ,xlri.whse_code                    whse_code                    -- 保管場所コード
           ,xlri.whse_name                    whse_name                    -- 保管場所名
           ,xlri.location_code                location_code                -- ロケーションコード
           ,xlri.location_name                location_name                -- ロケーション名称
           ,xlri.shipping_status              shipping_status              -- 出荷情報ステータス
           ,xlri.shipping_status_name         shipping_status_name         -- 出荷情報ステータス名称
           ,xlri.chain_code                   chain_code                   -- チェーン店コード
           ,xlri.chain_name                   chain_name                   -- チェーン店名
           ,xlri.shop_code                    shop_code                    -- 店舗コード
           ,xlri.shop_name                    shop_name                    -- 店舗名
           ,xlri.customer_code                customer_code                -- 顧客コード
           ,xlri.customer_name                customer_name                -- 顧客名
           ,xlri.center_code                  center_code                  -- センターコード
           ,xlri.center_name                  center_name                  -- センター名
           ,xlri.area_code                    area_code                    -- 地区コード
           ,xlri.area_name                    area_name                    -- 地区名称
           ,xlri.shipped_date                 shipped_date                 -- 出荷日
           ,xlri.arrival_date                 arrival_date                 -- 着日
           ,xlri.item_div                     item_div                     -- 商品区分
           ,xlri.item_div_name                item_div_name                -- 商品区分名
           ,xlri.parent_item_code             parent_item_code             -- 親品目コード
           ,xlri.parent_item_name             parent_item_name             -- 親品目名称
           ,xlri.item_code                    item_code                    -- 子品目コード
           ,xlri.item_name                    item_name                    -- 子品目名称
           ,xlri.lot                          lot                          -- ロット =>賞味期限
           ,xlri.difference_summary_code      difference_summary_code      -- 固有記号
           ,xlri.case_in_qty                  case_in_qty                  -- 入数
           ,xlri.case_qty                     case_qty                     -- ケース数
           ,xlri.singly_qty                   singly_qty                   -- バラ数
           ,xlri.summary_qty                  summary_qty                  -- 数量
           ,xlri.before_ordered_quantity      before_ordered_quantity      -- 訂正前受注数量
           ,xlri.regular_sale_class_line      regular_sale_class_line      -- 定番特売区分(明細)
           ,xlri.regular_sale_class_name_line regular_sale_class_name_line -- 定番特売区分名(明細)
           ,xlri.edi_received_date            edi_received_date            -- EDI受信日
           ,xlri.delivery_order_edi           delivery_order_edi           -- 配送順(EDI)
    FROM    xxcoi_lot_reserve_info    xlri
           ,mtl_secondary_inventories msi
    WHERE   msi.organization_id          = it_organization_id
    AND     msi.attribute15              = cv_yes                   -- 配信対象保管場所
    AND     xlri.base_code               = it_base_code
    AND     xlri.arrival_date      BETWEEN id_request_date_from
                                   AND     id_request_date_to
    AND     msi.secondary_inventory_name = xlri.whse_code
    AND     msi.attribute7               = it_base_code
    AND     xlri.parent_shipping_status IN (
                                               cv_p_shipping_st_10
                                              ,cv_p_shipping_st_20
                                              ,cv_p_shipping_st_25
                                              ,cv_p_shipping_st_30
                                           )                        -- 引当未・引当済・出荷仮確定・出荷確定
    AND     xlri.wf_delivery_flag IS NULL                           -- 未配信
    ORDER BY
            xlri.slip_num          ASC  -- 伝票No
           ,xlri.order_number      ASC  -- 受注番号
           ,xlri.whse_code         ASC  -- 保管場所コード
           ,xlri.location_code     ASC  -- ロケーションコード
           ,xlri.parent_item_code  ASC  -- 親品目コード
           ,xlri.item_code         ASC  -- 子品目コード
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_login_base_code   IN  VARCHAR2     -- 1.拠点コード
    ,iv_request_date_from IN  VARCHAR2     -- 2.着日（From）
    ,iv_request_date_to   IN  VARCHAR2     -- 3.着日（To）
    ,ov_errbuf            OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg            OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lt_organization_code  mtl_parameters.organization_code%TYPE DEFAULT NULL;  -- 在庫組織コード
    lt_base_name          hz_parties.party_name%TYPE            DEFAULT NULL;  -- 拠点名称
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
    --==================================
    -- 在庫組織ID取得
    --==================================
--
    -- 在庫組織コード取得
    lt_organization_code := FND_PROFILE.VALUE( cv_organization_code );
--
    IF ( lt_organization_code IS NULL ) THEN
      -- 在庫組織コード取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_00005
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 在庫組織ID取得
    gt_organization_id := xxcoi_common_pkg.get_organization_id( lt_organization_code );
--
    IF ( gt_organization_id IS NULL ) THEN
      -- 在庫組織ID取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_00006
                     ,iv_token_name1  => cv_tkn_org_code_tok
                     ,iv_token_value1 => lt_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 拠点名称取得
    --==================================
--
    gt_base_code := iv_login_base_code;
--
    BEGIN
      SELECT  hp.party_name  base_name
      INTO    lt_base_name
      FROM    hz_parties hp
             ,hz_cust_accounts hca
      WHERE   hca.customer_class_code = cv_cust_cls_cd_base
      AND     hca.account_number      = gt_base_code
      AND     hp.party_id             = hca.party_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_base_name := NULL;
    END;
--
    --==================================
    -- パラメータ出力
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application        => cv_app_xxcoi
                   ,iv_name               => cv_msg_xxcoi_10717
                   ,iv_token_name1        => cv_tkn_param1
                   ,iv_token_value1       => gt_base_code
                   ,iv_token_name2        => cv_tkn_param_name1
                   ,iv_token_value2       => lt_base_name
                   ,iv_token_name3        => cv_tkn_param2
                   ,iv_token_value3       => iv_request_date_from
                   ,iv_token_name4        => cv_tkn_param3
                   ,iv_token_value4       => iv_request_date_to
                 );
--
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_errmsg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => NULL
    );
--
    --==================================
    -- 日付逆転チェック
    --==================================
--
    gd_request_date_from := TO_DATE( iv_request_date_from, cv_fmt_date_time_s );
    gd_request_date_to   := TO_DATE( iv_request_date_to  , cv_fmt_date_time_s );
--
    IF ( gd_request_date_from > gd_request_date_to ) THEN
      -- 着日逆転エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10531
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
   * Procedure Name   : output_data
   * Description      : CSV出力処理(A-2)
   ***********************************************************************************/
  PROCEDURE output_data(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
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
    lr_wf_whs_rec       xxwsh_common3_pkg.wf_whs_rec         DEFAULT NULL;  -- ファイル情報格納レコード
    lf_file_hand        UTL_FILE.FILE_TYPE                   DEFAULT NULL;  -- ファイル・ハンドル
    lv_file_name        VARCHAR2(150)                        DEFAULT NULL;  -- ファイル名
    lv_csv_data         VARCHAR2(4000)                       DEFAULT NULL;  -- CSV文字列
    lt_slip_num         xxcoi_lot_reserve_info.slip_num%TYPE DEFAULT NULL;  -- 前レコードの伝票No
    ln_cnt              NUMBER                               DEFAULT 0;     -- 配列添え字
    ln_loop_cnt         NUMBER                               DEFAULT 0;     -- 処理件数用
    ln_lock_dummy       NUMBER;                                             -- ロック用ダミー
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_target_data_rec g_target_data_cur%ROWTYPE;
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
    --==================================
    -- ワークフロー情報取得
    --==================================
--
    -- 共通関数「アウトバウンド処理取得関数」呼出
    xxwsh_common3_pkg.get_wsh_wf_info(
       iv_wf_ope_div       => cv_ope_div     -- 処理区分
      ,iv_wf_class         => cv_wf_class    -- 対象
      ,iv_wf_notification  => gt_base_code   -- 宛先(拠点コード)
      ,or_wf_whs_rec       => lr_wf_whs_rec  -- ファイル情報
      ,ov_errbuf           => lv_errbuf      -- エラー・メッセージ
      ,ov_retcode          => lv_retcode     -- リターン・コード
      ,ov_errmsg           => lv_errmsg      -- ユーザー・エラー・メッセージ
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ファイル名編集
    lv_file_name := cv_ope_div                                                      -- 処理区分
                    || cv_sep_hyphen     || gt_base_code                            -- 宛先
                    || cv_sep_underscore || TO_CHAR( SYSDATE, cv_fmt_date_time )    -- 処理時刻
                    || lr_wf_whs_rec.file_name                                      -- ファイル名
    ;
--
    -- WFオーナーを起動ユーザへ変更
    lr_wf_whs_rec.wf_owner := fnd_global.user_name;
--
    --==================================
    -- ファイルオープン
    --==================================
    lf_file_hand := UTL_FILE.FOPEN(
                       lr_wf_whs_rec.directory -- ディレクトリ
                      ,lv_file_name            -- ファイル名
                      ,cv_file_mode            -- モード（上書）
                    );
--
    --==================================
    -- ロット別引当情報抽出
    --==================================
    << target_data_loop>>
    FOR  l_target_data_rec IN g_target_data_cur(
                                 gt_organization_id      -- 在庫組織ID
                                ,gt_base_code            -- パラメータ.拠点コード
                                ,gd_request_date_from    -- パラメータ.着日(From)
                                ,gd_request_date_to      -- パラメータ.着日(To)
                              )
    LOOP
--
      EXIT WHEN g_target_data_cur%NOTFOUND;
--
      -- 対象件数カウント
      ln_loop_cnt := ln_loop_cnt + 1;
--
      -- ループ初回、もしくは、前レコードの伝票Noと現コードの伝票Noが異なる場合
      IF ( ( lt_slip_num IS NULL ) OR ( lt_slip_num <> l_target_data_rec.slip_num ) )THEN
--
        -- 初期化
        lv_csv_data := NULL;
--
        --==================================
        -- ヘッダ情報出力
        --==================================
--
        -- 出力データの編集
        lv_csv_data := cv_company_name                                           || cv_sep_comma || -- 会社名
                       cv_data_type                                              || cv_sep_comma || -- データ種別
                       cv_branch_no_header                                       || cv_sep_comma || -- 伝送用枝番
                       l_target_data_rec.slip_num                                || cv_sep_comma || -- 伝票No
                       l_target_data_rec.base_code                               || cv_sep_comma || -- 拠点コード
                       l_target_data_rec.base_name                               || cv_sep_comma || -- 拠点名
                       cv_null                                                   || cv_sep_comma || -- 受注番号
                       cv_null                                                   || cv_sep_comma || -- 出荷情報ステータス(受注番号単位)
                       cv_null                                                   || cv_sep_comma || -- 出荷情報ステータス名(受注番号単位)
                       cv_null                                                   || cv_sep_comma || -- 保管場所コード
                       cv_null                                                   || cv_sep_comma || -- 保管場所名
                       cv_null                                                   || cv_sep_comma || -- ロケーションコード
                       cv_null                                                   || cv_sep_comma || -- ロケーション名
                       cv_null                                                   || cv_sep_comma || -- 出荷情報ステータス
                       cv_null                                                   || cv_sep_comma || -- 出荷情報ステータス名
                       cv_null                                                   || cv_sep_comma || -- チェーン店コード
                       cv_null                                                   || cv_sep_comma || -- チェーン店名
                       cv_null                                                   || cv_sep_comma || -- 店舗コード
                       cv_null                                                   || cv_sep_comma || -- 店舗名
                       cv_null                                                   || cv_sep_comma || -- 顧客コード
                       cv_null                                                   || cv_sep_comma || -- 顧客名
                       cv_null                                                   || cv_sep_comma || -- センターコード
                       cv_null                                                   || cv_sep_comma || -- センター名
                       cv_null                                                   || cv_sep_comma || -- 地区コード
                       cv_null                                                   || cv_sep_comma || -- 地区名称
                       cv_null                                                   || cv_sep_comma || -- 出荷日
                       cv_null                                                   || cv_sep_comma || -- 着日
                       cv_null                                                   || cv_sep_comma || -- 商品区分
                       cv_null                                                   || cv_sep_comma || -- 商品区分名
                       cv_null                                                   || cv_sep_comma || -- 親品目コード
                       cv_null                                                   || cv_sep_comma || -- 親品目名称
                       cv_null                                                   || cv_sep_comma || -- 子品目コード
                       cv_null                                                   || cv_sep_comma || -- 子品目名称
                       cv_null                                                   || cv_sep_comma || -- 賞味期限
                       cv_null                                                   || cv_sep_comma || -- 固有記号
                       cv_null                                                   || cv_sep_comma || -- 入数
                       cv_null                                                   || cv_sep_comma || -- ケース数
                       cv_null                                                   || cv_sep_comma || -- バラ数
                       cv_null                                                   || cv_sep_comma || -- 取引数量
                       cv_null                                                   || cv_sep_comma || -- 受注数量
                       cv_null                                                   || cv_sep_comma || -- 定番特売区分
                       cv_null                                                   || cv_sep_comma || -- 定番特売区分名
                       cv_null                                                   || cv_sep_comma || -- EDI受信日
                       cv_null                                                   || cv_sep_comma || -- 配送順(EDI)
                       cv_null                                                   || cv_sep_comma || -- データ区分
                       TO_CHAR( SYSDATE, cv_fmt_date_time_s )                                       -- 更新日
        ;
--
        -- ヘッダ出力
        UTL_FILE.PUT_LINE(
          lf_file_hand
         ,lv_csv_data
        );
--
      END IF;
--
      --==================================
      -- 明細情報出力
      --==================================
--
      -- 初期化
      lv_csv_data := NULL;
--
      -- 出力データの編集
      lv_csv_data := cv_company_name                                             || cv_sep_comma || -- 会社名
                     cv_data_type                                                || cv_sep_comma || -- データ種別
                     cv_branch_no_line                                           || cv_sep_comma || -- 伝送用枝番
                     cv_null                                                     || cv_sep_comma || -- 伝票No
                     cv_null                                                     || cv_sep_comma || -- 拠点コード
                     cv_null                                                     || cv_sep_comma || -- 拠点名
                     l_target_data_rec.order_number                              || cv_sep_comma || -- 受注番号
                     l_target_data_rec.parent_shipping_status                    || cv_sep_comma || -- 出荷情報ステータス(受注番号単位)
                     l_target_data_rec.parent_shipping_status_name               || cv_sep_comma || -- 出荷情報ステータス名(受注番号単位)
                     l_target_data_rec.whse_code                                 || cv_sep_comma || -- 保管場所コード
                     l_target_data_rec.whse_name                                 || cv_sep_comma || -- 保管場所名
                     l_target_data_rec.location_code                             || cv_sep_comma || -- ロケーションコード
                     l_target_data_rec.location_name                             || cv_sep_comma || -- ロケーション名
                     l_target_data_rec.shipping_status                           || cv_sep_comma || -- 出荷情報ステータス
                     l_target_data_rec.shipping_status_name                      || cv_sep_comma || -- 出荷情報ステータス名
                     l_target_data_rec.chain_code                                || cv_sep_comma || -- チェーン店コード
                     l_target_data_rec.chain_name                                || cv_sep_comma || -- チェーン店名
                     l_target_data_rec.shop_code                                 || cv_sep_comma || -- 店舗コード
                     l_target_data_rec.shop_name                                 || cv_sep_comma || -- 店舗名
                     l_target_data_rec.customer_code                             || cv_sep_comma || -- 顧客コード
                     l_target_data_rec.customer_name                             || cv_sep_comma || -- 顧客名
                     l_target_data_rec.center_code                               || cv_sep_comma || -- センターコード
                     l_target_data_rec.center_name                               || cv_sep_comma || -- センター名
                     l_target_data_rec.area_code                                 || cv_sep_comma || -- 地区コード
                     l_target_data_rec.area_name                                 || cv_sep_comma || -- 地区名称
                     TO_CHAR( l_target_data_rec.shipped_date, cv_fmt_date )      || cv_sep_comma || -- 出荷日
                     TO_CHAR( l_target_data_rec.arrival_date, cv_fmt_date )      || cv_sep_comma || -- 着日
                     l_target_data_rec.item_div                                  || cv_sep_comma || -- 商品区分
                     l_target_data_rec.item_div_name                             || cv_sep_comma || -- 商品区分名
                     l_target_data_rec.parent_item_code                          || cv_sep_comma || -- 親品目コード
                     l_target_data_rec.parent_item_name                          || cv_sep_comma || -- 親品目名称
                     l_target_data_rec.item_code                                 || cv_sep_comma || -- 子品目コード
                     l_target_data_rec.item_name                                 || cv_sep_comma || -- 子品目名称
                     l_target_data_rec.lot                                       || cv_sep_comma || -- 賞味期限
                     l_target_data_rec.difference_summary_code                   || cv_sep_comma || -- 固有記号
                     l_target_data_rec.case_in_qty                               || cv_sep_comma || -- 入数
                     l_target_data_rec.case_qty                                  || cv_sep_comma || -- ケース数
                     l_target_data_rec.singly_qty                                || cv_sep_comma || -- バラ数
                     l_target_data_rec.summary_qty                               || cv_sep_comma || -- 取引数量
                     l_target_data_rec.before_ordered_quantity                   || cv_sep_comma || -- 受注数量
                     l_target_data_rec.regular_sale_class_line                   || cv_sep_comma || -- 定番特売区分
                     l_target_data_rec.regular_sale_class_name_line              || cv_sep_comma || -- 定番特売区分名
                     TO_CHAR( l_target_data_rec.edi_received_date, cv_fmt_date)  || cv_sep_comma || -- EDI受信日
                     l_target_data_rec.delivery_order_edi                        || cv_sep_comma || -- 配送順(EDI)
                     cv_data_class                                               || cv_sep_comma || -- データ区分
                     TO_CHAR( SYSDATE, cv_fmt_date_time_s )                                         -- 更新日
      ;
--
      -- 明細出力
      UTL_FILE.PUT_LINE(
        lf_file_hand
       ,lv_csv_data
      );
--
      -- ヘッダ出力判定の為、伝票Noを変数に保持
      lt_slip_num := l_target_data_rec.slip_num;
--
      -- 出荷情報ステータス(受注番号単位)が「出荷仮確定」「出荷確定」の場合
      IF ( l_target_data_rec.parent_shipping_status IN ( cv_p_shipping_st_25, cv_p_shipping_st_30 ) ) THEN
        --==================================
        -- ロック取得
        --==================================
        -- 配信後のロックエラーを避ける為、ここでロック
        SELECT 1  dummy
        INTO   ln_lock_dummy
        FROM   xxcoi_lot_reserve_info    xlri
        WHERE  xlri.rowid = l_target_data_rec.row_id
        FOR UPDATE OF
               xlri.lot_reserve_info_id
        NOWAIT
        ;
        -- ロット別引当情報更新の為、ROWIDを格納
        ln_cnt               := ln_cnt + 1;
        gt_rowid_tbl(ln_cnt) := l_target_data_rec.row_id;
      END IF;
--
    END LOOP target_data_loop;
--
    -- 対象件数・成功件数の設定
    gn_target_cnt := ln_loop_cnt;
--
    --==================================
    -- ファイルクローズ
    --==================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    --==================================
    -- ワークフロー通知
    --==================================
    -- 対象が存在する場合のみ通知
    IF ( gn_target_cnt <> 0 ) THEN
--
      -- ワークフロー起動関数を実行
      xxwsh_common3_pkg.wf_whs_start(
         ir_wf_whs_rec => lr_wf_whs_rec      -- ワークフロー関連情報
        ,iv_filename   => lv_file_name       -- ファイル名
        ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ
        ,ov_retcode    => lv_retcode         -- リターン・コード
        ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF ;
--
    -- 対象件数が0件の場合は警告
    ELSE
      -- メッセージ生成
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10716
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --ステータスを警告にする
      ov_retcode := cv_status_warn;
--
    END IF;
--
  EXCEPTION
    -- *** ロック例外ハンドラ ***--
    WHEN global_lock_expt THEN
      -- ファイルクローズ
      UTL_FILE.FCLOSE( lf_file_hand );
      -- メッセー取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10039
                   );
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_reserve_info
   * Description      : ロット別引当情報更新処理(A-3)
   ***********************************************************************************/
  PROCEDURE upd_lot_reserve_info(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lot_reserve_info'; -- プログラム名
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
    BEGIN
      -- ロット別引当情報テーブル更新
      FORALL i IN 1.. gt_rowid_tbl.COUNT
        UPDATE  xxcoi_lot_reserve_info xilri
        SET     xilri.wf_delivery_flag          =   cv_yes               --WF配信フラグ(配信済)
               ,xilri.last_update_date          =   cd_last_update_date
               ,xilri.last_updated_by           =   cn_last_updated_by
               ,xilri.last_update_login         =   cn_last_update_login
               ,xilri.request_id                =   cn_request_id
               ,xilri.program_id                =   cn_program_id
               ,xilri.program_application_id    =   cn_program_application_id
               ,xilri.program_update_date       =   cd_last_update_date
        WHERE   xilri.rowid  =  gt_rowid_tbl(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        -- メッセージ生成
        lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_xxcoi
               ,iv_name         => cv_msg_xxcoi_10718
               ,iv_token_name1  => cv_tkn_err_msg
               ,iv_token_value1 => SQLERRM
             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END upd_lot_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_login_base_code    IN  VARCHAR2     -- 1.拠点コード
    ,iv_request_date_from  IN  VARCHAR2     -- 2.着日（From）
    ,iv_request_date_to    IN  VARCHAR2     -- 3.着日（To）
    ,ov_errbuf             OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode            OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg             OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_login_base_code    => iv_login_base_code     -- 1.拠点コード
      ,iv_request_date_from  => iv_request_date_from   -- 2.着日（From）
      ,iv_request_date_to    => iv_request_date_to     -- 3.着日（To）
      ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- CSV出力処理(A-2)
    -- ===============================
    output_data(
       ov_errbuf   => lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode  -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_warn) THEN
      RAISE global_warn_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 出荷仮確定・出荷確定の出力対象が存在した場合
    IF ( gt_rowid_tbl.COUNT <> 0 ) THEN
      -- ===============================
      -- ロット別引当情報更新処理(A-3)
      -- ===============================
      upd_lot_reserve_info(
         ov_errbuf   => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode  => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
    -- *** 警告時(対象なし) ***
    WHEN global_warn_expt THEN
      -- 処理を警告終了とする
      ov_retcode := lv_retcode;
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
    errbuf                OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode               OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_login_base_code    IN  VARCHAR2,      -- 1.拠点コード
    iv_request_date_from  IN  VARCHAR2,      -- 2.着日（From）
    iv_request_date_to    IN  VARCHAR2       -- 3.着日（To）
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
       iv_login_base_code    => iv_login_base_code    -- 1.拠点コード
      ,iv_request_date_from  => iv_request_date_from  -- 2.着日（From）
      ,iv_request_date_to    => iv_request_date_to    -- 3.着日（To）
      ,ov_errbuf             => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode            => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
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
      --件数設定
      gn_target_cnt := 0;  -- 対象件数
      gn_normal_cnt := 0;  -- 成功件数
      gn_error_cnt  := 1;  -- エラー件数
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      -- 件数設定(警告)
      gn_normal_cnt := 0;
      gn_error_cnt  := 0;
    ELSE
      -- 件数設定(正常)
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
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
END XXCOI017A02C;
/
