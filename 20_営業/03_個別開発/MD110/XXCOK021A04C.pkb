CREATE OR REPLACE PACKAGE BODY XXCOK021A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A04C(body)
 * Description      : 情報系システムインターフェースファイル作成-問屋支払
 * MD.050           : 情報系システムインターフェースファイル作成-問屋支払 MD050_COK_021_A04
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_file_open          ファイルオープン(A-2)
 *  get_wholesale_info     連携対象問屋支払情報取得(A-3)
 *  file_output            フラットファイル作成(A-4)
 *  update_status          出力済データステータス更新(A-5)
 *  file_close             ファイルクローズ(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.0   A.Yano           新規作成
 *  2009/02/06    1.1   T.Abe            [障害COK_016] ディレクトリパス出力対応
 *  2009/03/19    1.2   A.Yano           [障害T1_0087] 必須項目の不具合対応
 *  2009/04/21    1.3   M.Hiruta         [障害T1_0551] 補填額・問屋マージン額・拡売費額の取得方法を変更
 *  2009/12/18    1.4   K.Yamaguchi      [E_本稼動_00530] 支払金額=補填+問屋マージン+拡売費を満たさない場合
 *                                                        問屋マージンで金額調整を行うように修正（端数調整）
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20)   := 'XXCOK021A04C';
  -- ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER         := fnd_global.user_id;           -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER         := fnd_global.user_id;           -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER         := fnd_global.login_id;          -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER         := fnd_global.conc_request_id;   -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER         := fnd_global.prog_appl_id;      -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER         := fnd_global.conc_program_id;   -- PROGRAM_ID
  -- セパレータ
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1)    := '.';
  -- アプリケーション短縮名
  cv_app_name_ccp           CONSTANT VARCHAR2(5)    := 'XXCCP';
  cv_app_name_cok           CONSTANT VARCHAR2(5)    := 'XXCOK';
  -- メッセージ
  cv_no_parameter_msg       CONSTANT VARCHAR2(20)   := 'APP-XXCCP1-90008';           -- コンカレント入力パラメータなし
  cv_profile_err_msg        CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00003';           -- プロファイル取得エラー
  cv_org_id_nodata_msg      CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00013';           -- 在庫組織ID取得エラー
  cv_process_date_err_msg   CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00028';           -- 業務処理日付取得エラー
  cv_out_filename_msg       CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00006';           -- ファイル名メッセージ出力
  cv_file_chk_err_msg       CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00009';           -- ファイル存在チェックエラー
  cv_lock_err_msg           CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-10068';           -- 問屋支払情報ロック取得エラー
  cv_update_err_msg         CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-10069';           -- 連携ステータス更新エラー
  cv_out_dire_path_msg      CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00067';           -- ディレクトリパスメッセージ出力
  -- トークン
  cv_tkn_profile_name       CONSTANT VARCHAR2(10)   := 'PROFILE';                    -- プロファイル名
  cv_tkn_org_code           CONSTANT VARCHAR2(10)   := 'ORG_CODE';                   -- 在庫組織コード
  cv_tkn_file_name          CONSTANT VARCHAR2(10)   := 'FILE_NAME';                  -- ファイル名
  cv_tkn_dire_path_name     CONSTANT VARCHAR2(10)   := 'DIRECTORY';                  -- ディレクトリパス
  cv_tkn_wholesale_id       CONSTANT VARCHAR2(20)   := 'WHOLESALE_ID';               -- 問屋支払ID
  -- プロファイル名
  cv_comp_code              CONSTANT VARCHAR2(30)   := 'XXCOK1_AFF1_COMPANY_CODE';   -- XXCOK:会社コード
  cv_wholesale_dire_path    CONSTANT VARCHAR2(30)   := 'XXCOK1_WHOLESALE_DIRE_PATH'; -- XXCOK:ディレクトリパス
  cv_wholesale_file_name    CONSTANT VARCHAR2(30)   := 'XXCOK1_WHOLESALE_FILE_NAME'; -- XXCOK:ファイル名
--【2009/03/19 A.Yano Ver.1.2 追加START】------------------------------------------------------
  cv_emp_code_dummy         CONSTANT VARCHAR2(30)   := 'XXCOK1_EMP_CODE_DUMMY';      -- XXCOK:担当者コード_ダミー値
  cv_estimated_type_dummy   CONSTANT VARCHAR2(30)   := 'XXCOK1_ESTIMATED_TYPE_DUMMY';-- XXCOK:見積区分_ダミー値
  cv_estimated_no_dummy     CONSTANT VARCHAR2(30)   := 'XXCOK1_ESTIMATED_NO_DUMMY';  -- XXCOK:見積番号_ダミー値
--【2009/03/19 A.Yano Ver.1.2 追加END  】------------------------------------------------------
  cv_organization_code      CONSTANT VARCHAR2(30)   := 'XXCOK1_ORG_CODE_SALES';      -- XXCOK:在庫組織コード_営業組織
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD START
  cv_prof_aff3_fee          CONSTANT VARCHAR2(30)   := 'XXCOK1_AFF3_SELL_FEE';      -- 勘定科目_販売手数料（問屋）
  cv_prof_aff3_support      CONSTANT VARCHAR2(30)   := 'XXCOK1_AFF3_SELL_SUPPORT';  -- 勘定科目_販売協賛金（問屋）
  cv_prof_aff4_fee          CONSTANT VARCHAR2(30)   := 'XXCOK1_AFF4_SELL_FEE';      -- 補助科目_問屋条件
  cv_prof_aff4_support      CONSTANT VARCHAR2(30)   := 'XXCOK1_AFF4_SELL_SUPPORT';  -- 補助科目_拡売費
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD END
  -- AP連携ステータス
  cv_ap_interface_status    CONSTANT VARCHAR2(1)    := '1';                          -- 連携済
  -- 情報系システム連携ステータス
  cv_info_if_status_before  CONSTANT VARCHAR2(1)    := '0';                          -- 未処理
  cv_info_if_status_after   CONSTANT VARCHAR2(1)    := '1';                          -- 処理済
  -- 記号
  cv_slash                  CONSTANT VARCHAR2(1)    := '/';
  cv_double_quotation       CONSTANT VARCHAR2(1)    := '"';
  cv_comma                  CONSTANT VARCHAR2(1)    := ',';
  -- ファイルオープン時パラメータ
  cv_write_mode             CONSTANT VARCHAR2(1)    := 'w';                          -- ファイル上書き
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;                        -- 最大入出力サイズ
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_target_cnt             NUMBER                                               DEFAULT 0;     -- 対象件数
  gn_normal_cnt             NUMBER                                               DEFAULT 0;     -- 正常件数
  gn_error_cnt              NUMBER                                               DEFAULT 0;     -- エラー件数
  gn_warn_cnt               NUMBER                                               DEFAULT 0;     -- スキップ件数
  gd_process_date           DATE                                                 DEFAULT NULL;  -- 業務処理日付
  gd_sysdate                DATE                                                 DEFAULT NULL;  -- システム日付
  gv_comp_code              VARCHAR2(5)                                          DEFAULT NULL;  -- 会社コード
  gv_wholesale_dire_path    fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- ディレクトリパス
  gv_wholesale_file_name    fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- ファイル名
