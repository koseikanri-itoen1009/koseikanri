CREATE OR REPLACE PACKAGE BODY XXCOK009A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK009A01C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : アドオン：売上・売上原価振替仕訳の作成 販売物流 MD050_COK_009_A01
 * Version          : 1.6
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init                       初期処理(A-1)
 *  chk_status_p               会計期間ステータスチェック(A-2)
 *  get_object_journal_p       仕訳対象取得(A-3)
 *  get_entry_accession_info_p 登録付加情報取得(A-4)
 *  make_gloif_data_p          仕訳作成(A-5)
 *  ins_gl_interface_p         一般会計OIF登録(A-6)
 *  upd_jounal_create_p        仕訳作成フラグ更新(A-7)
 *  dlt_decision_flash_p       売上実績振替情報テーブルの速報データ削除(A-8)
 *  dlt_decision_fixedness_p   売上実績振替情報テーブルの確定データ削除(A-9)
 *  submain                    メイン処理プロシージャ
 *  main                       コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2008/12/17     1.0   SCS K.SUENAGA    新規作成
 * 2009/02/10     1.1   SCS T.OSADA      [障害COK_027]売上計上日抽出条件対応
 *                                       [障害COK_028]売上原価 NULL 対応
 * 2009/05/20     1.2   SCS M.HIRUTA     [障害T1_1099]売上実績振替情報テーブルより原価情報を取得する際のカラム変更
 *                                                    売上原価金額 ⇒ 営業原価
 * 2009/09/08     1.3   SCS K.YAMAGUCHI  [障害0001318]性能改善
 * 2009/10/09     1.4   SCS S.MORIYAMA   [障害E_T3_00632]伝票入力者を振替元顧客の担当営業員へ変更
 *                                                       仕訳集約単位に振替元顧客を追加
 * 2009/12/21     1.5   SCS K.NAKAMURA   [障害E_本稼動_00562]担当営業員取得の判定条件修正
 * 2010/01/28     1.6   SCS Y.KUBOSHIMA  [障害E_本稼動_01297]売上金額,営業原価がマイナスの場合、仕訳金額の符号反転するよう変更
 *
 *****************************************************************************************/
  --===============================
  --グローバル定数
  --===============================
  --ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by               CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
  cv_msg_part                 CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(3)   := '.';
  --パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(50)  := 'XXCOK009A01C';                     -- パッケージ名
  --プロファイル
  cv_set_of_bks_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                 -- 会計帳簿ID
  cv_set_of_bks_name          CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_NAME';               -- 会計帳簿名
  cv_comp_code                CONSTANT VARCHAR2(100) := 'XXCOK1_AFF1_COMPANY_CODE';         -- 会社コード
  cv_table_keep_period        CONSTANT VARCHAR2(100) := 'XXCOK1_TABLE_KEEP_PERIOD';         -- 売上実績振替情報保持期間
  cv_acct_prod_sale           CONSTANT VARCHAR2(100) := 'XXCOK1_AFF3_PROD_SALE';            -- 製品売上高
  cv_acct_prod_sale_cost      CONSTANT VARCHAR2(100) := 'XXCOK1_AFF3_PROD_SALE_COST';       -- 製品売上原価
  cv_aff4_subacct_dummy       CONSTANT VARCHAR2(100) := 'XXCOK1_AFF4_SUBACCT_DUMMY';        -- 補助科目のダミー値
  cv_assi_prod_sale_cost      CONSTANT VARCHAR2(100) := 'XXCOK1_AFF4_PROD_SALE_COST';       -- 受払表(製品原価)
  cv_gl_category_results      CONSTANT VARCHAR2(100) := 'XXCOK1_GL_CATEGORY_RESULTS';       -- 仕訳カテゴリ
  cv_gl_source_results        CONSTANT VARCHAR2(100) := 'XXCOK1_GL_SOURCE_RESULTS';         -- 仕訳ソース
  cv_aff5_customer_dummy      CONSTANT VARCHAR2(100) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- 顧客コードのダミー値
  cv_aff6_compuny_dummy       CONSTANT VARCHAR2(100) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- 企業コードのダミー値
  cv_aff7_preliminary1_dummy  CONSTANT VARCHAR2(100) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- 予備1のダミー値
  cv_aff8_preliminary2_dummy  CONSTANT VARCHAR2(100) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- 予備2のダミー値
  cv_selling_without_tax_code CONSTANT VARCHAR2(100) := 'XXCOK1_SELLING_WITHOUT_TAX_CODE';  -- 課税売上外税消費税コード
  --メッセージ
  cv_lock_err_msg             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10049';                 -- ロックエラーメッセージ
  cv_concurrent_msg           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90008';                 -- パラメータなしメッセージ
  cv_operation_date           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';                 -- 業務処理取得エラー
  cv_profile_msg              CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';                 -- プロファイル取得エラー
  cv_batch_msg                CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00026';                 -- バッチ名取得エラー
  cv_group_id_msg             CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00024';                 -- グループID取得エラー
  cv_currency_code_msg        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00029';                 -- 機能通貨コード取得エラー
  cv_acctg_calendar_msg       CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00011';                 -- 会計期間情報取得エラー
  cv_open_msg                 CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00042';                 -- 会計期間オープンエラー
  cv_data_msg                 CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00001';                 -- 対象データ無エラー
  cv_slip_number_msg          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00025';                 -- 伝票番号取得エラー
  cv_oif_msg                  CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10041';                 -- 一般会計OIF登録エラー
  cv_upd_msg                  CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10042';                 -- 仕訳作成フラグ更新エラー
  cv_lock_warn_msg            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10008';                 -- ロック警告メッセージ
  cv_flash_flag_msg           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10390';                 -- 速報削除エラーメッセージ
  cv_settlement_flag_msg      CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10391';                 -- 確定削除エラーメッセージ
  cv_normal_msg               CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';                 -- 正常終了メッセージ
  cv_warn_msg                 CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';                 -- エラー終了メッセージ
  cv_error_msg                CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';                 -- 警告終了メッセージ
  cv_target_count_msg         CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';                 -- 対象件数メッセージ
  cv_normal_count_msg         CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';                 -- 成功件数メッセージ
  cv_err_count_msg            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';                 -- エラー件数メッセージ
  cv_warn_count_msg           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';                 -- スキップ件数メッセージ
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
  cv_sales_staff_code_msg     CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00033';                 -- 営業担当員取得エラーメッセージ
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
  --ステータス
  cv_new_status               CONSTANT VARCHAR2(5)  := 'NEW';                               -- ステータス
  --フラグ
  cv_adjustment_period_flag   CONSTANT VARCHAR2(1)  := 'N';                                 -- 調整フラグ
  cv_report_decision_flag     CONSTANT VARCHAR2(1)  := '1';                                 -- 速報確定フラグ1(確定)
  cv_flash_report_flag        CONSTANT VARCHAR2(1)  := '0';                                 -- 速報確定フラグ0(速報)
  cv_info_interface_flag      CONSTANT VARCHAR2(1)  := '1';                                 -- 情報系I/Fフラグ1(I/F済)
  cv_unsettled_interface_flag CONSTANT VARCHAR2(1)  := '0';                                 -- 仕訳作成フラグ0(未済)
  cv_finish_interface_flag    CONSTANT VARCHAR2(1)  := '1';                                 -- 仕訳作成フラグ1(済)
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';                                 -- 実績フラグ
  --トークン
  cv_profile_token            CONSTANT VARCHAR2(15) := 'PROFILE';                           -- トークン名
  cv_sales_token              CONSTANT VARCHAR2(15) := 'SALES_DATE';                        -- トークン名
  cv_location_token           CONSTANT VARCHAR2(15) := 'LOCATION_CODE';                     -- トークン名
  cv_proc_token               CONSTANT VARCHAR2(15) := 'PROC_DATE';                         -- トークン名
  cv_count                    CONSTANT VARCHAR2(10) := 'COUNT';                             -- カウント
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
  cv_cust_code_token          CONSTANT VARCHAR2(10) := 'CUST_CODE';                         -- トークン名
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
  --アプリケーション短縮名
  cv_appli_ar_name            CONSTANT VARCHAR2(10) := 'AR';                                -- アプリケーション短縮名
  cv_appli_xxcok_name         CONSTANT VARCHAR2(10) := 'XXCOK';                             -- アプリケーション短縮名
  cv_appli_xxccp_name         CONSTANT VARCHAR2(10) := 'XXCCP';                             -- アプリケーション短縮名
  --===============================
  --グローバル変数
  --===============================
  gn_target_cnt               NUMBER         DEFAULT NULL;   -- 対象件数
  gn_normal_cnt               NUMBER         DEFAULT NULL;   -- 正常件数
  gn_error_cnt                NUMBER         DEFAULT NULL;   -- エラー件数
  gn_warn_cnt                 NUMBER         DEFAULT NULL;   -- スキップ件数
  gn_set_of_bks_id            NUMBER         DEFAULT NULL;   -- 会計帳簿ID
  gv_set_of_bks_name          VARCHAR2(100)  DEFAULT NULL;   -- 会計帳簿名
  gv_comp_code                VARCHAR2(100)  DEFAULT NULL;   -- 会社コード
  gv_table_keep_period        VARCHAR2(100)  DEFAULT NULL;   -- 保持期間(月数)
  gv_acct_prod_sale           VARCHAR2(100)  DEFAULT NULL;   -- 勘定科目コード(製品売上高)
  gv_acct_prod_sale_cost      VARCHAR2(100)  DEFAULT NULL;   -- 勘定科目コード(製品売上原価)
  gv_aff4_subacct_dummy       VARCHAR2(100)  DEFAULT NULL;   -- 補助科目のダミー値
  gv_assi_prod_sale_cost      VARCHAR2(100)  DEFAULT NULL;   -- 製品売上原価_受払表(製品原価)
  gv_gl_category_results      VARCHAR2(100)  DEFAULT NULL;   -- 仕訳カテゴリ
  gv_gl_source_results        VARCHAR2(100)  DEFAULT NULL;   -- 仕訳ソース
  gv_aff5_customer_dummy      VARCHAR2(100)  DEFAULT NULL;   -- 顧客コードのダミー値
  gv_aff6_compuny_dummy       VARCHAR2(100)  DEFAULT NULL;   -- 企業コードのダミー値
  gv_aff7_preliminary1_dummy  VARCHAR2(100)  DEFAULT NULL;   -- 予備1のダミー値
  gv_aff8_preliminary2_dummy  VARCHAR2(100)  DEFAULT NULL;   -- 予備2のダミー値
  gv_selling_without_tax_code VARCHAR2(100)  DEFAULT NULL;   -- 課税売上外税消費税コード
  gd_selling_date             DATE           DEFAULT NULL;   -- 売上計上日(前日末日)
  gv_slip_number              VARCHAR2(100)  DEFAULT NULL;   -- 伝票番号
  gv_currency_code            VARCHAR2(100)  DEFAULT NULL;   -- 機能通貨コード
  gv_batch_name               VARCHAR2(100)  DEFAULT NULL;   -- バッチ名
  gv_period_name              VARCHAR2(100)  DEFAULT NULL;   -- 会計期間名
  gn_group_id                 NUMBER         DEFAULT NULL;   -- グループID
  gv_division                 VARCHAR2(100)  DEFAULT NULL;   -- 部門
  gn_debit_amt                NUMBER         DEFAULT NULL;   -- 借方金額
  gn_credit_amt               NUMBER         DEFAULT NULL;   -- 貸方金額
  gd_operation_date           DATE           DEFAULT NULL;   -- 業務処理日付
  -- ===============================
  -- グローバルカーソル
  -- ===============================
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama REPAIR START
--  CURSOR g_get_journal_cur
--  IS
--    SELECT   xsti.selling_date            AS xsti_selling_date           -- 売上計上日
---- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama REPAIR START
--           , xsti.selling_from_cust_code  AS selling_from_cust_code      -- 売上振替元顧客コード
---- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama REPAIR END
--           , xsti.base_code               AS base_code                   -- 売上振替先拠点コード
--           , xsti.delivery_base_code      AS delivery_base_code          -- 売上振替元拠点コード
--           , SUM(xsti.selling_amt_no_tax) AS selling_amt                 -- 売上金額
---- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
----           , SUM(xsti.selling_cost_amt)   AS selling_cost_amt            -- 売上原価金額
--           , SUM(xsti.trading_cost)       AS trading_cost                -- 営業原価
---- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--    FROM     xxcok_selling_trns_info         xsti                        -- 売上実績振替情報テーブル
---- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
----    WHERE    substr(to_char(xsti.selling_date,'YYYY/MM/DD'),1,7) 
----                                          =  substr(to_char(gd_selling_date,'YYYY/MM/DD'),1,7) -- A-2で取得した売上計上日
--    WHERE    xsti.selling_date           >=              TRUNC( gd_selling_date,'MM' )      -- A-2で取得した売上計上日
--    AND      xsti.selling_date            <  ADD_MONTHS( TRUNC( gd_selling_date,'MM' ), 1 ) -- A-2で取得した売上計上日+1ヶ月
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
--    AND      xsti.report_decision_flag    =  cv_report_decision_flag     -- 速報確定フラグ1(確定)
--    AND      xsti.info_interface_flag     =  cv_info_interface_flag      -- 情報系I/Fフラグ1(I/F済)
--    AND      xsti.gl_interface_flag       =  cv_unsettled_interface_flag -- 仕訳作成フラグ0(仕訳作成未済)
--    GROUP BY xsti.selling_date
--           , xsti.base_code
--           , xsti.delivery_base_code;
--
  CURSOR g_get_journal_cur
  IS
    SELECT   xsti.selling_date            AS xsti_selling_date           -- 売上計上日
           , xsti.selling_from_cust_code  AS selling_from_cust_code      -- 売上振替元顧客コード
           , xsti.base_code               AS base_code                   -- 売上振替先拠点コード
           , xsti.delivery_base_code      AS delivery_base_code          -- 売上振替元拠点コード
           , SUM(xsti.selling_amt_no_tax) AS selling_amt                 -- 売上金額
           , SUM(xsti.trading_cost)       AS trading_cost                -- 営業原価
    FROM     xxcok_selling_trns_info         xsti                        -- 売上実績振替情報テーブル
    WHERE    xsti.selling_date           >=              TRUNC( gd_selling_date,'MM' )      -- A-2で取得した売上計上日
    AND      xsti.selling_date            <  ADD_MONTHS( TRUNC( gd_selling_date,'MM' ), 1 ) -- A-2で取得した売上計上日+1ヶ月
    AND      xsti.report_decision_flag    =  cv_report_decision_flag     -- 速報確定フラグ1(確定)
    AND      xsti.info_interface_flag     =  cv_info_interface_flag      -- 情報系I/Fフラグ1(I/F済)
    AND      xsti.gl_interface_flag       =  cv_unsettled_interface_flag -- 仕訳作成フラグ0(仕訳作成未済)
    GROUP BY xsti.selling_date
           , xsti.selling_from_cust_code
           , xsti.base_code
           , xsti.delivery_base_code
    ORDER BY xsti.selling_date
           , xsti.selling_from_cust_code
           , xsti.base_code
           , xsti.delivery_base_code;
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama REPAIR END
--
  -- ===============================
  -- グローバルレコードタイプ
  -- ===============================
  g_get_journal_rtype g_get_journal_cur%ROWTYPE;
    --===============================
  --グローバル例外
  --===============================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ロックエラー **
  lock_err_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_err_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : dlt_decision_fixedness_p
   * Description      : 売上実績振替情報テーブルの確定データ削除(A-9)
   ***********************************************************************************/
  PROCEDURE dlt_decision_fixedness_p(
    ov_errbuf  OUT VARCHAR2                                             -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                             -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                             -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlt_decision_fixedness_p'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT NULL;                 -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lb_retcode             BOOLEAN        DEFAULT NULL;                 -- メッセージ出力変数
    ld_dlt_possible_date   DATE           DEFAULT NULL;                 -- 格納変数
    lv_out_msg             VARCHAR2(5000) DEFAULT NULL;                 -- メッセージ出力変数
    --==============================================================
    --ロック取得用カーソル
    --==============================================================
    CURSOR dlt_cur(
             id_dlt_possible_date IN DATE
           )
    IS
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--      SELECT 'X'
      SELECT /*+
               INDEX( xsti XXCOK_SELLING_TRNS_INFO_N03 )
             */
             xsti.selling_trns_info_id  AS selling_trns_info_id
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
      FROM   xxcok_selling_trns_info     xsti
      WHERE  xsti.selling_date        <= id_dlt_possible_date    -- ADD_MONTHS(業務処理日付, - A-1で取得した保持期間)
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi DELETE START
--      AND    xsti.report_decision_flag = cv_report_decision_flag -- 速報確定フラグ1(確定)
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi DELETE END
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
    --================================================================
    --カーソルオープン
    --================================================================
    ld_dlt_possible_date := ADD_MONTHS( gd_operation_date, - gv_table_keep_period );
--
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--    OPEN  dlt_cur(
--            ld_dlt_possible_date
--          );
--    CLOSE dlt_cur;
--    --================================================================
--    --売上実績振替情報テーブルの削除処理
--    --================================================================
--    BEGIN
--      DELETE FROM xxcok_selling_trns_info     xsti
--      WHERE       xsti.selling_date        <= ld_dlt_possible_date     --ADD_MONTHS(業務処理日付,-A-1で取得した保持期間)
--      AND         xsti.report_decision_flag = cv_report_decision_flag; --速報確定フラグ1(確定)
--    EXCEPTION
--      -- *** 確定データ削除エラー ***
--      WHEN OTHERS THEN
--        lv_out_msg  := xxccp_common_pkg.get_msg(
--                         cv_appli_xxcok_name
--                       , cv_settlement_flag_msg
--                       );
--        lb_retcode  := xxcok_common_pkg.put_message_f( 
--                         FND_FILE.OUTPUT    -- 出力区分
--                       , lv_out_msg         -- メッセージ
--                       , 0                  -- 改行
--                       );
--        ov_errmsg   := NULL;
--        ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--        ov_retcode  := cv_status_error;
--    END;
    << purge_loop >>
    FOR dlt_rec IN dlt_cur( ld_dlt_possible_date ) LOOP
      --================================================================
      --売上実績振替情報テーブルの削除処理
      --================================================================
      BEGIN
        DELETE
        FROM  xxcok_selling_trns_info   xsti
        WHERE xsti.selling_trns_info_id = dlt_rec.selling_trns_info_id
        ;
      EXCEPTION
        -- *** 確定データ削除エラー ***
        WHEN OTHERS THEN
          lv_out_msg  := xxccp_common_pkg.get_msg(
                           cv_appli_xxcok_name
                         , cv_settlement_flag_msg
                         );
          lb_retcode  := xxcok_common_pkg.put_message_f( 
                           FND_FILE.OUTPUT    -- 出力区分
                         , lv_out_msg         -- メッセージ
                         , 0                  -- 改行
                         );
          ov_errmsg   := NULL;
          ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode  := cv_status_error;
          EXIT purge_loop;
      END;
    END LOOP purge_loop;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** ロック警告メッセージ ***
    WHEN lock_err_expt THEN
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi DELETE START
--      gn_warn_cnt := gn_warn_cnt + 1;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi DELETE END
      lv_out_msg  := xxccp_common_pkg.get_msg(
                       cv_appli_xxcok_name
                     , cv_lock_warn_msg
                     );
      lb_retcode  := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg   := NULL;
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--      ov_retcode  := cv_status_warn;
      ov_retcode  := cv_status_error;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END dlt_decision_fixedness_p;
--
  /**********************************************************************************
   * Procedure Name   : dlt_decision_flash_p
   * Description      : 売上実績振替情報テーブルの速報データ削除(A-8)
   ***********************************************************************************/
  PROCEDURE dlt_decision_flash_p(
    ov_errbuf  OUT VARCHAR2                                         -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                         -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                         -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlt_decision_flash_p'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                         -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                         -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                         -- ユーザー・エラー・メッセージ
    lb_retcode BOOLEAN        DEFAULT NULL;                         -- メッセージ出力変数
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                         -- メッセージ出力変数
    --==============================================================
    --ロック取得用カーソル
    --==============================================================
    CURSOR l_dlt_cur
    IS
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--      SELECT 'X'
      SELECT /*+
               INDEX( xsti XXCOK_SELLING_TRNS_INFO_N03 )
             */
             xsti.selling_trns_info_id  AS selling_trns_info_id
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
      FROM  xxcok_selling_trns_info      xsti                       -- 売上実績振替情報テーブル
      WHERE xsti.selling_date         <= gd_selling_date            -- 売上計上日
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi ADD START
      AND   xsti.selling_date         >= TRUNC( ADD_MONTHS( gd_selling_date, -1 ), 'MM' ) -- 売上計上日の前月月初
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi ADD END
      AND   xsti.report_decision_flag  = cv_flash_report_flag       -- 速報確定フラグ0(速報)
      AND   xsti.info_interface_flag   = cv_info_interface_flag     -- 情報系I/Fフラグ1(I/F済)
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--    --================================================================
--    --カーソルオープン
--    --================================================================
--    OPEN  l_dlt_cur;
--    CLOSE l_dlt_cur;
--    --================================================================
--    --売上実績振替情報テーブルの削除処理
--    --================================================================
--    BEGIN
--      DELETE FROM  xxcok_selling_trns_info      xsti
--      WHERE        xsti.selling_date         <= gd_selling_date         -- 売上計上日
--      AND          xsti.report_decision_flag  = cv_flash_report_flag    -- 速報確定フラグ0(速報)
--      AND          xsti.info_interface_flag   = cv_info_interface_flag; -- 情報系I/Fフラグ1(I/F済)
--    EXCEPTION
--      -- *** 速報データ削除エラー ***
--      WHEN OTHERS THEN
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                        cv_appli_xxcok_name
--                      , cv_flash_flag_msg
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f( 
--                        FND_FILE.OUTPUT    -- 出力区分
--                      , lv_out_msg         -- メッセージ
--                      , 0                  -- 改行
--                      );
--        ov_errmsg  := NULL;
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--        ov_retcode := cv_status_error;
--    END;
    --================================================================
    --カーソルオープン
    --================================================================
    << dlt_decision_flash_loop >>
    FOR l_dlt_rec IN l_dlt_cur LOOP
      --================================================================
      --売上実績振替情報テーブルの削除処理
      --================================================================
      BEGIN
        DELETE
        FROM  xxcok_selling_trns_info      xsti
        WHERE xsti.selling_trns_info_id = l_dlt_rec.selling_trns_info_id
        ;
      EXCEPTION
        -- *** 速報データ削除エラー ***
        WHEN OTHERS THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_flash_flag_msg
                        );
          lb_retcode := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- 出力区分
                        , lv_out_msg         -- メッセージ
                        , 0                  -- 改行
                        );
          ov_errmsg  := NULL;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode := cv_status_error;
          EXIT dlt_decision_flash_loop;
      END;
    END LOOP dlt_decision_flash_loop;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** ロック警告メッセージ ***
    WHEN lock_err_expt THEN
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi DELETE START
--      gn_warn_cnt:= gn_warn_cnt + 1;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi DELETE END
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_lock_warn_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--      ov_retcode := cv_status_warn;
      ov_retcode := cv_status_error;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END dlt_decision_flash_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_jounal_create_p
   * Description      : 仕訳作成フラグ更新(A-7)
   ***********************************************************************************/
  PROCEDURE upd_jounal_create_p(
    ov_errbuf  OUT VARCHAR2                                        -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                        -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                        -- ユーザー・エラー・メッセージ
  , i_get_rec  IN  g_get_journal_cur%ROWTYPE                       -- レコード引数
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_jounal_create_p'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                        -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                        -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                        -- ユーザー・エラー・メッセージ
    lb_retcode BOOLEAN        DEFAULT NULL;                        -- メッセージ出力変数
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                        -- メッセージ出力変数
    --==============================================================
    --ロック取得用カーソル
    --==============================================================
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama UPD START
--    CURSOR l_upd_cur
--    IS
---- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
----      SELECT 'X'
--      SELECT /*+
--               INDEX( xsti XXCOK_SELLING_TRNS_INFO_N03 )
--             */
--             xsti.selling_trns_info_id  AS selling_trns_info_id
---- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
--      FROM   xxcok_selling_trns_info     xsti                         -- 売上実績振替情報テーブル
--      WHERE  xsti.report_decision_flag = cv_report_decision_flag      -- 速報確定フラグ1(確定)
--      AND    xsti.info_interface_flag  = cv_info_interface_flag       -- 情報系I/Fフラグ1(I/F済)
--      AND    xsti.gl_interface_flag    = cv_unsettled_interface_flag  -- 仕訳作成フラグ0(仕訳作成未済)
---- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
----      AND    substr(to_char(xsti.selling_date,'YYYY/MM/DD'),1,7) 
----                                       =  substr(to_char(gd_selling_date,'YYYY/MM/DD'),1,7) -- 売上計上日
--      AND    xsti.selling_date         = i_get_rec.xsti_selling_date  -- 売上計上日
---- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
--      AND    xsti.base_code            = i_get_rec.base_code          -- 売上振替先拠点コード
--      AND    xsti.delivery_base_code   = i_get_rec.delivery_base_code -- 売上振替元拠点コード
--      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
    CURSOR l_upd_cur
    IS
      SELECT /*+
               INDEX( xsti XXCOK_SELLING_TRNS_INFO_N03 )
             */
             xsti.selling_trns_info_id  AS selling_trns_info_id
      FROM   xxcok_selling_trns_info     xsti                         -- 売上実績振替情報テーブル
      WHERE  xsti.report_decision_flag = cv_report_decision_flag      -- 速報確定フラグ1(確定)
      AND    xsti.info_interface_flag  = cv_info_interface_flag       -- 情報系I/Fフラグ1(I/F済)
      AND    xsti.gl_interface_flag    = cv_unsettled_interface_flag  -- 仕訳作成フラグ0(仕訳作成未済)
      AND    xsti.selling_date         = i_get_rec.xsti_selling_date  -- 売上計上日
      AND    xsti.base_code            = i_get_rec.base_code          -- 売上振替先拠点コード
      AND    xsti.delivery_base_code   = i_get_rec.delivery_base_code -- 売上振替元拠点コード
      AND    xsti.selling_from_cust_code = i_get_rec.selling_from_cust_code -- 売上振替元顧客コード
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama UPD END
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --カーソルオープン
    --==============================================================
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--    OPEN  l_upd_cur;
--    CLOSE l_upd_cur;
--    --==============================================================
--    --売上実績振替情報テーブルの更新処理
--    --===============================================================
--    BEGIN
----
--      UPDATE xxcok_selling_trns_info       xsti
--      SET    xsti.gl_interface_flag      = cv_finish_interface_flag      -- 仕訳作成フラグ1(仕訳作成済)
--           , xsti.org_slip_number        = gv_slip_number                -- A-4で取得した伝票番号
--           , xsti.last_updated_by        = cn_last_updated_by            -- ログインユーザーID
--           , xsti.last_update_date       = SYSDATE                       -- システム日付
--           , xsti.last_update_login      = cn_last_update_login          -- ログインID
--           , xsti.request_id             = cn_request_id                 -- コンカレント要求ID
--           , xsti.program_application_id = cn_program_application_id     -- プログラム・アプリケーションID
--           , xsti.program_id             = cn_program_id                 -- コンカレント・プログラムID
--           , xsti.program_update_date    = SYSDATE                       -- システム日付
--      WHERE  xsti.report_decision_flag   = cv_report_decision_flag       -- 速報確定フラグ1(確定)
--      AND    xsti.info_interface_flag    = cv_info_interface_flag        -- 情報系I/Fフラグ1(I/F済)
--      AND    xsti.gl_interface_flag      = cv_unsettled_interface_flag   -- 仕訳作成フラグ0(仕訳作成未済)
--      AND    substr(to_char(xsti.selling_date,'YYYY/MM/DD'),1,7) 
--                                         =  substr(to_char(gd_selling_date,'YYYY/MM/DD'),1,7) -- 売上計上日
--      AND    xsti.base_code              = i_get_rec.base_code           -- 売上振替先拠点コード
--      AND    xsti.delivery_base_code     = i_get_rec.delivery_base_code; -- 売上振替元拠点コード
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        -- *** 仕訳作成フラグ更新エラー ***
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                        cv_appli_xxcok_name
--                      , cv_upd_msg
--                      , cv_sales_token
--                      , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
--                      , cv_location_token
--                      , i_get_rec.base_code
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f( 
--                        FND_FILE.OUTPUT    -- 出力区分
--                      , lv_out_msg         -- メッセージ
--                      , 0                  -- 改行
--                      );
--        ov_errmsg  := NULL;
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--        ov_retcode := cv_status_error;
--    END;
    << update_xsti_loop >>
    FOR l_upd_rec IN l_upd_cur LOOP
      --==============================================================
      --売上実績振替情報テーブルの更新処理
      --===============================================================
      BEGIN
        UPDATE xxcok_selling_trns_info       xsti
        SET    xsti.gl_interface_flag      = cv_finish_interface_flag      -- 仕訳作成フラグ1(仕訳作成済)
             , xsti.org_slip_number        = gv_slip_number                -- A-4で取得した伝票番号
             , xsti.last_updated_by        = cn_last_updated_by            -- ログインユーザーID
             , xsti.last_update_date       = SYSDATE                       -- システム日付
             , xsti.last_update_login      = cn_last_update_login          -- ログインID
             , xsti.request_id             = cn_request_id                 -- コンカレント要求ID
             , xsti.program_application_id = cn_program_application_id     -- プログラム・アプリケーションID
             , xsti.program_id             = cn_program_id                 -- コンカレント・プログラムID
             , xsti.program_update_date    = SYSDATE                       -- システム日付
        WHERE  xsti.selling_trns_info_id   = l_upd_rec.selling_trns_info_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- *** 仕訳作成フラグ更新エラー ***
          lv_out_msg := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_upd_msg
                        , cv_sales_token
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--                        , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                        , TO_CHAR(i_get_rec.xsti_selling_date,'YYYY/MM/DD')
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
                        , cv_location_token
                        , i_get_rec.base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- 出力区分
                        , lv_out_msg         -- メッセージ
                        , 0                  -- 改行
                        );
          ov_errmsg  := NULL;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode := cv_status_error;
          EXIT update_xsti_loop;
      END;
    END LOOP update_xsti_loop;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** ロックエラーメッセージ ***
    WHEN lock_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_lock_err_msg
                    , cv_sales_token
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--                    , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                    , TO_CHAR(i_get_rec.xsti_selling_date,'YYYY/MM/DD')
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
                    , cv_location_token
                    , i_get_rec.base_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_jounal_create_p;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_interface_p
   * Description      : 一般会計OIF登録(A-6)
   ***********************************************************************************/
  PROCEDURE ins_gl_interface_p(
    ov_errbuf          OUT VARCHAR2                               -- エラー・メッセージ
  , ov_retcode         OUT VARCHAR2                               -- リターン・コード
  , ov_errmsg          OUT VARCHAR2                               -- ユーザー・エラー・メッセージ
  , iv_division        IN  VARCHAR2                               -- 部門
  , iv_account_class   IN  VARCHAR2                               -- 勘定科目
  , iv_adminicle_class IN  VARCHAR2                               -- 補助科目
  , in_debit_amt       IN  NUMBER                                 -- 借方金額
  , in_credit_amt      IN  NUMBER                                 -- 貸方金額
  , iv_base_code       IN  VARCHAR2                               -- 売上振替先拠点コード
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
  , iv_sales_staff_code IN VARCHAR2                               -- 売上振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_interface_p'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                       -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                       -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                       -- ユーザー・エラー・メッセージ
    lb_retcode BOOLEAN        DEFAULT NULL;                       -- メッセージ出力変数
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                       -- メッセージ出力変数
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    --==================================================================
    --一般会計OIFへレコードの追加
    --==================================================================
    BEGIN
      INSERT INTO gl_interface(
        status                                          -- ステータス
      , set_of_books_id                                 -- 会計帳簿ID
      , accounting_date                                 -- 仕訳有効日付
      , currency_code                                   -- 通貨コード
      , date_created                                    -- 新規作成日付
      , created_by                                      -- 新規作成者ID
      , actual_flag                                     -- 残高タイプ
      , user_je_category_name                           -- 仕訳カテゴリ名
      , user_je_source_name                             -- 仕訳ソース名
      , segment1                                        -- 会社
      , segment2                                        -- 部門
      , segment3                                        -- 勘定科目
      , segment4                                        -- 補助科目
      , segment5                                        -- 顧客コード
      , segment6                                        -- 企業コード
      , segment7                                        -- 予備1
      , segment8                                        -- 予備2
      , entered_dr                                      -- 借方金額
      , entered_cr                                      -- 貸方金額
      , reference1                                      -- バッチ名
      , reference4                                      -- 仕訳名
      , period_name                                     -- 会計期間名
      , group_id                                        -- グループID
      , attribute1                                      -- 税区分
      , attribute3                                      -- 伝票番号
      , attribute4                                      -- 起票部門
      , attribute5                                      -- 伝票入力者
      , context                                         -- DFFコンテキスト
      )
      VALUES(
        cv_new_status                                  -- 'NEW'
      , gn_set_of_bks_id                               -- A-1で取得した会計帳簿ID
      , gd_selling_date                                -- A-2で取得した売上計上日
      , gv_currency_code                               -- A-1で取得した機能通貨コード
      , SYSDATE                                        -- SYSDATE
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--      , cn_last_update_login                           -- ログインユーザーID
      , cn_created_by                                  -- ログインユーザーID
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
      , cv_result_flag                                 -- 'A'(実績)
      , gv_gl_category_results                         -- A-1で取得した仕訳カテゴリ名
      , gv_gl_source_results                           -- A-1で取得した仕訳ソース名
      , gv_comp_code                                   -- A-1で取得した会社コード
      , iv_division                                    -- パラメータ部門
      , iv_account_class                               -- パラメータ勘定科目
      , iv_adminicle_class                             -- パラメータ補助科目
      , gv_aff5_customer_dummy                         -- A-1で取得した顧客コードダミー値
      , gv_aff6_compuny_dummy                          -- A-1で取得した企業コードダミー値
      , gv_aff7_preliminary1_dummy                     -- A-1で取得した予備１ダミー値
      , gv_aff8_preliminary2_dummy                     -- A-1で取得した予備２ダミー値
      , in_debit_amt                                   -- パラメータ借方金額
      , in_credit_amt                                  -- パラメータ貸方金額
      , gv_batch_name                                  -- A-1で取得したバッチ名
      , gv_slip_number                                 -- A-4で取得した伝票番号
      , gv_period_name                                 -- A-2で取得した会計期間名
      , gn_group_id                                    -- A-1で取得したグループID
      , gv_selling_without_tax_code                    -- A-1で取得した課税売上外税消費税コード
      , gv_slip_number                                 -- A-4で取得した伝票番号
      , iv_base_code                                   -- A-3で取得した売上振替先拠点コード
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--      , cn_last_update_login                           -- ログインユーザーID
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama REPAIR START
--      , cn_created_by                                  -- ログインユーザーID
      , iv_sales_staff_code                            -- 売上振替元顧客担当営業員
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama REPAIR END
      , gv_set_of_bks_name                             -- A-1で取得した会計帳簿名
      );
    EXCEPTION
      -- *** 一般会計OIF登録エラー ***
      WHEN OTHERS THEN
        lv_out_msg  := xxccp_common_pkg.get_msg(
                         cv_appli_xxcok_name
                       , cv_oif_msg
                       , cv_sales_token
                       , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                       , cv_location_token
                       , iv_base_code
                       );
        lb_retcode  := xxcok_common_pkg.put_message_f( 
                         FND_FILE.OUTPUT    -- 出力区分
                       , lv_out_msg         -- メッセージ
                       , 0                  -- 改行
                       );
        ov_errmsg   := NULL;
        ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
        ov_retcode  := cv_status_error;
    END;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf   := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  := cv_status_error;
  END ins_gl_interface_p;
--
  /**********************************************************************************
   * Procedure Name   : make_gloif_data_p
   * Description      : 仕訳作成(A-5)
   ***********************************************************************************/
  PROCEDURE make_gloif_data_p(
    ov_errbuf  OUT VARCHAR2                                      -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                      -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                      -- ユーザー・エラー・メッセージ
  , i_get_rec  IN  g_get_journal_cur%ROWTYPE                     -- レコードの引数
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
  , iv_sales_staff IN jtf_rs_resource_extns.source_number%TYPE   -- 振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
    )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_gloif_data_p'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                      -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;                      -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                      -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;                      -- メッセージ出力変数
    lb_retcode BOOLEAN        DEFAULT NULL;                      -- メッセージ出力変数
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    --==================================================================
    --＜仕訳パターン1＞集計後の売上金額>0(貸借)
    --==================================================================
    IF( i_get_rec.selling_amt > 0 ) THEN
      --================================================================
      --ins_gl_interface_p呼び出し(一般会計OIF登録(A-6))
      --================================================================
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.delivery_base_code -- 部門(売上振替元拠点コード)
      , iv_account_class   => gv_acct_prod_sale            -- 勘定科目(A-1で取得した勘定科目コード(製品売上高))
      , iv_adminicle_class => gv_aff4_subacct_dummy        -- 補助科目(ダミー値)
      , in_debit_amt       => i_get_rec.selling_amt        -- 借方金額(売上金額)
      , in_credit_amt      => 0                            -- 貸方金額(0)
      , iv_base_code       => i_get_rec.base_code          -- 売上振替先拠点コード
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- 売上振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.base_code          -- 部門(売上振替先拠点コード)
      , iv_account_class   => gv_acct_prod_sale            -- 勘定科目(A-1で取得した勘定科目コード(製品売上高))
      , iv_adminicle_class => gv_aff4_subacct_dummy        -- 補助科目(ダミー値)
      , in_debit_amt       => 0                            -- 借方金額(0)
      , in_credit_amt      => i_get_rec.selling_amt        -- 貸方金額(売上金額)
      , iv_base_code       => i_get_rec.base_code          -- 売上振替先拠点コード
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- 売上振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
    --==================================================================
    --＜仕訳パターン2＞集計後の売上金額<0(貸借)
    --==================================================================
    IF( i_get_rec.selling_amt < 0 ) THEN
      --================================================================
      --ins_gl_interface_p呼び出し(一般会計OIF登録(A-6))
      --================================================================
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.delivery_base_code -- 部門(売上振替元拠点コード)
      , iv_account_class   => gv_acct_prod_sale            -- 勘定科目(A-1で取得した勘定科目コード(製品売上高))
      , iv_adminicle_class => gv_aff4_subacct_dummy        -- 補助科目(ダミー値)
      , in_debit_amt       => 0                            -- 借方金額(0)
-- 2010/01/28 Ver.1.6 [障害E_本稼動_01297] SCS Y.Kuboshima MOD START
--      , in_credit_amt      => i_get_rec.selling_amt        -- 貸方金額(売上金額)
        -- 金額の符号反転
      , in_credit_amt      => -( i_get_rec.selling_amt )   -- 貸方金額(売上金額)
-- 2010/01/28 Ver.1.6 [障害E_本稼動_01297] SCS Y.Kuboshima MOD END
      , iv_base_code       => i_get_rec.base_code          -- 売上振替先拠点コード
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- 売上振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.base_code          -- 部門(売上振替先拠点コード)
      , iv_account_class   => gv_acct_prod_sale            -- 勘定科目(A-1で取得した勘定科目コード(製品売上高))
      , iv_adminicle_class => gv_aff4_subacct_dummy        -- 補助科目(ダミー値)
-- 2010/01/28 Ver.1.6 [障害E_本稼動_01297] SCS Y.Kuboshima MOD START
--      , in_debit_amt       => i_get_rec.selling_amt        -- 借方金額(売上金額)
        -- 金額の符号反転
      , in_debit_amt       => -( i_get_rec.selling_amt )   -- 借方金額(売上金額)
-- 2010/01/28 Ver.1.6 [障害E_本稼動_01297] SCS Y.Kuboshima MOD END
      , in_credit_amt      => 0                            -- 貸方金額(0)
      , iv_base_code       => i_get_rec.base_code          -- 売上振替先拠点コード
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- 売上振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--    --==================================================================
--    --＜仕訳パターン3＞集計後の売上原価金額>0(貸借)
--    --==================================================================
--    IF( i_get_rec.selling_cost_amt > 0 ) THEN
--
    --==================================================================
    --＜仕訳パターン3＞集計後の営業原価>0(貸借)
    --==================================================================
    IF( i_get_rec.trading_cost > 0 ) THEN
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      --================================================================
      --ins_gl_interface_p呼び出し(一般会計OIF登録(A-6))
      --================================================================
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.delivery_base_code -- 部門(売上振替元拠点コード)
      , iv_account_class   => gv_acct_prod_sale_cost       -- 勘定科目(勘定科目コード(製品売上原価))
      , iv_adminicle_class => gv_assi_prod_sale_cost       -- 補助科目(製品売上原価_受払表(製品原価))
      , in_debit_amt       => 0                            -- 借方金額(0)
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      , in_credit_amt      => i_get_rec.selling_cost_amt   -- 貸方金額(売上原価金額)
      , in_credit_amt      => i_get_rec.trading_cost       -- 貸方金額(営業原価)
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      , iv_base_code       => i_get_rec.base_code          -- 売上振替先拠点コード
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- 売上振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.base_code          -- 部門(売上振替先拠点コード)
      , iv_account_class   => gv_acct_prod_sale_cost       -- 勘定科目(勘定科目コード(製品売上原価))
      , iv_adminicle_class => gv_assi_prod_sale_cost       -- 補助科目(製品売上原価_受払表(製品原価))
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      , in_debit_amt       => i_get_rec.selling_cost_amt   -- 借方金額(売上原価金額)
      , in_debit_amt       => i_get_rec.trading_cost       -- 借方金額(営業原価)
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      , in_credit_amt      => 0                            -- 貸方金額(0)
      , iv_base_code       => i_get_rec.base_code          -- 売上振替先拠点コード
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- 売上振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--    --==================================================================
--    --＜仕訳パターン4＞集計後の売上原価金額<0(借方)
--    --==================================================================
--    IF( i_get_rec.selling_cost_amt < 0 ) THEN
--
    --==================================================================
    --＜仕訳パターン4＞集計後の営業原価<0(借方)
    --==================================================================
    IF( i_get_rec.trading_cost < 0 ) THEN
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      --================================================================
      --ins_gl_interface_p呼び出し(一般会計OIF登録(A-6))
      --================================================================
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.delivery_base_code -- 部門(売上振替元拠点コード)
      , iv_account_class   => gv_acct_prod_sale_cost       -- 勘定科目(勘定科目コード(製品売上原価))
      , iv_adminicle_class => gv_assi_prod_sale_cost       -- 補助科目(製品売上原価_受払表(製品原価))
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      , in_debit_amt       => i_get_rec.selling_cost_amt   -- 借方金額(売上原価金額)
-- 2010/01/28 Ver.1.6 [障害E_本稼動_01297] SCS Y.Kuboshima MOD START
--      , in_debit_amt       => i_get_rec.trading_cost       -- 借方金額(営業原価)
        -- 金額の符号反転
      , in_debit_amt       => -( i_get_rec.trading_cost )  -- 借方金額(営業原価)
-- 2010/01/28 Ver.1.6 [障害E_本稼動_01297] SCS Y.Kuboshima MOD END
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      , in_credit_amt      => 0                            -- 借方金額(0)
      , iv_base_code       => i_get_rec.base_code          -- 売上振替先拠点コード
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- 売上振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      ins_gl_interface_p(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_division        => i_get_rec.base_code          -- 部門(売上振替先拠点コード)
      , iv_account_class   => gv_acct_prod_sale_cost       -- 勘定科目(勘定科目コード(製品売上原価))
      , iv_adminicle_class => gv_assi_prod_sale_cost       -- 補助科目(製品売上原価_受払表(製品原価))
      , in_debit_amt       => 0                            -- 借方金額(0)
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      , in_credit_amt      => i_get_rec.selling_cost_amt   -- 貸方金額(売上原価金額)
-- 2010/01/28 Ver.1.6 [障害E_本稼動_01297] SCS Y.Kuboshima MOD START
--      , in_credit_amt      => i_get_rec.trading_cost       -- 貸方金額(営業原価)
        -- 金額の符号反転
      , in_credit_amt      => -( i_get_rec.trading_cost )  -- 貸方金額(営業原価)
-- 2010/01/28 Ver.1.6 [障害E_本稼動_01297] SCS Y.Kuboshima MOD END
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
      , iv_base_code       => i_get_rec.base_code          -- 売上振替先拠点コード
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
      , iv_sales_staff_code => iv_sales_staff              -- 売上振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END make_gloif_data_p;
--
  /**********************************************************************************
   * Procedure Name   : get_entry_accession_info_p
   * Description      : 登録付加情報取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_entry_accession_info_p(
    ov_errbuf  OUT VARCHAR2                                               -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                               -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                               -- ユーザー・エラー・メッセージ
  , i_get_rec  IN  g_get_journal_cur%ROWTYPE                              -- レコード引数
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_entry_accession_info_p'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;                           -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT NULL;                           -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;                           -- ユーザー・エラー・メッセージ
    lb_retcode     BOOLEAN        DEFAULT NULL;                           -- メッセージ出力変数
    lv_out_msg     VARCHAR2(5000) DEFAULT NULL;                           -- メッセージ出力変数
    --===============================
    --ローカル例外
    --===============================
    get_slip_number_expt EXCEPTION;                                       -- 伝票番号取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==================================================================
    --登録付加情報取得
    --==================================================================
    gv_slip_number := xxcok_common_pkg.get_slip_number_f(
                        cv_pkg_name -- 本機能のパッケージ名
                      );
    IF( gv_slip_number IS NULL ) THEN
      RAISE get_slip_number_expt;
    END IF;
--
  EXCEPTION
    -- *** 伝票番号取得エラー ***
    WHEN get_slip_number_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_slip_number_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***	
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_entry_accession_info_p;
--
  /**********************************************************************************
   * Procedure Name   : get_object_journal_p
   * Description      : 仕訳対象取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_object_journal_p(
    ov_errbuf  OUT VARCHAR2                                         -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                         -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                         -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_object_journal_p'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode            VARCHAR2(1)    DEFAULT NULL;              -- リターン・コード
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lb_retcode            BOOLEAN        DEFAULT NULL;              -- メッセージ出力変数
    lv_out_msg            VARCHAR2(5000) DEFAULT NULL;              -- メッセージ出力変数
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
    lt_sales_staff_code jtf_rs_resource_extns.source_number%TYPE;   -- 担当営業員コード
-- 2009/12/21 Ver.1.5 [障害E_本稼動_00562] SCS K.Nakamura DEL START
--    lt_selling_from_cust  xxcok_selling_trns_info.selling_from_cust_code%TYPE;   -- 振替元顧客
-- 2009/12/21 Ver.1.5 [障害E_本稼動_00562] SCS K.Nakamura DEL END
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
    --===============================
    --ローカル例外
    --===============================
    taget_data_expt        EXCEPTION;                               -- 対象データ無エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    <<journal_loop>>
    FOR g_get_journal_rec IN g_get_journal_cur LOOP
      --================================================================
      --対象件数
      --================================================================
      gn_target_cnt := gn_target_cnt + 1;
      --================================================================
      --伝票番号初期化
      --================================================================
      gv_slip_number := NULL;
-- 2009/12/21 Ver.1.5 [障害E_本稼動_00562] SCS K.Nakamura MOD START
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
--      IF ( g_get_journal_rec.selling_from_cust_code != lt_selling_from_cust
--          OR g_get_journal_rec.selling_from_cust_code IS NULL )
--      THEN
--        lt_sales_staff_code := xxcok_common_pkg.get_sales_staff_code_f(
--                                   iv_customer_code => g_get_journal_rec.selling_from_cust_code
--                                 , id_proc_date     => g_get_journal_rec.xsti_selling_date
--                               );
--      END IF;
      lt_sales_staff_code := xxcok_common_pkg.get_sales_staff_code_f(
                                 iv_customer_code => g_get_journal_rec.selling_from_cust_code
                               , id_proc_date     => g_get_journal_rec.xsti_selling_date
                             );
-- 2009/12/21 Ver.1.5 [障害E_本稼動_00562] SCS K.Nakamura MOD END
--
      IF ( lt_sales_staff_code IS NOT NULL ) THEN
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
--
-- Start 2009/05/20 Ver_1.2 T1_1099 M.Hiruta
--      --================================================================
--      --売上金額(税抜き)、売上原価金額が共に0以外の場合
--      --================================================================
--      IF NOT( (     g_get_journal_rec.selling_amt         = 0 )
--        AND   ( NVL(g_get_journal_rec.selling_cost_amt,0) = 0 ) ) THEN
--
        --================================================================
        --売上金額(税抜き)、営業原価が共に0以外の場合
        --================================================================
        IF NOT( (     g_get_journal_rec.selling_amt     = 0 )
        AND   ( NVL(g_get_journal_rec.trading_cost,0) = 0 ) ) THEN
-- End   2009/05/20 Ver_1.2 T1_1099 M.Hiruta
          --================================================================
          --get_entry_accession_info_p呼び出し(登録付加情報取得(A-4))
          --================================================================
          get_entry_accession_info_p(
            ov_errbuf  => lv_errbuf          -- エラー・メッセージ
          , ov_retcode => lv_retcode         -- リターン・コード
          , ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ
          , i_get_rec  => g_get_journal_rec  -- レコード引数
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --================================================================
          --make_gloif_data_p呼び出し(仕訳作成(A-5))
          --================================================================
          make_gloif_data_p(
            ov_errbuf  => lv_errbuf          -- エラー・メッセージ
          , ov_retcode => lv_retcode         -- リターン・コード
          , ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ
          , i_get_rec  => g_get_journal_rec  -- レコード引数
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
          , iv_sales_staff => lt_sales_staff_code  -- 振替元顧客担当営業員
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --================================================================
        --upd_jounal_create_p呼び出し(仕訳作成フラグ更新(A-7))
        --================================================================
        upd_jounal_create_p(
          ov_errbuf  => lv_errbuf          -- エラー・メッセージ
        , ov_retcode => lv_retcode         -- リターン・コード
        , ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ
        , i_get_rec  => g_get_journal_rec  -- レコード引数
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --==============================================================
        --成功件数カウント
        --==============================================================
        gn_normal_cnt := gn_normal_cnt + 1;
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD START
      ELSE
        --==============================================================
        --警告件数カウント
        --==============================================================
        gn_warn_cnt := gn_warn_cnt + 1;
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_sales_staff_code_msg
                      , cv_cust_code_token
                      , g_get_journal_rec.selling_from_cust_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- 出力区分
                      , lv_out_msg         -- メッセージ
                      , 0                  -- 改行
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
        ov_retcode := cv_status_warn;
      END IF;
-- 2009/12/21 Ver.1.5 [障害E_本稼動_00562] SCS K.Nakamura DEL START
--      lt_selling_from_cust := g_get_journal_rec.selling_from_cust_code;
-- 2009/12/21 Ver.1.5 [障害E_本稼動_00562] SCS K.Nakamura DEL START
-- 2009/10/09 Ver.1.4 [障害E_T3_00632] SCS S.Moriyama ADD END
--
    END LOOP journal_loop;
    --==============================================================
    --対象件数のチェック
    --==============================================================
    IF( gn_target_cnt = 0 ) THEN
      RAISE taget_data_expt;
    END IF;
--
  EXCEPTION
    --*** 対象データ無エラー ***
    WHEN taget_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_data_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR START
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi REPAIR END
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_object_journal_p;
--
  /**********************************************************************************
   * Procedure Name   : chk_status_p
   * Description      : 会計期間ステータスチェック(A-2)
   ***********************************************************************************/
  PROCEDURE chk_status_p(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_status_p'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;          -- エラー・メッセージ
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;          -- リターン・コード
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;          -- ユーザー・エラー・メッセージ
    lb_retcode        BOOLEAN        DEFAULT NULL;          -- メッセージ出力変数
    ln_period_year    NUMBER         DEFAULT NULL;          -- 会計年度
    lv_closing_status VARCHAR2(100)  DEFAULT NULL;          -- ステータス
    lb_closing_status BOOLEAN        DEFAULT NULL;          -- ステータス(BOOLEAN)
    lv_out_msg        VARCHAR2(5000) DEFAULT NULL;          -- メッセージ出力変数
    --===============================
    --ローカル例外
    --===============================
    acctg_calendar_close_expt EXCEPTION;                    -- オープンファイル存在エラー
  --
  BEGIN
    ov_retcode := cv_status_normal;
    --==================================================================
    --売上計上日(前月末日)を取得
    --==================================================================
    gd_selling_date := LAST_DAY( ADD_MONTHS ( gd_operation_date, -1 ) );
    --==================================================================
    --会計期間のステータスを取得
    --==================================================================
    xxcok_common_pkg.get_acctg_calendar_p(
      ov_errbuf                 => lv_errbuf                    -- リターンコード
    , ov_retcode                => lv_retcode                   -- エラーバッファ
    , ov_errmsg                 => lv_errmsg                    -- エラーメッセージ
    , in_set_of_books_id        => gn_set_of_bks_id             -- A-1で取得した会計帳簿ID
    , iv_application_short_name => cv_appli_ar_name             -- 'AR'
    , id_object_date            => gd_selling_date              -- 上記で取得した売上計上日
    , iv_adjustment_period_flag => cv_adjustment_period_flag    -- 'N'
    , on_period_year            => ln_period_year               -- 会計年度
    , ov_period_name            => gv_period_name               -- 会計期間名
    , ov_closing_status         => lv_closing_status            -- ステータス
    );
--
    IF( lv_retcode <> cv_status_normal ) THEN
      -- *** 会計期間情報取得エラー ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_acctg_calendar_msg
                    , cv_proc_token
                    , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      RAISE global_api_expt;
    END IF;
    --==================================================================
    --会計期間のステータスチェック
    --==================================================================
    lb_closing_status := xxcok_common_pkg.check_acctg_period_f(
                           gn_set_of_bks_id                     -- A-1で取得した会計帳簿ID
                         , gd_selling_date                      -- 上記で取得した売上計上日
                         , cv_appli_ar_name                     -- アプリケーション短縮名
                         );
    IF( lb_closing_status = FALSE ) THEN
      RAISE acctg_calendar_close_expt;
    END IF;
--
  EXCEPTION
    -- *** 会計期間オープンエラー ***
    WHEN acctg_calendar_close_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_open_msg
                    , cv_proc_token
                    , TO_CHAR(gd_selling_date,'YYYY/MM/DD')
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_status_p;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                         -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                         -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                         -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lb_retcode         BOOLEAN        DEFAULT NULL; -- メッセージ出力変数
    lv_token_value     VARCHAR2(100)  DEFAULT NULL; -- トークン名
    lv_out_msg         VARCHAR2(5000) DEFAULT NULL; -- メッセージ出力変数
    --===============================
    --ローカル例外
    --===============================
    profile_expt        EXCEPTION;                  -- プロファイル取得エラー
    operation_date_expt EXCEPTION;                  -- 業務処理日付エラー
    batch_expt          EXCEPTION;                  -- バッチ取得エラー
    group_id_expt       EXCEPTION;                  -- グループID取得エラー
    currency_code_expt  EXCEPTION;                  -- 機能通貨コード取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --コンカレント入力パラメータなし項目をメッセージ出力
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_concurrent_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 1                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 1                  -- 改行
                  );
    --==============================================================
    --業務処理日付を取得
    --==============================================================
    gd_operation_date := xxccp_common_pkg2.get_process_date;
--
    IF( gd_operation_date IS NULL ) THEN
      RAISE operation_date_expt;
    END IF;
    --==============================================================
    --プロファイルを取得
    --==============================================================
    gn_set_of_bks_id  := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id           )); -- 会計帳簿ID
    gv_set_of_bks_name          := FND_PROFILE.VALUE( cv_set_of_bks_name          ); -- 会計帳簿名
    gv_comp_code                := FND_PROFILE.VALUE( cv_comp_code                ); -- 会社コード
    gv_table_keep_period        := FND_PROFILE.VALUE( cv_table_keep_period        ); -- 保持期間(月数)
    gv_acct_prod_sale           := FND_PROFILE.VALUE( cv_acct_prod_sale           ); -- 勘定科目コード(製品売上高)
    gv_aff4_subacct_dummy       := FND_PROFILE.VALUE( cv_aff4_subacct_dummy       ); -- 補助科目のダミー値
    gv_acct_prod_sale_cost      := FND_PROFILE.VALUE( cv_acct_prod_sale_cost      ); -- 勘定科目コード(製品売上原価)
    gv_assi_prod_sale_cost      := FND_PROFILE.VALUE( cv_assi_prod_sale_cost      ); -- 製品売上原価_受払表(製品原価)
    gv_gl_category_results      := FND_PROFILE.VALUE( cv_gl_category_results      ); -- 仕訳カテゴリ
    gv_gl_source_results        := FND_PROFILE.VALUE( cv_gl_source_results        ); -- 仕訳ソース
    gv_aff5_customer_dummy      := FND_PROFILE.VALUE( cv_aff5_customer_dummy      ); -- 顧客コードのダミー値
    gv_aff6_compuny_dummy       := FND_PROFILE.VALUE( cv_aff6_compuny_dummy       ); -- 企業コードのダミー値
    gv_aff7_preliminary1_dummy  := FND_PROFILE.VALUE( cv_aff7_preliminary1_dummy  ); -- 予備1のダミー値
    gv_aff8_preliminary2_dummy  := FND_PROFILE.VALUE( cv_aff8_preliminary2_dummy  ); -- 予備2のダミー値
    gv_selling_without_tax_code := FND_PROFILE.VALUE( cv_selling_without_tax_code ); -- 課税売上外税消費税コード
