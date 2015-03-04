CREATE OR REPLACE PACKAGE BODY XXCOK014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A03C(body)
 * Description      : 販手残高計算処理
 * MD.050           : 販売手数料（自販機）の支払予定額（未払残高）を計算 MD050_COK_014_A03
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  update_xcbs            販手販協連携結果の更新（金額確定分）(A-10)
 *  insert_xbb             販手残高の登録(A-9)
 *  calc_loop              販手残高計算ループ(A-8)
 *  delete_xbb             未確定販手残高データの削除(A-7)
 *  update_xbb             支払保留の解除(A-5)
 *  get_calc_period        計算開始日・終了日の取得(A-4)
 *  reserve_loop           保留ループ(A-3)
 *  purge_xbb              販手残高保持期間外データの削除(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   A.Yano           新規作成
 *  2009/02/17    1.1   T.Abe            [障害COK_041] 販手残高計算データの取得件数が0件の場合、正常終了するように修正
 *  2009/03/25    1.2   S.Kayahara       最終行にスラッシュ追加
 *  2009/05/28    1.3   M.Hiruta         [障害T1_1138] 販手残高保留情報の初期化で正しく保留情報を初期化できるよう変更
 *  2009/12/12    1.4   K.Yamaguchi      [E_本稼動_00360] 未確定データで削除されないデータが残るため再作成
 *  2012/07/09    1.5   K.Onotsuka       [E_本稼動_08365] 販手残高テーブルに項目追加(処理区分)※初期値：0
 *  2015/03/04    1.6   K.Kiriu          [E_本稼動_12937] PT対応(ヒント句追加)
 *
 *****************************************************************************************/
  --==================================================
  -- グローバル定数
  --==================================================
  -- パッケージ名
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK014A03C';
  -- アプリケーション短縮名
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  cv_appl_short_name_gl            CONSTANT VARCHAR2(10)    := 'SQLGL';
  cv_appl_short_name_ar            CONSTANT VARCHAR2(10)    := 'AR';
  -- ステータス・コード
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- 言語
  cv_lang                          CONSTANT VARCHAR2(50)    := USERENV( 'LANG' );
  -- メッセージコード
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- 対象件数
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- 成功件数
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- エラー件数
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- 正常終了
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- エラー終了全ロールバック
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00022                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00022';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00051                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00051';
  cv_msg_cok_10296                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10296';
  cv_msg_cok_10298                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10298';
  cv_msg_cok_10301                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10301';
  cv_msg_cok_10306                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10306';
  cv_msg_cok_10454                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10454';
  cv_msg_cok_10455                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10455';
  -- トークン
  cv_tkn_business_date             CONSTANT VARCHAR2(30)    := 'BUSINESS_DATE';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_close_date                CONSTANT VARCHAR2(30)    := 'CLOSE_DATE';
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_cust_code                 CONSTANT VARCHAR2(30)    := 'CUST_CODE';
  -- セパレータ
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- プロファイル・オプション名
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_FROM';     -- XXCOK:販手販協計算処理期間（From）
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_TO';       -- XXCOK:販手販協計算処理期間（To）
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'XXCOK1_SALES_RETENTION_PERIOD';     -- XXCOK:販手販協情報保持期間
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_DEFAULT_TERM_NAME';          -- 支払条件_デフォルト
  -- 共通関数メッセージ出力区分
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- 書式フォーマット
  cv_format_fxrrrrmmdd             CONSTANT VARCHAR2(50)    := 'FXRRRR/MM/DD';
  -- 条件別販手販協テーブル連携ステータス
  cv_xcbs_if_status_no             CONSTANT VARCHAR2(1)     := '0'; -- 未処理
  cv_xcbs_if_status_yes            CONSTANT VARCHAR2(1)     := '1'; -- 処理済
  cv_xcbs_if_status_off            CONSTANT VARCHAR2(1)     := '2'; -- 不要
  -- 販手残高テーブル連携ステータス
  cv_xbb_if_status_no              CONSTANT VARCHAR2(1)     := '0'; -- 未処理
  -- 支払月
  cv_month_type1                   CONSTANT VARCHAR2(2)     := '40'; -- 当月
  cv_month_type2                   CONSTANT VARCHAR2(2)     := '50'; -- 翌月
  -- サイト
  cv_site_type1                    CONSTANT VARCHAR2(2)     := '00'; -- 当月
  cv_site_type2                    CONSTANT VARCHAR2(2)     := '01'; -- 翌月
  -- 契約管理ステータス
  cv_xcm_status_result             CONSTANT VARCHAR2(1)     := '1'; -- 確定
  -- 条件別販手販協テーブル金額確定ステータス
  cv_xcbs_temp                     CONSTANT VARCHAR2(1)     := '0'; -- 未確定
  cv_xcbs_fix                      CONSTANT VARCHAR2(1)     := '1'; -- 確定
  -- 営業日取得関数・処理区分
  cn_proc_type_before              CONSTANT NUMBER          := 1;  -- 前
  cn_proc_type_after               CONSTANT NUMBER          := 2;  -- 後
  -- 販手残高テーブル・保留フラグ
  cv_reserve                       CONSTANT VARCHAR2(1)     := 'Y'; -- 保留
-- 2012/07/06 Ver.1.5 [E_本稼動_08365] SCSK K.Onotsuka ADD START
  cv_proc_type_default             CONSTANT VARCHAR2(1)     := '0'; -- 処理区分デフォルト値(登録用)
-- 2012/07/06 Ver.1.5 [E_本稼動_08365] SCSK K.Onotsuka ADD END
  --==================================================
  -- グローバル変数
  --==================================================
  -- カウンタ
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- 対象件数
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- 正常件数
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- 異常件数
  gn_skip_cnt                      NUMBER        DEFAULT 0;      -- スキップ件数
  gn_contract_err_cnt              NUMBER        DEFAULT 0;      -- 販手条件エラー件数
  -- 入力パラメータ
  gv_param_process_date            VARCHAR2(10)  DEFAULT NULL;   -- 業務処理日付
  -- 初期処理取得値
  gd_process_date                  DATE          DEFAULT NULL;   -- 業務処理日付
  gn_bm_support_period_from        NUMBER        DEFAULT NULL;   -- XXCOK:販手販協計算処理期間（From）
  gn_bm_support_period_to          NUMBER        DEFAULT NULL;   -- XXCOK:販手販協計算処理期間（To）
  gn_sales_retention_period        NUMBER        DEFAULT NULL;   -- XXCOK:販手販協情報保持期間
  gv_default_term_name             VARCHAR2(8)   DEFAULT NULL;   -- 支払条件_デフォルト
  --==================================================
  -- グローバルコレクション
  --==================================================
  -- 保留情報
  TYPE reserve_data_rtype          IS RECORD (
    cust_code       xxcok_backmargin_balance.cust_code%TYPE
  , supplier_code   xxcok_backmargin_balance.supplier_code%TYPE
  );
  TYPE reserve_data_ttype          IS TABLE OF reserve_data_rtype INDEX BY BINARY_INTEGER;
  reserve_data_tab                 reserve_data_ttype;
  --==================================================
  -- 共通例外
  --==================================================
  --*** 処理部共通例外 ***
  global_process_expt              EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                  EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ロック取得エラー ***
  resource_busy_expt               EXCEPTION;
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
  --==================================================
  -- グローバル例外
  --==================================================
  --*** エラー終了 ***
  error_proc_expt                  EXCEPTION;
  --*** 警告スキップ ***
  warning_skip_expt                EXCEPTION;
--
  --==================================================
  -- グローバルカーソル
  --==================================================
  -- 保留情報
  CURSOR reserve_cur
  IS
    SELECT xbb.cust_code                AS cust_code
         , xbb.supplier_code            AS supplier_code
         , ( SELECT ( CASE
                        WHEN (    ( xcm.close_day_code       IS NULL )
                               OR ( xcm.transfer_day_code    IS NULL )
                               OR ( xcm.transfer_month_code  IS NULL )
                             )
                        THEN
                          gv_default_term_name
                        ELSE
                             xcm.close_day_code
                          || '_'
                          || xcm.transfer_day_code
                          || '_'
                          || ( CASE
                                 WHEN xcm.transfer_month_code = cv_month_type1 THEN
                                   cv_site_type1
                                 ELSE
                                   cv_site_type2
                               END
                             )
                      END
                    )
             FROM xxcso_contract_managements  xcm
             WHERE xcm.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                                  FROM xxcso_contract_managements  xcm2
                                                     , hz_cust_accounts            hca
                                                  WHERE xcm2.install_account_id = hca.cust_account_id
                                                    AND xcm2.status             = cv_xcm_status_result
                                                    AND hca.account_number      = xbb.cust_code
                                                )
           )                            AS term_name
    FROM ( SELECT /*+
                    INDEX( xbb XXCOK_BACKMARGIN_BALANCE_N03 )
                  */
                  DISTINCT
                  xbb.cust_code
                , xbb.supplier_code
           FROM xxcok_backmargin_balance xbb
           WHERE xbb.resv_flag   = cv_reserve
         )                xbb
  ;
  -- 販手販協情報
  CURSOR xcbs_data_cur
  IS
    SELECT xcbs.base_code                            AS base_code           -- 拠点コード
         , xcbs.supplier_code                        AS supplier_code       -- 仕入先コード
         , xcbs.supplier_site_code                   AS supplier_site_code  -- 仕入先サイトコード
         , xcbs.delivery_cust_code                   AS delivery_cust_code  -- 顧客コード(納品先)
         , xcbs.closing_date                         AS closing_date        -- 締め日
         , xcbs.expect_payment_date                  AS expect_payment_date -- 支払予定日
         , xcbs.tax_code                             AS tax_code            -- 税金コード
         , xcbs.amt_fix_status                       AS amt_fix_status      -- 金額確定ステータス
         , SUM( xcbs.selling_amt_tax )               AS selling_amt_tax     -- 売上金額（税込）
         , SUM( NVL( xcbs.cond_bm_amt_no_tax , 0 ) ) AS cond_bm_amt         -- 条件別手数料額（税抜）
         , SUM( NVL( xcbs.cond_tax_amt       , 0 ) ) AS cond_tax_amt        -- 条件別消費税額
         , SUM( NVL( xcbs.electric_amt_no_tax, 0 ) ) AS electric_amt        -- 電気料(税抜)
         , SUM( NVL( xcbs.electric_tax_amt   , 0 ) ) AS electric_tax_amt    -- 電気料消費税額
    FROM xxcok_cond_bm_support xcbs
    WHERE xcbs.bm_interface_status = cv_xcbs_if_status_no
    GROUP BY xcbs.base_code
           , xcbs.supplier_code
           , xcbs.supplier_site_code
           , xcbs.delivery_cust_code
           , xcbs.closing_date
           , xcbs.expect_payment_date
           , xcbs.tax_code
           , xcbs.amt_fix_status
  ;