--【2009/03/19 A.Yano Ver.1.2 追加START】------------------------------------------------------
  gv_emp_code_dummy         fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- 担当者コード_ダミー値
  gv_estimated_type_dummy   fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- 見積区分_ダミー値
  gv_estimated_no_dummy     fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- 見積番号_ダミー値
--【2009/03/19 A.Yano Ver.1.2 追加END  】------------------------------------------------------
  gn_organization_id        NUMBER                                               DEFAULT NULL;  -- 在庫組織ID
  g_file_handle             UTL_FILE.FILE_TYPE;                                                 -- ファイルハンドル
  gv_dire_path              VARCHAR2(1000)                                       DEFAULT NULL;  -- ディレクトリパス(メッセージ出力用)
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD START
  gv_aff3_fee               VARCHAR2(50);                -- プロファイル値(販売手数料（問屋）)
  gv_aff3_support           VARCHAR2(50);                -- プロファイル値(販売協賛金（問屋）)
  gv_aff4_fee               VARCHAR2(50);                -- プロファイル値(問屋条件)
  gv_aff4_support           VARCHAR2(50);                -- プロファイル値(拡売費)
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD END
  -- ===============================
  -- グローバルカーソル
  -- ===============================
  -- 連携対象問屋支払情報
  CURSOR g_wholesale_info_cur
  IS
    SELECT xwp.wholesale_payment_id                 AS wholesale_payment_id       -- 問屋支払ID
          ,xwp.expect_payment_date                  AS expect_payment_date        -- 支払予定日
          ,xwp.selling_month                        AS selling_month              -- 売上対象年月
          ,xwp.base_code                            AS base_code                  -- 拠点コード
          ,xwp.supplier_code                        AS supplier_code              -- 仕入先コード
          ,xwp.emp_code                             AS emp_code                   -- 担当者コード
          ,xwp.wholesale_code_admin                 AS wholesale_code_admin       -- 問屋管理コード
          ,xwp.oprtn_status_code                    AS oprtn_status_code          -- 業態コード
          ,xwp.cust_code                            AS cust_code                  -- 顧客コード
          ,xwp.sales_outlets_code                   AS sales_outlets_code         -- 問屋帳合先コード
          ,xwp.estimated_type                       AS estimated_type             -- 見積区分
          ,xwp.estimated_no                         AS estimated_no               -- 見積番号
          ,xwp.container_group_code                 AS container_group_code       -- 容器群コード
          ,item.case_qty                            AS case_qty                   -- ケース入数
          ,xwp.item_code                            AS item_code                  -- 商品コード(品目コード)
          ,xwp.market_amt                           AS market_amt                 -- 建値
          ,xwp.selling_discount                     AS selling_discount           -- 売上値引
          ,xwp.normal_store_deliver_amt             AS normal_store_deliver_amt   -- 通常店納
          ,xwp.once_store_deliver_amt               AS once_store_deliver_amt     -- 今回店納
          ,xwp.net_selling_price                    AS net_selling_price          -- NET価格
          ,xwp.coverage_amt                         AS coverage_amt               -- 補填
          ,xwp.wholesale_margin_sum                 AS wholesale_margin_sum       -- 問屋マージン
          ,xwp.expansion_sales_amt                  AS expansion_sales_amt        -- 拡売費
          ,item.list_price                          AS list_price                 -- 定価
          ,xwp.demand_unit_type                     AS demand_unit_type           -- 請求単位
          ,xwp.demand_qty                           AS demand_qty                 -- 請求数量
          ,xwp.demand_unit_price                    AS demand_unit_price          -- 請求単価
          ,xwp.demand_amt                           AS demand_amt                 -- 請求金額(税抜)
          ,xwp.payment_qty                          AS payment_qty                -- 支払数量
          ,xwp.payment_unit_price                   AS payment_unit_price         -- 支払単価
          ,xwp.payment_amt                          AS payment_amt                -- 支払金額(税抜)
          ,xwp.acct_code                            AS acct_code                  -- 勘定科目コード
          ,xwp.sub_acct_code                        AS sub_acct_code              -- 補助科目コード
-- Start 2009/04/21 Ver_1.3 T1_0551 M.Hiruta
--          ,xwp.coverage_amt * payment_qty           AS coverage_amt_sum           -- 補填額
--          ,xwp.wholesale_margin_sum * payment_qty   AS wholesale_margin_amt_sum   -- 問屋マージン額
--          ,xwp.expansion_sales_amt * payment_qty    AS expansion_sales_amt_sum    -- 拡売費額
          ,xwp.backmargin                           AS backmargin                -- 販売手数料
          ,xwp.sales_support_amt                    AS sales_support_amt          -- 販売協賛金