--
    IF( gn_set_of_bks_id IS NULL ) THEN
      lv_token_value := TO_CHAR( cv_set_of_bks_id );
      RAISE profile_expt;
--
    ELSIF( gv_set_of_bks_name IS NULL ) THEN
      lv_token_value := cv_set_of_bks_name;
      RAISE profile_expt;
--
    ELSIF( gv_comp_code IS NULL ) THEN
      lv_token_value := cv_comp_code;
      RAISE profile_expt;
--
    ELSIF( gv_table_keep_period IS NULL ) THEN
      lv_token_value := cv_table_keep_period;
      RAISE profile_expt;
--
    ELSIF( gv_acct_prod_sale IS NULL ) THEN
      lv_token_value := cv_acct_prod_sale;
      RAISE profile_expt;
--
    ELSIF( gv_acct_prod_sale_cost IS NULL ) THEN
      lv_token_value := cv_acct_prod_sale_cost;
      RAISE profile_expt;
--
    ELSIF( gv_aff4_subacct_dummy IS NULL ) THEN
      lv_token_value := cv_aff4_subacct_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_assi_prod_sale_cost IS NULL ) THEN
      lv_token_value := cv_assi_prod_sale_cost;
      RAISE profile_expt;
--
    ELSIF( gv_gl_category_results IS NULL ) THEN
      lv_token_value := cv_gl_category_results;
      RAISE profile_expt;
