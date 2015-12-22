CREATE OR REPLACE PACKAGE BODY APPS.XXCCP003A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP003A01C(body)
 * Description      : 問屋未払データ出力
 * MD.070           : 問屋未払データ出力 (MD070_IPO_CCP_003_A01)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/09/15    1.0   S.Yamashita      [E_本稼動_11083]新規作成
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
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP003A01C'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********	************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_payment_date_from  IN  VARCHAR2      --   1.支払予定日FROM
   ,iv_payment_date_to    IN  VARCHAR2      --   2.支払予定日TO
   ,ov_errbuf             OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
    cv_msg_no_parameter     CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- パラメータなし
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
    ld_process_date              DATE := xxccp_common_pkg2.get_process_date; -- 業務日付
    --==================================================
    -- 関数取得値
    --==================================================
    lov_errbuf                   VARCHAR2(32767) DEFAULT NULL;  -- エラーバッファ
    lov_retcode                  VARCHAR2(32767) DEFAULT NULL;  -- リターンコード
    lov_errmsg                   VARCHAR2(32767) DEFAULT NULL;  -- エラーメッセージ
    lov_estimated_no             VARCHAR2(32767) DEFAULT NULL;  -- 見積書No
    lon_quote_line_id            NUMBER          DEFAULT NULL;  -- 問屋請求書明細ID
    lov_emp_code                 VARCHAR2(32767) DEFAULT NULL;  -- 担当者コード
    lon_market_amt               NUMBER          DEFAULT NULL;  -- 建値
    lon_allowance_amt            NUMBER          DEFAULT NULL;  -- 値引(割戻し)
    lon_normal_store_deliver_amt NUMBER          DEFAULT NULL;  -- 通常店納
    lon_once_store_deliver_amt   NUMBER          DEFAULT NULL;  -- 特売店納
    lon_net_selling_price        NUMBER          DEFAULT NULL;  -- NET価格
    lon_normal_net_selling_price NUMBER          DEFAULT NULL;  -- 通常NET価格
    lov_estimated_type           VARCHAR2(32767) DEFAULT NULL;  -- 見積区分
    lon_backmargin_amt           NUMBER          DEFAULT NULL;  -- 販売手数料
    lon_sales_support_amt        NUMBER          DEFAULT NULL;  -- 販売協賛金
    --==================================================
    -- 出力用項目
    --==================================================
    lv_file_output_info     VARCHAR2(3000)                                          DEFAULT NULL;  -- 出力データ
    lv_wholesale_payment_id VARCHAR2(20)                                            DEFAULT NULL;  -- 問屋支払ID
    lv_payment_date         VARCHAR2(20)                                            DEFAULT NULL;  -- 支払予定日
    lv_selling_month        xxcok.xxcok_wholesale_payment.selling_month%TYPE        DEFAULT NULL;  -- 売上対象年月
    lv_base_code            xxcok.xxcok_wholesale_payment.base_code%TYPE            DEFAULT NULL;  -- 拠点コード
    lv_supplier_code        xxcok.xxcok_wholesale_payment.supplier_code%TYPE        DEFAULT NULL;  -- 仕入先コード
    lv_emp_code             xxcok.xxcok_wholesale_payment.emp_code%TYPE             DEFAULT NULL;  -- 担当者コード
    lv_wholesale_code_admin xxcok.xxcok_wholesale_payment.wholesale_code_admin%TYPE DEFAULT NULL;  -- 問屋管理コード
    lv_oprtn_status_code    xxcok.xxcok_wholesale_payment.oprtn_status_code%TYPE    DEFAULT NULL;  -- 業態コード
    lv_cust_code            xxcok.xxcok_wholesale_payment.cust_code%TYPE            DEFAULT NULL;  -- 顧客コード
    lv_sales_outlets_code   xxcok.xxcok_wholesale_payment.sales_outlets_code%TYPE   DEFAULT NULL;  -- 問屋帳合先コード
    lv_estimated_type       xxcok.xxcok_wholesale_payment.estimated_type%TYPE       DEFAULT NULL;  -- 見積区分
    lv_estimated_no         xxcok.xxcok_wholesale_payment.estimated_no%TYPE         DEFAULT NULL;  -- 見積番号
    lv_container_group_code xxcok.xxcok_wholesale_payment.container_group_code%TYPE DEFAULT NULL;  -- 容器群コード
    lv_case_qty             VARCHAR2(20)                                            DEFAULT NULL;  -- ケース入数
    lv_item_code            xxcok.xxcok_wholesale_payment.item_code%TYPE            DEFAULT NULL;  -- 商品コード
    lv_market_amt           VARCHAR2(20)                                            DEFAULT NULL;  -- 建値
    lv_selling_discount     VARCHAR2(20)                                            DEFAULT NULL;  -- 売上値引
    lv_normal_dlv_amt       VARCHAR2(20)                                            DEFAULT NULL;  -- 通常店納
    lv_once_dlv_amt         VARCHAR2(20)                                            DEFAULT NULL;  -- 今回店納
    lv_net_selling_price    VARCHAR2(20)                                            DEFAULT NULL;  -- NET価格
    lv_coverage_amt         VARCHAR2(20)                                            DEFAULT NULL;  -- 補填
    lv_wholesale_margin_amt VARCHAR2(20)                                            DEFAULT NULL;  -- 問屋マージン
    lv_expansion_sales_amt  VARCHAR2(20)                                            DEFAULT NULL;  -- 拡売費
    lv_list_price           VARCHAR2(20)                                            DEFAULT NULL;  -- 定価
    lv_demand_unit_type     xxcok.xxcok_wholesale_payment.demand_unit_type%TYPE     DEFAULT NULL;  -- 請求単位
    lv_demand_qty           VARCHAR2(20)                                            DEFAULT NULL;  -- 請求数量
    lv_demand_unit_price    VARCHAR2(20)                                            DEFAULT NULL;  -- 請求単価
    lv_demand_amt           VARCHAR2(20)                                            DEFAULT NULL;  -- 請求金額(税抜)
    lv_payment_qty          VARCHAR2(20)                                            DEFAULT NULL;  -- 支払数量
    lv_payment_unit_price   VARCHAR2(20)                                            DEFAULT NULL;  -- 支払単価
    lv_payment_amt          VARCHAR2(20)                                            DEFAULT NULL;  -- 支払金額(税抜)
    lv_acct_code            xxcok.xxcok_wholesale_payment.acct_code%TYPE            DEFAULT NULL;  -- 勘定科目コード
    lv_sub_acct_code        xxcok.xxcok_wholesale_payment.sub_acct_code%TYPE        DEFAULT NULL;  -- 補助科目コード
    lv_coverage_amt_sum     VARCHAR2(20)                                            DEFAULT NULL;  -- 補填額
    lv_wholesale_margin_sum VARCHAR2(20)                                            DEFAULT NULL;  -- 問屋マージン額
    lv_expansion_sales_sum  VARCHAR2(20)                                            DEFAULT NULL;  -- 拡売費額
    lv_misc_acct_amt        VARCHAR2(20)                                            DEFAULT NULL;  -- その他科目額
    lv_sysdate              VARCHAR2(14)                                            DEFAULT NULL;  -- システム日付
    ln_fraction_amount      NUMBER                                                  DEFAULT NULL;  -- 端数計算用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 問屋未払レコード取得
    CURSOR main_cur( iv_payment_date_from IN VARCHAR2, iv_payment_date_to IN VARCHAR2 )
    IS
      SELECT /*+ LEADING(xwbh xwbl iimb ximb xsib)
                 INDEX (xwbh xxcok_wholesale_bill_head_n03)
                 USE_NL(xwbh xwbl iimb ximb xsib) */
             xwbh.base_code                   AS base_code                  -- 拠点コード
           , xwbh.cust_code                   AS cust_code                  -- 顧客コード
           , xca1.wholesale_ctrl_code         AS wholesale_ctrl_code        -- 問屋管理コード
           , xwbh.expect_payment_date         AS expect_payment_date        -- 支払予定日
           , xwbh.supplier_code               AS supplier_code              -- 仕入先コード
           , xwbl.selling_month               AS selling_month              -- 売上対象年月
           , xwbl.sales_outlets_code          AS sales_outlets_code         -- 問屋帳合先コード
           , xwbl.item_code                   AS item_code                  -- 品目コード
           , xwbl.acct_code                   AS acct_code                  -- 勘定科目コード
           , xwbl.sub_acct_code               AS sub_acct_code              -- 補助科目コード
           , xwbl.demand_unit_type            AS demand_unit_type           -- 請求単位
           , xwbl.demand_qty                  AS demand_qty                 -- 請求数量
           , xwbl.demand_unit_price           AS demand_unit_price          -- 請求単価
           , xwbl.payment_qty                 AS payment_qty                -- 支払数量
           , xwbl.payment_unit_price          AS payment_unit_price         -- 支払単価
           , flv_gyotai.attribute1            AS gyotai_chu                 -- 業態中分類(問屋帳合先)
           , xsib.vessel_group                AS vessel_group               -- 容器群コード
           , iimb.attribute11                 AS case_qty                   -- ケース入り数
           , CASE WHEN NVL( TO_DATE( iimb.attribute6, 'YYYY/MM/DD' ), ld_process_date ) > ld_process_date
                    THEN
                      iimb.attribute4  -- 定価（旧）
                    ELSE
                      iimb.attribute5  -- 定価（新）
                  END                         AS list_price                 -- 定価
      FROM   xxcok_wholesale_bill_head     xwbh           -- 問屋請求書ヘッダテーブル
           , xxcok_wholesale_bill_line     xwbl           -- 問屋請求書明細テーブル
           , xxcmm_cust_accounts           xca1           -- 顧客追加情報（顧客）
           , xxcmm_cust_accounts           xca2           -- 顧客追加情報（問屋帳合先）
           , fnd_lookup_values             flv_gyotai     -- クイックコード（業態小分類）
           , xxcmm_system_items_b          xsib -- Disc品目アドオン
           , ic_item_mst_b                 iimb -- OPM品目マスタ
           , xxcmn_item_mst_b              ximb -- OPM品目アドオン
      WHERE xwbl.wholesale_bill_header_id     = xwbh.wholesale_bill_header_id
        AND xwbh.cust_code                    = xca1.customer_code
        AND xwbl.sales_outlets_code           = xca2.customer_code
        AND flv_gyotai.lookup_code            = xca2.business_low_type
        AND flv_gyotai.language               = USERENV( 'LANG' )
        AND flv_gyotai.lookup_type            = 'XXCMM_CUST_GYOTAI_SHO'         -- 参照タイプ：業態（小分類）
        AND xwbh.expect_payment_date    BETWEEN NVL ( ximb.start_date_active, xwbh.expect_payment_date )
                                            AND NVL ( ximb.end_date_active  , xwbh.expect_payment_date )
        AND xwbl.item_code                    = iimb.item_no(+)
        AND xsib.item_id(+)                   = iimb.item_id
        AND iimb.item_id                      = ximb.item_id(+)
        AND NVL(xwbl.status,'X')              <> 'D'
        AND xwbl.payment_qty * xwbl.payment_unit_price <> 0
        AND xwbh.expect_payment_date BETWEEN TO_DATE( iv_payment_date_from, 'YYYY/MM/DD HH24:MI:SS' )
                                         AND TO_DATE( iv_payment_date_to, 'YYYY/MM/DD HH24:MI:SS' )
      ;
    -- メインカーソルレコード型
    main_rec  main_cur%ROWTYPE;
    -- 問屋未払レコード型
    l_xwp_rec xxcok.xxcok_wholesale_payment%ROWTYPE;
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
    -- init部
    -- ===============================
    --==============================================================
    -- 入力パラメータ出力
    --==============================================================
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '支払予定日FROM : ' || TO_CHAR( TO_DATE( iv_payment_date_from, 'YYYY/MM/DD HH24:MI:SS' ), 'YYYY/MM/DD' )
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '支払予定日TO   : ' || TO_CHAR( TO_DATE( iv_payment_date_to, 'YYYY/MM/DD HH24:MI:SS' ), 'YYYY/MM/DD' )
                     );