-- End   2009/04/21 Ver_1.3 T1_0551 M.Hiruta
          ,xwp.misc_acct_amt                        AS misc_acct_amt              -- その他科目
    FROM   xxcok_wholesale_payment  xwp
          ,( SELECT msib.segment1              AS item_code
                   ,iimb.attribute11           AS case_qty
                   ,CASE
                      WHEN NVL( TO_DATE( iimb.attribute6, 'YYYY/MM/DD' ), gd_process_date ) > gd_process_date
                      THEN
                        iimb.attribute4
                      ELSE
                        iimb.attribute5
                    END                        AS list_price
             FROM mtl_system_items_b  msib
                 ,ic_item_mst_b       iimb
             WHERE msib.segment1           = iimb.item_no
             AND   msib.organization_id    = gn_organization_id
           )                        item
    WHERE xwp.ap_interface_status   = cv_ap_interface_status
    AND   xwp.info_interface_status = cv_info_if_status_before
    AND   xwp.item_code             = item.item_code(+)
    FOR UPDATE OF xwp.wholesale_payment_id NOWAIT
  ;
  -- ===============================
  -- グローバルTABLE型
  -- ===============================
  -- 連携対象問屋支払情報
  TYPE g_wholesale_info_ttype IS TABLE OF g_wholesale_info_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  -- ===============================
  -- グローバルPL/SQL表
  -- ===============================
  -- 連携対象問屋支払情報
  g_wholesale_info_tab    g_wholesale_info_ttype;
  -- ===============================
  -- 例外
  -- ===============================
  --*** 処理部共通例外(ファイルクローズ処理なし) ***
  global_process_expt         EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
--
  close_file_process_expt     EXCEPTION;    -- 処理部共通例外(ファイルクローズ処理あり)
  no_data_expt                EXCEPTION;    -- データ取得例外
  lock_expt                   EXCEPTION;    -- ロック取得例外
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf    OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    ,ov_retcode   OUT VARCHAR2      -- リターン・コード             --# 固定 #
    ,ov_errmsg    OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name                CONSTANT VARCHAR2(5)  := 'init'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                -- ユーザー・エラー・メッセージ
    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                -- 出力メッセージ
    lb_retcode                 BOOLEAN        DEFAULT TRUE;                -- メッセージ出力関数の戻り値
    lv_organization_code       VARCHAR2(10)   DEFAULT NULL;                -- 在庫組織コード
    lv_nodata_profile          VARCHAR2(30)   DEFAULT NULL;                -- 未取得のプロファイル名
    -- *** ローカル例外 ***
    nodata_profile_expt        EXCEPTION;         -- プロファイル値取得例外
    process_date_expt          EXCEPTION;         -- 業務処理日付取得例外
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 1. メッセージ出力
    -- ===============================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_no_parameter_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.LOG
                    ,lv_out_msg
                    ,2
                  );
    -- ===============================
    -- 2. システム日付を取得
    -- ===============================
    gd_sysdate := SYSDATE;
    -- ===============================
    -- 3. プロファイルを取得
    -- ===============================
    -- (1)会社コード取得
    gv_comp_code := FND_PROFILE.VALUE( cv_comp_code );
    IF( gv_comp_code IS NULL ) THEN
      lv_nodata_profile := cv_comp_code;
      RAISE nodata_profile_expt;
    END IF;
    -- (2)ディレクトリパス取得
    gv_wholesale_dire_path := FND_PROFILE.VALUE( cv_wholesale_dire_path );
    IF( gv_wholesale_dire_path IS NULL ) THEN
      lv_nodata_profile := cv_wholesale_dire_path;
      RAISE nodata_profile_expt;
    END IF;
    -- (3)ファイル名取得
    gv_wholesale_file_name := FND_PROFILE.VALUE( cv_wholesale_file_name );
    IF( gv_wholesale_file_name IS NULL ) THEN
      lv_nodata_profile := cv_wholesale_file_name;
      RAISE nodata_profile_expt;
    END IF;
--【2009/03/19 A.Yano Ver.1.2 追加START】------------------------------------------------------
    -- (4)担当者コード_ダミー値取得
    gv_emp_code_dummy := FND_PROFILE.VALUE( cv_emp_code_dummy );
    IF( gv_emp_code_dummy IS NULL ) THEN
      lv_nodata_profile := cv_emp_code_dummy;
      RAISE nodata_profile_expt;
    END IF;
    -- (5)見積区分_ダミー値取得
    gv_estimated_type_dummy := FND_PROFILE.VALUE( cv_estimated_type_dummy );
    IF( gv_estimated_type_dummy IS NULL ) THEN
      lv_nodata_profile := cv_estimated_type_dummy;
      RAISE nodata_profile_expt;
    END IF;
    -- (6)見積番号_ダミー値取得
    gv_estimated_no_dummy := FND_PROFILE.VALUE( cv_estimated_no_dummy );
    IF( gv_estimated_no_dummy IS NULL ) THEN
      lv_nodata_profile := cv_estimated_no_dummy;
      RAISE nodata_profile_expt;
    END IF;
--【2009/03/19 A.Yano Ver.1.2 追加END  】------------------------------------------------------
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD START
    -- ===============================================
    -- プロファイル取得(販売手数料（問屋）)
    -- ===============================================
    gv_aff3_fee := FND_PROFILE.VALUE( cv_prof_aff3_fee );
    IF ( gv_aff3_fee IS NULL ) THEN
      lv_nodata_profile := cv_prof_aff3_fee;
      RAISE nodata_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(販売協賛金（問屋）)
    -- ===============================================
    gv_aff3_support := FND_PROFILE.VALUE( cv_prof_aff3_support );
    IF ( gv_aff3_support IS NULL ) THEN
      lv_nodata_profile := cv_prof_aff3_support;
      RAISE nodata_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(問屋条件)
    -- ===============================================
    gv_aff4_fee := FND_PROFILE.VALUE( cv_prof_aff4_fee );
    IF ( gv_aff4_fee IS NULL ) THEN
      lv_nodata_profile := cv_prof_aff4_fee;
      RAISE nodata_profile_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(拡売費)
    -- ===============================================
    gv_aff4_support := FND_PROFILE.VALUE( cv_prof_aff4_support );
    IF ( gv_aff4_support IS NULL ) THEN
      lv_nodata_profile := cv_prof_aff4_support;
      RAISE nodata_profile_expt;
    END IF;
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD END
    -- (7)在庫組織コード取得
    lv_organization_code := FND_PROFILE.VALUE( cv_organization_code );
    IF( lv_organization_code IS NULL ) THEN
      lv_nodata_profile := cv_organization_code;
      RAISE nodata_profile_expt;
    END IF;
    -- ===============================
    -- 4. 在庫組織IDを取得
    -- ===============================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                            lv_organization_code
                          );
    IF( gn_organization_id IS NULL ) THEN
      RAISE no_data_expt;
    END IF;
    -- ===============================
    -- 5. 業務処理日付取得
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date();
    IF( gd_process_date IS NULL ) THEN
      RAISE process_date_expt;
    END IF;
    -- ===============================
    -- 6. ファイル名出力
    -- ===============================
    -- ディレクトリパス出力
    gv_dire_path := xxcok_common_pkg.get_directory_path_f(
                      iv_directory_name => gv_wholesale_dire_path
                    );
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_cok
                    ,iv_name         => cv_out_dire_path_msg
                    ,iv_token_name1  => cv_tkn_dire_path_name
                    ,iv_token_value1 => gv_dire_path
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    -- ファイル名出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_cok
                    ,iv_name         => cv_out_filename_msg
                    ,iv_token_name1  => cv_tkn_file_name
                    ,iv_token_value1 => gv_wholesale_file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