--
  /**********************************************************************************
   * Procedure Name   : update_xcbs
   * Description      : 販手販協連携結果の更新（金額確定分）(A-10)
   ***********************************************************************************/
  PROCEDURE update_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_xcbs_data_rec                IN  xcbs_data_cur%ROWTYPE        -- 販手販協情報レコード
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xcbs';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xcbs_update_lock_cur
    IS
-- 2015/03/04 Ver.1.6 [E_本稼動_12937] SCSK K.Kiriu MOD START
--      SELECT xcbs.cond_bm_support_id    AS cond_bm_support_id           -- 条件別販手販協ID
      SELECT /*+ INDEX( xcbs XXCOK_COND_BM_SUPPORT_N04 ) */
             xcbs.cond_bm_support_id    AS cond_bm_support_id           -- 条件別販手販協ID
-- 2015/03/04 Ver.1.6 [E_本稼動_12937] SCSK K.Kiriu MOD END
      FROM xxcok_cond_bm_support   xcbs               -- 条件別販手販協テーブル
      WHERE xcbs.base_code            = i_xcbs_data_rec.base_code
        AND xcbs.supplier_code        = i_xcbs_data_rec.supplier_code
        AND xcbs.supplier_site_code   = i_xcbs_data_rec.supplier_site_code
        AND xcbs.delivery_cust_code   = i_xcbs_data_rec.delivery_cust_code
        AND xcbs.closing_date         = i_xcbs_data_rec.closing_date
        AND xcbs.expect_payment_date  = i_xcbs_data_rec.expect_payment_date
        AND xcbs.bm_interface_status  = cv_xcbs_if_status_no
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 条件別販手販協更新ループ
    --==================================================
    << xcbs_update_lock_loop >>
    FOR xcbs_update_lock_rec IN xcbs_update_lock_cur LOOP
      --==================================================
      -- 条件別販手販協テーブル更新
      --==================================================
      UPDATE xxcok_cond_bm_support      xcbs
      SET xcbs.bm_interface_status      = cv_xcbs_if_status_yes    -- 連携ステータス（販手残高）
        , xcbs.bm_interface_date        = gd_process_date          -- 連携日（販手残高）
        , xcbs.last_updated_by          = cn_last_updated_by
        , xcbs.last_update_date         = SYSDATE
        , xcbs.last_update_login        = cn_last_update_login
        , xcbs.request_id               = cn_request_id
        , xcbs.program_application_id   = cn_program_application_id
        , xcbs.program_id               = cn_program_id
        , xcbs.program_update_date      = SYSDATE
      WHERE xcbs.cond_bm_support_id = xcbs_update_lock_rec.cond_bm_support_id
      ;
    END LOOP xcbs_update_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : insert_xbb
   * Description      : 販手残高の登録(A-9)
   ***********************************************************************************/
  PROCEDURE insert_xbb(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_xcbs_data_rec                IN  xcbs_data_cur%ROWTYPE
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xbb';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lt_resv_flag                   xxcok_backmargin_balance.resv_flag%TYPE DEFAULT NULL; -- 保留フラグ
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 保留済チェック
    --==================================================
    lt_resv_flag := NULL;
    << reserve_check_loop >>
    FOR i IN 1 .. reserve_data_tab.COUNT LOOP
      IF(     ( i_xcbs_data_rec.delivery_cust_code = reserve_data_tab(i).cust_code     )
          AND ( i_xcbs_data_rec.supplier_code      = reserve_data_tab(i).supplier_code )
      ) THEN
        lt_resv_flag := cv_reserve;
        EXIT reserve_check_loop;
      END IF;
    END LOOP reserve_check_loop;
    --==================================================
    -- 販手残高テーブル登録
    --==================================================
    INSERT INTO xxcok_backmargin_balance(
      bm_balance_id                -- 販手残高ID
    , base_code                    -- 拠点コード
    , supplier_code                -- 仕入先コード
    , supplier_site_code           -- 仕入先サイトコード
    , cust_code                    -- 顧客コード
    , closing_date                 -- 締め日
    , selling_amt_tax              -- 販売金額（税込）
    , backmargin                   -- 販売手数料
    , backmargin_tax               -- 販売手数料（消費税額）
    , electric_amt                 -- 電気料
    , electric_amt_tax             -- 電気料（消費税額）
    , tax_code                     -- 税金コード
    , expect_payment_date          -- 支払予定日
    , expect_payment_amt_tax       -- 支払予定額（税込）
    , payment_amt_tax              -- 支払額（税込）
    , resv_flag                    -- 保留フラグ
    , return_flag                  -- 組み戻しフラグ
    , publication_date             -- 案内書発効日
    , fb_interface_status          -- 連携ステータス（本振用FB）
    , fb_interface_date            -- 連携日（本振用FB）
    , edi_interface_status         -- 連携ステータス（EDI支払案内書）
    , edi_interface_date           -- 連携日（EDI支払案内書）
    , gl_interface_status          -- 連携ステータス（GL）
    , gl_interface_date            -- 連携日（GL）
    , amt_fix_status               -- 金額確定ステータス
-- 2012/07/04 Ver.1.5 [E_本稼動_08365] SCSK K.Onotsuka ADD START
    , proc_type                    -- 処理区分
-- 2012/07/04 Ver.1.5 [E_本稼動_08365] SCSK K.Onotsuka ADD END
    -- WHOカラム
    , created_by                   -- 作成者
    , creation_date                -- 作成日
    , last_updated_by              -- 最終更新者
    , last_update_date             -- 最終更新日
    , last_update_login            -- 最終更新ログイン
    , request_id                   -- 要求ID
    , program_application_id       -- コンカレント・プログラム・アプリケーションID
    , program_id                   -- コンカレント・プログラムID
    , program_update_date          -- プログラム更新日
    )
    VALUES (
      xxcok_backmargin_balance_s01.NEXTVAL   -- bm_balance_id
    , i_xcbs_data_rec.base_code              -- base_code
    , i_xcbs_data_rec.supplier_code          -- supplier_code
    , i_xcbs_data_rec.supplier_site_code     -- supplier_site_code
    , i_xcbs_data_rec.delivery_cust_code     -- cust_code
    , i_xcbs_data_rec.closing_date           -- closing_date
    , i_xcbs_data_rec.selling_amt_tax        -- selling_amt_tax
    , i_xcbs_data_rec.cond_bm_amt            -- backmargin
    , i_xcbs_data_rec.cond_tax_amt           -- backmargin_tax
    , i_xcbs_data_rec.electric_amt           -- electric_amt
    , i_xcbs_data_rec.electric_tax_amt       -- electric_amt_tax
    , i_xcbs_data_rec.tax_code               -- tax_code
    , i_xcbs_data_rec.expect_payment_date    -- expect_payment_date
    , i_xcbs_data_rec.cond_bm_amt
    + i_xcbs_data_rec.cond_tax_amt
    + i_xcbs_data_rec.electric_amt
    + i_xcbs_data_rec.electric_tax_amt       -- expect_payment_amt_tax
    , 0                                      -- payment_amt_tax
    , lt_resv_flag                           -- resv_flag
    , NULL                                   -- return_flag
    , NULL                                   -- publication_date
    , cv_xbb_if_status_no                    -- fb_interface_status
    , NULL                                   -- fb_interface_date
    , cv_xbb_if_status_no                    -- edi_interface_status
    , NULL                                   -- edi_interface_date
    , cv_xbb_if_status_no                    -- gl_interface_status
    , NULL                                   -- gl_interface_date
    , i_xcbs_data_rec.amt_fix_status         -- amt_fix_status
-- 2012/07/06 Ver.1.5 [E_本稼動_08365] SCSK K.Onotsuka ADD START
    , cv_proc_type_default                   -- proc_type
-- 2012/07/06 Ver.1.5 [E_本稼動_08365] SCSK K.Onotsuka ADD END
    -- WHOカラム
    , cn_created_by                          -- created_by
    , SYSDATE                                -- creation_date
    , cn_last_updated_by                     -- last_updated_by
    , SYSDATE                                -- last_update_date
    , cn_last_update_login                   -- last_update_login
    , cn_request_id                          -- request_id
    , cn_program_application_id              -- program_application_id
    , cn_program_id                          -- program_id
    , SYSDATE                                -- program_update_date
    );
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xbb;
--
  /**********************************************************************************
   * Procedure Name   : calc_loop
   * Description      : 販手残高計算ループ(A-8)
   **********************************************************************************/
  PROCEDURE calc_loop(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'calc_loop';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 販手販協計算結果の取得(A-8)
    --==================================================
    << main_loop >>
    FOR xcbs_data_rec IN xcbs_data_cur LOOP
      --==================================================
      -- 対象件数カウント
      --==================================================
      gn_target_cnt := gn_target_cnt + 1;
      --==================================================
      -- 販手残高の登録(A-9)
      --==================================================
      insert_xbb(
        ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
      , ov_retcode                  => lv_retcode                 -- リターン・コード
      , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
      , i_xcbs_data_rec             => xcbs_data_rec              -- 販手販協情報レコード
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- 販手販協連携結果の更新（金額確定分）(A-10)
      --==================================================
      IF( xcbs_data_rec.amt_fix_status = cv_xcbs_fix ) THEN
        update_xcbs(
          ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
        , ov_retcode                  => lv_retcode                 -- リターン・コード
        , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
        , i_xcbs_data_rec             => xcbs_data_rec              -- 販手販協情報レコード
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        END IF;
      END IF;
      --==================================================
      -- 正常件数カウント
      --==================================================
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP main_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END calc_loop;
--
  /**********************************************************************************
   * Procedure Name   : delete_xbb
   * Description      : 未確定販手残高データの削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xbb(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xbb';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xbb_delete_lock_cur
    IS
      SELECT xbb.bm_balance_id          AS bm_balance_id  -- 販手残高ID
      FROM xxcok_backmargin_balance     xbb               -- 条件別販手販協テーブル
      WHERE xbb.amt_fix_status    = cv_xcbs_temp -- 未確定
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 販手残高削除ループ
    --==================================================
    << xbb_delete_lock_loop >>
    FOR xbb_delete_lock_rec IN xbb_delete_lock_cur LOOP
      --==================================================
      -- 条件別販手販協データ削除
      --==================================================
      DELETE
      FROM xxcok_backmargin_balance     xbb
      WHERE xbb.bm_balance_id = xbb_delete_lock_rec.bm_balance_id
      ;
    END LOOP xbb_delete_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10301
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END delete_xbb;
--
  /**********************************************************************************
   * Procedure Name   : update_xbb
   * Description      : 支払保留の解除(A-5)
   ***********************************************************************************/
  PROCEDURE update_xbb(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_reserve_rec                  IN  reserve_cur%ROWTYPE        -- 保留情報レコード
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xbb';      -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xbb_update_lock_cur
    IS
      SELECT xbb.bm_balance_id          AS bm_balance_id              -- 販手残高ID
      FROM xxcok_backmargin_balance     xbb                -- 販手残高テーブル
      WHERE xbb.cust_code               = i_reserve_rec.cust_code
        AND xbb.resv_flag               = cv_reserve
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 販手残高更新ループ
    --==================================================
    << xbb_update_lock_loop >>
    FOR xbb_update_lock_rec IN xbb_update_lock_cur LOOP
      --==================================================
      -- 販手残高テーブル更新
      --==================================================
      UPDATE xxcok_backmargin_balance   xbb
      SET xbb.resv_flag              = NULL
        , xbb.last_updated_by        = cn_last_updated_by
        , xbb.last_update_date       = SYSDATE
        , xbb.last_update_login      = cn_last_update_login
        , xbb.request_id             = cn_request_id
        , xbb.program_application_id = cn_program_application_id
        , xbb.program_id             = cn_program_id
        , xbb.program_update_date    = SYSDATE
      WHERE xbb.bm_balance_id        = xbb_update_lock_rec.bm_balance_id
      ;
    END LOOP xbb_update_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10298
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xbb;
--
  /**********************************************************************************
   * Procedure Name   : get_calc_period
   * Description      : 計算開始日・終了日の取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_calc_period(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_reserve_rec                  IN  reserve_cur%ROWTYPE        -- 保留情報レコード
  , od_start_date                  OUT DATE                       -- 計算開始日
  , od_end_date                    OUT DATE                       -- 計算終了日
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_calc_period';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ld_tmp_start_date              DATE           DEFAULT NULL;                 -- 計算開始日（仮）
    ld_close_date                  DATE           DEFAULT NULL;                 -- 締め日
    ld_pay_date                    DATE           DEFAULT NULL;                 -- 支払日
    ld_start_date                  DATE           DEFAULT NULL;                 -- 計算開始日
    ld_end_date                    DATE           DEFAULT NULL;                 -- 計算終了日
    --==================================================
    -- ローカル例外
    --==================================================
    skip_proc_expt                 EXCEPTION; -- 計算対象外スキップ
    get_close_date_expt            EXCEPTION; -- 締め・支払日取得関数エラー
    get_operating_day_expt         EXCEPTION; -- 営業日取得関数エラー
    get_acctg_calendar_expt        EXCEPTION; -- 会計カレンダ取得関数エラー
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 条件別販手販協計算開始日(仮)取得
    --==================================================
    ld_tmp_start_date :=
      xxcok_common_pkg.get_operating_day_f(
        id_proc_date             => gd_process_date                             -- IN DATE   処理日
      , in_days                  => -1 * gn_bm_support_period_to                -- IN NUMBER 日数
      , in_proc_type             => cn_proc_type_before                         -- IN NUMBER 処理区分
      );
    IF( ld_tmp_start_date IS NULL ) THEN
      RAISE get_operating_day_expt;
    END IF;
    --==================================================
    -- 締め支払日取得
    --==================================================
    xxcok_common_pkg.get_close_date_p(
      ov_errbuf                  => lv_errbuf                                   -- OUT VARCHAR2          ログに出力するエラー・メッセージ
    , ov_retcode                 => lv_retcode                                  -- OUT VARCHAR2          リターンコード
    , ov_errmsg                  => lv_errmsg                                   -- OUT VARCHAR2          ユーザーに見せるエラー・メッセージ
    , id_proc_date               => ld_tmp_start_date                           -- IN  DATE DEFAULT NULL 処理日(対象日)
    , iv_pay_cond                => i_reserve_rec.term_name                     -- IN  VARCHAR2          支払条件(IN)
    , od_close_date              => ld_close_date                               -- OUT DATE              締め日(OUT)
    , od_pay_date                => ld_pay_date                                 -- OUT DATE              支払日(OUT)
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE get_close_date_expt;
    END IF;
    --==================================================
    -- 計算開始日取得
    --==================================================
    ld_start_date :=
      xxcok_common_pkg.get_operating_day_f(
        id_proc_date             => ld_close_date                               -- IN DATE   処理日
      , in_days                  => gn_bm_support_period_from                   -- IN NUMBER 日数
      , in_proc_type             => cn_proc_type_before                         -- IN NUMBER 処理区分
      );
    IF( ld_start_date IS NULL ) THEN
      RAISE get_operating_day_expt;
    END IF;
    --==================================================
    -- 計算終了日取得
    --==================================================
    ld_end_date :=
      xxcok_common_pkg.get_operating_day_f(
        id_proc_date             => ld_close_date                               -- IN DATE   処理日
      , in_days                  => gn_bm_support_period_to                     -- IN NUMBER 日数
      , in_proc_type             => cn_proc_type_before                         -- IN NUMBER 処理区分
      );
    IF( ld_start_date IS NULL ) THEN
      RAISE get_operating_day_expt;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    od_start_date   := ld_start_date;
    od_end_date     := ld_end_date;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 締め・支払日取得関数エラー ***
    WHEN get_close_date_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10454
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_reserve_rec.cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 営業日取得関数エラー ***
    WHEN get_operating_day_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10455
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_reserve_rec.cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_calc_period;
--
  /**********************************************************************************
   * Procedure Name   : reserve_loop
   * Description      : 保留ループ(A-3)
   ***********************************************************************************/
  PROCEDURE reserve_loop(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'reserve_loop';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ld_start_date                  DATE           DEFAULT NULL;                 -- 計算開始日
    ld_end_date                    DATE           DEFAULT NULL;                 -- 計算終了日
    ln_reserve_data_cnt            BINARY_INTEGER DEFAULT 0;                    -- 保留情報保持件数
    -- ログ出力用退避項目
    lt_ship_cust_code              hz_cust_accounts.account_number      %TYPE DEFAULT NULL;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 各種初期化
    --==================================================
    reserve_data_tab.DELETE;
    ln_reserve_data_cnt := 0;
    --==================================================
    -- 販手残高保留データの取得(A-3)
    --==================================================
    << reserve_data_loop >>
    FOR reserve_rec IN reserve_cur LOOP
      DECLARE
        skip_proc_expt        EXCEPTION; -- 処理スキップ
      BEGIN
        -- 契約情報が取得できない場合処理スキップ
        IF( reserve_rec.term_name IS NULL ) THEN
          RAISE skip_proc_expt;
        END IF;
        --==================================================
        -- 計算開始日・終了日の取得(A-4)
        --==================================================
        get_calc_period(
          ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
        , ov_retcode                  => lv_retcode                 -- リターン・コード
        , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
        , i_reserve_rec               => reserve_rec                -- 保留情報レコード
        , od_start_date               => ld_start_date              -- 計算開始日
        , od_end_date                 => ld_end_date                -- 計算終了日
        );
fnd_file.put_line( FND_FILE.LOG
                 ,           reserve_rec.cust_code
                   || ',' || reserve_rec.supplier_code
                   || ',' || reserve_rec.term_name
                   || ',' || TO_CHAR( ld_start_date,'RRRR/MM/DD' )
                   || ',' || TO_CHAR( ld_end_date  ,'RRRR/MM/DD' )
                 ); -- debug
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        END IF;
        --==================================================
        -- 支払保留の解除(A-5)
        --==================================================
        IF( gd_process_date = ld_start_date ) THEN
          update_xbb(
            ov_errbuf                   => lv_errbuf                  -- エラー・メッセージ
          , ov_retcode                  => lv_retcode                 -- リターン・コード
          , ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
          , i_reserve_rec               => reserve_rec                -- 保留情報レコード
          );
          IF( lv_retcode = cv_status_error ) THEN
            lv_end_retcode := cv_status_error;
            RAISE global_process_expt;
          END IF;
        --==================================================
        -- 支払保留情報の保持(A-6)
        --==================================================
        ELSIF(     ( gd_process_date  > ld_start_date )
               AND ( gd_process_date <= ld_end_date   )
        ) THEN
          ln_reserve_data_cnt := ln_reserve_data_cnt + 1;
          reserve_data_tab(ln_reserve_data_cnt).cust_code     := reserve_rec.cust_code;
          reserve_data_tab(ln_reserve_data_cnt).supplier_code := reserve_rec.supplier_code;
        END IF;
      EXCEPTION
        WHEN skip_proc_expt THEN
fnd_file.put_line( FND_FILE.LOG
                 ,           'contract_unknown:'
                   || ':' || reserve_rec.cust_code
                   || ',' || reserve_rec.supplier_code
                 ); -- debug
      END;
    END LOOP reserve_data_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END reserve_loop;
--
  /**********************************************************************************
   * Procedure Name   : purge_xbb
   * Description      : 販手残高保持期間外データの削除(A-2)
   ***********************************************************************************/
  PROCEDURE purge_xbb(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'purge_xbb';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ld_start_date                  DATE           DEFAULT NULL;                 -- 業務月月初日
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR xbb_parge_lock_cur(
      id_target_date               IN  DATE
    )
    IS
      SELECT xbb.bm_balance_id          AS bm_balance_id
      FROM xxcok_backmargin_balance     xbb           -- 販手残高テーブル
      WHERE xbb.publication_date        < id_target_date
        AND xbb.expect_payment_amt_tax  = 0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 月初日取得
    --==================================================
    ld_start_date := ADD_MONTHS( TRUNC( gd_process_date, 'MM' ), - gn_sales_retention_period );
    --==================================================
    -- 販手残高テーブルのロック
    --==================================================
    FOR xbb_parge_lock_rec IN xbb_parge_lock_cur( ld_start_date ) LOOP
      --==================================================
      -- 販手残高データパージ
      --==================================================
      DELETE
      FROM xxcok_backmargin_balance   xbb
      WHERE xbb.bm_balance_id = xbb_parge_lock_rec.bm_balance_id
      ;
    END LOOP;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    --*** ロック取得エラー ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10296
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END purge_xbb;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_process_date                IN  VARCHAR2        -- 業務処理日付
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- プログラム入力項目を出力
    --==================================================
    -- 業務処理日付
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00022
                  , iv_token_name1          => cv_tkn_business_date
                  , iv_token_value1         => iv_process_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message              => lv_outmsg         -- メッセージ
                  , in_new_line             => 0                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    --==================================================
    -- プログラム入力項目をグローバル変数へ格納
    --==================================================
    gv_param_process_date := iv_process_date;
    --==================================================
    -- 業務処理日付取得
    --==================================================
    IF( gv_param_process_date IS NOT NULL ) THEN
      gd_process_date := TO_DATE( gv_param_process_date, cv_format_fxrrrrmmdd );
    ELSE
      gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
      IF( gd_process_date IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00028
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
    END IF;
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'gd_process_date' || '【' || TO_CHAR( gd_process_date, 'RRRR/MM/DD' ) || '】' ); -- debug
    --==================================================
    -- プロファイル取得(XXCOK:販手販協計算処理期間（From）)
    --==================================================
    gn_bm_support_period_from := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_01 ) );
    IF( gn_bm_support_period_from IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(XXCOK:販手販協計算処理期間（To）)
    --==================================================
    gn_bm_support_period_to := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_02 ) );
    IF( gn_bm_support_period_to IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_02
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(XXCOK:販手販協情報保持期間)
    --==================================================
    gn_sales_retention_period := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_03 ) );
    IF( gn_sales_retention_period IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_03
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払条件_デフォルト)
    --==================================================
    gv_default_term_name := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF( gv_default_term_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_04
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_process_date                IN  VARCHAR2        -- 業務処理日付
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 初期処理(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_process_date         => iv_process_date       -- 業務処理日付
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 販手残高保持期間外データの削除(A-2)
    --==================================================
    purge_xbb(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 保留ループ(A-3)
    --==================================================
    reserve_loop(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 未確定販手残高データの削除(A-7)
    --==================================================
    delete_xbb(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 販手残高計算ループ(A-8)
    --==================================================
    calc_loop(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- エラーメッセージ
  , retcode                        OUT VARCHAR2        -- エラーコード
  , iv_process_date                IN  VARCHAR2        -- 業務処理日付
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- 終了メッセージコード
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message               => NULL               -- メッセージ
                  , in_new_line              => 1                  -- 改行
                  );
    --==================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_process_date         => iv_process_date       -- 業務処理日付
    );
    --==================================================
    -- エラー出力
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT     -- 出力区分
                    , iv_message               => lv_errmsg           -- メッセージ
                    , in_new_line              => 1                   -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 0
                    );
    END IF;
    --==================================================
    -- 対象件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 成功件数出力(エラー発生の場合、成功件数:0件 エラー件数:1件  対象件数0件の場合、成功件数:0件)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- エラー件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- 処理終了メッセージ出力
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ステータスセット
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- 終了ステータスエラー時、ロールバック
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK014A03C;
/