--
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    -- 支払予定日FROM > 支払予定日TO の場合
    IF ( TO_DATE( iv_payment_date_from, 'YYYY/MM/DD HH24:MI:SS' ) > TO_DATE( iv_payment_date_to, 'YYYY/MM/DD HH24:MI:SS' ) ) THEN
      ov_errbuf  := '支払予定日FROM は 支払予定日TO 以前の日付を指定して下さい。';
      ov_retcode := cv_status_error;
    ELSE
      -- ===============================
      -- 処理部
      -- ===============================
--
      -- 項目名出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   =>           '"' || '問屋支払ID'         || '"' -- 問屋支払ID
                   || ',' || '"' || '会社コード'         || '"' -- 会社コード
                   || ',' || '"' || '支払予定日'         || '"' -- 支払予定日
                   || ',' || '"' || '売上対象年月'       || '"' -- 売上対象年月
                   || ',' || '"' || '拠点コード'         || '"' -- 拠点コード
                   || ',' || '"' || '仕入先コード'       || '"' -- 仕入先コード
                   || ',' || '"' || '担当者コード'       || '"' -- 担当者コード
                   || ',' || '"' || '問屋管理コード'     || '"' -- 問屋管理コード
                   || ',' || '"' || '業態コード'         || '"' -- 業態コード
                   || ',' || '"' || '顧客コード'         || '"' -- 顧客コード
                   || ',' || '"' || '問屋帳合先コード'   || '"' -- 問屋帳合先コード
                   || ',' || '"' || '見積区分'           || '"' -- 見積区分
                   || ',' || '"' || '見積番号'           || '"' -- 見積番号
                   || ',' || '"' || '容器群コード'       || '"' -- 容器群コード
                   || ',' || '"' || 'ケース入数'         || '"' -- ケース入数
                   || ',' || '"' || '商品コード'         || '"' -- 商品コード
                   || ',' || '"' || '建値'               || '"' -- 建値
                   || ',' || '"' || '売上値引'           || '"' -- 売上値引
                   || ',' || '"' || '通常店納'           || '"' -- 通常店納
                   || ',' || '"' || '今回店納'           || '"' -- 今回店納
                   || ',' || '"' || 'NET価格'            || '"' -- NET価格
                   || ',' || '"' || '補填'               || '"' -- 補填
                   || ',' || '"' || '問屋マージン'       || '"' -- 問屋マージン
                   || ',' || '"' || '拡売費'             || '"' -- 拡売費
                   || ',' || '"' || '定価'               || '"' -- 定価
                   || ',' || '"' || '請求単位'           || '"' -- 請求単位
                   || ',' || '"' || '請求数量'           || '"' -- 請求数量
                   || ',' || '"' || '請求単価'           || '"' -- 請求単価
                   || ',' || '"' || '請求金額(税抜)'     || '"' -- 請求金額(税抜)
                   || ',' || '"' || '支払数量'           || '"' -- 支払数量
                   || ',' || '"' || '支払単価'           || '"' -- 支払単価
                   || ',' || '"' || '支払金額(税抜)'     || '"' -- 支払金額(税抜)
                   || ',' || '"' || '勘定科目コード'     || '"' -- 勘定科目コード
                   || ',' || '"' || '補助科目コード'     || '"' -- 補助科目コード
                   || ',' || '"' || '補填額'             || '"' -- 補填額
                   || ',' || '"' || '問屋マージン額'     || '"' -- 問屋マージン額
                   || ',' || '"' || '拡売費額'           || '"' -- 拡売費額
                   || ',' || '"' || 'その他科目額'       || '"' -- その他科目額
                   || ',' || '"' || 'システム日付'       || '"' -- システム日付
      );
      -- データ部出力(CSV)
      FOR main_rec IN main_cur( iv_payment_date_from, iv_payment_date_to ) LOOP
        --件数セット
        gn_target_cnt := gn_target_cnt + 1;
        --==================================================
        -- 初期化
        --==================================================
        l_xwp_rec                    := NULL; -- 問屋未払レコード
        lov_errbuf                   := NULL; -- エラーバッファ
        lov_retcode                  := NULL; -- リターンコード
        lov_errmsg                   := NULL; -- エラーメッセージ
        lov_estimated_no             := NULL; -- 見積書No
        lon_quote_line_id            := NULL; -- 問屋請求書明細ID
        lov_emp_code                 := NULL; -- 担当者コード
        lon_market_amt               := NULL; -- 建値
        lon_allowance_amt            := NULL; -- 値引(割戻し)
        lon_normal_store_deliver_amt := NULL; -- 通常店納
        lon_once_store_deliver_amt   := NULL; -- 特売店納
        lon_net_selling_price        := NULL; -- NET価格
        lon_normal_net_selling_price := NULL; -- 通常NET価格
        lov_estimated_type           := NULL; -- 見積区分
        lon_backmargin_amt           := NULL; -- 販売手数料
        lon_sales_support_amt        := NULL; -- 販売協賛金
        lv_file_output_info          := NULL; -- 出力データ
        lv_wholesale_payment_id      := NULL; -- 問屋支払ID
        lv_payment_date              := NULL; -- 支払予定日
        lv_selling_month             := NULL; -- 売上対象年月
        lv_base_code                 := NULL; -- 拠点コード
        lv_supplier_code             := NULL; -- 仕入先コード
        lv_emp_code                  := NULL; -- 担当者コード
        lv_wholesale_code_admin      := NULL; -- 問屋管理コード
        lv_oprtn_status_code         := NULL; -- 業態コード
        lv_cust_code                 := NULL; -- 顧客コード
        lv_sales_outlets_code        := NULL; -- 問屋帳合先コード
        lv_estimated_type            := NULL; -- 見積区分
        lv_estimated_no              := NULL; -- 見積番号
        lv_container_group_code      := NULL; -- 容器群コード
        lv_case_qty                  := NULL; -- ケース入数
        lv_item_code                 := NULL; -- 商品コード
        lv_market_amt                := NULL; -- 建値
        lv_selling_discount          := NULL; -- 売上値引
        lv_normal_dlv_amt            := NULL; -- 通常店納
        lv_once_dlv_amt              := NULL; -- 今回店納
        lv_net_selling_price         := NULL; -- NET価格
        lv_coverage_amt              := NULL; -- 補填額
        lv_wholesale_margin_amt      := NULL; -- 問屋マージン
        lv_expansion_sales_amt       := NULL; -- 拡売費
        lv_list_price                := NULL; -- 定価
        lv_demand_unit_type          := NULL; -- 請求単位
        lv_demand_qty                := NULL; -- 請求数量
        lv_demand_unit_price         := NULL; -- 請求単価
        lv_demand_amt                := NULL; -- 請求金額(税抜)
        lv_payment_qty               := NULL; -- 支払数量
        lv_payment_unit_price        := NULL; -- 支払単価
        lv_payment_amt               := NULL; -- 支払金額(税抜)
        lv_acct_code                 := NULL; -- 勘定科目コード
        lv_sub_acct_code             := NULL; -- 補助科目コード
        lv_coverage_amt_sum          := NULL; -- 補填額
        lv_wholesale_margin_sum      := NULL; -- 問屋マージン額
        lv_expansion_sales_sum       := NULL; -- 拡売費額
        lv_misc_acct_amt             := NULL; -- その他科目額
        lv_sysdate                   := NULL; -- システム日付
        ln_fraction_amount           := NULL; -- 端数計算用
        --==================================================
        -- 共通関数「問屋請求見積照合」呼び出し
        --==================================================
        xxcok_common_pkg.get_wholesale_req_est_p(
          ov_errbuf                    => lov_errbuf                    -- エラーバッファ
        , ov_retcode                   => lov_retcode                   -- リターンコード
        , ov_errmsg                    => lov_errmsg                    -- エラーメッセージ
        , iv_wholesale_code            => main_rec.wholesale_ctrl_code  -- 問屋管理コード
        , iv_sales_outlets_code        => main_rec.sales_outlets_code   -- 問屋帳合先コード
        , iv_item_code                 => main_rec.item_code            -- 品目コード
        , in_demand_unit_price         => main_rec.payment_unit_price   -- 請求単価
        , iv_demand_unit_type          => main_rec.demand_unit_type     -- 請求単位
        , iv_selling_month             => main_rec.selling_month        -- 売上対象年月
        , ov_estimated_no              => lov_estimated_no              -- 見積書No
        , on_quote_line_id             => lon_quote_line_id             -- 問屋請求書明細ID
        , ov_emp_code                  => lov_emp_code                  -- 担当者コード
        , on_market_amt                => lon_market_amt                -- 建値
        , on_allowance_amt             => lon_allowance_amt             -- 値引(割戻し)
        , on_normal_store_deliver_amt  => lon_normal_store_deliver_amt  -- 通常店納
        , on_once_store_deliver_amt    => lon_once_store_deliver_amt    -- 特売店納
        , on_net_selling_price         => lon_net_selling_price         -- NET価格
        , on_normal_net_selling_price  => lon_normal_net_selling_price  -- 通常NET価格
        , ov_estimated_type            => lov_estimated_type            -- 見積区分
        , on_backmargin_amt            => lon_backmargin_amt            -- 販売手数料
        , on_sales_support_amt         => lon_sales_support_amt         -- 販売協賛金
        );
        --==================================================
        -- 問屋未払レコード作成
        --==================================================
        l_xwp_rec.base_code                    := main_rec.base_code;                                            -- 拠点コード
        l_xwp_rec.emp_code                     := lov_emp_code;                                                  -- 担当者コード
        l_xwp_rec.oprtn_status_code            := main_rec.gyotai_chu;                                           -- 業態コード
        l_xwp_rec.item_code                    := main_rec.item_code;                                            -- 品目コード
        l_xwp_rec.container_group_code         := main_rec.vessel_group;                                         -- 容器群コード
        l_xwp_rec.estimated_type               := lov_estimated_type;                                            -- 見積区分
        l_xwp_rec.market_amt                   := lon_market_amt;                                                -- 建値
        l_xwp_rec.normal_store_deliver_amt     := lon_normal_store_deliver_amt;                                  -- 通常店納
        l_xwp_rec.once_store_deliver_amt       := lon_once_store_deliver_amt;                                    -- 今回店納
        l_xwp_rec.coverage_amt                 := lon_market_amt - lon_normal_store_deliver_amt;                 -- 補填
        l_xwp_rec.expansion_sales_amt          := lon_normal_store_deliver_amt - lon_once_store_deliver_amt;     -- 拡売費
        l_xwp_rec.net_selling_price            := lon_net_selling_price;                                         -- NET価格
        IF( lon_once_store_deliver_amt = 0 OR lon_once_store_deliver_amt IS NULL ) THEN
          l_xwp_rec.wholesale_margin_sum       := lon_normal_store_deliver_amt - lon_net_selling_price;
        ELSE
          l_xwp_rec.wholesale_margin_sum       := lon_once_store_deliver_amt   - lon_net_selling_price;
        END IF;                                                                                                  -- 問屋マージン
        l_xwp_rec.selling_discount             := lon_allowance_amt;                                             -- 売上値引
        l_xwp_rec.acct_code                    := main_rec.acct_code;                                            -- 勘定科目コード
        l_xwp_rec.sub_acct_code                := main_rec.sub_acct_code;                                        -- 補助科目コード
        l_xwp_rec.selling_month                := main_rec.selling_month;                                        -- 売上対象年月
        l_xwp_rec.wholesale_code_admin         := main_rec.wholesale_ctrl_code;                                  -- 問屋管理コード
        l_xwp_rec.cust_code                    := main_rec.cust_code;                                            -- 顧客コード
        l_xwp_rec.sales_outlets_code           := main_rec.sales_outlets_code;                                   -- 問屋帳合先コード
        l_xwp_rec.payment_qty                  := main_rec.payment_qty;                                          -- 支払数量
        l_xwp_rec.payment_unit_price           := main_rec.payment_unit_price;                                   -- 支払単価
        l_xwp_rec.payment_amt                  := TRUNC( main_rec.payment_qty * main_rec.payment_unit_price );   -- 支払金額
        l_xwp_rec.estimated_no                 := lov_estimated_no;                                              -- 見積番号
        l_xwp_rec.estimated_detail_id          := lon_quote_line_id;                                             -- 見積書明細ID
        l_xwp_rec.supplier_code                := main_rec.supplier_code;                                        -- 仕入先コード
        l_xwp_rec.demand_qty                   := main_rec.demand_qty;                                           -- 請求数量
        l_xwp_rec.demand_unit_type             := main_rec.demand_unit_type;                                     -- 請求単位
        l_xwp_rec.demand_unit_price            := main_rec.demand_unit_price;                                    -- 請求単価
        l_xwp_rec.demand_amt                   := TRUNC( main_rec.demand_qty  * main_rec.demand_unit_price  );   -- 請求金額
        l_xwp_rec.expect_payment_date          := main_rec.expect_payment_date;                                  -- 支払予定日
        IF( main_rec.acct_code IS NOT NULL ) THEN
          l_xwp_rec.misc_acct_amt              := TRUNC( main_rec.payment_qty * main_rec.payment_unit_price );   -- その他科目
        END IF;
        l_xwp_rec.backmargin                   := lon_backmargin_amt;                                            -- 販売手数料
        l_xwp_rec.sales_support_amt            := lon_sales_support_amt;                                         -- 販売協賛金
        --==================================================
        -- 出力用項目設定
        --==================================================
        lv_wholesale_payment_id := TO_CHAR( l_xwp_rec.wholesale_payment_id );     -- 問屋支払ID
        lv_payment_date         := TO_CHAR( l_xwp_rec.expect_payment_date
                                          , 'YYYY/MM/DD' );                       -- 支払予定日
        lv_selling_month        := l_xwp_rec.selling_month;                       -- 売上対象年月
        lv_base_code            := l_xwp_rec.base_code;                           -- 拠点コード
        lv_supplier_code        := l_xwp_rec.supplier_code;                       -- 仕入先コード
        lv_emp_code             := NVL( l_xwp_rec.emp_code, '00000' );            -- 担当者コード
        lv_wholesale_code_admin := l_xwp_rec.wholesale_code_admin;                -- 問屋管理コード
        lv_oprtn_status_code    := l_xwp_rec.oprtn_status_code;                   -- 業態コード
        lv_cust_code            := l_xwp_rec.cust_code;                           -- 顧客コード
        lv_sales_outlets_code   := l_xwp_rec.sales_outlets_code;                  -- 問屋帳合先コード
        lv_estimated_type       := NVL( l_xwp_rec.estimated_type, '1' );          -- 見積区分
        lv_estimated_no         := NVL( l_xwp_rec.estimated_no, '見積なし' );     -- 見積番号
        lv_container_group_code := l_xwp_rec.container_group_code;                -- 容器群コード
        lv_case_qty             := TO_CHAR( main_rec.case_qty );                  -- ケース入数
        lv_item_code            := l_xwp_rec.item_code;                           -- 商品コード
        lv_market_amt           := TO_CHAR( l_xwp_rec.market_amt );               -- 建値
        lv_selling_discount     := TO_CHAR( l_xwp_rec.selling_discount );         -- 売上値引
        lv_normal_dlv_amt       := TO_CHAR( l_xwp_rec.normal_store_deliver_amt ); -- 通常店納
        lv_once_dlv_amt         := TO_CHAR( l_xwp_rec.once_store_deliver_amt );   -- 今回店納
        lv_net_selling_price    := TO_CHAR( l_xwp_rec.net_selling_price );        -- NET価格
        lv_coverage_amt         := TO_CHAR( l_xwp_rec.coverage_amt );             -- 補填
        lv_wholesale_margin_amt := TO_CHAR( l_xwp_rec.wholesale_margin_sum );     -- 問屋マージン
        lv_expansion_sales_amt  := TO_CHAR( l_xwp_rec.expansion_sales_amt );      -- 拡売費
        lv_list_price           := TO_CHAR( main_rec.list_price );                -- 定価
        lv_demand_unit_type     := l_xwp_rec.demand_unit_type;                    -- 請求単位
        lv_demand_qty           := TO_CHAR( l_xwp_rec.demand_qty );               -- 請求数量
        lv_demand_unit_price    := TO_CHAR( l_xwp_rec.demand_unit_price );        -- 請求単価
        lv_demand_amt           := TO_CHAR( l_xwp_rec.demand_amt );               -- 請求金額(税抜)
        lv_payment_qty          := TO_CHAR( l_xwp_rec.payment_qty );              -- 支払数量
        lv_payment_unit_price   := TO_CHAR( l_xwp_rec.payment_unit_price );       -- 支払単価
        lv_payment_amt          := TO_CHAR( l_xwp_rec.payment_amt );              -- 支払金額(税抜)
        lv_acct_code            := l_xwp_rec.acct_code;                           -- 勘定科目コード
        lv_sub_acct_code        := l_xwp_rec.sub_acct_code;                       -- 補助科目コード
        -- 補填額
        IF (    (   NVL( l_xwp_rec.market_amt              , 0 )
                  - NVL( l_xwp_rec.selling_discount        , 0 )
                  - NVL( l_xwp_rec.normal_store_deliver_amt, 0 ) <= 0
                )
             OR ( l_xwp_rec.backmargin IS NULL )
             OR ( l_xwp_rec.backmargin <= 0    )
           )
        THEN
          lv_coverage_amt_sum := '0';
        ELSE
          lv_coverage_amt_sum :=
            TO_CHAR( ROUND( (   NVL( l_xwp_rec.market_amt              , 0 )
                              - NVL( l_xwp_rec.selling_discount        , 0 )
                              - NVL( l_xwp_rec.normal_store_deliver_amt, 0 )
                            ) * NVL( l_xwp_rec.payment_qty             , 0 )
                     )
            );
        END IF;
        -- 問屋マージン額
        IF ( l_xwp_rec.backmargin >= 0 ) THEN
          lv_wholesale_margin_sum :=
            TO_CHAR( TRUNC(   NVL( l_xwp_rec.backmargin , 0  )
                            * NVL( l_xwp_rec.payment_qty, 0  )
                            - TO_NUMBER( lv_coverage_amt_sum )
                     )
             );
        ELSE
          lv_wholesale_margin_sum :=
            TO_CHAR( TRUNC(   NVL( l_xwp_rec.backmargin , 0 )
                            * NVL( l_xwp_rec.payment_qty, 0 )
                     )
            );
        END IF;
        -- 拡売費額
        lv_expansion_sales_sum := TO_CHAR( TRUNC(   NVL( l_xwp_rec.sales_support_amt, 0 )
                                                  * NVL( l_xwp_rec.payment_qty      , 0 )
                                           )
                                  );
        -- ===============================================
        -- 端数処理
        -- 支払金額=補填+問屋マージン+拡売費を満たさない場合
        -- 問屋マージンにて金額調整を行う
        -- ===============================================
        IF( l_xwp_rec.acct_code IS NULL ) THEN
          ln_fraction_amount :=   TO_NUMBER( lv_coverage_amt_sum     )
                                + TO_NUMBER( lv_wholesale_margin_sum )
                                + TO_NUMBER( lv_expansion_sales_sum  );
          IF ( NVL( l_xwp_rec.payment_amt
                  , l_xwp_rec.demand_amt ) != ln_fraction_amount ) THEN
            lv_wholesale_margin_sum := TO_CHAR(   TO_NUMBER( lv_wholesale_margin_sum )
                                                + ( NVL( l_xwp_rec.payment_amt
                                                       , l_xwp_rec.demand_amt  ) - ln_fraction_amount )
                                       );
          END IF;
        END IF;
        IF( l_xwp_rec.acct_code IS NOT NULL ) THEN
          IF (     l_xwp_rec.acct_code     = '83110'    -- 勘定科目
               AND l_xwp_rec.sub_acct_code = '05103'    -- 補助科目
          ) THEN
            lv_wholesale_margin_sum := TO_CHAR( l_xwp_rec.misc_acct_amt );           -- 問屋マージン額
          ELSIF (     l_xwp_rec.acct_code     = '83111' -- 勘定科目
                  AND l_xwp_rec.sub_acct_code = '05132' -- 補助科目
          ) THEN
            lv_expansion_sales_sum  := TO_CHAR( l_xwp_rec.misc_acct_amt );           -- 拡売費額
          ELSE
            lv_misc_acct_amt        := TO_CHAR( l_xwp_rec.misc_acct_amt );           -- その他科目額
          END IF;
        ELSE
          lv_misc_acct_amt          := TO_CHAR( l_xwp_rec.misc_acct_amt );           -- その他科目額
        END IF;
        lv_sysdate                  := TO_CHAR( SYSDATE, 'YYYYMMDDHH24MISS' );       -- システム日付
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   =>           '"' || lv_wholesale_payment_id  || '"' -- 問屋支払ID
                     || ',' || '"' || '001'                    || '"' -- 会社コード
                     || ',' || '"' || lv_payment_date          || '"' -- 支払予定日
                     || ',' || '"' || lv_selling_month         || '"' -- 売上対象年月
                     || ',' || '"' || lv_base_code             || '"' -- 拠点コード
                     || ',' || '"' || lv_supplier_code         || '"' -- 仕入先コード
                     || ',' || '"' || lv_emp_code              || '"' -- 担当者コード
                     || ',' || '"' || lv_wholesale_code_admin  || '"' -- 問屋管理コード
                     || ',' || '"' || lv_oprtn_status_code     || '"' -- 業態コード
                     || ',' || '"' || lv_cust_code             || '"' -- 顧客コード
                     || ',' || '"' || lv_sales_outlets_code    || '"' -- 問屋帳合先コード
                     || ',' || '"' || lv_estimated_type        || '"' -- 見積区分
                     || ',' || '"' || lv_estimated_no          || '"' -- 見積番号
                     || ',' || '"' || lv_container_group_code  || '"' -- 容器群コード
                     || ',' || '"' || lv_case_qty              || '"' -- ケース入数
                     || ',' || '"' || lv_item_code             || '"' -- 商品コード
                     || ',' || '"' || lv_market_amt            || '"' -- 建値
                     || ',' || '"' || lv_selling_discount      || '"' -- 売上値引
                     || ',' || '"' || lv_normal_dlv_amt        || '"' -- 通常店納
                     || ',' || '"' || lv_once_dlv_amt          || '"' -- 今回店納
                     || ',' || '"' || lv_net_selling_price     || '"' -- NET価格
                     || ',' || '"' || lv_coverage_amt          || '"' -- 補填
                     || ',' || '"' || lv_wholesale_margin_amt  || '"' -- 問屋マージン
                     || ',' || '"' || lv_expansion_sales_amt   || '"' -- 拡売費
                     || ',' || '"' || lv_list_price            || '"' -- 定価
                     || ',' || '"' || lv_demand_unit_type      || '"' -- 請求単位
                     || ',' || '"' || lv_demand_qty            || '"' -- 請求数量
                     || ',' || '"' || lv_demand_unit_price     || '"' -- 請求単価
                     || ',' || '"' || lv_demand_amt            || '"' -- 請求金額(税抜)
                     || ',' || '"' || lv_payment_qty           || '"' -- 支払数量
                     || ',' || '"' || lv_payment_unit_price    || '"' -- 支払単価
                     || ',' || '"' || lv_payment_amt           || '"' -- 支払金額(税抜)
                     || ',' || '"' || lv_acct_code             || '"' -- 勘定科目コード
                     || ',' || '"' || lv_sub_acct_code         || '"' -- 補助科目コード
                     || ',' || '"' || lv_coverage_amt_sum      || '"' -- 補填額
                     || ',' || '"' || lv_wholesale_margin_sum  || '"' -- 問屋マージン額
                     || ',' || '"' || lv_expansion_sales_sum   || '"' -- 拡売費額
                     || ',' || '"' || lv_misc_acct_amt         || '"' -- その他科目額
                     || ',' || '"' || lv_sysdate               || '"' -- システム日付
        );
      END LOOP;
--
      -- 成功件数＝対象件数
      gn_normal_cnt  := gn_target_cnt;
      -- 対象件数=0であればメッセージ出力
      IF (gn_target_cnt = 0) THEN
       FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => CHR(10) || '対象データはありません。'
       );
      END IF;
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
    errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_payment_date_from  IN  VARCHAR2      --   1.支払予定日FROM
   ,iv_payment_date_to    IN  VARCHAR2      --   2.支払予定日TO
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
       iv_which   => 'LOG'
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
       iv_payment_date_from  --   1.支払予定日FROM
      ,iv_payment_date_to    --   2.支払予定日TO
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP003A01C;
/