--
  EXCEPTION
    -- *** プロファイル取得例外ハンドラ ****
    WHEN nodata_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_profile_err_msg
                      ,iv_token_name1  => cv_tkn_profile_name
                      ,iv_token_value1 => lv_nodata_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 在庫組織ID取得例外ハンドラ ***
    WHEN no_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_org_id_nodata_msg
                      ,iv_token_name1  => cv_tkn_org_code
                      ,iv_token_value1 => lv_organization_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 業務処理日付取得例外ハンドラ ***
    WHEN process_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_process_date_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_file_open
   * Description      : ファイルオープン(A-2)
   ***********************************************************************************/
  PROCEDURE chk_file_open(
     ov_errbuf       OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2      -- リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name           CONSTANT VARCHAR2(20)    := 'chk_file_open'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf             VARCHAR2(5000)  DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode            VARCHAR2(1)     DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg             VARCHAR2(5000)  DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg            VARCHAR2(2000)  DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode            BOOLEAN         DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    lb_exists             BOOLEAN         DEFAULT FALSE;                -- ファイルの有無
    ln_file_length        NUMBER          DEFAULT NULL;                 -- ファイル長さ
    ln_blocksize          BINARY_INTEGER  DEFAULT NULL;                 -- ブロックサイズ
    -- *** ローカル例外 ***
    file_check_expt       EXCEPTION;          -- ファイル存在チェック例外
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 1. ファイルの存在チェック
    -- ===============================
    UTL_FILE.FGETATTR(
       location      =>   gv_wholesale_dire_path
      ,filename      =>   gv_wholesale_file_name
      ,fexists       =>   lb_exists
      ,file_length   =>   ln_file_length
      ,block_size    =>   ln_blocksize
    );
    IF( lb_exists ) THEN
      RAISE file_check_expt;
    END IF;
    -- ===============================
    -- 2. ファイルオープン
    -- ===============================
    g_file_handle := UTL_FILE.FOPEN(
                        gv_wholesale_dire_path
                       ,gv_wholesale_file_name
                       ,cv_write_mode
                       ,cn_max_linesize
                     );
--
  EXCEPTION
    -- *** ファイル存在チェック例外 ****
    WHEN file_check_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_file_chk_err_msg
                      ,iv_token_name1  => cv_tkn_file_name
                      ,iv_token_value1 => gv_wholesale_file_name
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END chk_file_open;
--
  /**********************************************************************************
   * Procedure Name   : get_wholesale_info
   * Description      : 連携対象問屋支払情報取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_wholesale_info(
     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2      --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name     CONSTANT VARCHAR2(20) := 'get_wholesale_info'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal;    -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;                -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;                -- 出力メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;                -- メッセージ出力関数の戻り値
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 連携対象問屋支払情報取得
    -- 問屋支払テーブルロック取得
    -- ===============================
    OPEN  g_wholesale_info_cur;
    FETCH g_wholesale_info_cur BULK COLLECT INTO g_wholesale_info_tab;
    CLOSE g_wholesale_info_cur;
--
  EXCEPTION
    -- *** ロック取得例外ハンドラ ****
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_lock_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_wholesale_info;
--
  /**********************************************************************************
   * Procedure Name   : file_output
   * Description      : フラットファイル作成(A-4)
   ***********************************************************************************/
  PROCEDURE file_output(
     ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2      -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
    ,in_index      IN  NUMBER        -- PL/SQL表インデックス
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name             CONSTANT VARCHAR2(15) := 'file_output'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf               VARCHAR2(5000)              DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode              VARCHAR2(1)                 DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg               VARCHAR2(5000)              DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_out_msg              VARCHAR2(2000)              DEFAULT NULL;              -- 出力メッセージ
    lb_retcode              BOOLEAN                     DEFAULT TRUE;              -- メッセージ出力関数の戻り値
    lv_file_output_info     VARCHAR2(3000)              DEFAULT NULL;              -- ファイル出力する問屋支払情報
    -- ファイル出力データ
    lv_wholesale_payment_id VARCHAR2(20)                                      DEFAULT NULL;  -- 問屋支払ID
    lv_payment_date         VARCHAR2(20)                                      DEFAULT NULL;  -- 支払予定日
    lv_selling_month        xxcok_wholesale_payment.selling_month%TYPE        DEFAULT NULL;  -- 売上対象年月
    lv_base_code            xxcok_wholesale_payment.base_code%TYPE            DEFAULT NULL;  -- 拠点コード
    lv_supplier_code        xxcok_wholesale_payment.supplier_code%TYPE        DEFAULT NULL;  -- 仕入先コード
    lv_emp_code             xxcok_wholesale_payment.emp_code%TYPE             DEFAULT NULL;  -- 担当者コード
    lv_wholesale_code_admin xxcok_wholesale_payment.wholesale_code_admin%TYPE DEFAULT NULL;  -- 問屋管理コード
    lv_oprtn_status_code    xxcok_wholesale_payment.oprtn_status_code%TYPE    DEFAULT NULL;  -- 業態コード
    lv_cust_code            xxcok_wholesale_payment.cust_code%TYPE            DEFAULT NULL;  -- 顧客コード
    lv_sales_outlets_code   xxcok_wholesale_payment.sales_outlets_code%TYPE   DEFAULT NULL;  -- 問屋帳合先コード
    lv_estimated_type       xxcok_wholesale_payment.estimated_type%TYPE       DEFAULT NULL;  -- 見積区分
    lv_estimated_no         xxcok_wholesale_payment.estimated_no%TYPE         DEFAULT NULL;  -- 見積番号
    lv_container_group_code xxcok_wholesale_payment.container_group_code%TYPE DEFAULT NULL;  -- 容器群コード
    lv_case_qty             VARCHAR2(20)                                      DEFAULT NULL;  -- ケース入数
    lv_item_code            xxcok_wholesale_payment.item_code%TYPE            DEFAULT NULL;  -- 商品コード
    lv_market_amt           VARCHAR2(20)                                      DEFAULT NULL;  -- 建値
    lv_selling_discount     VARCHAR2(20)                                      DEFAULT NULL;  -- 売上値引
    lv_normal_dlv_amt       VARCHAR2(20)                                      DEFAULT NULL;  -- 通常店納
    lv_once_dlv_amt         VARCHAR2(20)                                      DEFAULT NULL;  -- 今回店納
    lv_net_selling_price    VARCHAR2(20)                                      DEFAULT NULL;  -- NET価格
    lv_coverage_amt         VARCHAR2(20)                                      DEFAULT NULL;  -- 補填
    lv_wholesale_margin_amt VARCHAR2(20)                                      DEFAULT NULL;  -- 問屋マージン
    lv_expansion_sales_amt  VARCHAR2(20)                                      DEFAULT NULL;  -- 拡売費
    lv_list_price           VARCHAR2(20)                                      DEFAULT NULL;  -- 定価
    lv_demand_unit_type     xxcok_wholesale_payment.demand_unit_type%TYPE     DEFAULT NULL;  -- 請求単位
    lv_demand_qty           VARCHAR2(20)                                      DEFAULT NULL;  -- 請求数量
    lv_demand_unit_price    VARCHAR2(20)                                      DEFAULT NULL;  -- 請求単価
    lv_demand_amt           VARCHAR2(20)                                      DEFAULT NULL;  -- 請求金額(税抜)
    lv_payment_qty          VARCHAR2(20)                                      DEFAULT NULL;  -- 支払数量
    lv_payment_unit_price   VARCHAR2(20)                                      DEFAULT NULL;  -- 支払単価
    lv_payment_amt          VARCHAR2(20)                                      DEFAULT NULL;  -- 支払金額(税抜)
    lv_acct_code            xxcok_wholesale_payment.acct_code%TYPE            DEFAULT NULL;  -- 勘定科目コード
    lv_sub_acct_code        xxcok_wholesale_payment.sub_acct_code%TYPE        DEFAULT NULL;  -- 補助科目コード
    lv_coverage_amt_sum     VARCHAR2(20)                                      DEFAULT NULL;  -- 補填額
    lv_wholesale_margin_sum VARCHAR2(20)                                      DEFAULT NULL;  -- 問屋マージン額
    lv_expansion_sales_sum  VARCHAR2(20)                                      DEFAULT NULL;  -- 拡売費額
    lv_misc_acct_amt        VARCHAR2(20)                                      DEFAULT NULL;  -- その他科目額
    lv_sysdate              VARCHAR2(14)                                      DEFAULT NULL;  -- システム日付
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD START
    ln_fraction_amount       NUMBER         DEFAULT NULL;              -- 端数計算用
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD END
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 変数に代入
    -- ===============================
    lv_wholesale_payment_id := TO_CHAR( g_wholesale_info_tab( in_index ).wholesale_payment_id );     -- 問屋支払ID
    lv_payment_date         :=
      TO_CHAR( g_wholesale_info_tab( in_index ).expect_payment_date, 'YYYYMMDD' );                   -- 支払予定日
    lv_selling_month        := g_wholesale_info_tab( in_index ).selling_month;                       -- 売上対象年月
    lv_base_code            := g_wholesale_info_tab( in_index ).base_code;                           -- 拠点コード
    lv_supplier_code        := g_wholesale_info_tab( in_index ).supplier_code;                       -- 仕入先コード
--【2009/03/19 A.Yano Ver.1.2 START】------------------------------------------------------
--    lv_emp_code             := g_wholesale_info_tab( in_index ).emp_code;                            -- 担当者コード
    lv_emp_code             := NVL( g_wholesale_info_tab( in_index ).emp_code, gv_emp_code_dummy );  -- 担当者コード
--【2009/03/19 A.Yano Ver.1.2 END  】------------------------------------------------------
    lv_wholesale_code_admin := g_wholesale_info_tab( in_index ).wholesale_code_admin;                -- 問屋管理コード
    lv_oprtn_status_code    := g_wholesale_info_tab( in_index ).oprtn_status_code;                   -- 業態コード
    lv_cust_code            := g_wholesale_info_tab( in_index ).cust_code;                           -- 顧客コード
    lv_sales_outlets_code   := g_wholesale_info_tab( in_index ).sales_outlets_code;                  -- 問屋帳合先コード
--【2009/03/19 A.Yano Ver.1.2 START】------------------------------------------------------
--    lv_estimated_type       := g_wholesale_info_tab( in_index ).estimated_type;                      -- 見積区分
--    lv_estimated_no         := g_wholesale_info_tab( in_index ).estimated_no;                        -- 見積番号
    lv_estimated_type       :=
      NVL( g_wholesale_info_tab( in_index ).estimated_type, gv_estimated_type_dummy );               -- 見積区分
    lv_estimated_no         :=
      NVL( g_wholesale_info_tab( in_index ).estimated_no, gv_estimated_no_dummy );                   -- 見積番号
--【2009/03/19 A.Yano Ver.1.2 END  】------------------------------------------------------
    lv_container_group_code := g_wholesale_info_tab( in_index ).container_group_code;                -- 容器群コード
    lv_case_qty             := TO_CHAR( g_wholesale_info_tab( in_index ).case_qty );                 -- ケース入数
    lv_item_code            := g_wholesale_info_tab( in_index ).item_code;                           -- 商品コード
    lv_market_amt           := TO_CHAR( g_wholesale_info_tab( in_index ).market_amt );               -- 建値
    lv_selling_discount     := TO_CHAR( g_wholesale_info_tab( in_index ).selling_discount );         -- 売上値引
    lv_normal_dlv_amt       := TO_CHAR( g_wholesale_info_tab( in_index ).normal_store_deliver_amt ); -- 通常店納
    lv_once_dlv_amt         := TO_CHAR( g_wholesale_info_tab( in_index ).once_store_deliver_amt );   -- 今回店納
    lv_net_selling_price    := TO_CHAR( g_wholesale_info_tab( in_index ).net_selling_price );        -- NET価格
    lv_coverage_amt         := TO_CHAR( g_wholesale_info_tab( in_index ).coverage_amt );             -- 補填
    lv_wholesale_margin_amt := TO_CHAR( g_wholesale_info_tab( in_index ).wholesale_margin_sum );     -- 問屋マージン
    lv_expansion_sales_amt  := TO_CHAR( g_wholesale_info_tab( in_index ).expansion_sales_amt );      -- 拡売費
    lv_list_price           := TO_CHAR( g_wholesale_info_tab( in_index ).list_price );               -- 定価
    lv_demand_unit_type     := g_wholesale_info_tab( in_index ).demand_unit_type;                    -- 請求単位
    lv_demand_qty           := TO_CHAR( g_wholesale_info_tab( in_index ).demand_qty );               -- 請求数量
    lv_demand_unit_price    := TO_CHAR( g_wholesale_info_tab( in_index ).demand_unit_price );        -- 請求単価
    lv_demand_amt           := TO_CHAR( g_wholesale_info_tab( in_index ).demand_amt );               -- 請求金額(税抜)
    lv_payment_qty          := TO_CHAR( g_wholesale_info_tab( in_index ).payment_qty );              -- 支払数量
    lv_payment_unit_price   := TO_CHAR( g_wholesale_info_tab( in_index ).payment_unit_price );       -- 支払単価
    lv_payment_amt          := TO_CHAR( g_wholesale_info_tab( in_index ).payment_amt );              -- 支払金額(税抜)
    lv_acct_code            := g_wholesale_info_tab( in_index ).acct_code;                           -- 勘定科目コード
    lv_sub_acct_code        := g_wholesale_info_tab( in_index ).sub_acct_code;                       -- 補助科目コード
-- Start 2009/04/21 Ver_1.3 T1_0551 M.Hiruta
--    lv_coverage_amt_sum     := TO_CHAR( g_wholesale_info_tab( in_index ).coverage_amt_sum );         -- 補填額
--    lv_wholesale_margin_sum := TO_CHAR( g_wholesale_info_tab( in_index ).wholesale_margin_amt_sum ); -- 問屋マージン額
--    lv_expansion_sales_sum  := TO_CHAR( g_wholesale_info_tab( in_index ).expansion_sales_amt_sum );  -- 拡売費額
--
    -- 補填額
    IF ( ( NVL( g_wholesale_info_tab( in_index ).market_amt , 0 )
             - NVL( g_wholesale_info_tab( in_index ).selling_discount , 0 )
             - NVL( g_wholesale_info_tab( in_index ).normal_store_deliver_amt , 0) <= 0 )
      OR ( g_wholesale_info_tab( in_index ).backmargin IS NULL )
      OR ( g_wholesale_info_tab( in_index ).backmargin <= 0 ) )
    THEN
      lv_coverage_amt_sum := '0';
    ELSE
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR START
--      lv_coverage_amt_sum :=
--        TO_CHAR( ( NVL( g_wholesale_info_tab( in_index ).market_amt , 0 )
--                     - NVL( g_wholesale_info_tab( in_index ).selling_discount , 0 )
--                     - NVL( g_wholesale_info_tab( in_index ).normal_store_deliver_amt , 0) 
--                 ) * NVL( g_wholesale_info_tab( in_index ).payment_qty , 0 ) );
      lv_coverage_amt_sum :=
        TO_CHAR( ROUND( (   NVL( g_wholesale_info_tab( in_index ).market_amt               , 0 )
                          - NVL( g_wholesale_info_tab( in_index ).selling_discount         , 0 )
                          - NVL( g_wholesale_info_tab( in_index ).normal_store_deliver_amt , 0 )
                        ) * NVL( g_wholesale_info_tab( in_index ).payment_qty , 0 )
                 )
        );
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR END
    END IF;
    -- 問屋マージン額
    IF ( g_wholesale_info_tab( in_index ).backmargin >= 0 ) THEN
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR START
--      lv_wholesale_margin_sum :=
--        TO_CHAR( NVL( g_wholesale_info_tab( in_index ).backmargin , 0 )
--                   * NVL( g_wholesale_info_tab( in_index ).payment_qty , 0 ) - TO_NUMBER( lv_coverage_amt_sum ) );
      lv_wholesale_margin_sum :=
        TO_CHAR( ROUND(   NVL( g_wholesale_info_tab( in_index ).backmargin  , 0 )
                        * NVL( g_wholesale_info_tab( in_index ).payment_qty , 0 )
                        - TO_NUMBER( lv_coverage_amt_sum )
                 )
         );
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR END
    ELSE
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR START
--      lv_wholesale_margin_sum :=
--        TO_CHAR( NVL( g_wholesale_info_tab( in_index ).backmargin , 0 )
--                   * NVL( g_wholesale_info_tab( in_index ).payment_qty , 0 ) );
      lv_wholesale_margin_sum :=
        TO_CHAR( ROUND(   NVL( g_wholesale_info_tab( in_index ).backmargin  , 0 )
                        * NVL( g_wholesale_info_tab( in_index ).payment_qty , 0 )
                 )
        );
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR END
    END IF;
    -- 拡売費額
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR START
--    lv_expansion_sales_sum := TO_CHAR( NVL( g_wholesale_info_tab( in_index ).sales_support_amt , 0 )
--                                         * NVL( g_wholesale_info_tab( in_index ).payment_qty , 0 ) );
    lv_expansion_sales_sum := TO_CHAR( ROUND(   NVL( g_wholesale_info_tab( in_index ).sales_support_amt, 0 )
                                              * NVL( g_wholesale_info_tab( in_index ).payment_qty      , 0 )
                                       )
                              );
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR END
-- End   2009/04/21 Ver_1.3 T1_0551 M.Hiruta
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD START

    -- ===============================================
    -- 端数処理
    -- 支払金額=補填+問屋マージン+拡売費を満たさない場合
    -- 問屋マージンにて金額調整を行う
    -- ===============================================
    IF( g_wholesale_info_tab( in_index ).acct_code IS NULL ) THEN
      ln_fraction_amount :=   TO_NUMBER( lv_coverage_amt_sum     )
                            + TO_NUMBER( lv_wholesale_margin_sum )
                            + TO_NUMBER( lv_expansion_sales_sum  );
      IF ( NVL( g_wholesale_info_tab( in_index ).payment_amt
              , g_wholesale_info_tab( in_index ).demand_amt ) != ln_fraction_amount ) THEN
        lv_wholesale_margin_sum := TO_CHAR(   TO_NUMBER( lv_wholesale_margin_sum )
                                            + ( NVL( g_wholesale_info_tab( in_index ).payment_amt
                                                   , g_wholesale_info_tab( in_index ).demand_amt  ) - ln_fraction_amount )
                                   );
      END IF;
    END IF;
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi ADD END
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR START
--    lv_misc_acct_amt        := TO_CHAR( g_wholesale_info_tab( in_index ).misc_acct_amt );            -- その他科目額
    IF( g_wholesale_info_tab( in_index ).acct_code IS NOT NULL ) THEN
      IF (     g_wholesale_info_tab( in_index ).acct_code     = gv_aff3_fee
           AND g_wholesale_info_tab( in_index ).sub_acct_code = gv_aff4_fee
      ) THEN
        lv_wholesale_margin_sum := TO_CHAR( g_wholesale_info_tab( in_index ).misc_acct_amt );
      ELSIF (     g_wholesale_info_tab( in_index ).acct_code     = gv_aff3_support
              AND g_wholesale_info_tab( in_index ).sub_acct_code = gv_aff4_support
      ) THEN
        lv_expansion_sales_sum := TO_CHAR( g_wholesale_info_tab( in_index ).misc_acct_amt );
      ELSE
        lv_misc_acct_amt := TO_CHAR( g_wholesale_info_tab( in_index ).misc_acct_amt );
      END IF;
    ELSE
      lv_misc_acct_amt        := TO_CHAR( g_wholesale_info_tab( in_index ).misc_acct_amt );            -- その他科目額
    END IF;
-- 2009/12/18 Ver.1.4 [E_本稼動_00530] SCS K.Yamaguchi REPAIR END
    lv_sysdate              := TO_CHAR( gd_sysdate, 'YYYYMMDDHH24MISS' );                            -- システム日付
    -- ===============================
    -- 出力データを変数に格納
    -- ===============================
    lv_file_output_info :=
                                            lv_wholesale_payment_id                          -- 問屋支払ID
      || cv_comma || cv_double_quotation || gv_comp_code            || cv_double_quotation   -- 会社コード
      || cv_comma ||                        lv_payment_date                                  -- 支払予定日
      || cv_comma ||                        lv_selling_month                                 -- 売上対象年月
      || cv_comma || cv_double_quotation || lv_base_code            || cv_double_quotation   -- 拠点コード
      || cv_comma || cv_double_quotation || lv_supplier_code        || cv_double_quotation   -- 仕入先コード
      || cv_comma || cv_double_quotation || lv_emp_code             || cv_double_quotation   -- 担当者コード
      || cv_comma || cv_double_quotation || lv_wholesale_code_admin || cv_double_quotation   -- 問屋管理コード
      || cv_comma || cv_double_quotation || lv_oprtn_status_code    || cv_double_quotation   -- 業態コード
      || cv_comma || cv_double_quotation || lv_cust_code            || cv_double_quotation   -- 顧客コード
      || cv_comma || cv_double_quotation || lv_sales_outlets_code   || cv_double_quotation   -- 問屋帳合先コード
      || cv_comma || cv_double_quotation || lv_estimated_type       || cv_double_quotation   -- 見積区分
      || cv_comma || cv_double_quotation || lv_estimated_no         || cv_double_quotation   -- 見積番号
      || cv_comma || cv_double_quotation || lv_container_group_code || cv_double_quotation   -- 容器群コード
      || cv_comma ||                        lv_case_qty                                      -- ケース入数
      || cv_comma || cv_double_quotation || lv_item_code            || cv_double_quotation   -- 商品コード
      || cv_comma ||                        lv_market_amt                                    -- 建値
      || cv_comma ||                        lv_selling_discount                              -- 売上値引
      || cv_comma ||                        lv_normal_dlv_amt                                -- 通常店納
      || cv_comma ||                        lv_once_dlv_amt                                  -- 今回店納
      || cv_comma ||                        lv_net_selling_price                             -- NET価格
      || cv_comma ||                        lv_coverage_amt                                  -- 補填
      || cv_comma ||                        lv_wholesale_margin_amt                          -- 問屋マージン
      || cv_comma ||                        lv_expansion_sales_amt                           -- 拡売費
      || cv_comma ||                        lv_list_price                                    -- 定価
      || cv_comma || cv_double_quotation || lv_demand_unit_type     || cv_double_quotation   -- 請求単位
      || cv_comma ||                        lv_demand_qty                                    -- 請求数量
      || cv_comma ||                        lv_demand_unit_price                             -- 請求単価
      || cv_comma ||                        lv_demand_amt                                    -- 請求金額(税抜)
      || cv_comma ||                        lv_payment_qty                                   -- 支払数量
      || cv_comma ||                        lv_payment_unit_price                            -- 支払単価
      || cv_comma ||                        lv_payment_amt                                   -- 支払金額(税抜)
      || cv_comma || cv_double_quotation || lv_acct_code            || cv_double_quotation   -- 勘定科目コード
      || cv_comma || cv_double_quotation || lv_sub_acct_code        || cv_double_quotation   -- 補助科目コード
      || cv_comma ||                        lv_coverage_amt_sum                              -- 補填額
      || cv_comma ||                        lv_wholesale_margin_sum                          -- 問屋マージン額
      || cv_comma ||                        lv_expansion_sales_sum                           -- 拡売費額
      || cv_comma ||                        lv_misc_acct_amt                                 -- その他科目額
      || cv_comma ||                        lv_sysdate                                       -- システム日付
    ;
    -- ===============================
    -- ファイル出力
    -- ===============================
    UTL_FILE.PUT_LINE(
       file      =>   g_file_handle
      ,buffer    =>   lv_file_output_info
    );
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END file_output;
--
  /**********************************************************************************
   * Procedure Name   : update_status
   * Description      : 出力済データステータス更新(A-5)
   ***********************************************************************************/
  PROCEDURE update_status(
     ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2      -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
    ,in_index      IN  NUMBER        -- PL/SQL表インデックス
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(15) := 'update_status'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
    -- *** ローカル例外 ***
    local_update_expt         EXCEPTION;          -- 更新処理例外
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    BEGIN
--
      -- ===============================
      -- 情報系システム連携ステータス更新
      -- ===============================
      UPDATE xxcok_wholesale_payment
      SET info_interface_status   = cv_info_if_status_after     -- 情報系システム連携ステータス
         ,last_updated_by         = cn_last_updated_by          -- 最終更新者
         ,last_update_date        = SYSDATE                     -- 最終更新日
         ,last_update_login       = cn_last_update_login        -- 最終更新ログイン
         ,request_id              = cn_request_id               -- 要求ID
         ,program_application_id  = cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
         ,program_id              = cn_program_id               -- コンカレント・プログラムID
         ,program_update_date     = SYSDATE                     -- プログラム更新日
      WHERE wholesale_payment_id  = g_wholesale_info_tab( in_index ).wholesale_payment_id
      ;
--
    EXCEPTION
      -- *** 更新処理例外ハンドラ ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_update_err_msg
                        ,iv_token_name1  => cv_tkn_wholesale_id
                        ,iv_token_value1 => TO_CHAR( g_wholesale_info_tab( in_index ).wholesale_payment_id )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_status;
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : ファイルクローズ(A-6)
   ***********************************************************************************/
  PROCEDURE file_close(
     ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2      -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name     CONSTANT VARCHAR2(15) := 'file_close'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf       VARCHAR2(5000)   DEFAULT NULL;                   -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)      DEFAULT cv_status_normal;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)   DEFAULT NULL;                   -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000)   DEFAULT NULL;                   -- 出力メッセージ
    lb_retcode      BOOLEAN          DEFAULT TRUE;                   -- メッセージ出力関数の戻り値
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- ファイルクローズ
    -- ===============================
    IF( UTL_FILE.IS_OPEN( g_file_handle ) ) THEN
      UTL_FILE.FCLOSE(
        file   =>   g_file_handle
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name               CONSTANT VARCHAR2(10) := 'submain'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000)  DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)     DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000)  DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000)  DEFAULT NULL;                 -- 出力メッセージ
    lb_retcode                BOOLEAN         DEFAULT TRUE;                 -- メッセージ出力関数の戻り値
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- ファイルオープン(A-2)
    -- ===============================
    chk_file_open(
       ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- 連携対象問屋支払情報取得(A-3)
    -- ===============================
    get_wholesale_info(
       ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE close_file_process_expt;
    END IF;
    -- 対象件数
    gn_target_cnt := g_wholesale_info_tab.COUNT;
    IF( gn_target_cnt > 0 ) THEN
      << wholesale_info_loop >>
      FOR ln_index IN g_wholesale_info_tab.FIRST..g_wholesale_info_tab.LAST LOOP
        -- ===============================
        -- フラットファイル作成(A-4)
        -- ===============================
        file_output(
           ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
          ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
          ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
          ,in_index      =>    ln_index       -- PL/SQL表インデックス
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE close_file_process_expt;
        END IF;
        -- ===============================
        -- 出力済データステータス更新(A-5)
        -- ===============================
        update_status(
           ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
          ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
          ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
          ,in_index      =>    ln_index       -- PL/SQL表インデックス
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE close_file_process_expt;
        END IF;
        -- 正常件数
        gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP wholesale_info_loop;
    END IF;
    -- ===============================
    -- ファイルクローズ(A-6)
    -- ===============================
    file_close(
       ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ(ファイルクローズ) ***
    WHEN close_file_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
      -- ファイルクローズ
      file_close(
         ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
        ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
        ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
      -- ファイルクローズ
      file_close(
         ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
        ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
        ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
      -- ファイルクローズ
      file_close(
         ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
        ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
        ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT VARCHAR2       --   エラー・メッセージ  --# 固定 #
    ,retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name        CONSTANT VARCHAR2(5)   := 'main';             -- プログラム名
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- *** ローカル変数 ***
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;               -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)     DEFAULT cv_status_normal;   -- リターン・コード
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;               -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100)   DEFAULT NULL;               -- 終了メッセージ
    lv_out_msg         VARCHAR2(2000)  DEFAULT NULL;               -- 出力メッセージ
    lb_retcode         BOOLEAN         DEFAULT TRUE;               -- メッセージ出力関数の戻り値
--
  BEGIN
--
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf     =>    lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode    =>    lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg     =>    lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_errmsg  --ユーザー・エラー・メッセージ
                      ,1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.LOG
                      ,lv_errbuf  --エラーメッセージ
                      ,1
                    );
    END IF;
    -- 異常終了の場合の件数セット
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --対象件数出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
--
    --成功件数出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
--
    --エラー件数出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
--
    --終了メッセージ
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK021A04C;
/