--
    ELSIF( gv_gl_source_results IS NULL ) THEN
      lv_token_value := cv_gl_source_results;
      RAISE profile_expt;
--
    ELSIF( gv_aff5_customer_dummy IS NULL ) THEN
      lv_token_value := cv_aff5_customer_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff6_compuny_dummy IS NULL ) THEN
      lv_token_value := cv_aff6_compuny_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff7_preliminary1_dummy IS NULL ) THEN
      lv_token_value := cv_aff7_preliminary1_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff8_preliminary2_dummy IS NULL ) THEN
      lv_token_value := cv_aff8_preliminary2_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_selling_without_tax_code IS NULL ) THEN
      lv_token_value := cv_selling_without_tax_code;
      RAISE profile_expt;
    END IF;
    --==============================================================
    --バッチ名を取得
    --==============================================================
    gv_batch_name := xxcok_common_pkg.get_batch_name_f(
                       gv_gl_category_results -- 仕訳カテゴリ
                     );
    IF( gv_batch_name IS NULL ) THEN
      RAISE batch_expt;
    END IF;
      --==============================================================
      --グループIDを取得
      --==============================================================
      BEGIN
        SELECT gjs.attribute1         AS group_id -- グループID
        INTO   gn_group_id
        FROM   gl_je_sources             gjs      -- 仕訳ソースマスタ
        WHERE  gjs.user_je_source_name = gv_gl_source_results;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE group_id_expt;
      END;
      --==============================================================
      --機能通貨コードを取得
      --==============================================================
      BEGIN
        SELECT gsob.currency_code  AS currency_code -- 機能通貨コード
        INTO   gv_currency_code
        FROM   gl_sets_of_books       gsob          -- 会計帳簿マスタ
        WHERE  gsob.set_of_books_id = gn_set_of_bks_id;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE currency_code_expt;
      END;
--
  EXCEPTION
    -- *** 業務処理日付取得エラー ***
    WHEN operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_operation_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_profile_msg
                    , cv_profile_token
                    , lv_token_value
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** バッチ名取得エラー ***
    WHEN batch_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_batch_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** グループID取得エラー ***
    WHEN group_id_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_group_id_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 機能通貨コード取得エラー ***
    WHEN currency_code_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_currency_code_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                            -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                            -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                            -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;            -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;            -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;            -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(5000) DEFAULT NULL;            -- メッセージ出力変数
    lb_retcode BOOLEAN        DEFAULT NULL;            -- メッセージ出力変数
--
  BEGIN
    ov_retcode := cv_status_normal;
    --================================================================
    --グローバル変数の初期化
    --================================================================
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --================================================================
    --initの呼び出し(初期処理(A-1))
    --================================================================
    init(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
    , ov_retcode => lv_retcode          -- リターン・コード
    , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --================================================================
    --chk_status_p呼び出し(会計期間ステータスチェック(A-2))
    --================================================================
    chk_status_p(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
    , ov_retcode => lv_retcode          -- リターン・コード
    , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi ADD START
    --================================================================
    --dlt_decision_flash_p呼び出し(速報確定フラグ「速報」削除(A-8))
    --================================================================
    dlt_decision_flash_p(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
    , ov_retcode => lv_retcode          -- リターン・コード
    , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --================================================================
    --dlt_decision_fixedness_p呼び出し(速報確定フラグ「確定」削除(A-9))
    --================================================================
    dlt_decision_fixedness_p(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
    , ov_retcode => lv_retcode          -- リターン・コード
    , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi ADD END
    --================================================================
    --get_object_journal_p呼び出し(仕訳対象取得(A-3))
    --================================================================
    get_object_journal_p(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
    , ov_retcode => lv_retcode          -- リターン・コード
    , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi ADD START
    ELSIF( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi ADD END
    END IF;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi DELETE START
--    --================================================================
--    --dlt_decision_flash_p呼び出し(速報確定フラグ「速報」削除(A-8))
--    --================================================================
--    dlt_decision_flash_p(
--      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
--    , ov_retcode => lv_retcode          -- リターン・コード
--    , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    ELSIF ( lv_retcode = cv_status_warn ) THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_warn;
--    END IF;
--    --================================================================
--    --dlt_decision_fixedness_p呼び出し(速報確定フラグ「確定」削除(A-9))
--    --================================================================
--    dlt_decision_fixedness_p(
--      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
--    , ov_retcode => lv_retcode          -- リターン・コード
--    , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    ELSIF ( lv_retcode = cv_status_warn ) THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_warn;
--    END IF;
-- 2009/09/08 Ver.1.3 [障害0001318] SCS K.Yamaguchi DELETE END
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                              -- エラー・メッセージ
  , retcode OUT VARCHAR2                                              -- リターン・コード
  )
  IS
    --===============================
    --ローカル定数
    --===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
    --===============================
    --ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                      -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL;                      -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                      -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100)  DEFAULT NULL;                      -- メッセージコード
    lb_retcode      BOOLEAN        DEFAULT NULL;                      -- メッセージ出力変数
    lv_out_msg      VARCHAR2(5000) DEFAULT NULL;                      -- メッセージ出力変数
--
  BEGIN
    --================================================================
    --コンカレントヘッダメッセージ出力関数の呼び出し
    --================================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , NULL               -- メッセージ
                  , 1                  -- 改行
                  );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --================================================================
    --submainの呼び出し(実際の処理はsubmainで行う)
    --================================================================
    submain(
      ov_errbuf  => lv_errbuf   -- リターン・コード
    , ov_retcode => lv_retcode  -- エラー・メッセージ
    , ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    --================================================================
    --エラー出力
    --================================================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_errmsg          -- メッセージ
                    , 1                  -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.LOG       -- 出力区分
                    , lv_errbuf          -- メッセージ
                    , 0                  -- 改行
                    );
    END IF;
    --================================================================
    --警告出力
    --================================================================
    IF( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_errmsg          -- メッセージ
                    , 1                  -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.LOG       -- 出力区分
                    , lv_errbuf          -- メッセージ
                    , 0                  -- 改行
                    );
    END IF;
    --================================================================
    --対象件数出力
    --================================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
    END IF;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_target_count_msg
                    , cv_count
                    , TO_CHAR( gn_target_cnt )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
    --================================================================
    --成功件数出力
    --================================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_normal_count_msg
                  , cv_count
                  , TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --================================================================
    --エラー件数出力
    --================================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_err_count_msg
                  , cv_count
                  , TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --================================================================
    --スキップ件数出力
    --================================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_warn_count_msg
                  , cv_count
                  , TO_CHAR( gn_warn_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --================================================================
    --終了メッセージ
    --================================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
      retcode         := cv_status_normal;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
      retcode         := cv_status_warn;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
      retcode         := cv_status_error;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --終了ステータスがエラーの場合はROLLBACKする
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode := cv_status_error;
  END main;
--
END XXCOK009A01C;
/
